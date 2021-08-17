library WxInterface;

uses
  System.SysUtils,
  Winapi.Windows,
  Vcl.Forms,
  System.Classes,
  Unit2 in 'Unit2.pas' {Form2},
  u_debug in 'u_debug.pas',
  Method1 in 'inject\Method1.pas',
  Method2 in 'inject\Method2.pas',
  Method3 in 'inject\Method3.pas',
  wxCore in 'core\wxCore.pas',
  injectFriendModule in 'inject\injectFriendModule.pas',
  PubSub in 'inject\PubSub.pas',
  injectAutoRecvMsgModule in 'inject\injectAutoRecvMsgModule.pas',
  ImgPanel in 'ImgPanel.pas',
  GGlobal in 'core\GGlobal.pas',
  uWinApi in 'core\uWinApi.pas';

type
  Test = record
    a: Integer;
    b: Integer;
  end;
{$R *.res}

function IsWxVersionValid(): Boolean; cdecl external 'vxVer.dll' name 'IsWxVersionValid';

function MyThreadFun(var Param: Test): Integer; stdcall;
begin
  if Form2 = nil then
    Form2 := tform2.Create(nil);
  form2.ShowModal;
  Result := 0;
end;

procedure DLLEntryInit(fdwReason: DWord);
var
  Id: Dword;
  P: test;
begin
  case (fdwReason) of
    DLL_PROCESS_ATTACH:
      begin
        P.a := 5;
        if IsWxVersionValid() then
        begin
          Createthread(nil, 0, @MyThreadFun, @P, 0, Id);
        //  debug.Show('success');
        end
        else
          messagebox(0, '提示', '微信版本不符要求', 0);
      end;
    DLL_PROCESS_DETACH:
      ;
    DLL_THREAD_ATTACH:
      ;
    DLL_THREAD_DETACH:
      ;
  end;
end;

begin
  DllProc := @DLLEntryInit;
  DLLEntryInit(DLL_PROCESS_ATTACH);
end.

