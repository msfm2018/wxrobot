unit qdac_fmx_virtualtree;
{ FMX VirtualTree 是一个基于 FMX 设计优化的一种树形结构显示控件，它可以被用来当做
  普通的表格或者是树形结构使用。
}

interface

uses System.Classes, System.Sysutils, System.Types, System.UITypes,
  System.Math.Vectors,
  System.Generics.Collections, System.RTLConsts, System.Messaging,
  Math, FMX.TextLayout, FMX.Layouts, FMX.StdCtrls, FMX.Edit, FMX.ListBox,
  FMX.ComboEdit,
  FMX.Memo, FMX.InertialMovement, FMX.Colors, Data.DB, FMX.Forms,
  FMX.Types, FMX.Controls, FMX.Graphics, FMX.Dialogs, FMX.Objects, FMX.Platform;

const
  AllCurrentPlatforms = $FFFF;

type
  // 最简单的对象封装，用于将简单类型转换为对象
TQSimpleObject < T >= class //
  private FValue: T;
public
  constructor Create(const AValue: T);
  overload;
  property value: T read FValue write FValue;
  end;
  TQSimpleInterface < T >= class(TInterfacedObject)private FValue: T;
public
  constructor Create(const AValue: T);
  overload;
  property value: T read FValue write FValue;
  end;

type
  {
    结点的状态：
    Initialized 已经初始化完成
    Hover 当前鼠标或手指在上面移动
    MouseDown 当前鼠标或手指按在上面
    Unchecked 当前结点主列未被选中
    Checked 当前结点主列已选中
    SomeChecked 当前结点主列一部分子结点被选中了
    Selected 当前结点被选择
    Expanded 当前结点已经被展开
    Invalid 当前结点需要刷新显示
    HasChildren 当前结点拥有至少一个子结点
  }
  TQVTNode = class;
  TQVirtualTreeView = class;
  TQVTColumn = class;
  TQVTNodeState = (nsInitialized, nsVisible, nsHover, nsMouseDown, nsUnchecked,
    nsChecked, nsSomeChecked, nsSelected, nsExpanded, nsInvalid, nsHasChildren);

  TQVTNodeStates = set of TQVTNodeState;
  TQVTCheckState = (csChecked, csSomeChecked);
  TQVTCheckStates = set of TQVTCheckState;

  TQVTLayout = (clLeftTop, clTopCenter, clRightTop, clRightCenter,
    clRightBottom, clBottomCenter, clLeftBottom, clLeftCenter, clCenter);
  // 排序标记
  TQVTColumnSortMarker = (smNone, smAsc, smDesc);
  // 列绘制器定义
  TQVTDrawerType = (dtDefault, dtText, dtCheck, dtRadio, dtImage, dtStateText,
    dtTree, dtProgress, dtMoney, dtRowIndicator, dtHeader, dtCustom);

  IQVTDrawer = interface;
  IQVTCellData = interface;

  IQVTNamedExt = interface
    ['{78787785-3DE5-43FA-BDDE-9F9A39607546}']
    function GetName: String;
    property Name: String read GetName;
  end;

  IQVTExtendable = interface
    ['{984368F3-B4D4-4D20-96E4-7E8C4DCA7133}']
    function ExtByType(const IID: TGUID; var AValue): Boolean; overload;
    function ExtByType(const AClass: TClass): TObject; overload;
    function ExtByType(const AClass: TClass; var AValue): Boolean; overload;
    function ExtByName(const AName: String): IQVTNamedExt;
    function GetExts: TList<IInterface>;
    function HasExts: Boolean;
    property Exts: TList<IInterface> read GetExts;
  end;

  IQVTDrawable = interface
    ['{066AE9A9-18F1-484E-BA57-28BFF5221F06}']
    // 获取行画刷
    function GetFill: TBrush;
    // 获取行画笔
    function GetStroke: TStrokeBrush;
    property Fill: TBrush read GetFill;
    property Stroke: TStrokeBrush read GetStroke;
  end;

  IQVTTextDrawable = interface(IQVTDrawable)
    ['{84C5A8EA-F212-4CE7-B7EA-13FFFE8E7C39}']
    // 获取当前结点文本设置，如果返回空，则使用列的默认设置
    function GetTextSettings: TTextSettings;
    property TextSettings: TTextSettings read GetTextSettings;
  end;


  // 基本的单元格数据类型定义

  // 单元格数据
  IQVTCellData = interface
    ['{BBF731E7-B5A1-4783-85B7-8C76A46A289B}']
    // 列号
    function GetColumn: Integer;
    procedure SetColumn(const AColumn: Integer);
    function GetColumnId: Integer;
    // 关联的结点
    function GetNode: TQVTNode;
    procedure SetNode(ANode: TQVTNode);
    // 关联的树
    function GetTreeView: TQVirtualTreeView;
    // 是否处于允许状态
    function GetEnabled: Boolean;
    // 边框
    function GetSides: TSides;
    property Enabled: Boolean read GetEnabled;
    property Column: Integer read GetColumn write SetColumn;
    property ColumnId: Integer read GetColumnId;
    property Node: TQVTNode read GetNode write SetNode;
    property Sides: TSides read GetSides;
    property TreeView: TQVirtualTreeView read GetTreeView;
  end;

  IQVTColorCellData = interface
    ['{768100C2-A2C8-4AE9-A70F-3CB0A125A872}']
    function GetColor: TAlphaColor;
    procedure SetColor(const AValue: TAlphaColor);
    property Color: TAlphaColor read GetColor write SetColor;
  end;

  IQVTProgressCellData = interface
    ['{EDEA1C95-A417-4635-8380-28A89872BB1D}']
    function GetProgress: Single;
    procedure SetProgress(const AValue: Single);
  end;

  IQVTCurrencyCellData = interface
    ['{38E6E3AD-6383-42D1-B85F-CAC75876EEF3}']
    function GetValue: Currency;
    procedure SetValue(const AValue: Currency);
    function GetMaxValue: Currency;
  end;

  // 带文本的单元格数据
  IQVTTextCellData = interface(IQVTCellData)
    ['{ECAB714B-3EBD-4296-8121-61D541CE8758}']
    // 获取当前结点文本内容
    function GetText: String;
    property Text: String read GetText;
  end;

  IQVTPickListCellData = interface(IQVTTextCellData)
    ['{F2A7BA74-2E3C-4A4A-BAB5-CBA703BE2BFD}']
    function GetItems(AList: TStrings): Integer;
  end;

  // 鼠标操纵单元格内容
  IQVTCellMouseEditCellData = interface
    ['{73E532B2-BBBF-41DB-B78B-AD8D30A5ED59}']
    procedure MouseDown(AButton: TMouseButton; AShift: TShiftState;
      const APos: TPointF);
    procedure MouseMove(AShift: TShiftState; const APos: TPointF);
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState;
      const APos: TPointF);
    procedure MouseClick(Button: TMouseButton; Shift: TShiftState;
      const APos: TPointF);
  end;

  IVQTCellSpaceEditCellData = interface
    ['{5FCD79FC-6496-4B64-8F59-EFD87A73E9F3}']
    procedure NextValue;
  end;

  IQVTEditableTextCellData = interface(IQVTTextCellData)
    ['{40F451FF-D797-43DC-8DA2-7E43D4FF1B75}']

    procedure SetText(const S: String);
    property Text: String read GetText write SetText;
  end;

  IQVTCellLayoutData = interface
    ['{4DFBCBE6-CBF1-4E99-80CC-C7426CD00EDD}']
    function GetLayout: TQVTLayout;
    procedure SetLayout(ALayout: TQVTLayout);
    function GetStateSize: TSizeF;
    property StateSize: TSizeF read GetStateSize;
    property Layout: TQVTLayout read GetLayout write SetLayout;
  end;

  IQVTStateCellData = interface(IQVTCellLayoutData)
    ['{CE7EE186-2909-4A90-A3C6-7FB14D8866CA}']
    function GetStateSize: TSizeF;
    function StateSizable: Boolean;
  end;

  IQVTImageCellData = interface(IQVTCellLayoutData)
    ['{4D9429CE-C5C3-4D97-B177-FBD17D315C42}']
    function GetImage: TBitmap;
    function GetHighSpeed: Boolean;
  end;

  TQCellBlockData = record
    Bounds: TRectF;
    Size: TSizeF;
    DrawerType: TQVTDrawerType;
    Drawer: IQVTDrawer;
    Align: TAlignLayout;
  end;

  //
  IQVTMultiBlockCellData = interface(IQVTCellData)
    ['{5DB34749-AB5F-4705-98DC-6EF8436F6D8E}']
    function GetBlockCount: Integer;
    function GetBlockData(AIndex: Integer; var AData: TQCellBlockData): Boolean;
    procedure SetBlockBounds(const AIndex: Integer; ABounds: TRectF);
  end;

  // 带复选框的单元格数据
  IQVTCheckCellData = interface(IQVTTextCellData)
    ['{7C327040-43E8-4341-96BB-7BDE619401EE}']
    // 选择状态
    function GetCheckStates: TQVTCheckStates;
    procedure SetCheckStates(AStates: TQVTCheckStates);
    function GetCheckBounds: TRectF;
    procedure SetCheckBounds(const R: TRectF);
    // 是否跟随直属子结点或父结点变更状态
    function GetFollowStates: Boolean;
    procedure SetFollowStates(const value: Boolean);
    property CheckStates: TQVTCheckStates read GetCheckStates
      write SetCheckStates;
    property FollowStates: Boolean read GetFollowStates write SetFollowStates;
    property CheckBounds: TRectF read GetCheckBounds write SetCheckBounds;
  end;

  // 带单选框的单元格数据
  IQVTRadioCellData = interface(IQVTTextCellData)
    ['{04881B5A-7085-48EE-B2B6-0561E3B851AE}']
    // 单选框分组ID
    function GetGroupName: String;
    procedure SetGroupName(const AName: String);
    // 选择状态，csSomeChecked 等价于csChecked
    function GetCheckStates: TQVTCheckStates;
    procedure SetCheckStates(AStates: TQVTCheckStates);
    function GetRadioBounds: TRectF;
    procedure SetRadioBounds(const R: TRectF);
    property GroupName: String read GetGroupName write SetGroupName;
    property CheckStates: TQVTCheckStates read GetCheckStates
      write SetCheckStates;
    property RadioBounds: TRectF read GetRadioBounds write SetRadioBounds;
  end;

  IQVTDrawer = interface
    ['{3F8FF8B2-F5D4-470F-ADFB-F21D357E0B64}']
    procedure Draw(ARect: TRectF; AData: IQVTCellData);
    function GetEditorBounds(AData: IQVTCellData): TRectF;
    property EditorBounds[AData: IQVTCellData]: TRectF read GetEditorBounds;
  end;

  IQVTStateDrawer = interface
    ['{D8B76D75-A662-413F-BC83-5B35E20CC786}']
    function GetMargins(ALayout: TQVTLayout): TRectF;
    function GetLayout(AData: IQVTCellData; var AStatSize: TSizeF): TQVTLayout;
    function CalcStateRect(const ARect: TRectF; AData: IQVTCellData): TRectF;
    function CalcContentRect(const ARect: TRectF; AData: IQVTCellData): TRectF;
  end;

  IQVTSizableDrawer = interface(IQVTDrawer)
    ['{88914AA6-2E32-4165-84F1-BEDD3EB2B3BA}']
    function GetMargins: TRectF;
    function GetSize(AData: IQVTCellData; const R: TRectF): TSizeF;
  end;

  IQVTMultiDataCell = interface
    ['{4E572010-2517-4D59-947C-8F4430A092A9}']
    function GetDrawerIndex: Integer;
    procedure SetDrawerIndex(const value: Integer);
    property DrawerIndex: Integer read GetDrawerIndex write SetDrawerIndex;
  end;

  // 结点数据
  IQVTNodeData = interface
    ['{900D06CC-A19C-43FD-BC31-F072F0911CA6}']
    // 获取子结点数量
    function GetChildCount: Integer;
    // 遍历
    function GetFirstChildData: IQVTNodeData;
    function GetLastChildData: IQVTNodeData;
    function GetPriorData: IQVTNodeData;
    function GetNextData: IQVTNodeData;
    // 获取指定单元格的绘制方式
    function GetCellDrawer(const AIndex: Integer): IQVTDrawer;
    // 获取指定单元格的数据
    function GetCellData(const AIndex: Integer): IQVTCellData;
    // 获取结点的行号
    function GetRowIndex: Integer;
    property ChildCount: Integer read GetChildCount;
    property CellDrawer[const ACol: Integer]: IQVTDrawer read GetCellDrawer;
    property CellData[const ACol: Integer]: IQVTCellData read GetCellData;
  end;

  IQVirtualNode = interface
    ['{DEFFEB6D-538D-4AFE-BEE6-9A617CB60177}']
    // 结点状态
    function GetStates: TQVTNodeStates;
    procedure SetStates(const States: TQVTNodeStates);
    // 链接
    function GetParent: TQVTNode;
    function GetPrior: TQVTNode;
    function GetNext: TQVTNode;
    function GetFirstChild: TQVTNode;
    function GetLastChild: TQVTNode;
    function GetLevel: Integer;
    function GetHeight: Single;
    procedure SetHeight(const value: Single);
  end;

  IQVTInplaceEditor = interface
    ['{C88AD51A-53ED-4902-8012-9924193AF749}']
    procedure SetBounds(R: TRectF);
    function BeginEdit(ANode: TQVTNode; ACol: Integer): Boolean;
    function EndEdit: Boolean;
    procedure CancelEdit;
    function GetEditing(var ACol: Integer): TQVTNode;
    procedure DialogKey(var Key: Word; Shift: TShiftState);
    procedure Show;
    procedure Hide;
  end;

  TQVTDrawableObject = class(TPersistent, IInterface, IQVTDrawable)
  private
  protected
    FFill: TBrush;
    FStroke: TStrokeBrush;
{$IFNDEF AUTOREFCOUNT}
    [Volatile]
    FRefCount: Integer;
    function GetRefCount: Integer; // inline;
{$ENDIF}
    // 获取行画刷
    function GetFill: TBrush; virtual;
    procedure SetFill(AFill: TBrush); virtual;
    // 获取行画笔
    function GetStroke: TStrokeBrush;
    procedure SetStroke(AStroke: TStrokeBrush);

  public
    constructor Create; overload;
    destructor Destroy; override;
    procedure Assign(src: TPersistent); override;
    function QueryInterface(const IID: TGUID; out Obj): HResult;
      virtual; stdcall;
    function _AddRef: Integer; virtual; stdcall;
    function _Release: Integer; virtual; stdcall;
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;
{$IFNDEF AUTOREFCOUNT}
    property RefCount: Integer read GetRefCount;
{$ENDIF}
    class function NewInstance: TObject; override;
    property Fill: TBrush read GetFill write SetFill;
    property Stroke: TStrokeBrush read GetStroke write SetStroke;
  end;

  TQVTTextDrawableObject = class(TQVTDrawableObject, IQVTTextDrawable)
  protected
    FTextSettings: TTextSettings;
    function GetTextSettings: TTextSettings; virtual;
    procedure SetTextSettings(value: TTextSettings); virtual;
  public
    constructor Create; overload;
    destructor Destroy; override;
    procedure Assign(src: TPersistent); override;
    property TextSettings: TTextSettings read GetTextSettings
      write SetTextSettings;
  end;
{$M+}

  TQVTExtendableObject = class(TInterfacedObject, IQVTExtendable, IInterface)
  protected
    FExts: TList<IInterface>;
    function GetExts: TList<IInterface>;
  public
    destructor Destroy; override;
    function ExtByType(const IID: TGUID; var AValue): Boolean; overload;
    function ExtByType(const AClass: TClass): TObject; overload;
    function ExtByType(const AClass: TClass; var AValue): Boolean; overload;
    function ExtByName(const AName: String): IQVTNamedExt;
    function QueryInterface(const IID: TGUID; out Obj): HResult; stdcall;
    function HasExts: Boolean;
    property Exts: TList<IInterface> read GetExts;
  end;

  TQVTColumnTitle = class(TQVTTextDrawableObject, IQVTCellData,
    IQVTTextCellData, IQVTTextDrawable)
  protected
    [unsafe]
    FColumn: TQVTColumn;
    FText: String;
    [weak]
    FDrawer: IQVTDrawer;
    FSortMarker: TQVTColumnSortMarker;
    FDrawerType: TQVTDrawerType;
    FClickable: Boolean;
    FSortOnClick: Boolean;
    FIsMouseDown: Boolean;
    FIsHover: Boolean;
    FTextSettingsInfo: TTextSettingsInfo;
    function GetColIndex: Integer;
    function GetColumn: Integer;
    procedure SetColumn(const AColumn: Integer);
    function GetColumnId: Integer;
    function GetNode: TQVTNode;
    procedure SetNode(ANode: TQVTNode);
    function GetTreeView: TQVirtualTreeView;
    function GetEnabled: Boolean;
    procedure SetEnabled(value: Boolean);
    function GetText: String;
    procedure SetText(const value: String);
    procedure SetDrawerType(const value: TQVTDrawerType);
    function GetDrawer: IQVTDrawer;
    function GetSides: TSides;
    procedure SetSortMarker(const value: TQVTColumnSortMarker);
    function GetTextSettings: TTextSettings; override;
    procedure SetTextSettings(value: TTextSettings); override;
  public
    constructor Create(AColumn: TQVTColumn); overload; virtual;
    destructor Destroy; override;
    procedure Assign(src: TPersistent); override;
    property Drawer: IQVTDrawer read GetDrawer write FDrawer;
  published
    property TextSettings;
    property Fill;
    property Stroke;
    property Text: String read FText write SetText;
    property DrawerType: TQVTDrawerType read FDrawerType write SetDrawerType;
    property Clickable: Boolean read FClickable write FClickable;
    property SortOnClick: Boolean read FSortOnClick write FSortOnClick;
    property SortMarker: TQVTColumnSortMarker read FSortMarker
      write SetSortMarker;
  end;

  TQVTColumn = class(TCollectionItem, IQVTExtendable, IInterface)
  private
    FTextSettingsInfo: TTextSettingsInfo;
    FTitle: TQVTColumnTitle;
    FDrawer: IQVTDrawer;
    FCellData: IQVTCellData;
    FEditor: IQVTInplaceEditor;
    FFrozen: Boolean;
    FVisible: Boolean;
    FEnabled: Boolean;
    FReadOnly: Boolean;
    FDrawerType: TQVTDrawerType;
    FWidth: Single;
    FMinWidth, FMaxWidth: Single;
    FSortIndex: Integer;
    FTag: NativeInt;
    FExts: IQVTExtendable;
    procedure SetTextSettings(const value: TTextSettings);
    procedure SetFrozen(const value: Boolean);
    procedure SetTitle(const ATitle: TQVTColumnTitle);
    function GetDrawer: IQVTDrawer;
    procedure SetVisible(value: Boolean);
    procedure SetEnabled(value: Boolean);
    procedure SetReadOnly(value: Boolean);
    procedure SetDrawerType(const value: TQVTDrawerType);
    function GetTreeView: TQVirtualTreeView;
    procedure SetWidth(const value: Single);
    procedure SetMaxWidth(const value: Single);
    procedure SetMinWidth(const value: Single);
    procedure SetSortIndex(const value: Integer);
    function GetTextSettings: TTextSettings;
    function GetFixedWidth: Single;
    procedure SetFixedWidth(const value: Single);
    procedure NeedExts; inline;
  published
    property TextSettings: TTextSettings read GetTextSettings
      write SetTextSettings;
    property Title: TQVTColumnTitle read FTitle write SetTitle;
    property Frozen: Boolean read FFrozen write SetFrozen;
    property Visible: Boolean read FVisible write SetVisible;
    property ReadOnly: Boolean read FReadOnly write SetReadOnly;
    property Enabled: Boolean read FEnabled write SetEnabled;
    property DrawerType: TQVTDrawerType read FDrawerType write SetDrawerType;
    property Width: Single read FWidth write SetWidth;
    property MinWidth: Single read FMinWidth write SetMinWidth;
    property MaxWidth: Single read FMaxWidth write SetMaxWidth;
    property Drawer: IQVTDrawer read GetDrawer write FDrawer;
    property CellData: IQVTCellData read FCellData write FCellData;
    property Editor: IQVTInplaceEditor read FEditor write FEditor;
    property Tag: NativeInt read FTag write FTag;
  public
    constructor Create(ACollection: TCollection); override;
    destructor Destroy; override;
    procedure Assign(src: TPersistent); override;
    function ExtByType(const IID: TGUID; var AValue): Boolean; overload;
    function ExtByType(const AClass: TClass): TObject; overload;
    function ExtByType(const AClass: TClass; var AValue): Boolean; overload;
    function ExtByName(const AName: String): IQVTNamedExt;
    function GetExts: TList<IInterface>;
    function HasExts: Boolean;
    function _AddRef: Integer; stdcall;
    function _Release: Integer; stdcall;
    function QueryInterface(const IID: TGUID; out Obj): HResult; stdcall;
    property TreeView: TQVirtualTreeView read GetTreeView;
    property SortIndex: Integer read FSortIndex write SetSortIndex;
    property FixedWidth: Single read GetFixedWidth write SetFixedWidth;
    property Exts: TList<IInterface> read GetExts;
  end;

  TQVTColumns = class(TOwnedCollection)
  private
    function GetTreeView: TQVirtualTreeView;
  protected
    function GetAttrCount: Integer; override;
    function GetAttr(Index: Integer): string; override;
    function GetItemAttr(Index, ItemIndex: Integer): string; override;
    procedure Update(Item: TCollectionItem); override;
  public
    function GetItems(const AIndex: Integer): TQVTColumn;
  public
    constructor Create(AOwner: TPersistent); overload;
    function Add: TQVTColumn; overload;
    property Items[const AIndex: Integer]: TQVTColumn read GetItems; default;
    property TreeView: TQVirtualTreeView read GetTreeView;
  end;

  TQVTHeaderOption = (hoVisible, hoResizable, hoSelectColumn, hoSelectAll,
    hoMultiSortColumns);
  TQVTHeaderOptions = set of TQVTHeaderOption;

  TQVTHeader = class(TPersistent)
  protected
    FColumns: TQVTColumns;
    FOptions: TQVTHeaderOptions;
    FMasterColumn: Integer;
    FAutoSizeColumn: Integer;
    [unsafe]
    FTreeView: TQVirtualTreeView;
    FHeight: Single;
    FMinHeight, FMaxHeight: Single;
    procedure SetColumns(const value: TQVTColumns);
    procedure SetOptions(const value: TQVTHeaderOptions);
    procedure SetMasterColumn(const value: Integer);
    function GetWidth: Single;
    procedure SetHeight(const value: Single);
    procedure SetMaxHeight(const value: Single);
    procedure SetMinHeight(const value: Single);
    procedure SetAutoSizeColumn(const value: Integer);
    function GetOwner: TPersistent; override;
  public
    constructor Create(AOwner: TQVirtualTreeView); overload;
    destructor Destroy; override;
    procedure Assign(src: TPersistent); override;
    property TreeView: TQVirtualTreeView read FTreeView;
  published
    property Columns: TQVTColumns read FColumns write SetColumns;
    property Options: TQVTHeaderOptions read FOptions write SetOptions;
    property MasterColumn: Integer read FMasterColumn write SetMasterColumn;
    property AutoSizeColumn: Integer read FAutoSizeColumn
      write SetAutoSizeColumn;
    property Height: Single read FHeight write SetHeight;
    property MinHeight: Single read FMinHeight write SetMinHeight;
    property MaxHeight: Single read FMaxHeight write SetMaxHeight;
    property Width: Single read GetWidth;

  end;

  // 结点
  TQVTNodeClass = class of TQVTNode;

  TNodeInsertPosition = (ipNoWhere, ipBefore, ipAfter, ipFirstChild,
    ipLastChild);

  //
  TQVTNode = class(TQVTExtendableObject, IQVirtualNode, IQVTNodeData)
  private
    FTag: NativeInt;
  protected
    FStates: TQVTNodeStates; // 结点的状态
    [unsafe]
    FParent: TQVTNode; // 父结点
    [unsafe]
    FTreeView: TQVirtualTreeView; // 所隶属的树
    [unsafe]
    FNext: TQVTNode; // 下一个邻居结点
    [unsafe]
    FPrior: TQVTNode; // 前一个邻居结点
    [unsafe]
    FFirstChild: TQVTNode; // 首个子结点
    [unsafe]
    FLastChild: TQVTNode; // 最后一个子结点
    [unsafe]
    FLastInitChild: TQVTNode; // 最后一个初始化的子结点
    [unsafe]
    FFirstDirtyChild: TQVTNode;
    FCreatedCount: Integer; // 已经创建的子结点数量
    FCount: Integer; // 子结点数量，默认为-1，未知
    FLevel: Integer; // 结点的级别（初始为-1，所以不要直接读取它）
    FRowIndex: Integer; // 当前行号，默认为-1，未知，如果大于当前脏读行号或为-1，则会临时计算
    FDistance: Single; // 当前行距离首个显示的结点的距离
    FHeight: Single; // 当前行高，如果<0，则继承TreeView的默认行高，否则为缓存的本行行高
    FMinHeight: Single;
    FMaxHeight: Single;
    FIndex: Integer; // 当前结点在父结点中的索引号
    FLevelDirtyCounter: Integer;
    FVisibleRowIndex: Integer; // 当结点可见时，它所在的行号
    FDisplayRect: TRectF; // 当前结点的显示区域，仅可见时有意义
    FButtonRect: TRectF; // 当前结点如果包含子结点，则展开/收起按钮的位置
    function GetCanFocus: Boolean;
    procedure SetChildCount(const value: Integer); virtual;
    function GetHeight: Single; virtual;
    procedure SetHeight(const value: Single);
    procedure InitChildren;
    procedure CleanDirty(ANode: TQVTNode);
    procedure Dirty(ANode: TQVTNode);
    procedure SetMaxHeight(const value: Single);
    procedure SetMinHeight(const value: Single);
    function GetDisplayRect: TRectF;
    function GetCellRect(AColumn: Integer): TRectF;
    function GetIndex: Integer;
    function GetIsRoot: Boolean;
    function GetIsExpanded: Boolean;
    procedure SetIsExpanded(const value: Boolean);
    function GetIsFirstChild: Boolean;
    function GetIsLastChild: Boolean;
  public
    constructor Create(AOwner: TQVirtualTreeView); overload; virtual;
    destructor Destroy; override;
    // 结点状态
    function GetStates: TQVTNodeStates;
    procedure SetStates(const value: TQVTNodeStates);
    // 链接
    function GetParent: TQVTNode;
    function GetPrior: TQVTNode;
    function GetNext: TQVTNode;
    function GetFirstChild: TQVTNode;
    function GetLastChild: TQVTNode;
    // IQVTNodeData
    function GetFirstChildData: IQVTNodeData;
    function GetLastChildData: IQVTNodeData;
    function GetPriorData: IQVTNodeData;
    function GetNextData: IQVTNodeData;
    function GetFirstVisibleChild: TQVTNode;
    function GetNextVisibleChild(AChild: TQVTNode): TQVTNode;
    function GetPriorVisible(AChild: TQVTNode): TQVTNode;
    function GetLastVisibleChild: TQVTNode;
    function AddChild: TQVTNode;
    function Insert(APos: TNodeInsertPosition): TQVTNode;
    function HasChildren: Boolean;
    function GetLevel: Integer;
    function GetChildCount: Integer; virtual;
    function GetCellDrawer(const AIndex: Integer): IQVTDrawer; virtual;
    function GetCellData(const AIndex: Integer): IQVTCellData; virtual;
    function GetRowIndex: Integer;
    procedure MoveTo(ATarget: TQVTNode; AMode: TNodeInsertPosition);
    procedure ScrollToView;
    procedure Delete;
    procedure Clear;
    procedure Cascade;
    procedure Expand(const ANest: Boolean = false);
    procedure SetFocus;
    procedure NeedInitialized;
    procedure Reinit(ANest: Boolean = false);
    procedure ReinitChildren(ANest: Boolean = false);
    function IsChildOf(ANode: TQVTNode): Boolean;
    function IsParentOf(ANode: TQVTNode): Boolean;

    property Parent: TQVTNode read FParent;
    property States: TQVTNodeStates read FStates write SetStates;
    property Prior: TQVTNode read FPrior;
    property Next: TQVTNode read GetNext;
    property Level: Integer read GetLevel;
    property ChildCount: Integer read GetChildCount write SetChildCount;
    property CellDrawer[const AIndex: Integer]: IQVTDrawer read GetCellDrawer;
    property CellData[const AIndex: Integer]: IQVTCellData read GetCellData;
    property RowIndex: Integer read GetRowIndex;
    property Height: Single read GetHeight write SetHeight;
    property TreeView: TQVirtualTreeView read FTreeView;
    property CanFocus: Boolean read GetCanFocus;
    property MinHeight: Single read FMinHeight write SetMinHeight;
    property MaxHeight: Single read FMaxHeight write SetMaxHeight;
    property DisplayRect: TRectF read GetDisplayRect;
    property CellRect[AColumn: Integer]: TRectF read GetCellRect;
    property Index: Integer read GetIndex;
    property IsRoot: Boolean read GetIsRoot;
    property IsFirstChild: Boolean read GetIsFirstChild;
    property IsLastChild: Boolean read GetIsLastChild;
    property FirstChild: TQVTNode read GetFirstChild;
    property LastChild: TQVTNode read GetLastChild;
    property IsExpanded: Boolean read GetIsExpanded write SetIsExpanded;
    property Tag: NativeInt read FTag write FTag;
  end;

  // 默认的绘制器类定义
  TQVTBaseDrawer = class(TComponent, IQVTDrawer)
  protected
    procedure Draw(ARect: TRectF; AData: IQVTCellData); virtual; abstract;
    function GetEditorBounds(AData: IQVTCellData): TRectF; virtual;
  public
    procedure BeforeDestruction; override;
  end;

  TQVTCellDrawerEvent = procedure(Sender: TQVTBaseDrawer; ARect: TRectF;
    AData: IQVTCellData) of object;

  [ComponentPlatformsAttribute(AllCurrentPlatforms)]
  TQVTCustomDrawer = class(TQVTBaseDrawer)
  private
    FOnDraw: TQVTCellDrawerEvent;
  protected
    procedure Draw(ARect: TRectF; AData: IQVTCellData); override;
  published
    property OnDraw: TQVTCellDrawerEvent read FOnDraw write FOnDraw;
  end;

  TQVTTextDrawer = class(TQVTBaseDrawer)
  protected
    FTextRect: TRectF;
    function ColorWithOpacity(AColor: TAlphaColor; AOpacity: Single)
      : TAlphaColor; inline;
    function GetFill(AData: IQVTCellData; AllowNull: Boolean): TBrush;
    function GetStroke(AData: IQVTCellData; AllowNull: Boolean): TStrokeBrush;
    function GetTextSettings(AData: IQVTCellData; AllowNull: Boolean)
      : TTextSettings;
    procedure DrawText(ARect: TRectF; ATextData: IQVTTextCellData;
      ATextSettings: TTextSettings); overload;
    procedure DrawText(ATreeView: TQVirtualTreeView; ARect: TRectF;
      AText: String; ATextSettings: TTextSettings; AEnabled: Boolean); overload;
    procedure Draw(ARect: TRectF; AData: IQVTCellData); override;
  end;

  TQVTIndicatorDrawer = class(TQVTTextDrawer)
  protected
    procedure Draw(ARect: TRectF; AData: IQVTCellData); override;
  end;

  // 默认的进度状态绘制器，用于绘制进度条
  TQVTProgressDrawer = class(TQVTTextDrawer)
    procedure Draw(ARect: TRectF; AData: IQVTCellData); override;
  end;

  TQVTStateDrawer = class(TQVTTextDrawer, IQVTStateDrawer)
  protected
    function GetLayout(AData: IQVTCellData; var AStateSize: TSizeF): TQVTLayout;
    function GetMargins(ALayout: TQVTLayout): TRectF;
    function CalcStateRect(const ARect: TRectF; AData: IQVTCellData): TRectF;
      overload; virtual;
    function CalcStateRect(const ARect: TRectF; const ASize: TSizeF;
      ALayout: TQVTLayout): TRectF; overload;
    function CalcContentRect(const ARect: TRectF; AData: IQVTCellData): TRectF;
      overload; virtual;
    function CalcContentRect(const ARect, AStateRect: TRectF;
      ALayout: TQVTLayout): TRectF; overload;
    procedure CalcLayouts(AData: IQVTCellData; const ARect: TRectF;
      var AStateRect, AContentRect: TRectF);
    procedure DrawPath(AData: IQVTCellData; APath: TPathData;
      AOpacity: Single); virtual;
  end;

  TQVTHeaderDrawer = class(TQVTStateDrawer)
  private
    class var FStatePath: array [0 .. 1] of TPathData;
    class function GetAscPath: TPathData; static;
    class function GetDescPath: TPathData; static;
  protected
    FCurrentPath: array [0 .. 1] of TPathData;
    procedure Draw(ARect: TRectF; AData: IQVTCellData); override;
  public
    class constructor Create;
    class destructor Destroy;
    class property AscPath: TPathData read GetAscPath;
    class property DescPath: TPathData read GetDescPath;
  end;

  TQVTColorDrawer = class(TQVTStateDrawer)
  protected
    procedure Draw(ARect: TRectF; AData: IQVTCellData); override;
  end;

  // 默认复选框绘制器，用于绘制复选状态
  TQVTCheckDrawer = class(TQVTStateDrawer)
  private
    // 六种状态：未选中、选中、部分选中各启用和禁用两种
    class var FCheckStatePath: array [0 .. 2] of TPathData;
    class function GetPathData(AStates: TQVTCheckStates): TPathData; static;
    class function StatePathIndex(AStates: TQVTCheckStates): Integer; static;
    class function GetCheckedPath: TPathData; static;
    class function GetSomeCheckedPath: TPathData; static;
    class function GetUncheckPath: TPathData; static;
  protected
    FCurrentPath: array [0 .. 2] of TPathData;
    procedure Draw(ARect: TRectF; AData: IQVTCellData); override;
    class property StatePath[AStates: TQVTCheckStates]: TPathData
      read GetPathData;
  public
    class property UncheckPath: TPathData read GetUncheckPath;
    class property CheckedPath: TPathData read GetCheckedPath;
    class property SomeCheckedPath: TPathData read GetSomeCheckedPath;
  end;

  // 默认的单选框绘制器，用于绘制单选状态
  TQVTRadioDrawer = class(TQVTStateDrawer)
  private
    class var FCheckStatePath: array [Boolean] of TPathData;
    class function GetCheckedPath: TPathData; static;
    class function GetUncheckPath: TPathData; static;
  protected
    FCurrentPath: array [Boolean] of TPathData;
    procedure Draw(ARect: TRectF; AData: IQVTCellData); override;
    class property UncheckPath: TPathData read GetUncheckPath;
    class property CheckedPath: TPathData read GetCheckedPath;
  end;

  // 默认的图片绘制器，用于绘制图片结点
  TQVTImageDrawer = class(TQVTStateDrawer)
  protected
    procedure Draw(ARect: TRectF; AData: IQVTCellData); override;
  end;

  // 默认的主列绘制器，用于绘制带树形视图的文本内容
  TQVTMasterDrawer = class(TQVTImageDrawer)
  const
    ButtonSize = 4.5;
  private
    class var FStatePath: array [Boolean] of TPathData;
    class function GetCascadedPath: TPathData; static;
    class function GetExpandedPath: TPathData; static;
    class procedure SetCascadedPath(const value: TPathData); static;
    class procedure SetExpandedPath(const value: TPathData); static;
  protected
    FCurrentPath: array [Boolean] of TPathData;
    procedure Draw(ARect: TRectF; AData: IQVTCellData); override;
    function GetEditorBounds(AData: IQVTCellData): TRectF; override;
  public
    class constructor Create;
    class destructor Destroy;
    destructor Destroy; override;
    class property ExpandedPath: TPathData read GetExpandedPath
      write SetExpandedPath;
    class property CascadedPath: TPathData read GetCascadedPath
      write SetCascadedPath;
  end;

  // 默认带状态图片绘制器，用于绘制带状态的结点
  TQVTImageStateDrawer = class(TQVTStateDrawer)
    procedure Draw(ARect: TRectF; AData: IQVTCellData); override;
  end;

  TQVTMoneyDrawer = class(TQVTTextDrawer)
    procedure Draw(ARect: TRectF; AData: IQVTCellData); override;
  end;

  TQCellMultiDrawers = class(TInterfacedObject, IQVTDrawer)
  private
  protected
    FDrawers: TList<IQVTSizableDrawer>;
    FIsVertical: Boolean;
    procedure Draw(ARect: TRectF; AData: IQVTCellData);
    function GetEditorBounds(AData: IQVTCellData): TRectF; virtual;
  public
    constructor Create; overload;
    destructor Destroy; override;
    function Add(const ADrawer: IQVTSizableDrawer): Integer;
    procedure Delete(const AIdx: Integer);
    procedure Clear;
    property IsVertical: Boolean read FIsVertical write FIsVertical;
  end;

  TQGetSizeProc = reference to function(AData: IQVTCellData;
    const R: TRectF): TSizeF;

  TQSizableDrawer = class(TInterfacedObject, IQVTDrawer, IQVTSizableDrawer)
  private
    FRealDrawer: IQVTDrawer;
    FMargins: TRectF;
    FSizeProc: TQGetSizeProc;
    procedure Draw(ARect: TRectF; AData: IQVTCellData); virtual;
    function GetMargins: TRectF; virtual;
    function GetSize(AData: IQVTCellData; const R: TRectF): TSizeF; virtual;
    function GetEditorBounds(AData: IQVTCellData): TRectF; virtual;
  public
    constructor Create(ADrawer: IQVTDrawer; const AMargins: TRectF;
      ASizeProc: TQGetSizeProc);
    property Margins: TRectF read FMargins write FMargins;
    property OnGetSize: TQGetSizeProc read FSizeProc write FSizeProc;
  end;

  // 默认的结点单元格数据类型定义
  TQVTDefaultCellData = class(TQVTDrawableObject, IQVTCellData)
  private
  protected
    [unsafe]
    FNode: TQVTNode;
    FColumn: Integer;
    function GetColumn: Integer; virtual;
    procedure SetColumn(const AColumn: Integer);
    function GetColumnId: Integer;
    function GetNode: TQVTNode; virtual;
    procedure SetNode(ANode: TQVTNode); virtual;
    function GetTreeView: TQVirtualTreeView; virtual;
    function GetEnabled: Boolean; virtual;
    function GetSides: TSides; virtual;
  public
    constructor Create(ANode: TQVTNode; AColIndex: Integer); overload; virtual;
    constructor Create; overload;
    property Node: TQVTNode read FNode write FNode;
    property Column: Integer read FColumn write FColumn;
    property TreeView: TQVirtualTreeView read GetTreeView;
    property Enabled: Boolean read GetEnabled;
    property Sides: TSides read GetSides;
  end;

  TQVTCellTextGetEvent = procedure(ASender: TObject; var AText: String)
    of object;
  TQVTCellTextSetEvent = procedure(ASender: TObject; const AText: String)
    of object;
  TQVTCellTextValidEvent = procedure(ASender: TObject; const AText: String;
    var Accept: Boolean) of object;

  TQVTCustomCell = class(TComponent, IQVTCellData)
  private

  protected
    [unsafe]
    FNode: TQVTNode;
    FColumn: Integer;
    FEnabled: Boolean;
    FSides: TSides;
    function GetColumn: Integer; virtual;
    procedure SetColumn(const AColumn: Integer);
    function GetNode: TQVTNode; virtual;
    procedure SetNode(ANode: TQVTNode); virtual;
    function GetTreeView: TQVirtualTreeView; virtual;
    function GetEnabled: Boolean; virtual;
    function GetSides: TSides; virtual;
    function GetColumnId: Integer;
  public
    constructor Create(AOwner: TComponent); override;
    procedure BeforeDestruction; override;
    property Column: Integer read FColumn write FColumn;
    property ColumnId: Integer read GetColumnId;
    property Node: TQVTNode read FNode write FNode;
  published
    property Enabled: Boolean read FEnabled write FEnabled;
    property Sides: TSides read FSides write FSides;
  end;

  TQVTCellNotifyType = (cntUnknown, cntData, cntDrawer, cntEditor);

  TQVTCellNotifyMessage = class(TMessage<TQVTCellNotifyType>)

  end;

  // 文本数据辅助
  [ComponentPlatformsAttribute(AllCurrentPlatforms)]
  TQVTCustomTextCell = class(TQVTCustomCell, IQVTDrawable, IQVTTextCellData,
    IQVTEditableTextCellData, IQVTTextDrawable)
  private
    procedure SetTextSettings(const value: TTextSettings);
  protected
    FFill: TBrush;
    FStroke: TStrokeBrush;
    FTextSettings: TTextSettingsInfo;

    FOnSetText: TQVTCellTextSetEvent;
    FDefaultText: String;
    FOnGetText: TQVTCellTextGetEvent;
    FOnValidText: TQVTCellTextValidEvent;

    // 获取行画刷
    function GetFill: TBrush; virtual;
    procedure SetFill(AFill: TBrush); virtual;
    // 获取行画笔
    function GetStroke: TStrokeBrush;
    procedure SetStroke(AStroke: TStrokeBrush);
    function GetText: String; virtual;
    procedure SetText(const S: String); virtual;
    function GetTextSettings: TTextSettings;
    function GetTextSettingsClass: TTextSettingsInfo.TCustomTextSettingsClass;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Assign(src: TPersistent); override;
    property Text: String read GetText write SetText;
  published
    property DefaultText: String read FDefaultText write FDefaultText;
    property Fill: TBrush read GetFill write SetFill;
    property Stroke: TStrokeBrush read GetStroke write SetStroke;
    property TextSettings: TTextSettings read GetTextSettings
      write SetTextSettings;
    property OnGetText: TQVTCellTextGetEvent read FOnGetText write FOnGetText;
    property OnSetText: TQVTCellTextSetEvent read FOnSetText write FOnSetText;
    property OnValidText: TQVTCellTextValidEvent read FOnValidText
      write FOnValidText;
  end;

  [ComponentPlatformsAttribute(AllCurrentPlatforms)]
  TQVTDBAdapter = class(TComponent)
  private
    FAddOrphanAsRoot: Boolean;

  type
    TQDBNodeExt = class(TInterfacedObject)
    private
      FBookmark: TBookmark;
      FKeyValue, FParentValue: String;
      FChildren: TObjectList<TQDBNodeExt>;
      FParent: TQDBNodeExt;
      FFlags: Integer;
      function GetChildren: TObjectList<TQDBNodeExt>;
    public
      constructor Create;
      destructor Destroy; override;
      property Children: TObjectList<TQDBNodeExt> read GetChildren;
    end;
  protected
    FDataSet: TDataSet;
    FTreeView: TQVirtualTreeView;
    FKeyField: TField;
    FParentField: TField;
    FRootItems: TObjectList<TQDBNodeExt>;
    FDataSource: TDataSource;
    FRootParentValue: String;
    procedure SetDataSource(const value: TDataSource);
    procedure SetDataSet(const value: TDataSet);
    procedure SetTreeView(const value: TQVirtualTreeView);
    procedure SetKeyField(const value: TField);
    procedure SetParentField(const value: TField);
    procedure ContentChanged;
    procedure DoInitNode(Sender: TQVirtualTreeView; ANode: TQVTNode);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property TreeView: TQVirtualTreeView read FTreeView write SetTreeView;
    property DataSet: TDataSet read FDataSet write SetDataSet;
    property DataSource: TDataSource read FDataSource write SetDataSource;
    property KeyField: TField read FKeyField write SetKeyField;
    property ParentField: TField read FParentField write SetParentField;
    property RootParentValue: String read FRootParentValue
      write FRootParentValue;
    property AddOrphanAsRoot: Boolean read FAddOrphanAsRoot
      write FAddOrphanAsRoot;
  end;

  [ComponentPlatformsAttribute(AllCurrentPlatforms)]
  TQVTDBTextCell = class(TQVTCustomTextCell)
  private
    procedure SetField(const value: TField);
  protected
    FField: TField;
    function GetText: String; override;
    procedure SetText(const S: String); override;
    function GetEnabled: Boolean; override;
  published
    property Field: TField read FField write SetField;
  end;

  TQVTPickListCellGetEvent = procedure(Sender: TObject; AList: TStrings)
    of object;

  [ComponentPlatformsAttribute(AllCurrentPlatforms)]
  TQVTPickListCell = class(TQVTCustomTextCell, IQVTPickListCellData)
  protected
    FItems: TStrings;
    FOnGetItems: TQVTPickListCellGetEvent;
    procedure SetItems(const value: TStrings);
    function GetItems(AList: TStrings): Integer;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property Items: TStrings read FItems write SetItems;
    property OnGetItems: TQVTPickListCellGetEvent read FOnGetItems
      write FOnGetItems;
  end;

  TQVTGetCellCheckStates = procedure(ASender: TObject;
    var AStates: TQVTCheckStates) of object;
  TQVTSetCellCheckStates = procedure(ASender: TObject; AStates: TQVTCheckStates)
    of object;

  [ComponentPlatformsAttribute(AllCurrentPlatforms)]
  TQVTCustomCheckCell = class(TQVTCustomTextCell, IQVTCheckCellData,
    IVQTCellSpaceEditCellData, IQVTCellMouseEditCellData)
  protected
    FCheckStates: TQVTCheckStates;
    FCheckBounds: TRectF;
    FFollowStates: Boolean;
    FUpdateSender: TQVTNode;
    FUpdating: Boolean;
    FOnGetStates: TQVTGetCellCheckStates;
    FOnValidStates: TQVTGetCellCheckStates;
    FOnSetStates: TQVTSetCellCheckStates;
    function GetCheckStates: TQVTCheckStates; virtual;
    procedure SetCheckStates(AStates: TQVTCheckStates); virtual;
    function GetFollowStates: Boolean;
    procedure SetFollowStates(const value: Boolean);
    function GetCheckBounds: TRectF;
    procedure SetCheckBounds(const R: TRectF);
    procedure UpdateStates;
    procedure MouseDown(AButton: TMouseButton; AShift: TShiftState;
      const APos: TPointF);
    procedure MouseMove(AShift: TShiftState; const APos: TPointF);
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState;
      const APos: TPointF);
    procedure MouseClick(Button: TMouseButton; Shift: TShiftState;
      const APos: TPointF);
    procedure NextValue;
  published
    property CheckStates: TQVTCheckStates read GetCheckStates
      write SetCheckStates;
    property FollowStates: Boolean read FFollowStates write SetFollowStates;
    property OnGetStates: TQVTGetCellCheckStates read FOnGetStates
      write FOnGetStates;
    property OnValidStates: TQVTGetCellCheckStates read FOnValidStates
      write FOnValidStates;
    property OnSetStates: TQVTSetCellCheckStates read FOnSetStates
      write FOnSetStates;
  end;

  [ComponentPlatformsAttribute(AllCurrentPlatforms)]
  TQVTCustomRadioCell = class(TQVTCustomTextCell, IQVTRadioCellData,
    IVQTCellSpaceEditCellData, IQVTCellMouseEditCellData)
  private
    FCheckStates: TQVTCheckStates;
    FGroupName: String;
    FRadioBounds: TRectF;
    FMsgId: Integer;
    FOnGetStates: TQVTGetCellCheckStates;
    FOnValidStates: TQVTGetCellCheckStates;
    FOnSetStates: TQVTSetCellCheckStates;
  protected
    function GetGroupName: String;
    procedure SetGroupName(const AName: String);
    // 选择状态，csSomeChecked 等价于csChecked
    function GetCheckStates: TQVTCheckStates;
    procedure SetCheckStates(AStates: TQVTCheckStates);
    function GetRadioBounds: TRectF;
    procedure SetRadioBounds(const R: TRectF);
    procedure MouseDown(AButton: TMouseButton; AShift: TShiftState;
      const APos: TPointF);
    procedure MouseMove(AShift: TShiftState; const APos: TPointF);
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState;
      const APos: TPointF);
    procedure MouseClick(Button: TMouseButton; Shift: TShiftState;
      const APos: TPointF);
    procedure DoStateChanged(const ASender: TObject; const AMessage: TMessage);
    procedure NextValue;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property GroupName: String read FGroupName write FGroupName;
    property CheckStates: TQVTCheckStates read FCheckStates
      write SetCheckStates;
    property OnGetStates: TQVTGetCellCheckStates read FOnGetStates
      write FOnGetStates;
    property OnValidStates: TQVTGetCellCheckStates read FOnValidStates
      write FOnValidStates;
    property OnSetStates: TQVTSetCellCheckStates read FOnSetStates
      write FOnSetStates;
  end;

  TQVTGetCellProgressEvent = procedure(ASender: TObject; var AProgress: Single)
    of object;
  TQVTSetCellProgressEvent = procedure(ASender: TObject; AProgress: Single)
    of object;

  [ComponentPlatformsAttribute(AllCurrentPlatforms)]
  TQVTCustomProgressCell = class(TQVTCustomTextCell, IQVTProgressCellData)
  private
    FOnGetProgress: TQVTGetCellProgressEvent;
    FOnValidProgress: TQVTGetCellProgressEvent;
    FOnSetProgress: TQVTSetCellProgressEvent;
    procedure SetProgress(const value: Single);
  protected
    FProgress: Single;
    function GetProgress: Single;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property Progress: Single read FProgress write SetProgress;
    property OnGetProgress: TQVTGetCellProgressEvent read FOnGetProgress
      write FOnGetProgress;
    property OnValidProgress: TQVTGetCellProgressEvent read FOnValidProgress
      write FOnValidProgress;
    property OnSetProgress: TQVTSetCellProgressEvent read FOnSetProgress
      write FOnSetProgress;
  end;

  TQVTCellImageEvent = procedure(ASender: TObject; ABitmap: TBitmap) of object;

  [ComponentPlatformsAttribute(AllCurrentPlatforms)]
  TQVTImageCell = class(TQVTCustomCell, IQVTImageCellData)
  protected
    FBitmap: TBitmap;
    FHighSpeed: Boolean;
    FOnGetImage: TQVTCellImageEvent;
    FOnSetImage: TQVTCellImageEvent;
    FLayout: TQVTLayout;
    procedure SetImage(const value: TBitmap);
    function GetImage: TBitmap;
    function GetHighSpeed: Boolean;
    function GetLayout: TQVTLayout;
    procedure SetLayout(ALayout: TQVTLayout);
    function GetStateSize: TSizeF;
    procedure SetHighSpeed(const value: Boolean);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property Bitmap: TBitmap read GetImage write SetImage;
    property HighSpeed: Boolean read FHighSpeed write SetHighSpeed;
    property Layout: TQVTLayout read FLayout write SetLayout;
    property OnGetImage: TQVTCellImageEvent read FOnGetImage write FOnGetImage;
    property OnSetImage: TQVTCellImageEvent read FOnSetImage write FOnSetImage;
  end;

  TQVTCheckCellData = class(TQVTDefaultCellData, IQVTTextCellData,
    IQVTCheckCellData)
  protected
    FCheckStates: TQVTCheckStates;
    FCheckBounds: TRectF;
    FFollowStates: Boolean;
    FUpdating: Boolean;
    function GetText: String; virtual;
    function GetCheckStates: TQVTCheckStates; virtual;
    procedure SetCheckStates(AStates: TQVTCheckStates); virtual;
    function GetFollowStates: Boolean;
    procedure SetFollowStates(const value: Boolean);
    function GetCheckBounds: TRectF;
    procedure SetCheckBounds(const R: TRectF);
    procedure UpdateStates;
  public

  end;

  // Editor basic support
  TQVTCellEditorClass = class of TQVTBaseEditor;

  TQVTBaseEditor = class(TComponent, IQVTInplaceEditor)
  private
    FEnterAsTab: Boolean;
  protected
    FControlClass: TComponentClass;
    FControl: TControl;
    FNode: TQVTNode;
    FColumn: Integer;
    function GetControl: TControl; virtual;
    procedure SetBounds(R: TRectF); virtual;
    function BeginEdit(ANode: TQVTNode; ACol: Integer): Boolean; virtual;
    function EndEdit: Boolean; virtual;
    procedure CancelEdit; virtual;
    function GetEditing(var ACol: Integer): TQVTNode; virtual;
    procedure Show; virtual;
    procedure Hide; virtual;

    procedure DialogKey(var Key: Word; Shift: TShiftState); virtual;
    procedure DoKeyDown(Sender: TObject; var Key: Word;
      var KeyChar: System.WideChar; Shift: TShiftState); virtual;
  public
    constructor Create(AOwner: TComponent); overload; override;
    destructor Destroy; override;
    procedure BeforeDestruction; override;
    property ControlClass: TComponentClass read FControlClass
      write FControlClass;
    property Node: TQVTNode read FNode;
    property Column: Integer read FColumn;
    property Control: TControl read GetControl;
  published
    property EnterAsTab: Boolean read FEnterAsTab write FEnterAsTab;
  end;

  [ComponentPlatformsAttribute(AllCurrentPlatforms)]
  TQVTTextEditor = class(TQVTBaseEditor)
  protected
    function BeginEdit(ANode: TQVTNode; ACol: Integer): Boolean; override;
    function EndEdit: Boolean; override;
    procedure CancelEdit; override;
  public
    constructor Create(AOwner: TComponent); override;
  end;

  [ComponentPlatformsAttribute(AllCurrentPlatforms)]
  TQVTListEditor = class(TQVTBaseEditor)
  private
    FNextValueOnDoubleClick: Boolean;
    FTextEditable: Boolean;
    procedure SetTextEditable(const value: Boolean);
  protected
    function BeginEdit(ANode: TQVTNode; ACol: Integer): Boolean; override;
    function EndEdit: Boolean; override;
    procedure DoDoubleClick(ASender: TObject);
    procedure DialogKey(var Key: Word; Shift: TShiftState); override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property NextValueOnDoubleClick: Boolean read FNextValueOnDoubleClick
      write FNextValueOnDoubleClick;
    property TextEditable: Boolean read FTextEditable write SetTextEditable;
  end;

  [ComponentPlatformsAttribute(AllCurrentPlatforms)]
  TQVTColorEditor = class(TQVTBaseEditor)
  protected
    function BeginEdit(ANode: TQVTNode; ACol: Integer): Boolean; override;
    function EndEdit: Boolean; override;
  public
    constructor Create(AOwner: TComponent); override;
  end;

  [ComponentPlatformsAttribute(AllCurrentPlatforms)]
  TQVTDialogEditor = class(TQVTTextEditor)
  protected
    FEditButton: TEditButton;
    FOnShowEditDialog: TNotifyEvent;
    function GetControl: TControl; override;
    procedure DoEditButtonClick(ASender: TObject); virtual;
  published
    property OnShowEditDialog: TNotifyEvent read FOnShowEditDialog
      write FOnShowEditDialog;
  end;

  TQVTGetCellDataEvent = procedure(Sender: TQVirtualTreeView; ANode: TQVTNode;
    ACol: Integer; var AData: IQVTCellData) of object;
  TQVTGetCellDrawerEvent = procedure(Sender: TQVirtualTreeView; ANode: TQVTNode;
    ACol: Integer; var ADrawer: IQVTDrawer) of object;
  TQVTNodeNotifyEvent = procedure(Sender: TQVirtualTreeView; ANode: TQVTNode)
    of object;
  TQVTTitleNotifyEvent = procedure(Sender: TQVirtualTreeView; ACol: Integer)
    of object;
  TQVTColumnNotifyEvent = procedure(Sender: TQVirtualTreeView; ANode: TQVTNode;
    ACol: Integer) of object;
  TQVTCellClickEvent = procedure(Sender: TQVirtualTreeView; ANode: TQVTNode;
    ACol: Integer; APos: TPointF) of object;
  TQVTAcceptEvent = procedure(Sender: TQVirtualTreeView; ANode: TQVTNode;
    ACol: Integer; var Accept: Boolean) of object;
  TQVTGetCellEditorEvent = procedure(Sender: TQVirtualTreeView; ANode: TQVTNode;
    ACol: Integer; var AEditor: IQVTInplaceEditor) of object;
  TQVTGetCellSpansEvent = procedure(ASender: TQVirtualTreeView; ANode: TQVTNode;
    ACol: Integer; var ASpans: Integer) of object;
  TQVTPaintOption = (poHorizLine, poVertLine, poTreeLine, poColSelection,
    poRowSelection, poCellSelection, poNodeButton, poHover);
  TQVTPaintOptions = set of TQVTPaintOption;
  TQVTOption = (toTestHover, toRowSizable, toEditable, toAutoCascade,
    toClickToEdit, toClickToExpand);
  TQVTOptions = set of TQVTOption;
  TQVTState = (tsScrolling, tsDragging, tsRowSizing, tsColSizing,
    tsVisibleChanged, tsContentChanged);
  TQVTStates = set of TQVTState;
  TQVTHitTestResult = (hrNone, hrHeader, hrNode, hrColumnSpace, hrRowSpace);
  TQVTSortColumns = TList<TQVTColumn>;
  TGetCellBackgroundEvent = procedure(Sender: TQVirtualTreeView;
    ANode: TQVTNode; AColumn: Integer; AFill: TBrush; var AHandled: Boolean)
    of object;
  TGetNodeBackgroundEvent = procedure(Sender: TQVirtualTreeView;
    ANode: TQVTNode; AFill: TBrush; var AHandled: Boolean) of object;

  [ComponentPlatformsAttribute(AllCurrentPlatforms)]
  TQVirtualTreeView = class(TPresentedTextControl, IQVTDrawable)
  private
    class var DefaultDrawers: array [TQVTDrawerType] of IQVTDrawer;
  protected
    // Vars
    FRootNode: TQVTNode;
    FFirstVisibleNode: TQVTNode;
    FFocusNode: TQVTNode;
    FHoverNode: TQVTNode;
    FSizingNode: TQVTNode;
    FMouseDownNode: TQVTNode;
    FEditingNode: TQVTNode;
    FFirstVisibleColumn: Integer;
    FFill, FActiveFill: TBrush;
    FStroke: TStrokeBrush;
    FSelectionColor: TAlphaColor;
    FHoverColor: TAlphaColor;
    FLineStyle: TStrokeBrush;
    FHeader: TQVTHeader;
    FNodeIndent: Single;
    FFocusColumn: Integer;
    FNotifyMsgId: Integer;
    FHoverColumn: Integer;
    FTextLayout: TTextLayout;
    FNodeClass: TQVTNodeClass;
    FDirtyRowIndex: Integer;
    FLevelDirtyCounter: Integer;
    FDefaultRowHeight: Single;
    FPaintOptions: TQVTPaintOptions;
    FPaintOffset: TPointF;
    FHorzScrollBar: TScrollBar;
    FVertScrollBar: TScrollBar;
    FVisibleNodes: TList<TQVTNode>;
    FStates: TQVTStates;
    FSpace: TPointF;
    FOptions: TQVTOptions;
    FContentSize: TSizeF;

    FSizingNodeOriginHeight: Single;
    FSizingColumn: TQVTColumn;
    FSizingColumnOriginWidth: Single;
    FMouseDownPos: TPointF;
    FMouseDownTime: Cardinal;
    FMouseDownOffset: TPointF;
    FMouseDownPosition: TQVTHitTestResult;
    FMouseDownColumn: Integer;

    FEditingColumn: Integer;
    FTintColor: TAlphaColor;
    FInplaceEditor: IQVTInplaceEditor; // 当前编辑器
    FSortColumns: TQVTSortColumns;
    FMouseEditor: IQVTCellMouseEditCellData;
    FAniCalculations: TAniCalculations;
    // Events
    FOnHoverChanged: TNotifyEvent;
    FOnInitChildren: TQVTNodeNotifyEvent;
    FOnInitNode: TQVTNodeNotifyEvent;
    FOnFocusChanging: TQVTAcceptEvent;
    FOnFocusChanged: TQVTColumnNotifyEvent;
    FOnGetCellData: TQVTGetCellDataEvent;
    FOnGetCellDrawer: TQVTGetCellDrawerEvent;
    FOnCellClick: TQVTCellClickEvent;
    FOnCellDblClick: TQVTCellClickEvent;
    FOnCanEdit: TQVTAcceptEvent;
    FOnGetCellEditor: TQVTGetCellEditorEvent;
    FOnTitleClick: TQVTTitleNotifyEvent;
    FOnSortmarkerChanged: TNotifyEvent;
    FBeforeEdit: TQVTColumnNotifyEvent;
    FOnCancelEdit: TQVTColumnNotifyEvent;
    FAfterEdit: TQVTColumnNotifyEvent;
    FOnGetCellSpans: TQVTGetCellSpansEvent;
    FOnGetCellBackground: TGetCellBackgroundEvent;
    FOnGetNodeBackground: TGetNodeBackgroundEvent;
    function GetIsEditing: Boolean;
    procedure SetFill(const value: TBrush);
    procedure SetStroke(const value: TStrokeBrush);
    procedure SetFocusColumn(const value: Integer);
    procedure SetPaintOptions(const value: TQVTPaintOptions);
    procedure SetSpace(const value: TPointF);
    function GetRootNode: TQVTNode;
    function GetFill: TBrush;
    function GetStroke: TStrokeBrush;
    function GetDisplayRect(ANode: TQVTNode): TRectF;
    function GetCellRect(ANode: TQVTNode; AColumn: Integer): TRectF;
    procedure SetFocusNode(const value: TQVTNode);
    procedure Paint; override;
    procedure Resize; override;
    procedure AdjustAutoSizeColumn;
    procedure DoSortMarkerChanged(Sender: TObject);
    procedure CheckForBrowseMode(ASender: TObject);
    procedure RowDirty(ARowIndex: Integer);
    procedure InitNode(ANode: TQVTNode);
    procedure CalcVisibleNodes;
    function CreateNode: TQVTNode;
    function GetRootNodeCount: Integer;
    procedure SetHeader(const value: TQVTHeader);
    function GetColSpace: Single;
    function GetRowSpace: Single;
    procedure SetColSpace(const value: Single);
    procedure SetRowSpace(const value: Single);
    procedure SetRootNodeCount(const value: Integer);
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState;
      X, Y: Single); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState;
      X, Y: Single); override;
    procedure MouseClick(Button: TMouseButton; Shift: TShiftState;
      X, Y: Single); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Single); override;
    procedure MouseWheel(Shift: TShiftState; WheelDelta: Integer;
      var Handled: Boolean); override;
    procedure DoMouseEnter; override;
    procedure DoMouseLeave; override;
    procedure DialogKey(var Key: Word; Shift: TShiftState); override;
    procedure KeyDown(var Key: Word; var KeyChar: System.WideChar;
      Shift: TShiftState); override;
    function CreateScrollBar(AOrientation: TOrientation): TScrollBar;
    procedure DoScrollChanged(ASender: TObject);
    function CalcScrollRange: TSizeF;
    procedure NodeVisibleChanged;
    procedure NodeContentChanged;
    procedure CheckScrollBars;
    function FocusChanging(ANewNode: TQVTNode; ANewCol: Integer): Boolean;
    procedure FocusChanged;
    function DoHitTest(const APos: TPointF; var ANode: TQVTNode;
      var AColumn: Integer): TQVTHitTestResult;
    procedure CellClick(ANode: TQVTNode; ACol: Integer; const APos: TPointF);
    function CreateEditor(ANode: TQVTNode; ACol: Integer): IQVTInplaceEditor;
    function GetSortColumns: TQVTSortColumns;
    procedure DoSortColumnsChanged(Sender: TObject; const Item: TQVTColumn;
      Action: TCollectionNotification);
    procedure AniChange(Sender: TObject);
    procedure Notification(AComponent: TComponent;
      Operation: TOperation); override;
    procedure GetChildren(Proc: TGetChildProc; Root: TComponent); override;
    procedure DoCellDataRemove(const Sender: TObject; const M: TMessage);
    function GetTextSettingsClass
      : TTextSettingsInfo.TCustomTextSettingsClass; override;
    function GetNodeFill(ANode: TQVTNode; ABrush: TBrush): Boolean;
    function GetCellFill(ANode: TQVTNode; AColumn: Integer;
      ABrush: TBrush): Boolean;
    function ActiveFill: TBrush;
  published
    property LineStyle: TStrokeBrush read FLineStyle;
    property Fill: TBrush read FFill write SetFill;
    property Stroke: TStrokeBrush read FStroke write SetStroke;
    property SelectionColor: TAlphaColor read FSelectionColor
      write FSelectionColor;
    property HoverColor: TAlphaColor read FHoverColor write FHoverColor;
    property TintColor: TAlphaColor read FTintColor write FTintColor;
    property NodeIndent: Single read FNodeIndent write FNodeIndent;
    property Header: TQVTHeader read FHeader write SetHeader;
    property DefaultRowHeight: Single read FDefaultRowHeight
      write FDefaultRowHeight;
    property Options: TQVTOptions read FOptions write FOptions;
    property PaintOptions: TQVTPaintOptions read FPaintOptions
      write SetPaintOptions;
    property RootNodeCount: Integer read GetRootNodeCount
      write SetRootNodeCount;
    property ColSpace: Single read GetColSpace write SetColSpace nodefault;
    property RowSpace: Single read GetRowSpace write SetRowSpace nodefault;
    property AniCalculations: TAniCalculations read FAniCalculations;
    // Events
    property OnGetCellData: TQVTGetCellDataEvent read FOnGetCellData
      write FOnGetCellData;
    property OnGetCellDrawer: TQVTGetCellDrawerEvent read FOnGetCellDrawer
      write FOnGetCellDrawer;
    property OnHoverChanged: TNotifyEvent read FOnHoverChanged
      write FOnHoverChanged;
    property OnInitNode: TQVTNodeNotifyEvent read FOnInitNode write FOnInitNode;
    property OnInitChildren: TQVTNodeNotifyEvent read FOnInitChildren
      write FOnInitChildren;
    property OnFocusChanged: TQVTColumnNotifyEvent read FOnFocusChanged
      write FOnFocusChanged;
    property OnFocusChanging: TQVTAcceptEvent read FOnFocusChanging
      write FOnFocusChanging;
    property OnCellClick: TQVTCellClickEvent read FOnCellClick
      write FOnCellClick;
    property OnCellDblClick: TQVTCellClickEvent read FOnCellDblClick
      write FOnCellDblClick;
    property OnCanEdit: TQVTAcceptEvent read FOnCanEdit write FOnCanEdit;
    property BeforeEdit: TQVTColumnNotifyEvent read FBeforeEdit
      write FBeforeEdit;
    property AfterEdit: TQVTColumnNotifyEvent read FAfterEdit write FAfterEdit;
    property OnCancelEdit: TQVTColumnNotifyEvent read FOnCancelEdit
      write FOnCancelEdit;
    property OnGetCellEditor: TQVTGetCellEditorEvent read FOnGetCellEditor
      write FOnGetCellEditor;
    property OnTitleClick: TQVTTitleNotifyEvent read FOnTitleClick
      write FOnTitleClick;
    property OnSortmarkerChanged: TNotifyEvent read FOnSortmarkerChanged
      write FOnSortmarkerChanged;
    property OnGetCellSpans: TQVTGetCellSpansEvent read FOnGetCellSpans
      write FOnGetCellSpans;
    property OnGetCellBackground: TGetCellBackgroundEvent
      read FOnGetCellBackground write FOnGetCellBackground;
    property OnGetNodeBackground: TGetNodeBackgroundEvent
      read FOnGetNodeBackground write FOnGetNodeBackground;
    // inherited event

    property Action;
    property Align;
    property Anchors;
    property ClipChildren default false;
    property ClipParent default false;
    property Cursor default crDefault;
    property DragMode default TDragMode.dmManual;
    property EnableDragHighlight default True;
    property Enabled;
    property Locked default false;
    property Height;
    property HelpContext;
    property HelpKeyword;
    property HelpType;
    property Hint;
    property HitTest default false;
    property Padding;
    property Opacity;
    property Margins;
    property PopupMenu;
    property Position;
    property RotationAngle;
    property RotationCenter;
    property Scale;
    property Size;
    property StyleLookup;
    property TextSettings;
    property TouchTargetExpansion;
    property Visible;
    property Width;
    property ParentShowHint;
    property ShowHint;
    property TabOrder;
    property TabStop;
    { events }
    property OnApplyStyleLookup;
    { Drag and Drop events }
    property OnDragEnter;
    property OnDragLeave;
    property OnDragOver;
    property OnDragDrop;
    property OnDragEnd;
    { Keyboard events }
    property OnKeyDown;
    property OnKeyUp;
    { Mouse events }
    property OnCanFocus;
    property OnClick;
    property OnDblClick;

    property OnEnter;
    property OnExit;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnMouseWheel;
    property OnMouseEnter;
    property OnMouseLeave;

    property OnPainting;
    property OnPaint;
    property OnResize;
{$IF RTLVersioN>=32}
    property OnResized;
{$ENDIF}
  public
    class constructor Create;
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function GetCellData(ANode: TQVTNode; AColIndex: Integer): IQVTCellData;
    function GetCellDrawer(ANode: TQVTNode; AColIndex: Integer): IQVTDrawer;
    function GetChildCount(ANode: TQVTNode): Integer;
    procedure Invalidate;
    procedure InvalidateColumn(const AColumn: Integer);
    procedure InvalidateNode(const ANode: TQVTNode);
    function GetNext(ANode: TQVTNode): TQVTNode;
    function GetNextVisible(ANode: TQVTNode;
      AutoExpandChildren: Boolean = false): TQVTNode;
    function GetPriorVisible(ANode: TQVTNode): TQVTNode;
    function GetNodeAt(const APos: TPointF; AColumn: PInteger = nil): TQVTNode;
    procedure MakeNodeVisible(ANode: TQVTNode; ACenterInView: Boolean = false);
    procedure ScrollBy(dx, dy: Single);
    function CanEdit(ANode: TQVTNode; ACol: Integer): Boolean;
    function BeginEdit(ANode: TQVTNode; ACol: Integer): Boolean;
    function EndEdit: Boolean;
    procedure CancelEdit;
    class function GetDefaultDrawer(AType: TQVTDrawerType): IQVTDrawer;
    property VertScrollBar: TScrollBar read FVertScrollBar;
    property HorzScrollBar: TScrollBar read FHorzScrollBar;
    property FocusNode: TQVTNode read FFocusNode write SetFocusNode;
    property FocusColumn: Integer read FFocusColumn write SetFocusColumn;
    property FirstVisibleNode: TQVTNode read FFirstVisibleNode;
    property MouseDownNode: TQVTNode read FMouseDownNode;
    property MouseDownColumn: Integer read FMouseDownColumn;
    property DisplayRect[ANode: TQVTNode]: TRectF read GetDisplayRect;
    property CellRect[ANode: TQVTNode; AColumn: Integer]: TRectF
      read GetCellRect;
    property RootNode: TQVTNode read GetRootNode;
    property HoverNode: TQVTNode read FHoverNode;
    property HoverColumn: Integer read FHoverColumn;
    property SortColumns: TQVTSortColumns read GetSortColumns;
    property MouseDownPosition: TQVTHitTestResult read FMouseDownPosition;
    property Space: TPointF read FSpace write SetSpace;
    property IsEditing: Boolean read GetIsEditing;
  end;

implementation

resourcestring
  SCantEndEdit = 'Can''t end editing for browse mode.';
  SCantAddRootNodeSibling = 'Can''t add as root node sibling.';
  SCantAddToChild = 'Can''t set a node parent to it''s child.';
  SCantAddToSelf = 'Can''t set a node parent to self.';

type
  TCellTextSettings = class(TTextSettingsInfo.TCustomTextSettings)
  published
    property Font;
    property FontColor;
    property HorzAlign;
    property VertAlign;
    property WordWrap;
    property Trimming;
  end;

  { TQVTDrawableObject }

procedure TQVTDrawableObject.AfterConstruction;
begin
  inherited;
  AtomicDecrement(FRefCount);
end;

procedure TQVTDrawableObject.Assign(src: TPersistent);
var
  ASource: TQVTDrawableObject;
begin
  ASource := src as TQVTDrawableObject;
  SetFill(ASource.FFill);
  SetStroke(ASource.FStroke);
end;

procedure TQVTDrawableObject.BeforeDestruction;
begin
{$IFNDEF AUTOREFCOUNT}
  if ((FRefCount and $80000000) = 0) and (RefCount = 0) then
    Error(reInvalidPtr);
{$ENDIF}
end;

constructor TQVTDrawableObject.Create;
begin
  inherited;
end;

destructor TQVTDrawableObject.Destroy;
begin
  if Assigned(FFill) then
    FreeAndNil(FFill);
  if Assigned(FStroke) then
    FreeAndNil(FStroke);
  inherited;
end;

function TQVTDrawableObject.GetFill: TBrush;
begin
  Result := FFill;
end;
{$IFNDEF AUTOREFCOUNT}

function TQVTDrawableObject.GetRefCount: Integer;
begin
  Result := FRefCount and $7FFFFFFF;
end;
{$ENDIF}

function TQVTDrawableObject.GetStroke: TStrokeBrush;
begin
  Result := FStroke;
end;

class function TQVTDrawableObject.NewInstance: TObject;
begin
  Result := inherited NewInstance;
  TQVTDrawableObject(Result).FRefCount := 1;
end;

function TQVTDrawableObject.QueryInterface(const IID: TGUID; out Obj): HResult;
begin
  if GetInterface(IID, Obj) then
    Result := 0
  else
    Result := E_NOINTERFACE;
end;

procedure TQVTDrawableObject.SetFill(AFill: TBrush);
begin
  if AFill <> nil then
  begin
    if not Assigned(FFill) then
      FFill := TBrush.Create(TBrushKind.Solid, TAlphaColors.White);
    FFill.Assign(AFill);
  end
  else if Assigned(FFill) then
    FreeAndNil(FFill);
end;

procedure TQVTDrawableObject.SetStroke(AStroke: TStrokeBrush);
begin
  if Assigned(AStroke) then
  begin
    if not Assigned(AStroke) then
      FStroke := TStrokeBrush.Create(TBrushKind.Solid, TAlphaColors.Black);
    FStroke.Assign(AStroke);
  end
  else if Assigned(FStroke) then
    FreeAndNil(FStroke);
end;

function TQVTDrawableObject._AddRef: Integer;
begin
{$IFNDEF AUTOREFCOUNT}
  Result := AtomicIncrement(FRefCount);
{$ELSE}
  Result := __ObjAddRef;
{$ENDIF}
end;

function TQVTDrawableObject._Release: Integer;
{$IFNDEF AUTOREFCOUNT}
var
  LRefCount: Integer;
{$ENDIF}
const
  objDestroyingFlag = Integer($80000000);
begin
{$IFNDEF AUTOREFCOUNT}
  Result := AtomicDecrement(FRefCount);
  if Result = 0 then
  begin
    repeat
      LRefCount := FRefCount;
    until AtomicCmpExchange(FRefCount, LRefCount or objDestroyingFlag,
      LRefCount) = LRefCount;
    // Mark the refcount field so that any refcounting during destruction doesn't infinitely recurse.
    Destroy;
  end;
{$ELSE}
  Result := __ObjRelease;
{$ENDIF}
end;

{ TQVTTextDrawableObject }

procedure TQVTTextDrawableObject.Assign(src: TPersistent);
begin
  inherited;
  if src is TQVTTextDrawableObject then
    SetTextSettings(TQVTTextDrawableObject(src).TextSettings);
end;

constructor TQVTTextDrawableObject.Create;
begin
  inherited;
end;

destructor TQVTTextDrawableObject.Destroy;
begin
  if Assigned(FTextSettings) then
    FreeAndNil(FTextSettings);
  inherited;
end;

function TQVTTextDrawableObject.GetTextSettings: TTextSettings;
begin
  Result := FTextSettings;
end;

procedure TQVTTextDrawableObject.SetTextSettings(value: TTextSettings);
begin
  if not Assigned(FTextSettings) then
    FTextSettings := TTextSettingsClass(value.ClassType).Create(nil);
  FTextSettings.Assign(value);
end;

{ TQVTHeader }

procedure TQVTHeader.Assign(src: TPersistent);
begin
  inherited;
  if src is TQVTHeader then
  begin
    FColumns.Assign(TQVTHeader(src).FColumns);
    FOptions := TQVTHeader(src).Options;
    FMasterColumn := TQVTHeader(src).FMasterColumn;
    FAutoSizeColumn := TQVTHeader(src).FAutoSizeColumn;
    FHeight := TQVTHeader(src).FHeight;
    FMinHeight := TQVTHeader(src).FMinHeight;
    FMaxHeight := TQVTHeader(src).FMaxHeight;
  end;
end;

constructor TQVTHeader.Create(AOwner: TQVirtualTreeView);
begin
  inherited Create;
  FTreeView := AOwner;
  FColumns := TQVTColumns.Create(Self);
  FOptions := [hoResizable];
  FMasterColumn := 0;
  FAutoSizeColumn := -1;
  FHeight := 20;
end;

destructor TQVTHeader.Destroy;
begin
  FreeAndNil(FColumns);
  inherited;
end;

function TQVTHeader.GetOwner: TPersistent;
begin
  Result := FTreeView;
end;

function TQVTHeader.GetWidth: Single;

var
  I: Integer;
  ACol: TQVTColumn;
begin
  Result := 0;
  for I := 0 to Columns.Count - 1 do
  begin
    ACol := Columns[I];
    if ACol.Visible then
      Result := Result + ACol.Width + TreeView.Space.X;
  end;
  // 减去多加的那一次
  Result := Result - TreeView.Space.X;
end;

procedure TQVTHeader.SetAutoSizeColumn(const value: Integer);
begin
  if FAutoSizeColumn <> value then
  begin
    FAutoSizeColumn := value;
    FTreeView.Resize;
  end;
end;

procedure TQVTHeader.SetColumns(const value: TQVTColumns);
begin
  FColumns.Assign(value);
end;

procedure TQVTHeader.SetHeight(const value: Single);
begin
  if not SameValue(FHeight, value) then
  begin
    if (value > MinHeight) then
    begin
      if IsZero(MaxHeight) or (value <= MaxHeight) then
      begin
        FHeight := value;
        TreeView.NodeVisibleChanged;
      end;
    end;
  end;
end;

procedure TQVTHeader.SetMasterColumn(const value: Integer);
begin
  FMasterColumn := value;
  FTreeView.InvalidateColumn(value);
end;

procedure TQVTHeader.SetMaxHeight(const value: Single);
begin
  if not SameValue(FMaxHeight, value) then
  begin
    FMaxHeight := value;
    if (value > 0) and (Height > value) then
      Height := value;
  end;
end;

procedure TQVTHeader.SetMinHeight(const value: Single);
begin
  if not SameValue(FMinHeight, value) then
  begin
    FMinHeight := value;
    if (value > 0) and (Height < FMinHeight) then
      Height := value;
  end;
end;

procedure TQVTHeader.SetOptions(const value: TQVTHeaderOptions);
begin
  FOptions := value;
  TreeView.NodeContentChanged;
end;

{ TQVTColumnTitle }

procedure TQVTColumnTitle.Assign(src: TPersistent);
begin
  inherited;
  if src is TQVTColumnTitle then
  begin
    FText := TQVTColumnTitle(src).Text;
    FDrawerType := TQVTColumnTitle(src).DrawerType;
    FClickable := TQVTColumnTitle(src).Clickable;
    FSortMarker := TQVTColumnTitle(src).SortMarker;
    FSortOnClick := TQVTColumnTitle(src).SortOnClick;
    FDrawer := TQVTColumnTitle(src).FDrawer;
    FTextSettingsInfo.Assign(TQVTColumnTitle(src).FTextSettingsInfo);
  end;
end;

constructor TQVTColumnTitle.Create(AColumn: TQVTColumn);
begin
  inherited Create;
  FColumn := AColumn;
  FFill := TBrush.Create(TBrushKind.Solid, TAlphaColors.Whitesmoke);
  FStroke := TStrokeBrush.Create(TBrushKind.None, TAlphaColors.LtGray);
  FDrawerType := TQVTDrawerType.dtHeader;
  FSortMarker := TQVTColumnSortMarker.smNone;
  FSortOnClick := false;
  FClickable := false;
  FTextSettingsInfo := TTextSettingsInfo.Create(AColumn,
    AColumn.TreeView.GetTextSettingsClass);
  TextSettings.HorzAlign := TTextAlign.Center;
end;

destructor TQVTColumnTitle.Destroy;
begin
  inherited;
end;

function TQVTColumnTitle.GetColIndex: Integer;
begin
  Result := FColumn.Index;
end;

function TQVTColumnTitle.GetColumn: Integer;
begin
  Result := FColumn.Index;
end;

function TQVTColumnTitle.GetColumnId: Integer;
begin
  Result := FColumn.ID;
end;

function TQVTColumnTitle.GetDrawer: IQVTDrawer;
begin
  Result := FColumn.TreeView.GetCellDrawer(nil, FColumn.Index);
end;

function TQVTColumnTitle.GetEnabled: Boolean;
begin
  Result := FColumn.Enabled;
end;

function TQVTColumnTitle.GetNode: TQVTNode;
begin
  // 标题与结点无关，所以返回nil
  Result := nil;
end;

function TQVTColumnTitle.GetSides: TSides;
begin
  Result := [TSide.Top, TSide.Left, TSide.Right, TSide.Bottom];
end;

function TQVTColumnTitle.GetText: String;
begin
  Result := FText;
end;

function TQVTColumnTitle.GetTextSettings: TTextSettings;
begin
  Result := FTextSettingsInfo.TextSettings;
end;

function TQVTColumnTitle.GetTreeView: TQVirtualTreeView;
begin
  Result := FColumn.TreeView;
end;

procedure TQVTColumnTitle.SetColumn(const AColumn: Integer);
begin
  // 列标题是与列相关的，所以忽略修改
end;

procedure TQVTColumnTitle.SetDrawerType(const value: TQVTDrawerType);
begin
  if FDrawerType <> value then
  begin
    FDrawerType := value;
    FDrawer := nil;
  end;
end;

procedure TQVTColumnTitle.SetEnabled(value: Boolean);
begin
  FColumn.Enabled := value;
end;

procedure TQVTColumnTitle.SetNode(ANode: TQVTNode);
begin
  // 列标题的Node始终为空，所以忽略修改
end;

procedure TQVTColumnTitle.SetSortMarker(const value: TQVTColumnSortMarker);
begin
  if FSortMarker <> value then
  begin
    FSortMarker := value;
    FColumn.TreeView.DoSortMarkerChanged(FColumn);
  end;
end;

procedure TQVTColumnTitle.SetText(const value: String);
begin
  if FText <> value then
  begin
    FText := value;
    if hoVisible in FColumn.TreeView.Header.Options then
      FColumn.TreeView.InvalidateColumn(FColumn.Index);
  end;
end;

procedure TQVTColumnTitle.SetTextSettings(value: TTextSettings);
begin
  FTextSettingsInfo.TextSettings.Assign(value);
end;

{ TQVirtualTreeView }

function TQVirtualTreeView.ActiveFill: TBrush;
begin
  if Assigned(FActiveFill) then
    Result := FActiveFill
  else
    Result := Fill;
end;

procedure TQVirtualTreeView.AdjustAutoSizeColumn;

var
  W: Single;
  I: Integer;
  ACol: TQVTColumn;
begin
  if (Header.AutoSizeColumn >= 0) and
    (Header.AutoSizeColumn < Header.Columns.Count) then
  begin
    W := 0;
    for I := 0 to Header.Columns.Count - 1 do
    begin
      ACol := Header.Columns[I];
      if (I <> Header.AutoSizeColumn) and ACol.Visible then
        W := W + ACol.Width + Space.X;
    end;
    if Header.Columns[Header.AutoSizeColumn].Visible then
    begin
      W := Width - Padding.Left - Padding.Right - W;
      if Assigned(FVertScrollBar) then
        W := W - FVertScrollBar.Width;
      Header.Columns[Header.AutoSizeColumn].Width := W;
    end;
  end;
end;

procedure TQVirtualTreeView.AniChange(Sender: TObject);
begin
  if Assigned(FHorzScrollBar) then
    FHorzScrollBar.value := FAniCalculations.ViewportPosition.X;
  if Assigned(FVertScrollBar) then
    FVertScrollBar.value := FAniCalculations.ViewportPosition.Y;
end;

function TQVirtualTreeView.BeginEdit(ANode: TQVTNode; ACol: Integer): Boolean;
var
  LR, R: TRectF;
  I, ASpans: Integer;
begin
  if Assigned(OnGetCellSpans) then
  begin
    I := 0;
    while I < ACol do
    begin
      ASpans := 0;
      OnGetCellSpans(Self, ANode, I, ASpans);
      if I + ASpans >= ACol then
      begin
        ACol := I;
        Break;
      end
      else
        Inc(I, ASpans + 1);
    end;
  end;
  if Assigned(FInplaceEditor) then
    Result := EndEdit and CanEdit(ANode, ACol)
  else
    Result := CanEdit(ANode, ACol);
  if Result then
  begin
    if Assigned(FBeforeEdit) then
      FBeforeEdit(Self, ANode, ACol);
    FInplaceEditor := CreateEditor(ANode, ACol);
    if Assigned(FInplaceEditor) then
    begin
      Result := FInplaceEditor.BeginEdit(ANode, ACol);
      if Result then
      begin
        R := ANode.CellRect[ACol];
        LR := LocalRect;
        LR.Left := LR.Left + Padding.Left;
        LR.Right := LR.Right - Padding.Right;
        if Assigned(FVertScrollBar) then
          LR.Right := LR.Right - FVertScrollBar.Width;
        if R.Left < LR.Left then
          R.Left := LR.Left;
        if R.Right > LR.Right then
          R.Right := LR.Right;
        FInplaceEditor.SetBounds(R);
        FInplaceEditor.Show;
        FEditingNode := ANode;
        FEditingColumn := ACol;
      end
      else
        FInplaceEditor := nil;
    end
    else
      Result := false;
  end;
end;

function TQVirtualTreeView.CalcScrollRange: TSizeF;

var
  ANode: TQVTNode;
  ACol: TQVTColumn;
  I: Integer;
begin
  ANode := RootNode.GetFirstVisibleChild;
  Result.cx := 0;
  Result.cy := 0;
  I := 0;
  while Assigned(ANode) do
  begin
    ANode.NeedInitialized;
    ANode.FRowIndex := I;
    ANode.FDistance := Result.cy;
    Inc(I);
    Result.cy := Result.cy + ANode.Height + FSpace.Y;
    ANode := GetNextVisible(ANode);
  end;
  for I := 0 to Header.Columns.Count - 1 do
  begin
    ACol := Header.Columns[I];
    if ACol.Visible then
      Result.cx := Result.cx + ACol.Width + FSpace.X;
  end;
  if Result.cy > 0 then
    Result.cy := Result.cy - FSpace.Y;
  if Result.cx > 0 then
    Result.cx := Result.cx - FSpace.X;
end;

procedure TQVirtualTreeView.CalcVisibleNodes;

var
  W: Single;
  ANode: TQVTNode;
  R, AClientRect: TRectF;
begin
  W := Header.Width;
  if TQVTState.tsVisibleChanged in FStates then
  begin
    FVisibleNodes.Clear;
    AClientRect := RectF(Padding.Left, Padding.Top, Width - Padding.Right,
      Height - Padding.Top);
    if not Assigned(FFirstVisibleNode) then
      FFirstVisibleNode := RootNode.GetFirstVisibleChild;
    if Assigned(FFirstVisibleNode) then
    begin
      ANode := FFirstVisibleNode;
      R.Left := AClientRect.Left - FPaintOffset.X + Stroke.Thickness;
      R.Right := R.Left + W;
      R.Top := AClientRect.Top - FPaintOffset.Y;
      if TQVTHeaderOption.hoVisible in FHeader.Options then
        R.Top := R.Top + FHeader.Height + FSpace.Y
      else
        R.Top := R.Top + FSpace.X;
      if R.Right > AClientRect.Right then
        R.Right := AClientRect.Right;
      while Assigned(ANode) do
      begin
        ANode.NeedInitialized;
        ANode.FVisibleRowIndex := FVisibleNodes.Add(ANode);
        R.Bottom := R.Top + ANode.GetHeight;
        ANode.FDisplayRect := R;
        R.Top := R.Bottom + FSpace.Y;
        if R.Top > AClientRect.Bottom then
          Break;
        ANode := GetNextVisible(ANode);
      end;
    end;
    FStates := FStates - [TQVTState.tsVisibleChanged];
    CheckScrollBars;
  end;
end;

procedure TQVirtualTreeView.CancelEdit;
begin
  if Assigned(FInplaceEditor) then
  begin
    FInplaceEditor.CancelEdit;
    FInplaceEditor := nil;;
    FEditingNode := nil;
    FEditingColumn := 0;
  end;
end;

function TQVirtualTreeView.CanEdit(ANode: TQVTNode; ACol: Integer): Boolean;
var
  ACellData: IQVTCellData;
begin
  if (ACol < 0) or (ACol >= Header.Columns.Count) then
    Result := false
  else if TQVTOption.toEditable in Options then
  begin
    ACellData := ANode.CellData[ACol];
    if Assigned(ACellData) and ACellData.Enabled then
      Result := (not Header.Columns[ACol].ReadOnly)
    else
      Result := false;
    if Assigned(FOnCanEdit) then
      FOnCanEdit(Self, ANode, ACol, Result);
  end
  else
    Result := false;
end;

procedure TQVirtualTreeView.CellClick(ANode: TQVTNode; ACol: Integer;
  const APos: TPointF);
begin
  if Assigned(FOnCellClick) then
    FOnCellClick(Self, ANode, ACol, APos);
  if CanEdit(ANode, ACol) and (toClickToEdit in Options) then
    BeginEdit(ANode, ACol);
end;

procedure TQVirtualTreeView.CheckForBrowseMode(ASender: TObject);
begin
  if Assigned(FInplaceEditor) then
  begin
    if not EndEdit then
      raise Exception.Create(SCantEndEdit);
    FInplaceEditor := nil;
  end;
end;

procedure TQVirtualTreeView.CheckScrollBars;

var
  R: TRectF;
  pt: TPointD;
  Targets: array of TAniCalculations.TTarget;
begin
  if TQVTState.tsVisibleChanged in FStates then
    CalcVisibleNodes;
  if TQVTState.tsContentChanged in FStates then
  begin
    FContentSize := CalcScrollRange;
    FStates := FStates - [TQVTState.tsContentChanged];
    R := LocalRect;
    R.Left := R.Left + Padding.Left;
    R.Top := R.Top + Padding.Top;
    if TQVTHeaderOption.hoVisible in FHeader.Options then
      R.Top := R.Top + Header.Height;
    R.Right := R.Right - Padding.Right;
    R.Bottom := R.Bottom - Padding.Bottom;
    // 计算是否需要垂直滚动条
    if FContentSize.cy > R.Height then
    begin
      if not Assigned(FVertScrollBar) then
        FVertScrollBar := CreateScrollBar(TOrientation.Vertical);
      FVertScrollBar.Max := FContentSize.cy;
      if Assigned(FHorzScrollBar) then
        R.Bottom := R.Bottom - FHorzScrollBar.Height;
      if hoVisible in Header.Options then
        FVertScrollBar.ViewportSize := R.Height - FHeader.Height
      else
        FVertScrollBar.ViewportSize := R.Height;
    end
    else
      FreeAndNil(FVertScrollBar);
    if FContentSize.cx > R.Width then
    begin
      if not Assigned(FHorzScrollBar) then
        FHorzScrollBar := CreateScrollBar(TOrientation.Horizontal);
      FHorzScrollBar.Max := FContentSize.cx;
      if Assigned(FVertScrollBar) then
        R.Right := R.Right - FVertScrollBar.Width;
      FHorzScrollBar.ViewportSize := R.Width;
    end
    else
      FreeAndNil(FHorzScrollBar);
    SetLength(Targets, 2);

    Targets[0].TargetType := TAniCalculations.TTargetType.Min;
    Targets[0].Point := TPointD.Create(0, 0);
    Targets[1].TargetType := TAniCalculations.TTargetType.Max;
    if Assigned(FHorzScrollBar) then
      pt.X := FHorzScrollBar.Max - FHorzScrollBar.ViewportSize
    else
      pt.X := 0;
    if Assigned(FVertScrollBar) then
      pt.Y := FVertScrollBar.Max - FVertScrollBar.ViewportSize
    else
      pt.Y := 0;
    Targets[1].Point := pt;
    FAniCalculations.SetTargets(Targets);
  end;
end;

constructor TQVirtualTreeView.Create(AOwner: TComponent);
begin
  inherited;
  // AutoCapture := True;
  FFill := TBrush.Create(TBrushKind.Solid, TAlphaColors.White);
  FStroke := TStrokeBrush.Create(TBrushKind.Solid, TAlphaColors.LtGray);
  FLineStyle := TStrokeBrush.Create(TBrushKind.Solid, TAlphaColors.Black);
  FLineStyle.Dash := TStrokeDash.Dot;
  FHeader := TQVTHeader.Create(Self);
  FNodeClass := TQVTNode;
  FDefaultRowHeight := 20;
  FNodeIndent := 16;
  FSpace.X := 1;
  FSpace.Y := 1;
  CanFocus := True;
  FVisibleNodes := TList<TQVTNode>.Create;
  FStates := [tsVisibleChanged];
  FPaintOptions := [TQVTPaintOption.poNodeButton, TQVTPaintOption.poTreeLine,
    TQVTPaintOption.poRowSelection];
  FSelectionColor := TAlphaColors.Lightblue;
  FHoverColor := TAlphaColors.Lightpink;
  FHoverColumn := -1;
  FFocusColumn := -1;
  FMouseDownColumn := -1;
  FOptions := [toClickToEdit];
  FTintColor := TAlphaColors.Black;
  FAniCalculations := TAniCalculations.Create(Self);
  FAniCalculations.TouchTracking := [ttVertical, ttHorizontal];
  FAniCalculations.Animation := True;
  FAniCalculations.BoundsAnimation := True;
  FAniCalculations.DecelerationRate := DecelerationRateNormal;
  FAniCalculations.OnChanged := AniChange;
  TextSettings.WordWrap := false;
  TextSettings.VertAlign := TTextAlign.Center;
  Width := 180;
  Height := 300;
  FNotifyMsgId := TMessageManager.DefaultManager.SubscribeToMessage
    (TQVTCellNotifyMessage, DoCellDataRemove);
end;

function TQVirtualTreeView.CreateEditor(ANode: TQVTNode; ACol: Integer)
  : IQVTInplaceEditor;
begin
  Result := Header.Columns[ACol].Editor;
  if Assigned(FOnGetCellEditor) then
    FOnGetCellEditor(Self, ANode, ACol, Result);
end;

class constructor TQVirtualTreeView.Create;
begin
  DefaultDrawers[TQVTDrawerType.dtText] := TQVTTextDrawer.Create(nil);
  DefaultDrawers[TQVTDrawerType.dtCheck] := TQVTCheckDrawer.Create(nil);
  DefaultDrawers[TQVTDrawerType.dtRadio] := TQVTRadioDrawer.Create(nil);
  DefaultDrawers[TQVTDrawerType.dtImage] := TQVTImageDrawer.Create(nil);
  DefaultDrawers[TQVTDrawerType.dtStateText] := TQVTStateDrawer.Create(nil);
  DefaultDrawers[TQVTDrawerType.dtTree] := TQVTMasterDrawer.Create(nil);
  DefaultDrawers[TQVTDrawerType.dtProgress] := TQVTProgressDrawer.Create(nil);
  DefaultDrawers[TQVTDrawerType.dtMoney] := TQVTMoneyDrawer.Create(nil);
  DefaultDrawers[TQVTDrawerType.dtRowIndicator] :=
    TQVTIndicatorDrawer.Create(nil);
  DefaultDrawers[TQVTDrawerType.dtHeader] := TQVTHeaderDrawer.Create(nil);
  DefaultDrawers[TQVTDrawerType.dtCustom] := DefaultDrawers[dtText];
  DefaultDrawers[TQVTDrawerType.dtDefault] := DefaultDrawers[dtText];
end;

function TQVirtualTreeView.CreateNode: TQVTNode;
begin
  Result := FNodeClass.Create(Self);
end;

function TQVirtualTreeView.CreateScrollBar(AOrientation: TOrientation)
  : TScrollBar;
begin
  Result := TSmallScrollBar.Create(Self);
  Result.Parent := Self;
  Result.Orientation := AOrientation;
  Result.SetSubComponent(True);
  Result.FreeNotification(Self);
  case AOrientation of
    TOrientation.Horizontal: // 水平
      begin
        Result.Name := 'HorzBar';
        Result.Align := TAlignLayout.Bottom;
        Result.Height := 8;
        Result.Margins.Left := Stroke.Thickness;
        Result.Margins.Right := Result.Margins.Left;
      end;
    TOrientation.Vertical:
      begin
        Result.Name := 'VertBar';
        Result.Align := TAlignLayout.Right;
        Result.Margins.Top := Stroke.Thickness;
        Result.Margins.Bottom := Result.Margins.Top;
        Result.Width := 8;
      end;
  end;
  Result.OnChange := DoScrollChanged;
  Result.Visible := True;
end;

destructor TQVirtualTreeView.Destroy;
begin
  if Assigned(FAniCalculations) then
    FreeAndNil(FAniCalculations);
  if Assigned(FInplaceEditor) then
  begin
    FInplaceEditor.CancelEdit;
    FInplaceEditor := nil;
  end;
  FreeAndNil(FFill);
  FreeAndNil(FStroke);
  FreeAndNil(FLineStyle);
  FreeAndNil(FHeader);
  if Assigned(FTextLayout) then
    FreeAndNil(FTextLayout);
  if Assigned(FSortColumns) then
  begin
    FSortColumns.OnNotify := nil;
    FSortColumns.Clear;
    FreeAndNil(FSortColumns);
  end;
  FreeAndNil(FVisibleNodes);
  if Assigned(FRootNode) then
  begin
    FRootNode._Release;
    FRootNode := nil;
  end;
  TMessageManager.DefaultManager.Unsubscribe(TQVTCellNotifyMessage,
    FNotifyMsgId);
  inherited;
end;

procedure TQVirtualTreeView.DialogKey(var Key: Word; Shift: TShiftState);
begin
  if Assigned(FInplaceEditor) then
    FInplaceEditor.DialogKey(Key, Shift)
  else if Key = vkF2 then
  begin
    if CanEdit(FocusNode, FocusColumn) then
      BeginEdit(FocusNode, FocusColumn);
    Key := 0;
  end;
  inherited;
end;

procedure TQVirtualTreeView.DoScrollChanged(ASender: TObject);
  procedure CheckFirstVisibleNode;

  var
    ANode: TQVTNode;
    V: Single;
  begin
    if not Assigned(FFirstVisibleNode) then
      FFirstVisibleNode := RootNode.GetFirstVisibleChild;
    ANode := FFirstVisibleNode;
    if Assigned(FVertScrollBar) then
      V := FVertScrollBar.value
    else
      V := 0;
    while Assigned(ANode) and (ANode.FDistance + ANode.Height < V) do
    begin
      FFirstVisibleNode := ANode;
      ANode := GetNextVisible(ANode);
    end;
    while Assigned(ANode) do
    begin
      FFirstVisibleNode := ANode;
      if ANode.FDistance < V then
        Break;
      ANode := GetPriorVisible(ANode);
    end;
    if Assigned(FFirstVisibleNode) then
      FPaintOffset.Y := V - FFirstVisibleNode.FDistance
    else
      FPaintOffset.Y := 0;
  end;

  procedure CheckColumnVisible;

  var
    I: Integer;
    L, V: Single;
  begin
    L := 0;
    if Assigned(FHorzScrollBar) then
      V := FHorzScrollBar.value
    else
      V := 0;
    FFirstVisibleColumn := -1;
    for I := 0 to FHeader.Columns.Count - 1 do
    begin
      L := L + FHeader.Columns[I].Width + FSpace.X;
      if L > V then
      begin
        FFirstVisibleColumn := I;
        Break;
      end;
    end;
    if FFirstVisibleColumn <> -1 then
      FPaintOffset.X := V;
  end;

var
  pt: TPointF;
begin
  if ASender = FVertScrollBar then
    CheckFirstVisibleNode
  else
    CheckColumnVisible;
  if Assigned(FHorzScrollBar) then
    pt.X := FHorzScrollBar.value
  else
    pt.X := 0;
  if Assigned(FVertScrollBar) then
    pt.Y := FVertScrollBar.value
  else
    pt.Y := 0;
  FAniCalculations.ViewportPositionF := pt;
  NodeVisibleChanged;
end;

procedure TQVirtualTreeView.DoSortColumnsChanged(Sender: TObject;
  const Item: TQVTColumn; Action: TCollectionNotification);

var
  I: Integer;
begin
  for I := 0 to FSortColumns.Count - 1 do
    FSortColumns[I].FSortIndex := I;
  DoSortMarkerChanged(Self);
end;

procedure TQVirtualTreeView.DoSortMarkerChanged(Sender: TObject);
begin
  if Assigned(FOnSortmarkerChanged) then
    FOnSortmarkerChanged(Self);
  Invalidate;
end;

function TQVirtualTreeView.EndEdit: Boolean;
begin
  if Assigned(FInplaceEditor) then
    Result := FInplaceEditor.EndEdit
  else if Assigned(FMouseEditor) then
  begin
    Result := True;
    FMouseEditor := nil;
  end
  else
    Exit(True);
  if Result then
  begin
    if Assigned(FAfterEdit) then
      FAfterEdit(Self, FEditingNode, FEditingColumn);
    InvalidateNode(FEditingNode);
    FInplaceEditor := nil;
    FEditingNode := nil;
    FEditingColumn := 0;
  end;
end;

procedure TQVirtualTreeView.FocusChanged;
begin
  if Assigned(FOnFocusChanged) then
    FOnFocusChanged(Self, FocusNode, FocusColumn);
  Invalidate;
end;

function TQVirtualTreeView.FocusChanging(ANewNode: TQVTNode;
  ANewCol: Integer): Boolean;
begin
  Result := True;
  CheckForBrowseMode(Self);
  if Assigned(FOnFocusChanging) then
    FOnFocusChanging(Self, ANewNode, ANewCol, Result);
end;

function TQVirtualTreeView.GetCellData(ANode: TQVTNode; AColIndex: Integer)
  : IQVTCellData;
begin
  Result := FHeader.Columns[AColIndex].CellData;
  if Assigned(OnGetCellData) then
    OnGetCellData(Self, ANode, AColIndex, Result);
  if Assigned(Result) then
  begin
    Result.Node := ANode;
    Result.Column := AColIndex;
  end;
  if not Assigned(Result) then
    Result := TQVTDefaultCellData.Create(ANode, AColIndex);
end;

function TQVirtualTreeView.GetCellDrawer(ANode: TQVTNode; AColIndex: Integer)
  : IQVTDrawer;

var
  AType: TQVTDrawerType;
begin
  Result := nil;
  if Assigned(OnGetCellDrawer) then
    OnGetCellDrawer(Self, ANode, AColIndex, Result);
  if not Assigned(Result) then
  begin
    if (AColIndex >= 0) and (AColIndex < Header.Columns.Count) then
    begin
      if Assigned(ANode) then
      begin
        Result := Header.Columns[AColIndex].Drawer;
        if Assigned(Result) then
          Exit;
        AType := Header.Columns[AColIndex].DrawerType;
      end
      else
        AType := Header.Columns[AColIndex].Title.DrawerType;
      if (AColIndex = Header.MasterColumn) and (AType = TQVTDrawerType.dtDefault)
      then
        Result := GetDefaultDrawer(TQVTDrawerType.dtTree)
      else
        Result := GetDefaultDrawer(AType);
    end
    else
      Result := GetDefaultDrawer(TQVTDrawerType.dtDefault);
  end;
end;

function TQVirtualTreeView.GetCellFill(ANode: TQVTNode; AColumn: Integer;
  ABrush: TBrush): Boolean;
begin
  Result := false;
  if (nsHover in ANode.States) and (poHover in PaintOptions) then
  begin
    ABrush.Color := HoverColor;
    ABrush.Kind := TBrushKind.Solid;
    Result := (ABrush.Color <> Fill.Color) or (ABrush.Kind <> Fill.Kind);
  end
  else if (nsSelected in ANode.States) and (poCellSelection in PaintOptions)
  then
  begin
    ABrush.Color := SelectionColor;
    ABrush.Kind := TBrushKind.Solid;
    Result := (ABrush.Color <> Fill.Color) or (ABrush.Kind <> Fill.Kind);
  end;
  if Assigned(OnGetCellBackground) then
  begin
    ABrush.Assign(Fill);
    Result := True;
    OnGetCellBackground(Self, ANode, AColumn, ABrush, Result);
  end;
end;

function TQVirtualTreeView.GetCellRect(ANode: TQVTNode;
  AColumn: Integer): TRectF;

var
  I: Integer;
  R: TRectF;
  ACol: TQVTColumn;
begin
  if FVisibleNodes.IndexOf(ANode) <> -1 then
  begin
    R := ANode.FDisplayRect;
    Result.Top := R.Top;
    Result.Bottom := R.Bottom;
    Result.Left := R.Left;
    for I := 0 to AColumn do
    begin
      ACol := Header.Columns[I];
      if ACol.Visible then
      begin
        Result.Right := Result.Left + ACol.Width;
        if I <> AColumn then
          Result.Left := Result.Right + FSpace.X
        else
          Break;
      end
      else if I = AColumn then
      begin
        Result := TRect.Empty;
        Break;
      end;
    end;
    if Result.Right > R.Right then
      Result.Right := R.Right;
  end
  else
    Result := TRectF.Empty;
end;

function TQVirtualTreeView.GetColSpace: Single;
begin
  Result := FSpace.X;
end;

function TQVirtualTreeView.GetChildCount(ANode: TQVTNode): Integer;
begin
  ANode.InitChildren;
  Result := ANode.FCount;
end;

procedure TQVirtualTreeView.GetChildren(Proc: TGetChildProc; Root: TComponent);

var
  I: Integer;
  AComp: TComponent;
begin
  for I := 0 to ComponentCount - 1 do
  begin
    AComp := Components[I];
    if (AComp <> FVertScrollBar) and (AComp <> FHorzScrollBar) then
      Proc(AComp);
  end;
end;

class function TQVirtualTreeView.GetDefaultDrawer(AType: TQVTDrawerType)
  : IQVTDrawer;
begin
  if AType in [TQVTDrawerType.dtDefault .. TQVTDrawerType.dtCustom] then
    Result := DefaultDrawers[AType]
  else
    Result := nil;
end;

function TQVirtualTreeView.GetDisplayRect(ANode: TQVTNode): TRectF;
begin
  if FVisibleNodes.IndexOf(ANode) <> -1 then
    Result := ANode.FDisplayRect
  else
    Result := TRectF.Empty;
end;

function TQVirtualTreeView.GetFill: TBrush;
begin
  Result := FFill;
end;

function TQVirtualTreeView.GetIsEditing: Boolean;
begin
  Result := Assigned(FInplaceEditor);
end;

function TQVirtualTreeView.GetNext(ANode: TQVTNode): TQVTNode;
begin
  if TQVTNodeState.nsHasChildren in ANode.States then
  begin
    Result := ANode.GetFirstChild;
    if Assigned(Result) then
      Exit;
  end;
  repeat
    Result := ANode.GetNext;
    if not Assigned(Result) then
      ANode := ANode.Parent
    else
      Break;
  until not Assigned(ANode);
end;

function TQVirtualTreeView.GetNextVisible(ANode: TQVTNode;
  AutoExpandChildren: Boolean): TQVTNode;
begin
  if ANode.HasChildren and ((TQVTNodeState.nsExpanded in ANode.FStates) or
    AutoExpandChildren) then
  begin
    Result := ANode.GetFirstVisibleChild;
    if Assigned(Result) then
      Exit;
  end;
  repeat
    Result := ANode.GetNext;
    if not Assigned(Result) then
      ANode := ANode.Parent
    else if TQVTNodeState.nsVisible in Result.FStates then
      Break;
  until not Assigned(ANode);
end;

function TQVirtualTreeView.GetNodeAt(const APos: TPointF; AColumn: PInteger)
  : TQVTNode;
var
  Dummy: Integer;
begin
  DoHitTest(APos, Result, Dummy);
  if Assigned(AColumn) then
    AColumn^ := Dummy;
end;

function TQVirtualTreeView.GetNodeFill(ANode: TQVTNode; ABrush: TBrush)
  : Boolean;
// 将颜色变暗
  function GrayColor(AColor: TAlphaColor): TAlphaColor;
  var
    C: TAlphaColorRec absolute Result;
  begin
    Result := AColor;
    if C.R >= 10 then
      Dec(C.R, 10);
    if C.G >= 10 then
      Dec(C.G, 10);
    if C.B >= 10 then
      Dec(C.B, 10);
  end;

begin
  Result := false;
  if Assigned(OnGetNodeBackground) then
  begin
    ABrush.Assign(Fill);
    Result := True;
    OnGetNodeBackground(Self, ANode, ABrush, Result);
  end;
  if not Result then
  begin
    if (nsHover in ANode.States) and (poHover in PaintOptions) then
    begin
      ABrush.Kind := TBrushKind.Solid;
      if Root.Focused.GetObject = Self then
        ABrush.Color := HoverColor
      else
        ABrush.Color := GrayColor(HoverColor); // 变暗
      Result := (ABrush.Color <> Fill.Color) or (ABrush.Kind <> Fill.Kind);
    end
    else if (nsSelected in ANode.States) and (poRowSelection in PaintOptions)
    then
    begin
      ABrush.Color := SelectionColor;
      if Root.Focused.GetObject = Self then
        ABrush.Color := SelectionColor
      else
        ABrush.Color := GrayColor(SelectionColor); // 降低透
      ABrush.Kind := TBrushKind.Solid;
      Result := (ABrush.Color <> Fill.Color) or (ABrush.Kind <> Fill.Kind);
    end;
  end;
end;

function TQVirtualTreeView.GetPriorVisible(ANode: TQVTNode): TQVTNode;

var
  APrior: TQVTNode;
begin
  Result := nil;
  APrior := ANode.GetPriorVisible(ANode);
  if not Assigned(APrior) then
  begin
    if ANode.Parent <> RootNode then
      Result := ANode.Parent;
  end
  else
  begin
    while APrior.HasChildren and (TQVTNodeState.nsExpanded in APrior.FStates) do
    begin
      Result := APrior.GetLastVisibleChild;
      if Assigned(Result) then
        APrior := Result;
    end;
    Result := APrior;
  end;
end;

function TQVirtualTreeView.GetRootNode: TQVTNode;
begin
  if not Assigned(FRootNode) then
  begin
    FRootNode := CreateNode;
    FRootNode.FCount := 0; // 初始为没有子结点
    FRootNode.FStates := FRootNode.FStates + [nsExpanded, nsInitialized];
    FRootNode._AddRef;
    // 增加引用计数，避免被释放
  end;
  Result := FRootNode;
end;

function TQVirtualTreeView.GetRootNodeCount: Integer;
begin
  Result := RootNode.ChildCount;
end;

function TQVirtualTreeView.GetRowSpace: Single;
begin
  Result := FSpace.Y;
end;

function TQVirtualTreeView.GetSortColumns: TQVTSortColumns;
begin
  if not Assigned(FSortColumns) then
  begin
    FSortColumns := TQVTSortColumns.Create;
    FSortColumns.OnNotify := DoSortColumnsChanged;
  end;
  Result := FSortColumns;
end;

function TQVirtualTreeView.GetStroke: TStrokeBrush;
begin
  Result := FStroke;
end;

function TQVirtualTreeView.GetTextSettingsClass
  : TTextSettingsInfo.TCustomTextSettingsClass;
begin
  Result := TCellTextSettings;
end;

procedure TQVirtualTreeView.DoCellDataRemove(const Sender: TObject;
  const M: TMessage);
var
  AData: IQVTCellData;
  ADrawer: IQVTDrawer;
  AEditor: IQVTInplaceEditor;
  I: Integer;
  AMsg: TQVTCellNotifyMessage absolute M;
begin
  case AMsg.value of
    cntData:
      begin
        if Supports(Sender, IQVTCellData, AData) then
        begin
          for I := 0 to Header.Columns.Count - 1 do
          begin
            with Header.Columns[I] do
            begin
              if FCellData = AData then
                FCellData := nil;
            end;
          end;
        end;
      end;
    cntDrawer:
      begin
        if Supports(Sender, IQVTDrawer, ADrawer) then
        begin
          for I := 0 to Header.Columns.Count - 1 do
          begin
            with Header.Columns[I] do
            begin
              if FDrawer = ADrawer then
                FDrawer := nil;
              if Title.FDrawer = ADrawer then
                Title.FDrawer := nil;
            end;
          end;
        end;
      end;
    cntEditor:
      begin
        if Supports(Sender, IQVTInplaceEditor, AEditor) then
        begin
          for I := 0 to Header.Columns.Count - 1 do
          begin
            with Header.Columns[I] do
            begin
              if FEditor = AEditor then
                FEditor := nil;
            end;
          end;
        end;
      end;
  end;
end;

function TQVirtualTreeView.DoHitTest(const APos: TPointF; var ANode: TQVTNode;
  var AColumn: Integer): TQVTHitTestResult;

var
  I: Integer;
  L, T, AHeaderBottom: Single;
  AColResizable, ARowResizable: Boolean;
  LR: TRectF;
  ACurrentNode: TQVTNode;

const
  MinSpace = 4;
  MinHalfSpace = 2;
begin
  Result := hrNone;
  AColumn := -1;
  ANode := nil;
  LR := LocalRect;
  LR.Left := LR.Left + Padding.Left;
  LR.Top := LR.Top + Padding.Top;
  LR.Right := LR.Right - Padding.Right;
  LR.Bottom := LR.Bottom - Padding.Bottom;
  // 不再显示区域内，则忽略
  if (APos.Y < LR.Top) or (APos.Y > LR.Bottom) or (APos.X < LR.Left) or
    (APos.X > LR.Right) then
    Exit;
  // 如果标题行可见，计算标题行下边界
  if TQVTHeaderOption.hoVisible in Header.Options then
  begin
    AHeaderBottom := Padding.Top + Header.Height;
    if TQVTPaintOption.poHorizLine in PaintOptions then
      AHeaderBottom := AHeaderBottom + Stroke.Thickness;
  end
  else
    AHeaderBottom := LR.Top;
  AColResizable := (TQVTHeaderOption.hoResizable in Header.Options);
  L := LR.Left;
  if TQVTPaintOption.poVertLine in PaintOptions then
    L := L + Stroke.Thickness;
  // X 坐标不在范围内的话，直接退出
  if (APos.X < L) or (APos.X > FPaintOffset.X + FHeader.Width + 5) or
    (APos.X > Width - Padding.Right) then
    Exit;
  L := L - FPaintOffset.X;
  for I := 0 to FHeader.Columns.Count - 1 do
  begin
    L := L + FHeader.Columns[I].Width;
    if L > APos.X then
    begin
      AColumn := I;
      if (Result = TQVTHitTestResult.hrNone) and (APos.Y < AHeaderBottom) then
        Result := TQVTHitTestResult.hrHeader;
      Break;
    end;
    if AColResizable then // 判断是否落在分隔线上
    begin
      if FSpace.X < MinSpace then
      begin
        T := FSpace.X / 2;
        if T < MinHalfSpace then
          T := MinHalfSpace;
        if (APos.X > L - T) and (APos.X < L + T) then
          Result := TQVTHitTestResult.hrColumnSpace;
      end
      else if (APos.X > L) and (APos.X < L + FSpace.X) then
        Result := TQVTHitTestResult.hrColumnSpace;
    end;
    L := L + FSpace.X;
  end;
  ARowResizable := TQVTOption.toRowSizable in Options;
  // 获取结点
  if Assigned(FFirstVisibleNode) then
  begin
    if APos.Y < AHeaderBottom then
      Exit;
    for I := 0 to FVisibleNodes.Count - 1 do
    begin
      ACurrentNode := FVisibleNodes[I];
      if ARowResizable then
      begin
        if FSpace.Y < MinSpace then
        begin
          T := FSpace.Y / 2;
          if T < MinHalfSpace then
            T := MinHalfSpace;
          if (APos.Y < ACurrentNode.FDisplayRect.Top + T) and
            (APos.Y > ACurrentNode.FDisplayRect.Top - T) then
          begin
            Result := TQVTHitTestResult.hrRowSpace;
            ANode := ACurrentNode;
            Break;
          end;
        end
        else if (APos.Y < ACurrentNode.FDisplayRect.Top) and
          (APos.Y > ACurrentNode.FDisplayRect.Top - FSpace.Y) then
        begin
          Result := TQVTHitTestResult.hrRowSpace;
          if I > 0 then
            ANode := ACurrentNode;
        end;
      end;
      if PtInRect(ACurrentNode.FDisplayRect, APos) then
      begin
        ANode := FVisibleNodes[I];
        if Result = TQVTHitTestResult.hrNone then
          Result := TQVTHitTestResult.hrNode;
        Break;
      end;
    end;
  end;
end;

procedure TQVirtualTreeView.DoMouseEnter;
begin
  inherited;

end;

procedure TQVirtualTreeView.DoMouseLeave;
begin
  inherited;

end;

procedure TQVirtualTreeView.InitNode(ANode: TQVTNode);
begin
  try
    if Assigned(FOnInitNode) then
      FOnInitNode(Self, ANode);
  finally
    ANode.FStates := ANode.FStates + [TQVTNodeState.nsInitialized];
  end;
end;

procedure TQVirtualTreeView.Invalidate;
begin
  InvalidateRect(LocalRect);
end;

procedure TQVirtualTreeView.InvalidateColumn(const AColumn: Integer);
begin
  // 暂时全刷新
  Invalidate;
end;

procedure TQVirtualTreeView.InvalidateNode(const ANode: TQVTNode);
begin
  // 暂时全刷新
  Invalidate;
end;

procedure TQVirtualTreeView.KeyDown(var Key: Word; var KeyChar: System.WideChar;
  Shift: TShiftState);
var
  ANode: TQVTNode;
  AEditor: IVQTCellSpaceEditCellData;
begin
  inherited;
  case Key of
    vkUp:
      begin
        if Assigned(FocusNode) and EndEdit then
        begin
          ANode := GetPriorVisible(FocusNode);
          if Assigned(ANode) then
            FocusNode := ANode;
        end;
      end;
    vkDown:
      begin
        if Assigned(FocusNode) and EndEdit then
        begin
          ANode := GetNextVisible(FocusNode);
          if Assigned(ANode) then
            FocusNode := ANode;
        end;
      end;
    vkLeft:
      begin
        if Assigned(FocusNode) and EndEdit then
        begin
          if FocusColumn > 0 then
            FocusColumn := FocusColumn - 1;
        end;
      end;
    vkRight:
      begin
        if Assigned(FocusNode) and EndEdit then
        begin
          if FocusColumn + 1 < Header.Columns.Count then
            FocusColumn := FocusColumn + 1;
        end;
      end;
    vkPrior: // PageUp 上翻半篇
      if EndEdit and Assigned(VertScrollBar) then
      begin
        VertScrollBar.value := VertScrollBar.value -
          (LocalRect.Height - Padding.Top - Padding.Bottom) / 2;
      end;
    vkNext: // PageDown 下翻半篇
      begin
        if EndEdit and Assigned(VertScrollBar) then
          VertScrollBar.value := VertScrollBar.value +
            (LocalRect.Height - Padding.Top - Padding.Bottom) / 2;
      end
  else
    if KeyChar = ' ' then
    begin
      if Assigned(FocusNode) and Supports(FocusNode.CellData[FocusColumn],
        IVQTCellSpaceEditCellData, AEditor) and CanEdit(FocusNode, FocusColumn)
      then
        AEditor.NextValue;
    end;
  end;
end;

procedure TQVirtualTreeView.MakeNodeVisible(ANode: TQVTNode;
  ACenterInView: Boolean);
var
  AMin: Single;
  R: TRectF;
begin
  CheckScrollBars;
  if FVisibleNodes.IndexOf(ANode) = -1 then
  begin
    AMin := ANode.FDistance;
    R := LocalRect;
    if TQVTHeaderOption.hoVisible in Header.Options then
      R.Top := R.Top + Padding.Top + Header.Height + FSpace.Y
    else
      R.Top := R.Top + Padding.Top;
    R.Bottom := R.Bottom - Padding.Bottom;
    if Assigned(FVertScrollBar) then
      FVertScrollBar.value := AMin;
  end;
end;

procedure TQVirtualTreeView.MouseClick(Button: TMouseButton; Shift: TShiftState;
  X, Y: Single);

var
  ANode: TQVTNode;
  ACol: Integer;
  pt: TPointF;
  AHitTest: TQVTHitTestResult;
  procedure DoTitleClick;

  var
    AColumn: TQVTColumn;
    I: Integer;
  begin
    AColumn := Header.Columns[ACol];
    if AColumn.Title.Clickable then
    begin
      if Assigned(FOnTitleClick) then
        FOnTitleClick(Self, ACol);
      if AColumn.Title.SortOnClick then
      begin
        case AColumn.Title.SortMarker of
          smNone:
            AColumn.Title.FSortMarker := smAsc;
          smAsc:
            AColumn.Title.FSortMarker := smDesc;
          smDesc:
            AColumn.Title.FSortMarker := smNone;
        end;
        if AColumn.Title.SortMarker <> smNone then
        begin
          if TQVTHeaderOption.hoMultiSortColumns in Header.Options then
          begin
            if SortColumns.IndexOf(AColumn) = -1 then
              FSortColumns.Add(AColumn)
            else
              DoSortMarkerChanged(Self);
          end
          else
          begin
            SortColumns.OnNotify := nil;
            I := FSortColumns.Count - 1;
            while I >= 0 do
            begin
              if FSortColumns[I] <> AColumn then
              begin
                with FSortColumns[I] do
                begin
                  FSortIndex := -1;
                  Title.FSortMarker := TQVTColumnSortMarker.smNone;
                end;
              end;
              FSortColumns.Delete(FSortColumns.Count - 1);
              Dec(I);
            end;
            FSortColumns.OnNotify := DoSortColumnsChanged;
            FSortColumns.Add(AColumn);
          end
        end
        else
          FSortColumns.Remove(AColumn);
      end;
      FocusColumn := ACol;
    end;
  end;

begin
  inherited;
  pt := PointF(X, Y);
  if (FStates = []) or (FMouseDownPos.Distance(pt) < 5) then
  begin
    AHitTest := DoHitTest(FMouseDownPos, ANode, ACol);
    if Assigned(ANode) then
    begin
      // 点击展开/收缩按钮
      if ANode.HasChildren and PtInRect(ANode.FButtonRect, pt) then
      begin
        if TQVTNodeState.nsExpanded in ANode.FStates then
          ANode.States := ANode.States - [TQVTNodeState.nsExpanded]
        else
          ANode.Expand(false);
      end
      else
      begin
        if FocusChanging(ANode, ACol) then
        begin
          FFocusColumn := ACol;
          FocusNode := ANode;
          FocusChanged;
        end;
        if Assigned(FMouseEditor) then
          FMouseEditor.MouseClick(Button, Shift, pt);
        CellClick(ANode, ACol, pt);
      end;
    end
    // else if AHitTest in [TQVTHitTestResult.hrNone] then
    // begin
    // if FocusChanging(nil, -1) then
    // begin
    // FFocusColumn := -1;
    // FFocusNode := nil;
    // FocusChanged;
    // end;
    // end
    else if AHitTest = TQVTHitTestResult.hrHeader then
      DoTitleClick;
  end;
end;

procedure TQVirtualTreeView.MouseDown(Button: TMouseButton; Shift: TShiftState;
  X, Y: Single);
begin
  inherited;
  if (([TQVTOption.toTestHover, TQVTOption.toRowSizable] * Options) <> []) or
    (TQVTHeaderOption.hoResizable in Header.Options) then
  begin
    FMouseDownPos.X := X;
    FMouseDownPos.Y := Y;
    if Assigned(FHorzScrollBar) then
      FMouseDownOffset.X := HorzScrollBar.value
    else
      FMouseDownOffset.X := 0;
    if Assigned(FVertScrollBar) then
      FMouseDownOffset.Y := VertScrollBar.value
    else
      FMouseDownOffset.Y := 0;
    FMouseDownTime := TThread.GetTickCount;
    FMouseDownPosition := DoHitTest(FMouseDownPos, FMouseDownNode,
      FMouseDownColumn);
    case FMouseDownPosition of
      hrNode, hrHeader:
        // To drag node?
        begin
          if Header.Columns[FMouseDownColumn].Title.Clickable then
            Invalidate;
          if (FMouseDownPosition = hrNode) then
          begin
            if (ssDouble in Shift) then
            begin
              if toAutoCascade in Options then
                FMouseDownNode.IsExpanded := not FMouseDownNode.IsExpanded;
              if Assigned(FOnCellDblClick) then
                FOnCellDblClick(Self, FMouseDownNode, FMouseDownColumn,
                  FMouseDownPos);
            end;
            if (toClickToExpand in Options) and FMouseDownNode.HasChildren and
              (not FMouseDownNode.IsExpanded) and
              (not PtInRect(FMouseDownNode.FButtonRect, FMouseDownPos)) then
              FMouseDownNode.Expand();
            if Supports(FMouseDownNode.CellData[FMouseDownColumn],
              IQVTCellMouseEditCellData, FMouseEditor) and
              CanEdit(FMouseDownNode, FMouseDownColumn) then
              FMouseEditor.MouseDown(Button, Shift, FMouseDownOffset)
            else
              FMouseEditor := nil;
          end;
        end;
      hrColumnSpace:
        begin
          if FMouseDownColumn = -1 then
            FSizingColumn := FHeader.Columns[FHeader.Columns.Count - 1]
          else
            FSizingColumn := FHeader.Columns[FMouseDownColumn - 1];
          FSizingColumnOriginWidth := FSizingColumn.Width;
          FStates := FStates + [TQVTState.tsColSizing];
        end;
      hrRowSpace:
        begin
          if not Assigned(FMouseDownNode) then
            DoHitTest(FMouseDownPos, FMouseDownNode, FMouseDownColumn);
          FSizingNode := GetPriorVisible(FMouseDownNode);
          if Assigned(FSizingNode) then
            FSizingNodeOriginHeight := FSizingNode.Height
          else // 最前面调整标题高度
            FSizingNodeOriginHeight := FHeader.Height;
          FStates := FStates + [TQVTState.tsRowSizing];
        end;
    end;
    if (Button = TMouseButton.mbLeft) and (not Assigned(FMouseEditor)) and
      (FStates * [TQVTState.tsColSizing, TQVTState.tsRowSizing] = []) and
      (Assigned(FVertScrollBar) or Assigned(FHorzScrollBar)) then
    begin
      FAniCalculations.Averaging := ssTouch in Shift;
      FAniCalculations.MouseDown(X, Y);
    end;
  end;
end;

procedure TQVirtualTreeView.MouseMove(Shift: TShiftState; X, Y: Single);

var
  ANode: TQVTNode;
  ACol: Integer;
  AHitTest: TQVTHitTestResult;
begin
  if FAniCalculations.Down and (not(ssLeft in Shift)) then // 鼠标移出时需要控制时下
    FAniCalculations.Down := false;
  if Assigned(FMouseEditor) then // 编辑器优先获得处理权限
    FMouseEditor.MouseMove(Shift, PointF(X, Y))
  else if TQVTState.tsColSizing in FStates then
  begin
    FSizingColumn.Width := FSizingColumnOriginWidth - (FMouseDownPos.X - X);
    AdjustAutoSizeColumn;
  end
  else if TQVTState.tsRowSizing in FStates then
  begin
    if Assigned(FSizingNode) then
      FSizingNode.Height := FSizingNodeOriginHeight - (FMouseDownPos.Y - Y)
    else
      FHeader.Height := FSizingNodeOriginHeight - (FMouseDownPos.Y - Y);
  end
  else if TQVTState.tsScrolling in FStates then
  begin
    if Assigned(HorzScrollBar) then
      HorzScrollBar.value := FMouseDownOffset.X + (FMouseDownPos.X - X);
    if Assigned(VertScrollBar) then
      VertScrollBar.value := FMouseDownOffset.Y + (FMouseDownPos.Y - Y);
  end
  else
  begin
    if (([TQVTOption.toTestHover, TQVTOption.toRowSizable] * Options) <> []) or
      (TQVTHeaderOption.hoResizable in Header.Options) then
    begin
      AHitTest := DoHitTest(PointF(X, Y), ANode, ACol);
      case AHitTest of
        hrNone, hrHeader:
          Cursor := crDefault;
        hrNode:
          begin
            Cursor := crDefault;
            if (TQVTOption.toTestHover in Options) and
              ((ANode <> FHoverNode) or (ACol <> FHoverColumn)) then
            begin
              if Assigned(FHoverNode) then
                FHoverNode.States := FHoverNode.States - [nsHover];
              FHoverNode := ANode;
              if Assigned(FHoverNode) then
                FHoverNode.States := FHoverNode.States + [nsHover];
              FHoverColumn := ACol;
              if Assigned(FOnHoverChanged) then
                FOnHoverChanged(Self);
              if TQVTPaintOption.poHover in PaintOptions then
                Invalidate;
            end;
          end;
        hrColumnSpace:
          Cursor := crHSplit;
        hrRowSpace:
          Cursor := crVSplit;
      end;
    end;
    if (ssTouch in Shift) and ([TQVTState.tsDragging, TQVTState.tsScrolling] *
      FStates = []) then
    begin
      if (TThread.GetTickCount - FMouseDownTime < 500) or
        (DragMode <> TDragMode.dmManual) then
      begin
        FStates := FStates + [TQVTState.tsScrolling];
      end;
    end;
    if FAniCalculations.Down then
    begin
      if Assigned(FHorzScrollBar) then
      begin
        if Assigned(FVertScrollBar) then
          FAniCalculations.MouseMove(X, Y)
        else
          FAniCalculations.MouseMove(X, FMouseDownPos.Y);
      end
      else
        FAniCalculations.MouseMove(FMouseDownPos.X, Y);
    end;
  end;
  inherited;
end;

procedure TQVirtualTreeView.MouseUp(Button: TMouseButton; Shift: TShiftState;
  X, Y: Single);
begin
  inherited;
  if Assigned(FMouseEditor) then
  begin
    FMouseEditor.MouseUp(Button, Shift, PointF(X, Y));
    EndEdit;
  end;
  if FStates * [TQVTState.tsColSizing, TQVTState.tsRowSizing] <> [] then
    NodeContentChanged
  else if Button = TMouseButton.mbLeft then
    FAniCalculations.MouseUp(X, Y);
  FStates := FStates - [TQVTState.tsColSizing, TQVTState.tsRowSizing,
    TQVTState.tsScrolling, TQVTState.tsDragging];
  if FMouseDownColumn <> -1 then
    Invalidate;
  FMouseDownColumn := -1;
  FMouseDownNode := nil;
  FMouseDownPosition := TQVTHitTestResult.hrNone;
end;

procedure TQVirtualTreeView.MouseWheel(Shift: TShiftState; WheelDelta: Integer;
  var Handled: Boolean);
  procedure DoWheel(ABar: TScrollBar);

  var
    V: Single;
  begin
    if Assigned(ABar) then
    begin
      V := ABar.value - WheelDelta / 10;
      if V > ABar.Max then
        ABar.value := ABar.Max
      else if V < ABar.Min then
        ABar.value := ABar.Min
      else
        ABar.value := V;
    end;
  end;

begin
  inherited;
  if ssCtrl in Shift then
    DoWheel(FHorzScrollBar)
  else
    DoWheel(FVertScrollBar);
end;

procedure TQVirtualTreeView.NodeContentChanged;
begin
  FStates := FStates + [TQVTState.tsVisibleChanged, TQVTState.tsContentChanged];
  Invalidate;
end;

procedure TQVirtualTreeView.NodeVisibleChanged;
begin
  FStates := FStates + [TQVTState.tsVisibleChanged];
  Invalidate;
end;

procedure TQVirtualTreeView.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  inherited;
  if Operation = opRemove then
  begin
    if AComponent = FHorzScrollBar then
      FHorzScrollBar := nil
    else if AComponent = FVertScrollBar then
      FVertScrollBar := nil;
  end;
end;

procedure TQVirtualTreeView.Paint;

var
  R, AClientRect: TRectF;
  AMaxRight: Single;
  ADrawer: IQVTDrawer;
  ACol: TQVTColumn;
  ANode: TQVTNode;
  AState: TCanvasSaveState;
  procedure DrawGridLines;
  var
    pt1, pt2: TPointF;
    I: Integer;
    YStart, W: Single;
    ADrawHorz, ADrawVert: Boolean;
  begin
    W := FHeader.Width - FPaintOffset.X;
    ADrawHorz := TQVTPaintOption.poHorizLine in PaintOptions;
    ADrawVert := TQVTPaintOption.poVertLine in PaintOptions;
    // 先画水平线
    pt1.X := AClientRect.Left;
    pt2.X := pt1.X + W;
    if TQVTHeaderOption.hoVisible in Header.Options then
      YStart := AClientRect.Top + Header.Height + FSpace.Y - FPaintOffset.Y
    else
      YStart := AClientRect.Top - FPaintOffset.Y;
    pt1.Y := YStart;
    for I := 0 to FVisibleNodes.Count do
    begin
      pt2.Y := pt1.Y;
      if ADrawHorz then
        Canvas.DrawLine(pt1.SnapToPixel(Canvas.Scale),
          pt2.SnapToPixel(Canvas.Scale), Opacity, FStroke);
      if I < FVisibleNodes.Count then
      begin
        pt1.Y := pt1.Y + FVisibleNodes[I].Height;
        if I + 1 < FVisibleNodes.Count then
          pt1.Y := pt1.Y + FSpace.Y;
      end;
    end;
    if ADrawVert then
    begin
      pt1 := AClientRect.TopLeft;
      pt1.X := pt1.X - FPaintOffset.X;
      pt1.Y := YStart;
      for I := 0 to FHeader.Columns.Count do
      begin
        pt2.X := pt1.X;
        if I >= FFirstVisibleColumn then
          Canvas.DrawLine(pt1.SnapToPixel(Canvas.Scale),
            pt2.SnapToPixel(Canvas.Scale), Opacity, FStroke);
        if I < FHeader.Columns.Count then
        begin
          pt1.X := pt1.X + FHeader.Columns[I].Width;
          if I + 1 < FHeader.Columns.Count then
            pt1.X := pt1.X + FSpace.X;
        end;
      end;
    end;
  end;

  function DrawHeader: Boolean;
  var
    I: Integer;
  begin
    Result := TQVTHeaderOption.hoVisible in FHeader.Options;
    R := AClientRect;
    if Result then
    begin
      R.Top := R.Top + Stroke.Thickness;
      R.Bottom := R.Top + FHeader.Height;
      R.Left := R.Left - FPaintOffset.X + Stroke.Thickness;
      if R.Left > Stroke.Thickness then
        Canvas.FillRect(R, 0, 0, [], Opacity, Fill)
      else
        Canvas.FillRect(RectF(Stroke.Thickness, R.Top, R.Right, R.Bottom), 0, 0,
          [], Opacity, Fill);
      for I := 0 to FHeader.Columns.Count - 1 do
      begin
        ACol := FHeader.Columns[I];
        R.Right := R.Left + ACol.Width;
        if R.Right > AMaxRight then
          R.Right := AMaxRight;
        if R.Left < Stroke.Thickness then
          R.Left := Stroke.Thickness;
        if (I >= FFirstVisibleColumn) and (R.Left < R.Right) then
        begin
          ADrawer := ACol.Title.Drawer;
          if Assigned(ADrawer) then
            ADrawer.Draw(R, ACol.Title as IQVTCellData);
        end;

        R.Left := R.Right + FSpace.X;
        if R.Left > AMaxRight then
          Break;
      end;
    end
  end;

  procedure SetEditorPos(R: TRectF);
  begin
    if R.Left < AClientRect.Left then
      R.Left := AClientRect.Left;
    if R.Right > AClientRect.Right then
      R.Right := AClientRect.Right;
    FInplaceEditor.SetBounds(R);
    FInplaceEditor.Show;
  end;
  function EditorFocused: Boolean;
  var
    ACtrl: TControl;
  begin
    ACtrl := Root.Focused as TControl;
    Result := false;
    while Assigned(ACtrl) do
    begin
      if ACtrl.Parent = Self then
        Exit(True)
      else
        ACtrl := ACtrl.ParentControl;
    end;
  end;
  procedure DrawNodes;
  var
    I, J, K, AEditingCol, ASpans: Integer;
    ADrawHover: Boolean;
    ADrawRowSelection, ADrawColSelection, ADrawCellSelection, AdjustEditor,
      AEditorVisible: Boolean;
    ACellRect, AEditorRect: TRectF;
    ACellData: IQVTCellData;
    ASides: TSides;
    ADrawCellGrid, AColFocused: Boolean;
  begin
    ADrawHover := Assigned(FHoverNode) and
      (TQVTPaintOption.poHover in PaintOptions);
    ADrawRowSelection := TQVTPaintOption.poRowSelection in PaintOptions;
    ADrawColSelection := TQVTPaintOption.poColSelection in PaintOptions;
    ADrawCellSelection := TQVTPaintOption.poCellSelection in FPaintOptions;
    ADrawCellGrid := [TQVTPaintOption.poHorizLine, TQVTPaintOption.poVertLine] *
      FPaintOptions <> [];
    AEditorVisible := Assigned(FInplaceEditor) and EditorFocused;
    AEditorRect := TRectF.Empty;
    for I := 0 to FVisibleNodes.Count - 1 do
    begin
      ANode := FVisibleNodes[I];
      AdjustEditor := AEditorVisible and
        (FInplaceEditor.GetEditing(AEditingCol) = ANode);
      R := ANode.FDisplayRect;
      J := 0;
      ACellRect.Top := R.Top - FSpace.Y / 2;
      if poHorizLine in PaintOptions then
        ACellRect.Bottom := R.Bottom - FStroke.Thickness
      else
        ACellRect.Bottom := R.Bottom;
      if GetNodeFill(ANode, FActiveFill) then
        // Canvas.ClearRect(R,FActiveFill.Color);
        Canvas.FillRect(R.SnapToPixel(Canvas.Scale), 0, 0, [], Opacity,
          FActiveFill);
      while J < FHeader.Columns.Count do
      begin
        ACol := FHeader.Columns[J];
        ACellRect.Left := R.Left;
        ACellRect.Right := R.Left;
        ASpans := 0;
        if Assigned(OnGetCellSpans) then
        begin
          OnGetCellSpans(Self, ANode, J, ASpans);
          if J + ASpans >= FHeader.Columns.Count then
            ASpans := FHeader.Columns.Count - J - 1;
        end;
        for K := 0 to ASpans do
          ACellRect.Right := ACellRect.Right + FHeader.Columns[J + K].Width
            + FSpace.X;
        ACellRect.Right := ACellRect.Right - FSpace.X;
        ADrawer := ANode.CellDrawer[J];
        ACellData := ANode.CellData[J];
        if GetCellFill(ANode, J, FActiveFill) then
          // Canvas.ClearRect(ACellRect,FActiveFill.Color);
          Canvas.FillRect(ACellRect.SnapToPixel(Canvas.Scale), 0, 0, [],
            Opacity, FActiveFill);
        if Assigned(ADrawer) then
        begin
          AColFocused := (J <= FFocusColumn) and (J + ASpans >= FFocusColumn);
          if AdjustEditor and (J = FocusColumn) then
          begin
            AEditorRect := ADrawer.EditorBounds[ACellData];
            ADrawer.Draw(RectF(ACellRect.Left, ACellRect.Top, AEditorRect.Left,
              ACellRect.Bottom), ACellData);
          end
          else
          begin
            if AColFocused and
              (ADrawColSelection or (ADrawCellSelection and
              (ANode = FFocusNode))) then
              Canvas.ClearRect(ACellRect, FSelectionColor);
            if J >= FFirstVisibleColumn then
              ADrawer.Draw(ACellRect, ACellData);
          end;
        end;
        R.Left := ACellRect.Right + FSpace.X;
        if Assigned(ACellData) and ADrawCellGrid then
        begin
          ACellRect.Left := ACellRect.Left - FSpace.X / 2;
          ACellRect.Right := ACellRect.Right + FSpace.X / 2;
          // 计算需要绘制的表格边框
          ASides := [TSide.Bottom];
          if ACellRect.Left > Stroke.Thickness then
            ASides := ASides + [TSide.Left];
          if J + ASpans + 1 = FHeader.Columns.Count then
            ASides := ASides + [TSide.Right];
          if not(TQVTPaintOption.poVertLine in FPaintOptions) then
            ASides := ASides - [TSide.Left, TSide.Right];
          if not(TQVTPaintOption.poHorizLine in FPaintOptions) then
            ASides := ASides - [TSide.Top, TSide.Bottom];
          ASides := ASides * ACellData.Sides;
          if ASides <> [] then
            Canvas.DrawRectSides(ACellRect.SnapToPixel(Canvas.Scale), 0, 0, [],
              Opacity, ASides, FStroke);
        end;
        if R.Left > AMaxRight then
          Break;
        Inc(J, ASpans + 1);
      end;
    end;
    if AEditorVisible then
    begin
      if not AEditorRect.IsEmpty then
        SetEditorPos(AEditorRect)
      else
        FInplaceEditor.Show;
    end
    else if Assigned(FInplaceEditor) then
      FInplaceEditor.Hide;
  end;

begin
  R := LocalRect;
  if Canvas.BeginScene then
  begin
    FActiveFill := TBrush.Create(TBrushKind.Solid, TAlphaColors.Null);
    AState := Canvas.SaveState;
    try
      Canvas.FillRect(R, 0, 0, [], Opacity, Fill);
      Canvas.DrawRect(R.SnapToPixel(Canvas.Scale), 0, 0, [], Opacity, Stroke);
      if not Assigned(FTextLayout) then
        FTextLayout := TTextLayoutManager.TextLayoutByCanvas(Canvas.ClassType)
          .Create(Canvas);
      AClientRect := RectF(Padding.Left, Padding.Top, Width - Padding.Right,
        Height - Padding.Top);
      if Assigned(HorzScrollBar) then
        AClientRect.Bottom := AClientRect.Bottom - HorzScrollBar.Height;
      if Assigned(VertScrollBar) then
        AClientRect.Right := AClientRect.Right - VertScrollBar.Width;
      R := AClientRect;
      AMaxRight := AClientRect.Right;
      if TQVTHeaderOption.hoVisible in FHeader.Options then
        R.Top := R.Top + FHeader.Height + FSpace.Y
      else
        R.Top := R.Top + FSpace.X;
      R.Top := R.Top - FPaintOffset.Y;
      // 设置结点绘制区域
      // Canvas.IntersectClipRect(RectF(R.Left, Padding.Top, R.Right, R.Bottom));
      R.Left := R.Left - FPaintOffset.X;
      CalcVisibleNodes;
      DrawNodes;
      DrawHeader;
    finally
      Canvas.RestoreState(AState);
      Canvas.EndScene;
      FreeAndNil(FActiveFill);
    end;
  end;
end;

procedure TQVirtualTreeView.Resize;
begin
  inherited;
  AdjustAutoSizeColumn;
  NodeContentChanged;
end;

procedure TQVirtualTreeView.RowDirty(ARowIndex: Integer);
begin
  if ARowIndex < FDirtyRowIndex then
    FDirtyRowIndex := ARowIndex;
end;

procedure TQVirtualTreeView.ScrollBy(dx, dy: Single);
begin
  if Assigned(VertScrollBar) then
    VertScrollBar.value := VertScrollBar.value + dy;
  if Assigned(HorzScrollBar) then
    HorzScrollBar.value := HorzScrollBar.value + dx;
end;

procedure TQVirtualTreeView.SetColSpace(const value: Single);
begin
  if not SameValue(FSpace.X, value) then
  begin
    if value > 0 then
      FSpace.X := value
    else
      FSpace.X := 0;
    AdjustAutoSizeColumn;
    NodeContentChanged;
  end;
end;

procedure TQVirtualTreeView.SetFill(const value: TBrush);
begin
  FFill.Assign(value);
end;

procedure TQVirtualTreeView.SetFocusColumn(const value: Integer);
begin
  if FFocusColumn <> value then
  begin
    FFocusColumn := value;
    Invalidate;
  end;
end;

procedure TQVirtualTreeView.SetFocusNode(const value: TQVTNode);
begin
  if FFocusNode <> value then
  begin
    if Assigned(value) then
      value.SetFocus
    else
    begin
      FocusChanging(nil, FocusColumn);
      FFocusNode := nil;
      FocusChanged;
    end;
  end;
end;

procedure TQVirtualTreeView.SetHeader(const value: TQVTHeader);
begin
  if Assigned(value) then
    FHeader.Assign(value)
  else
    FHeader.Columns.Clear;
end;

procedure TQVirtualTreeView.SetPaintOptions(const value: TQVTPaintOptions);
begin
  if FPaintOptions <> value then
  begin
    FPaintOptions := value;
    NodeContentChanged;
  end;
end;

procedure TQVirtualTreeView.SetRootNodeCount(const value: Integer);
begin
  if RootNode.ChildCount <> value then
  begin
    RootNode.ChildCount := value;
    RootNode.States := [TQVTNodeState.nsInitialized,
      TQVTNodeState.nsHasChildren, TQVTNodeState.nsExpanded];
  end;
end;

procedure TQVirtualTreeView.SetRowSpace(const value: Single);
begin
  if value <> FSpace.Y then
  begin
    if value > 0 then
      FSpace.Y := value
    else
      FSpace.Y := 0;
    AdjustAutoSizeColumn;
    NodeContentChanged;
  end;
end;

procedure TQVirtualTreeView.SetSpace(const value: TPointF);
begin
  if not FSpace.EqualsTo(value) then
  begin
    FSpace := value;
    Invalidate;
  end;
end;

procedure TQVirtualTreeView.SetStroke(const value: TStrokeBrush);
begin
  FStroke.Assign(value);
end;

{ TQVTColumn }

procedure TQVTColumn.Assign(src: TPersistent);

var
  ASource: TQVTColumn;
begin
  inherited;
  if src is TQVTColumn then
  begin
    ASource := TQVTColumn(src);
    FTitle.Assign(ASource.Title);
    FTextSettingsInfo.TextSettings.Assign(ASource.TextSettings);
    FFrozen := ASource.Frozen;
    FVisible := ASource.Visible;
    FEnabled := ASource.Enabled;
    FReadOnly := ASource.ReadOnly;
    TreeView.InvalidateColumn(Index);
  end;
end;

constructor TQVTColumn.Create(ACollection: TCollection);
begin
  inherited;
  FTitle := TQVTColumnTitle.Create(Self);
  FTitle._AddRef;
  FFrozen := false;
  FVisible := True;
  FEnabled := True;
  FReadOnly := false;
  FWidth := 75; // 默认大小
  FDrawerType := TQVTDrawerType.dtDefault;
  FSortIndex := -1;
  FTextSettingsInfo := TTextSettingsInfo.Create(Self,
    TreeView.GetTextSettingsClass);
end;

destructor TQVTColumn.Destroy;
begin
  FTitle._Release;
  FreeAndNil(FTextSettingsInfo);
  inherited;
end;

function TQVTColumn.ExtByName(const AName: String): IQVTNamedExt;
begin
  NeedExts;
  Result := FExts.ExtByName(AName);
end;

function TQVTColumn.ExtByType(const IID: TGUID; var AValue): Boolean;
begin
  NeedExts;
  Result := FExts.ExtByType(IID, AValue);
end;

function TQVTColumn.ExtByType(const AClass: TClass): TObject;
begin
  NeedExts;
  Result := FExts.ExtByType(AClass);
end;

function TQVTColumn.ExtByType(const AClass: TClass; var AValue): Boolean;
begin
  NeedExts;
  Result := FExts.ExtByType(AClass, AValue);
end;

function TQVTColumn.GetDrawer: IQVTDrawer;
begin
  if not Assigned(FDrawer) then
    Result := TreeView.GetCellDrawer(nil, Index);
  Result := FDrawer;
end;

function TQVTColumn.GetExts: TList<IInterface>;
begin
  NeedExts;
  Result := FExts.Exts;
end;

function TQVTColumn.GetFixedWidth: Single;
begin
  if SameValue(FMinWidth, FMaxWidth) then
    Result := FMinWidth
  else
    Result := 0;
end;

function TQVTColumn.GetTextSettings: TTextSettings;
begin
  Result := FTextSettingsInfo.TextSettings;
end;

function TQVTColumn.GetTreeView: TQVirtualTreeView;
begin
  Result := ((Collection as TQVTColumns).Owner as TQVTHeader).TreeView;
end;

function TQVTColumn.HasExts: Boolean;
begin
  Result := Assigned(FExts) and FExts.HasExts;
end;

procedure TQVTColumn.NeedExts;
begin
  if not Assigned(FExts) then
    FExts := TQVTExtendableObject.Create;
end;

function TQVTColumn.QueryInterface(const IID: TGUID; out Obj): HResult;
begin
  if GetInterface(IID, Obj) then
    Result := S_OK
  else if Assigned(FExts) then
    Result := FExts.QueryInterface(IID, Obj)
  else
    Result := E_NOINTERFACE;
end;

procedure TQVTColumn.SetDrawerType(const value: TQVTDrawerType);
begin
  if FDrawerType <> value then
  begin
    FDrawerType := value;
    FDrawer := nil;
  end;
end;

procedure TQVTColumn.SetEnabled(value: Boolean);
begin
  FEnabled := value;
  if not value then
    TreeView.CheckForBrowseMode(Self);
end;

procedure TQVTColumn.SetFixedWidth(const value: Single);
begin
  if not IsZero(value) then
  begin
    FMinWidth := value;
    FMaxWidth := value;
    Width := value;
  end;
end;

procedure TQVTColumn.SetFrozen(const value: Boolean);
begin
  FFrozen := value;
end;

procedure TQVTColumn.SetMaxWidth(const value: Single);
begin
  if not SameValue(FMaxWidth, value) then
  begin
    FMaxWidth := value;
    if (value > 0) and (FMaxWidth < Width) then
      Width := MaxWidth;
  end;
end;

procedure TQVTColumn.SetMinWidth(const value: Single);
begin
  if not SameValue(FMinWidth, value) then
  begin
    FMinWidth := value;
    if (value > 0) and (FMinWidth > value) then
      Width := FMinWidth;
  end;
end;

procedure TQVTColumn.SetReadOnly(value: Boolean);
begin
  FReadOnly := value;
  if value then
    TreeView.CheckForBrowseMode(Self);
end;

procedure TQVTColumn.SetSortIndex(const value: Integer);
begin
  if FSortIndex <> value then
  begin
    if value < 0 then
      TreeView.SortColumns.Remove(Self)
    else
    begin
      if FSortIndex >= 0 then
        TreeView.SortColumns.Delete(FSortIndex);
      TreeView.SortColumns.Insert(value, Self);
    end;
  end;
end;

procedure TQVTColumn.SetTextSettings(const value: TTextSettings);
begin
  FTextSettingsInfo.TextSettings.Assign(value);
  TreeView.InvalidateColumn(Index);
end;

procedure TQVTColumn.SetTitle(const ATitle: TQVTColumnTitle);
begin
  FTitle.Assign(ATitle);
end;

procedure TQVTColumn.SetVisible(value: Boolean);
begin
  if FVisible <> value then
  begin
    FVisible := value;
    TreeView.Invalidate;
  end;
end;

procedure TQVTColumn.SetWidth(const value: Single);
begin
  if not SameValue(FWidth, value) then
  begin
    if value >= MinWidth then
    begin
      if (value <= MaxWidth) or IsZero(MaxWidth) then
        FWidth := value
      else
        FWidth := MaxWidth;
    end
    else
      FWidth := MinWidth;
    if Visible then
      TreeView.NodeContentChanged;
  end;
end;

function TQVTColumn._AddRef: Integer;
begin
  Result := -1;
end;

function TQVTColumn._Release: Integer;
begin
  Result := -1;
end;

{ TQVTColumns }

function TQVTColumns.Add: TQVTColumn;
begin
  Result := inherited Add as TQVTColumn;
  if Result.Index = Result.TreeView.Header.AutoSizeColumn then
  begin
    with TreeView do
    begin
      AdjustAutoSizeColumn;
      NodeContentChanged;
    end;
  end;
end;

constructor TQVTColumns.Create(AOwner: TPersistent);
begin
  inherited Create(AOwner, TQVTColumn);
end;

function TQVTColumns.GetAttr(Index: Integer): string;
begin
  case Index of
    0:
      Result := 'Id';
    1:
      Result := 'Title';
  end;
end;

function TQVTColumns.GetAttrCount: Integer;
begin
  Result := 2;
end;

function TQVTColumns.GetItemAttr(Index, ItemIndex: Integer): string;
begin
  case Index of
    0:
      Result := IntToStr(ItemIndex);
    // Id 在运行时实际上对应的就是创建时的只增的索引顺序，在设计时为了呈现最终结果，直接用ItemIndex代表
    1:
      Result := Items[ItemIndex].Title.Text;
  end;
end;

function TQVTColumns.GetItems(const AIndex: Integer): TQVTColumn;
begin
  Result := GetItem(AIndex) as TQVTColumn;
end;

function TQVTColumns.GetTreeView: TQVirtualTreeView;
begin
  Result := (Owner as TQVTHeader).TreeView;
end;

procedure TQVTColumns.Update(Item: TCollectionItem);
begin
  inherited;
  TreeView.NodeContentChanged;
end;

{ TQVTNode }

function TQVTNode.AddChild: TQVTNode;
begin
  NeedInitialized;
  GetLastChild;
  Result := TreeView.CreateNode;
  Result.FParent := Self;
  Result.FPrior := FLastChild;
  Result.FIndex := FCount;
  if Assigned(FLastChild) then
    FLastChild.FNext := Result;
  FStates := FStates + [TQVTNodeState.nsHasChildren];
  Result._AddRef;
  FLastInitChild := Result;
  Result.NeedInitialized;
  if not Assigned(FFirstChild) then
    FFirstChild := Result;
  FLastChild := Result;
  Inc(FCreatedCount);
  Inc(FCount);
  if TQVTNodeState.nsExpanded in FStates then
    TreeView.NodeContentChanged;
end;

procedure TQVTNode.Cascade;
begin
  if HasChildren then
  begin
    InitChildren;
    FStates := FStates - [TQVTNodeState.nsExpanded];
    TreeView.NodeContentChanged;
  end;
end;

procedure TQVTNode.CleanDirty(ANode: TQVTNode);

var
  AIndex: Integer;
begin
  if Assigned(FFirstDirtyChild) then
  begin
    if Assigned(FFirstDirtyChild.FPrior) then
      AIndex := FFirstDirtyChild.FPrior.FIndex + 1
    else
      AIndex := 0;
    while Assigned(FFirstDirtyChild) do
    begin
      FFirstDirtyChild.FIndex := AIndex;
      if FFirstDirtyChild = ANode then
      begin
        FFirstDirtyChild := FFirstDirtyChild.Next;
        Break;
      end
      else
      begin
        FFirstDirtyChild := FFirstDirtyChild.Next;;
        Inc(AIndex);
      end;
    end;
  end;
end;

procedure TQVTNode.Clear;
var
  ANext: TQVTNode;
begin
  FCount := 0;
  while Assigned(FFirstChild) do
  begin
    ANext := FFirstChild.FNext;
    FFirstChild._Release;
    FFirstChild := ANext;
  end;
  FLastChild := nil;
  FLastInitChild := nil;
  FFirstDirtyChild := nil;
  FCount := 0;
  FCreatedCount := 0;
  FStates := FStates - [TQVTNodeState.nsHasChildren];
  if Self = TreeView.RootNode then
    TreeView.FFirstVisibleNode := nil;
  TreeView.NodeContentChanged;
end;

constructor TQVTNode.Create(AOwner: TQVirtualTreeView);
begin
  inherited Create;
  FTreeView := AOwner;
  FCount := -1;
  FLevel := -1;
  FRowIndex := -1;
  FHeight := -1;
  FIndex := -1;
  FStates := [TQVTNodeState.nsVisible];
end;

procedure TQVTNode.Delete;

var
  ANext: TQVTNode;
begin
  ANext := Next;
  FParent.Dirty(ANext);
  if Assigned(FPrior) then
    Pointer(FPrior.FNext) := Next;
  if Assigned(ANext) then
    Pointer(ANext.FPrior) := Prior;
  if RowIndex > 0 then
    TreeView.RowDirty(RowIndex);
  if Assigned(FParent) then
  begin
    Dec(FParent.FCount);
    Dec(FParent.FCreatedCount);
    if FParent.FCount = 0 then
      FParent.States := FParent.States - [nsHasChildren];
    if FParent.FFirstChild = Self then
      FParent.FFirstChild := ANext;
    if FParent.FLastChild = Self then
      FParent.FLastChild := FPrior;
    if FParent.FLastInitChild = Self then
      FParent.FLastInitChild := FPrior;
    if FParent.FFirstDirtyChild = Self then
      FParent.FFirstDirtyChild := ANext;
  end;
  if FTreeView.FFirstVisibleNode = Self then
    FTreeView.FFirstVisibleNode := nil;
  TreeView.NodeContentChanged;
  if FTreeView.FocusNode = Self then
  begin
    if Assigned(ANext) then
      FTreeView.FocusNode := ANext
    else if Assigned(FPrior) then
      FTreeView.FocusNode := FPrior
    else if FParent <> FTreeView.RootNode then // 自己是唯一子结点了
      FTreeView.FocusNode := FParent
    else
      FTreeView.FocusNode := nil;
  end;
  if FTreeView.HoverNode = Self then
    FTreeView.FHoverNode := nil;
  if FTreeView.FEditingNode = Self then
    FTreeView.CancelEdit;
  if FTreeView.FMouseDownNode = Self then
    FTreeView.FMouseDownNode := nil;
  if FTreeView.FSizingNode = Self then
    FTreeView.FSizingNode := nil;
  _Release;
end;

destructor TQVTNode.Destroy;
begin
  Clear;
  Pointer(FParent) := nil;
  Pointer(FNext) := nil;
  Pointer(FPrior) := nil;
  Pointer(FTreeView) := nil;
  inherited;
end;

procedure TQVTNode.Dirty(ANode: TQVTNode);
begin
  if Assigned(ANode) then
  begin
    if not Assigned(FFirstDirtyChild) then
      FFirstDirtyChild := ANode
    else if ANode.FIndex < FFirstDirtyChild.FIndex then
      FFirstDirtyChild := ANode;
  end;
end;

procedure TQVTNode.Expand(const ANest: Boolean);

var
  AChild: TQVTNode;
begin
  if HasChildren then
  begin
    InitChildren;
    FStates := FStates + [TQVTNodeState.nsExpanded];
    if ANest then
    begin
      AChild := GetFirstVisibleChild;
      while Assigned(AChild) do
      begin
        AChild.Expand(ANest);
        AChild := GetNextVisibleChild(AChild);
      end;
    end;
    TreeView.NodeContentChanged;
  end;
end;

function TQVTNode.GetCanFocus: Boolean;

var
  AParent: TQVTNode;
begin
  Result := TQVTNodeState.nsVisible in FStates;
  if Result then
  begin
    AParent := Parent;
    while Assigned(AParent) and (AParent <> TreeView.RootNode) do
    begin
      if not(TQVTNodeState.nsVisible in AParent.FStates) then
      begin
        Result := false;
        Exit;
      end;
      AParent := AParent.Parent;
    end;
  end;
end;

function TQVTNode.GetCellData(const AIndex: Integer): IQVTCellData;
begin
  Result := TreeView.GetCellData(Self, AIndex);
end;

function TQVTNode.GetCellDrawer(const AIndex: Integer): IQVTDrawer;
begin
  Result := TreeView.GetCellDrawer(Self, AIndex);
end;

function TQVTNode.GetCellRect(AColumn: Integer): TRectF;
begin
  Result := TreeView.GetCellRect(Self, AColumn);
end;

function TQVTNode.GetChildCount: Integer;
begin
  if FCount < 0 then
  begin
    Result := TreeView.GetChildCount(Self);
    FCount := Result;
  end;
  Result := FCount;
end;

function TQVTNode.GetDisplayRect: TRectF;
begin
  Result := TreeView.DisplayRect[Self];
end;

function TQVTNode.GetFirstChild: TQVTNode;
begin
  NeedInitialized;
  // 如果有子结点
  if (TQVTNodeState.nsHasChildren in FStates) then
  begin
    // 检查第一个子结点是否赋值了
    if (not Assigned(FFirstChild)) and (FCount > 0) then
    begin
      Pointer(FFirstChild) := TreeView.CreateNode;
      FFirstChild.FIndex := 0;
      Pointer(FFirstChild.FParent) := Self;
      FFirstChild.FRowIndex := RowIndex + 1;
      FFirstChild._AddRef;
      Pointer(FLastInitChild) := FFirstChild;
      FCreatedCount := 1;
      if FCount = 1 then // 只有一个时，也同时是尾结点
        Pointer(FLastChild) := FFirstChild;
    end;
  end;
  Result := FFirstChild;
end;

function TQVTNode.GetFirstChildData: IQVTNodeData;
begin
  Result := GetFirstChild as IQVTNodeData;
end;

function TQVTNode.GetFirstVisibleChild: TQVTNode;
begin
  Result := GetFirstChild;
  while Assigned(Result) and (not(TQVTNodeState.nsVisible in Result.FStates)) do
    Result := Result.GetNext;
end;

function TQVTNode.GetHeight: Single;
begin
  if FHeight < 0 then
    Result := TreeView.DefaultRowHeight
  else
    Result := FHeight;
end;

function TQVTNode.GetIndex: Integer;
begin
  if Assigned(FParent) then
    FParent.CleanDirty(Self);
  Result := FIndex;
end;

function TQVTNode.GetIsExpanded: Boolean;
begin
  Result := TQVTNodeState.nsExpanded in States;
end;

function TQVTNode.GetIsFirstChild: Boolean;
begin
  Result := (FParent.GetFirstChild = Self);
end;

function TQVTNode.GetIsLastChild: Boolean;
begin
  Result := (FParent.GetLastChild = Self);
end;

function TQVTNode.GetIsRoot: Boolean;
begin
  Result := TreeView.RootNode = Self;
end;

function TQVTNode.GetLastChild: TQVTNode;

var
  ANext: TQVTNode;
begin
  NeedInitialized;
  InitChildren;
  // 如果有子结点
  if (TQVTNodeState.nsHasChildren in FStates) then
  begin
    // 检查第后一个子结点是否赋值了
    if not Assigned(FLastChild) then
    begin
      if not Assigned(FLastInitChild) then
        Pointer(FLastInitChild) := GetFirstChild as TQVTNode;
      if Assigned(FLastInitChild) then
      begin
        // 从最后一个初始化的结点开，将中间的结点都初始
        while not Assigned(FLastChild) do
        begin
          ANext := FLastInitChild.GetNext;
          ANext.NeedInitialized;
          FLastInitChild := ANext;
        end;
      end;
    end;
  end;
  Result := FLastChild;
end;

function TQVTNode.GetLastChildData: IQVTNodeData;
begin
  Result := GetLastChild as IQVTNodeData;
end;

function TQVTNode.GetLastVisibleChild: TQVTNode;
begin
  Result := GetLastChild;
  while Assigned(Result) and (not(TQVTNodeState.nsVisible in Result.FStates)) do
    Result := Result.Prior;
end;

function TQVTNode.GetLevel: Integer;

var
  AParent: TQVTNode;
begin
  if (FLevel < 0) or (FLevelDirtyCounter < TreeView.FLevelDirtyCounter) then
  begin
    AParent := Self;
    FLevel := 0;
    while Assigned(AParent) and (AParent <> TreeView.RootNode) do
    begin
      AParent := AParent.Parent;
      Inc(FLevel);
    end;
    // 记录下末次级别可能变更的计数，这个计数器在每调整一次树结点级别时加1，可以用来区分是否能使用缓存的Level
    FLevelDirtyCounter := TreeView.FLevelDirtyCounter;
  end;
  Result := FLevel;
end;

function TQVTNode.GetNext: TQVTNode;
begin
  if not Assigned(FNext) then
  begin
    if Assigned(FParent) then
    begin
      if FParent.FCreatedCount < FParent.FCount then
      begin
        Pointer(FNext) := TreeView.CreateNode;
        FNext._AddRef;
        Pointer(FNext.FPrior) := Self;
        Pointer(FNext.FParent) := FParent;
        FNext.FIndex := FIndex + 1;
        if Assigned(FParent) then
          Pointer(FParent.FLastInitChild) := FNext;
        Inc(FParent.FCreatedCount);
        if FParent.FCreatedCount = FParent.FCount then
          Pointer(FParent.FLastChild) := FNext;
      end;
    end;
  end;
  Result := FNext;
end;

function TQVTNode.GetNextData: IQVTNodeData;
begin
  Result := GetNext as IQVTNodeData;
end;

function TQVTNode.GetNextVisibleChild(AChild: TQVTNode): TQVTNode;
begin
  Result := AChild.GetNext;
  while Assigned(Result) and (not(TQVTNodeState.nsVisible in Result.FStates)) do
    Result := Result.GetNext;
end;

function TQVTNode.GetParent: TQVTNode;
begin
  Result := FParent;
end;

function TQVTNode.GetPrior: TQVTNode;
begin
  Result := FPrior;
end;

function TQVTNode.GetPriorData: IQVTNodeData;
begin
  Result := FPrior;
end;

function TQVTNode.GetPriorVisible(AChild: TQVTNode): TQVTNode;
begin
  Result := AChild.FPrior;
  while Assigned(Result) and (not(TQVTNodeState.nsVisible in Result.FStates)) do
    Result := Result.FPrior;
end;

{ RowIndex要求从第一个子结点到当前结点都是已知的，是一种开销比较大的操作，慎用 }
function TQVTNode.GetRowIndex: Integer;
begin
  Result := FRowIndex;
end;

function TQVTNode.GetStates: TQVTNodeStates;
begin
  Result := FStates;
end;

function TQVTNode.HasChildren: Boolean;
begin
  Result := TQVTNodeState.nsHasChildren in FStates;
end;

procedure TQVTNode.InitChildren;
begin
  if FCount < 0 then
  begin
    if Assigned(TreeView.FOnInitChildren) then
      TreeView.FOnInitChildren(TreeView, Self);
    if FCount < 0 then
    begin
      FCount := 0;
      FStates := FStates - [TQVTNodeState.nsHasChildren];
    end;
  end;
end;

function TQVTNode.Insert(APos: TNodeInsertPosition): TQVTNode;
begin
  if APos <> ipNoWhere then
  begin
    Result := TreeView.CreateNode;
    Result._AddRef;
    Result.MoveTo(Self, APos);
  end
  else
    Result := nil;
end;

function TQVTNode.IsChildOf(ANode: TQVTNode): Boolean;
var
  AParent: TQVTNode;
begin
  AParent := FParent;
  Result := false;
  while Assigned(AParent) do
  begin
    if AParent = ANode then
    begin
      Result := True;
      Exit;
    end;
    AParent := AParent.Parent;
  end;
end;

function TQVTNode.IsParentOf(ANode: TQVTNode): Boolean;
begin
  Result := ANode.IsChildOf(Self);
end;

procedure TQVTNode.MoveTo(ATarget: TQVTNode; AMode: TNodeInsertPosition);
begin
  // 首先判断下，根结点只有一个，所以不能做邻居
  if (ATarget = TreeView.RootNode) and (AMode in [ipBefore, ipAfter]) then
    raise Exception.Create(SCantAddRootNodeSibling);
  // 其次判断下，自己不能给自己的后代当孙子和同辈
  if ATarget.IsChildOf(Self) and (AMode <> ipNoWhere) then
    raise Exception.Create(SCantAddToChild);
  if ATarget = Self then
    raise Exception.Create(SCantAddToSelf);
  // 第一步：摘空，将自己从父结点中移除掉
  if Assigned(FParent) then
  begin
    if FParent.FFirstDirtyChild = Self then
      FParent.FFirstDirtyChild := FNext;
    FParent.Dirty(Next);
    if not Assigned(FNext) then
      GetNext;
    if Assigned(FPrior) then
      FPrior.FNext := FNext
    else
      FParent.FFirstChild := FNext;
    if Assigned(FNext) then
      FNext.FPrior := FPrior
    else
      FParent.FLastChild := FPrior;
    Dec(FParent.FCreatedCount);
    Dec(FParent.FCount);
    if FParent.FCount = 0 then
      FParent.FStates := FParent.FStates - [TQVTNodeState.nsHasChildren];
  end;
  FLevel := -1;
  // 第二步：摘干净后挪到新目标位置
  case AMode of
    ipBefore:
      begin
        FParent := ATarget.FParent;
        FPrior := ATarget.Prior;
        FNext := ATarget;
        FIndex := ATarget.FIndex;
        if Assigned(FPrior) then
          FPrior.FNext := Self
        else
          FParent.FFirstChild := Self;
        ATarget.FPrior := Self;
        FParent.Dirty(ATarget);
      end;
    ipAfter:
      begin
        FParent := ATarget.FParent;
        FPrior := ATarget;
        FNext := ATarget.GetNext;
        ATarget.FNext := Self;
        FIndex := ATarget.FIndex + 1;
        if not Assigned(FNext) then
          FParent.FLastChild := Self;
        FParent.Dirty(Self);
      end;
    ipFirstChild:
      begin
        FParent := ATarget;
        FNext := ATarget.GetFirstChild;
        FPrior := nil;
        FIndex := 0;
        if Assigned(ATarget.FFirstChild) then
          ATarget.FFirstChild.FPrior := Self;
        ATarget.FFirstChild := Self;
        ATarget.Dirty(Self);
        if not Assigned(FNext) then
          ATarget.FLastChild := Self;
      end;
    ipLastChild:
      begin
        FParent := ATarget;
        FPrior := ATarget.GetLastChild;
        FNext := nil;
        FIndex := ATarget.FCount;
        if Assigned(ATarget.FLastChild) then
          ATarget.FLastChild.FNext := Self;
        if not Assigned(FPrior) then
          ATarget.FFirstChild := Self;
        ATarget.FLastChild := Self;
      end;
  end;
  FParent.FStates := FParent.FStates + [TQVTNodeState.nsHasChildren];
  Inc(FParent.FCreatedCount);
  Inc(FParent.FCount);
  TreeView.FFirstVisibleNode := nil;
  TreeView.NodeContentChanged;
end;

procedure TQVTNode.NeedInitialized;
begin
  if not(TQVTNodeState.nsInitialized in FStates) then
    TreeView.InitNode(Self);
end;

procedure TQVTNode.Reinit(ANest: Boolean);
var
  AExpanded: Boolean;
begin
  if IsRoot then
    ReinitChildren(ANest)
  else
  begin
    if HasExts then
      Exts.Clear;
    AExpanded := TQVTNodeState.nsExpanded in FStates;
    FStates := [TQVTNodeState.nsVisible];
    NeedInitialized;
    ReinitChildren(ANest);
    if AExpanded and HasChildren then
      FStates := FStates + [TQVTNodeState.nsExpanded];
  end;
end;

procedure TQVTNode.ReinitChildren(ANest: Boolean);
var
  ALastCount: Integer;
  APrior: TQVTNode;
begin
  ALastCount := FCount;
  if Assigned(TreeView.OnInitChildren) then
  begin
    FCount := -1;
    InitChildren;
  end;
  while (ALastCount > FCount) and Assigned(FLastChild) do
  begin
    APrior := FLastChild.Prior;
    FLastChild.Delete;
    FLastChild := APrior;
    Dec(ALastCount);
  end;
  APrior := FLastChild;
  while Assigned(APrior) do
  begin
    if TQVTNodeState.nsInitialized in APrior.States then // 如果已经初始化
      APrior.Reinit(ANest);
    APrior := APrior.Prior;
  end;
  if FCount = 0 then
    FFirstChild := nil
  else
    FStates := FStates + [TQVTNodeState.nsHasChildren];
  TreeView.NodeContentChanged;
end;

procedure TQVTNode.ScrollToView;
begin
  TreeView.MakeNodeVisible(Self);
end;

procedure TQVTNode.SetChildCount(const value: Integer);

var
  AChild, ANext: TQVTNode;
  I: Integer;
  ALastInitChildReserved: Boolean;
begin
  if (FCount <> value) and (value >= 0) then
  begin
    if FCount < value then
    // 如果新的子结点数量增大，则末个结点变空，以便后续初始化
    begin
      Pointer(FLastChild) := nil;
      FCount := value;
    end
    else
    // FCount>Value，需要删除多余的子结点
    begin
      AChild := FFirstChild;
      I := 0;
      FCreatedCount := value;
      FCount := value;
      ALastInitChildReserved := false;
      while Assigned(AChild) and (I < value) do
      begin
        if AChild = FLastInitChild then
          ALastInitChildReserved := True;
        AChild.FIndex := I;
        AChild := AChild.Next;
        Inc(I);
      end;
      if Assigned(AChild) then
      begin
        Pointer(FFirstDirtyChild) := nil;
        if Assigned(AChild.Prior) then
        begin
          Pointer(AChild.Prior.FNext) := nil;
          FLastChild := AChild.Prior;
          if not ALastInitChildReserved then
            FLastInitChild := FLastChild;
        end
        else
        begin
          FFirstChild := nil;
          FLastChild := nil;
          FLastInitChild := nil;
        end;
        // 释放掉多余的结点
        while Assigned(AChild) do
        begin
          ANext := AChild.FNext;
          Pointer(AChild.FNext) := nil;
          if Assigned(ANext) then
            Pointer(ANext.FPrior) := nil;
          AChild._Release;
          AChild := ANext;
        end;
      end;
    end;
    if value > 0 then
      FStates := FStates + [TQVTNodeState.nsHasChildren]
    else
      FStates := FStates - [TQVTNodeState.nsHasChildren];
    if Self = TreeView.RootNode then
      TreeView.FFirstVisibleNode := nil;
    TreeView.NodeContentChanged;
  end;
end;

procedure TQVTNode.SetFocus;

var
  AParent: TQVTNode;
  AContentChanged: Boolean;
begin
  NeedInitialized;
  if CanFocus then
  begin
    // Expand all parent
    AParent := Parent;
    AContentChanged := false;
    while Assigned(AParent) do
    begin
      if not(TQVTNodeState.nsExpanded in AParent.FStates) then
      begin
        AContentChanged := True;
        AParent.FStates := AParent.FStates + [TQVTNodeState.nsExpanded];
      end;
      AParent := AParent.FParent;
    end;
    FStates := FStates + [nsSelected];
    with TreeView do
    begin
      FocusChanging(Self, TreeView.FocusColumn);
      if Assigned(FFocusNode) then
        FFocusNode.States := FFocusNode.States - [nsSelected];
      FFocusNode := Self;
      FocusChanged;
      if AContentChanged then
        NodeContentChanged;
    end;
    ScrollToView;
  end;
end;

// 加限制最小最大高度
procedure TQVTNode.SetHeight(const value: Single);
begin
  if not SameValue(value, FHeight) then
  begin
    if value >= FMinHeight then
    begin
      if (value < FMaxHeight) or IsZero(FMaxHeight) then
      begin
        FHeight := value;
        if TQVTNodeState.nsVisible in FStates then
          TreeView.NodeContentChanged;
      end;
    end;
  end;
end;

procedure TQVTNode.SetIsExpanded(const value: Boolean);
begin
  if value then
    Expand
  else
    Cascade;
end;

procedure TQVTNode.SetMaxHeight(const value: Single);
begin
  if not SameValue(value, FMaxHeight) then
  begin
    if value >= 0 then
    begin
      FMaxHeight := value;
      if (value > 0) and (Height > FMaxHeight) then
        Height := MaxHeight;
    end
    else
      FMaxHeight := 0;
  end;
end;

procedure TQVTNode.SetMinHeight(const value: Single);
begin
  if not SameValue(value, FMinHeight) then
  begin
    if value >= 0 then
    begin
      FMinHeight := value;
      if (value > 0) and (Height < FMinHeight) then
        Height := FMinHeight;
    end
    else
      FMinHeight := 0;
  end;
end;

procedure TQVTNode.SetStates(const value: TQVTNodeStates);
begin
  if FStates <> value then
  begin
    if ([TQVTNodeState.nsVisible, TQVTNodeState.nsExpanded] * FStates) <>
      ([TQVTNodeState.nsVisible, TQVTNodeState.nsExpanded] * value) then
      TreeView.NodeContentChanged;
    FStates := value;
  end;
end;

{ TQVTTextDrawer }

function TQVTTextDrawer.ColorWithOpacity(AColor: TAlphaColor; AOpacity: Single)
  : TAlphaColor;
var
  C: TAlphaColorRec absolute AColor;
begin
  C.A := Trunc(C.A * AOpacity);
  Result := C.Color;
end;

procedure TQVTTextDrawer.Draw(ARect: TRectF; AData: IQVTCellData);
var
  ATextData: IQVTTextCellData;
  ATreeView: TQVirtualTreeView;
  ATextSettings: TTextSettings;
  ADrawable: IQVTTextDrawable;
begin
  ATreeView := AData.TreeView;
  if Supports(AData, IQVTTextCellData, ATextData) then
  begin
    if Supports(AData, IQVTTextDrawable, ADrawable) then
    begin
      ATextSettings := ADrawable.TextSettings;
      if not Assigned(ATextSettings) then
        ATextSettings := ATreeView.TextSettings;
      if ADrawable.Fill <> ATreeView.ActiveFill then
        ATreeView.Canvas.FillRect(ARect, 0, 0, [], ATreeView.Opacity,
          ADrawable.Fill);
      DrawText(ARect, ATextData, ATextSettings);
    end
    else
    begin
      ATextSettings := ATreeView.TextSettings;
      DrawText(ARect, ATextData, ATextSettings);
    end;
  end;
end;

procedure TQVTTextDrawer.DrawText(ARect: TRectF; ATextData: IQVTTextCellData;
  ATextSettings: TTextSettings);
begin
  DrawText(ATextData.TreeView, ARect, ATextData.Text, ATextSettings,
    ATextData.Enabled);
end;

procedure TQVTTextDrawer.DrawText(ATreeView: TQVirtualTreeView; ARect: TRectF;
  AText: String; ATextSettings: TTextSettings; AEnabled: Boolean);
begin
  FTextRect := ARect;
  with ATreeView.FTextLayout do
  begin
    BeginUpdate;
    TopLeft := ARect.TopLeft;
    MaxSize := PointF(ARect.Width, ARect.Height);
    Text := AText;
    WordWrap := ATextSettings.WordWrap;
    Opacity := Opacity;
    HorizontalAlign := ATextSettings.HorzAlign;
    VerticalAlign := ATextSettings.VertAlign;
    Font := ATextSettings.Font;
    if AEnabled then
      Color := ColorWithOpacity(ATextSettings.FontColor, ATreeView.Opacity)
    else
      Color := ColorWithOpacity(TAlphaColors.Gray, ATreeView.Opacity);
    RightToLeft := false;
    if ARect.Height - 4 > (Font.Size * 4 / 3) then
      Padding.Rect := Rect(2, 2, 2, 2)
    else
      Padding.Rect := Rect(2, 0, 2, 0);
    // 不支持从右到左阅读TFillTextFlag.RightToLeft in ATextSettings.;
    EndUpdate;
    RenderLayout(ATreeView.Canvas);
  end;
end;

function TQVTTextDrawer.GetFill(AData: IQVTCellData;
  AllowNull: Boolean): TBrush;
var
  ADrawable: IQVTDrawable;
begin
  if Supports(AData, IQVTDrawable, ADrawable) then
    Result := ADrawable.Fill
  else
    Result := nil;
  if not Assigned(Result) then
  begin
    if not AllowNull then
      Result := AData.TreeView.ActiveFill;
  end;
end;

function TQVTTextDrawer.GetStroke(AData: IQVTCellData; AllowNull: Boolean)
  : TStrokeBrush;

var
  ADrawable: IQVTDrawable;
begin
  if Supports(AData, IQVTDrawable, ADrawable) then
    Result := ADrawable.Stroke
  else
    Result := nil;
  if not Assigned(Result) then
  begin
    if not AllowNull then
      Result := AData.TreeView.Stroke;
  end;
end;

function TQVTTextDrawer.GetTextSettings(AData: IQVTCellData; AllowNull: Boolean)
  : TTextSettings;

var
  ADrawable: IQVTTextDrawable;
begin
  if Supports(AData, IQVTTextDrawable, ADrawable) then
    Result := ADrawable.TextSettings
  else
    Result := nil;
  if not Assigned(Result) then
  begin
    if not AllowNull then
      Result := AData.TreeView.TextSettings;
  end;
end;

{ TQVTProgressDrawer }

procedure TQVTProgressDrawer.Draw(ARect: TRectF; AData: IQVTCellData);

var
  ATreeView: TQVirtualTreeView;
  AProgress: IQVTProgressCellData;
  ATextData: IQVTTextCellData;
  AFill: TBrush;
  AStroke: TStrokeBrush;
  ATextSettings, ASourceSettings: TTextSettings;
  R: TRectF;
  PW: Single;
  AText: String;
  function CalcTextColor(AColor: TAlphaColor): TAlphaColor;

  var
    C: TAlphaColorRec absolute AColor;
    f: TAlphaColorRec;
    R: TAlphaColorRec absolute Result;
  begin
    f.Color := ATreeView.Fill.Color;
    R.R := (f.R + C.R) shr 1;
    R.G := (f.G + C.G) shr 1;
    R.B := (f.B + C.B) shr 1;
    R.A := C.A;
  end;

begin
  ATreeView := AData.TreeView;
  if Supports(AData, IQVTProgressCellData, AProgress) then
  begin
    AFill := GetFill(AData, True);
    if not Assigned(AFill) then
    begin
      AFill := ATreeView.Canvas.Fill;
      AFill.Kind := TBrushKind.Solid;
      AFill.Color := ATreeView.TintColor;
    end;
    AStroke := GetStroke(AData, True);
    if not Assigned(AStroke) then
    begin
      AStroke := ATreeView.Canvas.Stroke;
      AStroke.Kind := TBrushKind.Solid;
      AStroke.Color := ATreeView.TintColor;
    end;
    R := ARect;
    R.Inflate(-2, -2);
    ATreeView.Canvas.DrawRect(R.SnapToPixel(ATreeView.Canvas.Scale), 0, 0, [],
      ATreeView.Opacity, AStroke);
    R.Inflate(-2, -2);
    PW := R.Width * AProgress.GetProgress / 100;
    R.Right := R.Left + PW;
    ATreeView.Canvas.FillRect(R.SnapToPixel(ATreeView.Canvas.Scale, false), 0,
      0, [], ATreeView.Opacity, AStroke);
    if Supports(AData, IQVTTextCellData, ATextData) then
    begin
      ARect.Left := R.Left + 3;
      AText := ATextData.Text;
      ASourceSettings := GetTextSettings(AData, false);
      ATextSettings := TTextSettingsClass(ASourceSettings.ClassType)
        .Create(nil);
      try
        ATextSettings.Assign(ASourceSettings);
        ATextSettings.FontColor := CalcTextColor(ATextSettings.FontColor);
        DrawText(ARect, ATextData, ATextSettings);
      finally
        FreeAndNil(ATextSettings);
      end;
    end;
  end;
end;
{ TQVTMasterDrawer }

class constructor TQVTMasterDrawer.Create;
begin
  FStatePath[false] := nil;
  FStatePath[True] := nil;
end;

class destructor TQVTMasterDrawer.Destroy;
begin
  if Assigned(FStatePath[false]) then
    FreeAndNil(FStatePath[false]);
  if Assigned(FStatePath[True]) then
    FreeAndNil(FStatePath[True]);
end;

destructor TQVTMasterDrawer.Destroy;
begin
  if Assigned(FCurrentPath[false]) then
    FreeAndNil(FCurrentPath[false]);
  if Assigned(FCurrentPath[True]) then
    FreeAndNil(FCurrentPath[True]);
end;

procedure TQVTMasterDrawer.Draw(ARect: TRectF; AData: IQVTCellData);

var
  ATreeView: TQVirtualTreeView;
  ANode: TQVTNode;
  R: TRectF;
  ACanvas: TCanvas;
  pt1, pt2, ct: TPointF;
  APaintButton, APaintTreeLine: Boolean;
  procedure DrawLeftLine(ALevelNode: TQVTNode);
  begin
    if ANode <> ATreeView.RootNode.GetFirstVisibleChild then
    begin
      pt1.Y := R.Top;
      // Todo:修正竖线连接问题
      // if (ALevelNode <> ATreeView.FFirstVisibleNode) and (ALevelNode.Level > 1)
      // then
      // pt1.Y := pt1.Y - ATreeView.GetPriorVisible(ALevelNode).Height / 2;
    end
    else
      pt1.Y := (R.Top + R.Bottom) / 2;
    if (ALevelNode = ANode) or (ALevelNode.GetNext <> nil) then
    begin
      if ALevelNode.GetNext <> nil then
        pt2.Y := R.Bottom
      else
        pt2.Y := (R.Top + R.Bottom) / 2;
      pt1.X := ct.X - (ANode.Level - ALevelNode.Level) * ATreeView.NodeIndent;
      if pt1.X < R.Right then
      begin
        pt2.X := pt1.X;
        pt1 := pt1.SnapToPixel(ACanvas.Scale);
        pt2 := pt2.SnapToPixel(ACanvas.Scale);
        if not pt1.EqualsTo(pt2) then
          ACanvas.DrawLine(pt1, pt2, ATreeView.Opacity, ATreeView.FLineStyle);
      end;
    end;
    if ALevelNode.Level > 1 then
      DrawLeftLine(ALevelNode.Parent);
  end;
  procedure DefaultDrawButton;
  var
    APolygon: TPolygon;
    pt: TPointF;
    AButtonRect: TRectF;
    AColor: TAlphaColor;
  begin
    AColor := ATreeView.Fill.Color;
    if (ANode = ATreeView.HoverNode) and (AData.Column = ATreeView.FocusColumn)
      and (TQVTPaintOption.poHover in ATreeView.PaintOptions) then
      AColor := ATreeView.HoverColor;
    if ANode = ATreeView.FocusNode then
    begin
      if (TQVTPaintOption.poRowSelection in ATreeView.PaintOptions) or
        (([TQVTPaintOption.poColSelection, TQVTPaintOption.poCellSelection] *
        ATreeView.PaintOptions <> []) and (AData.Column = ATreeView.FocusColumn))
      then
        AColor := ATreeView.SelectionColor
    end;
    SetLength(APolygon, 3);
    pt := ct.SnapToPixel(ACanvas.Scale);
    if TQVTNodeState.nsExpanded in ANode.FStates then // 展开
    begin
      APolygon[0] := PointF(pt.X - ButtonSize, pt.Y);
      APolygon[1] := PointF(pt.X + ButtonSize, pt.Y);
      APolygon[2] := PointF(pt.X, pt.Y + ButtonSize);
      AButtonRect := RectF(pt.X - ButtonSize, pt.Y, pt.X + ButtonSize,
        pt.Y + ButtonSize);
    end
    else // 收缩
    begin
      APolygon[0] := PointF(pt.X - 1, pt.Y - ButtonSize);
      APolygon[1] := PointF(pt.X - 1, pt.Y + ButtonSize);
      APolygon[2] := PointF(pt.X - 1 + ButtonSize, pt.Y);
      AButtonRect := RectF(pt.X - 1, pt.Y - ButtonSize,
        pt.X + 1 + ButtonSize, pt.Y);
    end;
    ACanvas.ClearRect(ANode.FButtonRect, AColor);
    ACanvas.Fill.Assign(ATreeView.LineStyle);
    ACanvas.FillPolygon(APolygon, ATreeView.Opacity);
  end;
  procedure DrawButton;
  var
    AIsExpanded: Boolean;
  begin
    if APaintButton and ANode.HasChildren then
    begin
      ANode.FButtonRect := RectF(ct.X - 6.5, ct.Y - 6.5, ct.X + 6.5, ct.Y + 6);
      if ANode.FButtonRect.Right > R.Right then
        ANode.FButtonRect.Right := R.Right;
      if ANode.FButtonRect.Left < R.Right then
      begin
        R := ANode.FButtonRect.SnapToPixel(ACanvas.Scale);
        AIsExpanded := TQVTNodeState.nsExpanded in ANode.FStates;
        if Assigned(FStatePath[AIsExpanded]) then
        begin
          if not Assigned(FCurrentPath[AIsExpanded]) then
            FCurrentPath[AIsExpanded] := TPathData.Create;
        end;
        if Assigned(FCurrentPath[AIsExpanded]) then
        begin
          FCurrentPath[AIsExpanded].Assign(FStatePath[AIsExpanded]);
          if (Length(FCurrentPath[AIsExpanded].Data) > 0) then
          begin
            FCurrentPath[AIsExpanded].FitToRect(R);
            ATreeView.Canvas.Fill.Kind := TBrushKind.Solid;
            ATreeView.Canvas.Fill.Color := ATreeView.TintColor;
            ATreeView.Canvas.FillPath(FCurrentPath[AIsExpanded],
              ATreeView.Opacity);
          end
          else
            DefaultDrawButton;
        end
        else
          DefaultDrawButton;
      end
    end
    else
      ANode.FButtonRect := RectF(ct.X, ct.Y, ct.X, ct.Y);
  end;

begin
  // 绘制树形的线
  R := ARect;
  ATreeView := AData.TreeView;
  if TQVTPaintOption.poVertLine in ATreeView.PaintOptions then
    R.Left := R.Left + 2;
  ANode := AData.Node;
  ACanvas := ATreeView.Canvas;
  ct.X := R.Left + ATreeView.NodeIndent * (ANode.Level - 1) + 8;
  ct.Y := (R.Top + R.Bottom) / 2;
  APaintButton := (TQVTPaintOption.poNodeButton in ATreeView.PaintOptions);
  APaintTreeLine := TQVTPaintOption.poTreeLine in ATreeView.PaintOptions;
  if APaintTreeLine then
  begin
    // 绘制最左侧的|线
    DrawLeftLine(ANode);
    DrawButton;
    // 绘制连结到内容的连接线
    pt1.X := ANode.FButtonRect.Right + 2;
    pt1.Y := ct.Y;
    if pt1.X < ARect.Right then
    begin
      pt2.Y := pt1.Y;
      pt2.X := ct.X + ATreeView.NodeIndent - 2;
      if pt2.X > ARect.Right then
        pt2.X := ARect.Right;
      pt1 := pt1.SnapToPixel(ACanvas.Scale);
      pt2 := pt2.SnapToPixel(ACanvas.Scale);
      ACanvas.DrawLine(pt2, pt1, ATreeView.Opacity, ATreeView.FLineStyle);
    end;
  end
  else
    DrawButton;
  // 有空闲空间，绘制文本
  if APaintTreeLine then
    ARect.Left := ct.X + ATreeView.NodeIndent
  else if APaintButton then
    ARect.Left := ANode.FButtonRect.Right + 4
  else
    ARect.Left := ct.X - 4;
  if ARect.Left < ARect.Right then
  begin
    if Supports(AData, IQVTCheckCellData) then
      TQVirtualTreeView.DefaultDrawers[TQVTDrawerType.dtCheck]
        .Draw(ARect, AData)
    else if Supports(AData, IQVTRadioCellData) then
      TQVirtualTreeView.DefaultDrawers[TQVTDrawerType.dtRadio]
        .Draw(ARect, AData)
    else
      inherited;
  end;
end;

class function TQVTMasterDrawer.GetCascadedPath: TPathData;
begin
  if not Assigned(FStatePath[false]) then
    FStatePath[false] := TPathData.Create;
  Result := FStatePath[false];
end;

function TQVTMasterDrawer.GetEditorBounds(AData: IQVTCellData): TRectF;
var
  ATreeView: TQVirtualTreeView;
begin
  Result := inherited GetEditorBounds(AData);
  ATreeView := AData.TreeView;
  if TQVTPaintOption.poVertLine in ATreeView.PaintOptions then
    Result.Left := Result.Left + 2;
  Result.Left := Result.Left + ATreeView.NodeIndent *
    (AData.Node.Level - 1) + 8;
  if TQVTPaintOption.poTreeLine in ATreeView.PaintOptions then
    Result.Left := Result.Left + ATreeView.NodeIndent
  else if TQVTPaintOption.poNodeButton in ATreeView.PaintOptions then
    Result.Left := Result.Left + 10.5
  else
    Result.Left := Result.Left - 4;
end;

class function TQVTMasterDrawer.GetExpandedPath: TPathData;
begin
  if not Assigned(FStatePath[True]) then
    FStatePath[True] := TPathData.Create;
  Result := FStatePath[True];
end;

class procedure TQVTMasterDrawer.SetCascadedPath(const value: TPathData);
begin
  if Assigned(value) then
    CascadedPath.Data := value.Data
  else if Assigned(FStatePath[false]) then
    FStatePath[false].Data := '';
end;

class procedure TQVTMasterDrawer.SetExpandedPath(const value: TPathData);
begin
  if Assigned(value) then
    ExpandedPath.Data := value.Data
  else if Assigned(FStatePath[True]) then
    ExpandedPath.Data := '';
end;

{ TQVTDefaultCellData }

constructor TQVTDefaultCellData.Create(ANode: TQVTNode; AColIndex: Integer);
begin
  inherited Create;
  FNode := ANode;
  FColumn := AColIndex;
end;

constructor TQVTDefaultCellData.Create;
begin
  inherited;
end;

function TQVTDefaultCellData.GetColumn: Integer;
begin
  Result := FColumn;
end;

function TQVTDefaultCellData.GetColumnId: Integer;
begin
  if Assigned(FNode) then
    Result := FNode.TreeView.Header.Columns[Column].ID
  else
    Result := -1;
end;

function TQVTDefaultCellData.GetEnabled: Boolean;
begin
  Result := True;
end;

function TQVTDefaultCellData.GetNode: TQVTNode;
begin
  Result := FNode;
end;

function TQVTDefaultCellData.GetSides: TSides;
begin
  Result := [TSide.Top, TSide.Left, TSide.Right, TSide.Bottom];
end;

function TQVTDefaultCellData.GetTreeView: TQVirtualTreeView;
begin
  if Assigned(FNode) then
    Result := FNode.TreeView
  else
    Result := nil;
end;

procedure TQVTDefaultCellData.SetColumn(const AColumn: Integer);
begin
  if AColumn < 0 then
    FColumn := -1
  else if Assigned(FNode) then
  begin
    if AColumn < Node.TreeView.Header.Columns.Count then
      FColumn := AColumn
    else
      FColumn := Node.TreeView.Header.Columns.Count - 1;
  end
  else
    FColumn := AColumn;
end;

procedure TQVTDefaultCellData.SetNode(ANode: TQVTNode);
begin
  FNode := ANode;
end;

{ TQVTCheckDrawer }

procedure TQVTCheckDrawer.Draw(ARect: TRectF; AData: IQVTCellData);

var
  R, ABox: TRectF;
  ACheckData: IQVTCheckCellData;
  ATreeView: TQVirtualTreeView;
  AStroke: TStrokeBrush;
  AFill: TBrush;
  AOpacity: Single;
  // 绘制默认的CheckBox样式
  procedure DefaultDrawCheckBox;
  var
    pt1, pt2: TPointF;

  begin
    if (ABox.Top < ARect.Bottom) and (ABox.Left < ARect.Right) then
    begin
      if not ACheckData.Enabled then
        AOpacity := ATreeView.Opacity * 0.5
      else
        AOpacity := ATreeView.Opacity;
      AStroke := GetStroke(AData, True);
      if not Assigned(AStroke) then
      begin
        AStroke := ATreeView.Canvas.Stroke;
        AStroke.Kind := TBrushKind.Solid;
        AStroke.Color := ATreeView.TintColor;
      end;
      ATreeView.Canvas.DrawRect(ABox.SnapToPixel(ATreeView.Canvas.Scale, True),
        0, 0, [], AOpacity, AStroke);
      if TQVTCheckState.csChecked in ACheckData.CheckStates then
      begin
        R := ABox;
        R.Inflate(-3, -3);
        if TQVTCheckState.csSomeChecked in ACheckData.CheckStates then
        begin
          R.Right := R.Right + 1;
          R.Bottom := R.Bottom + 1;
          ATreeView.Canvas.ClearRect(R.SnapToPixel(ATreeView.Canvas.Scale,
            True), ColorWithOpacity(AStroke.Color, AOpacity));
        end
        else
        begin
          pt1 := R.TopLeft;
          pt2 := R.BottomRight;
          ATreeView.Canvas.DrawLine(pt1.SnapToPixel(ATreeView.Canvas.Scale),
            pt2.SnapToPixel(ATreeView.Canvas.Scale), AOpacity, AStroke);
          pt1.X := R.Right;
          pt2.X := R.Left;
          ATreeView.Canvas.DrawLine(pt1.SnapToPixel(ATreeView.Canvas.Scale),
            pt2.SnapToPixel(ATreeView.Canvas.Scale), AOpacity, AStroke);
        end;
      end;
    end;
  end;

  procedure DrawCheckBox;
  var
    AIdx: Integer;
  begin
    ACheckData.CheckBounds := ABox;
    AIdx := StatePathIndex(ACheckData.CheckStates);
    if Assigned(FCheckStatePath[AIdx]) and
      (Length(FCheckStatePath[AIdx].Data) > 0) then
    begin
      if not Assigned(FCurrentPath[AIdx]) then
      begin
        FCurrentPath[AIdx] := TPathData.Create;
        FCurrentPath[AIdx].Assign(FCheckStatePath[AIdx]);
      end;
      FCurrentPath[AIdx].FitToRect(ABox);
      if ACheckData.Enabled then
        DrawPath(AData, FCurrentPath[AIdx], ATreeView.Opacity)
      else
        DrawPath(AData, FCurrentPath[AIdx], ATreeView.Opacity * 0.5);
    end
    else
      DefaultDrawCheckBox
  end;

begin
  ATreeView := AData.TreeView;
  if Supports(AData, IQVTCheckCellData, ACheckData) then
  begin
    AFill := GetFill(AData, false);
    ATreeView.Canvas.FillRect(ARect, 0, 0, [], ATreeView.Opacity, AFill);
    CalcLayouts(AData, ARect, ABox, ARect);
    ACheckData.CheckBounds := ABox;
    DrawCheckBox;
    inherited Draw(ARect, AData);
  end;
end;

class function TQVTCheckDrawer.GetCheckedPath: TPathData;
begin
  Result := GetPathData([TQVTCheckState.csChecked]);
end;

class function TQVTCheckDrawer.GetPathData(AStates: TQVTCheckStates): TPathData;

var
  AIdx: Integer;
begin
  AIdx := StatePathIndex(AStates);
  if not Assigned(FCheckStatePath[AIdx]) then
    FCheckStatePath[AIdx] := TPathData.Create;
  Result := FCheckStatePath[AIdx];
end;

class function TQVTCheckDrawer.GetSomeCheckedPath: TPathData;
begin
  Result := GetPathData([TQVTCheckState.csChecked,
    TQVTCheckState.csSomeChecked]);
end;

class function TQVTCheckDrawer.GetUncheckPath: TPathData;
begin
  Result := GetPathData([]);
end;

class function TQVTCheckDrawer.StatePathIndex(AStates: TQVTCheckStates)
  : Integer;
begin
  Result := 0;
  if TQVTCheckState.csChecked in AStates then
    Inc(Result);
  if TQVTCheckState.csSomeChecked in AStates then
    Inc(Result);
end;

{ TQVTRadioDrawer }

procedure TQVTRadioDrawer.Draw(ARect: TRectF; AData: IQVTCellData);

var
  R, ABox: TRectF;
  ARadioData: IQVTRadioCellData;
  ATreeView: TQVirtualTreeView;
  AStroke: TStrokeBrush;
  AOpacity: Single;
  procedure DrawDefaultRadioButton;
  begin
    if (ABox.Top < ARect.Bottom) and (ABox.Left < ARect.Right) then
    begin
      if not ARadioData.Enabled then
        AOpacity := ATreeView.Opacity * 0.5
      else
        AOpacity := ATreeView.Opacity;
      AStroke := GetStroke(AData, True);
      if not Assigned(AStroke) then
      begin
        AStroke := ATreeView.Canvas.Stroke;
        AStroke.Kind := TBrushKind.Solid;
        AStroke.Color := ATreeView.TintColor;
      end;
      ATreeView.Canvas.DrawEllipse(ABox.SnapToPixel(ATreeView.Canvas.Scale),
        AOpacity, AStroke);
      if TQVTCheckState.csChecked in ARadioData.CheckStates then
      begin
        ABox.Inflate(-3, -3);
        if TQVTCheckState.csSomeChecked in ARadioData.CheckStates then
        begin
          ATreeView.Canvas.FillEllipse(ABox.SnapToPixel(ATreeView.Canvas.Scale),
            AOpacity * 0.5, AStroke);
        end
        else
          ATreeView.Canvas.FillEllipse(ABox.SnapToPixel(ATreeView.Canvas.Scale),
            AOpacity, AStroke);
      end;
    end;
  end;

  procedure DrawRadioButton;

  var
    AIdx: Boolean;
  begin
    ARadioData.RadioBounds := ABox;
    AIdx := TQVTCheckState.csChecked in ARadioData.CheckStates;
    if Assigned(FCheckStatePath[AIdx]) and
      (Length(FCheckStatePath[AIdx].Data) > 0) then
    begin
      if not Assigned(FCurrentPath[AIdx]) then
      begin
        FCurrentPath[AIdx] := TPathData.Create;
        FCurrentPath[AIdx].Assign(FCheckStatePath[AIdx]);
      end;
      FCurrentPath[AIdx].FitToRect(ABox);
      if ARadioData.Enabled then
        DrawPath(AData, FCurrentPath[AIdx], ATreeView.Opacity)
      else
        DrawPath(AData, FCurrentPath[AIdx], ATreeView.Opacity * 0.5);
    end
    else
      DrawDefaultRadioButton;
  end;

begin
  ATreeView := AData.TreeView;
  if Supports(AData, IQVTRadioCellData, ARadioData) then
  begin
    CalcLayouts(AData, ARect, ABox, R);
    DrawRadioButton;
    if not R.IsEmpty then
      inherited Draw(R, AData);
  end;
end;

class function TQVTRadioDrawer.GetCheckedPath: TPathData;
begin
  if not Assigned(FCheckStatePath[True]) then
    FCheckStatePath[false] := TPathData.Create;
  Result := FCheckStatePath[True];
end;

class function TQVTRadioDrawer.GetUncheckPath: TPathData;
begin
  if not Assigned(FCheckStatePath[false]) then
    FCheckStatePath[false] := TPathData.Create;
  Result := FCheckStatePath[false];
end;

{ TQVTImageDrawer }

procedure TQVTImageDrawer.Draw(ARect: TRectF; AData: IQVTCellData);

var
  AImage: IQVTImageCellData;
  ABitmap: TBitmap;
  AStateRect, AContentRect: TRectF;
begin
  if Supports(AData, IQVTImageCellData, AImage) then
  begin
    CalcLayouts(AData, ARect, AStateRect, AContentRect);
    ABitmap := AImage.GetImage;
    if Assigned(ABitmap) then
      AData.TreeView.Canvas.DrawBitmap(ABitmap, RectF(0, 0, ABitmap.Width,
        ABitmap.Height), AStateRect, AData.TreeView.Opacity,
        AImage.GetHighSpeed);
    inherited Draw(AContentRect, AData);
  end
  else
    inherited Draw(ARect, AData);
end;

{ TQVTStateDrawer }

function TQVTStateDrawer.CalcContentRect(const ARect: TRectF;
  AData: IQVTCellData): TRectF;

var
  ALayout: TQVTLayout;
  ASize: TSizeF;
  AStateRect: TRectF;
begin
  ALayout := GetLayout(AData, ASize);
  AStateRect := CalcStateRect(ARect, AData);
  Result := CalcContentRect(ARect, AStateRect, ALayout);
end;

function TQVTStateDrawer.CalcContentRect(const ARect, AStateRect: TRectF;
  ALayout: TQVTLayout): TRectF;

var
  AMargins: TRectF;
begin
  AMargins := GetMargins(ALayout);
  case ALayout of
    clLeftTop:
      begin
        Result.Left := AStateRect.Right;
        Result.Top := AStateRect.Bottom;
        Result.Right := ARect.Right;
        Result.Bottom := ARect.Bottom;
      end;
    clTopCenter:
      begin
        Result.Left := ARect.Left;
        Result.Top := AStateRect.Bottom;
        Result.Right := ARect.Right;
        Result.Bottom := ARect.Bottom;
      end;
    clRightTop:
      begin
        Result.Left := ARect.Left;
        Result.Top := AStateRect.Bottom;
        Result.Right := AStateRect.Left;
        Result.Bottom := ARect.Bottom;
      end;
    clRightCenter:
      begin
        Result.Left := ARect.Left;
        Result.Top := ARect.Top;
        Result.Right := AStateRect.Left;
        Result.Bottom := ARect.Bottom;
      end;
    clRightBottom:
      begin
        Result.Left := ARect.Left;
        Result.Top := ARect.Top;
        Result.Right := AStateRect.Left;
        Result.Bottom := AStateRect.Bottom;
      end;
    clBottomCenter:
      begin
        Result.Left := ARect.Left;
        Result.Top := ARect.Top;
        Result.Right := ARect.Right;
        Result.Bottom := AStateRect.Top;
      end;
    clLeftBottom:
      begin
        Result.Left := AStateRect.Right;
        Result.Top := ARect.Top;
        Result.Right := ARect.Right;
        Result.Bottom := AStateRect.Top;
      end;
    clLeftCenter:
      begin
        Result.Left := AStateRect.Right;
        Result.Top := ARect.Top;
        Result.Right := ARect.Right;
        Result.Bottom := ARect.Bottom;
      end;
    clCenter:
      // 你非要占中间，我也很绝望
      Result := ARect;
  end;
  Result.Left := Result.Left + AMargins.Left;
  Result.Top := Result.Top + AMargins.Top;
  Result.Bottom := Result.Bottom - AMargins.Bottom;
  Result.Right := Result.Right - AMargins.Right;
  if (Result.Right <= Result.Left) or (Result.Bottom <= Result.Top) then
    Result := TRectF.Empty;
end;

procedure TQVTStateDrawer.CalcLayouts(AData: IQVTCellData; const ARect: TRectF;
  var AStateRect, AContentRect: TRectF);

var
  ALayout: TQVTLayout;
  ASize: TSizeF;
begin
  ALayout := GetLayout(AData, ASize);
  AStateRect := CalcStateRect(ARect, ASize, ALayout);
  AContentRect := CalcContentRect(ARect, AStateRect, ALayout);
end;

function TQVTStateDrawer.CalcStateRect(const ARect: TRectF; const ASize: TSizeF;
  ALayout: TQVTLayout): TRectF;

var
  ARatio: TPointF;
  R, AMargins: TRectF;
  V: Single;
begin
  if ASize.IsZero then
  begin
    Result := TRectF.Empty;
    Exit;
  end;
  AMargins := GetMargins(ALayout);
  R := ARect;
  R.Left := R.Left + AMargins.Left;
  R.Top := R.Top + AMargins.Top;
  R.Right := R.Right - AMargins.Right;
  R.Bottom := R.Bottom - AMargins.Bottom;
  case ALayout of
    clLeftTop:
      begin
        Result.Left := R.Left;
        Result.Top := R.Top;
      end;
    clTopCenter:
      begin
        Result.Left := (R.Left + R.Right - ASize.cx) / 2;
        Result.Top := R.Top;
      end;
    clRightTop:
      begin
        Result.Left := R.Right - ASize.cx;
        Result.Top := R.Top;
      end;
    clRightCenter:
      begin
        Result.Left := R.Right - ASize.cx;
        Result.Top := (R.Top + R.Bottom - ASize.cy) / 2;
      end;
    clRightBottom:
      begin
        Result.Left := R.Right - ASize.cx;
        Result.Top := R.Bottom - ASize.cy;
      end;
    clBottomCenter:
      begin
        Result.Left := (R.Left + R.Right - ASize.cx) / 2;
        Result.Top := R.Bottom - ASize.cy;
      end;
    clLeftBottom:
      begin
        Result.Left := R.Left;
        Result.Top := R.Bottom - ASize.cy;
      end;
    clLeftCenter:
      begin
        Result.Left := R.Left;
        Result.Top := (R.Top + R.Bottom - ASize.cy) / 2;
      end;
    clCenter:
      begin
        Result.Left := (R.Left + R.Right - ASize.cx) / 2;
        Result.Top := (R.Top + R.Bottom - ASize.cy) / 2;
      end;
  end;
  Result.Right := Result.Left + ASize.cx;
  Result.Bottom := Result.Top + ASize.cy;
  if Result.Left < R.Left then
    Result.Left := R.Left;
  if Result.Top < R.Top then
    Result.Top := R.Top;
  if Result.Right > R.Right then
    Result.Right := R.Right;
  if Result.Bottom > R.Bottom then
    Result.Bottom := R.Bottom;
  ARatio.X := Result.Width / ASize.cx;
  ARatio.Y := Result.Height / ASize.cy;
  if not SameValue(ARatio.X, ARatio.Y) then // 比例不一样，有一个需要缩小尺寸
  begin
    if ARatio.X > ARatio.Y then // 垂直不足，需要缩放,水平需要适应垂直的尺寸
    begin
      case ALayout of
        clLeftTop, clLeftBottom, clLeftCenter:
          Result.Right := Result.Left + Result.Width * ARatio.Y;
        clTopCenter, clBottomCenter, clCenter:
          begin
            V := Result.Width * ARatio.Y;
            Result.Left := (Result.Left + Result.Right - V) / 2;
            Result.Right := Result.Left + V;
          end;
        clRightTop, clRightCenter, clRightBottom:
          Result.Left := Result.Right - Result.Width * ARatio.Y;
      end;
    end
    else
    begin
      case ALayout of
        clLeftTop, clTopCenter, clRightTop:
          Result.Bottom := Result.Top + Result.Height * ARatio.X;
        clRightCenter, clLeftCenter, clCenter:
          begin
            V := Result.Height * ARatio.X;
            Result.Top := (Result.Top + Result.Bottom - V) / 2;
            Result.Bottom := V;
          end;
        clRightBottom, clBottomCenter, clLeftBottom:
          Result.Top := Result.Bottom - Result.Height * ARatio.X;
      end;
    end;
  end;
end;

procedure TQVTStateDrawer.DrawPath(AData: IQVTCellData; APath: TPathData;
  AOpacity: Single);

var
  APathFill: TBrush;
begin
  APathFill := GetFill(AData, True);
  with AData.TreeView do
  begin
    if not Assigned(APathFill) then
    begin
      Canvas.Fill.Color := TintColor;
      Canvas.Fill.Kind := TBrushKind.Solid;
      APathFill := Canvas.Fill;
    end;
    Canvas.FillPath(APath, AOpacity, APathFill);
  end;
end;

function TQVTStateDrawer.CalcStateRect(const ARect: TRectF;
  AData: IQVTCellData): TRectF;

var
  ALayout: TQVTLayout;
  ASize: TSizeF;
begin
  ALayout := GetLayout(AData, ASize);
  Result := CalcStateRect(ARect, ASize, ALayout);
end;

function TQVTStateDrawer.GetLayout(AData: IQVTCellData; var AStateSize: TSizeF)
  : TQVTLayout;

var
  ALayoutData: IQVTCellLayoutData;
begin
  // 如果不支持布局接口，则按左中布局来
  if Supports(AData, IQVTCellLayoutData, ALayoutData) then
  begin
    AStateSize := ALayoutData.StateSize;
    Result := ALayoutData.Layout;
  end
  else
  begin
    AStateSize := TSizeF.Create(12, 12);
    Result := TQVTLayout.clLeftCenter;
  end;
end;

function TQVTStateDrawer.GetMargins(ALayout: TQVTLayout): TRectF;
begin
  case ALayout of
    clLeftTop:
      Result := Rect(3, 3, 1, 1);
    clTopCenter:
      Result := Rect(1, 3, 1, 1);
    clRightTop:
      Result := Rect(1, 3, 3, 1);
    clRightCenter:
      Result := Rect(1, 1, 3, 1);
    clRightBottom:
      Result := Rect(1, 1, 3, 3);
    clBottomCenter:
      Result := Rect(1, 1, 1, 3);
    clLeftBottom:
      Result := Rect(3, 1, 1, 3);
    clLeftCenter:
      Result := Rect(3, 1, 1, 1);
    clCenter:
      Result := Rect(1, 1, 1, 1);
  end;
end;

{ TQVTMoneyDrawer }

procedure TQVTMoneyDrawer.Draw(ARect: TRectF; AData: IQVTCellData);
begin

  // inherited;

end;

{ TQVTIndicatorDrawer }

procedure TQVTIndicatorDrawer.Draw(ARect: TRectF; AData: IQVTCellData);
begin
  // 只在当前行标记
  if AData.Node = AData.TreeView.FocusNode then
    DrawText(AData.TreeView, ARect, '>', AData.TreeView.TextSettings,
      AData.Enabled);
end;

{ TQVTImageStateDrawer }

procedure TQVTImageStateDrawer.Draw(ARect: TRectF; AData: IQVTCellData);
begin
  inherited;

end;

{ TQVTHeaderDrawer }

class constructor TQVTHeaderDrawer.Create;
begin

end;

class destructor TQVTHeaderDrawer.Destroy;
begin
  if Assigned(FStatePath[0]) then
    FreeAndNil(FStatePath[0]);
  if Assigned(FStatePath[1]) then
    FreeAndNil(FStatePath[1]);
end;

procedure TQVTHeaderDrawer.Draw(ARect: TRectF; AData: IQVTCellData);

var
  AColumn: TQVTColumn;
  ATreeView: TQVirtualTreeView;
  ACanvas: TCanvas;
  AFill: TBrush;
  ATextSettings: TTextSettings;
  AColors: array [0 .. 1] of TAlphaColor;
  R: TRectF;
  ASides: TSides;
  procedure DrawDefaultMarkers;
  begin
    if ATreeView.SortColumns.Count > 1 then
    begin
      case AColumn.Title.SortMarker of
        smAsc:
          DrawText(ATreeView, R, '↑' + IntToStr(AColumn.SortIndex + 1),
            ATextSettings, AColumn.Enabled);
        smDesc:
          DrawText(ATreeView, R, '↓' + IntToStr(AColumn.SortIndex + 1),
            ATextSettings, AColumn.Enabled);
      end;
    end
    else
    begin
      case AColumn.Title.SortMarker of
        smAsc:
          DrawText(ATreeView, R, '↑', ATextSettings, AColumn.Enabled);
        smDesc:
          DrawText(ATreeView, R, '↓', ATextSettings, AColumn.Enabled);
      end;
    end;
  end;

  procedure DrawSortMarkers;
  var
    MR: TRectF;
    ASourceSettings: TTextSettings;
  begin
    ASourceSettings := GetTextSettings(AData, false);
    ATextSettings := TTextSettingsClass(ASourceSettings.ClassType).Create(nil);
    try
      ATextSettings.Assign(ASourceSettings);
      // Marker的字体大小设置为9pt
      ATextSettings.Font.Size := 10;
      if Assigned(FStatePath[0]) and (Length(FStatePath[0].Data) > 0) and
        (AColumn.Title.SortMarker = TQVTColumnSortMarker.smAsc) then
      begin
        if not Assigned(FCurrentPath[0]) then
        begin
          FCurrentPath[0] := TPathData.Create;
          FCurrentPath[0].Assign(FStatePath[0]);
        end;
        MR := R;
        MR.Right := MR.Left + (MR.Width * 0.4);
        FCurrentPath[0].FitToRect(MR);
        ATreeView.Canvas.Fill.Color := ATreeView.TintColor;
        ATreeView.Canvas.FillPath(FCurrentPath[0], ATreeView.Opacity);
        if ATreeView.SortColumns.Count > 1 then
        begin
          R.Left := MR.Right;
          DrawText(ATreeView, R, IntToStr(AColumn.SortIndex + 1), ATextSettings,
            AColumn.Enabled);
        end;
      end
      else if Assigned(FStatePath[1]) and (Length(FStatePath[1].Data) > 0) and
        (AColumn.Title.SortMarker = TQVTColumnSortMarker.smDesc) then
      begin
        if not Assigned(FCurrentPath[1]) then
        begin
          FCurrentPath[1] := TPathData.Create;
          FCurrentPath[1].Assign(FStatePath[1]);
        end;
        MR := R;
        MR.Right := MR.Left + (MR.Width * 0.4);
        FCurrentPath[1].FitToRect(MR);
        ATreeView.Canvas.Fill.Color := ATreeView.TintColor;
        ATreeView.Canvas.FillPath(FCurrentPath[1], ATreeView.Opacity);
        if ATreeView.SortColumns.Count > 1 then
        begin
          R.Left := MR.Right;
          DrawText(ATreeView, R, IntToStr(AColumn.SortIndex + 1), ATextSettings,
            AColumn.Enabled);
        end;
      end
      else
        DrawDefaultMarkers;
    finally
      FreeAndNil(ATextSettings);
    end;
  end;

begin
  ATreeView := AData.TreeView;
  AColumn := ATreeView.Header.Columns[AData.Column];
  ACanvas := ATreeView.Canvas;
  R := ARect;
  if AColumn.Title.SortMarker <> TQVTColumnSortMarker.smNone then
  begin
    R.Right := R.Right - 16;
    AFill := GetFill(AData, false);
    if AFill.Kind <> TBrushKind.None then
      ACanvas.FillRect(RectF(R.Right, R.Top, ARect.Right, R.Bottom)
        .SnapToPixel(ACanvas.Scale), 0, 0, [], ATreeView.Opacity, AFill);
  end;
  inherited Draw(R, AData);
  // 要在右侧绘制排序状态
  if AColumn.Title.SortMarker <> smNone then
  begin
    R := ARect;
    R.Left := R.Right - 16;
    if R.Left < ARect.Left then
      R.Left := ARect.Left;
    DrawSortMarkers;
  end;
  if AColumn.Title.Clickable then
  // 如果可以点击，则绘制成按钮的形状
  begin
    if (not Assigned(ATreeView.FMouseDownNode)) and
      (AColumn.Index = ATreeView.MouseDownColumn) then // 当前列标题被按下
    begin
      AColors[0] := TAlphaColors.Lightgray;
      AColors[1] := TAlphaColors.Darkgray;
      ACanvas.Fill.Color := TAlphaColors.MedGray;
      ACanvas.FillRect(ARect, 0, 0, [], 0.5 * ATreeView.Opacity);
    end
    else
    begin
      AColors[0] := TAlphaColors.Darkgray;
      AColors[1] := TAlphaColors.Lightgray;
    end;
    ACanvas.Stroke.Color := AColors[0]; //
    ACanvas.Stroke.Thickness := 1;
    ACanvas.Stroke.Kind := TBrushKind.Solid;
    // 底部
    if (AColumn.Index + 1 < ATreeView.Header.Columns.Count) and
      IsZero(ATreeView.ColSpace) then
      ASides := [TSide.Bottom]
    else
      ASides := [TSide.Right, TSide.Bottom];
    ACanvas.DrawRectSides(RectF(ARect.Left, ARect.Top, ARect.Right - 1,
      ARect.Bottom - 1).SnapToPixel(ACanvas.Scale), 0, 0, [],
      ATreeView.Opacity, ASides);
    ACanvas.Stroke.Color := AColors[1]; //
    // 左侧
    if (ATreeView.MouseDownPosition = TQVTHitTestResult.hrHeader) and
      (ATreeView.MouseDownColumn = AColumn.Index) then
      ASides := [TSide.Top]
    else
      ASides := [];
    if ARect.Left > ATreeView.Stroke.Thickness then
      ASides := ASides + [TSide.Left];
    ACanvas.DrawRectSides(RectF(ARect.Left, ARect.Top, ARect.Right - 1,
      ARect.Bottom - 1).SnapToPixel(ACanvas.Scale), 0, 0, [],
      ATreeView.Opacity, ASides);
  end
  else
  begin
    ACanvas.Stroke.Color := TAlphaColors.LtGray;
    if ARect.Left <= ATreeView.Stroke.Thickness then
    begin
      if AColumn.Index + 1 = ATreeView.Header.Columns.Count then
        ASides := [TSide.Right, TSide.Bottom]
      else
        ASides := [TSide.Bottom];
    end
    else
    begin
      if (AColumn.Index + 1 < ATreeView.Header.Columns.Count) and
        IsZero(ATreeView.ColSpace) then
        ASides := [TSide.Left, TSide.Bottom]
      else
        ASides := [TSide.Left, TSide.Right, TSide.Bottom];
    end;
    ACanvas.DrawRectSides(RectF(ARect.Left, ARect.Top, ARect.Right - 1,
      ARect.Bottom - 1).SnapToPixel(ACanvas.Scale), 0, 0, [],
      ATreeView.Opacity, ASides);
  end;
end;

class function TQVTHeaderDrawer.GetAscPath: TPathData;
begin
  if not Assigned(FStatePath[0]) then
    FStatePath[0] := TPathData.Create;
  Result := FStatePath[0];
end;

class function TQVTHeaderDrawer.GetDescPath: TPathData;
begin
  if not Assigned(FStatePath[1]) then
    FStatePath[1] := TPathData.Create;
  Result := FStatePath[1];
end;

{ TQVTCheckCellData }

function TQVTCheckCellData.GetCheckBounds: TRectF;
begin
  Result := FCheckBounds;
end;

function TQVTCheckCellData.GetCheckStates: TQVTCheckStates;
begin
  Result := FCheckStates;
end;

function TQVTCheckCellData.GetFollowStates: Boolean;
begin
  Result := FFollowStates;
end;

function TQVTCheckCellData.GetText: String;
begin
  Result := '';
end;

procedure TQVTCheckCellData.SetCheckBounds(const R: TRectF);
begin
  FCheckBounds := R;
end;

procedure TQVTCheckCellData.SetCheckStates(AStates: TQVTCheckStates);
begin
  if not FUpdating then
  begin
    if FCheckStates <> AStates then
    begin
      FCheckStates := AStates;
      if FFollowStates then
        UpdateStates;
    end;
  end;
end;

procedure TQVTCheckCellData.SetFollowStates(const value: Boolean);
begin
  if FFollowStates <> value then
  begin
    FFollowStates := value;
    if value then
      UpdateStates;
  end;
end;

procedure TQVTCheckCellData.UpdateStates;
  procedure UpdateParent(AParent: TQVTNode);

  var
    AParentData, ACheckData: IQVTCheckCellData;
    ACheckNodeCount, ACheckedCount, AUncheckedCount: Integer;
    AChild: TQVTNode;
  begin
    ACheckedCount := 0;
    AUncheckedCount := 0;
    ACheckNodeCount := 0;
    if Supports(AParent.CellData[Column], IQVTCheckCellData) then
    begin
      AChild := AParent.GetFirstChild;
      while Assigned(AChild) do
      begin
        if Supports(AChild.CellData[Column], IQVTCheckCellData, ACheckData) then
        begin
          Inc(ACheckNodeCount);
          if TQVTCheckState.csChecked in ACheckData.CheckStates then
          begin
            if not(TQVTCheckState.csSomeChecked in ACheckData.CheckStates) then
              Inc(ACheckedCount);
          end
          else
            Inc(AUncheckedCount);
        end;
        AChild := AChild.Next;
      end;
      // 我们不知道是不是共享同一个IQVTCheckCellData还是单独，所以为了安全，我们需要重来一次
      AParentData := AParent.CellData[Column] as IQVTCheckCellData;
      if AUncheckedCount = ACheckNodeCount then
        AParentData.CheckStates := AParentData.CheckStates -
          [TQVTCheckState.csChecked, TQVTCheckState.csSomeChecked]
      else if ACheckedCount = ACheckNodeCount then
        AParentData.CheckStates := AParentData.CheckStates +
          [TQVTCheckState.csChecked] - [TQVTCheckState.csSomeChecked]
      else
        AParentData.CheckStates := AParentData.CheckStates +
          [TQVTCheckState.csChecked, TQVTCheckState.csSomeChecked];
    end;
  end;
  procedure UpdateChildren;

  var
    AChild: TQVTNode;
    AChildData: IQVTCheckCellData;
  begin
    if (Node.ChildCount > 0) and ((not(TQVTCheckState.csChecked in FCheckStates)
      ) or (not(TQVTCheckState.csSomeChecked in FCheckStates))) then
    begin
      AChild := Node.GetFirstChild;
      while Assigned(AChild) do
      begin
        if Supports(AChild.CellData[Column], IQVTCheckCellData, AChildData) then
        begin
          if TQVTCheckState.csChecked in FCheckStates then
            AChildData.CheckStates := AChildData.CheckStates +
              [TQVTCheckState.csChecked]
          else
            AChildData.CheckStates := AChildData.CheckStates -
              [TQVTCheckState.csChecked, TQVTCheckState.csSomeChecked];
        end;
        AChild := AChild.Next;
      end;
    end;
  end;

begin
  if FUpdating then
    Exit;
  FUpdating := True;
  try
    UpdateParent(Node.Parent);
    UpdateChildren;
  finally
    FUpdating := false;
  end;
end;

{ TQCellMultiDrawers }

function TQCellMultiDrawers.Add(const ADrawer: IQVTSizableDrawer): Integer;
begin
  Result := FDrawers.Add(ADrawer);
end;

procedure TQCellMultiDrawers.Clear;
begin
  FDrawers.Clear;
end;

constructor TQCellMultiDrawers.Create;
begin
  inherited;
  FDrawers := TList<IQVTSizableDrawer>.Create;
end;

procedure TQCellMultiDrawers.Delete(const AIdx: Integer);
begin
  FDrawers.Delete(AIdx);
end;

destructor TQCellMultiDrawers.Destroy;
begin
  FreeAndNil(FDrawers);
  inherited;
end;

procedure TQCellMultiDrawers.Draw(ARect: TRectF; AData: IQVTCellData);

var
  I: Integer;
  R, AMargins: TRectF;
  ASize: TSizeF;
  ADrawer: IQVTSizableDrawer;
  AMultiData: IQVTMultiDataCell;
begin
  AMultiData := nil;
  Supports(AData, IQVTMultiDataCell, AMultiData);
  if FIsVertical then
  begin
    R.Top := ARect.Top;
    for I := 0 to FDrawers.Count - 1 do
    begin
      ADrawer := FDrawers[I];
      if Assigned(AMultiData) then
        AMultiData.DrawerIndex := I;
      AMargins := ADrawer.GetMargins;
      R.Left := ARect.Left + AMargins.Left;
      R.Top := R.Top + AMargins.Top;
      R.Right := ARect.Right - AMargins.Right;
      R.Bottom := ARect.Bottom - AMargins.Bottom;
      ASize := ADrawer.GetSize(AData, R);
      R.Bottom := R.Top + ASize.cy;
      if R.Right <= R.Left then
        Break;
      if R.Bottom > R.Top then
        ADrawer.Draw(R, AData);
      R.Top := R.Bottom + AMargins.Bottom;
    end;
  end
  else
  begin
    R.Left := ARect.Left;
    for I := 0 to FDrawers.Count - 1 do
    begin
      ADrawer := FDrawers[I];
      if Assigned(AMultiData) then
        AMultiData.DrawerIndex := I;
      AMargins := ADrawer.GetMargins;
      R.Left := R.Left + AMargins.Left;
      R.Top := ARect.Top + AMargins.Top;
      R.Right := ARect.Right - AMargins.Right;
      R.Bottom := ARect.Bottom - AMargins.Bottom;
      ASize := ADrawer.GetSize(AData, R);
      R.Right := R.Left + ASize.cx;
      if R.Right > ARect.Right - AMargins.Right then
        R.Right := ARect.Right - AMargins.Right;
      if R.Right <= R.Left then
        Break;
      if R.Bottom > R.Top then
        ADrawer.Draw(R, AData);
      R.Left := R.Right + AMargins.Right;
    end;
  end;
end;

function TQCellMultiDrawers.GetEditorBounds(AData: IQVTCellData): TRectF;
begin
  Result := AData.Node.CellRect[AData.Column];
end;

{ TQSizableDrawer }

constructor TQSizableDrawer.Create(ADrawer: IQVTDrawer; const AMargins: TRectF;
  ASizeProc: TQGetSizeProc);
begin
  inherited Create;
  FRealDrawer := ADrawer;
  FMargins := AMargins;
  FSizeProc := ASizeProc;
end;

procedure TQSizableDrawer.Draw(ARect: TRectF; AData: IQVTCellData);
begin
  FRealDrawer.Draw(ARect, AData);
end;

function TQSizableDrawer.GetEditorBounds(AData: IQVTCellData): TRectF;
begin
  Result := AData.Node.CellRect[AData.Column];
end;

function TQSizableDrawer.GetMargins: TRectF;
begin
  Result := FMargins;
end;

function TQSizableDrawer.GetSize(AData: IQVTCellData; const R: TRectF): TSizeF;
begin
  if Assigned(FSizeProc) then
    Result := FSizeProc(AData, R)
  else
  begin
    Result.cx := 0;
    Result.cy := 0;
  end;
end;

{ TQVTCustomTextCell }

procedure TQVTCustomTextCell.Assign(src: TPersistent);
begin
  if src is TQVTCustomTextCell then
  begin
    DefaultText := TQVTCustomTextCell(src).DefaultText;
    FFill.Assign(TQVTCustomTextCell(src).FFill);
    FStroke.Assign(TQVTCustomTextCell(src).FStroke);
    FTextSettings.Assign(TQVTCustomTextCell(src).FTextSettings);
  end;
end;

constructor TQVTCustomTextCell.Create(AOwner: TComponent);
begin
  inherited;
  FFill := TBrush.Create(TBrushKind.None, TAlphaColors.White);
  FStroke := TStrokeBrush.Create(TBrushKind.Solid, TAlphaColors.Black);
end;

destructor TQVTCustomTextCell.Destroy;
begin
  FreeAndNil(FFill);
  FreeAndNil(FStroke);
  if Assigned(FTextSettings) then
    FreeAndNil(FTextSettings);
  inherited;
end;

function TQVTCustomTextCell.GetFill: TBrush;
begin
  Result := FFill;
end;

function TQVTCustomTextCell.GetStroke: TStrokeBrush;
begin
  Result := FStroke;
end;

function TQVTCustomTextCell.GetText: String;
begin
  Result := DefaultText;
  if Assigned(OnGetText) then
    OnGetText(Self, Result);
end;

function TQVTCustomTextCell.GetTextSettings: TTextSettings;
begin
  if not Assigned(FTextSettings) then
    FTextSettings := TTextSettingsInfo.Create(Self, GetTextSettingsClass);
  Result := FTextSettings.TextSettings;
end;

function TQVTCustomTextCell.GetTextSettingsClass
  : TTextSettingsInfo.TCustomTextSettingsClass;
begin
  Result := TCellTextSettings;
end;

procedure TQVTCustomTextCell.SetFill(AFill: TBrush);
begin
  FFill.Assign(AFill);
end;

procedure TQVTCustomTextCell.SetStroke(AStroke: TStrokeBrush);
begin
  FStroke.Assign(AStroke);
end;

procedure TQVTCustomTextCell.SetText(const S: String);

var
  Accept: Boolean;
begin
  Accept := True;
  if Assigned(OnValidText) then
    OnValidText(Self, S, Accept);
  if Accept and Assigned(OnSetText) then
    OnSetText(Self, S);
end;

procedure TQVTCustomTextCell.SetTextSettings(const value: TTextSettings);
begin
  TextSettings.Assign(value);
end;

{ TQVTCustomCell }

procedure TQVTCustomCell.BeforeDestruction;
begin
  inherited;
  TMessageManager.DefaultManager.SendMessage(Self,
    TQVTCellNotifyMessage.Create(cntData));
end;

constructor TQVTCustomCell.Create(AOwner: TComponent);
begin
  inherited;
  FEnabled := True;
  FSides := [TSide.Left, TSide.Top, TSide.Right, TSide.Bottom];
end;

function TQVTCustomCell.GetColumn: Integer;
begin
  Result := FColumn;
end;

function TQVTCustomCell.GetColumnId: Integer;
begin
  if Assigned(FNode) then
    Result := FNode.TreeView.Header.Columns[Column].ID
  else
    Result := -1;
end;

function TQVTCustomCell.GetEnabled: Boolean;
begin
  Result := FEnabled;
end;

function TQVTCustomCell.GetNode: TQVTNode;
begin
  Result := FNode;
end;

function TQVTCustomCell.GetSides: TSides;
begin
  Result := FSides;
end;

function TQVTCustomCell.GetTreeView: TQVirtualTreeView;
begin
  if Assigned(FNode) then
    Result := FNode.TreeView
  else
    Result := nil;
end;

procedure TQVTCustomCell.SetColumn(const AColumn: Integer);
begin
  FColumn := AColumn;
end;

procedure TQVTCustomCell.SetNode(ANode: TQVTNode);
begin
  FNode := ANode;
end;

{ TQVTCustomCheckCell }

function TQVTCustomCheckCell.GetCheckBounds: TRectF;
begin
  Result := FCheckBounds;
end;

function TQVTCustomCheckCell.GetCheckStates: TQVTCheckStates;
begin
  Result := FCheckStates;
  if Assigned(Node) then
    Node.NeedInitialized;
  if Assigned(OnGetStates) then
    OnGetStates(Self, Result);
end;

function TQVTCustomCheckCell.GetFollowStates: Boolean;
begin
  Result := FFollowStates;
end;

procedure TQVTCustomCheckCell.MouseClick(Button: TMouseButton;
  Shift: TShiftState; const APos: TPointF);
var
  AStates: TQVTCheckStates;
  ADrawer: IQVTStateDrawer;
  R: TRectF;
  AIndent: Single;
begin
  if Supports(Node.CellDrawer[Column], IQVTStateDrawer, ADrawer) then
  begin
    R := ADrawer.CalcStateRect(Node.DisplayRect, Node.CellData[Column]);
    AIndent := (Node.Level - 1) * Node.TreeView.NodeIndent;
    R.Left := FCheckBounds.Left + AIndent;
    R.Right := FCheckBounds.Right + AIndent;
    if R.Contains(APos) then
    begin
      AStates := CheckStates;
      if TQVTCheckState.csChecked in AStates then
        AStates := AStates - [TQVTCheckState.csChecked]
      else
        AStates := AStates + [TQVTCheckState.csChecked];
      CheckStates := AStates;
    end;
  end;
end;

procedure TQVTCustomCheckCell.MouseDown(AButton: TMouseButton;
  AShift: TShiftState; const APos: TPointF);
begin

end;

procedure TQVTCustomCheckCell.MouseMove(AShift: TShiftState;
  const APos: TPointF);
begin

end;

procedure TQVTCustomCheckCell.MouseUp(Button: TMouseButton; Shift: TShiftState;
  const APos: TPointF);
begin

end;

procedure TQVTCustomCheckCell.NextValue;
var
  AStates: TQVTCheckStates;
begin
  AStates := CheckStates;
  if TQVTCheckState.csSomeChecked in AStates then
    AStates := AStates - [TQVTCheckState.csSomeChecked]
  else if TQVTCheckState.csChecked in AStates then
    AStates := AStates - [TQVTCheckState.csChecked]
  else
    AStates := AStates + [TQVTCheckState.csChecked];
  CheckStates := AStates;
end;

procedure TQVTCustomCheckCell.SetCheckBounds(const R: TRectF);
begin
  FCheckBounds := R;
end;

procedure TQVTCustomCheckCell.SetCheckStates(AStates: TQVTCheckStates);
begin
  if FUpdateSender <> Node then
  begin
    if CheckStates <> AStates then
    begin
      if Assigned(OnValidStates) then
        OnValidStates(Self, AStates);
      if Assigned(OnSetStates) then
        OnSetStates(Self, AStates);
      FCheckStates := AStates;
      if FFollowStates then
        UpdateStates;
      if Assigned(Node) then
        Node.TreeView.Invalidate;
    end;
  end;
end;

procedure TQVTCustomCheckCell.SetFollowStates(const value: Boolean);
begin
  if FFollowStates <> value then
  begin
    FFollowStates := value;
    if value then
    begin
      UpdateStates;
    end;
  end;
end;

procedure TQVTCustomCheckCell.UpdateStates;
  procedure UpdateParent(AParent: TQVTNode);
  var
    AParentData, ACheckData: IQVTCheckCellData;
    ACheckNodeCount, ACheckedCount, AUncheckedCount: Integer;
    AChild: TQVTNode;
  begin
    ACheckedCount := 0;
    AUncheckedCount := 0;
    ACheckNodeCount := 0;
    if Supports(AParent.CellData[Column], IQVTCheckCellData) then
    begin
      AChild := AParent.GetFirstChild;
      while Assigned(AChild) do
      begin
        if Supports(AChild.CellData[Column], IQVTCheckCellData, ACheckData) then
        begin
          Inc(ACheckNodeCount);
          if TQVTCheckState.csChecked in ACheckData.CheckStates then
          begin
            if not(TQVTCheckState.csSomeChecked in ACheckData.CheckStates) then
              Inc(ACheckedCount);
          end
          else
            Inc(AUncheckedCount);
        end;
        AChild := AChild.Next;
      end;
      // 我们不知道是不是共享同一个IQVTCheckCellData还是单独，所以为了安全，我们需要重来一次
      AParentData := AParent.CellData[Column] as IQVTCheckCellData;
      if AUncheckedCount = ACheckNodeCount then
        AParentData.CheckStates := AParentData.CheckStates -
          [TQVTCheckState.csChecked, TQVTCheckState.csSomeChecked]
      else if ACheckedCount = ACheckNodeCount then
        AParentData.CheckStates := AParentData.CheckStates +
          [TQVTCheckState.csChecked] - [TQVTCheckState.csSomeChecked]
      else
        AParentData.CheckStates := AParentData.CheckStates +
          [TQVTCheckState.csChecked, TQVTCheckState.csSomeChecked];
      if not AParent.IsRoot then
        UpdateParent(AParent.Parent);
    end;
  end;
  procedure UpdateChildren;
  var
    AChild: TQVTNode;
    AChildData: IQVTCheckCellData;
  begin
    if (FUpdateSender.ChildCount > 0) then
    begin
      AChild := FUpdateSender.GetFirstChild;
      while Assigned(AChild) do
      begin
        if Supports(AChild.CellData[Column], IQVTCheckCellData, AChildData) then
        begin
          if TQVTCheckState.csChecked in FCheckStates then
            AChildData.CheckStates := AChildData.CheckStates +
              [TQVTCheckState.csChecked]
          else
            AChildData.CheckStates := AChildData.CheckStates -
              [TQVTCheckState.csChecked, TQVTCheckState.csSomeChecked];
        end;
        AChild := AChild.Next;
      end;
    end;
  end;

begin
  if FUpdating or (not Assigned(Node)) then
    Exit;
  FUpdating := True;
  try
    FUpdateSender := Node;
    UpdateParent(Node.Parent);
    UpdateChildren;
  finally
    FUpdating := false;
    FUpdateSender := nil;
  end;
end;

{ TQVTCustomProgressCell }

constructor TQVTCustomProgressCell.Create(AOwner: TComponent);
begin
  inherited;

end;

function TQVTCustomProgressCell.GetProgress: Single;
begin
  Result := FProgress;
  if Assigned(OnGetProgress) then
  begin
    OnGetProgress(Self, Result);
    if Result < 0 then
      Result := 0
    else if Result > 100 then
      Result := 100;
  end;
end;

procedure TQVTCustomProgressCell.SetProgress(const value: Single);
begin
  if value < 0 then
    FProgress := 0
  else if value > 100 then
    FProgress := 100
  else
    FProgress := value;
end;

{ TQVTCustomRadioCell }

constructor TQVTCustomRadioCell.Create(AOwner: TComponent);
begin
  inherited;
  FMsgId := TMessageManager.DefaultManager.SubscribeToMessage
    (TRadioButtonGroupMessage, DoStateChanged);
end;

destructor TQVTCustomRadioCell.Destroy;
begin
  TMessageManager.DefaultManager.Unsubscribe(TRadioButtonGroupMessage, FMsgId);
  inherited;
end;

procedure TQVTCustomRadioCell.DoStateChanged(const ASender: TObject;
  const AMessage: TMessage);
begin
  if (ASender <> Self) and (TRadioButtonGroupMessage(AMessage)
    .GroupName = FGroupName) then
  begin
    CheckStates := [];
    if Assigned(Node) then
      Node.TreeView.Invalidate;
  end;
end;

function TQVTCustomRadioCell.GetCheckStates: TQVTCheckStates;
begin
  Result := FCheckStates;
  if Assigned(OnGetStates) then
    OnGetStates(Self, Result);
end;

function TQVTCustomRadioCell.GetGroupName: String;
begin
  Result := FGroupName;
end;

function TQVTCustomRadioCell.GetRadioBounds: TRectF;
begin
  Result := FRadioBounds;
end;

procedure TQVTCustomRadioCell.MouseClick(Button: TMouseButton;
  Shift: TShiftState; const APos: TPointF);
var
  AStates: TQVTCheckStates;
  ADrawer: IQVTStateDrawer;
  R: TRectF;
begin
  if Supports(Node.CellDrawer[Column], IQVTStateDrawer, ADrawer) then
  begin
    R := ADrawer.CalcStateRect(Node.DisplayRect, Node.CellData[Column]);
    R.Left := FRadioBounds.Left;
    R.Right := FRadioBounds.Right;
    if R.Contains(APos) then
    begin
      AStates := CheckStates;
      if TQVTCheckState.csChecked in AStates then
        AStates := AStates - [TQVTCheckState.csChecked]
      else
        AStates := AStates + [TQVTCheckState.csChecked];
      CheckStates := AStates;
    end;
  end;
end;

procedure TQVTCustomRadioCell.MouseDown(AButton: TMouseButton;
  AShift: TShiftState; const APos: TPointF);
begin

end;

procedure TQVTCustomRadioCell.MouseMove(AShift: TShiftState;
  const APos: TPointF);
begin

end;

procedure TQVTCustomRadioCell.MouseUp(Button: TMouseButton; Shift: TShiftState;
  const APos: TPointF);
begin

end;

procedure TQVTCustomRadioCell.NextValue;
begin
  if not(TQVTCheckState.csChecked in CheckStates) then
    CheckStates := [TQVTCheckState.csChecked];
end;

procedure TQVTCustomRadioCell.SetCheckStates(AStates: TQVTCheckStates);
begin
  if AStates <> CheckStates then
  begin
    if Assigned(OnValidStates) then
      OnValidStates(Self, AStates);
    if Assigned(OnSetStates) then
      OnSetStates(Self, AStates);
    FCheckStates := AStates;
    if Assigned(Node) then
      Node.TreeView.Invalidate;
    if TQVTCheckState.csChecked in AStates then
      TMessageManager.DefaultManager.SendMessage(Self,
        TRadioButtonGroupMessage.Create(GroupName));
  end;
end;

procedure TQVTCustomRadioCell.SetGroupName(const AName: String);
begin
  FGroupName := AName;
end;

procedure TQVTCustomRadioCell.SetRadioBounds(const R: TRectF);
begin
  FRadioBounds := R;
end;

{ TQVTImageCell }

constructor TQVTImageCell.Create(AOwner: TComponent);
begin
  inherited;
  FBitmap := TBitmap.Create;
  FLayout := TQVTLayout.clLeftCenter;
end;

destructor TQVTImageCell.Destroy;
begin
  FreeAndNil(FBitmap);
  inherited;
end;

function TQVTImageCell.GetHighSpeed: Boolean;
begin
  Result := FHighSpeed;
end;

function TQVTImageCell.GetImage: TBitmap;
begin
  Result := FBitmap;
end;

function TQVTImageCell.GetLayout: TQVTLayout;
begin
  Result := FLayout;
end;

function TQVTImageCell.GetStateSize: TSizeF;
begin
  Result := FBitmap.Size;
end;

procedure TQVTImageCell.SetHighSpeed(const value: Boolean);
begin
  if FHighSpeed <> value then
  begin
    FHighSpeed := value;
    if Assigned(Node) then
      Node.TreeView.Invalidate;
  end;
end;

procedure TQVTImageCell.SetImage(const value: TBitmap);
begin
  if Assigned(OnSetImage) then
    OnSetImage(Self, value);
  FBitmap.Assign(value);
  if Assigned(Node) then
    Node.TreeView.Invalidate;
end;

procedure TQVTImageCell.SetLayout(ALayout: TQVTLayout);
begin
  if FLayout <> ALayout then
  begin
    FLayout := ALayout;
    if Assigned(Node) then
      Node.TreeView.Invalidate;
  end;
end;

{ TQVTBaseEditor }

procedure TQVTBaseEditor.BeforeDestruction;
begin
  inherited;
  TMessageManager.DefaultManager.SendMessage(Self,
    TQVTCellNotifyMessage.Create(cntEditor));
end;

function TQVTBaseEditor.BeginEdit(ANode: TQVTNode; ACol: Integer): Boolean;
var
  AData: IQVTCellData;
begin
  FNode := ANode;
  FColumn := ACol;
  if Assigned(ANode) and
    ((ACol >= 0) and (ACol < FNode.TreeView.Header.Columns.Count)) then
  begin
    AData := FNode.CellData[ACol];
    Result := AData.Enabled;
  end
  else
    Result := false;
  if Result then
    Control.Parent := ANode.TreeView;
end;

procedure TQVTBaseEditor.CancelEdit;
begin
  // Do Nothing
end;

constructor TQVTBaseEditor.Create(AOwner: TComponent);
begin
  inherited;
end;

destructor TQVTBaseEditor.Destroy;
begin
  inherited;
end;

procedure TQVTBaseEditor.DialogKey(var Key: Word; Shift: TShiftState);
begin
  if ((Key = vkReturn) and EnterAsTab) or (Key = vkTab) then
  begin
    Key := 0;
    TThread.Queue(nil,
      procedure
      var
        ACol: Integer;
        ANode: TQVTNode;
        ATreeView: TQVirtualTreeView;
      begin
        ACol := Column;
        ANode := Node;
        ATreeView := Node.TreeView;
        if ATreeView.EndEdit then
        begin
          repeat
            Inc(ACol);
            while ACol < ATreeView.Header.Columns.Count do
            begin
              if ATreeView.BeginEdit(ANode, ACol) then
                Exit
              else
                Inc(ACol);
            end;
            ACol := -1;
            ANode := ATreeView.GetNextVisible(ANode);
          until not Assigned(ANode);
        end;
      end);
    Key := 0;
  end;
end;

function TQVTBaseEditor.EndEdit: Boolean;
begin
  Result := True;
end;

function TQVTBaseEditor.GetControl: TControl;
begin
  if not Assigned(FControl) then
  begin
    FControl := FControlClass.Create(Self) as TControl;
    FControl.Parent := Node.TreeView;
    FControl.OnKeyDown := DoKeyDown;
  end;
  Result := FControl;
end;

function TQVTBaseEditor.GetEditing(var ACol: Integer): TQVTNode;
begin
  ACol := FColumn;
  Result := FNode;
end;

procedure TQVTBaseEditor.Hide;
begin
  if Assigned(FControl) then
    FControl.Visible := false;
end;

procedure TQVTBaseEditor.DoKeyDown(Sender: TObject; var Key: Word;
var KeyChar: System.WideChar; Shift: TShiftState);
begin
  // Control.tab

end;

procedure TQVTBaseEditor.SetBounds(R: TRectF);
begin
  Control.SetBounds(R.Left, R.Top, R.Width, R.Height);
end;

procedure TQVTBaseEditor.Show;
begin
  if not Control.Visible then
    Control.Visible := True;
  if not Control.IsFocused then
    Control.SetFocus;
  Control.Repaint;
end;

{ TQVTTextEditor }

function TQVTTextEditor.BeginEdit(ANode: TQVTNode; ACol: Integer): Boolean;
var
  AData: IQVTEditableTextCellData;
begin
  if Supports(ANode.CellData[ACol], IQVTTextCellData, AData) then
  begin
    Result := inherited;
    if Result then
      (Control as TCustomEdit).Text := AData.Text;
  end
  else
    Result := false;
end;

procedure TQVTTextEditor.CancelEdit;
begin
  (Control as TEdit).Text := '';
end;

constructor TQVTTextEditor.Create(AOwner: TComponent);
begin
  inherited;
  ControlClass := TEdit;
end;

function TQVTTextEditor.EndEdit: Boolean;
var
  AData: IQVTEditableTextCellData;
begin
  Result := True;
  if Supports(Node.CellData[Column], IQVTEditableTextCellData, AData) then
  begin
    AData.Text := (Control as TCustomEdit).Text;
    Hide;
  end;
end;

{ TQVTPickListCell }

constructor TQVTPickListCell.Create(AOwner: TComponent);
begin
  inherited;
  FItems := TStringList.Create;
end;

destructor TQVTPickListCell.Destroy;
begin
  FreeAndNil(FItems);
  inherited;
end;

function TQVTPickListCell.GetItems(AList: TStrings): Integer;
begin
  if Assigned(FOnGetItems) then
  begin
    Result := AList.Count;
    FOnGetItems(Self, AList);
    Result := AList.Count - Result;
  end
  else
  begin
    AList.Assign(FItems);
    Result := FItems.Count;
  end;
end;

procedure TQVTPickListCell.SetItems(const value: TStrings);
begin
  FItems.Assign(value);
end;

{ TQVTListEditor }

function TQVTListEditor.BeginEdit(ANode: TQVTNode; ACol: Integer): Boolean;
var
  AData: IQVTPickListCellData;
  AList: TStrings;
  AIdx: Integer;
begin
  if Supports(ANode.CellData[ACol], IQVTPickListCellData, AData) then
  begin
    Result := inherited;
    if Result then
    begin
      if TextEditable then
      begin
        AList := TComboEdit(Control).Items;
        TComboEdit(Control).OnDblClick := DoDoubleClick;
      end
      else
      begin
        AList := TComboBox(Control).Items;
        TComboBox(Control).OnDblClick := DoDoubleClick;
      end;
      AList.BeginUpdate;
      try
        AList.Clear;
        if AData.GetItems(AList) > 0 then
        begin
          if TextEditable then
          begin
            AIdx := AList.IndexOf(AData.Text);
            if AIdx = -1 then
              TComboEdit(Control).Text := AData.Text
            else
              TComboEdit(Control).ItemIndex := AIdx;
          end
          else
            TComboBox(Control).ItemIndex := AList.IndexOf(AData.Text);
        end
        else
        begin
          if TextEditable then
            TComboEdit(Control).Text := AData.Text
          else
            TComboBox(Control).ItemIndex := -1;
        end;
      finally
        AList.EndUpdate;
      end;
    end;
  end
  else
    Result := false;
end;

constructor TQVTListEditor.Create(AOwner: TComponent);
begin
  inherited;
  ControlClass := TComboBox;
end;

procedure TQVTListEditor.DialogKey(var Key: Word; Shift: TShiftState);
begin
  inherited;
  if not TextEditable then
  begin
    with Control as TComboBox do
    begin
      if Key = vkSpace then
      begin
        if ItemIndex + 1 < Items.Count then
          ItemIndex := ItemIndex + 1
        else if Items.Count > 0 then
          ItemIndex := 0;
      end
      else if Key = vkUp then
      begin
        if ItemIndex > 0 then
          ItemIndex := ItemIndex - 1;
      end
      else if Key = vkDown then
      begin
        if ItemIndex < Items.Count - 1 then
          ItemIndex := ItemIndex + 1;
      end;
    end;
  end;
end;

procedure TQVTListEditor.DoDoubleClick(ASender: TObject);
begin
  if NextValueOnDoubleClick then
  begin
    if TextEditable then
    begin
      with ASender as TComboEdit do
      begin
        if ItemIndex + 1 < Items.Count then
          ItemIndex := ItemIndex + 1
        else if Items.Count > 0 then
          ItemIndex := 0;
      end;
    end
    else
    begin
      with ASender as TComboBox do
      begin
        if ItemIndex + 1 < Items.Count then
          ItemIndex := ItemIndex + 1
        else if Items.Count > 0 then
          ItemIndex := 0;
      end;
    end;
  end;
end;

function TQVTListEditor.EndEdit: Boolean;
var
  AData: IQVTEditableTextCellData;
begin
  Result := True;
  if Supports(Node.CellData[Column], IQVTEditableTextCellData, AData) then
  begin
    if TextEditable then
      AData.Text := TComboEdit(Control).Text
    else
    begin
      with Control as TComboBox do
      begin
        if ItemIndex <> -1 then
          AData.Text := Items[ItemIndex];
      end;
    end;
    Hide;
  end;
end;

procedure TQVTListEditor.SetTextEditable(const value: Boolean);
begin
  if FTextEditable <> value then
  begin
    FTextEditable := value;
    if Assigned(FControl) then
      FreeAndNil(FControl);
    if value then
      FControlClass := TComboEdit
    else
      FControlClass := TComboBox;
  end;
end;

{ TQVTColorEditor }

function TQVTColorEditor.BeginEdit(ANode: TQVTNode; ACol: Integer): Boolean;
var
  AData: IQVTTextCellData;
begin
  if Supports(ANode.CellData[ACol], IQVTTextCellData, AData) then
  begin
    Result := inherited;
    if Result then
    begin
      with Control as TColorComboBox do
        ItemIndex := Items.IndexOf(AData.Text);
    end;
  end
  else
    Result := false;
end;

constructor TQVTColorEditor.Create(AOwner: TComponent);
begin
  inherited;
  ControlClass := TColorComboBox;
end;

function TQVTColorEditor.EndEdit: Boolean;
var
  AData: IQVTEditableTextCellData;
begin
  Result := True;
  if Supports(Node.CellData[Column], IQVTEditableTextCellData, AData) then
  begin
    with Control as TColorComboBox do
    begin
      if ItemIndex <> -1 then
        AData.Text := Items[ItemIndex];
    end;
    Hide;
  end;
end;

{ TQVTDialogEditor }

procedure TQVTDialogEditor.DoEditButtonClick(ASender: TObject);
var
  AData: IQVTTextCellData;
begin
  if Assigned(OnShowEditDialog) then
    OnShowEditDialog(Self);
  if Supports(Node.CellData[Column], IQVTTextCellData, AData) then
    TEdit(Control).Text := AData.Text;
end;

function TQVTDialogEditor.GetControl: TControl;
begin
  Result := inherited;
  if not Assigned(FEditButton) then
  begin
    FEditButton := TEllipsesEditButton.Create(Result);
    FEditButton.Parent := Result;
    FEditButton.OnClick := DoEditButtonClick;
  end;
end;

{ TQVTDBTextCell }

function TQVTDBTextCell.GetEnabled: Boolean;
begin
  if Assigned(FField) then
    Result := not FField.ReadOnly
  else
    Result := inherited;
end;

function TQVTDBTextCell.GetText: String;
begin
  if Assigned(FField) and FField.DataSet.Active then
    Result := FField.AsString
  else
    Result := DefaultText;
  if Assigned(OnGetText) then
    OnGetText(Self, Result);
end;

procedure TQVTDBTextCell.SetField(const value: TField);
begin
  if FField <> value then
  begin
    FField := value;
    if Assigned(Node) then
      Node.TreeView.Invalidate;
  end;
end;

procedure TQVTDBTextCell.SetText(const S: String);
begin
  inherited;
  if Assigned(FField) and FField.DataSet.Active then
  begin
    if not(FField.DataSet.State in [dsEdit, dsInsert]) then
      FField.DataSet.Edit;
    FField.AsString := S;
  end;
end;

{ TQVTDBAdapter }

procedure TQVTDBAdapter.ContentChanged;
var
  ABookmark: TBookmark;
  AItem: TQDBNodeExt;
  ADict: TDictionary<String, TQDBNodeExt>;
  APair: TPair<String, TQDBNodeExt>;
  AParent: TQDBNodeExt;
const
  EXT_PARENT_FOUND = $1;
begin
  if Assigned(FDataSet) and Assigned(FTreeView) and FDataSet.Active then
  begin
    if Assigned(FParentField) and Assigned(FKeyField) then
    begin
      ABookmark := FDataSet.Bookmark;
      ADict := TDictionary<String, TQDBNodeExt>.Create;
      FDataSet.DisableControls;
      try
        FDataSet.First;
        FRootItems.Clear;
        while not FDataSet.Eof do
        begin
          AItem := TQDBNodeExt.Create;
          AItem.FKeyValue := FKeyField.AsString;
          AItem.FParentValue := FParentField.AsString;
          AItem.FBookmark := FDataSet.Bookmark;
          ADict.Add(AItem.FKeyValue, AItem);
          FDataSet.Next;
        end;
        for APair in ADict do
        begin
          if ADict.TryGetValue(APair.value.FParentValue, AParent) then
          begin
            APair.value.FParent := AParent;
            APair.value.FFlags := APair.value.FFlags or EXT_PARENT_FOUND;
            AParent.Children.Add(APair.value);
          end
          else if APair.value.FParentValue = FRootParentValue then
          begin
            APair.value.FFlags := APair.value.FFlags or EXT_PARENT_FOUND;
            FRootItems.Add(APair.value);
          end;
        end;
        // 对于孤儿结点处理
        for APair in ADict do
        begin
          if (APair.value.FFlags and EXT_PARENT_FOUND) = 0 then
          begin
            if AddOrphanAsRoot then
              FRootItems.Add(APair.value)
            else
              APair.value.DisposeOf;
          end;
        end;
      finally
        FDataSet.Bookmark := ABookmark;
        FDataSet.EnableControls;
        FreeAndNil(ADict);
        FTreeView.RootNodeCount := FRootItems.Count;
        FTreeView.RootNode.ReinitChildren;
      end;
    end;
  end
  else if Assigned(FTreeView) then
    FTreeView.RootNodeCount := 0;
end;

constructor TQVTDBAdapter.Create(AOwner: TComponent);
begin
  inherited;
  FRootItems := TObjectList<TQDBNodeExt>.Create;
end;

destructor TQVTDBAdapter.Destroy;
begin
  FreeAndNil(FRootItems);
  inherited;
end;

procedure TQVTDBAdapter.DoInitNode(Sender: TQVirtualTreeView; ANode: TQVTNode);
var
  AExt: TQDBNodeExt;
begin
  if ANode.Parent = Sender.RootNode then
    AExt := FRootItems[ANode.Index]
  else
  begin
    AExt := ANode.Parent.ExtByType(TQDBNodeExt) as TQDBNodeExt;
    AExt := AExt.Children[ANode.Index]
  end;
  if Assigned(AExt.FChildren) then
    ANode.ChildCount := AExt.FChildren.Count;
  ANode.Exts.Add(AExt);
end;

procedure TQVTDBAdapter.SetDataSet(const value: TDataSet);
begin
  if FDataSet <> value then
  begin
    FDataSet := value;
    ContentChanged;
  end;
end;

procedure TQVTDBAdapter.SetDataSource(const value: TDataSource);
begin
  if FDataSource <> value then
  begin
    FDataSource := value;
    if Assigned(value) then
      FDataSet := value.DataSet;
    ContentChanged;
  end;
end;

procedure TQVTDBAdapter.SetKeyField(const value: TField);
begin
  FKeyField := value;
end;

procedure TQVTDBAdapter.SetParentField(const value: TField);
begin
  FParentField := value;
end;

procedure TQVTDBAdapter.SetTreeView(const value: TQVirtualTreeView);
begin
  if FTreeView <> value then
  begin
    FTreeView := value;
    if Assigned(value) then
      FTreeView.OnInitNode := DoInitNode;
    ContentChanged;
  end;
end;

{ TQSimpleObject<T> }

constructor TQSimpleObject<T>.Create(const AValue: T);
begin
  inherited Create;
  FValue := AValue;
end;

{ TQSimpleInterface<T> }

constructor TQSimpleInterface<T>.Create(const AValue: T);
begin
  inherited Create;
  FValue := AValue;
end;

{ TQVTDBAdapter.TQDBNodeExt }

constructor TQVTDBAdapter.TQDBNodeExt.Create;
begin

end;

destructor TQVTDBAdapter.TQDBNodeExt.Destroy;
begin
  if Assigned(FChildren) then
    FreeAndNil(FChildren);
  inherited;
end;

function TQVTDBAdapter.TQDBNodeExt.GetChildren: TObjectList<TQDBNodeExt>;
begin
  if not Assigned(FChildren) then
    FChildren := TObjectList<TQDBNodeExt>.Create;
  Result := FChildren;
end;

{ TQVTColorDrawer }

procedure TQVTColorDrawer.Draw(ARect: TRectF; AData: IQVTCellData);
var
  ATreeView: TQVirtualTreeView;
  AColorData: IQVTColorCellData;
  AFill: TBrush;
  AColorBox: TRectF;
  AStroke: TStrokeBrush;
begin
  inherited;
  ATreeView := AData.TreeView;
  if Supports(AData, IQVTColorCellData, AColorData) then
  begin
    AFill := GetFill(AData, false);
    ATreeView.Canvas.FillRect(ARect, 0, 0, [], ATreeView.Opacity, AFill);
    CalcLayouts(AData, ARect, AColorBox, ARect);
    AStroke := GetStroke(AData, false);
    ATreeView.Canvas.Fill.Kind := TBrushKind.Solid;
    ATreeView.Canvas.Fill.Color := AColorData.Color;
    ATreeView.Canvas.FillRect(AColorBox, 0, 0, [], ATreeView.Opacity);
    ATreeView.Canvas.DrawRect(AColorBox, 0, 0, [], ATreeView.Opacity, AStroke);
    inherited Draw(ARect, AData);
  end;
end;

{ TQVTBaseDrawer }

procedure TQVTBaseDrawer.BeforeDestruction;
begin
  inherited;
  TMessageManager.DefaultManager.SendMessage(Self,
    TQVTCellNotifyMessage.Create(cntDrawer));
end;

function TQVTBaseDrawer.GetEditorBounds(AData: IQVTCellData): TRectF;
begin
  Result := AData.Node.CellRect[AData.Column];
end;

{ TQVTCustomDrawer }

procedure TQVTCustomDrawer.Draw(ARect: TRectF; AData: IQVTCellData);
begin
  if Assigned(FOnDraw) then
    FOnDraw(Self, ARect, AData);
end;

{ TQVTExtendableObject }

destructor TQVTExtendableObject.Destroy;
begin
  if Assigned(FExts) then
    FreeAndNil(FExts);
  inherited;
end;

function TQVTExtendableObject.ExtByName(const AName: String): IQVTNamedExt;
var
  I: Integer;
  AExt: IQVTNamedExt;
begin
  Result := nil;
  if Assigned(FExts) then
  begin
    for I := 0 to FExts.Count - 1 do
    begin
      if Supports(FExts[I], IQVTNamedExt, AExt) and (AExt.Name = AName) then
      begin
        Result := AExt;
        Exit;
      end;
    end;
  end;
end;

function TQVTExtendableObject.ExtByType(const IID: TGUID; var AValue): Boolean;
var
  I: Integer;
begin
  Result := false;
  Pointer(AValue) := nil;
  if Assigned(FExts) then
  begin
    for I := 0 to FExts.Count - 1 do
    begin
      Result := Supports(FExts[I], IID, AValue);
      if Result then
        Exit;
    end;
  end;
end;

function TQVTExtendableObject.ExtByType(const AClass: TClass): TObject;
var
  I: Integer;
  AExt: IInterface;
begin
  Result := nil;
  if Assigned(FExts) then
  begin
    for I := 0 to FExts.Count - 1 do
    begin
      AExt := FExts[I];
      if AExt is AClass then
      begin
        Result := AExt as AClass;
        Exit;
      end;
    end;
  end;
end;

function TQVTExtendableObject.ExtByType(const AClass: TClass;
var AValue): Boolean;
begin
  TObject(AValue) := ExtByType(AClass);
  Result := TObject(AValue) <> nil;
end;

function TQVTExtendableObject.GetExts: TList<IInterface>;
begin
  if not Assigned(FExts) then
    FExts := TList<IInterface>.Create;
  Result := FExts;
end;

function TQVTExtendableObject.HasExts: Boolean;
begin
  Result := Assigned(FExts) and (FExts.Count > 0);
end;

function TQVTExtendableObject.QueryInterface(const IID: TGUID; out Obj)
  : HResult;
var
  I: Integer;
begin
  Result := inherited;
  if (Result = E_NOINTERFACE) and Assigned(FExts) then
  begin
    for I := 0 to FExts.Count - 1 do
    begin
      Result := FExts[I].QueryInterface(IID, Obj);
      if Result = S_OK then
        Break;
    end;
  end;
end;

end.
