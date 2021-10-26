unit qmacros;

{
  QMacros使用基于宏替换的技术来完成模板内容的快速替换。QMacros的特色在于：
  ● 支持在替换时自定义宏的起始和结束字符串，两者可以一样，也可以不一样，但一定要保证宏定义中间不会出现该字符；
  ● 采用栈式管理，使用使用宏最后入栈的值替换，当不使用新值时，可以出栈恢复末次的值；
  ● 支持保存点功能，可以设置保存点并在其后多次入栈新的宏定义，只需要在最后还原到保存的保存点，就可以恢复所有保存点保存时的宏定义原状；
  ● 支持大小写区分和忽略大小写两种处理模式；
  ● 支持动态取值宏定义（相当于简单的函数），可以让宏定义每次替换时对应不同的值；
  ● 使用二分法查找宏定义名称，更快的解析替换速度；
  ● 支持模板预编译
  更多信息，请访问官网的QMacros专题
}
interface

{
  本源码来自QDAC项目，版权归swish(QQ:109867294)所有。
  (1)、使用许可及限制
  您可以自由复制、分发、修改本源码，但您的修改应该反馈给作者，并允许作者在必要时，
  合并到本项目中以供使用，合并后的源码同样遵循QDAC版权声明限制。
  您的产品的关于中，应包含以下的版本声明:
  本产品使用的宏解析器来自QDAC项目中的QMacros，版权归作者所有。
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
  2017.2.3
  ==========
  * 修正了使用匿名函数做为宏值函数时，存在内存泄露的问题

  2016.3.23
  ==========
  * 修正了以无效字符结束时，如果宏位于字符串结尾时出错的问题(黑暗杀手报告）

  2016.3.22
  ==========
  * 增加了MRF_ENABLE_ESCAPE来转义特定字符的支持，规则同JSON
  * 增加了MRF_IGNORE_MISSED标志位来支持忽略未定义的宏

  2015.12.17
  ==========
  + 新增参数化宏支持（感谢渣渣）
  2015.5.22
  ==========
  * 修正了 InternalCompile 中,CompareMem时 LS 值不对的问题
  2015.4.30
  ==========
  * 支持宏以指定的字符起始，以无效的标志字符结束
  * 宏名称为空时，抛出异常提示宏名称未指定

  2015.2.26
  =========
  * 修正了在2007下的编译错误（感谢麦子仲肥）
  2014.12.15
  ==========
  *  修正了编译为Andriod程序时，报InternalComplie函数参数错误（麦子仲肥报告）
  2014.12.12
  ==========
  * 初始版本

}
uses classes, sysutils, math, db, qstring, qjson{$IFDEF UNICODE},
  Generics.Collections{$ENDIF};

const
  MRF_IN_DBL_QUOTER = $01; // 是否替换双引号中间的内容
  MRF_IN_SINGLE_QUOTER = $02; // 是否替换单引号中间的内容
  MRF_DELAY_BINDING = $04; // 是否延迟绑定宏定义，如果是的话，则在第一次Replace之前会检查是否宏都已经绑定
  MRF_END_WITH_INVALID_CHAR = $08; // 宏以指定的字符起始，但以非标志字符结束
  MRF_PARSE_PARAMS = $10; // 解析宏里面的参数
  MRF_ENABLE_ESCAPE = $20; // 启用转义支持
  MRF_IGNORE_MISSED = $40; // 忽略无法识别的宏名称，将其认为是普通的字符串
  MFF_FILETYPE = $736F7263614D51; // 缓存文件标志符，用于区分其它文件

{$HPPEMIT '#pragma link "qmacros"'}

type
  TQMacroManager = class;
  TQMacroItem = class;
  TQMacroComplied = class;
  /// <summary>
  /// 查找动态宏的值时的通过回调函数获取相应的值，返回值直接赋给AMacro.Value.Value即可。
  /// </summary>
  /// <param name="AMacro">宏</param>
  /// <param name="AQuoter">引号类型，值可能是#0(0)或英文的单引号或双引号</param>
  TQMacroValueFetchEvent = procedure(AMacro: TQMacroItem; const AQuoter: QCharW)
    of object;
  TQMacroValueFetchEventG = procedure(AMacro: TQMacroItem;
    const AQuoter: QCharW);
{$IFDEF UNICODE}
  TQMacroValueFetchEventA = reference to procedure(AMacro: TQMacroItem;
    const AQuoter: QCharW);
  PQMacroValueFetchEventA = ^TQMacroValueFetchEventA;
{$ENDIF}
  /// <summary>指不到指定的宏时触发的事件</summary>
  /// <param name="ASender">宏管理器</param>
  /// <param name="AName">宏名称</param>
  /// <param name="AQuoter">引号类型，值可能是#0(\0)或英文的单引号或双引号</param>
  /// <param name="AHandled">如果事件处理了宏不存的问题，则设置为True，否则请勿设置</param>
  TQMacroMissEvent = procedure(ASender: TQMacroManager; AName: QStringW;
    const AQuoter: QCharW; var AHandled: Boolean) of object;
  TQMacroMissEventG = procedure(ASender: TQMacroManager; AName: QStringW;
    const AQuoter: QCharW; var AHandled: Boolean);
{$IFDEF UNICODE}
  TQMacroMissEventA = reference to procedure(ASender: TQMacroManager;
    AName: QStringW; const AQuoter: QCharW; var AHandled: Boolean);
  PQMacroMissEventA = ^TQMacroMissEventA;
{$ENDIF}
  TQMacroCharType = (mctChar, mctNameStart, mctNameEnd);
  TQMacroNameTestEvent = procedure(ASender: TQMacroManager; p: PQCharW;
    var ALen: Integer; var AType: TQMacroCharType) of object;
  TQMacroNameTestEventG = procedure(ASender: TQMacroManager; p: PQCharW;
    var ALen: Integer; var AType: TQMacroCharType);
{$IFDEF UNICODE}
  TQMacroNameTestEventA = reference to procedure(ASender: TQMacroManager;
    p: PQCharW; var ALen: Integer; var AType: TQMacroCharType);
  PQMacroNameTestEventA = ^TQMacroNameTestEventA;
{$ENDIF}
  /// <summary>
  /// 宏定义值的稳定性定义
  /// </summary>
  /// <param name="mvImmutable">值是固定不变的，是一种常量状态</param>
  /// <param name="mvStable">值是相对不变的，在一次替换操作过程中，除了在首次出现的位置外，我们都可以认为其等价发mvImmutable</param>
  /// <param name="mvVolatile">值是易变的，每次获取宏的值时，返回的值都可能是不同的</param>
  TQMacroVolatile = (mvImmutable,
    /// 值是固定不变的，是一种常量状态
    mvStable,
    /// 值是相对不变的，在一次替换操作过程中，除了在首次出现的位置外，我们都可以认为其等价发mvImmutable
    mvVolatile
    /// 值是易变的，每次获取宏的值时，返回的值都可能是不同的
    );

  IQMacroIterator = interface
    ['{3DB5D84F-0539-4C10-9476-E6B71D3099DE}']
    // 开始替换
    procedure BeginReplace(AMacro: TQMacroItem);
    // 判断是否还有要处理的数据
    function HasNext: Boolean;
    // 执行一次替换
    function Replace: QStringW;
    // 结束替换
    procedure EndReplace;
    // 获取当前活动的迭代器序号
    function GetItemIndex: Integer;
  end;

  // TQMacroValue类型的指针类型定义
  PQMacroValue = ^TQMacroValue;

  // 单个宏值定义
  TQMacroValue = record
    Value: QStringW; // 当前值，静态值固定时使用它
    OnFetchValue: TQMacroValueFetchEvent; // 动态宏取值时使用它
    Tag: IntPtr; // 用户附加标签
    SavePoint: Integer; // 保存点
    ReplaceId: Integer; // 替换内部标记，用于在一次缓存中缓存mvStable类型的值
    Volatile: TQMacroVolatile; // 稳定性
    Iterator: IQMacroIterator; // 值如果是一个列表，则此处指向迭代器
    /// 宏的下一个取值
    /// 宏的前一个取值
    Prior, Next: PQMacroValue; // 链表，用于实现栈式访问
  end;

  // 单一宏项目
  TQMacroItem = class
  protected
    FName: QStringW;
    FValue: PQMacroValue;
    FParams: TQJson;
    FOwner: TQMacroManager;
  public
    constructor Create(AOwner: TQMacroManager); overload;
    destructor Destroy; override;
    property Name: QStringW read FName; // 宏名称
    property Value: PQMacroValue read FValue; // 宏值
    property Owner: TQMacroManager read FOwner; // 所有者
    property Params: TQJson read FParams; // 获取值时临时由编译结果拷贝过来的值
  end;
{$IFDEF UNICODE}

  TMacroList = TList<TQMacroItem>; // 宏列表
{$ELSE}
  TMacroList = TList; // 宏列表 <D2009
{$ENDIF}

  // 编译结果的单项定义
  TQMacroCompliedItem = record
    Start: PWideChar; // 起始偏移
    Length: Integer; // 长度，单位为字符
    Quoter: QCharW; // 引号情况
    IsMacro: Boolean; // 是否是宏定义
    Macro: TQMacroItem; // 如果是宏定义，则对应于相应的宏定义
    Params: TQJson;
    Text: QStringW;
  end;

  // TQMacroCompliedItem的指针类型定义
  PQMacroCompliedItem = ^TQMacroCompliedItem;
  // TQMacroCompliedItem动态数组定义
  TQCompliedArray = array of TQMacroCompliedItem;

  // TQMacroComplied用于保存解析后的要替换内容的信息，以加速多次替换
  TQMacroComplied = class
  protected
    FOwner: TQMacroManager; // 所有者
    FMinSize: Integer; // 结果最小需要分配的内存长度
    FCount: Integer; // 项目数量
    FVolatiles: Integer; // 易变变量数量
    FDelayCount: Integer; // 延迟绑定的宏数量
    FPushId: Integer; // 用于检测入出栈变化，以决定是否在替换时进行编译检查的设置
    FText: QStringW; // 原始要替换的文本
    FMacroStart, FMacroEnd: QStringW; //
    FReplacedText: QStringW; // 末次替换结果，缓存以减少替换次数
    FItems: TQCompliedArray; // 编译项目
    FFlags: Integer;
    function MacroNeeded(const AName: QStringW): TQMacroItem;
  public
    constructor Create(AOwner: TQMacroManager); overload;
    destructor Destroy; override;
    /// <summary>从流中加载预编译的宏替换信息</summary>
    /// <param name="AStream">源数据流</param>
    procedure LoadFromStream(AStream: TStream);
    /// <summary>从文件中加载预编译的宏替换信息</summary>
    /// <param name="AFileName">源文件名</param>
    procedure LoadFromFile(const AFileName: QStringW);
    /// <summary>保存当前预编译的宏替换信息到数据流</summary>
    /// <param name="AStream">目标数据流</param>
    procedure SaveToStream(AStream: TStream);
    /// <summary>保存当前预编译的宏替换信息到文件中</summary>
    /// <param name="AStream">目标文件名</param>
    procedure SaveToFile(const AFileName: QStringW);
    /// <summary>执行一次替换操作</summary>
    /// <returns>返回替换后的字符串</returns>
    function Replace: QStringW;
    /// <summary>使用宏定义替换指定的文本</summary>
    /// <param name="AText">要被替换的文本</param>
    /// <param name="AMacroStart">宏定义起始字符，可以与结束字符不同</param>
    /// <param name="AMacroEnd">宏定义结束字符</param>
    /// <param name="AFlags">标志位，可取 MRF_IN_DBL_QUOTER 和 MRF_IN_SINGLE_QUOTER 的组合</param>
    /// <returns>编译成功，返回True，失败，返回False</returns>
    function Complie(AText: QStringW; AMacroStart, AMacroEnd: QStringW;
      const AFlags: Integer = MRF_ENABLE_ESCAPE): Boolean;
    /// <summary>枚举用到的宏名称</summary>
    /// <param name="AList">用来存贮宏名称的列表</param>
    /// <returns>返回使用的宏的数量</returns>
    function EnumUsedMacros(AList: TStrings): Integer;
    /// <summary>检查所有引用的宏定义是否有效</summary>
    /// <remarks>如果有问题，则抛出异常指出有问题的宏定义</returns>
    procedure CheckMacros;
    property MinSize: Integer read FMinSize; // 替换时，替换结果最小的大小（字符数）
    property Count: Integer read FCount; // 分析后的项目数
    property Items: TQCompliedArray read FItems; // 编译结果数组
    property Volatiles: Integer read FVolatiles; // 动态变化的宏定义数量
    property Owner: TQMacroManager read FOwner; // 所有者
    property Flags: Integer read FFlags; // 编译时设置的标志位
  end;

  TQMacroIterator = class(TInterfacedObject, IQMacroIterator)
  protected
    FItemIndex: Integer;
    FHasNext: Boolean;
    FMacro: TQMacroItem;
    procedure BeginReplace(AMacro: TQMacroItem); virtual;
    function HasNext: Boolean; virtual;
    function Replace: QStringW; virtual;
    procedure EndReplace; virtual;
    function GetItemIndex: Integer; virtual;
  public
    constructor Create; overload;
  end;

  TQMacroStringsIterator = class(TQMacroIterator)
  protected
    FList: TStrings;
    FComplied: TQMacroComplied;
    procedure BeginReplace(AMacro: TQMacroItem); override;
    function HasNext: Boolean; override;
    function Replace: QStringW; override;
  public
    constructor Create(AList: TStrings); overload;
    destructor Destroy; override;
  end;

  /// <summary>
  /// TQMacroManager用于管理已知的宏定义，并提供各种基本的操作支持。
  /// </summary>
  TQMacroManager = class
  private
    FIgnoreCase: Boolean;
    FOnMacroMissed: TQMacroMissEvent;
    FOnTestNameStart: TQMacroNameTestEvent;
    FOnTestNameEnd: TQMacroNameTestEvent;
    function GetCount: Integer;
    function GetItems(AIndex: Integer): TQMacroItem;
    function GetValues(AName: QStringW): QStringW;
    procedure SetOnTestNameEnd(const Value: TQMacroNameTestEvent); overload;
    procedure SetOnTestNameStart(const Value: TQMacroNameTestEvent); overload;
    procedure SetOnMacroMissed(AHandler: TQMacroMissEvent); overload;
  protected
    FMacroes: TMacroList;
    FSavePoint: Integer;
    FReplaceId: Integer;
    FStableCount: Integer;
    FVolatileCount: Integer;
    FLastPushId: Integer;
    FBooleanAsInt: Boolean;
    function InternalMacroValue(const AName: QStringW; const AQuoter: QCharW;
      var AValue: QStringW): Integer;
    function MacroValue(const AName: QStringW; const AQuoter: QCharW)
      : QStringW; overload;
    function DateTimeToStr(ADateTime: TDateTime): String;
    procedure DoFetchFieldValue(AMacro: TQMacroItem; const AQuoter: QCharW);
    procedure DoFetchFieldQuotedValue(AMacro: TQMacroItem;
      const AQuoter: QCharW);
    procedure DoFetchRecordNo(AMacro: TQMacroItem; const AQuoter: QCharW);
    function IncW(p: PQCharW; ALen: Integer): PQCharW; inline;
    procedure InternalPush(AMacro: TQMacroItem; const AValue: QStringW;
      AOnFetch: TQMacroValueFetchEvent; AStable: TQMacroVolatile; ATag: IntPtr);
    procedure InternalComplie(var AResult: TQMacroComplied; AText: QStringW;
      AMacroStart, AMacroEnd: QStringW; const AFlags: Integer);
    function DoMacroMissed(AName: QStringW; const AQuoter: QCharW): Boolean;
    procedure DoFetchValue(AMacro: TQMacroItem; const AQuoter: QCharW);
    function CharUnescape(var p: PQCharW): QCharW;
    function Unescape(const S: QStringW): QStringW; overload;
    function Unescape(p: PQCharW; ALen: Integer): QStringW; overload;
    procedure DoFetchIterator(AMacro: TQMacroItem; const AQuoter: QCharW);
    procedure DoFetchIteratorIndex(AMacro: TQMacroItem; const AQuoter: QCharW);
  public
    /// <summary>构造函数</summary>
    constructor Create; overload;
    /// <summary>析构函数</summary>
    destructor Destroy; override;
    /// <summary>入栈指定名称和值的宏定义</summary>
    /// <param name="AName">宏名称</param>
    /// <param name="AValue">宏对应的具体字符串值</param>
    /// <returns>返回添加的宏定义对象</returns>
    function Push(const AName, AValue: QStringW): TQMacroItem; overload;
    /// <summary>入栈指定名称和值的宏定义</summary>
    /// <param name="AName">宏名称</param>
    /// <param name="AOnFetchValue">获取宏对应的值时调用的回调函数</param>
    /// <param name="AVolatile">函数返回值的稳定性</param>
    /// <param name="ATag">用户附加的标签数据</param>
    /// <returns>返回添加的宏定义对象</returns>
    function Push(const AName: QStringW; AOnFetchValue: TQMacroValueFetchEvent;
      AVolatile: TQMacroVolatile = mvVolatile; ATag: IntPtr = 0)
      : TQMacroItem; overload;

    /// <summary>入栈指定名称和值的宏定义</summary>
    /// <param name="AName">宏名称</param>
    /// <param name="AOnFetchValue">获取宏对应的值时调用的回调函数</param>
    /// <param name="AVolatile">函数返回值的稳定性</param>
    /// <param name="ATag">用户附加的标签数据</param>
    /// <returns>返回添加的宏定义对象</returns>
    function Push(const AName: QStringW; AOnFetchValue: TQMacroValueFetchEventG;
      AVolatile: TQMacroVolatile = mvVolatile; ATag: IntPtr = 0)
      : TQMacroItem; overload;
{$IFDEF UNICODE}
    /// <summary>入栈指定名称和值的宏定义</summary>
    /// <param name="AName">宏名称</param>
    /// <param name="AOnFetchValue">获取宏对应的值时调用的回调函数</param>
    /// <param name="AVolatile">函数返回值的稳定性</param>
    /// <param name="ATag">用户附加的标签数据</param>
    /// <returns>返回添加的宏定义对象</returns>
    function Push(const AName: QStringW; AOnFetchValue: TQMacroValueFetchEventA;
      AVolatile: TQMacroVolatile = mvVolatile; ATag: IntPtr = 0)
      : TQMacroItem; overload;
{$ENDIF}
    /// <summary>入栈指定数据集的所有字段为宏定义</summary>
    /// <param name="ADataSet">数据集对象</param>
    /// <param name="ANameSpace">命名前缀，如果不为空，则为前缀.字段名的宏定义名称</param>
    // <remarks>同时会添加[ANameSpace.]ADataSet.Name.Rows的宏定义，用于迭代输出
    procedure Push(ADataSet: TDataSet;
      const ANameSpace: QStringW = ''); overload;
    /// <summary>入栈指定的迭代器</summary>
    /// <param name="AName">宏名称</param>
    /// <param name="AIterator">迭代器接口实例</param>
    /// <param name="AVolatile"> 函数返回值的稳定性</param>
    /// <param name="ATag">用户附加的标签数据</param>
    /// <returns>返回添加的宏定义对象</returns>
    function Push(const AName: QStringW; AIterator: IQMacroIterator;
      AVolatile: TQMacroVolatile = mvVolatile; ATag: IntPtr = 0)
      : TQMacroItem; overload;
    /// <summary>出栈指定名称的宏定义</summary>
    /// <param name="AName">要出栈的宏定义名称</param>
    procedure Pop(const AName: QStringW); overload;
    /// <summary>出栈指定数据集的上次入栈的所有宏定义</summary>
    /// <param name="ADataSet">数据集对象</param>
    /// <param name="ANameSpace">命名前缀，如果不为空，则为前缀.字段名的宏定义名称</param>
    procedure Pop(ADataSet: TDataSet; const ANameSpace: QStringW); overload;
    /// <summary>设置一个保存点，以便后面使用Restore来直接恢复</summary>
    /// <returns>返回保存点编号</returns>
    /// <remarks>SavePoint和Restore是配对使用的，返回的保存点编号在恢复时作为参数使用</remarks>
    function SavePoint: Integer;
    /// <summary>恢复到指定的保存点</summary>
    /// <param name="ASavePoint">要保存的保存点编号</param>
    /// <remarks>这个保存点之后入栈的所有宏定义都将被出栈</remarks>
    procedure Restore(ASavePoint: Integer);
    /// <summary>查找指定名称的宏定义的索引</summary>
    /// <param name="AName">宏名称</param>
    /// <returns>找到，返回指定的索引，失败，返回-1</returns>
    function IndexOf(const AName: QStringW): Integer;
    /// <summary>查找指定名称的宏定义</summary>
    /// <param name="AName">宏名称</param>
    /// <param name="AIndex">用于接收返回的索引</param>
    /// <returns>找到，返回true，失败，返回false</returns>
    /// <remarks>如果失败，AIndex返回的是指定的值应该出现的位置</remarks>
    function Find(const AName: QStringW; var AIndex: Integer): Boolean;
    /// <summary>清除所有宏定义</summary>
    /// <remarks>注意：清除操作删除所有的宏定义，而不管是保存点位置</remarks>
    procedure Clear;
    /// <summary>使用宏定义替换指定的文本</summary>
    /// <param name="AText">要被替换的文本</param>
    /// <param name="AMacroStart">宏定义起始字符，可以与结束字符不同</param>
    /// <param name="AMacroEnd">宏定义结束字符</param>
    /// <param name="AFlags">标志位，可取 MRF_IN_DBL_QUOTER 和 MRF_IN_SINGLE_QUOTER 的组合</param>
    /// <returns>编译成功，返回编译中间结果句柄，失败，返回空，返回的TQComplied可以直接用Free释放</returns>
    function Complie(AText: QStringW; AMacroStart, AMacroEnd: QStringW;
      const AFlags: Integer = MRF_ENABLE_ESCAPE): TQMacroComplied;
    /// <summary>使用指定的编译结果执行一次替换操作</summary>
    /// <param name="AHandle">使用Complie函数编译的中间结果</param>
    /// <returns>返回替换结果</returns>

    function Replace(AHandle: TQMacroComplied): QStringW; overload;
    /// <summary>使用宏定义替换指定的文本</summary>
    /// <param name="AText">要被替换的文本</param>
    /// <param name="AMacroStart">宏定义起始字符，可以与结束字符不同</param>
    /// <param name="AMacroEnd">宏定义结束字符</param>
    /// <param name="AFlags">标志位，可取 MRF_IN_DBL_QUOTER 和 MRF_IN_SINGLE_QUOTER 的组合</param>
    /// <returns>返回替换完成的结果字符串</returns>
    function Replace(const AText: QStringW; AMacroStart, AMacroEnd: QStringW;
      const AFlags: Integer = MRF_ENABLE_ESCAPE): QStringW; overload;
    /// <summary>获指指定名称的宏的当前值，如果未找到，抛出异常</summary>
    /// <param name="AName">宏名称</param>
    /// <returns>返回指定的宏的当前值</returns>
    function MacroValue(const AName: QStringW): QStringW; overload;
    procedure SetTestNameEnd(const Value: TQMacroNameTestEventG); overload;
    procedure SetTestNameStart(const Value: TQMacroNameTestEventG); overload;
    procedure SetMacroMissed(AHandler: TQMacroMissEventG); overload;
{$IFDEF UNICODE}
    procedure SetTestNameEnd(const Value: TQMacroNameTestEventA); overload;
    procedure SetTestNameStart(const Value: TQMacroNameTestEventA); overload;
    procedure SetMacroMissed(AHandler: TQMacroMissEventA); overload;
{$ENDIF}
    /// <summary>宏个数</summary>
    property Count: Integer read GetCount;
    /// <summary>宏列表</summary>
    property Items[AIndex: Integer]: TQMacroItem read GetItems; default;
    /// <summary>名称是否区分大小写</summary>
    property IgnoreCase: Boolean read FIgnoreCase write FIgnoreCase;
    /// <summary>指定名称宏的值，如果不存在，返回空字符串</summary>
    property Values[AName: QStringW]: QStringW read GetValues;
    /// <summary>在宏未找到触发该事件，你可以在该事件中为其赋默认值</summary>
    property OnMacroMissed: TQMacroMissEvent read FOnMacroMissed
      write SetOnMacroMissed;
    property OnTestNameStart: TQMacroNameTestEvent read FOnTestNameStart
      write SetOnTestNameStart;
    property OnTestNameEnd: TQMacroNameTestEvent read FOnTestNameEnd
      write SetOnTestNameEnd;
    property BooleanAsInt: Boolean read FBooleanAsInt write FBooleanAsInt;
  end;

implementation

resourcestring
  SMacroValueUnknown = '指定的宏 %s 的值未定义。';
  SMacroNotFound = '指定的宏 %s 未定义。';
  STagNotClosed = '指定的宏 %s 的结束标签未找到。';
  SMacroStartNeeded = '只定义了宏结束字符串而未指定宏定义开始字符串。';
  SBadFileFormat = '无效的QMacros预编译缓存数据。';
  STagNameMissed = '第 %d 行 %d 列宏名称未指定:'#13#10'%s'#13#10;
  SCharNeeded = '当前位置应该是 "%s" ，而不是 "%s"。';

  { TQMacroManager }
type
  TQMacroCompliedFileHeader = record
    Flags: Int64;
    Version: Integer; // 版本号
    Count: Integer; // 结果数量
    MinSize: Integer; //
    Volatiles: Integer;
    TextLength: Integer;
  end;

  TQMacoCompliedFileItem = record
    Start: Integer;
    Length: Integer;
    Quoter: QCharW;
    IsMacro: Boolean;
  end;

  TQMacroDataSetIterator = class(TQMacroIterator)
  protected
    FDataSet: TDataSet;
    FComplied: TQMacroComplied;
    function HasNext: Boolean; override;
    procedure BeginReplace(AMacro: TQMacroItem); override;
    function Replace: QStringW; override;
    procedure EndReplace; override;
  public
    constructor Create(ADataSet: TDataSet); overload;
    destructor Destroy; override;
  end;

procedure FreeMacroValue(AValue: PQMacroValue); // inline;
begin
{$IFDEF UNICODE}
  if TMethod(AValue.OnFetchValue).Data = Pointer(-1) then
    PQMacroValueFetchEventA(@TMethod(AValue.OnFetchValue).Code)^ := nil;
{$ENDIF}
  Dispose(AValue);
end;

function EventEqual(AHandler1, AHandler2: TMethod): Boolean;
begin
  Result := (AHandler1.Code = AHandler2.Code) and
    (AHandler1.Data = AHandler2.Data);
end;

function TQMacroManager.CharUnescape(var p: PQCharW): QCharW;
  function DecodeOrd: Integer;
  var
    C: Integer;
  begin
    Result := 0;
    C := 0;
    while (p^ <> #0) and (C < 4) do
    begin
      if IsHexChar(p^) then
        Result := (Result shl 4) + HexValue(p^)
      else
        Break;
      Inc(p);
      Inc(C);
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
    'b':
      begin
        Result := #7;
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
      end;
    '/':
      begin
        Result := '/';
        Inc(p);
      end
  else
    begin
      Result := '\';
      // Result := p^;
      // Inc(p);
    end;
  end;
end;

procedure TQMacroManager.Clear;
var
  I: Integer;
begin
  for I := 0 to FMacroes.Count - 1 do
    FreeObject(FMacroes[I]);
  FMacroes.Clear;
  FSavePoint := 0;
end;

const
  QMERR_TAG_BEGIN_NEEDED = 1;
  QMERR_TAG_NOT_CLOSED = 2;
  QMERR_MACRO_NOT_FOUND = 3;

function TQMacroManager.Complie(AText: QStringW;
  AMacroStart, AMacroEnd: QStringW; const AFlags: Integer): TQMacroComplied;
begin
  Result := nil;
  InternalComplie(Result, AText, AMacroStart, AMacroEnd, AFlags);
end;

constructor TQMacroManager.Create;
begin
  inherited Create;
  FMacroes := TMacroList.Create;
end;

function TQMacroManager.DateTimeToStr(ADateTime: TDateTime): String;
var
  T: Integer;
begin
  T := Trunc(ADateTime);
  if T = 0 then
    Result := FormatDateTime('hh:nn:ss.zzz', ADateTime)
  else if IsZero(ADateTime - T) then
    Result := FormatDateTime('yyyy-mm-dd', ADateTime)
  else
    Result := FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz', ADateTime);
end;

destructor TQMacroManager.Destroy;
begin
  Clear;
  FreeObject(FMacroes);
{$IFDEF UNICODE}
  if TMethod(OnMacroMissed).Data = Pointer(-1) then
    TQMacroMissEventA(TMethod(FOnMacroMissed).Code) := nil;
{$ENDIF}
  inherited;
end;

procedure TQMacroManager.DoFetchFieldQuotedValue(AMacro: TQMacroItem;
  const AQuoter: QCharW);
var
  AField: TField;
begin
  AField := TField(AMacro.Value.Tag);
  if AField <> nil then
  begin
    if AField.IsNull then
      AMacro.Value.Value := 'NULL'
    else if AField is TDateTimeField then
      AMacro.Value.Value := '''' + DateTimeToStr(AField.AsDateTime) + ''''
    else
    begin
      if BooleanAsInt and (AField is TBooleanField) then
      begin
        if AField.AsBoolean then
          AMacro.Value.Value := '''1'''
        else
          AMacro.Value.Value := '''0''';
      end
      else
        AMacro.Value.Value := QuotedStrW(AField.AsString, '''');
    end;
  end;
end;

procedure TQMacroManager.DoFetchFieldValue(AMacro: TQMacroItem;
  const AQuoter: QCharW);
var
  AField: TField;
begin
  AField := TField(AMacro.Value.Tag);
  if AField <> nil then
  begin
    if AField.IsNull then
      AMacro.Value.Value := 'NULL'
    else if AField is TDateTimeField then
      AMacro.Value.Value := DateTimeToStr(AField.AsDateTime)
    else
    begin
      if BooleanAsInt and (AField is TBooleanField) then
      begin
        if AField.AsBoolean then
          AMacro.Value.Value := '1'
        else
          AMacro.Value.Value := '0';
      end
      else
        AMacro.Value.Value := AField.AsString;
    end;
  end;
end;

procedure TQMacroManager.DoFetchIterator(AMacro: TQMacroItem;
  const AQuoter: QCharW);
var
  ABuilder: TQStringCatHelperW;
begin
  if Assigned(AMacro.Value.Iterator) then
  begin
    with AMacro.Value.Iterator do
    begin
      ABuilder := TQStringCatHelperW.Create;
      BeginReplace(AMacro);
      try
        while HasNext do
          ABuilder.Cat(Replace);
        AMacro.Value.Value := ABuilder.Value;
      finally
        FreeAndNil(ABuilder);
        EndReplace;
      end;
    end;
  end;
end;

procedure TQMacroManager.DoFetchIteratorIndex(AMacro: TQMacroItem;
  const AQuoter: QCharW);
var
  AIterator: IQMacroIterator;
begin
  AIterator := IQMacroIterator(AMacro.Value.Tag);
  AMacro.Value.Value := IntToStr(AIterator.GetItemIndex);
end;

procedure TQMacroManager.DoFetchRecordNo(AMacro: TQMacroItem;
  const AQuoter: QCharW);
var
  ADataSet: TDataSet;
begin
  ADataSet := TDataSet(AMacro.Value.Tag);
  AMacro.Value.Value := IntToStr(ADataSet.RecNo);
end;

procedure TQMacroManager.DoFetchValue(AMacro: TQMacroItem;
  const AQuoter: QCharW);
begin
  if TMethod(AMacro.Value.OnFetchValue).Data = nil then
    TQMacroValueFetchEventG(TMethod(AMacro.Value.OnFetchValue).Code)
      (AMacro, AQuoter)
{$IFDEF UNICODE}
  else if TMethod(AMacro.Value.OnFetchValue).Data = Pointer(-1) then
    TQMacroValueFetchEventA(TMethod(AMacro.Value.OnFetchValue).Code)
      (AMacro, AQuoter)
{$ENDIF}
  else
    AMacro.Value.OnFetchValue(AMacro, AQuoter);
end;

function TQMacroManager.DoMacroMissed(AName: QStringW;
  const AQuoter: QCharW): Boolean;
begin
  Result := False;
  if TMethod(FOnMacroMissed).Code <> nil then
  begin
    if TMethod(FOnMacroMissed).Data = nil then
      TQMacroMissEventG(TMethod(FOnMacroMissed).Code)
        (Self, AName, AQuoter, Result)
{$IFDEF UNICODE}
    else if IntPtr(TMethod(FOnMacroMissed).Data) = -1 then
      TQMacroMissEventA(TMethod(FOnMacroMissed).Code)
        (Self, AName, AQuoter, Result)
{$ENDIF}
    else
      FOnMacroMissed(Self, AName, AQuoter, Result);
  end;
end;

function TQMacroManager.Find(const AName: QStringW;
  var AIndex: Integer): Boolean;
var
  L, H, I, C: Integer;
begin
  Result := False;
  L := 0;
  H := FMacroes.Count - 1;
  while L <= H do
  begin
    I := (L + H) shr 1;
    C := StrCmpW(PQCharW(Items[I].Name), PQCharW(AName), IgnoreCase);
    if C < 0 then
      L := I + 1
    else
    begin
      H := I - 1;
      if C = 0 then
      begin
        Result := True;
        L := I;
      end;
    end;
  end;
  AIndex := L;
end;

function TQMacroManager.GetCount: Integer;
begin
  Result := FMacroes.Count;
end;

function TQMacroManager.GetItems(AIndex: Integer): TQMacroItem;
begin
  Result := FMacroes[AIndex];
end;

function TQMacroManager.GetValues(AName: QStringW): QStringW;
begin
  if InternalMacroValue(AName, #0, Result) <> 0 then
    Result := '';
end;

function TQMacroManager.IncW(p: PQCharW; ALen: Integer): PQCharW;
begin
  Inc(p, ALen);
  Result := p;
end;

function TQMacroManager.IndexOf(const AName: QStringW): Integer;
begin
  if not Find(AName, Result) then
    Result := -1;
end;

procedure TQMacroManager.InternalComplie(var AResult: TQMacroComplied;
  AText, AMacroStart, AMacroEnd: QStringW; const AFlags: Integer);
var
  LS, LE, AIndex: Integer;
  prs, pts, p, ps, pms, pme, pl: PQCharW;
  AItem: PQMacroCompliedItem;
  AQuoter: QCharW;
  // AMacro: TQMacroItem;
  AName: QStringW;
  AIsNewResult: Boolean;
  ANameStarted: Boolean;
  function IsMacroEndChar: Boolean;
  begin
    if (AFlags and MRF_END_WITH_INVALID_CHAR) <> 0 then
      Result := not(((p^ >= '0') and (p^ <= '9')) or
        ((p^ >= 'A') and (p^ <= 'Z')) or ((p^ >= 'a') and (p^ <= 'z')) or
        (p^ > #$7F))
    else
      Result := StartWithW(p, pme, False);
  end;

  function MacroCharType(var ALen: Integer): TQMacroCharType;
  begin
    Result := mctChar;
    if ANameStarted then
    begin
      if TMethod(OnTestNameEnd).Code <> nil then
      begin
        if TMethod(OnTestNameEnd).Data = nil then
          TQMacroNameTestEventG(TMethod(OnTestNameEnd).Code)
            (Self, p, ALen, Result)
{$IFDEF UNICODE}
        else if TMethod(OnTestNameEnd).Data = Pointer(-1) then
          TQMacroNameTestEventA(TMethod(OnTestNameEnd).Code)
            (Self, p, ALen, Result)
{$ENDIF}
        else
          OnTestNameEnd(Self, p, ALen, Result);
      end
      else if IsMacroEndChar then
        Result := mctNameEnd;
    end
    else
    begin
      if TMethod(OnTestNameStart).Code <> nil then
      begin
        if TMethod(OnTestNameStart).Data = nil then
          TQMacroNameTestEventG(TMethod(OnTestNameStart).Code)
            (Self, p, ALen, Result)
{$IFDEF UNICODE}
        else if TMethod(OnTestNameStart).Data = Pointer(-1) then
          TQMacroNameTestEventA(TMethod(OnTestNameStart).Code)
            (Self, p, ALen, Result)
{$ENDIF}
        else
          OnTestNameStart(Self, p, ALen, Result);
      end
      else if CompareMem(p, pms, LS shl 1) then
        Result := mctNameStart;
    end;
    case Result of
      mctNameStart:
        ANameStarted := True;
      mctNameEnd:
        ANameStarted := False;
    end;
  end;

  procedure TestMacro;
  var
    pq: PQCharW;
    ALine, ACol: Integer;
    AParams: QStringW;
  begin
    if MacroCharType(LS) = mctNameStart then //
    begin
      if ps <> p then
      begin
        AItem := @AResult.Items[AResult.Count];
        AItem.Start := prs;
        Inc(AItem.Start, (IntPtr(ps) - IntPtr(pts)) shr 1);
        AItem.Length := (IntPtr(p) - IntPtr(ps)) shr 1;
        AItem.Quoter := #0;
        AItem.Macro := nil;
        AItem.IsMacro := False;
        if (AFlags and MRF_ENABLE_ESCAPE) <> 0 then
          AItem.Text := Unescape(AItem.Start, AItem.Length)
        else
          AItem.Text := StrDupX(AItem.Start, AItem.Length);
        Inc(AResult.FCount);
        Inc(AResult.FMinSize, AItem.Length);
      end;
      pl := p;
      Inc(p, LS);
      ps := p;
      while (p^ <> #0) and (MacroCharType(LE) <> mctNameEnd) do
      begin
        if (p^ = '''') or (p^ = '"') then
        begin
          pq := p;
          Inc(p);
          while p^ <> #0 do
          begin
            if p^ = pq^ then
            begin
              Inc(p);
              Break;
            end
            else
              Inc(p);
          end;
        end
        else if (p^ = '\') and ((AFlags and MRF_ENABLE_ESCAPE) <> 0) then
        // 处理转义支持
        begin
          Inc(p);
          if p^ <> #0 then
            Inc(p);
        end
        else
          Inc(p);
      end;
      if (p^ = #0) and ((AFlags and MRF_END_WITH_INVALID_CHAR) = 0) then
        raise Exception.CreateFmt(STagNotClosed, [StrDupW(ps, 0, 20) + '...'])
      else if p = ps then
      begin
        ps := StrPosW(pts, p, ACol, ALine);
        AName := DecodeLineW(ps);
        raise Exception.CreateFmt(STagNameMissed, [ALine, ACol, AName]);
      end
      else
      begin
        if (AFlags and MRF_ENABLE_ESCAPE) <> 0 then
          AName := Unescape(ps, (IntPtr(p) - IntPtr(ps)) shr 1)
        else
          AName := StrDupX(ps, (IntPtr(p) - IntPtr(ps)) shr 1);
        if (AFlags and MRF_PARSE_PARAMS) <> 0 then
        begin
          AParams := ValueOfW(AName, '(');
          if EndWithW(AParams, ')', True) then // OK
          begin
            AName := NameOfW(AName, '(');
            SetLength(AParams, Length(AParams) - 1);
            AParams := '[' + AParams + ']'; // JSON数组模式
          end
          else
            SetLength(AParams, 0);
        end;
        if not Find(AName, AIndex) then
        begin
          if (AFlags and MRF_IGNORE_MISSED) <> 0 then
          begin
            ps := pl;
            Inc(p, LE);
            Exit;
          end
          else if not DoMacroMissed(AName, AQuoter) then
          begin
            if (AFlags and MRF_DELAY_BINDING) <> 0 then
              AIndex := -1
            else
              raise Exception.CreateFmt(SMacroNotFound, [AName]);
          end;
        end;
        AItem := @AResult.Items[AResult.Count];
        AItem.Start := prs;
        Inc(AItem.Start, (IntPtr(ps) - IntPtr(pts)) shr 1);
        AItem.Length := Length(AName);
        AItem.IsMacro := True;
        AItem.Quoter := AQuoter;
        AItem.Text := AName;
        if Length(AParams) > 0 then
        begin
          AItem.Params := TQJson.Create;
          AItem.Params.TryParse(AParams);
        end;
        if AIndex <> -1 then
        begin
          AItem.Macro := Items[AIndex];
          if AItem.Macro.Value.Volatile = mvImmutable then
            Inc(AResult.FMinSize, Length(AItem.Macro.Value.Value))
          else
            Inc(AResult.FVolatiles);
        end
        else
        begin
          AItem.Macro := nil;
          Inc(AResult.FDelayCount);
          Inc(AResult.FVolatiles); // 包含延迟绑定的项目无法预先确定类型
        end;
        Inc(AResult.FCount);
        Inc(p, LE);
        ps := p;
      end;
    end // End Macro Found
    else if (p^ = '\') and ((AFlags and MRF_ENABLE_ESCAPE) <> 0) then
      CharUnescape(p)
    else
      Inc(p);
  end;
  procedure ParseInQuoter;
  begin
    AQuoter := p^;
    Inc(p);
    while p^ <> #0 do
    begin
      if p^ = AQuoter then
      begin
        Inc(p);
        AQuoter := #0;
        Break;
      end
      else
        TestMacro;
    end;
  end;
  procedure ParseWithBoundary;
  begin
    while p^ <> #0 do
    begin
      if (p^ = '''') then
      begin
        if (AFlags and MRF_IN_SINGLE_QUOTER) = 0 then
        begin
          Inc(p);
          while (p^ <> #0) and (p^ <> '''') do
            Inc(p);
          if p^ = '''' then
            Inc(p);
        end
        else
          ParseInQuoter;
      end
      else if p^ = '"' then
      begin
        if (AFlags and MRF_IN_DBL_QUOTER) = 0 then
        begin
          Inc(p);
          while (p^ <> #0) and (p^ <> '"') do
            Inc(p);
          if p^ = '"' then
            Inc(p);
        end
        else
          ParseInQuoter;
      end
      else // No Quoted
        TestMacro;
    end;
    if p <> ps then
    begin
      AItem := @AResult.Items[AResult.Count];
      AItem.Start := prs;
      Inc(AItem.Start, (IntPtr(ps) - IntPtr(pts)) shr 1);
      AItem.Length := (IntPtr(p) - IntPtr(ps)) shr 1;
      AItem.Quoter := #0;
      AItem.Macro := nil;
      AItem.IsMacro := False;
      if (AFlags and MRF_ENABLE_ESCAPE) <> 0 then
        AItem.Text := Unescape(AItem.Start, AItem.Length)
      else
        AItem.Text := StrDupX(AItem.Start, AItem.Length);
      Inc(AResult.FCount);
      Inc(AResult.FMinSize, AItem.Length);
    end;
  end;
  function MacroStartWith: TQMacroItem;
  var
    L, H, I, C: Integer;
  begin
    L := 0;
    H := FMacroes.Count - 1;
    while L <= H do
    begin
      I := (L + H) shr 1;
      Result := Items[I];
      C := StrNCmpW(PQCharW(Result.Name), p, IgnoreCase, Length(Result.Name));
      if C < 0 then
        L := I + 1
      else
      begin
        H := I - 1;
        if C = 0 then
          Exit;
      end;
    end;
    Result := nil;
  end;

// 没有分隔符的情况下，只能采用二分法查找，可怜的娃
  procedure ParseWithNoBoundary;
  var
    AMacro: TQMacroItem;
  begin
    while p^ <> #0 do
    begin
      AMacro := MacroStartWith;
      if Assigned(AMacro) then
      begin
        if p <> ps then
        begin
          AItem := @AResult.Items[AResult.Count];
          AItem.Start := prs;
          Inc(AItem.Start, (IntPtr(ps) - IntPtr(pts)) shr 1);
          AItem.Length := (IntPtr(p) - IntPtr(ps)) shr 1;
          if (AFlags and MRF_ENABLE_ESCAPE) <> 0 then
            AItem.Text := Unescape(AItem.Start, AItem.Length)
          else
            AItem.Text := StrDupX(AItem.Start, AItem.Length);
          AItem.Quoter := #0;
          AItem.Macro := nil;
          AItem.IsMacro := False;
          Inc(AResult.FCount);
          Inc(AResult.FMinSize, AItem.Length);
        end;
        AItem := @AResult.Items[AResult.Count];
        AItem.Start := prs;
        Inc(AItem.Start, (IntPtr(ps) - IntPtr(pts)) shr 1);
        AItem.Length := Length(AMacro.Name);
        AItem.Macro := AMacro;
        AItem.IsMacro := True;
        AItem.Quoter := AQuoter;
        AItem.Text := AMacro.Name;
        if AMacro.Value.Volatile = mvImmutable then
          Inc(AResult.FMinSize, Length(AItem.Macro.Value.Value))
        else
          Inc(AResult.FVolatiles);
        Inc(AResult.FCount);
        Inc(p, Length(AMacro.Name));
        ps := p;
      end
      else
        Inc(p);
    end;
    if p <> ps then
    begin
      AItem := @AResult.Items[AResult.Count];
      AItem.Start := prs;
      Inc(AItem.Start, (IntPtr(ps) - IntPtr(pts)) shr 1);
      AItem.Length := (IntPtr(p) - IntPtr(ps)) shr 1;
      AItem.Quoter := #0;
      AItem.Macro := nil;
      AItem.IsMacro := False;
      if (AFlags and MRF_ENABLE_ESCAPE) <> 0 then
        AItem.Text := Unescape(AItem.Start, AItem.Length)
      else
        AItem.Text := StrDupX(AItem.Start, AItem.Length);
      Inc(AResult.FCount);
      Inc(AResult.FMinSize, AItem.Length);
    end;
  end;

begin
  LS := Length(AMacroStart);
  ANameStarted := False;
  if (AFlags and MRF_END_WITH_INVALID_CHAR) = 0 then
  begin
    LE := Length(AMacroEnd);
    if LE = 0 then
    begin
      AMacroEnd := AMacroStart;
      LE := LS;
    end;
  end
  else
    LE := 0;
  if LS = 0 then
  begin
    if LE <> 0 then
      raise Exception.Create(SMacroStartNeeded);
  end;
  if not Assigned(AResult) then
  begin
    AResult := TQMacroComplied.Create(Self);
    AResult.FText := AText;
    AResult.FMinSize := 0;
    AResult.FCount := 0;
    AResult.FVolatiles := 0;
    AIsNewResult := True;
  end
  else
    AIsNewResult := False;
  AResult.FPushId := FLastPushId;
  AResult.FMacroStart := AMacroStart;
  AResult.FMacroEnd := AMacroEnd;
  if Length(AText) = 0 then
    SetLength(AResult.FItems, 0)
  else
  begin
    try
      if IgnoreCase then
      begin
        AText := UpperCase(AText);
        AMacroStart := UpperCase(AMacroStart);
        AMacroEnd := UpperCase(AMacroEnd);
      end;
      SetLength(AResult.FItems, 4096);
      // 假设需要4096项
      ps := PQCharW(AText);
      p := ps;
      pts := ps;
      AQuoter := #0;
      prs := PQCharW(AResult.FText);
      if LS = 0 then
        ParseWithNoBoundary
      else
      begin
        pms := PQCharW(AMacroStart);
        pme := PQCharW(AMacroEnd);
        ParseWithBoundary;
      end;
    except
      if AIsNewResult then
        FreeObject(AResult);
      raise;
    end;
  end;
  AResult.FFlags := AFlags;
  SetLength(AResult.FItems, AResult.Count);
end;

function TQMacroManager.InternalMacroValue(const AName: QStringW;
  const AQuoter: QCharW; var AValue: QStringW): Integer;
var
  AIdx: Integer;
  AItem: TQMacroItem;
begin
  if Find(AName, AIdx) then
  begin
    AItem := Items[AIdx];
    if not Assigned(AItem.Value) then
      Result := 1
    else
    begin
      Result := 0;
      if AItem.Value.Volatile = mvImmutable then
        AValue := AItem.Value.Value
      else if TMethod(AItem.Value.OnFetchValue).Code <> nil then
      begin
        DoFetchValue(AItem, AQuoter);
        AValue := AItem.Value.Value;
      end
      else
        Result := 1;
    end
  end
  else
  begin
    if not DoMacroMissed(AName, AQuoter) then
      Result := 2
    else
      Result := InternalMacroValue(AName, AQuoter, AValue);
  end;
end;

procedure TQMacroManager.InternalPush(AMacro: TQMacroItem;
  const AValue: QStringW; AOnFetch: TQMacroValueFetchEvent;
  AStable: TQMacroVolatile; ATag: IntPtr);
var
  ALast: PQMacroValue;
begin
  New(ALast);
  ALast.Value := AValue;
  ALast.OnFetchValue := AOnFetch;
  ALast.Prior := AMacro.FValue;
  ALast.Next := nil;
  ALast.SavePoint := FSavePoint;
  ALast.Volatile := AStable;
  ALast.Tag := ATag;
  ALast.ReplaceId:=FReplaceId;
  if Assigned(AMacro.FValue) then
    AMacro.FValue.Next := ALast;
  AMacro.FValue := ALast;
  if (AStable = mvImmutable) and (TMethod(AOnFetch).Code <> nil) then
    AOnFetch(AMacro, #0);
  // 固定的值是常量，始终不变
  Inc(FLastPushId);
end;

function TQMacroManager.MacroValue(const AName: QStringW): QStringW;
begin
  Result := MacroValue(AName, QCharW(#0));
end;

function TQMacroManager.MacroValue(const AName: QStringW; const AQuoter: QCharW)
  : QStringW;
begin
  case InternalMacroValue(AName, AQuoter, Result) of
    1: //
      raise Exception.CreateFmt(SMacroValueUnknown, [AName]);
    2:
      raise Exception.CreateFmt(SMacroNotFound, [AName]);
  end;
end;

procedure TQMacroManager.Pop(const AName: QStringW);
var
  AIndex: Integer;
  AItem: TQMacroItem;
  AValue: PQMacroValue;
begin
  if Find(AName, AIndex) then
  begin
    AItem := Items[AIndex];
    if Assigned(AItem.Value.Prior) then
    begin
      AValue := AItem.Value;
      case AValue.Volatile of
        mvStable:
          Dec(FStableCount);
        mvVolatile:
          Dec(FVolatileCount);
      end;
      if Assigned(AValue.Iterator) then
        Pop(AName + '.@Index');
      AItem.FValue := AItem.Value.Prior;
      Dispose(AValue);
      if AItem.FValue = nil then
        FMacroes.Delete(AIndex);
    end;
    Inc(FLastPushId);
  end;
end;

function TQMacroManager.Push(const AName: QStringW;
  AOnFetchValue: TQMacroValueFetchEvent; AVolatile: TQMacroVolatile;
  ATag: IntPtr): TQMacroItem;
var
  AIndex: Integer;
begin
  if not Find(AName, AIndex) then
  begin
    Result := TQMacroItem.Create(Self);
    Result.FName := AName;
    InternalPush(Result, '', AOnFetchValue, AVolatile, ATag);
    FMacroes.Insert(AIndex, Result);
  end
  else
  begin
    Result := Items[AIndex];
    InternalPush(Result, '', AOnFetchValue, AVolatile, ATag);
  end;
  Inc(FLastPushId);
end;

function TQMacroManager.Push(const AName, AValue: QStringW): TQMacroItem;
var
  AIndex: Integer;
begin
  if not Find(AName, AIndex) then
  begin
    Result := TQMacroItem.Create(Self);
    Result.FName := AName;
    InternalPush(Result, AValue, nil, mvImmutable, 0);
    FMacroes.Insert(AIndex, Result);
  end
  else
  begin
    Result := Items[AIndex];
    InternalPush(Result, AValue, nil, mvImmutable, 0);
  end;
end;

function TQMacroManager.Replace(const AText: QStringW;
  AMacroStart, AMacroEnd: QStringW; const AFlags: Integer): QStringW;
var
  ATemp: TQMacroComplied;
begin
  ATemp := Complie(AText, AMacroStart, AMacroEnd, AFlags);
  try
    Result := Replace(ATemp);
  finally
    FreeObject(ATemp);
  end;
end;

function TQMacroManager.Replace(AHandle: TQMacroComplied): QStringW;
  procedure SimpleReplace;
  var
    I, L: Integer;
    pd: PQCharW;
    AItem: PQMacroCompliedItem;
  begin
    if Length(AHandle.FReplacedText) <> 0 then
      Result := AHandle.FReplacedText
    else
    begin
      SetLength(Result, AHandle.MinSize);
      I := 0;
      pd := PQCharW(Result);
      while I < AHandle.Count do
      begin
        AItem := @AHandle.Items[I];
        if AItem.Macro = nil then
        begin
          L := Length(AItem.Text);
          Move(PQCharW(AItem.Text)^, pd^, L shl 1);
          Inc(pd, L);
        end
        else
        begin
          L := Length(AItem.Macro.Value.Value);
          Move(PQCharW(AItem.Macro.Value.Value)^, pd^, L shl 1);
          Inc(pd, L);
        end;
        Inc(I);
      end;
      AHandle.FReplacedText := Result;
    end;
  end;

  procedure LowReplace;
  var
    I, L, AOffset, ASize: Integer;
    pd: PQCharW;
    AItem: PQMacroCompliedItem;
  begin
    L := AHandle.MinSize shl 1;
    if L < 4096 then
      L := 4096;
    SetLength(Result, L);
    I := 0;
    AOffset := 0;
    pd := PQCharW(Result);
    while I < AHandle.Count do
    begin
      AItem := @AHandle.Items[I];
      if AItem.IsMacro then
      begin
        case AItem.Macro.Value.Volatile of
          mvStable:
            begin
              if AItem.Macro.Value.ReplaceId <> FReplaceId then
              begin
                DoFetchValue(AItem.Macro, AItem.Quoter);
                AItem.Macro.Value.ReplaceId := FReplaceId;
              end;
            end;
          mvVolatile:
            begin
              AItem.Macro.FParams := AItem.Params;
              DoFetchValue(AItem.Macro, AItem.Quoter);
            end;
        end;
        ASize := Length(AItem.Macro.Value.Value);
        if AOffset + ASize > L then
        begin
          Inc(L, ((ASize div 4096) + 1) * 4096);
          SetLength(Result, L);
          pd := PQCharW(Result);
          Inc(pd, AOffset);
        end;
        Move(PQCharW(AItem.Macro.Value.Value)^, pd^, ASize shl 1);
        Inc(AOffset, ASize);
        Inc(pd, ASize);
      end
      else
      begin
        ASize := Length(AItem.Text);
        if AOffset + ASize > L then
        begin
          Inc(L, ((ASize div 4096) + 1) * 4096);
          SetLength(Result, L);
          pd := PQCharW(Result);
          Inc(pd, AOffset);
        end;
        Move(PQCharW(AItem.Text)^, pd^, ASize shl 1);
        Inc(AOffset, ASize);
        Inc(pd, ASize);
      end;
      Inc(I);
    end;
    SetLength(Result, AOffset);
  end;

begin
  Inc(FReplaceId);
  if AHandle.Count = 0 then
    SetLength(Result, 0)
  else
  begin
    if (AHandle.FPushId <> FLastPushId) or (AHandle.FDelayCount > 0) then
    begin
      AHandle.CheckMacros;
      AHandle.FPushId := FLastPushId;
    end;
    if AHandle.Volatiles = 0 then
      SimpleReplace
    else
      LowReplace;
  end;
end;

procedure TQMacroManager.Restore(ASavePoint: Integer);
var
  I, APopCount: Integer;
  AMacro: TQMacroItem;
  AValue: PQMacroValue;
begin
  if ASavePoint >= 0 then
  begin
    I := 0;
    APopCount := 0;
    while I < FMacroes.Count do
    begin
      AMacro := Items[I];
      while (AMacro.Value <> nil) and (AMacro.Value.SavePoint > ASavePoint) do
      begin
        AValue := AMacro.Value.Prior;
        FreeMacroValue(AMacro.Value);
        AMacro.FValue := AValue;
        Inc(APopCount);
      end;
      if AMacro.FValue = nil then // 全部出栈了
      begin
        FreeObject(AMacro);
        FMacroes.Delete(I);
      end
      else
        Inc(I);
    end;
    FSavePoint := ASavePoint;
    if APopCount > 0 then
      Inc(FLastPushId);
  end;
end;

function TQMacroManager.SavePoint: Integer;
begin
  Result := FSavePoint;
  Inc(FSavePoint);
end;

procedure TQMacroManager.SetOnMacroMissed(AHandler: TQMacroMissEvent);
begin
  if not EventEqual(TMethod(AHandler), TMethod(FOnMacroMissed)) then
  begin
{$IFDEF UNICODE}
    if TMethod(FOnMacroMissed).Data = Pointer(-1) then
      TQMacroMissEventA(TMethod(FOnMacroMissed).Code) := nil;
{$ENDIF}
    FOnMacroMissed := AHandler;
  end;
end;

procedure TQMacroManager.SetOnTestNameEnd(const Value: TQMacroNameTestEvent);
begin
  if not EventEqual(TMethod(Value), TMethod(FOnTestNameEnd)) then
  begin
{$IFDEF UNICODE}
    if TMethod(FOnTestNameEnd).Data = Pointer(-1) then
      TQMacroNameTestEventA(TMethod(FOnTestNameEnd).Code) := nil;
{$ENDIF}
    FOnTestNameEnd := Value;
  end;
end;

procedure TQMacroManager.SetOnTestNameStart(const Value: TQMacroNameTestEvent);
begin
  if not EventEqual(TMethod(Value), TMethod(FOnTestNameStart)) then
  begin
{$IFDEF UNICODE}
    if TMethod(FOnTestNameStart).Data = Pointer(-1) then
      TQMacroNameTestEventA(TMethod(FOnTestNameStart).Code) := nil;
{$ENDIF}
    FOnTestNameStart := Value;
  end;
end;

procedure TQMacroManager.Pop(ADataSet: TDataSet; const ANameSpace: QStringW);
var
  I: Integer;
begin
  if Length(ANameSpace) = 0 then
  begin
    for I := 0 to ADataSet.FieldCount - 1 do
      Pop(ADataSet.Fields[I].FieldName);
    if Length(ADataSet.Name) > 0 then
    begin
      Pop(ADataSet.Name + '.@Rows');
      Pop(ADataSet.Name + '.@RecNo');
    end;
  end
  else
  begin
    for I := 0 to ADataSet.FieldCount - 1 do
      Pop(ANameSpace + '.' + ADataSet.Fields[I].FieldName);
    if Length(ADataSet.Name) > 0 then
    begin
      Pop(ANameSpace + '.' + ADataSet.Name + '.Rows');
      Pop(ANameSpace + '.' + ADataSet.Name + '.@RecNo');
    end;
  end;
end;

procedure TQMacroManager.Push(ADataSet: TDataSet; const ANameSpace: QStringW);
var
  I: Integer;
  AField: TField;
begin
  if Length(ANameSpace) = 0 then
  begin
    for I := 0 to ADataSet.FieldCount - 1 do
    begin
      AField := ADataSet.Fields[I];
      Push(AField.FieldName, DoFetchFieldValue, mvVolatile, IntPtr(AField));
      Push(AField.FieldName + '.Quoted', DoFetchFieldQuotedValue, mvVolatile,
        IntPtr(AField));
    end;
    if Length(ADataSet.Name) > 0 then
    begin
      Push(ADataSet.Name + '.@Rows', TQMacroDataSetIterator.Create(ADataSet),
        mvVolatile);
      Push(ADataSet.Name + '.@RecNo', DoFetchRecordNo, mvVolatile,
        IntPtr(ADataSet));
    end;
  end
  else
  begin
    for I := 0 to ADataSet.FieldCount - 1 do
    begin
      AField := ADataSet.Fields[I];
      Push(ANameSpace + '.' + AField.FieldName, DoFetchFieldValue, mvVolatile,
        IntPtr(AField));
      Push(ANameSpace + '.' + AField.FieldName + '.Quoted',
        DoFetchFieldQuotedValue, mvVolatile, IntPtr(AField));
    end;
    if Length(ADataSet.Name) > 0 then
    begin
      Push(ANameSpace + '.' + ADataSet.Name + '.@Rows',
        TQMacroDataSetIterator.Create(ADataSet), mvVolatile);
      Push(ANameSpace + '.' + ADataSet.Name + '.@RecNo', DoFetchRecordNo,
        mvVolatile, IntPtr(ADataSet));
    end;
  end;
end;

function TQMacroManager.Push(const AName: QStringW;
  AOnFetchValue: TQMacroValueFetchEventG; AVolatile: TQMacroVolatile;
  ATag: IntPtr): TQMacroItem;
var
  AHandler: TQMacroValueFetchEvent;
begin
  if Assigned(AOnFetchValue) then
  begin
    TMethod(AHandler).Code := @AOnFetchValue;
    TMethod(AHandler).Data := nil;
    Result := Push(AName, AHandler, AVolatile, ATag);
  end
  else
    Result := Push(AName, TQMacroValueFetchEvent(nil), AVolatile, ATag);
end;
{$IFDEF UNICODE}

function TQMacroManager.Push(const AName: QStringW;
  AOnFetchValue: TQMacroValueFetchEventA; AVolatile: TQMacroVolatile;
  ATag: IntPtr): TQMacroItem;
var
  AHandler: TQMacroValueFetchEvent;
begin
  if Assigned(AOnFetchValue) then
  begin
    AHandler := nil;
    PQMacroValueFetchEventA(@TMethod(AHandler).Code)^ := AOnFetchValue;
    TMethod(AHandler).Data := Pointer(-1);
    Result := Push(AName, AHandler, AVolatile, ATag);
  end
  else
    Result := Push(AName, TQMacroValueFetchEvent(nil), AVolatile, ATag);
end;

procedure TQMacroManager.SetMacroMissed(AHandler: TQMacroMissEventA);
var
  AEvent: TQMacroMissEvent;
begin
  TMethod(AEvent).Data := Pointer(-1);
  TMethod(AEvent).Code := nil;
  PQMacroMissEventA(@TMethod(AEvent).Code)^ := AHandler;
  SetOnMacroMissed(AEvent);
end;
{$ENDIF}

procedure TQMacroManager.SetMacroMissed(AHandler: TQMacroMissEventG);
var
  AEvent: TQMacroMissEvent;
begin
  TMethod(AEvent).Data := nil;
  TQMacroMissEventG(TMethod(AEvent).Code) := AHandler;
  SetOnMacroMissed(AEvent);
end;
{$IFDEF UNICODE}

procedure TQMacroManager.SetTestNameEnd(const Value: TQMacroNameTestEventA);
var
  AEvent: TQMacroNameTestEvent;
begin
  TMethod(AEvent).Data := Pointer(-1);
  TMethod(AEvent).Code := nil;
  PQMacroNameTestEventA(@TMethod(AEvent).Code)^ := Value;
  SetOnTestNameEnd(AEvent);
end;
{$ENDIF}

procedure TQMacroManager.SetTestNameEnd(const Value: TQMacroNameTestEventG);
var
  AEvent: TQMacroNameTestEvent;
begin
  TMethod(AEvent).Data := nil;
  TQMacroNameTestEventG(TMethod(AEvent).Code) := Value;
  SetOnTestNameEnd(AEvent);
end;

procedure TQMacroManager.SetTestNameStart(const Value: TQMacroNameTestEventG);
var
  AEvent: TQMacroNameTestEvent;
begin
  TMethod(AEvent).Data := nil;
  TQMacroNameTestEventG(TMethod(AEvent).Code) := Value;
  SetOnTestNameStart(AEvent);
end;
{$IFDEF UNICODE}

procedure TQMacroManager.SetTestNameStart(const Value: TQMacroNameTestEventA);
var
  AEvent: TQMacroNameTestEvent;
begin
  TMethod(AEvent).Data := Pointer(-1);
  TMethod(AEvent).Code := nil;
  PQMacroNameTestEventA(@TMethod(AEvent).Code)^ := Value;
  SetOnTestNameStart(AEvent);
end;

{$ENDIF}

function TQMacroManager.Unescape(p: PQCharW; ALen: Integer): QStringW;
var
  pe, pd: PQCharW;
begin
  SetLength(Result, ALen);
  if ALen > 0 then
  begin
    pd := PQCharW(Result);
    pe := p;
    Inc(pe, ALen);
    while p < pe do
    begin
      pd^ := CharUnescape(p);
      Inc(pd);
    end;
    SetLength(Result, (IntPtr(pd) - IntPtr(PQCharW(Result))) shr 1);
  end;
end;

function TQMacroManager.Unescape(const S: QStringW): QStringW;
begin
  Result := Unescape(PQCharW(S), Length(S));
end;

function TQMacroManager.Push(const AName: QStringW; AIterator: IQMacroIterator;
  AVolatile: TQMacroVolatile; ATag: IntPtr): TQMacroItem;
begin
  Result := Push(AName, DoFetchIterator, AVolatile, ATag);
  Result.FValue.Iterator := AIterator;
  Push(AName + '.@Index', DoFetchIteratorIndex, mvVolatile, IntPtr(AIterator));
end;

{ TQMacroItem }

constructor TQMacroItem.Create(AOwner: TQMacroManager);
begin
  inherited Create;
  FOwner := AOwner;
end;

destructor TQMacroItem.Destroy;
var
  AValue: PQMacroValue;
begin
  while FValue <> nil do
  begin
    AValue := FValue;
    FValue := FValue.Prior;
    FreeMacroValue(AValue);
  end;
  inherited;
end;

{ TQMacroComplied }

procedure TQMacroComplied.CheckMacros;
var
  I: Integer;
  AItem: PQMacroCompliedItem;
begin
  SetLength(FReplacedText, 0);
  I := 0;
  FVolatiles := 0;
  FMinSize := 0;
  while I < FCount do
  begin
    AItem := @FItems[I];
    if AItem.IsMacro then
    begin
      if not Assigned(AItem.Macro) then
        Dec(FDelayCount);
      AItem.Macro := MacroNeeded(AItem.Text);
      if AItem.Macro.Value.Volatile <> mvImmutable then
        Inc(FVolatiles)
      else
        Inc(FMinSize, Length(AItem.Macro.Value.Value));
    end
    else
      Inc(FMinSize, AItem.Length);
    Inc(I);
  end;
end;

function TQMacroComplied.Complie(AText, AMacroStart, AMacroEnd: QStringW;
  const AFlags: Integer): Boolean;
var
  AResult: TQMacroComplied;
begin
  try
    AResult := Self;
    FOwner.InternalComplie(AResult, AText, AMacroStart, AMacroEnd, AFlags);
    Result := True;
  except
    Result := False;
  end;
end;

constructor TQMacroComplied.Create(AOwner: TQMacroManager);
begin
  inherited Create;
  FOwner := AOwner;
end;

destructor TQMacroComplied.Destroy;
var
  I: Integer;
begin
  for I := 0 to High(FItems) do
  begin
    if Assigned(Items[I].Params) then
      FreeAndNil(Items[I].Params);
  end;
  inherited;
end;

function TQMacroComplied.EnumUsedMacros(AList: TStrings): Integer;
var
  T: TStringList;
  I, J: Integer;
  S: String;
begin
  T := TStringList.Create;
  try
    T.Sorted := True;
    for I := 0 to High(Items) do
    begin
      if Items[I].IsMacro then
      begin
        if Items[I].Macro <> nil then
          S := Items[I].Macro.Name
        else
          S := Items[I].Text;
        if not T.Find(S, J) then
          T.Add(S);
      end;
    end;
    AList.AddStrings(T);
    Result := T.Count;
  finally
    FreeObject(T);
  end;
end;

procedure TQMacroComplied.LoadFromFile(const AFileName: QStringW);
var
  AStream: TMemoryStream;
begin
  AStream := TMemoryStream.Create;
  try
    AStream.LoadFromFile(AFileName);
    LoadFromStream(AStream);
  finally
    FreeObject(AStream);
  end;
end;

procedure TQMacroComplied.LoadFromStream(AStream: TStream);
var
  AHeader: TQMacroCompliedFileHeader;
  AItemHeader: TQMacoCompliedFileItem;
  I: Integer;
  ps: PQCharW;
  AItem: PQMacroCompliedItem;
begin
  AStream.ReadBuffer(AHeader, SizeOf(AHeader));
  if AHeader.Flags = MFF_FILETYPE then
  begin
    SetLength(FText, AHeader.TextLength);
    AStream.ReadBuffer(PQCharW(FText)^, AHeader.TextLength shl 1);
    FMinSize := AHeader.MinSize;
    FCount := AHeader.Count;
    FVolatiles := AHeader.Volatiles;
    SetLength(FReplacedText, 0);
    ps := PQCharW(FText);
    SetLength(FItems, FCount);
    for I := 0 to FCount - 1 do
    begin
      AStream.ReadBuffer(AItemHeader, SizeOf(AItemHeader));
      AItem := @FItems[I];
      AItem^.Start := ps + AItemHeader.Start;
      AItem^.Length := AItemHeader.Length;
      AItem^.Quoter := AItemHeader.Quoter;
      AItem^.IsMacro := AItemHeader.IsMacro;
      AItem^.Text := StrDupX(AItem^.Start, AItem^.Length);
      if AItemHeader.IsMacro then
        FItems[I].Macro := MacroNeeded(AItem^.Text);
    end;
    FPushId := FOwner.FLastPushId;
  end
  else
    raise Exception.Create(SBadFileFormat);
end;

function TQMacroComplied.MacroNeeded(const AName: QStringW): TQMacroItem;
var
  AIndex: Integer;
begin
  if FOwner.Find(AName, AIndex) then
    Result := FOwner.Items[AIndex]
  else
    raise Exception.CreateFmt(SMacroNotFound, [AName]);
end;

function TQMacroComplied.Replace: QStringW;
begin
  Result := FOwner.Replace(Self);
end;

procedure TQMacroComplied.SaveToFile(const AFileName: QStringW);
var
  AStream: TMemoryStream;
begin
  AStream := TMemoryStream.Create;
  try
    SaveToStream(AStream);
    AStream.SaveToFile(AFileName);
  finally
    FreeObject(AStream);
  end;
end;

procedure TQMacroComplied.SaveToStream(AStream: TStream);
var
  AHeader: TQMacroCompliedFileHeader;
  AItemHeader: TQMacoCompliedFileItem;
  I: Integer;
  ps: PQCharW;
begin
  AHeader.Flags := MFF_FILETYPE;
  AHeader.Version := 1;
  AHeader.Count := FCount;
  AHeader.MinSize := FMinSize;
  AHeader.Volatiles := FVolatiles;
  AHeader.TextLength := Length(FText);
  AStream.WriteBuffer(AHeader, SizeOf(AHeader));
  AStream.WriteBuffer(PQCharW(FText)^, AHeader.TextLength shl 1);
  ps := PQCharW(FText);
  for I := 0 to FCount - 1 do
  begin
    AItemHeader.Start := FItems[I].Start - ps;
    AItemHeader.Length := FItems[I].Length;
    AItemHeader.Quoter := FItems[I].Quoter;
    AItemHeader.IsMacro := FItems[I].IsMacro;
    AStream.WriteBuffer(AItemHeader, SizeOf(AItemHeader));
  end;
end;

{ TQMacroDataSetIterator }
// XXX(Format,MacroStart,MacroEnd)
procedure TQMacroDataSetIterator.BeginReplace(AMacro: TQMacroItem);
begin
  FDataSet.DisableControls;
  FItemIndex := -1;
  if AMacro <> FMacro then
  begin
    FMacro := AMacro;
    if Assigned(FComplied) then
      FreeAndNil(FComplied);
    if Assigned(AMacro.Params) and (AMacro.Params.Count = 3) then
      FComplied := AMacro.Owner.Complie(AMacro.Params[0].AsString,
        AMacro.Params[1].AsString, AMacro.Params[2].AsString);
  end;
end;

constructor TQMacroDataSetIterator.Create(ADataSet: TDataSet);
begin
  inherited Create;
  FDataSet := ADataSet;
end;

destructor TQMacroDataSetIterator.Destroy;
begin
  if Assigned(FComplied) then
    FreeAndNil(FComplied);
  inherited;
end;

procedure TQMacroDataSetIterator.EndReplace;
begin
  FDataSet.EnableControls;
end;

function TQMacroDataSetIterator.HasNext: Boolean;
begin
  if FItemIndex = -1 then
    FDataSet.First
  else
    FDataSet.Next;
  Inc(FItemIndex);
  Result := not FDataSet.Eof;
end;

function TQMacroDataSetIterator.Replace: QStringW;
begin
  if Assigned(FComplied) then
    Result := FComplied.Replace
  else
    Result := '';
end;

{ TQMacroStringsIterator }

procedure TQMacroStringsIterator.BeginReplace(AMacro: TQMacroItem);
begin
  FItemIndex := -1;
  FHasNext := FList.Count > 0;
  if AMacro <> FMacro then
  begin
    FMacro := AMacro;
    if Assigned(FComplied) then
      FreeAndNil(FComplied);
    if Assigned(AMacro.Params) and (AMacro.Params.Count = 3) then
      FComplied := AMacro.Owner.Complie(AMacro.Params[0].AsString,
        AMacro.Params[1].AsString, AMacro.Params[2].AsString);
  end;
end;

constructor TQMacroStringsIterator.Create(AList: TStrings);
begin
  inherited Create;
  FList := AList;
end;

destructor TQMacroStringsIterator.Destroy;
begin
  if Assigned(FComplied) then
    FreeAndNil(FComplied);
  inherited;
end;

function TQMacroStringsIterator.HasNext: Boolean;
begin
  Result := FHasNext;
  Inc(FItemIndex);
  FHasNext := FItemIndex + 1 < FList.Count;
end;

function TQMacroStringsIterator.Replace: QStringW;
begin
  if Assigned(FComplied) then
    Result := FComplied.Replace
  else
    Result := '';
end;

{ TQMacroIterator }

procedure TQMacroIterator.BeginReplace(AMacro: TQMacroItem);
begin
  FMacro := AMacro;
  FItemIndex := 0;
end;

constructor TQMacroIterator.Create;
begin
  inherited Create;
  FItemIndex := -1;
end;

procedure TQMacroIterator.EndReplace;
begin

end;

function TQMacroIterator.GetItemIndex: Integer;
begin
  Result := FItemIndex;
end;

function TQMacroIterator.HasNext: Boolean;
begin
  Result := false;
end;

function TQMacroIterator.Replace: QStringW;
begin
  Result := '';
end;

end.
