unit qconverter_adoxml;

interface

{$I qdac.inc}

uses classes, sysutils, db, qdb, qvalue, qstring, qxml;

{
  2015.9.9
  ========
  * 修正了导出时日期时间类型错误的写成 dateTime 的问题（AK47报告）
}
type
  TQADOXMLConverter = class(TQConverter)
  protected
    FXML, FRootNode, FDataRoot: TQXMLNode;
    FRowIndex: Integer;
    FFieldIndexes: TStringList;
    // 导入
    procedure BeforeImport; override;
    procedure BeginImport(AIndex: Integer); override;
    procedure LoadFieldDefs(ADefs: TQFieldDefs); override;
    function ReadRecord(ARec: TQRecord): Boolean; override;
    procedure EndImport(AIndex: Integer); override;
    procedure AfterImport; override;
    // 导出
    procedure BeforeExport; override;
    procedure BeginExport(AIndex: Integer); override;
    procedure SaveFieldDefs(ADefs: TQFieldDefs); override;
    function WriteRecord(ARec: TQRecord): Boolean; override;
    procedure EndExport(AIndex: Integer); override;
    procedure AfterExport; override;
  end;

implementation

resourcestring
  SBadXMLFormat = '指定的 XML 文件格式无效。';
  SUnsupportType = '不支持的数据类型 %s 。';
  { TQADOXMLConverter }

procedure TQADOXMLConverter.AfterExport;
begin
  inherited;
  FXML.SaveToStream(FStream);
  FreeAndNil(FFieldIndexes);
  FreeAndNil(FXML);
end;

procedure TQADOXMLConverter.AfterImport;
begin
  inherited;
  FreeAndNil(FFieldIndexes);
  FreeAndNil(FXML);
end;

procedure TQADOXMLConverter.BeforeExport;
begin
  inherited;
  FXML := TQXMLNode.Create;
  FFieldIndexes := TStringList.Create;
  FFieldIndexes.Sorted := True;
  FRootNode := FXML.AddNode('xml');
  FRootNode.Attrs.Add('xmlns:s', 'uuid:BDC6E3F0-6DA3-11d1-A2A3-00AA00C14882');
  FRootNode.Attrs.Add('xmlns:dt', 'uuid:C2F41010-65B3-11d1-A29F-00AA00C14882');
  FRootNode.Attrs.Add('xmlns:rs', 'urn:schemas-microsoft-com:rowset');
  FRootNode.Attrs.Add('xmlns:z', '#RowsetSchema');
end;

procedure TQADOXMLConverter.BeforeImport;
begin
  inherited;
  FXML := TQXMLNode.Create;
  FXML.LoadFromStream(FStream);
  FFieldIndexes := TStringList.Create;
  FFieldIndexes.Sorted := True;
  if FXML.HasChild('xml', FRootNode) then
  begin
    if FRootNode.Attrs.ValueByName('xmlns:s', '') <> 'uuid:BDC6E3F0-6DA3-11d1-A2A3-00AA00C14882'
    then
      raise QException.Create(SBadXMLFormat);
  end
  else
    raise QException.Create(SBadXMLFormat);;
end;

procedure TQADOXMLConverter.BeginExport(AIndex: Integer);
begin
  inherited;

end;

procedure TQADOXMLConverter.BeginImport(AIndex: Integer);
begin
  inherited;

end;

procedure TQADOXMLConverter.EndExport(AIndex: Integer);
begin
  inherited;

end;

procedure TQADOXMLConverter.EndImport(AIndex: Integer);
begin
  inherited;

end;

procedure TQADOXMLConverter.LoadFieldDefs(ADefs: TQFieldDefs);
var
  ARoot, ANode: TQXMLNode;
  ADef: TQFieldDef;
  I: Integer;
  S: QStringW;
begin
  if (ActiveDataSet = 0) and FRootNode.HasChild('s:Schema\s:ElementType', ARoot)
  then
  // 只能支持1个数据集，多余的数据集将被忽略
  begin
    try
      for I := 0 to ARoot.Count - 1 do
      begin
        ANode := ARoot[I]; //
        if ANode.Name <> 's:AttributeType' then
          Exit;
        ADef := ADefs.AddFieldDef as TQFieldDef;
        ADef.Name := ANode.Attrs.ValueByName('name');
        if (Length(ADef.Name) = 0) and (ANode.Attrs.ItemByName('rs:name') <> nil)
        then
          ADef.Name := ANode.Attrs.ValueByName('rs:name');
        FFieldIndexes.AddObject(ADef.Name, TObject(I));
        ADef.Schema := ANode.Attrs.ValueByName('rs:baseschema');
        ADef.Database := ANode.Attrs.ValueByName('rs:basecatalog');
        ADef.Table := ANode.Attrs.ValueByName('rs:basetable');
        ADef.BaseName := ANode.Attrs.ValueByName('rs:basecolumn');
        if ANode.Attrs.BoolByName('rs:autoincrement') then
          ADef.IsAutoInc := True;
        if ANode.Attrs.BoolByName('rs:keycolumn') then
          ADef.IsPrimary := True;
        if ANode.Attrs.BoolByName('rs:nullable') then
          ADef.Nullable := True;
        ADef.ReadOnly := not ANode.Attrs.BoolByName('rs:writeunknown');
        ADef.DBNo := ANode.Attrs.IntByName('rs:number');
        if ANode.HasChild('s:datatype', ANode) then
        begin
          S := LowerCase(ANode.Attrs.ValueByName('dt:type'));
          if S = 'string' then
          begin
            if ANode.Attrs.BoolByName('rs:long') then
              ADef.DBType := SQL_WIDETEXT
            else
            begin
              if ANode.Attrs.BoolByName('rs:fixedlength') then
                ADef.DBType := SQL_WIDECHAR
              else
                ADef.DBType := SQL_WIDEVARCHAR;
              ADef.Size := ANode.Attrs.IntByName('dt:maxLength');
            end;
          end
          else if S = 'i1' then
            ADef.DBType := SQL_TINYINT
          else if S = 'ui1' then
            ADef.DBType := SQL_BYTE
          else if S = 'i2' then
            ADef.DBType := SQL_SMALLINT
          else if S = 'ui2' then
            ADef.DBType := SQL_WORD
          else if (S = 'i4') or (S = 'int') then
            ADef.DBType := SQL_INTEGER
          else if S = 'ui4' then
            ADef.DBType := SQL_DWORD
          else if S = 'i8' then
            ADef.DBType := SQL_INT64
          else if S = 'boolean' then
            ADef.DBType := SQL_BOOLEAN
          else if S = 'r4' then
            ADef.DBType := SQL_SINGLE
          else if S = 'r8' then
            ADef.DBType := SQL_FLOAT
          else if (S = 'numeric') or (S = 'number') then
          begin
            if ANode.Attrs.ValueByName('rs:dbtype') = 'currency' then
            begin
              if ANode.Attrs.IntByName('rs:precision') = 10 then
                ADef.DBType := SQL_SMALLMONEY
              else
                ADef.DBType := SQL_MONEY;
            end
            else
            begin
              ADef.DBType := SQL_NUMERIC;
              ADef.Precision := ANode.Attrs.IntByName('rs:precision');
              ADef.Scale := ANode.Attrs.IntByName('rs:scale');
            end
          end
          else if S = 'date' then
            ADef.DBType := SQL_DATE
          else if S = 'time' then
            ADef.DBType := SQL_TIME
          else if S = 'datetime' then
          begin
            if ANode.Attrs.IntByName('rs:precison') = 16 then
              ADef.DBType := SQL_SMALLDATETIME
            else
              ADef.DBType := SQL_DATETIME;
          end
          else if S = 'bin.hex' then
          begin
            if ANode.Attrs.BoolByName('rs:long') then
              ADef.DBType := SQL_LARGEOBJECT
            else
            begin
              if ANode.Attrs.BoolByName('rs:fixedlength') then
                ADef.DBType := SQL_BINARY
              else
                ADef.DBType := SQL_VARBINARY;
              ADef.Size := ANode.Attrs.IntByName('dt:maxLength');
            end;
          end
          else if S = 'uuid' then
            ADef.DBType := SQL_UUID
          else
            raise QException.CreateFmt(SUnsupportType, [S]);
        end;
      end;
    finally
      FDataRoot := FRootNode.ItemByName('rs:data');
      FRowIndex := 0;
    end;
  end
  else
    FDataRoot := nil;
end;

function TQADOXMLConverter.ReadRecord(ARec: TQRecord): Boolean;
var
  ARow: TQXMLNode;
  procedure LoadOldValues;
  var
    I: Integer;
    AFieldIdx: Integer;
    Attr: TQXMLAttr;
  begin
    for I := 0 to ARow.Attrs.Count - 1 do
    begin
      Attr := ARow.Attrs[I];
      if FFieldIndexes.Find(Attr.Name, AFieldIdx) then
      begin
        AFieldIdx := Integer(FFieldIndexes.Objects[AFieldIdx]);
        ARec.Values[AFieldIdx].OldValue.TypeNeeded
          ((ARec.Fields[AFieldIdx] as TQFieldDef).ValueType);
        ARec.Values[AFieldIdx].OldValue.AsString := Attr.Value;
      end;
    end;
  end;

  procedure LoadNewValues;
  var
    I: Integer;
    AFieldIdx: Integer;
    Attr: TQXMLAttr;
  begin
    for I := 0 to ARow.Attrs.Count - 1 do
    begin
      Attr := ARow.Attrs[I];
      if FFieldIndexes.Find(Attr.Name, AFieldIdx) then
      begin
        AFieldIdx := Integer(FFieldIndexes.Objects[AFieldIdx]);
        ARec.Values[AFieldIdx].NewValue.TypeNeeded
          ((ARec.Fields[AFieldIdx] as TQFieldDef).ValueType);
        ARec.Values[AFieldIdx].NewValue.AsString := Attr.Value;
        ARec.Values[AFieldIdx].Changed := True;
      end;
    end;
  end;

begin
  Result := True;
  if Assigned(FDataRoot) and (FRowIndex < FDataRoot.Count) then
  begin
    ARow := FDataRoot[FRowIndex];
    Inc(FRowIndex);
    if ARow.Name = 'z:row' then
    begin
      ARec.Status := usUnmodified;
      LoadOldValues
    end
    else if ARow.Name = 'rs:insert' then
    begin
      ARec.Status := usInserted;
      ARow := ARow.ItemByName('z:row');
      LoadNewValues;
    end
    else if ARow.Name = 'rs:delete' then
    begin
      ARec.Status := usDeleted;
      ARow := ARow.ItemByName('z:row');
      LoadOldValues;
    end
    else if ARow.Name = 'rs:update' then
    begin
      ARec.Status := usModified;
      ARow := ARow.ItemByName('z:row');
      LoadNewValues;
      ARow := ARow.Parent.ItemByPath('rs:original\z:row');
      LoadOldValues;
    end;
    DoProgress(csLoadData, FRowIndex, FDataRoot.Count);
  end
  else
    Result := False;
end;

procedure TQADOXMLConverter.SaveFieldDefs(ADefs: TQFieldDefs);
var
  ARoot, ANode: TQXMLNode;
  ADef: TQFieldDef;
  I: Integer;
begin
  inherited;
  if ActiveDataSet = 0 then // 只能支持1个数据集，多余的数据集将被忽略
  begin
    ARoot := FRootNode.AddNode('s:Schema');
    ARoot.Attrs.Add('id', 'RowsetSchema');
    ARoot := ARoot.AddNode('s:ElementType');
    ARoot.Attrs.Add('rs:updatable', 'true');
    ARoot.Attrs.Add('content', 'eltOnly');
    ARoot.Attrs.Add('name', 'row');
    for I := 0 to ADefs.Count - 1 do
    begin
      ADef := ADefs[I] as TQFieldDef;
      ANode := ARoot.AddNode('s:AttributeType');
      ANode.Attrs.Add('name', ADef.Name);
      if Length(ADef.Schema) > 0 then
        ANode.Attrs.Add('rs:baseschema', ADef.Schema);
      if Length(ADef.Database) > 0 then
        ANode.Attrs.Add('rs:basecatalog', ADef.Database);
      if Length(ADef.Table) <> 0 then
        ANode.Attrs.Add('rs:basetable', ADef.Table);
      if Length(ADef.BaseName) > 0 then
        ANode.Attrs.Add('rs:basecolumn', ADef.BaseName);
      if ADef.IsAutoInc then
        ANode.Attrs.Add('rs:autoincrement', 'true');
      if ADef.IsPrimary then
        ANode.Attrs.Add('rs:keycolumn', 'true');
      if ADef.Nullable then
        ANode.Attrs.Add('rs:nullable', 'true');
      if not ADef.ReadOnly then
        ANode.Attrs.Add('rs:writeunknown', 'true');
      ANode.Attrs.Add('rs:number').AsInteger := ADef.DBNo;
      ANode := ANode.AddNode('s:datatype');
      // 保存类型信息
      case ADef.DataType of
        ftFixedChar, ftFixedWideChar, ftString, ftWideString, ftMemo, ftFmtMemo,
          ftWideMemo:
          begin
            ANode.Attrs.Add('dt:type', 'string');
            if ADef.DataType in [ftMemo, ftFmtMemo, ftWideMemo] then
            begin
              ANode.Attrs.Add('dt:maxLength', '2147483647');
              ANode.Attrs.Add('rs:long', 'true');
            end
            else
              ANode.Attrs.Add('dt:maxLength').AsInteger := ADef.Size;
            ANode.Attrs.Add('rs:dbtype', 'str');
          end;
{$IF RTLVersion>19}
        ftShortint:
          begin
            ANode.Attrs.Add('dt:type', 'i1');
            ANode.Attrs.Add('dt:maxLength', '1');
            ANode.Attrs.Add('rs:precision', '3');
            ANode.Attrs.Add('rs:fixedlength', 'true');
          end;
        ftByte:
          begin
            ANode.Attrs.Add('dt:type', 'ui1');
            ANode.Attrs.Add('dt:maxLength', '1');
            ANode.Attrs.Add('rs:precision', '3');
            ANode.Attrs.Add('rs:fixedlength', 'true');
          end;
{$IFEND}
        ftSmallint:
          begin
            ANode.Attrs.Add('dt:type', 'i2');
            ANode.Attrs.Add('dt:maxLength', '2');
            ANode.Attrs.Add('rs:precision', '5');
            ANode.Attrs.Add('rs:fixedlength', 'true');
          end;
        ftInteger:
          begin
            ANode.Attrs.Add('dt:type', 'int');
            ANode.Attrs.Add('dt:maxLength', '4');
            ANode.Attrs.Add('rs:precision', '10');
            ANode.Attrs.Add('rs:fixedlength', 'true');
          end;
        ftWord:
          begin
            ANode.Attrs.Add('dt:type', 'ui2');
            ANode.Attrs.Add('dt:maxLength', '2');
            ANode.Attrs.Add('rs:precision', '5');
            ANode.Attrs.Add('rs:fixedlength', 'true');
          end;
        ftBoolean:
          begin
            ANode.Attrs.Add('dt:type', 'boolean');
            ANode.Attrs.Add('dt:maxLength', '2');
            ANode.Attrs.Add('rs:fixedlength', 'true');
          end;
        ftFloat{$IF RTLVersion>19}, ftExtended{$IFEND}:
          begin
            ANode.Attrs.Add('dt:type', 'r8');
            ANode.Attrs.Add('dt:maxLength', '8');
            ANode.Attrs.Add('rs:precision', '15');
          end;
        ftCurrency:
          begin
            if ADef.DBType = SQL_SMALLMONEY then
            begin
              ANode.Attrs.Add('dt:type', 'numeric');
              ANode.Attrs.Add('rs:dbtype', 'currency');
              ANode.Attrs.Add('dt:maxLength', '8');
              ANode.Attrs.Add('rs:precision', '10');
            end
            else
            begin
              ANode.Attrs.Add('dt:type', 'numeric');
              ANode.Attrs.Add('rs:dbtype', 'currency');
              ANode.Attrs.Add('dt:maxLength', '8');
              ANode.Attrs.Add('rs:precision', '19');
            end;
          end;
        ftBCD, ftFMTBcd:
          begin
            ANode.Attrs.Add('dt:type', 'numeric');
            ANode.Attrs.Add('dt:maxLength', '19');
            ANode.Attrs.Add('rs:scale').AsInteger := ADef.Scale;
            ANode.Attrs.Add('rs:precision').AsInteger := ADef.Precision;
          end;
        ftDate:
          begin
            ANode.Attrs.Add('dt:type', 'date');
            ANode.Attrs.Add('rs:dbtype', 'timestamp');
            ANode.Attrs.Add('dt:maxLength', '16');
            ANode.Attrs.Add('rs:scale', '3');
            ANode.Attrs.Add('rs:precision', '23');
          end;
        ftTime:
          begin
            ANode.Attrs.Add('dt:type', 'time');
            ANode.Attrs.Add('rs:dbtype', 'timestamp');
            ANode.Attrs.Add('dt:maxLength', '16');
            ANode.Attrs.Add('rs:scale', '3');
            ANode.Attrs.Add('rs:precision', '23');
          end;
        ftDateTime, ftOraTimeStamp{$IF RTLVersion>20},
          ftTimeStampOffset{$IFEND}:
          begin
            if ADef.DBType = SQL_SMALLDATETIME then
            begin
              ANode.Attrs.Add('dt:type', 'datetime');
              ANode.Attrs.Add('rs:dbtype', 'timestamp');
              ANode.Attrs.Add('dt:maxLength', '16');
              ANode.Attrs.Add('rs:scale', '0');
              ANode.Attrs.Add('rs:precision', '16');
            end
            else
            begin
              ANode.Attrs.Add('dt:type', 'datetime');
              ANode.Attrs.Add('rs:dbtype', 'timestamp');
              ANode.Attrs.Add('dt:maxLength', '16');
              ANode.Attrs.Add('rs:scale', '3');
              ANode.Attrs.Add('rs:precision', '23');
            end;
          end;
        ftBytes, ftVarBytes:
          begin
            ANode.Attrs.Add('dt:type', 'bin.hex');
            ANode.Attrs.Add('dt:maxLength').AsInteger := ADef.Size;
            if ADef.DBType = SQL_BINARY then
              ANode.Attrs.Add('rs:fixedlength', 'true');
          end;
        ftAutoInc{$IF RTLVersion>19}, ftLongword{$IFEND}:
          begin
            ANode.Attrs.Add('dt:type', 'ui4');
            ANode.Attrs.Add('dt:maxLength', '4');
            ANode.Attrs.Add('rs:precision', '10');
            ANode.Attrs.Add('rs:fixedlength', 'true');
          end;
        ftBlob, ftGraphic, ftTypedBinary, ftOraBlob, ftOraClob:
          begin
            ANode.Attrs.Add('dt:type', 'bin.hex');
            ANode.Attrs.Add('dt:maxLength', '2147483647');
            ANode.Attrs.Add('rs:long', 'true');;
          end;
        ftLargeint:
          begin
            ANode.Attrs.Add('dt:type', 'i8');
            ANode.Attrs.Add('dt:maxLength', '8');
            ANode.Attrs.Add('rs:precision', '19');
            ANode.Attrs.Add('rs:fixedlength', 'true');
          end;
        ftGuid:
          begin
            ANode.Attrs.Add('dt:type', 'uuid');
            ANode.Attrs.Add('dt:maxLength', '16');
          end;
        ftTimeStamp:
          begin
            ANode.Attrs.Add('dt:type', 'bin.hex');
            ANode.Attrs.Add('dt:maxLength', '8');
            ANode.Attrs.Add('rs:fixedlength', 'true');
          end;
        ftOraInterval:
          begin
            ANode.Attrs.Add('dt:type', 'string');
            ANode.Attrs.Add('dt:maxLength', '30');
            ANode.Attrs.Add('rs:dbtype', 'str');
          end{$IF RTLVersion>20};
        ftSingle:
          begin
            ANode.Attrs.Add('dt:type', 'r4');
            ANode.Attrs.Add('dt:maxLength', '4');
            ANode.Attrs.Add('rs:precision', '7');
          end
{$IFEND}
      else
        raise QException.CreateFmt(SUnsupportType,
          [FieldTypeNames[ADef.DataType]]);
      end;
    end;
    ARoot.AddNode('s:extends').Attrs.Add('type', 'rs:rowbase');
    FDataRoot := FRootNode.Add('rs:data');
  end
  else
    FDataRoot := nil;
end;

function TQADOXMLConverter.WriteRecord(ARec: TQRecord): Boolean;
var
  ARow: TQXMLNode;
  procedure SaveValue(const AFieldName: QStringW; const AValue: TQValue);
  var
    D: Integer;
  begin
    if AValue.ValueType = vdtDateTime then
    begin
      D := Trunc(AValue.Value.AsDateTime);
      if D = 0 then // 日期部分为0
        ARow.Attrs.Add(AFieldName).AsString := FormatDateTime('hh:nn:ss.zzz',
          AValue.Value.AsDateTime)
      else if AValue.Value.AsDateTime - D < 1E-9 then // 时间部分为0
        ARow.Attrs.Add(AFieldName).AsString := FormatDateTime('yyyy-mm-dd',
          AValue.Value.AsDateTime)
      else
        ARow.Attrs.Add(AFieldName).AsString :=
          FormatDateTime('yyyy-mm-dd"T"hh:nn:ss.zzz', AValue.Value.AsDateTime);
    end
    else
      ARow.Attrs.Add(AFieldName).AsString := AValue.AsString;
  end;
  procedure SaveOldValues;
  var
    I: Integer;
  begin
    for I := 0 to High(ARec.Values) do
    begin
      if not ARec.Values[I].OldValue.IsNull then
        SaveValue(ARec.Fields[I].Name, ARec.Values[I].OldValue);
    end;
  end;
  procedure SaveNewValues;
  var
    I: Integer;
  begin
    for I := 0 to High(ARec.Values) do
    begin
      if not ARec.Values[I].NewValue.IsNull then
        SaveValue(ARec.Fields[I].Name, ARec.Values[I].NewValue);
    end;
  end;

begin
  if ActiveDataSet > 0 then
    Result := True
  else
  begin
    if not Assigned(FDataRoot) then
      FDataRoot := FRootNode.Add('rs:data');
    Result := False;
    case ARec.Status of
      usUnmodified:
        begin
          ARow := FDataRoot.AddNode('z:row');
          SaveOldValues;
        end;
      usModified:
        begin
          ARow := FDataRoot.AddNode('rs:update').AddNode('z:row');
          SaveNewValues;
          ARow := ARow.Parent.AddNode('rs:original').AddNode('z:row');
          SaveOldValues;
        end;
      usInserted:
        begin
          ARow := FDataRoot.AddNode('rs:insert').AddNode('z:row');
          SaveNewValues;
        end;
      usDeleted:
        begin
          ARow := FDataRoot.AddNode('rs:delete').AddNode('z:row');
          SaveOldValues;
        end;
    end;
  end;
end;

end.
