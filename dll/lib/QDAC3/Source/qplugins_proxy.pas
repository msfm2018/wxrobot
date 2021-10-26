unit qplugins_proxy;

interface

{$I 'qdac.inc'}

uses classes, sysutils, qstring, qplugins, qplugins_base,qplugins_params, windows,
  messages, syncobjs{$IF RTLVersion>21}, Generics.collections{$IFEND},
  qsimplepool;
{$HPPEMIT '#pragma link "qplugins_proxy"'}

type
  TQPendingCallback = procedure(ASerivce: IQService; AParams, AResult: IQParams;
    ATag: Pointer) of object;

  TQPendingRPC = class
  private
    FParams: IQParams;
    FResult: IQParams;
    FTag: Pointer;
    FService: IQService;
    FEvent: TEvent;
    FErrorCode: Cardinal;
    FErrorMsg: QStringW;
    FCallback: TQPendingCallback;
  public
    constructor Create(AService: IQService; AParams, AResult: IQParams;
      ATag: Pointer); overload;
    destructor Destroy; override;
    function WaitFor(ATimeout: Cardinal): TWaitResult;
    procedure SetEvent;
    property Params: IQParams read FParams;
    property Result: IQParams read FResult;
    property Tag: Pointer read FTag;
    property Callback: TQPendingCallback read FCallback write FCallback;
    property ErrorCode: Cardinal read FErrorCode write FErrorCode;
    property ErrorMsg: QStringW read FErrorMsg write FErrorMsg;
  end;

  // 远程过程进程
  TQRPCProcess = class
  protected
    FPath, FWorkDir: QStringW; // 服务提供进程路径，使用URI方式来定位，本地为：file:///xxxx?
    FLocker: TCriticalSection;
    function InternalSend(ACall: TQPendingRPC): Boolean; virtual; abstract;
    property Path: QStringW read FPath;

  public
    constructor Create(APath: String); overload; virtual;
    procedure Lock;
    procedure Unlock;
  end;

{$IF RTLVersion>21}

  TQProcessList = TList<TQRPCProcess>;
{$ELSE}
  TQProcessList = TList;
{$IFEND}
  TQProxyService = class;

  TQRPCProcesses = class(TCriticalSection)
  private
    function GetCount: Integer;
    function GetItems(AIndex: Integer): TQRPCProcess;
  protected
    FItems: TQProcessList;
    FEvents: TQSimplePool;
    function InternalPost(ACall: TQPendingRPC): Boolean; virtual;
    procedure DoNewEvent(ASender: TQSimplePool; var AData: Pointer);
    procedure DoFreeEvent(ASender: TQSimplePool; AData: Pointer);
  public
    constructor Create; overload;
    destructor Destroy; override;
    procedure Clear;
    // 投寄一个不关心返回结果的请求
    function Post(AService: IQService; AParams, AResult: IQParams;
      ATag: Pointer): TQPendingRPC; overload;
    function Post(AService: IQService; AParams, AResult: IQParams;
      ATag: Pointer; ACallback: TQPendingCallback): Boolean; overload;
    function Send(AService: IQService; AParams, AResult: IQParams): Boolean;
    property Count: Integer read GetCount;
    property Items[AIndex: Integer]: TQRPCProcess read GetItems; default;
  end;

  TQProxyService = class(TQService)
  protected
    FProcess: TQRPCProcess;
  public
    function Execute(AParams: IQParams; AResult: IQParams): Boolean;
      override; stdcall;
    property Process: TQRPCProcess read FProcess; // 服务所隶属的进程
  end;

var
  RemoteProcesses: TQRPCProcesses;

implementation

{ TQRPCProcesses }

procedure TQRPCProcesses.Clear;
var
  I: Integer;
begin
  Enter;
  try
    for I := 0 to FItems.Count - 1 do
      FreeObject(FItems[I]);
    FItems.Clear;
  finally
    Leave;
  end;
end;

constructor TQRPCProcesses.Create;
begin
  inherited Create;
  FItems := TQProcessList.Create;
  FEvents := TQSimplePool.Create(100, SizeOf(Pointer));
  FEvents.OnNewItem := DoNewEvent;
  FEvents.OnFree := DoFreeEvent;
end;

destructor TQRPCProcesses.Destroy;
begin
  Clear;
  FreeAndNil(FItems);
  FreeAndNil(FEvents);
  inherited;
end;

procedure TQRPCProcesses.DoFreeEvent(ASender: TQSimplePool; AData: Pointer);
begin
  FreeAndNil(AData);
end;

procedure TQRPCProcesses.DoNewEvent(ASender: TQSimplePool; var AData: Pointer);
begin
  AData := TEvent.Create(nil, false, false, '');
end;

function TQRPCProcesses.GetCount: Integer;
begin
  Result := FItems.Count;
end;

function TQRPCProcesses.GetItems(AIndex: Integer): TQRPCProcess;
begin
  Result := FItems[AIndex];
end;

function TQRPCProcesses.InternalPost(ACall: TQPendingRPC): Boolean;
begin
  Result := TQProxyService(ACall.FService.GetOriginObject)
    .FProcess.InternalSend(ACall);
end;

function TQRPCProcesses.Post(AService: IQService; AParams, AResult: IQParams;
  ATag: Pointer): TQPendingRPC;
begin
  Result := TQPendingRPC.Create(AService, AParams, AResult, ATag);
  try
    if not InternalPost(Result) then
      FreeAndNil(Result);
  except
    FreeAndNil(Result);
  end;
end;

function TQRPCProcesses.Post(AService: IQService; AParams, AResult: IQParams;
  ATag: Pointer; ACallback: TQPendingCallback): Boolean;
var
  ACall: TQPendingRPC;
begin
  ACall := TQPendingRPC.Create(AService, AParams, AResult, ATag);
  try
    ACall.Callback := ACallback;
    Result := InternalPost(ACall);
    if not Result then
      FreeAndNil(ACall);
  except
    FreeAndNil(ACall);
  end;
end;

function TQRPCProcesses.Send(AService: IQService;
  AParams, AResult: IQParams): Boolean;
var
  ACall: TQPendingRPC;
begin
  ACall := TQPendingRPC.Create(AService, AParams, AResult, nil);
  try
    Result := InternalPost(ACall);
    if Result then
    begin
      if ACall.FEvent.WaitFor(INFINITE) = wrSignaled then
        Result := True;
    end;
  finally
    FreeAndNil(ACall);
  end;
end;

{ TQProxyService }

function TQProxyService.Execute(AParams, AResult: IQParams): Boolean;
begin
  Result := RemoteProcesses.Send(Self, AParams, AResult);
end;

{ TQPendingRPC }

constructor TQPendingRPC.Create(AService: IQService; AParams, AResult: IQParams;
  ATag: Pointer);
begin
  inherited Create;
  FService := AService;
  FParams := AParams;
  FResult := AResult;
  FTag := ATag;
  FEvent := RemoteProcesses.FEvents.Pop;
end;

destructor TQPendingRPC.Destroy;
begin
  RemoteProcesses.FEvents.Push(FEvent);
  inherited;
end;

procedure TQPendingRPC.SetEvent;
begin
  FEvent.SetEvent;
end;

function TQPendingRPC.WaitFor(ATimeout: Cardinal): TWaitResult;
begin
  Result := FEvent.WaitFor(ATimeout);
end;

{ TQRPCProcess }

constructor TQRPCProcess.Create(APath: String);
begin
  inherited Create;
  FPath := APath;
  FLocker := TCriticalSection.Create;
end;

procedure TQRPCProcess.Lock;
begin
  FLocker.Enter;
end;

procedure TQRPCProcess.Unlock;
begin
  FLocker.Leave;
end;

initialization

RemoteProcesses := TQRPCProcesses.Create();

end.
