unit qsdk.alipay;

interface

uses system.Classes, system.SysUtils;

type
  TAlipayResult = (arUnknown, arOk, arCancel, arError);

  IAlipayService = interface
    ['{F225AEBC-475A-4513-BC08-5F82BF3713E0}']
    function getInSandbox: Boolean;
    procedure setInSandbox(const AVal: Boolean);
    function getInstalled: Boolean; // 判断支付宝是否安装
    function Pay(AOrder: String): String; // 调起支付接口
    function getScheme:String;
    procedure setScheme(const AValue:String);
    property InSandbox:Boolean read getInSandbox write setInSandbox;
    property Installed:Boolean read getInstalled;
    property Scheme:String read getScheme write setScheme;
  end;

function AlipayService: IAlipayService;

implementation

uses FMX.platform, qstring
{$IFDEF ANDROID}, qsdk.alipay.android{$ENDIF}{$IFDEF IOS},
  qsdk.alipay.ios{$ENDIF};

function AlipayService: IAlipayService;
begin
  if not TPlatformServices.Current.SupportsPlatformService(IAlipayService,
    Result) then
  begin
    RegisterAlipayService;
    TPlatformServices.Current.SupportsPlatformService(IAlipayService, Result);
  end;
end;

end.
