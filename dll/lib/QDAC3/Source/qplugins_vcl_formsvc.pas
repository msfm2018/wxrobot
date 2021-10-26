{$REGION History}
{ 修订历史

  2017.2.9
  =========
  * 修正了插件中在特定场景下 TabList 顺序切换的问题（墨宝轩报告）
}
{$ENDREGION}
/// <summary>
/// IQFormService 的 VCL 版实现单元，仅支持 VCL 程序
/// </summary>
unit qplugins_vcl_formsvc;

interface

uses classes, sysutils, types, windows, messages, controls, comctrls, forms,
  qstring, qplugins, qplugins_base, qplugins_params, qplugins_vcl_messages,
  qplugins_formsvc{$IF RTLVERSION>=23}, uitypes{$IFEND};
{$HPPEMIT '#pragma link "qplugins_vcl_formsvc"'}

type
  TQVCLFormService = class(TQFormService)
  protected
    FForm: TForm;
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
    procedure SetForm(const Value: TForm);
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
    constructor Create(AName: QStringW; AForm: TForm;
      ACreator: TObject); overload;
    constructor Create(AName: QStringW; AFormClass: TFormClass;
      AIsMultiInstance: Boolean = True); overload;
    constructor Create(const AId: TGuid; AName: QStringW; AForm: TForm;
      ACreator: TObject); overload;
    constructor Create(const AId: TGuid; AName: QStringW;
      AFormClass: TFormClass; AIsMultiInstance: Boolean = True); overload;
    destructor Destroy; override;
    procedure ShowModal(AOnModalResult: TQFormModalResultHandler;
      ATag: IQParams); override;
    procedure Show; override;
    procedure Close; override;
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
    property Form: TForm read FForm write SetForm;
    property FormAlign: TFormAlign read GetFormAlign write SetFormAlign;
  end;

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

const
  FreeNotificationRoot: QStringW = '/Services/Docks/FreeNotifications';
  VCLControlTestRoot: QStringW = '/Services/VCL/ControlTest';
  LocalVCLCtrlTestServiceName: QStringW = 'IsVCLControl';
  SFormNeedFree: PChar = 'QPlugins.VCL.FormService.NeedFree';
  SParentResized: PChar = 'QPlugins.FormService.ParentResized';

type
  IQVCLTestService = interface
    ['{CCC7C6EB-135F-4A89-99C2-109DF56B617E}']
    function IsVCLControl(AHandle: HWND): Boolean;
    function HasControl(AHandle: HWND): Boolean;
  end;

  TQVCLTestService = class(TQService, IQVCLTestService)
  protected
  public
    constructor Create; override;
    destructor Destroy; override;
    function IsVCLControl(AHandle: HWND): Boolean;
    function HasControl(AHandle: HWND): Boolean;
  end;

  TQControlHook = class
  private
    FControl: TWinControl;
    FLastWndProc: TWndMethod;
    FRefCount: Integer;
    procedure HackedFormProc(var AMsg: TMessage);
    procedure HackedControlProc(var AMsg: TMessage);
  public
    constructor Create(ACtrl: TWinControl); overload;
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
    CtrlHandle: THandle;
    Control: TWinControl;
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
    procedure RemoveHook(ACtrl: TWinControl);
    procedure AddHook(ACtrl: TWinControl);
    procedure DoNotifies(const ALink: TQFormNotifyLink);
    procedure FreeNotify(AItem: PQFormNotify);
    procedure DoParentFormFree(AData: Pointer);
    function NewItem(ACtrl: TWinControl): PQFormNotify;
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

  TQFormServiceHolder = class(TComponent)
  protected
    FFormService: TQFormService;
  end;

var
  VCLCtrlTestServices: IQServices;
  LocalVCLCtrlTestService: IQVCLTestService;
  LocalFreeNotifyService: IQFreeNotifyService;
  LocalFreeNotifyServiceName: QStringW;

function RegisterFormService(const APath, AName: QStringW; AClass: TFormClass;
  AMultiInstance: Boolean): IQFormService;
var
  AService: TQVCLFormService;
begin
  AService := TQVCLFormService.Create(AName, AClass, AMultiInstance);
  RegisterServices(PQCharW(APath), [AService]);
  Result := AService as IQFormService;
end;

function RegisterFormService(const AId: TGuid; const APath, AName: QStringW;
  AClass: TFormClass; AMultiInstance: Boolean): IQFormService;
var
  AService: TQVCLFormService;
begin
  AService := TQVCLFormService.Create(AId, AName, AClass, AMultiInstance);
  RegisterServices(PQCharW(APath), [AService]);
  Result := AService as IQFormService;
end;

function RegisterFormService(const APath, AName: QStringW; AForm: TForm)
  : IQFormService;
var
  AService: TQVCLFormService;
begin
  AService := TQVCLFormService.Create(AName, AForm, nil);
  RegisterServices(PQCharW(APath), [AService]);
  Result := AService as IQFormService;
end;

function RegisterFormService(const AId: TGuid; const APath, AName: QStringW;
  AForm: TForm): IQFormService;
var
  AService: TQVCLFormService;
begin
  AService := TQVCLFormService.Create(AId, AName, AForm, nil);
  RegisterServices(PQCharW(APath), [AService]);
  Result := AService as IQFormService;
end;

{ TQVCLFormService }
procedure TQVCLFormService.AdjustAlign;
var
  R: TRect;
  AW, AH: Integer;
  AParent: HWND;
begin
  if FormAlign in [faDefault, faNone, faCustom] then
    Exit;

  if Assigned(FForm) then
  begin
    AParent := windows.GetParent(FForm.Handle);
    if AParent <> 0 then
    begin
      GetWindowRect(AParent, R);
      AW := R.Right - R.Left;
      AH := R.Bottom - R.Top;
      FForm.Align := alNone;
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

procedure TQVCLFormService.BringToFront;
begin
  if FormNeeded then
    FForm.BringToFront;
end;

constructor TQVCLFormService.Create(const AId: TGuid; AName: QStringW;
  AForm: TForm; ACreator: TObject);
begin
  inherited Create(AId, AName);
  FCreator := ACreator;
  Form := AForm;
end;

procedure TQVCLFormService.Close;
begin
  inherited;
  if Assigned(FForm) then
    FForm.Close;
end;

constructor TQVCLFormService.Create(const AId: TGuid; AName: QStringW;
  AFormClass: TFormClass; AIsMultiInstance: Boolean);
begin
  inherited Create(AId, Name);
  FFormClass := AFormClass;
  FIsMultiInstance := AIsMultiInstance;
end;

constructor TQVCLFormService.Create(AName: QStringW; AForm: TForm;
  ACreator: TObject);
begin
  inherited Create(NewId, AName);
  FCreator := ACreator;
  Form := AForm;
end;

constructor TQVCLFormService.Create(AName: QStringW; AFormClass: TFormClass;
  AIsMultiInstance: Boolean);
begin
  inherited Create(NewId, AName);
  FFormClass := AFormClass;
  FIsMultiInstance := AIsMultiInstance;
end;

destructor TQVCLFormService.Destroy;
begin
  if Assigned(FForm) then
  begin
    Undock;
    DisableRefCount; // 禁用引用计数
    if FClosing then
    begin
      SetProp(FForm.Handle, SFormNeedFree, 1);
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

procedure TQVCLFormService.DoActivate(ASender: TObject);
begin
  if Assigned(FOldOnActivate) then
    FOldOnActivate(ASender);
  if Assigned(FEvents.OnActivate) then
    FEvents.OnActivate(Self);
end;

procedure TQVCLFormService.DoCanClose(ASender: TObject; var ACanClose: Boolean);
begin
  if Assigned(FOldCanClose) then
    FOldCanClose(ASender, ACanClose);
  if Assigned(FEvents.CanClose) then
    FEvents.CanClose(Self, ACanClose);
end;

procedure TQVCLFormService.DockTo(AHandle: THandle; Align: TFormAlign);
begin
  FormAlign := Align;
  DockTo(AHandle, Rect(0, 0, 0, 0));
end;

procedure TQVCLFormService.DockTo(AHandle: THandle; const ARect: TRect);
var
  AParent: TWinControl;

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
  type
    TWinControlMethod = procedure of object;
  var
    ACtrlMethod, AFormMethod: TWinControlMethod;
  begin
    ACtrlMethod := AParent.UpdateControlState;
    AFormMethod := FForm.UpdateControlState;
    // 如果控件和窗体位于同一个模块中，不需要额外处理，直接Dock就行
    Result := Assigned(AParent) and
      (FindHInstance(TMethod(ACtrlMethod).Code)
      = FindHInstance(TMethod(AFormMethod).Code));
  end;
  function IsEmptyRect(const R: TRect): Boolean;
  begin
    Result := (R.Right <= R.Left) or (R.Bottom <= R.Top);
  end;

begin
  if FormNeeded then
  begin
    AParent := FindControl(AHandle);
    if IsSharePackage then
    begin
      if RegisterFreeNotify then
      begin
        if IsEmptyRect(ARect) then
          FForm.Dock(AParent, FForm.BoundsRect)
        else
          FForm.Dock(AParent, ARect);
        FForm.Visible := True;
        FDockParent := AHandle;
        AdjustAlign;
      end;
    end
    else // 窗体和宿主的类型信息不在同一个模块内
    begin
      if RegisterFreeNotify then
      begin
        FForm.ParentWindow := AHandle;
        FForm.BorderStyle := bsNone;
        if FormAlign in [faCustom, faDefault, faNone] then
        begin
          if IsEmptyRect(ARect) then
            FForm.Dock(AParent, FForm.BoundsRect)
          else
            FForm.SetBounds(ARect.Left, ARect.Top, ARect.Right - ARect.Left,
              ARect.Bottom - ARect.Top);
        end;
        FForm.Visible := True;
        FDockParent := AHandle;
        AdjustAlign;
      end;
    end;
  end;
end;

procedure TQVCLFormService.DoClose(ASender: TObject; var Action: TCloseAction);
var
  AHandle: HWND;
begin
  FClosing := True;
  if FForm.HandleAllocated then
    AHandle := FForm.Handle
  else
    AHandle := 0;
  if Assigned(FOldOnClose) then
    FOldOnClose(ASender, Action);
  if Assigned(FEvents.OnClose) then
    FEvents.OnClose(Self, Action);
  // 检查窗体如果需要释放，则不要去管它
  if (AHandle <> 0) and (GetProp(AHandle, SFormNeedFree) = 1) then
    Action := caFree;
  FClosing := False;
end;

procedure TQVCLFormService.DoDeactivate(ASender: TObject);
begin
  if Assigned(FOldOnDeactivate) then
    FOldOnDeactivate(ASender);
  if Assigned(FEvents.OnDeactivate) then
    FEvents.OnDeactivate(Self);
end;

procedure TQVCLFormService.DoDockParentFree(AData: Pointer);
begin
  // Dock的父控件要被释放，要将WindowProc指回去，以避免
  if Assigned(FForm) then
    Undock;
end;

procedure TQVCLFormService.DoDockParentSizeChanged(AData: Pointer);
begin
  AdjustAlign;
end;

procedure TQVCLFormService.DoFormFree(AData: Pointer);
begin
  if Assigned(FForm) then
  begin
    Undock;
    UnlinkFormEvents;
    FForm := nil;
  end;
end;

procedure TQVCLFormService.DoFree(ASender: TObject);
var
  AFreeNotify: TQFormNotifyEvent;
begin
  if Assigned(FOldOnFree) then
    FOldOnFree(ASender);
  AFreeNotify := FEvents.OnFree;
  UnlinkFormEvents;
  FForm := nil;
  if Assigned(AFreeNotify) then
    AFreeNotify(Self);
end;

procedure TQVCLFormService.DoHide(ASender: TObject);
begin
  if Assigned(FOldOnHide) then
    FOldOnHide(ASender);
  if Assigned(FEvents.OnHide) then
    FEvents.OnHide(Self);
end;

procedure TQVCLFormService.DoResize(ASender: TObject);
begin
  if Assigned(FOldOnResize) then
    FOldOnResize(ASender);
  if Assigned(FEvents.OnResize) then
    FEvents.OnResize(Self);
end;

procedure TQVCLFormService.DoShow(ASender: TObject);
begin
  if Assigned(FOldOnShow) then
    FOldOnShow(ASender);
  if Assigned(FEvents.OnShow) then
    FEvents.OnShow(Self);
end;

function TQVCLFormService.FormNeeded: Boolean;
begin
  if not Assigned(FForm) then
  begin
    if not FIsMultiInstance then
      Form := FFormClass.Create(nil);
  end;
  Result := Assigned(FForm);
end;

procedure TQVCLFormService.GetBounds(var R: TRect);
begin
  if Assigned(FForm) then
    R := FForm.BoundsRect
  else
    FillChar(R, SizeOf(TRect), 0);
end;

function TQVCLFormService.GetDockParent: THandle;
begin
  Result := FDockParent;
end;

function TQVCLFormService.GetFormAlign: TFormAlign;
begin
  if FFormAlign = faDefault then
  begin
    if FormNeeded then
    begin
      case FForm.Align of
        alNone:
          FFormAlign := faNone;
        alTop:
          FFormAlign := faTop;
        alBottom:
          FFormAlign := faBottom;
        alLeft:
          FFormAlign := faLeft;
        alRight:
          FFormAlign := faRight;
        alClient:
          FFormAlign := faContent;
        alCustom:
          FFormAlign := faCustom;
      end
    end
    else
      FFormAlign := faDefault;
  end;
  Result := FFormAlign;
end;

function TQVCLFormService.GetHeight: Integer;
begin
  if FormNeeded then
    Result := FForm.Height
  else
    Result := 0;
end;

function TQVCLFormService.GetInstance: IQService;
begin
  if Assigned(FFormClass) then
  begin
    if FIsMultiInstance then
    begin
      Result := TQVCLFormService.Create(Name, FFormClass.Create(nil), Self);
    end
    else
    begin
      if not Assigned(FForm) then
        Form := FFormClass.Create(nil);
      Result := Self;
    end;
  end
  else
    Result := Self;
end;

function TQVCLFormService.GetModalResult: TModalResult;
begin
  if Assigned(FForm) then
    Result := FForm.ModalResult
  else
    Result := mrNone;
end;

function TQVCLFormService.GetOriginBottom: Integer;
begin
  Result := FFormOrigin.Bottom;
end;

function TQVCLFormService.GetOriginHeight: Integer;
begin
  Result := FFormOrigin.Bottom - FFormOrigin.Top;
end;

function TQVCLFormService.GetOriginLeft: Integer;
begin
  Result := FFormOrigin.Left;
end;

function TQVCLFormService.GetOriginRight: Integer;
begin
  Result := FFormOrigin.Right;
end;

function TQVCLFormService.GetOriginTop: Integer;
begin
  Result := FFormOrigin.Top;
end;

function TQVCLFormService.GetOriginWidth: Integer;
begin
  Result := FFormOrigin.Right - FFormOrigin.Left;
end;

function TQVCLFormService.GetWidth: Integer;
begin
  if FormNeeded then
    Result := FForm.Width
  else
    Result := 0;
end;

procedure TQVCLFormService.HookEvents(const AEvents: TQFormEvents);
begin
  FEvents := AEvents;
end;

function TQVCLFormService.IsMultiInstance: Boolean;
begin
  Result := Assigned(FFormClass) and FIsMultiInstance;
end;

procedure TQVCLFormService.ParentResized;
begin
  AdjustAlign;
end;

function TQVCLFormService.QueryInterface(const IID: TGuid; out Obj): HRESULT;
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

procedure TQVCLFormService.SendInput(var AInput: TQInputEvent);
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

procedure TQVCLFormService.SendToBack;
begin
  if FormNeeded then
    FForm.SendToBack;
end;

procedure TQVCLFormService.SetBounds(L, T, W, H: Integer);
begin
  if FormNeeded then
    FForm.SetBounds(L, T, W, H);
end;

procedure TQVCLFormService.SetForm(const Value: TForm);
  procedure BindService;
  var
    AHolder: TQFormServiceHolder;
    I: Integer;
  begin
    for I := 0 to Form.ComponentCount - 1 do
    begin
      if Form.Components[I] is TQFormServiceHolder then
      begin
        (Form.Components[I] as TQFormServiceHolder).FFormService := Self;
        Exit;
      end;
    end;
    AHolder := TQFormServiceHolder.Create(Form);
    AHolder.FFormService := Self;
  end;

begin
  if FForm <> Value then
  begin
    if Assigned(FForm) then
    begin
      UnlinkFormEvents;
      LocalFreeNotifyService.Unregister(DoFormFree);
    end;
    FForm := Value;
    if Assigned(FForm) then
    begin
      FFormOrigin := FForm.BoundsRect;
      LocalFreeNotifyService.RegisterFreeNotify(FForm.Handle, DoFormFree, nil);
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
      BindService;
    end;
  end;
end;

procedure TQVCLFormService.SetFormAlign(const AValue: TFormAlign);
begin
  if FFormAlign <> AValue then
  begin
    FFormAlign := AValue;
    if Assigned(FForm) and (AValue <> faDefault) then
    begin
      FForm.Align := alNone;
      AdjustAlign;
    end;
  end;
end;

procedure TQVCLFormService.SetHeight(const AValue: Integer);
begin
  if FormNeeded then
    FForm.Height := AValue;
end;

procedure TQVCLFormService.SetModalResult(const AValue: TModalResult);
begin
  if FormNeeded then
    FForm.ModalResult := AValue;
end;

procedure TQVCLFormService.SetWidth(const AValue: Integer);
begin
  if FormNeeded then
    FForm.Width := AValue;
end;

procedure TQVCLFormService.Show;
begin
  if FormNeeded then
  begin
    FForm.Show;
  end;
end;

procedure TQVCLFormService.ShowModal(AOnModalResult: TQFormModalResultHandler;
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

procedure TQVCLFormService.Undock;
begin
  if Assigned(FForm) then
  begin
    if FForm.FormStyle <> fsMDIChild then
      FForm.Hide;
    FForm.ParentWindow := 0;
    FForm.HostDockSite := nil;
    if Assigned(FFreeService) then
    begin
      FFreeService.Unregister(DoDockParentFree);
      FFreeService.Unregister(DoDockParentSizeChanged);
    end;
  end;
end;

procedure TQVCLFormService.UnhookEvents;
begin
  FillChar(FEvents, SizeOf(FEvents), 0);
end;

procedure TQVCLFormService.UnlinkFormEvents;
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
    FillChar(FEvents, SizeOf(TQFormEvents), 0);
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
  FreeAndNilObject(FNotifier);
  inherited;
end;

function TQFormNotifyService.InSameInstance(AHandle: THandle): Boolean;
type
  TComponentMethod = procedure of object;
var
  ACtrlMethod, ASelfMethod: TComponentMethod;
  ACtrl: TWinControl;
begin
  ACtrl := FindControl(AHandle);
  if Assigned(ACtrl) then
  begin
    ACtrlMethod := ACtrl.HandleNeeded;
    ASelfMethod := FNotifier.NoOp;
    Result := FindHInstance(TMethod(ACtrlMethod).Code)
      = FindHInstance(TMethod(ASelfMethod).Code);
  end
  else
    Result := False;
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

{ TQVCLTestService }

constructor TQVCLTestService.Create;
begin
  inherited Create(NewId, LocalVCLCtrlTestServiceName);
  IsVCLControlHook := IsVCLControl;
end;

destructor TQVCLTestService.Destroy;
begin
  IsVCLControlHook := nil;
  inherited;
end;

function TQVCLTestService.HasControl(AHandle: HWND): Boolean;
begin
  Result := FindControl(AHandle) <> nil;
end;

function TQVCLTestService.IsVCLControl(AHandle: HWND): Boolean;
var
  ATestService: IQVCLTestService;
  I: Integer;
  procedure DebugWindow(AWnd: HWND);
  var
    AName, AText: array [0 .. 255] of Char;
  begin
    GetClassName(AWnd, @AName, 256);
    GetWindowText(AWnd, @AText, 256);
    OutputDebugString(PChar('ClassName：' + PChar(@AName) + ',Text=' +
      PChar(@AText)));
  end;

begin
  DebugWindow(AHandle);
  Result := False;
  if not Assigned(VCLCtrlTestServices) then
    VCLCtrlTestServices := PluginsManager.ByPath(PQCharW(VCLControlTestRoot))
      as IQServices;
  if Assigned(VCLCtrlTestServices) then
  begin
    for I := 0 to VCLCtrlTestServices.Count - 1 do
    begin
      if Supports(VCLCtrlTestServices[I], IQVCLTestService, ATestService) then
      begin
        Result := ATestService.HasControl(AHandle);
        if Result then
          Break;
      end;
    end;
  end;
end;

{ TQFormNotifier }

procedure TQFormNotifier.AddHook(ACtrl: TWinControl);
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
  while FControlHooks.Count > 0 do
    RemoveHook(TQControlHook(FControlHooks[0]).FControl);
  FreeAndNilObject(FControlHooks);
  FreeAndNilObject(FNotifications);
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

procedure TQFormNotifier.DoParentFormFree(AData: Pointer);
begin
  RemoveHook(AData);
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
  begin
    RemoveHook(AItem.Control);
    if not(AItem.Control is TForm) then
      RemoveHook(GetParentForm(AItem.Control, False));
  end;
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

function TQFormNotifier.NewItem(ACtrl: TWinControl): PQFormNotify;
begin
  New(Result);
  Result.CtrlHandle := ACtrl.Handle;
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
  // No op needed
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
    if AItem.CtrlHandle = AParent then
      DoNotifies(AItem.FSizeNotifies);
  end;
end;

procedure TQFormNotifier.RegisterFreeNotification(AHandle: THandle;
  AOnFree: TQFormNotifyProc; AData: Pointer);
var
  AItem: PQFormNotify;
  I: Integer;
  ACtrl: TWinControl;
begin
  ACtrl := FindControl(AHandle);
  if Assigned(ACtrl) then
  begin
    I := IndexOf(ACtrl);
    if I = -1 then
      AItem := NewItem(ACtrl)
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
  ACtrl: TWinControl;
begin
  ACtrl := FindControl(AHandle);
  if Assigned(ACtrl) then
  begin
    I := IndexOf(ACtrl);
    if I = -1 then
      AItem := NewItem(ACtrl)
    else
      AItem := FNotifications[I];
    if not Assigned(AItem.FSizeNotifies.First) then
    begin
      AddHook(ACtrl);
      if not(ACtrl is TForm) then
        AddHook(GetParentForm(ACtrl, False));
    end;
    AddNotifyProc(AItem.FSizeNotifies, AOnSizeChanged, AData);
  end;
end;

procedure TQFormNotifier.RemoveHook(ACtrl: TWinControl);
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
        FreeAndNilObject(AHook);
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
begin
  for I := 0 to FNotifications.Count - 1 do
  begin
    AItem := FNotifications[I];
    if RemoveNotifyProc(AItem.FSizeNotifies, AProc) then
    begin
      if not Assigned(AItem.FSizeNotifies.First) then
      begin
        RemoveHook(AItem.Control);
        if not(AItem.Control is TForm) then
          RemoveHook(GetParentForm(AItem.Control, False));
      end;
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

constructor TQControlHook.Create(ACtrl: TWinControl);
begin
  inherited Create;
  FControl := ACtrl;
  FLastWndProc := ACtrl.WindowProc;
  if ACtrl is TForm then
    ACtrl.WindowProc := HackedFormProc
  else
    ACtrl.WindowProc := HackedControlProc;
end;

destructor TQControlHook.Destroy;
begin
  FControl.WindowProc := FLastWndProc;
  inherited;
end;

procedure TQControlHook.HackedControlProc(var AMsg: TMessage);
var
  AWMPosChanged: TWMWindowPosChanged absolute AMsg;
begin
  FLastWndProc(AMsg);
  if AMsg.Msg = WM_WINDOWPOSCHANGED then
  begin
    if (AWMPosChanged.WindowPos.flags and SWP_NOSIZE) = 0 then
    begin
      if Assigned(LocalFreeNotifyService) then
        LocalFreeNotifyService.ParentSizeChanged(FControl.Handle);
    end;
  end;
end;

function DoSetChildWindowFocus(AWnd: HWND; AParam: LParam): Boolean; stdcall;
begin
  if (not PBoolean(AParam)^) and IsWindowVisible(AWnd) and IsWindowEnabled(AWnd)
  then
  begin
    SetFocus(AWnd);
    Result := False;
    PBoolean(AParam)^ := True;
  end
  else
    Result := True;
end;

procedure TQControlHook.HackedFormProc(var AMsg: TMessage);
  procedure SelectFirstChild(AHandle: HWND);
  var
    AIsSet: Boolean;
  begin
    AIsSet := False;
    EnumChildWindows(AHandle, @DoSetChildWindowFocus, LParam(@AIsSet));
  end;
  procedure HackedTab;
  var
    AWMDialogKey: TCMDialogKey absolute AMsg;
    AList: TList;
    I, StartIndex: Integer;
    CurControl: TWinControl;
    AForm: TForm;
    GoForward: Boolean;
  begin
    if GetKeyState(VK_MENU) >= 0 then
    begin
      if AWMDialogKey.CharCode = VK_TAB then
      begin
        if GetKeyState(VK_CONTROL) >= 0 then
        begin
          AForm := (FControl as TForm);
          CurControl := AForm.ActiveControl;
          GoForward := GetKeyState(VK_SHIFT) >= 0;
          AList := TList.Create;
          try
            AForm.GetTabOrderList(AList);
            if AList.Count > 0 then
            begin
              StartIndex := AList.IndexOf(CurControl);
              if StartIndex = -1 then
              begin
                if GoForward then
                  StartIndex := AList.Count - 1
                else
                  StartIndex := 0;
              end;
              I := StartIndex;
              repeat
                if GoForward then
                begin
                  Inc(I);
                  if I = AList.Count then
                    I := 0;
                end
                else
                begin
                  if I = 0 then
                    I := AList.Count;
                  Dec(I);
                end;
                CurControl := TWinControl(AList[I]);
                if CurControl.CanFocus and CurControl.TabStop then
                begin
                  if CurControl is TPageControl then
                  // 如果是PageControl，则尝试定位到当前页的第一个子窗体，暂时非完美实现
                  begin
                    if Assigned(TPageControl(CurControl).ActivePage) then
                    begin
                      SelectFirstChild(TPageControl(CurControl)
                        .ActivePage.Handle);
                      Break;
                    end;
                  end
                  else
                    CurControl.SetFocus;
                  Break;
                end;
              until (I = StartIndex);
            end;
            AMsg.Result := 1;
            Exit;
          finally
            FreeAndNilObject(AList);
          end;
        end;
      end;
    end;
    FLastWndProc(AMsg);
  end;

begin
  if AMsg.Msg = CM_DIALOGKEY then
    HackedTab
  else
    FLastWndProc(AMsg);
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

initialization

LocalFreeNotifyService := TQFormNotifyService.Create;
LocalFreeNotifyServiceName := (LocalFreeNotifyService as IQService).Name;
RegisterServices(PQCharW(FreeNotificationRoot),
  [LocalFreeNotifyService as IQService]);
LocalVCLCtrlTestService := TQVCLTestService.Create;
RegisterServices(PQCharW(VCLControlTestRoot),
  [LocalVCLCtrlTestService as IQService]);
VCLCtrlTestServices := nil;

finalization

VCLCtrlTestServices := nil;
LocalVCLCtrlTestService := nil;
UnregisterServices(PQCharW(FreeNotificationRoot), [LocalFreeNotifyServiceName]);
UnregisterServices(PQCharW(VCLControlTestRoot), ['IsVCLControl']);
LocalFreeNotifyService.Clear;
LocalFreeNotifyService := nil;

end.
