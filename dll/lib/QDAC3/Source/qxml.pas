unit qxml;

{$I 'qdac.inc'}

{
  本源码来自QDAC项目，版权归swish(QQ:109867294)所有。
  (1)、使用许可及限制
  您可以自由复制、分发、修改本源码，但您的修改应该反馈给作者，并允许作者在必要时，
  合并到本项目中以供使用，合并后的源码同样遵循QDAC版权声明限制。
  您的产品的关于中，应包含以下的版本声明:
  本产品使用的XML解析器来自QDAC项目中的QXML，版权归作者所有。
  (2)、技术支持
  有技术问题，您可以加入QDAC官方QQ群250530692共同探讨。
  (3)、赞助
  您可以自由使用本源码而不需要支付任何费用。如果您觉得本源码对您有帮助，您可以赞
  助本项目（非强制），以使作者不为生活所迫，有更多的精力为您呈现更好的作品：
  赞助方式：
  支付宝： guansonghuan@sina.com 姓名：管耸寰
  建设银行：
  户名：管耸寰
  账号：4367 4209 4324 0179 731
  开户行：建设银行长春团风储蓄所
}
// 测试环境仅为Delphi 2007或XE6，其它版本的开发环境，请自行修改
{ 修订日志
  2017.12.15
  ==========
  * 修正了 XMLEncode 的编码处理，对属性值的引号进行转义，对结点内容文本的引号不进行转义
  2017.1.4
  =========
  * 修正了 XML 编码时，未正确处理空 XML 文件的问题（麦子仲肥报告）
  2016.6.21
  =========
  * 修正了 AttachTo 没有判断父是否创建了FItems对象的问题（堕落恶魔报告）
  2016.3.8
  =========
  * 修正了根添加多个子结点时，由于保存时自动添加了<xml>造成解析回来时出错的问题（Redbreast报告）

  2015.5.25
  ==========
  * XML 的属性列表加入 Add 的几个重载以及XXXByName的支持（感谢不得闲）
  * XML 的属性加入 AsXXX 方式的赋值方法（感谢不得闲）
  2015.5.20
  ==========
  * 修改 Clear 函数，加入了是否清除结点的属性的选项，如果为False，则只清除子结点（感谢不得闲）

  2015.5.14
  ==========
  * 修改 QXML 在处理文本结点时的行为，不在文本结点前后追加空白（感谢阿木报告）
  2015.2.26
  ==========
  * 修正了在2007下的编译警告（感谢麦子仲肥）
  2015.1.26
  ==========
  + 增加无参数的Delete函数用于删除结点自身

  2014.12.13
  ==========
  + 增加HasChild函数，来判定指定路径的子结点是否存在（阿木建议）
  2014.12.9
  ==========
  * SaveToStream和SaveToFile新增一个AWriterHeader和AFormat参数来决定是否写入
  <?xml version="1.0" encoding="编码"?>行和是否格式化内容
  + TQSoapXML来增加对Soap格式的XML支持，要加载Soap格式的XML，直接使用TQXMLNode即可

  2014.10.31
  ==========
  * 修正了MoveTo移动到一个没有子结点的结点时出错的问题（新心晨曦报告）
  2014.10.30
  ==========
  + 新增Remove函数
  * 检查MoveTo到自己的子结点时的，抛出异常
  2014.10.29
  ==========
  + 新增Detach、AttachTo、MoveTo函数（新心晨曦建议）
  2014.8.28
  =========
  * 修正了LoadFromFile的AEncoding参数未生效的问题(五月光报告)
  2014.8.15
  =========
  * 优化了标签不匹配时错误提示，以便更容易定位错误信息
  2014.7.16
  =========
  * 修正了GetPath时，未初始化结果字符串造成Path属性可能出错的问题
  2014.7.12
  =========
  * 用户使用习惯兼容性的改变，结点设置其Text属性的值时，改为相当于清除所有的子结点，
  然后添加一个文本子结点
  2014.7.7
  ========
  * 修正了编码为XML里在特定情况下出错的问题(不得闲报告)
  2014.7.3
  =========
  * 修正了Assign时复制了当前结点名称的问题
  2014.6.26
  =========
  * 加入HPPEMIT默认链接本单元(麦子仲肥 建议)
  2014.6.22
  =========
  * 移除旧版的RTTI函数
  + 加入新版RTTI函数
  2014.5.14
  =========
  + 加入CopyIf/DeleteIf/FindIf函数
  + 加入for..in语法支持

  2014.5.6
  ========
  + 加入ParseBlock函数支持
  2014.5.1
  ========
  + 加入AddRecord函数，支持直接保存记录数据，但以下类型的成员会被忽略
  对象(Class)、函数(Method)、接口(Interface)、类型引用(ClassRef),指针(Pointer)、过程(Procedure)
  将来可能根据实际需要决定是否添加支持
  + 加入ToRecord函数，完成XML直接到记录类型的转换
  + 加入Copy函数用于创建当前结点的一个拷贝实例，注意目前版本克隆内部调用了Copy函数，将来可能改掉
  * 修正了Assign函数的一处错误
}
interface

uses classes, sysutils, types, qstring, typinfo, variants, qrbtree
{$IFDEF UNICODE}, Generics.Collections{$ENDIF}{$IF RTLVersion>=21},
  Rtti{$IFEND >=XE10}
{$IF RTLVersion<22}// 2007-2010
    , PerlRegEx, pcre
{$ELSE}
    , RegularExpressionsCore
{$IFEND}
    ;
{$HPPEMIT '#pragma link "qxml"'}
{$M+}

/// 本单元是QDAC的组成部分，受QDAC授权限制，详情访问QDAC网站了解
/// <summary>
/// XML解析单元，用于快速解析和维护XML结构.全局变量XMLDateFormat和XMLDateTimeFormat
/// 约定了日期时间类型转换为XML属性时的数据格式
/// QXML解析器不支持DTD定义，遇到相关的结点会忽略，保存的XML文件也不会包含DTD数据
/// </summary>
type
  TQXMLNode = class;
  PQXMLNode = ^TQXMLNode;
  TQXMLAttr = class;
  PQXMLAttr = ^TQXMLAttr;
  TQXML = TQXMLNode;
  PQXML = PQXMLNode;

  /// <summary>
  /// XML属性类定义，用于保存一项XML属性的值
  /// </summary>
  TQXMLAttr = class
  private
    FName, FValue: QStringW;
    FNameHash: Integer;
    function GetAsInteger: Integer;
    procedure SetAsInteger(const Value: Integer);
    function GetAsInt64: Int64;
    procedure SetAsInt64(const Value: Int64);
    function GetAsFloat: Extended;
    procedure SetAsFloat(const Value: Extended);
    function GetAsBoolean: Boolean;
    procedure SetAsBoolean(const Value: Boolean);
    function GetAsDateTime: TDateTime;
    procedure SetAsDateTime(const Value: TDateTime);
    procedure SetName(const Value: QStringW);
    function GetAsVariant: Variant;
    procedure SetAsVariant(const Value: Variant);
  public
    /// <summary>属性名称</summary>
    property Name: QStringW read FName write SetName;
    /// <summary>属性值</summary>
    property Value: QStringW read FValue write FValue;
    /// <summary>尝试按整形值来访问值内容</summary>
    property AsInteger: Integer read GetAsInteger write SetAsInteger;
    /// <summary>尝试以64位整数形式来访问值内容</summary>
    property AsInt64: Int64 read GetAsInt64 write SetAsInt64;
    /// <summary>尝试以浮点数的形式来访问值内容</summary>
    property AsFloat: Extended read GetAsFloat write SetAsFloat;
    /// <summary>尝试以字符串的形式来访问值内容（等价于访问Value)
    property AsString: QStringW read FValue write FValue;
    /// <summary>尝试以布尔的形式访问值内容
    property AsBoolean: Boolean read GetAsBoolean write SetAsBoolean;
    /// <summary>尝试以日期时间类型访问内容
    property AsDateTime: TDateTime read GetAsDateTime write SetAsDateTime;
    property AsVariant: Variant read GetAsVariant write SetAsVariant;
  end;
{$IF RTLVersion>=21}

  TQXMLAttrList = TList<TQXMLAttr>;
{$ELSE}
  TQXMLAttrList = TList;
{$IFEND >=2010}
  TQXMLAttrEnumerator = class;

  /// <summary>XML属性列表，内部使用</summary>
  TQXMLAttrs = class
  private
    FItems: TQXMLAttrList;
    FOwner: TQXMLNode;
    function GetCount: Integer;
    function GetItems(AIndex: Integer): TQXMLAttr;
    function GetAsBoolean(AName: QStringW): Boolean;
    function GetAsDateTime(AName: QStringW): TDateTime;
    function GetAsDouble(AName: QStringW): Double;
    function GetAsInt(AName: QStringW): Int64;
    function GetAsString(AName: QStringW): QStringW;
    procedure SetAsBoolean(AName: QStringW; const Value: Boolean);
    procedure SetAsDateTime(AName: QStringW; const Value: TDateTime);
    procedure SetAsDouble(AName: QStringW; const Value: Double);
    procedure SetAsInt(AName: QStringW; const Value: Int64);
    procedure SetAsString(AName: QStringW; const Value: QStringW);
    function GetAsGuid(AName: QStringW): TGuid;
    procedure SetAsGuid(AName: QStringW; const Value: TGuid);
  public
    /// <summary>创建一个XML属性列表</summary>
    /// <param name="AOwner">所隶属的XML结点</param>
    constructor Create(AOwner: TQXMLNode); overload;
    /// <summary>复制一个XML属性的内容</summary>
    procedure Assign(ASource: TQXMLAttrs);
    /// <summary>添加一个XML属性</summary>
    /// <param name="AName">要添加的XML属性名称</param>
    /// <returns>返回添加的XML属性对象
    function Add(const AName: QStringW): TQXMLAttr; overload;
    /// <summary>添加一个XML属性的值</summary>
    /// <param name="AName">属性名称</param>
    /// <param name="AValue">属性值</param>
    /// <returns>返回添加的XML属性的索引</returns>
    /// <remarks>QXML不检查是否重复，如果不确定是否已存在，在添加前，请用
    /// ItemByName或IndexByName来检查是否存在属性
    function Add(const AName, AValue: QStringW): Integer; overload;
    function Add(const AName: QStringW; AValue: Boolean): Integer; overload;
    function Add(const AName: QStringW; AValue: Int64): Integer; overload;
    function Add(const AName: QStringW; AValue: Double): Integer; overload;
    function Add(const AName: QStringW; AValue: TGuid): Integer; overload;
    function AddDateTime(const AName: QStringW; AValue: TDateTime)
      : Integer; overload;

    /// <summary>查找指定名称的属性</summary>
    /// <param name="AName">要查找的属性名称</param>
    /// <returns>返回找到的属性对象</returns>
    function ItemByName(const AName: QStringW): TQXMLAttr;
    /// <summary>获取指定名称的属性的索引号</summary>
    /// <param name="AName">要查找的属性名称</param>
    /// <returns>返回找到的属性的索引，如果未找到，返回-1</returns>
    function IndexOfName(const AName: QStringW): Integer;
    /// <summary>获取指定名称的属性的值</summary>
    /// <param name="AName">属性名称</param>
    /// <param name="ADefVal">如果属性不存在，返回的默认值</param>
    /// <returns>返回找到的属性的值，如果未找到，返回ADefVal参数的值</returns>
    function ValueByName(const AName: QStringW; const ADefVal: QStringW = '')
      : QStringW;
    function BoolByName(const AName: QStringW;
      const ADefVal: Boolean = False): Boolean;
    function IntByName(const AName: QStringW; const ADefVal: Int64 = 0): Int64;
    function FloatByName(const AName: QStringW;
      const ADefVal: Double = 0): Double;
    function GuidByName(const AName: QStringW; const ADefVal: TGuid): TGuid;
    function DateTimeByName(const AName: QStringW; const ADefVal: TDateTime = 0)
      : TDateTime;
    /// <summary>删除指定索引的属性值</summary>
    /// <param name="AIndex">属性索引</param>
    procedure Delete(AIndex: Integer); overload;
    /// <summary>删除指定名称的属性值</summary>
    /// <param name="AName">属性名称</param>
    /// <remarks>如果有重名的属性，只会删除第一个找到的属性</remarks>
    procedure Delete(AName: QStringW); overload;
    /// <summary>清除所有的属性</summary>
    procedure Clear;
    /// <summary>析构函数</summary>
    destructor Destroy; override;
    /// <summary>for..in支持函数</summary>
    function GetEnumerator: TQXMLAttrEnumerator;
    /// <summary>属性个数</summary>
    property Count: Integer read GetCount;
    /// <summary>属性列表</summary>
    property Items[AIndex: Integer]: TQXMLAttr read GetItems; default;
    /// <summary>属性所有者结点</summary>
    property Owner: TQXMLNode read FOwner;
    property AsString[AName: QStringW]: QStringW read GetAsString
      write SetAsString;
    property AsInt[AName: QStringW]: Int64 read GetAsInt write SetAsInt;
    property AsFloat[AName: QStringW]: Double read GetAsDouble
      write SetAsDouble;
    property AsDateTime[AName: QStringW]: TDateTime read GetAsDateTime
      write SetAsDateTime;
    property AsBoolean[AName: QStringW]: Boolean read GetAsBoolean
      write SetAsBoolean;
    property AsGuid[AName: QStringW]: TGuid read GetAsGuid write SetAsGuid;
  end;

  TQXMLAttrEnumerator = class
  private
    FIndex: Integer;
    FList: TQXMLAttrs;
  public
    constructor Create(AList: TQXMLAttrs);
    function GetCurrent: TQXMLAttr; inline;
    function MoveNext: Boolean;
    property Current: TQXMLAttr read GetCurrent;
  end;

  /// <summary>XML结点类型<summary>
  /// <list>
  /// <item><term>xntNode</term><description>普通结点</description></item>
  /// <item><term>xntText</term><description>文本内容</description></item>
  /// <item><term>xntComment</term><description>注释</description></item>
  /// <item><term>xntCData</term><description>CDATA</description></item>
  /// </list>
  TQXMLNodeType = (xntNode, xntText, xntComment, xntCData);
{$IF RTLVersion<21}
  TQXMLNodeList = TList;
{$ELSE}
  TQXMLNodeList = TList<TQXMLNode>;
{$IFEND}
{$IF RTLVersion>=21}
  TQXMLRttiFilterEventA = reference to procedure(ASender: TQXMLNode;
    AObject: Pointer; AName: QStringW; AType: PTypeInfo; var Accept: Boolean;
    ATag: Pointer);
  /// <summary>
  /// 结点过滤处理函数，以在XE6上支持匿名函数
  /// </summary>
  /// <param name="ASender">触发事件的TQXML对象</param>
  /// <param name="AItem">要过滤的对象</param>
  /// <param name="Accept">是否要处理该对象</param>
  /// <param name="ATag">用户附加的数据项</param>
  TQXMLFilterEventA = reference to procedure(ASender, AItem: TQXMLNode;
    var Accept: Boolean; ATag: Pointer);
{$IFEND >=2010}
  TQXMLRttiFilterEvent = procedure(ASender: TQXMLNode; AObject: Pointer;
    AName: QStringW; AType: PTypeInfo; var Accept: Boolean; ATag: Pointer)
    of object;

  TQXMLFilterEvent = procedure(ASender, AItem: TQXMLNode; var Accept: Boolean;
    ATag: Pointer) of object;

  /// <summary>
  /// AddObject/AddRecord时内部过滤时使用附加的Tag类型，仅用于内部使用
  /// </summary>
  TQXMLTagType = (ttAnonEvent, ttNameFilter);
  /// <summary>内部使用的标记数据定义</summary>
  PQXMLInternalTagData = ^TQXMLInternalTagData;

  /// <summary>内部使用的标记数据定义</summary>
  TQXMLInternalTagData = record
    /// <summary>Tag数据的类型</summary>
    TagType: TQXMLTagType;
{$IF RTLVersion>=21}
    /// <summary>过滤使用的匿名函数</summary>
    OnEvent: TQXMLRttiFilterEventA;
{$IFEND >=2010}
    /// <summary>接受的属性(AddObject)或记录字段(AddRecord)名称，如果名称同时在IgnoreNames出现，则IgnoreNames里的信息被忽略</summary>
    AcceptNames: QStringW;
    /// <summary>忽略的属性(AddObject)或记录字段(AddRecord)名称，如果名称同时在AcceptNameds里，则AcceptNames优先</summary>
    IgnoreNames: QStringW;
    /// <summary>原始传递给AddObject或AddRecord的附加数据成员，它将被传递给OnEvent的Tag，以供用户使用</summary>
    Tag: Pointer;
  end;

  TQXMLNodeEnumerator = class
  private
    FIndex: Integer;
    FList: TQXMLNode;
  public
    constructor Create(AList: TQXMLNode);
    function GetCurrent: TQXMLNode; inline;
    function MoveNext: Boolean;
    property Current: TQXMLNode read GetCurrent;
  end;

  /// <summary>用于外部支持对象池的函数，创建一个新的TQXMLNode对象，注意从池中创建的对象</summary>
  /// <returns>返回新创建的QXMLNode对象</returns>
  TQXMLCreateNode = function: TQXMLNode;
  /// <summary>用于外部将对象缓存，以便重用对象</summary>
  /// <param name="ANode">要释放的tQXMLNode对象</param>
  TQXMLFreeNode = procedure(ANode: TQXMLNode);

  /// <summary>
  /// TQXMLNode用于解析并维护XML格式数据，要使用前，需要先在堆中创建对应的实例。
  /// TQXML和TQXML在绝大多数接口上保持一致，但由于XML是有类型信息，而XML没有类型
  /// 信息（始终认为是字符串），因此少部分接口会略有不同.
  /// 与其它实现不同，QXML没有所谓的文档对象，也没有所谓一个根结点下只能有一个结点
  /// 的限制，但如果根结点下有多个子结点，在保存到文件或流中时，如果根结点没有命名
  /// 则会自动加入一个<xml></xml>根结点以保证生成的文件符合XML标准要求。
  /// 您可以认为根结点就是文档对象，任意一级结点都可以直接从文件或流中加载内容，
  /// 或者保存到文件或流中。
  /// </summary>
  TQXMLNode = class
  private
    FAttrs: TQXMLAttrs;
    FItems: TQXMLNodeList;
    FNodeType: TQXMLNodeType;
    FParent: TQXMLNode;
    FName: QStringW;
    FNameHash: Integer; // 名称的哈希值
    FData: Pointer;
    function GetCount: Integer;
    function GetItems(AIndex: Integer): TQXMLNode;
    function XMLEncode(const S: QStringW; AConvertQuoter: Boolean;
      AppendSpace: Boolean): QStringW;
    function XMLDecode(const p: PQCharW; l: Integer): QStringW; overload;
    function GetItemIndex: Integer;
    function GetText: QStringW;
    procedure SetText(const Value: QStringW);
    procedure SetName(const Value: QStringW);
    function GetAttrs: TQXMLAttrs;
    function GetPath: QStringW;
    function GetCapacity: Integer;
    procedure SetCapacity(const Value: Integer);
    function InternalEncode(ABuilder: TQStringCatHelperW; ADoFormat: Boolean;
      const AIndent: QStringW): TQStringCatHelperW;
    function GetName: QStringW;
    // procedure InternalRttiFilter(ASender: TQXMLNode; AObject: Pointer;
    // APropName: QStringW; APropType: PTypeInfo; var Accept: Boolean;
    // ATag: Pointer);
    // function InternalAddObject(AName: QStringW; AObject: TObject;
    // AOnFilter: TQXMLRttiFilterEvent; ANest: Boolean; ATag: Pointer)
    // : TQXMLNode;
    function GetAsXML: QStringW;
    procedure SetAsXML(const Value: QStringW);
    procedure DoParse(p: PQCharW);
    procedure SetNodeType(const Value: TQXMLNodeType);
    function CreateNode: TQXMLNode; virtual;
    procedure DoNodeNameChanged(ANode: TQXMLNode); virtual;
    procedure FreeNode(ANode: TQXMLNode); inline;
  public
    /// <summary>构造函数</summary>
    constructor Create; overload;
    /// <summary>析构函数</summary>
    destructor Destroy; override;
    /// <summary>值拷贝函数</summary>
    procedure Assign(ANode: TQXMLNode);
    /// <summary>添加一个未命名结点</summary>
    /// <remarks>如果您添加了一个未命名结点，保存时，该结点层级将被忽略而直接保存子一级</remarks>
    function Add: TQXMLNode; overload;
    /// <summary>添加一个结点、文本、注释或CData</summary>
    /// <param name="AName_Text">名称或内容，具体取决于AType参数</param>
    /// <returns>返回添加的结点实例</returns>
    function Add(const AName_Text: QStringW; AType: TQXMLNodeType = xntNode)
      : TQXMLNode; overload;
    /// <summary>添加一个结点</summary>
    /// <param name="AName">结点名称</param>
    /// <returns>返回添加的结点实例</returns>
    /// <remarks>等价于调用Add(AName,xntNode)</remarks>
    function AddNode(const AName: QStringW): TQXMLNode; virtual;
    /// <summary>添加一个文本结点</summary>
    /// <param name="AText">要添加的文本内容</param>
    /// <returns>返回添加的结点实例</returns>
    /// <remarks>等价于调用Add(AText,xntText)</remarks>
    function AddText(const AText: QStringW): TQXMLNode;
    /// <summary>添加一个注释</summary>
    /// <param name="AText">要添加的注释内容，不能包含--&gt;</param>
    /// <returns>返回添加的结点实例</returns>
    /// <remarks>等价于调用Add(AText,xntComment)</remarks>
    function AddComment(const AText: QStringW): TQXMLNode;
    /// <summary>添加一个注释</summary>
    /// <param name="AText">要添加的CData，不能包含]]&gt;</param>
    /// <returns>返回添加的结点实例</returns>
    /// <remarks>等价于调用Add(AText,xntCData)</remarks>
    function AddCData(const AText: QStringW): TQXMLNode;
    /// <summary>获取指定名称的第一个结点</summary>
    /// <param name="AName">结点名称</param>
    /// <returns>返回找到的结点，如果未找到，返回空(NULL/nil)</returns>
    /// <remarks>注意XML允许重名，因此，如果存在重名的结点，只会返回第一个结点</remarks>
    function ItemByName(const AName: QStringW): TQXMLNode; overload;
    /// <summary>获取指定名称的结点到列表中</summary>
    /// <param name="AName">结点名称</param>
    /// <param name="AList">用于保存结点的列表对象</param>
    /// <param name="ANest">是否递归查找子结点</param>
    /// <returns>返回找到的结点数量，如果未找到，返回0</returns>
    function ItemByName(const AName: QStringW; AList: TQXMLNodeList;
      ANest: Boolean = False): Integer; overload;
    /// <summary>获取指定路径的XML对象</summary>
    /// <param name="APath">路径，以"."或"/"或"\"分隔</param>
    /// <returns>返回找到的子结点，如果未找到返回NULL(nil)</returns>
    function ItemByPath(const APath: QStringW): TQXMLNode;
    /// <summary>获取符合指定名称规则的结点到列表中</summary>
    /// <param name="ARegex">正则表达式</param>
    /// <param name="AList">用于保存结点的列表对象</param>
    /// <param name="ANest">是否递归查找子结点</param>
    /// <returns>返回找到的结点数量，如果未找到，返回0</returns>
    function ItemByRegex(const ARegex: QStringW; AList: TQXMLNodeList;
      ANest: Boolean = False): Integer; overload;
    /// <summary>获取指定路径结点的文本内容</summary>
    /// <param name="APath">路径，以"."或"/"或"\"分隔</param>
    /// <param name="ADefVal">若路径不存在，返回的默认值</param>
    /// <returns>如果找到结点，返回找到的结点的文本内容，否则返回ADefVal参数的值</returns>
    function TextByPath(const APath, ADefVal: QStringW): QStringW;
    /// <summary>获取指定路径下的子结点中属性匹配指定值的结点</summary>
    /// <param name="APath">路径，以"."或"/"或"\"分隔</param>
    /// <param name="AttrName">要检查的属性名称</param>
    /// <param name="AttrValue">要检查的属性值</param>
    /// <returns>如果找到结点，返回找到的结点，否则返回空(nil/NULL)</returns>
    function ItemWithAttrValue(const APath: QStringW;
      const AttrName, AttrValue: QStringW): TQXMLNode;
    /// <summary>判断自己是否是指定对象的子对象</summmary>
    /// <param name="AParent">可能的父对象</param>
    /// <returns>如果AParent是自己的父对象，返回True，否则返回false</returns>
    function IsChildOf(AParent: TQXMLNode): Boolean;
    /// <summary>判断自己是否是指定对象的父对象</summmary>
    /// <param name="AChild">可能的子对象</param>
    /// <returns>如果AChild是自己的子对象，返回True，否则返回false</returns>
    function IsParentOf(AChild: TQXMLNode): Boolean;
    /// <summary>获取指定路径结点的指定属性</summary>
    /// <param name="APath">路径，以"."或"/"或"\"分隔</param>
    /// <param name="AttrName">属性名称</param>
    /// <returns>如果找到结点相应的属性，返回找到的属性，否则返回NULL/nil</returns>
    /// <remarks>
    function AttrByPath(const APath, AttrName: QStringW): TQXMLAttr;
    /// <summary>获取指定路径结点的指定属性值</summary>
    /// <param name="APath">路径，以"."或"/"或"\"分隔</param>
    /// <param name="AttrName">属性名称</param>
    /// <param name="ADefVal">若路径不存在，返回的默认值</param>
    /// <returns>如果找到结点相应的属性，返回找到的属性的文本内容，否则返回ADefVal参数的值</returns>
    /// <remarks>
    function AttrValueByPath(const APath, AttrName, ADefVal: QStringW)
      : QStringW;

    /// <summary>强制一个路径存在,如果不存在,则依次创建需要的结点</summary>
    /// <param name="APath">要添加的结点路径</param>
    /// <returns>返回路径对应的对象</returns>
    function ForcePath(APath: QStringW): TQXMLNode;
    /// <summary>编码为字符串</summary>
    /// <param name="ADoFormat">是否格式化字符串，以增加可读性</param>
    /// <param name="AIndent">ADoFormat参数为True时，缩进内容，默认为两个空格</param>
    /// <returns>返回编码后的字符串</returns>
    /// <remarks>AsXML等价于Encode(True,'  ')</remarks>
    function Encode(ADoFormat: Boolean; AIndent: QStringW = '  '): QStringW;
    /// <summary>拷贝生成一个新的实例</summary>
    /// <returns>返回新的拷贝实例</returns>
    /// <remarks>因为是拷贝，所以新旧对象之间的内容变更没有任何关系，更改任意一个
    /// 对象，不会对另外一个对象造成影响。
    /// </remarks>
    function Copy: TQXMLNode;
{$IF RTLVersion>=21}
    function CopyIf(const ATag: Pointer; AFilter: TQXMLFilterEventA)
      : TQXMLNode; overload;
{$IFEND >=2010}
    function CopyIf(const ATag: Pointer; AFilter: TQXMLFilterEvent)
      : TQXMLNode; overload;
    /// <summary>克隆生成一个新的实例</summary>
    /// <returns>返回新的拷贝实例</returns>
    /// <remarks>因为实际上执行的是拷贝，所以新旧对象之间的内容变更没有任何关系，
    /// 更改任意一个对象，不会对另外一个对象造成影响，但此行为将来并不保证，可能
    /// 会调整为引用，以便相互影响。
    /// </remarks>
    function Clone: TQXMLNode;
    /// <summary>删除指定索引的结点</summary>
    /// <param name="AIndex">要删除的结点索引</param>
    /// <remarks>
    /// 如果指定索引的结点不存在，则抛出EOutRange异常
    /// </remarks>
    procedure Delete(AIndex: Integer); overload; virtual;
    /// <summary>从父结点中删除自身，如果没有父结点，则释放自己</summary>
    procedure Delete; overload;
    /// <summary>移除指定索引的结点</summary>
    /// <param name="AIndex">要移除的结点索引</param>
    /// <returns>返回被移除的结点</returns>
    /// <remarks>
    /// 1、如果指定索引的结点不存在，则抛出EOutRange异常
    /// 2、被移除的结点需要用户自行释放
    /// </remarks>
    function Remove(AIndex: Integer): TQXMLNode; overload; virtual;
    /// <summary>移除指定的子结点</summary>
    /// <param name="AIndex">要移除的结点</param>
    procedure Remove(ANode: TQXMLNode); overload;
{$IF RTLVersion>=21}
    /// <summary>
    /// 删除符合条件的子结点
    /// </summary>
    /// <param name="ATag">用户自己附加的额外标记</param>
    /// <param name="ANest">是否嵌套调用，如果为false，则只对当前子结点过滤</param>
    /// <param name="AFilter">过滤回调函数，如果为nil，等价于Clear</param>
    procedure DeleteIf(const ATag: Pointer; ANest: Boolean;
      AFilter: TQXMLFilterEventA); overload;
{$IFEND >=2010}
    /// <summary>
    /// 删除符合条件的子结点
    /// </summary>
    /// <param name="ATag">用户自己附加的额外标记</param>
    /// <param name="ANest">是否嵌套调用，如果为false，则只对当前子结点过滤</param>
    /// <param name="AFilter">过滤回调函数，如果为nil，等价于Clear</param>
    procedure DeleteIf(const ATag: Pointer; ANest: Boolean;
      AFilter: TQXMLFilterEvent); overload;

    /// <summary>删除指定名称的结点</summary>
    /// <param name="AName">要删除的结点名称</param>
    /// <param name="ADeleteAll">是否删除全部同名的结点</param>
    procedure Delete(AName: QStringW; ADeleteAll: Boolean = True); overload;
    /// <summary>查找指定名称的结点的索引</summary>
    /// <param name="AName">要查找的结点名称</param>
    /// <returns>返回索引值，未找到返回-1</returns>
    function IndexOf(const AName: QStringW): Integer; virtual;
{$IF RTLVersion>=21}
    /// <summary>遍历结点查找符合条件的结点</summary>
    /// <param name="ATag">用户自定义的附加额外标记</param>
    /// <param name="ANest">是否嵌套调用，如果为false，则只对当前子结点过滤</param>
    /// <param name="AFilter">过滤回调函数，如果为nil，则返回nil</param>
    function FindIf(const ATag: Pointer; ANest: Boolean;
      AFilter: TQXMLFilterEventA): TQXMLNode; overload;
{$IFEND >=2010}
    /// <summary>遍历结点查找符合条件的结点</summary>
    /// <param name="ATag">用户自定义的附加额外标记</param>
    /// <param name="ANest">是否嵌套调用，如果为false，则只对当前子结点过滤</param>
    /// <param name="AFilter">过滤回调函数，如果为nil，则返回nil</param>
    function FindIf(const ATag: Pointer; ANest: Boolean;
      AFilter: TQXMLFilterEvent): TQXMLNode; overload;

    /// <summary>清除所有的结点</summary>
    procedure Clear(AIncAttrs: Boolean = True); virtual;
    /// <summary>解析指定的XML字符串</summary>
    /// <param name="p">要解析的字符串</param>
    /// <param name="l">字符串长度，<=0认为是以\0(#0)结尾的C语言标准字符串</param>
    /// <remarks>如果l>=0，会检测p[l]是否为\0，如果不为\0，则会创建拷贝实例并解析拷贝实例</remarks>
    procedure Parse(p: PQCharW; len: Integer = -1); overload;
    /// <summary>解析指定的XML字符串</summary>
    /// <param name='s'>要解析的XML字符串</param>
    procedure Parse(const S: QStringW); overload;
    /// <summmary>从流中解析首个XML结点</summary>
    /// <param name="AStream">流对象</param>
    /// <param name="AEncoding">流数据的编码方式</param>
    /// <remarks>ParseBlock适合解析分段式XML，它会从当前位置开始，解析到当前对象结束为止.
    /// 可以很好的满足渐进式传输的需要</remarks>
    procedure ParseBlock(AStream: TStream; AEncoding: TTextEncoding);
    /// <summary>从指定的文件中加载当前对象</summary>
    /// <param name="AFileName">要加载的文件名</param>
    /// <param name="AEncoding">源文件编码，如果为teUnknown，则自动判断</param>
    procedure LoadFromFile(AFileName: QStringW;
      AEncoding: TTextEncoding = teUnknown);
    /// <summary>从流的当前位置开始加载XML对象</summary>
    /// <param name="AStream">源数据流</param>
    /// <param name="AEncoding">源文件编码，如果为teUnknown，则自动判断</param>
    /// <remarks>流的当前位置到结束的长度必需大于2字节，否则无意义</remarks>
    procedure LoadFromStream(AStream: TStream;
      AEncoding: TTextEncoding = teUnknown);
    /// <summary>保存当前对象内容到文件中</summary>
    /// <param name="AFileName">文件名</param>
    /// <param name="AEncoding">编码格式</param>
    /// <param name="AWriteBOM">是否写入UTF-8的BOM</param>
    /// <param name="AWriteHeader">是否写入xml标准头部</param>
    /// <param name="AFormat">是否格式化内容</param>
    /// <remarks>注意当前结点的名称不会被写入</remarks>
    procedure SaveToFile(AFileName: QStringW; AEncoding: TTextEncoding = teUTF8;
      AWriteBom: Boolean = False; AWriteHeader: Boolean = True;
      AFormat: Boolean = True); overload;
    /// <summary>保存当前对象内容到流中</summary>
    /// <param name="AFileName">文件名</param>
    /// <param name="AEncoding">编码格式，如果传入的是UTF-8则使用 UTF-8 编码，如果是 UTF-16 则使用 Unicode LE 编码，其它则使用 Ansi编码</param>
    /// <param name="AWriteBom">是否写入BOM</param>
    /// <param name="AWriteHeader">是否写入xml标准头部</param>
    /// <param name="AFormat">是否格式化内容</param>
    /// <remarks>注意当前结点的名称不会被写入</remarks>
    procedure SaveToFile(AFileName: QStringW; AEncoding: String;
      AWriteBom: Boolean = False; AWriteHeader: Boolean = True;
      AFormat: Boolean = True); overload;
    /// <summary>保存当前对象内容到流中</summary>
    /// <param name="AStream">目标流对象</param>
    /// <param name="AEncoding">编码格式</param>
    /// <param name="AWriteBom">是否写入BOM</param>
    /// <param name="AWriteHeader">是否写入xml标准头部</param>
    /// <param name="AFormat">是否格式化内容</param>
    /// <remarks>注意当前结点的名称不会被写入</remarks>
    procedure SaveToStream(AStream: TStream; AEncoding: TTextEncoding = teUTF8;
      AWriteBom: Boolean = False; AWriteHeader: Boolean = True;
      AFormat: Boolean = True); overload;
    /// <summary>保存当前对象内容到流中</summary>
    /// <param name="AStream">目标流对象</param>
    /// <param name="AEncoding">编码格式，如果传入的是UTF-8则使用 UTF-8 编码，如果是 UTF-16 则使用 Unicode LE 编码，其它则使用 Ansi编码</param>
    /// <param name="AWriteBom">是否写入BOM</param>
    /// <param name="AWriteHeader">是否写入xml标准头部</param>
    /// <param name="AFormat">是否格式化内容</param>
    /// <remarks>注意当前结点的名称不会被写入</remarks>
    procedure SaveToStream(AStream: TStream; AEncoding: String;
      AWriteBom: Boolean = False; AWriteHeader: Boolean = True;
      AFormat: Boolean = True); overload;
{$IF RTLVersion>=21}
    /// <summary>使用当前XML对象参数调用指定对象的相应函数</summary>
    /// <param name="AInstance">函数所隶属的对象实例</param>
    /// <returns>返回函数调用的结果</returns>
    /// <remarks>函数名称为当前结点名称，函数的参数名称与子结点的名称要保持一致</remarks>
    /// function Invoke(AInstance: TValue): TValue;
    /// <summary>将当前的值转换为TValue类型的值</summary>
    /// <returns>返回当前结点转换后的TValue值</returns>
    function ToRttiValue: TValue;
    /// <summary>从指定的RTTI实例中生成JSON数据</summary>
    /// <param name="AInstance">对象或其它RTTI类型值</param>
    /// <remarks>注意不是全部RTTI类型都受支持，如接口啥的</remarks>
    procedure FromRtti(AInstance: TValue); overload;
    /// <summary>将指定的来源地址按指定的类型生成JSON数据</summary>
    /// <param name="ASource">对象或结构体地址</param>
    /// <param name="AType">对象或结构体类型信息</param>
    procedure FromRtti(ASource: Pointer; AType: PTypeInfo); overload;
    /// <summary>从指定的记录实例中生成JSON数据</summary>
    /// <param name="ARecord">记录实例</param>
    procedure FromRecord<T>(const ARecord: T);
    /// <summary>从当前JSON中还原到指定的对象实例中</summary>
    /// <param name="AInstance">实例地址</param>
    /// <param name="AClearCollections">是否在恢复TCollection对象的元素时先清理已有的元素,默认为trur</param>
    /// <remarks>实际上参数只支持对象，记录由于目前无法直接转换为TValue，所以没
    /// 意义，而其它类型因为是值拷贝，实际就算赋值了也返回不了，因此无意义</remarks>
    procedure ToRtti(AInstance: TValue;
      AClearCollections: Boolean = True); overload;
    /// <summary>从当前JSON中按指定的类型信息还原到指定的地址</summary>
    /// <param name="ADest">目的地址</param>
    /// <param name="AType">对象或结构体的类型信息</param>
    /// <param name="AClearCollections">是否在恢复TCollection对象的元素时先清理已有的元素,默认为trur</param>
    /// <remarks>ADest对应的应是记录或对象，其它类型不受支持</remarks>
    procedure ToRtti(ADest: Pointer; AType: PTypeInfo;
      AClearCollections: Boolean = True); overload;
    /// <summary>从当前的JSON中还原到指定的记录实例中</summary>
    /// <param name="ARecord">目的记录实例</param>
    /// <param name="AClearCollections">是否在恢复TCollection对象的元素时先清理已有的元素,默认为trur</param>
    procedure ToRecord<T: record >(var ARecord: T;
      AClearCollections: Boolean = True);
{$IFEND}
    /// <summary>从当前XML父结点中分离当前结点</summary>
    /// <remarks>分离后的结点需要单独释放</remarks>
    procedure Detach;
    /// <summary>将当前结点附加到新的父结点上</summary>
    /// <param name="AParent">要附加的目标结点</param>
    /// <remarks>附加后的结点由父结点负责释放</remarks>
    procedure AttachTo(AParent: TQXMLNode);
    /// <summary>将当前结点移动的新的父结点的指定位置</summary>
    /// <param name="ANewParent">新的父结点</param>
    /// <param name="AIndex">新位置索引</param>
    /// <remarks>如果新位置索引小于等于0，则插入到起始位置，如果大于父的已有结点数量，则插入到
    /// 父结点末尾，否则添加到指定位置</remarks>
    procedure MoveTo(ANewParent: TQXMLNode; AIndex: Integer);
    /// <summary>重载TObject.ToString函数</summary>
    function ToString: string; {$IFDEF UNICODE}override; {$ENDIF}
    /// <summary>for..in支持函数</summary>
    function GetEnumerator: TQXMLNodeEnumerator;
    /// <summary>判定是否有符合指定路径要求的子结点，如果存在，通过参数AChild保存实例地址并返回True，否则返回False</summary>
    /// <param name="ANamePath">结点路径，分隔符接受“.”，“/”，“\”三种</param>
    /// <param name="AChild">用于返回子结点指针</param>
    /// <returns>成功，返回True，AChild赋值为子结点指针，失败，返回False</returns>
    function HasChild(ANamePath: QStringW; var AChild: TQXMLNode)
      : Boolean; inline;
    /// <summary>获取到指定父结点的相对路径</summary>
    /// <param name="AParent">目标父结点</param>
    /// <param name="APathDelimiter">路径分隔符</param>
    /// <returns>返回相对路径</returns>
    function GetRelPath(AParent: TQXMLNode; APathDelimiter: QCharW = '\')
      : QStringW;
    function XMLDecode(const S: QStringW): QStringW; overload;
    procedure Reset(ADetach: Boolean);
    /// <summary>子结点数量</<summary>summary>
    property Count: Integer read GetCount;
    /// <summary>子结点数组</summary>
    property Items[AIndex: Integer]: TQXMLNode read GetItems; default;
    /// <summary>额外的附加数据成员，供用户关联附加内容</summary>
    property Data: Pointer read FData write FData;
    /// <summary>结点的路径，中间以"\"分隔</summary>
    property Path: QStringW read GetPath;
    /// <summary>结点在父结点上的索引，如果自己是根结点，则返回-1</summary>
    property ItemIndex: Integer read GetItemIndex;
    /// <summary>父结点</summary>
    property Parent: TQXMLNode read FParent write FParent;
  published
    /// <summary>结点名称</summary>
    property Name: QStringW read GetName write SetName;
    /// <summary>结点的纯文本内容（不含注释，只包含Text和CDATA)</summary>
    property Text: QStringW read GetText write SetText;
    /// <summary>结点类型</summary>
    property NodeType: TQXMLNodeType read FNodeType write SetNodeType;
    /// <summary>属性列表</summary>
    property Attrs: TQXMLAttrs read GetAttrs;
    /// <summary>列表容量</summary>
    property Capacity: Integer read GetCapacity write SetCapacity;
    /// <summary>返回XML格式的数据</summary>
    property AsXML: QStringW read GetAsXML write SetAsXML;
  end;

  TQHashedXMLNode = class(TQXMLNode)
  protected
    FHashTable: TQHashTable;
    function CreateNode: TQXMLNode; override;
    procedure DoNodeNameChanged(ANode: TQXMLNode); override;
  public
    constructor Create; overload;
    destructor Destroy; override;
    function IndexOf(const AName: QStringW): Integer; override;
    function Remove(AIndex: Integer): TQXMLNode; override;
    procedure Clear(AIncAttrs: Boolean = True); override;
  end;

  // Soap格式的XML封装
  TQSoapXML = class
  protected
    FRoot: TQXMLNode;
    FHeader: TQXMLNode;
    FBody: TQXMLNode;
  public
    /// <summary>构造函数</summary>
    constructor Create; overload;
    /// <summary>析构函数</summary>
    destructor Destroy; override;
    /// <summary>添加一个Soap头部定义</summary>
    /// <param name="AName">要添加的头结点名称</param>
    /// <returns>返回新添加的Soap头子结点</returns>
    function Header(const AName: QStringW): TQXMLNode; overload;
    /// <summary>添加一个带有命名空间的头结点</param>
    /// <param name="ANodeName">要添加的头结点名称</param>
    /// <param name="ANameSpace">命名空间的URI地址</param>
    /// <returns>返回新添加的Soap头子结点</returns>
    /// <remarks>请自己保证URI地址的有效性，QSoapXML不检查内容</remarks>
    function Header(const ANodeName, ANSUri: QStringW): TQXMLNode; overload;
    /// <summary>获取Soap头部的根定义</summary>
    /// <returns>返回Soap头部的根定义</returns>
    function Header: TQXMLNode; overload;
    /// <summary>获取Soap正文部分的根定义</summary>
    /// <returns>返回Soap正文部分的根定义</returns>
    function Body: TQXMLNode; overload;
    /// <summary>添加一个指定名称的正文结点</summary>
    /// <param name="AName">要添加的结点名称</param>
    /// <returns>返回新添加的Soap正文子结点</returns>
    function Body(const AName: QStringW): TQXMLNode; overload;
    /// <summary>保存到流中</summary>
    /// <param name="AStream">要保存的目标数据流</param>
    procedure SaveToStream(AStream: TStream);
    /// <summary>保存到文件中</summary>
    /// <param name="AFileName">目标文件名</param>
    procedure SaveToFile(const AFileName: QStringW);
    /// <summary>根结点</summary>
    property Root: TQXMLNode read FRoot;
  end;

var
  /// 日期时间类型转换为XML数据时会转换成字符串，这两个变量控制如何格式化
  XMLDateFormat, XMLDateTimeFormat, XMLTimeFormat: QStringW;
  /// 在ItemByName/ItemByPath/ValueByName/ValueByPath等函数的判断中，是否区分名称大小写
  XMLCaseSensitive: Boolean;
  /// 强制编码时XML节点名称必需配对出现,如果为True，则如果对应的结点没有子结点时，会
  /// 直接以/>结尾，如果为False，则会强制配对出现
  XMLTagShortClose: Boolean;
  /// 在需要新建一个TQXMLNode对象时触发
  OnQXMLNodeCreate: TQXMLCreateNode;
  /// 在需要释放一个TQXMLNode对象时触发
  OnQXMLNodeFree: TQXMLFreeNode;

  XMLRttiEnumAsInt: Boolean;

  XMLPathDelimiter: QCharW = '\';

implementation

uses math;

resourcestring
  SNodeWithoutName = '指定的结点名称未指定，无法生成XML数据。';
  SBadXMLName = '无效的XML结点名称，名称不能以数字或xml打头，也不能包含空白或控制符。';
  SBadXMLComment = '无效的XML注释！注释中不能包含“--”。';
  SUnterminateXMLComment = '未结束的XML注释！';
  SBadXMLCData = '无效的CData内容！CData内容中不能出现“]]>”。';
  SUnterminateXMLCData = '未结束的CDATA标记！';
  SBadXMLEncoding = '无效的XML内容编码，Ansi编码请使用另一重载。';
  SXMLBadAttrValue = '无效的XML属性值，属性值必需使用引号包裹。';
  SXMLAttrValueMissed = '未找到XML属性值定义。';
  SUnterminatedXMLTag = '未结束的XML标签定义。';
  SUnclosedXMLTag = '未关闭的XML标签定义%s。';
  SUnexpectXMLTagClose = '错误的XML结束标签: </%s> ,期望 </%s>';
  SBadXMLEscape = '无效的XML转义序列定义。';
  SNotSupport = '不支持的函数[%s]';
  SUnknownXMLEscape = '未知的XML转义字符串[%s]。';
  SXMLNameNotSupport = '当前结点类型不支持名称。';
  SValueNotNumeric = '字符串 %s 不是有效的数值。';
  SValueNotInteger = '字符串 %s 不是有效的整数值。';
  SValueNotBoolean = '字符串 %s 不是有效的布尔值。';
  SValueNotDateTime = '字符串 %s 不是有效的日期时间值。';
  SValueNotGuid = '字符串 %s 不是有效的 GUID 值。';
  SBadXMLTagStart = 'XML文档需要以<开始一个结点名称。';
  SXMLNameNeeded = 'XML结点在编码前必需指定一个名称。';
  SSupportFloat = 'NaN/+∞/-∞不受XML规范支持。';
  SParamMissed = '参数 %s 同名的结点未找到。';
  SMethodMissed = '指定的函数 %s 不存在。';
  SMissRttiTypeDefine =
    '无法找到 %s 的RTTI类型信息，尝试将对应的类型单独定义(如array[0..1] of Byte改为TByteArr=array[0..1]，然后用TByteArr声明)。';
  SUnsupportPropertyType = '不支持的属性类型';
  SParentMustNode = '添加子结点时，上级结点类型必需是xntNode';
  SCantMoveToChild = '不能将自己移动到自己的子结点下面';

  { TQXMLAttrs }
  {
    名称中的位置	 允许的字符
    任何位置
    ["A"-"Z"]、["a"-"z"]、"_"、[0x00C0-0x02FF]、[0x0370-0x037D]、[0x037F-0x1FFF]、[0x200C-0x200D]、
    [0x2070-0x218F]、[0x2C00-0x2FEF]、[0x3001-0xD7FF]、[0xF900-0xEFFF]
    除第一个位置之外的任何位置
    "-"、"."、["0"-"9"]、0x00B7、[0x0300-0x036F]、[0x203F-0x2040]
    元素或属性名称（架构树视图中的节点名称）以英文表示的最佳实践可概括为以下几点：
    使用字母数字字符，但名称不要以数字开头。

    使用下划线 (_)、连字符 (-)、句点 (.) 和中间点 (·)。

    不要使用空格。

    使用以自然语言表示的有意义单词或单词的组合。
  }
function ValidXMLName(const S: QStringW): Boolean;
var
  p: PQCharW;
  function InRange(const c, cmin, cmax: QCharW): Boolean; inline;
  begin
    Result := (c >= cmin) and (c <= cmax);
  end;

begin
  p := PQCharW(S);
  if InRange(p^, 'A', 'Z') or InRange(p^, 'a', 'z') or (p^ = '_') or
    InRange(p^, #$00C0, #$02FF) or InRange(p^, #$0370, #$037D) or
    InRange(p^, #$037F, #$1FFF) or InRange(p^, #$200C, #$200D) or
    InRange(p^, #$2070, #$218F) or InRange(p^, #$2C00, #$2FEF) or
    InRange(p^, #$3001, #$D7FF) or InRange(p^, #$F900, #$EFFF) then
  begin
    Inc(p);
    while p^ <> #0 do
    begin
      if InRange(p^, 'A', 'Z') or InRange(p^, 'a', 'z') or InRange(p^, '0', '9')
        or (p^ = '_') or (p^ = '-') or (p^ = '.') or (p^ = ':') or (p^ = #$00B7)
        or InRange(p^, #$00C0, #$02FF) or InRange(p^, #$0300, #$037D) or
        InRange(p^, #$037F, #$1FFF) or InRange(p^, #$200C, #$200D) or
        InRange(p^, #$203F, #$2040) or InRange(p^, #$2070, #$218F) or
        InRange(p^, #$2C00, #$2FEF) or InRange(p^, #$3001, #$D7FF) or
        InRange(p^, #$F900, #$EFFF) then
        Inc(p)
      else
        Break;
    end;
    Result := (p^ = #0);
  end
  else
    Result := False;
end;

function ValidXMLComment(const Value: QStringW): Boolean;
var
  ps: PQCharW;
begin
  ps := PQCharW(Value);
  Result := True;
  while ps^ <> #0 do
  begin
    if (ps[0] = '-') and (ps[1] = '-') then
    begin
      Result := False;
      Break;
    end
    else
      Inc(ps);
  end;
end;

function ValidXMLCData(const Value: QStringW): Boolean;
var
  ps: PQCharW;
begin
  ps := PQCharW(Value);
  Result := True;
  while ps^ <> #0 do
  begin
    // CDATA里不能出现]]>串
    if (ps[0] = ']') and (ps[1] = ']') and (ps[2] = '>') then
    begin
      Result := False;
      Break;
    end
    else
      Inc(ps);
  end;
end;

function TQXMLAttrs.Add(const AName, AValue: QStringW): Integer;
var
  Attr: TQXMLAttr;
begin
  if ValidXMLName(AName) then
  begin
    Attr := TQXMLAttr.Create;
    Attr.FName := AName;
    Attr.FValue := AValue;
    Result := FItems.Add(Attr);

  end
  else
    raise Exception.Create(SBadXMLName);
end;

function TQXMLAttrs.Add(const AName: QStringW): TQXMLAttr;
begin
  if ValidXMLName(AName) then
  begin
    Result := TQXMLAttr.Create;
    Result.FName := AName;
    FItems.Add(Result);
  end
  else
    raise Exception.Create(SBadXMLName);
end;

function TQXMLAttrs.Add(const AName: QStringW; AValue: Boolean): Integer;
begin
  Result := Add(AName, BoolToStr(AValue, True));
end;

function TQXMLAttrs.Add(const AName: QStringW; AValue: Int64): Integer;
begin
  Result := Add(AName, IntToStr(AValue));
end;

function TQXMLAttrs.Add(const AName: QStringW; AValue: Double): Integer;
begin
  Result := Add(AName, FloatToStr(AValue));
end;

procedure TQXMLAttrs.Assign(ASource: TQXMLAttrs);
var
  I: Integer;
  Attr, ASrc: TQXMLAttr;
begin
  Clear;
  if (ASource <> nil) and (ASource.Count > 0) then
  begin
    for I := 0 to ASource.Count - 1 do
    begin
      ASrc := ASource[I];
      Attr := TQXMLAttr.Create;
      Attr.FName := ASrc.FName;
      Attr.FValue := ASrc.FValue;
      FItems.Add(Attr);
    end;
  end;
end;

function TQXMLAttrs.BoolByName(const AName: QStringW;
  const ADefVal: Boolean): Boolean;
var
  I: Integer;
begin
  I := IndexOfName(AName);
  if I <> -1 then
  begin
    if not TryStrToBool(Items[I].FValue, Result) then
      Result := ADefVal;
  end
  else
    Result := ADefVal;
end;

procedure TQXMLAttrs.Clear;
var
  I: Integer;
begin
  for I := 0 to FItems.Count - 1 do
    FreeObject(Items[I]);
  FItems.Clear;
end;

constructor TQXMLAttrs.Create(AOwner: TQXMLNode);
begin
  inherited Create;
  FOwner := AOwner;
  FItems := TQXMLAttrList.Create;
end;

procedure TQXMLAttrs.Delete(AIndex: Integer);
begin
  FreeObject(Items[AIndex]);
  FItems.Delete(AIndex);
end;

function TQXMLAttrs.DateTimeByName(const AName: QStringW;
  const ADefVal: TDateTime): TDateTime;
var
  I: Integer;
  S: QStringW;
begin
  I := IndexOfName(AName);
  if I <> -1 then
  begin
    S := Items[I].FValue;
    if not(ParseDateTime(PQCharW(S), Result) or ParseWebTime(PQCharW(S), Result)
      or TryStrToDateTime(S, Result)) then
      Result := ADefVal;
  end
  else
    Result := ADefVal;
end;

procedure TQXMLAttrs.Delete(AName: QStringW);
var
  AIndex: Integer;
begin
  AIndex := IndexOfName(AName);
  if AIndex <> -1 then
    Delete(AIndex);
end;

destructor TQXMLAttrs.Destroy;
begin
  Clear;
  FreeObject(FItems);
  inherited;
end;

function TQXMLAttrs.FloatByName(const AName: QStringW;
  const ADefVal: Double): Double;
var
  I: Integer;
begin
  I := IndexOfName(AName);
  if I <> -1 then
  begin
    if not TryStrToFloat(Items[I].FValue, Result) then
      Result := ADefVal;
  end
  else
    Result := ADefVal;
end;

function TQXMLAttrs.GetAsBoolean(AName: QStringW): Boolean;
var
  S: QStringW;
begin
  S := ValueByName(AName, '');
  if not TryStrToBool(S, Result) then
    raise EConvertError.CreateFmt(SValueNotBoolean, [S]);
end;

function TQXMLAttrs.GetAsDateTime(AName: QStringW): TDateTime;
var
  S: QStringW;
  p: PQCharW;
begin
  S := ValueByName(AName, '');
  p := PQCharW(S);
  if not(ParseDateTime(p, Result) or ParseWebTime(p, Result) or
    TryStrToDateTime(S, Result)) then
    raise EConvertError.CreateFmt(SValueNotDateTime, [S]);
end;

function TQXMLAttrs.GetAsDouble(AName: QStringW): Double;
var
  S: QStringW;
begin
  S := ValueByName(AName, '');
  if not TryStrToFloat(S, Result) then
    raise EConvertError.CreateFmt(SValueNotNumeric, [S]);
end;

function TQXMLAttrs.GetAsGuid(AName: QStringW): TGuid;
var
  S: QStringW;
begin
  S := ValueByName(AName, '');
  if not TryStrToGuid(S, Result) then
    raise EConvertError.CreateFmt(SValueNotGuid, [S]);
end;

function TQXMLAttrs.GetAsInt(AName: QStringW): Int64;
var
  S: QStringW;
begin
  S := ValueByName(AName, '');
  if not TryStrToInt64(S, Result) then
    raise EConvertError.CreateFmt(SValueNotInteger, [S]);
end;

function TQXMLAttrs.GetAsString(AName: QStringW): QStringW;
begin
  Result := ValueByName(AName, '');
end;

function TQXMLAttrs.GetCount: Integer;
begin
  Result := FItems.Count;
end;

function TQXMLAttrs.GetEnumerator: TQXMLAttrEnumerator;
begin
  Result := TQXMLAttrEnumerator.Create(Self);
end;

function TQXMLAttrs.GetItems(AIndex: Integer): TQXMLAttr;
begin
  Result := FItems[AIndex];
end;

function TQXMLAttrs.GuidByName(const AName: QStringW;
  const ADefVal: TGuid): TGuid;
var
  I: Integer;
begin
  I := IndexOfName(AName);
  if I <> -1 then
  begin
    if not TryStrToGuid(Items[I].FValue, Result) then
      Result := ADefVal;
  end
  else
    Result := ADefVal;
end;

function TQXMLAttrs.IndexOfName(const AName: QStringW): Integer;
var
  I, l, AHash: Integer;
  AItem: TQXMLAttr;
begin
  Result := -1;
  l := Length(AName);
  AHash := HashOf(PQCharW(AName), l shl 1);
  for I := 0 to Count - 1 do
  begin
    AItem := Items[I];
    if Length(AItem.FName) = l then
    begin
      if XMLCaseSensitive then
      begin
        if AItem.FNameHash = 0 then
          AItem.FNameHash := HashOf(PQCharW(AItem.FName), l shl 1);
        if AItem.FNameHash = AHash then
        begin
          if AItem.FName = AName then
          begin
            Result := I;
            Break;
          end;
        end;
      end
      else if StartWithW(PQCharW(AItem.FName), PQCharW(AName), True) then
      begin
        Result := I;
        Break;
      end;
    end;
  end;
end;

function TQXMLAttrs.IntByName(const AName: QStringW;
  const ADefVal: Int64): Int64;
var
  I: Integer;
begin
  I := IndexOfName(AName);
  if I <> -1 then
  begin
    if not TryStrToInt64(Items[I].FValue, Result) then
      Result := ADefVal;
  end
  else
    Result := ADefVal;
end;

function TQXMLAttrs.ItemByName(const AName: QStringW): TQXMLAttr;
var
  I: Integer;
begin
  Result := nil;
  I := IndexOfName(AName);
  if I <> -1 then
    Result := Items[I];
end;

procedure TQXMLAttrs.SetAsBoolean(AName: QStringW; const Value: Boolean);
begin
  SetAsString(AName, BoolToStr(Value, True));
end;

procedure TQXMLAttrs.SetAsDateTime(AName: QStringW; const Value: TDateTime);
var
  AInt: Integer;
begin
  AInt := Trunc(Value);
  if AInt <> 0 then
  begin
    if IsZero(Value - AInt) then
      SetAsString(AName, FormatDateTime(XMLDateFormat, Value))
    else
      SetAsString(AName, FormatDateTime(XMLDateTimeFormat, Value));
  end
  else
    SetAsString(AName, FormatDateTime(XMLTimeFormat, Value));
end;

procedure TQXMLAttrs.SetAsDouble(AName: QStringW; const Value: Double);
begin
  SetAsString(AName, FloatToStr(Value));
end;

procedure TQXMLAttrs.SetAsGuid(AName: QStringW; const Value: TGuid);
begin
  SetAsString(AName, GuidToString(Value));
end;

procedure TQXMLAttrs.SetAsInt(AName: QStringW; const Value: Int64);
begin
  SetAsString(AName, IntToStr(Value));
end;

procedure TQXMLAttrs.SetAsString(AName: QStringW; const Value: QStringW);
var
  I: Integer;
begin
  I := IndexOfName(AName);
  if I <> -1 then
    Items[I].FValue := Value
  else
    Add(AName, Value);
end;

function TQXMLAttrs.ValueByName(const AName, ADefVal: QStringW): QStringW;
var
  I: Integer;
begin
  I := IndexOfName(AName);
  if I <> -1 then
    Result := Items[I].FValue
  else
    Result := ADefVal;
end;

{ TQXMLNode }

function TQXMLNode.Add: TQXMLNode;
begin
  Result := CreateNode;
  Result.FParent := Self;
  if not Assigned(FItems) then
    FItems := TQXMLNodeList.Create;
  FItems.Add(Result);
end;

function TQXMLNode.Add(const AName_Text: QStringW; AType: TQXMLNodeType)
  : TQXMLNode;
begin
  if AType = xntNode then
    Result := AddNode(AName_Text)
  else
  begin
    Result := Add;
    Result.FNodeType := AType;
    Result.Text := AName_Text;
  end;
end;

function TQXMLNode.AddCData(const AText: QStringW): TQXMLNode;
begin
  Result := Add(AText, xntCData);
end;

function TQXMLNode.AddComment(const AText: QStringW): TQXMLNode;
begin
  Result := Add(AText, xntComment);
end;

function TQXMLNode.AddNode(const AName: QStringW): TQXMLNode;
begin
  if ValidXMLName(AName) then
  begin
    Result := Add;
    Result.FNodeType := xntNode;
    Result.FName := AName;
    DoNodeNameChanged(Result);
  end
  else
    raise Exception.Create(SBadXMLName);
end;

function TQXMLNode.IndexOf(const AName: QStringW): Integer;
var
  I, l, AHash: Integer;
  AItem: TQXMLNode;
  AFound: Boolean;
begin
  Result := -1;
  l := Length(AName);
  if l > 0 then
    AHash := HashOf(PQCharW(AName), l shl 1)
  else
    AHash := 0;
  AFound := False;
  for I := 0 to Count - 1 do
  begin
    AItem := Items[I];
    if (AItem.NodeType = xntNode) and (Length(AItem.FName) = l) then
    begin
      if XMLCaseSensitive then
      begin
        if AItem.FNameHash = 0 then
          AItem.FNameHash := HashOf(PQCharW(AItem.FName),
            Length(AItem.FName) shl 1);
        if AItem.FNameHash = AHash then
        begin
          if Items[I].FName = AName then
            AFound := True;
        end;
      end
      else // 忽略大小写，不推荐
        AFound := StartWithW(PQCharW(AItem.FName), PQCharW(AName), True);
      if AFound then
      begin
        Result := I;
        Break;
      end;
    end;
  end;
end;

// function TQXMLNode.InternalAddObject(AName: QStringW; AObject: TObject;
// AOnFilter: TQXMLRttiFilterEvent; ANest: Boolean; ATag: Pointer): TQXMLNode;
// function GetObjectName(AObj: TObject): String;
// begin
// if AObj <> nil then
// begin
// {$IFDEF TYPENAMEASMETHODPREF}
// Result := TObject(AObj).ClassName;
// {$ELSE}
// if TObject(AObj) is TComponent then
// Result := TComponent(AObj).GetNamePath
// else if GetPropInfo(AObj, 'Name') <> nil then
// Result := GetStrProp(AObj, 'Name');
// if Length(Result) = 0 then
// Result := TObject(AObj).ClassName;
// {$ENDIF}
// end
// else
// SetLength(Result, 0);
// end;
//
// function GetMethodName(AMethod: TMethod): String;
// var
// AMethodName: String;
// begin
// if AMethod.Data <> nil then
// begin
// Result := GetObjectName(AMethod.Data);
// AMethodName := TObject(AMethod.Data).MethodName(AMethod.Code);
// {$IFDEF CPUX64}
// if Length(Result) = 0 then
// Result := IntToHex(Int64(AMethod.Data), 16);
// if Length(AMethodName) = 0 then
// AMethodName := IntToHex(Int64(AMethod.Code), 16);
// {$ELSE}
// if Length(Result) = 0 then
// Result := IntToHex(IntPtr(AMethod.Data), 8);
// if Length(AMethodName) = 0 then
// AMethodName := IntToHex(IntPtr(AMethod.Code), 8);
// {$ENDIF}
// Result := Result + '.' + AMethodName;
// end
// else if AMethod.Code <> nil then
// begin
// {$IFDEF CPUX64}
// Result := IntToHex(Int64(AMethod.Code), 16);
// {$ELSE}
// Result := IntToHex(IntPtr(AMethod.Code), 8);
// {$ENDIF}
// end
// else
// SetLength(Result, 0);
// end;
//
// procedure AddChildren(AParent: TQXMLNode; AObj: TObject);
// var
// AList: PPropList;
// ACount: Integer;
// I: Integer;
// AChild: TQXMLNode;
// ACharVal: QStringA;
// V: Variant;
// Accept: Boolean;
// const
// AttrName: QStringW = 'value';
// begin
// if AObj = nil then
// Exit;
// if PTypeInfo(AObject.ClassInfo) = nil then // 对象没有RTTI信息
// Exit;
// AParent.Attrs.Add('class', AObject.ClassName); // 记录类型名称
// AList := nil;
// ACount := GetPropList(AObj, AList);
// try
// for I := 0 to ACount - 1 do
// begin
// if Assigned(AOnFilter) then
// begin
// Accept := True;
// {$IF RTLVersion>=26}
// AOnFilter(AParent, AObj, AList[I].NameFld.ToString, AList[I].PropType^,
// Accept, ATag);
// {$ELSE}
// AOnFilter(AParent, AObj, AList[I].Name, AList[I].PropType^,
// Accept, ATag);
// {$IFEND >=XE5}
// if not Accept then
// Continue;
// end;
// {$IF RTLVersion>=26}
// AChild := AParent.Add(AList[I].NameFld.ToString);
// {$ELSE}
// AChild := AParent.Add(AList[I].Name);
// {$IFEND >=XE5}
// case AList[I].PropType^.Kind of
// tkChar:
// begin
// ACharVal.Length := 1;
// ACharVal.Chars[0] := GetOrdProp(AObj, AList[I]);
// AChild.Attrs.Add(AttrName, ACharVal);
// end;
// tkWChar:
// AChild.Attrs.Add(AttrName, QCharW(GetOrdProp(AObj, AList[I])));
// tkInteger:
// AChild.Attrs.Add(AttrName, IntToStr(GetOrdProp(AObj, AList[I])));
// tkClass:
// if ANest then
// AddChildren(AChild, TObject(GetOrdProp(AObj, AList[I])))
// else
// AChild.Attrs.Add(AttrName,
// GetObjectName(TObject(GetOrdProp(AObj, AList[I]))));
// tkEnumeration:
// AChild.Attrs.Add(AttrName, GetEnumProp(AObj, AList[I]));
// tkSet:
// AChild.Attrs.Add(AttrName, '[' + GetSetProp(AObj, AList[I]) + ']');
// tkFloat:
// AChild.Attrs.Add(AttrName, FloatToStr(GetFloatProp(AObj, AList[I])));
// tkMethod:
// AChild.Attrs.Add(AttrName,
// GetMethodName(GetMethodProp(AObj, AList[I])));
// {$IFNDEF NEXTGEN}
// tkString, tkLString:
// AChild.Attrs.Add(AttrName, GetStrProp(AObj, AList[I]));
// tkWString:
// AChild.Attrs.Add(AttrName, GetWideStrProp(AObj, AList[I]));
// {$ENDIF !NEXTGEN}
// {$IFDEF UNICODE}
// tkUString:
// AChild.Attrs.Add(AttrName, GetStrProp(AObj, AList[I]));
// {$ENDIF UNICODE}
// tkVariant:
// AChild.Attrs.Add(AttrName, VarToStr(GetVariantProp(AObj, AList[I])));
// tkInt64:
// AChild.Attrs.Add(AttrName, IntToStr(GetInt64Prop(AObj, AList[I])));
// tkDynArray:
// begin
// DynArrayToVariant(V, GetDynArrayProp(AObj, AList[I]),
// AList[I].PropType^);
// AChild.Attrs.Add(AttrName, VarToStr(V));
// end;
// end;
// end;
// finally
// if AList <> nil then
// FreeMem(AList);
// end;
// end;
//
// begin
/// / 利用RTTI直接获取对象的属性信息并保存到结果中
// Result := Add(AName);
// AddChildren(Result, AObject);
// end;

function TQXMLNode.AddText(const AText: QStringW): TQXMLNode;
begin
  Result := Add(AText, xntText);
end;

procedure TQXMLNode.Assign(ANode: TQXMLNode);
var
  I: Integer;
  ASrc, ADest: TQXMLNode;
begin
  FNodeType := ANode.NodeType;
  Clear;
  if Assigned(ANode.FAttrs) then
    Attrs.Assign(ANode.Attrs);
  for I := 0 to ANode.Count - 1 do
  begin
    ASrc := ANode.Items[I];
    ADest := Add;
    ADest.Assign(ASrc);
    ADest.FName := ASrc.FName;
    ADest.FNameHash := ASrc.FNameHash;
  end;
end;

procedure TQXMLNode.AttachTo(AParent: TQXMLNode);
begin
  if (AParent <> Self) then
  begin
    if IsChildOf(AParent) then // 已经是子结点，直接返回
      Exit;
    if AParent.NodeType <> xntNode then
      raise Exception.Create(SParentMustNode);
    Detach;
    if not Assigned(AParent.FItems) then
      AParent.FItems := TQXMLNodeList.Create;
    AParent.FItems.Add(Self);
    FParent := AParent;
    DoNodeNameChanged(Self);
  end;
end;

function TQXMLNode.AttrByPath(const APath, AttrName: QStringW): TQXMLAttr;
var
  ANode: TQXMLNode;
begin
  ANode := ItemByPath(APath);
  if Assigned(ANode) then
    Result := ANode.Attrs.ItemByName(AttrName)
  else
    Result := nil;
end;

function TQXMLNode.AttrValueByPath(const APath, AttrName, ADefVal: QStringW)
  : QStringW;
var
  Attr: TQXMLAttr;
begin
  Attr := AttrByPath(APath, AttrName);
  if Assigned(Attr) then
    Result := Attr.Value
  else
    Result := ADefVal;
end;

procedure TQXMLNode.Clear(AIncAttrs: Boolean);
var
  I: Integer;
begin
  if Assigned(FItems) then
  begin
    for I := 0 to FItems.Count - 1 do
      FreeNode(Items[I]);
    FItems.Clear;
  end;
  if Assigned(FAttrs) and AIncAttrs then
    FAttrs.Clear;
end;

function TQXMLNode.Clone: TQXMLNode;
begin
  Result := Copy;
end;

function TQXMLNode.Copy: TQXMLNode;
begin
  Result := CreateNode;
  Result.Assign(Self);
end;
{$IF RTLVersion>=21}

function TQXMLNode.CopyIf(const ATag: Pointer; AFilter: TQXMLFilterEventA)
  : TQXMLNode;
  procedure NestCopy(AParentSource, AParentDest: TQXMLNode);
  var
    I: Integer;
    Accept: Boolean;
    AChildSource, AChildDest: TQXMLNode;
  begin
    for I := 0 to AParentSource.Count - 1 do
    begin
      Accept := True;
      AChildSource := AParentSource[I];
      AFilter(Self, AChildSource, Accept, ATag);
      if Accept then
      begin
        AChildDest := AParentDest.Add(AChildSource.FName,
          AChildSource.NodeType);
        if Assigned(AChildSource.FAttrs) then
          AChildDest.Attrs.Assign(AChildSource.Attrs);
        if AChildSource.Count > 0 then
          NestCopy(AChildSource, AChildDest);
      end;
    end;
  end;

begin
  if Assigned(AFilter) then
  begin
    Result := CreateNode;
    Result.FNodeType := NodeType;
    Result.FName := FName;
    if Count > 0 then
      NestCopy(Self, Result);
  end
  else
    Result := Copy;
end;
{$IFEND >=2010}

function TQXMLNode.CopyIf(const ATag: Pointer; AFilter: TQXMLFilterEvent)
  : TQXMLNode;

  procedure NestCopy(AParentSource, AParentDest: TQXMLNode);
  var
    I: Integer;
    Accept: Boolean;
    AChildSource, AChildDest: TQXMLNode;
  begin
    for I := 0 to AParentSource.Count - 1 do
    begin
      Accept := True;
      AChildSource := AParentSource[I];
      AFilter(Self, AChildSource, Accept, ATag);
      if Accept then
      begin
        AChildDest := AParentDest.Add(AChildSource.FName,
          AChildSource.NodeType);
        if Assigned(AChildSource.FAttrs) then
          AChildDest.Attrs.Assign(AChildSource.Attrs);
        if AChildSource.Count > 0 then
          NestCopy(AChildSource, AChildDest);
      end;
    end;
  end;

begin
  if Assigned(AFilter) then
  begin
    Result := CreateNode;
    Result.FNodeType := NodeType;
    Result.FName := FName;
    if Count > 0 then
      NestCopy(Self, Result);
  end
  else
    Result := Copy;
end;

constructor TQXMLNode.Create;
begin
  inherited;
end;

function TQXMLNode.CreateNode: TQXMLNode;
begin
  if Assigned(OnQXMLNodeCreate) then
    Result := OnQXMLNodeCreate
  else
    Result := TQXMLNode.Create;
end;

procedure TQXMLNode.Delete(AIndex: Integer);
var
  ANode: TQXMLNode;
begin
  ANode := Remove(AIndex);
  if Assigned(ANode) then
    FreeNode(ANode);
end;

procedure TQXMLNode.Delete(AName: QStringW; ADeleteAll: Boolean);
var
  I: Integer;
begin
  I := 0;
  while I < Count do
  begin
    if Items[I].FName = AName then
    begin
      Delete(I);
      if not ADeleteAll then
        Break;
    end
    else
      Inc(I);
  end;
end;

procedure TQXMLNode.Delete;
begin
  if Assigned(FParent) then
    FParent.Delete(ItemIndex)
  else
    FreeObject(Self);
end;

{$IF RTLVersion>=21}

procedure TQXMLNode.DeleteIf(const ATag: Pointer; ANest: Boolean;
  AFilter: TQXMLFilterEventA);
  procedure DeleteChildren(AParent: TQXMLNode);
  var
    I: Integer;
    Accept: Boolean;
    AChild: TQXMLNode;
  begin
    I := 0;
    while I < AParent.Count do
    begin
      Accept := True;
      AChild := AParent.Items[I];
      if ANest then
        DeleteChildren(AChild);
      AFilter(Self, AChild, Accept, ATag);
      if Accept then
        AParent.Delete(I)
      else
        Inc(I);
    end;
  end;

begin
  if Assigned(AFilter) then
    DeleteChildren(Self)
  else
    Clear;
end;
{$IFEND >=2010}

procedure TQXMLNode.DeleteIf(const ATag: Pointer; ANest: Boolean;
  AFilter: TQXMLFilterEvent);
  procedure DeleteChildren(AParent: TQXMLNode);
  var
    I: Integer;
    Accept: Boolean;
    AChild: TQXMLNode;
  begin
    I := 0;
    while I < AParent.Count do
    begin
      Accept := True;
      AChild := AParent.Items[I];
      if ANest then
        DeleteChildren(AChild);
      AFilter(Self, AChild, Accept, ATag);
      if Accept then
        AParent.Delete(I)
      else
        Inc(I);
    end;
  end;

begin
  if Assigned(AFilter) then
    DeleteChildren(Self)
  else
    Clear;
end;

destructor TQXMLNode.Destroy;
begin
  if Assigned(FItems) then
  begin
    Clear;
    FreeObject(FItems);
  end;
  if Assigned(FAttrs) then
    FreeObject(FAttrs);
  inherited;
end;

procedure TQXMLNode.Detach;
begin
  if Assigned(FParent) then
  begin
    FParent.Remove(ItemIndex);
  end;
end;

procedure TQXMLNode.DoNodeNameChanged(ANode: TQXMLNode);
begin

end;

procedure TQXMLNode.DoParse(p: PQCharW);
var
  ACol, ARow: Integer;
  ps, pl: PQCharW;
  AttrName: QStringW;
  // 解析DTD部分，但QXML不支持DTD部分，会忽略掉其中的内容
  function ParseDTD: Boolean;
  var
    APairCount: Integer;
  begin
    if StartWithW(p, '<!DOCTYPE', False) or StartWithW(p, '<!ELEMENT', False) or
      StartWithW(p, '<!ATTLIST', False) then
    begin
      APairCount := 1;
      Inc(p, 9); // 都是9个字符长度,:)
      while (p^ <> #0) do
      begin
        if p^ = '<' then
          Inc(APairCount)
        else if p^ = '>' then
        begin
          Dec(APairCount);
          if APairCount = 0 then
          begin
            Inc(p);
            SkipSpaceW(p);
            Break;
          end;
        end
        else
          Inc(p);
      end;
      Result := True;
    end
    else
      Result := False;
  end;
  procedure InternalParse(AParent: TQXMLNode);
  var
    AChild: TQXMLNode;
    ws: PQCharW;
    AClosed: Boolean;
  const
    TagStart: PQCharW = '<';
    TagClose: PQCharW = '>';
    Question: PQCharW = '?';
    TagNameEnd: PQCharW = #9#10#13#32'/>';
    AttrNameEnd: PQCharW = #9#10#13#32'=/>';
  begin
    while p^ <> #0 do
    begin
      SkipSpaceW(p);
      if p^ = '<' then // 标签开始
      begin
        if p[1] = '/' then // </AParent.Name>
        begin
          Inc(p, 2);
          ws := p;
          SkipUntilW(p, TagClose);
          if p^ = '>' then
          begin
            if (Length(AParent.Name) = (p - ws)) and
              StartWithW(ws, PQCharW(AParent.Name), False) then
            begin
              Inc(p);
              Exit;
            end
            else
              raise Exception.CreateFmt(SUnexpectXMLTagClose,
                [StrDupX(ws, p - ws), AParent.Name]);
          end
          else
            raise Exception.CreateFmt(SUnexpectXMLTagClose,
              [StrDupX(ws, p - ws), AParent.Name]);
        end
        else if p[1] = '!' then
        begin
          if (p[2] = '-') and (p[3] = '-') then // 注释
          begin
            Inc(p, 4);
            ws := p;
            AClosed := False;
            while p^ <> #0 do
            begin
              if (p[0] = '-') and (p[1] = '-') then
              begin
                if p[2] = '>' then
                begin
                  AParent.Add(StrDupX(ws, p - ws), xntComment);
                  Inc(p, 3);
                  AClosed := True;
                  Break;
                end
                else
                  raise Exception.Create(SBadXMLComment);
              end
              else
                Inc(p);
            end;
            if not AClosed then
              raise Exception.Create(SUnterminateXMLComment);
          end
          else if StartWithW(p, '<![CDATA[', False) then // CDATA
          begin
            Inc(p, 9);
            ws := p;
            AClosed := False;
            while p^ <> #0 do
            begin
              if (p[0] = ']') and (p[1] = ']') then
              begin
                if p[2] = '>' then
                begin
                  AParent.Add(StrDupX(ws, p - ws), xntCData);
                  Inc(p, 3);
                  AClosed := True;
                  Break;
                end
                else
                  Inc(p);
              end
              else
                Inc(p);
            end;
            if not AClosed then
              raise Exception.Create(SUnterminateXMLCData);
          end
          else // DTD 定义？
          begin
            if not ParseDTD then
              raise Exception.Create(SBadXMLName);
          end;
        end
        else if p[1] = '?' then
        begin
          if StartWithW(p, '<?xml', True) and IsSpaceW(p + 5) then
          begin
            Inc(p, 6);
            SkipUntilW(p, Question);
            if StartWithW(p, '?>', False) then
            begin
              Inc(p, 2);
              SkipSpaceW(p);
            end
            else
              raise Exception.CreateFmt(SUnclosedXMLTag, [AParent.Name]);
          end
          else
            raise Exception.Create(SBadXMLName);
        end
        else // 结点
        begin
          Inc(p);
          SkipSpaceW(p);
          ws := p;
          SkipUntilW(p, TagNameEnd);
          AChild := AParent.Add(StrDupX(ws, p - ws), xntNode);
          if (p^ <> '>') and (p^ <> '/') then
          begin
            // 解析属性
            while p^ <> #0 do
            begin
              SkipSpaceW(p);
              ws := p;
              SkipUntilW(p, AttrNameEnd);
              AttrName := StrDupX(ws, p - ws);
              SkipSpaceW(p);
              if p^ = '=' then
              begin
                Inc(p);
                SkipSpaceW(p);
                if (p^ = '''') or (p^ = '"') then
                begin
                  ws := p;
                  Inc(p);
                  while p^ <> #0 do
                  begin
                    if p^ = ws^ then
                    begin
                      Inc(p);
                      Break;
                    end
                    else
                      Inc(p);
                  end;
                  AChild.Attrs.Add(AttrName, XMLDecode(ws + 1, p - ws - 2));
                end
                else
                  raise Exception.Create(SXMLBadAttrValue);
              end
              else if (p^ = '/') or (p^ = '>') then
                Break
              else
                raise Exception.Create(SXMLAttrValueMissed);
            end;
          end;
          if p^ = '>' then
            Inc(p)
          else if (p[0] = '/') and (p[1] = '>') then // 直接结束，没有附加内容的结点
          begin
            Inc(p, 2);
            Continue;
          end
          else
            raise Exception.Create(SUnterminatedXMLTag);
          SkipSpaceW(p);
          if p^ = '<' then
            InternalParse(AChild)
          else // 不是标签开始,中间包含文本内容了
          begin
            ws := p;
            SkipUntilW(p, TagStart);
            pl := p - 1;
            while IntPtr(pl) > IntPtr(ws) do
            begin
              if IsSpaceW(pl) then
                Dec(pl)
              else
                Break;
            end;
            AChild.Add(XMLDecode(ws, pl - ws + 1), xntText);
            if (p[0] = '<') then
              InternalParse(AChild);
          end;
        end;
      end
      else if p^ <> #0 then // 不是<开始的标签，为文本
      begin
        if p <> ps then
        begin
          ws := p;
          SkipUntilW(p, TagStart);
          AParent.Add(StrDupX(ws, p - ws), xntText);
        end
        else
          raise Exception.Create(SBadXMLTagStart);
      end;
    end;
  end;

  procedure CheckIsXMLRoot;
  var
    AItem, AChild: TQXMLNode;
  begin
    if (Count = 1) then
    begin
      AItem := Items[0];
      if (AItem.NodeType = xntNode) and (AItem.Name = 'xml') then
      begin
        FItems.Clear;
        FItems.Capacity := AItem.Count;
        // 复制子结点的数据到根结点
        while AItem.FItems.Count > 0 do
          AItem[0].MoveTo(Self, FItems.Count);
        Attrs.Assign(AItem.Attrs);
        FreeAndNil(AItem);
      end;
    end;
  end;

begin
  ps := p;
  SkipSpaceW(p);
  try
    InternalParse(Self);
    // 只有一个子结点 <xml> 时，将子结点移动到根结点
    CheckIsXMLRoot;
  except
    on E: Exception do
    begin
      pl := StrPosW(ps, p, ACol, ARow);
      raise Exception.CreateFmt('%s'#13#10'位置:第%d行 第%d列'#13#10'行内容：%s',
        [E.Message, ARow, ACol, DecodeLineW(pl, True, 1024)]);
    end;
  end;
end;

// Redo:格式化不对
function TQXMLNode.Encode(ADoFormat: Boolean; AIndent: QStringW): QStringW;
var
  ABuilder: TQStringCatHelperW;
begin
  ABuilder := TQStringCatHelperW.Create; // (16384);
  try
    InternalEncode(ABuilder, ADoFormat, AIndent);
    Result := ABuilder.Value;
  finally
    FreeObject(ABuilder);
  end;
end;
{$IF RTLVersion>=21}

function TQXMLNode.FindIf(const ATag: Pointer; ANest: Boolean;
  AFilter: TQXMLFilterEventA): TQXMLNode;
  function DoFind(AParent: TQXMLNode): TQXMLNode;
  var
    I: Integer;
    AChild: TQXMLNode;
    Accept: Boolean;
  begin
    Result := nil;
    for I := 0 to AParent.Count - 1 do
    begin
      AChild := AParent[I];
      Accept := True;
      AFilter(Self, AChild, Accept, ATag);
      if Accept then
        Result := AChild
      else if ANest then
        Result := DoFind(AChild);
      if Result <> nil then
        Break;
    end;
  end;

begin
  if Assigned(AFilter) then
    Result := DoFind(Self)
  else
    Result := nil;
end;
{$IFEND >=2010}

function TQXMLNode.FindIf(const ATag: Pointer; ANest: Boolean;
  AFilter: TQXMLFilterEvent): TQXMLNode;
  function DoFind(AParent: TQXMLNode): TQXMLNode;
  var
    I: Integer;
    AChild: TQXMLNode;
    Accept: Boolean;
  begin
    Result := nil;
    for I := 0 to AParent.Count - 1 do
    begin
      AChild := AParent[I];
      Accept := True;
      AFilter(Self, AChild, Accept, ATag);
      if Accept then
        Result := AChild
      else if ANest then
        Result := DoFind(AChild);
      if Result <> nil then
        Break;
    end;
  end;

begin
  if Assigned(AFilter) then
    Result := DoFind(Self)
  else
    Result := nil;
end;

function TQXMLNode.ForcePath(APath: QStringW): TQXMLNode;
var
  AName: QStringW;
  p: PQCharW;
  AParent: TQXMLNode;
const
  PathDelimiters: PWideChar = './\';
begin
  p := PQCharW(APath);
  AParent := Self;
  Result := Self;
  while p^ <> #0 do
  begin
    AName := DecodeTokenW(p, PathDelimiters, WideChar(0), True);
    Result := AParent.ItemByName(AName);
    if not Assigned(Result) then
      Result := AParent.Add(AName);
    AParent := Result;
  end;
end;

procedure TQXMLNode.FreeNode(ANode: TQXMLNode);
begin
  if Assigned(OnQXMLNodeFree) then
  begin
    ANode.FParent := nil;
    OnQXMLNodeFree(ANode);
  end
  else
    FreeObject(ANode);
end;

{$IF RTLVersion>=21}

procedure TQXMLNode.FromRecord<T>(const ARecord: T);
begin
  FromRtti(@ARecord, TypeInfo(T));
end;

procedure TQXMLNode.FromRtti(ASource: Pointer; AType: PTypeInfo);
var
  AValue: TValue;
  procedure AddCollection(AParent: TQXMLNode; ACollection: TCollection);
  var
    J: Integer;
  begin
    for J := 0 to ACollection.Count - 1 do
      AParent.Add('item', xntNode).FromRtti(ACollection.Items[J]);
  end;
  procedure AddVariant(AParent: TQXMLNode; const AName: String;
    const V: Variant);
  var
    I: Integer;
  begin
    if VarIsArray(V) then
    begin
      AParent := AParent.Add(AName, xntNode);
      with AParent do
      begin
        for I := VarArrayLowBound(V, 1) to VarArrayHighBound(V, 1) do
          AddVariant(AParent.Add('item', xntNode), '', V[I]);
      end;
    end
    else
    begin
      with AParent.Add(AName, xntNode) do
      begin
        Attrs.Add('type', VarType(V));
        Attrs.Add('value').AsVariant := V;
      end;
    end;
  end;
// 修正XE6中System.rtti中TValue对tkSet类型处理的Bug
  function SetAsOrd(AValue: TValue): Int64;
  var
    ATemp: Integer;
  begin
    AValue.ExtractRawData(@ATemp);
    case GetTypeData(AValue.TypeInfo).OrdType of
      otSByte:
        Result := PShortint(@ATemp)^;
      otUByte:
        Result := PByte(@ATemp)^;
      otSWord:
        Result := PSmallint(@ATemp)^;
      otUWord:
        Result := PWord(@ATemp)^;
      otSLong:
        Result := PInteger(@ATemp)^;
      otULong:
        Result := PCardinal(@ATemp)^
    else
      Result := 0;
    end;
  end;
  procedure AddRecord;
  var
    AContext: TRttiContext;
    AFields: TArray<TRttiField>;
    ARttiType: TRttiType;
    I, J: Integer;
    AObj: TObject;
  begin
    AContext := TRttiContext.Create;
    ARttiType := AContext.GetType(AType);
    AFields := ARttiType.GetFields;
    for J := Low(AFields) to High(AFields) do
    begin
      if AFields[J].FieldType <> nil then
      begin
        // 如果是从结构体，则记录其成员，如果是对象，则只记录其公开的属性，特殊处理TStrings和TCollection
        case AFields[J].FieldType.TypeKind of
          tkInteger:
            Attrs.Add(AFields[J].Name).AsInteger := AFields[J].GetValue(ASource)
              .AsInteger;
{$IFNDEF NEXTGEN}tkString, tkLString, tkWString,
{$ENDIF !NEXTGEN}tkUString:
            Attrs.Add(AFields[J].Name).AsString :=
              AFields[J].GetValue(ASource).AsString;
          tkEnumeration:
            begin
              if GetTypeData(AFields[J].FieldType.Handle)
                .BaseType^ = TypeInfo(Boolean) then
                Attrs.Add(AFields[J].Name).AsBoolean :=
                  AFields[J].GetValue(ASource).AsBoolean
              else if XMLRttiEnumAsInt then
                Attrs.Add(AFields[J].Name).AsInteger :=
                  AFields[J].GetValue(ASource).AsOrdinal
              else
                Attrs.Add(AFields[J].Name).AsString :=
                  AFields[J].GetValue(ASource).ToString;
            end;
          tkSet:
            begin
              if XMLRttiEnumAsInt then
                Attrs.Add(AFields[J].Name).AsInt64 :=
                  SetAsOrd(AFields[J].GetValue(ASource))
              else
                Attrs.Add(AFields[J].Name).AsString :=
                  AFields[J].GetValue(ASource).ToString;
            end;
          tkChar, tkWChar:
            Attrs.Add(AFields[J].Name).AsString :=
              AFields[J].GetValue(ASource).ToString;
          tkFloat:
            begin
              if (AFields[J].FieldType.Handle = TypeInfo(TDateTime)) or
                (AFields[J].FieldType.Handle = TypeInfo(TTime)) or
                (AFields[J].FieldType.Handle = TypeInfo(TDate)) then
              begin
                // 判断一个数值是否是一个有效的值

                Attrs.Add(AFields[J].Name).AsDateTime :=
                  AFields[J].GetValue(ASource).AsExtended
              end
              else
                Attrs.Add(AFields[J].Name).AsFloat :=
                  AFields[J].GetValue(ASource).AsExtended;
            end;
          tkInt64:
            Attrs.Add(AFields[J].Name).AsInt64 :=
              AFields[J].GetValue(ASource).AsInt64;
          tkVariant:
            AddVariant(Self, AFields[J].Name, AFields[J].GetValue(ASource)
              .AsVariant);
          tkArray, tkDynArray:
            begin
              with Add(AFields[J].Name, xntNode) do
              begin
                AValue := AFields[J].GetValue(ASource);
                for I := 0 to AValue.GetArrayLength - 1 do
                  Add('item', xntNode).FromRtti(AValue.GetArrayElement(I));
              end;
            end;
          tkClass:
            begin
              AValue := AFields[J].GetValue(ASource);
              AObj := AValue.AsObject;
              if (AObj is TStrings) then
                Add(AFields[J].Name, xntNode).AddText(TStrings(AObj).Text)
              else if AObj is TCollection then
                AddCollection(Add(AFields[J].Name, xntNode),
                  AObj as TCollection)
              else // 其它类型的对象不保存
                Add(AFields[J].Name, xntNode).FromRtti(AObj, AObj.ClassInfo);
            end;
          tkRecord:
            begin
              // AValue := AFields[J].GetValue(ASource);
              if AFields[J].FieldType.Handle = TypeInfo(TGuid) then
                Attrs.Add(AFields[J].Name).AsString :=
                  GuidToString
                  (PGuid(Pointer(IntPtr(ASource) + AFields[J].Offset))^)
              else
                Add(AFields[J].Name, xntNode)
                  .FromRtti(Pointer(IntPtr(ASource) + AFields[J].Offset),
                  AFields[J].FieldType.Handle);
            end;
        end;
      end
      else
        raise Exception.CreateFmt(SMissRttiTypeDefine, [AFields[J].Name]);
    end;
  end;
// Object
  procedure AddObject;
  var
    APropList: PPropList;
    ACount: Integer;
    J: Integer;
    AObj, AChildObj: TObject;
    AName: String;
  begin
    AObj := ASource;
    if AObj is TStrings then
      AddText((AObj as TStrings).Text)
    else if AObj is TCollection then
      AddCollection(Self, AObj as TCollection)
    else
    begin
      APropList := nil;
      ACount := GetPropList(AType, APropList);
      try
        for J := 0 to ACount - 1 do
        begin
          if Assigned(APropList[J].GetProc) and Assigned(APropList[J].SetProc)
            and (not(APropList[J].PropType^.Kind in [tkMethod, tkInterface,
            tkClassRef, tkPointer, tkProcedure])) then
          begin
{$IF RTLVersion>25}
            AName := APropList[J].NameFld.ToString;
{$ELSE}
            AName := String(APropList[J].Name);
{$IFEND}
            case APropList[J].PropType^.Kind of
              tkClass:
                begin
                  AChildObj := Pointer(GetOrdProp(AObj, APropList[J]));
                  if AChildObj is TStrings then
                    Add(AName, xntNode).AddText((AChildObj as TStrings).Text)
                  else if AChildObj is TCollection then
                    AddCollection(Add(AName, xntNode), AChildObj as TCollection)
                  else
                    Add(AName, xntNode).FromRtti(AChildObj);
                end;
              tkRecord, tkArray, tkDynArray: // 记录、数组、动态数组属性系统也不保存，也没提供所有太好的接口
                raise Exception.Create(SUnsupportPropertyType);
              tkInteger:
                Attrs.Add(AName).AsInt64 := GetOrdProp(AObj, APropList[J]);
              tkFloat:
                begin
                  if (APropList[J].PropType^ = TypeInfo(TDateTime)) or
                    (APropList[J].PropType^ = TypeInfo(TTime)) or
                    (APropList[J].PropType^ = TypeInfo(TDate)) then
                  begin
                    // 判断一个数值是否是一个有效的值
                    Attrs.Add(AName).AsDateTime :=
                      GetFloatProp(AObj, APropList[J]);
                  end
                  else
                    Attrs.Add(AName).AsFloat :=
                      GetFloatProp(AObj, APropList[J]);
                end;
              tkChar, tkString, tkWChar, tkLString, tkWString, tkUString:
                Attrs.Add(AName).AsString := GetStrProp(AObj, APropList[J]);
              tkEnumeration:
                begin
                  if GetTypeData(APropList[J]^.PropType^)
                    ^.BaseType^ = TypeInfo(Boolean) then
                    Attrs.Add(AName).AsBoolean :=
                      GetOrdProp(AObj, APropList[J]) <> 0
                  else if XMLRttiEnumAsInt then
                    Attrs.Add(AName).AsInteger := GetOrdProp(AObj, APropList[J])
                  else
                    Attrs.Add(AName).AsString :=
                      GetEnumProp(AObj, APropList[J]);
                end;
              tkSet:
                begin
                  if XMLRttiEnumAsInt then
                    Attrs.Add(AName).AsInteger := GetOrdProp(AObj, APropList[J])
                  else
                    Attrs.Add(AName).AsString :=
                      GetSetProp(AObj, APropList[J], True);
                end;
              tkVariant:
                Attrs.Add(AName).AsVariant := GetPropValue(AObj, APropList[J]);
              tkInt64:
                Attrs.Add(AName).AsInt64 := GetInt64Prop(AObj, APropList[J]);
            end;
          end;
        end;
      finally
        if Assigned(APropList) then
          FreeMem(APropList);
      end;
    end;
  end;

  procedure AddArray;
  var
    I, c: Integer;
  begin
    Clear;
    TValue.Make(ASource, AType, AValue);
    c := AValue.GetArrayLength;
    for I := 0 to c - 1 do
      Add('item', xntNode).FromRtti(AValue.GetArrayElement(I));
  end;

begin
  if ASource = nil then
    Exit;
  Clear;
  case AType.Kind of
    tkRecord:
      AddRecord;
    tkClass:
      AddObject;
    tkDynArray:
      AddArray;
  end;
end;

procedure TQXMLNode.FromRtti(AInstance: TValue);
var
  I, c: Integer;
begin
  case AInstance.Kind of
    tkClass:
      FromRtti(AInstance.AsObject, AInstance.TypeInfo);
    tkRecord:
      FromRtti(AInstance.GetReferenceToRawData, AInstance.TypeInfo);
    tkArray, tkDynArray:
      begin
        Clear;
        c := AInstance.GetArrayLength;
        for I := 0 to c - 1 do
          Add.FromRtti(AInstance.GetArrayElement(I));
      end;
    tkInteger:
      Attrs.Add('value').AsInt64 := AInstance.AsInt64;
    tkChar, tkString, tkWChar, tkLString, tkWString, tkUString:
      Attrs.Add('value').AsString := AInstance.ToString;
    tkEnumeration:
      begin
        if GetTypeData(AInstance.TypeInfo)^.BaseType^ = TypeInfo(Boolean) then
          Attrs.Add('value').AsBoolean := AInstance.AsBoolean
        else if XMLRttiEnumAsInt then
          Attrs.Add('value').AsInteger := AInstance.AsOrdinal
        else
          Attrs.Add('value').AsString := AInstance.ToString;
      end;
    tkSet:
      Attrs.Add('value').AsString := AInstance.ToString;
    tkVariant:
      Attrs.Add('value').AsVariant := AInstance.AsVariant;
    tkInt64:
      Attrs.Add('value').AsInt64 := AInstance.AsInt64;
  end;
end;
{$IFEND >=2010}

function TQXMLNode.GetAsXML: QStringW;
begin
  Result := Encode(True, '  ');
end;

function TQXMLNode.GetAttrs: TQXMLAttrs;
begin
  if not Assigned(FAttrs) then
    FAttrs := TQXMLAttrs.Create(Self);
  Result := FAttrs;
end;

function TQXMLNode.GetCapacity: Integer;
begin
  if Assigned(FItems) then
    Result := FItems.Capacity
  else
    Result := 0;
end;

function TQXMLNode.GetCount: Integer;
begin
  if Assigned(FItems) then
    Result := FItems.Count
  else
    Result := 0;
end;

function TQXMLNode.GetEnumerator: TQXMLNodeEnumerator;
begin
  Result := TQXMLNodeEnumerator.Create(Self);
end;

function TQXMLNode.GetItemIndex: Integer;
begin
  Result := -1;
  if Assigned(FParent) then
    Result := FParent.FItems.IndexOf(Self);
end;

function TQXMLNode.GetItems(AIndex: Integer): TQXMLNode;
begin
  Result := FItems[AIndex];
end;

function TQXMLNode.GetName: QStringW;
begin
  if NodeType = xntNode then
    Result := FName
  else
    SetLength(Result, 0);
end;

function TQXMLNode.GetPath: QStringW;
begin
  Result := GetRelPath(nil);
end;

function TQXMLNode.GetRelPath(AParent: TQXMLNode; APathDelimiter: QCharW)
  : QStringW;
var
  AItem, APItem: TQXMLNode;
  AItemName: QStringW;
begin
  AItem := Self;
  SetLength(Result, 0);
  while Assigned(AItem) and (AItem <> AParent) do
  begin
    APItem := AItem.Parent;
    if Assigned(APItem) then
    begin
      AItemName := AItem.Name;
      if Length(AItemName) > 0 then // 命名的元素
        Result := APathDelimiter + AItemName + Result
      else
        Result := '[' + IntToStr(AItem.ItemIndex) + ']' + Result;
    end
    else
      Result := APathDelimiter + AItem.Name + Result;
    AItem := APItem;
  end;
  if Length(Result) > 0 then
    Result := StrDupX(PQCharW(Result) + 1, Length(Result) - 1);
end;

function TQXMLNode.GetText: QStringW;
var
  ABuilder: TQStringCatHelperW;
  procedure InternalGetText(ANode: TQXMLNode);
  var
    I: Integer;
  begin
    if ANode.NodeType = xntNode then
    begin
      for I := 0 to ANode.Count - 1 do
        InternalGetText(ANode.Items[I]);
    end
    else // if ANode.NodeType<>xntComment then //注释不包含在Text中，文本或CDATA数据返回
      ABuilder.Cat(ANode.FName);
  end;

begin
  ABuilder := TQStringCatHelperW.Create;
  try
    InternalGetText(Self);
    Result := ABuilder.Value;
  finally
    ABuilder.Free;
  end;
end;

function TQXMLNode.HasChild(ANamePath: QStringW; var AChild: TQXMLNode)
  : Boolean;
begin
  AChild := ItemByPath(ANamePath);
  Result := AChild <> nil;
end;

function TQXMLNode.ItemByName(const AName: QStringW): TQXMLNode;
var
  AIndex: Integer;
begin
  AIndex := IndexOf(AName);
  if AIndex <> -1 then
    Result := Items[AIndex]
  else if (AName = 'xml') and (Parent = nil) then
    Result := Self
  else
    Result := nil;
end;

function TQXMLNode.InternalEncode(ABuilder: TQStringCatHelperW;
  ADoFormat: Boolean; const AIndent: QStringW): TQStringCatHelperW;
const
  TagStart: PWideChar = '<';
  TagEnd: PWideChar = '/>';
  TagClose: PWideChar = '>';
  TagCloseStart: PWideChar = '</';
  Space: PWideChar = ' ';
  ValueStart: PWideChar = '="';
  Quoter: PWideChar = '"';
  CommentStart: PWideChar = '<!--';
  CommentEnd: PWideChar = '-->';
  CDataStart: PWideChar = '<![CDATA[';
  CDataEnd: PWideChar = ']]>';
  TagXMLStart: PWideChar = '<xml';
  TagXMLEnd: PWideChar = '</xml>';
var
  ADefaultTag: Boolean;
  ACount: Integer;
  procedure DoEncode(AItem: TQXMLNode; ALevel: Integer);
  var
    I: Integer;
    ANode: TQXMLNode;
  begin
    if ADoFormat then
      ABuilder.Replicate(AIndent, ALevel);
    if (Length(AItem.FName) > 0) then
      ABuilder.Cat(TagStart, 1).Cat(AItem.FName)
    else if (NodeType = xntNode) and (AItem.Parent <> nil) then
      raise Exception.Create(SNodeWithoutName);
    if Assigned(AItem.FAttrs) then
    begin
      for I := 0 to AItem.FAttrs.Count - 1 do
        ABuilder.Cat(Space, 1).Cat(AItem.Attrs[I].FName).Cat(ValueStart, 2)
          .Cat(XMLEncode(AItem.Attrs[I].FValue,true,false)).Cat(Quoter);
    end;
    if AItem.Count = 0 then
    begin
      if (Length(AItem.Name) > 0) or (ADefaultTag and (AItem = Self)) then
      begin
        if XMLTagShortClose then
          ABuilder.Cat(TagEnd, 2)
        else if Length(AItem.FName) > 0 then
          ABuilder.Cat(TagClose, 1).Cat(TagCloseStart, 2).Cat(AItem.FName)
            .Cat(TagClose, 1)
        else if AItem.Parent = nil then
          ABuilder.Cat(TagCloseStart, 6);
      end;
    end
    else
    begin
      if (AItem.Parent = nil) and ADefaultTag then
      begin
        ABuilder.Cat(TagClose, 1);
        if ADoFormat then
          ABuilder.Cat(SLineBreak).Replicate(AIndent, ALevel);
      end;
      if Length(AItem.Name) > 0 then
      begin
        ABuilder.Cat(TagClose, 1);
        if (AItem.Count > 0) and (AItem[0].NodeType <> xntText) and ADoFormat
        then
          ABuilder.Cat(SLineBreak);
      end;
      for I := 0 to AItem.Count - 1 do
      begin
        ANode := AItem[I];
        case ANode.NodeType of
          xntNode:
            begin
              if Length(ANode.Name) = 0 then
                raise Exception.Create(SXMLNameNeeded);
              DoEncode(ANode, ALevel + 1);
            end;
          xntText:
            begin
              // if ADoFormat then
              // ABuilder.Replicate(AIndent, ALevel);
              ABuilder.Cat(XMLEncode(ANode.FName,false, True));
              if ADoFormat and (I < AItem.Count - 1) then
                ABuilder.Cat(SLineBreak);
            end;
          xntComment:
            begin
              if ADoFormat then
                ABuilder.Replicate(AIndent, ALevel);
              ABuilder.Cat(CommentStart, 4).Cat(ANode.FName).Cat(CommentEnd, 3);
            end;
          xntCData:
            begin
              if ADoFormat then
                ABuilder.Replicate(AIndent, ALevel);
              ABuilder.Cat(CDataStart, 9).Cat(ANode.FName).Cat(CDataEnd, 3);
            end;
        end;
        if ADoFormat and (ANode.NodeType <> xntText) then
          ABuilder.Cat(SLineBreak);
      end;
      if ADoFormat then
      begin
        if (AItem.Count > 0) then
        begin
          if AItem[AItem.Count - 1].NodeType <> xntText then
            ABuilder.Replicate(AIndent, ALevel);
        end
        else if AItem.NodeType <> xntText then
          ABuilder.Replicate(AIndent, ALevel);
      end;
      if (Length(AItem.FName) > 0) then
      begin
        ABuilder.Cat(TagCloseStart, 2).Cat(AItem.FName).Cat(TagClose, 1)
      end;
    end;
  end;
  function DefaultTagNeeded: Boolean;
  var
    I, C: Integer;
  begin
    if NodeType = xntNode then
    begin
      if Length(FName) = 0 then // 自己是结点，但没有名称
      begin
        case ACount of
          0:
            Result := Assigned(FAttrs) and (Attrs.Count > 0);
          1:
            Result := Items[0].NodeType in [xntText, xntCData]
        else
          begin
            C := 0;
            for I := 0 to Count - 1 do
            begin
              if Items[I].NodeType <> xntComment then
                Inc(C);
              if C > 1 then
                Break;
            end;
            Result := C > 1;
          end;
        end;
      end
      else
        Result := False;
    end
    else
      Result := False;
  end;

begin
  Result := ABuilder;
  ACount := Count;
  ADefaultTag := DefaultTagNeeded;
  if ADefaultTag then
  begin
    ABuilder.Cat(TagXMLStart, 4);
    DoEncode(Self, 0);
    if ((Count > 0) or (not XMLTagShortClose)) then
      // XMLTagShortClose为True并且Count=0时在InternalEncode中已处理
      ABuilder.Cat(TagXMLEnd, 6);
  end
  else
    DoEncode(Self, 0);
end;

function TQXMLNode.IsChildOf(AParent: TQXMLNode): Boolean;
begin
  if Assigned(FParent) then
  begin
    if AParent = FParent then
      Result := True
    else
      Result := FParent.IsChildOf(AParent);
  end
  else
    Result := False;
end;

function TQXMLNode.IsParentOf(AChild: TQXMLNode): Boolean;
begin
  if Assigned(AChild) then
    Result := AChild.IsChildOf(Self)
  else
    Result := False;
end;

// procedure TQXMLNode.InternalRttiFilter(ASender: TQXMLNode; AObject: Pointer;
// APropName: QStringW; APropType: PTypeInfo; var Accept: Boolean;
// ATag: Pointer);
// var
// AFilter: PQXMLInternalTagData;
// procedure DoNameFilter;
// var
// ps: PQCharW;
// begin
// if Length(AFilter.AcceptNames) > 0 then
// begin
// Accept := False;
// ps := StrIStrW(PQCharW(AFilter.AcceptNames), PQCharW(APropName));
// if (ps <> nil) and ((ps = PQCharW(AFilter.AcceptNames)) or (ps[-1] = ',') or
// (ps[-1] = ';')) then
// begin
// ps := ps + Length(APropName);
// Accept := (ps^ = ',') or (ps^ = ';') or (ps^ = #0);
// end;
// end
// else if Length(AFilter.IgnoreNames) > 0 then
// begin
// ps := StrIStrW(PQCharW(AFilter.IgnoreNames), PQCharW(APropName));
// Accept := True;
// if (ps <> nil) and ((ps = PQCharW(AFilter.IgnoreNames)) or (ps[-1] = ',') or
// (ps[-1] = ';')) then
// begin
// ps := ps + Length(APropName);
// Accept := not((ps^ = ',') or (ps^ = ';') or (ps^ = #0));
// end;
// end;
// end;
//
// begin
// AFilter := PQXMLInternalTagData(ATag);
// {$IFDEF UNICODE}
// if AFilter.TagType = ttAnonEvent then
// AFilter.OnEvent(ASender, AObject, APropName, APropType, Accept, AFilter.Tag)
// else
// {$ENDIF}
// if AFilter.TagType = ttNameFilter then
// DoNameFilter;
// end;
// {$IFDEF UNICODE}

// function TQXMLNode.Invoke(AInstance: TValue): TValue;
// begin
//
// end;
// {$ENDIF}

function TQXMLNode.ItemByName(const AName: QStringW; AList: TQXMLNodeList;
  ANest: Boolean): Integer;
var
  ANode: TQXMLNode;
  function InternalFind(AParent: TQXMLNode): Integer;
  var
    I: Integer;
  begin
    Result := 0;
    for I := 0 to AParent.Count - 1 do
    begin
      ANode := AParent.Items[I];
      if ANode.Name = AName then
      begin
        AList.Add(ANode);
        Inc(Result);
      end;
      if ANest then
        Inc(Result, InternalFind(ANode));
    end;
  end;

begin
  Result := InternalFind(Self);
end;

function TQXMLNode.ItemByPath(const APath: QStringW): TQXMLNode;
var
  AName: QStringW;
  pPath: PQCharW;
  AParent, AItem: TQXMLNode;
const
  PathDelimiters: PWideChar = '/\.';
begin
  if Length(APath) > 0 then
  begin
    pPath := PQCharW(APath);
    AParent := Self;
    AItem := nil;
    while pPath^ <> #0 do
    begin
      AName := HtmlUnescape(DecodeTokenW(pPath, PathDelimiters,
        WideChar(0), False));
      AItem := AParent.ItemByName(AName);
      if Assigned(AItem) then
        AParent := AItem
      else
        Break;
    end;
    if AParent = AItem then
      Result := AParent
    else
      Result := nil;
  end
  else
    Result := Self;
end;

function TQXMLNode.ItemByRegex(const ARegex: QStringW; AList: TQXMLNodeList;
  ANest: Boolean): Integer;
var
  ANode: TQXMLNode;
  APcre: TPerlRegex;
  function RegexStr(const S: QStringW):
{$IF RTLVersion<=24}UTF8String{$ELSE}UnicodeString{$IFEND};
  begin
{$IF RTLVersion<19}
    Result := System.UTF8Encode(S);
{$ELSE}
{$IF RTLVersion<=24}
    Result := UTF8String(S);
{$ELSE}
    Result := S;
{$IFEND}
{$IFEND}
  end;
  function InternalFind(AParent: TQXMLNode): Integer;
  var
    I: Integer;
  begin
    Result := 0;
    for I := 0 to AParent.Count - 1 do
    begin
      ANode := AParent.Items[I];
      APcre.Subject := RegexStr(ANode.Name);
      if APcre.Match then
      begin
        AList.Add(ANode);
        Inc(Result);
      end;
      if ANest then
        Inc(Result, InternalFind(ANode));
    end;
  end;

begin
  APcre := TPerlRegex.Create;
  try
    APcre.RegEx := RegexStr(ARegex);
    APcre.Compile;
    Result := InternalFind(Self);
  finally
    FreeObject(APcre);
  end;
end;

function TQXMLNode.ItemWithAttrValue(const APath, AttrName, AttrValue: QStringW)
  : TQXMLNode;
var
  ANode: TQXMLNode;
  I: Integer;
  Attr: TQXMLAttr;
  AFound: Boolean;
begin
  Result := nil;
  ANode := ItemByPath(APath);
  if Assigned(ANode) then
  begin
    I := ANode.ItemIndex;
    while I < ANode.Parent.Count do
    begin
      ANode := ANode.Parent[I];
      Attr := ANode.Attrs.ItemByName(AttrName);
      if Attr <> nil then
      begin
        if Length(Attr.Value) = Length(AttrValue) then
        begin
          if XMLCaseSensitive then
            AFound := Attr.Value = AttrValue
          else
            AFound := StartWithW(PQCharW(Attr.Value), PQCharW(AttrValue), True);
          if AFound then
          begin
            Result := ANode;
            Break;
          end;
        end;
      end;
      Inc(I);
    end;
  end;
end;

procedure TQXMLNode.LoadFromFile(AFileName: QStringW; AEncoding: TTextEncoding);
var
  AStream: TFileStream;
begin
  AStream := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyWrite);
  try
    LoadFromStream(AStream, AEncoding);
  finally
    FreeObject(AStream);
  end;
end;

procedure TQXMLNode.LoadFromStream(AStream: TStream; AEncoding: TTextEncoding);
var
  S: QStringW;
  procedure DetectXMLEncoding;
  // 快速通过xml的头部定义来判定XML文件的编码，如果未定义，则通过LoadText来判断
  var
    APos: Int64;
    S: TBytes;
    I: Integer;
  const
    UTF8Code: array [0 .. 4] of Byte = ($55, $54, $46, $2D, $38);
    // UTF8的编码串的ASCII码
    UTF16LECode: array [0 .. 11] of Byte = ($55, $00, $54, $00, $46, $00, $2D,
      $00, $31, $00, $36, $00);
    UTF16BECode: array [0 .. 11] of Byte = ($00, $55, $00, $54, $00, $46, $00,
      $2D, $00, $31, $00, $36);
  begin
    APos := AStream.Position;
    SetLength(S, 1024); // 读取前1024个字节来判定
    AStream.Read((@S[0])^, 1024);
    // BOM?
    if (S[0] = $EF) and (S[1] = $BB) and (S[2] = $BF) then
    begin
      AEncoding := teUTF8;
      AStream.Position := APos + 3;
    end
    else if (S[0] = $FF) and (S[1] = $FE) then
    begin
      AEncoding := teUnicode16LE;
      AStream.Position := APos + 2;
    end
    else if (S[0] = $FE) and (S[1] = $FF) then
    begin
      AEncoding := teUnicode16BE;
      AStream.Position := APos + 2;
    end
    else // 查找xml头部,查找UTF-8，UTF-16，UTF-16BE
    begin
      I := 0;
      AStream.Position := APos;
      while I < 1024 do
      begin
        if (S[I] = 0) and (S[I + 1] = $55) then
        begin
          if CompareMem(@S[I], @UTF16BECode[0], 12) then
          begin
            AEncoding := teUnicode16BE;
            Break;
          end;
        end
        else if S[I] = $55 then
        begin
          if CompareMem(@S[I], @UTF8Code[0], 5) then
          begin
            AEncoding := teUTF8;
            Break;
          end
          else if CompareMem(@S[I], @UTF16LECode[0], 12) then
          begin
            AEncoding := teUnicode16LE;
            Break;
          end;
        end;
        Inc(I);
      end;
    end;
  end;

begin
  if AEncoding = teUnknown then
    DetectXMLEncoding;
  S := LoadTextW(AStream, AEncoding);
  Parse(S);
end;

procedure TQXMLNode.MoveTo(ANewParent: TQXMLNode; AIndex: Integer);
begin
  if (ANewParent <> Self) then
  begin
    if FParent = ANewParent then // 已经是直属子结点了，调整顺序
      FParent.FItems.Move(ItemIndex, AIndex)
    else if ANewParent.NodeType <> xntNode then
      raise Exception.Create(SParentMustNode)
    else if IsParentOf(ANewParent) then
      raise Exception.Create(SCantMoveToChild)
    else
    begin
      if Assigned(FParent) then
        FParent.Remove(ItemIndex);
      FParent := ANewParent;
      if not Assigned(ANewParent.FItems) then
        ANewParent.FItems := TQXMLNodeList.Create;
      if AIndex >= ANewParent.Count then
        ANewParent.FItems.Add(Self)
      else if AIndex <= 0 then
        ANewParent.FItems.Insert(0, Self)
      else
        ANewParent.FItems.Insert(AIndex, Self);
      DoNodeNameChanged(Self);
    end;
  end;
end;

procedure TQXMLNode.Parse(const S: QStringW);
begin
  Parse(PQCharW(S), Length(S));
end;

procedure TQXMLNode.ParseBlock(AStream: TStream; AEncoding: TTextEncoding);
var
  AMS: TMemoryStream;
  procedure ParseUCS2;
  var
    c: QCharW;
    ATagStart, ACharSize: Integer;
    ATagName, ATag: QStringW;
    ps, p: PQCharW;
  const
    XMLTagNameEnd: PWideChar = ' '#9#10#13'/>';
  begin
    // 查找标签开始，并记录标签的名称
    repeat
      AStream.ReadBuffer(c, SizeOf(QCharW));
      AMS.WriteBuffer(c, SizeOf(QCharW));
    until c = '<';
    ATagStart := AMS.Position - 2;
    // 读取Tag名称
    repeat
      AStream.Read(c, SizeOf(QCharW));
      AMS.WriteBuffer(c, SizeOf(QCharW));
    until c = '>';
    ATag := StrDupW(PQCharW(AMS.Memory), ATagStart,
      (AMS.Position - ATagStart) shr 1);
    ps := PQCharW(ATag);
    if StartWithW(ps, '<?xml', True) then
    begin
      AMS.Size := 0;
      ParseUCS2;
    end
    else if ps[1] <> '!' then // 非注释，CDATA和DTD
    begin
      p := ps;
      while not CharInW(p, XMLTagNameEnd, @ACharSize) do
        Inc(p);
      ATagName := StrDupW(ps, 1, p - ps - 1);
      // 检查是否是短标签<xxx />
      if StartWithW(ps + Length(ATag) - 2, '/>', False) then
        DoParse(PQCharW(ATag))
      else
      begin
        // 重复直到找到</ATagName>止
        ATagStart := 0;
        ATagName := '</' + ATagName + '>';
        repeat
          AStream.ReadBuffer(c, SizeOf(QCharW));
          AMS.WriteBuffer(c, SizeOf(QCharW));
          if c = '<' then
            ATagStart := AMS.Position - 2
          else if ATagStart <> 0 then
          begin
            if AMS.Position - ATagStart = (Length(ATagName) shl 1) then
            begin
              if StartWithW(PWideChar(AMS.Memory) + (ATagStart shr 1),
                PQCharW(ATagName), False) then
              begin
                // OK,Found Close
                c := #0;
                AMS.Write(c, SizeOf(QCharW));
                DoParse(AMS.Memory);
                Exit;
              end
              else
                ATagStart := 0;
            end;
          end;
        until 1 > 2;
      end;
    end
    else // 注释，CDATA，DocType
    begin
      // DTD,忽略
      if StartWithW(ps, '<!DOCTYPE', False) or StartWithW(ps, '<!ELEMENT',
        False) or StartWithW(ps, '<!ATTLIST', False) then
      begin
        AMS.Size := 0;
        ParseUCS2;
      end
      else
        DoParse(PQCharW(ATag));
    end;
  end;

  procedure ParseUtf8;
  var
    c: QCharA;
    ATagStart, ACharSize: Integer;
    ATagName, ATag: QStringA;
    ps, p: PQCharA;
  const
    XMLTagNameEnd: array [0 .. 5] of QCharA = ($9, $A, $D, $20, $2F, $3E);
    XMLTagStart: QCharA = $3C;
    XMLTagEnd: QCharA = $3E;
    XMLTagClose: array [0 .. 1] of QCharA = ($2F, $3E); // />
    XMLDeclare: array [0 .. 4] of QCharA = ($3C, $3F, $78, $6D, $6C); // <?xml
    XMLComment: QCharA = $21;
    DTDDocType: array [0 .. 8] of QCharA = (Ord('<'), Ord('!'), Ord('D'),
      Ord('O'), Ord('C'), Ord('T'), Ord('Y'), Ord('P'), Ord('E'));
    DTDElement: array [0 .. 8] of QCharA = (Ord('<'), Ord('!'), Ord('E'),
      Ord('L'), Ord('E'), Ord('M'), Ord('E'), Ord('N'), Ord('T'));
    DTDAttrList: array [0 .. 8] of QCharA = (Ord('<'), Ord('!'), Ord('A'),
      Ord('T'), Ord('T'), Ord('L'), Ord('I'), Ord('S'), Ord('T'));
  begin
    // 查找标签开始，并记录标签的名称
    repeat
      AStream.ReadBuffer(c, SizeOf(QCharA));
      AMS.WriteBuffer(c, SizeOf(QCharA));
    until c = XMLTagStart;
    ATagStart := AMS.Position - 1;
    // 读取Tag名称
    repeat
      AStream.Read(c, SizeOf(QCharA));
      AMS.WriteBuffer(c, SizeOf(QCharA));
    until c = XMLTagEnd;
    ATag.From(PQCharA(AMS.Memory), ATagStart, (AMS.Position - ATagStart));
    ps := PQCharA(ATag);
    p := ps;
    Inc(p);
    if CompareMem(ps, @XMLDeclare[0], 5) then
    begin
      AMS.Size := 0;
      ParseUtf8;
    end
    else if p^ <> XMLComment then // 非注释，CDATA和DTD
    begin
      p := ps;
      while not CharInA(p, XMLTagNameEnd, @ACharSize) do
        Inc(p);
      ATagName.Length := IntPtr(p) - IntPtr(ps) + 2;
      ATagName[0] := XMLTagStart;
      ATagName[1] := $2F; // </
      ATagName[ATagName.Length - 1] := XMLTagEnd;
      p := PQCharA(ATagName);
      Inc(p, 2);
      Inc(ps);
      Move(ps^, p^, ATagName.Length - 3);
      // 检查是否是短标签<xxx />
      p := ps;
      Inc(p, ATag.Length - 1);
      if CompareMem(p, @XMLTagClose[0], 2) then
        DoParse(PQCharW(qstring.Utf8Decode(ATag)))
      else
      begin
        // 重复直到找到</ATagName>止
        ATagStart := 0;
        repeat
          AStream.ReadBuffer(c, SizeOf(QCharA));
          AMS.WriteBuffer(c, SizeOf(QCharA));
          if c = XMLTagStart then
            ATagStart := AMS.Position - 1
          else if ATagStart <> 0 then
          begin
            if AMS.Position - ATagStart = ATagName.Length then
            begin
              p := PQCharA(AMS.Memory);
              Inc(p, ATagStart);
              if CompareMem(p, PQCharA(ATagName), ATagName.Length) then
              begin
                // OK,Found Close
                ATag.From(AMS.Memory, 0, AMS.Size);
                DoParse(PQCharW(qstring.Utf8Decode(ATag)));
                Exit;
              end
              else
                ATagStart := 0;
            end;
          end;
        until 1 > 2;
      end;
    end
    else // 注释，CDATA，DocType
    begin
      // DTD,忽略
      if CompareMem(ps, @DTDDocType[0], 9) or CompareMem(ps, @DTDElement[0], 9)
        or CompareMem(ps, @DTDAttrList[0], 9) then
      begin
        AMS.Size := 0;
        ParseUtf8;
      end
      else
        DoParse(PQCharW(qstring.Utf8Decode(ATag)));
    end;
  end;

begin
  AMS := TMemoryStream.Create;
  try
    if AEncoding = teUTF8 then
      ParseUtf8
    else if AEncoding = teUnicode16LE then
      ParseUCS2
    else
      raise Exception.Create(SBadXMLEncoding);
  finally
    AMS.Free;
  end;
end;

procedure TQXMLNode.Remove(ANode: TQXMLNode);
begin
  if ANode.Parent = Self then
    Remove(ANode.ItemIndex);
end;

procedure TQXMLNode.Reset(ADetach: Boolean);
begin
  if Assigned(FParent) and ADetach then
  begin
    FParent.Remove(Self);
    FParent := nil;
  end;
  if Assigned(FAttrs) then
    FAttrs.Clear;
  if Assigned(FItems) then
    Clear;
  FNodeType := xntNode;
  FName := '';
  FNameHash := 0;
  FData := nil;
end;

function TQXMLNode.Remove(AIndex: Integer): TQXMLNode;
begin
  if Assigned(FItems) then
  begin
    Result := Items[AIndex];
    FItems.Delete(AIndex);
    Result.FParent := nil;
  end
  else
    Result := nil;
end;

procedure TQXMLNode.Parse(p: PQCharW; len: Integer);
  procedure ParseCopy;
  var
    S: QStringW;
  begin
    S := StrDupX(p, len);
    p := PQCharW(S);
    DoParse(p);
  end;

begin
  Clear;
  if (len > 0) and (p[len] <> #0) then
    ParseCopy
  else
  begin
    DoParse(p);
  end;
end;

procedure TQXMLNode.SaveToFile(AFileName: QStringW; AEncoding: TTextEncoding;
  AWriteBom, AWriteHeader, AFormat: Boolean);
var
  AStream: TMemoryStream;
begin
  AStream := TMemoryStream.Create;
  try
    SaveToStream(AStream, AEncoding, AWriteBom, AWriteHeader, AFormat);
    AStream.SaveToFile(AFileName);
  finally
    FreeObject(AStream);
  end;
end;

procedure TQXMLNode.SaveToFile(AFileName: QStringW; AEncoding: String;
  AWriteBom, AWriteHeader, AFormat: Boolean);
var
  AStream: TMemoryStream;
begin
  AStream := TMemoryStream.Create;
  try
    SaveToStream(AStream, AEncoding, AWriteBom, AWriteHeader, AFormat);
    AStream.SaveToFile(AFileName);
  finally
    FreeObject(AStream);
  end;
end;

procedure TQXMLNode.SaveToStream(AStream: TStream; AEncoding: String;
  AWriteBom, AWriteHeader, AFormat: Boolean);
var
  ABuilder: TQStringCatHelperW;
const
  XMLHeader: PQCharW = '<?xml version="1.0" encoding="';
  UTF8Format: PQCharW = 'UTF-8"?>';
  UTF16Format: PQCharW = 'UTF-16"?>';
begin
  ABuilder := TQStringCatHelperW.Create;
  try
    if AWriteHeader then
      ABuilder.Cat(XMLHeader, 30);
    if AEncoding = 'UTF-8' then
    begin
      if AWriteHeader then
        ABuilder.Cat(UTF8Format, 8).Cat(SLineBreak);
      InternalEncode(ABuilder, AFormat, ' ');
      SaveTextU(AStream, qstring.UTF8Encode(ABuilder.Value), AWriteBom)
    end
    else if AEncoding = 'UTF-16' then
    begin
      if AWriteHeader then
        ABuilder.Cat(UTF16Format, 9).Cat(SLineBreak);
      InternalEncode(ABuilder, AFormat, ' ');
      SaveTextW(AStream, ABuilder.Value, AWriteBom)
    end
    else
    begin
      if AWriteHeader then
        ABuilder.Cat(AEncoding).Cat('"?>').Cat(SLineBreak);
      InternalEncode(ABuilder, AFormat, ' ');
      SaveTextA(AStream, ABuilder.Value);
    end;
  finally
    FreeObject(ABuilder);
  end;
end;

procedure TQXMLNode.SaveToStream(AStream: TStream; AEncoding: TTextEncoding;
  AWriteBom, AWriteHeader, AFormat: Boolean);
begin
  case AEncoding of
    teUnicode16LE:
      SaveToStream(AStream, 'UTF-16', AWriteBom, AWriteHeader, AFormat);
    teUTF8:
      SaveToStream(AStream, 'UTF-8', AWriteBom, AWriteHeader, AFormat)
  else
    raise QException.Create(SBadXMLEncoding);
  end;
end;

procedure TQXMLNode.SetAsXML(const Value: QStringW);
begin
  Clear;
  Parse(Value);
end;

procedure TQXMLNode.SetCapacity(const Value: Integer);
begin
  if not Assigned(FItems) then
    FItems := TQXMLNodeList.Create;
  FItems.Capacity := Value;
end;

procedure TQXMLNode.SetName(const Value: QStringW);
  procedure ValidName;
  begin
    if not ValidXMLName(Value) then
      raise Exception.Create(SBadXMLName);
  end;

begin
  if FName <> Value then
  begin
    if NodeType = xntNode then
    begin
      ValidName;
      FName := Value;
      FNameHash := 0;
      DoNodeNameChanged(Self);
    end
    else
      raise Exception.Create(SXMLNameNotSupport);
  end;
end;

procedure TQXMLNode.SetNodeType(const Value: TQXMLNodeType);
var
  S: QStringW;
begin
  if FNodeType <> Value then
  begin
    if FNodeType = xntNode then
    begin
      S := Text; // Node转换为其它类型时,文本内容被保留，但属性和子结点的信息将丢失
      if Value = xntComment then
      begin
        if not ValidXMLComment(S) then
          raise Exception.Create(SBadXMLComment);
      end
      else if Value = xntCData then
      begin
        if not ValidXMLCData(S) then
          raise Exception.Create(SBadXMLCData);
      end;
      Clear;
      FName := S;
    end
    else if Value = xntNode then
      SetLength(FName, 0)
    else
    begin
      if Value = xntComment then
      begin
        if not ValidXMLComment(FName) then
          raise Exception.Create(SBadXMLComment);
      end
      else if Value = xntCData then
      begin
        if not ValidXMLCData(FName) then
          raise Exception.Create(SBadXMLCData);
      end;
    end;
    FNodeType := Value;
  end;
end;

procedure TQXMLNode.SetText(const Value: QStringW);
var
  AChild: TQXMLNode;
begin
  if NodeType = xntNode then
  begin
    // 为用户提供习惯性兼容
    while Count > 1 do
      Delete(Count - 1);
    if Count = 0 then
      AddText(Value)
    else
    begin
      AChild := Items[0];
      AChild.NodeType := xntText;
      AChild.FName := Value;
    end;
  end
  else if NodeType = xntComment then
  begin
    if not ValidXMLComment(Value) then
      raise Exception.Create(SBadXMLComment);
    FName := Value;
  end
  else if NodeType = xntCData then
  begin
    if not ValidXMLCData(Value) then
      raise Exception.Create(SBadXMLCData);
    FName := Value;
  end
  else // Text没有任何限制，保存时会进行必要的转码
    FName := Value;
end;

function TQXMLNode.TextByPath(const APath, ADefVal: QStringW): QStringW;
var
  ANode: TQXMLNode;
begin
  ANode := ItemByPath(APath);
  if Assigned(ANode) then
    Result := ANode.Text
  else
    Result := ADefVal;
end;

function TQXMLNode.ToString: string;
begin
  Result := Text;
end;
{$IF RTLVersion>=21}

procedure TQXMLNode.ToRecord<T>(var ARecord: T; AClearCollections: Boolean);
begin
  ToRtti(@ARecord, TypeInfo(T), AClearCollections);
end;

procedure TQXMLNode.ToRtti(AInstance: TValue; AClearCollections: Boolean);
begin
  if AInstance.IsEmpty then
    Exit;
  if AInstance.Kind = tkRecord then
    ToRtti(AInstance.GetReferenceToRawData, AInstance.TypeInfo,
      AClearCollections)
  else if AInstance.Kind = tkClass then
    ToRtti(AInstance.AsObject, AInstance.TypeInfo, AClearCollections)
end;

procedure TQXMLNode.ToRtti(ADest: Pointer; AType: PTypeInfo;
  AClearCollections: Boolean);
  procedure LoadCollection(AParent: TQXMLNode; ACollection: TCollection);
  var
    I: Integer;
  begin
    if AClearCollections then
      ACollection.Clear;
    for I := 0 to AParent.Count - 1 do
      AParent[I].ToRtti(ACollection.Add);
  end;
  function NodeToVariant(ANode: TQXMLNode): Variant;
  var
    I: Integer;
    AType: Word;
  begin
    if ANode.Count > 0 then
    begin
      Result := VarArrayCreate([0, ANode.Count - 1], varVariant);
      for I := 0 to ANode.Count - 1 do
        Result[I] := NodeToVariant(ANode[I]);
    end
    else
    begin
      AType := ANode.Attrs.IntByName('type', varVariant);
      if AType = varDate then
        Result := ANode.Attrs.DateTimeByName('value', 0)
      else
        Result := VarAsType(ANode.Attrs.ValueByName('value'), AType);
    end;
  end;
  procedure ToRecord;
  var
    AContext: TRttiContext;
    AFields: TArray<TRttiField>;
    ARttiType: TRttiType;
    ABaseAddr: Pointer;
    J: Integer;
    AChild: TQXMLNode;
    Attr: TQXMLAttr;
    AObj: TObject;
    fVal: Double;
    iVal: Integer;
  begin
    AContext := TRttiContext.Create;
    ARttiType := AContext.GetType(AType);
    ABaseAddr := ADest;
    AFields := ARttiType.GetFields;
    for J := Low(AFields) to High(AFields) do
    begin
      if (AFields[J].FieldType <> nil) then
      begin
        AChild := ItemByName(AFields[J].Name);
        Attr := Attrs.ItemByName(AFields[J].Name);
        case AFields[J].FieldType.TypeKind of
          tkInteger:
            if Assigned(Attr) then // Simple type store in attribute
              AFields[J].SetValue(ABaseAddr, Attr.AsInteger);
{$IFNDEF NEXTGEN}
          tkString:
            if Assigned(Attr) then
              PShortString(IntPtr(ABaseAddr) + AFields[J].Offset)^ :=
                ShortString(Attr.AsString);
{$ENDIF !NEXTGEN}
          tkUString{$IFNDEF NEXTGEN}, tkLString, tkWString{$ENDIF !NEXTGEN}:
            if Assigned(Attr) then
              AFields[J].SetValue(ABaseAddr, Attr.AsString);
          tkEnumeration:
            begin
              if Assigned(Attr) then
              begin
                if GetTypeData(AFields[J].FieldType.Handle)
                  ^.BaseType^ = TypeInfo(Boolean) then
                  AFields[J].SetValue(ABaseAddr, Attr.AsBoolean)
                else
                begin
                  case GetTypeData(AFields[J].FieldType.Handle).OrdType of
                    otSByte:
                      begin
                        if TryStrToInt(Attr.AsString, iVal) then
                          PShortint(IntPtr(ABaseAddr) + AFields[J]
                            .Offset)^ := iVal
                        else
                          PShortint(IntPtr(ABaseAddr) + AFields[J].Offset)^ :=
                            GetEnumValue(AFields[J].FieldType.Handle,
                            Attr.AsString);
                      end;
                    otUByte:
                      begin
                        if TryStrToInt(Attr.AsString, iVal) then
                          PByte(IntPtr(ABaseAddr) + AFields[J].Offset)^ := iVal
                        else
                          PByte(IntPtr(ABaseAddr) + AFields[J].Offset)^ :=
                            GetEnumValue(AFields[J].FieldType.Handle,
                            Attr.AsString);
                      end;
                    otSWord:
                      begin
                        if TryStrToInt(Attr.AsString, iVal) then
                          PSmallint(IntPtr(ABaseAddr) + AFields[J]
                            .Offset)^ := iVal
                        else
                          PSmallint(IntPtr(ABaseAddr) + AFields[J].Offset)^ :=
                            GetEnumValue(AFields[J].FieldType.Handle,
                            Attr.AsString);
                      end;
                    otUWord:
                      begin
                        if TryStrToInt(Attr.AsString, iVal) then
                          PWord(IntPtr(ABaseAddr) + AFields[J].Offset)^ := iVal
                        else
                          PWord(IntPtr(ABaseAddr) + AFields[J].Offset)^ :=
                            GetEnumValue(AFields[J].FieldType.Handle,
                            Attr.AsString);
                      end;
                    otSLong:
                      begin
                        if TryStrToInt(Attr.AsString, iVal) then
                          PInteger(IntPtr(ABaseAddr) + AFields[J]
                            .Offset)^ := iVal
                        else
                          PInteger(IntPtr(ABaseAddr) + AFields[J].Offset)^ :=
                            GetEnumValue(AFields[J].FieldType.Handle,
                            Attr.AsString);
                      end;
                    otULong:
                      begin
                        if TryStrToInt(Attr.AsString, iVal) then
                          PCardinal(IntPtr(ABaseAddr) + AFields[J]
                            .Offset)^ := iVal
                        else
                          PCardinal(IntPtr(ABaseAddr) + AFields[J].Offset)^ :=
                            GetEnumValue(AFields[J].FieldType.Handle,
                            Attr.AsString);
                      end;
                  end;
                end;
              end;
            end;
          tkSet:
            begin
              if Assigned(Attr) then
              begin
                case GetTypeData(AFields[J].FieldType.Handle).OrdType of
                  otSByte:
                    begin
                      if TryStrToInt(Attr.AsString, iVal) then
                        PShortint(IntPtr(ABaseAddr) + AFields[J]
                          .Offset)^ := iVal
                      else
                        PShortint(IntPtr(ABaseAddr) + AFields[J].Offset)^ :=
                          StringToSet(AFields[J].FieldType.Handle,
                          Attr.AsString);
                    end;
                  otUByte:
                    begin
                      if TryStrToInt(Attr.AsString, iVal) then
                        PByte(IntPtr(ABaseAddr) + AFields[J].Offset)^ := iVal
                      else
                        PByte(IntPtr(ABaseAddr) + AFields[J].Offset)^ :=
                          StringToSet(AFields[J].FieldType.Handle,
                          Attr.AsString);
                    end;
                  otSWord:
                    begin
                      if TryStrToInt(Attr.AsString, iVal) then
                        PSmallint(IntPtr(ABaseAddr) + AFields[J]
                          .Offset)^ := iVal
                      else
                        PSmallint(IntPtr(ABaseAddr) + AFields[J].Offset)^ :=
                          StringToSet(AFields[J].FieldType.Handle,
                          Attr.AsString);
                    end;
                  otUWord:
                    begin
                      if TryStrToInt(Attr.AsString, iVal) then
                        PWord(IntPtr(ABaseAddr) + AFields[J].Offset)^ := iVal
                      else
                        PWord(IntPtr(ABaseAddr) + AFields[J].Offset)^ :=
                          StringToSet(AFields[J].FieldType.Handle,
                          Attr.AsString);
                    end;
                  otSLong:
                    begin
                      if TryStrToInt(Attr.AsString, iVal) then
                        PInteger(IntPtr(ABaseAddr) + AFields[J].Offset)^ := iVal
                      else
                        PInteger(IntPtr(ABaseAddr) + AFields[J].Offset)^ :=
                          StringToSet(AFields[J].FieldType.Handle,
                          Attr.AsString);
                    end;
                  otULong:
                    begin
                      if TryStrToInt(Attr.AsString, iVal) then
                        PCardinal(IntPtr(ABaseAddr) + AFields[J]
                          .Offset)^ := iVal
                      else
                        PCardinal(IntPtr(ABaseAddr) + AFields[J].Offset)^ :=
                          StringToSet(AFields[J].FieldType.Handle,
                          Attr.AsString);
                    end;
                end;
              end;
            end;
          tkChar, tkWChar:
            if Assigned(Attr) then
              AFields[J].SetValue(ABaseAddr, Attr.AsString);
          tkFloat:
            if Assigned(Attr) then
            begin
              if (AFields[J].FieldType.Handle = TypeInfo(TDateTime)) or
                (AFields[J].FieldType.Handle = TypeInfo(TTime)) or
                (AFields[J].FieldType.Handle = TypeInfo(TDate)) then
              begin
                if Length(Attr.AsString) > 0 then
                  AFields[J].SetValue(ABaseAddr, Attr.AsDateTime)
                else
                  AFields[J].SetValue(ABaseAddr, 0);
              end
              else
                AFields[J].SetValue(ABaseAddr, Attr.AsFloat);
            end;
          tkInt64:
            if Assigned(Attr) then
              AFields[J].SetValue(ABaseAddr, Attr.AsInt64);
          tkVariant:
            if Assigned(Attr) then
              PVariant(IntPtr(ABaseAddr) + AFields[J].Offset)^ := Attr.AsVariant
            else
              PVariant(IntPtr(ABaseAddr) + AFields[J].Offset)^ :=
                NodeToVariant(AChild);
          tkArray, tkDynArray:
            AChild.ToRtti(Pointer(IntPtr(ABaseAddr) + AFields[J].Offset),
              AFields[J].FieldType.Handle);
          tkClass:
            begin
              AObj := AFields[J].GetValue(ABaseAddr).AsObject;
              if AObj is TStrings then
              begin
                if Assigned(AChild) then
                  (AObj as TStrings).Text := AChild.Text
                else
                  (AObj as TStrings).Text := Attr.AsString;
              end
              else if Assigned(AChild) then
              begin
                if AObj is TCollection then
                  LoadCollection(AChild, AObj as TCollection)
                else
                  AChild.ToRtti(AObj);
              end;
            end;
          tkRecord:
            if AFields[J].FieldType.Handle = TypeInfo(TGuid) then
              PGuid(IntPtr(ABaseAddr) + AFields[J].Offset)^ :=
                StringToGuid(Attr.AsString)
            else
              AChild.ToRtti(Pointer(IntPtr(ABaseAddr) + AFields[J].Offset),
                AFields[J].FieldType.Handle);
        end;
      end;
    end;
  end;

  procedure ToObject;
  var
    AProp: PPropInfo;
    ACount: Integer;
    J, iVal: Integer;
    dVal: Double;
    AObj, AChildObj: TObject;
    AChild: TQXMLNode;
    Attr: TQXMLAttr;
  begin
    AObj := ADest;
    ACount := Count;
    if AObj is TStrings then
      (AObj as TStrings).Text := Text
    else if AObj is TCollection then
      LoadCollection(Self, AObj as TCollection)
    else
    begin
      for J := 0 to Attrs.Count - 1 do
      begin
        Attr := Attrs[J];
        AProp := GetPropInfo(AObj, Attr.Name);
        if (AProp <> nil) and Assigned(AProp.SetProc) then
        begin
          case AProp.PropType^.Kind of
            tkInteger:
              SetOrdProp(AObj, AProp, Attr.AsInteger);
            tkFloat:
              begin
                if (AProp.PropType^ = TypeInfo(TDateTime)) or
                  (AProp.PropType^ = TypeInfo(TTime)) or
                  (AProp.PropType^ = TypeInfo(TDate)) then
                  SetFloatProp(AObj, AProp, Attr.AsDateTime)
                else
                  SetFloatProp(AObj, AProp, Attr.AsFloat);
              end;
            tkChar, tkString, tkWChar, tkLString, tkWString, tkUString:
              SetStrProp(AObj, AProp, Attr.AsString);
            tkEnumeration:
              begin
                if GetTypeData(AProp.PropType^)^.BaseType^ = TypeInfo(Boolean)
                then
                  SetOrdProp(AObj, AProp, Integer(Attr.AsBoolean))
                else if TryStrToInt(Attr.AsString, iVal) then
                  SetOrdProp(AObj, AProp, iVal)
                else
                  SetEnumProp(AObj, AProp, Attr.AsString);
              end;
            tkSet:
              begin
                if TryStrToInt(Attr.AsString, iVal) then
                  SetOrdProp(AObj, AProp, iVal)
                else
                  SetSetProp(AObj, AProp, Attr.AsString);
              end;
            tkVariant:
              SetVariantProp(AObj, AProp, Attr.AsVariant);
            tkInt64:
              SetInt64Prop(AObj, AProp, Attr.AsInt64);
          end;
        end;
      end;
      for J := 0 to ACount - 1 do
      begin
        AChild := Items[J];
        AProp := GetPropInfo(AObj, AChild.Name);
        if (AProp <> nil) and Assigned(AProp.SetProc) then
        begin
          case AProp.PropType^.Kind of
            tkClass:
              begin
                AChildObj := Pointer(GetOrdProp(AObj, AProp));
                if AChildObj is TStrings then
                  (AChildObj as TStrings).Text := AChild.Text
                else if AChildObj is TCollection then
                  LoadCollection(AChild, AChildObj as TCollection)
                else
                  AChild.ToRtti(AChildObj);
              end;
            tkRecord, tkArray, tkDynArray:
              // tkArray,tkDynArray类型的属性没见过,tkRecord存疑
              begin
                AChild.ToRtti(Pointer(GetOrdProp(AObj, AProp)),
                  AProp.PropType^);
              end;
          end;
        end;
      end;
    end;
  end;

  procedure SetDynArrayLen(arr: Pointer; AType: PTypeInfo; ALen: NativeInt);
  var
    pmem: Pointer;
  begin
    pmem := PPointer(arr)^;
    DynArraySetLength(pmem, AType, 1, @ALen);
    PPointer(arr)^ := pmem;
  end;

  function ArrayItemTypeName(ATypeName: QStringW): QStringW;
  var
    p, ps: PQCharW;
    ACount: Integer;
  begin
    p := PQCharW(ATypeName);
    if StartWithW(p, 'TArray<', True) then
    begin
      Inc(p, 7);
      ps := p;
      ACount := 1;
      while ACount > 0 do
      begin
        if p^ = '>' then
          Dec(ACount)
        else if p^ = '<' then
          Inc(ACount);
        Inc(p);
      end;
      Result := StrDupX(ps, p - ps - 1);
    end
    else
      Result := '';
  end;

  procedure ToArray;
  var
    AContext: TRttiContext;
    ASubType: TRttiType;
    I, l, AOffset, iVal: Integer;
    dVal: Double;
    S: QStringW;
    pd, pi: PByte;
    AChildObj: TObject;
    ASubTypeInfo: PTypeInfo;
    AChild: TQXMLNode;
    Attr: TQXMLAttr;
  begin
    AContext := TRttiContext.Create;
{$IF RTLVersion>25}
    S := ArrayItemTypeName(AType.NameFld.ToString);
{$ELSE}
    S := ArrayItemTypeName(String(AType.Name));
{$IFEND}
    if Length(S) > 0 then
      ASubType := AContext.FindType(S)
    else
      ASubType := nil;
    if ASubType <> nil then
    begin
      ASubTypeInfo := ASubType.Handle;
      l := Count;
      SetDynArrayLen(ADest, AType, l);
      pd := PPointer(ADest)^;
      for I := 0 to l - 1 do
      begin
        AOffset := I * GetTypeData(AType).elSize;
        pi := Pointer(IntPtr(pd) + AOffset);
        AChild := Items[I];
        Attr := AChild.Attrs.ItemByName('value');
        case ASubType.TypeKind of
          tkInteger:
            begin
              if Assigned(Attr) then
              begin
                case GetTypeData(ASubTypeInfo).OrdType of
                  otSByte:
                    PShortint(pi)^ := Attr.AsInteger;
                  otUByte:
                    pi^ := Attr.AsInteger;
                  otSWord:
                    PSmallint(pi)^ := Attr.AsInteger;
                  otUWord:
                    PWord(pi)^ := Attr.AsInteger;
                  otSLong:
                    PInteger(pi)^ := Attr.AsInteger;
                  otULong:
                    PCardinal(pi)^ := Attr.AsInteger;
                end;
              end;
            end;
{$IFNDEF NEXTGEN}
          tkChar:
            if Assigned(Attr) then
              pi^ := Ord(PAnsiChar(AnsiString(Attr.AsString))[0]);
{$ENDIF !NEXTGEN}
          tkEnumeration:
            begin
              if Assigned(Attr) then
              begin
                if GetTypeData(ASubTypeInfo)^.BaseType^ = TypeInfo(Boolean) then
                  PBoolean(pi)^ := Attr.AsBoolean
                else
                begin
                  case GetTypeData(ASubTypeInfo)^.OrdType of
                    otSByte:
                      begin
                        if TryStrToInt(Attr.AsString, iVal) then
                          PShortint(pi)^ := iVal
                        else
                          PShortint(pi)^ := GetEnumValue(ASubTypeInfo,
                            Attr.AsString);
                      end;
                    otUByte:
                      begin
                        if TryStrToInt(Attr.AsString, iVal) then
                          pi^ := iVal
                        else
                          pi^ := GetEnumValue(ASubTypeInfo, Attr.AsString);
                      end;
                    otSWord:
                      begin
                        if TryStrToInt(Attr.AsString, iVal) then
                          PSmallint(pi)^ := iVal
                        else
                          PSmallint(pi)^ := GetEnumValue(ASubTypeInfo,
                            Attr.AsString);
                      end;
                    otUWord:
                      begin
                        if TryStrToInt(Attr.AsString, iVal) then
                          PWord(pi)^ := iVal
                        else
                          PWord(pi)^ := GetEnumValue(ASubTypeInfo,
                            Attr.AsString);
                      end;
                    otSLong:
                      begin
                        if TryStrToInt(Attr.AsString, iVal) then
                          PInteger(pi)^ := iVal
                        else
                          PInteger(pi)^ := GetEnumValue(ASubTypeInfo,
                            Attr.AsString);
                      end;
                    otULong:
                      begin
                        if TryStrToInt(Attr.AsString, iVal) then
                          PCardinal(pi)^ := iVal
                        else
                          PCardinal(pi)^ := GetEnumValue(ASubTypeInfo,
                            Attr.AsString);
                      end;
                  end;
                end;
              end;
            end;
          tkFloat:
            if Assigned(Attr) then
            begin
              case GetTypeData(ASubTypeInfo)^.FloatType of
                ftSingle:
                  PSingle(pi)^ := Attr.AsFloat;
                ftDouble:
                  PDouble(pi)^ := Attr.AsFloat;
                ftExtended:
                  PExtended(pi)^ := Attr.AsFloat;
                ftComp:
                  PComp(pi)^ := Attr.AsFloat;
                ftCurr:
                  PCurrency(pi)^ := Attr.AsFloat;
              end;
            end;
{$IFNDEF NEXTGEN}
          tkString:
            if Assigned(Attr) then
              PShortString(pi)^ := ShortString(Attr.AsString);
{$ENDIF !NEXTGEN}
          tkSet:
            begin
              if Assigned(Attr) then
              begin
                case GetTypeData(ASubTypeInfo)^.OrdType of
                  otSByte:
                    begin
                      if TryStrToInt(Attr.AsString, iVal) then
                        PShortint(pi)^ := iVal
                      else
                        PShortint(pi)^ := StringToSet(ASubTypeInfo,
                          Attr.AsString);
                    end;
                  otUByte:
                    begin
                      if TryStrToInt(Attr.AsString, iVal) then
                        pi^ := iVal
                      else
                        pi^ := StringToSet(ASubTypeInfo, Attr.AsString);
                    end;
                  otSWord:
                    begin
                      if TryStrToInt(Attr.AsString, iVal) then
                        PSmallint(pi)^ := iVal
                      else
                        PSmallint(pi)^ := StringToSet(ASubTypeInfo,
                          Attr.AsString);
                    end;
                  otUWord:
                    begin
                      if TryStrToInt(Attr.AsString, iVal) then
                        PWord(pi)^ := iVal
                      else
                        PWord(pi)^ := StringToSet(ASubTypeInfo, Attr.AsString);
                    end;
                  otSLong:
                    begin
                      if TryStrToInt(Attr.AsString, iVal) then
                        PInteger(pi)^ := iVal
                      else
                        PInteger(pi)^ := StringToSet(ASubTypeInfo,
                          Attr.AsString);
                    end;
                  otULong:
                    begin
                      if TryStrToInt(Attr.AsString, iVal) then
                        PCardinal(pi)^ := iVal
                      else
                        PCardinal(pi)^ := StringToSet(ASubTypeInfo,
                          Attr.AsString);
                    end;
                end;
              end;
            end;
          tkClass:
            begin
              if PPointer(pi)^ <> nil then
              begin
                AChildObj := PPointer(pi)^;
                if AChildObj is TStrings then
                begin
                  if Assigned(Attr) then
                    (AChildObj as TStrings).Text := Attr.AsString
                  else
                    (AChildObj as TStrings).Text := AChild.Text;
                end
                else if AChildObj is TCollection then
                  LoadCollection(AChild, AChildObj as TCollection)
                else
                  AChild.ToRtti(AChildObj);
              end;
            end;
          tkWChar:
            if Assigned(Attr) then
              PWideChar(pi)^ := PWideChar(Attr.AsString)[0];
{$IFNDEF NEXTGEN}
          tkLString:
            if Assigned(Attr) then
              PAnsiString(pi)^ := AnsiString(Attr.AsString);
          tkWString:
            if Assigned(Attr) then
              PWideString(pi)^ := Attr.AsString;
{$ENDIF}
          tkVariant:
            if Assigned(Attr) then
              PVariant(pi)^ := Attr.AsVariant
            else
              PVariant(pi)^ := NodeToVariant(AChild);
          tkArray, tkDynArray:
            if Assigned(AChild) then

              AChild.ToRtti(pi, ASubTypeInfo);
          tkRecord:
            if Assigned(AChild) then
              AChild.ToRtti(pi, ASubTypeInfo);
          tkInt64:
            if Assigned(Attr) then
              PInt64(pi)^ := Attr.AsInt64;
          tkUString:
            if Assigned(Attr) then
              PUnicodeString(pi)^ := Attr.AsString;
        end;
      end;
    end
    else
      raise Exception.CreateFmt(SMissRttiTypeDefine, [AType.Name]);
  end;

  function GetFixedArrayItemType: PTypeInfo;
  var
    pType: PPTypeInfo;
  begin
    pType := GetTypeData(AType)^.ArrayData.elType;
    if pType = nil then
      Result := nil
    else
      Result := pType^;
  end;

  procedure ToFixedArray;
  var
    I, c, iVal, ASize: Integer;
    ASubTypeInfo: PTypeInfo;
    AChild: TQXMLNode;
    AChildObj: TObject;
    pi: PByte;
    Attr: TQXMLAttr;
  begin
    c := Min(GetTypeData(AType).ArrayData.ElCount, Count);
    ASubTypeInfo := GetFixedArrayItemType;
    if ASubTypeInfo = nil then
      Exit;
    ASize := GetTypeData(ASubTypeInfo).elSize;
    for I := 0 to c - 1 do
    begin
      pi := Pointer(IntPtr(ADest) + ASize * I);
      AChild := Items[I];
      Attr := AChild.Attrs.ItemByName('value');
      case ASubTypeInfo.Kind of
        tkInteger:
          begin
            if Assigned(Attr) then
            begin
              case GetTypeData(ASubTypeInfo).OrdType of
                otSByte:
                  PShortint(pi)^ := Attr.AsInteger;
                otUByte:
                  pi^ := Attr.AsInteger;
                otSWord:
                  PSmallint(pi)^ := Attr.AsInteger;
                otUWord:
                  PWord(pi)^ := Attr.AsInteger;
                otSLong:
                  PInteger(pi)^ := Attr.AsInteger;
                otULong:
                  PCardinal(pi)^ := Attr.AsInteger;
              end;
            end;
          end;
{$IFNDEF NEXTGEN}
        tkChar:
          if Assigned(Attr) then
            pi^ := Ord(PAnsiChar(AnsiString(Attr.AsString))[0]);
{$ENDIF !NEXTGEN}
        tkEnumeration:
          begin
            if Assigned(Attr) then
            begin
              if GetTypeData(ASubTypeInfo)^.BaseType^ = TypeInfo(Boolean) then
                PBoolean(pi)^ := Attr.AsBoolean
              else
              begin
                case GetTypeData(ASubTypeInfo)^.OrdType of
                  otSByte:
                    begin
                      if TryStrToInt(Attr.AsString, iVal) then
                        PShortint(pi)^ := iVal
                      else
                        PShortint(pi)^ := GetEnumValue(ASubTypeInfo,
                          Attr.AsString);
                    end;
                  otUByte:
                    begin
                      if TryStrToInt(Attr.AsString, iVal) then
                        pi^ := iVal
                      else
                        pi^ := GetEnumValue(ASubTypeInfo, Attr.AsString);
                    end;
                  otSWord:
                    begin
                      if TryStrToInt(Attr.AsString, iVal) then
                        PSmallint(pi)^ := iVal
                      else
                        PSmallint(pi)^ := GetEnumValue(ASubTypeInfo,
                          Attr.AsString);
                    end;
                  otUWord:
                    begin
                      if TryStrToInt(Attr.AsString, iVal) then
                        PWord(pi)^ := iVal
                      else
                        PWord(pi)^ := GetEnumValue(ASubTypeInfo, Attr.AsString);
                    end;
                  otSLong:
                    begin
                      if TryStrToInt(Attr.AsString, iVal) then
                        PInteger(pi)^ := iVal
                      else
                        PInteger(pi)^ := GetEnumValue(ASubTypeInfo,
                          Attr.AsString);
                    end;
                  otULong:
                    begin
                      if TryStrToInt(Attr.AsString, iVal) then
                        PCardinal(pi)^ := iVal
                      else
                        PCardinal(pi)^ := GetEnumValue(ASubTypeInfo,
                          Attr.AsString);
                    end;
                end;
              end;
            end;
          end;
        tkFloat:
          if Assigned(Attr) then
          begin
            case GetTypeData(ASubTypeInfo)^.FloatType of
              ftSingle:
                PSingle(pi)^ := Attr.AsFloat;
              ftDouble:
                PDouble(pi)^ := Attr.AsFloat;
              ftExtended:
                PExtended(pi)^ := Attr.AsFloat;
              ftComp:
                PComp(pi)^ := Attr.AsFloat;
              ftCurr:
                PCurrency(pi)^ := Attr.AsFloat;
            end;
          end;
{$IFNDEF NEXTGEN}
        tkString:
          if Assigned(Attr) then
            PShortString(pi)^ := ShortString(Attr.AsString);
{$ENDIF !NEXTGEN}
        tkSet:
          begin
            if Assigned(Attr) then
            begin
              case GetTypeData(ASubTypeInfo)^.OrdType of
                otSByte:
                  begin
                    if TryStrToInt(Attr.AsString, iVal) then
                      PShortint(pi)^ := iVal
                    else
                      PShortint(pi)^ := StringToSet(ASubTypeInfo,
                        Attr.AsString);
                  end;
                otUByte:
                  begin
                    if TryStrToInt(Attr.AsString, iVal) then
                      pi^ := iVal
                    else
                      pi^ := StringToSet(ASubTypeInfo, Attr.AsString);
                  end;
                otSWord:
                  begin
                    if TryStrToInt(Attr.AsString, iVal) then
                      PSmallint(pi)^ := iVal
                    else
                      PSmallint(pi)^ := StringToSet(ASubTypeInfo,
                        Attr.AsString);
                  end;
                otUWord:
                  begin
                    if TryStrToInt(Attr.AsString, iVal) then
                      PWord(pi)^ := iVal
                    else
                      PWord(pi)^ := StringToSet(ASubTypeInfo, Attr.AsString);
                  end;
                otSLong:
                  begin
                    if TryStrToInt(Attr.AsString, iVal) then
                      PInteger(pi)^ := iVal
                    else
                      PInteger(pi)^ := StringToSet(ASubTypeInfo, Attr.AsString);
                  end;
                otULong:
                  begin
                    if TryStrToInt(Attr.AsString, iVal) then
                      PCardinal(pi)^ := iVal
                    else
                      PCardinal(pi)^ := StringToSet(ASubTypeInfo,
                        Attr.AsString);
                  end;
              end;
            end;
          end;
        tkClass:
          begin
            if PPointer(pi)^ <> nil then
            begin
              AChildObj := PPointer(pi)^;
              if AChildObj is TStrings then
              begin
                if Assigned(Attr) then
                  (AChildObj as TStrings).Text := Attr.AsString
                else
                  (AChildObj as TStrings).Text := AChild.Text;
              end
              else if AChildObj is TCollection then
                LoadCollection(AChild, AChildObj as TCollection)
              else
                AChild.ToRtti(AChildObj);
            end;
          end;
        tkWChar:
          if Assigned(Attr) then
            PWideChar(pi)^ := PWideChar(Attr.AsString)[0];
{$IFNDEF NEXTGEN}
        tkLString:
          if Assigned(Attr) then
            PAnsiString(pi)^ := AnsiString(Attr.AsString);
        tkWString:
          if Assigned(Attr) then
            PWideString(pi)^ := Attr.AsString;
{$ENDIF}
        tkVariant:
          if Assigned(Attr) then
            PVariant(pi)^ := Attr.AsVariant
          else
            PVariant(pi)^ := NodeToVariant(AChild);
        tkArray, tkDynArray:
          if Assigned(AChild) then

            AChild.ToRtti(pi, ASubTypeInfo);
        tkRecord:
          if Assigned(AChild) then
            AChild.ToRtti(pi, ASubTypeInfo);
        tkInt64:
          if Assigned(Attr) then
            PInt64(pi)^ := Attr.AsInt64;
        tkUString:
          if Assigned(Attr) then
            PUnicodeString(pi)^ := Attr.AsString;
      end;
    end;
  end;

begin
  if ADest <> nil then
  begin
    if AType.Kind = tkRecord then
      ToRecord
    else if AType.Kind = tkClass then
      ToObject
    else if AType.Kind = tkDynArray then
      ToArray
    else if AType.Kind = tkArray then
      ToFixedArray
    else
      raise Exception.Create(SUnsupportPropertyType);
  end;
end;

function TQXMLNode.ToRttiValue: TValue;
  procedure AsDynValueArray;
  var
    AValues: array of TValue;
    I: Integer;
  begin
    SetLength(AValues, Count);
    for I := 0 to Count - 1 do
      AValues[I] := Items[I].ToRttiValue;
    Result := TValue.FromArray(TypeInfo(TValueArray), AValues);
  end;

begin
  Result := AsXML;
end;
{$IFEND >=2010}

function TQXMLNode.XMLDecode(const S: QStringW): QStringW;
begin
  Result := XMLDecode(PQCharW(S), Length(S));
end;

function TQXMLNode.XMLDecode(const p: PQCharW; l: Integer): QStringW;
var
  ps, ws, pd: PQCharW;
  c: QCharW;
const
  EscapeEnd: PQCharW = ';<>';
begin
  SetLength(Result, l);
  ps := p;
  pd := PQCharW(Result);
  while ps - p < l do
  begin
    if ps^ = '&' then
    begin
      ws := ps;
      SkipUntilW(ps, EscapeEnd);
      if ps^ = ';' then
      begin
        Inc(ps);
        c := PQCharW(HtmlUnescape(StrDupX(ws, ps - ws)))^;
        if c <> #0 then
          pd^ := c
        else
          raise Exception.Create(Format(SUnknownXMLEscape,
            [StrDupX(ws, ps - ws)]));
        Inc(pd);
      end
      else // 兼容处理
      begin
        pd^ := ws^;
        ps := ws;
        Inc(pd);
        Inc(ps);
        // raise Exception.Create(SBadXMLEscape);
      end;
    end
    else
    begin
      pd^ := ps^;
      Inc(ps);
      Inc(pd);
    end;
  end;
  SetLength(Result, pd - PQCharW(Result));
end;

function TQXMLNode.XMLEncode(const S: QStringW;
  AConvertQuoter, AppendSpace: Boolean): QStringW;
var
  ps, pd: PQCharW;
  ASpaceCount: Integer;
const
  SpaceText: PQCharW = '&nbsp;';
  procedure StrCat(var d: PQCharW; S: PQCharW);
  begin
    while S^ <> #0 do
    begin
      d^ := S^;
      Inc(d);
      Inc(S);
    end;
  end;

begin
  {
    &lt;	<	小于
    &gt;	>	大于
    &amp;	&	和号
    &apos;	'	单引号
    &quot;	"	引号
  }
  SetLength(Result, Length(S) * 6);
  ps := PQCharW(S);
  pd := PQCharW(Result);
  if AppendSpace then
  begin
    // 如果前面有空格，则转义空格
    while ps^ = ' ' do
    begin
      StrCat(pd, '&nbsp;');
      Inc(ps);
    end;
  end;
  ASpaceCount := 0;
  while ps^ <> #0 do
  begin
    if ps^ = ' ' then
      Inc(ASpaceCount)
    else
      ASpaceCount := 0;
    case ps^ of
      '<':
        StrCat(pd, '&lt;');
      '>':
        StrCat(pd, '&gt;');
      '&':
        StrCat(pd, '&amp;');
      '''':
        begin
          if AConvertQuoter then
            StrCat(pd, '&apos;')
          else
          begin
            pd^ := ps^;
            Inc(pd);
          end;
        end;
      '"':
        begin
          if AConvertQuoter then
            StrCat(pd, '&quot;')
          else
          begin
            pd^ := ps^;
            Inc(pd);
          end;
        end
    else
      begin
        pd^ := ps^;
        Inc(pd);
      end;
    end;
    Inc(ps);
  end;
  if AppendSpace then
  begin
    Dec(pd, ASpaceCount);
    while ASpaceCount > 0 do
    begin
      Move(SpaceText^, pd^, 12);
      Inc(pd, 6);
      Dec(ASpaceCount);
    end;
  end;
  SetLength(Result, pd - PQCharW(Result));
end;
{ TQXMLAttr }

function TQXMLAttr.GetAsBoolean: Boolean;
begin
  if not TryStrToBool(FValue, Result) then
  begin
    try
      Result := (AsInt64 <> 0);
    except
      raise Exception.Create(SValueNotBoolean);
    end;
  end;
end;

function TQXMLAttr.GetAsDateTime: TDateTime;
begin
  if not(ParseDateTime(PQCharW(FValue), Result) or ParseWebTime(PQCharW(FValue),
    Result)) then
    Result := GetAsFloat;
end;

function TQXMLAttr.GetAsFloat: Extended;
var
  p: PQCharW;
begin
  p := PQCharW(FValue);
  if not ParseNumeric(p, Result) then
    raise Exception.CreateFmt(SValueNotNumeric, [FValue]);
end;

function TQXMLAttr.GetAsInt64: Int64;
begin
  Result := Trunc(AsFloat);
end;

function TQXMLAttr.GetAsInteger: Integer;
begin
  Result := AsInt64;
end;

function TQXMLAttr.GetAsVariant: Variant;
begin
  Result := FValue;
end;

procedure TQXMLAttr.SetAsBoolean(const Value: Boolean);
begin
  FValue := BoolToStr(Value, True);
end;

procedure TQXMLAttr.SetAsDateTime(const Value: TDateTime);
begin
  FValue := FloatToStr(Value);
end;

procedure TQXMLAttr.SetAsFloat(const Value: Extended);
begin
  FValue := FloatToStr(Value);
end;

procedure TQXMLAttr.SetAsInt64(const Value: Int64);
begin
  FValue := IntToStr(Value);
end;

procedure TQXMLAttr.SetAsInteger(const Value: Integer);
begin
  SetAsInt64(Value);
end;

procedure TQXMLAttr.SetAsVariant(const Value: Variant);
begin
  FValue := VarToStr(Value);
end;

procedure TQXMLAttr.SetName(const Value: QStringW);
begin
  if FName <> Value then
  begin
    FName := Value;
    FNameHash := 0;
  end;
end;

{ TQXMLAttrEnumerator }

constructor TQXMLAttrEnumerator.Create(AList: TQXMLAttrs);
begin
  FList := AList;
  FIndex := -1;
  inherited Create;
end;

function TQXMLAttrEnumerator.GetCurrent: TQXMLAttr;
begin
  Result := FList[FIndex];
end;

function TQXMLAttrEnumerator.MoveNext: Boolean;
begin
  if FIndex < FList.Count - 1 then
  begin
    Inc(FIndex);
    Result := True;
  end
  else
    Result := False;
end;

{ TQXMLNodeEnumerator }

constructor TQXMLNodeEnumerator.Create(AList: TQXMLNode);
begin
  inherited Create;
  FList := AList;
  FIndex := -1;
end;

function TQXMLNodeEnumerator.GetCurrent: TQXMLNode;
begin
  Result := FList[FIndex];
end;

function TQXMLNodeEnumerator.MoveNext: Boolean;
begin
  if FIndex + 1 < FList.Count then
  begin
    Inc(FIndex);
    Result := True;
  end
  else
    Result := False;
end;

{ TQHashedXMLNode }

procedure TQHashedXMLNode.Clear(AIncAttrs: Boolean);
begin
  inherited;
  FHashTable.Clear;
end;

constructor TQHashedXMLNode.Create;
begin
  inherited;
  FHashTable := TQHashTable.Create();
  FHashTable.AutoSize := True;
end;

function TQHashedXMLNode.CreateNode: TQXMLNode;
begin
  if Assigned(OnQXMLNodeCreate) then
    Result := OnQXMLNodeCreate
  else
    Result := TQHashedXMLNode.Create;
end;

destructor TQHashedXMLNode.Destroy;
begin
  inherited;
  FreeObject(FHashTable);
end;

procedure TQHashedXMLNode.DoNodeNameChanged(ANode: TQXMLNode);
begin
  ANode.FNameHash := HashOf(PQCharW(ANode.Name), Length(ANode.Name) shl 1);
  if Assigned(ANode.Parent) then
    TQHashedXMLNode(ANode.Parent).FHashTable.Add
      (Pointer(ANode.Parent.Count - 1), ANode.FNameHash);
end;

function TQHashedXMLNode.IndexOf(const AName: QStringW): Integer;
var
  AIndex, AHash: Integer;
  AList: PQHashList;
  AItem: TQXMLNode;
begin
  AHash := HashOf(PQCharW(AName), Length(AName) shl 1);
  AList := FHashTable.FindFirst(AHash);
  Result := -1;
  while AList <> nil do
  begin
    AIndex := Integer(AList.Data);
    AItem := Items[AIndex];
    if AItem.Name = AName then
    begin
      Result := AIndex;
      Break;
    end
    else
      AList := FHashTable.FindNext(AList);
  end;
end;

function TQHashedXMLNode.Remove(AIndex: Integer): TQXMLNode;
begin
  Result := inherited Remove(AIndex);
  if Assigned(Result) then
    FHashTable.Delete(Pointer(AIndex), Result.FNameHash);
end;

{ TQSoapXML }

function TQSoapXML.Body(const AName: QStringW): TQXMLNode;
begin
  Result := Body.AddNode(AName);
end;

function TQSoapXML.Body: TQXMLNode;
begin
  if not Assigned(FBody) then
    FBody := FRoot.ForcePath('SOAP-ENV:Body');
  Result := FBody;
end;

constructor TQSoapXML.Create;
begin
  FRoot := TQXMLNode.Create;
  FRoot.Name := 'SOAP-ENV:Envelope';
  FRoot.Attrs.Add('xmlns:SOAP-ENV',
    'http://schemas.xmlsoap.org/soap/envelope/');
  FRoot.Attrs.Add('SOAP-ENV:encodingStyle',
    'http://schemas.xmlsoap.org/soap/encoding/');
end;

destructor TQSoapXML.Destroy;
begin
  FreeObject(FRoot);
  inherited;
end;

function TQSoapXML.Header: TQXMLNode;
begin
  if not Assigned(FHeader) then
  begin
    FHeader := FRoot.ForcePath('SOAP-ENV:Header');
    if FRoot[0] <> FHeader then
      FHeader.MoveTo(FRoot, 0);
  end;
  Result := FHeader;
end;

function TQSoapXML.Header(const AName: QStringW): TQXMLNode;
begin
  Result := Header.AddNode(AName);
end;

function TQSoapXML.Header(const ANodeName, ANSUri: QStringW): TQXMLNode;
var
  p: PQCharW;
const
  NameValueDelimiter: PWideChar = ':';
begin
  Result := Header.AddNode(ANodeName);
  p := PWideChar(ANodeName);
  Result.Attrs.Add('xmlns:' + DecodeTokenW(p, NameValueDelimiter, QCharW(#0),
    False), ANSUri);
end;

procedure TQSoapXML.SaveToFile(const AFileName: QStringW);
begin
  FRoot.SaveToFile(AFileName, teUTF8, False, False, False);
end;

procedure TQSoapXML.SaveToStream(AStream: TStream);
begin
  FRoot.SaveToStream(AStream, teUTF8, False, False, False);
end;

function TQXMLAttrs.AddDateTime(const AName: QStringW;
  AValue: TDateTime): Integer;
var
  AInt: Integer;
begin
  AInt := Trunc(AValue);
  if AInt <> 0 then
  begin
    if IsZero(AValue - AInt) then
      Result := Add(AName, FormatDateTime(XMLDateFormat, AValue))
    else
      Result := Add(AName, FormatDateTime(XMLDateTimeFormat, AValue));
  end
  else
    Result := Add(AName, FormatDateTime(XMLTimeFormat, AValue));
end;

function TQXMLAttrs.Add(const AName: QStringW; AValue: TGuid): Integer;
begin
  Result := Add(AName, sysutils.GuidToString(AValue));
end;

initialization

XMLDateFormat := 'yyyy-mm-dd';
XMLDateTimeFormat := 'yyyy-mm-dd''T''hh:nn:ss.zzz';
XMLTimeFormat := 'hh:nn:ss.zzz';
XMLCaseSensitive := True;
XMLTagShortClose := True;
XMLRttiEnumAsInt := False;
OnQXMLNodeCreate := nil;
OnQXMLNodeFree := nil;

end.
