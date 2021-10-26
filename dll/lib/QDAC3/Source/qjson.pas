unit qjson;
{$I 'qdac.inc'}

interface

{
  本源码来自QDAC项目，版权归swish(QQ:109867294)所有。
  (1)、使用许可及限制
  您可以自由复制、分发、修改本源码，但您的修改应该反馈给作者，并允许作者在必要时，
  合并到本项目中以供使用，合并后的源码同样遵循QDAC版权声明限制。
  您的产品的关于中，应包含以下的版本声明:
  本产品使用的JSON解析器来自QDAC项目中的QJSON，版权归作者所有。
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
  2017.3.27
  ==========
  + 增加 ForEach 函数和 Sort 函数的重载
  2017.2.26
  ==========
  * 修正了 Replace 未处理父结点的问题（cntlis报告）
  2017.4.10
  ==========
  + 修正了大浮点数判断时出错的问题（SeMain报告）

  2017.1.1
  ==========
  + 增加 Insert 系列函数，用于在指定的位置插入一个结点（阿木、恢弘建议）                                     {￥I不【

  2016.11.23
  ==========
  + 增加 Reset 函数，重置结点的所有内容，同时也会从父结点中移除自身（不得闲报告）

  2016.11.16
  ==========
  * 修正了 FromRtti 时，对象只读或只写的属性保存，造成ToRtti恢复属性值时无法处理的问题（KEN报告）
  2016.11.02
  ==========
  * 修正了 Merge 合并时，参数为 Ignore 时未考虑子元素不同的问题，造成子元素没有合并的问题（阿木报告）

  2016.8.23
  ==========
  * 修正了 ToFixedArray 没有比较数组元素个数与子结点数的造成可能访问越界的问题（随云报告）
  2016.6.24
  ==========
  * 修正了 JsonCat 时分配内存空间可能不足的问题（熊猫叔叔报告）
  * 修改对 encddecd 单元的引用（恢弘建议）
  2016.2.24
  ==========
  * 修正了 ItemByPath 时对特殊数组路径解析存在的问题（恢弘报告）
  2016.1.25
  ==========
  * 修正了 TQHashedJson 在析构时，提前释放了 FHashTable 的问题
  2016.1.23
  ==========
  * 修改 SetValue 函数自动检测类型的代码，避免抛出异常

  2016.1.11
  ==========
  + 新增 Equals 函数判定两个 JSON 内容是否相同
  + 新增 CommentStyle 和 Comment 属性来管理备注
  + 新增 Merge/Intersect/Diff 函数来进行内容的合并、求重和差异比较
  2015.11.19
  ===========
  * 修正了TQHashedJson添加结点时，没有正确对名称进行哈希的问题（QQ报告）
  * 修正了 FromRtti 在 Win64 时，如果没有子属性时出错的问题

  2015.10.30
  ===========
  * 修正了TQJsonStreamHelper.EndArray时，JSON编码可能出错的问题(中国制造报告）
  2015.10.23
  ===========
  + ForceName 确保指定的名称存在

  2015.10.20
  ==========
  + Exists 函数判断是否包含指定路径的子结点（阿木建议）
  + Sort 排序子结点（恢弘建议）
  + ExchangeOrder 交换两个结点
  + ContainsName 判断是否有指定名称的子结点
  + ContainsValue 判断是否包含指定值的子结点（青春建议）

  2015.10.8
  ==========
  * 修正了名称末尾包含空格时错误的自动移除的问题

  2015.9.22
  ==========
  * 修正了TQJsonStreamHelper写入对象或数组时，如果没有子元素时造成格式错乱的问题

  2015.7.20
  ==========
  * 更改了 ToRtti 时对采用默认值对象属性的控制方法
  * 修正了 ToRtti 和 FromRtti 落下 TDateTime 类型属性的问题（感谢好人一生平安）
  2015.6.23
  =========
  + 新增 TQJsonStreamHelper 用于直接向流中写入 JSON 格式的数据，优点是由于省略了
  TQJson对象的创建和维速度更快，缺点是需要自行控制更多的步骤（如数组和对象的闭合）
  2015.5.22
  =========
  + 增加二进制编码为Base64的默认启用函数 EncodeJsonBinaryAsBase64，如果要恢复默认，则用
  EncodeJsonBinaryAsHex

  2015.4.21
  =========
  + IgnoreCase 属性用于控制Json对象自身的区分大小写属性，默认继承自全局的JsonCaseSensitive属性值（恢弘建议）
  + Root 属性用于返回根结点
  * HashName 从 TQHashedJson 移到 TQJson
  2015.2.6
  =========
  * 修正了 AsInteger/AsFloat 时不支持十六进制的问题

  2015.2.1
  =========
  * 修改了解析和编码的行为，兼容名称为空字符串的JSON代码（感谢 Synopse）
  2015.1.26
  ==========
  + 增加无参数的Delete函数用于删除结点自身

  2015.1.19
  ==========
  * 公开了编码时的一些特定字符为变量，这样方便程序员手动自己控制编码的结果以增加可读性（阿木建议）
  * 修正了重复调用 FromRtti 时没有清空末次值的问题（阿木报告）

  2015.1.13
  ==========
  * 修正了 TQHashedJson 的 IndexOf 未正确处理大小写的问题
  * 修正了 TQHashedJson 在解析完成后未正确重新计算哈希值的问题（阿木报告）
  * 修正了解析数值类型时 Parse 时未正确移除名称空格的问题

  2015.1.6
  ========
  * 修正了SetAsVariant对非标准的变体类型的支持问题（小枫报告）

  2015.1.5
  =========
  * 修正了IsChildOf的一处判断错误，造成可能发生AV异常

  2015.1.4
  =========
  * 修改了 ItemByName 的部分代码，修正了没有正确处理 JsonCaseSensitive 标记的问题,造成忽略大小写无效的问题(阿木）
  * 修正了 ItemByName 对数组下标处理的逻辑错误
  * 修正了 ItemByPath 不支持多维数组的问题
  2015.1.3
  =========
  * SaveToStream/SaveToFile 增加了一个ADoFormat参数，以便控制是否格式化（恢弘、阿木建议）
  2014.12.24
  ==========
  * 修正了解析Json中包含注释时，处理不够全面的问题（kylix2008报告）

  2014.12.13
  ==========
  + 增加HasChild函数，来判定指定路径的子结点是否存在（阿木建议）

  2014.11.25
  ==========
  * 修改了ItemByPath的代码，支持按索引顺序来访问jdtObject类型的子成员

  2014.11.24
  ==========
  * 修正了ToRtti.FoArray的行为，在子类型名字未找到时，提示异常

  2014.11.20
  ==========
  + 加入AsBytes属性，以支持二进制数据类型，默认实现直接使用的十六进制字符串表达，
  上层可以重载OnQJsonEncodeBytes和OnQJsonDecodeBytes事件来替换为自己的实现（如
  ZLib+Base64）
  + 加入ValueFromStream/ValueFromFile/StreamFromValue/StreamFromFile函数

  2014.11.14
  ==========
  * 修正了GetAsVariant时没有处理jdtNull类型的问题

  2014.11.13
  ==========
  + 加入IsBool属性判断当前值是否能转换为布尔值访问（五月光_???-建议）
  2014.11.10
  ==========
  * 修正了FromRtti/ToRtti在处理TCollection类型时存在的问题(阿木报告)
  * 修正了FromRtti中ToObject子函数的一处错误(hq200306报告)

  2014.11.6
  ==========
  * 修正了FromRtti时集合类型元素添加结点时，AName误写成Name造成结点未命名的问题（阿木报告）
  + 新增IntByPath,IntByName，BoolByPath,BoolByName,FloatByPath,FloatByName,DateTimeByPath,
  DateTimeByName函数，以简化判断编程(FreeSpace8建议)

  2014.10.30
  ==========
  + 新增Detach、AttachTo、MoveTo、Remove函数
  * 允许Json结点名称重命名以避免调用MoveTo、AttachTo时元素未命名

  2014.9.11
  =========
  * 修正了从流或文件中加载空白JSON数组和对象时出错的问题（恢弘报告）
  * 修改直接将非对象或数组值保存到流中的策略（麦子仲肥报告）：
  1、如果JSON结点的名称已经指定，则保存为对象的一个子对象；
  2、如果未指定名称，且类型为未知或为jdtNull，则不保存任何内容
  2014.9.3
  =========
  * 修正了解析特殊字符串值时可能丢失字符的问题(阿木报告)

  2014.8.27
  =========
  * 修正了解析数组或对象结束符前有行注释时出错的问题(阿木报告)
  2014.8.15
  =========
  * 修正了Add函数自动检测内容类型时，添加特定格式如11,23时解析出错的问题(Tuesday报告)
  2014.7.31
  =========
  * 修正了解析出错时，如果行过长，系统异常无法完整显示的问题(音儿小白报告)
  * 修正了解析时可能陷入死循环的问题（音儿小白报告）
  * 修正了出现异常时，异常行提示重复的问题
  * 修正了ForcePath时'array[].subobjectname'未正确生成路径的问题(音儿小白报告)
  2014.7.28
  =========
  * 修正了ToRtti如果源类型是日期时间类型，而JSON为null时解析出错的问题(恢宏报告)
  * 修改ToRecord参数类型为var，而不是const(恢宏报告)
  2014.7.16
  =========
  * 修正了GetPath时，未初始化结果字符串造成Path属性可能出错的问题(音儿小白报告)
  2014.7.6
  =========
  + ToRtti加入对静态数组类型的支持

  2014.7.3
  =========
  * 修正了Assign时复制了当前结点名称的问题

  2014.7.1
  =========
  * AsString修改jdtNull/jdtUnknown时，改为返回空字符串
  2014.6.28
  =========
  * 修正了ForcePath('Items[]')默认添加了空子结点的问题(pony,光明报告)
  + 加入JsonRttiEnumAsInt全局选项，控制枚举值和集合值是否保存成其字符串表达，默认为True(恢弘建议)
  2014.6.27
  =========
  + 增加TryParse函数（恢弘建议）
  * 修改了Encode时将自己的名称也加到了结果字符串中的问题（恢弘报告）
  * 修正了FromRTTI时，对于方法、事件等属性没有进行过滤的问题
  * 修正了ToRtti.ToArray时，对于动态数组的设置长度时类型错误（恢弘报告）
  2014.6.26
  ==========
  * 修正了ToRtti.ToRecord子函数处理日期类型时的错误(感谢群友恢弘大量的RTTI建议和测试)
  * 加入HPPEMIT默认链接本单元(麦子仲肥 建议)
  2014.6.23
  ==========
  + FromRecord支持动态数组和普通数组
  2014.6.21
  ==========
  * 移除原来AddObject/AddRecord/ToObject/ToRecord支持
  + 添加FromRtti/ToRtti/FromRecord/ToRecord/ToRttiValue函数支持，替换原来的RTTI函数
  + 添加Invoke函数，支持直接通过Json调用对应的函数，具体参考Demo
  2014.6.17
  =========
  * AsFloat赋值时加入对Nan、Infinite、NegInfinite三个无效值的检查
  * AsVariant赋值时加入对varNull,varEmpty,varUnknown,varUInt64类型的支持
  2014.5.27
  ==========
  + TQHashedJson 支持，这是一个面向查询优化的版本，使用哈希表加快ItemByName的查询速度，
  如果您的应用中大量的使用ItemByName、ItemByPath等查询，使用它代替TQJson，否则应直接
  使用TQJson

  2014.5.14
  =========
  + 加入CopyIf/DeleteIf/FindIf函数
  + 加入for..in语法支持
  * 修正了Encode和ForcePath可能存在的问题

  2014.5.6
  ========
  + 加入ParseBlock函数，以支持流式传送分段解析
  * 修正了解析\uxxxx时的识别错误
  * 修改Parse函数为清除已有子结点

  2014.5.4
  ========
  + 加入对JavaScript和.net的日期时间类型/DATE(MillSeconds+TimeZone)/格式的支持
  * Json数据支持加入VCL的TDateTime类型支持，生成的JSON数据默认由JsonDateFormat、
  JsonTimeFormat,JsonDateTimeFormat三个变量控制，如果StrictJson变量为True，则
  生成/DATE(MillSeconds+TimeZone)/格式
  【注】
  日期时间类型仅适用于运行时，生成JSON后实际上仍为字符串，这种字符串再次打开时
  将丢失类型信息，但您仍可以直接以AsDateTime属性来读写。如果日期时间类型使用
  JavaScript和.net格式并且包含了时区信息，则时间将被转换为格林威治时间。

  2014.5.1
  ========
  + 加入AddRecord函数，支持直接保存记录数据，但以下类型的成员会被忽略
  对象(Class)、函数(Method)、接口(Interface)、类型引用(ClassRef),指针(Pointer)、过程(Procedure)
  将来可能根据实际需要决定是否添加支持
  + 加入ToRecord函数，完成Json直接到记录类型的转换
  + 加入Copy函数用于创建当前结点的一个拷贝实例，注意目前版本克隆内部调用了Copy函数，将来可能改掉
  * 修正了Assign函数的一处错误
}
// 测试环境仅为Delphi 2007或XE6，其它版本的开发环境，请自行修改
uses classes, sysutils, math, qstring, typinfo, qrbtree,
{$IF RTLVersion>27}
  System.NetEncoding{$ELSE}EncdDecd{$IFEND}
{$IFDEF MSWINDOWS}, windows{$ENDIF}
{$IFDEF UNICODE}, Generics.Collections{$ENDIF}{$IF RTLVersion>=21},
  Rtti{$IFEND >=XE10}
{$IF RTLVersion<22}// 2007-2010
{$IFDEF ENABLE_REGEX}
    , PerlRegEx, pcre
{$ENDIF}
{$ELSE}
    , RegularExpressionsCore
{$IFEND}
    ;
{$M+}
{$HPPEMIT '#pragma link "qjson"'}
{$IF RTLVersion<=27}
{$HPPEMIT '#pragma link "soaprtl.lib"'}
{$IFEND}

// 如果要使用类名来表示方式，如TForm1.FormCreate,则启用下面的定义，否则方法名为Form1.FormCreate
{ .$DEFINE TYPENAMEASMETHODPREF }
type
  /// 本单元是QDAC的组成部分，受QDAC授权限制，详情访问QDAC网站了解
  /// <summary>
  /// JSON解析单元，用于快速解析和维护JSON结构.全局变量StrictJson为False时，支持
  /// 注释和名称不包含'"'。
  /// </summary>
  /// TQJsonDataType用于记录JSON数据元的类型，可取值包括：
  /// <list>
  /// <item>
  /// <term>jdtUnknown</term><description>未知类型，只有新构造对象未赋值时，才会是该类型</description>
  /// </item>
  /// <item>
  /// <term>jdtNull</term><description>NULL</description>
  /// </item>
  /// <item>
  /// <term>jdtString</term><description>字符串</description>
  /// </item>
  /// <item>
  /// <term>jdtInteger</term><description>整数(Int64,不管整数值多大，内部均使用64位整数存贮)</description>
  /// </item>
  /// <item>
  /// <term>jdtFloat</term><description>双精度浮点数(Double)</description>
  /// </item>
  /// <item>
  /// <term>jdtBoolean</term><description>布尔</description>
  /// </item>
  /// <item>
  /// <term>jdtDateTime</term><description>日期时间类型</description>
  /// </item>
  /// <item>
  /// <term>jdtArray</term><description>数组</description>
  /// </item>
  /// <item>
  /// <term>jdtObject</term><description>对象</description>
  /// </item>
  /// </list>
  TQJsonDataType = (jdtUnknown, jdtNull, jdtString, jdtInteger, jdtFloat,
    jdtBoolean, jdtDateTime, jdtArray, jdtObject);
  TQJson = class;
{$IF RTLVersion>=21}
  /// <summary>
  /// RTTI信息过滤回调函数，在XE6上支持匿名函数，在XE及以前的版本采用事件回调
  /// </summary>
  /// <param name="ASender">触发事件的TQJson对象</param>
  /// <param name="AName">属性名(AddObject)或字段名(AddRecord)</param>
  /// <param name="AType">属性或字段的类型信息</param>
  /// <param name="Accept">是否记录该属性或字段</param>
  /// <param name="ATag">用户自定义的附加数据成员</param>
  TQJsonRttiFilterEventA = reference to procedure(ASender: TQJson;
    AObject: Pointer; AName: QStringW; AType: PTypeInfo; var Accept: Boolean;
    ATag: Pointer);
  /// <summary>
  /// 结点过滤处理函数，以在XE6上支持匿名函数
  /// </summary>
  /// <param name="ASender">触发事件的TQJson对象</param>
  /// <param name="AItem">要过滤的对象</param>
  /// <param name="Accept">是否要处理该对象</param>
  /// <param name="ATag">用户附加的数据项</param>
  TQJsonFilterEventA = reference to procedure(ASender, AItem: TQJson;
    var Accept: Boolean; ATag: Pointer);
{$IFEND >=2010}
  /// <summary>
  /// RTTI信息过滤回调函数，在XE6上支持匿名函数，在XE及以前的版本采用事件回调
  /// </summary>
  /// <param name="ASender">触发事件的TQJson对象</param>
  /// <param name="AName">属性名(AddObject)或字段名(AddRecord)</param>
  /// <param name="AType">属性或字段的类型信息</param>
  /// <param name="Accept">是否记录该属性或字段</param>
  /// <param name="ATag">用户自定义的附加数据成员</param>
  TQJsonRttiFilterEvent = procedure(ASender: TQJson; AObject: Pointer;
    AName: QStringW; AType: PTypeInfo; var Accept: Boolean; ATag: Pointer)
    of object;
  /// <summary>
  /// 结点过滤处理函数，以在XE6上支持匿名函数
  /// </summary>
  /// <param name="ASender">触发事件的TQJson对象</param>
  /// <param name="AItem">要过滤的对象</param>
  /// <param name="Accept">是否要处理该对象</param>
  /// <param name="ATag">用户附加的数据项</param>
  TQJsonFilterEvent = procedure(ASender, AItem: TQJson; var Accept: Boolean;
    ATag: Pointer) of object;
  TListSortCompareEvent = function(Item1, Item2: Pointer): Integer of object;
  PQJson = ^TQJson;
{$IF RTLVersion>=21}
  TQJsonItemList = TList<TQJson>;
{$ELSE}
  TQJsonItemList = TList;
{$IFEND}
  /// <summary>
  /// TQJsonTagType用于内部AddObject和AddRecord函数的内部过滤使用
  /// </summary>
  /// <list>
  /// <item>
  /// <term>ttAnonEvent</term><description>回调匿名函数</description>
  /// <term>ttNameFilter</term><description>属性或成员名称过滤</descriptio>
  /// </list>
  TQJsonTagType = (ttAnonEvent, ttNameFilter);
  PQJsonInternalTagData = ^TQJsonInternalTagData;

  /// <summary>
  /// TQJsonInternalTagData用于AddRecord和AddObject函数需要内部过滤RTTI信息时使用
  /// </summary>
  TQJsonInternalTagData = record
    /// <summary>Tag数据的类型</summary>
    TagType: TQJsonTagType;
{$IF RTLVersion>=21}
    /// <summary>过滤使用的匿名函数</summary>
    OnEvent: TQJsonRttiFilterEventA;
{$IFEND >=2010}
    /// <summary>接受的属性(AddObject)或记录字段(AddRecord)名称，如果名称同时在IgnoreNames出现，则IgnoreNames里的信息被忽略</summary>
    AcceptNames: QStringW;
    /// <summary>忽略的属性(AddObject)或记录字段(AddRecord)名称，如果名称同时在AcceptNameds里，则AcceptNames优先</summary>
    IgnoreNames: QStringW;
    /// <summary>原始传递给AddObject或AddRecord的附加数据成员，它将被传递给OnEvent的Tag，以供用户使用</summary>
    Tag: Pointer;
  end;

  TQJsonEnumerator = class;
  /// <summary>用于外部支持对象池的函数，创建一个新的QJSON对象，注意从池中创建的对象</summary>
  /// <returns>返回新创建的QJSON对象</returns>
  TQJsonCreateEvent = function: TQJson;
  /// <summary>用于外部将对象缓存，以便重用对象</summary>
  /// <param name="AJson">要释放的Json对象</param>
  TQJsonFreeEvent = procedure(AJson: TQJson);
  /// <summary>
  /// JSON 编码成字符串时的控制选项
  /// </summary>
  /// <list>
  /// <item>
  /// <term>jesIgnoreNull</term><description>忽略jdtNull/jdtUnknown类型成员</description>
  /// </item>
  /// <item>
  /// <term>jdtIgnoreDefault</term><description>忽略掉jdtNull/jdtUnknown类型及其它类型的默认值：空字符串/0/false</description>
  /// </item>
  /// <item>
  /// <term>jesDoFormat</term><description>格式化 JSON 字符串</description>
  /// </item>
  /// <item>
  /// <term>jesDoEscape</term><description>转义Unicode字符</description>
  /// </item>
  /// <item>
  /// <term>jesNullAsString</term><description>将 jdtNull/jdtUnknown 转换为空字符串</description>
  /// </item>
  /// <item>
  /// <term>jesJavaDateTime</term><description>日期时间类型转化为 Java 的 /DATE/ 表述形式</description>
  /// </item>
  /// <item>
  /// <term>jesWithComment</term><description>编码时包含注释</description>
  /// </item>
  /// </list>
  TJsonEncodeSetting = (jesIgnoreNull, jesIgnoreDefault, jesDoFormat,
    jesDoEscape, jesNullAsString, jesJavaDateTime, jesWithComment);
  TJsonEncodeSettings = set of TJsonEncodeSetting;

  TQJsonEncodeBytesEvent = procedure(const ABytes: TBytes;
    var AResult: QStringW);
  TQJsonDecodeBytesEvent = procedure(const S: QStringW; var AResult: TBytes);

  EJsonError = class(Exception)
  private
    FRow, FCol: Integer;
  public
    property Row: Integer read FRow;
    property Col: Integer read FCol;
  end;

  // </summary>
  /// TQJsonCommentStyle 用于记录JSON中注释的类型，注意，严格模式下，注释将被忽略
  /// <list>
  /// <item>
  /// <term>jcsIgnore</term><description>保存时忽略原来的注释</description>
  /// <term>jcsInherited</term><description>保存时由父结点的设置决定注释出现的位置</description>
  /// <term>jcsBeforeName</term><description>在项目名之前进行注释</description>
  /// <term>jcsAfterValue</term><description>在项目值之后，逗号分隔符前进行注释</description>
  /// </item>
  TQJsonCommentStyle = (jcsIgnore, jcsInherited, jcsBeforeName, jcsAfterValue);
  TQJsonMergeMethod = (jmmIgnore, jmmAsSource, jmmAppend, jmmReplace);
  TQJsonForEachCallback = procedure(AItem: TQJson; ATag: Pointer) of object;
  TQJsonMatchFilterCallback = procedure(AItem: TQJson; ATag: Pointer;
    var Accept: Boolean) of object;
{$IFDEF UNICODE}
  TQJsonForEachCallbackA = reference to procedure(AItem: TQJson);
  TQJsonMatchFilterCallbackA = reference to procedure(AItem: TQJson;
    var Accept: Boolean);
{$ENDIF}
  TQJsonMatchSetting = (jmsIgnoreCase, jmsNest, jmsMatchName, jmsMatchPath,
    jmsMatchValue);
  TQJsonMatchSettings = set of TQJsonMatchSetting;
  TQJsonContainerEnumerator = class;

  IQJsonContainer = interface
    ['{C9FF8471-19FC-435A-B1A7-21F0D5206720}']
    function GetCount: Integer;
    function GetItems(const AIndex: Integer): TQJson;
    function ForEach(ACallback: TQJsonForEachCallback; ATag: Pointer = nil)
      : IQJsonContainer; overload;
{$IFDEF UNICODE}
    function ForEach(ACallback: TQJsonForEachCallbackA)
      : IQJsonContainer; overload;
    function Match(const AFilter: TQJsonMatchFilterCallbackA;
      ATag: Pointer = nil): IQJsonContainer; overload;
{$ENDIF}
    function Match(const ARegex: QStringW; ASettings: TQJsonMatchSettings)
      : IQJsonContainer; overload;
    function Match(const AIndexes: array of Integer): IQJsonContainer; overload;
    function Match(const AStart, AStop, AStep: Integer)
      : IQJsonContainer; overload;
    function Match(const AFilter: TQJsonMatchFilterCallback;
      ATag: Pointer = nil): IQJsonContainer; overload;
    function GetEnumerator: TQJsonContainerEnumerator;
    function GetIsEmpty: Boolean;
    property Items[const AIndex: Integer]: TQJson read GetItems; default;
    property Count: Integer read GetCount;
    property IsEmpty: Boolean read GetIsEmpty;
  end;

  TQJsonContainerEnumerator = class
  private
    FIndex: Integer;
    FList: IQJsonContainer;
  public
    constructor Create(AList: IQJsonContainer);
    function GetCurrent: TQJson; inline;
    function MoveNext: Boolean;
    property Current: TQJson read GetCurrent;
  end;

  TQJsonContainer = class(TInterfacedObject, IQJsonContainer)
  protected
    FItems: TQJsonItemList;
    function GetCount: Integer;
    function GetItems(const AIndex: Integer): TQJson;
    function ForEach(ACallback: TQJsonForEachCallback; ATag: Pointer = nil)
      : IQJsonContainer; overload;
{$IFDEF UNICODE}
    function ForEach(ACallback: TQJsonForEachCallbackA)
      : IQJsonContainer; overload;
    function Match(const AFilter: TQJsonMatchFilterCallbackA;
      ATag: Pointer = nil): IQJsonContainer; overload;
{$ENDIF}
    function Match(const ARegex: QStringW; ASettings: TQJsonMatchSettings)
      : IQJsonContainer; overload;
    function Match(const AIndexes: array of Integer): IQJsonContainer; overload;
    function Match(const AStart, AStop, AStep: Integer)
      : IQJsonContainer; overload;
    function Match(const AFilter: TQJsonMatchFilterCallback; ATag: Pointer)
      : IQJsonContainer; overload;
    function GetIsEmpty: Boolean;
    function GetEnumerator: TQJsonContainerEnumerator;
  public
    constructor Create; overload;
    constructor Create(AJson: TQJson); overload;
    destructor Destroy; override;
  end;

  // TQJsonSortFlags=(jsmAsString,);
  /// <summary>
  /// TQJson用于解析并维护JSON格式的对象类型，要使用前，需要先在堆中创建对应的实例。
  /// TQJson和TQXML在绝大多数接口上保持一致，但由于Json是有类型信息，而XML没有类型
  /// 信息（始终认为是字符串），因此少部分接口会略有不同.
  /// 与其它实现不同，QJSON所有的类型都是同一个对象实现，根据DataType的不同，而使用
  /// 不同的成员来访问。当类型为jdtArray或者是jdtObject时，它可以有子结点.
  /// </summary>
  TQJson = class
  protected
    FName: QStringW;
    FNameHash: Cardinal;
    FDataType: TQJsonDataType;
    FValue: QStringW;
    FComment: QStringW;
    FCommentStyle: TQJsonCommentStyle;
    FParent: TQJson;
    FData: Pointer;
    FItems: TQJsonItemList;
    FIgnoreCase: Boolean;
    function GetValue: QStringW;
    procedure SetValue(const Value: QStringW);
    procedure SetDataType(const Value: TQJsonDataType);
    function TryGetAsBoolean(var AValue: Boolean): Boolean;
    function GetAsBoolean: Boolean;
    function TryGetAsFloat(var AValue: Extended): Boolean;
    function GetAsFloat: Extended;
    function TryGetAsInt64(var AValue: Int64): Boolean;
    function GetAsInt64: Int64;
    function GetAsInteger: Integer;
    function GetAsString: QStringW;
    function GetAsObject: QStringW;
    procedure SetAsObject(const Value: QStringW);
    function TryGetAsDateTime(var AValue: TDateTime): Boolean;
    function GetAsDateTime: TDateTime;
    procedure SetAsBoolean(const Value: Boolean);
    procedure SetAsFloat(const Value: Extended);
    procedure SetAsInt64(const Value: Int64);
    procedure SetAsInteger(const Value: Integer);
    procedure SetAsString(const Value: QStringW);
    procedure SetAsDateTime(const Value: TDateTime);
    function GetCount: Integer;
    function GetItems(AIndex: Integer): TQJson;
    class function CharUnescape(var p: PQCharW): QCharW;
    class function CharEscape(c: QCharW; pd: PQCharW): Integer;
    procedure ArrayNeeded(ANewType: TQJsonDataType);
    procedure ValidArray;
    procedure ParseObject(var p: PQCharW);
    function ParseJsonPair(ABuilder: TQStringCatHelperW;
      var p: PQCharW): Integer;
    function ParseName(ABuilder: TQStringCatHelperW; var p: PQCharW): Integer;
    procedure ParseValue(ABuilder: TQStringCatHelperW; var p: PQCharW);
    function FormatParseError(ACode: Integer; AMsg: QStringW; ps, p: PQCharW)
      : QStringW;
    function FormatParseErrorEx(ACode: Integer; AMsg: QStringW; ps, p: PQCharW)
      : EJsonError;
    procedure RaiseParseException(ACode: Integer; ps, p: PQCharW);
    function TryParseValue(ABuilder: TQStringCatHelperW;
      var p: PQCharW): Integer;
    function BooleanToStr(const b: Boolean): QStringW;
    function GetIsNull: Boolean;
    function GetIsNumeric: Boolean;
    function GetIsArray: Boolean;
    function GetIsObject: Boolean;
    function GetIsString: Boolean;
    function GetIsDateTime: Boolean;
    function GetAsArray: QStringW;
    procedure SetAsArray(const Value: QStringW);
    function GetPath: QStringW;
    function GetAsVariant: Variant;
    procedure SetAsVariant(const Value: Variant);
    function GetAsJson: QStringW;
    procedure SetAsJson(const Value: QStringW);
    function GetItemIndex: Integer;
    function ParseJsonTime(p: PQCharW; var ATime: TDateTime): Boolean;
    function CreateJson: TQJson; virtual;
    procedure FreeJson(AJson: TQJson); inline;
    procedure CopyValue(ASource: TQJson); inline;
    procedure Replace(AIndex: Integer; ANewItem: TQJson); virtual;
    procedure InternalRttiFilter(ASender: TQJson; AObject: Pointer;
      APropName: QStringW; APropType: PTypeInfo; var Accept: Boolean;
      ATag: Pointer);
    function InternalEncode(ABuilder: TQStringCatHelperW;
      ASettings: TJsonEncodeSettings; const AIndent: QStringW)
      : TQStringCatHelperW;
    function ArrayItemTypeName(ATypeName: QStringW): QStringW;
    function ArrayItemType(ArrType: PTypeInfo): PTypeInfo;
    procedure DoJsonNameChanged(AJson: TQJson); virtual;
    procedure SetName(const Value: QStringW);
    function GetIsBool: Boolean;
    function GetAsBytes: TBytes;
    procedure SetAsBytes(const Value: TBytes);
    class function SkipSpaceAndComment(var p: PQCharW; var AComment: QStringW;
      lastvalidchar: Char = #0): Integer;
    procedure DoParsed; virtual;
    procedure SetIgnoreCase(const Value: Boolean);
    function HashName(const S: QStringW): TQHashType;
    procedure HashNeeded; inline;
    procedure FromType(const AValue: String; AType: TQJsonDataType);
    function GetRoot: TQJson;
    function DoCompareName(Item1, Item2: Pointer): Integer;
    function DoCompareValueBoolean(Item1, Item2: Pointer): Integer;
    function DoCompareValueDateTime(Item1, Item2: Pointer): Integer;
    function DoCompareValueFloat(Item1, Item2: Pointer): Integer;
    function DoCompareValueInt(Item1, Item2: Pointer): Integer;
    function DoCompareValueString(Item1, Item2: Pointer): Integer;
    function GetA(const APath: String): TQJson;
    function GetB(const APath: String): Boolean;
    function GetF(const APath: String): Double;
    function GetI(const APath: String): Int64;
    function GetO(const APath: String): TQJson;
    function GetS(const APath: String): String;
    function GetT(const APath: String): TDateTime;
    function GetV(const APath: String): Variant;
    procedure SetA(const APath: String; const Value: TQJson);
    procedure SetB(const APath: String; const Value: Boolean);
    procedure SetF(const APath: String; const Value: Double);
    procedure SetI(const APath: String; const Value: Int64);
    procedure SetO(const APath: String; const Value: TQJson);
    procedure SetS(const APath, Value: String);
    procedure SetT(const APath: String; const Value: TDateTime);
    procedure SetV(const APath: String; const Value: Variant);
    function GetAsBase64Bytes: TBytes;
    procedure SetAsBase64Bytes(const Value: TBytes);
    function GetAsHexBytes: TBytes;
    procedure SetAsHexBytes(const Value: TBytes);
    function InternalGetAsBytes(AConverter: TQJsonDecodeBytesEvent;
      AEncoding: TTextEncoding; AWriteBom: Boolean): TBytes;
    procedure InternalSetAsBytes(AConverter: TQJsonEncodeBytesEvent;
      ABytes: TBytes);
  public
    /// <summary>构造函数</summary>
    constructor Create; overload;
    constructor Create(const AName, AValue: QStringW;
      ADataType: TQJsonDataType = jdtUnknown); overload;
    /// <summary>析构函数</summary>
    destructor Destroy; override;
    { <summary>添加一个子结点</summary>
      <param name="ANode">要添加的结点</param>
      <returns>返回添加的结点索引</returns>
    }
    function Add(ANode: TQJson): Integer; overload;
    /// <summary>添加一个未命名的JSON子结点</summary>
    /// <returns>返回添加的结点实例</returns>
    /// <remarks>
    /// 一般情况下，除非数组类型，不应添加未命名的实例
    /// </remarks>
    function Add: TQJson; overload;
    /// <summary>添加一个数组</summary>
    /// <param name="AName">要添加的对象的结点名称</param>
    /// <param name="AValue">要添加的内容的值表达式（字符串）</param>
    /// <param name="ADataType">表达式类型，如果为jdtUnknown，则会自动检测内容类型</param>
    /// <returns>返回创建的结点索引</returns>
    function Add(AName, AValue: QStringW; ADataType: TQJsonDataType)
      : Integer; overload;
    /// <summary>添加一个数组</summary>
    /// <param name="AName">要添加的对象的结点名称</param>
    /// <param name="AItems">要添加的数组内容</param>
    /// <returns>返回创建的结点实例</returns>
    function Add(const AName: QStringW; AItems: array of const)
      : TQJson; overload;
    { <summary>添加一个子结点</summary>
      <param name="AName">要添加的结点名</param>
      <param name="ADataType">要添加的结点数据类型，如果省略，则自动根据值的内容检测</param>
      <returns>返回添加的新对象</returns>
      <remarks>
      1.如果当前类型不是jdtObject或jdtArray，将自动转换为jdtObject类型
      2.上层应自己负责重名检查
      </remarks>
    }
    function Add(AName: QStringW; ADataType: TQJsonDataType): TQJson; overload;

    /// <summary>添加一个子结点</summary>
    /// <param name="AName">要添加的结点名，如果当前结点为数组，则在输出时会忽略该值</param>
    /// <param name="AValue">要添加的结点值</param>
    /// <returns>返回添加的新对象</returns>
    function Add(AName: QStringW; AValue: Extended): TQJson; overload;
    /// <summary>添加一个子结点</summary>
    /// <param name="AName">要添加的结点名，如果当前结点为数组，则在输出时会忽略该值</param>
    /// <param name="AValue">要添加的结点值</param>
    /// <returns>返回添加的新对象</returns>
    function Add(AName: QStringW; AValue: Int64): TQJson; overload;
    /// <summary>添加一个子结点</summary>
    /// <param name="AName">要添加的结点名，如果当前结点为数组，则在输出时会忽略该值</param>
    /// <param name="AValue">要添加的结点值</param>
    /// <returns>返回添加的新对象</returns>
    function Add(AName: QStringW; AValue: Boolean): TQJson; overload;
    /// <summary>添加一个子结点</summary>
    /// <param name="AName">要添加的结点名，如果当前结点为数组，则在输出时会忽略该值</param>
    /// <param name="AValue">要添加的子结点</param>
    /// <returns>返回添加的新对象的索引位置</returns>
    /// <remarks>添加的结点释放归主本结点负责，外部不应再释放</remarks>
    function Add(AName: QStringW; AChild: TQJson): Integer; overload;
    /// <summary>添加一个数组类型子结点</summary>
    /// <param name="AName">要添加的结点名，如果当前结点为数组，则在输出时会忽略该值</param>
    /// <returns>返回添加的新对象</returns>
    function AddArray(AName: QStringW): TQJson; overload;
    /// <summary>添加一个子结点</summary>
    /// <param name="AName">要添加的结点名，如果当前结点为数组，则在输出时会忽略该值</param>
    /// <param name="AValue">要添加的结点值</param>
    /// <returns>返回添加的新对象</returns>
    function AddDateTime(AName: QStringW; AValue: TDateTime): TQJson; overload;
    /// <summary>添加一个子结点</summary>
    /// <param name="AName">要添加的结点名，如果当前结点为数组，则在输出时会忽略该值</param>
    /// <param name="AValue">要添加的结点值</param>
    /// <returns>返回添加的新对象</returns>
    function AddVariant(AName: QStringW; AValue: Variant): TQJson; overload;
    /// <summary>添加一个子结点(Null)</summary>
    /// <param name="AName">要添加的结点名，如果当前结点为数组，则在输出时会忽略该值</param>
    /// <returns>返回添加的新对象</returns>
    function Add(AName: QStringW): TQJson; overload; virtual;

    function Insert(AIndex: Integer; const AName: String): TQJson; overload;
    function Insert(AIndex: Integer; const AName: String;
      ADataType: TQJsonDataType): TQJson; overload;
    function Insert(AIndex: Integer; const AName, AValue: String;
      ADataType: TQJsonDataType = jdtString): TQJson; overload;
    function Insert(AIndex: Integer; const AName: String; AValue: Extended)
      : TQJson; overload;
    function Insert(AIndex: Integer; const AName: String; AValue: Int64)
      : TQJson; overload;
    function Insert(AIndex: Integer; const AName: String; AValue: Boolean)
      : TQJson; overload;
    procedure Insert(AIndex: Integer; AChild: TQJson); overload;
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
    function ForcePath(APath: QStringW): TQJson;
    /// <summary>确保指定名称的子结点存在</summary>
    /// <param name="AName">子结点名称</param>
    /// <param name="AType">子结点的类型</param>
    /// <returns>如果子结点存在，则返回指定的子结点，如果不存在，则添加子结点并返回</returns>
    /// <remarks>与 Add 函数的区别在于它会检查子结点是否存在，以避免重复，而 Add 不检查。与ForcePath的区别在于不会识别名称中的特殊字符，从而允许创建特殊的名称</remarks>
    function ForceName(AName: QStringW;
      AType: TQJsonDataType = jdtNull): TQJson;
    /// <summary>解析指定的JSON字符串</summary>
    /// <param name="p">要解析的字符串</param>
    /// <param name="l">字符串长度，<=0认为是以\0(#0)结尾的C语言标准字符串</param>
    /// <remarks>如果l>=0，会检测p[l]是否为\0，如果不为\0，则会创建拷贝实例并解析拷贝实例</remarks>
    procedure Parse(p: PWideChar; l: Integer = -1); overload;
    /// <summary>解析指定的JSON字符串</summary>
    /// <param name="s">要解析的JSON字符串</param>
    procedure Parse(const S: QStringW); overload;
    function TryParse(p: PWideChar; l: Integer = -1): Boolean; overload;
    /// <summary>解析指定的JSON字符串</summary>
    /// <param name="s">要解析的JSON字符串</param>
    function TryParse(const S: QStringW): Boolean; overload;
    /// <summmary>从流中解析首个JSON数据块</summary>
    /// <param name="AStream">流对象</param>
    /// <param name="AEncoding">流数据的编码方式</param>
    /// <remarks>ParseBlock适合解析分段式JSON，它会从当前位置开始，解析到当前对象结束为止.
    /// 可以很好的满足渐进式传输的需要</remarks>
    procedure ParseBlock(AStream: TStream; AEncoding: TTextEncoding);
    /// <summary>拷贝生成一个新的实例</summary>
    /// <returns>返回新的拷贝实例</returns>
    /// <remarks>因为是拷贝，所以新旧对象之间的内容变更没有任何关系，更改任意一个
    /// 对象，不会对另外一个对象造成影响。
    /// </remarks>
    function Copy: TQJson;
{$IF RTLVersion>=21}
    /// <summary>拷贝生成一个新的实例</summary>
    /// <param name="ATag">用户附加的标签数据</param>
    /// <param name="AFilter">用户过滤事件，用于控制要拷贝的内容</param>
    /// <returns>返回新的拷贝实例</returns>
    /// <remarks>因为是拷贝，所以新旧对象之间的内容变更没有任何关系，更改任意一个
    /// 对象，不会对另外一个对象造成影响。
    /// </remarks>
    function CopyIf(const ATag: Pointer; AFilter: TQJsonFilterEventA)
      : TQJson; overload;
{$IFEND >=2010}
    /// <summary>拷贝生成一个新的实例</summary>
    /// <param name="ATag">用户附加的标签数据</param>
    /// <param name="AFilter">用户过滤事件，用于控制要拷贝的内容</param>
    /// <returns>返回新的拷贝实例</returns>
    /// <remarks>因为是拷贝，所以新旧对象之间的内容变更没有任何关系，更改任意一个
    /// 对象，不会对另外一个对象造成影响。
    /// </remarks>
    function CopyIf(const ATag: Pointer; AFilter: TQJsonFilterEvent)
      : TQJson; overload;
    /// <summary>克隆生成一个新的实例</summary>
    /// <returns>返回新的拷贝实例</returns>
    /// <remarks>因为实际上执行的是拷贝，所以新旧对象之间的内容变更没有任何关系，
    /// 更改任意一个对象，不会对另外一个对象造成影响，但此行为将来并不保证，可能
    /// 会调整为引用，以便相互影响。
    /// </remarks>
    function Clone: TQJson;
    /// <summary>编码为字符串</summary>
    /// <param name="ADoFormat">是否格式化字符串，以增加可读性</param>
    /// <param name="ADoEscape">是否转义非字母和数字字符</param>
    /// <param name="AIndent">ADoFormat参数为True时，缩进内容，默认为两个空格</param>
    /// <returns>返回编码后的字符串</returns>
    /// <remarks>AsJson等价于Encode(True,'  ')</remarks>
    function Encode(ADoFormat: Boolean; ADoEscape: Boolean = False;
      AIndent: QStringW = '  '): QStringW; overload;
    function Encode(ASettings: TJsonEncodeSettings; AIndent: QStringW = '  ')
      : QStringW; overload;
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
    /// <summary>获取指定名称的第一个结点</summary>
    /// <param name="AName">结点名称</param>
    /// <returns>返回找到的结点，如果未找到，返回空(NULL/nil)</returns>
    /// <remarks>注意QJson并不检查重名，因此，如果存在重名的结点，只会返回第一个结点</remarks>
    function ItemByName(AName: QStringW): TQJson; overload; virtual;
    /// <summary>获取指定名称的结点到列表中</summary>
    /// <param name="AName">结点名称</param>
    /// <param name="AList">用于保存结点的列表对象</param>
    /// <param name="ANest">是否递归查找子结点</param>
    /// <returns>返回找到的结点数量，如果未找到，返回0</returns>
    /// <remarks>此函数不支持按数组下标方式检索</remarks>
    function ItemByName(const AName: QStringW; AList: TQJsonItemList;
      ANest: Boolean = False): Integer; overload;
{$IFDEF ENABLE_REGEX}
    /// <summary>获取符合指定名称规则的结点到列表中</summary>
    /// <param name="ARegex">正则表达式</param>
    /// <param name="AList">用于保存结点的列表对象</param>
    /// <param name="ANest">是否递归查找子结点</param>
    /// <returns>返回找到的结点数量，如果未找到，返回0</returns>
    function ItemByRegex(const ARegex: QStringW; AList: TQJsonItemList;
      ANest: Boolean = False): Integer; overload;
    function Match(const ARegex: QStringW; AMatches: TQJsonMatchSettings)
      : IQJsonContainer;
{$ENDIF}
    /// <summary>获取指定路径的JSON对象</summary>
    /// <param name="APath">路径，以"."或"/"或"\"分隔</param>
    /// <returns>返回找到的子结点，如果未找到返回NULL(nil)</returns>
    /// <remarks>对于数组或对象子结点，可以直接使用下标来访问，多层的数组和对象子结点，可以使用[][]这样子来访问。</remarks>
    function ItemByPath(APath: QStringW): TQJson;
    /// <summary>从源对象复制JSON对象内容</summary>
    /// <param name="ANode">要复制的源结点</param>
    /// <remarks>注意不要复制子结点给自己，否则会造成死循环。要复制子结点，先复
    /// 制一个子结点的新实例，再从新实例复制
    /// </remarks>
    procedure Assign(ANode: TQJson); virtual;
    /// <summary>删除指定索引的子结点</summary>
    /// <param name="AIndex">要删除的结点索引</param>
    /// <remarks>
    /// 如果指定索引的结点不存在，则抛出EOutRange异常
    /// </remarks>
    procedure Delete(AIndex: Integer); overload; virtual;
    /// <summary>删除指定名称的子结点</summary>
    /// <param name="AName">要删除的结点名称</param>
    /// <remarks>
    /// 如果要多个重名的结点，则只删除第一个
    procedure Delete(AName: QStringW); overload;
    /// <summary>从父结点中删除自身，如果没有父结点，则释放自己</summary>
    procedure Delete; overload;
{$IF RTLVersion>=21}
    /// <summary>
    /// 删除符合条件的子结点
    /// </summary>
    /// <param name="ATag">用户自己附加的额外标记</param>
    /// <param name="ANest">是否嵌套调用，如果为false，则只对当前子结点过滤</param>
    /// <param name="AFilter">过滤回调函数，如果为nil，等价于Clear</param>
    procedure DeleteIf(const ATag: Pointer; ANest: Boolean;
      AFilter: TQJsonFilterEventA); overload;
{$IFEND >=2010}
    /// <summary>
    /// 删除符合条件的子结点
    /// </summary>
    /// <param name="ATag">用户自己附加的额外标记</param>
    /// <param name="ANest">是否嵌套调用，如果为false，则只对当前子结点过滤</param>
    /// <param name="AFilter">过滤回调函数，如果为nil，等价于Clear</param>
    procedure DeleteIf(const ATag: Pointer; ANest: Boolean;
      AFilter: TQJsonFilterEvent); overload;
    /// <summary>查找指定名称的结点的索引</summary>
    /// <param name="AName">要查找的结点名称</param>
    /// <returns>返回索引值，未找到返回-1</returns>
    function IndexOf(const AName: QStringW): Integer; virtual;
    /// <summary>查找指定的值的结点索引</summary>
    /// <param name="AValue">要查找的结点值</param>
    /// <param name="AStrict">是否按严格模式比较</param>
    /// <returns>返回索引值，未找到返回-1</returns>
    function IndexOfValue(const AValue: Variant;
      AStrict: Boolean = False): Integer;
    /// <summary>遍历所有的子结点</summary>
    /// <param name="ACallback">遍历回调函数</param>
    /// <param name="ANest">是否嵌套调用，如果为false，则只对当前子结点过滤</param>
    /// <param name="ATag">用户自定义的附加额外标记</param>
    procedure ForEach(ACallback: TQJsonFilterEvent; ANest: Boolean;
      const ATag: Pointer); overload;
{$IF RTLVersion>=21}
    /// <summary>遍历所有的子结点</summary>
    /// <param name="ACallback">遍历回调函数</param>
    /// <param name="ANest">是否嵌套调用，如果为false，则只对当前子结点过滤</param>
    /// <param name="ATag">用户自定义的附加额外标记</param>
    procedure ForEach(ACallback: TQJsonFilterEventA; ANest: Boolean;
      const ATag: Pointer); overload;
    /// <summary>遍历结点查找符合条件的结点</summary>
    /// <param name="ATag">用户自定义的附加额外标记</param>
    /// <param name="ANest">是否嵌套调用，如果为false，则只对当前子结点过滤</param>
    /// <param name="AFilter">过滤回调函数，如果为nil，则返回nil</param>
    function FindIf(const ATag: Pointer; ANest: Boolean;
      AFilter: TQJsonFilterEventA): TQJson; overload;
{$IFEND >=2010}
    /// <summary>遍历结点查找符合条件的结点</summary>
    /// <param name="ATag">用户自定义的附加额外标记</param>
    /// <param name="ANest">是否嵌套调用，如果为false，则只对当前子结点过滤</param>
    /// <param name="AFilter">过滤回调函数，如果为nil，则返回nil</param>
    function FindIf(const ATag: Pointer; ANest: Boolean;
      AFilter: TQJsonFilterEvent): TQJson; overload;
    /// <summary>清除所有的结点</summary>
    procedure Clear; virtual;
    /// <summary>保存当前对象内容到流中</summary>
    /// <param name="AStream">目标流对象</param>
    /// <param name="AEncoding">编码格式</param>
    /// <param name="AWriteBom">是否写入BOM</param>
    /// <param name="ADoFormat">是否格式化Json结果</param>
    /// <remarks>注意当前结点的名称不会被写入</remarks>
    procedure SaveToStream(AStream: TStream; AEncoding: TTextEncoding = teUtf8;
      AWriteBom: Boolean = True; ADoFormat: Boolean = True);
    /// <summary>从流的当前位置开始加载JSON对象</summary>
    /// <param name="AStream">源数据流</param>
    /// <param name="AEncoding">源文件编码，如果为teUnknown，则自动判断</param>
    /// <remarks>流的当前位置到结束的长度必需大于2字节，否则无意义</remarks>
    procedure LoadFromStream(AStream: TStream;
      AEncoding: TTextEncoding = teUnknown);
    /// <summary>保存当前对象内容到文件中</summary>
    /// <param name="AFileName">文件名</param>
    /// <param name="AEncoding">编码格式</param>
    /// <param name="AWriteBOM">是否写入UTF-8的BOM</param>
    /// <param name="ADoFormat">是否格式化Json结果</param>
    /// <remarks>注意当前结点的名称不会被写入</remarks>
    procedure SaveToFile(const AFileName: String;
      AEncoding: TTextEncoding = teUtf8; AWriteBom: Boolean = True;
      ADoFormat: Boolean = True);
    /// <summary>从指定的文件中加载当前对象</summary>
    /// <param name="AFileName">要加载的文件名</param>
    /// <param name="AEncoding">源文件编码，如果为teUnknown，则自动判断</param>
    procedure LoadFromFile(const AFileName: String;
      AEncoding: TTextEncoding = teUnknown);
    /// / <summary>重置值为Null，等价于直接设置DataType为jdtNull</summary>
    procedure ResetNull;
    function Escape(const S: QStringW): QStringW;
    /// <summary>重载TObject.ToString函数</summary>
    function ToString: string; {$IFDEF UNICODE}override; {$ELSE}virtual;
{$ENDIF}
    /// <summary>获取for..in需要的GetEnumerator支持</summary>
    function GetEnumerator: TQJsonEnumerator;
    /// <summary>判断自己是否是指定对象的子对象</summmary>
    /// <param name="AParent">可能的父对象</param>
    /// <returns>如果AParent是自己的父对象，返回True，否则返回false</returns>
    function IsChildOf(AParent: TQJson): Boolean;
    /// <summary>判断自己是否是指定对象的父对象</summmary>
    /// <param name="AChild">可能的子对象</param>
    /// <returns>如果AChild是自己的子对象，返回True，否则返回false</returns>
    function IsParentOf(AChild: TQJson): Boolean;
{$IF RTLVersion>=21}
    /// <summary>使用当前Json对象参数调用指定对象的相应函数</summary>
    /// <param name="AInstance">函数所隶属的对象实例</param>
    /// <returns>返回函数调用的结果</returns>
    /// <remarks>函数名称为当前结点名称，函数的参数名称与子结点的名称要保持一致</remarks>
    function Invoke(AInstance: TValue): TValue;
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
    /// <summary>将指定索引的子结点移除</summary>
    /// <param name="AItemIndex">要移除的子结点索引</param>
    /// <returns>返回被移除的子结点，如果指定的索引不存在，返回nil</returns>
    /// <remarks>被移除的子结点需要用户自己手工释放</remarks>
    function Remove(AItemIndex: Integer): TQJson; overload; virtual;
    /// <summary>将指定的子结点移除</summary>
    /// <param name="AJson">要移除的子结点</param>
    /// <remarks>被移除的子结点需要用户自己手工释放</remarks>
    procedure Remove(AJson: TQJson); overload;
    /// <summary>从当前父结点中分离当前结点</summary>
    /// <remarks>分离后的结点需要单独释放</remarks>
    procedure Detach;
    /// <summary>将当前结点附加到新的父结点上</summary>
    /// <param name="AParent">要附加的目标结点</param>
    /// <remarks>附加后的结点由父结点负责释放</remarks>
    procedure AttachTo(ANewParent: TQJson);
    /// <summary>将当前结点移动的新的父结点的指定位置</summary>
    /// <param name="ANewParent">新的父结点</param>
    /// <param name="AIndex">新位置索引</param>
    /// <remarks>如果新位置索引小于等于0，则插入到起始位置，如果大于父的已有结点数量，则插入到
    /// 父结点末尾，否则添加到指定位置</remarks>
    procedure MoveTo(ANewParent: TQJson; AIndex: Integer);

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
    function HasChild(ANamePath: QStringW; var AChild: TQJson): Boolean; inline;
    /// <summary>获取到指定父结点的相对路径</summary>
    /// <param name="AParent">目标父结点</param>
    /// <param name="APathDelimiter">路径分隔符</param>
    /// <returns>返回相对路径</returns>
    function GetRelPath(AParent: TQJson; APathDelimiter: QCharW = '\')
      : QStringW;
    /// <summary>排序子结点</summary>
    /// <param name="AByName">是否按名称排序</param>
    /// <param name="ANest">是否排序子结点</param>
    /// <param name="AByType">子结点排序的类型依据，如果为jdtUnknown，则自动检测，否则按指定的类型排序</param>
    /// <param name="AOnCompare">排序比较方法，如果不指定，则按默认规则排序，否则根据它来排序</param>
    /// <remarks>AByType如果不为jdtUnknown，则你必需保证子结点的值能够转换为目标类型</remarks>
    procedure Sort(AByName, ANest: Boolean; AByType: TQJsonDataType;
      AOnCompare: TListSortCompareEvent); overload;
    /// <summary>排序子结点</summary>
    /// <param name="AByName">是否按名称排序</param>
    /// <param name="ANest">是否排序子结点</param>
    /// <param name="AByType">子结点排序的类型依据，如果为jdtUnknown，则自动检测，否则按指定的类型排序</param>
    /// <param name="AOnCompare">排序比较方法，如果不指定，则按默认规则排序，否则根据它来排序</param>
    /// <remarks>AByType如果不为jdtUnknown，则你必需保证子结点的值能够转换为目标类型</remarks>
    procedure Sort(AByName, ANest: Boolean; AByType: TQJsonDataType;
      AOnCompare: TListSortCompare); overload;
{$IF RTLVersion>=21}
    /// <summary>排序子结点</summary>
    /// <param name="AByName">是否按名称排序</param>
    /// <param name="ANest">是否排序子结点</param>
    /// <param name="AByType">子结点排序的类型依据，如果为jdtUnknown，则自动检测，否则按指定的类型排序</param>
    /// <param name="AOnCompare">排序比较方法，如果不指定，则按默认规则排序，否则根据它来排序</param>
    /// <remarks>AByType如果不为jdtUnknown，则你必需保证子结点的值能够转换为目标类型</remarks>
    procedure Sort(AByName, ANest: Boolean; AByType: TQJsonDataType;
      AOnCompare: TListSortCompareFunc); overload;
{$IFEND}
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
    /// <summary>合并源JSON的内容到当前JSON</summary>
    /// <param name="ASource">源JSON</param>
    /// <param name="AMethod">合并方式</param>
    /// <remarks>
    /// 不同的合并方式效果如下：
    /// jmmIgnore : 忽略源中重复的项目合并
    /// jmmAppend : 追加为重复的项目
    /// jmmAsSource : 替换为源中的内容
    /// </remarks>
    procedure Merge(ASource: TQJson; AMethod: TQJsonMergeMethod);
    /// <summary>判断JSON内容是否相同</summary>
    /// <returns>如果内容一致，则返回 true，否则返回 false</returns>
    function Equals(AJson: TQJson): Boolean; reintroduce;
    /// <summary>获取两个JSON中内容相同的部分（待优化）</summary>
    /// <param name="AJson">要参与比较的JSON对象</param>
    /// <returns>返回两个JSON的子集</returns>
    /// <remarks>返回值需要手动释放</remarks>
    function Intersect(AJson: TQJson): TQJson;
    /// <summary>获取两个JSON中内容不同的部分（待优化）</summary>
    /// <param name="AJson">要参与比较的JSON对象</param>
    /// <returns>返回两个JSON的差集</returns>
    /// <remarks>返回值需要手动释放</remarks>
    function Diff(AJson: TQJson): TQJson;
    /// <summary>重置各项的值为默认状态</summary>
    /// <param name="ADetach">是否从父结点中移除自己</param>
    procedure Reset(ADetach: Boolean); virtual;
    // 转换一个Json值为字符串
    class function BuildJsonString(ABuilder: TQStringCatHelperW; var p: PQCharW)
      : Boolean; overload;
    class function BuildJsonString(S: QStringW): QStringW; overload;
    class function BuildJsonString(ABuilder: TQStringCatHelperW; S: QStringW)
      : Boolean; overload;
    class procedure JsonCat(ABuilder: TQStringCatHelperW; const S: QStringW;
      ADoEscape: Boolean); overload;
    class function JsonCat(const S: QStringW; ADoEscape: Boolean)
      : QStringW; overload;
    class function JsonEscape(const S: QStringW; ADoEscape: Boolean)
      : QStringW; overload;
    class function JsonUnescape(const S: QStringW): QStringW;
    class function EncodeDateTime(const AValue: TDateTime): QStringW;
    /// <summary>父结点</summary>
    property Parent: TQJson read FParent;
    /// <summary>结点类型</summary>
    /// <seealso>TQJsonDataType</seealso>
    property DataType: TQJsonDataType read FDataType write SetDataType;
    /// <summary>结点名称</summary>
    property Name: QStringW read FName write SetName;
    /// <summary>子结点数量</<summary>summary>
    property Count: Integer read GetCount;
    /// <summary>子结点数组</summary>
    property Items[AIndex: Integer]: TQJson read GetItems; default;
    /// <summary>子结点的值</summary>
    property Value: QStringW read GetValue write SetValue;
    /// <summary>判断是否是布尔类型</summary>
    property IsBool: Boolean read GetIsBool;
    /// <summary>判断是否是NULL类型</summary>
    property IsNull: Boolean read GetIsNull;
    /// <summary>判断是否是数字类型</summary>
    property IsNumeric: Boolean read GetIsNumeric;
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
    /// <summary>将当前结点当作整数类型来访问</summary>
    property AsInteger: Integer read GetAsInteger write SetAsInteger;
    /// <summary>将当前结点当作64位整数类型来访问</summary>
    property AsInt64: Int64 read GetAsInt64 write SetAsInt64;
    /// <summary>将当前结点当作浮点类型来访问</summary>
    property AsFloat: Extended read GetAsFloat write SetAsFloat;
    /// <summary>将当前结点当作日期时间类型来访问</summary>
    property AsDateTime: TDateTime read GetAsDateTime write SetAsDateTime;
    /// <summary>将当前结点当作字符串类型访问</summary>
    property AsString: QStringW read GetAsString write SetAsString;
    /// <summary>将当前结点当作一个对象字符串来访问</summary>
    property AsObject: QStringW read GetAsObject write SetAsObject;
    /// <summary>将当前结点当作一个字符串数组来访问</summary>
    property AsArray: QStringW read GetAsArray write SetAsArray;
    /// <summary>将自己当做Variant类型来访问</summary>
    property AsVariant: Variant read GetAsVariant write SetAsVariant;
    /// <summary>将自己当做Json对象来访问</summary>
    property AsJson: QStringW read GetAsJson write SetAsJson;
    /// <summary>将自己当做二进制数据访问</summary>
    property AsBytes: TBytes read GetAsBytes write SetAsBytes;
    property AsHexBytes: TBytes read GetAsHexBytes write SetAsHexBytes;
    property AsBase64Bytes: TBytes read GetAsBase64Bytes write SetAsBase64Bytes;
    // <summary>额外的附加数据成员，供用户关联附加内容</summary>
    property Data: Pointer read FData write FData;
    /// <summary>结点的路径，路径中间以"\"分隔</summary>
    property Path: QStringW read GetPath;

    /// <summary>在父结点中的索引顺序，从0开始，如果是-1，则代表自己是根结点</summary>
    property ItemIndex: Integer read GetItemIndex;
    /// <summary>名称哈希值</summary>
    property NameHash: Cardinal read FNameHash;
    /// <summary>比较旱是否忽略大小写</summary>
    property IgnoreCase: Boolean read FIgnoreCase write SetIgnoreCase;
    /// <summary>根JSON结点</summary>
    property Root: TQJson read GetRoot;
    /// <summary>注释样式</summary>
    property CommentStyle: TQJsonCommentStyle read FCommentStyle
      write FCommentStyle;
    /// <summary>注释内容</summary>
    property Comment: QStringW read FComment write FComment;
    // Super Object 兼容访问模式
{$IFDEF SUPER_OBJECT_STYLE}
    property S[const APath: String]: String read GetS write SetS;
    property b[const APath: String]: Boolean read GetB write SetB;
    property F[const APath: String]: Double read GetF write SetF;
    property O[const APath: String]: TQJson read GetO write SetO;
    property A[const APath: String]: TQJson read GetA write SetA;
    property V[const APath: String]: Variant read GetV write SetV;
    property T[const APath: String]: TDateTime read GetT write SetT;
    property I[const APath: String]: Int64 read GetI write SetI;
{$ENDIF}
  end;

  TQJsonEnumerator = class
  private
    FIndex: Integer;
    FList: TQJson;
  public
    constructor Create(AList: TQJson);
    function GetCurrent: TQJson; inline;
    function MoveNext: Boolean;
    property Current: TQJson read GetCurrent;
  end;

  TQHashedJson = class(TQJson)
  protected
    FHashTable: TQHashTable;
    function CreateJson: TQJson; override;
    procedure Replace(AIndex: Integer; ANewItem: TQJson); override;
    procedure DoJsonNameChanged(AJson: TQJson); override;
    procedure DoParsed; override;
  public
    constructor Create; overload;
    destructor Destroy; override;
    procedure Assign(ANode: TQJson); override;
    function IndexOf(const AName: QStringW): Integer; override;
    function ItemByName(AName: QStringW): TQJson; overload; override;
    function Remove(AIndex: Integer): TQJson; override;
    procedure Clear; override;
  end;

  PQStreamHelperStack = ^TQStreamHelperStack;

  TQStreamHelperStack = record
    Count: Integer;
    Prior: PQStreamHelperStack;
  end;

  TQJsonStreamHelper = record
  private
    FEncoding: TTextEncoding;
    FStream: TStream;
    FDoEscape: Boolean;
    FWriteBom: Boolean;
    FLast: PQStreamHelperStack;
    FStringHelper: TQStringCatHelperW;
    procedure InternalWriteString(S: QStringW;
      ADoAppend: Boolean = True); inline;
    procedure Push;
    procedure Pop;
  public
    procedure BeginWrite(AStream: TStream; AEncoding: TTextEncoding;
      ADoEscape: Boolean = False; AWriteBom: Boolean = True);
    procedure EndWrite;
    procedure BeginObject; overload;
    procedure BeginObject(const AName: QStringW); overload;
    procedure EndObject;
    procedure BeginArray; overload;
    procedure BeginArray(const AName: QStringW); overload;
    procedure EndArray;
    procedure WriteName(const S: QStringW);
    procedure Write(const S: QStringW); overload;
    procedure Write(const I: Int64); overload;
    procedure Write(const D: Double); overload;
    procedure WriteDateTime(const V: TDateTime); overload;
    procedure Write(const c: Currency); overload;
    procedure Write(const ABytes: TBytes); overload;
    procedure Write(const p: PByte; l: Integer); overload;
    procedure WriteNull; overload;
    procedure Write(const b: Boolean); overload;
    procedure Write(const AName, AValue: QStringW); overload;
    procedure Write(const AName: QStringW; AValue: Int64); overload;
    procedure Write(const AName: QStringW; AValue: Double); overload;
    procedure Write(const AName: QStringW; AValue: TBytes); overload;
    procedure Write(const AName: QStringW; AValue: Boolean); overload;
    procedure WriteDateTime(const AName: QStringW; AValue: TDateTime); overload;
    procedure Write(const AName: QStringW; const p: PByte;
      const l: Integer); overload;
    procedure WriteNull(const AName: QStringW); overload;
    property DoEscape: Boolean read FDoEscape write FDoEscape;
  end;

  TJsonDatePrecision = (jdpMillisecond, jdpSecond);
  TJsonIntToTimeStyle = (tsDeny, tsSecondsFrom1970, tsSecondsFrom1899,
    tsMsFrom1970, tsMsFrom1899);

const
  JSON_NO_TIMEZONE = -128;

var
  /// <summary>是否启用严格检查模式，在严格模式下：
  /// 1.名称或字符串必需使用双引号包含起来,如果为False，则名称可以没有引号或使用单引号。
  /// 2.注释不受支持，如果为False，则支持//行注释和/**/的块注释
  /// </summary>
  StrictJson: Boolean;
  /// <summary>指定如何处理RTTI中的枚举和集合类型</summary>
  JsonRttiEnumAsInt: Boolean;
  /// <summary>日期类型转换为Json数据时会转换成字符串，这个变量控制如何格式化</summary>
  JsonDateFormat: QStringW;
  /// <summary>时间类型转换为Json数据时会转换成字符串，这个变量控制如何格式化</summary>
  JsonTimeFormat: QStringW;
  /// <summary>日期时间类型转换为Json数据时会转换成字符串，这个变量控制如何格式化</summary>
  JsonDateTimeFormat: QStringW;
  /// <summary>Json 日期时间类型的时区，仅在Strict模式下生效，设置为相应的时区，以便输出</summary>
  JsonTimezone: Shortint;
  /// <summary>Json 严格模式下日期类型的精度，默认为毫秒，可以设置为秒以便与某些系统兼容</summary>
  JsonDatePrecision: TJsonDatePrecision;
  JsonIntToTimeStyle: TJsonIntToTimeStyle;
  /// <summary>在ItemByName/ItemByPath/ValueByName/ValueByPath等函数的判断中，是否区分名称大小写</summary>
  JsonCaseSensitive: Boolean;
  /// 在需要新建一个TQJson对象时触发
  OnQJsonCreate: TQJsonCreateEvent;
  /// 在需要释放一个TQJson对象时触发
  OnQJsonFree: TQJsonFreeEvent;
  /// 字符串与字节流之间的转换事件
  OnQJsonEncodeBytes: TQJsonEncodeBytesEvent;
  OnQJsonDecodeBytes: TQJsonDecodeBytesEvent;
  // 字符串值的起始标记
  CharStringStart: QStringW = '"';
  // 字符串值的结束标记
  CharStringEnd: QStringW = '"';
  // JSON名称开始标记
  CharNameStart: QStringW = '"';
  // JSON名称结束标记
  CharNameEnd: QStringW = '":';
  // JSON 数组开始标记
  CharArrayStart: QStringW = '[';
  // JSON 数组结束标记
  CharArrayEnd: QStringW = ']';
  // JSON 对象开始标记
  CharObjectStart: QStringW = '{';
  // JSON 对象结束标记
  CharObjectEnd: QStringW = '}';
  // JSON NULL 值
  CharNull: QStringW = 'null';
  // JSON 假的值
  CharFalse: QStringW = 'false';
  // JSON 真的值
  CharTrue: QStringW = 'true';
  // JSON 值分隔符
  CharComma: QStringW = ',';
procedure EncodeJsonBinaryAsBase64;
procedure EncodeJsonBinaryAsHex;

implementation

uses variants, varutils, dateutils;

resourcestring
  SBadJson = '当前内容不是有效的JSON字符串。';
  SNotArrayOrObject = '%s 不是一个JSON数组或对象。';
  SVarNotArray = '%s 的类型不是数组或对象。';
  SBadConvert = '%s 不是一个有效的 %s 类型的值。';
  SCharNeeded = '当前位置应该是 "%s" ，而不是 "%s"。';
  SEndCharNeeded = '当前位置需要Json结束字符",]}"。';
  SBadNumeric = '"%s"不是有效的数值。';
  SBadJsonTime = '"%s"不是一个有效的日期时间值。';
  SBadNameStart = 'Json名称应以''"''字符开始。';
  SBadNameEnd = 'Json名称未正确结束。';
  SNameNotFound = '项目名称未找到。';
  SCommentNotSupport = '严格模式下不支持注释，要解析包括注释的JSON内容，请将StrictJson变量设置为False。';
  SUnsupportArrayItem = '添加的动态数组第%d个元素类型不受支持。';
  SBadStringStart = '严格栻上JSON字符串必需以"开始。';
  SUnknownToken = '无法识别的注释符，注释必需以//或/**/包括。';
  SNotSupport = '函数 [%s] 在当前开发环境下不受支持。';
  SBadJsonArray = '%s 不是一个有效的JSON数组定义。';
  SBadJsonObject = '%s 不是一个有效的JSON对象定义。';
  SBadJsonEncoding = '无效的编码，编码只能是UTF-8，ANSI，Unicode 16 LE，Unicode 16 BE。';
  SJsonParseError = '第%d行第%d列:%s '#13#10'%s';
  SBadJsonName = '%s 不是一个有效的JSON对象名称。';
  SObjectChildNeedName = '对象 %s 的第 %d 个子结点名称未赋值，编码输出前必需赋值。';
  SReplaceTypeNeed = '替换结点的类型要求是 %s 或其子类。';
  SSupportFloat = 'NaN/+∞/-∞不受JSON规范支持。';
  SParamMissed = '参数 %s 同名的结点未找到。';
  SMethodMissed = '指定的函数 %s 不存在。';
  SMissRttiTypeDefine =
    '无法找到 %s 的RTTI类型信息，尝试将对应的类型单独定义(如array[0..1] of Byte改为TByteArr=array[0..1]，然后用TByteArr声明)。';
  SUnsupportPropertyType = '不支持的属性类型。';
  SArrayTypeMissed = '未知的数组元素类型。';
  SUnknownError = '未知的错误。';
  SCantAttachToSelf = '不允许自己附加为自己的子结点。';
  SCanAttachToNoneContainer = '不能将结点附加到非数组和对象类型的结点下。';
  SCantAttachNoNameNodeToObject = '不能将未命名的结点做为对象类型的子结点。';
  SNodeNameExists = '指定的父结点下已经存在名为 %s 的子结点。';
  SCantMoveToChild = '不能将自己移动到自己的子结点下面';
  SConvertError = '无法将类型 %s 转换为 %s ';
  SUnsupportVarType = '不支持的变体类型 %d 。';

const
  JsonTypeName: array [TQJsonDataType] of QStringW = ('Unknown', 'Null',
    'String', 'Integer', 'Float', 'Boolean', 'DateTime', 'Array', 'Object');
  EParse_Unknown = -1;
  EParse_BadStringStart = 1;
  EParse_BadJson = 2;
  EParse_CommentNotSupport = 3;
  EParse_UnknownToken = 4;
  EParse_EndCharNeeded = 5;
  EParse_BadNameStart = 6;
  EParse_BadNameEnd = 7;
  EParse_NameNotFound = 8;

procedure DoEncodeAsBase64(const ABytes: TBytes; var AResult: QStringW);
{$IF RTLVersion<=27}
  function EncodeBase64(const V: Pointer; len: Integer): QStringW;
  var
    AIn, AOut: TMemoryStream;
    T: QStringA;
  begin
    AIn := TMemoryStream.Create;
    AOut := TMemoryStream.Create;
    try
      AIn.WriteBuffer(V^, len);
      AIn.Position := 0;
      EncodeStream(AIn, AOut);
      T.Length := AOut.Size;
      Move(AOut.Memory^, PQCharA(T)^, AOut.Size);
      Result := qstring.Utf8Decode(T);
    finally
      FreeObject(AIn);
      FreeObject(AOut);
    end;
  end;
{$ELSE}
  function EncodeBase64(const V: Pointer; len: Integer): QStringW;
  begin
    Result := TNetEncoding.Base64.EncodeBytesToString(V, len);
  end;
{$IFEND}

begin
  if Length(ABytes) > 0 then
    AResult := QStringW(EncodeBase64(@ABytes[0], Length(ABytes)))
  else
    SetLength(AResult, 0);
end;

procedure DoDecodeAsBase64(const S: QStringW; var AResult: TBytes);
{$IF RTLVersion<=27}
  function DecodeBase64(const S: QStringW): TBytes;
  var
    AIn, AOut: TMemoryStream;
    T: QStringA;
  begin
    AIn := TMemoryStream.Create;
    AOut := TMemoryStream.Create;
    try
      T := qstring.Utf8Encode(S);
      AIn.WriteBuffer(PQCharA(T)^, T.Length);
      AIn.Position := 0;
      DecodeStream(AIn, AOut);
      SetLength(Result, AOut.Size);
      Move(AOut.Memory^, Result[0], AOut.Size);
    finally
      FreeObject(AIn);
      FreeObject(AOut);
    end;
  end;
{$ELSE}
  function DecodeBase64(const S: QStringW): TBytes;
  begin
    Result := TNetEncoding.Base64.DecodeStringToBytes(S);
  end;
{$IFEND}

begin
  if Length(S) > 0 then
    AResult := DecodeBase64(S)
  else
    SetLength(AResult, 0);
end;

procedure DoDecodeAsHex(const S: QStringW; var AResult: TBytes);
begin
  AResult := HexToBin(S);
end;

procedure DoEncodeAsHex(const ABytes: TBytes; var AResult: QStringW);
begin
  AResult := BinToHex(ABytes);
end;

function TQJson.DoCompareName(Item1, Item2: Pointer): Integer;
var
  AIgnoreCase: Boolean;
  AItem1, AItem2: TQJson;
begin
  AItem1 := Item1;
  AItem2 := Item2;
  AIgnoreCase := AItem1.IgnoreCase;
  if AIgnoreCase <> AItem2.IgnoreCase then
    AIgnoreCase := False;
  Result := StrCmpW(PWideChar(AItem1.Name), PWideChar(AItem2.Name),
    AIgnoreCase);
end;

function TQJson.DoCompareValueBoolean(Item1, Item2: Pointer): Integer;
var
  AItem1, AItem2: TQJson;
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

function TQJson.DoCompareValueDateTime(Item1, Item2: Pointer): Integer;
var
  AItem1, AItem2: TQJson;
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

function TQJson.DoCompareValueFloat(Item1, Item2: Pointer): Integer;
var
  AItem1, AItem2: TQJson;
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

function TQJson.DoCompareValueInt(Item1, Item2: Pointer): Integer;
var
  AItem1, AItem2: TQJson;
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

function TQJson.DoCompareValueString(Item1, Item2: Pointer): Integer;
var
  AIgnoreCase: Boolean;
  AItem1, AItem2: TQJson;
begin
  AItem1 := Item1;
  AItem2 := Item2;
  AIgnoreCase := AItem1.IgnoreCase;
  if AIgnoreCase <> AItem2.IgnoreCase then
    AIgnoreCase := False;
  Result := StrCmpW(PWideChar(AItem1.AsString), PWideChar(AItem2.AsString),
    AIgnoreCase);
end;
{ TQJson }

function TQJson.Add(AName: QStringW; AValue: Int64): TQJson;
begin
  Result := Add(AName, jdtInteger);
  PInt64(PQCharW(Result.FValue))^ := AValue;
end;

function TQJson.Add(AName: QStringW; AValue: Extended): TQJson;
begin
  Result := Add(AName, jdtFloat);
  PExtended(PQCharW(Result.FValue))^ := AValue;
end;

function TQJson.Add(AName: QStringW; AValue: Boolean): TQJson;
begin
  Result := Add(AName, jdtBoolean);
  PBoolean(PQCharW(Result.FValue))^ := AValue;
end;

function TQJson.Add(AName: QStringW): TQJson;
begin
  Result := Add;
  Result.FName := AName;
  DoJsonNameChanged(Result);
end;

function TQJson.Add(AName: QStringW; AChild: TQJson): Integer;
begin
  AChild.FName := AName;
  Result := Add(AChild);
  DoJsonNameChanged(AChild);
end;

function TQJson.AddArray(AName: QStringW): TQJson;
begin
  Result := Add(AName, jdtArray);
end;

function TQJson.AddDateTime(AName: QStringW; AValue: TDateTime): TQJson;
begin
  Result := Add(AName);
  Result.DataType := jdtString;
  Result.AsDateTime := AValue;
end;

function TQJson.AddVariant(AName: QStringW; AValue: Variant): TQJson;
begin
  Result := Add(AName);
  Result.AsVariant := AValue;
end;

function TQJson.Add: TQJson;
begin
  Result := CreateJson;
  Add(Result);
end;

function TQJson.Add(ANode: TQJson): Integer;
begin
  if Assigned(ANode.Parent) then
  begin
    if ANode.Parent <> Self then
      ANode.Parent.Remove(ANode)
    else
    begin
      Result := ANode.ItemIndex;
      Exit;
    end;
  end;
  ArrayNeeded(jdtObject);
  Result := FItems.Add(ANode);
  ANode.FParent := Self;
  ANode.FIgnoreCase := FIgnoreCase;
end;

function TQJson.Add(AName, AValue: QStringW; ADataType: TQJsonDataType)
  : Integer;
var
  ANode: TQJson;
begin
  ANode := CreateJson;
  ANode.FName := AName;
  Result := Add(ANode);
  DoJsonNameChanged(ANode);
  ANode.FromType(AValue, ADataType);
end;

function TQJson.Add(AName: QStringW; ADataType: TQJsonDataType): TQJson;
begin
  Result := Add(AName);
  Result.DataType := ADataType;
end;

function TQJson.Add(const AName: QStringW; AItems: array of const): TQJson;
var
  I: Integer;
begin
  Result := Add(AName);
  Result.DataType := jdtArray;
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
          if TObject(AItems[I].VObject) is TQJson then
            Result.Add(TObject(AItems[I].VObject) as TQJson)
          else
            raise Exception.Create(Format(SUnsupportArrayItem, [I]));
        end
    else
      raise Exception.Create(Format(SUnsupportArrayItem, [I]));
    end; // End case
  end; // End for
end;

function TQJson.ArrayItemType(ArrType: PTypeInfo): PTypeInfo;
var
  ATypeData: PTypeData;
begin
  Result := nil;
  if (ArrType <> nil) and (ArrType.Kind in [tkArray, tkDynArray]) then
  begin
    ATypeData := GetTypeData(ArrType);
    if (ATypeData <> nil) then
      Result := ATypeData.elType2^;
    if Result = nil then
    begin
      if ATypeData.BaseType^ = TypeInfo(Byte) then
        Result := TypeInfo(Byte);
    end;
  end;
end;

function TQJson.ArrayItemTypeName(ATypeName: QStringW): QStringW;
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

procedure TQJson.ArrayNeeded(ANewType: TQJsonDataType);
begin
  if not(DataType in [jdtArray, jdtObject]) then
  begin
    FDataType := ANewType;
    ValidArray;
  end;
end;

procedure TQJson.Assign(ANode: TQJson);
var
  I: Integer;
  AItem, ACopy: TQJson;
begin
  if ANode.FDataType in [jdtArray, jdtObject] then
  begin
    DataType := ANode.FDataType;
    Clear;
    for I := 0 to ANode.Count - 1 do
    begin
      AItem := ANode[I];
      if Length(AItem.FName) > 0 then
      begin
        ACopy := Add(AItem.FName);
        ACopy.FNameHash := AItem.FNameHash;
      end
      else
        ACopy := Add;
      ACopy.Assign(AItem);
    end;
  end
  else
    CopyValue(ANode);
end;

procedure TQJson.AttachTo(ANewParent: TQJson);
begin
  MoveTo(ANewParent, MaxInt);
end;

function TQJson.BoolByName(AName: QStringW; ADefVal: Boolean): Boolean;
var
  AChild: TQJson;
begin
  AChild := ItemByName(AName);
  if Assigned(AChild) then
  begin
    if not AChild.TryGetAsBoolean(Result) then
      Result := ADefVal;
  end
  else
    Result := ADefVal;
end;

function TQJson.BoolByPath(APath: QStringW; ADefVal: Boolean): Boolean;
var
  AItem: TQJson;
begin
  AItem := ItemByPath(APath);
  if Assigned(AItem) then
  begin
    if not AItem.TryGetAsBoolean(Result) then
      Result := ADefVal;
  end
  else
    Result := ADefVal;
end;

function TQJson.BooleanToStr(const b: Boolean): QStringW;
begin
  if b then
    Result := CharTrue
  else
    Result := CharFalse;
end;

class function TQJson.BuildJsonString(ABuilder: TQStringCatHelperW;
  S: QStringW): Boolean;
var
  p: PQCharW;
begin
  p := PQCharW(S);
  Result := BuildJsonString(ABuilder, p);
end;

class function TQJson.BuildJsonString(S: QStringW): QStringW;
var
  AHelper: TQStringCatHelperW;
  p: PQCharW;
begin
  AHelper := TQStringCatHelperW.Create;
  try
    p := PQCharW(S);
    BuildJsonString(AHelper, p);
    Result := AHelper.Value;
  finally
    FreeAndNil(AHelper);
  end;
end;

class function TQJson.BuildJsonString(ABuilder: TQStringCatHelperW;
  var p: PQCharW): Boolean;
var
  AQuoter: QCharW;
  ps: PQCharW;
begin
  ABuilder.Position := 0;
  if (p^ = '"') or (p^ = '''') then
  begin
    AQuoter := p^;
    Inc(p);
    ps := p;
    Result := False;
    while p^ <> #0 do
    begin
      if (p^ = AQuoter) then
      begin
        if ps <> p then
          ABuilder.Cat(ps, p - ps);
        if p[1] = AQuoter then
        begin
          ABuilder.Cat(AQuoter);
          Inc(p, 2);
          ps := p;
        end
        else
        begin
          Inc(p);
          SkipSpaceW(p);
          ps := p;
          Result := True;
          Break;
        end;
      end
      else if p^ = '\' then
      begin
        if ps <> p then
          ABuilder.Cat(ps, p - ps);
        ABuilder.Cat(CharUnescape(p));
        ps := p;
      end
      else
        Inc(p);
    end;
    if Result then
    begin
      if (ps <> p) then
        ABuilder.Cat(ps, p - ps)
    end
    else
    begin
      ABuilder.Cat(ps, p - ps);
    end;
  end
  else
  begin
    Result := True;
    while p^ <> #0 do
    begin
      if (p^ = ':') or (p^ = ']') or (p^ = ',') or (p^ = '}') then
        Break
      else
        ABuilder.Cat(p, 1);
      Inc(p);
    end
  end;
end;

function TQJson.BytesByPath(APath: QStringW; ADefVal: TBytes): TBytes;
var
  AItem: TQJson;
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

class procedure TQJson.JsonCat(ABuilder: TQStringCatHelperW; const S: QStringW;
  ADoEscape: Boolean);
var
  ps, p, pd: PQCharW;
  ADelta: Integer;
const
  CharNum1: PWideChar = '1';
  CharNum0: PWideChar = '0';
  Char7: PWideChar = '\a';
  Char8: PWideChar = '\b';
  Char9: PWideChar = '\t';
  Char10: PWideChar = '\n';
  Char11: PWideChar = '\v';
  Char12: PWideChar = '\f';
  Char13: PWideChar = '\r';
  CharQuoter: PWideChar = '\"';
  CharBackslash: PWideChar = '\\';
  CharCode: PWideChar = '\u00';
  CharEscape: PWideChar = '\u';
begin
  ABuilder.IncSize(Length(S)); // 增加缓冲区大小
  ps := PQCharW(S);
  p := ps;
  pd := ABuilder.Current;
  while (p^ <> #0) do
  begin
    if IntPtr(ABuilder.Last) - IntPtr(pd) < 12 then // 最糟糕的情况是 \uxxxx
    begin
      ABuilder.Current := pd;
      ADelta := Length(S) - ((IntPtr(p) - IntPtr(ps)) shr 1);
      // 如果是剩下一个需转义字符，且ADoEscape为true，则至少需要6个字符的位置
      if ADoEscape and (ADelta < 6) then
        ADelta := 6;
      ABuilder.IncSize(ADelta);
      pd := ABuilder.Current;
      ps := p;
    end;
    case p^ of
      #7:
        begin
          PInteger(pd)^ := PInteger(Char7)^;
          Inc(pd, 2);
        end;
      #8:
        begin
          PInteger(pd)^ := PInteger(Char8)^;
          Inc(pd, 2);
        end;
      #9:
        begin
          PInteger(pd)^ := PInteger(Char9)^;
          Inc(pd, 2);
        end;
      #10:
        begin
          PInteger(pd)^ := PInteger(Char10)^;
          Inc(pd, 2);
        end;
      #11:
        begin
          PInteger(pd)^ := PInteger(Char11)^;
          Inc(pd, 2);
        end;
      #12:
        begin
          PInteger(pd)^ := PInteger(Char12)^;
          Inc(pd, 2);
        end;
      #13:
        begin
          PInteger(pd)^ := PInteger(Char13)^;
          Inc(pd, 2);
        end;
      '\':
        begin
          PInteger(pd)^ := PInteger(CharBackslash)^;
          Inc(pd, 2);
        end;
      '"':
        begin
          PInteger(pd)^ := PInteger(CharQuoter)^;
          Inc(pd, 2);
        end
    else
      begin
        if p^ < #$1F then
        begin
          PInt64(pd)^ := PInt64(CharCode)^;
          Inc(pd, 4);
          if p^ > #$F then
            pd^ := CharNum1^
          else
            pd^ := CharNum0^;
          Inc(pd);
          pd^ := LowerHexChars[Ord(p^) and $0F];
          Inc(pd);
        end
        else if (p^ <= #$7E) or (not ADoEscape) then // 英文字符区
        begin
          pd^ := p^;
          Inc(pd);
        end
        else
        begin
          PInteger(pd)^ := PInteger(CharEscape)^;
          Inc(pd, 2);
          pd^ := LowerHexChars[(PWord(p)^ shr 12) and $0F];
          Inc(pd);
          pd^ := LowerHexChars[(PWord(p)^ shr 8) and $0F];
          Inc(pd);
          pd^ := LowerHexChars[(PWord(p)^ shr 4) and $0F];
          Inc(pd);
          pd^ := LowerHexChars[PWord(p)^ and $0F];
          Inc(pd);
        end;
      end;
    end;
    Inc(p);
  end;
  ABuilder.Current := pd;
end;

class function TQJson.CharEscape(c: QCharW; pd: PQCharW): Integer;
begin
  case c of
    #7:
      begin
        pd[0] := '\';
        pd[1] := 'b';
        Result := 2;
      end;
    #9:
      begin
        pd[0] := '\';
        pd[1] := 't';
        Result := 2;
      end;
    #10:
      begin
        pd[0] := '\';
        pd[1] := 'n';
        Result := 2;
      end;
    #12:
      begin
        pd[0] := '\';
        pd[1] := 'f';
        Result := 2;
      end;
    #13:
      begin
        pd[0] := '\';
        pd[1] := 'r';
        Result := 2;
      end;
    '\':
      begin
        pd[0] := '\';
        pd[1] := '\';
        Result := 2;
      end;
    '''':
      begin
        pd[0] := '\';
        pd[1] := '''';
        Result := 2;
      end;
    '"':
      begin
        pd[0] := '\';
        pd[1] := '"';
        Result := 2;
      end
  else
    begin
      pd[0] := c;
      Result := 1;
    end;
  end;
end;

class function TQJson.CharUnescape(var p: PQCharW): QCharW;
  function DecodeOrd: Integer;
  var
    c: Integer;
  begin
    Result := 0;
    c := 0;
    while (p^ <> #0) and (c < 4) do
    begin
      if IsHexChar(p^) then
        Result := (Result shl 4) + HexValue(p^)
      else
        Break;
      Inc(p);
      Inc(c);
    end
  end;

begin
  if p^ = #0 then
  begin
    Result := #0;
    Exit;
  end;
  if p^ <> '\' then
  begin
    Result := p^;
    Inc(p);
    Exit;
  end;
  Inc(p);
  case p^ of
    'a':
      begin
        Result := #7;
        Inc(p);
      end;
    'b':
      begin
        Result := #8;
        Inc(p);
      end;
    't':
      begin
        Result := #9;
        Inc(p);
      end;
    'n':
      begin
        Result := #10;
        Inc(p);
      end;
    'v':
      begin
        Result := #11;
        Inc(p);
      end;
    'f':
      begin
        Result := #12;
        Inc(p);
      end;
    'r':
      begin
        Result := #13;
        Inc(p);
      end;
    '\':
      begin
        Result := '\';
        Inc(p);
      end;
    '''':
      begin
        Result := '''';
        Inc(p);
      end;
    '"':
      begin
        Result := '"';
        Inc(p);
      end;
    'u':
      begin
        // \uXXXX
        if IsHexChar(p[1]) and IsHexChar(p[2]) and IsHexChar(p[3]) and
          IsHexChar(p[4]) then
        begin
          Result := WideChar((HexValue(p[1]) shl 12) or (HexValue(p[2]) shl 8)
            or (HexValue(p[3]) shl 4) or HexValue(p[4]));
          Inc(p, 5);
        end
        else
          raise Exception.CreateFmt(SCharNeeded,
            ['0-9A-Fa-f', StrDupW(p, 0, 4)]);
      end
  else
    begin
      if StrictJson then
        raise Exception.CreateFmt(SCharNeeded, ['btfrn"u''/', StrDupW(p, 0, 4)])
      else
      begin
        Result := p^;
        Inc(p);
      end;
    end;
  end;
end;

procedure TQJson.Clear;
var
  I: Integer;
begin
  if FDataType in [jdtArray, jdtObject] then
  begin
    for I := 0 to Count - 1 do
      FreeJson(FItems[I]);
    FItems.Clear;
  end;
end;

function TQJson.Clone: TQJson;
begin
  Result := Copy;
end;

function TQJson.ContainsName(AName: QStringW; ANest: Boolean): Boolean;
var
  I, H: Integer;
  AItem: TQJson;
begin
  Result := ItemByName(AName) <> nil;
  if (not Result) and ANest then
  begin
    H := Count - 1;
    for I := 0 to H do
    begin
      AItem := Items[I];
      if AItem.DataType = jdtObject then
      begin
        Result := Items[I].ContainsName(AName, ANest);
        if Result then
          Break;
      end;
    end;
  end;
end;

function TQJson.ContainsValue(const AValue: Variant;
  ANest, AStrict: Boolean): Boolean;
var
  I, H: Integer;
  AItem: TQJson;
  function CompareValue: Boolean;
  begin
    if AItem.DataType in [jdtUnknown, jdtNull] then
      Result := VarIsNull(AValue)
    else if AStrict then
    begin
      if AItem.DataType = jdtString then
        Result := StrCmpW(PWideChar(AItem.AsString),
          PWideChar({$IFNDEF UNICODE}QStringW({$ENDIF}VarToStr
          (AValue){$IFNDEF UNICODE}){$ENDIF}), IgnoreCase) = 0
      else if (AItem.DataType in [jdtInteger, jdtFloat, jdtBoolean]) and
        VarIsNumeric(AValue) then
        Result := (AItem.AsVariant = AValue)
      else if (AItem.DataType = jdtDateTime) and
        (FindVarData(AValue)^.VType = varDate) then
        Result := SameValue(AItem.AsDateTime, VarToDateTime(AValue))
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
    if (not(AItem.DataType in [jdtObject, jdtArray])) and CompareValue then
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
      if AItem.DataType in [jdtObject, jdtArray] then
      begin
        Result := AItem.ContainsValue(AValue, ANest, AStrict);
        if Result then
          Exit;
      end;
    end;
  end;
end;

function TQJson.Copy: TQJson;
begin
  Result := CreateJson;
  Result.Assign(Self);
end;
{$IF RTLVersion>=21}

function TQJson.CopyIf(const ATag: Pointer;
  AFilter: TQJsonFilterEventA): TQJson;
  procedure NestCopy(AParentSource, AParentDest: TQJson);
  var
    I: Integer;
    Accept: Boolean;
    AChildSource, AChildDest: TQJson;
  begin
    for I := 0 to AParentSource.Count - 1 do
    begin
      Accept := True;
      AChildSource := AParentSource[I];
      AFilter(Self, AChildSource, Accept, ATag);
      if Accept then
      begin
        AChildDest := AParentDest.Add(AChildSource.FName,
          AChildSource.DataType);
        if AChildSource.DataType in [jdtArray, jdtObject] then
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
    Result := CreateJson;
    Result.FName := Name;
    if DataType in [jdtObject, jdtArray] then
    begin
      NestCopy(Self, Result);
    end
    else
      Result.CopyValue(Self);
  end
  else
    Result := Copy;
end;
{$IFEND >=2010}

function TQJson.CopyIf(const ATag: Pointer; AFilter: TQJsonFilterEvent): TQJson;
  procedure NestCopy(AParentSource, AParentDest: TQJson);
  var
    I: Integer;
    Accept: Boolean;
    AChildSource, AChildDest: TQJson;
  begin
    for I := 0 to AParentSource.Count - 1 do
    begin
      Accept := True;
      AChildSource := AParentSource[I];
      AFilter(Self, AChildSource, Accept, ATag);
      if Accept then
      begin
        AChildDest := AParentDest.Add(AChildSource.FName,
          AChildSource.DataType);
        if AChildSource.DataType in [jdtArray, jdtObject] then
          NestCopy(AChildSource, AChildDest)
        else
          AChildDest.CopyValue(AChildSource);
      end;
    end;
  end;

begin
  if Assigned(AFilter) then
  begin
    Result := CreateJson;
    Result.FName := Name;
    if DataType in [jdtObject, jdtArray] then
    begin
      NestCopy(Self, Result);
    end
    else
      Result.CopyValue(Self);
  end
  else
    Result := Copy;
end;

procedure TQJson.CopyValue(ASource: TQJson);
var
  l: Integer;
begin
  l := Length(ASource.FValue);
  DataType := ASource.DataType;
  SetLength(FValue, l);
  if l > 0 then
    Move(PQCharW(ASource.FValue)^, PQCharW(FValue)^, l shl 1);
end;

constructor TQJson.Create(const AName, AValue: QStringW;
  ADataType: TQJsonDataType);
begin
  inherited Create;
  FName := AName;
  FIgnoreCase := not JsonCaseSensitive;
  if ADataType <> jdtUnknown then
    DataType := ADataType;
  Value := AValue;
  // DebugOut('Create Json Object %x', [IntPtr(Self)]);
end;

function TQJson.CreateJson: TQJson;
begin
  if Assigned(OnQJsonCreate) then
    Result := OnQJsonCreate
  else
    Result := TQJson.Create;
end;

constructor TQJson.Create;
begin
  inherited;
  FCommentStyle := jcsInherited;
  FIgnoreCase := not JsonCaseSensitive;
  // DebugOut('Create Json Object %x', [IntPtr(Self)]);
end;

function TQJson.DateTimeByName(AName: QStringW; ADefVal: TDateTime): TDateTime;
var
  AChild: TQJson;
begin
  AChild := ItemByName(AName);
  if Assigned(AChild) then
  begin
    if not AChild.TryGetAsDateTime(Result) then
      Result := ADefVal;
  end
  else
    Result := ADefVal;
end;

function TQJson.DateTimeByPath(APath: QStringW; ADefVal: TDateTime): TDateTime;
var
  AItem: TQJson;
begin
  AItem := ItemByPath(APath);
  if Assigned(AItem) then
  begin
    if not AItem.TryGetAsDateTime(Result) then
      Result := ADefVal;
  end
  else
    Result := ADefVal;
end;

procedure TQJson.Delete(AName: QStringW);
var
  I: Integer;
begin
  I := IndexOf(AName);
  if I <> -1 then
    Delete(I);
end;
{$IF RTLVersion>=21}

procedure TQJson.DeleteIf(const ATag: Pointer; ANest: Boolean;
  AFilter: TQJsonFilterEventA);
  procedure DeleteChildren(AParent: TQJson);
  var
    I: Integer;
    Accept: Boolean;
    AChild: TQJson;
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

procedure TQJson.DeleteIf(const ATag: Pointer; ANest: Boolean;
  AFilter: TQJsonFilterEvent);
  procedure DeleteChildren(AParent: TQJson);
  var
    I: Integer;
    Accept: Boolean;
    AChild: TQJson;
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

procedure TQJson.Delete(AIndex: Integer);
var
  AJson: TQJson;
begin
  AJson := Remove(AIndex);
  if Assigned(AJson) then
    FreeJson(AJson);
end;

destructor TQJson.Destroy;
begin
  // DebugOut('Free Json object %s %s', [IntToHex(IntPtr(Self), 8), Path]);
  ResetNull;
  inherited;
end;

procedure TQJson.Detach;
begin
  if Assigned(FParent) then
    FParent.Remove(Self);
end;

function TQJson.Diff(AJson: TQJson): TQJson;
  procedure DoDiff(ALeft, ARight, AParent: TQJson);
  var
    I, H1, H2, J: Integer;
    AItem1, AItem2, AResult: TQJson;
    AFound: Boolean;
  begin
    if DataType <> AJson.DataType then
      AParent.Add(ALeft.Name, ALeft)
    else
    begin
      H1 := ALeft.Count - 1;
      H2 := ARight.Count - 1;
      for I := 0 to H1 do
      begin
        AItem1 := ALeft[I];
        AFound := False;
        for J := 0 to H2 do
        begin
          AItem2 := ARight[J];
          if (AItem1.Name = AItem2.Name) then
          begin
            AFound := True;
            if not AItem1.Equals(AItem2) then
            begin
              AResult := AParent.Add(AItem1.Name, jdtObject);
              AResult.Add('Value1', AItem1.DataType).Assign(AItem1);
              AResult.Add('Value2', AItem2.DataType).Assign(AItem2);
            end;
            Break;
          end;
        end;
        if not AFound then
          AParent.Add(AItem1.Name).Assign(AItem1);
      end;
    end;
  end;

begin
  Result := TQJson.Create;
  DoDiff(Self, AJson, Result);
  DoDiff(AJson, Self, Result);
end;

procedure TQJson.DoJsonNameChanged(AJson: TQJson);
begin

end;

procedure TQJson.DoParsed;
begin

end;

function TQJson.Encode(ADoFormat: Boolean; ADoEscape: Boolean;
  AIndent: QStringW): QStringW;
var
  ASettings: TJsonEncodeSettings;
begin
  ASettings := [];
  if ADoFormat then
    ASettings := ASettings + [jesDoFormat];
  if ADoEscape then
    ASettings := ASettings + [jesDoEscape];
  Result := Encode(ASettings, AIndent);
end;

function TQJson.Encode(ASettings: TJsonEncodeSettings; AIndent: QStringW)
  : QStringW;
var
  ABuilder: TQStringCatHelperW;
begin
  ABuilder := TQStringCatHelperW.Create;
  try
    InternalEncode(ABuilder, ASettings, AIndent);
    ABuilder.Back(1); // 删除最后一个逗号
    Result := ABuilder.Value;
  finally
    FreeObject(ABuilder);
  end;
end;

class function TQJson.EncodeDateTime(const AValue: TDateTime): QStringW;
var
  ADate: Integer;
begin
  ADate := Trunc(AValue);
  if SameValue(ADate, 0) then // Date为0，是时间
  begin
    if SameValue(AValue, 0) then
      Result := FormatDateTime(JsonDateFormat, AValue)
    else
      Result := FormatDateTime(JsonTimeFormat, AValue);
  end
  else
  begin
    if SameValue(AValue - ADate, 0) then
      Result := FormatDateTime(JsonDateFormat, AValue)
    else
      Result := FormatDateTime(JsonDateTimeFormat, AValue);
  end;
end;

function TQJson.Equals(AJson: TQJson): Boolean;
var
  I, c: Integer;
begin
  if DataType = AJson.DataType then
  begin
    if DataType in [jdtArray, jdtObject] then
    begin
      Result := Count = AJson.Count;
      if Result then
      begin
        c := Count - 1;
        for I := 0 to c do
        begin
          Result := Items[I].Equals(AJson[I]);
          if not Result then
            Break;
        end;
      end;
    end
    else
      Result := FValue = AJson.FValue;
  end
  else
    Result := False;
end;

function TQJson.Escape(const S: QStringW): QStringW;
var
  ABuilder: TQStringCatHelperW;
begin
  ABuilder := TQStringCatHelperW.Create;
  try
    JsonCat(ABuilder, S, True);
    Result := ABuilder.Value;
  finally
    FreeObject(ABuilder);
  end;
end;

procedure TQJson.ExchangeOrder(AIndex1, AIndex2: Integer);
begin
  FItems.Exchange(AIndex1, AIndex2);
end;

{$IF RTLVersion>=21}

function TQJson.FindIf(const ATag: Pointer; ANest: Boolean;
  AFilter: TQJsonFilterEventA): TQJson;
  function DoFind(AParent: TQJson): TQJson;
  var
    I: Integer;
    AChild: TQJson;
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

procedure TQJson.FileFromValue(AFileName: QStringW);
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

function TQJson.FindIf(const ATag: Pointer; ANest: Boolean;
  AFilter: TQJsonFilterEvent): TQJson;
  function DoFind(AParent: TQJson): TQJson;
  var
    I: Integer;
    AChild: TQJson;
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

function TQJson.FloatByName(AName: QStringW; ADefVal: Extended): Extended;
var
  AChild: TQJson;
begin
  AChild := ItemByName(AName);
  if Assigned(AChild) then
  begin
    if not AChild.TryGetAsFloat(Result) then
      Result := ADefVal;
  end
  else
    Result := ADefVal;
end;

function TQJson.FloatByPath(APath: QStringW; ADefVal: Extended): Extended;
var
  AItem: TQJson;
begin
  AItem := ItemByPath(APath);
  if Assigned(AItem) then
  begin
    if not AItem.TryGetAsFloat(Result) then
      Result := ADefVal;
  end
  else
    Result := ADefVal;
end;

function TQJson.ForceName(AName: QStringW; AType: TQJsonDataType): TQJson;
var
  I: Integer;
begin
  I := IndexOf(AName);
  if I <> -1 then
    Result := Items[I]
  else
    Result := Add(AName, AType);
end;

function TQJson.ForcePath(APath: QStringW): TQJson;
var
  AName: QStringW;
  p, pn, ws: PQCharW;
  AParent: TQJson;
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
    if not(AParent.DataType in [jdtObject, jdtArray]) then
      AParent.DataType := jdtObject;
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
        until l < 0;
        if l >= 0 then
        begin
          AName := StrDupX(pn, l);
          if Length(AName) > 0 then
          begin
            Result := AParent.ItemByName(AName);
            if EndWithW(AName, ']', False) then
            begin
              Result := AParent.ForcePath(AName);
              Result.DataType := jdtArray;
            end
            else if Result = nil then
              Result := AParent.Add(AName, jdtArray)
            else if Result.DataType <> jdtArray then
              raise Exception.CreateFmt(SBadJsonArray, [AName]);
          end
          else // Self
            Result := AParent;
          if AIndex >= 0 then
          begin
            while Result.Count <= AIndex do
              Result.Add;
            Result := Result[AIndex];
          end;
        end
        else
          raise Exception.CreateFmt(SBadJsonName, [AName]);
      end
      else
      begin
        if AParent.IsArray then
          Result := AParent.Add.Add(AName)
        else
          Result := AParent.Add(AName);
      end;
    end;
    AParent := Result;
  end;
end;

procedure TQJson.ForEach(ACallback: TQJsonFilterEvent; ANest: Boolean;
  const ATag: Pointer);
var
  AContinue: Boolean;
  procedure DoEnum(AParent: TQJson);
  var
    I: Integer;
    AChild: TQJson;
  begin
    I := 0;
    while (I < AParent.Count) and AContinue do
    begin
      AChild := AParent[I];
      ACallback(Self, AChild, AContinue, ATag);
      if AContinue and ANest then
        DoEnum(AChild);
      Inc(I);
    end;
  end;

begin
  if Assigned(ACallback) then
  begin
    AContinue := True;
    DoEnum(Self);
  end;
end;
{$IF RTLVersion>=21}

procedure TQJson.ForEach(ACallback: TQJsonFilterEventA; ANest: Boolean;
  const ATag: Pointer);
var
  AContinue: Boolean;
  procedure DoEnum(AParent: TQJson);
  var
    I: Integer;
    AChild: TQJson;
  begin
    I := 0;
    while (I < AParent.Count) and AContinue do
    begin
      AChild := AParent[I];
      ACallback(Self, AChild, AContinue, ATag);
      if AContinue and ANest then
        DoEnum(AChild);
      Inc(I);
    end;
  end;

begin
  if Assigned(ACallback) then
  begin
    AContinue := True;
    DoEnum(Self);
  end;
end;
{$IFEND}

function TQJson.FormatParseError(ACode: Integer; AMsg: QStringW; ps, p: PQCharW)
  : QStringW;
var
  ACol, ARow: Integer;
  ALine: QStringW;
  pLine: PQCharW;
  procedure ErrorLine;
  var
    pl, pls, pe: PQCharW;
  begin
    pl := PQCharW(ALine);
    pls := pl;
    Inc(pl, ACol);
    pe := pls + Length(ALine);
    if IntPtr(pe) - IntPtr(pl) > 50 then
    begin
      pls := pl - 25;
      pe := pl + 25;
    end
    else if Length(ALine) >= 50 then
      pls := pe - 50;
    ALine := StrDupX(pls, pe - pls) + SLineBreak + StringReplicateW('0',
      (IntPtr(pl) - IntPtr(pls)) shr 1 - 1) + '^';
  end;

begin
  if ACode <> 0 then
  begin
    pLine := StrPosW(ps, p, ACol, ARow);
    ALine := DecodeLineW(pLine, False);
    if Length(ALine) > 1024 then // 一行最长允许1024个字符
    begin
      ErrorLine;
    end;
    Result := Format(SJsonParseError, [ARow, ACol, AMsg, ALine]);
  end
  else
    SetLength(Result, 0);
end;

function TQJson.FormatParseErrorEx(ACode: Integer; AMsg: QStringW;
  ps, p: PQCharW): EJsonError;
var
  ACol, ARow: Integer;
  ALine: QStringW;
  pLine: PQCharW;
  procedure ErrorLine;
  var
    pl, pls, pe: PQCharW;
  begin
    pl := PQCharW(ALine);
    pls := pl;
    Inc(pl, ACol);
    pe := pls + Length(ALine);
    if IntPtr(pe) - IntPtr(pl) > 50 then
    begin
      pls := pl - 25;
      pe := pl + 25;
    end
    else if Length(ALine) >= 50 then
      pls := pe - 50;
    ALine := StrDupX(pls, pe - pls) + SLineBreak + StringReplicateW('0',
      (IntPtr(pl) - IntPtr(pls)) shr 1 - 1) + '^';
  end;

begin
  if ACode <> 0 then
  begin
    pLine := StrPosW(ps, p, ACol, ARow);
    ALine := DecodeLineW(pLine, False);
    if Length(ALine) > 1024 then // 一行最长允许1024个字符
    begin
      ErrorLine;
    end;
    Result := EJsonError.Create(Format(SJsonParseError,
      [ARow, ACol, AMsg, ALine]));
    Result.FRow := ARow;
    Result.FCol := ACol;
  end
  else
    Result := nil;
end;

procedure TQJson.FreeJson(AJson: TQJson);
begin
  if Assigned(OnQJsonFree) then
  begin
    AJson.FParent := nil;
    OnQJsonFree(AJson);
  end
  else
    FreeObject(AJson);
end;

procedure TQJson.FromType(const AValue: String; AType: TQJsonDataType);
var
  p: PQCharW;
  ABuilder: TQStringCatHelperW;
  procedure ToDateTime;
  var
    ATime: TDateTime;
  begin
    if ParseDateTime(PQCharW(AValue), ATime) then
      AsDateTime := ATime
    else if ParseJsonTime(PQCharW(AValue), ATime) then
      AsDateTime := ATime
    else
      raise Exception.Create(SBadJsonTime);
  end;

begin
  p := PQCharW(AValue);
  if AType = jdtUnknown then
  begin
    ABuilder := TQStringCatHelperW.Create;
    try
      if TryParseValue(ABuilder, p) <> 0 then
        AsString := AValue
      else if p^ <> #0 then
        AsString := AValue;
    finally
      FreeObject(ABuilder);
    end;
  end
  else
  begin
    case AType of
      jdtString:
        AsString := AValue;
      jdtInteger:
        AsInteger := StrToInt(AValue);
      jdtFloat:
        AsFloat := StrToFloat(AValue);
      jdtBoolean:
        AsBoolean := StrToBool(AValue);
      jdtDateTime:
        ToDateTime;
      jdtArray:
        begin
          if p^ <> '[' then
            raise Exception.CreateFmt(SBadJsonArray, [AValue]);
          ParseObject(p);
        end;
      jdtObject:
        begin
          if p^ <> '{' then
            raise Exception.CreateFmt(SBadJsonObject, [AValue]);
          ParseObject(p);
        end;
    end;
  end;
end;

{$IF RTLVersion>=21}

procedure TQJson.FromRecord<T>(const ARecord: T);
begin
  FromRtti(@ARecord, TypeInfo(T));
end;

procedure TQJson.FromRtti(ASource: Pointer; AType: PTypeInfo);
var
  AValue: TValue;
  procedure AddCollection(AParent: TQJson; ACollection: TCollection);
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
    J, K: Integer;
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
              else if JsonRttiEnumAsInt then
                Add(AFields[J].Name).AsInteger := AFields[J].GetValue(ASource)
                  .AsOrdinal
              else
                Add(AFields[J].Name).AsString :=
                  AFields[J].GetValue(ASource).ToString;
            end;
          tkSet:
            begin
              if JsonRttiEnumAsInt then
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
              begin
                // 判断一个数值是否是一个有效的值

                Add(AFields[J].Name).AsDateTime := AFields[J].GetValue(ASource)
                  .AsExtended
              end
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
              with Add(AFields[J].Name, jdtArray) do
              begin
                AValue := AFields[J].GetValue(ASource);
                for K := 0 to AValue.GetArrayLength - 1 do
                  Add.FromRtti(AValue.GetArrayElement(K));
              end;
            end;
          tkClass:
            begin
              AValue := AFields[J].GetValue(ASource);
              AObj := AValue.AsObject;
              if (AObj is TStrings) then
              begin
                Add(AFields[J].Name).AsString := TStrings(AObj).Text
              end
              else if AObj is TCollection then
                AddCollection(AddArray(AFields[J].Name), AObj as TCollection)
              else // 其它类型的对象不保存
                Add(AFields[J].Name, jdtObject)
                  .FromRtti(AObj, AFields[J].FieldType.Handle);
            end;
          tkRecord:
            begin
              DataType := jdtObject;
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
      DataType := jdtArray;
      AddCollection(Self, AObj as TCollection)
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
                    AddCollection(AddArray(AName), AChildObj as TCollection)
                  else
                    Add(AName, jdtObject).FromRtti(AChildObj);
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
                  else if JsonRttiEnumAsInt then
                    Add(AName).AsInteger := GetOrdProp(AObj, APropList[J])
                  else
                    Add(AName).AsString := GetEnumProp(AObj, APropList[J]);
                end;
              tkSet:
                begin
                  if JsonRttiEnumAsInt then
                    Add(AName).AsInteger := GetOrdProp(AObj, APropList[J])
                  else
                    Add(AName).AsString := GetSetProp(AObj, APropList[J], True);
                end;
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
    I, c: Integer;
  begin
    DataType := jdtArray;
    Clear;
    TValue.Make(ASource, AType, AValue);
    c := AValue.GetArrayLength;
    for I := 0 to c - 1 do
      Add.FromRtti(AValue.GetArrayElement(I));
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

procedure TQJson.FromRtti(AInstance: TValue);
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
        DataType := jdtArray;
        Clear;
        c := AInstance.GetArrayLength;
        for I := 0 to c - 1 do
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
        else if JsonRttiEnumAsInt then
          AsInteger := AInstance.AsOrdinal
        else
          AsString := AInstance.ToString;
      end;
    tkSet:
      AsString := AInstance.ToString;
    tkVariant:
      AsVariant := AInstance.AsVariant;
    tkInt64:
      AsInt64 := AInstance.AsInt64;
  end;
end;
{$IFEND >=2010}

function TQJson.GetA(const APath: String): TQJson;
begin
  Result := ItemByPath(APath);
end;

function TQJson.GetAsArray: QStringW;
begin
  if DataType = jdtArray then
    Result := Value
  else
    raise Exception.Create(Format(SBadConvert, [AsString, 'Array']));
end;

function TQJson.GetAsBase64Bytes: TBytes;
begin
  Result := InternalGetAsBytes(DoDecodeAsBase64, teUtf8, False);
end;

function TQJson.GetAsBoolean: Boolean;
begin
  if not TryGetAsBoolean(Result) then
    raise Exception.Create(Format(SBadConvert, [JsonTypeName[DataType],
      'Boolean']));
end;

function TQJson.GetAsBytes: TBytes;
begin
  if Assigned(OnQJsonDecodeBytes) then
    Result := InternalGetAsBytes(OnQJsonDecodeBytes, teUnicode16LE, True)
  else
    Result := InternalGetAsBytes(DoDecodeAsHex, teUnicode16LE, True);
end;

function TQJson.GetAsDateTime: TDateTime;
begin
  if not TryGetAsDateTime(Result) then
    raise Exception.Create(Format(SBadConvert, [JsonTypeName[DataType],
      'DateTime']));
end;

function TQJson.GetAsFloat: Extended;
begin
  if not TryGetAsFloat(Result) then
    raise Exception.Create(Format(SBadConvert, [JsonTypeName[DataType],
      'Numeric']))
end;

function TQJson.GetAsHexBytes: TBytes;
begin
  Result := InternalGetAsBytes(DoDecodeAsHex, teUtf8, False);
end;

function TQJson.GetAsInt64: Int64;
begin
  if not TryGetAsInt64(Result) then
    raise Exception.Create(Format(SBadConvert, [JsonTypeName[DataType],
      'Numeric']))
end;

function TQJson.GetAsInteger: Integer;
begin
  Result := GetAsInt64;
end;

function TQJson.GetAsJson: QStringW;
begin
  Result := Encode(False, False, '  ');
//    Result := Encode(True, False, '  ');
end;

function TQJson.GetAsObject: QStringW;
begin
  if DataType = jdtObject then
    Result := Value
  else
    raise Exception.Create(Format(SBadConvert, [AsString, 'Object']));
end;

function TQJson.GetAsString: QStringW;
begin
  if DataType in [jdtNull, jdtUnknown] then
    SetLength(Result, 0)
  else
    Result := Value;
end;

function TQJson.GetAsVariant: Variant;
var
  I: Integer;
begin
  case DataType of
    jdtNull:
      Result := Null;
    jdtString:
      begin
        if IsDateTime then
          Result := AsDateTime
        else
          Result := AsString;
      end;
    jdtInteger:
      Result := AsInt64;
    jdtFloat:
      Result := AsFloat;
    jdtDateTime:
      Result := AsDateTime;
    jdtBoolean:
      Result := AsBoolean;
    jdtArray, jdtObject:
      begin
        Result := VarArrayCreate([0, Count - 1], varVariant);
        for I := 0 to Count - 1 do
          Result[I] := Items[I].AsVariant;
      end
  else
    VarClear(Result);
  end;
end;

function TQJson.GetB(const APath: String): Boolean;
begin
  Result := BoolByPath(APath, False);
end;

function TQJson.GetCount: Integer;
begin
  if DataType in [jdtObject, jdtArray] then
    Result := FItems.Count
  else
    Result := 0;
end;

function TQJson.GetEnumerator: TQJsonEnumerator;
begin
  Result := TQJsonEnumerator.Create(Self);
end;

function TQJson.GetF(const APath: String): Double;
begin
  Result := FloatByPath(APath, 0);
end;

function TQJson.GetI(const APath: String): Int64;
begin
  Result := IntByPath(APath, 0);
end;

function TQJson.GetIsArray: Boolean;
begin
  Result := (DataType = jdtArray);
end;

function TQJson.GetIsBool: Boolean;
begin
  if DataType = jdtBoolean then
    Result := True
  else if DataType = jdtString then
    Result := TryStrToBool(FValue, Result)
  else
    Result := DataType in [jdtInteger, jdtFloat, jdtDateTime];
end;

function TQJson.GetIsDateTime: Boolean;
var
  ATime: TDateTime;
begin
  Result := (DataType = jdtDateTime);
  if not Result then
  begin
    if DataType = jdtString then
      Result := ParseDateTime(PQCharW(FValue), ATime) or
        ParseJsonTime(PQCharW(FValue), ATime) or
        ParseWebTime(PQCharW(FValue), ATime);
  end;
end;

function TQJson.GetIsNull: Boolean;
begin
  Result := (DataType = jdtNull);
end;

function TQJson.GetIsNumeric: Boolean;
var
  V: Extended;
begin
  if DataType in [jdtInteger, jdtFloat] then
    Result := True
  else if (DataType = jdtString) then
    Result := TryStrToFloat(AsString, V)
  else
    Result := False;
end;

function TQJson.GetIsObject: Boolean;
begin
  Result := (DataType = jdtObject);
end;

function TQJson.GetIsString: Boolean;
begin
  Result := (DataType = jdtString);
end;

function TQJson.GetItemIndex: Integer;
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

function TQJson.GetItems(AIndex: Integer): TQJson;
begin
  Result := FItems[AIndex];
end;

function TQJson.GetO(const APath: String): TQJson;
begin
  Result := ItemByPath(APath);
end;

function TQJson.GetPath: QStringW;
begin
  Result := GetRelPath(nil);
end;

function TQJson.GetRelPath(AParent: TQJson; APathDelimiter: QCharW): QStringW;
var
  AItem, APItem: TQJson;
  AItemName: QStringW;
begin
  AItem := Self;
  SetLength(Result, 0);
  while Assigned(AItem) and (AItem <> AParent) do
  begin
    APItem := AItem.Parent;
    if Assigned(APItem) then
    begin
      if APItem.DataType = jdtArray then
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
  if (Length(Result) > 0) and (PQCharW(Result)^ = APathDelimiter) then
    Result := StrDupX(PQCharW(Result) + 1, Length(Result) - 1);
end;

function TQJson.GetRoot: TQJson;
begin
  Result := Self;
  while Result.FParent <> nil do
    Result := Result.FParent;
end;

function TQJson.GetS(const APath: String): String;
begin
  Result := ValueByPath(APath, '');
end;

function TQJson.GetT(const APath: String): TDateTime;
begin
  Result := DateTimeByPath(APath, 0);
end;

function TQJson.GetV(const APath: String): Variant;
var
  AItem: TQJson;
begin
  AItem := ItemByPath(APath);
  if Assigned(AItem) then
    Result := AItem.AsVariant
  else
    Result := Null;
end;

function TQJson.GetValue: QStringW;
  procedure ValueAsDateTime;
  var
    ADate: Integer;
    AValue: Extended;
  begin
    AValue := PExtended(FValue)^;
    ADate := Trunc(AValue);
    if SameValue(ADate, 0) then // Date为0，是时间
    begin
      if SameValue(AValue, 0) then
        Result := FormatDateTime(JsonDateFormat, AValue)
      else
        Result := FormatDateTime(JsonTimeFormat, AValue);
    end
    else
    begin
      if SameValue(AValue - ADate, 0) then
        Result := FormatDateTime(JsonDateFormat, AValue)
      else
        Result := FormatDateTime(JsonDateTimeFormat, AValue);
    end;
  end;

begin
  case DataType of
    jdtNull, jdtUnknown:
      Result := CharNull;
    jdtString:
      Result := FValue;
    jdtInteger:
      Result := IntToStr(PInt64(FValue)^);
    jdtFloat:
      Result := FloatToStr(PExtended(FValue)^);
    jdtDateTime:
      ValueAsDateTime;
    jdtBoolean:
      Result := BooleanToStr(PBoolean(FValue)^);
    jdtArray, jdtObject:
      Result := Encode(True)
  else
    raise QException.CreateFmt(SBadConvert, [Integer(DataType), 'DataType']);
  end;
end;

function TQJson.HasChild(ANamePath: QStringW; var AChild: TQJson): Boolean;
begin
  AChild := ItemByPath(ANamePath);
  Result := AChild <> nil;
end;

function TQJson.HashName(const S: QStringW): TQHashType;
var
  ATemp: QStringW;
begin
  if IgnoreCase then
  begin
    ATemp := UpperCase(S);
    Result := HashOf(PQCharW(ATemp), Length(ATemp) shl 1);
  end
  else
    Result := HashOf(PQCharW(S), Length(S) shl 1)
end;

procedure TQJson.HashNeeded;
begin
  if (FNameHash = 0) and (Length(FName) > 0) then
    FNameHash := HashName(Name);
end;

function TQJson.IndexOf(const AName: QStringW): Integer;
var
  I, l: Integer;
  AItem: TQJson;
  AHash: Cardinal;
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
    if Length(AItem.FName) = l then
    begin
      AItem.HashNeeded;
      if AItem.FNameHash = AHash then
      begin
        if StrCmpW(PQCharW(AItem.FName), PQCharW(AName), IgnoreCase) = 0 then
        begin
          Result := I;
          Break;
        end;
      end;
    end;
  end;
end;

function TQJson.IndexOfValue(const AValue: Variant; AStrict: Boolean): Integer;
var
  I: Integer;
  function DTEqual(S: QStringW; const V: TDateTime): Boolean;
  var
    T: TDateTime;
  begin
    if ParseDateTime(PWideChar(S), T) or ParseJsonTime(PWideChar(S), T) or
      ParseWebTime(PQCharW(FValue), T) then
      Result := SameValue(T, V)
    else
      Result := False;
  end;

  function BoolEqual(S: String; const V: Boolean): Boolean;
  var
    T: Boolean;
  begin
    if TryStrToBool(S, T) then
      Result := T = V
    else
      Result := False;
  end;

  function CompareWithVariant(ANode: TQJson; const V: Variant): Boolean;
  var
    J: Integer;
  begin
    if VarIsArray(V) then
    begin
      Result := (ANode.DataType in [jdtObject, jdtArray]) and
        (ANode.Count = VarArrayHighBound(V, VarArrayDimCount(V)) -
        VarArrayLowBound(V, VarArrayDimCount(V)) + 1);
      if Result then
      begin
        for J := 0 to ANode.Count - 1 do
        begin
          if not CompareWithVariant(ANode[J], V[J]) then
          begin
            Result := False;
            Break;
          end;
        end;
      end;
    end
    else if ANode.DataType in [jdtObject, jdtArray] then
      Result := False
    else
    begin
      Result := False;
      case VarType(V) of
        varEmpty, varNull, varUnknown:
          Result := ANode.IsNull;
        varSmallInt, varInteger, varByte, varShortInt, varWord, varLongWord,
          varInt64{$IF RtlVersion>=26}
          , varUInt64{$IFEND}:
          begin
            if ANode.DataType <> jdtString then
              Result := ANode.AsInt64 = V
            else if AStrict then
              Result := False
            else
              Result := ANode.AsString = VarToStr(V);
          end;
        varSingle, varDouble, varCurrency:
          begin
            if ANode.DataType <> jdtString then
              Result := SameValue(ANode.AsFloat, V)
            else if AStrict then
              Result := False
            else
              Result := ANode.AsString = VarToStr(V);
          end;
        varDate:
          begin
            if ANode.DataType = jdtDateTime then
              Result := SameValue(ANode.AsDateTime, V)
            else if ANode.DataType = jdtString then
              Result := DTEqual(ANode.AsString, V);
          end;
        varOleStr, varString{$IFDEF UNICODE}, varUString{$ENDIF}:
          Result := (ANode.AsString = V);
        varBoolean:
          begin
            if AStrict then
            begin
              if ANode.DataType = jdtBoolean then
                Result := ANode.AsBoolean = V
              else
                Result := False;
            end
            else
            begin
              if ANode.IsString then
                Result := BoolEqual(ANode.AsString, V)
              else
                Result := ANode.AsBoolean = V;
            end;
          end;
      end;
    end;
  end;

begin
  Result := -1;
  for I := 0 to Count - 1 do
  begin
    if CompareWithVariant(Items[I], AValue) then
    begin
      Result := I;
      Break;
    end;
  end;
end;

function TQJson.Insert(AIndex: Integer; const AName, AValue: String;
  ADataType: TQJsonDataType): TQJson;
begin
  Result := Insert(AIndex, AName);
  Result.FromType(AValue, ADataType);
end;

function TQJson.Insert(AIndex: Integer; const AName: String;
  ADataType: TQJsonDataType): TQJson;
begin
  Result := CreateJson;
  Insert(AIndex, Result);
  Result.Name := AName;
  Result.DataType := ADataType;
end;

function TQJson.Insert(AIndex: Integer; const AName: String): TQJson;
begin
  Result := Insert(AIndex, AName, jdtUnknown);
end;

function TQJson.Insert(AIndex: Integer; const AName: String;
  AValue: Extended): TQJson;
begin
  Result := Insert(AIndex, AName);
  Result.AsFloat := AValue;
end;

procedure TQJson.Insert(AIndex: Integer; AChild: TQJson);
begin
  if Assigned(AChild.Parent) then
  begin
    if AChild.Parent <> Self then
      AChild.Parent.Remove(AChild)
    else
      Exit;
  end;
  ArrayNeeded(jdtObject);
  AChild.FParent := Self;
  AChild.FIgnoreCase := FIgnoreCase;
  if AIndex <= 0 then
    AIndex := 0
  else if AIndex >= Count then
    AIndex := Count;
  FItems.Insert(AIndex, AChild);
end;

function TQJson.Insert(AIndex: Integer; const AName: String;
  AValue: Boolean): TQJson;
begin
  Result := Insert(AIndex, AName);
  Result.AsBoolean := AValue;
end;

function TQJson.Insert(AIndex: Integer; const AName: String;
  AValue: Int64): TQJson;
begin
  Result := Insert(AIndex, AName);
  Result.AsInt64 := AValue;
end;

function TQJson.IntByName(AName: QStringW; ADefVal: Int64): Int64;
var
  AChild: TQJson;
begin
  AChild := ItemByName(AName);
  if Assigned(AChild) then
  begin
    if not AChild.TryGetAsInt64(Result) then
      Result := ADefVal;
  end
  else
    Result := ADefVal;
end;

function TQJson.IntByPath(APath: QStringW; ADefVal: Int64): Int64;
var
  AItem: TQJson;
begin
  AItem := ItemByPath(APath);
  if Assigned(AItem) then
  begin
    if not AItem.TryGetAsInt64(Result) then
      Result := ADefVal;
  end
  else
    Result := ADefVal;
end;

function TQJson.InternalEncode(ABuilder: TQStringCatHelperW;
  ASettings: TJsonEncodeSettings; const AIndent: QStringW): TQStringCatHelperW;
  procedure StrictJsonTime(ATime: TDateTime);
  var
    MS: Int64; // 时区信息不保存
  const
    JsonTimeStart: PWideChar = '/DATE(';
    JsonTimeEnd: PWideChar = ')/';
    UnixDelta: Int64 = 25569;
  begin
    MS := Trunc((ATime - UnixDelta) * 86400000);
    ABuilder.Cat(JsonTimeStart, 6);
    if (JsonTimezone >= -12) and (JsonTimezone <= 12) then
    begin
      Dec(MS, 3600000 * JsonTimezone);
      if JsonDatePrecision = jdpSecond then
        MS := MS div 1000;
      ABuilder.Cat(IntToStr(MS));
      if JsonTimezone >= 0 then
        ABuilder.Cat('+');
      ABuilder.Cat(JsonTimezone);
    end
    else
      ABuilder.Cat(IntToStr(MS));
    ABuilder.Cat(JsonTimeEnd, 2);
  end;
  procedure AddComment(const S: QStringW);
  var
    p: PQCharW;
    ALine: QStringW;
  const
    SLineComment: PWideChar = '//';
    SBlockComentStart: PWideChar = '/*';
    SBlockComentStop: PWideChar = '*/';
  begin
    p := PQCharW(S);
    while p^ <> #0 do
    begin
      ALine := DecodeLineW(p, False);
      ABuilder.Cat(SLineComment, 2);
      ABuilder.Cat(ALine);
      ABuilder.Cat(SLineBreak);
    end;
  end;
  function Ignore(ANode: TQJson): Boolean;
  begin
    Result := False;
    if [jesIgnoreNull, jesIgnoreDefault] * ASettings <> [] then
    begin
      if ANode.DataType in [jdtNull, jdtUnknown] then
        Result := True
      else if jesIgnoreDefault in ASettings then
      begin
        case ANode.DataType of
          jdtString:
            Result := Length(ANode.FValue) = 0;
          jdtInteger:
            Result := ANode.AsInt64 = 0;
          jdtFloat:
            Result := IsZero(ANode.AsFloat);
          jdtBoolean:
            Result := not ANode.AsBoolean;
          jdtDateTime:
            Result := IsZero(ANode.AsDateTime);
          jdtArray, jdtObject:
            Result := ANode.Count = 0;
        end;
      end;
    end;
  end;
  procedure DoEncode(ANode: TQJson; ALevel: Integer);
  var
    I, AEncoded: Integer;
    ArrayWraped: Boolean;
    AChild: TQJson;
  begin
    if (jesWithComment in ASettings) and (Length(ANode.Comment) > 0) and
      ((ANode.CommentStyle = jcsBeforeName) or
      ((ANode.CommentStyle = jcsInherited) and (CommentStyle = jcsBeforeName)))
    then
      AddComment(ANode.Comment);
    if (ANode.Parent <> nil) and (ANode.Parent.DataType <> jdtArray) and
      (ANode <> Self) then
    begin
      if jesDoFormat in ASettings then
        ABuilder.Replicate(AIndent, ALevel);
      ABuilder.Cat(CharNameStart);
      JsonCat(ABuilder, ANode.FName, jesDoEscape in ASettings);
      ABuilder.Cat(CharNameEnd);
    end;
    case ANode.DataType of
      jdtArray:
        begin
          ABuilder.Cat(CharArrayStart);
          if ANode.Count > 0 then
          begin
            ArrayWraped := False;
            AEncoded := 0;
            for I := 0 to ANode.Count - 1 do
            begin
              AChild := ANode.Items[I];
              if Ignore(AChild) then
                continue;
              if AChild.DataType in [jdtArray, jdtObject] then
              begin
                if jesDoFormat in ASettings then
                begin
                  ABuilder.Cat(SLineBreak); // 对于对象和数组，换行
                  ABuilder.Replicate(AIndent, ALevel + 1);
                  ArrayWraped := True;
                end;
              end;
              DoEncode(AChild, ALevel + 1);
              Inc(AEncoded);
            end;
            if AEncoded > 0 then
              ABuilder.Back(1);
            if ArrayWraped then
            begin
              ABuilder.Cat(SLineBreak);
              ABuilder.Replicate(AIndent, ALevel);
            end;
          end;
          ABuilder.Cat(CharArrayEnd);
        end;
      jdtObject:
        begin
          ABuilder.Cat(CharObjectStart);
          AEncoded := 0;
          if jesDoFormat in ASettings then
            ABuilder.Cat(SLineBreak);
          for I := 0 to ANode.Count - 1 do
          begin
            AChild := ANode.Items[I];
            if Ignore(AChild) then
              continue;
            DoEncode(AChild, ALevel + 1);
            Inc(AEncoded);
            if jesDoFormat in ASettings then
              ABuilder.Cat(SLineBreak);
          end;
          if AEncoded > 0 then
          begin
            if jesDoFormat in ASettings then
              ABuilder.BackIf(' '#9#10#13);
            ABuilder.Back(1);
          end;
          if (jesDoFormat in ASettings) and (AEncoded > 0) then
          begin
            ABuilder.BackIf(' '#9#10#13);
            ABuilder.Cat(SLineBreak);
          end;
          if AEncoded > 0 then
          begin
            if (jesDoFormat in ASettings) then
              ABuilder.Replicate(AIndent, ALevel);
          end
          else
            ABuilder.BackIf(' '#9#10#13);
          ABuilder.Cat(CharObjectEnd);
        end;
      jdtNull, jdtUnknown:
        begin
          if jesNullAsString in ASettings then
            ABuilder.Cat(CharStringStart).Cat(CharStringEnd)
          else
            ABuilder.Cat(CharNull);
        end;
      jdtString:
        begin
          ABuilder.Cat(CharStringStart);
          JsonCat(ABuilder, ANode.FValue, jesDoEscape in ASettings);
          ABuilder.Cat(CharStringEnd);
        end;
      jdtInteger, jdtFloat, jdtBoolean:
        ABuilder.Cat(ANode.Value);
      jdtDateTime:
        begin
          ABuilder.Cat(CharStringStart);
          if jesJavaDateTime in ASettings then
            StrictJsonTime(ANode.AsDateTime)
          else
            ABuilder.Cat(ANode.Value);
          ABuilder.Cat(CharStringEnd);
        end;
    end;
    if (jesWithComment in ASettings) and (Length(ANode.Comment) > 0) and
      ((ANode.CommentStyle = jcsAfterValue) or
      ((ANode.CommentStyle = jcsInherited) and (CommentStyle = jcsAfterValue)))
    then
    begin
      AddComment(ANode.Comment);
      if jesDoFormat in ASettings then
        ABuilder.Replicate(AIndent, ALevel);
    end;
    ABuilder.Cat(CharComma);
  end;

begin
  Result := ABuilder;
  DoEncode(Self, 0);
end;

function TQJson.InternalGetAsBytes(AConverter: TQJsonDecodeBytesEvent;
  AEncoding: TTextEncoding; AWriteBom: Boolean): TBytes;
var
  I: Integer;
  AItem: TQJson;
  function StrToBytes: TBytes;
  var
    V: QStringW;
    U: QStringA;
  begin
    V := AsString;
    SetLength(Result, 0);
    try
      AConverter(V, Result)
    except
    end;
    if (Length(Result) = 0) and (Length(V) > 0) then
    begin
      if AEncoding = teUtf8 then
      begin
        U := qstring.Utf8Encode(V);
        if AWriteBom then
        begin
          SetLength(Result, U.Length + 3);
          // 前面加上UTF8的BOM
          Result[0] := $EF;
          Result[1] := $BB;
          Result[2] := $BF;
          Move(PQCharA(U)^, Result[3], U.Length);
        end
        else
          Result := U;
      end
      else if AEncoding = teAnsi then // ANSI没有 BOM 头，所以忽略
        Result := AnsiEncode(V)
      else if AEncoding = teUnicode16BE then
      begin
        if AWriteBom then
        begin
          SetLength(Result, Length(V) shl 1 + 2);
          Move(PWideChar(V)^, Result[2], Length(Result) - 2);
          ExchangeByteOrder(PQCharA(@Result[2]), Length(Result));
          Result[0] := $FE;
          Result[1] := $FF;
        end
        else
        begin
          SetLength(Result, Length(V) shl 1);
          Move(PWideChar(V)^, Result[0], Length(Result));
          ExchangeByteOrder(PQCharA(@Result[0]), Length(Result));
        end;
      end
      else
      begin
        if AWriteBom then
        begin
          SetLength(Result, Length(V) shl 1 + 2);
          Move(PWideChar(V)^, Result[2], Length(Result) - 2);
          Result[0] := $FF;
          Result[1] := $FE;
        end
        else
        begin
          SetLength(Result, Length(V) shl 1);
          Move(PWideChar(V)^, Result[0], Length(Result));
        end;
      end;
    end;
  end;

begin
  if DataType = jdtString then // 字符串
  begin
    Result := StrToBytes
  end
  else if DataType = jdtArray then
  begin
    SetLength(Result, Count);
    for I := 0 to Count - 1 do
    begin
      AItem := Items[I];
      if (AItem.DataType = jdtInteger) and (AItem.AsInteger >= 0) and
        (AItem.AsInteger <= 255) then
        Result[I] := AItem.AsInteger
      else
        raise Exception.CreateFmt(SConvertError, ['jdtArray', 'Bytes']);
    end;
  end
  else
    raise Exception.CreateFmt(SConvertError, [JsonTypeName[DataType], 'Bytes']);
end;

procedure TQJson.InternalRttiFilter(ASender: TQJson; AObject: Pointer;
  APropName: QStringW; APropType: PTypeInfo; var Accept: Boolean;
  ATag: Pointer);
var
  ATagData: PQJsonInternalTagData;
  procedure DoNameFilter;
  var
    ps: PQCharW;
  begin
    if Length(ATagData.AcceptNames) > 0 then
    begin
      Accept := False;
      ps := StrIStrW(PQCharW(ATagData.AcceptNames), PQCharW(APropName));
      if (ps <> nil) and ((ps = PQCharW(ATagData.AcceptNames)) or (ps[-1] = ',')
        or (ps[-1] = ';')) then
      begin
        ps := ps + Length(APropName);
        Accept := (ps^ = ',') or (ps^ = ';') or (ps^ = #0);
      end;
    end
    else if Length(ATagData.IgnoreNames) > 0 then
    begin
      ps := StrIStrW(PQCharW(ATagData.IgnoreNames), PQCharW(APropName));
      Accept := True;
      if (ps <> nil) and ((ps = PQCharW(ATagData.IgnoreNames)) or (ps[-1] = ',')
        or (ps[-1] = ';')) then
      begin
        ps := ps + Length(APropName);
        Accept := not((ps^ = ',') or (ps^ = ';') or (ps^ = #0));
      end;
    end;
  end;

begin
  ATagData := PQJsonInternalTagData(ATag);
  if ATagData.TagType = ttNameFilter then
  begin
    DoNameFilter;
    Exit;
  end;
{$IF RTLVersion>=21}
  if ATagData.TagType = ttAnonEvent then
  begin
    ATagData.OnEvent(ASender, AObject, APropName, APropType, Accept,
      ATagData.Tag);
  end;
{$IFEND >=2010}
end;

procedure TQJson.InternalSetAsBytes(AConverter: TQJsonEncodeBytesEvent;
  ABytes: TBytes);
var
  S: QStringW;
begin
  AConverter(ABytes, S);
  AsString := S;
end;

function TQJson.Intersect(AJson: TQJson): TQJson;
var
  I, H1, H2, J: Integer;
  AItem1, AItem2, AResult: TQJson;
begin
  Result := TQJson.Create;
  if DataType = AJson.DataType then
  begin
    H1 := Count - 1;
    H2 := AJson.Count - 1;
    for I := 0 to H1 do
    begin
      AItem1 := Items[I];
      for J := 0 to H2 do
      begin
        AItem2 := AJson[J];
        if (AItem1.Name = AItem2.Name) and (AItem1.DataType = AItem2.DataType)
        then
        begin
          if AItem1.DataType in [jdtArray, jdtObject] then
          begin
            AResult := AItem1.Intersect(AItem2);
            if AResult.Count > 0 then
              Result.Add(AItem1.Name, AResult)
            else
              FreeAndNil(AResult);
          end
          else if AItem1.FValue = AItem2.FValue then
          begin
            Result.Add(AItem1.Name, AItem1.DataType).Assign(AItem1);
            Break;
          end;
        end;
      end;
    end;
  end;
end;

function TQJson.IsChildOf(AParent: TQJson): Boolean;
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

function TQJson.Exists(const APath: QStringW): Boolean;
begin
  Result := ItemByPath(APath) <> nil;
end;

function TQJson.IsParentOf(AChild: TQJson): Boolean;
begin
  if Assigned(AChild) then
    Result := AChild.IsChildOf(Self)
  else
    Result := False;
end;

function TQJson.ItemByName(AName: QStringW): TQJson;
var
  I: Integer;
  p: PQCharW;
  AIndex: Int64;
begin
  Result := nil;
  p := PQCharW(AName);
  if (p^ = '[') and (DataType in [jdtObject, jdtArray]) then
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
  else if DataType = jdtObject then
  begin
    I := IndexOf(AName);
    if I <> -1 then
      Result := Items[I];
  end;
end;

function TQJson.ItemByName(const AName: QStringW; AList: TQJsonItemList;
  ANest: Boolean): Integer;
var
  AHash: Cardinal;
  l: Integer;
  function InternalFind(AParent: TQJson): Integer;
  var
    I: Integer;
    AItem: TQJson;
  begin
    Result := -1;
    for I := 0 to Count - 1 do
    begin
      AItem := Items[I];
      if Length(AItem.FName) = l then
      begin
        AItem.HashNeeded;
        if AItem.FNameHash = AHash then
        begin
          if StrCmpW(PQCharW(AItem.FName), PQCharW(AName), IgnoreCase) = 0 then
            AList.Add(AItem);
        end;
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

function TQJson.ItemByPath(APath: QStringW): TQJson;
var
  AParent: TQJson;
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
    AName := JavaUnescape(DecodeTokenW(p, PathDelimiters, WideChar(0),
      False), False);
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
          if Result.DataType in [jdtArray, jdtObject] then
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
                      continue
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
{$IFDEF ENABLE_REGEX}

function TQJson.ItemByRegex(const ARegex: QStringW; AList: TQJsonItemList;
  ANest: Boolean): Integer;
var
  ANode: TQJson;
  APcre: TPerlRegEx;
  function RegexStr(const S: QStringW):
{$IF RTLVersion<=24}UTF8String{$ELSE}UnicodeString{$IFEND};
  begin
{$IF RTLVersion<19}
    Result := System.Utf8Encode(S);
{$ELSE}
{$IF RTLVersion<=24}
    Result := UTF8String(S);
{$ELSE}
    Result := S;
{$IFEND}
{$IFEND}
  end;
  function InternalFind(AParent: TQJson): Integer;
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

function TQJson.Match(const ARegex: QStringW; AMatches: TQJsonMatchSettings)
  : IQJsonContainer;
var
  T: TQJsonContainer;
begin
  T := TQJsonContainer.Create;
  try
    T.FItems.Add(Self);
    Result := T.Match(ARegex, AMatches);
  finally
    FreeAndNil(T);
  end;
end;
{$ENDIF}

class function TQJson.JsonCat(const S: QStringW; ADoEscape: Boolean): QStringW;
var
  ABuilder: TQStringCatHelperW;
begin
  ABuilder := TQStringCatHelperW.Create;
  try
    JsonCat(ABuilder, S, ADoEscape);
    Result := ABuilder.Value;
  finally
    FreeObject(ABuilder);
  end;
end;

class function TQJson.JsonEscape(const S: QStringW; ADoEscape: Boolean)
  : QStringW;
begin
  Result := JsonCat(S, ADoEscape);
end;

class function TQJson.JsonUnescape(const S: QStringW): QStringW;
begin
  Result := BuildJsonString(S);
end;

procedure TQJson.LoadFromFile(const AFileName: String;
  AEncoding: TTextEncoding);
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

procedure TQJson.LoadFromStream(AStream: TStream; AEncoding: TTextEncoding);
var
  S: QStringW;
begin
  S := LoadTextW(AStream, AEncoding);
  case Length(S) of
    0:
      DataType := jdtNull;
    1:
      raise Exception.Create(SBadJson)
  else
    Parse(PQCharW(S), Length(S));
  end;
end;

procedure TQJson.Merge(ASource: TQJson; AMethod: TQJsonMergeMethod);
var
  I, AIdx: Integer;
  ASourceChild: TQJson;
  function IndexOfValue: Integer;
  var
    J, H: Integer;
    AItem: TQJson;
  begin
    H := Count - 1;
    Result := -1;
    for J := 0 to H do
    begin
      AItem := Items[J];
      if AItem.Equals(ASourceChild) then
      begin
        Result := J;
        Break;
      end;
    end;
  end;

begin
  for I := 0 to ASource.Count - 1 do
  begin
    ASourceChild := ASource[I];
    if AMethod <> jmmAppend then
    begin
      if ASourceChild.IsArray then
        AIdx := IndexOfValue
      else
        AIdx := IndexOf(ASourceChild.Name);
      if AIdx = -1 then
        Add(ASourceChild.Name, ASourceChild.DataType).Assign(ASourceChild)
      else if AMethod = jmmAsSource then
        Items[AIdx].Assign(ASourceChild)
      else if AMethod = jmmIgnore then // 如果一致，则尝试合并子元素
        Items[AIdx].Merge(ASourceChild, AMethod)
      else // jmmReplace
      begin
        if Items[AIdx].DataType in [jdtArray, jdtObject] then
          Items[AIdx].Merge(ASourceChild, AMethod)
        else
          Items[AIdx].Assign(ASourceChild);
      end;
    end
    else
      Add(ASourceChild.Name, ASourceChild.DataType).Assign(ASourceChild);
  end;
end;

procedure TQJson.MoveTo(ANewParent: TQJson; AIndex: Integer);
begin
  if ANewParent = Self then
    raise Exception.Create(SCantAttachToSelf)
  else
  begin
    if Parent = ANewParent then
      Exit;
    if IsParentOf(ANewParent) then
      raise Exception.Create(SCantMoveToChild);
    if ANewParent.DataType in [jdtArray, jdtObject] then
    begin
      if ANewParent.DataType = jdtObject then
      begin
        if Length(Name) = 0 then
          raise Exception.Create(SCantAttachNoNameNodeToObject)
        else if ANewParent.IndexOf(Name) <> -1 then
          raise Exception.CreateFmt(SNodeNameExists, [Name]);;
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
      DoJsonNameChanged(Self);
    end
    else
      raise Exception.Create(SCanAttachToNoneContainer);
  end;
end;

procedure TQJson.Parse(p: PWideChar; l: Integer);
  procedure ParseCopy;
  var
    S: QStringW;
  begin
    S := StrDupW(p, 0, l);
    p := PQCharW(S);
    ParseObject(p);
  end;

begin
  if DataType in [jdtObject, jdtArray] then
    Clear;
  if (l > 0) and (p[l] <> #0) then
    ParseCopy
  else if p^ <> #0 then
    ParseObject(p);
end;

procedure TQJson.Parse(const S: QStringW);
begin
  Parse(PQCharW(S), Length(S));
end;

procedure TQJson.ParseBlock(AStream: TStream; AEncoding: TTextEncoding);
var
  AMS: TMemoryStream;
  procedure ParseUCS2;
  var
    c: QCharW;
    ABlockCount: Integer;
  begin
    ABlockCount := 0;
    repeat
      if ABlockCount = 0 then
      begin
        repeat
          AStream.ReadBuffer(c, SizeOf(QCharW));
          AMS.WriteBuffer(c, SizeOf(QCharW));
        until c = '{';
        Inc(ABlockCount);
      end;
      AStream.ReadBuffer(c, SizeOf(QCharW));
      if c = '{' then
        Inc(ABlockCount)
      else if c = '}' then
        Dec(ABlockCount);
      AMS.WriteBuffer(c, SizeOf(QCharW));
    until ABlockCount = 0;
    c := #0;
    AMS.Write(c, SizeOf(QCharW));
    Parse(AMS.Memory, AMS.Size - 1);
  end;

  procedure ParseUCS2BE;
  var
    c: Word;
    ABlockCount: Integer;
    p: PQCharW;
  begin
    ABlockCount := 0;
    repeat
      if ABlockCount = 0 then
      begin
        repeat
          AStream.ReadBuffer(c, SizeOf(Word));
          c := (c shr 8) or ((c shl 8) and $FF00);
          AMS.WriteBuffer(c, SizeOf(Word));
        until c = $7B; // #$7B={
        Inc(ABlockCount);
      end;
      AStream.ReadBuffer(c, SizeOf(Word));
      c := (c shr 8) or ((c shl 8) and $FF00);
      if c = $7B then
        Inc(ABlockCount)
      else if c = $7D then // #$7D=}
        Dec(ABlockCount);
      AMS.WriteBuffer(c, SizeOf(QCharW));
    until ABlockCount = 0;
    c := 0;
    AMS.Write(c, SizeOf(QCharW));
    p := AMS.Memory;
    ParseObject(p);
  end;

  procedure ParseByByte;
  var
    c: Byte;
    ABlockCount: Integer;
  begin
    ABlockCount := 0;
    repeat
      if ABlockCount = 0 then
      begin
        repeat
          AStream.ReadBuffer(c, SizeOf(Byte));
          AMS.WriteBuffer(c, SizeOf(Byte));
        until c = $7B;
        // #$7B={
        Inc(ABlockCount);
      end;
      AStream.ReadBuffer(c, SizeOf(Byte));
      if c = $7B then
        Inc(ABlockCount)
      else if c = $7D then // #$7D=}
        Dec(ABlockCount);
      AMS.WriteBuffer(c, SizeOf(Byte));
    until ABlockCount = 0;
  end;

  procedure ParseUtf8;
  var
    S: QStringW;
    p: PQCharW;
  begin
    ParseByByte;
    S := qstring.Utf8Decode(AMS.Memory, AMS.Size);
    p := PQCharW(S);
    ParseObject(p);
  end;

  procedure ParseAnsi;
  var
    S: QStringW;
  begin
    ParseByByte;
    S := qstring.AnsiDecode(AMS.Memory, AMS.Size);
    Parse(PQCharW(S));
  end;

begin
  AMS := TMemoryStream.Create;
  try
    if AEncoding = teAnsi then
      ParseAnsi
    else if AEncoding = teUtf8 then
      ParseUtf8
    else if AEncoding = teUnicode16LE then
      ParseUCS2
    else if AEncoding = teUnicode16BE then
      ParseUCS2BE
    else
      raise Exception.Create(SBadJsonEncoding);
  finally
    AMS.Free;
  end;
end;

function TQJson.ParseJsonPair(ABuilder: TQStringCatHelperW;
  var p: PQCharW): Integer;
const
  SpaceWithSemicolon: PWideChar = ': '#9#10#13#$3000;
  CommaWithSpace: PWideChar = ', '#9#10#13#$3000;
  JsonEndChars: PWideChar = ',}]';
  JsonComplexEnd: PWideChar = '}]';
var
  AChild: TQJson;
  AObjEnd, lastP: QCharW;
  AComment: QStringW;
begin
  Result := SkipSpaceAndComment(p, AComment);
  if Result <> 0 then
    Exit;
  if Length(AComment) > 0 then
    FComment := AComment;
  // 解析值
  if (p^ = '{') or (p^ = '[') then // 对象
  begin
    try
      if p^ = '{' then
      begin
        DataType := jdtObject;
        AObjEnd := '}';
      end
      else
      begin
        DataType := jdtArray;
        AObjEnd := ']';
      end;
      Inc(p);
      Result := SkipSpaceAndComment(p, AComment);
      while (p^ <> #0) and (p^ <> AObjEnd) do
      begin
        if (p^ <> AObjEnd) then
        begin
          AChild := Add;
          if Length(AComment) > 0 then
          begin
            AChild.FComment := AComment;
            SetLength(AComment, 0);
          end;
          Result := AChild.ParseJsonPair(ABuilder, p);
          if Result <> 0 then
            Exit;
          if p^ = ',' then
          begin
            lastP := p^;
            Inc(p);
            Result := SkipSpaceAndComment(p, AComment, lastP);
            if Result <> 0 then
              Exit;
          end;
        end
        else
          Exit;
      end;
      Result := SkipSpaceAndComment(p, AComment);
      if Result <> 0 then
        Exit;
      if p^ <> AObjEnd then
      begin
        Result := EParse_BadJson;
        Exit;
      end
      else
      begin
        Inc(p);
        SkipSpaceAndComment(p, AComment);
      end;
    except
      Clear;
      raise;
    end;
  end
  else if Parent <> nil then
  begin
    if (Parent.DataType = jdtObject) and (Length(FName) = 0) then
    begin
      Result := ParseName(ABuilder, p);
      if Result <> 0 then
        Exit;
    end;
    Result := TryParseValue(ABuilder, p);
    if Result = 0 then
    begin
      SkipSpaceAndComment(p, AComment);
      if Length(AComment) > 0 then
        FComment := AComment;
      if not CharInW(p, JsonEndChars) then
      begin
        Result := EParse_EndCharNeeded;
      end;
    end;
  end
  else
    Result := EParse_BadJson;
end;

function TQJson.ParseJsonTime(p: PQCharW; var ATime: TDateTime): Boolean;
var
  MS, TimeZone: Int64;
const
  UnixDelta: Int64 = 25569;
begin
  // Javascript日期格式为/DATE(自1970.1.1起到现在的毫秒数+时区)/
  Result := False;
  if not StartWithW(p, '/DATE', True) then
    Exit;
  Inc(p, 5);
  SkipSpaceW(p);
  if p^ <> '(' then
    Exit;
  Inc(p);
  SkipSpaceW(p);
  if ParseInt(p, MS) = 0 then
    Exit;
  SkipSpaceW(p);
  if (p^ = '+') or (p^ = '-') then
  begin
    if ParseInt(p, TimeZone) = 0 then
      Exit;
    SkipSpaceW(p);
  end
  else
    TimeZone := 0;
  if p^ = ')' then
  begin
    if (MS > 10000000000) or (JsonDatePrecision = jdpMillisecond) then
      ATime := UnixDelta + (MS div 86400000) + ((MS mod 86400000) / 86400000)
    else
      ATime := UnixDelta + (MS div 86400) + ((MS mod 86400) / 86400);
    if TimeZone <> 0 then
      ATime := IncHour(ATime, TimeZone);
    Inc(p);
    SkipSpaceW(p);
    Result := True
  end;
end;

function TQJson.ParseName(ABuilder: TQStringCatHelperW; var p: PQCharW)
  : Integer;
var
  AInQuoter: Boolean;
  AComment: QStringW;
begin
  if StrictJson and (p^ <> '"') then
  begin
    Result := EParse_BadNameStart;
    Exit;
  end;
  AInQuoter := (p^ = '"') or (p^ = '''');
  if not BuildJsonString(ABuilder, p) then
  begin
    Result := EParse_NameNotFound;
    Exit;
  end;
  SkipSpaceAndComment(p, AComment);
  if p^ <> ':' then
  begin
    Result := EParse_BadNameEnd;
    Exit;
  end;
  if not AInQuoter then
    ABuilder.TrimRight;
  FName := ABuilder.Value;

  // 解析名称完成
  Inc(p);
  SkipSpaceAndComment(p, AComment);
  Result := 0;
end;

procedure TQJson.ParseObject(var p: PQCharW);
var
  ABuilder: TQStringCatHelperW;
  ps: PQCharW;
  AErrorCode: Integer;
  AComment: QStringW;
begin
  ABuilder := TQStringCatHelperW.Create;
  try
    ps := p;
    try
      SkipSpaceAndComment(p, AComment);
      if Length(AComment) > 0 then
        FComment := AComment;
      AErrorCode := ParseJsonPair(ABuilder, p);
      if AErrorCode <> 0 then
        RaiseParseException(AErrorCode, ps, p);
    except
      on E: Exception do
      begin
        if E is EJsonError then
          raise
        else
        begin
          raise FormatParseErrorEx(EParse_Unknown, E.Message, ps, p);

          { raise Exception.Create(Self.FormatParseError(EParse_Unknown,
            E.Message, ps, p)); }
        end;
      end;
    end;
  finally
    FreeObject(ABuilder);
    DoParsed;
  end;
end;

procedure TQJson.ParseValue(ABuilder: TQStringCatHelperW; var p: PQCharW);
var
  ps: PQCharW;
begin
  ps := p;
  RaiseParseException(TryParseValue(ABuilder, p), ps, p);
end;

procedure TQJson.RaiseParseException(ACode: Integer; ps, p: PQCharW);
begin
  if ACode <> 0 then
  begin
    case ACode of
      EParse_BadStringStart:
        { raise EJsonError.Create(FormatParseError(ACode,
          SBadStringStart, ps, p)); }
        raise FormatParseErrorEx(ACode, SBadStringStart, ps, p);
      EParse_BadJson:
        // raise EJsonError.Create(FormatParseError(ACode, SBadJson, ps, p));
        raise FormatParseErrorEx(ACode, SBadJson, ps, p);
      EParse_CommentNotSupport:
        { raise EJsonError.Create(FormatParseError(ACode,
          SCommentNotSupport, ps, p)); }
        raise FormatParseErrorEx(ACode, SCommentNotSupport, ps, p);
      EParse_UnknownToken:
        { raise EJsonError.Create(FormatParseError(ACode,
          SCommentNotSupport, ps, p)); }
        raise FormatParseErrorEx(ACode, SCommentNotSupport, ps, p);
      EParse_EndCharNeeded:
        // raise EJsonError.Create(FormatParseError(ACode, SEndCharNeeded, ps, p));
        raise FormatParseErrorEx(ACode, SEndCharNeeded, ps, p);
      EParse_BadNameStart:
        // raise EJsonError.Create(FormatParseError(ACode, SBadNameStart, ps, p));
        raise FormatParseErrorEx(ACode, SBadNameStart, ps, p);
      EParse_BadNameEnd:
        // raise EJsonError.Create(FormatParseError(ACode, SBadNameEnd, ps, p));
        raise FormatParseErrorEx(ACode, SBadNameEnd, ps, p);
      EParse_NameNotFound:
        // raise EJsonError.Create(FormatParseError(ACode, SNameNotFound, ps, p))
        raise FormatParseErrorEx(ACode, SNameNotFound, ps, p);
    else
      raise FormatParseErrorEx(ACode, SUnknownError, ps, p);
      // raise EJsonError.Create(FormatParseError(ACode, SUnknownError, ps, p));
    end;
  end;
end;

function TQJson.Remove(AItemIndex: Integer): TQJson;
begin
  if FDataType in [jdtArray, jdtObject] then
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

procedure TQJson.Remove(AJson: TQJson);
begin
  Remove(AJson.ItemIndex);
end;

procedure TQJson.Replace(AIndex: Integer; ANewItem: TQJson);
begin
  FreeObject(Items[AIndex]);
  if Assigned(ANewItem.FParent) then
    ANewItem.FParent.Remove(ANewItem.ItemIndex);
  ANewItem.FParent := Self;
  FItems[AIndex] := ANewItem;
end;

procedure TQJson.Reset(ADetach: Boolean);
begin
  if ADetach and Assigned(FParent) then
  begin
    FParent.Remove(Self);
    FParent := nil;
  end;
  SetLength(FName, 0);
  FNameHash := 0;
  DataType := jdtUnknown;
  SetLength(FValue, 0);
  SetLength(FComment, 0);
  FCommentStyle := jcsIgnore;
  FData := nil;
  FIgnoreCase := not JsonCaseSensitive;
end;

procedure TQJson.ResetNull;
var
  ALastType: TQJsonDataType;
  V: String;
begin
  DataType := jdtNull;
end;

procedure TQJson.RevertOrder(ANest: Boolean);
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

procedure TQJson.SaveToFile(const AFileName: String; AEncoding: TTextEncoding;
  AWriteBom, ADoFormat: Boolean);
var
  AStream: TMemoryStream;
begin
  AStream := TMemoryStream.Create;
  try
    SaveToStream(AStream, AEncoding, AWriteBom, ADoFormat);
    AStream.SaveToFile(AFileName);
  finally
    FreeObject(AStream);
  end;
end;

procedure TQJson.SaveToStream(AStream: TStream; AEncoding: TTextEncoding;
  AWriteBom, ADoFormat: Boolean);
var
  S: QStringW;
begin
  if DataType in [jdtArray, jdtObject] then
    S := Encode(ADoFormat)
  else
  begin
    if DataType in [jdtUnknown, jdtNull] then
    begin
      if Length(FName) = 0 then
        S := ''
      else
        S := '{"' + Escape(FName) + '":' + Value + '}';
    end
    else
    begin
      if Length(FName) > 0 then
        S := '{"' + Escape(FName) + '":' + Encode(True) + '}'
      else
        raise Exception.Create(SNameNotFound);
    end;
  end;
  if AEncoding = teUtf8 then
    SaveTextU(AStream, qstring.Utf8Encode(S), AWriteBom)
  else if AEncoding = teAnsi then
    SaveTextA(AStream, qstring.AnsiEncode(S))
  else if AEncoding = teUnicode16LE then
    SaveTextW(AStream, S, AWriteBom)
  else
    SaveTextWBE(AStream, S, AWriteBom);
end;

procedure TQJson.SetA(const APath: String; const Value: TQJson);
begin
  ForcePath(APath).Assign(Value);
end;

procedure TQJson.SetAsArray(const Value: QStringW);
var
  p: PQCharW;
begin
  DataType := jdtArray;
  Clear;
  p := PQCharW(Value);
  ParseObject(p);
end;

procedure TQJson.SetAsBase64Bytes(const Value: TBytes);
begin
  InternalSetAsBytes(DoEncodeAsBase64, Value);
end;

procedure TQJson.SetAsBoolean(const Value: Boolean);
begin
  DataType := jdtBoolean;
  PBoolean(FValue)^ := Value;
end;

procedure TQJson.SetAsBytes(const Value: TBytes);
begin
  if Assigned(OnQJsonEncodeBytes) then
    InternalSetAsBytes(OnQJsonEncodeBytes, Value)
  else
    InternalSetAsBytes(DoEncodeAsHex, Value);
end;

procedure TQJson.SetAsDateTime(const Value: TDateTime);
begin
  DataType := jdtDateTime;
  PExtended(FValue)^ := Value;
end;

procedure TQJson.SetAsFloat(const Value: Extended);
begin
  if IsNan(Value) or IsInfinite(Value) then
    raise Exception.Create(SSupportFloat);
  DataType := jdtFloat;
  PExtended(FValue)^ := Value;
end;

procedure TQJson.SetAsHexBytes(const Value: TBytes);
begin
  InternalSetAsBytes(DoEncodeAsHex, Value);
end;

procedure TQJson.SetAsInt64(const Value: Int64);
begin
  DataType := jdtInteger;
  PInt64(FValue)^ := Value;
end;

procedure TQJson.SetAsInteger(const Value: Integer);
begin
  SetAsInt64(Value);
end;

procedure TQJson.SetAsJson(const Value: QStringW);
var
  ABuilder: TQStringCatHelperW;
  p: PQCharW;
begin
  ABuilder := TQStringCatHelperW.Create;
  try
    try
      if DataType in [jdtArray, jdtObject] then
        Clear;
      p := PQCharW(Value);
      ParseValue(ABuilder, p);
    except
      AsString := Value;
    end;
  finally
    FreeObject(ABuilder);
  end;
end;

procedure TQJson.SetAsObject(const Value: QStringW);
begin
  Parse(PQCharW(Value), Length(Value));
end;

procedure TQJson.SetAsString(const Value: QStringW);
begin
  DataType := jdtString;
  FValue := Value;
end;

procedure TQJson.SetAsVariant(const Value: Variant);
var
  I: Integer;
  AType: TVarType;
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
  if VarIsArray(Value) then
  begin
    ArrayNeeded(jdtArray);
    Clear;
    for I := VarArrayLowBound(Value, VarArrayDimCount(Value))
      to VarArrayHighBound(Value, VarArrayDimCount(Value)) do
      Add.AsVariant := Value[I];
  end
  else
  begin
    AType := VarType(Value);
    case AType of
      varEmpty, varNull, varUnknown:
        ResetNull;
      varSmallInt, varInteger, varByte, varShortInt, varWord,
        varLongWord, varInt64:
        AsInt64 := Value;
      varSingle, varDouble, varCurrency:
        AsFloat := Value;
      varDate:
        AsDateTime := Value;
      varOleStr, varString{$IFDEF UNICODE}, varUString{$ENDIF}:
        AsString := Value;
{$IF RtlVersion>=26}
      varUInt64:
        AsInt64 := Value;
      varRecord:
        FromRtti(PVarRecord(@Value).RecInfo, PVarRecord(@Value).PRecord);
{$IFEND >=XE5}
      varBoolean:
        AsBoolean := Value
    else
      CastFromCustomVarType;
    end;
  end;
end;

procedure TQJson.SetB(const APath: String; const Value: Boolean);
begin
  ForcePath(APath).AsBoolean := Value;
end;

procedure TQJson.SetDataType(const Value: TQJsonDataType);
begin
  if FDataType <> Value then
  begin
    if DataType in [jdtArray, jdtObject] then
    begin
      Clear;
      if not(Value in [jdtArray, jdtObject]) then
      begin
        FreeObject(FItems);
      end;
    end;
    case Value of
      jdtNull, jdtUnknown, jdtString:
        SetLength(FValue, 0);
      jdtInteger:
        begin
          SetLength(FValue, SizeOf(Int64) shr 1);
          PInt64(FValue)^ := 0;
        end;
      jdtFloat, jdtDateTime:
        begin
          SetLength(FValue, SizeOf(Extended) shr 1);
          PExtended(FValue)^ := 0;
        end;
      jdtBoolean:
        begin
          SetLength(FValue, 1);
          PBoolean(FValue)^ := False;
        end;
      jdtArray, jdtObject:
        if not(FDataType in [jdtArray, jdtObject]) then
          ArrayNeeded(Value);
    end;
    FDataType := Value;
  end;
end;

procedure TQJson.SetF(const APath: String; const Value: Double);
begin
  ForcePath(APath).AsFloat := Value;
end;

procedure TQJson.SetI(const APath: String; const Value: Int64);
begin
  ForcePath(APath).AsInt64 := Value;
end;

procedure TQJson.SetIgnoreCase(const Value: Boolean);
  procedure InternalSetIgnoreCase(AParent: TQJson);
  var
    I: Integer;
  begin
    AParent.FIgnoreCase := Value;
    if AParent.FNameHash <> 0 then
      AParent.FNameHash := AParent.HashName(AParent.FName);
    if AParent.DataType in [jdtArray, jdtObject] then
    begin
      for I := 0 to AParent.Count - 1 do
        InternalSetIgnoreCase(AParent[I]);
    end;
  end;

begin
  if FIgnoreCase <> Value then
  begin
    InternalSetIgnoreCase(Root);
  end;
end;

procedure TQJson.SetName(const Value: QStringW);
begin
  if FName <> Value then
  begin
    if Assigned(FParent) then
    begin
      if FParent.IndexOf(Value) <> -1 then
        raise Exception.CreateFmt(SNodeNameExists, [Value]);
    end;
    FName := Value;
    FNameHash := 0;
    DoJsonNameChanged(Self);
  end;
end;

procedure TQJson.SetO(const APath: String; const Value: TQJson);
begin
  ForcePath(APath).Assign(Value);
end;

procedure TQJson.SetS(const APath, Value: String);
begin
  ForcePath(APath).AsString := Value;
end;

procedure TQJson.SetT(const APath: String; const Value: TDateTime);
begin
  ForcePath(APath).AsDateTime := Value;
end;

procedure TQJson.SetV(const APath: String; const Value: Variant);
begin
  ForcePath(APath).AsVariant := Value;
end;

procedure TQJson.SetValue(const Value: QStringW);
var
  p: PQCharW;
  procedure ParseNum;
  var
    ANum: Extended;
  begin
    if ParseNumeric(p, ANum) then
    begin
      if SameValue(ANum, Trunc(ANum), 5E-324) then
        AsInt64 := Trunc(ANum)
      else
        AsFloat := ANum;
    end
    else
      raise Exception.Create(Format(SBadNumeric, [Value]));
  end;
  procedure SetDateTime;
  var
    ATime: TDateTime;
  begin
    if ParseDateTime(PQCharW(Value), ATime) then
      AsDateTime := ATime
    else if ParseJsonTime(PQCharW(Value), ATime) then
      AsDateTime := ATime
    else
      raise Exception.Create(SBadJsonTime);
  end;
  procedure DetectValue;
  var
    ABuilder: TQStringCatHelperW;
    p: PQCharW;
  begin
    ABuilder := TQStringCatHelperW.Create;
    try
      p := PQCharW(Value);
      if TryParseValue(ABuilder, p) <> 0 then
        AsString := Value;
    finally
      FreeObject(ABuilder);
    end;
  end;

begin
  if DataType = jdtString then
    FValue := Value
  else if DataType = jdtBoolean then
    AsBoolean := StrToBool(Value)
  else
  begin
    p := PQCharW(Value);
    if DataType in [jdtInteger, jdtFloat] then
      ParseNum
    else if DataType = jdtDateTime then
      SetDateTime
    else if DataType in [jdtArray, jdtObject] then
    begin
      Clear;
      ParseObject(p);
    end
    else // jdtUnknown
      DetectValue;
  end;
end;

class function TQJson.SkipSpaceAndComment(var p: PQCharW;
  var AComment: QStringW; lastvalidchar: Char = #0): Integer;
var
  ps: PQCharW;
begin
  SkipSpaceW(p);
  Result := 0;
  SetLength(AComment, 0);
  if not StrictJson then
  begin
    while p^ = '/' do
    begin
      if StrictJson then
      begin
        Result := EParse_CommentNotSupport;
        Exit;
      end;
      if p[1] = '/' then
      begin
        Inc(p, 2);
        AComment := DecodeLineW(p) + SLineBreak;
        SkipSpaceW(p);
      end
      else if p[1] = '*' then
      begin
        Inc(p, 2);
        ps := p;
        while p^ <> #0 do
        begin
          if (p[0] = '*') and (p[1] = '/') then
          begin
            AComment := AComment + StrDupX(ps, (IntPtr(p) - IntPtr(ps)) shr 1) +
              SLineBreak;
            Inc(p, 2);
            SkipSpaceW(p);
            Break;
          end
          else
            Inc(p);
        end;
      end
      else
      begin
        Result := EParse_UnknownToken;
        Exit;
      end;
    end;
  end
  else if ((p^ = CharObjectEnd) or (p^ = CharArrayEnd)) and
    (lastvalidchar = CharComma) then
  begin
    Result := EParse_EndCharNeeded;
    Exit;
  end;
  if Length(AComment) > 0 then
    SetLength(AComment, Length(AComment) - Length(SLineBreak));
end;

procedure TQJson.Sort(AByName, ANest: Boolean; AByType: TQJsonDataType;
  AOnCompare: TListSortCompareEvent);
  function DoCompare(Item1, Item2: Pointer): Integer;
  var
    AMethod: TMethod absolute AOnCompare;
  begin
    if AMethod.Data = nil then
      Result := TListSortCompare(AMethod.Code)(Item1, Item2)
{$IFDEF UNICODE}
    else if AMethod.Data = Pointer(-1) then
      Result := TListSortCompareFunc(AMethod.Code)(Item1, Item2)
{$ENDIF}
    else
      Result := AOnCompare(Item1, Item2);
  end;
  procedure QuickSort(l, R: Integer);
  var
    I, J, p: Integer;
  begin
    repeat
      I := l;
      J := R;
      p := (l + R) shr 1;
      repeat
        while DoCompare(Items[I], Items[p]) < 0 do
          Inc(I);
        while DoCompare(Items[J], Items[p]) > 0 do
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
        QuickSort(l, J);
      l := I;
    until I >= R;
  end;
  function DetectCompareType: TQJsonDataType;
  var
    I, c: Integer;
  begin
    c := Count;
    if c > 0 then
    begin
      Result := Items[0].DataType;
      Dec(c);
      for I := 1 to c do
      begin
        case Items[I].DataType of
          jdtNull:
            ;
          jdtString:
            begin
              Result := jdtString;
              Break;
            end;
          jdtInteger:
            begin
              if Result in [jdtNull, jdtBoolean] then
                Result := jdtInteger;
            end;
          jdtFloat:
            begin
              if Result in [jdtNull, jdtBoolean, jdtInteger, jdtDateTime] then
                Result := jdtFloat;
            end;
          jdtBoolean:
            begin
              if Result = jdtNull then
                Result := jdtBoolean;
            end;
          jdtDateTime:
            begin
              if Result in [jdtNull, jdtBoolean, jdtInteger] then
                Result := jdtDateTime;
            end;
        end;
      end;
    end
    else
      Result := jdtUnknown;
  end;
  procedure DoSort(ADataType: TQJsonDataType);
  begin
    case ADataType of
      jdtString:
        AOnCompare := DoCompareValueString;
      jdtInteger:
        AOnCompare := DoCompareValueInt;
      jdtFloat:
        AOnCompare := DoCompareValueFloat;
      jdtBoolean:
        AOnCompare := DoCompareValueBoolean;
      jdtDateTime:
        AOnCompare := DoCompareValueDateTime
    else
      Exit;
    end;
    QuickSort(0, Count - 1);
  end;
  procedure SortChildrens;
  var
    I, H: Integer;
    AItem: TQJson;
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
  if Count > 0 then
  begin
    if not Assigned(AOnCompare) then
    begin
      if AByName then
      begin
        AOnCompare := DoCompareName;
        QuickSort(0, Count - 1);
      end
      else if AByType = jdtUnknown then
        DoSort(DetectCompareType)
      else
        DoSort(AByType);
    end
    else
      QuickSort(0, Count - 1);
    if ANest then
      SortChildrens;
  end;
end;

procedure TQJson.Sort(AByName, ANest: Boolean; AByType: TQJsonDataType;
  AOnCompare: TListSortCompare);
var
  AEvent: TListSortCompareEvent;
  AMethod: TMethod absolute AEvent;
begin
  AEvent := nil;
  TListSortCompare(AMethod.Code) := AOnCompare;
  Sort(AByName, ANest, AByType, AEvent);
end;
{$IF RTLVersion>=21)}

procedure TQJson.Sort(AByName, ANest: Boolean; AByType: TQJsonDataType;
  AOnCompare: TListSortCompareFunc);
var
  AEvent: TListSortCompareEvent;
  AMethod: TMethod absolute AEvent;
begin
  AEvent := nil;
  AMethod.Data := Pointer(-1);
  TListSortCompareFunc(AMethod.Code) := AOnCompare;
  Sort(AByName, ANest, AByType, AEvent);
end;
{$IFEND}

procedure TQJson.StreamFromValue(AStream: TStream);
var
  ABytes: TBytes;
begin
  ABytes := AsBytes;
  AStream.WriteBuffer(ABytes[0], Length(ABytes));
end;

{$IF RTLVersion>=21}

function TQJson.Invoke(AInstance: TValue): TValue;
var
  AMethods: TArray<TRttiMethod>;
  AParams: TArray<TRttiParameter>;
  AMethod: TRttiMethod;
  AType: TRttiType;
  AContext: TRttiContext;
  AParamValues: array of TValue;
  I, c: Integer;
  AParamItem, AItemType, AItemValue: TQJson;
  function CharOfValue: Byte;
  var
    S: QStringA;
  begin
    S := AItemValue.AsString;
    if S.Length > 0 then
      Result := S.Chars[0]
    else
      Result := 0;
  end;
  function WCharOfValue: WideChar;
  var
    S: QStringW;
  begin
    S := AItemValue.AsString;
    if Length(S) > 0 then
      Result := PQCharW(S)[0]
    else
      Result := #0;
  end;

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
  c := Count;
  for AMethod in AMethods do
  begin
    AParams := AMethod.GetParameters;
    if Length(AParams) = c then
    begin
      SetLength(AParamValues, c);
      for I := 0 to c - 1 do
      begin
        AParamItem := ItemByName(AParams[I].Name);
        if AParamItem <> nil then
        begin
          if AParamItem.IsObject then // 参数有类型修饰信息
          begin
            if AParamItem.HasChild('Type', AItemType) and
              AParamItem.HasChild('Value', AItemValue) then
            begin
              case TTypeKind(AItemType.AsInteger) of
                tkInteger:
                  AParamValues[I] := AItemValue.AsInteger;
                tkChar:
                  AParamValues[I] :=
{$IFNDEF NEXTGEN}AnsiChar(CharOfValue){$ELSE}CharOfValue{$ENDIF};
                tkEnumeration:
                  AParamValues[I] := AItemValue.AsInteger;
                tkFloat:
                  AParamValues[I] := AItemValue.AsFloat;
                tkString:
                  AParamValues[I] := AItemValue.AsString;
                tkWChar:
                  AParamValues[I] := WCharOfValue;
{$IFNDEF NEXTGEN}
                tkLString:
                  AParamValues[I] := AnsiString(AItemValue.AsString);
{$ENDIF}
                tkWString:
                  AParamValues[I] := WideString(AItemValue.AsString);
{$IFDEF UNICODE}
                tkUString:
                  AParamValues[I] := AItemValue.AsString;
{$ENDIF}
                tkPointer:
                  AParamValues[I] := Pointer(AItemValue.AsInt64);
                tkClassRef:
                  AParamValues[I] := TClass(AItemValue.AsInt64);
                tkClass:
                  AParamValues[I] := TObject(AItemValue.AsInt64)
              else
                raise Exception.CreateFmt(SParamMissed, [AParams[I].Name]);
              end;
            end
            else if AParamItem.HasChild('Value', AItemValue) then
              AParamValues[I] := AItemValue.ToRttiValue
            else
              raise Exception.CreateFmt(SParamMissed, [AParams[I].Name]);
          end
          else
            AParamValues[I] := AParamItem.ToRttiValue
        end
        else
          raise Exception.CreateFmt(SParamMissed, [AParams[I].Name]);
      end;
      Result := AMethod.Invoke(AInstance, AParamValues);
      Exit;
    end;
  end;
  raise Exception.CreateFmt(SMethodMissed, [Name]);
end;

procedure TQJson.ToRecord<T>(var ARecord: T; AClearCollections: Boolean);
begin
  ToRtti(@ARecord, TypeInfo(T), AClearCollections);
end;

procedure TQJson.ToRtti(AInstance: TValue; AClearCollections: Boolean);
begin
  if AInstance.IsEmpty then
    Exit;
  if AInstance.Kind = tkRecord then
    ToRtti(AInstance.GetReferenceToRawData, AInstance.TypeInfo,
      AClearCollections)
  else if AInstance.Kind = tkClass then
    ToRtti(AInstance.AsObject, AInstance.TypeInfo, AClearCollections)
end;

procedure TQJson.ToRtti(ADest: Pointer; AType: PTypeInfo;
  AClearCollections: Boolean);

  procedure LoadCollection(AJson: TQJson; ACollection: TCollection);
  var
    I: Integer;
  begin
    if AClearCollections then
      ACollection.Clear;
    for I := 0 to AJson.Count - 1 do
      AJson[I].ToRtti(ACollection.Add);
  end;
  procedure ToRecord;
  var
    AContext: TRttiContext;
    AFields: TArray<TRttiField>;
    ARttiType: TRttiType;
    ABaseAddr: Pointer;
    J: Integer;
    AChild: TQJson;
    AObj: TObject;
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
                        if AChild.DataType = jdtInteger then
                          PShortint(IntPtr(ABaseAddr) + AFields[J].Offset)^ :=
                            AChild.AsInteger
                        else
                          PShortint(IntPtr(ABaseAddr) + AFields[J].Offset)^ :=
                            GetEnumValue(AFields[J].FieldType.Handle,
                            AChild.AsString);
                      end;
                    otUByte:
                      begin
                        if AChild.DataType = jdtInteger then
                          PByte(IntPtr(ABaseAddr) + AFields[J].Offset)^ :=
                            AChild.AsInteger
                        else
                          PByte(IntPtr(ABaseAddr) + AFields[J].Offset)^ :=
                            GetEnumValue(AFields[J].FieldType.Handle,
                            AChild.AsString);
                      end;
                    otSWord:
                      begin
                        if AChild.DataType = jdtInteger then
                          PSmallint(IntPtr(ABaseAddr) + AFields[J].Offset)^ :=
                            AChild.AsInteger
                        else
                          PSmallint(IntPtr(ABaseAddr) + AFields[J].Offset)^ :=
                            GetEnumValue(AFields[J].FieldType.Handle,
                            AChild.AsString);
                      end;
                    otUWord:
                      begin
                        if AChild.DataType = jdtInteger then
                          PWord(IntPtr(ABaseAddr) + AFields[J].Offset)^ :=
                            AChild.AsInteger
                        else
                          PWord(IntPtr(ABaseAddr) + AFields[J].Offset)^ :=
                            GetEnumValue(AFields[J].FieldType.Handle,
                            AChild.AsString);
                      end;
                    otSLong:
                      begin
                        if AChild.DataType = jdtInteger then
                          PInteger(IntPtr(ABaseAddr) + AFields[J].Offset)^ :=
                            AChild.AsInteger
                        else
                          PInteger(IntPtr(ABaseAddr) + AFields[J].Offset)^ :=
                            GetEnumValue(AFields[J].FieldType.Handle,
                            AChild.AsString);
                      end;
                    otULong:
                      begin
                        if AChild.DataType = jdtInteger then
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
                      if AChild.DataType = jdtInteger then
                        PShortint(IntPtr(ABaseAddr) + AFields[J].Offset)^ :=
                          AChild.AsInteger
                      else
                        PShortint(IntPtr(ABaseAddr) + AFields[J].Offset)^ :=
                          StringToSet(AFields[J].FieldType.Handle,
                          AChild.AsString);
                    end;
                  otUByte:
                    begin
                      if AChild.DataType = jdtInteger then
                        PByte(IntPtr(ABaseAddr) + AFields[J].Offset)^ :=
                          AChild.AsInteger
                      else
                        PByte(IntPtr(ABaseAddr) + AFields[J].Offset)^ :=
                          StringToSet(AFields[J].FieldType.Handle,
                          AChild.AsString);
                    end;
                  otSWord:
                    begin
                      if AChild.DataType = jdtInteger then
                        PSmallint(IntPtr(ABaseAddr) + AFields[J].Offset)^ :=
                          AChild.AsInteger
                      else
                        PSmallint(IntPtr(ABaseAddr) + AFields[J].Offset)^ :=
                          StringToSet(AFields[J].FieldType.Handle,
                          AChild.AsString);
                    end;
                  otUWord:
                    begin
                      if AChild.DataType = jdtInteger then
                        PWord(IntPtr(ABaseAddr) + AFields[J].Offset)^ :=
                          AChild.AsInteger
                      else
                        PWord(IntPtr(ABaseAddr) + AFields[J].Offset)^ :=
                          StringToSet(AFields[J].FieldType.Handle,
                          AChild.AsString);
                    end;
                  otSLong:
                    begin
                      if AChild.DataType = jdtInteger then
                        PInteger(IntPtr(ABaseAddr) + AFields[J].Offset)^ :=
                          AChild.AsInteger
                      else
                        PInteger(IntPtr(ABaseAddr) + AFields[J].Offset)^ :=
                          StringToSet(AFields[J].FieldType.Handle,
                          AChild.AsString);
                    end;
                  otULong:
                    begin
                      if AChild.DataType = jdtInteger then
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
              if (AFields[J].FieldType.Handle = TypeInfo(TDateTime)) or
                (AFields[J].FieldType.Handle = TypeInfo(TTime)) or
                (AFields[J].FieldType.Handle = TypeInfo(TDate)) then
              begin
                if AChild.IsDateTime then
                  AFields[J].SetValue(ABaseAddr, AChild.AsDateTime)
                else if AChild.DataType in [jdtNull, jdtUnknown] then
                  AFields[J].SetValue(ABaseAddr, 0)
                else
                begin
                  if AChild.DataType = jdtInteger then // 整数？Unix 时间戳？
                  begin
                    case JsonIntToTimeStyle of
                      tsDeny:
                        raise Exception.CreateFmt(SBadConvert,
                          [AChild.AsString, JsonTypeName[jdtDateTime]]);
                      tsSecondsFrom1970: // Unix
                        begin
                          if (JsonTimezone >= -12) and (JsonTimezone <= 12) then
                            AFields[J].SetValue(ABaseAddr,
                              IncHour(UnixToDateTime(AChild.AsInt64),
                              JsonTimezone))
                          else
                            AFields[J].SetValue(ABaseAddr,
                              UnixToDateTime(AChild.AsInt64));
                        end;
                      tsSecondsFrom1899:
                        begin
                          if (JsonTimezone >= -12) and (JsonTimezone <= 12) then
                            AFields[J].SetValue(ABaseAddr,
                              IncHour(AChild.AsInt64 / 86400, JsonTimezone))
                          else
                            AFields[J].SetValue(ABaseAddr,
                              AChild.AsInt64 / 86400);
                        end;
                      tsMsFrom1970:
                        begin
                          if (JsonTimezone >= -12) and (JsonTimezone <= 12) then
                            AFields[J].SetValue(ABaseAddr,
                              IncHour(IncMilliSecond(UnixDateDelta,
                              AChild.AsInt64), JsonTimezone))
                          else
                            AFields[J].SetValue(ABaseAddr,
                              IncMilliSecond(UnixDateDelta, AChild.AsInt64));
                        end;
                      tsMsFrom1899:
                        if (JsonTimezone >= -12) and (JsonTimezone <= 12) then
                          AFields[J].SetValue(ABaseAddr,
                            IncHour(AChild.AsInt64 / 86400000, JsonTimezone))
                        else
                          AFields[J].SetValue(ABaseAddr,
                            AChild.AsInt64 / 86400000);
                    end;
                  end
                  else
                    raise Exception.CreateFmt(SBadConvert,
                      [AChild.AsString, JsonTypeName[AChild.DataType]]);
                end;
              end
              else
                AFields[J].SetValue(ABaseAddr, AChild.AsFloat);
            tkInt64:
              AFields[J].SetValue(ABaseAddr, AChild.AsInt64);
            tkVariant:
              PVariant(IntPtr(ABaseAddr) + AFields[J].Offset)^ :=
                AChild.AsVariant;
            tkArray, tkDynArray:
              AChild.ToRtti(Pointer(IntPtr(ABaseAddr) + AFields[J].Offset),
                AFields[J].FieldType.Handle);
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

  procedure ToObject;
  var
    AProp: PPropInfo;
    ACount: Integer;
    J, V: Integer;
    AObj, AChildObj: TObject;
    AChild: TQJson;
    AIdentToInt: TIdentToInt;
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
              begin
                if AChild.DataType = jdtString then
                begin
                  AIdentToInt := FindIdentToInt(AProp.PropType^);
                  if Assigned(AIdentToInt) then
                  begin
                    if AIdentToInt(AChild.AsString, V) then
                      SetOrdProp(AObj, AProp, V);
                  end;
                end
                else
                  SetOrdProp(AObj, AProp, AChild.AsInteger);
              end;
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
                else if AChild.DataType = jdtInteger then
                  SetOrdProp(AObj, AProp, AChild.AsInteger)
                else
                  SetEnumProp(AObj, AProp, AChild.AsString);
              end;
            tkSet:
              begin
                if AChild.DataType = jdtInteger then
                  SetOrdProp(AObj, AProp, AChild.AsInteger)
                else
                  SetSetProp(AObj, AProp, AChild.AsString);
              end;
            tkVariant:
              SetVariantProp(AObj, AProp, AChild.AsVariant);
            tkInt64:
              SetInt64Prop(AObj, AProp, AChild.AsInt64);
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

  procedure ToArray;
  var
    AContext: TRttiContext;
    ASubType: TRttiType;
    I, l, AOffset: Integer;
    S: QStringW;
    pd, pi: PByte;
    AChildObj: TObject;
    ASubTypeInfo: PTypeInfo;
    AChild: TQJson;
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
        case ASubType.TypeKind of
          tkInteger:
            begin
              case GetTypeData(ASubTypeInfo).OrdType of
                otSByte:
                  PShortint(pi)^ := AChild.AsInteger;
                otUByte:
                  pi^ := Items[I].AsInteger;
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
              if GetTypeData(ASubTypeInfo)^.BaseType^ = TypeInfo(Boolean) then
                PBoolean(pi)^ := AChild.AsBoolean
              else
              begin
                case GetTypeData(ASubTypeInfo)^.OrdType of
                  otSByte:
                    begin
                      if AChild.DataType = jdtInteger then
                        PShortint(pi)^ := AChild.AsInteger
                      else
                        PShortint(pi)^ := GetEnumValue(ASubTypeInfo,
                          AChild.AsString);
                    end;
                  otUByte:
                    begin
                      if AChild.DataType = jdtInteger then
                        pi^ := AChild.AsInteger
                      else
                        pi^ := GetEnumValue(ASubTypeInfo, AChild.AsString);
                    end;
                  otSWord:
                    begin
                      if AChild.DataType = jdtInteger then
                        PSmallint(pi)^ := AChild.AsInteger
                      else
                        PSmallint(pi)^ := GetEnumValue(ASubTypeInfo,
                          AChild.AsString);
                    end;
                  otUWord:
                    begin
                      if AChild.DataType = jdtInteger then
                        PWord(pi)^ := AChild.AsInteger
                      else
                        PWord(pi)^ := GetEnumValue(ASubTypeInfo,
                          AChild.AsString);
                    end;
                  otSLong:
                    begin
                      if AChild.DataType = jdtInteger then
                        PInteger(pi)^ := AChild.AsInteger
                      else
                        PInteger(pi)^ := GetEnumValue(ASubTypeInfo,
                          AChild.AsString);
                    end;
                  otULong:
                    begin
                      if AChild.DataType = jdtInteger then
                        PCardinal(pi)^ := AChild.AsInteger
                      else
                        PCardinal(pi)^ := GetEnumValue(ASubTypeInfo,
                          Items[I].AsString);
                    end;
                end;
              end;
            end;
          tkFloat:
            case GetTypeData(ASubTypeInfo)^.FloatType of
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
              case GetTypeData(ASubTypeInfo)^.OrdType of
                otSByte:
                  begin
                    if AChild.DataType = jdtInteger then
                      PShortint(pi)^ := AChild.AsInteger
                    else
                      PShortint(pi)^ := StringToSet(ASubTypeInfo,
                        AChild.AsString);
                  end;
                otUByte:
                  begin
                    if AChild.DataType = jdtInteger then
                      pi^ := AChild.AsInteger
                    else
                      pi^ := StringToSet(ASubTypeInfo, AChild.AsString);
                  end;
                otSWord:
                  begin
                    if AChild.DataType = jdtInteger then
                      PSmallint(pi)^ := AChild.AsInteger
                    else
                      PSmallint(pi)^ := StringToSet(ASubTypeInfo,
                        AChild.AsString);
                  end;
                otUWord:
                  begin
                    if AChild.DataType = jdtInteger then
                      PWord(pi)^ := AChild.AsInteger
                    else
                      PWord(pi)^ := StringToSet(ASubTypeInfo, AChild.AsString);
                  end;
                otSLong:
                  begin
                    if AChild.DataType = jdtInteger then
                      PInteger(pi)^ := AChild.AsInteger
                    else
                      PInteger(pi)^ := StringToSet(ASubTypeInfo,
                        AChild.AsString);
                  end;
                otULong:
                  begin
                    if AChild.DataType = jdtInteger then
                      PCardinal(pi)^ := AChild.AsInteger
                    else
                      PCardinal(pi)^ := StringToSet(ASubTypeInfo,
                        Items[I].AsString);
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
            Items[I].ToRtti(pi, ASubTypeInfo);
          tkRecord:
            Items[I].ToRtti(pi, ASubTypeInfo);
          tkInt64:
            PInt64(pi)^ := Items[I].AsInt64;
          tkUString:
            PUnicodeString(pi)^ := Items[I].AsString;
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
    I, c, ASize: Integer;
    ASubType: PTypeInfo;
    AChild: TQJson;
    AChildObj: TObject;
    pi: Pointer;
  begin
    c := Min(GetTypeData(AType).ArrayData.ElCount, Count);
    ASubType := GetFixedArrayItemType;
    if ASubType = nil then
      Exit;
    ASize := GetTypeData(ASubType).elSize;
    for I := 0 to c - 1 do
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
                    if AChild.DataType = jdtInteger then
                      PShortint(pi)^ := AChild.AsInteger
                    else
                      PShortint(pi)^ := GetEnumValue(ASubType, AChild.AsString);
                  end;
                otUByte:
                  begin
                    if AChild.DataType = jdtInteger then
                      PByte(pi)^ := AChild.AsInteger
                    else
                      PByte(pi)^ := GetEnumValue(ASubType, AChild.AsString);
                  end;
                otSWord:
                  begin
                    if AChild.DataType = jdtInteger then
                      PSmallint(pi)^ := AChild.AsInteger
                    else
                      PSmallint(pi)^ := GetEnumValue(ASubType, AChild.AsString);
                  end;
                otUWord:
                  begin
                    if AChild.DataType = jdtInteger then
                      PWord(pi)^ := AChild.AsInteger
                    else
                      PWord(pi)^ := GetEnumValue(ASubType, AChild.AsString);
                  end;
                otSLong:
                  begin
                    if AChild.DataType = jdtInteger then
                      PInteger(pi)^ := AChild.AsInteger
                    else
                      PInteger(pi)^ := GetEnumValue(ASubType, AChild.AsString);
                  end;
                otULong:
                  begin
                    if AChild.DataType = jdtInteger then
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
                  if AChild.DataType = jdtInteger then
                    PShortint(pi)^ := AChild.AsInteger
                  else
                    PShortint(pi)^ := StringToSet(ASubType, AChild.AsString);
                end;
              otUByte:
                begin
                  if AChild.DataType = jdtInteger then
                    PByte(pi)^ := AChild.AsInteger
                  else
                    PByte(pi)^ := StringToSet(ASubType, AChild.AsString);
                end;
              otSWord:
                begin
                  if AChild.DataType = jdtInteger then
                    PSmallint(pi)^ := AChild.AsInteger
                  else
                    PSmallint(pi)^ := StringToSet(ASubType, AChild.AsString);
                end;
              otUWord:
                begin
                  if AChild.DataType = jdtInteger then
                    PWord(pi)^ := AChild.AsInteger
                  else
                    PWord(pi)^ := StringToSet(ASubType, AChild.AsString);
                end;
              otSLong:
                begin
                  if AChild.DataType = jdtInteger then
                    PInteger(pi)^ := AChild.AsInteger
                  else
                    PInteger(pi)^ := StringToSet(ASubType, AChild.AsString);
                end;
              otULong:
                begin
                  if AChild.DataType = jdtInteger then
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

function TQJson.ToRttiValue: TValue;
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
    jdtString:
      Result := AsString;
    jdtInteger:
      Result := AsInt64;
    jdtFloat:
      Result := AsFloat;
    jdtDateTime:
      Result := AsDateTime;
    jdtBoolean:
      Result := AsBoolean;
    jdtArray, jdtObject:
      // 数组和对象都只能当成数组来处理
      AsDynValueArray
  else
    Result := TValue.Empty;
  end;
end;
{$IFEND >=2010}

function TQJson.ToString: string;
begin
  Result := AsString;
end;

function TQJson.TryParse(p: PWideChar; l: Integer): Boolean;

  procedure DoTry;
  var
    ABuilder: TQStringCatHelperW;
  begin
    ABuilder := TQStringCatHelperW.Create;
    try
      try
        SkipSpaceW(p);
        Result := ParseJsonPair(ABuilder, p) = 0;
      except
        on E: Exception do
          Result := False;
      end;
    finally
      FreeObject(ABuilder);
    end;
  end;

  procedure ParseCopy;
  var
    S: QStringW;
  begin
    S := StrDupW(p, 0, l);
    p := PQCharW(S);
    DoTry;
  end;

begin
  Result := False;
  if DataType in [jdtObject, jdtArray] then
    Clear;
  if (l > 0) and (p[l] <> #0) then
    ParseCopy
  else
    DoTry;
end;

function TQJson.TryGetAsBoolean(var AValue: Boolean): Boolean;
begin
  Result := True;
  if DataType = jdtBoolean then
    AValue := PBoolean(FValue)^
  else if DataType = jdtString then
  begin
    if not TryStrToBool(FValue, AValue) then
      Result := False;
  end
  else if DataType in [jdtFloat, jdtDateTime] then
    AValue := not SameValue(AsFloat, 0, 5E-324)
  else if DataType = jdtInteger then
    AValue := AsInt64 <> 0
  else
    Result := False;
end;

function TQJson.TryGetAsDateTime(var AValue: TDateTime): Boolean;
begin
  Result := True;
  if DataType in [jdtDateTime, jdtFloat] then
    AValue := PExtended(FValue)^
  else if DataType = jdtString then
  begin
    if Length(FValue) > 0 then
      Result := ParseDateTime(PWideChar(FValue), AValue) or
        ParseJsonTime(PWideChar(FValue), AValue) or
        ParseWebTime(PQCharW(FValue), AValue)
    else
      Result := False;
  end
  else if DataType = jdtInteger then
    AValue := AsInt64
  else if DataType in [jdtNull, jdtUnknown] then
    AValue := 0
  else
    Result := False;
end;

function TQJson.TryGetAsFloat(var AValue: Extended): Boolean;
  procedure StrAsFloat;
  var
    p: PQCharW;
  begin
    p := PQCharW(FValue);
    if (not ParseNumeric(p, AValue)) or (p^ <> #0) then
      Result := False;
  end;

begin
  Result := True;
  if DataType in [jdtFloat, jdtDateTime] then
    AValue := PExtended(FValue)^
  else if DataType = jdtBoolean then
    AValue := Integer(AsBoolean)
  else if DataType = jdtString then
    StrAsFloat
  else if DataType = jdtInteger then
    AValue := AsInt64
  else if DataType = jdtNull then
    AValue := 0
  else
    Result := False;
end;

function TQJson.TryGetAsInt64(var AValue: Int64): Boolean;
var
  AExt: Extended;
begin
  Result := True;
  if DataType = jdtInteger then
    AValue := PInt64(FValue)^
  else if DataType in [jdtFloat, jdtDateTime] then
    AValue := Trunc(PExtended(FValue)^)
  else if DataType = jdtBoolean then
    AValue := Integer(AsBoolean)
  else if DataType = jdtString then
  begin
    Result := TryGetAsFloat(AExt);
    if Result then
      AValue := Trunc(AExt);
  end
  else if DataType = jdtNull then
    AValue := 0
  else
    Result := False;
end;

function TQJson.TryParse(const S: QStringW): Boolean;
begin
  Result := TryParse(PQCharW(S), Length(S));
end;

function TQJson.TryParseValue(ABuilder: TQStringCatHelperW;
  var p: PQCharW): Integer;
var
  ANum: Extended;
  AComment: QStringW;
  AIsFloat: Boolean;
const
  JsonEndChars: PWideChar = ',]}';
  MaxInt64: Int64 = 9223372036854775807;
  MinInt64: Int64 = -9223372036854775808;
begin
  Result := 0;
  if p^ = '"' then
  begin
    BuildJsonString(ABuilder, p);
    AsString := ABuilder.Value;
  end
  else if p^ = '''' then
  begin
    if StrictJson then
      Result := EParse_BadStringStart;
    BuildJsonString(ABuilder, p);
    AsString := ABuilder.Value;
  end
  else if ParseNumeric(p, ANum, AIsFloat) then // 数字？
  begin
    SkipSpaceAndComment(p, AComment);
    if Length(AComment) > 0 then
      FComment := AComment;
    if (p^ = #0) or CharInW(p, JsonEndChars) then
    begin
      if (ANum >= MinInt64) and (ANum <= MaxInt64) and (not AIsFloat) then
        AsInt64 := Trunc(ANum)
      else
        AsFloat := ANum;
    end
    else
      Result := EParse_BadJson;
  end
  else if StartWithW(p, 'False', True) then // False
  begin
    Inc(p, 5);
    SkipSpaceAndComment(p, AComment);
    AsBoolean := False
  end
  else if StartWithW(p, 'True', True) then
  // True
  begin
    Inc(p, 4);
    SkipSpaceAndComment(p, AComment);
    AsBoolean := True;
  end
  else if StartWithW(p, 'NULL', True) then
  // Null
  begin
    Inc(p, 4);
    SkipSpaceAndComment(p, AComment);
    ResetNull;
  end
  else if p^ = ',' then
  begin
    SkipSpaceAndComment(p, AComment);
    ResetNull;
  end
  else if (p^ = '[') or (p^ = '{') then
    Result := ParseJsonPair(ABuilder, p)
  else
    Result := 2;
end;

procedure TQJson.ValidArray;
begin
  if DataType in [jdtArray, jdtObject] then
    FItems := TQJsonItemList.Create
  else
    raise Exception.Create(Format(SVarNotArray, [FName]));
end;

function TQJson.ValueByName(AName, ADefVal: QStringW): QStringW;
var
  AChild: TQJson;
begin
  AChild := ItemByName(AName);
  if Assigned(AChild) then
    Result := AChild.Value
  else
    Result := ADefVal;
end;

function TQJson.ValueByPath(APath, ADefVal: QStringW): QStringW;
var
  AItem: TQJson;
begin
  AItem := ItemByPath(APath);
  if Assigned(AItem) then
    Result := AItem.Value
  else
    Result := ADefVal;
end;

procedure TQJson.ValueFromFile(AFileName: QStringW);
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

procedure TQJson.ValueFromStream(AStream: TStream; ACount: Cardinal);
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

procedure TQJson.Delete;
begin
  if Assigned(FParent) then
    FParent.Delete(ItemIndex)
  else
    FreeObject(Self);
end;

{ TQJsonEnumerator }

constructor TQJsonEnumerator.Create(AList: TQJson);
begin
  inherited Create;
  FList := AList;
  FIndex := -1;
end;

function TQJsonEnumerator.GetCurrent: TQJson;
begin
  Result := FList[FIndex];
end;

function TQJsonEnumerator.MoveNext: Boolean;
begin
  if FIndex < FList.Count - 1 then
  begin
    Inc(FIndex);
    Result := True;
  end
  else
    Result := False;
end;

{ TQHashedJson }

procedure TQHashedJson.Assign(ANode: TQJson);
var
  I: Integer;
begin
  inherited;
  if (Length(FName) > 0) and (FNameHash = 0) then
  begin
    FNameHash := HashName(FName);
    if Assigned(Parent) then
      TQHashedJson(Parent).FHashTable.Add(Self, FNameHash);
  end;
  for I := 0 to Count - 1 do
  begin
    ANode := Items[I];
    ANode.HashNeeded;
    FHashTable.Add(ANode, ANode.NameHash);
  end;
end;

procedure TQHashedJson.Clear;
begin
  inherited;
  FHashTable.Clear;
end;

constructor TQHashedJson.Create;
begin
  inherited;
  FHashTable := TQHashTable.Create();
  FHashTable.AutoSize := True;
end;

function TQHashedJson.CreateJson: TQJson;
begin
  if Assigned(OnQJsonCreate) then
    Result := OnQJsonCreate
  else
    Result := TQHashedJson.Create;
end;

destructor TQHashedJson.Destroy;
begin
  Clear;
  inherited;
  FreeAndNil(FHashTable);
end;

procedure TQHashedJson.DoJsonNameChanged(AJson: TQJson);
  procedure Rehash;
  var
    AHash: TQHashType;
    AList: PQHashList;
    AItem: TQJson;
  begin
    AHash := HashName(AJson.Name);
    if AHash <> AJson.FNameHash then
    begin
      AList := TQHashedJson(AJson.Parent).FHashTable.FindFirst(AJson.FNameHash);
      while AList <> nil do
      begin
        AItem := AList.Data;
        if AItem = AJson then
        begin
          TQHashedJson(AJson.Parent).FHashTable.ChangeHash(AJson,
            AJson.FNameHash, AHash);
          AJson.FNameHash := AHash;
          Break;
        end
        else
          AList := TQHashedJson(AJson.Parent).FHashTable.FindNext(AList);
      end;
    end;
  end;

begin
  if AJson.FNameHash = 0 then
  begin
    AJson.FNameHash := HashName(AJson.Name);
    if Assigned(AJson.Parent) then
      TQHashedJson(AJson.Parent).FHashTable.Add(AJson, AJson.FNameHash);
  end
  else
    Rehash;
end;

function TQHashedJson.IndexOf(const AName: QStringW): Integer;
var
  AHash: Integer;
  AList: PQHashList;
  AItem: TQJson;
begin
  AHash := HashName(AName);
  AList := FHashTable.FindFirst(AHash);
  Result := -1;
  while AList <> nil do
  begin
    AItem := AList.Data;
    if AItem.Name = AName then
    begin
      Result := AItem.ItemIndex;
      Break;
    end
    else
      AList := FHashTable.FindNext(AList);
  end;
end;

function TQHashedJson.ItemByName(AName: QStringW): TQJson;
  function ByHash: TQJson;
  var
    AHash: Integer;
    AList: PQHashList;
    AItem: TQJson;
  begin
    AHash := HashName(AName);
    AList := FHashTable.FindFirst(AHash);
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
        AList := FHashTable.FindNext(AList);
    end;
  end;

begin
  if DataType = jdtObject then
    Result := ByHash
  else
    Result := inherited ItemByName(AName);
end;

procedure TQHashedJson.DoParsed;
var
  I: Integer;
  AJson: TQJson;
begin
  FHashTable.Resize(Count);
  for I := 0 to Count - 1 do
  begin
    AJson := Items[I];
    if Length(AJson.FName) > 0 then
    begin
      if AJson.FNameHash = 0 then
      begin
        AJson.FNameHash := HashName(AJson.FName);
        FHashTable.Add(AJson, AJson.FNameHash);
      end;
    end;
    if AJson.Count > 0 then
      AJson.DoParsed;
  end;
end;

function TQHashedJson.Remove(AIndex: Integer): TQJson;
begin
  Result := inherited Remove(AIndex);
  if Assigned(Result) then
    FHashTable.Delete(Result, Result.NameHash);
end;

procedure TQHashedJson.Replace(AIndex: Integer; ANewItem: TQJson);
var
  AOld: TQJson;
begin
  if not(ANewItem is TQHashedJson) then
    raise Exception.CreateFmt(SReplaceTypeNeed, ['TQHashedJson']);
  AOld := Items[AIndex];
  FHashTable.Delete(AOld, AOld.NameHash);
  inherited;
  if Length(ANewItem.FName) > 0 then
  begin
    if ANewItem.NameHash = 0 then
      ANewItem.FNameHash := HashName(ANewItem.Name);
    FHashTable.Add(ANewItem, ANewItem.FNameHash);
  end;
end;

procedure EncodeJsonBinaryAsBase64;
begin
  OnQJsonEncodeBytes := DoEncodeAsBase64;
  OnQJsonDecodeBytes := DoDecodeAsBase64;
end;

procedure EncodeJsonBinaryAsHex;
begin
  OnQJsonEncodeBytes := nil;
  OnQJsonDecodeBytes := nil;
end;

{ TQJsonStreamHelper }

procedure TQJsonStreamHelper.BeginArray;
begin
  Inc(FLast.Count);
  FStringHelper.Cat('[');
  Push;
end;

procedure TQJsonStreamHelper.BeginArray(const AName: QStringW);
begin
  Inc(FLast.Count);
  WriteName(AName);
  FStringHelper.Cat('[');
  Push;
end;

procedure TQJsonStreamHelper.BeginObject;
begin
  Inc(FLast.Count);
  FStringHelper.Cat('{');
  Push;
end;

procedure TQJsonStreamHelper.BeginObject(const AName: QStringW);
begin
  Inc(FLast.Count);
  WriteName(AName);
  FStringHelper.Cat('{');
  Push;
end;

procedure TQJsonStreamHelper.BeginWrite(AStream: TStream;
  AEncoding: TTextEncoding; ADoEscape, AWriteBom: Boolean);
begin
  FStream := AStream;
  FEncoding := AEncoding;
  FDoEscape := ADoEscape;
  FWriteBom := AWriteBom;
  FLast := nil;
  FStringHelper := TQStringCatHelperW.Create;
  Push;
end;

procedure TQJsonStreamHelper.EndArray;
begin
  if FLast.Count > 0 then
    FStringHelper.Back(1);
  FStringHelper.Cat('],');
  Pop;
end;

procedure TQJsonStreamHelper.EndObject;
begin
  if FLast.Count > 0 then
    FStringHelper.Back(1);
  FStringHelper.Cat('},');
  Pop;
end;

procedure TQJsonStreamHelper.EndWrite;
  procedure AnsiWrite;
  var
    T: QStringA;
  begin
    T := qstring.AnsiEncode(FStringHelper.Start, FStringHelper.Position);
    FStream.Write(PQCharA(T)^, T.Length);
  end;
  procedure Utf8Write;
  var
    T: QStringA;
  const
    Utf8BOM: array [0 .. 2] of Byte = ($EF, $BB, $BF);
  begin
    T := qstring.Utf8Encode(FStringHelper.Start, FStringHelper.Position);
    if FWriteBom then
      FStream.Write(Utf8BOM, 3);
    FStream.Write(PQCharA(T)^, T.Length);
  end;
  procedure LEWrite;
  const
    Utf16LEBom: Word = $FEFF;
  begin
    if FWriteBom then
      FStream.Write(Utf16LEBom, 2);
    FStream.Write(FStringHelper.Start^, FStringHelper.Position shl 1);
  end;
  procedure BEWrite;
  const
    Utf16BEBom: Word = $FFFE;
  begin
    ExchangeByteOrder(PQCharA(FStringHelper.Start),
      FStringHelper.Position shl 1);
    if FWriteBom then
      FStream.Write(Utf16BEBom, 2);
    FStream.Write(FStringHelper.Start^, FStringHelper.Position shl 1);
  end;

begin
  if FLast.Count > 0 then
  begin
    FStringHelper.Back(1);
    case FEncoding of
      teAnsi:
        AnsiWrite;
      teUnicode16LE:
        LEWrite;
      teUnicode16BE:
        BEWrite;
      teUtf8:
        Utf8Write;
    end;
  end;
  Pop;
  FreeAndNil(FStringHelper);
end;

procedure TQJsonStreamHelper.InternalWriteString(S: QStringW;
  ADoAppend: Boolean);
begin
  FStringHelper.Cat(S);
  if ADoAppend then
    FStringHelper.Cat(',');
  Inc(FLast.Count);
end;

procedure TQJsonStreamHelper.Pop;
var
  ALast: PQStreamHelperStack;
begin
  if Assigned(FLast) then
  begin
    ALast := FLast;
    FLast := ALast.Prior;
    Dispose(ALast);
  end;
end;

procedure TQJsonStreamHelper.Push;
var
  AItem: PQStreamHelperStack;
begin
  New(AItem);
  AItem.Prior := FLast;
  AItem.Count := 0;
  FLast := AItem;
end;

procedure TQJsonStreamHelper.Write(const S: QStringW);
begin
  FStringHelper.Cat('"');
  TQJson.JsonCat(FStringHelper, S, FDoEscape);
  FStringHelper.Cat('",');
  Inc(FLast.Count);
end;

procedure TQJsonStreamHelper.Write(const ABytes: TBytes);
var
  S: QStringW;
begin
  if Assigned(OnQJsonEncodeBytes) then
    OnQJsonEncodeBytes(ABytes, S)
  else
    S := qstring.BinToHex(ABytes);
  Write(S);
end;

procedure TQJsonStreamHelper.Write(const p: PByte; l: Integer);
var
  ATemp: TBytes;
begin
  SetLength(ATemp, l);
  Move(p^, ATemp[0], l);
  Write(ATemp);
end;

procedure TQJsonStreamHelper.Write(const b: Boolean);
begin
  if b then
    InternalWriteString('true')
  else
    InternalWriteString('false');
end;

procedure TQJsonStreamHelper.Write(const I: Int64);
begin
  InternalWriteString(IntToStr(I));
end;

procedure TQJsonStreamHelper.Write(const D: Double);
begin
  InternalWriteString(FloatToStr(D));
end;

procedure TQJsonStreamHelper.Write(const c: Currency);
begin
  InternalWriteString(CurrToStr(c));
end;

procedure TQJsonStreamHelper.WriteDateTime(const V: TDateTime);
  function JsonDateTime: QStringW;
  var
    MS: Int64; // 时区信息不保存
  const
    JsonTimeStart: PWideChar = '/DATE(';
    JsonTimeEnd: PWideChar = ')/';
    UnixDelta: Int64 = 25569;
  begin
    MS := Trunc((V - UnixDelta) * 86400000);
    Result := JsonTimeStart;
    if (JsonTimezone >= -12) and (JsonTimezone <= 12) then
    begin
      Dec(MS, 3600000 * JsonTimezone);
      if JsonDatePrecision = jdpSecond then
        MS := MS div 1000;
      Result := Result + IntToStr(MS);
      if JsonTimezone >= 0 then
        Result := Result + '+';
      Result := Result + IntToStr(JsonTimezone);
    end
    else
      Result := Result + IntToStr(MS);
    Result := Result + JsonTimeEnd;
  end;

  function FormatedJsonTime: QStringW;
  var
    ADate: Integer;
  begin
    ADate := Trunc(V);
    if SameValue(ADate, 0) then // Date为0，是时间
    begin
      if SameValue(V, 0) then
        Result := '"' + FormatDateTime(JsonDateFormat, V) + '"'
      else
        Result := '"' + FormatDateTime(JsonTimeFormat, V) + '"';
    end
    else
    begin
      if SameValue(V - ADate, 0) then
        Result := '"' + FormatDateTime(JsonDateFormat, V) + '"'
      else
        Result := '"' + FormatDateTime(JsonDateTimeFormat, V) + '"';
    end;
  end;

begin
  if StrictJson then
    InternalWriteString(JsonDateTime)
  else
    InternalWriteString(FormatedJsonTime);
end;

procedure TQJsonStreamHelper.WriteName(const S: QStringW);
begin
  FStringHelper.Cat('"');
  TQJson.JsonCat(FStringHelper, S, FDoEscape);
  FStringHelper.Cat('":');
end;

procedure TQJsonStreamHelper.WriteNull(const AName: QStringW);
begin
  WriteName(AName);
  WriteNull;
end;

procedure TQJsonStreamHelper.WriteNull;
begin
  InternalWriteString('null');
end;

procedure TQJsonStreamHelper.Write(const AName: QStringW; AValue: Double);
begin
  WriteName(AName);
  InternalWriteString(FloatToStr(AValue));
end;

procedure TQJsonStreamHelper.Write(const AName: QStringW; AValue: Int64);
begin
  WriteName(AName);
  InternalWriteString(IntToStr(AValue));
end;

procedure TQJsonStreamHelper.Write(const AName, AValue: QStringW);
begin
  WriteName(AName);
  Write(AValue);
end;

procedure TQJsonStreamHelper.Write(const AName: QStringW; const p: PByte;
  const l: Integer);
begin
  WriteName(AName);
  Write(p, l);
end;

procedure TQJsonStreamHelper.Write(const AName: QStringW; AValue: Boolean);
begin
  WriteName(AName);
  Write(AValue);
end;

procedure TQJsonStreamHelper.Write(const AName: QStringW; AValue: TBytes);
begin
  WriteName(AName);
  Write(AValue);
end;

procedure TQJsonStreamHelper.WriteDateTime(const AName: QStringW;
  AValue: TDateTime);
begin
  WriteName(AName);
  WriteDateTime(AValue);
end;

{ TQJsonContainer }

function TQJsonContainer.ForEach(ACallback: TQJsonForEachCallback;
  ATag: Pointer): IQJsonContainer;
var
  I: Integer;
begin
  Result := Self;
  if Assigned(ACallback) then
  begin
    for I := 0 to FItems.Count - 1 do
      ACallback(FItems[I], ATag);
  end;
end;

constructor TQJsonContainer.Create;
begin
  inherited;
  FItems := TQJsonItemList.Create;
end;

constructor TQJsonContainer.Create(AJson: TQJson);
begin
  inherited Create;
  FItems := TQJsonItemList.Create;
  if Assigned(AJson) then
    FItems.Add(AJson);
end;

destructor TQJsonContainer.Destroy;
begin
  FreeAndNil(FItems);
  inherited;
end;
{$IFDEF UNICODE}

function TQJsonContainer.ForEach(ACallback: TQJsonForEachCallbackA)
  : IQJsonContainer;
var
  I: Integer;
begin
  Result := Self;
  if Assigned(ACallback) then
  begin
    for I := 0 to FItems.Count - 1 do
      ACallback(FItems[I]);
  end;
end;

function TQJsonContainer.Match(const AFilter: TQJsonMatchFilterCallbackA;
  ATag: Pointer): IQJsonContainer;
var
  I: Integer;
  T: TQJsonContainer;
  Accept: Boolean;
begin
  if Assigned(AFilter) then
  begin
    T := TQJsonContainer.Create;
    Result := T;
    for I := 0 to FItems.Count - 1 do
    begin
      Accept := False;
      AFilter(FItems[I], Accept);
      if Accept then
        T.FItems.Add(FItems[I]);
    end;
  end
  else // 没有执行任何过滤
    Result := Self;
end;
{$ENDIF}

function TQJsonContainer.GetCount: Integer;
begin
  Result := FItems.Count;
end;

function TQJsonContainer.GetEnumerator: TQJsonContainerEnumerator;
begin
  Result := TQJsonContainerEnumerator.Create(Self);
end;

function TQJsonContainer.GetIsEmpty: Boolean;
begin
  Result := FItems.Count = 0;
end;

function TQJsonContainer.GetItems(const AIndex: Integer): TQJson;
begin
  Result := FItems[AIndex];
end;

function TQJsonContainer.Match(const AFilter: TQJsonMatchFilterCallback;
  ATag: Pointer): IQJsonContainer;
var
  I: Integer;
  T: TQJsonContainer;
  Accept: Boolean;
begin
  if Assigned(AFilter) then
  begin
    T := TQJsonContainer.Create;
    Result := T;
    for I := 0 to FItems.Count - 1 do
    begin
      Accept := False;
      AFilter(FItems[I], ATag, Accept);
      if Accept then
        T.FItems.Add(FItems[I]);
    end;
  end
  else // 没有执行任何过滤
    Result := Self;
end;

function TQJsonContainer.Match(const AStart, AStop, AStep: Integer)
  : IQJsonContainer;
var
  I, c: Integer;
  T: TQJsonContainer;
begin
  I := AStart;
  T := TQJsonContainer.Create;
  Result := T;
  if AStep > 0 then
  begin
    c := AStop;
    if c > FItems.Count then
      c := FItems.Count;
    while I < c do
    begin
      if I >= 0 then
        T.FItems.Add(FItems[I]);
      Inc(I, AStep);
    end;
  end
  else if AStart > AStop then // 逆序
  begin
    c := FItems.Count;
    while I > AStop do
    begin
      if (I >= 0) and (I < c) then
        T.FItems.Add(FItems[I]);
      Inc(I, AStep);
    end;
  end;
end;

function TQJsonContainer.Match(const AIndexes: array of Integer)
  : IQJsonContainer;
var
  I, c: Integer;
  T: TQJsonContainer;
begin
  I := 0;
  T := TQJsonContainer.Create;
  Result := T;
  c := FItems.Count;
  for I := 0 to High(AIndexes) do
  begin
    if (AIndexes[I] >= 0) and (AIndexes[I] < c) then
      T.FItems.Add(FItems[AIndexes[I]]);
  end;
end;

function TQJsonContainer.Match(const ARegex: QStringW;
  ASettings: TQJsonMatchSettings): IQJsonContainer;
var
  AReg: TPerlRegEx;
  T: TQJsonContainer;
  I: Integer;

  procedure DoMatch(AJson: TQJson);
  var
    J: Integer;
    Accept: Boolean;
  begin
    if jmsMatchName in ASettings then
    begin
      AReg.Subject := AJson.Name;
      if AReg.Match then
      begin
        T.FItems.Add(FItems[I]);
        Exit;
      end;
    end;
    if jmsMatchPath in ASettings then
    begin
      AReg.Subject := AJson.Path;
      if AReg.Match then
      begin
        T.FItems.Add(AJson);
        Exit;
      end;
    end;
    if AJson.DataType in [jdtArray, jdtObject] then
    begin
      if jmsNest in ASettings then
      begin
        for J := 0 to AJson.Count - 1 do
          DoMatch(AJson[J]);
      end;
    end
    else if jmsMatchValue in ASettings then
    begin
      AReg.Subject := AJson.AsString;
      if AReg.Match then
        T.FItems.Add(AJson);
    end;
  end;

begin
  AReg := TPerlRegEx.Create;
  try
    AReg.RegEx := ARegex;
    if jmsIgnoreCase in ASettings then
      AReg.Options := [preCaseLess];
    AReg.Compile;
    T := TQJsonContainer.Create;
    Result := T;
    for I := 0 to FItems.Count - 1 do
      DoMatch(FItems[I]);
  finally
    FreeAndNil(AReg);
  end;
end;

{ TQJsonContainerEnumerator }

constructor TQJsonContainerEnumerator.Create(AList: IQJsonContainer);
begin
  FList := AList;
  FIndex := -1;
end;

function TQJsonContainerEnumerator.GetCurrent: TQJson;
begin
  Result := FList[FIndex];
end;

function TQJsonContainerEnumerator.MoveNext: Boolean;
begin
  if FIndex < FList.Count - 1 then
  begin
    Inc(FIndex);
    Result := True;
  end
  else
    Result := False;
end;

initialization

StrictJson := False;
JsonRttiEnumAsInt := True;
JsonCaseSensitive := True;
JsonDateFormat := 'yyyy-mm-dd';
JsonDateTimeFormat := 'yyyy-mm-dd''T''hh:nn:ss.zzz';
JsonTimeFormat := 'hh:nn:ss.zzz';
JsonTimezone := JSON_NO_TIMEZONE;
JsonDatePrecision := jdpMillisecond;
JsonIntToTimeStyle := tsDeny;
OnQJsonCreate := nil;
OnQJsonFree := nil;

end.
