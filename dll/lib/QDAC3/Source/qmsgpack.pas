unit qmsgpack;
{$i 'qdac.inc'}

interface

{
  本源码来自QDAC项目，版权归swish(QQ:109867294)所有。
  (1)、使用许可及限制
  您可以自由复制、分发、修改本源码，但您的修改应该反馈给作者，并允许作者在必要时，
  合并到本项目中以供使用，合并后的源码同样遵循QDAC版权声明限制。
  您的产品的关于中，应包含以下的版本声明:
  本产品使用的JSON解析器来自QDAC项目中的QMsgPack，版权归作者所有。
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

{ 修订日志
  2016.10.08
  =========
  * 修正了 WriteSingle/WriteFloat 可能出现无效的浮点运算的问题
  2016.8.23
  =========
  + ToRtti 加入固定长度数组支持（移植 QJson 源码）
  2016.7.24
  =========
  * 修正了 SaveToStream 时，由于 TFileStream 类型的流在调整 Size 时同时调整了 Position 造成的问题（谢顿报告）
  2016.3.7
  =========
  * 修正了 DoNodeNameChanged 事件中，Rehash 时，没有正确更新哈希值的问题（QQ报告）
  2016.2.24
  =========
  * 修正了 ItemByPath 时对特殊数组路径解析存在的问题（恢弘报告）
  2016.2.23
  =========
  * 修正了 TQHashedMsgPack 重复添加哈希表项的问题（QQ报告）
  2016.2.22
  =========
  * 修正了TQHashedMsgPack子结点创建时类型错误使用了TQMsgPack的问题（QQ报告）
  2016.1.25
  ==========
  * 修正了 TQHashedMsgPack 在析构时，提前释放了 FHashTable 的问题
  2015.11.19
  ==========
  * 修正了 FromRtti 在 Win64 时，如果没有子属性时出错的问题
  2015.10.30
  ==========
  * 修正了转换为JSON时，由于调用系统自带的BoolToStr造成True/False不是有效的JSON布尔值的问题（空气报告）

  2015.10.20
  ==========
  + 增加 Root/IgnoreCase属性
  + 增加函数 Sort/RevertOrder/ExchangeOrder/ContainsName/ContainsValue/Exists函数
  2015.7.20
  ==========
  * 更改了 ToRtti 时对采用默认值对象属性的控制方法
  * 修正了 ToRtti 和 FromRtti 落下 TDateTime 类型属性的问题（感谢好人一生平安）
  2015.4.27
  =========
  * 修正了键类型非字符串时，IndexOf等方式检索无法找到对象的子结点的问题（感谢空号）

  2015.3.26
  =========
  * 修正了FromRtti.AddObject时忘记释放PropList的问题（感谢Vagabond)
  2015.2.14
  =========
  * 新增 KeyAsXXX 属性来按类型来操作映射的键类型，键值类型可以是除了数组、映射和扩
  展类型外的所有类型
  * 新增 KeyType 属性来判断键的类型（只读，要赋值通过 KeyAsXXX 系列函数）
  * 新增 KeyIsNull 属性来判断键是否为空
  2015.2.6
  =========
  * 修正了 AsInteger/AsFloat 时不支持十六进制的问题

  2015.1.26
  ==========
  + 增加无参数的Delete函数用于删除结点自身

  2015.1.20
  =========
  * 修正了 BytesToFile 函数忘记保存到文件的问题(playwo报告）

  2015.1.13
  ==========
  * 修正了 TQHashedMsgPack 的 IndexOf 未正确处理大小写的问题
  * 修正了 TQHashedMsgPack 在解析完成后未正确重新计算哈希值的问题（阿木报告）

  2015.1.6
  ========
  * 修正了SetAsVariant对非标准的变体类型的支持问题（小枫报告）

  2015.1.5
  =========
  * 修正了IsChildOf的一处判断错误，造成可能发生AV异常

  2014.1.4
  ==========
  * 修改了 ItemByName 的部分代码，修正了没有正确处理 MsgPackCaseSensitive 标记的问题,造成忽略大小写无效的问题
  * 修正了 ItemByName 对数组下标处理的逻辑错误
  * 修正了 ItemByPath 不支持多维数组的问题

  2014.12.30
  ==========
  * 修正了SaveToStream时，流的大小未截断造成按16KB对齐的问题（觉悟报告）
  2014.12.18
  ==========
  * 优化了SaveToStream的行为，避免不必要的创建了TBytes实例问题（不得闲报告）
  * 修正了AsJson属性在处理空对象或数组时未正确编码的问题（凌风报告）
  2014.12.13
  ==========
  + 增加HasChild函数，来判定指定路径的子结点是否存在（阿木建议）
  * 修正了ForcePath处理"a.b[].c"时生成的路径错误的问题

  2014.11.26
  ==========
  * AsString修改回原行为，单独加入一个AsJson来格式化成Json格式

  2014.11.25
  ==========
  * 修改了ItemByPath的代码，支持按索引顺序来访问mptMap类型的子成员

  2014.11.21
  ==========
  + 加入ValueFromStream/ValueFromFile/StreamFromValue/StreamFromFile函数
  * AsString修改为标准的JSON字符串

  2014.11.14
  ==========
  * 修正SetVariant/GetVariant加入对varNull/varEmpty的支持(合并自cyw)
  * 修正了解析8位整数时，负数错误的解析成正数的问题
  2014.11.10
  ==========
  * 修正了FromRtti/ToRtti在处理TCollection类型时存在的问题
  * 修正了FromRtti中ToObject子函数的一处错误(hq200306报告)

  2014.11.9
  ==========
  + 新增IntByPath,IntByName，BoolByPath,BoolByName,FloatByPath,FloatByName,DateTimeByPath,
  DateTimeByName函数，以简化判断编程(参考QJson)
  2014.10.30
  ==========
  + 新增Detach、AttachTo、MoveTo、Remove函数
  * 允许MsgPack结点名称重命名以避免调用MoveTo、AttachTo时元素未命名

  2014.10.21
  ==========
  * 修正了解析数组元素数量介于16-31之间时出错的问题（追梦报告）
  2014.8.25
  ==========
  * 修正了打开IO越界检查时，如果字符串长度为0,GetAsString出错的问题(天地弦报告)

  2014.8.15
  ==========
  * 修正了加载长二进制数据时，错误的跳过内容的前4个字节的问题(天地弦报告)
  * 优化了AsVariant读写时，对字节数组时的转换效率
  * 修正了CopyValue时，对于非字符串类型拷贝长度设置错误的问题
  * 网络字节顺序和主机字节顺序转换统一改为使用ExchangeByteOrder函数完成

  2014.8.2
  =========
  * 修正了SetAsString时如果长度为0时，未检查数组FValue造成访问越界的问题

  2014.7.17
  =========
  * 合并QJson的相关RTTI函数(AK47完成)

  2014.7.16
  =========
  * 修正了GetPath时，未初始化结果字符串造成Path属性可能出错的问题
  2014.7.7
  =========
  * 修正了整数值-1~-31时，解码出错的问题(五毒报告)
  2014.7.3
  =========
  * 修正了Assign时复制了当前结点名称的问题
  2014.7.1
  =========
  * 修改AsString在空值时的返回内容为空字符串
  2014.6.28
  =========
  * 修正了ForcePath('Items[]')默认添加了空子结点的问题(pony,光明报告)
  + 加入MsgPackRttiEnumAsInt全局选项，控制枚举值和集合值是否保存成其字符串表达，默认为True(同步自QJson)
  2014.6.27
  =========
  * 修正了FromRTTI时，对于方法、事件等属性没有进行过滤的问题
  * 修正了ToRtti.ToArray时，对于动态数组的设置长度时类型错误
  * 修改了AsVariant的行为，对字节数组直接转换为TBytes，而不再使用普通的数组
  2014.6.26
  ==========
  * 修正了ToRtti.ToRecord子函数处理日期类型时的错误(感谢群友飞鸿大量的RTTI建议和测试)
  * 加入HPPEMIT默认链接本单元(麦子仲肥 建议)
  2014.6.23
  ==========
  + FromRecord支持动态数组和普通数组
  2014.6.21
  ==========
  + 增加RTTI函数支持(Invoke/FromRtti/ToRtti/FromRecord/ToRecord)
  2014.6.20
  ==========
  + 增加对Single类型的支持(AsSingle)，这样全部MessagePack格式的支持完整了
  2014.6.19
  ==========
  * 修正了QMsgPack解码时，对于长度为0的字符串解码出错的问题
  2014.6.17
  ==========
  * 首个正式版本发布，目前与RTTI相关的几个函数暂时不可用
}
uses classes, sysutils, math, qstring, qrbtree, typinfo,
  variants, varutils
{$IFDEF UNICODE}, Generics.Collections{$ENDIF}{$IF RTLVersion>=21},
  Rtti{$IFEND >=2010}
{$IF RTLVersion<22}// 2007-2010
    , PerlRegEx, pcre
{$ELSE}
    , RegularExpressionsCore
{$IFEND};
{$HPPEMIT '#pragma link "qmsgpack"'}

type
  TQMsgPack = class;
  PQMsgPack = ^TQMsgPack;
  /// MessagePack 结点数据类型列表
  TQMsgPackType = (mptUnknown,
    /// 未知类型
    mptInteger,
    /// 整数
    mptNull,
    /// 空
    mptBoolean,
    /// 布尔型数据
    mptSingle,
    /// 单精度浮点数

    mptFloat,
    /// 双精度浮点数
    mptString,
    /// 字符串类型
    mptBinary,
    /// 二进制数据
    mptArray,
    /// 数组
    mptMap,
    /// 映射，相当于 Json 中的对象。
    mptExtended,
    /// 扩展数据类型
    mptDateTime
    /// 日期时间类型，这是QMsgPack的一个扩展，保存时类型信息会转换为双精度浮点值保存。
    );
{$IFDEF UNICODE}
  /// <summary>
  /// RTTI信息过滤回调函数，在XE6上支持匿名函数，在XE及以前的版本采用事件回调
  /// </summary>
  /// <param name="ASender">触发事件的TQMsgPack对象</param>
  /// <param name="AName">属性名(AddObject)或字段名(AddRecord)</param>
  /// <param name="AType">属性或字段的类型信息</param>
  /// <param name="Accept">是否记录该属性或字段</param>
  /// <param name="ATag">用户自定义的附加数据成员</param>
  TQMsgPackRttiFilterEventA = reference to procedure(ASender: TQMsgPack;
    AObject: Pointer; AName: QStringW; AType: PTypeInfo; var Accept: Boolean;
    ATag: Pointer);
  /// <summary>
  /// 结点过滤处理函数，以在XE6上支持匿名函数
  /// </summary>
  /// <param name="ASender">触发事件的TQMsgPack对象</param>
  /// <param name="AItem">要过滤的对象</param>
  /// <param name="Accept">是否要处理该对象</param>
  /// <param name="ATag">用户附加的数据项</param>
  TQMsgPackFilterEventA = reference to procedure(ASender, AItem: TQMsgPack;
    var Accept: Boolean; ATag: Pointer);
{$ENDIF UNICODE}
  /// <summary>
  /// RTTI信息过滤回调函数，在XE6上支持匿名函数，在XE及以前的版本采用事件回调
  /// </summary>
  /// <param name="ASender">触发事件的TQMsgPack对象</param>
  /// <param name="AName">属性名(AddObject)或字段名(AddRecord)</param>
  /// <param name="AType">属性或字段的类型信息</param>
  /// <param name="Accept">是否记录该属性或字段</param>
  /// <param name="ATag">用户自定义的附加数据成员</param>
  TQMsgPackRttiFilterEvent = procedure(ASender: TQMsgPack; AObject: Pointer;
    AName: QStringW; AType: PTypeInfo; var Accept: Boolean; ATag: Pointer)
    of object;
  /// <summary>
  /// 结点过滤处理函数，以在XE6上支持匿名函数
  /// </summary>
  /// <param name="ASender">触发事件的TQMsgPack对象</param>
  /// <param name="AItem">要过滤的对象</param>
  /// <param name="Accept">是否要处理该对象</param>
  /// <param name="ATag">用户附加的数据项</param>
  TQMsgPackFilterEvent = procedure(ASender, AItem: TQMsgPack;
    var Accept: Boolean; ATag: Pointer) of object;
{$IF RTLVersion>=21}
  TQMsgPackList = TList<TQMsgPack>;
{$ELSE}
  TQMsgPackList = TList;
{$IFEND}

  TQMsgPackEnumerator = class
  private
    FIndex: Integer;
    FList: TQMsgPack;
  public
    constructor Create(AList: TQMsgPack);
    function GetCurrent: TQMsgPack; inline;
    function MoveNext: Boolean;
    property Current: TQMsgPack read GetCurrent;
  end;

  // 时间戳
  TQMsgPackTimeStamp = record
    Seconds: Int64;
    NanoSeconds: Cardinal;
  end;

  TQMsgPack = class
  private
    FKey: TBytes; // 名称
    FKeyHash: Cardinal; // 哈希值
    FValue: TBytes; // 值
    FItems: TQMsgPackList;
    FParent: TQMsgPack;
    FDataType: TQMsgPackType;
    FKeyType: TQMsgPackType;
    FExtType: Shortint;
    FData: Pointer;
    FIgnoreCase: Boolean;
    function GetAsBoolean: Boolean;
    function GetAsDateTime: TDateTime;
    function GetAsFloat: Double;
    function GetAsInt64: Int64;
    function GetAsInteger: Integer;
    function GetAsMsgPack: TBytes;
    function GetAsString: QStringW;
    function GetAsVariant: Variant;
    function GetCount: Integer;
    function GetIsArray: Boolean;
    function GetIsDateTime: Boolean;
    function GetIsNull: Boolean;
    function GetIsNumeric: Boolean;
    function GetIsObject: Boolean;
    function GetIsString: Boolean;
    function GetItemIndex: Integer;
    function GetItems(AIndex: Integer): TQMsgPack;
    function GetPath: QStringW;
    function GetValue: QStringW;
    procedure SetAsBoolean(const Value: Boolean);
    procedure SetAsDateTime(const Value: TDateTime);
    procedure SetAsFloat(const Value: Double);
    procedure SetAsInt64(const Value: Int64);
    procedure SetAsInteger(const Value: Integer);
    procedure SetAsMsgPack(const Value: TBytes);
    procedure SetAsString(const Value: QStringW);
    procedure SetAsVariant(const Value: Variant);
    procedure SetDataType(const Value: TQMsgPackType);
    procedure InternalParse(var p: PByte; l: Integer; AToKey: Boolean);
    procedure ArrayNeeded(ANewType: TQMsgPackType);
    function CreateItem: TQMsgPack; virtual;
    procedure FreeItem(AItem: TQMsgPack); virtual;
    procedure CopyValue(ASource: TQMsgPack); inline;
    procedure SetExtType(const Value: Shortint);
    function GetAsExtBytes: TBytes;
    procedure SetExtBytes(const Value: TBytes);
    function GetAsBytes: TBytes;
    procedure SetAsBytes(const Value: TBytes);
    function GetAsSingle: Single;
    procedure SetAsSingle(const Value: Single);
    function GetAsJson: QStringW;
    function EncodeAsString(AStrictJson: Boolean): QStringW;
    procedure SetKeyAsString(const Value: QStringW);
    function GetKeyAsString: QStringW;
    function GetKeyAsBytes: TBytes;
    function GetKeyAsFloat: Double;
    function GetKeyAsInt64: Int64;
    function GetKeyAsInteger: Integer;
    function GetKeyAsSingle: Single;
    procedure SetKeyAsBytes(const Value: TBytes);
    procedure SetKeyAsFloat(const Value: Double);
    procedure SetKeyAsInt64(const Value: Int64);
    procedure SetKeyAsInteger(const Value: Integer);
    procedure SetKeyAsSingle(const Value: Single);
    function GetKeyAsBoolean: Boolean;
    procedure SetKeyAsBoolean(const Value: Boolean);
    function GetKeyIsNull: Boolean;
    function GetKeyAsDateTime: TDateTime;
    procedure SetKeyAsDateTime(const Value: TDateTime);
    procedure SetIgnoreCase(const Value: Boolean);
    function GetRoot: TQMsgPack;
    function BoolToStr(v: Boolean): QStringW; inline;
    function GetIsOrdType: Boolean;
  protected
    /// 替换指定位置的结点为新结点
    ///
    ///
    /// <param name="AIndex">要替换的位置索引</param>
    /// <param name="ANewItem">要替换的新结点</param>
    procedure Replace(AIndex: Integer; ANewItem: TQMsgPack); virtual;
    procedure DoNodeNameChanged(ANode: TQMsgPack); virtual;
    procedure DoNodeMoved(ANode: TQMsgPack); virtual;
    procedure InternalEncode(ANode: TQMsgPack; AStream: TStream;
      ADateTimeAsTimeStamp: Boolean);
    procedure DoParsed; virtual;
    function InternalAdd(const AKey: TBytes; AKeyType, ADataType: TQMsgPackType)
      : TQMsgPack;
    function CreateNew: TQMsgPack; virtual;
    function HashName(const s: QStringW): TQHashType;
    procedure HashNeeded; inline;
  public
    /// <summary>构造函数</summary>
    constructor Create; overload;
    constructor Create(const AName: QStringW;
      ADataType: TQMsgPackType = mptUnknown); overload;
    /// <summary>析构函数</summary>
    destructor Destroy; override;
    { <summary>添加一个子结点<、summary>
      <param name="ANode">要添加的结点</param>
      <returns>返回添加的结点索引</returns>
    }
    function Add(ANode: TQMsgPack): Integer; overload;
    /// <summary>添加一个未命名的MsgPack子结点</summary>
    /// <returns>返回添加的结点实例</returns>
    /// <remarks>
    /// 一般情况下，除非数组类型，不应添加未命名的实例
    /// </remarks>
    function Add: TQMsgPack; overload;
    /// <summary>添加一个数组</summary>
    /// <param name="AName">要添加的对象的结点名称</param>
    /// <param name="AItems">要添加的数组内容</param>
    /// <returns>返回创建的结点实例</returns>
    function Add(const AName: QStringW; AItems: array of const)
      : TQMsgPack; overload;

    { <summary>添加一个子结点</summary>
      <param name="AName">要添加的结点名</param>
      <param name="ADataType">要添加的结点数据类型，如果省略，则自动根据值的内容检测</param>
      <returns>返回添加的新对象</returns>
      <remarks>
      1.如果当前类型不是jdtObject或jdtArray，将自动转换为jdtObject类型
      2.上层应自己负责重名检查
      </remarks>
    }
    function Add(AName: QStringW; ADataType: TQMsgPackType): TQMsgPack;
      overload;
    /// <summary>添加一个数组子结点</summary>
    /// <param name="AName">要添加的结点名，如果当前结点为数组，则在输出时会忽略该值</param>
    /// <returns>返回添加的新对象</returns>
    function AddArray(AName: QStringW): TQMsgPack; inline;
    /// <summary>添加一个子结点</summary>
    /// <param name="AName">要添加的结点名，如果当前结点为数组，则在输出时会忽略该值</param>
    /// <param name="AValue">要添加的结点值</param>
    /// <returns>返回添加的新对象</returns>
    function Add(AName, AValue: QStringW): TQMsgPack; overload;
    /// <summary>添加一个子结点</summary>
    /// <param name="AName">要添加的结点名，如果当前结点为数组，则在输出时会忽略该值</param>
    /// <param name="AValue">要添加的结点值</param>
    /// <returns>返回添加的新对象</returns>
    function Add(AName: QStringW; AValue: Double): TQMsgPack; overload;
    /// <summary>添加一个子结点</summary>
    /// <param name="AName">要添加的结点名，如果当前结点为数组，则在输出时会忽略该值</param>
    /// <param name="AValue">要添加的结点值</param>
    /// <returns>返回添加的新对象</returns>
    function Add(AName: QStringW; AValue: Int64): TQMsgPack; overload;
    /// <summary>添加一个子结点</summary>
    /// <param name="AName">要添加的结点名，如果当前结点为数组，则在输出时会忽略该值</param>
    /// <param name="AValue">要添加的结点值</param>
    /// <returns>返回添加的新对象</returns>
    function Add(AName: QStringW; AValue: Boolean): TQMsgPack; overload;
    /// <summary>添加一个子结点</summary>
    /// <param name="AName">要添加的结点名，如果当前结点为数组，则在输出时会忽略该值</param>
    /// <param name="AValue">要添加的结点值</param>
    /// <returns>返回添加的新对象</returns>
    function Add(AName: QStringW; const AValue: TBytes): TQMsgPack; overload;
    /// <summary>添加一个子结点</summary>
    /// <param name="AName">要添加的结点名，如果当前结点为数组，则在输出时会忽略该值</param>
    /// <param name="AValue">要添加的结点值</param>
    /// <returns>返回添加的新对象</returns>
    function AddDateTime(AName: QStringW; AValue: TDateTime)
      : TQMsgPack; overload;
    /// <summary>添加一个子结点(Null)</summary>
    /// <param name="AName">要添加的结点名，如果当前结点为数组，则在输出时会忽略该值</param>
    /// <returns>返回添加的新对象</returns>
    function Add(AName: QStringW): TQMsgPack; overload; virtual;

    /// <summary>强制一个路径存在,如果不存在,则依次创建需要的结点(jdtObject或jdtArray)</summary>
    /// <param name="APath">要添加的结点路径</param>
    /// <returns>返回路径对应的对象</returns>
    /// <remarks>
    /// 假设以下路径完全不存在，则ForcePath会按如下规则执行:
    /// 1、如果APath中包含[]，则认为对应的路径结点为数组，示例如下：
    /// (1)、'a.b[].name'：
    /// a -> jdtObject
    /// b -> jdtArray
    /// b[0].name -> jdtNull(b的索引未指定，自动认为是b[0]
    /// (2)、'a.c[2].name'：
    /// a -> jdtObject
    /// c -> jdtArray
    /// c[2].name -> jdtNull
    /// 其中,c[0],c[1]被自动创建，并赋值为jdtNull，执行完成后c为包含三个元素的数组
    /// (3)、'a[0]'：
    /// a -> jdtArray
    /// a[0] -> jdtNull
    /// 2、路径分隔符./\是等价的，并且结点名称中不应包含上述三个字符之一,即：
    /// a.b.c和a\b\c和a/b/c是完全相同的路径
    /// 3、如果APath指定的对象类型不匹配，则会抛出异常，如a为对象，但使用a[0].b访问时。
    /// </remarks>
    function ForcePath(APath: QStringW): TQMsgPack;
    /// <summary>解析指定的MsgPack字节序列</summary>
    /// <param name="p">要解析的字节序列</param>
    /// <param name="l">字符串长度，<=0认为是以\0(#0)结尾的C语言标准字符串</param>
    /// <remarks>如果l>=0，会检测p[l]是否为\0，如果不为\0，则会创建拷贝实例并解析拷贝实例</remarks>
    procedure Parse(p: PByte; l: Integer = -1); overload;
    /// <summary>解析指定的MsgPack字符串</summary>
    /// <param name="s">要解析的MsgPack字符串</param>
    procedure Parse(const s: TBytes); overload;
    /// <summary>拷贝生成一个新的实例</summary>
    /// <returns>返回新的拷贝实例</returns>
    /// <remarks>因为是拷贝，所以新旧对象之间的内容变更没有任何关系，更改任意一个
    /// 对象，不会对另外一个对象造成影响。
    /// </remarks>
    function Copy: TQMsgPack;
{$IFDEF UNICODE}
    /// <summary>拷贝生成一个新的实例</summary>
    /// <param name="ATag">用户附加的标签数据</param>
    /// <param name="AFilter">用户过滤事件，用于控制要拷贝的内容</param>
    /// <returns>返回新的拷贝实例</returns>
    /// <remarks>因为是拷贝，所以新旧对象之间的内容变更没有任何关系，更改任意一个
    /// 对象，不会对另外一个对象造成影响。
    /// </remarks>
    function CopyIf(const ATag: Pointer; AFilter: TQMsgPackFilterEventA)
      : TQMsgPack; overload;
{$ENDIF UNICODE}
    /// <summary>拷贝生成一个新的实例</summary>
    /// <param name="ATag">用户附加的标签数据</param>
    /// <param name="AFilter">用户过滤事件，用于控制要拷贝的内容</param>
    /// <returns>返回新的拷贝实例</returns>
    /// <remarks>因为是拷贝，所以新旧对象之间的内容变更没有任何关系，更改任意一个
    /// 对象，不会对另外一个对象造成影响。
    /// </remarks>
    function CopyIf(const ATag: Pointer; AFilter: TQMsgPackFilterEvent)
      : TQMsgPack; overload;
    /// <summary>克隆生成一个新的实例</summary>
    /// <returns>返回新的拷贝实例</returns>
    /// <remarks>因为实际上执行的是拷贝，所以新旧对象之间的内容变更没有任何关系，
    /// 更改任意一个对象，不会对另外一个对象造成影响，但此行为将来并不保证，可能
    /// 会调整为引用，以便相互影响。
    /// </remarks>
    function Clone: TQMsgPack;
    /// <summary>
    /// 编码当前的QMsgPack结点及其子结点为二进制数据流
    /// </summary>
    /// <returns>
    /// 返回编码后的字节流
    /// </returns>
    /// <remarks>
    /// AsMsgPack等价于本函数
    /// </remarks>
    function Encode: TBytes;
    /// <summary>获取指定名称获取结点的值的字符串表示</summary>
    /// <param name="AName">结点名称</param>
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

    /// <summary>获取指定名称的第一个结点</summary>
    /// <param name="AName">结点名称</param>
    /// <returns>返回找到的结点，如果未找到，返回空(NULL/nil)</returns>
    /// <remarks>注意QMsgPack并不检查重名，因此，如果存在重名的结点，只会返回第一个结点</remarks>
    /// <summary>获取指定名称的第一个结点</summary>
    /// <param name="AName">结点名称</param>
    /// <returns>返回找到的结点，如果未找到，返回空(NULL/nil)</returns>
    /// <remarks>注意QMsgPack并不检查重名，因此，如果存在重名的结点，只会返回第一个结点</remarks>
    function ItemByName(AName: QStringW): TQMsgPack; overload; virtual;
    /// <summary>获取指定名称的结点到列表中</summary>
    /// <param name="AName">结点名称</param>
    /// <param name="AList">用于保存结点的列表对象</param>
    /// <param name="ANest">是否递归查找子结点</param>
    /// <returns>返回找到的结点数量，如果未找到，返回0</returns>
    function ItemByName(const AName: QStringW; AList: TQMsgPackList;
      ANest: Boolean = False): Integer; overload;
    /// <summary>获取符合指定名称规则的结点到列表中</summary>
    /// <param name="ARegex">正则表达式</param>
    /// <param name="AList">用于保存结点的列表对象</param>
    /// <param name="ANest">是否递归查找子结点</param>
    /// <returns>返回找到的结点数量，如果未找到，返回0</returns>
    /// <remarks>此函数不支持按数组下标方式检索</remarks>
    function ItemByRegex(const ARegex: QStringW; AList: TQMsgPackList;
      ANest: Boolean = False): Integer; overload;
    /// <summary>获取指定路径的MsgPack对象</summary>
    /// <param name="APath">路径，以"."或"/"或"\"分隔</param>
    /// <returns>返回找到的子结点，如果未找到返回NULL(nil)</returns>
    /// <remarks>对于数组或对象子结点，可以直接使用下标来访问，多层的数组和对象子结点，可以使用[][]这样子来访问。</remarks>
    function ItemByPath(APath: QStringW): TQMsgPack;
    /// <summary>从源对象复制MsgPack对象内容</summary>
    /// <param name="ANode">要复制的源结点</param>
    /// <remarks>注意不要复制子结点给自己，否则会造成死循环。要复制子结点，先复
    /// 制一个子结点的新实例，再从新实例复制
    /// </remarks>
    procedure Assign(ANode: TQMsgPack); virtual;
    /// <summary>删除指定索引的结点</summary>
    /// <param name="AIndex">要删除的结点索引</param>
    /// <remarks>
    /// 如果指定索引的结点不存在，则抛出EOutRange异常
    /// </remarks>
    procedure Delete(AIndex: Integer); overload; virtual;
    /// <summary>删除指定名称的结点</summary>
    /// <param name="AName">要删除的结点名称</param>
    /// <remarks>
    /// 如果要多个重名的结点，则只删除第一个
    procedure Delete(AName: QStringW); overload;
    /// <summary>从父结点中删除自身，如果没有父结点，则释放自己</summary>
    procedure Delete; overload;
{$IFDEF UNICODE}
    /// <summary>
    /// 删除符合条件的子结点
    /// </summary>
    /// <param name="ATag">用户自己附加的额外标记</param>
    /// <param name="ANest">是否嵌套调用，如果为false，则只对当前子结点过滤</param>
    /// <param name="AFilter">过滤回调函数，如果为nil，等价于Clear</param>
    procedure DeleteIf(const ATag: Pointer; ANest: Boolean;
      AFilter: TQMsgPackFilterEventA); overload;
{$ENDIF UNICODE}
    /// <summary>
    /// 删除符合条件的子结点
    /// </summary>
    /// <param name="ATag">用户自己附加的额外标记</param>
    /// <param name="ANest">是否嵌套调用，如果为false，则只对当前子结点过滤</param>
    /// <param name="AFilter">过滤回调函数，如果为nil，等价于Clear</param>
    procedure DeleteIf(const ATag: Pointer; ANest: Boolean;
      AFilter: TQMsgPackFilterEvent); overload;
    /// <summary>查找指定名称的结点的索引</summary>
    /// <param name="AName">要查找的结点名称</param>
    /// <returns>返回索引值，未找到返回-1</returns>
    function IndexOf(const AName: QStringW): Integer; overload; virtual;
{$IFDEF UNICODE}
    /// <summary>遍历结点查找符合条件的结点</summary>
    /// <param name="ATag">用户自定义的附加额外标记</param>
    /// <param name="ANest">是否嵌套调用，如果为false，则只对当前子结点过滤</param>
    /// <param name="AFilter">过滤回调函数，如果为nil，则返回nil</param>
    function FindIf(const ATag: Pointer; ANest: Boolean;
      AFilter: TQMsgPackFilterEventA): TQMsgPack; overload;
{$ENDIF UNICODE}
    /// <summary>遍历结点查找符合条件的结点</summary>
    /// <param name="ATag">用户自定义的附加额外标记</param>
    /// <param name="ANest">是否嵌套调用，如果为false，则只对当前子结点过滤</param>
    /// <param name="AFilter">过滤回调函数，如果为nil，则返回nil</param>
    function FindIf(const ATag: Pointer; ANest: Boolean;
      AFilter: TQMsgPackFilterEvent): TQMsgPack; overload;
    /// <summary>清除所有的结点</summary>
    procedure Clear; virtual;
    /// <summary>保存当前对象内容到流中</summary>
    /// <param name="AStream">目标流对象</param>
    /// <remarks>注意当前结点的名称不会被写入</remarks>
    procedure SaveToStream(AStream: TStream;
      ADateTimeAsTimeStamp: Boolean = False);
    /// <summary>从流的当前位置开始加载MsgPack对象</summary>
    /// <param name="AStream">源数据流</param>
    /// <remarks>流的当前位置到结束的长度必需大于2字节，否则无意义</remarks>
    procedure LoadFromStream(AStream: TStream);
    /// <summary>保存当前对象内容到文件中</summary>
    /// <param name="AFileName">文件名</param>
    /// <remarks>注意当前结点的名称不会被写入</remarks>
    procedure SaveToFile(AFileName: String;
      ADateTimeAsTimeStamp: Boolean = False);
    /// <summary>从指定的文件中加载当前对象</summary>
    /// <param name="AFileName">要加载的文件名</param>
    procedure LoadFromFile(AFileName: String);
    /// / <summary>重置值为Null，等价于直接设置DataType为jdtNull</summary>
    procedure ResetNull;
    /// <summary>重载TObject.ToString函数</summary>
    function ToString: string; {$IFDEF UNICODE}override; {$ELSE}virtual;
{$ENDIF}
{$IF RTLVersion>=21}
    /// <summary>
    /// 使用当前MsgPack对象参数调用指定对象的相应函数
    /// </summary>
    /// <param name="AInstance">函数所隶属的对象实例</param>
    /// <returns>
    /// 返回函数调用的结果
    /// </returns>
    /// <remarks>
    /// 函数名称为当前结点名称，函数的参数名称与子结点的名称要保持一致
    /// </remarks>
    function Invoke(AInstance: TValue): TValue;
    /// <summary>将当前的值转换为TValue类型的值</summary>
    /// <returns>返回当前结点转换后的TValue值</returns>
    function ToRttiValue: TValue;
    /// <summary>
    /// 从指定的RTTI实例中生成MsgPack数据
    /// </summary>
    /// <param name="AInstance">对象或其它RTTI类型值</param>
    /// <remarks>
    /// 注意不是全部RTTI类型都受支持，如接口啥的
    /// </remarks>
    procedure FromRtti(AInstance: TValue); overload;
    /// <summary>
    /// 将指定的来源地址按指定的类型生成MsgPack数据
    /// </summary>
    /// <param name="ASource">对象或结构体地址</param>
    /// <param name="AType">对象或结构体类型信息</param>
    procedure FromRtti(ASource: Pointer; AType: PTypeInfo); overload;
    /// <summary>从指定的记录实例中生成JSON数据</summary>
    /// <param name="ARecord">记录实例</param>
    procedure FromRecord<T>(const ARecord: T);
    /// <summary>从当前JSON中还原到指定的对象实例中</summary>
    /// <param name="AInstance">实例地址</param>
    /// <remarks>实际上参数只支持对象，记录由于目前无法直接转换为TValue，所以没
    /// 意义，而其它类型因为是值拷贝，实际就算赋值了也返回不了，因此无意义</remarks>
    procedure ToRtti(AInstance: TValue;
      AClearCollections: Boolean = True); overload;
    /// <summary>从当前JSON中按指定的类型信息还原到指定的地址</summary>
    /// <param name="ADest">目的地址</param>
    /// <param name="AType">对象或结构体的类型信息</param>
    /// <remarks>ADest对应的应是记录或对象，其它类型不受支持</remarks>
    procedure ToRtti(ADest: Pointer; AType: PTypeInfo;
      AClearCollections: Boolean = True); overload;
    /// <summary>从当前的JSON中还原到指定的记录实例中</summary>
    /// <param name="ARecord">目的记录实例</param>
    procedure ToRecord<T: record >(var ARecord: T;
      AClearCollections: Boolean = True);
{$IFEND >=2010}
    /// 该函数用于为 Delphi 提供 for .. in 语法支持。
    function GetEnumerator: TQMsgPackEnumerator;
    /// <summary>判断自己是否是一个指定的对象的子对象</summary>
    /// <param name="AParent">可能的父对象</param>
    /// <returns>如果自己是指定对象的子对象，则返回True，否则，返回False</returns>
    function IsChildOf(AParent: TQMsgPack): Boolean;
    /// <summary>判断自己是否是一个指定的对象的父对象</summary>
    /// <param name="AParent">可能的子对象</param>
    /// <returns>如果自己是指定对象的父对象，则返回True，否则，返回False</returns>
    function IsParentOf(AChild: TQMsgPack): Boolean;
    /// <summary>从流中加载二进制数据</summary>
    /// <param name="AStream">源数据流</param>
    /// <param name="ACount">要拷贝的字节数，如果为0，则拷贝源数据流的全部内容</param>
    procedure BytesFromStream(AStream: TStream; ACount: Integer);
    /// <summary>从文件中加载二进制数据</summary>
    /// <param name="AFileName">源文件名</param>
    procedure BytesFromFile(AFileName: QStringW);
    /// <summary>将当前数据保存到流中</summary>
    /// <param name="AStream">目标数据流</param>
    procedure BytesToStream(AStream: TStream);
    /// <summary>将当前数据保存到文件中</summary>
    /// <param name="AFileName">目标文件名</param>
    procedure BytesToFile(AFileName: QStringW);
    /// <summary>将指定索引的子结点移除</summary>
    /// <param name="AItemIndex">要移除的子结点索引</param>
    /// <returns>返回被移除的子结点，如果指定的索引不存在，返回nil</returns>
    /// <remarks>被移除的子结点需要用户自己手工释放</remarks>
    function Remove(AItemIndex: Integer): TQMsgPack; overload; virtual;
    /// <summary>将指定的子结点移除</summary>
    /// <param name="ANode">要移除的子结点</param>
    /// <remarks>被移除的子结点需要用户自己手工释放</remarks>
    procedure Remove(ANode: TQMsgPack); overload;
    /// <summary>从当前XML父结点中分离当前结点</summary>
    /// <remarks>分离后的结点需要单独释放</remarks>
    procedure Detach;
    /// <summary>将当前结点附加到新的父结点上</summary>
    /// <param name="AParent">要附加的目标结点</param>
    /// <remarks>附加后的结点由父结点负责释放</remarks>
    procedure AttachTo(ANewParent: TQMsgPack);
    /// <summary>将当前结点移动的新的父结点的指定位置</summary>
    /// <param name="ANewParent">新的父结点</param>
    /// <param name="AIndex">新位置索引</param>
    /// <remarks>如果新位置索引小于等于0，则插入到起始位置，如果大于父的已有结点数量，则插入到
    /// 父结点末尾，否则添加到指定位置</remarks>
    procedure MoveTo(ANewParent: TQMsgPack; AIndex: Integer);
    /// <summary>从流中加载二进制数据</summary>
    /// <param name="AStream">源数据流</param>
    /// <param name="ACount">长度，如果为0，则全部</param>
    procedure ValueFromStream(AStream: TStream; ACount: Cardinal);
    /// <summary>将二进制数据写入到流中</summary>
    /// <param name="AStream">目标数据流</param>
    procedure StreamFromValue(AStream: TStream);

    /// <summary>从流中加载二进制数据</summary>
    /// <param name="AStream">源文件名</param>
    procedure ValueFromFile(AFileName: QStringW);
    /// <summary>将二进制数据写入到流中</summary>
    /// <param name="AStream">目标文件名</param>
    procedure FileFromValue(AFileName: QStringW);

    /// <summary>判定是否有符合指定路径要求的子结点，如果存在，通过参数AChild保存实例地址并返回True，否则返回False</summary>
    /// <param name="ANamePath">结点路径，分隔符接受“.”，“/”，“\”三种</param>
    /// <param name="AChild">用于返回子结点指针</param>
    /// <returns>成功，返回True，AChild赋值为子结点指针，失败，返回False</returns>
    function HasChild(ANamePath: QStringW; var AChild: TQMsgPack)
      : Boolean; inline;
    /// <summary>获取到指定父结点的相对路径</summary>
    /// <param name="AParent">目标父结点</param>
    /// <param name="APathDelimiter">路径分隔符</param>
    /// <returns>返回相对路径</returns>
    function GetRelPath(AParent: TQMsgPack; APathDelimiter: QCharW = '\')
      : QStringW;
    procedure ResetKey;
    /// <summary>排序子结点</summary>
    /// <param name="AByName">是否按名称排序</param>
    /// <param name="ANest">是否排序子结点</param>
    /// <param name="AByType">子结点排序的类型依据，如果为jdtUnknown，则自动检测，否则按指定的类型排序</param>
    /// <param name="AOnCompare">排序比较方法，如果不指定，则按默认规则排序，否则根据它来排序</param>
    /// <remarks>AByType如果不为jdtUnknown，则你必需保证子结点的值能够转换为目标类型</remarks>
    procedure Sort(AByName, ANest: Boolean; AByType: TQMsgPackType;
      AOnCompare: TListSortCompare);
    /// <summary>逆转结点顺序</summary>
    /// <param name="ANest">是否嵌套逆转</param>
    procedure RevertOrder(ANest: Boolean = False);
    /// <summary>调整两个结点的顺序</summary>
    /// <param name="AIndex1">第一个结点索引<param>
    /// <param name="AIndex2">第二个结点索引</param>
    procedure ExchangeOrder(AIndex1, AIndex2: Integer);
    /// <summary>判断是否包含指定名称的子结点</summary>
    /// <param name="AName">结点名称</param>
    /// <param name="ANest">是否嵌套检查子结点</param>
    /// <returns>包含，返回true，否则，返回false</returns>
    function ContainsName(AName: QStringW; ANest: Boolean = False): Boolean;
    /// <summary>判断是否包含指定名称的子结点</summary>
    /// <param name="AValue">结点值</param>
    /// <param name="ANest">是否嵌套检查子结点</param>
    /// <param name="AStrict">是否严格要求类型匹配</param>
    /// <returns>包含，返回true，否则，返回false</returns>
    function ContainsValue(const AValue: Variant; ANest: Boolean = False;
      AStrict: Boolean = False): Boolean;
    /// <summary>判断是否包含指定路径的子结点</summary>
    /// <param name="APath">要查找的结点名称</param>
    /// <returns>包含，返回true，失败，返回false</returns>
    /// <remarks>此函数等价于ItemByPath(APath)<>nil</remarks>
    function Exists(const APath: QStringW): Boolean; inline;
    /// <summary>重置各项的值为默认状态</summary>
    /// <param name="ADetach">是否从父结点中移除自己</param>
    procedure Reset(ADetach: Boolean); virtual;

    // 下面的方法是为了方便流式管理加入
    class procedure WriteInt(AStream: TStream; AValue: Int64);
    class procedure WriteFloat(AStream: TStream; AValue: Double);
    class procedure WriteSingle(AStream: TStream; AValue: Single);
    class procedure WriteBool(AStream: TStream; AValue: Boolean);
    class procedure WriteString(AStream: TStream; AValue: QStringW);
    class procedure WriteDateTime(AStream: TStream; AValue: TDateTime;
      ADateTimeAsTimeStamp: Boolean);
    class procedure WriteBytes(AStream: TStream; const ABytes: TBytes);
      overload;
    class procedure WriteBytes(AStream: TStream; const p: PByte;
      const l: Integer); overload;
    class procedure WriteNull(AStream: TStream);
    class procedure WriteMap(AStream: TStream; const ACount: Integer);
    class procedure WriteArray(AStream: TStream; const ACount: Integer);
    class procedure WriteExt(AStream: TStream; AType: Byte; const p: PByte;
      const l: Integer);
    /// <summary>父结点</summary>
    property Parent: TQMsgPack read FParent;
    /// <summary>键类型</summary>
    property KeyType: TQMsgPackType read FKeyType;
    /// <summary>键作为字符串类型来访问</summary>
    property KeyAsString: QStringW read GetKeyAsString write SetKeyAsString;
    /// <summary>键作为64位整数类型来访问</summary>
    property KeyAsInt64: Int64 read GetKeyAsInt64 write SetKeyAsInt64;
    /// <summary>键作为整数类型来访问，实际内容调用了AsInt64</summary>
    property KeyAsInteger: Integer read GetKeyAsInteger write SetKeyAsInteger;
    /// <summary>键作为单精度浮点数来访问</summary>
    property KeyAsSingle: Single read GetKeyAsSingle write SetKeyAsSingle;
    /// <summary>键作为双精度浮点数来访问</summary>
    property KeyAsFloat: Double read GetKeyAsFloat write SetKeyAsFloat;
    /// <summary>键作为日期时间类型来访问</summary>
    property KeyAsDateTime: TDateTime read GetKeyAsDateTime
      write SetKeyAsDateTime;
    /// <summary>键作为二进制类型来访问</summary>
    property KeyAsBytes: TBytes read GetKeyAsBytes write SetKeyAsBytes;
    /// <summary>键作为布尔类型来访问</summary>
    property KeyAsBoolean: Boolean read GetKeyAsBoolean write SetKeyAsBoolean;
    /// <summary>键是否为空</summary>
    property KeyIsNull: Boolean read GetKeyIsNull;
    /// <summary>
    /// 结点类型
    /// </summary>
    property DataType: TQMsgPackType read FDataType write SetDataType;
    /// <summary>结点名称</summary>
    property Name: QStringW read GetKeyAsString write SetKeyAsString;
    /// <summary>
    /// 子结点数量
    /// </summary>
    property Count: Integer read GetCount;
    /// <summary>子结点数组</summary>
    property Items[AIndex: Integer]: TQMsgPack read GetItems; default;
    /// <summary>子结点的值</summary>
    property Value: QStringW read GetValue;
    /// <summary>判断是否是NULL类型</summary>
    property IsNull: Boolean read GetIsNull;
    /// <summary>判断是否是数字类型</summary>
    property IsNumeric: Boolean read GetIsNumeric;
    property IsOrdType: Boolean read GetIsOrdType;
    /// <summary>判断是否是日期时间类型</summary>
    property IsDateTime: Boolean read GetIsDateTime;
    /// <summary>判断是否是字符串类型</summary>
    property IsString: Boolean read GetIsString;
    /// <summary>判断是否是对象</summary>
    property IsObject: Boolean read GetIsObject;
    /// <summary>判断是否是数组</summary>
    property IsArray: Boolean read GetIsArray;
    /// <summary>将当前结点当作布尔类型访问</summary>
    property AsBoolean: Boolean read GetAsBoolean write SetAsBoolean;
    /// <summary>将当前结点作为字节流来访问</summary>
    property AsBytes: TBytes read GetAsBytes write SetAsBytes;
    /// <summary>将当前结点当作整数类型来访问</summary>
    property AsInteger: Integer read GetAsInteger write SetAsInteger;
    /// <summary>将当前结点当作64位整数类型来访问</summary>
    property AsInt64: Int64 read GetAsInt64 write SetAsInt64;
    /// <summary>将当前结点当作双浮点类型来访问</summary>
    property AsFloat: Double read GetAsFloat write SetAsFloat;
    /// <summary>将当前结点当作单精度浮点类型来访问</summary>
    property AsSingle: Single read GetAsSingle write SetAsSingle;
    /// <summary>将当前结点当作日期时间类型来访问</summary>
    property AsDateTime: TDateTime read GetAsDateTime write SetAsDateTime;
    /// <summary>将当前结点当作字符串类型访问</summary>
    property AsString: QStringW read GetAsString write SetAsString;
    /// <summary>将自己当做Variant类型来访问</summary>
    property AsVariant: Variant read GetAsVariant write SetAsVariant;
    /// <summary>将自己当做MsgPack序列来访问</summary>
    property AsMsgPack: TBytes read GetAsMsgPack write SetAsMsgPack;
    /// <summary>将自己当做扩展对象来访问</summary>
    property AsExtBytes: TBytes read GetAsExtBytes write SetExtBytes;
    // <summary>额外的附加数据成员，供用户关联附加内容</summary>
    property AsJson: QStringW read GetAsJson;
    /// 用户自定义的附加数据指针，用于关联用户自定义的数据内容。
    property Data: Pointer read FData write FData;
    /// <summary>
    /// 结点的路径，路径中间以&quot;./\\&quot;分隔，具体取值取决于全局的
    /// QMsgPackPathDelimiter 变量的值。
    /// </summary>
    property Path: QStringW read GetPath;
    /// <summary>在父结点中的索引顺序，从0开始，如果是-1，则代表自己是根结点</summary>
    property ItemIndex: Integer read GetItemIndex;
    /// <summary>名称哈希值</summary>
    property NameHash: Cardinal read FKeyHash;
    /// <summary>扩展类型</summary>
    property ExtType: Shortint read FExtType write SetExtType;
    property IgnoreCase: Boolean read FIgnoreCase write SetIgnoreCase;
    property Root: TQMsgPack read GetRoot;
  end;

  TQHashedMsgPack = class(TQMsgPack)
  protected
    FHashTable: TQHashTable;
    function CreateItem: TQMsgPack; override;
    procedure Replace(AIndex: Integer; ANewItem: TQMsgPack); override;
    procedure DoNodeNameChanged(ANode: TQMsgPack); override;
    procedure DoParsed; override;
    function CreateNew: TQMsgPack; override;
    procedure DoNodeMoved(ANode: TQMsgPack); override;
    function GetHashTable: TQHashTable;
    property HashTable: TQHashTable read GetHashTable;
  public
    constructor Create; overload;
    destructor Destroy; override;
    procedure Assign(ANode: TQMsgPack); override;
    function IndexOf(const AName: QStringW): Integer; override;
    function ItemByName(AName: QStringW): TQMsgPack; overload; override;
    function Remove(AIndex: Integer): TQMsgPack; override;
    procedure Clear; override;
  end;

  /// <summary>用于外部支持对象池的函数，创建一个新的TQMsgPack对象，注意从池中创建的对象</summary>
  /// <returns>返回新创建的TQMsgPack对象</returns>
  TQMsgPackCreateEvent = function: TQMsgPack;
  /// <summary>用于外部将对象缓存，以便重用对象</summary>
  /// <param name="AObj">要释放的MsgPack对象</param>
  TQMsgPackFreeEvent = procedure(AObj: TQMsgPack);

var
  /// <summary>日期类型转换为字符串时，这个变量控制如何格式化</summary>
  MsgPackDateFormat: QStringW;
  /// <summary>时间类型转换为字符串时，这个变量控制如何格式化</summary>
  MsgPackTimeFormat: QStringW;
  /// <summary>日期时间类型转换为字符串时，这个变量控制如何格式化</summary>
  MsgPackDateTimeFormat: QStringW;
  /// <summary>在ItemByName/ItemByPath/ValueByName/ValueByPath等函数的判断中，是否区分名称大小写</summary>
  MsgPackCaseSensitive: Boolean;
  /// <summary>指定如何处理RTTI中的枚举和集合类型</summary>
  MsgPackRttiEnumAsInt: Boolean;
  /// 在需要新建一个TQMsgPack对象时触发
  OnQMsgPackCreate: TQMsgPackCreateEvent;
  /// 在需要释放一个TQMsgPack对象时触发
  OnQMsgPackFree: TQMsgPackFreeEvent;
  QMsgPackPathDelimiter: QCharW = '\';

implementation

resourcestring

  SNotArrayOrMap = '%s 不是映射或数组。';
  SUnsupportArrayItem = '添加的动态数组第%d个元素类型不受支持。';
  SBadMsgPackArray = '%s 不是一个有效的MsgPack数组定义。';
  SBadMsgPackName = '%s 不是一个有效的MsgPack名称。';
  SBadConvert = '%s 不是一个有效的 %s 类型的值。';
  SVariantNotSupport = '不支持转换为Variant类型。';
  SNotSupport = '函数 [%s] 在当前开发环境下不受支持。';
  SReservedExtType = '<0的扩展类型被标准声明为保留不可用。';
  SReplaceTypeNeed = '替换结点的类型要求是 %s 或其子类。';
  SParamMissed = '参数 %s 同名的结点未找到。';
  SMethodMissed = '指定的函数 %s 不存在。';
  SMissRttiTypeDefine =
    '无法找到 %s 的RTTI类型信息，尝试将对应的类型单独定义(如array[0..1] of Byte改为TByteArr=array[0..1]，然后用TByteArr声明)。';
  SUnsupportPropertyType = '不支持的属性类型';
  SUnsupportValueType = 'TValue不支持二进制或扩展类型.';
  SArrayTypeMissed = '未知的数组元素类型。';
  SMapNameMissed = '映射名称未找到，无效和MessagePack格式？';
  SCantAttachToSelf = '不允许自己附加为自己的子结点。';
  SCanAttachToNoneContainer = '不能将结点附加到非数组和映射类型的结点下。';
  SCantAttachNoNameNodeToObject = '不能将未命名的结点做为映射类型的子结点。';
  SNodeNameExists = '指定的父结点下已经存在名为 %s 的子结点。';
  SCantMoveToChild = '不能将自己移动到自己的子结点下面';
  SUnsupportVarType = '不支持的变体类型 %d 。';
  SRttiComplexArrayNow = 'QMsgPack暂时不支持复杂类型做为动态数组子元素的参数';

type

  TQMsgPackValue = packed record
    ValueType: Byte;
    case Integer of
      0:
        (U8Val: Byte);
      1:
        (I8Val: Shortint);
      2:
        (U16Val: Word);
      3:
        (I16Val: Smallint);
      4:
        (U32Val: Cardinal);
      5:
        (I32Val: Integer);
      6:
        (U64Val: UInt64);
      7:
        (I64Val: Int64);
      8:
        (F32Val: Single);
      9:
        (F64Val: Double);
      10:
        (BArray: array [0 .. 16] of Byte);
  end;

const
  MsgPackTypeName: array [0 .. 10] of QStringW = ('Unknown', 'Integer', 'Null',
    'Boolean', 'Float', 'String', 'Binary', 'Array', 'Map', 'Extended',
    'DateTime');

function DoCompareName(Item1, Item2: Pointer): Integer;
var
  AIgnoreCase: Boolean;
  AItem1, AItem2: TQMsgPack;
begin
  AItem1 := Item1;
  AItem2 := Item2;
  AIgnoreCase := AItem1.IgnoreCase;
  if AIgnoreCase <> AItem2.IgnoreCase then
    AIgnoreCase := False;
  Result := StrCmpW(PWideChar(AItem1.Name), PWideChar(AItem2.Name),
    AIgnoreCase);
end;

function DoCompareValueBoolean(Item1, Item2: Pointer): Integer;
var
  AItem1, AItem2: TQMsgPack;
begin
  AItem1 := Item1;
  AItem2 := Item2;
  if AItem1.IsNull then
  begin
    if not AItem2.IsNull then
      Result := -1
    else
      Result := 0;
  end
  else
  begin
    if AItem2.IsNull then
      Result := 1
    else
      Result := Integer(AItem1.AsBoolean) - Integer(AItem2.AsBoolean);
  end;
end;

function DoCompareValueDateTime(Item1, Item2: Pointer): Integer;
var
  AItem1, AItem2: TQMsgPack;
begin
  AItem1 := Item1;
  AItem2 := Item2;
  if AItem1.IsNull then
  begin
    if AItem2.IsNull then
      Result := 0
    else
      Result := -1;
  end
  else
  begin
    if AItem2.IsNull then
      Result := 1
    else
      Result := CompareValue(AItem1.AsDateTime, AItem2.AsDateTime);
  end;
end;

function DoCompareValueFloat(Item1, Item2: Pointer): Integer;
var
  AItem1, AItem2: TQMsgPack;
begin
  AItem1 := Item1;
  AItem2 := Item2;
  if AItem1.IsNull then
  begin
    if AItem2.IsNull then
      Result := 0
    else
      Result := -1;
  end
  else
  begin
    if AItem2.IsNull then
      Result := 1
    else
      Result := CompareValue(AItem1.AsFloat, AItem2.AsFloat);
  end;
end;

function DoCompareValueInt(Item1, Item2: Pointer): Integer;
var
  AItem1, AItem2: TQMsgPack;
begin
  AItem1 := Item1;
  AItem2 := Item2;
  if AItem1.IsNull then
  begin
    if AItem2.IsNull then
      Result := 0
    else
      Result := -1;
  end
  else
  begin
    if AItem2.IsNull then
      Result := 1
    else
      Result := CompareValue(AItem1.AsInt64, AItem2.AsInt64);
  end;
end;

function DoCompareValueString(Item1, Item2: Pointer): Integer;
var
  AIgnoreCase: Boolean;
  AItem1, AItem2: TQMsgPack;
begin
  AItem1 := Item1;
  AItem2 := Item2;
  AIgnoreCase := AItem1.IgnoreCase;
  if AIgnoreCase <> AItem2.IgnoreCase then
    AIgnoreCase := False;
  Result := StrCmpW(PWideChar(AItem1.AsString), PWideChar(AItem2.AsString),
    AIgnoreCase);
end;

function DoCompareValueBinary(Item1, Item2: Pointer): Integer;
var
  AItem1, AItem2: TQMsgPack;
  L1, L2: Integer;
begin
  AItem1 := Item1;
  AItem2 := Item2;
  if AItem1.IsNull then
  begin
    if AItem2.IsNull then
      Result := 0
    else
      Result := -1;
  end
  else
  begin
    if AItem2.IsNull then
      Result := 1
    else
    begin
      L1 := Length(AItem1.FValue);
      L2 := Length(AItem2.FValue);
      if L1 > L2 then
      begin
        Result := BinaryCmp(@AItem1.FValue[0], @AItem2.FValue[0], L2);
        if Result = 0 then
          Result := 1;
      end
      else if L1 < L2 then
      begin
        Result := BinaryCmp(@AItem1.FValue[0], @AItem2.FValue[0], L2);
        if Result = 0 then
          Result := -1;
      end
      else
        Result := BinaryCmp(@AItem1.FValue[0], @AItem2.FValue[0], L2);
    end;
  end;
end;
{ TQMsgPack }

constructor TQMsgPack.Create;
begin
  inherited;
  FIgnoreCase := not MsgPackCaseSensitive;
end;

constructor TQMsgPack.Create(const AName: QStringW; ADataType: TQMsgPackType);
begin
  inherited Create;
  FIgnoreCase := not MsgPackCaseSensitive;
  DataType := ADataType;
  KeyAsString := AName;
end;

function TQMsgPack.CreateItem: TQMsgPack;
begin
  if Assigned(OnQMsgPackCreate) then
    Result := OnQMsgPackCreate
  else
    Result := CreateNew;
end;

function TQMsgPack.CreateNew: TQMsgPack;
begin
  Result := TQMsgPack.Create;
end;

function TQMsgPack.DateTimeByName(AName: QStringW; ADefVal: TDateTime)
  : TDateTime;
var
  AChild: TQMsgPack;
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

function TQMsgPack.DateTimeByPath(APath: QStringW; ADefVal: TDateTime)
  : TDateTime;
var
  AItem: TQMsgPack;
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

procedure TQMsgPack.Delete(AName: QStringW);
var
  I: Integer;
begin
  I := IndexOf(AName);
  if I <> -1 then
    Delete(I);
end;

procedure TQMsgPack.Delete(AIndex: Integer);
var
  AItem: TQMsgPack;
begin
  if FDataType in [mptArray, mptMap] then
  begin
    AItem := Remove(AIndex);
    FreeItem(AItem);
  end
  else
    raise Exception.Create(Format(SNotArrayOrMap, [KeyAsString]));
end;

procedure TQMsgPack.DeleteIf(const ATag: Pointer; ANest: Boolean;
  AFilter: TQMsgPackFilterEvent);
  procedure DeleteChildren(AParent: TQMsgPack);
  var
    I: Integer;
    Accept: Boolean;
    AChild: TQMsgPack;
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
{$IFDEF UNICODE}

procedure TQMsgPack.DeleteIf(const ATag: Pointer; ANest: Boolean;
  AFilter: TQMsgPackFilterEventA);
  procedure DeleteChildren(AParent: TQMsgPack);
  var
    I: Integer;
    Accept: Boolean;
    AChild: TQMsgPack;
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
{$ENDIF UNICODE}

destructor TQMsgPack.Destroy;
begin
  if DataType in [mptArray, mptMap] then
  begin
    Clear;
    FreeObject(FItems);
  end;
  inherited;
end;

procedure TQMsgPack.Detach;
begin
  if Assigned(FParent) then
    FParent.Remove(Self);
end;

procedure TQMsgPack.DoNodeMoved(ANode: TQMsgPack);
begin

end;

procedure TQMsgPack.DoNodeNameChanged(ANode: TQMsgPack);
begin
  FKeyHash := 0;
end;

procedure TQMsgPack.DoParsed;
begin

end;

function TQMsgPack.Add(const AName: QStringW; AItems: array of const)
  : TQMsgPack;
var
  I: Integer;
begin
  Result := Add(AName, mptArray);
  for I := Low(AItems) to High(AItems) do
  begin
    case AItems[I].VType of
      vtInteger:
        Result.Add.AsInteger := AItems[I].VInteger;
      vtBoolean:
        Result.Add.AsBoolean := AItems[I].VBoolean;
{$IFNDEF NEXTGEN}
      vtChar:
        Result.Add.AsString := QStringW(AItems[I].VChar);
{$ENDIF !NEXTGEN}
      vtExtended:
        Result.Add.AsFloat := AItems[I].VExtended^;
{$IFNDEF NEXTGEN}
      vtPChar:
        Result.Add.AsString := QStringW(AItems[I].VPChar);
      vtString:
        Result.Add.AsString := QStringW(AItems[I].VString^);
      vtAnsiString:
        Result.Add.AsString := QStringW(
{$IFDEF UNICODE}
          PAnsiString(AItems[I].VAnsiString)^
{$ELSE}
          AItems[I].VPChar
{$ENDIF UNICODE}
          );
      vtWideString:
        Result.Add.AsString := PWideString(AItems[I].VWideString)^;
{$ENDIF !NEXTGEN}
      vtPointer:
        Result.Add.AsInt64 := IntPtr(AItems[I].VPointer);
      vtWideChar:
        Result.Add.AsString := AItems[I].VWideChar;
      vtPWideChar:
        Result.Add.AsString := AItems[I].VPWideChar;
      vtCurrency:
        Result.Add.AsFloat := AItems[I].VCurrency^;
      vtInt64:
        Result.Add.AsInt64 := AItems[I].VInt64^;
{$IFDEF UNICODE}       // variants
      vtUnicodeString:
        Result.Add.AsString := AItems[I].VPWideChar;
{$ENDIF UNICODE}
      vtVariant:
        Result.Add.AsVariant := AItems[I].VVariant^;
      vtObject:
        begin
          if TObject(AItems[I].VObject) is TQMsgPack then
            Result.Add(TObject(AItems[I].VObject) as TQMsgPack)
          else
            raise Exception.Create(Format(SUnsupportArrayItem, [I]));
        end
    else
      raise Exception.Create(Format(SUnsupportArrayItem, [I]));
    end; // End case
  end; // End for
end;

function TQMsgPack.Add(AName: QStringW; ADataType: TQMsgPackType): TQMsgPack;
begin
  Result := Add(AName);
  Result.DataType := ADataType;
end;

function TQMsgPack.Add: TQMsgPack;
begin
  ArrayNeeded(mptMap);
  Result := CreateItem;
  Result.FParent := Self;
  Result.FIgnoreCase := IgnoreCase;
  FItems.Add(Result);
end;

function TQMsgPack.Add(AName: QStringW; AValue: Boolean): TQMsgPack;
begin
  Result := Add(AName);
  Result.AsBoolean := AValue;
end;

function TQMsgPack.Add(AName: QStringW): TQMsgPack;
begin
  Result := Add;
  Result.KeyAsString := AName;
end;

function TQMsgPack.AddArray(AName: QStringW): TQMsgPack;
begin
  Result := Add(AName, mptArray);
end;

function TQMsgPack.Add(AName: QStringW; const AValue: TBytes): TQMsgPack;
begin
  Result := Add(AName);
  Result.DataType := mptBinary;
  Result.FValue := AValue;
end;

function TQMsgPack.Add(AName, AValue: QStringW): TQMsgPack;
begin
  Result := Add(AName);
  Result.AsString := AValue;
end;

function TQMsgPack.Add(AName: QStringW; AValue: Double): TQMsgPack;
begin
  Result := Add(AName);
  Result.AsFloat := AValue;
end;

function TQMsgPack.Add(AName: QStringW; AValue: Int64): TQMsgPack;
begin
  Result := Add(AName);
  Result.AsInt64 := AValue;
end;

function TQMsgPack.Add(ANode: TQMsgPack): Integer;
begin
  ArrayNeeded(mptArray);
  ANode.FParent := Self;
  Result := FItems.Add(ANode);
end;

function TQMsgPack.AddDateTime(AName: QStringW; AValue: TDateTime): TQMsgPack;
begin
  Result := Add(AName);
  Result.AsDateTime := AValue;
end;

procedure TQMsgPack.ArrayNeeded(ANewType: TQMsgPackType);
begin
  if not(DataType in [mptArray, mptMap]) then
    DataType := ANewType;
end;

procedure TQMsgPack.Assign(ANode: TQMsgPack);
var
  I: Integer;
  AItem, ACopy: TQMsgPack;
begin
  if ANode.FDataType in [mptArray, mptMap] then
  begin
    DataType := ANode.FDataType;
    if Count > 0 then
      Clear;
    for I := 0 to ANode.Count - 1 do
    begin
      AItem := ANode[I];
      if Length(AItem.FKey) > 0 then
      begin
        ACopy := InternalAdd(AItem.FKey, AItem.KeyType, AItem.DataType);
        ACopy.FKeyHash := AItem.FKeyHash;
      end
      else
        ACopy := Add;
      ACopy.Assign(AItem);
    end;
  end
  else
    CopyValue(ANode);
end;

procedure TQMsgPack.AttachTo(ANewParent: TQMsgPack);
begin
  MoveTo(ANewParent, MaxInt);
end;

procedure TQMsgPack.Clear;
var
  I: Integer;
begin
  if FDataType in [mptArray, mptMap] then
  begin
    for I := 0 to Count - 1 do
      FreeItem(FItems[I]);
    FItems.Clear;
  end;
end;

function TQMsgPack.Clone: TQMsgPack;
begin
  Result := Copy;
end;

function TQMsgPack.ContainsName(AName: QStringW; ANest: Boolean): Boolean;
var
  I, H: Integer;
  AItem: TQMsgPack;
begin
  Result := ItemByName(AName) <> nil;
  if (not Result) and ANest then
  begin
    H := Count - 1;
    for I := 0 to H do
    begin
      AItem := Items[I];
      if AItem.DataType = mptMap then
      begin
        Result := Items[I].ContainsName(AName, ANest);
        if Result then
          Break;
      end;
    end;
  end;
end;

function TQMsgPack.ContainsValue(const AValue: Variant;
  ANest, AStrict: Boolean): Boolean;
var
  I, H: Integer;
  AItem: TQMsgPack;
  function CompareValue: Boolean;
  var
    b: PByte;
  begin
    if AItem.DataType in [mptUnknown, mptNull] then
      Result := VarIsNull(AValue)
    else if AStrict then
    begin
      if AItem.DataType = mptString then
        Result := StrCmpW(PWideChar(AItem.AsString),
          PWideChar({$IFNDEF UNICODE}QStringW({$ENDIF}VarToStr
          (AValue){$IFNDEF UNICODE}){$ENDIF}), IgnoreCase) = 0
      else if (AItem.DataType in [mptInteger, mptSingle, mptFloat, mptBoolean])
        and VarIsNumeric(AValue) then
        Result := (AItem.AsVariant = AValue)
      else if (AItem.DataType = mptDateTime) and
        (FindVarData(AValue)^.VType = varDate) then
        Result := SameValue(AItem.AsDateTime, VarToDateTime(AValue))
      else if (AItem.DataType = mptBinary) and VarIsArray(AValue) then
      begin
        b := VarArrayLock(AValue);
        try
          if Length(AItem.FValue) = VarArrayHighBound(AValue, 1) -
            VarArrayLowBound(AValue, 1) + 1 then
            Result := CompareMem(@AItem.FValue[0], b, Length(AItem.FValue))
          else
            Result := False;
        finally
          VarArrayUnlock(AValue);
        end;
      end
      else
        Result := False;
    end
    else
      Result := AItem.AsString = VarToStr(AValue);
  end;

begin
  H := Count - 1;
  Result := False;
  for I := 0 to H do
  begin
    AItem := Items[I];
    if (not(AItem.DataType in [mptMap, mptArray])) and CompareValue then
    begin
      Result := True;
      Exit;
    end;
  end;
  if ANest then
  begin
    for I := 0 to H do
    begin
      AItem := Items[I];
      if AItem.DataType in [mptMap, mptArray] then
      begin
        Result := AItem.ContainsValue(AValue, ANest, AStrict);
        if Result then
          Exit;
      end;
    end;
  end;
end;

function TQMsgPack.Copy: TQMsgPack;
begin
  Result := CreateItem;
  Result.Assign(Self);
end;
{$IFDEF UNICODE}

function TQMsgPack.CopyIf(const ATag: Pointer; AFilter: TQMsgPackFilterEventA)
  : TQMsgPack;
  procedure NestCopy(AParentSource, AParentDest: TQMsgPack);
  var
    I: Integer;
    Accept: Boolean;
    AChildSource, AChildDest: TQMsgPack;
  begin
    for I := 0 to AParentSource.Count - 1 do
    begin
      Accept := True;
      AChildSource := AParentSource[I];
      AFilter(Self, AChildSource, Accept, ATag);
      if Accept then
      begin
        AChildDest := AParentDest.InternalAdd(AChildSource.FKey,
          AChildSource.KeyType, AChildSource.DataType);
        if AChildSource.DataType in [mptArray, mptMap] then
        begin
          AChildDest.DataType := AChildSource.DataType;
          NestCopy(AChildSource, AChildDest)
        end
        else
          AChildDest.CopyValue(AChildSource);
      end;
    end;
  end;

begin
  if Assigned(AFilter) then
  begin
    Result := InternalAdd(FKey, KeyType, DataType);
    if DataType in [mptArray, mptMap] then
    begin
      NestCopy(Self, Result);
    end
    else
      Result.CopyValue(Self);
  end
  else
    Result := Copy;
end;
{$ENDIF UNICODE}

function TQMsgPack.CopyIf(const ATag: Pointer; AFilter: TQMsgPackFilterEvent)
  : TQMsgPack;
  procedure NestCopy(AParentSource, AParentDest: TQMsgPack);
  var
    I: Integer;
    Accept: Boolean;
    AChildSource, AChildDest: TQMsgPack;
  begin
    for I := 0 to AParentSource.Count - 1 do
    begin
      Accept := True;
      AChildSource := AParentSource[I];
      AFilter(Self, AChildSource, Accept, ATag);
      if Accept then
      begin
        AChildDest := AParentDest.InternalAdd(AChildSource.FKey,
          AChildSource.KeyType, AChildSource.DataType);
        if AChildSource.DataType in [mptArray, mptMap] then
        begin
          AChildDest.DataType := AChildSource.DataType;
          NestCopy(AChildSource, AChildDest)
        end
        else
          AChildDest.CopyValue(AChildSource);
      end;
    end;
  end;

begin
  if Assigned(AFilter) then
  begin
    Result := InternalAdd(FKey, KeyType, DataType);
    if DataType in [mptArray, mptMap] then
    begin
      NestCopy(Self, Result);
    end
    else
      Result.CopyValue(Self);
  end
  else
    Result := Copy;
end;

procedure TQMsgPack.CopyValue(ASource: TQMsgPack);
var
  l: Integer;
begin
  l := Length(ASource.FValue);
  DataType := ASource.DataType;
  if DataType in [mptString, mptBinary, mptExtended] then
    SetLength(FValue, l);
  if l > 0 then
  begin
    if not(DataType in [mptUnknown, mptNull, mptArray, mptMap]) then
      Move(ASource.FValue[0], FValue[0], l);
  end;
end;

function TQMsgPack.Encode: TBytes;
var
  AStream: TMemoryStream;
begin
  AStream := TMemoryStream.Create;
  AStream.Size := 16384;
  try
    InternalEncode(Self, AStream, False);
    SetLength(Result, AStream.Position);
    if Length(Result) > 0 then
      Move(PByte(AStream.Memory)^, Result[0], Length(Result));
  finally
    FreeObject(AStream);
  end;
end;

function TQMsgPack.EncodeAsString(AStrictJson: Boolean): QStringW;
  function EncodeDateTime(AItem: TQMsgPack): QStringW;
  var
    AValue: TDateTime;
  begin
    AValue := AItem.AsDateTime;
    if SameValue(AValue - Trunc(AValue), 0) then // Date
      Result := FormatDateTime(MsgPackDateFormat, AValue)
    else
    begin
      if Trunc(AValue) = 0 then
        Result := FormatDateTime(MsgPackTimeFormat, AValue)
      else
        Result := FormatDateTime(MsgPackDateTimeFormat, AValue);
    end;
    if AStrictJson then
      Result := '"' + Result + '"';
  end;

  function EncodeExtended(AItem: TQMsgPack): QStringW;
  begin
    if AStrictJson then
      Result := '{"TypeId":' + IntToStr(AItem.FExtType) + ',"Data":"' +
        qstring.BinToHex(@AItem.FValue[0], Length(AItem.FValue)) + '"}'
    else
      Result := '{TypeId:' + IntToStr(AItem.FExtType) + ',Data:' +
        qstring.BinToHex(@AItem.FValue[0], Length(AItem.FValue)) + '}';
  end;

  function EncodeBaseType(AItem: TQMsgPack): QStringW;
  begin
    case AItem.DataType of
      mptString:
        begin
          if AStrictJson then
          begin
            if Length(AItem.FValue) = 0 then
              Result := '""'
            else
              Result := '"' + JavaEscape(StrDupX(@AItem.FValue[0],
                Length(AItem.FValue) shr 1), False) + '"';
          end
          else
          begin
            if Length(AItem.FValue) = 0 then
              SetLength(Result, 0)
            else
              Result := StrDupX(@AItem.FValue[0], Length(AItem.FValue) shr 1);
          end;
        end;
      mptUnknown, mptNull:
        begin
          if AStrictJson then
            Result := 'null'
          else
            SetLength(Result, 0);
        end;
      mptInteger:
        Result := IntToStr(AItem.AsInt64);
      mptBoolean:
        Result := BoolToStr(AItem.AsBoolean);
      mptFloat:
        Result := FloatToStrF(AItem.AsFloat, ffGeneral, 15, 0);
      mptSingle:
        Result := FloatToStrF(AItem.AsSingle, ffGeneral, 7, 0);
      mptBinary:
        begin
          if AStrictJson then
            Result := '"' + qstring.BinToHex(@AItem.FValue[0],
              Length(AItem.FValue)) + '"'
          else
            Result := qstring.BinToHex(@AItem.FValue[0], Length(AItem.FValue));
        end;
      mptDateTime:
        Result := EncodeDateTime(AItem);
      mptExtended:
        Result := EncodeExtended(AItem)
    else // 不应该执行到
      SetLength(Result, 0);
    end;
  end;

  procedure InternalEncode(ABuilder: TQStringCatHelperW; AParent: TQMsgPack);
  const
    ArrayStart: PWideChar = '[';
    ArrayEnd: PWideChar = ']';
    ArrayDelim: PWideChar = ',';
    MapStart: PWideChar = '{';
    MapEnd: PWideChar = '}';
    MapDelim: PWideChar = ',';
    MapValueDelim: PWideChar = ':';
    MapEmptyName: PWideChar = '" "';
    MapStrStart: PWideChar = '"';
  var
    AFreeNeeded: Boolean;
    I, C: Integer;
    AItem: TQMsgPack;
  begin
    AFreeNeeded := not Assigned(ABuilder);
    if AFreeNeeded then
      ABuilder := TQStringCatHelperW.Create;
    try
      C := AParent.Count;
      Dec(C);
      if AParent.DataType = mptArray then
      begin
        ABuilder.Cat(ArrayStart, 1);
        for I := 0 to C do
        begin
          InternalEncode(ABuilder, AParent[I]);
          ABuilder.Cat(ArrayDelim, 1);
        end;
        if C >= 0 then
          ABuilder.Back(1);
        ABuilder.Cat(ArrayEnd, 1);
      end
      else if AParent.DataType = mptMap then
      begin
        ABuilder.Cat(MapStart, 1);
        for I := 0 to C do
        begin
          AItem := AParent[I];
          if Length(AItem.Name) > 0 then
          begin
            if AStrictJson then
              ABuilder.Cat(MapStrStart).Cat(JavaEscape(AItem.Name, False))
                .Cat(MapStrStart)
            else
              ABuilder.Cat(AItem.Name);
            ABuilder.Cat(MapValueDelim, 1);
          end
          else if AStrictJson then
            ABuilder.Cat(MapEmptyName).Cat(MapValueDelim, 1);
          InternalEncode(ABuilder, AItem);
          ABuilder.Cat(MapDelim, 1);
        end;
        if C >= 0 then
          ABuilder.Back(1);
        ABuilder.Cat(MapEnd, 1);
      end
      else
        ABuilder.Cat(EncodeBaseType(AParent));
    finally
      if AFreeNeeded then
      begin
        Result := ABuilder.Value;
        FreeObject(ABuilder);
      end;
    end;
  end;

begin
  if DataType in [mptArray, mptMap] then
    InternalEncode(nil, Self)
  else
    Result := EncodeBaseType(Self);
end;

procedure TQMsgPack.ExchangeOrder(AIndex1, AIndex2: Integer);
begin
  FItems.Exchange(AIndex1, AIndex2);
end;

function TQMsgPack.Exists(const APath: QStringW): Boolean;
begin
  Result := ItemByPath(APath) <> nil;
end;

procedure TQMsgPack.FileFromValue(AFileName: QStringW);
var
  AStream: TFileStream;
begin
  AStream := TFileStream.Create(AFileName, fmCreate);
  try
    StreamFromValue(AStream);
  finally
    FreeObject(AStream);
  end;
end;

function TQMsgPack.FindIf(const ATag: Pointer; ANest: Boolean;
  AFilter: TQMsgPackFilterEvent): TQMsgPack;
  function DoFind(AParent: TQMsgPack): TQMsgPack;
  var
    I: Integer;
    AChild: TQMsgPack;
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

function TQMsgPack.FloatByName(AName: QStringW; ADefVal: Extended): Extended;
var
  AChild: TQMsgPack;
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

function TQMsgPack.FloatByPath(APath: QStringW; ADefVal: Extended): Extended;
var
  AItem: TQMsgPack;
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

{$IFDEF UNICODE}

function TQMsgPack.FindIf(const ATag: Pointer; ANest: Boolean;
  AFilter: TQMsgPackFilterEventA): TQMsgPack;
  function DoFind(AParent: TQMsgPack): TQMsgPack;
  var
    I: Integer;
    AChild: TQMsgPack;
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
{$ENDIF UNICODE}

function TQMsgPack.ForcePath(APath: QStringW): TQMsgPack;
var
  AName: QStringW;
  p, pn, ws: PQCharW;
  AParent: TQMsgPack;
  l: Integer;
  AIndex: Int64;
const
  PathDelimiters: PWideChar = './\';
begin
  p := PQCharW(APath);
  AParent := Self;
  Result := Self;
  while p^ <> #0 do
  begin
    AName := DecodeTokenW(p, PathDelimiters, WideChar(0), True);
    if not(AParent.DataType in [mptArray, mptMap]) then
      AParent.DataType := mptMap;
    Result := AParent.ItemByName(AName);
    if not Assigned(Result) then
    begin
      pn := PQCharW(AName);
      l := Length(AName);
      AIndex := -1;
      if (pn[l - 1] = ']') then
      begin
        repeat
          if pn[l] = '[' then
          begin
            ws := pn + l + 1;
            if ParseInt(ws, AIndex) = 0 then
              AIndex := -1;
            Break;
          end
          else
            Dec(l);
        until l = 0;
        if l > 0 then
        begin
          AName := StrDupX(pn, l);
          Result := AParent.ItemByName(AName);
          if Result = nil then
            Result := AParent.Add(AName, mptArray)
          else if Result.DataType <> mptArray then
            raise Exception.CreateFmt(SBadMsgPackArray, [AName]);
          if AIndex >= 0 then
          begin
            while Result.Count <= AIndex do
              Result.Add;
            Result := Result[AIndex];
          end;
        end
        else
          raise Exception.CreateFmt(SBadMsgPackName, [AName]);
      end
      else if AParent.DataType = mptArray then
        Result := AParent.Add.Add(AName)
      else
        Result := AParent.Add(AName);
    end;
    AParent := Result;
  end;
end;

procedure TQMsgPack.FreeItem(AItem: TQMsgPack);
begin
  if Assigned(OnQMsgPackFree) then
  begin
    AItem.FParent := nil;
    OnQMsgPackFree(AItem);
  end
  else
    FreeObject(AItem);
end;

{$IF RTLVersion>=21}

procedure TQMsgPack.FromRecord<T>(const ARecord: T);
begin
  FromRtti(@ARecord, TypeInfo(T));
end;

procedure TQMsgPack.FromRtti(ASource: Pointer; AType: PTypeInfo);
var
  AValue: TValue;
  procedure AddCollection(AParent: TQMsgPack; ACollection: TCollection);
  var
    J: Integer;
  begin
    for J := 0 to ACollection.Count - 1 do
      AParent.Add.FromRtti(ACollection.Items[J]);
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
            Add(AFields[J].Name).AsInteger := AFields[J].GetValue(ASource)
              .AsInteger;
{$IFNDEF NEXTGEN}tkString, tkLString, tkWString,
{$ENDIF !NEXTGEN}tkUString:
            Add(AFields[J].Name).AsString :=
              AFields[J].GetValue(ASource).AsString;
          tkEnumeration:
            begin
              if GetTypeData(AFields[J].FieldType.Handle)
                .BaseType^ = TypeInfo(Boolean) then
                Add(AFields[J].Name).AsBoolean := AFields[J].GetValue(ASource)
                  .AsBoolean
              else if MsgPackRttiEnumAsInt then
                Add(AFields[J].Name).AsInt64 := AFields[J].GetValue(ASource)
                  .AsOrdinal
              else
                Add(AFields[J].Name).AsString :=
                  AFields[J].GetValue(ASource).ToString;
            end;
          tkSet:
            begin
              if MsgPackRttiEnumAsInt then
                // Add(AFields[J].Name).AsInteger := AFields[J].GetValue(ASource).AsInteger
                Add(AFields[J].Name).AsInt64 :=
                  SetAsOrd(AFields[J].GetValue(ASource))
              else
                Add(AFields[J].Name).AsString :=
                  AFields[J].GetValue(ASource).ToString;
            end;
          tkChar, tkWChar:
            Add(AFields[J].Name).AsString :=
              AFields[J].GetValue(ASource).ToString;
          tkFloat:
            begin
              if (AFields[J].FieldType.Handle = TypeInfo(TDateTime)) or
                (AFields[J].FieldType.Handle = TypeInfo(TTime)) or
                (AFields[J].FieldType.Handle = TypeInfo(TDate)) then
                Add(AFields[J].Name).AsDateTime := AFields[J].GetValue(ASource)
                  .AsExtended
              else
                Add(AFields[J].Name).AsFloat := AFields[J].GetValue(ASource)
                  .AsExtended;
            end;
          tkInt64:
            Add(AFields[J].Name).AsInt64 :=
              AFields[J].GetValue(ASource).AsInt64;
          tkVariant:
            Add(AFields[J].Name).AsVariant := AFields[J].GetValue(ASource)
              .AsVariant;
          tkArray, tkDynArray:
            begin
              with Add(AFields[J].Name, mptArray) do
              begin
                AValue := AFields[J].GetValue(ASource);
                for I := 0 to AValue.GetArrayLength - 1 do
                  Add.FromRtti(AValue.GetArrayElement(I));
              end;
            end;
          tkClass:
            begin
              AValue := AFields[J].GetValue(ASource);
              AObj := AValue.AsObject;
              if (AObj is TStrings) then
                Add(AFields[J].Name).AsString := TStrings(AObj).Text
              else if AObj is TCollection then
                AddCollection(Add(AFields[J].Name, mptArray),
                  AObj as TCollection)
              else // 其它类型的对象不保存
                Add(AFields[J].Name, mptMap)
                  .FromRtti(AObj, AFields[J].FieldType.Handle);
            end;
          tkRecord:
            begin
              DataType := mptMap;
              // AValue := AFields[J].GetValue(ASource);
              if AFields[J].FieldType.Handle = TypeInfo(TGuid) then
                Add(AFields[J].Name).AsString :=
                  GUIDToString
                  (PGuid(Pointer(IntPtr(ASource) + AFields[J].Offset))^)
              else
                Add(AFields[J].Name)
                  .FromRtti(Pointer(IntPtr(ASource) + AFields[J].Offset),
                  AFields[J].FieldType.Handle);
            end;
        end;
      end
      else
        raise Exception.CreateFmt(SMissRttiTypeDefine, [AFields[J].Name]);
    end;
  end;

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
      AsString := (AObj as TStrings).Text
    else if AObj is TCollection then
    begin
      DataType := mptArray;
      AddCollection(Self, AObj as TCollection);
    end
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
                    Add(AName).AsString := (AChildObj as TStrings).Text
                  else if AChildObj is TCollection then
                    AddCollection(Add(AName, mptArray),
                      AChildObj as TCollection)
                  else
                    Add(AName, mptMap).FromRtti(AChildObj);
                end;
              tkRecord, tkArray, tkDynArray: // 记录、数组、动态数组属性系统也不保存，也没提供所有太好的接口
                raise Exception.Create(SUnsupportPropertyType);
              tkInteger:
                Add(AName).AsInt64 := GetOrdProp(AObj, APropList[J]);
              tkFloat:
                begin
                  if (APropList[J].PropType^ = TypeInfo(TDateTime)) or
                    (APropList[J].PropType^ = TypeInfo(TTime)) or
                    (APropList[J].PropType^ = TypeInfo(TDate)) then
                  begin
                    // 判断一个数值是否是一个有效的值
                    Add(AName).AsDateTime := GetFloatProp(AObj, APropList[J]);
                  end
                  else
                    Add(AName).AsFloat := GetFloatProp(AObj, APropList[J]);
                end;
              tkChar, tkString, tkWChar, tkLString, tkWString, tkUString:
                Add(AName).AsString := GetStrProp(AObj, APropList[J]);
              tkEnumeration:
                begin
                  if GetTypeData(APropList[J]^.PropType^)
                    ^.BaseType^ = TypeInfo(Boolean) then
                    Add(AName).AsBoolean := GetOrdProp(AObj, APropList[J]) <> 0
                  else if MsgPackRttiEnumAsInt then
                    Add(AName).AsInteger := GetOrdProp(AObj, APropList[J])
                  else
                    Add(AName).AsString := GetEnumProp(AObj, APropList[J]);
                end;
              tkSet:
                if MsgPackRttiEnumAsInt then
                  Add(AName).AsInteger := GetOrdProp(AObj, APropList[J])
                else
                  Add(AName).AsString := GetSetProp(AObj, APropList[J], True);
              tkVariant:
                Add(AName).AsVariant := GetPropValue(AObj, APropList[J]);
              tkInt64:
                Add(AName).AsInt64 := GetInt64Prop(AObj, APropList[J]);
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
    I, C: Integer;
  begin
    DataType := mptArray;
    Clear;
    TValue.Make(ASource, AType, AValue);
    C := AValue.GetArrayLength;
    for I := 0 to C - 1 do
      Add.FromRtti(AValue.GetArrayElement(I));
  end;

begin
  if ASource = nil then
    Exit;
  case AType.Kind of
    tkRecord:
      AddRecord;
    tkClass:
      AddObject;
    tkDynArray:
      AddArray;
  end;
end;

procedure TQMsgPack.FromRtti(AInstance: TValue);
var
  I, C: Integer;
begin
  case AInstance.Kind of
    tkClass:
      FromRtti(AInstance.AsObject, AInstance.TypeInfo);
    tkRecord:
      FromRtti(AInstance.GetReferenceToRawData, AInstance.TypeInfo);
    tkArray, tkDynArray:
      begin
        DataType := mptArray;
        Clear;
        C := AInstance.GetArrayLength;
        for I := 0 to C - 1 do
          Add.FromRtti(AInstance.GetArrayElement(I));
      end;
    tkInteger:
      AsInt64 := AInstance.AsInt64;
    tkChar, tkString, tkWChar, tkLString, tkWString, tkUString:
      AsString := AInstance.ToString;
    tkEnumeration:
      begin
        if GetTypeData(AInstance.TypeInfo)^.BaseType^ = TypeInfo(Boolean) then
          AsBoolean := AInstance.AsBoolean
        else if MsgPackRttiEnumAsInt then
          AsInt64 := AInstance.AsOrdinal
        else
          AsString := AInstance.ToString;
      end;
    tkSet:
      begin
        if MsgPackRttiEnumAsInt then
          AsInt64 := AInstance.AsOrdinal
        else
          AsString := AInstance.ToString;
      end;
    tkVariant:
      AsVariant := AInstance.AsVariant;
    tkInt64:
      AsInt64 := AInstance.AsInt64;
  end;
end;
{$IFEND >=2010}

function TQMsgPack.BoolByName(AName: QStringW; ADefVal: Boolean): Boolean;
var
  AChild: TQMsgPack;
begin
  AChild := ItemByName(AName);
  if Assigned(AChild) then
  begin
    try
      Result := AChild.AsBoolean;
    except
      Result := ADefVal;
    end;
  end
  else
    Result := ADefVal;
end;

function TQMsgPack.BoolByPath(APath: QStringW; ADefVal: Boolean): Boolean;
var
  AItem: TQMsgPack;
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

function TQMsgPack.BoolToStr(v: Boolean): QStringW;
begin
  if v then
    Result := 'true'
  else
    Result := 'false';
end;

function TQMsgPack.BytesByPath(APath: QStringW; ADefVal: TBytes): TBytes;
var
  AItem: TQMsgPack;
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

procedure TQMsgPack.BytesFromFile(AFileName: QStringW);
var
  AStream: TMemoryStream;
begin
  AStream := TMemoryStream.Create;
  try
    AStream.LoadFromFile(AFileName);
    BytesFromStream(AStream, 0);
  finally
    FreeObject(AStream);
  end;
end;

procedure TQMsgPack.BytesFromStream(AStream: TStream; ACount: Integer);
begin
  DataType := mptBinary;
  if ACount = 0 then
  begin
    ACount := AStream.Size;
    AStream.Position := 0;
  end
  else
  begin
    if AStream.Size - AStream.Position < ACount then
      ACount := AStream.Size - AStream.Position;
  end;
  SetLength(FValue, ACount);
  AStream.ReadBuffer(FValue[0], ACount);
end;

procedure TQMsgPack.BytesToFile(AFileName: QStringW);
var
  AStream: TMemoryStream;
begin
  AStream := TMemoryStream.Create;
  try
    BytesToStream(AStream);
    AStream.SaveToFile(AFileName);
  finally
    FreeObject(AStream);
  end;
end;

procedure TQMsgPack.BytesToStream(AStream: TStream);
begin
  AStream.WriteBuffer(FValue[0], Length(FValue));
end;

function TQMsgPack.GetAsBoolean: Boolean;
begin
  if DataType = mptBoolean then
    Result := PBoolean(FValue)^
  else if DataType = mptString then
  begin
    if not TryStrToBool(AsString, Result) then
      raise Exception.Create(Format(SBadConvert, [AsString, 'Boolean']));
  end
  else if DataType in [mptFloat, mptDateTime] then
    Result := not SameValue(AsFloat, 0)
  else if DataType = mptSingle then
    Result := not SameValue(AsSingle, 0)
  else if DataType = mptInteger then
    Result := AsInt64 <> 0
  else if DataType in [mptNull, mptUnknown] then
    Result := False
  else
    raise Exception.Create(Format(SBadConvert,
      [MsgPackTypeName[Integer(DataType)], 'Boolean']));
end;

function TQMsgPack.GetAsBytes: TBytes;
begin
  Result := FValue;
end;

function TQMsgPack.GetAsDateTime: TDateTime;
  procedure FromTimeStamp;
  var
    T: Int64;
  begin
    if Length(FValue) = 4 then // 32位秒数
      Result := ExchangeByteOrder(PCardinal(@FValue[0])^) / 86400 +
        UnixDateDelta
    else if Length(FValue) = 8 then // 64位,30纳秒+34位秒数
    begin
      T := ExchangeByteOrder(PInt64(@FValue[0])^);
      Result := (T and Int64($3FFFFFFFF)) / 86400 + (T shr 34) / 10000000000;
    end;
  end;

begin
  if DataType in [mptDateTime, mptFloat] then
    Result := PDouble(FValue)^
  else if DataType = mptSingle then
    Result := PSingle(FValue)^
  else if DataType = mptString then
  begin
    if not(ParseDateTime(PWideChar(FValue), Result) or
      ParseWebTime(PQCharW(FValue), Result)) then
      raise Exception.Create(Format(SBadConvert,
        [MsgPackTypeName[Integer(DataType)], 'DateTime']))
  end
  else if DataType in [mptInteger, mptNull, mptUnknown] then
    Result := AsInt64
  else if (DataType = mptExtended) and (Byte(ExtType) = $FF) then
    FromTimeStamp
  else
    raise Exception.Create(Format(SBadConvert,
      [MsgPackTypeName[Integer(DataType)], 'DateTime']));
end;

function TQMsgPack.GetAsExtBytes: TBytes;
begin
  if DataType = mptExtended then
    Result := FValue
  else
    SetLength(Result, 0);
end;

function TQMsgPack.GetAsFloat: Double;
  procedure StrAsFloat;
  var
    p: PQCharW;
    s: QStringW;
    T: Extended;
  begin
    s := AsString;
    p := PQCharW(s);
    if (not ParseNumeric(p, T)) or (p^ <> #0) then
      raise Exception.Create(Format(SBadConvert, [s, 'Numeric']));
    Result := T;
  end;

begin
  if DataType in [mptFloat, mptDateTime] then
    Result := PDouble(FValue)^
  else if DataType = mptSingle then
    Result := PSingle(FValue)^
  else if DataType = mptBoolean then
    Result := Integer(AsBoolean)
  else if DataType = mptString then
    StrAsFloat
  else if DataType = mptInteger then
    Result := AsInt64
  else if DataType in [mptNull, mptUnknown] then
    Result := 0
  else
    raise Exception.Create(Format(SBadConvert,
      [MsgPackTypeName[Integer(DataType)], 'Numeric']))
end;

function TQMsgPack.GetAsInt64: Int64;
begin
  if DataType = mptInteger then
    Result := PInt64(FValue)^
  else if DataType in [mptFloat, mptDateTime] then
    Result := Trunc(PDouble(FValue)^)
  else if DataType = mptSingle then
    Result := Trunc(PSingle(FValue)^)
  else if DataType = mptBoolean then
    Result := Integer(AsBoolean)
  else if DataType = mptString then
    Result := Trunc(AsFloat)
  else if DataType in [mptNull, mptUnknown] then
    Result := 0
  else
    raise Exception.Create(Format(SBadConvert,
      [MsgPackTypeName[Integer(DataType)], 'Numeric']))
end;

function TQMsgPack.GetAsInteger: Integer;
begin
  Result := AsInt64;
end;

function TQMsgPack.GetAsJson: QStringW;
begin
  Result := EncodeAsString(True);
end;

function TQMsgPack.GetAsMsgPack: TBytes;
begin
  Result := Encode;
end;

function TQMsgPack.GetAsSingle: Single;
begin
  if DataType = mptSingle then
    Result := PSingle(FValue)^
  else if DataType in [mptFloat, mptDateTime] then
    Result := PDouble(FValue)^
  else if DataType = mptBoolean then
    Result := Integer(AsBoolean)
  else if DataType = mptString then
  begin
    if not TryStrToFloat(AsString, Result) then
      raise Exception.Create(Format(SBadConvert, [AsString, 'Numeric']));
  end
  else if DataType = mptInteger then
    Result := AsInt64
  else if DataType in [mptNull, mptUnknown] then
    Result := 0
  else
    raise Exception.Create(Format(SBadConvert,
      [MsgPackTypeName[Integer(DataType)], 'Numeric']))
end;

function TQMsgPack.GetAsString: QStringW;
begin
  Result := EncodeAsString(False);
end;

function TQMsgPack.GetAsVariant: Variant;
var
  I: Integer;
  procedure BytesAsVariant;
  var
    l: Integer;
    p: PByte;
  begin
    l := Length(FValue);
    Result := VarArrayCreate([0, l - 1], varByte);
    p := VarArrayLock(Result);
    Move(FValue[0], p^, l);
    VarArrayUnlock(Result);
  end;

begin
  case DataType of
    mptNull:
      Result := Null;
    mptString:
      Result := AsString;
    mptInteger:
      Result := AsInt64;
    mptFloat:
      Result := AsFloat;
    mptSingle:
      Result := AsSingle;
    mptDateTime:
      Result := AsDateTime;
    mptBoolean:
      Result := AsBoolean;
    mptArray, mptMap:
      begin
        Result := VarArrayCreate([0, Count - 1], varVariant);
        for I := 0 to Count - 1 do
          Result[I] := Items[I].AsVariant;
      end;
    mptBinary:
      BytesAsVariant;
    mptExtended:
      raise Exception.Create(SVariantNotSupport)
  else
    VarClear(Result);
  end;
end;

function TQMsgPack.GetCount: Integer;
begin
  if DataType in [mptArray, mptMap] then
    Result := FItems.Count
  else
    Result := 0;
end;

function TQMsgPack.GetEnumerator: TQMsgPackEnumerator;
begin
  Result := TQMsgPackEnumerator.Create(Self);
end;

function TQMsgPack.GetIsArray: Boolean;
begin
  Result := (DataType = mptArray);
end;

function TQMsgPack.GetIsDateTime: Boolean;
var
  ATime: TDateTime;
begin
  Result := (DataType = mptDateTime);
  if not Result then
  begin
    if DataType = mptString then
      Result := ParseDateTime(PQCharW(FValue), ATime) or
        ParseWebTime(PQCharW(FValue), ATime)
  end;
end;

function TQMsgPack.GetIsNull: Boolean;
begin
  Result := (DataType = mptNull);
end;

function TQMsgPack.GetIsNumeric: Boolean;
var
  ANum: Extended;
  s: QStringW;
  p: PWideChar;
begin
  Result := (DataType in [mptInteger, mptSingle, mptFloat]);
  if DataType = mptString then
  begin
    s := AsString;
    p := PWideChar(s);
    if ParseNumeric(p, ANum) then
    begin
      SkipSpaceW(p);
      Result := (p^ = #0);
    end;
  end;
end;

function TQMsgPack.GetIsObject: Boolean;
begin
  Result := (DataType = mptMap);
end;

function TQMsgPack.GetIsOrdType: Boolean;
begin
  Result := DataType in [mptBoolean, mptInteger];
end;

function TQMsgPack.GetIsString: Boolean;
begin
  Result := (DataType = mptString);
end;

function TQMsgPack.GetItemIndex: Integer;
var
  I: Integer;
begin
  Result := -1;
  if Assigned(Parent) then
  begin
    for I := 0 to Parent.Count - 1 do
    begin
      if Parent.Items[I] = Self then
      begin
        Result := I;
        Break;
      end;
    end;
  end;
end;

function TQMsgPack.GetItems(AIndex: Integer): TQMsgPack;
begin
  Result := FItems[AIndex];
end;

function TQMsgPack.GetKeyAsBoolean: Boolean;
begin
  if KeyType = mptBoolean then
    Result := PBoolean(FKey)^
  else if KeyType = mptString then
  begin
    if not TryStrToBool(KeyAsString, Result) then
      raise Exception.Create(Format(SBadConvert, [KeyAsString, 'Boolean']));
  end
  else if KeyType in [mptFloat, mptDateTime] then
    Result := not SameValue(KeyAsFloat, 0)
  else if KeyType = mptSingle then
    Result := not SameValue(KeyAsSingle, 0)
  else if KeyType = mptInteger then
    Result := KeyAsInt64 <> 0
  else if KeyType in [mptNull, mptUnknown] then
    Result := False
  else
    raise Exception.Create(Format(SBadConvert,
      [MsgPackTypeName[Integer(KeyType)], 'Boolean']));
end;

function TQMsgPack.GetKeyAsBytes: TBytes;
begin
  Result := FKey;
end;

function TQMsgPack.GetKeyAsDateTime: TDateTime;
begin
  if KeyType in [mptDateTime, mptFloat] then
    Result := PDouble(FKey)^
  else if KeyType = mptSingle then
    Result := PSingle(FKey)^
  else if KeyType = mptString then
  begin
    if not(ParseDateTime(PQCharW(FKey), Result) or ParseWebTime(PQCharW(FKey),
      Result)) then
      raise Exception.Create(Format(SBadConvert,
        [MsgPackTypeName[Integer(KeyType)], 'DateTime']))
  end
  else if KeyType in [mptInteger, mptNull, mptUnknown] then
    Result := KeyAsInt64
  else
    raise Exception.Create(Format(SBadConvert,
      [MsgPackTypeName[Integer(KeyType)], 'DateTime']));
end;

function TQMsgPack.GetKeyAsFloat: Double;
  procedure StrAsFloat;
  var
    p: PQCharW;
    s: QStringW;
    T: Extended;
  begin
    s := KeyAsString;
    p := PQCharW(s);
    if (not ParseNumeric(p, T)) or (p^ <> #0) then
      raise Exception.Create(Format(SBadConvert, [s, 'Numeric']));
    Result := T;
  end;

begin
  if KeyType in [mptFloat, mptDateTime] then
    Result := PDouble(FKey)^
  else if KeyType = mptSingle then
    Result := PSingle(FKey)^
  else if KeyType = mptBoolean then
    Result := Integer(KeyAsBoolean)
  else if KeyType = mptString then
    StrAsFloat
  else if KeyType = mptInteger then
    Result := KeyAsInt64
  else if KeyType in [mptNull, mptUnknown] then
    Result := 0
  else
    raise Exception.Create(Format(SBadConvert,
      [MsgPackTypeName[Integer(KeyType)], 'Numeric']));
end;

function TQMsgPack.GetKeyAsInt64: Int64;
begin
  if KeyType = mptInteger then
    Result := PInt64(FKey)^
  else if KeyType in [mptFloat, mptDateTime] then
    Result := Trunc(PDouble(FKey)^)
  else if KeyType = mptSingle then
    Result := Trunc(PSingle(FKey)^)
  else if KeyType = mptBoolean then
    Result := Integer(KeyAsBoolean)
  else if KeyType = mptString then
    Result := Trunc(KeyAsFloat)
  else if KeyType in [mptNull, mptUnknown] then
    Result := 0
  else
    raise Exception.Create(Format(SBadConvert,
      [MsgPackTypeName[Integer(KeyType)], 'Numeric']))
end;

function TQMsgPack.GetKeyAsInteger: Integer;
begin
  Result := KeyAsInt64;
end;

function TQMsgPack.GetKeyAsSingle: Single;
begin
  if KeyType = mptSingle then
    Result := PSingle(FKey)^
  else if KeyType in [mptFloat, mptDateTime] then
    Result := PDouble(FKey)^
  else if KeyType = mptBoolean then
    Result := Integer(KeyAsBoolean)
  else if KeyType = mptString then
  begin
    if not TryStrToFloat(KeyAsString, Result) then
      raise Exception.Create(Format(SBadConvert, [KeyAsString, 'Numeric']));
  end
  else if KeyType = mptInteger then
    Result := KeyAsInt64
  else if KeyType in [mptNull, mptUnknown] then
    Result := 0
  else
    raise Exception.Create(Format(SBadConvert,
      [MsgPackTypeName[Integer(KeyType)], 'Numeric']))
end;

function TQMsgPack.GetKeyAsString: QStringW;
begin
  case FKeyType of
    mptString:
      Result := StrDupX(PQCharW(@FKey[0]), Length(FKey) shr 1);
    mptUnknown, mptNull:
      Result := '';
    mptInteger:
      Result := IntToStr(KeyAsInt64);
    mptBoolean:
      Result := BoolToStr(KeyAsBoolean);
    mptSingle:
      Result := FloatToStr(KeyAsSingle);
    mptFloat:
      Result := FloatToStr(KeyAsFloat);
    mptBinary:
      Result := BinToHex(KeyAsBytes);
    mptDateTime:
      begin
        if SameValue(PDateTime(PQCharW(FKey))^ - Trunc(PDateTime(PQCharW(FKey))
          ^), 0) then
          Result := FormatDateTime(MsgPackDateFormat, PDateTime(PQCharW(FKey))^)
        else
        begin
          if Trunc(PDateTime(PQCharW(FKey))^) = 0 then
            Result := FormatDateTime(MsgPackTimeFormat,
              PDateTime(PQCharW(FKey))^)
          else
            Result := FormatDateTime(MsgPackDateTimeFormat,
              PDateTime(PQCharW(FKey))^);
        end;
      end;
  end;
end;

function TQMsgPack.GetKeyIsNull: Boolean;
begin
  Result := (FKeyType in [mptNull, mptUnknown]);
end;

function TQMsgPack.GetPath: QStringW;
begin
  Result := GetRelPath(nil);
end;

function TQMsgPack.GetRelPath(AParent: TQMsgPack; APathDelimiter: QCharW)
  : QStringW;
var
  AItem, APItem: TQMsgPack;
  AItemName: QStringW;
begin
  AItem := Self;
  SetLength(Result, 0);
  while Assigned(AItem) and (AItem <> AParent) do
  begin
    APItem := AItem.Parent;
    if Assigned(APItem) then
    begin
      if APItem.DataType = mptArray then
        Result := '[' + IntToStr(AItem.ItemIndex) + ']' + Result
      else
      begin
        AItemName := AItem.Name;
        if Length(AItemName) > 0 then
          // 命名的元素
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

function TQMsgPack.GetRoot: TQMsgPack;
begin
  Result := Self;
  while Result.FParent <> nil do
    Result := Result.FParent;
end;

function TQMsgPack.GetValue: QStringW;
begin
  Result := AsString;
end;

function TQMsgPack.HasChild(ANamePath: QStringW; var AChild: TQMsgPack)
  : Boolean;
begin
  AChild := ItemByPath(ANamePath);
  Result := AChild <> nil;
end;

function TQMsgPack.HashName(const s: QStringW): TQHashType;
var
  ATemp: QStringW;
begin
  if not IgnoreCase then
    Result := HashOf(PQCharW(s), Length(s) shl 1)
  else
  begin
    ATemp := UpperCase(s);
    Result := HashOf(PQCharW(ATemp), Length(ATemp) shl 1);
  end;
end;

procedure TQMsgPack.HashNeeded;
begin
  if (FKeyHash = 0) and (Length(FKey) > 0) then
    FKeyHash := HashName(Name);
end;

function TQMsgPack.IndexOf(const AName: QStringW): Integer;
var
  I, l: Integer;
  AItem: TQMsgPack;
  AHash: TQHashType;
  s: QStringW;
begin
  Result := -1;
  l := Length(AName);
  if l > 0 then
    AHash := HashName(AName)
  else
    Exit;
  l := l shl 1;
  for I := 0 to Count - 1 do
  begin
    AItem := Items[I];
    s := AItem.Name;
    if (Length(s) shl 1) = l then
    begin
      AItem.HashNeeded;
      if AItem.FKeyHash = AHash then
      begin
        if StrCmpW(PQCharW(s), PQCharW(AName), IgnoreCase) = 0 then
        begin
          Result := I;
          Break;
        end;
      end;
    end;
  end;
end;

function TQMsgPack.IntByName(AName: QStringW; ADefVal: Int64): Int64;
var
  AChild: TQMsgPack;
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

function TQMsgPack.IntByPath(APath: QStringW; ADefVal: Int64): Int64;
var
  AItem: TQMsgPack;
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

function TQMsgPack.InternalAdd(const AKey: TBytes;
  AKeyType, ADataType: TQMsgPackType): TQMsgPack;
begin
  ArrayNeeded(mptMap);
  Result := CreateItem;
  Result.FParent := Self;
  Result.FKeyType := AKeyType;
  Result.FIgnoreCase := IgnoreCase;
  SetLength(Result.FKey, Length(AKey));
  if Length(AKey) > 0 then
    Move(AKey[0], Result.FKey[0], Length(AKey));
  FItems.Add(Result);
end;

procedure TQMsgPack.InternalEncode(ANode: TQMsgPack; AStream: TStream;
  ADateTimeAsTimeStamp: Boolean);
var
  I, C: Integer;
  AChild: TQMsgPack;
  ALastPos: Int64;
begin
  ALastPos := AStream.Position;
  if ALastPos = AStream.Size then
  begin
    AStream.Size := AStream.Size + 16384;
    AStream.Position := ALastPos;
  end;
  case ANode.DataType of
    mptUnknown, mptNull:
      WriteNull(AStream);
    mptInteger:
      WriteInt(AStream, ANode.AsInt64);
    mptBoolean:
      WriteBool(AStream, ANode.AsBoolean);
    mptDateTime:
      WriteDateTime(AStream, ANode.AsDateTime, ADateTimeAsTimeStamp);
    mptFloat:
      WriteFloat(AStream, ANode.AsFloat);
    mptSingle:
      WriteSingle(AStream, ANode.AsSingle);
    mptString:
      WriteString(AStream, ANode.AsString);
    mptBinary:
      WriteBytes(AStream, @ANode.FValue[0], Length(ANode.FValue));
    mptArray:
      begin
        C := ANode.Count;
        WriteArray(AStream, C);
        for I := 0 to C - 1 do
          InternalEncode(ANode[I], AStream, ADateTimeAsTimeStamp);
      end;
    mptMap:
      begin
        C := ANode.Count;
        WriteMap(AStream, C);
        for I := 0 to C - 1 do
        begin
          AChild := ANode[I];
          case AChild.FKeyType of
            mptUnknown:
              WriteNull(AStream);
            mptInteger:
              WriteInt(AStream, AChild.KeyAsInt64);
            mptNull:
              WriteNull(AStream);
            mptBoolean:
              WriteBool(AStream, AChild.KeyAsBoolean);
            mptSingle:
              WriteSingle(AStream, AChild.KeyAsSingle);
            mptFloat:
              WriteFloat(AStream, AChild.KeyAsFloat);
            mptString:
              WriteString(AStream, AChild.KeyAsString);
            mptBinary:
              WriteBytes(AStream, @AChild.FKey[0], Length(AChild.FKey));
            mptDateTime:
              WriteDateTime(AStream, ANode.KeyAsDateTime, ADateTimeAsTimeStamp);
          end;
          InternalEncode(AChild, AStream, ADateTimeAsTimeStamp);
        end;
      end;
    mptExtended:
      WriteExt(AStream, ANode.FExtType, @ANode.FValue[0], Length(ANode.FValue));
  end;
end;

procedure TQMsgPack.InternalParse(var p: PByte; l: Integer; AToKey: Boolean);
var
  ps: PByte;
  I: Integer;
  ACount: Cardinal;
  AChild: TQMsgPack;
begin
  ps := p;
  while IntPtr(p) - IntPtr(ps) < l do
  begin
    if p^ in [$0 .. $7F] then
    // 0-127的整数
    begin
      if AToKey then
        KeyAsInt64 := p^
      else
        AsInt64 := p^;
      Inc(p);
      Break;
    end
    else if p^ in [$80 .. $8F] then // 短映射，最多15项
    begin
      DataType := mptMap;
      FItems.Capacity := p^ - $80; // 项数
      ACount := FItems.Capacity;
      Inc(p);
      for I := 0 to ACount - 1 do
      begin
        AChild := Add;
        AChild.InternalParse(p, l - (Integer(p) - Integer(ps)), True);
        AChild.InternalParse(p, l - (Integer(p) - Integer(ps)), False);
      end;
      Break;
    end
    else if p^ in [$90 .. $9F] then // 短数组，最多15项
    begin
      DataType := mptArray;
      FItems.Capacity := p^ - $90;
      ACount := FItems.Capacity;
      Inc(p);
      for I := 0 to ACount - 1 do
        Add.InternalParse(p, l - (Integer(p) - Integer(ps)), False);
      Break;
    end
    else if p^ in [$A0 .. $BF] then // 短字符串，最多31个字节
    begin
      ACount := p^ - $A0;
      Inc(p);
      if ACount > 0 then
      begin
        if AToKey then
          KeyAsString := qstring.Utf8Decode(PQCharA(p), ACount)
        else
          AsString := qstring.Utf8Decode(PQCharA(p), ACount);
        Inc(p, ACount);
      end
      else if AToKey then
        KeyAsString := ''
      else
        AsString := '';
      Break;
    end
    else if p^ in [$E0 .. $FF] then
    begin
      if AToKey then
        KeyAsInt64 := Shortint(p^)
      else
        AsInt64 := Shortint(p^);
      Inc(p);
      Break;
    end
    else
    begin
      case p^ of
        $C0: // nil/null
          begin
            if AToKey then
              ResetKey
            else
              DataType := mptNull;
            Inc(p);
          end;
        $C1:
          // 保留
          raise Exception.Create('保留的类型');
        $C2: // False
          begin
            if AToKey then
              KeyAsBoolean := False
            else
              AsBoolean := False;
            Inc(p);
          end;
        $C3: // True
          begin
            if AToKey then
              KeyAsBoolean := True
            else
              AsBoolean := True;
            Inc(p);
          end;
        $C4: // 短二进制，最长255字节
          begin
            Inc(p);
            ACount := p^;
            if AToKey then
            begin
              FKeyType := mptBinary;
              SetLength(FKey, ACount);
              Inc(p);
              Move(p^, FKey[0], ACount);
            end
            else
            begin
              DataType := mptBinary;
              SetLength(FValue, ACount);
              Inc(p);
              Move(p^, FValue[0], ACount);
            end;
            Inc(p, ACount);
          end;
        $C5:
          // 二进制，16位，最长65535B
          begin
            Inc(p);
            ACount := ExchangeByteOrder(PWord(p)^);
            Inc(p, 2);
            if AToKey then
            begin
              FKeyType := mptBinary;
              SetLength(FKey, ACount);
              Move(p^, FKey[0], ACount);
            end
            else
            begin
              DataType := mptBinary;
              SetLength(FValue, ACount);
              Move(p^, FValue[0], ACount);
            end;
            Inc(p, ACount);
          end;
        $C6: // 二进制，32位，最长2^32-1
          begin
            Inc(p);
            ACount := ExchangeByteOrder(PCardinal(p)^);
            Inc(p, 4);
            if AToKey then
            begin
              FKeyType := mptBinary;
              SetLength(FKey, ACount);
              Move(p^, FKey[0], ACount);
            end
            else
            begin
              DataType := mptBinary;
              SetLength(FValue, ACount);
              Move(p^, FValue[0], ACount);
            end;
            Inc(p, ACount);
          end;
        $C7: // Ext8
          begin
            Inc(p);
            DataType := mptExtended;
            ACount := p^;
            SetLength(FValue, ACount);
            Inc(p);
            FExtType := p^;
            Inc(p);
            Move(p^, FValue[0], ACount);
            Inc(p, ACount);
          end;
        $C8: // Ext16
          begin
            Inc(p);
            DataType := mptExtended;
            ACount := ExchangeByteOrder(PWord(p)^);
            Inc(p, 2);
            SetLength(FValue, ACount);
            FExtType := p^;
            Inc(p);
            Move(p^, FValue[0], ACount);
            Inc(p, ACount);
          end;
        $C9: // Ext32,4B
          begin
            Inc(p);
            DataType := mptExtended;
            ACount := ExchangeByteOrder(PCardinal(p)^);
            Inc(p, 4);
            SetLength(FValue, ACount);
            FExtType := p^;
            Inc(p);
            Move(p^, FValue[0], ACount);
            Inc(p, ACount);
          end;
        $CA: // float 32
          begin
            Inc(p);
            if AToKey then
              KeyAsSingle := ExchangeByteOrder(PSingle(p)^)
            else
              AsSingle := ExchangeByteOrder(PSingle(p)^);
            Inc(p, 4);
          end;
        $CB:
          // Float 64
          begin
            Inc(p);
            if AToKey then
              KeyAsFloat := ExchangeByteOrder(PDouble(p)^)
            else
              AsFloat := ExchangeByteOrder(PDouble(p)^);
            Inc(p, 8);
          end;
        $CC:
          // UInt8
          begin
            Inc(p);
            if AToKey then
              KeyAsInt64 := p^
            else
              AsInt64 := p^;
            Inc(p);
          end;
        $CD: // UInt16
          begin
            Inc(p);
            if AToKey then
              KeyAsInt64 := ExchangeByteOrder(PWord(p)^)
            else
              AsInt64 := ExchangeByteOrder(PWord(p)^);
            Inc(p, 2);
          end;
        $CE:
          // UInt32
          begin
            Inc(p);
            if AToKey then
              KeyAsInt64 := ExchangeByteOrder(PCardinal(p)^)
            else
              AsInt64 := ExchangeByteOrder(PCardinal(p)^);
            Inc(p, 4);
          end;
        $CF: // UInt64
          begin
            Inc(p);
            if AToKey then
              KeyAsInt64 := ExchangeByteOrder(PInt64(p)^)
            else
              AsInt64 := ExchangeByteOrder(PInt64(p)^);
            Inc(p, 8);
          end;
        $D0:
          // Int8
          begin
            Inc(p);
            if AToKey then
              KeyAsInt64 := Shortint(p^)
            else
              AsInt64 := Shortint(p^);
            Inc(p);
          end;
        $D1: // Int16
          begin
            Inc(p);
            if AToKey then
              KeyAsInt64 := ExchangeByteOrder(PSmallint(p)^)
            else
              AsInt64 := ExchangeByteOrder(PSmallint(p)^);
            Inc(p, 2);
          end;
        $D2: // Int32
          begin
            Inc(p);
            if AToKey then
              KeyAsInt64 := ExchangeByteOrder(PInteger(p)^)
            else
              AsInt64 := ExchangeByteOrder(PInteger(p)^);
            Inc(p, 4);
          end;
        $D3:
          // Int64
          begin
            Inc(p);
            if AToKey then
              KeyAsInt64 := ExchangeByteOrder(PInt64(p)^)
            else
              AsInt64 := ExchangeByteOrder(PInt64(p)^);
            Inc(p, 8);
          end;
        $D4:
          // Fixed ext8,1B
          begin
            Inc(p);
            DataType := mptExtended;
            SetLength(FValue, 1);
            FExtType := p^;
            Inc(p);
            FValue[0] := p^;
            Inc(p);
          end;
        $D5:
          // Fixed Ext16,2B
          begin
            Inc(p);
            DataType := mptExtended;
            SetLength(FValue, 2);
            FExtType := p^;
            Inc(p);
            PWord(@FValue[0])^ := PWord(p)^;
            Inc(p, 2);
          end;
        $D6: // Fixed Ext32,4B
          begin
            Inc(p);
            DataType := mptExtended;
            SetLength(FValue, 4);
            FExtType := p^;
            Inc(p);
            PCardinal(@FValue[0])^ := PCardinal(p)^;
            Inc(p, 4);
          end;
        $D7: // Fixed Ext64,8B
          begin
            Inc(p);
            DataType := mptExtended;
            SetLength(FValue, 8);
            FExtType := p^;
            Inc(p);
            PInt64(@FValue[0])^ := PInt64(p)^;
            Inc(p, 8);
          end;
        $D8: // Fixed Ext 128bit,16B
          begin
            Inc(p);
            DataType := mptExtended;
            SetLength(FValue, 16);
            FExtType := p^;
            Inc(p);
            PInt64(@FValue[0])^ := PInt64(p)^;
            Inc(p, 8);
            PInt64(@FValue[8])^ := PInt64(p)^;
            Inc(p, 8);
          end;
        $D9: // Str
          begin
            Inc(p);
            ACount := p^;
            Inc(p);
            if AToKey then
              KeyAsString := Utf8Decode(PQCharA(p), ACount)
            else
              AsString := Utf8Decode(PQCharA(p), ACount);
            Inc(p, ACount);
          end;
        $DA: // Str 16
          begin
            Inc(p);
            ACount := ExchangeByteOrder(PWord(p)^);
            Inc(p, 2);
            if AToKey then
              KeyAsString := Utf8Decode(PQCharA(p), ACount)
            else
              AsString := Utf8Decode(PQCharA(p), ACount);
            Inc(p, ACount);
          end;
        $DB: // Str 32
          begin
            Inc(p);
            ACount := ExchangeByteOrder(PCardinal(p)^);
            Inc(p, 4);
            if AToKey then
              KeyAsString := Utf8Decode(PQCharA(p), ACount)
            else
              AsString := Utf8Decode(PQCharA(p), ACount);
            Inc(p, ACount);
          end;
        $DC: // array 16
          begin
            Inc(p);
            DataType := mptArray;
            ACount := ExchangeByteOrder(PWord(p)^);
            Inc(p, 2);
            FItems.Capacity := ACount;
            for I := 0 to ACount - 1 do
              Add.InternalParse(p, l - (Integer(p) - Integer(ps)), False);
          end;
        $DD: // Array 32
          begin
            Inc(p);
            DataType := mptArray;
            ACount := ExchangeByteOrder(PCardinal(p)^);
            Inc(p, 4);
            FItems.Capacity := ACount;
            for I := 0 to ACount - 1 do
              Add.InternalParse(p, l - (Integer(p) - Integer(ps)), False);
          end;
        $DE: // Object map 16
          begin
            Inc(p);
            DataType := mptMap;
            ACount := ExchangeByteOrder(PWord(p)^);
            Inc(p, 2);
            FItems.Capacity := ACount;
            for I := 0 to ACount - 1 do
            begin
              AChild := Add;
              AChild.InternalParse(p, l - (Integer(p) - Integer(ps)), True);
              // 解析值
              AChild.InternalParse(p, l - (Integer(p) - Integer(ps)), False);
            end;
          end;
        $DF: // Object map 32
          begin
            Inc(p);
            DataType := mptMap;
            ACount := ExchangeByteOrder(PCardinal(p)^);
            Inc(p, 4);
            FItems.Capacity := ACount;
            for I := 0 to ACount - 1 do
            begin
              AChild := Add;
              AChild.InternalParse(p, l - (Integer(p) - Integer(ps)), True);
              // 解析值
              AChild.InternalParse(p, l - (Integer(p) - Integer(ps)), False);
            end;
          end;
      end;
    end;
    Break;
  end;
end;

{$IF RTLVersion>=21}

function TQMsgPack.Invoke(AInstance: TValue): TValue;
var
  AMethods: TArray<TRttiMethod>;
  AParams: TArray<TRttiParameter>;
  AMethod: TRttiMethod;
  AType: TRttiType;
  AContext: TRttiContext;
  AParamValues: array of TValue;
  I, C: Integer;
  AParamItem: TQMsgPack;
begin
  AContext := TRttiContext.Create;
  Result := TValue.Empty;
  if AInstance.IsObject then
    AType := AContext.GetType(AInstance.AsObject.ClassInfo)
  else if AInstance.IsClass then
    AType := AContext.GetType(AInstance.AsClass)
  else if AInstance.Kind = tkRecord then
    AType := AContext.GetType(AInstance.TypeInfo)
  else
    AType := AContext.GetType(AInstance.TypeInfo);
  AMethods := AType.GetMethods(Name);
  C := Count;
  for AMethod in AMethods do
  begin
    AParams := AMethod.GetParameters;
    if Length(AParams) = C then
    begin
      SetLength(AParamValues, C);
      for I := 0 to C - 1 do
      begin
        AParamItem := ItemByName(AParams[I].Name);
        if AParamItem <> nil then
          AParamValues[I] := AParamItem.ToRttiValue
        else
          raise Exception.CreateFmt(SParamMissed, [AParams[I].Name]);
      end;
      Result := AMethod.Invoke(AInstance, AParamValues);
      Exit;
    end;
  end;
  raise Exception.CreateFmt(SMethodMissed, [Name]);
end;
{$IFEND >=2010}

function TQMsgPack.IsChildOf(AParent: TQMsgPack): Boolean;
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

function TQMsgPack.IsParentOf(AChild: TQMsgPack): Boolean;
begin
  if Assigned(AChild) then
    Result := AChild.IsChildOf(Self)
  else
    Result := False;
end;

function TQMsgPack.ItemByName(AName: QStringW): TQMsgPack;
var
  I: Integer;
  p: PQCharW;
  AIndex: Int64;
begin
  Result := nil;
  p := PQCharW(AName);
  if (p^ = '[') and (DataType in [mptMap, mptArray]) then
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
  else if DataType = mptMap then
  begin
    I := IndexOf(AName);
    if I <> -1 then
      Result := Items[I];
  end;
end;

function TQMsgPack.ItemByName(const AName: QStringW; AList: TQMsgPackList;
  ANest: Boolean): Integer;
var
  l: Integer;
  function InternalFind(AParent: TQMsgPack): Integer;
  var
    I: Integer;
    AItem: TQMsgPack;
  begin
    Result := -1;
    for I := 0 to Count - 1 do
    begin
      AItem := Items[I];
      if Length(AItem.FKey) = l then
      begin
        AItem.HashNeeded;
        if StrCmpW(PQCharW(AItem.Name), PQCharW(AName), IgnoreCase) = 0 then
          AList.Add(AItem);
      end;
      if ANest then
        InternalFind(AItem);
    end;
  end;

begin
  l := Length(AName);
  if l > 0 then
    Result := InternalFind(Self)
  else
  begin
    Result := -1;
    Exit;
  end;
end;

function TQMsgPack.ItemByPath(APath: QStringW): TQMsgPack;
var
  AParent: TQMsgPack;
  AName: QStringW;
  p, pn, ws: PQCharW;
  l: Integer;
  AIndex: Int64;
const
  PathDelimiters: PWideChar = './\';
  ArrayStart: PWideChar = '[';
begin
  AParent := Self;
  p := PQCharW(APath);
  Result := nil;
  while Assigned(AParent) and (p^ <> #0) do
  begin
    AName := HtmlUnescape(DecodeTokenW(p, PathDelimiters, WideChar(0), False));
    if Length(AName) > 0 then
    begin
      // 查找的是数组？
      l := Length(AName);
      AIndex := -1;
      pn := PQCharW(AName);
      if (pn[l - 1] = ']') then
      begin
        ws := pn;
        if pn^ = '[' then
          // 如果是直接的数组，则直接取当前的parent为数组的根
          Result := AParent
        else
        begin
          SkipUntilW(ws, ArrayStart);
          Result := AParent.ItemByName
            (StrDupX(pn, (IntPtr(ws) - IntPtr(pn)) shr 1));
        end;
        if Result <> nil then
        begin
          if Result.DataType in [mptArray, mptMap] then
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
    if CharInW(p, PathDelimiters) then
      Inc(p);
    // 否则是..或//\\等路径，忽略
  end;
  if p^ <> #0 then
    Result := nil;
end;

function TQMsgPack.ItemByRegex(const ARegex: QStringW; AList: TQMsgPackList;
  ANest: Boolean): Integer;
var
  ANode: TQMsgPack;
  APcre: TPerlRegEx;
  function RegexStr(const s: QStringW):
{$IF RTLVersion<=24}UTF8String{$ELSE}UnicodeString{$IFEND};
  begin
{$IF RTLVersion<19}
    Result := System.UTF8Encode(s);
{$ELSE}
{$IF RTLVersion<=24}
    Result := UTF8String(s);
{$ELSE}
    Result := s;
{$IFEND}
{$IFEND}
  end;

  function InternalFind(AParent: TQMsgPack): Integer;
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
  APcre := TPerlRegEx.Create;
  try
    APcre.RegEx := RegexStr(ARegex);
    APcre.Compile;
    Result := InternalFind(Self);
  finally
    FreeObject(APcre);
  end;
end;

procedure TQMsgPack.LoadFromFile(AFileName: String);
var
  AStream: TFileStream;
begin
  AStream := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyWrite);
  try
    LoadFromStream(AStream);
  finally
    FreeObject(AStream);
  end;
end;

procedure TQMsgPack.LoadFromStream(AStream: TStream);
var
  ABytes: TBytes;
begin
  SetLength(ABytes, AStream.Size - AStream.Position);
  AStream.ReadBuffer(ABytes[0], Length(ABytes));
  Parse(ABytes);
end;

procedure TQMsgPack.MoveTo(ANewParent: TQMsgPack; AIndex: Integer);
begin
  if ANewParent = Self then
    raise Exception.Create(SCantAttachToSelf)
  else
  begin
    if Parent = ANewParent then
      Exit;
    if IsParentOf(ANewParent) then
      raise Exception.Create(SCantMoveToChild);
    if ANewParent.DataType in [mptArray, mptMap] then
    begin
      if ANewParent.DataType = mptMap then
      begin
        if Length(Name) = 0 then
          raise Exception.Create(SCantAttachNoNameNodeToObject)
        else if ANewParent.IndexOf(Name) <> -1 then
          raise Exception.CreateFmt(SNodeNameExists, [Name]);
      end;
      if Assigned(FParent) then
        FParent.Remove(Self);
      FParent := ANewParent;
      if AIndex >= ANewParent.Count then
        ANewParent.FItems.Add(Self)
      else if AIndex <= 0 then
        ANewParent.FItems.Insert(0, Self)
      else
        ANewParent.FItems.Insert(AIndex, Self);
      DoNodeMoved(Self);
    end
    else
      raise Exception.Create(SCanAttachToNoneContainer);
  end;
end;

procedure TQMsgPack.Parse(const s: TBytes);
begin
  Parse(@s[0], Length(s));
end;

procedure TQMsgPack.Parse(p: PByte; l: Integer);
begin
  Clear;
  InternalParse(p, l, False);
  DoParsed;
end;

function TQMsgPack.Remove(AItemIndex: Integer): TQMsgPack;
begin
  if FDataType in [mptArray, mptMap] then
  begin
    if (AItemIndex >= 0) and (AItemIndex < Count) then
    begin
      Result := Items[AItemIndex];
      FItems.Delete(AItemIndex);
      Result.FParent := nil;
    end
    else
      Result := nil;
  end
  else
    Result := nil;
end;

procedure TQMsgPack.Remove(ANode: TQMsgPack);
begin
  Remove(ANode.ItemIndex);
end;

procedure TQMsgPack.Replace(AIndex: Integer; ANewItem: TQMsgPack);
begin
  FreeObject(Items[AIndex]);
  FItems[AIndex] := ANewItem;
end;

procedure TQMsgPack.Reset(ADetach: Boolean);
begin
  if ADetach and Assigned(FParent) then
  begin
    FParent.Remove(Self);
    FParent := nil;
  end;
  SetLength(FKey, 0);
  FKeyHash := 0;
  SetLength(FValue, 0);
  Clear;
  FKeyType := mptUnknown;
  FDataType := mptUnknown;
  FExtType := 0;
  FData := nil;
  FIgnoreCase := not MsgPackCaseSensitive;
end;

procedure TQMsgPack.ResetKey;
begin
  SetLength(FKey, 0);
  FKeyType := mptNull;
end;

procedure TQMsgPack.ResetNull;
begin
  DataType := mptNull;
end;

procedure TQMsgPack.RevertOrder(ANest: Boolean);
var
  I, H, M: Integer;
begin
  H := Count - 1;
  if H > 0 then
  begin
    M := H shr 1;
    for I := 0 to M do
      FItems.Exchange(I, H - I);
    if ANest then
    begin
      for I := 0 to H do
        Items[I].RevertOrder(ANest);
    end;
  end;
end;

procedure TQMsgPack.SaveToFile(AFileName: String;
  ADateTimeAsTimeStamp: Boolean = False);
var
  AStream: TMemoryStream;
begin
  AStream := TMemoryStream.Create;
  try
    SaveToStream(AStream, ADateTimeAsTimeStamp);
    AStream.SaveToFile(AFileName);
  finally
    FreeObject(AStream);
  end;
end;

procedure TQMsgPack.SaveToStream(AStream: TStream;
  ADateTimeAsTimeStamp: Boolean = False);
begin
  InternalEncode(Self, AStream, ADateTimeAsTimeStamp);
  AStream.Size := AStream.Position;
end;

procedure TQMsgPack.SetAsBoolean(const Value: Boolean);
begin
  DataType := mptBoolean;
  FValue[0] := Integer(Value);
end;

procedure TQMsgPack.SetAsBytes(const Value: TBytes);
begin
  DataType := mptBinary;
  FValue := Value;
end;

procedure TQMsgPack.SetAsDateTime(const Value: TDateTime);
begin
  DataType := mptDateTime;
  PDouble(@FValue[0])^ := Value;
end;

procedure TQMsgPack.SetAsFloat(const Value: Double);
begin
  DataType := mptFloat;
  PDouble(@FValue[0])^ := Value;
end;

procedure TQMsgPack.SetAsInt64(const Value: Int64);
begin
  DataType := mptInteger;
  PInt64(@FValue[0])^ := Value;
end;

procedure TQMsgPack.SetAsInteger(const Value: Integer);
begin
  SetAsInt64(Value);
end;

procedure TQMsgPack.SetAsMsgPack(const Value: TBytes);
begin
  Parse(@Value[0], Length(Value));
end;

procedure TQMsgPack.SetAsSingle(const Value: Single);
begin
  DataType := mptSingle;
  PSingle(FValue)^ := Value;
end;

procedure TQMsgPack.SetAsString(const Value: QStringW);
var
  l: NativeInt;
begin
  DataType := mptString;
  l := Length(Value) shl 1;
  SetLength(FValue, l);
  if l > 0 then
    Move(PQCharW(Value)^, FValue[0], l);
end;

procedure TQMsgPack.SetAsVariant(const Value: Variant);
var
  I: Integer;
  AType: TVarType;
  procedure VarAsBytes;
  var
    l: Integer;
    p: PByte;
  begin
    DataType := mptBinary;
    l := VarArrayHighBound(Value, 1) + 1;
    SetLength(FValue, l);
    p := VarArrayLock(Value);
    Move(p^, FValue[0], l);
    VarArrayUnlock(Value);
  end;
  procedure CastFromCustomVarType;
  var
    ATypeInfo: TCustomVariantType;
    AData: TVarData;
  begin
    if FindCustomVariantType(AType, ATypeInfo) then
    begin
      VariantInit(AData);
      // 先尝试转换成双精度数值，如果不行，就当字符串处理
      try
        try
          ATypeInfo.CastTo(AData, FindVarData(Value)^, varDouble);
          AsFloat := AData.VDouble;
        except
          AsString := Value;
        end;
      finally
        VariantClear(AData);
      end;
    end
    else
      raise Exception.CreateFmt(SUnsupportVarType, [AType]);
  end;

begin
  AType := VarType(Value);
  if VarIsArray(Value) then
  begin
    if (AType and varTypeMask) = varByte then
      VarAsBytes
    else
    begin
      ArrayNeeded(mptArray);
      Clear;
      for I := VarArrayLowBound(Value, VarArrayDimCount(Value))
        to VarArrayHighBound(Value, VarArrayDimCount(Value)) do
        Add.AsVariant := Value[I];
    end;
  end
  else
  begin
    case AType of
      varSmallInt, varInteger, varByte, varShortInt, varWord,
        varLongWord, varInt64:
        AsInt64 := Value;
      varSingle, varDouble, varCurrency:
        AsFloat := Value;
      varDate:
        AsDateTime := Value;
      varOleStr, varString{$IFDEF UNICODE}, varUString{$ENDIF}:
        AsString := Value;
      varBoolean:
        AsBoolean := Value;
{$IF RtlVersion>=26}
      varUInt64:
        AsInt64 := Value;
      varRecord:
        FromRtti(PVarRecord(@Value).RecInfo, PVarRecord(@Value).PRecord);
{$IFEND >=XE5}
      varNull, varEmpty, varUnknown:
        DataType := mptNull
    else
      CastFromCustomVarType;
    end;
  end;
end;

procedure TQMsgPack.SetDataType(const Value: TQMsgPackType);
begin
  if FDataType <> Value then
  begin
    if Value in [mptArray, mptMap] then
    begin
      if not Assigned(FItems) then
        FItems := TQMsgPackList.Create
      else if FDataType in [mptArray, mptMap] then
        Clear;
    end
    else
    begin
      if Assigned(FItems) then
      begin
        Clear;
        FreeAndNilObject(FItems);
      end;
      case Value of
        mptUnknown, mptNull, mptString, mptBinary, mptExtended:
          SetLength(FValue, 0);
        mptInteger:
          SetLength(FValue, SizeOf(Int64));
        mptBoolean:
          SetLength(FValue, 1);
        mptSingle:
          SetLength(FValue, SizeOf(Single));
        mptFloat, mptDateTime:
          SetLength(FValue, SizeOf(Extended));
      end;
    end;
    FDataType := Value;
  end;
end;

procedure TQMsgPack.SetExtBytes(const Value: TBytes);
begin
  DataType := mptExtended;
  FValue := Value;
end;

procedure TQMsgPack.SetExtType(const Value: Shortint);
begin
  if FExtType <> Value then
  begin
    if Value < 0 then
      raise Exception.Create(SReservedExtType);
    FExtType := Value;
  end;
end;

procedure TQMsgPack.SetIgnoreCase(const Value: Boolean);
  procedure InternalSetIgnoreCase(AParent: TQMsgPack);
  var
    I: Integer;
  begin
    AParent.FIgnoreCase := Value;
    if AParent.DataType in [mptArray, mptMap] then
    begin
      for I := 0 to AParent.Count - 1 do
        InternalSetIgnoreCase(AParent[I]);
    end;
    DoNodeNameChanged(AParent);
  end;

begin
  if FIgnoreCase <> Value then
    InternalSetIgnoreCase(Root);
end;

procedure TQMsgPack.SetKeyAsBoolean(const Value: Boolean);
begin
  FKeyType := mptBoolean;
  SetLength(FKey, 1);
  FKey[0] := Integer(Value);
  DoNodeNameChanged(Self);
end;

procedure TQMsgPack.SetKeyAsBytes(const Value: TBytes);
begin
  FKeyType := mptBinary;
  SetLength(FKey, Length(Value));
  if Length(Value) > 0 then
    Move(Value[0], FKey[0], Length(Value));
  DoNodeNameChanged(Self);
end;

procedure TQMsgPack.SetKeyAsDateTime(const Value: TDateTime);
begin
  FKeyType := mptDateTime;
  SetLength(FKey, SizeOf(TDateTime));
  PDateTime(@FKey[0])^ := Value;
  DoNodeNameChanged(Self);
end;

procedure TQMsgPack.SetKeyAsFloat(const Value: Double);
begin
  FKeyType := mptFloat;
  SetLength(FKey, SizeOf(Double));
  PDouble(@FKey[0])^ := Value;
  DoNodeNameChanged(Self);
end;

procedure TQMsgPack.SetKeyAsInt64(const Value: Int64);
begin
  FKeyType := mptInteger;
  SetLength(FKey, SizeOf(Int64));
  PInt64(@FKey[0])^ := Value;
  DoNodeNameChanged(Self);
end;

procedure TQMsgPack.SetKeyAsInteger(const Value: Integer);
begin
  SetKeyAsInt64(Value);
end;

procedure TQMsgPack.SetKeyAsSingle(const Value: Single);
begin
  FKeyType := mptSingle;
  SetLength(FKey, SizeOf(Single));
  PSingle(@FKey[0])^ := Value;
  DoNodeNameChanged(Self);
end;

procedure TQMsgPack.SetKeyAsString(const Value: QStringW);
begin
  if (FKeyType <> mptString) or (KeyAsString <> Value) then
  begin
    FKeyType := mptString;
    SetLength(FKey, Length(Value) shl 1);
    Move(PQCharW(Value)^, FKey[0], Length(FKey));
    DoNodeNameChanged(Self);
  end;
end;

procedure TQMsgPack.Sort(AByName, ANest: Boolean; AByType: TQMsgPackType;
  AOnCompare: TListSortCompare);
  procedure QuickSort(l, R: Integer; AOnCompare: TListSortCompare);
  var
    I, J, p: Integer;
  begin
    repeat
      I := l;
      J := R;
      p := (l + R) shr 1;
      repeat
        while AOnCompare(Items[I], Items[p]) < 0 do
          Inc(I);
        while AOnCompare(Items[J], Items[p]) > 0 do
          Dec(J);
        if I <= J then
        begin
          if I <> J then
            FItems.Exchange(I, J);
          if p = I then
            p := J
          else if p = J then
            p := I;
          Inc(I);
          Dec(J);
        end;
      until I > J;
      if l < J then
        QuickSort(l, J, AOnCompare);
      l := I;
    until I >= R;
  end;
  function DetectCompareType: TQMsgPackType;
  var
    I, C: Integer;
  begin
    C := Count;
    if C > 0 then
    begin
      Result := Items[0].DataType;
      Dec(C);
      for I := 1 to C do
      begin
        case Items[I].DataType of
          mptString:
            begin
              Result := mptString;
              Break;
            end;
          mptInteger:
            begin
              if Result in [mptNull, mptBoolean] then
                Result := mptInteger;
            end;
          mptSingle, mptFloat:
            begin
              if Result in [mptNull, mptBoolean, mptInteger, mptDateTime] then
                Result := mptFloat;
            end;
          mptBoolean:
            begin
              if Result = mptNull then
                Result := mptBoolean;
            end;
          mptDateTime:
            begin
              if Result in [mptNull, mptBoolean, mptInteger] then
                Result := mptDateTime;
            end;
          mptBinary:
            Result := mptBinary;
        end;
      end;
    end
    else
      Result := mptUnknown;
  end;
  procedure DoSort(ADataType: TQMsgPackType);
  begin
    case ADataType of
      mptString:
        QuickSort(0, Count - 1, DoCompareValueString);
      mptInteger:
        QuickSort(0, Count - 1, DoCompareValueInt);
      mptSingle, mptFloat:
        QuickSort(0, Count - 1, DoCompareValueFloat);
      mptBoolean:
        QuickSort(0, Count - 1, DoCompareValueBoolean);
      mptDateTime:
        QuickSort(0, Count - 1, DoCompareValueDateTime);
      mptBinary:
        QuickSort(0, Count - 1, DoCompareValueBinary);
    else
      Exit;
    end;
  end;
  procedure SortChildrens;
  var
    I, H: Integer;
    AItem: TQMsgPack;
  begin
    H := Count - 1;
    for I := 0 to H do
    begin
      AItem := Items[I];
      if AItem.IsObject then
        AItem.Sort(AByName, ANest, AByType, AOnCompare)
      else if (AItem.IsArray) and (not AByName) then
        AItem.Sort(AByName, ANest, AByType, AOnCompare);
    end;
  end;

begin
  if not Assigned(AOnCompare) then
  begin
    if AByName then
      QuickSort(0, Count - 1, DoCompareName)
    else if AByType = mptUnknown then
      DoSort(DetectCompareType)
    else
      DoSort(AByType);
  end
  else
    QuickSort(0, Count - 1, AOnCompare);
  if ANest then
    SortChildrens;
end;

procedure TQMsgPack.StreamFromValue(AStream: TStream);
var
  ABytes: TBytes;
begin
  ABytes := AsBytes;
  AStream.WriteBuffer(ABytes[0], Length(ABytes));
end;

{$IF RTLVersion>=21}

procedure TQMsgPack.ToRecord<T>(var ARecord: T; AClearCollections: Boolean);
begin
  ToRtti(@ARecord, TypeInfo(T), AClearCollections);
end;

procedure TQMsgPack.ToRtti(ADest: Pointer; AType: PTypeInfo;
  AClearCollections: Boolean);
  function MsgPackToValueArray(ATypeInfo: PTypeInfo; AMsgPack: TQMsgPack)
    : TValueArray;
  var
    I: Integer;
    AChild: TQMsgPack;
  begin
    SetLength(Result, AMsgPack.Count);
    for I := 0 to AMsgPack.Count - 1 do
    begin
      AChild := AMsgPack[I];
      case AChild.DataType of
        mptNull:
          Result[I] := TValue.Empty;
        mptString:
          Result[I] := AChild.AsString;
        mptInteger:
          Result[I] := AChild.AsInteger;
        mptSingle, mptFloat:
          Result[I] := AChild.AsFloat;
        mptBoolean:
          Result[I] := AChild.AsBoolean;
        mptDateTime:
          Result[I] := AChild.AsDateTime;
        mptArray:
          Result[I] := TValue.FromArray(TypeInfo(TValue),
            MsgPackToValueArray(ATypeInfo, AChild));
        mptMap:
          begin
            case ATypeInfo.Kind of
              tkRecord:
                begin

                end;
              tkClass:
                begin

                end;
            end;
            raise Exception.Create(SRttiComplexArrayNow);
          end;
        mptBinary, mptExtended:
          raise Exception.Create(SVariantNotSupport);
      end;
    end;
  end;

  procedure LoadCollection(AMsgPack: TQMsgPack; ACollection: TCollection);
  var
    I: Integer;
  begin
    if AClearCollections then
      ACollection.Clear;
    for I := 0 to AMsgPack.Count - 1 do
      AMsgPack[I].ToRtti(ACollection.Add);
  end;
  procedure ToRecord;
  var
    AContext: TRttiContext;
    AFields: TArray<TRttiField>;
    ARttiType: TRttiType;
    ABaseAddr: Pointer;
    J: Integer;
    AChild: TQMsgPack;
    AObj: TObject;
  begin
    AContext := TRttiContext.Create;
    ARttiType := AContext.GetType(AType);
    ABaseAddr := ADest;
    AFields := ARttiType.GetFields;
    for J := Low(AFields) to High(AFields) do
    begin
      if AFields[J].FieldType <> nil then
      begin
        AChild := ItemByName(AFields[J].Name);
        if AChild <> nil then
        begin
          case AFields[J].FieldType.TypeKind of
            tkInteger:
              AFields[J].SetValue(ABaseAddr, AChild.AsInteger);
{$IFNDEF NEXTGEN}
            tkString:
              PShortString(IntPtr(ABaseAddr) + AFields[J].Offset)^ :=
                ShortString(AChild.AsString);
{$ENDIF !NEXTGEN}
            tkUString{$IFNDEF NEXTGEN}, tkLString, tkWString{$ENDIF !NEXTGEN}:
              AFields[J].SetValue(ABaseAddr, AChild.AsString);
            tkEnumeration:
              begin
                if GetTypeData(AFields[J].FieldType.Handle)
                  ^.BaseType^ = TypeInfo(Boolean) then
                  AFields[J].SetValue(ABaseAddr, AChild.AsBoolean)
                else
                begin
                  case GetTypeData(AFields[J].FieldType.Handle).OrdType of
                    otSByte:
                      begin
                        if AChild.DataType = mptInteger then
                          PShortint(IntPtr(ABaseAddr) + AFields[J].Offset)^ :=
                            AChild.AsInteger
                        else
                          PShortint(IntPtr(ABaseAddr) + AFields[J].Offset)^ :=
                            GetEnumValue(AFields[J].FieldType.Handle,
                            AChild.AsString);
                      end;
                    otUByte:
                      begin
                        if AChild.DataType = mptInteger then
                          PByte(IntPtr(ABaseAddr) + AFields[J].Offset)^ :=
                            AChild.AsInteger
                        else
                          PByte(IntPtr(ABaseAddr) + AFields[J].Offset)^ :=
                            GetEnumValue(AFields[J].FieldType.Handle,
                            AChild.AsString);
                      end;
                    otSWord:
                      begin
                        if AChild.DataType = mptInteger then
                          PSmallint(IntPtr(ABaseAddr) + AFields[J].Offset)^ :=
                            AChild.AsInteger
                        else
                          PSmallint(IntPtr(ABaseAddr) + AFields[J].Offset)^ :=
                            GetEnumValue(AFields[J].FieldType.Handle,
                            AChild.AsString);
                      end;
                    otUWord:
                      begin
                        if AChild.DataType = mptInteger then
                          PWord(IntPtr(ABaseAddr) + AFields[J].Offset)^ :=
                            AChild.AsInteger
                        else
                          PWord(IntPtr(ABaseAddr) + AFields[J].Offset)^ :=
                            GetEnumValue(AFields[J].FieldType.Handle,
                            AChild.AsString);
                      end;
                    otSLong:
                      begin
                        if AChild.DataType = mptInteger then
                          PInteger(IntPtr(ABaseAddr) + AFields[J].Offset)^ :=
                            AChild.AsInteger
                        else
                          PInteger(IntPtr(ABaseAddr) + AFields[J].Offset)^ :=
                            GetEnumValue(AFields[J].FieldType.Handle,
                            AChild.AsString);
                      end;
                    otULong:
                      begin
                        if AChild.DataType = mptInteger then
                          PCardinal(IntPtr(ABaseAddr) + AFields[J].Offset)^ :=
                            AChild.AsInteger
                        else
                          PCardinal(IntPtr(ABaseAddr) + AFields[J].Offset)^ :=
                            GetEnumValue(AFields[J].FieldType.Handle,
                            AChild.AsString);
                      end;
                  end;
                end;
              end;
            tkSet:
              begin
                case GetTypeData(AFields[J].FieldType.Handle).OrdType of
                  otSByte:
                    begin
                      if AChild.DataType = mptInteger then
                        PShortint(IntPtr(ABaseAddr) + AFields[J].Offset)^ :=
                          AChild.AsInteger
                      else
                        PShortint(IntPtr(ABaseAddr) + AFields[J].Offset)^ :=
                          StringToSet(AFields[J].FieldType.Handle,
                          AChild.AsString);
                    end;
                  otUByte:
                    begin
                      if AChild.DataType = mptInteger then
                        PByte(IntPtr(ABaseAddr) + AFields[J].Offset)^ :=
                          AChild.AsInteger
                      else
                        PByte(IntPtr(ABaseAddr) + AFields[J].Offset)^ :=
                          StringToSet(AFields[J].FieldType.Handle,
                          AChild.AsString);
                    end;
                  otSWord:
                    begin
                      if AChild.DataType = mptInteger then
                        PSmallint(IntPtr(ABaseAddr) + AFields[J].Offset)^ :=
                          AChild.AsInteger
                      else
                        PSmallint(IntPtr(ABaseAddr) + AFields[J].Offset)^ :=
                          StringToSet(AFields[J].FieldType.Handle,
                          AChild.AsString);
                    end;
                  otUWord:
                    begin
                      if AChild.DataType = mptInteger then
                        PWord(IntPtr(ABaseAddr) + AFields[J].Offset)^ :=
                          AChild.AsInteger
                      else
                        PWord(IntPtr(ABaseAddr) + AFields[J].Offset)^ :=
                          StringToSet(AFields[J].FieldType.Handle,
                          AChild.AsString);
                    end;
                  otSLong:
                    begin
                      if AChild.DataType = mptInteger then
                        PInteger(IntPtr(ABaseAddr) + AFields[J].Offset)^ :=
                          AChild.AsInteger
                      else
                        PInteger(IntPtr(ABaseAddr) + AFields[J].Offset)^ :=
                          StringToSet(AFields[J].FieldType.Handle,
                          AChild.AsString);
                    end;
                  otULong:
                    begin
                      if AChild.DataType = mptInteger then
                        PCardinal(IntPtr(ABaseAddr) + AFields[J].Offset)^ :=
                          AChild.AsInteger
                      else
                        PCardinal(IntPtr(ABaseAddr) + AFields[J].Offset)^ :=
                          StringToSet(AFields[J].FieldType.Handle,
                          AChild.AsString);
                    end;
                end;
              end;
            tkChar, tkWChar:
              AFields[J].SetValue(ABaseAddr, AChild.AsString);
            tkFloat:
              begin
                if (AFields[J].FieldType.Handle = TypeInfo(TDateTime)) or
                  (AFields[J].FieldType.Handle = TypeInfo(TTime)) or
                  (AFields[J].FieldType.Handle = TypeInfo(TDate)) then
                  AFields[J].SetValue(ABaseAddr, AChild.AsDateTime)
                else
                  AFields[J].SetValue(ABaseAddr, AChild.AsFloat);
              end;
            tkInt64:
              AFields[J].SetValue(ABaseAddr, AChild.AsInt64);
            tkVariant:
              PVariant(IntPtr(ABaseAddr) + AFields[J].Offset)^ :=
                AChild.AsVariant;
            tkArray, tkDynArray:
              AFields[J].SetValue(ABaseAddr,
                TValue.FromArray(AFields[J].FieldType.Handle,
                MsgPackToValueArray(AFields[J].FieldType.Handle, AChild)));
            tkClass:
              begin
                AObj := AFields[J].GetValue(ABaseAddr).AsObject;
                if AObj is TStrings then
                  (AObj as TStrings).Text := AChild.AsString
                else if AObj is TCollection then
                  LoadCollection(AChild, AObj as TCollection)
                else
                  AChild.ToRtti(AObj);
              end;
            tkRecord:
              begin
                if AFields[J].FieldType.Handle = TypeInfo(TGuid) then
                  PGuid(IntPtr(ABaseAddr) + AFields[J].Offset)^ :=
                    StringToGuid(AChild.AsString)
                else
                  AChild.ToRtti(Pointer(IntPtr(ABaseAddr) + AFields[J].Offset),
                    AFields[J].FieldType.Handle);
              end;
          end;
        end;
      end;
    end;
  end;

  procedure ToObject;
  var
    AProp: PPropInfo;
    ACount: Integer;
    J: Integer;
    AObj, AChildObj: TObject;
    AChild: TQMsgPack;
  begin
    AObj := ADest;
    ACount := Count;
    if AObj is TStrings then
      (AObj as TStrings).Text := AsString
    else if AObj is TCollection then
      LoadCollection(Self, AObj as TCollection)
    else
    begin
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
                  (AChildObj as TStrings).Text := AChild.AsString
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
            tkInteger:
              SetOrdProp(AObj, AProp, AChild.AsInteger);
            tkFloat:
              begin
                if (AProp.PropType^ = TypeInfo(TDateTime)) or
                  (AProp.PropType^ = TypeInfo(TTime)) or
                  (AProp.PropType^ = TypeInfo(TDate)) then
                  SetFloatProp(AObj, AProp, AChild.AsDateTime)
                else
                  SetFloatProp(AObj, AProp, AChild.AsFloat);
              end;
            tkChar, tkString, tkWChar, tkLString, tkWString, tkUString:
              SetStrProp(AObj, AProp, AChild.AsString);
            tkEnumeration:
              begin
                if GetTypeData(AProp.PropType^)^.BaseType^ = TypeInfo(Boolean)
                then
                  SetOrdProp(AObj, AProp, Integer(AChild.AsBoolean))
                else if AChild.DataType = mptInteger then
                  SetOrdProp(AObj, AProp, AChild.AsInteger)
                else
                  SetEnumProp(AObj, AProp, AChild.AsString);
              end;
            tkSet:
              if AChild.DataType = mptInteger then
                SetOrdProp(AObj, AProp, AChild.AsInteger)
              else
                SetSetProp(AObj, AProp, AChild.AsString);
            tkVariant:
              SetVariantProp(AObj, AProp, AChild.AsVariant);
            tkInt64:
              SetInt64Prop(AObj, AProp, AChild.AsInt64);
          end;
        end;
      end;
    end;
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

  procedure SetDynArrayLen(arr: Pointer; AType: PTypeInfo; ALen: NativeInt);
  var
    pmem: Pointer;
  begin
    pmem := PPointer(arr)^;
    DynArraySetLength(pmem, AType, 1, @ALen);
    PPointer(arr)^ := pmem;
  end;

  procedure ToArray;
  var
    AContext: TRttiContext;
    ASubType: TRttiType;
    I, l, AOffset: Integer;
    s: QStringW;
    pd, pi: PByte;
    AChildObj: TObject;
    AChild: TQMsgPack;
  begin
    AContext := TRttiContext.Create;
{$IF RTLVersion>25}
    s := ArrayItemTypeName(AType.NameFld.ToString);
{$ELSE}
    s := ArrayItemTypeName(String(AType.Name));
{$IFEND}
    if Length(s) > 0 then
      ASubType := AContext.FindType(s)
    else
      ASubType := nil;
    if ASubType <> nil then
    begin
      l := Count;
      SetDynArrayLen(ADest, AType, l);
      pd := PPointer(ADest)^;
      for I := 0 to l - 1 do
      begin
        AOffset := I * GetTypeData(AType).elSize;
        pi := Pointer(IntPtr(pd) + AOffset);
        AChild := Items[I];
        case ASubType.TypeKind of
          tkInteger:
            begin
              case GetTypeData(ASubType.Handle).OrdType of
                otSByte:
                  PShortint(pi)^ := AChild.AsInteger;
                otUByte:
                  pi^ := AChild.AsInteger;
                otSWord:
                  PSmallint(pi)^ := AChild.AsInteger;
                otUWord:
                  PWord(pi)^ := AChild.AsInteger;
                otSLong:
                  PInteger(pi)^ := AChild.AsInteger;
                otULong:
                  PCardinal(pi)^ := AChild.AsInteger;
              end;
            end;
{$IFNDEF NEXTGEN}
          tkChar:
            pi^ := Ord(PAnsiChar(AnsiString(AChild.AsString))[0]);
{$ENDIF !NEXTGEN}
          tkEnumeration:
            begin
              if GetTypeData(ASubType.Handle)^.BaseType^ = TypeInfo(Boolean)
              then
                PBoolean(pi)^ := AChild.AsBoolean
              else
              begin
                case GetTypeData(ASubType.Handle)^.OrdType of
                  otSByte:
                    begin
                      if AChild.DataType = mptInteger then
                        PShortint(pi)^ := AChild.AsInt64
                      else
                        PShortint(pi)^ := GetEnumValue(ASubType.Handle,
                          AChild.AsString);
                    end;
                  otUByte:
                    begin
                      if AChild.DataType = mptInteger then
                        pi^ := AChild.AsInt64
                      else
                        pi^ := GetEnumValue(ASubType.Handle, AChild.AsString);
                    end;
                  otSWord:
                    begin
                      if AChild.DataType = mptInteger then
                        PSmallint(pi)^ := AChild.AsInt64
                      else
                        PSmallint(pi)^ := GetEnumValue(ASubType.Handle,
                          AChild.AsString);
                    end;
                  otUWord:
                    begin
                      if AChild.DataType = mptInteger then
                        PWord(pi)^ := AChild.AsInt64
                      else
                        PWord(pi)^ := GetEnumValue(ASubType.Handle,
                          AChild.AsString);
                    end;
                  otSLong:
                    begin
                      if AChild.DataType = mptInteger then
                        PInteger(pi)^ := AChild.AsInt64
                      else
                        PInteger(pi)^ := GetEnumValue(ASubType.Handle,
                          AChild.AsString);
                    end;
                  otULong:
                    begin
                      if AChild.DataType = mptInteger then
                        PCardinal(pi)^ := AChild.AsInt64
                      else
                        PCardinal(pi)^ := GetEnumValue(ASubType.Handle,
                          AChild.AsString);
                    end;
                end;
              end;
            end;
          tkFloat:
            case GetTypeData(ASubType.Handle)^.FloatType of
              ftSingle:
                PSingle(pi)^ := AChild.AsFloat;
              ftDouble:
                PDouble(pi)^ := AChild.AsFloat;
              ftExtended:
                PExtended(pi)^ := AChild.AsFloat;
              ftComp:
                PComp(pi)^ := AChild.AsFloat;
              ftCurr:
                PCurrency(pi)^ := AChild.AsFloat;
            end;
{$IFNDEF NEXTGEN}
          tkString:
            PShortString(pi)^ := ShortString(AChild.AsString);
{$ENDIF !NEXTGEN}
          tkSet:
            begin
              case GetTypeData(ASubType.Handle)^.OrdType of
                otSByte:
                  PShortint(pi)^ := StringToSet(ASubType.Handle,
                    AChild.AsString);
                otUByte:
                  pi^ := StringToSet(ASubType.Handle, AChild.AsString);
                otSWord:
                  PSmallint(pi)^ := StringToSet(ASubType.Handle,
                    AChild.AsString);
                otUWord:
                  PWord(pi)^ := StringToSet(ASubType.Handle, AChild.AsString);
                otSLong:
                  PInteger(pi)^ := StringToSet(ASubType.Handle,
                    AChild.AsString);
                otULong:
                  PCardinal(pi)^ := StringToSet(ASubType.Handle,
                    AChild.AsString);
              end;
            end;
          tkClass:
            begin
              if PPointer(pi)^ <> nil then
              begin
                AChildObj := PPointer(pi)^;
                if AChildObj is TStrings then
                  (AChildObj as TStrings).Text := AChild.AsString
                else if AChildObj is TCollection then
                  LoadCollection(AChild, AChildObj as TCollection)
                else
                  AChild.ToRtti(AChildObj);
              end;
            end;
          tkWChar:
            PWideChar(pi)^ := PWideChar(AChild.AsString)[0];
{$IFNDEF NEXTGEN}
          tkLString:
            PAnsiString(pi)^ := AnsiString(AChild.AsString);
          tkWString:
            PWideString(pi)^ := AChild.AsString;
{$ENDIF}
          tkVariant:
            PVariant(pi)^ := AChild.AsVariant;
          tkArray, tkDynArray:
            AChild.ToRtti(pi, ASubType.Handle);
          tkRecord:
            AChild.ToRtti(pi, ASubType.Handle);
          tkInt64:
            PInt64(pi)^ := AChild.AsInt64;
          tkUString:
            PUnicodeString(pi)^ := AChild.AsString;
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
    I, C, ASize: Integer;
    ASubType: PTypeInfo;
    AChild: TQMsgPack;
    AChildObj: TObject;
    pi: Pointer;
  begin
    C := Min(GetTypeData(AType).ArrayData.ElCount, Count);
    ASubType := GetFixedArrayItemType;
    if ASubType = nil then
      Exit;
    ASize := GetTypeData(ASubType).elSize;
    for I := 0 to C - 1 do
    begin
      pi := Pointer(IntPtr(ADest) + ASize * I);
      AChild := Items[I];
      case ASubType.Kind of
        tkInteger:
          begin
            case GetTypeData(ASubType).OrdType of
              otSByte:
                PShortint(pi)^ := AChild.AsInteger;
              otUByte:
                PByte(pi)^ := AChild.AsInteger;
              otSWord:
                PSmallint(pi)^ := AChild.AsInteger;
              otUWord:
                PWord(pi)^ := AChild.AsInteger;
              otSLong:
                PInteger(pi)^ := AChild.AsInteger;
              otULong:
                PCardinal(pi)^ := AChild.AsInteger;
            end;
          end;
{$IFNDEF NEXTGEN}
        tkChar:
          PByte(pi)^ := Ord(PAnsiChar(AnsiString(AChild.AsString))[0]);
{$ENDIF !NEXTGEN}
        tkEnumeration:
          begin
            if GetTypeData(ASubType)^.BaseType^ = TypeInfo(Boolean) then
              PBoolean(pi)^ := AChild.AsBoolean
            else
            begin
              case GetTypeData(ASubType)^.OrdType of
                otSByte:
                  begin
                    if AChild.IsOrdType then
                      PShortint(pi)^ := AChild.AsInteger
                    else
                      PShortint(pi)^ := GetEnumValue(ASubType, AChild.AsString);
                  end;
                otUByte:
                  begin
                    if AChild.IsOrdType then
                      PByte(pi)^ := AChild.AsInteger
                    else
                      PByte(pi)^ := GetEnumValue(ASubType, AChild.AsString);
                  end;
                otSWord:
                  begin
                    if AChild.IsOrdType then
                      PSmallint(pi)^ := AChild.AsInteger
                    else
                      PSmallint(pi)^ := GetEnumValue(ASubType, AChild.AsString);
                  end;
                otUWord:
                  begin
                    if AChild.IsOrdType then
                      PWord(pi)^ := AChild.AsInteger
                    else
                      PWord(pi)^ := GetEnumValue(ASubType, AChild.AsString);
                  end;
                otSLong:
                  begin
                    if AChild.IsOrdType then
                      PInteger(pi)^ := AChild.AsInteger
                    else
                      PInteger(pi)^ := GetEnumValue(ASubType, AChild.AsString);
                  end;
                otULong:
                  begin
                    if AChild.IsOrdType then
                      PCardinal(pi)^ := AChild.AsInteger
                    else
                      PCardinal(pi)^ :=
                        GetEnumValue(ASubType, Items[I].AsString);
                  end;
              end;
            end;
          end;
        tkFloat:
          case GetTypeData(ASubType)^.FloatType of
            ftSingle:
              PSingle(pi)^ := Items[I].AsFloat;
            ftDouble:
              PDouble(pi)^ := Items[I].AsFloat;
            ftExtended:
              PExtended(pi)^ := Items[I].AsFloat;
            ftComp:
              PComp(pi)^ := Items[I].AsFloat;
            ftCurr:
              PCurrency(pi)^ := Items[I].AsFloat;
          end;
{$IFNDEF NEXTGEN}
        tkString:
          PShortString(pi)^ := ShortString(Items[I].AsString);
{$ENDIF !NEXTGEN}
        tkSet:
          begin
            case GetTypeData(ASubType)^.OrdType of
              otSByte:
                begin
                  if AChild.IsOrdType then
                    PShortint(pi)^ := AChild.AsInteger
                  else
                    PShortint(pi)^ := StringToSet(ASubType, AChild.AsString);
                end;
              otUByte:
                begin
                  if AChild.IsOrdType then
                    PByte(pi)^ := AChild.AsInteger
                  else
                    PByte(pi)^ := StringToSet(ASubType, AChild.AsString);
                end;
              otSWord:
                begin
                  if AChild.IsOrdType then
                    PSmallint(pi)^ := AChild.AsInteger
                  else
                    PSmallint(pi)^ := StringToSet(ASubType, AChild.AsString);
                end;
              otUWord:
                begin
                  if AChild.IsOrdType then
                    PWord(pi)^ := AChild.AsInteger
                  else
                    PWord(pi)^ := StringToSet(ASubType, AChild.AsString);
                end;
              otSLong:
                begin
                  if AChild.IsOrdType then
                    PInteger(pi)^ := AChild.AsInteger
                  else
                    PInteger(pi)^ := StringToSet(ASubType, AChild.AsString);
                end;
              otULong:
                begin
                  if AChild.IsOrdType then
                    PCardinal(pi)^ := AChild.AsInteger
                  else
                    PCardinal(pi)^ := StringToSet(ASubType, Items[I].AsString);
                end;
            end;
          end;
        tkClass:
          begin
            if PPointer(pi)^ <> nil then
            begin
              AChildObj := PPointer(pi)^;
              if AChildObj is TStrings then
                (AChildObj as TStrings).Text := Items[I].AsString
              else if AChildObj is TCollection then
                LoadCollection(Items[I], AChildObj as TCollection)
              else
                Items[I].ToRtti(AChildObj);
            end;
          end;
        tkWChar:
          PWideChar(pi)^ := PWideChar(Items[I].AsString)[0];
{$IFNDEF NEXTGEN}
        tkLString:
          PAnsiString(pi)^ := AnsiString(Items[I].AsString);
        tkWString:
          PWideString(pi)^ := Items[I].AsString;
{$ENDIF}
        tkVariant:
          PVariant(pi)^ := Items[I].AsVariant;
        tkArray, tkDynArray:
          Items[I].ToRtti(pi, ASubType);
        tkRecord:
          Items[I].ToRtti(pi, ASubType);
        tkInt64:
          PInt64(pi)^ := Items[I].AsInt64;
        tkUString:
          PUnicodeString(pi)^ := Items[I].AsString;
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

procedure TQMsgPack.ToRtti(AInstance: TValue; AClearCollections: Boolean);
begin
  if AInstance.IsEmpty then
    Exit;
  if AInstance.Kind = tkRecord then
    ToRtti(AInstance.GetReferenceToRawData, AInstance.TypeInfo,
      AClearCollections)
  else if AInstance.Kind = tkClass then
    ToRtti(AInstance.AsObject, AInstance.TypeInfo, AClearCollections)
end;

function TQMsgPack.ToRttiValue: TValue;
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
  case DataType of
    mptString:
      Result := AsString;
    mptInteger:
      Result := AsInt64;
    mptSingle:
      Result := AsSingle;
    mptFloat:
      Result := AsFloat;
    mptDateTime:
      Result := AsDateTime;
    mptBoolean:
      Result := AsBoolean;
    mptBinary, mptExtended:
      raise Exception.Create(SUnsupportValueType);
    mptArray, mptMap: // 数组和对象都只能当成数组来处理
      AsDynValueArray
  else
    Result := TValue.Empty;
  end;
end;
{$IFEND >=2010}

function TQMsgPack.ToString: string;
begin
  if Length(FKey) > 0 then
    Result := Name + ':' + AsString
  else
    Result := AsString;
end;

function TQMsgPack.ValueByName(AName, ADefVal: QStringW): QStringW;
var
  AChild: TQMsgPack;
begin
  AChild := ItemByName(AName);
  if Assigned(AChild) then
    Result := AChild.AsString
  else
    Result := ADefVal;
end;

function TQMsgPack.ValueByPath(APath, ADefVal: QStringW): QStringW;
var
  AItem: TQMsgPack;
begin
  AItem := ItemByPath(APath);
  if Assigned(AItem) then
    Result := AItem.AsString
  else
    Result := ADefVal;
end;

procedure TQMsgPack.ValueFromFile(AFileName: QStringW);
var
  AStream: TFileStream;
begin
  AStream := TFileStream.Create(AFileName, fmOpenRead);
  try
    ValueFromStream(AStream, 0);
  finally
    FreeObject(AStream);
  end;
end;

procedure TQMsgPack.ValueFromStream(AStream: TStream; ACount: Cardinal);
var
  ABytes: TBytes;
begin
  if ACount = 0 then
  begin
    AStream.Position := 0;
    ACount := AStream.Size;
  end
  else if AStream.Position + ACount > AStream.Size then
    ACount := AStream.Size - AStream.Position;
  SetLength(ABytes, ACount);
  AStream.ReadBuffer(ABytes[0], ACount);
  AsBytes := ABytes;
end;

class procedure TQMsgPack.WriteArray(AStream: TStream; const ACount: Integer);
var
  AValue: TQMsgPackValue;
begin
  if ACount <= 15 then
  begin
    AValue.ValueType := $90 + ACount;
    AStream.WriteBuffer(AValue.ValueType, 1);
  end
  else if ACount <= 65535 then
  begin
    AValue.ValueType := $DC;
    AValue.BArray[0] := (ACount shr 8) and $FF;
    AValue.BArray[1] := ACount and $FF;
    AStream.WriteBuffer(AValue, 3);
  end
  else
  begin
    AValue.ValueType := $DD;
    AValue.BArray[0] := (ACount shr 24) and $FF;
    AValue.BArray[1] := (ACount shr 16) and $FF;
    AValue.BArray[2] := (ACount shr 8) and $FF;
    AValue.BArray[3] := ACount and $FF;
    AStream.WriteBuffer(AValue, 5);
  end;
end;

class procedure TQMsgPack.WriteBool(AStream: TStream; AValue: Boolean);
var
  b: Byte;
begin
  if AValue then
    b := $C3
  else
    b := $C2;
  AStream.WriteBuffer(b, 1);
end;

class procedure TQMsgPack.WriteBytes(AStream: TStream; const p: PByte;
  const l: Integer);
var
  AValue: TQMsgPackValue;
begin
  if l <= 255 then
  begin
    AValue.ValueType := $C4;
    AValue.U8Val := Byte(l);
    AStream.WriteBuffer(AValue, 2);
  end
  else if l <= 65535 then
  begin
    AValue.ValueType := $C5;
    AValue.BArray[0] := (l shr 8) and $FF;
    AValue.BArray[1] := l and $FF;
    AStream.WriteBuffer(AValue, 3);
  end
  else
  begin
    AValue.ValueType := $C6;
    AValue.BArray[0] := (l shr 24) and $FF;
    AValue.BArray[1] := (l shr 16) and $FF;
    AValue.BArray[2] := (l shr 8) and $FF;
    AValue.BArray[3] := l and $FF;
    AStream.WriteBuffer(AValue, 5);
  end;
  AStream.WriteBuffer(p^, l);
end;

class procedure TQMsgPack.WriteBytes(AStream: TStream; const ABytes: TBytes);
begin
  if Length(ABytes) > 0 then
    WriteBytes(AStream, @ABytes[0], Length(ABytes))
  else
    WriteBytes(AStream, @ABytes, 0);
end;

class procedure TQMsgPack.WriteDateTime(AStream: TStream; AValue: TDateTime;
  ADateTimeAsTimeStamp: Boolean);
var
  ts: TQMsgPackTimeStamp;
  V: Double;
  ABuf: array [0 .. 15] of Byte;
  ABuf32: array [0 .. 3] of Cardinal absolute ABuf;
  ABuf64: array [0 .. 1] of Int64 absolute ABuf;
begin
  if ADateTimeAsTimeStamp then
  begin
    V := AValue * 86400;
    ts.Seconds := Trunc(V - UnixDateDelta * Int64(86400));
    V := V * 10;
    ts.NanoSeconds := Trunc((V - Trunc(V)) * 1000000000);
    if ts.NanoSeconds = 0 then
    begin
      if ts.Seconds <= $FFFFFFFF then
      begin
        ABuf32[0] := ExchangeByteOrder(Cardinal(ts.Seconds));
        WriteExt(AStream, $FF, @ABuf[0], SizeOf(Cardinal));
        Exit;
      end
    end;
    if ts.Seconds <= Int64($3FFFFFFFF) then // 64位:30位纳秒,34位秒数
    begin
      ABuf64[0] := Int64(ts.NanoSeconds) shl 34;
      ABuf64[0]:=ABuf64[0]+ts.Seconds;
      ABuf64[0] := ExchangeByteOrder(ABuf64[0]);
      WriteExt(AStream, $FF, @ABuf[0], SizeOf(Int64));
    end
    else
    // 64位秒，32位纳秒
    begin
      ABuf64[1] := ExchangeByteOrder(ts.Seconds);
      ABuf32[1] := ExchangeByteOrder(ts.NanoSeconds);
      WriteExt(AStream, $FF, @ABuf[4], SizeOf(Int64) + SizeOf(Cardinal));
    end;
  end
  else
    WriteFloat(AStream, AValue);
end;

class procedure TQMsgPack.WriteExt(AStream: TStream; AType: Byte;
  const p: PByte; const l: Integer);
var
  AValue: TQMsgPackValue;
begin
  if l = 1 then
  begin
    AValue.ValueType := $D4;
    AValue.BArray[0] := AType;
    AValue.BArray[1] := p^;
    AStream.WriteBuffer(AValue, 3);
  end
  else if l = 2 then
  begin
    AValue.ValueType := $D5;
    AValue.BArray[0] := AType;
    PWord(@AValue.BArray[1])^ := PWord(p)^;
    AStream.WriteBuffer(AValue, 4);
  end
  else if l = 4 then
  begin
    AValue.ValueType := $D6;
    AValue.BArray[0] := AType;
    PInteger(@AValue.BArray[1])^ := PInteger(p)^;
    AStream.WriteBuffer(AValue, 6);
  end
  else if l = 8 then
  begin
    AValue.ValueType := $D7;
    AValue.BArray[0] := AType;
    PInt64(@AValue.BArray[1])^ := PInt64(p)^;
    AStream.WriteBuffer(AValue, 10);
  end
  else if l = 16 then
  begin
    AValue.ValueType := $D8;
    AValue.BArray[0] := AType;
    Move(p^, AValue.BArray[1], l);
    AStream.WriteBuffer(AValue, 18);
  end
  else if l <= 255 then
  begin
    AValue.ValueType := $C7;
    AValue.BArray[0] := Byte(l);
    AValue.BArray[1] := AType;
    AStream.WriteBuffer(AValue, 3);
    AStream.WriteBuffer(p^, l);
  end
  else if l <= 65535 then
  begin
    AValue.ValueType := $C8;
    AValue.BArray[0] := (l shr 8) and $FF;
    AValue.BArray[1] := (l and $FF);
    AValue.BArray[2] := AType;
    AStream.WriteBuffer(AValue, 4);
    AStream.WriteBuffer(p^, l);
  end
  else
  begin
    AValue.ValueType := $C8;
    AValue.BArray[0] := (l shr 24) and $FF;
    AValue.BArray[1] := (l shr 16) and $FF;
    AValue.BArray[2] := (l shr 8) and $FF;
    AValue.BArray[3] := (l and $FF);
    AValue.BArray[4] := AType;
    AStream.WriteBuffer(AValue, 6);
    AStream.WriteBuffer(p^, l);
  end;
end;

class procedure TQMsgPack.WriteFloat(AStream: TStream; AValue: Double);
var
  AType: Byte;
  v: Int64 absolute AValue;
begin
  v := ExchangeByteOrder(v);
  AType := $CB;
  AStream.WriteBuffer(AType, 1);
  AStream.WriteBuffer(v, 8);
end;

class procedure TQMsgPack.WriteInt(AStream: TStream; AValue: Int64);
var
  ABuf: array [0 .. 8] of Byte;
begin
  if AValue >= 0 then
  begin
    if AValue <= 127 then
    begin
      ABuf[0] := AValue;
      AStream.WriteBuffer(ABuf[0], 1);
    end
    else if AValue <= 255 then
    // UInt8
    begin
      ABuf[0] := $CC;
      ABuf[1] := Byte(AValue);
      AStream.WriteBuffer(ABuf, 2);
    end
    else if AValue <= 65535 then
    begin
      ABuf[0] := $CD;
      ABuf[1] := (AValue shr 8);
      ABuf[2] := (AValue and $FF);
      AStream.WriteBuffer(ABuf, 3);
    end
    else if AValue <= Cardinal($FFFFFFFF) then
    begin
      ABuf[0] := $CE;
      ABuf[1] := (AValue shr 24) and $FF;
      ABuf[2] := (AValue shr 16) and $FF;
      ABuf[3] := (AValue shr 8) and $FF;
      ABuf[4] := AValue and $FF;
      AStream.WriteBuffer(ABuf, 5);
    end
    else
    begin
      ABuf[0] := $CF;
      ABuf[1] := (AValue shr 56) and $FF;
      ABuf[2] := (AValue shr 48) and $FF;
      ABuf[3] := (AValue shr 40) and $FF;
      ABuf[4] := (AValue shr 32) and $FF;
      ABuf[5] := (AValue shr 24) and $FF;
      ABuf[6] := (AValue shr 16) and $FF;
      ABuf[7] := (AValue shr 8) and $FF;
      ABuf[8] := AValue and $FF;
      AStream.WriteBuffer(ABuf, 9);
    end;
  end
  else
  // <0
  begin
    if AValue <= -2147483648 then // 64位
    begin
      ABuf[0] := $D3;
      ABuf[1] := (AValue shr 56) and $FF;
      ABuf[2] := (AValue shr 48) and $FF;
      ABuf[3] := (AValue shr 40) and $FF;
      ABuf[4] := (AValue shr 32) and $FF;
      ABuf[5] := (AValue shr 24) and $FF;
      ABuf[6] := (AValue shr 16) and $FF;
      ABuf[7] := (AValue shr 8) and $FF;
      ABuf[8] := AValue and $FF;
      AStream.WriteBuffer(ABuf, 9);
    end
    else if AValue <= -32768 then
    begin
      ABuf[0] := $D2;
      ABuf[1] := (AValue shr 24) and $FF;
      ABuf[2] := (AValue shr 16) and $FF;
      ABuf[3] := (AValue shr 8) and $FF;
      ABuf[4] := AValue and $FF;
      AStream.WriteBuffer(ABuf, 5);
    end
    else if AValue <= -128 then
    begin
      ABuf[0] := $D1;
      ABuf[1] := (AValue shr 8);
      ABuf[2] := (AValue and $FF);
      AStream.WriteBuffer(ABuf, 3);
    end
    else if AValue < -32 then
    begin
      ABuf[0] := $D0;
      Shortint(ABuf[1]) := AValue;
      AStream.WriteBuffer(ABuf, 2);
    end
    else
    begin
      Shortint(ABuf[0]) := AValue;
      AStream.Write(ABuf, 1);
    end;
  end; // End <0
end;

class procedure TQMsgPack.WriteMap(AStream: TStream; const ACount: Integer);
var
  AValue: TQMsgPackValue;
begin
  if ACount <= 15 then
  begin
    AValue.ValueType := $80 + ACount;
    AStream.WriteBuffer(AValue.ValueType, 1);
  end
  else if ACount <= 65535 then
  begin
    AValue.ValueType := $DE;
    AValue.BArray[0] := (ACount shr 8) and $FF;
    AValue.BArray[1] := ACount and $FF;
    AStream.WriteBuffer(AValue, 3);
  end
  else
  begin
    AValue.ValueType := $DF;
    AValue.BArray[0] := (ACount shr 24) and $FF;
    AValue.BArray[1] := (ACount shr 16) and $FF;
    AValue.BArray[2] := (ACount shr 8) and $FF;
    AValue.BArray[3] := ACount and $FF;
    AStream.WriteBuffer(AValue, 5);
  end;
end;

class procedure TQMsgPack.WriteNull(AStream: TStream);
var
  v: Byte;
begin
  v := $C0;
  AStream.Write(v, 1);
end;

class procedure TQMsgPack.WriteSingle(AStream: TStream; AValue: Single);
var
  AType: Byte;
  v: Integer absolute AValue;
begin
  AType := $CA;
  v := ExchangeByteOrder(v);
  AStream.WriteBuffer(AType, 1);
  AStream.WriteBuffer(v, 4);
end;

class procedure TQMsgPack.WriteString(AStream: TStream; AValue: QStringW);
var
  U: QStringA;
  l: Integer;
  AVal: TQMsgPackValue;
begin
  U := qstring.UTF8Encode(AValue);
  l := U.Length;
  if l <= 31 then
  begin
    AVal.ValueType := $A0 + Byte(l);
    AStream.WriteBuffer(AVal.ValueType, 1);
  end
  else if l <= 255 then
  begin
    AVal.ValueType := $D9;
    AVal.U8Val := Byte(l);
    AStream.WriteBuffer(AVal, 2);
  end
  else if l <= 65535 then
  begin
    AVal.ValueType := $DA;
    AVal.U16Val := ((l shr 8) and $FF) or ((l shl 8) and $FF00);
    AStream.Write(AVal, 3);
  end
  else
  begin
    AVal.ValueType := $DB;
    AVal.BArray[0] := (l shr 24) and $FF;
    AVal.BArray[1] := (l shr 16) and $FF;
    AVal.BArray[2] := (l shr 8) and $FF;
    AVal.BArray[3] := l and $FF;
    AStream.WriteBuffer(AVal, 5);
  end;
  AStream.WriteBuffer(PQCharA(U)^, l);
end;

procedure TQMsgPack.Delete;
begin
  if Assigned(FParent) then
    FParent.Delete(ItemIndex)
  else
    FreeObject(Self);
end;

{ TQMsgPackEnumerator }

constructor TQMsgPackEnumerator.Create(AList: TQMsgPack);
begin
  inherited Create;
  FList := AList;
  FIndex := -1;
end;

function TQMsgPackEnumerator.GetCurrent: TQMsgPack;
begin
  Result := FList[FIndex];
end;

function TQMsgPackEnumerator.MoveNext: Boolean;
begin
  if FIndex < FList.Count - 1 then
  begin
    Inc(FIndex);
    Result := True;
  end
  else
    Result := False;
end;

{ TQHashedMsgPack }

procedure TQHashedMsgPack.Assign(ANode: TQMsgPack);
var
  I: Integer;
begin
  inherited;
  if (Length(FKey) > 0) and (FKeyHash = 0) then
  begin
    FKeyHash := HashName(Name);
    if Assigned(Parent) and (Parent.DataType = mptMap) then
      TQHashedMsgPack(Parent).HashTable.Add(Self, FKeyHash);
  end;
  if DataType = mptMap then
  begin
    for I := 0 to Count - 1 do
    begin
      ANode := Items[I];
      ANode.HashNeeded;
      HashTable.Add(ANode, ANode.NameHash);
    end;
  end;
end;

procedure TQHashedMsgPack.Clear;
begin
  inherited;
  if DataType = mptMap then
    HashTable.Clear;
end;

constructor TQHashedMsgPack.Create;
begin
  inherited;

end;

function TQHashedMsgPack.CreateItem: TQMsgPack;
begin
  if Assigned(OnQMsgPackCreate) then
    Result := OnQMsgPackCreate
  else
    Result := TQHashedMsgPack.Create;
end;

function TQHashedMsgPack.CreateNew: TQMsgPack;
begin
  Result := TQHashedMsgPack.Create;
end;

destructor TQHashedMsgPack.Destroy;
begin
  inherited;
  if Assigned(FHashTable) then
    FreeAndNilObject(FHashTable);
end;

procedure TQHashedMsgPack.DoNodeMoved(ANode: TQMsgPack);
var
  AParent: TQHashedMsgPack;
begin
  inherited;
  if FParent is TQHashedMsgPack then
  begin
    AParent := FParent as TQHashedMsgPack;
    HashNeeded;
    if (AParent.DataType = mptMap) and
      (not AParent.HashTable.Exists(ANode, ANode.FKeyHash)) then
      AParent.HashTable.Add(ANode, ANode.FKeyHash);
  end;
end;

procedure TQHashedMsgPack.DoNodeNameChanged(ANode: TQMsgPack);
  procedure Rehash;
  var
    AHash: TQHashType;
    AList: PQHashList;
    AItem: TQMsgPack;
  begin
    AHash := HashName(ANode.Name);
    if AHash <> ANode.FKeyHash then
    begin
      AList := TQHashedMsgPack(ANode.Parent).HashTable.FindFirst
        (ANode.FKeyHash);
      while AList <> nil do
      begin
        AItem := AList.Data;
        if AItem = ANode then
        begin
          TQHashedMsgPack(ANode.Parent).HashTable.ChangeHash(ANode,
            ANode.FKeyHash, AHash);
          ANode.FKeyHash := AHash;
          Break;
        end
        else
          AList := TQHashedMsgPack(ANode.Parent).HashTable.FindNext(AList);
      end;
    end;
  end;

begin
  if Assigned(ANode.Parent) and (ANode.Parent.DataType = mptMap) then
  begin
    if ANode.FKeyHash = 0 then
    begin
      ANode.FKeyHash := HashName(ANode.Name);
      TQHashedMsgPack(ANode.Parent).HashTable.Add(ANode, ANode.FKeyHash);
    end
    else
      Rehash;
  end;
end;

procedure TQHashedMsgPack.DoParsed;
var
  I: Integer;
  AMsgPack: TQMsgPack;
begin
  if DataType = mptMap then
    HashTable.Resize(Count);
  for I := 0 to Count - 1 do
  begin
    AMsgPack := Items[I];
    if (Length(AMsgPack.FKey) > 0) and (DataType = mptMap) then
    begin
      if AMsgPack.FKeyHash = 0 then
      begin
        AMsgPack.FKeyHash := HashName(AMsgPack.Name);
        HashTable.Add(AMsgPack, AMsgPack.FKeyHash);
      end;
    end;
    if AMsgPack.Count > 0 then
      AMsgPack.DoParsed;
  end;
end;

function TQHashedMsgPack.GetHashTable: TQHashTable;
begin
  if not Assigned(FHashTable) then
  begin
    FHashTable := TQHashTable.Create();
    FHashTable.AutoSize := True;
  end;
  Result := FHashTable;
end;

function TQHashedMsgPack.IndexOf(const AName: QStringW): Integer;
var
  AHash: TQHashType;
  AList: PQHashList;
  AItem: TQMsgPack;
begin
  if DataType = mptMap then
  begin
    AHash := HashName(AName);
    AList := HashTable.FindFirst(AHash);
    Result := -1;
    while AList <> nil do
    begin
      AItem := AList.Data;
      if StrCmpW(PQCharW(AItem.Name), PQCharW(AName), IgnoreCase) = 0 then
      begin
        Result := AItem.ItemIndex;
        Break;
      end
      else
        AList := HashTable.FindNext(AList);
    end;
  end
  else
    Result := -1;
end;

function TQHashedMsgPack.ItemByName(AName: QStringW): TQMsgPack;
  function ByHash: TQMsgPack;
  var
    AHash: TQHashType;
    AList: PQHashList;
    AItem: TQMsgPack;
  begin
    AHash := HashName(AName);
    AList := HashTable.FindFirst(AHash);
    Result := nil;
    while AList <> nil do
    begin
      AItem := AList.Data;
      if StrCmpW(PQCharW(AItem.Name), PQCharW(AName), IgnoreCase) = 0 then
      begin
        Result := AItem;
        Break;
      end
      else
        AList := HashTable.FindNext(AList);
    end;
  end;

begin
  if DataType = mptMap then
    Result := ByHash
  else
    Result := inherited ItemByName(AName);
end;

function TQHashedMsgPack.Remove(AIndex: Integer): TQMsgPack;
begin
  Result := inherited Remove(AIndex);
  if Assigned(Result) and (DataType = mptMap) then
    HashTable.Delete(Result, Result.NameHash);
end;

procedure TQHashedMsgPack.Replace(AIndex: Integer; ANewItem: TQMsgPack);
var
  AOld: TQMsgPack;
begin
  if not(ANewItem is TQHashedMsgPack) then
    raise Exception.CreateFmt(SReplaceTypeNeed, ['TQHashedMsgPack']);
  AOld := Items[AIndex];
  if DataType = mptMap then
    HashTable.Delete(AOld, AOld.NameHash);
  inherited;
  if Length(ANewItem.FKey) > 0 then
  begin
    if ANewItem.FKeyHash = 0 then
      ANewItem.FKeyHash := HashName(ANewItem.Name);
    if DataType = mptMap then
      HashTable.Add(ANewItem, ANewItem.FKeyHash);
  end;
end;

initialization

MsgPackDateFormat := 'yyyy-mm-dd';
MsgPackTimeFormat := 'hh:nn:ss.zzz';
MsgPackDateTimeFormat := 'yyyy-mm-dd"T"hh:nn:ss.zzz';
MsgPackCaseSensitive := True;
MsgPackRttiEnumAsInt := True;
OnQMsgPackCreate := nil;
OnQMsgPackFree := nil;

end.
