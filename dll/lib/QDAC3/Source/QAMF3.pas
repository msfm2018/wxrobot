unit QAMF3;

interface

{$I QDAC.INC}

uses classes, sysutils, math{$IFDEF MSWINDOWS}, windows{$ENDIF}, qstring,
  qrbtree, qxml{$IFDEF UNICODE},
  Generics.Collections{$ENDIF}{$IF RTLVersion>=21},
  Rtti{$IFEND >=XE10}
{$IF RTLVersion<22}// 2007-2010
{$IFDEF ENABLE_REGEX}
    , PerlRegEx, pcre
{$ENDIF}
{$ELSE}
    , RegularExpressionsCore
{$IFEND};

type
  /// <summary>
  /// AMF 数据类型枚举值
  /// </summary>
  /// <remarks>
  /// 部分类型的支持因为找到合适的测试用例暂未完成
  /// </remarks>
  TQAMFDataType = (
    /// <summary>
    /// 未定义
    /// </summary>
    adtUndefined,
    /// <summary>
    /// 空
    /// </summary>
    adtNull,
    /// <summary>
    /// 布尔
    /// </summary>
    adtBoolean,
    /// <summary>
    /// 整数
    /// </summary>
    adtInteger,
    /// <summary>
    /// 浮点数
    /// </summary>
    adtFloat,
    /// <summary>
    /// 字符串
    /// </summary>
    adtString,
    /// <summary>
    /// 日期时间
    /// </summary>
    adtDateTime,
    /// <summary>
    /// 数组
    /// </summary>
    adtArray,
    /// <summary>
    /// 对象
    /// </summary>
    adtObject,
    /// <summary>
    /// XML文档
    /// </summary>
    adtXML,
    /// <summary>
    /// 二进制
    /// </summary>
    adtBytes,
    /// <summary>
    /// 向量
    /// </summary>
    adtVector,
    /// <summary>
    /// 字典
    /// </summary>
    adtDictionary, adtDictionaryItem);
  TQAMFDataTypes = set of TQAMFDataType;
  TQAMFNode = class;
{$IF RTLVersion>=21}
  TQAMFList = TList<TQAMFNode>;
{$ELSE}
  TQAMFList = TList;
  PObject = ^TObject;
{$IFEND}
  /// <summary>
  /// 内部使用，用于添加对象或类时触发的事件类型
  /// </summary>
  TQAMFAddObjectEvent = procedure(ASender: TQAMFNode) of object;
  /// <summary>
  /// 内部使用，用于获取对象或类时触发的事件使用
  /// </summary>
  TQAMFGetObjectEvent = procedure(ASender: TQAMFNode; AIndex: Integer;
    var AObj: TQAMFNode) of object;
  /// <summary>
  /// 在解析出错时触发的事件
  /// </summary>
  TQAMFParseErrorEvent = procedure(ASender: TQAMFNode; p: PByte;
    AErorrCode: Integer; const AErrorMsg: QStringW) of object;
  /// <summary>
  /// 在读取到一个字符串时触发的事件时触发的事件类型
  /// </summary>
  TQAMFAddStringEvent = procedure(ASender: TQAMFNode; const S: QStringW)
    of object;
  /// <summary>
  /// 在获取指定的字符串时触发的事件类型
  /// </summary>
  TQAMFGetStringEvent = procedure(ASender: TQAMFNode; AIndex: Integer;
    var S: QStringW; var AExists: Boolean) of object;
  /// <summary>
  /// 在解析未知的外部类型引用时触发的事件类型
  /// </summary>
  TQAMFParseUnknownExternalEvent = procedure(ASender: TQAMFNode;
    AClassName: QStringW; var p: PByte; const pe: PByte) of object;
  /// <summary>
  /// 用于注册解析特定类型的外部外用时触发的回调函数
  /// </summary>
  TQAMFParseUnknownExternalCallback = procedure(ASender: TQAMFNode;
    AClassName: QStringW; var p: PByte; const pe: PByte);

  /// <summary>
  /// 在解析 AMF 格式时要回调的事件参数，所有的子结点都在解析时指向同一个实例
  /// </summary>
  TQAMFParseEvents = record
    /// <summary>
    /// 触发解析的根结点
    /// </summary>
    ParseRoot: TQAMFNode;
    /// <summary>
    /// 解析出错时触发的事件
    /// </summary>
    OnParseError: TQAMFParseErrorEvent;
    /// <summary>
    /// 添加AMF 0 格式的对象时触发的事件
    /// </summary>
    OnAddAMF0Object: TQAMFAddObjectEvent;
    OnAddAMF3Object: TQAMFAddObjectEvent;
    OnGetAMF0Object: TQAMFGetObjectEvent;
    OnGetAMF3Object: TQAMFGetObjectEvent;
    OnAddAMF0Class: TQAMFAddObjectEvent;
    OnAddAMF3Class: TQAMFAddObjectEvent;
    OnGetAMF0Class: TQAMFGetObjectEvent;
    OnGetAMF3Class: TQAMFGetObjectEvent;
    OnAddAMF0String: TQAMFAddStringEvent;
    OnAddAMF3String: TQAMFAddStringEvent;
    OnGetAMF0String: TQAMFGetStringEvent;
    OnGetAMF3String: TQAMFGetStringEvent;
    OnParseUnknownExternal: TQAMFParseUnknownExternalEvent;
  end;

  PQAMFParseEvents = ^TQAMFParseEvents;
  TQAMFNodeClass = class of TQAMFNode;
  TQAMFNodeExtClass = class of TQAMFNodeExt;

  TQAMFNodeExt = class
  private
    FExtClass: QStringW;
  public
    function Copy: TQAMFNodeExt; virtual;
    constructor Create(AExtClass: QStringW); overload; virtual;
    property ExtClass: QStringW read FExtClass;
  end;

  /// <summary>
  /// AMF 格式支持的基础类型，一般对外公开的是这一类型
  /// </summary>
  TQAMFNode = class
  private
    FExt: TQAMFNodeExt;
    function GetAsBoolean: Boolean;
    function GetAsBytes: TBytes;
    function GetAsDateTime: TDateTime;
    function GetAsFloat: Double;
    function GetAsInt64: Int64;
    function GetAsInteger: Integer;
    function GetAsString: QStringW; virtual;
    function GetAsXML: TQXMLNode;
    function GetIsNull: Boolean;
    function GetIsUndefined: Boolean;
    procedure SetAsBoolean(const Value: Boolean);
    procedure SetAsBytes(const Value: TBytes); overload;
    procedure SetAsBytes(const p: PByte; l: Integer); overload;
    procedure SetAsDateTime(const Value: TDateTime);
    procedure SetAsFloat(const Value: Double);
    procedure SetAsInt64(const Value: Int64);
    procedure SetAsInteger(const Value: Integer);
    procedure SetAsString(const Value: QStringW);
    procedure SetDataType(const Value: TQAMFDataType);
    function GetAsArray: TQAMFNode;
    function GetAsDictionary: TQAMFNode;
    function GetAsObject: TQAMFNode;
    function GetAsVector: TQAMFNode;
    function GetKeyAsArray: TQAMFNode;
    function GetKeyAsBoolean: Boolean;
    function GetKeyAsBytes: TBytes;
    function GetKeyAsDateTime: TDateTime;
    function GetKeyAsDictionary: TQAMFNode;
    function GetKeyAsFloat: Double;
    function GetKeyAsInt64: Int64;
    function GetKeyAsInteger: Integer;
    function GetKeyAsObject: TQAMFNode;
    function GetKeyAsString: QStringW;
    function GetKeyAsVector: TQAMFNode;
    function GetKeyAsXML: TQXMLNode;
    function GetKeyIsNull: Boolean;
    function GetKeyIsUndefined: Boolean;
    procedure SetKeyAsBoolean(const Value: Boolean);
    procedure SetKeyAsBytes(const Value: TBytes);
    procedure SetKeyAsDateTime(const Value: TDateTime);
    procedure SetKeyAsFloat(const Value: Double);
    procedure SetKeyAsInt64(const Value: Int64);
    procedure SetKeyAsInteger(const Value: Integer);
    procedure SetKeyAsString(const Value: QStringW);
    procedure SetKeyType(const Value: TQAMFDataType);
    function GetCount: Integer;
    function GetItems(AIndex: Integer): TQAMFNode;
    function GetListItems: TQAMFList; inline;
    procedure DoAddObject(AIsAMF3: Boolean);
    procedure DoAddClass(AIsAMF3: Boolean);
    procedure DoAddString(S: QStringW; AIsAMF3: Boolean);
    function DoGetReferString(AIndex: Integer; AIsAMF3: Boolean;
      var S: QStringW): Boolean;
    function DoGetReferObject(AIndex: Integer; AIsAMF3: Boolean): TQAMFNode;
    function DoGetReferClass(AIndex: Integer; AIsAMF3: Boolean): TQAMFNode;
    procedure DoParseError(p: PByte; AErrorCode: Integer; AErrorMsg: QStringW);
    function GetParseEvents: PQAMFParseEvents;
    procedure SetParseEvents(const Value: PQAMFParseEvents); virtual;
    function LastParseError: Integer; virtual;
    function Failed: Boolean; inline;
    procedure SetExt(const Value: TQAMFNodeExt);
    function GetKeyHash: TQHashType;
    function GetItemIndex: Integer;
    function GetPath: QStringW;
    function GetPathDelimiters: QStringW;
    function GetRoot: TQAMFNode;
  protected
    FValue: QStringW;
    FDataType: TQAMFDataType;
    FKey: QStringW;
    FKeyType: TQAMFDataType;
    FKeyHash: TQHashType;
    FParent: TQAMFNode;
    FObjectClass: TQAMFNode;
    FParseEvents: PQAMFParseEvents; // 只在解析时设置
    FNodeExt: TQAMFNodeExt; // 结点的扩展类型信息
    FChildClass: TQAMFNodeClass; // 子结点类型
    FTag: Pointer;
    procedure ConvertError(ASourceType, ATargetType: TQAMFDataType);
    procedure TypeNeeded(ATypes: TQAMFDataTypes; AType: TQAMFDataType);
    procedure InternalEncode(AHelper: TQBytesCatHelper); virtual;
    procedure WriteAMF0String(AHelper: TQBytesCatHelper; S: QStringW);
    function ReadAMF0Word(var p: PByte; const pe: PByte): Word;
    function ReadAMF0Boolean(var p: PByte; const pe: PByte): Boolean;
    function ReadAMF0Int32(var p: PByte; const pe: PByte): Integer;
    function ReadAMF0String(var p: PByte; const pe: PByte): QStringW;
    function ReadAMF0Value(var p: PByte; const pe: PByte): Boolean;
    function ReadInt29(var p: PByte; const pe: PByte): Integer;
    function ReadAMF3String(var p: PByte; const pe: PByte): QStringW;
    function ReadAMF3Value(var p: PByte; const pe: PByte): Boolean;
    function ReadAMF3Object(var p: PByte; const pe: PByte): Boolean;
    procedure WriteAMF0Value(AHelper: TQBytesCatHelper; AItem: TQAMFNode);
    procedure WriteAMF3Value(AHelper: TQBytesCatHelper; AItem: TQAMFNode);
    function DoReadUnknownExternalClass(AClassName: QStringW; var p: PByte;
      const pe: PByte): Boolean;
    function IsInline(var V: Integer): Boolean; inline;
    function HashName(S: QStringW): TQHashType;
    property ListItems: TQAMFList read GetListItems;
    property ParseEvents: PQAMFParseEvents read GetParseEvents
      write SetParseEvents;

  public
    constructor Create; overload; virtual;
    constructor Create(ADataType: TQAMFDataType); overload;
    constructor Create(AExt: TQAMFNodeExt); overload;
    destructor Destroy; override;
    /// <summary>
    /// 复制函数，将ANode的内容复制给当前结点（Key 除外）
    /// </summary>
    procedure Assign(ANode: TQAMFNode); virtual;
    /// <summary>
    /// 添加一个子结点，子结点的类型实际上由继承的子类指定，默认是TQAMFNode
    /// </summary>
    function Add(ANode: TQAMFNode): Integer; overload;
    /// <summary>
    /// 添加一个字符串命名的子结点（常用，其它类型请添加结点后用KeyAsXXX来设置）
    /// </summary>
    function Add(AName: QStringW): TQAMFNode; overload;
    /// <summary>
    /// 添加指定名称和类型的子结点
    /// </summary>
    /// <param name="AName">
    /// 要添加的结点名称
    /// </param>
    /// <param name="ADataType">
    /// 要 添加的结点类型
    /// </param>
    function Add(AName: QStringW; ADataType: TQAMFDataType): TQAMFNode;
      overload;
    /// <summary>
    /// 添加一个子结点
    /// </summary>
    function Add: TQAMFNode; overload;
    /// <summary>
    /// 添加一个指定类型的子结点
    /// </summary>
    /// <param name="ADataType">
    /// 要添加的结点类型
    /// </param>
    function Add(ADataType: TQAMFDataType): TQAMFNode; overload;
    /// <summary>
    /// 清除所有的子结点
    /// </summary>
    procedure Clear;
    /// <summary>
    /// 解析指定的内容
    /// </summary>
    /// <param name="p">
    /// 内容首地址
    /// </param>
    /// <param name="l">
    /// 内容长度
    /// </param>
    /// <param name="AIsAMF3">
    /// 是否是AMF 3格式
    /// </param>
    function Decode(var p: PByte; l: Integer; AIsAMF3: Boolean)
      : Boolean; virtual;
    /// <summary>
    /// 将内容值编码为字节流
    /// </summary>
    function Encode: TBytes;
    /// <summary>
    /// 从流中加载内容
    /// </summary>
    /// <param name="AStream">
    /// 内容来源
    /// </param>
    /// <remarks>
    /// 注意TQAMF实现要求包头，而其它级别的实现要求没有包头（仅可加载AMF3，其它格式请用 TryParseAMF0Data 来解析）
    /// </remarks>
    procedure LoadFromStream(AStream: TStream);
    /// <summary>
    /// 从文件中加载内容
    /// </summary>
    procedure LoadFromFile(AFileName: QStringW);
    /// <summary>
    /// 保存内容到流
    /// </summary>
    procedure SaveToStream(AStream: TStream);
    /// <summary>
    /// 保存内容到文件
    /// </summary>
    procedure SaveToFile(AFileName: QStringW);

    /// <summary>
    /// 为二进制项目从流中加载值
    /// </summary>
    procedure ValueFromStream(AStream: TStream);
    /// <summary>
    /// 为二进制主键从流中主键
    /// </summary>
    procedure KeyFromStream(AStream: TStream);
    procedure ValueFromFile(const AFileName: QStringW);
    procedure KeyFromFile(const AFileName: QStringW);
    procedure StreamFromValue(AStream: TStream);
    procedure StreamFromKey(AStream: TStream);
    procedure FileFromValue(const AFileName: QStringW);
    procedure FileFromKey(const AFileName: QStringW);

    /// <summary>获取指定名称获取结点的值的字符串表示</summary>
    /// <param name="AName">结点名称</param>
    /// <param name="ADefVal">默认值</param>
    /// <returns>返回应结点的值</returns>
    function ValueByName(AName, ADefVal: QStringW): QStringW;
    /// <summary>获取指定名称获取结点的值的布尔值表示</summary>
    /// <param name="AName">结点名称</param>
    /// <param name="ADefVal">默认值</param>
    /// <returns>返回应结点的值</returns>
    function BoolByName(AName: QStringW; ADefVal: Boolean): Boolean;
    /// <summary>获取指定名称获取结点的值的整数值表示</summary>
    /// <param name="AName">结点名称</param>
    /// <param name="ADefVal">默认值</param>
    /// <returns>返回应结点的值</returns>
    function IntByName(AName: QStringW; ADefVal: Int64): Int64;
    /// <summary>获取指定名称获取结点的值的浮点值表示</summary>
    /// <param name="AName">结点名称</param>
    /// <param name="ADefVal">默认值</param>
    /// <returns>返回应结点的值</returns>
    function FloatByName(AName: QStringW; ADefVal: Extended): Extended;
    /// <summary>获取指定名称获取结点的值的日期时间值表示</summary>
    /// <param name="AName">结点名称</param>
    /// <param name="ADefVal">默认值</param>
    /// <returns>返回应结点的值</returns>
    function DateTimeByName(AName: QStringW; ADefVal: TDateTime): TDateTime;
    /// <summary>获取指定路径结点的值的字符串表示</summary>
    /// <param name="AName">结点名称</param>
    /// <param name="ADefVal">默认值</param>
    /// <returns>如果结果不存在，返回默认值，否则，返回原始值</returns>
    function ValueByPath(APath, ADefVal: QStringW): QStringW;
    /// <summary>获取指定路径结点的值的布尔值表示</summary>
    /// <param name="AName">结点名称</param>
    /// <param name="ADefVal">默认值</param>
    /// <returns>如果结果不存在，返回默认值，否则，返回原始值</returns>
    function BoolByPath(APath: QStringW; ADefVal: Boolean): Boolean;
    /// <summary>获取指定路径结点的值的整数表示</summary>
    /// <param name="AName">结点名称</param>
    /// <param name="ADefVal">默认值</param>
    /// <returns>如果结果不存在，返回默认值，否则，返回原始值</returns>
    function IntByPath(APath: QStringW; ADefVal: Int64): Int64;
    /// <summary>获取指定路径结点的值的浮点数表示</summary>
    /// <param name="AName">结点名称</param>
    /// <param name="ADefVal">默认值</param>
    /// <returns>如果结果不存在，返回默认值，否则，返回原始值</returns>
    function FloatByPath(APath: QStringW; ADefVal: Extended): Extended;
    /// <summary>获取指定路径结点的值的日期时间表示</summary>
    /// <param name="AName">结点名称</param>
    /// <param name="ADefVal">默认值</param>
    /// <returns>如果结果不存在，返回默认值，否则，返回原始值</returns>
    function DateTimeByPath(APath: QStringW; ADefVal: TDateTime): TDateTime;
    /// <summary>获取指定路径结点的二进制表示</summary>
    /// <param name="AName">结点名称</param>
    /// <param name="ADefVal">默认值</param>
    /// <returns>如果结果不存在，返回默认值，否则，返回原始值</returns>
    function BytesByPath(APath: QStringW; ADefVal: TBytes): TBytes;

    function ItemByName(const AName: QStringW): TQAMFNode; overload;
    function ItemByName(const AName: QStringW; AList: TQAMFList; ANest: Boolean)
      : Integer; overload;
    function ItemByPath(const APath: QStringW): TQAMFNode;
    function HasChild(const APath: QStringW; var AChild: TQAMFNode): Boolean;
    function Exists(const APath: QStringW): Boolean;
    function IndexOf(const AName: QStringW): Integer;
    function Remove(AItemIndex: Integer): TQAMFNode; overload;
    procedure Remove(AItem: TQAMFNode); overload;
    procedure Detach;
    function GetRelPath(AParent: TQAMFNode; APathDelimiter: QCharW = '\')
      : QStringW;
    property IsNull: Boolean read GetIsNull;
    property IsUndefined: Boolean read GetIsUndefined;
    property DataType: TQAMFDataType read FDataType write SetDataType;
    property AsBoolean: Boolean read GetAsBoolean write SetAsBoolean;
    property AsInteger: Integer read GetAsInteger write SetAsInteger;
    property AsInt64: Int64 read GetAsInt64 write SetAsInt64;
    property AsFloat: Double read GetAsFloat write SetAsFloat;
    property AsDateTime: TDateTime read GetAsDateTime write SetAsDateTime;
    property AsString: QStringW read GetAsString write SetAsString;
    property AsXML: TQXMLNode read GetAsXML;
    property AsBytes: TBytes read GetAsBytes write SetAsBytes;
    property AsArray: TQAMFNode read GetAsArray;
    property AsObject: TQAMFNode read GetAsObject;
    property AsVector: TQAMFNode read GetAsVector;
    property AsDictionary: TQAMFNode read GetAsDictionary;
    property Parent: TQAMFNode read FParent;
    // Key
    property Name: QStringW read GetKeyAsString write SetKeyAsString;
    property KeyIsNull: Boolean read GetKeyIsNull;
    property KeyIsUndefined: Boolean read GetKeyIsUndefined;
    property KeyType: TQAMFDataType read FKeyType write SetKeyType;
    property KeyAsBoolean: Boolean read GetKeyAsBoolean write SetKeyAsBoolean;
    property KeyAsInteger: Integer read GetKeyAsInteger write SetKeyAsInteger;
    property KeyAsInt64: Int64 read GetKeyAsInt64 write SetKeyAsInt64;
    property KeyAsFloat: Double read GetKeyAsFloat write SetKeyAsFloat;
    property KeyAsDateTime: TDateTime read GetKeyAsDateTime
      write SetKeyAsDateTime;
    property KeyAsString: QStringW read GetKeyAsString write SetKeyAsString;
    property KeyAsXML: TQXMLNode read GetKeyAsXML;
    property KeyAsBytes: TBytes read GetKeyAsBytes write SetKeyAsBytes;
    property KeyAsArray: TQAMFNode read GetKeyAsArray;
    property KeyAsObject: TQAMFNode read GetKeyAsObject;
    property KeyAsVector: TQAMFNode read GetKeyAsVector;
    property KeyAsDictionary: TQAMFNode read GetKeyAsDictionary;
    property KeyHash: TQHashType read GetKeyHash;
    property Count: Integer read GetCount;
    property Items[AIndex: Integer]: TQAMFNode read GetItems; default;
    property ItemIndex: Integer read GetItemIndex;
    property ObjectClass: TQAMFNode read FObjectClass write FObjectClass;
    property Ext: TQAMFNodeExt read FExt write SetExt;
    property Tag: Pointer read FTag write FTag;
    property Path: QStringW read GetPath;
    property PathDelimiters: QStringW read GetPathDelimiters;
    property Root: TQAMFNode read GetRoot;
  end;

  TQAMFClassExt = class(TQAMFNodeExt)
  private
    FIsTypedObject: Boolean;
  protected
    FIsExternal: Boolean;
    FIsDynamic: Boolean;
    FName: QStringW;
  public
    constructor Create; overload;
    function Copy: TQAMFNodeExt; override;
    /// <summary>
    /// 是否是外部定义类型
    /// </summary>
    property IsExternal: Boolean read FIsExternal write FIsExternal;
    /// <summary>
    /// 是否是动态类型
    /// </summary>
    property IsDynamic: Boolean read FIsDynamic write FIsDynamic;

    property IsTypedObject: Boolean read FIsTypedObject write FIsTypedObject;
    property Name: QStringW read FName write FName;
  end;

  TQAMFVectorType = (vtInteger = 13, vtDWord = 14, vtFloat = 15, vtObject = 16);

  TQAMFVectorExt = class(TQAMFNodeExt)
  protected
    FIsFixed: Boolean;
    FVectorType: TQAMFVectorType;
    FName: QStringW;
  public
    constructor Create; overload;
    function Copy: TQAMFNodeExt; override;
    property IsFixed: Boolean read FIsFixed write FIsFixed;
    property VectorType: TQAMFVectorType read FVectorType write FVectorType;
    property Name: QStringW read FName write FName;
  end;

  TQAMFDictionaryExt = class(TQAMFNodeExt)
  protected
    FIsWeak: Boolean;
  public
    constructor Create; overload;
    property IsWeak: Boolean read FIsWeak write FIsWeak;
  end;

  TQAMFHeaderExt = class(TQAMFNodeExt)
  private
    FRequired: Boolean;
  public
    /// <summary>
    /// 是否必需
    /// </summary>
    property Required: Boolean read FRequired write FRequired;
  end;

  TQAMFHeader = class(TQAMFNode)
  protected
    procedure InternalEncode(AHelper: TQBytesCatHelper); override;
  public
    constructor Create; override;
  end;

  TQAMFHeaders = class(TQAMFNode)
  public
    constructor Create; override;
  end;

  TQAMFMessageExt = class(TQAMFNodeExt)
  private
    FResponse: QStringW;
    FTarget: QStringW;
  public
    constructor Create; overload;
    /// <summary>
    /// 目标请求
    /// </summary>
    property Target: QStringW read FTarget write FTarget;
    /// <summary>
    /// 回应
    /// </summary>
    property Response: QStringW read FResponse write FResponse;
  end;

  TQAMFMessage = class(TQAMFNode)
  protected
    procedure InternalEncode(AHelper: TQBytesCatHelper); override;
  public
    constructor Create; override;
  end;

  TQAMFMessages = class(TQAMFNode)
  public
    constructor Create; override;
  end;

  PQAMF = ^TQAMF;

  /// <summary>
  /// AMF 的根对象，用于提供核心的加载、解析和编码功能
  /// </summary>
  TQAMF = class(TQAMFNode)
  private
    FPathDelimiter: QCharW;
  protected
    FAMF0Objects: TQAMFList;
    FAMFStrings: TStringList;
    FAMF3Objects: TQAMFList;
    FAMF3Defines: TQAMFList;
    FHeaders: TQAMFHeaders;
    FMessages: TQAMFMessages;
    FParseError: Integer;
    FParseErrorMsg: QStringW;
    FErrorAt: PByte;
    FErrorOffset: Integer;
    FOnParseUnknownExternal: TQAMFParseUnknownExternalEvent;
    procedure Reset;
    procedure DoAddAMF0Object(AObject: TQAMFNode);
    procedure DoAddAMF3Object(AObject: TQAMFNode);
    procedure DoAddAMF0Class(AClass: TQAMFNode);
    procedure DoAddAMF3Class(AClass: TQAMFNode);
    procedure DoAddAMF0String(ASender: TQAMFNode; const S: QStringW);
    procedure DoAddAMF3String(ASender: TQAMFNode; const S: QStringW);
    procedure DoGetAMF0Object(ASender: TQAMFNode; AIndex: Integer;
      var AObj: TQAMFNode);
    procedure DoGetAMF3Object(ASender: TQAMFNode; AIndex: Integer;
      var AObj: TQAMFNode);
    procedure DoGetAMF0Class(ASender: TQAMFNode; AIndex: Integer;
      var AObj: TQAMFNode);
    procedure DoGetAMF3Class(ASender: TQAMFNode; AIndex: Integer;
      var AObj: TQAMFNode);
    procedure DoGetAMF0String(ASender: TQAMFNode; AIndex: Integer;
      var S: QStringW; var AExists: Boolean);
    procedure DoGetAMF3String(ASender: TQAMFNode; AIndex: Integer;
      var S: QStringW; var AExists: Boolean);
    procedure DoAMFParseError(ASender: TQAMFNode; p: PByte; AErrorCode: Integer;
      const AErrorMsg: QStringW);
    procedure DoParseUnknownExternal(ASender: TQAMFNode; AClassName: QStringW;
      var p: PByte; const pe: PByte);
    function GetItemInList(AParent: TQAMFList; AIndex: Integer): TQAMFNode;
    procedure InternalEncode(AHelper: TQBytesCatHelper); override;
    procedure RaiseError(ps: PByte);
    procedure SetParseEvents(const Value: PQAMFParseEvents); override;
    function GetAsString: QStringW; override;
    procedure SetupEvents(var AEvents: TQAMFParseEvents);
    function LastParseError: Integer; override;
  public
    constructor Create; override;
    destructor Destroy; override;

    /// <summary>
    /// 解析一个有包头的数据，如果失败，抛出异常
    /// </summary>
    procedure Parse(p: PByte; ALen: Integer);
    /// <summary>
    /// 尝试解析一个有包头的数据，如果失败，返回False
    /// </summary>
    function TryParse(p: PByte; ALen: Integer): Boolean;
    /// <summary>
    /// 尝试解析一个 无包头的AMF3 格式的数据 <br />
    /// </summary>
    function TryParseAMF3Data(p: PByte; ALen: Integer): Boolean;
    /// <summary>
    /// 解析一个 无包头的AMF3 格式的数据
    /// </summary>
    procedure ParseAMF3Data(p: PByte; ALen: Integer);
    /// <summary>
    /// 尝试解析一个 无包头的AMF0 格式的数据
    /// </summary>
    function TryParseAMF0Data(p: PByte; ALen: Integer): Boolean;
    /// <summary>
    /// 解析一个 无包头的AMF0 格式的数据
    /// </summary>
    procedure ParseAMF0Data(p: PByte; ALen: Integer);
    /// <summary>
    /// 重载完成统一的解析接口
    /// </summary>
    function Decode(var p: PByte; l: Integer; AIsAMF3: Boolean)
      : Boolean; override;
    /// <summary>
    /// 头部定义
    /// </summary>
    property Headers: TQAMFHeaders read FHeaders;
    /// <summary>
    /// 消息体定义
    /// </summary>
    property Messages: TQAMFMessages read FMessages;
    /// <summary>
    /// 末次解析错误代码
    /// </summary>
    property LastError: Integer read FParseError;
    /// <summary>
    /// 末次解析错误
    /// </summary>
    property LastErrorMsg: QStringW read FParseErrorMsg;
    /// <summary>
    /// 末次错误在内容中出现的位置偏移
    /// </summary>
    property ErrorOffset: Integer read FErrorOffset;
    /// <summary>
    /// 在无法找到外部类型的注册时触发的用户自定义类型解析事件
    /// </summary>
    property OnParseUnknownExternal: TQAMFParseUnknownExternalEvent
      read FOnParseUnknownExternal write FOnParseUnknownExternal;
    property PathDelimiter: QCharW read FPathDelimiter write FPathDelimiter;
  end;

const
  AMFTypeName: array [TQAMFDataType] of QStringW = ('Undefined', 'Null',
    'Boolean', 'Integer', 'Float', 'String', 'DateTime', 'Array', 'Object',
    'XML', 'Bytes', 'Vector', 'Dictionary', 'DictionaryItem');

var
  /// <summary>日期类型转换为字符串，这个变量控制如何格式化</summary>
  AMFDateFormat: QStringW;
  /// <summary>时间类型转换为成字符串，这个变量控制如何格式化</summary>
  AMFTimeFormat: QStringW;
  /// <summary>日期时间类型转换为字符串，这个变量控制如何格式化</summary>
  AMFDateTimeFormat: QStringW;

  /// <summary>
  /// 注册一个特定类型的解析函数
  /// </summary>
procedure RegisterAMFExternalClass(AClassName: QStringW;
  AHandler: TQAMFParseUnknownExternalCallback);
/// <summary>
/// 查找一个特定类型的解析函数
/// </summary>
function GetKnownAMFExternalClassHandler(AClassName: QStringW)
  : TQAMFParseUnknownExternalCallback;
function DecodeRTMPC3Block(p: PByte; ALen: Integer): TBytes;

implementation

resourcestring
  SBadConvert = '%s 不是一个有效的 %s 类型的值。';
  SBadStreamFormat = '数据内容不是有效的 AMF3 格式。';
  SConvertError = '无法转换类型 %s 到 %s。';
  SOutOfRange = '索引 %d 越界:(0~%d)。';
  SUnknownAMF3Type = '未知的 AMF3 数据类型 %d';
  SUnknownAMF0Type = '未知的 AMF0 数据类型 %d';
  SUnexpectEof = '不期望的数据内容结束';
  SReferObjectMissed = '引用的对象 %d 不存在。';
  SReferStringMissed = '引用的字符串 %d 不存在。';
  SReferClassMissed = '引用的类 %d 不存在。';
  SAMFParseError = '解析 AMF 数据时出错，位置: 第 %d 字节，错误代码：%d，错误:%s';
  SUnknownExternal =
    '无法解析未注册的外部类型 %s，您可以尝试人工响应 OnParseUnknownExternal 事件来完成解析。';

const
  // AMF0 内置类型编码
  AMF0_NUMERIC = 0;
  AMF0_BOOLEAN = 1;
  AMF0_STRING = 2;
  AMF0_OBJECT = 3;
  AMF0_MOVIE = 4;
  AMF0_NULL = 5;
  AMF0_UNDEFINED = 6;
  AMF0_REFERENCE = 7;
  AMF0_MIXEDARRAY = 8;
  AMF0_OBJECTEND = 9;
  AMF0_ARRAY = 10;
  AMF0_DATETIME = 11;
  AMF0_LONGSTRING = 12;
  AMF0_UNSUPPORT = 13;
  AMF0_RECORDSET = 14;
  AMF0_XML = 15;
  AMF0_TYPEDOBJECT = 16;
  AMF0_AMF3 = 17;
  // AMF3 内置类型编码
  AMF3_UNDEFINED = 0;
  AMF3_NULL = 1;
  AMF3_FALSE = 2;
  AMF3_TRUE = 3;
  AMF3_INTEGER = 4;
  AMF3_FLOAT = 5;
  AMF3_STRING = 6;
  AMF3_XMLDOC = 7;
  AMF3_DATETIME = 8;
  AMF3_ARRAY = 9;
  AMF3_OBJECT = 10;
  AMF3_XML = 11;
  AMF3_BYTEARRAY = 12;
  AMF3_INT_VECTOR = 13;
  AMF3_UINT_VECTOR = 14;
  AMF3_DOUBLE_VECTOR = 15;
  AMF3_OBJECT_VECTOR = 16;
  AMF3_DICTIONARY = 17;
  AMF3_MAX_INT = 268435455;

  // 解析的错误代码
  AE_BADTYPE = -1;
  AE_UNEXPECT_EOF = -2;
  AE_REFER_OBJECT_MISSED = -3;
  AE_BAD_FORMAT = -4;
  AE_UNKNOWN_EXTERNAL = -5;

type
  TSetKeyTypeProc = procedure(const AType: TQAMFDataType) of object;

  TQAMFExternalClassItem = class
  private
    FHandler: TQAMFParseUnknownExternalCallback;
  public
    constructor Create(AHandler: TQAMFParseUnknownExternalCallback); overload;
  end;

var
  KnownExternalClasses: TStringList;

procedure SetAMFValue(var ATarget: QStringW; ASetTypeProc: TSetKeyTypeProc;
  ASourceType: TQAMFDataType; ASource: PByte; ASize: Integer);

  procedure MoveBytes;
  var
    pd: PByte;
  begin
    if ASize = 0 then
      SetLength(ATarget, 0)
    else
    begin
      SetLength(ATarget, (ASize + 1) shr 1 + 2);
      pd := PByte(ATarget);
      PInteger(pd)^ := ASize;
      Inc(pd, 4);
      Move(ASource^, pd^, ASize);
    end;
  end;

begin
  ASetTypeProc(ASourceType);
  case ASourceType of
    adtUndefined, adtNull:
      SetLength(ATarget, 0);
    adtBoolean:
      PBoolean(ATarget)^ := PBoolean(ASource)^;
    adtInteger:
      PInt64(ATarget)^ := PInt64(ASource)^;
    adtFloat:
      PDouble(ATarget)^ := PDouble(ASource)^;
    adtString:
      ATarget := StrDupX(PQCharW(ASource), ASize shr 1);
    adtDateTime:
      PDateTime(ATarget)^ := PDateTime(ASource)^;
    adtBytes:
      MoveBytes;
    adtVector:
      ;
    adtDictionary: // Todo: 字典支持
      ;
  end;
end;

procedure SetAMFType(var ATargetValue: QStringW; var ATargetType: TQAMFDataType;
  AValue: TQAMFDataType);
  procedure Clear;
  var
    I: Integer;
    AList: TQAMFList;
  begin
    AList := PPointer(ATargetValue)^;
    for I := 0 to AList.Count - 1 do
      FreeObject(AList[I]);
    AList.Clear;
  end;

begin
  if ATargetType <> AValue then
  begin
    if ATargetType in [adtObject, adtArray, adtVector, adtDictionary] then
    // List
    begin
      if AValue in [adtObject, adtArray, adtVector, adtDictionary] then
        Clear
      else
        FreeAndNil(PPointer(ATargetValue)^);
    end
    else if ATargetType in [adtDictionaryItem, adtXML] then
      FreeAndNil(PPointer(ATargetValue)^);
    ATargetType := AValue;
    case AValue of
      adtUndefined, adtNull:
        SetLength(ATargetValue, 0);
      adtBoolean:
        SetLength(ATargetValue, 1); // 2B
      adtInteger, adtFloat, adtDateTime:
        SetLength(ATargetValue, 4); // 8B
      adtString:
        SetLength(ATargetValue, 0);
      adtArray, adtObject, adtVector, adtDictionary:
        begin
          SetLength(ATargetValue, SizeOf(Pointer) shr 1);
          PObject(ATargetValue)^ := TQAMFList.Create;
        end;
      adtXML:
        begin
          SetLength(ATargetValue, SizeOf(Pointer) shr 1);
          PObject(ATargetValue)^ := TQXMLNode.Create;
        end;
      adtBytes:
        SetLength(ATargetValue, 0);
      adtDictionaryItem:
        begin
          SetLength(ATargetValue, SizeOf(Pointer) shr 1);
          PObject(ATargetValue)^ := TQAMFNode.Create;
        end;
    end;
  end;
end;

{ TQAMFNode }

procedure TQAMFNode.ConvertError(ASourceType, ATargetType: TQAMFDataType);
begin
  raise EConvertError.CreateFmt(SConvertError, [AMFTypeName[ASourceType],
    AMFTypeName[ATargetType]]);
end;

constructor TQAMFNode.Create(AExt: TQAMFNodeExt);
begin
  Create;
  FExt := AExt;
end;

constructor TQAMFNode.Create(ADataType: TQAMFDataType);
begin
  Create;
  DataType := ADataType;
end;

constructor TQAMFNode.Create;
begin
  inherited;
  FChildClass := TQAMFNode;
end;

function TQAMFNode.DateTimeByName(AName: QStringW; ADefVal: TDateTime)
  : TDateTime;
var
  AChild: TQAMFNode;
begin
  AChild := ItemByName(AName);
  if Assigned(AChild) then
  begin
    try
      Result := AChild.AsDateTime;
    except
      Result := ADefVal;
    end;
  end
  else
    Result := ADefVal;

end;

function TQAMFNode.DateTimeByPath(APath: QStringW; ADefVal: TDateTime)
  : TDateTime;
var
  AItem: TQAMFNode;
begin
  AItem := ItemByPath(APath);
  if Assigned(AItem) then
  begin
    try
      Result := AItem.AsDateTime;
    except
      Result := ADefVal;
    end;
  end
  else
    Result := ADefVal;
end;

function TQAMFNode.Decode(var p: PByte; l: Integer; AIsAMF3: Boolean): Boolean;
begin
  if AIsAMF3 then
    Result := ReadAMF3Value(p, PByte(IntPtr(p) + l))
  else
    Result := ReadAMF0Value(p, PByte(IntPtr(p) + l))
end;

destructor TQAMFNode.Destroy;
begin
  Clear;
  DataType := adtUndefined;
  KeyType := adtUndefined;
  Ext := nil;
  inherited;
end;

procedure TQAMFNode.Detach;
begin
  if Assigned(FParent) then
    FParent.Remove(Self);
end;

function TQAMFNode.Encode: TBytes;
var
  AHelper: TQBytesCatHelper;
begin
  AHelper := TQBytesCatHelper.Create;
  try
    InternalEncode(AHelper);
    Result := AHelper.Value;
  finally
    FreeAndNil(AHelper);
  end;
end;

function TQAMFNode.Exists(const APath: QStringW): Boolean;
begin
  Result := ItemByPath(APath) <> nil;
end;

function TQAMFNode.Failed: Boolean;
begin
  Result := LastParseError <> 0;
end;

procedure TQAMFNode.FileFromKey(const AFileName: QStringW);
var
  AStream: TMemoryStream;
begin
  AStream := TMemoryStream.Create;
  try
    StreamFromKey(AStream);
    AStream.SaveToFile(AFileName);
  finally
    FreeAndNil(AStream);
  end;
end;

procedure TQAMFNode.FileFromValue(const AFileName: QStringW);
var
  AStream: TMemoryStream;
begin
  AStream := TMemoryStream.Create;
  try
    StreamFromValue(AStream);
    AStream.SaveToFile(AFileName);
  finally
    FreeAndNil(AStream);
  end;
end;

function TQAMFNode.FloatByName(AName: QStringW; ADefVal: Extended): Extended;
var
  AChild: TQAMFNode;
begin
  AChild := ItemByName(AName);
  if Assigned(AChild) then
  begin
    try
      Result := AChild.AsFloat;
    except
      Result := ADefVal;
    end;
  end
  else
    Result := ADefVal;
end;

function TQAMFNode.FloatByPath(APath: QStringW; ADefVal: Extended): Extended;
var
  AItem: TQAMFNode;
begin
  AItem := ItemByPath(APath);
  if Assigned(AItem) then
  begin
    try
      Result := AItem.AsFloat;
    except
      Result := ADefVal;
    end;
  end
  else
    Result := ADefVal;
end;

function TQAMFNode.GetAsArray: TQAMFNode;
begin
  Result := Self;
end;

function TQAMFNode.GetAsBoolean: Boolean;
begin
  case DataType of
    adtBoolean:
      Result := PBoolean(FValue)^;
    adtUndefined, adtNull:
      Result := False;
    adtInteger:
      Result := PInt64(FValue)^ <> 0;
    adtFloat:
      Result := not IsZero(PDouble(FValue)^);
    adtString:
      if not TryStrToBool(FValue, Result) then
        ConvertError(adtString, adtBoolean);
    adtDateTime:
      Result := not IsZero(PDouble(FValue)^)
  else
    ConvertError(DataType, adtBoolean);
  end;
end;

function TQAMFNode.GetAsBytes: TBytes;
begin
  case DataType of
    adtUndefined, adtNull:
      SetLength(Result, 0);
    adtBoolean, adtInteger, adtFloat, adtDateTime, adtString:
      begin
        SetLength(Result, Length(FValue) shl 1);
        Move(PQCharW(FValue)^, Result[0], Length(Result));
      end;
    adtArray, adtObject, adtVector, adtDictionary:
      Result := Encode;
    adtXML:
      Result := qstring.Utf8Encode(AsXML.Encode(False));
    adtBytes:
      begin
        if Length(FValue) > 4 then
        begin
          SetLength(Result, PInteger(FValue)^);
          Move(PByte(IntPtr(PQCharW(FValue)) + 4)^, Result[0], Length(Result));
        end
        else
          SetLength(Result, 0);
      end;
  end;
end;

function TQAMFNode.GetAsDateTime: TDateTime;
begin
  case DataType of
    adtDateTime:
      Result := PDateTime(FValue)^;
    adtUndefined, adtNull:
      Result := 0;
    adtBoolean:
      Result := PByte(FValue)^;
    adtInteger:
      Result := PInt64(FValue)^;
    adtFloat:
      Result := PDouble(FValue)^;
    adtString:
      begin
        if not(ParseDateTime(PWideChar(FValue), Result) or
          ParseWebTime(PQCharW(FValue), Result)) then
          ConvertError(DataType, adtDateTime);
      end
  else
    ConvertError(DataType, adtDateTime);
  end;
end;

function TQAMFNode.GetAsDictionary: TQAMFNode;
begin
  Result := Self;
end;

function TQAMFNode.GetAsFloat: Double;
begin
  case DataType of
    adtFloat:
      Result := PDouble(FValue)^;
    adtUndefined, adtNull:
      Result := 0;
    adtBoolean:
      Result := PByte(FValue)^;
    adtInteger:
      Result := PInt64(FValue)^;
    adtString:
      if not TryStrToFloat(FValue, Result) then
        ConvertError(DataType, adtFloat);
    adtDateTime:
      Result := PDouble(FValue)^
  else
    ConvertError(DataType, adtFloat);
  end;
end;

function TQAMFNode.GetAsInt64: Int64;
begin
  case DataType of
    adtInteger:
      Result := PInt64(FValue)^;
    adtUndefined, adtNull:
      Result := 0;
    adtBoolean:
      Result := PByte(FValue)^;
    adtFloat, adtDateTime:
      Result := Trunc(PDouble(FValue)^);
    adtString:
      begin
        if not TryStrToInt64(FValue, Result) then
          ConvertError(DataType, adtInteger);
      end
  else
    ConvertError(DataType, adtInteger);
  end;
end;

function TQAMFNode.GetAsInteger: Integer;
begin
  Result := AsInt64;
end;

function TQAMFNode.GetAsObject: TQAMFNode;
begin
  Result := nil;
  if DataType = adtDictionaryItem then
    Result := PPointer(FValue)^
  else
    ConvertError(DataType, adtDictionary);
end;

function TQAMFNode.GetAsString: QStringW;
  procedure DateTimeAsString;
  var
    ADate: Integer;
    AValue: Double;
  begin
    AValue := PDouble(FValue)^;
    ADate := Trunc(AValue);
    if SameValue(ADate, 0) then // Date为0，是时间
    begin
      if SameValue(AValue, 0) then
        Result := FormatDateTime(AMFDateFormat, AValue)
      else
        Result := FormatDateTime(AMFTimeFormat, AValue);
    end
    else
    begin
      if SameValue(AValue - ADate, 0) then
        Result := FormatDateTime(AMFDateFormat, AValue)
      else
        Result := FormatDateTime(AMFDateTimeFormat, AValue);
    end;
  end;

  function ObjectAsString: QStringW;
  var
    I: Integer;
    AItem: TQAMFNode;
    AName: QStringW;
  begin
    Result := '{'#13#10;
    for I := 0 to Count - 1 do
    begin
      AItem := Items[I];
      AName := AItem.Name;
      if Length(AName) > 0 then
        Result := Result + QuotedStrW(AName, '"') + ':';
      if AItem.DataType in [adtString, adtXML, adtDateTime, adtBytes] then
        Result := Result + QuotedStrW(AItem.AsString, '"')
      else
        Result := Result + AItem.AsString;
      Result := Result + ','#13#10;
    end;
    Result := StrDupX(PWideChar(Result), Length(Result) - 3) + #13#10'}';
  end;
  function ArrayAsString: QStringW;
  var
    I, C: Integer;
    AItem: TQAMFNode;
  begin
    C := Count;
    if C > 0 then
    begin
      Dec(C);
      Result := '['#13#10;
      for I := 0 to C do
      begin
        AItem := Items[I];
        if AItem.DataType in [adtUndefined, adtString, adtXML] then
          Result := Result + QuotedStrW(AItem.AsString, '"')
        else
          Result := Result + AItem.AsString;
        Result := Result + ','#13#10;
      end;
      Result := StrDupX(PWideChar(Result), Length(Result) - 3) + #13#10']';
    end
    else
      Result := '[]';
  end;
  function VectorAsString: QStringW;
  begin
    Result := ArrayAsString;
  end;

  function DictionaryAsString: QStringW;
  begin
    Result := ObjectAsString;
  end;

begin
  case DataType of
    adtString:
      Result := FValue;
    adtUndefined:
      Result := 'undefined';
    adtNull:
      Result := 'null';
    adtBoolean:
      Result := BoolToStr(AsBoolean, true);
    adtInteger:
      Result := IntToStr(PInt64(FValue)^);
    adtFloat:
      Result := FloatToStr(PDouble(FValue)^);
    adtDateTime:
      DateTimeAsString;
    adtXML:
      Result := AsXML.AsXML;
    adtBytes:
      Result := BinToHex(AsBytes, true);
    adtObject:
      Result := ObjectAsString;
    adtArray:
      Result := ArrayAsString;
    adtVector:
      Result := VectorAsString;
    adtDictionary:
      Result := DictionaryAsString;
  else
    ConvertError(DataType, adtString);
  end;
end;

function TQAMFNode.GetAsVector: TQAMFNode;
begin
  Result := Self;
end;

function TQAMFNode.GetAsXML: TQXMLNode;
begin
  Result := nil;
  if DataType = adtXML then
    Result := PPointer(FValue)^
  else
    ConvertError(DataType, adtXML);
end;

function TQAMFNode.GetIsNull: Boolean;
begin
  Result := DataType = adtNull;
end;

function TQAMFNode.GetIsUndefined: Boolean;
begin
  Result := DataType = adtUndefined;
end;

function TQAMFNode.GetKeyAsArray: TQAMFNode;
begin
  Result := nil;
  if KeyType = adtDictionaryItem then
  begin
    Result := KeyAsObject;
    if not(Result.DataType in [adtArray, adtObject, adtVector, adtDictionary])
    then
      ConvertError(Result.DataType, adtArray);
  end
  else
    ConvertError(KeyType, adtArray); // 暂不支持数组做为Key
end;

function TQAMFNode.GetKeyAsBoolean: Boolean;
begin
  case KeyType of
    adtBoolean:
      Result := PBoolean(FKey)^;
    adtUndefined, adtNull:
      Result := False;
    adtInteger:
      Result := PInt64(FKey)^ <> 0;
    adtFloat:
      Result := not IsZero(PDouble(FKey)^);
    adtString:
      if not TryStrToBool(FKey, Result) then
        ConvertError(adtString, adtBoolean);
    adtDateTime:
      Result := not IsZero(PDouble(FKey)^)
  else
    ConvertError(KeyType, adtBoolean);
  end;
end;

function TQAMFNode.GetKeyAsBytes: TBytes;
begin
  case KeyType of
    adtUndefined, adtNull:
      SetLength(Result, 0);
    adtBoolean, adtInteger, adtFloat, adtDateTime, adtString:
      begin
        SetLength(Result, Length(FKey) shl 1);
        Move(PQCharW(FKey)^, Result[0], Length(Result));
      end;
    adtArray, adtObject, adtVector, adtDictionary:
      ConvertError(KeyType, adtBytes); // 暂时不支持，将来加入支持编码为AMF3格式数据流
    adtXML:
      Result := qstring.Utf8Encode(AsXML.Encode(False));
    adtBytes:
      begin
        if Length(FKey) > 4 then
        begin
          SetLength(Result, PInteger(FKey)^);
          Move(PByte(IntPtr(PQCharW(FKey)) + 4)^, Result[0], Length(Result));
        end
        else
          SetLength(Result, 0);
      end;
  end;
end;

function TQAMFNode.GetKeyAsDateTime: TDateTime;
begin
  case KeyType of
    adtDateTime:
      Result := PDateTime(FKey)^;
    adtUndefined, adtNull:
      Result := 0;
    adtBoolean:
      Result := PByte(FKey)^;
    adtInteger:
      Result := PInt64(FKey)^;
    adtFloat:
      Result := PDouble(FKey)^;
    adtString:
      begin
        if not(ParseDateTime(PWideChar(FKey), Result) or
          ParseWebTime(PQCharW(FKey), Result)) then
          ConvertError(DataType, adtDateTime);
      end
  else
    ConvertError(DataType, adtDateTime);
  end;
end;

function TQAMFNode.GetKeyAsDictionary: TQAMFNode;
begin
  Result := nil;
  if DataType = adtDictionaryItem then
  begin
    Result := KeyAsObject;
    if Result.DataType <> adtDictionary then
      ConvertError(Result.DataType, adtDictionary);
  end
  else
    ConvertError(KeyType, adtDictionary);
end;

function TQAMFNode.GetKeyAsFloat: Double;
begin
  case KeyType of
    adtFloat:
      Result := PDouble(FKey)^;
    adtUndefined, adtNull:
      Result := 0;
    adtBoolean:
      Result := PByte(FKey)^;
    adtInteger:
      Result := PInt64(FKey)^;
    adtString:
      if not TryStrToFloat(FKey, Result) then
        ConvertError(KeyType, adtFloat);
    adtDateTime:
      Result := PDouble(FKey)^
  else
    ConvertError(KeyType, adtFloat);
  end;
end;

function TQAMFNode.GetKeyAsInt64: Int64;
begin
  case KeyType of
    adtInteger:
      Result := PInt64(FKey)^;
    adtUndefined, adtNull:
      Result := 0;
    adtBoolean:
      Result := PByte(FKey)^;
    adtFloat, adtDateTime:
      Result := Trunc(PDouble(FKey)^);
    adtString:
      begin
        if not TryStrToInt64(FKey, Result) then
          ConvertError(KeyType, adtInteger);
      end
  else
    ConvertError(KeyType, adtInteger);
  end;
end;

function TQAMFNode.GetKeyAsInteger: Integer;
begin
  Result := GetKeyAsInt64;
end;

function TQAMFNode.GetKeyAsObject: TQAMFNode;
begin
  Result := nil;
  if DataType = adtDictionaryItem then
  begin
    Result := PPointer(FKey)^
  end
  else
    ConvertError(KeyType, adtObject);
end;

function TQAMFNode.GetKeyAsString: QStringW;
  procedure DateTimeAsString;
  var
    ADate: Integer;
    AValue: Double;
  begin
    AValue := PDouble(FKey)^;
    ADate := Trunc(AValue);
    if SameValue(ADate, 0) then // Date为0，是时间
    begin
      if SameValue(AValue, 0) then
        Result := FormatDateTime(AMFDateFormat, AValue)
      else
        Result := FormatDateTime(AMFTimeFormat, AValue);
    end
    else
    begin
      if SameValue(AValue - ADate, 0) then
        Result := FormatDateTime(AMFDateFormat, AValue)
      else
        Result := FormatDateTime(AMFDateTimeFormat, AValue);
    end;
  end;

begin
  case KeyType of
    adtString:
      Result := FKey;
    adtUndefined, adtNull:
      SetLength(Result, 0);
    adtBoolean:
      Result := BoolToStr(AsBoolean, true);
    adtInteger:
      Result := IntToStr(PInt64(FKey)^);
    adtFloat:
      Result := FloatToStr(PDouble(FKey)^);
    adtDateTime:
      DateTimeAsString;
    adtXML:
      Result := AsXML.AsXML;
    adtBytes:
      Result := BinToHex(AsBytes, true)
  else
    ConvertError(KeyType, adtString);
  end;
end;

function TQAMFNode.GetKeyAsVector: TQAMFNode;
begin
  Result := nil;
  if DataType = adtDictionaryItem then
  begin
    Result := KeyAsObject;
    if Result.DataType <> adtVector then
      ConvertError(Result.DataType, adtVector);
  end
  else
    ConvertError(KeyType, adtVector);
end;

function TQAMFNode.GetKeyAsXML: TQXMLNode;
begin
  Result := nil;
  if KeyType = adtXML then
    Result := PPointer(FKey)^
  else
    ConvertError(KeyType, adtXML);
end;

function TQAMFNode.GetKeyHash: TQHashType;
begin
  if FKeyHash = 0 then
    FKeyHash := HashName(KeyAsString);
  Result := FKeyHash;
end;

function TQAMFNode.GetKeyIsNull: Boolean;
begin
  Result := FKeyType = adtNull;
end;

function TQAMFNode.GetKeyIsUndefined: Boolean;
begin
  Result := FKeyType = adtUndefined;
end;

function TQAMFNode.GetListItems: TQAMFList;
begin
  TypeNeeded([adtArray, adtObject, adtVector, adtDictionary], adtObject);
  Result := PPointer(FValue)^;
end;

function TQAMFNode.GetParseEvents: PQAMFParseEvents;
begin
  if not Assigned(FParseEvents) then
  begin
    if Assigned(FParent) then
      FParseEvents := FParent.ParseEvents;
  end;
  Result := FParseEvents;
end;

function TQAMFNode.GetPath: QStringW;
begin
  Result := GetRelPath(nil);
end;

function TQAMFNode.GetPathDelimiters: QStringW;
var
  ARoot: TQAMFNode;
begin
  ARoot := Root;
  if Assigned(ARoot) and (ARoot is TQAMF) then
    Result := (ARoot as TQAMF).PathDelimiter
  else
    Result := '\';
end;

function TQAMFNode.GetRelPath(AParent: TQAMFNode; APathDelimiter: QCharW)
  : QStringW;
var
  AItem, APItem: TQAMFNode;
  AItemName: QStringW;
begin
  AItem := Self;
  SetLength(Result, 0);
  while Assigned(AItem) and (AItem <> AParent) do
  begin
    APItem := AItem.Parent;
    if Assigned(APItem) then
    begin
      if APItem.DataType = adtArray then
        Result := '[' + IntToStr(AItem.ItemIndex) + ']' + Result
      else
      begin
        AItemName := AItem.Name;
        if Length(AItemName) > 0 then // 命名的元素
          Result := APathDelimiter + AItemName + Result
        else
          Result := '[' + IntToStr(AItem.ItemIndex) + ']' + Result;
      end
    end
    else
      Result := APathDelimiter + AItem.Name + Result;
    AItem := APItem;
  end;
  if Length(Result) > 0 then
    Result := StrDupX(PQCharW(Result) + 1, Length(Result) - 1);
end;

function TQAMFNode.GetRoot: TQAMFNode;
begin
  Result := Self;
  while Assigned(Result.Parent) do
    Result := Result.Parent;
end;

function TQAMFNode.HasChild(const APath: QStringW;
  var AChild: TQAMFNode): Boolean;
begin
  AChild := ItemByPath(APath);
  Result := Assigned(AChild);
end;

function TQAMFNode.HashName(S: QStringW): TQHashType;
begin
  S := UpperCase(S);
  Result := HashOf(PQCharW(S), Length(S) shl 1);
end;

function TQAMFNode.IndexOf(const AName: QStringW): Integer;
var
  I, l: Integer;
  AItem: TQAMFNode;
  AHash: Cardinal;
  AKey: QStringW;
begin
  Result := -1;
  l := Length(AName);
  if l > 0 then
    AHash := HashName(AName)
  else
  begin
    Exit;
  end;
  for I := 0 to Count - 1 do
  begin
    AItem := Items[I];
    AKey := AItem.Name;
    if (Length(AKey) = l) and (AItem.KeyHash = AHash) then
    begin
      if StartWithW(PQCharW(AKey), PQCharW(AName), true) then
      begin
        Result := I;
        Break;
      end;
    end;
  end;
end;

function TQAMFNode.IntByName(AName: QStringW; ADefVal: Int64): Int64;
var
  AChild: TQAMFNode;
begin
  AChild := ItemByName(AName);
  if Assigned(AChild) then
  begin
    try
      Result := AChild.AsInt64;
    except
      Result := ADefVal;
    end;
  end
  else
    Result := ADefVal;
end;

function TQAMFNode.IntByPath(APath: QStringW; ADefVal: Int64): Int64;
var
  AItem: TQAMFNode;
begin
  AItem := ItemByPath(APath);
  if Assigned(AItem) then
  begin
    try
      Result := AItem.AsInt64;
    except
      Result := ADefVal;
    end;
  end
  else
    Result := ADefVal;

end;

procedure TQAMFNode.InternalEncode(AHelper: TQBytesCatHelper);
begin
  WriteAMF3Value(AHelper, Self);
end;

function TQAMFNode.IsInline(var V: Integer): Boolean;
begin
  Result := (V and $1) <> 0;
  V := V shr 1;
end;

function TQAMFNode.ItemByName(const AName: QStringW; AList: TQAMFList;
  ANest: Boolean): Integer;
var
  AHash: Cardinal;
  l: Integer;
  function InternalFind(AParent: TQAMFNode): Integer;
  var
    I: Integer;
    AItem: TQAMFNode;
    AKey: QStringW;
  begin
    Result := -1;
    for I := 0 to Count - 1 do
    begin
      AItem := Items[I];
      AKey := AItem.KeyAsString;
      if (Length(AKey) = l) and (AHash = AItem.KeyHash) then
      begin
        if StartWithW(PQCharW(AKey), PQCharW(AName), true) then
          AList.Add(AItem);
      end;
      if ANest then
        InternalFind(AItem);
    end;
  end;

begin
  l := Length(AName);
  if l > 0 then
  begin
    AHash := HashName(AName);
    Result := InternalFind(Self);
  end
  else
  begin
    AHash := 0;
    Result := -1;
    Exit;
  end;
end;

function TQAMFNode.ItemByName(const AName: QStringW): TQAMFNode;
var
  I: Integer;
  p: PQCharW;
  AIndex: Int64;
begin
  Result := nil;
  p := PQCharW(AName);
  if (p^ = '[') and (DataType in [adtObject, adtArray, adtVector, adtDictionary])
  then
  begin
    Inc(p);
    SkipSpaceW(p);
    if ParseInt(p, AIndex) <> 0 then
    begin
      SkipSpaceW(p);
      if p^ = ']' then
      begin
        Inc(p);
        if p^ <> #0 then
          Exit;
      end
      else
        Exit;
    end
    else
      Exit;
    if (AIndex >= 0) and (AIndex < Count) then
      Result := Items[AIndex];
  end
  else if DataType in [adtObject, adtVector, adtDictionary] then
  begin
    I := IndexOf(AName);
    if I <> -1 then
      Result := Items[I];
  end;

end;

function TQAMFNode.ItemByPath(const APath: QStringW): TQAMFNode;
var
  AParent: TQAMFNode;
  AName: QStringW;
  p, pn, ws: PQCharW;
  l: Integer;
  AIndex: Int64;
  APathDelimiters: QStringW;
const
  ArrayStart: PWideChar = '[';
begin
  AParent := Self;
  p := PQCharW(APath);
  Result := nil;
  APathDelimiters := PathDelimiters;
  while Assigned(AParent) and (p^ <> #0) do
  begin
    AName := DecodeTokenW(p, PQCharW(APathDelimiters), WideChar(0), False);
    if Length(AName) > 0 then
    begin
      // 查找的是数组？
      l := Length(AName);
      AIndex := -1;
      pn := PQCharW(AName);
      if (pn[l - 1] = ']') then
      begin
        ws := pn;
        if pn^ = '[' then // 如果是直接的数组，则直接取当前的parent为数组的根
          Result := AParent
        else
        begin
          SkipUntilW(ws, ArrayStart);
          Result := AParent.ItemByName
            (StrDupX(pn, (IntPtr(ws) - IntPtr(pn)) shr 1));
        end;
        if Result <> nil then
        begin
          if Result.DataType in [adtArray, adtObject, adtVector, adtDictionary]
          then
          begin
            repeat
              Inc(ws);
              SkipSpaceW(ws);
              if ParseInt(ws, AIndex) <> 0 then
              begin
                if (AIndex >= 0) and (AIndex < Result.Count) then
                begin
                  Result := Result[AIndex];
                  SkipSpaceW(ws);
                  if ws^ = ']' then
                  begin
                    Inc(ws);
                    SkipSpaceW(ws);
                    if ws^ = '[' then
                      Continue
                    else if ws^ = #0 then
                      Break
                    else
                      Result := nil;
                  end
                  else
                    Result := nil;
                end
                else
                  Result := nil;
              end;
            until Result = nil;
          end
        end;
      end
      else
        Result := AParent.ItemByName(AName);
      if Assigned(Result) then
        AParent := Result
      else
      begin
        Exit;
      end;
    end;
    if CharInW(p, PQCharW(APathDelimiters)) then
      Inc(p);
    // 否则是..或//\\等路径，忽略
  end;
  if p^ <> #0 then
    Result := nil;
end;

procedure TQAMFNode.KeyFromFile(const AFileName: QStringW);
var
  AStream: TFileStream;
begin
  AStream := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyWrite);
  try
    KeyFromStream(AStream);
  finally
    FreeAndNil(AStream);
  end;
end;

procedure TQAMFNode.KeyFromStream(AStream: TStream);
var
  ABytes: TBytes;
begin
  SetLength(ABytes, AStream.Size - AStream.Position);
  AStream.ReadBuffer(ABytes[0], Length(ABytes));
  KeyAsBytes := ABytes;
end;

function TQAMFNode.LastParseError: Integer;
begin
  if Assigned(ParseEvents) then
    Result := ParseEvents.ParseRoot.LastParseError
  else
    Result := 0;
end;

procedure TQAMFNode.LoadFromFile(AFileName: QStringW);
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

procedure TQAMFNode.LoadFromStream(AStream: TStream);
  procedure LoadFromMemory(ATemp: TCustomMemoryStream);
  var
    p: PByte;
    APos: Int64;
  begin
    APos := ATemp.Position;
    p := ATemp.Memory;
    Inc(p, APos);
    if Decode(p, ATemp.Size - APos, true) then
      ATemp.Position := (IntPtr(p) - IntPtr(ATemp.Memory))
    else
    begin
      ATemp.Position := APos;
      raise EStreamError.Create(SBadStreamFormat);
    end;
  end;
  procedure LoadFromTempStream;
  var
    ATemp: TMemoryStream;
    APos: Int64;
  begin
    ATemp := TMemoryStream.Create;
    try
      APos := AStream.Position;
      ATemp.CopyFrom(AStream, AStream.Size - AStream.Position);
      AStream.Position := APos;
      LoadFromMemory(ATemp);
      AStream.Position := APos + ATemp.Position;
    finally
      FreeAndNil(ATemp);
    end;
  end;

begin
  if AStream is TCustomMemoryStream then
    LoadFromMemory(AStream as TCustomMemoryStream)
  else
    LoadFromTempStream;
end;

procedure TQAMFNode.DoAddClass(AIsAMF3: Boolean);
begin
  if Assigned(ParseEvents) then
  begin
    if AIsAMF3 then
    begin
      if Assigned(ParseEvents.OnAddAMF3Class) then
        ParseEvents.OnAddAMF3Class(Self);
    end
    else if Assigned(ParseEvents.OnAddAMF0Class) then
      ParseEvents.OnAddAMF0Class(Self);
  end;
end;

procedure TQAMFNode.DoAddObject(AIsAMF3: Boolean);
begin
  if Assigned(ParseEvents) then
  begin

    if Assigned(Ext) then
    begin
      if (Ext.ExtClass = 'message') or (Ext.ExtClass = 'header') then
        Exit;
    end;
    if AIsAMF3 then
    begin
      if Assigned(ParseEvents.OnAddAMF3Object) then
        ParseEvents.OnAddAMF3Object(Self);
    end
    else if Assigned(ParseEvents.OnAddAMF0Object) then
      ParseEvents.OnAddAMF0Object(Self);
  end;
end;

procedure TQAMFNode.DoAddString(S: QStringW; AIsAMF3: Boolean);
begin
  if Assigned(ParseEvents) then
  begin
    if AIsAMF3 then
    begin
      if Assigned(ParseEvents.OnAddAMF3String) then
        ParseEvents.OnAddAMF3String(Self, S);
    end
    else if Assigned(ParseEvents.OnAddAMF0String) then
      ParseEvents.OnAddAMF0String(Self, S);
  end;
end;

function TQAMFNode.DoGetReferClass(AIndex: Integer; AIsAMF3: Boolean)
  : TQAMFNode;
begin
  Result := nil;
  if Assigned(ParseEvents) then
  begin
    if AIsAMF3 then
    begin
      if Assigned(ParseEvents.OnGetAMF3Class) then
        ParseEvents.OnGetAMF3Class(Self, AIndex, Result);
    end
    else if Assigned(ParseEvents.OnGetAMF0Class) then
      ParseEvents.OnGetAMF0Class(Self, AIndex, Result);
  end;
end;

function TQAMFNode.DoGetReferObject(AIndex: Integer; AIsAMF3: Boolean)
  : TQAMFNode;
begin
  Result := nil;
  if Assigned(ParseEvents) then
  begin
    if AIsAMF3 then
    begin
      if Assigned(ParseEvents.OnGetAMF3Object) then
        ParseEvents.OnGetAMF3Object(Self, AIndex, Result);
    end
    else if Assigned(ParseEvents.OnGetAMF0Object) then
      ParseEvents.OnGetAMF0Object(Self, AIndex, Result);
  end;
end;

function TQAMFNode.DoGetReferString(AIndex: Integer; AIsAMF3: Boolean;
  var S: QStringW): Boolean;
begin
  Result := False;
  if Assigned(ParseEvents) then
  begin
    if AIsAMF3 then
    begin
      if Assigned(ParseEvents.OnGetAMF3String) then
        ParseEvents.OnGetAMF3String(Self, AIndex, S, Result);
    end
    else if Assigned(ParseEvents.OnGetAMF0String) then
      ParseEvents.OnGetAMF0String(Self, AIndex, S, Result);
  end;
end;

procedure TQAMFNode.DoParseError(p: PByte; AErrorCode: Integer;
  AErrorMsg: QStringW);
begin
  if Assigned(ParseEvents) and Assigned(ParseEvents.OnParseError) then
    ParseEvents.OnParseError(Self, p, AErrorCode, AErrorMsg);
end;

function TQAMFNode.DoReadUnknownExternalClass(AClassName: QStringW;
  var p: PByte; const pe: PByte): Boolean;
var
  ps: PByte;
  AHandler: TQAMFParseUnknownExternalCallback;
begin
  ps := p;
  AHandler := GetKnownAMFExternalClassHandler(AClassName);
  if Assigned(AHandler) then
    AHandler(Self, AClassName, p, pe)
  else
  begin
    if Assigned(ParseEvents) and Assigned(ParseEvents.OnParseUnknownExternal)
    then
    begin
      ParseEvents.OnParseUnknownExternal(Self, AClassName, p, pe);
    end
  end;
  if IntPtr(p) = IntPtr(ps) then
    DoParseError(p, AE_UNKNOWN_EXTERNAL, Format(SUnknownExternal,
      [AClassName]));
  Result := not Failed;
end;

function TQAMFNode.ReadAMF0Boolean(var p: PByte; const pe: PByte): Boolean;
begin
  Result := p^ <> 0;
  Inc(p);
end;

function TQAMFNode.ReadAMF0Int32(var p: PByte; const pe: PByte): Integer;
begin
  Result := ExchangeByteOrder(PInteger(p)^);
  Inc(p, 4);
end;

function TQAMFNode.ReadAMF0String(var p: PByte; const pe: PByte): QStringW;
var
  ALen: Word;
begin
  if IntPtr(p) + 2 < IntPtr(pe) then
  begin
    ALen := ReadAMF0Word(p, pe);
    if IntPtr(p) + ALen < IntPtr(pe) then
    begin
      Result := qstring.Utf8Decode(PQCharA(p), ALen);
      Inc(p, ALen);
    end
    else
    begin
      DoParseError(p, AE_UNEXPECT_EOF, SUnexpectEof);
      SetLength(Result, 0)
    end;
  end
  else
    SetLength(Result, 0);
end;

function TQAMFNode.ReadAMF0Value(var p: PByte; const pe: PByte): Boolean;
var
  AType: BYTE;
  function ReadAMF0Number: Double;
  begin
    Result := ExchangeByteOrder(PDouble(p)^);
    Inc(p, 8);
  end;

  function ReadAMF0DateTime: TDateTime;
  begin
    // Double类型的毫秒数 时区（始终为0）
    Result := UnixDateDelta + ReadAMF0Number / MSecsPerDay;
    // 跳过时区部分
    Inc(p, 2);
  end;

  function ReadAMF0LString: QStringW;
  var
    ALen: Integer;
  begin
    if IntPtr(p) + 4 < IntPtr(pe) then
    begin
      ALen := ReadAMF0Int32(p, pe);
      Result := qstring.Utf8Decode(PQCharA(p), ALen);
      Inc(p, ALen);
    end
    else
    begin
      DoParseError(p, AE_UNEXPECT_EOF, SUnexpectEof);
      SetLength(Result, 0);
    end;
  end;

  procedure ReadAMF0Object;
  var
    AKey: QStringW;
  begin
    // object-property = (UTF-8 value-type) |(UTF-8-empty object-end-marker)
    // 格式= object-marker *(object-property)
    AKey := ReadAMF0String(p, pe);
    DoAddObject(False);
    while (p^ <> AMF0_OBJECTEND) and (IntPtr(p) < IntPtr(pe)) do
    begin
      with Add do
      begin
        Name := AKey;
        ReadAMF0Value(p, pe);
      end;
      AKey := ReadAMF0String(p, pe);
    end;
    if p^ = AMF0_OBJECTEND then
      Inc(p)
    else
      DoParseError(p, AE_UNEXPECT_EOF, SUnexpectEof);
  end;

  procedure ReadAMF0TypedObject;
  var
    AClass: TQAMFNode;
    AKey: QStringW;
  begin
    AClass := TQAMFNode.Create(TQAMFClassExt.Create('class'));
    AClass.Name := ReadAMF0String(p, pe);
    AClass.ParseEvents := ParseEvents;
    AClass.DoAddClass(False);
    FObjectClass := AClass;
    DoAddObject(False);
    AKey := ReadAMF0String(p, pe);
    while (p^ <> AMF0_OBJECTEND) do
    begin
      with Add do
      begin
        KeyAsString := AKey;
        ReadAMF0Value(p, pe);
      end;
      AKey := ReadAMF0String(p, pe);
    end;
  end;

  procedure ReadRefer;
  var
    ARef: TQAMFNode;
    AIdx: Integer;
  begin
    AIdx := ReadAMF0Word(p, pe);
    ARef := DoGetReferObject(AIdx, False);
    if Assigned(ARef) then // 如果找到了则复制引用的对象的值
      Assign(ARef)
    else
      DoParseError(p, AE_REFER_OBJECT_MISSED,
        Format(SReferObjectMissed, [AIdx]));
  end;
  procedure ReadMixedArray;
  var
    ACount: Integer;
    I: Integer;
    AKey: QStringW;
  begin
    ACount := ReadAMF0Int32(p, pe);
    AKey := ReadAMF0String(p, pe);
    DoAddObject(False);
    for I := 0 to ACount - 1 do
    begin
      with Add do
      begin
        Name := AKey;
        ReadAMF0Value(p, pe);
      end;
      AKey := ReadAMF0String(p, pe);
      if p^ = AMF0_OBJECTEND then
      begin
        Inc(p);
        Break;
      end;
    end;
  end;

  procedure ReadArray;
  var
    ACount: Integer;
    I: Integer;
  begin
    DataType := adtArray;
    ACount := ReadAMF0Int32(p, pe);
    DoAddObject(False);
    for I := 0 to ACount - 1 do
    begin
      Result := Add.ReadAMF0Value(p, pe);
      if not Result then
        Break;
    end;
  end;

begin
  if IntPtr(p) >= IntPtr(pe) then
  begin
    Result := False;
    DoParseError(p, AE_UNEXPECT_EOF, SUnexpectEof);
  end
  else
  begin
    AType := p^;
    Inc(p);
    Result := true;
    case AType of
      AMF0_NUMERIC:
        AsFloat := ReadAMF0Number;
      AMF0_BOOLEAN:
        AsBoolean := ReadAMF0Boolean(p, pe);
      AMF0_STRING:
        AsString := ReadAMF0String(p, pe);
      AMF0_OBJECT:
        ReadAMF0Object;
      AMF0_NULL:
        DataType := adtNull;
      AMF0_UNDEFINED:
        DataType := adtUndefined;
      AMF0_REFERENCE:
        ReadRefer;
      AMF0_MIXEDARRAY:
        ReadMixedArray;
      AMF0_ARRAY:
        ReadArray;
      AMF0_DATETIME:
        AsDateTime := ReadAMF0DateTime;
      AMF0_LONGSTRING:
        AsString := ReadAMF0LString;
      AMF0_XML:
        begin
          DataType := adtXML;
          AsXML.Parse(ReadAMF0LString);
        end;
      AMF0_TYPEDOBJECT:
        ReadAMF0TypedObject;
      AMF0_AMF3:
        begin
          DataType := adtObject;
          Result := Add.ReadAMF3Value(p, pe);
        end
    else
      begin
        Result := False;
        DoParseError(p, AE_BADTYPE, Format(SUnknownAMF0Type, [Integer(AType)]));
      end;
    end;
  end;
end;

function TQAMFNode.ReadAMF0Word(var p: PByte; const pe: PByte): Word;
begin
  Result := ExchangeByteOrder(PWord(p)^);
  Inc(p, 2);
end;

function TQAMFNode.ReadAMF3Object(var p: PByte; const pe: PByte): Boolean;
var
  AHandle, ACount, I: Integer;
  AClass: TQAMFNode;
  AObject: TQAMFNode;
  AKey: QStringW;
  function ReadFlags: TBytes;
  var
    ACount: Integer;
  begin
    SetLength(Result, 8); // 默认分配8个字节，不足再增加
    ACount := 0;
    repeat
      if ACount = Length(Result) then
        SetLength(Result, ACount + 8);
      Result[ACount] := p^;
      Inc(ACount);
      Inc(p);
    until (Result[ACount - 1] and $80) = 0;
    SetLength(Result, ACount);
  end;

  procedure AppendExtItems(a, b: BYTE);
  var
    C: BYTE;
  begin
    if (a shr b) <> 0 then
    begin
      C := b;
      while C <= 6 do
      begin
        if ((a shr C) and $1) <> 0 then
        begin
          if not Add.ReadAMF3Value(p, pe) then
          begin
            Result := False;
            Break;
          end;
        end;
        Inc(C);
      end;
    end;
  end;
  function ReadExternalChild(AFlags, ABit: BYTE; AChildName: QStringW): Boolean;
  begin
    if (AFlags and (1 shl ABit)) <> 0 then
      Result := Add(AChildName).ReadAMF3Value(p, pe)
    else
      Result := true;
  end;
  procedure ReadAbstractMessage;
  var
    AFlags: TBytes;
    I: Integer;
    ABits: Integer;
  begin
    AFlags := ReadFlags;
    for I := 0 to High(AFlags) do
    begin
      ABits := 0;
      if I = 0 then
      begin
        if not ReadExternalChild(AFlags[I], 0, 'body') then
        begin
          Result := False;
          Break;
        end;
        if not ReadExternalChild(AFlags[I], 1, 'clientId') then
        begin
          Result := False;
          Break;
        end;
        if not ReadExternalChild(AFlags[I], 2, 'destination') then
        begin
          Result := False;
          Break;
        end;
        if not ReadExternalChild(AFlags[I], 3, 'headers') then
        begin
          Result := False;
          Break;
        end;
        if not ReadExternalChild(AFlags[I], 4, 'messageId') then
        begin
          Result := False;
          Break;
        end;
        if not ReadExternalChild(AFlags[I], 5, 'timestamp') then
        begin
          Result := False;
          Break;
        end;
        if not ReadExternalChild(AFlags[I], 6, 'timeToLive') then
        begin
          Result := False;
          Break;
        end;
        ABits := 7;
      end
      else if I = 1 then
      begin
        if not ReadExternalChild(AFlags[I], 0, 'clientId') then
        begin
          Result := False;
          Break;
        end;
        if not ReadExternalChild(AFlags[I], 1, 'messageId') then
        begin
          Result := False;
          Break;
        end;
        ABits := 2;
      end;
      if Result then
        AppendExtItems(AFlags[I], ABits);
      if not Result then
        Break;
    end;
  end;

  procedure ReadAsyncMessage;
  var
    AFlags: TBytes;
    a, b: BYTE;
    I: Integer;
  begin
    ReadAbstractMessage;
    if Result then
    begin
      AFlags := ReadFlags;
      for I := 0 to High(AFlags) do
      begin
        a := AFlags[I];
        b := 0;
        if I = 0 then
        begin
          if not ReadExternalChild(AFlags[I], 0, 'correlationId') then
          begin
            Result := False;
            Exit;
          end;
          if not ReadExternalChild(AFlags[I], 1, 'correlationId') then
          begin
            Result := False;
            Exit;
          end;
          b := 2;
        end;
        if Result then
          AppendExtItems(a, b);
        if not Result then
          Break;
      end;
    end;
  end;

  procedure ReadAcknowledgeMessage;
  var
    AFlags: TBytes;
    I: Integer;
  begin
    ReadAsyncMessage;
    if Result then
    begin
      AFlags := ReadFlags;
      for I := 0 to High(AFlags) do
      begin
        AppendExtItems(AFlags[I], 0);
        if not Result then
          Break;
      end;
    end;
  end;

  procedure ReadArrayCollection;
  begin
    Result := Add('source').ReadAMF3Value(p, pe);
  end;

  procedure ReadCommandMessage;
  var
    AFlags: TBytes;
    b: BYTE;
    I: Integer;
  begin
    ReadAsyncMessage;
    if Result then
    begin
      AFlags := ReadFlags;
      for I := 0 to High(AFlags) do
      begin
        b := 0;
        if I = 0 then
        begin
          if (AFlags[0] and $1) <> 0 then
            Result := Add('operation').ReadAMF3Value(p, pe);
          b := 1;
        end;
        if Result then
          AppendExtItems(AFlags[I], b);
        if not Result then
          Break;
      end;
    end;
  end;

  procedure ReadSerializationProxy;
  begin
    Add('defaultInstance').ReadAMF3Value(p, pe);
  end;

  procedure ReadAcknowledgeMessageExt;
  begin
    ReadAcknowledgeMessage;
  end;

  procedure ReadExternalObject;
  var
    AClassName: QStringW;
  begin
    AClassName := UpperCase(AClass.Name);
    if AClassName = 'DSK' then
      AClassName := 'flex.messaging.messages.AcknowledgeMessageExt'
    else if AClassName = 'DSA' then
      AClassName := 'flex.messaging.messages.AsyncMessageExt'
    else if AClassName = 'DSC' then
      AClassName := 'flex.messaging.messages.CommandMessageExt'
    else
      AClassName := AClass.Name;
    if StartWithW(PQCharW(AClassName), 'flex.messaging.messages.', true) or
      StartWithW(PQCharW(AClassName), 'flex.messaging.io', true) then
    begin
      Result := true;
      if EndWithW(AClassName, 'AbstractMessage', true) then
        ReadAbstractMessage
      else if EndWithW(AClassName, 'AsyncMessage', true) then
        ReadAsyncMessage
      else if EndWithW(AClassName, 'AsyncMessageExt', true) then
        ReadAsyncMessage
      else if EndWithW(AClassName, 'AcknowledgeMessage', true) then
        ReadAcknowledgeMessage
      else if EndWithW(AClassName, 'AcknowledgeMessageExt', true) then
        ReadAcknowledgeMessageExt
      else if EndWithW(AClassName, 'CommandMessage', true) then
        ReadCommandMessage
      else if EndWithW(AClassName, 'CommandMessageExt', true) then
        ReadCommandMessage
      else if EndWithW(AClassName, 'ErrorMessage', true) then
        ReadAcknowledgeMessage
      else if EndWithW(AClassName, 'ArrayCollection', true) then
        ReadArrayCollection
      else if EndWithW(AClassName, 'ArrayList', true) then
        ReadArrayCollection
      else if EndWithW(AClassName, 'ObjectProxy', true) then
        Result := Add.ReadAMF3Value(p, pe)
      else if EndWithW(AClassName, 'ManagedObjectProxy', true) then
        Result := Add.ReadAMF3Value(p, pe)
      else if EndWithW(AClassName, 'SerializationProxy', true) then
        ReadSerializationProxy
      else
        Result := Add.ReadAMF3Value(p, pe);
    end
    else // 未知的类型，交由程序员自己去解析
      Result := DoReadUnknownExternalClass(AClassName, p, pe);
  end;
  procedure AssignByRefer(AIndex: Integer);
  var
    AObj: TQAMFNode;
  begin
    AObj := DoGetReferObject(AHandle, true);
    if not Assigned(AObj) then
    begin
      Result := False;
      DoParseError(p, AE_REFER_OBJECT_MISSED, Format(SReferObjectMissed,
        [AIndex]));
    end;
  end;

begin
  AHandle := ReadInt29(p, pe);
  DataType := adtObject;
  Result := False;
  if IsInline(AHandle) then // 0001
  begin
    // 一个内置对象
    if IsInline(AHandle) then // 0011
    begin
      // 内置类声明
      AClass := TQAMFNode.Create(TQAMFClassExt.Create);
      AClass.ParseEvents := ParseEvents;
      AClass.Name := ReadAMF3String(p, pe);
      if Failed then
        Exit;
      TQAMFClassExt(AClass.Ext).IsTypedObject := Length(AClass.Name) > 0;
      TQAMFClassExt(AClass.Ext).IsExternal := IsInline(AHandle); // 0111
      TQAMFClassExt(AClass.Ext).IsDynamic := IsInline(AHandle); // 1011
      ACount := AHandle;
      for I := 0 to ACount - 1 do
      begin
        AClass.Add.Name := ReadAMF3String(p, pe);
        if Failed then
          Exit;
      end;
      AClass.DoAddClass(true);;
    end
    else
    begin
      AClass := DoGetReferClass(AHandle, true);
      if not Assigned(AClass) then
        DoParseError(p, AE_REFER_OBJECT_MISSED, Format(SReferClassMissed,
          [AHandle]));
      if Failed then
        Exit;
    end;
  end
  else // 引用对象
  begin
    Result := true;
    AssignByRefer(AHandle);
    Exit;
  end;
  DoAddObject(true);
  FObjectClass := AClass;
  if TQAMFClassExt(AClass.Ext).IsExternal then
    ReadExternalObject
  else
  begin
    Result := true;
    for I := 0 to AClass.Count - 1 do
    begin
      AObject := Add;
      AObject.Name := AClass[I].Name;
      Result := AObject.ReadAMF3Value(p, pe);
      if not Result then
        Exit;
    end;
    if TQAMFClassExt(AClass.Ext).IsDynamic then
    begin
      AKey := ReadAMF3String(p, pe);
      if Failed then
      begin
        Result := False;
        Exit;
      end;
      while Length(AKey) > 0 do
      begin
        AObject := Add;
        AObject.Name := AKey;
        Result := AObject.ReadAMF3Value(p, pe);
        if not Result then
          Exit;
        AKey := ReadAMF3String(p, pe);
        if Failed then
        begin
          Result := False;
          Exit;
        end;
      end;
    end;
  end;
end;

function TQAMFNode.ReadAMF3String(var p: PByte; const pe: PByte): QStringW;
var
  ALen: Integer;
  function GetReferString(AIndex: Integer): QStringW;
  begin
    if not DoGetReferString(AIndex, true, Result) then
    begin
      SetLength(Result, 0);
      DoParseError(p, AE_REFER_OBJECT_MISSED, Format(SReferStringMissed,
        [AIndex]));
    end;
  end;
// function ReadUtf8CharCount(ACount: Integer): QStringW;
// var
// ps: PByte;
// begin
// ps := p;
// while ACount > 0 do
// begin
// Inc(p, CharSizeU(PQCharA(p)));
// Dec(ACount);
// end;
// Result := qstring.Utf8Decode(PQCharA(ps), IntPtr(p) - IntPtr(ps));
// end;

begin
  if IntPtr(p) < IntPtr(pe) then
  begin
    ALen := ReadInt29(p, pe);
    if IsInline(ALen) then
    begin
      if ALen > 0 then
      begin
        if IntPtr(p) + ALen < IntPtr(pe) then
        begin
          Result := qstring.Utf8Decode(PQCharA(p), ALen);
          Inc(p, ALen);
          DoAddString(Result, true);
        end
        else
        begin
          begin
            DoParseError(p, AE_UNEXPECT_EOF, SUnexpectEof);
            SetLength(Result, 0);
          end;
        end;
      end
      else
        SetLength(Result, 0);
    end
    else
      Result := GetReferString(ALen);
  end
  else
    SetLength(Result, 0);
end;

function TQAMFNode.ReadAMF3Value(var p: PByte; const pe: PByte): Boolean;
var
  AType: BYTE;

  function ReadAMF3Number: Double;
  begin
    Result := ExchangeByteOrder(PDouble(p)^);
    Inc(p, 8);
  end;

  function ReadAMF3DateTime: TDateTime;
  var
    V: Double;
    ARef: Integer;
    ASource: TQAMFNode;
  begin
    // AMF3 日期格式：08 Int29(引用或者是01) 浮点值
    ARef := ReadInt29(p, pe);
    if IsInline(ARef) then
    begin
      V := ReadAMF3Number;
      Result := UnixDateDelta + V / MSecsPerDay;
    end
    else
    begin
      ASource := DoGetReferObject(ARef, true);
      if Assigned(ASource) then
        Result := ASource.AsDateTime
      else
      begin
        Result := 0;
        DoParseError(p, AE_REFER_OBJECT_MISSED,
          Format(SReferObjectMissed, [ARef]));
      end;
    end;
  end;
  procedure ReadAMF3Array;
  var
    AHandle: Integer;
    AKey: QStringW;
    AChild: TQAMFNode;
    I: Integer;
    ARef: TQAMFNode;
  begin
    AHandle := ReadInt29(p, pe);
    DataType := adtArray;
    if IsInline(AHandle) then
    begin
      DoAddObject(true);
      AKey := ReadAMF3String(p, pe);
      while Length(AKey) > 0 do
      begin
        AChild := Add;
        AChild.KeyAsString := AKey;
        Result := AChild.ReadAMF3Value(p, pe);
        if not Result then
        begin
          // OutputDebugString(PChar('Cant read ' + AKey + ' value'));
          Exit;
        end;
        AKey := ReadAMF3String(p, pe);
      end;
      for I := 0 to AHandle - 1 do
      begin
        AChild := Add();
        AChild.KeyAsInteger := I;
        Result := AChild.ReadAMF3Value(p, pe);
        if not Result then
        begin
          // OutputDebugString(PChar('Cant read ' + IntToStr(I) + ' value'));
          Exit;
        end;
      end;
    end
    else
    begin
      ARef := DoGetReferObject(AHandle, true);
      if Assigned(ARef) then
        SetAsBytes(ARef.AsBytes)
      else
      begin
        Result := False;
        DoParseError(p, AE_REFER_OBJECT_MISSED, Format(SReferObjectMissed,
          [AHandle]));
      end;
    end;
  end;
  procedure ReadAMF3Bytes;
  var
    ALen: Integer;
    ARef: TQAMFNode;
  begin
    ALen := ReadInt29(p, pe);
    if IsInline(ALen) then
    begin
      if ALen > 0 then
      begin
        if IntPtr(p) + ALen < IntPtr(pe) then
        begin
          SetAsBytes(p, ALen);
          Inc(p, ALen);
        end
        else
        begin
          Result := False;
          DoParseError(p, AE_UNEXPECT_EOF, SUnexpectEof);
        end;
      end
      else
        SetAsBytes(nil, 0);
    end
    else
    begin
      ARef := DoGetReferObject(ALen, true);
      if Assigned(ARef) then
        SetAsBytes(ARef.AsBytes)
      else
      begin
        Result := False;
        DoParseError(p, AE_REFER_OBJECT_MISSED,
          Format(SReferObjectMissed, [ALen]));
      end;
    end;
  end;

  procedure ReadAMF3Vector;
  var
    AHandle: Integer;
    AVectorExt: TQAMFVectorExt;
    I: Integer;
    ARef: TQAMFNode;
  begin
    AHandle := ReadInt29(p, pe);
    if IsInline(AHandle) then
    begin
      AVectorExt := TQAMFVectorExt.Create;
      Ext := AVectorExt;
      AVectorExt.VectorType := TQAMFVectorType(AType);
      AVectorExt.IsFixed := ReadAMF0Boolean(p, pe);
      DataType := adtVector;
      DoAddObject(true);
      case AVectorExt.VectorType of
        vtInteger:
          for I := 0 to AHandle - 1 do
          begin
            if IntPtr(p) + 4 >= IntPtr(pe) then
            begin
              Result := False;
              DoParseError(p, AE_UNEXPECT_EOF, SUnexpectEof);
            end
            else
              Add.AsInteger := ReadAMF0Int32(p, pe);
          end;
        vtDWord:
          for I := 0 to AHandle - 1 do
          begin
            if IntPtr(p) + 4 >= IntPtr(pe) then
            begin
              Result := False;
              DoParseError(p, AE_UNEXPECT_EOF, SUnexpectEof);
            end
            else
            begin
              Add.AsInteger := ExchangeByteOrder(PCardinal(p)^);
              Inc(p, 4);
            end;
          end;
        vtFloat:
          begin
            for I := 0 to AHandle - 1 do
            begin
              if IntPtr(p) + 8 >= IntPtr(pe) then
              begin
                Result := False;
                DoParseError(p, AE_UNEXPECT_EOF, SUnexpectEof);
              end
              else
              begin
                Add.AsFloat := ExchangeByteOrder(PDouble(p)^);
                Inc(p, 8);
              end;
            end;
          end;
        vtObject:
          begin
            for I := 0 to AHandle - 1 do
            begin
              Result := Add.ReadAMF3Value(p, pe);
              if not Result then
              begin
                // OutputDebugString(PChar('Cant read object ' + IntToStr(I) +
                // ' value'));
                Break;
              end;
            end;
          end;
      end;
    end
    else
    begin
      ARef := DoGetReferObject(AHandle, true);
      if Assigned(ARef) then
        Assign(ARef)
      else
      begin
        Result := False;
        DoParseError(p, AE_REFER_OBJECT_MISSED, Format(SReferObjectMissed,
          [AHandle]));
      end;
    end;
  end;

  procedure ReadAMF3Dictionary;
  var
    AHandle: Integer;
    I: Integer;
    ARef: TQAMFNode;
    AExt: TQAMFDictionaryExt;
    AChild: TQAMFNode;
  begin
    AHandle := ReadInt29(p, pe);
    if IsInline(AHandle) then
    begin
      AExt := TQAMFDictionaryExt.Create;
      Ext := AExt;
      AExt.IsWeak := ReadAMF0Boolean(p, pe);
      DataType := adtDictionary;
      DoAddObject(true);
      for I := 0 to AHandle - 1 do
      begin
        AChild := Add;
        AChild.KeyType := adtDictionaryItem;
        AChild.DataType := adtDictionaryItem;
        Result := AChild.KeyAsObject.ReadAMF3Value(p, pe);
        if not Result then
        begin
          // OutputDebugString('Cant read Dictionary item key');
          Exit;
        end;
        Result := AChild.AsObject.ReadAMF3Value(p, pe);
        if not Result then
        begin
          // OutputDebugString('Cant read Dictionary item value');
          Exit;
        end;
      end;
    end
    else
    begin
      ARef := DoGetReferObject(AHandle, true);
      if Assigned(ARef) then
        Assign(ARef)
      else
      begin
        Result := False;
        DoParseError(p, AE_REFER_OBJECT_MISSED, Format(SReferObjectMissed,
          [AHandle]));
      end;
    end;
  end;

begin
  if IntPtr(p) >= IntPtr(pe) then
  begin
    Result := False;
    DoParseError(p, AE_UNEXPECT_EOF, SUnexpectEof);
  end
  else
  begin
    AType := p^;
    Inc(p);
    Result := true;
    case AType of
      AMF3_UNDEFINED:
        DataType := adtUndefined;
      AMF3_NULL:
        DataType := adtNull;
      AMF3_FALSE:
        AsBoolean := False;
      AMF3_TRUE:
        AsBoolean := true;
      AMF3_INTEGER:
        AsInteger := ReadInt29(p, pe);
      AMF3_FLOAT:
        AsFloat := ReadAMF3Number;
      AMF3_STRING:
        begin
          AsString := ReadAMF3String(p, pe);
          Result := not Failed;
        end;
      AMF3_XMLDOC, AMF3_XML:
        begin
          DataType := adtXML;
          AsXML.Parse(ReadAMF3String(p, pe));
        end;
      AMF3_DATETIME:
        AsDateTime := ReadAMF3DateTime;
      AMF3_ARRAY:
        ReadAMF3Array;
      AMF3_OBJECT:
        Result := ReadAMF3Object(p, pe);
      AMF3_BYTEARRAY:
        ReadAMF3Bytes;
      AMF3_INT_VECTOR, AMF3_UINT_VECTOR, AMF3_DOUBLE_VECTOR, AMF3_OBJECT_VECTOR:
        ReadAMF3Vector;
      AMF3_DICTIONARY:
        ReadAMF3Dictionary
    else
      begin
        Result := False;
        DoParseError(p, AE_BADTYPE, Format(SUnknownAMF3Type, [Integer(AType)]));
      end;
    end;
  end;
end;

function TQAMFNode.ReadInt29(var p: PByte; const pe: PByte): Integer;
const
  AMF3_INT29_FIX = 1 shl 29;
begin
  if (p^ and $80) <> 0 then
  begin
    Result := (p^ and $7F) shl 7; // p[0]
    Inc(p);
    if (p^ and $80) <> 0 then
    begin
      Result := (Result + (p^ and $7F)) shl 7; // p[1]
      Inc(p);
      if (p^ and $80) <> 0 then
      begin
        Result := (Result + (p^ and $7F)) shl 8; // p[2]
        Inc(p);
        Inc(Result, p^);
      end
      else
        Inc(Result, p^);
    end
    else
      Inc(Result, p^);
    Inc(p);
  end
  else
  begin
    Result := p^;
    Inc(p);
  end;
  if Result > AMF3_MAX_INT then
    Dec(Result, AMF3_INT29_FIX);
end;

function TQAMFNode.Remove(AItemIndex: Integer): TQAMFNode;
begin
  if FDataType in [adtArray, adtObject, adtVector, adtDictionary] then
  begin
    if (AItemIndex >= 0) and (AItemIndex < Count) then
    begin
      Result := ListItems[AItemIndex];
      ListItems.Delete(AItemIndex);
      Result.FParent := nil;
    end
    else
      Result := nil;
  end
  else
    Result := nil;
end;

procedure TQAMFNode.Remove(AItem: TQAMFNode);
begin
  Remove(AItem.ItemIndex);
end;

procedure TQAMFNode.SaveToFile(AFileName: QStringW);
var
  AStream: TMemoryStream;
begin
  AStream := TMemoryStream.Create;
  try
    SaveToStream(AStream);
    AStream.SaveToFile(AFileName);
  finally
    FreeAndNil(AStream);
  end;
end;

procedure TQAMFNode.SaveToStream(AStream: TStream);
var
  ABytes: TBytes;
begin
  ABytes := Encode;
  if Length(ABytes) > 0 then
    AStream.WriteBuffer(ABytes[0], Length(ABytes));
end;

procedure TQAMFNode.SetAsBoolean(const Value: Boolean);
begin
  SetAMFValue(FValue, SetDataType, adtBoolean, @Value, 1);
end;

procedure TQAMFNode.SetAsBytes(const p: PByte; l: Integer);
begin
  SetAMFValue(FValue, SetDataType, adtBytes, p, l);
end;

procedure TQAMFNode.SetAsBytes(const Value: TBytes);
begin
  if Length(Value) > 0 then
    SetAMFValue(FValue, SetDataType, adtBytes, @Value[0], Length(Value))
  else
    SetAMFValue(FValue, SetDataType, adtBytes, nil, 0);
end;

procedure TQAMFNode.SetAsDateTime(const Value: TDateTime);
begin
  SetAMFValue(FValue, SetDataType, adtDateTime, @Value, SizeOf(Value));
end;

procedure TQAMFNode.SetAsFloat(const Value: Double);
begin
  SetAMFValue(FValue, SetDataType, adtFloat, @Value, SizeOf(Value));
end;

procedure TQAMFNode.SetAsInt64(const Value: Int64);
begin
  SetAMFValue(FValue, SetDataType, adtInteger, @Value, SizeOf(Value));
end;

procedure TQAMFNode.SetAsInteger(const Value: Integer);
begin
  SetAsInt64(Value);
end;

procedure TQAMFNode.SetAsString(const Value: QStringW);
begin
  SetAMFValue(FValue, SetDataType, adtString, PByte(Value),
    Length(Value) shl 1);
end;

procedure TQAMFNode.SetDataType(const Value: TQAMFDataType);
begin
  SetAMFType(FValue, FDataType, Value);
end;

procedure TQAMFNode.SetExt(const Value: TQAMFNodeExt);
begin
  if FExt <> Value then
  begin
    if Assigned(FExt) then
      FreeAndNil(FExt);
    FExt := Value;
  end;
end;

procedure TQAMFNode.SetKeyAsBoolean(const Value: Boolean);
begin
  SetAMFValue(FKey, SetKeyType, adtBoolean, @Value, SizeOf(Value));
end;

procedure TQAMFNode.SetKeyAsBytes(const Value: TBytes);
begin
  if Length(Value) > 0 then
    SetAMFValue(FKey, SetKeyType, adtBytes, @Value[0], Length(Value))
  else
    SetAMFValue(FKey, SetKeyType, adtBytes, nil, 0)
end;

procedure TQAMFNode.SetKeyAsDateTime(const Value: TDateTime);
begin
  SetAMFValue(FKey, SetKeyType, adtDateTime, @Value, SizeOf(Value));
end;

procedure TQAMFNode.SetKeyAsFloat(const Value: Double);
begin
  SetAMFValue(FKey, SetKeyType, adtFloat, @Value, SizeOf(Value));
end;

procedure TQAMFNode.SetKeyAsInt64(const Value: Int64);
begin
  SetAMFValue(FKey, SetKeyType, adtInteger, @Value, SizeOf(Value));
end;

procedure TQAMFNode.SetKeyAsInteger(const Value: Integer);
begin
  SetKeyAsInt64(Value);
end;

procedure TQAMFNode.SetKeyAsString(const Value: QStringW);
begin
  SetAMFValue(FKey, SetKeyType, adtString, PByte(Value), Length(Value) shl 1);
end;

procedure TQAMFNode.SetKeyType(const Value: TQAMFDataType);
begin
  SetAMFType(FKey, FKeyType, Value);
end;

procedure TQAMFNode.SetParseEvents(const Value: PQAMFParseEvents);
var
  I: Integer;
begin
  if FParseEvents <> Value then
  begin
    FParseEvents := Value;
    for I := 0 to Count - 1 do
      Items[I].ParseEvents := Value;
  end;
end;

procedure TQAMFNode.StreamFromKey(AStream: TStream);
var
  ABytes: TBytes;
begin
  ABytes := KeyAsBytes;
  if Length(ABytes) > 0 then
    AStream.WriteBuffer(ABytes[0], Length(ABytes));
end;

procedure TQAMFNode.StreamFromValue(AStream: TStream);
var
  ABytes: TBytes;
begin
  ABytes := AsBytes;
  if Length(ABytes) > 0 then
    AStream.WriteBuffer(ABytes[0], Length(ABytes));
end;

procedure TQAMFNode.TypeNeeded(ATypes: TQAMFDataTypes; AType: TQAMFDataType);
begin
  if DataType in ATypes then
    Exit;
  DataType := AType;
end;

function TQAMFNode.ValueByName(AName, ADefVal: QStringW): QStringW;
var
  AItem: TQAMFNode;
begin
  AItem := ItemByName(AName);
  if Assigned(AItem) then
    Result := AItem.AsString
  else
    Result := ADefVal;
end;

function TQAMFNode.ValueByPath(APath, ADefVal: QStringW): QStringW;
var
  AItem: TQAMFNode;
begin
  AItem := ItemByPath(APath);
  if Assigned(AItem) then
    Result := AItem.AsString
  else
    Result := ADefVal;
end;

procedure TQAMFNode.ValueFromFile(const AFileName: QStringW);
var
  AStream: TFileStream;
begin
  AStream := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyWrite);
  try
    ValueFromStream(AStream);
  finally
    FreeAndNil(AStream);
  end;
end;

procedure TQAMFNode.ValueFromStream(AStream: TStream);
var
  ABytes: TBytes;
begin
  SetLength(ABytes, AStream.Size - AStream.Position);
  AStream.ReadBuffer(ABytes[0], Length(ABytes));
  AsBytes := ABytes;
end;

procedure TQAMFNode.WriteAMF0String(AHelper: TQBytesCatHelper; S: QStringW);
var
  l: Word;
  V: QStringA;
begin
  V := qstring.Utf8Encode(S);
  l := V.Length;
  AHelper.Cat(ExchangeByteOrder(l));
  AHelper.Cat(V);
end;

procedure TQAMFNode.WriteAMF0Value(AHelper: TQBytesCatHelper; AItem: TQAMFNode);
begin

end;

procedure TQAMFNode.WriteAMF3Value(AHelper: TQBytesCatHelper; AItem: TQAMFNode);
  procedure WriteInt29(V: Integer);
  var
    b: BYTE;
  begin
    repeat
      if V < 128 then
        AHelper.Cat(BYTE(V))
      else
      begin
        b := (V and $7F) or $80;
        AHelper.Cat(b);
      end;
      V := V shr 7;
    until V = 0;
  end;

  procedure WriteString(S: QStringW);
  var
    U: QStringA;
  begin
    U := qstring.Utf8Encode(S);
    WriteInt29((U.Length shl 1) or 1);
    AHelper.Cat(U);
  end;

  procedure WriteNullString;
  begin
    AHelper.Cat(BYTE(01));
  end;

  procedure WriteDateTime(V: TDateTime);
  var
    D: Double;
  begin
    D := (V - UnixDateDelta) * MSecsPerDay;
{$IF RTLVersion<19}
    AHelper.Cat(ExchangeByteOrder(PInt64(@D)^));
{$ELSE}
    AHelper.Cat(ExchangeByteOrder(D));
{$IFEND}
  end;

  procedure WriteObject(AItem: TQAMFNode);
  var
    J: Integer;
    AFlags: Integer;
  begin
    AFlags := 11; // 1(动态)0(非外部)1(包含类声明)1(内置)
    WriteInt29(AFlags);
    if AItem.ObjectClass <> nil then
      WriteString(AItem.ObjectClass.Name)
    else
      WriteNullString;
    // 按动态类别来写
    for J := 0 to AItem.Count - 1 do
    begin
      WriteString(AItem[J].Name);
      WriteAMF3Value(AHelper, AItem[J]);
    end;
  end;

  procedure WriteBytes(const V: TBytes);
  var
    l: Integer;
  begin
    l := (Length(V) shl 1) or 1;
    WriteInt29(l);
    AHelper.Cat(V);
  end;

  procedure WriteFloat(const V: Double);
  var
    I64: Int64 absolute V;
  begin
    AHelper.Cat(ExchangeByteOrder(I64));
  end;

begin
  case AItem.DataType of
    adtUndefined:
      AHelper.Cat(BYTE(AMF3_UNDEFINED));
    adtNull:
      AHelper.Cat(BYTE(AMF3_NULL));
    adtBoolean:
      begin
        if AItem.AsBoolean then
          AHelper.Cat(BYTE(AMF3_TRUE))
        else
          AHelper.Cat(BYTE(AMF3_FALSE));
      end;
    adtInteger:
      begin
        AHelper.Cat(BYTE(AMF3_INTEGER));
        WriteInt29(AItem.AsInteger);
      end;
    adtFloat:
      begin
        AHelper.Cat(BYTE(AMF3_FLOAT));
        WriteFloat(AItem.AsFloat);
      end;
    adtString:
      begin
        AHelper.Cat(BYTE(AMF3_STRING));
        WriteString(AItem.AsString);
      end;
    adtDateTime:
      begin
        AHelper.Cat(BYTE(AMF3_DATETIME));
        AHelper.Cat(BYTE(1)); // 直接数据
        WriteDateTime(AItem.AsDateTime);
      end;
    adtArray:
      ;
    adtObject:
      begin
        AHelper.Cat(BYTE(AMF3_OBJECT));
        WriteObject(AItem);
      end;
    adtXML:
      begin
        AHelper.Cat(BYTE(AMF3_XML));
        WriteString(AItem.AsXML.AsXML);
      end;
    adtBytes:
      begin
        AHelper.Cat(BYTE(AMF3_BYTEARRAY));
        WriteBytes(AItem.AsBytes);
      end;
    adtVector:
      ;
    adtDictionary:
      ;
  end;
end;

function TQAMFNode.Add(ADataType: TQAMFDataType): TQAMFNode;
begin
  Result := Add;
  Result.DataType := ADataType;
end;

function TQAMFNode.Add(AName: QStringW): TQAMFNode;
begin
  Result := Add;
  Result.Name := AName;
end;

function TQAMFNode.Add(AName: QStringW; ADataType: TQAMFDataType): TQAMFNode;
begin
  Result := Add(ADataType);
  Result.Name := AName;
end;

procedure TQAMFNode.Assign(ANode: TQAMFNode);
var
  I: Integer;
  AChild: TQAMFNode;
begin
  if Assigned(ANode.Ext) then
    Ext := ANode.Ext.Copy;
  case ANode.DataType of
    adtUndefined, adtNull:
      DataType := ANode.DataType;
    adtBoolean:
      AsBoolean := ANode.AsBoolean;
    adtInteger:
      AsInt64 := ANode.AsInt64;
    adtFloat:
      AsFloat := ANode.AsFloat;
    adtString:
      AsString := ANode.AsString;
    adtDateTime:
      AsDateTime := ANode.AsDateTime;
    adtArray:
      begin
        DataType := ANode.DataType;
        Clear;
        for I := 0 to ANode.Count - 1 do
          Add.Assign(ANode[I]);
      end;
    adtObject:
      begin
        DataType := ANode.DataType;
        Clear;
        for I := 0 to ANode.Count - 1 do
        begin
          AChild := ANode[I];
          with Add do
          begin
            case AChild.KeyType of
              adtUndefined, adtNull:
                KeyType := AChild.KeyType;
              adtBoolean:
                KeyAsBoolean := AChild.KeyAsBoolean;
              adtInteger:
                KeyAsInt64 := AChild.AsInt64;
              adtFloat:
                KeyAsFloat := AChild.KeyAsFloat;
              adtString:
                KeyAsString := AChild.KeyAsString;
              adtDateTime:
                KeyAsDateTime := AChild.KeyAsDateTime;
              adtArray:
                begin
                  KeyType := adtArray;
                  KeyAsArray.Assign(AChild.KeyAsArray);
                end;
              adtObject:
                begin
                  KeyType := adtObject;
                  KeyAsObject.Assign(AChild.KeyAsObject);
                end;
              adtXML:
                begin
                  KeyType := adtXML;
                  KeyAsXML.Assign(AChild.KeyAsXML);
                end;
              adtBytes:
                begin
                  KeyType := adtBytes;
                  KeyAsBytes := AChild.KeyAsBytes;
                end;
              adtVector:
                ;
              adtDictionary:
                ;
            end;
            Assign(AChild);
          end;
        end;
      end;
    adtXML:
      AsXML.Assign(ANode.AsXML);
    adtBytes:
      AsBytes := ANode.AsBytes;
    adtVector:
      ;
    adtDictionary:
      ;
  end;
end;

function TQAMFNode.BoolByName(AName: QStringW; ADefVal: Boolean): Boolean;
var
  AItem: TQAMFNode;
begin
  AItem := ItemByName(AName);
  if Assigned(AItem) then
  begin
    try
      Result := AItem.AsBoolean
    except
      Result := ADefVal;
    end;
  end
  else
    Result := ADefVal;
end;

function TQAMFNode.BoolByPath(APath: QStringW; ADefVal: Boolean): Boolean;
var
  AItem: TQAMFNode;
begin
  AItem := ItemByPath(APath);
  if Assigned(AItem) then
  begin
    try
      Result := AItem.AsBoolean
    except
      Result := ADefVal;
    end;
  end
  else
    Result := ADefVal;

end;

function TQAMFNode.BytesByPath(APath: QStringW; ADefVal: TBytes): TBytes;
var
  AItem: TQAMFNode;
begin
  AItem := ItemByPath(APath);
  if Assigned(AItem) then
  begin
    try
      Result := AItem.AsBytes;
    except
      Result := ADefVal;
    end;
  end
  else
    Result := ADefVal;
end;

function TQAMFNode.Add: TQAMFNode;
begin
  Result := FChildClass.Create;
  // 默认添加的为对象，以保证最大的兼容性
  Add(Result);
end;

function TQAMFNode.Add(ANode: TQAMFNode): Integer;
begin
  TypeNeeded([adtArray, adtObject, adtVector, adtDictionary], adtObject);
  ANode.FParent := Self;
  Result := ListItems.Add(ANode);
end;

procedure TQAMFNode.Clear;
var
  I: Integer;
  AItem: TQAMFNode;
begin
  if DataType in [adtArray, adtObject, adtVector, adtDictionary] then
  begin
    for I := 0 to ListItems.Count - 1 do
    begin
      AItem := ListItems[I];
      FreeObject(AItem);
    end;
    ListItems.Clear;
  end;
end;

function TQAMFNode.GetCount: Integer;
begin
  if DataType in [adtArray, adtObject, adtVector, adtDictionary] then
    Result := ListItems.Count
  else
    Result := 0;
end;

function TQAMFNode.GetItemIndex: Integer;
var
  I: Integer;
begin
  Result := -1;
  if Assigned(Parent) then
  begin
    for I := 0 to Parent.Count - 1 do
    begin
      if Parent[I] = Self then
      begin
        Result := I;
        Break;
      end;
    end;
  end;
end;

function TQAMFNode.GetItems(AIndex: Integer): TQAMFNode;
begin
  if DataType in [adtArray, adtObject, adtVector, adtDictionary] then
    Result := ListItems[AIndex]
  else
    raise Exception.CreateFmt(SOutOfRange, [AIndex, -1]);
end;

{ TQAMF }

constructor TQAMF.Create;
begin
  inherited;
  DataType := adtObject;
  FAMF0Objects := TQAMFList.Create;
  FAMFStrings := TStringList.Create;
  FAMF3Objects := TQAMFList.Create;
  FAMF3Defines := TQAMFList.Create;
  FHeaders := TQAMFHeaders.Create(adtObject);
  FHeaders.Name := 'headers';
  Add(FHeaders);
  FMessages := TQAMFMessages.Create(adtArray);
  FMessages.Name := 'messages';
  Add(FMessages);
  FPathDelimiter := '\';
end;

function TQAMF.Decode(var p: PByte; l: Integer; AIsAMF3: Boolean): Boolean;
begin
  Result := TryParse(p, l);
end;

destructor TQAMF.Destroy;
  procedure FreeDefines;
  var
    I: Integer;
  begin
    for I := 0 to FAMF3Defines.Count - 1 do
      FreeObject(FAMF3Defines[I]);
    FreeAndNil(FAMF3Defines);
  end;

begin
  FreeAndNil(FAMF0Objects);
  FreeAndNil(FAMFStrings);
  FreeAndNil(FAMF3Objects);
  FreeDefines;
  inherited;
end;

procedure TQAMF.DoAddAMF0Class(AClass: TQAMFNode);
begin
  // AMF0 的类型也是添加到对象引用表里的
  FAMF0Objects.Add(AClass);
end;

procedure TQAMF.DoAddAMF0Object(AObject: TQAMFNode);
begin
  FAMF0Objects.Add(AObject);
end;

procedure TQAMF.DoAddAMF0String(ASender: TQAMFNode; const S: QStringW);
begin
  FAMFStrings.Add(S);
end;

procedure TQAMF.DoAddAMF3Class(AClass: TQAMFNode);
begin
  FAMF3Defines.Add(AClass);
end;

procedure TQAMF.DoAddAMF3Object(AObject: TQAMFNode);
begin
  FAMF3Objects.Add(AObject);
end;

procedure TQAMF.DoAddAMF3String(ASender: TQAMFNode; const S: QStringW);
begin
  FAMFStrings.Add(S);
end;

procedure TQAMF.DoAMFParseError(ASender: TQAMFNode; p: PByte;
  AErrorCode: Integer; const AErrorMsg: QStringW);
begin
  FErrorAt := p;
  FParseError := AErrorCode;
  FParseErrorMsg := AErrorMsg;
end;

procedure TQAMF.DoGetAMF0Class(ASender: TQAMFNode; AIndex: Integer;
  var AObj: TQAMFNode);
begin
  AObj := GetItemInList(FAMF3Defines, AIndex);
end;

procedure TQAMF.DoGetAMF0Object(ASender: TQAMFNode; AIndex: Integer;
  var AObj: TQAMFNode);
begin
  AObj := GetItemInList(FAMF0Objects, AIndex);
end;

procedure TQAMF.DoGetAMF0String(ASender: TQAMFNode; AIndex: Integer;
  var S: QStringW; var AExists: Boolean);
begin
  AExists := (AIndex >= 0) and (AIndex < FAMFStrings.Count);
  if AExists then
    S := FAMFStrings[AIndex];
end;

procedure TQAMF.DoGetAMF3Class(ASender: TQAMFNode; AIndex: Integer;
  var AObj: TQAMFNode);
begin
  AObj := GetItemInList(FAMF3Defines, AIndex);
end;

procedure TQAMF.DoGetAMF3Object(ASender: TQAMFNode; AIndex: Integer;
  var AObj: TQAMFNode);
begin
  AObj := GetItemInList(FAMF3Objects, AIndex);
end;

procedure TQAMF.DoGetAMF3String(ASender: TQAMFNode; AIndex: Integer;
  var S: QStringW; var AExists: Boolean);
begin
  AExists := (AIndex >= 0) and (AIndex < FAMFStrings.Count);
  if AExists then
    S := FAMFStrings[AIndex];
end;

procedure TQAMF.DoParseUnknownExternal(ASender: TQAMFNode; AClassName: QStringW;
  var p: PByte; const pe: PByte);
begin
  if Assigned(FOnParseUnknownExternal) then
    FOnParseUnknownExternal(ASender, AClassName, p, pe)
  else
    DoParseError(p, AE_UNKNOWN_EXTERNAL, Format(SUnknownExternal,
      [AClassName]));
end;

function TQAMF.GetAsString: QStringW;
begin
  Result := '{';
  if FHeaders.Count > 0 then
    Result := Result + SLineBreak + '"headers":' + FHeaders.AsString + ',';
  if FMessages.Count > 0 then
    Result := Result + SLineBreak + '"messages":' + FMessages.AsString + ',';
  if Length(Result) > 0 then
    Result := LeftStrW(Result, Length(Result) - 1, False);
  Result := Result + SLineBreak + '}';
end;

function TQAMF.GetItemInList(AParent: TQAMFList; AIndex: Integer): TQAMFNode;
begin
  if (AIndex >= 0) and (AIndex < AParent.Count) then
    Result := AParent[AIndex]
  else
    Result := nil;
end;

procedure TQAMF.InternalEncode(AHelper: TQBytesCatHelper);
var
  I: Integer;
begin
  AHelper.Cat(Word($0300)); // 版本号 00 03
  AHelper.Cat(ExchangeByteOrder(Word(FHeaders.Count))); // Header的数量
  if FHeaders.Count > 0 then
  begin
    for I := 0 to FHeaders.Count - 1 do
      FHeaders[I].InternalEncode(AHelper);
  end;
  AHelper.Cat(ExchangeByteOrder(Word(FMessages.Count)));
  for I := 0 to FMessages.Count - 1 do
    (FMessages[I] as TQAMFMessage).InternalEncode(AHelper);
end;

function TQAMF.LastParseError: Integer;
begin
  Result := FParseError;
end;

procedure TQAMF.Parse(p: PByte; ALen: Integer);
begin
  if not TryParse(p, ALen) then
    raise EStreamError.Create(SBadStreamFormat);
end;

procedure TQAMF.ParseAMF0Data(p: PByte; ALen: Integer);
begin
  if not TryParseAMF0Data(p, ALen) then
    RaiseError(p);
end;

procedure TQAMF.ParseAMF3Data(p: PByte; ALen: Integer);
begin
  if not TryParseAMF3Data(p, ALen) then
    RaiseError(p);
end;

procedure TQAMF.RaiseError(ps: PByte);
var
  AOffset: Integer;
begin
  AOffset := IntPtr(FErrorAt) - IntPtr(ps);
  raise Exception.CreateFmt(SAMFParseError, [AOffset, FParseError,
    FParseErrorMsg]);
end;

procedure TQAMF.Reset;
begin
  FAMF0Objects.Clear;
  FAMFStrings.Clear;
  FAMF3Objects.Clear;
  FAMF3Defines.Clear;
  FHeaders.Clear;
  FMessages.Clear;
  FErrorOffset := 0;
  FParseError := 0;
  SetLength(FParseErrorMsg, 0);
  FErrorAt := nil;
end;

procedure TQAMF.SetParseEvents(const Value: PQAMFParseEvents);
begin
  inherited;
  FHeaders.ParseEvents := Value;
  FMessages.ParseEvents := Value;
end;

procedure TQAMF.SetupEvents(var AEvents: TQAMFParseEvents);
begin
  AEvents.ParseRoot := Self;
  AEvents.OnParseError := DoAMFParseError;
  AEvents.OnAddAMF0Object := DoAddAMF0Object;
  AEvents.OnAddAMF3Object := DoAddAMF3Object;
  AEvents.OnGetAMF0Object := DoGetAMF0Object;
  AEvents.OnGetAMF3Object := DoGetAMF3Object;
  AEvents.OnAddAMF0Class := DoAddAMF0Class;
  AEvents.OnAddAMF3Class := DoAddAMF3Class;
  AEvents.OnGetAMF0Class := DoGetAMF0Class;
  AEvents.OnGetAMF3Class := DoGetAMF3Class;
  AEvents.OnAddAMF0String := DoAddAMF0String;
  AEvents.OnAddAMF3String := DoAddAMF3String;
  AEvents.OnGetAMF0String := DoGetAMF0String;
  AEvents.OnGetAMF3String := DoGetAMF3String;
  AEvents.OnParseUnknownExternal := DoParseUnknownExternal;
  ParseEvents := @AEvents;
end;

function TQAMF.TryParse(p: PByte; ALen: Integer): Boolean;
var
  ps, pe: PByte;
  AEvents: TQAMFParseEvents;
  function ReadHeader: Boolean;
  var
    AHeader: TQAMFHeader;
    ALen: Integer;
    AExt: TQAMFHeaderExt;
  begin
    AHeader := FHeaders.Add(adtObject) as TQAMFHeader;
    AExt := AHeader.Ext as TQAMFHeaderExt;
    AHeader.Ext := AExt;
    AHeader.Name := ReadAMF0String(p, pe);
    AExt.Required := ReadAMF0Boolean(p, pe);
    ALen := ReadAMF0Int32(p, pe); // 头部长度
    if IntPtr(p) + ALen < IntPtr(pe) then
      Result := AHeader.ReadAMF0Value(p, pe)
    else
    begin
      DoParseError(p, AE_UNEXPECT_EOF, SUnexpectEof);
      Result := False;
    end;
  end;

  function DecodeHeaders: Boolean;
  var
    ACount: Word;
    I: Integer;
  begin
    ACount := ReadAMF0Word(p, pe);
    Result := true;
    for I := 0 to ACount - 1 do
    begin
      Result := ReadHeader;
      if not Result then
        Break;
    end;
  end;

  function ReadMessage: Boolean;
  var
    AMsg: TQAMFMessage;
    ALen: Integer;
    AMsgExt: TQAMFMessageExt;
  begin
    AMsg := FMessages.Add(adtObject) as TQAMFMessage;
    AMsgExt := AMsg.Ext as TQAMFMessageExt;
    AMsgExt.Target := ReadAMF0String(p, pe);
    AMsgExt.Response := ReadAMF0String(p, pe);
    ALen := ReadAMF0Int32(p, pe);
    if IntPtr(p) + ALen <= IntPtr(pe) then
      Result := AMsg.ReadAMF0Value(p, pe)
    else
    begin
      DoParseError(p, AE_UNEXPECT_EOF, SUnexpectEof);
      Result := False;
    end;
  end;

  function DecodeMessages: Boolean;
  var
    ACount: Integer;
    I: Integer;
  begin
    ACount := ReadAMF0Word(p, pe);
    Result := true;
    for I := 0 to ACount - 1 do
    begin
      Result := ReadMessage;
      if not Result then
        Break;
    end;
  end;
  function CheckVersion: Boolean;
  var
    V: Word;
  begin
    V := ReadAMF0Word(p, pe);
    Result := (V = 0) or (V = 3);
    if not Result then
      DoParseError(p, AE_BAD_FORMAT, SBadStreamFormat);
  end;

begin
  ps := p;
  pe := PByte(IntPtr(p) + ALen);
  Result := CheckVersion;
  Reset;
  try
    SetupEvents(AEvents);
    // 检查文件头部版本标记 00 00 或 00 03
    if Result then
      Result := DecodeHeaders and DecodeMessages;
  finally
    ParseEvents := nil;
    if not Result then
      FErrorOffset := IntPtr(FErrorAt) - IntPtr(ps);
  end;
end;

function TQAMF.TryParseAMF0Data(p: PByte; ALen: Integer): Boolean;
var
  AMsg: TQAMFMessage;
  AEvents: TQAMFParseEvents;
  ps: PByte;
begin
  ps := p;
  Result := False;
  Reset;
  try
    SetupEvents(AEvents);
    AMsg := TQAMFMessage.Create(adtObject);
    FMessages.Add(AMsg);
    Result := AMsg.ReadAMF0Value(p, PByte(IntPtr(p) + ALen));
  finally
    ParseEvents := nil;
    if not Result then
      FErrorOffset := IntPtr(FErrorAt) - IntPtr(ps);
  end;
end;

function TQAMF.TryParseAMF3Data(p: PByte; ALen: Integer): Boolean;
var
  AMsg: TQAMFMessage;
  AEvents: TQAMFParseEvents;
  ps: PByte;

begin
  ps := p;
  Result := False;
  Reset;
  try
    SetupEvents(AEvents);
    AMsg := TQAMFMessage.Create(adtObject);
    FMessages.Add(AMsg);
    Result := AMsg.ReadAMF3Value(p, PByte(IntPtr(p) + ALen));
  finally
    ParseEvents := nil;
    if not Result then
      FErrorOffset := IntPtr(FErrorAt) - IntPtr(ps);
  end;
end;

{ TQAMFMessage }

constructor TQAMFMessage.Create;
begin
  inherited;
  Ext := TQAMFMessageExt.Create;
end;

procedure TQAMFMessage.InternalEncode(AHelper: TQBytesCatHelper);
var
  l, p: Integer;
  AExt: TQAMFMessageExt;
begin
  AExt := Ext as TQAMFMessageExt;
  if Assigned(AExt) then
  begin
    WriteAMF0String(AHelper, AExt.Target);
    WriteAMF0String(AHelper, AExt.Response);
  end
  else
  begin
    WriteAMF0String(AHelper, '');
    WriteAMF0String(AHelper, '');
  end;
  l := AHelper.Position;
  AHelper.Cat(Integer(0));
  AHelper.Cat(BYTE(AMF0_AMF3));
  WriteAMF3Value(AHelper, Self);
  p := AHelper.Position;
  AHelper.Position := l;
  l := p - l;
  AHelper.Cat(ExchangeByteOrder(l));
  AHelper.Position := p;
end;

{ TQAMFHeader }

constructor TQAMFHeader.Create;
begin
  inherited;
  Ext := TQAMFHeaderExt.Create;
end;

procedure TQAMFHeader.InternalEncode(AHelper: TQBytesCatHelper);
var
  AExt: TQAMFHeaderExt;
begin
  AExt := Ext as TQAMFHeaderExt;
  WriteAMF0String(AHelper, Name);
  if Assigned(AExt) then
    AHelper.Cat(AExt.Required)
  else
    AHelper.Cat(False);
  WriteAMF0Value(AHelper, Self);
end;

procedure RegisterAMFExternalClass(AClassName: QStringW;
  AHandler: TQAMFParseUnknownExternalCallback);
begin
  GlobalNameSpace.BeginWrite;
  try
    KnownExternalClasses.AddObject(AClassName,
      TQAMFExternalClassItem.Create(AHandler));
  finally
    GlobalNameSpace.EndWrite;
  end;
end;

function GetKnownAMFExternalClassHandler(AClassName: QStringW)
  : TQAMFParseUnknownExternalCallback;
var
  AIdx: Integer;
begin
  GlobalNameSpace.BeginRead;
  try
    if KnownExternalClasses.Find(AClassName, AIdx) then
      Result := (KnownExternalClasses.Objects[AIdx]
        as TQAMFExternalClassItem).FHandler
    else
      Result := nil;
  finally
    GlobalNameSpace.EndRead;
  end;
end;
{ TQAMFExternalClassItem }

constructor TQAMFExternalClassItem.Create
  (AHandler: TQAMFParseUnknownExternalCallback);
begin
  FHandler := AHandler;
end;

procedure FreeKnownExternalClasses;
var
  I: Integer;
begin
  GlobalNameSpace.BeginWrite;
  try
    for I := 0 to KnownExternalClasses.Count - 1 do
      FreeObject(KnownExternalClasses.Objects[I]);
    FreeAndNil(KnownExternalClasses);
  finally
    GlobalNameSpace.EndWrite;
  end;
end;

{ TQAMFNodeExt }

function TQAMFNodeExt.Copy: TQAMFNodeExt;
begin
  Result := TQAMFNodeExtClass(ClassType).Create(FExtClass);
end;

constructor TQAMFNodeExt.Create(AExtClass: QStringW);
begin
  inherited Create;
  FExtClass := AExtClass;
end;

{ TQAMFClassExt }

function TQAMFClassExt.Copy: TQAMFNodeExt;
var
  AResult: TQAMFClassExt;
begin
  Result := inherited Copy;;
  AResult := Result as TQAMFClassExt;
  AResult.FIsExternal := FIsExternal;
  AResult.FIsDynamic := FIsDynamic;
  AResult.FName := FName;
end;

constructor TQAMFClassExt.Create;
begin
  inherited Create('class');
end;

{ TQAMFHeaders }

constructor TQAMFHeaders.Create;
begin
  inherited;
  FChildClass := TQAMFHeader;
end;

{ TQAMFMessages }

constructor TQAMFMessages.Create;
begin
  inherited;
  FChildClass := TQAMFMessage;
end;

{ TQAMFVectorExt }

function TQAMFVectorExt.Copy: TQAMFNodeExt;
var
  AResult: TQAMFVectorExt;
begin
  Result := inherited Copy;
  AResult := Result as TQAMFVectorExt;
  AResult.FIsFixed := FIsFixed;
  AResult.FVectorType := FVectorType;
  AResult.FName := FName;
end;

constructor TQAMFVectorExt.Create;
begin
  inherited Create('vector');
end;

{ TQAMFDictionaryExt }

constructor TQAMFDictionaryExt.Create;
begin
  inherited Create('dictionary');
end;

{ TQAMFMessageExt }

constructor TQAMFMessageExt.Create;
begin
  inherited Create('message');
end;

function DecodeRTMPC3Block(p: PByte; ALen: Integer): TBytes;
var
  ps, pd: PByte;
  function HasC3: Boolean;
  begin
    Result := False;
    while IntPtr(p) - IntPtr(ps) < ALen do
    begin
      if p^ = $C3 then
      begin
        Inc(p, 129); // 下一个C3的距离应为128
        if IntPtr(p) - IntPtr(ps) < ALen then
        begin
          if p^ = $C3 then // 不在继续判断，认为是C3分段的数据
          begin
            Result := true;
            Break;
          end;
        end;
      end;
      Inc(p);
    end;
  end;

begin
  ps := p;
  if HasC3 then
  begin
    SetLength(Result, ALen);
    p := ps;
    pd := PByte(@Result[0]);
    while IntPtr(p) - IntPtr(ps) < ALen do
    begin
      if p^ <> $C3 then
      begin
        pd^ := p^;
        Inc(pd);
        Inc(p);
      end
      else
      begin
        while p^ = $C3 do
        begin
          Inc(p);
          if IntPtr(p) - IntPtr(ps) + 128 < ALen then
          begin
            if PByte(IntPtr(p) + 128)^ = $C3 then
            begin
              Move(p^, pd^, 128);
              Inc(p, 128);
              Inc(pd, 128);
            end
            else // 虽然可能是，但还是不是
            begin
              SetLength(Result, ALen);
              Move(ps^, Result[0], ALen);
              Exit;
            end
          end
          else
          begin
            Move(p^, pd^, ALen - (IntPtr(p) - IntPtr(ps)));
            SetLength(Result, IntPtr(pd) - IntPtr(@Result[0]));
            Exit;
          end;
        end;
      end;
    end;
  end
  else
  begin
    SetLength(Result, ALen);
    Move(p^, Result[0], ALen);
  end;
end;

initialization

AMFDateFormat := 'yyyy-mm-dd';
AMFDateTimeFormat := 'yyyy-mm-dd''T''hh:nn:ss.zzz';
AMFTimeFormat := 'hh:nn:ss.zzz';
KnownExternalClasses := TStringList.Create;
KnownExternalClasses.Sorted := true;
KnownExternalClasses.CaseSensitive := False;
KnownExternalClasses.Duplicates := dupAccept;

finalization

FreeKnownExternalClasses;

end.
