unit injectAutoRecvMsgModule;

interface
  //取得好友列表

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, tlhelp32,
  PsAPI, Vcl.StdCtrls, Vcl.ExtCtrls, u_debug, DDetours, Method2,
  System.Messaging, Generics.Collections, wxCore;



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

var
  ChatMessageData: TChatMessageData;


procedure show_item_data();
var
  len: Cardinal;
  p1: Nativeuint;
  pwxid: pchar;
var
  Message: TMessage;
  vvv: string;
begin
  const GroupMsgSenderOffset = $164;
  const MsgSourceOffset = $1b8;
  const MsgTypeOffset = $30;
  const WxidOffset = $40;
  const MsgContentOffset = $68;

  if Winapi.Windows.IsBadReadPtr(Pointer(data_base), 4) or IsBadReadPtr(Pointer(data_base + MsgTypeOffset), 4) or (IsBadReadPtr(PDWORD(data_base + MsgContentOffset), 4)) or (IsBadReadPtr(PDWORD(data_base + WxidOffset), 4)) or (IsBadReadPtr(PDWORD(data_base + GroupMsgSenderOffset), 4)) then
    Exit;


      //取出消息类型
  ChatMessageData.dwtype := PDWORD(data_base + MsgTypeOffset)^;

//  debug.Show('消息类型：' + IntToHex(ChatMessageData.dwtype));



          //取出消息内容
  p1 := data_base + MsgContentOffset;
  ChatMessageData.content := PChar(Pointer((@p1)^)^);

           //取出微信ID/群ID
  p1 := data_base + WxidOffset;
  ChatMessageData.wxid := PChar(Pointer((@p1)^)^);

//  debug.Show('wxid:' + ChatMessageData.wxid);
  if ChatMessageData.wxid.Contains('gh_') then
    Exit;



//消息发送者
  p1 := data_base + GroupMsgSenderOffset;
  if Winapi.Windows.IsBadReadPtr(Pointer(p1), 4) then
    Exit;
  ChatMessageData.sender := PChar(Pointer((@p1)^)^);

//  debug.Show('ChatMessageData.sender:' + ChatMessageData.sender);


//                 消息来源
  p1 := data_base + MsgSourceOffset;
  if Winapi.Windows.IsBadReadPtr(Pointer(p1), 4) then
    Exit;
  if ChatMessageData.wxid <> 'fmessage' then
  begin
    ChatMessageData.Source := MsgSourceOffset + PChar(Pointer((@p1)^)^);
//    debug.Show('ChatMessageData.Source:' + ChatMessageData.Source);
  end
  else
    ChatMessageData.Source := '';

  DefineNotify.MsgStruct := ChatMessageData;
  DefineNotify.protocol := 91;
  Message := TMessage<TDefineNotify>.Create(DefineNotify);
  message_bus.SendMessage(nil, Message, True);
end;

procedure NewFuncAddr();
asm
        pushad
        mov     data_base, eax
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
  OldFuncAddr := g_baseaddr + $3df42c;

  OldFunc := Pointer(g_baseaddr + $87a70);

  JumpBackAddress := OldFuncAddr + SizeOf(TInstruction);  // +5  跳回地址继续执行
//  保留原来的地址指令     复原使用
  CopyMemory(@OldInstructionBackUp, Pointer(OldFuncAddr), 5);  //memcpy


  f3(@NewFuncAddr, Pointer(OldFuncAddr));

end.

