unit PubSub;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, System.Messaging;

type
  //聊天记录的消息结构体
  TChatMessageData = packed record
    dwtype: DWORD;				//消息类型
    sztype, 		//消息类型
    source,		//消息来源
    wxid, //微信ID/群ID
    wxname,		//微信名称/群名称
    sender,		//消息发送者
    sendername,		//消息发送者昵称
    content: string;	//消息内容
  end;
//   好友列表

  TFriendList = packed record
    wxid: string;
    nickname: string;
    Remark:string;
    wxNumber:string;//微信号
  end;





  TDefineNotify = record
    TxtData: string;
    MsgStruct: TChatMessageData;
    FriendStruct:TFriendList;
    protocol: Integer;    //90 文本好友列表         91 结构体 接收消息
  end;

var
  DefineNotify: TDefineNotify;

var
  message_bus: TMessageManager;

var
  SubscriptionId: Integer;

var
  MsgListener: TMessageListener;

implementation

initialization
  message_bus := TMessageManager.DefaultManager;

end.

