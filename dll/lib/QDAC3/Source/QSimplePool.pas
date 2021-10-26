unit QSimplePool;

interface

uses classes, types, sysutils, syncobjs;

{
  更新日志
  2015.8.7
  =========
  * 修改重置的默认行为，只有当做内存池使用时才默认清零（根据阿木反馈修改）
  2015.7.23
  =========
  * 修正了匿名函数版本赋值错误访问无效指针的问题（勇哥报告）
}
type
{$HPPEMIT '#pragma link "qsimplepool"'}
  TQSimplePool = class;
  TQSimplePoolItemNotify = procedure(ASender: TQSimplePool; AData: Pointer)
    of object;
  TQSimplePoolItemNotifyG = procedure(ASender: TQSimplePool; AData: Pointer);

  TQSimplePoolNewItemEvent = procedure(ASender: TQSimplePool;
    var AData: Pointer) of object;
  TQSimplePoolNewItemG = procedure(ASender: TQSimplePool; var AData: Pointer);

{$IFDEF UNICODE}
  TQSimplePoolItemNotifyA = reference to procedure(ASender: TQSimplePool;
    AData: Pointer);
  TQSimplePoolNewItemEventA = reference to procedure(ASender: TQSimplePool;
    var AData: Pointer);
  PQSimplePoolNewItemEventA = ^TQSimplePoolNewItemEventA;
  PQSimplePoolItemNotifyA = ^TQSimplePoolItemNotifyA;
{$ENDIF}

  TQSimplePool = class
  private
    FOnFree: TQSimplePoolItemNotify;
    FOnNewItem: TQSimplePoolNewItemEvent;
    FOnReset: TQSimplePoolItemNotify;
    FBeforePush: TQSimplePoolItemNotify;
    FAfterPop: TQSimplePoolItemNotify;
    procedure SetSize(const Value: Integer);
  protected
    FPool: array of Pointer;
    FCount: Integer;
    FSize: Integer;
    FDataSize: Integer;
    FInDestroy: Boolean;
    FLocker: TCriticalSection;
    procedure DoFree(AData: Pointer); // inline;
    procedure DoReset(AData: Pointer); // inline;
    procedure DoNew(var AData: Pointer); // inline;
  public
    constructor Create(AMaxSize, ADataSize: Integer); overload;
{$IFDEF UNICODE}
    constructor Create(AMaxSize: Integer; AOnNew: TQSimplePoolNewItemEventA;
      AOnFree, AOnReset: TQSimplePoolItemNotifyA); overload;
    constructor Create(AMaxSize: Integer;
      AOnNew: TQSimplePoolNewItemEventA); overload;
{$ENDIF}
    destructor Destroy; override;
    procedure Push(p: Pointer);
    function Pop: Pointer;
    property Count: Integer read FCount;
    property Size: Integer read FSize write SetSize;
    property OnNewItem: TQSimplePoolNewItemEvent read FOnNewItem
      write FOnNewItem;
    property OnFree: TQSimplePoolItemNotify read FOnFree write FOnFree;
    property OnReset: TQSimplePoolItemNotify read FOnReset write FOnReset;
    property BeforePush: TQSimplePoolItemNotify read FBeforePush
      write FBeforePush;
    property AfterPop: TQSimplePoolItemNotify read FAfterPop write FAfterPop;
  end;

function Pool_MakeNewItemProc(AProc: TQSimplePoolNewItemG)
  : TQSimplePoolNewItemEvent;
function Pool_MakeNotifyProc(AProc: TQSimplePoolItemNotifyG)
  : TQSimplePoolItemNotify;

implementation

function Pool_MakeNewItemProc(AProc: TQSimplePoolNewItemG)
  : TQSimplePoolNewItemEvent;
begin
  TMethod(Result).Code := @AProc;
  TMethod(Result).Data := nil;
end;

function Pool_MakeNotifyProc(AProc: TQSimplePoolItemNotifyG)
  : TQSimplePoolItemNotify;
begin
  TMethod(Result).Code := @AProc;
  TMethod(Result).Data := nil;
end;
{ TQSimplePool }

constructor TQSimplePool.Create(AMaxSize, ADataSize: Integer);
begin
  inherited Create;
  FSize := AMaxSize;
  FDataSize := ADataSize;
  SetLength(FPool, FSize);
  FLocker := TCriticalSection.Create;
end;
{$IFDEF UNICODE}

constructor TQSimplePool.Create(AMaxSize: Integer;
  AOnNew: TQSimplePoolNewItemEventA;
  AOnFree, AOnReset: TQSimplePoolItemNotifyA);
begin
  Create(AMaxSize, 0);
  if Assigned(AOnNew) then
  begin
    PQSimplePoolNewItemEventA(@TMethod(FOnNewItem).Code)^ := AOnNew;
    TMethod(FOnNewItem).Data := Pointer(-1);
  end;
  if Assigned(AOnFree) then
  begin
    PQSimplePoolItemNotifyA(@TMethod(FOnFree).Code)^ := AOnFree;
    TMethod(FOnFree).Data := Pointer(-1);
  end;
  if Assigned(AOnReset) then
  begin
    PQSimplePoolItemNotifyA(@TMethod(FOnReset).Code)^ := AOnReset;
    TMethod(FOnReset).Data := Pointer(-1);
  end;
end;

constructor TQSimplePool.Create(AMaxSize: Integer;
  AOnNew: TQSimplePoolNewItemEventA);
begin
  Create(AMaxSize, AOnNew, nil, nil);
end;
{$ENDIF}

destructor TQSimplePool.Destroy;
var
  I: Integer;
begin
  FInDestroy := True;
  FLocker.Enter;
  I := 0;
  while I < FCount do
  begin
    DoFree(FPool[I]);
    Inc(I);
  end;
  FreeAndNil(FLocker);
{$IFDEF UNICODE}
  if TMethod(FOnNewItem).Code <> nil then
  begin
    if TMethod(FOnNewItem).Data = Pointer(-1) then
      PQSimplePoolNewItemEventA(@TMethod(FOnNewItem).Code)^ := nil;
  end;
  if TMethod(FOnFree).Code <> nil then
  begin
    if TMethod(FOnFree).Data = Pointer(-1) then
      PQSimplePoolItemNotifyA(@TMethod(FOnFree).Code)^ := nil;
  end;
  if TMethod(FOnReset).Code <> nil then
  begin
    if TMethod(FOnReset).Data = Pointer(-1) then
      PQSimplePoolItemNotifyA(@TMethod(FOnReset).Code)^ := nil;
  end;
{$ENDIF}
  inherited;
end;

procedure TQSimplePool.DoFree(AData: Pointer);
begin
  if TMethod(FOnFree).Code <> nil then
  begin
    if TMethod(FOnFree).Data = nil then
      TQSimplePoolItemNotifyG(TMethod(FOnFree).Code)(Self, AData)
{$IFDEF UNICODE}
    else if TMethod(FOnFree).Data = Pointer(-1) then
      TQSimplePoolItemNotifyA(TMethod(FOnFree).Code)(Self, AData)
{$ENDIF}
    else
      FOnFree(Self, AData);
  end
  else
    FreeMem(AData);
end;

procedure TQSimplePool.DoNew(var AData: Pointer);
begin
  if TMethod(FOnNewItem).Code <> nil then
  begin
    if TMethod(FOnNewItem).Data = nil then
      TQSimplePoolNewItemG(TMethod(FOnNewItem).Code)(Self, AData)
{$IFDEF UNICODE}
    else if TMethod(FOnNewItem).Data = Pointer(-1) then
      TQSimplePoolNewItemEventA(TMethod(FOnNewItem).Code)(Self, AData)
{$ENDIF}
    else
      FOnNewItem(Self, AData)
  end
  else
    GetMem(AData, FDataSize);
end;

procedure TQSimplePool.DoReset(AData: Pointer);
begin
  if TMethod(FOnReset).Code <> nil then
  begin
    if TMethod(FOnReset).Data = nil then
      TQSimplePoolItemNotifyG(TMethod(FOnReset).Code)(Self, AData)
{$IFDEF UNICODE}
    else if TMethod(FOnReset).Data = Pointer(-1) then
      TQSimplePoolItemNotifyA(TMethod(FOnReset).Code)(Self, AData)
{$ENDIF}
    else
      FOnReset(Self, AData);
  end
  else if TMethod(FOnNewItem).Code = nil then
    FillChar(AData^, FDataSize, 0);
end;

function TQSimplePool.Pop: Pointer;
begin
  Result := nil;
  FLocker.Enter;
  if FCount > 0 then
  begin
    Result := FPool[FCount - 1];
    Dec(FCount);
  end;
  FLocker.Leave;
  if Result = nil then
    DoNew(Result);
  if Result <> nil then
  begin
    DoReset(Result);
    if TMethod(FAfterPop).Code<>nil then
      FAfterPop(Self, Result);
  end;
end;

procedure TQSimplePool.Push(p: Pointer);
var
  ADoFree: Boolean;
begin
  if not FInDestroy then
  begin
    if TMethod(FBeforePush).Data<>nil then
      FBeforePush(Self, p);
    FLocker.Enter;
    ADoFree := (FCount = FSize);
    if not ADoFree then
    begin
      FPool[FCount] := p;
      Inc(FCount);
    end;
    FLocker.Leave;
    if ADoFree then
      DoFree(p);
  end
  else
    DoFree(p);
end;

procedure TQSimplePool.SetSize(const Value: Integer);
var
  AToFree: array of Pointer;
  I: Integer;
begin
  if (FSize <> Value) and (Value > 0) then
  begin
    FLocker.Enter;
    try
      if FCount > Value then
      begin
        SetLength(AToFree, FCount - Value);
        Move(FPool[Value], AToFree[0], (FCount - Value) * SizeOf(Pointer));
      end;
      FSize := Value;
      SetLength(FPool, Value);
    finally
      FLocker.Leave;
      for I := 0 to High(AToFree) do
        DoFree(AToFree[I]);
    end;
  end;
end;

end.
