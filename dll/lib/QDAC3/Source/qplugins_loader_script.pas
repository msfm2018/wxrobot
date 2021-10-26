unit qplugins_loader_script;

{ Pascal 脚本插件加载器，使用 JvInterpreter 来解释脚本的执行
}
interface

uses classes, sysutils, syncobjs, variants, qstring, qplugins,qplugins_base,qplugins_params,
  jvInterpreter, jvInterpreterFM;
{$HPPEMIT '#pragma link "qplugins_loader_script"'}
type
  // 这个接口只是自己单元使用，所以不用使用stdcall规则
  IQScriptService = interface
    ['{7B7100EE-88CC-4C07-9A34-F46AD6A506FD}']
    function GetSourceFile: QStringW;
    function GetSourceEntry: QStringW;
  end;

  TQScriptModule = class
  protected
    FFileName: QStringW;
    FScriptEngine: TJvInterpreterFm;
    FServices: TQPointerList;
    FLocker: TCriticalSection;
  public
    constructor Create; overload;
    destructor Destroy; override;
    procedure Lock;
    procedure Unlock;
  end;

  TQScriptService = class(TQService, IQScriptService)
  private
  protected
    FEntry: QStringW;
    FModule: TQScriptModule;
    function GetSourceFile: QStringW;
    function GetSourceEntry: QStringW;
  public
    constructor Create(const AId: TGuid; AName: QStringW); override;
    destructor Destroy; override;
    function Execute(AParams: IQParams; AResult: IQParams): Boolean;
      override; stdcall;
    property Source: QStringW read GetSourceFile;
    property Entry: QStringW read FEntry;
  end;

  TQPascalScriptLoader = class(TQBaseLoader)
  protected
    FActiveModule: TQScriptModule;
    function GetServiceSource(AService: IQService; ABuf: PWideChar;
      ALen: Integer): Integer; override; stdcall;
    function InternalLoadServices(const AFileName: PWideChar): THandle;
      override;
    function InternalUnloadServices(const AHandle: THandle): Boolean; override;
    class procedure DoRegisterService(var Value: Variant;
      Args: TJvInterpreterArgs); static;
  public
    constructor Create(APath, AExt: QStringW); overload;
    destructor Destroy; override;
  end;

implementation

const
  LID_PASCALSCRIPT: TGuid = '{189CF9D6-4EA3-4C4A-BF0C-A842127C0AB9}';

resourcestring
  SServiceFunctionMissed = '请求的函数 %s 不存在。';
  SUnsupportParamType = '脚本不支持指定的参数类型 %s 。';
  SUnsupportResultType = '函数的返回值类型不受支持。';

var
  ScriptLoader: TQPascalScriptLoader;
  { TQScriptService }

constructor TQScriptService.Create(const AId: TGuid; AName: QStringW);
begin
  inherited Create(AId, AName);
  FLoader := ScriptLoader;
end;

destructor TQScriptService.Destroy;
begin
  inherited;
end;

function TQScriptService.Execute(AParams, AResult: IQParams): Boolean;
var
  AParamValues: array of Variant;
  procedure ParamToArgs;
  var
    I: Integer;
    AParam: IQParam;
  begin
    SetLength(AParamValues, AParams.Count);
    for I := 0 to AParams.Count - 1 do
    begin
      AParam := AParams[I];
      case AParam.ParamType of
        ptInt8, ptUInt8, ptInt16, ptUInt16, ptInt32:
          AParamValues[I] := AParam.AsInteger;
        ptUInt32, ptInt64, ptUInt64:
          AParamValues[I] := AParam.AsInt64;
        ptFloat4:
          AParamValues[I] := AParam.AsSingle;
        ptFloat8:
          AParamValues[I] := AParam.AsFloat;
        ptDateTime:
          AParamValues[I] := AParam.AsFloat;
        ptInterval, ptAnsiString, ptUtf8String, ptUnicodeString, ptGuid:
          AParamValues[I] := QStringW(AParam.AsString.Value);
        ptBoolean:
          AParamValues[I] := AParam.AsBoolean;
        ptBytes, ptStream, ptArray:
          raise QException.CreateFmt(SUnsupportParamType,
            [ParamTypeNames[AParam.ParamType]]);
      end;
    end;
  end;
  procedure VarToResult(V: Variant);
  begin
    AResult.Clear;
    case VarType(V) of
      varEmpty, varNull:
        ;
      varSmallint, varInteger, varShortInt, varByte, varWord:
        AResult.Add('Result', ptInt32).AsInteger := V;
      varSingle:
        AResult.Add('Result', ptFloat4).AsSingle := V;
      varDouble, varCurrency, varDate:
        AResult.Add('Result', ptFloat8).AsFloat := V;
      varString, varOleStr, varUString:
        AResult.Add('Result', ptUnicodeString).AsString :=
          NewString(PWideChar(VarToWideStr(V)));
      varBoolean:
        AResult.Add('Result', ptBoolean).AsBoolean := V;
      varLongWord, varInt64, varUInt64:
        AResult.Add('Result', ptInt64).AsInt64 := V
    else
      raise QException.Create(SUnsupportResultType);
    end;
  end;

begin
  Result := True;
  ParamToArgs;
  FModule.Lock;
  try
    VarToResult(FModule.FScriptEngine.CallFunction(FEntry, nil, AParamValues));
  except
    on E: Exception do
    begin
      SetLastError(2, E.Message);
      Result := False;
    end;
  end;
  FModule.Unlock;
end;

function TQScriptService.GetSourceEntry: QStringW;
begin
  Result := FEntry;
end;

function TQScriptService.GetSourceFile: QStringW;
begin
  Result := FModule.FFileName;
end;

{ TQPascalScriptLoader }

constructor TQPascalScriptLoader.Create(APath, AExt: QStringW);
begin
  if Length(AExt) = 0 then
    AExt := '.PAS';
  inherited Create(LID_PASCALSCRIPT, 'Loader_PascalScript', APath, AExt);
  GlobalJvInterpreterAdapter.AddFunction('', 'RegisterService',
    DoRegisterService, 4, [varUString, varUString, varUString,
    varUString], varNull);
  ScriptLoader := Self;
end;

destructor TQPascalScriptLoader.Destroy;
begin
  inherited;
  ScriptLoader := nil;
end;

class procedure TQPascalScriptLoader.DoRegisterService(var Value: Variant;
  Args: TJvInterpreterArgs);
var
  APath, AName, AEntry: QStringW;
  AId: TGuid;
  AServices: IQServices;
  procedure AddService;
  var
    AScriptService: TQScriptService;
  begin
    if ScriptLoader.FActiveModule.FScriptEngine.FunctionExists('', AEntry) then
    begin
      AScriptService := TQScriptService.Create(AId, AName);
      AScriptService.FModule := ScriptLoader.FActiveModule;
      AScriptService.FEntry := AEntry;
      AServices.Add(AScriptService);
      ScriptLoader.FActiveModule.FServices.Add(AScriptService);
    end
    else
      raise Exception.CreateFmt(SServiceFunctionMissed, [AEntry]);
  end;

begin
  AId := StringToGuid(Args.Values[0]);
  APath := Args.Values[1];
  AName := Args.Values[2];
  AEntry := Args.Values[3];
  AServices := PluginsManager.ForcePath(PQCharW(APath));
  AddService;
end;

function TQPascalScriptLoader.GetServiceSource(AService: IQService;
  ABuf: PWideChar; ALen: Integer): Integer;
var
  ASource: IQScriptService;
  S: QStringW;
begin
  if Supports(AService, IQScriptService, ASource) then
  begin
    S := Format('%s.%s', [ASource.GetSourceFile, ASource.GetSourceEntry]);
    if (ABuf = nil) or (ALen = 0) then
      Result := Length(S)
    else
    begin
      Result := Length(S);
      if ALen < Result then
        Result := ALen;
      Move(PWideChar(S)^, ABuf^, ALen shl 1);
    end;
  end
  else
    Result := 0;
end;

function TQPascalScriptLoader.InternalLoadServices(const AFileName
  : PWideChar): THandle;
var
  ADFMFile: QStringW;
  APath: QStringW;
begin
  Result := 0;
  FActiveModule := TQScriptModule.Create;
  try
    FActiveModule.FFileName := AFileName;
    APath := ExtractFilePath(AFileName);
    ADFMFile := ExtractFileName(AFileName);
    ADFMFile := StrDupX(PWideChar(ADFMFile), Length(ADFMFile) -
      Length(ExtractFileExt(ADFMFile))) + '.dfm';
    if FileExists(APath + ADFMFile) then // 如果存在窗体文件
      FActiveModule.FScriptEngine.MakeForm(APath + ADFMFile)
    else
    begin
      FActiveModule.FScriptEngine.Source := LoadTextW(AFileName);
      FActiveModule.FScriptEngine.Compile;
    end;
    if FActiveModule.FScriptEngine.FunctionExists('', 'RegisterServices') then
    begin
      FActiveModule.FScriptEngine.CallFunction('RegisterServices', nil, []);
      Result := IntPtr(FActiveModule);
    end;
  except
    on E: Exception do
    begin
      SetLastError(1, E.Message);
    end;
  end;
  if Result = 0 then
    FreeObject(FActiveModule);
end;

function TQPascalScriptLoader.InternalUnloadServices(const AHandle
  : THandle): Boolean;
begin
  FreeObject(Pointer(AHandle));
  Result := True;
end;

{ TQScriptModule }

constructor TQScriptModule.Create;
begin
  inherited;
  FServices := TQPointerList.Create;
  FScriptEngine := TJvInterpreterFm.Create(nil);
  FLocker := TCriticalSection.Create;
end;

destructor TQScriptModule.Destroy;
var
  I: Integer;
  AService: TQScriptService;
begin
  FLocker.Enter;
  try
    for I := 0 to FServices.Count - 1 do
    begin
      AService := FServices[I];
      AService.Parent.Remove(AService);
    end;
  finally
    FLocker.Leave;
  end;
  FreeObject(FServices);
  FreeObject(FScriptEngine);
  FreeObject(FLocker);
  inherited;
end;

procedure TQScriptModule.Lock;
begin
  FLocker.Enter;
end;

procedure TQScriptModule.Unlock;
begin
  FLocker.Leave;
end;

end.
