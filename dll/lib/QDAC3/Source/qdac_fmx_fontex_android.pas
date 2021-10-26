unit qdac_fmx_fontex_android;

interface

implementation

uses Classes, Sysutils, Types, FMX.FontGlyphs, System.IOUtils, System.Rtti
{$IFDEF MSWINDOWS}, Windows, {$ENDIF}
{$IFDEF POSIX}
, Posix.SysMMan, Posix.UniStd
{$ENDIF}
{$IFDEF ANDROID}
    , Androidapi.Helpers, Androidapi.JNI.JavaTypes, FMX.FontGlyphs.Android,
  Androidapi.JNI.GraphicsContentViewText
{$ENDIF};
{$IFDEF ANDROID}

type
  PJPaint = ^JPaint;

  TAndroidFontGlyphManagerHelper = class(TAndroidFontGlyphManager)
  public
    property CurrentSettings;
  end;

  TAndroidFontManagerHacker = class
  private
    FPaint: PJPaint;
    // Current metrics
    FTop: PInteger;
    FAscent: PInteger;
    FDescent: PInteger;
    FBottom: PInteger;
    FLeading: PInteger;
    FCurrentSettings: TFontSettings;
    FFontPath: String;
    procedure DoLoadResource;
    procedure HookVirtualMethod(AClass: TClass; AOld, ANew: Pointer);
  public
    constructor Create; overload;
    destructor Destroy; override;
    property FontPath: String read FFontPath write FFontPath;
  end;

var
  AndroidFontHacker: TAndroidFontManagerHacker = nil;
{$ENDIF}
  { TAndroidFontManagerHacker }

constructor TAndroidFontManagerHacker.Create;
var
  AContext: TRttiContext;
  AType: TRttiType;
  AField: TRttiField;
  ABase: PByte;
  ACurrent: TAndroidFontGlyphManager;
begin
  inherited;
  FFontPath := TPath.GetDocumentsPath + PathDelim;
  AContext := TRttiContext.Create;
  ACurrent := TFontGlyphManager.Current as TAndroidFontGlyphManager;
  AType := AContext.GetType(ACurrent.ClassType);
  if Assigned(AType) then
  begin
    ABase := PByte(TFontGlyphManager.Current);
    // We are looking for private fields for TAndroidFontGlyphManager
    AField := AType.GetField('FPaint');
    if not Assigned(AField) then
      Exit;
    FPaint := PJPaint(ABase + AField.Offset);
    AField := AType.GetField('FTop');
    if not Assigned(AField) then
      Exit;
    FTop := PInteger(ABase + AField.Offset);
    AField := AType.GetField('FAscent');
    if not Assigned(AField) then
      Exit;
    FAscent := PInteger(ABase + AField.Offset);
    AField := AType.GetField('FAscent');
    if not Assigned(AField) then
      Exit;
    FAscent := PInteger(ABase + AField.Offset);

    AField := AType.GetField('FDescent');
    if not Assigned(AField) then
      Exit;
    FDescent := PInteger(ABase + AField.Offset);

    AField := AType.GetField('FBottom');
    if not Assigned(AField) then
      Exit;
    FBottom := PInteger(ABase + AField.Offset);

    AField := AType.GetField('FLeading');
    if not Assigned(AField) then
      Exit;
    FLeading := PInteger(ABase + AField.Offset);
    HookVirtualMethod(TFontGlyphManager.Current.ClassType,
      @TAndroidFontGlyphManagerHelper.LoadResource,
      @TAndroidFontManagerHacker.DoLoadResource);
  end;
end;

destructor TAndroidFontManagerHacker.Destroy;
begin

  inherited;
end;

procedure TAndroidFontManagerHacker.DoLoadResource;
var
  TypefaceFlag: Integer;
  Typeface: JTypeface;
  FamilyName: JString;
  Metrics: JPaint_FontMetricsInt;
  FontFile: String;
begin
  AndroidFontHacker.FPaint^.setAntiAlias(True);
  with TAndroidFontGlyphManagerHelper(TFontGlyphManager.Current) do
  begin
    AndroidFontHacker.FPaint^.setTextSize(CurrentSettings.Size *
      CurrentSettings.Scale);
    AndroidFontHacker.FPaint^.setARGB(255, 255, 255, 255);
    if TOSVersion.Check(4, 0) then
      AndroidFontHacker.FPaint^.setHinting(TJPaint.JavaClass.HINTING_ON);
    // Font
    try
      FamilyName := StringToJString(CurrentSettings.Family);
      if not CurrentSettings.Style.Slant.IsRegular and
        not CurrentSettings.Style.Weight.IsRegular then
        TypefaceFlag := TJTypeface.JavaClass.BOLD_ITALIC
      else if not CurrentSettings.Style.Weight.IsRegular then
        TypefaceFlag := TJTypeface.JavaClass.BOLD
      else if not CurrentSettings.Style.Slant.IsRegular then
        TypefaceFlag := TJTypeface.JavaClass.ITALIC
      else
        TypefaceFlag := TJTypeface.JavaClass.NORMAL;
      // Fix for support custom font
      FontFile := AndroidFontHacker.FFontPath + CurrentSettings.Family;
      if FileExists(FontFile + '.ttf') then
        Typeface := TJTypeface.JavaClass.createFromFile
          (StringToJString(FontFile + '.ttf'))
      else if FileExists(FontFile + '.otf') then
        Typeface := TJTypeface.JavaClass.createFromFile
          (StringToJString(FontFile + '.ttf'))
      else
        Typeface := TJTypeface.JavaClass.Create(FamilyName, TypefaceFlag);
      // Custom font support done
      AndroidFontHacker.FPaint^.setTypeface(Typeface);
      try
        Metrics := AndroidFontHacker.FPaint^.getFontMetricsInt;
        //
        AndroidFontHacker.FTop^ := Metrics.top;
        AndroidFontHacker.FAscent^ := Metrics.ascent;
        AndroidFontHacker.FDescent^ := Metrics.descent;
        AndroidFontHacker.FBottom^ := Metrics.bottom;
        AndroidFontHacker.FLeading^ := Metrics.leading;
      finally
        Metrics := nil;
      end;
    finally
      FamilyName := nil;
      Typeface := nil;
    end;
  end;
end;

procedure TAndroidFontManagerHacker.HookVirtualMethod(AClass: TClass;
  AOld, ANew: Pointer);
var
  pClass: PPointer;
  pPage: Pointer;
  dw: DWORD;
  AContext: TRttiContext;
  AType: TRttiInstanceType;
  APageSize: Longint;
begin
  pClass := PPointer(AClass);
  while Assigned(pClass^) and (pClass^ <> AOld) do
    Inc(pClass);
  if Assigned(pClass) then
  begin
{$IFDEF MSWINDOWS}
    VirtualProtect(Pointer(pClass), SizeOf(Pointer),
      PAGE_EXECUTE_READWRITE, @dw);
    pClass^ := ANew;
    VirtualProtect(Pointer(pClass), SizeOf(Pointer), dw, @dw);
{$ELSE}
    APageSize := sysconf(_SC_PAGESIZE);
    pPage := Pointer(UIntPtr(pClass) and (not(APageSize - 1)));
    if mprotect(pPage, APageSize, PROT_READ or PROT_WRITE) = 0 then
    begin
      PPointer(pClass)^ := ANew;
      mprotect(pPage, APageSize, PROT_READ);
    end
    else
      RaiseLastOSError;
{$ENDIF}
  end;
end;

initialization

AndroidFontHacker := TAndroidFontManagerHacker.Create;

finalization

FreeAndNil(AndroidFontHacker);

end.
