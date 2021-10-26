unit qdac.htmlparser;

interface

uses classes, sysutils, qstring, windows {$IFDEF UNICODE},
  Generics.Collections{$ENDIF};
{$I QDAC.INC}

{ 本单元是一个简单的HTML解析单元，不支持复杂的包含脚本的内容的解析，只是简单的解析
  HTML 的标签和属性
  //已知在解析部分网页是有问题
}
type
  TQHTMLTag = class;

  TQTagAttr = class
  private
    FValue: QStringW;
  protected
  public
    constructor Create; overload;
    destructor Destroy; override;
    property Value: QStringW read FValue write FValue;
  end;

  TQTagAttributes = class
  private
    FItems: TStringList;
    function GetCount: Integer;
    function GetItems(AIndex: Integer): TQTagAttr;
    function GetNames(AIndex: Integer): QStringW;
    function GetValues(AIndex: Integer): QStringW;
    procedure SetValues(AIndex: Integer; const Value: QStringW);
    property Items[AIndex: Integer]: TQTagAttr read GetItems;
  public
    constructor Create(AOwner: TQHTMLTag); overload;
    destructor Destroy; override;
    procedure Add(const AName, AValue: QStringW);
    procedure Delete(AIndex: Integer);
    procedure Clear;
    function ValueByName(const AName: QStringW): QStringW;
    function HasAttr(const AName: QStringW): Boolean;
    procedure BeginUpdate;
    procedure EndUpdate;
    property Count: Integer read GetCount;
    property Names[AIndex: Integer]: QStringW read GetNames;
    property Values[AIndex: Integer]: QStringW read GetValues write SetValues;
  end;
{$IF RTLVersion>=21}

  TQTagItems = TList<TQHTMLTag>;
{$ELSE}
  TQTagItems = TList;
{$IFEND}
  TQHtmlTagForEachProc = procedure(AHtmlTag: TQHTMLTag; AParam: IntPtr)
    of object;

  TQHTMLTag = class
  private
    FName: QStringW;
    FInnerHtml: QStringW;
    FAttrs: TQTagAttributes;
    FItems: TQTagItems;
    FParent: TQHTMLTag;
    function GetCount: Integer;
    function GetItems(AIndex: Integer): TQHTMLTag;
    function GetAttrValue(AName: QStringW): QStringW;
    function GetInnerHtml: QStringW;
    function GetPlanText: QStringW;
    procedure SetAttrValue(AName: QStringW; const Value: QStringW);
  public
    constructor Create; overload;
    destructor Destroy; override;
    function Add(const AName: QStringW): TQHTMLTag;
    procedure Delete(AIndex: Integer);
    procedure Clear;
    function TryParse(var s: PQCharW; l: Integer): Boolean; overload;
    function TryParse(s: QStringW): Boolean; overload;
    procedure Parse(s: QStringW);
    procedure ForEach(ACallback: TQHtmlTagForEachProc; ANest: Boolean;
      AParam: IntPtr);
    function IsChildOf(ATag: TQHTMLTag): Boolean;
    function IsParentOf(ATag: TQHTMLTag): Boolean;
    function ItemByName(AName: QStringW): TQHTMLTag;
    function IndexOf(AName: QStringW; AStartIndex: Integer = 0): Integer;
    function ItemByPath(APath: QStringW): TQHTMLTag;
    property Name: QStringW read FName write FName;
    property InnerHtml: QStringW read GetInnerHtml write FInnerHtml;
    property Attrs: TQTagAttributes read FAttrs;
    property Parent: TQHTMLTag read FParent;
    property Items[AIndex: Integer]: TQHTMLTag read GetItems; default;
    property Count: Integer read GetCount;
    property PlanText: QStringW read GetPlanText;
    property AttrValue[AName: QStringW]: QStringW read GetAttrValue
      write SetAttrValue;
  end;

implementation

resourcestring
  SBadHtmlText = '不受支持的 HTML 文本格式';
  { TQTagAttribute }

constructor TQTagAttr.Create;
begin
end;

destructor TQTagAttr.Destroy;
begin
  inherited;
end;

{ TQTagAttributes }

procedure TQTagAttributes.Add(const AName, AValue: QStringW);
var
  Attr: TQTagAttr;
  AIdx: Integer;
begin
  if FItems.Find(AName, AIdx) then
    Attr := FItems.Objects[AIdx] as TQTagAttr
  else
  begin
    Attr := TQTagAttr.Create;
    FItems.AddObject(AName, Attr);
  end;
  Attr.FValue := AValue;
end;

procedure TQTagAttributes.BeginUpdate;
begin
  FItems.BeginUpdate;
end;

procedure TQTagAttributes.Clear;
var
  I: Integer;
begin
  for I := 0 to FItems.Count - 1 do
    FreeObject(FItems.Objects[I]);
  FItems.Clear;
end;

constructor TQTagAttributes.Create(AOwner: TQHTMLTag);
begin
  inherited Create;
  FItems := TStringList.Create;
  FItems.Sorted := True;
  FItems.Duplicates := dupIgnore;
  FItems.CaseSensitive := False; // HTML 不区分大小写
end;

procedure TQTagAttributes.Delete(AIndex: Integer);
begin
  FreeObject(FItems.Objects[AIndex]);
  FItems.Delete(AIndex);
end;

destructor TQTagAttributes.Destroy;
begin
  Clear;
  FreeAndNil(FItems);
  inherited;
end;

procedure TQTagAttributes.EndUpdate;
begin
  FItems.EndUpdate;
end;

function TQTagAttributes.GetCount: Integer;
begin
  Result := FItems.Count;
end;

function TQTagAttributes.GetItems(AIndex: Integer): TQTagAttr;
begin
  Result := FItems.Objects[AIndex] as TQTagAttr;
end;

function TQTagAttributes.GetNames(AIndex: Integer): QStringW;
begin
  Result := FItems[AIndex];
end;

function TQTagAttributes.GetValues(AIndex: Integer): QStringW;
begin
  Result := Items[AIndex].FValue;
end;

function TQTagAttributes.HasAttr(const AName: QStringW): Boolean;
var
  AIndex: Integer;
begin
  Result := FItems.Find(AName, AIndex);
end;

procedure TQTagAttributes.SetValues(AIndex: Integer; const Value: QStringW);
begin
  Items[AIndex].FValue := Value;
end;

function TQTagAttributes.ValueByName(const AName: QStringW): QStringW;
var
  AIndex: Integer;
begin
  if FItems.Find(AName, AIndex) then
    Result := Values[AIndex]
  else
    Result := '';
end;

{ TQHTMLTag }

function TQHTMLTag.Add(const AName: QStringW): TQHTMLTag;
begin
  Result := TQHTMLTag.Create;
  Result.FParent := Self;
  Result.FName := AName;
  SetLength(FInnerHtml, 0);
  FItems.Add(Result);
end;

procedure TQHTMLTag.Clear;
var
  I: Integer;
begin
  for I := 0 to FItems.Count - 1 do
    FreeObject(FItems[I]);
  FItems.Clear;
  SetLength(FInnerHtml, 0);
end;

constructor TQHTMLTag.Create;
begin
  inherited Create;
  FAttrs := TQTagAttributes.Create(Self);
  FItems := TQTagItems.Create;
end;

procedure TQHTMLTag.Delete(AIndex: Integer);
begin
  FreeObject(FItems[AIndex]);
  FItems.Delete(AIndex);
  SetLength(FInnerHtml, 0);
end;

destructor TQHTMLTag.Destroy;
begin
  FreeAndNil(FAttrs);
  Clear;
  inherited;
end;

procedure TQHTMLTag.ForEach(ACallback: TQHtmlTagForEachProc; ANest: Boolean;
  AParam: IntPtr);
  procedure DoEach(AParent: TQHTMLTag);
  var
    I: Integer;
  begin
    for I := 0 to AParent.Count - 1 do
    begin
      ACallback(AParent[I], AParam);
      if ANest then
        DoEach(AParent[I]);
    end;
  end;

begin
  DoEach(Self);
end;

function TQHTMLTag.GetAttrValue(AName: QStringW): QStringW;
begin
  if Attrs.HasAttr(AName) then
    Result := Attrs.ValueByName(AName)
  else if Assigned(FParent) then
    Result := FParent.GetAttrValue(AName)
  else
    Result := '';
end;

function TQHTMLTag.GetCount: Integer;
begin
  Result := FItems.Count;
end;

function TQHTMLTag.GetInnerHtml: QStringW;
var
  AHelper: TQStringCatHelperW;
  procedure BuildTag(ATag: TQHTMLTag);
  const
    HtmlTagStart: QStringW = '<';
    HtmlTagEnd: QStringW = '>';
    HtmlTagClose: QStringW = '</';
    HtmlTagEndClose: QStringW = '/>';
    SpaceChar: QCharW = ' ';
    EqualChar: QCharW = '=';
    DblQuoter: QCharW = '"';
  var
    I: Integer;
  begin
    if Length(ATag.Name) > 0 then
    begin
      AHelper.Cat(HtmlTagStart).Cat(ATag.Name);
      if ATag.Attrs.Count > 0 then
      begin
        for I := 0 to ATag.Attrs.Count - 1 do
          AHelper.Cat(SpaceChar).Cat(ATag.Attrs.Names[I]).Cat(EqualChar)
            .Cat(DblQuoter).Cat(HtmlEscape(ATag.Attrs.Values[I]))
            .Cat(DblQuoter);
      end;
      if (ATag.Count = 0) and (Length(ATag.FInnerHtml) = 0) then
      begin
        AHelper.Cat(HtmlTagEndClose).Cat(SLineBreak);
        Exit;
      end
      else
        AHelper.Cat(HtmlTagEnd).Cat(SLineBreak);
    end;
    if Length(ATag.FInnerHtml) > 0 then
      AHelper.Cat(ATag.FInnerHtml).Cat(SLineBreak)
    else
    begin
      for I := 0 to ATag.Count - 1 do
        BuildTag(ATag[I]);
    end;
    if Length(ATag.Name) > 0 then
      AHelper.Cat(HtmlTagClose).Cat(ATag.Name).Cat(HtmlTagEnd).Cat(SLineBreak);
  end;

begin
  if Length(FInnerHtml) = 0 then
  begin
    AHelper := TQStringCatHelperW.Create;
    try
      BuildTag(Self);
      AHelper.Back(Length(SLineBreak));
      FInnerHtml := AHelper.Value;
    finally
      FreeAndNil(AHelper);
    end;
  end;
  Result := FInnerHtml;
end;

function TQHTMLTag.GetItems(AIndex: Integer): TQHTMLTag;
begin
  Result := FItems[AIndex];
end;

function TQHTMLTag.GetPlanText: QStringW;
var
  AHelper: TQStringCatHelperW;
  procedure EncodePlanText(AParent: TQHTMLTag);
  var
    I: Integer;
    AItem: TQHTMLTag;
  begin
    if Length(AParent.Name) = 0 then
      AHelper.Cat(AParent.InnerHtml);
    for I := 0 to AParent.Count - 1 do
    begin
      AItem := AParent[I];
      if Length(AItem.Name) = 0 then
        AHelper.Cat(AItem.InnerHtml)
      else
        EncodePlanText(AItem);
    end;
  end;

begin
  AHelper := TQStringCatHelperW.Create;
  try
    EncodePlanText(Self);
    Result := AHelper.Value;
  finally
    FreeAndNil(AHelper);
  end;
end;

function TQHTMLTag.IndexOf(AName: QStringW; AStartIndex: Integer): Integer;
var
  I: Integer;
begin
  Result := -1;
  for I := AStartIndex to Count - 1 do
  begin
    if StrCmpW(PWideChar(Items[I].Name), PWideChar(AName), True) = 0 then
    begin
      Result := I;
      Break;
    end;
  end;
end;

function TQHTMLTag.IsChildOf(ATag: TQHTMLTag): Boolean;
var
  AParent: TQHTMLTag;
begin
  AParent := FParent;
  Result := False;
  while Assigned(AParent) do
  begin
    if AParent = ATag then
    begin
      Result := True;
      Break;
    end
    else
      AParent := AParent.Parent;
  end;
end;

function TQHTMLTag.IsParentOf(ATag: TQHTMLTag): Boolean;
begin
  Result := ATag.IsChildOf(Self);
end;

function TQHTMLTag.ItemByName(AName: QStringW): TQHTMLTag;
var
  I: Integer;
begin
  I := IndexOf(AName);
  if I <> -1 then
    Result := Items[I]
  else
    Result := nil;
end;

function TQHTMLTag.ItemByPath(APath: QStringW): TQHTMLTag;
var
  AToken: String;
  I: Integer;
const
  ADelimiter: PWideChar = '/';
begin
  AToken := DecodeTokenW(APath, ADelimiter, #0, True, True);
  I := IndexOf(AToken);
  Result := nil;
  while I <> -1 do
  begin
    if Length(APath) > 0 then
    begin
      Result := Items[I].ItemByPath(APath);
      if not Assigned(Result) then
        I := IndexOf(AToken, I + 1);
    end
    else
    begin
      Result := Items[I];
      Break;
    end;
  end;
end;

procedure TQHTMLTag.Parse(s: QStringW);
var
  p: PQCharW;
begin
  p := PQCharW(s);
  if not TryParse(p, Length(s)) then
    raise Exception.Create(SBadHtmlText);
end;

procedure TQHTMLTag.SetAttrValue(AName: QStringW; const Value: QStringW);
begin
  Attrs.Add(AName, Value);
end;

function TQHTMLTag.TryParse(s: QStringW): Boolean;
var
  p: PQCharW;
begin
  p := PQCharW(s);
  Result := TryParse(p, s.Length);
end;

function TQHTMLTag.TryParse(var s: PQCharW; l: Integer): Boolean;
var
  AName, AValue, ATemp: QStringW;
  ps, pe, pl: PQCharW;
  AChild: TQHTMLTag;
const
  HtmlTagStart: PWideChar = '<';
  HtmlTagClose: PWideChar = '>';
  HtmlAttrDelimiters: PWideChar = ' '#9#10#13'/>';
  NullChar: WideChar = #0;
  SingleQuoter: WideChar = '''';
  DblQuoter: WideChar = '"';
  AttrValueDelimiter: PWideChar = '=';
  function DequotedValue(const V: QStringW): QStringW;
  var
    p: PQCharW;
  begin
    p := PQCharW(V);
    if p^ = SingleQuoter then
      Result := DequotedStrW(V, SingleQuoter)
    else if p^ = DblQuoter then
      Result := DequotedStrW(V, DblQuoter)
    else
      Result := V;
  end;
  procedure SkipMetaAndComments;
  begin
    while s < pe do
    begin
      if StartWithW(s, '<!--', False) then
      begin
        while s < pe do
        begin
          if s^ <> '-' then
            Inc(s)
          else if StartWithW(s, '-->', False) then
          begin
            Inc(s, 3);
            SkipSpaceW(s);
            Break;
          end
          else
            Inc(s);
        end;
      end
      else if StartWithW(s, '<!', False) or StartWithW(s, '<meta', True) then
      // 注释或meta行，忽略掉
      begin
        SkipUntilW(s, '>');
        if s^ = '>' then
          Inc(s);
        SkipSpaceW(s);
      end
      else
        Break;
    end;
  end;

begin
  ps := s;
  pe := s;
  Inc(pe, l);
  Result := False;
  while s < pe do
  begin
    SkipMetaAndComments;
    ATemp := DecodeTokenW(s, HtmlTagStart, NullChar, True, False);
    if Length(ATemp) > 0 then
      Add('').FInnerHtml := HtmlUnescape(ATemp);
    if s^ = '<' then
    begin
      Inc(s);
      if s^ = '/' then // ATagClose
      begin
        Inc(s);
        AName := DecodeTokenW(s, HtmlAttrDelimiters, NullChar, True, True);
        if StrCmpW(PQCharW(AName), PQCharW(FName), True) = 0 then
        begin
          Result := True;
          Exit;
        end
        else
          Break;
      end
      else
        AName := DecodeTokenW(s, HtmlAttrDelimiters, NullChar, True, False);
      AChild := Add(AName);
      while (s < pe) and (not CharInW(s, '/>')) do
      begin
        AName := DecodeTokenW(s, AttrValueDelimiter, NullChar, True, True);
        if (s^ = '''') or (s^ = '"') then
        begin
          AValue := DecodeTokenW(s, HtmlAttrDelimiters, s^, True, False)
        end
        else
          AValue := DecodeTokenW(s, HtmlAttrDelimiters, NullChar, False, False);
        SkipSpaceW(s);
        AName := HtmlUnescape(DequotedValue(AName));
        AValue := HtmlUnescape(DequotedValue(AValue));
        AChild.Attrs.Add(AName, AValue);
      end;
      if s^ = HtmlTagClose^ then
      begin
        Inc(s);
        SkipSpaceW(s);
        if StrCmpW(PQCharW(AChild.Name), 'img', True) = 0 then // img 可以忽略
          continue;
        if StrCmpW(PQCharW(AChild.Name), 'input', True) = 0 then // img 可以忽略
          continue;
        if StrCmpW(PQCharW(AChild.Name), 'p', True) = 0 then // p 可能有/p，也可能没有
        begin
          pl := s;
          if not AChild.TryParse(s, l - ((IntPtr(s) - IntPtr(ps)) shr 1)) then
            s := pl;
          continue;
        end;
        if StrCmpW(PQCharW(AChild.Name), 'br', True) = 0 then
          continue;
        if not AChild.TryParse(s, l - ((IntPtr(s) - IntPtr(ps)) shr 1)) then
          Break;
      end
      else if StartWithW(s, '/>', False) then
      begin
        Inc(s, 2);
        SkipSpaceW(s);
      end
      else
        Break;
    end
    else
      Break;
  end;
  Result := s >= pe;
end;

end.
