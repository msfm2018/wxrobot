unit qdialog_builder;

interface

{
  QDialogBuilder VCL 版，FMX 版本暂时没工夫提供
  ===============================================
  QDialogBuilder 用于构建自定义的对话框，依赖于 QJson 以提供 JSON 格式的属性支持。
  1、使用教程：http://blog.qdac.cc/?p=4959
  2、
}
uses classes, sysutils, types, controls, stdctrls, extctrls, graphics, forms,
  windows, messages, AppEvnts;

const
  CDF_ALWAYS_CLOSABLE = $80000000; // 是否总是允许显示关闭按钮
  CDF_TIMEOUT = $40000000; // 倒计时关闭
  CDF_DISPLAY_REMAIN_TIME = $20000000; // 是否在标题栏显示倒计时
  CDF_MASK_TIMEOUT = $FFFF; //

type
  IBaseDialogItem = interface;
  IDialogBuilder = interface;
  IDialogContainer = interface;
  // 对话框通知事件，分别对应子项添加、子项删除、父项变更、项目变更
  TDialogNotifyEvent = (dneItemAdded, dneItemRemoved, dneParentChanged,
    dneItemChanged);
  // 子项对齐方式：按行居上，按行居中，按行居下，按列居左，按列居中，按列居右
  TDialogItemAlignMode = (amVertTop, amVertCenter, amVertBottom, amHorizLeft,
    amHorizCenter, amHorizRight);
{$IFDEF UNICODE}
  // TNotifyEvent 的匿名版本
  TNotifyCallback = reference to procedure(Sender: TObject);
{$ENDIF}

  // 项目分组列表接口，只支持枚举，添加和移除是通过设置对应的 GroupName 自动完成的
  IDialogItemGroup = interface
    ['{299F037F-2EDB-4677-A950-A05B9CCE3137}']
    // 项目数量
    function GetCount: Integer;
    // 获取单项
    function GetItems(const AIndex: Integer): IBaseDialogItem;
    property Count: Integer read GetCount;
    property Items[const AIndex: Integer]: IBaseDialogItem
      read GetItems; default;
  end;

  // 基本项目定义
  IBaseDialogItem = interface
    ['{3C247227-5BF6-4DE8-BB4D-A4A574FE929B}']
    // 项目位置信息
    function GetBounds: TRect;
    procedure SetBounds(const R: TRect);
    // 计算项目大小
    function CalcSize: TSize;
    // 分组名读写
    function GetGroupName: String;
    procedure SetGroupName(const Value: String);
    // 父项目容器
    function GetParent: IDialogContainer;
    procedure SetParent(const Value: IDialogContainer);
    // 接受通知处理
    procedure Notify(ASender: IBaseDialogItem; AEvent: TDialogNotifyEvent);
    // 关联的 IDialogBuilder 对象
    function GetBuilder: IDialogBuilder;
    // 关联的分组
    function GetGroup: IDialogItemGroup;
    // 尺寸信息
    function GetWidth: Integer;
    procedure SetWidth(const AValue: Integer);
    function GetHeight: Integer;
    procedure SetHeight(const AValue: Integer);
    property Bounds: TRect read GetBounds write SetBounds;
    property GroupName: String read GetGroupName write SetGroupName;
    property Parent: IDialogContainer read GetParent write SetParent;
    property Builder: IDialogBuilder read GetBuilder;
    property Group: IDialogItemGroup read GetGroup;
    property Width: Integer read GetWidth write SetWidth;
    property Height: Integer read GetHeight write SetHeight;
  end;

  // 关联控件的对话框项目，通过容器的 AddControl 添加
  IControlDialogItem = interface(IBaseDialogItem)
    ['{44E207B3-080C-4A45-BFE0-286D9B8222D5}']
    // 关联控件
    function GetControl: TControl;
    // OnClick 事件响应 ，其它事件响应请直接设置Control的相关事件
    function GetOnClick: TNotifyEvent;
    procedure SetOnClick(const AValue: TNotifyEvent);
    // 基于JSON的属性定义
    function GetPropText: String;
    procedure SetPropText(const AValue: String);
    property PropText: String read GetPropText write SetPropText;
    property Control: TControl read GetControl;
    property OnClick: TNotifyEvent read GetOnClick write SetOnClick;
  end;

  // 关联控件容器接口
  IDialogContainer = interface(IControlDialogItem)
    ['{91EBE933-1AA0-45E0-8C1D-7B57578FA2B8}']
    // 添加项目
    function Add(const AItem: IBaseDialogItem): IDialogContainer;
    // 添加一下控件项目，注意有些控件并不能自动调整合适的大小，需要赋值
    function AddControl(AClass: TControlClass; APropText: String = '')
      : IControlDialogItem; overload;
{$IFDEF UNICODE}
    function AddControl(AClass: TControlClass; AOnClick: TNotifyCallback;
      APropText: String = ''): IControlDialogItem; overload;
{$ENDIF}
    // 添加一个子容器
    function AddContainer(AlignMode: TDialogItemAlignMode): IDialogContainer;
    // 删除某一子项
    procedure Delete(const AIndex: Integer);
    // 清空所有子项
    procedure Clear;
    // 获取子项
    function GetItems(const AIndex: Integer): IBaseDialogItem;
    // 获取子项数
    function GetCount: Integer;
    // 对齐方式
    function GetAlignMode: TDialogItemAlignMode;
    procedure SetAlignMode(AMode: TDialogItemAlignMode);
    // 重新对齐
    procedure Realign;
    // 自动调整大小
    function GetAutoSize: Boolean;
    procedure SetAutoSize(const AValue: Boolean);
    // 子项间隔大小
    function GetItemSpace: Integer;
    procedure SetItemSpace(const V: Integer);
    property AlignMode: TDialogItemAlignMode read GetAlignMode
      write SetAlignMode;
    property AutoSize: Boolean read GetAutoSize write SetAutoSize;
    property Count: Integer read GetCount;
    property Items[const AIndex: Integer]: IBaseDialogItem
      read GetItems; default;
    property ItemSpace: Integer read GetItemSpace write SetItemSpace;

  end;
  // 对话框关闭时的通知事件
{$IFDEF UNICODE}

  TDialogResultCallback = reference to procedure(ABuilder: IDialogBuilder);
{$ENDIF}
  TDialogResultEvent = procedure(ABuilder: IDialogBuilder) of object;

  // 对话框构建工具
  IDialogBuilder = interface(IDialogContainer)
    ['{3E33A340-A664-4110-B257-061F2B8B4E3C}']
    // ModalResult
    function GetModalResult: TModalResult;
    procedure SetModalResult(const AModalResult: TModalResult);
    // 变更分组为新名称
    procedure ChangeGroup(AItem: IBaseDialogItem; ANewName: String);
    // 组内广播事件
    procedure GroupCast(ASender: IBaseDialogItem; AEvent: TDialogNotifyEvent);
    // 获取指定名称分组
    function GroupByName(const AName: String): IDialogItemGroup;
    // 显示模态对话框
    procedure ShowModal(); overload;
    // 在指定的控件位置弹出，会优先采用下拉的方式，避开控件本身的区域
    procedure Popup(AControl: TControl); overload;
    // 在指定的位置弹出
    procedure Popup(APos: TPoint); overload;
    // 显示前需要重新对齐
    procedure RequestAlign;
    // 关联的窗体对象
    function GetDialog: TForm;
    // 关闭通知事件
    function GetOnResult: TDialogResultEvent;
    procedure SetOnResult(AEvent: TDialogResultEvent);
{$IFDEF UNICODE}
    procedure Popup(AControl: TControl;
      ACallback: TDialogResultCallback); overload;
    procedure Popup(APos: TPoint; ACallback: TDialogResultCallback); overload;
    procedure ShowModal(ACallback: TDialogResultCallback); overload;
{$ENDIF}
    // Dialog的PropText定义，注意 Position 属性无效，在 ShowModal 里，始终是poScreenCenter
    function GetPropText: String;
    procedure SetPropText(const AValue: String);
    function GetCanClose: Boolean;
    procedure SetCanClose(const AValue: Boolean);
    function GetCloseDelay: Word;
    procedure SetCloseDelay(const ASeconds: Word);
    function GetDisplayRemainTime: Boolean;
    procedure SetDisplayRemainTime(const AValue: Boolean);
    property PropText: String read GetPropText write SetPropText;
    property ModalResult: TModalResult read GetModalResult write SetModalResult;
    property OnResult: TDialogResultEvent read GetOnResult write SetOnResult;
    property Dialog: TForm read GetDialog;
    property CanClose: Boolean read GetCanClose write SetCanClose;
    property CloseDelay: Word read GetCloseDelay write SetCloseDelay;
    property DisplayRemainTime: Boolean read GetDisplayRemainTime
      write SetDisplayRemainTime;
  end;

  TDialogIcon = (diNone, diWarning, diHelp, diError, diInformation, diShield);
  // 新建一个对话框接口，如果不指定标题，则为Application.Title
function NewDialog(ACaption: String = ''): IDialogBuilder;
function CustomDialog(const ACaption, ATitle, AMessage: String;
  AButtons: array of String; AIcon: TDialogIcon; AFlags: Integer = 0;
  const ACustomProps: String = ''): Integer; overload;
function CustomDialog(const ACaption, ATitle, AMessage: String;
  AButtons: array of String; AIconResId: Integer; AIconResFile: String;
  AIconSize: TSize; AFlags: Integer = 0; const ACustomProps: String = '')
  : Integer; overload;

implementation

uses qstring, qjson, typinfo;

type
  TDialogGroup = class(TInterfaceList, IDialogItemGroup)
    function GetItems(const AIndex: Integer): IBaseDialogItem;
  end;

  TBaseDialogItem = class(TInterfacedObject, IBaseDialogItem)
  protected
    FParent: IDialogContainer;
    FGroupName: String;
    FBuilder: IDialogBuilder;
    function GetBounds: TRect; virtual; abstract;
    procedure SetBounds(const R: TRect); virtual; abstract;
    function CalcSize: TSize; virtual;
    function GetGroupName: String;
    procedure SetGroupName(const Value: String);
    function GetParent: IDialogContainer;
    procedure SetParent(const Value: IDialogContainer);
    procedure Notify(ASender: IBaseDialogItem;
      AEvent: TDialogNotifyEvent); virtual;
    function GetBuilder: IDialogBuilder;
    function GetGroup: IDialogItemGroup;
    function GetWidth: Integer;
    procedure SetWidth(const AValue: Integer);
    function GetHeight: Integer;
    procedure SetHeight(const AValue: Integer);
  public
    constructor Create(ABuilder: IDialogBuilder); virtual;
    destructor Destroy; override;
    property Parent: IDialogContainer read FParent write SetParent;
    property Bounds: TRect read GetBounds write SetBounds;
    property GroupName: String read FGroupName write SetGroupName;
    property Builder: IDialogBuilder read FBuilder;
  end;

  TControlDialogItem = class(TBaseDialogItem, IControlDialogItem)
  protected
    FControl: TControl;
    FOnClick: TNotifyEvent;
    FPropText: String;
    procedure SetOnClick(const Value: TNotifyEvent);
    function GetBounds: TRect; override;
    procedure SetBounds(const R: TRect); override;
    function CalcSize: TSize; override;
    procedure Notify(ASender: IBaseDialogItem;
      AEvent: TDialogNotifyEvent); override;
    constructor Create(ABuilder: IDialogBuilder;
      ACtrlClass: TControlClass); overload;
    function GetControl: TControl;
    procedure DoClick(Sender: TObject);
    function GetOnClick: TNotifyEvent;
    function GetPropText: String;
    procedure SetPropText(const AValue: String);
  public
    constructor Create(ABuilder: IDialogBuilder); overload; override;
    destructor Destroy; override;
    property Control: TControl read FControl write FControl;
    property PropText: String read FPropText write SetPropText;
    property OnClick: TNotifyEvent read FOnClick write SetOnClick;
  end;

  TDialogContainer = class(TControlDialogItem, IDialogContainer)
  protected
    FItems: TList;
    FAlignMode: TDialogItemAlignMode;
    FAutoSize: Boolean;
    FItemSpace: Integer;
    function GetItems(const AIndex: Integer): IBaseDialogItem;
    function GetCount: Integer;
    function GetAlignMode: TDialogItemAlignMode;
    procedure SetAlignMode(AMode: TDialogItemAlignMode);
    function GetAutoSize: Boolean;
    procedure SetAutoSize(const AValue: Boolean);
    constructor Create(ABuilder: IDialogBuilder;
      ACtrlClass: TControlClass); overload;
    function GetItemSpace: Integer;
    procedure SetItemSpace(const V: Integer);
    function ItemSize: TSize;
  public
    constructor Create(ABuilder: IDialogBuilder); overload; override;
    destructor Destroy; override;
    function Add(const AItem: IBaseDialogItem): IDialogContainer;
    function AddControl(AClass: TControlClass; APropText: String = '')
      : IControlDialogItem; overload;
{$IFDEF UNICODE}
    function AddControl(AClass: TControlClass; AOnClick: TNotifyCallback;
      APropText: String = ''): IControlDialogItem; overload;
{$ENDIF}
    function AddContainer(AlignMode: TDialogItemAlignMode): IDialogContainer;
    procedure Delete(const AIndex: Integer);
    procedure Clear;
    procedure Realign; virtual;
    function CalcSize: TSize; override;
    property AutoSize: Boolean read FAutoSize write FAutoSize;
    property AlignMode: TDialogItemAlignMode read FAlignMode write FAlignMode;
    property Bounds: TRect read GetBounds write SetBounds;
    property ItemSpace: Integer read FItemSpace write FItemSpace;
  end;

  TDialogBuilderState = (dbsAlignRequest, dbsAligning, dbsPopup, dbsModal);
  TDialogBuilderStates = set of TDialogBuilderState;

  TDialogPopupHelper = class(TComponent)
  private
    FControl: TControl;
    FBuilder: IDialogBuilder;
    procedure Notification(AComponent: TComponent;
      Operation: TOperation); override;
    procedure SetBuilder(const Value: IDialogBuilder);
    procedure SetControl(const Value: TControl);
  public
    destructor Destroy; override;
    property Builder: IDialogBuilder read FBuilder write SetBuilder;
    property Control: TControl read FControl write SetControl;
  end;

  TDialogBuilder = class(TDialogContainer, IDialogBuilder)
  protected
    FDialog: TForm;
    FGroups: TStringList;
    FTimer: TTimer;
    FOnResult: TDialogResultEvent;
    FStates: TDialogBuilderStates;
    FAppEvents: TApplicationEvents;
    FLastDialogWndProc: TWndMethod;
    FPopupHelper: TDialogPopupHelper;
    FLastActiveWnd: THandle;
    FCloseDelay: Word;
    FCanClose: Boolean;
    FDisplayRemainTime: Boolean;
    FInitializeCaption: String;
    function GetGroups: TStrings;
    procedure ChangeGroup(AItem: IBaseDialogItem; ANewName: String);
    procedure GroupCast(ASender: IBaseDialogItem; AEvent: TDialogNotifyEvent);
    function GroupByName(const AName: String): IDialogItemGroup;
    procedure RemoveFromGroup(AItem: TBaseDialogItem);
    procedure AddToGroup(AItem: TBaseDialogItem);
    function GetBounds: TRect; override;
    procedure SetBounds(const R: TRect); override;
    function GetModalResult: TModalResult;
    procedure SetModalResult(const AModalResult: TModalResult);
    function GetOnResult: TDialogResultEvent;
    procedure SetOnResult(AEvent: TDialogResultEvent);
    function GetDialog: TForm;
    procedure DoClosePopup(ASender: TObject);
    procedure DoResult;
    procedure DoPopupMessage(var Msg: tagMSG; var Handled: Boolean);
    procedure DoDialogWndProc(var AMsg: TMessage);
    procedure DoDialogClose(Sender: TObject; var Action: TCloseAction);
    function GetCanClose: Boolean;
    procedure SetCanClose(const AValue: Boolean);
    function GetCloseDelay: Word;
    procedure SetCloseDelay(const Value: Word);
    function GetDisplayRemainTime: Boolean;
    procedure SetDisplayRemainTime(const AValue: Boolean);
    procedure TimerNeeded;
    procedure DoCloseTimer(ASender: TObject);
    function CalcControlPopupPos(AControl: TControl): TPoint;
{$IFDEF UNICODE}
    procedure SetOnResultCallback(ACallback: TDialogResultCallback);
{$ENDIF}
  public
    constructor Create(const ACaption: String); overload;
    destructor Destroy; override;
    procedure ShowModal(); overload;
    procedure Popup(AControl: TControl); overload;
    procedure Popup(APos: TPoint); overload;
    procedure RequestAlign;
    procedure Realign; override;
{$IFDEF UNICODE}
    procedure Popup(AControl: TControl;
      ACallback: TDialogResultCallback); overload;
    procedure Popup(APos: TPoint; ACallback: TDialogResultCallback); overload;
    procedure ShowModal(ACallback: TDialogResultCallback); overload;
{$ENDIF}
    property Dialog: TForm read FDialog;
    property Groups: TStrings read GetGroups;
    property ModalResult: TModalResult read GetModalResult write SetModalResult;
    property OnResult: TDialogResultEvent read FOnResult write SetOnResult;
    property CanClose: Boolean read FCanClose write SetCanClose;
    property CloseDelay: Word read FCloseDelay write SetCloseDelay;
    property DisplayRemainTime: Boolean read FDisplayRemainTime
      write FDisplayRemainTime;
  end;

function NewDialog(ACaption: String): IDialogBuilder;
begin
  if Length(ACaption) = 0 then
    Result := TDialogBuilder.Create(Application.Title)
  else
    Result := TDialogBuilder.Create(ACaption);
end;

function CustomDialog(const ACaption, ATitle, AMessage: String;
  AButtons: array of String; AIcon: TDialogIcon; AFlags: Integer;
  const ACustomProps: String): Integer;
var
  AIconSize: TSize;
const
  IconResId: array [TDialogIcon] of Integer = (0, 101, 102, 103, 104, 106);
begin
  AIconSize.cx := 32;
  AIconSize.cy := 32;
  Result := CustomDialog(ACaption, ATitle, AMessage, AButtons, IconResId[AIcon],
    user32, AIconSize, AFlags, ACustomProps);
end;

function CustomDialog(const ACaption, ATitle, AMessage: String;
  AButtons: array of String; AIconResId: Integer; AIconResFile: String;
  AIconSize: TSize; AFlags: Integer; const ACustomProps: String): Integer;
var
  AIcon: TIcon;
  ABuilder: IDialogBuilder;
  I: Integer;
  AIconImage: TImage;
begin
  ABuilder := NewDialog(ACaption);
  ABuilder.ItemSpace := 10;
  ABuilder.AutoSize := True;
  // 首行，可能是标题，图标+标题，图标+消息，消息
  with ABuilder.AddContainer(amVertTop) do
  begin
    AutoSize := True;
    with TPanel(Control) do
    begin
      Padding.Left := ABuilder.ItemSpace;
      Padding.Right := ABuilder.ItemSpace;
      ParentBackground := false;
      Color := clWhite;
    end;
    with AddContainer(amHorizLeft) do
    begin
      AutoSize := True;
      if (Length(AIconResFile) > 0) and (AIconResId > 0) then
      begin
        AIcon := TIcon.Create;
        try
          AIcon.SetSize(AIconSize.cx, AIconSize.cy);
          AIconImage := TImage(AddControl(TImage).Control);
          with AIconImage do
          begin
            AutoSize := True;
            AlignWithMargins := True;
            AIcon.Handle := LoadImage(GetModuleHandle(PChar(AIconResFile)),
              MAKEINTRESOURCE(AIconResId), IMAGE_ICON, AIconSize.cx,
              AIconSize.cy, 0);
            Picture.Assign(AIcon);
          end;
        finally
          FreeAndNil(AIcon);
        end;
      end;
      if Length(ATitle) > 0 then
      begin
        with TLabel(AddControl(TLabel).Control) do
        begin
          // 低版本的 Delphi 需要调用函数来获取当前操作系统版本
          if TOSVersion.Major > 5 then
            Font.Name := 'Microsoft YaHei'
          else
            Font.Name := 'SimHei';
          Font.Size := 12;
          Layout := tlCenter;
          Caption := ATitle;
        end;
      end
      else if Length(AMessage) > 0 then
      begin
        with TLabel(AddControl(TLabel).Control) do
        begin
          AlignWithMargins := True;
          Layout := tlCenter;
          Caption := AMessage;
        end;
      end;;
    end;
    if (Length(ATitle) > 0) and (Length(AMessage) > 0) then
    begin
      with TLabel(AddControl(TLabel).Control) do
      begin
        AlignWithMargins := True;
        Margins.Left := AIconImage.Left + ABuilder.ItemSpace + AIconImage.Width;
        Margins.Right := Margins.Left;
        Caption := AMessage;
      end;
    end;
  end;
  if Length(AButtons) > 0 then
  begin
    with ABuilder.AddContainer(amHorizRight) do
    begin
      Height := 32;
      with TPanel(Control) do
      begin
        ParentBackground := false;
        Padding.Right := ABuilder.ItemSpace div 2;
      end;
      for I := 0 to High(AButtons) do
      begin
        with TButton(AddControl(TButton).Control) do
        begin
          Caption := AButtons[I];
          ModalResult := 100 + I;
        end;
      end;
      if (AFlags and CDF_ALWAYS_CLOSABLE) = 0 then
        ABuilder.CanClose := Length(AButtons) <= 1;
    end;
  end;
  ABuilder.CloseDelay := AFlags and CDF_MASK_TIMEOUT;
  ABuilder.DisplayRemainTime := (AFlags and CDF_DISPLAY_REMAIN_TIME) <> 0;
  ABuilder.Realign;
  ABuilder.PropText := ACustomProps;
  ABuilder.ShowModal;
  if ABuilder.ModalResult >= 100 then
    Result := ABuilder.ModalResult - 100
  else // 用户直接关闭了窗口，没有选择任何按钮
    Result := -1;
end;

{ TDialogContainer }

function TDialogContainer.Add(const AItem: IBaseDialogItem): IDialogContainer;
begin
  AItem._AddRef;
  FItems.Add(AItem);
  AItem.Parent := Self;
  Result := Self;
  Builder.RequestAlign;
  Builder.GroupCast(Self, dneItemAdded);
end;

function TDialogContainer.AddContainer(AlignMode: TDialogItemAlignMode)
  : IDialogContainer;
var
  AItem: TDialogContainer;
begin
  AItem := TDialogContainer.Create(Builder);
  AItem.AlignMode := AlignMode;
  Add(AItem);
  Result := AItem;
end;

{$IFDEF UNICODE}

function TDialogContainer.AddControl(AClass: TControlClass;
  AOnClick: TNotifyCallback; APropText: String): IControlDialogItem;
var
  AEvent: TNotifyEvent;
begin
  AEvent := nil;
  with TMethod(AEvent) do
  begin
    TNotifyCallback(Code) := AOnClick;
    Data := Pointer(-1);
  end;
  Result := AddControl(AClass, APropText);
  Result.OnClick := AEvent;
end;
{$ENDIF}

function TDialogContainer.AddControl(AClass: TControlClass;
  APropText: String = ''): IControlDialogItem;
var
  AItem: TControlDialogItem;
begin
  AItem := TControlDialogItem.Create(Builder, AClass);
  Add(AItem);
  AItem.PropText := APropText;
  Result := AItem;
end;

function TDialogContainer.CalcSize: TSize;
var
  AItemSize: TSize;
  I: Integer;
begin
  if AutoSize then
    Result := ItemSize
  else
  begin
    with Bounds do
      Result := TSize.Create(Right - Left, Bottom - Top);
  end;
end;

procedure TDialogContainer.Clear;
var
  I: Integer;
  AObj: IBaseDialogItem;
begin
  for I := 0 to FItems.Count - 1 do
  begin
    AObj := IBaseDialogItem(FItems[I]);
    AObj._Release;
  end;
  FItems.Clear;
  Builder.GroupCast(Self, dneItemChanged);
end;

constructor TDialogContainer.Create(ABuilder: IDialogBuilder;
  ACtrlClass: TControlClass);
begin
  inherited;
  FItems := TList.Create;
  FItemSpace := 3;
end;

constructor TDialogContainer.Create(ABuilder: IDialogBuilder);
begin
  Create(ABuilder, TPanel);
  with TPanel(Control) do
  begin
    BevelOuter := bvNone;
    BevelInner := bvNone;
  end;
end;

procedure TDialogContainer.Delete(const AIndex: Integer);
var
  AObj: TBaseDialogItem;
begin
  AObj := FItems[AIndex];
  FItems.Delete(AIndex);
  AObj._Release;
  Builder.GroupCast(Self, dneItemRemoved);
end;

destructor TDialogContainer.Destroy;
begin
  Clear;
  FreeAndNil(FItems);
  inherited;
end;

function TDialogContainer.GetAlignMode: TDialogItemAlignMode;
begin
  Result := FAlignMode;
end;

function TDialogContainer.GetAutoSize: Boolean;
begin
  Result := FAutoSize;
end;

function TDialogContainer.GetCount: Integer;
begin
  Result := FItems.Count;
end;

function TDialogContainer.GetItems(const AIndex: Integer): IBaseDialogItem;
begin
  Result := IBaseDialogItem(FItems[AIndex]);
end;

function TDialogContainer.GetItemSpace: Integer;
begin
  Result := FItemSpace;
end;

function TDialogContainer.ItemSize: TSize;
var
  I: Integer;
  AItemSize: TSize;
begin
  Result.cx := 0;
  Result.cy := 0;
  for I := 0 to FItems.Count - 1 do
  begin
    AItemSize := IBaseDialogItem(FItems[I]).CalcSize;
    case AlignMode of
      amVertTop, amVertCenter, amVertBottom: // 垂直布局
        begin
          Inc(Result.cy, AItemSize.cy + ItemSpace);
          if Result.cx < AItemSize.cx then
            Result.cx := AItemSize.cx;
        end;
      amHorizLeft, amHorizCenter, amHorizRight:
        begin
          Inc(Result.cx, AItemSize.cx + ItemSpace);
          if Result.cy < AItemSize.cy then
            Result.cy := AItemSize.cy;
        end;
    end;
  end;
  if Control is TWinControl then
  begin
    with TWinControl(Control) do
    begin
      Inc(Result.cx, Padding.Left + Padding.Right);
      Inc(Result.cy, Padding.Top + Padding.Bottom);
    end;
  end;
end;

procedure TDialogContainer.Realign;
var
  ASize, AItemSize: TSize;
  I: Integer;
  R: TRect;
  AItem: IBaseDialogItem;
  AContainer: IDialogContainer;
begin
  R := GetBounds;
  if AutoSize then
  begin
    ASize := ItemSize;
    if not Assigned(Parent) then
    begin
      R.Right := R.Left + ASize.cx;
      R.Bottom := R.Top + ASize.cy;
      SetBounds(R);
    end;
  end;
  OffsetRect(R, -R.Left, -R.Top);
  if Control is TWinControl then
  begin
    with TWinControl(Control) do
    begin
      R.Left := R.Left + Padding.Left;
      R.Top := R.Top + Padding.Top;
      R.Right := R.Right - Padding.Right;
      R.Bottom := R.Bottom - Padding.Bottom;
    end;
  end;
  case AlignMode of
    amVertCenter:
      R.Top := R.Top + (R.Bottom - R.Top - ItemSize.cy) shr 1;
    amVertBottom:
      R.Top := R.Bottom - ItemSize.cy;
    amHorizCenter:
      R.Left := R.Left + (R.Right - R.Left - ItemSize.cx) shr 1;
    amHorizRight:
      R.Left := R.Right - ItemSize.cx;
  end;
  for I := 0 to FItems.Count - 1 do
  begin
    AItem := IBaseDialogItem(FItems[I]);
    AItemSize := AItem.CalcSize;
    case AlignMode of
      amVertTop, amVertCenter, amVertBottom:
        begin
          AItem.SetBounds(Rect(R.Left, R.Top, R.Right, R.Top + AItemSize.cy));
          R.Top := R.Top + AItemSize.cy + ItemSpace;
        end;
      amHorizLeft, amHorizCenter, amHorizRight:
        begin
          AItem.SetBounds(Rect(R.Left, R.Top, R.Left + AItemSize.cx, R.Bottom));
          R.Left := R.Left + AItemSize.cx + ItemSpace;
        end;
    end;
    if Supports(AItem, IDialogContainer, AContainer) then
      AContainer.Realign;
  end;
end;

procedure TDialogContainer.SetAlignMode(AMode: TDialogItemAlignMode);
begin
  if FAlignMode <> AMode then
  begin
    FAlignMode := AMode;
    Builder.RequestAlign;
  end;
end;

procedure TDialogContainer.SetAutoSize(const AValue: Boolean);
begin
  if FAutoSize <> AValue then
  begin
    FAutoSize := AValue;
    Builder.RequestAlign;
  end;
end;

procedure TDialogContainer.SetItemSpace(const V: Integer);
begin
  if FItemSpace <> V then
  begin
    FItemSpace := V;
    Builder.RequestAlign;
  end;
end;

{ TBaseDialogItem }

function TBaseDialogItem.CalcSize: TSize;
begin
  Result.cx := 0;
  Result.cy := 0;
end;

constructor TBaseDialogItem.Create(ABuilder: IDialogBuilder);
begin
  inherited Create;
  Pointer(FBuilder) := Pointer(ABuilder);
end;

destructor TBaseDialogItem.Destroy;
begin
  if Length(GroupName) > 0 then
    Builder.ChangeGroup(Self, '');
  Pointer(FParent) := nil;
  inherited;
end;

function TBaseDialogItem.GetBuilder: IDialogBuilder;
begin
  Result := FBuilder;
end;

function TBaseDialogItem.GetGroup: IDialogItemGroup;
begin
  if Length(FGroupName) > 0 then
    Result := Builder.GroupByName(FGroupName)
  else
    Result := nil;
end;

function TBaseDialogItem.GetGroupName: String;
begin
  Result := FGroupName;
end;

function TBaseDialogItem.GetHeight: Integer;
begin
  with Bounds do
    Result := Bottom - Top;
end;

function TBaseDialogItem.GetParent: IDialogContainer;
begin
  Result := FParent;
end;

function TBaseDialogItem.GetWidth: Integer;
begin
  with Bounds do
    Result := Right - Left;
end;

procedure TBaseDialogItem.Notify(ASender: IBaseDialogItem;
  AEvent: TDialogNotifyEvent);
begin

end;

procedure TBaseDialogItem.SetGroupName(const Value: String);
begin
  Builder.ChangeGroup(Self, Value);
end;

procedure TBaseDialogItem.SetHeight(const AValue: Integer);
var
  R: TRect;
begin
  R := Bounds;
  R.Bottom := R.Top + AValue;
  Bounds := R;
end;

procedure TBaseDialogItem.SetParent(const Value: IDialogContainer);
begin
  Pointer(FParent) := Pointer(Value);
  Notify(Self, dneParentChanged);
end;

procedure TBaseDialogItem.SetWidth(const AValue: Integer);
var
  R: TRect;
begin
  R := Bounds;
  R.Right := R.Left + AValue;
  Bounds := R;
end;

{ TDialogBuilder }

procedure TDialogBuilder.AddToGroup(AItem: TBaseDialogItem);
var
  AGroup: TDialogGroup;
  AIdx: Integer;
begin
  if Length(AItem.GroupName) > 0 then
  begin
    AIdx := FGroups.IndexOf(AItem.GroupName);
    if AIdx <> -1 then
      AGroup := FGroups.Objects[AIdx] as TDialogGroup
    else
    begin
      AGroup := TDialogGroup.Create;
      AGroup._AddRef;
      FGroups.AddObject(AItem.GroupName, AGroup);
    end;
    if AGroup.IndexOf(AItem) = -1 then
      AGroup.Add(AItem);
  end;
end;

function TDialogBuilder.CalcControlPopupPos(AControl: TControl): TPoint;
var
  AMonitor: TMonitor;
  ASize: TSize;
begin
  FLastActiveWnd := GetParentForm(AControl).Handle;
  Result := AControl.ClientToScreen(Point(0, AControl.Height));
  ASize := ItemSize;
  AMonitor := Screen.MonitorFromPoint(Result);
  if Result.X + ASize.cx > AMonitor.BoundsRect.Right then
    Result.X := AMonitor.BoundsRect.Right - ASize.cx;
  if Result.Y + ASize.cy > AMonitor.BoundsRect.Bottom then
  begin
    if Result.Y - AControl.Height - ASize.cy > AMonitor.BoundsRect.Top then
      Result.Y := Result.Y - AControl.Height - ASize.cy
    else
      Result.Y := AMonitor.BoundsRect.Bottom - ASize.cy;
  end;
end;

procedure TDialogBuilder.ChangeGroup(AItem: IBaseDialogItem; ANewName: String);
var
  ATemp: TBaseDialogItem;
begin
  ATemp := AItem as TBaseDialogItem;
  if ATemp.GroupName <> ANewName then
  begin
    if Length(ATemp.GroupName) > 0 then
      RemoveFromGroup(ATemp);
    ATemp.FGroupName := ANewName;
    if Length(ANewName) > 0 then
      AddToGroup(ATemp);
  end;
end;

constructor TDialogBuilder.Create(const ACaption: String);
begin
  inherited Create(Self, TForm);
  FGroups := TStringList.Create;
  FDialog := Control as TForm;
  FDialog.BorderStyle := bsDialog;
  FDialog.Position := poScreenCenter;
  FDialog.Caption := ACaption;
  FLastDialogWndProc := FDialog.WindowProc;
  FDialog.WindowProc := DoDialogWndProc;
  FDialog.OnClose := DoDialogClose;
  FStates := [dbsAlignRequest];
  FCanClose := True;
end;

destructor TDialogBuilder.Destroy;
var
  I: Integer;
  AObj: TDialogGroup;
begin
  if Assigned(FPopupHelper) then
    FreeAndNil(FPopupHelper);
  Clear;
  for I := 0 to FGroups.Count - 1 do
  begin
    AObj := FGroups.Objects[I] as TDialogGroup;
    AObj._Release;
  end;
  FreeAndNil(FGroups);
  FreeAndNil(FDialog);
  inherited;
end;

procedure TDialogBuilder.DoClosePopup(ASender: TObject);
begin
  FStates := FStates - [dbsPopup];
  Dialog.Close;
  DoResult;
  // 减少弹出时增加的引用计数
  _Release;
end;

procedure TDialogBuilder.DoCloseTimer(ASender: TObject);
begin
  FTimer.Tag := FTimer.Tag + 1;
  if FTimer.Tag >= CloseDelay then
  begin
    FTimer.Enabled := false;
    CanClose := True;
    Dialog.Close;
  end
  else if DisplayRemainTime then
  begin
    if Length(FInitializeCaption) = 0 then
      FInitializeCaption := Dialog.Caption;
    Dialog.Caption := FInitializeCaption + '-' +
      RollupTime(CloseDelay - FTimer.Tag);
  end;
end;

procedure TDialogBuilder.DoDialogClose(Sender: TObject;
  var Action: TCloseAction);
begin
  if not CanClose then
  begin
    if ModalResult < 100 then
      Action := caNone;
  end;
  if Action <> caNone then
    PostMessage(Dialog.Handle, WM_APP, 0, 0);
end;

procedure TDialogBuilder.DoDialogWndProc(var AMsg: TMessage);
begin
  if dbsPopup in FStates then
  begin
    if AMsg.Msg = WM_NCACTIVATE then
    begin
      if FLastActiveWnd <> 0 then
        SendMessage(FLastActiveWnd, WM_NCACTIVATE, 1, -1);
    end
    else if AMsg.Msg = WM_APP then
      DoClosePopup(Self);
  end;
  FLastDialogWndProc(AMsg);
end;

procedure TDialogBuilder.DoPopupMessage(var Msg: tagMSG; var Handled: Boolean);
  procedure FollowControl;
  var
    pt: TPoint;
  begin
    pt := CalcControlPopupPos(FPopupHelper.Control);
    Dialog.SetBounds(pt.X, pt.Y, Dialog.Width, Dialog.Height);
  end;

begin
  case Msg.message of
    WM_LBUTTONDOWN, WM_RBUTTONDOWN, WM_MBUTTONDOWN, WM_XBUTTONDOWN:
      begin
        if not PtInRect(Dialog.BoundsRect, Mouse.CursorPos) then
        begin
          if dbsPopup in FStates then
            DoClosePopup(Self);
        end;
      end;
  end;
  if Assigned(FPopupHelper) and (FPopupHelper.Control <> nil) then
    FollowControl;
end;

procedure TDialogBuilder.DoResult;
begin
  FLastActiveWnd := 0;
  if Assigned(FPopupHelper) then
    FPopupHelper.Control := nil;
  if Assigned(FOnResult) then
  begin
{$IFDEF UNICODE}
    with TMethod(FOnResult) do
    begin
      if Data = Pointer(-1) then
        TDialogResultCallback(Code)(Self)
      else
        FOnResult(Self);
    end;
{$ELSE}
    FOnResult(Self);
{$ENDIF}
  end;
end;

function TDialogBuilder.GetBounds: TRect;
begin
  Result := FDialog.ClientRect;
end;

function TDialogBuilder.GetCanClose: Boolean;
begin
  Result := FCanClose;
end;

function TDialogBuilder.GetCloseDelay: Word;
begin
  Result := FCloseDelay;
end;

function TDialogBuilder.GetDialog: TForm;
begin
  Result := FDialog;
end;

function TDialogBuilder.GetDisplayRemainTime: Boolean;
begin
  Result := FDisplayRemainTime;
end;

function TDialogBuilder.GetGroups: TStrings;
begin
  Result := FGroups;
end;

function TDialogBuilder.GetModalResult: TModalResult;
begin
  Result := FDialog.ModalResult;
end;

function TDialogBuilder.GetOnResult: TDialogResultEvent;
begin
  Result := FOnResult;
end;

function TDialogBuilder.GroupByName(const AName: String): IDialogItemGroup;
var
  AIdx: Integer;
begin
  Result := nil;
  if Length(AName) > 0 then
  begin
    AIdx := FGroups.IndexOf(AName);
    if AIdx <> -1 then
      Result := FGroups.Objects[AIdx] as TDialogGroup;
  end;
end;

procedure TDialogBuilder.GroupCast(ASender: IBaseDialogItem;
  AEvent: TDialogNotifyEvent);
var
  AGroup: IDialogItemGroup;
  AIdx: Integer;
  AItem: IBaseDialogItem;
begin
  AGroup := GroupByName(ASender.GroupName);
  if Assigned(AGroup) then
  begin
    for AIdx := 0 to AGroup.Count - 1 do
    begin
      AItem := AGroup[AIdx];
      AItem.Notify(AItem, AEvent);
    end;
  end;
end;

procedure TDialogBuilder.Popup(APos: TPoint);
begin
  // 调整好控件的位置
  if not(dbsPopup in FStates) then // 检测以避免重复调用时出现计数问题
  begin
    FStates := FStates + [dbsPopup];
    _AddRef;
  end;
  if Dialog.BorderStyle <> bsNone then
    RequestAlign;
  Dialog.BorderStyle := bsNone;
  Dialog.Position := poDesigned;
  if dbsAlignRequest in FStates then
    Realign;
  Dialog.SetBounds(APos.X, APos.Y, Dialog.Width, Dialog.Height);
  Dialog.FormStyle := fsStayOnTop;
  {
    VCL 本身并没有内置非活动窗口的显示，无论你调用 Show/Visible，都会让当前窗口变为
    活动窗口，原来的窗口会失去焦点，所以要做几件事：
    1、调用 SetWindowPos 以非活动状态显示出窗口
    2、强制修改窗口的 Visible 属性为 True
    3、发起 CM_VISIBLECHANGED 消息，以通知相关控件
    同时，为了避免点击对话框中的控件时，原来的窗口显示为失去焦点的状态，也要处理下
    消息，具体看 DoDialogWndProc 代码。
    弹出的对话框在用户点击其它位置时，应自动消失，所以还要检查鼠标消息，并在用户点
    击非当前位置时自动消失。
  }
  if FLastActiveWnd = 0 then
    FLastActiveWnd := GetActiveWindow;
  SetClassLong(Dialog.Handle, GCL_STYLE, GetClassLong(Dialog.Handle, GCL_STYLE)
    or CS_DROPSHADOW);
  SetWindowPos(Dialog.Handle, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOACTIVATE OR
    SWP_NOSIZE OR SWP_NOMOVE OR SWP_SHOWWINDOW);
  PBoolean(@Dialog.Visible)^ := True;
  Dialog.Perform(CM_VISIBLECHANGED, 0, 0);
  if not Assigned(FAppEvents) then
  begin
    FAppEvents := TApplicationEvents.Create(Dialog);
    FAppEvents.OnMessage := DoPopupMessage;
  end;
end;

procedure TDialogBuilder.Popup(AControl: TControl);
begin
  if not Assigned(FPopupHelper) then
  begin
    FPopupHelper := TDialogPopupHelper.Create(nil);
    FPopupHelper.Builder := Self;
  end;
  FPopupHelper.Control := AControl;
  FLastActiveWnd := GetParentForm(AControl).Handle;
  Popup(CalcControlPopupPos(AControl));
end;

procedure TDialogBuilder.Realign;
begin
  FStates := FStates + [dbsAligning] - [dbsAlignRequest];
  try
    inherited;
  finally
    FStates := FStates - [dbsAligning];
  end;
end;

procedure TDialogBuilder.RemoveFromGroup(AItem: TBaseDialogItem);
var
  AGroup: TDialogGroup;
  AIdx: Integer;
begin
  if Length(AItem.GroupName) > 0 then
  begin
    AIdx := FGroups.IndexOf(AItem.GroupName);
    if AIdx <> -1 then
    begin
      AGroup := FGroups.Objects[AIdx] as TDialogGroup;
      AGroup.Remove(AItem);
      if AGroup.Count = 0 then
      begin
        FGroups.Delete(AIdx);
        AGroup._Release;
      end;
    end;
  end;
end;

procedure TDialogBuilder.RequestAlign;
begin
  if not(dbsAligning in FStates) then
    FStates := FStates + [dbsAlignRequest];
end;

procedure TDialogBuilder.SetBounds(const R: TRect);
begin
  FDialog.ClientWidth := R.Right - R.Left;
  FDialog.ClientHeight := R.Bottom - R.Top;
end;

procedure TDialogBuilder.SetCanClose(const AValue: Boolean);
begin
  if FCanClose <> AValue then
  begin
    FCanClose := AValue;
    if AValue then
      EnableMenuItem(GetSystemMenu(Dialog.Handle, false), SC_CLOSE,
        MF_BYCOMMAND)
    else
      EnableMenuItem(GetSystemMenu(Dialog.Handle, false), SC_CLOSE,
        MF_DISABLED or MF_GRAYED or MF_BYCOMMAND);
  end;
end;

procedure TDialogBuilder.SetModalResult(const AModalResult: TModalResult);
begin
  FDialog.ModalResult := AModalResult;
end;

procedure TDialogBuilder.SetOnResult(AEvent: TDialogResultEvent);
begin
{$IFDEF UNICODE}
  with TMethod(FOnResult) do
  begin
    if Data = Pointer(-1) then
    begin
      TDialogResultCallback(Code) := nil;
      Data := nil;
    end;
  end;
{$ENDIF}
  FOnResult := AEvent;
end;

{$IFDEF UNICODE}

procedure TDialogBuilder.SetOnResultCallback(ACallback: TDialogResultCallback);
var
  AEvent: TDialogResultEvent;
begin
  AEvent := nil;
  with TMethod(AEvent) do
  begin
    Data := Pointer(-1);
    TDialogResultCallback(Code) := ACallback;
  end;
  SetOnResult(AEvent);
end;

procedure TDialogBuilder.SetCloseDelay(const Value: Word);
begin
  if FCloseDelay <> Value then
  begin
    FCloseDelay := Value;
    if Value > 0 then
      TimerNeeded;
  end;
end;

procedure TDialogBuilder.SetDisplayRemainTime(const AValue: Boolean);
begin
  FDisplayRemainTime := AValue;
end;

procedure TDialogBuilder.ShowModal(ACallback: TDialogResultCallback);
begin
  SetOnResultCallback(ACallback);
  ShowModal;
end;

procedure TDialogBuilder.TimerNeeded;
begin
  if not Assigned(FTimer) then
  begin
    FTimer := TTimer.Create(Dialog);
    FTimer.OnTimer := DoCloseTimer;
    FTimer.Enabled := Dialog.Visible;
  end;
  FTimer.Tag := 0; // 计数清零
end;

{$ENDIF}

procedure TDialogBuilder.ShowModal;
begin
  if FDialog.BorderStyle <> bsDialog then
  begin
    FDialog.BorderStyle := bsDialog;
    RequestAlign;
  end;
  FDialog.Position := poScreenCenter;
  if dbsAlignRequest in FStates then
    Realign;
  if CloseDelay > 0 then
    FTimer.Enabled := True;
  SetClassLong(Dialog.Handle, GCL_STYLE, GetClassLong(Dialog.Handle, GCL_STYLE)
    and (not CS_DROPSHADOW));
  FDialog.ShowModal;
  DoResult;
end;

procedure TDialogBuilder.Popup(APos: TPoint; ACallback: TDialogResultCallback);
begin
  SetOnResultCallback(ACallback);
  Popup(APos);
end;

procedure TDialogBuilder.Popup(AControl: TControl;
  ACallback: TDialogResultCallback);
begin
  SetOnResultCallback(ACallback);
  Popup(AControl);
end;

{ TControlDialogItem }

function TControlDialogItem.CalcSize: TSize;
begin
  Result.cx := FControl.Width;
  Result.cy := FControl.Height;
  if FControl.AlignWithMargins then
  begin
    Inc(Result.cx, FControl.Margins.Left + FControl.Margins.Right);
    Inc(Result.cy, FControl.Margins.Top + FControl.Margins.Bottom);
  end;
end;

constructor TControlDialogItem.Create(ABuilder: IDialogBuilder;
  ACtrlClass: TControlClass);
var
  AProp: PPropInfo;
  AEvent: TNotifyEvent;
begin
  inherited Create(ABuilder);
  FControl := ACtrlClass.Create(ABuilder.Dialog);
  AProp := GetPropInfo(FControl, 'OnClick');
  if Assigned(AProp) and (AProp.PropType^.Kind = tkMethod) then
  begin
    AEvent := DoClick;
    SetMethodProp(FControl, AProp, TMethod(AEvent));
  end;
end;

constructor TControlDialogItem.Create(ABuilder: IDialogBuilder);
begin
  inherited;
end;

destructor TControlDialogItem.Destroy;
begin
  if Assigned(FOnClick) then
  begin
    with TMethod(FOnClick) do
    begin
      if Data = Pointer(-1) then
      begin
        TNotifyCallback(Code) := nil;
        Data := nil;
      end;
    end;
  end;
  inherited;
end;

procedure TControlDialogItem.DoClick(Sender: TObject);
begin
  if Assigned(FOnClick) then
  begin
{$IFDEF UNICODE}
    with TMethod(FOnClick) do
    begin
      if Data = Pointer(-1) then
        TNotifyCallback(Code)(Self)
      else
        FOnClick(Self);
    end;
{$ELSE}
    FOnClick(Self);
{$ENDIF}
  end;
end;

function TControlDialogItem.GetBounds: TRect;
begin
  Result := FControl.BoundsRect;
  if FControl.ClassName = 'TEdit' then
  begin
    Notify(Self, dneItemChanged);
  end;
  if FControl.AlignWithMargins then
  begin
    Result.Left := Result.Left - FControl.Margins.Left;
    Result.Top := Result.Top - FControl.Margins.Top;
    Result.Right := Result.Right + FControl.Margins.Right;
    Result.Bottom := Result.Bottom + FControl.Margins.Bottom;
  end;
end;

function TControlDialogItem.GetControl: TControl;
begin
  Result := FControl;
end;

function TControlDialogItem.GetOnClick: TNotifyEvent;
begin
  Result := FOnClick;
end;

function TControlDialogItem.GetPropText: String;
begin
  Result := FPropText;
end;

procedure TControlDialogItem.Notify(ASender: IBaseDialogItem;
  AEvent: TDialogNotifyEvent);
var
  AContainer: TDialogContainer;
begin
  inherited;
  if AEvent = dneParentChanged then
  begin
    AContainer := Parent as TDialogContainer;
    if Assigned(AContainer) then
      FControl.Parent := AContainer.Control as TWinControl;
  end;
end;

procedure TControlDialogItem.SetBounds(const R: TRect);
begin
  if FControl.AlignWithMargins then
    FControl.BoundsRect := Rect(R.Left + FControl.Margins.Left,
      R.Top + FControl.Margins.Top, R.Right - FControl.Margins.Right,
      R.Bottom - FControl.Margins.Bottom)
  else
    FControl.BoundsRect := R;
end;

procedure TControlDialogItem.SetOnClick(const Value: TNotifyEvent);
begin
{$IFDEF UNICODE}
  with TMethod(FOnClick) do
  begin
    if Data = Pointer(-1) then
    begin
      TNotifyCallback(Code) := nil;
      Data := nil;
    end;
  end;
{$ENDIF}
  FOnClick := Value;
end;

procedure TControlDialogItem.SetPropText(const AValue: String);
var
  AProps: TQJson;
begin
  if FPropText <> AValue then
  begin
    FPropText := AValue;
    AProps := TQJson.Create;
    try
      if AProps.TryParse(AValue) then
      begin
        AProps.ToRtti(FControl);
      end;
    finally
      FreeAndNil(AProps);
    end;
  end;
end;

{ TDialogGroup }

function TDialogGroup.GetItems(const AIndex: Integer): IBaseDialogItem;
begin
  Result := IBaseDialogItem(Items[AIndex]);
end;

{ TDialogPopupHelper }

destructor TDialogPopupHelper.Destroy;
begin
  Builder := nil;
  if Assigned(Control) then
    Control.RemoveFreeNotification(Self);
  inherited;
end;

procedure TDialogPopupHelper.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  inherited;
  if Operation = opRemove then
  begin
    if AComponent = FControl then
    begin
      FControl := nil;
      Builder.Dialog.Close;
    end;
  end;
end;

procedure TDialogPopupHelper.SetBuilder(const Value: IDialogBuilder);
begin
  Pointer(FBuilder) := Pointer(Value);
end;

procedure TDialogPopupHelper.SetControl(const Value: TControl);
begin
  if Assigned(FControl) then
    FControl.RemoveFreeNotification(Self);
  FControl := Value;
  if Value <> nil then
    Value.FreeNotification(Self);
end;

end.
