unit qprov_http;

interface

uses classes, sysutils, dateutils, qstring, qjson, qdigest, db, fmtbcd, qdb,
  qvalue, qhttprequest, qconverter_stds;

type
  TQHttpToken = record
    Value: String;
    ExpireTime: TDateTime;
  end;

  EQDBHttpException = class(Exception)
  private
    FHelp: QStringW;
    FErrorCode: Integer;
  public
    constructor Create(AJson: TQJson);
    property ErrorCode: Integer read FErrorCode;
    property Help: QStringW read FHelp;
  end;

  TQHttpProvider = class(TQProvider)
  protected
    FAccessToken, FRefreshToken: TQHttpToken;
    FRequests: TQHttpRequests;
    FServiceUrl: QStringW;
    FAppSalt: QStringW;
    FServerExtParams: TQJson;
    function GetCustomHeaders: IQHttpHeaders;
    function GetServiceUrl: QStringW;
    procedure SetServiceUrl(const Value: QStringW);
    function GetAppId: QStringW;
    procedure SetAppId(const Value: QStringW);
    function InternalExecute(var ARequest: TQSQLRequest): Boolean; override;
    procedure InternalClose; override;
    procedure InternalOpen; override;
    procedure InternalApplyChanges(Fields: TFieldDefs;
      ARecords: TQRecords); override;
    function Rest(Action: QStringW; Params: TStrings; AData: TQJson;
      AUseToken: Boolean): TQJson;
    function CheckError(AJson: TQJson; ARaiseError: Boolean): Boolean;
    procedure RaiseError(AJson: TQJson);
    procedure Json2DataSet(ASource: TQJson; ADataSet: TQDataSet);
    procedure CloseHandle(AHandle: THandle); override;
    procedure KeepAliveNeeded; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    property AccessToken: TQHttpToken read FAccessToken;
    property RefreshToken: TQHttpToken read FRefreshToken;
    property CustomHeaders: IQHttpHeaders read GetCustomHeaders;
  published
    property ServiceUrl: QStringW read FServiceUrl write SetServiceUrl;
    property AppId: QStringW read GetAppId write SetAppId;
    property AppSalt: QStringW read FAppSalt write FAppSalt;
    property ServerExtParams: TQJson read FServerExtParams;
  end;

implementation

resourcestring
  SHttpError = 'HTTP 服务器发生错误 %d';
  SUnknownError = '未知错误';
  SUnknownJsonFormat = '服务器返回的数据格式不匹配';

  { TQHttpProvider }
const
  ERROR_SUCCESS = 0;
  ERROR_TOKEN_TIMEOUT = Cardinal(-1);
  ERROR_BAD_VALUE = Cardinal(-2);
  ERROR_MISSED = Cardinal(-3);
  ERROR_UNSUPPORT = Cardinal(-4);

type
  TPDONativeType = record
    Name: String;
    FieldType: TFieldType;
  end;

function TQHttpProvider.CheckError(AJson: TQJson; ARaiseError: Boolean)
  : Boolean;
var
  ACode: Integer;
begin
  (* TQHttpProvider 返回结构格式：
    {
    "code":整数错误代码,
    "hint":"字符串出错提示，也就是error message",
    "help":"出错时辅助的帮助信息，一般不呈现给用户",
    "result":请求结果（根据请求不同，返回的可能是单一值或对象或数组）
    }
    上面的结构中，code 是始终存在的，如果成功，返回0，失败，返回错误代码
  *)
  ACode := AJson.IntByName('code', MaxInt);
  Result := ACode = 0;
  if (not Result) then
  begin
    SetError(Cardinal(ACode), AJson.ValueByName('hint', ''));
    if ARaiseError then
      RaiseError(AJson);
  end
  else
    SetError(0, '');
end;

procedure TQHttpProvider.CloseHandle(AHandle: THandle);
begin
  inherited;
  // 不支持，忽略
end;

constructor TQHttpProvider.Create(AOwner: TComponent);
begin
  inherited;
  FRequests := TQHttpRequests.Create;
  FServerExtParams := TQJson.Create;
end;

destructor TQHttpProvider.Destroy;
begin
  FreeAndNil(FServerExtParams);
  inherited;
  FreeAndNil(FRequests);
end;

function TQHttpProvider.GetAppId: QStringW;
begin
  Result := Params.Values['appid'];
end;

function TQHttpProvider.GetCustomHeaders: IQHttpHeaders;
begin
  Result := FRequests.DefaultHeaders;
end;

function TQHttpProvider.GetServiceUrl: QStringW;
begin
  Result := Params.Values['url'];
end;

procedure TQHttpProvider.InternalApplyChanges(Fields: TFieldDefs;
  ARecords: TQRecords);
begin
  // Todo:转换SQL为更新SQL脚本，要求服务器端启用
end;

procedure TQHttpProvider.InternalClose;
var
  AResult, ATokens: TQJson;
begin
  inherited;
  AResult := Rest('Close', nil, nil, true);
  try
    CheckError(AResult, false);
    FAccessToken.Value := '';
    FAccessToken.ExpireTime := 0;
    FRefreshToken.Value := '';
    FRefreshToken.ExpireTime := 0;
    FHandle := 0;
  finally
    FreeAndNil(AResult);
  end;
end;

function TQHttpProvider.InternalExecute(var ARequest: TQSQLRequest): Boolean;
var
  AReqJson, AResult: TQJson;
  I: Integer;
  ATokenTimeout: Boolean;
  procedure FetchAsStream;
  var
    ATemp: TQDataSet;
  begin
    ATemp := OpenDataSet(ARequest.Command.SQL);
    if Assigned(ATemp) then
    begin
      try
        ATemp.SaveToStream(ARequest.Command.DataObject,
          TQJsonConverter, merAll);
      finally
        ReleaseDataSet(ATemp);
      end;
    end;
  end;
  procedure FetchDataSet;
  var
    ADataSet: TQDataSet;
  begin
    AResult := Rest('OpenDataSet', nil, AReqJson, true);
    CheckError(AResult, false);
    if FErrorCode = ERROR_TOKEN_TIMEOUT then
    begin
      KeepAliveNeeded;
      FreeAndNil(AResult);
      FetchDataSet;
    end
    else if FErrorCode <> 0 then
      RaiseError(AResult)
    else
    begin
      Json2DataSet(AResult.ItemByName('result'), ARequest.Command.DataObject);
    end;
  end;

  procedure DoExecuteSQL;
  begin
    AResult := Rest('ExecSQL', nil, AReqJson, true);
    CheckError(AResult, false);
    if FErrorCode = ERROR_TOKEN_TIMEOUT then
    begin
      KeepAliveNeeded;
      FreeAndNil(AResult);
      DoExecuteSQL;
    end
    else if FErrorCode <> 0 then
      RaiseError(AResult)
    else
      ARequest.Result.Statics.AffectRows := AResult.IntByName('result', 0);
  end;

begin
  Result := false;
  AResult := nil;
  ATokenTimeout := false;
  AReqJson := TQJson.Create;
  try
    AReqJson.Add('id').AsString := ARequest.Command.Id;
    AReqJson.Add('sql').AsString := ARequest.Command.SQL;
    if TransactionLevel > 0 then
      AReqJson.Add('transaction').AsBoolean := true;
    if Length(ARequest.Command.Params) > 0 then
    begin
      with AReqJson.Add('params', jdtArray) do
      begin
        for I := 0 to High(ARequest.Command.Params) do
          Add.AsVariant := ARequest.Command.Params[I].AsVariant
      end;
    end;
    case ARequest.Command.Action of
      caPrepare: // 不支持
        Result := true;
      caFetchStream:
        FetchAsStream;
      caFetchRecords:
        begin
          FetchDataSet;
          Result := true;
        end;
      caExecute:
        begin
          DoExecuteSQL;
          Result := true;
        end;
      caUnprepare:
        Result := true;
    end;
  finally
    FreeAndNil(AReqJson);
    if Assigned(AResult) then
      FreeAndNil(AResult);
  end;
end;

procedure TQHttpProvider.InternalOpen;
var
  AResult, ATokens: TQJson;
  ATime: TDateTime;
  AExpire: Integer;
begin
  inherited;
  AResult := Rest('Open', Params, nil, false);
  try
    CheckError(AResult, true);
    if AResult.HasChild('result', ATokens) then
    begin
      // 打开连接token
      ATime := Now;
      FAccessToken.Value := ATokens.ValueByName('access_token', '');
      // 默认会话有效期为2小时（7200秒）
      AExpire := ATokens.IntByName('access_expire', 7200);
      FAccessToken.ExpireTime := IncSecond(ATime, AExpire);
      if AExpire > 30 then // 提前30秒刷新会话
        PeekInterval := AExpire - 30;
      FRefreshToken.Value := ATokens.ValueByName('refresh_token', '');
      // 刷新会话有效期，默认为30天
      FRefreshToken.ExpireTime :=
        IncSecond(ATime, ATokens.IntByName('refresh_expire', 2592000));
      // 连接句柄
      FHandle := IntPtr(Self);
      FServerExtParams.Assign(ATokens);
    end;
  finally
    FreeAndNil(AResult);
  end;
end;

procedure TQHttpProvider.Json2DataSet(ASource: TQJson; ADataSet: TQDataSet);
var
  AFieldsRoot, ARowsRoot, AItem: TQJson;
  ADefs: TQFieldDefs;
  ADef: TQFieldDef;
  function TypeOfName(const AName: String): TFieldType;
  begin
    for Result := Low(TFieldType) to High(TFieldType) do
    begin
      if FieldTypeNames[Result] = AName then
        Exit;
    end;
    Result := ftWideMemo;
  end;

  function CheckSize(AValue: Integer): Integer;
  var
    I: Integer;
  begin
    if ADef.DataType in ftFixedSizeTypes then
      Result := 0
    else if ADef.DataType = ftGuid then
      Result := dsGuidStringLength
    else if ADef.DataType = ftBcd then
    begin
      if AValue > 32 then
        Result := 32
      else
        Result := AValue;
    end
    else if AValue < 0 then
    begin
      if ADef.DataType in [ftString, ftWideString] then
        Result := MaxInt
      else
        Result := 0;
    end
    else
      Result := AValue;
  end;

  function ForceInRange(const V, AMin, AMax: Integer): Integer;
  begin
    if V < AMin then
      Result := AMin
    else if V > AMax then
      Result := AMax
    else
      Result := V;
  end;

  procedure LoadFieldDefs;
  var
    I, J: Integer;
    AFlags: TQJson;
    S: String;
  begin
    ADataSet.FieldDefs.BeginUpdate;
    try
      ADefs := ADataSet.FieldDefs as TQFieldDefs;
      for I := 0 to AFieldsRoot.Count - 1 do
      begin
        AItem := AFieldsRoot[I];
        ADef := ADefs.AddFieldDef as TQFieldDef;
        ADef.Name := AItem.ValueByName('name', '');
        ADef.Table := AItem.ValueByName('table', '');
        ADef.Schema := AItem.ValueByName('schema', '');
        ADef.Database := AItem.ValueByName('category', '');
        ADef.BaseName := AItem.ValueByName('base_name', '');
        // ADef.Nullable:=AItem
        ADef.DBNo := I;
        ADef.DataType := TypeOfName(AItem.ValueByName('delphi_type',
          'WideMemo'));
        ADef.Size := CheckSize(AItem.IntByName('len', -1));
        ADef.Precision := AItem.IntByName('precision', -1);
        ADef.Scale := AItem.IntByName('scale', 0);
        if AItem.HasChild('flags', AFlags) then
        begin
          for J := 0 to AFlags.Count - 1 do
          begin
            S := LowerCase(AFlags[J].AsString);
            if S = 'not_null' then
              ADef.Nullable := false
            else if (S = 'primary_key') or (S = 'multiple_key') then
            begin
              ADef.IsPrimary := true;
              ADef.IsIndex := true;
            end
            else if S = 'unique_key' then
            begin
              ADef.IsUnique := true;
              ADef.IsIndex := true;
            end
            else if S = 'blob' then // Blob从字段类型中可以直接获取，不需要管它
                ;

          end;

        end;
      end;
    finally
      ADataSet.FieldDefs.EndUpdate;
    end;
  end;
  procedure WriteBlobStream(AStream: TStream; AValue: TQJson);
  var
    ABytes: TBytes;
    V: String;
  begin
    if ADef.DataType = ftWideMemo then
    begin
      V := AValue.AsString;
      if Length(V) > 0 then
        AStream.Write(PChar(V)^, Length(V) shl 1);
    end
    else if ADef.DataType in [ftMemo, ftFmtMemo] then
    begin
      ABytes := qstring.AnsiEncode(V);
      if Length(ABytes) > 0 then
        AStream.Write(ABytes[0], Length(ABytes));
    end
    else
      AValue.StreamFromValue(AStream);
  end;
  procedure LoadRecords;
  var
    I: Integer;
    J: Integer;
    ARec: TQRecord;
    AFieldItem: TQJson;
  begin
    for I := 0 to ARowsRoot.Count - 1 do
    begin
      AItem := ARowsRoot[I];
      ARec := ADataSet.AllocRecord;
      for J := 0 to ADefs.Count - 1 do
      begin
        ADef := ADefs[J] as TQFieldDef;
        AFieldItem := AItem[J];
        with ARec.Values[J].OldValue do
        begin
          if AFieldItem.IsNull then
            Reset
          else
          begin
            TypeNeeded(ADef.ValueType);
            case ValueType of
              vdtBoolean:
                Value.AsBoolean := AFieldItem.AsBoolean;
              vdtFloat:
                Value.AsFloat := AFieldItem.AsFloat;
              vdtInteger:
                Value.AsInteger := AFieldItem.AsInteger;
              vdtInt64:
                Value.AsInt64 := AFieldItem.AsInt64;
              vdtCurrency:
                Value.AsCurrency := AFieldItem.AsFloat;
              vdtBcd:
                Value.AsBcd^ := DoubleToBcd(AFieldItem.AsFloat);
              vdtGuid:
                if not TryStrToGuid(AFieldItem.AsString, Value.AsGuid^) then
                begin
                  if ADef.Nullable then
                    Reset;
                end;
              vdtDateTime:
                if AFieldItem.IsDateTime then
                  Value.AsDateTime := AFieldItem.AsDateTime
                else if ADef.Nullable then
                  Reset
                else
                  Value.AsDateTime := 0;
              vdtInterval:
                Value.AsInt64 := AFieldItem.AsInt64;
              vdtString:
                Value.AsString^ := AFieldItem.AsString;
              vdtStream:
                WriteBlobStream(Value.AsStream, AFieldItem);
            end;
          end;
        end;
      end;
      AddResultRecord(ARec);
    end;
  end;

begin
  AFieldsRoot := ASource.ItemByName('Fields');
  ARowsRoot := ASource.ItemByName('Records');
  if Assigned(AFieldsRoot) and Assigned(ARowsRoot) then
  begin
    LoadFieldDefs;
    LoadRecords;
  end
  else
    DatabaseError(SUnknownJsonFormat);
end;

procedure TQHttpProvider.KeepAliveNeeded;
var
  AParams: TStringList;
  AResult, ATokens: TQJson;
  ATime: TDateTime;
begin
  AParams := TStringList.Create;
  AResult := nil;
  try
    AParams.Add('refreshtoken=' + RefreshToken.Value);
    AResult := Rest('RefreshToken', AParams, nil, true);
    CheckError(AResult, true);
    if AResult.HasChild('result', ATokens) then
    begin
      ATime := Now;
      FAccessToken.Value := ATokens.ValueByName('access_token', '');
      FAccessToken.ExpireTime :=
        IncSecond(ATime, ATokens.IntByName('access_expire', 7200));
      FRefreshToken.Value := ATokens.ValueByName('refresh_token', '');
      FRefreshToken.ExpireTime :=
        IncSecond(ATime, ATokens.IntByName('refresh_expire', 2592000));
      FHandle := IntPtr(Self);
      FServerExtParams.Assign(ATokens);
    end;
  finally
    FreeAndNil(AParams);
    if Assigned(AResult) then
      FreeAndNil(AResult);
  end;
end;

procedure TQHttpProvider.RaiseError(AJson: TQJson);
begin
  raise EQDBHttpException.Create(AJson);
end;

function TQHttpProvider.Rest(Action: QStringW; Params: TStrings; AData: TQJson;
  AUseToken: Boolean): TQJson;
var
  AUrl: TQUrl;
  AStatus: Integer;
begin
  Result := TQJson.Create;
  AUrl := TQUrl.Create(ServiceUrl + Action);
  try
    // 强制为公共参数赋值
    // URL签名生成算法为参数值+Salt,Salt为AppSalt
    if Assigned(Params) then
      AUrl.Params.Assign(Params);
    // 如果有 Access Token，则传它
    if AUseToken and (Length(AccessToken.Value) > 0) then
      AUrl.Params.Values['token'] := AccessToken.Value
    else if Length(AppId) > 0 then
      AUrl.Params.Values['appid'] := AppId;
    // 强制传时间戳进去，服务器端会记录客户端和服务器端的时间差异，如果太大，会拒绝请求，以避免伪造的历史数据包
    // 注意：服务器并不要求客户端与服务器端时间一致，打开连接时，服务器会记录客户端的时间戳参数和服务器端的差值，
    // 比较也会以这个差值为基础，从而避免不必要麻烦，当然客户端也可以同步服务器的时间
    AUrl.Params.Values['timestamp'] := IntToStr(DateTimeToUnix(Now));
    AUrl.SortParams();
    // 生成签名
    AUrl.Params.Values['sign'] :=
      DigestToString(MD5Hash(AUrl.OriginParams + '&' + AppSalt), true);
    // 参数乱序化
    AUrl.RandSortParams;
    repeat
      AStatus := FRequests.Rest(AUrl.Url, AData, Result, CustomHeaders,
        nil, reqPost);
    until AStatus <> 12030; // 12030- HTTP接收数据时，连接异外中止
    if AStatus <> 200 then
    begin
      Result.Add('code').AsInteger := -1000 - AStatus;
      Result.Add('hint').AsString := Format(SHttpError, [AStatus]);
    end;
  finally
    FreeAndNil(AUrl);
  end;
end;

procedure TQHttpProvider.SetAppId(const Value: QStringW);
begin
  Params.Values['appid'] := Value;
end;

procedure TQHttpProvider.SetServiceUrl(const Value: QStringW);
begin
  if FServiceUrl <> Value then
  begin
    Close;
    if not EndWithW(Value, '/', false) then
      FServiceUrl := Value + '/'
    else
      FServiceUrl := Value;
  end;
end;

{ TQDBHttpException }

constructor EQDBHttpException.Create(AJson: TQJson);
begin
  inherited Create(AJson.ValueByName('hint', SUnknownError));
  FErrorCode := AJson.IntByName('code', -999);
  FHelp := AJson.ValueByName('help', '');
end;

end.
