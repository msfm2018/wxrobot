unit qplugins_loader_process;

interface

uses classes, sysutils, windows, messages, qplugins, qstring, qplugins_params,
  qplugins_proxy, qsocket_sharemem;
{$HPPEMIT '#pragma link "qplugins_loader_process"'}

type
  { 基本思路：
    服务通过配置文件注册，然后这个配置文件中包含了注册接口的ID，客户端可以通过这个接口来直接
    访问（需要RTTI支持），或者通过Execute函数来传递
  }
  TQLocalProcess = class;

  TQLocalProcessItem = class
  private
    FOwner: TQLocalProcess;
    FProcessId: Cardinal;
    FProcessHandle: THandle;
    FStartTime: Cardinal; // 进程启动时间，以便计算超时，结束进程
    FConnection: TQShareMemConnection;
    FPendingCalls: Integer; // 正在执行未完成的调用数量
    procedure LoadProcess;
    procedure CloseProcess;
  public
    constructor Create(AOwner: TQLocalProcess); overload;
    destructor Destroy; override;
  end;

  TQLocalProcess = class(TQRPCProcess)
  private
    FMaxProcesses: Integer;
    FEnvSettings: TStrings;
    FEnvCached: QStringW;
    FEnvChanged: Boolean;
    FChildren: array of TQLocalProcessItem;
    FWorkDir: QStringW;
    function GetIdleProcess: TQLocalProcessItem;
  protected
    function InternalSend(ACall: TQPendingRPC): Boolean; override;
    procedure DoEnvSettingsChanges(ASender: TObject);
    function EnvData: QStringW;
  public
    constructor Create(APath: String); override;
    destructor Destroy; override;
    property MaxProcesses: Integer read FMaxProcesses write FMaxProcesses;
    property EnvSettings: TStrings read FEnvSettings;
    property WorkDir: QStringW read FWorkDir write FWorkDir;
  end;

implementation

{ TQLocalProcess }

constructor TQLocalProcess.Create(APath: String);
begin
  inherited;
  FMaxProcesses := 1;
  FEnvSettings := TStringList.Create;
  TStringList(FEnvSettings).OnChange := DoEnvSettingsChanges;
end;

destructor TQLocalProcess.Destroy;
begin
  FreeAndNil(FEnvSettings);
  inherited;
end;

procedure TQLocalProcess.DoEnvSettingsChanges(ASender: TObject);
begin
  FEnvChanged := True;
end;

function TQLocalProcess.EnvData: QStringW;
var
  I, L, LS: Integer;
  p: PQCharW;
  S: QStringW;
begin
  if FEnvChanged then
  begin
    FEnvChanged := False;
    L := 0;
    for I := 0 to FEnvSettings.Count - 1 do
    begin
      LS := Length(FEnvSettings[I]);
      if LS > 0 then
        Inc(L, LS + 1);
    end;
    SetLength(FEnvCached, L);
    p := PQCharW(FEnvCached);
    for I := 0 to FEnvSettings.Count - 1 do
    begin
      S := FEnvSettings[I];
      p := StrECopy(p, PQCharW(S));
      Inc(p);
    end;
    p^ := #0;
  end;
  Result := FEnvCached;
end;

function TQLocalProcess.GetIdleProcess: TQLocalProcessItem;
var
  I: Integer;
begin
  Result := nil;
  Lock;
  try
    for I := 0 to High(FChildren) do
    begin
      if not Assigned(Result) then
        Result := FChildren[I]
      else if FChildren[I].FPendingCalls < Result.FPendingCalls then
        Result := FChildren[I];
    end;
    if (not Assigned(Result)) or ((Result.FPendingCalls > 0) and
      (Length(FChildren) < MaxProcesses)) then
    begin
      SetLength(FChildren, Length(FChildren) + 1);
      FChildren[High(FChildren)] := TQLocalProcessItem.Create(Self);
    end;
  finally
    Unlock;
  end;
end;

function TQLocalProcess.InternalSend(ACall: TQPendingRPC): Boolean;
begin
  //
end;

{ TQLocalProcessItem }

procedure TQLocalProcessItem.CloseProcess;
begin

end;

constructor TQLocalProcessItem.Create(AOwner: TQLocalProcess);
begin
  inherited Create;
  FOwner := AOwner;
  FConnection := TQShareMemConnection.Create;
  LoadProcess;
end;

destructor TQLocalProcessItem.Destroy;
begin
  if FProcessId <> 0 then
    CloseProcess;
  FreeAndNil(FConnection);
  inherited;
end;

procedure TQLocalProcessItem.LoadProcess;
var
  AStartupInfo: TStartupInfo;
  AProcessInfo: TProcessInformation;
  AFlags: Integer;
  AEnvData: QStringW;
  pEnvData: PQCharW;
  ACmdline: QStringW;
begin
  FillChar(AProcessInfo, SizeOf(AProcessInfo), 0);
  AFlags := CREATE_SUSPENDED or NORMAL_PRIORITY_CLASS;
  AEnvData := FOwner.EnvData;
  if Length(AEnvData) > 0 then
    pEnvData := PQCharW(AEnvData)
  else
    pEnvData := nil;
  FillChar(AStartupInfo, SizeOf(AStartupInfo), 0);
  AStartupInfo.cb := SizeOf(AStartupInfo); // 一切都默认
  // 加入参数，以便让插件能够得到宿主进程的
  SetLength(ACmdline, MAX_PATH);
  StrPCopy(ACmdline, FOwner.Path);
  if not CreateProcessW(nil, PQCharW(ACmdline), nil, nil, False, AFlags,
    pEnvData, PQCharW(FOwner.WorkDir), AStartupInfo, AProcessInfo) then
  begin
    if AProcessInfo.hProcess <> 0 then
      CloseHandle(AProcessInfo.hProcess);
    if AProcessInfo.hThread <> 0 then
      CloseHandle(AProcessInfo.hThread);
    RaiseLastOSError;
  end
  else
  begin
    FProcessId := AProcessInfo.dwProcessId;
    FProcessHandle := AProcessInfo.hProcess;
    // 本地地址强制为 "子进程ID:Host"，如"1245:QPlugins.Host"，这样子进程可以很轻易知道自己的宿主通讯端口
    FConnection.LocalAddr := IntToStr(FProcessId) + ':QPlugins.Host';
    ResumeThread(AProcessInfo.hThread);
  end;
end;

end.
