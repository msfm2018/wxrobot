unit qplugins;

interface

{$I qdac.inc}
{$HPPEMIT '#pragma link "qplugins"'}

uses classes, sysutils, types, qstring, qvalue, qtimetypes, qdac_postqueue,
  qplugins_base, qplugins_params, syncobjs, math{$IFDEF MSWINDOWS},
  windows{$ENDIF} {$IFDEF POSIX},
  Posix.Unistd, Posix.PThread{$ENDIF}{$IFDEF UNICODE},
  Generics.collections{$ENDIF};

{ QPlugins 插件管理引擎 Delphi 接口实现单元，其它编程语言会有自己的实现
  本单元实现了Delphi下的 QPlugins 的核心实现（注：不包括额外的加载器和路由器）。

  变更说明
  2017.2.7
  =========
  * 修正了 ById 查找指定的接口实例时，多次触发 GetInstance 的问题（勇哥报告）
  2017.1.3
  =========
  * 修正了 HandlePost 处理通知时参数错误（软件高手报告）

  2016.3.25
  =========
  * 修正了 TQBaseLoader 返回的 Loader 地址错误的问题
  * 增加了 ServiceSource 函数来返回服务的来源文件
  2015.8.8
  ========
  * 修改 TPointerList 为直接映射到 TList 以解决 C++ Builder 中出现异常问题
  * 修正了 TQParams.ByName 时找到后仍然循环的问题(奋斗报告）
  * 修正了 TQParams 保存到流再加载后类型信息丢失的问题
  2015.8.4
  =========
  * 修改锁定方式，使用全局的共享锁来避免可能存在的死锁（阿正、小光）
  * 修正了特定场景下引用计数不正确，造成程序退出时内存可能泄露的问题
  * 修正了注册服务时，无法注册到非默认根结点的问题（似水流年报告）
  * 修正了 IdByName 时返回重复ID的问题（青春报告）
  2015.7.29
  =========
  + 增加 RegisterServices 和 UnregisterServices 以方便服务的注册与注销（青春等）
  * 修正了 ByPath 是根路径查找无效的问题（青春报告）

  2015.7.27
  =========
  * 修正了 QueryInterface 时重复调用 GetInstance 的问题（感谢勇哥）
  + 新增四个预定义的通知ID，在插件加载和卸载时触发
  + 新增 TQBaseLoader 实现做为所有加载器的基类,子类重载相应的部分接口即可
  * 修正了 TQBaseLoader FreeLibraries 时，没有插件时出异常的问题
  2015.7.23
  ========
  * 修正了ByPath/ById 返回值没有使用GetInstance返回可能的新实例的问题（感谢勇哥）
  * 修正了ByPath时 Lock/Unlock 配对错误（感谢勇哥）
  * 修正了替换PluginsManager的对象始终返回 False 的问题（感谢勇哥）

  2015.7.22
  =========
  + 初始版本
}

type

{$IF RTLVersion>=21}
{$M-}
{$IFEND}
  // 下面是Delphi对上述接口的实现

  TQServices = class;

  PQServiceExtension = ^TQServiceExtension;

  TQServiceExtension = record
    Instance: IInterface;
    Next: PQServiceExtension;
  end;

  TQService = class(TQInterfacedObject, IQService)
  private
    function GetPath: QStringW;
  protected
    FId: TGuid;
    FName: QStringW;
    FAttrs: IQParams;
    FErrorCode: Cardinal;
    FErrorMsg: QStringW;
    FParent: Pointer; // 不使用IQServices，以避免由此增加引用计数
    FLoader: Pointer;
    FCreator: Pointer; // 服务的创建者实例，多实例时用于指向主服务
    FFirstExt, FLastExt: PQServiceExtension;
    FOwnerInst: HINST;
    function GetParent: IQServices; stdcall;
    procedure SetParent(AParent: IQServices); stdcall;
    function GetName: PWideChar; stdcall;
    function GetAttrs: IQParams; stdcall;
    function GetLastErrorMsg: PWideChar; stdcall;
    function GetLastErrorCode: Cardinal; stdcall;
    function GetId: TGuid; stdcall;
    function GetDParent: TQServices;
    function GetServiceAttrs: TQParams; virtual;
    function GetLoader: IQLoader; virtual; stdcall;
    procedure SetLastError(ACode: Cardinal; AMsg: QStringW);
    procedure ValidName(const S: QStringW);
    function GetOriginObject: Pointer; virtual; stdcall;
    /// <summary>
    /// 判断指定的
    /// </summary>
    function IsInModule(AModule: THandle): Boolean; stdcall;
    function GetInstanceCreator: IQService; virtual; stdcall;
    procedure ClearExts;
    procedure _GetId(AId: PGuid); stdcall;
    function _GetParent: StandInterfaceResult; stdcall;
    function _GetInstanceCreator: StandInterfaceResult; stdcall;
    function _GetAttrs: StandInterfaceResult; stdcall;
    function _GetInstance: StandInterfaceResult; virtual; stdcall;
  public
    constructor Create(const AId: TGuid; AName: QStringW); overload; virtual;
    destructor Destroy; override;
    function GetInstance: IQService; virtual; stdcall;
    function Execute(AParams: IQParams; AResult: IQParams): Boolean;
      virtual; stdcall;
    function Suspended(AParams: IQParams): Boolean; virtual; stdcall;
    function Resume(AParams: IQParams): Boolean; virtual; stdcall;
    function GetOwnerInstance: HINST; stdcall;
    procedure AddExtension(AInterface: IInterface); stdcall;
    procedure RemoveExtension(AInterface: IInterface); stdcall;
    function QueryInterface(const IID: TGuid; out Obj): HRESULT;
      override; stdcall;
    property Parent: TQServices read GetDParent;
    property Id: TGuid read FId;
    property Name: QStringW read FName;
    property Path: QStringW read GetPath;
    property Attrs: TQParams read GetServiceAttrs;
    property LastError: Cardinal read FErrorCode;
    property LastErrorMsg: QStringW read FErrorMsg;
  end;

  TQPointerList = TList;

  TQServices = class(TQService, IQServices)
  protected
    FItems: TQPointerList;
    function GetItems(AIndex: Integer): IQService; stdcall;
    function GetCount: Integer; stdcall;
  public
    constructor Create(const AId: TGuid; AName: QStringW); override;
    destructor Destroy; override;
    function ByPath(APath: PWideChar): IQService; virtual; stdcall;
    function ById(const AId: TGuid; ADoGetInstance: Boolean): IQService;
      virtual; stdcall;
    function Add(AItem: IQService): Integer; virtual; stdcall;
    function IndexOf(AItem: IQService): Integer; virtual; stdcall;
    procedure Delete(AIndex: Integer); virtual; stdcall;
    function MoveTo(AIndex, ANewIndex: Integer): Boolean; virtual; stdcall;
    /// <summary>
    /// 从父中
    /// </summary>
    procedure Remove(AItem: IQService); virtual; stdcall;
    procedure Clear; virtual; stdcall;
    function QueryInterface(const IID: TGuid; out Obj): HRESULT;
      override; stdcall;
    function _GetItems(AIndex: Integer): StandInterfaceResult; stdcall;
    function _ByPath(APath: PWideChar): StandInterfaceResult; stdcall;
    function _ById(const AId: TGuid; ADoGetInstance: Boolean = true)
      : StandInterfaceResult; stdcall;
    function _GetParent: StandInterfaceResult; stdcall;
    function _GetInstanceCreator: StandInterfaceResult; stdcall;
    function _GetAttrs: StandInterfaceResult; stdcall;
  end;

  TQNotifyManager = class;

  TQNotifyBroadcast = class(TQInterfacedObject, IQNotifyBroadcast,
    IQNotifyBroadcast2)
  private
  protected
    FNotifyId: Cardinal;
    FItems: TQPointerList;
    function GetCount: Integer; stdcall;
    function GetItems(AIndex: Integer): IQNotify; stdcall;
    function Add(ANotify: IQNotify): Integer; stdcall;
    function AddFirst(ANotify: IQNotify): Integer; stdcall;
    procedure Remove(ANotify: IQNotify); stdcall;
    procedure Clear; stdcall;
    procedure Send(AParams: IQParams); stdcall;
    procedure Post(AParams: IQParams); stdcall;
    procedure HandlePost(AParams: IInterface);
    procedure DoNotify(AParams: IQParams);
    function EnumSubscribe(ACallback: TQSubscribeEnumCallback; AParam: Int64)
      : Integer; stdcall;
    function GetNotifyId: Integer; stdcall;
  public
    constructor Create; override;
    constructor Create(AId: Cardinal); overload;
    destructor Destroy; override;
    property Id: Cardinal read FNotifyId;
    property Items[AIndex: Integer]: IQNotify read GetItems; default;
    property Count: Integer read GetCount;
  end;

  TQNotifyItem = class(TQNotifyBroadcast)
  protected
    FName: QStringW;
    FOwner: TQNotifyManager;
  public
    constructor Create(AOwner: TQNotifyManager; AId: Cardinal;
      AName: QStringW); overload;
    function _AddRef: Integer; override; stdcall;
    function _Release: Integer; override; stdcall;
    property Name: QStringW read FName;
  end;

  TQNotifyProc = reference to procedure(const AId: Cardinal; AParams: IQParams;
    var AFireNext: Boolean);

  TQBaseSubscriber = class(TQInterfacedObject, IQNotify)
  protected
    FCallback: TQNotifyProc;
    procedure Notify(const AId: Cardinal; AParams: IQParams;
      var AFireNext: Boolean); stdcall;
  public
    constructor Create(ACallback: TQNotifyProc); overload;
  end;

  TQNotifyManager = class(TQInterfacedObject, IQNotifyManager)
  protected
    FItems: TQPointerList;
    FNextId: Cardinal;
    FBeforeProcessNotify, FAfterProcessNotify: TQNotifyItem;
    procedure Clear;
    procedure HandlePost(AParams: IInterface);
    procedure DoNotify(AId: Cardinal; AParams: IQParams);
  public
    constructor Create; override;
    destructor Destroy; override;
    function Subscribe(ANotifyId: Cardinal; AHandler: IQNotify)
      : Boolean; stdcall;
    procedure Unsubscribe(ANotifyId: Cardinal; AHandler: IQNotify); stdcall;
    function EnumSubscribe(ANotifyId: Cardinal;
      ACallback: TQSubscribeEnumCallback; AParam: Int64): Integer; stdcall;
    function IdByName(const AName: PWideChar): Cardinal; stdcall;
    function NameOfId(const AId: Cardinal): PWideChar; stdcall;
    procedure Send(AId: Cardinal; AParams: IQParams); stdcall;
    procedure Post(AId: Cardinal; AParams: IQParams); stdcall;
    function GetCount: Integer; stdcall;
    function GetId(const AIndex: Integer): Cardinal; stdcall;
    function GetName(const AIndex: Integer): PWideChar; stdcall;
    property Count: Integer read GetCount;
    function HasSubscriber(const AId: Cardinal): Boolean; stdcall;
    property Id[const AIndex: Integer]: Cardinal read GetId;
    property Name[const AIndex: Integer]: PWideChar read GetName;
  end;

  TQLoadedModule = record
    FileName: QStringW;
    Handle: THandle;
  end;

  PQLoadedModule = ^TQLoadedModule;
  TQBaseLoader = class;
  TQAcceptModuleEvent = procedure(ALoader: TQBaseLoader; AFileName: QStringW;
    var Accept: Boolean);

  TQBaseLoader = class(TQService, IQLoader, IQVersion)
  protected
    FFileExt: QStringW;
    FPath: QStringW;
    FIncludeSubDir: Boolean;
    FItems: TQPointerList;
    FState: TQLoaderState;
    FActiveFileName: QStringW;
    FOnAccept: TQAcceptModuleEvent;
    FLoadingModule, FUnloadingModule: HINST;
    procedure Clear; virtual;
    function GetServiceSource(AService: IQService; ABuf: PWideChar;
      ALen: Integer): Integer; virtual; stdcall;
    function InternalLoadServices(const AFileName: PWideChar): THandle;
      overload; virtual;
    function InternalLoadServices(const AStream: TStream): THandle;
      overload; virtual;
    function LoadServices(const AFileName: PWideChar): THandle;
      overload; stdcall;
    procedure Start; virtual; stdcall;
    procedure Stop; virtual; stdcall;
    function LoadServices(const AStream: IQStream): THandle; overload; stdcall;
    function InternalUnloadServices(const AHandle: THandle): Boolean; virtual;
    function UnloadServices(const AHandle: THandle; AWaitDone: Boolean = true)
      : Boolean; stdcall;
    function GetVersion(var AVerInfo: TQVersion): Boolean; virtual; stdcall;
    function GetModuleCount: Integer; virtual; stdcall;
    function GetModuleName(AIndex: Integer): PWideChar; virtual; stdcall;
    function GetModules(AIndex: Integer): HMODULE; virtual; stdcall;
    procedure AddModule(AFileName: QStringW; AHandle: THandle);
    procedure RemoveModule(AModule: PQLoadedModule);
    function FileByHandle(AHandle: THandle): String;
    function HandleByFile(AFileName: QStringW): THandle;
    function GetLoader: IQLoader; override; stdcall;
    procedure AsynUnload(AParams: IInterface);
    function GetModuleState(AInstance: HINST): TQModuleState; stdcall;
    procedure SetLoadingModule(AInstance: HINST); stdcall;
    function GetLoadingModule: HINST; virtual; stdcall;
    function GetLoadingFileName: PWideChar; stdcall;
    function GetState: TQLoaderState; stdcall;
  public
    constructor Create(const AId: TGuid; AName: QStringW; APath, AExt: QStringW;
      AIncSubDir: Boolean = false); overload;
    destructor Destroy; override;
    function Execute(AParams: IQParams; AResult: IQParams): Boolean;
      override; stdcall;
    property FileExt: QStringW read FFileExt;
    property Path: QStringW read FPath;
    property OnAccept: TQAcceptModuleEvent read FOnAccept write FOnAccept;
  end;

  TQInterfaceHolder = class(TComponent)
  private
    FInterface: IInterface;
  public
    constructor Create(AOwner: TComponent); overload; override;
    constructor Create(AOwner: TComponent; AInterface: IInterface);
      reintroduce; overload;
    property InterfaceObject: IInterface read FInterface write FInterface;
  end;

  /// <summary>
  /// 返回全局的 PluginsManager 实例，如果还未创建，则创建它
  /// </summary>
  /// <remarks>
  /// 注意：每个进程有自己独立的插件管理器
  /// </remarks>
function PluginsManager: IQPluginsManager;
/// <summary>
/// 注册一组服务
/// </summary>
/// <param name="AParent">
/// 服务的父路径
/// </param>
/// <param name="AServices">
/// 服务列表，必需实现IQService接口
/// </param>
procedure RegisterServices(AParent: PWideChar; AServices: array of IQService);
/// <summary>
/// 取消一组服务的注册
/// </summary>
/// <param name="APath">
/// 服务的父路径
/// </param>
/// <param name="AServices">
/// 要取消注册的服务名称列表
/// </param>
procedure UnregisterServices(APath: PWideChar; AServices: array of QStringW);
/// <summary>
/// 获取服务的来源模块名
/// </summary>
/// <param name="AService">
/// 要查找来源模块的服务实例
/// </param>
function ServiceSource(AService: IQService): QStringW;
/// <summary>
/// 在指定的父结点下，查找指定路径的服务
/// </summary>
/// <param name="AParent">
/// 父结点
/// </param>
/// <param name="APath">
/// 服务所在的路径，如果以/开始，则忽略AParent，从根开始，否则从AParent开始往下查找
/// </param>
/// <remarks>
/// 注意 FindService 不会调用 GetInstance ，它返回的始终是实例自身，而 GetService 则调用 FindService
/// 及 GetInstance。也就是说，对于多实例服务来说，FindService返回的多实例服务本身，而 GetService
/// 返回的始终是提供服务的具体实例。
/// </remarks>
function FindService(AParent: IQServices; APath: PWideChar): IQService;
  overload;
/// <summary>
/// 在指定的父结点下，查找指定路径的服务
/// </summary>
/// <param name="APath">
/// 从根开始的服务所在的路径
/// </param>
/// <param name="AId">
/// 服务的IID编码
/// </param>
/// <param name="AService">
/// 返回的服务实例
/// </param>
/// <returns>
/// 找到相应的服务，返回true，否则返回false
/// </returns>
/// <remarks>
/// 注意 FindService 不会调用 GetInstance ，它返回的始终是实例自身，而 GetService 则调用 FindService
/// 及 GetInstance。也就是说，对于多实例服务来说，FindService返回的多实例服务本身，而 GetService
/// 返回的始终是提供服务的具体实例。
/// </remarks>
function FindService(APath: PWideChar; const AId: TGuid; out AService)
  : Boolean; overload;
/// <summary>
/// 在指定的父结点下，查找指定路径的服务
/// </summary>
/// <param name="APath">
/// 从根开始的服务所在的路径
/// </param>
/// <returns>
/// 返回找到的服务
/// </returns>
/// <remarks>
/// 注意 FindService 不会调用 GetInstance ，它返回的始终是实例自身，而 GetService 则调用 FindService
/// 及 GetInstance。也就是说，对于多实例服务来说，FindService返回的多实例服务本身，而 GetService
/// 返回的始终是提供服务的具体实例。
/// </remarks>
function FindService(APath: PWideChar): IQService; overload;

/// <summary>
/// 获取指定路径的服务实例（如果是多实例，则返回一个用于提供服务的新实例）
/// </summary>
/// <param name="APath">
/// 从根开始的服务所在的路径
/// </param>
/// <returns>
/// 返回找到的服务
/// </returns>
/// <remarks>
/// 注意 FindService 不会调用 GetInstance ，它返回的始终是实例自身，而 GetService 则调用 FindService
/// 及 GetInstance。也就是说，对于多实例服务来说，FindService返回的多实例服务本身，而 GetService
/// 返回的始终是提供服务的具体实例。
/// </remarks>
function GetService(APath: PWideChar): IQService; overload;
/// <summary>
/// 获取指定路径的服务实例（如果是多实例，则返回一个用于提供服务的新实例）
/// </summary>
/// <param name="AParent">
/// 父结点
/// </param>
/// <param name="APath">
/// 服务所在的路径，如果以/开始，则忽略AParent，从根开始，否则从AParent开始往下查找
/// </param>
/// <returns>
/// 返回找到的服务
/// </returns>
function GetService(AParent: IQServices; APath: PWideChar): IQService; overload;
/// <summary>
/// 获取指定路径的服务实例（如果是多实例，则返回一个用于提供服务的新实例）
/// </summary>
/// <param name="APath">
/// 服务所在的路径
/// </param>
/// <param name="AId">
/// 服务的IID编码
/// </param>
/// <param name="AService">
/// 返回的服务实例
/// </param>
/// <returns>
/// 找到相应的服务，返回true，否则返回false
/// </returns>
/// <remarks>
/// 注意 FindService 不会调用 GetInstance ，它返回的始终是实例自身，而 GetService 则调用 FindService
/// 及 GetInstance。也就是说，对于多实例服务来说，FindService返回的多实例服务本身，而 GetService
/// 返回的始终是提供服务的具体实例。
/// </remarks>
function GetService(APath: PWideChar; const AId: TGuid; out AService)
  : Boolean; overload;

/// <summary>
/// 获取服务所属的加载器实例，如果服务是当前宿主程序内注册的，则返回空
/// </summary>
/// <param name="AService">
/// 要查询的服务实例
/// </param>
/// <returns>
/// 成功，返回加载器接口实例，失败或服务为宿主提前注册的，则返回空
/// </returns>
/// <remarks>
/// 注意 FindService 不会调用 GetInstance ，它返回的始终是实例自身，而 GetService 则调用 FindService
/// 及 GetInstance。也就是说，对于多实例服务来说，FindService返回的多实例服务本身，而 GetService
/// 返回的始终是提供服务的具体实例。
/// </remarks>

function ServiceLoader(AService: IInterface): IQLoader;
/// <summary>
/// 获取服务所属的模块
/// </summary>
/// <param name="AService">
/// 要查询的服务实例
/// </param>
/// <returns>
/// 成功，返回模块句柄，失败，返回0
/// </returns>
function ServiceModule(AService: IInterface): HMODULE;

/// <summary>
/// 获取指定的服务的注册完整路径
/// </summary>
/// <param name="AService">
/// 要查询的服务实例
/// </param>
/// <returns>
/// 返回服务的完整路径（基于PluginsManager）
/// </returns>
function ServicePath(AService: IQService; APathDelimiter: QCharW = '/')
  : QStringW;
function UnloadServices(AInstance: HMODULE; AWaitDone: Boolean): Boolean;
function HoldByComponent(AOwner: TComponent; AInterface: IInterface)
  : TComponent;

var
  PathDelimiter: PQCharW = '/';

implementation

const
  NullChar: WideChar = #0;

resourcestring
  SInvalidName = '无效的结点名称，名称中不能包含 "/"。';
  SMismatchServicePath = '请求的服务路径 %s 不存在或类型不匹配。';

type

  PServiceWaitItem = ^TServiceWaitItem;

  TServiceWaitItem = record
    Path: QStringW;
    Id: TGuid;
    Next: PServiceWaitItem;
    case Integer of
      0:
        (OnReady: TQServiceCallback);
      1:
        (Method: TMethod);
  end;

  // TQPluginsManager 实现了IQService/IQServices/IQNotify接口
  TQPluginsManager = class(TQServices, IQPluginsManager, IQNotify,
    IQStringService)
  private
  protected
    FRouters: IQServices;
    FServices: IQServices;
    FLoaders: IQServices;
    FActiveLoader: IQLoader;
    FWaitingServices: PServiceWaitItem;
    FNotifyMgr: IQNotifyManager;
    function GetLoaders: IQServices; stdcall;
    function GetRouters: IQServices; stdcall;
    function GetServices: IQServices; stdcall;
    function GetActiveLoader: IQLoader; stdcall;
    procedure SetActiveLoader(ALoader: IQLoader); stdcall;
    function DoLoaderAction(AStartAction, AStopAction: BYTE;
      ARevert: Boolean): Boolean;
    procedure Notify(const AId: Cardinal; AParams: IQParams;
      var AFireNext: Boolean); stdcall;
    function WaitService(const AService: PQCharW; ANotify: TQServiceCallback)
      : Boolean; overload; stdcall;
    function WaitService(const AId: TGuid; ANotify: TQServiceCallback): Boolean;
      overload; stdcall;
    procedure RemoveServiceWait(ANotify: TQServiceCallback); overload; stdcall;
    procedure RemoveServiceWait(const AService: PQCharW;
      ANotify: TQServiceCallback); overload; stdcall;
    procedure RemoveServiceWait(const AId: TGuid; ANotify: TQServiceCallback);
      overload; stdcall;
    procedure ServiceReady(AService: IQService); stdcall;
  public
    constructor Create; override;
    destructor Destroy; override;
    procedure Start; stdcall;
    function Stop: Boolean; stdcall;
    function Replace(ANewManager: IQPluginsManager): Boolean; stdcall;
    function ForcePath(APath: PWideChar): IQServices; stdcall;
    function QueryInterface(const IID: TGuid; out Obj): HRESULT;
      override; stdcall;
    function ByPath(APath: PWideChar): IQService; override; stdcall;
    function ById(const AId: TGuid; ADoGetInstance: Boolean): IQService;
      override; stdcall;
    function PathOf(AService: IQService): QStringW;
    procedure AsynCall(AProc: TQAsynProc; AParams: IQParams); stdcall;
    procedure ProcessQueuedCalls; stdcall;
    procedure ModuleUnloading(AInstance: HINST); stdcall;
    function NewParams: IQParams; stdcall;
    function NewString: IQString; overload; stdcall;
    function NewString(const ASource: PWideChar): IQString; overload; stdcall;
    function NewString(const S: QStringW): IQString; overload;
    function NewBroadcast(const AId: Cardinal): IQNotifyBroadcast; stdcall;

    function _GetLoaders: StandInterfaceResult; stdcall;
    function _GetRouters: StandInterfaceResult; stdcall;
    function _GetServices: StandInterfaceResult; stdcall;
    function _ForcePath(APath: PWideChar): StandInterfaceResult; stdcall;
    function _GetActiveLoader: StandInterfaceResult; stdcall;
    function _NewParams: StandInterfaceResult; stdcall;
    function _NewString: StandInterfaceResult; overload; stdcall;
    function _NewString(const ASource: PWideChar): StandInterfaceResult;
      overload; stdcall;
    procedure _AsynCall(AProc: TQAsynProcG; AParams: IQParams); stdcall;
    function _NewBroadcast(const AId: Cardinal): Pointer; stdcall;
    function _AddRef: Integer; override; stdcall;
    function _Release: Integer; override; stdcall;
    property Services: IQServices read GetServices;
    property Router: IQServices read GetRouters;
    property Loaders: IQServices read GetLoaders;
  end;

  TQManagerChangeHandler = class(TQInterfacedObject, IQNotify)
  protected
    procedure Notify(const AId: Cardinal; AParams: IQParams;
      var AFireNext: Boolean); stdcall;
  end;

  TQLocker = class(TQInterfacedObject, IQLocker)
  protected
    FLocker: TCriticalSection;
  public
    constructor Create; override;
    destructor Destroy; override;
    procedure Lock; stdcall;
    procedure Unlock; stdcall;
  end;

var
  MapHandle: THandle = 0;
  OwnerInstance: THandle;
  PluginsTerminated: Boolean = false;
  _PluginsManager: IQPluginsManager = nil;
  PluginsManagerNameSpace: QStringW;
  _MgrReplaceNotify: IQNotify = nil;
  _ActiveLoader: IQLoader = nil;
  GlobalLocker: IQLocker;

{$IFDEF POSIX}

function GetCurrentProcessId: Cardinal;
begin
  Result := getpid;
end;
{$ENDIF}

procedure Lock; inline;
begin
  GlobalLocker.Lock;
end;

procedure Unlock; inline;
begin
  GlobalLocker.Unlock;
end;

{$IFDEF MSWINDOWS}

procedure RegisterManager;
var
  P: Pointer;
begin
  _PluginsManager := TQPluginsManager.Create as IQPluginsManager;
  OwnerInstance := (_PluginsManager as IQService).GetOwnerInstance;
  _PluginsManager._Release; // 释放构造函数中人为增加的计数
  MapHandle := CreateFileMappingW(INVALID_HANDLE_VALUE, nil, PAGE_READWRITE, 0,
    SizeOf(Pointer), PWideChar(PluginsManagerNameSpace));
  if MapHandle = 0 then
    RaiseLastOSError(GetLastError);
  P := MapViewOfFile(MapHandle, FILE_MAP_WRITE, 0, 0, 0);
  PPointer(P)^ := Pointer(_PluginsManager);
  UnmapViewOfFile(P);
  DebugOut('QPluginsManager registered at %x with Name %s',
    [IntPtr(_PluginsManager), PluginsManagerNameSpace]);
end;

procedure UnregisterManager;
begin
  if _PluginsManager <> nil then
  begin
    if _MgrReplaceNotify <> nil then
    begin
      (_PluginsManager as IQNotifyManager).Unsubscribe(NID_MANAGER_REPLACED,
        _MgrReplaceNotify);
      _MgrReplaceNotify := nil;
    end;
    if HInstance <> OwnerInstance then
      _PluginsManager.ModuleUnloading(HInstance)
    else
    begin
      (_PluginsManager as IQServices).Clear;
      PluginsTerminated := true;
    end;
    _PluginsManager := nil;
    if MapHandle <> 0 then
    begin
      CloseHandle(MapHandle);
      MapHandle := 0;
    end;
  end;
end;
{$ELSE}

procedure RegisterManager;
var
  AVal: Pointer;
begin
  OwnerInstance := HInstance;
  _PluginsManager := TQPluginsManager.Create;
end;

procedure UnregisterManager;
begin
  if _PluginsManager <> nil then
  begin
    if _MgrReplaceNotify <> nil then
    begin
      (_PluginsManager as IQNotifyManager).Unsubscribe(NID_MANAGER_REPLACED,
        _MgrReplaceNotify);
      _MgrReplaceNotify := nil;
    end;
    if HInstance <> OwnerInstance then
      _PluginsManager.ModuleUnloading(HInstance)
    else
    begin
      (_PluginsManager as IQServices).Clear;
      PluginsTerminated := true;
    end;
    _PluginsManager := nil;
  end;
end;
{$ENDIF}

function PluginsManager: IQPluginsManager;
{$IFDEF MSWINDOWS}
  procedure FindManager;
  var
    AHandle: THandle;
    P: Pointer;
  begin
    AHandle := OpenFileMappingW(FILE_MAP_READ, false,
      PWideChar(PluginsManagerNameSpace));
    if AHandle = 0 then // 不存在，自己是首个调用者
    begin
      RegisterManager;
      Result := _PluginsManager;
    end
    else
    begin
      P := MapViewOfFile(AHandle, FILE_MAP_READ, 0, 0, 0);
      _PluginsManager := IQPluginsManager(PPointer(P)^);
      UnmapViewOfFile(P);
      { Close the file mapping }
      CloseHandle(AHandle);
      DebugOut('Find PluginsManager at %x with Name %s',
        [IntPtr(Pointer(_PluginsManager)), PluginsManagerNameSpace]);
      OwnerInstance := (_PluginsManager as IQService).GetOwnerInstance;
    end;
  end;
{$ELSE}
  procedure FindManager;
  var
    AHandle: THandle;
    P: Pointer;
  begin
    AHandle := FileOpen(PluginsManagerNameSpace, fmOpenRead or fmShareDenyNone);
    if AHandle <> INVALID_HANDLE_VALUE then
    begin
      FileRead(AHandle, P^, SizeOf(Pointer));
      FileClose(AHandle);
      _PluginsManager := IQPluginsManager(P);
    end
    else
    begin
      RegisterManager;
    end;
  end;
{$ENDIF}

begin
  if not(Assigned(_PluginsManager) or PluginsTerminated) then
  begin
    FindManager;
    GlobalLocker := _PluginsManager as IQLocker;
    if Assigned(_PluginsManager) then
    begin
      _MgrReplaceNotify := TQManagerChangeHandler.Create;
      (_PluginsManager as IQNotifyManager).Subscribe(NID_MANAGER_REPLACED,
        _MgrReplaceNotify)
    end;
  end;
  Result := _PluginsManager;
end;

function ServiceSource(AService: IQService): QStringW;
var
  ALoader: IQLoader;
begin
  ALoader := AService.Loader;
  SetLength(Result, MAX_PATH);
  if not Assigned(ALoader) then
  begin
    if not Supports(AService, IQLoader, ALoader) then // 服务自身不是Loader
    begin
      SetLength(Result,
{$IFDEF UNICODE}GetModuleFileName{$ELSE}GetModuleFileNameW{$ENDIF}(MainInstance,
        PQCharW(Result), MAX_PATH));
      Exit;
    end;
  end;
  SetLength(Result, ALoader.GetServiceSource(AService, PWideChar(Result),
    MAX_PATH));
end;
{ TQService }

procedure TQService.AddExtension(AInterface: IInterface);
var
  AItem: PQServiceExtension;
begin
  if Assigned(AInterface) then
  begin
    New(AItem);
    AItem.Instance := AInterface;
    AItem.Next := nil;
    if Assigned(FLastExt) then
      FLastExt.Next := AItem
    else
      FFirstExt := AItem;
    FLastExt := AItem;
  end;
end;

procedure TQService.ClearExts;
var
  AItem, ANext: PQServiceExtension;
begin
  AItem := FFirstExt;
  while Assigned(AItem) do
  begin
    ANext := AItem.Next;
    Dispose(AItem);
    AItem := ANext;
  end;
  FFirstExt := nil;
  FLastExt := nil;
end;

constructor TQService.Create(const AId: TGuid; AName: QStringW);
begin
  inherited Create;
  FId := AId;
  FName := AName;
  FLoader := Pointer(_ActiveLoader);
  if Assigned(FLoader) then
    FOwnerInst := _ActiveLoader.GetLoadingModule;
  if FOwnerInst = 0 then
    FOwnerInst := HInstance;
end;

destructor TQService.Destroy;
begin
  FParent := nil;
  ClearExts;
  inherited;
end;

function TQService.Execute(AParams, AResult: IQParams): Boolean;
begin
  Result := true;
end;

function TQService.GetAttrs: IQParams;
begin
  if not Assigned(FAttrs) then
    FAttrs := TQParams.Create;
  Result := FAttrs;
end;

function TQService.GetDParent: TQServices;
begin
  Result := InstanceOf(IInterface(FParent)) as TQServices;
end;

function TQService.GetOriginObject: Pointer;
begin
  Result := Self;
end;

function TQService.GetOwnerInstance: THandle;
begin
  Result := FOwnerInst;
end;

function TQService.GetId: TGuid;
begin
  Result := FId;
end;

function TQService.GetLastErrorCode: Cardinal;
begin
  Result := FErrorCode;
end;

function TQService.GetLastErrorMsg: PWideChar;
begin
  Result := PQCharW(FErrorMsg);
end;

function TQService.GetLoader: IQLoader;
begin
  Result := IQLoader(FLoader);
end;

function TQService.GetName: PWideChar;
begin
  Result := PQCharW(FName);
end;

function TQService.GetParent: IQServices;
begin
  Result := IQServices(FParent);
end;

function TQService.GetPath: QStringW;
var
  AParent: IQServices;
begin
  AParent := IQServices(FParent);
  Result := FName;
  while AParent <> nil do
  begin
    Result := QStringW(AParent.Name) + PathDelimiter^ + Result;
    AParent := AParent.Parent;
  end;
end;

function TQService.GetServiceAttrs: TQParams;
begin
  Result := InstanceOf(GetAttrs) as TQParams;
end;

function TQService.IsInModule(AModule: THandle): Boolean;
begin
  Result := HInstance = AModule;
end;

function TQService.QueryInterface(const IID: TGuid; out Obj): HRESULT;
  function QueryExt: HRESULT;
  var
    AItem: PQServiceExtension;
    AExt: IQMultiInstanceExtension;
    AResult: IInterface;
  begin
    Result := E_NOINTERFACE;
    AItem := FFirstExt;
    while Assigned(AItem) do
    begin
      Result := AItem.Instance.QueryInterface(IID, Obj);
      if Result = S_OK then
      begin
        AResult := IInterface(Obj);
        if Supports(AResult, IQMultiInstanceExtension, AExt) then
        begin
          if AExt.GetInstance(AResult) then
            AResult.QueryInterface(IID, Obj)
          else
            IInterface(Obj) := nil;
        end;
        break;
      end;
      AItem := AItem.Next;
    end;
  end;

begin
  Result := QueryExt;
  if Result = E_NOINTERFACE then
    Result := inherited QueryInterface(IID, Obj);
end;

function TQService.GetInstance: IQService;
begin
  Result := Self;
end;

function TQService.GetInstanceCreator: IQService;
begin
  if not Supports(TObject(FCreator), IQService, Result) then
    Result := nil;
end;

procedure TQService.RemoveExtension(AInterface: IInterface);
var
  APrior, AItem, ANext: PQServiceExtension;
begin
  AItem := FFirstExt;
  APrior := nil;
  while Assigned(AItem) do
  begin
    if AItem.Instance = AInterface then
    begin
      ANext := AItem.Next;
      if Assigned(APrior) then
        APrior.Next := ANext
      else
        FFirstExt := ANext;
      Dispose(AItem);
      AItem := ANext;
    end
    else
    begin
      APrior := AItem;
      AItem := AItem.Next;
    end;
  end;
  if FFirstExt = nil then
    FLastExt := nil;
end;

function TQService.Resume(AParams: IQParams): Boolean;
begin
  Result := true;
end;

procedure TQService.SetLastError(ACode: Cardinal; AMsg: QStringW);
begin
  FErrorCode := ACode;
  FErrorMsg := AMsg;
{$IFDEF DEBUG}
  if ACode <> 0 then
    DebugOut('服务 %s 遇到错误 %d:%s', [Name, ACode, AMsg]);
{$ENDIF}
end;

procedure TQService.SetParent(AParent: IQServices);
begin
  FParent := Pointer(AParent);
end;

function TQService.Suspended(AParams: IQParams): Boolean;
begin
  Result := true;
end;

procedure TQService.ValidName(const S: QStringW);
begin
  if ContainsCharW(S, PathDelimiter) then
    raise QException.Create(SInvalidName);
end;

function TQService._GetAttrs: StandInterfaceResult;
begin
  Result := PointerOf(GetAttrs);
end;

procedure TQService._GetId(AId: PGuid);
begin
  AId^ := FId;
end;

function TQService._GetInstance: StandInterfaceResult;
begin
  Result := PointerOf(GetInstance);
end;

function TQService._GetInstanceCreator: StandInterfaceResult;
begin
  Result := PointerOf(GetInstanceCreator);
end;

function TQService._GetParent: StandInterfaceResult;
begin
  Result := PointerOf(GetParent);
end;

{ TQServices }

function TQServices.Add(AItem: IQService): Integer;
begin
  AItem._AddRef;
  AItem.Parent := Self;
  Lock;
  try
    Result := FItems.Add(Pointer(AItem));
  finally
    Unlock;
  end;
end;

function TQServices.ById(const AId: TGuid; ADoGetInstance: Boolean): IQService;
var
  I: Integer;
  AParent: IQServices;
  AService: IQService;
begin
  Result := nil;
  Lock;
  try
    for I := 0 to FItems.Count - 1 do
    begin
      AService := IQService(FItems[I]);
      if SameId(AService.GetId, AId) or
        (AService.QueryInterface(AId, Result) = S_OK) then
      begin
        if ADoGetInstance then
          Result := AService.GetInstance
        else
          Result := AService;
        break;
      end
      else if Supports(AService, IQServices, AParent) then
      begin
        Result := AParent.ById(AId, ADoGetInstance);
        if Assigned(Result) then
          break;
      end;
    end;
  finally
    Unlock;
  end;
end;

function FindService(AParent: IQServices; APath: PWideChar): IQService;
var
  I: Integer;
  AName: QStringW;
  AMgr: IQPluginsManager;
  AFound: Boolean;
begin
  if Assigned(APath) and Assigned(_PluginsManager) then
  begin
    AMgr := PluginsManager;
    if CharInW(APath, PathDelimiter) then
    begin
      AParent := AMgr as IQServices;
      Inc(APath);
    end
    else if AParent = nil then
      AParent := AMgr as IQServices;
    if not Supports(AParent, IQService, Result) then
      Result := nil;
    AFound := true;
    Lock;
    try
      while (APath^ <> #0) and (AParent <> nil) and AFound do
      begin
        AName := DecodeTokenW(APath, PathDelimiter, NullChar, true);
        if Length(AName) > 0 then
        begin
          AFound := false;
          for I := 0 to AParent.Count - 1 do
          begin
            Result := AParent[I];
            if StrCmpW(Result.Name, PWideChar(AName), true) = 0 then
            begin
              AFound := true;
              if not Supports(Result, IQServices, AParent) then
                AParent := nil;
              break;
            end;
          end;
        end;
      end;
      if (APath^ <> #0) or (not AFound) then
        Result := nil;
    finally
      Unlock;
    end;
  end
  else
    Result := nil;
end;

function FindService(APath: PWideChar): IQService;
begin
  Result := FindService(PluginsManager as IQServices, APath);
end;

function FindService(APath: PWideChar; const AId: TGuid; out AService): Boolean;
begin
  Result := Supports(FindService(APath), AId, AService);
end;

function GetService(APath: PWideChar): IQService;
begin
  Result := (PluginsManager as IQServices).ByPath(APath);
end;

function GetService(AParent: IQServices; APath: PWideChar): IQService;
begin
  Result := AParent.ByPath(APath);
end;

function GetService(APath: PWideChar; const AId: TGuid; out AService): Boolean;
begin
  Result := Supports(GetService(APath), AId, AService);
end;

function ServiceLoader(AService: IInterface): IQLoader;
var
  AIntf: IQService;
begin
  if Supports(AService, IQService, AIntf) then
    Result := AIntf.Loader
  else
    Result := nil;
end;

function ServiceModule(AService: IInterface): HMODULE;
var
  AIntf: IQService;
begin
  if Supports(AService, IQService, AIntf) then
    Result := AIntf.GetOwnerInstance
  else
    Result := 0;
end;

function ServicePath(AService: IQService; APathDelimiter: QCharW): QStringW;
var
  AParent, ARoot: IQServices;
begin
  ARoot := PluginsManager as IQServices;
  if Assigned(AService.Creator) then
    AService := AService.Creator;
  AParent := AService.Parent;
  if AParent <> ARoot then
  begin
    Result := AService.Name;
    Lock;
    try
      while AParent <> ARoot do
      begin
        Result := QStringW(AParent.Name) + APathDelimiter + Result;
        AParent := AParent.Parent;
      end;
      Result := APathDelimiter + Result;
    finally
      Unlock;
    end;
  end
  else
    SetLength(Result, 0);
end;

function HoldByComponent(AOwner: TComponent; AInterface: IInterface)
  : TComponent;
begin
  Result := TQInterfaceHolder.Create(AOwner, AInterface);
end;

function InstanceLoader(AInstance: HMODULE): IQLoader;
var
  I, J, C: Integer;
begin
  Lock;
  try
    for I := 0 to PluginsManager.Loaders.Count - 1 do
    begin
      if Supports(PluginsManager.Loaders[I], IQLoader, Result) then
      begin
        C := Result.GetModuleCount;
        for J := 0 to C - 1 do
        begin
          if Result.GetModules(J) = AInstance then
            Exit;
        end;
      end;
    end;
  finally
    Unlock;
  end;
  Result := nil;
end;

function UnloadServices(AInstance: HMODULE; AWaitDone: Boolean): Boolean;
var
  ALoader: IQLoader;
begin
  ALoader := InstanceLoader(AInstance);
  if Assigned(ALoader) then
    Result := ALoader.UnloadServices(AInstance, AWaitDone)
  else
    Result := false;
end;

function TQServices.ByPath(APath: PWideChar): IQService;
begin
  if (APath <> nil) then
  begin
    if APath^ = PathDelimiter^ then
    begin
      Inc(APath);
      Result := FindService(PluginsManager as IQServices, APath);
    end
    else
      Result := FindService(Self, APath);
    if Assigned(Result) then
      Result := Result.GetInstance;
  end
  else
    Result := GetInstance;
end;

procedure TQServices.Clear;
var
  I: Integer;
begin
  Lock;
  try
    for I := 0 to FItems.Count - 1 do
      IQService(FItems[I])._Release;
    FItems.Clear;
  finally
    Unlock;
  end;
end;

constructor TQServices.Create(const AId: TGuid; AName: QStringW);
begin
  inherited;
  FItems := TQPointerList.Create;
end;

procedure TQServices.Delete(AIndex: Integer);
begin
  Lock;
  try
    IQService(FItems[AIndex])._Release;
    FItems.Delete(AIndex);
  finally
    Unlock;
  end;
end;

destructor TQServices.Destroy;
begin
  Clear;
  FreeAndNil(FItems);
  inherited;
end;

function TQServices.GetCount: Integer;
begin
  Result := FItems.Count;
end;

function TQServices.GetItems(AIndex: Integer): IQService;
begin
  Result := IQService(FItems[AIndex]);
end;

function TQServices.IndexOf(AItem: IQService): Integer;
begin
  Result := FItems.IndexOf(Pointer(AItem));
end;

function TQServices.MoveTo(AIndex, ANewIndex: Integer): Boolean;
begin
  Lock;
  try
    Result := (AIndex >= 0) and (AIndex < FItems.Count);
    if Result then
    begin
      if ANewIndex < 0 then
        ANewIndex := 0;
      if ANewIndex >= FItems.Count then
        ANewIndex := FItems.Count - 1;
      if AIndex <> ANewIndex then
        FItems.Move(AIndex, ANewIndex)
      else
        Result := false
    end;
  finally
    Unlock;
  end;
end;

function TQServices.QueryInterface(const IID: TGuid; out Obj): HRESULT;
var
  AService: IQService;
begin
  Result := inherited QueryInterface(IID, Obj);
  if Result = E_NOINTERFACE then
  begin
    AService := ById(IID, false);
    if Assigned(AService) then
      Result := AService.QueryInterface(IID, Obj)
  end;
end;

procedure TQServices.Remove(AItem: IQService);
begin
  Lock;
  try
    if FItems.IndexOf(Pointer(AItem)) <> -1 then
    begin
      AItem._Release;
      FItems.Remove(Pointer(AItem));
    end;
  finally
    Unlock;
  end;
end;

function TQServices._ById(const AId: TGuid; ADoGetInstance: Boolean)
  : StandInterfaceResult;
begin
  Result := PointerOf(ById(AId, ADoGetInstance));
end;

function TQServices._ByPath(APath: PWideChar): StandInterfaceResult;
begin
  Result := PointerOf(ByPath(APath));
end;

function TQServices._GetAttrs: StandInterfaceResult;
begin
  Result := PointerOf(GetAttrs);
end;

function TQServices._GetInstanceCreator: StandInterfaceResult;
begin
  Result := PointerOf(GetInstanceCreator);
end;

function TQServices._GetItems(AIndex: Integer): StandInterfaceResult;
begin
  Result := PointerOf(GetItems(AIndex));
end;

function TQServices._GetParent: StandInterfaceResult;
begin
  Result := PointerOf(GetParent);
end;

{ TQPluginsManager }

procedure TQPluginsManager.AsynCall(AProc: TQAsynProc; AParams: IQParams);
begin
  qdac_postqueue.AsynCall(AProc, AParams);
end;

function TQPluginsManager.ById(const AId: TGuid; ADoGetInstance: Boolean)
  : IQService;
var
  I: Integer;
  AServices: IQServices;
begin
  Result := nil;
  // 优先使用路由器路由的结果
  Lock;
  try
    for I := 0 to FRouters.Count - 1 do
    begin
      if Supports(FRouters[I], IQServices, AServices) then
      begin
        Result := AServices.ById(AId, ADoGetInstance);
        if Assigned(Result) then
          break;
      end;
    end;
  finally
    Unlock;
  end;
  if Result = nil then
    Result := inherited ById(AId, ADoGetInstance);
end;

function TQPluginsManager.ByPath(APath: PWideChar): IQService;
var
  I: Integer;
  AServices: IQServices;
begin
  Result := nil;
  Lock;
  try
    for I := 0 to FRouters.Count - 1 do
    begin
      if Supports(FRouters[I], IQServices, AServices) then
      begin
        Result := AServices.ByPath(APath);
        if Assigned(Result) then
          break;
      end;
    end;
  finally
    Unlock;
  end;
  if Result = nil then
    Result := inherited ByPath(APath);
end;

procedure TQPluginsManager.ModuleUnloading(AInstance: HINST);
  procedure Unregister(AParent: IQServices);
  var
    I: Integer;
    AList: IQServices;
    AService: IQService;
    AServiceInstance: THandle;
  begin
    I := 0;
    while I < AParent.Count do
    begin
      AService := AParent[I];
      AServiceInstance := AService.GetOwnerInstance;
      // OutputDebugString(PChar('Service ' + AService.Name + '.OwnerInstance=' +
      // IntToHex(AServiceInstance, 8)));
      if AInstance = AServiceInstance then
      begin
        // OutputDebugString(PChar(String('Delete Service ') + AService.Name));
        if Supports(AService, IQServices, AList) then
          AList.Clear;
        AParent.Delete(I);
      end
      else
      begin
        if Supports(AService, IQServices, AList) then
          Unregister(AList);
        Inc(I);
      end;
    end;
  end;
  procedure RemoveWaitings;
  var
    APrior, AItem, ANext: PServiceWaitItem;
  begin
    if Assigned(FWaitingServices) then
    begin
      APrior := nil;
      AItem := FWaitingServices;
      while Assigned(AItem) do
      begin
        if FindHInstance(AItem.Method.Code) = AInstance then
        begin
          ANext := AItem.Next;
          if Assigned(APrior) then
            APrior.Next := ANext
          else
            FWaitingServices := ANext;
          Dispose(AItem);
          AItem := ANext;
        end
        else
        begin
          APrior := AItem;
          AItem := AItem.Next;
        end;
      end;
    end;
  end;

begin
  // OutputDebugString(PChar('Clear module HInstance=' + IntToHex(AInstance,
  // 8) + ' ''s Services.'));
  Unregister(Self);
end;

constructor TQPluginsManager.Create;
begin
  inherited Create(IQPluginsManager, 'Manager');
  GlobalLocker := TQLocker.Create;
  _AddRef; // 这个计数保证后面的调用不会释放自身
  FNotifyMgr := TQNotifyManager.Create;
  FServices := TQServices.Create
    (StringToGuid('{EB72B93B-66BF-40C6-A412-6301DE149FC1}'), 'Services');
  Add(FServices as IQService);
  FRouters := TQServices.Create
    (StringToGuid('{C0E2C566-D5F0-4FD3-8BE6-4FFF042C0023}'), 'Routers');
  Add(FRouters as IQService);
  FLoaders := TQServices.Create
    (StringToGuid('{0BBAEE7C-ECD0-4CFA-A968-34BF071623DE}'), 'Loaders');
  Add(FLoaders as IQService);
  DebugOut('TQPluginsManager Created,Address:%x', [IntPtr(Self)]);
end;

destructor TQPluginsManager.Destroy;
begin
  DebugOut('TQPluginsManager Freed,Address:%x', [IntPtr(Self)]);
  FRouters := nil;
  FServices := nil;
  FLoaders := nil;
  FActiveLoader := nil;
  FNotifyMgr.Clear;
  FNotifyMgr := nil;
  inherited;
end;

function TQPluginsManager.DoLoaderAction(AStartAction, AStopAction: BYTE;
  ARevert: Boolean): Boolean;
var
  I: Integer;
  AParams, AResult, AError, AProgress: IQParams;
  APath: QStringW;
  ALoaders: IQServices;
begin
  Result := true;
  ALoaders := Loaders;
  if ALoaders.Count > 0 then
  begin
    FNotifyMgr.Send(AStartAction, nil);
    AParams := TQParams.Create;
    AParams.Add('Sender', ptUnicodeString).AsString := NewString(GetName);
    AParams.Add('Action', ptUInt8).AsInteger := AStartAction;
    AResult := TQParams.Create;
    AProgress := TQParams.Create;
    AProgress.Add('Action', ptUInt8).AsInteger := AStartAction;
    AProgress.Add('Index', ptInt32);
    AProgress.Add('Count', ptInt32);
    AProgress.Add('Name', ptUnicodeString);
    if ARevert then
      I := ALoaders.Count - 1
    else
      I := 0;
    try
      repeat
        if Supports(ALoaders[I], IQLoader, FActiveLoader) then
        begin
          AProgress[1].AsInteger := I;
          AProgress[2].AsInteger := ALoaders.Count;
          FNotifyMgr.Send(NID_LOADERS_PROGRESS, AProgress);
          if not(FActiveLoader as IQService).Execute(AParams, AResult) then
          begin
            AError := TQParams.Create;
            AError.Add('Sender', ptUnicodeString).AsString := NewString(APath);
            AError.Add('Action', ptUInt8).AsInteger := AStartAction;
            AError.Add('ErrorCode', ptUInt32).AsInt64 :=
              (FActiveLoader as IQService).LastError;
            AError.Add('ErrorMsg', ptUnicodeString).AsString :=
              NewString((FActiveLoader as IQService).LastErrorMsg);
            FNotifyMgr.Send(NID_LOADER_ERROR, AError);
            Result := false;
          end;
        end;
        if ARevert then
        begin
          Dec(I);
          // 这里如果加载器加载的插件提供的是加载器服务时，卸载可能会卸载多个加载器，所以要检查
          if I >= ALoaders.Count then
            I := ALoaders.Count - 1;
          if I < 0 then
            break;
        end
        else
        begin
          Inc(I);
          if I = ALoaders.Count then
            break;
        end;
      until 1 > 2;
    finally
      FActiveLoader := nil;
      // 发送加载完成通知
      FNotifyMgr.Send(AStopAction, nil);
    end;
  end;
end;

function PathRoot(var P: PWideChar): IQServices;
var
  AName: QStringW;
  I: Integer;
  AServices: IQServices;
begin
  if CharInW(P, PathDelimiter) then
    Inc(P);
  Result := nil;
  AName := DecodeTokenW(P, PathDelimiter, NullChar, true);
  Lock;
  try
    AServices := _PluginsManager as IQServices;
    for I := 0 to AServices.Count - 1 do
    begin
      if StrCmpW(AServices[I].Name, PWideChar(AName), true) = 0 then
      begin
        if Supports(AServices[I], IQServices, Result) then
          break;
      end;
    end;
  finally
    Unlock;
  end;
end;

function TQPluginsManager.ForcePath(APath: PWideChar): IQServices;
var
  P: PWideChar;
  AName: QStringW;
  AService: IQService;
  AParent: TQServices;
  I: Integer;
  AFound: Boolean;
begin
  P := PQCharW(APath);
  Result := Self;
  Lock;
  try
    while P^ <> #0 do
    begin
      AName := DecodeTokenW(P, PathDelimiter, NullChar, true);
      if Length(AName) > 0 then
      begin
        AFound := false;
        for I := 0 to Result.Count - 1 do
        begin
          AService := Result[I];
          if StrCmpW(AService.Name, PWideChar(AName), true) = 0 then
          begin
            if Supports(AService, IQServices, Result) then
            begin
              AFound := true;
              break
            end
            else
              raise QException.CreateFmt(SMismatchServicePath, [APath]);
          end;
        end;
        if not AFound then
        begin
          AParent := TQServices.Create(NewId, AName);
          Result.Add(AParent);
          Result := AParent;
        end;
      end;
    end;
  finally
    Unlock;
  end;
end;

function TQPluginsManager.GetActiveLoader: IQLoader;
begin
  Result := FActiveLoader;
end;

function TQPluginsManager.GetLoaders: IQServices;
begin
  Result := FLoaders;
end;

function TQPluginsManager.GetRouters: IQServices;
begin
  Result := FRouters;
end;

function TQPluginsManager.GetServices: IQServices;
begin
  Result := FServices;
end;

function TQPluginsManager.NewBroadcast(const AId: Cardinal): IQNotifyBroadcast;
begin
  Result := TQNotifyBroadcast.Create(AId);
end;

function TQPluginsManager.NewParams: IQParams;
begin
  Result := TQParams.Create;
end;

function TQPluginsManager.NewString(const ASource: PWideChar): IQString;
begin
  Result := TQUnicodeString.Create(ASource);
end;

function TQPluginsManager.NewString: IQString;
begin
  Result := TQUnicodeString.Create;
end;

procedure TQPluginsManager.Notify(const AId: Cardinal; AParams: IQParams;
  var AFireNext: Boolean);
begin
  if AId = NID_MANAGER_FREE then
  begin
    ModuleUnloading(HInstance);
    _PluginsManager := nil;
  end;
end;

function TQPluginsManager.PathOf(AService: IQService): QStringW;
var
  AParent: IQServices;
begin
  Result := AService.Name;
  AParent := AService.Parent;
  while Assigned(AParent) do
  begin
    Result := QStringW(AParent.Name) + PathDelimiter^ + Result;
    AParent := AParent.Parent;
  end;
end;

procedure TQPluginsManager.ProcessQueuedCalls;
begin
  qdac_postqueue.ProcessAsynCalls;
end;

function TQPluginsManager.QueryInterface(const IID: TGuid; out Obj): HRESULT;
begin
  if SameId(IID, IQNotifyManager) then
    Result := FNotifyMgr.QueryInterface(IID, Obj)
  else if SameId(IID, IQLocker) then
    Result := GlobalLocker.QueryInterface(IID, Obj)
  else
    Result := inherited QueryInterface(IID, Obj);
end;

procedure TQPluginsManager.RemoveServiceWait(ANotify: TQServiceCallback);
begin
  RemoveServiceWait(nil, ANotify);
end;

procedure TQPluginsManager.RemoveServiceWait(const AService: PQCharW;
  ANotify: TQServiceCallback);
var
  APrior, ANext, AItem, AFirst: PServiceWaitItem;
  ASvcPath: QStringW;
  ANotifyAddr: TMethod absolute ANotify;
begin
  ASvcPath := AService;
  APrior := nil;
  AFirst := nil;
  Lock;
  try
    AItem := FWaitingServices;
    while Assigned(AItem) do
    begin
      if (AItem.Method.Code = ANotifyAddr.Code) and
        ((not Assigned(AService)) or (AItem.Path = ASvcPath)) then
      begin
        ANext := AItem.Next;
        if Assigned(APrior) then
          APrior.Next := ANext
        else
          FWaitingServices := ANext;
        AItem.Next := AFirst;
        AFirst := AItem;
      end
      else
      begin
        APrior := AItem;
        AItem := AItem.Next;
      end;
    end;
  finally
    Unlock;
  end;
  while Assigned(AFirst) do
  begin
    ANext := AFirst.Next;
    Dispose(AFirst);
    AFirst := ANext;
  end;
end;

procedure TQPluginsManager.RemoveServiceWait(const AId: TGuid;
  ANotify: TQServiceCallback);
var
  APrior, ANext, AItem, AFirst: PServiceWaitItem;
  ANotifyAddr: TMethod absolute ANotify;
begin
  APrior := nil;
  AFirst := nil;
  Lock;
  try
    AItem := FWaitingServices;
    while Assigned(AItem) do
    begin
      if (AItem.Method.Code = ANotifyAddr.Code) and SameId(AId, AItem.Id) then
      begin
        ANext := AItem.Next;
        if Assigned(APrior) then
          APrior.Next := ANext
        else
          FWaitingServices := ANext;
        AItem.Next := AFirst;
        AFirst := AItem;
      end
      else
      begin
        APrior := AItem;
        AItem := AItem.Next;
      end;
    end;
  finally
    Unlock;
  end;
  while Assigned(AFirst) do
  begin
    ANext := AFirst.Next;
    Dispose(AFirst);
    AFirst := ANext;
  end;
end;

function TQPluginsManager.Replace(ANewManager: IQPluginsManager): Boolean;
var
  AParams: TQParams;
begin
  // 替换时广播一个通知给所有的插件，告诉你插件管理器发生变更
  AParams := TQParams.Create;
  AParams.Add('Old', ptInt64).AsInt64 := IntPtr(Pointer(_PluginsManager));
  AParams.Add('New', ptInt64).AsInt64 := IntPtr(Pointer(ANewManager));
  FNotifyMgr.Send(NID_MANAGER_REPLACED, AParams);
  _PluginsManager := ANewManager;
  Result := true;
end;

procedure TQPluginsManager.ServiceReady(AService: IQService);
var
  AFirst, APrior, AItem, ANext: PServiceWaitItem;
begin
  AFirst := nil;
  Lock;
  try
    AItem := FWaitingServices;
    APrior := nil;
    while Assigned(AItem) do
    begin
      ANext := AItem.Next;
      if ((Length(AItem.Path) > 0) and (AItem.Path = ServicePath(AService))) or
        SameId(AService.GetId, AItem.Id) then
      begin
        if Assigned(APrior) then
          APrior.Next := ANext
        else
          FWaitingServices := ANext;
        if Assigned(AFirst) then
          AItem.Next := AFirst
        else
          AItem.Next := nil;
        AFirst := AItem;
      end
      else
        APrior := AItem;
      AItem := ANext;
    end;
  finally
    Unlock;
  end;
  while Assigned(AFirst) do
  begin
    ANext := AFirst.Next;
    if Assigned(AFirst.OnReady) then
      AFirst.OnReady(AService);
    Dispose(AFirst);
    AFirst := ANext;
  end;
end;

procedure TQPluginsManager.SetActiveLoader(ALoader: IQLoader);
begin
  FActiveLoader := ALoader;
  _ActiveLoader := ALoader;
end;

procedure TQPluginsManager.Start;
begin
  DoLoaderAction(NID_LOADERS_STARTING, NID_LOADERS_STARTED, false);
end;

function TQPluginsManager.Stop: Boolean;
begin
  Result := DoLoaderAction(NID_LOADERS_STOPPING, NID_LOADERS_STOPPED, true);
end;

function TQPluginsManager.WaitService(const AService: PQCharW;
  ANotify: TQServiceCallback): Boolean;
var
  AItem: PServiceWaitItem;
begin
  if Assigned(AService) and (AService^ <> #0) then
  begin
    New(AItem);
    AItem.Path := AService;
    AItem.OnReady := ANotify;
    Lock;
    try
      AItem.Next := FWaitingServices;
      FWaitingServices := AItem;
    finally
      Unlock;
    end;
    Result := true;
  end
  else
    Result := false;
end;

function TQPluginsManager.WaitService(const AId: TGuid;
  ANotify: TQServiceCallback): Boolean;
var
  AItem: PServiceWaitItem;
begin
  New(AItem);
  AItem.Id := AId;
  AItem.OnReady := ANotify;
  Lock;
  try
    AItem.Next := FWaitingServices;
    FWaitingServices := AItem;
  finally
    Unlock;
  end;
  Result := true;
end;

function TQPluginsManager._AddRef: Integer;
begin
  Result := inherited _AddRef;
end;

procedure TQPluginsManager._AsynCall(AProc: TQAsynProcG; AParams: IQParams);
begin
  qdac_postqueue.AsynCall(AProc, AParams);
end;

function TQPluginsManager._ForcePath(APath: PWideChar): StandInterfaceResult;
begin
  Result := PointerOf(ForcePath(APath));
end;

function TQPluginsManager._GetActiveLoader: StandInterfaceResult;
begin
  Result := PointerOf(GetActiveLoader);
end;

function TQPluginsManager._GetLoaders: StandInterfaceResult;
begin
  Result := PointerOf(GetLoaders);
end;

function TQPluginsManager._GetRouters: StandInterfaceResult;
begin
  Result := PointerOf(GetRouters);
end;

function TQPluginsManager._GetServices: StandInterfaceResult;
begin
  Result := PointerOf(GetServices);
end;

function TQPluginsManager._NewBroadcast(const AId: Cardinal): Pointer;
begin
  Result := PointerOf(NewBroadcast(AId));
end;

function TQPluginsManager._NewParams: StandInterfaceResult;
begin
  Result := PointerOf(NewParams);
end;

function TQPluginsManager._NewString: StandInterfaceResult;
begin
  Result := PointerOf(NewString);
end;

function TQPluginsManager._NewString(const ASource: PWideChar)
  : StandInterfaceResult;
begin
  Result := PointerOf(NewString(ASource));
end;

function TQPluginsManager._Release: Integer;
begin
  Result := inherited _Release;
end;

function TQPluginsManager.NewString(const S: QStringW): IQString;
begin
  Result := TQUnicodeString.Create(S);
end;

{ TQNotifyManager }

procedure TQNotifyManager.Clear;
var
  I: Integer;
  AItem: TQNotifyItem;
begin
  for I := 0 to FItems.Count - 1 do
    TQNotifyItem(FItems[I])._Release;
  FItems.Clear;
end;

constructor TQNotifyManager.Create;
  function AddDefault(AId: Integer; AName: String): TQNotifyItem;
  begin
    Result := TQNotifyItem.Create(Self, AId, AName);
    Result._AddRef;
    FItems.Add(Result);
  end;

begin
  inherited Create;
  FItems := TQPointerList.Create;
  AddDefault(NID_MANAGER_REPLACED, 'Manager.Replaced');
  AddDefault(NID_MANAGER_FREE, 'Manager.Free');
  AddDefault(NID_LOADERS_STARTING, 'Manager.Loaders.Starting');
  AddDefault(NID_LOADERS_STARTED, 'Manager.Loaders.Started');
  AddDefault(NID_LOADERS_STOPPING, 'Manager.Loaders.Stopping');
  AddDefault(NID_LOADERS_STOPPED, 'Manager.Loaders.Stopped');
  AddDefault(NID_LOADERS_PROGRESS, 'Manager.Loaders.OnProgress');
  AddDefault(NID_LOADER_ERROR, 'Manager.Loaders.OnError');
  AddDefault(NID_PLUGIN_LOADING, 'Manager.Plugin.Loading');
  AddDefault(NID_PLUGIN_LOADED, 'Manager.Plugin.Loaded');
  AddDefault(NID_PLUGIN_UNLOADING, 'Manager.Plugin.Unloading');
  AddDefault(NID_PLUGIN_UNLOADED, 'Manager.Plugin.Unloaded');
  FBeforeProcessNotify := AddDefault(NID_NOTIFY_PROCESSING,
    'Manager.NotifyManager.Processing');
  FAfterProcessNotify := AddDefault(NID_NOTIFY_PROCESSED,
    'Manager.NotifyManager.Processed');
  AddDefault(NID_SERVICE_READY, 'Services.Ready');
  FNextId := FItems.Count;
end;

destructor TQNotifyManager.Destroy;
begin
  Clear;
  FreeObject(FItems);
  inherited;
end;

procedure TQNotifyManager.DoNotify(AId: Cardinal; AParams: IQParams);
var
  I: Integer;
  AItem: TQNotifyItem;
  AItems: array of IQNotify;
  AFireNext: Boolean;
  AFireProcessNotify: Boolean;
  AProcessParams: IQParams;
begin
  Lock;
  try
    if AId < Cardinal(FItems.Count) then
    begin
      AItem := FItems[AId];
      SetLength(AItems, AItem.Count);
      for I := 0 to AItem.Count - 1 do
        AItems[I] := IQNotify(AItem.FItems[I]);
    end
    else
      SetLength(AItems, 0);
  finally
    Unlock;
  end;
  AFireProcessNotify := (AId <> NID_NOTIFY_PROCESSING) and
    (AId <> NID_NOTIFY_PROCESSED);
  if AFireProcessNotify then
  begin
    AProcessParams := TQParams.Create;
    AProcessParams.Add('Id', ptUInt32).AsInt64 := AId;
    AProcessParams.Add('Params', ptInterface).AsInterface := AParams;
    DoNotify(NID_NOTIFY_PROCESSING, AProcessParams);
  end;
  try
    AFireNext := true;
    for I := 0 to High(AItems) do
    begin
      AItems[I].Notify(AId, AParams, AFireNext);
      if not AFireNext then
        break;
    end;
  finally
    if AFireProcessNotify then
      DoNotify(NID_NOTIFY_PROCESSED, AProcessParams);
  end;
end;

function TQNotifyManager.EnumSubscribe(ANotifyId: Cardinal;
  ACallback: TQSubscribeEnumCallback; AParam: Int64): Integer;
var
  I: Integer;
  AItem: TQNotifyItem;
  AItems: array of IQNotify;
  AFireNext: Boolean;
begin
  Lock;
  try
    if ANotifyId < Cardinal(FItems.Count) then
    begin
      AItem := FItems[ANotifyId];
      SetLength(AItems, AItem.Count);
      for I := 0 to AItem.Count - 1 do
        AItems[I] := IQNotify(AItem.FItems[I]);
    end
    else
      SetLength(AItems, 0);
  finally
    Unlock;
  end;
  Result := 0;
  AFireNext := true;
  for I := 0 to High(AItems) do
  begin
    ACallback(AItems[I], AParam, AFireNext);
    Inc(Result);
    if not AFireNext then
      break;
  end;
end;

function TQNotifyManager.GetCount: Integer;
begin
  Result := FItems.Count;
end;

function TQNotifyManager.GetId(const AIndex: Integer): Cardinal;
begin
  Result := TQNotifyItem(FItems[AIndex]).Id;
end;

function TQNotifyManager.GetName(const AIndex: Integer): PWideChar;
begin
  Result := PWideChar(TQNotifyItem(FItems[AIndex]).Name);
end;

procedure TQNotifyManager.HandlePost(AParams: IInterface);
var
  ANotifyParams: IQParams;
  ALastParam: IQParam;
  ANotifyId: Cardinal;
  AEvent: TEvent;
begin
  ANotifyParams := AParams as IQParams;
  ALastParam := ANotifyParams[ANotifyParams.Count - 1];
  AEvent := nil;
  if StrCmpW(ALastParam.Name, '@NID', true) = 0 then
  begin
    ANotifyId := Cardinal(ALastParam.AsInteger);
    if ANotifyParams.Count >= 2 then
    begin
      ALastParam := ANotifyParams[ANotifyParams.Count - 2];
      if StrCmpW(ALastParam.Name, '@EVT', true) = 0 then
      begin
        AEvent := Pointer(ALastParam.AsInt64);
        ANotifyParams.Delete(ANotifyParams.Count - 1);
      end;
    end;
    ANotifyParams.Delete(ANotifyParams.Count - 1);
    DoNotify(ANotifyId, ANotifyParams);
    if Assigned(AEvent) then
      AEvent.SetEvent;
  end;
end;

function TQNotifyManager.HasSubscriber(const AId: Cardinal): Boolean;
begin
  Lock;
  try
    if AId < Cardinal(FItems.Count) then
      Result := TQNotifyItem(FItems[AId]).GetCount > 0
    else
      Result := false;
  finally
    Unlock;
  end;
end;

function TQNotifyManager.IdByName(const AName: PWideChar): Cardinal;
var
  I: Integer;
  AItem: TQNotifyItem;
begin
  Result := Cardinal(-1);
  Lock;
  try
    for I := 0 to FItems.Count - 1 do
    begin
      if TQNotifyItem(FItems[I]).Name = AName then
      begin
        Result := TQNotifyItem(FItems[I]).Id;
        Exit;
      end;
    end;
    if Result = Cardinal(-1) then
    begin
      Result := FNextId;
      Inc(FNextId);
      AItem := TQNotifyItem.Create(Self, Result, AName);
      AItem._AddRef;
      FItems.Add(AItem);
    end;
  finally
    Unlock;
  end;
end;

function TQNotifyManager.NameOfId(const AId: Cardinal): PWideChar;
begin
  Lock;
  try
    if AId > Cardinal(FItems.Count) then
      Result := nil
    else
      Result := PWideChar(TQNotifyItem(FItems[AId]).Name);
  finally
    Unlock;
  end;
end;

procedure TQNotifyManager.Post(AId: Cardinal; AParams: IQParams);
begin
  // 追加最后一个参数为通知的ID
  if not Assigned(AParams) then
    AParams := TQParams.Create;
  AParams.Add('@NID', ptInt32).AsInteger := Integer(AId);
  AsynCall(HandlePost, AParams);
end;

procedure TQNotifyManager.Send(AId: Cardinal; AParams: IQParams);
var
  AEvent: TEvent;
begin
  if MainThreadId = GetCurrentThreadId then
    DoNotify(AId, AParams)
  else
  begin
    if not Assigned(AParams) then
      AParams := TQParams.Create;
    AEvent := TEvent.Create;
    try
      AParams.Add('@EVT', ptInt64).AsInt64 := IntPtr(AEvent);
      Post(AId, AParams);
      AEvent.WaitFor(INFINITE);
    finally
      FreeAndNil(AEvent);
    end;
  end;
end;

function TQNotifyManager.Subscribe(ANotifyId: Cardinal;
  AHandler: IQNotify): Boolean;
begin
  Lock;
  try
    if ANotifyId <= Cardinal(FItems.Count) then
    begin
      TQNotifyItem(FItems[ANotifyId]).Add(AHandler);
      Result := true;
    end
    else
      Result := false;
  finally
    Unlock;
  end;
end;

procedure TQNotifyManager.Unsubscribe(ANotifyId: Cardinal; AHandler: IQNotify);
begin
  Lock;
  try
    if ANotifyId <= Cardinal(FItems.Count) then
      TQNotifyItem(FItems[ANotifyId]).Remove(AHandler);
  finally
    Unlock;
  end;
end;

{ TQNotifyItem }
constructor TQNotifyItem.Create(AOwner: TQNotifyManager; AId: Cardinal;
  AName: QStringW);
begin
  inherited Create(AId);
  FOwner := AOwner;
  FName := AName;
end;

function TQNotifyItem._AddRef: Integer;
begin
  Result := inherited;
end;

function TQNotifyItem._Release: Integer;
begin
  Result := inherited;
end;

{ TQManagerChangeHandler }

procedure TQManagerChangeHandler.Notify(const AId: Cardinal; AParams: IQParams;
  var AFireNext: Boolean);
var
  AOld: Pointer;
begin
  if AId = NID_MANAGER_REPLACED then // 管理器被替换时，替换本地变量的值
  begin
    // Param[0]=Old,Param[1]=New
    AOld := Pointer(_PluginsManager);
{$IFDEF WIN32}
    AtomicExchange(Integer(_PluginsManager), Integer(AParams[1].AsInt64));
{$ELSE}
    AtomicExchange(Pointer(_PluginsManager), Pointer(AParams[1].AsInt64));
{$ENDIF}
    _PluginsManager._AddRef;
    IQPluginsManager(AOld) := nil;
  end;
end;

{ TQBaseLoader }

procedure TQBaseLoader.AddModule(AFileName: QStringW; AHandle: THandle);
var
  AItem: PQLoadedModule;
begin
  New(AItem);
  AItem.FileName := AFileName;
  AItem.Handle := AHandle;
  FItems.Add(AItem);
end;

procedure TQBaseLoader.AsynUnload(AParams: IInterface);
var
  AInstParams: IQParams;
  AInst: HINST;
begin
  AInstParams := AParams as IQParams;
  AInst := AInstParams[0].AsInt64;
  UnloadServices(AInst);
end;

procedure TQBaseLoader.Clear;
var
  I: Integer;
begin
  for I := 0 to FItems.Count - 1 do
    RemoveModule(FItems[I]);
  FItems.Clear;
end;

constructor TQBaseLoader.Create(const AId: TGuid; AName, APath, AExt: QStringW;
  AIncSubDir: Boolean);
begin
  inherited Create(AId, AName);
  FPath := APath;
  FFileExt := AExt;
  FIncludeSubDir := AIncSubDir;
  FItems := TQPointerList.Create;
end;

destructor TQBaseLoader.Destroy;
begin
  Clear;
  FreeAndNil(FItems);
  inherited;
end;

function TQBaseLoader.Execute(AParams, AResult: IQParams): Boolean;
begin
  Result := true;
  case AParams.ByName('Action').AsInteger of
    NID_LOADERS_STARTING:
      Start;
    NID_LOADERS_STOPPING:
      Stop;
  end;
end;

function TQBaseLoader.FileByHandle(AHandle: THandle): String;
var
  I: Integer;
  ALoaded: PQLoadedModule;
begin
  SetLength(Result, 0);
  for I := 0 to FItems.Count - 1 do
  begin
    ALoaded := FItems[I];
    if ALoaded.Handle = AHandle then
    begin
      Result := ALoaded.FileName;
      Exit;
    end;
  end;
end;

function TQBaseLoader.GetLoader: IQLoader;
begin
  Result := Self;
end;

function TQBaseLoader.GetLoadingFileName: PWideChar;
begin
  Result := PWideChar(FActiveFileName);
end;

function TQBaseLoader.GetLoadingModule: HINST;
begin
  Result := FLoadingModule;
end;

function TQBaseLoader.GetModuleCount: Integer;
begin
  Result := FItems.Count;
end;

function TQBaseLoader.GetModuleName(AIndex: Integer): PWideChar;
begin
  Result := PWideChar(PQLoadedModule(FItems[AIndex]).FileName);
end;

function TQBaseLoader.GetModules(AIndex: Integer): HMODULE;
begin
  Result := PQLoadedModule(FItems[AIndex]).Handle;
end;

function TQBaseLoader.GetModuleState(AInstance: HINST): TQModuleState;
var
  I: Integer;
begin
  Result := msUnknown;
  if AInstance = FLoadingModule then
    Result := msLoading
  else if AInstance = FUnloadingModule then
    Result := msUnloading
  else
  begin
    Lock;
    try
      for I := 0 to FItems.Count - 1 do
      begin
        if PQLoadedModule(FItems[I]).Handle = AInstance then
        begin
          Result := msLoaded;
          break;
        end;
      end;
    finally
      Unlock;
    end;
  end;
end;

function TQBaseLoader.GetServiceSource(AService: IQService; ABuf: PWideChar;
  ALen: Integer): Integer;
begin
  Result := 0;
end;

function TQBaseLoader.GetState: TQLoaderState;
begin
  Result := FState;
end;

function TQBaseLoader.GetVersion(var AVerInfo: TQVersion): Boolean;
begin
  Result := true;
  FillChar(AVerInfo, SizeOf(TQVersion), 0);
  AVerInfo.Version.Major := 3;
  AVerInfo.Version.Release := 1;
  strcpyW(AVerInfo.Name, PWideChar(Name));
  strcpyW(AVerInfo.Company, 'QDAC team');
  strcpyW(AVerInfo.Description, 'Default Plugins Loader');
{$IFDEF UNICODE}
  GetModuleFileName
{$ELSE}
  GetModuleFileNameW
{$ENDIF}(HInstance, AVerInfo.FileName, MAX_PATH)
end;

function TQBaseLoader.HandleByFile(AFileName: QStringW): THandle;
var
  I: Integer;
  ALoaded: PQLoadedModule;
begin
  Result := 0;
  for I := 0 to FItems.Count - 1 do
  begin
    ALoaded := FItems[I];
    if ALoaded.FileName = AFileName then
    begin
      Result := ALoaded.Handle;
      Exit;
    end;
  end;
end;

function TQBaseLoader.InternalLoadServices(const AFileName: PWideChar): THandle;
begin
  Result := 0;
end;

function TQBaseLoader.InternalLoadServices(const AStream: TStream): THandle;
var
  AFileStream: TFileStream;
  AFileName: QStringW;
  function GetTempFileName: QStringW;
  var
    ATempDir: QStringW;
    I: Cardinal;
  begin
    I := GetCurrentProcessId;
{$IFDEF MSWINDOWS}
    SetLength(ATempDir, MAX_PATH);
    SetLength(ATempDir, GetTempPathW(MAX_PATH, PWideChar(ATempDir)));
    SetLength(Result, MAX_PATH);
    windows.GetTempFileNameW(PWideChar(ATempDir), 'QP_', I, PWideChar(Result));
    AFileName := PWideChar(Result);
    Result := AFileName;
{$ELSE}
{$IFDEF ANDROID}
    ATempDir := '/data/local/tmp/';
{$ELSE}
    ATempDir := '/tmp/';
{$ENDIF}
    while FileExists(ATempDir + 'QP_' + IntToStr(I)) do
      Inc(I);
    Result := ATempDir + 'QP_' + IntToStr(I);
{$ENDIF}
  end;

begin
  // 默认通用实现采用临时文件的机制来将数据保存到文件，然后调用从文件中加载的方式来实现
  AFileStream := TFileStream.Create(GetTempFileName, fmCreate);
  try
    AFileStream.CopyFrom(AStream, 0);
    FreeObject(AFileStream);
    AFileStream := nil;
    Result := LoadServices(PWideChar(AFileName));
  finally
    if Assigned(AFileStream) then
      FreeObject(AFileStream);
    sysutils.DeleteFile(AFileName);
  end;
end;

function TQBaseLoader.InternalUnloadServices(const AHandle: THandle): Boolean;
begin
  Result := true;
end;

function TQBaseLoader.LoadServices(const AStream: IQStream): THandle;
var
  AVclStream: TQStream;
  AParams: TQParams;
  ALastState: TQLoaderState;
begin
  AParams := TQParams.Create;
  FLoadingModule := 0;
  ALastState := FState;
  FState := lsLoading;
  AParams.Add('File', ptUnicodeString).AsString := '<Stream>';
  AParams._AddRef;
  (PluginsManager as IQNotifyManager).Send(NID_PLUGIN_LOADING, AParams);
  PluginsManager.ActiveLoader := Self;
  AVclStream := NewStream(AStream);
  try
    Result := InternalLoadServices(AVclStream);
    if ALastState = lsIdle then
    begin
      if Result <> 0 then
        AddModule('', Result);
    end;
  finally
    (PluginsManager as IQNotifyManager).Send(NID_PLUGIN_LOADED, AParams);
    if Assigned(AParams) then
    begin
      AParams._Release;
      PluginsManager.ActiveLoader := nil;
    end;
    FreeAndNil(AVclStream);
    FLoadingModule := 0;
    FState := ALastState;
  end;
end;

procedure TQBaseLoader.RemoveModule(AModule: PQLoadedModule);
begin
  Dispose(AModule);
end;

procedure TQBaseLoader.SetLoadingModule(AInstance: HINST);
begin
  FLoadingModule := AInstance;
end;

procedure TQBaseLoader.Start;
var
  AExts: QStringW;
  AInst: THandle;
  ANotifyMgr: IQNotifyManager;
  function IsMatch(AName: QStringW): Boolean;
  var
    pExts, P: PWideChar;
    AExt: QStringW;
  begin
    pExts := PQCharW(AExts);
    AExt := UpperCase(ExtractFileExt(AName));
    P := StrStrW(pExts, PQCharW(AExt));
    Result := false;
    if P <> nil then
    begin
      if (P = pExts) or (P[-1] = ';') or (P[-1] = ',') then
      begin
        Inc(P, Length(AExt));
        if (P^ = #0) or (P^ = ',') or (P^ = ';') then
        begin
          Result := true;
          if Assigned(OnAccept) then
            OnAccept(Self, AName, Result);
        end;
      end;
    end;
  end;

  procedure StartPlugins(APath: String);
  var
    sr: TSearchRec; // 用系统的封装以便跨平台
  begin
    if FindFirst(APath + '*.*', faAnyFile, sr) = 0 then
    begin
      repeat
        if (sr.Attr and faDirectory) = 0 then
        // 不加载子目录下的东西
        begin
          if IsMatch(sr.Name) then
          begin
            AInst := LoadServices(PWideChar(FPath + sr.Name));
            if AInst <> 0 then
              AddModule(FPath + sr.Name, AInst);
          end;
        end
        else if FIncludeSubDir and (sr.Name <> '.') and (sr.Name <> '..') then
          StartPlugins(APath + sr.Name +
{$IFDEF MSWINDOWS}'\'{$ELSE}'/'{$ENDIF});
      until FindNext(sr) <> 0;
    end;
  end;

begin
  AExts := UpperCase(FileExt);
  FState := lsLoading;
  ANotifyMgr := PluginsManager as IQNotifyManager;
  try
    ANotifyMgr.Send(NID_PLUGIN_LOADING, nil);
    StartPlugins(FPath);
  finally
    FState := lsIdle;
    ANotifyMgr.Send(NID_PLUGIN_LOADED, nil);
  end;
end;

procedure TQBaseLoader.Stop;
var
  I: Integer;
  AItem: PQLoadedModule;
begin
  if FItems.Count > 0 then
  begin
    FState := lsUnloading;
    (PluginsManager as IQNotifyManager).Send(NID_PLUGIN_UNLOADING, nil);
    try
      for I := FItems.Count - 1 downto 0 do
      begin
        AItem := PQLoadedModule(FItems[I]);
        try
          UnloadServices(AItem.Handle);
        except
          on E: Exception do
{$IFDEF MSWINDOWS}
            OutputDebugString(PChar('无法正常卸载插件 ' + AItem.FileName + ':' +
              E.Message));
{$ENDIF}
        end;
      end;
      Clear;
    finally
      FState := lsIdle;
      (PluginsManager as IQNotifyManager).Send(NID_PLUGIN_UNLOADED, nil);
    end;
  end;
end;

function TQBaseLoader.LoadServices(const AFileName: PWideChar): THandle;
var
  AParams: TQParams;
  ALastState: TQLoaderState;
begin
  Result := HandleByFile(AFileName);
  if Result = 0 then
  begin
    FLoadingModule := 0;
    ALastState := FState;
    FState := lsLoading;
    AParams := TQParams.Create;
    AParams.Add('File', ptUnicodeString).AsString := AFileName;
    AParams._AddRef;
    (PluginsManager as IQNotifyManager).Send(NID_PLUGIN_LOADING, AParams);
    PluginsManager.ActiveLoader := Self;
    try
      FActiveFileName := AFileName;
      Result := InternalLoadServices(AFileName);
      if (ALastState = lsIdle) then
      begin
        if Result <> 0 then
          AddModule(AFileName, Result);
      end;
      if Result = 0 then
        RaiseLastOSError;
      AParams.Add('Instance', ptInt64).AsInt64 := Result;
    finally
      (PluginsManager as IQNotifyManager).Send(NID_PLUGIN_LOADED, AParams);
      if Assigned(AParams) then
      begin
        AParams._Release;
        PluginsManager.ActiveLoader := nil;
      end;
      FLoadingModule := 0;
      SetLength(FActiveFileName, 0);
      FState := ALastState;
    end;
  end;
end;

function TQBaseLoader.UnloadServices(const AHandle: THandle;
  AWaitDone: Boolean): Boolean;
var
  AParams: TQParams;
  I: Integer;
  ALastState: TQLoaderState;
begin
  if AWaitDone then
  begin
    FUnloadingModule := AHandle;
    ALastState := FState;
    FState := lsUnloading;
    AParams := TQParams.Create;
    AParams.Add('Instance', ptInt64).AsInt64 := AHandle;
    AParams.Add('File', ptUnicodeString).AsString := FileByHandle(AHandle);
    AParams._AddRef;
    PluginsManager.ActiveLoader := Self;
    (PluginsManager as IQNotifyManager).Send(NID_PLUGIN_UNLOADING, AParams);
    try
      Result := InternalUnloadServices(AHandle);
    finally
      (PluginsManager as IQNotifyManager).Send(NID_PLUGIN_UNLOADED, AParams);
      if Assigned(AParams) then
      begin
        PluginsManager.ActiveLoader := nil;
        AParams._Release;
        for I := 0 to FItems.Count - 1 do
        begin
          if PQLoadedModule(FItems[I]).Handle = AHandle then
          begin
            RemoveModule(FItems[I]);
            FItems.Delete(I);
            break;
          end;
        end;
      end;
      FUnloadingModule := 0;
      FState := ALastState;
    end;
  end
  else
  begin
    begin
      AsynCall(AsynUnload, NewParams([AHandle]));
      Result := true;
    end;
  end;
end;

procedure RegisterServices(AParent: PWideChar; AServices: array of IQService);
var
  AContainer: IQServices;
  I: Integer;
  AMgr: IQPluginsManager;
begin
  AMgr := PluginsManager;
  Lock;
  try
    AContainer := AMgr.ForcePath(AParent);
    for I := 0 to High(AServices) do
    begin
      AContainer.Add(AServices[I]);
    end;
  finally
    Unlock;
  end;
  for I := 0 to High(AServices) do
    AMgr.ServiceReady(AServices[I]);
end;

procedure UnregisterServices(APath: PWideChar; AServices: array of QStringW);
var
  AParent: IQServices;
  AItem: IQService;
  I, J: Integer;
begin
  if Supports(FindService(nil, APath), IQServices, AParent) then
  begin
    for I := 0 to High(AServices) do
    begin
      J := 0;
      while J < AParent.Count do
      begin
        AItem := AParent[J];
        if StrCmpW(AItem.Name, PWideChar(AServices[I]), true) = 0 then
          AParent.Remove(AItem)
        else
          Inc(J);
      end;
    end;
  end;
end;

function GetCurrentFileName: QStringW;
begin
  SetLength(Result, MAX_PATH);
  SetLength(Result,
{$IFDEF UNICODE}GetModuleFileName{$ELSE}GetModuleFileNameW{$ENDIF}(HInstance,
    PWideChar(Result), MAX_PATH));
end;

{ TQLocker }

constructor TQLocker.Create;
begin
  FLocker := TCriticalSection.Create;
end;

destructor TQLocker.Destroy;
begin
  FreeObject(FLocker);
  inherited;
end;

procedure TQLocker.Lock; stdcall;
begin
  FLocker.Enter;
end;

procedure TQLocker.Unlock; stdcall;
begin
  FLocker.Leave;
end;

{ TQInterfaceHolder }

constructor TQInterfaceHolder.Create(AOwner: TComponent;
  AInterface: IInterface);
begin
  inherited Create(AOwner);
  FInterface := AInterface;
end;

constructor TQInterfaceHolder.Create(AOwner: TComponent);
begin
  inherited;
end;

{ TQNotifyBroadcast }

function TQNotifyBroadcast.Add(ANotify: IQNotify): Integer;
begin
  if Assigned(ANotify) then
  begin
    ANotify._AddRef;
    Result := FItems.Add(Pointer(ANotify));
  end
  else
    Result := -1;
end;

function TQNotifyBroadcast.AddFirst(ANotify: IQNotify): Integer;
begin
  if Assigned(ANotify) then
  begin
    ANotify._AddRef;
    Result := 0;
    FItems.Insert(0, Pointer(ANotify));
  end
  else
    Result := -1;
end;

procedure TQNotifyBroadcast.Clear;
var
  I: Integer;
begin
  for I := 0 to FItems.Count - 1 do
    IQNotify(FItems[I])._Release;
  FItems.Clear;
end;

constructor TQNotifyBroadcast.Create;
begin
  inherited;
  // 不允许调用它创建实例
end;

constructor TQNotifyBroadcast.Create(AId: Cardinal);
begin
  inherited Create;
  FNotifyId := AId;
  FItems := TQPointerList.Create;
end;

destructor TQNotifyBroadcast.Destroy;
begin
  Clear;
  FreeAndNil(FItems);
  inherited;
end;

procedure TQNotifyBroadcast.DoNotify(AParams: IQParams);
var
  I: Integer;
  AItems: array of IQNotify;
  AFireNext: Boolean;
  AFireProcessNotify: Boolean;
  AProcessParams: IQParams;
  AMgr: IQNotifyManager;
begin
  AMgr := PluginsManager as IQNotifyManager;
  Lock;
  try
    SetLength(AItems, Count);
    for I := 0 to Count - 1 do
      AItems[I] := IQNotify(FItems[I]);
  finally
    Unlock;
  end;
  AFireProcessNotify := (Id <> NID_NOTIFY_PROCESSING) and
    (Id <> NID_NOTIFY_PROCESSED);
  if AFireProcessNotify and Assigned(AMgr) then
  begin
    AProcessParams := TQParams.Create;
    AProcessParams.Add('Id', ptUInt32).AsInt64 := Id;
    AProcessParams.Add('Params', ptInterface).AsInterface := AParams;
    AMgr.Send(NID_NOTIFY_PROCESSING, AProcessParams);
  end;
  try
    AFireNext := true;
    for I := 0 to High(AItems) do
    begin
      AItems[I].Notify(Id, AParams, AFireNext);
      if not AFireNext then
        break;
    end;
  finally
    if AFireProcessNotify and Assigned(AMgr) then
      AMgr.Send(NID_NOTIFY_PROCESSED, AProcessParams);
  end;
end;

function TQNotifyBroadcast.EnumSubscribe(ACallback: TQSubscribeEnumCallback;
  AParam: Int64): Integer;
var
  I: Integer;
  AContinue: Boolean;
begin
  Result := 0;
  if Assigned(ACallback) then
  begin
    AContinue := true;
    for I := 0 to FItems.Count - 1 do
    begin
      ACallback(IQNotify(FItems[I]), AParam, AContinue);
      Inc(Result);
      if not AContinue then
        break;
    end;
  end;
end;

function TQNotifyBroadcast.GetCount: Integer;
begin
  Result := FItems.Count;
end;

function TQNotifyBroadcast.GetItems(AIndex: Integer): IQNotify;
begin
  Result := IQNotify(FItems[AIndex]);
end;

function TQNotifyBroadcast.GetNotifyId: Integer;
begin
  Result := Id;
end;

procedure TQNotifyBroadcast.HandlePost(AParams: IInterface);
var
  ANotifyParams: IQParams;
  AEventParam: IQParam;
  AEvent: TEvent;
begin
  if Assigned(AParams) then
    ANotifyParams := AParams as IQParams
  else
    ANotifyParams := NewParams;
  AEvent := nil;
  AEventParam := ANotifyParams.ByName('@EVT');
  if Assigned(AEventParam) then
    AEvent := Pointer(AEventParam.AsInt64);
  DoNotify(ANotifyParams);
  if Assigned(AEvent) then
    AEvent.SetEvent;
end;

procedure TQNotifyBroadcast.Post(AParams: IQParams);
begin
  AsynCall(HandlePost, AParams);
end;

procedure TQNotifyBroadcast.Remove(ANotify: IQNotify);
var
  I: Integer;
begin
  I := FItems.IndexOf(Pointer(ANotify));
  if I <> -1 then
  begin
    FItems.Delete(I);
    ANotify._Release;
  end;
end;

procedure TQNotifyBroadcast.Send(AParams: IQParams);
var
  AEvent: TEvent;
begin
  if MainThreadId = GetCurrentThreadId then
    DoNotify(AParams)
  else
  begin
    if not Assigned(AParams) then
      AParams := TQParams.Create;
    AEvent := TEvent.Create;
    try
      AParams.Add('@EVT', ptInt64).AsInt64 := IntPtr(AEvent);
      Post(AParams);
      AEvent.WaitFor(INFINITE);
    finally
      FreeAndNil(AEvent);
    end;
  end;
end;

{$IFNDEF MSWINDOWS}

type
  THostPluginsManager = function: Pointer; stdcall;

function HostPluginsManager: Pointer; stdcall;
  function CallHost: Pointer;
  var
    AHostEntry: THostPluginsManager;
  begin
    AHostEntry := GetProcAddress(MainInstance, 'HostPluginsManager');
    if Assigned(AHostEntry) then
      Result := AHostEntry
    else
      Result := nil;
  end;

begin
  if IsLibrary then
    CallHost
  else
    Result := PointerOf(PluginsManager);
end;

exports HostPluginsManager;
{$ENDIF}
{ TQBaseSubscriber }

constructor TQBaseSubscriber.Create(ACallback: TQNotifyProc);
begin
  inherited Create;
  FCallback := ACallback;
end;

procedure TQBaseSubscriber.Notify(const AId: Cardinal; AParams: IQParams;
  var AFireNext: Boolean);
begin
  if Assigned(FCallback) then
    FCallback(AId, AParams, AFireNext);
end;

initialization

{$IFDEF MSWINDOWS}
  PluginsManagerNameSpace := 'Local\QPluginsManager_PID_' +
  IntToStr(GetCurrentProcessId);
{$ELSE}
{$IFDEF ANDROID}
  PluginsManagerNameSpace := '/data/local/tmp/QPluginsManager_PID_' +
  IntToStr(GetCurrentProcessId);
{$ELSE}
  PluginsManagerNameSpace := '/tmp/QPluginsManager_PID_' +
  IntToStr(GetCurrentProcessId);
{$ENDIF}
{$ENDIF}
_ActiveLoader := PluginsManager.ActiveLoader;
if Assigned(_ActiveLoader) then
  _ActiveLoader.SetLoadingModule(HInstance);

finalization

if _PluginsManager <> nil then
begin
  if HInstance = OwnerInstance then
  begin
    PluginsManager.Stop;
    (PluginsManager as IQNotifyManager).Send(NID_MANAGER_FREE, nil);
  end
  else
    _ActiveLoader := nil;
  UnregisterManager;
end;

end.
