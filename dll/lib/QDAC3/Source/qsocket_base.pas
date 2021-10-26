unit qsocket_base;

interface

uses classes, sysutils, qstring, qworker, syncobjs;

type
  {
    数据传输过程：
    【发送数据】
    请求数据流 -> 封装为 IQBaseSession 会话 -> 通过 IQBaseDispatcher.Transmit 接口对会话数据进行编码
    ->循环通过 IQBaseTransport.SendBuffer 接口发送数据
    【接收数据】
    接收到数据->检查会话是否存在，不存在则创建 IQBaseSession 会话->接收会话完成调用 IQBaseDispatcher.Dispatch 接口派发
    ->如果需要回应，派发函数调用 IQBaseDispatcher.NewReplySession 创建回复会话，然后按发送数据流程发送回应
    【广播数据】
    广播的数据用 IQBaseDispatcher.NewSession 来创建一个供广播用的会话，然后调用 IQBaseTransport.Broadcast 来发送数据到全部连接
    【组播数据】
    组播前需要用 IQBaseTransport.NewGroup 来创建一个分组，然后调用 IQBaseDispatch.NewSession 来创建一个会话，然后调用
    IQBaseGroup.Broadcast 函数将广播发送数据到组内全部连接

    !!! 频繁广播或组播数据可能造成网络堵塞，所以要慎用 !!!
  }
  TQBaseConnection = class;

  TQConnectionNotifyEvent = procedure(ASender: TQBaseConnection) of object;
  TQConnectionCallback = procedure(ASender: TQBaseConnection; AParam: IntPtr)
    of object;

  IQBaseTransport = interface;

  // 连接
  IQBaseConnection = interface
    ['{82DE0DD9-48A9-49CD-A798-C3B37BD89810}']
    function GetTransport: IQBaseTransport;
    function Connect: Boolean;
    procedure Disconnect;
    function GetRemoteAddr: QStringW;
    procedure SetRemoteAddr(const AValue: QStringW);
    function GetLocalAddr: QStringW;
    function GetConnected: Boolean;
    procedure SetLocalAddr(const AValue: QStringW);
    property Transport: IQBaseTransport read GetTransport;
    property RemoteAddr: QStringW read GetRemoteAddr write SetRemoteAddr;
    property LocalAddr: QStringW read GetLocalAddr write SetLocalAddr;
    property Connected: Boolean read GetConnected;
  end;

  TQConnectionEnumCallback = reference to procedure(ASender: IQBaseTransport;
    AConnection: IQBaseConnection; var AContinue: Boolean);

  IQBaseConnections = interface
    ['{B1906599-B938-4447-9A96-D8670AD87A37}']
    function GetTransport: IQBaseTransport;
    function GetCount: Integer;
    function Find(const Addr: QStringW): IQBaseConnection;
    // 因为内部连接不一定用列表存贮，所以不使用列表式方式
    procedure ForEach(ACallback: TQConnectionEnumCallback);
    property Transport: IQBaseTransport read GetTransport;
    property Count: Integer read GetCount;
  end;

  IQBaseConnectionGroup = interface
    ['{B509CDDB-E0C2-42C5-82E1-B4111F49A334}']
    procedure Join(AConnection: IQBaseConnection);
    procedure Leave(AConnection: IQBaseConnection);
    function GetCount: Integer;
    procedure ForEach(ACallback: TQConnectionEnumCallback);
    property Count: Integer read GetCount;
  end;

  TQSessionState = (ssRecving, ssSending, ssReply, ssDone, ssCanceled,
    ssMustArrive);
  TQSessionStates = set of TQSessionState;

  IQBaseSession = interface
    ['{DCAC7533-B793-4B46-A8AC-EBC3B65FEA12}']
    function GetId: Int64;
    function GetRefId: Int64;
    function GetRequestStream: TStream;
    function GetReplyStream: TStream;
    function GetConnection: IQBaseConnection;
    function GetStates: TQSessionStates;
    procedure SetStates(const AStates: TQSessionStates);
    property Id: Int64 read GetId;
    property RequestStream: TStream read GetRequestStream;
    property ReplyStream: TStream read GetReplyStream;
    property Connection: IQBaseConnection read GetConnection;
    property States: TQSessionStates read GetStates write SetStates;
  end;

  TQDispatchHandler = procedure(ASession: IQBaseSession; var AHandled: Boolean)
    of object;

  IQBaseDispatcher = interface
    ['{0A49A4F8-3620-49BF-943A-4EDC8A8ED5A3}']
    // 实际上BaseDispatch根本不知道如何派发，所以把会话数据传进去就算了，怎么处理是上层的事
    procedure Dispatch(ASession: IQBaseSession);
    // 从会话流中解析出会话请求命令并存贮到 ACmdBuf 中，返回实际的命令内容长度，失败返回 0
    function DecodeCmd(ASession: IQBaseSession; ACmdBuf: PByte): Integer;
    // 传送指定的会话对远程
    procedure Transmit(ASession: IQBaseSession);

    // 注册一个事件处理函数，因为在这一层面不知道命令的类型，所以传的是地址和长度
    procedure RegisterHandler(ACmd: Pointer; ACmdLen: Integer;
      AHandler: TQDispatchHandler);
    // 查询一个会话需要派发的命令对应的派发函数
    function FindHandler(ACmd: Pointer; ACmdLen: Integer): TQDispatchHandler;
    // 注册默认的事件处理函数，如果没有任何已知的派发，则走此派函数处理
    procedure RegisterDefaultHandler(AHandler: TQDispatchHandler);
    procedure UnregisterHandler(ACmd: Pointer; ACmdLen: Integer;
      AHandler: TQDispatchHandler);
    procedure UnregisterDefaultHandler(AHandler: TQDispatchHandler);
    // 新建会话，如果没有AReplyStream为空，则内部在需要时自动创建内存流接收回应结果
    // 在传输大量数据时，需要通过文件来存贮会话结果，就需要传递AReplyStream
    function NewSession(AConnection: IQBaseConnection;
      ARequestStream, AReplyStream: TStream): IQBaseSession;
    function NewReplySession(ARequest: IQBaseSession; AReplyStream: TStream)
      : IQBaseSession;
    // 派发指令最大字节长度，DecodeCmd时传进去的ACmdBuf长度为该大小
    function GetMaxCommandLength: Integer;
    property MaxCommandLength: Integer read GetMaxCommandLength;
  end;

  // 黑白名单，用来限制从某一地址过来的连接，直接在连接一建立就放弃掉，以避免额外的开销。
  // 注意黑名单优先，一个地址如果在黑名单里，则不管其是否在白名称里，都阻止连接
  IQAddrList = interface;

  TQAddrListEnumCallback = reference to procedure(ASender: IQAddrList;
    const Addr: QStringW; var AContinue: Boolean);

  IQAddrList = interface
    ['{9E56EFC2-720C-4ED6-96EE-A1F7F36294F2}']
    function GetTransport: IQBaseTransport;
    procedure Add(const Addr: QStringW);
    procedure Remove(const Addr: QStringW);
    function Contains(const Addr: QStringW): Boolean;
    function ForEach(ACallback: TQAddrListEnumCallback): Integer;
    function GetCount: Integer;
    property Transport: IQBaseTransport read GetTransport;
    property Count: Integer read GetCount;
  end;

  TQTransportState = (tsEnableBlackList, tsEnableWhiteList, tsListening);

  TQTransportStates = set of TQTransportState;

  IQBaseTransport = interface
    ['{0D149B26-02C7-4E12-AE85-F0DE6A1672D1}']
    function GetSchema: String;
    function GetVersion: String;
    function Startup: Boolean;
    procedure Cleanup;
    function Listen: Boolean;
    procedure Accept;
    function NewConnection(const ARemoteAddr: QStringW): IQBaseConnection;
    function NewGroup: IQBaseConnectionGroup;
    procedure Broadcast(ASession: IQBaseSession);
    function Bind(Addr: QStringW): Boolean;
    function GetConnections: IQBaseConnections;
    function GetDispatcher: IQBaseDispatcher;
    procedure SetDispatcher(const ADispatcher: IQBaseDispatcher);
    function GetBlackList: IQAddrList;
    function GetWhiteList: IQAddrList;
    function GetStates: TQTransportStates;
    property Schema: String read GetSchema;
    property Version: String read GetVersion;
    property Connections: IQBaseConnections read GetConnections;
    property Dispatcher: IQBaseDispatcher read GetDispatcher
      write SetDispatcher;
    property BlackList: IQAddrList read GetBlackList;
    property WhiteList: IQAddrList read GetWhiteList;
    property States: TQTransportStates read GetStates;
  end;

  TQBaseConnection = class
  protected
    FLocalAddr, FRemoteAddr: QStringW;
    FTag: IntPtr;
    FConnected: Boolean;
  public
  end;

  procedure RegisterTransport(ATransport:IQBaseTransport);

implementation

resourcestring
  SCantConnectToRemote = '无法连接到远程地址:%s。';
  SCantCreateHandle = '无法创建连接句柄。';
  SAsynWaitNotSupport = '连接不支持异步等待数据。';

procedure RegisterTransport(ATransport:IQBaseTransport);
begin
 //Todo:管理传输泵注册
end;

end.
