unit qconverter_fdac;

interface

uses classes, sysutils, db, qdb, fmtbcd, SqlTimSt, qstring, qjson, qxml,
  qrbtree, qvalue,
  typinfo, dateutils{$IFDEF MSWINDOWS}, windows{$ENDIF};

const
  FD_OBJECT_BEGIN = $FF;
  FD_OBJECT_END = $FE;

type
  TQFDConverter = class;

  TFdBinaryHeader = record
    Magic: array [0 .. 3] of Byte;
    Version: Word;
    DictionaryOffset: Cardinal;
  end;

  TFdObjectHeader = packed record
    Magic: Byte; // $FF
    NameIndex: Byte;
  end;

  TFDPropHeader = packed record
    Magic: Byte; // $FF
    NameIndex: Word;
  end;

  TFdProp = class
  private
    FName: QStringW;
  public
    property Name: QStringW read FName write FName;
  end;

  TFDIntervalKind = (itUnknown, itYear, itMonth, itDay, itHour, itMinute,
    itSecond, itYear2Month, itDay2Hour, itDay2Minute, itDay2Second,
    itHour2Minute, itHour2Second, itMinute2Second);

  TFDInterval = packed record
    Sign: Shortint;
    Kind: Integer;
    case TFDIntervalKind of
      itYear, itMonth, itYear2Month:
        (Years: Cardinal;
          Months: Cardinal
        );
      itDay, itHour, itMinute, itSecond, itDay2Hour, itDay2Minute, itDay2Second,
        itHour2Minute, itHour2Second, itMinute2Second:
        (Days: Cardinal;
          Hours: Cardinal;
          Minutes: Cardinal;
          Seconds: Cardinal;
          Fractions: Cardinal
        );
  end;

  TFDTableObject = record
    Name: QStringW;
    SourceName: QStringW;
    SourceId: Integer;
    Index: Integer;
    CaseSensitive: Boolean;
    EnforceConstraints: Boolean;
    Locale: LongWord;
    MinimumCapacity: Integer;
    Nested: Boolean;
    Round2Scale: Boolean;
    CheckPrecision: Boolean;
    StrsTrim2Len: Boolean;
    CheckNotNull: Boolean;
    CheckReadOnly: Boolean;
    InlineDataSize: Word;
  end;

  TFDChange = record
    TabId: Integer;
    RowId: Integer;
  end;

  PFDObjectStack = ^TFDObjectStack;

  TFDObjectStack = record
    Name: QStringW;
    Offset: Int64;
    IsArray: Boolean;
    Prior: PFDObjectStack;
  end;

  TFDStreamHelper = class
  protected
    FStream: TStream;
    FOwner: TQFDConverter;
    FVersion: Word;
    FLastObject: PFDObjectStack;
  public
    constructor Create(AOwner: TQFDConverter); overload;
    destructor Destroy; override;
    procedure PushObject(AOffset: Int64; AName: QStringW; AIsArray: Boolean);
    procedure PopObject;
    function CurrentObjectName: QStringW;
    function ObjectStacks: QStringW;
    function PrepareRead: Boolean; virtual; abstract;
    procedure EndRead; virtual;
    function PrepareWrite: Boolean; virtual; abstract;
    procedure EndWrite; virtual;
    // FireDAC 对象读写函数
    procedure ObjectBeginWrite(const AName: QStringW;
      AIsArray, AWriteClass: Boolean); virtual; abstract;
    procedure ObjectEndWrite; virtual; abstract;
    function ObjectBeginRead(const AExpectName: QStringW; ACheckClass: Boolean)
      : Boolean; virtual; abstract;
    procedure ObjectEndRead; virtual; abstract;
    function IsObject(AName: QStringW): Boolean; virtual; abstract;
    // FireDAC 属性读写函数
    function PropRead(const AExpectName: QStringW; var ABuf; ASize: Integer)
      : Boolean; virtual; abstract;
    procedure PropWrite(const AName: QStringW; const ABuf; ASize: Integer);
      virtual; abstract;
    function IsProp(AName: QStringW): Boolean; virtual; abstract;
    // bool
    function PropReadBool(const AName: QStringW; ADefVal: Boolean): Boolean;
      virtual; abstract;
    procedure PropWriteBool(const AName: QStringW; AValue: Boolean);
      virtual; abstract;
    // Int types
    function PropReadWord(const AName: QStringW; ADefVal: Word): Word;
      virtual; abstract;
    procedure PropWriteWord(const AName: QStringW; AValue: Word);
      virtual; abstract;
    function PropReadInteger(const AName: QStringW; ADefVal: Integer): Integer;
      virtual; abstract;
    procedure PropWriteInteger(const AName: QStringW; AValue: Integer);
      virtual; abstract;
    function PropReadLongword(const AName: QStringW; ADefVal: Cardinal)
      : Cardinal; virtual; abstract;
    procedure PropWriteLongWord(const AName: QStringW; AValue: Cardinal);
      virtual; abstract;
    function PropReadInt64(const AName: QStringW; ADefVal: Int64): Int64;
      virtual; abstract;
    procedure PropWriteInt64(const AName: QStringW; AValue: Int64);
      virtual; abstract;
    // Read Float Type
    function PropReadFloat(const AName: QStringW; ADefVal: Double): Double;
      virtual; abstract;
    procedure PropWriteFloat(const AName: QStringW; AValue: Double);
      virtual; abstract;
    function PropReadDate(const AName: QStringW; ADefValue: TDateTime)
      : TDateTime; virtual; abstract;
    procedure PropWriteDate(const AName: QStringW; AValue: TDateTime);
      virtual; abstract;
    // String Types
    function PropReadAnsiStr(const AName: QStringW; const ADefVal: QStringW)
      : QStringW; virtual; abstract;
    procedure PropWriteAnsi(const AName, AValue: QStringW); virtual; abstract;
    function PropReadStr(const AName, ADefVal: QStringW): QStringW;
      virtual; abstract;
    procedure PropWriteStr(const AName, AValue: QStringW); virtual; abstract;
    // Field Value
    function ReadValue(const AFieldName: QStringW; AFieldIndex: Word;
      AFdType: Word; var AValue: TQValue): Boolean; virtual; abstract;
    procedure WriteValue(const AFieldName: QStringW; AFieldIndex: Word;
      AFdType: Word; var AValue: TQValue); virtual; abstract;
    // Field Type
    function ReadType: Word; virtual; abstract;
    procedure WriteType(AType: Word); virtual; abstract;
    // Row State
    function ReadRowState: TUpdateStatus; virtual; abstract;
    procedure WriteRowState(AStatus: TUpdateStatus); virtual; abstract;
    property Version: Word read FVersion;
  end;

  TQFDBinaryStreamHelper = class(TFDStreamHelper)
  protected
    FStartOffset: Int64;
    FIndexes: TStringList;
    FDictionary: TStringList;
    function IndexOfName(const S: String): Integer;
  public
    constructor Create(AOwner: TQFDConverter); overload;
    destructor Destroy; override;
    function PrepareRead: Boolean; override;
    function PrepareWrite: Boolean; override;
    procedure EndRead; override;
    procedure EndWrite; override;
    // FireDAC 对象读写函数
    procedure ObjectBeginWrite(const AName: QStringW;
      AIsArray, AWriteClass: Boolean); override;
    procedure ObjectEndWrite; override;
    function ObjectBeginRead(const AExpectName: QStringW; ACheckClass: Boolean)
      : Boolean; override;
    procedure ObjectEndRead; override;
    function IsObject(AName: QStringW): Boolean; override;
    // FireDAC 属性读写函数
    function PropRead(const AExpectName: QStringW; var ABuf; ASize: Integer)
      : Boolean; override;
    procedure PropWrite(const AName: QStringW; const ABuf;
      ASize: Integer); override;
    function IsProp(AName: QStringW): Boolean; override;
    // bool
    function PropReadBool(const AName: QStringW; ADefVal: Boolean)
      : Boolean; override;
    procedure PropWriteBool(const AName: QStringW; AValue: Boolean); override;
    // Int types
    function PropReadWord(const AName: QStringW; ADefVal: Word): Word; override;
    procedure PropWriteWord(const AName: QStringW; AValue: Word); override;
    function PropReadInteger(const AName: QStringW; ADefVal: Integer)
      : Integer; override;
    procedure PropWriteInteger(const AName: QStringW; AValue: Integer);
      override;
    function PropReadLongword(const AName: QStringW; ADefVal: Cardinal)
      : Cardinal; override;
    procedure PropWriteLongWord(const AName: QStringW;
      AValue: Cardinal); override;
    function PropReadInt64(const AName: QStringW; ADefVal: Int64)
      : Int64; override;
    procedure PropWriteInt64(const AName: QStringW; AValue: Int64); override;
    // Read Float Type
    function PropReadFloat(const AName: QStringW; ADefVal: Double)
      : Double; override;
    procedure PropWriteFloat(const AName: QStringW; AValue: Double); override;
    function PropReadDate(const AName: QStringW; ADefValue: TDateTime)
      : TDateTime; override;
    procedure PropWriteDate(const AName: QStringW; AValue: TDateTime); override;
    // String Types
    function PropReadAnsiStr(const AName: QStringW; const ADefVal: QStringW)
      : QStringW; override;
    procedure PropWriteAnsi(const AName, AValue: QStringW); override;
    function PropReadStr(const AName, ADefVal: QStringW): QStringW; override;
    procedure PropWriteStr(const AName, AValue: QStringW); override;
    // Field Value
    function ReadValue(const AFieldName: QStringW; AFieldIndex: Word;
      AFdType: Word; var AValue: TQValue): Boolean; override;
    procedure WriteValue(const AFieldName: QStringW; AFieldIndex: Word;
      AFdType: Word; var AValue: TQValue); override;
    // Field Type
    function ReadType: Word; override;
    procedure WriteType(AType: Word); override;
    // Row State
    function ReadRowState: TUpdateStatus; override;
    procedure WriteRowState(AStatus: TUpdateStatus); override;
  end;

  TQFDConverter = class(TQConverter)
  protected
    FLastRowId: Integer;
    FChangedCount: Integer;
    FHelper: TFDStreamHelper;
    FTables: array of TFDTableObject;
    FChanges: array of TFDChange;
    FFdFieldTypes: array of Word;
    procedure PrepareFieldTypes(ADefs:TQFieldDefs);
    // 导入
    procedure BeforeImport; override;
    procedure BeginImport(AIndex: Integer); override;
    procedure LoadFieldDefs(ADefs: TQFieldDefs); override;
    function ReadRecord(ARec: TQRecord): Boolean; override;
    procedure EndImport(AIndex: Integer); override;
    // 导出
    procedure BeforeExport; override;
    procedure BeginExport(AIndex: Integer); override;
    procedure SaveFieldDefs(ADefs: TQFieldDefs); override;
    function WriteRecord(ARec: TQRecord): Boolean; override;
    procedure EndExport(AIndex: Integer); override;
    procedure AfterExport; override;
    // StreamHelper
    procedure HelperNeeded; virtual; abstract;
  public
  end;

  TQFDJsonStreamHelper = class(TFDStreamHelper)
  protected
    FJson: TQJson;
    FParent: TQJson;
  public
    constructor Create(AOwner: TQFDConverter); overload;
    destructor Destroy; override;
    function PrepareRead: Boolean; override;
    procedure EndRead; override;
    function PrepareWrite: Boolean; override;
    procedure EndWrite; override;
    // FireDAC 对象读写函数
    procedure ObjectBeginWrite(const AName: QStringW;
      AIsArray, AWriteClass: Boolean); override;
    procedure ObjectEndWrite; override;
    function ObjectBeginRead(const AExpectName: QStringW; ACheckClass: Boolean)
      : Boolean; override;
    procedure ObjectEndRead; override;
    function IsObject(AName: QStringW): Boolean; override;
    // FireDAC 属性读写函数
    function PropRead(const AExpectName: QStringW; var ABuf; ASize: Integer)
      : Boolean; override;
    procedure PropWrite(const AName: QStringW; const ABuf;
      ASize: Integer); override;
    function IsProp(AName: QStringW): Boolean; override;
    // bool
    function PropReadBool(const AName: QStringW; ADefVal: Boolean)
      : Boolean; override;
    procedure PropWriteBool(const AName: QStringW; AValue: Boolean); override;
    // Int types
    function PropReadWord(const AName: QStringW; ADefVal: Word): Word; override;
    procedure PropWriteWord(const AName: QStringW; AValue: Word); override;
    function PropReadInteger(const AName: QStringW; ADefVal: Integer)
      : Integer; override;
    procedure PropWriteInteger(const AName: QStringW; AValue: Integer);
      override;
    function PropReadLongword(const AName: QStringW; ADefVal: Cardinal)
      : Cardinal; override;
    procedure PropWriteLongWord(const AName: QStringW;
      AValue: Cardinal); override;
    function PropReadInt64(const AName: QStringW; ADefVal: Int64)
      : Int64; override;
    procedure PropWriteInt64(const AName: QStringW; AValue: Int64); override;
    // Read Float Type
    function PropReadFloat(const AName: QStringW; ADefVal: Double)
      : Double; override;
    procedure PropWriteFloat(const AName: QStringW; AValue: Double); override;
    function PropReadDate(const AName: QStringW; ADefValue: TDateTime)
      : TDateTime; override;
    procedure PropWriteDate(const AName: QStringW; AValue: TDateTime); override;
    // String Types
    function PropReadAnsiStr(const AName: QStringW; const ADefVal: QStringW)
      : QStringW; override;
    procedure PropWriteAnsi(const AName, AValue: QStringW); override;
    function PropReadStr(const AName, ADefVal: QStringW): QStringW; override;
    procedure PropWriteStr(const AName, AValue: QStringW); override;
    // Field Value
    function ReadValue(const AFieldName: QStringW; AFieldIndex: Word;
      AFdType: Word; var AValue: TQValue): Boolean; override;
    procedure WriteValue(const AFieldName: QStringW; AFieldIndex: Word;
      AFdType: Word; var AValue: TQValue); override;
    // Field Type
    function ReadType: Word; override;
    procedure WriteType(AType: Word); override;
    // Row State
    function ReadRowState: TUpdateStatus; override;
    procedure WriteRowState(AStatus: TUpdateStatus); override;
  end;
{$IF RTLVersion>=23}
  [ComponentPlatformsAttribute(pidWin32 or pidWin64{$IF RTLVersion>=24} or
    pidOSX32{$IFEND}{$IF RTLVersion>=25} or pidiOSSimulator or
    pidiOSDevice{$IFEND}{$IF RTLVersion>=26} or
    pidAndroid{$IFEND}{$IF RTLVersion>=29} or pidiOSDevice32 or
    pidiOSDevice64{$IFEND})]
{$IFEND}

  TQFDJsonConverter = class(TQFDConverter)
  protected
    procedure HelperNeeded; override;
  end;

  TQFDXMLStreamHelper = class(TFDStreamHelper)
  protected
    FXML: TQXMLNode;
    FParent: TQXMLNode;
  public
    constructor Create(AOwner: TQFDConverter); overload;
    destructor Destroy; override;
    function PrepareRead: Boolean; override;
    procedure EndRead; override;
    function PrepareWrite: Boolean; override;
    procedure EndWrite; override;
    // FireDAC 对象读写函数
    procedure ObjectBeginWrite(const AName: QStringW;
      AIsArray, AWriteClass: Boolean); override;
    procedure ObjectEndWrite; override;
    function ObjectBeginRead(const AExpectName: QStringW; ACheckClass: Boolean)
      : Boolean; override;
    procedure ObjectEndRead; override;
    function IsObject(AName: QStringW): Boolean; override;
    // FireDAC 属性读写函数
    function PropRead(const AExpectName: QStringW; var ABuf; ASize: Integer)
      : Boolean; override;
    procedure PropWrite(const AName: QStringW; const ABuf;
      ASize: Integer); override;
    function IsProp(AName: QStringW): Boolean; override;
    // bool
    function PropReadBool(const AName: QStringW; ADefVal: Boolean)
      : Boolean; override;
    procedure PropWriteBool(const AName: QStringW; AValue: Boolean); override;
    // Int types
    function PropReadWord(const AName: QStringW; ADefVal: Word): Word; override;
    procedure PropWriteWord(const AName: QStringW; AValue: Word); override;
    function PropReadInteger(const AName: QStringW; ADefVal: Integer)
      : Integer; override;
    procedure PropWriteInteger(const AName: QStringW; AValue: Integer);
      override;
    function PropReadLongword(const AName: QStringW; ADefVal: Cardinal)
      : Cardinal; override;
    procedure PropWriteLongWord(const AName: QStringW;
      AValue: Cardinal); override;
    function PropReadInt64(const AName: QStringW; ADefVal: Int64)
      : Int64; override;
    procedure PropWriteInt64(const AName: QStringW; AValue: Int64); override;
    // Read Float Type
    function PropReadFloat(const AName: QStringW; ADefVal: Double)
      : Double; override;
    procedure PropWriteFloat(const AName: QStringW; AValue: Double); override;
    function PropReadDate(const AName: QStringW; ADefValue: TDateTime)
      : TDateTime; override;
    procedure PropWriteDate(const AName: QStringW; AValue: TDateTime); override;
    // String Types
    function PropReadAnsiStr(const AName: QStringW; const ADefVal: QStringW)
      : QStringW; override;
    procedure PropWriteAnsi(const AName, AValue: QStringW); override;
    function PropReadStr(const AName, ADefVal: QStringW): QStringW; override;
    procedure PropWriteStr(const AName, AValue: QStringW); override;
    // Field Value
    function ReadValue(const AFieldName: QStringW; AFieldIndex: Word;
      AFdType: Word; var AValue: TQValue): Boolean; override;
    procedure WriteValue(const AFieldName: QStringW; AFieldIndex: Word;
      AFdType: Word; var AValue: TQValue); override;
    // Field Type
    function ReadType: Word; override;
    procedure WriteType(AType: Word); override;
    // Row State
    function ReadRowState: TUpdateStatus; override;
    procedure WriteRowState(AStatus: TUpdateStatus); override;
  end;
{$IF RTLVersion>=23}
  [ComponentPlatformsAttribute(pidWin32 or pidWin64{$IF RTLVersion>=24} or
    pidOSX32{$IFEND}{$IF RTLVersion>=25} or pidiOSSimulator or
    pidiOSDevice{$IFEND}{$IF RTLVersion>=26} or
    pidAndroid{$IFEND}{$IF RTLVersion>=29} or pidiOSDevice32 or
    pidiOSDevice64{$IFEND})]
{$IFEND}

  TQFDXMLConverter = class(TQFDConverter)
  protected
    procedure HelperNeeded; override;
  end;
{$IF RTLVersion>=23}
  [ComponentPlatformsAttribute(pidWin32 or pidWin64{$IF RTLVersion>=24} or
    pidOSX32{$IFEND}{$IF RTLVersion>=25} or pidiOSSimulator or
    pidiOSDevice{$IFEND}{$IF RTLVersion>=26} or
    pidAndroid{$IFEND}{$IF RTLVersion>=29} or pidiOSDevice32 or
    pidiOSDevice64{$IFEND})]
{$IFEND}

  TQFDBinaryConverter = class(TQFDConverter)
  protected
    procedure HelperNeeded; override;
  end;

implementation

resourcestring
  SBadStreamFormat = '无效或不受支持的 FireDAC 数据流';
  SVersionTooLow = '不受支持的数据版本(要求>=6)';
  SUnsupportFormat = '未找到需要的数据项目，该版本数据不受支持';
  SDiskFull = '无法写入数据到流，空间不足？';

  { TFDBinaryConverter }
const
  StreamMagic: array [0 .. 3] of Byte = (Ord('A'), Ord('D'), Ord('B'),
    Ord('S'));
  TypeMaps: array [0 .. 40] of Cardinal = (SQL_UNKNOWN, SQL_BOOLEAN,
    SQL_TINYINT, SQL_SMALLINT, SQL_INTEGER, // 0..4
    SQL_INT64, SQL_BYTE, SQL_WORD, SQL_DWORD, SQL_QWORD, // 5..9
    SQL_SINGLE, SQL_FLOAT, SQL_EXTENDED, SQL_MONEY, SQL_BCD, // 10..14
    SQL_BCD, SQL_DATETIME, SQL_TIME, SQL_DATE, SQL_TIMESTAMP, // 15..19
    SQL_INTERVAL, SQL_INTERVAL, SQL_INTERVAL, SQL_VARCHAR, SQL_WIDEVARCHAR,
    // 20..24
    SQL_BYTES, SQL_LARGEOBJECT, SQL_TEXT, SQL_WIDETEXT, SQL_XML, // 25..29
    SQL_BYTES, SQL_TEXT, SQL_WIDETEXT, SQL_BYTES, SQL_DATASET, // 30..34
    SQL_CURSOR, SQL_INTEGER, SQL_ARRAY, SQL_INTEGER, SQL_UUID, // 35..39
    SQL_OBJECT);
  TypeNames: array [0 .. 40] of QStringW = ('dtUnknown', 'dtBoolean', 'dtSByte',
    'dtInt16', 'dtInt32', // 0..4
    'dtInt64', 'dtByte', 'dtUInt16', 'dtUInt32', 'dtUInt64', // 5..9
    'dtSingle', 'dtDouble', 'dtExtended', 'dtCurrency', 'dtBCD', // 10..14
    'dtFmtBCD', 'dtDateTime', 'dtTime', 'dtDate', 'dtDateTimeStamp', // 15..19
    'dtTimeIntervalFull', 'dtTimeIntervalYM', 'dtTimeIntervalDS',
    'dtAnsiString', 'dtWideString', // 20..24
    'dtByteString', 'dtBlob', 'dtMemo', 'dtWideMemo', 'dtXML', // 25..29
    'dtHBlob', 'dtHMemo', 'dtWideHMemo', 'dtHBFile', 'dtRowSetRef', // 30..34
    'dtCursorRef', 'dtRowRef', 'dtArrayRef', 'dtParentRowRef', 'dtGUID',
    // 35..39
    'dtObject');

function DBType2FDType(AType: Cardinal): Word;
var
  I: Integer;
begin
  for I := 0 to 40 do
  begin
    if TypeMaps[I] = AType then
    begin
      Result := I;
      Exit;
    end;
  end;
  Result := 0;
end;

function FDTypeNameToType(const AName: String): Word;
var
  I: Integer;
begin
  for I := 0 to 40 do
  begin
    if TypeNames[I] = AName then
    begin
      Result := Word(I);
      Exit;
    end;
  end;
  Result := 0;
end;

function ParseFDDateTime(Val: QStringW): TDateTime;
var
  p: PQCharW;
  Y, M, D, H, N, S: Word;
begin
  p := PQCharW(Val);
  Y := StrToInt(StrDupW(p, 0, 4));
  Inc(p, 4);
  M := StrToInt(StrDupW(p, 0, 2));
  Inc(p, 2);
  D := StrToInt(StrDupW(p, 0, 2));
  Inc(p, 2);
  if p^ = 'T' then
    Inc(p);
  if p^ <> #0 then
  begin
    H := StrToInt(StrDupW(p, 0, 2));
    Inc(p, 2);
    N := StrToInt(StrDupW(p, 0, 2));
    Inc(p, 2);
    S := StrToInt(StrDupW(p, 0, 2));
    Result := EncodeDateTime(Y, M, D, H, N, S, 0);
  end
  else
    Result := EncodeDate(Y, M, D);
end;

function ParseFDDate(Val: QStringW): TDateTime;
var
  p: PQCharW;
  Y, M, D: Word;
begin
  p := PQCharW(Val);
  Y := StrToInt(StrDupW(p, 0, 4));
  Inc(p, 4);
  M := StrToInt(StrDupW(p, 0, 2));
  Inc(p, 2);
  D := StrToInt(StrDupW(p, 0, 2));
  Result := EncodeDate(Y, M, D);
end;

function ParseFDTime(Val: QStringW): TDateTime;
var
  p: PQCharW;
  H, N, S: Word;
begin
  p := PQCharW(Val);
  H := StrToInt(StrDupW(p, 0, 2));
  Inc(p, 2);
  N := StrToInt(StrDupW(p, 0, 2));
  Inc(p, 2);
  S := StrToInt(StrDupW(p, 0, 2));
  Result := EncodeTime(H, N, S, 0);
end;
{ TQFDConverter }

procedure TQFDConverter.BeforeExport;
begin
  inherited;
  HelperNeeded;
  if not FHelper.PrepareWrite then
    raise Exception.Create(SDiskFull);
  FLastRowId := 0;
  FChangedCount := 0;
  SetLength(FChanges, 1024);
  FHelper.ObjectBeginWrite('Manager', false, false);
  FHelper.PropWriteStr('Name', 'Manager');
  FHelper.PropWriteBool('CaseSensitive', True);
  FHelper.PropWriteBool('EnforceConstraints', True);
  FHelper.PropWriteLongWord('Locale',
{$IFDEF MSWINDOWS}LOCALE_USER_DEFAULT{$ELSE}0{$ENDIF});
  FHelper.PropWriteBool('UpdatesRegistry', True);
  FHelper.PropWriteBool('Round2Scale', false);
  FHelper.PropWriteBool('CheckPrecision', false);
  FHelper.PropWriteBool('StrsTrim2Len', false);
  FHelper.PropWriteBool('CheckNotNull', True);
  FHelper.PropWriteBool('CheckReadOnly', True);
  FHelper.ObjectBeginWrite('TableList', True, false);
end;

procedure TQFDConverter.BeforeImport;
begin
  inherited;
  HelperNeeded;
  if not FHelper.PrepareRead then
    raise Exception.Create(SBadStreamFormat);
  SetLength(FTables, 16); // 默认16个，一般足够不用重分配
  DataSetCount := MaxInt; // 由于流读到此时并不知道有多少个表，所以暂时设置为最大整数
  if FHelper.ObjectBeginRead('Manager', false) then
  begin
    FHelper.PropReadStr('Name', '');
    FHelper.PropReadBool('CaseSensitive', True);
    FHelper.PropReadBool('EnforceConstraints', True);
    FHelper.PropReadLongword('Locale',
{$IFDEF MSWINDOWS}LOCALE_USER_DEFAULT{$ELSE}0{$ENDIF});
    FHelper.PropReadBool('UpdatesRegistry', false);
    FHelper.PropReadBool('Round2Scale', false);
    if FHelper.Version >= 14 then
      FHelper.PropReadBool('CheckPrecision', false);
    if FHelper.Version >= 7 then
      FHelper.PropReadBool('StrsTrim2Len', false);
    FHelper.PropReadBool('CheckNotNull', True);
    if FHelper.Version >= 6 then
      FHelper.PropReadBool('CheckReadOnly', True);
    if FHelper.Version < 6 then
      raise Exception.Create(SVersionTooLow);
    if not FHelper.ObjectBeginRead('TableList', false) then
      raise Exception.Create(SUnsupportFormat);
  end
  else
    raise Exception.Create(SUnsupportFormat);
end;

procedure TQFDConverter.BeginExport(AIndex: Integer);
var
  ADataSet: TQDataSet;
  function GetTableName: QStringW;
  var
    I: Integer;
    ADef: TQFieldDef;
  begin
    Result := '';
    for I := 0 to ADataSet.FieldDefs.Count - 1 do
    begin
      ADef := TQFieldDef(ADataSet.FieldDefs[I]);
      if Length(ADef.Table) > 0 then
      begin
        if Length(Result) = 0 then
          Result := ADef.Table
        else if ADef.Table <> Result then
          Result := '';
      end;
    end;
  end;

begin
  inherited;
  if FDataSet.RecordsetCount > 0 then
    ADataSet := FDataSet.Recordsets[AIndex]
  else
    ADataSet := FDataSet;
  // Todo:将默认值不需要写的属性去掉
  FHelper.ObjectBeginWrite('Table', false, True);
  if Length(ADataSet.Name) > 0 then
    FHelper.PropWriteStr('Name', ADataSet.Name)
  else
    FHelper.PropWriteStr('Name', 'Noname');
  FHelper.PropWriteStr('SourceName', GetTableName);
  FHelper.PropWriteInteger('SourceID', ActiveDataSet);
  FHelper.PropWriteInteger('TabID', ActiveDataSet);
  FHelper.PropWriteBool('CaseSensitive', True);
  FHelper.PropWriteBool('EnforceConstraints', True);
  FHelper.PropWriteLongWord('Locale',
{$IFDEF MSWINDOWS}LOCALE_USER_DEFAULT{$ELSE}0{$ENDIF});
  FHelper.PropWriteInteger('MinimumCapacity', 50);
  if ADataSet <> FDataSet then
    FHelper.PropWriteBool('Nested', True)
  else
    FHelper.PropWriteBool('Nested', false);
  FHelper.PropWriteBool('Round2Scale', false);
  FHelper.PropWriteBool('CheckPrecision', false);
  FHelper.PropWriteBool('StrsTrim2Len', false);
  FHelper.PropWriteBool('CheckNotNull', True);
  FHelper.PropWriteBool('CheckReadOnly', True);
  FHelper.PropWriteInteger('InlineDataSize', 1000);
end;

procedure TQFDConverter.BeginImport(AIndex: Integer);
begin
  inherited;
  if FHelper.ObjectBeginRead('Table', True) then
  begin
    if ActiveDataSet > High(FTables) then
      SetLength(FTables, Length(FTables) + 16);
    FTables[ActiveDataSet].Name := FHelper.PropReadStr('Name', '');
    FTables[ActiveDataSet].SourceName := FHelper.PropReadStr('SourceName', '');
    FHelper.PropReadInteger('SourceID', 0);
    FHelper.PropReadInteger('TabID', -1);
    FHelper.PropReadBool('CaseSensitive', True);
    FHelper.PropReadBool('EnforceConstraints', True);
    FHelper.PropReadLongword('Locale',
{$IFDEF MSWINDOWS}LOCALE_USER_DEFAULT{$ELSE}0{$ENDIF});
    FHelper.PropReadInteger('MinimumCapacity', 0);
    FHelper.PropReadBool('Nested', false);
    FHelper.PropReadBool('Round2Scale', false);
    if FHelper.Version >= 14 then
      FHelper.PropReadBool('CheckPrecision', false);
    if FHelper.Version >= 7 then
      FHelper.PropReadBool('StrsTrim2Len', false);
    FHelper.PropReadBool('CheckNotNull', True);
    if FHelper.Version >= 6 then
      FHelper.PropReadBool('CheckReadOnly', True);
    if FHelper.Version >= 12 then
      FHelper.PropReadInteger('InlineDataSize', 1000);
  end
  else
    raise Exception.Create(SBadStreamFormat);
end;

procedure TQFDConverter.AfterExport;
var
  I: Integer;
begin
  FHelper.ObjectEndWrite; // </TableList>
  FHelper.ObjectBeginWrite('RelationList', True, false); // <RelationList>
  FHelper.ObjectEndWrite; // </RelationList>
  FHelper.ObjectBeginWrite('UpdatesJournal', false, false);
  if FChangedCount > 0 then
  begin
    FHelper.PropWriteInteger('SavePoint', FChangedCount);
    FHelper.ObjectBeginWrite('Changes', True, false); // <Changes>
    for I := 0 to FChangedCount - 1 do
    begin
      FHelper.ObjectBeginWrite('Change', false, false);
      FHelper.PropWriteInteger('TabID', FChanges[I].TabId);
      FHelper.PropWriteLongWord('RowID', FChanges[I].RowId);
      FHelper.PropWriteLongWord('ChangeNumber', I);
      FHelper.ObjectEndWrite;
    end;
  end
  else
    FHelper.ObjectBeginWrite('Changes', True, false); // <Changes>
  FHelper.ObjectEndWrite; // </Changes>
  FHelper.ObjectEndWrite; // </UpdatesJournal'>
  FHelper.EndWrite;
  FreeAndNil(FHelper);
  inherited;
end;

procedure TQFDConverter.EndExport(AIndex: Integer);
begin
  FHelper.ObjectEndWrite; // RowList
  FHelper.ObjectEndWrite; // </Table>
end;

procedure TQFDConverter.EndImport(AIndex: Integer);
begin
  inherited;
  FHelper.ObjectEndRead; // RowList
  FHelper.ObjectEndRead; // Table
  if not FHelper.IsObject('Table') then
    FDataSetCount := FActiveDataSet;
end;

procedure TQFDConverter.LoadFieldDefs(ADefs: TQFieldDefs);
var
  ADef: TQFieldDef;
begin
  inherited;
  if FHelper.ObjectBeginRead('ColumnList', false) then
  begin
    SetLength(FFdFieldTypes, 16);
    while FHelper.ObjectBeginRead('Column', false) do
    begin
      ADef := ADefs.AddFieldDef as TQFieldDef;
      ADef.Name := FHelper.PropReadStr('Name', '');
      ADef.BaseName := FHelper.PropReadStr('SourceName', '');
      ADef.DBNo := FHelper.PropReadInteger('SourceID', 0); //
      if ADefs.Count > Length(FFdFieldTypes) then
        SetLength(FFdFieldTypes, Length(FFdFieldTypes) + 16);
      FFdFieldTypes[ADef.Index] := FHelper.ReadType;
      // FDTypeEnumValue(ReadWord('DataType', 0));
      ADef.DBType := TypeMaps[FFdFieldTypes[ADef.Index]];
      ADef.Precision := FHelper.PropReadInteger('Precision', 0);
      ADef.Scale := FHelper.PropReadInteger('Scale', 0);
      if ADef.DataType <> ftOraInterval then
        ADef.Size := FHelper.PropReadInteger('Size', ADef.Size)
      else
        ADef.Size := 0;
      FHelper.PropReadBool('Searchable', false);
      ADef.Nullable := FHelper.PropReadBool('AllowNull', True);
      ADef.IsFixed := FHelper.PropReadBool('FixedLen', false);
      FHelper.PropReadBool('BlobData', false);
      ADef.ReadOnly := FHelper.PropReadBool('ReadOnly', false);
      ADef.IsAutoInc := FHelper.PropReadBool('AutoInc', false);
      if FHelper.PropReadBool('RowID', false) then
        ADef.DBType := SQL_PG_OID;
      FHelper.PropReadBool('Default', false);
      FHelper.PropReadBool('RowVersion', false);
      ADef.InternalCalcField := FHelper.PropReadBool('Internal', false);
      ADef.IsCalc := FHelper.PropReadBool('Calculated', false);
      FHelper.PropReadBool('Volatile', false);
      if FHelper.PropReadBool('Unnamed', false) then
        ADef.Attributes := ADef.Attributes + [faUnnamed];
      FHelper.PropReadBool('Virtual', false);
      FHelper.PropReadBool('Base', false);
      FHelper.PropReadBool('Expr', false);
      ADef.IsAutoInc := FHelper.PropReadBool('AutoIncrement', ADef.IsAutoInc);
      FHelper.PropReadInteger('AutoIncrementSeed', 1);
      FHelper.PropReadInteger('AutoIncrementStep', 1);
      FHelper.PropReadStr('Caption', '');
      FHelper.PropReadStr('Expression', '');
      FHelper.PropReadBool('OAllowNull', false);
      ADef.IsUnique := FHelper.PropReadBool('OUnique', false);
      FHelper.PropReadBool('OReadOnly', false);
      FHelper.PropReadBool('OInUpdate', false);
      ADef.InWhere := FHelper.PropReadBool('OInWhere', false);
      ADef.IsPrimary := FHelper.PropReadBool('OInKey', false);
      FHelper.PropReadBool('OAfterInsChanged', false);
      FHelper.PropReadBool('OAfterUpdChanged', false);
      if FHelper.IsProp('OriginName') then
        ADef.BaseName := FHelper.PropReadStr('OriginName', ADef.BaseName)
      else
      begin
        ADef.Table := FHelper.PropReadStr('OriginTabName', '');
        if (Length(ADef.Table) = 0) and
          (not(ADef.InternalCalcField or ADef.IsCalc or ADef.ReadOnly)) then
          ADef.Table := FTables[ActiveDataSet].SourceName;
        ADef.BaseName := FHelper.PropReadStr('OriginColName', ADef.BaseName);
      end;
      if FHelper.IsProp('SourceDataType') then
        FHelper.PropReadInteger('SourceDataType', 0);
      FHelper.PropReadInteger('SourcePrecision', 0);
      FHelper.PropReadInteger('SourceScale', 0);
      FHelper.PropReadInteger('SourceSize', 0);
      FHelper.PropReadStr('SourceDataTypeName', '');
      FHelper.PropReadStr('SourceDirectory', '');
      FHelper.PropReadStr('SourceGenerator', '');
      FHelper.ObjectEndRead;
    end;
    FHelper.ObjectEndRead; // end Column List
    // ConstraintList
    if FHelper.ObjectBeginRead('ConstraintList', false) then
      FHelper.ObjectEndRead
    else
      raise Exception.Create(SBadStreamFormat);
    // ViewList
    if FHelper.ObjectBeginRead('ViewList', false) then
    begin
      FHelper.PropReadStr('Name', '');
      FHelper.PropReadBool('Active', false);
      FHelper.PropReadStr('SourceView', '');
      //
      FHelper.ObjectEndRead;
    end
    else
      raise Exception.Create(SBadStreamFormat);
    // RowList
    if not FHelper.ObjectBeginRead('RowList', false) then
      raise Exception.Create(SBadStreamFormat);
  end
  else
    raise Exception.Create(SBadStreamFormat);
end;

procedure TQFDConverter.PrepareFieldTypes(ADefs:TQFieldDefs);
var
  I:Integer;
begin
  SetLength(FFdFieldTypes, ADefs.Count);
  for I := 0 to ADefs.Count - 1 do
    FFdFieldTypes[I] := DBType2FDType((ADefs[I] as TQFieldDef).DBType);
end;

function TQFDConverter.ReadRecord(ARec: TQRecord): Boolean;

  procedure LoadRow(const ARowName: QStringW; ATypeIdx: Integer);
  var
    I: Integer;
    AValue: TQValue;
  begin
    if FHelper.ObjectBeginRead(ARowName, false) then
    begin
      try
        // FireDAC 先存贮了常规类型字段，后存储Blob字段，所以在此需要做一个判定
        // Blob类型：dtByteString(25),dtBlob(26),dtMemo(27),dtWideMemo(28),dtXML(29),dtHBlob(30),dtHMemo(31),dtWideHMemo(32),dtHBFile(33)
        for I := 0 to High(ARec.Values) do
        begin
          if (FFdFieldTypes[I] < 25) or (FFdFieldTypes[I] > 33) then
          begin
            case ATypeIdx of
              0:
                FHelper.ReadValue(ARec.Fields[I].Name, I, FFdFieldTypes[I],
                  ARec.Values[I].OldValue);
              1:
                if FHelper.ReadValue(ARec.Fields[I].Name, I, FFdFieldTypes[I],
                  ARec.Values[I].NewValue) then
                begin
                  ARec.Values[I].Changed := True;
                end;
              2:
                FHelper.ReadValue(ARec.Fields[I].Name, I, FFdFieldTypes[I],
                  AValue); // Proposed Value
            end;
          end;
        end;
        for I := 0 to High(ARec.Values) do
        begin
          if FFdFieldTypes[I] in [25 .. 33] then
          begin
            case ATypeIdx of
              0:
                FHelper.ReadValue(ARec.Fields[I].Name, I, FFdFieldTypes[I],
                  ARec.Values[I].OldValue);
              1:
                if FHelper.ReadValue(ARec.Fields[I].Name, I, FFdFieldTypes[I],
                  ARec.Values[I].NewValue) then
                begin
                  ARec.Values[I].Changed := True;
                end;
              2:
                FHelper.ReadValue(ARec.Fields[I].Name, I, FFdFieldTypes[I],
                  AValue); // Proposed Value
            end;
          end;
        end;
      finally
        FHelper.ObjectEndRead;
      end;
    end;
  end;

begin
  if FHelper.ObjectBeginRead('Row', false) then
  begin
    try
      FHelper.PropReadLongword('RowID', $FFFFFFFF); // RowId 忽略
      ARec.Status := FHelper.ReadRowState;
      FHelper.PropReadWord('RowPriorState', 0);
      if FHelper.ObjectBeginRead('Exception', false) then
      begin
        // 读取并忽略FDException
        FHelper.PropReadInteger('FDCode', 0);
        FHelper.PropReadStr('Message', '');
        if FHelper.Version >= 8 then
          FHelper.PropReadStr('FDObjName', '');
        FHelper.ObjectEndRead;
      end;
      LoadRow('Original', 0);
      LoadRow('Current', 1);
      LoadRow('Proposed', 2);
      Result := True;
      //不支持进度显示
    finally
      FHelper.ObjectEndRead; // Row
    end;
  end
  else
    Result := false;
end;

procedure TQFDConverter.SaveFieldDefs(ADefs: TQFieldDefs);
var
  ADef: TQFieldDef;
  I: Integer;
begin
  inherited;
  PrepareFieldTypes(ADefs);
  FHelper.ObjectBeginWrite('ColumnList', True, false);
  for I := 0 to ADefs.Count - 1 do
  begin
    ADef := ADefs[I] as TQFieldDef;
    FHelper.ObjectBeginWrite('Column', false, True);
    FHelper.PropWriteStr('Name', ADef.Name);
    FHelper.PropWriteStr('SourceName', ADef.BaseName);
    FHelper.PropWriteInteger('SourceID', ADef.DBNo);
    FHelper.WriteType(FFdFieldTypes[I]);
    FHelper.PropWriteInteger('Precision', ADef.Precision);
    FHelper.PropWriteInteger('Scale', ADef.Scale);
    FHelper.PropWriteInteger('Size', ADef.Size);
    FHelper.PropWriteBool('Searchable', True);
    FHelper.PropWriteBool('AllowNull', ADef.Nullable);
    FHelper.PropWriteBool('FixedLen', ADef.IsFixed);
    FHelper.PropWriteBool('BlobData', ADef.IsBlob);
    FHelper.PropWriteBool('ReadOnly', ADef.ReadOnly);
    FHelper.PropWriteBool('AutoInc', ADef.IsAutoInc);
    if ADef.DBType = SQL_PG_OID then
      FHelper.PropWriteBool('RowID', True);
    FHelper.PropWriteBool('Default', false);
    FHelper.PropWriteBool('RowVersion', false);
    FHelper.PropWriteBool('Internal', ADef.InternalCalcField);
    FHelper.PropWriteBool('Calculated', ADef.IsCalc);
    FHelper.PropWriteBool('Volatile', false);
    if faUnnamed in ADef.Attributes then
      FHelper.PropWriteBool('Unnamed', True);
    FHelper.PropWriteBool('Virtual', false);
    FHelper.PropWriteBool('Base', not(ADef.IsCalc or ADef.InternalCalcField));
    FHelper.PropWriteBool('AutoIncrement', ADef.IsAutoInc);
    if ADef.IsAutoInc then
    begin
      FHelper.PropWriteInteger('AutoIncrementSeed', 1);
      FHelper.PropWriteInteger('AutoIncrementStep', 1);
    end;
    FHelper.PropWriteStr('Caption', '');
    FHelper.PropWriteStr('Expression', '');
    FHelper.PropWriteBool('OAllowNull', ADef.Nullable);
    FHelper.PropWriteBool('OUnique', ADef.IsUnique);
    FHelper.PropWriteBool('OReadOnly', ADef.ReadOnly);
    FHelper.PropWriteBool('OInUpdate', ADef.InWhere);
    FHelper.PropWriteBool('OInWhere', ADef.InWhere);
    FHelper.PropWriteBool('OInKey', ADef.IsPrimary);
    FHelper.PropWriteBool('OAfterInsChanged', false);
    FHelper.PropWriteBool('OAfterUpdChanged', false);
    FHelper.PropWriteStr('OriginTabName', ADef.Table);
    FHelper.PropWriteStr('OriginColName', ADef.BaseName);
    FHelper.ObjectEndWrite;
  end;
  FHelper.ObjectEndWrite; // ColumnList
  FHelper.ObjectBeginWrite('ConstraintList', True, false);
  FHelper.ObjectEndWrite;
  FHelper.ObjectBeginWrite('ViewList', True, false);
  FHelper.ObjectEndWrite;
  FHelper.ObjectBeginWrite('RowList', True, false);
end;

function TQFDConverter.WriteRecord(ARec: TQRecord): Boolean;
  procedure WriteRow(const AName: QStringW; ATypeId: Integer);
  var
    I: Integer;
  begin
    FHelper.ObjectBeginWrite(AName, false, false);
    for I := 0 to High(ARec.Values) do
    begin
      if (FFdFieldTypes[I] < 25) or (FFdFieldTypes[I] > 33) then
      begin
        case ATypeId of
          0:
            FHelper.WriteValue(ARec.Fields[I].Name, I, FFdFieldTypes[I],
              ARec.Values[I].OldValue);
          1:
            if ARec.Values[I].Changed then
              FHelper.WriteValue(ARec.Fields[I].Name, I, FFdFieldTypes[I],
                ARec.Values[I].NewValue)
            else
              FHelper.WriteValue(ARec.Fields[I].Name, I, FFdFieldTypes[I],
                ARec.Values[I].OldValue);
        end;
      end;
    end;
    for I := 0 to High(ARec.Values) do
    begin
      if FFdFieldTypes[I] in [25 .. 33] then
      begin
        case ATypeId of
          0:
            FHelper.WriteValue(ARec.Fields[I].Name, I, FFdFieldTypes[I],
              ARec.Values[I].OldValue);
          1:
            if ARec.Values[I].Changed then
              FHelper.WriteValue(ARec.Fields[I].Name, I, FFdFieldTypes[I],
                ARec.Values[I].NewValue)
            else
              FHelper.WriteValue(ARec.Fields[I].Name, I, FFdFieldTypes[I],
                ARec.Values[I].OldValue);
        end;
      end;
    end;
    FHelper.ObjectEndWrite;
  end;

begin
  Result := True;
  if Length(FFdFieldTypes)=0 then
    PrepareFieldTypes((ARec.Owner as TQDataSet).FieldDefs as TQFieldDefs);
  FHelper.ObjectBeginWrite('Row', false, false);
  try
    if ARec.Status <> usUnmodified then
    begin
      if FChangedCount = Length(FChanges) then
        SetLength(FChanges, Length(FChanges) + 1024);
      FChanges[FChangedCount].TabId := ActiveDataSet;
      FChanges[FChangedCount].RowId := FLastRowId;
      Inc(FChangedCount);
    end;
    FHelper.PropWriteLongWord('RowID', FLastRowId);
    Inc(FLastRowId);
    FHelper.WriteRowState(ARec.Status);
    case ARec.Status of
      usModified:
        begin
          WriteRow('Original', 0);
          WriteRow('Current', 1);
        end;
      usInserted:
        WriteRow('Current', 1);
      usUnmodified, usDeleted:
        WriteRow('Original', 0);
    end;
  finally
    FHelper.ObjectEndWrite;
  end;
end;

{ TFDStreamHelper }

constructor TFDStreamHelper.Create(AOwner: TQFDConverter);
begin
  inherited Create;
  FOwner := AOwner;
  FStream := AOwner.FStream;
end;

function TFDStreamHelper.CurrentObjectName: QStringW;
begin
  if Assigned(FLastObject) then
    Result := FLastObject.Name
  else
    SetLength(Result, 0);
end;

destructor TFDStreamHelper.Destroy;
begin
  while Assigned(FLastObject) do
    PopObject;
  inherited;
end;

procedure TFDStreamHelper.EndRead;
begin

end;

procedure TFDStreamHelper.EndWrite;
begin

end;

function TFDStreamHelper.ObjectStacks: QStringW;
var
  AItem: PFDObjectStack;
begin
  SetLength(Result, 0);
  if Assigned(FLastObject) then
  begin
    AItem := FLastObject;
    while AItem <> nil do
    begin
      Result := IntToHex(AItem.Offset, 8) + ' ' + AItem.Name +
        SLineBreak + Result;
      AItem := AItem.Prior;
    end;
  end;
end;

procedure TFDStreamHelper.PopObject;
var
  APrior: PFDObjectStack;
begin
  if Assigned(FLastObject) then
  begin
    // OutputDebugString(PChar('<< ' + FLastObject.Name));
    APrior := FLastObject.Prior;
    Dispose(FLastObject);
    FLastObject := APrior;
  end;
end;

procedure TFDStreamHelper.PushObject(AOffset: Int64; AName: QStringW;
  AIsArray: Boolean);
var
  AItem: PFDObjectStack;
begin
  if Assigned(FLastObject) and (FLastObject.Offset = AOffset) then
    Exit;
  // OutputDebugString(PChar('>> ' + AName));
  New(AItem);
  AItem.Offset := AOffset;
  AItem.Name := AName;
  AItem.Prior := FLastObject;
  AItem.IsArray := AIsArray;
  FLastObject := AItem;
end;

{ TQFDBinaryStreamHelper }

constructor TQFDBinaryStreamHelper.Create(AOwner: TQFDConverter);
begin
  inherited;
  FDictionary := TStringList.Create;
  FIndexes := TStringList.Create;
  FIndexes.Sorted := True;
end;

destructor TQFDBinaryStreamHelper.Destroy;
begin
  FreeAndNil(FDictionary);
  FreeAndNil(FIndexes);
  inherited;
end;

procedure TQFDBinaryStreamHelper.EndRead;
begin
  inherited;
end;

procedure TQFDBinaryStreamHelper.EndWrite;
var
  AHdr: TFdBinaryHeader;
  ASize: Int64;
  I: Integer;
  L: Word;
  S: QStringW;
begin
  AHdr.DictionaryOffset := Cardinal(FStream.Position);
  for I := 0 to FDictionary.Count - 1 do
  begin
    S := FDictionary[I];
    L := Length(S) shl 1;
    FStream.WriteBuffer(L, SizeOf(Word));
    FStream.WriteBuffer(PWideChar(S)^, L);
  end;
  ASize := FStream.Position;
  FStream.Position := FStartOffset + IntPtr(@AHdr.DictionaryOffset) -
    IntPtr(@AHdr);
  FStream.WriteBuffer(AHdr.DictionaryOffset, SizeOf(Cardinal));
  FStream.Position := ASize;
end;

function TQFDBinaryStreamHelper.IndexOfName(const S: String): Integer;
var
  AIdx: Integer;
begin
  if FIndexes.Find(S, AIdx) then
  begin
    Result := Integer(FIndexes.Objects[AIdx]);
  end
  else
  begin
    Result := FDictionary.Add(S);
    FIndexes.AddObject(S, TObject(Result));
  end;
end;

function TQFDBinaryStreamHelper.IsObject(AName: QStringW): Boolean;
var
  AHdr: TFdObjectHeader;
begin
  FStream.ReadBuffer(AHdr, SizeOf(AHdr));
  if AHdr.Magic = FD_OBJECT_BEGIN then
    Result := FDictionary[AHdr.NameIndex] = AName
  else
    Result := false;
  FStream.Seek(-SizeOf(AHdr), soCurrent);
end;

function TQFDBinaryStreamHelper.IsProp(AName: QStringW): Boolean;
var
  AIdx: Word;
begin
  FStream.ReadBuffer(AIdx, SizeOf(Word));
  if ((AIdx and $FF) < $FE) then
    Result := FDictionary[AIdx] = AName
  else
    Result := false;
  FStream.Seek(-SizeOf(Word), soCurrent);
end;

function TQFDBinaryStreamHelper.ObjectBeginRead(const AExpectName: QStringW;
  ACheckClass: Boolean): Boolean;
var
  AHdr: TFdObjectHeader;
begin
  FStream.ReadBuffer(AHdr, SizeOf(AHdr));
  if AHdr.Magic = FD_OBJECT_BEGIN then
    Result := FDictionary[AHdr.NameIndex] = AExpectName
  else
    Result := false;
  if not Result then
    FStream.Seek(-SizeOf(AHdr), soCurrent);
end;

procedure TQFDBinaryStreamHelper.ObjectBeginWrite(const AName: QStringW;
  AIsArray, AWriteClass: Boolean);
var
  AHdr: TFdObjectHeader;
  I: Integer;
begin
  AHdr.Magic := $FF;
  I := IndexOfName(AName);
  AHdr.NameIndex := Byte(I);
  PushObject(FStream.Position, AName, AIsArray);
  FStream.WriteBuffer(AHdr, SizeOf(AHdr));
end;

procedure TQFDBinaryStreamHelper.ObjectEndRead;
var
  AMagic: Byte;
begin
  FStream.ReadBuffer(AMagic, SizeOf(AMagic));
  if AMagic <> FD_OBJECT_END then
    raise Exception.Create(SBadStreamFormat);
  PopObject;
end;

procedure TQFDBinaryStreamHelper.ObjectEndWrite;
const
  AEndOfObj: Byte = $FE;
begin
  FStream.WriteBuffer(AEndOfObj, SizeOf(Byte));
  PopObject;
end;

function TQFDBinaryStreamHelper.PrepareRead: Boolean;
var
  ALen: Word;
  S: QStringW;
  AHdr: TFdBinaryHeader;
begin
  inherited;
  FStartOffset := FStream.Position;
  if (FStream.Read(AHdr, SizeOf(AHdr)) <> SizeOf(AHdr)) or
    not CompareMem(@AHdr.Magic[0], @StreamMagic[0], SizeOf(StreamMagic)) then
    Result := false
  else
  begin
    if AHdr.Version < 6 then
      Result := false
    else
    begin
      FVersion := AHdr.Version;
      Result := True;
      FStream.Seek(AHdr.DictionaryOffset, soBeginning);
      FDictionary.BeginUpdate;
      FIndexes.BeginUpdate;
      try
        FDictionary.Clear;
        FIndexes.Clear;
        while FStream.Read(ALen, SizeOf(ALen)) = SizeOf(ALen) do
        begin
          SetLength(S, ALen shr 1);
          if ALen > 0 then
            FStream.Read(PWideChar(S)^, ALen);
          FIndexes.AddObject(S, TObject(FDictionary.Add(S)));
        end;
      finally
        FDictionary.EndUpdate;
        FIndexes.EndUpdate;
        FStream.Seek(SizeOf(AHdr), soBeginning);
      end;
    end;
  end;
end;

function TQFDBinaryStreamHelper.PrepareWrite: Boolean;
var
  AHdr: TFdBinaryHeader;
begin
  Result := True;
  FStartOffset := FStream.Position;
  FDictionary.Clear;
  FIndexes.Clear;
  PInteger(@AHdr.Magic[0])^ := PInteger(@StreamMagic)^;
  AHdr.Version := 15;
  AHdr.DictionaryOffset := 0;
  FStream.WriteBuffer(AHdr, SizeOf(AHdr));
end;

function TQFDBinaryStreamHelper.PropRead(const AExpectName: QStringW; var ABuf;
  ASize: Integer): Boolean;
var
  AIdx: Word;
begin
  FStream.ReadBuffer(AIdx, SizeOf(Word));
  if ((AIdx and $FF) < $FE) then
  begin
    Result := AExpectName = FDictionary[AIdx];
    if Result then
    begin
      FStream.ReadBuffer(ABuf, ASize);
      Exit;
    end;
  end;
  Result := false;
  FStream.Seek(-SizeOf(Word), soCurrent);
end;

function TQFDBinaryStreamHelper.PropReadAnsiStr(const AName, ADefVal: QStringW)
  : QStringW;
var
  ALen: Cardinal;
  AIdx: Word;
  ABuf: QStringA;
begin
  FStream.ReadBuffer(AIdx, SizeOf(Word));
  if ((AIdx and $FF) < $FE) and (AName = FDictionary[AIdx]) then
  begin
    FStream.ReadBuffer(ALen, SizeOf(Cardinal));
    if ALen > 0 then
    begin
      ABuf.Length := ALen;
      FStream.ReadBuffer(PQCharA(ABuf)^, ALen);
      Result := qstring.AnsiDecode(ABuf);
    end
    else
      SetLength(Result, 0);
  end
  else
  begin
    FStream.Seek(-SizeOf(Word), soCurrent);
    Result := ADefVal;
  end;
end;

function TQFDBinaryStreamHelper.PropReadBool(const AName: QStringW;
  ADefVal: Boolean): Boolean;
begin
  if not PropRead(AName, Result, SizeOf(Result)) then
    Result := ADefVal;
end;

function TQFDBinaryStreamHelper.PropReadDate(const AName: QStringW;
  ADefValue: TDateTime): TDateTime;
begin
  if not PropRead(AName, Result, SizeOf(Result)) then
    Result := ADefValue;
end;

function TQFDBinaryStreamHelper.PropReadFloat(const AName: QStringW;
  ADefVal: Double): Double;
begin
  if not PropRead(AName, Result, SizeOf(Result)) then
    Result := ADefVal;
end;

function TQFDBinaryStreamHelper.PropReadInt64(const AName: QStringW;
  ADefVal: Int64): Int64;
begin
  if not PropRead(AName, Result, SizeOf(Result)) then
    Result := ADefVal;
end;

function TQFDBinaryStreamHelper.PropReadInteger(const AName: QStringW;
  ADefVal: Integer): Integer;
begin
  if not PropRead(AName, Result, SizeOf(Result)) then
    Result := ADefVal;
end;

function TQFDBinaryStreamHelper.PropReadLongword(const AName: QStringW;
  ADefVal: Cardinal): Cardinal;
begin
  if not PropRead(AName, Result, SizeOf(Result)) then
    Result := ADefVal;
end;

function TQFDBinaryStreamHelper.PropReadStr(const AName, ADefVal: QStringW)
  : QStringW;
var
  ALen: Cardinal;
  AIdx: Word;
begin
  FStream.ReadBuffer(AIdx, SizeOf(Word));
  if ((AIdx and $FF) < $FE) and (AName = FDictionary[AIdx]) then
  begin
    FStream.ReadBuffer(ALen, SizeOf(Cardinal));
    SetLength(Result, ALen shr 1);
    if ALen > 0 then
      FStream.ReadBuffer(PWideChar(Result)^, ALen);
  end
  else
  begin
    FStream.Seek(-SizeOf(Word), soCurrent);
    Result := ADefVal;
  end;
end;

function TQFDBinaryStreamHelper.PropReadWord(const AName: QStringW;
  ADefVal: Word): Word;
begin
  if not PropRead(AName, Result, SizeOf(Result)) then
    Result := ADefVal;
end;

procedure TQFDBinaryStreamHelper.PropWrite(const AName: QStringW; const ABuf;
  ASize: Integer);
var
  AIdx: Word;
  I: Integer;
begin
  I := IndexOfName(AName);
  AIdx := Word(I);
  FStream.WriteBuffer(AIdx, SizeOf(Word));
  FStream.WriteBuffer(ABuf, ASize);
end;

procedure TQFDBinaryStreamHelper.PropWriteAnsi(const AName, AValue: QStringW);
var
  S: QStringA;
  L: Cardinal;
begin
  S := AnsiEncode(AValue);
  L := S.Length;
  PropWrite(AName, L, SizeOf(Cardinal));
  FStream.WriteBuffer(PQCharA(S)^, L);
end;

procedure TQFDBinaryStreamHelper.PropWriteBool(const AName: QStringW;
  AValue: Boolean);
begin
  PropWrite(AName, AValue, SizeOf(AValue));
end;

procedure TQFDBinaryStreamHelper.PropWriteDate(const AName: QStringW;
  AValue: TDateTime);
begin
  PropWrite(AName, AValue, SizeOf(AValue));
end;

procedure TQFDBinaryStreamHelper.PropWriteFloat(const AName: QStringW;
  AValue: Double);
begin
  PropWrite(AName, AValue, SizeOf(AValue));
end;

procedure TQFDBinaryStreamHelper.PropWriteInt64(const AName: QStringW;
  AValue: Int64);
begin
  PropWrite(AName, AValue, SizeOf(AValue));
end;

procedure TQFDBinaryStreamHelper.PropWriteInteger(const AName: QStringW;
  AValue: Integer);
begin
  PropWrite(AName, AValue, SizeOf(AValue));
end;

procedure TQFDBinaryStreamHelper.PropWriteLongWord(const AName: QStringW;
  AValue: Cardinal);
begin
  PropWrite(AName, AValue, SizeOf(AValue));
end;

procedure TQFDBinaryStreamHelper.PropWriteStr(const AName, AValue: QStringW);
var
  L: Cardinal;
begin
  L := Length(AValue) shl 1;
  PropWrite(AName, L, SizeOf(Cardinal));
  FStream.WriteBuffer(PQCharW(AValue)^, L);
end;

procedure TQFDBinaryStreamHelper.PropWriteWord(const AName: QStringW;
  AValue: Word);
begin
  PropWrite(AName, AValue, SizeOf(AValue));
end;

function TQFDBinaryStreamHelper.ReadRowState: TUpdateStatus;
var
  AName: QStringW;
begin
  AName := FDictionary[PropReadWord('RowState', 0)];
  if AName = 'rsInserted' then
    Result := usInserted
  else if AName = 'rsDeleted' then
    Result := usDeleted
  else if AName = 'rsModified' then
    Result := usModified
  else
    Result := usUnmodified;
end;

function TQFDBinaryStreamHelper.ReadType: Word;
begin
  Result := FDTypeNameToType(FDictionary[PropReadWord('DataType', 0)]);
end;

function TQFDBinaryStreamHelper.ReadValue(const AFieldName: QStringW;
  AFieldIndex, AFdType: Word; var AValue: TQValue): Boolean;
var
  AColIdx: Word;
  ALen: Cardinal;
  procedure ReadBcd;
  var
    L: Byte;
  begin
    FStream.Read(L, SizeOf(Byte));
    AValue.TypeNeeded(vdtBcd);
    if L <> 0 then
      FStream.ReadBuffer(AValue.Value.AsBcd^, L);
    FillChar((PByte(AValue.Value.AsBcd) + L)^, SizeOf(TBcd) - L, 0);
  end;
  procedure AsDate;
  var
    AStamp: TTimeStamp;
  begin
    AValue.TypeNeeded(vdtDateTime);
    FStream.ReadBuffer(AStamp.Date, SizeOf(Integer));
    AStamp.Time := 0;
    AValue.Value.AsDateTime := TimeStampToDateTime(AStamp);
  end;
  procedure ReadDateTime;
  var
    ADT: TDateTimeAlias;
  begin
    AValue.TypeNeeded(vdtDateTime);
    FStream.ReadBuffer(ADT, SizeOf(ADT));
    AValue.Value.AsDateTime := TimeStampToDateTime(MSecsToTimeStamp(ADT));
  end;
  procedure AsTime;
  var
    ATime: Integer;
  begin
    AValue.TypeNeeded(vdtDateTime);
    FStream.ReadBuffer(ATime, SizeOf(Integer));
    AValue.Value.AsDateTime := ATime / (24.0 * 60.0 * 60.0 * 1000.0)
  end;

  procedure AsTimeStamp;
  var
    AStamp: TSQLTimeStamp;
  begin
    AValue.TypeNeeded(vdtDateTime);
    FStream.ReadBuffer(AStamp, SizeOf(TSQLTimeStamp));
    AValue.Value.AsDateTime := SQLTimeStampToDateTime(AStamp);
  end;

  procedure AsInterval(AType: Integer);
  var
    AInterval: TFDInterval;
  begin
    AValue.TypeNeeded(vdtInterval);
    FStream.ReadBuffer(AInterval, SizeOf(TFDInterval));
    case AType of
      0:
        case TFDIntervalKind(AInterval.Kind) of
          itYear:
            begin
              if AInterval.Sign < 0 then
                AValue.Value.AsInterval.Encode(-AInterval.Years, 0, 0)
              else
                AValue.Value.AsInterval.Encode(AInterval.Years, 0, 0);
            end;
          itMonth:
            begin
              if AInterval.Sign < 0 then
                AValue.Value.AsInterval.Encode(0, -AInterval.Months, 0)
              else
                AValue.Value.AsInterval.Encode(0, AInterval.Months, 0);
            end;
          itDay:
            begin
              if AInterval.Sign < 0 then
                AValue.Value.AsInterval.Encode(0, 0, -AInterval.Days)
              else
                AValue.Value.AsInterval.Encode(0, 0, AInterval.Days);
            end;
          itHour:
            begin
              if AInterval.Sign < 0 then
                AValue.Value.AsInterval.Encode(0, 0, 0,
                  -AInterval.Hours, 0, 0, 0)
              else
                AValue.Value.AsInterval.Encode(0, 0, 0,
                  AInterval.Hours, 0, 0, 0);
            end;
          itMinute:
            begin
              if AInterval.Sign < 0 then
                AValue.Value.AsInterval.Encode(0, 0, 0, 0,
                  -AInterval.Minutes, 0, 0)
              else
                AValue.Value.AsInterval.Encode(0, 0, 0, 0,
                  AInterval.Minutes, 0, 0);
            end;
          itSecond:
            begin
              if AInterval.Sign < 0 then
                AValue.Value.AsInterval.Encode(0, 0, 0, 0, 0,
                  -AInterval.Seconds, 0)
              else
                AValue.Value.AsInterval.Encode(0, 0, 0, 0, 0,
                  AInterval.Seconds, 0);
            end;
          itYear2Month:
            begin
              if AInterval.Sign < 0 then
                AValue.Value.AsInterval.Encode(-AInterval.Years,
                  AInterval.Months, 0)
              else
                AValue.Value.AsInterval.Encode(AInterval.Years,
                  AInterval.Months, 0);
            end;
          itDay2Hour:
            begin
              if AInterval.Sign < 0 then
                AValue.Value.AsInterval.Encode(0, 0, -AInterval.Days,
                  AInterval.Hours, 0, 0, 0)
              else
                AValue.Value.AsInterval.Encode(0, 0, AInterval.Days,
                  AInterval.Hours, 0, 0, 0)
            end;
          itDay2Minute:
            begin
              if AInterval.Sign < 0 then
                AValue.Value.AsInterval.Encode(0, 0, -AInterval.Days,
                  AInterval.Hours, AInterval.Minutes, 0, 0)
              else
                AValue.Value.AsInterval.Encode(0, 0, AInterval.Days,
                  AInterval.Hours, AInterval.Minutes, 0, 0);
            end;
          itDay2Second:
            begin
              if AInterval.Sign < 0 then
                AValue.Value.AsInterval.Encode(0, 0, -AInterval.Days,
                  AInterval.Hours, AInterval.Minutes, AInterval.Seconds, 0)
              else
                AValue.Value.AsInterval.Encode(0, 0, AInterval.Days,
                  AInterval.Hours, AInterval.Minutes, AInterval.Seconds, 0);
            end;
          itHour2Minute:
            begin
              if AInterval.Sign < 0 then
                AValue.Value.AsInterval.Encode(0, 0, 0, -AInterval.Hours,
                  AInterval.Minutes, 0, 0)
              else
                AValue.Value.AsInterval.Encode(0, 0, 0, AInterval.Hours,
                  AInterval.Minutes, 0, 0)
            end;
          itHour2Second:
            begin
              if AInterval.Sign < 0 then
                AValue.Value.AsInterval.Encode(0, 0, 0, -AInterval.Hours,
                  AInterval.Minutes, AInterval.Seconds, 0)
              else
                AValue.Value.AsInterval.Encode(0, 0, 0, AInterval.Hours,
                  AInterval.Minutes, AInterval.Seconds, 0)
            end;
          itMinute2Second:
            begin
              if AInterval.Sign < 0 then
                AValue.Value.AsInterval.Encode(0, 0, 0, 0, -AInterval.Minutes,
                  AInterval.Seconds, 0)
              else
                AValue.Value.AsInterval.Encode(0, 0, 0, 0, AInterval.Minutes,
                  AInterval.Seconds, 0)
            end;
        end; // Full Interval
      1: // Year-Month
        begin
          if AInterval.Sign < 0 then
            AValue.Value.AsInterval.Encode(-AInterval.Years,
              AInterval.Months, 0)
          else
            AValue.Value.AsInterval.Encode(AInterval.Years,
              AInterval.Months, 0);
        end;
      2: // DS
        begin
          if AInterval.Sign < 0 then
            AValue.Value.AsInterval.Encode(0, 0, -AInterval.Days,
              AInterval.Hours, AInterval.Minutes, AInterval.Seconds, 0)
          else
            AValue.Value.AsInterval.Encode(0, 0, AInterval.Days,
              AInterval.Hours, AInterval.Minutes, AInterval.Seconds, 0);
        end;
    end;
  end;
  procedure AsAnsiString;
  var
    S: QStringA;
  begin
    AValue.TypeNeeded(vdtString);
    FStream.ReadBuffer(ALen, SizeOf(Cardinal));
    S.Length := ALen;
    FStream.ReadBuffer(S.Data^, ALen);
    AValue.Value.AsString^ := AnsiDecode(S);
  end;

  procedure AsExtended;
  var
    AExtend:Extended;
  begin
    AValue.TypeNeeded(vdtFloat);
    if SizeOf(Extended) = SizeOf(Double) then
      FStream.ReadBuffer(AValue.Value.AsFloat, SizeOf(Double))
    else
    begin
      FStream.ReadBuffer(AExtend, SizeOf(Extended));
      AValue.Value.AsFloat := AExtend;
    end;
  end;

begin
  FStream.ReadBuffer(AColIdx, SizeOf(Word));
  if AColIdx <> AFieldIndex then
  begin
    AValue.TypeNeeded(vdtNull);
    FStream.Seek(-SizeOf(Word), soCurrent);
    Result := false;
  end
  else
  begin
    Result := True;
    case AFdType of
      1: // dtBoolean(1):
        begin
          AValue.TypeNeeded(vdtBoolean);
          FStream.ReadBuffer(AValue.Value.AsWord, SizeOf(WordBool));
          AValue.Value.AsBoolean := AValue.Value.AsWord <> 0;
        end;
      2: // dtSByte(2)
        begin
          AValue.TypeNeeded(vdtInteger);
          FStream.ReadBuffer(AValue.Value.AsShort, SizeOf(Shortint));
          AValue.Value.AsInteger := AValue.Value.AsShort;
        end;
      3: // dtInt16(3)
        begin
          AValue.TypeNeeded(vdtInteger);
          FStream.ReadBuffer(AValue.Value.AsSmallint, SizeOf(Smallint));
          AValue.Value.AsInteger := AValue.Value.AsSmallint;
        end;
      4: // dtInt32(4)
        begin
          AValue.TypeNeeded(vdtInteger);
          FStream.ReadBuffer(AValue.Value.AsInteger, SizeOf(Integer));
        end;
      5: // dtInt64(5)
        begin
          AValue.TypeNeeded(vdtInt64);
          FStream.ReadBuffer(AValue.Value.AsInt64, SizeOf(Int64));
        end;
      6: // dtByte(6)
        begin
          AValue.TypeNeeded(vdtInteger);
          FStream.ReadBuffer(AValue.Value.AsByte, SizeOf(Byte));
        end;
      7: // dtUInt16(7)
        begin
          AValue.TypeNeeded(vdtInteger);
          FStream.ReadBuffer(AValue.Value.AsWord, SizeOf(Word));
        end;
      8, 38: // dtUInt32(8),dtParentRowRef(38)
        begin
          AValue.TypeNeeded(vdtInt64);
          FStream.ReadBuffer(AValue.Value.AsInteger, SizeOf(Cardinal));
        end;
      9: // dtUInt64(9)
        begin
          AValue.TypeNeeded(vdtInt64);
          FStream.ReadBuffer(AValue.Value.AsInt64, SizeOf(Int64));
        end;
      10: // dtSingle(10)
        begin
          AValue.TypeNeeded(vdtSingle);
          FStream.ReadBuffer(AValue.Value.AsSingle, SizeOf(Single));
        end;
      11: // dtDouble(11)
        begin
          AValue.TypeNeeded(vdtFloat);
          FStream.ReadBuffer(AValue.Value.AsFloat, SizeOf(Double));
        end;
      12: // dtExtended(12)
        AsExtended;
      13: // dtCurrency(13)
        begin
          AValue.TypeNeeded(vdtCurrency);
          FStream.ReadBuffer(AValue.Value.AsCurrency, SizeOf(Currency));
        end;
      14, 15: // dtBCD(14),dtFmtBCD(15)
        ReadBcd;
      16: // dtDateTime(16):
        ReadDateTime;
      17: // dtTime(17)
        AsTime;
      18: // dtDate(18):
        AsDate;
      19: // dtDateTimeStamp(19)
        AsTimeStamp;
      20: // dtTimeIntervalFull(20)
        AsInterval(0);
      21: // dtTimeIntervalYM(21)
        AsInterval(1);
      22: // dtTimeIntervalDS(22)
        AsInterval(2);
      23: // dtAnsiString(23)
        AsAnsiString;
      24: // dtWideString(24)
        begin
          FStream.ReadBuffer(ALen, SizeOf(Cardinal));
          AValue.TypeNeeded(vdtString);
          SetLength(AValue.Value.AsString^, ALen shr 1);
          FStream.ReadBuffer(PWideChar(AValue.Value.AsString^)^, ALen);
        end;
      25, 26, 27, 28 .. 33:
        // dtByteString(25),dtBlob(26),dtMemo(27),dtWideMemo(28),dtXML(29),dtHBlob(30), dtHMemo(31), dtWideHMemo(32), dtHBFile(33)
        begin
          FStream.ReadBuffer(ALen, SizeOf(Cardinal));
          AValue.TypeNeeded(vdtStream);
          if ALen > 0 then
            TQValueStream(AValue.Value.AsStream).CopyFrom(FStream, ALen)
          else
            TQValueStream(AValue.Value.AsStream).Size := 0;
        end;
      39: // dtGUID(39)
        begin
          AValue.TypeNeeded(vdtGuid);
          FStream.ReadBuffer(AValue.Value.AsGuid^, SizeOf(TGuid));
        end;
    end;
  end;
end;

procedure TQFDBinaryStreamHelper.WriteRowState(AStatus: TUpdateStatus);
var
  I: Integer;
  AName: QStringW;
begin
  case AStatus of
    usUnmodified:
      Exit;
    usModified:
      AName := 'rsModified';
    usInserted:
      AName := 'rsInserted';
    usDeleted:
      AName := 'rsDeleted';
  end;
  I := IndexOfName(AName);
  PropWriteWord('RowState', Word(I));
end;

procedure TQFDBinaryStreamHelper.WriteType(AType: Word);
var
  AValue: Word;
begin
  AValue := IndexOfName(TypeNames[AType]);
  PropWriteWord('DataType', AValue);
end;

procedure TQFDBinaryStreamHelper.WriteValue(const AFieldName: QStringW;
  AFieldIndex, AFdType: Word; var AValue: TQValue);
var
  ALen: Cardinal;
  procedure AsBcd;
  var
    L: Byte;
  begin
    L := 2 + (AValue.Value.AsBcd^.Precision + 1) div 2;
    FStream.WriteBuffer(L, SizeOf(Byte));
    FStream.Write(AValue.Value.AsBcd^, L);
  end;

  procedure AsDate;
  var
    AStamp: TTimeStamp;
  begin
    AStamp := DateTimeToTimeStamp(AValue.Value.AsDateTime);
    FStream.WriteBuffer(AStamp.Date, SizeOf(Integer));
  end;

  procedure AsTime;
  var
    ATime: Integer;
  begin
    ATime := Trunc((AValue.Value.AsDateTime - Trunc(AValue.Value.AsDateTime)) *
      24 * 60 * 60 * 1000);
    FStream.WriteBuffer(ATime, SizeOf(Integer));
  end;
  procedure AsDateTime;
  var
    ADT: TDateTimeAlias;
  begin
    ADT := TimeStampToMSecs(DateTimeToTimeStamp(AValue.Value.AsDateTime));
    FStream.WriteBuffer(ADT, SizeOf(ADT));
  end;

  procedure AsTimeStamp;
  var
    AStamp: TSQLTimeStamp;
  begin
    AStamp := DateTimeToSQLTimeStamp(AValue.Value.AsDateTime);
    FStream.WriteBuffer(AStamp, SizeOf(TSQLTimeStamp));
  end;

  procedure AsInterval(AType: Integer);
  var
    AInterval: TFDInterval;
  begin
    FillChar(AInterval, SizeOf(TFDInterval), 0);
    case AType of
      0:
        begin
          if AValue.Value.AsInterval.IsNeg then
          begin
            AInterval.Sign := -1;
            if AValue.Value.AsInterval.YearMonth <> 0 then
            begin
              AInterval.Kind := Integer(itYear2Month);
              AInterval.Years := -AValue.Value.AsInterval.Year;
              AInterval.Months := AValue.Value.AsInterval.Month;
            end
            else
            begin
              AInterval.Kind := Integer(itDay2Second);
              AInterval.Days := -AValue.Value.AsInterval.Day;
              AInterval.Hours := AValue.Value.AsInterval.Hour;
              AInterval.Minutes := AValue.Value.AsInterval.Minute;
              AInterval.Seconds := AValue.Value.AsInterval.Second;
              AInterval.Fractions := AValue.Value.AsInterval.MilliSecond;
            end;
          end
          else
          begin
            AInterval.Sign := 1;
            if AValue.Value.AsInterval.YearMonth <> 0 then
            begin
              AInterval.Kind := Integer(itYear2Month);
              AInterval.Years := -AValue.Value.AsInterval.Year;
              AInterval.Months := AValue.Value.AsInterval.Month;
            end
            else
            begin
              AInterval.Kind := Integer(itDay2Second);
              AInterval.Days := -AValue.Value.AsInterval.Day;
              AInterval.Hours := AValue.Value.AsInterval.Hour;
              AInterval.Minutes := AValue.Value.AsInterval.Minute;
              AInterval.Seconds := AValue.Value.AsInterval.Second;
              AInterval.Fractions := AValue.Value.AsInterval.MilliSecond;
            end;
          end;
        end; // Full Interval
      1: // Year-Month
        begin
          AInterval.Kind := Integer(itDay2Second);
          if AValue.Value.AsInterval.IsNeg then
            AInterval.Sign := -1;
          if AInterval.Sign > 0 then
          begin
            AInterval.Years := AValue.Value.AsInterval.Year;
            AInterval.Months := AValue.Value.AsInterval.Month;
          end
          else
          begin
            AInterval.Years := -AValue.Value.AsInterval.Year;
            AInterval.Months := -AValue.Value.AsInterval.Month;
          end;
        end;
      2: // DS
        begin
          AInterval.Kind := Integer(itDay2Second);
          AInterval.Days := -AValue.Value.AsInterval.Day;
          AInterval.Hours := AValue.Value.AsInterval.Hour;
          AInterval.Minutes := AValue.Value.AsInterval.Minute;
          AInterval.Seconds := AValue.Value.AsInterval.Second;
          AInterval.Fractions := AValue.Value.AsInterval.MilliSecond;
        end;
    end;
    FStream.WriteBuffer(AInterval, SizeOf(AInterval));
  end;
  procedure AsAnsiString;
  var
    S: QStringA;
  begin
    S := qstring.AnsiEncode(AValue.Value.AsString^);
    ALen := S.Length;
    FStream.WriteBuffer(ALen, SizeOf(Cardinal));
    FStream.WriteBuffer(S.Data^, ALen);
  end;
  procedure AsExtended;
{$IFDEF WIN32}
  var
    AExt: Extended;
  begin
    AExt := AValue.Value.AsFloat;
    // QDAC 不支持Extended类型，强制使用Double
    FStream.WriteBuffer(AExt, SizeOf(AExt));
  end;
{$ELSE}

  begin
    FStream.WriteBuffer(AValue.Value.AsFloat, SizeOf(Double));
  end;
{$ENDIF}

begin
if AValue.IsNull then
  Exit;
FStream.WriteBuffer(AFieldIndex, SizeOf(Word));
case AFdType of
  1: // dtBoolean(1):
    FStream.WriteBuffer(AValue.Value.AsWord, SizeOf(WordBool));
  2: // dtSByte(2)
    FStream.WriteBuffer(AValue.Value.AsShort, SizeOf(Shortint));
  3: // dtInt16(3)
    FStream.WriteBuffer(AValue.Value.AsSmallint, SizeOf(Smallint));
  4: // dtInt32(4)
    FStream.WriteBuffer(AValue.Value.AsInteger, SizeOf(Integer));
  5: // dtInt64(5)
    FStream.WriteBuffer(AValue.Value.AsInt64, SizeOf(Int64));
  6: // dtByte(6)
    FStream.WriteBuffer(AValue.Value.AsByte, SizeOf(Byte));
  7: // dtUInt16(7)
    FStream.WriteBuffer(AValue.Value.AsWord, SizeOf(Word));
  8, 38: // dtUInt32(8),dtParentRowRef(38)
    FStream.WriteBuffer(AValue.Value.AsInteger, SizeOf(Cardinal));
  9: // dtUInt64(9)
    FStream.WriteBuffer(AValue.Value.AsInt64, SizeOf(Int64));
  10: // dtSingle(10)
    FStream.WriteBuffer(AValue.Value.AsSingle, SizeOf(Single));
  11: // dtDouble(11)
    FStream.WriteBuffer(AValue.Value.AsFloat, SizeOf(Double));
  12: // dtExtended(12)
    AsExtended;
  13: // dtCurrency(13)
    FStream.WriteBuffer(AValue.Value.AsCurrency, SizeOf(Currency));
  14, 15: // dtBCD(14),dtFmtBCD(15)
    AsBcd;
  16: // dtDateTime(16):
    AsDateTime;
  17: // dtTime(17)
    AsTime;
  18: // dtDate(18):
    AsDate;
  19: // dtDateTimeStamp(19)
    AsTimeStamp;
  20: // dtTimeIntervalFull(20)
    AsInterval(0);
  21: // dtTimeIntervalYM(21)
    AsInterval(1);
  22: // dtTimeIntervalDS(22)
    AsInterval(2);
  23: // dtAnsiString(23)
    AsAnsiString;
  24: // dtWideString(24)
    begin
      ALen := Length(AValue.Value.AsString^) shl 1;
      FStream.WriteBuffer(ALen, SizeOf(Cardinal));
      if ALen > 0 then
        FStream.WriteBuffer(PWideChar(AValue.Value.AsString^)^, ALen);
    end;
  25, 26, 27, 28 .. 33:
    // dtByteString(25),dtBlob(26),dtMemo(27),dtWideMemo(28),dtXML(29),dtHBlob(30), dtHMemo(31), dtWideHMemo(32), dtHBFile(33)
    begin
      ALen := Cardinal(TQValueStream(AValue.Value.AsStream).Size);
      FStream.WriteBuffer(ALen, SizeOf(Cardinal));
      FStream.CopyFrom(TQValueStream(AValue.Value.AsStream), 0);
    end;
  39: // dtGUID(39)
    FStream.WriteBuffer(AValue.Value.AsGuid^, SizeOf(TGuid));
end;
end;

{ TQFDBinaryConverter }

procedure TQFDBinaryConverter.HelperNeeded;
begin
  FHelper := TQFDBinaryStreamHelper.Create(Self);
end;

{ TQFDJsonStreamHelper }

constructor TQFDJsonStreamHelper.Create(AOwner: TQFDConverter);
begin
  inherited;
  FJson := TQJson.Create;
end;

destructor TQFDJsonStreamHelper.Destroy;
begin
  FreeAndNil(FJson);
  inherited;
end;

procedure TQFDJsonStreamHelper.EndRead;
begin
  inherited;
  PopObject;
end;

procedure TQFDJsonStreamHelper.EndWrite;
begin
  inherited;
  FJson.SaveToStream(FStream, teUtf8, false, false);
  PopObject;
end;

function TQFDJsonStreamHelper.IsObject(AName: QStringW): Boolean;
var
  AItem: TQJson;
begin
  if FParent.HasChild(AName, AItem) then
    Result := AItem.DataType in [jdtArray, jdtObject]
  else
    Result := false
end;

function TQFDJsonStreamHelper.IsProp(AName: QStringW): Boolean;
var
  AItem: TQJson;
begin
  if FParent.HasChild(AName, AItem) then
    Result := not(AItem.DataType in [jdtArray, jdtObject])
  else
    Result := false
end;

function TQFDJsonStreamHelper.ObjectBeginRead(const AExpectName: QStringW;
  ACheckClass: Boolean): Boolean;
var
  AItem: TQJson;
  I: Integer;
begin
  Result := false;
  AItem := nil;
  if FParent.IsObject then
  begin
    I := FParent.IndexOf(AExpectName);
    if I <> -1 then
    begin
      AItem := FParent[I];
      if AItem.DataType in [jdtObject, jdtArray] then
        Result := True;
    end;
  end
  else
  begin
    for I := FLastObject.Offset to FParent.Count - 1 do
    begin
      AItem := FParent[I];
      if (not ACheckClass) or (AItem.ValueByName('class', '') = AExpectName)
      then
      begin
        Result := True;
        Break;
      end;
    end;
  end;
  if Result then
  begin
    FLastObject.Offset := AItem.ItemIndex + 1;
    FParent := AItem;
    PushObject(0, AExpectName, FParent.IsArray);
  end;
end;

procedure TQFDJsonStreamHelper.ObjectBeginWrite(const AName: QStringW;
  AIsArray, AWriteClass: Boolean);
begin
  PushObject(FParent.Count, AName, AIsArray);
  if AIsArray then
    FParent := FParent.AddArray(AName)
  else
  begin
    if FParent.IsArray then
    begin
      FParent := FParent.Add;
      if AWriteClass then
        FParent.Add('class').AsString := AName;
    end
    else
      FParent := FParent.Add(AName, jdtObject);
  end;
end;

procedure TQFDJsonStreamHelper.ObjectEndRead;
begin
  FParent := FParent.Parent;
  PopObject;
end;

procedure TQFDJsonStreamHelper.ObjectEndWrite;
begin
  FParent := FParent.Parent;
  PopObject;
end;

function TQFDJsonStreamHelper.PrepareRead: Boolean;
begin
  FJson.LoadFromStream(FStream);
  if FJson.HasChild('FDBS', FParent) then
  begin
    FVersion := FParent.IntByName('Version', 15);
    Result := True;
    PushObject(0, 'FDBS', false);
  end
  else
    Result := false;
end;

function TQFDJsonStreamHelper.PrepareWrite: Boolean;
begin
  FJson.Clear;
  FParent := FJson.Add('FDBS');
  FParent.Add('Version', 15);
  Result := True;
end;

function TQFDJsonStreamHelper.PropRead(const AExpectName: QStringW; var ABuf;
  ASize: Integer): Boolean;
begin
  Result := false; // 这个不需要
end;

function TQFDJsonStreamHelper.PropReadAnsiStr(const AName, ADefVal: QStringW)
  : QStringW;
begin
  Result := FParent.ValueByName(AName, ADefVal);
end;

function TQFDJsonStreamHelper.PropReadBool(const AName: QStringW;
  ADefVal: Boolean): Boolean;
begin
  Result := FParent.BoolByName(AName, ADefVal);
end;

function TQFDJsonStreamHelper.PropReadDate(const AName: QStringW;
  ADefValue: TDateTime): TDateTime;
begin
  Result := FParent.FloatByName(AName, ADefValue);
end;

function TQFDJsonStreamHelper.PropReadFloat(const AName: QStringW;
  ADefVal: Double): Double;
begin
  Result := FParent.FloatByName(AName, ADefVal);
end;

function TQFDJsonStreamHelper.PropReadInt64(const AName: QStringW;
  ADefVal: Int64): Int64;
begin
  Result := FParent.IntByName(AName, ADefVal);
end;

function TQFDJsonStreamHelper.PropReadInteger(const AName: QStringW;
  ADefVal: Integer): Integer;
begin
  Result := FParent.IntByName(AName, ADefVal);
end;

function TQFDJsonStreamHelper.PropReadLongword(const AName: QStringW;
  ADefVal: Cardinal): Cardinal;
begin
  Result := FParent.IntByName(AName, ADefVal);
end;

function TQFDJsonStreamHelper.PropReadStr(const AName, ADefVal: QStringW)
  : QStringW;
begin
  Result := FParent.ValueByName(AName, ADefVal);
end;

function TQFDJsonStreamHelper.PropReadWord(const AName: QStringW;
  ADefVal: Word): Word;
begin
  Result := FParent.IntByName(AName, ADefVal);
end;

procedure TQFDJsonStreamHelper.PropWrite(const AName: QStringW; const ABuf;
  ASize: Integer);
begin
  // Do nothing
end;

procedure TQFDJsonStreamHelper.PropWriteAnsi(const AName, AValue: QStringW);
begin
  FParent.Add(AName).AsString := AValue;
end;

procedure TQFDJsonStreamHelper.PropWriteBool(const AName: QStringW;
  AValue: Boolean);
begin
  FParent.Add(AName).AsBoolean := AValue;
end;

procedure TQFDJsonStreamHelper.PropWriteDate(const AName: QStringW;
  AValue: TDateTime);
begin
  FParent.Add(AName).AsDateTime := AValue;
end;

procedure TQFDJsonStreamHelper.PropWriteFloat(const AName: QStringW;
  AValue: Double);
begin
  FParent.Add(AName).AsFloat := AValue;
end;

procedure TQFDJsonStreamHelper.PropWriteInt64(const AName: QStringW;
  AValue: Int64);
begin
  FParent.Add(AName).AsInt64 := AValue;
end;

procedure TQFDJsonStreamHelper.PropWriteInteger(const AName: QStringW;
  AValue: Integer);
begin
  FParent.Add(AName).AsInt64 := AValue;
end;

procedure TQFDJsonStreamHelper.PropWriteLongWord(const AName: QStringW;
  AValue: Cardinal);
begin
  FParent.Add(AName).AsInt64 := AValue;
end;

procedure TQFDJsonStreamHelper.PropWriteStr(const AName, AValue: QStringW);
begin
  FParent.Add(AName).AsString := AValue;
end;

procedure TQFDJsonStreamHelper.PropWriteWord(const AName: QStringW;
  AValue: Word);
begin
  FParent.Add(AName).AsInt64 := AValue;
end;

function TQFDJsonStreamHelper.ReadRowState: TUpdateStatus;
var
  S: String;
begin
  S := FParent.ValueByName('RowState', '');
  if S = 'rsInserted' then
    Result := usInserted
  else if S = 'rsDeleted' then
    Result := usDeleted
  else if S = 'rsModified' then
    Result := usModified
  else
    Result := usUnmodified;
end;

function TQFDJsonStreamHelper.ReadType: Word;
var
  S: String;
begin
  S := FParent.ValueByName('DataType', '');
  Result := FDTypeNameToType('dt' + S);
end;

function TQFDJsonStreamHelper.ReadValue(const AFieldName: QStringW;
  AFieldIndex, AFdType: Word; var AValue: TQValue): Boolean;
var
  AJson: TQJson;
  procedure AsAnsiMemo;
  var
    S: QStringA;
  begin
    AValue.TypeNeeded(vdtStream);
    S := qstring.AnsiEncode(AJson.AsString);
    AValue.AsStream.WriteBuffer(PQCharA(S)^, S.Length);
  end;
  procedure AsBlob;
  var
    ABytes: TBytes;
  begin
    AValue.TypeNeeded(vdtStream);
    ABytes := qstring.HexToBin(AJson.AsString);
    TQValueStream(AValue.Value.AsStream).WriteBuffer(ABytes[0], Length(ABytes));
  end;

begin
  Result := FParent.HasChild(AFieldName, AJson);
  if not Result then
  begin
    AValue.TypeNeeded(vdtNull);
    Exit;
  end;
  case AFdType of
    1: // dtBoolean(1):
      begin
        AValue.TypeNeeded(vdtBoolean);
        AValue.Value.AsBoolean := AJson.AsBoolean;
      end;
    2, 3, 4, 6, 7: // dtSByte(2),dtInt16(3),dtInt32(4),dtByte(6),dtUInt16(7)
      begin
        AValue.TypeNeeded(vdtInteger);
        AValue.Value.AsInteger := AJson.AsInteger;
      end;
    5, 8, 38, 9: // dtInt64(5),dtUInt32(8),dtParentRowRef(38), dtUInt64(9)
      begin
        AValue.TypeNeeded(vdtInt64);
        AValue.Value.AsInt64 := AJson.AsInt64;
      end;
    10: // dtSingle(10)
      begin
        AValue.TypeNeeded(vdtSingle);
        AValue.Value.AsSingle := AJson.AsFloat;
      end;
    11, 12: // dtDouble(11),dtExtended(12)
      begin
        AValue.TypeNeeded(vdtFloat);
        AValue.Value.AsFloat := AJson.AsFloat;
      end;
    13: // dtCurrency(13)
      begin
        AValue.TypeNeeded(vdtCurrency);
        AValue.Value.AsCurrency := AJson.AsFloat;
      end;
    14, 15: // dtBCD(14),dtFmtBCD(15)
      begin
        AValue.TypeNeeded(vdtBcd);
        AValue.Value.AsBcd^ := DoubleToBcd(AJson.AsFloat);
      end;
    16, 19: // dtDateTime(16),dtDateTimeStamp(19)
      begin
        AValue.TypeNeeded(vdtDateTime);
        AValue.Value.AsDateTime := ParseFDDateTime(AJson.AsString);
      end;
    17: // dtTime(17)
      begin
        AValue.TypeNeeded(vdtDateTime);
        AValue.Value.AsDateTime := ParseFDTime(AJson.AsString);
      end;
    18: // dtDate(18),
      begin
        AValue.TypeNeeded(vdtDateTime);
        AValue.Value.AsDateTime := ParseFDDate(AJson.AsString);
      end;
    20, 21, 22:
      // dtTimeIntervalFull(20),dtTimeIntervalYM(21),dtTimeIntervalDS(22)
      begin
        AValue.TypeNeeded(vdtInterval);
        AValue.Value.AsInterval.AsString := AJson.AsString;
      end;
    23, 24: // dtAnsiString(23),dtWideString(24)
      begin
        AValue.TypeNeeded(vdtString);
        AValue.Value.AsString^ := AJson.AsString;
      end;
    27, 31: // dtMemo(27), dtHMemo(31)
      AsAnsiMemo;
    28, 29, 32: // ,dtWideMemo(28),dtXML(29)dtWideHMemo(32)
      begin
        AValue.TypeNeeded(vdtStream);
        AValue.AsStream.WriteBuffer(PQCharW(AJson.AsString)^,
          Length(AJson.AsString) shl 1);
      end;
    25, 26, 30, 33: // dtByteString(25),dtBlob(26),dtHBlob(30), , dtHBFile(33)
      AsBlob;
    39: // dtGUID(39)
      begin
        AValue.TypeNeeded(vdtGuid);
        AValue.Value.AsGuid^ := StringToGuid(AJson.AsString);
      end;
  end;
end;

procedure TQFDJsonStreamHelper.WriteRowState(AStatus: TUpdateStatus);
begin
  case AStatus of
    usUnmodified:
      ;
    usModified:
      FParent.Add('RowState').AsString := 'Modified';
    usInserted:
      FParent.Add('RowState').AsString := 'Inserted';
    usDeleted:
      FParent.Add('RowState').AsString := 'Deleted';
  end;
end;

procedure TQFDJsonStreamHelper.WriteType(AType: Word);
begin
  FParent.Add('DataType').AsString := StrDupW(PWideChar(TypeNames[AType]), 2);
end;

procedure TQFDJsonStreamHelper.WriteValue(const AFieldName: QStringW;
  AFieldIndex, AFdType: Word; var AValue: TQValue);
  procedure AsAnsiMemo;
  begin
    AValue.AsStream.Position := 0;
    FParent.Add(AFieldName).AsString := LoadTextW(AValue.AsStream, teAnsi);
  end;
  procedure AsBlob;
  begin
    FParent.Add(AFieldName).AsString := qstring.BinToHex(AValue.AsStream.Memory,
      AValue.AsStream.Size);
  end;

begin
  if AValue.IsNull then
    Exit;
  case AFdType of
    1: // dtBoolean(1):
      FParent.Add(AFieldName).AsBoolean := AValue.Value.AsBoolean;
    2 .. 9, 38:
      // dtSByte(2),dtInt16(3),dtInt32(4),dtByte(6),dtUInt16(7),dtInt64(5),dtUInt32(8),dtParentRowRef(38), dtUInt64(9)
      FParent.Add(AFieldName).AsInt64 := AValue.AsInt64;
    10 .. 15: // dtSingle(10),dtDouble(11),dtExtended(12),dtCurrency(13),dtBCD(14),dtFmtBCD(15)
      FParent.Add(AFieldName).AsFloat := AValue.AsFloat;
    16, 19: // dtDateTime(16),dtTime(17), dtDate(18),dtDateTimeStamp(19)
      FParent.Add(AFieldName).AsString := FormatDateTime('yyyymmdd"T"hhnnss',
        AValue.AsDateTime);
    17: // dtTime(17)
      FParent.Add(AFieldName).AsString := FormatDateTime('hhnnsszzz',
        AValue.AsDateTime);
    18: // dtDate(18),
      FParent.Add(AFieldName).AsString := FormatDateTime('yyyymmdd',
        AValue.AsDateTime);
    20, 21, 22:
      // dtTimeIntervalFull(20),dtTimeIntervalYM(21),dtTimeIntervalDS(22)
      FParent.Add(AFieldName).AsString := AValue.AsInterval.AsOracleString;
    27, 31: // dtMemo(27), dtHMemo(31)
      begin
        AValue.AsStream.Position := 0;
        FParent.Add(AFieldName).AsString := LoadTextW(AValue.AsStream, teAnsi);
      end;
    23, 24, 28, 29:
      // dtAnsiString(23),dtWideString(24),dtWideMemo(28),dtXML(29),dtWideHMemo(32)
      FParent.Add(AFieldName).AsString := AValue.AsString;
    25, 26, 30, 33: // dtByteString(25),dtBlob(26),dtHBlob(30), , dtHBFile(33)
      AsBlob;
    39: // dtGUID(39)
      FParent.Add(AFieldName).AsString := sysutils.GUIDToString(AValue.AsGuid);
  end;
end;

{ TQFDJsonConverter }

procedure TQFDJsonConverter.HelperNeeded;
begin
  FHelper := TQFDJsonStreamHelper.Create(Self);
end;

{ TQFDXMLStreamHelper }

constructor TQFDXMLStreamHelper.Create(AOwner: TQFDConverter);
begin
  inherited;
  FXML := TQXMLNode.Create;
end;

destructor TQFDXMLStreamHelper.Destroy;
begin
  FreeAndNil(FXML);
  inherited;
end;

procedure TQFDXMLStreamHelper.EndRead;
begin
  inherited;
  PopObject;
end;

procedure TQFDXMLStreamHelper.EndWrite;
begin
  inherited;
  FXML.SaveToStream(FStream);
  PopObject;
end;

function TQFDXMLStreamHelper.IsObject(AName: QStringW): Boolean;
var
  AItem: TQXMLNode;
  I: Integer;
begin
  Result := false;
  for I := FLastObject.Offset to FParent.Count - 1 do
  begin
    AItem := FParent[I];
    if (AItem.NodeType = xntNode) and (AItem.Name = AName) then
    begin
      Result := True;
      Break;
    end;
  end;
end;

function TQFDXMLStreamHelper.IsProp(AName: QStringW): Boolean;
begin
  Result := FParent.Attrs.ItemByName(AName) <> nil;
end;

function TQFDXMLStreamHelper.ObjectBeginRead(const AExpectName: QStringW;
  ACheckClass: Boolean): Boolean;
var
  AItem: TQXMLNode;
  I: Integer;
begin
  Result := false;
  AItem := nil;
  if FParent.Count > 0 then
  begin
    for I := FLastObject.Offset to FParent.Count - 1 do
    begin
      AItem := FParent[I];
      if AItem.Name = AExpectName then
      begin
        Result := True;
        Break;
      end;
    end;
  end;
  if Result then
  begin
    FLastObject.Offset := AItem.ItemIndex + 1;
    FParent := AItem;
    PushObject(0, AExpectName, false);
  end;
end;

procedure TQFDXMLStreamHelper.ObjectBeginWrite(const AName: QStringW;
  AIsArray, AWriteClass: Boolean);
begin
  FParent := FParent.AddNode(AName);
end;

procedure TQFDXMLStreamHelper.ObjectEndRead;
begin
  FParent := FParent.Parent;
  PopObject;
end;

procedure TQFDXMLStreamHelper.ObjectEndWrite;
begin
  FParent := FParent.Parent;
end;

function TQFDXMLStreamHelper.PrepareRead: Boolean;
begin
  FXML.LoadFromStream(FStream);
  if FXML.HasChild('FDBS', FParent) then
  begin
    FVersion := FParent.Attrs.IntByName('Version', 15);
    Result := True;
    PushObject(0, 'FDBS', false);
  end
  else
    Result := false;
end;

function TQFDXMLStreamHelper.PrepareWrite: Boolean;
begin
  FXML.Clear;
  FParent := FXML.Add('FDBS');
  FParent.Attrs.Add('Version', 15);
  Result := True;
end;

function TQFDXMLStreamHelper.PropRead(const AExpectName: QStringW; var ABuf;
  ASize: Integer): Boolean;
begin
  Result := false;
end;

function TQFDXMLStreamHelper.PropReadAnsiStr(const AName, ADefVal: QStringW)
  : QStringW;
begin
  Result := FParent.Attrs.ValueByName(AName, ADefVal);
end;

function TQFDXMLStreamHelper.PropReadBool(const AName: QStringW;
  ADefVal: Boolean): Boolean;
begin
  Result := FParent.Attrs.BoolByName(AName, ADefVal);
end;

function TQFDXMLStreamHelper.PropReadDate(const AName: QStringW;
  ADefValue: TDateTime): TDateTime;
begin
  Result := FParent.Attrs.DateTimeByName(AName, ADefValue);
end;

function TQFDXMLStreamHelper.PropReadFloat(const AName: QStringW;
  ADefVal: Double): Double;
begin
  Result := FParent.Attrs.FloatByName(AName, ADefVal);
end;

function TQFDXMLStreamHelper.PropReadInt64(const AName: QStringW;
  ADefVal: Int64): Int64;
begin
  Result := FParent.Attrs.IntByName(AName, ADefVal);
end;

function TQFDXMLStreamHelper.PropReadInteger(const AName: QStringW;
  ADefVal: Integer): Integer;
begin
  Result := FParent.Attrs.IntByName(AName, ADefVal);
end;

function TQFDXMLStreamHelper.PropReadLongword(const AName: QStringW;
  ADefVal: Cardinal): Cardinal;
begin
  Result := FParent.Attrs.IntByName(AName, ADefVal);
end;

function TQFDXMLStreamHelper.PropReadStr(const AName, ADefVal: QStringW)
  : QStringW;
begin
  Result := FParent.Attrs.ValueByName(AName, ADefVal);
end;

function TQFDXMLStreamHelper.PropReadWord(const AName: QStringW;
  ADefVal: Word): Word;
begin
  Result := FParent.Attrs.IntByName(AName, ADefVal);
end;

procedure TQFDXMLStreamHelper.PropWrite(const AName: QStringW; const ABuf;
  ASize: Integer);
begin
  // Do Nothing
end;

procedure TQFDXMLStreamHelper.PropWriteAnsi(const AName, AValue: QStringW);
begin
  FParent.Attrs.Add(AName, AValue);
end;

procedure TQFDXMLStreamHelper.PropWriteBool(const AName: QStringW;
  AValue: Boolean);
begin
  FParent.Attrs.Add(AName, AValue);
end;

procedure TQFDXMLStreamHelper.PropWriteDate(const AName: QStringW;
  AValue: TDateTime);
begin
  FParent.Attrs.AddDateTime(AName, AValue);
end;

procedure TQFDXMLStreamHelper.PropWriteFloat(const AName: QStringW;
  AValue: Double);
begin
  FParent.Attrs.Add(AName, AValue);
end;

procedure TQFDXMLStreamHelper.PropWriteInt64(const AName: QStringW;
  AValue: Int64);
begin
  FParent.Attrs.Add(AName, AValue);
end;

procedure TQFDXMLStreamHelper.PropWriteInteger(const AName: QStringW;
  AValue: Integer);
begin
  FParent.Attrs.Add(AName, AValue);
end;

procedure TQFDXMLStreamHelper.PropWriteLongWord(const AName: QStringW;
  AValue: Cardinal);
begin
  FParent.Attrs.Add(AName, AValue);
end;

procedure TQFDXMLStreamHelper.PropWriteStr(const AName, AValue: QStringW);
begin
  FParent.Attrs.Add(AName, AValue);
end;

procedure TQFDXMLStreamHelper.PropWriteWord(const AName: QStringW;
  AValue: Word);
begin
  FParent.Attrs.Add(AName, AValue);
end;

function TQFDXMLStreamHelper.ReadRowState: TUpdateStatus;
var
  S: String;
begin
  S := FParent.Attrs.ValueByName('RowState', '');
  if S = 'rsInserted' then
    Result := usInserted
  else if S = 'rsDeleted' then
    Result := usDeleted
  else if S = 'rsModified' then
    Result := usModified
  else
    Result := usUnmodified;
end;

function TQFDXMLStreamHelper.ReadType: Word;
var
  S: String;
begin
  S := FParent.Attrs.ValueByName('DataType', '');
  Result := FDTypeNameToType('dt' + S);
end;

function TQFDXMLStreamHelper.ReadValue(const AFieldName: QStringW;
  AFieldIndex, AFdType: Word; var AValue: TQValue): Boolean;
  procedure AsAnsiMemo;
  var
    S: QStringA;
  begin
    AValue.TypeNeeded(vdtStream);
    S := qstring.AnsiEncode(FParent.Attrs.ValueByName(AFieldName, ''));
    AValue.AsStream.WriteBuffer(PQCharA(S)^, S.Length);
  end;
  procedure AsUnicodeStream;
  var
    S: QStringW;
  begin
    S := FParent.Attrs.AsString[AFieldName];
    AValue.TypeNeeded(vdtStream);
    AValue.AsStream.WriteBuffer(PQCharW(S)^, Length(S) shl 1);
  end;

  procedure AsBlob;
  var
    ABytes: TBytes;
  begin
    AValue.TypeNeeded(vdtStream);
    ABytes := qstring.HexToBin(FParent.Attrs.ValueByName(AFieldName, ''));
    TQValueStream(AValue.Value.AsStream).WriteBuffer(ABytes[0], Length(ABytes));
  end;

begin
  Result := FParent.Attrs.IndexOfName(AFieldName) <> -1;
  if not Result then
  begin
    AValue.TypeNeeded(vdtNull);
    Exit;
  end;
  case AFdType of
    1: // dtBoolean(1):
      begin
        AValue.TypeNeeded(vdtBoolean);
        AValue.Value.AsBoolean := FParent.Attrs.AsBoolean[AFieldName];
      end;
    2, 3, 4, 6, 7: // dtSByte(2),dtInt16(3),dtInt32(4),dtByte(6),dtUInt16(7)
      begin
        AValue.TypeNeeded(vdtInteger);
        AValue.Value.AsInteger := FParent.Attrs.AsInt[AFieldName];
      end;
    5, 8, 38, 9: // dtInt64(5),dtUInt32(8),dtParentRowRef(38), dtUInt64(9)
      begin
        AValue.TypeNeeded(vdtInt64);
        AValue.Value.AsInt64 := FParent.Attrs.AsInt[AFieldName];
      end;
    10: // dtSingle(10)
      begin
        AValue.TypeNeeded(vdtSingle);
        AValue.Value.AsSingle := FParent.Attrs.AsFloat[AFieldName];
      end;
    11, 12: // dtDouble(11),dtExtended(12)
      begin
        AValue.TypeNeeded(vdtFloat);
        AValue.Value.AsFloat := FParent.Attrs.AsFloat[AFieldName];
      end;
    13: // dtCurrency(13)
      begin
        AValue.TypeNeeded(vdtCurrency);
        AValue.Value.AsCurrency := FParent.Attrs.AsFloat[AFieldName];
      end;
    14, 15: // dtBCD(14),dtFmtBCD(15)
      begin
        AValue.TypeNeeded(vdtBcd);
        AValue.Value.AsBcd^ := DoubleToBcd(FParent.Attrs.AsFloat[AFieldName]);
      end;
    16, 19: // dtDateTime(16),dtTime(17), dtDate(18),dtDateTimeStamp(19)
      begin
        AValue.TypeNeeded(vdtDateTime);
        AValue.Value.AsDateTime :=
          ParseFDDateTime(FParent.Attrs.AsString[AFieldName]);
      end;
    17: // dtTime(17)
      begin
        AValue.TypeNeeded(vdtDateTime);
        AValue.Value.AsDateTime :=
          ParseFDTime(FParent.Attrs.AsString[AFieldName]);
      end;
    18: // dtDate(18)
      begin
        AValue.TypeNeeded(vdtDateTime);
        AValue.Value.AsDateTime :=
          ParseFDDate(FParent.Attrs.AsString[AFieldName]);
      end;
    20, 21, 22:
      // dtTimeIntervalFull(20),dtTimeIntervalYM(21),dtTimeIntervalDS(22)
      begin
        AValue.TypeNeeded(vdtInterval);
        AValue.Value.AsInterval.AsString := FParent.Attrs.AsString[AFieldName];
      end;
    23, 24: // dtAnsiString(23),dtWideString(24)
      begin
        AValue.TypeNeeded(vdtString);
        AValue.Value.AsString^ := FParent.Attrs.AsString[AFieldName];
      end;
    27, 31: // dtMemo(27), dtHMemo(31)
      AsAnsiMemo;
    28, 29, 32: // ,dtWideMemo(28),dtXML(29)dtWideHMemo(32)
      AsUnicodeStream;
    25, 26, 30, 33: // dtByteString(25),dtBlob(26),dtHBlob(30), , dtHBFile(33)
      AsBlob;
    39: // dtGUID(39)
      begin
        AValue.TypeNeeded(vdtGuid);
        AValue.Value.AsGuid^ :=
          StringToGuid(FParent.Attrs.AsString[AFieldName]);
      end;
  end;

end;

procedure TQFDXMLStreamHelper.WriteRowState(AStatus: TUpdateStatus);
begin
  case AStatus of
    usUnmodified:
      ;
    usModified:
      FParent.Attrs.Add('RowState', 'Modified');
    usInserted:
      FParent.Attrs.Add('RowState', 'Inserted');
    usDeleted:
      FParent.Attrs.Add('RowState', 'Deleted');
  end;
end;

procedure TQFDXMLStreamHelper.WriteType(AType: Word);
begin
  FParent.Attrs.Add('DataType', StrDupW(PWideChar(TypeNames[AType]), 2));
end;

procedure TQFDXMLStreamHelper.WriteValue(const AFieldName: QStringW;
  AFieldIndex, AFdType: Word; var AValue: TQValue);
  procedure AsBlob;
  begin
    FParent.Attrs.Add(AFieldName, qstring.BinToHex(AValue.AsStream.Memory,
      AValue.AsStream.Size));
  end;

begin
  if AValue.IsNull then
    Exit;
  case AFdType of
    1: // dtBoolean(1):
      FParent.Attrs.Add(AFieldName).AsBoolean := AValue.Value.AsBoolean;
    2 .. 9, 38:
      // dtSByte(2),dtInt16(3),dtInt32(4),dtByte(6),dtUInt16(7),dtInt64(5),dtUInt32(8),dtParentRowRef(38), dtUInt64(9)
      FParent.Attrs.Add(AFieldName).AsInt64 := AValue.AsInt64;
    10 .. 15: // dtSingle(10),dtDouble(11),dtExtended(12),dtCurrency(13),dtBCD(14),dtFmtBCD(15)
      FParent.Attrs.Add(AFieldName).AsFloat := AValue.AsFloat;
    16, 19: // dtDateTime(16),dtDateTimeStamp(19)
      FParent.Attrs.Add(AFieldName).AsString :=
        FormatDateTime('yyyymmdd"T"hhnnss', AValue.AsDateTime);
    17: // dtTime(17)
      FParent.Attrs.Add(AFieldName).AsString :=
        FormatDateTime('hhnnss', AValue.AsDateTime);
    18: // dtDate(18)
      FParent.Attrs.Add(AFieldName).AsString :=
        FormatDateTime('yyyymmdd', AValue.AsDateTime);
    20, 21, 22:
      // dtTimeIntervalFull(20),dtTimeIntervalYM(21),dtTimeIntervalDS(22)
      FParent.Attrs.Add(AFieldName).AsString :=
        AValue.AsInterval.AsOracleString;
    23, 24:
      // dtAnsiString(23),dtWideString(24)
      FParent.Attrs.Add(AFieldName).AsString := AValue.AsString;
    27, 31: // dtMemo(27), dtHMemo(31),
      begin
        AValue.AsStream.Position := 0;
        FParent.Attrs.Add(AFieldName).AsString :=
          LoadTextW(AValue.AsStream, teAnsi);
      end;
    28, 29, 32: // dtWideMemo(28),dtXML(29),dtWideHMemo(32)
      begin
        AValue.AsStream.Position := 0;
        FParent.Attrs.Add(AFieldName).AsString :=
          LoadTextW(AValue.AsStream, teUnicode16LE);
      end;
    25, 26, 30, 33: // dtByteString(25),dtBlob(26),dtHBlob(30), , dtHBFile(33)
      AsBlob;
    39: // dtGUID(39)
      FParent.Attrs.Add(AFieldName).AsString :=
        sysutils.GUIDToString(AValue.Value.AsGuid^);
  end;
end;

{ TQFDXMLConverter }

procedure TQFDXMLConverter.HelperNeeded;
begin
  FHelper := TQFDXMLStreamHelper.Create(Self);
end;

end.
