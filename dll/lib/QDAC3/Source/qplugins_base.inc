unit qplugins_base;
const
  SQPluginsVersion = '3.1'; // 3.1版
  // 日志记录级别
  LOG_EMERGENCY: BYTE = 0;
  LOG_ALERT = 1;
  LOG_FATAL = 2;
  LOG_ERROR = 3;
  LOG_WARN = 4;
  LOG_HINT = 5;
  LOG_MESSAGE = 6;
  LOG_DEBUG = 7;
  // 预定义通知的ID
  NID_MANAGER_REPLACED = 0; // 服务管理器被替换（这个通知只需要进程内插件响应）
  NID_MANAGER_FREE = 1; // 插件管理器需要被立即释放
  NID_LOADERS_STARTING = 2; // 正在启动加载器
  NID_LOADERS_STARTED = 3; // 启动器加载完成
  NID_LOADERS_STOPPING = 4; // 启动器停止中
  NID_LOADERS_STOPPED = 5; // 启动器已停止
  NID_LOADERS_PROGRESS = 6; // 启动器加载/停止进度
  NID_LOADER_ERROR = 7; // 启动器加载出错
  NID_PLUGIN_LOADING = 8; // 正在加载插件
  NID_PLUGIN_LOADED = 9; // 加载插件完成
  NID_PLUGIN_UNLOADING = 10; // 服务准备卸载
  NID_PLUGIN_UNLOADED = 11; // 服务卸载完成
  NID_NOTIFY_PROCESSING = 12; // 通知将要被处理
  NID_NOTIFY_PROCESSED = 13; // 通知已经处理完成
  NID_SERVICE_READY = 14; // 服务注册完成

type
  StandInterfaceResult = Pointer;
  TQAsynProcG = procedure(AParams: IInterface); stdcall;
  TQAsynProc = procedure(AParasm: IInterface) of object; // Delphi only

  IQBytes = interface
    ['{8C570D86-517F-4729-8C5F-427F3F6A414B}']
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
    procedure LoadFromFile(const fileName: PWideChar); stdcall;
    procedure SaveToFile(const fileName: PWideChar); stdcall;
    procedure AppendToFile(const fileName: PWideChar); stdcall;
  end;
  // 基础类型定义
  // 流
  IQStream = interface
    ['{BCFD2F69-CCB8-4E0B-9FE9-A7D58797D1B8}']
    function Read(pv: Pointer; cb: Cardinal): Cardinal; stdcall;
    function Write(pv: Pointer; cb: Cardinal): Cardinal; stdcall;
    function Seek(AOffset: Int64; AFrom: BYTE): Int64; stdcall;
    procedure SetSize(ANewSize: UInt64); stdcall;
    function CopyFrom(AStream: IQStream; ACount: Int64): Int64; stdcall;
  end;

  // 参数规格化，用于使用不同语言之间交互
  TQParamType = (ptUnknown,
    // Integer Types
    ptInt8, ptUInt8, ptInt16, ptUInt16, ptInt32, ptUInt32, ptInt64, ptUInt64,
    ptFloat4, ptFloat8, // Float types
    ptDateTime, ptInterval, // DateTime types
    ptAnsiString, ptUtf8String, ptUnicodeString, // String types
    ptBoolean, // Boolean
    ptGuid, // Guid
    ptBytes, // Binary
    ptStream, // 流
    ptArray, // Array
    ptInterface);
  IQParams = interface;

  IQString = interface
    ['{B2FB1524-A06D-47F6-AA85-87C2251F2FCF}']
    procedure SetValue(const S: PWideChar); stdcall;
    function GetValue: PWideChar; stdcall;
    function GetLength: Integer; stdcall;
    procedure SetLength(ALen: Integer); stdcall;
    property value: PWideChar read GetValue write SetValue;
    property Length: Integer read GetLength write SetLength;
  end;

  IQStringEx = interface(IQString)
    ['{54BF45E6-0D9F-4E66-9AA3-87974FB50893}']
    function Left(const AMaxCount: Cardinal; const ACheckExt: Boolean): IQString;stdcall;
    function Right(const AMaxCount: Cardinal; const ACheckExt: Boolean): IQString;stdcall;
    function SubString(const AStart, ACount: Cardinal; const ACheckExt: Boolean): IQString;stdcall;
    function Replace(const old, new: PWideChar; AFlags: Integer): Cardinal;
    //Todo:Add more function
  end;
  // 单个参数
  IQParam = interface
    ['{8641FD44-1BC3-4F04-B730-B5406CDA17E3}']
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
    function GetAsBytes(ABuf: PByte; ABufLen: Cardinal): Cardinal; overload;stdcall;
    procedure SetAsBytes(ABuf: PByte; ABufLen: Cardinal); overload;stdcall;
    function GetIsNull: Boolean; stdcall;
    procedure SetNull; stdcall;
    function GetAsArray: IQParams; stdcall;
    function GetAsStream: IQStream; stdcall;
    procedure SetAsStream(AStream: IQStream); stdcall;
    function GetParent: IQParams; overload; stdcall;
    function GetType: TQParamType; stdcall;
    procedure SetType(const AType: TQParamType); stdcall;
    function GetAsInterface: IInterface; overload; stdcall;
    procedure SetAsInterface(const AIntf: IInterface); stdcall;
    function GetIndex: Integer; stdcall;
    function GetAsBytes:IQBytes;overload;stdcall;
    procedure SetAsBytes(const ABytes:IQBytes);overload;stdcall;
    // 下面的代码为了兼容其它语言加入
    function _GetAsArray: StandInterfaceResult; stdcall;
    function _GetAsStream: StandInterfaceResult; stdcall;
    function _GetParent: StandInterfaceResult; overload; stdcall;
    function _GetAsInterface: StandInterfaceResult; overload; stdcall;
    function _GetAsBytes:StandInterfaceResult;overload;stdcall;
    property AsInteger: Integer read GetAsInteger write SetAsInteger;
    property AsInt64: Int64 read GetAsInt64 write SetAsInt64;
    property AsBoolean: Boolean read GetAsBoolean write SetAsBoolean;
    property AsSingle: Single read GetAsSingle write SetAsSingle;
    property AsFloat: Double read GetAsFloat write SetAsFloat;
    property AsGuid: TGuid read GetAsGuid write SetAsGuid;
    property IsNull: Boolean read GetIsNull;
    property Name: PWideChar read GetName;
    property AsArray: IQParams read GetAsArray;
    property AsStream: IQStream read GetAsStream write SetAsStream;
    property AsString: IQString read GetAsString write SetAsString;
    property Parent: IQParams read GetParent;
    property ParamType: TQParamType read GetType;
    property AsInterface: IInterface read GetAsInterface write SetAsInterface;
    property Index: Integer read GetIndex;
  end;

  // 参数列表
  IQParams = interface
    ['{B5746B65-7586-4DED-AE20-D4FF9B6ECD9E}']
    function GetItems(AIndex: Integer): IQParam; overload; stdcall;
    function GetCount: Integer; stdcall;
    function ByName(const AName: PWideChar): IQParam; stdcall;
    function ByPath(APath: PWideChar): IQParam; stdcall;
    function Add(const AName: PWideChar; AParamType: TQParamType): IQParam;
      overload; stdcall;
    function Add(const AName: PWideChar; AChildren: IQParams): IQParam;
      overload; stdcall;
    function GetAsString: IQString; stdcall;
    procedure Delete(AIndex: Integer); stdcall;
    procedure Clear; stdcall;
    function IndexOf(const AParam: IQParam): Integer; stdcall;
    procedure SaveToStream(AStream: IQStream); stdcall;
    procedure LoadFromStream(AStream: IQStream); stdcall;
    procedure SaveToFile(const AFileName: PWideChar); stdcall;
    procedure LoadFromFile(const AFileName: PWideChar); stdcall;

    function _GetItems(AIndex: Integer): StandInterfaceResult;
      overload; stdcall;
    function _ByName(const AName: PWideChar): StandInterfaceResult; stdcall;
    function _ByPath(APath: PWideChar): StandInterfaceResult; stdcall;
    function _Add(const AName: PWideChar; AParamType: TQParamType)
      : StandInterfaceResult; overload; stdcall;
    function _Add(const AName: PWideChar; AChildren: IQParams)
      : StandInterfaceResult; overload; stdcall;
    function _GetAsString: StandInterfaceResult; stdcall;

    property Items[AIndex: Integer]: IQParam read GetItems; default;
    property count: Integer read GetCount;
    property AsString: IQString read GetAsString;
  end;

  // 版本信息
  TQShortVersion = packed record
    case Integer of
      0:
        (Major, Minor, Release, Build: BYTE); // 主、副、发布、构建的版本号
      1:
        (value: Integer);
  end;
{$IF RTLVersion>=21}
{$M+}
{$IFEND}

  // 版本信息结构
  TQVersion = packed record
    Version: TQShortVersion; // 版本
    Company: array [0 .. 63] of WideChar; // 公司名
    Name: array [0 .. 63] of WideChar; // 模块名称
    Description: array [0 .. 255] of WideChar; // 描述
    fileName: array [0 .. 259] of WideChar; // 原始文件名
  end;

  // 插件版本信息
  IQVersion = interface
    ['{4AD82500-4148-45D1-B0F8-F6B6FB8B7F1C}']
    function GetVersion(var AVerInfo: TQVersion): Boolean; stdcall;
  end;

  IQServices = interface;
  IQLoader = interface;

  IQMultiInstanceExtension = interface
    ['{A13CADF7-96EE-4B95-B3CA-1476EBC19A41}']
    function GetInstance(var AResult: IInterface): Boolean;stdcall;
  end;

  // 单个服务
  IQService = interface
    ['{0DA5CBAC-6AB0-49FA-B845-FDF493D9E639}']
    function GetInstance: IQService; stdcall;
    function GetOwnerInstance: THandle; stdcall;
    function Execute(AParams: IQParams; AResult: IQParams): Boolean; stdcall;
    function Suspended(AParams: IQParams): Boolean; stdcall;
    function Resume(AParams: IQParams): Boolean; stdcall;
    function GetParent: IQServices; stdcall;
    function GetInstanceCreator: IQService; stdcall;
    procedure AddExtension(AInterface: IInterface); stdcall;
    procedure RemoveExtension(AInterface: IInterface); stdcall;
    procedure SetParent(AParent: IQServices); stdcall;
    function GetName: PWideChar; stdcall;
    function GetAttrs: IQParams; stdcall;
    function GetLastErrorMsg: PWideChar; stdcall;
    function GetLastErrorCode: Cardinal; stdcall;
    function GetId: TGuid; stdcall;
    function GetLoader: IQLoader; stdcall;
    function GetOriginObject: Pointer; stdcall;
    function IsInModule(AModule: THandle): Boolean; stdcall;

    function _GetInstance: StandInterfaceResult; stdcall;
    function _GetParent: StandInterfaceResult; stdcall;
    function _GetInstanceCreator: StandInterfaceResult; stdcall;
    function _GetAttrs: StandInterfaceResult; stdcall;

    property Parent: IQServices read GetParent write SetParent;
    property Name: PWideChar read GetName;
    property Attrs: IQParams read GetAttrs;
    property LastError: Cardinal read GetLastErrorCode;
    property LastErrorMsg: PWideChar read GetLastErrorMsg;
    property Loader: IQLoader read GetLoader;
    property Creator: IQService read GetInstanceCreator;
  end;

  // 多个服务列表
  IQServices = interface(IQService)
    ['{7325DF17-BC83-4163-BB72-0AE0208352ED}']
    function GetItems(AIndex: Integer): IQService; stdcall;
    function GetCount: Integer; stdcall;
    function ByPath(APath: PWideChar): IQService; stdcall;
    function ById(const AId: TGuid; ADoGetInstance: Boolean = true)
      : IQService; stdcall;
    function Add(AItem: IQService): Integer; stdcall;
    function IndexOf(AItem: IQService): Integer; stdcall;
    procedure Delete(AIndex: Integer); stdcall;
    procedure Remove(AItem: IQService); stdcall;
    function MoveTo(AIndex, ANewIndex: Integer): Boolean; stdcall;
    procedure Clear; stdcall;
    function GetName: PWideChar; stdcall;
    function GetOwnerInstance: HINST; stdcall;
    //
    function _GetItems(AIndex: Integer): StandInterfaceResult; stdcall;
    function _ByPath(APath: PWideChar): StandInterfaceResult; stdcall;
    function _ById(const AId: TGuid; ADoGetInstance: Boolean = true)
      : StandInterfaceResult; stdcall;

    property Name: PWideChar read GetName;
    property Parent: IQServices read GetParent;
    property count: Integer read GetCount;
    property Items[AIndex: Integer]: IQService read GetItems; default;
  end;

  // 通知响应接口
  IQNotify = interface
    ['{00C7F80F-44BF-4E60-AA58-5992B2B71754}']
    procedure Notify(const AId: Cardinal; AParams: IQParams;
      var AFireNext: Boolean); stdcall;
  end;

  TQSubscribeEnumCallback = procedure(ANotify: IQNotify; AParam: Int64;
    var AContinue: Boolean); stdcall;

  // 通知管理器
  IQNotifyManager = interface
    ['{037DCCD1-6877-4917-A315-120CD3E403F4}']
    function Subscribe(ANotifyId: Cardinal; AHandler: IQNotify)
      : Boolean; stdcall;
    procedure Unsubscribe(ANotifyId: Cardinal; AHandler: IQNotify); stdcall;
    function IdByName(const AName: PWideChar): Cardinal; stdcall;
    function NameOfId(const AId: Cardinal): PWideChar; stdcall;
    procedure Send(AId: Cardinal; AParams: IQParams); stdcall;
    procedure Post(AId: Cardinal; AParams: IQParams); stdcall;
    procedure Clear;
    function EnumSubscribe(ANotifyId: Cardinal;
      ACallback: TQSubscribeEnumCallback; AParam: Int64): Integer; stdcall;
    function GetCount: Integer; stdcall;
    function GetId(const AIndex: Integer): Cardinal; stdcall;
    function GetName(const AIndex: Integer): PWideChar; stdcall;
    property count: Integer read GetCount;
    property Id[const AIndex: Integer]: Cardinal read GetId;
    property Name[const AIndex: Integer]: PWideChar read GetName;
  end;

  // 基于文本的路由规则项目，此接口仅为显示和修改使用
  IQTextRouter = interface
    ['{F3834278-4D2F-46D5-AA72-6EF016CE7F3A}']
    function GetSource: PWideChar; stdcall; // 规则源
    function GetTarget: PWideChar; stdcall; // 规则目标
    procedure SetRule(const ASource, ATarget: PWideChar); stdcall; // 设置目标和源
  end;

  // 基于 ID 映射的规则项目
  IQIdRouter = interface
    ['{C2390553-ABE3-489A-8713-CB28A938C000}']
    function GetSource: TGuid; stdcall;
    function GetTarget: TGuid; stdcall;
    procedure SetRule(const ASource, ATarget: TGuid); stdcall;
  end;

  TQModuleState = (msUnknown, msLoading, msLoaded, msUnloading);
  TQLoaderState = (lsIdle, lsLoading, lsUnloading);

  // 加载器接口，它的实现基类是 TQBaseLoader
  IQLoader = interface
    ['{3F576A14-D251-47C4-AB6E-0F89B849B71F}']
    function GetServiceSource(AService: IQService; ABuf: PWideChar;
      ALen: Integer): Integer; stdcall;
    procedure Start; stdcall;
    procedure Stop; stdcall;
    function LoadServices(const AFileName: PWideChar): THandle;
      stdcall; overload;
    function LoadServices(const AStream: IQStream): THandle; stdcall; overload;
    function UnloadServices(const AHandle: THandle; AWaitDone: Boolean = true)
      : Boolean; stdcall;
    function GetModuleCount: Integer; stdcall;
    function GetModuleName(AIndex: Integer): PWideChar; stdcall;
    function GetModules(AIndex: Integer): HMODULE; stdcall;
    function GetModuleState(AInstance: HINST): TQModuleState; stdcall;
    procedure SetLoadingModule(AInstance: HINST); stdcall;
    function GetLoadingFileName: PWideChar; stdcall;
    function GetLoadingModule: HINST; stdcall;
    function GetState: TQLoaderState; stdcall;
  end;

  // 日志接口，一般由宿主提供，Delphi默认使用QLog封装
  IQLog = interface(IQService)
    ['{14F4C543-2D43-4AAD-BAFE-B25784BC917D}']
    procedure Post(ALevel: BYTE; AMsg: PWideChar); stdcall;
    procedure Flush; stdcall;
  end;

  // QWorker接口封装
  IQNotifyCallback = interface
    ['{8039F16A-0D0C-42C9-B891-454935371ACE}']
    procedure DoNotify(ASender: IInterface); stdcall;
  end;

  IQJobCallback = interface
    ['{886BE1F7-3365-4F81-9CEA-742EBD833584}']
    procedure DoJob(AParams: IQParams); stdcall;
    procedure AfterDone;stdcall;
    procedure BeforeCancel;stdcall;
  end;

  IQForJobManager = interface
    ['{F67881A5-92C6-4656-8073-C58E4DA43BF7}']
    procedure BreakIt; stdcall;
    function GetStartIndex: Int64; stdcall;
    function GetStopIndex: Int64; stdcall;
    function GetBreaked: Boolean; stdcall;
    function GetRuns: Int64; stdcall;
    function GetTotalTime: Int64; stdcall;
    function GetAvgTime: Int64; stdcall;
  end;

  IQForJobCallback = interface
    ['{9A29AC85-2A57-4C01-8313-E7D3A7C29904}']
    procedure DoJob(AMgr: IQForJobManager; AIndex: Int64;
      AParams: IQParams); stdcall;
  end;

  IQJobGroup = interface
    ['{061C27B2-1D09-42FA-8A80-B738E8CFA5F3}']
    procedure Cancel(AWaitRunningDone: Boolean = true); stdcall;
    procedure Prepare; stdcall;
    procedure Run(ATimeout: Cardinal = INFINITE); stdcall;
    function Insert(AIndex: Integer; AJob: IQJobCallback; AParams: IQParams;
      ARunInMainThread: Boolean): Boolean; stdcall;
    function Add(AJob: IQJobCallback; AParams: IQParams; AInMainThread: Boolean)
      : Boolean; stdcall;
    function Wait(ABlockMessage: Boolean; ATimeout: Cardinal = INFINITE)
      : TWaitResult; overload;
    function GetCount: Integer; stdcall;
    procedure SetAfterDone(AValue: IQNotifyCallback); stdcall;
    function GetAfterDone: IQNotifyCallback; stdcall;
    function GetByOrder: Boolean; stdcall;
    function GetRuns: Integer; stdcall;
    property Count: Integer read GetCount;
    function _GetAfterDone: StandInterfaceResult; stdcall;
    property AfterDone: IQNotifyCallback read GetAfterDone write SetAfterDone;
    property ByOrder: Boolean read GetByOrder;
    property Runs: Integer read GetRuns;
  end;

  IQWorkers = interface
    ['{94B6F5B4-1C16-448F-927C-DD8772DDAA78}']
    function Post(AJob: IQJobCallback; AParams: IQParams;
      ARunInMainThread: Boolean): Int64; stdcall;
    function Timer(AJob: IQJobCallback; AInterval: Cardinal; AParams: IQParams;
      ARunInMainThread: Boolean): Int64; stdcall;
    function Delay(AJob: IQJobCallback; AParams: IQParams; ADelay: Int64;
      ARunInMainThread, AIsRepeat: Boolean): Int64; stdcall;
    function At(AJob: IQJobCallback; AParams: IQParams; ATime: TDateTime;
      AInterval: Cardinal; ARunInMainThread: Boolean): Int64; stdcall;
    function Plan(AJob: IQJobCallback; AParams: IQParams; APlan: PWideChar;
      ARunInMainThread: Boolean): Int64; stdcall;
    procedure &For(AJob: IQForJobCallback; AParams: IQParams;
      AStart, AStop: Int64; AMsgWait: Boolean); stdcall;
    procedure Clear(AHandle: Int64; AWaitRunningDone: Boolean); stdcall;
    function CreateJobGroup(AByOrder: Boolean): IQJobGroup; stdcall;
    procedure SetWorkers(const AMinWorkers, AMaxWorkers: Integer); stdcall;
    procedure PeekCurrentWorkers(var ATotal, AIdle, ABusy: Integer); stdcall;
    function RegisterSignal(const ASignal:PWideChar):Integer;stdcall;
    function WaitSignal(const ASignal:PWideChar;AJob:IQJobCallback;ARunInMainThread:Boolean):Int64;stdcall;
    procedure Signal(const ASignal:PWideChar;AParams:IQParams);
    //
    function _CreateJobGroup(AByOrder: Boolean): StandInterfaceResult; stdcall;
  end;

  TQServiceCallback = procedure(const AService: IQService); stdcall;

  // 插件管理器，所有服务的总管家
  IQPluginsManager = interface(IQServices)
    ['{BDE6247B-87AD-4105-BDC9-1EA345A9E4B0}']
    function GetLoaders: IQServices; stdcall;
    function GetRouters: IQServices; stdcall;
    function GetServices: IQServices; stdcall;
    function ForcePath(APath: PWideChar): IQServices; stdcall;
    function GetActiveLoader: IQLoader; stdcall;
    procedure SetActiveLoader(ALoader: IQLoader); stdcall;
    procedure Start; stdcall;
    procedure ModuleUnloading(AInstance: HINST); stdcall;
    procedure AsynCall(AProc: TQAsynProc; AParams: IQParams); stdcall;
    procedure ProcessQueuedCalls; stdcall;
    function Stop: Boolean; stdcall;
    function Replace(ANewManager: IQPluginsManager): Boolean; stdcall;
    function WaitService(const AService: PWideChar; ANotify: TQServiceCallback)
      : Boolean; overload; stdcall;
    function WaitService(const AId: TGuid; ANotify: TQServiceCallback): Boolean;
      overload; stdcall;
    procedure RemoveServiceWait(ANotify: TQServiceCallback); overload; stdcall;
    procedure RemoveServiceWait(const AService: PWideChar;
      ANotify: TQServiceCallback); overload; stdcall;
    procedure RemoveServiceWait(const AId: TGuid; ANotify: TQServiceCallback);
      overload; stdcall;
    procedure ServiceReady(AService: IQService); stdcall;
    function NewParams: IQParams; stdcall;
    function NewString: IQString; overload; stdcall;
    function NewString(const ASource: PWideChar): IQString; overload; stdcall;

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
    property Services: IQServices read GetServices;
    property Routers: IQServices read GetRouters;
    property Loaders: IQServices read GetLoaders;
    property ActiveLoader: IQLoader read GetActiveLoader write SetActiveLoader;
  end;

  // 提供跨语言类型封装支持

  IQLocker = interface
    ['{5008B5D4-EE67-419D-80CB-E5C62FA95243}']
    procedure Lock; stdcall;
    procedure Unlock; stdcall;
  end;

