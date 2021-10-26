unit qdac_fmx_pophint;

interface

uses classes, sysutils, types, uitypes, System.Messaging, fmx.types,
  fmx.Objects, fmx.textlayout,
  fmx.graphics, fmx.controls, fmx.stdctrls, fmx.forms;

type
  TQPopupHintHelper = class(TFMXObject)
  private
    FPopup: TPopup;
    FBackground: TRectangle;
    FText: TLabel;
    FTimer: TTimer;
    FVKMsgId: Integer;
    procedure DoHideHint(ASender: TObject);
    procedure DoVKVisibleChanged(const Sender: TObject;
      const Msg: System.Messaging.TMessage);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

  TQPopupHint = class
  private
    FHintFrameColor: TAlphaColor;
    FHintTextColor: TAlphaColor;
    FHintBackgroundColor: TAlphaColor;
    FHintPause: Cardinal;
    FTextLayout: TTextLayout;
    function HintNeeded: TQPopupHintHelper; inline;
    function Prepare: TQPopupHintHelper;

    function GetTextLayout: TTextLayout;
    property textlayout: TTextLayout read GetTextLayout;
  public
    constructor Create; overload;
    destructor Destroy; override;
    procedure ShowHint(ACtrl: TControl; const AMsg: String;
      APlacement: TPlacement = TPlacement.Bottom); overload;
    procedure ShowHint(APos: TPointF; const AMsg: String); overload;
    procedure ShowHint(ARect: TRectF; const AMsg: String); overload;
    procedure ShowHint(const S: String;
      AHorzAlign, AVertAlign: TTextAlign); overload;
    function TextRect(const S: String; ASettings: TTextSettings;
      AMaxWidth: Single): TRectF;
    property HintFrameColor: TAlphaColor read FHintFrameColor
      write FHintFrameColor;
    property HintBackgroundColor: TAlphaColor read FHintBackgroundColor
      write FHintBackgroundColor;
    property HintTextColor: TAlphaColor read FHintTextColor
      write FHintTextColor;
    property HintPause: Cardinal read FHintPause write FHintPause;
  end;

var
  PopupHint: TQPopupHint;

implementation

uses qdac_fmx_vkhelper;
{ TQPopupHint }

constructor TQPopupHint.Create;
begin
  inherited Create;
  FHintFrameColor := TAlphaColors.Black;
  FHintBackgroundColor := TAlphaColor($80FFFFFF);
  FHintTextColor := TAlphaColors.Black;
  FHintPause := 5000;
end;

destructor TQPopupHint.Destroy;
begin
  if Assigned(FTextLayout) then
    FTextLayout.DisposeOf;
  inherited;
end;

function TQPopupHint.GetTextLayout: TTextLayout;
begin
  if not Assigned(FTextLayout) then
  begin
    FTextLayout := TTextLayoutManager.TextLayoutByCanvas
      (TCanvasManager.MeasureCanvas.ClassType)
      .Create(TCanvasManager.MeasureCanvas);
    FTextLayout.HorizontalAlign := TTextAlign.Leading;
  end;
  Result := FTextLayout;
end;

function TQPopupHint.HintNeeded: TQPopupHintHelper;
begin
  Result := Prepare;
end;

function TQPopupHint.Prepare: TQPopupHintHelper;
var
  AForm: TCommonCustomForm;
  I: Integer;
begin
  AForm := Screen.ActiveForm;
  if not Assigned(AForm) then
    AForm := Application.MainForm;
  Result := nil;
  if Assigned(AForm) then
  begin
    for I := 0 to AForm.ComponentCount - 1 do
    begin
      if AForm.Components[I] is TQPopupHintHelper then
      begin
        Result := AForm.Components[I] as TQPopupHintHelper;
        Result.FBackground.Fill.Color := HintBackgroundColor;
        Result.FBackground.Stroke.Color := HintFrameColor;
        Result.FText.FontColor := HintTextColor;
        Result.FTimer.Interval := HintPause;
        Break;
      end;
    end;
    if not Assigned(Result) then
    begin
      Result := TQPopupHintHelper.Create(AForm);
      Result.FPopup.Parent := AForm;
    end;
  end;
end;

procedure TQPopupHint.ShowHint(ACtrl: TControl; const AMsg: String;
  APlacement: TPlacement);
var
  R: TRectF;
  AHelper: TQPopupHintHelper;
begin
  AHelper := Prepare;
  if Assigned(AHelper) then
  begin
    R := TextRect(AMsg, AHelper.FText.ResultingTextSettings,
      Screen.DesktopWidth);
    AHelper.FPopup.Size.Size := TSizeF.Create(R.Width + 20, R.Height + 20);
    AHelper.FText.Text := AMsg;
    AHelper.FPopup.PlacementTarget := ACtrl;
    AHelper.FPopup.Placement := APlacement;
    AHelper.FPopup.IsOpen := true;
    AHelper.FTimer.Enabled := false;
    AHelper.FTimer.Enabled := true;
  end;
end;

procedure TQPopupHint.ShowHint(const S: String;
  AHorzAlign, AVertAlign: TTextAlign);
var
  R, VKBounds: TRectF;
  LT: TPointF;
  AHelper: TQPopupHintHelper;
begin
  AHelper := Prepare;
  if Assigned(AHelper) then
  begin
    R := TextRect(S, AHelper.FText.ResultingTextSettings, Screen.DesktopWidth);
    AHelper.FPopup.Size.Size := TSizeF.Create(R.Width + 20, R.Height + 20);
    AHelper.FText.Text := S;
    AHelper.FPopup.PlacementTarget := nil;
    case AHorzAlign of
      TTextAlign.Center:
        LT.X := (Screen.Width - AHelper.FPopup.Width) / 2;
      TTextAlign.Leading:
        LT.X := 5;
      TTextAlign.Trailing:
        LT.X := (Screen.Width - 5 - AHelper.FPopup.Width);
    end;
    VKBounds := GetVKBounds;
    if VKBounds.IsEmpty then
    begin
      case AVertAlign of
        TTextAlign.Center:
          LT.Y := (Screen.Height - AHelper.FPopup.Height) / 2;
        TTextAlign.Leading:
          LT.Y := 5;
        TTextAlign.Trailing:
          LT.Y := Screen.Height - AHelper.FPopup.Height - 5;
      end;
    end
    else
    begin
      case AVertAlign of
        TTextAlign.Center:
          LT.Y := (VKBounds.Top - AHelper.FPopup.Height) / 2;
        TTextAlign.Leading:
          LT.Y := 5;
        TTextAlign.Trailing:
          LT.Y := VKBounds.Top - AHelper.FPopup.Height - 5;
      end;
    end;
    if LT.X < 1 then
      assert(LT.X > 0);
    AHelper.FPopup.PlacementRectangle.Rect :=
      RectF(LT.X, LT.Y, LT.X + AHelper.FPopup.Width,
      LT.Y + AHelper.FPopup.Height);
    AHelper.FPopup.PlacementTarget := nil;
    AHelper.FPopup.Placement := TPlacement.Absolute;
    AHelper.FPopup.IsOpen := true;
    AHelper.FTimer.Enabled := false;
    AHelper.FTimer.Enabled := true;
  end;
end;

procedure TQPopupHint.ShowHint(ARect: TRectF; const AMsg: String);
var
  R: TRectF;
  AHelper: TQPopupHintHelper;
begin
  AHelper := Prepare;
  if Assigned(AHelper) then
  begin
    R := TextRect(AMsg, AHelper.FText.ResultingTextSettings,
      Screen.DesktopWidth);
    AHelper.FPopup.Size.Size := TSizeF.Create(R.Width + 20, R.Height + 20);
    AHelper.FText.Text := AMsg;
    AHelper.FPopup.PlacementTarget := nil;
    if AHelper.FPopup.Height < ARect.Height then
      AHelper.FPopup.Height := ARect.Height;
    if AHelper.FPopup.Width < ARect.Width then
      AHelper.FPopup.Width := ARect.Width;
    if ARect.Left + AHelper.FPopup.Width > Screen.DesktopWidth then
      ARect.Left := Screen.DesktopWidth - AHelper.FPopup.Width;
    if ARect.Top + AHelper.FPopup.Height > Screen.DesktopHeight then
      ARect.Top := Screen.DesktopHeight - AHelper.FPopup.Height;
    AHelper.FPopup.HorizontalOffset := ARect.Left;
    AHelper.FPopup.VerticalOffset := ARect.Top;
    AHelper.FPopup.IsOpen := true;
    AHelper.FTimer.Enabled := false;
    AHelper.FTimer.Enabled := true;
  end;
end;

function TQPopupHint.TextRect(const S: String; ASettings: TTextSettings;
  AMaxWidth: Single): TRectF;
var
  ALayout: TTextLayout;
begin
  ALayout := textlayout;
  Result := TRectF.Create(0, 0, AMaxWidth, MaxInt);
  ALayout.BeginUpdate;
  ALayout.Font.Assign(ASettings.Font);
  ALayout.HorizontalAlign := ASettings.HorzAlign;
  ALayout.WordWrap := ASettings.WordWrap;
  ALayout.Text := S;
  ALayout.TopLeft := Result.TopLeft;
  ALayout.MaxSize := Result.BottomRight;
  ALayout.EndUpdate;
  Result := ALayout.TextRect;
end;

procedure TQPopupHint.ShowHint(APos: TPointF; const AMsg: String);
var
  R: TRectF;
  AHelper: TQPopupHintHelper;
begin
  AHelper := Prepare;
  if Assigned(AHelper) then
  begin
    R := TextRect(AMsg, AHelper.FText.ResultingTextSettings,
      Screen.DesktopWidth);
    AHelper.FPopup.Size.Size := TSizeF.Create(R.Width + 20, R.Height + 20);
    AHelper.FText.Text := AMsg;
    AHelper.FPopup.PlacementTarget := nil;
    AHelper.FPopup.HorizontalOffset := APos.X;
    AHelper.FPopup.VerticalOffset := APos.Y;
    AHelper.FPopup.IsOpen := true;
    AHelper.FTimer.Enabled := false;
    AHelper.FTimer.Enabled := true;
  end;
end;

{ TQPopupHintHelper }

constructor TQPopupHintHelper.Create(AOwner: TComponent);
begin
  inherited;
  FPopup := TPopup.Create(Self);
  FPopup.Margins.Rect := RectF(5, 5, 5, 5);
  FBackground := TRectangle.Create(FPopup);
  FBackground.Parent := FPopup;
  FBackground.Align := TAlignLayout.Client;
  FBackground.Fill.Color := PopupHint.HintBackgroundColor;
  FBackground.Stroke.Color := PopupHint.HintFrameColor;
  FText := TLabel.Create(FPopup);
  FText.Parent := FBackground;
  FText.Align := TAlignLayout.Client;
  FText.Margins.Rect := RectF(5, 5, 5, 5);
  FText.StyledSettings := [];
  FText.Font.Size := 14;
  FText.FontColor := PopupHint.HintTextColor;
  FText.TextSettings.HorzAlign := TTextAlign.Center;
  FTimer := TTimer.Create(FPopup);
  FTimer.OnTimer := DoHideHint;
  FTimer.Interval := PopupHint.HintPause;
  FTimer.Enabled := false;
  FVKMsgId := TMessageManager.DefaultManager.SubscribeToMessage
    (TVKStateChangeMessage, DoVKVisibleChanged);
end;

destructor TQPopupHintHelper.Destroy;
begin
  TMessageManager.DefaultManager.Unsubscribe(TVKStateChangeMessage, FVKMsgId);
  inherited;
end;

procedure TQPopupHintHelper.DoHideHint(ASender: TObject);
begin
  FPopup.IsOpen := false;
  FTimer.Enabled := false;
end;

procedure TQPopupHintHelper.DoVKVisibleChanged(const Sender: TObject;
  const Msg: System.Messaging.TMessage);
var
  AVKMsg: TVKStateChangeMessage absolute Msg;
  R, KR: TRectF;
begin
  if AVKMsg.KeyboardVisible then // ¼üÅÌ¿É¼û
  begin
    R := FPopup.PlacementRectangle.Rect;
    KR := TRectF.Create(AVKMsg.KeyboardBounds);
    if R.Bottom > KR.Top then
    begin
      OffsetRect(R, 0, KR.Top - R.Bottom-R.Height);
      FPopup.PlacementRectangle.Rect := R;
    end;
  end;
end;

initialization

PopupHint := TQPopupHint.Create;

finalization

{$IFDEF AUTOREFCOUNT}
  PopupHint := nil;
{$ELSE}
  PopupHint.DisposeOf;
{$ENDIF}

end.
