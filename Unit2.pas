unit Unit2; //微信代码学习3.2.1.154

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, tlhelp32,
  Jpeg, u_debug, PsAPI, Vcl.StdCtrls, Vcl.ExtCtrls, IdBaseComponent, IdComponent,
  IdTCPConnection, IdTCPClient, IdHTTP, System.Messaging, Vcl.CheckLst,
  Vcl.WinXPickers, Vcl.ComCtrls, Vcl.ExtDlgs, Vcl.WinXCtrls, Vcl.TitleBarCtrls,
  Vcl.Imaging.pngimage, Vcl.Menus, Xml.xmldom, Xml.XMLIntf, Xml.XMLDoc,
  IdCustomTCPServer, IdCustomHTTPServer, IdHTTPServer, Vcl.Mask, IdContext,
  Generics.Collections, define, ImgPanel, utils;

const
  WM_MyMessage = WM_USER + $200;

const
  WM_MY_PING = WM_USER + 3024;

type
  Tmain = class(TForm)
    Panel2: TPanel;
    Panel3: TPanel;
    CheckBox1: TCheckBox;
    Panel1: TPanel;
    Button2: TButton;
    lv_recv: TListView;
    lb__receipt: TCheckListBox;
    BtnExport: TButton;
    SaveTextFileDialog1: TSaveTextFileDialog;
    PageControl1: TPageControl;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    TabSheet3: TTabSheet;
    TabSheet4: TTabSheet;
    pnl_left: TPanel;
    l2: TLabel;
    l1: TLabel;
    l5: TLabel;
    pnl_right: TPanel;
    l3: TLabel;
    edtLookup: TSearchBox;
    SearchBox1: TSearchBox;
    Button1: TButton;
    XMLDoc: TXMLDocument;
    Edit1: TEdit;
    Memo1: TEdit;
    CheckBox2: TCheckBox;
    Label5: TLabel;
    pnlQr: TPanel;
    imgQr: TImage;
    btnQr: TButton;
    Button3: TButton;
    lv1: TListView;
    Button4: TButton;
    Panel5: TPanel;
    procedure FormShow(Sender: TObject);
    procedure l1Click(Sender: TObject);
    procedure l2Click(Sender: TObject);
    procedure l3Click(Sender: TObject);
    procedure l5Click(Sender: TObject);
    procedure edtLookupKeyPress(Sender: TObject; var Key: Char);
    procedure Memo1MouseEnter(Sender: TObject);
    procedure Memo1MouseLeave(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Edit1MouseEnter(Sender: TObject);
    procedure Edit1MouseLeave(Sender: TObject);
    procedure btnQrClick(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);

  private

    //消息订阅
    procedure sub;
    procedure setColorBtn(c1, c2, c3, c4, c5, c6, c7: Boolean);

//    procedure RecvMessage(var aMsg: Winapi.Messages.tmessage); message WM_COPYDATA;
    procedure RecvMessage(var aMsg: TWMCOPYDATA); message WM_COPYDATA;
    procedure ExchangeItems(lv: TListView; const i, j: Integer);
  end;

var
  main: Tmain;
  UserList: TList<tUserInfo>;

implementation
{$R *.dfm}

uses
  pubsub;




//procedure Tmain.RecvMessage(var aMsg: Winapi.Messages.tmessage);

procedure Tmain.RecvMessage(var aMsg: TWMCOPYDATA);
var
  Message: TMessage;
var
  u: tUserInfo;
begin
  if aMsg.Msg = WM_COPYDATA then
  begin

    case aMsg.CopyDataStruct.dwData of
      WM_Login:
        begin
          Debug.Show('login');
        end;

      WM_ShowQrPicture:
        begin
        end;
      wm_logout:
        begin

        end;
      WM_GetFriendList:
        begin
          pnlQr.Visible := false;
          if Winapi.Windows.IsBadReadPtr(aMsg.CopyDataStruct.lpData, 4) then
            Exit;
          u := PTUserInfo(aMsg.CopyDataStruct.lpData)^;
          UserList.Add(u);



//          TThread.CreateAnonymousThread(
//            procedure
//            begin
//              TThread.Synchronize(nil,
//                procedure
//                begin
//
//                  var item1 := lv1.items.add;
//
//                  try
//                        if tmp.wxid='' then exit;
//
//                    item1.caption := tmp.wxid;
//
//                    item1.subitems.add(tmp.wxNumber);
//                    item1.subitems.add(tmp.nickname);
//                    item1.subitems.add(tmp.Remark);
//                  except
//                  end;
//                end)
//            end).Start;
//            DefineNotify.FriendStruct := FriendStruct1;
//            DefineNotify.protocol := 90;
//            Message := TMessage<TDefineNotify>.Create(DefineNotify);
//            message_bus.SendMessage(nil, Message, True);
        end;
    end;
  end;

end;

procedure Tmain.Button4Click(Sender: TObject);
var
  item1: Tlistitem;
begin
  lv1.Clear;
        caption:=UserList.Count.ToString;
  for var I := 0 to UserList.Count - 1 do
  begin
    item1 := lv1.items.add;
    try
    item1.caption := UserList[i].wxid;
//    if 'zjxzhuangjiaxing'=UserList[i].wxNumber then

    item1.subitems.add(UserList[i].wxNumber);
    item1.subitems.add(UserList[i].nickname+' No:'+i.ToString);
    item1.subitems.add(UserList[i].Remark);
    except

    end;
  end;
end;

procedure tmain.sub;
var
  auto_vv1, auto_vv2: string;
var
  item1: Tlistitem;
  ChatMessageData: TChatMessageData;
  FriendStruct1: tuserinfo;
begin
  MsgListener :=
    procedure(const Sender: TObject; const M: TMessage)
    begin
      if (M as TMessage<TDefineNotify>).Value.protocol = 90 then
      begin

        FriendStruct1 := (M as TMessage<TDefineNotify>).Value.FriendStruct;

        if lv1.FindCaption(0, FriendStruct1.wxid, false, true, true) = nil then
        begin
          item1 := lv1.items.add;
          begin

            item1.caption := FriendStruct1.wxid;

//              item1.subitems.add(FriendStruct1.wxNumber);
//              item1.subitems.add(FriendStruct1.nickname);
//              item1.subitems.add(FriendStruct1.Remark);

          end;
        end;

      end
      else if (M as TMessage<TDefineNotify>).Value.protocol = 91 then
      begin

        PostMessage(handle, WM_MyMessage, integer(Pchar(ChatMessageData.wxid)), integer(Pchar(ChatMessageData.content)));
      end;
    end;
end;

procedure Tmain.Edit1MouseEnter(Sender: TObject);
begin
  edit1.Color := clWhite;
end;

procedure Tmain.Edit1MouseLeave(Sender: TObject);
begin
  edit1.Color := $f5f5f5;
end;

procedure Tmain.ExchangeItems(lv: TListView; const i, j: Integer);
//move down :
//ExchangeItems(lst_detile,lst_detile.Selected.Index,lst_detile.Selected.Index+1);
//move up :
//ExchangeItems(lst_detile,lst_detile.Selected.Index,lst_detile.Selected.Index-1);
var
  tempLI: TListItem;
begin
  lv.Items.BeginUpdate;
  try
    tempLI := TListItem.Create(lv.Items);
    tempLI.Assign(lv.Items.Item[i]);
    lv.Items.Item[i].Assign(lv.Items.Item[j]);
    lv.Items.Item[j].Assign(tempLI);
    tempLI.Free;
  finally
    lv.Items.EndUpdate
  end;
end;

procedure Tmain.edtLookupKeyPress(Sender: TObject; var Key: Char);
var
  strkeyword: string;
  inx: Integer;
begin
  if Key <> #13 then
    Exit;

  strkeyword := trim(edtlookup.text);
  if strkeyword <> '' then
  begin
    for inx := 0 to lv1.Items.Count - 1 do
    begin
      if lv1.Items[inx].SubItems[1].Contains(strkeyword) then
      begin
        lv1.Items[inx].Selected := true;
        ExchangeItems(lv1, lv1.Selected.Index, 0);
        lv1.Items[1].Selected := false;
        edtlookup.text := '';
      end;
    end;
  end;
  edtlookup.SetFocus;

end;

procedure Tmain.Button3Click(Sender: TObject);
begin
  SendCmdTo(WM_Logout, 0, '');
end;

procedure tmain.setColorBtn(c1, c2, c3, c4, c5, c6, c7: Boolean);
begin
  l1.Transparent := c1;
  l2.Transparent := c2;
  l3.Transparent := c3;
  l5.Transparent := c5;
end;

procedure Tmain.l2Click(Sender: TObject);
begin
  PageControl1.ActivePage := TabSheet2;
  setColorBtn(True, false, True, True, True, true, true);
  memo1.SetFocus;
end;

procedure Tmain.l1Click(Sender: TObject);
begin
  PageControl1.ActivePage := TabSheet1;

  setColorBtn(false, true, True, True, True, true, true);
  edit1.SetFocus;
end;

procedure Tmain.btnQrClick(Sender: TObject);
begin

//   二维码   WM_ShowQrPicture
  if SendCmdTo(WM_ShowQrPicture, 0, '') then
  begin
    Sleep(500);
    while true do
    begin
      if FileExists(GetTempDirectory + 'qrcode.png') then
        break;
    end;
    Sleep(500);
    var Png: TPngObject;
    try
      Png := TPngObject.Create;
      try

        Png.LoadFromFile(GetTempDirectory + 'qrcode.png');
        imgqr.Picture.Assign(Png);
      finally
        Png.Free;
      end;
      var tmp: ansistring;
      tmp := GetTempDirectory + 'qrcode.png';
      DeleteFileA(pansichar(tmp));
    except

    end;
  end;
end;

procedure Tmain.l5Click(Sender: TObject);
begin
  PageControl1.ActivePage := TabSheet4;
  setColorBtn(True, True, True, True, false, true, true);
end;

procedure Tmain.l3Click(Sender: TObject);
begin
  PageControl1.ActivePage := TabSheet3;
  setColorBtn(True, True, false, True, True, true, true);
end;

procedure Tmain.Memo1MouseEnter(Sender: TObject);
begin
  Memo1.Color := clWhite;
end;

procedure Tmain.Memo1MouseLeave(Sender: TObject);
begin
  Memo1.Color := $f5f5f5;
end;

procedure Tmain.FormCreate(Sender: TObject);
begin

  RunSingle();
  if not InjectDll then
    ShowMessage('注入失败');

end;

procedure Tmain.FormShow(Sender: TObject);
begin

  pnlQr.BringToFront;
  sub();
  SubscriptionId := message_bus.SubscribeToMessage(TMessage<TDefineNotify>, MsgListener);

  with lv_recv do
  begin
    Columns.Add;
    Columns.Add;
    Columns.Add;
    ViewStyle := vsreport;
    GridLines := true;
    columns.items[0].caption := 'wxid';
    columns.items[1].caption := '发送者';
    columns.items[2].caption := '消息';
    Columns.Items[0].Width := 200;
    Columns.Items[1].Width := 300;
    Columns.Items[2].Width := lv_recv.Width - 200 - 300 - 10;
  end;

  var i: integer;
  for i := 0 to PageControl1.PageCount - 1 do
    PageControl1.Pages[i].TabVisible := False;

  l1Click(self);

end;

initialization
  UserList := TList<tUserInfo>.create;

end.

