unit qplugins_menusvc;

interface

uses classes, sysutils, qplugins_base;

const
  MC_CAPTION = $01;
  MC_ICON = $02;
  MC_VISIBLE = $04;
  MC_ENABLED = $08;
  MC_EXTS = $10;
  MC_ALIGN = $20;
  MC_CHILDREN = $40;

type

  IQMenuCategory = interface;

  // 图片支持
  /// <summary>
  /// 图片支持接口，用于跨语言支持图片显示
  /// </summary>
  /// <remarks>
  /// IQImage 支持的常见的位图文件格式，如PNG/JPG，但并不支持编辑，不管原数据格式是啥格式，保存时都会按PNG格式保存。 要创建一个
  /// IQImage 接口的实例，使用路径 /Services/Images 下的服务，调用 NewImage 接口创建新的对象。
  /// 注意：本单元只包含接口声明，不包含实际实现
  /// </remarks>
  IQImage = interface
    ['{013129AD-B177-4D9F-818A-45E09ADDC2ED}']
    /// <summary>
    /// 从流中加载图片
    /// </summary>
    /// <param name="AStream">
    /// 保存图片的数据流对象
    /// </param>
    procedure LoadFromStream(AStream: IQStream); stdcall;

    /// <summary>
    /// 以 PNG 格式保存图片到流中
    /// </summary>
    /// <param name="AStream">
    /// 目标数据流
    /// </param>
    procedure SaveToStream(AStream: IQStream); stdcall;
    /// <summary>
    /// 从文件中加载图片
    /// </summary>
    /// <param name="AFileName">
    /// 图片文件名
    /// </param>
    /// <remarks>
    /// 从文件中加载图片时，是通过扩展名来确定文件格式的，所以请保证扩展名与实际格式一致。
    /// </remarks>
    procedure LoadFromFile(const AFileName: PWideChar); stdcall;
    /// <summary>
    /// 保存图片数据到PNG文件中
    /// </summary>
    /// <param name="AFileName">
    /// 目标文件名
    /// </param>
    /// <remarks>
    /// 请确认目标目录有写入权限，否则会无法保存
    /// </remarks>
    procedure SaveToFile(const AFileName: PWideChar); stdcall;
    /// <summary>
    /// 从 Base64 编码字符串
    /// </summary>
    /// <param name="ABase64Data">
    /// 以 Base 64 编码的图片数据
    /// </param>
    procedure LoadFromBase64(const ABase64Data: IQString); stdcall;
    /// <summary>
    /// 保存为 PNG 格式的 Base64 字符串
    /// </summary>
    /// <returns>
    /// 返回值实际类型为IQString，为兼容非 Delphi 语言，改为返回 Pointer，用户需要自行减小引用计数
    /// </returns>
    function SaveToBase64: Pointer; stdcall;
    /// <summary>
    /// 获取内部图像的实际宽度
    /// </summary>
    function GetWidth: Integer; stdcall;
    /// <summary>
    /// 获取内部图像的实际高度
    /// </summary>
    function GetHeight: Integer; stdcall;
    /// <summary>
    /// 以 IQBytes 接口获取PNG格式的数据
    /// </summary>
    /// <param name="AData">
    /// 用于存贮结果数据的缓冲区对象
    /// </param>
    function GetData(AData: IQBytes): Integer; stdcall;
    /// <summary>
    /// 获取图像对象末次变更的Id，每加载一次图片，该ID变更一次，以便上层检查图片内容是否发生变动
    /// </summary>
    function GetLastChangeId: Integer; stdcall;
    /// <summary>
    /// 从另一个图片中复制一份拷贝
    /// </summary>
    procedure Assign(ASource: IQImage); stdcall;
    /// <summary>
    /// 图片末次变更ID
    /// </summary>
    property LastChangeId: Integer read GetLastChangeId;
  end;

  /// <summary>
  /// 菜单（IQMenuItem） 和分类 （IQMenuCategory ）的基类，用于管理菜单类型项目的公有成员
  /// </summary>
  IQMenuBase = interface
    /// <summary>
    /// 菜单内部Id，每个菜单项目拥有唯一的编码
    /// </summary>
    function GetId: Integer; stdcall;
    /// <summary>
    /// 获取菜单的内部名称，
    /// </summary>
    function GetName: PWideChar; stdcall;
    /// <summary>
    /// 设置菜单名称
    /// </summary>
    /// <param name="AName">
    /// 菜单的名称
    /// </param>
    /// <remarks>
    /// 该名称实际上是一个内部标志，调用者应避免重复
    /// </remarks>
    procedure SetName(AName: PWideChar); stdcall;

    /// <summary>
    /// 获取菜单显示标题
    /// </summary>
    /// <remarks>
    /// 如果要支持多语言，则需要响应 Language.Changed 通知调用 SetCaption 重新设置标题
    /// </remarks>
    function GetCaption: PWideChar; stdcall;
    /// <summary>
    /// 设置菜单标题
    /// </summary>
    /// <param name="S">
    /// 标题内容
    /// </param>
    procedure SetCaption(const S: PWideChar); stdcall;

    /// <summary>
    /// 获取菜单的启用状态
    /// </summary>
    function GetEnabled: Boolean; stdcall;
    /// <summary>
    /// 设置菜单项目的启用状态
    /// </summary>
    /// <param name="val">
    /// true -&gt; 启用 false-&gt;禁用
    /// </param>
    procedure SetEnabled(const val: Boolean); stdcall;

    /// <summary>
    /// 获取菜单项目是否可见
    /// </summary>
    function GetVisible: Boolean; stdcall;
    /// <summary>
    /// 设置菜单项目是否可见
    /// </summary>
    /// <param name="val">
    /// true-&gt;可见，false-&gt;不可见
    /// </param>
    procedure SetVisible(const val: Boolean); stdcall;

    /// <summary>
    /// 判断是否包含扩展参数列表
    /// </summary>
    function HasExtParams: Boolean; stdcall;

    /// <summary>
    /// 获取扩展参数列表
    /// </summary>
    /// <remarks>
    /// 扩展参数列表提供了不修改系统服务的情况下，添加额外数据成员的办法，其它模块可以往内部添加自己的参数标志，以建立关联。
    /// </remarks>
    function GetExtParams: Pointer; stdcall;

    /// <summary>
    /// 菜单当前状态发生变更时，会触发该接口。
    /// </summary>
    /// <remarks>
    /// Invalidate 函数触发 MenuService.Validate 通知，程序可以订阅该通知以便进行处理。该通知的 @Sender
    /// 参数为菜单实例的 IQMenuBase 接口地址（类型为 64 位整数）
    /// </remarks>
    procedure Invalidate; stdcall;
    /// <summary>
    /// 获取菜单末次内容的ID，以便快速判断菜单内容是否发生了变动
    /// </summary>
    function GetLastChangeId: Integer; stdcall;
    /// <summary>
    /// 获取自己在父中的索引
    /// </summary>
    /// <remarks>
    /// 父对象为IQMenuCategory类型
    /// </remarks>
    function GetItemIndex: Integer; stdcall;
    /// <summary>
    /// 获取父分类对象接口实例，如果是根分类，则为空
    /// </summary>
    /// <returns>
    /// 实际类型为IQMenuCategory，注意使用完成要减小接口的引用计数
    /// </returns>
    /// <seealso cref="IQMenuCategory">
    /// 父接口类型
    /// </seealso>
    function GetParent: Pointer; stdcall; // IQMenuCategory

    /// <summary>
    /// 获取项目关联的图片接口实例
    /// </summary>
    /// <returns>
    /// 返回 IQImage 接口实例，注意使用完成接口要减少引用计数
    /// </returns>
    /// <seealso cref="IQImage">
    /// 图像接口
    /// </seealso>
    function GetImage: Pointer; stdcall; // IQImage
    /// <summary>
    /// 设置关联图片实例
    /// </summary>
    /// <param name="AImage">
    /// 新的图片实例
    /// </param>
    /// <remarks>
    /// 如果在关联后，直接修改实例的图片内容，并不会触发刷新，需要手动调用菜单项的Invalidate来通知菜单服务更新相应的图标。否则可能会使用旧图标显示。
    /// </remarks>
    /// <seealso cref="IQImage">
    /// 图像接口
    /// </seealso>
    procedure SetImage(AImage: IQImage); stdcall;

    function GetTag: Pointer; stdcall;
    procedure SetTag(const V: Pointer); stdcall;
    function GetChanges: Integer; stdcall;
    procedure BeginUpdate; stdcall;
    procedure EndUpdate; stdcall;
    /// <summary>
    /// 项目标题
    /// </summary>
    property Caption: PWideChar read GetCaption write SetCaption;
    /// <summary>
    /// 是否启用
    /// </summary>
    property Enabled: Boolean read GetEnabled write SetEnabled;
    /// <summary>
    /// 是否显示
    /// </summary>
    property Visible: Boolean read GetVisible write SetVisible;
    /// <summary>
    /// 父分类接口
    /// </summary>
    property Parent: Pointer read GetParent;
    /// <summary>
    /// 项目名称
    /// </summary>
    property Name: PWideChar read GetName write SetName;
    /// <summary>
    /// 扩展参数
    /// </summary>
    property ExtParams: Pointer read GetExtParams;
    /// <summary>
    /// 项目索引
    /// </summary>
    property ItemIndex: Integer read GetItemIndex;
    /// <summary>
    /// 末次变更ID
    /// </summary>
    property LastChangeId: Integer read GetLastChangeId;
    property Tag: Pointer read GetTag write SetTag;
    property Changes: Integer read GetChanges;
  end;

  /// <summary>
  /// 菜单类型
  /// </summary>
  TQMenuCheckType = (
    /// <summary>
    /// 普通菜单
    /// </summary>
    None,
    /// <summary>
    /// 单选菜单，同一分类下的单选菜单中，只能有一个被选中
    /// </summary>
    Radio,
    /// <summary>
    /// 复选菜单
    /// </summary>
    CheckBox);
  TImageAlignLayout = (alNone, alTop, alLeft, alRight, alBottom, alMostTop,
    alMostBottom, alMostLeft, alMostRight, alClient, alContents, alCenter,
    alVertCenter, alHorzCenter, alHorizontal, alVertical, alScale, alFit,
    alFitLeft, alFitRight);

  /// <summary>
  /// 菜单项目接口
  /// </summary>
  IQMenuItem = interface(IQMenuBase)
    ['{6C53B06C-EA0E-4020-A303-1DBE74755E42}']
    /// <summary>
    /// 图片对齐方式 ，默认左对齐
    /// </summary>
    /// <returns>
    /// TAlignLayout 的值序列为{None=0, Top, Left, Right, Bottom, MostTop,
    /// MostBottom, MostLeft, MostRight, Client, Contents, Center,
    /// VertCenter, HorzCenter, Horizontal, Vertical, Scale, Fit, FitLeft,
    /// FitRight}，默认为Left
    /// </returns>
    function GetImageAlign: TImageAlignLayout; stdcall;

    /// <summary>
    /// 设置图片的对齐方式
    /// </summary>
    /// <param name="Align">
    /// 新的对齐方式
    /// </param>
    /// <remarks>
    /// 如果是单选或复选菜单，默认布局则单选或复选框在最左侧，然后是图片，最后是文字。可以通过设置它，来调整图片的位置。
    /// </remarks>
    procedure SetImageAlign(const Align: TImageAlignLayout); stdcall;
    /// <summary>
    /// 获取菜单项目单击的响应广播 IQNotifyBroadcast 接口实例
    /// </summary>
    /// <returns>
    /// 实际为 IQNotifyBroadcast 类型的接口地址，用户可以调用其 Add 方法添加响应，用 Remove 移除响应
    /// </returns>
    /// <remarks>
    /// Click 函数会调用此接口，通过 Send 来发送通知给所有的响应者
    /// </remarks>
    /// <seealso cref="IQNotifyBroadcast">
    /// QPlugins 的通知广播接口
    /// </seealso>
    function GetOnClick: Pointer; stdcall; // IQNotifyBroadcastor
    /// <summary>
    /// 模拟点击指定的菜单项目
    /// </summary>
    /// <param name="AParams">
    /// 传递给响应接口的参数
    /// </param>
    procedure Click(AParams: IQParams); stdcall;
    /// <summary>
    /// 获取当前菜单项目是否已经选中
    /// </summary>
    function GetIsChecked: Boolean; stdcall;
    /// <summary>
    /// 设置当前菜单项目是否选中
    /// </summary>
    procedure SetIsChecked(const Value: Boolean); stdcall;
    /// <summary>
    /// 获取菜单项目类型
    /// </summary>
    /// <seealso cref="TQMenuCheckType">
    /// 菜单项目类型
    /// </seealso>
    function GetCheckType: TQMenuCheckType; stdcall;
    /// <summary>
    /// 设置菜单项目类型
    /// </summary>
    /// <param name="AType">
    /// 新的类型
    /// </param>
    procedure SetCheckType(const AType: TQMenuCheckType); stdcall;
    /// <summary>
    /// 菜单图标对齐方式
    /// </summary>
    property ImageAlign: TImageAlignLayout read GetImageAlign
      write SetImageAlign;
    /// <summary>
    /// 当前 菜单项目类型
    /// </summary>
    /// <exception cref="TQMenuCheckType">
    /// 菜单项目类型
    /// </exception>
    property CheckType: TQMenuCheckType read GetCheckType write SetCheckType;
    /// <summary>
    /// 是否选中
    /// </summary>
    property IsChecked: Boolean read GetIsChecked write SetIsChecked;
  end;

  /// <summary>
  /// 菜单项目分类，用于管理多个菜单及子分类
  /// </summary>
  /// <remarks>
  /// 菜单分类一般不推荐太多级数，一般菜单项目显示区域有限，每一级分类都需要缩进一定的距离，以保证视觉效果。
  /// </remarks>
  IQMenuCategory = interface(IQMenuBase)
    ['{FC2909CF-7AD2-450F-B02A-7372886BA43E}']
    /// <summary>
    /// 获取分类是否处于展开的状态
    /// </summary>
    function GetIsExpanded: Boolean; stdcall;
    /// <summary>
    /// 设置分类是否展开
    /// </summary>
    procedure SetIsExpanded(const val: Boolean); stdcall;
    /// <summary>
    /// 为分类添加子菜单项目
    /// </summary>
    /// <returns>
    /// 返回的实际接口类型是IQMenuItem，注意用完要减少引用计数
    /// </returns>
    function AddMenu(const AName, ACaption: PWidechar): Pointer; stdcall;
    /// <summary>
    /// 添加一个子分类
    /// </summary>
    /// <returns>
    /// 返回的实际接口类型是 IQMenuCategory，注意用完要减少引用计数
    /// </returns>
    function AddCategory(const AName, ACaption: PWidechar): Pointer; stdcall;
    /// <summary>
    /// 删除指定索引的子项
    /// </summary>
    /// <param name="AIndex">
    /// 要删除的子项索引
    /// </param>
    procedure Delete(AIndex: Integer); stdcall;
    /// <summary>
    /// 清除所有的子项
    /// </summary>
    procedure Clear; stdcall;
    /// <summary>
    /// 查找指定的子项的索引序号
    /// </summary>
    /// <returns>
    /// 成功返回 &gt;=0 的索引序号，失败，返回-1
    /// </returns>
    function IndexOf(AItem: IQMenuBase): Integer; overload; stdcall;
    /// <summary>
    /// 查找指定名称的子项目索引序号
    /// </summary>
    /// <param name="AName">
    /// 要查找的项目的名称，注意区分大小写
    /// </param>
    /// <returns>
    /// 成功返回 &amp;gt;=0 的索引序号，失败，返回-1
    /// </returns>
    function IndexOf(AName: PWideChar): Integer; overload; stdcall;
    /// <summary>
    /// 获取总的子项数量
    /// </summary>
    function GetCount: Integer; stdcall;

    /// <summary>
    /// 获取指定索引的子项接口实例地址
    /// </summary>
    /// <param name="AIndex">
    /// 要获取的子项接口索引
    /// </param>
    /// <returns>
    /// 返回的接口实例为 IQMenuBase 接口，注意不要直接转换为 IQMenuItem 或
    /// IQMenuCategory，应按相应的规范调用。
    /// </returns>
    function GetItems(const AIndex: Integer): Pointer; stdcall;
    /// <summary>
    /// 子项数量，只读
    /// </summary>
    property Count: Integer read GetCount;
    /// <summary>
    /// 是否处于展开状态
    /// </summary>
    property IsExpanded: Boolean read GetIsExpanded write SetIsExpanded;
    /// <summary>
    /// 子项列表
    /// </summary>
    /// <param name="AIndex">
    /// 子项索引
    /// </param>
    /// <value>
    /// 返回的接口实例为 IQMenuBase 接口，注意不要直接转换为 IQMenuItem 或
    /// IQMenuCategory，应按相应的规范调用。
    /// </value>
    property Items[const AIndex: Integer]: Pointer read GetItems; default;
  end;

  /// <summary>
  /// 菜单服务提供者接口
  /// </summary>
  /// <remarks>
  /// <para>
  /// 在菜单项目发生变动或被点击触发时，会生成一系列通知，包括：
  /// </para>
  /// <list type="bullet">
  /// <item>
  /// MenuService.ItemClicked ： 菜单项目被点击,@Sender 参数为被点击的菜单项目
  /// </item>
  /// <item>
  /// MenuService.ItemAdded ： 有项目加入，@Sender 参数为新加的菜单项目
  /// </item>
  /// <item>
  /// MenuService.ItemDeleted ：有项目被删除，@Sender 是已被删除的项目
  /// </item>
  /// <item>
  /// MenuService.ItemCleared ： 所有的子项都被清理掉了，@sender 参数是被清理的分类对象
  /// </item>
  /// <item>
  /// MenuService.ItemExpand ：当一个分类被展开时触发，@Sender 参数为分类对象
  /// </item>
  /// <item>
  /// MenuService.Validate：当一个菜单项目无效时被触发，@Sender 参数为失效的菜单类实像例
  /// </item>
  /// <item>
  /// MenuService.Iconic：当整个菜单在图标和正常状态切换时触发，IsIconic 参数指定了新的状态
  /// </item>
  /// </list>
  /// <para>
  /// 上述通知中，@Sender 的类型为64位整数，指向的是 IQMenuBase 类型的接口的地址。
  /// </para>
  /// </remarks>
  IQMenuService = interface
    ['{EDAE42E6-C53E-4407-862C-AFB4AA910336}']
    /// <summary>
    /// 添加一个分类
    /// </summary>
    /// <returns>
    /// 实际返回的接口类型为 IQMenuCategory，注意使用完成需要减小引用计数
    /// </returns>
    function AddCategory(const AName, ACaption: PWidechar): Pointer; stdcall;
    /// <summary>
    /// 删除指定索引的项目
    /// </summary>
    /// <param name="AIndex">
    /// 要删除的接口索引
    /// </param>
    procedure Delete(AIndex: Integer); stdcall;
    /// <summary>
    /// 清除所有的项目
    /// </summary>
    procedure Clear; stdcall;
    /// <summary>获取指定路径的项目地址，路径分隔符以/分隔</summary>
    /// <returns>返回对应的路径的IQMenuBase实例地址</returns>
    function ItemByPath(APath: PWideChar): Pointer; stdcall; // IQMenuBase
    /// <summary>强制创建指定分类路径，路径分隔符以/分隔</summary>
    /// <returns>返回对应的路径的IQMenuBase实例地址</returns>
    function ForceCategories(APath: PWideChar): Pointer; stdcall;
    // IQMenuCategory
    /// <summary>
    /// 获取指定分类的索引
    /// </summary>
    /// <param name="ACategory">
    /// 要获取的子分类接口
    /// </param>
    function IndexOf(ACategory: IQMenuCategory): Integer; stdcall;
    /// <summary>
    /// 获取子分类数量
    /// </summary>
    function GetCount: Integer; stdcall;
    /// <summary>
    /// 获取指定索引的子分类接口实例地址
    /// </summary>
    /// <param name="AIndex">
    /// 子分类索引
    /// </param>
    /// <returns>
    /// 实际返回的接口类型为IQMenuCategory，注意使用完成后释放接口引用计数
    /// </returns>
    function GetItems(const AIndex: Integer): Pointer; stdcall;
    /// <summary>
    /// 获取当前是否处于图标状态
    /// </summary>
    /// <remarks>
    /// 图标状态下，所有的子项会被收起，只显示根分类的图标列表
    /// </remarks>
    function GetIsIconic: Boolean; stdcall;
    /// <summary>
    /// 设置当前是否处于图标状态
    /// </summary>
    procedure SetIsIconic(const value: Boolean); stdcall;
    /// <summary>
    /// 子分类数量
    /// </summary>
    property Count: Integer read GetCount;
    /// <summary>
    /// 子分类项目
    /// </summary>
    /// <param name="AIndex">
    /// 子分类项目索引
    /// </param>
    property Items[const AIndex: Integer]: Pointer read GetItems; default;
    /// <summary>
    /// 是否处于图标状态
    /// </summary>
    property IsIconic: Boolean read GetIsIconic write SetIsIconic;
  end;

  /// <summary>
  /// 图片服务，注册路径为 /Services/Images
  /// </summary>
  IQImageService = interface(IQService)
    ['{4C44E9DD-14A2-4FFF-9003-FC88F4EBA291}']
    /// <summary>
    /// 获取一个新的IQImage实例
    /// </summary>
    /// <returns>
    /// 返回的是 IQImage 类型的接口地址，注意使用完成减少引用计数
    /// </returns>
    function NewImage: Pointer; stdcall;
  end;

const
  MenuServiceRoot: PWideChar = '\Services\Menus';
  ImageServiceRoot: PWideChar = '\Services\Images';

implementation

end.
