/// <summary>
/// <para>
/// IQSecurityService 是用于实现用户账号及权限管理的服务。 其它依赖于此模块的服务可以通过此服务，
/// 获取当前用户的信息，以及当前用户是否被授权访问指定权限对象信息。
/// </para>
/// <para>
/// IQSecurityService 的注册服务路径为
/// /Services/Security，可以通过该路径或服务ID获取到该服务的管理实例。
/// </para>
/// <para>
/// IQSecurityService 不提供账号的添加、删除账号及角色等服务，要执行该类型的操作，调用 IQSecurityService
/// 的 Config 来弹出账号及权限管理界面，由用户手动操作。
/// </para>
/// <para>
/// 本单元包含可授权对象接口、用户账号、 用户角色及它们的父接口的定义，并不包含实际实现。
/// </para>
/// </summary>
unit qplugins_security;

interface

uses classes, sysutils, types, qplugins_base;

const
  // 角色及权限管理分组ID
  SID_SECURITY_GROUP: TGuid = '{110CA18E-4B52-4D75-B3F3-9C99DC2B76FE}';
  // 查看其它用户账号及权限
  SID_SECURITY_VIEW: TGuid = '{B02A4134-3563-42A0-825E-C90BB5DD031E}'; //
  // 修改其它用户账号及权限等资料
  SID_SECURITY_EDIT: TGuid = '{800896A0-E733-48BB-8CB4-857EC83F6F89}';
  // 通知：会话结束
  SNotify_SessionDead = 'Security.Session.Dead';
  // 通知：会话就绪
  SNotify_SessionReady = 'Security.Session.Ready';
  // 通知：当前账号权限发生变动
  SNotify_RightsChanged = 'Security.Session.RightsChanged';
  // 通知：当前登录操作被取消
  SNotify_LoginCanceled = 'Security.Login.Cancel';

type
  IQSecurityUserBase = interface;
  IQSecurityGroup = interface;

  IQObjectInterface = interface
    ['{C1E8B65C-9BAD-4F33-B97A-88BDCB768EF7}']
    /// <summary>
    /// 获取当前实例原始对象地址
    /// </summary>
    function GetObjectPointer: Pointer; stdcall;
  end;

  /// <summary>
  /// 安全服务对象的基础接口，所有的安全对象都继承自此接口
  /// </summary>
  /// <remarks>
  /// 安全接口用于提供服务给其它模块，以便其它模块能够检查用户权限并处理登录等事宜。
  /// </remarks>
  IQSecurityBase = interface(IQObjectInterface)
    ['{BA55D0A8-CC00-40A5-8FD6-0743DD1145A7}']
    /// <summary>
    /// 获取安全对象的名称
    /// </summary>
    function GetName: PWideChar; stdcall;
    /// <summary>
    /// 获取安全对象的编码，安全对象编码固定为GUID类型，以便方便各个功能自己定义自己的ID，而不会与其它功能定义重复
    /// </summary>
    /// <param name="AId">
    /// 用于存贮安全对象的编码
    /// </param>
    procedure GetId(AId: PGuid); stdcall;
    /// <summary>
    /// 获取安全对象的父对象
    /// </summary>
    function GetParent: Pointer; stdcall;
    /// <summary>
    /// 获取当前安全对象的注解
    /// </summary>
    function GetComment: PWideChar; stdcall;
    /// <summary>
    /// 获取当前安全的扩展信息，这些信息不会存贮到数据库中，只在运行时随时设置和删除，实际类型为IQParams
    /// </summary>
    function GetExts: Pointer; stdcall;
    /// <summary>
    /// 获取当前是否是某个父的子结点
    /// </summary>
    function IsChildOf(AParent: IQSecurityGroup): Boolean; stdcall;
    /// <summary>
    /// 获取当前是否是某个子的父结点
    /// </summary>
    function IsParentOf(AChild: IQSecurityBase): Boolean; stdcall;
    /// <summary>
    /// 名称
    /// </summary>
    property Name: PWideChar read GetName;
    /// <summary>
    /// 注解
    /// </summary>
    property Comment: PWideChar read GetComment;
    /// <summary>
    /// 父安全对象(IQSecurityGroup)
    /// </summary>
    property Parent: Pointer read GetParent; // IQSecurityGroup
    /// <summary>
    /// 扩展
    /// </summary>
    property Exts: Pointer read GetExts;
  end;

  /// <summary>
  /// 角色和权限对象的父接口，
  /// </summary>
  IQSecurityGroup = interface(IQSecurityBase)
    ['{18712A8C-6152-45C9-B7AE-9265A62D8E36}']
    /// <summary>
    /// 获取指定的ID对应的子安全对象索引
    /// </summary>
    /// <param name="AId">
    /// 子对象ID
    /// </param>
    function IndexOf(const AId: PGuid): Integer; overload; stdcall;
    /// <summary>
    /// 获取指定名称的子安全对象索引
    /// </summary>
    /// <param name="AName">
    /// 子对象名称，注意区分大小写
    /// </param>
    function IndexOf(const AName: PWideChar): Integer; overload; stdcall;
    /// <summary>
    /// 获取指定的子安全对象的索引
    /// </summary>
    /// <param name="AItem">
    /// 要获取索引的子安全对象
    /// </param>
    function IndexOf(const AItem: IQSecurityBase): Integer; overload; stdcall;
    /// <summary>
    /// 判断是否有子安全对象
    /// </summary>
    function HasChildren: Boolean; stdcall;
    /// <summary>
    /// 获取子安全对象的个数
    /// </summary>
    function GetCount: Integer; stdcall;
    /// <summary>
    /// 获取指定索引的子安全对象，索引基于0开始
    /// </summary>
    /// <param name="AIndex">
    /// 子对象索引
    /// </param>
    function GetItems(const AIndex: Integer): Pointer; stdcall;
    /// <summary>
    /// 子安全对象个数
    /// </summary>
    property Count: Integer read GetCount;
    /// <summary>
    /// 访问指定索引的子安全对象
    /// </summary>
    property Items[const AIndex: Integer]: Pointer read GetItems; default;
  end;

  /// <summary>
  /// 访问权限枚举类型
  /// </summary>
  TQAccessRight = (
    /// <summary>
    /// 继承全局设置，全局设置通过IQSecurityService 的 GetDefaultRight 获取，只读
    /// </summary>
    arGlobal,
    /// <summary>
    /// 继承父权限
    /// </summary>
    arInherited,
    /// <summary>
    /// 拒绝访问
    /// </summary>
    arDeny,
    /// <summary>
    /// 允许访问
    /// </summary>
    arAllow);

  IQDependencyList = interface
    ['{2E5ACC3C-EA93-4E82-B703-AC141823698F}']
    function Add(const AId: TGuid): Integer; stdcall;
    procedure Delete(const AId: TGuid); overload; stdcall;
    procedure Delete(const AIndex: Integer); overload; stdcall;
    procedure Clear; stdcall;
    function GetCount: Integer; stdcall;
    function GetItems(const AIndex: Integer): Pointer; overload; stdcall;
    function GetItems(const AIndex: Integer; var AId: TGuid): Boolean;
      overload; stdcall;
    function Contains(const AId:TGuid):Boolean;stdcall;
    property Count: Integer read GetCount;
  end;
  /// <summary>
  /// 权限对象接口定义
  /// </summary>
  IQSecurityRight = interface(IQSecurityBase)
    ['{0DF2B05C-F070-4DD1-98E5-44C4625ED8BA}']
    /// <summary>
    /// 该权限对象默认的访问权限，初始值一般是继承（arInherited），注册权限对象时可以默认其访问权限。
    /// </summary>
    function GetDefaultRight: TQAccessRight; stdcall;
    /// <summary>
    /// 判断指定的用户或角色是否能够访问当前对象
    /// </summary>
    /// <param name="AUser">
    /// 要判定的用户或角色
    /// </param>
    /// <returns>
    /// 允许访问，返回 true，不允许访问，返回 false
    /// </returns>
    function CanAccess(AUser: IQSecurityUserBase): Boolean; stdcall;
  end;

  /// <summary>
  /// 权限分组接口定义
  /// </summary>
  IQSecurityRights = interface(IQSecurityRight)
    ['{67839552-6648-4271-987A-187511777E7C}']
    /// <summary>添加一个新的权限分组</summary>
    /// <param name="AId">分组ID，全局唯一</param>
    /// <param name="AName">分组名称，用于描述权限自身</param>
    /// <param name="ADefaultRight">如果没有定义权限或者权限冲突时，如果全局默认权限为arInherited时的返回值</param>
    /// <returns>返回 IQSecurityRights 类型的权限分组接口</returns>
    /// <remarks>如果指定的ID已存在，则会直接返回原来的分组接口，并忽略AName和ADefaultRight参数</remarks>
    function AddGroup(const AId: TGuid; const AName: PWideChar;
      ADefaultRight: TQAccessRight): Pointer; // IQSecurityRights;
    /// <summary>在当前分组下添加一个新的权限对象</summary>
    /// <param name="AId">权限ID，全局唯一</param>
    /// <param name="AName">权限名称，用于描述权限自身</param>
    /// <param name="ADefaultRight">如果没有定义权限或者权限冲突时，如果全局默认权限为arInherited时的返回值</param>
    /// <returns>返回 IQSecurityRight 类型的权限分组接口</returns>
    /// <remarks>如果指定的ID已存在，则会直接返回原来的分组接口，并忽略AName和ADefaultRight参数</remarks>
    function AddRight(const AId: TGuid; const AName: PWideChar;
      ADefaultRight: TQAccessRight): Pointer; // IQSecurityRight;
  end;

  /// <summary>
  /// 访问限制项目接口定义
  /// </summary>
  /// <remarks>
  /// 访问限制用于控制用户是否能够登录，比如时间限制可以限制用户是否允许在指定的时间点登录，IP地址限制可以限制用户是否从指定的IP地址段登录
  /// </remarks>
  IQSecurityLimit = interface(IQSecurityBase)
    ['{32DF2C09-06D9-47E1-BAC3-585C23503F7F}']
    /// <summary>
    /// 判断是否允许登录，如果当前限制禁止该用户登录，则返回false，否则返回true
    /// </summary>
    /// <param name="AUser">
    /// 要判定的用户账号或角色
    /// </param>
    /// <param name="AParams">
    /// 用户登录参数
    /// </param>
    function CanLogin(AUser: IQSecurityUserBase; AParams: IQParams): Boolean;
  end;

  /// <summary>
  /// 用户和角色的基类接口，提供用户和角色的公共接口定义
  /// </summary>
  IQSecurityUserBase = interface
    ['{476748D4-675C-45BA-B636-3592BAE77F3D}']
    /// <summary>
    /// 判断是否能够访问指定的安全对象
    /// </summary>
    /// <param name="ARight">
    /// 要判定的安全对象
    /// </param>
    /// <remarks>
    /// <para>
    /// 判定规则顺序：
    /// </para>
    /// <para>
    /// 1、当前用户或角色对指定的安全对象明确允许或拒绝的，返回该权限；
    /// </para>
    /// <para>
    /// 2、当前用户或角色对指定的安全对象的父对象有明确的允许或拒绝的，返回该权限；
    /// </para>
    /// <para>
    /// 3、对父角色重复1、2两步，且用户隶属的同级其它父角色没有相互冲突的，返回该权限；
    /// </para>
    /// <para>
    /// 4、父角色权限冲突时，根据权限对象的默认权限，如果是 arInherited 或 arGlobal，则返回
    /// IQSecurityService 的 GetDefaultRight 返回的结果，如果为 arDeny 或
    /// arAllow，则直接返回该权限。
    /// </para>
    /// </remarks>
    /// <seealso cref="IQSecurityRight">
    /// 安全对象接口定义
    /// </seealso>
    function CanAccess(ARight: IQSecurityRight): Boolean; overload; stdcall;
    /// <summary>
    /// 判断是否允许访问指定ID对应的安全对象
    /// </summary>
    /// <param name="ARightId">
    /// 安全对象ID
    /// </param>
    /// <returns>
    /// 允许返回true，拒绝返回false
    /// </returns>
    /// <seealso cref="IQSecurityRight">
    /// 安全对象接口定义
    /// </seealso>
    function CanAccess(const ARightId: PGuid): Boolean; overload; stdcall;
    /// <summary>
    /// 获取指定的账号或角色是否启用
    /// </summary>
    function GetEnabled: Boolean; stdcall;
    /// <summary>
    /// 获取本级拒绝的权限对象数量
    /// </summary>
    function GetDenyCount: Integer; stdcall;
    /// <summary>
    /// 获取本级拒绝的权限对象列表
    /// </summary>
    /// <param name="AIndex">
    /// 要获取的权限对象索引
    /// </param>
    /// <returns>
    /// 实际类型为IQSecurityRight
    /// </returns>
    function GetDenyItems(const AIndex: Integer): Pointer; stdcall;
    /// <summary>
    /// 获取本级允许的权限对象数量
    /// </summary>
    function GetAllowCount: Integer; stdcall;
    /// <summary>
    /// 获取指定索引的本级拒绝的权限对象
    /// </summary>
    /// <param name="AIndex">
    /// 要获取的权限对象索引
    /// </param>
    /// <returns>
    /// 实际类型为IQSecurityRight
    /// </returns>
    function GetAllowItems(const AIndex: Integer): Pointer; stdcall;
    /// <summary>
    /// 获取绑定到本级用户或角色的限制数量
    /// </summary>
    function GetLimitCount: Integer; stdcall;
    /// <summary>
    /// 获取指定索引的限制对象
    /// </summary>
    /// <param name="AIndex">
    /// 要访问的对象索引
    /// </param>
    /// <returns>
    /// 实际类型为IQSecurityLimit
    /// </returns>
    function GetLimits(const AIndex: Integer): Pointer; stdcall;
    /// <summary>
    /// 本级拒绝权限对象数量
    /// </summary>
    property DenyCount: Integer read GetDenyCount;
    /// <summary>
    /// 本级拒绝权限对象列表
    /// </summary>
    property DenyItems[const AIndex: Integer]: Pointer read GetDenyItems;
    /// <summary>
    /// 本级允许权限对象数量
    /// </summary>
    property AllowCount: Integer read GetAllowCount;
    /// <summary>
    /// 本级允许的权限对象列表
    /// </summary>
    property AllowItems[const AIndex: Integer]: Pointer read GetAllowItems;
    /// <summary>
    /// 本级绑定的限制数量
    /// </summary>
    property LimitCount: Integer read GetLimitCount;
    /// <summary>
    /// 本级编写的限制列表
    /// </summary>
    property Limits[const AIndex: Integer]: Pointer read GetLimits;
  end;

  /// <summary>
  /// 用户账号接口定义
  /// </summary>
  IQSecurityUser = interface(IQSecurityBase)
    ['{8B4EBC08-9C48-47E5-BA66-70D4F1A77345}']
    /// <summary>
    /// 检查指定的密码是否正确
    /// </summary>
    /// <param name="APassword">
    /// 要验证的密码
    /// </param>
    function CheckPassword(const APassword: PWideChar): Boolean; stdcall;
    /// <summary>获取父角色数量</summary>
    function GetParentCount: Integer; stdcall;
    /// <summary>获得父角色列表</summary>
    /// <param name="AIndex">要获取的父角色索引</param>
    function GetParents(const AIndex: Integer): Pointer; stdcall;
  end;

  /// <summary>
  /// 角色接口定义
  /// </summary>
  IQSecurityRole = interface(IQSecurityGroup)
    ['{893FD6E7-452B-4B3F-99C6-F6820EB32D55}']
    /// <summary>获取当前角色下直属子用户数量</summary>
    function GetUserCount: Integer; stdcall;
    /// <summary>获取当前角色下直接子角色数量</summary>
    function GetRoleCount: Integer; stdcall;
    /// <summary>获取指定索引的直属用户</summary>
    /// <param name="AIndex">要获取的用户索引</param>
    /// <returns>返回 IQSecurityUser 接口的实例地址</returns>
    function GetUsers(const AIndex: Integer): Pointer; stdcall;
    /// <summary>获取指定索引的直属角色</summary>
    /// <param name="AIndex">要获取的角色索引</param>
    /// <returns>返回 IQSecurityRole 接口的实例地址</returns>
    function GetRoles(const AIndex: Integer): Pointer; stdcall;
  end;

  /// <summary>
  /// 安全管理服务接口定义
  /// </summary>
  IQSecurityService = interface
    ['{C0F91FA3-EB95-4B7A-9E78-4F8F233BAD96}']
    /// <summary>
    /// 获取根角色，它是所有角色的根结点
    /// </summary>
    function GetRootRole: Pointer; stdcall; // IQSecurityRole
    /// <summary>
    /// 获取根权限对象，它是所有权限定义的根结点
    /// </summary>
    function GetRootRight: Pointer; stdcall; // IQSecurityRight
    /// <summary>
    /// 要求用户必需已登录， 如果未登录，则弹出登录对话框，让用户进行登录。
    /// </summary>
    /// <returns>如果已经登录或成功或者成功调起登录界面，则返回true，否则返回false</returns>
    /// <remarks>注意返回值并不代表登录成功，要判断登录是否成功，使用IsLogined函数</remarks>
    function LoginNeeded: Boolean; stdcall;
    /// <summary>
    /// 退出当前账号并重新登录
    /// </summary>
    /// <param name="AMustLogin">是否必需完成登录，如果为true，则登录失败取消登录时，会退出程序，否则保留原登录</param>
    /// <returns>成功，返回true，失败，返回false</returns>
    function Relogin(const AMustLogin: Boolean): Boolean; stdcall;
    /// <summary>判断当前是否已经登录</summary>
    /// <returns>当前已经登录，返回True，未登录返回false</returns>
    function IsLoggedIn: Boolean; stdcall;
    /// <summary>获取当前登录的会话编码</summary>
    /// <returns>返回当前已经登录的会话编码，未登录返回空</returns>
    function GetSessionId: PWideChar; stdcall;
    /// <summary>
    /// 弹出账号角色和权限管理对话框，来管理用户的相关权限
    /// </summary>
    function Config: Boolean; stdcall;
    /// <summary>
    /// 请求修改当前账号密码
    /// </summary>
    /// <returns>
    /// 修改完成返回 true，用户取消返回 false
    /// </returns>
    function ChangePassword: Boolean; stdcall;
    /// <summary>判断当前账号是否有权限访问指定的对象</summary>
    /// <param name="ARightId">权限对象ID</param>
    /// <returns>允许，返回true，禁止，返回false</returns>
    function CanAccess(const AId: PGuid): Boolean;
    /// <summary>
    /// 选择一个用户账号
    /// </summary>
    /// <param name="AParent">
    /// 可选账号隶属的根角色
    /// </param>
    /// <param name="AcceptRole">
    /// 是否可以返回角色，如果不可以，则只能选择具体的用户，不能选择角色
    /// </param>
    /// <returns>返回选择的用户或角色，返回类型为IQSecurityBase</returns>
    function SelectUser(AParent: IQSecurityRole; AcceptRole: Boolean)
      : Pointer; stdcall;
    /// <summary>
    /// 选择一个角色
    /// </summary>
    /// <param name="AParent">
    /// 可选角色的根角色
    /// </param>
    /// <returns>
    /// 返回选择的角色(IQSecurityRole)
    /// </returns>
    function SelectRole(AParent: IQSecurityRole): Pointer; stdcall;
    /// <summary>
    /// 获取全局默认访问权限，只能是arAllow或arDeny
    /// </summary>
    function GetDefaultRight: TQAccessRight; stdcall;
  end;

implementation

end.
