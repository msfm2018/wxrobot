unit qconverter_stds;

interface

{
  2015.8.6
  =========
  * 修正了无法在早期版本编译的问题（感谢阿木报告）
  2015.8.5
  =========
  * 修正了 JSON 和 MsgPack 格式保存修改记录字段值修改内容顺序错位的问题（感谢奋斗报告）
  2015.7.22
  ---------
  * 修正了字段原始值不为空后，修改为空时显示乱码的问题（感谢ijia报告）
}
uses classes, sysutils, qstring, qmsgpack, qjson, qxml, db, qvalue, fmtbcd, qdb;

type
{$IF RTLVersion>=23}
  [ComponentPlatformsAttribute(pidWin32 or pidWin64{$IF RTLVersion>=24} or
    pidOSX32{$IFEND}{$IF RTLVersion>=25} or pidiOSSimulator or
    pidiOSDevice{$IFEND}{$IF RTLVersion>=26} or
    pidAndroid{$IFEND}{$IF RTLVersion>=29} or pidiOSDevice32 or
    pidiOSDevice64{$IFEND})]
{$IFEND}

  TQMsgPackConverter = class(TQConverter)
  protected
    FMsgPack, FDSRoot, FActiveDS, FActiveRecs: TQMsgPack;
    FRecordIndex: Integer;
    FLoadingDefs: TQFieldDefs;
    procedure BeforeExport; override;
    procedure SaveFieldDefs(ADefs: TQFieldDefs); override;
    function WriteRecord(ARec: TQRecord): Boolean; override;
    procedure AfterExport; override;
    // 导入接口
    procedure BeforeImport; override;
    procedure LoadFieldDefs(AFieldDefs: TQFieldDefs); override;
    function ReadRecord(ARec: TQRecord): Boolean; override;
    procedure AfterImport; override;
  end;
{$IF RTLVersion>=23}
  [ComponentPlatformsAttribute(pidWin32 or pidWin64{$IF RTLVersion>=24} or
    pidOSX32{$IFEND}{$IF RTLVersion>=25} or pidiOSSimulator or
    pidiOSDevice{$IFEND}{$IF RTLVersion>=26} or
    pidAndroid{$IFEND}{$IF RTLVersion>=29} or pidiOSDevice32 or
    pidiOSDevice64{$IFEND})]
{$IFEND}

  TQJsonConverter = class(TQConverter)
  private
  protected
    FJson, FDSRoot, FActiveDS, FActiveRecs: TQJson;
    FRecordIndex: Integer;
    FLoadingDefs: TQFieldDefs;
    FJsonText: PQStringW;
    procedure BeforeExport; override;
    procedure SaveFieldDefs(ADefs: TQFieldDefs); override;
    function WriteRecord(ARec: TQRecord): Boolean; override;
    procedure AfterExport; override;
    procedure BeforeImport; override;
    procedure LoadFieldDefs(AFieldDefs: TQFieldDefs); override;
    function ReadRecord(ARec: TQRecord): Boolean; override;
    procedure AfterImport; override;
    function GetAsJson: QStringW;
  public
    property AsJson:QStringW read GetAsJson;
  end;

  TQBinaryStreamHeader = packed record
    TypeFlag: Integer; // 标志位，宏为QDAC
    Size: Word; // 头部大小，也可以认为是代表版本号
    DSCount: Word; // 数据集的个数
    FirstDS: Int64; // 第一个数据集的偏移
  end;

  TQDSStreamHeader = packed record
    PriorDS: Int64; // 前一个数据集偏移
    NextDS: Int64; // 下一个数据集偏移
    Fields: Word; // 字段数
  end;

  TQDSStreamFieldHeader = packed record
    Count: Word; // 子结点数
    Precision: Word;
    Scale: Word;
    DBNo: Word;
    DBType: Integer;
    Flags: Integer;
    FieldSize: Integer;
  end;
{$IF RTLVersion>=23}
  [ComponentPlatformsAttribute(pidWin32 or pidWin64{$IF RTLVersion>=24} or
    pidOSX32{$IFEND}{$IF RTLVersion>=25} or pidiOSSimulator or
    pidiOSDevice{$IFEND}{$IF RTLVersion>=26} or
    pidAndroid{$IFEND}{$IF RTLVersion>=29} or pidiOSDevice32 or
    pidiOSDevice64{$IFEND})]
{$IFEND}

  TQBinaryConverter = class(TQConverter)
  protected
    FRecordIndex: Integer;
    FStartOffset, FPriorDSOffset: Int64;
    FStreamHeader: TQBinaryStreamHeader;
    FDSHeader: TQDSStreamHeader;
    FLoadingDefs: TQFieldDefs;
    procedure BeforeExport; override;
    procedure SaveFieldDefs(ADefs: TQFieldDefs); override;
    function WriteRecord(ARec: TQRecord): Boolean; override;
    procedure EndExport(AIndex: Integer); override;
    procedure AfterExport; override;
    // 导入接口
    procedure BeforeImport; override;
    procedure LoadFieldDefs(AFieldDefs: TQFieldDefs); override;
    function ReadRecord(ARec: TQRecord): Boolean; override;
    procedure AfterImport; override;
  end;

implementation

resourcestring
  SBadFileFormat = '不支持的数据格式，无法加载。';
  { TQMsgPackConverter }

procedure TQMsgPackConverter.AfterExport;
begin
  FMsgPack.SaveToStream(FStream);
  FreeObject(FMsgPack);
  inherited;
end;

procedure TQMsgPackConverter.AfterImport;
begin
  inherited;
  FreeObject(FMsgPack);
end;

procedure TQMsgPackConverter.BeforeExport;
begin
  inherited;
  FMsgPack := TQMsgPack.Create;
  FMsgPack.Add('Type').AsString := 'QDAC.DataSet';
  FDSRoot := FMsgPack.AddArray('DataSets');
end;

procedure TQMsgPackConverter.BeforeImport;
begin
  inherited;
  FMsgPack := TQMsgPack.Create;
  FMsgPack.LoadFromStream(FStream);
  if FMsgPack.ValueByName('Type', '') <> 'QDAC.DataSet' then
    raise EConvertError.Create(SBadFileFormat);
  FDSRoot := FMsgPack.ItemByName('DataSets');
  if FDSRoot.DataType <> mptArray then
    raise EConvertError.Create(SBadFileFormat);
  DataSetCount := FDSRoot.Count;
end;

procedure TQMsgPackConverter.LoadFieldDefs(AFieldDefs: TQFieldDefs);
var
  AItem: TQMsgPack;
  ADef: TQFieldDef;
  procedure LoadDefs(AParent: TQMsgPack; ADefs: TQFieldDefs);
  var
    I, AFlags: Integer;
    AChildren: TQMsgPack;
  begin
    if AParent = nil then
      raise EConvertError.Create(SBadFileFormat);
    I := 0;
    ADefs.BeginUpdate;
    try
      while I < AParent.Count do
      begin
        AItem := AParent[I];
        ADef := ADefs.AddFieldDef as TQFieldDef;
        ADef.Name := AItem.Name;
        ADef.DBType := AItem.IntByName('DBType', 0);
        ADef.DataType := TFieldType(AItem.IntByName('FieldType', 0));
        ADef.Size := AItem.IntByName('Size', 0);
        ADef.Precision := AItem.IntByName('Prec', 0);
        ADef.Scale := AItem.IntByName('Scale', 0);
        ADef.Schema := AItem.ValueByName('Schema', '');
        ADef.Database := AItem.ValueByName('Catalog', '');
        ADef.Table := AItem.ValueByName('Table', '');
        ADef.BaseName := AItem.ValueByName('Base', '');
        ADef.DBNo := AItem.IntByName('DBNo', 0);
        AFlags := AItem.IntByName('Flags', 0);
        // Flags Mask test
        if (AFlags and SCHEMA_ISINDEX) <> 0 then
          ADef.IsIndex := True;
        if (AFlags and SCHEMA_ISPRIMARY) <> 0 then
          ADef.IsPrimary := True;
        if (AFlags and SCHEMA_NULLABLE) <> 0 then
          ADef.Nullable := True;
        if (AFlags and SCHEMA_ISFIXED) <> 0 then
          ADef.IsFixed := True;
        if (AFlags and SCHEMA_AUTOINC) <> 0 then
          ADef.IsAutoInc := True;
        if (AFlags and SCHEMA_VISIBLE) <> 0 then
          ADef.Visible := True;
        if (AFlags and SCHEMA_READONLY) <> 0 then
          ADef.ReadOnly := True;
        if (AFlags and SCHEMA_UNNAMED) <> 0 then
          ADef.Attributes := ADef.Attributes + [faUnnamed];
        if (AFlags and SCHEMA_CALC) <> 0 then
          ADef.IsCalc := True;
        if (AFlags and SCHEMA_ARRAY) <> 0 then
          ADef.IsArray := True;
        if (AFlags and SCHEMA_INWHERE) <> 0 then
          ADef.InWhere := True;
        if (AFlags and SCHEMA_UNIQUE) <> 0 then
          ADef.IsUnique := True;
        AChildren := AItem.ItemByName('Items');
        if (AChildren <> nil) and AChildren.IsArray then
          LoadDefs(AChildren, ADef.ChildDefs as TQFieldDefs);
        Inc(I);
      end;
    finally
      ADefs.EndUpdate;
    end;
  end;

begin
  inherited;
  FActiveDS := FDSRoot[FActiveDataSet];
  FLoadingDefs := AFieldDefs;
  LoadDefs(FActiveDS.ItemByName('Fields'), AFieldDefs);
  FActiveRecs := FActiveDS.ItemByName('Records');
  FRecordIndex := -1;
end;

function TQMsgPackConverter.ReadRecord(ARec: TQRecord): Boolean;
var
  ARoot, AItem: TQMsgPack;
  AColVal: PQColumnValue;
  I, AIdx: Integer;
  AChanges: TQBits;
  procedure ReadValue(AValueItem: TQMsgPack; ADefs: TQFieldDefs; AIdx: Integer;
    var AValue: TQValue);
  var
    J: Integer;
    ADef: TQFieldDef;
  begin
    ADef := ADefs[AIdx] as TQFieldDef;
    if ADef.Count > 0 then
    begin
      if AValueItem.IsArray and (AValueItem.Count = ADef.Count) then
      begin
        AValue.ArrayNeeded(ADef.Count);
        for J := 0 to ADef.Count - 1 do
          ReadValue(AValueItem[J], ADef.ChildDefs as TQFieldDefs, J,
            AValue.Items[J]^);
      end
      else
        raise EConvertError.Create(SBadFileFormat);
    end
    else
    begin
      if AValueItem.IsNull then
        AValue.Reset
      else
      begin
        AValue.TypeNeeded(ADef.ValueType);
        case AValue.ValueType of
          vdtBoolean:
            AValue.Value.AsBoolean := AValueItem.AsBoolean;
          vdtFloat:
            AValue.Value.AsFloat := AValueItem.AsFloat;
          vdtInteger:
            AValue.Value.AsInteger := AValueItem.AsInteger;
          vdtInt64:
            AValue.Value.AsInt64 := AValueItem.AsInt64;
          vdtCurrency:
            AValue.Value.AsCurrency := AValueItem.AsFloat;
          vdtBcd:
            AValue.Value.AsBcd^ := DoubleToBcd(AValueItem.AsFloat);
          vdtGuid:
            AValue.Value.AsGuid^ := StringToGuid(AValueItem.AsString);
          vdtDateTime:
            AValue.Value.AsDateTime := AValueItem.AsDateTime;
          vdtInterval:
            AValue.Value.AsInt64 := AValueItem.AsInt64;
          vdtString:
            AValue.Value.AsString^ := AValueItem.AsString;
          vdtStream:
            AValueItem.StreamFromValue(AValue.Value.AsStream);
        end;
      end;
    end;
  end;

begin
  if FActiveRecs <> nil then
  begin
    Inc(FRecordIndex);
    Result := FRecordIndex < FActiveRecs.Count;
    if not Result then
      Exit;
    // 读取记录内容
    ARoot := FActiveRecs[FRecordIndex];
    ARec.Status := TUpdateStatus(ARoot.IntByName('Status', 0));
    if ARec.Status <> usInserted then
    begin
      AItem := ARoot.ItemByName('Old');
      if AItem = nil then
        raise EConvertError.Create(SBadFileFormat);
      for I := 0 to High(ARec.Values) do
        ReadValue(AItem[I], FLoadingDefs, I, ARec.Values[I].OldValue);
    end;
    if not(ARec.Status in [usUnmodified, usDeleted]) then // 已经删除和未修改的记录不需要新值
    begin
      if ARoot.HasChild('Changes', AItem) then
        AChanges.Bytes := AItem.AsBytes
      else
        AChanges.Size := 0;
      AItem := ARoot.ItemByName('New');
      if AItem = nil then
        raise EConvertError.Create(SBadFileFormat);
      AIdx := 0;
      for I := 0 to High(ARec.Values) do
      begin
        if AChanges[I] then
        begin
          AColVal := @ARec.Values[I];
          ReadValue(AItem[AIdx], FLoadingDefs, I, AColVal.NewValue);
          Inc(AIdx);
          if (ARec.Status = usInserted) or
            (AColVal.OldValue.ValueType <> AColVal.NewValue.ValueType) then
            AColVal.Changed := True
          else if not AColVal.OldValue.IsNull then
            AColVal.Changed := (FLoadingDefs[I] as TQFieldDef)
              .ValueComparor(@AColVal.OldValue, @AColVal.NewValue) <> 0
        end;
      end;
    end;
    DoProgress(csLoadData, FRecordIndex, FActiveRecs.Count);
  end
  else
    Result := False;
end;

procedure TQMsgPackConverter.SaveFieldDefs(ADefs: TQFieldDefs);
var
  AItem: TQMsgPack;
  ADef: TQFieldDef;
  procedure SaveDefs(AParent: TQMsgPack; AChildren: TQFieldDefs);
  var
    I: Integer;
  begin
    I := 0;
    while I < AChildren.Count do
    begin
      ADef := AChildren[I] as TQFieldDef;
      AItem := AParent.Add(ADef.Name);
      if ADef.DBType <> 0 then
        AItem.Add('DBType').AsInteger := ADef.DBType;
      AItem.Add('FieldType').AsInteger := Integer(ADef.DataType);
      if ADef.Size > 0 then
        AItem.Add('Size').AsInteger := ADef.Size;
      if ADef.Precision <> 0 then
        AItem.Add('Prec').AsInteger := ADef.Precision;
      if ADef.Scale > 0 then
        AItem.Add('Scale').AsInteger := ADef.Scale;
      if Length(ADef.Schema) > 0 then
        AItem.Add('Schema').AsString := ADef.Schema;
      if Length(ADef.Database) > 0 then
        AItem.Add('Catalog').AsString := ADef.Database;
      if Length(ADef.Table) > 0 then
        AItem.Add('Table').AsString := ADef.Table;
      if Length(ADef.BaseName) > 0 then
        AItem.Add('Base').AsString := ADef.BaseName;
      if ADef.DBNo > 0 then
        AItem.Add('DBNo').AsInteger := ADef.DBNo;
      AItem.Add('Flags').AsInteger := ADef.Flags;
      if ADef.Count > 0 then
        SaveDefs(AItem.AddArray('Items'), ADef.ChildDefs as TQFieldDefs);
      Inc(I);
    end;
  end;

begin
  inherited;
  FActiveDS := FDSRoot.Add;
  SaveDefs(FActiveDS.Add('Fields'), ADefs);
  if ExportRanges <> [merMeta] then
    FActiveRecs := FActiveDS.AddArray('Records');
end;

function TQMsgPackConverter.WriteRecord(ARec: TQRecord): Boolean;
var
  ARoot, AItem: TQMsgPack;
  I: Integer;
  AChanges: TQBits;
  procedure WriteValue(const AValue: TQValue);
  begin
    case AValue.ValueType of
      vdtNull:
        AItem.Add;
      vdtBoolean:
        AItem.Add.AsBoolean := AValue.Value.AsBoolean;
      vdtFloat, vdtDateTime:
        AItem.Add.AsFloat := AValue.Value.AsFloat;
      vdtInteger:
        AItem.Add.AsInteger := AValue.Value.AsInteger;
      vdtInt64, vdtInterval:
        AItem.Add.AsInt64 := AValue.Value.AsInt64;
      vdtCurrency:
        AItem.Add.AsFloat := AValue.Value.AsCurrency;
      vdtBcd:
        AItem.Add.AsFloat := BcdToDouble(AValue.Value.AsBcd^);
      vdtGuid:
        AItem.Add.AsString := GuidToString(AValue.Value.AsGuid^);
      vdtString:
        AItem.Add.AsString := AValue.Value.AsString^;
      vdtStream:
        AItem.Add.ValueFromStream(AValue.Value.AsStream, 0);
      vdtArray:
        raise Exception.Create('Unsupport Array type now.');
    end;
  end;

begin
  Result := True;
  if not Assigned(FActiveDS) then
    begin
    FActiveDS := FDSRoot.Add;
    FActiveRecs := FActiveDS.AddArray('Records');
    end;
  ARoot := FActiveRecs.Add;
  ARoot.Add('Status').AsInteger := Integer(ARec.Status);;
  if ARec.Status <> usInserted then
  begin
    AItem := ARoot.AddArray('Old');
    for I := 0 to High(ARec.Values) do
      WriteValue(ARec.Values[I].OldValue);
  end;
  if not(ARec.Status in [usUnmodified, usDeleted]) then // 已经删除和未修改的记录不需要新值
  begin
    AChanges.Size := Length(ARec.Values);
    for I := 0 to High(ARec.Values) do
      AChanges[I] := ARec.Values[I].Changed;
    ARoot.Add('Changes').AsBytes := AChanges.Bytes;
    AItem := ARoot.AddArray('New');
    for I := 0 to High(ARec.Values) do
      WriteValue(ARec.Values[I].NewValue);
  end;
end;

{ TQJsonConverter }

procedure TQJsonConverter.AfterExport;
begin
  if Assigned(FStream) then
    FJson.SaveToStream(FStream, teUtf8, True, False)
  else if Assigned(FJsonText) then
    FJsonText^:=FJson.Encode(false,true);
  FreeObject(FJson);
  inherited;
end;

procedure TQJsonConverter.AfterImport;
begin
  inherited;
  FreeObject(FJson);
end;

procedure TQJsonConverter.BeforeExport;
begin
  inherited;
  FJson := TQJson.Create;
  FJson.Add('Type').AsString := 'QDAC.DataSet';
  FDSRoot := FJson.AddArray('DataSets');
end;

procedure TQJsonConverter.BeforeImport;
begin
  inherited;
  FJson := TQJson.Create;
  FJson.LoadFromStream(FStream);
  if FJson.ValueByName('Type', '') <> 'QDAC.DataSet' then
    raise EConvertError.Create(SBadFileFormat);
  FDSRoot := FJson.ItemByName('DataSets');
  if FDSRoot.DataType <> jdtArray then
    raise EConvertError.Create(SBadFileFormat);
  DataSetCount := FDSRoot.Count;
end;

function TQJsonConverter.GetAsJson: QStringW;
begin
  if Assigned(FDataSet) then
  begin
    Result := '';
    FJsonText := @Result;
    FDataSet.SaveToStream(nil, Self);
    FJsonText := nil;
  end;
end;

procedure TQJsonConverter.LoadFieldDefs(AFieldDefs: TQFieldDefs);
var
  AItem: TQJson;
  ADef: TQFieldDef;
  procedure LoadDefs(AParent: TQJson; ADefs: TQFieldDefs);
  var
    I, AFlags: Integer;
    AChildren: TQJson;
  begin
    if AParent = nil then
      raise EConvertError.Create(SBadFileFormat);
    I := 0;
    ADefs.BeginUpdate;
    try
      while I < AParent.Count do
      begin
        AItem := AParent[I];
        ADef := ADefs.AddFieldDef as TQFieldDef;
        ADef.Name := AItem.Name;
        ADef.DBType := AItem.IntByName('DBType', 0);
        ADef.DBNo := AItem.IntByName('DBNo', 0);
        ADef.DataType := TFieldType(AItem.IntByName('FieldType', 0));
        ADef.Size := AItem.IntByName('Size', 0);
        ADef.Precision := AItem.IntByName('Prec', 0);
        ADef.Scale := AItem.IntByName('Scale', 0);
        ADef.Schema := AItem.ValueByName('Schema', '');
        ADef.Database := AItem.ValueByName('Catalog', '');
        ADef.Table := AItem.ValueByName('Table', '');
        ADef.BaseName := AItem.ValueByName('Base', '');
        AFlags := AItem.IntByName('Flags', 0);
        // Flags Mask test
        if (AFlags and SCHEMA_ISINDEX) <> 0 then
          ADef.IsIndex := True;
        if (AFlags and SCHEMA_ISPRIMARY) <> 0 then
          ADef.IsPrimary := True;
        if (AFlags and SCHEMA_NULLABLE) <> 0 then
          ADef.Nullable := True;
        if (AFlags and SCHEMA_ISFIXED) <> 0 then
          ADef.IsFixed := True;
        if (AFlags and SCHEMA_AUTOINC) <> 0 then
          ADef.IsAutoInc := True;
        if (AFlags and SCHEMA_VISIBLE) <> 0 then
          ADef.Visible := True;
        if (AFlags and SCHEMA_READONLY) <> 0 then
          ADef.ReadOnly := True;
        if (AFlags and SCHEMA_UNNAMED) <> 0 then
          ADef.Attributes := ADef.Attributes + [faUnnamed];
        if (AFlags and SCHEMA_CALC) <> 0 then
          ADef.IsCalc := True;
        if (AFlags and SCHEMA_ARRAY) <> 0 then
          ADef.IsArray := True;
        if (AFlags and SCHEMA_INWHERE) <> 0 then
          ADef.InWhere := True;
        if (AFlags and SCHEMA_UNIQUE) <> 0 then
          ADef.IsUnique := True;
        AChildren := AItem.ItemByName('Items');
        if (AChildren <> nil) and AChildren.IsArray then
          LoadDefs(AChildren, ADef.ChildDefs as TQFieldDefs);
        Inc(I);
      end;
    finally
      ADefs.EndUpdate;
    end;
  end;

begin
  inherited;
  FActiveDS := FDSRoot[FActiveDataSet];
  FLoadingDefs := AFieldDefs;
  LoadDefs(FActiveDS.ItemByName('Fields'), AFieldDefs);
  FActiveRecs := FActiveDS.ItemByName('Records');
  FRecordIndex := -1;
end;

function TQJsonConverter.ReadRecord(ARec: TQRecord): Boolean;
var
  ARoot, AItem: TQJson;
  AColVal: PQColumnValue;
  I, ANewIdx: Integer;
  AChanges: TQBits;
  procedure ReadValue(AValueItem: TQJson; ADefs: TQFieldDefs; AIdx: Integer;
    var AValue: TQValue);
  var
    J: Integer;
    ADef: TQFieldDef;
  begin
    ADef := ADefs[AIdx] as TQFieldDef;
    if ADef.Count > 0 then
    begin
      if AValueItem.IsArray and (AValueItem.Count = ADef.Count) then
      begin
        AValue.ArrayNeeded(ADef.Count);
        for J := 0 to ADef.Count - 1 do
          ReadValue(AValueItem[J], ADef.ChildDefs as TQFieldDefs, J,
            AValue.Items[J]^);
      end
      else
        raise EConvertError.Create(SBadFileFormat);
    end
    else
    begin
      if AValueItem.IsNull then
        AValue.Reset
      else
      begin
        AValue.TypeNeeded(ADef.ValueType);
        case AValue.ValueType of
          vdtBoolean:
            AValue.Value.AsBoolean := AValueItem.AsBoolean;
          vdtFloat:
            AValue.Value.AsFloat := AValueItem.AsFloat;
          vdtInteger:
            AValue.Value.AsInteger := AValueItem.AsInteger;
          vdtInt64:
            AValue.Value.AsInt64 := AValueItem.AsInt64;
          vdtCurrency:
            AValue.Value.AsCurrency := AValueItem.AsFloat;
          vdtBcd:
            AValue.Value.AsBcd^ := DoubleToBcd(AValueItem.AsFloat);
          vdtGuid:
            AValue.Value.AsGuid^ := StringToGuid(AValueItem.AsString);
          vdtDateTime:
            AValue.Value.AsDateTime := AValueItem.AsDateTime;
          vdtInterval:
            AValue.Value.AsInt64 := AValueItem.AsInt64;
          vdtString:
            AValue.Value.AsString^ := AValueItem.AsString;
          vdtStream:
            AValueItem.StreamFromValue(AValue.Value.AsStream);
        end;
      end;
    end;
  end;

begin
  if FActiveRecs <> nil then
  begin
    Inc(FRecordIndex);
    Result := FRecordIndex < FActiveRecs.Count;
    if not Result then
      Exit;
    // 读取记录内容
    ARoot := FActiveRecs[FRecordIndex];
    ARec.Status := TUpdateStatus(ARoot.IntByName('Status', 0));
    if ARec.Status <> usInserted then
    begin
      AItem := ARoot.ItemByName('Old');
      if AItem = nil then
        raise EConvertError.Create(SBadFileFormat);
      for I := 0 to High(ARec.Values) do
        ReadValue(AItem[I], FLoadingDefs, I, ARec.Values[I].OldValue);
    end;
    if not(ARec.Status in [usUnmodified, usDeleted]) then // 已经删除和未修改的记录不需要新值
    begin
      if ARoot.HasChild('Changes', AItem) then
        AChanges.Bytes := AItem.AsBytes
      else
        AChanges.Size := 0;
      AItem := ARoot.ItemByName('New');
      if AItem = nil then
        raise EConvertError.Create(SBadFileFormat);
      ANewIdx := 0;
      for I := 0 to High(ARec.Values) do
      begin
        if AChanges[I] then
        begin
          AColVal := @ARec.Values[I];
          ReadValue(AItem[ANewIdx], FLoadingDefs, I, AColVal.NewValue);
          Inc(ANewIdx);
          if (ARec.Status = usInserted) or
            (AColVal.OldValue.ValueType <> AColVal.NewValue.ValueType) then
            AColVal.Changed := True
          else if not AColVal.OldValue.IsNull then
            AColVal.Changed := (FLoadingDefs[I] as TQFieldDef)
              .ValueComparor(@AColVal.OldValue, @AColVal.NewValue) <> 0
        end;
      end;
    end;
    DoProgress(csLoadData, FRecordIndex, FActiveRecs.Count);
  end
  else
    Result := False;
end;

procedure TQJsonConverter.SaveFieldDefs(ADefs: TQFieldDefs);
var
  AItem: TQJson;
  ADef: TQFieldDef;
  I: Integer;

  procedure SaveDefs(AParent: TQJson; AChildren: TQFieldDefs);
  begin
    I := 0;
    while I < AChildren.Count do
    begin
      ADef := AChildren[I] as TQFieldDef;
      AItem := AParent.Add(ADef.Name);
      AItem.Add('FieldType').AsInteger := Integer(ADef.DataType);
      if ADef.Size > 0 then
        AItem.Add('Size').AsInteger := ADef.Size;
      if ADef.Precision <> 0 then
        AItem.Add('Prec').AsInteger := ADef.Precision;
      if ADef.Scale > 0 then
        AItem.Add('Scale').AsInteger := ADef.Scale;
      if Length(ADef.Schema) > 0 then
        AItem.Add('Schema').AsString := ADef.Schema;
      if Length(ADef.Database) > 0 then
        AItem.Add('Catalog').AsString := ADef.Database;
      if Length(ADef.Table) > 0 then
        AItem.Add('Table').AsString := ADef.Table;
      if Length(ADef.BaseName) > 0 then
        AItem.Add('Base').AsString := ADef.BaseName;
      if ADef.DBType <> 0 then
        AItem.Add('DBType').AsInteger := ADef.DBType;
      if ADef.DBNo > 0 then
        AItem.Add('DBNo').AsInteger := ADef.DBNo;
      AItem.Add('Flags').AsInteger := ADef.Flags;
      if ADef.Count > 0 then
        SaveDefs(AItem.AddArray('Items'), ADef.ChildDefs as TQFieldDefs);
      Inc(I);
    end;
  end;

begin
  inherited;
  FActiveDS := FDSRoot.Add;
  SaveDefs(FActiveDS.Add('Fields'), ADefs);
  if ExportRanges <> [merMeta] then
    FActiveRecs := FActiveDS.AddArray('Records');
end;

function TQJsonConverter.WriteRecord(ARec: TQRecord): Boolean;
var
  ARoot, AItem: TQJson;
  I: Integer;
  AChanges: TQBits;
  procedure WriteValue(const AValue: TQValue);
  begin
    case AValue.ValueType of
      vdtNull:
        AItem.Add;
      vdtBoolean:
        AItem.Add.AsBoolean := AValue.Value.AsBoolean;
      vdtFloat, vdtDateTime:
        AItem.Add.AsFloat := AValue.Value.AsFloat;
      vdtInteger:
        AItem.Add.AsInteger := AValue.Value.AsInteger;
      vdtInt64, vdtInterval:
        AItem.Add.AsInt64 := AValue.Value.AsInt64;
      vdtCurrency:
        AItem.Add.AsFloat := AValue.Value.AsCurrency;
      vdtBcd:
        AItem.Add.AsFloat := BcdToDouble(AValue.Value.AsBcd^);
      vdtGuid:
        AItem.Add.AsString := GuidToString(AValue.Value.AsGuid^);
      vdtString:
        AItem.Add.AsString := AValue.Value.AsString^;
      vdtStream:
        AItem.Add.ValueFromStream(AValue.Value.AsStream, 0);
      vdtArray:
        raise Exception.Create('Unsupport Array type now.');
    end;
  end;

begin
  if not Assigned(FActiveDS) then
    begin
    FActiveDS := FDSRoot.Add;
    FActiveRecs := FActiveDS.AddArray('Records');
    end;
  ARoot := FActiveRecs.Add('Row');
  ARoot.Add('Status').AsInteger := Integer(ARec.Status);
  if ARec.Status <> usInserted then
  begin
    AItem := ARoot.AddArray('Old');
    for I := 0 to High(ARec.Values) do
      WriteValue(ARec.Values[I].OldValue);
  end;
  if not(ARec.Status in [usUnmodified, usDeleted]) then // 已经删除和未修改的记录不需要新值
  begin
    AItem := ARoot.AddArray('New');
    AChanges.Size := Length(ARec.Values);
    for I := 0 to High(ARec.Values) do
      AChanges[I] := ARec.Values[I].Changed;
    ARoot.Add('Changes').AsBytes := AChanges.Bytes;
    for I := 0 to High(ARec.Values) do
      WriteValue(ARec.Values[I].NewValue);
  end;
  Result := True;
end;

{ TQBinaryConverter }

procedure TQBinaryConverter.AfterExport;
var
  AOffset: Int64;
begin
  AOffset := FStream.Position;
  FStream.Position := FStartOffset;
  FStream.WriteBuffer(FStreamHeader, SizeOf(FStreamHeader));
  FStream.Position := AOffset;
  inherited;
end;

procedure TQBinaryConverter.AfterImport;
begin
  inherited;

end;

procedure TQBinaryConverter.BeforeExport;
begin
  inherited;
  FStreamHeader.TypeFlag := $43414451;
  FStreamHeader.Size := SizeOf(FStreamHeader);
  FStreamHeader.DSCount := 0;
  FStreamHeader.FirstDS := FStreamHeader.Size;
  FStartOffset := FStream.Position;
  FStream.WriteBuffer(FStreamHeader, SizeOf(FStreamHeader));
end;

procedure TQBinaryConverter.BeforeImport;
begin
  inherited;
  FStartOffset := FStream.Position;
  FStream.ReadBuffer(FStreamHeader, SizeOf(FStreamHeader));
  if FStreamHeader.TypeFlag <> $43414451 then
    raise EStreamError.Create(SBadFileFormat);
  FStream.Position := FStartOffset + FStreamHeader.FirstDS;
  FDataSetCount := FStreamHeader.DSCount;
end;

procedure TQBinaryConverter.EndExport(AIndex: Integer);
begin
  FDSHeader.NextDS := FStream.Position;
  FStream.Position := FPriorDSOffset;
  FStream.WriteBuffer(FDSHeader, SizeOf(FDSHeader));
  FStream.Position := FDSHeader.NextDS;
end;

procedure TQBinaryConverter.LoadFieldDefs(AFieldDefs: TQFieldDefs);
var
  I: Integer;
  ANameBuf: array [0 .. 255] of Byte;
  function ReadName: QStringW;
  var
    ASize: Byte;
  begin
    FStream.ReadBuffer(ASize, SizeOf(Byte));
    if ASize > 0 then
    begin
      FStream.ReadBuffer(ANameBuf[0], ASize);
      Result := qstring.Utf8Decode(PQCharA(@ANameBuf[0]), ASize);
    end
    else
      SetLength(Result, 0);
  end;

  procedure LoadDef(ADef: TQFieldDef);
  var
    AHeader: TQDSStreamFieldHeader;
    J: Integer;
  begin
    FStream.ReadBuffer(AHeader, SizeOf(AHeader));
    ADef.Name := ReadName;
    ADef.Schema := ReadName;
    ADef.Database := ReadName;
    ADef.Table := ReadName;
    ADef.BaseName := ReadName;
    ADef.DBType := AHeader.DBType;
    ADef.Size := AHeader.FieldSize;
    ADef.DBNo := AHeader.DBNo;
    ADef.Precision := AHeader.Precision;
    ADef.Scale := AHeader.Scale;
    ADef.Flags := AHeader.Flags;
    for J := 0 to AHeader.Count - 1 do
      LoadDef(ADef.ChildDefs.AddFieldDef as TQFieldDef);
  end;

begin
  FStream.ReadBuffer(FDSHeader, SizeOf(FDSHeader));
  for I := 0 to FDSHeader.Fields - 1 do
    LoadDef(AFieldDefs.AddFieldDef as TQFieldDef);
end;

function TQBinaryConverter.ReadRecord(ARec: TQRecord): Boolean;
var
  I: Word;
  AStatus: TUpdateStatus;
  AMasks: TQBits; //
begin
  if FStream.Position < FDSHeader.NextDS then
  begin
    FStream.ReadBuffer(AStatus, SizeOf(TUpdateStatus));
    ARec.Status := AStatus;
    if ARec.Status <> usInserted then // 原记录、编辑或删除有老的记录
    begin
      AMasks.Size := Length(ARec.Values);
      FStream.ReadBuffer(AMasks.Bytes[0], Length(AMasks.Bytes));
      for I := 0 to High(ARec.Values) do
      begin
        if AMasks[I] then
          ARec.Values[I].OldValue.LoadFromStream(FStream);
      end;
    end;
    if ARec.Status in [usModified, usInserted] then // 插入或修改的记录新值
    begin
      AMasks.Size := Length(ARec.Values) shl 1;
      FStream.ReadBuffer(AMasks.Bytes[0], Length(AMasks.Bytes));
      for I := 0 to High(ARec.Values) do
      begin
        ARec.Values[I].Changed := AMasks[I shl 1];
        if AMasks[I shl 1 + 1] then
          ARec.Values[I].NewValue.LoadFromStream(FStream);
      end;
    end;
    Result := True;
    DoProgress(csLoadData, FStream.Position, FDSHeader.NextDS);
  end
  else
    Result := False;
end;

procedure TQBinaryConverter.SaveFieldDefs(ADefs: TQFieldDefs);
var
  I: Integer;
  AOffset: Int64;
  procedure WriteName(const AName: QStringW);
  var
    S: QStringA;
    L: Byte;
  begin
    S := qstring.Utf8Encode(AName);
    if S.Length > 255 then
      L := 255
    else
      L := S.Length;
    FStream.Write(L, SizeOf(Byte));
    FStream.WriteBuffer(PQCharA(S)^, L);
  end;
  procedure SaveDef(ADef: TQFieldDef);
  var
    AHeader: TQDSStreamFieldHeader;
    J: Integer;
  begin
    AHeader.Count := ADef.Count;
    AHeader.Precision := ADef.Precision;
    AHeader.Scale := ADef.Scale;
    AHeader.DBNo := ADef.DBNo;
    AHeader.DBType := ADef.DBType;
    AHeader.Flags := ADef.Flags;
    AHeader.FieldSize := ADef.Size;
    FStream.WriteBuffer(AHeader, SizeOf(AHeader));
    WriteName(ADef.Name);
    WriteName(ADef.Schema);
    WriteName(ADef.Database);
    WriteName(ADef.Table);
    WriteName(ADef.BaseName);
    for J := 0 to AHeader.Count - 1 do
      SaveDef(ADef.ChildDefs[J] as TQFieldDef);
  end;

begin
  AOffset := FStream.Position;
  if FPriorDSOffset <> 0 then
  begin
    FStream.Position := FPriorDSOffset;
    FDSHeader.NextDS := AOffset;
    FStream.WriteBuffer(FDSHeader, SizeOf(FDSHeader));
    FStream.Position := AOffset;
    FPriorDSOffset := AOffset;
  end
  else
    FPriorDSOffset := FStream.Position;
  FDSHeader.PriorDS := FPriorDSOffset;
  FDSHeader.NextDS := 0;
  FDSHeader.Fields := ADefs.Count;
  FStream.WriteBuffer(FDSHeader, SizeOf(FDSHeader));
  Inc(FStreamHeader.DSCount);
  for I := 0 to ADefs.Count - 1 do
  begin
    SaveDef(ADefs[I] as TQFieldDef);
  end;
end;

function TQBinaryConverter.WriteRecord(ARec: TQRecord): Boolean;
var
  I: Word;
  AMask: TQBits; // 每个字段占1（原始记录）或2（新记录）位，分别标记 是否为空，是否变更
begin
  FStream.Write(ARec.Status, SizeOf(TUpdateStatus));
  if ARec.Status <> usInserted then
  begin
    // 原始记录的掩码只需要记录是否为空即可
    AMask.Size := Length(ARec.Values);
    for I := 0 to High(ARec.Values) do
      AMask[I] := not ARec.Values[I].OldValue.IsNull;
    FStream.Write(AMask.Bytes[0], Length(AMask.Bytes));
    for I := 0 to High(ARec.Values) do
    begin
      if not ARec.Values[I].OldValue.IsNull then
        ARec.Values[I].OldValue.SaveToStream(FStream);
    end;
  end;
  if ARec.Status in [usModified, usInserted] then // 插入或修改的记录新值
  begin
    // 新记录需要一个额外的标记为来标记是否变更
    AMask.Size := Length(ARec.Values) shl 1;
    for I := 0 to High(ARec.Values) do
    begin
      AMask[I shl 1] := ARec.Values[I].Changed;
      AMask[(I shl 1) + 1] := not ARec.Values[I].NewValue.IsNull;
    end;
    FStream.Write(AMask.Bytes[0], Length(AMask.Bytes));
    for I := 0 to High(ARec.Values) do
    begin
      if ARec.Values[I].Changed and (not ARec.Values[I].NewValue.IsNull) then
        ARec.Values[I].NewValue.SaveToStream(FStream);
    end;
  end;
  Result := True;
end;

end.
