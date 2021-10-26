unit qsdk.wechat;

interface

uses system.classes, system.SysUtils, system.Generics.Collections, FMX.Graphics;

type

  // Wechat Objects
  IWechatObject = IInterface;

  TMediaObjectType = (otUnknown, otText, otImage, otMusic, otVideo, otUrl,
    otFile, otAppData, otEmoji, otProduct, otEmotionGift, otDeviceAccess,
    otMailProduct, otOldTV, otEmotionShared, otCardShare, otLocationShare,
    otRecord, otTV, otDesignerShared);

  IWechatMediaMessage = interface
    ['{46D42E74-E148-4FC5-AFEC-706F4BA77B62}']
    function getTitle: String;
    procedure setTitle(const Value: String);
    function getDescription: String;
    procedure setDescription(const Value: String);
    function getThumb: TBitmap;
    procedure setThumb(ABitmap: TBitmap);
    function getMediaObject: IWechatObject;
    procedure setMediaObject(AObject: IWechatObject);
    function getMediaTagName: String;
    procedure setMediaTagName(const AValue: String);
    function getMessageAction: String;
    procedure setMessageAction(const AValue: String);
    function getMessageExt: String;
    procedure setMessageExt(const AValue: String);

    property Title: String read getTitle write setTitle;
    property Description: String read getDescription write setDescription;
    property Thumb: TBitmap read getThumb write setThumb;
    property MediaObject: IWechatObject read getMediaObject
      write setMediaObject;
    property MediaTagName: String read getMediaTagName write setMediaTagName;
    property MessageAction: String read getMessageAction write setMessageAction;
    property MessageExt: String read getMessageExt write setMessageExt;
  end;

  IWechatAppExt = interface
    ['{93D6174A-8DE6-4B70-AD60-94FB1935B97D}']
    function getExtInfo: String;
    procedure setExtInfo(const AValue: String);
    function getFilePath: String;
    procedure setFilePath(const AValue: String);
    function getFileData: TBytes;
    procedure setFileData(const AValue: TBytes);
    property ExtInfo: String read getExtInfo write setExtInfo;
    property FilePath: String read getFilePath write setFilePath;
    property FileData: TBytes read getFileData write setFileData;
  end;

  IWechatText = interface
    ['{01239E30-1D80-4155-BEB5-907226753781}']
    function getText: String;
    procedure setText(const AValue: String);
    property Text: String read getText write setText;
  end;

  IWechatImage = interface
    ['{B015BE08-4F95-4C08-8F2A-11B1B9430B20}']
    function getImagePath: String;
    procedure setImagePath(AValue: String);
    function getImage: TBitmap;
    procedure setImage(ABitmap: TBitmap);

    property ImagePath: String read getImagePath write setImagePath;
    property Imaget: TBitmap read getImage write setImage;
  end;

  IWechatMusic = interface
    ['{C4ED7560-E07B-43A2-AB17-2D287C17BAD4}']
    function getMusicUrl: String;
    procedure setMusicUrl(const AValue: String);
    function getMusicLowBandUrl: String;
    procedure setMusicLowBandUrl(const AValue: String);
    function getMusicDataUrl: String;
    procedure setMusicDataUrl(const AValue: String);
    function getMusicLowBandDataUrl: String;
    procedure setMusicLowBandDataUrl(const AValue: String);

    property MusicUrl: String read getMusicUrl write setMusicUrl;
    property MusicLowBandUrl: String read getMusicLowBandUrl
      write setMusicLowBandUrl;
    property MusicDataUrl: String read getMusicDataUrl write setMusicDataUrl;
    property MusicLowBandDataUrl: String read getMusicLowBandDataUrl
      write setMusicLowBandDataUrl;
  end;

  IWechatVideo = interface
    ['{0C43F90E-02FF-4292-9485-2287F5CB4749}']
    function getVideoUrl: String;
    procedure setVideoUrl(const AValue: String);
    function getVideoLowBandUrl: String;
    procedure setVideoLowBandUrl(const AValue: String);
    property VideoUrl: String read getVideoUrl write setVideoUrl;
    property VideoLowBandUrl: String read getVideoLowBandUrl
      write setVideoLowBandUrl;
  end;

  IWechatWebPage = interface
    ['{B7414EA8-AEDA-4DFD-9DC9-A167204D1E70}']
    function getWebPageUrl: String;
    procedure setWebPageUrl(const AValue: String);
    function getExtInfo: String;
    procedure setExtInfo(const AValue: String);
    { Property }
    property WebPageUrl: String read getWebPageUrl write setWebPageUrl;
    property ExtInfo: String read getExtInfo write setExtInfo;
  end;

  IWechatEmoticon = interface
    ['{3CA5F5CB-38FF-4DDF-BBDF-EECC7C9F344F}']
    function getEmoticonData: TBytes;
    procedure setEmoticonData(const AValue: TBytes);
    property EmoticonData: TBytes read getEmoticonData write setEmoticonData;
  end;

  IWechatFile = interface
    ['{C5FB3AC2-3D65-4A16-9F15-0943B7F4F819}']
    function getFileExt: String;
    procedure setFileExt(const AValue: String);
    function getFileData: TBytes;
    procedure setFileData(const AValue: TBytes);
    property FileExt: String read getFileExt write setFileExt;
    property FileData: TBytes read getFileData write setFileData;
  end;

  IWechatLocation = interface
    ['{D0EA31ED-5972-4430-8720-DCEA91657862}']
    function getLng: Double;
    procedure setLng(const AValue: Double);
    function getLat: Double;
    procedure setLat(const AValue: Double);
    property Lng: Double read getLng write setLng;
    property Lat: Double read getLat write setLat;
  end;

  IWechatRequest = interface
    ['{4FF6EC96-563B-4F66-9129-BD7ABF7416F1}']
    function getOpenID: String;
    procedure setOpenID(const AValue: String);
    function getTansaction: String;
    procedure setTransaction(const AValue: String);
    property OpenID: String read getOpenID write setOpenID;
    property Transaction: String read getTansaction write setTransaction;
  end;

  IWechatResponse = interface
    ['{02FF62AF-5705-4047-947E-7F6019A9474E}']
    function getErrorCode: Integer;
    procedure setErrorCode(const ACode: Integer);
    function getErrorMsg: String;
    procedure setErrorMsg(const AValue: String);
    function getRespType: Integer;
    property RespType: Integer read getRespType;
    property ErrorCode: Integer read getErrorCode write setErrorCode;
    property ErrorMsg: String read getErrorMsg write setErrorMsg;
  end;

  TWechatPayResult = (wprOk, wprCancel, wprError);

  IWechatPayResponse = interface(IWechatResponse)
    ['{0D062157-281E-40DB-A223-A74AB05D1C10}']
    function getPrepayId: String;
    procedure setPrepayId(const AVal: String);
    function getReturnKey: String;
    procedure setReturnKey(const AVal: String);
    function getExtData: String;
    function getPayResult: TWechatPayResult;
    procedure setExtData(const AVal: String);
    property prepayId: String read getPrepayId write setPrepayId;
    property returnKey: String read getReturnKey write setReturnKey;
    property extData: String read getExtData write setExtData;
    property PayResult: TWechatPayResult read getPayResult;
  end;

  IWechatAddCardToPackageRequest = interface(IWechatRequest)

  end;

  TWechatOrderItem = record
    Id: String; // 商品ID
    WePayId: String; // 微信支付商品ID
    GoodsName: String; // 商品名称
    Quantity: Integer; // 商品数量
    Price: Currency; // 价格
    CategoryId: String; // 分类编码
    Comment: String; // 描述<1000字
  end;

  TWechatOrderItems = array of TWechatOrderItem;

  TWechatOrder = record
    No: String;
    Description: String; // 商品描述（body:App名称-商品描述）
    Detail: TWechatOrderItems; // 商品详情(detail)
    extData: String; // 扩展数据(attach)
    TradeNo: String; // 商户订单号(out_trade_no)
    FeeType: String; // 货币类型(fee_type)
    Total: Currency; // 总金额（*100=total_fee）
    TTL: Integer; // 订单失效时间，单位为分钟，不小于5分钟（转换为time_expire,time_start直接取当前时间）
    Tag: String; // 商品标记，(goods_tag)如代金券
    Limit: String; // 支付限制，no_credit 代表不接受信用卡支付
  end;

  TWechatRequestEvent = procedure(ARequest: IWechatRequest) of object;
  TWechatResponseEvent = procedure(AResponse: IWechatResponse) of object;

  TWechatSession = (Session, Timeline, Favorite);

  IWechatSigner = interface
    ['{C06D210C-2DF7-413F-BFE6-E5CEAD764DA1}']
    procedure Add(const AKey, AValue: String);
    procedure Clear;
    function GetSign: String;
    function GetKey: String;
    property Sign: String read GetSign;
    property Key: String read GetKey;
  end;

  IWechatService = interface
    ['{10370690-72BC-438C-8105-042D2029B895}']
    procedure Unregister;
    function IsInstalled: Boolean;
    function getAppId: String;
    function getMchId: String;
    procedure setMchId(const AId: String);
    function getDevId: String;
    procedure setDevId(const AId: String);
    function getPayKey: String;
    procedure setPayKey(const AKey: String);
    function OpenWechat: Boolean;
    function IsAPISupported: Boolean;
    function SendRequest(ARequest: IWechatRequest): Boolean;
    function SendResponse(AResp: IWechatResponse): Boolean;
    function getOnRequest: TWechatRequestEvent;
    procedure setOnRequest(const AEvent: TWechatRequestEvent);
    function getOnResponse: TWechatResponseEvent;
    procedure setOnResponse(const AEvent: TWechatResponseEvent);
    procedure setAppId(const AId: String);
    function OpenUrl(const AUrl: String): Boolean;
    function SendText(const AText: String;
      ASession: TWechatSession = TWechatSession.Session): Boolean;
    function CreateObject(AObjId: TGuid): IWechatObject;
    function Pay(APrepayId, AnonceStr, ASign: String;
      ATimeStamp: Integer): Boolean;
    procedure EnableSignCheck(ASigner:IWechatSigner);
    function ShareText(ATarget: TWechatSession; const S: String): Boolean;
    function ShareWebPage(ATarget: TWechatSession;
      const ATitle, AContent, AUrl: String; APicture: TBitmap): Boolean;
    function ShareBitmap(ATarget: TWechatSession; ABitmap: TBitmap): Boolean;
    // function ShareVideo(const S:String):Boolean;

    property AppId: String read getAppId write setAppId;
    property Installed: Boolean read IsInstalled;
    property APISupported: Boolean read IsAPISupported;
    // 微信支付相关接口
    property MchId: String read getMchId write setMchId;
    property DevId: String read getDevId write setDevId; // 支付终端设备号（device_info）
    property PayKey: String read getPayKey write setPayKey;
    property OnRequest: TWechatRequestEvent read getOnRequest
      write setOnRequest;
    property OnResponse: TWechatResponseEvent read getOnResponse
      write setOnResponse;
  end;



  TWechatObject = class(TInterfacedObject, IInterface)
  protected
{$IFNDEF AUTOREFCOUNT}
    [Volatile]
    FRefCount: Integer;
{$ENDIF}
  public
    function QueryInterface(const IID: TGuid; out Obj): HResult;
      virtual; stdcall;
    function _AddRef: Integer; virtual; stdcall;
    function _Release: Integer; virtual; stdcall;
  end;

function WechatService: IWechatService;
function WechatSigner(const AKey: String): IWechatSigner;

implementation

uses FMX.platform, qstring, qdigest{$IFDEF ANDROID}, qsdk.wechat.android{$ENDIF}
{$IFDEF IOS}, qsdk.wechat.ios{$ENDIF};
{$I 'wxapp.inc'}

type
  TWechatParam = class
  private
    FValue: String;
  public
    constructor Create(AValue: String); overload;
    property Value: String read FValue write FValue;
  end;

  TWechatSigner = class(TInterfacedObject, IWechatSigner)
  private
    FItems: TStringList;
    FKey: String;
    function GetSign: String;
    function GetKey: String;
  public
    constructor Create(const AKey: String); overload;
    destructor Destroy; override;
    procedure Add(const AName, AValue: String);
    procedure Clear;
    property Sign: String read GetSign;
  end;

function WechatService: IWechatService;
begin
  if not TPlatformServices.Current.SupportsPlatformService(IWechatService,
    Result) then
  begin
    RegisterWechatService;
    TPlatformServices.Current.SupportsPlatformService(IWechatService, Result);
    if Assigned(Result) then
    begin
      Result.AppId := SWechatAppId;
      Result.MchId := SWechatMchId;
    end;
  end;
end;

function WechatSigner(const AKey: String): IWechatSigner;
begin
  Result := TWechatSigner.Create(AKey);
end;
{ TWechatObject }

function TWechatObject.QueryInterface(const IID: TGuid; out Obj): HResult;
begin
  Result := inherited QueryInterface(IID, Obj);
end;

function TWechatObject._AddRef: Integer;
begin
  Result := inherited _AddRef;
end;

function TWechatObject._Release: Integer;
begin
  Result := inherited _Release;
end;

{ TWechatSigner }

procedure TWechatSigner.Add(const AName, AValue: String);
begin
  // 空参数不参与签名
  if Length(AValue) > 0 then
    FItems.AddObject(AName, TWechatParam.Create(AValue));
end;

procedure TWechatSigner.Clear;
var
  I: Integer;
  AObj: TObject;
begin
  for I := 0 to FItems.Count - 1 do
  begin
    AObj := FItems.Objects[I];
    FreeAndNilObject(AObj);
  end;
  FItems.Clear;
end;

constructor TWechatSigner.Create(const AKey: String);
begin
  inherited Create;
  FKey := AKey;
  FItems := TStringList.Create;
end;

destructor TWechatSigner.Destroy;
begin
  Clear;
  FreeAndNilObject(FItems);
  inherited;
end;

function TWechatSigner.GetKey: String;
begin
  Result := FKey;
end;

function TWechatSigner.GetSign: String;
var
  S: String;
  I: Integer;
begin
  FItems.Sort;
  S:='';
  for I := 0 to FItems.Count - 1 do
    S := S+FItems[I] + '=' + TWechatParam(FItems.Objects[I]).Value + '&';
  S := S + 'key=' + FKey;
  Result := DigestToString(MD5Hash(S));
end;

{ TWechatParam }

constructor TWechatParam.Create(AValue: String);
begin
  inherited Create;
  FValue := AValue;
end;

end.
