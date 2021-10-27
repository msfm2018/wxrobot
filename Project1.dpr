program Project1;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  Winapi.Windows,
  Winapi.Messages,
  System.SysUtils,
  System.Variants,
  System.Classes,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Dialogs,
  tlhelp32,
  PsAPI,
  Vcl.StdCtrls,
  Vcl.ExtCtrls,
  IdBaseComponent,
  IdComponent,
  IdTCPConnection,
  IdTCPClient,
  IdHTTP,
  System.Messaging,
  Vcl.CheckLst,
  Vcl.WinXPickers,
  Vcl.ComCtrls,
  Vcl.ExtDlgs,
  Vcl.WinXCtrls,
  Vcl.TitleBarCtrls,
  Vcl.Imaging.pngimage,
  Vcl.Menus,
  Xml.xmldom,
  Xml.XMLIntf,
  Xml.XMLDoc,
  IdCustomTCPServer,
  IdCustomHTTPServer,
  IdHTTPServer,
  Vcl.Mask,
  IdContext,
  System.Win.Registry,
  u_debug in 'u_debug.pas';

const
  WECHAT_PROCESS_NAME = 'WeChat.exe';


const
  DLLNAME = 'WxInterface.dll';


procedure RunSingle();
begin
  var hMutex: tHANDLE;
  var ExitValue := -1;
  hMutex := 0;
  hMutex := CreateMutexA(nil, FALSE, 'iphoneXe');
  if (hMutex > 0) then
    if (GetLastError() = ERROR_ALREADY_EXISTS) then
      ExitProcess(ExitValue);

end;

function ProcessNameFindPID(ProcessName: string): DWORD;
begin
  result := 0;
  var pe32: PROCESSENTRY32;
  ZeroMemory(@pe32, sizeof(PROCESSENTRY32));
  pe32.dwSize := sizeof(PROCESSENTRY32);
  var hProcess: THANDLE;
  hProcess := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  if (Process32First(hProcess, pe32)) then
  begin
  //第一个比较多余
    if LowerCase(pe32.szExeFile) = ProcessName.ToLower then
    begin
      result := pe32.th32ProcessID;
    end
    else
    begin
      while Process32Next(hProcess, pe32) do
      begin
        if LowerCase(pe32.szExeFile) = ProcessName.ToLower then
        begin
          result := pe32.th32ProcessID;
          Break;
        end
      end;
    end;

  end;
end;

function WxPath(strAppName, QueryValue: string): string;
//win11
var
  hKeyx: HKEY;
  size: PDWORD;
  info: PByte;
begin

  var lRet := RegOpenKeyEx(HKEY_CURRENT_USER, pchar(strAppName), 0, KEY_ALL_ACCESS, hKeyx);

  GetMem(info, 64);
  GetMem(size, SizeOf(pdword));
  size^ := 64;
  if QueryValue.ToLower = 'wechat' then
    RegQueryValueEx(hKeyx, PChar('WeChat'), nil, nil, Pbyte(info), @size)
  else
    RegQueryValueEx(hKeyx, PChar('InstallPath'), nil, nil, Pbyte(info), @size);
  result := PChar(info);
  FreeMem(info);
  RegCloseKey(hKeyx);
  var nPos := Result.IndexOf('-');
  if (nPos >= 0) then
    Result := Result.Substring(0, nPos - 1);

end;

procedure InjectDll;
var
  szPath: ansistring; //必须定义在外面 且 ansistring
begin

  var WxHandle := ProcessNameFindPID(WECHAT_PROCESS_NAME);
  var wx_path: string;
  if (WxHandle = 0) then
    wx_path := WxPath('Software\Microsoft\Windows\CurrentVersion\Run', 'Wechat');

  if (wx_path.length < 5) then
    wx_path := WxPath('Software\Tencent\WeChat', 'InstallPath') + '\WeChat.exe';

  var si: STARTUPINFO;
  var pi: PROCESS_INFORMATION;
  FillChar(si, SizeOf(si), 0);
  FillChar(pi, SizeOf(pi), 0);
  si.cb := SizeOf(si);

  CreateProcess(pchar(wx_path), nil, nil, nil, FALSE, 0, nil, nil, si, pi);
  var hWechatMainForm: HWND;
  hWechatMainForm := 0;
  while (hWechatMainForm = 0) do
  begin
    hWechatMainForm := FindWindow('WeChatLoginWndForPC', nil);
    Sleep(500);
  end;

//  if CheckIsInject(dwPid) then


  var hProcess := OpenProcess(PROCESS_ALL_ACCESS, FALSE, pi.dwProcessId);

  var pAddress := VirtualAllocEx(hProcess, nil, MAX_PATH, MEM_COMMIT, PAGE_EXECUTE_READWRITE);

  szPath := GetCurrentDir + '\' + DLLNAME;

  var lpNumberOfBytes: NativeUInt;

  WriteProcessMemory(hProcess, pAddress, PChar(szPath), MAX_PATH, lpNumberOfBytes);

  var LoadLibraryA := GetProcAddress(GetModuleHandleA('kernel32.dll'), 'LoadLibraryA');
  var bcc: Cardinal;
  var hThread := CreateRemoteThread(hProcess, nil, 0, LoadLibraryA, pAddress, 0, bcc);
  WaitForSingleObject(hThread, INFINITE);
  CloseHandle(hThread);
  CloseHandle(hProcess);

end;

begin
  try
    RunSingle();
    InjectDll
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.



//废弃


