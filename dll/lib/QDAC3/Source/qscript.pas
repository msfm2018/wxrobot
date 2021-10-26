unit qscript;

{ 本来不打算在QDAC3里实现这个单元，但发现缺少这个单元，QDB的功能会太不完美，所以还是决定加入 }
interface

uses classes, sysutils, qstring, qrbtree, qtimetypes, variants,
  math, fmtbcd{$IFDEF UNICODE},
  generics.collections{$ENDIF};

type
  TQVar = class;
  TQClassField = class;
  TQClassMeta = class;
  TQFunction = class;
  TQClassTree = class;
{$IFDEF UNICODE}
  TQClassFields = TList<TQClassField>;
  TQClassMetaList = TList<TQClassMeta>;
{$ELSE}
  TQClassFields = TList;
  TQClassMetaList = TList;
{$ENDIF}
  /// <summary>数据类型支持</summary>
  /// <list>
  /// <item><term>vdtInteger</term><description>整数</description></item>
  /// <item><term>vdtFloat</term><description>浮点数</description></item>
  /// <item><term>vdtString</term><description>字符串</description></item>
  /// <item><term>vdtBoolean</term><description>布尔</description></item>
  /// <item><term>vdtDateTime</term><description>日期时间</description></item>
  /// <item><term>vdtInterval</term><description>时间间隔</description></item>
  /// <item><term>vdtGuid</term><description>全局唯一编码</description></item>
  /// <item><term>vdtVariant</term><description>变体类型</description></item>
  /// <item><term>vdtBinary</term><description>二进制类型</description></item>
  /// <item><term>vdtRecord</term><description>结构体/记录</description></item>
  /// <item><term>vdtObject</term><description>对象</description></item>
  /// <item><term>vdtIsArray</term><description>数组类型</description></item>
  /// </list>


  /// <summary>操作符类型定义，具体操作符对应的值，取决于具体的解析器，后面注释是C/C++中对应的操作符</summary>
  TQOperator = (
    // 复合语句支持
    opBlockStart (* { *) , opBlockEnd (* } *) , opBracketStart { ( } ,
    opBracketEnd { ) } ,
    // 数组支持
    opArrayStart { [ } , opArrayEnd { ] } , opBeforeInc { ++i } ,
    opBeforeDec { --i } ,
    // 数学运算符
    opMultiply { * } , opDiv { / } , opMod { % } , opAdd { + } , opSub { - } ,
    opSelfMultiply { *= } , opSelfDiv { /= } , opSelfAdd { += } ,
    opSelfSub { -= } ,
    // 位运算符
    opBitAnd { & } , opBitOr { | } , opBitXor { ^ } , opBitNot { ~ } ,
    opShiftLeft { << } , opShiftRight { >> } , opSelfBitAnd { &= } ,
    opSelfBitOr { |= } , opSelfBitXor { ^= } , opSelfBitNot { ~= } ,
    opSelfShiftLeft { <<= } , opSelfShiftRight { >>= } ,
    // 逻辑运算符
    opAnd { && } , opOr { && } , opNot { ! } ,
    // 比较操作符
    opLessThan { < } , opLessThanOrEqual { <= } , opEqual { == } ,
    opGreatThan { > } , opGreatThanOrEqual { >= } ,
    // 赋值
    opAssign { = } ,
    // 后置自增
    opAfterInc { i++ } , opAfterDec { i-- }
    );
  /// <summary>值的可变性(常量、固定、稳定、易变)</summary>
  TQValueStable = (vsConstant, vsImmutable, vsStable, vsVolitile);

  // 所有变量及函数的基类
  TQVarHelper = class
  protected
    FData: PQValueData;
    function GetAsInteger: Int64; virtual;
    procedure SetAsInteger(const Value: Int64); virtual;
    function GetAsBoolean: Boolean; virtual;
    function GetAsBytes: TBytes; virtual;
    function GetAsDateTime: TDateTime; virtual;
    function GetAsFloat: Double; virtual;
    function GetAsGuid: TGuid; virtual;
    function GetAsInterval: TQInterval; virtual;
    function GetAsString: QStringW; virtual;
    function GetAsVariant: Variant; virtual;
    procedure SetAsBoolean(const Value: Boolean); virtual;
    procedure SetAsBytes(const Value: TBytes); virtual;
    procedure SetAsDateTime(const Value: TDateTime); virtual;
    procedure SetAsFloat(const Value: Double); virtual;
    procedure SetAsGuid(const Value: TGuid); virtual;
    procedure SetAsInterval(const Value: TQInterval); virtual;
    procedure SetAsString(const Value: QStringW); virtual;
    procedure SetAsVariant(const Value: Variant); virtual;
    function GetAsObject: TObject; virtual;
    function GetAsRecord: PByte; virtual;
    procedure SetAsObject(const Value: TObject); virtual;
    procedure SetAsRecord(const Value: PByte); virtual;
    procedure ConvertError; inline;
  public
    constructor Create(AData: PQValueData);
  end;

  // 整数辅助
  TQIntHelper = class(TQVarHelper)
  protected
    function GetAsInteger: Int64; override;
    procedure SetAsInteger(const Value: Int64); override;
    function GetAsBoolean: Boolean; override;
    function GetAsBytes: TBytes; override;
    function GetAsDateTime: TDateTime; override;
    function GetAsFloat: Double; override;
    function GetAsString: QStringW; override;
    function GetAsVariant: Variant; override;
    procedure SetAsBoolean(const Value: Boolean); override;
    procedure SetAsBytes(const Value: TBytes); override;
    procedure SetAsDateTime(const Value: TDateTime); override;
    procedure SetAsFloat(const Value: Double); override;
    procedure SetAsGuid(const Value: TGuid); override;
    procedure SetAsString(const Value: QStringW); override;
    procedure SetAsVariant(const Value: Variant); override;
  end;

  // 浮点数辅助函数
  TQFloatHelper = class(TQVarHelper)
  protected
    function GetAsInteger: Int64; override;
    procedure SetAsInteger(const Value: Int64); override;
    function GetAsBoolean: Boolean; override;
    function GetAsBytes: TBytes; override;
    function GetAsDateTime: TDateTime; override;
    function GetAsFloat: Double; override;
    function GetAsGuid: TGuid; override;
    function GetAsString: QStringW; override;
    function GetAsVariant: Variant; override;
    procedure SetAsBoolean(const Value: Boolean); override;
    procedure SetAsBytes(const Value: TBytes); override;
    procedure SetAsDateTime(const Value: TDateTime); override;
    procedure SetAsFloat(const Value: Double); override;
    procedure SetAsString(const Value: QStringW); override;
    procedure SetAsVariant(const Value: Variant); override;
  end;

  TQStringHelper = class(TQVarHelper)
  protected
    function GetAsInteger: Int64; override;
    procedure SetAsInteger(const Value: Int64); override;
    function GetAsBoolean: Boolean; override;
    function GetAsBytes: TBytes; override;
    function GetAsDateTime: TDateTime; override;
    function GetAsFloat: Double; override;
    function GetAsGuid: TGuid; override;
    function GetAsInterval: TQInterval; override;
    function GetAsString: QStringW; override;
    function GetAsVariant: Variant; override;
    procedure SetAsBoolean(const Value: Boolean); override;
    procedure SetAsBytes(const Value: TBytes); override;
    procedure SetAsDateTime(const Value: TDateTime); override;
    procedure SetAsFloat(const Value: Double); override;
    procedure SetAsGuid(const Value: TGuid); override;
    procedure SetAsInterval(const Value: TQInterval); override;
    procedure SetAsString(const Value: QStringW); override;
    procedure SetAsVariant(const Value: Variant); override;
  end;

  TQBoolHelper = class(TQVarHelper)
  protected
    function GetAsInteger: Int64; override;
    procedure SetAsInteger(const Value: Int64); override;
    function GetAsBoolean: Boolean; override;
    function GetAsBytes: TBytes; override;
    function GetAsDateTime: TDateTime; override;
    function GetAsFloat: Double; override;
    function GetAsString: QStringW; override;
    function GetAsVariant: Variant; override;
    procedure SetAsBoolean(const Value: Boolean); override;
    procedure SetAsBytes(const Value: TBytes); override;
    procedure SetAsDateTime(const Value: TDateTime); override;
    procedure SetAsFloat(const Value: Double); override;
    procedure SetAsString(const Value: QStringW); override;
    procedure SetAsVariant(const Value: Variant); override;
  end;

  TQDateTimeHelper = class(TQVarHelper)
  protected
    function GetAsInteger: Int64; override;
    procedure SetAsInteger(const Value: Int64); override;
    function GetAsBoolean: Boolean; override;
    function GetAsBytes: TBytes; override;
    function GetAsDateTime: TDateTime; override;
    function GetAsFloat: Double; override;
    function GetAsString: QStringW; override;
    function GetAsVariant: Variant; override;
    procedure SetAsBoolean(const Value: Boolean); override;
    procedure SetAsBytes(const Value: TBytes); override;
    procedure SetAsDateTime(const Value: TDateTime); override;
    procedure SetAsFloat(const Value: Double); override;
    procedure SetAsString(const Value: QStringW); override;
    procedure SetAsVariant(const Value: Variant); override;
  end;

  TQIntervalHelper = class(TQVarHelper)
  protected
    function GetAsInterval: TQInterval; override;
    function GetAsString: QStringW; override;
    function GetAsVariant: Variant; override;
    procedure SetAsInterval(const Value: TQInterval); override;
    procedure SetAsString(const Value: QStringW); override;
    procedure SetAsVariant(const Value: Variant); override;
    function GetAsBytes: TBytes; override;
    procedure SetAsBytes(const Value: TBytes); override;
  end;

  // vdtGuid
  TQGuidHelper = class(TQVarHelper)
  protected
    function GetAsBytes: TBytes; override;
    function GetAsGuid: TGuid; override;
    function GetAsString: QStringW; override;
    function GetAsVariant: Variant; override;
    procedure SetAsBytes(const Value: TBytes); override;
    procedure SetAsGuid(const Value: TGuid); override;
    procedure SetAsString(const Value: QStringW); override;
    procedure SetAsVariant(const Value: Variant); override;
  end;

  // vdtVariant
  TQBinaryHelper = class(TQVarHelper)
  protected
    function GetAsInteger: Int64; override;
    procedure SetAsInteger(const Value: Int64); override;
    function GetAsBoolean: Boolean; override;
    function GetAsBytes: TBytes; override;
    function GetAsDateTime: TDateTime; override;
    function GetAsFloat: Double; override;
    function GetAsGuid: TGuid; override;
    function GetAsInterval: TQInterval; override;
    function GetAsString: QStringW; override;
    function GetAsVariant: Variant; override;
    procedure SetAsBoolean(const Value: Boolean); override;
    procedure SetAsBytes(const Value: TBytes); override;
    procedure SetAsDateTime(const Value: TDateTime); override;
    procedure SetAsFloat(const Value: Double); override;
    procedure SetAsGuid(const Value: TGuid); override;
    procedure SetAsInterval(const Value: TQInterval); override;
    procedure SetAsString(const Value: QStringW); override;
    procedure SetAsVariant(const Value: Variant); override;
    procedure NeedSize(const ASize: Cardinal);
  end;

  // vdtRecord
  TQRecordHelper = class(TQVarHelper)
  private
    function GetClassMeta: TQClassMeta;
    function GetFields(AIndex: Integer): TQClassField;
  protected
    function GetAsRecord: PByte; override;
    procedure SetAsRecord(const Value: PByte); override;
  public
    property Fields[AIndex: Integer]: TQClassField read GetFields;
    property ClassMeta: TQClassMeta read GetClassMeta;
  end;
  // vdtObject,
  // vdtIsArray

  TQVar = class
  private
    function GetAsInteger: Int64;
    procedure SetAsInteger(const Value: Int64);
    function GetAsBoolean: Boolean;
    function GetAsBytes: TBytes;
    function GetAsDateTime: TDateTime;
    function GetAsFloat: Double;
    function GetAsGuid: TGuid;
    function GetAsInterval: TQInterval;
    function GetAsString: QStringW;
    function GetAsVariant: Variant;
    procedure SetAsBoolean(const Value: Boolean);
    procedure SetAsBytes(const Value: TBytes);
    procedure SetAsDateTime(const Value: TDateTime);
    procedure SetAsFloat(const Value: Double);
    procedure SetAsGuid(const Value: TGuid);
    procedure SetAsInterval(const Value: TQInterval);
    procedure SetAsString(const Value: QStringW);
    procedure SetAsVariant(const Value: Variant);
    function GetAsObject: TObject;
    function GetAsRecord: PByte;
    procedure SetAsObject(const Value: TObject);
    procedure SetAsRecord(const Value: PByte);
  protected
    FName: QStringW;
    FValue: TQValue;
    FStable: TQValueStable;
    function GetValue: PQValue; virtual;
    procedure SetValue(AValue: PQValue); virtual; abstract;
    procedure SetName(const AName: QStringW); virtual;
    function GetIsArray: Boolean; inline;
    function GetItems(AIndex: Integer): PQValue;
  public
    constructor Create(ADataType: TQValueDataType); overload;
    destructor Destroy; override;
    property Stable: TQValueStable read FStable write FStable;
    property Value: PQValue read GetValue write SetValue;
    property Name: QStringW read FName write SetName;
    property IsArray: Boolean read GetIsArray;
    property Items[AIndex: Integer]: PQValue read GetItems;
    property AsInteger: Int64 read GetAsInteger write SetAsInteger;
    property AsString: QStringW read GetAsString write SetAsString;
    property AsFloat: Double read GetAsFloat write SetAsFloat;
    property AsBoolean: Boolean read GetAsBoolean write SetAsBoolean;
    property AsDateTime: TDateTime read GetAsDateTime write SetAsDateTime;
    property AsInterval: TQInterval read GetAsInterval write SetAsInterval;
    property AsGuid: TGuid read GetAsGuid write SetAsGuid;
    property AsVariant: Variant read GetAsVariant write SetAsVariant;
    property AsBytes: TBytes read GetAsBytes write SetAsBytes;
    property AsRecord: PByte read GetAsRecord write SetAsRecord;
    property AsObject: TObject read GetAsObject write SetAsObject;
  end;

  TQClassField = class
  protected
    FName: QStringW; // 名称
    FOffset, FSize: Cardinal; // 偏移和大小
    FNameHash: Cardinal; // 名称哈希
    FDataType: TQValueDataType; // 类型
    FClass: TQClassMeta; // 关联的类型信息
  public
    constructor Create; overload;
    destructor Destroy; override;
    property Name: QStringW read FName write FName;
    property Offset: Cardinal read FOffset write FOffset;
    property Size: Cardinal read FSize write FSize;
    property DataType: TQValueDataType read FDataType write FDataType;
  end;

  // 复合对象类型的元数据信息，用于支持结构体和对象，
  // 在QScript中，结构体和类的处理和C++一样，都认为是一个东西
  TQClassMeta = class
  protected
    FOwner: TQClassTree;
    FParents: TQClassMetaList;
    FChildren: TQClassMetaList;
    FFields: TQClassFields;
    FName: QStringW;
    FNameHash: Cardinal;
    FAllocSize: Cardinal;
    FBaseSize: Cardinal;
    FSizeChanged: Boolean;
    FAlignSize: Byte; // 请求的对齐字节
    FInDestroy: Boolean;
    FBaseType: TQClassMeta;
    FIsPublic: Boolean; // 是否是公开的类型，私有的类型只有在指定的代码段内部使用
    FSourceFile: QStringW; // 类型源文件
    FSourceLine: Cardinal; // 类型源行号
    function GetChildCount: Integer;
    function GetChildren(AIndex: Integer): TQClassMeta;
    function GetParents(AIndex: Integer): TQClassMeta;
    procedure Clear;
    function GetFieldCount: Integer;
    function GetFields(AIndex: Integer): TQClassField;
    function GetAllocSize: Cardinal;
    procedure SetAlignSize(const Value: Byte);
    procedure SizeChanged;
    procedure ClearParents;
    function GetBaseType: TQClassMeta;
  public
    constructor Create(ABaseSize: Cardinal = 0); overload;
    destructor Destroy; override;
    function AddChild(AClass: TQClassMeta): Integer;
    procedure DeleteChild(AIndex: Integer);
    procedure ClearChild;
    function AddField(const AName: QStringW): TQClassField;
    function FieldByName(const AName: QStringW): TQClassField;
    function IsParentOf(AClass: TQClassMeta): Boolean;
    function IsChildOf(AClass: TQClassMeta): Boolean;
    procedure DeleteField(AIndex: Integer); overload;
    procedure DeleteField(const AName: QStringW); overload;
    procedure ClearFields;
    procedure BeforeDestruction; override;
    property Parents[AIndex: Integer]: TQClassMeta read GetParents;
    property ParentCount: Integer read GetChildCount;
    property Children[AIndex: Integer]: TQClassMeta read GetChildren;
    property ChildCount: Integer read GetChildCount;
    property Fields[AIndex: Integer]: TQClassField read GetFields;
    property FieldCount: Integer read GetFieldCount;
    property AllocSize: Cardinal read GetAllocSize;
    property AlignSize: Byte read FAlignSize write SetAlignSize;
    property Name: QStringW read FName;
    property BaseType: TQClassMeta read GetBaseType;
    property IsPublic: Boolean read FIsPublic write FIsPublic;
    property SourceFile: QStringW read FSourceFile write FSourceFile;
    property SourceLine: Cardinal read FSourceLine write FSourceLine;
  end;

  TQClassTree = class
  protected
    FClasses: TQHashTable; // 类元数据哈希表
    FIgnoreCase: Boolean;
    function GetCount: Integer;
    procedure DoDeleteClass(ATable: TQHashTable; AHash: TQHashType;
      AData: Pointer);
    procedure DoClearItem(ATable: TQHashTable; AHash: TQHashType;
      AData: Pointer);
    function HashOf(const S: QStringW): Cardinal;
    procedure AddDefaultClasses;
  public
    constructor Create; overload;
    destructor Destroy; override;
    function Add(const AName: QStringW; ABaseSize: Integer = 0): TQClassMeta;
    procedure Delete(const AName: QStringW);
    function Find(const AName: QStringW): TQClassMeta;
    procedure EnumClasses(AList: TQClassMetaList);
    procedure Clear;
    property Count: Integer read GetCount;
    property IgnoreCase: Boolean read FIgnoreCase write FIgnoreCase;

  end;

  // 常量
  TQConstVar = class(TQVar)
  protected
    procedure SetValue(AValue: PQValue); override;
  public
    constructor Create(AValue: Int64); overload;
    constructor Create(AValue: Double); overload;
    constructor Create(AValue: QStringW); overload;
    constructor Create(AValue: TGuid); overload;
    constructor Create(AValue: Boolean); overload;
  end;

  TQImmutableVar = class(TQVar)
  protected
    procedure SetValue(AValue: PQValue); override;
  public
    constructor Create; overload;

  end;

  TQStableVar = class(TQVar)

  end;

  TQVoliatileVar = class(TQVar)

  end;

  TQFunction = class(TQVar)

  end;

resourcestring
  SConvertError = '值类型不兼容，无法自动转换。';

implementation

resourcestring
  SCantAssignToConst = '不能为一个常量赋值。';
  SOutOfRange = '数组访问越界，请求 %d ，允许范围 [%d~%d]。';

  { TQVar }

constructor TQVar.Create(ADataType: TQValueDataType);
begin
inherited Create;
FValue.DataType := ADataType;
case ADataType of
  vdtString:
    New(FValue.Data.AsString);
  vdtVariant:
    New(FValue.Data.AsVariant);
end;
end;

destructor TQVar.Destroy;
begin
FValue.Clear;
inherited;
end;

function TQVar.GetAsBoolean: Boolean;
begin
if FValue.DataType = vdtBoolean then
  Result := FValue.Data.AsBoolean
else
  Result := AsInteger <> 0;
end;

function TQVar.GetAsBytes: TBytes;
begin
if FValue.DataType = vdtBinary then
  begin
  SetLength(Result, FValue.Data.Size);
  Move(FValue.Data.AsBinary^, Result[0], FValue.Data.Size);
  end
else if FValue.DataType = vdtInteger then
  begin
  SetLength(Result, SizeOf(Int64));
  Move(FValue.Data.AsInt, Result[0], SizeOf(Int64));
  end
else if FValue.DataType in [vdtFloat, vdtDateTime] then
  begin
  SetLength(Result, SizeOf(Double));
  Move(FValue.Data.AsFloat, Result[0], SizeOf(Double));
  end
else if FValue.DataType = vdtBoolean then
  begin
  SetLength(Result, 1);
  Result[0] := Byte(AsBoolean);
  end
else if FValue.DataType = vdtString then
  begin
  SetLength(Result, Length(FValue.Data.AsString^) shl 1);
  Move(PQCharW(FValue.Data.AsString^)^, Result[0],
    Length(FValue.Data.AsString^) shl 1);
  end
else if FValue.DataType = vdtInterval then
  begin
  SetLength(Result, SizeOf(TQInterval));
  Move(FValue.Data.AsInterval, Result[0], SizeOf(TQInterval));
  end
else if FValue.DataType = vdtGuid then
  begin
  SetLength(Result, SizeOf(TGuid));
  Move(FValue.Data.AsGuid, Result[0], SizeOf(TGuid));
  end
else if FValue.DataType = vdtVariant then
  begin
  if VarIsArray(FValue.Data.AsVariant^) then
    begin
    if VarType(FValue.Data.AsVariant^) = varByte then // 字节流
      begin
      SetLength(Result, VarArrayHighBound(FValue.Data.AsVariant^, 1) + 1);
      Move(VarArrayLock(Result)^, Result[0], Length(Result));
      VarArrayUnlock(Result);
      Exit;
      end;
    end;
  raise Exception.Create(SConvertError);
  end
else
  raise Exception.Create(SConvertError);
end;

function TQVar.GetAsDateTime: TDateTime;
  function ParseFromString(S: QStringW): TDateTime;
  begin
  if not(ParseDateTime(PQCharW(S), Result) or ParseWebTime(PQCharW(S), Result)
    or TryStrToDateTime(S, Result)) then
    raise Exception.Create(SConvertError);
  end;

begin
if FValue.DataType = vdtDateTime then
  Result := FValue.Data.AsDateTime
else if FValue.DataType = vdtFloat then
  Result := AsFloat
else if FValue.DataType = vdtInteger then
  Result := AsInteger
else if FValue.DataType = vdtString then
  Result := ParseFromString(AsString)
else if FValue.DataType = vdtVariant then
  Result := AsVariant
else
  raise Exception.Create(SConvertError);
end;

function TQVar.GetAsFloat: Double;
begin
if FValue.DataType in [vdtFloat, vdtDateTime] then
  Result := FValue.Data.AsFloat
else if FValue.DataType = vdtInteger then
  Result := FValue.Data.AsInt
else if FValue.DataType = vdtBoolean then
  Result := Integer(FValue.Data.AsBoolean)
else if FValue.DataType = vdtString then
  begin
  if not TryStrtoFloat(FValue.Data.AsString^, Result) then
    raise Exception.Create(SConvertError);
  end
else
  raise Exception.Create(SConvertError);
end;

function TQVar.GetAsGuid: TGuid;
begin

end;

function TQVar.GetAsInteger: Int64;
begin
if FValue.DataType = vdtInteger then
  Result := FValue.Data.AsInt
else if FValue.DataType in [vdtFloat, vdtDateTime] then
  Result := Trunc(AsFloat)
else if FValue.DataType = vdtBoolean then
  Result := Integer(AsBoolean)
else if FValue.DataType = vdtString then
  begin
  if not TryStrToInt64(AsString, Result) then
    raise Exception.Create(SConvertError);
  end
else if FValue.DataType = vdtVariant then
  Result := FValue.Data.AsVariant^
else
  raise Exception.Create(SConvertError);
end;

function TQVar.GetAsInterval: TQInterval;
begin

end;

function TQVar.GetAsObject: TObject;
begin

end;

function TQVar.GetAsRecord: PByte;
begin

end;

function TQVar.GetAsString: QStringW;
begin

end;

function TQVar.GetAsVariant: Variant;
begin

end;

function TQVar.GetIsArray: Boolean;
begin
Result := FValue.IsArray;
end;

function TQVar.GetItems(AIndex: Integer): PQValue;
begin
if (AIndex >= 0) and (AIndex < FValue.Data.Size) then
  Result := PQValue(IntPtr(FValue.Data.AsArray) + SizeOf(TQValue) * AIndex)
else
  raise Exception.CreateFmt(SOutOfRange, [AIndex, 0, FValue.Data.Size]);
end;

function TQVar.GetValue: PQValue;
begin
Result := @FValue;
end;

procedure TQVar.SetAsBoolean(const Value: Boolean);
begin

end;

procedure TQVar.SetAsBytes(const Value: TBytes);
begin

end;

procedure TQVar.SetAsDateTime(const Value: TDateTime);
begin

end;

procedure TQVar.SetAsFloat(const Value: Double);
begin

end;

procedure TQVar.SetAsGuid(const Value: TGuid);
begin

end;

procedure TQVar.SetAsInteger(const Value: Int64);
begin

end;

procedure TQVar.SetAsInterval(const Value: TQInterval);
begin

end;

procedure TQVar.SetAsObject(const Value: TObject);
begin

end;

procedure TQVar.SetAsRecord(const Value: PByte);
begin

end;

procedure TQVar.SetAsString(const Value: QStringW);
begin

end;

procedure TQVar.SetAsVariant(const Value: Variant);
begin

end;

procedure TQVar.SetName(const AName: QStringW);
begin
FName := AName;
end;

{ TQConstVar }

constructor TQConstVar.Create(AValue: Double);
begin
inherited Create;
FValue.Data.AsFloat := AValue;
FValue.DataType := vdtFloat;
Stable := vsConstant;
end;

constructor TQConstVar.Create(AValue: Int64);
begin
inherited Create(vdtInteger);
AsInteger := AValue;
Stable := vsConstant;
end;

constructor TQConstVar.Create(AValue: QStringW);
begin
inherited Create;
New(FValue.Data.AsString);
FValue.Data.AsString^ := AValue;
FValue.DataType := vdtString;
Stable := vsConstant;
end;

constructor TQConstVar.Create(AValue: Boolean);
begin
inherited Create;
FValue.Data.AsBoolean := AValue;
FValue.DataType := vdtBoolean;
Stable := vsConstant;
end;

constructor TQConstVar.Create(AValue: TGuid);
begin
inherited Create;
FValue.Data.AsGuid := AValue;
FValue.DataType := vdtGuid;
Stable := vsConstant;
end;

procedure TQConstVar.SetValue(AValue: PQValue);
begin
raise Exception.Create(SCantAssignToConst);
end;

{ TQValue }

procedure TQValue.Clear;
  procedure Clear(AValue: PQValue);
  var
    I: Integer;
    AItem: PQValue;
  begin
  if AValue.IsArray then
    begin
    if AValue.Data.Size > 0 then
      begin
      AItem := AValue.Data.AsArray;
      I := 0;
      while I < AItem.Data.Size do
        begin
        Clear(AItem);
        Inc(AItem);
        Inc(I);
        end;
      AValue.Data.Size := 0;
      FreeMem(AValue.Data.AsArray);
      AValue.Data.AsArray := nil;
      end;
    end
  else
    begin
    case TQValueDataType(Byte(AValue.DataType) and $3F) of
      vdtString:
        Dispose(AValue.Data.AsString);
      vdtVariant:
        Dispose(AValue.Data.AsVariant);
      vdtBinary, vdtRecord:
        begin
        if AValue.Data.Size > 0 then
          begin
          FreeMem(AValue.Data.AsBinary);
          AValue.Data.Size := 0;
          AValue.Data.AsBinary := nil;
          end;
        end;
      vdtObject:
        begin
        if AValue.Data.AsObject <> nil then
          FreeObject(AValue.Data.AsObject);
        end;
    end;
    end;
  end;

begin
Clear(@Self);
end;

function TQValue.IsArray: Boolean;
begin
Result := (Byte(DataType) and Byte(vdtIsArray)) <> 0;
end;

{ TQImmutableVar }

constructor TQImmutableVar.Create;
begin

end;

procedure TQImmutableVar.SetValue(AValue: PQValue);
begin

end;

{ TQVarHelper }

procedure TQVarHelper.ConvertError;
begin
raise EConvertError.Create(SConvertError);
end;

constructor TQVarHelper.Create(AData: PQValueData);
begin
inherited Create;
FData := AData;
end;

function TQVarHelper.GetAsBoolean: Boolean;
begin
ConvertError;
end;

function TQVarHelper.GetAsBytes: TBytes;
begin
ConvertError;
end;

function TQVarHelper.GetAsDateTime: TDateTime;
begin
ConvertError;
end;

function TQVarHelper.GetAsFloat: Double;
begin
ConvertError;
end;

function TQVarHelper.GetAsGuid: TGuid;
begin
ConvertError;
end;

function TQVarHelper.GetAsInteger: Int64;
begin
ConvertError;
end;

function TQVarHelper.GetAsInterval: TQInterval;
begin
ConvertError;
end;

function TQVarHelper.GetAsObject: TObject;
begin
ConvertError;
end;

function TQVarHelper.GetAsRecord: PByte;
begin
ConvertError;
end;

function TQVarHelper.GetAsString: QStringW;
begin
ConvertError;
end;

function TQVarHelper.GetAsVariant: Variant;
begin
ConvertError;
end;

procedure TQVarHelper.SetAsBoolean(const Value: Boolean);
begin
ConvertError;
end;

procedure TQVarHelper.SetAsBytes(const Value: TBytes);
begin
ConvertError;
end;

procedure TQVarHelper.SetAsDateTime(const Value: TDateTime);
begin
ConvertError;
end;

procedure TQVarHelper.SetAsFloat(const Value: Double);
begin
ConvertError;
end;

procedure TQVarHelper.SetAsGuid(const Value: TGuid);
begin
ConvertError;
end;

procedure TQVarHelper.SetAsInteger(const Value: Int64);
begin
ConvertError;
end;

procedure TQVarHelper.SetAsInterval(const Value: TQInterval);
begin
ConvertError;
end;

procedure TQVarHelper.SetAsObject(const Value: TObject);
begin
ConvertError;
end;

procedure TQVarHelper.SetAsRecord(const Value: PByte);
begin
ConvertError;
end;

procedure TQVarHelper.SetAsString(const Value: QStringW);
begin
ConvertError;
end;

procedure TQVarHelper.SetAsVariant(const Value: Variant);
begin
ConvertError;
end;

{ TQIntHelper }

function TQIntHelper.GetAsBoolean: Boolean;
begin
Result := FData.AsInt <> 0;
end;

function TQIntHelper.GetAsBytes: TBytes;
begin
SetLength(Result, SizeOf(Int64));
Move(FData.AsInt, Result[0], SizeOf(Int64));
end;

function TQIntHelper.GetAsDateTime: TDateTime;
begin
Result := FData.AsInt;
end;

function TQIntHelper.GetAsFloat: Double;
begin
Result := FData.AsInt;
end;

function TQIntHelper.GetAsInteger: Int64;
begin
Result := FData.AsInt;
end;

function TQIntHelper.GetAsString: QStringW;
begin
Result := IntToStr(FData.AsInt);
end;

function TQIntHelper.GetAsVariant: Variant;
begin
Result := FData.AsInt;
end;

procedure TQIntHelper.SetAsBoolean(const Value: Boolean);
begin
FData.AsInt := Integer(Value);
end;

procedure TQIntHelper.SetAsBytes(const Value: TBytes);
begin
if Length(Value) = SizeOf(Int64) then
  Move(Value[0], FData.AsInt, SizeOf(Int64))
else
  ConvertError;
end;

procedure TQIntHelper.SetAsDateTime(const Value: TDateTime);
begin
FData.AsInt := Trunc(Value);
end;

procedure TQIntHelper.SetAsFloat(const Value: Double);
begin
FData.AsInt := Trunc(Value);
end;

procedure TQIntHelper.SetAsGuid(const Value: TGuid);
begin
ConvertError;
end;

procedure TQIntHelper.SetAsInteger(const Value: Int64);
begin
FData.AsInt := Value;
end;

procedure TQIntHelper.SetAsString(const Value: QStringW);
begin
if not TryStrToInt64(Value, FData.AsInt) then
  ConvertError;
end;

procedure TQIntHelper.SetAsVariant(const Value: Variant);
begin
case VarType(Value) of
  varSmallint, varInteger, varSingle, varDouble, varCurrency, varDate,
    varBoolean, varShortInt, varByte, varWord, varLongWord, varInt64, varUInt64,
    varOleStr, varString, varUString:
    FData.AsInt := Value
else
  ConvertError;
end;
end;

{ TQFloatHelper }

function TQFloatHelper.GetAsBoolean: Boolean;
begin
Result := SameValue(FData.AsFloat, 0);
end;

function TQFloatHelper.GetAsBytes: TBytes;
begin
SetLength(Result, SizeOf(Double));
Move(FData.AsFloat, Result[0], SizeOf(Double));
end;

function TQFloatHelper.GetAsDateTime: TDateTime;
begin
Result := FData.AsDateTime;
end;

function TQFloatHelper.GetAsFloat: Double;
begin
Result := FData.AsFloat;
end;

function TQFloatHelper.GetAsGuid: TGuid;
begin
ConvertError;
end;

function TQFloatHelper.GetAsInteger: Int64;
begin
Result := Trunc(FData.AsFloat);
end;

function TQFloatHelper.GetAsString: QStringW;
begin
Result := FloatToStr(FData.AsFloat);
end;

function TQFloatHelper.GetAsVariant: Variant;
begin
Result := FData.AsFloat;
end;

procedure TQFloatHelper.SetAsBoolean(const Value: Boolean);
begin
FData.AsFloat := Integer(Value);
end;

procedure TQFloatHelper.SetAsBytes(const Value: TBytes);
begin
if Length(Value) = SizeOf(Double) then
  Move(Value[0], FData.AsFloat, SizeOf(Double))
else
  ConvertError;
end;

procedure TQFloatHelper.SetAsDateTime(const Value: TDateTime);
begin
FData.AsDateTime := Value;
end;

procedure TQFloatHelper.SetAsFloat(const Value: Double);
begin
FData.AsFloat := Value;
end;

procedure TQFloatHelper.SetAsInteger(const Value: Int64);
begin
FData.AsFloat := Value;
end;

procedure TQFloatHelper.SetAsString(const Value: QStringW);
begin
if not TryStrtoFloat(Value, FData.AsFloat) then
  ConvertError;
end;

procedure TQFloatHelper.SetAsVariant(const Value: Variant);
begin
case VarType(Value) of
  varSmallint, varInteger, varSingle, varDouble, varCurrency, varDate,
    varBoolean, varShortInt, varByte, varWord, varLongWord, varInt64, varUInt64,
    varOleStr, varString, varUString:
    FData.AsInt := Value
else
  ConvertError;
end;
end;

{ TQBoolHelper }

function TQBoolHelper.GetAsBoolean: Boolean;
begin
Result := FData.AsBoolean;
end;

function TQBoolHelper.GetAsBytes: TBytes;
begin
SetLength(Result, 1);
if FData.AsBoolean then
  Result[0] := 1
else
  Result[0] := 0;
end;

function TQBoolHelper.GetAsDateTime: TDateTime;
begin
if FData.AsBoolean then
  Result := 1
else
  Result := 0;
end;

function TQBoolHelper.GetAsFloat: Double;
begin
if FData.AsBoolean then
  Result := 1
else
  Result := 0;
end;

function TQBoolHelper.GetAsInteger: Int64;
begin
if FData.AsBoolean then
  Result := 1
else
  Result := 0;
end;

function TQBoolHelper.GetAsString: QStringW;
begin
Result := BoolToStr(FData.AsBoolean, True);
end;

function TQBoolHelper.GetAsVariant: Variant;
begin
Result := FData.AsBoolean;
end;

procedure TQBoolHelper.SetAsBoolean(const Value: Boolean);
begin
FData.AsBoolean := Value;
end;

procedure TQBoolHelper.SetAsBytes(const Value: TBytes);
begin
if Length(Value) = 1 then
  FData.AsBoolean := Value[0] = 1
else
  ConvertError;
end;

procedure TQBoolHelper.SetAsDateTime(const Value: TDateTime);
begin
SetAsFloat(Value);
end;

procedure TQBoolHelper.SetAsFloat(const Value: Double);
begin
FData.AsBoolean := SameValue(Value, 0);
end;

procedure TQBoolHelper.SetAsInteger(const Value: Int64);
begin
FData.AsBoolean := (Value = 1);
end;

procedure TQBoolHelper.SetAsString(const Value: QStringW);
begin
if not TryStrToBool(Value, FData.AsBoolean) then
  ConvertError;
end;

procedure TQBoolHelper.SetAsVariant(const Value: Variant);
begin
case VarType(Value) of
  varSmallint, varInteger, varSingle, varDouble, varCurrency, varDate,
    varBoolean, varShortInt, varByte, varWord, varLongWord, varInt64, varUInt64,
    varOleStr, varString, varUString:
    FData.AsBoolean := Value
else
  ConvertError;
end;
end;

{ TQStringHelper }

function TQStringHelper.GetAsBoolean: Boolean;
begin
if not TryStrToBool(FData.AsString^, Result) then
  ConvertError;
end;

function TQStringHelper.GetAsBytes: TBytes;
var
  L: NativeInt;
begin
L := Length(FData.AsString^) shl 1;
SetLength(Result, L);
Move(PQCharW(FData.AsString^)^, Result[0], L);
end;

function TQStringHelper.GetAsDateTime: TDateTime;
begin
if not(ParseDateTime(PQCharW(FData.AsString^), Result) or
  ParseWebTime(PQCharW(FData.AsString^), Result) or
  TryStrToDateTime(FData.AsString^, Result)) then
  ConvertError;
end;

function TQStringHelper.GetAsFloat: Double;
begin
if not TryStrtoFloat(FData.AsString^, Result) then
  ConvertError;
end;

function TQStringHelper.GetAsGuid: TGuid;
begin
if not TryStrToGuid(FData.AsString^, Result) then
  ConvertError;
end;

function TQStringHelper.GetAsInteger: Int64;
begin
if not TryStrToInt64(FData.AsString^, Result) then
  ConvertError;
end;

function TQStringHelper.GetAsInterval: TQInterval;
begin
Result.AsString := FData.AsString^;
end;

function TQStringHelper.GetAsString: QStringW;
begin
Result := FData.AsString^;
end;

function TQStringHelper.GetAsVariant: Variant;
begin
Result := FData.AsString^;
end;

procedure TQStringHelper.SetAsBoolean(const Value: Boolean);
begin
FData.AsString^ := BoolToStr(Value, True);
end;

procedure TQStringHelper.SetAsBytes(const Value: TBytes);
var
  AEncoding: TTextEncoding;
  ABom: Boolean;
  p: PByte;
  L: Integer;
begin
p := @Value[0];
L := Length(Value);
AEncoding := DetectTextEncoding(p, L, ABom);
case AEncoding of
  teAnsi:
    FData.AsString^ := AnsiDecode(PQCharA(p), L);
  teUnicode16LE:
    begin
    if ABom then
      begin
      Inc(p, 2);
      FData.AsString^ := StrDupX(PQCharW(p), (L - 2) shr 1);
      end
    else
      FData.AsString^ := StrDupX(PQCharW(p), L shr 1);
    end;
  teUnicode16BE:
    begin
    if ABom then
      begin
      Inc(p, 2);
      FData.AsString^ := StrDupX(PQCharW(p), (L - 2) shr 1);
      end
    else
      FData.AsString^ := StrDupX(PQCharW(p), L shr 1);
    ExchangeByteOrder(PQCharA(PQCharW(FData.AsString^)),
      Length(FData.AsString^) shl 1);
    end;
  teUTF8:
    begin
    if ABom then
      begin
      Inc(p, 3);
      FData.AsString^ := Utf8Decode(PQCharA(p), L - 3);
      end
    else
      FData.AsString^ := Utf8Decode(PQCharA(p), L);
    end;
end;
end;

procedure TQStringHelper.SetAsDateTime(const Value: TDateTime);
var
  Y, M, D: Word;
  H, N, S, MS: Word;
begin
if Trunc(Value) = 0 then
  FData.AsString^ := FormatDateTime('hh:nn:ss.zzz', Value)
else if SameValue(Value - Trunc(Value), 0) then
  FData.AsString^ := FormatDateTime('yyyy-mm-dd', Value)
else
  FData.AsString^ := FormatDateTime('yyyy-mm-ddThh:nn:ss.zzz', Value);
end;

procedure TQStringHelper.SetAsFloat(const Value: Double);
begin
FData.AsString^ := FloatToStr(Value);
end;

procedure TQStringHelper.SetAsGuid(const Value: TGuid);
begin
FData.AsString^ := GuidToString(Value);
end;

procedure TQStringHelper.SetAsInteger(const Value: Int64);
begin
FData.AsString^ := IntToStr(Value);
end;

procedure TQStringHelper.SetAsInterval(const Value: TQInterval);
begin
FData.AsString^ := Value.AsString;
end;

procedure TQStringHelper.SetAsString(const Value: QStringW);
begin
FData.AsString^ := Value;
end;

procedure TQStringHelper.SetAsVariant(const Value: Variant);
begin
FData.AsString^ := Value;
end;

{ TQDateTimeHelper }

function TQDateTimeHelper.GetAsBoolean: Boolean;
begin
Result := SameValue(FData.AsFloat, 0);
end;

function TQDateTimeHelper.GetAsBytes: TBytes;
begin
SetLength(Result, SizeOf(TDateTime));
Move(FData.AsDateTime, Result[0], SizeOf(TDateTime));
end;

function TQDateTimeHelper.GetAsDateTime: TDateTime;
begin
Result := FData.AsDateTime;
end;

function TQDateTimeHelper.GetAsFloat: Double;
begin
Result := FData.AsFloat;
end;

function TQDateTimeHelper.GetAsInteger: Int64;
begin
Result := Trunc(FData.AsFloat);
end;

function TQDateTimeHelper.GetAsString: QStringW;
begin
if Trunc(FData.AsFloat) = 0 then
  FData.AsString^ := FormatDateTime('hh:nn:ss.zzz', FData.AsDateTime)
else if SameValue(FData.AsFloat - Trunc(FData.AsFloat), 0) then
  FData.AsString^ := FormatDateTime('yyyy-mm-dd', FData.AsDateTime)
else
  FData.AsString^ := FormatDateTime('yyyy-mm-ddThh:nn:ss.zzz',
    FData.AsDateTime);
end;

function TQDateTimeHelper.GetAsVariant: Variant;
begin
Result := FData.AsDateTime;
end;

procedure TQDateTimeHelper.SetAsBoolean(const Value: Boolean);
begin
FData.AsDateTime := Integer(Value);
end;

procedure TQDateTimeHelper.SetAsBytes(const Value: TBytes);
begin
if Length(Value) = SizeOf(TDateTime) then
  Move(Value[0], FData.AsDateTime, SizeOf(TDateTime))
else
  ConvertError;
end;

procedure TQDateTimeHelper.SetAsDateTime(const Value: TDateTime);
begin
FData.AsDateTime := Value;
end;

procedure TQDateTimeHelper.SetAsFloat(const Value: Double);
begin
FData.AsFloat := Value;
end;

procedure TQDateTimeHelper.SetAsInteger(const Value: Int64);
begin
FData.AsDateTime := Value;
end;

procedure TQDateTimeHelper.SetAsString(const Value: QStringW);
begin
if not(ParseDateTime(PQCharW(Value), FData.AsDateTime) or
  ParseWebTime(PQCharW(Value), FData.AsDateTime) or TryStrToDateTime(Value,
  FData.AsDateTime)) then
  ConvertError;
end;

procedure TQDateTimeHelper.SetAsVariant(const Value: Variant);
begin
FData.AsDateTime := VarToDateTime(Value);
end;

{ TQIntervalHelper }

function TQIntervalHelper.GetAsBytes: TBytes;
begin
SetLength(Result, SizeOf(TQInterval));
Move(FData.AsInterval, Result[0], SizeOf(TQInterval));
end;

function TQIntervalHelper.GetAsInterval: TQInterval;
begin
Result := FData.AsInterval;
end;

function TQIntervalHelper.GetAsString: QStringW;
begin
Result := FData.AsInterval.AsString;
end;

function TQIntervalHelper.GetAsVariant: Variant;
begin
Result := FData.AsInterval.AsString;
end;

procedure TQIntervalHelper.SetAsBytes(const Value: TBytes);
begin
if Length(Value) = SizeOf(TQInterval) then
  Move(Value[0], FData.AsInterval, SizeOf(TQInterval))
else
  ConvertError;
end;

procedure TQIntervalHelper.SetAsInterval(const Value: TQInterval);
begin
FData.AsInterval := Value;
end;

procedure TQIntervalHelper.SetAsString(const Value: QStringW);
begin
if not FData.AsInterval.TryFromString(Value) then
  ConvertError;
end;

procedure TQIntervalHelper.SetAsVariant(const Value: Variant);
begin
if not FData.AsInterval.TryFromString(Value) then
  ConvertError;
end;

{ TQGuidHelper }

function TQGuidHelper.GetAsBytes: TBytes;
begin
SetLength(Result, SizeOf(TGuid));
Move(FData.AsGuid, Result[0], SizeOf(TGuid));
end;

function TQGuidHelper.GetAsGuid: TGuid;
begin
Result := FData.AsGuid;
end;

function TQGuidHelper.GetAsString: QStringW;
begin
Result := GuidToString(FData.AsGuid);
end;

function TQGuidHelper.GetAsVariant: Variant;
begin
Result := GuidToString(FData.AsGuid);
end;

procedure TQGuidHelper.SetAsBytes(const Value: TBytes);
begin
if Length(Value) = SizeOf(TGuid) then
  Move(Value[0], FData.AsGuid, SizeOf(TGuid))
else
  ConvertError;
end;

procedure TQGuidHelper.SetAsGuid(const Value: TGuid);
begin
FData.AsGuid := Value;
end;

procedure TQGuidHelper.SetAsString(const Value: QStringW);
begin
if not TryStrToGuid(Value, FData.AsGuid) then
  ConvertError;
end;

procedure TQGuidHelper.SetAsVariant(const Value: Variant);
begin
if not TryStrToGuid(Value, FData.AsGuid) then
  ConvertError;
end;

{ TQBinaryHelper }

function TQBinaryHelper.GetAsBoolean: Boolean;
begin
if FData.Size = 1 then
  Result := (FData.AsBinary^ <> 0)
else
  ConvertError;
end;

function TQBinaryHelper.GetAsBytes: TBytes;
begin
SetLength(Result, FData.Size);
Move(FData.AsBinary^, Result[0], FData.Size);
end;

function TQBinaryHelper.GetAsDateTime: TDateTime;
begin
if FData.Size = SizeOf(TDateTime) then
  Result := PDateTime(FData.AsBinary)^
else
  ConvertError;
end;

function TQBinaryHelper.GetAsFloat: Double;
begin
if FData.Size = SizeOf(Double) then
  Result := PDouble(FData.AsBinary)^
else
  ConvertError;
end;

function TQBinaryHelper.GetAsGuid: TGuid;
begin
if FData.Size = SizeOf(TGuid) then
  Result := PGuid(FData.AsBinary)^
else
  ConvertError;
end;

function TQBinaryHelper.GetAsInteger: Int64;
begin
if FData.Size = SizeOf(Int64) then
  Result := PInt64(FData.AsBinary)^
else
  ConvertError;
end;

function TQBinaryHelper.GetAsInterval: TQInterval;
begin
if FData.Size = SizeOf(TQInterval) then
  Result := PQInterval(FData.AsBinary)^
else
  ConvertError;
end;

function TQBinaryHelper.GetAsString: QStringW;
begin
Result := qstring.BinToHex(FData.AsBinary, FData.Size);
end;

function TQBinaryHelper.GetAsVariant: Variant;
begin
if FData.Size > 0 then
  begin
  Result := VarArrayCreate([0, FData.Size - 1], varByte);
  Move(FData.AsBinary^, VarArrayLock(Result)^, FData.Size);
  VarArrayUnlock(Result);
  end
else
  VarClear(Result);
end;

procedure TQBinaryHelper.NeedSize(const ASize: Cardinal);
var
  ANewSize: Cardinal;
begin
if ASize > FData.Allocated then
  begin
  ANewSize := ((ASize shr 4) + 1) shl 4; // 按16字节对齐
  if FData.Allocated > 0 then
    ReallocMem(FData.AsBinary, ANewSize)
  else
    GetMem(FData.AsBinary, ANewSize);
  FData.Allocated := ANewSize;
  end
else if FData.Allocated > 0 then
  begin
  FData.Allocated := 0;
  FreeMem(FData.AsBinary);
  FData.AsBinary := nil;
  end;
FData.Size := ASize;
end;

procedure TQBinaryHelper.SetAsBoolean(const Value: Boolean);
begin
NeedSize(SizeOf(Boolean));
PBoolean(FData.AsBinary)^ := Value;
end;

procedure TQBinaryHelper.SetAsBytes(const Value: TBytes);
begin
NeedSize(Length(Value));
if Length(Value) > 0 then
  Move(Value[0], FData.AsBinary^, FData.Size);
end;

procedure TQBinaryHelper.SetAsDateTime(const Value: TDateTime);
begin
NeedSize(SizeOf(TDateTime));
PDateTime(FData.AsBinary)^ := Value;
end;

procedure TQBinaryHelper.SetAsFloat(const Value: Double);
begin
NeedSize(SizeOf(Double));
PDouble(FData.AsBinary)^ := Value;
end;

procedure TQBinaryHelper.SetAsGuid(const Value: TGuid);
begin
NeedSize(SizeOf(TGuid));
PGuid(FData.AsBinary)^ := Value;
end;

procedure TQBinaryHelper.SetAsInteger(const Value: Int64);
begin
NeedSize(SizeOf(Int64));
PInt64(FData.AsBinary)^ := Value;
end;

procedure TQBinaryHelper.SetAsInterval(const Value: TQInterval);
begin
NeedSize(SizeOf(TQInterval));
PQInterval(FData.AsBinary)^ := Value;
end;

procedure TQBinaryHelper.SetAsString(const Value: QStringW);
begin
NeedSize(Length(Value) shl 1);
Move(PQCharW(Value)^, FData.AsBinary^, FData.Size);
end;

procedure TQBinaryHelper.SetAsVariant(const Value: Variant);
  procedure AddStringArray; // varOleStr
  var
    ABuilder: TQStringCatHelperW;
    I: Integer;
  begin
  ABuilder := TQStringCatHelperW.Create;
  try
    ABuilder.Cat('[');
    for I := VarArrayLowBound(Value, 1) to VarArrayHighBound(Value, 1) do
      ABuilder.Cat(QuotedStrW(VarToStr(Value[I]))).Cat(',');
    if ABuilder.Position > 1 then
      ABuilder.Back(1);
    ABuilder.Cat(']');
    SetAsString(ABuilder.Value);
  finally
    FreeObject(ABuilder);
  end;
  end;

  procedure AddAsArray;
  var
    AItemSize: Cardinal;
    AType: Word;
  begin
  AType := VarType(Value);
  if AType = varOleStr then
    AddStringArray
  else
    begin
    case AType of
      varBoolean, varShortInt, varByte: // 1B
        AItemSize := SizeOf(Byte);
      varSmallint, varWord: // 2B
        AItemSize := SizeOf(Smallint);
      varInteger, varLongWord: // 4B
        AItemSize := SizeOf(Integer);
      varSingle: // 4B
        AItemSize := SizeOf(Single);
      varDouble, varCurrency, varDate, varInt64, varUInt64: // 8B
        AItemSize := SizeOf(Double);
    else
      ConvertError;
    end;
    NeedSize(AItemSize * (VarArrayHighBound(Value, 1) -
      VarArrayLowBound(Value, 1) + 1));
    Move(VarArrayLock(Value)^, FData.AsBinary^, FData.Size);
    end;
  end;

begin
if VarIsArray(Value) then
  AddAsArray
else
  begin
  case VarType(Value) of
    varNull:
      NeedSize(0);
    varSmallint, varShortInt, varByte, varWord, varLongWord, varInt64,
      varUInt64:
      SetAsInteger(Value);
    varSingle, varDouble, varCurrency:
      SetAsFloat(Value);
    varDate:
      SetAsDateTime(Value);
    varOleStr, varString, varUString:
      SetAsString(Value);
    varBoolean:
      SetAsBoolean(Value)
  else
    ConvertError;
  end;
  end;
end;

{ TQRecordHelper }

function TQRecordHelper.GetAsRecord: PByte;
begin
Result := PByte(IntPtr(FData.AsBinary) + SizeOf(Pointer));
end;

function TQRecordHelper.GetClassMeta: TQClassMeta;
begin
Result := TQClassMeta(FData.AsBinary);
end;

function TQRecordHelper.GetFields(AIndex: Integer): TQClassField;
begin
Result := ClassMeta.Fields[AIndex];
end;

procedure TQRecordHelper.SetAsRecord(const Value: PByte);
begin
inherited;
Move(Value^, GetAsRecord^, FData.Size);
end;

{ TQClassMeta }

function TQClassMeta.AddChild(AClass: TQClassMeta): Integer;
begin
Result := FChildren.IndexOf(AClass);
if Result = -1 then
  begin
  Result := FChildren.Add(AClass);
  AClass.FParents.Add(Self);
  end;
end;

function TQClassMeta.AddField(const AName: QStringW): TQClassField;
begin
Result := FieldByName(AName);
if Result = nil then
  begin
  Result := TQClassField.Create;
  Result.FName := AName;
  Result.FNameHash := FOwner.HashOf(AName);
  FFields.Add(Result);
  SizeChanged;
  end;
end;

procedure TQClassMeta.BeforeDestruction;
begin
inherited;
FInDestroy := True;
end;

procedure TQClassMeta.Clear;
begin
ClearChild;
ClearFields;
ClearParents;
end;

procedure TQClassMeta.ClearChild;
var
  I: Integer;
  AChild: TQClassMeta;
begin
for I := 0 to FChildren.Count - 1 do
  begin
  AChild := FChildren[I];
  AChild.SizeChanged;
  AChild.FParents.Remove(Self);
  end;
FChildren.Clear;
end;

procedure TQClassMeta.ClearFields;
var
  I: Integer;
begin
for I := 0 to FFields.Count - 1 do
  FreeObject(FFields[I]);
FFields.Clear;
end;

procedure TQClassMeta.ClearParents;
var
  I: Integer;
begin
for I := 0 to FParents.Count - 1 do
  FParents[I].FChildren.Remove(Self);
FParents.Clear;
end;

constructor TQClassMeta.Create(ABaseSize: Cardinal);
begin
inherited Create;
FParents := TQClassMetaList.Create;
FChildren := TQClassMetaList.Create;
FFields := TQClassFields.Create;
FBaseSize := ABaseSize;
end;

procedure TQClassMeta.DeleteChild(AIndex: Integer);
begin
FChildren[AIndex].FParents.Remove(Self);
FChildren.Delete(AIndex);
end;

procedure TQClassMeta.DeleteField(AIndex: Integer);
begin
FreeObject(FFields[AIndex]);
FFields.Delete(AIndex);
end;

procedure TQClassMeta.DeleteField(const AName: QStringW);
var
  I: Integer;
  AHash: Cardinal;
begin
AHash := FOwner.HashOf(AName);
for I := 0 to FFields.Count - 1 do
  begin
  if (FFields[I].FNameHash = AHash) and (FFields[I].Name = AName) then
    begin
    DeleteField(I);
    Break;
    end;
  end;
end;

destructor TQClassMeta.Destroy;
begin
Clear;
if Assigned(FOwner) then
  FOwner.FClasses.Delete(Self, FNameHash);
inherited;
end;

function TQClassMeta.FieldByName(const AName: QStringW): TQClassField;
var
  I: Integer;
  AHash: Cardinal;
  AField: TQClassField;
begin
AHash := FOwner.HashOf(AName);
Result := nil;
for I := 0 to FFields.Count - 1 do
  begin
  AField := FFields[I];
  if (AField.FNameHash = AHash) and (AField.FName = AName) then
    begin
    Result := AField;
    Break;
    end;
  end;
end;

function TQClassMeta.GetChildCount: Integer;
begin
Result := FChildren.Count;
end;

function TQClassMeta.GetChildren(AIndex: Integer): TQClassMeta;
begin
Result := FChildren[AIndex];
end;

function TQClassMeta.GetFieldCount: Integer;
begin
Result := FFields.Count;
end;

function TQClassMeta.GetFields(AIndex: Integer): TQClassField;
begin
Result := FFields[AIndex];
end;

{ 计算需要分配的内存大小，这个算法暂时不知道是否能够和普通的程序对齐方式算法一致
  需要仔细核对，目前先内部使用，可以不用关心类型交换的问题
}
function TQClassMeta.GetAllocSize: Cardinal;
var
  I, AlignBytes: Integer;
  AField: TQClassField;
begin
if FSizeChanged then
  begin
  FAllocSize := FBaseSize;
  for I := 0 to FParents.Count - 1 do
    Inc(FAllocSize, FParents[I].InstanceSize);
  AlignBytes := FAllocSize mod AlignSize;
  if AlignBytes <> 0 then
    Inc(FAllocSize, AlignSize - AlignBytes);
  for I := 0 to FFields.Count - 1 do
    begin
    AField := FFields[I];
    Inc(FAllocSize, AField.Size);
    end;
  end;
Result := FAllocSize;
end;

function TQClassMeta.GetBaseType: TQClassMeta;
begin
if Assigned(FBaseType) then
  Result := FBaseType
else
  Result := Self;
end;

function TQClassMeta.GetParents(AIndex: Integer): TQClassMeta;
begin
Result := FParents[AIndex];
end;

function TQClassMeta.IsChildOf(AClass: TQClassMeta): Boolean;
var
  I: Integer;
begin
Result := AClass.FChildren.IndexOf(Self) <> -1; // 检查自己是否是指定的类的直属子类
if not Result then // 不是，检查自己所属的父类是否是指定的子类
  begin
  I := 0;
  while I < FParents.Count - 1 do
    begin
    Result := FParents[I].IsChildOf(AClass);
    if Result then
      begin
      Result := True;
      Break;
      end;
    end;
  end;
end;

function TQClassMeta.IsParentOf(AClass: TQClassMeta): Boolean;
begin
Result := AClass.IsChildOf(Self);
end;

procedure TQClassMeta.SetAlignSize(const Value: Byte);
begin
FAlignSize := Value;
end;

/// 标记尺寸发生变更
procedure TQClassMeta.SizeChanged;
var
  I: Integer;
begin
FSizeChanged := True;
for I := 0 to FChildren.Count - 1 do
  FChildren[I].SizeChanged;
end;

{ TQClassTree }

function TQClassTree.Add(const AName: QStringW; ABaseSize: Integer)
  : TQClassMeta;
begin
Result := Find(AName);
if not Assigned(Result) then
  begin
  Result := TQClassMeta.Create(ABaseSize);
  Result.FName := AName;
  Result.FNameHash := HashOf(AName);
  Result.FOwner := Self;
  FClasses.Add(Result, Result.FNameHash);
  end;
end;

procedure TQClassTree.AddDefaultClasses;
var
  AType, AChild: TQClassMeta;
begin
// 整数列表列表
AType := Add('__int__', 8); // 整数基类型
AType.IsPublic := False; // 私有类型，不对外公开，不能用于其它位置的声明
AChild := Add('int64', 8);
AChild.FBaseType := AType;
AType.AddChild(AChild); // 64位整数
AType.AddChild(Add('int32', 4)); // 32位整数
AType.AddChild(Add('int16', 2)); // 16位整数
AType.AddChild(Add('int8', 1)); // 8位整数
AType.AddChild(Add('uint64', 8)); // 64位无符号整数
AType.AddChild(Add('uint32', 4)); // 32位无符号整数
AChild := Add('uint16', 2); // 16位无符号整数
AType.AddChild(AChild);
AChild.AddChild(Add('char', 2)); // 字符类型继承自uint16
AChild := Add('uint8', 1);
AType.AddChild(AChild); // 8位无符号整数
AChild.AddChild(Add('BYTE', 1)); // 8位无符号整数的别名
AChild.AddChild(Add('bool', 1)); // 布尔值
// 浮点类型列表
AType := Add('__float__', 8); // 浮点类型
AType.IsPublic := False;
AType.AddChild(Add('single', 4));
AType.AddChild(Add('double', 8));
AType.AddChild(Add('money', 8)); // 货币
AType.AddChild(Add('date', 8)); // 日期
AType.AddChild(Add('time', 8));
AType.AddChild(Add('datetime', 8));
// 字符串类型
AType.AddChild(Add('string')); // 普通的Unicode编码字符串
AType.AddChild(Add('ansistring')); // Ansi编码字符串
AType.AddChild(Add('utf8string')); // Utf8编码字符串
AType := Add('__complex__', 0); // 复合数据类型的基准
end;

procedure TQClassTree.Clear;
begin
FClasses.Clear;
end;

constructor TQClassTree.Create;
var
  AClass: TQClassMeta;
begin
FClasses := TQHashTable.Create();
FClasses.AutoSize := True;
FClasses.OnDelete := DoDeleteClass;
AddDefaultClasses;
end;

procedure TQClassTree.Delete(const AName: QStringW);
var
  AClass: TQClassMeta;
begin
AClass := Find(AName);
if Assigned(AClass) then
  FClasses.Delete(AClass, AClass.FNameHash);
end;

destructor TQClassTree.Destroy;
begin
FClasses.ForEach(DoClearItem); // 先将父子关系删除，以加快类元数据释放速度
Clear;
FreeObject(FClasses);
inherited;
end;

procedure TQClassTree.DoClearItem(ATable: TQHashTable; AHash: TQHashType;
  AData: Pointer);
var
  AClass: TQClassMeta;
begin
AClass := AData;
AClass.FParents.Clear;
AClass.FChildren.Clear;
end;

procedure TQClassTree.DoDeleteClass(ATable: TQHashTable; AHash: TQHashType;
  AData: Pointer);
var
  AClass: TQClassMeta;
begin
AClass := AData;
if not AClass.FInDestroy then
  FreeObject(TQClassMeta(AData));
end;

procedure TQClassTree.EnumClasses(AList: TQClassMetaList);
var
  I: Integer;
  AHashList: PQHashList;
begin
for I := 0 to FClasses.BucketCount - 1 do
  begin
  AHashList := FClasses.Buckets[I];
  while AHashList <> nil do
    begin
    AList.Add(AHashList.Data);
    AHashList := AHashList.Next;
    end;
  end;
end;

function TQClassTree.Find(const AName: QStringW): TQClassMeta;
var
  AHashCode: Cardinal;
  AList: PQHashList;
begin
AHashCode := HashOf(AName);
AList := FClasses.Find(AHashCode);
while AList <> nil do
  begin
  Result := AList.Data;
  if Result.FName = AName then
    Exit;
  AList := AList.Next;
  end;
Result := nil;
end;

function TQClassTree.GetCount: Integer;
begin
Result := FClasses.Count;
end;

function TQClassTree.HashOf(const S: QStringW): Cardinal;
begin
if IgnoreCase then
  Result := qstring.HashOf(PQCharW(UpperCase(S)), Length(S) shl 1)
else
  Result := qstring.HashOf(PQCharW(S), Length(S) shl 1);
end;

{ TQClassField }

constructor TQClassField.Create;
begin

end;

destructor TQClassField.Destroy;
begin

inherited;
end;

end.
