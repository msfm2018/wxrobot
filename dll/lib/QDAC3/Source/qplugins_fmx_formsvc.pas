unit qplugins_fmx_formsvc;

interface

/// <summary>
/// IQFormService 的 FMX 版实现单元，仅支持 FMX 程序
/// </summary>
uses classes, qplugins_base,qplugins_formsvc, qstring, fmx.forms,fmx.Styles;

type
  TFormClass = class of TCommonCustomForm;
  /// <summary>
  /// 注册一个IQFormService服务
  /// </summary>
  /// <param name="APath">
  /// 服务注册的父结点，用户可以自定义，推荐/Services/Forms
  /// </param>
  /// <param name="AName">
  /// 服务的名称
  /// </param>
  /// <param name="AClass">
  /// 窗体类型
  /// </param>
  /// <param name="AMultiInstance">
  /// 是否是多实例
  /// </param>
  /// <returns>
  /// 返回注册的服务实例
  /// </returns>
function RegisterFormService(const APath, AName: QStringW; AClass: TFormClass;
  AMultiInstance: Boolean = True): IQFormService; overload;
function RegisterFormService(const AId: TGuid; const APath, AName: QStringW;
  AClass: TFormClass; AMultiInstance: Boolean = True): IQFormService; overload;
/// <summary>
/// 注册一个单实例服务
/// </summary>
/// <param name="APath">
/// 服务注册的父结点，用户可以自定义，推荐/Services/Forms
/// </param>
/// <param name="AName">
/// 服务的名称
/// </param>
/// <param name="AForm">
/// 共享的窗体实例
/// </param>
/// <returns>
/// 返回注册的服务实例
/// </returns>
function RegisterFormService(const APath, AName: QStringW; AForm: TForm)
  : IQFormService; overload;
function RegisterFormService(const AId: TGuid; const APath, AName: QStringW;
  AForm: TForm): IQFormService; overload;
/// <summary>
/// 获取指定的窗体关联的 IQFormService 的服务接口
/// </summary>
/// <param name="AForm">
/// 要获取的窗体实例
/// </param>
/// <returns>
/// 返回获取到的服务接口，如果没有关联，则返回空
/// </returns>
function FindFormService(AForm: TForm): IQFormService;

implementation

uses sysutils, types, fmx.types, uitypes, qplugins_params, qplugins, windows,
  fmx.platform.Win;
// sysutils, uitypes, types, fmx.types,
// fmx.controls, fmx.Platform, fmx.styles, fmx.forms, qstring, qplugins,
// qplugins_params,
// qplugins_fmx_messages, qplugins_formsvc
// {$IFDEF MSWINDOWS}
// , Winapi.windows, Winapi.messages,
// fmx.Platform.Win
// {$ELSE}
// {$MESSAGE Error 'QPlugins FMX 仅支持 Windows 下的程序'}
// {$ENDIF};
{$HPPEMIT '#pragma link "qplugins_fmx_formsvc"'}

const
  FreeNotificationRoot: QStringW = '/Services/Docks/FreeNotifications';
  VCLControlTestRoot: QStringW = '/Services/VCL/ControlTest';
  LocalVCLCtrlTestServiceName: QStringW = 'IsVCLControl';
  SFormNeedFree: PChar = 'QPlugins.VCL.FormService.NeedFree';
  SParentResized: PChar = 'QPlugins.FormService.ParentResized';

type
  TQFormServiceHolder = class(TComponent)
  protected
    FFormService: TQFormService;
  end;

  TQFMXFormService = class(TQFormService)
  private
    FForm: TCommonCustomForm;
    FFormOrigin: TRect;
    FFormClass: TFormClass;
    FEvents: TQFormEvents;
    FFreeService: IQFreeNotifyService;
    FOldCanClose: TCloseQueryEvent;
    FOldOnClose: TCloseEvent;
    FOldOnFree: TNotifyEvent;
    FOldOnActivate: TNotifyEvent;
    FOldOnDeactivate: TNotifyEvent;
    FOldOnResize: TNotifyEvent;
    FOldOnShow: TNotifyEvent;
    FOldOnHide: TNotifyEvent;
    FFormAlign: TFormAlign;
    FIsMultiInstance: Boolean;
    FClosing: Boolean;
    FDockParent: THandle;
    procedure AdjustAlign;
    procedure DoCanClose(ASender: TObject; var ACanClose: Boolean);
    procedure DoClose(ASender: TObject; var Action: TCloseAction);
    procedure DoFree(ASender: TObject);
    procedure DoActivate(ASender: TObject);
    procedure DoDeactivate(ASender: TObject);
    procedure DoResize(ASender: TObject);
    procedure DoShow(ASender: TObject);
    procedure DoHide(ASender: TObject);
    procedure SetForm(const Value: TCommonCustomForm);
    procedure DoDockParentFree(AData: Pointer);
    procedure DoDockParentSizeChanged(AData: Pointer);
    procedure DoFormFree(AData: Pointer);
    function FormNeeded: Boolean; override;
    function GetWidth: Integer; override;
    procedure SetWidth(const AValue: Integer); override;
    function GetHeight: Integer; override;
    procedure SetHeight(const AValue: Integer); override;
    function GetFormAlign: TFormAlign; override;
    procedure SetFormAlign(const AValue: TFormAlign); override;
    procedure ParentResized; override;
    function GetDockParent: THandle; override;
    procedure UnlinkFormEvents;
    function GetOriginHeight: Integer;
    function GetOriginWidth: Integer;
    function GetOriginBottom: Integer;
    function GetOriginLeft: Integer;
    function GetOriginRight: Integer;
    function GetOriginTop: Integer;
    property OriginWidth: Integer read GetOriginWidth;
    property OriginHeight: Integer read GetOriginHeight;
    property OriginLeft: Integer read GetOriginLeft;
    property OriginTop: Integer read GetOriginTop;
    property OriginRight: Integer read GetOriginRight;
    property OriginBottom: Integer read GetOriginBottom;
  public
    constructor Create(AName: QStringW; AForm: TCommonCustomForm;
      ACreator: TObject); overload;
    constructor Create(AName: QStringW; AFormClass: TFormClass;
      AIsMultiInstance: Boolean = True); overload;
    constructor Create(const AId: TGuid; AName: QStringW;
      AForm: TCommonCustomForm; ACreator: TObject); overload;
    constructor Create(const AId: TGuid; AName: QStringW;
      AFormClass: TFormClass; AIsMultiInstance: Boolean = True); overload;
    destructor Destroy; override;
    procedure ShowModal(AOnModalResult: TQFormModalResultHandler;
      ATag: IQParams); override;
    procedure Show; override;
    procedure BringToFront; override;
    function GetInstance: IQService; override; stdcall;
    procedure SendToBack; override;
    procedure SetBounds(L, T, W, H: Integer); override;
    procedure GetBounds(var R: TRect); override;
    procedure DockTo(AHandle: THandle; const ARect: TRect); overload; override;
    procedure DockTo(AHandle: THandle; Align: TFormAlign); overload; override;
    procedure Undock; override;
    procedure SendInput(var AInput: TQInputEvent); override;
    procedure HookEvents(const AEvents: TQFormEvents); override;
    procedure UnhookEvents; override;
    function IsMultiInstance: Boolean; override;
    function GetModalResult: TModalResult; override;
    procedure SetModalResult(const AValue: TModalResult); override;
    function QueryInterface(const IID: TGuid; out Obj): HRESULT;
      override; stdcall;
    property Form: TCommonCustomForm read FForm write SetForm;
    property FormAlign: TFormAlign read GetFormAlign write SetFormAlign;
  end;

  TQControlHook = class
  private
    FControl: TCommonCustomForm;
    FLastResize: TNotifyEvent;
    FRefCount: Integer;
    procedure DoResize(ASender: TObject);
  public
    constructor Create(ACtrl: TCommonCustomForm); overload;
    destructor Destroy; override;
  end;

  PQFormNotifyItem = ^TQFormNotifyItem;

  TQFormNotifyItem = record
    OnNotify: TQFormNotifyProc;
    Data: Pointer;
    Next: PQFormNotifyItem;
  end;

  TQFormNotifyLink = record
    First, Last: PQFormNotifyItem;
  end;

  TQFormNotify = record
    Control: TCommonCustomForm;
    FSizeNotifies: TQFormNotifyLink;
    FFreeNotifies: TQFormNotifyLink;
  end;

  PQFormNotify = ^TQFormNotify;

  TQFormNotifier = class(TComponent)
  private
  protected
    FNotifications: TList;
    FControlHooks: TList;
    procedure Notification(AComponent: TComponent;
      Operation: TOperation); override;
    function IndexOf(AComponent: TComponent): Integer;
    procedure ParentSizeChanged(AParent: THandle);
    procedure NoOp;
    procedure RemoveHook(ACtrl: TCommonCustomForm);
    procedure AddHook(ACtrl: TCommonCustomForm);
    procedure DoNotifies(const ALink: TQFormNotifyLink);
    procedure FreeNotify(AItem: PQFormNotify);
    function NewItem(ACtrl: TCommonCustomForm): PQFormNotify;
    procedure AddNotifyProc(var ALink: TQFormNotifyLink;
      AProc: TQFormNotifyProc; AData: Pointer);
    function RemoveNotifyProc(var ALink: TQFormNotifyLink;
      AProc: TQFormNotifyProc): Boolean;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure RegisterFreeNotification(AHandle: THandle;
      AOnFree: TQFormNotifyProc; AData: Pointer);
    procedure RegisterSizeNotification(AHandle: THandle;
      AOnSizeChanged: TQFormNotifyProc; AData: Pointer);
    procedure Unregister(AProc: TQFormNotifyProc);
    procedure Clear;
  end;

  TQFormNotifyService = class(TQService, IQFreeNotifyService)
  protected
    FNotifier: TQFormNotifier;
  public
    constructor Create; override;
    destructor Destroy; override;
    procedure RegisterFreeNotify(AHandle: THandle; AOnFree: TQFormNotifyProc;
      AData: Pointer);
    procedure RegisterSizeNotify(AHandle: THandle; AOnResize: TQFormNotifyProc;
      AData: Pointer);
    procedure Unregister(AOnFree: TQFormNotifyProc);
    function InSameInstance(AHandle: THandle): Boolean;
    procedure Clear;
    procedure ParentSizeChanged(AParent: THandle);
  end;

var
  LocalFreeNotifyService: IQFreeNotifyService;
  LocalFreeNotifyServiceName: QStringW;

function RegisterFormService(const APath, AName: QStringW; AClass: TFormClass;
  AMultiInstance: Boolean): IQFormService;
var
  AService: TQFMXFormService;
begin
  AService := TQFMXFormService.Create(AName, AClass, AMultiInstance);
  RegisterServices(PQCharW(APath), [AService]);
  Result := AService as IQFormService;
end;

function RegisterFormService(const AId: TGuid; const APath, AName: QStringW;
  AClass: TFormClass; AMultiInstance: Boolean): IQFormService;
var
  AService: TQFMXFormService;
begin
  AService := TQFMXFormService.Create(AId, AName, AClass, AMultiInstance);
  RegisterServices(PQCharW(APath), [AService]);
  Result := AService as IQFormService;
end;

function RegisterFormService(const APath, AName: QStringW; AForm: TForm)
  : IQFormService;
var
  AService: TQFMXFormService;
begin
  AService := TQFMXFormService.Create(AName, AForm, nil);
  RegisterServices(PQCharW(APath), [AService]);
  Result := AService as IQFormService;
end;

function RegisterFormService(const AId: TGuid; const APath, AName: QStringW;
  AForm: TForm): IQFormService;
var
  AService: TQFMXFormService;
begin
  AService := TQFMXFormService.Create(AId, AName, AForm, nil);
  RegisterServices(PQCharW(APath), [AService]);
  Result := AService as IQFormService;
end;

function FindFormService(AForm: TForm): IQFormService;
var
  AHolder: TQFormServiceHolder;
  I: Integer;
begin
  Result := nil;
  for I := 0 to AForm.ComponentCount - 1 do
  begin
    if AForm.Components[I] is TQFormServiceHolder then
    begin
      Result := (AForm.Components[I] as TQFormServiceHolder).FFormService;
      Exit;
    end;
  end;
end;
{ TQFMXFormService }

procedure TQFMXFormService.AdjustAlign;
var
  R: TRect;
  AW, AH: Integer;
  AParent: HWND;
begin
  if FormAlign in [faDefault, faNone, faCustom] then
    Exit;

  if Assigned(FForm) then
  begin
    AParent := windows.GetParent(FormToHwnd(FForm));
    if AParent <> 0 then
    begin
      GetWindowRect(AParent, R);
      AW := R.Right - R.Left;
      AH := R.Bottom - R.Top;
      case FormAlign of
        faLeftTop:
          FForm.SetBounds(0, 0, OriginWidth, OriginHeight);
        faCenterTop:
          FForm.SetBounds((AW - OriginWidth) div 2, 0, OriginWidth,
            OriginHeight);
        faTop:
          FForm.SetBounds(0, 0, AW, OriginHeight);
        faRightTop:
          FForm.SetBounds(AW - OriginWidth, 0, OriginWidth, OriginHeight);
        faRightCenter:
          FForm.SetBounds(AW - OriginWidth, (AH - OriginHeight) div 2,
            OriginWidth, OriginHeight);
        faRight:
          FForm.SetBounds(AW - OriginWidth, 0, OriginWidth, AH);
        faRightBottom:
          FForm.SetBounds(AW - OriginWidth, AH - OriginHeight, OriginWidth,
            OriginHeight);
        faCenterBottom:
          FForm.SetBounds((AW - OriginWidth) div 2, AH - OriginHeight,
            OriginWidth, OriginHeight);
        faBottom:
          FForm.SetBounds(0, AH - OriginHeight, AW, OriginHeight);
        faLeftBottom:
          FForm.SetBounds(0, AH - OriginHeight, OriginWidth, OriginHeight);
        faLeft:
          FForm.SetBounds(0, 0, OriginWidth, AH);
        faLeftCenter:
          FForm.SetBounds(0, (AH - OriginHeight) div 2, OriginWidth,
            OriginHeight);
        faContent:
          FForm.SetBounds(0, 0, AW, AH);
        faCenter:
          FForm.SetBounds((AW - OriginWidth) div 2, (AH - OriginHeight) div 2,
            OriginWidth, OriginHeight);
        faHoriz:
          FForm.SetBounds(0, OriginTop, AW, OriginHeight);
        faVert:
          FForm.SetBounds(OriginLeft, 0, OriginWidth, AH);
      end;
    end;
  end;
end;

procedure TQFMXFormService.BringToFront;
begin
  if Assigned(FForm) then
    FForm.BringToFront;
end;

constructor TQFMXFormService.Create(const AId: TGuid; AName: QStringW;
  AForm: TCommonCustomForm; ACreator: TObject);
begin
  inherited Create(NewId, AName);
  FCreator := ACreator;
  Form := AForm;
end;

constructor TQFMXFormService.Create(AName: QStringW; AFormClass: TFormClass;
  AIsMultiInstance: Boolean);
begin
  inherited Create(NewId, AName);
  FFormClass := AFormClass;
  FIsMultiInstance := AIsMultiInstance;
end;

constructor TQFMXFormService.Create(AName: QStringW; AForm: TCommonCustomForm;
  ACreator: TObject);
begin
  inherited Create(NewId, AName);
  FCreator := ACreator;
  Form := AForm;
end;

constructor TQFMXFormService.Create(const AId: TGuid; AName: QStringW;
  AFormClass: TFormClass; AIsMultiInstance: Boolean);
begin
  inherited Create(NewId, AName);
  FFormClass := AFormClass;
  FIsMultiInstance := AIsMultiInstance;
end;

destructor TQFMXFormService.Destroy;
begin
  if Assigned(FForm) then
  begin
    Undock;
    DisableRefCount; // 禁用引用计数
    if FClosing then
    begin
      SetProp(FormToHwnd(FForm), SFormNeedFree, 1);
      if not(csDestroying in FForm.ComponentState) then
        DoFree(Self)
      else
      begin
        UnlinkFormEvents;
        FForm := nil;
      end;
    end
    else
      FreeAndNilObject(FForm);
  end;
  inherited;
end;

procedure TQFMXFormService.DoActivate(ASender: TObject);
begin
  if Assigned(FOldOnActivate) then
    FOldOnActivate(ASender);
  if Assigned(FEvents.OnActivate) then
    FEvents.OnActivate(Self);
end;

procedure TQFMXFormService.DoCanClose(ASender: TObject; var ACanClose: Boolean);
begin
  if Assigned(FOldCanClose) then
    FOldCanClose(ASender, ACanClose);
  if Assigned(FEvents.CanClose) then
    FEvents.CanClose(Self, ACanClose);
end;

procedure TQFMXFormService.DockTo(AHandle: THandle; const ARect: TRect);
var
  AForm: TCommonCustomForm;

  function RegisterFreeNotify: Boolean;
  var
    AParent: IQServices;
    I: Integer;
    AFreeService: IQFreeNotifyService;
  begin
    Result := False;
    if Assigned(FFreeService) then
    begin
      FFreeService.Unregister(DoDockParentFree);
      FFreeService.Unregister(DoDockParentSizeChanged);
      FFreeService := nil;
    end;
    if Supports(PluginsManager.ByPath(PQCharW(FreeNotificationRoot)),
      IQServices, AParent) then
    begin
      for I := 0 to AParent.Count - 1 do
      begin
        if Supports(AParent[I], IQFreeNotifyService, AFreeService) then
        begin
          if AFreeService.InSameInstance(AHandle) then
          begin
            FFreeService := AFreeService;
            AFreeService.RegisterFreeNotify(AHandle, DoDockParentFree, Self);
            AFreeService.RegisterSizeNotify(AHandle,
              DoDockParentSizeChanged, Self);
            Result := True;
            Break;
          end;
        end;
      end;
    end;
  end;

  function IsSharePackage: Boolean;
  begin
    // 如果控件和窗体位于同一个模块中，不需要额外处理，直接Dock就行
    Result := Assigned(AForm) and
      (FindHInstance(Pointer(GetWindowLong(AHandle, GWL_WNDPROC)))
      = FindHInstance(Pointer(GetWindowLong(FormToHwnd(FForm), GWL_WNDPROC))));
  end;
  procedure WinDock;
  begin
    AForm := FindWindow(AHandle);
    if FormNeeded then
    begin
      if IsSharePackage then
      begin
        if RegisterFreeNotify then
        begin
          FDockParent := AHandle;
          FForm.Parent := AForm;
          FForm.SetBounds(ARect.Left, ARect.Top, ARect.Width, ARect.Height);
          FForm.Visible := True;
        end;
      end
      else
      begin
        if RegisterFreeNotify then
        begin
          FForm.BorderStyle := TFmxFormBorderStyle.None;
          FForm.Visible := True;
          FDockParent := AHandle;
          windows.SetParent(FormToHwnd(FForm), AHandle);
          AdjustAlign;
        end;
      end;
    end;
  end;

begin
  WinDock;
end;

procedure TQFMXFormService.DockTo(AHandle: THandle; Align: TFormAlign);
begin
  FormAlign := Align;
  DockTo(AHandle, Rect(0, 0, 0, 0));
end;

procedure TQFMXFormService.DoClose(ASender: TObject; var Action: TCloseAction);
begin
  if Assigned(FOldOnClose) then
    FOldOnClose(ASender, Action);
  if Assigned(FEvents.OnClose) then
    FEvents.OnClose(Self, Action);
end;

procedure TQFMXFormService.DoDeactivate(ASender: TObject);
begin
  if Assigned(FOldOnDeactivate) then
    FOldOnDeactivate(ASender);
  if Assigned(FEvents.OnDeactivate) then
    FEvents.OnDeactivate(Self);
end;

procedure TQFMXFormService.DoDockParentFree(AData: Pointer);
begin
  if Assigned(FForm) then
    Undock;
end;

procedure TQFMXFormService.DoDockParentSizeChanged(AData: Pointer);
begin
  ParentResized;
end;

procedure TQFMXFormService.DoFormFree(AData: Pointer);
begin
  if Assigned(FForm) then
  begin
    Undock;
    UnhookEvents;
    FForm := nil;
  end;
end;

procedure TQFMXFormService.DoFree(ASender: TObject);
var
  AFreeNotify: TQFormNotifyEvent;
begin
  if Assigned(FOldOnFree) then
    FOldOnFree(ASender);
  AFreeNotify := FEvents.OnFree;
  FForm := nil;
  if Assigned(AFreeNotify) then
    AFreeNotify(Self);
end;

procedure TQFMXFormService.DoHide(ASender: TObject);
begin
  if Assigned(FOldOnHide) then
    FOldOnHide(ASender);
  if Assigned(FEvents.OnHide) then
    FEvents.OnHide(Self);
end;

procedure TQFMXFormService.DoResize(ASender: TObject);
begin
  if Assigned(FOldOnResize) then
    FOldOnResize(ASender);
  if Assigned(FEvents.OnResize) then
    FEvents.OnResize(Self);
end;

procedure TQFMXFormService.DoShow(ASender: TObject);
begin
  if Assigned(FOldOnShow) then
    FOldOnShow(ASender);
  if Assigned(FEvents.OnShow) then
    FEvents.OnShow(Self);
end;

function TQFMXFormService.FormNeeded: Boolean;
begin
  if not Assigned(FForm) then
  begin
    if not FIsMultiInstance then
      Form := FFormClass.Create(nil);
  end;
  Result := Assigned(FForm);
end;

procedure TQFMXFormService.GetBounds(var R: TRect);
begin
  if Assigned(FForm) then
    R := Rect(FForm.Left, FForm.Top, FForm.Left + FForm.Width,
      FForm.Top + FForm.Height)
  else
    FillChar(R, SizeOf(TRect), 0);
end;

function TQFMXFormService.GetDockParent: THandle;
begin
  Result := FDockParent;
end;

function TQFMXFormService.GetFormAlign: TFormAlign;
begin
  Result := FFormAlign;
end;

function TQFMXFormService.GetHeight: Integer;
begin
  if FormNeeded then
    Result := FForm.Height
  else
    Result := 0;
end;

function TQFMXFormService.GetInstance: IQService;
begin
  if Assigned(FFormClass) then
  begin
    if FIsMultiInstance then
      Result := TQFMXFormService.Create(Name, FFormClass.Create(nil), Self)
    else
    begin
      if not Assigned(FForm) then
        FForm := FFormClass.Create(nil);
      Result := Self;
    end;
  end
  else
    Result := Self;
end;

function TQFMXFormService.GetModalResult: TModalResult;
begin
  if Assigned(FForm) then
    Result := FForm.ModalResult
  else
    Result := mrNone;
end;

function TQFMXFormService.GetOriginBottom: Integer;
begin
  Result := FFormOrigin.Bottom;
end;

function TQFMXFormService.GetOriginHeight: Integer;
begin
  Result := FFormOrigin.Bottom - FFormOrigin.Top;
end;

function TQFMXFormService.GetOriginLeft: Integer;
begin
  Result := FFormOrigin.Left;
end;

function TQFMXFormService.GetOriginRight: Integer;
begin
  Result := FFormOrigin.Right;
end;

function TQFMXFormService.GetOriginTop: Integer;
begin
  Result := FFormOrigin.Top;
end;

function TQFMXFormService.GetOriginWidth: Integer;
begin
  Result := FFormOrigin.Right - FFormOrigin.Left;
end;

function TQFMXFormService.GetWidth: Integer;
begin
  if FormNeeded then
    Result := FForm.Width
  else
    Result := 0;
end;

procedure TQFMXFormService.HookEvents(const AEvents: TQFormEvents);
begin
  FEvents := AEvents;
end;

function TQFMXFormService.IsMultiInstance: Boolean;
begin
  Result := Assigned(FFormClass) and FIsMultiInstance;
end;

procedure TQFMXFormService.ParentResized;
begin
  AdjustAlign;
end;

function TQFMXFormService.QueryInterface(const IID: TGuid; out Obj): HRESULT;
begin
  Result := inherited QueryInterface(IID, Obj);
  if Result = E_NOINTERFACE then
  begin
    if Assigned(FForm) then
    begin
      if Supports(FForm, IID, Obj) then
        Result := S_OK
    end;
  end;
end;

procedure TQFMXFormService.SendInput(var AInput: TQInputEvent);
  procedure InputKey(var AItem: TInput; AKey: Word; AIsDown: Boolean);
  const
    MAPVK_VK_TO_VSC = 0;
  begin
    AItem.ki.wVk := AKey;
    AItem.itype := INPUT_KEYBOARD;
    AItem.ki.wScan := MapVirtualKey(AKey, MAPVK_VK_TO_VSC);
    if AIsDown then
      AItem.ki.dwFlags := 0
    else
      AItem.ki.dwFlags := KEYEVENTF_KEYUP;
    AItem.ki.time := 0;
    AItem.ki.dwExtraInfo := 0;
  end;

  procedure InputMouse(AItem: TInput; const APos: TSmallPoint;
    AWheelDelta: Integer = 0; AFlags: Cardinal = 0);
  begin
    AItem.itype := INPUT_MOUSE;
    AItem.mi.dx := (APos.x shl 16) div GetSystemMetrics(SM_CXSCREEN);
    AItem.mi.dy := (APos.y shl 16) div GetSystemMetrics(SM_CYSCREEN);
    AItem.mi.mouseData := AWheelDelta;
    AItem.mi.dwFlags := AFlags;
    AItem.mi.time := 0;
    AItem.mi.dwExtraInfo := 0;
  end;

  procedure SendMouseInput;
  var
    si: array [0 .. 8] of TInput;
    C: Integer;
  begin
    C := 0;
    if AInput.Shifts.LeftShiftDown then
      InputKey(si[C], VK_LSHIFT, True)
    else
      InputKey(si[C], VK_LSHIFT, False);
    Inc(C);
    if AInput.Shifts.RightShiftDown then
      InputKey(si[C], VK_RSHIFT, True)
    else
      InputKey(si[C], VK_RSHIFT, False);
    Inc(C);
    if AInput.Shifts.LeftCtrlDown then
      InputKey(si[C], VK_LCONTROL, True)
    else
      InputKey(si[C], VK_LCONTROL, False);
    Inc(C);

    if AInput.Shifts.RightCtrlDown then
      InputKey(si[C], VK_RCONTROL, True)
    else
      InputKey(si[C], VK_RCONTROL, False);
    Inc(C);

    if AInput.Shifts.LeftAltDown then
      InputKey(si[C], VK_LMENU, True)
    else
      InputKey(si[C], VK_LMENU, False);
    Inc(C);

    if AInput.Shifts.RightAltDown then
      InputKey(si[C], VK_RMENU, True)
    else
      InputKey(si[C], VK_RMENU, False);
    Inc(C);

    if AInput.Shifts.LeftWinDown then
      InputKey(si[C], VK_LWIN, True)
    else
      InputKey(si[C], VK_LWIN, False);
    Inc(C);

    if AInput.Shifts.RightWinDown then
      InputKey(si[C], VK_RWIN, True)
    else
      InputKey(si[C], VK_RWIN, False);
    Inc(C);
    SetCursorPos(AInput.Mouse.Pos.x, AInput.Mouse.Pos.y);
    InputMouse(si[C], AInput.Mouse.Pos, AInput.Mouse.WheelData,
      MOUSEEVENTF_ABSOLUTE or AInput.Mouse.Events);
    Inc(C);
    windows.SendInput(C, si[0], SizeOf(TInput));
  end;
  procedure SendKeyInput;
  var
    si: array [0 .. 8] of TInput;
    C: Integer;
  begin
    C := 0;
    if AInput.Shifts.LeftShiftDown then
      InputKey(si[C], VK_LSHIFT, True)
    else
      InputKey(si[C], VK_LSHIFT, False);
    Inc(C);
    if AInput.Shifts.RightShiftDown then
      InputKey(si[C], VK_RSHIFT, True)
    else
      InputKey(si[C], VK_RSHIFT, False);
    Inc(C);
    if AInput.Shifts.LeftCtrlDown then
      InputKey(si[C], VK_LCONTROL, True)
    else
      InputKey(si[C], VK_LCONTROL, False);
    Inc(C);

    if AInput.Shifts.RightCtrlDown then
      InputKey(si[C], VK_RCONTROL, True)
    else
      InputKey(si[C], VK_RCONTROL, False);
    Inc(C);

    if AInput.Shifts.LeftAltDown then
      InputKey(si[C], VK_LMENU, True)
    else
      InputKey(si[C], VK_LMENU, False);
    Inc(C);

    if AInput.Shifts.RightAltDown then
      InputKey(si[C], VK_RMENU, True)
    else
      InputKey(si[C], VK_RMENU, False);
    Inc(C);

    if AInput.Shifts.LeftWinDown then
      InputKey(si[C], VK_LWIN, True)
    else
      InputKey(si[C], VK_LWIN, False);
    Inc(C);

    if AInput.Shifts.RightWinDown then
      InputKey(si[C], VK_RWIN, True)
    else
      InputKey(si[C], VK_RWIN, False);
    Inc(C);
    if AInput.Key.Key <> 0 then
    begin
      InputKey(si[C], AInput.Key.Key, AInput.Key.IsDown);
      Inc(C);
    end;
    windows.SendInput(C, si[0], SizeOf(TInput));
  end;

begin
  if FormNeeded then
  begin
    case AInput.EventType of
      ietMouse:
        SendMouseInput;
      ietKeyboad:
        SendKeyInput;
    end;
  end;
end;

procedure TQFMXFormService.SendToBack;
begin
  if Assigned(FForm) then
    FForm.SendToBack;
end;

procedure TQFMXFormService.SetBounds(L, T, W, H: Integer);
begin
  if Assigned(FForm) then
    FForm.SetBounds(L, T, W, H);
end;

procedure TQFMXFormService.SetForm(const Value: TCommonCustomForm);
begin
  if FForm <> Value then
  begin
    if Assigned(FForm) then
      UnhookEvents;
    FForm := Value;
    if Assigned(FForm) then
    begin
      FFormOrigin := FForm.GetBounds;
      LocalFreeNotifyService.RegisterFreeNotify(FormToHwnd(FForm),
        DoFormFree, nil);
      FOldCanClose := FForm.OnCloseQuery;
      FOldOnClose := FForm.OnClose;
      FOldOnFree := FForm.OnDestroy;
      FOldOnActivate := FForm.OnActivate;
      FOldOnDeactivate := FForm.OnDeactivate;
      FOldOnResize := FForm.OnResize;
      FOldOnShow := FForm.OnShow;
      FOldOnHide := FForm.OnHide;
      FForm.OnCloseQuery := DoCanClose;
      FForm.OnClose := DoClose;
      FForm.OnDestroy := DoFree;
      FForm.OnActivate := DoActivate;
      FForm.OnDeactivate := DoDeactivate;
      FForm.OnResize := DoResize;
      FForm.OnShow := DoShow;
      FForm.OnHide := DoHide;
    end;
  end;
end;

procedure TQFMXFormService.SetFormAlign(const AValue: TFormAlign);
begin
  if FFormAlign <> AValue then
  begin
    FFormAlign := AValue;
    AdjustAlign;
  end;
end;

procedure TQFMXFormService.SetHeight(const AValue: Integer);
begin
  if FormNeeded then
    FForm.Height := AValue;
end;

procedure TQFMXFormService.SetModalResult(const AValue: TModalResult);
begin
  if FormNeeded then
    FForm.ModalResult := AValue;
end;

procedure TQFMXFormService.SetWidth(const AValue: Integer);
begin
  if FormNeeded then
    FForm.Width := AValue;
end;

procedure TQFMXFormService.Show;
begin
  if FormNeeded then
    FForm.Show;
end;

procedure TQFMXFormService.ShowModal(AOnModalResult: TQFormModalResultHandler;
  ATag: IQParams);
begin
  if FormNeeded then
  begin
    FForm.ShowModal;
    if Assigned(AOnModalResult) then
      AOnModalResult(Self, ATag);
  end
  else if Assigned(AOnModalResult) then
    AOnModalResult(Self, ATag);
end;

procedure TQFMXFormService.Undock;
begin
  FForm.Parent := nil;
  windows.SetParent(FormToHwnd(FForm), 0);
  FDockParent := 0;
end;

procedure TQFMXFormService.UnhookEvents;
begin
  FEvents.CanClose := nil;
  FEvents.OnClose := nil;
  FEvents.OnFree := nil;
  FEvents.OnActivate := nil;
  FEvents.OnDeactivate := nil;
  FEvents.OnResize := nil;
  FEvents.OnShow := nil;
  FEvents.OnHide := nil;
end;

procedure TQFMXFormService.UnlinkFormEvents;
begin
  if Assigned(FForm) then
  begin
    FForm.OnCloseQuery := FOldCanClose;
    FForm.OnClose := FOldOnClose;
    FForm.OnDestroy := FOldOnFree;
    FForm.OnActivate := FOldOnActivate;
    FForm.OnDeactivate := FOldOnDeactivate;
    FForm.OnResize := FOldOnResize;
    FForm.OnShow := FOldOnShow;
    FForm.OnHide := FOldOnHide;
    UnhookEvents;
  end;
end;

{ TQFormNotifyService }

procedure TQFormNotifyService.Clear;
begin
  FNotifier.Clear;
end;

constructor TQFormNotifyService.Create;
begin
  LocalFreeNotifyServiceName := 'FreeNotifyService_' +
    IntToHex(HInstance, SizeOf(Pointer) shl 1);
  inherited Create(NewId, LocalFreeNotifyServiceName);
  FNotifier := TQFormNotifier.Create(nil);
end;

destructor TQFormNotifyService.Destroy;
begin
  FreeAndNil(FNotifier);
  inherited;
end;

function TQFormNotifyService.InSameInstance(AHandle: THandle): Boolean;
type
  TComponentMethod = procedure of object;
var
  AMethod: TComponentMethod;
begin
  AMethod := FNotifier.NoOp;
  Result := GetClassLong(AHandle, GCL_HMODULE)
    = FindHInstance(TMethod(AMethod).Code);
end;

procedure TQFormNotifyService.ParentSizeChanged(AParent: THandle);
begin
  FNotifier.ParentSizeChanged(AParent);
end;

procedure TQFormNotifyService.RegisterFreeNotify(AHandle: THandle;
  AOnFree: TQFormNotifyProc; AData: Pointer);
begin
  FNotifier.RegisterFreeNotification(AHandle, AOnFree, AData);
end;

procedure TQFormNotifyService.RegisterSizeNotify(AHandle: THandle;
  AOnResize: TQFormNotifyProc; AData: Pointer);
begin
  FNotifier.RegisterSizeNotification(AHandle, AOnResize, AData);
end;

procedure TQFormNotifyService.Unregister(AOnFree: TQFormNotifyProc);
begin
  FNotifier.Unregister(AOnFree);
end;

{ TQFormNotifier }

procedure TQFormNotifier.AddHook(ACtrl: TCommonCustomForm);
var
  I: Integer;
  AHook: TQControlHook;
begin
  for I := 0 to FControlHooks.Count - 1 do
  begin
    AHook := FControlHooks[I];
    if AHook.FControl = ACtrl then
    begin
      Inc(AHook.FRefCount);
      Exit;
    end;
  end;
  AHook := TQControlHook.Create(ACtrl);
  FControlHooks.Add(AHook);
  Inc(AHook.FRefCount);
end;

procedure TQFormNotifier.AddNotifyProc(var ALink: TQFormNotifyLink;
  AProc: TQFormNotifyProc; AData: Pointer);
var
  AProcItem: PQFormNotifyItem;
begin
  AProcItem := ALink.First;
  while Assigned(AProcItem) do
  begin
    if MethodEqual(TMethod(AProcItem.OnNotify), TMethod(AProc)) then
    begin
      if AProcItem.Data = AData then
        Exit;
    end;
    AProcItem := AProcItem.Next;
  end;
  New(AProcItem);
  AProcItem.Next := nil;
  AProcItem.OnNotify := AProc;
  AProcItem.Data := AData;
  if Assigned(ALink.Last) then
    ALink.Last.Next := AProcItem
  else
    ALink.First := AProcItem;
  ALink.Last := AProcItem;
end;

procedure TQFormNotifier.Clear;
var
  I: Integer;
  AItem: PQFormNotify;
  ANotify: PQFormNotifyItem;
begin
  for I := 0 to FNotifications.Count - 1 do
  begin
    AItem := FNotifications[I];
    try
      DoNotifies(AItem.FFreeNotifies);
      AItem.Control.RemoveFreeNotification(Self);
    except
      FreeNotify(AItem);
    end;
  end;
  FNotifications.Clear;
end;

constructor TQFormNotifier.Create(AOwner: TComponent);
begin
  inherited;
  FNotifications := TList.Create;
  FControlHooks := TList.Create;
end;

destructor TQFormNotifier.Destroy;
begin
  Clear;
  FreeAndNil(FControlHooks);
  FreeAndNil(FNotifications);
  inherited;
end;

procedure TQFormNotifier.DoNotifies(const ALink: TQFormNotifyLink);
var
  AItem: PQFormNotifyItem;
begin
  AItem := ALink.First;
  while Assigned(AItem) do
  begin
    try
      AItem.OnNotify(AItem.Data);
    except

    end;
    AItem := AItem.Next;
  end;
end;

procedure TQFormNotifier.FreeNotify(AItem: PQFormNotify);
  procedure FreeLinks(var ALink: TQFormNotifyLink);
  var
    ANotify: PQFormNotifyItem;
  begin
    ANotify := ALink.First;
    while Assigned(ANotify) do
    begin
      ALink.First := ANotify.Next;
      Dispose(ANotify);
      ANotify := ALink.First;
    end;
    ALink.Last := nil;
  end;

begin
  if Assigned(AItem.FSizeNotifies.First) then
    RemoveHook(AItem.Control);
  FreeLinks(AItem.FSizeNotifies);
  FreeLinks(AItem.FFreeNotifies);
  Dispose(AItem);
end;

function TQFormNotifier.IndexOf(AComponent: TComponent): Integer;
var
  I: Integer;
  AItem: PQFormNotify;
begin
  Result := -1;
  for I := 0 to FNotifications.Count - 1 do
  begin
    AItem := FNotifications[I];
    if AItem.Control = AComponent then
    begin
      Result := I;
      Break;
    end;
  end;
end;

function TQFormNotifier.NewItem(ACtrl: TCommonCustomForm): PQFormNotify;
begin
  New(Result);
  Result.Control := ACtrl;
  Result.FSizeNotifies.First := nil;
  Result.FSizeNotifies.Last := nil;
  Result.FFreeNotifies.First := nil;
  Result.FFreeNotifies.Last := nil;
  FNotifications.Add(Result);
  ACtrl.FreeNotification(Self);
end;

procedure TQFormNotifier.NoOp;
begin

end;

procedure TQFormNotifier.Notification(AComponent: TComponent;
  Operation: TOperation);
var
  I: Integer;
  AItem: PQFormNotify;
begin
  inherited;
  if Operation = opRemove then
  begin
    I := IndexOf(AComponent);
    if I <> -1 then
    begin
      AItem := FNotifications[I];
      try
        FNotifications.Delete(I);
        AItem.Control.RemoveFreeNotification(Self);
        DoNotifies(AItem.FFreeNotifies);
      finally
        FreeNotify(AItem);
      end;
    end;
  end;
end;

procedure TQFormNotifier.ParentSizeChanged(AParent: THandle);
var
  I: Integer;
  AItem: PQFormNotify;
begin
  for I := 0 to FNotifications.Count - 1 do
  begin
    AItem := FNotifications[I];
    if IntPtr(AItem.Control) = AParent then
      DoNotifies(AItem.FSizeNotifies);
  end;
end;

procedure TQFormNotifier.RegisterFreeNotification(AHandle: THandle;
  AOnFree: TQFormNotifyProc; AData: Pointer);
var
  AItem: PQFormNotify;
  I: Integer;
  AForm: TCommonCustomForm;
begin
  AForm := FindWindow(AHandle);
  if Assigned(AForm) then
  begin
    I := IndexOf(AForm);
    if I = -1 then
      AItem := NewItem(AForm)
    else
      AItem := FNotifications[I];
    AddNotifyProc(AItem.FFreeNotifies, AOnFree, AData);
  end;
end;

procedure TQFormNotifier.RegisterSizeNotification(AHandle: THandle;
  AOnSizeChanged: TQFormNotifyProc; AData: Pointer);
var
  AItem: PQFormNotify;
  I: Integer;
  AForm: TCommonCustomForm;
begin
  AForm := FindWindow(AHandle);
  if Assigned(AForm) then
  begin
    I := IndexOf(AForm);
    if I = -1 then
      AItem := NewItem(AForm)
    else
      AItem := FNotifications[I];
    if not Assigned(AItem.FSizeNotifies.First) then
      AddHook(AForm);
    AddNotifyProc(AItem.FSizeNotifies, AOnSizeChanged, AData);
  end;
end;

procedure TQFormNotifier.RemoveHook(ACtrl: TCommonCustomForm);
var
  I: Integer;
  AHook: TQControlHook;
begin
  for I := 0 to FControlHooks.Count - 1 do
  begin
    AHook := FControlHooks[I];
    if AHook.FControl = ACtrl then
    begin
      Dec(AHook.FRefCount);
      if AHook.FRefCount = 0 then
      begin
        FreeAndNil(AHook);
        FControlHooks.Delete(I);
      end;
      Exit;
    end;
  end;
end;

function TQFormNotifier.RemoveNotifyProc(var ALink: TQFormNotifyLink;
  AProc: TQFormNotifyProc): Boolean;
var
  AItem, APrior, ANext: PQFormNotifyItem;
begin
  AItem := ALink.First;
  APrior := nil;
  Result := False;
  while Assigned(AItem) do
  begin
    if MethodEqual(TMethod(AItem.OnNotify), TMethod(AProc)) then
    begin
      ANext := AItem.Next;
      if Assigned(APrior) then
        APrior.Next := AItem.Next;
      if ALink.First = AItem then
        ALink.First := ANext;
      Dispose(AItem);
      AItem := ANext;
      Result := True;
    end
    else
    begin
      APrior := AItem;
      AItem := AItem.Next;
    end;
  end;
  if ALink.First = nil then
    ALink.Last := nil;
end;

procedure TQFormNotifier.Unregister(AProc: TQFormNotifyProc);
var
  I: Integer;
  AItem: PQFormNotify;
  AFound: Boolean;
begin
  AFound := False;
  for I := 0 to FNotifications.Count - 1 do
  begin
    AItem := FNotifications[I];
    if RemoveNotifyProc(AItem.FSizeNotifies, AProc) then
    begin
      if not Assigned(AItem.FSizeNotifies.First) then
        RemoveHook(AItem.Control);
    end;
    RemoveNotifyProc(AItem.FFreeNotifies, AProc);
    if not(Assigned(AItem.FSizeNotifies.First) or
      Assigned(AItem.FFreeNotifies.First)) then
    begin
      FNotifications.Delete(I);
      FreeNotify(AItem);
      Break;
    end;
  end;
end;

{ TQControlHook }

constructor TQControlHook.Create(ACtrl: TCommonCustomForm);
begin
  inherited Create;
  FControl := ACtrl;
  FLastResize := ACtrl.OnResize;
  ACtrl.OnResize := DoResize;
end;

destructor TQControlHook.Destroy;
begin
  FControl.OnResize := FLastResize;
  inherited;
end;

procedure TQControlHook.DoResize(ASender: TObject);
begin
  if Assigned(LocalFreeNotifyService) then
    LocalFreeNotifyService.ParentSizeChanged(IntPtr(FControl));
end;

initialization

LocalFreeNotifyService := TQFormNotifyService.Create;
LocalFreeNotifyServiceName := (LocalFreeNotifyService as IQService).Name;
RegisterServices(PQCharW(FreeNotificationRoot),
  [LocalFreeNotifyService as IQService]);

finalization

UnregisterServices(PQCharW(FreeNotificationRoot), [LocalFreeNotifyServiceName]);
LocalFreeNotifyService.Clear;
LocalFreeNotifyService := nil;
end.
