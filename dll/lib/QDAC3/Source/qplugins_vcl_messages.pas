unit qplugins_vcl_messages;

{ Delphi VCL 消息处理单元，用于处理插件和宿主程序之间的消息同步和派发
  使用方法：
  1、在宿主程序中引用或加入此单元；
  2、在插件DLL中引用或加入此单元
  然后就没有了。

  变更说明
  2016.3.30
  =========
  * 不再劫持消息循环，改为劫持宿主的 Application.OnMessage 和 Application.OnIdle 事件

  2015.7.29
  =========
  * 修正了在进入被截持的消息循环前，显示模态窗口，引起循环嵌套造成程序无法正常结束的问题（勇哥报告）
}
interface

uses classes, sysutils, syncobjs, qstring, qplugins,qplugins_base,
  qplugins_params, qplugins_messages, qdac_postqueue, windows, messages,
  controls, forms;
{$HPPEMIT '#pragma link "qplugins_vcl_messages"'}
// 判断宿主程序是否是VCL程序
function HostIsVCL: Boolean;

implementation

resourcestring
  SMsgFilterRootMissed = '请求的服务路径 /Services/Messages 未注册';

type
  // 消息处理服务，用于将消息派发到特定的插件中

  TQMessageService = class(TQService, IQMessageService, IQNotify)
  private
  public
    procedure Notify(const AId: Cardinal; AParams: IQParams;
      var AFireNext: Boolean); stdcall;
    function Accept(AInstance: HMODULE): Boolean; virtual; stdcall;
    procedure HandleMessage(var AMsg: TMsg; var AHandled: Boolean); stdcall;
    procedure HandleIdle; virtual; stdcall;
    function IsShowModal: Boolean; stdcall;
  end;

  TQMsgFilters = class(TQMessageService, IQHostService, IQNotify,
    IQMessageService)
  protected
    FMsgLoopOwner: Boolean;
    FTerminating: Boolean;
    FLastModalEnd: TNotifyEvent;
    function IsFilterShowModal: Boolean;
    procedure DoAppMessage(var AMsg: TMsg; var AHandled: Boolean);
    procedure DoAppIdle(Sender: TObject; var Done: Boolean);
    procedure HandleIdle; override; stdcall;
    function Accept(AInstance: HMODULE): Boolean; override; stdcall;
    function Terminating: Boolean;
    function Terminated: Boolean;
    function IsShareForm(AFormClass:Pointer): Boolean;
  public
    constructor Create; override;
    destructor Destroy; override;
    function GetAppWnd: HWND;
  end;

var
  MsgFilters: IQService;
  _MsgFilter: IQMessageService;
  NID_APPREADY: Cardinal;
  { TQMessageService }

function TQMessageService.Accept(AInstance: HMODULE): Boolean;
begin
  Result := AInstance = HInstance;
end;

procedure TQMessageService.HandleIdle;
var
  ADone: Boolean;
begin
  // 触发下DLL中的Application.OnIdle
  if Assigned(Application.OnIdle) then //
    Application.OnIdle(Application, ADone);
  CheckSynchronize;
end;

type
  TAppHack = class(TApplication)

  end;

procedure TQMessageService.HandleMessage(var AMsg: TMsg; var AHandled: Boolean);
var
  AIsUnicode: Boolean;
begin
  AIsUnicode := (AMsg.HWND = 0) or IsWindowUnicode(AMsg.HWND);
  if not TAppHack(Application).IsPreProcessMessage(AMsg) and
    not TAppHack(Application).IsHintMsg(AMsg) and not TAppHack(Application)
    .IsMDIMsg(AMsg) and not TAppHack(Application).IsKeyMsg(AMsg) and
    not TAppHack(Application).IsDlgMsg(AMsg) then
  begin
    TranslateMessage(AMsg);
    if AIsUnicode then
      DispatchMessageW(AMsg)
    else
      DispatchMessageA(AMsg);
  end;
end;

function TQMessageService.IsShowModal: Boolean;
begin
  Result := Application.ModalLevel > 0;
end;

function FindAppHandle: HWND;
var
  AService: IQHostService;
begin
  // 如果主程序使用 IQHostService，则使用该服务，如果未使用，则返回0
  // 如果要在子程序使用窗体服务，则主程序必需实现 IQHostService
  if Supports(PluginsManager, IQHostService, AService) then
  begin
    Result := AService.GetAppWnd;
    if MainInstance = 0 then
      MainInstance := (AService as IQService).GetOwnerInstance;
  end
  else
    Result := 0;
end;

procedure TQMessageService.Notify(const AId: Cardinal; AParams: IQParams;
  var AFireNext: Boolean);
begin
  if AId = NID_APPREADY then
    Application.Handle := FindAppHandle;
end;

function FilterRoot: IQServices;
var
  AMgr: IQNotifyManager;
begin
  Result := PluginsManager.Services.ByPath('Messages') as IQServices;
  if not Assigned(Result) then
  begin
    Result := TQServices.Create(NewId, 'Messages');
    PluginsManager.Services.Add(Result as IQService);
    AMgr := (PluginsManager as IQNotifyManager);
    AMgr.Send(AMgr.IdByName(NAME_APPREADY), NIL);
  end;
end;

//// 查找 TForm 声明所在的模块地址，如果找不到，返回0
//function FormInstance: HMODULE;
//type
//  TTestMethod = procedure of object;
//
//  TJmpInst = packed record
//    Inst: Word;
//    Offset: IntPtr;
//  end;
//
//  PJmpInst = ^TJmpInst;
//var
//  AMethod: TTestMethod;
//  Alias: TMethod absolute AMethod;
//  AJump: PJmpInst;
//  AForm: TForm;
//  AContext: CONTEXT;
//  ATargetAddr: IntPtr;
//  AClass:TFormClass;
//begin
//  AForm := TForm.Create(nil);
//  try
//    AMethod := AForm.Cascade;
//    AJump := PJmpInst(Alias.Code);
//    if AJump.Inst = $25FF then // JMP Offset
//    begin
//      ATargetAddr:=HInstance;
//      if AJump.Offset<0 then
//        Dec(ATargetAddr,AJump.Offset and $FFFFFFFF)
//      else
//        Inc(ATargetAddr,AJump.Offset and $FFFFFFFF);
//      Result:=FindHInstance(PPointer(ATargetAddr)^);
//    end
//    else // 不认识
//  finally
//    FreeAndNil(AForm);
//  end;
//end;

function IsSharePackage: Boolean;
var
  AService: IQHostService;
begin
  // 如果主程序使用 IQHostService，则使用该服务，如果未使用，则返回0
  // 如果要在子程序使用窗体服务，则主程序必需实现 IQHostService
  if Supports(PluginsManager, IQHostService, AService) then
  begin
    Result := AService.IsShareForm(TFormClass.ClassInfo);
  end
  else
    Result := False;
end;

procedure RegisterMessageService;
var
  AppHandle: HWND;
  ANotifyMgr: IQNotifyManager;

begin
  if not IsSharePackage then
  begin
    AppHandle := FindAppHandle;
    _MsgFilter := TQMessageService.Create(NewId, 'MessageFilter.VCL');
    RegisterServices('Services/Messages',
      [InstanceOf(_MsgFilter) as TQService]);
    if AppHandle <> 0 then
    begin
      Application.Handle := AppHandle;
    end
    else
    begin
      ANotifyMgr := (PluginsManager as IQNotifyManager);
      NID_APPREADY := ANotifyMgr.IdByName(NAME_APPREADY);
      ANotifyMgr.Subscribe(NID_APPREADY, _MsgFilter as IQNotify);
    end;
  end
  else
    _MsgFilter := nil;
end;

procedure UnregisterMessageService;
var
  AMgr: IQNotifyManager;
  ASvc: IQService;
begin
  if Assigned(_MsgFilter) then
  begin
    if Supports(PluginsManager, IQNotifyManager, AMgr) then
      AMgr.Unsubscribe(NID_APPREADY, _MsgFilter as IQNotify);
    ASvc := (_MsgFilter as IQService);
    ASvc.Parent.Remove(ASvc);
    _MsgFilter := nil;
  end;
end;

{ TQMsgFilters }

function TQMsgFilters.Accept(AInstance: HMODULE): Boolean;
var
  AppHinst: HMODULE;
begin
  AppHinst := GetClassLong(Application.Handle, GCL_HMODULE);
  Result := (AInstance = HInstance) or (AppHinst = AInstance);
end;

constructor TQMsgFilters.Create;
type
  TNoParamProc = procedure of object;
var
  AProc: TNoParamProc;
begin
  inherited Create(NewId, 'MessageHost.VCL');
  Application.OnMessage := DoAppMessage;
  Application.OnIdle := DoAppIdle;
  if IsLibrary then
    Application.Handle := FindAppHandle;
  AProc := Application.Initialize;
end;

destructor TQMsgFilters.Destroy;
begin
  FTerminating := True;
  WakeMainThread(Self);
  inherited;
end;

procedure TQMsgFilters.DoAppIdle(Sender: TObject; var Done: Boolean);
var
  AService: IQService;
  AFilters: IQServices;
  AFilter: IQMessageService;
  I: Integer;
begin
  Done := True;
  AFilters := FilterRoot;
  begin
    for I := 0 to AFilters.Count - 1 do
    begin
      AService := AFilters[I];
      if not AService.IsInModule(HInstance) then
      begin
        AFilter := AService as IQMessageService;
        AFilter.HandleIdle;
      end;
    end;
  end;
end;

procedure TQMsgFilters.DoAppMessage(var AMsg: TMsg; var AHandled: Boolean);
var
  AWndInstance: HMODULE;
  AFilters: IQServices;
  I: Integer;
  function DoProcess(AIndex: Integer): Boolean;
  var
    AFilter: IQMessageService;
    AService: IQService;
  begin
    AService := AFilters[I];
    Result := False;
    if AService.GetOwnerInstance <> HInstance then
    begin
      AFilter := AService as IQMessageService;
      if AFilter.Accept(AWndInstance) then
      begin
        Result := True;
        AFilter.HandleMessage(AMsg, AHandled);
      end;
    end;
  end;

begin
  AFilters := FilterRoot;
  AWndInstance := GetClassLong(AMsg.HWND, GCL_HMODULE);
  if AWndInstance <> MainInstance then
  begin
    for I := 0 to AFilters.Count - 1 do
    begin
      if DoProcess(I) then
      begin
        AHandled := True;
        break;
      end;
    end;
  end;
  ProcessAsynCalls;
end;

function TQMsgFilters.GetAppWnd: HWND;
begin
  Result := Application.Handle;
end;

procedure TQMsgFilters.HandleIdle;
begin
  CheckSynchronize;
end;

function TQMsgFilters.IsFilterShowModal: Boolean;
var
  AFilters: IQServices;
  AFilter: IQMessageService;
  I: Integer;
begin
  AFilters := FilterRoot;
  Result := False;
  for I := 0 to AFilters.Count - 1 do
  begin
    AFilter := AFilters[I] as IQMessageService;
    Result := AFilter.IsShowModal;
    if Result then
      break;
  end;
end;

function TQMsgFilters.IsShareForm(AFormClass:Pointer): Boolean;
begin
  Result := AFormClass=TFormClass.ClassInfo;
end;

function TQMsgFilters.Terminated: Boolean;
begin
  Result := Application.Terminated;
end;

function TQMsgFilters.Terminating: Boolean;
begin
  Result := Application.Terminated;
end;

function HostIsVCL: Boolean;
var
  AppWnd: HWND;
  AClassName: array [0 .. 255] of WideChar;
begin
  AppWnd := FindAppHandle;
  windows.GetClassNameW(AppWnd, AClassName, 255);
  Result := StrCmpW(@AClassName[0], VCLAppClass, True) = 0;
end;

initialization

if HInstance <> MainInstance then
begin
  MsgFilters := nil;
  RegisterMessageService;
end
else
begin
  FilterRoot;
  MsgFilters := TQMsgFilters.Create;
  RegisterServices('Services/Messages', [MsgFilters]);
end;

finalization

if HInstance <> MainInstance then
  UnregisterMessageService
else
begin
  UnregisterServices('Services/Messages', [MsgFilters.Name]);
  MsgFilters := nil;
end;

end.
