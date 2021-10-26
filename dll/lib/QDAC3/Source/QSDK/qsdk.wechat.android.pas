unit qsdk.wechat.android;

{ ******************************************************* }
{ QSDK.wechat.android 1.0 }
{ Interfaces for wechat android sdk 3.1.1 }
{ This is a modified sdk library for wechat,not origin }
{ ******************************************************* }
interface

uses AndroidAPI.JNIBridge, AndroidAPI.JNI.JavaTypes,
  AndroidAPI.JNI.GraphicsContentViewText, AndroidAPI.JNI.OS,
  AndroidAPI.JNI.App, AndroidAPI.JNI.Util;

type
  JWXPayEntryActivity = interface; //
  JBuild = interface; // com.tencent.mm.sdk.constants.Build
  JConstantsAPI_Token = interface;
  // com.tencent.mm.sdk.constants.ConstantsAPI$Token
  JConstantsAPI_WXApp = interface;
  // com.tencent.mm.sdk.constants.ConstantsAPI$WXApp
  JConstantsAPI = interface; // com.tencent.mm.sdk.constants.ConstantsAPI
  JDiffDevOAuthFactory = interface;
  // com.tencent.mm.sdk.diffdev.DiffDevOAuthFactory
  JIDiffDevOAuth = interface; // com.tencent.mm.sdk.diffdev.IDiffDevOAuth
  JOAuthErrCode = interface; // com.tencent.mm.sdk.diffdev.OAuthErrCode
  JOAuthListener = interface; // com.tencent.mm.sdk.diffdev.OAuthListener
  JBaseReq = interface; // com.tencent.mm.sdk.modelbase.BaseReq
  JBaseResp_ErrCode = interface;
  // com.tencent.mm.sdk.modelbase.BaseResp$ErrCode
  JBaseResp = interface; // com.tencent.mm.sdk.modelbase.BaseResp
  JAddCardToWXCardPackage_Req = interface;
  // com.tencent.mm.sdk.modelbiz.AddCardToWXCardPackage$Req
  JAddCardToWXCardPackage_Resp = interface;
  // com.tencent.mm.sdk.modelbiz.AddCardToWXCardPackage$Resp
  JAddCardToWXCardPackage_WXCardItem = interface;
  // com.tencent.mm.sdk.modelbiz.AddCardToWXCardPackage$WXCardItem
  JAddCardToWXCardPackage = interface;
  // com.tencent.mm.sdk.modelbiz.AddCardToWXCardPackage
  JCreateChatroom_Req = interface;
  // com.tencent.mm.sdk.modelbiz.CreateChatroom$Req
  JCreateChatroom_Resp = interface;
  // com.tencent.mm.sdk.modelbiz.CreateChatroom$Resp
  JCreateChatroom = interface; // com.tencent.mm.sdk.modelbiz.CreateChatroom
  JJoinChatroom_Req = interface; // com.tencent.mm.sdk.modelbiz.JoinChatroom$Req
  JJoinChatroom_Resp = interface;
  // com.tencent.mm.sdk.modelbiz.JoinChatroom$Resp
  JJoinChatroom = interface; // com.tencent.mm.sdk.modelbiz.JoinChatroom
  JJumpToBizProfile_Req = interface;
  // com.tencent.mm.sdk.modelbiz.JumpToBizProfile$Req
  JJumpToBizProfile = interface; // com.tencent.mm.sdk.modelbiz.JumpToBizProfile
  JJumpToBizTempSession_Req = interface;
  // com.tencent.mm.sdk.modelbiz.JumpToBizTempSession$Req
  JJumpToBizTempSession = interface;
  // com.tencent.mm.sdk.modelbiz.JumpToBizTempSession
  JJumpToBizWebview_Req = interface;
  // com.tencent.mm.sdk.modelbiz.JumpToBizWebview$Req
  JJumpToBizWebview = interface; // com.tencent.mm.sdk.modelbiz.JumpToBizWebview
  JOpenBusiLuckyMoney_Req = interface;
  // com.tencent.mm.sdk.modelbiz.OpenBusiLuckyMoney$Req
  JOpenBusiLuckyMoney = interface;
  // com.tencent.mm.sdk.modelbiz.OpenBusiLuckyMoney
  JOpenRankList_Req = interface; // com.tencent.mm.sdk.modelbiz.OpenRankList$Req
  JOpenRankList = interface; // com.tencent.mm.sdk.modelbiz.OpenRankList
  JOpenWebview_Req = interface; // com.tencent.mm.sdk.modelbiz.OpenWebview$Req
  JOpenWebview_Resp = interface; // com.tencent.mm.sdk.modelbiz.OpenWebview$Resp
  JOpenWebview = interface; // com.tencent.mm.sdk.modelbiz.OpenWebview
  JGetMessageFromWX_Req = interface;
  // com.tencent.mm.sdk.modelmsg.GetMessageFromWX$Req
  JGetMessageFromWX_Resp = interface;
  // com.tencent.mm.sdk.modelmsg.GetMessageFromWX$Resp
  JGetMessageFromWX = interface; // com.tencent.mm.sdk.modelmsg.GetMessageFromWX
  JLaunchFromWX_Req = interface; // com.tencent.mm.sdk.modelmsg.LaunchFromWX$Req
  JLaunchFromWX_Resp = interface;
  // com.tencent.mm.sdk.modelmsg.LaunchFromWX$Resp
  JLaunchFromWX = interface; // com.tencent.mm.sdk.modelmsg.LaunchFromWX
  JSendAuth_Req = interface; // com.tencent.mm.sdk.modelmsg.SendAuth$Req
  JSendAuth_Resp = interface; // com.tencent.mm.sdk.modelmsg.SendAuth$Resp
  JSendAuth = interface; // com.tencent.mm.sdk.modelmsg.SendAuth
  JSendMessageToWX_Req = interface;
  // com.tencent.mm.sdk.modelmsg.SendMessageToWX$Req
  JSendMessageToWX_Resp = interface;
  // com.tencent.mm.sdk.modelmsg.SendMessageToWX$Resp
  JSendMessageToWX = interface; // com.tencent.mm.sdk.modelmsg.SendMessageToWX
  JShowMessageFromWX_Req = interface;
  // com.tencent.mm.sdk.modelmsg.ShowMessageFromWX$Req
  JShowMessageFromWX_Resp = interface;
  // com.tencent.mm.sdk.modelmsg.ShowMessageFromWX$Resp
  JShowMessageFromWX = interface;
  // com.tencent.mm.sdk.modelmsg.ShowMessageFromWX
  JWXAppExtendObject = interface;
  // com.tencent.mm.sdk.modelmsg.WXAppExtendObject
  JWXAppLaunchData_Builder = interface;
  // com.tencent.mm.sdk.modelmsg.WXAppLaunchData$Builder
  JWXAppLaunchData = interface; // com.tencent.mm.sdk.modelmsg.WXAppLaunchData
  JWXDesignerSharedObject = interface;
  // com.tencent.mm.sdk.modelmsg.WXDesignerSharedObject
  JWXEmojiObject = interface; // com.tencent.mm.sdk.modelmsg.WXEmojiObject
  JWXEmojiSharedObject = interface;
  // com.tencent.mm.sdk.modelmsg.WXEmojiSharedObject
  JWXFileObject = interface; // com.tencent.mm.sdk.modelmsg.WXFileObject
  JWXImageObject = interface; // com.tencent.mm.sdk.modelmsg.WXImageObject
  JWXMediaMessage_Builder = interface;
  // com.tencent.mm.sdk.modelmsg.WXMediaMessage$Builder
  JWXMediaMessage_IMediaObject = interface;
  // com.tencent.mm.sdk.modelmsg.WXMediaMessage$IMediaObject
  JWXMediaMessage = interface; // com.tencent.mm.sdk.modelmsg.WXMediaMessage
  JWXMusicObject = interface; // com.tencent.mm.sdk.modelmsg.WXMusicObject
  JWXTextObject = interface; // com.tencent.mm.sdk.modelmsg.WXTextObject
  JWXVideoObject = interface; // com.tencent.mm.sdk.modelmsg.WXVideoObject
  JWXWebpageObject = interface; // com.tencent.mm.sdk.modelmsg.WXWebpageObject
  JPayReq_Options = interface; // com.tencent.mm.sdk.modelpay.PayReq$Options
  JPayReq = interface; // com.tencent.mm.sdk.modelpay.PayReq
  JPayResp = interface; // com.tencent.mm.sdk.modelpay.PayResp
  JIWXAPI = interface; // com.tencent.mm.sdk.openapi.IWXAPI
  JIWXAPIEventHandler = interface;
  // com.tencent.mm.sdk.openapi.IWXAPIEventHandler
  JMMSharedPreferences_REditor = interface;
  // com.tencent.mm.sdk.openapi.MMSharedPreferences$REditor
  JMMSharedPreferences = interface;
  // com.tencent.mm.sdk.openapi.MMSharedPreferences
  JWXAPIFactory = interface; // com.tencent.mm.sdk.openapi.WXAPIFactory
  JWXApiImplComm = interface; // com.tencent.mm.sdk.openapi.WXApiImplComm
  JWXApiImplV10_1 = interface; // com.tencent.mm.sdk.openapi.WXApiImplV10$1
  JWXApiImplV10_ActivityLifecycleCb_1 = interface;
  // com.tencent.mm.sdk.openapi.WXApiImplV10$ActivityLifecycleCb$1
  JWXApiImplV10_ActivityLifecycleCb_2 = interface;
  // com.tencent.mm.sdk.openapi.WXApiImplV10$ActivityLifecycleCb$2
  JWXApiImplV10_ActivityLifecycleCb = interface;
  // com.tencent.mm.sdk.openapi.WXApiImplV10$ActivityLifecycleCb
  JWXApiImplV10 = interface; // com.tencent.mm.sdk.openapi.WXApiImplV10
  JStatConstants = interface; // com.tencent.wxop.stat.common.StatConstants
  JStatLogger = interface; // com.tencent.wxop.stat.common.StatLogger
  JEasyActivity = interface; // com.tencent.wxop.stat.EasyActivity
  JMtaSDkException = interface; // com.tencent.wxop.stat.MtaSDkException
  JNetworkMonitor = interface; // com.tencent.wxop.stat.NetworkMonitor
  JStatAccount = interface; // com.tencent.wxop.stat.StatAccount
  JStatAppMonitor = interface; // com.tencent.wxop.stat.StatAppMonitor
  JStatConfig = interface; // com.tencent.wxop.stat.StatConfig
  JStatGameUser = interface; // com.tencent.wxop.stat.StatGameUser
  JStatReportStrategy = interface; // com.tencent.wxop.stat.StatReportStrategy
  JStatService = interface; // com.tencent.wxop.stat.StatService
  JStatServiceImpl = interface; // com.tencent.wxop.stat.StatServiceImpl
  JStatSpecifyReportedInfo = interface;
  // com.tencent.wxop.stat.StatSpecifyReportedInfo

  JBuildClass = interface(JObjectClass)
    ['{99971DBD-DEC4-4CCC-B572-22C9EBD6F5EB}']
    { static Property Methods }
    { class } function _GetSDK_INT: Integer; // I
    { class } function _GetSDK_VERSION_NAME: JString; // Ljava/lang/String;
    { class } function _GetMIN_SDK_INT: Integer; // I
    { class } function _GetTIMELINE_SUPPORTED_SDK_INT: Integer; // I
    { class } function _GetEMOJI_SUPPORTED_SDK_INT: Integer; // I
    { class } function _GetMUSIC_DATA_URL_SUPPORTED_SDK_INT: Integer; // I
    { class } function _GetPAY_SUPPORTED_SDK_INT: Integer; // I
    { class } function _GetOPENID_SUPPORTED_SDK_INT: Integer; // I
    { class } function _GetFAVORITE_SUPPPORTED_SDK_INT: Integer; // I
    { class } function _GetMESSAGE_ACTION_SUPPPORTED_SDK_INT: Integer; // I
    { class } function _GetSCAN_QRCODE_AUTH_SUPPORTED_SDK_INT: Integer; // I

    { static Methods }
    { class } function getMajorVersion: Integer; cdecl; // ()I
    { class } function getMinorVersion: Integer; cdecl; // ()I

    { static Property }
    { class } property SDK_INT: Integer read _GetSDK_INT;
    { class } property SDK_VERSION_NAME: JString read _GetSDK_VERSION_NAME;
    { class } property MIN_SDK_INT: Integer read _GetMIN_SDK_INT;
    { class } property TIMELINE_SUPPORTED_SDK_INT: Integer
      read _GetTIMELINE_SUPPORTED_SDK_INT;
    { class } property EMOJI_SUPPORTED_SDK_INT: Integer
      read _GetEMOJI_SUPPORTED_SDK_INT;
    { class } property MUSIC_DATA_URL_SUPPORTED_SDK_INT: Integer
      read _GetMUSIC_DATA_URL_SUPPORTED_SDK_INT;
    { class } property PAY_SUPPORTED_SDK_INT: Integer
      read _GetPAY_SUPPORTED_SDK_INT;
    { class } property OPENID_SUPPORTED_SDK_INT: Integer
      read _GetOPENID_SUPPORTED_SDK_INT;
    { class } property FAVORITE_SUPPPORTED_SDK_INT: Integer
      read _GetFAVORITE_SUPPPORTED_SDK_INT;
    { class } property MESSAGE_ACTION_SUPPPORTED_SDK_INT: Integer
      read _GetMESSAGE_ACTION_SUPPPORTED_SDK_INT;
    { class } property SCAN_QRCODE_AUTH_SUPPORTED_SDK_INT: Integer
      read _GetSCAN_QRCODE_AUTH_SUPPORTED_SDK_INT;
  end;

  [JavaSignature('com/tencent/mm/sdk/constants/Build')]
  JBuild = interface(JObject)
    ['{D0732554-C31F-41F0-AFA2-461BA1AEF32E}']
    { Property Methods }

    { methods }

    { Property }
  end;

  TJBuild = class(TJavaGenericImport<JBuildClass, JBuild>)
  end;

  JConstantsAPI_TokenClass = interface(JObjectClass)
    ['{FBE5B411-5D44-4909-9521-30B85541FD56}']
    { static Property Methods }
    { class } function _GetWX_TOKEN_KEY: JString; // Ljava/lang/String;
    { class } function _GetWX_TOKEN_VALUE_MSG: JString; // Ljava/lang/String;
    { class } function _GetWX_TOKEN_PLATFORMID_KEY: JString;
    // Ljava/lang/String;
    { class } function _GetWX_TOKEN_PLATFORMID_VALUE: JString;
    // Ljava/lang/String;
    { class } function _GetWX_LAUNCH_PARAM_KEY: JString; // Ljava/lang/String;

    { static Methods }
    { class } function init: JConstantsAPI_Token; cdecl; // ()V

    { static Property }
    { class } property WX_TOKEN_KEY: JString read _GetWX_TOKEN_KEY;
    { class } property WX_TOKEN_VALUE_MSG: JString read _GetWX_TOKEN_VALUE_MSG;
    { class } property WX_TOKEN_PLATFORMID_KEY: JString
      read _GetWX_TOKEN_PLATFORMID_KEY;
    { class } property WX_TOKEN_PLATFORMID_VALUE: JString
      read _GetWX_TOKEN_PLATFORMID_VALUE;
    { class } property WX_LAUNCH_PARAM_KEY: JString
      read _GetWX_LAUNCH_PARAM_KEY;
  end;

  [JavaSignature('com/tencent/mm/sdk/constants/ConstantsAPI$Token')]
  JConstantsAPI_Token = interface(JObject)
    ['{60659560-92D0-4252-99D6-F74D03B42BF6}']
    { Property Methods }

    { methods }

    { Property }
  end;

  TJConstantsAPI_Token = class(TJavaGenericImport<JConstantsAPI_TokenClass,
    JConstantsAPI_Token>)
  end;

  JConstantsAPI_WXAppClass = interface(JObjectClass)
    ['{E5FDCDB5-93ED-4453-B276-E770B7E9F4B0}']
    { static Property Methods }
    { class } function _GetWXAPP_PACKAGE_NAME: JString; // Ljava/lang/String;
    { class } function _GetWXAPP_BROADCAST_PERMISSION: JString;
    // Ljava/lang/String;
    { class } function _GetWXAPP_MSG_ENTRY_CLASSNAME: JString;
    // Ljava/lang/String;

    { static Methods }
    { class } function init: JConstantsAPI_WXApp; cdecl; // ()V

    { static Property }
    { class } property WXAPP_PACKAGE_NAME: JString read _GetWXAPP_PACKAGE_NAME;
    { class } property WXAPP_BROADCAST_PERMISSION: JString
      read _GetWXAPP_BROADCAST_PERMISSION;
    { class } property WXAPP_MSG_ENTRY_CLASSNAME: JString
      read _GetWXAPP_MSG_ENTRY_CLASSNAME;
  end;

  [JavaSignature('com/tencent/mm/sdk/constants/ConstantsAPI$WXApp')]
  JConstantsAPI_WXApp = interface(JObject)
    ['{E1592FA4-CF5B-43E1-946E-9E8B15465F59}']
    { Property Methods }

    { methods }

    { Property }
  end;

  TJConstantsAPI_WXApp = class(TJavaGenericImport<JConstantsAPI_WXAppClass,
    JConstantsAPI_WXApp>)
  end;

  JConstantsAPIClass = interface(JObjectClass)
    ['{7D3ACF7E-9247-490C-B9CE-B6024FD35679}']
    { static Property Methods }
    { class } function _GetACTION_HANDLE_APP_REGISTER: JString;
    // Ljava/lang/String;
    { class } function _GetACTION_HANDLE_APP_UNREGISTER: JString;
    // Ljava/lang/String;
    { class } function _GetACTION_REFRESH_WXAPP: JString; // Ljava/lang/String;
    { class } function _GetCOMMAND_UNKNOWN: Integer; // I
    { class } function _GetCOMMAND_SENDAUTH: Integer; // I
    { class } function _GetCOMMAND_SENDMESSAGE_TO_WX: Integer; // I
    { class } function _GetCOMMAND_GETMESSAGE_FROM_WX: Integer; // I
    { class } function _GetCOMMAND_SHOWMESSAGE_FROM_WX: Integer; // I
    { class } function _GetCOMMAND_PAY_BY_WX: Integer; // I
    { class } function _GetCOMMAND_LAUNCH_BY_WX: Integer; // I
    { class } function _GetCOMMAND_JUMP_TO_BIZ_PROFILE: Integer; // I
    { class } function _GetCOMMAND_JUMP_BIZ_WEBVIEW: Integer; // I
    { class } function _GetCOMMAND_ADD_CARD_TO_EX_CARD_PACKAGE: Integer; // I
    { class } function _GetCOMMAND_JUMP_BIZ_TEMPSESSION: Integer; // I
    { class } function _GetCOMMAND_OPEN_RANK_LIST: Integer; // I
    { class } function _GetCOMMAND_OPEN_WEBVIEW: Integer; // I
    { class } function _GetCOMMAND_OPEN_BUSI_LUCKY_MONEY: Integer; // I
    { class } function _GetCOMMAND_CREATE_CHATROOM: Integer; // I
    { class } function _GetCOMMAND_JOIN_CHATROOM: Integer; // I
    { class } function _GetAPP_PACKAGE: JString; // Ljava/lang/String;
    { class } function _GetSDK_VERSION: JString; // Ljava/lang/String;
    { class } function _GetCONTENT: JString; // Ljava/lang/String;
    { class } function _GetCHECK_SUM: JString; // Ljava/lang/String;

    { static Methods }

    { static Property }
    { class } property ACTION_HANDLE_APP_REGISTER: JString
      read _GetACTION_HANDLE_APP_REGISTER;
    { class } property ACTION_HANDLE_APP_UNREGISTER: JString
      read _GetACTION_HANDLE_APP_UNREGISTER;
    { class } property ACTION_REFRESH_WXAPP: JString
      read _GetACTION_REFRESH_WXAPP;
    { class } property COMMAND_UNKNOWN: Integer read _GetCOMMAND_UNKNOWN;
    { class } property COMMAND_SENDAUTH: Integer read _GetCOMMAND_SENDAUTH;
    { class } property COMMAND_SENDMESSAGE_TO_WX: Integer
      read _GetCOMMAND_SENDMESSAGE_TO_WX;
    { class } property COMMAND_GETMESSAGE_FROM_WX: Integer
      read _GetCOMMAND_GETMESSAGE_FROM_WX;
    { class } property COMMAND_SHOWMESSAGE_FROM_WX: Integer
      read _GetCOMMAND_SHOWMESSAGE_FROM_WX;
    { class } property COMMAND_PAY_BY_WX: Integer read _GetCOMMAND_PAY_BY_WX;
    { class } property COMMAND_LAUNCH_BY_WX: Integer
      read _GetCOMMAND_LAUNCH_BY_WX;
    { class } property COMMAND_JUMP_TO_BIZ_PROFILE: Integer
      read _GetCOMMAND_JUMP_TO_BIZ_PROFILE;
    { class } property COMMAND_JUMP_BIZ_WEBVIEW: Integer
      read _GetCOMMAND_JUMP_BIZ_WEBVIEW;
    { class } property COMMAND_ADD_CARD_TO_EX_CARD_PACKAGE: Integer
      read _GetCOMMAND_ADD_CARD_TO_EX_CARD_PACKAGE;
    { class } property COMMAND_JUMP_BIZ_TEMPSESSION: Integer
      read _GetCOMMAND_JUMP_BIZ_TEMPSESSION;
    { class } property COMMAND_OPEN_RANK_LIST: Integer
      read _GetCOMMAND_OPEN_RANK_LIST;
    { class } property COMMAND_OPEN_WEBVIEW: Integer
      read _GetCOMMAND_OPEN_WEBVIEW;
    { class } property COMMAND_OPEN_BUSI_LUCKY_MONEY: Integer
      read _GetCOMMAND_OPEN_BUSI_LUCKY_MONEY;
    { class } property COMMAND_CREATE_CHATROOM: Integer
      read _GetCOMMAND_CREATE_CHATROOM;
    { class } property COMMAND_JOIN_CHATROOM: Integer
      read _GetCOMMAND_JOIN_CHATROOM;
    { class } property APP_PACKAGE: JString read _GetAPP_PACKAGE;
    { class } property SDK_VERSION: JString read _GetSDK_VERSION;
    { class } property CONTENT: JString read _GetCONTENT;
    { class } property CHECK_SUM: JString read _GetCHECK_SUM;
  end;

  [JavaSignature('com/tencent/mm/sdk/constants/ConstantsAPI')]
  JConstantsAPI = interface(IJavaInstance)
    ['{EF4859F5-DB39-4CFB-ABB3-96A80F4B0843}']
    { Property Methods }

    { methods }

    { Property }
  end;

  TJConstantsAPI = class(TJavaGenericImport<JConstantsAPIClass, JConstantsAPI>)
  end;

  JDiffDevOAuthFactoryClass = interface(JObjectClass)
    ['{8D86A889-0C79-471F-83FC-4A013643300F}']
    { static Property Methods }
    { class } function _GetVERSION_1: Integer; // I
    { class } function _GetMAX_SUPPORTED_VERSION: Integer; // I

    { static Methods }
    { class } function getDiffDevOAuth: JIDiffDevOAuth; cdecl; overload;
    // ()Lcom/tencent/mm/sdk/diffdev/IDiffDevOAuth;
    { class } function getDiffDevOAuth(P1: Integer): JIDiffDevOAuth; cdecl;
      overload; // (I)Lcom/tencent/mm/sdk/diffdev/IDiffDevOAuth;

    { static Property }
    { class } property VERSION_1: Integer read _GetVERSION_1;
    { class } property MAX_SUPPORTED_VERSION: Integer
      read _GetMAX_SUPPORTED_VERSION;
  end;

  [JavaSignature('com/tencent/mm/sdk/diffdev/DiffDevOAuthFactory')]
  JDiffDevOAuthFactory = interface(JObject)
    ['{6BC300EA-06BF-4136-87B5-BB67A6F186B9}']
    { Property Methods }

    { methods }

    { Property }
  end;

  TJDiffDevOAuthFactory = class(TJavaGenericImport<JDiffDevOAuthFactoryClass,
    JDiffDevOAuthFactory>)
  end;

  JIDiffDevOAuthClass = interface(JObjectClass)
    ['{C65B5CC6-36B7-48C2-A5B7-CAE54522553E}']
    { static Property Methods }

    { static Methods }

    { static Property }
  end;

  [JavaSignature('com/tencent/mm/sdk/diffdev/IDiffDevOAuth')]
  JIDiffDevOAuth = interface(IJavaInstance)
    ['{146AE809-FAF4-49F6-9D13-BF18F6F22759}']
    { Property Methods }

    { methods }
    function auth(P1: JString; P2: JString; P3: JString; P4: JString;
      P5: JString; P6: JOAuthListener): Boolean; cdecl;
    // (Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Lcom/tencent/mm/sdk/diffdev/OAuthListener;)Z
    function stopAuth: Boolean; cdecl; // ()Z
    procedure addListener(P1: JOAuthListener); cdecl;
    // (Lcom/tencent/mm/sdk/diffdev/OAuthListener;)V
    procedure removeListener(P1: JOAuthListener); cdecl;
    // (Lcom/tencent/mm/sdk/diffdev/OAuthListener;)V
    procedure removeAllListeners; cdecl; // ()V
    procedure detach; cdecl; // ()V

    { Property }
  end;

  TJIDiffDevOAuth = class(TJavaGenericImport<JIDiffDevOAuthClass,
    JIDiffDevOAuth>)
  end;

  JOAuthErrCodeClass = interface(JEnumClass)
    // or JObjectClass // SuperSignature: java/lang/Enum
    ['{F802324D-9B29-494F-9256-15BA8BEE621F}']
    { static Property Methods }
    { class } function _GetWechatAuth_Err_OK: JOAuthErrCode;
    // Lcom/tencent/mm/sdk/diffdev/OAuthErrCode;
    { class } function _GetWechatAuth_Err_NormalErr: JOAuthErrCode;
    // Lcom/tencent/mm/sdk/diffdev/OAuthErrCode;
    { class } function _GetWechatAuth_Err_NetworkErr: JOAuthErrCode;
    // Lcom/tencent/mm/sdk/diffdev/OAuthErrCode;
    { class } function _GetWechatAuth_Err_JsonDecodeErr: JOAuthErrCode;
    // Lcom/tencent/mm/sdk/diffdev/OAuthErrCode;
    { class } function _GetWechatAuth_Err_Cancel: JOAuthErrCode;
    // Lcom/tencent/mm/sdk/diffdev/OAuthErrCode;
    { class } function _GetWechatAuth_Err_Timeout: JOAuthErrCode;
    // Lcom/tencent/mm/sdk/diffdev/OAuthErrCode;
    { class } function _GetWechatAuth_Err_Auth_Stopped: JOAuthErrCode;
    // Lcom/tencent/mm/sdk/diffdev/OAuthErrCode;

    { static Methods }
    { class } function values: TJavaObjectArray<JOAuthErrCode>; cdecl;
    // ()[Lcom/tencent/mm/sdk/diffdev/OAuthErrCode;
    { class } function valueOf(P1: JString): JOAuthErrCode; cdecl;
    // (Ljava/lang/String;)Lcom/tencent/mm/sdk/diffdev/OAuthErrCode;

    { static Property }
    { class } property WechatAuth_Err_OK: JOAuthErrCode
      read _GetWechatAuth_Err_OK;
    { class } property WechatAuth_Err_NormalErr: JOAuthErrCode
      read _GetWechatAuth_Err_NormalErr;
    { class } property WechatAuth_Err_NetworkErr: JOAuthErrCode
      read _GetWechatAuth_Err_NetworkErr;
    { class } property WechatAuth_Err_JsonDecodeErr: JOAuthErrCode
      read _GetWechatAuth_Err_JsonDecodeErr;
    { class } property WechatAuth_Err_Cancel: JOAuthErrCode
      read _GetWechatAuth_Err_Cancel;
    { class } property WechatAuth_Err_Timeout: JOAuthErrCode
      read _GetWechatAuth_Err_Timeout;
    { class } property WechatAuth_Err_Auth_Stopped: JOAuthErrCode
      read _GetWechatAuth_Err_Auth_Stopped;
  end;

  [JavaSignature('com/tencent/mm/sdk/diffdev/OAuthErrCode')]
  JOAuthErrCode = interface(JEnum)
    // or JObject // SuperSignature: java/lang/Enum
    ['{8CA67DB8-018B-428B-BBA2-C56BB33B5A48}']
    { Property Methods }

    { methods }
    function getCode: Integer; cdecl; // ()I
    function toString: JString; cdecl; // ()Ljava/lang/String;

    { Property }
  end;

  TJOAuthErrCode = class(TJavaGenericImport<JOAuthErrCodeClass, JOAuthErrCode>)
  end;

  JOAuthListenerClass = interface(JObjectClass)
    ['{23E91C92-2275-44DC-8E45-7446FD77C17F}']
    { static Property Methods }

    { static Methods }

    { static Property }
  end;

  [JavaSignature('com/tencent/mm/sdk/diffdev/OAuthListener')]
  JOAuthListener = interface(IJavaInstance)
    ['{894EB376-2821-434F-A911-1FF5BCABF186}']
    { Property Methods }

    { methods }
    procedure onAuthGotQrcode(P1: JString; P2: TJavaArray<Byte>); cdecl;
    // (Ljava/lang/String;[B)V
    procedure onQrcodeScanned; cdecl; // ()V
    procedure onAuthFinish(P1: JOAuthErrCode; P2: JString); cdecl;
    // (Lcom/tencent/mm/sdk/diffdev/OAuthErrCode;Ljava/lang/String;)V

    { Property }
  end;

  TJOAuthListener = class(TJavaGenericImport<JOAuthListenerClass,
    JOAuthListener>)
  end;

  JBaseReqClass = interface(JObjectClass)
    ['{6E22817A-8CB1-4FFD-8B31-56E4AD28A1F8}']
    { static Property Methods }

    { static Methods }
    { class } function init: JBaseReq; cdecl; // ()V

    { static Property }
  end;

  [JavaSignature('com/tencent/mm/sdk/modelbase/BaseReq')]
  JBaseReq = interface(JObject)
    ['{9A516615-839D-4885-A688-3B2CBF2E8E9C}']
    { Property Methods }
    function _Gettransaction: JString; // Ljava/lang/String;
    procedure _Settransaction(atransaction: JString); // (Ljava/lang/String;)V
    function _GetopenId: JString; // Ljava/lang/String;
    procedure _SetopenId(aopenId: JString); // (Ljava/lang/String;)V

    { methods }
    function getType: Integer; cdecl; // ()I
    procedure toBundle(P1: JBundle); cdecl; // (Landroid/os/Bundle;)V
    procedure fromBundle(P1: JBundle); cdecl; // (Landroid/os/Bundle;)V
    function checkArgs: Boolean; cdecl; // ()Z

    { Property }
    property transaction: JString read _Gettransaction write _Settransaction;
    property openId: JString read _GetopenId write _SetopenId;
  end;

  TJBaseReq = class(TJavaGenericImport<JBaseReqClass, JBaseReq>)
  end;

  JBaseResp_ErrCodeClass = interface(JObjectClass)
    ['{CCFD2D98-AF82-48C5-BB4E-86AAF7E53A84}']
    { static Property Methods }
    { class } function _GetERR_OK: Integer; // I
    { class } function _GetERR_COMM: Integer; // I
    { class } function _GetERR_USER_CANCEL: Integer; // I
    { class } function _GetERR_SENT_FAILED: Integer; // I
    { class } function _GetERR_AUTH_DENIED: Integer; // I
    { class } function _GetERR_UNSUPPORT: Integer; // I
    { class } function _GetERR_BAN: Integer; // I

    { static Methods }

    { static Property }
    { class } property ERR_OK: Integer read _GetERR_OK;
    { class } property ERR_COMM: Integer read _GetERR_COMM;
    { class } property ERR_USER_CANCEL: Integer read _GetERR_USER_CANCEL;
    { class } property ERR_SENT_FAILED: Integer read _GetERR_SENT_FAILED;
    { class } property ERR_AUTH_DENIED: Integer read _GetERR_AUTH_DENIED;
    { class } property ERR_UNSUPPORT: Integer read _GetERR_UNSUPPORT;
    { class } property ERR_BAN: Integer read _GetERR_BAN;
  end;

  [JavaSignature('com/tencent/mm/sdk/modelbase/BaseResp$ErrCode')]
  JBaseResp_ErrCode = interface(IJavaInstance)
    ['{3F2E1C84-49A1-4EF6-B7AE-A62E70299BF4}']
    { Property Methods }

    { methods }

    { Property }
  end;

  TJBaseResp_ErrCode = class(TJavaGenericImport<JBaseResp_ErrCodeClass,
    JBaseResp_ErrCode>)
  end;

  JBaseRespClass = interface(JObjectClass)
    ['{ED8E13F1-0EA5-45D3-BAC4-FBCBEAE3AA2B}']
    { static Property Methods }

    { static Methods }
    { class } function init: JBaseResp; cdecl; // ()V

    { static Property }
  end;

  [JavaSignature('com/tencent/mm/sdk/modelbase/BaseResp')]
  JBaseResp = interface(JObject)
    ['{E8A7E99F-7248-4CE2-863E-16FD232FB390}']
    { Property Methods }
    function _GeterrCode: Integer; // I
    procedure _SeterrCode(aerrCode: Integer); // (I)V
    function _GeterrStr: JString; // Ljava/lang/String;
    procedure _SeterrStr(aerrStr: JString); // (Ljava/lang/String;)V
    function _Gettransaction: JString; // Ljava/lang/String;
    procedure _Settransaction(atransaction: JString); // (Ljava/lang/String;)V
    function _GetopenId: JString; // Ljava/lang/String;
    procedure _SetopenId(aopenId: JString); // (Ljava/lang/String;)V

    { methods }
    function getType: Integer; cdecl; // ()I
    procedure toBundle(P1: JBundle); cdecl; // (Landroid/os/Bundle;)V
    procedure fromBundle(P1: JBundle); cdecl; // (Landroid/os/Bundle;)V
    function checkArgs: Boolean; cdecl; // ()Z

    { Property }
    property errCode: Integer read _GeterrCode write _SeterrCode;
    property errStr: JString read _GeterrStr write _SeterrStr;
    property transaction: JString read _Gettransaction write _Settransaction;
    property openId: JString read _GetopenId write _SetopenId;
  end;

  TJBaseResp = class(TJavaGenericImport<JBaseRespClass, JBaseResp>)
  end;

  JAddCardToWXCardPackage_ReqClass = interface(JBaseReqClass)
    // or JObjectClass // SuperSignature: com/tencent/mm/sdk/modelbase/BaseReq
    ['{755FBB8C-5F8A-4610-81AA-174E12BEAF22}']
    { static Property Methods }

    { static Methods }
    { class } function init: JAddCardToWXCardPackage_Req; cdecl; // ()V

    { static Property }
  end;

  [JavaSignature('com/tencent/mm/sdk/modelbiz/AddCardToWXCardPackage$Req')]
  JAddCardToWXCardPackage_Req = interface(JBaseReq)
    // or JObject // SuperSignature: com/tencent/mm/sdk/modelbase/BaseReq
    ['{26A61259-BFA7-4D56-8D17-082AD80E1639}']
    { Property Methods }
    function _GetcardArrary: JList; // Ljava/util/List;
    procedure _SetcardArrary(acardArrary: JList); // (Ljava/util/List;)V

    { methods }
    function getType: Integer; cdecl; // ()I
    function checkArgs: Boolean; cdecl; // ()Z
    procedure toBundle(P1: JBundle); cdecl; // (Landroid/os/Bundle;)V

    { Property }
    property cardArrary: JList read _GetcardArrary write _SetcardArrary;
  end;

  TJAddCardToWXCardPackage_Req = class
    (TJavaGenericImport<JAddCardToWXCardPackage_ReqClass,
    JAddCardToWXCardPackage_Req>)
  end;

  JAddCardToWXCardPackage_RespClass = interface(JBaseRespClass)
    // or JObjectClass // SuperSignature: com/tencent/mm/sdk/modelbase/BaseResp
    ['{898D9422-C288-4726-8F08-62D741646167}']
    { static Property Methods }

    { static Methods }
    { class } function init: JAddCardToWXCardPackage_Resp; cdecl; overload;
    // ()V
    { class } function init(P1: JBundle): JAddCardToWXCardPackage_Resp; cdecl;
      overload; // (Landroid/os/Bundle;)V

    { static Property }
  end;

  [JavaSignature('com/tencent/mm/sdk/modelbiz/AddCardToWXCardPackage$Resp')]
  JAddCardToWXCardPackage_Resp = interface(JBaseResp)
    // or JObject // SuperSignature: com/tencent/mm/sdk/modelbase/BaseResp
    ['{2A8B9006-CE7D-417E-9CD1-D393FF00A8D7}']
    { Property Methods }
    function _GetcardArrary: JList; // Ljava/util/List;
    procedure _SetcardArrary(acardArrary: JList); // (Ljava/util/List;)V

    { methods }
    function getType: Integer; cdecl; // ()I
    function checkArgs: Boolean; cdecl; // ()Z
    procedure toBundle(P1: JBundle); cdecl; // (Landroid/os/Bundle;)V
    procedure fromBundle(P1: JBundle); cdecl; // (Landroid/os/Bundle;)V

    { Property }
    property cardArrary: JList read _GetcardArrary write _SetcardArrary;
  end;

  TJAddCardToWXCardPackage_Resp = class
    (TJavaGenericImport<JAddCardToWXCardPackage_RespClass,
    JAddCardToWXCardPackage_Resp>)
  end;

  JAddCardToWXCardPackage_WXCardItemClass = interface(JObjectClass)
    ['{1FF276F6-E7C1-4B53-801E-6D119D8C4389}']
    { static Property Methods }

    { static Methods }
    { class } function init: JAddCardToWXCardPackage_WXCardItem; cdecl; // ()V

    { static Property }
  end;

  [JavaSignature
    ('com/tencent/mm/sdk/modelbiz/AddCardToWXCardPackage$WXCardItem')]
  JAddCardToWXCardPackage_WXCardItem = interface(JObject)
    ['{5DC2D06A-C696-4DF5-AF55-E33349CAF922}']
    { Property Methods }
    function _GetcardId: JString; // Ljava/lang/String;
    procedure _SetcardId(acardId: JString); // (Ljava/lang/String;)V
    function _GetcardExtMsg: JString; // Ljava/lang/String;
    procedure _SetcardExtMsg(acardExtMsg: JString); // (Ljava/lang/String;)V
    function _GetcardState: Integer; // I
    procedure _SetcardState(acardState: Integer); // (I)V

    { methods }

    { Property }
    property cardId: JString read _GetcardId write _SetcardId;
    property cardExtMsg: JString read _GetcardExtMsg write _SetcardExtMsg;
    property cardState: Integer read _GetcardState write _SetcardState;
  end;

  TJAddCardToWXCardPackage_WXCardItem = class
    (TJavaGenericImport<JAddCardToWXCardPackage_WXCardItemClass,
    JAddCardToWXCardPackage_WXCardItem>)
  end;

  JAddCardToWXCardPackageClass = interface(JObjectClass)
    ['{F798040D-4364-436D-940C-E297658CEB63}']
    { static Property Methods }

    { static Methods }
    { class } function init: JAddCardToWXCardPackage; cdecl; // ()V

    { static Property }
  end;

  [JavaSignature('com/tencent/mm/sdk/modelbiz/AddCardToWXCardPackage')]
  JAddCardToWXCardPackage = interface(JObject)
    ['{FD7FE351-F2CB-4099-B962-F663B6FC37F6}']
    { Property Methods }

    { methods }

    { Property }
  end;

  TJAddCardToWXCardPackage = class
    (TJavaGenericImport<JAddCardToWXCardPackageClass, JAddCardToWXCardPackage>)
  end;

  JCreateChatroom_ReqClass = interface(JBaseReqClass)
    // or JObjectClass // SuperSignature: com/tencent/mm/sdk/modelbase/BaseReq
    ['{C779546D-87A9-4839-9C8F-F29B4EEB90C6}']
    { static Property Methods }

    { static Methods }
    { class } function init: JCreateChatroom_Req; cdecl; // ()V

    { static Property }
  end;

  [JavaSignature('com/tencent/mm/sdk/modelbiz/CreateChatroom$Req')]
  JCreateChatroom_Req = interface(JBaseReq)
    // or JObject // SuperSignature: com/tencent/mm/sdk/modelbase/BaseReq
    ['{0A14DF07-7510-43AE-B3A0-E60A5BF62937}']
    { Property Methods }
    function _GetgroupId: JString; // Ljava/lang/String;
    procedure _SetgroupId(agroupId: JString); // (Ljava/lang/String;)V
    function _GetchatroomName: JString; // Ljava/lang/String;
    procedure _SetchatroomName(achatroomName: JString); // (Ljava/lang/String;)V
    function _GetchatroomNickName: JString; // Ljava/lang/String;
    procedure _SetchatroomNickName(achatroomNickName: JString);
    // (Ljava/lang/String;)V
    function _GetextMsg: JString; // Ljava/lang/String;
    procedure _SetextMsg(aextMsg: JString); // (Ljava/lang/String;)V

    { methods }
    function getType: Integer; cdecl; // ()I
    function checkArgs: Boolean; cdecl; // ()Z
    procedure toBundle(P1: JBundle); cdecl; // (Landroid/os/Bundle;)V

    { Property }
    property groupId: JString read _GetgroupId write _SetgroupId;
    property chatroomName: JString read _GetchatroomName write _SetchatroomName;
    property chatroomNickName: JString read _GetchatroomNickName
      write _SetchatroomNickName;
    property extMsg: JString read _GetextMsg write _SetextMsg;
  end;

  TJCreateChatroom_Req = class(TJavaGenericImport<JCreateChatroom_ReqClass,
    JCreateChatroom_Req>)
  end;

  JCreateChatroom_RespClass = interface(JBaseRespClass)
    // or JObjectClass // SuperSignature: com/tencent/mm/sdk/modelbase/BaseResp
    ['{CDC82E59-99BA-4D08-AEF8-2CA8F62AC01B}']
    { static Property Methods }

    { static Methods }
    { class } function init: JCreateChatroom_Resp; cdecl; overload; // ()V
    { class } function init(P1: JBundle): JCreateChatroom_Resp; cdecl; overload;
    // (Landroid/os/Bundle;)V

    { static Property }
  end;

  [JavaSignature('com/tencent/mm/sdk/modelbiz/CreateChatroom$Resp')]
  JCreateChatroom_Resp = interface(JBaseResp)
    // or JObject // SuperSignature: com/tencent/mm/sdk/modelbase/BaseResp
    ['{8EFE90F8-7581-40C9-BC7C-348CABCA96BC}']
    { Property Methods }
    function _GetextMsg: JString; // Ljava/lang/String;
    procedure _SetextMsg(aextMsg: JString); // (Ljava/lang/String;)V

    { methods }
    function getType: Integer; cdecl; // ()I
    procedure fromBundle(P1: JBundle); cdecl; // (Landroid/os/Bundle;)V
    procedure toBundle(P1: JBundle); cdecl; // (Landroid/os/Bundle;)V
    function checkArgs: Boolean; cdecl; // ()Z

    { Property }
    property extMsg: JString read _GetextMsg write _SetextMsg;
  end;

  TJCreateChatroom_Resp = class(TJavaGenericImport<JCreateChatroom_RespClass,
    JCreateChatroom_Resp>)
  end;

  JCreateChatroomClass = interface(JObjectClass)
    ['{A3BCC4CA-45E4-419D-937B-521BCE38D2B6}']
    { static Property Methods }

    { static Methods }

    { static Property }
  end;

  [JavaSignature('com/tencent/mm/sdk/modelbiz/CreateChatroom')]
  JCreateChatroom = interface(JObject)
    ['{24A95ACB-0840-4CDC-A918-70B16EFDAD44}']
    { Property Methods }

    { methods }

    { Property }
  end;

  TJCreateChatroom = class(TJavaGenericImport<JCreateChatroomClass,
    JCreateChatroom>)
  end;

  JJoinChatroom_ReqClass = interface(JBaseReqClass)
    // or JObjectClass // SuperSignature: com/tencent/mm/sdk/modelbase/BaseReq
    ['{7B37D5A9-09AC-4781-B307-6C687FBAF1AD}']
    { static Property Methods }

    { static Methods }
    { class } function init: JJoinChatroom_Req; cdecl; // ()V

    { static Property }
  end;

  [JavaSignature('com/tencent/mm/sdk/modelbiz/JoinChatroom$Req')]
  JJoinChatroom_Req = interface(JBaseReq)
    // or JObject // SuperSignature: com/tencent/mm/sdk/modelbase/BaseReq
    ['{4DE5190E-2478-46EC-84D0-AD9DA0DCCE44}']
    { Property Methods }
    function _GetgroupId: JString; // Ljava/lang/String;
    procedure _SetgroupId(agroupId: JString); // (Ljava/lang/String;)V
    function _GetchatroomNickName: JString; // Ljava/lang/String;
    procedure _SetchatroomNickName(achatroomNickName: JString);
    // (Ljava/lang/String;)V
    function _GetextMsg: JString; // Ljava/lang/String;
    procedure _SetextMsg(aextMsg: JString); // (Ljava/lang/String;)V

    { methods }
    function getType: Integer; cdecl; // ()I
    function checkArgs: Boolean; cdecl; // ()Z
    procedure toBundle(P1: JBundle); cdecl; // (Landroid/os/Bundle;)V

    { Property }
    property groupId: JString read _GetgroupId write _SetgroupId;
    property chatroomNickName: JString read _GetchatroomNickName
      write _SetchatroomNickName;
    property extMsg: JString read _GetextMsg write _SetextMsg;
  end;

  TJJoinChatroom_Req = class(TJavaGenericImport<JJoinChatroom_ReqClass,
    JJoinChatroom_Req>)
  end;

  JJoinChatroom_RespClass = interface(JBaseRespClass)
    // or JObjectClass // SuperSignature: com/tencent/mm/sdk/modelbase/BaseResp
    ['{CDFA07E7-B0F5-4081-967B-AA843391F6AC}']
    { static Property Methods }

    { static Methods }
    { class } function init: JJoinChatroom_Resp; cdecl; overload; // ()V
    { class } function init(P1: JBundle): JJoinChatroom_Resp; cdecl; overload;
    // (Landroid/os/Bundle;)V

    { static Property }
  end;

  [JavaSignature('com/tencent/mm/sdk/modelbiz/JoinChatroom$Resp')]
  JJoinChatroom_Resp = interface(JBaseResp)
    // or JObject // SuperSignature: com/tencent/mm/sdk/modelbase/BaseResp
    ['{509226B7-A02B-4718-9664-0E1A6D1D7310}']
    { Property Methods }
    function _GetextMsg: JString; // Ljava/lang/String;
    procedure _SetextMsg(aextMsg: JString); // (Ljava/lang/String;)V

    { methods }
    function getType: Integer; cdecl; // ()I
    procedure fromBundle(P1: JBundle); cdecl; // (Landroid/os/Bundle;)V
    procedure toBundle(P1: JBundle); cdecl; // (Landroid/os/Bundle;)V
    function checkArgs: Boolean; cdecl; // ()Z

    { Property }
    property extMsg: JString read _GetextMsg write _SetextMsg;
  end;

  TJJoinChatroom_Resp = class(TJavaGenericImport<JJoinChatroom_RespClass,
    JJoinChatroom_Resp>)
  end;

  JJoinChatroomClass = interface(JObjectClass)
    ['{444AEC29-59C0-437A-9D05-CE2CF9223CB6}']
    { static Property Methods }

    { static Methods }

    { static Property }
  end;

  [JavaSignature('com/tencent/mm/sdk/modelbiz/JoinChatroom')]
  JJoinChatroom = interface(JObject)
    ['{16F724C7-89A7-4C9E-8BF3-CB55B3C7CDE6}']
    { Property Methods }

    { methods }

    { Property }
  end;

  TJJoinChatroom = class(TJavaGenericImport<JJoinChatroomClass, JJoinChatroom>)
  end;

  JJumpToBizProfile_ReqClass = interface(JBaseReqClass)
    // or JObjectClass // SuperSignature: com/tencent/mm/sdk/modelbase/BaseReq
    ['{7FF44569-9275-4CED-AC22-E14393D900EE}']
    { static Property Methods }

    { static Methods }
    { class } function init: JJumpToBizProfile_Req; cdecl; // ()V

    { static Property }
  end;

  [JavaSignature('com/tencent/mm/sdk/modelbiz/JumpToBizProfile$Req')]
  JJumpToBizProfile_Req = interface(JBaseReq)
    // or JObject // SuperSignature: com/tencent/mm/sdk/modelbase/BaseReq
    ['{3FF362C3-4419-4614-B9CA-2B83C2F335C6}']
    { Property Methods }
    function _GettoUserName: JString; // Ljava/lang/String;
    procedure _SettoUserName(atoUserName: JString); // (Ljava/lang/String;)V
    function _GetextMsg: JString; // Ljava/lang/String;
    procedure _SetextMsg(aextMsg: JString); // (Ljava/lang/String;)V
    function _GetprofileType: Integer; // I
    procedure _SetprofileType(aprofileType: Integer); // (I)V

    { methods }
    function getType: Integer; cdecl; // ()I
    function checkArgs: Boolean; cdecl; // ()Z
    procedure toBundle(P1: JBundle); cdecl; // (Landroid/os/Bundle;)V
    procedure fromBundle(P1: JBundle); cdecl; // (Landroid/os/Bundle;)V

    { Property }
    property toUserName: JString read _GettoUserName write _SettoUserName;
    property extMsg: JString read _GetextMsg write _SetextMsg;
    property profileType: Integer read _GetprofileType write _SetprofileType;
  end;

  TJJumpToBizProfile_Req = class(TJavaGenericImport<JJumpToBizProfile_ReqClass,
    JJumpToBizProfile_Req>)
  end;

  JJumpToBizProfileClass = interface(JObjectClass)
    ['{7436EC84-062D-4D42-AC73-7055E4BACF00}']
    { static Property Methods }
    { class } function _GetJUMP_TO_NORMAL_BIZ_PROFILE: Integer; // I
    { class } function _GetJUMP_TO_HARD_WARE_BIZ_PROFILE: Integer; // I

    { static Methods }
    { class } function init: JJumpToBizProfile; cdecl; // ()V

    { static Property }
    { class } property JUMP_TO_NORMAL_BIZ_PROFILE: Integer
      read _GetJUMP_TO_NORMAL_BIZ_PROFILE;
    { class } property JUMP_TO_HARD_WARE_BIZ_PROFILE: Integer
      read _GetJUMP_TO_HARD_WARE_BIZ_PROFILE;
  end;

  [JavaSignature('com/tencent/mm/sdk/modelbiz/JumpToBizProfile')]
  JJumpToBizProfile = interface(JObject)
    ['{B65AA346-B5D9-43B3-8E7C-EA83487B44E1}']
    { Property Methods }

    { methods }

    { Property }
  end;

  TJJumpToBizProfile = class(TJavaGenericImport<JJumpToBizProfileClass,
    JJumpToBizProfile>)
  end;

  JJumpToBizTempSession_ReqClass = interface(JBaseReqClass)
    // or JObjectClass // SuperSignature: com/tencent/mm/sdk/modelbase/BaseReq
    ['{73CF560D-18B7-4AC4-8C43-83338C1743FE}']
    { static Property Methods }

    { static Methods }
    { class } function init: JJumpToBizTempSession_Req; cdecl; // ()V

    { static Property }
  end;

  [JavaSignature('com/tencent/mm/sdk/modelbiz/JumpToBizTempSession$Req')]
  JJumpToBizTempSession_Req = interface(JBaseReq)
    // or JObject // SuperSignature: com/tencent/mm/sdk/modelbase/BaseReq
    ['{C60B9A4F-CE72-40F4-AEAC-337BEF267718}']
    { Property Methods }
    function _GettoUserName: JString; // Ljava/lang/String;
    procedure _SettoUserName(atoUserName: JString); // (Ljava/lang/String;)V
    function _GetsessionFrom: JString; // Ljava/lang/String;
    procedure _SetsessionFrom(asessionFrom: JString); // (Ljava/lang/String;)V
    function _GetshowType: Integer; // I
    procedure _SetshowType(ashowType: Integer); // (I)V

    { methods }
    function getType: Integer; cdecl; // ()I
    function checkArgs: Boolean; cdecl; // ()Z
    procedure toBundle(P1: JBundle); cdecl; // (Landroid/os/Bundle;)V

    { Property }
    property toUserName: JString read _GettoUserName write _SettoUserName;
    property sessionFrom: JString read _GetsessionFrom write _SetsessionFrom;
    property showType: Integer read _GetshowType write _SetshowType;
  end;

  TJJumpToBizTempSession_Req = class
    (TJavaGenericImport<JJumpToBizTempSession_ReqClass,
    JJumpToBizTempSession_Req>)
  end;

  JJumpToBizTempSessionClass = interface(JObjectClass)
    ['{330951AE-0DD4-4E8B-992E-575CD68D1988}']
    { static Property Methods }
    { class } function _GetSHOW_MENU: Integer; // I
    { class } function _GetSHOW_CHAT: Integer; // I

    { static Methods }
    { class } function init: JJumpToBizTempSession; cdecl; // ()V

    { static Property }
    { class } property SHOW_MENU: Integer read _GetSHOW_MENU;
    { class } property SHOW_CHAT: Integer read _GetSHOW_CHAT;
  end;

  [JavaSignature('com/tencent/mm/sdk/modelbiz/JumpToBizTempSession')]
  JJumpToBizTempSession = interface(JObject)
    ['{3D0DB117-F78D-4430-BE8C-71C379C27237}']
    { Property Methods }

    { methods }

    { Property }
  end;

  TJJumpToBizTempSession = class(TJavaGenericImport<JJumpToBizTempSessionClass,
    JJumpToBizTempSession>)
  end;

  JJumpToBizWebview_ReqClass = interface(JBaseReqClass)
    // or JObjectClass // SuperSignature: com/tencent/mm/sdk/modelbase/BaseReq
    ['{91BE6834-53E2-4293-A8BB-CA05020B0C4C}']
    { static Property Methods }

    { static Methods }
    { class } function init: JJumpToBizWebview_Req; cdecl; // ()V

    { static Property }
  end;

  [JavaSignature('com/tencent/mm/sdk/modelbiz/JumpToBizWebview$Req')]
  JJumpToBizWebview_Req = interface(JBaseReq)
    // or JObject // SuperSignature: com/tencent/mm/sdk/modelbase/BaseReq
    ['{E1E56768-B11E-4B4F-9EDE-AFF8AFAEC8FD}']
    { Property Methods }
    function _GettoUserName: JString; // Ljava/lang/String;
    procedure _SettoUserName(atoUserName: JString); // (Ljava/lang/String;)V
    function _GetextMsg: JString; // Ljava/lang/String;
    procedure _SetextMsg(aextMsg: JString); // (Ljava/lang/String;)V
    function _GetwebType: Integer; // I
    procedure _SetwebType(awebType: Integer); // (I)V
    function _Getscene: Integer; // I
    procedure _Setscene(ascene: Integer); // (I)V

    { methods }
    function getType: Integer; cdecl; // ()I
    function checkArgs: Boolean; cdecl; // ()Z
    procedure toBundle(P1: JBundle); cdecl; // (Landroid/os/Bundle;)V

    { Property }
    property toUserName: JString read _GettoUserName write _SettoUserName;
    property extMsg: JString read _GetextMsg write _SetextMsg;
    property webType: Integer read _GetwebType write _SetwebType;
    property scene: Integer read _Getscene write _Setscene;
  end;

  TJJumpToBizWebview_Req = class(TJavaGenericImport<JJumpToBizWebview_ReqClass,
    JJumpToBizWebview_Req>)
  end;

  JJumpToBizWebviewClass = interface(JObjectClass)
    ['{4492BB0E-DEBD-4AFD-AFC9-C5A0CF1EC456}']
    { static Property Methods }

    { static Methods }
    { class } function init: JJumpToBizWebview; cdecl; // ()V

    { static Property }
  end;

  [JavaSignature('com/tencent/mm/sdk/modelbiz/JumpToBizWebview')]
  JJumpToBizWebview = interface(JObject)
    ['{D951CFCC-CEA3-4789-A193-B17B28EF97CE}']
    { Property Methods }

    { methods }

    { Property }
  end;

  TJJumpToBizWebview = class(TJavaGenericImport<JJumpToBizWebviewClass,
    JJumpToBizWebview>)
  end;

  JOpenBusiLuckyMoney_ReqClass = interface(JBaseReqClass)
    // or JObjectClass // SuperSignature: com/tencent/mm/sdk/modelbase/BaseReq
    ['{5014F79F-FE9E-4580-9835-5A25624066FA}']
    { static Property Methods }

    { static Methods }
    { class } function init: JOpenBusiLuckyMoney_Req; cdecl; // ()V

    { static Property }
  end;

  [JavaSignature('com/tencent/mm/sdk/modelbiz/OpenBusiLuckyMoney$Req')]
  JOpenBusiLuckyMoney_Req = interface(JBaseReq)
    // or JObject // SuperSignature: com/tencent/mm/sdk/modelbase/BaseReq
    ['{E4837D51-83CA-4E80-8814-617B94C7AB2D}']
    { Property Methods }
    function _GetappId: JString; // Ljava/lang/String;
    procedure _SetappId(aappId: JString); // (Ljava/lang/String;)V
    function _GettimeStamp: JString; // Ljava/lang/String;
    procedure _SettimeStamp(atimeStamp: JString); // (Ljava/lang/String;)V
    function _GetnonceStr: JString; // Ljava/lang/String;
    procedure _SetnonceStr(anonceStr: JString); // (Ljava/lang/String;)V
    function _GetpackageExt: JString; // Ljava/lang/String;
    procedure _SetpackageExt(apackageExt: JString); // (Ljava/lang/String;)V
    function _GetsignType: JString; // Ljava/lang/String;
    procedure _SetsignType(asignType: JString); // (Ljava/lang/String;)V
    function _Getsignature: JString; // Ljava/lang/String;
    procedure _Setsignature(asignature: JString); // (Ljava/lang/String;)V

    { methods }
    function getType: Integer; cdecl; // ()I
    function checkArgs: Boolean; cdecl; // ()Z
    procedure toBundle(P1: JBundle); cdecl; // (Landroid/os/Bundle;)V

    { Property }
    property appId: JString read _GetappId write _SetappId;
    property timeStamp: JString read _GettimeStamp write _SettimeStamp;
    property nonceStr: JString read _GetnonceStr write _SetnonceStr;
    property packageExt: JString read _GetpackageExt write _SetpackageExt;
    property signType: JString read _GetsignType write _SetsignType;
    property signature: JString read _Getsignature write _Setsignature;
  end;

  TJOpenBusiLuckyMoney_Req = class
    (TJavaGenericImport<JOpenBusiLuckyMoney_ReqClass, JOpenBusiLuckyMoney_Req>)
  end;

  JOpenBusiLuckyMoneyClass = interface(JObjectClass)
    ['{0BC708F3-0995-4E75-98E3-440AAE41BDBB}']
    { static Property Methods }

    { static Methods }
    { class } function init: JOpenBusiLuckyMoney; cdecl; // ()V

    { static Property }
  end;

  [JavaSignature('com/tencent/mm/sdk/modelbiz/OpenBusiLuckyMoney')]
  JOpenBusiLuckyMoney = interface(JObject)
    ['{F4E7FEBA-122C-419D-BEF9-6BCFD9A459D5}']
    { Property Methods }

    { methods }

    { Property }
  end;

  TJOpenBusiLuckyMoney = class(TJavaGenericImport<JOpenBusiLuckyMoneyClass,
    JOpenBusiLuckyMoney>)
  end;

  JOpenRankList_ReqClass = interface(JBaseReqClass)
    // or JObjectClass // SuperSignature: com/tencent/mm/sdk/modelbase/BaseReq
    ['{0F4A5577-D34B-4BB9-979C-0F2F1678A58D}']
    { static Property Methods }

    { static Methods }
    { class } function init: JOpenRankList_Req; cdecl; // ()V

    { static Property }
  end;

  [JavaSignature('com/tencent/mm/sdk/modelbiz/OpenRankList$Req')]
  JOpenRankList_Req = interface(JBaseReq)
    // or JObject // SuperSignature: com/tencent/mm/sdk/modelbase/BaseReq
    ['{429B223F-AAF5-40DE-AE64-7F406ED2FFDE}']
    { Property Methods }

    { methods }
    function getType: Integer; cdecl; // ()I
    function checkArgs: Boolean; cdecl; // ()Z

    { Property }
  end;

  TJOpenRankList_Req = class(TJavaGenericImport<JOpenRankList_ReqClass,
    JOpenRankList_Req>)
  end;

  JOpenRankListClass = interface(JObjectClass)
    ['{4DC8DC76-7F28-45A1-ACDB-8AD524CEE6EC}']
    { static Property Methods }

    { static Methods }
    { class } function init: JOpenRankList; cdecl; // ()V

    { static Property }
  end;

  [JavaSignature('com/tencent/mm/sdk/modelbiz/OpenRankList')]
  JOpenRankList = interface(JObject)
    ['{7BAD2B24-DA07-4962-99FE-816739E84976}']
    { Property Methods }

    { methods }

    { Property }
  end;

  TJOpenRankList = class(TJavaGenericImport<JOpenRankListClass, JOpenRankList>)
  end;

  JOpenWebview_ReqClass = interface(JBaseReqClass)
    // or JObjectClass // SuperSignature: com/tencent/mm/sdk/modelbase/BaseReq
    ['{D64A3FE3-82C2-466E-9987-33BF4B6312AC}']
    { static Property Methods }

    { static Methods }
    { class } function init: JOpenWebview_Req; cdecl; // ()V

    { static Property }
  end;

  [JavaSignature('com/tencent/mm/sdk/modelbiz/OpenWebview$Req')]
  JOpenWebview_Req = interface(JBaseReq)
    // or JObject // SuperSignature: com/tencent/mm/sdk/modelbase/BaseReq
    ['{A6D16ABF-48CD-431D-B79D-ED1BAE40A66B}']
    { Property Methods }
    function _Geturl: JString; // Ljava/lang/String;
    procedure _Seturl(aurl: JString); // (Ljava/lang/String;)V

    { methods }
    function getType: Integer; cdecl; // ()I
    function checkArgs: Boolean; cdecl; // ()Z
    procedure toBundle(P1: JBundle); cdecl; // (Landroid/os/Bundle;)V

    { Property }
    property url: JString read _Geturl write _Seturl;
  end;

  TJOpenWebview_Req = class(TJavaGenericImport<JOpenWebview_ReqClass,
    JOpenWebview_Req>)
  end;

  JOpenWebview_RespClass = interface(JBaseRespClass)
    // or JObjectClass // SuperSignature: com/tencent/mm/sdk/modelbase/BaseResp
    ['{8F45F736-F3AE-438D-9269-6E60151D08A9}']
    { static Property Methods }

    { static Methods }
    { class } function init: JOpenWebview_Resp; cdecl; overload; // ()V
    { class } function init(P1: JBundle): JOpenWebview_Resp; cdecl; overload;
    // (Landroid/os/Bundle;)V

    { static Property }
  end;

  [JavaSignature('com/tencent/mm/sdk/modelbiz/OpenWebview$Resp')]
  JOpenWebview_Resp = interface(JBaseResp)
    // or JObject // SuperSignature: com/tencent/mm/sdk/modelbase/BaseResp
    ['{B656FFDE-17D8-4A60-860C-4C282825CC43}']
    { Property Methods }
    function _Getresult: JString; // Ljava/lang/String;
    procedure _Setresult(aresult: JString); // (Ljava/lang/String;)V

    { methods }
    function getType: Integer; cdecl; // ()I
    procedure fromBundle(P1: JBundle); cdecl; // (Landroid/os/Bundle;)V
    procedure toBundle(P1: JBundle); cdecl; // (Landroid/os/Bundle;)V
    function checkArgs: Boolean; cdecl; // ()Z

    { Property }
    property result: JString read _Getresult write _Setresult;
  end;

  TJOpenWebview_Resp = class(TJavaGenericImport<JOpenWebview_RespClass,
    JOpenWebview_Resp>)
  end;

  JOpenWebviewClass = interface(JObjectClass)
    ['{B7177AE4-F572-4375-86A5-DDBB9E3C7E34}']
    { static Property Methods }

    { static Methods }
    { class } function init: JOpenWebview; cdecl; // ()V

    { static Property }
  end;

  [JavaSignature('com/tencent/mm/sdk/modelbiz/OpenWebview')]
  JOpenWebview = interface(JObject)
    ['{F168099B-7E8E-4FD2-85E1-8C44615DDDEE}']
    { Property Methods }

    { methods }

    { Property }
  end;

  TJOpenWebview = class(TJavaGenericImport<JOpenWebviewClass, JOpenWebview>)
  end;

  JGetMessageFromWX_ReqClass = interface(JBaseReqClass)
    // or JObjectClass // SuperSignature: com/tencent/mm/sdk/modelbase/BaseReq
    ['{1CEE276B-6CB2-44E9-9FEC-7C7C46227F65}']
    { static Property Methods }

    { static Methods }
    { class } function init: JGetMessageFromWX_Req; cdecl; overload; // ()V
    { class } function init(P1: JBundle): JGetMessageFromWX_Req; cdecl;
      overload; // (Landroid/os/Bundle;)V

    { static Property }
  end;

  [JavaSignature('com/tencent/mm/sdk/modelmsg/GetMessageFromWX$Req')]
  JGetMessageFromWX_Req = interface(JBaseReq)
    // or JObject // SuperSignature: com/tencent/mm/sdk/modelbase/BaseReq
    ['{93BD8BED-8DBC-4C18-83E6-535569B46791}']
    { Property Methods }
    function _Getusername: JString; // Ljava/lang/String;
    procedure _Setusername(ausername: JString); // (Ljava/lang/String;)V
    function _Getlang: JString; // Ljava/lang/String;
    procedure _Setlang(alang: JString); // (Ljava/lang/String;)V
    function _Getcountry: JString; // Ljava/lang/String;
    procedure _Setcountry(acountry: JString); // (Ljava/lang/String;)V

    { methods }
    function getType: Integer; cdecl; // ()I
    procedure toBundle(P1: JBundle); cdecl; // (Landroid/os/Bundle;)V
    procedure fromBundle(P1: JBundle); cdecl; // (Landroid/os/Bundle;)V
    function checkArgs: Boolean; cdecl; // ()Z

    { Property }
    property username: JString read _Getusername write _Setusername;
    property lang: JString read _Getlang write _Setlang;
    property country: JString read _Getcountry write _Setcountry;
  end;

  TJGetMessageFromWX_Req = class(TJavaGenericImport<JGetMessageFromWX_ReqClass,
    JGetMessageFromWX_Req>)
  end;

  JGetMessageFromWX_RespClass = interface(JBaseRespClass)
    // or JObjectClass // SuperSignature: com/tencent/mm/sdk/modelbase/BaseResp
    ['{4129EA4F-355E-49FF-A235-E99EA93E67F7}']
    { static Property Methods }

    { static Methods }
    { class } function init: JGetMessageFromWX_Resp; cdecl; overload; // ()V
    { class } function init(P1: JBundle): JGetMessageFromWX_Resp; cdecl;
      overload; // (Landroid/os/Bundle;)V

    { static Property }
  end;

  [JavaSignature('com/tencent/mm/sdk/modelmsg/GetMessageFromWX$Resp')]
  JGetMessageFromWX_Resp = interface(JBaseResp)
    // or JObject // SuperSignature: com/tencent/mm/sdk/modelbase/BaseResp
    ['{ECAF705B-3664-4F69-B684-16F0641DB4C1}']
    { Property Methods }
    function _Getmessage: JWXMediaMessage;
    // Lcom/tencent/mm/sdk/modelmsg/WXMediaMessage;
    procedure _Setmessage(amessage: JWXMediaMessage);
    // (Lcom/tencent/mm/sdk/modelmsg/WXMediaMessage;)V

    { methods }
    function getType: Integer; cdecl; // ()I
    procedure fromBundle(P1: JBundle); cdecl; // (Landroid/os/Bundle;)V
    procedure toBundle(P1: JBundle); cdecl; // (Landroid/os/Bundle;)V
    function checkArgs: Boolean; cdecl; // ()Z

    { Property }
    property &message: JWXMediaMessage read _Getmessage write _Setmessage;
  end;

  TJGetMessageFromWX_Resp = class
    (TJavaGenericImport<JGetMessageFromWX_RespClass, JGetMessageFromWX_Resp>)
  end;

  JGetMessageFromWXClass = interface(JObjectClass)
    ['{B9E97B89-7245-40C7-B2F1-20B0C7A10F94}']
    { static Property Methods }

    { static Methods }

    { static Property }
  end;

  [JavaSignature('com/tencent/mm/sdk/modelmsg/GetMessageFromWX')]
  JGetMessageFromWX = interface(JObject)
    ['{6E5D7F69-0326-44F7-9E32-918F4BF8E308}']
    { Property Methods }

    { methods }

    { Property }
  end;

  TJGetMessageFromWX = class(TJavaGenericImport<JGetMessageFromWXClass,
    JGetMessageFromWX>)
  end;

  JLaunchFromWX_ReqClass = interface(JBaseReqClass)
    // or JObjectClass // SuperSignature: com/tencent/mm/sdk/modelbase/BaseReq
    ['{40844483-8AB2-4EAB-A81B-6FD4DBBE2F5C}']
    { static Property Methods }

    { static Methods }
    { class } function init: JLaunchFromWX_Req; cdecl; overload; // ()V
    { class } function init(P1: JBundle): JLaunchFromWX_Req; cdecl; overload;
    // (Landroid/os/Bundle;)V

    { static Property }
  end;

  [JavaSignature('com/tencent/mm/sdk/modelmsg/LaunchFromWX$Req')]
  JLaunchFromWX_Req = interface(JBaseReq)
    // or JObject // SuperSignature: com/tencent/mm/sdk/modelbase/BaseReq
    ['{8DEC9B57-8286-4D18-B322-FA283A408169}']
    { Property Methods }
    function _GetmessageAction: JString; // Ljava/lang/String;
    procedure _SetmessageAction(amessageAction: JString);
    // (Ljava/lang/String;)V
    function _GetmessageExt: JString; // Ljava/lang/String;
    procedure _SetmessageExt(amessageExt: JString); // (Ljava/lang/String;)V
    function _Getlang: JString; // Ljava/lang/String;
    procedure _Setlang(alang: JString); // (Ljava/lang/String;)V
    function _Getcountry: JString; // Ljava/lang/String;
    procedure _Setcountry(acountry: JString); // (Ljava/lang/String;)V

    { methods }
    procedure toBundle(P1: JBundle); cdecl; // (Landroid/os/Bundle;)V
    procedure fromBundle(P1: JBundle); cdecl; // (Landroid/os/Bundle;)V
    function getType: Integer; cdecl; // ()I
    function checkArgs: Boolean; cdecl; // ()Z

    { Property }
    property messageAction: JString read _GetmessageAction
      write _SetmessageAction;
    property messageExt: JString read _GetmessageExt write _SetmessageExt;
    property lang: JString read _Getlang write _Setlang;
    property country: JString read _Getcountry write _Setcountry;
  end;

  TJLaunchFromWX_Req = class(TJavaGenericImport<JLaunchFromWX_ReqClass,
    JLaunchFromWX_Req>)
  end;

  JLaunchFromWX_RespClass = interface(JBaseRespClass)
    // or JObjectClass // SuperSignature: com/tencent/mm/sdk/modelbase/BaseResp
    ['{87B6BE37-69CF-41EB-9B28-68AAB5745D22}']
    { static Property Methods }

    { static Methods }
    { class } function init: JLaunchFromWX_Resp; cdecl; overload; // ()V
    { class } function init(P1: JBundle): JLaunchFromWX_Resp; cdecl; overload;
    // (Landroid/os/Bundle;)V

    { static Property }
  end;

  [JavaSignature('com/tencent/mm/sdk/modelmsg/LaunchFromWX$Resp')]
  JLaunchFromWX_Resp = interface(JBaseResp)
    // or JObject // SuperSignature: com/tencent/mm/sdk/modelbase/BaseResp
    ['{A4FBF12F-0A11-49A1-B78E-2B22F35500EA}']
    { Property Methods }

    { methods }
    function getType: Integer; cdecl; // ()I
    function checkArgs: Boolean; cdecl; // ()Z

    { Property }
  end;

  TJLaunchFromWX_Resp = class(TJavaGenericImport<JLaunchFromWX_RespClass,
    JLaunchFromWX_Resp>)
  end;

  JLaunchFromWXClass = interface(JObjectClass)
    ['{68AC6141-EECB-4C3F-999B-9D569B45B0BF}']
    { static Property Methods }

    { static Methods }

    { static Property }
  end;

  [JavaSignature('com/tencent/mm/sdk/modelmsg/LaunchFromWX')]
  JLaunchFromWX = interface(JObject)
    ['{FC2B1B34-AED1-4679-8438-90B1D764EB65}']
    { Property Methods }

    { methods }

    { Property }
  end;

  TJLaunchFromWX = class(TJavaGenericImport<JLaunchFromWXClass, JLaunchFromWX>)
  end;

  JSendAuth_ReqClass = interface(JBaseReqClass)
    // or JObjectClass // SuperSignature: com/tencent/mm/sdk/modelbase/BaseReq
    ['{D8C4BA8D-3319-44DE-BCB5-5E397052CA39}']
    { static Property Methods }

    { static Methods }
    { class } function init: JSendAuth_Req; cdecl; overload; // ()V
    { class } function init(P1: JBundle): JSendAuth_Req; cdecl; overload;
    // (Landroid/os/Bundle;)V

    { static Property }
  end;

  [JavaSignature('com/tencent/mm/sdk/modelmsg/SendAuth$Req')]
  JSendAuth_Req = interface(JBaseReq)
    // or JObject // SuperSignature: com/tencent/mm/sdk/modelbase/BaseReq
    ['{3356E049-AF8D-46D3-8D4F-34152F24C249}']
    { Property Methods }
    function _Getscope: JString; // Ljava/lang/String;
    procedure _Setscope(ascope: JString); // (Ljava/lang/String;)V
    function _Getstate: JString; // Ljava/lang/String;
    procedure _Setstate(astate: JString); // (Ljava/lang/String;)V

    { methods }
    function getType: Integer; cdecl; // ()I
    procedure fromBundle(P1: JBundle); cdecl; // (Landroid/os/Bundle;)V
    procedure toBundle(P1: JBundle); cdecl; // (Landroid/os/Bundle;)V
    function checkArgs: Boolean; cdecl; // ()Z

    { Property }
    property scope: JString read _Getscope write _Setscope;
    property state: JString read _Getstate write _Setstate;
  end;

  TJSendAuth_Req = class(TJavaGenericImport<JSendAuth_ReqClass, JSendAuth_Req>)
  end;

  JSendAuth_RespClass = interface(JBaseRespClass)
    // or JObjectClass // SuperSignature: com/tencent/mm/sdk/modelbase/BaseResp
    ['{5E30F8CA-CE28-4552-A97B-9C2848540124}']
    { static Property Methods }

    { static Methods }
    { class } function init: JSendAuth_Resp; cdecl; overload; // ()V
    { class } function init(P1: JBundle): JSendAuth_Resp; cdecl; overload;
    // (Landroid/os/Bundle;)V

    { static Property }
  end;

  [JavaSignature('com/tencent/mm/sdk/modelmsg/SendAuth$Resp')]
  JSendAuth_Resp = interface(JBaseResp)
    // or JObject // SuperSignature: com/tencent/mm/sdk/modelbase/BaseResp
    ['{29EDA15C-0E50-4F77-82DB-4FD5B10802D9}']
    { Property Methods }
    function _Getcode: JString; // Ljava/lang/String;
    procedure _Setcode(acode: JString); // (Ljava/lang/String;)V
    function _Getstate: JString; // Ljava/lang/String;
    procedure _Setstate(astate: JString); // (Ljava/lang/String;)V
    function _Geturl: JString; // Ljava/lang/String;
    procedure _Seturl(aurl: JString); // (Ljava/lang/String;)V
    function _Getlang: JString; // Ljava/lang/String;
    procedure _Setlang(alang: JString); // (Ljava/lang/String;)V
    function _Getcountry: JString; // Ljava/lang/String;
    procedure _Setcountry(acountry: JString); // (Ljava/lang/String;)V

    { methods }
    function getType: Integer; cdecl; // ()I
    procedure fromBundle(P1: JBundle); cdecl; // (Landroid/os/Bundle;)V
    procedure toBundle(P1: JBundle); cdecl; // (Landroid/os/Bundle;)V
    function checkArgs: Boolean; cdecl; // ()Z

    { Property }
    property code: JString read _Getcode write _Setcode;
    property state: JString read _Getstate write _Setstate;
    property url: JString read _Geturl write _Seturl;
    property lang: JString read _Getlang write _Setlang;
    property country: JString read _Getcountry write _Setcountry;
  end;

  TJSendAuth_Resp = class(TJavaGenericImport<JSendAuth_RespClass,
    JSendAuth_Resp>)
  end;

  JSendAuthClass = interface(JObjectClass)
    ['{CF321B4C-16A1-4270-ADD6-141232963BEF}']
    { static Property Methods }

    { static Methods }

    { static Property }
  end;

  [JavaSignature('com/tencent/mm/sdk/modelmsg/SendAuth')]
  JSendAuth = interface(JObject)
    ['{8D70D45D-F797-4EF6-80A4-F8E592EAF275}']
    { Property Methods }

    { methods }

    { Property }
  end;

  TJSendAuth = class(TJavaGenericImport<JSendAuthClass, JSendAuth>)
  end;

  JSendMessageToWX_ReqClass = interface(JBaseReqClass)
    // or JObjectClass // SuperSignature: com/tencent/mm/sdk/modelbase/BaseReq
    ['{E8DD43BB-F06D-461E-80C5-C858C91688E6}']
    { static Property Methods }
    { class } function _GetWXSceneSession: Integer; // I
    { class } function _GetWXSceneTimeline: Integer; // I
    { class } function _GetWXSceneFavorite: Integer; // I

    { static Methods }
    { class } function init: JSendMessageToWX_Req; cdecl; overload; // ()V
    { class } function init(P1: JBundle): JSendMessageToWX_Req; cdecl; overload;
    // (Landroid/os/Bundle;)V

    { static Property }
    { class } property WXSceneSession: Integer read _GetWXSceneSession;
    { class } property WXSceneTimeline: Integer read _GetWXSceneTimeline;
    { class } property WXSceneFavorite: Integer read _GetWXSceneFavorite;
  end;

  [JavaSignature('com/tencent/mm/sdk/modelmsg/SendMessageToWX$Req')]
  JSendMessageToWX_Req = interface(JBaseReq)
    // or JObject // SuperSignature: com/tencent/mm/sdk/modelbase/BaseReq
    ['{BC977394-5ABF-482A-9F3F-B66220EE995C}']
    { Property Methods }
    function _Getmessage: JWXMediaMessage;
    // Lcom/tencent/mm/sdk/modelmsg/WXMediaMessage;
    procedure _Setmessage(amessage: JWXMediaMessage);
    // (Lcom/tencent/mm/sdk/modelmsg/WXMediaMessage;)V
    function _Getscene: Integer; // I
    procedure _Setscene(ascene: Integer); // (I)V

    { methods }
    function getType: Integer; cdecl; // ()I
    procedure fromBundle(P1: JBundle); cdecl; // (Landroid/os/Bundle;)V
    procedure toBundle(P1: JBundle); cdecl; // (Landroid/os/Bundle;)V
    function checkArgs: Boolean; cdecl; // ()Z

    { Property }
    property &message: JWXMediaMessage read _Getmessage write _Setmessage;
    property scene: Integer read _Getscene write _Setscene;
  end;

  TJSendMessageToWX_Req = class(TJavaGenericImport<JSendMessageToWX_ReqClass,
    JSendMessageToWX_Req>)
  end;

  JSendMessageToWX_RespClass = interface(JBaseRespClass)
    // or JObjectClass // SuperSignature: com/tencent/mm/sdk/modelbase/BaseResp
    ['{206005F3-2C45-4171-9520-EEAA7AD2B921}']
    { static Property Methods }

    { static Methods }
    { class } function init: JSendMessageToWX_Resp; cdecl; overload; // ()V
    { class } function init(P1: JBundle): JSendMessageToWX_Resp; cdecl;
      overload; // (Landroid/os/Bundle;)V

    { static Property }
  end;

  [JavaSignature('com/tencent/mm/sdk/modelmsg/SendMessageToWX$Resp')]
  JSendMessageToWX_Resp = interface(JBaseResp)
    // or JObject // SuperSignature: com/tencent/mm/sdk/modelbase/BaseResp
    ['{EEDB9E47-C851-4C4F-B44B-97F1034D3D69}']
    { Property Methods }

    { methods }
    function getType: Integer; cdecl; // ()I
    procedure fromBundle(P1: JBundle); cdecl; // (Landroid/os/Bundle;)V
    procedure toBundle(P1: JBundle); cdecl; // (Landroid/os/Bundle;)V
    function checkArgs: Boolean; cdecl; // ()Z

    { Property }
  end;

  TJSendMessageToWX_Resp = class(TJavaGenericImport<JSendMessageToWX_RespClass,
    JSendMessageToWX_Resp>)
  end;

  JSendMessageToWXClass = interface(JObjectClass)
    ['{48597E4A-8A78-4501-97E8-96B92129EC25}']
    { static Property Methods }

    { static Methods }

    { static Property }
  end;

  [JavaSignature('com/tencent/mm/sdk/modelmsg/SendMessageToWX')]
  JSendMessageToWX = interface(JObject)
    ['{1E2F57DD-1E0B-46C9-A6F5-658B57D8E72F}']
    { Property Methods }

    { methods }

    { Property }
  end;

  TJSendMessageToWX = class(TJavaGenericImport<JSendMessageToWXClass,
    JSendMessageToWX>)
  end;

  JShowMessageFromWX_ReqClass = interface(JBaseReqClass)
    // or JObjectClass // SuperSignature: com/tencent/mm/sdk/modelbase/BaseReq
    ['{9389F594-8E9C-417B-A3D9-182B60731CD5}']
    { static Property Methods }

    { static Methods }
    { class } function init: JShowMessageFromWX_Req; cdecl; overload; // ()V
    { class } function init(P1: JBundle): JShowMessageFromWX_Req; cdecl;
      overload; // (Landroid/os/Bundle;)V

    { static Property }
  end;

  [JavaSignature('com/tencent/mm/sdk/modelmsg/ShowMessageFromWX$Req')]
  JShowMessageFromWX_Req = interface(JBaseReq)
    // or JObject // SuperSignature: com/tencent/mm/sdk/modelbase/BaseReq
    ['{35701096-8434-4107-AE1F-C063DB422557}']
    { Property Methods }
    function _Getmessage: JWXMediaMessage;
    // Lcom/tencent/mm/sdk/modelmsg/WXMediaMessage;
    procedure _Setmessage(amessage: JWXMediaMessage);
    // (Lcom/tencent/mm/sdk/modelmsg/WXMediaMessage;)V
    function _Getlang: JString; // Ljava/lang/String;
    procedure _Setlang(alang: JString); // (Ljava/lang/String;)V
    function _Getcountry: JString; // Ljava/lang/String;
    procedure _Setcountry(acountry: JString); // (Ljava/lang/String;)V

    { methods }
    function getType: Integer; cdecl; // ()I
    procedure toBundle(P1: JBundle); cdecl; // (Landroid/os/Bundle;)V
    procedure fromBundle(P1: JBundle); cdecl; // (Landroid/os/Bundle;)V
    function checkArgs: Boolean; cdecl; // ()Z

    { Property }
    property &message: JWXMediaMessage read _Getmessage write _Setmessage;
    property lang: JString read _Getlang write _Setlang;
    property country: JString read _Getcountry write _Setcountry;
  end;

  TJShowMessageFromWX_Req = class
    (TJavaGenericImport<JShowMessageFromWX_ReqClass, JShowMessageFromWX_Req>)
  end;

  JShowMessageFromWX_RespClass = interface(JBaseRespClass)
    // or JObjectClass // SuperSignature: com/tencent/mm/sdk/modelbase/BaseResp
    ['{B95A3225-20B9-4F7A-B665-77643FF0F6CA}']
    { static Property Methods }

    { static Methods }
    { class } function init: JShowMessageFromWX_Resp; cdecl; overload; // ()V
    { class } function init(P1: JBundle): JShowMessageFromWX_Resp; cdecl;
      overload; // (Landroid/os/Bundle;)V

    { static Property }
  end;

  [JavaSignature('com/tencent/mm/sdk/modelmsg/ShowMessageFromWX$Resp')]
  JShowMessageFromWX_Resp = interface(JBaseResp)
    // or JObject // SuperSignature: com/tencent/mm/sdk/modelbase/BaseResp
    ['{39569C35-6327-4A73-970B-C4C670097B93}']
    { Property Methods }

    { methods }
    function getType: Integer; cdecl; // ()I
    function checkArgs: Boolean; cdecl; // ()Z

    { Property }
  end;

  TJShowMessageFromWX_Resp = class
    (TJavaGenericImport<JShowMessageFromWX_RespClass, JShowMessageFromWX_Resp>)
  end;

  JShowMessageFromWXClass = interface(JObjectClass)
    ['{639E1FDE-12F0-4C5D-9CBD-55CF16D058B7}']
    { static Property Methods }

    { static Methods }

    { static Property }
  end;

  [JavaSignature('com/tencent/mm/sdk/modelmsg/ShowMessageFromWX')]
  JShowMessageFromWX = interface(JObject)
    ['{E6CBD452-9D54-48F6-B0D4-AC7257B13DC2}']
    { Property Methods }

    { methods }

    { Property }
  end;

  TJShowMessageFromWX = class(TJavaGenericImport<JShowMessageFromWXClass,
    JShowMessageFromWX>)
  end;

  JWXAppExtendObjectClass = interface(JObjectClass)
    ['{DA0DA8F8-FF5A-44D3-B96D-BE61B0B1E346}']
    { static Property Methods }

    { static Methods }
    { class } function init: JWXAppExtendObject; cdecl; overload; // ()V
    { class } function init(P1: JString; P2: TJavaArray<Byte>)
      : JWXAppExtendObject; cdecl; overload; // (Ljava/lang/String;[B)V
    { class } function init(P1: JString; P2: JString): JWXAppExtendObject;
      cdecl; overload; // (Ljava/lang/String;Ljava/lang/String;)V

    { static Property }
  end;

  [JavaSignature('com/tencent/mm/sdk/modelmsg/WXAppExtendObject')]
  JWXAppExtendObject = interface(JObject)
    ['{E955B9E5-46A8-4F9A-BC14-36C2E77E730D}']
    { Property Methods }
    function _GetextInfo: JString; // Ljava/lang/String;
    procedure _SetextInfo(aextInfo: JString); // (Ljava/lang/String;)V
    function _GetfilePath: JString; // Ljava/lang/String;
    procedure _SetfilePath(afilePath: JString); // (Ljava/lang/String;)V
    function _GetfileData: TJavaArray<Byte>; // [B
    procedure _SetfileData(afileData: TJavaArray<Byte>); // ([B)V

    { methods }
    procedure serialize(P1: JBundle); cdecl; // (Landroid/os/Bundle;)V
    procedure unserialize(P1: JBundle); cdecl; // (Landroid/os/Bundle;)V
    function &type: Integer; cdecl; // ()I
    function checkArgs: Boolean; cdecl; // ()Z

    { Property }
    property extInfo: JString read _GetextInfo write _SetextInfo;
    property filePath: JString read _GetfilePath write _SetfilePath;
    property fileData: TJavaArray<Byte> read _GetfileData write _SetfileData;
  end;

  TJWXAppExtendObject = class(TJavaGenericImport<JWXAppExtendObjectClass,
    JWXAppExtendObject>)
  end;

  JWXAppLaunchData_BuilderClass = interface(JObjectClass)
    ['{AE4DF006-D1AF-489F-9A04-7C9F06A2654B}']
    { static Property Methods }

    { static Methods }
    { class } function init: JWXAppLaunchData_Builder; cdecl; // ()V
    { class } function fromBundle(P1: JBundle): JWXAppLaunchData; cdecl;
    // (Landroid/os/Bundle;)Lcom/tencent/mm/sdk/modelmsg/WXAppLaunchData;
    { class } function toBundle(P1: JWXAppLaunchData): JBundle; cdecl;
    // (Lcom/tencent/mm/sdk/modelmsg/WXAppLaunchData;)Landroid/os/Bundle;

    { static Property }
  end;

  [JavaSignature('com/tencent/mm/sdk/modelmsg/WXAppLaunchData$Builder')]
  JWXAppLaunchData_Builder = interface(JObject)
    ['{4A0C65B9-0FF5-46E0-AC9B-C4BF14FCECE6}']
    { Property Methods }

    { methods }

    { Property }
  end;

  TJWXAppLaunchData_Builder = class
    (TJavaGenericImport<JWXAppLaunchData_BuilderClass,
    JWXAppLaunchData_Builder>)
  end;

  JWXAppLaunchDataClass = interface(JObjectClass)
    ['{FFDB827C-DF75-4DDD-BFDA-5E0A9C5403B2}']
    { static Property Methods }
    { class } function _GetACTION_HANDLE_WXAPPLAUNCH: JString;
    // Ljava/lang/String;
    { class } function _GetACTION_HANDLE_WXAPP_RESULT: JString;
    // Ljava/lang/String;
    { class } function _GetACTION_HANDLE_WXAPP_SHOW: JString;
    // Ljava/lang/String;

    { static Methods }
    { class } function init: JWXAppLaunchData; cdecl; // ()V

    { static Property }
    { class } property ACTION_HANDLE_WXAPPLAUNCH: JString
      read _GetACTION_HANDLE_WXAPPLAUNCH;
    { class } property ACTION_HANDLE_WXAPP_RESULT: JString
      read _GetACTION_HANDLE_WXAPP_RESULT;
    { class } property ACTION_HANDLE_WXAPP_SHOW: JString
      read _GetACTION_HANDLE_WXAPP_SHOW;
  end;

  [JavaSignature('com/tencent/mm/sdk/modelmsg/WXAppLaunchData')]
  JWXAppLaunchData = interface(JObject)
    ['{A4FDEBBE-C46C-4E68-B63D-B7917E601B48}']
    { Property Methods }
    function _GetlaunchType: Integer; // I
    procedure _SetlaunchType(alaunchType: Integer); // (I)V
    function _Getmessage: JString; // Ljava/lang/String;
    procedure _Setmessage(amessage: JString); // (Ljava/lang/String;)V

    { methods }

    { Property }
    property launchType: Integer read _GetlaunchType write _SetlaunchType;
    property &message: JString read _Getmessage write _Setmessage;
  end;

  TJWXAppLaunchData = class(TJavaGenericImport<JWXAppLaunchDataClass,
    JWXAppLaunchData>)
  end;

  JWXDesignerSharedObjectClass = interface(JObjectClass)
    ['{22D9C4C0-2E1E-4B17-BDF5-739F5EB2F369}']
    { static Property Methods }

    { static Methods }
    { class } function init: JWXDesignerSharedObject; cdecl; overload; // ()V
    { class } function init(P1: JString; P2: Integer; P3: JString; P4: JString)
      : JWXDesignerSharedObject; cdecl; overload;
    // (Ljava/lang/String;ILjava/lang/String;Ljava/lang/String;)V

    { static Property }
  end;

  [JavaSignature('com/tencent/mm/sdk/modelmsg/WXDesignerSharedObject')]
  JWXDesignerSharedObject = interface(JObject)
    ['{09F824E6-3C28-4EE1-AEE1-314BCB7643AD}']
    { Property Methods }
    function _Getthumburl: JString; // Ljava/lang/String;
    procedure _Setthumburl(athumburl: JString); // (Ljava/lang/String;)V
    function _GetdesignerUIN: Integer; // I
    procedure _SetdesignerUIN(adesignerUIN: Integer); // (I)V
    function _GetdesignerName: JString; // Ljava/lang/String;
    procedure _SetdesignerName(adesignerName: JString); // (Ljava/lang/String;)V
    function _GetdesignerRediretctUrl: JString; // Ljava/lang/String;
    procedure _SetdesignerRediretctUrl(adesignerRediretctUrl: JString);
    // (Ljava/lang/String;)V
    function _Geturl: JString; // Ljava/lang/String;
    procedure _Seturl(aurl: JString); // (Ljava/lang/String;)V

    { methods }
    procedure serialize(P1: JBundle); cdecl; // (Landroid/os/Bundle;)V
    procedure unserialize(P1: JBundle); cdecl; // (Landroid/os/Bundle;)V
    function &type: Integer; cdecl; // ()I
    function checkArgs: Boolean; cdecl; // ()Z

    { Property }
    property thumburl: JString read _Getthumburl write _Setthumburl;
    property designerUIN: Integer read _GetdesignerUIN write _SetdesignerUIN;
    property designerName: JString read _GetdesignerName write _SetdesignerName;
    property designerRediretctUrl: JString read _GetdesignerRediretctUrl
      write _SetdesignerRediretctUrl;
    property url: JString read _Geturl write _Seturl;
  end;

  TJWXDesignerSharedObject = class
    (TJavaGenericImport<JWXDesignerSharedObjectClass, JWXDesignerSharedObject>)
  end;

  JWXEmojiObjectClass = interface(JObjectClass)
    ['{67B9FB3D-8EB5-4C70-89E4-F011AD480A39}']
    { static Property Methods }

    { static Methods }
    { class } function init: JWXEmojiObject; cdecl; overload; // ()V
    { class } function init(P1: TJavaArray<Byte>): JWXEmojiObject; cdecl;
      overload; // ([B)V
    { class } function init(P1: JString): JWXEmojiObject; cdecl; overload;
    // (Ljava/lang/String;)V

    { static Property }
  end;

  [JavaSignature('com/tencent/mm/sdk/modelmsg/WXEmojiObject')]
  JWXEmojiObject = interface(JObject)
    ['{AAE7D961-C924-4B49-8EF3-B5BDDAABA51A}']
    { Property Methods }
    function _GetemojiData: TJavaArray<Byte>; // [B
    procedure _SetemojiData(aemojiData: TJavaArray<Byte>); // ([B)V
    function _GetemojiPath: JString; // Ljava/lang/String;
    procedure _SetemojiPath(aemojiPath: JString); // (Ljava/lang/String;)V

    { methods }
    procedure setEmojiData(P1: TJavaArray<Byte>); cdecl; // ([B)V
    procedure setEmojiPath(P1: JString); cdecl; // (Ljava/lang/String;)V
    procedure serialize(P1: JBundle); cdecl; // (Landroid/os/Bundle;)V
    procedure unserialize(P1: JBundle); cdecl; // (Landroid/os/Bundle;)V
    function &type: Integer; cdecl; // ()I
    function checkArgs: Boolean; cdecl; // ()Z

    { Property }
    property emojiData: TJavaArray<Byte> read _GetemojiData write _SetemojiData;
    property emojiPath: JString read _GetemojiPath write _SetemojiPath;
  end;

  TJWXEmojiObject = class(TJavaGenericImport<JWXEmojiObjectClass,
    JWXEmojiObject>)
  end;

  JWXEmojiSharedObjectClass = interface(JObjectClass)
    ['{B3885902-881E-459B-BC9C-36EBDEF38B9F}']
    { static Property Methods }

    { static Methods }
    { class } function init: JWXEmojiSharedObject; cdecl; overload; // ()V
    { class } function init(P1: JString; P2: Integer; P3: JString; P4: JString)
      : JWXEmojiSharedObject; cdecl; overload;
    // (Ljava/lang/String;ILjava/lang/String;Ljava/lang/String;)V

    { static Property }
  end;

  [JavaSignature('com/tencent/mm/sdk/modelmsg/WXEmojiSharedObject')]
  JWXEmojiSharedObject = interface(JObject)
    ['{EC3865DF-DB89-48DA-A239-429C1F3839D5}']
    { Property Methods }
    function _Getthumburl: JString; // Ljava/lang/String;
    procedure _Setthumburl(athumburl: JString); // (Ljava/lang/String;)V
    function _Getpackageflag: Integer; // I
    procedure _Setpackageflag(apackageflag: Integer); // (I)V
    function _Getpackageid: JString; // Ljava/lang/String;
    procedure _Setpackageid(apackageid: JString); // (Ljava/lang/String;)V
    function _Geturl: JString; // Ljava/lang/String;
    procedure _Seturl(aurl: JString); // (Ljava/lang/String;)V

    { methods }
    procedure serialize(P1: JBundle); cdecl; // (Landroid/os/Bundle;)V
    procedure unserialize(P1: JBundle); cdecl; // (Landroid/os/Bundle;)V
    function &type: Integer; cdecl; // ()I
    function checkArgs: Boolean; cdecl; // ()Z

    { Property }
    property thumburl: JString read _Getthumburl write _Setthumburl;
    property packageflag: Integer read _Getpackageflag write _Setpackageflag;
    property packageid: JString read _Getpackageid write _Setpackageid;
    property url: JString read _Geturl write _Seturl;
  end;

  TJWXEmojiSharedObject = class(TJavaGenericImport<JWXEmojiSharedObjectClass,
    JWXEmojiSharedObject>)
  end;

  JWXFileObjectClass = interface(JObjectClass)
    ['{904CCD81-20C0-4275-B76A-42233059D7F2}']
    { static Property Methods }

    { static Methods }
    { class } function init: JWXFileObject; cdecl; overload; // ()V
    { class } function init(P1: TJavaArray<Byte>): JWXFileObject; cdecl;
      overload; // ([B)V
    { class } function init(P1: JString): JWXFileObject; cdecl; overload;
    // (Ljava/lang/String;)V

    { static Property }
  end;

  [JavaSignature('com/tencent/mm/sdk/modelmsg/WXFileObject')]
  JWXFileObject = interface(JObject)
    ['{9FA9B35B-13DC-4178-9109-4C62FA407D43}']
    { Property Methods }
    function _GetfileData: TJavaArray<Byte>; // [B
    procedure _SetfileData(afileData: TJavaArray<Byte>); // ([B)V
    function _GetfilePath: JString; // Ljava/lang/String;
    procedure _SetfilePath(afilePath: JString); // (Ljava/lang/String;)V

    { methods }
    procedure setFileData(P1: TJavaArray<Byte>); cdecl; // ([B)V
    procedure setFilePath(P1: JString); cdecl; // (Ljava/lang/String;)V
    procedure serialize(P1: JBundle); cdecl; // (Landroid/os/Bundle;)V
    procedure unserialize(P1: JBundle); cdecl; // (Landroid/os/Bundle;)V
    function &type: Integer; cdecl; // ()I
    procedure setContentLengthLimit(P1: Integer); cdecl; // (I)V
    function checkArgs: Boolean; cdecl; // ()Z

    { Property }
    property fileData: TJavaArray<Byte> read _GetfileData write _SetfileData;
    property filePath: JString read _GetfilePath write _SetfilePath;
  end;

  TJWXFileObject = class(TJavaGenericImport<JWXFileObjectClass, JWXFileObject>)
  end;

  JWXImageObjectClass = interface(JObjectClass)
    ['{CDA66D55-B3BC-4B07-8D20-87AAE8B8F39A}']
    { static Property Methods }

    { static Methods }
    { class } function init: JWXImageObject; cdecl; overload; // ()V
    { class } function init(P1: TJavaArray<Byte>): JWXImageObject; cdecl;
      overload; // ([B)V
    { class } function init(P1: JBitmap): JWXImageObject; cdecl; overload;
    // (Landroid/graphics/Bitmap;)V

    { static Property }
  end;

  [JavaSignature('com/tencent/mm/sdk/modelmsg/WXImageObject')]
  JWXImageObject = interface(JObject)
    ['{CBC90C13-9DA6-469E-9BDE-AD8110354157}']
    { Property Methods }
    function _GetimageData: TJavaArray<Byte>; // [B
    procedure _SetimageData(aimageData: TJavaArray<Byte>); // ([B)V
    function _GetimagePath: JString; // Ljava/lang/String;
    procedure _SetimagePath(aimagePath: JString); // (Ljava/lang/String;)V

    { methods }
    procedure setImagePath(P1: JString); cdecl; // (Ljava/lang/String;)V
    procedure serialize(P1: JBundle); cdecl; // (Landroid/os/Bundle;)V
    procedure unserialize(P1: JBundle); cdecl; // (Landroid/os/Bundle;)V
    function &type: Integer; cdecl; // ()I
    function checkArgs: Boolean; cdecl; // ()Z

    { Property }
    property imageData: TJavaArray<Byte> read _GetimageData write _SetimageData;
    property imagePath: JString read _GetimagePath write _SetimagePath;
  end;

  TJWXImageObject = class(TJavaGenericImport<JWXImageObjectClass,
    JWXImageObject>)
  end;

  JWXMediaMessage_BuilderClass = interface(JObjectClass)
    ['{D2721C64-644F-4860-88D1-F89311BD0BA5}']
    { static Property Methods }
    { class } function _GetKEY_IDENTIFIER: JString; // Ljava/lang/String;

    { static Methods }
    { class } function init: JWXMediaMessage_Builder; cdecl; // ()V
    { class } function toBundle(P1: JWXMediaMessage): JBundle; cdecl;
    // (Lcom/tencent/mm/sdk/modelmsg/WXMediaMessage;)Landroid/os/Bundle;
    { class } function fromBundle(P1: JBundle): JWXMediaMessage; cdecl;
    // (Landroid/os/Bundle;)Lcom/tencent/mm/sdk/modelmsg/WXMediaMessage;

    { static Property }
    { class } property KEY_IDENTIFIER: JString read _GetKEY_IDENTIFIER;
  end;

  [JavaSignature('com/tencent/mm/sdk/modelmsg/WXMediaMessage$Builder')]
  JWXMediaMessage_Builder = interface(JObject)
    ['{55B295EE-05E9-4929-91E5-B9FC07794BB3}']
    { Property Methods }

    { methods }

    { Property }
  end;

  TJWXMediaMessage_Builder = class
    (TJavaGenericImport<JWXMediaMessage_BuilderClass, JWXMediaMessage_Builder>)
  end;

  JWXMediaMessage_IMediaObjectClass = interface(JObjectClass)
    ['{1DDF6A42-BA60-4E08-92EB-95A5DCCE2A0B}']
    { static Property Methods }
    { class } function _GetTYPE_UNKNOWN: Integer; // I
    { class } function _GetTYPE_TEXT: Integer; // I
    { class } function _GetTYPE_IMAGE: Integer; // I
    { class } function _GetTYPE_MUSIC: Integer; // I
    { class } function _GetTYPE_VIDEO: Integer; // I
    { class } function _GetTYPE_URL: Integer; // I
    { class } function _GetTYPE_FILE: Integer; // I
    { class } function _GetTYPE_APPDATA: Integer; // I
    { class } function _GetTYPE_EMOJI: Integer; // I
    { class } function _GetTYPE_PRODUCT: Integer; // I
    { class } function _GetTYPE_EMOTICON_GIFT: Integer; // I
    { class } function _GetTYPE_DEVICE_ACCESS: Integer; // I
    { class } function _GetTYPE_MALL_PRODUCT: Integer; // I
    { class } function _GetTYPE_OLD_TV: Integer; // I
    { class } function _GetTYPE_EMOTICON_SHARED: Integer; // I
    { class } function _GetTYPE_CARD_SHARE: Integer; // I
    { class } function _GetTYPE_LOCATION_SHARE: Integer; // I
    { class } function _GetTYPE_RECORD: Integer; // I
    { class } function _GetTYPE_TV: Integer; // I
    { class } function _GetTYPE_DESIGNER_SHARED: Integer; // I

    { static Methods }

    { static Property }
    { class } property TYPE_UNKNOWN: Integer read _GetTYPE_UNKNOWN;
    { class } property TYPE_TEXT: Integer read _GetTYPE_TEXT;
    { class } property TYPE_IMAGE: Integer read _GetTYPE_IMAGE;
    { class } property TYPE_MUSIC: Integer read _GetTYPE_MUSIC;
    { class } property TYPE_VIDEO: Integer read _GetTYPE_VIDEO;
    { class } property TYPE_URL: Integer read _GetTYPE_URL;
    { class } property TYPE_FILE: Integer read _GetTYPE_FILE;
    { class } property TYPE_APPDATA: Integer read _GetTYPE_APPDATA;
    { class } property TYPE_EMOJI: Integer read _GetTYPE_EMOJI;
    { class } property TYPE_PRODUCT: Integer read _GetTYPE_PRODUCT;
    { class } property TYPE_EMOTICON_GIFT: Integer read _GetTYPE_EMOTICON_GIFT;
    { class } property TYPE_DEVICE_ACCESS: Integer read _GetTYPE_DEVICE_ACCESS;
    { class } property TYPE_MALL_PRODUCT: Integer read _GetTYPE_MALL_PRODUCT;
    { class } property TYPE_OLD_TV: Integer read _GetTYPE_OLD_TV;
    { class } property TYPE_EMOTICON_SHARED: Integer
      read _GetTYPE_EMOTICON_SHARED;
    { class } property TYPE_CARD_SHARE: Integer read _GetTYPE_CARD_SHARE;
    { class } property TYPE_LOCATION_SHARE: Integer
      read _GetTYPE_LOCATION_SHARE;
    { class } property TYPE_RECORD: Integer read _GetTYPE_RECORD;
    { class } property TYPE_TV: Integer read _GetTYPE_TV;
    { class } property TYPE_DESIGNER_SHARED: Integer
      read _GetTYPE_DESIGNER_SHARED;
  end;

  [JavaSignature('com/tencent/mm/sdk/modelmsg/WXMediaMessage$IMediaObject')]
  JWXMediaMessage_IMediaObject = interface(IJavaInstance)
    ['{D4A66E84-171D-4C77-8DC1-3CA6DDEA0555}']
    { Property Methods }

    { methods }
    procedure serialize(P1: JBundle); cdecl; // (Landroid/os/Bundle;)V
    procedure unserialize(P1: JBundle); cdecl; // (Landroid/os/Bundle;)V
    function &type: Integer; cdecl; // ()I
    function checkArgs: Boolean; cdecl; // ()Z

    { Property }
  end;

  TJWXMediaMessage_IMediaObject = class
    (TJavaGenericImport<JWXMediaMessage_IMediaObjectClass,
    JWXMediaMessage_IMediaObject>)
  end;

  JWXMediaMessageClass = interface(JObjectClass)
    ['{D0F7A39E-A883-4E0C-8FAA-F19A5DB10520}']
    { static Property Methods }
    { class } function _GetTHUMB_LENGTH_LIMIT: Integer; // I
    { class } function _GetACTION_WXAPPMESSAGE: JString; // Ljava/lang/String;

    { static Methods }
    { class } function init: JWXMediaMessage; cdecl; overload; // ()V
    { class } function init(P1: JWXMediaMessage_IMediaObject): JWXMediaMessage;
      cdecl; overload;
    // (Lcom/tencent/mm/sdk/modelmsg/WXMediaMessage$IMediaObject;)V

    { static Property }
    { class } property THUMB_LENGTH_LIMIT: Integer read _GetTHUMB_LENGTH_LIMIT;
    { class } property ACTION_WXAPPMESSAGE: JString
      read _GetACTION_WXAPPMESSAGE;
  end;

  [JavaSignature('com/tencent/mm/sdk/modelmsg/WXMediaMessage')]
  JWXMediaMessage = interface(JObject)
    ['{4E4CFEF1-6342-4037-B9DE-57B6E9FE4C26}']
    { Property Methods }
    function _GetsdkVer: Integer; // I
    procedure _SetsdkVer(asdkVer: Integer); // (I)V
    function _Gettitle: JString; // Ljava/lang/String;
    procedure _Settitle(atitle: JString); // (Ljava/lang/String;)V
    function _Getdescription: JString; // Ljava/lang/String;
    procedure _Setdescription(adescription: JString); // (Ljava/lang/String;)V
    function _GetthumbData: TJavaArray<Byte>; // [B
    procedure _SetthumbData(athumbData: TJavaArray<Byte>); // ([B)V
    function _GetmediaObject: JWXMediaMessage_IMediaObject;
    // Lcom/tencent/mm/sdk/modelmsg/WXMediaMessage$IMediaObject;
    procedure _SetmediaObject(amediaObject: JWXMediaMessage_IMediaObject);
    // (Lcom/tencent/mm/sdk/modelmsg/WXMediaMessage$IMediaObject;)V
    function _GetmediaTagName: JString; // Ljava/lang/String;
    procedure _SetmediaTagName(amediaTagName: JString); // (Ljava/lang/String;)V
    function _GetmessageAction: JString; // Ljava/lang/String;
    procedure _SetmessageAction(amessageAction: JString);
    // (Ljava/lang/String;)V
    function _GetmessageExt: JString; // Ljava/lang/String;
    procedure _SetmessageExt(amessageExt: JString); // (Ljava/lang/String;)V

    { methods }
    function getType: Integer; cdecl; // ()I
    procedure setThumbImage(P1: JBitmap); cdecl; // (Landroid/graphics/Bitmap;)V

    { Property }
    property sdkVer: Integer read _GetsdkVer write _SetsdkVer;
    property title: JString read _Gettitle write _Settitle;
    property description: JString read _Getdescription write _Setdescription;
    property thumbData: TJavaArray<Byte> read _GetthumbData write _SetthumbData;
    property mediaObject: JWXMediaMessage_IMediaObject read _GetmediaObject
      write _SetmediaObject;
    property mediaTagName: JString read _GetmediaTagName write _SetmediaTagName;
    property messageAction: JString read _GetmessageAction
      write _SetmessageAction;
    property messageExt: JString read _GetmessageExt write _SetmessageExt;
  end;

  TJWXMediaMessage = class(TJavaGenericImport<JWXMediaMessageClass,
    JWXMediaMessage>)
  end;

  JWXMusicObjectClass = interface(JObjectClass)
    ['{1EE23A71-DD2A-4203-9406-7BE6CD69F451}']
    { static Property Methods }

    { static Methods }
    { class } function init: JWXMusicObject; cdecl; // ()V

    { static Property }
  end;

  [JavaSignature('com/tencent/mm/sdk/modelmsg/WXMusicObject')]
  JWXMusicObject = interface(JObject)
    ['{B80E9A32-CD72-4870-BB35-1B3F49B5FE55}']
    { Property Methods }
    function _GetmusicUrl: JString; // Ljava/lang/String;
    procedure _SetmusicUrl(amusicUrl: JString); // (Ljava/lang/String;)V
    function _GetmusicLowBandUrl: JString; // Ljava/lang/String;
    procedure _SetmusicLowBandUrl(amusicLowBandUrl: JString);
    // (Ljava/lang/String;)V
    function _GetmusicDataUrl: JString; // Ljava/lang/String;
    procedure _SetmusicDataUrl(amusicDataUrl: JString); // (Ljava/lang/String;)V
    function _GetmusicLowBandDataUrl: JString; // Ljava/lang/String;
    procedure _SetmusicLowBandDataUrl(amusicLowBandDataUrl: JString);
    // (Ljava/lang/String;)V

    { methods }
    procedure serialize(P1: JBundle); cdecl; // (Landroid/os/Bundle;)V
    procedure unserialize(P1: JBundle); cdecl; // (Landroid/os/Bundle;)V
    function &type: Integer; cdecl; // ()I
    function checkArgs: Boolean; cdecl; // ()Z

    { Property }
    property musicUrl: JString read _GetmusicUrl write _SetmusicUrl;
    property musicLowBandUrl: JString read _GetmusicLowBandUrl
      write _SetmusicLowBandUrl;
    property musicDataUrl: JString read _GetmusicDataUrl write _SetmusicDataUrl;
    property musicLowBandDataUrl: JString read _GetmusicLowBandDataUrl
      write _SetmusicLowBandDataUrl;
  end;

  TJWXMusicObject = class(TJavaGenericImport<JWXMusicObjectClass,
    JWXMusicObject>)
  end;

  JWXTextObjectClass = interface(JObjectClass)
    ['{0FB40792-7A8A-4CE6-9F89-AD109B2C4281}']
    { static Property Methods }

    { static Methods }
    { class } function init: JWXTextObject; cdecl; overload; // ()V
    { class } function init(P1: JString): JWXTextObject; cdecl; overload;
    // (Ljava/lang/String;)V

    { static Property }
  end;

  [JavaSignature('com/tencent/mm/sdk/modelmsg/WXTextObject')]
  JWXTextObject = interface(JObject)
    ['{73954F74-0DB1-4153-BF93-25D5EF01BC4B}']
    { Property Methods }
    function _Gettext: JString; // Ljava/lang/String;
    procedure _Settext(atext: JString); // (Ljava/lang/String;)V

    { methods }
    procedure serialize(P1: JBundle); cdecl; // (Landroid/os/Bundle;)V
    procedure unserialize(P1: JBundle); cdecl; // (Landroid/os/Bundle;)V
    function &type: Integer; cdecl; // ()I
    function checkArgs: Boolean; cdecl; // ()Z

    { Property }
    property text: JString read _Gettext write _Settext;
  end;

  TJWXTextObject = class(TJavaGenericImport<JWXTextObjectClass, JWXTextObject>)
  end;

  JWXVideoObjectClass = interface(JObjectClass)
    ['{97E6B337-DE04-4C45-B642-79A91C58B70B}']
    { static Property Methods }

    { static Methods }
    { class } function init: JWXVideoObject; cdecl; // ()V

    { static Property }
  end;

  [JavaSignature('com/tencent/mm/sdk/modelmsg/WXVideoObject')]
  JWXVideoObject = interface(JObject)
    ['{A2038962-D12E-4978-9DAE-912356943C86}']
    { Property Methods }
    function _GetvideoUrl: JString; // Ljava/lang/String;
    procedure _SetvideoUrl(avideoUrl: JString); // (Ljava/lang/String;)V
    function _GetvideoLowBandUrl: JString; // Ljava/lang/String;
    procedure _SetvideoLowBandUrl(avideoLowBandUrl: JString);
    // (Ljava/lang/String;)V

    { methods }
    procedure serialize(P1: JBundle); cdecl; // (Landroid/os/Bundle;)V
    procedure unserialize(P1: JBundle); cdecl; // (Landroid/os/Bundle;)V
    function &type: Integer; cdecl; // ()I
    function checkArgs: Boolean; cdecl; // ()Z

    { Property }
    property videoUrl: JString read _GetvideoUrl write _SetvideoUrl;
    property videoLowBandUrl: JString read _GetvideoLowBandUrl
      write _SetvideoLowBandUrl;
  end;

  TJWXVideoObject = class(TJavaGenericImport<JWXVideoObjectClass,
    JWXVideoObject>)
  end;

  JWXWebpageObjectClass = interface(JObjectClass)
    ['{FACDEDB8-61E5-40C1-86FC-505995280E25}']
    { static Property Methods }

    { static Methods }
    { class } function init: JWXWebpageObject; cdecl; overload; // ()V
    { class } function init(P1: JString): JWXWebpageObject; cdecl; overload;
    // (Ljava/lang/String;)V

    { static Property }
  end;

  [JavaSignature('com/tencent/mm/sdk/modelmsg/WXWebpageObject')]
  JWXWebpageObject = interface(JObject)
    ['{20969DCD-7C1E-4111-A068-EFDAEB0E5602}']
    { Property Methods }
    function _GetwebpageUrl: JString; // Ljava/lang/String;
    procedure _SetwebpageUrl(awebpageUrl: JString); // (Ljava/lang/String;)V
    function _GetextInfo: JString; // Ljava/lang/String;
    procedure _SetextInfo(aextInfo: JString); // (Ljava/lang/String;)V

    { methods }
    procedure serialize(P1: JBundle); cdecl; // (Landroid/os/Bundle;)V
    procedure unserialize(P1: JBundle); cdecl; // (Landroid/os/Bundle;)V
    function &type: Integer; cdecl; // ()I
    function checkArgs: Boolean; cdecl; // ()Z

    { Property }
    property webpageUrl: JString read _GetwebpageUrl write _SetwebpageUrl;
    property extInfo: JString read _GetextInfo write _SetextInfo;
  end;

  TJWXWebpageObject = class(TJavaGenericImport<JWXWebpageObjectClass,
    JWXWebpageObject>)
  end;

  JPayReq_OptionsClass = interface(JObjectClass)
    ['{DA589DF3-AFB5-4EEE-A5B0-47A15BC52139}']
    { static Property Methods }
    { class } function _GetINVALID_FLAGS: Integer; // I

    { static Methods }
    { class } function init: JPayReq_Options; cdecl; // ()V

    { static Property }
    { class } property INVALID_FLAGS: Integer read _GetINVALID_FLAGS;
  end;

  [JavaSignature('com/tencent/mm/sdk/modelpay/PayReq$Options')]
  JPayReq_Options = interface(JObject)
    ['{107EF25A-61AE-42C2-8FE8-0B5E195997D8}']
    { Property Methods }
    function _GetcallbackClassName: JString; // Ljava/lang/String;
    procedure _SetcallbackClassName(acallbackClassName: JString);
    // (Ljava/lang/String;)V
    function _GetcallbackFlags: Integer; // I
    procedure _SetcallbackFlags(acallbackFlags: Integer); // (I)V

    { methods }
    procedure toBundle(P1: JBundle); cdecl; // (Landroid/os/Bundle;)V
    procedure fromBundle(P1: JBundle); cdecl; // (Landroid/os/Bundle;)V

    { Property }
    property callbackClassName: JString read _GetcallbackClassName
      write _SetcallbackClassName;
    property callbackFlags: Integer read _GetcallbackFlags
      write _SetcallbackFlags;
  end;

  TJPayReq_Options = class(TJavaGenericImport<JPayReq_OptionsClass,
    JPayReq_Options>)
  end;

  JPayReqClass = interface(JBaseReqClass)
    // or JObjectClass // SuperSignature: com/tencent/mm/sdk/modelbase/BaseReq
    ['{5E4161FD-4206-4E83-8C4E-D8F0BDFA5C96}']
    { static Property Methods }

    { static Methods }
    { class } function init: JPayReq; cdecl; // ()V

    { static Property }
  end;

  [JavaSignature('com/tencent/mm/sdk/modelpay/PayReq')]
  JPayReq = interface(JBaseReq)
    // or JObject // SuperSignature: com/tencent/mm/sdk/modelbase/BaseReq
    ['{7716CA65-DEC1-41DC-8C4B-D16163BC13DF}']
    { Property Methods }
    function _GetappId: JString; // Ljava/lang/String;
    procedure _SetappId(aappId: JString); // (Ljava/lang/String;)V
    function _GetpartnerId: JString; // Ljava/lang/String;
    procedure _SetpartnerId(apartnerId: JString); // (Ljava/lang/String;)V
    function _GetprepayId: JString; // Ljava/lang/String;
    procedure _SetprepayId(aprepayId: JString); // (Ljava/lang/String;)V
    function _GetnonceStr: JString; // Ljava/lang/String;
    procedure _SetnonceStr(anonceStr: JString); // (Ljava/lang/String;)V
    function _GettimeStamp: JString; // Ljava/lang/String;
    procedure _SettimeStamp(atimeStamp: JString); // (Ljava/lang/String;)V
    function _GetpackageValue: JString; // Ljava/lang/String;
    procedure _SetpackageValue(apackageValue: JString); // (Ljava/lang/String;)V
    function _Getsign: JString; // Ljava/lang/String;
    procedure _Setsign(asign: JString); // (Ljava/lang/String;)V
    function _GetextData: JString; // Ljava/lang/String;
    procedure _SetextData(aextData: JString); // (Ljava/lang/String;)V
    function _Getoptions: JPayReq_Options;
    // Lcom/tencent/mm/sdk/modelpay/PayReq$Options;
    procedure _Setoptions(aoptions: JPayReq_Options);
    // (Lcom/tencent/mm/sdk/modelpay/PayReq$Options;)V
    function _GetsignType: JString; // Ljava/lang/String;
    procedure _SetsignType(asignType: JString); // (Ljava/lang/String;)V

    { methods }
    function checkArgs: Boolean; cdecl; // ()Z
    procedure toBundle(P1: JBundle); cdecl; // (Landroid/os/Bundle;)V
    procedure fromBundle(P1: JBundle); cdecl; // (Landroid/os/Bundle;)V
    function getType: Integer; cdecl; // ()I

    { Property }
    property appId: JString read _GetappId write _SetappId;
    property partnerId: JString read _GetpartnerId write _SetpartnerId;
    property prepayId: JString read _GetprepayId write _SetprepayId;
    property nonceStr: JString read _GetnonceStr write _SetnonceStr;
    property timeStamp: JString read _GettimeStamp write _SettimeStamp;
    property packageValue: JString read _GetpackageValue write _SetpackageValue;
    property sign: JString read _Getsign write _Setsign;
    property extData: JString read _GetextData write _SetextData;
    property options: JPayReq_Options read _Getoptions write _Setoptions;
    property signType: JString read _GetsignType write _SetsignType;
  end;

  TJPayReq = class(TJavaGenericImport<JPayReqClass, JPayReq>)
  end;

  JPayRespClass = interface(JBaseRespClass)
    // or JObjectClass // SuperSignature: com/tencent/mm/sdk/modelbase/BaseResp
    ['{FEAB27E6-B27A-44CA-BC4E-41A33A51A645}']
    { static Property Methods }

    { static Methods }
    { class } function init: JPayResp; cdecl; overload; // ()V
    { class } function init(P1: JBundle): JPayResp; cdecl; overload;
    // (Landroid/os/Bundle;)V

    { static Property }
  end;

  [JavaSignature('com/tencent/mm/sdk/modelpay/PayResp')]
  JPayResp = interface(JBaseResp)
    // or JObject // SuperSignature: com/tencent/mm/sdk/modelbase/BaseResp
    ['{BE4C92D4-7D96-4C07-B908-57285FFD8B57}']
    { Property Methods }
    function _GetprepayId: JString; // Ljava/lang/String;
    procedure _SetprepayId(aprepayId: JString); // (Ljava/lang/String;)V
    function _GetreturnKey: JString; // Ljava/lang/String;
    procedure _SetreturnKey(areturnKey: JString); // (Ljava/lang/String;)V
    function _GetextData: JString; // Ljava/lang/String;
    procedure _SetextData(aextData: JString); // (Ljava/lang/String;)V

    { methods }
    procedure toBundle(P1: JBundle); cdecl; // (Landroid/os/Bundle;)V
    procedure fromBundle(P1: JBundle); cdecl; // (Landroid/os/Bundle;)V
    function getType: Integer; cdecl; // ()I
    function checkArgs: Boolean; cdecl; // ()Z

    { Property }
    property prepayId: JString read _GetprepayId write _SetprepayId;
    property returnKey: JString read _GetreturnKey write _SetreturnKey;
    property extData: JString read _GetextData write _SetextData;
  end;

  TJPayResp = class(TJavaGenericImport<JPayRespClass, JPayResp>)
  end;

  JIWXAPIClass = interface(JObjectClass)
    ['{5CCF29D6-959F-4A77-B08C-4E25AD10845D}']
    { static Property Methods }

    { static Methods }

    { static Property }
  end;

  [JavaSignature('com/tencent/mm/sdk/openapi/IWXAPI')]
  JIWXAPI = interface(IJavaInstance)
    ['{74D1416C-0258-46E4-8A49-F12B301323F5}']
    { Property Methods }

    { methods }
    function registerApp(P1: JString): Boolean; cdecl; // (Ljava/lang/String;)Z
    procedure unregisterApp; cdecl; // ()V
    function handleIntent(P1: JIntent; P2: JIWXAPIEventHandler): Boolean; cdecl;
    // (Landroid/content/Intent;Lcom/tencent/mm/sdk/openapi/IWXAPIEventHandler;)Z
    function isWXAppInstalled: Boolean; cdecl; // ()Z
    function isWXAppSupportAPI: Boolean; cdecl; // ()Z
    function getWXAppSupportAPI: Integer; cdecl; // ()I
    function openWXApp: Boolean; cdecl; // ()Z
    function sendReq(P1: JBaseReq): Boolean; cdecl;
    // (Lcom/tencent/mm/sdk/modelbase/BaseReq;)Z
    function sendResp(P1: JBaseResp): Boolean; cdecl;
    // (Lcom/tencent/mm/sdk/modelbase/BaseResp;)Z
    procedure detach; cdecl; // ()V

    { Property }
  end;

  TJIWXAPI = class(TJavaGenericImport<JIWXAPIClass, JIWXAPI>)
  end;

  JIWXAPIEventHandlerClass = interface(JObjectClass)
    ['{7E3F06B9-C57F-403F-9942-8504068CD800}']
    { static Property Methods }

    { static Methods }

    { static Property }
  end;

  [JavaSignature('com/tencent/mm/sdk/openapi/IWXAPIEventHandler')]
  JIWXAPIEventHandler = interface(IJavaInstance)
    ['{AD6E0AAF-613C-45AB-8A01-E4AF652A6BF9}']
    { Property Methods }

    { methods }
    procedure onReq(P1: JBaseReq); cdecl;
    // (Lcom/tencent/mm/sdk/modelbase/BaseReq;)V
    procedure onResp(P1: JBaseResp); cdecl;
    // (Lcom/tencent/mm/sdk/modelbase/BaseResp;)V

    { Property }
  end;

  TJIWXAPIEventHandler = class(TJavaGenericImport<JIWXAPIEventHandlerClass,
    JIWXAPIEventHandler>)
  end;

  JMMSharedPreferences_REditorClass = interface(JObjectClass)
    ['{EBCCFE24-6FE1-4614-9312-D88A1AE57E23}']
    { static Property Methods }

    { static Methods }
    { class } function init(P1: JContentResolver): JMMSharedPreferences_REditor;
      cdecl; // (Landroid/content/ContentResolver;)V

    { static Property }
  end;

  [JavaSignature('com/tencent/mm/sdk/openapi/MMSharedPreferences$REditor')]
  JMMSharedPreferences_REditor = interface(JObject)
    ['{55BFCDA9-503C-45AC-9A81-B2916D2A628B}']
    { Property Methods }

    { methods }
    function putString(P1: JString; P2: JString): JSharedPreferences_Editor;
      cdecl; // (Ljava/lang/String;Ljava/lang/String;)Landroid/content/SharedPreferences$Editor;
    function putInt(P1: JString; P2: Integer): JSharedPreferences_Editor; cdecl;
    // (Ljava/lang/String;I)Landroid/content/SharedPreferences$Editor;
    function putLong(P1: JString; P2: Int64): JSharedPreferences_Editor; cdecl;
    // (Ljava/lang/String;J)Landroid/content/SharedPreferences$Editor;
    function putFloat(P1: JString; P2: Single): JSharedPreferences_Editor;
      cdecl; // (Ljava/lang/String;F)Landroid/content/SharedPreferences$Editor;
    function putBoolean(P1: JString; P2: Boolean): JSharedPreferences_Editor;
      cdecl; // (Ljava/lang/String;Z)Landroid/content/SharedPreferences$Editor;
    function remove(P1: JString): JSharedPreferences_Editor; cdecl;
    // (Ljava/lang/String;)Landroid/content/SharedPreferences$Editor;
    function clear: JSharedPreferences_Editor; cdecl;
    // ()Landroid/content/SharedPreferences$Editor;
    function commit: Boolean; cdecl; // ()Z
    procedure apply; cdecl; // ()V
    function putStringSet(P1: JString; P2: JSet): JSharedPreferences_Editor;
      cdecl; // (Ljava/lang/String;Ljava/util/Set;)Landroid/content/SharedPreferences$Editor;

    { Property }
  end;

  TJMMSharedPreferences_REditor = class
    (TJavaGenericImport<JMMSharedPreferences_REditorClass,
    JMMSharedPreferences_REditor>)
  end;

  JMMSharedPreferencesClass = interface(JObjectClass)
    ['{237D4756-BDB0-4EBB-A358-531862F7CFDC}']
    { static Property Methods }

    { static Methods }
    { class } function init(P1: JContext): JMMSharedPreferences; cdecl;
    // (Landroid/content/Context;)V

    { static Property }
  end;

  [JavaSignature('com/tencent/mm/sdk/openapi/MMSharedPreferences')]
  JMMSharedPreferences = interface(JObject)
    ['{C078D0C4-0516-4774-ADA8-AB1C7AA76D0B}']
    { Property Methods }

    { methods }
    function getAll: JMap; cdecl; // ()Ljava/util/Map;
    function getString(P1: JString; P2: JString): JString; cdecl;
    // (Ljava/lang/String;Ljava/lang/String;)Ljava/lang/String;
    function getInt(P1: JString; P2: Integer): Integer; cdecl;
    // (Ljava/lang/String;I)I
    function getLong(P1: JString; P2: Int64): Int64; cdecl;
    // (Ljava/lang/String;J)J
    function getFloat(P1: JString; P2: Single): Single; cdecl;
    // (Ljava/lang/String;F)F
    function getBoolean(P1: JString; P2: Boolean): Boolean; cdecl;
    // (Ljava/lang/String;Z)Z
    function contains(P1: JString): Boolean; cdecl; // (Ljava/lang/String;)Z
    function edit: JSharedPreferences_Editor; cdecl;
    // ()Landroid/content/SharedPreferences$Editor;
    procedure registerOnSharedPreferenceChangeListener
      (P1: JSharedPreferences_OnSharedPreferenceChangeListener); cdecl;
    // (Landroid/content/SharedPreferences$OnSharedPreferenceChangeListener;)V
    procedure unregisterOnSharedPreferenceChangeListener
      (P1: JSharedPreferences_OnSharedPreferenceChangeListener); cdecl;
    // (Landroid/content/SharedPreferences$OnSharedPreferenceChangeListener;)V
    function getStringSet(P1: JString; P2: JSet): JSet; cdecl;
    // (Ljava/lang/String;Ljava/util/Set;)Ljava/util/Set;

    { Property }
  end;

  TJMMSharedPreferences = class(TJavaGenericImport<JMMSharedPreferencesClass,
    JMMSharedPreferences>)
  end;

  JWXAPIFactoryClass = interface(JObjectClass)
    ['{2AD143DE-1795-410E-B4E9-DA47B88E91CC}']
    { static Property Methods }

    { static Methods }
    { class } function createWXAPI(P1: JContext; P2: JString): JIWXAPI; cdecl;
      overload; // (Landroid/content/Context;Ljava/lang/String;)Lcom/tencent/mm/sdk/openapi/IWXAPI;
    { class } function createWXAPI(P1: JContext; P2: JString; P3: Boolean)
      : JIWXAPI; cdecl; overload;
    // (Landroid/content/Context;Ljava/lang/String;Z)Lcom/tencent/mm/sdk/openapi/IWXAPI;

    { static Property }
  end;

  [JavaSignature('com/tencent/mm/sdk/openapi/WXAPIFactory')]
  JWXAPIFactory = interface(JObject)
    ['{5A586FA6-4EA1-484D-9FAC-1DE175C67437}']
    { Property Methods }

    { methods }

    { Property }
  end;

  TJWXAPIFactory = class(TJavaGenericImport<JWXAPIFactoryClass, JWXAPIFactory>)
  end;

  JWXApiImplCommClass = interface(JObjectClass)
    ['{74BDBF6D-85EF-4D02-B1A9-58227B4462E5}']
    { static Property Methods }

    { static Methods }
    { class } function isIntentFromWx(P1: JIntent; P2: JString): Boolean; cdecl;
    // (Landroid/content/Intent;Ljava/lang/String;)Z
    { class } function validateAppSignatureForPackage(P1: JContext; P2: JString;
      P3: Boolean): Boolean; cdecl;
    // (Landroid/content/Context;Ljava/lang/String;Z)Z
    { class } function validateAppSignature(P1: JContext;
      P2: TJavaObjectArray<JSignature>; P3: Boolean): Boolean; cdecl;
    // (Landroid/content/Context;[Landroid/content/pm/Signature;Z)Z

    { static Property }
  end;

  [JavaSignature('com/tencent/mm/sdk/openapi/WXApiImplComm')]
  JWXApiImplComm = interface(JObject)
    ['{BDCE560A-1219-42BB-B7F2-71A69B8F7BFB}']
    { Property Methods }

    { methods }

    { Property }
  end;

  TJWXApiImplComm = class(TJavaGenericImport<JWXApiImplCommClass,
    JWXApiImplComm>)
  end;

  JWXApiImplV10_1Class = interface(JObjectClass)
    ['{6F408BF9-E945-4349-BF1F-0328B0513743}']
    { static Property Methods }

    { static Methods }

    { static Property }
  end;

  [JavaSignature('com/tencent/mm/sdk/openapi/WXApiImplV10$1')]
  JWXApiImplV10_1 = interface(JObject)
    ['{402C34BC-0B91-4E5E-90E5-728AF21E5702}']
    { Property Methods }

    { methods }

    { Property }
  end;

  TJWXApiImplV10_1 = class(TJavaGenericImport<JWXApiImplV10_1Class,
    JWXApiImplV10_1>)
  end;

  JWXApiImplV10_ActivityLifecycleCb_1Class = interface(JObjectClass)
    ['{50E2A629-4529-47EF-842F-CD6BB3D8B1E5}']
    { static Property Methods }

    { static Methods }

    { static Property }
  end;

  [JavaSignature
    ('com/tencent/mm/sdk/openapi/WXApiImplV10$ActivityLifecycleCb$1')]
  JWXApiImplV10_ActivityLifecycleCb_1 = interface(JObject)
    ['{A656B961-A5CD-4916-8BF6-81B8AC019626}']
    { Property Methods }

    { methods }
    procedure run; cdecl; // ()V

    { Property }
  end;

  TJWXApiImplV10_ActivityLifecycleCb_1 = class
    (TJavaGenericImport<JWXApiImplV10_ActivityLifecycleCb_1Class,
    JWXApiImplV10_ActivityLifecycleCb_1>)
  end;

  JWXApiImplV10_ActivityLifecycleCb_2Class = interface(JObjectClass)
    ['{249C10CE-4D3E-4B1D-A8FB-B3015F85F182}']
    { static Property Methods }

    { static Methods }

    { static Property }
  end;

  [JavaSignature
    ('com/tencent/mm/sdk/openapi/WXApiImplV10$ActivityLifecycleCb$2')]
  JWXApiImplV10_ActivityLifecycleCb_2 = interface(JObject)
    ['{E5A9AB0E-ECC5-476B-9B53-6EFF7009540A}']
    { Property Methods }

    { methods }
    procedure run; cdecl; // ()V

    { Property }
  end;

  TJWXApiImplV10_ActivityLifecycleCb_2 = class
    (TJavaGenericImport<JWXApiImplV10_ActivityLifecycleCb_2Class,
    JWXApiImplV10_ActivityLifecycleCb_2>)
  end;

  JWXApiImplV10_ActivityLifecycleCbClass = interface(JObjectClass)
    ['{0011DD04-298C-44C0-8E76-928B44ACCBA0}']
    { static Property Methods }

    { static Methods }

    { static Property }
  end;

  [JavaSignature('com/tencent/mm/sdk/openapi/WXApiImplV10$ActivityLifecycleCb')]
  JWXApiImplV10_ActivityLifecycleCb = interface(JObject)
    ['{53F76941-7D18-45D4-8888-E449806EBD3A}']
    { Property Methods }

    { methods }
    procedure onActivityCreated(P1: JActivity; P2: JBundle); cdecl;
    // (Landroid/app/Activity;Landroid/os/Bundle;)V
    procedure onActivityDestroyed(P1: JActivity); cdecl;
    // (Landroid/app/Activity;)V
    procedure onActivityPaused(P1: JActivity); cdecl;
    // (Landroid/app/Activity;)V
    procedure onActivityResumed(P1: JActivity); cdecl;
    // (Landroid/app/Activity;)V
    procedure onActivitySaveInstanceState(P1: JActivity; P2: JBundle); cdecl;
    // (Landroid/app/Activity;Landroid/os/Bundle;)V
    procedure onActivityStarted(P1: JActivity); cdecl;
    // (Landroid/app/Activity;)V
    procedure onActivityStopped(P1: JActivity); cdecl;
    // (Landroid/app/Activity;)V
    procedure detach; cdecl; // ()V

    { Property }
  end;

  TJWXApiImplV10_ActivityLifecycleCb = class
    (TJavaGenericImport<JWXApiImplV10_ActivityLifecycleCbClass,
    JWXApiImplV10_ActivityLifecycleCb>)
  end;

  JWXApiImplV10Class = interface(JObjectClass)
    ['{F35BFE38-E34E-4180-AEDA-5150F78011C1}']
    { static Property Methods }

    { static Methods }

    { static Property }
  end;

  [JavaSignature('com/tencent/mm/sdk/openapi/WXApiImplV10')]
  JWXApiImplV10 = interface(JObject)
    ['{B2191B42-9A95-4933-8A48-00DD900072A0}']
    { Property Methods }

    { methods }
    function registerApp(P1: JString): Boolean; cdecl; // (Ljava/lang/String;)Z
    procedure unregisterApp; cdecl; // ()V
    function handleIntent(P1: JIntent; P2: JIWXAPIEventHandler): Boolean; cdecl;
    // (Landroid/content/Intent;Lcom/tencent/mm/sdk/openapi/IWXAPIEventHandler;)Z
    function isWXAppInstalled: Boolean; cdecl; // ()Z
    function isWXAppSupportAPI: Boolean; cdecl; // ()Z
    function getWXAppSupportAPI: Integer; cdecl; // ()I
    function openWXApp: Boolean; cdecl; // ()Z
    function sendReq(P1: JBaseReq): Boolean; cdecl;
    // (Lcom/tencent/mm/sdk/modelbase/BaseReq;)Z
    function sendResp(P1: JBaseResp): Boolean; cdecl;
    // (Lcom/tencent/mm/sdk/modelbase/BaseResp;)Z
    procedure detach; cdecl; // ()V

    { Property }
  end;

  TJWXApiImplV10 = class(TJavaGenericImport<JWXApiImplV10Class, JWXApiImplV10>)
  end;

  JStatConstantsClass = interface(JObjectClass)
    ['{C7F5BC66-5514-420E-834B-9514293F82A2}']
    { static Property Methods }
    { class } function _GetVERSION: JString; // Ljava/lang/String;
    { class } function _GetMTA_SERVER_HOST: JString; // Ljava/lang/String;
    { class } function _GetMTA_SERVER_PORT: Integer; // I
    { class } function _GetMTA_SERVER: JString; // Ljava/lang/String;
    { class } function _GetMTA_STAT_URL: JString; // Ljava/lang/String;
    { class } function _GetMTA_REPORT_FULL_URL: JString; // Ljava/lang/String;
    { class } function _GetMTA_COOPERATION_TAG: JString; // Ljava/lang/String;
    { class } function _GetMTA_STORAGE_PRE_TAG: JString; // Ljava/lang/String;
    { class } function _GetSTAT_DB_VERSION: Integer; // I
    { class } function _GetSDK_ONLINE_CONFIG_TYPE: Integer; // I
    { class } function _GetUSER_ONLINE_CONFIG_TYPE: Integer; // I
    { class } function _GetDATABASE_NAME: JString; // Ljava/lang/String;
    { class } function _GetLOG_TAG: JString; // Ljava/lang/String;
    { class } function _GetXG_PRO_VERSION: Integer; // I

    { static Methods }
    { class } function init: JStatConstants; cdecl; // ()V

    { static Property }
    { class } property VERSION: JString read _GetVERSION;
    { class } property MTA_SERVER_HOST: JString read _GetMTA_SERVER_HOST;
    { class } property MTA_SERVER_PORT: Integer read _GetMTA_SERVER_PORT;
    { class } property MTA_SERVER: JString read _GetMTA_SERVER;
    { class } property MTA_STAT_URL: JString read _GetMTA_STAT_URL;
    { class } property MTA_REPORT_FULL_URL: JString
      read _GetMTA_REPORT_FULL_URL;
    { class } property MTA_COOPERATION_TAG: JString
      read _GetMTA_COOPERATION_TAG;
    { class } property MTA_STORAGE_PRE_TAG: JString
      read _GetMTA_STORAGE_PRE_TAG;
    { class } property STAT_DB_VERSION: Integer read _GetSTAT_DB_VERSION;
    { class } property SDK_ONLINE_CONFIG_TYPE: Integer
      read _GetSDK_ONLINE_CONFIG_TYPE;
    { class } property USER_ONLINE_CONFIG_TYPE: Integer
      read _GetUSER_ONLINE_CONFIG_TYPE;
    { class } property DATABASE_NAME: JString read _GetDATABASE_NAME;
    { class } property LOG_TAG: JString read _GetLOG_TAG;
    { class } property XG_PRO_VERSION: Integer read _GetXG_PRO_VERSION;
  end;

  [JavaSignature('com/tencent/wxop/stat/common/StatConstants')]
  JStatConstants = interface(JObject)
    ['{447BDA08-E3B5-429E-8EBE-1F60E51AE211}']
    { Property Methods }

    { methods }

    { Property }
  end;

  TJStatConstants = class(TJavaGenericImport<JStatConstantsClass,
    JStatConstants>)
  end;

  JStatLoggerClass = interface(JObjectClass)
    ['{CC381C72-0708-45B7-8524-A8C9FFDD1810}']
    { static Property Methods }

    { static Methods }
    { class } function init: JStatLogger; cdecl; overload; // ()V
    { class } function init(P1: JString): JStatLogger; cdecl; overload;
    // (Ljava/lang/String;)V

    { static Property }
  end;

  [JavaSignature('com/tencent/wxop/stat/common/StatLogger')]
  JStatLogger = interface(JObject)
    ['{C343955E-CDEB-42D7-9E20-22F938B51665}']
    { Property Methods }

    { methods }
    function isDebugEnable: Boolean; cdecl; // ()Z
    procedure setDebugEnable(P1: Boolean); cdecl; // (Z)V
    function getLogLevel: Integer; cdecl; // ()I
    procedure setLogLevel(P1: Integer); cdecl; // (I)V
    procedure setTag(P1: JString); cdecl; // (Ljava/lang/String;)V
    procedure info(P1: JObject); cdecl; // (Ljava/lang/Object;)V
    procedure i(P1: JObject); cdecl; // (Ljava/lang/Object;)V
    procedure verbose(P1: JObject); cdecl; // (Ljava/lang/Object;)V
    procedure v(P1: JObject); cdecl; // (Ljava/lang/Object;)V
    procedure warn(P1: JObject); cdecl; // (Ljava/lang/Object;)V
    procedure w(P1: JObject); cdecl; // (Ljava/lang/Object;)V
    procedure error(P1: JObject); cdecl; overload; // (Ljava/lang/Object;)V
    procedure error(P1: JThrowable); cdecl; overload;
    // (Ljava/lang/Throwable;)V
    procedure e(P1: JObject); cdecl; overload; // (Ljava/lang/Object;)V
    procedure e(P1: JThrowable); cdecl; overload; // (Ljava/lang/Throwable;)V
    procedure debug(P1: JObject); cdecl; // (Ljava/lang/Object;)V
    procedure d(P1: JObject); cdecl; // (Ljava/lang/Object;)V

    { Property }
  end;

  TJStatLogger = class(TJavaGenericImport<JStatLoggerClass, JStatLogger>)
  end;

  JEasyActivityClass = interface(JActivityClass)
    // or JObjectClass // SuperSignature: android/app/Activity
    ['{18EFAC2D-D43F-4B57-A28D-B2210860C22F}']
    { static Property Methods }

    { static Methods }
    { class } function init: JEasyActivity; cdecl; // ()V

    { static Property }
  end;

  [JavaSignature('com/tencent/wxop/stat/EasyActivity')]
  JEasyActivity = interface(JActivity)
    // or JObject // SuperSignature: android/app/Activity
    ['{6D31DCF6-C0AD-44B6-8ECA-53BFC8E238A6}']
    { Property Methods }

    { methods }

    { Property }
  end;

  TJEasyActivity = class(TJavaGenericImport<JEasyActivityClass, JEasyActivity>)
  end;

  JMtaSDkExceptionClass = interface(JExceptionClass)
    // or JObjectClass // SuperSignature: java/lang/Exception
    ['{F8EF746B-CDAF-466F-944F-D70919A40570}']
    { static Property Methods }

    { static Methods }
    { class } function init: JMtaSDkException; cdecl; overload; // ()V
    { class } function init(P1: JString): JMtaSDkException; cdecl; overload;
    // (Ljava/lang/String;)V
    { class } function init(P1: JString; P2: JThrowable): JMtaSDkException;
      cdecl; overload; // (Ljava/lang/String;Ljava/lang/Throwable;)V
    { class } function init(P1: JThrowable): JMtaSDkException; cdecl; overload;
    // (Ljava/lang/Throwable;)V

    { static Property }
  end;

  [JavaSignature('com/tencent/wxop/stat/MtaSDkException')]
  JMtaSDkException = interface(JException)
    // or JObject // SuperSignature: java/lang/Exception
    ['{B27E2D4A-10EA-4D59-966D-9070FC9AF1F8}']
    { Property Methods }

    { methods }

    { Property }
  end;

  TJMtaSDkException = class(TJavaGenericImport<JMtaSDkExceptionClass,
    JMtaSDkException>)
  end;

  JNetworkMonitorClass = interface(JObjectClass)
    ['{821AFF0F-D86E-4B0A-A634-93B5A7FB9995}']
    { static Property Methods }

    { static Methods }
    { class } function init: JNetworkMonitor; cdecl; // ()V

    { static Property }
  end;

  [JavaSignature('com/tencent/wxop/stat/NetworkMonitor')]
  JNetworkMonitor = interface(JObject)
    ['{71141182-324E-4A72-B171-A28592E62D57}']
    { Property Methods }

    { methods }
    function getMillisecondsConsume: Int64; cdecl; // ()J
    procedure setMillisecondsConsume(P1: Int64); cdecl; // (J)V
    function getStatusCode: Integer; cdecl; // ()I
    procedure setStatusCode(P1: Integer); cdecl; // (I)V
    function getDomain: JString; cdecl; // ()Ljava/lang/String;
    procedure setDomain(P1: JString); cdecl; // (Ljava/lang/String;)V
    function getPort: Integer; cdecl; // ()I
    procedure setPort(P1: Integer); cdecl; // (I)V
    function getRemoteIp: JString; cdecl; // ()Ljava/lang/String;
    procedure setRemoteIp(P1: JString); cdecl; // (Ljava/lang/String;)V
    function toJSONObject: JJSONObject; cdecl; // ()Lorg/json/JSONObject;

    { Property }
  end;

  TJNetworkMonitor = class(TJavaGenericImport<JNetworkMonitorClass,
    JNetworkMonitor>)
  end;

  JStatAccountClass = interface(JObjectClass)
    ['{0F249111-CFDE-4E18-9D90-C39B733470E3}']
    { static Property Methods }
    { class } function _GetDEFAULT_TYPE: Integer; // I
    { class } function _GetQQ_NUM_TYPE: Integer; // I
    { class } function _GetWECHAT_ID_TYPE: Integer; // I
    { class } function _GetQQ_OPENID_TYPE: Integer; // I
    { class } function _GetWECHAT_OPENID_TYPE: Integer; // I
    { class } function _GetPHONE_NUM_TYPE: Integer; // I
    { class } function _GetEMAIL_TYPE: Integer; // I
    { class } function _GetCUSTOM_TYPE: Integer; // I

    { static Methods }
    { class } function init(P1: JString): JStatAccount; cdecl; overload;
    // (Ljava/lang/String;)V
    { class } function init(P1: JString; P2: Integer): JStatAccount; cdecl;
      overload; // (Ljava/lang/String;I)V

    { static Property }
    { class } property DEFAULT_TYPE: Integer read _GetDEFAULT_TYPE;
    { class } property QQ_NUM_TYPE: Integer read _GetQQ_NUM_TYPE;
    { class } property WECHAT_ID_TYPE: Integer read _GetWECHAT_ID_TYPE;
    { class } property QQ_OPENID_TYPE: Integer read _GetQQ_OPENID_TYPE;
    { class } property WECHAT_OPENID_TYPE: Integer read _GetWECHAT_OPENID_TYPE;
    { class } property PHONE_NUM_TYPE: Integer read _GetPHONE_NUM_TYPE;
    { class } property EMAIL_TYPE: Integer read _GetEMAIL_TYPE;
    { class } property CUSTOM_TYPE: Integer read _GetCUSTOM_TYPE;
  end;

  [JavaSignature('com/tencent/wxop/stat/StatAccount')]
  JStatAccount = interface(JObject)
    ['{4CC042DF-ED03-4162-BE50-EC1456E84666}']
    { Property Methods }

    { methods }
    function toString: JString; cdecl; // ()Ljava/lang/String;
    function toJsonString: JString; cdecl; // ()Ljava/lang/String;
    function getAccount: JString; cdecl; // ()Ljava/lang/String;
    procedure setAccount(P1: JString); cdecl; // (Ljava/lang/String;)V
    function getAccountType: Integer; cdecl; // ()I
    procedure setAccountType(P1: Integer); cdecl; // (I)V
    function getExt: JString; cdecl; // ()Ljava/lang/String;
    procedure setExt(P1: JString); cdecl; // (Ljava/lang/String;)V
    function getExt1: JString; cdecl; // ()Ljava/lang/String;
    procedure setExt1(P1: JString); cdecl; // (Ljava/lang/String;)V

    { Property }
  end;

  TJStatAccount = class(TJavaGenericImport<JStatAccountClass, JStatAccount>)
  end;

  JStatAppMonitorClass = interface(JObjectClass)
    ['{0EEC2E68-05F9-4317-81C6-065ACDC7E25C}']
    { static Property Methods }
    { class } function _GetSUCCESS_RESULT_TYPE: Integer; // I
    { class } function _GetFAILURE_RESULT_TYPE: Integer; // I
    { class } function _GetLOGIC_FAILURE_RESULT_TYPE: Integer; // I

    { static Methods }
    { class } function init(P1: JString): JStatAppMonitor; cdecl; overload;
    // (Ljava/lang/String;)V
    { class } function init(P1: JString; P2: Integer; P3: Integer; P4: Int64;
      P5: Int64; P6: Int64; P7: Integer): JStatAppMonitor; cdecl; overload;
    // (Ljava/lang/String;IIJJJI)V

    { static Property }
    { class } property SUCCESS_RESULT_TYPE: Integer
      read _GetSUCCESS_RESULT_TYPE;
    { class } property FAILURE_RESULT_TYPE: Integer
      read _GetFAILURE_RESULT_TYPE;
    { class } property LOGIC_FAILURE_RESULT_TYPE: Integer
      read _GetLOGIC_FAILURE_RESULT_TYPE;
  end;

  [JavaSignature('com/tencent/wxop/stat/StatAppMonitor')]
  JStatAppMonitor = interface(JObject)
    ['{E29D368A-1DC3-4C57-B589-18EF4D38334F}']
    { Property Methods }

    { methods }
    function getInterfaceName: JString; cdecl; // ()Ljava/lang/String;
    procedure setInterfaceName(P1: JString); cdecl; // (Ljava/lang/String;)V
    function getReqSize: Int64; cdecl; // ()J
    procedure setReqSize(P1: Int64); cdecl; // (J)V
    function getRespSize: Int64; cdecl; // ()J
    procedure setRespSize(P1: Int64); cdecl; // (J)V
    function getResultType: Integer; cdecl; // ()I
    procedure setResultType(P1: Integer); cdecl; // (I)V
    function getMillisecondsConsume: Int64; cdecl; // ()J
    procedure setMillisecondsConsume(P1: Int64); cdecl; // (J)V
    function getReturnCode: Integer; cdecl; // ()I
    procedure setReturnCode(P1: Integer); cdecl; // (I)V
    function getSampling: Integer; cdecl; // ()I
    procedure setSampling(P1: Integer); cdecl; // (I)V
    function clone: JStatAppMonitor; cdecl; overload;
    // ()Lcom/tencent/wxop/stat/StatAppMonitor;
    // function clone: JObject; cdecl; overload; // ()Ljava/lang/Object;

    { Property }
  end;

  TJStatAppMonitor = class(TJavaGenericImport<JStatAppMonitorClass,
    JStatAppMonitor>)
  end;

  JStatConfigClass = interface(JObjectClass)
    ['{ADDC563A-8543-47BE-B2C7-859E23B2DA3E}']
    { static Property Methods }
    { class } function _GetisAutoExceptionCaught: Boolean; // Z

    { static Methods }
    { class } function init: JStatConfig; cdecl; // ()V
    { class } function getStatSendStrategy: JStatReportStrategy; cdecl;
    // ()Lcom/tencent/wxop/stat/StatReportStrategy;
    { class } procedure setStatSendStrategy(P1: JStatReportStrategy); cdecl;
    // (Lcom/tencent/wxop/stat/StatReportStrategy;)V
    { class } function isDebugEnable: Boolean; cdecl; // ()Z
    { class } procedure setDebugEnable(P1: Boolean); cdecl; // (Z)V
    { class } function isEnableStatService: Boolean; cdecl; // ()Z
    { class } procedure setEnableStatService(P1: Boolean); cdecl; // (Z)V
    { class } function getSessionTimoutMillis: Integer; cdecl; // ()I
    { class } procedure setSessionTimoutMillis(P1: Integer); cdecl; // (I)V
    { class } function getMaxImportantDataSendRetryCount: Integer; cdecl; // ()I
    { class } procedure setMaxImportantDataSendRetryCount(P1: Integer); cdecl;
    // (I)V
    { class } function getMaxBatchReportCount: Integer; cdecl; // ()I
    { class } procedure setMaxBatchReportCount(P1: Integer); cdecl; // (I)V
    { class } procedure setMaxSendRetryCount(P1: Integer); cdecl; // (I)V
    { class } function getMaxSendRetryCount: Integer; cdecl; // ()I
    { class } function getNumEventsCommitPerSec: Integer; cdecl; // ()I
    { class } procedure setNumEventsCommitPerSec(P1: Integer); cdecl; // (I)V
    { class } function getMaxStoreEventCount: Integer; cdecl; // ()I
    { class } procedure setMaxStoreEventCount(P1: Integer); cdecl; // (I)V
    { class } function getCustomProperty(P1: JString): JString; cdecl; overload;
    // (Ljava/lang/String;)Ljava/lang/String;
    { class } function getCustomProperty(P1: JString; P2: JString): JString;
      cdecl; overload;
    // (Ljava/lang/String;Ljava/lang/String;)Ljava/lang/String;
    { class } function getAppKey(P1: JContext): JString; cdecl;
    // (Landroid/content/Context;)Ljava/lang/String;
    { class } procedure setAppKey(P1: JContext; P2: JString); cdecl; overload;
    // (Landroid/content/Context;Ljava/lang/String;)V
    { class } procedure setAppKey(P1: JString); cdecl; overload;
    // (Ljava/lang/String;)V
    { class } function getInstallChannel(P1: JContext): JString; cdecl;
    // (Landroid/content/Context;)Ljava/lang/String;
    { class } procedure setInstallChannel(P1: JString); cdecl; overload;
    // (Ljava/lang/String;)V
    { class } procedure setInstallChannel(P1: JContext; P2: JString); cdecl;
      overload; // (Landroid/content/Context;Ljava/lang/String;)V
    { class } function getQQ(P1: JContext): JString; cdecl;
    // (Landroid/content/Context;)Ljava/lang/String;
    { class } procedure setQQ(P1: JContext; P2: JString); cdecl;
    // (Landroid/content/Context;Ljava/lang/String;)V
    { class } procedure setSendPeriodMinutes(P1: Integer); cdecl; // (I)V
    { class } function getNumOfMethodsCalledLimit: Integer; cdecl; // ()I
    { class } procedure setNumOfMethodsCalledLimit(P1: Integer; P2: Int64);
      cdecl; // (IJ)V
    { class } function getMsPeriodForMethodsCalledLimitClear: Int64; cdecl;
    // ()J
    { class } function getSendPeriodMinutes: Integer; cdecl; // ()I
    { class } function getMaxParallelTimmingEvents: Integer; cdecl; // ()I
    { class } procedure setMaxParallelTimmingEvents(P1: Integer); cdecl; // (I)V
    { class } function isEnableSmartReporting: Boolean; cdecl; // ()Z
    { class } procedure setEnableSmartReporting(P1: Boolean); cdecl; // (Z)V
    { class } function isAutoExceptionCaught: Boolean; cdecl; // ()Z
    { class } procedure setAutoExceptionCaught(P1: Boolean); cdecl; // (Z)V
    { class } function getStatReportUrl: JString; cdecl; // ()Ljava/lang/String;
    { class } procedure setStatReportUrl(P1: JString); cdecl;
    // (Ljava/lang/String;)V
    { class } function getStatReportHost: JString; cdecl;
    // ()Ljava/lang/String;
    { class } function getMaxSessionStatReportCount: Integer; cdecl; // ()I
    { class } procedure setMaxSessionStatReportCount(P1: Integer); cdecl;
    // (I)V
    { class } function getCurSessionStatReportCount: Integer; cdecl; // ()I
    { class } function getMaxDaySessionNumbers: Integer; cdecl; // ()I
    { class } procedure setMaxDaySessionNumbers(P1: Integer); cdecl; // (I)V
    { class } function getMaxReportEventLength: Integer; cdecl; // ()I
    { class } procedure setMaxReportEventLength(P1: Integer); cdecl; // (I)V
    { class } function isEnableConcurrentProcess: Boolean; cdecl; // ()Z
    { class } procedure setEnableConcurrentProcess(P1: Boolean); cdecl; // (Z)V
    { class } function getCustomUserId(P1: JContext): JString; cdecl;
    // (Landroid/content/Context;)Ljava/lang/String;
    { class } procedure setCustomUserId(P1: JContext; P2: JString); cdecl;
    // (Landroid/content/Context;Ljava/lang/String;)V
    { class } function getMid(P1: JContext): JString; cdecl;
    // (Landroid/content/Context;)Ljava/lang/String;
    { class } function getLocalMidOnly(P1: JContext): JString; cdecl;
    // (Landroid/content/Context;)Ljava/lang/String;
    { class } procedure setXGProMode(P1: Boolean); cdecl; // (Z)V
    { class } function isXGProMode: Boolean; cdecl; // ()Z
    // { class } function getCustomLogger: Jg; cdecl;
    // ()Lcom/tencent/wxop/stat/g;
    // { class } procedure setCustomLogger(P1: Jg); cdecl;
    // (Lcom/tencent/wxop/stat/g;)V
    { class } function isReportEventsByOrder: Boolean; cdecl; // ()Z
    { class } procedure setReportEventsByOrder(P1: Boolean); cdecl; // (Z)V
    { class } function getNumEventsCachedInMemory: Integer; cdecl; // ()I
    { class } procedure setNumEventsCachedInMemory(P1: Integer); cdecl; // (I)V
    { class } function getFlushDBSpaceMS: Int64; cdecl; // ()J
    { class } procedure setFlushDBSpaceMS(P1: Int64); cdecl; // (J)V
    { class } function getReportCompressedSize: Integer; cdecl; // ()I
    { class } procedure setReportCompressedSize(P1: Integer); cdecl; // (I)V

    { static Property }
    { class } property isAutoExceptionCaught: Boolean
      read _GetisAutoExceptionCaught;
  end;

  [JavaSignature('com/tencent/wxop/stat/StatConfig')]
  JStatConfig = interface(JObject)
    ['{3A9BF9B3-300B-4111-9B7B-7D8AE9813106}']
    { Property Methods }

    { methods }

    { Property }
  end;

  TJStatConfig = class(TJavaGenericImport<JStatConfigClass, JStatConfig>)
  end;

  JStatGameUserClass = interface(JObjectClass)
    ['{CB744331-EDF7-43AE-A049-9EE15B33C53A}']
    { static Property Methods }

    { static Methods }
    { class } function init(P1: JString; P2: JString; P3: JString)
      : JStatGameUser; cdecl; overload;
    // (Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V
    { class } function init: JStatGameUser; cdecl; overload; // ()V

    { static Property }
  end;

  [JavaSignature('com/tencent/wxop/stat/StatGameUser')]
  JStatGameUser = interface(JObject)
    ['{BDCBECA7-3523-4382-B2F2-F5A1AAF4CD49}']
    { Property Methods }

    { methods }
    function toString: JString; cdecl; // ()Ljava/lang/String;
    function getWorldName: JString; cdecl; // ()Ljava/lang/String;
    procedure setWorldName(P1: JString); cdecl; // (Ljava/lang/String;)V
    function getAccount: JString; cdecl; // ()Ljava/lang/String;
    procedure setAccount(P1: JString); cdecl; // (Ljava/lang/String;)V
    function getLevel: JString; cdecl; // ()Ljava/lang/String;
    procedure setLevel(P1: JString); cdecl; // (Ljava/lang/String;)V
    function clone: JStatGameUser; cdecl; overload;
    // ()Lcom/tencent/wxop/stat/StatGameUser;
    // function clone: JObject; cdecl; overload; // ()Ljava/lang/Object;

    { Property }
  end;

  TJStatGameUser = class(TJavaGenericImport<JStatGameUserClass, JStatGameUser>)
  end;

  JStatReportStrategyClass = interface(JEnumClass)
    // or JObjectClass // SuperSignature: java/lang/Enum
    ['{38F967B0-0F46-4368-AC71-27A4D640575B}']
    { static Property Methods }
    { class } function _GetINSTANT: JStatReportStrategy;
    // Lcom/tencent/wxop/stat/StatReportStrategy;
    { class } function _GetONLY_WIFI: JStatReportStrategy;
    // Lcom/tencent/wxop/stat/StatReportStrategy;
    { class } function _GetBATCH: JStatReportStrategy;
    // Lcom/tencent/wxop/stat/StatReportStrategy;
    { class } function _GetAPP_LAUNCH: JStatReportStrategy;
    // Lcom/tencent/wxop/stat/StatReportStrategy;
    { class } function _GetDEVELOPER: JStatReportStrategy;
    // Lcom/tencent/wxop/stat/StatReportStrategy;
    { class } function _GetPERIOD: JStatReportStrategy;
    // Lcom/tencent/wxop/stat/StatReportStrategy;
    { class } function _GetONLY_WIFI_NO_CACHE: JStatReportStrategy;
    // Lcom/tencent/wxop/stat/StatReportStrategy;

    { static Methods }
    { class } function values: TJavaObjectArray<JStatReportStrategy>; cdecl;
    // ()[Lcom/tencent/wxop/stat/StatReportStrategy;
    { class } function valueOf(P1: JString): JStatReportStrategy; cdecl;
    // (Ljava/lang/String;)Lcom/tencent/wxop/stat/StatReportStrategy;
    { class } function getStatReportStrategy(P1: Integer): JStatReportStrategy;
      cdecl; // (I)Lcom/tencent/wxop/stat/StatReportStrategy;

    { static Property }
    { class } property INSTANT: JStatReportStrategy read _GetINSTANT;
    { class } property ONLY_WIFI: JStatReportStrategy read _GetONLY_WIFI;
    { class } property BATCH: JStatReportStrategy read _GetBATCH;
    { class } property APP_LAUNCH: JStatReportStrategy read _GetAPP_LAUNCH;
    { class } property DEVELOPER: JStatReportStrategy read _GetDEVELOPER;
    { class } property PERIOD: JStatReportStrategy read _GetPERIOD;
    { class } property ONLY_WIFI_NO_CACHE: JStatReportStrategy
      read _GetONLY_WIFI_NO_CACHE;
  end;

  [JavaSignature('com/tencent/wxop/stat/StatReportStrategy')]
  JStatReportStrategy = interface(JEnum)
    // or JObject // SuperSignature: java/lang/Enum
    ['{DA9073A8-459F-4C01-AAB5-B567BD54647C}']
    { Property Methods }

    { methods }
    function a: Integer; cdecl; // ()I

    { Property }
  end;

  TJStatReportStrategy = class(TJavaGenericImport<JStatReportStrategyClass,
    JStatReportStrategy>)
  end;

  JStatServiceClass = interface(JObjectClass)
    ['{ADB8983B-A250-4F26-97B0-4667344C3922}']
    { static Property Methods }

    { static Methods }
    { class } function init: JStatService; cdecl; // ()V
    { class } procedure trackBeginPage(P1: JContext; P2: JString); cdecl;
    // (Landroid/content/Context;Ljava/lang/String;)V
    { class } procedure trackEndPage(P1: JContext; P2: JString); cdecl;
    // (Landroid/content/Context;Ljava/lang/String;)V
    { class } procedure startNewSession(P1: JContext); cdecl;
    // (Landroid/content/Context;)V
    { class } procedure stopSession; cdecl; // ()V
    { class } procedure onResume(P1: JContext); cdecl;
    // (Landroid/content/Context;)V
    { class } procedure setEnvAttributes(P1: JContext; P2: JMap); cdecl;
    // (Landroid/content/Context;Ljava/util/Map;)V
    { class } procedure reportQQ(P1: JContext; P2: JString); cdecl;
    // (Landroid/content/Context;Ljava/lang/String;)V
    { class } procedure reportAccount(P1: JContext; P2: JStatAccount); cdecl;
    // (Landroid/content/Context;Lcom/tencent/wxop/stat/StatAccount;)V
    { class } procedure reportGameUser(P1: JContext; P2: JStatGameUser); cdecl;
    // (Landroid/content/Context;Lcom/tencent/wxop/stat/StatGameUser;)V
    { class } function startStatService(P1: JContext; P2: JString; P3: JString)
      : Boolean; cdecl;
    // (Landroid/content/Context;Ljava/lang/String;Ljava/lang/String;)Z
    { class } procedure onPause(P1: JContext); cdecl;
    // (Landroid/content/Context;)V
    { class } procedure reportError(P1: JContext; P2: JString); cdecl;
    // (Landroid/content/Context;Ljava/lang/String;)V
    { class } procedure reportException(P1: JContext; P2: JThrowable); cdecl;
    // (Landroid/content/Context;Ljava/lang/Throwable;)V
    { class } procedure trackCustomEvent(P1: JContext; P2: JString;
      P3: TJavaObjectArray<JString>); cdecl;
    // (Landroid/content/Context;Ljava/lang/String;[Ljava/lang/String;)V
    { class } procedure trackCustomKVEvent(P1: JContext; P2: JString;
      P3: JProperties); cdecl;
    // (Landroid/content/Context;Ljava/lang/String;Ljava/util/Properties;)V
    { class } procedure trackCustomKVTimeIntervalEvent(P1: JContext;
      P2: Integer; P3: JString; P4: JProperties); cdecl;
    // (Landroid/content/Context;ILjava/lang/String;Ljava/util/Properties;)V
    { class } procedure trackCustomBeginEvent(P1: JContext; P2: JString;
      P3: TJavaObjectArray<JString>); cdecl;
    // (Landroid/content/Context;Ljava/lang/String;[Ljava/lang/String;)V
    { class } procedure trackCustomEndEvent(P1: JContext; P2: JString;
      P3: TJavaObjectArray<JString>); cdecl;
    // (Landroid/content/Context;Ljava/lang/String;[Ljava/lang/String;)V
    { class } procedure trackCustomBeginKVEvent(P1: JContext; P2: JString;
      P3: JProperties); cdecl;
    // (Landroid/content/Context;Ljava/lang/String;Ljava/util/Properties;)V
    { class } procedure trackCustomEndKVEvent(P1: JContext; P2: JString;
      P3: JProperties); cdecl;
    // (Landroid/content/Context;Ljava/lang/String;Ljava/util/Properties;)V
    { class } procedure reportAppMonitorStat(P1: JContext; P2: JStatAppMonitor);
      cdecl; // (Landroid/content/Context;Lcom/tencent/wxop/stat/StatAppMonitor;)V
    { class } procedure commitEvents(P1: JContext; P2: Integer); cdecl;
    // (Landroid/content/Context;I)V
    { class } procedure testSpeed(P1: JContext); cdecl; overload;
    // (Landroid/content/Context;)V
    { class } procedure testSpeed(P1: JContext; P2: JMap); cdecl; overload;
    // (Landroid/content/Context;Ljava/util/Map;)V
    { class } procedure flushDataToDB(P1: JContext); cdecl;
    // (Landroid/content/Context;)V
    { class } procedure setContext(P1: JContext); cdecl;
    // (Landroid/content/Context;)V
    { class } procedure onStop(P1: JContext); cdecl;
    // (Landroid/content/Context;)V
    { class } procedure onLowMemory(P1: JContext); cdecl;
    // (Landroid/content/Context;)V
    { class } procedure setCommonKeyValueForKVEvent(P1: JString;
      P2: JProperties); cdecl; // (Ljava/lang/String;Ljava/util/Properties;)V
    { class } function getCommonKeyValueForKVEvent(P1: JString): JProperties;
      cdecl; // (Ljava/lang/String;)Ljava/util/Properties;

    { static Property }
  end;

  [JavaSignature('com/tencent/wxop/stat/StatService')]
  JStatService = interface(JObject)
    ['{131D233C-F994-4DBB-B369-E29C17169FCC}']
    { Property Methods }

    { methods }

    { Property }
  end;

  TJStatService = class(TJavaGenericImport<JStatServiceClass, JStatService>)
  end;

  JStatServiceImplClass = interface(JObjectClass)
    ['{E36025DD-24B5-4FE2-A220-1CDC8D016EAC}']
    { static Property Methods }

    { static Methods }
    { class } function init: JStatServiceImpl; cdecl; // ()V
    { class } function getContext(P1: JContext): JContext; cdecl;
    // (Landroid/content/Context;)Landroid/content/Context;
    { class } procedure setContext(P1: JContext); cdecl;
    // (Landroid/content/Context;)V
    { class } procedure trackBeginPage(P1: JContext; P2: JString;
      P3: JStatSpecifyReportedInfo); cdecl;
    // (Landroid/content/Context;Ljava/lang/String;Lcom/tencent/wxop/stat/StatSpecifyReportedInfo;)V
    { class } procedure trackEndPage(P1: JContext; P2: JString;
      P3: JStatSpecifyReportedInfo); cdecl;
    // (Landroid/content/Context;Ljava/lang/String;Lcom/tencent/wxop/stat/StatSpecifyReportedInfo;)V
    { class } procedure startNewSession(P1: JContext;
      P2: JStatSpecifyReportedInfo); cdecl;
    // (Landroid/content/Context;Lcom/tencent/wxop/stat/StatSpecifyReportedInfo;)V
    { class } procedure stopSession; cdecl; // ()V
    { class } procedure onResume(P1: JContext; P2: JStatSpecifyReportedInfo);
      cdecl; // (Landroid/content/Context;Lcom/tencent/wxop/stat/StatSpecifyReportedInfo;)V
    { class } procedure setEnvAttributes(P1: JContext; P2: JMap); cdecl;
    // (Landroid/content/Context;Ljava/util/Map;)V
    { class } procedure reportQQ(P1: JContext; P2: JString;
      P3: JStatSpecifyReportedInfo); cdecl;
    // (Landroid/content/Context;Ljava/lang/String;Lcom/tencent/wxop/stat/StatSpecifyReportedInfo;)V
    { class } procedure reportAccount(P1: JContext; P2: JStatAccount;
      P3: JStatSpecifyReportedInfo); cdecl;
    // (Landroid/content/Context;Lcom/tencent/wxop/stat/StatAccount;Lcom/tencent/wxop/stat/StatSpecifyReportedInfo;)V
    { class } procedure reportGameUser(P1: JContext; P2: JStatGameUser;
      P3: JStatSpecifyReportedInfo); cdecl;
    // (Landroid/content/Context;Lcom/tencent/wxop/stat/StatGameUser;Lcom/tencent/wxop/stat/StatSpecifyReportedInfo;)V
    { class } function startStatService(P1: JContext; P2: JString; P3: JString;
      P4: JStatSpecifyReportedInfo): Boolean; cdecl;
    // (Landroid/content/Context;Ljava/lang/String;Ljava/lang/String;Lcom/tencent/wxop/stat/StatSpecifyReportedInfo;)Z
    { class } procedure onPause(P1: JContext; P2: JStatSpecifyReportedInfo);
      cdecl; // (Landroid/content/Context;Lcom/tencent/wxop/stat/StatSpecifyReportedInfo;)V
    { class } procedure onStop(P1: JContext; P2: JStatSpecifyReportedInfo);
      cdecl; // (Landroid/content/Context;Lcom/tencent/wxop/stat/StatSpecifyReportedInfo;)V
    { class } procedure onLowMemory(P1: JContext); cdecl;
    // (Landroid/content/Context;)V
    { class } procedure reportError(P1: JContext; P2: JString;
      P3: JStatSpecifyReportedInfo); cdecl;
    // (Landroid/content/Context;Ljava/lang/String;Lcom/tencent/wxop/stat/StatSpecifyReportedInfo;)V
    { class } procedure reportException(P1: JContext; P2: JThrowable;
      P3: JStatSpecifyReportedInfo); cdecl;
    // (Landroid/content/Context;Ljava/lang/Throwable;Lcom/tencent/wxop/stat/StatSpecifyReportedInfo;)V
    { class } procedure trackCustomEvent(P1: JContext; P2: JString;
      P3: JStatSpecifyReportedInfo; P4: TJavaObjectArray<JString>); cdecl;
    // (Landroid/content/Context;Ljava/lang/String;Lcom/tencent/wxop/stat/StatSpecifyReportedInfo;[Ljava/lang/String;)V
    { class } procedure trackCustomKVEvent(P1: JContext; P2: JString;
      P3: JProperties; P4: JStatSpecifyReportedInfo); cdecl;
    // (Landroid/content/Context;Ljava/lang/String;Ljava/util/Properties;Lcom/tencent/wxop/stat/StatSpecifyReportedInfo;)V
    { class } procedure setCommonKeyValueForKVEvent(P1: JString;
      P2: JProperties); cdecl; // (Ljava/lang/String;Ljava/util/Properties;)V
    { class } function getCommonKeyValueForKVEvent(P1: JString): JProperties;
      cdecl; // (Ljava/lang/String;)Ljava/util/Properties;
    { class } procedure trackCustomBeginEvent(P1: JContext; P2: JString;
      P3: JStatSpecifyReportedInfo; P4: TJavaObjectArray<JString>); cdecl;
    // (Landroid/content/Context;Ljava/lang/String;Lcom/tencent/wxop/stat/StatSpecifyReportedInfo;[Ljava/lang/String;)V
    { class } procedure trackCustomEndEvent(P1: JContext; P2: JString;
      P3: JStatSpecifyReportedInfo; P4: TJavaObjectArray<JString>); cdecl;
    // (Landroid/content/Context;Ljava/lang/String;Lcom/tencent/wxop/stat/StatSpecifyReportedInfo;[Ljava/lang/String;)V
    { class } procedure trackCustomBeginKVEvent(P1: JContext; P2: JString;
      P3: JProperties; P4: JStatSpecifyReportedInfo); cdecl;
    // (Landroid/content/Context;Ljava/lang/String;Ljava/util/Properties;Lcom/tencent/wxop/stat/StatSpecifyReportedInfo;)V
    { class } procedure trackCustomEndKVEvent(P1: JContext; P2: JString;
      P3: JProperties; P4: JStatSpecifyReportedInfo); cdecl;
    // (Landroid/content/Context;Ljava/lang/String;Ljava/util/Properties;Lcom/tencent/wxop/stat/StatSpecifyReportedInfo;)V
    { class } procedure reportAppMonitorStat(P1: JContext; P2: JStatAppMonitor;
      P3: JStatSpecifyReportedInfo); cdecl;
    // (Landroid/content/Context;Lcom/tencent/wxop/stat/StatAppMonitor;Lcom/tencent/wxop/stat/StatSpecifyReportedInfo;)V
    { class } procedure trackCustomTimeIntervalEvent(P1: JContext; P2: Integer;
      P3: JString; P4: TJavaObjectArray<JString>); cdecl;
    // (Landroid/content/Context;ILjava/lang/String;[Ljava/lang/String;)V
    { class } procedure trackCustomKVTimeIntervalEvent(P1: JContext;
      P2: JString; P3: JProperties; P4: Integer; P5: JStatSpecifyReportedInfo);
      cdecl; // (Landroid/content/Context;Ljava/lang/String;Ljava/util/Properties;ILcom/tencent/wxop/stat/StatSpecifyReportedInfo;)V
    { class } procedure commitEvents(P1: JContext; P2: Integer); cdecl;
    // (Landroid/content/Context;I)V
    { class } procedure testSpeed(P1: JContext); cdecl; overload;
    // (Landroid/content/Context;)V
    { class } procedure testSpeed(P1: JContext; P2: JMap;
      P3: JStatSpecifyReportedInfo); cdecl; overload;
    // (Landroid/content/Context;Ljava/util/Map;Lcom/tencent/wxop/stat/StatSpecifyReportedInfo;)V
    { class } procedure flushDataToDB(P1: JContext); cdecl;
    // (Landroid/content/Context;)V

    { static Property }
  end;

  [JavaSignature('com/tencent/wxop/stat/StatServiceImpl')]
  JStatServiceImpl = interface(JObject)
    ['{B07D79B9-72C8-40AC-BE5B-2759C038484C}']
    { Property Methods }

    { methods }

    { Property }
  end;

  TJStatServiceImpl = class(TJavaGenericImport<JStatServiceImplClass,
    JStatServiceImpl>)
  end;

  JStatSpecifyReportedInfoClass = interface(JObjectClass)
    ['{78BD451F-2F33-47D8-9922-653FDCAD72DD}']
    { static Property Methods }

    { static Methods }
    { class } function init: JStatSpecifyReportedInfo; cdecl; // ()V

    { static Property }
  end;

  [JavaSignature('com/tencent/wxop/stat/StatSpecifyReportedInfo')]
  JStatSpecifyReportedInfo = interface(JObject)
    ['{C3C4FDF1-CE73-4BB6-B331-99F3AFDFC618}']
    { Property Methods }

    { methods }
    function isSendImmediately: Boolean; cdecl; // ()Z
    procedure setSendImmediately(P1: Boolean); cdecl; // (Z)V
    function getVersion: JString; cdecl; // ()Ljava/lang/String;
    procedure setVersion(P1: JString); cdecl; // (Ljava/lang/String;)V
    function getAppKey: JString; cdecl; // ()Ljava/lang/String;
    procedure setAppKey(P1: JString); cdecl; // (Ljava/lang/String;)V
    function getInstallChannel: JString; cdecl; // ()Ljava/lang/String;
    procedure setInstallChannel(P1: JString); cdecl; // (Ljava/lang/String;)V
    function isImportant: Boolean; cdecl; // ()Z
    procedure setImportant(P1: Boolean); cdecl; // (Z)V
    function toString: JString; cdecl; // ()Ljava/lang/String;

    { Property }
  end;

  TJStatSpecifyReportedInfo = class
    (TJavaGenericImport<JStatSpecifyReportedInfoClass,
    JStatSpecifyReportedInfo>)
  end;

  JWXPayEntryActivityClass = interface(JActivityClass)
    // or JObjectClass // SuperSignature: android/app/Activity
    ['{36F4681B-72E4-423E-86DC-DDD1DEE7BC3D}']
    { static Property Methods }

    { static Methods }
    { class } function init: JWXPayEntryActivity; cdecl; // ()V

    { class } procedure setWxAPI(P1: JIWXAPI); cdecl;
    // (Lcom/tencent/mm/sdk/openapi/IWXAPI;)V
    { class } function getWxAPI: JIWXAPI; cdecl;
    // ()Lcom/tencent/mm/sdk/openapi/IWXAPI;
    { class } procedure setWXEventHandler(P1: JIWXAPIEventHandler); cdecl;
    // (Lcom/tencent/mm/sdk/openapi/IWXAPIEventHandler;)V
    { class } function getWXEventHandler: JIWXAPIEventHandler; cdecl;
    // ()Lcom/tencent/mm/sdk/openapi/IWXAPIEventHandler;

    { static Property }
    property WxAPI: JIWXAPI read getWxAPI write setWxAPI;
    property WXEventHandler: JIWXAPIEventHandler read getWXEventHandler
      write setWXEventHandler;
  end;

{$I 'wxpayactivity.inc'}

  JWXPayEntryActivity = interface(JActivity)
    // or JObject // SuperSignature: android/app/Activity
    ['{0011B21A-C602-4435-8F87-241B8968AC64}']
    { Property Methods }

    { methods }
    procedure onCreate(savedInstanceState: JBundle); cdecl;
    // (Landroid/os/Bundle;)V
    procedure onReq(req: JBaseReq); cdecl;
    // (Lcom/tencent/mm/sdk/modelbase/BaseReq;)V
    procedure onResp(resp: JBaseResp); cdecl;
    // (Lcom/tencent/mm/sdk/modelbase/BaseResp;)V

    { Property }
  end;

  TJWXPayEntryActivity = class(TJavaGenericImport<JWXPayEntryActivityClass,
    JWXPayEntryActivity>)
  end;

procedure RegisterWechatService;

implementation

uses system.classes, system.sysutils, system.Generics.Collections, fmx.platform,
  fmx.graphics, system.Diagnostics, system.Rtti, TypInfo, Dateutils,
  AndroidAPI.Helpers, system.Net.HttpClient, qstring, qxml, qjson, qdigest,
  qsdk.wechat;

resourcestring
  SSignMismatch = '业务签名校验失败，参数值：%s ，期望值为 %s';

type
  TWechatResponse = class(TInterfacedObject, IWechatResponse)
  private
    FErrorMsg: String;
    FType, FErrorCode: Integer;
    function getErrorCode: Integer;
    procedure setErrorCode(const acode: Integer);
    function getErrorMsg: String;
    function getRespType: Integer;
    procedure setErrorMsg(const AValue: String);
    property ErrorCode: Integer read getErrorCode write setErrorCode;
    property ErrorMsg: String read getErrorMsg write setErrorMsg;
  public
    constructor Create(AResp: JBaseResp);
  end;

  TWechatPayResponse = class(TWechatResponse, IWechatPayResponse)
  private
    FPrepayId, FReturnKey, FExtData: String;
    FPayResult: TWechatPayResult;
    function getPrepayId: String;
    procedure setPrepayId(const AVal: String);
    function getReturnKey: String;
    procedure setReturnKey(const AVal: String);
    function getExtData: String;
    procedure setExtData(const AVal: String);
    function getPayResult: TWechatPayResult;
  public
    constructor Create(AResp: JBaseResp);
  end;

  TAndroidWechatService = class(TJavaLocal, IWechatService, JIWXAPIEventHandler)
  private
    FInstance: JIWXAPI;
    FAppId: String;
    FMchId: String;
    FDevId: String;
    FPayKey: String;
    FLastErrorMsg: String;
    FLastError: Integer;
    FLastTransaction: Integer;
    FRegistered: Boolean;
    FOnRequest: TWechatRequestEvent;
    FOnResponse: TWechatResponseEvent;
    FPayActivity: JActivity;
    FSigner: IWechatSigner;
    function NextTransaction: String;
    function BitmapToArray(ABitmap: TBitmap): TJavaArray<Byte>;
  public
    constructor Create; overload;
    procedure Unregister;
    function IsInstalled: Boolean;
    function Registered: Boolean;
    function getAppId: String;
    function OpenWechat: Boolean;
    function ShareText(ATarget: TWechatSession; const S: String): Boolean;
    function ShareWebPage(ATarget: TWechatSession;
      const atitle, AContent, aurl: String; ABitmap: TBitmap): Boolean;
    function ShareBitmap(ATarget: TWechatSession; ABitmap: TBitmap): Boolean;
    function IsAPISupported: Boolean;
    function SendRequest(ARequest: IWechatRequest): Boolean;
    function SendResponse(AResp: IWechatResponse): Boolean;
    function getOnRequest: TWechatRequestEvent;
    procedure setOnRequest(const AEvent: TWechatRequestEvent);
    function getOnResponse: TWechatResponseEvent;
    procedure setOnResponse(const AEvent: TWechatResponseEvent);
    procedure setAppId(const AId: String);
    function OpenUrl(const aurl: String): Boolean;
    function SendText(const atext: String; ASession: TWechatSession): Boolean;
    function CreateObject(AObjId: TGuid): IWechatObject;
    function getMchId: String;
    procedure setMchId(const AId: String);
    function getDevId: String;
    procedure setDevId(const AId: String);
    function Pay(aprepayId, anonceStr, asign: String;
      atimeStamp: Integer): Boolean;
    procedure EnableSignCheck(ASigner: IWechatSigner);
    function getPayKey: String;
    procedure setPayKey(const AKey: String);
    procedure onReq(P1: JBaseReq); cdecl;
    procedure onResp(P1: JBaseResp); cdecl;
    property Instance: JIWXAPI read FInstance;
  end;

  TAndroidWechatBaseRequest = class(TWechatObject, IWechatRequest)
  protected
    FInstance: JBaseReq;
    function getOpenID: String;
    procedure setOpenID(const AValue: String);
    function getTansaction: String;
    procedure setTransaction(const AValue: String);
    function GetRequest: JBaseReq;
    function CreateRequest: JBaseReq; virtual;
  public
    constructor Create; overload;
    function QueryInterface(const IID: TGuid; out Obj): HResult;
      override; stdcall;
    property Request: JBaseReq read GetRequest;
  end;

  TAndroidWechatOpenUrlRequest = class(TAndroidWechatBaseRequest)
  private
    function GetUrl: String;
    procedure SetUrl(const Value: String);
  protected
    function CreateRequest: JBaseReq; override;
  public
    property url: String read GetUrl write SetUrl;
  end;

procedure RegisterWechatService;
begin
  TPlatformServices.Current.AddPlatformService(IWechatService,
    TAndroidWechatService.Create);
end;

procedure RegisterTypes;
begin
  TRegTypes.RegisterType('QSDK.Wechat.Android.JBuild',
    TypeInfo(qsdk.wechat.android.JBuild));
  TRegTypes.RegisterType('QSDK.Wechat.Android.JConstantsAPI_Token',
    TypeInfo(qsdk.wechat.android.JConstantsAPI_Token));
  TRegTypes.RegisterType('QSDK.Wechat.Android.JConstantsAPI_WXApp',
    TypeInfo(qsdk.wechat.android.JConstantsAPI_WXApp));
  TRegTypes.RegisterType('QSDK.Wechat.Android.JConstantsAPI',
    TypeInfo(qsdk.wechat.android.JConstantsAPI));
  TRegTypes.RegisterType('QSDK.Wechat.Android.JDiffDevOAuthFactory',
    TypeInfo(qsdk.wechat.android.JDiffDevOAuthFactory));
  TRegTypes.RegisterType('QSDK.Wechat.Android.JIDiffDevOAuth',
    TypeInfo(qsdk.wechat.android.JIDiffDevOAuth));
  TRegTypes.RegisterType('QSDK.Wechat.Android.JOAuthErrCode',
    TypeInfo(qsdk.wechat.android.JOAuthErrCode));
  TRegTypes.RegisterType('QSDK.Wechat.Android.JOAuthListener',
    TypeInfo(qsdk.wechat.android.JOAuthListener));
  TRegTypes.RegisterType('QSDK.Wechat.Android.JBaseReq',
    TypeInfo(qsdk.wechat.android.JBaseReq));
  TRegTypes.RegisterType('QSDK.Wechat.Android.JBaseResp_ErrCode',
    TypeInfo(qsdk.wechat.android.JBaseResp_ErrCode));
  TRegTypes.RegisterType('QSDK.Wechat.Android.JBaseResp',
    TypeInfo(qsdk.wechat.android.JBaseResp));
  TRegTypes.RegisterType('QSDK.Wechat.Android.JAddCardToWXCardPackage_Req',
    TypeInfo(qsdk.wechat.android.JAddCardToWXCardPackage_Req));
  TRegTypes.RegisterType('QSDK.Wechat.Android.JAddCardToWXCardPackage_Resp',
    TypeInfo(qsdk.wechat.android.JAddCardToWXCardPackage_Resp));
  TRegTypes.RegisterType
    ('QSDK.Wechat.Android.JAddCardToWXCardPackage_WXCardItem',
    TypeInfo(qsdk.wechat.android.JAddCardToWXCardPackage_WXCardItem));
  TRegTypes.RegisterType('QSDK.Wechat.Android.JAddCardToWXCardPackage',
    TypeInfo(qsdk.wechat.android.JAddCardToWXCardPackage));
  TRegTypes.RegisterType('QSDK.Wechat.Android.JCreateChatroom_Req',
    TypeInfo(qsdk.wechat.android.JCreateChatroom_Req));
  TRegTypes.RegisterType('QSDK.Wechat.Android.JCreateChatroom_Resp',
    TypeInfo(qsdk.wechat.android.JCreateChatroom_Resp));
  TRegTypes.RegisterType('QSDK.Wechat.Android.JCreateChatroom',
    TypeInfo(qsdk.wechat.android.JCreateChatroom));
  TRegTypes.RegisterType('QSDK.Wechat.Android.JJoinChatroom_Req',
    TypeInfo(qsdk.wechat.android.JJoinChatroom_Req));
  TRegTypes.RegisterType('QSDK.Wechat.Android.JJoinChatroom_Resp',
    TypeInfo(qsdk.wechat.android.JJoinChatroom_Resp));
  TRegTypes.RegisterType('QSDK.Wechat.Android.JJoinChatroom',
    TypeInfo(qsdk.wechat.android.JJoinChatroom));
  TRegTypes.RegisterType('QSDK.Wechat.Android.JJumpToBizProfile_Req',
    TypeInfo(qsdk.wechat.android.JJumpToBizProfile_Req));
  TRegTypes.RegisterType('QSDK.Wechat.Android.JJumpToBizProfile',
    TypeInfo(qsdk.wechat.android.JJumpToBizProfile));
  TRegTypes.RegisterType('QSDK.Wechat.Android.JJumpToBizTempSession_Req',
    TypeInfo(qsdk.wechat.android.JJumpToBizTempSession_Req));
  TRegTypes.RegisterType('QSDK.Wechat.Android.JJumpToBizTempSession',
    TypeInfo(qsdk.wechat.android.JJumpToBizTempSession));
  TRegTypes.RegisterType('QSDK.Wechat.Android.JJumpToBizWebview_Req',
    TypeInfo(qsdk.wechat.android.JJumpToBizWebview_Req));
  TRegTypes.RegisterType('QSDK.Wechat.Android.JJumpToBizWebview',
    TypeInfo(qsdk.wechat.android.JJumpToBizWebview));
  TRegTypes.RegisterType('QSDK.Wechat.Android.JOpenBusiLuckyMoney_Req',
    TypeInfo(qsdk.wechat.android.JOpenBusiLuckyMoney_Req));
  TRegTypes.RegisterType('QSDK.Wechat.Android.JOpenBusiLuckyMoney',
    TypeInfo(qsdk.wechat.android.JOpenBusiLuckyMoney));
  TRegTypes.RegisterType('QSDK.Wechat.Android.JOpenRankList_Req',
    TypeInfo(qsdk.wechat.android.JOpenRankList_Req));
  TRegTypes.RegisterType('QSDK.Wechat.Android.JOpenRankList',
    TypeInfo(qsdk.wechat.android.JOpenRankList));
  TRegTypes.RegisterType('QSDK.Wechat.Android.JOpenWebview_Req',
    TypeInfo(qsdk.wechat.android.JOpenWebview_Req));
  TRegTypes.RegisterType('QSDK.Wechat.Android.JOpenWebview_Resp',
    TypeInfo(qsdk.wechat.android.JOpenWebview_Resp));
  TRegTypes.RegisterType('QSDK.Wechat.Android.JOpenWebview',
    TypeInfo(qsdk.wechat.android.JOpenWebview));
  TRegTypes.RegisterType('QSDK.Wechat.Android.JGetMessageFromWX_Req',
    TypeInfo(qsdk.wechat.android.JGetMessageFromWX_Req));
  TRegTypes.RegisterType('QSDK.Wechat.Android.JGetMessageFromWX_Resp',
    TypeInfo(qsdk.wechat.android.JGetMessageFromWX_Resp));
  TRegTypes.RegisterType('QSDK.Wechat.Android.JGetMessageFromWX',
    TypeInfo(qsdk.wechat.android.JGetMessageFromWX));
  TRegTypes.RegisterType('QSDK.Wechat.Android.JLaunchFromWX_Req',
    TypeInfo(qsdk.wechat.android.JLaunchFromWX_Req));
  TRegTypes.RegisterType('QSDK.Wechat.Android.JLaunchFromWX_Resp',
    TypeInfo(qsdk.wechat.android.JLaunchFromWX_Resp));
  TRegTypes.RegisterType('QSDK.Wechat.Android.JLaunchFromWX',
    TypeInfo(qsdk.wechat.android.JLaunchFromWX));
  TRegTypes.RegisterType('QSDK.Wechat.Android.JSendAuth_Req',
    TypeInfo(qsdk.wechat.android.JSendAuth_Req));
  TRegTypes.RegisterType('QSDK.Wechat.Android.JSendAuth_Resp',
    TypeInfo(qsdk.wechat.android.JSendAuth_Resp));
  TRegTypes.RegisterType('QSDK.Wechat.Android.JSendAuth',
    TypeInfo(qsdk.wechat.android.JSendAuth));
  TRegTypes.RegisterType('QSDK.Wechat.Android.JSendMessageToWX_Req',
    TypeInfo(qsdk.wechat.android.JSendMessageToWX_Req));
  TRegTypes.RegisterType('QSDK.Wechat.Android.JSendMessageToWX_Resp',
    TypeInfo(qsdk.wechat.android.JSendMessageToWX_Resp));
  TRegTypes.RegisterType('QSDK.Wechat.Android.JSendMessageToWX',
    TypeInfo(qsdk.wechat.android.JSendMessageToWX));
  TRegTypes.RegisterType('QSDK.Wechat.Android.JShowMessageFromWX_Req',
    TypeInfo(qsdk.wechat.android.JShowMessageFromWX_Req));
  TRegTypes.RegisterType('QSDK.Wechat.Android.JShowMessageFromWX_Resp',
    TypeInfo(qsdk.wechat.android.JShowMessageFromWX_Resp));
  TRegTypes.RegisterType('QSDK.Wechat.Android.JShowMessageFromWX',
    TypeInfo(qsdk.wechat.android.JShowMessageFromWX));
  TRegTypes.RegisterType('QSDK.Wechat.Android.JWXAppExtendObject',
    TypeInfo(qsdk.wechat.android.JWXAppExtendObject));
  TRegTypes.RegisterType('QSDK.Wechat.Android.JWXAppLaunchData_Builder',
    TypeInfo(qsdk.wechat.android.JWXAppLaunchData_Builder));
  TRegTypes.RegisterType('QSDK.Wechat.Android.JWXAppLaunchData',
    TypeInfo(qsdk.wechat.android.JWXAppLaunchData));
  TRegTypes.RegisterType('QSDK.Wechat.Android.JWXDesignerSharedObject',
    TypeInfo(qsdk.wechat.android.JWXDesignerSharedObject));
  TRegTypes.RegisterType('QSDK.Wechat.Android.JWXEmojiObject',
    TypeInfo(qsdk.wechat.android.JWXEmojiObject));
  TRegTypes.RegisterType('QSDK.Wechat.Android.JWXEmojiSharedObject',
    TypeInfo(qsdk.wechat.android.JWXEmojiSharedObject));
  TRegTypes.RegisterType('QSDK.Wechat.Android.JWXFileObject',
    TypeInfo(qsdk.wechat.android.JWXFileObject));
  TRegTypes.RegisterType('QSDK.Wechat.Android.JWXImageObject',
    TypeInfo(qsdk.wechat.android.JWXImageObject));
  TRegTypes.RegisterType('QSDK.Wechat.Android.JWXMediaMessage_Builder',
    TypeInfo(qsdk.wechat.android.JWXMediaMessage_Builder));
  TRegTypes.RegisterType('QSDK.Wechat.Android.JWXMediaMessage_IMediaObject',
    TypeInfo(qsdk.wechat.android.JWXMediaMessage_IMediaObject));
  TRegTypes.RegisterType('QSDK.Wechat.Android.JWXMediaMessage',
    TypeInfo(qsdk.wechat.android.JWXMediaMessage));
  TRegTypes.RegisterType('QSDK.Wechat.Android.JWXMusicObject',
    TypeInfo(qsdk.wechat.android.JWXMusicObject));
  TRegTypes.RegisterType('QSDK.Wechat.Android.JWXTextObject',
    TypeInfo(qsdk.wechat.android.JWXTextObject));
  TRegTypes.RegisterType('QSDK.Wechat.Android.JWXVideoObject',
    TypeInfo(qsdk.wechat.android.JWXVideoObject));
  TRegTypes.RegisterType('QSDK.Wechat.Android.JWXWebpageObject',
    TypeInfo(qsdk.wechat.android.JWXWebpageObject));
  TRegTypes.RegisterType('QSDK.Wechat.Android.JPayReq_Options',
    TypeInfo(qsdk.wechat.android.JPayReq_Options));
  TRegTypes.RegisterType('QSDK.Wechat.Android.JPayReq',
    TypeInfo(qsdk.wechat.android.JPayReq));
  TRegTypes.RegisterType('QSDK.Wechat.Android.JPayResp',
    TypeInfo(qsdk.wechat.android.JPayResp));
  TRegTypes.RegisterType('QSDK.Wechat.Android.JIWXAPI',
    TypeInfo(qsdk.wechat.android.JIWXAPI));
  TRegTypes.RegisterType('QSDK.Wechat.Android.JIWXAPIEventHandler',
    TypeInfo(qsdk.wechat.android.JIWXAPIEventHandler));
  TRegTypes.RegisterType('QSDK.Wechat.Android.JMMSharedPreferences_REditor',
    TypeInfo(qsdk.wechat.android.JMMSharedPreferences_REditor));
  TRegTypes.RegisterType('QSDK.Wechat.Android.JMMSharedPreferences',
    TypeInfo(qsdk.wechat.android.JMMSharedPreferences));
  TRegTypes.RegisterType('QSDK.Wechat.Android.JWXAPIFactory',
    TypeInfo(qsdk.wechat.android.JWXAPIFactory));
  TRegTypes.RegisterType('QSDK.Wechat.Android.JWXApiImplComm',
    TypeInfo(qsdk.wechat.android.JWXApiImplComm));
  TRegTypes.RegisterType('QSDK.Wechat.Android.JWXApiImplV10_1',
    TypeInfo(qsdk.wechat.android.JWXApiImplV10_1));
  TRegTypes.RegisterType
    ('QSDK.Wechat.Android.JWXApiImplV10_ActivityLifecycleCb_1',
    TypeInfo(qsdk.wechat.android.JWXApiImplV10_ActivityLifecycleCb_1));
  TRegTypes.RegisterType
    ('QSDK.Wechat.Android.JWXApiImplV10_ActivityLifecycleCb_2',
    TypeInfo(qsdk.wechat.android.JWXApiImplV10_ActivityLifecycleCb_2));
  TRegTypes.RegisterType
    ('QSDK.Wechat.Android.JWXApiImplV10_ActivityLifecycleCb',
    TypeInfo(qsdk.wechat.android.JWXApiImplV10_ActivityLifecycleCb));
  TRegTypes.RegisterType('QSDK.Wechat.Android.JWXApiImplV10',
    TypeInfo(qsdk.wechat.android.JWXApiImplV10));
  TRegTypes.RegisterType('QSDK.Wechat.Android.JStatConstants',
    TypeInfo(qsdk.wechat.android.JStatConstants));
  TRegTypes.RegisterType('QSDK.Wechat.Android.JStatLogger',
    TypeInfo(qsdk.wechat.android.JStatLogger));
  TRegTypes.RegisterType('QSDK.Wechat.Android.JEasyActivity',
    TypeInfo(qsdk.wechat.android.JEasyActivity));
  TRegTypes.RegisterType('QSDK.Wechat.Android.JMtaSDkException',
    TypeInfo(qsdk.wechat.android.JMtaSDkException));
  TRegTypes.RegisterType('QSDK.Wechat.Android.JNetworkMonitor',
    TypeInfo(qsdk.wechat.android.JNetworkMonitor));
  TRegTypes.RegisterType('QSDK.Wechat.Android.JStatAccount',
    TypeInfo(qsdk.wechat.android.JStatAccount));
  TRegTypes.RegisterType('QSDK.Wechat.Android.JStatAppMonitor',
    TypeInfo(qsdk.wechat.android.JStatAppMonitor));
  TRegTypes.RegisterType('QSDK.Wechat.Android.JStatConfig',
    TypeInfo(qsdk.wechat.android.JStatConfig));
  TRegTypes.RegisterType('QSDK.Wechat.Android.JStatGameUser',
    TypeInfo(qsdk.wechat.android.JStatGameUser));
  TRegTypes.RegisterType('QSDK.Wechat.Android.JStatReportStrategy',
    TypeInfo(qsdk.wechat.android.JStatReportStrategy));
  TRegTypes.RegisterType('QSDK.Wechat.Android.JStatService',
    TypeInfo(qsdk.wechat.android.JStatService));
  TRegTypes.RegisterType('QSDK.Wechat.Android.JStatServiceImpl',
    TypeInfo(qsdk.wechat.android.JStatServiceImpl));
  TRegTypes.RegisterType('QSDK.Wechat.Android.JStatSpecifyReportedInfo',
    TypeInfo(qsdk.wechat.android.JStatSpecifyReportedInfo));
  TRegTypes.RegisterType('Androidapi.JNI.wxpay.JWXPayEntryActivity',
    TypeInfo(qsdk.wechat.android.JWXPayEntryActivity));
end;

{ TAndroidWechatService }

function TAndroidWechatService.BitmapToArray(ABitmap: TBitmap)
  : TJavaArray<Byte>;
var
  AStream: TMemoryStream;
begin
  AStream := TMemoryStream.Create;
  try
    ABitmap.SaveToStream(AStream);
    result := TJavaArray<Byte>.Create(AStream.Size);
    Move(AStream.Memory^, result.Data^, AStream.Size);
  finally
    FreeAndNil(ABitmap);
  end;
end;

constructor TAndroidWechatService.Create;
begin
  inherited;
  FDevId := 'APP';
end;

function TAndroidWechatService.CreateObject(AObjId: TGuid): IWechatObject;
begin
  if AObjId = IWechatRequest then
    result := TAndroidWechatBaseRequest.Create;
end;

procedure TAndroidWechatService.EnableSignCheck(ASigner: IWechatSigner);
begin
  FSigner := ASigner;
end;

function TAndroidWechatService.getAppId: String;
begin
  result := FAppId;
end;

function TAndroidWechatService.getDevId: String;
begin
  result := FDevId;
end;

function TAndroidWechatService.getMchId: String;
begin
  result := FMchId;
end;

function TAndroidWechatService.getOnRequest: TWechatRequestEvent;
begin
  result := FOnRequest;
end;

function TAndroidWechatService.getOnResponse: TWechatResponseEvent;
begin
  result := FOnResponse;
end;

function TAndroidWechatService.getPayKey: String;
begin
  result := FPayKey;
end;

function TAndroidWechatService.IsAPISupported: Boolean;
begin
  result := Registered and FInstance.isWXAppSupportAPI;
end;

function TAndroidWechatService.IsInstalled: Boolean;
begin
  result := Registered and FInstance.isWXAppInstalled;
end;

function TAndroidWechatService.NextTransaction: String;
begin
  Inc(FLastTransaction);
  result := IntToStr(FLastTransaction);
end;

procedure TAndroidWechatService.onReq(P1: JBaseReq);
var
  AReq: IWechatRequest;
  ATypeId: Integer;
  AXML: TQXML;
begin
  if Assigned(FOnRequest) then
  begin
    ATypeId := P1.getType;
    // case ATypeId of
    //
    // end;
  end;
end;

procedure TAndroidWechatService.onResp(P1: JBaseResp);
var
  APayResp: JPayResp;
  AResp: IWechatResponse;
  AClassName: String;
begin
  if Assigned(FOnResponse) then
  begin
    // Debugout('WechatService::Pay Response cast error,real class is %s',
    // [JStringToString(P1.getClass.getCanonicalName)]);
    if P1.getType = TJConstantsAPI.JavaClass.COMMAND_PAY_BY_WX then
      FOnResponse(TWechatPayResponse.Create(P1))
    else
      FOnResponse(TWechatResponse.Create(P1));
  end;
end;

function TAndroidWechatService.OpenUrl(const aurl: String): Boolean;
var
  AReq: TAndroidWechatOpenUrlRequest;
begin
  AReq := TAndroidWechatOpenUrlRequest.Create;
  AReq.url := aurl;
  result := SendRequest(AReq);
end;

function TAndroidWechatService.OpenWechat: Boolean;
begin
  result := Registered and FInstance.openWXApp;
end;

function TAndroidWechatService.Pay(aprepayId, anonceStr, asign: String;
  atimeStamp: Integer): Boolean;
const
  PrepayUrl = 'https://api.mch.weixin.qq.com/pay/unifiedorder';
var
  AReq: JPayReq;
  AExpectSign: String;
begin
  AReq := TJPayReq.JavaClass.init;
  AReq.appId := StringToJString(FAppId);
  AReq.partnerId := StringToJString(FMchId);
  AReq.prepayId := StringToJString(aprepayId);
  AReq.packageValue := StringToJString('Sign=WXPay');
  AReq.nonceStr := StringToJString(anonceStr);
  AReq.timeStamp := StringToJString(IntToStr(atimeStamp));
  AReq.sign := StringToJString(asign);
  if Assigned(FSigner) then
  begin
    FSigner.Clear;
    FSigner.Add('appid', FAppId);
    FSigner.Add('partnerid', FMchId);
    FSigner.Add('prepayid', aprepayId);
    FSigner.Add('noncestr', anonceStr);
    FSigner.Add('package', 'Sign=WXPay');
    FSigner.Add('timestamp', IntToStr(atimeStamp));
    AExpectSign := FSigner.Sign;
    if AExpectSign <> ASign then
      raise Exception.CreateFmt(SSignMismatch, [ASign, AExpectSign]);
  end;
  Debugout('WXPay Start with PrepayId %s,NonceStr %s,Timestamp %d ,Sign %s',
    [aprepayId, anonceStr, atimeStamp, asign]);
  result := Registered and FInstance.sendReq(AReq as JBaseReq);
end;

function TAndroidWechatService.Registered: Boolean;
begin
  if not Assigned(FInstance) then
  begin
    if Length(FAppId) > 0 then
    begin
      FInstance := TJWXAPIFactory.JavaClass.createWXAPI(TAndroidHelper.Context,
        StringToJString(FAppId));
      FInstance.registerApp(StringToJString(FAppId));
      TJWXPayEntryActivity.JavaClass.WxAPI := FInstance;
      TJWXPayEntryActivity.JavaClass.WXEventHandler := Self;
    end;
  end;
  result := Assigned(FInstance);
end;

function TAndroidWechatService.SendRequest(ARequest: IWechatRequest): Boolean;
begin
  result := Registered and FInstance.sendReq(ARequest as JBaseReq);
end;

function TAndroidWechatService.SendResponse(AResp: IWechatResponse): Boolean;
begin
  result := Registered and FInstance.sendResp(AResp as JBaseResp);
end;

function TAndroidWechatService.SendText(const atext: String;
  ASession: TWechatSession): Boolean;
var
  ATextObj: JWXTextObject;
  AMsg: JWXMediaMessage;
  AReq: JSendMessageToWX_Req;
begin
  if Registered then
  begin
    ATextObj := TJWXTextObject.JavaClass.init;
    ATextObj.text := StringToJString(atext);
    AMsg := TJWXMediaMessage.JavaClass.init;
    AMsg.mediaObject := TJWXMediaMessage_IMediaObject.Wrap
      ((ATextObj as ILocalObject).GetObjectID);
    AMsg.description := ATextObj.text;
    AReq := TJSendMessageToWX_Req.JavaClass.init;
    AReq.transaction := StringToJString(IntToStr(TStopWatch.GetTimeStamp));
    AReq.message := AMsg;
    case ASession of
      TWechatSession.Session:
        AReq.scene := TJSendMessageToWX_Req.JavaClass.WXSceneSession;
      TWechatSession.Timeline:
        AReq.scene := TJSendMessageToWX_Req.JavaClass.WXSceneTimeline;
      TWechatSession.Favorite:
        AReq.scene := TJSendMessageToWX_Req.JavaClass.WXSceneFavorite;
    end;
    result := FInstance.sendReq(AReq);
  end
  else
    result := false;
end;

procedure TAndroidWechatService.setAppId(const AId: String);
begin
  if FAppId <> AId then
  begin
    if Length(FAppId) > 0 then
      Unregister;
    FAppId := AId;
  end;
end;

procedure TAndroidWechatService.setDevId(const AId: String);
begin
  FDevId := AId;
end;

procedure TAndroidWechatService.setMchId(const AId: String);
begin
  FMchId := AId;
end;

procedure TAndroidWechatService.setOnRequest(const AEvent: TWechatRequestEvent);
begin
  FOnRequest := AEvent;
end;

procedure TAndroidWechatService.setOnResponse(const AEvent
  : TWechatResponseEvent);
begin
  FOnResponse := AEvent;
end;

procedure TAndroidWechatService.setPayKey(const AKey: String);
begin
  FPayKey := AKey;
end;

function TAndroidWechatService.ShareBitmap(ATarget: TWechatSession;
  ABitmap: TBitmap): Boolean;
var
  imgObj: JWXImageObject;
  msg: JWXMediaMessage;
  req: JSendMessageToWX_Req;
begin
  imgObj := TJWXImageObject.JavaClass.init;
  imgObj.imageData := BitmapToArray(ABitmap);
  msg := TJWXMediaMessage.JavaClass.init
    (TJWXMediaMessage_IMediaObject.Wrap((imgObj as ILocalObject).GetObjectID));
  req := TJSendMessageToWX_Req.JavaClass.init;
  req.transaction := StringToJString(NextTransaction);
  req.message := msg;
  case ATarget of
    TWechatSession.Session: // 当前会话
      req.scene := TJSendMessageToWX_Req.JavaClass.WXSceneSession;
    TWechatSession.Timeline:
      req.scene := TJSendMessageToWX_Req.JavaClass.WXSceneTimeline;
    TWechatSession.Favorite:
      req.scene := TJSendMessageToWX_Req.JavaClass.WXSceneFavorite;
  end;
  result := Registered and Instance.sendReq(req);
end;

function TAndroidWechatService.ShareText(ATarget: TWechatSession;
  const S: String): Boolean;
var
  textObj: JWXTextObject;
  msg: JWXMediaMessage;
  req: JSendMessageToWX_Req;
begin
  textObj := TJWXTextObject.JavaClass.init;
  textObj.text := StringToJString(S);
  msg := TJWXMediaMessage.JavaClass.init
    (TJWXMediaMessage_IMediaObject.Wrap((textObj as ILocalObject).GetObjectID));
  msg.description := StringToJString(S);
  req := TJSendMessageToWX_Req.JavaClass.init;
  req.transaction := StringToJString(NextTransaction);
  req.message := msg;
  case ATarget of
    TWechatSession.Session: // 当前会话
      req.scene := TJSendMessageToWX_Req.JavaClass.WXSceneSession;
    TWechatSession.Timeline:
      req.scene := TJSendMessageToWX_Req.JavaClass.WXSceneTimeline;
    TWechatSession.Favorite:
      req.scene := TJSendMessageToWX_Req.JavaClass.WXSceneFavorite;
  end;
  result := Registered and Instance.sendReq(req);
end;

function TAndroidWechatService.ShareWebPage(ATarget: TWechatSession;
  const atitle, AContent, aurl: String; ABitmap: TBitmap): Boolean;
var
  webPage: JWXWebpageObject;
  msg: JWXMediaMessage;
  req: JSendMessageToWX_Req;
begin
  webPage := TJWXWebpageObject.JavaClass.init;
  webPage.webpageUrl := StringToJString(aurl);
  msg := TJWXMediaMessage.JavaClass.init
    (TJWXMediaMessage_IMediaObject.Wrap((webPage as ILocalObject).GetObjectID));
  msg.title := StringToJString(atitle);
  msg.description := StringToJString(AContent);
  if Assigned(ABitmap) then
    msg.thumbData := BitmapToArray(ABitmap)
  else
    msg.thumbData := nil;
  req := TJSendMessageToWX_Req.JavaClass.init;
  req.transaction := StringToJString(NextTransaction);
  req.message := msg;
  case ATarget of
    TWechatSession.Session: // 当前会话
      req.scene := TJSendMessageToWX_Req.JavaClass.WXSceneSession;
    TWechatSession.Timeline:
      req.scene := TJSendMessageToWX_Req.JavaClass.WXSceneTimeline;
    TWechatSession.Favorite:
      req.scene := TJSendMessageToWX_Req.JavaClass.WXSceneFavorite;
  end;
  result := Registered and Instance.sendReq(req);
  //
  // WXWebpageObject webpage = new WXWebpageObject();
  // webpage.webpageUrl = shareContent.getURL();
  // WXMediaMessage msg = new WXMediaMessage(webpage);
  // msg.title = shareContent.getTitle();
  // msg.description = shareContent.getContent();
  //
  // Bitmap thumb = BitmapFactory.decodeResource(mContext.getResources(), shareContent.getPictureResource());
  // if(thumb == null) {
  // Toast.makeText(mContext, "图片不能为空", Toast.LENGTH_SHORT).show();
  // } else {
  // msg.thumbData = Util.bmpToByteArray(thumb, true);
  // }
  //
  // SendMessageToWX.req req = new SendMessageToWX.req();
  // req.transaction = buildTransaction(" webPage ");
  // req.message = msg;
  // req.scene = shareType;
  // mWXApi.sendReq(req);
end;

procedure TAndroidWechatService.Unregister;
begin
  if Assigned(FInstance) then
  begin
    FInstance.unregisterApp;
    FInstance := nil;
  end;
end;

{ TAndroidWechatBaseRequest }

constructor TAndroidWechatBaseRequest.Create;
begin
  inherited;
end;

function TAndroidWechatBaseRequest.CreateRequest: JBaseReq;
begin
  result := TJBaseReq.JavaClass.init;
end;

function TAndroidWechatBaseRequest.getOpenID: String;
begin
  result := JStringToString(Request.openId);
end;

function TAndroidWechatBaseRequest.getTansaction: String;
begin
  result := JStringToString(Request.transaction);
end;

function TAndroidWechatBaseRequest.QueryInterface(const IID: TGuid;
  out Obj): HResult;
begin
  if not Supports(Request, IID, Obj) then
    result := inherited
  else
    result := S_OK;
end;

function TAndroidWechatBaseRequest.GetRequest: JBaseReq;
begin
  if not Assigned(FInstance) then
  begin
    FInstance := CreateRequest;
    // 使用当前时间创建一个默认的会话ID
    FInstance.transaction := StringToJString(IntToStr(TStopWatch.GetTimeStamp));
  end;
  result := FInstance;
end;

procedure TAndroidWechatBaseRequest.setOpenID(const AValue: String);
begin
  Request.openId := StringToJString(AValue);
end;

procedure TAndroidWechatBaseRequest.setTransaction(const AValue: String);
begin
  Request.transaction := StringToJString(AValue);
end;

{ TAndroidWechatOpenUrlRequest }

function TAndroidWechatOpenUrlRequest.CreateRequest: JBaseReq;
begin
  result := TJOpenWebview_Req.JavaClass.init;
end;

function TAndroidWechatOpenUrlRequest.GetUrl: String;
begin
  result := JStringToString((Request as JOpenWebview_Req).url);
end;

procedure TAndroidWechatOpenUrlRequest.SetUrl(const Value: String);
begin
  (Request as JOpenWebview_Req).url := StringToJString(Value);
end;

{ TWechatResponse }

constructor TWechatResponse.Create(AResp: JBaseResp);
begin
  inherited Create;
  FType := AResp.getType;
  FErrorCode := AResp.errCode;
  FErrorMsg := JStringToString(AResp.errStr);
end;

function TWechatResponse.getErrorCode: Integer;
begin
  result := FErrorCode;
end;

function TWechatResponse.getErrorMsg: String;
begin
  result := FErrorMsg;
end;

function TWechatResponse.getRespType: Integer;
begin
  result := FType;
end;

procedure TWechatResponse.setErrorCode(const acode: Integer);
begin
  FErrorCode := acode;
end;

procedure TWechatResponse.setErrorMsg(const AValue: String);
begin
  FErrorMsg := AValue;
end;

{ TWechatPayResponse }

constructor TWechatPayResponse.Create(AResp: JBaseResp);
var
  APayResp: JPayResp;
  AJavaClass: Jlang_Class;
begin
  inherited Create(AResp);
  AJavaClass := TJlang_Class.JavaClass.forName(AResp.getClass.getCanonicalName);
  if Assigned(AJavaClass) then
    APayResp := TJPayResp.Wrap((AJavaClass.cast(AResp) as ILocalObject)
      .GetObjectID);
  FPrepayId := JStringToString(APayResp.prepayId);
  FReturnKey := JStringToString(APayResp.returnKey);
  FExtData := JStringToString(APayResp.extData);
  if ErrorCode = TJBaseResp_ErrCode.JavaClass.ERR_OK then
    FPayResult := TWechatPayResult.wprOk
  else
  begin
    if Length(ErrorMsg) = 0 then
    begin
      if ErrorCode = TJBaseResp_ErrCode.JavaClass.ERR_COMM then
        FErrorMsg := 'ERR_COMM'
      else if ErrorCode = TJBaseResp_ErrCode.JavaClass.ERR_USER_CANCEL then
        FErrorMsg := 'ERR_USER_CANCEL'
      else if ErrorCode = TJBaseResp_ErrCode.JavaClass.ERR_SENT_FAILED then
        FErrorMsg := 'ERR_SENT_FAILED'
      else if ErrorCode = TJBaseResp_ErrCode.JavaClass.ERR_AUTH_DENIED then
        FErrorMsg := 'ERR_AUTH_DENIED'
      else if ErrorCode = TJBaseResp_ErrCode.JavaClass.ERR_UNSUPPORT then
        FErrorMsg := 'ERR_UNSUPPORT'
      else if ErrorCode = TJBaseResp_ErrCode.JavaClass.ERR_BAN then
        FErrorMsg := 'ERR_BAN'
      else
        FErrorMsg := 'ERR_UNKNOWN';
    end;
    if ErrorCode = TJBaseResp_ErrCode.JavaClass.ERR_USER_CANCEL then
      FPayResult := TWechatPayResult.wprCancel
    else
      FPayResult := TWechatPayResult.wprError;
  end;
end;

function TWechatPayResponse.getExtData: String;
begin
  result := FExtData;
end;

function TWechatPayResponse.getPayResult: TWechatPayResult;
begin
  result := FPayResult;
end;

function TWechatPayResponse.getPrepayId: String;
begin
  result := FPrepayId;
end;

function TWechatPayResponse.getReturnKey: String;
begin
  result := FReturnKey;
end;

procedure TWechatPayResponse.setExtData(const AVal: String);
begin
  FExtData := AVal;
end;

procedure TWechatPayResponse.setPrepayId(const AVal: String);
begin
  FPrepayId := AVal;
end;

procedure TWechatPayResponse.setReturnKey(const AVal: String);
begin
  FReturnKey := AVal;
end;

initialization

RegisterTypes;
// LifecycleManager := TAndroidActivityLifecycleManager.Create;

finalization

// UnregisterLifecycleManager;

end.
