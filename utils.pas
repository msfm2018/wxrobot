unit utils;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, ShellApi, ShlObj, pngimage, ComObj, ActiveX, Vcl.ExtCtrls,
  tlhelp32, PsAPI, IdBaseComponent, IdComponent, IdTCPConnection, IdTCPClient,
  IdHTTP, System.Messaging, Vcl.CheckLst, Vcl.WinXPickers, Vcl.ComCtrls,
  Vcl.ExtDlgs, Vcl.WinXCtrls, Vcl.TitleBarCtrls, Xml.xmldom, Xml.XMLIntf,
  Xml.XMLDoc, IdCustomTCPServer, IdCustomHTTPServer, IdHTTPServer, Vcl.Mask,
  IdContext, System.Win.Registry;

const
  WECHAT_PROCESS_NAME = 'WeChat.exe';
  DLLNAME = 'WeChatHelper.dll';

function ProcessNameFindPID(ProcessName: string): DWORD;

procedure RunSingle();

function WxPath(strAppName, QueryValue: string): string;

function GetTempDirectory: string;

function CheckIsInject(dwProcessid: DWORD): Boolean;

function EnableDebugPrivilege: Boolean;

function InjectDll: boolean;

procedure SendMessageTo(Hwd: HWND; var SendStr: string);

function SendCmdTo(dwData, cbData: Integer; SendStr: string): Boolean;

var
  WxProcess: Thandle;

implementation

function SendCmdTo(dwData, cbData: Integer; SendStr: string): Boolean;
var
  DataStruct: TCopyDataStruct;
begin
  result := false;
  var Hwd := FindWindow(nil, PChar('WeChatHelper'));
  if (Hwd = 0) then
    exit;
  DataStruct.dwData := dwData;

  DataStruct.cbData := cbData;
  if SendStr <> '' then
    DataStruct.lpData := @SendStr
  else
    DataStruct.lpData := nil;

  SendMessage(Hwd, WM_COPYDATA, 0, LongInt(@DataStruct));
  result := true;
end;

procedure SendMessageTo(Hwd: HWND; var SendStr: string);
var
  DataStruct: TCopyDataStruct;
begin

  DataStruct.dwData := 0;

  DataStruct.cbData := 0;

  DataStruct.lpData := @SendStr;

  SendMessage(Hwd, WM_COPYDATA, 0, LongInt(@DataStruct));

end;

function InjectDll: boolean;
var
  szPath: ansistring; //必须定义在外面 且 ansistring
  WxDwProcessId: DWORD;
  pAddress: Pointer;
var
  pi: PROCESS_INFORMATION;
begin
  result := false;
  WxDwProcessId := ProcessNameFindPID(WECHAT_PROCESS_NAME);
  var wx_path: string;
  if (WxDwProcessId = 0) then
  begin
  //启动微信
    wx_path := WxPath('Software\Microsoft\Windows\CurrentVersion\Run', 'Wechat');

    if (wx_path.length < 5) then
      wx_path := WxPath('Software\Tencent\WeChat', 'InstallPath') + '\WeChat.exe';

    var si: STARTUPINFO;

    FillChar(si, SizeOf(si), 0);
    FillChar(pi, SizeOf(pi), 0);
    si.cb := SizeOf(si);

    CreateProcess(pchar(wx_path), nil, nil, nil, FALSE, 0, nil, nil, si, pi);
    var hWechatMainForm: HWND;
    hWechatMainForm := 0;
    while (hWechatMainForm = 0) do
    begin
      hWechatMainForm := FindWindow('WeChatLoginWndForPC', nil);
      Sleep(100);
    end;

    WxDwProcessId := pi.dwProcessId;
    WxProcess := pi.hProcess;
  end;

  if not CheckIsInject(WxDwProcessId) then
  begin
  //  远程注入
    szPath := GetCurrentDir + '\' + DLLNAME;
    var h: thandle;
    h := OpenProcess(PROCESS_ALL_ACCESS, FALSE, WxDwProcessId);
    if (h = 0) then
    begin
      MessageBoxA(NULL, '进程打开失败', '错误', 0);
      Exit;
    end;

    pAddress := VirtualAllocEx(h, nil, MAX_PATH, MEM_COMMIT, PAGE_EXECUTE_READWRITE);

    if (pAddress = nil) then
    begin
      MessageBoxA(NULL, '内存分配失败', '错误', 0);
      CloseHandle(h);
      exit;
    end;
    var NumWrote: SIZE_T;
    if not WriteProcessMemory(h, pAddress, PansiChar(szPath), MAX_PATH, NumWrote) then
    begin
      MessageBoxA(NULL, '路径写入失败', '错误', 0);
      CloseHandle(h);
      VirtualFreeEx(h, pAddress, 0, MEM_RELEASE);
      exit;
    end;
    var hmod := GetModuleHandleA('kernel32.dll');
    var LoadLibraryA_ := GetProcAddress(hmod, 'LoadLibraryA');

    if (LoadLibraryA_ = nil) then
    begin
      MessageBoxA(NULL, '获取LoadLibraryA函数地址失败', '错误', 0);
      CloseHandle(h);
      VirtualFreeEx(h, pAddress, 0, MEM_RELEASE);
      exit;
    end;
    var v: DWORD;

    var hRemoteThread := CreateRemoteThread(h, nil, 0, LoadLibraryA_, pAddress, 0, v);

    if (hRemoteThread = 0) then
    begin
      MessageBoxA(NULL, '远程线程运行失败', '错误', 0);
      CloseHandle(h);
      VirtualFreeEx(h, pAddress, 0, MEM_RELEASE);
      exit;
    end;
    result := true;
    CloseHandle(hRemoteThread);
    CloseHandle(h);
    VirtualFreeEx(h, pAddress, 0, MEM_RELEASE);
  end
  else
  begin
    MessageBoxA(NULL, 'dll已经注入，请勿重复注入', '提示', 0);
    result := True;
  end;

end;

function EnableDebugPrivilege: Boolean;

  function EnablePrivilege(hToken1: Cardinal; PrivName: string; bEnable: Boolean): Boolean;
  var
    TP: TOKEN_PRIVILEGES;
    Dummy: Cardinal;
  begin
    TP.PrivilegeCount := 1;
    LookupPrivilegeValue(Nil, pchar(PrivName), TP.Privileges[0].Luid);
    if bEnable then
      TP.Privileges[0].Attributes := SE_PRIVILEGE_ENABLED
    else
      TP.Privileges[0].Attributes := 0;
    AdjustTokenPrivileges(hToken1, False, TP, SizeOf(TP), Nil, Dummy);
    Result := GetLastError = ERROR_SUCCESS;
  end;

var
  hToken: THandle;
begin
  OpenProcessToken(GetCurrentProcess, TOKEN_ADJUST_PRIVILEGES, hToken);
  result := EnablePrivilege(hToken, 'SeDebugPrivilege', True);
  CloseHandle(hToken);
end;

function CheckIsInject(dwProcessid: DWORD): Boolean;
var
  hModuleSnap: THANDLE;
  me32: TMODULEENTRY32;
begin
  result := false;

  hModuleSnap := INVALID_HANDLE_VALUE;

  me32.dwSize := sizeof(TMODULEENTRY32);

  hModuleSnap := CreateToolhelp32Snapshot(TH32CS_SNAPMODULE, dwProcessid);

  if (hModuleSnap <> INVALID_HANDLE_VALUE) then
  begin

    if (Module32First(hModuleSnap, me32)) then
    begin

      repeat
        if LowerCase(me32.szModule) = DLLNAME.ToLower then
        begin
          result := true;
          break;
        end;
      until (Module32Next(hModuleSnap, me32));

    end
    else
    begin
      MessageBoxA(NULL, '获取第一个模块的信息失败', '错误', MB_OK);
      CloseHandle(hModuleSnap);

    end;
  end;
end;

function GetTempDirectory: string;
var
  lpBuffer: array[0..MAX_PATH] of Char;
begin
  GetTempPath(MAX_PATH, @lpBuffer);
  Result := StrPas(lpBuffer);
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

procedure RunSingle();
begin
  var hMutex: tHANDLE;
  var ExitValue := -1;
  hMutex := 0;
  hMutex := CreateMutexA(nil, FALSE, 'single_object');
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

//function ProcessNameFindPID(ProcessName: string): DWORD;
//begin
//  result := 0;
//  var pe32: PROCESSENTRY32;
//  ZeroMemory(@pe32, sizeof(PROCESSENTRY32));
//  pe32.dwSize := sizeof(PROCESSENTRY32);
//  var hProcess: THANDLE;
//  hProcess := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
//  if (Process32First(hProcess, pe32)) then
//  begin
//    repeat
//      if LowerCase(pe32.szExeFile) = ProcessName.ToLower then
//      begin
//        result := pe32.th32ProcessID;
//        break;
//      end;
//    until (Process32Next(hProcess, pe32));
//  end;
//end;

end.

