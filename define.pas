unit define;

interface

uses
  Winapi.Messages;

type
  PTUserInfo = ^TUserInfo;
//好友列表   UserInfo

//  TUserInfo = packed record
//    wxid: string;
//    wxNumber: string; //微信号
//    Remark: string;
//    nickname: string;
//
//  end;

////  TUserInfo = packed record
    TUserInfo = packed record
    wxid: array[0..79]  of  char;
    wxNumber:array[0..79]  of  char;
    Remark: array[0..79]  of  char;
    nickname: array[0..79]  of  char;
  end;

//客户端和服务端通讯消息

const
  WM_Login = 0;
  WM_ShowQrPicture = 1;
  WM_Logout = 2;
  WM_GetFriendList = 3;
  WM_ShowChatRecord = 4;
  WM_SendTextMessage = 5;
  WM_SendFileMessage = 6;
  WM_GetInformation = 7;
  WM_SendImageMessage = 8;
  WM_SetRoomAnnouncement = 9;
  WM_DeleteUser = 10;
  WM_QuitChatRoom = 11;
  WM_AddGroupMember = 12;
  WM_SendXmlCard = 13;
  WM_ShowChatRoomMembers = 14;
  WM_ShowChatRoomMembersDone = 15;
  WM_DecryptDatabase = 16;
  WM_AddUser = 17;
  WM_SetRoomName = 18;
  WM_AutoChat = 19;
  WM_CancleAutoChat = 20;
  WM_AlreadyLogin = 21;
  WM_SendAtMsg = 22;
  WM_DelRoomMember = 23;
  WM_OpenUrl = 24;
  WM_InviteGroupMember = 26;
  WM_SendXmlArticle = 27;
  WM_GetFriendInfomations = 28;
  WM_TimerToSend = 29;
  WM_CancelTimerToSend = 30;
  WM_SetRemark = 31;
  WM_CreateChatRoom = 32;
  WM_ModifyVersion = 33;
  WM_DecodeImage = 34;
  WM_SendVideoMessage = 35;
  WM_SendGifMessage = 36;
  WM_TopMsg = 37;
  WM_CancleTopMsg = 38;
  WM_OpenNewMsgNotify = 39;
  WM_MsgNoDisturb = 40;
  WM_FollowPublicAccount = 41;
  WM_KeywordsReplyOpen = 43;
  WM_KeywordsReplyClose = 44;


//窗口通讯的自定义消息
  WM_ShowFriendList = WM_USER + 100;
  WM_ShowMessage = WM_USER + 101;
  SaveFriendList = WM_USER + 102;

//聊天机器微信ID
  ChatRobotWxID = 'gh_f0e9306d8d03';

implementation

end.

