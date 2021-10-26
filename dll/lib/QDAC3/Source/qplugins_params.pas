unit qplugins_params;

interface

uses classes, sysutils, types, qstring, qvalue, qplugins_base, qjson,
  variants{$IFDEF UNICODE},
  Generics.collections, Rtti{$ENDIF};
{$HPPEMIT '#pragma link "qplugins_params"'}
{$REGION History}
{
  Todo:加入只读接口的支持

  修订日志
  ========
  2017.1.5
  * 修正了 AddRange 忘记减少ACount的值的问题（软件高手报告）
}
{$ENDREGION}

type

  // 下面的封装是仅面向Delphi的，以便简化编码
  IQParamHelper = interface(IQParam)
    ['{7E6EF90D-5D88-4734-92C6-CB055F2C0222}']
    function GetUName: QStringW;
    function GetAsUString: QStringW;
    function GetAsDBytes: TBytes;
    function GetAsDVariant: Variant;
    procedure SetAsDBytes(const AValue: TBytes);
    procedure SetAsUString(const S: QStringW);
    procedure SetAsDVariant(const V: Variant);
    property AsString: QStringW read GetAsUString write SetAsUString;
    property AsBytes: TBytes read GetAsDBytes write SetAsDBytes;
    property AsVariant: Variant read GetAsDVariant write SetAsDVariant;
  end;

  IQParamsHelper = interface(IQParams)
    ['{8F199BB7-665B-476E-B5BB-72A813539AF0}']
    function ByName(const AName: QStringW): IQParamHelper;
    function ByPath(APath: QStringW): IQParamHelper;
    function Add(const AName: QStringW; AValue: Int64): Integer; overload;
    function Add(const AName: QStringW; AValue: Double): Integer; overload;
    function Add(const AName: QStringW; AValue: Boolean): Integer; overload;
    function Add(const AName, AValue: QStringW): Integer; overload;
    function Add(const AName: QStringW; AValue: Variant): Integer; overload;
    function Add(const AName: QStringW; AValue: TStream): Integer; overload;
    function Add(const AName: QStringW; const AValue: TBytes): Integer;
      overload;
    function Add(const AName: QStringW; const AValue: PByte; ALen: Integer)
      : Integer; overload;
    function Add(const AName: QStringW; const AValue: TGuid): Integer; overload;
    procedure LoadFromFile(const AFileName: QStringW);
    procedure LoadFromStream(AStream: TStream);
    procedure SaveToFile(const AFileName: QStringW);
    procedure SaveToStream(AStream: TStream);
    procedure ToJson(AJson: TQJson);
  end;

  // 重新实现 TInterfacedObject，以便子类能够重载 QueryInterface 方法
  TQInterfacedObject = class(TInterfacedObject, IInterface)
  protected
    FDisableRefCount: Integer;
  public
    constructor Create; overload; virtual;
    function _AddRef: Integer; virtual; stdcall;
    function _Release: Integer; virtual; stdcall;
    function QueryInterface(const IID: TGuid; out Obj): HRESULT;
      virtual; stdcall;
    function GetOriginPointer: Pointer; stdcall;
    procedure DisableRefCount;
    procedure EnableRefCount;
    function ObjectInstance: TObject;
  end;

  TQUnicodeString = class(TQInterfacedObject, IQString)
  protected
    FValue: QStringW;
    function GetLength: Integer; stdcall;
    procedure SetLength(ALen: Integer); stdcall;
  public
    constructor Create; override;
    constructor Create(const S: QStringW); overload;
    procedure SetValue(const S: PWideChar); stdcall;
    function GetValue: PWideChar; stdcall;
  end;

  TQBytes = class(TQInterfacedObject, IQBytes)
  protected
    FCatHelper: TQBytesCatHelper;
    procedure SetLength(const len: DWORD); stdcall;
    function GetLength: DWORD; stdcall;
    function GetByte(const idx: DWORD; var value: BYTE): Boolean; stdcall;
    function SetByte(const idx: DWORD; const value: BYTE): Boolean; stdcall;
    function GetData: Pointer; stdcall;
    procedure SetCapacity(const len: DWORD); stdcall;
    function GetCapcacity: DWORD; stdcall;
    procedure Append(const src: Pointer; const len: DWORD); stdcall;
    procedure Insert(const idx: DWORD; const src: Pointer;
      const len: DWORD); stdcall;
    procedure Delete(const idx: DWORD; const count: DWORD); stdcall;
    function CopyTo(dest: Pointer; const idx, count: DWORD): DWORD; stdcall;
    procedure Replace(const idx: DWORD; const src: Pointer;
      const len: DWORD); stdcall;
    procedure LoadFromFile(const fileName: PWideChar); stdcall;
    procedure SaveToFile(const fileName: PWideChar); stdcall;
    procedure AppendToFile(const fileName: PWideChar); stdcall;
  public
    constructor Create; override;
    destructor Destroy; override;
  end;
  // Delphi 的流接口与 IQStream 之间的相互转换

  TQStream = class(TStream)
  protected
    FStream: IQStream;
    procedure SetSize(const NewSize: Int64); override;
  public
    constructor Create(AStream: IQStream); overload;
    destructor Destroy; override;
    procedure LoadFromStream(AStream: TStream); overload;
    procedure LoadFromStream(AStream: IQStream); overload;
    procedure LoadFromFile(const AFileName: QStringW);
    procedure SaveToStream(AStream: TStream); overload;
    procedure SaveToStream(AStream: IQStream); overload;
    procedure SaveToFile(const AFileName: QStringW);
    function Read(var Buffer; count: Longint): Longint; override;
    function Write(const Buffer; count: Longint): Longint; override;
    function Seek(const Offset: Int64; Origin: TSeekOrigin): Int64; override;
  end;

  TQStreamHelper = class(TQInterfacedObject, IQStream)
  protected
    FStream: TStream;
    FOwnStream: Boolean;
    function Read(pv: Pointer; cb: Cardinal): Cardinal; stdcall;
    function Write(pv: Pointer; cb: Cardinal): Cardinal; stdcall;
    function Seek(AOffset: Int64; AFrom: BYTE): Int64; stdcall;
    procedure SetSize(ANewSize: UInt64); stdcall;
    function CopyFrom(AStream: IQStream; ACount: Int64): Int64; stdcall;
  public
    constructor Create(AStream: TStream; AOwnStream: Boolean);
    destructor Destroy; override;
  end;

  // 参数接口的实现
  TQParams = class;

  TQParam = class(TQInterfacedObject, IQParam, IQParamHelper)
  protected
    FName: QStringW;
    FType: TQParamType;
    FValue: TQValue;
    FOwner: TQParams;
    function GetName: PWideChar; overload; stdcall;
    function GetUName: QStringW; overload;
    function GetAsInteger: Integer; stdcall;
    procedure SetAsInteger(const AValue: Integer); stdcall;
    function GetAsInt64: Int64; stdcall;
    procedure SetAsInt64(const AValue: Int64); stdcall;
    function GetAsBoolean: Boolean; stdcall;
    procedure SetAsBoolean(const AValue: Boolean); stdcall;
    function GetAsSingle: Single; stdcall;
    procedure SetAsSingle(const AValue: Single); stdcall;
    function GetAsFloat: Double; stdcall;
    procedure SetAsFloat(const AValue: Double); stdcall;
    function GetAsString: IQString; stdcall;
    procedure SetAsString(const AValue: IQString); stdcall;
    function GetAsGuid: TGuid; stdcall;
    procedure SetAsGuid(const value: TGuid); stdcall;
    function GetAsBytes(ABuf: PByte; ABufLen: Cardinal): Cardinal;
      overload; stdcall;
    procedure SetAsBytes(ABuf: PByte; ABufLen: Cardinal); overload; stdcall;
    function GetIsNull: Boolean; stdcall;
    procedure SetNull; stdcall;
    function GetAsArray: IQParams; stdcall;
    function GetAsStream: IQStream; stdcall;
    function GetParent: IQParams; stdcall;
    function GetType: TQParamType; stdcall;
    procedure SetType(const AType: TQParamType); stdcall;
    function GetAsUString: QStringW;
    procedure SetAsUString(const value: QStringW);
    function GetAsDBytes: TBytes;
    procedure SetAsDBytes(const value: TBytes);
    procedure SetAsStream(AStream: IQStream); stdcall;
    function GetAsDVariant: Variant;
    procedure SetAsDVariant(const V: Variant);
    function GetAsInterface: IInterface; stdcall;
    procedure SetAsInterface(const AIntf: IInterface); stdcall;
    function GetIndex: Integer; stdcall;
    function _GetAsArray: StandInterfaceResult; stdcall;
    function _GetAsStream: StandInterfaceResult; stdcall;
    function _GetParent: StandInterfaceResult; overload; stdcall;
    function _GetAsInterface: StandInterfaceResult; overload; stdcall;
    function GetAsBytes: IQBytes; overload; stdcall;
    procedure SetAsBytes(const ABytes: IQBytes); overload; stdcall;
    // 下面的代码为了兼容其它语言加入
    function _GetAsBytes: StandInterfaceResult; overload; stdcall;
  public
    constructor Create(AOwner: TQParams); overload;
    destructor Destroy; override;
    procedure Assign(ASource: IQParam);
    property Name: QStringW read FName write FName;
    property AsInteger: Integer read GetAsInteger write SetAsInteger;
    property AsInt64: Int64 read GetAsInt64 write SetAsInt64;
    property AsBoolean: Boolean read GetAsBoolean write SetAsBoolean;
    property AsSingle: Single read GetAsSingle write SetAsSingle;
    property AsFloat: Double read GetAsFloat write SetAsFloat;
    property AsString: QStringW read GetAsUString write SetAsUString;
    property AsGuid: TGuid read GetAsGuid write SetAsGuid;
    property AsBytes: TBytes read GetAsDBytes write SetAsDBytes;
    property IsNull: Boolean read GetIsNull;
    property AsArray: IQParams read GetAsArray;
    property AsStream: IQStream read GetAsStream;
    property Parent: IQParams read GetParent;
    property DataType: TQParamType read FType write SetType;
  end;

  TQParamString = class(TQInterfacedObject, IQString)
  protected
    FValue: PQValue;
    FText: QStringW;
    procedure SetValue(const S: PWideChar); stdcall;
    function GetValue: PWideChar; stdcall;
    function GetLength: Integer; stdcall;
    procedure SetLength(ALen: Integer); stdcall;
  public
    constructor Create(AValue: PQValue); overload;
    destructor Destroy; override;
  end;

{$IF RTLVersion>=21}

  TQParamList = TList<TQParam>;
{$ELSE}
  TQParamList = TList;
{$IFEND}

  TQParams = class(TQInterfacedObject, IQParams, IQParamsHelper)
  private
    function GetDItems(AIndex: Integer): TQParam;
    procedure SetDItems(AIndex: Integer; const value: TQParam);
  protected
    FItems: TQParamList;
    function GetItems(AIndex: Integer): IQParam; stdcall;
    function GetCount: Integer; stdcall;
    function GetAsString: IQString; stdcall;
    function Add(const AName: PWideChar; AParamType: TQParamType): IQParam;
      overload; stdcall;
    function InternalAdd(const AName: QStringW; AParamType: TQParamType;
      var AResult: TQParam): Integer; overload;
  public
    constructor Create; override;
    destructor Destroy; override;
    function ByName(const AName: PWideChar): IQParam; overload; stdcall;
    function ByPath(APath: PWideChar): IQParam; overload; stdcall;
    function Add(const AName: QStringW; AParamType: TQParamType)
      : TQParam; overload;
    procedure AddRange(AParams: IQParams; AStartIndex, ACount: Integer);
    function Add(AParam: TQParam): Integer; overload;
    function Add(AParam: IQParam): Integer; overload;
    function Add(const AName: PWideChar; AChildren: IQParams): IQParam;
      overload; stdcall;
    procedure Delete(AIndex: Integer); stdcall;
    procedure Clear; stdcall;
    procedure SaveToStream(AStream: TStream); overload;
    procedure SaveToStream(AStream: IQStream); overload; stdcall;
    procedure LoadFromStream(AStream: TStream); overload;
    procedure LoadFromStream(AStream: IQStream); overload; stdcall;
    procedure SaveToFile(const AFileName: PWideChar); overload; stdcall;
    procedure LoadFromFile(const AFileName: PWideChar); overload; stdcall;
    procedure LoadFromFile(const AFileName: QStringW); overload;
    procedure SaveToFile(const AFileName: QStringW); overload;
    function ByName(const AName: QStringW): IQParamHelper; overload;
    function ByPath(APath: QStringW): IQParamHelper; overload;
    function Add(const AName: QStringW; AValue: Int64): Integer; overload;
    function Add(const AName: QStringW; AValue: Double): Integer; overload;
    function Add(const AName: QStringW; AValue: Boolean): Integer; overload;
    function Add(const AName, AValue: QStringW): Integer; overload;
    function Add(const AName: QStringW; AValue: Variant): Integer; overload;
    function Add(const AName: QStringW; AValue: TStream): Integer; overload;
    function Add(const AName: QStringW; const AValue: TBytes): Integer;
      overload;
    function Add(const AName: QStringW; const AValue: PByte; ALen: Integer)
      : Integer; overload;
    function Add(const AName: QStringW; const AValue: TGuid): Integer; overload;
    function IndexOf(const AParam: IQParam): Integer; stdcall;

    function _GetItems(AIndex: Integer): StandInterfaceResult;
      overload; stdcall;
    function _ByName(const AName: PWideChar): StandInterfaceResult; stdcall;
    function _ByPath(APath: PWideChar): StandInterfaceResult; stdcall;
    function _Add(const AName: PWideChar; AParamType: TQParamType)
      : StandInterfaceResult; overload; stdcall;
    function _Add(const AName: PWideChar; AChildren: IQParams)
      : StandInterfaceResult; overload; stdcall;
    function _GetAsString: StandInterfaceResult; stdcall;
    procedure ToJson(AJson: TQJson);
    property Items[AIndex: Integer]: TQParam read GetDItems
      write SetDItems; default;
    property count: Integer read GetCount;
  end;

  // 参数类型名称
const
  ParamTypeNames: array [TQParamType] of QStringW = ('Unknown',
    // Integer Types
    'Shortint', 'Byte', 'Smallint', 'Word', 'Integer', 'DWord', 'Int64',
    'UInt64', 'Single', 'Double', // Float types
    'DateTime', 'Interval', // DateTime types
    'AnsiString', 'Utf8String', 'UnicodeString', // String types
    'Bool', // Boolean
    'Guid', // Guid
    'Binary', // Binary
    'Stream', // 流
    'Array', // Array
    'Interface');
  // IQStream <-> TStream 的简单转换接口
function NewStream(AStream: TStream; AStreamOwner: Boolean): IQStream; overload;
function NewStream(AStream: IQStream): TQStream; overload;

function QStream(AStream: TStream; AStreamOwner: Boolean): IQStream; overload;
{$IF RTLVersion>20}deprecated 'Use NewStream instead'; {$IFEND}
function QStream(AStream: IQStream): TQStream; overload;
{$IF RTLVersion>20}deprecated 'Use NewStream instead'; {$IFEND}
// IQParams 的简单实现
function NewParams(const AValues: array of const): IQParams; overload;
function NewParams: IQParams; overload;

function NewString(const S: QStringW): IQString;
function ParamAsString(AParam: IQParam): QStringW;
function ParamAsBytes(AParam: IQParam): TBytes;
function ParamHelper(AParam: IQParam): IQParamHelper;
function ParamsHelper(AParams: IQParams): IQParamsHelper;
// Interface to object
function InstanceOf(AIntf: IInterface): TObject; overload;
function InstanceOf(AIntf: IInterface; var AObj: TObject): Boolean; overload;
function PointerOf(AIntf: IInterface): Pointer; inline;

implementation

const
  NullChar: QCharW = #0;
  PathDelimiter: PQCharW = '/'; //
  ObjCastGUID: TGuid = '{CEDF24DE-80A4-447D-8C75-EB871DC121FD}';

resourcestring
  // SInvalidName = '无效的结点名称，名称中不能包含 "/"。';
  SCantConvert = '无法转换类型 %s 的值到 %s 。';
  SUnsupportParamArrayItem = '第 %d 个参数类型不受支持。';
  SUnsupportNow = '%s 目前不受支持。';

  // SMismatchServicePath = '请求的服务路径 %s 不存在或类型不匹配。';
type
  TQParamHelper = class(TQInterfacedObject, IQParamHelper)
  protected
    FInterface: IQParam;
    function GetUName: QStringW;
    function GetAsUString: QStringW;
    procedure SetAsUString(const S: QStringW);
    function GetName: PWideChar; stdcall;
    function GetAsInteger: Integer; stdcall;
    procedure SetAsInteger(const AValue: Integer); stdcall;
    function GetAsInt64: Int64; stdcall;
    procedure SetAsInt64(const AValue: Int64); stdcall;
    function GetAsBoolean: Boolean; stdcall;
    procedure SetAsBoolean(const AValue: Boolean); stdcall;
    function GetAsSingle: Single; stdcall;
    procedure SetAsSingle(const AValue: Single); stdcall;
    function GetAsFloat: Double; stdcall;
    procedure SetAsFloat(const AValue: Double); stdcall;
    function GetAsString: IQString; stdcall;
    procedure SetAsString(const AValue: IQString); stdcall;
    function GetAsGuid: TGuid; stdcall;
    procedure SetAsGuid(const value: TGuid); stdcall;
    function GetAsBytes(ABuf: PByte; ABufLen: Cardinal): Cardinal;
      overload; stdcall;
    procedure SetAsBytes(ABuf: PByte; ABufLen: Cardinal); overload; stdcall;
    function GetIsNull: Boolean; stdcall;
    procedure SetNull; stdcall;
    function GetAsArray: IQParams; stdcall;
    function GetAsStream: IQStream; stdcall;
    procedure SetAsStream(AStream: IQStream); stdcall;
    function GetParent: IQParams; stdcall;
    function GetType: TQParamType; stdcall;
    procedure SetType(const AType: TQParamType); stdcall;
    function GetAsDBytes: TBytes;
    procedure SetAsDBytes(const AValue: TBytes);
    function GetAsDVariant: Variant;
    procedure SetAsDVariant(const V: Variant);
    function GetAsInterface: IInterface; stdcall;
    procedure SetAsInterface(const AIntf: IInterface); stdcall;
    function GetIndex: Integer; stdcall;
    function _GetAsArray: StandInterfaceResult; stdcall;
    function _GetAsStream: StandInterfaceResult; stdcall;
    function _GetParent: StandInterfaceResult; overload; stdcall;
    function _GetAsInterface: StandInterfaceResult; overload; stdcall;
    function GetAsBytes: IQBytes; overload; stdcall;
    procedure SetAsBytes(const ABytes: IQBytes); overload; stdcall;
    function _GetAsBytes: StandInterfaceResult; overload; stdcall;
  public
    constructor Create(AIntf: IQParam);
  end;

  TQParamsHelper = class(TQInterfacedObject, IQParamsHelper)
  protected
    FInterface: IQParams;
    function GetItems(AIndex: Integer): IQParam; stdcall;
    function GetCount: Integer; stdcall;
    function ByName(const AName: PWideChar): IQParam; overload; stdcall;
    function ByPath(APath: PWideChar): IQParam; overload; stdcall;
    function Add(const AName: PWideChar; AParamType: TQParamType): IQParam;
      overload; stdcall;
    function GetAsString: IQString; stdcall;
    procedure Delete(AIndex: Integer); stdcall;
    procedure Clear; stdcall;
    procedure SaveToStream(AStream: IQStream); overload; stdcall;
    procedure LoadFromStream(AStream: IQStream); overload; stdcall;
    procedure SaveToFile(const AFileName: PWideChar); overload; stdcall;
    procedure LoadFromFile(const AFileName: PWideChar); overload; stdcall;
    procedure LoadFromFile(const AFileName: QStringW); overload;
    procedure LoadFromStream(AStream: TStream); overload;
    procedure SaveToFile(const AFileName: QStringW); overload;
    procedure SaveToStream(AStream: TStream); overload;
    function ByName(const AName: QStringW): IQParamHelper; overload;
    function ByPath(APath: QStringW): IQParamHelper; overload;
    function Add(const AName: QStringW; AValue: Int64): Integer; overload;
    function Add(const AName: QStringW; AValue: Double): Integer; overload;
    function Add(const AName: QStringW; AValue: Boolean): Integer; overload;
    function Add(const AName, AValue: QStringW): Integer; overload;
    function Add(const AName: QStringW; AValue: Variant): Integer; overload;
    function Add(const AName: QStringW; AValue: TStream): Integer; overload;
    function Add(const AName: QStringW; const AValue: TBytes): Integer;
      overload;
    function Add(const AName: QStringW; const AValue: TGuid): Integer; overload;
    function Add(const AName: QStringW; const AValue: PByte; ALen: Integer)
      : Integer; overload;
    function Add(const AName: PWideChar; AChildren: IQParams): IQParam;
      overload; stdcall;
    function IndexOf(const AParam: IQParam): Integer; stdcall;
    function _GetItems(AIndex: Integer): StandInterfaceResult;
      overload; stdcall;
    function _ByName(const AName: PWideChar): StandInterfaceResult; stdcall;
    function _ByPath(APath: PWideChar): StandInterfaceResult; stdcall;
    function _Add(const AName: PWideChar; AParamType: TQParamType)
      : StandInterfaceResult; overload; stdcall;
    function _Add(const AName: PWideChar; AChildren: IQParams)
      : StandInterfaceResult; overload; stdcall;
    function _GetAsString: StandInterfaceResult; stdcall;
  public
    constructor Create(AIntf: IQParams);
    procedure ToJson(AJson: TQJson);
  end;

function PointerOf(AIntf: IInterface): Pointer; inline;
begin
  if Assigned(AIntf) then
  begin
    AIntf._AddRef;
    Result := Pointer(AIntf);
  end
  else
    Result := nil;
end;

function InstanceOf(AIntf: IInterface): TObject;
var
  ATemp: Pointer;
begin
  ATemp := nil;
  if Assigned(AIntf) and (AIntf.QueryInterface(ObjCastGUID, IInterface(ATemp))
    = S_OK) then
    Result := TObject(ATemp)
  else
    Result := nil;
end;

function InstanceOf(AIntf: IInterface; var AObj: TObject): Boolean;
begin
  AObj := InstanceOf(AIntf);
  Result := Assigned(AObj);
end;

function ParamHelper(AParam: IQParam): IQParamHelper;
begin
  if Assigned(AParam) then
  begin
    if not Supports(AParam, IQParamHelper, Result) then
      Result := TQParamHelper.Create(AParam);
  end
  else
    Result := nil;
end;

function ParamsHelper(AParams: IQParams): IQParamsHelper;
begin
  if Assigned(AParams) then
  begin
    if not Supports(AParams, IQParamsHelper, Result) then
      Result := TQParamsHelper.Create(AParams);
  end
  else
    Result := nil;
end;

procedure ParamsToJson(AParams: IQParams; AParent: TQJson);
var
  I: Integer;
  AParam: IQParam;
  ABytes: TBytes;
  function IsArray: Boolean;
  var
    J: Integer;
  begin
    Result := True;
    for J := 0 to AParams.Count - 1 do
    begin
      if Assigned(AParams[J].Name) and (AParams[J].Name^<>#0) then
      begin
        Result := false;
        Break;
      end;
    end;
  end;

begin
  if IsArray then
    AParent.DataType := jdtArray;
  for I := 0 to AParams.Count - 1 do
  begin
    AParam := AParams[I];
    case AParam.ParamType of
      ptInt8, ptUInt8, ptInt16, ptUInt16, ptInt32, ptUInt32, ptInt64, ptUInt64:
        AParent.Add(AParam.Name).AsInt64 := AParam.AsInt64;
      ptFloat4, ptFloat8:
        AParent.Add(AParam.Name).AsFloat := AParam.AsFloat;
      ptDateTime:
        AParent.Add(AParam.Name).AsDateTime := AParam.AsFloat;
      ptInterval, ptAnsiString, ptUtf8String, ptUnicodeString:
        AParent.Add(AParam.Name).AsString := AParam.AsString.Value;
      ptBoolean:
        AParent.Add(AParam.Name).AsBoolean := AParam.AsBoolean;
      ptGuid:
        AParent.Add(AParam.Name).AsString := GuidToString(AParam.AsGuid);
      ptBytes:
        begin
          SetLength(ABytes, AParam.GetAsBytes(nil, 0));
          if Length(ABytes) > 0 then
          begin
            AParam.GetAsBytes(@ABytes[0], Length(ABytes));
            AParent.Add(AParam.Name).AsBytes := ABytes;
          end;
        end;
      ptStream:
        AParent.Add(AParam.Name).ValueFromStream(NewStream(AParam.AsStream), 0);
      ptArray:
        ParamsToJson(AParam.AsArray, AParent.Add(AParam.Name));
      ptInterface: // Unsupport
        ;
    end;
  end;
end;

{ TQInterfacedObject }

constructor TQInterfacedObject.Create;
begin
  inherited;
end;

procedure TQInterfacedObject.DisableRefCount;
begin
  AtomicIncrement(FDisableRefCount);
end;

procedure TQInterfacedObject.EnableRefCount;
begin
  AtomicDecrement(FDisableRefCount);
end;

function TQInterfacedObject.GetOriginPointer: Pointer;
begin
  Result := Self;
end;

function TQInterfacedObject.ObjectInstance: TObject;
begin
  Result := Self;
end;

function TQInterfacedObject.QueryInterface(const IID: TGuid; out Obj): HRESULT;
begin
  Result := inherited;
  if Result <> 0 then
  begin
    if SameId(IID, ObjCastGUID) then
    begin
      Pointer(Obj) := Self;
      Result := 0;
    end
    else
      Result := E_NOINTERFACE;
  end;
end;

function TQInterfacedObject._AddRef: Integer;
begin
  if FDisableRefCount = 0 then
    Result := inherited
  else
    Result := -1;
end;

function TQInterfacedObject._Release: Integer;
begin
  if FDisableRefCount = 0 then
    Result := inherited
  else
    Result := -1;
end;

{ TQStream }

constructor TQStream.Create(AStream: IQStream);
begin
  inherited Create;
  FStream := AStream;
end;

destructor TQStream.Destroy;
begin
  FStream := nil;
  inherited;
end;

procedure TQStream.LoadFromFile(

  const AFileName: QStringW);
var
  AStream: TStream;
begin
  AStream := TFileStream.Create(AFileName, fmOpenRead);
  try
    LoadFromStream(AStream);
  finally
    FreeAndNil(AStream);
  end;
end;

procedure TQStream.LoadFromStream(AStream: IQStream);
begin
  FStream.CopyFrom(AStream, AStream.Seek(0, soFromEnd) - AStream.Seek(0,
    soFromCurrent));
end;

procedure TQStream.LoadFromStream(AStream: TStream);
begin
  CopyFrom(AStream, AStream.size - AStream.Position);
end;

function TQStream.Read(var Buffer; count: Longint): Longint;
begin
  Result := FStream.Read(@Buffer, count);
end;

procedure TQStream.SaveToFile(const AFileName: QStringW);
var
  AStream: TStream;
begin
  AStream := TFileStream.Create(AFileName, fmCreate);
  try
    SaveToStream(AStream);
  finally
    FreeAndNil(AStream);
  end;
end;

procedure TQStream.SaveToStream(AStream: IQStream);
begin
  AStream.CopyFrom(FStream, size - Position);
end;

procedure TQStream.SaveToStream(AStream: TStream);
begin
  AStream.CopyFrom(Self, size - Position);
end;

function TQStream.Seek(const Offset: Int64; Origin: TSeekOrigin): Int64;
begin
  Result := FStream.Seek(Offset, BYTE(Origin));
end;

procedure TQStream.SetSize(const NewSize: Int64);
begin
  FStream.SetSize(NewSize);
end;

function TQStream.Write(const Buffer; count: Longint): Longint;
begin
  Result := FStream.Write(@Buffer, count);
end;

{ TQStreamHelper }

function TQStreamHelper.CopyFrom(AStream: IQStream; ACount: Int64): Int64;
const
  MaxBufSize = $F000;
var
  BufSize, N, W: Integer;
  Buffer: TBytes;
begin
  if ACount <= 0 then
  begin
    ACount := AStream.Seek(0, soFromEnd);
    AStream.Seek(0, soFromBeginning);
  end;
  Result := ACount;
  if ACount > MaxBufSize then
    BufSize := MaxBufSize
  else
    BufSize := ACount;
  SetLength(Buffer, BufSize);
  try
    while ACount <> 0 do
    begin
      if ACount > BufSize then
        N := BufSize
      else
        N := ACount;
      N := AStream.Read(@Buffer[0], N);
      W := 0;
      while N > W do
        Inc(W, Write(@Buffer[W], N - W));
      Dec(ACount, N);
    end;
  finally
    SetLength(Buffer, 0);
  end;
end;

constructor TQStreamHelper.Create(AStream: TStream; AOwnStream: Boolean);
begin
  inherited Create;
  FStream := AStream;
  FOwnStream := AOwnStream;
end;

destructor TQStreamHelper.Destroy;
begin
  if FOwnStream then
    FreeAndNil(FStream);
  inherited;
end;

function TQStreamHelper.Read(pv: Pointer; cb: Cardinal): Cardinal;
begin
  Result := FStream.Read(pv^, cb);
end;

function TQStreamHelper.Seek(AOffset: Int64; AFrom: BYTE): Int64;
begin
  Result := FStream.Seek(AOffset, TSeekOrigin(AFrom));
end;

procedure TQStreamHelper.SetSize(ANewSize: UInt64);
begin
  FStream.size := ANewSize;
end;

function TQStreamHelper.Write(pv: Pointer; cb: Cardinal): Cardinal;
begin
  Result := FStream.Write(pv^, cb);
end;

function NewStream(AStream: TStream; AStreamOwner: Boolean): IQStream;
begin
  Result := TQStreamHelper.Create(AStream, AStreamOwner);
end;

function NewStream(AStream: IQStream): TQStream;
begin
  Result := TQStream.Create(AStream);
end;

function QStream(AStream: TStream; AStreamOwner: Boolean): IQStream;
begin
  Result := TQStreamHelper.Create(AStream, AStreamOwner);
end;

function QStream(AStream: IQStream): TQStream;
begin
  Result := TQStream.Create(AStream);
end;

function NewString(const S: QStringW): IQString;
begin
  Result := TQUnicodeString.Create(S);
end;

{ TQParam }

procedure TQParam.Assign(ASource: IQParam);
  procedure AssignArray;
  var
    ASourceParams: IQParams;
    ATargetParams: TQParams;
  begin
    FValue.TypeNeeded(vdtInt64);
    IQParams(FValue.value.AsPointer) := nil;
    ASourceParams := ASource.AsArray;
    if Assigned(ASourceParams) then
    begin
      ATargetParams := TQParams.Create;
      ATargetParams.AddRange(ASourceParams, 0, ASourceParams.count);
      IQParams(FValue.value.AsPointer) := ATargetParams;
    end;
  end;

begin
  case ASource.ParamType of
    ptInt8, ptUInt8, ptInt16, ptUInt16, ptInt32:
      begin
        FValue.TypeNeeded(vdtInteger);
        FValue.AsInteger := ASource.AsInteger;
      end;
    ptUInt32, ptInt64, ptUInt64:
      begin
        FValue.TypeNeeded(vdtInt64);
        FValue.AsInt64 := ASource.AsInt64;
      end;
    ptFloat4:
      begin
        FValue.TypeNeeded(vdtSingle);
        FValue.AsSingle := ASource.AsSingle;
      end;
    ptFloat8:
      begin
        FValue.TypeNeeded(vdtFloat);
        FValue.AsFloat := ASource.AsFloat;
      end;
    ptDateTime:
      begin
        FValue.TypeNeeded(vdtDateTime);
        FValue.AsDateTime := ASource.AsFloat;
      end;
    ptInterval:
      begin
        FValue.TypeNeeded(vdtInterval);
        FValue.AsInterval.AsString := ParamAsString(ASource);
      end;
    ptAnsiString, ptUtf8String, ptUnicodeString:
      begin
        FValue.TypeNeeded(vdtString);
        FValue.AsString := ParamAsString(ASource);
      end;
    ptBoolean:
      begin
        FValue.TypeNeeded(vdtBoolean);
        FValue.AsBoolean := ASource.AsBoolean;
      end;
    ptGuid:
      begin
        FValue.TypeNeeded(vdtGuid);
        FValue.AsGuid := ASource.AsGuid;
      end;
    ptBytes:
      begin
        AsBytes := ParamAsBytes(ASource);
      end;
    ptStream:
      begin
        SetAsStream(ASource.AsStream);
      end;
    ptArray:
      AssignArray;
  end;
end;

constructor TQParam.Create(AOwner: TQParams);
begin
  inherited Create;
  FOwner := AOwner;
end;

destructor TQParam.Destroy;
begin
  SetNull;
  inherited;
end;

function TQParam.GetAsArray: IQParams;
begin
  if FType = ptArray then
    Result := IQParams(FValue.value.AsPointer)
  else
    raise QException.CreateFmt(SCantConvert, [ParamTypeNames[FType],
      ParamTypeNames[ptArray]]);
end;

function TQParam.GetAsBoolean: Boolean;
begin
  Result := FValue.AsBoolean;
end;

function TQParam.GetAsBytes: IQBytes;
begin
  // Result:=TQBytes.
end;

function TQParam.GetAsBytes(ABuf: PByte; ABufLen: Cardinal): Cardinal;
var
  ATemp: TBytes;
  procedure StreamToBytes;
  var
    AStream: IQStream;
  begin
    AStream := AsStream;
    SetLength(ATemp, AStream.Seek(0, soFromEnd));
    AStream.Seek(0, soFromBeginning);
    AStream.Read(@ATemp[0], Length(ATemp));
  end;
  procedure ArrayToBytes;
  var
    AStream: TMemoryStream;
  begin
    AStream := TMemoryStream.Create;
    try
      AsArray.SaveToStream(NewStream(AStream, False));
      SetLength(ATemp, AStream.size);
      AStream.Position := 0;
      AStream.Read(ATemp[0], Length(ATemp));
    finally
      FreeObject(AStream);
    end;
  end;

begin
  case FType of
    ptStream:
      StreamToBytes;
    ptArray:
      ArrayToBytes
  else
    ATemp := FValue.AsBytes;
  end;
  if (ABuf = nil) or (ABufLen = 0) then
    Result := Length(ATemp)
  else
  begin
    if ABufLen > Cardinal(Length(ATemp)) then
      Result := Length(ATemp)
    else
      Result := ABufLen;
    if Result > 0 then
      Move(ATemp[0], ABuf, Result);
  end;
end;

function TQParam.GetAsDBytes: TBytes;
begin
  Result := FValue.AsBytes;
end;

function TQParam.GetAsDVariant: Variant;
  procedure StreamToVar;
  var
    AStream: IQStream;
    ASize: Int64;
  begin
    AStream := AsStream;
    if Assigned(AStream) then
    begin
      ASize := AStream.Seek(0, soFromEnd);
      if ASize > 0 then
      begin
        Result := VarArrayCreate([0, ASize - 1], varByte);
        AStream.Seek(0, soFromBeginning);
        AStream.Read(VarArrayLock(Result), ASize);
        VarArrayUnlock(Result);
      end
      else
        Result := Null;
    end
    else
      Result := Null;
  end;
  procedure ArrayToVar;
  var
    I: Integer;
    AItems: IQParams;
  begin
    AItems := AsArray;
    if AItems.count > 0 then
    begin
      Result := VarArrayCreate([0, AItems.count - 1], varVariant);
      for I := 0 to AItems.count - 1 do
        Result[I] := ParamHelper(AItems[I]).AsVariant;
    end
    else
      Result := Null;
  end;

begin
  if FType = ptStream then
    StreamToVar
  else if FType = ptArray then
    ArrayToVar
  else
    Result := FValue.AsVariant;
end;

function TQParam.GetAsFloat: Double;
begin
  Result := FValue.AsFloat;
end;

function TQParam.GetAsGuid: TGuid;
begin
  Result := FValue.AsGuid;
end;

function TQParam.GetAsInt64: Int64;
begin
  Result := FValue.AsInt64;
end;

function TQParam.GetAsInteger: Integer;
begin
  Result := AsInt64;
end;

function TQParam.GetAsInterface: IInterface;
begin
  if FType in [ptInterface, ptStream, ptBytes] then
    Result := IInterface(FValue.value.AsPointer)
  else
    raise QException.CreateFmt(SCantConvert, [ParamTypeNames[FType],
      ParamTypeNames[ptInt64]]);
end;

function TQParam.GetAsSingle: Single;
begin
  Result := AsFloat;
end;

function TQParam.GetAsStream: IQStream;
begin
  if FType = ptStream then
    Result := IQStream(FValue.value.AsPointer)
  else
    raise QException.CreateFmt(SCantConvert, [ParamTypeNames[FType],
      ParamTypeNames[ptInt64]]);
end;

function TQParam.GetAsString: IQString;
begin
  if FType = ptArray then
    Result := AsArray.AsString
  else
    Result := TQParamString.Create(@FValue);
end;

function TQParam.GetAsUString: QStringW;
begin
  case FType of
    ptBytes, ptStream:
      Result := BinToHex(AsBytes);
    ptArray:
      Result := AsArray.AsString.value
      // 格式化为JSON字符串
  else
    Result := FValue.AsString;
  end;
end;

function TQParam.GetIndex: Integer;
begin
  if Assigned(Parent) then
    Result := Parent.IndexOf(Self)
  else
    Result := -1;
end;

function TQParam.GetIsNull: Boolean;
begin
  Result := FValue.IsNull;
end;

function TQParam.GetUName: QStringW;
begin
  Result := FName;
end;

function TQParam.GetName: PWideChar;
begin
  Result := PQCharW(FName);
end;

function TQParam.GetParent: IQParams;
begin
  Result := FOwner;
end;

function TQParam.GetType: TQParamType;
begin
  Result := FType;
end;

procedure TQParam.SetAsBoolean(const AValue: Boolean);
begin
  FValue.AsBoolean := AValue;
end;

procedure TQParam.SetAsBytes(const ABytes: IQBytes);
begin

end;

procedure TQParam.SetAsBytes(ABuf: PByte; ABufLen: Cardinal);
var
  ATemp: TBytes;
begin
  SetLength(ATemp, ABufLen);
  if ABufLen > 0 then
    Move(ABuf^, ATemp[0], ABufLen);
  FValue.AsBytes := ATemp;
end;

procedure TQParam.SetAsDBytes(const value: TBytes);
begin
  FValue.AsBytes := value;
end;

procedure TQParam.SetAsDVariant(const V: Variant);
  procedure FromVar;
  begin
    raise Exception.CreateFmt(SUnsupportNow, ['TQParam.SetAsDVaraint.FromVar']);
  end;

  procedure ToBytes;
  begin
    raise Exception.CreateFmt(SUnsupportNow, ['TQParam.SetAsDVaraint.FromVar']);
  end;
  procedure ToStream;
  begin
    raise Exception.CreateFmt(SUnsupportNow, ['TQParam.SetAsDVaraint.FromVar']);
  end;
  procedure ToArray;
  begin
    raise Exception.CreateFmt(SUnsupportNow, ['TQParam.SetAsDVaraint.FromVar']);
  end;

begin
  case FType of
    ptUnknown:
      FromVar;
    ptInt8, ptUInt8, ptInt16, ptUInt16, ptInt32:
      begin
        FValue.TypeNeeded(vdtInteger);
        FValue.AsInteger := V;
      end;
    ptUInt32, ptInt64, ptUInt64:
      begin
        FValue.TypeNeeded(vdtInt64);
        FValue.AsInt64 := V;
      end;
    ptFloat4:
      begin
        FValue.TypeNeeded(vdtSingle);
        FValue.AsSingle := V;
      end;
    ptFloat8:
      begin
        FValue.TypeNeeded(vdtFloat);
        FValue.AsFloat := V;
      end;
    ptDateTime:
      begin
        FValue.TypeNeeded(vdtDateTime);
        FValue.AsDateTime := V;
      end;
    ptInterval:
      begin
        FValue.TypeNeeded(vdtInterval);
        FValue.AsInt64 := V;
      end;
    ptAnsiString, ptUtf8String, ptUnicodeString:
      begin
        FValue.TypeNeeded(vdtString);
        FValue.AsString := V;
      end;
    ptBoolean:
      begin
        FValue.TypeNeeded(vdtBoolean);
        FValue.AsBoolean := V;
      end;
    ptGuid:
      begin
        FValue.TypeNeeded(vdtGuid);
        FValue.AsGuid := StringToGuid(V);
      end;
    ptBytes:
      ToBytes;
    ptStream:
      ToStream;
    ptArray:
      ToArray;
  end;
end;

procedure TQParam.SetAsFloat(const AValue: Double);
begin
  FValue.AsFloat := AValue;
end;

procedure TQParam.SetAsGuid(const value: TGuid);
begin
  FValue.AsGuid := value;
end;

procedure TQParam.SetAsInt64(const AValue: Int64);
begin
  FValue.AsInt64 := AValue;
end;

procedure TQParam.SetAsInteger(const AValue: Integer);
begin
  FValue.AsInteger := AValue;
end;

procedure TQParam.SetAsInterface(const AIntf: IInterface);
begin
  FValue.TypeNeeded(vdtInt64);
  IInterface(FValue.value.AsPointer) := AIntf;
end;

procedure TQParam.SetAsSingle(const AValue: Single);
begin
  FValue.AsSingle := AValue;
end;

procedure TQParam.SetAsStream(AStream: IQStream);
begin
  FValue.TypeNeeded(vdtInt64);
  IQStream(FValue.value.AsPointer) := AStream;
end;

procedure TQParam.SetAsString(const AValue: IQString);
var
  S: QStringW;
begin
  SetLength(S, AValue.Length);
  Move(AValue.value^, PWideChar(S)^, AValue.Length shl 1);
  FValue.AsString := S;
end;

procedure TQParam.SetAsUString(const value: QStringW);
begin
  FValue.AsString := value;
end;

procedure TQParam.SetNull;
begin
  case FType of
    ptInterface:
      IInterface(FValue.value.AsPointer) := nil;
    ptBytes, ptStream:
      IQStream(FValue.value.AsPointer) := nil;
    ptArray:
      IQParams(FValue.value.AsPointer) := nil
  else
    FValue.Reset;
  end;
end;

procedure TQParam.SetType(const AType: TQParamType);
begin
  if AType <> FType then
  begin
    if FType = ptArray then
      IQParams(FValue.value.AsPointer) := nil;
    FType := AType;
    case AType of
      ptUnknown:
        FValue.Reset;
      ptInt8, ptUInt8, ptInt16, ptUInt16, ptInt32:
        FValue.TypeNeeded(vdtInteger);
      ptUInt32, ptInt64, ptUInt64:
        FValue.TypeNeeded(vdtInt64);
      ptFloat4:
        FValue.TypeNeeded(vdtSingle);
      ptFloat8:
        FValue.TypeNeeded(vdtFloat);
      ptDateTime:
        FValue.TypeNeeded(vdtDateTime);
      ptInterval:
        FValue.TypeNeeded(vdtInterval);
      ptAnsiString, ptUtf8String, ptUnicodeString:
        FValue.TypeNeeded(vdtString);
      ptBoolean:
        FValue.TypeNeeded(vdtBoolean);
      ptGuid:
        FValue.TypeNeeded(vdtGuid);
      ptBytes, ptStream:
        IQStream(FValue.value.AsPointer) :=
          NewStream(TMemoryStream.Create, True);
      ptArray:
        begin
          FValue.Reset;
          IQParams(FValue.value.AsPointer) := TQParams.Create;
        end;
    end;
  end;
end;

function TQParam._GetAsArray: StandInterfaceResult;
begin
  Result := PointerOf(GetAsArray);
end;

function TQParam._GetAsBytes: StandInterfaceResult;
begin
  Result := PointerOf(GetAsBytes);
end;

function TQParam._GetAsInterface: StandInterfaceResult;
begin
  Result := PointerOf(GetAsInterface);
end;

function TQParam._GetAsStream: StandInterfaceResult;
begin
  Result := PointerOf(GetAsStream);
end;

function TQParam._GetParent: StandInterfaceResult;
begin
  Result := PointerOf(GetParent);
end;

{ TQParams }

function TQParams.Add(const AName: PWideChar; AParamType: TQParamType): IQParam;
begin
  Result := Add(QStringW(AName), AParamType);
end;

function TQParams.Add(AParam: TQParam): Integer;
begin
  AParam._AddRef;
  Result := FItems.Add(AParam);
end;

function TQParams.Add(AParam: IQParam): Integer;
var
  AItem: TQParam;
begin
  AItem := TQParam.Create(Self);
  AItem.Assign(AParam);
  Result := Add(AItem);
end;

function TQParams.Add(const AName: QStringW; AValue: Boolean): Integer;
var
  AParam: TQParam;
begin
  Result := InternalAdd(AName, ptBoolean, AParam);
  AParam.AsBoolean := AValue;
end;

function TQParams.Add(const AName, AValue: QStringW): Integer;
var
  AParam: TQParam;
begin
  Result := InternalAdd(AName, ptUnicodeString, AParam);
  AParam.SetAsString(NewString(AValue));
end;

function TQParams.Add(const AName: QStringW; AValue: Int64): Integer;
var
  AParam: TQParam;
begin
  Result := InternalAdd(AName, ptInt64, AParam);
  AParam.AsInt64 := AValue;
end;

function TQParams.Add(const AName: QStringW; AValue: Double): Integer;
var
  AParam: TQParam;
begin
  Result := InternalAdd(AName, ptFloat8, AParam);
  AParam.AsFloat := AValue;
end;

function TQParams.Add(const AName: QStringW; AValue: Variant): Integer;
var
  AParam: TQParam;
begin
  case VarType(AValue) of
    varSmallInt:
      begin
        Result := InternalAdd(AName, ptInt16, AParam);
        AParam.AsInteger := AValue;
      end;
    varInteger, varError:
      begin
        Result := InternalAdd(AName, ptInt32, AParam);
        AParam.AsInteger := AValue;
      end;
    varSingle:
      begin
        Result := InternalAdd(AName, ptFloat4, AParam);
        AParam.AsSingle := AValue;
      end;
    varDouble, varCurrency:
      begin
        Result := InternalAdd(AName, ptFloat8, AParam);
        AParam.AsFloat := AValue;
      end;
    varDate:
      begin
        Result := InternalAdd(AName, ptDateTime, AParam);
        AParam.AsFloat := AValue;
      end;
    varOleStr:
      begin
        Result := InternalAdd(AName, ptUnicodeString, AParam);
        AParam.AsString := AValue;
      end;
    varBoolean:
      begin
        Result := InternalAdd(AName, ptBoolean, AParam);
        AParam.AsBoolean := AValue;
      end;
    varShortInt:
      begin
        Result := InternalAdd(AName, ptInt8, AParam);
        AParam.AsInteger := AValue;
      end;
    varByte:
      begin
        Result := InternalAdd(AName, ptUInt8, AParam);
        AParam.AsInteger := AValue;
      end;
    varWord:
      begin
        Result := InternalAdd(AName, ptUInt16, AParam);
        AParam.AsInteger := AValue;
      end;
    varLongWord:
      begin
        Result := InternalAdd(AName, ptUInt32, AParam);
        AParam.AsInt64 := AValue;
      end;
    varInt64:
      begin
        Result := InternalAdd(AName, ptInt64, AParam);
        AParam.AsInt64 := AValue;
      end;
{$IF RtlVersion>=26}
    varUInt64:
      begin
        Result := InternalAdd(AName, ptUInt64, AParam);
        AParam.AsInt64 := AValue;
      end;
{$IFEND}
    varString{$IFDEF UNICODE}, varUString{$ENDIF}:
      begin
        Result := InternalAdd(AName, ptUnicodeString, AParam);
        AParam.AsString := AValue;
      end
  else
    raise QException.CreateFmt(SUnsupportNow,
      ['VarType ' + IntToStr(VarType(AValue))]);
  end;
end;

function TQParams.Add(const AName: QStringW; const AValue: PByte;
  ALen: Integer): Integer;
var
  AParam: TQParam;
begin
  Result := InternalAdd(AName, ptBytes, AParam);
  AParam.SetAsBytes(AValue, ALen);
end;

function TQParams.Add(const AName: QStringW; const AValue: TGuid): Integer;
var
  AParam: TQParam;
begin
  Result := InternalAdd(AName, ptGuid, AParam);
  AParam.AsGuid := AValue;
end;

function TQParams.Add(const AName: PWideChar; AChildren: IQParams): IQParam;
var
  I: Integer;
  ATemp: IQParams;
  AParam: IQParam;
  ABytes: TBytes;
begin
  Result := Add(AName, ptArray);
  ATemp := Result.AsArray;
  for I := 0 to AChildren.count - 1 do
  begin
    AParam := AChildren[I];
    case AParam.ParamType of
      ptInt8, ptUInt8, ptInt16, ptUInt16, ptInt32, ptUInt32:
        ATemp.Add(AParam.Name, AParam.ParamType).AsInteger := AParam.AsInteger;
      ptInt64, ptUInt64:
        ATemp.Add(AParam.Name, AParam.ParamType).AsInt64 := AParam.AsInt64;
      ptFloat4:
        ATemp.Add(AParam.Name, AParam.ParamType).AsSingle := AParam.AsSingle;
      ptFloat8:
        ATemp.Add(AParam.Name, AParam.ParamType).AsFloat := AParam.AsFloat;
      ptDateTime:
        ATemp.Add(AParam.Name, AParam.ParamType).AsFloat := AParam.AsFloat;
      ptInterval:
        ATemp.Add(AParam.Name, AParam.ParamType).AsInt64 := AParam.AsInt64;
      ptAnsiString, ptUtf8String, ptUnicodeString:
        ATemp.Add(AParam.Name, AParam.ParamType).AsString := AParam.AsString;
      ptBoolean:
        ATemp.Add(AParam.Name, AParam.ParamType).AsBoolean := AParam.AsBoolean;
      ptGuid:
        ATemp.Add(AParam.Name, AParam.ParamType).AsGuid := AParam.AsGuid;
      ptBytes:
        begin
          SetLength(ABytes, AParam.GetAsBytes(nil, 0));
          if Length(ABytes) > 0 then
            AParam.GetAsBytes(@ABytes[0], Length(ABytes));
          ATemp.Add(AParam.Name, AParam.ParamType).SetAsBytes(@ABytes[0],
            Length(ABytes));
        end;
      ptStream:
        ATemp.Add(AParam.Name, AParam.ParamType).AsStream := AParam.AsStream;
      ptArray:
        ATemp.Add(AParam.Name, AParam.AsArray);
      ptInterface:
        ATemp.Add(AParam.Name, AParam.ParamType).AsInterface :=
          AParam.AsInterface;
    end;
  end;
end;

function TQParams.Add(const AName: QStringW; AValue: TStream): Integer;
var
  AParam: TQParam;
begin
  Result := InternalAdd(AName, ptStream, AParam);
  AParam.SetAsStream(NewStream(AValue, True));
end;

function TQParams.Add(const AName: QStringW; const AValue: TBytes): Integer;
var
  AParam: TQParam;
begin
  Result := InternalAdd(AName, ptBytes, AParam);
  if Length(AValue) > 0 then
    AParam.SetAsBytes(@AValue[0], Length(AValue));
end;

procedure TQParams.AddRange(AParams: IQParams; AStartIndex, ACount: Integer);
begin
  while ACount > 0 do
  begin
    Add(AParams[AStartIndex]);
    Inc(AStartIndex);
    Dec(ACount);
  end;
end;

function TQParams.Add(const AName: QStringW; AParamType: TQParamType): TQParam;
var
  AParam: TQParam;
begin
  AParam := TQParam.Create(Self);
  AParam.FName := AName;
  AParam.DataType := AParamType;
  Add(AParam);
  Result := AParam;
end;

function TQParams.ByName(const AName: PWideChar): IQParam;
var
  I: Integer;
begin
  Result := nil;
  for I := 0 to FItems.count - 1 do
  begin
    if Items[I].Name = AName then
    begin
      Result := Items[I];
      Break;
    end;
  end;
end;

function TQParams.ByPath(APath: PWideChar): IQParam;
var
  AParent: TQParams;
  AName: QStringW;
begin
  AParent := Self;
  Result := nil;
  if Assigned(APath) then
  begin
    if APath^ = PathDelimiter^ then
      Inc(APath);
    while APath^ <> #0 do
    begin
      AName := DecodeTokenW(APath, PathDelimiter, NullChar, False);
      if Length(AName) > 0 then
      begin
        Result := AParent.ByName(PQCharW(AName));
        if Result.ParamType = ptArray then
          AParent := InstanceOf(Result) as TQParams
          // TQParams
        else
          Break;
      end;
    end;
    if APath^ <> NullChar then
      Result := nil;
  end;
end;

procedure TQParams.Clear;
var
  I: Integer;
begin
  for I := 0 to FItems.count - 1 do
    TQParam(FItems.Items[I])._Release;
  FItems.Clear;
end;

constructor TQParams.Create;
begin
  inherited;
  FItems := TQParamList.Create;
end;

procedure TQParams.Delete(AIndex: Integer);
begin
  TQParams(FItems[AIndex])._Release;
  FItems.Delete(AIndex);
end;

destructor TQParams.Destroy;
begin
  Clear;
  FreeAndNil(FItems);
  inherited;
end;

function TQParams.GetAsString: IQString;
var
  I: Integer;
  AParam: IQParam;
  AHelper: TQStringCatHelperW;
  AHasName: Boolean;
const
  SArrayStart: PWideChar = '[';
  SArrayEnd: PWideChar = ']';
  SObjectStart: PWideChar = '{';
  SObjectEnd: PWideChar = '}';
  SQuoter: WideChar = '"';
  SNameValue: WideChar = ':';
  SDelimiter: WideChar = ',';
begin
  AHelper := TQStringCatHelperW.Create;
  try
    AHasName := False;
    for I := 0 to count - 1 do
    begin
      AParam := Items[I];
      if (AParam.Name <> nil) and (AParam.Name^ <> #0) then
      begin
        AHasName := True;
        Break;
      end;
    end;
    if AHasName then
      AHelper.Cat(SObjectStart, -1)
    else
      AHelper.Cat(SArrayStart, -1);
    for I := 0 to count - 1 do
    begin
      AParam := Items[I];
      if AHasName then
        AHelper.Cat(QuotedStrW(AParam.Name, SQuoter)).Cat(SNameValue);
      if AParam.ParamType in [ptDateTime, ptInterval, ptAnsiString,
        ptUtf8String, ptUnicodeString, ptGuid, ptBytes, ptStream] then
        AHelper.Cat(QuotedStrW(JavaEscape(AParam.AsString.value,
          False), SQuoter))
      else
        AHelper.Cat(AParam.AsString.value);
      AHelper.Cat(SDelimiter);
    end;
    if count > 0 then
      AHelper.Back(1);
    if AHasName then
      AHelper.Cat(SObjectEnd, -1)
    else
      AHelper.Cat(SArrayEnd, -1);
    Result := NewString(AHelper.value);
  finally
    FreeObject(AHelper);
  end;
end;

function TQParams.GetCount: Integer;
begin
  Result := FItems.count;
end;

function TQParams.GetDItems(AIndex: Integer): TQParam;
begin
  Result := TQParam(FItems[AIndex]);
end;

function TQParams.GetItems(AIndex: Integer): IQParam;
begin
  Result := TQParam(FItems[AIndex]);
end;

function TQParams.IndexOf(const AParam: IQParam): Integer;
var
  I: Integer;
begin
  Result := -1;
  for I := 0 to FItems.count - 1 do
  begin
    if GetItems(I) = AParam then
    begin
      Result := I;
      Break;
    end;
  end;
end;

function TQParams.InternalAdd(const AName: QStringW; AParamType: TQParamType;
  var AResult: TQParam): Integer;
begin
  AResult := TQParam.Create(Self);
  AResult.FName := AName;
  AResult.DataType := AParamType;
  Result := Add(AResult);
end;

procedure TQParams.LoadFromFile(const AFileName: PWideChar);
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

procedure TQParams.LoadFromStream(AStream: TStream);
var
  I, ACount: Integer;
  C, AName: TQValue;
  AParam: TQParam;
begin
  Clear;
  C.LoadFromStream(AStream);
  try
    ACount := C.AsInteger;
    for I := 0 to ACount - 1 do
    begin
      AParam := TQParam.Create(Self);
      AName.LoadFromStream(AStream);
      AParam.FName := AName.value.AsString^;
      AStream.ReadBuffer(AParam.FType, SizeOf(TQParamType));
      AParam.FValue.LoadFromStream(AStream);
      Add(AParam);
    end;
  finally
    AName.Reset;
  end;
end;

procedure TQParams.LoadFromFile(const AFileName: QStringW);
begin
  LoadFromFile(PQCharW(AFileName));
end;

procedure TQParams.LoadFromStream(AStream: IQStream);
var
  ATemp: TQStream;
begin
  ATemp := NewStream(AStream);
  try
    LoadFromStream(ATemp);
  finally
    FreeAndNil(ATemp);
  end;
end;

procedure TQParams.SaveToFile(const AFileName: PWideChar);
var
  AStream: TStream;
begin
  AStream := TFileStream.Create(AFileName, fmCreate);
  try
    SaveToStream(AStream);
  finally
    FreeAndNil(AStream);
  end;
end;

procedure TQParams.SaveToStream(AStream: TStream);
var
  I: Integer;
  AParam: TQParam;
begin
  TQValue.WriteInt(AStream, count);
  for I := 0 to FItems.count - 1 do
  begin
    AParam := Items[I];
    TQValue.WriteString(AStream, AParam.Name);
    TQValue.WriteInt(AStream, Integer(AParam.FType));
    TQValue.WriteValue(AStream, AParam.FValue);
  end;
end;

procedure TQParams.SaveToFile(const AFileName: QStringW);
begin
  SaveToFile(PQCharW(AFileName));
end;

procedure TQParams.SaveToStream(AStream: IQStream);
var
  ATemp: TQStream;
begin
  ATemp := NewStream(AStream);
  try
    SaveToStream(ATemp);
  finally
    FreeAndNil(ATemp);
  end;
end;

procedure TQParams.SetDItems(AIndex: Integer; const value: TQParam);
begin
  if value <> Items[AIndex] then
  begin
{$IFDEF UNICODE}
    FItems[AIndex] := value;
{$ELSE}
    IQParam(FItems[AIndex])._Release;
    FItems[AIndex] := value;
{$ENDIF}
  end;
end;

procedure TQParams.ToJson(AJson: TQJson);
begin
  ParamsToJson(Self, AJson);
end;

function TQParams._Add(const AName: PWideChar; AChildren: IQParams)
  : StandInterfaceResult;
begin
  Result := PointerOf(Add(AName, AChildren));
end;

function TQParams._Add(const AName: PWideChar; AParamType: TQParamType)
  : StandInterfaceResult;
begin
  Result := PointerOf(Add(AName, AParamType));
end;

function TQParams._ByName(const AName: PWideChar): StandInterfaceResult;
begin
  Result := PointerOf(ByName(AName));
end;

function TQParams._ByPath(APath: PWideChar): StandInterfaceResult;
begin
  Result := PointerOf(ByPath(APath));
end;

function TQParams._GetAsString: StandInterfaceResult;
begin
  Result := PointerOf(GetAsString);
end;

function TQParams._GetItems(AIndex: Integer): StandInterfaceResult;
begin
  Result := PointerOf(GetItems(AIndex));
end;

function NewParams(const AValues: array of const): IQParams;
var
  I: Integer;
  procedure AddParam(AType: BYTE; const AValue: TVarRec);
  begin
    case AValues[I].VType of
      vtInteger:
        Result.Add(nil, ptInt32).AsInteger := AValues[I].VInteger;
      vtBoolean:
        Result.Add(nil, ptBoolean).AsBoolean := AValues[I].VBoolean;
{$IFNDEF NEXTGEN}
      vtChar:
        Result.Add(nil, ptUnicodeString).AsString :=
          NewString(PWideChar(AnsiDecode(@AValues[I].VChar, 1)));
{$ENDIF !NEXTGEN}
      vtExtended:
        Result.Add(nil, ptFloat8).AsFloat := AValues[I].VExtended^;
{$IFNDEF NEXTGEN}
      vtPChar:
        Result.Add(nil, ptAnsiString).AsString :=
          NewString(PWideChar(AnsiDecode(@AValues[I].VPChar, -1)));
      vtString:
        Result.Add(nil, ptUnicodeString).AsString :=
          NewString(PWideChar(AnsiDecode(PQCharA(AValues[I].VString), -1)));
      vtAnsiString:
        Result.Add(nil, ptAnsiString).AsString :=
          NewString(PWideChar(AnsiDecode(
{$IFDEF UNICODE}
          PAnsiString(AValues[I].VAnsiString)^
{$ELSE}
          PQCharA(AValues[I].VPChar), -1
{$ENDIF UNICODE}
          )));
      vtWideString:
        Result.Add(nil, ptUnicodeString).AsString :=
          NewString(PWideChar(AValues[I].VWideString^));
{$ENDIF !NEXTGEN}
      vtPointer:
        Result.Add(nil, ptInt64).AsInt64 := IntPtr(AValues[I].VPointer);
      vtWideChar:
        Result.Add(nil, ptUnicodeString).AsString :=
          NewString(PWideChar(StrDupX(@AValues[I].VWideChar, 1)));
      vtPWideChar:
        Result.Add(nil, ptUnicodeString).AsString :=
          NewString(AValues[I].VPWideChar);
      vtCurrency:
        Result.Add(nil, ptFloat8).AsFloat := AValues[I].VCurrency^;
      vtInt64:
        Result.Add(nil, ptInt64).AsInt64 := AValues[I].VInt64^;
{$IFDEF UNICODE}       // variants
      vtUnicodeString:
        Result.Add(nil, ptUnicodeString).AsString :=
          NewString(AValues[I].VPWideChar);
{$ENDIF UNICODE}
      vtVariant:
        // AddParam(AValues[I].VVariant^.VType, AValues[I].VVariant^)
      else
        raise QException.CreateFmt(SUnsupportParamArrayItem, [I]);
    end;
  end;

begin
  Result := TQParams.Create;
  for I := 0 to High(AValues) do
  begin
    AddParam(AValues[I].VType, AValues[I]);
  end;
end;

function NewParams: IQParams;
begin
  Result := TQParams.Create;
end;

function TQParams.ByName(const AName: QStringW): IQParamHelper;
begin
  Result := ParamHelper(ByName(PQCharW(AName)));
end;

function TQParams.ByPath(APath: QStringW): IQParamHelper;
begin
  Result := ParamHelper(ByPath(PQCharW(APath)));
end;

{ TQUnicodeString }

constructor TQUnicodeString.Create(const S: QStringW);
begin
  inherited Create;
  FValue := S;
end;

function TQUnicodeString.GetValue: PWideChar;
begin
  Result := PWideChar(FValue);
end;

constructor TQUnicodeString.Create;
begin
  inherited;
end;

function TQUnicodeString.GetLength: Integer;
begin
  Result := Length(FValue);
end;

procedure TQUnicodeString.SetValue(const S: PWideChar);
begin
  FValue := S;
end;

procedure TQUnicodeString.SetLength(ALen: Integer);
begin
  system.SetLength(FValue, ALen);
end;
{ TQParamString }

constructor TQParamString.Create(AValue: PQValue);
begin
  inherited Create;
  FValue := AValue;
end;

destructor TQParamString.Destroy;
begin
  inherited;
end;

function TQParamString.GetLength: Integer;
begin
  FText := FValue.AsString;
  Result := Length(FText);
end;

function TQParamString.GetValue: PWideChar;
begin
  FText := FValue.AsString;
  Result := PWideChar(FText);
end;

procedure TQParamString.SetLength(ALen: Integer);
begin
  if FValue.ValueType = vdtString then
    system.SetLength(FValue.value.AsString^, ALen);
end;

procedure TQParamString.SetValue(const S: PWideChar);
begin
  FValue.AsString := S;
end;

function ParamAsString(AParam: IQParam): QStringW;
var
  S: IQString;
begin
  if Assigned(AParam) then
  begin
    S := AParam.AsString;
    SetLength(Result, S.Length);
    Move(S.value^, PQCharW(Result)^, S.Length shl 1);
  end
  else
    SetLength(Result, 0);
end;

function ParamAsBytes(AParam: IQParam): TBytes;
var
  L: Cardinal;
begin
  if Assigned(AParam) then
  begin
    L := AParam.GetAsBytes(nil, 0);
    SetLength(Result, L);
    if L > 0 then
      AParam.GetAsBytes(@Result[0], L);
  end
  else
    SetLength(Result, 0);
end;

{ TQParamHelper }

constructor TQParamHelper.Create(AIntf: IQParam);
begin
  inherited Create;
  FInterface := AIntf;
end;

function TQParamHelper.GetAsArray: IQParams;
begin
  Result := FInterface.AsArray;
end;

function TQParamHelper.GetAsBoolean: Boolean;
begin
  Result := FInterface.AsBoolean;
end;

function TQParamHelper.GetAsBytes: IQBytes;
begin

end;

function TQParamHelper.GetAsBytes(ABuf: PByte; ABufLen: Cardinal): Cardinal;
begin
  Result := FInterface.GetAsBytes(ABuf, ABufLen);
end;

function TQParamHelper.GetAsDBytes: TBytes;
begin
  SetLength(Result, GetAsBytes(nil, 0));
  if Length(Result) > 0 then
    GetAsBytes(@Result[0], Length(Result));
end;

function TQParamHelper.GetAsDVariant: Variant;
var
  AObj: TObject;
  procedure BytesToVar;
  var
    ASize: Cardinal;
  begin
    ASize := FInterface.GetAsBytes(nil, 0);
    if ASize = 0 then
      Result := Null
    else
    begin
      Result := VarArrayCreate([0, ASize - 1], varByte);
      FInterface.GetAsBytes(VarArrayLock(Result), ASize);
      VarArrayUnlock(Result);
    end;
  end;

  procedure StreamToVar;
  var
    ASize: Int64;
    AStream: IQStream;
  begin
    AStream := FInterface.AsStream;
    ASize := AStream.Seek(0, soFromEnd);
    if ASize = 0 then
      Result := Null
    else
    begin
      Result := VarArrayCreate([0, ASize - 1], varByte);
      AStream.Read(VarArrayLock(Result), ASize);
      VarArrayUnlock(Result);
    end;
  end;

  procedure ArrayToVar;
  var
    I: Integer;
    AItems: IQParams;
  begin
    AItems := FInterface.AsArray;
    if AItems.count > 0 then
    begin
      Result := VarArrayCreate([0, AItems.count - 1], varVariant);
      for I := 0 to AItems.count - 1 do
        Result[I] := ParamHelper(AItems[I]).AsVariant;
    end
    else
      Result := Null;
  end;

begin
  AObj := InstanceOf(FInterface);
  if Assigned(AObj) and (AObj is TQParam) then
    Result := (AObj as TQParam).GetAsDVariant
  else
  begin
    case FInterface.ParamType of
      ptInt8:
        Result := ShortInt(FInterface.AsInteger);
      ptUInt8:
        Result := BYTE(FInterface.AsInteger);
      ptInt16:
        Result := SmallInt(FInterface.AsInteger);
      ptUInt16:
        Result := Word(FInterface.AsInteger);
      ptInt32:
        Result := FInterface.AsInteger;
      ptUInt32:
        Result := Cardinal(FInterface.AsInteger);
      ptInt64:
        Result := FInterface.AsInt64;
      ptUInt64:
        Result := UInt64(FInterface.AsInt64);
      ptFloat4:
        Result := FInterface.AsFloat;
      ptFloat8:
        Result := FInterface.AsFloat;
      ptDateTime:
        Result := FInterface.AsFloat;
      ptInterval:
        Result := FInterface.AsInt64;
      ptAnsiString:
{$IFNDEF NEXTGEN}
        Result := AnsiString(GetAsUString);
{$ELSE}
        Result := GetAsUString;
{$ENDIF}
      ptUtf8String:
        Result := GetAsUString;
      ptUnicodeString:
        Result := GetAsUString;
      ptBoolean:
        Result := FInterface.AsBoolean;
      ptGuid:
        Result := GuidToString(FInterface.AsGuid);
      ptBytes:
        BytesToVar;
      ptStream:
        StreamToVar;
      ptArray:
        ArrayToVar;
    end;
  end;
end;

function TQParamHelper.GetAsFloat: Double;
begin
  Result := FInterface.AsFloat;
end;

function TQParamHelper.GetAsGuid: TGuid;
begin
  Result := FInterface.AsGuid;
end;

function TQParamHelper.GetAsInt64: Int64;
begin
  Result := FInterface.AsInt64;
end;

function TQParamHelper.GetAsInteger: Integer;
begin
  Result := FInterface.AsInteger;
end;

function TQParamHelper.GetAsInterface: IInterface;
begin
  Result := FInterface.GetAsInterface;
end;

function TQParamHelper.GetAsSingle: Single;
begin
  Result := FInterface.AsSingle;
end;

function TQParamHelper.GetAsStream: IQStream;
begin
  Result := FInterface.AsStream;
end;

function TQParamHelper.GetAsString: IQString;
begin
  Result := FInterface.AsString;
end;

function TQParamHelper.GetAsUString: QStringW;
begin
  Result := FInterface.AsString.value;
end;

function TQParamHelper.GetIndex: Integer;
begin
  Result := FInterface.Index;
end;

function TQParamHelper.GetIsNull: Boolean;
begin
  Result := FInterface.IsNull;
end;

function TQParamHelper.GetName: PWideChar;
begin
  Result := FInterface.Name;
end;

function TQParamHelper.GetParent: IQParams;
begin
  Result := FInterface.Parent;
end;

function TQParamHelper.GetType: TQParamType;
begin
  Result := FInterface.ParamType;
end;

function TQParamHelper.GetUName: QStringW;
begin
  Result := FInterface.Name;
end;

procedure TQParamHelper.SetAsBoolean(const AValue: Boolean);
begin
  FInterface.AsBoolean := AValue;
end;

procedure TQParamHelper.SetAsBytes(const ABytes: IQBytes);
begin

end;

procedure TQParamHelper.SetAsBytes(ABuf: PByte; ABufLen: Cardinal);
begin
  FInterface.SetAsBytes(ABuf, ABufLen);
end;

procedure TQParamHelper.SetAsDBytes(const AValue: TBytes);
begin
  if Length(AValue) > 0 then
    SetAsBytes(@AValue[0], Length(AValue))
  else
    SetAsBytes(nil, 0);
end;

procedure TQParamHelper.SetAsDVariant(const V: Variant);
  procedure FromVar;
  begin
    raise Exception.CreateFmt(SUnsupportNow,
      ['TQParamHelper.SetAsDVaraint.FromVar']);
  end;

  procedure ToBytes;
  begin
    raise Exception.CreateFmt(SUnsupportNow,
      ['TQParamHelper.SetAsDVaraint.FromVar']);
  end;
  procedure ToStream;
  begin
    raise Exception.CreateFmt(SUnsupportNow,
      ['TQParamHelper.SetAsDVaraint.FromVar']);
  end;
  procedure ToArray;
  begin
    raise Exception.CreateFmt(SUnsupportNow,
      ['TQParamHelper.SetAsDVaraint.FromVar']);
  end;

begin
  case FInterface.ParamType of
    ptUnknown:
      FromVar;
    ptInt8, ptUInt8, ptInt16, ptUInt16, ptInt32:
      FInterface.AsInteger := V;
    ptUInt32, ptInt64, ptUInt64:
      FInterface.AsInt64 := V;
    ptFloat4:
      FInterface.AsSingle := V;
    ptFloat8:
      FInterface.AsFloat := V;
    ptDateTime:
      FInterface.AsFloat := V;
    ptInterval:
      FInterface.AsInt64 := V;
    ptAnsiString, ptUtf8String, ptUnicodeString:
      SetAsUString(V);
    ptBoolean:
      FInterface.AsBoolean := V;
    ptGuid:
      FInterface.AsGuid := StringToGuid(V);
    ptBytes:
      ToBytes;
    ptStream:
      ToStream;
    ptArray:
      ToArray;
  end;
end;

procedure TQParamHelper.SetAsFloat(const AValue: Double);
begin
  FInterface.AsFloat := AValue;
end;

procedure TQParamHelper.SetAsGuid(const value: TGuid);
begin
  FInterface.AsGuid := value;
end;

procedure TQParamHelper.SetAsInt64(const AValue: Int64);
begin
  FInterface.AsInt64 := AValue;
end;

procedure TQParamHelper.SetAsInteger(const AValue: Integer);
begin
  FInterface.AsInteger := AValue;
end;

procedure TQParamHelper.SetAsInterface(const AIntf: IInterface);
begin
  FInterface.SetAsInterface(AIntf);
end;

procedure TQParamHelper.SetAsSingle(const AValue: Single);
begin
  FInterface.AsSingle := AValue;
end;

procedure TQParamHelper.SetAsStream(AStream: IQStream);
begin
  FInterface.AsStream := AStream;
end;

procedure TQParamHelper.SetAsString(const AValue: IQString);
begin
  FInterface.AsString := AValue;
end;

procedure TQParamHelper.SetAsUString(const S: QStringW);
begin
  FInterface.AsString := NewString(S);
end;

procedure TQParamHelper.SetNull;
begin
  FInterface.SetNull;
end;

procedure TQParamHelper.SetType(const AType: TQParamType);
begin
  FInterface.SetType(AType);
end;

function TQParamHelper._GetAsArray: StandInterfaceResult;
begin
  Result := PointerOf(GetAsArray);
end;

function TQParamHelper._GetAsBytes: StandInterfaceResult;
begin
  Result := PointerOf(GetAsBytes);
end;

function TQParamHelper._GetAsInterface: StandInterfaceResult;
begin
  Result := PointerOf(GetAsInterface);
end;

function TQParamHelper._GetAsStream: StandInterfaceResult;
begin
  Result := PointerOf(GetAsStream);
end;

function TQParamHelper._GetParent: StandInterfaceResult;
begin
  Result := PointerOf(GetParent);
end;

{ TQParamsHelper }

function TQParamsHelper.Add(const AName, AValue: QStringW): Integer;
begin
  Result := FInterface.count;
  ParamHelper(FInterface.Add(PQCharW(AName), ptUnicodeString)).AsString
    := AValue;
end;

function TQParamsHelper.Add(const AName: QStringW; AValue: Variant): Integer;
begin
  Result := FInterface.count;
  ParamHelper(FInterface.Add(PQCharW(AName), ptUnknown)).AsVariant := AValue;
end;

function TQParamsHelper.Add(const AName: QStringW; AValue: Boolean): Integer;
begin
  Result := FInterface.count;
  FInterface.Add(PQCharW(AName), ptBoolean).AsBoolean := AValue;
end;

function TQParamsHelper.Add(const AName: QStringW; AValue: Int64): Integer;
begin
  Result := FInterface.count;
  FInterface.Add(PQCharW(AName), ptInt64).AsInt64 := AValue;
end;

function TQParamsHelper.Add(const AName: QStringW; AValue: Double): Integer;
begin
  Result := FInterface.count;
  FInterface.Add(PQCharW(AName), ptFloat8).AsFloat := AValue;
end;

function TQParamsHelper.Add(const AName: QStringW; const AValue: PByte;
  ALen: Integer): Integer;
begin
  Result := FInterface.count;
  FInterface.Add(PQCharW(AName), ptBytes).SetAsBytes(AValue, ALen);
end;

function TQParamsHelper.Add(const AName: QStringW; const AValue: TGuid)
  : Integer;
begin
  Result := FInterface.count;
  FInterface.Add(PQCharW(AName), ptGuid).AsGuid := AValue;
end;

function TQParamsHelper.Add(const AName: PWideChar;
  AParamType: TQParamType): IQParam;
begin
  Result := FInterface.Add(AName, AParamType);
end;

function TQParamsHelper.Add(const AName: QStringW; AValue: TStream): Integer;
begin
  Result := FInterface.count;
  FInterface.Add(PQCharW(AName), ptStream).AsStream := NewStream(AValue, True);
end;

function TQParamsHelper.Add(const AName: QStringW;
  const AValue: TBytes): Integer;
begin
  Result := FInterface.count;
  if Length(AValue) > 0 then
    FInterface.Add(PQCharW(AName), ptBytes).SetAsBytes(@AValue[0],
      Length(AValue))
  else
    FInterface.Add(PQCharW(AName), ptBytes);
end;

function TQParamsHelper.ByName(const AName: QStringW): IQParamHelper;
begin
  Result := ParamHelper(FInterface.ByName(PQCharW(AName)));
end;

function TQParamsHelper.ByName(const AName: PWideChar): IQParam;
begin
  Result := FInterface.ByName(AName);
end;

function TQParamsHelper.ByPath(APath: PWideChar): IQParam;
begin
  Result := FInterface.ByPath(APath);
end;

function TQParamsHelper.ByPath(APath: QStringW): IQParamHelper;
begin
  Result := ParamHelper(FInterface.ByPath(PQCharW(APath)));
end;

procedure TQParamsHelper.Clear;
begin
  FInterface.Clear;
end;

constructor TQParamsHelper.Create(AIntf: IQParams);
begin
  inherited Create;
  FInterface := AIntf;
end;

procedure TQParamsHelper.Delete(AIndex: Integer);
begin
  FInterface.Delete(AIndex);
end;

function TQParamsHelper.GetAsString: IQString;
begin
  Result := FInterface.AsString;
end;

function TQParamsHelper.GetCount: Integer;
begin
  Result := FInterface.count;
end;

function TQParamsHelper.GetItems(AIndex: Integer): IQParam;
begin
  Result := FInterface[AIndex];
end;

function TQParamsHelper.IndexOf(const AParam: IQParam): Integer;
begin
  Result := FInterface.IndexOf(AParam);
end;

procedure TQParamsHelper.LoadFromFile(const AFileName: PWideChar);
begin
  FInterface.LoadFromFile(AFileName);
end;

procedure TQParamsHelper.LoadFromStream(AStream: IQStream);
begin
  FInterface.LoadFromStream(AStream);
end;

procedure TQParamsHelper.SaveToFile(const AFileName: PWideChar);
begin
  FInterface.SaveToFile(AFileName);
end;

procedure TQParamsHelper.SaveToStream(AStream: IQStream);
begin
  FInterface.SaveToStream(AStream);
end;

procedure TQParamsHelper.LoadFromFile(const AFileName: QStringW);
begin
  FInterface.SaveToFile(PQCharW(AFileName));
end;

procedure TQParamsHelper.LoadFromStream(AStream: TStream);
begin
  FInterface.LoadFromStream(NewStream(AStream, False));
end;

procedure TQParamsHelper.SaveToFile(const AFileName: QStringW);
begin
  FInterface.SaveToFile(PQCharW(AFileName));
end;

procedure TQParamsHelper.SaveToStream(AStream: TStream);
begin
  FInterface.SaveToStream(NewStream(AStream, False));
end;

procedure TQParamsHelper.ToJson(AJson: TQJson);
begin
  ParamsToJson(FInterface, AJson);
end;

function TQParamsHelper._Add(const AName: PWideChar; AChildren: IQParams)
  : StandInterfaceResult;
begin
  Result := PointerOf(Add(AName, AChildren));
end;

function TQParamsHelper._Add(const AName: PWideChar; AParamType: TQParamType)
  : StandInterfaceResult;
begin
  Result := PointerOf(Add(AName, AParamType));
end;

function TQParamsHelper._ByName(const AName: PWideChar): StandInterfaceResult;
begin
  Result := PointerOf(ByName(AName));
end;

function TQParamsHelper._ByPath(APath: PWideChar): StandInterfaceResult;
begin
  Result := PointerOf(ByPath(APath));
end;

function TQParamsHelper._GetAsString: StandInterfaceResult;
begin
  Result := PointerOf(GetAsString);
end;

function TQParamsHelper._GetItems(AIndex: Integer): StandInterfaceResult;
begin
  Result := PointerOf(GetItems(AIndex));
end;

function TQParamsHelper.Add(const AName: PWideChar;
  AChildren: IQParams): IQParam;
begin
  Result := FInterface.Add(AName, AChildren);
end;

{ TQBytes }

procedure TQBytes.Append(const src: Pointer; const len: DWORD);
begin
  FCatHelper.Cat(src, len);
end;

procedure TQBytes.AppendToFile(const fileName: PWideChar);
var
  AStream: TFileStream;
  AFileName: QStringW;
begin
  AFileName := fileName;
  if FileExists(AFileName) then
    AStream := TFileStream.Create(AFileName, fmOpenWrite or fmShareDenyWrite)
  else
    AStream := TFileStream.Create(AFileName, fmCreate);
  try
    AStream.Seek(0, soEnd);
    AStream.WriteBuffer(FCatHelper.Start^, FCatHelper.Position);
  finally
    FreeAndNil(AStream);
  end;
end;

function TQBytes.CopyTo(dest: Pointer; const idx, count: DWORD): DWORD;
var
  AMax: DWORD;
begin
  if idx > Cardinal(FCatHelper.Position) then
    Result := 0
  else
  begin
    AMax := FCatHelper.Position - idx;
    if count > AMax then
      Result := AMax
    else
      Result := count;
    Move((FCatHelper.Start + idx)^, dest^, Result);
  end;
end;

constructor TQBytes.Create;
begin
  inherited Create;
  FCatHelper := TQBytesCatHelper.Create;
end;

procedure TQBytes.Delete(const idx, count: DWORD);
begin
  FCatHelper.Delete(idx, count);
end;

destructor TQBytes.Destroy;
begin
  FreeAndNil(FCatHelper);
  inherited;
end;

function TQBytes.GetByte(const idx: DWORD; var value: BYTE): Boolean;
begin
  Result := idx < FCatHelper.Position;
  if Result then
    value := FCatHelper.Bytes[idx];
end;

function TQBytes.GetCapcacity: DWORD;
begin
  Result := FCatHelper.Capacity;
end;

function TQBytes.GetData: Pointer;
begin
  Result := FCatHelper.Start;
end;

function TQBytes.GetLength: DWORD;
begin
  Result := FCatHelper.Position;
end;

procedure TQBytes.Insert(const idx: DWORD; const src: Pointer;
  const len: DWORD);
begin
  FCatHelper.Insert(idx, src, len);
end;

procedure TQBytes.LoadFromFile(const fileName: PWideChar);
var
  AStream: TFileStream;
begin
  AStream := TFileStream.Create(fileName, fmOpenRead or fmShareDenyWrite);
  try
    FCatHelper.Capacity := AStream.Size;
    AStream.ReadBuffer(FCatHelper.Start^, FCatHelper.Capacity);
    FCatHelper.Position := AStream.Size;
  finally
    FreeAndNil(AStream);
  end;
end;

procedure TQBytes.Replace(const idx: DWORD; const src: Pointer;
  const len: DWORD);
begin
  if idx + len > FCatHelper.Position then
  begin
    FCatHelper.Position := idx;
    FCatHelper.Cat(src, len);
  end
  else
    Move(src^, PByte(IntPtr(FCatHelper.Start) + idx)^, len);
end;

procedure TQBytes.SaveToFile(const fileName: PWideChar);
var
  AStream: TFileStream;
begin
  AStream := TFileStream.Create(fileName, fmCreate);
  try
    AStream.WriteBuffer(FCatHelper.Start^, FCatHelper.Position);
  finally
    FreeAndNil(AStream);
  end;
end;

function TQBytes.SetByte(const idx: DWORD; const value: BYTE): Boolean;
begin
  Result := idx < FCatHelper.Position;
  if Result then
    PByte(IntPtr(FCatHelper.Start) + idx)^ := value;
end;

procedure TQBytes.SetCapacity(const len: DWORD);
begin
  FCatHelper.Capacity := len;
end;

procedure TQBytes.SetLength(const len: DWORD);
begin
  FCatHelper.Position := len;
end;

end.
