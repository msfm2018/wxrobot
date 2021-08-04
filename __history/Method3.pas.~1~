unit Method3;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, tlhelp32,
  PsAPI, Vcl.StdCtrls, Vcl.ExtCtrls, u_debug, DDetours;

type
//  TDv = function(): Integer; stdcall;   这里如何定义 TDV 不影响
  TDv = function(x, y: Integer): Integer; stdcall;

var
  newDv: TDv = nil;

function f3(new_addr,HookAddress: Pointer): Pointer;
procedure f3_dis();
implementation

function f3(new_addr,HookAddress: Pointer): Pointer;
begin
  result := InterceptCreate(HookAddress, new_addr);
  newDv := result;
end;

procedure f3_dis();
begin
  if Assigned(newDv) then
  begin
    InterceptRemove(@newDv);
    newDv := nil;
  end;
end;

end.

