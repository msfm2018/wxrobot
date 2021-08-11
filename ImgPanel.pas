unit ImgPanel;

interface

uses
  Types, ExtCtrls, Windows, Messages, Graphics, Controls, Classes, SysUtils,
   forms;

type
  ttimenotify = procedure of object;

  TImgPanel = class(TCustomPanel)
  private
    procedure WndProc(var message: TMessage); override;
  private
    ftnotify: ttimenotify;
    FPic: TPicture;
    FHotPic: TPicture;
    FTmpPic: TPicture;
    FTransparent: Boolean;
    FAutoSize: Boolean;
    FCaptionPosX: Integer;
    FCaptionPosY: Integer;
    FTransColor: TColor; // 透明色
    FLastDrawCaptionRect: TRect;
    FStretch: Boolean;
    FTitleBar: Boolean;
    procedure WMERASEBKGND(var Msg: TMessage); message WM_ERASEBKGND;
    procedure ApplyAutoSize();
    procedure ApplyTransparent();
    procedure SetPicture(const Value: TPicture);
    procedure SetAutoSize(const Value: Boolean); reintroduce;
    procedure SetCaptionPosX(const Value: Integer);
    procedure SetCaptionPosY(const Value: Integer);
    procedure SetStretch(const Value: Boolean);
    procedure SetTitleBar(const Value: Boolean);
    procedure setftime(v: ttimenotify);
    procedure SetTransColor(const Value: TColor);
  published
    property ontnotify: ttimenotify read ftnotify write setftime;
  protected
    procedure Paint(); override;
    procedure ClearPanel(); virtual;
    procedure PictureChanged(Sender: TObject); virtual;
    procedure SetTransparent(const Value: Boolean); virtual;
    procedure Resize(); override;
    property TransColor: TColor read FTransColor write SetTransColor;
  public
    AppPath: string;
    constructor Create(AOwner: TComponent); override;
    destructor Destroy(); override;
    property CaptionPosX: Integer read FCaptionPosX write SetCaptionPosX;
    property CaptionPosY: Integer read FCaptionPosY write SetCaptionPosY;
  published
    property BevelOuter;
    property BevelInner;
    property BiDiMode;
    property BorderWidth;
    property Anchors;
    property Canvas;
    property Transparent: Boolean Read FTransparent Write SetTransparent
      default false;
    property AutoSize: Boolean Read FAutoSize Write SetAutoSize;
    property Stretch: Boolean read FStretch write SetStretch;
    property Parentfont;
    property Alignment;
    property Align;
    property Font;
    property TabStop;
    property TabOrder;
    property Caption;
    property Color;
    property Visible;
    property PopupMenu;
    property ShowHint;
    property ParentColor;
    property OnCanResize;
    property OnClick;
    property OnConstrainedResize;
    property OnDockDrop;
    property OnDockOver;
    property OnDblClick;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDock;
    property OnEndDrag;
    property OnEnter;
    property OnExit;
    property OnGetSiteInfo;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnResize;
    property OnStartDock;
    property OnStartDrag;
    property OnUnDock;
    property TitleBar: Boolean read FTitleBar write SetTitleBar;
  private
    { Private declarations }

    Fchanged: Boolean;
    procedure SetHotPic(const Value: TPicture);
    procedure CMMouseEnter(var message: TMessage); message CM_MOUSEENTER;
    procedure CMMouseLeave(var message: TMessage); message CM_MOUSELEAVE;
  public
  G_Buf: TBitmap;
  published
    property Pic: TPicture read FPic write SetPicture;
    property HotPic: TPicture read FHotPic write SetHotPic;

  end;

procedure Register;

implementation



var

  gmov: Boolean = false;

procedure Register;
begin
  RegisterComponents('widget', [TImgPanel]);
end;

{ TsuiCustomPanel }
procedure DoTrans(Canvas: TCanvas; Control: TWinControl);
var
  DC: HDC;
  SaveIndex: HDC;
  Position: TPoint;
  IA, IB: Integer;
begin
  if Control.Parent <> nil then
  begin
{$R-}
    DC := Canvas.Handle;
    SaveIndex := SaveDC(DC);
    GetViewportOrgEx(DC, Position);
    IA := Position.X - Control.Left;
    IB := Position.Y - Control.Top;
    SetViewportOrgEx(DC, IA, IB, nil); // 哪个设备点映射到窗口原点(0,0)
    IntersectClipRect(DC, 0, 0, Control.Parent.ClientWidth,
      Control.Parent.ClientHeight); // 创建了一个新的剪切区域，该区域是当前剪切区域和一个特定矩形的交集。
    Control.Parent.Perform(WM_ERASEBKGND, DC, 0);
    Control.Parent.Perform(WM_PAINT, DC, 0);
    RestoreDC(DC, SaveIndex);
{$R+}
  end;
end;

procedure TImgPanel.ApplyAutoSize;
begin
  if FAutoSize then
  begin
    if ((Align <> alTop) and (Align <> alBottom) and (Align <> alClient)) then
      Width := FPic.Width;

    if ((Align <> alLeft) and (Align <> alRight) and (Align <> alClient)) then
      Height := FPic.Height;
  end;
end;

procedure TImgPanel.ApplyTransparent;
begin
  if FPic.Graphic.Transparent <> FTransparent then
    FPic.Graphic.Transparent := FTransparent;
end;

procedure TImgPanel.ClearPanel;
begin
  Canvas.Brush.Color := Color;

  if ParentWindow <> 0 then
    Canvas.FillRect(ClientRect);
end;

constructor TImgPanel.Create(AOwner: TComponent);
begin

  inherited Create(AOwner);
   DoubleBuffered:=true;
  FPic := TPicture.Create();
  FHotPic := TPicture.Create;
  FTmpPic := TPicture.Create;

  FPic.OnChange := PictureChanged;
  FCaptionPosX := -1;
  FCaptionPosY := -1;

  BevelInner := bvNone;
  BevelOuter := bvNone;

  Fchanged := false;
  G_Buf := TBitmap.Create;
//  Repaint();
end;

destructor TImgPanel.Destroy;
begin
  if FPic <> nil then
    FreeAndNil(FPic);

  if FHotPic <> nil then
    FreeAndNil(FHotPic);
  if FTmpPic <> nil then
    FreeAndNil(FTmpPic);
    if G_Buf<>nil then
    FreeAndNil(G_Buf);
  G_Buf.Free;;
  inherited;
end;

procedure TImgPanel.Paint;
var
  uDrawTextFlag: Cardinal;
  Rect: TRect;

var

  Rgn: HRGN;
begin

  G_Buf.Height := Height;
  G_Buf.Width := Width;

  if FTransparent then
    DoTrans(G_Buf.Canvas, self);

  if Assigned(FPic.Graphic) then
  begin
    if Stretch then
      G_Buf.Canvas.StretchDraw(ClientRect, FPic.Graphic)
    else
      G_Buf.Canvas.Draw(0, 0, FPic.Graphic);
  end
  else if not FTransparent then
  begin
    G_Buf.Canvas.Brush.Color := Color;
    G_Buf.Canvas.FillRect(ClientRect);
  end;

  G_Buf.Canvas.Brush.Style := bsClear;

  if Trim(Caption) <> '' then
  begin
    G_Buf.Canvas.Font := Font;

    if (FCaptionPosX <> -1) and (FCaptionPosY <> -1) then
    begin
      G_Buf.Canvas.TextOut(FCaptionPosX, FCaptionPosY, Caption);
      FLastDrawCaptionRect := Classes.Rect(FCaptionPosX, FCaptionPosY,
        FCaptionPosX + G_Buf.Canvas.TextWidth(Caption),
        FCaptionPosY + G_Buf.Canvas.TextWidth(Caption));
    end
    else
    begin
      Rect := ClientRect;
      uDrawTextFlag := DT_CENTER;
      if Alignment = taRightJustify then
        uDrawTextFlag := DT_RIGHT
      else if Alignment = taLeftJustify then
        uDrawTextFlag := DT_LEFT;
      DrawText(G_Buf.Canvas.Handle, PChar(Caption), -1, Rect, uDrawTextFlag or
        DT_SINGLELINE or DT_VCENTER);
      FLastDrawCaptionRect := Rect;
    end;
  end;

  BitBlt(Canvas.Handle, 0, 0, Width, Height, G_Buf.Canvas.Handle, 0, 0,
    SRCCOPY);

end;

procedure TImgPanel.PictureChanged(Sender: TObject);
begin
  if FPic.Graphic <> nil then
  begin
    if FAutoSize then
      ApplyAutoSize();
    ApplyTransparent();
  end;

  ClearPanel();
  Repaint();
end;

procedure TImgPanel.Resize;

begin
  inherited;

  Repaint();
end;

procedure TImgPanel.SetAutoSize(const Value: Boolean);
begin
  FAutoSize := Value;

  if FPic.Graphic <> nil then
    ApplyAutoSize();
end;

procedure TImgPanel.SetCaptionPosX(const Value: Integer);
begin
  FCaptionPosX := Value;

  Repaint();
end;

procedure TImgPanel.SetCaptionPosY(const Value: Integer);
begin
  FCaptionPosY := Value;

  Repaint();
end;

procedure TImgPanel.setftime(v: ttimenotify);
begin
  ftnotify := v;
end;

procedure TImgPanel.SetPicture(const Value: TPicture);
begin
  FPic.Assign(Value);

  ClearPanel();
  Repaint();
end;

procedure TImgPanel.SetStretch(const Value: Boolean);
begin
  FStretch := Value;
end;

procedure TImgPanel.SetTitleBar(const Value: Boolean);
begin
  FTitleBar := Value;
end;

procedure TImgPanel.SetTransColor(const Value: TColor);
begin
  FTransColor := Value;
end;

procedure TImgPanel.SetTransparent(const Value: Boolean);
begin
  FTransparent := Value;

  if FPic.Graphic <> nil then
    ApplyTransparent();
  Repaint();
end;

procedure TImgPanel.WMERASEBKGND(var Msg: TMessage);
begin
  // // do nothing;
  Msg.Result := 1
end;

procedure TImgPanel.WndProc(var message: TMessage);
begin
//  case message.Msg of
//
//
//    WM_MOUSEMOVE:
//      begin
//
//        // MK_LBUTTON
//        if message.WParam = MK_LBUTTON then
//        begin
//          gmov := True;
//       //   Form1.allInvalidate;
//          g_core.SysSet.MoveWindow(self.Parent.Handle);
//
//        end     ;
//
//      end;
//  end;

  inherited;
end;

procedure TImgPanel.CMMouseEnter(var message: TMessage);
begin
  try
    if Not(csDesigning in ComponentState) then
    begin
      if Assigned(OnMouseEnter) then
        OnMouseEnter(self);

      if FPic.Graphic <> nil then
      begin
        FTmpPic.Assign(FPic);
        Fchanged := false;
        if HotPic.Graphic <> nil then
          Pic.Assign(HotPic);
      end;
    end;
  except
  end;
end;

procedure TImgPanel.CMMouseLeave(var message: TMessage);
begin
  try
    if Not(csDesigning in ComponentState) then
    begin
      if Assigned(OnMouseLeave) then
        OnMouseLeave(self);

      if FTmpPic.Graphic <> nil then
        Pic.Assign(FTmpPic);
    end;
  except
  end;
end;

procedure TImgPanel.SetHotPic(const Value: TPicture);
begin
  FHotPic.Assign(Value);
end;

end.// ---
