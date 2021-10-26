unit QMapSymbols;

{ 本单元用于通过加载Delphi/C++ Builder编译生成的Map文件，来获取指定的地址所隶属的
  源码信息，以便跟踪相关信息。本单元只支持Windows平台的32位版本，Windows 64位版本
  堆栈跟踪部分暂未实现，限于作者有限的知识水平，其它版本未实现支持。
}
{
  本源码来自QDAC项目，版权归swish(QQ:109867294)所有。
  (1)、使用许可及限制
  您可以自由复制、分发、修改本源码，但您的修改应该反馈给作者，并允许作者在必要时，
  合并到本项目中以供使用，合并后的源码同样遵循QDAC版权声明限制。
  您的产品的关于中，应包含以下的版本声明:
  本产品使用的JSON解析器来自QDAC项目中的QJSON，版权归作者所有。
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
{
  更新日志：
  ========
  2015.8.13
  =========
  * 修正了StackByThreadHandle时参数为 GetCurrentThread 返回的句柄时逻辑错误的问题（感谢音儿小白）
  2015.2.26
  =========
  * 修正了在2007下的编译警告（感谢麦子仲肥）
  2014.11.25
  ==========
  * 修正了解析C++生成的Map文件时，函数名未正确解析的问题

  2014.10.30
  ==========
  * 修正了由于DisableDeadLockChecker未检查死锁检查对象是否存在就处理造成的退出时可能出错的问题（火鸟报告）

  2014.10.9
  =========
  + 增加对DLL中导入函数地址解析的支持，以便更容易跟踪堆栈内容
}
interface

{
  如果您安装了JCL，启用下面的宏以使用JCLDebug来替代QWinStackTracer，相比微软的
  DbgHelp.dll，对于Delphi程序JCLDebug解析更可靠．
}
{ .$define USE_JCLDEBUG }
{$HPPEMIT '#pragma link "qmapsymbols"'}

uses classes, sysutils, qstring, qrbtree, syncobjs{$IFDEF UNICODE}
    , Generics.Collections{$ENDIF}{$IFDEF MSWINDOWS}
    , windows, tlhelp32, activex, psapi{$ENDIF};

type
  TQSymbols = class;

  TQSymbolBase = class
  protected
    FOffset: NativeInt;
    FSize: Cardinal;
    FOwner: TQSymbols;
    FTag: NativeInt;
  public
    constructor Create; overload; virtual;
    destructor Destroy; override;
    property Offset: NativeInt read FOffset write FOffset;
    property Size: Cardinal read FSize write FSize;
    property Owner: TQSymbols read FOwner;
    property Tag: NativeInt read FTag write FTag;
  end;

  TQNamedSymbol = class(TQSymbolBase)
  protected
    FName: String;
  public
    property Name: String read FName write FName;
  end;

  TQFileSymbol = class(TQNamedSymbol)
  protected
    FFileName: String;
  public
    property FileName: String read FFileName write FFileName;
  end;

  TQLineOffset = class(TQSymbolBase)
  protected
    FLineNo: Cardinal;
    FModule: TQNamedSymbol;
    FFile: TQNamedSymbol;
  public
    property LineNo: Cardinal read FLineNo write FLineNo;
    property Module: TQNamedSymbol read FModule write FModule;
  end;
{$IF RTLVersion>=21}

  TQSymbolList = TList<TQSymbolBase>;
{$ELSE}
  TQSymbolList = TList;
{$IFEND >=2010}
  TQSymbolClass = class of TQSymbolBase;

  TQSymbols = class
  protected
    FItems: TQSymbolList;
    FItemClass: TQSymbolClass;
    FUpdateCount: Integer;
    function GetCount: Integer; inline;
    function GetItems(AIndex: Integer): TQSymbolBase; inline;
    function InternalFind(const Addr: NativeInt; var AIndex: Integer): Boolean;
    procedure Sort;
    function GetCapapcity: Integer; inline;
    procedure SetCapacity(const Value: Integer); inline;
  public
    constructor Create(AItemClass: TQSymbolClass); overload;
    destructor Destroy; override;
    function Add(AOffset: NativeInt): TQSymbolBase; overload;
    function Add(AItem: TQSymbolBase): Integer; overload;
    procedure Delete(AIndex: Integer);
    procedure Clear;
    procedure BeginUpdate;
    procedure EndUpdate;
    function FindNearest(AOffset: NativeInt): TQSymbolBase;
    function IndexOfNearest(AOffset: NativeInt): Integer;
    property Count: Integer read GetCount;
    property Items[AIndex: Integer]: TQSymbolBase read GetItems; default;
    property Capacity: Integer read GetCapapcity write SetCapacity;
  end;

  TQSymbolLocation = record
    Addr: Pointer;
    FunctionName: String;
    UnitName: String;
    LineNo: Cardinal;
    FileName: String;
  end;

  TQSymbolMapFile = class(TQNamedSymbol)
  protected
    FFunctions: TQSymbols;
    FModules: TQSymbols;
    FLines: TQSymbols;
    procedure LoadSymbols; virtual;
    function GetFileName: String; inline;
    procedure SetFileName(const Value: String); inline;
  public
    constructor Create; override;
    destructor Destroy; override;
    function Locate(const Addr: Pointer; var AInfo: TQSymbolLocation): Boolean;
    property FileName: String read GetFileName write SetFileName;
  end;

  TQDebugSymbols = class
  protected
    FItems: TQSymbols;
    FSymbolsLoaded: Boolean;
    procedure ResetLocation(var AInfo: TQSymbolLocation);
  public
    constructor Create; overload;
    destructor Destroy; override;
    procedure Add(AFile: TQSymbolMapFile; AOffset: Cardinal = 0);
    function Locate(const Addr: Pointer; var AInfo: TQSymbolLocation)
      : Boolean; overload;
    function Locate(const Addr: Pointer): TQSymbolLocation; overload;
    procedure LoadSymbols;
    procedure LoadDefault;
  end;

var
  Symbols: TQDebugSymbols;
function LocateSymbol(const Addr: Pointer;
  var ALocation: TQSymbolLocation): Boolean;
function StackOfThread(AThread: TThread): QStringW; overload;
function StackByThreadId(AThreadId: TThreadId): QStringW; overload;
{$IFDEF MSWINDOWS}
function StackByThreadHandle(AThread: THandle): QStringW; overload;
function EnumWaitChains: QStringW;
{ 启用死锁检查，死锁检查一旦启用，会后台定时检测是否发生死锁，一旦发生死锁，会
  在后台记录死锁信息日志到deadlock.log文件中，然后停止检查。
}
procedure EnableDeadlockCheck;
procedure DisableDeadlockCheck;
{$ENDIF}

implementation

{$IFDEF MSWINDOWS}

uses {$IFDEF USE_JCLDEBUG}jcldebug{$ELSE}qwinstacktracer{$ENDIF};
{$ENDIF}

resourcestring
  SUnsupportSymbolClass = '当前符号不兼容类型 %s，期望 % 及其子类。';
  SSymbolDuplicate = '指定的符号实例已经添加，不能重复添加。';
  SUnsupportNow = '<当前不受支持>';
  SUnknownFunction = '<未知>';
  SWaitThreadDesc = '线程 ';
  SIsMainThread = '(主线程)';
  SGetWaitStateError = '<无法获取等待列表(%d):%s>';
  SMoreChainNodes = '获取到 %d 个列表结点，但目前只支持 %d 个。';
  SThreadBlocked = ' <阻止中> ';
  SThreadRunning = ' <运行中> ';
  SWaitAbandoned = ' <已中断> ';
  SWaiting = ' <等待中> ';
  SDeadLockFound = ' !!!已死锁!!! ';
  SComChainDisabled = ' !初始化COM列表失败，无法获取COM状态! ';
  SCantCheckWaitChain = ' <当前操作系统不受支持> ';
  SStackList = '[堆栈]';

const
  WCT_MAX_NODE_COUNT       = 16;
  WCT_OBJNAME_LENGTH       = 128;
  WCT_ASYNC_OPEN_FLAG      = $01;
  WCTP_OPEN_ALL_FLAGS      = WCT_ASYNC_OPEN_FLAG;
  WCT_OUT_OF_PROC_FLAG     = $01;
  WCT_OUT_OF_PROC_COM_FLAG = $02;
  WCT_OUT_OF_PROC_CS_FLAG  = $04;
  WCT_NETWORK_IO_FLAG      = $08;
  WCTP_GETINFO_ALL_FLAGS = WCT_OUT_OF_PROC_FLAG or WCT_OUT_OF_PROC_COM_FLAG or
    WCT_OUT_OF_PROC_CS_FLAG;

  THREAD_GET_CONTEXT       = $0008;
  THREAD_QUERY_INFORMATION = $0040;
  THREAD_ALL_ACCESS        = $1FFFFF;

const
  ObjectTypes: array [0 .. 10] of String = ('CriticalSection', 'SendMessage',
    'Mutex', 'Alpc', 'Com', 'ThreadWait', 'ProcWait', 'Thread', 'ComActivation',
    'Unknown', 'Max');

type
  WCT_OBJECT_TYPE = (WctCriticalSectionType = 1, WctSendMessageType,
    WctMutexType, WctAlpcType, WctComType, WctThreadWaitType,
    WctProcessWaitType, WctThreadType, WctComActivationType, WctUnknownType,
    WctSocketIoType, WctSmbIoType, WctMaxType);

  WCT_OBJECT_STATUS = (WctStatusNoAccess = 1, // ACCESS_DENIED for this object
    WctStatusRunning, // Thread status
    WctStatusBlocked, // Thread status
    WctStatusPidOnly, // Thread status
    WctStatusPidOnlyRpcss, // Thread status
    WctStatusOwned, // Dispatcher object status
    WctStatusNotOwned, // Dispatcher object status
    WctStatusAbandoned, // Dispatcher object status
    WctStatusUnknown, // All objects
    WctStatusError, // All objects
    WctStatusMax);

  TLockObject = record
    ObjectName: array [0 .. WCT_OBJNAME_LENGTH - 1] of WideChar;
    Timeout: Int64; // Not implemented in v1
    Alertable: Boolean; // Not implemented in v1
  end;

  TThreadObject = record
    ProcessId, ThreadId, WaitTime, ContextSwitches: Cardinal;
  end;

  WAITCHAIN_NODE_INFO = record
    ObjectType: WCT_OBJECT_TYPE;
    ObjectStatus: WCT_OBJECT_STATUS;
    case Integer of
      1:
        (LockObject: TLockObject);
      2:
        (ThreadObject: TThreadObject);
  end;

  TWaitChainNodeInfo = WAITCHAIN_NODE_INFO;
  PWaitChainNodeInfo = ^TWaitChainNodeInfo;

  TWaitChainCallback = procedure(WctHandle: THandle; Context: DWORD_PTR;
    CallbackStatus: DWORD; NodeCount: PDWord;
    NodeInfoArrary: PWaitChainNodeInfo; IsCycle: PBool); stdcall;

  TOpenThreadWaitChainSession = function(Flags: DWORD;
    callback: TWaitChainCallback): THandle; stdcall;
  TCloseThreadWaitChainSession = procedure(WctHandle: THandle); stdcall;
  TGetThreadWaitChain = function(WctHandle: THandle; Context: DWORD_PTR;
    Flags, ThreadId: DWORD; NodeCount: LPDWORD;
    NodeInfoArray: PWaitChainNodeInfo; IsCycle: PBool): BOOL; stdcall;
  PCoGetCallState = function(P1: Integer; P2: PCardinal): HRESULT; stdcall;
  PCoGetActivationState = function(AId: TGuid; P1: DWORD; P2: PCardinal)
    : HRESULT; stdcall;
  TRegisterWaitChainCOMCallback = procedure(CallStateCallback: PCoGetCallState;
    ActivationStateCallback: PCoGetActivationState); stdcall;

  TCurrentThreadStackHelper = class(TThread)
  protected
    FTargetThread: THandle;
    FStacks: String;
    procedure Execute; override;
  public
    constructor Create(ATargetThread: THandle); overload;
    destructor Destroy; override;
    property Stacks: String read FStacks;
  end;

  TThreadCheckEvent = procedure(WctHandle: THandle; AThreadId: TThreadId;
    ATag: Pointer; var ADeadFound: Boolean);

  TDeadlockChecker = class(TThread)
  protected
    FEvent: TEvent;
    FComInitialized: Boolean;
    procedure Execute; override;
    function InitializeComAccess: Boolean;
  public
    constructor Create; overload;
    destructor Destroy; override;
    class function EnumWaitChains: QStringW;
    class function CheckThreads(ACallback: TThreadCheckEvent;
      AExcludeThread: TThreadId; ATag: Pointer;
      var ADeadFound: Boolean): Boolean;
    class function DeadlockExists(var ALog: QStringW): Boolean;
  end;
  // XE2以前版本不支持64位
{$IF RTLVersion<=22}

  _IMAGE_IMPORT_DESCRIPTOR = record
    case Byte of
      0:
        (Characteristics: DWORD); // 0 for terminating null import descriptor
      1:
        (OriginalFirstThunk: DWORD;
          // RVA to original unbound IAT (PIMAGE_THUNK_DATA)
          TimeDateStamp: DWORD; // 0 if not bound,
          // -1 if bound, and real date\time stamp
          // in IMAGE_DIRECTORY_ENTRY_BOUND_IMPORT (new BIND)
          // O.W. date/time stamp of DLL bound to (Old BIND)

          ForwarderChain: DWORD; // -1 if no forwarders
          Name: DWORD;
          FirstThunk: DWORD);
    // RVA to IAT (if bound this IAT has actual addresses)
  end;

  IMAGE_IMPORT_DESCRIPTOR = _IMAGE_IMPORT_DESCRIPTOR;
  TImageImportDescriptor = _IMAGE_IMPORT_DESCRIPTOR;
  PIMAGE_IMPORT_DESCRIPTOR = ^_IMAGE_IMPORT_DESCRIPTOR;
  PImageImportDescriptor = ^_IMAGE_IMPORT_DESCRIPTOR;

  _IMAGE_THUNK_DATA64 = record
    case Byte of
      0:
        (ForwarderString: ULONGLONG); // PBYTE
      1:
        (_Function: ULONGLONG); // PDWORD Function -> _Function
      2:
        (Ordinal: ULONGLONG);
      3:
        (AddressOfData: ULONGLONG); // PIMAGE_IMPORT_BY_NAME
  end;

  IMAGE_THUNK_DATA64 = _IMAGE_THUNK_DATA64;
  TImageThunkData64 = _IMAGE_THUNK_DATA64;
  PIMAGE_THUNK_DATA64 = ^_IMAGE_THUNK_DATA64;
  ImageThunkData64 = ^_IMAGE_THUNK_DATA64;

  _IMAGE_THUNK_DATA32 = record
    case Byte of
      0:
        (ForwarderString: DWORD); // PBYTE
      1:
        (_Function: DWORD); // PDWORD Function -> _Function
      2:
        (Ordinal: DWORD);
      3:
        (AddressOfData: DWORD); // PIMAGE_IMPORT_BY_NAME
  end;

  IMAGE_THUNK_DATA32 = _IMAGE_THUNK_DATA32;
  TImageThunkData32 = _IMAGE_THUNK_DATA32;
  PIMAGE_THUNK_DATA32 = ^_IMAGE_THUNK_DATA32;
  PImageThunkData32 = ^_IMAGE_THUNK_DATA32;
  IMAGE_THUNK_DATA = IMAGE_THUNK_DATA32;
  PIMAGE_THUNK_DATA = PIMAGE_THUNK_DATA32;

  TImageNtHeaders32 = TImageNtHeaders;
  PImageOptionalHeader64 = ^TImageOptionalHeader64;

  _IMAGE_OPTIONAL_HEADER64 = record
    { Standard fields. }
    Magic: Word;
    MajorLinkerVersion: Byte;
    MinorLinkerVersion: Byte;
    SizeOfCode: DWORD;
    SizeOfInitializedData: DWORD;
    SizeOfUninitializedData: DWORD;
    AddressOfEntryPoint: DWORD;
    BaseOfCode: DWORD;
    { NT additional fields. }
    ImageBase: ULONGLONG;
    SectionAlignment: DWORD;
    FileAlignment: DWORD;
    MajorOperatingSystemVersion: Word;
    MinorOperatingSystemVersion: Word;
    MajorImageVersion: Word;
    MinorImageVersion: Word;
    MajorSubsystemVersion: Word;
    MinorSubsystemVersion: Word;
    Win32VersionValue: DWORD;
    SizeOfImage: DWORD;
    SizeOfHeaders: DWORD;
    CheckSum: DWORD;
    Subsystem: Word;
    DllCharacteristics: Word;
    SizeOfStackReserve: ULONGLONG;
    SizeOfStackCommit: ULONGLONG;
    SizeOfHeapReserve: ULONGLONG;
    SizeOfHeapCommit: ULONGLONG;
    LoaderFlags: DWORD;
    NumberOfRvaAndSizes: DWORD;
    DataDirectory: packed array [0 .. IMAGE_NUMBEROF_DIRECTORY_ENTRIES - 1]
      of TImageDataDirectory;
  end;

  TImageOptionalHeader64 = _IMAGE_OPTIONAL_HEADER64;
  IMAGE_OPTIONAL_HEADER64 = _IMAGE_OPTIONAL_HEADER64;
  PImageNtHeaders64 = ^TImageNtHeaders64;

  _IMAGE_NT_HEADERS64 = record
    Signature: DWORD;
    FileHeader: TImageFileHeader;
    OptionalHeader: TImageOptionalHeader64;
  end;

  TImageNtHeaders64 = _IMAGE_NT_HEADERS64;
  IMAGE_NT_HEADERS64 = _IMAGE_NT_HEADERS64;

  _IMAGE_IMPORT_BY_NAME = record
    Hint: Word;
    Name: array [0 .. 0] of Byte;
  end;

  IMAGE_IMPORT_BY_NAME = _IMAGE_IMPORT_BY_NAME;
  TImageImportByName = _IMAGE_IMPORT_BY_NAME;
  PIMAGE_IMPORT_BY_NAME = ^_IMAGE_IMPORT_BY_NAME;
  PImageImportByName = ^_IMAGE_IMPORT_BY_NAME;

const
  IMAGE_FILE_MACHINE_AMD64 = $8664; { AMD64 (K8) }
{$IFEND <XE2}
{$IFDEF MSWINDOWS}

type
  TPEImageHeader = record
    case Integer of
      1:
        (PE32: TImageNtHeaders32);
      2:
        (PE64: TImageNtHeaders64);
  end;

var
  OpenThreadWaitChainSession: TOpenThreadWaitChainSession;
  CloseThreadWaitChainSession: TCloseThreadWaitChainSession;
  GetThreadWaitChain: TGetThreadWaitChain;
  RegisterWaitChainCOMCallback: TRegisterWaitChainCOMCallback;
  DeadLocker: TDeadlockChecker;
  DeadCheckThreadId: TThreadId;
function OpenThread(dwDesiredAccess: DWORD; bInheritHandle: Boolean;
  dwThreadId: Cardinal): THandle; stdcall; external kernel32 name 'OpenThread';

{$ENDIF}

function LocateSymbol(const Addr: Pointer;
  var ALocation: TQSymbolLocation): Boolean;
begin
  Result := Symbols.Locate(Addr, ALocation);
end;

function StackOfThread(AThread: TThread): QStringW;
var
  p: PQCharW;
begin
{$IFDEF MSWINDOWS}
  Result := StackByThreadHandle(AThread.Handle);
{$ELSE}
  Result := StackByThreadId(AThread.ThreadId);
{$ENDIF}
  // 移除堆栈中自身的调用
  if Length(Result) > 0 then
  begin
    p := PQCharW(Result);
    p := StrStrW(p, 'StackOfThread');
    if p <> nil then
    begin
      SkipLineW(p);
      Result := p;
    end;
  end;
end;

function StackByThreadId(AThreadId: TThreadId): QStringW;
{$IFDEF MSWINDOWS}
var
  AHandle: THandle;
  p: PQCharW;
{$ENDIF}
begin
{$IFDEF MSWINDOWS}
  AHandle := OpenThread(THREAD_QUERY_INFORMATION or THREAD_GET_CONTEXT, False,
    AThreadId);
  if AHandle <> 0 then
  begin
    Result := StackByThreadHandle(AHandle);
    if Length(Result) > 0 then
    begin
      p := PQCharW(Result);
      p := StrStrW(p, 'StackByThreadId');
      if p <> nil then
      begin
        SkipLineW(p);
        Result := p;
      end;
    end;
  end
  else
    SetLength(Result, 0);
{$ELSE}
  Result := SUnsupportNow;
{$ENDIF}
end;
{$IFDEF MSWINDOWS}
{$IFNDEF CPUX64}

var
  EIP: Cardinal;

procedure GetEIP(); stdcall;
asm
  pop eax;
  mov EIP,eax;
  push eax;
end;
{$ENDIF}
type
  THREAD_BASIC_INFORMATION = record
    ExitStatus: Cardinal;
    TebBaseAddress: Pointer;
    ProcessId: THandle;
    ThreadId: THandle;
    AffinityMask: ULONG;
    Priority: LongInt;
    BasePriority: LongInt;
  end;

  TNtQueryInformationThread = function(ThreadHandle: THandle;
    ThreadInformationClass: Cardinal; ThreadInformation: Pointer;
    ThreadInformationLength: ULONG; ReturnLength: PULONG): Cardinal; stdcall;

var
  NtQueryInformationThread: TNtQueryInformationThread;

function IdByThreadHandle(AHandle: THandle): DWORD;
var
  AInfo: THREAD_BASIC_INFORMATION;
  L: ULONG;
begin
  if AHandle = GetCurrentThread then
    Result := GetCurrentThreadId
  else
  begin
    FillChar(AInfo, SizeOf(THREAD_BASIC_INFORMATION), 0);
    NtQueryInformationThread(AHandle, 0, @AInfo,
      SizeOf(THREAD_BASIC_INFORMATION), @L);
    Result := AInfo.ThreadId;
  end;
end;
{$ENDIF MSWINDOWS}
{$IFDEF MSWINDOWS}

function StackByThreadHandle(AThread: THandle): QStringW;
var
{$IFDEF USE_JCLDEBUG}
  AStacks: TJclStackInfoList;
{$ELSE}
  AFrames: TStackFrames;
{$ENDIF}
  AInfo: TQSymbolLocation;
  I, C: Integer;
  function FormatLocation: QStringW;
  begin
    Result := IntToHex(NativeInt(AInfo.Addr), SizeOf(NativeInt) shl 1) + ' ' +
      AInfo.FileName;
    if (Length(Result) > 0) and (AInfo.LineNo <> 0) then
      Result := Result + '[' + IntToStr(AInfo.LineNo) + ']:'
    else
      Result := Result + ':';
    Result := Result + AInfo.FunctionName;
  end;
  function DumpCurrentStack: String;
  var
    AHelper: TCurrentThreadStackHelper;
    p: PChar;
    AHandle: THandle;
  begin
    if AThread = GetCurrentThread then
      AHandle := OpenThread(THREAD_ALL_ACCESS, False, GetCurrentThreadId)
    else
      AHandle := AThread;
    AHelper := TCurrentThreadStackHelper.Create(AHandle);
    try
      AHelper.WaitFor;
      Result := AHelper.Stacks;
    finally
      FreeObject(AHelper);
      if AHandle <> AThread then
        CloseHandle(AHandle);
    end;
    if Length(Result) > 0 then
    begin
      p := PChar(Result);
      I := Pos('StackByThreadHandle', Result);
      Inc(p, I);
      while (p^ <> #0) do
      begin
        if p^ = #10 then
        begin
          Inc(p);
          Result := p;
          Break;
        end
        else
          Inc(p);
      end;
    end;
  end;

begin
  if GetCurrentThreadId = IdByThreadHandle(AThread) then
  begin
    Result := DumpCurrentStack;
    Exit;
  end;
  SetLength(Result, 0);
{$IFDEF USE_JCLDEBUG}
  AStacks := JclCreateThreadStackTrace(True, AThread);
  if Assigned(AStacks) then
  begin
    try
      C := AStacks.Count;
      if C > 20 then
        C := 20;
      for I := 0 to C - 1 do
      begin
        if Symbols.Locate(AStacks.Items[I].CallerAddr, AInfo) then
          Result := Result + FormatLocation + #13#10
        else
          Result := Result + IntToHex(IntPtr(AStacks.Items[I].CallerAddr),
            SizeOf(IntPtr) shl 1) + #13#10;
      end;
    finally
      FreeObject(AStacks);
    end;
  end;
{$ELSE}
  AFrames := GetThreadStacks(AThread);
  C := High(AFrames);
  if C > 20 then
    C := 20;
  for I := Low(AFrames) to C do
  begin
    if Symbols.Locate(Pointer(AFrames[I].AddrPC.Offset - 6), AInfo) then
      Result := Result + FormatLocation + #13#10
    else
      Result := Result + GetFunctionInfo(Pointer(AFrames[I].AddrPC.Offset)
        ) + #13#10;
  end;
{$ENDIF}
end;
{$ENDIF}

{ TQSymbols }
function TQSymbols.Add(AOffset: NativeInt): TQSymbolBase;
var
  AIndex: Integer;
begin
  if FItems.Capacity = FItems.Count then
    FItems.Capacity := FItems.Capacity shl 1;
  Result := FItemClass.Create;
  Result.FOwner := Self;
  Result.FOffset := AOffset;
  if FUpdateCount = 0 then
  begin
    InternalFind(AOffset, AIndex);
    FItems.Insert(AIndex, Result);
  end
  else
    FItems.Add(Result);
end;

function TQSymbols.Add(AItem: TQSymbolBase): Integer;
begin
  if AItem is FItemClass then
  begin
    AItem.FOwner := Self;
    if FItems.Capacity = FItems.Count then
      FItems.Capacity := FItems.Capacity shl 1;
    if FUpdateCount = 0 then
    begin
      if InternalFind(AItem.FOffset, Result) then
      begin
        if Items[Result] = AItem then
          raise Exception.Create(SSymbolDuplicate);
      end;
      FItems.Insert(Result, AItem);
    end
    else
      FItems.Add(AItem);
  end
  else
    raise Exception.CreateFmt(SUnsupportSymbolClass, [AItem.ClassType.ClassName,
      FItemClass.ClassName]);
end;

procedure TQSymbols.BeginUpdate;
begin
  Inc(FUpdateCount);
end;

procedure TQSymbols.Clear;
var
  I: Integer;
begin
  for I := 0 to FItems.Count - 1 do
    FreeObject(FItems[I]);
  FItems.Clear;
end;

constructor TQSymbols.Create(AItemClass: TQSymbolClass);
begin
  inherited Create;
  FItemClass := AItemClass;
  FItems := TQSymbolList.Create;
  FItems.Capacity := 64;
end;

procedure TQSymbols.Delete(AIndex: Integer);
begin
  FreeObject(Items[AIndex]);
  FItems.Delete(AIndex);
end;

destructor TQSymbols.Destroy;
begin
  Clear;
  FreeObject(FItems);
  inherited;
end;

procedure TQSymbols.EndUpdate;
begin
  Dec(FUpdateCount);
  if FUpdateCount = 0 then
  begin
    FItems.Capacity := FItems.Count;
    Sort;
  end;
end;

function TQSymbols.FindNearest(AOffset: NativeInt): TQSymbolBase;
var
  I: Integer;
begin
  I := IndexOfNearest(AOffset);
  if I <> -1 then
    Result := Items[I]
  else
    Result := nil;
end;

function TQSymbols.GetCapapcity: Integer;
begin
  Result := FItems.Capacity;
end;

function TQSymbols.GetCount: Integer;
begin
  Result := FItems.Count;
end;

function TQSymbols.GetItems(AIndex: Integer): TQSymbolBase;
begin
  Result := FItems[AIndex];
end;

function TQSymbols.IndexOfNearest(AOffset: NativeInt): Integer;
var
  C: Integer;
begin
  if not InternalFind(AOffset, Result) then
  begin
    C := Count;
    if C > 0 then
    begin
      if Result >= 0 then
        Dec(Result)
      else
        Result := C - 1;
    end
    else
      Result := -1;
  end;
end;

function TQSymbols.InternalFind(const Addr: NativeInt;
  var AIndex: Integer): Boolean;
var
  L, H, I: Integer;
  V: NativeInt;
begin
  Result := False;
  L := 0;
  H := Count - 1;
  while L <= H do
  begin
    I := (L + H) shr 1;
    V := Items[I].FOffset;
    if V < Addr then
      L := I + 1
    else
    begin
      H := I - 1;
      if V = Addr then
      begin
        Result := True;
      end;
    end;
  end;
  AIndex := L;
end;

procedure TQSymbols.SetCapacity(const Value: Integer);
begin
  FItems.Capacity := Value;
end;

procedure TQSymbols.Sort;
  procedure QuickSort(L, R: Integer);
  var
    I, J, p: Integer;
  begin
    repeat
      I := L;
      J := R;
      p := (L + R) shr 1;
      repeat
        while Items[I].Offset < Items[p].Offset do
          Inc(I);
        while Items[J].Offset > Items[p].Offset do
          Dec(J);
        if I <= J then
        begin
          if I <> J then
            FItems.Exchange(I, J);
          if p = I then
            p := J
          else if p = J then
            p := I;
          Inc(I);
          Dec(J);
        end;
      until I > J;
      if L < J then
        QuickSort(L, J);
      L := I;
    until I >= R;
  end;

begin
  if Count > 0 then
    QuickSort(0, Count - 1);
end;

{ TQDebugSymbols }

procedure TQDebugSymbols.Add(AFile: TQSymbolMapFile; AOffset: Cardinal);
begin
  FItems.Add(AFile);
  AFile.Offset := AOffset;
end;

constructor TQDebugSymbols.Create;
begin
  inherited;
  FItems := TQSymbols.Create(TQSymbolMapFile);
end;

destructor TQDebugSymbols.Destroy;
begin
  FreeObject(FItems);
  inherited;
end;

function TQDebugSymbols.Locate(const Addr: Pointer;
  var AInfo: TQSymbolLocation): Boolean;
var
  AFile: TQSymbolMapFile;
begin
  ResetLocation(AInfo);
  if not FSymbolsLoaded then
    LoadSymbols;
  AFile := FItems.FindNearest(NativeInt(Addr)) as TQSymbolMapFile;
  if (AFile <> nil) and (AFile.Offset + IntPtr(AFile.Size) > IntPtr(Addr)) then
    Result := AFile.Locate(Addr, AInfo)
  else
    Result := False;
end;

procedure TQDebugSymbols.LoadDefault;
var
  AFileName: QStringW;
{$IFDEF MSWINDOWS}
  // 解析PE文件头，找到代码起始地址
  function IsPEFile(AFile: TFileStream; var APEHdr: TPEImageHeader): Boolean;
  var
    ADosHdr: TImageDosHeader;
  begin
    AFile.ReadBuffer(ADosHdr, SizeOf(TImageDosHeader));
    if (ADosHdr.e_magic = IMAGE_DOS_SIGNATURE) and (ADosHdr._lfanew <> 0) then
    begin
      AFile.Position := ADosHdr._lfanew;
      AFile.ReadBuffer(APEHdr, SizeOf(TImageNtHeaders32));
      Result := (APEHdr.PE32.Signature = IMAGE_NT_SIGNATURE) and
        ((APEHdr.PE32.FileHeader.Machine = IMAGE_FILE_MACHINE_I386) or
        (APEHdr.PE32.FileHeader.Machine = IMAGE_FILE_MACHINE_AMD64));
      if APEHdr.PE32.FileHeader.Machine = IMAGE_FILE_MACHINE_AMD64 then
        // 64位则读取PE头部剩下的字节
        AFile.ReadBuffer(PByte(IntPtr(@APEHdr) + SizeOf(TImageNtHeaders32))^,
          SizeOf(TImageNtHeaders64) - SizeOf(TImageNtHeaders32));
    end
    else
      Result := False;
  end;

  function ReadImports(AFile: TFileStream; AImportVAddr: DWORD; ASections: Word)
    : TStrings;
  var
    ADLL: String;
    I: Word;
    AHdr: TImageSectionHeader;
    AImport: PImageImportDescriptor;
    AMem: Pointer;
    AOffset: Integer;
    ALastPos: Int64;
    AImportEnd: IntPtr;
    ABuffer: array [0 .. 519] of Byte;
    AThunk: IMAGE_THUNK_DATA;
    ACat: TQStringCatHelperW;
  begin
    Result := TStringList.Create;
    ACat := TQStringCatHelperW.Create;
    Result.BeginUpdate;
    try
      for I := 0 to ASections - 1 do
      begin
        AFile.ReadBuffer(AHdr, SizeOf(TImageSectionHeader));
        if AHdr.VirtualAddress = AImportVAddr then
        begin
          // 找到了导入小节
          AFile.Position := AHdr.PointerToRawData;
          GetMem(AMem, AHdr.SizeOfRawData);
          try
            AFile.ReadBuffer(AMem^, AHdr.SizeOfRawData);
            AImport := AMem;
            AImportEnd := IntPtr(AMem) + IntPtr(AHdr.SizeOfRawData);
            AOffset := AHdr.PointerToRawData - AHdr.VirtualAddress;
            while (IntPtr(AImport) < AImportEnd) and (AImport.Name <> 0) do
            begin
              AFile.Position := Int64(AImport.Name) + AOffset;
              AFile.Read(ABuffer[0], 520);
              ADLL := AnsiDecode(@ABuffer[0], -1);
              ACat.Reset;
              AFile.Position := Int64(AImport.FirstThunk) + AOffset;
              repeat
                if AFile.Read(AThunk, SizeOf(IMAGE_THUNK_DATA))
                  = SizeOf(IMAGE_THUNK_DATA) then
                begin
                  ALastPos := AFile.Position;
                  if AThunk.Ordinal <> 0 then
                  begin
                    AFile.Position := Int64(AThunk.Ordinal) + AOffset;
                    AFile.Read(ABuffer[0], 520);
                    if PImageImportByName(@ABuffer[0]).Hint = 0 then
                    begin
                      ACat.Cat(AnsiDecode(@PImageImportByName(@ABuffer[0])
                        .Name[0], -1)).Cat(',');
                      AFile.Position := ALastPos;
                    end;
                  end;
                end
                else
                  Break;
              until AThunk.Ordinal = 0;
              ACat.Back(1);
              Result.Add(ADLL + '=' + ACat.Value);
              AImport :=
                Pointer(IntPtr(AImport) + SizeOf(TImageImportDescriptor));
            end;
          finally
            FreeMem(AMem);
          end;
          Break;
        end;
      end;
    finally
      Result.EndUpdate;
      FreeObject(ACat);
    end;
  end;
  function LoadPEImports(AFile: TFileStream; AMapFile: TQSymbolMapFile;
    AdjustOffset: Boolean): Boolean;
  var
    AHdr: TPEImageHeader;
  begin
    Result := IsPEFile(AFile, AHdr);
    if not Result then
      Exit;
    // 调整模块的加载地址区间
    if AHdr.PE32.FileHeader.Machine = IMAGE_FILE_MACHINE_AMD64 then
    begin
      if AdjustOffset then
      begin
        if AMapFile.FOffset = 0 then
          AMapFile.FOffset := AHdr.PE64.OptionalHeader.ImageBase +
            AHdr.PE64.OptionalHeader.BaseOfCode
        else
          Inc(AMapFile.FOffset, AHdr.PE64.OptionalHeader.BaseOfCode);
      end;
      AMapFile.Size := AHdr.PE64.OptionalHeader.SizeOfCode;
      AMapFile.Tag :=
        NativeInt(ReadImports(AFile, AHdr.PE64.OptionalHeader.DataDirectory
        [IMAGE_DIRECTORY_ENTRY_IMPORT].VirtualAddress,
        AHdr.PE64.FileHeader.NumberOfSections));
    end
    else
    begin
      if AdjustOffset then
      begin
        if AMapFile.FOffset = 0 then
          AMapFile.FOffset := AHdr.PE32.OptionalHeader.ImageBase +
            AHdr.PE32.OptionalHeader.BaseOfCode
        else
          Inc(AMapFile.FOffset, AHdr.PE32.OptionalHeader.BaseOfCode);
      end;
      AMapFile.Size := AHdr.PE32.OptionalHeader.SizeOfCode;
      AMapFile.Tag :=
        NativeInt(ReadImports(AFile, AHdr.PE32.OptionalHeader.DataDirectory
        [IMAGE_DIRECTORY_ENTRY_IMPORT].VirtualAddress,
        AHdr.PE32.FileHeader.NumberOfSections));
    end;
  end;

  function LoadDLLAddresses(AMapFile: TQSymbolMapFile): Boolean;
  var
    AFile: TFileStream;
  begin
    AFile := TFileStream.Create(AMapFile.FileName, fmOpenRead or
      fmShareDenyWrite);
    try
      Result := LoadPEImports(AFile, AMapFile, True);
    finally
      FreeObject(AFile);
    end;
  end;

  function GetModuleName(AHandle: THandle): QStringW;
  begin
    SetLength(Result, MAX_PATH);
    SetLength(Result, GetModuleFileNameW(AHandle, PQCharW(Result), MAX_PATH));
  end;

  procedure BindImports(AList: TStrings);
  var
    AModule: THandle;
    I, J: Integer;
    ADLL, AFunc, S: QStringW;
    p: PQCharW;
    AMap: TQSymbolMapFile;
    AProc: TQNamedSymbol;
  const
    ANameSpliter: PWideChar = '=';
    AFuncSpliter: PWideChar = ',';
    ANonQuoter: WideChar    = #0;
  begin
    for I := 0 to AList.Count - 1 do
    begin
      S := AList[I];
      p := PQCharW(S);
      ADLL := DecodeTokenW(p, ANameSpliter, ANonQuoter, True);
      AModule := GetModuleHandleW(PQCharW(ADLL));
      if AModule <> 0 then
      begin
        for J := 0 to FItems.Count - 1 do
        begin
          AMap := FItems[J] as TQSymbolMapFile;
          if EndWithW(AMap.FileName, ADLL, True) then // 找到了
          begin
            repeat
              AFunc := DecodeTokenW(p, AFuncSpliter, ANonQuoter, True);
              if Length(AFunc) > 0 then
              begin
                AProc := AMap.FFunctions.Add
                  (IntPtr(GetProcAddress(AModule,
                  LPCSTR(PQCharA(AnsiEncode(AFunc)))))) as TQNamedSymbol;
                AProc.Name := AFunc;
              end;
            until p^ = #0;
          end;
        end;
      end;
    end;
    FreeObject(AList);
  end;

  procedure LoadImports;
  var
    AHandles: array of THandle;
    ACount: Cardinal;
    I: Integer;
    AMapFile, AExeMapFile: TQSymbolMapFile;
    AFile: TFileStream;
    AFileName: QStringW;
  begin
    // 枚举已加载动态链接库导入函数
    ACount := 0;
    EnumProcessModules(GetCurrentProcess, nil, 0, ACount);
    SetLength(AHandles, ACount);
    if EnumProcessModules(GetCurrentProcess, @AHandles[0], ACount, ACount) then
    begin
      AExeMapFile := FItems[0] as TQSymbolMapFile;
      for I := 0 to ACount - 1 do
      begin
        if (AHandles[I] <> 0) and (AHandles[I] <> MainInstance) then
        begin
          AMapFile := TQSymbolMapFile.Create;
          AMapFile.FileName := GetModuleName(AHandles[I]);
          AMapFile.FOffset := AHandles[I];
          LoadDLLAddresses(AMapFile);
          FItems.Add(AMapFile);
        end;
      end;
      try
        AFileName := GetModuleName(MainInstance);
        AFile := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyWrite);
        try
          LoadPEImports(AFile, AExeMapFile, False);
          // 将导出函数加载到对应的映像上
          FItems.Sort;
          for I := 0 to FItems.Count - 1 do
          begin
            BindImports(Pointer(FItems[I].Tag));
          end;
        finally
          FreeObject(AFile);
        end;
      except
        on E: Exception do
          OutputDebugString
            (PChar(String('Error read symbols ' + AFileName + ' :' +
            E.Message)));
      end;
    end;
  end;
{$ENDIF}

begin
  AFileName := ChangeFileExt(ParamStr(0), '.map');
  if FileExists(AFileName) then
  begin
    (FItems.Add(0) as TQSymbolMapFile).FileName := AFileName;
    LoadSymbols;
{$IFDEF MSWINDOWS}
    LoadImports;
{$ENDIF}
  end;
end;

procedure TQDebugSymbols.LoadSymbols;
var
  I: Integer;
begin
  try
    for I := 0 to FItems.Count - 1 do
      (FItems[I] as TQSymbolMapFile).LoadSymbols;
    FSymbolsLoaded := True;
  except
  end;
end;

function TQDebugSymbols.Locate(const Addr: Pointer): TQSymbolLocation;
begin
  ResetLocation(Result);
  Locate(Addr, Result);
end;

procedure TQDebugSymbols.ResetLocation(var AInfo: TQSymbolLocation);
begin
  AInfo.Addr := nil;
  SetLength(AInfo.FunctionName, 0);
  SetLength(AInfo.UnitName, 0);
  SetLength(AInfo.FileName, 0);
  AInfo.LineNo := 0;
end;

{ TQSymbolBase }

constructor TQSymbolBase.Create;
begin
  inherited Create;
end;

destructor TQSymbolBase.Destroy;
begin
  inherited;
end;

{ TQSymbolMapFile }

constructor TQSymbolMapFile.Create;
begin
  inherited;
  FFunctions := TQSymbols.Create(TQNamedSymbol);
  FModules := TQSymbols.Create(TQFileSymbol);
  FLines := TQSymbols.Create(TQLineOffset);
end;

destructor TQSymbolMapFile.Destroy;
begin
  FreeObject(FFunctions);
  FreeObject(FModules);
  FreeObject(FLines);
  inherited;
end;

function TQSymbolMapFile.GetFileName: String;
begin
  Result := Name;
end;

procedure TQSymbolMapFile.LoadSymbols;
var
  S: QStringW;
  SSectionEnd: QStringW;
  ASegIndex: QStringW;
  AModules: TQHashTable;
  function ParseCodeBase(p: PQCharW): Boolean;
  var
    ps: PQCharW;
    AOffset, ASize: Int64;
  begin
    SkipSpaceW(p);
    Result := False;
    // 找到段定位部分
    if StartWithW(p, 'Start', False) then
    begin
      // 跳过行首
      SkipLineW(p);
      repeat
        SkipSpaceW(p);
        ps := p;
        SkipUntilW(p, [':']);
        if p^ <> ':' then
          Exit;
        Inc(p);
        ASegIndex := StrDupX(ps, p - ps);
        Inc(p);
        if ParseHex(p, AOffset) <> 0 then // 偏移量OK
        begin
          SkipSpaceW(p);
          if ParseHex(p, ASize) <> 0 then
          begin
            // 跳过name，解析Class
            SkipUntilW(p, [' ', #9]);
            SkipSpaceW(p);
            SkipUntilW(p, [' ', #9]);
            SkipSpaceW(p);
            if StartWithW(p, 'CODE', True) then
            begin
              if FOffset = 0 then
              begin
                if AOffset = 0 then
                  AOffset := $401000; // 默认的代码地址段，如果未定义，则以其为基准
                FOffset := AOffset;
              end;
              FSize := ASize;
              Result := True;
              Break;
            end;
          end
          else // 解析段大小失败
            Exit;
        end
        else // 解析段偏移失败
          Exit;
      until p^ <> #0;
    end;
  end;
  function ParseFunctions(p: PQCharW): Boolean;
  var
    AOffset: Int64;
    AItem: TQNamedSymbol;
    ps: PQCharW;
  begin
    p := StrStrW(p, 'Publics by Name');
    Result := p <> nil;
    if Result then
    begin
      Inc(p, 15);
      repeat
        SkipSpaceW(p);
        if CompareMem(p, PQCharW(ASegIndex), Length(ASegIndex) shl 1) then
        begin
          Inc(p, Length(ASegIndex));
          if ParseHex(p, AOffset) <> 0 then
          begin
            SkipSpaceW(p);
            AItem := FFunctions.Add(AOffset + FOffset) as TQNamedSymbol;
            ps := p;
            SkipUntilW(p, [#10, #13]);
            AItem.Name := StrDupX(ps, p - ps);
            if CompareMem(p, PQCharW(SSectionEnd), Length(SSectionEnd) shl 1)
            then
            begin
              SkipSpaceW(p);
              Break;
            end;
          end
          else
          begin
            Result := False;
            Break;
          end;
        end
        else
        begin
          SkipLineW(p);
          if (p^ = #13) then
            Inc(p);
          if p^ = #10 then
          begin
            Inc(p);
            SkipSpaceW(p);
            Break;
          end;
        end;
      until p^ = #0;
    end;
  end;
  function ParseLines(p: PQCharW): Boolean;
  var
    ps: PQCharW;
    AModuleName, AFileName, AKey: QStringW;
    AList: PQHashList;
    AMod: TQFileSymbol;
    ALineNo, AOffset: Int64;
    AItem: TQLineOffset;
  begin
    Result := False;
    repeat
      ps := StrStrW(p, 'Line numbers for ');
      if ps <> nil then
      begin
        Result := True;
        Inc(ps, 17);
        p := ps;
        SkipSpaceW(p);
        ps := p;
        SkipUntilW(p, ['(']);
        AModuleName := StrDupX(ps, p - ps);
        Inc(p);
        ps := p;
        SkipUntilW(p, [')']);
        AFileName := StrDupX(ps, p - ps);
        AKey := AModuleName + AFileName;
        AList := AModules.FindFirst(HashOf(PQCharW(AKey), Length(AKey) shl 1));
        AMod := nil;
        while AList <> nil do
        begin
          if (TQFileSymbol(AList.Data).Name = AModuleName) and
            (TQFileSymbol(AList.Data).FileName = AFileName) then
          begin
            AMod := AList.Data;
            Break;
          end
          else
            AList := AList.Next;
        end;
        if AMod = nil then
        begin
          AMod := TQFileSymbol.Create;
          AMod.Name := AModuleName;
          AMod.FileName := AFileName;
          FModules.Add(AMod);
        end;
        SkipLineW(p);
        // 开始解析行信息
        SkipSpaceW(p);
        repeat
          if ParseInt(p, ALineNo) <> 0 then
          begin
            SkipSpaceW(p);
            if CompareMem(p, PQCharW(ASegIndex), Length(ASegIndex) shl 1) then
            begin
              Inc(p, Length(ASegIndex));
              if ParseHex(p, AOffset) <> 0 then
              begin
                SkipSpaceW(p);
                AItem := FLines.Add(AOffset + FOffset) as TQLineOffset;
                AItem.LineNo := ALineNo;
                AItem.Module := AMod;
              end;
            end
            else
              SkipLineW(p);
          end
          else
            Break;
        until False;
      end
      else
        Break;
    until not Result;
  end;
  procedure ParseSymbols(p: PQCharW);
  begin
    if not ParseCodeBase(p) then
      Exit;
    if not ParseFunctions(p) then
      Exit;
    if not ParseLines(p) then
      Exit;
  end;

begin
  AModules := TQHashTable.Create();
  SSectionEnd := #13#10#13#10;
  FFunctions.BeginUpdate;
  FModules.BeginUpdate;
  FLines.BeginUpdate;
  try
    FFunctions.Clear;
    FModules.Clear;
    FLines.Clear;
    AModules.AutoSize := True;
    S := LoadTextW(FileName);
    ParseSymbols(PQCharW(S));
  finally
    FFunctions.EndUpdate;
    FModules.EndUpdate;
    FLines.EndUpdate;
    FreeObject(AModules);
  end;
end;

function TQSymbolMapFile.Locate(const Addr: Pointer;
  var AInfo: TQSymbolLocation): Boolean;
var
  ASymbol: TQSymbolBase;
begin
  AInfo.Addr := Addr;
  Result := False;
  ASymbol := FFunctions.FindNearest(NativeInt(Addr));
  if ASymbol <> nil then
  begin
    AInfo.FunctionName := TQNamedSymbol(ASymbol).Name;
    AInfo.FileName := FileName;
    AInfo.UnitName := ExtractFileName(FileName);
    Result := True;
  end;
  ASymbol := FLines.FindNearest(NativeInt(Addr));
  if ASymbol <> nil then
  begin
    AInfo.LineNo := TQLineOffset(ASymbol).LineNo;
    with TQFileSymbol(TQLineOffset(ASymbol).Module) do
    begin
      AInfo.FileName := FileName;
      AInfo.UnitName := Name;
    end;
    Result := True;
  end;
end;

procedure TQSymbolMapFile.SetFileName(const Value: String);
begin
  Name := Value;
end;
{$IFDEF MSWINDOWS}

function EnablePrivilege(PrivName: string; bEnable: Boolean): Boolean;
var
  TP: PTokenPrivileges;
  Dummy: Cardinal;
  hToken: THandle;
begin
  Result := False;
  if OpenProcessToken(GetCurrentProcess, TOKEN_ADJUST_PRIVILEGES or TOKEN_QUERY,
    hToken) then
  begin
    GetMem(TP, SizeOf(DWORD) + SizeOf(TLUIDAndAttributes));
    try
      TP.PrivilegeCount := 1;
      if LookupPrivilegeValue(nil, PChar(PrivName), TP.Privileges[0].Luid) then
      begin
        if bEnable then
          TP.Privileges[0].Attributes := SE_PRIVILEGE_ENABLED
        else
          TP.Privileges[0].Attributes := 0;
        Result := AdjustTokenPrivileges(hToken, False, TP^, SizeOf(TP),
          nil, Dummy);
      end
      else
        Result := False;
    finally
      FreeMem(TP);
      CloseHandle(hToken);
    end;
  end;
end;

{$ENDIF}
{ TCurrentThreadStackHelper }

constructor TCurrentThreadStackHelper.Create(ATargetThread: THandle);
begin
  FTargetThread := ATargetThread;
  inherited Create(False);
end;

destructor TCurrentThreadStackHelper.Destroy;
begin

  inherited;
end;

procedure TCurrentThreadStackHelper.Execute;
begin
  FStacks := StackByThreadHandle(FTargetThread);
end;

// 枚举线程等待列表
function EnumWaitChains: QStringW;
begin
  Result := TDeadlockChecker.EnumWaitChains;
end;

{ TDeadlockChecker }

class function TDeadlockChecker.CheckThreads(ACallback: TThreadCheckEvent;
  AExcludeThread: TThreadId; ATag: Pointer; var ADeadFound: Boolean): Boolean;
var
  hSnapshot, hThread, hWct: THandle;
  AEntry: THREADENTRY32;
  AProcId: Cardinal;
  AExitCode: DWORD;
begin
  ADeadFound := False;
  Result := False;
  if not Assigned(OpenThreadWaitChainSession) then
    Exit;
  hWct := OpenThreadWaitChainSession(0, nil);
  if hWct <> 0 then
  begin
    try
      AProcId := GetCurrentProcessId;
      hSnapshot := CreateToolhelp32Snapshot(TH32CS_SNAPTHREAD, AProcId);
      if hSnapshot <> 0 then
      begin
        AEntry.dwSize := SizeOf(THREADENTRY32);
        if Thread32First(hSnapshot, AEntry) then
        begin
          repeat
            if (AEntry.th32OwnerProcessID = AProcId) and
              (AEntry.th32ThreadID <> AExcludeThread) then
            begin
              hThread := OpenThread(THREAD_ALL_ACCESS, False,
                AEntry.th32ThreadID);
              if hThread <> 0 then
              begin
                GetExitCodeThread(hThread, AExitCode);
                if AExitCode = STILL_ACTIVE then
                  ACallback(hWct, AEntry.th32ThreadID, ATag, ADeadFound);
                CloseHandle(hThread);
              end;
            end;
          until not Thread32Next(hSnapshot, AEntry);
        end;
        Result := True;
        CloseHandle(hSnapshot);
      end;
    finally
      CloseThreadWaitChainSession(hWct);
    end;
  end;
end;

constructor TDeadlockChecker.Create;
begin
  inherited Create(True);
  FEvent := TEvent.Create(nil, False, False, '');
  FreeOnTerminate := True;
end;

procedure CheckThreadDeadlock(WctHandle: THandle; AThreadId: TThreadId;
  ATag: Pointer; var ADeadFound: Boolean);
var
  NodeInfoArray: array [0 .. WCT_MAX_NODE_COUNT - 1] of WAITCHAIN_NODE_INFO;
  Count, I: DWORD;
  IsCycle: Boolean;
  ABuilder: TQStringCatHelperW;
const
  SpaceChar: PWideChar = ' ';
begin
  ABuilder := ATag;
  Count := WCT_MAX_NODE_COUNT;
  if not GetThreadWaitChain(WctHandle, 0, WCTP_GETINFO_ALL_FLAGS, AThreadId,
    @Count, @NodeInfoArray[0], @IsCycle) then
  begin
    I := GetLastError;
    ABuilder.Cat(SpaceChar, 1)
      .Cat(Format(SGetWaitStateError, [I, SysErrorMessage(I)])).Cat(SLineBreak);
    Exit;
  end;
  if IsCycle then // 在发生死锁时才记录相关日志
  begin
    ADeadFound := True;
    ABuilder.Cat(SWaitThreadDesc).Cat(AThreadId);
    if AThreadId = MainThreadId then
      ABuilder.Cat(SIsMainThread);
    ABuilder.Cat(SLineBreak).Cat(SDeadLockFound).Cat(SLineBreak);
    if Count > WCT_MAX_NODE_COUNT then
    begin
      ABuilder.Cat(SpaceChar, 1)
        .Cat(Format(SMoreChainNodes, [Count, WCT_MAX_NODE_COUNT]))
        .Cat(SLineBreak);
      Count := WCT_MAX_NODE_COUNT;
    end;
    for I := 0 to Count - 1 do
    begin
      ABuilder.Cat(SpaceChar, 1);
      case NodeInfoArray[I].ObjectType of
        WctThreadType:
          begin
            ABuilder.Cat(SWaitThreadDesc)
              .Cat(NodeInfoArray[I].ThreadObject.ThreadId);
            if NodeInfoArray[I].ObjectStatus = WctStatusBlocked then
              ABuilder.Cat(SThreadBlocked)
            else
              ABuilder.Cat(SThreadRunning);
            if IsCycle then
              ABuilder.Cat(SLineBreak).Cat(SStackList).Cat(SLineBreak)
                .Cat(StackByThreadId(NodeInfoArray[I].ThreadObject.ThreadId));
          end
      else
        begin
          ABuilder.Cat(ObjectTypes[Integer(NodeInfoArray[I].ObjectType) - 1]);
          if NodeInfoArray[I].LockObject.ObjectName[0] <> #0 then
            ABuilder.Cat('-').Cat(NodeInfoArray[I].LockObject.ObjectName);
          if NodeInfoArray[I].ObjectStatus = WctStatusAbandoned then
            ABuilder.Cat(SWaitAbandoned)
          else
            ABuilder.Cat(SWaiting);
        end;
      end;
      ABuilder.Cat(SLineBreak);
    end;
  end;
end;

class function TDeadlockChecker.DeadlockExists(var ALog: QStringW): Boolean;
var
  ABuilder: TQStringCatHelperW;
begin
  if not Assigned(OpenThreadWaitChainSession) then
    Result := False
  else
  begin
    ABuilder := TQStringCatHelperW.Create;
    try
      if CheckThreads(CheckThreadDeadlock, DeadCheckThreadId, ABuilder, Result)
      then
      begin
        if Result then
          ALog := ABuilder.Value
        else
          SetLength(ALog, 0);
      end
      else
      begin
        Result := False;
        ALog := Format(SGetWaitStateError,
          [GetLastError, SysErrorMessage(GetLastError)]);
      end;
    finally
      FreeObject(ABuilder);
    end;
  end;
end;

destructor TDeadlockChecker.Destroy;
begin
  FreeObject(FEvent);
  inherited;
end;

procedure PrintThreadWaitChain(hWct: THandle; AThreadId: TThreadId;
  ATag: Pointer; var ADeadFound: Boolean);
var
  NodeInfoArray: array [0 .. WCT_MAX_NODE_COUNT - 1] of WAITCHAIN_NODE_INFO;
  Count, I: DWORD;
  IsCycle: Boolean;
  ABuilder: TQStringCatHelperW;
const
  SpaceChar: PWideChar = ' ';
begin
  ABuilder := ATag;
  Count := WCT_MAX_NODE_COUNT;
  if not GetThreadWaitChain(hWct, 0, WCTP_GETINFO_ALL_FLAGS, AThreadId, @Count,
    @NodeInfoArray[0], @IsCycle) then
  begin
    I := GetLastError;
    ABuilder.Cat(SpaceChar, 1)
      .Cat(Format(SGetWaitStateError, [I, SysErrorMessage(I)])).Cat(SLineBreak);
    Exit;
  end;
  ABuilder.Cat(SWaitThreadDesc).Cat(AThreadId);
  if AThreadId = MainThreadId then
    ABuilder.Cat(SIsMainThread);
  ABuilder.Cat(SLineBreak);
  if IsCycle then // 在发生死锁时才记录相关日志
  begin
    ADeadFound := True;
    ABuilder.Cat(SDeadLockFound).Cat(SLineBreak);
  end;
  if Count > WCT_MAX_NODE_COUNT then
  begin
    ABuilder.Cat(SpaceChar, 1)
      .Cat(Format(SMoreChainNodes, [Count, WCT_MAX_NODE_COUNT]))
      .Cat(SLineBreak);
    Count := WCT_MAX_NODE_COUNT;
  end;
  I := 0;
  while I < Count do
  begin
    ABuilder.Cat(SpaceChar, 1);
    case NodeInfoArray[I].ObjectType of
      WctThreadType:
        begin
          ABuilder.Cat(SWaitThreadDesc)
            .Cat(NodeInfoArray[I].ThreadObject.ThreadId);
          if NodeInfoArray[I].ObjectStatus = WctStatusBlocked then
            ABuilder.Cat(SThreadBlocked)
          else
            ABuilder.Cat(SThreadRunning);
          if IsCycle then
            ABuilder.Cat(SLineBreak).Cat(SStackList).Cat(SLineBreak)
              .Cat(StackByThreadId(NodeInfoArray[I].ThreadObject.ThreadId));
        end
    else
      begin
        ABuilder.Cat(ObjectTypes[Integer(NodeInfoArray[I].ObjectType) - 1]);
        if NodeInfoArray[I].LockObject.ObjectName[0] <> #0 then
          ABuilder.Cat('-').Cat(NodeInfoArray[I].LockObject.ObjectName);
        if NodeInfoArray[I].ObjectStatus = WctStatusAbandoned then
          ABuilder.Cat(SWaitAbandoned)
        else
          ABuilder.Cat(SWaiting);
      end;
    end;
    ABuilder.Cat(SLineBreak);
    Inc(I);
  end;
end;

class function TDeadlockChecker.EnumWaitChains: QStringW;
var
  ABuilder: TQStringCatHelperW;
  ADeadFound: Boolean;
begin
  if not Assigned(OpenThreadWaitChainSession) then
    Result := SCantCheckWaitChain
  else
  begin
    ABuilder := TQStringCatHelperW.Create;
    try
      if CheckThreads(PrintThreadWaitChain, DeadCheckThreadId, ABuilder,
        ADeadFound) then
        Result := ABuilder.Value
      else
        Result := Format(SGetWaitStateError,
          [GetLastError, SysErrorMessage(GetLastError)]);
    finally
      FreeObject(ABuilder);
    end;
  end;
end;

procedure TDeadlockChecker.Execute;
var
  S: QStringW;
begin
  FComInitialized := InitializeComAccess;
  while not Terminated do
  begin
    if DeadlockExists(S) then
    begin
      SaveTextW(ExtractFilePath(GetModuleName(MainInstance)) +
        'deadlock.log', S);
      AtomicCmpExchange(PPointer(@DeadLocker)^, nil, Pointer(Self));
      Terminate; // 检测到死锁后记录日志就退出
    end
    else
      FEvent.WaitFor(5000);
  end;
  if FComInitialized then
    CoUninitialize;
  AtomicCmpExchange(PPointer(@DeadLocker)^, nil, Pointer(Self));
end;

function TDeadlockChecker.InitializeComAccess: Boolean;
var
  CallStateCallback: PCoGetCallState;
  ActivationStateCallback: PCoGetActivationState;
begin
  CoInitialize(nil);
  CallStateCallback := GetProcAddress(GetModuleHandle('ole32.dll'),
    'CoGetCallState');
  ActivationStateCallback := GetProcAddress(GetModuleHandle('ole32.dll'),
    'CoGetActivationState');
  Result := Assigned(CallStateCallback) and Assigned(ActivationStateCallback);
  if Result then
    RegisterWaitChainCOMCallback(CallStateCallback, ActivationStateCallback);
end;

procedure EnableDeadlockCheck;
begin
  if not Assigned(DeadLocker) then
  begin
    DeadLocker := TDeadlockChecker.Create;
    DeadCheckThreadId := DeadLocker.ThreadId;
  end;
  DeadLocker.Suspended := False;
end;

procedure DisableDeadlockCheck;
var
  ADeadChecker: TDeadlockChecker;
begin
  if Assigned(DeadLocker) then
  begin
    DeadCheckThreadId := 0;
    repeat
      ADeadChecker := DeadLocker;
      AtomicCmpExchange(PPointer(@DeadLocker)^, nil, Pointer(ADeadChecker));
    until DeadLocker = nil;
    if ADeadChecker <> nil then
    begin
      ADeadChecker.Terminate;
      ADeadChecker.FEvent.SetEvent;
      ADeadChecker.Suspended := False;
    end;
  end;
end;

initialization

{$IFDEF MSWINDOWS}
  EnablePrivilege('SeDebugPrivilege', True);
NtQueryInformationThread := GetProcAddress(GetModuleHandle('ntdll.dll'),
  'NtQueryInformationThread');
OpenThreadWaitChainSession := GetProcAddress(GetModuleHandle(Advapi32),
  'OpenThreadWaitChainSession');
CloseThreadWaitChainSession := GetProcAddress(GetModuleHandle(Advapi32),
  'CloseThreadWaitChainSession');
GetThreadWaitChain := GetProcAddress(GetModuleHandle(Advapi32),
  'GetThreadWaitChain');
RegisterWaitChainCOMCallback := GetProcAddress(GetModuleHandle(Advapi32),
  'RegisterWaitChainCOMCallback');
{$ENDIF}
Symbols := TQDebugSymbols.Create;
Symbols.LoadDefault;

finalization

DisableDeadlockCheck;
FreeObject(Symbols);

end.
