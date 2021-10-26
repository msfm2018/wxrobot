unit QAndroid.Shell;

interface

{
  本源码来自QDAC项目，版权归swish(QQ:109867294)所有。
  (1)、使用许可及限制
  您可以自由复制、分发、修改本源码，但您的修改应该反馈给作者，并允许作者在必要时，
  合并到本项目中以供使用，合并后的源码同样遵循QDAC版权声明限制。
  您的产品的关于中，应包含以下的版本声明:
  本产品使用的QAndroidShell来自QDAC项目，版权归作者所有。
  (2)、技术支持
  有技术问题，您可以加入QDAC官方QQ群250530692共同探讨。
  (3)、赞助
  您可以自由使用本源码而不需要支付任何费用。如果您觉得本源码对您有帮助，您可以赞
  助本项目（非强制），以使作者不为生活所迫，有更多的精力为您呈现更好的作品：
  赞助方式：
  支付宝： guansonghuan@sina.com 姓名：管耸寰
  建设银行：
  户名：管耸寰
  账号：4367 4209 4324 0179 731
  开户行：建设银行长春团风储蓄所
}
{
  本单元实现了一个伪的Shell，可以用于在Android程序中执行Shell命令，如果需要Root权限，
  则在执行前，调用AskForRoot方法来获取用户的Root授权，如果不再需要在Root账号下执行
  命令，则调用ExitRoot方法来退出Root账号返回普通账号模式。
  1、调用TQAndroidShell.Initialize方法来初始化当前实例
  AShell.Initialize;
  2、如果需要Root权限执行某些命令，调用TQAndroidShell.AskForRoot获得Root权限，否则忽略此步骤
  if AShell.AskForRoot then
  begin
  ...
  end
  else //进入失败，手机未Root或者用户拒绝给予Root权限
  ...;
  3、调用Execute方法来执行命令行并获得返回的结果
  AShell.Execute('ls /proc -l');
  4、如果要切换回普通账号模式，调用AShell.ExitRoot来返回当前普通账号模式
  【注意】TQAndroidShell是一个记录，不需要手工释放（除非你是New生成的）

}

uses System.SysUtils, System.Diagnostics, Androidapi.Jni,
  Androidapi.JNIBridge,
  Androidapi.Jni.GraphicsContentViewText,
  Androidapi.Jni.JavaTypes,
  Androidapi.Helpers,
  FMX.Helpers.Android, FMX.Forms, FMX.Dialogs, qstring;

type
  PQAndroidShell = ^TQAndroidShell;

  TQAndroidShell = record
  private
    FRuntime: JObject;
    FProcess: JObject;
    FInRoot: Boolean;
    function GetIsRooted: Boolean;
    function InternalReadReply(AProcess: JObject; ATimeout: Cardinal): QStringW;
    /// <summary>发送一个命令行</summary>
    /// <param name="ACmdline">要发送的命令行内容</param>
    /// <returns>成功，返回true，失败，返回false</returns>
    /// <remarks>仅用于Root模式下</remarks>
    function SendCmd(const ACmdline: QStringW): Boolean;
    function ReadReply(ATimeout: Cardinal = INFINITE): QStringW;
  public
    /// <summary>初始化函数，用于初始化一个TQAndroidShell实例</summary>
    /// <returns>返回当前记录的指针</returns>
    function Initliaize: PQAndroidShell;
    /// <summary>请求Root权限以进入Root账号准备执行后续的命令</summary>
    /// <returns>成功，返回True，失败，返回False</returns>
    /// <remarks>如果失败，一般有两种可能：
    /// 1、设备未Root，此时IsRooted属性为False；
    /// 2、用户拒绝授权
    /// </remarks>
    function AskForRoot: Boolean;
    /// <summary>执行指定的命令行并等待返回</summary>
    /// <param name="ACmdline">命令行内容</param>
    /// <param name="ATimeout">等待命令执行前等待的时间，单位为毫秒</param>
    /// <returns>返回命令行的输出结果</returns>
    function Execute(const ACmdline: QStringW; ATimeout: Cardinal = INFINITE)
      : QStringW;
    /// <summary>退出Root模式</summary>
    /// <remarks>如果未处于Root模式，什么也不会发生</remarks>
    procedure ExitRoot;
    /// <summary>当前是否处于Root模式</summary>
    property InRoot: Boolean read FInRoot;
    /// <summary>当前设备是否已经Root过了</summary>
    property IsRooted: Boolean read GetIsRooted;
  end;

implementation

type
  JProcess = interface;
  JRuntime = interface;

  // ----------------------------------JProcess----------------------
  JProcessClass = interface(JObjectClass)
    ['{7BFD2CCB-89B6-4382-A00B-A7B5BB0BC7C9}']

  end;

  [JavaSignature('java/lang/Process')]
  JProcess = interface(JObject)
    ['{476414FD-570F-4EDF-B678-A2FE459EA6EB}']
    { Methods }
    procedure destroy; cdecl;
    function exitValue: integer; cdecl;
    function getErrorStream: JInputStream; cdecl;
    function getInputStream: JInputStream; cdecl;
    function getOutputStream: JOutputStream; cdecl;
    function waitFor: integer; cdecl;
  end;

  TJProcess = class(TJavaGenericImport<JProcessClass, JProcess>)
  end;

  // ----------------------------------Jruntime----------------------
  JRuntimeClass = interface(JObjectClass)
    ['{3F2E949D-E97C-4AD8-B5B9-19CB0A6A29F3}']
    { costant }
  end;

  [JavaSignature('java/lang/Runtime')]
  JRuntime = interface(JObject)
    ['{C097A7EC-677B-4BCB-A4BD-7227160750A5}']
    { Methods }
    procedure addShutdownHook(hook: JThread); cdecl;
    function availableProcessors: integer; cdecl;
    function exec(progArray, envp: array of JString): JProcess; overload; cdecl;
    function exec(progArray: JString; envp: array of JString; directory: JFile)
      : JProcess; overload; cdecl;
    function exec(progArray, envp: array of JString; directory: JFile)
      : JProcess; overload; cdecl;
    function exec(prog: JString; envp: array of JString): JProcess; cdecl;
      overload; cdecl;
    function exec(progArray: array of JString): JProcess; overload; cdecl;
    function exec(prog: JString): JProcess; cdecl; overload; cdecl;
    procedure Exit(code: integer); cdecl;
    function freeMemory: LongInt; cdecl;
    procedure gc; cdecl;
    function getLocalizedInputStream(stream: JInputStream): JInputStream; cdecl;
    function getLocalizedOutputStream(stream: JOutputStream)
      : JOutputStream; cdecl;
    function getRuntime: JRuntime; cdecl;
    procedure halt(code: integer); cdecl;
    procedure load(pathName: JString); cdecl;
    procedure loadLibrary(libName: JString); cdecl;
    function maxMemory: LongInt; cdecl;
    function RemoveShutdownHook(hook: JThread): Boolean; cdecl;
    procedure runFinalization; cdecl;
    procedure runFinalizersOnExit(run: Boolean); cdecl;
    function totalMemory: LongInt; cdecl;
    procedure traceInstructions(enable: Boolean); cdecl;
    procedure traceMethodCalls(enable: Boolean); cdecl;
  end;

  TJRuntime = class(TJavaGenericImport<JRuntimeClass, JRuntime>)
  end;

  { TQAndroidShell }

function TQAndroidShell.AskForRoot: Boolean;
begin
Result := InRoot;
if not Result then
  begin
  Result := IsRooted;
  if not Assigned(FProcess) then
    begin
    Result := False;
    if IsRooted then
      begin
      FProcess := (FRuntime as JRuntime).exec(StringToJString('su'));
      if Assigned(FProcess) then
        begin
        // 通过检查当前账号来判断下自己是否成功获取root权限
        if SendCmd('id -nu') then
          begin
          FInRoot := StrStrW(PQCharW(ReadReply), 'root') <> nil;
          Result := FInRoot;
          end;
        end;
      if not Result then
        FProcess := nil;
      end;
    end;
  end;
end;

function TQAndroidShell.Initliaize: PQAndroidShell;
begin
FRuntime := TJRuntime.Create;
FProcess := nil;
FInRoot := False;
Result := @Self;
end;

function TQAndroidShell.Execute(const ACmdline: QStringW; ATimeout: Cardinal)
  : QStringW;
var
  AProcess: JProcess;
begin
SetLength(Result, 0);
if InRoot then
  begin
  if SendCmd(ACmdline) then
    Result := ReadReply(ATimeout);
  end
else
  begin
  AProcess := (FRuntime as JRuntime).exec(StringToJString(ACmdline));
  if Assigned(AProcess) then
    Result := InternalReadReply(AProcess, ATimeout);
  end;
end;

procedure TQAndroidShell.ExitRoot;
begin
if InRoot then
  begin
  if SendCmd('exit') then
    begin
    (FProcess as JProcess).waitFor;
    FProcess := nil;
    FInRoot := False;
    end;
  end;
end;

function TQAndroidShell.GetIsRooted: Boolean;
begin
Result := FileExists('/system/bin/su') or FileExists('/system/xbin/su');
end;

function TQAndroidShell.InternalReadReply(AProcess: JObject; ATimeout: Cardinal)
  : QStringW;
var
  AError, AInput, AResultStream: JInputStream;
  AWatch: TStopWatch;
  ABuf: TJavaArray<Byte>;
begin
AError := (AProcess as JProcess).getErrorStream;
AInput := (AProcess as JProcess).getInputStream;
AWatch := TStopWatch.StartNew;
AResultStream := nil;
repeat
  if AInput.available > 0 then
    AResultStream := AInput
  else if AError.available > 0 then
    AResultStream := AError;
until (AWatch.ElapsedMilliseconds > ATimeout) or (AResultStream <> nil);
if Assigned(AResultStream) then
  begin
  ABuf := TJavaArray<Byte>.Create(AResultStream.available);
  try
    AResultStream.read(ABuf);
    Result := qstring.Utf8Decode(PQCharA(ABuf.Data), ABuf.Length);
  finally
    FreeAndNil(ABuf);
  end;
  end
else
  SetLength(Result, 0);
end;

function TQAndroidShell.ReadReply(ATimeout: Cardinal): QStringW;
begin
Result := InternalReadReply(FProcess, ATimeout);
end;

function TQAndroidShell.SendCmd(const ACmdline: QStringW): Boolean;
var
  S: QStringA;
  ABuf: TJavaArray<Byte>;
  AStream: JOutputStream;
begin
S := qstring.Utf8Encode(ACmdline + SLineBreak);
ABuf := TJavaArray<Byte>.Create(S.Length);
try
  Move(PQCharA(S)^, ABuf.Data^, S.Length);
  AStream := (FProcess as JProcess).getOutputStream;
  AStream.write(ABuf);
  AStream.flush;
  Result := True;
except
  Result := False;
end;
FreeAndNil(ABuf);
end;

end.
