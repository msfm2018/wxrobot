unit Unit2; //微信代码学习3.2.1.154

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, tlhelp32,
  Jpeg, u_debug, PsAPI, Vcl.StdCtrls, Vcl.ExtCtrls, IdBaseComponent, IdComponent, qrenc, IdTCPConnection, IdTCPClient, IdHTTP, System.Messaging,
  Vcl.CheckLst, Vcl.WinXPickers, Vcl.ComCtrls, Vcl.ExtDlgs, Vcl.WinXCtrls, Vcl.TitleBarCtrls, Vcl.Imaging.pngimage, ImgPanel, Vcl.Menus, GGlobal,
  uWinApi, replayWindow, Xml.xmldom, Xml.XMLIntf, Xml.XMLDoc;

const
  WM_MyMessage = WM_USER + $200;

type
  TForm2 = class(TForm)
    IdHTTP1: TIdHTTP;
    Panel2: TPanel;
    Panel3: TPanel;
    CheckBox1: TCheckBox;
    LbUsers: TCheckListBox;
    Timer1: TTimer;
    pnlQr: TPanel;
    btnQr: TButton;
    imgQr: TImage;
    Panel1: TPanel;
    Button2: TButton;
    CheckBox3: TCheckBox;
    lv_recv: TListView;
    lb__receipt: TCheckListBox;
    BtnExport: TButton;
    SaveTextFileDialog1: TSaveTextFileDialog;
    Label7: TLabel;
    PageControl1: TPageControl;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    TabSheet3: TTabSheet;
    TabSheet4: TTabSheet;
    TabSheet5: TTabSheet;
    pnl_left: TPanel;
    imgboxFace: TImage;
    l2: TLabel;
    l1: TLabel;
    l5: TLabel;
    pnl_right: TPanel;
    btn_max1: TImgPanel;
    Label2: TLabel;
    Label3: TLabel;
    l3: TLabel;
    l4: TLabel;
    edtLookup: TSearchBox;
    SearchBox1: TSearchBox;
    PopupMenu1: TPopupMenu;
    N1: TMenuItem;
    Panel4: TPanel;
    Image2: TImage;
    ImgPanel1: TImgPanel;
    Label1: TLabel;
    Button1: TButton;
    Label4: TLabel;
    XMLDoc: TXMLDocument;
    Edit1: TEdit;
    Memo1: TEdit;
    procedure Button1Click(Sender: TObject);
    procedure btnQrClick(Sender: TObject);
    procedure CheckBox1Click(Sender: TObject);
    procedure LbUsersDblClick(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure CheckBox3Click(Sender: TObject);
    procedure doMyMessage(var mymsg: Winapi.Messages.TMessage); message WM_MyMessage;
    procedure BtnExportClick(Sender: TObject);
    procedure lv_recvChange(Sender: TObject; Item: TListItem; Change: TItemChange);
    procedure pnl_leftMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure l4Click(Sender: TObject);
    procedure l1Click(Sender: TObject);
    procedure l2Click(Sender: TObject);
    procedure l3Click(Sender: TObject);
    procedure l5Click(Sender: TObject);
    procedure edtLookupKeyPress(Sender: TObject; var Key: Char);
    procedure SearchBox1KeyPress(Sender: TObject; var Key: Char);
    procedure lv_recvDblClick(Sender: TObject);
    procedure N1Click(Sender: TObject);
    procedure btn_max1Click(Sender: TObject);
    procedure Image2MouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure N2Click(Sender: TObject);
    procedure ImgPanel1Click(Sender: TObject);
    procedure Memo1MouseEnter(Sender: TObject);
    procedure Memo1MouseLeave(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormPaint(Sender: TObject);
    procedure Edit1KeyPress(Sender: TObject; var Key: Char);
    procedure Edit1MouseEnter(Sender: TObject);
    procedure Edit1MouseLeave(Sender: TObject);
    procedure lb__receiptDblClick(Sender: TObject);
  private
    UsrCount: Integer;
    FList: TProcessRecList;
    procedure head_pic;
    function GetValue(offset: dword): ansistring;
    //消息订阅
    procedure sub;
    procedure setColorBtn(c1, c2, c3, c4, c5: Boolean);
    procedure GetWeChatProcess;
    function IsTagetPid(APid: THandle): boolean;
    procedure SetWnd(w, h: Integer);
  end;

var
  Form2: TForm2;
  g_data_txt: string;

implementation
{$R *.dfm}

uses
  wxCore, PubSub;

procedure tform2.sub;
var
  auto_vv1, auto_vv2: string;
var
  ChatMessageData: TChatMessageData;
begin
  MsgListener :=
    procedure(const Sender: TObject; const M: TMessage)
    begin
      if (M as TMessage<TDefineNotify>).Value.protocol = 90 then
      begin

        var FriendStruct1 := (M as TMessage<TDefineNotify>).Value.FriendStruct;
        if FriendStruct1.wxid.Contains('gh_') or FriendStruct1.wxid.Contains('filehelper') or FriendStruct1.wxid.Contains('fmessage') or FriendStruct1.wxid.Contains
          ('qqmail') or FriendStruct1.wxid.Contains('medianote') or FriendStruct1.wxid.Contains('qmessage') or FriendStruct1.wxid.Contains('newsapp')
          or FriendStruct1.wxid.Contains('weixin') or FriendStruct1.wxid.Contains('qqsafe') or FriendStruct1.wxid.Contains('tmessage') or FriendStruct1.wxid.Contains('mphelper') then
          Exit
        else
        begin
          var vvalue: string;
          if FriendStruct1.remark.Trim = '' then
            vvalue := get_space(LbUsers.Handle, lbusers.Font.Handle, FriendStruct1.wxid, v1_standard) + get_space(LbUsers.Handle, lbusers.Font.Handle, FriendStruct1.nickname, v2_standard)
          else
            vvalue := get_space(LbUsers.Handle, lbusers.Font.Handle, FriendStruct1.wxid, v1_standard) + get_space(LbUsers.Handle, lbusers.Font.Handle,
              FriendStruct1.nickname, v2_standard) + '备注:' + FriendStruct1.remark;

          if LbUsers.Items.IndexOf(vvalue) = -1 then
          begin
            inc(UsrCount);

            label4.Caption := '好友数量 ' + UsrCount.ToString;
            LbUsers.Items.Add(vvalue);
            lb__receipt.Items.Add(get_space(lb__receipt.Handle, lb__receipt.Font.Handle, FriendStruct1.wxid, v1_standard) + FriendStruct1.nickname);
          end;
        end;
      end
      else if (M as TMessage<TDefineNotify>).Value.protocol = 91 then
      begin
        var isFriendMsg := FALSE;		//是否是好友消息
        var isImageMessage := FALSE;	//是否是图片消息
        var isRadioMessage := FALSE;	//是否是视频消息
        var isVoiceMessage := FALSE;	//是否是语音消息
        var isBusinessCardMessage := FALSE;	//是否是名片消息
        var isExpressionMessage := FALSE;	//是否是名片消息
        var isLocationMessage := FALSE;	//是否是位置消息
        var isSystemMessage := FALSE;	//是否是系统或红包消息
        var isPos_File_Money_XmlLink := FALSE;			//是否位置 文件 转账和链接消息
        var isFriendRequestMessage := FALSE;	//是否是好友请求消息
        var isOther := FALSE;	//是否是其他消息
        ChatMessageData := (M as TMessage<TDefineNotify>).Value.MsgStruct;

        case ChatMessageData.dwtype of
          $01:
            begin
              ChatMessageData.sztype := '文字';
            end;
          $03:
            begin
              ChatMessageData.sztype := '图片';
              isImageMessage := TRUE;
            end;
          $22:
            begin
              ChatMessageData.sztype := '语音';
              isVoiceMessage := TRUE;
            end;
          $25:
            begin
              ChatMessageData.sztype := '好友确认';
//              Debug.Show('好友确认');
              isFriendRequestMessage := TRUE;
            end;
          $28:
            begin
              ChatMessageData.sztype := 'POSSIBLEFRIEND_MSG';
              isOther := TRUE;
            end;
          $2a:
            begin
              ChatMessageData.sztype := '名片';
              isBusinessCardMessage := TRUE;
            end;
          $2b:
            begin
              ChatMessageData.sztype := '视频';
              isRadioMessage := TRUE;
            end;
          $2f:   //石头剪刀布
            begin
              ChatMessageData.sztype := '表情';
              isExpressionMessage := TRUE;
            end;
          $30:
            begin
              ChatMessageData.sztype := '位置';
              isLocationMessage := TRUE;
            end;
          $31:
            begin
            //共享实时位置
			//文件
			//转账
			//链接
			//收款
              ChatMessageData.sztype := '共享实时位置、文件、转账、链接';
              isPos_File_Money_XmlLink := TRUE;
            end;
          $32:
            begin
              ChatMessageData.sztype := 'VOIPMSG';
              isOther := TRUE;
            end;
          $33:
            begin
              ChatMessageData.sztype := '微信初始化';
              isOther := TRUE;
            end;
          $34:
            begin
              ChatMessageData.sztype := 'VOIPNOTIFY';
              isOther := TRUE;
            end;
          $35:
            begin
              ChatMessageData.sztype := 'VOIPINVITE';
              isOther := TRUE;
            end;
          $3e:
            begin
              ChatMessageData.sztype := '小视频';
              isRadioMessage := TRUE;
            end;
          $270F:
            begin
              ChatMessageData.sztype := 'SYSNOTICE';
              isOther := TRUE;
            end;
          $2710:
            begin
              ChatMessageData.sztype := '系统消息';
              isSystemMessage := TRUE;
            end;
          $2712:
            begin
              ChatMessageData.sztype := '提现消息';
            end;
        end;
        var fullmessgaedata := (ChatMessageData.content);	//完整的消息内容
        var tempcontent := ChatMessageData.content;	//完整的消息内容
        var wxid_wstr := ChatMessageData.wxid;
        if wxid_wstr.Contains('@im.chatroom') then
          ChatMessageData.source := '企业微信群消息'
        else if wxid_wstr.Contains('@chatroom') then
          ChatMessageData.source := '群消息'
        else
        begin
          ChatMessageData.source := '好友消息';
          isFriendMsg := TRUE;
          ChatMessageData.sendername := '';
        end;
        //将微信ID转为微信昵称/群名称
        var transformwxid := (ChatMessageData.wxid);

        g_userinfolist.TryGetValue(transformwxid, ChatMessageData.wxname);

               //将群发送者微信ID转换为发送着昵称
        if (isFriendMsg = FALSE) then
        begin                   	//根据微信ID获取详细信息这里有问题
          tmp_GetNicknameByWxid := ChatMessageData.sender;
          ChatMessageData.sendername := GetNicknameByWxid();
        end;
         //显示消息内容  过滤无法显示的消息 防止奔溃
        if (ChatMessageData.wxid.Contains('gh')) then
        begin
          isFriendMsg := FALSE;
            	//如果是聊天机器人发来的消息 并且消息已经发送给机器人
//			if ((StrCmpW(msg->wxid, ChatRobotWxID) == 0) && isSendTuLing)
//			{
//				SendTextMessage(tempwxid, msg->content);
//				isSendTuLing = FALSE;
//			}
			//如果微信ID为gh_3dfda90e39d6 说明是收款消息

          if ChatMessageData.wxid.Contains('gh_3dfda90e39d6') then
            ChatMessageData.content := '微信收款到账'
          else
            ChatMessageData.content := '公众号发来推文,请在手机上查看';

        end
        else if (isImageMessage = TRUE) then
          ChatMessageData.content := '收到图片消息'
        else if (isRadioMessage = TRUE) then
          ChatMessageData.content := '收到视频消息,请在手机上查看'
        else if (isVoiceMessage = TRUE) then
          ChatMessageData.content := '收到语音消息,请在手机上查看'
        else if (isBusinessCardMessage = TRUE) then
          ChatMessageData.content := '收到名片消息,已自动添加好友'
        else if (isExpressionMessage = TRUE) then
          ChatMessageData.content := '收到表情消息,请在手机上查看'
        else if (isFriendRequestMessage = TRUE) then
        begin
			//自动通过好友请求
		 //	AutoAgreeUserRequest(fullmessgaedata);


          XMLDoc.LoadFromXML(fullmessgaedata);
          XMLDoc.Active := True;

          auto_vv1 := XMLDoc.DocumentElement.AttributeNodes['encryptusername'].NodeValue;

          auto_vv2 := XMLDoc.DocumentElement.AttributeNodes['ticket'].NodeValue;

          AgreeUserRequest(auto_vv1, auto_vv2);
          ChatMessageData.content := '收到好友请求,已自动通过'; //+ fullmessgaedata;
//          Debug.Show(ChatMessageData.content);

        end
        else if (isPos_File_Money_XmlLink = TRUE) then
        begin
          if tempcontent.Contains('<type>2000</type>') then
          begin
            ChatMessageData.sztype := '转账消息';

//   AutoCllectMoney(fullmessgaedata, msg->wxid);
            ChatMessageData.content := '收到转账消息,已自动收款';

          end
          else if tempcontent.Contains('<type>5</type>') then
          begin
            //邀请入群的链接
            if (fullmessgaedata.Contains('<![CDATA[邀请你加入群聊]]></title>')) then
            begin
              ChatMessageData.sztype := '群邀请';
              ChatMessageData.content := '收到群邀请,请在手机上查看';

            end				//留言入选通知
            else if (fullmessgaedata.Contains('留言入选通知')) then
            begin
              ChatMessageData.sztype := '留言入选';
              ChatMessageData.content := '公众号留言入选通知,请在手机上查看';
            end
            else
            begin
					//否则 说明是XML文章链接
              ChatMessageData.sztype := 'XML文章消息';
              ChatMessageData.content := '收到XML文章消息,请在手机上查看';
            end
          end
          else if tempcontent.Contains('<type>6</type>') then
          begin
            ChatMessageData.sztype := '文件消息';
            ChatMessageData.content := '收到文件 请及时查看';
          end			//共享实时位置消息
          else if tempcontent.Contains('<type>17</type>') then
          begin
            ChatMessageData.sztype := '共享实时位置';
            ChatMessageData.content := '收到共享实时位置 请在手机上查看';
          end			//合并转发的聊天记录
          else if tempcontent.Contains('的聊天记录</title>') then
          begin
            ChatMessageData.sztype := '聊天记录消息';
            ChatMessageData.content := '收到合并转发的聊天记录 请在手机上查看';
          end

        end
        else if (isLocationMessage = TRUE) then
          ChatMessageData.content := '收到位置消息,请在手机上查看'
        else if (isSystemMessage = TRUE) then
        begin
          if tempcontent.Contains('移出了群聊') or tempcontent.Contains('加入了群聊') then
            ChatMessageData.content := tempcontent
          else
            ChatMessageData.content := '收到红包或系统消息,请在手机上查看';
        end
        else if tempcontent.Length > 200 then
          ChatMessageData.content := '消息内容过长 已经过滤';

        var Titem := lv_recv.Items.Insert(0);
        with Titem do
        begin
          caption := ChatMessageData.wxid;

          subitems.add(ChatMessageData.wxname);
          subitems.add(ChatMessageData.content);

        end;

        PostMessage(handle, WM_MyMessage, integer(Pchar(ChatMessageData.wxid)), 0);
      end;
    end;
end;

procedure TForm2.doMyMessage(var mymsg: Winapi.Messages.TMessage);
var
  wxid: string;
begin

  wxid := PChar(mymsg.WParam);

  TThread.CreateAnonymousThread(
    procedure
    var
      i: Integer;
    begin

      for i := 0 to lb__receipt.Items.Count - 1 do
      begin
        if lb__receipt.Checked[i] then
        begin
          var tmpa := lb__receipt.Items[i].Split([' ']);
          if tmpa[0] = wxid then
          begin
            TThread.CreateAnonymousThread(
              procedure
              begin

                SendMsg(wxid, Trim(memo1.Text));

              end).start;

          end;
          sleep(1000);

        end;
      end
    end).start;

end;

procedure TForm2.Edit1KeyPress(Sender: TObject; var Key: Char);
begin
  if Key = #13 then
    Button2Click(self);
end;

procedure TForm2.Edit1MouseEnter(Sender: TObject);
begin
  edit1.Color := clWhite;
end;

procedure TForm2.Edit1MouseLeave(Sender: TObject);
begin
  edit1.Color := $f5f5f5;
end;

procedure TForm2.edtLookupKeyPress(Sender: TObject; var Key: Char);
var
  strkeyword: string;
  inx: Integer;
begin
  if Key <> #13 then
    Exit;

  strkeyword := trim(edtlookup.text);
  if strkeyword <> '' then
  begin

    for inx := 0 to LbUsers.Count - 1 do
    begin

      if LbUsers.Items[inx].Contains(strkeyword) then
      begin
        LbUsers.Items.Move(inx, 0);
        edtlookup.text := '';
      end;

    end;

  end;

end;

procedure TForm2.Timer1Timer(Sender: TObject);
begin
  if CheckLogin then
  begin

    Label2.Caption := GetNickname;
    Label3.Caption := '微信ID: ' + GetWxid;

//    lstInfo.Items.add('区域：' + GetRegion);
//    lstInfo.Items.add('个性签名：' + GetSign);
//
//    lstInfo.Items.Add('手机号:' + GetPhone);

    head_pic();
    pnlQr.Width := 1;
    pnlQr.Height := 1;
    pnlQr.Visible := false;
    Timer1.Enabled := false;
    self.BringToFront;
  end;
end;

procedure tform2.head_pic();
var
  imagestream: TMemoryStream;
  jpg: TJpegImage;
begin
  imagestream := TMemoryStream.Create();
  jpg := TJpegImage.Create;
  idhttp1.Get(GetHeadUrl, imagestream);
  imagestream.Position := 0;
  jpg.LoadFromStream(imagestream);
  imgboxface.Picture.Assign(jpg);
  imagestream.Free;
  jpg.free;

end;

procedure TForm2.Image2MouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  ReleaseCapture;
  Perform(WM_SysCommand, $F008, 0);
  SetWnd(Width, height);
end;

procedure TForm2.ImgPanel1Click(Sender: TObject);
begin
  windowstate := wsMinimized;
end;

function tform2.GetValue(offset: dword): ansistring;
begin
  result := PansiChar(g_baseaddr + offset);
end;

procedure TForm2.Button1Click(Sender: TObject);
const
  cnBufSize = $10000;
var
  nSize, nRSize, R: Cardinal;
  i, nCount: Cardinal;
  p: pointer;
  pHandleList: PSystemHandleList;
  pHandle: PSystemHandle;
  cHandle: THandle;
  curPid: THandle;
  wechatPID: THandle;
  szName: array[0..511] of byte; // 本来应是结构体的
  szType: array[0..127] of byte;
  sType: string;
  sName: string;
  Found: boolean;
begin

  Found := false;

  curPid := GetCurrentProcess;
  GetWeChatProcess;
  nSize := cnBufSize;
  p := GetMemory(nSize);
  try

    nSize := cnBufSize;
    // $10 表示取 System Handle Info
    R := ZwQuerySystemInformation($10, p, nSize, nRSize);

    if R = $C0000004 then // $0000004 表示长度不够
    begin
      FreeMem(p);
      nSize := nRSize;
      p := GetMemory(nSize);
      R := ZwQuerySystemInformation($10, p, nSize, nRSize);
    end;

    if R = 0 then
    begin

      pHandleList := p;
      nCount := pHandleList.dwHandleCount;
      pHandle := @pHandleList.Handles; // 取首地址的指针


      for i := 0 to nCount - 1 do
      begin
        if IsTagetPid(pHandle.dwProcessID) then
        begin
          wechatPID := OpenProcess($1FFFFF, false, pHandle.dwProcessID);

          // Memo1.Lines.Add('Wechat ProcessID:' + Inttostr(pHandle.dwProcessID));

          curPid := $FFFFFFFF; // 看说明是当前本程序 processid
          // 但 exe 中是这个值。
          cHandle := 0;
          DuplicateHandle(wechatPID, pHandle.wValue, curPid, @cHandle, 0, false, DUPLICATE_SAME_ACCESS);

          if cHandle > 0 then
          begin
            FillChar(szName[0], 512, 0);
            FillChar(szType[0], 128, 0);

            NtQueryObject(cHandle, 1, @szName[0], 512, nRSize);
            sName := ExtractFileName(pchar(@szName[8])); // 前8个 win unicode 的 len 和 maxlen
            NtQueryObject(cHandle, 2, @szType[0], 128, nRSize);

            sType := trim(pchar(@szType[6 * 16])); // 结构搞不清楚，强行偏移到此处了。
             //Mutant---->WeChat_GlobalConfig_Multi_Process_Mutex
//             Mutant---->wxid_dqf9on5070kd22_WeChat_Win_User_Identity_Mutex_Name
            if ((sType = 'Mutant') and (sName = '_WeChat_App_Instance_Identity_Mutex_Name'))//             or
//              ((sType = 'Mutant') and (sName = 'WeChat_GlobalConfig_Multi_Process_Mutex'))or
//              ((sType = 'Mutant') and (sName = 'wxid_dqf9on5070kd22_WeChat_Win_User_Identity_Mutex_Name'))
              then
            begin

              Found := true;

              CloseHandle(cHandle);

              DuplicateHandle(wechatPID, pHandle.wValue, curPid, @cHandle, 0, false, DUPLICATE_CLOSE_SOURCE);

              CloseHandle(cHandle);
            end;

          end
          else
            CloseHandle(cHandle);

          CloseHandle(wechatPID);

        end;
        inc(pHandle);
      end;

    end;

  finally
    FreeMem(p);
  end;
end;
//     procedure tform2

procedure TForm2.Button2Click(Sender: TObject);
var
  vv: tthread;
  u, i: integer;
begin
  g_data_txt := edit1.text;
  if g_data_txt.Trim = '' then
    Exit;

  u := 0;

  for i := 0 to LbUsers.Items.Count - 1 do
    if LbUsers.Checked[i] then
      inc(u);

  if u = 0 then
    ShowMessage('勾选发送')
  else
  begin

    TThread.CreateAnonymousThread(
      procedure
      var
        i: Integer;
      begin

        for i := 0 to LbUsers.Items.Count - 1 do
        begin
          if LbUsers.Checked[i] then
          begin

            TThread.CreateAnonymousThread(
              procedure
              begin
                var s := LbUsers.Items[i];

                var arr := s.Split([' ']);

                SendMsg(arr[0], g_data_txt.Trim);

              end).start;
            sleep(1000);
            Edit1.Text := ''
          end;
        end
      end).start;
  end;

//  if  Edit1.Text <> '' then
//    ShowMessage('勾选发送');
end;

procedure TForm2.BtnExportClick(Sender: TObject);
begin

  if SaveTextFileDialog1.Execute then
  begin
    LbUsers.Items.SaveToFile(SaveTextFileDialog1.FileName);
    ShowMessage('导出完成');
  end;
end;

procedure tform2.setColorBtn(c1, c2, c3, c4, c5: Boolean);
begin
  l1.Transparent := c1;
  l2.Transparent := c2;
  l3.Transparent := c3;
  l4.Transparent := c4;
  l5.Transparent := c5;
end;

procedure TForm2.l2Click(Sender: TObject);
begin
  PageControl1.ActivePage := TabSheet2;
  setColorBtn(True, false, True, True, True);
  memo1.SetFocus;
end;

procedure TForm2.l1Click(Sender: TObject);
begin
  PageControl1.ActivePage := TabSheet1;

  setColorBtn(false, true, True, True, True);
  edit1.SetFocus;
end;

procedure TForm2.btnQrClick(Sender: TObject);
begin    //得到二维码
//  GotoQr;
  qr(QrStr(), ExtractFilePath(ParamStr(0)) + '\QRcode.BMP', 1, 8, 0, 1, 0, 0, 0, clBlack, clWhite);
  imgqr.Picture.Bitmap.LoadFromFile(ExtractFilePath(ParamStr(0)) + '\QRcode.BMP');

end;

procedure TForm2.btn_max1Click(Sender: TObject);
begin
  if windowstate = wsmaximized then
  begin
//    btn_max1.Pic.LoadFromFile('./res/max.png');
//    btn_max1.HotPic.LoadFromFile('./res/max_h.png');
    windowstate := wsnormal;

  end
  else
  begin
//    btn_max1.Pic.LoadFromFile('./res/restore.png');
//    btn_max1.HotPic.LoadFromFile('./res/restore_h.png');
    windowstate := wsmaximized;
  end;
end;

//SendMsg(edit2.text, Edit1.Text);
procedure TForm2.CheckBox1Click(Sender: TObject);
begin
  TmpShield(CheckBox1.Checked);
end;

procedure TForm2.CheckBox3Click(Sender: TObject);
var
  i: Integer;
begin
  if CheckBox3.Checked then
  begin
    for i := 0 to LbUsers.Items.Count - 1 do

      LbUsers.Checked[i] := true;
  end
  else
  begin
    for i := 0 to LbUsers.Items.Count - 1 do

      LbUsers.Checked[i] := false;
  end;
end;

procedure TForm2.l5Click(Sender: TObject);
begin
  PageControl1.ActivePage := TabSheet4;
  setColorBtn(True, True, True, True, false);
end;

procedure TForm2.l3Click(Sender: TObject);
begin
  PageControl1.ActivePage := TabSheet3;
  setColorBtn(True, True, false, True, True);
end;

procedure TForm2.l4Click(Sender: TObject);
begin
  PageControl1.ActivePage := TabSheet5;
  setColorBtn(True, True, True, false, True);
end;

procedure TForm2.LbUsersDblClick(Sender: TObject);
begin

  if LbUsers.ItemIndex >= 0 then
  begin
    LbUsers.Checked[LbUsers.ItemIndex] := not LbUsers.Checked[LbUsers.ItemIndex];

  end;
end;

procedure TForm2.lb__receiptDblClick(Sender: TObject);
begin
  if lb__receipt.ItemIndex >= 0 then
  begin
    lb__receipt.Checked[lb__receipt.ItemIndex] := not lb__receipt.Checked[lb__receipt.ItemIndex];

  end;
end;

procedure TForm2.lv_recvChange(Sender: TObject; Item: TListItem; Change: TItemChange);
begin
  if lv_recv.Items.Count > 100 then
    lv_recv.Items.Delete(lv_recv.Items.Count - 1);
end;

procedure TForm2.lv_recvDblClick(Sender: TObject);
begin
  if lv_recv.Selected = nil then
    exit;

  ShowMessage(lv_recv.Selected.SubItems[1]);
//  l1Click(self);
//  edtLookup.Text := lv_recv.Selected.Caption;
//
//  postmessage(edtLookup.handle, WM_KEYDOWN, VK_RETURN, 0);

end;

procedure TForm2.Memo1MouseEnter(Sender: TObject);
begin
  Memo1.Color := clWhite;
end;

procedure TForm2.Memo1MouseLeave(Sender: TObject);
begin
  Memo1.Color := $f5f5f5;
end;

procedure TForm2.N1Click(Sender: TObject);
begin
  var str: string;
// str := InputBox('说点啥', '默认收到', 'AA');
// if str='AA' then exit;
  if lv_recv.Selected = nil then
    exit;
  if InputQuery('回复', '内容', str) then
  begin
    TThread.CreateAnonymousThread(
      procedure
      begin
        if str.Trim = '' then
          exit;

        SendMsg(lv_recv.Selected.Caption, str.Trim);

      end).start;
  end;
end;

procedure TForm2.N2Click(Sender: TObject);
begin
//if lv_recv.Selected=nil then exit;
//
//     l1Click(self);
//  edtLookup.Text := lv_recv.Selected.Caption;
//
//  postmessage(edtLookup.handle, WM_KEYDOWN, VK_RETURN, 0);
end;

procedure TForm2.pnl_leftMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  releasecapture;
  postmessage(self.handle, wm_syscommand, sc_move + 1, 0);
end;

procedure TForm2.SearchBox1KeyPress(Sender: TObject; var Key: Char);
var
  strkeyword: string;
  inx: Integer;
begin
  if Key <> #13 then
    Exit;

  strkeyword := trim(SearchBox1.text);
  if strkeyword <> '' then
  begin
    for inx := 0 to lb__receipt.Count - 1 do
    begin
      if lb__receipt.Items[inx].Contains(strkeyword) then
      begin
        lb__receipt.Items.Move(inx, 0);
        SearchBox1.text := '';
      end;

    end;

  end;

end;

procedure TForm2.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if Assigned(FList) then
  begin
    FList.FreeAllItem;
    FList.Free;
  end;
end;

procedure tform2.SetWnd(w, h: Integer);
var
  hr: thandle;
begin
//  hr := createroundrectrgn(1, 1, w - 2, h - 2, 5, 5);
//  setwindowrgn(handle, hr, true);
end;

procedure TForm2.FormCreate(Sender: TObject);
var
  hr: thandle;
begin
//  hr := createroundrectrgn(1, 1, width - 2, height - 2, 5, 5);
//  setwindowrgn(handle, hr, true);
  SetWnd(Width, height);
end;

procedure TForm2.FormPaint(Sender: TObject);
var
  DC: HDC;
  Pen: HPen;
  OldPen: HPen;
  OldBrush: HBrush;
begin
//  DC := GetWindowDC(Handle);
////  Pen := CreatePen(PS_SOLID, 1, clGray);
//
//  Pen := CreatePen(PS_SOLID, 2, clGray);
//
//  OldPen := SelectObject(DC, Pen); //载入自定义的画笔,保存原画笔
//  OldBrush := SelectObject(DC, GetStockObject(NULL_BRUSH)); //载入空画刷,保存原画刷
//  RoundRect(DC, 0, 0, Width - 1, Height - 1, 6, 6); //画边框
//  SelectObject(DC, OldBrush); //载入原画刷
//  SelectObject(DC, OldPen); // 载入原画笔
//
//  DeleteObject(Pen);
//  ReleaseDC(Handle, DC);

end;

procedure TForm2.GetWeChatProcess;
var
  i: integer;
  p: PProcessRec;
begin

  if Assigned(FList) then
  begin
    FList.FreeAllItem;
    FList.Free;
  end;
  FList := GetAllProcess;
  for i := FList.Count - 1 downto 0 do
  begin
    p := FList[i];
    if not SameText('WeChat.exe', p.ProcessName) then
      FList.Delete(i)

  end;
end;

function TForm2.IsTagetPid(APid: THandle): boolean;
var
  p: PProcessRec;
begin
  result := false;
  for p in FList do
    if p.ProcessID = APid then
      exit(true);
end;

procedure TForm2.FormShow(Sender: TObject);
begin

  pnlQr.Width := Width;
  pnlQr.Height := Height;
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

end.

