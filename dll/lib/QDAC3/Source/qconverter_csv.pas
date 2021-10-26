unit qconverter_csv;

interface

uses qstring, qdb, qvalue, fmtbcd, classes, sysutils, db;

type
  TQTextReformatEvent = procedure(ASender: TQConverter; AField: TQFieldDef;
    var AText: QStringW) of object;
  TQGetTextFieldTypeEvent = procedure(ASender: TQConverter; AField: QStringW;
    var AType: TFieldType; var ASize: Integer) of object;
  TQGetCustomFieldsEvent = procedure(ASender: TQConverter;
    AFieldDefs: TQFieldDefs) of object;
  TQGetCustomFieldValuesEvent = procedure(ASender: TQConverter; ARec: TQRecord)
    of object;
{$IF RTLVersion>=23}
  [ComponentPlatformsAttribute(pidWin32 or pidWin64{$IF RTLVersion>=24} or
    pidOSX32{$IFEND}{$IF RTLVersion>=25} or pidiOSSimulator or
    pidiOSDevice{$IFEND}{$IF RTLVersion>=26} or
    pidAndroid{$IFEND}{$IF RTLVersion>=29} or pidiOSDevice32 or
    pidiOSDevice64{$IFEND})]
{$IFEND}

  TQTextConverter = class(TQConverter)
  protected
    FDelimiter: WideChar;
    FQuoter: WideChar;
    FExportEncoding: TTextEncoding;
    FOnGetFieldType: TQGetTextFieldTypeEvent;
    FOnGetCustomFields: TQGetCustomFieldsEvent;
    FOnGetCustomValues: TQGetCustomFieldValuesEvent;
    FFirstIsFieldName: Boolean;
    FText: TQStringCatHelperW;
    FFixedFieldCount: Integer;
    FTextPos: PWideChar;
    FOnEncodeValue: TQTextReformatEvent;
    FOnDecodeValue: TQTextReformatEvent;
    FSaveToText: Boolean;
    procedure BeforeExport; override;
    procedure BeginExport(AIndex: Integer); override;
    procedure SaveFieldDefs(ADefs: TQFieldDefs); override;
    function WriteRecord(ARec: TQRecord): Boolean; override;
    procedure EndExport(AIndex: Integer); override;
    procedure AfterExport; override;
    // 导入接口
    procedure BeforeImport; override;
    procedure BeginImport(AIndex: Integer); override;
    procedure LoadFieldDefs(AFieldDefs: TQFieldDefs); override;
    function ReadRecord(ARec: TQRecord): Boolean; override;
    procedure EndImport(AIndex: Integer); override;
    procedure AfterImport; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function SaveToText(ADataSet: TQDataSet): QStringW;
    procedure LoadFromText(ADataSet: TQDataSet; const AText: QStringW);
  published
    property ExportEncoding: TTextEncoding read FExportEncoding
      write FExportEncoding; // 输出文件编码，默认UTF-8
    property Delimiter: WideChar read FDelimiter write FDelimiter; // 字段分隔符
    property Quoter: WideChar read FQuoter write FQuoter; // 值两边的引号
    property FirstIsFieldName: Boolean read FFirstIsFieldName
      write FFirstIsFieldName; // 首行是否是字段名称列表
    property OnDecodeValue: TQTextReformatEvent read FOnDecodeValue
      write FOnDecodeValue; // 提供用户自定义值的解析方式
    property OnEncodeValue: TQTextReformatEvent read FOnEncodeValue
      write FOnEncodeValue;
    property OnGetFieldType: TQGetTextFieldTypeEvent read FOnGetFieldType
      write FOnGetFieldType; // 提供用户自定义字段类型的位置
    property OnGetCustomFields: TQGetCustomFieldsEvent read FOnGetCustomFields
      write FOnGetCustomFields; // 提供用户添加额外的自定义字段的位置
    property OnGetCustomValues: TQGetCustomFieldValuesEvent
      read FOnGetCustomValues write FOnGetCustomValues; // 提供用户为自定义字段赋值的位置
  end;
{$IF RTLVersion>=23}
  [ComponentPlatformsAttribute(pidWin32 or pidWin64{$IF RTLVersion>=24} or
    pidOSX32{$IFEND}{$IF RTLVersion>=25} or pidiOSSimulator or
    pidiOSDevice{$IFEND}{$IF RTLVersion>=26} or
    pidAndroid{$IFEND}{$IF RTLVersion>=29} or pidiOSDevice32 or
    pidiOSDevice64{$IFEND})]
{$IFEND}

  // CSV和普通的文本转换器完全一样，没啥需要额外处理的
  TQCSVConverter = class(TQTextConverter)

  end;

implementation

resourcestring
  SCanConvert = '无法将值 %s 转换为 %s 类型.';
  { TQTextConverter }

procedure TQTextConverter.AfterExport;

var
  S: QStringW;

  procedure SaveTextWBE;
  var
    bom: Word;
  begin
    bom := $FEFF;
    FStream.WriteBuffer(bom, 2);
    ExchangeByteOrder(PQCharA(PWideChar(S)), Length(S) shl 1);
    FStream.WriteBuffer(PWideChar(S)^, Length(S) shl 1);
  end;

begin
  if FSaveToText then
    Exit;
  S := FText.Value;
  case ExportEncoding of
    teAnsi:
      SaveTextA(FStream, qstring.AnsiEncode(S));
    teUnicode16LE:
      SaveTextW(FStream, S);
    teUnicode16BE:
      SaveTextWBE
  else
    SaveTextU(FStream, S);
  end;
  inherited;
end;

procedure TQTextConverter.AfterImport;
begin
  inherited;

end;

procedure TQTextConverter.BeforeExport;
begin
  inherited;
  FText.Reset;
end;

procedure TQTextConverter.BeforeImport;
begin
  inherited;
  if Assigned(FStream) then
    FText.LoadFromStream(FStream);
  FTextPos := FText.Start;
end;

procedure TQTextConverter.BeginExport(AIndex: Integer);
begin
  inherited;
  // CSV 只支持导出一个结果集，所以不需要任何操作
end;

procedure TQTextConverter.BeginImport(AIndex: Integer);
begin
  inherited;
  // CSV 只支持导入一个结果集，所以不需要任何操作
end;

constructor TQTextConverter.Create(AOwner: TComponent);
begin
  inherited;
  FDelimiter := ',';
  FQuoter := '"';
  FExportEncoding := teUtf8;
  FFirstIsFieldName := True;
  FText := TQStringCatHelperW.Create;
end;

destructor TQTextConverter.Destroy;
begin
  FreeAndNil(FText);
  inherited;
end;

procedure TQTextConverter.EndExport(AIndex: Integer);
begin
  inherited;

end;

procedure TQTextConverter.EndImport(AIndex: Integer);
begin
  inherited;

end;

procedure TQTextConverter.LoadFieldDefs(AFieldDefs: TQFieldDefs);
var
  ALine: QStringW;
  p: PWideChar;
  AName: QStringW;
  procedure AddFieldDef;
  var
    AType: TFieldType;
    ASize: Integer;
    ADef: TQFieldDef;
  begin
    AType := ftWideString;
    ASize := MaxInt;
    if Assigned(OnGetFieldType) then
      OnGetFieldType(Self, AName, AType, ASize);
    ADef := AFieldDefs.AddFieldDef as TQFieldDef;
    ADef.Name := AName;
    ADef.DBType := SQLTypeMap[AType];
    if (ASize <> ADef.Size) and (ASize > 0) then
      ADef.Size := ASize;
  end;

begin
  inherited;
  p := FTextPos;
  ALine := DecodeLineW(p);
  if FirstIsFieldName then
  begin
    FTextPos := p;
    p := PWideChar(ALine);
    repeat
      AName := DequotedStrW(DecodeTokenW(p, [Delimiter], Quoter, True,
        False), Quoter);
      if Length(AName) = 0 then
        AName := 'COL_' + IntToStr(AFieldDefs.Count);
      if p^ = Delimiter then
      begin
        Inc(p);
        SkipSpaceW(p);
      end;
      AddFieldDef;
    until p^ = #0;
  end
  else
  begin
    p := PWideChar(ALine);
    repeat
      DecodeTokenW(p, [Delimiter], Quoter, True, False);
      AName := 'COL_' + IntToStr(AFieldDefs.Count);
      if p^ = Delimiter then
      begin
        Inc(p);
        SkipSpaceW(p);
      end;
      AddFieldDef;
    until p^ = #0;
  end;
  FFixedFieldCount := AFieldDefs.Count;
  if Assigned(FOnGetCustomFields) then
    FOnGetCustomFields(Self, AFieldDefs);
end;

procedure TQTextConverter.LoadFromText(ADataSet: TQDataSet;
  const AText: QStringW);
begin
  FText.Reset;
  FText.Cat(AText);
  LoadFromStream(ADataSet, nil);
end;

function TQTextConverter.ReadRecord(ARec: TQRecord): Boolean;
var
  ALine, AValue: QStringW;
  p: PWideChar;
  AIndex: Integer;
  ADef: TQFieldDef;
  AFieldVal: PQValue;
  AQuoted: Boolean;
  APrior: PWideChar;
begin
  Result := FTextPos < FText.Current;
  if Result then
  begin
    ALine := DecodeLineW(FTextPos);
    p := PWideChar(ALine);
    AIndex := 0;
    repeat
      AFieldVal := ARec.Values[AIndex].CurrentValue;
      AValue := DecodeTokenW(p, [Delimiter], Quoter, True, False);
      if p^ = Delimiter then
        Inc(p);
      ADef := ARec.Fields[AIndex] as TQFieldDef;
      if Assigned(FOnDecodeValue) then
        FOnDecodeValue(Self, ADef, AValue);
      if AValue = 'NULL' then
        AFieldVal.Reset
      else
      begin
        AFieldVal.TypeNeeded(ADef.ValueType);
        AFieldVal.AsString := DequotedStrW(AValue, Quoter);
      end;
      Inc(AIndex);
    until p^ = #0;
    if Assigned(FOnGetCustomValues) then
      FOnGetCustomValues(Self, ARec);
    DoProgress(csLoadData, (IntPtr(FTextPos) - IntPtr(FText.Start)) shr 1,
      (IntPtr(FText.Current) - IntPtr(FText.Start)) shr 1);
  end;
end;

procedure TQTextConverter.SaveFieldDefs(ADefs: TQFieldDefs);
var
  I: Integer;
begin
  inherited;
  if ActiveDataSet = 0 then
  begin
    if FirstIsFieldName then
    begin
      for I := 0 to ADefs.Count - 1 do
        FText.Cat(QuotedStrW(ADefs[I].Name, Quoter)).Cat(Delimiter);
      if ADefs.Count > 0 then
        FText.Back(1);
      FText.Cat(SLineBreak);
    end;
  end;
end;

function TQTextConverter.SaveToText(ADataSet: TQDataSet): String;
begin
  FSaveToText := True;
  try
    ADataSet.SaveToStream(nil, Self);
    Result := FText.Value;
  finally
    FSaveToText := False;
  end;
end;

function TQTextConverter.WriteRecord(ARec: TQRecord): Boolean;
var
  I: Integer;
  AValue: QStringW;

  procedure EncodeValue(AFieldVal: PQValue);
  begin
    if AFieldVal.IsNull then
      AValue := 'NULL'
    else if AFieldVal.ValueType = vdtStream then // 如果是字符串类型的流，则转换为字符串，否则使用二进制串
    begin
      case ARec.Fields[I].DataType of
        ftMemo, ftFmtMemo:
          begin
            AFieldVal.AsStream.Position := 0;
            AValue := QuotedStrW(LoadTextW(AFieldVal.AsStream, teAnsi), Quoter);
          end;
        ftWideMemo:
          begin
            AFieldVal.AsStream.Position := 0;
            AValue := QuotedStrW(LoadTextW(AFieldVal.AsStream,
              teUnicode16LE), Quoter);
          end
      else
        AValue := QuotedStrW(ARec.Values[I].CurrentValue.AsString, Quoter);
      end;
    end
    else
      AValue := QuotedStrW(ARec.Values[I].CurrentValue.AsString, Quoter);
  end;

begin
  Result := ActiveDataSet = 0;
  if Result then
  begin
    if Assigned(FOnEncodeValue) then
    begin
      for I := 0 to High(ARec.Values) do
      begin
        EncodeValue(ARec.Values[I].CurrentValue);
        FOnEncodeValue(Self, ARec.Fields[I] as TQFieldDef, AValue);
        FText.Cat(AValue).Cat(Delimiter);
      end;
    end
    else
    begin
      for I := 0 to High(ARec.Values) do
      begin
        EncodeValue(ARec.Values[I].CurrentValue);
        FText.Cat(AValue).Cat(Delimiter);
      end;
    end;
    if Length(ARec.Values) > 0 then
      FText.Back(1);
    FText.Cat(SLineBreak);
  end;
end;

end.
