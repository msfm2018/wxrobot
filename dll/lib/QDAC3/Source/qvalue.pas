unit qvalue;

interface

uses classes, sysutils, variants, varutils, math, qstring, fmtbcd, qtimetypes,
  qjson, qmsgpack;
{$I qdac.inc}

{
  TQValue 是一个类似与变体类型的实现，QDAC 使用它做为记录的基础，如每个字段的值
  就是由两个 TQValue 组成，一个代表原始值，一个代表新值

  变更说明

  2016.3.5
  =========
  * 修正了 AsVariant 时，从 Variant 字节流转换为流内容时出错的问题（幽灵报告）
  2015.8.23
  =========
  * 修正了AsVariant目标为流时，源为非字节数组时出错的问题
  * 修正了Reset时没有处理 Bcd 类型的问题（感谢ijia)
}
type
  TQValueDataType = (vdtUnset, vdtNull, vdtBoolean, vdtSingle, vdtFloat,
    vdtInteger, vdtInt64, vdtCurrency, vdtBcd, vdtGuid, vdtDateTime,
    vdtInterval, vdtString, vdtStream, vdtArray);

  PQValue = ^TQValue;
  TQValueStream = class(TMemoryStream)
  end;
  // C++ TQInterval 编译有错误，所以自己定义下
{$NODEFINE TQValueData}
{$NODEFINE TQValueStream}
{$HPPEMIT 'namespace Qvalue{'}
{$HPPEMIT 'struct TQValue;'}
{$HPPEMIT 'typedef TMemoryStream TQValueStream;'}
{$HPPEMIT 'struct TQValueData{'}
{$HPPEMIT '   __int64 AsInt64;'}
(*$HPPEMIT ' Currency & GetAsCurrency(){'*)
{$HPPEMIT '   return *((Currency *)this);'}
(*$HPPEMIT '  }'*)
(*$HPPEMIT ' void SetAsCurrency(const Currency &val){'*)
{$HPPEMIT '   *((Currency *)this)=val;'}
(*$HPPEMIT '  }'*)
(*$HPPEMIT ' TDateTime & GetAsDateTime(){'*)
{$HPPEMIT '   return *((TDateTime *)this);'}
(*$HPPEMIT '  }'*)
(*$HPPEMIT ' void SetAsDateTime(const TDateTime &val){'*)
{$HPPEMIT '   *((TDateTime *)this)=val;'}
(*$HPPEMIT '  }'*)
(*$HPPEMIT ' bool & GetAsBoolean(){'*)
{$HPPEMIT '   return *((bool *)this);'}
(*$HPPEMIT '  }'*)
(*$HPPEMIT ' void SetAsBoolean(const bool &val){'*)
{$HPPEMIT '   *((bool *)this)=val;'}
(*$HPPEMIT '  }'*)
(*$HPPEMIT ' double & GetAsFloat(){'*)
{$HPPEMIT '   return *((double *)this);'}
(*$HPPEMIT '  }'*)
(*$HPPEMIT ' void SetAsFloat(const double &val){'*)
{$HPPEMIT '   *((double *)this)=val;'}
(*$HPPEMIT '  }'*)
(*$HPPEMIT ' int & GetAsInteger(){'*)
{$HPPEMIT '   return *((int *)this);'}
(*$HPPEMIT '  }'*)
(*$HPPEMIT ' void SetAsInteger(const int &val){'*)
{$HPPEMIT '   *((int *)this)=val;'}
(*$HPPEMIT '  }'*)
(*$HPPEMIT ' __property int AsInteger={read=GetAsInteger,write=SetAsInteger};'*)
(*$HPPEMIT ' __property double AsFloat={read=GetAsFloat,write=SetAsFloat};'*)
(*$HPPEMIT ' __property bool AsBoolean={read=GetAsBoolean,write=SetAsBoolean};'*)
(*$HPPEMIT ' __property Currency AsDateTime={read=GetAsDateTime,write=SetAsDateTime};'*)
(*$HPPEMIT ' __property Currency AsCurrency={read=GetAsCurrency,write=SetAsCurrency};'*)
(*$HPPEMIT '  };*)
(*$HPPEMIT '};*)

  /// 一个值对象
  TQValueData = record
    case Integer of
      0:
        (AsBoolean: Boolean);
      1:
        (AsFloat: Double);
      2:
        (AsInteger: Integer);
      3:
        (AsInt64: Int64);
      4:
        (AsBcd: PBcd);
      5:
        (AsGuid: PGuid);
      6:
        (AsDateTime: TDateTime);
      7:
        (AsInterval: TQInterval);
      8:
        (AsString: PQStringW);
      9:
        (AsStream: {$IFDEF NEXTGEN}Pointer{$ELSE}TQValueStream{$ENDIF});
      10:
        (Size: Cardinal;
          Items: PQValue;
        );
      11:
        (AsCurrency: Currency);
      12:
        (AsSingle: Single);
      13:
        (AsShort: Shortint);
      14:
        (AsByte: Byte);
      15:
        (AsSmallint: Smallint);
      16:
        (AsWord: Word);
      17:
        (AsPointer: Pointer);
      18:
        (ValueType: TQValueDataType;
          Value: PQValue;
        );
  end;

  TQValue = record
    Value: TQValueData;
    ValueType: TQValueDataType;
  end;

  TQValues = array of TQValue;

  TQValueHelper = record helper for TQValue
  private
    function GetItems(AIndex: Integer): PQValue;
    function GetCount: Integer; inline;
    function GetAsBcd: TBcd;
    function GetAsBoolean: Boolean;
    function GetAsCurrency: Currency;
    function GetAsDateTime: TDateTime;
    function GetAsGuid: TGuid;
    function GetAsInt64: Int64;
    function GetAsInteger: Integer;
    function GetAsInterval: TQInterval;
    function GetAsStream: TQValueStream;
    function GetAsString: QStringW;
    function GetIsNull: Boolean;
    procedure SetAsBcd(const AValue: TBcd);
    procedure SetAsBoolean(const AValue: Boolean);
    procedure SetAsCurrency(const AValue: Currency);
    procedure SetAsDateTime(const AValue: TDateTime);
    procedure SetAsGuid(const AValue: TGuid);
    procedure SetAsInt64(const AValue: Int64);
    procedure SetAsInteger(const AValue: Integer);
    procedure SetAsInterval(const AValue: TQInterval);
    procedure SetAsString(const AValue: QStringW);
    function GetAsFloat: Double;
    procedure SetAsFloat(const AValue: Double);
    function GetAsBytes: TBytes;
    procedure SetAsBytes(const AValue: TBytes);
    function GetAsVariant: Variant;
    procedure SetAsVariant(const AValue: Variant);
    function GetSize: Integer;
    function GetAsSingle: Single;
    procedure SetAsSingle(const AValue: Single);
  public
    procedure Reset;
    function TypeNeeded(AType: TQValueDataType): PQValue;
    function ArrayNeeded(ALen: Integer): PQValue;
    procedure From(const V: Variant);
    procedure SaveToStream(AStream: TStream);
    procedure SaveToFile(const AFileName: String);
    procedure LoadFromStream(AStream: TStream);
    procedure LoadFromFile(const AFileName: String);
    // 写入流函数
    class procedure WriteNull(AStream: TStream); static;
    class procedure WriteUnset(AStream: TStream); static;
    class procedure WriteInt(AStream: TStream; V: Int64); static;
    class procedure WriteBoolean(AStream: TStream; V: Boolean); static;
    class procedure WriteSingle(AStream: TStream; V: Single); static;
    class procedure WriteFloat(AStream: TStream; V: Double); static;
    class procedure WriteGuid(AStream: TStream; const V: TGuid); static;
    class procedure WriteBcd(AStream: TStream; const V: TBcd); static;
    class procedure WriteInterval(AStream: TStream; V: TQInterval); static;
    class procedure WriteDateTime(AStream: TStream; AValue: TDateTime); static;
    class procedure WriteCurrency(AStream: TStream; V: Currency); static;
    class procedure WriteArray(AStream: TStream; const V: array of const);
      overload; static;
    class procedure WriteValue(AStream: TStream; const V: TQValue); static;
    class procedure WriteString(AStream: TStream; V: QStringW); static;
    class procedure WriteBinary(AStream: TStream; V: TBytes); overload; static;
    class procedure WriteBinary(AStream: TStream; V: PByte; L: Int64);
      overload; static;
    class procedure WriteStream(AStream: TStream; ASource: TStream;
      ACount: Int64); static;
    class procedure WriteFile(AStream: TStream; AFile: QStringW); static;

    function IsEqual(const AValue: TQValue): Boolean;
    procedure Copy(const ASource: TQValue; AStrict: Boolean);
    property Items[AIndex: Integer]: PQValue read GetItems; default;
    property Count: Integer read GetCount;
    property IsNull: Boolean read GetIsNull;
    property AsString: QStringW read GetAsString write SetAsString;
    property AsBoolean: Boolean read GetAsBoolean write SetAsBoolean;
    property AsInteger: Integer read GetAsInteger write SetAsInteger;
    property AsInt64: Int64 read GetAsInt64 write SetAsInt64;
    property AsSingle: Single read GetAsSingle write SetAsSingle;
    property AsFloat: Double read GetAsFloat write SetAsFloat;
    property AsBcd: TBcd read GetAsBcd write SetAsBcd;
    property AsGuid: TGuid read GetAsGuid write SetAsGuid;
    property AsDateTime: TDateTime read GetAsDateTime write SetAsDateTime;
    property AsInterval: TQInterval read GetAsInterval write SetAsInterval;
    property AsStream: TQValueStream read GetAsStream;
    property AsCurrency: Currency read GetAsCurrency write SetAsCurrency;
    property AsBytes: TBytes read GetAsBytes write SetAsBytes;
    property AsVariant: Variant read GetAsVariant write SetAsVariant;
    property Size: Integer read GetSize;
  end;

  TQValueCompare = function(const V1, V2: PQValue): Integer;

function LookupCompareProc(ADataType1, ADataType2: TQValueDataType;
  AIgnoreCase, ANaturalCompare: Boolean): TQValueCompare;

resourcestring
  SValueNotArray = '当前值不是数组类型，无法按数组方式访问。';
  SConvertError = '无法将 %s 转换为 %s 类型的值。';
  SUnsupportStreamSource = '无法将 Variant 类型 %d(0x%x) 转换为流。';

const
  QValueTypeName: array [TQValueDataType] of String = ('Unassigned', 'NULL',
    'Boolean', 'Single', 'Float', 'Integer', 'Int64', 'Currency', 'Bcd', 'Guid',
    'DateTime', 'Interval', 'String', 'Stream', 'Array');

implementation

const
  // 0xxx xxxx Int8 0~127
  TYPE_UNSET = $80; // 1000 0000 Unset $80
  TYPE_NULL = $81; // 1000 0001 Null  $81
  TYPE_TRUE = $82; // 1000 0010 True  $82
  TYPE_FALSE = $83; // 1000 0011 False $8
  TYPE_INT8 = $84; // 1000 0100 Int:8 $84
  TYPE_UINT8 = $85; // 1000 0101 UInt:8 $85
  TYPE_INT16 = $86; // 1000 0110 Int:16 $86
  TYPE_UINT16 = $87; // 1000 0111 UInt:16 $87
  TYPE_INT32 = $88; // 1000 1000 Int:32 $88
  TYPE_UINT32 = $89; // 1000 1001 UInt:32 $89
  TYPE_INT64 = $8A; // 1000 1010 Int:64 $8A
  TYPE_UINT64 = $8B; // 1000 1011 UInt:64 $8B
  TYPE_FLOAT32 = $8C; // 1000 1100 Float:32 $8C
  TYPE_FLOAT64 = $8D; // 1000 1101 Float:64 $8D
  TYPE_GUID = $8E; // 1000 1110 Guid   $8E
  TYPE_BCD = $8F; // 1000 1111 Bcd    $8F
  TYPE_INT4 = $90; // 1001 xxxx Int:4 -16~-1  $9x
  TYPE_ARRAY4 = $A0; // 1010 xxxx Array:4       $Ax
  TYPE_STR4 = $B0; // 1011 xxxx String:4      $Bx
  TYPE_BIN4 = $C0; // 1100 xxxx Binary:4      $Cx
  TYPE_MONEY4 = $D0; // 1101 xxxx Currency:4    $Dx
  TYPE_ARRAY8 = $E1; // 1110 0001 Array:8       $E1
  TYPE_ARRAY16 = $E2; // 1110 0010 Array:16      $E2
  TYPE_ARRAY32 = $E3; // 1110 0011 Array:32      $E3
  TYPE_STR8 = $E4; // 1110 0100 String:8      $E4
  TYPE_STR16 = $E5; // 1110 0101 String:16     $E5
  TYPE_STR32 = $E6; // 1110 0110 String:32     $E6
  TYPE_BIN8 = $E7; // 1110 0111 Binary:8      $E7
  TYPE_BIN16 = $E8; // 1110 1000 Binary:16     $E8
  TYPE_BIN32 = $E9; // 1110 1001 Binary:32     $E9
  TYPE_BIN64 = $EA; // 1110 1010 Interval:64   $EA
  TYPE_DATETIME = $EB; // 1110 1011 DateTime      $EB//Double
  TYPE_DATE = $EC; // 1110 1100 Date          $EC//Integer
  TYPE_TIME = $ED; // 1110 1101 Time          $ED//Single
  TYPE_MONEY8 = $EE; // 1110 1110 Currency:8    $EE
  TYPE_MONEY16 = $EF; // 1110 1111 Currency:16   $EF
  TYPE_MONEY32 = $F0; // 1111 0000 Currency:32   $F0
  TYPE_MONEY64 = $F1; // 1111 0001 Currency:64   $F1
  TYPE_INTERVAL = $F2; // 1111 0010 Interval     $F2
  TYPE_USTR8 = $F3; // 1111 0011 UnicodeString:8 $F3
  TYPE_USTR16 = $F4; // 1111 0100 UnicodeString:16  $F4
  TYPE_USTR32 = $F5; // 1111 0101 UnicodeString:32  $F5
  TYPE_INFINITE = $F6; // 1111 0110 +∞ $F6
  TYPE_NEG_INFINITE = $F7; // 1111 0111 -∞ $F7
  TYPE_REFER = $F8; // 1111 1000 引用类型，后面跟的是一个整数对应的是相应的引用索引(ReferInt整数编码)
  TYPE_DEFAULT = $FF; // 1111 1111 没有任何值，取默认值

  // 1111 1000
  // 1111 1001
  // 1111 1010
  // 1111 1011
  // 1111 1100
  // 1111 1101
  // 1111 1110
  // 1111 1111

{$IF RTLVersion<27}

  // XE3以前没有此函数
function CurrencyToBcd(const Curr: Currency): TBcd;
begin
  Result := StrToBcd(CurrToStr(Curr));
end;

function BcdToInt64(const V: TBcd): Int64; inline;
begin
  Result := StrToInt64(BcdToStr(V));
end;
{$IFEND}

{ 引用类型的整数是一个特殊编码的大整数，每一个字节如果>=128，则代表后面一个字节
  是内容的一部分，自己的低7位是有效数据的一部分，左移7位后得到实际的结果。最后一个
  字节小于128，直接将当前值左移7位后加上这个值就得到最终的结果，由此：
  0~127 (0x7F,2^7-1) 占1个字节
  128~16383(0x3FFF,2^14-1) 占2个字节
  16384~2097151(0x1FFFFF,2^21-1) 占3个字节
  2097152~26843455(0xFFFFFFF,2^28-1)占4个字节
  26843456~34359738367(0x7FFFFFFFF,2^35-1)占5个字节
  34359738368~‭4398046511103(0x3FFFFFFFFFF,2^42-1)占6个字节
  4398046511104~562949953421311(0x1FFFFFFFFFFFF‬,2^49-1)占7个字节
  562949953421312~72057594037927935(0x‭FFFFFFFFFFFFFF,2^56-1)占8个字节
  依次继续往下类推，可以表示的范围实际上不受限制，但ReadReferInt/WriteReferInt暂时
  只支持到Int64(Int128不是内置类型，所以暂时不管）
}
function ReadReferInt(var p: PByte): Int64;
begin
  Result := 0;
  while (p^ and $80) <> 0 do
  begin
    Result := (Result shl 7) + (p^ and $7F);
    Inc(p);
  end;
  Result := (Result shl 7) + p^;
  Inc(p);
end;

procedure WriteReferInt(var p: PByte; V: Int64);
begin
  if V = 0 then
  begin
    p^ := 0;
    Inc(p);
  end
  else
  begin
    while V > 0 do
    begin
      if V > 127 then
        p^ := $80 or (V and $7F)
      else
        p^ := (V and $7F);
      Inc(p);
      V := V shr 7;
    end;
  end;
end;

function Int64ToBcd(const V: Int64): TBcd; inline;
begin
  Result := StrToBcd(IntToStr(V));
end;
/// 值比较操作，排序或过滤时会使用这些表达式来比较两个值的大小

function Comp_Float_Zero(const V: Double): Integer; inline;
begin
  if V > 0 then
    Result := 1
  else if V < 0 then
    Result := -1
  else
    Result := 0;
end;

/// 布尔 vs *
function Comp_Bool_Bool(const V1, V2: PQValue): Integer;
begin
  Result := Ord(V1.Value.AsBoolean) - Ord(V2.Value.AsBoolean);
end;

function Comp_Bool_Float(const V1, V2: PQValue): Integer;
begin
  Result := Ord(V1.Value.AsBoolean) - Integer(not IsZero(V2.Value.AsFloat));
end;

function Comp_Bool_Single(const V1, V2: PQValue): Integer;
begin
  Result := Ord(V1.Value.AsBoolean) - Integer(not IsZero(V2.Value.AsSingle));
end;

function Comp_Bool_Int(const V1, V2: PQValue): Integer;
begin
  Result := Ord(V1.Value.AsBoolean) - V2.Value.AsInteger;
end;

function Comp_Bool_Int64(const V1, V2: PQValue): Integer;
begin
  Result := Ord(V1.Value.AsBoolean) - V2.Value.AsInt64;
end;

function Comp_Bool_Bcd(const V1, V2: PQValue): Integer;
begin
  Result := Ord(V1.Value.AsBoolean) - Trunc(BcdToDouble(V2.Value.AsBcd^));
end;

function Comp_Bool_DateTime(const V1, V2: PQValue): Integer;
begin
  Result := Ord(V1.Value.AsBoolean) - Trunc(V2.Value.AsDateTime);
end;

function Comp_Bool_Currency(const V1, V2: PQValue): Integer;
begin
  Result := Ord(V1.Value.AsBoolean) * 10000 - V2.Value.AsInt64;
end;

function Comp_Bool_String(const V1, V2: PQValue): Integer;
var
  b: Boolean;
begin
  if TryStrToBool(V2.Value.AsString^, b) then
    Result := Ord(V1.Value.AsBoolean) - Ord(b)
  else
    raise EConvertError.CreateFmt(SConvertError, [V2.Value.AsString^, 'bool']);
end;

/// Single vs *
function Comp_Single_Bool(const V1, V2: PQValue): Integer;
begin
  Result := Trunc(V1.Value.AsSingle) - Ord(V2.Value.AsBoolean);
end;

function Comp_Single_Single(const V1, V2: PQValue): Integer;
begin
  Result := Comp_Float_Zero(V1.Value.AsSingle - V2.Value.AsSingle);
end;

function Comp_Single_Float(const V1, V2: PQValue): Integer;
begin
  Result := Comp_Float_Zero(V1.Value.AsSingle - V2.Value.AsFloat);
end;

function Comp_Single_Int(const V1, V2: PQValue): Integer;
begin
  Result := Comp_Float_Zero(V1.Value.AsSingle - V2.Value.AsInteger);
end;

function Comp_Single_Int64(const V1, V2: PQValue): Integer;
begin
  Result := Comp_Float_Zero(V1.Value.AsSingle - V2.Value.AsInt64);
end;

function Comp_Single_Bcd(const V1, V2: PQValue): Integer;
begin
  Result := BcdCompare(DoubleToBcd(V1.Value.AsSingle), V2.Value.AsBcd^);
end;

function Comp_Single_DateTime(const V1, V2: PQValue): Integer;
begin
  Result := Comp_Single_Single(V1, V2);
end;

function Comp_Single_Currency(const V1, V2: PQValue): Integer;
begin
  Result := Comp_Float_Zero(V1.Value.AsSingle - V2.Value.AsCurrency);
end;

function Comp_Single_String(const V1, V2: PQValue): Integer;
var
  T: Single;
begin
  if TryStrToFloat(V2.Value.AsString^, T) then
  begin
    Result := Comp_Float_Zero(V1.Value.AsSingle - T);
  end
  else
    raise EConvertError.CreateFmt(SConvertError,
      [V2.Value.AsString^, 'Single']);
end;

/// Float vs *

function Comp_Float_Bool(const V1, V2: PQValue): Integer;
begin
  Result := Trunc(V1.Value.AsFloat) - Ord(V2.Value.AsBoolean);
end;

function Comp_Float_Single(const V1, V2: PQValue): Integer;
begin
  Result := Comp_Float_Zero(V1.Value.AsFloat - V2.Value.AsSingle);
end;

function Comp_Float_Float(const V1, V2: PQValue): Integer;
begin
  Result := Comp_Float_Zero(V1.Value.AsFloat - V2.Value.AsFloat);
end;

function Comp_Float_Int(const V1, V2: PQValue): Integer;
begin
  Result := Comp_Float_Zero(V1.Value.AsFloat - V2.Value.AsInteger);
end;

function Comp_Float_Int64(const V1, V2: PQValue): Integer;
begin
  Result := Comp_Float_Zero(V1.Value.AsFloat - V2.Value.AsInt64);
end;

function Comp_Float_Bcd(const V1, V2: PQValue): Integer;
begin
  Result := BcdCompare(DoubleToBcd(V1.Value.AsFloat), V2.Value.AsBcd^);
end;

function Comp_Float_DateTime(const V1, V2: PQValue): Integer;
begin
  Result := Comp_Float_Float(V1, V2);
end;

function Comp_Float_Currency(const V1, V2: PQValue): Integer;
begin
  Result := Comp_Float_Zero(V1.Value.AsFloat - V2.Value.AsCurrency);
end;

function Comp_Float_String(const V1, V2: PQValue): Integer;
var
  T: Double;
begin
  if TryStrToFloat(V2.Value.AsString^, T) then
  begin
    Result := Comp_Float_Zero(V1.Value.AsFloat - T);
  end
  else
    raise EConvertError.CreateFmt(SConvertError, [V2.Value.AsString^, 'float']);
end;

// Integer vs *
function Comp_Int_Bool(const V1, V2: PQValue): Integer;
begin
  Result := V1.Value.AsInteger - Ord(V2.Value.AsBoolean);
end;

function Comp_Int_Single(const V1, V2: PQValue): Integer;
begin
  Result := Comp_Float_Zero(V1.Value.AsInteger - V2.Value.AsSingle);
end;

function Comp_Int_Float(const V1, V2: PQValue): Integer;
begin
  Result := -Comp_Float_Int(V2, V1);
end;

function Comp_Int_Currency(const V1, V2: PQValue): Integer;
begin
  Result := V1.Value.AsInteger * Int64(10000) - V2.Value.AsInt64;
end;

function Comp_Int_Int(const V1, V2: PQValue): Integer;
begin
  Result := V1.Value.AsInteger - V2.Value.AsInteger;
end;

function Comp_Int_Int64(const V1, V2: PQValue): Integer;
begin
  Result := V1.Value.AsInteger - V2.Value.AsInt64;
end;

function Comp_Int_Bcd(const V1, V2: PQValue): Integer;
begin
  Result := BcdCompare(IntegerToBcd(V1.Value.AsInteger), V2.Value.AsBcd^);
end;

function Comp_Int_DateTime(const V1, V2: PQValue): Integer;
begin
  Result := Comp_Float_Zero(V1.Value.AsInteger - V2.Value.AsDateTime);
end;

function Comp_Int_String(const V1, V2: PQValue): Integer;
var
  T: Integer;
begin
  if TryStrToInt(V2.Value.AsString^, T) then
    Result := V1.Value.AsInteger - T
  else
    raise EConvertError.CreateFmt(SConvertError, [V2.Value.AsString^, 'int']);
end;

/// Int64 vs *

function Comp_Int64_Bool(const V1, V2: PQValue): Integer;
begin
  Result := V1.Value.AsInt64 - Ord(V2.Value.AsBoolean);
end;

function Comp_Int64_Single(const V1, V2: PQValue): Integer;
begin
  Result := Comp_Float_Zero(V1.AsInt64 - V2.Value.AsSingle);
end;

function Comp_Int64_Float(const V1, V2: PQValue): Integer;
begin
  Result := -Comp_Float_Int64(V2, V1);
end;

function Comp_Int64_Currency(const V1, V2: PQValue): Integer;
begin
  Result := V1.Value.AsInt64 * 10000 - V2.Value.AsInt64;
end;

function Comp_Int64_Int(const V1, V2: PQValue): Integer;
begin
  Result := V1.Value.AsInt64 - V2.Value.AsInteger;
end;

function Comp_Int64_Int64(const V1, V2: PQValue): Integer;
begin
  Result := V1.Value.AsInt64 - V2.Value.AsInt64;
end;

function Comp_Int64_Bcd(const V1, V2: PQValue): Integer;
begin
  Result := BcdCompare(StrToBcd(IntToStr(V1.Value.AsInt64)), V2.Value.AsBcd^);
end;

function Comp_Int64_DateTime(const V1, V2: PQValue): Integer;
begin
  Result := Comp_Float_Zero(V1.Value.AsInt64 - V2.Value.AsDateTime);
end;

function Comp_Int64_String(const V1, V2: PQValue): Integer;
var
  T: Int64;
begin
  if TryStrToInt64(V2.Value.AsString^, T) then
    Result := V1.Value.AsInt64 - T
  else
    raise EConvertError.CreateFmt(SConvertError, [V2.Value.AsString^, 'int64']);
end;

/// Currency vs *
function Comp_Currency_Bool(const V1, V2: PQValue): Integer;
begin
  Result := V1.Value.AsInt64 - Ord(V2.Value.AsBoolean) * 10000;
end;

function Comp_Currency_Single(const V1, V2: PQValue): Integer;
begin
  Result := Comp_Float_Zero(V1.Value.AsCurrency - V2.Value.AsSingle);
end;

function Comp_Currency_Float(const V1, V2: PQValue): Integer;
begin
  Result := Comp_Float_Zero(V1.Value.AsCurrency - V2.Value.AsFloat);
end;

function Comp_Currency_Int(const V1, V2: PQValue): Integer;
begin
  Result := V1.Value.AsInt64 - V2.Value.AsInteger * 10000;
end;

function Comp_Currency_Int64(const V1, V2: PQValue): Integer;
begin
  Result := V1.Value.AsInt64 - V2.Value.AsInt64 * 10000;
end;

function Comp_Currency_Bcd(const V1, V2: PQValue): Integer;
begin
  Result := BcdCompare(CurrencyToBcd(V1.Value.AsCurrency), V2.Value.AsBcd^);
end;

function Comp_Currency_DateTime(const V1, V2: PQValue): Integer;
begin
  Result := Comp_Float_Zero(V1.Value.AsCurrency - V2.Value.AsDateTime);
end;

function Comp_Currency_String(const V1, V2: PQValue): Integer;
var
  T: Double;
begin
  if TryStrToFloat(V2.Value.AsString^, T) then
    Result := Comp_Float_Zero(V1.Value.AsCurrency - T)
  else
    raise EConvertError.CreateFmt(SConvertError,
      [V2.Value.AsString^, 'Currency']);
end;

function Comp_Currency_Currency(const V1, V2: PQValue): Integer;
var
  T: Int64;
begin
  T := V1.Value.AsInt64 - V2.Value.AsInt64;
  if T > 0 then
    Result := 1
  else if T < 0 then
    Result := -1
  else
    Result := 0;
end;

/// Bcd vs *

function Comp_Bcd_Bool(const V1, V2: PQValue): Integer;
begin
  Result := BcdCompare(V1.Value.AsBcd^, IntegerToBcd(Ord(V2.Value.AsBoolean)));
end;

function Comp_Bcd_Single(const V1, V2: PQValue): Integer;
begin
  Result := BcdCompare(V1.Value.AsBcd^, DoubleToBcd(V2.Value.AsSingle));
end;

function Comp_Bcd_Float(const V1, V2: PQValue): Integer;
begin
  Result := BcdCompare(V1.Value.AsBcd^, DoubleToBcd(V2.Value.AsFloat));
end;

function Comp_Bcd_Currency(const V1, V2: PQValue): Integer;
begin
  Result := BcdCompare(V1.Value.AsBcd^, CurrencyToBcd(V2.Value.AsCurrency));
end;

function Comp_Bcd_Int(const V1, V2: PQValue): Integer;
begin
  Result := BcdCompare(V1.Value.AsBcd^, IntegerToBcd(V2.Value.AsInteger));
end;

function Comp_Bcd_Int64(const V1, V2: PQValue): Integer;
begin
  Result := BcdCompare(V1.Value.AsBcd^, StrToBcd(IntToStr(V2.Value.AsInt64)));
end;

function Comp_Bcd_Bcd(const V1, V2: PQValue): Integer;
begin
  Result := BcdCompare(V1.Value.AsBcd^, V2.Value.AsBcd^);
end;

function Comp_Bcd_DateTime(const V1, V2: PQValue): Integer;
begin
  Result := BcdCompare(V1.Value.AsBcd^, DoubleToBcd(V2.Value.AsFloat));
end;

function Comp_Bcd_String(const V1, V2: PQValue): Integer;
var
  bcd: TBcd;
begin
  if TryStrToBcd(V2.Value.AsString^, bcd) then
    Result := BcdCompare(V1.Value.AsBcd^, V2.Value.AsBcd^)
  else
    raise EConvertError.CreateFmt(SConvertError, [V2.Value.AsString^, 'bcd']);
end;

/// Guid

function Comp_Guid_Guid(const V1, V2: PQValue): Integer;
begin
  Result := BinaryCmp(@V1.Value.AsGuid^, @V2.Value.AsGuid^, SizeOf(TGuid));
end;

function Comp_Guid_String(const V1, V2: PQValue): Integer;
var
  T: TGuid;
begin
  if TryStrToGuid(V2.Value.AsString^, T) then
    Result := BinaryCmp(@V1.Value.AsGuid^, @T, SizeOf(TGuid))
  else
    raise EConvertError.CreateFmt(SConvertError, [V2.Value.AsString^, 'guid']);
end;

/// DateTime

function Comp_DateTime_Bool(const V1, V2: PQValue): Integer;
begin
  Result := Comp_Float_Zero(V1.Value.AsFloat - Ord(V2.Value.AsBoolean));
end;

function Comp_DateTime_Single(const V1, V2: PQValue): Integer;
begin
  Result := Comp_Float_Zero(V1.Value.AsFloat - V2.Value.AsSingle);
end;

function Comp_DateTime_Float(const V1, V2: PQValue): Integer;
begin
  Result := Comp_Float_Zero(V1.Value.AsFloat - V2.Value.AsFloat);
end;

function Comp_DateTime_Currency(const V1, V2: PQValue): Integer;
begin
  Result := Comp_Float_Zero(V1.Value.AsFloat - V2.Value.AsCurrency);
end;

function Comp_DateTime_Int(const V1, V2: PQValue): Integer;
begin
  Result := Comp_Float_Zero(V1.Value.AsFloat - V2.Value.AsInteger);
end;

function Comp_DateTime_Int64(const V1, V2: PQValue): Integer;
begin
  Result := Comp_Float_Zero(V1.Value.AsFloat - V2.Value.AsInt64);
end;

function Comp_DateTime_Bcd(const V1, V2: PQValue): Integer;
begin
  Result := BcdCompare(DoubleToBcd(V1.Value.AsFloat), V2.Value.AsBcd^);
end;

function Comp_DateTime_DateTime(const V1, V2: PQValue): Integer;
begin
  Result := Comp_Float_Zero(V1.Value.AsFloat - V2.Value.AsFloat);
end;

function Comp_DateTime_String(const V1, V2: PQValue): Integer;
var
  T: TDateTime;
begin
  if ParseDateTime(PQCharW(V2.Value.AsString^), T) or
    ParseWebTime(PQCharW(V2.Value.AsString^), T) or
    TryStrToDateTime(V2.Value.AsString^, T) then
    Result := Comp_Float_Zero(V1.Value.AsFloat - T)
  else
    raise EConvertError.CreateFmt(SConvertError,
      [V2.Value.AsString^, 'TDateTime']);
end;

/// Interval
function Comp_Interval_Interval(const V1, V2: PQValue): Integer;
begin
  Result := TQInterval.Compare(V1.Value.AsInterval, V2.Value.AsInterval);
end;

function Comp_Interval_String(const V1, V2: PQValue): Integer;
var
  T: TQInterval;
begin
  if T.TryFromString(V2.Value.AsString^) then
    Result := TQInterval.Compare(V1.Value.AsInterval, V2.Value.AsInterval)
  else
    raise EConvertError.CreateFmt(SConvertError,
      [V2.Value.AsString^, 'TDateTime']);
end;

/// String

function Comp_String_Bool(const V1, V2: PQValue): Integer;
begin
  Result := -Comp_Bool_String(V2, V1);
end;

function Comp_String_Single(const V1, V2: PQValue): Integer;
var
  V: Single;
begin
  if TryStrToFloat(V1.Value.AsString^, V) then
    Result := Comp_Float_Zero(V - V2.Value.AsSingle)
  else
    raise EConvertError.CreateFmt(SConvertError,
      [V1.Value.AsString^, 'Single']);
end;

function Comp_String_Float(const V1, V2: PQValue): Integer;
begin
  Result := -Comp_Float_String(V2, V1);
end;

function Comp_String_Currency(const V1, V2: PQValue): Integer;
var
  T: Currency;
begin
  if TryStrToCurr(V1.Value.AsString^, T) then
    Result := PInt64(@T)^ - V2.Value.AsInt64
  else
    raise EConvertError.CreateFmt(SConvertError,
      [V1.Value.AsString^, 'Currency']);
end;

function Comp_String_Int(const V1, V2: PQValue): Integer;
begin
  Result := -Comp_Int_String(V2, V1);
end;

function Comp_String_Int64(const V1, V2: PQValue): Integer;
begin
  Result := -Comp_Int64_String(V2, V1);
end;

function Comp_String_Bcd(const V1, V2: PQValue): Integer;
begin
  Result := -Comp_Bcd_String(V2, V1);
end;

function Comp_String_Guid(const V1, V2: PQValue): Integer;
begin
  Result := -Comp_Guid_String(V2, V1);
end;

function Comp_String_DateTime(const V1, V2: PQValue): Integer;
begin
  Result := -Comp_DateTime_String(V2, V1);
end;

function Comp_String_Interval(const V1, V2: PQValue): Integer;
begin
  Result := -Comp_Interval_String(V2, V1);
end;

function Comp_String_String(const V1, V2: PQValue): Integer;
begin
  Result := StrCmpW(PQCharW(V1.Value.AsString^),
    PQCharW(V2.Value.AsString^), false);
end;

function Comp_String_String_IC(const V1, V2: PQValue): Integer;
begin
  Result := StrCmpW(PQCharW(V1.Value.AsString^),
    PQCharW(V2.Value.AsString^), True);
end;

function Comp_String_String_Natural(const V1, V2: PQValue): Integer;
begin
  Result := NaturalCompareW(PQCharW(V1.Value.AsString^),
    PQCharW(V2.Value.AsString^), false);
end;

function Comp_String_String_NaturalIC(const V1, V2: PQValue): Integer;
begin
  Result := NaturalCompareW(PQCharW(V1.Value.AsString^),
    PQCharW(V2.Value.AsString^), True);
end;

/// Stream vs Stream
function Comp_Stream_Stream(const V1, V2: PQValue): Integer;
var
  L1, L2: Int64;
  S1, S2: TQValueStream;
begin
  S1 := V1.Value.AsStream;
  S2 := V2.Value.AsStream;
  L1 := S1.Size;
  L2 := S2.Size;
  if L1 < L2 then
  begin
    Result := BinaryCmp(S1.Memory, S2.Memory, L1);
    if Result = 0 then
      Result := -1;
  end
  else if L1 > L2 then
  begin
    Result := BinaryCmp(S1.Memory, S2.Memory, L2);
    if Result = 0 then
      Result := 1;
  end
  else
    Result := BinaryCmp(S1.Memory, S2.Memory, L2);
end;

function LookupCompareProc(ADataType1, ADataType2: TQValueDataType;
  AIgnoreCase, ANaturalCompare: Boolean): TQValueCompare;
begin
  Result := nil;
  case ADataType1 of
    vdtString:
      case ADataType2 of
        vdtString:
          begin
            if AIgnoreCase then
            begin
              if ANaturalCompare then
                Result := Comp_String_String_NaturalIC
              else
                Result := Comp_String_String_IC
            end
            else
            begin
              if ANaturalCompare then
                Result := Comp_String_String_Natural
              else
                Result := Comp_String_String;
            end;
          end;
        vdtInteger:
          Result := Comp_String_Int;
        vdtBoolean:
          Result := Comp_String_Bool;
        vdtSingle:
          Result := Comp_String_Single;
        vdtFloat:
          Result := Comp_String_Float;
        vdtCurrency:
          Result := Comp_String_Currency;
        vdtBcd:
          Result := Comp_String_Bcd;
        vdtDateTime:
          Result := Comp_String_DateTime;
        vdtInt64:
          Result := Comp_String_Int64;
        vdtGuid:
          Result := Comp_String_Guid;
        vdtInterval:
          Result := Comp_String_Interval;
      end;
    vdtInteger:
      case ADataType2 of
        vdtString:
          Result := Comp_Int_String;
        vdtInteger:
          Result := Comp_Int_Int;
        vdtBoolean:
          Result := Comp_Int_Bool;
        vdtSingle:
          Result := Comp_Int_Single;
        vdtFloat:
          Result := Comp_Int_Float;
        vdtCurrency:
          Result := Comp_Int_Currency;
        vdtBcd:
          Result := Comp_Int_Bcd;
        vdtDateTime:
          Result := Comp_Int_DateTime;
        vdtInt64:
          Result := Comp_Int_Int64;
      end;
    vdtBoolean:
      case ADataType2 of
        vdtString:
          Result := Comp_Bool_String;
        vdtInteger:
          Result := Comp_Bool_Int;
        vdtBoolean:
          Result := Comp_Bool_Bool;
        vdtSingle:
          Result := Comp_Bool_Single;
        vdtFloat:
          Result := Comp_Bool_Float;
        vdtCurrency:
          Result := Comp_Bool_Currency;
        vdtBcd:
          Result := Comp_Bool_Bcd;
        vdtDateTime:
          Result := Comp_Bool_DateTime;
        vdtInt64:
          Result := Comp_Bool_Int64;
      end;
    vdtSingle:
      case ADataType2 of
        vdtString:
          Result := Comp_Single_String;
        vdtInteger:
          Result := Comp_Single_Int;
        vdtBoolean:
          Result := Comp_Single_Bool;
        vdtSingle:
          Result := Comp_Single_Single;
        vdtFloat:
          Result := Comp_Single_Float;
        vdtCurrency:
          Result := Comp_Single_Currency;
        vdtBcd:
          Result := Comp_Single_Bcd;
        vdtDateTime:
          Result := Comp_Single_DateTime;
        vdtInt64:
          Result := Comp_Single_Int64;
      end;
    vdtFloat:
      case ADataType2 of
        vdtString:
          Result := Comp_Float_String;
        vdtInteger:
          Result := Comp_Float_Int;
        vdtBoolean:
          Result := Comp_Float_Bool;
        vdtSingle:
          Result := Comp_Float_Single;
        vdtFloat:
          Result := Comp_Float_Float;
        vdtCurrency:
          Result := Comp_Float_Currency;
        vdtBcd:
          Result := Comp_Float_Bcd;
        vdtDateTime:
          Result := Comp_Float_DateTime;
        vdtInt64:
          Result := Comp_Float_Int64;
      end;
    vdtCurrency:
      case ADataType2 of
        vdtString:
          Result := Comp_Currency_String;
        vdtInteger:
          Result := Comp_Currency_Int;
        vdtBoolean:
          Result := Comp_Currency_Bool;
        vdtSingle:
          Result := Comp_Currency_Single;
        vdtFloat:
          Result := Comp_Currency_Float;
        vdtCurrency:
          Result := Comp_Currency_Currency;
        vdtBcd:
          Result := Comp_Currency_Bcd;
        vdtDateTime:
          Result := Comp_Currency_DateTime;
        vdtInt64:
          Result := Comp_Currency_Int64;
      end;
    vdtInt64:
      case ADataType2 of
        vdtString:
          Result := Comp_Int64_String;
        vdtInteger:
          Result := Comp_Int64_Int;
        vdtBoolean:
          Result := Comp_Int64_Bool;
        vdtSingle:
          Result := Comp_Int64_Single;
        vdtFloat:
          Result := Comp_Int64_Float;
        vdtCurrency:
          Result := Comp_Int64_Currency;
        vdtBcd:
          Result := Comp_Int64_Bcd;
        vdtDateTime:
          Result := Comp_Int64_DateTime;
        vdtInt64:
          Result := Comp_Int64_Int64;
      end;
    vdtBcd:
      case ADataType2 of
        vdtString:
          Result := Comp_Bcd_String;
        vdtInteger:
          Result := Comp_Bcd_Int;
        vdtBoolean:
          Result := Comp_Bcd_Bool;
        vdtSingle:
          Result := Comp_Bcd_Single;
        vdtFloat:
          Result := Comp_Bcd_Float;
        vdtCurrency:
          Result := Comp_Bcd_Currency;
        vdtBcd:
          Result := Comp_Bcd_Bcd;
        vdtDateTime:
          Result := Comp_Bcd_DateTime;
        vdtInt64:
          Result := Comp_Bcd_Int64;
      end;
    vdtDateTime:
      case ADataType2 of
        vdtString:
          Result := Comp_DateTime_String;
        vdtInteger:
          Result := Comp_DateTime_Int;
        vdtBoolean:
          Result := Comp_DateTime_Bool;
        vdtSingle:
          Result := Comp_DateTime_Single;
        vdtFloat:
          Result := Comp_DateTime_Float;
        vdtCurrency:
          Result := Comp_DateTime_Currency;
        vdtBcd:
          Result := Comp_DateTime_Bcd;
        vdtDateTime:
          Result := Comp_DateTime_DateTime;
        vdtInt64:
          Result := Comp_DateTime_Int64;
      end;
    vdtGuid:
      case ADataType2 of
        vdtString:
          Result := Comp_Guid_String;
        vdtGuid:
          Result := Comp_Guid_Guid;
      end;
    vdtInterval:
      case ADataType2 of
        vdtString:
          Result := Comp_Interval_String;
        vdtInterval:
          Result := Comp_Interval_Interval;
      end;
    vdtStream:
      case ADataType2 of
        vdtStream:
          Result := Comp_Stream_Stream;
      end;
  end;
end;
{ TQValueHelper }

function TQValueHelper.ArrayNeeded(ALen: Integer): PQValue;
begin
  Result := TypeNeeded(vdtArray);
  if ALen > 0 then
  begin
    if Value.Size = 0 then
    begin
      GetMem(Value.Items, SizeOf(TQValue) * ALen);
      Value.Size := ALen;
    end
    else
    begin
      if Cardinal(ALen) > Value.Size then
      begin
        ReallocMem(Value.Items, SizeOf(TQValue) * ALen);
        Value.Size := ALen;
      end
      else
      begin
        while Value.Size > Cardinal(ALen) do
        begin
          Items[Value.Size - 1].Reset;
          Dec(Value.Size);
        end;
      end;
    end;
  end;
end;

procedure TQValueHelper.Copy(const ASource: TQValue; AStrict: Boolean);
  procedure CopyArray;
  var
    I: Cardinal;
  begin
    if not AStrict then
      ArrayNeeded(ASource.Value.Size);
    I := 0;
    while I < ASource.Value.Size do
    begin
      Items[I].Copy(ASource.Items[I]^, AStrict);
      Inc(I);
    end;
  end;
  procedure ToStream;
  var
    ABytes: TBytes;
    AStream: TQValueStream;
  begin
    AStream := Value.AsStream;
    AStream.Position := 0;
    if ASource.ValueType = vdtStream then
      AStream.CopyFrom(ASource.Value.AsStream, 0)
    else
    begin
      ABytes := ASource.AsBytes;
      AStream.Write(ABytes[0], Length(ABytes));
      AStream.Size := AStream.Position;
    end;
  end;

begin
  if AStrict then
  begin
    case ValueType of
      vdtUnset, vdtNull:
        begin
          if not ASource.IsNull then
            raise Exception.CreateFmt(SConvertError,
              [ASource.AsString, QValueTypeName[vdtNull]]);
        end;
      vdtBoolean:
        Value.AsBoolean := ASource.AsBoolean;
      vdtSingle:
        Value.AsSingle := ASource.AsSingle;
      vdtFloat:
        Value.AsFloat := ASource.AsFloat;
      vdtInteger:
        Value.AsInteger := ASource.AsInteger;
      vdtInt64:
        Value.AsInt64 := ASource.AsInt64;
      vdtCurrency:
        Value.AsCurrency := ASource.AsCurrency;
      vdtBcd:
        Value.AsBcd^ := ASource.AsBcd;
      vdtGuid:
        Value.AsGuid^ := ASource.AsGuid;
      vdtDateTime:
        Value.AsDateTime := ASource.AsDateTime;
      vdtInterval:
        Value.AsInterval := ASource.AsInterval;
      vdtString:
        Value.AsString^ := ASource.AsString;
      vdtStream:
        ToStream;
      vdtArray:
        if ASource.ValueType = vdtArray then
        begin
          if ASource.Value.Size <> Value.Size then
            raise Exception.CreateFmt(SConvertError,
              [ASource.AsString, QValueTypeName[vdtArray]])
          else
            CopyArray;
        end
        else
          raise Exception.CreateFmt(SConvertError,
            [ASource.AsString, QValueTypeName[vdtArray]]);
    end;
  end
  else
  begin
    TypeNeeded(ASource.ValueType);
    case ASource.ValueType of
      vdtUnset, vdtNull:
        ;
      vdtBoolean:
        Value.AsBoolean := ASource.Value.AsBoolean;
      vdtSingle:
        Value.AsSingle := ASource.Value.AsSingle;
      vdtFloat:
        Value.AsFloat := ASource.Value.AsFloat;
      vdtInteger:
        Value.AsInteger := ASource.Value.AsInteger;
      vdtInt64, vdtCurrency:
        Value.AsInt64 := ASource.Value.AsInt64;
      vdtBcd:
        Value.AsBcd^ := ASource.Value.AsBcd^;
      vdtGuid:
        Value.AsGuid^ := ASource.Value.AsGuid^;
      vdtDateTime:
        Value.AsDateTime := ASource.Value.AsDateTime;
      vdtInterval:
        Value.AsInterval := ASource.Value.AsInterval;
      vdtString:
        Value.AsString^ := ASource.Value.AsString^;
      vdtStream:
        begin
          TQValueStream(Value.AsStream).Size :=
            TQValueStream(ASource.Value.AsStream).Size;
          Move(TQValueStream(ASource.Value.AsStream).Memory^,
            TQValueStream(Value.AsStream).Memory^,
            TQValueStream(ASource.Value.AsStream).Size);
        end;
      vdtArray:
        CopyArray;
    end;
  end;
end;

procedure TQValueHelper.From(const V: Variant);
begin

end;

function TQValueHelper.GetAsBcd: TBcd;
begin
  case ValueType of
    vdtBcd:
      Result := Value.AsBcd^;
    vdtUnset, vdtNull:
      FillChar(Result, SizeOf(TBcd), 0);
    vdtBoolean:
      Result := IntegerToBcd(Integer(Value.AsBoolean));
    vdtSingle:
      Result := DoubleToBcd(Value.AsSingle);
    vdtFloat:
      Result := DoubleToBcd(Value.AsFloat);
    vdtInteger:
      Result := IntegerToBcd(Value.AsInteger);
    vdtInt64:
      Result := StrToBcd(IntToStr(Value.AsInt64));
    vdtCurrency:
      CurrToBcd(Value.AsCurrency, Result);
    vdtDateTime:
      Result := DoubleToBcd(Value.AsFloat);
    vdtString:
      Result := StrToBcd(Value.AsString^)
  else
    raise EConvertError.CreateFmt(SConvertError, [QValueTypeName[ValueType],
      QValueTypeName[vdtBcd]]);
  end;
end;

function TQValueHelper.GetAsBoolean: Boolean;
begin
  case ValueType of
    vdtBoolean:
      Result := Value.AsBoolean;
    vdtUnset, vdtNull:
      Result := false;
    vdtSingle:
      Result := not IsZero(Value.AsSingle);
    vdtFloat:
      Result := not IsZero(Value.AsFloat);
    vdtInteger:
      Result := Value.AsInteger <> 0;
    vdtInt64, vdtCurrency:
      Result := Value.AsInt64 <> 0;
    vdtBcd:
      Result := BcdCompare(Value.AsBcd^, NullBcd) <> 0;
    vdtDateTime:
      Result := not IsZero(Value.AsFloat);
    vdtString:
      Result := StrToBool(Value.AsString^);
  else
    raise EConvertError.CreateFmt(SConvertError, [QValueTypeName[ValueType],
      QValueTypeName[vdtBoolean]]);
  end;
end;

function TQValueHelper.GetAsBytes: TBytes;

  procedure EncodeBytes(AMsgPack: TQMsgPack; const AParent: PQValue);
  var
    I: Cardinal;
    AItem: PQValue;
  begin
    AMsgPack.DataType := mptArray;
    I := 0;
    while I < AParent.Value.Size do
    begin
      AItem := AParent.Items[I];
      case AItem.ValueType of
        vdtUnset, vdtNull:
          AMsgPack.Add;
        vdtBoolean:
          AMsgPack.Add.AsBoolean := AItem.Value.AsBoolean;
        vdtSingle:
          AMsgPack.Add.AsSingle := AItem.Value.AsSingle;
        vdtFloat:
          AMsgPack.Add.AsFloat := AItem.Value.AsFloat;
        vdtInteger:
          AMsgPack.Add.AsInteger := AItem.Value.AsInteger;
        vdtInt64:
          AMsgPack.Add.AsInt64 := AItem.Value.AsInt64;
        vdtCurrency:
          AMsgPack.Add.AsFloat := AItem.Value.AsCurrency;
        vdtBcd:
          AMsgPack.Add.AsFloat := BcdToDouble(AItem.Value.AsBcd^);
        vdtGuid:
          AMsgPack.Add.AsString := GuidToString(AItem.Value.AsGuid^);
        vdtDateTime:
          AMsgPack.Add.AsDateTime := AItem.AsDateTime;
        vdtInterval:
          AMsgPack.Add.AsString := AItem.Value.AsInterval.AsString;
        vdtString:
          AMsgPack.Add.AsString := AItem.Value.AsString^;
        vdtStream:
          AMsgPack.Add.ValueFromStream(AItem.Value.AsStream, 0);
        vdtArray:
          EncodeBytes(AMsgPack.Add, AItem);
      end;
      Inc(I);
    end;
  end;
  procedure ArrayToBytes;
  var
    AMsgPack: TQMsgPack;
  begin
    AMsgPack := TQMsgPack.Create;
    try
      EncodeBytes(AMsgPack, @Self);
      Result := AMsgPack.Encode;
    finally
      FreeObject(AMsgPack);
    end;
  end;

begin
  case ValueType of
    vdtUnset, vdtNull:
      SetLength(Result, 0);
    vdtBoolean:
      begin
        SetLength(Result, 1);
        Result[0] := Integer(Value.AsBoolean);
      end;
    vdtFloat, vdtDateTime, vdtInt64, vdtCurrency, vdtInterval: // 8B
      begin
        SetLength(Result, SizeOf(Double));
        PInt64(@Result[0])^ := Value.AsInt64;
      end;
    vdtSingle, vdtInteger: // 4B
      begin
        SetLength(Result, SizeOf(Integer));
        PInteger(@Result[0])^ := Value.AsInteger;
      end;
    vdtBcd:
      begin
        SetLength(Result, SizeOf(TBcd));
        PBcd(@Result[0])^ := Value.AsBcd^;
      end;
    vdtGuid:
      begin
        SetLength(Result, SizeOf(TGuid));
        PGuid(@Result[0])^ := Value.AsGuid^;
      end;
    vdtString:
      Result := qstring.Utf8Encode(Value.AsString^);
    vdtStream:
      begin
        SetLength(Result, TQValueStream(Value.AsStream).Size);
        Move(TQValueStream(Value.AsStream).Memory^, Result[0], Length(Result));
      end;
    vdtArray: // Array as bytes
      ArrayToBytes;
  end;
end;

function TQValueHelper.GetAsCurrency: Currency;
begin
  case ValueType of
    vdtCurrency:
      Result := Value.AsCurrency;
    vdtUnset, vdtNull:
      Result := 0;
    vdtBoolean:
      Result := Integer(Value.AsBoolean);
    vdtSingle:
      Result := Value.AsSingle;
    vdtFloat, vdtDateTime:
      Result := Value.AsFloat;
    vdtInteger:
      Result := Value.AsInteger;
    vdtInt64:
      Result := Value.AsInt64;
    vdtBcd:
      Result := BcdToDouble(Value.AsBcd^);
    vdtString:
      Result := StrToCurr(Value.AsString^);
  else
    raise EConvertError.CreateFmt(SConvertError, [QValueTypeName[ValueType],
      QValueTypeName[vdtCurrency]]);
  end;
end;

function TQValueHelper.GetAsDateTime: TDateTime;
  procedure StrToDT;
  var
    S: QStringW;
  begin
    S := Value.AsString^;
    if TryStrToDateTime(S, Result) or ParseDateTime(PQCharW(S), Result) or
      ParseWebTime(PQCharW(S), Result) then
      Exit;
    raise EConvertError.CreateFmt(SConvertError, [QValueTypeName[ValueType],
      QValueTypeName[vdtDateTime]]);
  end;

begin
  case ValueType of
    vdtUnset, vdtNull:
      Result := 0;
    vdtBoolean:
      Result := Integer(0);
    vdtSingle:
      Result := Value.AsSingle;
    vdtFloat:
      Result := Value.AsFloat;
    vdtInteger:
      Result := Value.AsInteger;
    vdtInt64:
      Result := Value.AsInt64;
    vdtCurrency:
      Result := Value.AsCurrency;
    vdtBcd:
      Result := BcdToDouble(Value.AsBcd^);
    vdtDateTime:
      Result := Value.AsDateTime;
    vdtString:
      StrToDT;
  else
    raise EConvertError.CreateFmt(SConvertError, [QValueTypeName[ValueType],
      QValueTypeName[vdtDateTime]]);
  end;
end;

function TQValueHelper.GetAsFloat: Double;
begin
  case ValueType of
    vdtFloat, vdtDateTime:
      Result := Value.AsFloat;
    vdtSingle:
      Result := Value.AsSingle;
    vdtUnset, vdtNull:
      Result := 0;
    vdtBoolean:
      Result := Integer(Value.AsBoolean);
    vdtInteger:
      Result := Value.AsInteger;
    vdtInt64:
      Result := Value.AsInt64;
    vdtCurrency:
      Result := Value.AsCurrency;
    vdtBcd:
      Result := BcdToDouble(Value.AsBcd^);
    vdtString:
      Result := StrToFloat(Value.AsString^)
  else
    raise EConvertError.CreateFmt(SConvertError, [QValueTypeName[ValueType],
      QValueTypeName[vdtFloat]]);
  end;
end;

function TQValueHelper.GetAsGuid: TGuid;
begin
  if ValueType = vdtGuid then
    Result := Value.AsGuid^
  else
  begin
    if ValueType = vdtString then
    begin
      if TryStrToGuid(Value.AsString^, Result) then
        Exit;
    end;
    raise EConvertError.CreateFmt(SConvertError, [QValueTypeName[ValueType],
      QValueTypeName[vdtGuid]]);
  end;
end;

function TQValueHelper.GetAsInt64: Int64;
begin
  case ValueType of
    vdtInt64:
      Result := Value.AsInt64;
    vdtInteger:
      Result := Value.AsInteger;
    vdtUnset, vdtNull:
      Result := 0;
    vdtBoolean:
      Result := Integer(Value.AsBoolean);
    vdtSingle:
      Result := Trunc(Value.AsSingle);
    vdtFloat, vdtDateTime:
      Result := Trunc(Value.AsFloat);
    vdtCurrency:
      Result := Value.AsInt64 div 10000;
    vdtBcd:
      Result := BcdToInt64(Value.AsBcd^);
    vdtString:
      Result := StrToInt64(Value.AsString^)
  else
    raise EConvertError.CreateFmt(SConvertError, [QValueTypeName[ValueType],
      QValueTypeName[vdtInt64]]);
  end;
end;

function TQValueHelper.GetAsInteger: Integer;
begin
  case ValueType of
    vdtInteger:
      Result := Value.AsInteger;
    vdtInt64:
      Result := Value.AsInt64;
    vdtUnset, vdtNull:
      Result := 0;
    vdtBoolean:
      Result := Integer(Value.AsBoolean);
    vdtSingle:
      Result := Trunc(Value.AsSingle);
    vdtFloat, vdtDateTime:
      Result := Trunc(Value.AsFloat);
    vdtCurrency:
      Result := Value.AsInt64 div 10000;
    vdtBcd:
      Result := BcdToInt64(Value.AsBcd^);
    vdtString:
      Result := StrToInt64(Value.AsString^)
  else
    raise EConvertError.CreateFmt(SConvertError, [QValueTypeName[ValueType],
      QValueTypeName[vdtInt64]]);
  end;
end;

function TQValueHelper.GetAsInterval: TQInterval;
begin
  if ValueType = vdtInterval then
    Result := Value.AsInterval
  else
  begin
    if ValueType = vdtString then
    begin
      if Result.TryFromString(Value.AsString^) then
        Exit;
    end;
    raise EConvertError.CreateFmt(SConvertError, [QValueTypeName[ValueType],
      QValueTypeName[vdtInterval]]);
  end;
end;

function TQValueHelper.GetAsSingle: Single;
begin
  case ValueType of
    vdtSingle:
      Result := Value.AsSingle;
    vdtFloat, vdtDateTime:
      Result := Value.AsFloat;
    vdtUnset, vdtNull:
      Result := 0;
    vdtBoolean:
      Result := Integer(Value.AsBoolean);
    vdtInteger:
      Result := Value.AsInteger;
    vdtInt64:
      Result := Value.AsInt64;
    vdtCurrency:
      Result := Value.AsCurrency;
    vdtBcd:
      Result := BcdToDouble(Value.AsBcd^);
    vdtString:
      Result := StrToFloat(Value.AsString^)
  else
    raise EConvertError.CreateFmt(SConvertError, [QValueTypeName[ValueType],
      QValueTypeName[vdtSingle]]);
  end;
end;

function TQValueHelper.GetAsStream: TQValueStream;
begin
  if ValueType = vdtStream then
    Result := Value.AsStream
  else
    raise EConvertError.CreateFmt(SConvertError, [QValueTypeName[ValueType],
      QValueTypeName[vdtStream]]);
end;

function TQValueHelper.GetAsString: QStringW;
  function DTToStr(Value: TQValueData): QStringW;
  begin
    if Trunc(Value.AsFloat) = 0 then
      Result := FormatDateTime({$IF RTLVersion>=22} FormatSettings.{$IFEND}LongTimeFormat, Value.AsDateTime)
    else if IsZero(Value.AsFloat - Trunc(Value.AsFloat)) then
      Result := FormatDateTime
        ({$IF RTLVersion>=22}FormatSettings.{$IFEND}LongDateFormat,
        Value.AsDateTime)
    else
      Result := FormatDateTime
        ({$IF RTLVersion>=22}FormatSettings.{$IFEND}LongDateFormat + ' ' +
{$IF RTLVersion>=22}FormatSettings.{$IFEND}LongTimeFormat, Value.AsDateTime);
  end;
  procedure CatStr(ABuilder: TQStringCatHelperW; const AValue: QStringW);
  var
    ps: PQCharW;
  const
    CharNum1: PWideChar = '1';
    CharNum0: PWideChar = '0';
    Char7: PWideChar = '\b';
    Char9: PWideChar = '\t';
    Char10: PWideChar = '\n';
    Char12: PWideChar = '\f';
    Char13: PWideChar = '\r';
    CharQuoter: PWideChar = '\"';
    CharBackslash: PWideChar = '\\';
    CharCode: PWideChar = '\u00';
  begin
    ps := PQCharW(AValue);
    while ps^ <> #0 do
    begin
      case ps^ of
        #7:
          ABuilder.Cat(Char7, 2);
        #9:
          ABuilder.Cat(Char9, 2);
        #10:
          ABuilder.Cat(Char10, 2);
        #12:
          ABuilder.Cat(Char12, 2);
        #13:
          ABuilder.Cat(Char13, 2);
        '\':
          ABuilder.Cat(CharBackslash, 2);
        '"':
          ABuilder.Cat(CharQuoter, 2);
      else
        begin
          if ps^ < #$1F then
          begin
            ABuilder.Cat(CharCode, 4);
            if ps^ > #$F then
              ABuilder.Cat(CharNum1, 1)
            else
              ABuilder.Cat(CharNum0, 1);
            ABuilder.Cat(HexChar(Ord(ps^) and $0F));
          end
          else
            ABuilder.Cat(ps, 1);
        end;
      end;
      Inc(ps);
    end;
  end;
  procedure ArrToStrHelper(const ABuilder: TQStringCatHelperW;
    const AParent: TQValue);
  var
    I: Cardinal;
    AItem: PQValue;
  const
    ArrayStart: PWideChar = '[';
    ArrayStop: PWideChar = ']';
    StrStart: PWideChar = '"';
    StrStop: PWideChar = '"';
    StrNull: PWideChar = 'null';
    StrTrue: PWideChar = 'true';
    StrFalse: PWideChar = 'false';
    StrComma: PWideChar = ',';
  begin
    I := 0;
    ABuilder.Cat(ArrayStart);
    while I < AParent.Value.Size do
    begin
      AItem := AParent.Items[I];
      case AItem.ValueType of
        vdtUnset, vdtNull:
          ABuilder.Cat(StrNull, 4);
        vdtBoolean:
          begin
            if AItem.Value.AsBoolean then
              ABuilder.Cat(StrTrue, 4)
            else
              ABuilder.Cat(StrFalse, 5);
          end;
        vdtSingle:
          ABuilder.Cat(FloatToStr(AItem.Value.AsSingle));
        vdtFloat:
          ABuilder.Cat(FloatToStr(AItem.Value.AsFloat));
        vdtInteger:
          ABuilder.Cat(AItem.Value.AsInteger);
        vdtInt64:
          ABuilder.Cat(AItem.Value.AsInt64);
        vdtCurrency:
          ABuilder.Cat(CurrToStr(AItem.Value.AsCurrency));
        vdtBcd:
          ABuilder.Cat(BcdToStr(AItem.Value.AsBcd^));
        vdtGuid:
          ABuilder.Cat(StrStart).Cat(AItem.Value.AsGuid^).Cat(StrStop);
        vdtDateTime:
          ABuilder.Cat(StrStart).Cat(DTToStr(AItem.Value)).Cat(StrStop);
        vdtInterval:
          ABuilder.Cat(StrStart).Cat(AItem.Value.AsInterval.AsString)
            .Cat(StrStop);
        vdtString:
          begin
            ABuilder.Cat(StrStart);
            CatStr(ABuilder, AItem.Value.AsString^);
            ABuilder.Cat(StrStop);
          end;
        vdtStream:
          ABuilder.Cat(StrStart)
            .Cat(BinToHex(TQValueStream(AItem.Value.AsStream).Memory,
            TQValueStream(Value.AsStream).Size)).Cat(StrStop);
        vdtArray:
          ArrToStrHelper(ABuilder, AItem^);
      end;
      Inc(I);
      if I < AParent.Value.Size then
        ABuilder.Cat(StrComma);
    end;
    ABuilder.Cat(ArrayStop);
  end;
  procedure ArrToStr;
  var
    ABuilder: TQStringCatHelperW;
  begin
    ABuilder := TQStringCatHelperW.Create;
    try
      ArrToStrHelper(ABuilder, Self);
      Result := ABuilder.Value;
    finally
      FreeObject(ABuilder);
    end;
  end;

begin
  case ValueType of
    vdtString:
      Result := Value.AsString^;
    vdtUnset:
      Result := 'default';
    vdtNull:
      Result := 'null';
    vdtBoolean:
      Result := BoolToStr(Value.AsBoolean, True);
    vdtSingle:
      Result := FloatToStr(Value.AsSingle);
    vdtFloat:
      Result := FloatToStr(Value.AsFloat);
    vdtInteger:
      Result := IntToStr(Value.AsInteger);
    vdtInt64:
      Result := IntToStr(Value.AsInt64);
    vdtCurrency:
      Result := CurrToStr(Value.AsCurrency);
    vdtBcd:
      Result := BcdToStr(Value.AsBcd^);
    vdtGuid:
      Result := GuidToString(Value.AsGuid^);
    vdtDateTime:
      Result := DTToStr(Value);
    vdtInterval:
      Result := Value.AsInterval.AsString;
    vdtStream:
      Result := BinToHex(TQValueStream(Value.AsStream).Memory,
        TQValueStream(Value.AsStream).Size);
    vdtArray:
      ArrToStr;
  end;
end;

function TQValueHelper.GetAsVariant: Variant;
var
  I: Integer;
  procedure ByteAsVariant;
  var
    L: Integer;
    p: PByte;
  begin
    L := TQValueStream(Value.AsStream).Size;
    Result := VarArrayCreate([0, L - 1], varByte);
    p := VarArrayLock(Result);
    Move(TQValueStream(Value.AsStream).Memory^, p^, L);
    VarArrayUnlock(Result);
  end;

begin
  case ValueType of
    vdtUnset:
      Result := Unassigned;
    vdtNull:
      Result := Null;
    vdtBoolean:
      Result := Value.AsBoolean;
    vdtSingle:
      Result := Value.AsSingle;
    vdtFloat:
      Result := Value.AsFloat;
    vdtInteger:
      Result := Value.AsInteger;
    vdtInt64:
      Result := Value.AsInt64;
    vdtCurrency:
      Result := Value.AsCurrency;
    vdtBcd:
      Result := BcdToDouble(Value.AsBcd^);
    vdtGuid:
      Result := GuidToString(Value.AsGuid^);
    vdtDateTime:
      Result := Value.AsDateTime;
    vdtInterval:
      Result := Value.AsInterval.AsString;
    vdtString:
      Result := Value.AsString^;
    vdtStream:
      ByteAsVariant;
    vdtArray:
      begin
        Result := VarArrayCreate([0, Value.Size - 1], varVariant);
        for I := 0 to Value.Size - 1 do
          Result[I] := Items[I].AsVariant;
      end
  else
    VarClear(Result);
  end;
end;

function TQValueHelper.GetCount: Integer;
begin
  if ValueType = vdtArray then
    Result := Value.Size
  else
    Result := 0;
end;

function TQValueHelper.GetIsNull: Boolean;
begin
  Result := ValueType in [vdtNull, vdtUnset];
end;

function TQValueHelper.GetItems(AIndex: Integer): PQValue;
begin
  if ValueType = vdtArray then
    Result := PQValue(IntPtr(Value.Items) + SizeOf(TQValue) * AIndex)
  else
    raise Exception.Create(SValueNotArray);
end;

function TQValueHelper.GetSize: Integer;
var
  I: Integer;
begin
  Result := 0;
  case ValueType of
    vdtBoolean:
      Result := 1;
    vdtSingle:
      Result := SizeOf(Single);
    vdtFloat:
      Result := SizeOf(Double);
    vdtInteger:
      Result := SizeOf(Integer);
    vdtInt64:
      Result := SizeOf(Int64);
    vdtCurrency:
      Result := SizeOf(Currency);
    vdtBcd:
      Result := SizeOf(TBcd);
    vdtGuid:
      Result := SizeOf(TGuid);
    vdtDateTime:
      Result := SizeOf(TDateTime);
    vdtInterval:
      Result := SizeOf(TQInterval);
    vdtString:
      Result := Length(Value.AsString^) shl 1;
    vdtStream:
      Result := TQValueStream(Value.AsStream).Size;
    vdtArray:
      begin
        Result := 0;
        for I := 0 to Value.Size - 1 do
          Inc(Result, Items[I].Size);
      end;
  end;
end;

function TQValueHelper.IsEqual(const AValue: TQValue): Boolean;
var
  AProc: TQValueCompare;
begin
  AProc := LookupCompareProc(ValueType, AValue.ValueType, false, false);
  if Assigned(AProc) then
    Result := AProc(@Self, @AValue) = 0
  else // Null Compare
    Result := (ValueType = AValue.ValueType);
end;

procedure TQValueHelper.LoadFromFile(const AFileName: String);
var
  AStream: TMemoryStream;
begin
  AStream := TMemoryStream.Create;
  try
    AStream.LoadFromFile(AFileName);
    LoadFromStream(AStream);
  finally
    FreeAndNil(AStream);
  end;
end;

procedure TQValueHelper.LoadFromStream(AStream: TStream);
var
  AType: Byte;
  S: QStringA;
  L: Int64;

  procedure ReadArray(ASize: Cardinal);
  var
    I: Cardinal;
  begin
    ArrayNeeded(ASize);
    for I := 0 to ASize - 1 do
      Items[I].LoadFromStream(AStream);
  end;

begin
  AStream.ReadBuffer(AType, SizeOf(AType));
  if AType in [0 .. 127] then
  begin
    TypeNeeded(vdtInteger);
    Value.AsInteger := AType;
  end
  else if (AType >= TYPE_INT4) and (AType <= TYPE_INT4 + $0F) then
  begin
    TypeNeeded(vdtInteger);
    Value.AsInteger := Shortint((AType and $0F) or $F0);
  end
  else if (AType >= TYPE_ARRAY4) and (AType <= TYPE_ARRAY4 + $0F) then
  // 0..15 Array
  begin
    TypeNeeded(vdtArray);
    ReadArray(AType and $F);
  end
  else if (AType >= TYPE_STR4) and (AType <= TYPE_STR4 + $0F) then
  // 0..15 String
  begin
    TypeNeeded(vdtString);
    S.Length := AType and $0F;
    if S.Length > 0 then
    begin
      AStream.ReadBuffer(PQCharA(S)^, S.Length);
      Value.AsString^ := qstring.Utf8Decode(PQCharA(S), S.Length)
    end
    else // 空字符串？
      Value.AsString^ := '';
  end
  else if (AType >= TYPE_MONEY4) and (AType <= TYPE_MONEY4 + $0F) then
  // Currency 0-15
  begin
    TypeNeeded(vdtCurrency);
    Value.AsCurrency := (AType and $0F);
  end
  else if (AType >= TYPE_BIN4) and (AType <= TYPE_BIN4 + $0F) then
  begin
    TypeNeeded(vdtStream);
    TMemoryStream(Value.AsStream).CopyFrom(AStream, AType and $0F);
  end
  else
  begin
    case AType of
      TYPE_UNSET: // Unset
        Reset;
      TYPE_NULL: // Null
        TypeNeeded(vdtNull);
      TYPE_TRUE: // True
        begin
          TypeNeeded(vdtBoolean);
          Value.AsBoolean := True;
        end;
      TYPE_FALSE: // False
        begin
          TypeNeeded(vdtBoolean);
          Value.AsBoolean := false;
        end;
      TYPE_INT8: //
        begin
          TypeNeeded(vdtInteger);
          AStream.ReadBuffer(Value.AsShort, SizeOf(Shortint));
          Value.AsInteger := Value.AsShort;
        end;
      TYPE_UINT8:
        begin
          TypeNeeded(vdtInteger);
          AStream.ReadBuffer(Value.AsByte, SizeOf(Byte));
        end;
      TYPE_INT16:
        begin
          TypeNeeded(vdtInteger);
          AStream.ReadBuffer(Value.AsSmallint, SizeOf(Smallint));
          Value.AsInteger := Value.AsSmallint;
        end;
      TYPE_UINT16:
        begin
          TypeNeeded(vdtInteger);
          AStream.ReadBuffer(Value.AsWord, SizeOf(Word));
        end;
      TYPE_INT32:
        begin
          TypeNeeded(vdtInteger);
          AStream.ReadBuffer(Value.AsInteger, SizeOf(Integer));
        end;
      TYPE_UINT32: // DWord
        begin
          TypeNeeded(vdtInt64);
          AStream.ReadBuffer(Value.AsInteger, SizeOf(Integer));
        end;
      TYPE_INT64, TYPE_UINT64: // Int64/UInt64
        begin
          TypeNeeded(vdtInt64);
          AStream.ReadBuffer(Value.AsInt64, SizeOf(Int64));
        end;
      TYPE_FLOAT32:
        begin
          TypeNeeded(vdtSingle);
          AStream.ReadBuffer(Value.AsSingle, SizeOf(Single));
        end;
      TYPE_FLOAT64:
        begin
          TypeNeeded(vdtFloat);
          AStream.ReadBuffer(Value.AsFloat, SizeOf(Double));
        end;
      TYPE_GUID:
        begin
          TypeNeeded(vdtGuid);
          AStream.ReadBuffer(Value.AsGuid^, SizeOf(TGuid));
        end;
      TYPE_BCD:
        begin
          TypeNeeded(vdtBcd);
          AStream.ReadBuffer(Value.AsBcd^, SizeOf(TBcd));
        end;
      TYPE_ARRAY8:
        begin
          TypeNeeded(vdtArray);
          L := 0;
          AStream.ReadBuffer(L, 1);
          ReadArray(L);
        end;
      TYPE_ARRAY16:
        begin
          TypeNeeded(vdtArray);
          L := 0;
          AStream.ReadBuffer(L, 2);
          ReadArray(L);
        end;
      TYPE_ARRAY32:
        begin
          TypeNeeded(vdtArray);
          L := 0;
          AStream.ReadBuffer(L, 4);
          ReadArray(L);
        end;
      TYPE_STR8: // 16-255 String
        begin
          TypeNeeded(vdtString);
          L := 0;
          AStream.ReadBuffer(L, SizeOf(Byte));
          S.Length := L;
          AStream.ReadBuffer(PQCharA(S)^, L);
          Value.AsString^ := qstring.Utf8Decode(PQCharA(S), S.Length);
        end;
      TYPE_STR16: // String:256~65535
        begin
          TypeNeeded(vdtString);
          L := 0;
          AStream.ReadBuffer(L, SizeOf(Word));
          S.Length := L;
          AStream.ReadBuffer(PQCharA(S)^, L);
          Value.AsString^ := qstring.Utf8Decode(PQCharA(S), S.Length);
        end;
      TYPE_STR32: // String:65536+
        begin
          TypeNeeded(vdtString);
          L := 0;
          AStream.ReadBuffer(L, SizeOf(Cardinal));
          S.Length := L;
          AStream.ReadBuffer(PQCharA(S)^, L);
          Value.AsString^ := qstring.Utf8Decode(PQCharA(S), S.Length);
        end;
      TYPE_BIN8: // Binary 16..255
        begin
          TypeNeeded(vdtStream);
          L := 0;
          AStream.ReadBuffer(L, 1);
          TMemoryStream(Value.AsStream).CopyFrom(AStream, L);
        end;
      TYPE_BIN16: // Binary 256..65535
        begin
          TypeNeeded(vdtStream);
          L := 0;
          AStream.ReadBuffer(L, 2);
          TMemoryStream(Value.AsStream).CopyFrom(AStream, L);
        end;
      TYPE_BIN32: // Binary 65536~$FFFFFFFF
        begin
          TypeNeeded(vdtStream);
          L := 0;
          AStream.ReadBuffer(L, 4);
          TMemoryStream(Value.AsStream).CopyFrom(AStream, L);
        end;
      TYPE_BIN64: // Binary $100000000+
        begin
          TypeNeeded(vdtStream);
          L := 0;
          AStream.ReadBuffer(L, 8);
          TMemoryStream(Value.AsStream).CopyFrom(AStream, L);
        end;
      TYPE_INTERVAL: // Interval
        begin
          TypeNeeded(vdtInterval);
          AStream.ReadBuffer(Value.AsInterval, SizeOf(TQInterval));
        end;
      TYPE_DATETIME: // TDateTime
        begin
          TypeNeeded(vdtDateTime);
          AStream.ReadBuffer(Value.AsDateTime, SizeOf(TDateTime));
        end;
      TYPE_DATE: // TDate
        begin
          TypeNeeded(vdtDateTime);
          AStream.ReadBuffer(Value.AsInteger, SizeOf(Integer));
          Value.AsDateTime := Value.AsInteger;
        end;
      TYPE_TIME: // TTime
        begin
          TypeNeeded(vdtDateTime);
          AStream.ReadBuffer(Value.AsSingle, SizeOf(Single));
          Value.AsDateTime := Value.AsSingle;
        end;
      TYPE_MONEY8: // Currency -128~127
        begin
          TypeNeeded(vdtCurrency);
          AStream.ReadBuffer(Value.AsShort, SizeOf(Shortint));
          Value.AsCurrency := Value.AsShort;
        end;
      TYPE_MONEY16: // Currency -32768~32767
        begin
          TypeNeeded(vdtCurrency);
          AStream.ReadBuffer(Value.AsSmallint, SizeOf(Smallint));
          Value.AsCurrency := Value.AsSmallint;
        end;
      TYPE_MONEY32: // Currency -2147483648 ~ 2147483647
        begin
          TypeNeeded(vdtCurrency);
          AStream.ReadBuffer(Value.AsInteger, SizeOf(Integer));
          Value.AsCurrency := Value.AsInteger;
        end;
      TYPE_MONEY64:
        begin
          TypeNeeded(vdtCurrency);
          AStream.ReadBuffer(Value.AsCurrency, SizeOf(Currency));
        end;
      TYPE_USTR8:
        begin
          TypeNeeded(vdtString);
          L := 0;
          AStream.ReadBuffer(L, 1);
          SetLength(Value.AsString^, L shr 1);
          AStream.ReadBuffer(PQCharW(Value.AsString^)^, L);
        end;
      TYPE_USTR16:
        begin
          TypeNeeded(vdtString);
          L := 0;
          AStream.ReadBuffer(L, 2);
          SetLength(Value.AsString^, L shr 1);
          AStream.ReadBuffer(PQCharW(Value.AsString^)^, L);
        end;
      TYPE_USTR32:
        begin
          TypeNeeded(vdtString);
          L := 0;
          AStream.ReadBuffer(L, 4);
          SetLength(Value.AsString^, L shr 1);
          AStream.ReadBuffer(PQCharW(Value.AsString^)^, L);
        end;
    end;
  end;
end;

procedure TQValueHelper.Reset;
  procedure ClearArray;
  var
    I: Cardinal;
  begin
    I := 0;
    while I < Value.Size do
    begin
      Items[I].Reset;
      Inc(I);
    end;
    FreeMem(Value.Items);
  end;

begin
  if ValueType <> vdtUnset then
  begin
    case ValueType of
      vdtGuid:
        Dispose(Value.AsGuid);
      vdtString:
        Dispose(Value.AsString);
      vdtStream:
        FreeAndNil(Value.AsStream);
      vdtArray:
        ClearArray;
      vdtBcd:
        Dispose(Value.AsBcd);
    end;
    ValueType := vdtUnset;
  end;
end;

procedure TQValueHelper.SaveToFile(const AFileName: String);
var
  AStream: TFileStream;
begin
  AStream := TFileStream.Create(AFileName, fmCreate);
  try
    SaveToStream(AStream);
  finally
    FreeAndNil(AStream);
  end;
end;

procedure TQValueHelper.SaveToStream(AStream: TStream);

  procedure WriteArray;
  var
    AType: Byte;
    I: Cardinal;
  begin
    if Value.Size < 16 then
    begin
      AType := TYPE_ARRAY4 + Byte(Value.Size);
      AStream.WriteBuffer(AType, 1);
    end
    else if Value.Size < 256 then
    begin
      AType := TYPE_ARRAY8;
      AStream.WriteBuffer(AType, 1);
      AStream.WriteBuffer(Value.Size, 1);
    end
    else if Value.Size < 65536 then
    begin
      AType := TYPE_ARRAY16;
      AStream.WriteBuffer(AType, 1);
      AStream.WriteBuffer(Value.Size, 2);
    end
    else
    begin
      AType := TYPE_ARRAY32;
      AStream.WriteBuffer(AType, 1);
      AStream.WriteBuffer(Value.Size, 4);
    end;
    I := 0;
    while I < Value.Size do
    begin
      Items[I].SaveToStream(AStream);
      Inc(I);
    end;
  end;

begin
  case ValueType of
    vdtUnset:
      WriteUnset(AStream);
    vdtNull:
      WriteNull(AStream);
    vdtBoolean:
      WriteBoolean(AStream, Value.AsBoolean);
    vdtSingle:
      WriteSingle(AStream, Value.AsSingle);
    vdtFloat:
      WriteFloat(AStream, Value.AsFloat);
    vdtInteger:
      WriteInt(AStream, Value.AsInteger);
    vdtInt64:
      WriteInt(AStream, Value.AsInt64);
    vdtCurrency:
      WriteCurrency(AStream, Value.AsCurrency);
    vdtBcd:
      WriteBcd(AStream, Value.AsBcd^);
    vdtGuid:
      WriteGuid(AStream, Value.AsGuid^);
    vdtDateTime:
      WriteDateTime(AStream, Value.AsDateTime);
    vdtInterval:
      WriteInterval(AStream, Value.AsInterval);
    vdtString:
      WriteString(AStream, Value.AsString^);
    vdtStream:
      WriteBinary(AStream, TQValueStream(Value.AsStream).Memory,
        TQValueStream(Value.AsStream).Size);
    vdtArray:
      WriteArray;
  end;
end;

procedure TQValueHelper.SetAsBcd(const AValue: TBcd);
begin
  if ValueType = vdtBcd then
    Value.AsBcd^ := AValue
  else if ValueType = vdtString then
    Value.AsString^ := BcdToStr(AValue)
  else
    raise Exception.CreateFmt(SConvertError, [QValueTypeName[vdtBcd],
      QValueTypeName[ValueType]]);
end;

procedure TQValueHelper.SetAsBoolean(const AValue: Boolean);
begin
  case ValueType of
    vdtBoolean:
      Value.AsBoolean := AValue;
    vdtSingle:
      Value.AsSingle := Integer(AValue);
    vdtFloat, vdtDateTime:
      Value.AsFloat := Integer(AValue);
    vdtInteger:
      Value.AsInteger := Integer(AValue);
    vdtInt64:
      Value.AsInt64 := Int64(AValue);
    vdtCurrency:
      Value.AsCurrency := Integer(AValue);
    vdtBcd:
      Value.AsBcd^ := IntegerToBcd(Integer(AValue));
    vdtString:
      Value.AsString^ := BoolToStr(AValue, True)
  else
    raise Exception.CreateFmt(SConvertError, [QValueTypeName[vdtBoolean],
      QValueTypeName[ValueType]]);
  end;
end;

procedure TQValueHelper.SetAsBytes(const AValue: TBytes);

  procedure ArrayFromMsgPack(AMsgPack: TQMsgPack; AParent: PQValue);
  var
    I: Integer;
    AItem: TQMsgPack;
    ADest: PQValue;
  begin
    AParent.ArrayNeeded(AMsgPack.Count);
    I := 0;
    while I < AMsgPack.Count do
    begin
      AItem := AMsgPack[I];
      ADest := AParent.Items[I];
      case AItem.DataType of
        mptInteger:
          begin
            ADest.TypeNeeded(vdtInteger);
            ADest.Value.AsInteger := AItem.AsInteger;
          end;
        mptNull:
          ADest.Reset;
        mptBoolean:
          begin
            ADest.TypeNeeded(vdtBoolean);
            ADest.Value.AsBoolean := AItem.AsBoolean;
          end;
        mptSingle:
          begin
            ADest.TypeNeeded(vdtSingle);
            ADest.Value.AsSingle := AItem.AsSingle;
          end;
        mptFloat:
          begin
            ADest.TypeNeeded(vdtFloat);
            ADest.Value.AsFloat := AItem.AsFloat;
          end;
        mptString:
          begin
            ADest.TypeNeeded(vdtString);
            ADest.Value.AsString^ := AItem.AsString;
          end;
        mptBinary:
          begin
            ADest.TypeNeeded(vdtStream);
            ADest.AsBytes := AItem.AsBytes;
          end;
        mptArray, mptMap:
          begin
            ADest.ArrayNeeded(AItem.Count);
            ArrayFromMsgPack(AItem, ADest);
          end;
        mptExtended:
          begin
            ADest.TypeNeeded(vdtStream);
            ADest.AsBytes := AItem.AsBytes;
          end;
        mptDateTime:
          begin
            ADest.TypeNeeded(vdtDateTime);
            ADest.Value.AsDateTime := AItem.AsDateTime;
          end;
      end;
      Inc(I);
    end;
  end;

  procedure ArrayToValue;
  var
    AMsgPack: TQMsgPack;
  begin
    AMsgPack := TQMsgPack.Create;
    try
      AMsgPack.Parse(@AValue[0], Length(AValue));
      if AMsgPack.DataType <> mptArray then
        raise Exception.CreateFmt(SConvertError, [QValueTypeName[vdtStream],
          QValueTypeName[ValueType]])
      else
        ArrayFromMsgPack(AMsgPack, @Self);
    finally
      FreeObject(AMsgPack);
    end;
  end;

begin
  case ValueType of
    vdtUnset, vdtNull:
      begin
        if Length(AValue) <> 0 then
          raise Exception.CreateFmt(SConvertError, [QValueTypeName[vdtStream],
            QValueTypeName[ValueType]]);
      end;
    vdtBoolean:
      begin
        if Length(AValue) = 1 then
          Value.AsBoolean := AValue[1] <> 0
        else
          raise Exception.CreateFmt(SConvertError, [QValueTypeName[vdtStream],
            QValueTypeName[ValueType]]);
      end;
    vdtSingle:
      begin
        if Length(AValue) = SizeOf(Single) then
          Value.AsSingle := PSingle(@AValue[0])^
        else
          raise Exception.CreateFmt(SConvertError, [QValueTypeName[vdtStream],
            QValueTypeName[ValueType]]);;
      end;
    vdtFloat:
      begin
        if Length(AValue) = SizeOf(Double) then
          Value.AsFloat := PDouble(@AValue[0])^
        else
          raise Exception.CreateFmt(SConvertError, [QValueTypeName[vdtStream],
            QValueTypeName[ValueType]]);;
      end;
    vdtInteger:
      begin
        if Length(AValue) = SizeOf(Integer) then
          Value.AsInteger := PInteger(@AValue[0])^
        else
          raise Exception.CreateFmt(SConvertError, [QValueTypeName[vdtStream],
            QValueTypeName[ValueType]]);
      end;
    vdtInt64:
      begin
        if Length(AValue) = SizeOf(Int64) then
          Value.AsInt64 := PInt64(@AValue[0])^
        else
          raise Exception.CreateFmt(SConvertError, [QValueTypeName[vdtStream],
            QValueTypeName[ValueType]]);
      end;
    vdtCurrency:
      begin
        if Length(AValue) = SizeOf(Currency) then
          Value.AsCurrency := PCurrency(@AValue[0])^
        else
          raise Exception.CreateFmt(SConvertError, [QValueTypeName[vdtStream],
            QValueTypeName[ValueType]]);

      end;
    vdtBcd:
      begin
        if Length(AValue) = SizeOf(TBcd) then
          Value.AsBcd^ := PBcd(@AValue[0])^
        else
          raise Exception.CreateFmt(SConvertError, [QValueTypeName[vdtStream],
            QValueTypeName[ValueType]]);
      end;
    vdtGuid:
      begin
        if Length(AValue) = SizeOf(TGuid) then
          Value.AsGuid^ := PGuid(@AValue[0])^
        else
          raise Exception.CreateFmt(SConvertError, [QValueTypeName[vdtStream],
            QValueTypeName[ValueType]]);
      end;
    vdtDateTime:
      begin
        if Length(AValue) = SizeOf(TDateTime) then
          Value.AsDateTime := PDateTime(@AValue[0])^
        else
          raise Exception.CreateFmt(SConvertError, [QValueTypeName[vdtStream],
            QValueTypeName[ValueType]]);
      end;
    vdtInterval:
      begin
        if Length(AValue) = SizeOf(TQInterval) then
          Value.AsInterval := PQInterval(@AValue[0])^
        else
          raise Exception.CreateFmt(SConvertError, [QValueTypeName[vdtStream],
            QValueTypeName[ValueType]]);
      end;
    vdtString:
      begin
        if Length(AValue) > 0 then
          Value.AsString^ := qstring.Utf8Decode(@AValue[0], Length(AValue))
        else
          SetLength(Value.AsString^, 0);
      end;
    vdtStream:
      begin
        TQValueStream(Value.AsStream).Position := 0;
        TQValueStream(Value.AsStream).Write(AValue[0], Length(AValue));
        TQValueStream(Value.AsStream).Size := Length(AValue);
      end;
    vdtArray:
      ArrayToValue;
  end;
end;

procedure TQValueHelper.SetAsCurrency(const AValue: Currency);
begin
  case ValueType of
    vdtCurrency:
      Value.AsCurrency := AValue;
    vdtBoolean:
      Value.AsBoolean := AValue <> 0;
    vdtSingle:
      Value.AsSingle := AValue;
    vdtFloat, vdtDateTime:
      Value.AsFloat := AValue;
    vdtInteger:
      Value.AsInteger := Trunc(AValue);
    vdtInt64:
      Value.AsInt64 := Trunc(AValue);
    vdtBcd:
      CurrToBcd(AValue, Value.AsBcd^);
    vdtString:
      Value.AsString^ := CurrToStr(AValue)
  else
    raise Exception.CreateFmt(SConvertError, [QValueTypeName[vdtCurrency],
      QValueTypeName[ValueType]]);
  end;
end;

procedure TQValueHelper.SetAsDateTime(const AValue: TDateTime);
begin
  case ValueType of
    vdtFloat, vdtDateTime:
      Value.AsFloat := AValue;
    vdtSingle:
      Value.AsSingle := AValue;
    vdtBoolean:
      Value.AsBoolean := IsZero(AValue);
    vdtInteger:
      Value.AsInteger := Trunc(AValue);
    vdtInt64:
      Value.AsInt64 := Trunc(AValue);
    vdtCurrency:
      Value.AsCurrency := AValue;
    vdtBcd:
      Value.AsBcd^ := DoubleToBcd(AValue);
    vdtString:
      Value.AsString^ := DateTimeToStr(AValue)
  else
    raise Exception.CreateFmt(SConvertError, [QValueTypeName[vdtDateTime],
      QValueTypeName[ValueType]]);
  end;
end;

procedure TQValueHelper.SetAsFloat(const AValue: Double);
begin
  case ValueType of
    vdtFloat, vdtDateTime:
      Value.AsFloat := AValue;
    vdtSingle:
      Value.AsSingle := AValue;
    vdtBoolean:
      Value.AsBoolean := IsZero(AValue);
    vdtInteger:
      Value.AsInteger := Trunc(AValue);
    vdtInt64:
      Value.AsInt64 := Trunc(AValue);
    vdtCurrency:
      Value.AsCurrency := AValue;
    vdtBcd:
      Value.AsBcd^ := DoubleToBcd(AValue);
    vdtString:
      Value.AsString^ := DateTimeToStr(AValue)
  else
    raise Exception.CreateFmt(SConvertError, [QValueTypeName[vdtFloat],
      QValueTypeName[ValueType]]);
  end;
end;

procedure TQValueHelper.SetAsGuid(const AValue: TGuid);
begin
  if ValueType = vdtGuid then
    Value.AsGuid^ := AValue
  else if ValueType = vdtString then
    Value.AsString^ := GuidToString(AValue)
  else
    raise Exception.CreateFmt(SConvertError, [QValueTypeName[vdtGuid],
      QValueTypeName[ValueType]]);
end;

procedure TQValueHelper.SetAsInt64(const AValue: Int64);
begin
  case ValueType of
    vdtInt64:
      Value.AsInt64 := AValue;
    vdtInteger:
      Value.AsInteger := AValue;
    vdtBoolean:
      Value.AsBoolean := AValue <> 0;
    vdtSingle:
      Value.AsSingle := AValue;
    vdtFloat, vdtDateTime:
      Value.AsFloat := AValue;
    vdtCurrency:
      Value.AsCurrency := AValue;
    vdtBcd:
      Value.AsBcd^ := Int64ToBcd(AValue);
    vdtString:
      Value.AsString^ := IntToStr(AValue)
  else
    raise Exception.CreateFmt(SConvertError, [QValueTypeName[vdtInt64],
      QValueTypeName[ValueType]]);
  end;
end;

procedure TQValueHelper.SetAsInteger(const AValue: Integer);
begin
  case ValueType of
    vdtInteger:
      Value.AsInteger := AValue;
    vdtInt64:
      Value.AsInt64 := AValue;
    vdtBoolean:
      Value.AsBoolean := AValue <> 0;
    vdtSingle:
      Value.AsSingle := AValue;
    vdtFloat, vdtDateTime:
      Value.AsFloat := AValue;
    vdtCurrency:
      Value.AsCurrency := AValue;
    vdtBcd:
      Value.AsBcd^ := IntegerToBcd(AValue);
    vdtString:
      Value.AsString^ := IntToStr(AValue)
  else
    raise Exception.CreateFmt(SConvertError, [QValueTypeName[vdtInt64],
      QValueTypeName[ValueType]]);
  end;
end;

procedure TQValueHelper.SetAsInterval(const AValue: TQInterval);
begin
  if ValueType = vdtInterval then
    Value.AsInterval := AValue
  else if ValueType = vdtString then
    Value.AsString^ := AValue.AsString
  else
    raise Exception.CreateFmt(SConvertError, [QValueTypeName[vdtInterval],
      QValueTypeName[ValueType]]);
end;

procedure TQValueHelper.SetAsSingle(const AValue: Single);
begin
  case ValueType of
    vdtSingle:
      Value.AsSingle := AValue;
    vdtFloat, vdtDateTime:
      Value.AsFloat := AValue;
    vdtBoolean:
      Value.AsBoolean := IsZero(AValue);
    vdtInteger:
      Value.AsInteger := Trunc(AValue);
    vdtInt64:
      Value.AsInt64 := Trunc(AValue);
    vdtCurrency:
      Value.AsCurrency := AValue;
    vdtBcd:
      Value.AsBcd^ := DoubleToBcd(AValue);
    vdtString:
      Value.AsString^ := DateTimeToStr(AValue)
  else
    raise Exception.CreateFmt(SConvertError, [QValueTypeName[vdtSingle],
      QValueTypeName[ValueType]]);
  end;
end;

procedure TQValueHelper.SetAsString(const AValue: QStringW);
  procedure ToStream;
  var
    ABytes: TBytes;
  begin
    HexToBin(AValue, ABytes);
    if Length(ABytes) <> 0 then
    begin
      TQValueStream(Value.AsStream).Size := Length(ABytes);
      TQValueStream(Value.AsStream).WriteBuffer(ABytes[0], Length(ABytes));
    end
    else if Length(AValue) <> 0 then
      raise Exception.CreateFmt(SConvertError, [QValueTypeName[vdtString],
        QValueTypeName[ValueType]])
    else
      TQValueStream(Value.AsStream).Size := 0;
  end;
  procedure JsonToArray(AJson: TQJson; AParent: PQValue);
  var
    I: Integer;
    AItem: PQValue;
  begin
    AParent.ArrayNeeded(AJson.Count);
    I := 0;
    while I < AJson.Count do
    begin
      AItem := AParent.Items[I];
      case AJson.DataType of
        jdtUnknown, jdtNull:
          AItem.Reset;
        jdtString:
          begin
            AItem.TypeNeeded(vdtString);
            AItem.Value.AsString^ := AJson[I].AsString;
          end;
        jdtInteger:
          begin
            AItem.TypeNeeded(vdtInteger);
            AItem.Value.AsInteger := AJson[I].AsInteger;
          end;
        jdtFloat:
          begin
            AItem.TypeNeeded(vdtFloat);
            AItem.Value.AsFloat := AJson[I].AsFloat;
          end;
        jdtBoolean:
          begin
            AItem.TypeNeeded(vdtBoolean);
            AItem.Value.AsBoolean := AJson[I].AsBoolean;
          end;
        jdtDateTime:
          begin
            AItem.TypeNeeded(vdtDateTime);
            AItem.Value.AsDateTime := AJson[I].AsDateTime;
          end;
        jdtArray:
          JsonToArray(AJson[I], AItem);
        jdtObject:
          JsonToArray(AJson[I], AItem);
      end;
      Inc(I);
    end;
  end;
  procedure ToArray;
  var
    AJson: TQJson;
  begin
    AJson := TQJson.Create;
    try
      if AJson.TryParse(AValue) and (AJson.DataType = jdtArray) then
        JsonToArray(AJson, @Self)
      else
        raise Exception.CreateFmt(SConvertError, [QValueTypeName[vdtString],
          QValueTypeName[ValueType]]);
    finally
      FreeObject(AJson);
    end;
  end;
  function StrToBool(const S: QStringW): Boolean;
  var
    p: PQCharW;
    V: Integer;
  begin
    p := PQCharW(S);
    if (p^ = 't') or (p^ = 'T') then
    begin
      Inc(p);
      if p^ <> #0 then
      begin
        Result := StrCmpW(p, 'rue', True) = 0;
        if not Result then
          raise Exception.CreateFmt(SConvertError, [QValueTypeName[vdtString],
            QValueTypeName[ValueType]]);
      end
      else
        Result := True;
    end
    else if (p^ = 'f') or (p^ = 'F') then
    begin
      Inc(p);
      if p^ <> #0 then
      begin
        if StrCmpW(p, 'alse', True) = 0 then
          Result := false
        else
          raise Exception.CreateFmt(SConvertError, [QValueTypeName[vdtString],
            QValueTypeName[ValueType]]);
      end
      else
        Result := false;
    end
    else if StrCmpW(p, '.t.', True) = 0 then
      Result := True
    else if StrCmpW(p, '.f.', True) = 0 then
      Result := false
    else if TryStrToInt(S, V) then
      Result := V <> 0
    else
      raise Exception.CreateFmt(SConvertError, [QValueTypeName[vdtString],
        QValueTypeName[ValueType]]);
  end;

begin
  case ValueType of
    vdtString:
      Value.AsString^ := AValue;
    vdtUnset, vdtNull:
      begin
        if StrCmpW(PQCharW(AValue), 'null', True) <> 0 then
          raise Exception.CreateFmt(SConvertError, [QValueTypeName[vdtString],
            QValueTypeName[ValueType]]);
      end;
    vdtBoolean:
      Value.AsBoolean := StrToBool(AValue);
    vdtSingle:
      Value.AsSingle := StrToFloat(AValue);
    vdtFloat:
      Value.AsFloat := StrToFloat(AValue);
    vdtInteger:
      Value.AsInteger := StrToInt(AValue);
    vdtInt64:
      Value.AsInt64 := StrToInt64(AValue);
    vdtCurrency:
      if StartWithW(PQCharW(AValue), '$', false) then
        Value.AsCurrency := StrToCurr(StrDupW(PQCharW(AValue), 1))
      else
        Value.AsCurrency := StrToCurr(AValue);
    vdtBcd:
      Value.AsBcd^ := StrToBcd(AValue);
    vdtGuid:
      if not TryStrToGuid(AValue, Value.AsGuid^) then
        raise Exception.CreateFmt(SConvertError, [QValueTypeName[vdtString],
          QValueTypeName[ValueType]]);
    vdtDateTime:
      if not(TryStrToDateTime(AValue, Value.AsDateTime) or
        ParseDateTime(PQCharW(AValue), Value.AsDateTime) or
        ParseWebTime(PQCharW(AValue), Value.AsDateTime)) then
        raise Exception.CreateFmt(SConvertError, [QValueTypeName[vdtString],
          QValueTypeName[ValueType]]);
    vdtInterval:
      Value.AsInterval.AsString := AValue;
    vdtStream:
      begin
        TQValueStream(Value.AsStream).Size := 0;
        SaveTextW(Value.AsStream, AValue, True);
      end;
    vdtArray:
      ;
  end;
end;

procedure TQValueHelper.SetAsVariant(const AValue: Variant);
  procedure I1Stream(V: Shortint);
  begin
    TQValueStream(Value.AsStream).Size := SizeOf(V);
    PShortint(TQValueStream(Value.AsStream).Memory)^ := V;
  end;

  procedure W1Stream(V: Byte);
  begin
    TQValueStream(Value.AsStream).Size := SizeOf(V);
    PByte(TQValueStream(Value.AsStream).Memory)^ := V;
  end;

  procedure I2Stream(V: Smallint);
  begin
    TQValueStream(Value.AsStream).Size := SizeOf(V);
    PSmallint(TQValueStream(Value.AsStream).Memory)^ := V;
  end;

  procedure W2Stream(V: Word);
  begin
    TQValueStream(Value.AsStream).Size := SizeOf(V);
    PWord(TQValueStream(Value.AsStream).Memory)^ := V;
  end;

  procedure I4Stream(V: Integer);
  begin
    TQValueStream(Value.AsStream).Size := SizeOf(V);
    PInteger(TQValueStream(Value.AsStream).Memory)^ := V;
  end;

  procedure W4Stream(V: Cardinal);
  begin
    TQValueStream(Value.AsStream).Size := SizeOf(V);
    PCardinal(TQValueStream(Value.AsStream).Memory)^ := V;
  end;

  procedure I8Stream(V: Int64);
  begin
    TQValueStream(Value.AsStream).Size := SizeOf(V);
    PInt64(TQValueStream(Value.AsStream).Memory)^ := V;
  end;

  procedure W8Stream(V: UInt64);
  begin
    TQValueStream(Value.AsStream).Size := SizeOf(V);
    PInt64(TQValueStream(Value.AsStream).Memory)^ := V;
  end;

  procedure F4Stream(V: Single);
  begin
    TQValueStream(Value.AsStream).Size := SizeOf(V);
    PSingle(TQValueStream(Value.AsStream).Memory)^ := V;
  end;

  procedure F8Stream(V: Double);
  begin
    TQValueStream(Value.AsStream).Size := SizeOf(V);
    PDouble(TQValueStream(Value.AsStream).Memory)^ := V;
  end;

  procedure C8Stream(V: Currency);
  begin
    TQValueStream(Value.AsStream).Size := SizeOf(V);
    PCurrency(TQValueStream(Value.AsStream).Memory)^ := V;
  end;

  procedure WCS2Stream(V: QStringW);
  begin
    TQValueStream(Value.AsStream).Size := Length(V) shl 1;
    Move(PWideChar(V)^, TQValueStream(Value.AsStream).Memory^, Length(V) shl 1);
  end;
  procedure AnsiStream(V: QStringA);
  begin
    TQValueStream(Value.AsStream).Size := V.Length;
    Move(PQCharA(V)^, TQValueStream(Value.AsStream).Memory^, V.Length);
  end;

  procedure BoolStream(V: Boolean);
  begin
    TQValueStream(Value.AsStream).Size := SizeOf(V);
    PBoolean(TQValueStream(Value.AsStream).Memory)^ := V;
  end;

  procedure VarAsBytes;
  var
    L: Integer;
    p: PByte;
  begin
    case VarType(AValue) of
      varSmallInt:
        I2Stream(AValue);
      varInteger:
        I4Stream(AValue);
      varSingle:
        F4Stream(AValue);
      varDouble:
        F8Stream(AValue);
      varCurrency:
        C8Stream(AValue);
      varDate:
        F8Stream(AValue);
      varOleStr:
        WCS2Stream(AValue);
      varBoolean:
        BoolStream(AValue);
      varShortInt:
        I1Stream(AValue);
      varByte:
        W1Stream(AValue);
      varWord:
        W2Stream(AValue);
      varLongWord:
        W4Stream(AValue);
      varInt64:
        I8Stream(AValue);
{$IF RTLVersion>18.5}
      varUInt64:
        W8Stream(AValue);
{$IFEND}
      varString:
        AnsiStream(String(AValue));
      varArray or varByte:
        begin
          L := VarArrayHighBound(AValue, 1) + 1;
          TQValueStream(Value.AsStream).Size := L;
          p := VarArrayLock(AValue);
          Move(p^, TQValueStream(Value.AsStream).Memory^, L);
          VarArrayUnlock(AValue);
        end{$IF RTLVersion>18.5};
      varUString:
        WCS2Stream(AValue)
{$IFEND}
    else
      raise QException.CreateFmt(SUnsupportStreamSource,
        [VarType(AValue), VarType(AValue)]);
    end;
  end;
  procedure VarAsArray;
  var
    I, H: Integer;
  begin
    if VarIsArray(AValue) then
    begin
      H := VarArrayHighBound(AValue, 1);
      ArrayNeeded(H + 1);
      for I := VarArrayLowBound(AValue, 1) to H do
        Items[I].AsVariant := AValue[I];
    end
    else
      raise Exception.CreateFmt(SConvertError, [VarToStr(AValue), 'Array']);
  end;

begin
  case ValueType of
    vdtUnset, vdtNull:
      if not VarIsNull(AValue) then
        raise Exception.CreateFmt(SConvertError, [VarToStr(AValue), 'Null']);
    vdtBoolean:
      Value.AsBoolean := AValue;
    vdtSingle:
      Value.AsSingle := AValue;
    vdtFloat:
      Value.AsFloat := AValue;
    vdtInteger:
      Value.AsInteger := AValue;
    vdtInt64:
      Value.AsInt64 := AValue;
    vdtCurrency:
      Value.AsCurrency := AValue;
    vdtBcd:
      Value.AsBcd^ := StrToBcd(AValue);
    vdtGuid:
      Value.AsGuid^ := StringToGuid(AValue);
    vdtDateTime:
      Value.AsDateTime := AValue;
    vdtInterval:
      Value.AsInterval.AsString := AValue;
    vdtString:
      Value.AsString^ := AValue;
    vdtStream:
      VarAsBytes;
    vdtArray:
      VarAsArray;
  end;

end;

/// <summary>确保当前TQValue实例已经按正确的类型初始化</summary>
/// <param name="AType">需要的数据类型</param>
function TQValueHelper.TypeNeeded(AType: TQValueDataType): PQValue;
begin
  Result := @Self;
  if AType <> ValueType then
  begin
    Reset;
    case AType of
      vdtBcd:
        New(Value.AsBcd);
      vdtGuid:
        New(Value.AsGuid);
      vdtString:
        New(Value.AsString);
      vdtStream:
        Value.AsStream := TQValueStream.Create;
      vdtArray:
        Value.Size := 0;
    end;
    ValueType := AType;
  end;
end;

class procedure TQValueHelper.WriteArray(AStream: TStream;
  const V: array of const);
var
  AType: Byte;
  I, L: Cardinal;
  procedure WriteVariant(const V: Variant);
  var
    T: TQValue;
  begin
    T.AsVariant := V;
    T.SaveToStream(AStream);
  end;

begin
  L := Length(V);
  if L < 16 then
  begin
    AType := TYPE_ARRAY4 + Byte(L);
    AStream.WriteBuffer(AType, 1);
  end
  else if L < 256 then
  begin
    AType := TYPE_ARRAY8;
    AStream.WriteBuffer(AType, 1);
    AStream.WriteBuffer(L, 1);
  end
  else if L < 65536 then
  begin
    AType := TYPE_ARRAY16;
    AStream.WriteBuffer(AType, 1);
    AStream.WriteBuffer(L, 2);
  end
  else
  begin
    AType := TYPE_ARRAY32;
    AStream.WriteBuffer(AType, 1);
    AStream.WriteBuffer(L, 4);
  end;
  I := 0;
  while I < L do
  begin
    case V[I].VType of
      vtInteger:
        WriteInt(AStream, V[I].VInteger);
      vtBoolean:
        WriteBoolean(AStream, V[I].VBoolean);
{$IFNDEF NEXTGEN}
      vtChar:
        WriteString(AStream, V[I].VChar);
{$ENDIF !NEXTGEN}
      vtExtended:
        WriteFloat(AStream, V[I].VExtended^);
{$IFNDEF NEXTGEN}
      vtPChar:
        WriteString(AStream, V[I].VPChar);
      vtString:
        WriteString(AStream, V[I].VString^);
      vtAnsiString:
        WriteString(AStream, AnsiDecode(
{$IFDEF UNICODE}
          PAnsiString(V[I].VAnsiString)^
{$ELSE}
          PQCharA(V[I].VPChar), -1
{$ENDIF UNICODE}
          ));
      vtWideString:
        WriteString(AStream, PWideChar(V[I].VWideString^));
{$ENDIF !NEXTGEN}
      vtWideChar:
        WriteString(AStream, V[I].VWideChar);
      vtPWideChar:
        WriteString(AStream, V[I].VPWideChar);
      vtCurrency:
        WriteCurrency(AStream, V[I].VCurrency^);
      vtInt64:
        WriteInt(AStream, V[I].VInt64^);
{$IFDEF UNICODE}       // variants
      vtUnicodeString:
        WriteString(AStream, PUnicodeString(V[I].VUnicodeString)^);
{$ENDIF UNICODE}
      vtVariant:
        WriteVariant(V[I].VVariant^)
    else
      raise QException.CreateFmt(SUnsupportStreamSource,
        [Integer(V[I].VType), Integer(V[I].VType)]);
    end;
    Inc(I);
  end;
end;

class procedure TQValueHelper.WriteBcd(AStream: TStream; const V: TBcd);
var
  AType: Byte;
begin
  AType := TYPE_BCD;
  AStream.WriteBuffer(AType, 1);
  AStream.WriteBuffer(V, SizeOf(TBcd));
end;

class procedure TQValueHelper.WriteBinary(AStream: TStream; V: PByte; L: Int64);
var
  AType: Byte;
begin
  if L < 16 then
  begin
    AType := TYPE_BIN4 + L;
    AStream.WriteBuffer(AType, 1);
  end
  else if L < 256 then
  begin
    AType := TYPE_BIN8;
    AStream.WriteBuffer(AType, 1);
    AStream.WriteBuffer(L, 1);
  end
  else if L < 65536 then
  begin
    AType := TYPE_BIN16;
    AStream.WriteBuffer(AType, 1);
    AStream.WriteBuffer(L, 2);
  end
  else if L <= Cardinal($FFFFFFFF) then
  begin
    AType := TYPE_BIN32;
    AStream.WriteBuffer(AType, 1);
    AStream.WriteBuffer(L, 4);
  end
  else
  begin
    AType := TYPE_BIN64;
    AStream.WriteBuffer(AType, 1);
    AStream.WriteBuffer(L, 8);
  end;
  if L > 0 then
    AStream.WriteBuffer(V^, L);
end;

class procedure TQValueHelper.WriteBinary(AStream: TStream; V: TBytes);
begin
  if Length(V) > 0 then
    WriteBinary(AStream, @V[0], Length(V))
  else
    WriteBinary(AStream, nil, 0);
end;

class procedure TQValueHelper.WriteBoolean(AStream: TStream; V: Boolean);
var
  AType: Byte;
begin
  if V then
    AType := TYPE_TRUE
  else
    AType := TYPE_FALSE;
  AStream.WriteBuffer(AType, 1);
end;

class procedure TQValueHelper.WriteCurrency(AStream: TStream; V: Currency);
var
  AType: Byte;
  Value: Int64 absolute V;
begin
  if (Value >= 0) and (Value <= 15) then
  begin
    AType := TYPE_MONEY4 + Byte(Value);
    AStream.WriteBuffer(AType, 1);
  end
  else if (Value >= -128) and (Value <= 127) then // 1B
  begin
    AType := TYPE_MONEY8;
    AStream.WriteBuffer(AType, 1);
    AStream.WriteBuffer(Value, 1);
  end
  else if (Value >= -32768) and (Value <= 32767) then // 2B
  begin
    AType := TYPE_MONEY16;
    AStream.WriteBuffer(AType, 1);
    AStream.WriteBuffer(Value, 2);
  end
  else if (Value >= -2147483648) and (Value <= 2147483647) then
  // 4B
  begin
    AType := TYPE_MONEY32;
    AStream.WriteBuffer(AType, 1);
    AStream.WriteBuffer(Value, 4);
  end
  else
  begin
    AType := TYPE_MONEY64;
    AStream.WriteBuffer(AType, 1);
    AStream.WriteBuffer(Value, 8);
  end;
end;

class procedure TQValueHelper.WriteDateTime(AStream: TStream;
  AValue: TDateTime);
var
  AType: Byte;
  V: Integer;
  S: Single;
begin
  V := Trunc(AValue);
  if V = 0 then
  begin
    AType := TYPE_TIME; // Time only
    AStream.WriteBuffer(AType, 1);
    S := AValue;
    AStream.WriteBuffer(S, 4);
  end
  else if SameValue(AValue, V) then // Date Only
  begin
    AType := TYPE_DATE;
    AStream.WriteBuffer(AType, 1);
    AStream.WriteBuffer(V, SizeOf(Integer));
  end
  else
  begin
    AType := TYPE_DATETIME;
    AStream.WriteBuffer(AType, 1);
    AStream.WriteBuffer(AValue, SizeOf(TDateTime));
  end;
end;

class procedure TQValueHelper.WriteFile(AStream: TStream; AFile: QStringW);
var
  ASource: TMemoryStream;
begin
  ASource := TMemoryStream.Create;
  try
    ASource.LoadFromFile(AFile);
    WriteStream(AStream, ASource, 0);
  finally
    FreeAndNil(ASource);
  end;
end;

class procedure TQValueHelper.WriteFloat(AStream: TStream; V: Double);
var
  AType: Byte;
begin
  AType := TYPE_FLOAT64;
  AStream.WriteBuffer(AType, 1);
  AStream.WriteBuffer(V, 8);
end;

class procedure TQValueHelper.WriteGuid(AStream: TStream; const V: TGuid);
var
  AType: Byte;
begin
  AType := TYPE_GUID;
  AStream.WriteBuffer(AType, 1);
  AStream.WriteBuffer(V, 16);
end;

class procedure TQValueHelper.WriteInt(AStream: TStream; V: Int64);
var
  AType: Byte;
  b: array [0 .. 7] of Byte absolute V;
begin
  if V >= 0 then
  begin
    if V <= 127 then
    begin
      AType := Byte(V);
      AStream.WriteBuffer(AType, 1);
    end
    else if V <= 255 then // 1B
    begin
      AType := TYPE_UINT8;
      AStream.WriteBuffer(AType, 1);
      AStream.WriteBuffer(V, 1);
    end
    else if V <= 65535 then // 2B
    begin
      AType := TYPE_UINT16;
      AStream.WriteBuffer(AType, 1);
      AStream.WriteBuffer(V, 2);
    end
    else if V <= Cardinal($FFFFFFFF) then
    begin
      AType := TYPE_UINT32;
      AStream.WriteBuffer(AType, 1);
      AStream.WriteBuffer(V, 4);
    end
    else
    begin
      AType := TYPE_UINT64;
      AStream.WriteBuffer(AType, 1);
      AStream.WriteBuffer(V, 8);
    end;
  end
  else
  begin
    if V <= -2147483648 then // 64位
    begin
      AType := TYPE_INT64;
      AStream.WriteBuffer(AType, 1);
      AStream.WriteBuffer(V, 8);
    end
    else if V <= -32768 then
    begin
      AType := TYPE_INT32;
      AStream.WriteBuffer(AType, 1);
      AStream.WriteBuffer(V, 4);
    end
    else if V <= -128 then
    begin
      AType := TYPE_INT16;
      AStream.WriteBuffer(AType, 1);
      AStream.WriteBuffer(V, 2);
    end
    else if V < -32 then
    begin
      AType := TYPE_INT8;
      AStream.WriteBuffer(AType, 1);
      AStream.WriteBuffer(V, 1);
    end
    else
    begin
      AType := TYPE_INT4 + (V and $0F);
      AStream.Write(AType, 1);
    end;
  end;
end;

class procedure TQValueHelper.WriteInterval(AStream: TStream; V: TQInterval);
var
  AType: Byte;
begin
  AType := TYPE_INTERVAL;
  AStream.WriteBuffer(AType, 1);
  AStream.WriteBuffer(V, SizeOf(TQInterval));
end;

class procedure TQValueHelper.WriteNull(AStream: TStream);
var
  AType: Byte;
begin
  AType := TYPE_NULL;
  AStream.WriteBuffer(AType, 1);
end;

class procedure TQValueHelper.WriteSingle(AStream: TStream; V: Single);
var
  AType: Byte;
begin
  AType := TYPE_FLOAT32;
  AStream.WriteBuffer(AType, 1);
  AStream.WriteBuffer(V, 4);
end;

class procedure TQValueHelper.WriteStream(AStream, ASource: TStream;
  ACount: Int64);
var
  p: PByte;
  L: Int64;
begin
  if ACount = 0 then
  begin
    ACount := ASource.Size;
    ASource.Position := 0;
  end
  else
  begin
    L := ASource.Size - ASource.Position;
    if ACount > L then
      ACount := L;
  end;
  if ASource is TCustomMemoryStream then
  begin
    p := TCustomMemoryStream(ASource).Memory;
    Inc(p, ASource.Position);
    WriteBinary(AStream, p, ACount);
  end
  else
  begin
    GetMem(p, ACount);
    try
      ASource.ReadBuffer(p^, ACount);
      WriteBinary(AStream, p, ACount);
    finally
      FreeMem(p);
    end;
  end;
end;

class procedure TQValueHelper.WriteString(AStream: TStream; V: QStringW);
var
  L: Integer;
  S: QStringA;
  AType: Byte;
begin
  S := qstring.Utf8Encode(V);
  L := S.Length;
  if (L = 0) or (L < (Length(V) shl 1)) then // UTF8编码更短一些
  begin
    if L < 16 then // 0B
    begin
      AType := TYPE_STR4 + Byte(L);
      AStream.WriteBuffer(AType, 1);
    end
    else if L < 256 then // 1B
    begin
      AType := TYPE_STR8;
      AStream.WriteBuffer(AType, 1);
      AStream.WriteBuffer(L, 1);
    end
    else if L < 65536 then // 2B
    begin
      AType := TYPE_STR16;
      AStream.WriteBuffer(AType, 1);
      AStream.WriteBuffer(L, 2);
    end
    else // 4B
    begin
      AType := TYPE_STR32;
      AStream.WriteBuffer(AType, 1);
      AStream.WriteBuffer(L, 4);
    end;
    if L > 0 then
      AStream.WriteBuffer(PQCharA(S)^, S.Length);
  end
  else // Unicode 编码更短
  begin
    L := Length(V) shl 1;
    if L < 256 then
    begin
      AType := TYPE_USTR8;
      AStream.WriteBuffer(AType, 1);
      AStream.WriteBuffer(L, 1);
    end
    else if L < 65536 then
    begin
      AType := TYPE_USTR16;
      AStream.WriteBuffer(AType, 1);
      AStream.WriteBuffer(L, 2);
    end
    else
    begin
      AType := TYPE_USTR32;
      AStream.WriteBuffer(AType, 1);
      AStream.WriteBuffer(L, 4);
    end;
    AStream.WriteBuffer(PQCharW(V)^, L);
  end;
end;

class procedure TQValueHelper.WriteUnset(AStream: TStream);
var
  AType: Byte;
begin
  AType := TYPE_UNSET;
  AStream.WriteBuffer(AType, 1);
end;

class procedure TQValueHelper.WriteValue(AStream: TStream; const V: TQValue);
begin
  V.SaveToStream(AStream);
end;

end.
