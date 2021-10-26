unit qplugins_formsvc;

interface

{$I 'qdac.inc'}

uses classes, sysutils, types, qstring, qplugins,qplugins_base,
  qplugins_params{$IF RTLVERSION<23}, controls, forms{$ELSE}, uitypes{$IFEND};
{$HPPEMIT '#pragma link "qplugins_formsvc"'}

type
  // 本单元只支持 Delphi/C++ Builder
  IQFormService = interface;

  /// <summary>
  /// 窗体显示模态对话框时的回调函数
  /// </summary>
  TQFormModalResultHandler = procedure(ASender: IQFormService; ATag: IQParams)
    of object;

  /// <summary>
  /// 窗体CanClose事件的接口版
  /// </summary>
  TQFormCloseQueryEvent = procedure(ASender: IQFormService;
    var ACanClose: Boolean) of object;
  /// <summary>
  /// 窗体OnClose事件的接口版
  /// </summary>
  TQFormCloseEvent = procedure(ASender: IQFormService; var Action: TCloseAction)
    of object;
  /// <summary>
  /// 窗体通知事件的接口版
  /// </summary>
  TQFormNotifyEvent = procedure(ASender: IQFormService) of object;

  /// <summary>
  /// 键盘按键状态
  /// </summary>
  TQKeyState = record
  private
    FFlags: Byte;
    function GetFlags(const Index: Integer): Boolean;
    procedure SetFlags(const Index: Integer; const Value: Boolean);
  public
    property LeftShiftDown: Boolean index 0 read GetFlags write SetFlags;
    property RightShiftDown: Boolean index 1 read GetFlags write SetFlags;
    property LeftCtrlDown: Boolean index 2 read GetFlags write SetFlags;
    property RightCtrlDown: Boolean index 3 read GetFlags write SetFlags;
    property LeftAltDown: Boolean index 4 read GetFlags write SetFlags;
    property RightAltDown: Boolean index 5 read GetFlags write SetFlags;
    property LeftWinDown: Boolean index 2 read GetFlags write SetFlags;
    property RightWinDown: Boolean index 2 read GetFlags write SetFlags;
  end;

  /// <summary>
  /// 键盘数据
  /// </summary>
  TQKeyData = record
    IsDown: Boolean;
    Key: Byte;
  end;

  /// <summary>
  /// 鼠标按钮
  /// </summary>
  TQMouseButton = (
    /// <summary>
    /// 左键
    /// </summary>
    vmbLeft,
    /// <summary>
    /// 右键
    /// </summary>
    vmbRight,
    /// <summary>
    /// 中间键
    /// </summary>
    vmbMiddle,
    /// <summary>
    /// X键
    /// </summary>
    vmbX);

  /// <summary>
  /// 鼠标输入数据
  /// </summary>
  TQMouseData = record
    Pos: TSmallPoint; // 鼠标位置
    WheelData: Cardinal; // 滚动数据
    Events: Word;
  end;

  /// <summary>
  /// 模拟输入类型的事件类型
  /// </summary>
  TQInputEventType = (
    /// <summary>
    /// 鼠标
    /// </summary>
    ietMouse,
    /// <summary>
    /// 键盘
    /// </summary>
    ietKeyboad);

  /// <summary>
  /// 输入事件定义
  /// </summary>
  TQInputEvent = record
    Shifts: TQKeyState;
    EventType: TQInputEventType;
    case Integer of
      0:
        (Mouse: TQMouseData);
      1:
        (Key: TQKeyData);
  end;

  // 暂时先关联这几个事件
  TQFormEvents = record
    CanClose: TQFormCloseQueryEvent;
    OnClose: TQFormCloseEvent;
    OnFree: TQFormNotifyEvent;
    OnActivate: TQFormNotifyEvent;
    OnDeactivate: TQFormNotifyEvent;
    OnResize: TQFormNotifyEvent;
    OnShow: TQFormNotifyEvent;
    OnHide: TQFormNotifyEvent;
  end;

  TQFormNotifyProc = procedure(AData: Pointer) of object;

  /// <summary>
  /// 窗体或其所关联的组件的释放通知管理接口
  /// </summary>
  IQFreeNotifyService = interface
    ['{375027FB-185B-44C4-B3C5-1ABAE344ABBE}']
    procedure RegisterFreeNotify(AHandle: THandle; AOnFree: TQFormNotifyProc;
      AData: Pointer);
    procedure RegisterSizeNotify(AHandle: THandle; AOnResize: TQFormNotifyProc;
      AData: Pointer);
    procedure Unregister(AOnFree: TQFormNotifyProc);
    function InSameInstance(AHandle: THandle): Boolean;
    procedure ParentSizeChanged(AParent: THandle);
    procedure Clear;
  end;

  /// <summary>
  /// 用户自定义参数动作接口，可以通过它调用服务的自定义方法
  /// </summary>
  IQCustomAction = interface
    ['{E367142F-B866-4419-9AC1-A29F0D43DA5F}']
    function DoAction(AParams: IQParams; AResult: IQParams = nil): Boolean;
  end;

  /// <summary>
  /// 窗体在Dock时的对齐方式
  /// </summary>
  TFormAlign = (
    /// <summary>
    /// 不处理对齐
    /// </summary>
    faNone,
    /// <summary>
    /// 窗体默认定义，取决于其Align属性的值
    /// </summary>
    faDefault,
    /// <summary>
    /// 水平居左，垂直居上
    /// </summary>
    faLeftTop,
    /// <summary>
    /// 水平居中，垂直居上
    /// </summary>
    faCenterTop,
    /// <summary>
    /// 水平填充， 垂直居上
    /// </summary>
    faTop,
    /// <summary>
    /// 水下居右，垂直居上
    /// </summary>
    faRightTop,
    /// <summary>
    /// 水平居右，垂直居中
    /// </summary>
    faRightCenter,
    /// <summary>
    /// 水平居中，垂直填充
    /// </summary>
    faRight,
    /// <summary>
    /// 水平居右，垂直居下
    /// </summary>
    faRightBottom,
    /// <summary>
    /// 水平居中，垂直居下
    /// </summary>
    faCenterBottom,
    /// <summary>
    /// 水平填充，垂直居下
    /// </summary>
    faBottom,
    /// <summary>
    /// 水平居左，垂直居下
    /// </summary>
    faLeftBottom,
    /// <summary>
    /// 水平居左，垂直填充
    /// </summary>
    faLeft,
    /// <summary>
    /// 水平居左，垂直居中
    /// </summary>
    faLeftCenter,
    /// <summary>
    /// 填充内容区
    /// </summary>
    faContent,
    /// <summary>
    /// 居中
    /// </summary>
    faCenter,
    /// <summary>
    /// 水平填充，垂直不变
    /// </summary>
    faHoriz,
    /// <summary>
    /// 垂直填充，水平不变
    /// </summary>
    faVert,
    /// <summary>
    /// 用户自定义
    /// </summary>
    faCustom);

  /// <summary>
  /// 窗体服务的接口
  /// </summary>
  IQFormService = interface
    ['{8B1FC131-122E-4961-9A85-833DF892AC1A}']
    /// <summary>
    /// 显示一个模态对话框
    /// </summary>
    /// <param name="AOnModalResult">
    /// 当关闭窗口时的回调函数
    /// </param>
    /// <param name="ATag">
    /// 用户附加的额外参数，在AOnModalResult时会传递给用户过程
    /// </param>
    procedure ShowModal(AOnModalResult: TQFormModalResultHandler = nil;
      ATag: IQParams = nil);
    /// <summary>
    /// 显示一个非模态对话框
    /// </summary>
    procedure Show;

    /// <summary>
    /// 提前窗口
    /// </summary>
    procedure BringToFront;
    /// <summary>
    /// 后置窗口
    /// </summary>
    procedure SendToBack;
    /// <summary>
    /// 设置窗体位置大小
    /// </summary>
    procedure SetBounds(L, T, W, H: Integer);
    /// <summary>
    /// 获取窗体位置及大小
    /// </summary>
    procedure GetBounds(var R: TRect);
    /// <summary>
    /// 嵌入窗体到父窗口的特定的位置
    /// </summary>
    /// <param name="AHandle">
    /// 父控件的窗口句柄
    /// </param>
    /// <param name="ARect">
    /// 要绑定的位置区域
    /// </param>
    procedure DockTo(AHandle: THandle; const ARect: TRect); overload;
    /// <summary>
    /// 嵌入窗体到父窗口的特定的位置
    /// </summary>
    /// <param name="AHandle">
    /// 父控件的窗口句柄
    /// </param>
    /// <param name="Align">
    /// 对齐方式
    /// </param>
    procedure DockTo(AHandle: THandle; Align: TFormAlign); overload;
    /// <summary>
    /// 取消窗体的嵌入
    /// </summary>
    procedure Undock;
    /// <summary>
    /// 发送模拟输入按键或鼠标动作给当前的窗体
    /// </summary>
    procedure SendInput(var AInput: TQInputEvent);
    /// <summary>
    /// 挂接服务关联的窗口事件
    /// </summary>
    procedure HookEvents(const AEvents: TQFormEvents);
    /// <summary>
    /// 移除到服务关联事件的监听
    /// </summary>
    procedure UnhookEvents;
    /// <summary>
    /// 设置窗体的ModalReslt值
    /// </summary>
    function GetModalResult: TModalResult;
    /// <summary>
    /// 设置窗体的ModalResult值
    /// </summary>
    procedure SetModalResult(const AValue: TModalResult);
    /// <summary>
    /// 是否是多实例服务
    /// </summary>
    function IsMultiInstance: Boolean;
    /// <summary>
    /// 获取窗体的宽度
    /// </summary>
    function GetWidth: Integer;
    /// <summary>
    /// 设置窗体的宽度
    /// </summary>
    procedure SetWidth(const AValue: Integer);
    /// <summary>
    /// 获取窗体的高度
    /// </summary>
    function GetHeight: Integer;
    /// <summary>
    /// 设置窗体的高度
    /// </summary>
    procedure SetHeight(const AValue: Integer);
    /// <summary>
    /// 获取窗体的对齐方式
    /// </summary>
    function GetFormAlign: TFormAlign;
    /// <summary>
    /// 设置窗体的对齐方式
    /// </summary>
    procedure SetFormAlign(const AValue: TFormAlign);

    /// <summary>
    /// Dock时，如果父大小调整时触发
    /// </summary>
    procedure ParentResized;
    /// <summary>
    /// 在执行进一步操作前，确认Form是否创建
    /// </summary>
    function FormNeeded: Boolean;
    /// <summary>
    /// 获取 DockTo 时的父句柄
    /// </summary>
    function GetDockParent: THandle;
    ///<summary>
    ///  关闭窗口
    ///</summary>
    procedure Close;
    property ModalResult: TModalResult read GetModalResult write SetModalResult;
    property Width: Integer read GetWidth write SetWidth;
    property Height: Integer read GetHeight write SetHeight;
    property Align: TFormAlign read GetFormAlign write SetFormAlign;
    property DockParent: THandle read GetDockParent;
  end;

  /// <summary>

  /// IQFormService的实现基类，VCL和FMX分别实现了具体的类型。VCL程序请引用qplugins.vcl.formsvc单元，FMX程序请引用qplugins.fmx.formsvc，然后调用RegisterFormService来注册具体的服务
  /// </summary>
  /// <remarks>
  /// 不要试图创建 TQFormService类型的实例，否则会出现Abstract Error。
  /// </remarks>
  TQFormService = class(TQService, IQFormService)
  protected
    procedure InternalModalResult(ASender: IQFormService; ATag: IQParams);
    function GetWidth: Integer; virtual; abstract;
    procedure SetWidth(const AValue: Integer); virtual; abstract;
    function GetHeight: Integer; virtual; abstract;
    procedure SetHeight(const AValue: Integer); virtual; abstract;
    function GetFormAlign: TFormAlign; virtual; abstract;
    procedure SetFormAlign(const AValue: TFormAlign); virtual; abstract;
    procedure ParentResized; virtual; abstract;
    function FormNeeded: Boolean; virtual; abstract;
    function GetDockParent: THandle; virtual; abstract;
  public
    function Execute(AParams: IQParams; AResult: IQParams): Boolean; override;
    procedure ShowModal(AOnModalResult: TQFormModalResultHandler;
      ATag: IQParams); virtual; abstract;
    procedure Show; virtual; abstract;
    procedure BringToFront; virtual; abstract;
    procedure SendToBack; virtual; abstract;
    procedure SetBounds(L, T, W, H: Integer); virtual; abstract;
    procedure GetBounds(var R: TRect); virtual; abstract;
    procedure DockTo(AHandle: THandle; const ARect: TRect); overload;
      virtual; abstract;
    procedure DockTo(AHandle: THandle; Align: TFormAlign); overload;
      virtual; abstract;
    procedure Undock; virtual; abstract;
    procedure SendInput(var AInput: TQInputEvent); virtual; abstract;
    procedure HookEvents(const AEvents: TQFormEvents); virtual; abstract;
    procedure UnhookEvents; virtual; abstract;
    procedure Close; virtual;abstract;
    function IsMultiInstance: Boolean; virtual; abstract;
    function GetModalResult: TModalResult; virtual; abstract;
    procedure SetModalResult(const AValue: TModalResult); virtual; abstract;
  end;

implementation
{$IFDEF MSWINDOWS}
var
  hGdiPlus:HMODULE;

{$ENDIF}
{ TQFormService }


function TQFormService.Execute(AParams, AResult: IQParams): Boolean;
var
  AName: QStringW;
  procedure DoGetBounds;
  var
    R: TRect;
  begin
    if Assigned(AResult) then
    begin
      GetBounds(R);
      AResult.Add('Left', ptInt32).AsInteger := R.Left;
      AResult.Add('Top', ptInt32).AsInteger := R.Top;
      AResult.Add('Right', ptInt32).AsInteger := R.Right;
      AResult.Add('Bottom', ptInt32).AsInteger := R.Bottom;
    end;
  end;
  procedure DoCustomAction;
  var
    ATemp: TQParams;
    ACustomAction: IQCustomAction;
  begin
    if Supports(Self, IQCustomAction, ACustomAction) then
    begin
      ATemp := TQParams.Create;
      ATemp.AddRange(AParams, 1, AParams.Count - 1);
      ACustomAction.DoAction(ATemp, AResult);
    end;
  end;

begin
  Result := False;
  AName := ParamAsString(AParams[0]);
  if StrCmpW(PQCharW(AName), 'ShowModal', True) = 0 then // Show Modal
  begin
    ShowModal(InternalModalResult, AResult);
    Result := True;
  end
  else if StrCmpW(PQCharW(AName), 'Show', True) = 0 then
  begin
    Show;
    Result := True;
  end
  else if StrCmpW(PQCharW(AName), 'BringToFront', True) = 0 then
  begin
    BringToFront;
    Result := True;
  end
  else if StrCmpW(PQCharW(AName), 'SendToBack', True) = 0 then
  begin
    SendToBack;
    Result := True;
  end
  else if StrCmpW(PQCharW(AName), 'SetBounds', True) = 0 then
  begin
    if AParams.Count = 5 then
    begin
      SetBounds(AParams[1].AsInteger, AParams[2].AsInteger,
        AParams[3].AsInteger, AParams[4].AsInteger);
      Result := True;
    end
  end
  else if StrCmpW(PQCharW(AName), 'GetBounds', True) = 0 then
  begin
    DoGetBounds;
    Result := True;
  end
  else if StrCmpW(PQCharW(AName), 'DockTo', True) = 0 then
  begin
    if AParams.Count = 6 then // Name,Handle,Left,Top,Right,Bottom
    begin
      DockTo(AParams[1].AsInt64, Rect(AParams[2].AsInteger,
        AParams[3].AsInteger, AParams[4].AsInteger, AParams[5].AsInteger));
      Result := True;
    end
  end
  else if StrCmpW(PQCharW(AName), 'Undock', True) = 0 then
  begin
    Undock;
    Result := True;
  end
  else if StrCmpW(PQCharW(AName), 'IsMultiInstance', True) = 0 then
  begin
    if Assigned(AResult) then
    begin
      AResult.Add('IsMultiInstance', ptBoolean).AsBoolean := IsMultiInstance;
      Result := True;
    end
  end
  else if StrCmpW(PQCharW(AName), 'GetModalResult', True) = 0 then
  begin
    if Assigned(AResult) then
    begin
      AResult.Add('ModalResult', ptInt32).AsInteger := GetModalResult;
      Result := True;
    end
  end
  else if StrCmpW(PQCharW(AName), 'SetModalResult', True) = 0 then
  begin
    if AParams.Count = 2 then // Name,ModalResult
    begin
      SetModalResult(AParams[1].AsInteger);
      Result := True;
    end
  end
  else if StrCmpW(PQCharW(AName), 'CustomAction', True) = 0 then
  begin
    DoCustomAction;
    Result := True;
  end
  else // 不支持其它功能
    Result := False;
end;

procedure TQFormService.InternalModalResult(ASender: IQFormService;
  ATag: IQParams);
begin
  if Assigned(ATag) then
    ATag.Add('ModalResult', ptInt32).AsInteger := Integer(ASender.ModalResult);
end;

{ TQKeyState }

function TQKeyState.GetFlags(const Index: Integer): Boolean;
begin
  Result := (FFlags and (1 shl Index)) <> 0;
end;

procedure TQKeyState.SetFlags(const Index: Integer; const Value: Boolean);
begin
  if Value then
    FFlags := FFlags or (1 shl Index)
  else
    FFlags := FFlags and (not(1 shl Index));
end;
{$IFDEF MSWINDOWS}
function GdipAlloc: pointer; stdcall; external 'gdiplus.dll' name 'GdipAlloc';

{$ENDIF}

end.
