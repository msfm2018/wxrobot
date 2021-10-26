unit qsocket_sharemem;

interface

uses classes, sysutils, windows, psapi, syncobjs, qstring, qsocket_base, qworker
{$IFDEF UNICODE}, Generics.Collections{$ENDIF};
{$I qdac.inc}

{
  2016.5.18
  =========
  * 修改了实现方式，需要调试确认下双方的事件名称是否正确
  * 需要加入Disconnect实现
}
type

  TQShareMemConnection = class(TQBaseConnection)
  protected
    FRemoteProcessId: Cardinal;
    FReadTimeout, FWriteTimeout: Cardinal;
    function GetRemoteProcessFileName: String;
    procedure CreateStreams; virtual; abstract;
    procedure CloseStreams;
    function InternalConnect: Boolean; override;
    procedure InternalDisconnect; override;
    procedure AddrChanged; override;
    procedure HandleNeeded; override;
    procedure DispatchControl(AData: PByte; ASize: Integer);
  public
    constructor Create; override;
    destructor Destroy; override;
    procedure AttachTo(AProcessId: Cardinal; AInstId: Integer);
    function WaitForData(ATimeout: Cardinal): TWaitResult; overload; override;
    property RemoteProcessFileName: String read GetRemoteProcessFileName;
    property RemoteProcessId: Cardinal read FRemoteProcessId;
    property ReadTimeout: Cardinal read FReadTimeout write FReadTimeout;
    property WriteTimeout: Cardinal read FWriteTimeout write FWriteTimeout;
  end;

  TQShareMemClient = class(TQShareMemConnection)
  protected
    procedure CreateStreams; override;
    procedure AddrChanged; override;
  end;

  TQShareMemServerClient = class(TQShareMemConnection)
  protected
    procedure CreateStreams; override;
  public
    function WaitForData(ATimeout: Cardinal): TWaitResult; override;
  end;

implementation

resourcestring
  SReadOnlyStream = '不能写入一个只读的数据流';
  SWriteOnlyStream = '不能从一个只读的数据流中读数据';
  SCantCreateStreamHandle = '无法创建数据流句柄';
  SNotConnected = '共享内存连接未建立';

type
  /// Stream Format
  TQNamedEvent = class(TEvent)
  private
    FName: QStringW;
  public
    constructor Create(EventAttributes: PSecurityAttributes;
      ManualReset, InitialState: Boolean; const Name: string;
      UseCOMWait: Boolean = False); overload;
    function WaitFor(Timeout: LongWord): TWaitResult; override;
    procedure SetEvent; reintroduce;
    procedure ResetEvent; reintroduce;
    property Name: QStringW read FName;
  end;

  TQShareMemStream = class(TStream)
  protected
    FHandle: THandle;
    FOwner: TQBaseConnection;
    FReadEvent: TQNamedEvent;
    FWriteEvent: TQNamedEvent;
    FLastSeqNo: Word;
    FMapName: QStringW;
    procedure HandleNeeded;
    procedure CreateHandle; virtual; abstract;
    procedure FreeHandle; virtual;
    procedure RecreateHandle;
    procedure RecreateIfAllocated;
    procedure HostAddrChanged;
  public
    constructor Create(AOwner: TQBaseConnection); overload; virtual;
    destructor Destroy; override;
    function Read(var Buffer; Count: Longint): Longint; override;
    function Seek(const Offset: Int64; Origin: TSeekOrigin): Int64; override;
    function Write(const Buffer; Count: Longint): Longint; override;
  end;

  TQShareStreamBlock = packed record
    SeqNo: Word;
    Size: Word;
    Data: array [0 .. 0] of Byte;
  end;

  PQShareStreamBlock = ^TQShareStreamBlock;

  TQHandshake = packed record
    Command: Word;
    AddrLen: Word;
    ProcessId: Cardinal;
  end;

  PQHandshake = ^TQHandshake;

  TQDisconnectCmd = packed record
    Command: Word;
  end;

  TQShareMemReadStream = class(TQShareMemStream)
  protected
    FBufferStream: TMemoryStream;
    function ReadBlock: Cardinal;
    function GetSize: Int64; override;
  public
    constructor Create(AOwner: TQBaseConnection); override;
    destructor Destroy; override;
    function Read(var Buffer; Count: Longint): Longint; override;
    function WaitForData(ATimeout: Cardinal): TWaitResult;
  end;

  TQShareMemClientReadStream = class(TQShareMemReadStream)
  protected
    procedure CreateHandle; override;
  public
    constructor Create(AOwner: TQBaseConnection); override;
  end;

  TQShareMemServerReadStream = class(TQShareMemReadStream)
  protected
    procedure CreateHandle; override;
  public
    constructor Create(AOwner: TQBaseConnection); override;
  end;

  TQShareMemWriteStream = class(TQShareMemStream)
  protected
    function InternalWriteBlock(AData: Pointer; ASize: Longint;
      AIsCtrl: Boolean): Longint;
  public
    constructor Create(AOwner: TQBaseConnection); override;
    function Write(const Buffer; Count: Longint): Longint; override;
    function WriteControl(const Buffer; Count: Longint): Longint;
  end;

  TQShareMemClientWriteStream = class(TQShareMemWriteStream)
  protected
    procedure CreateHandle; override;
  public
    constructor Create(AOwner: TQBaseConnection); override;
  end;

  TQShareMemServerWriteStream = class(TQShareMemWriteStream)
  protected
    procedure CreateHandle; override;
  public
    constructor Create(AOwner: TQBaseConnection); override;
  end;

const
  CMD_CONNECT = 1; // C->S
  CMD_CONNECTED = 3; // S->C
  CMD_DISCONNECT = 2; // C->S OR S->C

  { TQShareMemConnection }

procedure TQShareMemConnection.AddrChanged;
begin
  inherited;
  (FReadStream as TQShareMemStream).RecreateIfAllocated;
  (FWriteStream as TQShareMemStream).RecreateIfAllocated;
end;

procedure TQShareMemConnection.AttachTo(AProcessId: Cardinal; AInstId: Integer);
begin
  FRemoteAddr := IntToStr(AProcessId) + '.' + IntToStr(AInstId);
  CloseStreams;
  HandleNeeded;
end;

procedure TQShareMemConnection.CloseStreams;
begin
  if Assigned(FReadStream) then
    FreeAndNil(FReadStream);
  if Assigned(FWriteStream) then
    FreeAndNil(FWriteStream);
end;

constructor TQShareMemConnection.Create;
begin
  inherited;
  FLocalAddr := IntToStr(GetCurrentProcessID) + ':' + IntToStr(IntPtr(Self));
  FReadTimeout := {$IFDEF IO_DEBUG}INFINITE{$ELSE}1000{$ENDIF}; // 读取数据超时
  FWriteTimeout := {$IFDEF IO_DEBUG}INFINITE{$ELSE}1000{$ENDIF}; // 写入数据超时
  CreateStreams;
end;

destructor TQShareMemConnection.Destroy;
begin
  inherited;
end;

procedure TQShareMemConnection.DispatchControl(AData: PByte; ASize: Integer);
  procedure DispatchConnect;
  var
    AHandshake, AReply: PQHandshake;
  begin
    AHandshake := PQHandshake(AData);
    FRemoteProcessId := AHandshake.ProcessId;
    FRemoteAddr := qstring.Utf8Decode
      (PQCharA(IntPtr(AData) + SizeOf(TQHandshake)), AHandshake.AddrLen);
    GetMem(AReply, SizeOf(TQHandshake));
    try
      AReply.Command := CMD_CONNECTED;
      AReply.ProcessId := GetCurrentProcessID;
      AReply.AddrLen := 0;
      (WriteStream as TQShareMemWriteStream).WriteControl(AReply^,
        SizeOf(TQHandshake));
      DoConnected;
    finally
      FreeMem(AReply);
    end;
  end;

  procedure DispatchConnected;
  var
    AHandshake: PQHandshake;
  begin
    AHandshake := PQHandshake(AData);
    FRemoteProcessId := AHandshake.ProcessId;
    if AHandshake.AddrLen > 0 then
    begin
      FRemoteAddr := qstring.Utf8Decode
        (PQCharA(IntPtr(AData) + SizeOf(TQHandshake)),
        ASize - SizeOf(TQHandshake));
    end;
    DoConnected;
  end;
  procedure DispatchDisconnect;
  begin
    DoDisconnected;
    FRemoteAddr := '';
  end;

begin
  case PWord(AData)^ of
    CMD_CONNECT:
      DispatchConnect;
    CMD_CONNECTED:
      DispatchConnected;
    CMD_DISCONNECT:
      DispatchDisconnect;
  end;
end;

type
  TGetProcessImageFileName = function(hProcess: THandle;
    lpImageFileName: PWideChar; nSize: Cardinal): DWORD; stdcall;

var
  _GetProcessImageFileName: TGetProcessImageFileName = nil;

const
  psapi = 'psapi.dll';

function GetProcessImageFileName(hProcess: THandle; lpImageFileName: PWideChar;
  nSize: Cardinal): DWORD;
begin
  if not Assigned(_GetProcessImageFileName) then
  begin
    _GetProcessImageFileName := GetProcAddress(GetModuleHandle(kernel32),
      'GetProcessImageFileNameW');
    if not Assigned(_GetProcessImageFileName) then
      _GetProcessImageFileName := GetProcAddress(GetModuleHandle(psapi),
        'GetProcessImageFileNameW');
  end;
  if Assigned(_GetProcessImageFileName) then
    Result := _GetProcessImageFileName(hProcess, lpImageFileName, nSize)
  else
    Result := 0;
end;

function TQShareMemConnection.GetRemoteProcessFileName: String;
var
  AHandle: THandle;
begin
  Result := '';
  if FRemoteProcessId <> 0 then
  begin
    AHandle := OpenProcess(PROCESS_QUERY_INFORMATION, False, FRemoteProcessId);
    if AHandle <> INVALID_HANDLE_VALUE then
    begin
      SetLength(Result, MAX_PATH);
      SetLength(Result, GetProcessImageFileName(AHandle, PChar(Result),
        MAX_PATH));
      CloseHandle(AHandle);
    end;
  end;
end;

procedure TQShareMemConnection.HandleNeeded;
begin
  // Do nothing
end;

function TQShareMemConnection.InternalConnect: Boolean;
var
  AHandshake: PQHandshake;
  AReplyShake: TQHandshake;
  S: QStringA;
  ALen: Word;
begin
  S := qstring.Utf8Encode(LocalAddr);
  ALen := SizeOf(TQHandshake) + S.Length;
  GetMem(AHandshake, ALen);
  try
    AHandshake.AddrLen := S.Length;
    AHandshake.Command := CMD_CONNECT;
    AHandshake.ProcessId := GetCurrentProcessID;
    Move(PQCharA(S)^, PByte(IntPtr(AHandshake) + SizeOf(TQHandshake))^,
      S.Length);
    Result := (WriteStream as TQShareMemWriteStream).WriteControl(AHandshake^,
      ALen) = ALen;
    if Result then
    begin
      with ReadStream as TQShareMemReadStream do
      begin
        HandleNeeded;
        DebugOut('发送握手数据包成功，等待服务器端设置信号 %s ', [FReadEvent.Name]);
        // 读取并等待连接
        Result := WaitForData(FReadTimeout) = wrSignaled;
        if Result then
        begin
          DebugOut('接收到服务器端回应就绪信号，读取回应');
          ReadBlock;
        end
        else
          DebugOut('服务器端回应信号未就绪:%d', [Integer(Result)]);
      end;
    end;
  finally
    FreeMem(AHandshake);
  end;
end;

procedure TQShareMemConnection.InternalDisconnect;
var
  ACmd: Word;
begin
  ACmd := CMD_DISCONNECT;
  (WriteStream as TQShareMemWriteStream).WriteControl(ACmd, SizeOf(Word));
end;

function TQShareMemConnection.WaitForData(ATimeout: Cardinal): TWaitResult;
begin
  if not Connected then
    raise Exception.Create(SNotConnected);
  with (ReadStream as TQShareMemReadStream) do
  begin
    HandleNeeded;
    Result := FReadEvent.WaitFor(ATimeout);
  end;
end;

{ TQShareMemStream }

constructor TQShareMemStream.Create(AOwner: TQBaseConnection);
begin
  inherited Create;
  FOwner := AOwner;
end;

destructor TQShareMemStream.Destroy;
begin
  if FHandle <> 0 then
    FreeHandle;
  inherited;
end;

procedure TQShareMemStream.FreeHandle;
begin
  if Assigned(FReadEvent) then
    FreeAndNil(FReadEvent);
  if Assigned(FWriteEvent) then
    FreeAndNil(FWriteEvent);
  if FHandle <> 0 then
    CloseHandle(FHandle);
  FHandle := 0;
end;

procedure TQShareMemStream.HandleNeeded;
begin
  if FHandle = 0 then
  begin
    CreateHandle;
    if FHandle = 0 then
      raise EStreamError.Create(SCantCreateStreamHandle);
  end;
end;

procedure TQShareMemStream.HostAddrChanged;
begin
  RecreateHandle;
end;

function TQShareMemStream.Read(var Buffer; Count: Integer): Longint;
begin
  raise EStreamError.Create(SWriteOnlyStream);
end;

procedure TQShareMemStream.RecreateHandle;
begin
  if FHandle <> 0 then
    FreeHandle;
  CreateHandle;
end;

procedure TQShareMemStream.RecreateIfAllocated;
begin
  if FHandle <> 0 then
    RecreateHandle;
end;

function TQShareMemStream.Seek(const Offset: Int64; Origin: TSeekOrigin): Int64;
begin
  Result := 0;
end;

function TQShareMemStream.Write(const Buffer; Count: Integer): Longint;
begin
  raise EStreamError.Create(SReadOnlyStream);
end;

{ TQShareMemReadStream }

constructor TQShareMemReadStream.Create(AOwner: TQBaseConnection);
begin
  inherited;
  FBufferStream := TMemoryStream.Create;
end;

destructor TQShareMemReadStream.Destroy;
begin
  FreeAndNil(FBufferStream);
  inherited;
end;

function TQShareMemReadStream.GetSize: Int64;
var
  AIsCtrl: Boolean;
begin
  ReadBlock;
  Result := FBufferStream.Size - FBufferStream.Position;
end;

function TQShareMemReadStream.Read(var Buffer; Count: Integer): Longint;
var
  AReaded: Integer;
  pBuf: PByte;
begin
  pBuf := @Buffer;
  Result := 0;
  while Count > 0 do
  begin
    AReaded := FBufferStream.Read(pBuf^, Count);
    if AReaded > 0 then
    begin
      Inc(pBuf, AReaded);
      Inc(Result, AReaded);
      Dec(Count, AReaded);
    end;
    if Count > 0 then
    begin
      if ReadBlock = 0 then
        Break;
    end;
  end;
end;

function TQShareMemReadStream.ReadBlock: Cardinal;
var
  p: PQShareStreamBlock;
  ALastPos: Int64;
  ASize: Word;
begin
  if FBufferStream.Position = FBufferStream.Size then
    FBufferStream.Position := 0;
  Result := 0;
  HandleNeeded;
  if FReadEvent.WaitFor((FOwner as TQShareMemConnection).ReadTimeout) = wrSignaled
  then
  begin
    p := MapViewOfFile(FHandle, FILE_MAP_READ, 0, 0, 4096);
    ALastPos := FBufferStream.Position;
    if Assigned(p) and (p.SeqNo <> FLastSeqNo) then // 因为顺序读写，
    begin
      FLastSeqNo := p.SeqNo;
      ASize := (p.Size and $7FFF);
      if (p.Size and $8000) <> 0 then
      begin
        (FOwner as TQShareMemConnection).DispatchControl(@p.Data, ASize);
      end
      else
      begin
        FBufferStream.WriteBuffer(p.Data, ASize);
        Result := ASize;
      end;
      UnmapViewOfFile(p);
      FReadEvent.ResetEvent;
      FWriteEvent.SetEvent;
    end;
    FBufferStream.Size := FBufferStream.Position;
    FBufferStream.Position := ALastPos;
  end;
end;

function TQShareMemReadStream.WaitForData(ATimeout: Cardinal): TWaitResult;
begin
  HandleNeeded;
  Result := FReadEvent.WaitFor(ATimeout);
end;

{ TQShareMemWriteStream }

constructor TQShareMemWriteStream.Create(AOwner: TQBaseConnection);
begin
  inherited;
end;

function TQShareMemWriteStream.InternalWriteBlock(AData: Pointer;
  ASize: Integer; AIsCtrl: Boolean): Longint;
var
  p: PQShareStreamBlock;
  AToWrite: NativeUInt;
  ps: PByte;
begin
  Result := 0;
  ps := AData;
  while (ASize > 0) and
    (FWriteEvent.WaitFor((FOwner as TQShareMemConnection).WriteTimeout)
    = wrSignaled) do
  begin
    FWriteEvent.ResetEvent;
    p := MapViewOfFile(FHandle, FILE_MAP_WRITE, 0, 0, 4096);
    if Assigned(p) then // 因为顺序读写，
    begin
      Inc(FLastSeqNo);
      p.SeqNo := FLastSeqNo;
      if ASize > 4092 then
        // 4096
        AToWrite := 4092
      else
        AToWrite := ASize;
      if AIsCtrl then
        p.Size := AToWrite or $8000 // Ctrl command flags
      else
        p.Size := AToWrite;
      Dec(ASize, AToWrite);
      Move(ps^, p.Data, AToWrite);
      Inc(Result, AToWrite);
      UnmapViewOfFile(p);
      FReadEvent.SetEvent;
    end;
  end;
end;

function TQShareMemWriteStream.Write(const Buffer; Count: Integer): Longint;
begin
  HandleNeeded;
  Result := InternalWriteBlock(@Buffer, Count, False);
end;

function TQShareMemWriteStream.WriteControl(const Buffer;
  Count: Integer): Longint;
begin
  HandleNeeded;
  Result := InternalWriteBlock(@Buffer, Count, True);
end;

{ TQShareMemServerWriteStream }

constructor TQShareMemServerWriteStream.Create(AOwner: TQBaseConnection);
begin
  inherited;
  if Length(AOwner.LocalAddr) > 0 then
    CreateHandle;
end;

procedure TQShareMemServerWriteStream.CreateHandle;
begin
  FMapName := FOwner.LocalAddr + '.S2C';
  FHandle := CreateFileMappingW(INVALID_HANDLE_VALUE, nil, PAGE_READWRITE, 0,
    4096, PQCharW(FMapName));
  if FHandle = 0 then
    RaiseLastOSError(GetLastError);
  FReadEvent := TQNamedEvent.Create(nil, True, False, 'Global\' + FMapName +
    '.ReadyToRead');
  FWriteEvent := TQNamedEvent.Create(nil, True, True, 'Global\' + FMapName +
    '.ReadyToWrite');
  DebugOut('Stream.Server.Write.Name=%s,ReadEvent=%s,WriteEvent=%s',
    [FMapName, FReadEvent.Name, FWriteEvent.Name]);
end;

{ TQShareMemClientWriteStream }

constructor TQShareMemClientWriteStream.Create(AOwner: TQBaseConnection);
begin
  inherited;
  if Length(AOwner.RemoteAddr) > 0 then
    CreateHandle;
end;

procedure TQShareMemClientWriteStream.CreateHandle;
begin
  FMapName := FOwner.RemoteAddr + '.C2S';
  FHandle := OpenFileMappingW(FILE_MAP_WRITE, False, PQCharW(FMapName));
  if FHandle = 0 then
    RaiseLastOSError;
  FReadEvent := TQNamedEvent.Create(nil, True, False, 'Global\' + FMapName +
    '.ReadyToRead');
  FWriteEvent := TQNamedEvent.Create(nil, True, True, 'Global\' + FMapName +
    '.ReadyToWrite');
  DebugOut('Stream.Client.Write.Name=%s,ReadEvent=%s,WriteEvent=%s',
    [FMapName, FReadEvent.Name, FWriteEvent.Name]);

end;

{ TQShareMemClientReadStream }

constructor TQShareMemClientReadStream.Create(AOwner: TQBaseConnection);
begin
  inherited;
  if Length(AOwner.RemoteAddr) > 0 then
    CreateHandle;
end;

procedure TQShareMemClientReadStream.CreateHandle;
begin
  FMapName := FOwner.RemoteAddr + '.S2C';
  FHandle := OpenFileMappingW(FILE_MAP_READ, False, PQCharW(FMapName));
  if FHandle = 0 then
    RaiseLastOSError;
  FReadEvent := TQNamedEvent.Create(nil, True, False, 'Global\' + FMapName +
    '.ReadyToRead');
  FWriteEvent := TQNamedEvent.Create(nil, True, True, 'Global\' + FMapName +
    '.ReadyToWrite');
  DebugOut('Stream.Client.Read.Name=%s,ReadEvent=%s,WriteEvent=%s',
    [FMapName, FReadEvent.Name, FWriteEvent.Name]);
end;

{ TQShareMemServerReadStream }

constructor TQShareMemServerReadStream.Create(AOwner: TQBaseConnection);
begin
  inherited;
  if Length(AOwner.LocalAddr) > 0 then
    CreateHandle;
end;

procedure TQShareMemServerReadStream.CreateHandle;
begin
  FMapName := FOwner.LocalAddr + '.C2S';
  FHandle := CreateFileMappingW(INVALID_HANDLE_VALUE, nil, PAGE_READWRITE, 0,
    4096, PQCharW(FMapName));
  if FHandle = 0 then
    RaiseLastOSError(GetLastError);
  FReadEvent := TQNamedEvent.Create(nil, True, False, 'Global\' + FMapName +
    '.ReadyToRead');
  FWriteEvent := TQNamedEvent.Create(nil, True, True, 'Global\' + FMapName +
    '.ReadyToWrite');
  DebugOut('Stream.Server.Read.Name=%s,ReadEvent=%s,WriteEvent=%s',
    [FMapName, FReadEvent.Name, FWriteEvent.Name]);
end;

{ TQShareMemClient }

procedure TQShareMemClient.AddrChanged;
begin
  inherited;

end;

procedure TQShareMemClient.CreateStreams;
begin
  FReadStream := TQShareMemClientReadStream.Create(Self);
  FWriteStream := TQShareMemClientWriteStream.Create(Self);
end;

{ TQShareMemServerClient }

procedure TQShareMemServerClient.CreateStreams;
begin
  FReadStream := TQShareMemServerReadStream.Create(Self);
  FWriteStream := TQShareMemServerWriteStream.Create(Self);
end;

function TQShareMemServerClient.WaitForData(ATimeout: Cardinal): TWaitResult;
  procedure DoConnect;
  var
    ARequest: TQHandshake;
    AReply: PQHandshake;
    S: QStringA;
  begin
    (ReadStream as TQShareMemReadStream).ReadBlock; // 读取以调用派发控制指令函数
  end;

begin
  Result := (ReadStream as TQShareMemServerReadStream).WaitForData(ATimeout);
  if Result = wrSignaled then
  begin
    if not Connected then
    begin
      DoConnect;
      // 重新等待数据
      Result := WaitForData(ATimeout);
    end;
  end;
end;

{ TQNamedEvent }

constructor TQNamedEvent.Create(EventAttributes: PSecurityAttributes;
  ManualReset, InitialState: Boolean; const Name: string; UseCOMWait: Boolean);
begin
  inherited;
  FName := Name;
end;

procedure TQNamedEvent.ResetEvent;
begin
  DebugOut('%s 已重置为无信号', [Name]);
  inherited ResetEvent;
end;

procedure TQNamedEvent.SetEvent;
begin
  DebugOut('%s 已设置为有信号', [Name]);
  inherited SetEvent;
end;

function TQNamedEvent.WaitFor(Timeout: LongWord): TWaitResult;
begin
  DebugOut('%s 正在等待超时 %d ms', [Name, Timeout]);
  Result := inherited WaitFor(Timeout);
  case Result of
    wrSignaled:
      DebugOut('%s 已触发', [Name]);
    wrTimeout:
      DebugOut('%s 已超时', [Name]);
    wrAbandoned:
      DebugOut('%s 已中断', [Name]);
    wrError:
      DebugOut('%s 已出错', [Name]);
    wrIOCompletion:
      DebugOut('%s IO进行中', [Name]);
  end;
end;

end.
