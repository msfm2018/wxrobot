unit qplugins_qworker;

{ 本单元是QWorker的插件宿主版实现，服务将被注册到/Services/QWorker
}
interface

uses classes, sysutils, syncobjs, qworker, qstring, qplugins, qplugins_params,
  qplugins_base;

type
{$HPPEMIT '#pragma link "qplugins_qworker"'}
  TJobCallback = class
  private
    FCallback: IQJobCallback;
    FParams: IQParams;
  public
    constructor Create(ACallback: IQJobCallback; AParams: IQParams); overload;
  end;

  TQForJobManager = class(TInterfacedObject, IQForJobManager)
  private
    FManager: TQForJobs;
  public
    constructor Create(AMgr: TQForJobs); overload;
    destructor Destroy; override;
    procedure BreakIt; stdcall;
    function GetStartIndex: Int64; stdcall;
    function GetStopIndex: Int64; stdcall;
    function GetBreaked: Boolean; stdcall;
    function GetRuns: Int64; stdcall;
    function GetTotalTime: Int64; stdcall;
    function GetAvgTime: Int64; stdcall;
  end;

  TForJobCallback = class
  private
    FCallback: IQForJobCallback;
    FParams: IQParams;
    FManager: IQForJobManager;
  public
    constructor Create(ACallback: IQForJobCallback; AParams: IQParams);
      overload;
  end;

  TQWorkerBaseService = class(TQService)
  protected
    procedure DoJob(AJob: PQJob);
  end;

  TQWorkerService = class(TQWorkerBaseService, IQWorkers)
  protected
    procedure DoSignalJob(AJob: PQJob);
    procedure DoForJob(ALoopMgr: TQForJobs; AJob: PQJob; AIndex: NativeInt);
    function Post(AJob: IQJobCallback; AParams: IQParams;
      ARunInMainThread: Boolean): Int64; stdcall;
    function Timer(AJob: IQJobCallback; AInterval: Cardinal; AParams: IQParams;
      ARunInMainThread: Boolean): Int64; stdcall;
    function Delay(AJob: IQJobCallback; AParams: IQParams; ADelay: Int64;
      ARunInMainThread, AIsRepeat: Boolean): Int64; stdcall;
    function At(AJob: IQJobCallback; AParams: IQParams; ATime: TDateTime;
      AInterval: Cardinal; ARunInMainThread: Boolean): Int64; stdcall;
    function Plan(AJob: IQJobCallback; AParams: IQParams; APlan: PWideChar;
      ARunInMainThread: Boolean): Int64; stdcall;
    procedure &For(AJob: IQForJobCallback; AParams: IQParams;
      AStart, AStop: Int64; AMsgWait: Boolean); stdcall;
    procedure Clear(AHandle: Int64; AWaitRunningDone: Boolean); stdcall;
    function CreateJobGroup(AByOrder: Boolean): IQJobGroup; stdcall;
    procedure SetWorkers(const AMinWorkers, AMaxWorkers: Integer); stdcall;
    procedure PeekCurrentWorkers(var ATotal, AIdle, ABusy: Integer); stdcall;
    function RegisterSignal(const ASignal: PWideChar): Integer; stdcall;
    function WaitSignal(const ASignal: PWideChar; AJob: IQJobCallback;
      ARunInMainThread: Boolean): Int64; stdcall;
    procedure Signal(const ASignal: PWideChar; AParams: IQParams);
    //
    function _CreateJobGroup(AByOrder: Boolean): StandInterfaceResult; stdcall;
  end;

  TQJobGroupService = class(TQWorkerBaseService, IQJobGroup)
  protected
    FGroup: TQJobGroup;
    FAfterDone: IQNotifyCallback;
    FFreeAfterDone: Boolean;
    procedure DoGroupDone(ASender: TObject);
    procedure Cancel(AWaitRunningDone: Boolean = true); stdcall;
    procedure Prepare; stdcall;
    procedure Run(ATimeout: Cardinal = INFINITE); stdcall;
    function Insert(AIndex: Integer; AJob: IQJobCallback; AParams: IQParams;
      ARunInMainThread: Boolean): Boolean; stdcall;
    function Add(AJob: IQJobCallback; AParams: IQParams; AInMainThread: Boolean)
      : Boolean; stdcall;
    function Wait(ABlockMessage: Boolean; ATimeout: Cardinal = INFINITE)
      : TWaitResult; overload;
    function GetCount: Integer; stdcall;
    procedure SetAfterDone(AValue: IQNotifyCallback); stdcall;
    function GetAfterDone: IQNotifyCallback; stdcall;
    function GetByOrder: Boolean; stdcall;
    function GetRuns: Integer; stdcall;
    function GetMaxWorkers: Integer; stdcall;
    procedure SetMaxWorkers(const AValue: Integer); stdcall;
    function _GetAfterDone: StandInterfaceResult; stdcall;
  public
    constructor Create(AByOrder: Boolean); overload;
    destructor Destroy; override;
  end;

implementation

type
  TSignalJobWaiter = class
  protected
    FCallback: IQJobCallback;
  public
    constructor Create(ACallback: IQJobCallback);

  end;
  { TQWorkerService }

function TQWorkerService.At(AJob: IQJobCallback; AParams: IQParams;
  ATime: TDateTime; AInterval: Cardinal; ARunInMainThread: Boolean): Int64;
begin
  Result := Workers.At(DoJob, ATime, AInterval, TJobCallback.Create(AJob,
    AParams), ARunInMainThread, jdfFreeAsObject);
end;

procedure TQWorkerService.Clear(AHandle: Int64; AWaitRunningDone: Boolean);
begin
  Workers.ClearSingleJob(AHandle, AWaitRunningDone);
end;

function TQWorkerService.CreateJobGroup(AByOrder: Boolean): IQJobGroup;
begin
  Result := TQJobGroupService.Create;
end;

function TQWorkerService.Delay(AJob: IQJobCallback; AParams: IQParams;
  ADelay: Int64; ARunInMainThread, AIsRepeat: Boolean): Int64;
begin
  Result := Workers.Delay(DoJob, ADelay, TJobCallback.Create(AJob, AParams),
    ARunInMainThread, jdfFreeAsObject, AIsRepeat);
end;

procedure TQWorkerService.DoForJob(ALoopMgr: TQForJobs; AJob: PQJob;
  AIndex: NativeInt);
var
  ACallback: TForJobCallback;
begin
  ACallback := TForJobCallback(AJob.Data);
  if Assigned(ACallback.FCallback) then
    ACallback.FCallback.DoJob(ACallback.FManager, AIndex, ACallback.FParams);
end;

procedure TQWorkerService.DoSignalJob(AJob: PQJob);
var
  AWaiter: TSignalJobWaiter;
begin
  AWaiter := TSignalJobWaiter(AJob.Source.Data);
  AWaiter.FCallback.DoJob(IQParams(AJob.Data));
end;

procedure TQWorkerService.&For(AJob: IQForJobCallback; AParams: IQParams;
  AStart, AStop: Int64; AMsgWait: Boolean);
var
  ALooper: TQForJobs;
  ACallback: TForJobCallback;
begin
  ACallback := TForJobCallback.Create(AJob, AParams);
  ALooper := TQForJobs.Create(AStart, AStop, ACallback, jdfFreeAsObject);
  ACallback.FManager := TQForJobManager.Create(ALooper);
  ALooper.Run(DoForJob, AMsgWait);
end;

procedure TQWorkerService.PeekCurrentWorkers(var ATotal, AIdle, ABusy: Integer);
begin
  ATotal := Workers.Workers;
  AIdle := Workers.IdleWorkers;
  ABusy := Workers.BusyWorkers;
end;

function TQWorkerService.Plan(AJob: IQJobCallback; AParams: IQParams;
  APlan: PWideChar; ARunInMainThread: Boolean): Int64;
begin
  Result := Workers.Plan(DoJob, APlan, TJobCallback.Create(AJob, AParams),
    ARunInMainThread, jdfFreeAsObject);
end;

function TQWorkerService.Post(AJob: IQJobCallback; AParams: IQParams;
  ARunInMainThread: Boolean): Int64;
begin
  Result := Workers.Post(DoJob, TJobCallback.Create(AJob, AParams),
    ARunInMainThread, jdfFreeAsObject);
end;

function TQWorkerService.RegisterSignal(const ASignal: PWideChar): Integer;
begin
  Result := Workers.RegisterSignal(ASignal);
end;

procedure TQWorkerService.SetWorkers(const AMinWorkers, AMaxWorkers: Integer);
begin
  Workers.MaxWorkers := AMaxWorkers;
  Workers.MinWorkers := AMinWorkers;
end;

procedure TQWorkerService.Signal(const ASignal: PWideChar; AParams: IQParams);
begin
  Workers.Signal(ASignal, Pointer(AParams), jdfFreeAsInterface);
end;

function TQWorkerService.Timer(AJob: IQJobCallback; AInterval: Cardinal;
  AParams: IQParams; ARunInMainThread: Boolean): Int64;
begin
  Result := Workers.Post(DoJob, AInterval, TJobCallback.Create(AJob, AParams),
    ARunInMainThread, jdfFreeAsObject);
end;

function TQWorkerService.WaitSignal(const ASignal: PWideChar;
  AJob: IQJobCallback; ARunInMainThread: Boolean): Int64;
var
  AWaiter: TSignalJobWaiter;
begin
  if Assigned(AJob) then
  begin
    AWaiter := TSignalJobWaiter.Create(AJob);
    Result := Workers.Wait(DoSignalJob, ASignal, ARunInMainThread, AWaiter,
      jdfFreeAsObject);
  end;
end;

function TQWorkerService._CreateJobGroup(AByOrder: Boolean)
  : StandInterfaceResult;
begin
  Result := PointerOf(CreateJobGroup(AByOrder));
end;

{ TJobCallback }

constructor TJobCallback.Create(ACallback: IQJobCallback; AParams: IQParams);
begin
  inherited Create;
  FCallback := ACallback;
  FParams := AParams;
end;

{ TQJobGroupService }

function TQJobGroupService.Add(AJob: IQJobCallback; AParams: IQParams;
  AInMainThread: Boolean): Boolean;
begin
  Result := FGroup.Add(DoJob, TJobCallback.Create(AJob, AParams), AInMainThread,
    jdfFreeAsObject);
end;

procedure TQJobGroupService.Cancel(AWaitRunningDone: Boolean);
begin
  FGroup.Cancel(AWaitRunningDone);
end;

constructor TQJobGroupService.Create(AByOrder: Boolean);
begin
  inherited Create;
  FGroup := TQJobGroup.Create(AByOrder);
  FGroup.AfterDone := DoGroupDone;
end;

destructor TQJobGroupService.Destroy;
begin
  FreeAndNil(FGroup);
  inherited;
end;

procedure TQJobGroupService.DoGroupDone(ASender: TObject);
begin
  if Assigned(FAfterDone) then
    FAfterDone.DoNotify(Self);
end;

function TQJobGroupService.GetAfterDone: IQNotifyCallback;
begin
  Result := FAfterDone;
end;

function TQJobGroupService.GetByOrder: Boolean;
begin
  Result := FGroup.ByOrder;
end;

function TQJobGroupService.GetCount: Integer;
begin
  Result := FGroup.Count;
end;

function TQJobGroupService.GetMaxWorkers: Integer;
begin
  Result := FGroup.MaxWorkers;
end;

function TQJobGroupService.GetRuns: Integer;
begin
  Result := FGroup.Runs;
end;

function TQJobGroupService.Insert(AIndex: Integer; AJob: IQJobCallback;
  AParams: IQParams; ARunInMainThread: Boolean): Boolean;
begin
  Result := FGroup.Insert(AIndex, DoJob, TJobCallback.Create(AJob, AParams),
    ARunInMainThread, jdfFreeAsObject);
end;

procedure TQJobGroupService.Prepare;
begin
  FGroup.Prepare;
end;

procedure TQJobGroupService.Run(ATimeout: Cardinal);
begin
  FGroup.Run(ATimeout);
end;

procedure TQJobGroupService.SetAfterDone(AValue: IQNotifyCallback);
begin
  FAfterDone := AValue;
end;

procedure TQJobGroupService.SetMaxWorkers(const AValue: Integer);
begin
  FGroup.MaxWorkers := AValue;
end;

function TQJobGroupService.Wait(ABlockMessage: Boolean; ATimeout: Cardinal)
  : TWaitResult;
begin
  if ABlockMessage then
    Result := FGroup.WaitFor(ATimeout)
  else
    Result := FGroup.MsgWaitFor(ATimeout);
end;

function TQJobGroupService._GetAfterDone: StandInterfaceResult;
begin
  Result := PointerOf(FAfterDone);
end;

{ TQForJobManager }

procedure TQForJobManager.BreakIt;
begin
  FManager.BreakIt;
end;

constructor TQForJobManager.Create(AMgr: TQForJobs);
begin
  inherited Create;
  FManager := AMgr;
end;

destructor TQForJobManager.Destroy;
begin
  FreeAndNil(FManager);
  inherited;
end;

function TQForJobManager.GetAvgTime: Int64;
begin
  Result := FManager.AvgTime;
end;

function TQForJobManager.GetBreaked: Boolean;
begin
  Result := FManager.Breaked;
end;

function TQForJobManager.GetRuns: Int64;
begin
  Result := FManager.Runs;
end;

function TQForJobManager.GetStartIndex: Int64;
begin
  Result := FManager.StartIndex;
end;

function TQForJobManager.GetStopIndex: Int64;
begin
  Result := FManager.StopIndex;
end;

function TQForJobManager.GetTotalTime: Int64;
begin
  Result := FManager.TotalTime;
end;

{ TQWorkerBaseService }

procedure TQWorkerBaseService.DoJob(AJob: PQJob);
var
  ACallback: TJobCallback;
begin
  ACallback := TJobCallback(AJob.Data);
  if Assigned(ACallback.FCallback) then
    ACallback.FCallback.DoJob(ACallback.FParams);
end;

{ TForJobCallback }

constructor TForJobCallback.Create(ACallback: IQForJobCallback;
  AParams: IQParams);
begin
  inherited Create;
  FCallback := ACallback;
  FParams := AParams;
end;

{ TSignalJobWaiter }

constructor TSignalJobWaiter.Create(ACallback: IQJobCallback);
begin
  inherited Create;
  FCallback := ACallback;
end;

initialization

RegisterServices('/Services', [TQWorkerService.Create(IQWorkers, 'QWorker')]);

finalization

UnregisterServices('/Services', ['QWorker']);

end.
