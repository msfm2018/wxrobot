unit Method1;

interface
 uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, tlhelp32,
  PsAPI, Vcl.StdCtrls, Vcl.ExtCtrls, u_debug, DDetours;

var
  jmpCode: array[0..4] of Byte;

  procedure F1(new_addr,HookAddress:pointer);
implementation


procedure F1(new_addr,HookAddress:pointer);
begin

  ZeroMemory(@jmpcode[0], 5);
  jmpCode[0] := $E9;
//	*(DWORD*)&jmpCode[1] = (DWORD)HookFun - HookAddress - 5;
//jmpCode[1]:=    Pointer(HookAddress)
  var tmp: dword;
//  iix := NativeInt(@new_addr) - NativeInt(Pointer(HookAddress)) - 5;
 tmp := NativeInt(new_addr) - NativeInt(HookAddress) - 5;
  move(tmp, jmpcode[1], 4);

  var xv: SIZE_T;
  WriteProcessMemory(GetCurrentProcess(), Pointer(HookAddress), @jmpCode[0], 5, xv);
end;
end.
