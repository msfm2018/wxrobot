unit injectFriendModule;

interface
  //取得好友列表

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, tlhelp32,
  PsAPI, Vcl.StdCtrls, Vcl.ExtCtrls, u_debug, DDetours, Method2,
  System.Messaging, Generics.Collections, wxCore, GGlobal;

var
  OldFuncAddr: dword;
  OldFunc: pointer;   //  OldFuncAddr   call OldFunc
  OldInstructionBackUp: array[0..4] of Byte; //老指令备份
  JumpBackAddress: dword;
  str: string;
  ddd: PChar;
  mystr: string;
  data_base: dword;

implementation

uses
  Method1, Method3, PubSub;



  //////////////
procedure show_item_data();
var
  len: Cardinal;
  p1: Nativeuint;
var
  Message: TMessage;
  FriendStruct1: TFriendList;
begin



//    form2.ListBox1.Items.Insert(0, v.ToString);
  len := PDWORD(data_base + 4 + 4 + 4)^;   // wxid_len
//  len := PDWORD(v + 4 + 4 + 4)^;   // wxid_len
//
  p1 := data_base + 4 + 4;

  FriendStruct1.wxid := PChar(Pointer((@p1)^)^);

  if FriendStruct1.wxid.Contains('gh_') or FriendStruct1.wxid.Contains('filehelper') or FriendStruct1.wxid.Contains('fmessage') or FriendStruct1.wxid.Contains('qqmail') or FriendStruct1.wxid.Contains('medianote') or FriendStruct1.wxid.Contains('qmessage') or FriendStruct1.wxid.Contains('newsapp') or FriendStruct1.wxid.Contains('weixin') or FriendStruct1.wxid.Contains('qqsafe') or FriendStruct1.wxid.Contains('tmessage') or FriendStruct1.wxid.Contains('mphelper') then
    Exit;

  p1 := data_base + $64;
  FriendStruct1.nickname := PChar(Pointer((@p1)^)^);

  p1 := data_base + $1c;
  FriendStruct1.wxNumber := PChar(Pointer((@p1)^)^);

  p1 := data_base + $50;
  FriendStruct1.Remark := PChar(Pointer((@p1)^)^);

  g_userinfolist.TryAdd(FriendStruct1.wxid, FriendStruct1.nickname);

  DefineNotify.FriendStruct := FriendStruct1;
  DefineNotify.protocol := 90;
  Message := TMessage<TDefineNotify>.Create(DefineNotify);
  message_bus.SendMessage(nil, Message, True);
end;

procedure NewFuncAddr();
asm
        pushad
        mov     data_base, esi
        call    show_item_data
        popad
        call    OldFunc;
        jmp     JumpBackAddress
end;

procedure UnHook;
  //恢复原指令
begin
  var xv: SIZE_T;
  WriteProcessMemory(GetCurrentProcess(), Pointer(OldFuncAddr), @OldInstructionBackUp, 5, xv);
end;

initialization
  g_baseaddr := GetModuleHandle('WeChatWin.dll');
  OldFuncAddr := g_baseaddr + $5244a8;

  OldFunc := Pointer(g_baseaddr + $64550);

  JumpBackAddress := OldFuncAddr + SizeOf(TInstruction);  // +5  跳回地址继续执行
//  保留原来的地址指令     复原使用
  CopyMemory(@OldInstructionBackUp, Pointer(OldFuncAddr), 5);  //memcpy


  f3(@NewFuncAddr, Pointer(OldFuncAddr));

finalization

end.

