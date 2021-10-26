unit qsdk.alipay.ios;

interface

uses
  Classes, Sysutils, System.ZLib {libz.dylib} ,
  System.Sqlite {libsqlite3.0.dylib} ,
  iOSapi.Foundation, Macapi.ObjectiveC, iOSapi.UIKit, Macapi.Helpers,
  FMX.Platform.ios, iOSapi.Security, iOSapi.CoreMotion, iOSapi.CoreTelephony,
  iOSapi.SystemConfiguration;
{$M+}

type
  // APayAuthInfo.h
  {
    @interface APayAuthInfo : NSObject

    @property(nonatomic, copy)NSString *appID;
    @property(nonatomic, copy)NSString *pid;
    @property(nonatomic, copy)NSString *redirectUri;

    /**
    *  初始化AuthInfo
    *
    *  @param appIDStr     应用ID
    *  @param productIDStr 产品码 该商户在aboss签约的产品,用户获取pid获取的参数
    *  @param pidStr       商户ID   可不填
    *  @param uriStr       授权的应用回调地址  比如：alidemo://auth
    *
    *  @return authinfo实例
    */
    - (id)initWithAppID:(NSString *)appIDStr
    pid:(NSString *)pidStr
    redirectUri:(NSString *)uriStr;

    - (NSString *)description;
    - (NSString *)wapDescription;
    @end
  }
  APayAuthInfoClass = interface(NSObjectClass)
    ['{C8335BFC-50DB-49E6-8BEF-C7F64A9812E7}']

  end;

  APayAuthInfo = interface(NSObject)
    ['{244AA8B5-074B-4ECA-B50B-660392B6399D}']
    function appID: NSString; cdecl;
    procedure setAppID(Value: NSString); cdecl;
    function pid: NSString; cdecl;
    procedure setPid(Value: NSString); cdecl;
    function redirectUri: NSString; cdecl;
    procedure setRedirectUri(Value: NSString); cdecl;
    [MethodName('initWithAppID:pid:redirectUri:')]
    function initWithAppIDPidRedirectUri(appIDStr, pidStr,
      redirectUri: NSString): Pointer; cdecl;
    function description: NSString; cdecl;
    function wapDescription: NSString; cdecl;
  end;

  TAPayAuthInfo = class(TOCGenericImport<APayAuthInfoClass, APayAuthInfo>)
  end;

  // AlipaySDK.h
  AlipayTidFactor = (ALIPAY_TIDFACTOR_IMEI, ALIPAY_TIDFACTOR_IMSI,
    ALIPAY_TIDFACTOR_TID, ALIPAY_TIDFACTOR_CLIENTKEY, ALIPAY_TIDFACTOR_VIMEI,
    ALIPAY_TIDFACTOR_VIMSI, ALIPAY_TIDFACTOR_CLIENTID, ALIPAY_TIDFACTOR_APDID,
    ALIPAY_TIDFACTOR_MAX);
  TAlipayTidFactor = AlipayTidFactor;

  // typedef void(^CompletionBlock)(NSDictionary *resultDic);
  CompletionBlock = procedure(resultDic: NSDictionary) of object; // cdecl;
  TCompletionBlock = CompletionBlock;

  AlipaySDK = interface;

  AlipaySDKClass = interface(NSObjectClass)
    ['{087F1862-DA2C-43BD-9FFA-E6EBEE9B17D6}']
    {
      *  创建支付单例服务
      *  @return 返回单例对象
      + (AlipaySDK *)defaultService;
    }
    //
    function defaultService: AlipaySDK; cdecl;
  end;

  AlipaySDK = interface(NSObject)
    ['{41F28044-7B8F-41BD-8DE3-F74B9BAD3835}']
    { *
      *  用于设置SDK使用的window，如果没有自行创建window无需设置此接口
      @property (nonatomic, weak) UIWindow *targetWindow;
    }
    function targetWindow: UIWindow; cdecl;
    procedure setTargetWindow(wnd: UIWindow); cdecl;
    { *
      *  支付接口
      *
      *  @param orderStr       订单信息
      *  @param schemeStr      调用支付的app注册在info.plist中的scheme
      *  @param compltionBlock 支付结果回调Block，用于wap支付结果回调（非跳转钱包支付）
      - (void)payOrder:(NSString *)orderStr
      fromScheme:(NSString *)schemeStr
      callback:(CompletionBlock)completionBlock;
    }
    [MethodName('payOrder:fromScheme:callback:')]
    procedure PayOrderFromSchemeCallback(orderStr: NSString;
      schemeStr: NSString; AcompletionBlock: TCompletionBlock); cdecl;
    {
      *  处理钱包或者独立快捷app支付跳回商户app携带的支付结果Url
      *
      *  @param resultUrl        支付结果url
      *  @param completionBlock  支付结果回调
    }
    [MethodName('processOrderWithPayment:standbyCallback:')]
    procedure processOrderWithPaymentResultStandbyCallback(resultUrl: NSURL;
      AcompletionBlock: TCompletionBlock); cdecl;

    {
      *  获取交易token。
      *
      *  @return 交易token，若无则为空。
      - (NSString *)fetchTradeToken;
    }
    function fetchTradeToken: NSString; cdecl;
    {
      *  是否已经使用过
      *
      *  @return YES为已经使用过，NO反之
      - (BOOL)isLogined;
    }
    function isLogined: Boolean; cdecl;
    { *
      *  当前版本号
      *
      *  @return 当前版本字符串
      - (NSString *)currentVersion;
    }
    function currentVersion: NSString; cdecl;
    { *
      *  当前版本号
      *
      *  @return tid相关信息
      - (NSString*)queryTidFactor:(AlipayTidFactor)factor;
    }
    [MethodName('queryTidFactor:')]
    function queryTidFactor(factor: TAlipayTidFactor): NSString; cdecl;
    { *
      *  測試所用，realse包无效
      *
      *  @param url  测试环境
      - (void)setUrl:(NSString *)url;
    }
    [MethodName('setUrl:')]
    procedure setUrl(url: NSString); cdecl;
    { *
      *  url order 获取接口
      *
      *  @param urlStr     拦截的 url string
      *
      *  @return 获取到的url order info
      - (NSString*)fetchOrderInfoFromH5PayUrl:(NSString*)urlStr;
    }
    [MethodName('fetchOrderInfoFromH5PayUrl:')]
    function fetchOrderInfoFromH5PayUrl(urlStr: NSString): NSString; cdecl;

    {
      *  url支付接口
      *
      *  @param orderStr       订单信息
      *  @param schemeStr      调用支付的app注册在info.plist中的scheme
      *  @param compltionBlock 支付结果回调Block
      - (void)payUrlOrder:(NSString *)orderStr
      fromScheme:(NSString *)schemeStr
      callback:(CompletionBlock)completionBlock;
    }
    [MethodName('payUrlOrder:fromScheme:callback:')]
    procedure payUrlOrderFromSchemeCallback(orderStr, schemeStr: NSString;
      AcompletionBlock: TCompletionBlock); cdecl;

    /// ///////////////////////////////////////////////////////////////////////////////////////////
    /// ///////////////////////授权1.0//////////////////////////////////////////////////////////////
    /// ///////////////////////////////////////////////////////////////////////////////////////////

    {
      *  快登授权
      *  @param authInfo         需授权信息
      *  @param completionBlock  授权结果回调，若在授权过程中，调用方应用被系统终止，则此block无效，
      需要调用方在appDelegate中调用processAuthResult:standbyCallback:方法获取授权结果
      - (void)authWithInfo:(APayAuthInfo *)authInfo
      callback:(CompletionBlock)completionBlock;
    }
    [MethodName('authWithInfo:callback:')]
    procedure authWithInfoCallback(authInfo: APayAuthInfo;
      callback: TCompletionBlock); cdecl;

    {
      *  处理授权信息Url
      *
      *  @param resultUrl        钱包返回的授权结果url
      *  @param completionBlock  授权结果回调
      - (void)processAuthResult:(NSURL *)resultUrl
      standbyCallback:(CompletionBlock)completionBlock;
    }
    /// ///////////////////////////////////////////////////////////////////////////////////////////
    /// ///////////////////////授权2.0//////////////////////////////////////////////////////////////
    /// ///////////////////////////////////////////////////////////////////////////////////////////

    {
      *  快登授权2.0
      *
      *  @param infoStr          授权请求信息字符串
      *  @param schemeStr        调用授权的app注册在info.plist中的scheme
      *  @param completionBlock  授权结果回调，若在授权过程中，调用方应用被系统终止，则此block无效，
      需要调用方在appDelegate中调用processAuth_V2Result:standbyCallback:方法获取授权结果
      - (void)auth_V2WithInfo:(NSString *)infoStr
      fromScheme:(NSString *)schemeStr
      callback:(CompletionBlock)completionBlock;
    }
    [MethodName('auth_V2WithInfo:fromScheme:callback:')]
    procedure auth_V2WithInfoFromSchemeCallback(infostr, schemeStr: NSString;
      callback: TCompletionBlock); cdecl;

    {
      *  处理授权信息Url
      *
      *  @param resultUrl        钱包返回的授权结果url
      *  @param completionBlock  授权结果回调
      - (void)processAuth_V2Result:(NSURL *)resultUrl
      standbyCallback:(CompletionBlock)completionBlock;
    }
    [MethodName('processAuth_V2Result:standbyCallback:')]
    procedure processAuth_V2ResultStandbyCallback(resultUrl: NSString;
      AcompletionBlock: TCompletionBlock); cdecl;
  end;

  TAlipaySDK = class(TOCGenericImport<AlipaySDKClass, AlipaySDK>)
  end;

procedure RegisterAlipayService;

implementation

uses qsdk.alipay, FMX.Platform, qstring, syncobjs;

const
  CoreTelephonyFwk =
    '/System/Library/Frameworks/CoreTelephony.framework/CoreTelephony';
  LibCMMotion = '/System/Library/Frameworks/CoreMotion.framework/CoreMotion';
function CoreTelephonyFakeLoader: NSString; cdecl;
  external CoreTelephonyFwk name 'OBJC_CLASS_$_CTTelephonyNetworkInfo';
function CMotionFakeLoader: CMMotionManager; cdecl;
  external LibCMMotion name 'OBJC_CLASS_$_CMMotionManager';
procedure nothrow; cdecl; external '/usr/lib/libc++.dylib' name '_ZSt7nothrow';
{$IFDEF IOS}
{$O-}
function AlipaySDK_FakeLoader: AlipaySDK; cdecl;
  external 'AlipaySDK' name 'OBJC_CLASS_$_AlipaySDK';
{$O+}
{$ENDIF}

type
  TAlipayiOSService = class(TInterfacedObject, IAlipayService)
  protected
    FInSandbox: Boolean;
    FScheme: String;
    FPayResult: String;
    FEvent: TEvent;
    function getInSandbox: Boolean;
    procedure setInSandbox(const AVal: Boolean);
    function getInstalled: Boolean; // 判断支付宝是否安装
    function pay(AOrder: String): String; // 调起支付接口
    function getScheme: String;
    procedure setScheme(const AValue: String);
    procedure DoPayDone(resultDic: NSDictionary);
  public
    constructor Create; overload;
    destructor Destroy; override;
  end;

procedure RegisterAlipayService;
begin
  TPlatformServices.Current.AddPlatformService(IAlipayService,
    TAlipayiOSService.Create);
end;

{ TAlipayiOSService }

constructor TAlipayiOSService.Create;
begin
  FEvent := TEvent.Create(nil,false,false,'');
end;

destructor TAlipayiOSService.Destroy;
begin
  FreeAndNil(FEvent);
  inherited;
end;

procedure TAlipayiOSService.DoPayDone(resultDic: NSDictionary);
var
  AKeys: NSArray;
  AValues: NSArray;
  I: Integer;
begin
  // 格式化和Android一样的格式
  AKeys := resultDic.allKeys;
  AValues := resultDic.allValues;
  SetLength(FPayResult, 0);
  for I := 0 to resultDic.count - 1 do
  begin
    FPayResult := FPayResult + NSStrToStr(TNSString.Wrap(AKeys.objectAtIndex(I))
      ) + '={' + JavaEscape(NSStrToStr(TNSString.Wrap(AValues.objectAtIndex(I))
      ), false) + '};';
  end;
  FPayResult := StrDupX(PQCharW(FPayResult), Length(FPayResult) - 1);
  FEvent.SetEvent;
end;

function TAlipayiOSService.getInSandbox: Boolean;
begin
  Result := FInSandbox;
end;

function TAlipayiOSService.getInstalled: Boolean;
begin
  Result := true; // 支付宝接口会自己判断，如果不行会调用Web支付，所以始终返回tru
end;

function TAlipayiOSService.getScheme: String;
begin
  Result := FScheme;
end;

function TAlipayiOSService.pay(AOrder: String): String;
begin
  SetLength(FPayResult, 0);
  TAlipaySDK.OCClass.defaultService.PayOrderFromSchemeCallback
    (StrToNSStr(AOrder), StrToNSStr(FScheme), DoPayDone);
  FEvent.WaitFor(INFINITE);
  Result := FPayResult;
end;

procedure TAlipayiOSService.setInSandbox(const AVal: Boolean);
begin
  FInSandbox := AVal;
end;

procedure TAlipayiOSService.setScheme(const AValue: String);
begin
  FScheme := AValue;
end;

END.
