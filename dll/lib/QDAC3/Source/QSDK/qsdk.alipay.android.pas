unit qsdk.alipay.android;

interface

uses
  AndroidAPI.JNI.GraphicsContentViewText,
  AndroidAPI.JNI.OS,
  AndroidAPI.JNI.App,
  AndroidAPI.JNI.Util,
  AndroidAPI.JNIBridge,
  AndroidAPI.JNI.JavaTypes;

type
  JEnvUtils_EnvEnum = interface;

  JEnvUtils_EnvEnumClass = interface(JObjectClass)
    ['{4E918B81-D814-4F50-A159-7111F2619C2D}']
    function _GetONLINE: JEnvUtils_EnvEnum; cdecl; // A: $4019
    function _GetSANDBOX: JEnvUtils_EnvEnum; cdecl; // A: $4019
    function valueOf(JStringparam0: JString): JEnvUtils_EnvEnum; cdecl;
    // (Ljava/lang/String;)Lcom/alipay/sdk/app/EnvUtils$EnvEnum; A: $9
    function values: TJavaArray<JEnvUtils_EnvEnum>; cdecl;
    // ()[Lcom/alipay/sdk/app/EnvUtils$EnvEnum; A: $9
    property ONLINE: JEnvUtils_EnvEnum read _GetONLINE;
    // Lcom/alipay/sdk/app/EnvUtils$EnvEnum; A: $4019
    property SANDBOX: JEnvUtils_EnvEnum read _GetSANDBOX;
    // Lcom/alipay/sdk/app/EnvUtils$EnvEnum; A: $4019
  end;

  [JavaSignature('com/alipay/sdk/app/EnvUtils$EnvEnum')]
  JEnvUtils_EnvEnum = interface(JObject)
    ['{5496FBAB-E43D-4148-9285-E925BD20571C}']
  end;

  TJEnvUtils_EnvEnum = class(TJavaGenericImport<JEnvUtils_EnvEnumClass,
    JEnvUtils_EnvEnum>)
  end;

  JEnvUtils = interface;

  JEnvUtilsClass = interface(JObjectClass)
    ['{7AD680F2-0792-4CED-9074-C2EC50D4955A}']
    function geEnv: JEnvUtils_EnvEnum; cdecl;
    // ()Lcom/alipay/sdk/app/EnvUtils$EnvEnum; A: $9
    function init: JEnvUtils; cdecl; // ()V A: $1
    function isSandBox: boolean; cdecl; // ()Z A: $9
    procedure setEnv(JEnvUtils_EnvEnumparam0: JEnvUtils_EnvEnum); cdecl;
    // (Lcom/alipay/sdk/app/EnvUtils$EnvEnum;)V A: $9
  end;

  [JavaSignature('com/alipay/sdk/app/EnvUtils')]
  JEnvUtils = interface(JObject)
    ['{0BECA38D-39DD-4ACA-9235-DBEDB57509EF}']
  end;

  TJEnvUtils = class(TJavaGenericImport<JEnvUtilsClass, JEnvUtils>)
  end;

  JH5PayActivity = interface;

  JH5PayActivityClass = interface(JObjectClass)
    ['{38787A5B-BCC9-44C9-A8F5-B67B554E83FD}']
    function init: JH5PayActivity; cdecl; // ()V A: $1
    procedure a; cdecl; // ()V A: $1
    procedure finish; cdecl; // ()V A: $1
    procedure onBackPressed; cdecl; // ()V A: $1
    procedure onConfigurationChanged(JConfigurationparam0: JConfiguration);
      cdecl; // (Landroid/content/res/Configuration;)V A: $1
  end;

  [JavaSignature('com/alipay/sdk/app/H5PayActivity')]
  JH5PayActivity = interface(JObject)
    ['{17D5976B-3DB5-4339-A091-24A8006B2889}']
    procedure a; cdecl; // ()V A: $1
    procedure finish; cdecl; // ()V A: $1
    procedure onBackPressed; cdecl; // ()V A: $1
    procedure onConfigurationChanged(JConfigurationparam0: JConfiguration);
      cdecl; // (Landroid/content/res/Configuration;)V A: $1
  end;

  TJH5PayActivity = class(TJavaGenericImport<JH5PayActivityClass,
    JH5PayActivity>)
  end;

  JH5AuthActivity = interface;

  JH5AuthActivityClass = interface(JObjectClass)
    ['{7C1E5C99-8A6D-408C-A4C5-42DD1A17AA41}']
    function init: JH5AuthActivity; cdecl; // ()V A: $1
    procedure a; cdecl; // ()V A: $11
  end;

  [JavaSignature('com/alipay/sdk/app/H5AuthActivity')]
  JH5AuthActivity = interface(JObject)
    ['{590722C0-9699-4506-A895-6FDCE4A6EAB9}']
  end;

  TJH5AuthActivity = class(TJavaGenericImport<JH5AuthActivityClass,
    JH5AuthActivity>)
  end;

  JH5PayResultModel = interface;

  JH5PayResultModelClass = interface(JObjectClass)
    ['{8F216E49-AB46-49A5-A11B-60FD18A6FE13}']
    function getResultCode: JString; cdecl; // ()Ljava/lang/String; A: $1
    function getReturnUrl: JString; cdecl; // ()Ljava/lang/String; A: $1
    function init: JH5PayResultModel; cdecl; // ()V A: $1
    procedure setResultCode(JStringparam0: JString); cdecl;
    // (Ljava/lang/String;)V A: $1
    procedure setReturnUrl(JStringparam0: JString); cdecl;
    // (Ljava/lang/String;)V A: $1
  end;

  [JavaSignature('com/alipay/sdk/util/H5PayResultModel')]
  JH5PayResultModel = interface(JObject)
    ['{CFFAF726-0811-4AF0-A77C-8B851918151A}']
    function getResultCode: JString; cdecl; // ()Ljava/lang/String; A: $1
    function getReturnUrl: JString; cdecl; // ()Ljava/lang/String; A: $1
    procedure setResultCode(JStringparam0: JString); cdecl;
    // (Ljava/lang/String;)V A: $1
    procedure setReturnUrl(JStringparam0: JString); cdecl;
    // (Ljava/lang/String;)V A: $1
  end;

  TJH5PayResultModel = class(TJavaGenericImport<JH5PayResultModelClass,
    JH5PayResultModel>)
  end;

type
  JPayTask = interface;

  JPayTaskClass = interface(JObjectClass)
    ['{5DF68024-BD3B-4497-AC47-875507457A99}']
    function getVersion: JString; cdecl; // ()Ljava/lang/String; A: $1
    function init(JActivityparam0: JActivity): JPayTask; cdecl;
    // (Landroid/app/Activity;)V A: $1
  end;

  [JavaSignature('com/alipay/sdk/app/PayTask')]
  JPayTask = interface(JObject)
    ['{017EA9FB-60DE-442B-A05D-3BDE3BA128B3}']
    function getVersion: JString; cdecl; // ()Ljava/lang/String; A: $1
    function fetchOrderInfoFromH5PayUrl(JStringparam0: JString): JString; cdecl;
    // (Ljava/lang/String;)Ljava/lang/String; A: $21
    function fetchTradeToken: JString; cdecl; // ()Ljava/lang/String; A: $21
    function h5Pay(JStringparam0: JString; booleanparam1: boolean)
      : JH5PayResultModel; cdecl;
    // (Ljava/lang/String;Z)Lcom/alipay/sdk/util/H5PayResultModel; A: $21
    function pay(JStringparam0: JString; booleanparam1: boolean): JString;
      cdecl; // (Ljava/lang/String;Z)Ljava/lang/String; A: $21
    function payV2(JStringparam0: JString; booleanparam1: boolean): JMap; cdecl;
    // (Ljava/lang/String;Z)Ljava/util/Map; A: $21
  end;

  TJPayTask = class(TJavaGenericImport<JPayTaskClass, JPayTask>)
  end;

procedure RegisterAlipayService;

implementation

uses qsdk.alipay, AndroidAPI.Helpers, fmx.platform;

type
  TAlipayAndroidService = class(TInterfacedObject, IAlipayService)
  protected
    FInSandbox: boolean;
    function getInSandbox: boolean;
    procedure setInSandbox(const AVal: boolean);
    function getInstalled: boolean; // 判断支付宝是否安装
    function pay(AOrder: String): String; // 调起支付接口
    function getScheme: String;
    procedure setScheme(const AValue: String);
  end;

procedure RegisterAlipayService;
begin
  TPlatformServices.Current.AddPlatformService(IAlipayService,
    TAlipayAndroidService.Create);
end;

{ TAlipayAndroidService }

function TAlipayAndroidService.getInSandbox: boolean;
begin
  Result := FInSandbox;
end;

function TAlipayAndroidService.getInstalled: boolean;
begin
  Result := true; // 支付宝接口会自己判断，如果不行会调用Web支付，所以始终返回true
end;

function TAlipayAndroidService.getScheme: String;
begin
  Result := ''; // Android不需要scheme
end;

function TAlipayAndroidService.pay(AOrder: String): String;
begin
  if FInSandbox then
    TJEnvUtils.JavaClass.setEnv(TJEnvUtils_EnvEnum.JavaClass.SANDBOX);
  Result := JStringToString(TJPayTask.JavaClass.init(TAndroidHelper.Activity)
    .pay(StringToJString(AOrder), true));
end;

procedure TAlipayAndroidService.setInSandbox(const AVal: boolean);
begin
  FInSandbox := AVal;
end;

procedure TAlipayAndroidService.setScheme(const AValue: String);
begin
  // Do nothing
end;

end.
