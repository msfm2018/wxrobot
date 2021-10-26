unit qplugins_loader_socket;

interface

uses classes, sysutils, syncobjs, qstring, qrbtree,
  qplugins{$IFDEF MSWINDOWS},
  windows,
  winsock{$ELSE}posix.base, posix.unstd{$ENDIF};
{$HPPEMIT '#pragma link "qplugins_loader_socket"'}
const
  PHF_REQUEST = $01; // 是一个请求会话
  PHF_REPLY = $02; // 是一个回复会话
  PHF_FIRST = $04; // 是会话的首个数据包
  PHF_LAST = $08; // 是会话的最后一个数据包
  PHF_WANTREPLY = $10; // 会话希望回复结果
  PACKAGE_SIZE = 1465; // 默认打包大小

type

  TQPackageHeader = packed record
    Offset: Int64; // 起始偏移量
    SessionId: DWORD; // 包所隶属的会话编码
    Size: Word; // 包内容大小
    Flags: BYTE; // 标志位
  end;

  PQPackageHeader = ^TQPackageHeader;

  TQRequestHeader = packed record
    TotalSize: Int64; // 所有要传送的数据内容大小
    RefCode: Int64; // 参考代码，由发送端设置，发送端使用，回复时原样回复
    Command: BYTE; // 命令代码
  end;

  PQRequestHeader = ^TQRequestHeader;

  TQReplyHeader = packed record
    TotalSize: Int64;
    RefCode: Int64;
  end;

  PQReplyHeader = ^TQReplyHeader;

  TQSocketSession = class;
  TQSessionReplyNotify = procedure(ASession: TQSocketSession;
    AResult: TQParams);
  TQClientSocket = class;

  // 会话对象，一个会话唯一对应一次请求
  TQSocketSession = class
  protected
    FId: DWORD; // 会话的编码
    FRefCode: Int64;
    FTotalSize: Int64;
    FCommand: BYTE;
    FFlags: Integer;
    FStream: TStream;
    FWait: TEvent; // 等待结果事件句柄
    FOnReply: TQSessionReplyNotify; // 结果就绪时的回调函数
    FSocket: TQClientSocket; // 关联的连接对象
    procedure DispatchSession(AJob: PQJob);
    procedure InternalPost(AParams: IQParams; ACmdId: BYTE; ARefCode: Int64;
      AWantReply: Boolean);
    procedure Cache(p: PByte; l: Integer); virtual; abstract;
  public
    constructor Create(AId: DWORD); overload; virtual;
    destructor Destroy; override;
    function Send(ACmdId: BYTE; AParams: IQParams; ARefCode: Int64): IQParams;
    procedure Post(ACmdId: BYTE; AParams: IQParams; ARefCode: Int64;
      AOnReply: TQSessionReplyNotify);
    property OnReply: TQSessionReplyNotify read FOnReply write FOnReply;
    property Socket: TQClientSocket read FSocket;
  end;

  TQMemorySession = class(TQSocketSession)
  protected
    procedure Cache(p: PByte; l: Integer); override;
  public
    constructor Create(AId: DWORD); override;
    destructor Destroy; override;
  end;

  TQStreamSession = class(TQSocketSession)
  protected
    FStream: IQStream;
  public
    constructor Create(AId: DWORD; AStream: IQStream); overload;
    destructor Destroy; override;
  end;

  TQSocketHandler = procedure(AParams, AResult: TQParams) of object;

  TQHostSocket = class
  protected
    FSocket: TSocket;
    FBindAddr: TSockAddrIn;
    FCount: Integer;
    FChildrenChanged: Boolean;
    FChildren: array [0 .. 63] of TQClientSocket; // 最多同时启动63个服务进程
    FLocker: TCriticalSection;
    FRecvBuf: TQBytesCatHelper;
    procedure DoListen(AJob: PQJob);
    procedure DoRecv(AJob: PQJob);
    procedure DispatchData(ASocket: TSocket);
  public
    constructor Create(ABindAddr: TInAddr; AListenPort: Word); overload;
    destructor Destroy; override;
  end;

  TQClientSocket = class
  protected
    FSocket: TSocket;
    FLocker: TCriticalSection;
    FRecvBuf: TQBytesCatHelper;
    FSessions: TQHashTable;
    procedure DispatchData(ABytes: PByte; ALen: Integer);
  public
    constructor Create(AHandle: TSocket); overload;
    destructor Destroy; override;
    procedure WriteBuffer(p: PByte; l: Integer);
  end;

var
  CommandVectors: array [0 .. 255] of TQSocketHandler;

implementation

var
  GlobalNextSessionId: Cardinal;
  { TQHostSocket }

constructor TQHostSocket.Create(ABindAddr: TInAddr; AListenPort: Word);
begin
  inherited Create;
  FillChar(FBindAddr, SizeOf(FBindAddr), 0);
  FBindAddr.sin_family := AF_INET;
  FBindAddr.sin_port := htons(AListenPort);
  FBindAddr.sin_addr := ABindAddr;
  FLocker := TCriticalSection.Create;
  FRecvBuf := TQBytesCatHelper.Create;
  Workers.LongtimeJob(DoListen, nil);
end;

destructor TQHostSocket.Destroy;
begin
  Workers.Clear(Self);
  FreeObject(FLocker);
  FreeObject(FRecvBuf);
  inherited;
end;

procedure TQHostSocket.DispatchData(ASocket: TSocket);
begin

end;

procedure TQHostSocket.DoListen(AJob: PQJob);
var
  AChild: TSocket;
  procedure Cleanup;
  begin
    if FSocket <> SOCKET_ERROR then
      closesocket(FSocket);
  end;
  procedure Startup;
  var
{$IFDEF MSWINDOWS}
    AData: WSAData;
{$ENDIF}
  begin
{$IFDEF MSWINDOWS}
    WSAStartup(MakeWord(1, 1), AData);
{$ENDIF}
    FSocket := Socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
    if FSocket = SOCKET_ERROR then
      RaiseLastOsError(GetLastError);
    if bind(FSocket, FBindAddr, SizeOf(FBindAddr)) = SOCKET_ERROR then
      RaiseLastOsError(GetLastError);
    if listen(FSocket, 16) = SOCKET_ERROR then
      RaiseLastOsError(GetLastError);
  end;

begin
  try
    Startup;
    while not AJob.IsTerminated do
    begin
      AChild := accept(FSocket, nil, nil);
      FLocker.Enter;
      try
        if FCount < 64 then
        begin
          FChildren[FCount] := TQClientSocket.Create(AChild);
          Inc(FCount);
          FChildrenChanged := True;
          if FCount = 1 then
            Workers.Post(DoRecv, nil);
        end
        else // 超过64个了，不接受任何新的连接
        begin
          closesocket(AChild);
        end;
      finally
        FLocker.Leave;
      end;
    end;
  finally
    Cleanup;
  end;
end;

procedure TQHostSocket.DoRecv(AJob: PQJob);
var
  tv: TIMEVAL;
  fdr: TFDSet;
  ALastCount: Integer;
  AChildren: array of TSocket;
  procedure InitFdSets;
  var
    I: Integer;
  begin
    fd_zero(fdr);
    FLocker.Enter;
    try
      SetLength(AChildren, FCount);
      for I := 0 to FCount - 1 do
      begin
        AChildren[I] := FChildren[I].FSocket;
        fd_set(AChildren[I], fdr);
      end;
      ALastCount := FCount;
      FChildrenChanged := False;
    finally
      FLocker.Leave;
    end;
  end;

  procedure DoDispatch;
  var
    I, AToRead, AReaded: Integer;
    ABuf: array [0 .. 65535] of BYTE;
  begin
    // 读取数据
    for I := 0 to ALastCount - 1 do
    begin
      if fd_isset(AChildren[I], fdr) then // 如果指定的连接有需要读取的数据
      begin
        FRecvBuf.Reset;
        while ioctlsocket(AChildren[I], FIONREAD, AToRead) <> SOCKET_ERROR do
        begin
          if AToRead >= 0 then
          begin
            while AToRead > 0 do
            begin
              if AToRead > 65536 then
                AReaded := recv(AChildren[I], ABuf[0], 65536, 0)
              else
                AReaded := recv(AChildren[I], ABuf[0], AToRead, 0);
              FRecvBuf.Cat(@ABuf[0], AReaded);
              Dec(AToRead, AReaded);
            end;
          end
          else
            break;
        end;
        FChildren[I].DispatchData(FRecvBuf.Start, FRecvBuf.Position);
      end
    end;
  end;

begin
  tv.tv_sec := 0;
  tv.tv_usec := 1000000;
  ALastCount := 0;
  while not AJob.IsTerminated do
  begin
    if FChildrenChanged then
      InitFdSets;
    if select(ALastCount + 1, @fdr, nil, nil, @tv) <> SOCKET_ERROR then
    begin
      DoDispatch;
    end;
  end;
end;

{ TQSocketSession }

constructor TQSocketSession.Create(AId: DWORD);
begin
  inherited Create;
  FId := AId;
end;

destructor TQSocketSession.Destroy;
begin
  if Assigned(FWait) then
    FreeObject(FWait);
  inherited;
end;

procedure TQSocketSession.DispatchSession(AJob: PQJob);
var
  AParams, AResult: TQParams;
  procedure DoReply;
  begin
    AResult := TQParams.Create;
    try
      AResult.LoadFromStream(FStream);
      OnReply(Self, AResult);
    finally
      FreeObject(AResult);
    end;
  end;

begin
  if (FFlags and PHF_REPLY) <> 0 then
  begin
    // 派发一个会话包
    if Assigned(OnReply) then
      DoReply
    else if Assigned(FWait) then
      FWait.SetEvent;
  end
  else
  begin
    if Assigned(CommandVectors[FCommand]) then
    begin
      AParams := TQParams.Create;
      AResult := TQParams.Create;
      try
        AParams.LoadFromStream(FStream);
        CommandVectors[FCommand](AParams, AResult);
      finally
        FreeObject(AParams);
        FreeObject(AResult);
      end;
      // 派发命令到相应的执行处理函数
    end;
  end;
end;

procedure TQSocketSession.InternalPost(AParams: IQParams; ACmdId: BYTE;
  ARefCode: Int64; AWantReply: Boolean);
var
  AStream: TMemoryStream;
  ABuf: array [0 .. PACKAGE_SIZE - 1] of BYTE;
  AHdr: TQPackageHeader;
  AReqHdr: PQRequestHeader;
  AOffset: Integer;
begin
  FRefCode := ARefCode;
  FCommand := ACmdId;
  AStream := TMemoryStream.Create;
  try
    AParams.SaveToStream(QStream(AStream, False));
    AStream.Seek(0, soFromBeginning);
    repeat
      AHdr.Offset := AStream.Position;
      AHdr.SessionId := FId;
      AOffset := SizeOf(AHdr);
      AHdr.Flags := PHF_REQUEST;
      if AWantReply then
        AHdr.Flags := AHdr.Flags or PHF_WANTREPLY;
      if AHdr.Offset = 0 then
      begin
        AHdr.Flags := PHF_FIRST;
        AReqHdr := @ABuf[SizeOf(AHdr)];
        AReqHdr.TotalSize := AStream.Size;
        AReqHdr.RefCode := ARefCode;
        AReqHdr.Command := ACmdId;
        Inc(AOffset, SizeOf(TQRequestHeader));
      end;
      AHdr.Size := AStream.Read(ABuf[AOffset], PACKAGE_SIZE - AOffset)
        + AOffset;
      FSocket.WriteBuffer(@ABuf[0], AHdr.Size);
    until AHdr.Size < PACKAGE_SIZE;
  finally
    FreeObject(AStream);
  end;
end;

procedure TQSocketSession.Post(ACmdId: BYTE; AParams: IQParams; ARefCode: Int64;
  AOnReply: TQSessionReplyNotify);
begin
  FOnReply := AOnReply;
  InternalPost(AParams, ACmdId, ARefCode, Assigned(FOnReply));
end;

function TQSocketSession.Send(ACmdId: BYTE; AParams: IQParams; ARefCode: Int64)
  : IQParams;
var
  AResult: TQParams;
begin
  if not Assigned(FWait) then
    FWait := TEvent.Create(nil, False, False, '');
  InternalPost(AParams, ACmdId, ARefCode, True);
  FWait.WaitFor(INFINITE);
  AResult := TQParams.Create;
  Result := AResult;
  AResult.LoadFromStream(FStream);
  Result := AResult;
end;

{ TQMemorySession }

procedure TQMemorySession.Cache(p: PByte; l: Integer);
begin
  FStream.WriteBuffer(p^, l);
  if FStream.Size = FTotalSize then
    Workers.Post(DispatchSession, nil);
end;

constructor TQMemorySession.Create(AId: DWORD);
begin
  inherited;
  FStream := TMemoryStream.Create;
end;

destructor TQMemorySession.Destroy;
begin
  FreeObject(FStream);
  inherited;
end;

{ TQStreamSession }

constructor TQStreamSession.Create(AId: DWORD; AStream: IQStream);
begin
  inherited Create(AId);
  FStream := AStream;
end;

destructor TQStreamSession.Destroy;
begin

  inherited;
end;

{ TQClientSocket }

constructor TQClientSocket.Create(AHandle: TSocket);
begin
  inherited Create;
  FSocket := AHandle;
  FRecvBuf := TQBytesCatHelper.Create;
end;

destructor TQClientSocket.Destroy;
begin
  if FSocket <> INVALID_SOCKET then
  begin
    closesocket(FSocket);
    FSocket := INVALID_SOCKET;
  end;
  FreeAndNil(FRecvBuf);
  inherited;
end;

procedure TQClientSocket.DispatchData(ABytes: PByte; ALen: Integer);
  function TryDecode: Boolean;
  var
    AHdr: PQPackageHeader;
    AReqHdr: PQRequestHeader;
    AReplyHdr: PQReplyHeader;
    pe: PByte;
    ASession: TQSocketSession;
  begin
    AHdr := PQPackageHeader(ABytes);
    Result := AHdr.Size >= ALen;
    if not Result then
      Exit;
    pe := ABytes;
    Inc(pe, AHdr.Size);
    if (AHdr.Flags and PHF_FIRST) <> 0 then // 接收到一个新的会话
    begin
      ASession := TQMemorySession.Create(AHdr.SessionId);
      ASession.FSocket := Self;
      FSessions.Add(ASession, AHdr.SessionId);
      Inc(ABytes, SizeOf(TQPackageHeader));
      if (AHdr.Flags and PHF_REPLY) = 0 then // 读取操作命令
      begin
        AReqHdr := PQRequestHeader(ABytes);
        ASession.FRefCode := AReqHdr.RefCode;
        ASession.FCommand := AReqHdr.Command;
        ASession.FTotalSize := AReqHdr.TotalSize;
        Inc(ABytes, SizeOf(TQRequestHeader));
      end
      else // 读取返回结果头
      begin
        AReplyHdr := PQReplyHeader(ABytes);
        ASession.FRefCode := AReplyHdr.RefCode;
        ASession.FTotalSize := AReplyHdr.TotalSize;
      end
    end
    else // 回复，查找已经存在的小节
    begin
      ASession := FSessions.FindFirstData(AHdr.SessionId);
      Inc(ABytes, SizeOf(TQPackageHeader));
    end;
    if Assigned(ASession) then
      ASession.Cache(ABytes, IntPtr(pe) - IntPtr(ABytes));
  end;

begin
  FLocker.Enter;
  try
    FRecvBuf.Cat(ABytes, ALen);
    ABytes := FRecvBuf.Start;
    ALen := FRecvBuf.Position;
    while TryDecode do;
  finally
    FLocker.Leave;
  end;
end;

procedure TQClientSocket.WriteBuffer(p: PByte; l: Integer);
var
  d: Integer;
begin
  repeat
    d := Send(FSocket, p^, l, 0);
    if d <> SOCKET_ERROR then
    begin
      Inc(p, d);
      Dec(l, d);
    end;
  until l = 0;
end;

end.
