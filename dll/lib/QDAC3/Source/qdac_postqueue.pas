unit qdac_postqueue;

interface

uses classes, sysutils, syncobjs, qstring{$IFDEF MSWINDOWS}, windows,
  messages{$ENDIF};

{ 本单元实现的是一个跨平台的异步调用模块，调用时用AsynCall函数，参数为一个接口对象 }
type

  TQAsynProc = procedure(AParams: IInterface) of object;
  TQAsynStdProc = procedure(AParams: IInterface); stdcall;
  TQAsynProcG = procedure(AParams: IInterface);
{$IFDEF UNICODE}
  TQAsynProcA = reference to procedure(AParams: IInterface);
  PQAsynProcA = ^TQAsynProcA;
{$ENDIF}
  PPostItem = ^TPostItem;

  TPostItem = record
    Handler: TQAsynProc;
    Params: IInterface;
    Next: PPostItem;
  end;

  IQPostQueue = interface
    ['{3C7CBAE8-20D8-4F63-A423-723A9B1E5F0A}']
    procedure ProcessQueue;
    procedure Post(ACallback: TQAsynProc; AParams: IInterface); overload;
    procedure Post(ACallback: TQAsynProcG; AParams: IInterface); overload;
    procedure Post(ACallback: TQAsynStdProc; AParams: IInterface); overload;
{$IFDEF UNICODE}
    procedure Post(ACallback: TQAsynProcA; AParams: IInterface); overload;
{$ENDIF}
  end;

  TQPostQueue = class(TInterfacedObject, IQPostQueue)
  protected
    FFirst, FLast: PPostItem;
    FLocker: TCriticalSection;
{$IFDEF MSWINDOWS}
    FAsynWnd: HWND;
    procedure AsynWndProc(var AMsg: TMessage);
{$ELSE}
    FAsynThread: TThread;
{$ENDIF}
    procedure ProcessQueue;
    function ProcessItem: Boolean;
    procedure Wakeup;
  public
    constructor Create; overload;
    destructor Destroy; override;
    procedure Post(ACallback: TQAsynProc; AParams: IInterface); overload;
    procedure Post(ACallback: TQAsynProcG; AParams: IInterface); overload;
    procedure Post(ACallback: TQAsynStdProc; AParams: IInterface); overload;
{$IFDEF UNICODE}
    procedure Post(ACallback: TQAsynProcA; AParams: IInterface); overload;
{$ENDIF}
  end;

procedure AsynCall(ACallback: TQAsynProc; AParams: IInterface); overload;
procedure AsynCall(ACallback: TQAsynProcG; AParams: IInterface); overload;
procedure AsynCall(ACallback: TQAsynStdProc; AParams: IInterface); overload;
{$IFDEF UNICODE}
procedure AsynCall(ACallback: TQAsynProcA; AParams: IInterface); overload;
{$ENDIF}
procedure ProcessAsynCalls;

implementation

type
  TQPostThread = class(TThread)
  protected
    FEvent: TEvent;
    FQueue: TQPostQueue;
    procedure Execute; override;
    procedure ProcessQueues;
  public
    constructor Create(AOwner: TQPostQueue);
  end;

var
  _PostQueue: IQPostQueue;

  { TQPostQueue }
{$IFDEF MSWINDOWS}

procedure TQPostQueue.AsynWndProc(var AMsg: TMessage);
begin
  if AMsg.Msg = WM_APP then
    ProcessQueue
  else
    AMsg.Result := DefWindowProc(FAsynWnd, AMsg.Msg, AMsg.WParam, AMsg.LParam);
end;
{$ENDIF}

constructor TQPostQueue.Create;
begin
  inherited;
  FLocker := TCriticalSection.Create;
{$IFDEF MSWINDOWS}
  FAsynWnd := AllocateHWnd(AsynWndProc);
{$ENDIF}
end;

destructor TQPostQueue.Destroy;
begin
  ProcessQueue;
{$IFDEF MSWINDOWS}
  DeallocateHWnd(FAsynWnd);
{$ELSE}
  if Assigned(FAsynThread) then
  begin
    FAsynThread.Terminate;
    with TQPostThread(FAsynThread) do
    begin
      FQueue := nil;
      FEvent.SetEvent;
    end;
    FAsynThread := nil;
  end;
{$ENDIF}
  FreeAndNil(FLocker);
  inherited;
end;

procedure TQPostQueue.Post(ACallback: TQAsynProc; AParams: IInterface);
var
  AItem: PPostItem;
begin
  New(AItem);
  AItem.Handler := ACallback;
  AItem.Params := AParams;
  AItem.Next := nil;
  FLocker.Enter;
  if Assigned(FLast) then
    FLast.Next := AItem
  else
    FFirst := AItem;
  FLast := AItem;
  FLocker.Leave;
  Wakeup;
end;

procedure TQPostQueue.Post(ACallback: TQAsynProcG; AParams: IInterface);
var
  ATemp: TQAsynProc;
begin
  TMethod(ATemp).Data := nil;
  TQAsynProcG(TMethod(ATemp).Code) := ACallback;
  Post(ATemp, AParams);
end;
{$IFDEF UNICODE}

procedure TQPostQueue.Post(ACallback: TQAsynProcA; AParams: IInterface);
var
  ATemp: TQAsynProc;
begin
  TMethod(ATemp).Data := Pointer(-1);
  TMethod(ATemp).Code := nil;
  PQAsynProcA(@TMethod(ATemp).Code)^ := ACallback;
  Post(ATemp, AParams);
end;

{$ENDIF}

procedure TQPostQueue.Post(ACallback: TQAsynStdProc; AParams: IInterface);
var
  ATemp: TQAsynProc;
begin
  TMethod(ATemp).Data := Pointer(-2);
  TQAsynStdProc(TMethod(ATemp).Code) := ACallback;
  Post(ATemp, AParams);
end;

function TQPostQueue.ProcessItem: Boolean;
var
  AItem: PPostItem;
begin
  if Assigned(FFirst) then
  begin
    FLocker.Enter;
    AItem := FFirst;
    if Assigned(AItem) then
      FFirst := FFirst.Next;
    if AItem = FLast then
      FLast := nil;
    FLocker.Leave;
    if Assigned(AItem) then
    begin
      try
        if TMethod(AItem.Handler).Data = nil then
          TQAsynProcG(TMethod(AItem.Handler).Code)(AItem.Params)
        else if TMethod(AItem.Handler).Data = Pointer(-1) then
          TQAsynStdProc(TMethod(AItem.Handler).Code)(AItem.Params)
{$IFDEF UNICODE}
        else if TMethod(AItem.Handler).Data = Pointer(-1) then
        begin
          TQAsynProcA(TMethod(AItem.Handler).Code)(AItem.Params);
          TQAsynProcA(TMethod(AItem.Handler).Code) := nil;
        end
{$ENDIF}
        else
          AItem.Handler(AItem.Params);
      except
      end;
      Dispose(AItem);
      Result := True;
    end
    else
      Result := False;
  end
  else
    Result := False;
end;

procedure TQPostQueue.ProcessQueue;
begin
{$IFDEF MSWINDOWS}
  if ProcessItem then
  begin
    PostMessage(FAsynWnd, WM_APP, 0, 0);
  end;
{$ELSE}
  while ProcessItem do;
{$ENDIF}
end;

procedure TQPostQueue.Wakeup;
{$IFDEF MSWINDOWS}
  procedure WakeupMessage;
  begin
    PostMessage(FAsynWnd, WM_APP, 0, 0);
  end;
{$ELSE}
  procedure WakeupThread;
  var
    AThread: TQPostThread;
  begin
    if not Assigned(FAsynThread) then
    begin
      AThread := TQPostThread.Create(Self);
      if AtomicCmpExchange(Pointer(FAsynThread), Pointer(AThread), nil) <> nil
      then
        FreeAndNil(AThread);
    end;
    TQPostThread(FAsynThread).FEvent.SetEvent;
  end;
{$ENDIF}

begin
{$IFDEF MSWINDOWS}
  WakeupMessage;
{$ELSE}
  WakeupThread;
{$ENDIF}
end;

function AsynQueue: IQPostQueue; inline;
begin
  if _PostQueue = nil then
  begin
    Result := TQPostQueue.Create;
    if AtomicCmpExchange(Pointer(_PostQueue), Pointer(Result), nil) <> nil then
      Result := nil
    else // 由于直接交换指针没有增加引用计数，所以手动增加下
      _PostQueue._AddRef;
  end;
  Result := _PostQueue;
end;

{ TQPostThread }

constructor TQPostThread.Create(AOwner: TQPostQueue);
begin
  FQueue := AOwner;
  FEvent := TEvent.Create;
  inherited Create(False);
  FreeOnTerminate := True;
end;

procedure TQPostThread.Execute;
begin
  while not Terminated do
  begin
    Synchronize(ProcessQueues);
    FEvent.WaitFor(INFINITE);
  end;
  FreeAndNil(FEvent);
end;

procedure TQPostThread.ProcessQueues;
begin
  if Assigned(FQueue) then
    FQueue.ProcessQueue;
end;

procedure AsynCall(ACallback: TQAsynProc; AParams: IInterface);
begin
  AsynQueue.Post(ACallback, AParams);
end;

procedure AsynCall(ACallback: TQAsynProcG; AParams: IInterface);
begin
  AsynQueue.Post(ACallback, AParams);
end;

procedure AsynCall(ACallback: TQAsynStdProc; AParams: IInterface);
begin
  AsynQueue.Post(ACallback, AParams);
end;
{$IFDEF UNICODE}

procedure AsynCall(ACallback: TQAsynProcA; AParams: IInterface);
begin
  AsynQueue.Post(ACallback, AParams);
end;
{$ENDIF}

procedure ProcessAsynCalls;
begin
  AsynQueue.ProcessQueue;
end;

initialization

AsynQueue;

finalization

end.
