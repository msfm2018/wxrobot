{ *********************************************************** }
{ }
{ CodeGear Delphi Runtime Library }
{ }
{ Copyright(c) 2012-2014 Embarcadero Technologies, Inc. }
{ }
{ *********************************************************** }

//
// Delphi-Objective-C Bridge
// Interfaces for Cocoa framework CFNetwork
//

unit iOSapi.CFNetwork;

interface

uses
  Macapi.CoreFoundation,
  Macapi.CoreServices,
  Macapi.Dispatch,
  Macapi.Mach,
  Macapi.ObjCRuntime,
  Macapi.ObjectiveC,
  iOSapi.CocoaTypes,
  iOSapi.Foundation;

const
  kCFHostAddresses = 0;
  kCFHostNames = 1;
  kCFHostReachability = 2;
  kCFStreamErrorHTTPAuthenticationTypeUnsupported = -1000;
  kCFStreamErrorHTTPAuthenticationBadUserName = -1001;
  kCFStreamErrorHTTPAuthenticationBadPassword = -1002;
  kCFStreamErrorHTTPParseFailure = -1;
  kCFStreamErrorHTTPRedirectionLoop = -2;
  kCFStreamErrorHTTPBadURL = -3;
  kCFNetDiagnosticNoErr = 0;
  kCFNetDiagnosticErr = -66560;
  kCFNetDiagnosticConnectionUp = -66559;
  kCFNetDiagnosticConnectionIndeterminate = -66558;
  kCFNetDiagnosticConnectionDown = -66557;
  kCFNetServicesErrorUnknown = -72000;
  kCFNetServicesErrorCollision = -72001;
  kCFNetServicesErrorNotFound = -72002;
  kCFNetServicesErrorInProgress = -72003;
  kCFNetServicesErrorBadArgument = -72004;
  kCFNetServicesErrorCancel = -72005;
  kCFNetServicesErrorInvalid = -72006;
  kCFNetServicesErrorTimeout = -72007;
  kCFNetServiceMonitorTXT = 1;
  kCFNetServiceFlagNoAutoRename = 1;
  kCFNetServiceFlagMoreComing = 1;
  kCFNetServiceFlagIsDomain = 2;
  kCFNetServiceFlagIsDefault = 4;
  kCFNetServiceFlagIsRegistrationDomain = 4;
  kCFNetServiceFlagRemove = 8;
  kCFHostErrorHostNotFound = 1;
  kCFHostErrorUnknown = 2;
  kCFSOCKSErrorUnknownClientVersion = 100;
  kCFSOCKSErrorUnsupportedServerVersion = 101;
  kCFSOCKS4ErrorRequestFailed = 110;
  kCFSOCKS4ErrorIdentdFailed = 111;
  kCFSOCKS4ErrorIdConflict = 112;
  kCFSOCKS4ErrorUnknownStatusCode = 113;
  kCFSOCKS5ErrorBadState = 120;
  kCFSOCKS5ErrorBadResponseAddr = 121;
  kCFSOCKS5ErrorBadCredentials = 122;
  kCFSOCKS5ErrorUnsupportedNegotiationMethod = 123;
  kCFSOCKS5ErrorNoAcceptableMethod = 124;
  kCFFTPErrorUnexpectedStatusCode = 200;
  kCFErrorHTTPAuthenticationTypeUnsupported = 300;
  kCFErrorHTTPBadCredentials = 301;
  kCFErrorHTTPConnectionLost = 302;
  kCFErrorHTTPParseFailure = 303;
  kCFErrorHTTPRedirectionLoopDetected = 304;
  kCFErrorHTTPBadURL = 305;
  kCFErrorHTTPProxyConnectionFailure = 306;
  kCFErrorHTTPBadProxyCredentials = 307;
  kCFErrorPACFileError = 308;
  kCFErrorPACFileAuth = 309;
  kCFErrorHTTPSProxyConnectionFailure = 310;
  kCFStreamErrorHTTPSProxyFailureUnexpectedResponseToCONNECTMethod = 311;
  kCFURLErrorBackgroundSessionInUseByAnotherProcess = -996;
  kCFURLErrorBackgroundSessionWasDisconnected = -997;
  kCFURLErrorUnknown = -998;
  kCFURLErrorCancelled = -999;
  kCFURLErrorBadURL = -1000;
  kCFURLErrorTimedOut = -1001;
  kCFURLErrorUnsupportedURL = -1002;
  kCFURLErrorCannotFindHost = -1003;
  kCFURLErrorCannotConnectToHost = -1004;
  kCFURLErrorNetworkConnectionLost = -1005;
  kCFURLErrorDNSLookupFailed = -1006;
  kCFURLErrorHTTPTooManyRedirects = -1007;
  kCFURLErrorResourceUnavailable = -1008;
  kCFURLErrorNotConnectedToInternet = -1009;
  kCFURLErrorRedirectToNonExistentLocation = -1010;
  kCFURLErrorBadServerResponse = -1011;
  kCFURLErrorUserCancelledAuthentication = -1012;
  kCFURLErrorUserAuthenticationRequired = -1013;
  kCFURLErrorZeroByteResource = -1014;
  kCFURLErrorCannotDecodeRawData = -1015;
  kCFURLErrorCannotDecodeContentData = -1016;
  kCFURLErrorCannotParseResponse = -1017;
  kCFURLErrorInternationalRoamingOff = -1018;
  kCFURLErrorCallIsActive = -1019;
  kCFURLErrorDataNotAllowed = -1020;
  kCFURLErrorRequestBodyStreamExhausted = -1021;
  kCFURLErrorAppTransportSecurityRequiresSecureConnection = -1022;
  kCFURLErrorFileDoesNotExist = -1100;
  kCFURLErrorFileIsDirectory = -1101;
  kCFURLErrorNoPermissionsToReadFile = -1102;
  kCFURLErrorDataLengthExceedsMaximum = -1103;
  kCFURLErrorSecureConnectionFailed = -1200;
  kCFURLErrorServerCertificateHasBadDate = -1201;
  kCFURLErrorServerCertificateUntrusted = -1202;
  kCFURLErrorServerCertificateHasUnknownRoot = -1203;
  kCFURLErrorServerCertificateNotYetValid = -1204;
  kCFURLErrorClientCertificateRejected = -1205;
  kCFURLErrorClientCertificateRequired = -1206;
  kCFURLErrorCannotLoadFromNetwork = -2000;
  kCFURLErrorCannotCreateFile = -3000;
  kCFURLErrorCannotOpenFile = -3001;
  kCFURLErrorCannotCloseFile = -3002;
  kCFURLErrorCannotWriteToFile = -3003;
  kCFURLErrorCannotRemoveFile = -3004;
  kCFURLErrorCannotMoveFile = -3005;
  kCFURLErrorDownloadDecodingFailedMidStream = -3006;
  kCFURLErrorDownloadDecodingFailedToComplete = -3007;
  kCFHTTPCookieCannotParseCookieFile = -4000;
  kCFNetServiceErrorUnknown = -72000;
  kCFNetServiceErrorCollision = -72001;
  kCFNetServiceErrorNotFound = -72002;
  kCFNetServiceErrorInProgress = -72003;
  kCFNetServiceErrorBadArgument = -72004;
  kCFNetServiceErrorCancel = -72005;
  kCFNetServiceErrorInvalid = -72006;
  kCFNetServiceErrorTimeout = -72007;
  kCFNetServiceErrorDNSServiceFailure = -73000;
  kCFStreamErrorSOCKSSubDomainNone = 0;
  kCFStreamErrorSOCKSSubDomainVersionCode = 1;
  kCFStreamErrorSOCKS4SubDomainResponse = 2;
  kCFStreamErrorSOCKS5SubDomainUserPass = 3;
  kCFStreamErrorSOCKS5SubDomainMethod = 4;
  kCFStreamErrorSOCKS5SubDomainResponse = 5;
  kCFStreamErrorSOCKS5BadResponseAddr = 1;
  kCFStreamErrorSOCKS5BadState = 2;
  kCFStreamErrorSOCKSUnknownClientVersion = 3;
  kCFStreamErrorSOCKS4RequestFailed = 91;
  kCFStreamErrorSOCKS4IdentdFailed = 92;
  kCFStreamErrorSOCKS4IdConflict = 93;
  kSOCKS5NoAcceptableMethod = 255;

type
  // ===== Framework typedefs =====
{$M+}
  CFStringRef = Pointer;
  CFAllocatorRef = Pointer;
  CFURLRef = Pointer;
  CFReadStreamRef = Pointer;
  CFIndex = LongInt;
  CFWriteStreamRef = Pointer;
  CFHostRef = Pointer;
  CFHostInfoType = Integer;
  CFAllocatorRetainCallBack = function(param1: Pointer): Pointer; cdecl;
  CFAllocatorReleaseCallBack = procedure(param1: Pointer); cdecl;
  CFAllocatorCopyDescriptionCallBack = function(param1: Pointer)
    : CFStringRef; cdecl;

  CFHostClientContext = record
    version: CFIndex;
    info: Pointer;
    retain: CFAllocatorRetainCallBack;
    release: CFAllocatorReleaseCallBack;
    copyDescription: CFAllocatorCopyDescriptionCallBack;
  end;

  PCFHostClientContext = ^CFHostClientContext;

  CFHostClientCallBack = procedure(param1: CFHostRef; param2: CFHostInfoType;
    param3: Pointer; param4: Pointer); cdecl;
  CFTypeID = LongWord;
  CFDataRef = Pointer;
  CFArrayRef = Pointer;
  CFRunLoopRef = Pointer;
  CFHTTPMessageRef = Pointer;
  CFDictionaryRef = Pointer;
  CFHTTPAuthenticationRef = Pointer;
  CFStreamErrorHTTPAuthentication = Integer;
  CFStreamErrorHTTP = Integer;
  CFNetDiagnosticRef = Pointer;
  CFNetDiagnosticStatusValues = Integer;
  CFNetDiagnosticStatus = CFIndex;
  CFNetServiceRef = Pointer;
  CFNetServiceMonitorRef = Pointer;
  CFNetServiceBrowserRef = Pointer;
  CFNetServicesError = Integer;
  CFNetServiceMonitorType = Integer;
  CFOptionFlags = LongWord;
  CFNetServiceRegisterFlags = CFOptionFlags;
  CFNetServiceBrowserFlags = CFOptionFlags;

  CFNetServiceClientContext = record
    version: CFIndex;
    info: Pointer;
    retain: CFAllocatorRetainCallBack;
    release: CFAllocatorReleaseCallBack;
    copyDescription: CFAllocatorCopyDescriptionCallBack;
  end;

  PCFNetServiceClientContext = ^CFNetServiceClientContext;

  CFNetServiceClientCallBack = procedure(param1: CFNetServiceRef;
    param2: Pointer; param3: Pointer); cdecl;
  CFNetServiceMonitorClientCallBack = procedure(param1: CFNetServiceMonitorRef;
    param2: CFNetServiceRef; param3: CFNetServiceMonitorType; param4: CFDataRef;
    param5: Pointer; param6: Pointer); cdecl;
  CFTypeRef = Pointer;
  CFNetServiceBrowserClientCallBack = procedure(param1: CFNetServiceBrowserRef;
    param2: CFOptionFlags; param3: CFTypeRef; param4: Pointer;
    param5: Pointer); cdecl;
  CFTimeInterval = Double;
  CFNetworkErrors = Integer;
  CFErrorRef = Pointer;
  CFProxyAutoConfigurationResultCallback = procedure(param1: Pointer;
    param2: CFArrayRef; param3: CFErrorRef); cdecl;
  CFRunLoopSourceRef = Pointer;
  // ===== Exported string consts =====

function kCFStreamErrorDomainFTP: Pointer;
function kCFStreamPropertyFTPUserName: Pointer;
function kCFStreamPropertyFTPPassword: Pointer;
function kCFStreamPropertyFTPUsePassiveMode: Pointer;
function kCFStreamPropertyFTPResourceSize: Pointer;
function kCFStreamPropertyFTPFetchResourceInfo: Pointer;
function kCFStreamPropertyFTPFileTransferOffset: Pointer;
function kCFStreamPropertyFTPAttemptPersistentConnection: Pointer;
function kCFStreamPropertyFTPProxy: Pointer;
function kCFStreamPropertyFTPProxyHost: Pointer;
function kCFStreamPropertyFTPProxyPort: Pointer;
function kCFStreamPropertyFTPProxyUser: Pointer;
function kCFStreamPropertyFTPProxyPassword: Pointer;
function kCFFTPResourceMode: Pointer;
function kCFFTPResourceName: Pointer;
function kCFFTPResourceOwner: Pointer;
function kCFFTPResourceGroup: Pointer;
function kCFFTPResourceLink: Pointer;
function kCFFTPResourceSize: Pointer;
function kCFFTPResourceType: Pointer;
function kCFFTPResourceModDate: Pointer;
function kCFStreamErrorDomainNetDB: Pointer;
function kCFStreamErrorDomainSystemConfiguration: Pointer;
function kCFHTTPVersion1_0: Pointer;
function kCFHTTPVersion1_1: Pointer;
function kCFHTTPVersion2_0: Pointer;
function kCFHTTPAuthenticationSchemeBasic: Pointer;
function kCFHTTPAuthenticationSchemeDigest: Pointer;
function kCFHTTPAuthenticationSchemeNTLM: Pointer;
function kCFHTTPAuthenticationSchemeKerberos: Pointer;
function kCFHTTPAuthenticationSchemeNegotiate: Pointer;
function kCFHTTPAuthenticationSchemeNegotiate2: Pointer;
function kCFHTTPAuthenticationSchemeXMobileMeAuthToken: Pointer;
function kCFHTTPAuthenticationSchemeOAuth1: Pointer;
function kCFHTTPAuthenticationUsername: Pointer;
function kCFHTTPAuthenticationPassword: Pointer;
function kCFHTTPAuthenticationAccountDomain: Pointer;
function kCFStreamErrorDomainHTTP: Pointer;
function kCFStreamPropertyHTTPResponseHeader: Pointer;
function kCFStreamPropertyHTTPFinalURL: Pointer;
function kCFStreamPropertyHTTPFinalRequest: Pointer;
function kCFStreamPropertyHTTPProxy: Pointer;
function kCFStreamPropertyHTTPProxyHost: Pointer;
function kCFStreamPropertyHTTPProxyPort: Pointer;
function kCFStreamPropertyHTTPSProxyHost: Pointer;
function kCFStreamPropertyHTTPSProxyPort: Pointer;
function kCFStreamPropertyHTTPShouldAutoredirect: Pointer;
function kCFStreamPropertyHTTPAttemptPersistentConnection: Pointer;
function kCFStreamPropertyHTTPRequestBytesWrittenCount: Pointer;
function kCFStreamErrorDomainMach: Pointer;
function kCFStreamErrorDomainNetServices: Pointer;
function kCFErrorDomainCFNetwork: Pointer;
function kCFErrorDomainWinSock: Pointer;
function kCFURLErrorFailingURLErrorKey: Pointer;
function kCFURLErrorFailingURLStringErrorKey: Pointer;
function kCFGetAddrInfoFailureKey: Pointer;
function kCFSOCKSStatusCodeKey: Pointer;
function kCFSOCKSVersionKey: Pointer;
function kCFSOCKSNegotiationMethodKey: Pointer;
function kCFDNSServiceFailureKey: Pointer;
function kCFFTPStatusCodeKey: Pointer;
function kCFStreamPropertySSLContext: Pointer;
function kCFStreamPropertySSLPeerTrust: Pointer;
function kCFStreamSSLValidatesCertificateChain: Pointer;
function kCFStreamPropertySSLSettings: Pointer;
function kCFStreamSSLLevel: Pointer;
function kCFStreamSSLPeerName: Pointer;
function kCFStreamSSLCertificates: Pointer;
function kCFStreamSSLIsServer: Pointer;
function kCFStreamNetworkServiceType: Pointer;
function kCFStreamNetworkServiceTypeVideo: Pointer;
function kCFStreamNetworkServiceTypeVoice: Pointer;
function kCFStreamNetworkServiceTypeBackground: Pointer;
function kCFStreamNetworkServiceTypeVoIP: Pointer;
function kCFStreamPropertyNoCellular: Pointer;
function kCFStreamPropertyConnectionIsCellular: Pointer;
function kCFStreamErrorDomainWinSock: Pointer;
function kCFStreamErrorDomainSOCKS: Pointer;
function kCFStreamPropertySOCKSProxy: Pointer;
function kCFStreamPropertySOCKSProxyHost: Pointer;
function kCFStreamPropertySOCKSProxyPort: Pointer;
function kCFStreamPropertySOCKSVersion: Pointer;
function kCFStreamSocketSOCKSVersion4: Pointer;
function kCFStreamSocketSOCKSVersion5: Pointer;
function kCFStreamPropertySOCKSUser: Pointer;
function kCFStreamPropertySOCKSPassword: Pointer;
function kCFStreamPropertyProxyLocalBypass: Pointer;
function kCFStreamErrorDomainSSL: Pointer;
function kCFStreamPropertySocketSecurityLevel: Pointer;
function kCFStreamSocketSecurityLevelNone: Pointer;
function kCFStreamSocketSecurityLevelSSLv2: Pointer;
function kCFStreamSocketSecurityLevelSSLv3: Pointer;
function kCFStreamSocketSecurityLevelTLSv1: Pointer;
function kCFStreamSocketSecurityLevelNegotiatedSSL: Pointer;
function kCFStreamPropertyShouldCloseNativeSocket: Pointer;
function kCFStreamPropertySocketRemoteHost: Pointer;
function kCFStreamPropertySocketRemoteNetService: Pointer;
function kCFStreamPropertySocketExtendedBackgroundIdleMode: Pointer;
function kCFStreamPropertySSLPeerCertificates: Pointer;
function kCFStreamSSLAllowsExpiredCertificates: Pointer;
function kCFStreamSSLAllowsExpiredRoots: Pointer;
function kCFStreamSSLAllowsAnyRoot: Pointer;
function kCFProxyTypeKey: Pointer;
function kCFProxyHostNameKey: Pointer;
function kCFProxyPortNumberKey: Pointer;
function kCFProxyAutoConfigurationURLKey: Pointer;
function kCFProxyAutoConfigurationJavaScriptKey: Pointer;
function kCFProxyUsernameKey: Pointer;
function kCFProxyPasswordKey: Pointer;
function kCFProxyTypeNone: Pointer;
function kCFProxyTypeHTTP: Pointer;
function kCFProxyTypeHTTPS: Pointer;
function kCFProxyTypeSOCKS: Pointer;
function kCFProxyTypeFTP: Pointer;
function kCFProxyTypeAutoConfigurationURL: Pointer;
function kCFProxyTypeAutoConfigurationJavaScript: Pointer;
function kCFProxyAutoConfigurationHTTPResponseKey: Pointer;
function kCFNetworkProxiesExceptionsList: Pointer;
function kCFNetworkProxiesExcludeSimpleHostnames: Pointer;
function kCFNetworkProxiesFTPEnable: Pointer;
function kCFNetworkProxiesFTPPassive: Pointer;
function kCFNetworkProxiesFTPPort: Pointer;
function kCFNetworkProxiesFTPProxy: Pointer;
function kCFNetworkProxiesGopherEnable: Pointer;
function kCFNetworkProxiesGopherPort: Pointer;
function kCFNetworkProxiesGopherProxy: Pointer;
function kCFNetworkProxiesHTTPEnable: Pointer;
function kCFNetworkProxiesHTTPPort: Pointer;
function kCFNetworkProxiesHTTPProxy: Pointer;
function kCFNetworkProxiesHTTPSEnable: Pointer;
function kCFNetworkProxiesHTTPSPort: Pointer;
function kCFNetworkProxiesHTTPSProxy: Pointer;
function kCFNetworkProxiesRTSPEnable: Pointer;
function kCFNetworkProxiesRTSPPort: Pointer;
function kCFNetworkProxiesRTSPProxy: Pointer;
function kCFNetworkProxiesSOCKSEnable: Pointer;
function kCFNetworkProxiesSOCKSPort: Pointer;
function kCFNetworkProxiesSOCKSProxy: Pointer;
function kCFNetworkProxiesProxyAutoConfigEnable: Pointer;
function kCFNetworkProxiesProxyAutoConfigURLString: Pointer;
function kCFNetworkProxiesProxyAutoConfigJavaScript: Pointer;
function kCFNetworkProxiesProxyAutoDiscoveryEnable: Pointer;


// ===== External functions =====

const
  libCFNetwork = '/System/Library/Frameworks/CFNetwork.framework/CFNetwork';
function CFReadStreamCreateWithFTPURL(alloc: CFAllocatorRef; ftpURL: CFURLRef)
  : CFReadStreamRef; cdecl;
  external libCFNetwork name _PU + 'CFReadStreamCreateWithFTPURL';
function CFFTPCreateParsedResourceListing(alloc: CFAllocatorRef; buffer: PByte;
  bufferLength: CFIndex; parsed: Pointer): CFIndex; cdecl;
  external libCFNetwork name _PU + 'CFFTPCreateParsedResourceListing';
function CFWriteStreamCreateWithFTPURL(alloc: CFAllocatorRef; ftpURL: CFURLRef)
  : CFWriteStreamRef; cdecl;
  external libCFNetwork name _PU + 'CFWriteStreamCreateWithFTPURL';
function CFHostGetTypeID: CFTypeID; cdecl;
  external libCFNetwork name _PU + 'CFHostGetTypeID';
function CFHostCreateWithName(allocator: CFAllocatorRef; hostname: CFStringRef)
  : CFHostRef; cdecl; external libCFNetwork name _PU + 'CFHostCreateWithName';
function CFHostCreateWithAddress(allocator: CFAllocatorRef; addr: CFDataRef)
  : CFHostRef; cdecl; external libCFNetwork name _PU +
  'CFHostCreateWithAddress';
function CFHostCreateCopy(alloc: CFAllocatorRef; host: CFHostRef): CFHostRef;
  cdecl; external libCFNetwork name _PU + 'CFHostCreateCopy';
function CFHostStartInfoResolution(theHost: CFHostRef; info: CFHostInfoType;
  error: Pointer): Boolean; cdecl;
  external libCFNetwork name _PU + 'CFHostStartInfoResolution';
function CFHostGetAddressing(theHost: CFHostRef; hasBeenResolved: PByte)
  : CFArrayRef; cdecl; external libCFNetwork name _PU + 'CFHostGetAddressing';
function CFHostGetNames(theHost: CFHostRef; hasBeenResolved: PByte): CFArrayRef;
  cdecl; external libCFNetwork name _PU + 'CFHostGetNames';
function CFHostGetReachability(theHost: CFHostRef; hasBeenResolved: PByte)
  : CFDataRef; cdecl; external libCFNetwork name _PU + 'CFHostGetReachability';
procedure CFHostCancelInfoResolution(theHost: CFHostRef; info: CFHostInfoType);
  cdecl; external libCFNetwork name _PU + 'CFHostCancelInfoResolution';
function CFHostSetClient(theHost: CFHostRef; clientCB: CFHostClientCallBack;
  clientContext: Pointer): Boolean; cdecl;
  external libCFNetwork name _PU + 'CFHostSetClient';
procedure CFHostScheduleWithRunLoop(theHost: CFHostRef; runLoop: CFRunLoopRef;
  runLoopMode: CFStringRef); cdecl;
  external libCFNetwork name _PU + 'CFHostScheduleWithRunLoop';
procedure CFHostUnscheduleFromRunLoop(theHost: CFHostRef; runLoop: CFRunLoopRef;
  runLoopMode: CFStringRef); cdecl;
  external libCFNetwork name _PU + 'CFHostUnscheduleFromRunLoop';
function CFHTTPMessageGetTypeID: CFTypeID; cdecl;
  external libCFNetwork name _PU + 'CFHTTPMessageGetTypeID';
function CFHTTPMessageCreateRequest(alloc: CFAllocatorRef;
  requestMethod: CFStringRef; url: CFURLRef; httpVersion: CFStringRef)
  : CFHTTPMessageRef; cdecl;
  external libCFNetwork name _PU + 'CFHTTPMessageCreateRequest';
function CFHTTPMessageCreateResponse(alloc: CFAllocatorRef; statusCode: CFIndex;
  statusDescription: CFStringRef; httpVersion: CFStringRef): CFHTTPMessageRef;
  cdecl; external libCFNetwork name _PU + 'CFHTTPMessageCreateResponse';
function CFHTTPMessageCreateEmpty(alloc: CFAllocatorRef; isRequest: Boolean)
  : CFHTTPMessageRef; cdecl;
  external libCFNetwork name _PU + 'CFHTTPMessageCreateEmpty';
function CFHTTPMessageCreateCopy(alloc: CFAllocatorRef;
  message: CFHTTPMessageRef): CFHTTPMessageRef; cdecl;
  external libCFNetwork name _PU + 'CFHTTPMessageCreateCopy';
function CFHTTPMessageIsRequest(message: CFHTTPMessageRef): Boolean; cdecl;
  external libCFNetwork name _PU + 'CFHTTPMessageIsRequest';
function CFHTTPMessageCopyVersion(message: CFHTTPMessageRef): CFStringRef;
  cdecl; external libCFNetwork name _PU + 'CFHTTPMessageCopyVersion';
function CFHTTPMessageCopyBody(message: CFHTTPMessageRef): CFDataRef; cdecl;
  external libCFNetwork name _PU + 'CFHTTPMessageCopyBody';
procedure CFHTTPMessageSetBody(message: CFHTTPMessageRef; bodyData: CFDataRef);
  cdecl; external libCFNetwork name _PU + 'CFHTTPMessageSetBody';
function CFHTTPMessageCopyHeaderFieldValue(message: CFHTTPMessageRef;
  headerField: CFStringRef): CFStringRef; cdecl;
  external libCFNetwork name _PU + 'CFHTTPMessageCopyHeaderFieldValue';
function CFHTTPMessageCopyAllHeaderFields(message: CFHTTPMessageRef)
  : CFDictionaryRef; cdecl;
  external libCFNetwork name _PU + 'CFHTTPMessageCopyAllHeaderFields';
procedure CFHTTPMessageSetHeaderFieldValue(message: CFHTTPMessageRef;
  headerField: CFStringRef; value: CFStringRef); cdecl;
  external libCFNetwork name _PU + 'CFHTTPMessageSetHeaderFieldValue';
function CFHTTPMessageAppendBytes(message: CFHTTPMessageRef; newBytes: PByte;
  numBytes: CFIndex): Boolean; cdecl;
  external libCFNetwork name _PU + 'CFHTTPMessageAppendBytes';
function CFHTTPMessageIsHeaderComplete(message: CFHTTPMessageRef): Boolean;
  cdecl; external libCFNetwork name _PU + 'CFHTTPMessageIsHeaderComplete';
function CFHTTPMessageCopySerializedMessage(message: CFHTTPMessageRef)
  : CFDataRef; cdecl; external libCFNetwork name _PU +
  'CFHTTPMessageCopySerializedMessage';
function CFHTTPMessageCopyRequestURL(request: CFHTTPMessageRef): CFURLRef;
  cdecl; external libCFNetwork name _PU + 'CFHTTPMessageCopyRequestURL';
function CFHTTPMessageCopyRequestMethod(request: CFHTTPMessageRef): CFStringRef;
  cdecl; external libCFNetwork name _PU + 'CFHTTPMessageCopyRequestMethod';
function CFHTTPMessageAddAuthentication(request: CFHTTPMessageRef;
  authenticationFailureResponse: CFHTTPMessageRef; username: CFStringRef;
  password: CFStringRef; authenticationScheme: CFStringRef; forProxy: Boolean)
  : Boolean; cdecl; external libCFNetwork name _PU +
  'CFHTTPMessageAddAuthentication';
function CFHTTPMessageGetResponseStatusCode(response: CFHTTPMessageRef)
  : CFIndex; cdecl; external libCFNetwork name _PU +
  'CFHTTPMessageGetResponseStatusCode';
function CFHTTPMessageCopyResponseStatusLine(response: CFHTTPMessageRef)
  : CFStringRef; cdecl; external libCFNetwork name _PU +
  'CFHTTPMessageCopyResponseStatusLine';
function CFHTTPAuthenticationGetTypeID: CFTypeID; cdecl;
  external libCFNetwork name _PU + 'CFHTTPAuthenticationGetTypeID';
function CFHTTPAuthenticationCreateFromResponse(alloc: CFAllocatorRef;
  response: CFHTTPMessageRef): CFHTTPAuthenticationRef; cdecl;
  external libCFNetwork name _PU + 'CFHTTPAuthenticationCreateFromResponse';
function CFHTTPAuthenticationIsValid(auth: CFHTTPAuthenticationRef;
  error: Pointer): Boolean; cdecl;
  external libCFNetwork name _PU + 'CFHTTPAuthenticationIsValid';
function CFHTTPAuthenticationAppliesToRequest(auth: CFHTTPAuthenticationRef;
  request: CFHTTPMessageRef): Boolean; cdecl;
  external libCFNetwork name _PU + 'CFHTTPAuthenticationAppliesToRequest';
function CFHTTPAuthenticationRequiresOrderedRequests
  (auth: CFHTTPAuthenticationRef): Boolean; cdecl;
  external libCFNetwork name _PU +
  'CFHTTPAuthenticationRequiresOrderedRequests';
function CFHTTPMessageApplyCredentials(request: CFHTTPMessageRef;
  auth: CFHTTPAuthenticationRef; username: CFStringRef; password: CFStringRef;
  error: Pointer): Boolean; cdecl;
  external libCFNetwork name _PU + 'CFHTTPMessageApplyCredentials';
function CFHTTPMessageApplyCredentialDictionary(request: CFHTTPMessageRef;
  auth: CFHTTPAuthenticationRef; dict: CFDictionaryRef; error: Pointer)
  : Boolean; cdecl; external libCFNetwork name _PU +
  'CFHTTPMessageApplyCredentialDictionary';
function CFHTTPAuthenticationCopyRealm(auth: CFHTTPAuthenticationRef)
  : CFStringRef; cdecl; external libCFNetwork name _PU +
  'CFHTTPAuthenticationCopyRealm';
function CFHTTPAuthenticationCopyDomains(auth: CFHTTPAuthenticationRef)
  : CFArrayRef; cdecl; external libCFNetwork name _PU +
  'CFHTTPAuthenticationCopyDomains';
function CFHTTPAuthenticationCopyMethod(auth: CFHTTPAuthenticationRef)
  : CFStringRef; cdecl; external libCFNetwork name _PU +
  'CFHTTPAuthenticationCopyMethod';
function CFHTTPAuthenticationRequiresUserNameAndPassword
  (auth: CFHTTPAuthenticationRef): Boolean; cdecl;
  external libCFNetwork name _PU +
  'CFHTTPAuthenticationRequiresUserNameAndPassword';
function CFHTTPAuthenticationRequiresAccountDomain
  (auth: CFHTTPAuthenticationRef): Boolean; cdecl;
  external libCFNetwork name _PU + 'CFHTTPAuthenticationRequiresAccountDomain';
function CFReadStreamCreateForHTTPRequest(alloc: CFAllocatorRef;
  request: CFHTTPMessageRef): CFReadStreamRef; cdecl;
  external libCFNetwork name _PU + 'CFReadStreamCreateForHTTPRequest';
function CFReadStreamCreateForStreamedHTTPRequest(alloc: CFAllocatorRef;
  requestHeaders: CFHTTPMessageRef; requestBody: CFReadStreamRef)
  : CFReadStreamRef; cdecl;
  external libCFNetwork name _PU + 'CFReadStreamCreateForStreamedHTTPRequest';
procedure CFHTTPReadStreamSetRedirectsAutomatically(httpStream: CFReadStreamRef;
  shouldAutoRedirect: Boolean); cdecl;
  external libCFNetwork name _PU + 'CFHTTPReadStreamSetRedirectsAutomatically';
function CFNetDiagnosticCreateWithStreams(alloc: CFAllocatorRef;
  readStream: CFReadStreamRef; writeStream: CFWriteStreamRef)
  : CFNetDiagnosticRef; cdecl;
  external libCFNetwork name _PU + 'CFNetDiagnosticCreateWithStreams';
function CFNetDiagnosticCreateWithURL(alloc: CFAllocatorRef; url: CFURLRef)
  : CFNetDiagnosticRef; cdecl;
  external libCFNetwork name _PU + 'CFNetDiagnosticCreateWithURL';
procedure CFNetDiagnosticSetName(details: CFNetDiagnosticRef;
  name: CFStringRef); cdecl;
  external libCFNetwork name _PU + 'CFNetDiagnosticSetName';
function CFNetDiagnosticDiagnoseProblemInteractively
  (details: CFNetDiagnosticRef): CFNetDiagnosticStatus; cdecl;
  external libCFNetwork name _PU +
  'CFNetDiagnosticDiagnoseProblemInteractively';
function CFNetDiagnosticCopyNetworkStatusPassively(details: CFNetDiagnosticRef;
  description: Pointer): CFNetDiagnosticStatus; cdecl;
  external libCFNetwork name _PU + 'CFNetDiagnosticCopyNetworkStatusPassively';
function CFNetServiceGetTypeID: CFTypeID; cdecl;
  external libCFNetwork name _PU + 'CFNetServiceGetTypeID';
function CFNetServiceMonitorGetTypeID: CFTypeID; cdecl;
  external libCFNetwork name _PU + 'CFNetServiceMonitorGetTypeID';
function CFNetServiceBrowserGetTypeID: CFTypeID; cdecl;
  external libCFNetwork name _PU + 'CFNetServiceBrowserGetTypeID';
function CFNetServiceCreate(alloc: CFAllocatorRef; domain: CFStringRef;
  serviceType: CFStringRef; name: CFStringRef; port: Int32): CFNetServiceRef;
  cdecl; external libCFNetwork name _PU + 'CFNetServiceCreate';
function CFNetServiceCreateCopy(alloc: CFAllocatorRef; service: CFNetServiceRef)
  : CFNetServiceRef; cdecl;
  external libCFNetwork name _PU + 'CFNetServiceCreateCopy';
function CFNetServiceGetDomain(theService: CFNetServiceRef): CFStringRef; cdecl;
  external libCFNetwork name _PU + 'CFNetServiceGetDomain';
function CFNetServiceGetType(theService: CFNetServiceRef): CFStringRef; cdecl;
  external libCFNetwork name _PU + 'CFNetServiceGetType';
function CFNetServiceGetName(theService: CFNetServiceRef): CFStringRef; cdecl;
  external libCFNetwork name _PU + 'CFNetServiceGetName';
function CFNetServiceRegisterWithOptions(theService: CFNetServiceRef;
  options: CFOptionFlags; error: Pointer): Boolean; cdecl;
  external libCFNetwork name _PU + 'CFNetServiceRegisterWithOptions';
function CFNetServiceResolveWithTimeout(theService: CFNetServiceRef;
  timeout: CFTimeInterval; error: Pointer): Boolean; cdecl;
  external libCFNetwork name _PU + 'CFNetServiceResolveWithTimeout';
procedure CFNetServiceCancel(theService: CFNetServiceRef); cdecl;
  external libCFNetwork name _PU + 'CFNetServiceCancel';
function CFNetServiceGetTargetHost(theService: CFNetServiceRef): CFStringRef;
  cdecl; external libCFNetwork name _PU + 'CFNetServiceGetTargetHost';
function CFNetServiceGetPortNumber(theService: CFNetServiceRef): Int32; cdecl;
  external libCFNetwork name _PU + 'CFNetServiceGetPortNumber';
function CFNetServiceGetAddressing(theService: CFNetServiceRef): CFArrayRef;
  cdecl; external libCFNetwork name _PU + 'CFNetServiceGetAddressing';
function CFNetServiceGetTXTData(theService: CFNetServiceRef): CFDataRef; cdecl;
  external libCFNetwork name _PU + 'CFNetServiceGetTXTData';
function CFNetServiceSetTXTData(theService: CFNetServiceRef;
  txtRecord: CFDataRef): Boolean; cdecl;
  external libCFNetwork name _PU + 'CFNetServiceSetTXTData';
function CFNetServiceCreateDictionaryWithTXTData(alloc: CFAllocatorRef;
  txtRecord: CFDataRef): CFDictionaryRef; cdecl;
  external libCFNetwork name _PU + 'CFNetServiceCreateDictionaryWithTXTData';
function CFNetServiceCreateTXTDataWithDictionary(alloc: CFAllocatorRef;
  keyValuePairs: CFDictionaryRef): CFDataRef; cdecl;
  external libCFNetwork name _PU + 'CFNetServiceCreateTXTDataWithDictionary';
function CFNetServiceSetClient(theService: CFNetServiceRef;
  clientCB: CFNetServiceClientCallBack; clientContext: Pointer): Boolean; cdecl;
  external libCFNetwork name _PU + 'CFNetServiceSetClient';
procedure CFNetServiceScheduleWithRunLoop(theService: CFNetServiceRef;
  runLoop: CFRunLoopRef; runLoopMode: CFStringRef); cdecl;
  external libCFNetwork name _PU + 'CFNetServiceScheduleWithRunLoop';
procedure CFNetServiceUnscheduleFromRunLoop(theService: CFNetServiceRef;
  runLoop: CFRunLoopRef; runLoopMode: CFStringRef); cdecl;
  external libCFNetwork name _PU + 'CFNetServiceUnscheduleFromRunLoop';
function CFNetServiceMonitorCreate(alloc: CFAllocatorRef;
  theService: CFNetServiceRef; clientCB: CFNetServiceMonitorClientCallBack;
  clientContext: Pointer): CFNetServiceMonitorRef; cdecl;
  external libCFNetwork name _PU + 'CFNetServiceMonitorCreate';
procedure CFNetServiceMonitorInvalidate(monitor: CFNetServiceMonitorRef); cdecl;
  external libCFNetwork name _PU + 'CFNetServiceMonitorInvalidate';
function CFNetServiceMonitorStart(monitor: CFNetServiceMonitorRef;
  recordType: CFNetServiceMonitorType; error: Pointer): Boolean; cdecl;
  external libCFNetwork name _PU + 'CFNetServiceMonitorStart';
procedure CFNetServiceMonitorStop(monitor: CFNetServiceMonitorRef;
  error: Pointer); cdecl; external libCFNetwork name _PU +
  'CFNetServiceMonitorStop';
procedure CFNetServiceMonitorScheduleWithRunLoop
  (monitor: CFNetServiceMonitorRef; runLoop: CFRunLoopRef;
  runLoopMode: CFStringRef); cdecl;
  external libCFNetwork name _PU + 'CFNetServiceMonitorScheduleWithRunLoop';
procedure CFNetServiceMonitorUnscheduleFromRunLoop
  (monitor: CFNetServiceMonitorRef; runLoop: CFRunLoopRef;
  runLoopMode: CFStringRef); cdecl;
  external libCFNetwork name _PU + 'CFNetServiceMonitorUnscheduleFromRunLoop';
function CFNetServiceBrowserCreate(alloc: CFAllocatorRef;
  clientCB: CFNetServiceBrowserClientCallBack; clientContext: Pointer)
  : CFNetServiceBrowserRef; cdecl;
  external libCFNetwork name _PU + 'CFNetServiceBrowserCreate';
procedure CFNetServiceBrowserInvalidate(browser: CFNetServiceBrowserRef); cdecl;
  external libCFNetwork name _PU + 'CFNetServiceBrowserInvalidate';
function CFNetServiceBrowserSearchForDomains(browser: CFNetServiceBrowserRef;
  registrationDomains: Boolean; error: Pointer): Boolean; cdecl;
  external libCFNetwork name _PU + 'CFNetServiceBrowserSearchForDomains';
function CFNetServiceBrowserSearchForServices(browser: CFNetServiceBrowserRef;
  domain: CFStringRef; serviceType: CFStringRef; error: Pointer): Boolean;
  cdecl; external libCFNetwork name _PU +
  'CFNetServiceBrowserSearchForServices';
procedure CFNetServiceBrowserStopSearch(browser: CFNetServiceBrowserRef;
  error: Pointer); cdecl; external libCFNetwork name _PU +
  'CFNetServiceBrowserStopSearch';
procedure CFNetServiceBrowserScheduleWithRunLoop
  (browser: CFNetServiceBrowserRef; runLoop: CFRunLoopRef;
  runLoopMode: CFStringRef); cdecl;
  external libCFNetwork name _PU + 'CFNetServiceBrowserScheduleWithRunLoop';
procedure CFNetServiceBrowserUnscheduleFromRunLoop
  (browser: CFNetServiceBrowserRef; runLoop: CFRunLoopRef;
  runLoopMode: CFStringRef); cdecl;
  external libCFNetwork name _PU + 'CFNetServiceBrowserUnscheduleFromRunLoop';
function CFNetServiceRegister(theService: CFNetServiceRef; error: Pointer)
  : Boolean; cdecl; external libCFNetwork name _PU + 'CFNetServiceRegister';
function CFNetServiceResolve(theService: CFNetServiceRef; error: Pointer)
  : Boolean; cdecl; external libCFNetwork name _PU + 'CFNetServiceResolve';
function CFNetServiceGetProtocolSpecificInformation(theService: CFNetServiceRef)
  : CFStringRef; cdecl; external libCFNetwork name _PU +
  'CFNetServiceGetProtocolSpecificInformation';
procedure CFNetServiceSetProtocolSpecificInformation
  (theService: CFNetServiceRef; theInfo: CFStringRef); cdecl;
  external libCFNetwork name _PU + 'CFNetServiceSetProtocolSpecificInformation';
function CFSocketStreamSOCKSGetErrorSubdomain(error: Pointer): Int32; cdecl;
  external libCFNetwork name _PU + 'CFSocketStreamSOCKSGetErrorSubdomain';
function CFSocketStreamSOCKSGetError(error: Pointer): Int32; cdecl;
  external libCFNetwork name _PU + 'CFSocketStreamSOCKSGetError';
procedure CFStreamCreatePairWithSocketToCFHost(alloc: CFAllocatorRef;
  host: CFHostRef; port: Int32; readStream: Pointer; writeStream: Pointer);
  cdecl; external libCFNetwork name _PU +
  'CFStreamCreatePairWithSocketToCFHost';
procedure CFStreamCreatePairWithSocketToNetService(alloc: CFAllocatorRef;
  service: CFNetServiceRef; readStream: Pointer; writeStream: Pointer); cdecl;
  external libCFNetwork name _PU + 'CFStreamCreatePairWithSocketToNetService';
function CFNetworkCopySystemProxySettings: CFDictionaryRef; cdecl;
  external libCFNetwork name _PU + 'CFNetworkCopySystemProxySettings';
function CFNetworkCopyProxiesForURL(url: CFURLRef;
  proxySettings: CFDictionaryRef): CFArrayRef; cdecl;
  external libCFNetwork name _PU + 'CFNetworkCopyProxiesForURL';
function CFNetworkCopyProxiesForAutoConfigurationScript
  (proxyAutoConfigurationScript: CFStringRef; targetURL: CFURLRef;
  error: Pointer): CFArrayRef; cdecl;
  external libCFNetwork name _PU +
  'CFNetworkCopyProxiesForAutoConfigurationScript';
function CFNetworkExecuteProxyAutoConfigurationScript
  (proxyAutoConfigurationScript: CFStringRef; targetURL: CFURLRef;
  cb: CFProxyAutoConfigurationResultCallback; clientContext: Pointer)
  : CFRunLoopSourceRef; cdecl;
  external libCFNetwork name _PU +
  'CFNetworkExecuteProxyAutoConfigurationScript';
function CFNetworkExecuteProxyAutoConfigurationURL(proxyAutoConfigURL: CFURLRef;
  targetURL: CFURLRef; cb: CFProxyAutoConfigurationResultCallback;
  clientContext: Pointer): CFRunLoopSourceRef; cdecl;
  external libCFNetwork name _PU + 'CFNetworkExecuteProxyAutoConfigurationURL';

implementation

{$IF defined(IOS) and NOT defined(CPUARM)}

uses
  Posix.Dlfcn;

var
  CFNetworkModule: THandle;

{$ENDIF IOS}

function kCFStreamErrorDomainFTP: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork, 'kCFStreamErrorDomainFTP');
end;

function kCFStreamPropertyFTPUserName: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork, 'kCFStreamPropertyFTPUserName');
end;

function kCFStreamPropertyFTPPassword: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork, 'kCFStreamPropertyFTPPassword');
end;

function kCFStreamPropertyFTPUsePassiveMode: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork,
    'kCFStreamPropertyFTPUsePassiveMode');
end;

function kCFStreamPropertyFTPResourceSize: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork, 'kCFStreamPropertyFTPResourceSize');
end;

function kCFStreamPropertyFTPFetchResourceInfo: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork,
    'kCFStreamPropertyFTPFetchResourceInfo');
end;

function kCFStreamPropertyFTPFileTransferOffset: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork,
    'kCFStreamPropertyFTPFileTransferOffset');
end;

function kCFStreamPropertyFTPAttemptPersistentConnection: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork,
    'kCFStreamPropertyFTPAttemptPersistentConnection');
end;

function kCFStreamPropertyFTPProxy: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork, 'kCFStreamPropertyFTPProxy');
end;

function kCFStreamPropertyFTPProxyHost: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork, 'kCFStreamPropertyFTPProxyHost');
end;

function kCFStreamPropertyFTPProxyPort: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork, 'kCFStreamPropertyFTPProxyPort');
end;

function kCFStreamPropertyFTPProxyUser: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork, 'kCFStreamPropertyFTPProxyUser');
end;

function kCFStreamPropertyFTPProxyPassword: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork,
    'kCFStreamPropertyFTPProxyPassword');
end;

function kCFFTPResourceMode: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork, 'kCFFTPResourceMode');
end;

function kCFFTPResourceName: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork, 'kCFFTPResourceName');
end;

function kCFFTPResourceOwner: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork, 'kCFFTPResourceOwner');
end;

function kCFFTPResourceGroup: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork, 'kCFFTPResourceGroup');
end;

function kCFFTPResourceLink: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork, 'kCFFTPResourceLink');
end;

function kCFFTPResourceSize: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork, 'kCFFTPResourceSize');
end;

function kCFFTPResourceType: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork, 'kCFFTPResourceType');
end;

function kCFFTPResourceModDate: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork, 'kCFFTPResourceModDate');
end;

function kCFStreamErrorDomainNetDB: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork, 'kCFStreamErrorDomainNetDB');
end;

function kCFStreamErrorDomainSystemConfiguration: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork,
    'kCFStreamErrorDomainSystemConfiguration');
end;

function kCFHTTPVersion1_0: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork, 'kCFHTTPVersion1_0');
end;

function kCFHTTPVersion1_1: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork, 'kCFHTTPVersion1_1');
end;

function kCFHTTPVersion2_0: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork, 'kCFHTTPVersion2_0');
end;

function kCFHTTPAuthenticationSchemeBasic: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork, 'kCFHTTPAuthenticationSchemeBasic');
end;

function kCFHTTPAuthenticationSchemeDigest: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork,
    'kCFHTTPAuthenticationSchemeDigest');
end;

function kCFHTTPAuthenticationSchemeNTLM: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork, 'kCFHTTPAuthenticationSchemeNTLM');
end;

function kCFHTTPAuthenticationSchemeKerberos: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork,
    'kCFHTTPAuthenticationSchemeKerberos');
end;

function kCFHTTPAuthenticationSchemeNegotiate: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork,
    'kCFHTTPAuthenticationSchemeNegotiate');
end;

function kCFHTTPAuthenticationSchemeNegotiate2: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork,
    'kCFHTTPAuthenticationSchemeNegotiate2');
end;

function kCFHTTPAuthenticationSchemeXMobileMeAuthToken: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork,
    'kCFHTTPAuthenticationSchemeXMobileMeAuthToken');
end;

function kCFHTTPAuthenticationSchemeOAuth1: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork,
    'kCFHTTPAuthenticationSchemeOAuth1');
end;

function kCFHTTPAuthenticationUsername: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork, 'kCFHTTPAuthenticationUsername');
end;

function kCFHTTPAuthenticationPassword: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork, 'kCFHTTPAuthenticationPassword');
end;

function kCFHTTPAuthenticationAccountDomain: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork,
    'kCFHTTPAuthenticationAccountDomain');
end;

function kCFStreamErrorDomainHTTP: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork, 'kCFStreamErrorDomainHTTP');
end;

function kCFStreamPropertyHTTPResponseHeader: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork,
    'kCFStreamPropertyHTTPResponseHeader');
end;

function kCFStreamPropertyHTTPFinalURL: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork, 'kCFStreamPropertyHTTPFinalURL');
end;

function kCFStreamPropertyHTTPFinalRequest: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork,
    'kCFStreamPropertyHTTPFinalRequest');
end;

function kCFStreamPropertyHTTPProxy: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork, 'kCFStreamPropertyHTTPProxy');
end;

function kCFStreamPropertyHTTPProxyHost: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork, 'kCFStreamPropertyHTTPProxyHost');
end;

function kCFStreamPropertyHTTPProxyPort: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork, 'kCFStreamPropertyHTTPProxyPort');
end;

function kCFStreamPropertyHTTPSProxyHost: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork, 'kCFStreamPropertyHTTPSProxyHost');
end;

function kCFStreamPropertyHTTPSProxyPort: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork, 'kCFStreamPropertyHTTPSProxyPort');
end;

function kCFStreamPropertyHTTPShouldAutoredirect: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork,
    'kCFStreamPropertyHTTPShouldAutoredirect');
end;

function kCFStreamPropertyHTTPAttemptPersistentConnection: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork,
    'kCFStreamPropertyHTTPAttemptPersistentConnection');
end;

function kCFStreamPropertyHTTPRequestBytesWrittenCount: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork,
    'kCFStreamPropertyHTTPRequestBytesWrittenCount');
end;

function kCFStreamErrorDomainMach: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork, 'kCFStreamErrorDomainMach');
end;

function kCFStreamErrorDomainNetServices: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork, 'kCFStreamErrorDomainNetServices');
end;

function kCFErrorDomainCFNetwork: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork, 'kCFErrorDomainCFNetwork');
end;

function kCFErrorDomainWinSock: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork, 'kCFErrorDomainWinSock');
end;

function kCFURLErrorFailingURLErrorKey: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork, 'kCFURLErrorFailingURLErrorKey');
end;

function kCFURLErrorFailingURLStringErrorKey: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork,
    'kCFURLErrorFailingURLStringErrorKey');
end;

function kCFGetAddrInfoFailureKey: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork, 'kCFGetAddrInfoFailureKey');
end;

function kCFSOCKSStatusCodeKey: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork, 'kCFSOCKSStatusCodeKey');
end;

function kCFSOCKSVersionKey: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork, 'kCFSOCKSVersionKey');
end;

function kCFSOCKSNegotiationMethodKey: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork, 'kCFSOCKSNegotiationMethodKey');
end;

function kCFDNSServiceFailureKey: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork, 'kCFDNSServiceFailureKey');
end;

function kCFFTPStatusCodeKey: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork, 'kCFFTPStatusCodeKey');
end;

function kCFStreamPropertySSLContext: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork, 'kCFStreamPropertySSLContext');
end;

function kCFStreamPropertySSLPeerTrust: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork, 'kCFStreamPropertySSLPeerTrust');
end;

function kCFStreamSSLValidatesCertificateChain: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork,
    'kCFStreamSSLValidatesCertificateChain');
end;

function kCFStreamPropertySSLSettings: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork, 'kCFStreamPropertySSLSettings');
end;

function kCFStreamSSLLevel: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork, 'kCFStreamSSLLevel');
end;

function kCFStreamSSLPeerName: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork, 'kCFStreamSSLPeerName');
end;

function kCFStreamSSLCertificates: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork, 'kCFStreamSSLCertificates');
end;

function kCFStreamSSLIsServer: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork, 'kCFStreamSSLIsServer');
end;

function kCFStreamNetworkServiceType: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork, 'kCFStreamNetworkServiceType');
end;

function kCFStreamNetworkServiceTypeVideo: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork, 'kCFStreamNetworkServiceTypeVideo');
end;

function kCFStreamNetworkServiceTypeVoice: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork, 'kCFStreamNetworkServiceTypeVoice');
end;

function kCFStreamNetworkServiceTypeBackground: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork,
    'kCFStreamNetworkServiceTypeBackground');
end;

function kCFStreamNetworkServiceTypeVoIP: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork, 'kCFStreamNetworkServiceTypeVoIP');
end;

function kCFStreamPropertyNoCellular: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork, 'kCFStreamPropertyNoCellular');
end;

function kCFStreamPropertyConnectionIsCellular: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork,
    'kCFStreamPropertyConnectionIsCellular');
end;

function kCFStreamErrorDomainWinSock: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork, 'kCFStreamErrorDomainWinSock');
end;

function kCFStreamErrorDomainSOCKS: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork, 'kCFStreamErrorDomainSOCKS');
end;

function kCFStreamPropertySOCKSProxy: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork, 'kCFStreamPropertySOCKSProxy');
end;

function kCFStreamPropertySOCKSProxyHost: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork, 'kCFStreamPropertySOCKSProxyHost');
end;

function kCFStreamPropertySOCKSProxyPort: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork, 'kCFStreamPropertySOCKSProxyPort');
end;

function kCFStreamPropertySOCKSVersion: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork, 'kCFStreamPropertySOCKSVersion');
end;

function kCFStreamSocketSOCKSVersion4: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork, 'kCFStreamSocketSOCKSVersion4');
end;

function kCFStreamSocketSOCKSVersion5: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork, 'kCFStreamSocketSOCKSVersion5');
end;

function kCFStreamPropertySOCKSUser: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork, 'kCFStreamPropertySOCKSUser');
end;

function kCFStreamPropertySOCKSPassword: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork, 'kCFStreamPropertySOCKSPassword');
end;

function kCFStreamPropertyProxyLocalBypass: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork,
    'kCFStreamPropertyProxyLocalBypass');
end;

function kCFStreamErrorDomainSSL: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork, 'kCFStreamErrorDomainSSL');
end;

function kCFStreamPropertySocketSecurityLevel: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork,
    'kCFStreamPropertySocketSecurityLevel');
end;

function kCFStreamSocketSecurityLevelNone: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork, 'kCFStreamSocketSecurityLevelNone');
end;

function kCFStreamSocketSecurityLevelSSLv2: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork,
    'kCFStreamSocketSecurityLevelSSLv2');
end;

function kCFStreamSocketSecurityLevelSSLv3: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork,
    'kCFStreamSocketSecurityLevelSSLv3');
end;

function kCFStreamSocketSecurityLevelTLSv1: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork,
    'kCFStreamSocketSecurityLevelTLSv1');
end;

function kCFStreamSocketSecurityLevelNegotiatedSSL: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork,
    'kCFStreamSocketSecurityLevelNegotiatedSSL');
end;

function kCFStreamPropertyShouldCloseNativeSocket: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork,
    'kCFStreamPropertyShouldCloseNativeSocket');
end;

function kCFStreamPropertySocketRemoteHost: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork,
    'kCFStreamPropertySocketRemoteHost');
end;

function kCFStreamPropertySocketRemoteNetService: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork,
    'kCFStreamPropertySocketRemoteNetService');
end;

function kCFStreamPropertySocketExtendedBackgroundIdleMode: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork,
    'kCFStreamPropertySocketExtendedBackgroundIdleMode');
end;

function kCFStreamPropertySSLPeerCertificates: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork,
    'kCFStreamPropertySSLPeerCertificates');
end;

function kCFStreamSSLAllowsExpiredCertificates: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork,
    'kCFStreamSSLAllowsExpiredCertificates');
end;

function kCFStreamSSLAllowsExpiredRoots: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork, 'kCFStreamSSLAllowsExpiredRoots');
end;

function kCFStreamSSLAllowsAnyRoot: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork, 'kCFStreamSSLAllowsAnyRoot');
end;

function kCFProxyTypeKey: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork, 'kCFProxyTypeKey');
end;

function kCFProxyHostNameKey: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork, 'kCFProxyHostNameKey');
end;

function kCFProxyPortNumberKey: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork, 'kCFProxyPortNumberKey');
end;

function kCFProxyAutoConfigurationURLKey: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork, 'kCFProxyAutoConfigurationURLKey');
end;

function kCFProxyAutoConfigurationJavaScriptKey: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork,
    'kCFProxyAutoConfigurationJavaScriptKey');
end;

function kCFProxyUsernameKey: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork, 'kCFProxyUsernameKey');
end;

function kCFProxyPasswordKey: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork, 'kCFProxyPasswordKey');
end;

function kCFProxyTypeNone: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork, 'kCFProxyTypeNone');
end;

function kCFProxyTypeHTTP: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork, 'kCFProxyTypeHTTP');
end;

function kCFProxyTypeHTTPS: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork, 'kCFProxyTypeHTTPS');
end;

function kCFProxyTypeSOCKS: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork, 'kCFProxyTypeSOCKS');
end;

function kCFProxyTypeFTP: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork, 'kCFProxyTypeFTP');
end;

function kCFProxyTypeAutoConfigurationURL: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork, 'kCFProxyTypeAutoConfigurationURL');
end;

function kCFProxyTypeAutoConfigurationJavaScript: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork,
    'kCFProxyTypeAutoConfigurationJavaScript');
end;

function kCFProxyAutoConfigurationHTTPResponseKey: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork,
    'kCFProxyAutoConfigurationHTTPResponseKey');
end;

function kCFNetworkProxiesExceptionsList: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork, 'kCFNetworkProxiesExceptionsList');
end;

function kCFNetworkProxiesExcludeSimpleHostnames: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork,
    'kCFNetworkProxiesExcludeSimpleHostnames');
end;

function kCFNetworkProxiesFTPEnable: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork, 'kCFNetworkProxiesFTPEnable');
end;

function kCFNetworkProxiesFTPPassive: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork, 'kCFNetworkProxiesFTPPassive');
end;

function kCFNetworkProxiesFTPPort: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork, 'kCFNetworkProxiesFTPPort');
end;

function kCFNetworkProxiesFTPProxy: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork, 'kCFNetworkProxiesFTPProxy');
end;

function kCFNetworkProxiesGopherEnable: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork, 'kCFNetworkProxiesGopherEnable');
end;

function kCFNetworkProxiesGopherPort: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork, 'kCFNetworkProxiesGopherPort');
end;

function kCFNetworkProxiesGopherProxy: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork, 'kCFNetworkProxiesGopherProxy');
end;

function kCFNetworkProxiesHTTPEnable: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork, 'kCFNetworkProxiesHTTPEnable');
end;

function kCFNetworkProxiesHTTPPort: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork, 'kCFNetworkProxiesHTTPPort');
end;

function kCFNetworkProxiesHTTPProxy: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork, 'kCFNetworkProxiesHTTPProxy');
end;

function kCFNetworkProxiesHTTPSEnable: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork, 'kCFNetworkProxiesHTTPSEnable');
end;

function kCFNetworkProxiesHTTPSPort: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork, 'kCFNetworkProxiesHTTPSPort');
end;

function kCFNetworkProxiesHTTPSProxy: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork, 'kCFNetworkProxiesHTTPSProxy');
end;

function kCFNetworkProxiesRTSPEnable: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork, 'kCFNetworkProxiesRTSPEnable');
end;

function kCFNetworkProxiesRTSPPort: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork, 'kCFNetworkProxiesRTSPPort');
end;

function kCFNetworkProxiesRTSPProxy: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork, 'kCFNetworkProxiesRTSPProxy');
end;

function kCFNetworkProxiesSOCKSEnable: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork, 'kCFNetworkProxiesSOCKSEnable');
end;

function kCFNetworkProxiesSOCKSPort: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork, 'kCFNetworkProxiesSOCKSPort');
end;

function kCFNetworkProxiesSOCKSProxy: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork, 'kCFNetworkProxiesSOCKSProxy');
end;

function kCFNetworkProxiesProxyAutoConfigEnable: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork,
    'kCFNetworkProxiesProxyAutoConfigEnable');
end;

function kCFNetworkProxiesProxyAutoConfigURLString: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork,
    'kCFNetworkProxiesProxyAutoConfigURLString');
end;

function kCFNetworkProxiesProxyAutoConfigJavaScript: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork,
    'kCFNetworkProxiesProxyAutoConfigJavaScript');
end;

function kCFNetworkProxiesProxyAutoDiscoveryEnable: Pointer;
begin
  Result := CocoaPointerConst(libCFNetwork,
    'kCFNetworkProxiesProxyAutoDiscoveryEnable');
end;

{$IF defined(IOS) and NOT defined(CPUARM)}

initialization

CFNetworkModule := dlopen(MarshaledAString(libCFNetwork), RTLD_LAZY);

finalization

dlclose(CFNetworkModule);
{$ENDIF IOS}

end.
