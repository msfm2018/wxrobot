unit qconverter_sql;

interface

uses qstring, qdb, qvalue, qmacros, qtimetypes, fmtbcd, classes, sysutils, db,
  math;

// SQL 导出转换器
type
  TQSQLConverter = class(TQConverter)
  private

  protected
    FAllAsInsert: Boolean;
    FText: TQStringCatHelperW;
    FExportEncoding: TTextEncoding;
    FIdentBegin, FIdentEnd: QStringW;
    FTableName: QStringW;
    FStatementEnd: QStringW;
    FInsertBegin: QStringW;
    FKeyWords: TStringList;
    FPrimaryKeyOnly: Boolean;
    FInsertTemplate: QStringW;
    FDeleteTemplate: QStringW;
    FUpdateTemplate: QStringW;
    FMacroStart: QCharW;
    FMacroEnd: QCharW;
    FMacros: TQMacroManager;
    FSavePoint: Integer;
    FWhereFields: array of TQFieldDef;
    function EncodeBinary(const p: PByte; L: Integer): QStringW;
      virtual; abstract;
    function EncodeDateTime(const v: TDateTime): QStringW; virtual;
    function EncodeBoolean(const v: Boolean): QStringW; virtual; abstract;
    function EncodeInterval(const v: TQInterval): QStringW; virtual;
    function QuotedIdent(S: QStringW): QStringW; virtual;
    function IsKeyword(const S: QStringW): Boolean;
    procedure AddKeyWords(const S: QStringW);
    procedure BeforeExport; override;
    procedure SaveFieldDefs(ADefs: TQFieldDefs); override;
    procedure BeginExport(AIndex: Integer); override;
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
    function GenSQL: QStringW;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    property SQL: QStringW read GenSQL;
  published
    property ExportEncoding: TTextEncoding read FExportEncoding
      write FExportEncoding; // 输出文件编码，默认UTF-8
    property AllAsInsert: Boolean read FAllAsInsert write FAllAsInsert;
    property PrimaryKeyOnly: Boolean read FPrimaryKeyOnly write FPrimaryKeyOnly;
    property InsertTemplate: QStringW read FInsertTemplate
      write FInsertTemplate;
    property UpdateTemplate: QStringW read FUpdateTemplate
      write FUpdateTemplate;
    property DeleteTemplate: QStringW read FDeleteTemplate
      write FDeleteTemplate;
    property MacroStart: QCharW read FMacroStart write FMacroStart;
    property MacroEnd: QCharW read FMacroEnd write FMacroEnd;
  end;
{$IF RTLVersion>=23}
  [ComponentPlatformsAttribute(pidWin32 or pidWin64{$IF RTLVersion>=24} or
    pidOSX32{$IFEND}{$IF RTLVersion>=25} or pidiOSSimulator or
    pidiOSDevice{$IFEND}{$IF RTLVersion>=26} or
    pidAndroid{$IFEND}{$IF RTLVersion>=29} or pidiOSDevice32 or
    pidiOSDevice64{$IFEND})]
{$IFEND}

  // MSSQL 脚本导出转换器
  TQMSSQLConverter = class(TQSQLConverter)
  protected
    function EncodeBinary(const p: PByte; L: Integer): QStringW; override;
    function EncodeBoolean(const v: Boolean): QStringW; override;
  public
    constructor Create(AOwner: TComponent); override;
  end;
{$IF RTLVersion>=23}
  [ComponentPlatformsAttribute(pidWin32 or pidWin64{$IF RTLVersion>=24} or
    pidOSX32{$IFEND}{$IF RTLVersion>=25} or pidiOSSimulator or
    pidiOSDevice{$IFEND}{$IF RTLVersion>=26} or
    pidAndroid{$IFEND}{$IF RTLVersion>=29} or pidiOSDevice32 or
    pidiOSDevice64{$IFEND})]
{$IFEND}

  // PostgreSQL 脚本导出转换器
  TQPgSQLConverter = class(TQSQLConverter)
  protected
    FCaseSensitive: Boolean;
    function EncodeBinary(const p: PByte; L: Integer): QStringW; override;
    function EncodeBoolean(const v: Boolean): QStringW; override;
    function EncodeInterval(const v: TQInterval): QStringW; override;
    function QuotedIdent(S: QStringW): QStringW; override;
  public
    constructor Create(AOwner: TComponent); override;
    property CaseSensitive: Boolean read FCaseSensitive write FCaseSensitive;
  end;
{$IF RTLVersion>=23}
  [ComponentPlatformsAttribute(pidWin32 or pidWin64{$IF RTLVersion>=24} or
    pidOSX32{$IFEND}{$IF RTLVersion>=25} or pidiOSSimulator or
    pidiOSDevice{$IFEND}{$IF RTLVersion>=26} or
    pidAndroid{$IFEND}{$IF RTLVersion>=29} or pidiOSDevice32 or
    pidiOSDevice64{$IFEND})]
{$IFEND}

  // MySQL 脚本导出转换器
  TQMySQLConverter = class(TQSQLConverter)
  protected
    function EncodeBinary(const p: PByte; L: Integer): QStringW; override;
    function EncodeBoolean(const v: Boolean): QStringW; override;
  public
    constructor Create(AOwner: TComponent); override;
  end;

implementation

resourcestring
  SSQLImportUnsupport = 'SQL 转换器不支持导入操作。';
  SSQLConverterMustExportMeta='SQL 转换器导出时必需包含 merMeta 选项以利用元数据生成脚本。';
  STooManyTables = '数据集内容来自多个不同的表，无法导出为脚本。';
  STableNameMissed = '数据集内容的来源表未定义，无法导出为脚本。';
  { TQSQLConverter }

procedure TQSQLConverter.AddKeyWords(const S: QStringW);
var
  p: PWideChar;
  AToken: QStringW;
const
  ADelimters: PWideChar = ',';
  ANullChar: WideChar = #0;
begin
  if Length(S) > 0 then
  begin
    p := PWideChar(S);
    FKeyWords.BeginUpdate;
    try
      while p^ <> #0 do
      begin
        AToken := DecodeTokenW(p, ADelimters, ANullChar, true, true);
        if Length(AToken) > 0 then
          FKeyWords.Add(UpperCase(AToken));
      end;
    finally
      FKeyWords.EndUpdate;
    end;
  end;
end;

procedure TQSQLConverter.AfterExport;
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
  if Assigned(FMacros) then
    FreeAndNil(FMacros);
  inherited;
end;

procedure TQSQLConverter.AfterImport;
begin
  inherited;

end;

procedure TQSQLConverter.BeforeExport;
begin
  inherited;
  FText.Reset;
  if (Length(FUpdateTemplate) > 0) or (Length(FDeleteTemplate) > 0) or
    (Length(FInsertTemplate) > 0) then
  begin
    FMacros := TQMacroManager.Create;
    FMacros.IgnoreCase := true;
  end;
  if not (merMeta in ExportRanges) then
    DatabaseError(SSQLConverterMustExportMeta,self);
end;

procedure TQSQLConverter.BeforeImport;
begin
  inherited;
  raise Exception.Create(SSQLImportUnsupport);
end;

procedure TQSQLConverter.BeginExport(AIndex: Integer);
begin
  inherited;

end;

procedure TQSQLConverter.BeginImport(AIndex: Integer);
begin
  inherited;

end;

constructor TQSQLConverter.Create(AOwner: TComponent);
begin
  inherited;
  FExportEncoding := teUtf8;
  FText := TQStringCatHelperW.Create;
  FIdentBegin := '"';
  FIdentEnd := '"';
  FStatementEnd := ';';
  FMacroStart := '{';
  FMacroEnd := '}';
  FKeyWords := TStringList.Create;
  FKeyWords.Sorted := true;
  FKeyWords.Duplicates := dupIgnore;
  AddKeyWords
    ('ABSOLUTE, ACTION, ADD, ADMIN, AFTER, AGGREGATE, ALIAS, ALL, ALLOCATE, ALTER,'
    + 'ANALYS, ANALYZ, AND, ANY, ARE, ARRAY, AS, ASC, ASSERTION, AT, AUTHORIZATION,'
    + 'AVG, BEFORE, BEGIN, BETWEEN, BINARY, BIT, BIT, BLOB, BOOLEAN, BOTH, BREADTH,'
    + 'BY, CALL, CASCADE, CASCADED, CASE, CAST, CATALOG, CHAR, CHARACTER, CHARACTER,'
    + 'CHAR, CHECK, CLASS, CLOB, CLOSE, COALESCE, COLLATE, COLLATION, COLUMN, COMMIT,'
    + 'COMPLETION, CONNECT, CONNECTION, CONSTRAINT, CONSTRAINTS, CONSTRUCTOR,' +
    'CONTINUE, CONVERT, CORRESPONDING, COUNT, CREATE, CROSS, CUBE, CURRENT, CURRENT,'
    + 'CURRENT, CURRENT, CURRENT, CURRENT, CURRENT, CURSOR, CYCLE, DATA, DATE, DAY,'
    + 'DEALLOCATE, DEC, DECIMAL, DECLARE, DEFAULT, DEFERRABLE, DEFERRED, DELETE,'
    + 'DEPTH, DEREF, DESC, DESCRIBE, DESCRIPTOR, DESTROY, DESTRUCTOR, DETERMINISTIC,'
    + 'DIAGNOSTICS, DICTIONARY, DISCONNECT, DISTINCT, D, DOMAIN, DOUBLE, DROP,'
    + 'DYNAMIC, EACH, ELSE, END, END, EQUALS, ESCAPE, EVERY, EXCEPT, EXCEPTION, EXEC,'
    + 'EXECUTE, EXISTS, EXTERNAL, EXTRACT, FALSE, FETCH, FIRST, FLOAT, FOR, FOREIGN,'
    + 'FOUND, FREE, FROM, FULL, FUNCTION, GENERAL, GET, GLOBAL, GO, GOTO, GRANT,'
    + 'GROUP, GROUPING, HAVING, HOST, HOUR, IDENTITY, IGNORE, ILIK, IMMEDIATE, IN,'
    + 'INDICATOR, INITIALIZE, INITIALLY, INNER, INOUT, INPUT, INSENSITIVE, INSERT,'
    + 'INT, INTEGER, INTERSECT, INTERVAL, INTO, IS, ISNUL, ISOLATION, ITERATE, JOIN,'
    + 'KEY, LANGUAGE, LARGE, LAST, LATERAL, LEADING, LEFT, LESS, LEVEL, LIKE, LIMIT,'
    + 'LOCAL, LOCALTIME, LOCALTIMESTAMP, LOCATOR, LOWER, MAP, MATCH, MAX, MIN, MINUTE,'
    + 'MODIFIES, MODIFY, MODULE, MONTH, NAMES, NATIONAL, NATURAL, NCHAR, NCLOB, NEW,'
    + 'NEXT, NO, NONE, NOT, NOTNUL, NULL, NULLIF, NUMERIC, OBJECT, OCTET, OF, OFF,'
    + 'OFFSE, OLD, ON, ONLY, OPEN, OPERATION, OPTION, OR, ORDER, ORDINALITY, OUT,'
    + 'OUTER, OUTPUT, OVERLAPS, PAD, PARAMETER, PARAMETERS, PARTIAL, PATH, PLACIN,'
    + 'POSITION, POSTFIX, PRECISION, PREFIX, PREORDER, PREPARE, PRESERVE, PRIMARY,'
    + 'PRIOR, PRIVILEGES, PROCEDURE, PUBLIC, READ, READS, REAL, RECURSIVE, REF,'
    + 'REFERENCES, REFERENCING, RELATIVE, RESTRICT, RESULT, RETURN, RETURNS, REVOKE,'
    + 'RIGHT, ROLE, ROLLBACK, ROLLUP, ROUTINE, ROW, ROWS, SAVEPOINT, SCHEMA, SCOPE,'
    + 'SCROLL, SEARCH, SECOND, SECTION, SELECT, SEQUENCE, SESSION, SESSION, SET, SETS,'
    + 'SIMILA, SIZE, SMALLINT, SOME, SPACE, SPECIFIC, SPECIFICTYPE, SQL, SQLCODE,'
    + 'SQLERROR, SQLEXCEPTION, SQLSTATE, SQLWARNING, START, STATE, STATEMENT, STATIC,'
    + 'STRUCTURE, SUBSTRING, SUM, SYSTEM, TABLE, TEMPORARY, TERMINATE, THAN, THEN,'
    + 'TIME, TIMESTAMP, TIMEZONE, TIMEZONE, TO, TRAILING, TRANSACTION, TRANSLATE,'
    + 'TRANSLATION, TREAT, TRIGGER, TRIM, TRUE, UNDER, UNION, UNIQUE, UNKNOWN, UNNEST,'
    + 'UPDATE, UPPER, USAGE, USER, USING, VALUE, VALUES, VARCHAR, VARIABLE, VARYING,'
    + 'VERBOS, VIEW, WHEN, WHENEVER, WHERE, WITH, WITHOUT, WORK, WRITE, YEAR, ZONE');
end;

destructor TQSQLConverter.Destroy;
begin
  FreeObject(FText);
  FreeObject(FKeyWords);
  inherited;
end;

function TQSQLConverter.EncodeDateTime(const v: TDateTime): QStringW;
var
  D: Integer;
begin
  D := Trunc(v);
  if D = 0 then
    Result := '''' + FormatDateTime('hh:nn:ss.zzz', v) + ''''
  else if IsZero(v - D) then
    Result := '''' + FormatDateTime('yyyy-mm-dd', v) + ''''
  else
    Result := '''' + FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz', v) + '''';
end;

function TQSQLConverter.EncodeInterval(const v: TQInterval): QStringW;
begin
  Result := QuotedStrW(v.AsString, '''');
end;

procedure TQSQLConverter.EndExport(AIndex: Integer);
begin
  inherited;

end;

procedure TQSQLConverter.EndImport(AIndex: Integer);
begin
  inherited;

end;

function TQSQLConverter.GenSQL: QStringW;
var
  AStream: TMemoryStream;
  AEncoding: TTextEncoding;
begin
  AEncoding := FExportEncoding;
  AStream := TMemoryStream.Create;
  try
    ExportEncoding := teUnicode16LE;
    FDataSet.SaveToStream(AStream, Self);
    AStream.Position := 0;
    Result := LoadTextW(AStream, teUnicode16LE);
  finally
    FreeObject(AStream);
    FExportEncoding := AEncoding;
  end;
end;

function TQSQLConverter.IsKeyword(const S: QStringW): Boolean;
var
  AIdx: Integer;
begin
  Result := FKeyWords.Find(UpperCase(S), AIdx);
end;

procedure TQSQLConverter.LoadFieldDefs(AFieldDefs: TQFieldDefs);
begin
  inherited;

end;

function TQSQLConverter.QuotedIdent(S: QStringW): QStringW;
begin
  if IsKeyword(S) then
    Result := FIdentBegin + S + FIdentEnd
  else
  begin
    Result := S;
    if ContainsCharW(S, ' ') then
      Result := FIdentBegin + S + FIdentEnd;
  end;
end;

function TQSQLConverter.ReadRecord(ARec: TQRecord): Boolean;
begin
  Result := False;
end;

procedure TQSQLConverter.SaveFieldDefs(ADefs: TQFieldDefs);
var
  I, J, ACount: Integer;
  ADef: TQFieldDef;
  Added: Boolean;
  procedure FetchTableName;
  begin
    I := 0;
    FTableName := '';
    while I < ADefs.Count do
    begin
      ADef := ADefs[I] as TQFieldDef;
      if Length(ADef.Table) > 0 then
      begin
        if Length(FTableName) = 0 then
          FTableName := ADef.Table
        else if FTableName <> ADef.Table then
          raise QException.Create(STooManyTables);
      end;
      Inc(I);
    end;
    if Length(FTableName) = 0 then
      raise QException.Create(STableNameMissed);
  end;

begin
  inherited;
  FetchTableName;
  if Assigned(FMacros) then
  begin
    FMacros.Push('TableName', FTableName);
    FMacros.Push('TableName.Quoted', QuotedIdent(FTableName));
  end;
  FInsertBegin := 'insert into ' + QuotedIdent(FTableName) + '(';
  SetLength(FWhereFields, ADefs.Count);
  ACount := 0;
  for I := 0 to ADefs.Count - 1 do
  begin
    ADef := ADefs[I] as TQFieldDef;
    if Length(ADef.BaseName) > 0 then
      FInsertBegin := FInsertBegin + QuotedIdent(ADef.BaseName) + ','
    else
      FInsertBegin := FInsertBegin + QuotedIdent(ADef.Name) + ',';
    Added := False;
    if (Length(ADef.BaseName) > 0) and ADef.InWhere then
    begin
      if ADef.IsPrimary then
      begin
        Move(FWhereFields[0], FWhereFields[1], ACount * sizeof(TQFieldDef));
        FWhereFields[0] := ADef;
        Added := true;
        Inc(ACount);
      end
      else if not PrimaryKeyOnly then
      begin
        if ADef.IsUnique then // 唯一,挪到主键后面做为值
        begin
          for J := 0 to ACount - 1 do
          begin
            if not FWhereFields[J].IsPrimary then
            begin
              Move(FWhereFields[J], FWhereFields[J + 1],
                (ACount - J) * sizeof(TQFieldDef));
              FWhereFields[J] := ADef;
              Added := true;
              Inc(ACount);
              Break;
            end;
          end;
        end
        else if ADef.IsIndex then // 索引字段放到普通字段的前面，但主键和唯一索引后面
        begin
          for J := 0 to ACount - 1 do
          begin
            if not(FWhereFields[J].IsPrimary or FWhereFields[J].IsUnique or
              FWhereFields[J].IsIndex) then
            begin
              Move(FWhereFields[J], FWhereFields[J + 1],
                (ACount - J) * sizeof(TQFieldDef));
              FWhereFields[J] := ADef;
              Added := true;
              Inc(ACount);
              Break;
            end;
          end;
        end;
      end
      else
        Added := true;
      if not Added then
      begin
        FWhereFields[ACount] := ADef;
        Inc(ACount);
      end;
    end
    else if not PrimaryKeyOnly then
    begin
      FWhereFields[ACount] := ADef;
      Inc(ACount);
    end;
  end;
  SetLength(FWhereFields, ACount);
  SetLength(FInsertBegin, Length(FInsertBegin) - 1);
  FInsertBegin := FInsertBegin + ') values (';
end;

function TQSQLConverter.WriteRecord(ARec: TQRecord): Boolean;
var
  ADef: TQFieldDef;
  AByMacros: Boolean;
  function EncodeValue(AFieldVal: PQValue): QStringW;
  var
    AStream: TQValueStream;
  begin
    if AFieldVal.IsNull then
      Result := 'NULL'
    else
    begin
      case AFieldVal.ValueType of
        vdtBoolean:
          Result := EncodeBoolean(AFieldVal.Value.AsBoolean);
        vdtDateTime:
          Result := EncodeDateTime(AFieldVal.Value.AsDateTime);
        vdtInterval:
          Result := EncodeInterval(AFieldVal.Value.AsInterval);
        vdtStream:
          begin
            if ADef.DataType in [ftMemo, ftWideMemo, ftFmtMemo] then
            begin
              AFieldVal.AsStream.Position := 0;
              Result := QuotedStrW(LoadTextW(AFieldVal.AsStream), '''');
            end
            else
            begin
              AStream := AFieldVal.AsStream;
              Result := EncodeBinary(AStream.Memory, AStream.Size);
            end;
          end;
        vdtString, vdtGuid:
          Result := QuotedStrW(AFieldVal.AsString, '''')
      else
        Result := AFieldVal.AsString;
      end;
    end;
  end;

  procedure GenInsertSQL;
  var
    I: Integer;
  begin
    if Length(FInsertTemplate) > 0 then
    begin
      for I := 0 to ARec.Fields.Count - 1 do
      begin
        ADef := ARec.Fields[I] as TQFieldDef;
        FMacros.Push(ADef.Name + '.New',
          EncodeValue(ARec.Values[ADef.FieldNo - 1].CurrentValue));
      end;
      FText.Cat(FMacros.Replace(FInsertTemplate, FMacroStart, FMacroEnd));
      for I := 0 to ARec.Fields.Count - 1 do
      begin
        ADef := ARec.Fields[I] as TQFieldDef;
        FMacros.Pop(ADef.Name + '.New');
      end;
      AByMacros := true;
    end
    else
    begin
      FText.Cat(FInsertBegin);
      for I := 0 to ARec.Fields.Count - 1 do
      begin
        ADef := ARec.Fields[I] as TQFieldDef;
        FText.Cat(EncodeValue(ARec.Values[ADef.FieldNo - 1].CurrentValue)
          ).Cat(',');
      end;
      FText.Back(1);
      FText.Cat(')');
    end;
  end;

  procedure GenUpdateSQL;
  var
    I: Integer;
    ACol: PQColumnValue;
  begin
    if Length(FUpdateTemplate) > 0 then
    begin
      for I := 0 to ARec.Fields.Count - 1 do
      begin
        ADef := ARec.Fields[I] as TQFieldDef;
        FMacros.Push(ADef.Name + '.Old',
          EncodeValue(@ARec.Values[ADef.FieldNo - 1].OldValue));
        FMacros.Push(ADef.Name + '.New',
          EncodeValue(ARec.Values[ADef.FieldNo - 1].CurrentValue));
      end;
      FText.Cat(FMacros.Replace(FUpdateTemplate, FMacroStart, FMacroEnd));
      for I := 0 to ARec.Fields.Count - 1 do
      begin
        ADef := ARec.Fields[I] as TQFieldDef;
        FMacros.Pop(ADef.Name + '.Old');
        FMacros.Pop(ADef.Name + '.New');
      end;
      AByMacros := true;
    end
    else
    begin
      FText.Cat('update ').Cat(QuotedIdent(FTableName)).Cat(' set ');
      for I := 0 to ARec.Fields.Count - 1 do
      begin
        ADef := ARec.Fields[I] as TQFieldDef;
        ACol := @ARec.Values[ADef.FieldNo - 1];
        if ACol.Changed then
        begin
          if Length(ADef.BaseName) > 0 then
            FText.Cat(QuotedIdent(ADef.BaseName))
          else
            FText.Cat(QuotedIdent(ADef.Name));
          FText.Cat('=').Cat(EncodeValue(@ACol.NewValue)).Cat(',');
        end;
      end;
      FText.Back(1);
      FText.Cat(' where ');
      for I := 0 to High(FWhereFields) do
      begin
        ADef := FWhereFields[I];
        ACol := @ARec.Values[ADef.FieldNo - 1];
        if Length(ADef.BaseName) > 0 then
          FText.Cat(QuotedIdent(ADef.BaseName))
        else
          FText.Cat(QuotedIdent(ADef.Name));
        if ACol.OldValue.IsNull then
          FText.Cat(' is null and ')
        else
          FText.Cat('=').Cat(EncodeValue(@ACol.OldValue)).Cat(' and ');
      end;
      FText.Back(5);
    end;
  end;

  procedure GenDeleteSQL;
  var
    I: Integer;
    ACol: PQColumnValue;
  begin
    if Length(FDeleteTemplate) > 0 then
    begin
      for I := 0 to ARec.Fields.Count - 1 do
      begin
        ADef := ARec.Fields[I] as TQFieldDef;
        FMacros.Push(ADef.Name + '.Old',
          EncodeValue(@ARec.Values[ADef.FieldNo - 1].OldValue));
      end;
      FText.Cat(FMacros.Replace(FDeleteTemplate, FMacroStart, FMacroEnd));
      for I := 0 to ARec.Fields.Count - 1 do
      begin
        ADef := ARec.Fields[I] as TQFieldDef;
        FMacros.Pop(ADef.Name + '.Old');
      end;
      AByMacros := true;
    end
    else
    begin
      FText.Cat('delete from ').Cat(QuotedIdent(FTableName)).Cat(' where ');
      for I := 0 to High(FWhereFields) do
      begin
        ADef := FWhereFields[I];
        ACol := @ARec.Values[ADef.FieldNo - 1];
        if Length(ADef.BaseName) > 0 then
          FText.Cat(QuotedIdent(ADef.BaseName))
        else
          FText.Cat(QuotedIdent(ADef.Name));
        if ACol.OldValue.IsNull then
          FText.Cat(' is null and ')
        else
          FText.Cat('=').Cat(EncodeValue(@ACol.OldValue)).Cat(' and ');
      end;
      FText.Back(5);
    end;
  end;

begin
  Result := true;
  AByMacros := False;
  if AllAsInsert then
    GenInsertSQL
  else if ARec.Status <> usUnmodified then
  begin
    case ARec.Status of
      usModified:
        GenUpdateSQL;
      usInserted:
        GenInsertSQL;
      usDeleted:
        GenDeleteSQL;
    end;
  end
  else
    Result := False;
  if Result then
  begin
    if (not AByMacros) and (Length(FStatementEnd) > 0) then
      FText.Cat(FStatementEnd);
    FText.Cat(SLineBreak);
  end;
  Result := true;
end;

{ TQMSSQLConverter }

constructor TQMSSQLConverter.Create(AOwner: TComponent);
begin
  inherited;
  FIdentBegin := '[';
  FIdentEnd := ']';
end;

function TQMSSQLConverter.EncodeBinary(const p: PByte; L: Integer): QStringW;
begin
  Result := '0x' + qstring.BinToHex(p, L);
end;

function TQMSSQLConverter.EncodeBoolean(const v: Boolean): QStringW;
begin
  if v then
    Result := '1'
  else
    Result := '0';
end;

{ TQPgSQLConverter }

constructor TQPgSQLConverter.Create(AOwner: TComponent);
begin
  inherited;

end;

function TQPgSQLConverter.EncodeBinary(const p: PByte; L: Integer): QStringW;
begin
  Result := 'E''\\x' + qstring.BinToHex(p, L) + '''';
end;

function TQPgSQLConverter.EncodeBoolean(const v: Boolean): QStringW;
begin
  if v then
    Result := 'true'
  else
    Result := 'false';
end;

function TQPgSQLConverter.EncodeInterval(const v: TQInterval): QStringW;
begin
  Result := '''' + v.AsPgString + '''';
end;

function TQPgSQLConverter.QuotedIdent(S: QStringW): QStringW;
var
  p: PWideChar;
  AFlags: Integer;
begin
  if (Length(S) > 0) and CaseSensitive then
  begin
    p := PWideChar(S);
    AFlags := 0;
    while (p^ <> #0) and (AFlags <> 3) do
    begin
      if (p^ >= 'A') and (p^ <= 'Z') then
        AFlags := AFlags or 1
      else if (p^ >= 'a') and (p^ <= 'z') then
        AFlags := AFlags or 2;
    end;
    if AFlags = 3 then
      Result := FIdentBegin + S + FIdentEnd
    else
      Result := inherited QuotedIdent(S);
  end
  else
    Result := inherited QuotedIdent(S);
end;

{ TQMySQLConverter }

constructor TQMySQLConverter.Create(AOwner: TComponent);
begin
  inherited;
  FIdentBegin := '`';
  FIdentEnd := FIdentBegin;
end;

function TQMySQLConverter.EncodeBinary(const p: PByte; L: Integer): QStringW;
begin
  Result := 'X''' + qstring.BinToHex(p, L) + '''';
end;

function TQMySQLConverter.EncodeBoolean(const v: Boolean): QStringW;
begin
  if v then
    Result := '1'
  else
    Result := '0';
end;

end.
