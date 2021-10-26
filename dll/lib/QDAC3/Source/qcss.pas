unit qcss;

interface

uses classes, sysutils, variants, qstring, Rtti;

type
  TQCSSObject = class
  protected
    FName: QStringW;
    FItems: TStringList;
    function GetCount: Integer;
    function GetItemNames(const AIndex: Integer): QStringW;
    function ItemList: TStrings;
    function GetText: String; virtual; abstract;
  public
    constructor Create; overload;
    destructor Destroy; override;
    procedure Clear;
    function HasName(const AName: QStringW): Boolean;
    function IndexOfName(const AName: QStringW): Integer; virtual;
    property Name: QStringW read FName;
    property Text: String read GetText;
  end;

  TQCSSAttrValueType = (aptBoolean, aptInteger, aptFloat, aptDateTime,
    aptUnitValue, aptConst, aptString);

  TQCSSValueParam = record
    ParamType: TQCSSAttrValueType;
    Value: variant;
    UnitName: QStringW;
  end;

  TQCSSAttrParams = array of TQCSSValueParam;
  TQCSSAttrItems = class;
  TQCSSStyle = class;
  TQCSS = class;

  TQCSSAttrValue = class
  private
    function GetIsFunction: Boolean;
    function GetText: QStringW;
  protected
    FName: QStringW;
    FParams: TQCSSAttrParams;
    FOwner: TQCSSAttrItems;
  public
    constructor Create(AValue: QStringW); overload;
    property IsFunction: Boolean read GetIsFunction;
    property Name: QStringW read FName;
    property Params: TQCSSAttrParams read FParams;
    property Text: QStringW read GetText;
    property Owner: TQCSSAttrItems read FOwner;
  end;

  TQCSSAttrItems = class(TQCSSObject)
  private
    function GetValues(const AIndex: Integer): TQCSSAttrValue;
  protected
    FOwner: TQCSSStyle;
    function GetText: String; override;
  public
    constructor Create(AOwner: TQCSSStyle); overload;
    function IndexOfName(const AName: QStringW): Integer; override;
    property Values[const AIndex: Integer]: TQCSSAttrValue
      read GetValues; default;
    property Names[const AIndex: Integer]: QStringW read GetItemNames;
    property AttrCount: Integer read GetCount;
  end;

  TQCSSStyle = class(TQCSSObject)
  protected
    FOwner: TQCSS;
    function GetItems(AIndex: Integer): TQCSSAttrItems;
    function GetText: QStringW; override;
  public
    constructor Create(AOwner: TQCSS); overload;
    function Parse(const S: QStringW): Boolean; overload;
    function Parse(var ps: PQCharW; L: Integer): Boolean; overload;
    function AttrByName(const AName: QStringW): TQCSSAttrItems;
    property Count: Integer read GetCount;
    property Items[AIndex: Integer]: TQCSSAttrItems read GetItems; default;
  end;

  TQCSSAttrHandler = procedure(AObject: TObject; Attr: TQCSSAttrValue)
    of object;

  TQCSSAttrDispatchItem = class
  protected
    FHandler: TQCSSAttrHandler;
  public
    constructor Create(AHandler: TQCSSAttrHandler); overload;
  end;

  TQCSS = class(TQCSSObject)
  protected
    FDispatcher: TStringList;
    FStylingObject: TObject;
    function GetItems(AIndex: Integer): TQCSSStyle;
    function GetText: QStringW; override;
    procedure DispatchAttrValue(Attr: TQCSSAttrItems;
      AObject: TObject); virtual;
    function FindHandler(const AName: QStringW): TQCSSAttrHandler;
    procedure DoBeforeStyling; virtual;
    procedure DoAfterStyled; virtual;
    property StyingObject: TObject read FStylingObject;
  public
    constructor Create; overload;
    destructor Destroy; override;
    function Parse(const S: QStringW): Boolean; overload;
    function Parse(var ps: PQCharW; L: Integer): Boolean; overload;
    procedure LoadFromStream(AStream: TStream);
    procedure LoadFromFile(const AFileName: QStringW);
    procedure ApplyStyle(const AStyleName: QStringW; const AObject: TObject);
    function Register(const AttrName: QStringW;
      AHandler: TQCSSAttrHandler): Boolean;
    procedure Unregister(const AttrName: QStringW; AHandler: TQCSSAttrHandler);
    function StyleByName(const AName: QStringW): TQCSSStyle;
    property Count: Integer read GetCount;
    property Items[AIndex: Integer]: TQCSSStyle read GetItems; default;
  end;

implementation

{ TQCSSObject }

function TQCSSObject.ItemList: TStrings;
begin
  if not Assigned(FItems) then
  begin
    FItems := TStringList.Create;
    FItems.Sorted := true;
    FItems.Duplicates := dupIgnore;
  end;
  Result := FItems;
end;

procedure TQCSSObject.Clear;
var
  I: Integer;
  AObj: TObject;
begin
  if Assigned(FItems) then
  begin
    for I := 0 to FItems.Count - 1 do
    begin
      AObj := FItems.Objects[I];
      if Assigned(AObj) then
        FreeObject(AObj);
    end;
    FItems.Clear;
  end;
end;

constructor TQCSSObject.Create;
begin
  inherited;
end;

destructor TQCSSObject.Destroy;
begin
  Clear;
  if Assigned(FItems) then
    FreeObject(FItems);
  inherited;
end;

function TQCSSObject.GetCount: Integer;
begin
  if Assigned(FItems) then
    Result := FItems.Count
  else
    Result := 0;
end;

function TQCSSObject.GetItemNames(const AIndex: Integer): QStringW;
begin
  if Assigned(FItems) and (AIndex >= 0) and (AIndex < FItems.Count) then
  begin
    Result := FItems[AIndex];
    Result := DecodeTokenW(Result, '(', '"', false, false);
  end
  else
    raise EListError.Create('Out of range');
end;

function TQCSSObject.HasName(const AName: QStringW): Boolean;
begin
  Result := IndexOfName(AName) <> -1;
end;

function TQCSSObject.IndexOfName(const AName: QStringW): Integer;
begin
  if not(Assigned(FItems) and FItems.Find(AName, Result)) then
    Result := -1;
end;

{ TQCSS }

function TQCSSStyle.AttrByName(const AName: QStringW): TQCSSAttrItems;
var
  I: Integer;
begin
  I := IndexOfName(AName);
  if I <> -1 then
    Result := Items[I]
  else
    Result := nil;
end;

constructor TQCSSStyle.Create(AOwner: TQCSS);
begin
  inherited Create;
  FOwner := AOwner;
end;

function TQCSSStyle.GetItems(AIndex: Integer): TQCSSAttrItems;
begin
  if Assigned(FItems) and (AIndex >= 0) and (AIndex < FItems.Count) then
    Result := TQCSSAttrItems(FItems.Objects[AIndex])
  else
    raise EListError.Create('Out of range');
end;

function TQCSSStyle.GetText: QStringW;
var
  I: Integer;
begin
  Result := Name + '{' + SLineBreak;
  for I := 0 to Count - 1 do
    Result := Result + Items[I].Text + ';' + SLineBreak;
  Result := Result + '}';
end;

function TQCSSStyle.Parse(var ps: PQCharW; L: Integer): Boolean;
var
  AName: String;
  pe, pts: PQCharW;
  AChild: TQCSSAttrItems;
  function DecodeStatement: String;
  var
    pl: PQCharW;
  begin
    SkipSpaceW(ps);
    pl := ps;
    Result := '';
    while (ps^ <> ';') and (ps < pe) do
    begin
      if ps^ = '/' then
      begin
        Inc(ps);
        if ps^ = '/' then // //
        begin
          Result := Result + StrDupX(pl, ps - pl - 1) + ' ';
          SkipLineW(ps);
          pl := ps;
        end
        else if ps^ = '*' then // /*
        begin
          Result := Result + StrDupX(pl, ps - pl - 1) + ' ';
          Inc(ps);
          while ps < pe do
          begin
            if ps^ = '*' then
            begin
              Inc(ps);
              if ps^ = '/' then
              begin
                Inc(ps);
                pl := ps;
                break;
              end;
            end
            else
              Inc(ps);
          end;
        end;
      end
      else
        Inc(ps);
    end;
    if ps <> pl then
      Result := Result + StrDupX(pl, ps - pl);
    if ps^ = ';' then
    begin
      Inc(ps);
      SkipSpaceW(ps);
    end;
  end;

  function DecodeAttr: Boolean;
  var
    pl: PQCharW;
    ALine: QStringW;
    Attr: TQCSSAttrValue;
  begin
    ALine := DecodeStatement;
    Result := (ALine <> '}') and (ps^ <> #0) and (Length(ALine)>0);
    if Result then
    begin
      pl := PQCharW(ALine);
      while pl^ <> #0 do
      begin
        AName := DecodeTokenW(pl, ':', '"', true, true);
        if Length(AName) > 0 then
        begin
          AChild := TQCSSAttrItems.Create(Self);
          AChild.FName := AName;
          with AChild.ItemList do
          begin
            BeginUpdate;
            try
              while pl^ <> #0 do
              begin
                Attr := TQCSSAttrValue.Create(DecodeTokenW(pl, ' '#9#10#13, '"',
                  true, true));
                Attr.FOwner := AChild;
                AddObject(Attr.Name, Attr);
              end;
            finally
              EndUpdate;
            end;
            ItemList.AddObject(AChild.FName, AChild);
          end;
        end;
      end;
    end;
  end;

begin
  if L > 0 then
  begin
    pe := ps + L;
    SkipSpaceW(ps);
    // 跳过前面的空白，取名称
    pts := ps;
    SkipUntilW(ps, '{');
    FName := DeleteSideCharsW(StrDupX(pts, ps - pts), #9' '#10#13);
    Inc(ps); //
    SkipSpaceW(ps);
    // 解析剩下的属性
    while DecodeAttr do;
    if ps^ = '}' then
    begin
      Inc(ps);
      SkipSpaceW(ps);
    end;
    Result := true;
  end
  else
    Result := false;
end;

function TQCSSStyle.Parse(const S: QStringW): Boolean;
var
  ps: PQCharW;
begin
  ps := PQCharW(S);
  Result := Parse(ps, Length(S));
end;

{ TQCSS }

procedure TQCSS.ApplyStyle(const AStyleName: QStringW; const AObject: TObject);
var
  AStyle: TQCSSStyle;
  I: Integer;
begin
  AStyle := StyleByName(AStyleName);
  if Assigned(AStyle) then
  begin
    FStylingObject := AObject;
    try
      DoBeforeStyling;
      for I := 0 to AStyle.Count - 1 do
        DispatchAttrValue(AStyle[I], AObject);
    finally
      DoAfterStyled;
      FStylingObject := nil;
    end;
  end;
end;

constructor TQCSS.Create;
begin
  inherited;
  FDispatcher := TStringList.Create;
  FDispatcher.Sorted := true;
end;

destructor TQCSS.Destroy;
var
  I: Integer;
begin
  for I := 0 to FDispatcher.Count - 1 do
    FreeObject(FDispatcher.Objects[I]);
  FreeObject(FDispatcher);
  inherited;
end;

procedure TQCSS.DispatchAttrValue(Attr: TQCSSAttrItems; AObject: TObject);
var
  AHandler: TQCSSAttrHandler;
  I: Integer;
begin
  AHandler := FindHandler(Attr.Name);
  if Assigned(AHandler) then
  begin
    for I := 0 to Attr.AttrCount - 1 do
      AHandler(AObject, Attr[I]);
  end;
end;

procedure TQCSS.DoAfterStyled;
begin

end;

procedure TQCSS.DoBeforeStyling;
begin

end;

function TQCSS.FindHandler(const AName: QStringW): TQCSSAttrHandler;
var
  I: Integer;
begin
  if FDispatcher.Find(AName, I) then
    Result := TQCSSAttrDispatchItem(FDispatcher.Objects[I]).FHandler
  else
    Result := nil;
end;

function TQCSS.GetItems(AIndex: Integer): TQCSSStyle;
begin
  if Assigned(FItems) and (AIndex >= 0) and (AIndex < FItems.Count) then
    Result := TQCSSStyle(FItems.Objects[AIndex])
  else
    raise EListError.Create('Out of range');
end;

function TQCSS.GetText: QStringW;
var
  I: Integer;
begin
  Result := '';
  for I := 0 to Count - 1 do
    Result := Result + Items[I].Text + SLineBreak;
end;

procedure TQCSS.LoadFromFile(const AFileName: QStringW);
begin
  Parse(LoadTextW(AFileName));
end;

procedure TQCSS.LoadFromStream(AStream: TStream);
begin
  Parse(LoadTextW(AStream));
end;

function TQCSS.Parse(var ps: PQCharW; L: Integer): Boolean;
var
  pe: PQCharW;
  AItem: TQCSSStyle;
begin
  if L = -1 then
    L := StrLen(ps);
  pe := ps + L;
  Clear;
  Result := true;
  while ps < pe do
  begin
    AItem := TQCSSStyle.Create(Self);
    if AItem.Parse(ps, pe - ps) then
      ItemList.AddObject(AItem.Name, AItem)
    else
    begin
      Result := false;
      FreeObject(AItem);
    end;
  end;
end;

function TQCSS.Register(const AttrName: QStringW;
  AHandler: TQCSSAttrHandler): Boolean;
begin
  Result := Assigned(AHandler) and (FDispatcher.IndexOfName(AttrName) = -1);
  if Result then
    FDispatcher.AddObject(AttrName, TQCSSAttrDispatchItem.Create(AHandler))
end;

function TQCSS.StyleByName(const AName: QStringW): TQCSSStyle;
var
  I: Integer;
begin
  I := IndexOfName(AName);
  if I <> -1 then
    Result := Items[I]
  else
    Result := nil;
end;

procedure TQCSS.Unregister(const AttrName: QStringW;
  AHandler: TQCSSAttrHandler);
var
  AIdx: Integer;
begin
  AIdx := FDispatcher.IndexOfName(AttrName);
  if AIdx <> -1 then
  begin
    FreeObject(FDispatcher.Objects[AIdx]);
    FDispatcher.Delete(AIdx);
  end;
end;

function TQCSS.Parse(const S: QStringW): Boolean;
var
  ps: PQCharW;
begin
  ps := PQCharW(S);
  Result := Parse(ps, Length(S));
end;

{ TQCSSAttrItems }

constructor TQCSSAttrItems.Create(AOwner: TQCSSStyle);
begin
  inherited Create;
  FOwner := AOwner;
end;

function TQCSSAttrItems.GetText: String;
var
  I: Integer;
begin
  Result := Name + ':';
  for I := 0 to AttrCount - 1 do
    Result := Result + Values[I].Text + ' ';
end;

function TQCSSAttrItems.GetValues(const AIndex: Integer): TQCSSAttrValue;
begin
  if Assigned(FItems) and (AIndex >= 0) and (AIndex < FItems.Count) then
    Result := TQCSSAttrValue(FItems.Objects[AIndex])
  else
    raise EListError.Create('Out of range');
end;

function TQCSSAttrItems.IndexOfName(const AName: QStringW): Integer;
begin
  if Assigned(FItems) then
  begin
    if not FItems.Find(AName, Result) then
    begin
      if Names[Result] <> AName then
        Result := -1;
    end;
  end
  else
    Result := -1;
end;

{ TQCSSAttrValue }

constructor TQCSSAttrValue.Create(AValue: QStringW);
var
  C: Integer;
  pParam: PQCharW;
  procedure ProcessValue(const AVal: QStringW);
  var
    dVal: Extended;
    iVal: Int64 absolute dVal;
    dtVal: TDateTime absolute iVal;
    bVal: Boolean absolute iVal;
    lVal: QStringW;
    pVal: PQCharW;
  begin
    lVal := LowerCase(AVal);
    with FParams[C] do
    begin
      if lVal = 'true' then
      begin
        ParamType := TQCSSAttrValueType.aptBoolean;
        Value := true
      end
      else if lVal = 'false' then
      begin
        ParamType := TQCSSAttrValueType.aptBoolean;
        Value := false;
      end
      else if TryStrToInt64(AVal, iVal) then
      begin
        ParamType := TQCSSAttrValueType.aptInteger;
        Value := iVal;
      end
      else if TryStrToFloat(AVal, dVal) then
      begin
        ParamType := TQCSSAttrValueType.aptFloat;
        Value := dVal
      end
      else // Str/Num+Unit
      begin
        pVal := PQCharW(AVal);
        if (pVal^ = '"') or (pVal^ = '''') then
        begin
          lVal := JavaUnescape(DequotedStrW(AVal, pVal^), false);
          if TryStrToDateTime(AVal, dtVal) or ParseDateTime(PQCharW(AVal), dtVal)
          then
          begin
            ParamType := TQCSSAttrValueType.aptDateTime;
            Value := dtVal;
          end
          else
          begin
            ParamType := TQCSSAttrValueType.aptString;
            Value := lVal;
          end;
        end
        else if ParseNumeric(pVal, dVal) then
        begin
          ParamType := TQCSSAttrValueType.aptUnitValue;
          Value := dVal;
          UnitName := pVal;
        end
        else
        begin
          ParamType := TQCSSAttrValueType.aptConst;
          Value := AVal;
        end;
      end;
    end;
  end;

begin
  inherited Create;
  C := 0;
  FName := DecodeTokenW(AValue, '(', '"', false, true);
  if Length(AValue) > 0 then
  begin
    pParam := PQCharW(AValue);
    repeat
      if Length(FParams) = C then
        SetLength(FParams, C + 4); // 4个参数最多每次加
      ProcessValue(DecodeTokenW(pParam, ',)', '"', true));
      Inc(C);
    until (pParam^ = ')') or (pParam^ = #0);
  end;
  SetLength(FParams, C);
end;

function TQCSSAttrValue.GetIsFunction: Boolean;
begin
  Result := Length(FParams) > 0;
end;

function TQCSSAttrValue.GetText: QStringW;
var
  I: Integer;
begin
  Result := FName;
  if Length(FParams) > 0 then
  begin
    Result := Result + '(';
    for I := 0 to High(FParams) do
    begin
      with FParams[I] do
      begin
        case ParamType of
          aptBoolean, aptInteger, aptFloat:
            Result := Result + VarToStr(Value);
          aptDateTime:
            Result := Result + '''' + FormatDateTime('yyyy-mm-dd hh:nn:ss',
              TDateTime(Value)) + '''';
          aptUnitValue:
            Result := Result + VarToStr(Value) + UnitName;
          aptConst:
            Result := Result + Value;
          aptString:
            Result := Result + QuotedStrW(Value);
        end;
      end;
      Result := Result + ',';
    end;
    SetLength(Result, Length(Result) - 1);
    Result := Result + ')';
  end;
end;

{ TQCSSAttrDispatchItem }

constructor TQCSSAttrDispatchItem.Create(AHandler: TQCSSAttrHandler);
begin
  inherited Create;
  FHandler := AHandler;
end;

end.
