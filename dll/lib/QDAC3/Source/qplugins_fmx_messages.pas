unit qplugins_fmx_messages;

interface

{$HPPEMIT '#pragma link "qplugins_vcl_messages"'}
// 判断宿主程序是否是VCL程序
function HostIsVCL: Boolean;

const
  IID_FMX_MESSAGEHOST: TGuid = '{06132435-6E52-44C7-9128-AF14BA92B5CB}';

implementation

uses classes, sysutils, syncobjs, qstring, qplugins, qplugins_base,
  qplugins_params, qplugins_messages, qdac_postqueue, system.messaging,
  fmx.types, fmx.platform, fmx.controls, fmx.forms, fmx.canvas.d2d
{$IFDEF MSWINDOWS}, fmx.platform.Win, windows, messages{$ENDIF};

resourcestring
  SMsgFilterRootMissed = '请求的服务路径 /Services/Messages 未注册';

type
  TQFMXMessageService = class(TQService, IQMessageService, IQNotify,
    IFMXApplicationService)
  private
    FAppReadyId: Cardinal;
    FTerminating: Boolean;
    FOldAppService: IFMXApplicationService;
    function HostService: IQHostService;
  public
    constructor Create(const AId: TGuid; AName: QStringW); override;
    procedure Notify(const AId: Cardinal; AParams: IQParams;
      var AFireNext: Boolean); stdcall;
    function Accept(AInstance: HMODULE): Boolean; virtual; stdcall;
    procedure HandleMessage(var AMsg: TMsg; var AHandled: Boolean);
      overload; stdcall;
    procedure HandleIdle; virtual; stdcall;
    function IsShowModal: Boolean; stdcall;
    procedure Run;
    function Running: Boolean;
    function HandleMessage: Boolean; overload;
    procedure WaitMessage;
    function GetDefaultTitle: string;
    function GetTitle: string;
    procedure SetTitle(const Value: string);
    /// <summary>Gets a string representing the version number of the application</summary>
    function GetVersionString: string;
    procedure Terminate;
    function Terminating: Boolean;
    procedure RestoreHook;
  end;

  TQHostMessageService = class(TQService, IQHostService, IQNotify,
    IFMXApplicationService)
  protected
    FTerminating: Boolean;
    FRunning: Boolean;
    FOldAppService: IFMXApplicationService;
    function IsFilterShowModal: Boolean;
    procedure Notify(const AId: Cardinal; AParams: IQParams;
      var AFireNext: Boolean); stdcall;
    function IsShareForm(AFormClass: Pointer): Boolean;
  public
    constructor Create; override;
    destructor Destroy; override;
    // IQHostService
    function GetAppWnd: HWND;
    // IFMXApplicationService
    procedure Run;
    function Running: Boolean;
    function HandleMessage: Boolean;
    procedure WaitMessage;
    function GetDefaultTitle: string;
    function GetTitle: string;
    procedure SetTitle(const Value: string);
    /// <summary>Gets a string representing the version number of the application</summary>
    function GetVersionString: string;
    procedure Terminate;
    function Terminating: Boolean;
    function Terminated: Boolean;
  end;

var
  MsgFilters: IQService;
  _MsgFilter: TQFMXMessageService;
  NID_APPREADY: Cardinal;
{$IFDEF MSWINDOWS}

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
{$ENDIF}

function HostIsVCL: Boolean;
{$IFDEF MSWINDOWS}
var
  AppWnd: HWND;
  AClassName: array [0 .. 255] of WideChar;
begin

  AppWnd := FindAppHandle;
  windows.GetClassNameW(AppWnd, AClassName, 255);
  Result := StrCmpW(@AClassName[0], VCLAppClass, True) = 0;
end;
{$ELSE}

// 移动平台宿主不可能是VCL
begin
  Result := false;
end;
{$ENDIF}

function QueryAppState: TApplicationState;
var
  AHostService: IQHostService;
begin
  Result := TApplicationState.None;
  if Supports(PluginsManager, IQHostService, AHostService) then
  begin
    if not AHostService.Terminating then
      Result := TApplicationState.Running
    else
      Result := TApplicationState.Terminating;
  end;
end;

procedure ProcessAppMsg(var AMsg: TMsg; var AHandled: Boolean);
var
  AIsUnicode: Boolean;
begin
  AIsUnicode := (AMsg.HWND = 0) or IsWindowUnicode(AMsg.HWND);
  TranslateMessage(AMsg);
  if AIsUnicode then
    DispatchMessageW(AMsg)
  else
    DispatchMessageA(AMsg);
  AHandled := True;
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

function ProcessFMXAppMsg(var AIsQuit: Boolean): Boolean;
var
  AWndInstance: HMODULE;
  AFilters: IQServices;
  AFilter: IQMessageService;
  I: Integer;
  AMsg: TMsg;
  procedure DebugWnd(AWnd: HWND);
  var
    AClassName: array [0 .. 255] of WideChar;
    AText: array [0 .. 255] of WideChar;
    S: String;
  begin
    if AWnd <> 0 then
    begin
      GetClassName(AWnd, @AClassName, 255);
      GetWindowText(AWnd, @AText, 255);
      S := 'Class:' + PChar(@AClassName) + ',Text=' + PChar(@AText);
      OutputDebugString(PChar(S));
    end;
  end;

begin
  Result := false;
  AIsQuit := false;
  if PeekMessage(AMsg, 0, 0, 0, PM_REMOVE) then
  begin
    if AMsg.message = WM_QUIT then
    begin
      Result := True;
      AIsQuit := True;
      Exit;
    end
    else
    begin
      AFilters := FilterRoot;
      if AMsg.HWND = 0 then
        AWndInstance := MainInstance
      else
        AWndInstance := GetClassLong(AMsg.HWND, GCL_HMODULE);
      if AWndInstance <> HInstance then
      begin
        // DebugWnd(AMsg.HWND);
        for I := 0 to AFilters.Count - 1 do
        begin
          AFilter := AFilters[I] as IQMessageService;
          if AFilter.Accept(AWndInstance) then
          begin
            Result := True;
            AFilter.HandleMessage(AMsg, Result);
            if Result then
              Break;
          end;
        end;
      end;
    end;
    if not Result then
      ProcessAppMsg(AMsg, Result);
    ProcessAsynCalls;
  end;
end;

function IsFMXModalShowing: Boolean;
var
  AForm: TCommonCustomForm;
begin
  AForm := Screen.ActiveForm;
  if Assigned(AForm) then
    Result := TFmxFormState.Modal in AForm.FormState
  else
    Result := false;
end;

function FormInstance: HMODULE;
type
  TTestMethod = procedure of object;

  TJmpInst = packed record
    Inst: Word;
    Offset: PPointer;
  end;

  PJmpInst = ^TJmpInst;
var
  AMethod: TTestMethod;
  AJump: PJmpInst;
  AForm: TFormFactor;
begin
  AForm := TFormFactor.Create;
  try
    AMethod := AForm.AdjustToScreenSize;
    AJump := PJmpInst(TMethod(AMethod).Code);
    if AJump.Inst = $25FF then
      Result := FindHInstance(AJump.Offset^)
    else // 不是跳转，则说明是自己
      Result := HInstance;
  finally
    FreeAndNil(AForm);
  end;
end;

function IsSharePackage: Boolean;
var
  AService: IQHostService;
begin
  // 如果主程序使用 IQHostService，则使用该服务，如果未使用，则返回0
  // 如果要在子程序使用窗体服务，则主程序必需实现 IQHostService
  if Supports(PluginsManager, IQHostService, AService) then
  begin
    Result := AService.IsShareForm(TForm);
  end
  else
    Result := false;
end;

{ TQFMXMessageService }

function TQFMXMessageService.Accept(AInstance: HMODULE): Boolean;
begin
  Result := AInstance = HInstance;
end;

constructor TQFMXMessageService.Create(const AId: TGuid; AName: QStringW);
begin
  inherited Create(AId, AName);
  RegisterApplicationHWNDProc(FindAppHandle);
  FOldAppService := TPlatformServices.Current.GetPlatformService
    (IFMXApplicationService) as IFMXApplicationService;
  TPlatformServices.Current.RemovePlatformService(IFMXApplicationService);
  TPlatformServices.Current.AddPlatformService(IFMXApplicationService, Self);
  Application.ApplicationStateQuery := QueryAppState;
end;

function TQFMXMessageService.GetDefaultTitle: string;
begin
  Result := FOldAppService.DefaultTitle;
end;

function TQFMXMessageService.GetTitle: string;
{$IFDEF MSWINDOWS}
var
  AHandle: HWND;
  AHostSvc: IQHostService;
{$ENDIF}
begin
  if HInstance = MainInstance then
    Result := FOldAppService.Title
  else
  begin
{$IFDEF MSWINDOWS}
    AHostSvc := HostService;
    if Assigned(AHostSvc) then
    begin
      AHandle := AHostSvc.GetAppWnd;
      SetLength(Result, GetWindowTextLength(AHandle));
      if Length(Result) > 0 then
        GetWindowText(AHandle, PChar(Result), Length(Result));
    end
    else
      SetLength(Result, 0);
{$ENDIF}
  end;
end;

function TQFMXMessageService.GetVersionString: string;
begin
  Result := FOldAppService.AppVersion;
end;

procedure TQFMXMessageService.HandleIdle;
begin
  TMessageManager.DefaultManager.SendMessage(Self, TIdleMessage.Create);
end;

function TQFMXMessageService.HandleMessage: Boolean;
begin
  Result := ProcessFMXAppMsg(FTerminating);
end;

function TQFMXMessageService.HostService: IQHostService;
var
  ARoot: IQServices;
  I: Integer;
begin
  if not Supports(Self, IQHostService, Result) then
  begin
    ARoot := FilterRoot;
    for I := 0 to ARoot.Count - 1 do
    begin
      if Supports(ARoot[I], IQHostService, Result) then
        Exit;
    end;
  end;
end;

procedure TQFMXMessageService.HandleMessage(var AMsg: TMsg;
  var AHandled: Boolean);
begin
  ProcessAppMsg(AMsg, AHandled);
  FTerminating := AMsg.message = WM_QUIT;
end;

function TQFMXMessageService.IsShowModal: Boolean;
begin
  Result := IsFMXModalShowing;
end;

procedure TQFMXMessageService.Notify(const AId: Cardinal; AParams: IQParams;
  var AFireNext: Boolean);
begin
  if AId = FAppReadyId then
    RegisterApplicationHWNDProc(FindAppHandle);
end;

procedure TQFMXMessageService.RestoreHook;
begin
  Terminate;
  TPlatformServices.Current.RemovePlatformService(IFMXApplicationService);
  TPlatformServices.Current.AddPlatformService(IFMXApplicationService,
    FOldAppService);
  RegisterApplicationHWNDProc(nil);
end;

procedure TQFMXMessageService.Run;
begin
  FOldAppService.Run;
end;

function TQFMXMessageService.Running: Boolean;
begin
  Result := FOldAppService.Running;
end;

procedure TQFMXMessageService.SetTitle(const Value: string);
var
  AHostSvc: IQHostService;
begin
  if MainInstance = HInstance then
    FOldAppService.Title := Value
  else
  begin
    AHostSvc := HostService;
    if Assigned(AHostSvc) then
      SetWindowText(AHostSvc.GetAppWnd, Value);
  end;
end;

procedure TQFMXMessageService.Terminate;
begin
  FOldAppService.Terminate;
end;

function TQFMXMessageService.Terminating: Boolean;
begin
  Result := FTerminating or FOldAppService.Terminating;
end;

procedure TQFMXMessageService.WaitMessage;
begin
  FOldAppService.WaitMessage;
end;

{ TQHostMessageService }

constructor TQHostMessageService.Create;
begin
  inherited Create(IID_FMX_MESSAGEHOST, 'MessageHost.FMX');
  FOldAppService := TPlatformServices.Current.GetPlatformService
    (IFMXApplicationService) as IFMXApplicationService;
  TPlatformServices.Current.RemovePlatformService(IFMXApplicationService);
  TPlatformServices.Current.AddPlatformService(IFMXApplicationService, Self);
end;

destructor TQHostMessageService.Destroy;
begin

  inherited;
end;

function TQHostMessageService.GetAppWnd: HWND;
begin
  Result := ApplicationHWND;
end;

function TQHostMessageService.GetDefaultTitle: string;
begin
  Result := FOldAppService.DefaultTitle;
end;

function TQHostMessageService.GetTitle: string;
begin
  Result := FOldAppService.Title;
end;

function TQHostMessageService.GetVersionString: string;
begin
  Result := FOldAppService.AppVersion;
end;

function TQHostMessageService.HandleMessage: Boolean;
begin
  Result := ProcessFMXAppMsg(FTerminating);
end;

function TQHostMessageService.IsFilterShowModal: Boolean;
var
  AFilters: IQServices;
  AFilter: IQMessageService;
  I: Integer;
begin
  AFilters := FilterRoot;
  Result := false;
  for I := 0 to AFilters.Count - 1 do
  begin
    AFilter := AFilters[I] as IQMessageService;
    Result := AFilter.IsShowModal;
    if Result then
      Break;
  end;
end;

function TQHostMessageService.IsShareForm(AFormClass: Pointer): Boolean;
  function FormInstance: HMODULE;
  type
    TTestMethod = procedure of object;

    TJmpInst = packed record
      Inst: Word;
      Offset: PPointer;
    end;

    PJmpInst = ^TJmpInst;
  var
    AMethod: TTestMethod;
    AJump: PJmpInst;
    AForm: TFormFactor;
  begin
    AForm := TFormFactor.Create;
    try
      AMethod := AForm.AdjustToScreenSize;
      AJump := PJmpInst(TMethod(AMethod).Code);
      if AJump.Inst = $25FF then
        Result := FindHInstance(AJump.Offset^)
      else // 不是跳转，则说明是自己
        Result := HInstance;
    finally
      FreeAndNil(AForm);
    end;
  end;

begin
  Result := true; // FormInstance = AFormClassInstance;
end;

procedure TQHostMessageService.Notify(const AId: Cardinal; AParams: IQParams;
  var AFireNext: Boolean);
begin
  // Do Nothing
end;

procedure TQHostMessageService.Run;
begin
  FOldAppService.Run;
end;

function TQHostMessageService.Running: Boolean;
begin
  Result := FOldAppService.Running;
end;

procedure TQHostMessageService.SetTitle(const Value: string);
begin
  FOldAppService.Title := Value;
end;

procedure TQHostMessageService.Terminate;
begin
  FTerminating := True;
  FOldAppService.Terminate;
end;

function TQHostMessageService.Terminated: Boolean;
begin
  Result := Application.Terminated;
end;

function TQHostMessageService.Terminating: Boolean;
begin
  Result := FTerminating or FOldAppService.Terminating;
end;

procedure TQHostMessageService.WaitMessage;
begin
  FOldAppService.WaitMessage;
end;

function EnumFMXAppWnd(AWnd: HWND; AParam: LParam): Boolean; stdcall;
var
  AClassName: array [0 .. 255] of WideChar;
begin
  Result := True;
  windows.GetClassName(AWnd, @AClassName, 256);
  if StrCmpW(@AClassName, FMXAppClass, True) = 0 then
  begin
    if GetClassLong(AWnd, GWL_HINSTANCE) = HInstance then
    begin
      PNativeUInt(AParam)^ := AWnd;
      Result := false;
    end;
  end;
end;

procedure HideFMXAppWindow;
var
  FmxAppWnd: HWND;
begin
  FmxAppWnd := 0;
  EnumThreadWindows(GetCurrentThreadId, @EnumFMXAppWnd, LParam(@FmxAppWnd));
  if (FmxAppWnd <> 0) and (windows.IsWindowVisible(FmxAppWnd)) then
    ShowWindow(FmxAppWnd, SW_HIDE);
end;

procedure RegisterMessageService;
var
  AppHandle: HWND;
  ANotifyMgr: IQNotifyManager;
begin
  if not IsSharePackage then
  begin
    AppHandle := FindAppHandle;
    _MsgFilter := TQFMXMessageService.Create(NewId, 'MessageFilter.FMX');
    RegisterServices('Services/Messages', [_MsgFilter]);
    if AppHandle <> 0 then
    begin
      if HostIsVCL or IsLibrary then
        HideFMXAppWindow;
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
begin
  if Assigned(_MsgFilter) then
  begin
    (PluginsManager as IQNotifyManager).Unsubscribe(NID_APPREADY,
      _MsgFilter as IQNotify);
    _MsgFilter.RestoreHook;
    _MsgFilter.GetParent.Remove(_MsgFilter as IQService);
    _MsgFilter := nil;
  end;
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
  MsgFilters := TQHostMessageService.Create;
end;

finalization

if HInstance <> MainInstance then
begin
  UnregisterMessageService;
end
else
  MsgFilters := nil;

end.
