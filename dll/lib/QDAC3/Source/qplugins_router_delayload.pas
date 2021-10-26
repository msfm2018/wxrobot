unit qplugins_router_delayload;

interface

uses classes, sysutils, qstring, qplugins_params, qplugins, qplugins_base,qjson;
{$HPPEMIT '#pragma link "qplugins_router_delayload"'}
type
  (*
    延迟加载服务的格式使用JSON
    [
    {
    "Id":"Service Id",
    "Path":"Service Path",
    "Loader":"Loader Name"
    "Module":"Service module path"
    }
    ]
  *)
  TQDelayRouter = class(TQServices)
  private
    FConfigFile: QStringW;
    FSearching: Boolean;
    procedure SetConfigFile(const Value: QStringW);
  protected
    FConfig: TQJson;
  public
    constructor Create(const AId: TGuid; AName: QStringW); overload; override;
    constructor Create; overload;override;
    destructor Destroy; override;
    function ByPath(APath: PWideChar): IQService; override; stdcall;
    function ById(const AId: TGuid; ADoGetInstance: Boolean): IQService; override; stdcall;
    property ConfigFile: QStringW read FConfigFile write SetConfigFile;
  end;

implementation

const
  IID_ROUTER_DELAY: TGuid = '{C13FF21A-3B63-4A69-A9D8-9313A3666FFB}';
  { TQDelayRouter }

function TQDelayRouter.ById(const AId: TGuid; ADoGetInstance: Boolean): IQService;
  function LoadService: IQService;
  var
    I: Integer;
    S: QStringW;
    AJson: TQJson;
  begin
    S := GuidToString(AId);
    Result := nil;
    for I := 0 to FConfig.Count - 1 do
    begin
      AJson := FConfig[I];
      if AJson.ValueByName('Id', '') = S then
      begin
        S := AJson.ValueByName('Path', '');
        Result := ByPath(PWideChar(S));
        Break;
      end;
    end;
  end;

begin
  if FSearching then
    Exit;
  FSearching := True;
  try
    Result := inherited ById(AId,ADoGetInstance);
    if not Assigned(Result) then
      Result := LoadService;
  finally
    FSearching := False;
  end;
end;

function TQDelayRouter.ByPath(APath: PWideChar): IQService;
  function LoadService: IQService;
  var
    I, J: Integer;
    S: QStringW;
    AJson: TQJson;
    ALoader: IQLoader;
    ALocker: IQLocker;
    K: Integer;
    AFound: Boolean;
  begin
    Result := nil;
    S := APath;
    for I := 0 to FConfig.Count - 1 do
    begin
      AJson := FConfig[I];
      if StrCmpW(PWideChar(AJson.ValueByName('Path', '')), APath, True) = 0 then
      begin
        S := AJson.ValueByName('Loader', '');
        if Length(S) > 0 then
        begin
          ALocker := PluginsManager as IQLocker;
          ALocker.Lock;
          try
            for J := 0 to PluginsManager.Loaders.Count - 1 do
            begin
              ALoader := PluginsManager.Loaders[J] as IQLoader;
              if StrCmpW(PWideChar(S), ALoader.Name, True) = 0 then
              begin
                S := AJson.ValueByName('Module', '');
                if Length(S) > 0 then
                begin
                  AFound := False;
                  for K := 0 to ALoader.GetModuleCount - 1 do
                  begin
                    if StrCmpW(PWideChar(S), ALoader.GetModuleName(K), True) = 0
                    then
                    begin
                      AFound := True;
                      Break;
                    end;
                  end;
                  if not AFound then
                  begin
                    if ALoader.LoadServices(PWideChar(S)) <> 0 then
                    // 服务提供模块已经成功加载，那么服务肯定要么已经注册了，要么不存在
                    begin
                      Result := inherited ByPath(APath);
                    end;
                  end;
                end;
                Break;
              end;
            end;
          finally
            ALocker.Unlock;
          end;
        end;
        Break;
      end;
    end;
  end;

begin
  Result := inherited ByPath(APath);
  if not Assigned(Result) then
    Result := LoadService;
end;

constructor TQDelayRouter.Create;
begin
  Create(IID_ROUTER_DELAY, 'DelayServiceLoader');
end;

constructor TQDelayRouter.Create(const AId: TGuid; AName: QStringW);
begin
  inherited;
  FConfig := TQJson.Create;
end;

destructor TQDelayRouter.Destroy;
begin
  FreeAndNil(FConfig);
  inherited;
end;

procedure TQDelayRouter.SetConfigFile(const Value: QStringW);
begin
  if FConfigFile <> Value then
  begin
    FConfigFile := Value;
    if FileExists(Value) then
      FConfig.LoadFromFile(Value)
    else
      FConfig.Clear;
  end;
end;

end.
