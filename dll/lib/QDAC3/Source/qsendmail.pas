unit qsendmail;

interface

{$I 'qdac.inc'}

{
  发送邮件实现单元，方便发送邮件，您可以免费使用本单元，但请保留版权信息
  (C)2016,swish,chinawsb@sina.com
  本单元实现参考了 BCCSafe 的实现，详情参考：
  http://www.bccsafe.com/delphi%E7%AC%94%E8%AE%B0/2015/05/12/IndySendMail/?utm_source=tuicool&utm_medium=referral
}
uses classes, sysutils,qstring;

type
  PQMailAttachment = ^TQMailAttachment;

  TQMailAttachment = record
    ContentType: QStringW;
    ContentId: QStringW;
    ContentFile: QStringW;
    ContentStream: TStream;
  end;

  IMailAttachments = interface
    procedure AddFile(const AFileName: QStringW;
      const AContentId: QStringW = '');
    procedure AddStream(AData: TStream; const AContentType: QStringW;
      const AContentId: QStringW = '');
    function GetCount: Integer;
    function GetItems(AIndex: Integer): PQMailAttachment;
    property Count: Integer read GetCount;
    property Items[AIndex: Integer]: PQMailAttachment read GetItems;
  end;

  TQMailSender = record
  public
    SMTPServer: QStringW; // 服务器地址
    SMTPPort: Integer; // 服务器端口
    UserName: QStringW; // 用户名
    Password: QStringW; // 密码
    CCList: QStringW; // 抄送地址列表
    BCCList: QStringW; // 暗抄送地址列表
    Attachements: IMailAttachments; // 附件
    SenderName: QStringW; // 发送者姓名
    SenderMail: QStringW; // 发送者邮箱
    RecipientMail: QStringW; // 收件人邮箱
    Subject: QStringW; // 邮件主题
    Body: QStringW; // 邮件内容
    LastError: QStringW;
    UseSASL: Boolean;
  private
  public
    class function Create(AServer, AUserName, APassword: QStringW)
      : TQMailSender; overload; static;
    class function Create: TQMailSender; overload; static;
    function Send: Boolean;
    function SendBySSL: Boolean;
  end;

  TGraphicFormat = (gfUnknown, gfBitmap, gfJpeg, gfPng, gfGif, gfMetafile,
    gfTga, gfPcx, gfTiff, gfIcon, gfCursor, gfIff, gfAni);

function DetectImageFormat(AStream: TStream): TGraphicFormat; overload;
function DetectImageFormat(AFileName: String): TGraphicFormat; overload;
function EncodeMailImage(AStream: TStream; AId: QStringW = '';
  AWidth: QStringW = ''; AHeight: QStringW = '')
  : QStringW; overload;
function EncodeMailImage(AFileName: QStringW; AId: QStringW = '';
  AWidth: QStringW = ''; AHeight: QStringW = '')
  : QStringW; overload;
function EncodeMailImage(AImage: IStreamPersist; AId: QStringW = '';
  AWidth: QStringW = ''; AHeight: QStringW = '')
  : QStringW; overload;

var
  DefaultSMTPServer: String;
  DefaultSMTPUserName: String;
  DefaultSMTPPassword: String;

implementation

uses
  IdComponent, IdTCPConnection, IdTCPClient, IdExplicitTLSClientServerBase,
  IdMessage, IdMessageClient, IdMessageBuilder, IdSMTPBase, IdBaseComponent,
  IdIOHandler, IdSmtp,
  IdIOHandlerSocket, IdIOHandlerStack, IdSSL, IdSSLOpenSSL, IdSASLLogin,
  IdSASL_CRAM_SHA1, IdSASL, IdSASLUserPass, IdSASL_CRAMBase, IdSASL_CRAM_MD5,
  IdSASLSKey, IdSASLPlain, IdSASLOTP, IdSASLExternal, IdSASLDigest,
  IdSASLAnonymous, IdUserPassProvider, EncdDecd{$IF RTLVersion>27},
  NetEncoding{$IFEND}{$IFDEF UNICODE}, Generics.Collections{$ENDIF};

resourcestring
  SUnsupportImageFormat = '不支持的图片格式，HTML中图片只支持JPG/PNG/GIF/BMP';

type
{$IF RTLVersion>=21}
  TAttachmentList = TList<PQMailAttachment>;
{$ELSE}
  TAttachmentList = TList;
{$IFEND}

  TQMailAttachments = class(TInterfacedObject, IMailAttachments)
  protected
    FItems: TAttachmentList;
    procedure AddFile(const AFileName: QStringW;
      const AContentId: QStringW = '');
    procedure AddStream(AData: TStream; const AContentType: QStringW;
      const AContentId: QStringW = '');
    function GetCount: Integer;
    function GetItems(AIndex: Integer): PQMailAttachment;
    procedure DoInitializeISO(var VHeaderEncoding: Char; var VCharSet: string);
  public
    constructor Create; overload;
    destructor Destroy; override;
  end;
  { TQMailSender }

class function TQMailSender.Create(AServer, AUserName, APassword: QStringW)
  : TQMailSender;
var
  AHost: QStringW;
begin
  AHost := DecodeTokenW(AServer, ':', #0, true, true);
  Result.SMTPServer := AHost;
  if not TryStrToInt(AServer, Result.SMTPPort) then
    Result.SMTPPort := 25;
  Result.UserName := AUserName;
  Result.Password := APassword;
  Result.Attachements := TQMailAttachments.Create;
  Result.UseSASL := true;
end;

procedure BuildHtmlMessage(const AData: TQMailSender; AMsg: TIdMessage);
var
  I: Integer;
  ABuilder: TIdMessageBuilderHtml;
begin
  ABuilder := TIdMessageBuilderHtml.Create;
  try
    ABuilder.HtmlCharSet := 'UTF-8';
    if StartWithW(PWideChar(AData.Body), '<', False) then
      ABuilder.Html.Text := AData.Body
    else
      ABuilder.PlainText.Text := AData.Body;
    for I := 0 to AData.Attachements.Count - 1 do
    begin
      with AData.Attachements.Items[I]^ do
      begin
        if Length(ContentFile) > 0 then
          ABuilder.Attachments.Add(ContentFile, ContentId)
        else if Assigned(ContentStream)  then
          ABuilder.Attachments.Add(ContentStream, ContentType, ContentId)
      end;
    end;
    ABuilder.FillMessage(AMsg);
  finally
    FreeAndNil(ABuilder);
  end;
  AMsg.CharSet := 'UTF-8';
  AMsg.Body.Text := AData.Body;
  AMsg.Sender.Text := AData.SenderMail;
  AMsg.From.Address := AData.SenderMail;
  AMsg.From.Name := AData.SenderName;
  AMsg.ReplyTo.EMailAddresses := AData.SenderMail;
  AMsg.Recipients.EMailAddresses := AData.RecipientMail;
  AMsg.Subject := AData.Subject;
  AMsg.CCList.EMailAddresses := AData.CCList;
  AMsg.ReceiptRecipient.Text := '';
  AMsg.BCCList.EMailAddresses := AData.BCCList;
end;

procedure InitSASL(ASmtp: TIdSmtp; AUserName, APassword: String);
var
  IdUserPassProvider: TIdUserPassProvider;
  IdSASLCRAMMD5: TIdSASLCRAMMD5;
  IdSASLCRAMSHA1: TIdSASLCRAMSHA1;
  IdSASLPlain: TIdSASLPlain;
  IdSASLLogin: TIdSASLLogin;
  IdSASLSKey: TIdSASLSKey;
  IdSASLOTP: TIdSASLOTP;
  IdSASLAnonymous: TIdSASLAnonymous;
  IdSASLExternal: TIdSASLExternal;
begin
  IdUserPassProvider := TIdUserPassProvider.Create(ASmtp);
  IdUserPassProvider.UserName := AUserName;
  IdUserPassProvider.Password := APassword;

  IdSASLCRAMSHA1 := TIdSASLCRAMSHA1.Create(ASmtp);
  IdSASLCRAMSHA1.UserPassProvider := IdUserPassProvider;
  IdSASLCRAMMD5 := TIdSASLCRAMMD5.Create(ASmtp);
  IdSASLCRAMMD5.UserPassProvider := IdUserPassProvider;
  IdSASLSKey := TIdSASLSKey.Create(ASmtp);
  IdSASLSKey.UserPassProvider := IdUserPassProvider;
  IdSASLOTP := TIdSASLOTP.Create(ASmtp);
  IdSASLOTP.UserPassProvider := IdUserPassProvider;
  IdSASLAnonymous := TIdSASLAnonymous.Create(ASmtp);
  IdSASLExternal := TIdSASLExternal.Create(ASmtp);
  IdSASLLogin := TIdSASLLogin.Create(ASmtp);
  IdSASLLogin.UserPassProvider := IdUserPassProvider;
  IdSASLPlain := TIdSASLPlain.Create(ASmtp);
  IdSASLPlain.UserPassProvider := IdUserPassProvider;

  ASmtp.SASLMechanisms.Add.SASL := IdSASLCRAMSHA1;
  ASmtp.SASLMechanisms.Add.SASL := IdSASLCRAMMD5;
  ASmtp.SASLMechanisms.Add.SASL := IdSASLSKey;
  ASmtp.SASLMechanisms.Add.SASL := IdSASLOTP;
  ASmtp.SASLMechanisms.Add.SASL := IdSASLAnonymous;
  ASmtp.SASLMechanisms.Add.SASL := IdSASLExternal;
  ASmtp.SASLMechanisms.Add.SASL := IdSASLLogin;
  ASmtp.SASLMechanisms.Add.SASL := IdSASLPlain;

end;

procedure AddSSLSupport(ASmtp: TIdSmtp);
var
  SSLHandler: TIdSSLIOHandlerSocketOpenSSL;
begin
  SSLHandler := TIdSSLIOHandlerSocketOpenSSL.Create(ASmtp);
  // SSL/TLS handshake determines the highest available SSL/TLS version dynamically
  SSLHandler.SSLOptions.Method := sslvSSLv23;
  SSLHandler.SSLOptions.Mode := sslmClient;
  SSLHandler.SSLOptions.VerifyMode := [];
  SSLHandler.SSLOptions.VerifyDepth := 0;
  ASmtp.IOHandler := SSLHandler;
end;

procedure SendMailEx(const AData: TQMailSender; AUseSSL, AUseSASL: Boolean);
var
  AMsg: TIdMessage;
  ASmtp: TIdSmtp;
begin
  AMsg := TIdMessage.Create;
  ASmtp := TIdSmtp.Create;
  try
    AMsg.OnInitializeISO := (AData.Attachements as TQMailAttachments)
      .DoInitializeISO;
    BuildHtmlMessage(AData, AMsg);
    if AUseSSL then
    begin
      AddSSLSupport(ASmtp);
      if AData.SMTPPort = 587 then
        ASmtp.UseTLS := utUseExplicitTLS
      else
        ASmtp.UseTLS := utUseImplicitTLS;
    end;
    if (Length(AData.UserName) > 0) or (Length(AData.Password) > 0) then
    begin
      if AUseSASL then
      begin
        ASmtp.AuthType := satSASL;
        InitSASL(ASmtp, AData.UserName, AData.Password);
      end
      else
      begin
        ASmtp.UserName := AData.UserName;
        ASmtp.Password := AData.Password;
      end;
    end
    else
    begin
      ASmtp.AuthType := satNone;
    end;

    ASmtp.Host := AData.SMTPServer;
    ASmtp.Port := AData.SMTPPort;
    ASmtp.ConnectTimeout := 30000;
    ASmtp.UseEHLO := true;
    ASmtp.Connect;
    try
      ASmtp.Send(AMsg);
    finally
      ASmtp.Disconnect;
    end;
  finally
    FreeAndNil(ASmtp);
    FreeAndNil(AMsg);
  end;
end;

class function TQMailSender.Create: TQMailSender;
begin
  Result := Create(DefaultSMTPServer, DefaultSMTPUserName, DefaultSMTPPassword);
end;

function TQMailSender.Send: Boolean;
begin
  try
    Result := true;
    SendMailEx(Self, False, UseSASL);
  except
    on E: Exception do
    begin
      LastError := E.Message;
      Result := False;
    end;
  end;
end;

function TQMailSender.SendBySSL: Boolean;
begin
  try
    Result := true;
    SendMailEx(Self, true, UseSASL);
  except
    on E: Exception do
    begin
      LastError := E.Message;
      Result := False;
    end;
  end;
end;

{ TQMailAttachments }

procedure TQMailAttachments.AddFile(const AFileName, AContentId: QStringW);
var
  AItem: PQMailAttachment;
begin
  New(AItem);
  AItem.ContentFile := AFileName;
  AItem.ContentId := AContentId;
  FItems.Add(AItem);
end;

procedure TQMailAttachments.AddStream(AData: TStream;
  const AContentType, AContentId: QStringW);
var
  AItem: PQMailAttachment;
begin
  New(AItem);
  AItem.ContentStream := AData;
  AItem.ContentType := AContentType;
  AItem.ContentId := AContentId;
  FItems.Add(AItem);
end;

constructor TQMailAttachments.Create;
begin
  FItems := TAttachmentList.Create;
end;

destructor TQMailAttachments.Destroy;
var
  I: Integer;
begin
  for I := 0 to FItems.Count - 1 do
    Dispose(PQMailAttachment(FItems[I]));
  FreeAndNil(FItems);
  inherited;
end;

procedure TQMailAttachments.DoInitializeISO(var VHeaderEncoding: Char;
  var VCharSet: string);
begin
  VCharSet := 'UTF-8';
  VHeaderEncoding := 'B';
end;

function TQMailAttachments.GetCount: Integer;
begin
  Result := FItems.Count;
end;

function TQMailAttachments.GetItems(AIndex: Integer): PQMailAttachment;
begin
  Result := FItems[AIndex];
end;

/// <summary>检测图片格式</summary>
/// <params>
/// <param name="AStream">要检测的图片数据流</param>
/// </params>
/// <returns>返回可以识别的图片格式代码</returns>

function DetectImageFormat(AStream: TStream): TGraphicFormat; overload;
var
  ABuf: array [0 .. 7] of Byte;
  AReaded: Integer;
  APos:Int64;
begin
  FillChar(ABuf, 8, 0);
  APos:=AStream.Position;
  AReaded := AStream.Read(ABuf[0], 8);
  AStream.Position:=APos;// 回到原始位置
  if (ABuf[0] = $FF) and (ABuf[1] = $D8) then
    // JPEG文件头标识 (2 bytes): $ff, $d8 (SOI) (JPEG 文件标识)
    Result := gfJpeg
  else if (ABuf[0] = $89) and (ABuf[1] = $50) and (ABuf[2] = $4E) and
    (ABuf[3] = $47) and (ABuf[4] = $0D) and (ABuf[5] = $0A) and (ABuf[6] = $1A)
    and (ABuf[7] = $0A) then
    Result := gfPng // 3.PNG文件头标识 (8 bytes)   89 50 4E 47 0D 0A 1A 0A
  else if (ABuf[0] = $42) and (ABuf[1] = $4D) then
    Result := gfBitmap
  else if (ABuf[0] = $47) and (ABuf[1] = $49) and (ABuf[2] = $46) and
    (ABuf[3] = $38) and (ABuf[4] in [$37, $39]) and (ABuf[5] = $61) then
    Result := gfGif
    // GIF- 文件头标识 (6 bytes)   47 49 46 38 39(37) 61 G   I   F     8   9 (7)     a
  else if (ABuf[0] = $01) and (ABuf[1] = $00) and (ABuf[2] = $00) and
    (ABuf[3] = $00) then
    Result := gfMetafile // EMF 01 00 00 00
  else if (ABuf[0] = $01) and (ABuf[1] = $00) and (ABuf[2] = $09) and
    (ABuf[3] = $00) and (ABuf[4] = $00) and (ABuf[5] = $03) then
    Result := gfMetafile // WMF 01 00 09 00 00 03
  else if (ABuf[0] = $00) and (ABuf[1] = $00) and
    ((ABuf[2] = $02) or (ABuf[2] = $10)) and (ABuf[3] = $00) and (ABuf[4] = $00)
  then
    Result := gfTga
    // TGA- 未压缩的前5字节   00 00 02 00 00,RLE压缩的前5字节   00 00 10 00 00
  else if (ABuf[0] = $0A) then
    Result := gfPcx // PCX - 文件头标识 (1 bytes)   0A
  else if ((ABuf[0] = $4D) and (ABuf[1] = $4D)) or
    ((ABuf[0] = $49) and (ABuf[1] = $49)) then
    Result := gfTiff // TIFF  - 文件头标识 (2 bytes)   4D 4D 或 49 49
  else if (ABuf[0] = $00) and (ABuf[1] = $00) and (ABuf[2] = $01) and
    (ABuf[3] = $00) and (ABuf[4] = $01) and (ABuf[5] = $00) and (ABuf[6] = $20)
    and (ABuf[7] = $20) then
    Result := gfIcon // ICO - 文件头标识 (8 bytes)   00 00 01 00 01 00 20 20
  else if (ABuf[0] = $00) and (ABuf[1] = $00) and (ABuf[2] = $02) and
    (ABuf[3] = $00) and (ABuf[4] = $01) and (ABuf[5] = $00) and (ABuf[6] = $20)
    and (ABuf[7] = $20) then
    Result := gfCursor // CUR - 文件头标识 (8 bytes)   00 00 02 00 01 00 20 20
  else if (ABuf[0] = $46) and (ABuf[1] = $4F) and (ABuf[2] = $52) and
    (ABuf[3] = $4D) then
    Result := gfIff // IFF - 文件头标识 (4 bytes)   46 4F 52 4D(FORM)
  else if (ABuf[0] = $52) and (ABuf[1] = $49) and (ABuf[2] = $46) and
    (ABuf[3] = $46) then
    Result := gfAni // 11.ANI- 文件头标识 (4 bytes)   52 49 46 46(RIFF)
  else
    Result := gfUnknown;
end;

/// <summary>检测图片格式</summary>
/// <params>
/// <param name="AFileName">要检测的图片文件名</param>
/// </params>
/// <returns>返回可以识别的图片格式代码</returns>
function DetectImageFormat(AFileName: String): TGraphicFormat; overload;
var
  AStream: TStream;
begin
  AStream := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyWrite);
  try
    Result := DetectImageFormat(AStream);
  finally
    FreeAndNil(AStream);
  end;
end;

function EncodeImageHeader(AStream: TStream; AId, AWidth, AHeight: String)
  : QStringW;
begin
  if Length(AId) > 0 then
    Result := '<img id=' + QuotedStrW(AId, '"')
  else
    Result := '<img';
  if Length(AWidth) > 0 then
    Result := Result + ' width=' + QuotedStrW(AWidth, '"');
  if Length(AHeight) > 0 then
    Result := Result + ' height=' + QuotedStrW(AHeight, '"');
  Result := Result + ' src="data:image/';
  case DetectImageFormat(AStream) of
    gfBitmap:
      Result := Result + 'bmp;base64,';
    gfJpeg:
      Result := Result + 'jpeg;base64,';
    gfPng:
      Result := Result + 'png;base64,';
    gfGif:
      Result := Result + 'gif;base64,';
  else // 其它格式就不支持了，想支持的自己参考处理
    raise Exception.Create(SUnsupportImageFormat);
  end;
end;

function EncodeMailImage(AStream: TStream; AId, AWidth, AHeight: QStringW)
  : QStringW;
var
  ATemp: TCustomMemoryStream;
begin
  if AStream is TCustomMemoryStream then
  begin
    ATemp := AStream as TCustomMemoryStream;
    Result := EncodeImageHeader(ATemp, '', '', '') +
      EncodeBase64(PByte(IntPtr(ATemp.Memory) + ATemp.Position),
      ATemp.Size - ATemp.Position) + '">';
  end
  else
  begin
    ATemp := TMemoryStream.Create;
    try
      ATemp.CopyFrom(AStream, AStream.Size - AStream.Position);
      Result := EncodeImageHeader(ATemp, '', '', '') +
        EncodeBase64(ATemp.Memory, ATemp.Size) + '">';
    finally
      FreeAndNil(ATemp);
    end;
  end;
end;

function EncodeMailImage(AFileName: QStringW;
  AId, AWidth, AHeight: QStringW): QStringW;
var
  AStream: TMemoryStream;
begin
  AStream := TMemoryStream.Create;
  try
    AStream.LoadFromFile(AFileName);
    AStream.Position := 0;
    Result := EncodeImageHeader(AStream, '', '', '') +
      EncodeBase64(AStream.Memory, AStream.Size) + '">';
  finally
    FreeAndNil(AStream);
  end;
end;

function EncodeMailImage(AImage: IStreamPersist; AId: QStringW = '';
  AWidth: QStringW = ''; AHeight: QStringW = ''): QStringW;
var
  AStream: TMemoryStream;
begin
  AStream := TMemoryStream.Create;
  try
    AImage.SaveToStream(AStream);
    AStream.Position := 0;
    Result := EncodeMailImage(AStream, AId, AWidth, AHeight);
  finally
    FreeAndNil(AStream);
  end;
end;

end.
