unit QNamePipe;

interface

uses classes, types, sysutils, windows, TlHelp32, qstring,QSimplePool,
  syncobjs{$IFDEF UNICODE},
  Generics.Collections{$ENDIF};

type

  TQNamedPipe = class;
  TQNamedPipeClient = class;
  PQNamedPipeClient = ^TQNamedPipeClient;
{$IFDEF UNICODE}
  TQNamedPipeClientList = TList<TQNamedPipeClient>;
{$ELSE}
  TQNamedPipeClientList = TList;
{$ENDIF}
  TQNamedPipeIOEvent = procedure(ASender: TQNamedPipe; const AData: PByte;
    const ASize: Integer) of object;

  TQNamedPipe = class
  protected
    FActive: Boolean;
    FName: QStringW;
    FSentBytes: Int64;
    FRecvBytes: Int64;
    FLastError: Cardinal;
    FAfterRecvData: TQNamedPipeIOEvent;
    FAfterSentData: TQNamedPipeIOEvent;
    procedure SetActive(const Value: Boolean);

  public
    constructor Create(const AName: QStringW); overload;
    destructor Destroy; override;
    procedure Open; virtual; abstract;
    procedure Close; virtual; abstract;
    property Name: QStringW read FName;
    property SentBytes: Int64 read FSentBytes;
    property RecvBytes: Int64 read FRecvBytes;
    property LastError: Cardinal read FLastError;
    property Active: Boolean read FActive write SetActive;
  end;

  TQNamedPipeServerNotifyEvent = procedure(ASender: TQNamedPipe;
    AClient: TQNamedPipeClient);

  TQNamedPipeServer = class(TQNamedPipe)
  protected
    FClients: TQNamedPipeClientList;
    FIOThread: TThread;
    FEvent: THandle;
    FPool: TQSimplePool;
    FAfterAccept: TQNamedPipeServerNotifyEvent;
    FAfterClientDisconnect: TQNamedPipeServerNotifyEvent;
    function GetClientCount: Integer;
    function GetClients(AIndex: Integer): TQNamedPipeClient;
    procedure DoAccept(AClient: TQNamedPipeClient);
    procedure DoClientDisconnect(AClient: TQNamedPipeClient);
    // pool helper
    procedure DoNewClient(ASender: TQSimplePool; var AData: Pointer);
    procedure DoFreeClient(ASender: TQSimplePool; AData: Pointer);
    procedure DoResetClient(ASender: TQSimplePool; AData: Pointer);
  public
    constructor Create(const AName: QStringW); overload;
    destructor Destroy; override;
    procedure Open; override;
    procedure Close; override;
    property Clients[AIndex: Integer]: TQNamedPipeClient read GetClients;
    property ClientCount: Integer read GetClientCount;
    property AfterAccept: TQNamedPipeServerNotifyEvent read FAfterAccept
      write FAfterAccept;
    property AfterClientDisconnect: TQNamedPipeServerNotifyEvent
      read FAfterClientDisconnect write FAfterClientDisconnect;
  end;

  TQNamedPipeOverlapped = record
    Sys: OVERLAPPED;
    NamedPipe: TQNamedPipeClient;
    Buf: TBytes;
  end;

  PQNamedPipeOverlapped = ^TQNamedPipeOverlapped;

  TQNamedPipeClient = class(TQNamedPipe)
  private
  protected
    FHandle: THandle;
    FReadEvent: THandle;
    FInWaiting: Boolean;
    FReading: Boolean;
    FLastRecvBytes: TBytes;
    FServer: TQNamedPipeServer;
    FOnError: TNotifyEvent;
    FReadOverlapped: PQNamedPipeOverlapped;
    procedure DoAfterSent(const ABytes: PByte; ASize: Cardinal);
    procedure DoAfterRecv(const ABytes: PByte; ASize: Cardinal);
    procedure HandleNeeded;
    function GetClientComputerName: QStringW;
    function GetClientProcessId: Cardinal;
    function GetClientSessionId: Cardinal;
    function GetServerSessionId: Cardinal;
    function GetServerProcessId: Cardinal;
    procedure PostRead;
    procedure WaitReply;
    procedure DoError;
  public
    constructor Create(const AName: QStringW); overload;
    destructor Destroy; override;
    procedure Open; override;
    procedure Close; override;
    procedure Post(const AData: PByte; ASize: Integer); overload;
    procedure Post(const AData: TBytes); overload;
    procedure Post(const AData: QStringW); overload;
    function Send(const AData: PByte; ASize: Integer): TBytes; overload;
    function Send(const AData: TBytes): TBytes; overload;
    function Send(const AData: QStringW): TBytes; overload;
    property ServerSessionId: Cardinal read GetServerSessionId;
    property ServerProcessId: Cardinal read GetServerProcessId;
    property ClientSessionId: Cardinal read GetClientSessionId;
    property ClientProcessId: Cardinal read GetClientProcessId;
    property ClientComputerName: QStringW read GetClientComputerName;
    property Handle: THandle read FHandle;
    property AfterRecvData: TQNamedPipeIOEvent read FAfterRecvData
      write FAfterRecvData;
    property AfterSentData: TQNamedPipeIOEvent read FAfterSentData
      write FAfterSentData;
    property OnError: TNotifyEvent read FOnError write FOnError;
    property Server: TQNamedPipeServer read FServer;
  end;

implementation

const
  POOL_SIGN =
{$IFDEF CPU_X64}$4C4F4F504D495153 QSIMPOOL{$ELSE}$4C505351{$ENDIF};

  // 64位下是QSIMPOOL，32位下是QSPL
resourcestring
  SBadPtrToPool = '指针 %x 不是由缓冲池创建的对象，不能进行缓冲操作。';
  SBadSizePtrToPool = '指针 %x 的大小 %d 与池要求的成员大小 %d 不相符，不能进行缓冲操作。';

type
  TQNamedPipeIOThread = class(TThread)
  protected
    FNamedPipe: TQNamedPipeServer;
    function Accept: TQNamedPipeClient;
    procedure Execute; override;
  end;

var
  OverlayPool: TQSimplePool;
  ClientPool: TQSimplePool;

procedure NamedPipeWriteDone(dwErr, cbBytesWrite: Cardinal;
  lpOverlapped: POverlapped); stdcall;
var
  ov: PQNamedPipeOverlapped;
begin
ov := Pointer(lpOverlapped);
try
  if dwErr = 0 then
    ov.NamedPipe.DoAfterSent(@ov.Buf[0], cbBytesWrite)
  else
    begin
    ov.NamedPipe.FLastError := dwErr;
    ov.NamedPipe.DoError;
    end;
finally
  Dispose(ov);
end;
end;

procedure NamedPipeReadDone(dwErr, cbBytesRead: Cardinal;
  lpOverlapped: POverlapped); stdcall;
var
  ov: PQNamedPipeOverlapped;
begin
ov := Pointer(lpOverlapped);
try
  ov.NamedPipe.DoAfterRecv(@ov.Buf[0], cbBytesRead);
finally
  ov.NamedPipe.PostRead;
end;
end;
{ TQNamedPipe }

constructor TQNamedPipe.Create(const AName: QStringW);
begin
inherited Create;
FName := AName;
end;

destructor TQNamedPipe.Destroy;
begin
inherited;
end;

procedure TQNamedPipe.SetActive(const Value: Boolean);
begin
if FActive <> Value then
  begin
  if Value then
    Open
  else
    Close;
  end;
end;

{ TQNamedPipeIOThread }

function TQNamedPipeIOThread.Accept: TQNamedPipeClient;
var
  ovConnect: OVERLAPPED;
  rc: Cardinal;
begin
FillChar(ovConnect, SizeOf(OVERLAPPED), 0);
Result := FNamedPipe.FPool.Pop;
Result.FServer := FNamedPipe;
Result.FHandle := CreateNamedPipeW(PQCharW(FNamedPipe.Name),
  PIPE_ACCESS_DUPLEX or FILE_FLAG_OVERLAPPED, PIPE_TYPE_MESSAGE or
  PIPE_READMODE_MESSAGE or PIPE_WAIT, PIPE_UNLIMITED_INSTANCES, 65536, 65536,
  NMPWAIT_USE_DEFAULT_WAIT, nil);
if Result.FHandle = INVALID_HANDLE_VALUE then
  begin
  rc := GetLastError;
  FreeObject(Result);
  RaiseLastOSError(rc);
  end;
ovConnect.hEvent := FNamedPipe.FEvent;
if not ConnectNamedPipe(Result.FHandle, @ovConnect) then
  begin
  rc := GetLastError;
  if (rc = ERROR_IO_PENDING) then
    begin
    if WaitForSingleObjectEx(FNamedPipe.FEvent, INFINITE, True) = WAIT_OBJECT_0
    then
      begin
      if not Terminated then
        begin
        Result.FActive := True;
        FNamedPipe.DoAccept(Result);
        end
      else
        begin
        FNamedPipe.FPool.Push(Result);
        Result := nil;
        end;
      end;
    end
  else if rc = ERROR_PIPE_CONNECTED then
    begin
    Result.FActive := True;
    FNamedPipe.DoAccept(Result);
    end
  else
    begin
    FNamedPipe.FPool.Push(Result);
    RaiseLastOSError(rc);
    Result := nil;
    end;
  end
else
  begin
  Result.FActive := True;
  FNamedPipe.DoAccept(Result);
  end;
if Assigned(Result) then
  // 加入到列表
  FNamedPipe.FClients.Add(Result);
end;

procedure TQNamedPipeIOThread.Execute;

  procedure RunAsServer;
  var
    AClient: TQNamedPipeClient;
    AServer: TQNamedPipeServer;
  begin
  AServer := FNamedPipe as TQNamedPipeServer;
  while not Terminated do
    begin
    AClient := Accept;
    if Assigned(AClient) then
      AClient.PostRead;
    end;
  end;

begin
RunAsServer;
end;

{ TQNamedPipeClient }

procedure TQNamedPipeClient.Close;
begin
if FHandle <> 0 then
  begin
  if FServer <> nil then
    DisconnectNamedPipe(FHandle);
  CloseHandle(FHandle);
  FHandle := 0;
  end;
end;

constructor TQNamedPipeClient.Create(const AName: QStringW);
begin
inherited Create(AName);
FReadEvent := CreateEventW(nil, false, false, nil);
FReadOverlapped := OverlayPool.Pop;
FReadOverlapped.NamedPipe := Self;
SetLength(FReadOverlapped.Buf, 65536);
end;

destructor TQNamedPipeClient.Destroy;
begin
Close;
OverlayPool.Push(FReadOverlapped);
inherited;
end;

procedure TQNamedPipeClient.DoAfterRecv(const ABytes: PByte; ASize: Cardinal);
begin
AtomicIncrement(FRecvBytes, ASize);
if Assigned(FServer) then
  AtomicIncrement(FServer.FRecvBytes, ASize);
SetLength(FLastRecvBytes, ASize);
Move(ABytes^, FLastRecvBytes[0], ASize);
if FInWaiting then
  SetEvent(FReadEvent);
if Assigned(FAfterRecvData) then
  FAfterRecvData(Self, ABytes, ASize);
end;

procedure TQNamedPipeClient.DoAfterSent(const ABytes: PByte; ASize: Cardinal);
begin
AtomicIncrement(FSentBytes, ASize);
if Assigned(FServer) then
  AtomicIncrement(FServer.FSentBytes, ASize);
if Assigned(FAfterSentData) then
  FAfterSentData(Self, ABytes, ASize);
end;

procedure TQNamedPipeClient.DoError;
begin
if (FLastError <> 0) and Assigned(FOnError) then
  FOnError(Self);
end;

function TQNamedPipeClient.GetClientComputerName: QStringW;
var
  ALen: Integer;
  ABuf: array [0 .. 64] of WideChar;
begin
HandleNeeded;
ABuf[64] := #0;
if GetNamedPipeClientComputerNameW(Handle, @ABuf[0], 64) then
  Result := PQCharW(Result)
else
  SetLength(Result, 0);
end;

function TQNamedPipeClient.GetClientProcessId: Cardinal;
begin
HandleNeeded;
if not GetNamedPipeClientProcessId(Handle, Result) then
  Result := 0;
end;

function TQNamedPipeClient.GetClientSessionId: Cardinal;
begin
HandleNeeded;
if not GetNamedPipeClientSessionId(Handle, Result) then
  Result := 0;
end;

function TQNamedPipeClient.GetServerProcessId: Cardinal;
begin
HandleNeeded;
if not GetNamedPipeServerProcessId(Handle, Result) then
  Result := 0;
end;

function TQNamedPipeClient.GetServerSessionId: Cardinal;
begin
HandleNeeded;
if not GetNamedPipeServerSessionId(Handle, Result) then
  Result := 0;
end;

procedure TQNamedPipeClient.HandleNeeded;
begin
if FHandle = 0 then
  begin
  // 客户端用CreateFile创建一个连接
  FHandle := CreateFileW(PQCharW(FName), GENERIC_READ or GENERIC_WRITE, 0, nil,
    OPEN_EXISTING, FILE_FLAG_OVERLAPPED, 0);
  if FHandle = INVALID_HANDLE_VALUE then
    begin
    FLastError := GetLastError;
    FHandle := 0;
    raise EOSError.Create(SysErrorMessage(FLastError));
    end;
  end;
end;

procedure TQNamedPipeClient.Open;
begin
HandleNeeded;
FActive := True;
PostRead; // 投寄一个读取数据请求
end;

procedure TQNamedPipeClient.Post(const AData: PByte; ASize: Integer);
var
  ov: PQNamedPipeOverlapped;
begin
HandleNeeded;
New(ov);
ov.NamedPipe := Self;
SetLength(ov.Buf, ASize);
Move(AData^, ov.Buf[0], ASize);
WriteFileEx(Handle, @ov.Buf[0], ASize, ov.Sys, @NamedPipeWriteDone);
end;

procedure TQNamedPipeClient.Post(const AData: QStringW);
begin
Post(PByte(PQCharW(AData)), Length(AData) shl 1);
end;

procedure TQNamedPipeClient.PostRead;
begin
if not FReading then
  begin
  FReading := True;
  if not ReadFileEx(Handle, @FReadOverlapped, 65536, @FReadOverlapped,
    @NamedPipeReadDone) then
    begin
    FLastError := GetLastError;
    if FLastError <> ERROR_IO_PENDING then
      begin
      DoError;
      Close;
      end;
    end;
  end;
end;

procedure TQNamedPipeClient.Post(const AData: TBytes);
begin
Post(@AData[0], Length(AData));
end;

function TQNamedPipeClient.Send(const AData: PByte; ASize: Integer): TBytes;
begin
SetLength(FLastRecvBytes, 0);
Post(AData, ASize);
WaitReply;
Result := FLastRecvBytes;
end;

function TQNamedPipeClient.Send(const AData: QStringW): TBytes;
begin
SetLength(FLastRecvBytes, 0);
Post(AData);
WaitReply;
Result := FLastRecvBytes;
end;

procedure TQNamedPipeClient.WaitReply;
begin
if WaitForSingleObject(FReadEvent, INFINITE) <> WAIT_OBJECT_0 then
  SetLength(FLastRecvBytes, 0);
end;

function TQNamedPipeClient.Send(const AData: TBytes): TBytes;
begin
SetLength(FLastRecvBytes, 0);
Post(AData);
WaitReply;
Result := FLastRecvBytes;
end;

{ TQNamedPipeServer }

procedure TQNamedPipeServer.Close;
var
  AThreadId: TThreadId;
  I: Integer;
  function ThreadExists(AId: TThreadId): Boolean;
  var
    ASnapshot: THandle;
    AEntry: TThreadEntry32;
  begin
  Result := false;
  ASnapshot := CreateToolhelp32Snapshot(TH32CS_SNAPTHREAD, 0);
  if ASnapshot = INVALID_HANDLE_VALUE then
    Exit;
  try
    AEntry.dwSize := SizeOf(TThreadEntry32);
    if Thread32First(ASnapshot, AEntry) then
      begin
      repeat
        if AEntry.th32ThreadID = AId then
          begin
          Result := True;
          Break;
          end;
      until not Thread32Next(ASnapshot, AEntry);
      end;
  finally
    CloseHandle(ASnapshot);
  end;
  end;

begin
if Assigned(FIOThread) then
  begin
  AThreadId := FIOThread.ThreadID;
  FIOThread.Terminate;
  SetEvent(FEvent);
  FIOThread := nil;
  while ThreadExists(AThreadId) do
    Sleep(10);
  for I := 0 to FClients.Count - 1 do
    FreeObject(Clients[I]);
  FClients.Clear;
  end;
end;

constructor TQNamedPipeServer.Create(const AName: QStringW);
begin
inherited Create(AName);
FClients := TQNamedPipeClientList.Create;
FEvent := CreateEventW(nil, false, false, nil);
FPool := TQSimplePool.Create(1024, SizeOf(TQNamedPipeClient));
FPool.OnNewItem := DoNewClient;
FPool.OnFree := DoFreeClient;
FPool.OnReset := DoResetClient;
end;

destructor TQNamedPipeServer.Destroy;
begin
Close;
FreeObject(FClients);
inherited;
end;

procedure TQNamedPipeServer.DoAccept(AClient: TQNamedPipeClient);
begin
if Assigned(FAfterAccept) then
  FAfterAccept(Self, AClient);
end;

procedure TQNamedPipeServer.DoClientDisconnect(AClient: TQNamedPipeClient);
begin
if Assigned(FAfterClientDisconnect) then
  FAfterClientDisconnect(Self, AClient);
end;

procedure TQNamedPipeServer.DoFreeClient(ASender: TQSimplePool; AData: Pointer);
begin
FreeObject(PPointer(AData)^);
end;

procedure TQNamedPipeServer.DoNewClient(ASender: TQSimplePool;
  var AData: Pointer);
begin
AData := TQNamedPipeClient.Create(FName);
end;

procedure TQNamedPipeServer.DoResetClient(ASender: TQSimplePool;
  AData: Pointer);
var
  AClient: TQNamedPipeClient;
begin
// AClient:=AData;
// Do Nothing Needed
end;

function TQNamedPipeServer.GetClientCount: Integer;
begin
Result := FClients.Count;
end;

function TQNamedPipeServer.GetClients(AIndex: Integer): TQNamedPipeClient;
begin
Result := FClients[AIndex];
end;

procedure TQNamedPipeServer.Open;
var
  AListenThread: TQNamedPipeIOThread;
begin
if not Assigned(FIOThread) then
  begin
  AListenThread := TQNamedPipeIOThread.Create(True);
  AListenThread.FNamedPipe := Self;
  AListenThread.FreeOnTerminate := false;
  AListenThread.Suspended := false;
  FIOThread := AListenThread;
  FActive := True;
  end;
end;



initialization

OverlayPool := TQSimplePool.Create(1024, SizeOf(TQNamedPipeOverlapped));

finalization

FreeObject(OverlayPool);

end.
