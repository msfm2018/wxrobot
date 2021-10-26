unit qhttprequest;

interface

{ QHttpRequest 单元用于封装 HTTP 异步访问，清使用 TQWebRequests 来管理请求，对于
  早期版本的 Delphi，使用自行实现的 TQHttpClient 来访问（仅支持 HTTP 协议的 GET/POST），
  其它版本的 Delphi，直接使用系统内置的 THttpClient 来访问，同时支持 HTTP/HTTPS。
  每个添加到 TQHttpRequests 中的请求，完成后会自动释放，请不要手工释放，否则重复释放
  会出AV时请自理
}
{$IF RTLVersion>=28}
{$DEFINE SYSHTTP }
{$IFEND}

uses Classes, Sysutils, Types, SyncObjs, QString, QDigest, QJson, QXML,
  QSimplePool, QWorker{$IFDEF SYSHTTP}, System.Net.HttpClient,
  System.Net.UrlClient{$ENDIF}
{$IFDEF UNICODE}, System.Generics.Collections{$ELSE}, Contnrs{$ENDIF};
{$I 'qdac.inc'}

type
  TQUrl = class;
  TQHttpRecvProgressEvent = procedure(const Sender: TObject;
    AContentLength: Int64; AReadCount: Int64; var Abort: Boolean) of object;
  TQHttpErrorEvent = procedure(ASender: TObject; AError: Exception) of object;
  TQHttpRedirectEvent = procedure(ASender: TObject; ANewUrl: TQUrl;
    var Allow: Boolean) of object;
  TQUrlRedirectEvent = procedure(ASender: TObject; var Allow: Boolean)
    of object;
  TQHttpRequestClientBoundEvent = procedure(ASender: TObject; AClient: TObject)
    of object;

  // TQUrl 是一处简单的 URL 处理类，注意各项参数不要传无效的参数，因为它并不进行规范性检查
  // 它假设你传的参数都是合法有效的
  TQUrl = class
  private
    function GetOriginNames: QStringW;
    function GetOriginValues: QStringW;
    function GetUrlWithoutParams: QStringW;

  protected
    FUrl: QStringW;
    FUserName, FPassword: QStringW;
    FScheme, FHost, FDocument: QStringW;
    FBookmark: QStringW;
    FPort: Word;
    FParams: TStringList;
    FChanged: Boolean;
    FSpaceAsPlus: Boolean;
    function GetParams: TStrings;
    function GetUrl: QStringW;
    procedure SetUrl(const Value: QStringW);
    procedure DoParamsChanged(ASender: TObject);
    procedure SetBookmark(const Value: QStringW);
    procedure SetDocument(const Value: QStringW);
    procedure SetHost(const Value: QStringW);
    procedure SetPort(const Value: Word);
    procedure SetScheme(const Value: QStringW);
    function GetSchemePort: Word;
    function GetPort: Word;
    function GetHostAddr: QStringW;
    function GetIPAddr: Cardinal;
    function GetDocumentWithParams: QStringW;
    function GetRequestHost: QStringW;
    function GetDocumentFullPath: QStringW;
    function GetFullParams: QStringW;
    function GetOriginParams: QStringW;
  public
    constructor Create; overload;
    constructor Create(AUrl: QStringW); overload;
    destructor Destroy; override;
    procedure Assign(ASource: TQUrl);
    procedure SortParams(ACaseSensitive: Boolean = false;
      AUseLocale: Boolean = false; Compare: TStringListSortCompare = nil);
    procedure RandSortParams;
    property SchemePort: Word read GetSchemePort;
    property Scheme: QStringW read FScheme write SetScheme;
    property Host: QStringW read FHost write SetHost;
    property Port: Word read GetPort write SetPort;
    property Document: QStringW read FDocument write SetDocument;
    property FullDocument: QStringW read GetDocumentWithParams;
    property FullPath: QStringW read GetDocumentFullPath;
    property RequestHost: QStringW read GetRequestHost;
    property Bookmark: QStringW read FBookmark write SetBookmark;
    property Params: TStrings read GetParams;
    property FullParams: QStringW read GetFullParams;
    property OriginParams: QStringW read GetOriginParams;
    property OriginNames: QStringW read GetOriginNames;
    property OriginValues: QStringW read GetOriginValues;
    property Url: QStringW read GetUrl write SetUrl;
    property UrlWithoutParams: QStringW read GetUrlWithoutParams;
    property SpaceAsPlus: Boolean read FSpaceAsPlus write FSpaceAsPlus;
    property HostAddr: QStringW read GetHostAddr;
    property IPAddr: Cardinal read GetIPAddr;
  end;

  IQHttpHeaders = interface
    ['{8A15352D-6CDE-4D0A-90B6-2A70AC7657A0}']
    function GetHeaderValue(const AName: QStringW): QStringW;
    procedure SetHeaderValue(const AName, AValue: QStringW);
    function HeaderIndex(AName: QStringW): Integer;
    function HeaderValue(AName, ADefVal: QStringW): QStringW;
    procedure RemoveHeader(AName: QStringW);
    procedure ReplaceHeader(AName, AValue: QStringW);
    function GetText: QStringW;
    procedure SetText(const S: QStringW);
    function GetNames(const AIndex: Integer): QStringW;
    function GetValueFromIndex(const AIndex: Integer): QStringW;
    function GetCount: Integer;
    procedure Replace(AHeaders: IQHttpHeaders);
    procedure Merge(AHeaders: IQHttpHeaders);
    property Values[const AName: QStringW]: QStringW read GetHeaderValue
      write SetHeaderValue; default;
    property Text: QStringW read GetText write SetText;
    property Names[const AIndex: Integer]: QStringW read GetNames;
    property ValueFromIndex[const AIndex: Integer]: QStringW
      read GetValueFromIndex;
    property Count: Integer read GetCount;
  end;

  TQHttpClientAction = (reqUnknown, reqGet, reqPost, reqHead);
  TQDownloadProgressEvent = procedure(const Sender: TObject;
    AContentLength: Int64; AReadCount: Int64; var Abort: Boolean) of object;
  TQHttpRequests = class;

  TQHttpRequestItem = class(TInterfacedObject)
  protected
    FUrl: QStringW;
    FQueue: TQHttpRequests;
    FResultUrl: QStringW;
    FRequestStream, FResponseStream: TStream;
    FAction: TQHttpClientAction;
    FSender: TObject;
    FAfterDone: TNotifyEvent;
    FHttpClient: TObject;
    FRequestHeaders: IQHttpHeaders;
    FResponseHeaders: IQHttpHeaders;
    FStatusCode: Integer;
    FStatusText: QStringW;
    FResponseStreamOwner, FRequestStreamOwner: Boolean;
    FResponse: IInterface;
    FMainThreadNotify: Boolean;
    FLastProgressTick: Cardinal;
    FOnRecvData: TQDownloadProgressEvent;
    FOnError: TQHttpErrorEvent;
    FProgressInterval: Cardinal;
    FSentBytes: Int64;
    FRecvBytes: Int64;
    FTotalBytes: Int64;
    FStopTime: TDateTime;
    FStartTime: TDateTime;
    FRedirectTimes: Integer;
    FMaxRedirectTimes: Integer;
    FLastException: Exception;
    FTag: Int64;
    FAbort: Boolean;
    FIsDone: Boolean;
    FFreeRequestStream: Boolean;
    // FFreeAfterDone: Boolean;
    FRequestHeaderReady: Boolean;
    FAllowRedirect: Boolean;
    FBeforeUrlRedirect: TQUrlRedirectEvent;
    FConnectionTimeout: Cardinal;
    FOnClientBound: TQHttpRequestClientBoundEvent;
    FSyncEvent: TEvent;
    procedure DoAfterDone(ASender: TObject);
    procedure DoError;
    procedure DoProgress(const Sender: TObject; AContentLength: Int64;
      AReadCount: Int64; var Abort: Boolean); overload;
    function DoProgress: Boolean; overload;
    procedure DoRedirect;
    procedure DoClientRedirect(ASender: TObject; ANewUrl: TQUrl;
      var Allow: Boolean);
    procedure DoMainThreadAfterDone;
    procedure DoMainThreadRecvProgress;
    function GetResponseStream: TStream;
    procedure SetResponseStream(const Value: TStream);
    function GetContentAsString: QStringW;
    function GetResponseCharset: QStringW;
    function GetResultUrl: QStringW;
    function StartWith(AHttpClient: TObject): Boolean;
    function GetUserAgent: QStringW;
    procedure SetUserAgent(const Value: QStringW);
    procedure DoClientBound;
  private

  protected
    procedure BeforePush; virtual;
    procedure AfterPush; virtual;
    function GetCanStart: Boolean; virtual;
    function CreateInternalStream: TStream; virtual;
    procedure InternalCreate(ASender: TObject; AIsSyncMode: Boolean);
    property HttpClient: TObject read FHttpClient write FHttpClient;
  public
    constructor Create(ASender: TObject; AIsSyncMode: Boolean); overload;
    constructor Create(ASender: TObject); overload;
    destructor Destroy; override;
    function WaitFor(ATimeout: Cardinal): TWaitResult;
    function NeedRequestStream: TStream;
    property Url: QStringW read FUrl write FUrl;
    property ResultUrl: QStringW read GetResultUrl;
    property Action: TQHttpClientAction read FAction write FAction;
    property Sender: TObject read FSender;
    property RequestStream: TStream read FRequestStream write FRequestStream;
    property ResponseStream: TStream read GetResponseStream
      write SetResponseStream;
    // ContentStream做为 ResponseStream的别名
    property ContentStream: TStream read GetResponseStream
      write SetResponseStream;
    property RequestHeaders: IQHttpHeaders read FRequestHeaders;
    property StatusCode: Integer read FStatusCode;
    property StatusText: QStringW read FStatusText;
    property ResponseHeaders: IQHttpHeaders read FResponseHeaders;
    property MainThreadNotify: Boolean read FMainThreadNotify
      write FMainThreadNotify;
    property ResponseCharset: QStringW read GetResponseCharset;
    property MaxRedirectTimes: Integer read FMaxRedirectTimes
      write FMaxRedirectTimes;
    property RedirectTimes: Integer read FRedirectTimes write FRedirectTimes;
    property ProgressInterval: Cardinal read FProgressInterval
      write FProgressInterval default 1000;
    property ContentAsString: QStringW read GetContentAsString;
    property StartTime: TDateTime read FStartTime;
    property StopTime: TDateTime read FStopTime;
    property SentBytes: Int64 read FSentBytes;
    property RecvBytes: Int64 read FRecvBytes;
    property ContentLength: Int64 read FTotalBytes;
    property TotalBytes: Int64 read FTotalBytes;
    property UserAgent: QStringW read GetUserAgent write SetUserAgent;
    property CanStart: Boolean read GetCanStart;
    property ConnectionTimeut: Cardinal read FConnectionTimeout
      write FConnectionTimeout;
    property Tag: Int64 read FTag write FTag;
    // property FreeAfterDone: Boolean read FFreeAfterDone write FFreeAfterDone;
    property OnRecvData: TQDownloadProgressEvent read FOnRecvData
      write FOnRecvData;
    property AfterDone: TNotifyEvent read FAfterDone write FAfterDone;
    property OnError: TQHttpErrorEvent read FOnError write FOnError;
    property BeforeUrlRedirect: TQUrlRedirectEvent read FBeforeUrlRedirect
      write FBeforeUrlRedirect;
    property OnClientBound: TQHttpRequestClientBoundEvent read FOnClientBound
      write FOnClientBound;
    property IsAborted: Boolean read FAbort write FAbort;
  end;

  TQRequestList = class
  private
    FItems: TList;
    function GetCount: Integer;
    function GetItems(const AIndex: Integer): TQHttpRequestItem;
  public
    constructor Create; overload;
    destructor Destroy; override;
    function Add(const ARequest: TQHttpRequestItem): Integer;
    procedure Remove(const ARequest: TQHttpRequestItem);
    procedure Delete(AIndex: Integer);
    procedure Clear;
    function IndexOf(const ARequest: TQHttpRequestItem): Integer;
    property Items[const AIndex: Integer]: TQHttpRequestItem
      read GetItems; default;
    property Count: Integer read GetCount;
  end;

  TQHttpRequests = class
  protected
    FRequests: TQRequestList;
    FHttpClients: TQSimplePool;
    FMaxClients, FBusyClients: Integer;
    FDefaultHeaders: IQHttpHeaders;
    FCS: TCriticalSection;
    FCookieManager: TCookieManager;
    procedure Start(ARequest: TQHttpRequestItem);
    procedure RequestDone(ARequest: TQHttpRequestItem);
    procedure DoEventReqDone(ASender: TObject);
    procedure Lock; inline;
    procedure Unlock; inline;
    procedure DoNewHttpClient(ASender: TQSimplePool; var AData: Pointer);
    procedure DoFreeHttpClient(ASender: TQSimplePool; AData: Pointer);
  public
    constructor Create; overload;
    destructor Destroy; override;
    procedure Push(ARequest: TQHttpRequestItem); virtual;
    procedure Clear(AExclude: TQHttpRequestItem = nil);
    function Get(const AUrl: QStringW; var AResult: QStringW;
      AHeaders: IQHttpHeaders = nil): Integer; overload;
    function Get(const AUrl: QStringW; AReplyStream: TStream;
      AHeaders: IQHttpHeaders = nil): Integer; overload;
    function Post(const AUrl: QStringW; var AResult: QStringW;
      AHeaders: IQHttpHeaders = nil): Integer; overload;
    function Post(const AUrl: QStringW; AReplyStream: TStream;
      AHeaders: IQHttpHeaders = nil): Integer; overload;
    function Post(const AUrl: QStringW; AFormParams: TStrings;
      AReplyStream: TStream; AfterDone: TNotifyEvent = nil;
      AHeaders: IQHttpHeaders = nil): Integer; overload;
    function Post(const AUrl: QStringW; AFormParams: TStrings;
      var AReply: QStringW): Integer; overload;
    function Post(const AUrl: QStringW; AContent: TStrings;
      AReplyStream: TStream; AContentType: QStringW = 'text/plain';
      AfterDone: TNotifyEvent = nil; AHeaders: IQHttpHeaders = nil)
      : Integer; overload;
    function Post(const AUrl: QStringW; AContent: QStringW;
      var AReply: QStringW; AContentType: QStringW = 'text/plain')
      : Integer; overload;
    function Rest(const AUrl: QStringW; ASource, AResult: TQJson;
      AHeaders: IQHttpHeaders = nil; AfterDone: TNotifyEvent = nil;
      Action: TQHttpClientAction = reqUnknown): Integer; overload; virtual;
    function Rest(const AUrl: QStringW; AContent: QStringW; AResult: TQJson;
      AHeaders: IQHttpHeaders = nil; AfterDone: TNotifyEvent = nil;
      Action: TQHttpClientAction = reqUnknown): Integer; overload; virtual;
    function Rest(const AUrl: QStringW; AParams: TStrings; AResult: TQJson;
      AHeaders: IQHttpHeaders = nil; AfterDone: TNotifyEvent = nil;
      Action: TQHttpClientAction = reqUnknown): Integer; overload; virtual;
    function Soap(const AUrl, Action, ARequestBody: QStringW;
      var AResult: QStringW): Integer; virtual;
    function NewHeaders: IQHttpHeaders;
    property MaxClients: Integer read FMaxClients write FMaxClients;
    property DefaultHeaders: IQHttpHeaders read FDefaultHeaders;
  end;

  TQHttpFileDownloadEvent = procedure(ASender: TObject; AHeaders: IQHttpHeaders;
    var AContinue: Boolean) of object;

  TQHttpFileRequestItem = class(TQHttpRequestItem)
  protected
    FFileName: QStringW;
    FPath: QStringW;
    FBeforeDownload: TQHttpFileDownloadEvent;
    FResumeBroken: Boolean;
    FFileSize: Int64;
    FHeadReady: Boolean;
    function GetFilePath: QStringW;
    procedure DoHeadReady(ASender: TObject);
  protected
    procedure BeforePush; override;
    function GetCanStart: Boolean; override;
    function CreateInternalStream: TStream; override;
    procedure DoError(ASender: TObject; AError: Exception);
  public
    property Path: QStringW read FPath write FPath;
    property FileName: QStringW read FFileName write FFileName;
    property FilePath: QStringW read GetFilePath;
    property ResumeBroken: Boolean read FResumeBroken write FResumeBroken;
    property BeforeDownload: TQHttpFileDownloadEvent read FBeforeDownload
      write FBeforeDownload;
    property FileSize: Int64 read FFileSize;
  end;

  TQHttpHeaders = class(TStringList)
  public
    constructor Create; overload;
    function HeaderIndex(AName: QStringW): Integer;
    function HeaderValue(AName, ADefVal: QStringW): QStringW;
    procedure RemoveHeader(AName: QStringW);
    procedure ReplaceHeader(AName, AValue: QStringW);
  end;

  TQHttpRequeststatus = (rsPrepare, rsConnecting, rsSending, rsRecving,
    rsProcessed, rsAborted);

  // 封装 HTTP 请求，以便兼容低版本和高版本，只提供必需的 HTTP 支持
  TQHttpClient = class
  private

  protected
    // 请求的头部
    FRequestHeaders: TQHttpHeaders;
    // 回复的头部
    FResponseHeaders: TQHttpHeaders;
    // 请求的原始 URL
    FUrl: TQUrl;
    // 实际返回结果的 URL
    FResultUrl: TQUrl;
    // 接收进度回调
    FOnReceiveData: TQHttpRecvProgressEvent;
    // 是否跟随跳转
    FFollowRedirection: Boolean;
    // 请求处理完成后的通知
    FAfterDone: TNotifyEvent;
    // 通知是否要求在主线程中响应
    FMainThreadNotify: Boolean;
    // 请求执行线程
    FWorkThread: TThread;
    // 请求动作
    FAction: QStringW;
    // 请求的内容数据流
    FRequestStream: TStream;
    // 返回的结果流
    FResponseStream: TStream;
    // 内存流，用于没有提供 ResponseStream参数时保存返回结果
    FInternalResponseStream: TMemoryStream;
    // 返回的 HTTP 状态码
    FStatusCode: Integer;
    // 返回的 HTTP 状态消息
    FStatusText: QStringW;
    // 允许跟随跳转的次数
    FMaxRedirects: Integer;
    // 要接收的内容总大小
    FContentLength: Int64;
    // 请求处理状态
    FStatus: TQHttpRequeststatus;
    // 状态报告最小间隔，默认每秒报告一次，单位为毫秒
    FStatusReportInterval: Cardinal;
    // 收发状态统计
    FSentBytes, FRecvBytes: Int64;
    FStartTime, FStopTime: TDateTime;
    FConnectionTimeout: Cardinal;
    FNotifyEvent: TEvent;
    FIsWaiting: Boolean;
    FOnError: TQHttpErrorEvent;
    FOnRedirect: TQHttpRedirectEvent;
    FErrorMessage: QStringW;
    function GetResponseHeaders: TQHttpHeaders;
    function GetRequestHeaders: TQHttpHeaders;
    procedure DoThreadTerminated(Sender: TObject);
    function GetInternalResponseStream: TMemoryStream;
    function GetUserAgent: QStringW;
    procedure SetUserAgent(const Value: QStringW);
    property InternalResponseStream: TMemoryStream
      read GetInternalResponseStream;
    procedure HandleException(E: Exception);
    procedure ReportStatus;
    procedure InternalExecuteRequest(const Action, AUrl: QStringW;
      AContentStream, AResponseStream: TStream; AWaitResponse: Boolean);
    property IsWaiting: Boolean read FIsWaiting;
  public
    constructor Create; overload; virtual;
    destructor Destroy; override;
    procedure Get(const AUrl: QStringW; AResponseStream: TStream;
      AWaitResponse: Boolean = false);
    procedure Post(const AUrl: QStringW;
      AContentStream, AResponseStream: TStream; AWaitResponse: Boolean = false);
    procedure Head(const AUrl: QStringW; AWaitResponse: Boolean = false);
    property Url: TQUrl read FUrl;
    property ResultUrl: TQUrl read FResultUrl;
    property Action: QStringW read FAction;
    property OnReceiveData: TQHttpRecvProgressEvent read FOnReceiveData
      write FOnReceiveData;
    property RequestHeaders: TQHttpHeaders read GetRequestHeaders;
    property ResponseHeaders: TQHttpHeaders read GetResponseHeaders;
    property FollowRedirection: Boolean read FFollowRedirection
      write FFollowRedirection;
    property AfterDone: TNotifyEvent read FAfterDone write FAfterDone;
    property OnError: TQHttpErrorEvent read FOnError write FOnError;
    property OnRedirect: TQHttpRedirectEvent read FOnRedirect write FOnRedirect;
    property MainThreadNotify: Boolean read FMainThreadNotify
      write FMainThreadNotify;
    property RequestStream: TStream read FRequestStream;
    property ResponseStream: TStream read FResponseStream;
    property StatusCode: Integer read FStatusCode;
    property StatusText: QStringW read FStatusText;
    property MaxRedirects: Integer read FMaxRedirects write FMaxRedirects;
    property UserAgent: QStringW read GetUserAgent write SetUserAgent;
    property Status: TQHttpRequeststatus read FStatus;
    property StatusReportInterval: Cardinal read FStatusReportInterval
      write FStatusReportInterval;
    property ConnectionTimeout: Cardinal read FConnectionTimeout
      write FConnectionTimeout;
    property StartTime: TDateTime read FStartTime;
    property StopTime: TDateTime read FStopTime;
    property SentBytes: Int64 read FSentBytes;
    property RecvBytes: Int64 read FRecvBytes;
  end;

function DNSLookupV4(const AHost: QStringW): Cardinal; overload;
function DNSLookupV4(const AHost: QStringW; var Addr: QStringW)
  : Boolean; overload;

implementation

uses zlib
{$IFDEF MSWINDOWS} , windows, messages, winsock{$ENDIF}
{$IFDEF POSIX}, System.Net.Socket, Posix.Base, Posix.Stdio, Posix.Pthread,
  Posix.UniStd, IOUtils, Posix.NetDB, Posix.SysSocket, Posix.Fcntl,
  Posix.StrOpts, Posix.NetinetIn, Posix.arpainet, Posix.SysSelect,
  Posix.Systime{$ENDIF}
    ;

resourcestring
  SBadHttpFormat = '无效的HTTP数据格式';
  SRequestInProcess = '当前请求正在处理中';
  SZlibError = '数据解压失败';
  SCantWaitResponseWithNotify = '不能在主线程中等待请求处理完成的同时响应相关通知';
  SHttpSupportOnly = 'TQHttpClient 当前仅支持 HTTP 协议.';
  SRedirectToNoHttp = '请求 %s 重定向到了非 HTTP 协议网址 %s，该协议当前不受支持';
  SUserCanceled = '用户取消了指定的操作';
  SContnetIsNotJson = '当前内容不是有效的 Json 格式:'#13#10'%s';

const
  NullQuoter: WideChar = #0;
  DefaultUserAgent = 'Mozilla/5.0 (' +
{$IFDEF MSWINDOWS}'Windows NT 10.0; WOW64' + {$ENDIF}
{$IFDEF ANDROID}'Android 5.0' + {$ENDIF}
{$IFDEF LINUX}'Linux X86_64' + {$ENDIF}
{$IFDEF IOS}'iPhone; CPU iPhone OS 8_4 like Mac OS X' + {$ELSE}
{$IFDEF MACOS}
    'Macintosh; U; Intel Mac OS X 10_6_2' +
{$ENDIF}
{$ENDIF}
    ') AppleWebKit/537.36 (KHTML, like Gecko) Chrome/55.0.2883.75 Safari/537.36 QDAC/3.0';
{$IFDEF POSIX}
  INVALID_SOCKET = IntPtr(not 0);
  SOCKET_ERROR = -1;
  NO_ERROR = 0;
{$ENDIF}

type
{$IFDEF MSWINDOWS}
  TSocketHandle = TSocket;
  SockAddr = TSockAddr;
{$ENDIF}

  // HTTP 下载线程
  TQHttpThread = class(TThread)
  protected
    FRequest: TQHttpClient;
    FSocket: TSocketHandle;
    FException: Exception;
    FRedirectingUrl: TQUrl;
    FAllowRedirect: Boolean;
    procedure Execute; override;
    procedure HandleException;
    procedure HandleRedirection;
  public
    constructor Create(ARequest: TQHttpClient); overload;
  end;

{$IFDEF POSIX}

  TSockAddrIn = sockaddr_in;
{$ENDIF}
{$IFDEF SYSHTTP}
  THttpClientClass = THttpClient;

  THeadersHelper = class(TInterfacedObject, IQHttpHeaders)
  protected
    FHeaders: TNetHeaders;
    function GetHeaderValue(const AName: QStringW): QStringW;
    procedure SetHeaderValue(const AName, AValue: QStringW);
    function HeaderIndex(AName: QStringW): Integer;
    function HeaderValue(AName, ADefVal: QStringW): QStringW;
    procedure RemoveHeader(AName: QStringW);
    procedure ReplaceHeader(AName, AValue: QStringW);
    function GetText: QStringW;
    procedure SetText(const S: QStringW);
    procedure SetHeaders(const AValue: TNetHeaders);
    function GetCount: Integer;
    function GetNames(const AIndex: Integer): QStringW;
    function GetValueFromIndex(const AIndex: Integer): QStringW;
    procedure Replace(AHeaders: IQHttpHeaders);
    procedure Merge(AHeaders: IQHttpHeaders);
  public
    constructor Create; overload;
    constructor Create(AHeaders: TNetHeaders); overload;
    property Headers: TNetHeaders read FHeaders write SetHeaders;
  end;
{$ELSE}

  THeadersHelper = class(TInterfacedObject, IQHttpHeaders, IInterface)
  protected
    FHeaders: TQHttpHeaders;
    function GetHeaderValue(const AName: QStringW): QStringW;
    procedure SetHeaderValue(const AName, AValue: QStringW);
    function HeaderIndex(AName: QStringW): Integer;
    function HeaderValue(AName, ADefVal: QStringW): QStringW;
    procedure RemoveHeader(AName: QStringW);
    procedure ReplaceHeader(AName, AValue: QStringW);
    procedure SetHeaders(const Value: TQHttpHeaders);
    function GetText: QStringW;
    procedure SetText(const S: QStringW);
    function GetCount: Integer;
    function GetNames(const AIndex: Integer): QStringW;
    function GetValueFromIndex(const AIndex: Integer): QStringW;
    procedure Replace(AHeaders: IQHttpHeaders);
    procedure Merge(AHeaders: IQHttpHeaders);
  public
    constructor Create; overload;
    constructor Create(AHeaders: TQHttpHeaders); overload;
    destructor Destroy; override;
    function QueryInterface(const IID: TGUID; out Obj): HResult; stdcall;
    property Headers: TQHttpHeaders read FHeaders write SetHeaders;
  end;

  THttpClientClass = TQHttpClient;
{$ENDIF}
{$IF RTLVersion=18}

const
  ObjCastGUID: TGUID = '{CEDF24DE-80A4-447D-8C75-EB871DC121FD}';

type
  TinflateInit2_ = function(var strm: TZStreamRec; windowBits: Integer;
    version: PAnsiChar; stream_size: Integer): Integer; cdecl;

var
  inflateInit2_: TinflateInit2_ = nil;
  ZLibHandle: HINST;

function ObjectOf(AIntf: IInterface): TObject;
begin
  if not Supports(AIntf, ObjCastGUID, Result) then
    Result := nil;
end;
{$IFEND}

// IPv4 DNS 解析支持，不支持 IPv6
function DNSLookupV4(const AHost: QStringW): Cardinal;
var
  Utf8Host: QStringA;
  AEntry: PHostEnt;
  function TryAsAddr(var AResult: Cardinal): Boolean;
  var
    p: PQCharW;
    I, V: Integer;
    B: array [0 .. 3] of Byte absolute AResult;
  begin
    p := PQCharW(AHost);
    V := 0;
    I := 0;
    while p^ <> #0 do
    begin
      if (p^ >= '0') and (p^ <= '9') then
        V := V * 10 + Ord(p^) - Ord('0')
      else if p^ = '.' then
      begin
        if V > 255 then
        begin
          Result := false;
          Exit;
        end;
        B[I] := Byte(V);
        Inc(I);
        V := 0;
      end
      else
      begin
        Result := false;
        Exit;
      end;
      Inc(p);
    end;
    Result := (p^ = #0) and (I = 3) and (V < 256);
    if Result then
      B[I] := V;
  end;

begin
  if not TryAsAddr(Result) then
  begin
    Result := 0;
    Utf8Host := QString.Utf8Encode(AHost);
    AEntry := gethostbyname
      ({$IFDEF UNICODE}MarshaledAString{$ELSE}PAnsiChar{$ENDIF}(PQCharA(Utf8Host)));
    if Assigned(AEntry) then
    begin
      if AEntry.h_addrtype = AF_INET then
      begin
        if AEntry.h_addr_list^ <> nil then
          Result := PCardinal(AEntry.h_addr_list^)^;
      end;
    end;
  end;
end;

function DNSLookupV4(const AHost: QStringW; var Addr: QStringW): Boolean;
var
  v4addr: Cardinal;
  v4bytes: array [0 .. 3] of Byte absolute v4addr;
begin
  v4addr := DNSLookupV4(AHost);
  Addr := IntToStr(v4bytes[0]) + '.' + IntToStr(v4bytes[1]) + '.' +
    IntToStr(v4bytes[2]) + '.' + IntToStr(v4bytes[3]);
  Result := v4addr <> 0;
end;
{$IFDEF POSIX}

function closesocket(Socket: TSocketHandle): Integer; inline;
begin
  Result := Posix.UniStd.__close(Socket);
end;

function ioctlsocket(Socket: TSocketHandle; Request: Integer; var Data)
  : Integer; inline;
begin
  Result := ioctl(Socket, Request, @Data);
end;
{$ENDIF}
/// <summary>取指定分隔符前的字符串</summary>
/// <param name="S">源字符串</param>
/// <param name="ADelimiter">分隔子串</param>
/// <param name="AIgnoreCase">是否忽略大小写</param>
/// <param name="ATimes">分隔次数，如果>=0则从前到后，<0则从后到前</param>

{ TQHttpClient }

constructor TQHttpClient.Create;
begin;
  inherited;
  FMaxRedirects := 3;
  // 默认最多跳3次
  FRequestHeaders := TQHttpHeaders.Create;
  FResponseHeaders := TQHttpHeaders.Create;
  FUrl := TQUrl.Create;
  FResultUrl := TQUrl.Create;
  FFollowRedirection := True;
  FStatusReportInterval := 1000;
end;

destructor TQHttpClient.Destroy;
begin
  if Assigned(FWorkThread) then
  begin
    FWorkThread.Terminate;
    FWorkThread.WaitFor;
  end;
  if Assigned(FNotifyEvent) then
    FreeAndNil(FNotifyEvent);
  FreeAndNil(FRequestHeaders);
  FreeAndNil(FResponseHeaders);
  FreeAndNil(FUrl);
  FreeAndNil(FResultUrl);
  if Assigned(FInternalResponseStream) then
    FreeAndNil(FInternalResponseStream);
  inherited;
end;

procedure TQHttpClient.DoThreadTerminated(Sender: TObject);
begin
  FWorkThread.FreeOnTerminate := True;
  FWorkThread := nil;
  if Assigned(FAfterDone) then
    FAfterDone(Self);
end;

procedure TQHttpClient.Get(const AUrl: QStringW; AResponseStream: TStream;
  AWaitResponse: Boolean);
begin
  InternalExecuteRequest('GET', AUrl, nil, AResponseStream, AWaitResponse);
end;

function TQHttpClient.GetInternalResponseStream: TMemoryStream;
begin
  if not Assigned(FInternalResponseStream) then
    FInternalResponseStream := TMemoryStream.Create;
  Result := FInternalResponseStream;
end;

function TQHttpClient.GetResponseHeaders: TQHttpHeaders;
begin
  Result := FResponseHeaders;
end;

function TQHttpClient.GetRequestHeaders: TQHttpHeaders;
begin
  Result := FRequestHeaders;
end;

function TQHttpClient.GetUserAgent: QStringW;
begin
  Result := RequestHeaders.HeaderValue('user-agent', DefaultUserAgent);
end;

procedure TQHttpClient.HandleException(E: Exception);
begin
  if Assigned(FOnError) then
    FOnError(Self, E);
end;

procedure TQHttpClient.Head(const AUrl: QStringW; AWaitResponse: Boolean);
begin
  InternalExecuteRequest('HEAD', AUrl, nil, nil, AWaitResponse);
end;

procedure TQHttpClient.InternalExecuteRequest(const Action, AUrl: QStringW;
  AContentStream, AResponseStream: TStream; AWaitResponse: Boolean);
var
  AThread: TQHttpThread;
begin
  if Assigned(FWorkThread) then
    raise Exception.Create(SRequestInProcess);
  if AWaitResponse and MainThreadNotify and Assigned(FOnReceiveData) then
    raise Exception.Create(SCantWaitResponseWithNotify);
  FUrl.Url := AUrl;
  if FUrl.Scheme <> 'http' then
    raise Exception.Create(SHttpSupportOnly);
  FAction := Action;
  FStatus := rsPrepare;
  FStartTime := Now;
  FRequestStream := AContentStream;
  FSentBytes := 0;
  FRecvBytes := 0;
  FContentLength := 0;
  if not Assigned(AResponseStream) then
    FResponseStream := InternalResponseStream
  else
    FResponseStream := AResponseStream;
  FIsWaiting := AWaitResponse;
  if FIsWaiting then
  begin
    if not Assigned(FNotifyEvent) then
      FNotifyEvent := TEvent.Create(nil, false, false, '');
  end;
  AThread := TQHttpThread.Create(Self);
  FWorkThread := AThread;
  AThread.OnTerminate := DoThreadTerminated;
  AThread.Suspended := false;
  if FIsWaiting then
    FNotifyEvent.WaitFor(INFINITE);
end;

procedure TQHttpClient.Post(const AUrl: QStringW;
  AContentStream, AResponseStream: TStream; AWaitResponse: Boolean);
begin
  InternalExecuteRequest('POST', AUrl, AContentStream, AResponseStream,
    AWaitResponse);
end;

procedure TQHttpClient.ReportStatus;
var
  AbortIt: Boolean;
begin
  AbortIt := false;
  case FStatus of
    rsPrepare:
      ;
    rsConnecting:
      ;
    rsSending:
      ;
    rsRecving:
      if Assigned(FOnReceiveData) then
        FOnReceiveData(Self, FContentLength, FRecvBytes, AbortIt);
    rsProcessed, rsAborted:
      begin
        if Assigned(FOnReceiveData) then
        begin
          FOnReceiveData(Self, FContentLength, FRecvBytes, AbortIt);
          AbortIt := false; // 不需要再次调用
        end;
      end;
  end;
  if AbortIt then
    FWorkThread.Terminate;
end;

procedure TQHttpClient.SetUserAgent(const Value: QStringW);
begin
  RequestHeaders.ReplaceHeader('user-agent', Value);
end;

{$IFDEF MSWINDOWS}

procedure StartSocket;
var
  AData: WSAData;
begin
  if WSAStartup($202, &AData) <> NO_ERROR then
    RaiseLastOSError();
end;

procedure CleanSocket;
begin
  WSACleanup;
end;
{$ELSE}

procedure StartSocket; inline;
begin
end;

procedure CleanSocket; inline;
begin
end;
{$ENDIF}
{ TQHttpThread }

constructor TQHttpThread.Create(ARequest: TQHttpClient);
begin
  inherited Create(True);
  FRequest := ARequest;
end;

procedure TQHttpThread.Execute;
var
  Addr: TSockAddrIn;
  AHelper: TQStringCatHelperW;
  ABuf: array [0 .. 65535] of Byte;
  ACloseNeeded: Boolean;
  ALastStatusTick: Cardinal;
  ALastStatus: TQHttpRequeststatus;
  AIsGZip, AIsDeflate: Boolean;
  procedure RaiseOSError;
  begin
    FRequest.FStatusCode := GetLastError;
    FRequest.FStatusText := SysErrorMessage(FRequest.FStatusCode);
    RaiseLastOSError(FRequest.FStatusCode);
  end;
  procedure ReportStatus;
  var
    ATick: Cardinal;
  begin
    ATick := GetTickCount;
    if (ATick - ALastStatusTick > FRequest.FStatusReportInterval) or
      (ALastStatus <> FRequest.Status) then
    begin
      ALastStatusTick := ATick;
      ALastStatus := FRequest.Status;
      if FRequest.MainThreadNotify then
      begin
        if not FRequest.IsWaiting then
          // 如果主线程处于等待状态，为避免死锁，不报告任何状态
          Synchronize(FRequest.ReportStatus)
      end
      else
        FRequest.ReportStatus;
    end;
  end;

  function SendData(p: Pointer; ASize: Integer): Boolean;
  var
    ASent: Integer;
  begin
    while (ASize > 0) and (not Terminated) do
    begin
      ASent := send(FSocket, p^, ASize, 0);
      if ASent <> SOCKET_ERROR then
      begin
        Dec(ASize, ASent);
        Inc(FRequest.FSentBytes, ASent);
        ReportStatus;
      end
      else
        Break;
    end;
    Result := ASize = 0;
  end;

  procedure SendStream(AStream: TStream);
  var
    ASize: Integer;
  begin
    AStream.Position := 0;
    repeat
      ASize := AStream.read(ABuf[0], 65536);
      if (ASize > 0) and (not SendData(@ABuf[0], ASize)) and (not Terminated)
      then
        RaiseOSError;
    until (ASize = 0) or Terminated;
  end;

  procedure SendRequest;
  const
    HttpLineBreak = #13#10;
    NameDelimiter: PWideChar = ':';
  var
    I: Integer;
    AName, AValue: QStringW;
    AHeader: QStringA;
  begin
    FRequest.FStatus := rsSending;
    AHelper.Reset;
    AHelper.Cat(FRequest.Action).Cat(' ').Cat(FRequest.ResultUrl.FullDocument)
      .Cat(' HTTP/1.1').Cat(HttpLineBreak);
    if FRequest.RequestHeaders.HeaderIndex('accept') = -1 then
      FRequest.RequestHeaders.Insert(0, 'Accept:*/*');
    if FRequest.RequestHeaders.HeaderIndex('accept-encoding') = -1 then
      FRequest.RequestHeaders.Add('Accept-Encoding:gzip, deflate');
    if FRequest.RequestHeaders.HeaderIndex('host') = -1 then
    begin
      if FRequest.ResultUrl.Port <> 80 then
        FRequest.RequestHeaders.Add('Host:' + FRequest.ResultUrl.Host + ':' +
          IntToStr(FRequest.ResultUrl.Port))
      else
        FRequest.RequestHeaders.Add('Host:' + FRequest.ResultUrl.Host);
    end;
    if FRequest.RequestHeaders.HeaderIndex('user-agent') = -1 then
      FRequest.RequestHeaders.Add('User-Agent:' + DefaultUserAgent);
    if FRequest.RequestHeaders.HeaderIndex('connection') = -1 then
      FRequest.RequestHeaders.Add('Connection:keep-alive');
    if (FRequest.RequestStream <> nil) and
      (FRequest.RequestHeaders.HeaderIndex('content-length') = -1) then
      FRequest.RequestHeaders.Add('Content-Length:' +
        IntToStr(FRequest.RequestStream.Size));

    for I := 0 to FRequest.RequestHeaders.Count - 1 do
    begin
      AValue := FRequest.RequestHeaders[I];
      AName := DecodeTokenW(AValue, NameDelimiter, NullQuoter, True, True);
      AHelper.Cat(AName).Cat(': ').Cat(AValue).Cat(HttpLineBreak);
    end;
    AHelper.Cat(HttpLineBreak);
    AHeader := QString.Utf8Encode(AHelper.Value);
    if SendData(PQCharA(AHeader), AHeader.Length) then
    begin
      if Assigned(FRequest.RequestStream) and (not Terminated) then
        SendStream(FRequest.RequestStream);
    end
    else if not Terminated then
      RaiseOSError;
  end;

  function DecodeResponse: Integer;
  var
    p, pl: PQCharW;
    L: QStringW;
  const
    SpaceChar: PWideChar = ' ';
    NullChar: WideChar = #0;
  begin
    p := AHelper.Start;
    L := DecodeLineW(p);
    pl := PQCharW(L);
    if StartWithW(pl, 'HTTP/', True) then
    begin
      DecodeTokenW(pl, SpaceChar, NullChar, false);
      Result := StrToIntDef(DecodeTokenW(pl, SpaceChar, NullChar, false), -1);
      FRequest.FStatusCode := Result;
      FRequest.FStatusText := pl;
      FRequest.ResponseHeaders.Text :=
        StrDupX(p, AHelper.Position - Length(L) - 6);
    end
    else
      Result := -1;
  end;

  function ParseChunkSize(p: PByte): Integer;
  begin
    Result := 0;
    while IsHexChar(WideChar(p^)) do
    begin
      Result := (Result shl 4) + HexValue(WideChar(p^));
      Inc(p);
    end;
  end;
{$IF RTLVERSION=18}
  function InflateInit(var strm: TZStreamRec): Integer;
  begin
    Result := inflateInit_(strm, ZLIB_VERSION, SizeOf(TZStreamRec));
  end;
  function inflateInit2(var strm: TZStreamRec; windowBits: Integer): Integer;
  begin
    Result := inflateInit2_(strm, windowBits, ZLIB_VERSION,
      SizeOf(TZStreamRec));
  end;
{$IFEND}
  procedure FlushChunk(ABlock: PByte; ASize: Integer);
  var
    ARetVal: Integer;
    AHave: Cardinal;
    AStrm: TZStreamRec;
    ABuf: array [0 .. 65535] of Byte;
  begin
    if AIsGZip or AIsDeflate then
    begin
      AStrm.zalloc := nil;
      AStrm.zfree := nil;
{$IF RTLVersion>18}
      AStrm.opaque := nil;
{$IFEND}
      AStrm.avail_in := 0;
      AStrm.next_in := nil;
      if AIsGZip then
        ARetVal := inflateInit2(AStrm, 47)
      else
        ARetVal := InflateInit(AStrm);
      if ARetVal <> Z_OK then
        raise Exception.Create(SZlibError);
      AStrm.avail_in := ASize;
      AStrm.next_in := Pointer(ABlock);
      repeat
        AStrm.avail_out := 65536;
        AStrm.next_out := @ABuf[0];
        ARetVal := inflate(AStrm, Z_NO_FLUSH);
        if (ARetVal = Z_STREAM_END) or (ARetVal = Z_OK) then
        begin
          AHave := 65536 - AStrm.avail_out;
          Inc(FRequest.FRecvBytes, AHave);
          FRequest.ResponseStream.WriteBuffer(ABuf[0], AHave);
          if ARetVal = Z_STREAM_END then
          begin
            inflateEnd(AStrm);
            Break;
          end;
        end
        else
        begin
          inflateEnd(AStrm);
          raise Exception.Create(SZlibError);
        end;
      until AStrm.avail_out <> 0;
    end
    else
    begin
      FRequest.ResponseStream.WriteBuffer(ABlock, ASize);
      Inc(FRequest.FRecvBytes, ASize);
    end;
    ReportStatus;
  end;

  procedure RecvChunks(AReaded: Integer);
  var
    AChunkSize: Integer;
    I, ARecvBytes, AOffset: Integer;
    ATemp: TMemoryStream;
    ps: PByte;
  begin
    AChunkSize := -1;
    ATemp := TMemoryStream.Create;
    try
      ATemp.WriteBuffer(ABuf[0], AReaded);
      repeat
        if AChunkSize < 0 then
        begin
          ps := ATemp.Memory;
          for I := 2 to AReaded do
          begin
            if (PByte(IntPtr(ps) + I)^ = 10) and
              (PByte(IntPtr(ps) + I - 1)^ = 13) then
            // 块头长度结束
            begin
              AChunkSize := ParseChunkSize(ps) + 2; // Chunk以#13#10结束，需要考虑在内
              AOffset := AReaded - I - 1;
              Move(PByte(IntPtr(ps) + I + 1)^, ps^, AOffset);
              ATemp.Position := AOffset;
              AReaded := AOffset;
              Break;
            end;
          end;
          if AChunkSize < 0 then // 当前缓冲区块头还未结束
          begin
            ARecvBytes := recv(FSocket, ABuf[0], 65536, 0);
            if ARecvBytes = SOCKET_ERROR then
              RaiseOSError;
            ATemp.WriteBuffer(ABuf[0], ARecvBytes);
            Inc(AReaded, ARecvBytes);
            continue;
          end;
        end
        else
        begin
          if AReaded >= AChunkSize then
          begin
            ps := ATemp.Memory;
            FlushChunk(ATemp.Memory, AChunkSize - 2);
            Move(PByte(IntPtr(ps) + AChunkSize)^, ps^, AReaded - AChunkSize);
            Dec(AReaded, AChunkSize);
            ATemp.Position := AReaded;
            AChunkSize := -1;
          end
          else
          begin
            ARecvBytes := AChunkSize - AReaded;
            if ARecvBytes > 65536 then
              ARecvBytes := 65536;
            ARecvBytes := recv(FSocket, ABuf[0], ARecvBytes, 0);
            if ARecvBytes <> SOCKET_ERROR then
            begin
              Inc(AReaded, ARecvBytes);
              ATemp.WriteBuffer(ABuf, ARecvBytes);
            end;
          end;
        end;
      until (AChunkSize = 2) or Terminated;
    finally
      FreeAndNil(ATemp);
    end;
  end;

  procedure RecvResponse;
  var
    ARecv, I, V: Integer;
    AReaded: Int64;
    AUrl: TQUrl;
    AHeaderReady: Boolean;
    S: QStringW;
  begin
    // 接收回应头
    FRequest.FStatus := rsRecving;
    FRequest.ResponseHeaders.Clear;
    AHelper.Reset;
    repeat
      ARecv := recv(FSocket, ABuf, 65536, 0);
      if ARecv = SOCKET_ERROR then
        RaiseOSError;
      Inc(FRequest.FRecvBytes, ARecv);
      AHeaderReady := false;
      I := 0;
      while I < ARecv do
      begin
        AHelper.Cat(WideChar(ABuf[I]));
        if (ABuf[I] = 10) and (AHelper.Position >= 4) then // 判断是否头部结束
        begin
          if AHelper.EndWith(#13#10#13#10, false) then
          begin
            V := DecodeResponse;
            if ((V >= 300) and (V <= 303)) or (V = 307) then // 跳转到新地址
            begin
              if FRequest.FollowRedirection then
              begin
                V := FRequest.ResponseHeaders.HeaderIndex('location');
                if V = -1 then
                  raise Exception.Create(SBadHttpFormat);
                AUrl := TQUrl.Create(UrlMerge(FRequest.ResultUrl.Url,
                  Trim(ValueOfW(FRequest.ResponseHeaders[V], ':'))));
                try
                  // 如果是同一个Host，那么不断开连接，如果不是，则断开连接
                  FAllowRedirect := True;
                  ACloseNeeded := (AUrl.Host <> FRequest.ResultUrl.Host) or
                    (AUrl.Port <> FRequest.ResultUrl.Port) or
                    (FRequest.ResponseHeaders.HeaderValue('connection', '')
                    = 'close');
                  FRedirectingUrl := AUrl;
                  if FRequest.MainThreadNotify then
                  begin
                    if not FRequest.IsWaiting then
                      Synchronize(HandleRedirection);
                  end
                  else
                    HandleRedirection;
                  FRequest.ResultUrl.Assign(AUrl);
                  if FRequest.ResultUrl.Scheme <> 'http' then
                    raise Exception.CreateFmt(SRedirectToNoHttp,
                      [FRequest.Url.Url, FRequest.ResultUrl.Url]);
                  FRequest.RequestHeaders.RemoveHeader('host');
                  if ACloseNeeded then
                    // 地址变了，需要重连，没必要继续接收剩下的内容
                    Exit;
                finally
                  FreeAndNil(AUrl);
                end;
              end;
            end;
            AHeaderReady := True;
            Inc(I);
            Break;
          end;
        end;
        Inc(I);
      end;
    until AHeaderReady or Terminated;
    if (not Terminated) and (FRequest.Action <> 'HEAD') then
    begin
      S := LowerCase(FRequest.ResponseHeaders.HeaderValue
        ('content-encoding', ''));
      AIsGZip := S = 'gzip';
      AIsDeflate := S = 'deflate';
      if FRequest.ResponseHeaders.HeaderValue('transfer-encoding', '') = 'chunked'
      then
      begin
        AReaded := ARecv - I;
        Move(ABuf[I], ABuf[0], AReaded);
        RecvChunks(AReaded);
      end
      else
      begin
        FRequest.FContentLength :=
          StrToInt64Def(FRequest.ResponseHeaders.HeaderValue
          ('content-length', ''), 0);
        if I < ARecv then
        begin
          ARecv := ARecv - I;
          Inc(FRequest.FRecvBytes, ARecv);
          FRequest.ResponseStream.WriteBuffer(ABuf[I], ARecv);
          AReaded := ARecv;
        end
        else
          AReaded := 0;
        while (AReaded < FRequest.FContentLength) and (not Terminated) do
        begin
          if FRequest.FContentLength - AReaded > 65536 then
            ARecv := recv(FSocket, ABuf, 65536, 0)
          else
            ARecv := recv(FSocket, ABuf, FRequest.FContentLength - AReaded, 0);
          if ARecv = SOCKET_ERROR then
            RaiseOSError;
          if ARecv > 0 then
            FRequest.ResponseStream.WriteBuffer(ABuf[0], ARecv)
          else
            Sleep(10);
          Inc(FRequest.FRecvBytes, ARecv);
          Inc(AReaded, ARecv);
          ReportStatus;
        end;
      end;
    end;
  end;

  procedure CreateAndConnect;
  var
    tm: timeval;
    mode: Integer;
    fdWrite, fdError: TFdSet;
    // const
    // FIONBIO=$51B;
  begin
    FSocket := Socket(PF_INET, SOCK_STREAM, 0);
    if FSocket = INVALID_SOCKET then
      RaiseOSError;
    // 连接到远程地址
    Addr.sin_port := htons(FRequest.ResultUrl.Port);
    Addr.sin_addr.S_addr := FRequest.ResultUrl.IPAddr;
    if Addr.sin_addr.S_addr = 0 then
      RaiseOSError;
    tm.tv_sec := FRequest.ConnectionTimeout div 1000;
    tm.tv_usec := (FRequest.ConnectionTimeout mod 1000) * 1000;
    mode := 1;
    if ioctlsocket(FSocket, FIONBIO, mode) <> NO_ERROR then
      RaiseOSError;
    connect(FSocket, SockAddr(Addr), SizeOf(Addr));
    mode := 0;
    if ioctlsocket(FSocket, FIONBIO, mode) <> NO_ERROR then
      RaiseOSError;
    FD_ZERO(fdWrite);
    FD_ZERO(fdError);
    FD_SET(FSocket, fdWrite);
    FD_SET(FSocket, fdError);
    select(0, nil, @fdWrite, @fdError, @tm);
    if not FD_ISSET(FSocket, fdWrite) then
      RaiseOSError;
  end;

begin
  FSocket := INVALID_SOCKET;
  ALastStatus := FRequest.FStatus;
  FRequest.FStatus := rsConnecting;
  ReportStatus;
  AHelper := TQStringCatHelperW.Create;
  try
    FillChar(Addr, SizeOf(Addr), 0);
    Addr.sin_family := AF_INET;
    FRequest.ResultUrl.Assign(FRequest.Url);
    FAllowRedirect := True;
    CreateAndConnect;
    repeat
      FAllowRedirect := false;
      ACloseNeeded := false;
      // 编码请求头问并发送
      SendRequest;
      if not Terminated then
      begin
        // FRequest.ResponseStream.Size := 0;
        RecvResponse;
        if ACloseNeeded then
        begin
          closesocket(FSocket);
          CreateAndConnect;
        end;
      end;
    until (not FAllowRedirect) or Terminated;
    if Terminated then
      FRequest.FStatus := rsAborted
    else
      FRequest.FStatus := rsProcessed;
    ReportStatus;
  except
    on E: Exception do
    begin
      FRequest.FStatus := rsAborted;
      FException := E;
      if FRequest.MainThreadNotify then
      begin
        if not FRequest.IsWaiting then
          Synchronize(HandleException)
      end
      else
        HandleException;
      ReportStatus;
    end;
  end;
  if FSocket <> INVALID_SOCKET then
    closesocket(FSocket);
  FreeAndNil(AHelper);
  FRequest.FStopTime := Now;
  if Assigned(FRequest.FNotifyEvent) then
    FRequest.FNotifyEvent.SetEvent;
end;

procedure TQHttpThread.HandleException;
begin
  FRequest.HandleException(FException);
end;

procedure TQHttpThread.HandleRedirection;
begin
  FAllowRedirect := True;
  if Assigned(FRequest.OnRedirect) then
    FRequest.OnRedirect(Self, FRedirectingUrl, FAllowRedirect);
end;

{ TQUrl }

constructor TQUrl.Create;
begin
  inherited;
end;

procedure TQUrl.Assign(ASource: TQUrl);
begin
  FUrl := ASource.FUrl;
  FUserName := ASource.FUserName;
  FPassword := ASource.FPassword;
  FScheme := ASource.FScheme;
  FHost := ASource.FHost;
  FDocument := ASource.FDocument;
  FBookmark := ASource.FBookmark;
  FPort := ASource.FPort;
  if Assigned(ASource.FParams) then
    Params.Assign(ASource.FParams);
  FChanged := ASource.FChanged;
  FSpaceAsPlus := ASource.SpaceAsPlus;
end;

constructor TQUrl.Create(AUrl: QStringW);
begin
  inherited Create;
  Url := AUrl;
end;

destructor TQUrl.Destroy;
begin
  if Assigned(FParams) then
    FreeAndNil(FParams);
  inherited;
end;

procedure TQUrl.DoParamsChanged(ASender: TObject);
begin
  FChanged := True;
end;

function TQUrl.GetDocumentFullPath: QStringW;
  function ExtractPath: QStringW;
  var
    p, ps, pl: PQCharW;
  begin
    p := PQCharW(FDocument);
    pl := p;
    ps := p;
    while p^ <> #0 do
    begin
      if p^ = '/' then
        pl := p;
      Inc(p);
    end;
    Result := StrDupX(ps, (IntPtr(pl) - IntPtr(ps)) shr 1);
  end;

begin
  if Length(FScheme) = 0 then
    Result := 'http'
  else
    Result := LowerCase(FScheme);
  Result := Result + '://';
  if Length(FUserName) > 0 then
  begin
    Result := Result + UrlEncode(FUserName, True);
    if Length(FPassword) > 0 then
      Result := Result + ':' + UrlEncode(FPassword, True);
    Result := Result + '@';
  end;
  Result := Result + RequestHost;
  if Length(FDocument) = 0 then
    Result := Result + '/'
  else
    Result := Result + ExtractPath + '/';
end;

function TQUrl.GetDocumentWithParams: QStringW;
begin
  if Length(FDocument) = 0 then
    Result := '/'
  else
    Result := FDocument;
  if Assigned(FParams) and (FParams.Count > 0) then
    Result := Result + '?' + FullParams;
  if Length(FBookmark) > 0 then
    Result := Result + '#' + UrlEncode(FBookmark, SpaceAsPlus);
end;

function TQUrl.GetFullParams: QStringW;
var
  I: Integer;
begin
  Result := '';
  for I := 0 to FParams.Count - 1 do
  begin
    if I = 0 then
      Result := Result + UrlEncode(FParams.Names[I], SpaceAsPlus) + '=' +
        UrlEncode(FParams.ValueFromIndex[I], SpaceAsPlus)
    else
      Result := Result + '&' + UrlEncode(FParams.Names[I], SpaceAsPlus) + '=' +
        UrlEncode(FParams.ValueFromIndex[I], SpaceAsPlus);
  end;
end;

function TQUrl.GetHostAddr: QStringW;
begin
  DNSLookupV4(Host, Result);
end;

function TQUrl.GetIPAddr: Cardinal;
begin
  Result := DNSLookupV4(Host);
end;

function TQUrl.GetOriginNames: QStringW;
var
  I: Integer;
begin
  Result := '';
  for I := 0 to FParams.Count - 1 do
  begin
    if I = 0 then
      Result := FParams.Names[I]
    else
      Result := Result + ',' + FParams.Names[I];
  end;
end;

function TQUrl.GetOriginParams: QStringW;
var
  I: Integer;
begin
  Result := '';
  for I := 0 to FParams.Count - 1 do
  begin
    if I = 0 then
      Result := Result + FParams.Names[I] + '=' + FParams.ValueFromIndex[I]
    else
      Result := Result + '&' + FParams.Names[I] + '=' +
        FParams.ValueFromIndex[I];
  end;
end;

function TQUrl.GetOriginValues: QStringW;
var
  I: Integer;
begin
  Result := '';
  for I := 0 to FParams.Count - 1 do
  begin
    if I = 0 then
      Result := FParams.ValueFromIndex[I]
    else
      Result := Result + ',' + FParams.ValueFromIndex[I];
  end;
end;

function TQUrl.GetParams: TStrings;
begin
  if not Assigned(FParams) then
  begin
    FParams := TStringList.Create;
    FParams.OnChange := DoParamsChanged;
  end;
  Result := FParams;
end;

function TQUrl.GetPort: Word;
begin
  if FPort = 0 then
    Result := SchemePort
  else
    Result := FPort;
end;

function TQUrl.GetRequestHost: QStringW;
var
  ADefPort: Word;
begin
  Result := FHost;
  ADefPort := GetSchemePort;
  if FPort = 0 then
    FPort := ADefPort
  else if (FPort <> ADefPort) or (FPort = 0) then
    Result := Result + ':' + IntToStr(FPort);
end;

function TQUrl.GetSchemePort: Word;
var
  S: QStringW;
begin
  S := LowerCase(FScheme);
  if (Length(S) = 0) or (S = 'http') then
    Result := 80
  else if S = 'https' then
    Result := 443
  else if S = 'ftp' then
    Result := 21
  else if S = 'ssh' then
    Result := 22
  else
    Result := 0;
end;

function TQUrl.GetUrl: QStringW;

// Format:scheme://username:password@host:port/documentpath?param1=value1[&param_n=value_n]#Bookmark
  procedure DoEncode;
  begin
    if Length(FScheme) = 0 then
      FUrl := 'http'
    else
      FUrl := LowerCase(FScheme);
    FUrl := FUrl + '://';
    if Length(FUserName) > 0 then
    begin
      FUrl := FUrl + UrlEncode(FUserName, True);
      if Length(FPassword) > 0 then
        FUrl := FUrl + ':' + UrlEncode(FPassword, SpaceAsPlus);
      FUrl := FUrl + '@';
    end;
    FUrl := FUrl + RequestHost;
    FUrl := FUrl + FullDocument;
    FChanged := false;
  end;

begin
  if FChanged then
    DoEncode;
  Result := FUrl;
end;

function TQUrl.GetUrlWithoutParams: QStringW;
  procedure DoEncode;
  begin
    if Length(FScheme) = 0 then
      FUrl := 'http'
    else
      FUrl := LowerCase(FScheme);
    FUrl := FUrl + '://';
    if Length(FUserName) > 0 then
    begin
      FUrl := FUrl + UrlEncode(FUserName, True);
      if Length(FPassword) > 0 then
        FUrl := FUrl + ':' + UrlEncode(FPassword, SpaceAsPlus);
      FUrl := FUrl + '@';
    end;
    FUrl := FUrl + RequestHost;
    FUrl := FUrl + Document;
    FChanged := false;
  end;

begin
  if FChanged then
    DoEncode;
  Result := FUrl;
end;

procedure TQUrl.RandSortParams;
// 此函数将参数的顺序打乱随机化,以避免用户从参数顺序推测签名一类的规律
var
  I, L, R: Integer;
begin
  for I := 0 to FParams.Count - 1 do
  begin
    L := Random(FParams.Count);
    R := Random(FParams.Count);
    if L <> R then
      FParams.Exchange(L, R);
  end;
end;

procedure TQUrl.SetBookmark(const Value: QStringW);
begin
  if FBookmark <> Value then
  begin
    FBookmark := Value;
    FChanged := True;
  end;
end;

procedure TQUrl.SetDocument(const Value: QStringW);
begin
  if FDocument <> Value then
  begin
    if Length(Value) > 0 then
    begin
      if PQCharW(Value)^ <> '/' then
        FDocument := '/' + Value
      else
        FDocument := Value;
    end
    else
      FDocument := '/';

    FChanged := True;
  end;
end;

procedure TQUrl.SetHost(const Value: QStringW);
begin
  if FHost <> Value then
  begin
    FHost := Value;
    FChanged := True;
  end;
end;

procedure TQUrl.SetPort(const Value: Word);
begin
  if FPort <> Value then
  begin
    FPort := Value;
    FChanged := True;
  end;
end;

procedure TQUrl.SetScheme(const Value: QStringW);
begin
  if FScheme <> Value then
  begin
    FScheme := Value;
    FChanged := True;
  end;
end;

procedure TQUrl.SetUrl(const Value: QStringW);
const
  NamePasswordDelimiter: PWideChar = ':';
  NameHostDelimiter: PWideChar = '@';
  BookmarkDelimiter: PWideChar = '#';
var
  AParams: TStringList;
  ADoc: QStringW;
  procedure DecodeNamePassword;
  var
    p, ps, pl: PQCharW;
  begin
    p := PQCharW(FHost);
    ps := p;
    pl := nil;
    while p^ <> #0 do
    begin
      if p^ = '@' then
        pl := p;
      Inc(p);
    end;
    if Assigned(pl) then
    begin
      Inc(pl);
      FHost := pl;
      FPassword := StrDupX(ps, pl - ps - 1);
      FUserName := DecodeTokenW(FPassword, NamePasswordDelimiter, NullQuoter,
        True, True);
    end
    else
    begin
      SetLength(FPassword, 0);
      SetLength(FUserName, 0);
    end;
  end;

begin
  if FUrl <> Value then
  begin
    FUrl := Value;
    AParams := TStringList.Create;
    try
      if UrlDecode(Value, FScheme, FHost, ADoc, FPort, AParams) then
      begin
        Document := ADoc;
        if AParams.Count > 0 then
        begin
          // 测试Bookmark
          FBookmark := AParams.ValueFromIndex[AParams.Count - 1];
          AParams.ValueFromIndex[AParams.Count - 1] :=
            DecodeTokenW(FBookmark, BookmarkDelimiter, NullQuoter, True, True);
          Params.Assign(AParams);
        end
        else
          FBookmark := '';
        // UrlDecode 解析的主机名中可能包含用户名，我们需要进行额外的处理，将UserName:Password@解析出来
        DecodeNamePassword;
      end
      else
      begin
        FScheme := '';
        FHost := '';
        FDocument := '';
        FUserName := '';
        FPassword := '';
        FBookmark := '';
        FPort := 0;
        FParams.Clear;
      end;
    finally
      FreeAndNil(AParams);
      FChanged := false;
    end;
  end;
end;

function SortByName(List: TStringList; Index1, Index2: Integer): Integer;
begin
{$IF RTLVersion>=31}
  if List.UseLocale then
  begin
    if List.CaseSensitive then
      Result := AnsiCompareStr(List.Names[Index1], List.Names[Index2])
    else
      Result := AnsiCompareText(List.Names[Index1], List.Names[Index2])
  end
  else
{$IFEND}
  begin
    if List.CaseSensitive then
      Result := CompareStr(List.Names[Index1], List.Names[Index2])
    else
      Result := CompareText(List.Names[Index1], List.Names[Index2]);
  end;
end;

procedure TQUrl.SortParams(ACaseSensitive, AUseLocale: Boolean;
  Compare: TStringListSortCompare);
begin
  FParams.CaseSensitive := ACaseSensitive;
{$IF RTLVersion>=31}
  FParams.UseLocale := AUseLocale;
{$IFEND}
  if Assigned(Compare) then
    FParams.CustomSort(Compare)
  else
    FParams.CustomSort(SortByName);
end;

{ TQHttpHeaders }

constructor TQHttpHeaders.Create;
begin
  inherited;
  NameValueSeparator := ':';
end;

function TQHttpHeaders.HeaderIndex(AName: QStringW): Integer;
var
  I: Integer;
begin
  Result := -1;
  AName := LowerCase(AName);
  for I := 0 to Count - 1 do
  begin
    if LowerCase(NameOfW(Strings[I], ':')) = AName then
    begin
      Result := I;
      Break;
    end;
  end;
end;

function TQHttpHeaders.HeaderValue(AName, ADefVal: QStringW): QStringW;
var
  AIdx: Integer;
begin
  AIdx := HeaderIndex(AName);
  if AIdx <> -1 then
    Result := Trim(ValueOfW(Strings[AIdx], ':'))
  else
    Result := ADefVal;
end;

procedure TQHttpHeaders.RemoveHeader(AName: QStringW);
var
  AIdx: Integer;
begin
  AIdx := HeaderIndex(AName);
  if AIdx <> -1 then
    Delete(AIdx);
end;

procedure TQHttpHeaders.ReplaceHeader(AName, AValue: QStringW);
var
  AIdx: Integer;
begin
  AIdx := HeaderIndex(AName);
  if AIdx <> -1 then
    Strings[AIdx] := AName + ':' + AValue
  else
    Add(AName + ':' + AValue);
end;

{ TQHttpRequestItem }

procedure TQHttpRequestItem.AfterPush;
begin

end;

procedure TQHttpRequestItem.BeforePush;
begin

end;

constructor TQHttpRequestItem.Create(ASender: TObject; AIsSyncMode: Boolean);
begin
  inherited Create;
  InternalCreate(ASender, AIsSyncMode);
end;

constructor TQHttpRequestItem.Create(ASender: TObject);
begin
  inherited Create;
  InternalCreate(ASender, false);
end;

function TQHttpRequestItem.CreateInternalStream: TStream;
begin
  Result := TMemoryStream.Create;
end;

destructor TQHttpRequestItem.Destroy;
begin
  if Assigned(FResponseStream) and FResponseStreamOwner then
    FreeAndNil(FResponseStream);
  if Assigned(FRequestStream) and FRequestStreamOwner then
    FreeAndNil(FRequestStream);
  if Assigned(FSyncEvent) then
    FreeAndNil(FSyncEvent);
  inherited;
end;

procedure TQHttpRequestItem.DoAfterDone(ASender: TObject);
{$IFNDEF SYSHTTP}
var
  AClient: THttpClientClass;
{$ENDIF}
begin
  FStopTime := Now;
  if Assigned(HttpClient) then
  begin
{$IFDEF SYSHTTP}
    if Assigned(FResponse) then
    begin
      with FResponse as IHttpResponse do
      begin
        if ((StatusCode >= 300) and (StatusCode <= 303)) or (StatusCode = 307)
        then
        begin
          // 官方规定是如果POST改成GET，我暂时不改不知道行不行:)
          FResultUrl := UrlMerge(ResultUrl, GetHeaderValue('Location'));
          if MainThreadNotify then
            TThread.Synchronize(nil, DoRedirect)
          else
            DoRedirect;
          if (FRedirectTimes < FMaxRedirectTimes) and FAllowRedirect then
            StartWith(HttpClient);
          Exit;
        end
        else
        begin
          FStatusCode := StatusCode;
          FStatusText := StatusText;
          (FResponseHeaders as THeadersHelper).Headers := GetHeaders;
          // (FRequestHeaders as THeadersHelper).Headers:=(HttpClient as THttpClientClass).Get.
        end;
      end;
    end;
    // (FResponseHeaders as THeadersHelper):=AClient.
{$ELSE}
    AClient := THttpClientClass(HttpClient);
{$IF RTLVersion=18}
    (ObjectOf(FResponseHeaders) as THeadersHelper)
{$ELSE}
    (FResponseHeaders as THeadersHelper)
{$IFEND}.FHeaders.Assign(AClient.ResponseHeaders);
{$IF RTLVersion=18}
    (ObjectOf(FRequestHeaders) as THeadersHelper)
{$ELSE}
    (FRequestHeaders as THeadersHelper)
{$IFEND}
      .FHeaders.Assign(AClient.RequestHeaders);
    FStatusCode := AClient.StatusCode;
    FStatusText := AClient.StatusText;
    FResultUrl := AClient.ResultUrl.Url;
{$ENDIF}
  end;
  if not FAbort then
    DoProgress;
  if MainThreadNotify then
    TThread.Synchronize(nil, DoMainThreadAfterDone)
  else
    DoMainThreadAfterDone;
end;

procedure TQHttpRequestItem.DoClientBound;
begin
  if Assigned(FOnClientBound) then
    FOnClientBound(Self, FHttpClient);
end;

procedure TQHttpRequestItem.DoClientRedirect(ASender: TObject; ANewUrl: TQUrl;
  var Allow: Boolean);
begin
  FResultUrl := ANewUrl.Url;
  if MainThreadNotify then
    TThread.Synchronize(nil, DoRedirect)
  else
    DoRedirect;
  Allow := FAllowRedirect;
end;

procedure TQHttpRequestItem.DoError;
begin
  if Assigned(OnError) then
    OnError(Self, FLastException);
  FLastException := nil;
end;

procedure TQHttpRequestItem.DoMainThreadAfterDone;
begin
  try
    if Assigned(FAfterDone) then
      FAfterDone(Self);
  finally
    FQueue.RequestDone(Self);
  end;
end;

procedure TQHttpRequestItem.DoMainThreadRecvProgress;
begin
  if Assigned(FOnRecvData) then
    FOnRecvData(Self, FTotalBytes, FRecvBytes, FAbort);
end;

function TQHttpRequestItem.DoProgress: Boolean;
begin
  if Assigned(FOnRecvData) then
  begin
    if MainThreadNotify then
      TThread.Synchronize(nil, DoMainThreadRecvProgress)
    else
      FOnRecvData(Self, FTotalBytes, FRecvBytes, FAbort);
  end;
  Result := FAbort;
  if FAbort then
  begin
    FStatusCode := 1223;
    // Windows Error code of ERROR_CANCELLED;
    FStatusText := SUserCanceled;
  end;
end;

procedure TQHttpRequestItem.DoRedirect;
begin
  FAllowRedirect := True;
  Inc(FRedirectTimes);
  if Assigned(FBeforeUrlRedirect) then
    FBeforeUrlRedirect(Self, FAllowRedirect);
end;

procedure TQHttpRequestItem.DoProgress(const Sender: TObject;
  AContentLength, AReadCount: Int64; var Abort: Boolean);
var
  ATick: Cardinal;
begin
  if AReadCount = 0 then
  begin

  end;
  FRecvBytes := AReadCount;
  FTotalBytes := AContentLength;
{$IFDEF SYSHTTP}
  if (not FRequestHeaderReady) and (Sender is THttpRequest) then
  begin
    FRequestHeaderReady := True;
    (FRequestHeaders as THeadersHelper).Headers := (Sender as THttpRequest)
      .GetHeaders;
  end;
{$ENDIF}
  if Assigned(FOnRecvData) then
  begin
    ATick :=
{$IFDEF UNICODE}TThread.{$ENDIF}GetTickCount;
    if ATick - FLastProgressTick > FProgressInterval then
    begin
      FLastProgressTick := ATick;
      Abort := DoProgress;
    end;
  end;
end;

function TQHttpRequestItem.GetCanStart: Boolean;
begin
  Result := True;
end;

function TQHttpRequestItem.GetContentAsString: QStringW;
var
  ACharset: QStringW;
  function StreamToBytes: TBytes;
  begin
{$IFDEF UNICODE}
    if ResponseStream is TBytesStream then
      Result := (ResponseStream as TBytesStream).Bytes
    else
    begin
{$ENDIF}
      SetLength(Result, ResponseStream.Size);
      ResponseStream.ReadBuffer(Result[0], Length(Result));
{$IFDEF UNICODE}
    end;
{$ENDIF}
  end;

begin
  if ResponseStream.Size > 0 then
  begin
    ACharset := ResponseCharset;
    ResponseStream.Position := 0;
    if Length(ACharset) > 0 then
    begin
      if (ACharset = 'utf-8') or (ACharset = 'utf8') then
        // utf8是错误的写法，但为了兼容加入
        Result := LoadTextW(ResponseStream, teUTF8)
      else if ACharset = 'utf-16' then
        Result := LoadTextW(ResponseStream, teUnicode16LE)
      else
      begin
{$IFDEF UNICODE}
        begin
          if ACharset = 'gbk' then // GBK和CP936是一个代码页
            ACharset := 'cp936';
          Result := TEncoding.GetEncoding(ACharset).GetString(StreamToBytes);
        end;
{$ELSE}
        Result := LoadTextW(ResponseStream);
{$ENDIF}
      end;
    end
    else
      Result := LoadTextW(ResponseStream);
  end
  else
    Result := '';
end;

function TQHttpRequestItem.GetResponseStream: TStream;
begin
  if not Assigned(FResponseStream) then
  begin
    if not FAbort then
    begin
      FResponseStream := CreateInternalStream;
      FResponseStreamOwner := True;
    end;
  end;
  Result := FResponseStream;
end;

function TQHttpRequestItem.GetResponseCharset: QStringW;
var
  AValue: QStringW;
const
  NullQuoter: WideChar = #0;
  function DequotedValue(S: QStringW): QStringW;
  var
    p: PQCharW;
  begin
    p := PQCharW(S);
    if p^ = '''' then
      Result := DequotedStrW(S)
    else if p^ = '"' then
      Result := DequotedStrW(S, '"')
    else
      Result := S;
  end;

  function DecodeContentType(S: QStringW): QStringW;
  var
    APair: QStringW;
  const
    ValueDelimiter: PWideChar = ';';

  begin
    Result := '';
    repeat
      APair := DecodeTokenW(S, ValueDelimiter, NullQuoter, false, True);
      if Trim(NameOfW(APair, '=')) = 'charset' then
      begin
        Result := LowerCase(Trim(ValueOfW(APair, '=')));
        Break;
      end;
    until Length(S) = 0;
  end;
  function CharsetFromHtml: QStringW;
  var
    ABuf: array [0 .. 8191] of Byte; // 从前8K里解析，如果不存在，则认为不存在
    AReaded: Integer;
    AText, ALine, AName, APair, AContent: QStringW;
    p, ps: PQCharW;
    AIsContentType: Boolean;
  const
    SpaceChars: PWideChar = ' '#9#13#10;
    TagEnd: PWideChar = '>';
  begin
    FResponseStream.Position := 0;
    AReaded := FResponseStream.read(ABuf[0], 8192);
    // 假设为Ansi编码
    AText := LowerCase(AnsiDecode(PQCharA(@ABuf[0]), AReaded));
    p := PQCharW(AText);
    p := StrStrW(p, '<head>');
    if Assigned(p) then
    begin
      ps := p;
      p := StrStrW(p, '</head>');
      if Assigned(p) then // 只关心 Header 部分
      begin
        AText := StrDupX(ps, (IntPtr(p) - IntPtr(ps)) shr 1);
        p := PQCharW(AText);
      end;
      while Assigned(p) and (p^ <> #0) do
      begin
        p := StrStrW(p, '<meta');
        if Assigned(p) then
        begin
          Inc(p, 5);
          if IsSpaceW(p) then
          begin
            SkipSpaceW(p);
            ps := p;
            SkipUntilW(p, TagEnd);
            ALine := StrDupX(ps, (IntPtr(p) - IntPtr(ps)) shr 1 - 1);
            // />不包含在内
            // <meta charset=xxx> 或 <meta http-equiv="content-type" content="text/html; charset=XXX">
            while Length(ALine) > 0 do
            begin
              APair := DecodeTokenW(ALine, SpaceChars, NullQuoter, false, True);
              AName := Trim(NameOfW(APair, '='));
              if AName = 'charset' then
              begin
                Result := DequotedValue(ValueOfW(APair, '='));
                Exit;
              end
              else
              begin
                AContent := '';
                AIsContentType := false;
                repeat
                  if AName = 'content' then
                    AContent := DequotedValue(ValueOfW(APair, '='))
                  else if (AName = 'http-equiv') and
                    (DequotedValue(ValueOfW(APair, '=')) = 'content-type') then
                    AIsContentType := True;
                  APair := DecodeTokenW(ALine, SpaceChars, NullQuoter,
                    false, True);
                  AName := Trim(NameOfW(APair, '='));
                until Length(ALine) = 0;
                if AIsContentType then
                begin
                  Result := DecodeContentType(AContent);
                  Exit;
                end;
              end;
            end;
          end;
        end;
      end;
    end;
    Result := '';
  end;

  function CharsetByDetect: QStringW;
  var
    ABuf: array [0 .. 8191] of Byte;
    AReaded: Integer;
    ABom: Boolean;
  begin
    FResponseStream.Position := 0;
    AReaded := FResponseStream.read(ABuf[0], 8192);
    case DetectTextEncoding(@ABuf[0], AReaded, ABom) of
      teUTF8:
        Result := 'utf-8';
      teUnicode16LE:
        Result := 'utf-16';
      teUnicode16BE:
        Result := 'utf-16be'
    else // Unknown,treat as ascii
      Result := 'iso-8859-1';
    end;

  end;
  function CharsetFromStream: QStringW;
  begin
    // 假设是HTML
    Result := CharsetFromHtml;
    if Length(Result) = 0 then
      Result := CharsetByDetect;
  end;

begin
  AValue := ResponseHeaders.HeaderValue('content-type', '');
  if Length(AValue) = 0 then
    Result := CharsetFromStream
  else
    Result := DecodeContentType(AValue);
end;

function TQHttpRequestItem.GetResultUrl: QStringW;
begin
  if Length(FResultUrl) = 0 then
    Result := FUrl
  else
    Result := FResultUrl;
end;

function TQHttpRequestItem.GetUserAgent: QStringW;
begin
  Result := RequestHeaders.HeaderValue('user-agent', DefaultUserAgent)
end;

procedure TQHttpRequestItem.InternalCreate(ASender: TObject;
  AIsSyncMode: Boolean);
begin
  FSender := ASender;
  FRequestHeaders := THeadersHelper.Create;
  FResponseHeaders := THeadersHelper.Create;
  FMaxRedirectTimes := 3;
  FProgressInterval := 1000;
  FConnectionTimeout := 60000;
  FAction := reqGet;
  if AIsSyncMode then
    FSyncEvent := TEvent.Create(nil, false, false, '', false);
end;

function TQHttpRequestItem.NeedRequestStream: TStream;
begin
  if not Assigned(FRequestStream) then
  begin
    FRequestStream := TMemoryStream.Create;
    FRequestStreamOwner := True;
  end;
  Result := FRequestStream;
end;

procedure TQHttpRequestItem.SetResponseStream(const Value: TStream);
begin
  if Value <> FResponseStream then
  begin
    if Assigned(FResponseStream) and FResponseStreamOwner then
      FreeAndNil(FResponseStream);
    FResponseStreamOwner := false;
    FResponseStream := Value;
  end;
end;

procedure TQHttpRequestItem.SetUserAgent(const Value: QStringW);
begin
  RequestHeaders.Values['user-agent'] := Value;
end;

function DecodeExceptionErrorCode(AMsg: QStringW): Integer;
var
  p: PQCharW;
begin
  p := PQCharW(AMsg);
  Result := StrToIntDef(StrBetween(p, '(', ')', false), 0);
end;

function TQHttpRequestItem.StartWith(AHttpClient: TObject): Boolean;
var
  AClient: THttpClientClass;
begin
  // 如果当前不能启动，则直接返回
  Result := CanStart;
  if not Result then
    Exit;
  FHttpClient := AHttpClient;
  FStartTime := Now;
  FRequestHeaderReady := false;
  FStatusCode := 0;
  FStatusText := '';
  FResponse := nil;
  AClient := AHttpClient as THttpClientClass;
  AClient.OnReceiveData := DoProgress;
  AClient.ConnectionTimeout := FConnectionTimeout;
  if MainThreadNotify then
    TThread.Synchronize(nil, DoClientBound)
  else
    DoClientBound;
  AClient.UserAgent := UserAgent;
{$IFDEF SYSHTTP}
  AClient.HandleRedirects := false; // 自带的HTTP客户端处理跳转不正确，我们自己处理
  // 系统自带的THttpClient只能同步
  case Action of
    reqGet:
      // AClient.BeginGet(ResultUrl, ResponseStream,
      // (RequestHeaders as THeadersHelper).Headers)
      Workers.Post(
        procedure(AJob: PQJob)
        begin
          try
            FResponse := AClient.Get(ResultUrl, ResponseStream,
              (RequestHeaders as THeadersHelper).Headers);
          except
            on E: Exception do
            begin
              // THttpClient 异步格式为：error sending data():....
              FStatusCode := GetLastError;
              if FStatusCode = 0 then
                FStatusCode := DecodeExceptionErrorCode(E.Message);
              FStatusText := SysErrorMessage(FStatusCode);
              FLastException := E;
              FAbort := True;
              TThread.Synchronize(nil, DoError);
            end;
          end;
          DoAfterDone(AClient);
        end, nil);
    reqPost:
      begin
        Workers.Post(
          procedure(AJob: PQJob)
          begin
            try
              FResponse := AClient.Post(ResultUrl, RequestStream,
                ResponseStream, (RequestHeaders as THeadersHelper).Headers);
            except
              on E: Exception do
              begin
                FStatusCode := GetLastError;
                if FStatusCode = 0 then
                  FStatusCode := DecodeExceptionErrorCode(E.Message);
                FStatusText := SysErrorMessage(FStatusCode);
                FLastException := E;
                FAbort := True;
                TThread.Synchronize(nil, DoError);
              end
            end;
            DoAfterDone(AClient);
          end, nil);
      end;
    reqHead:
      Workers.Post(
        procedure(AJob: PQJob)
        begin
          try
            FResponse := AClient.Head(ResultUrl,
              (RequestHeaders as THeadersHelper).Headers);
          except
            on E: Exception do
            begin
              FStatusCode := GetLastError;
              if FStatusCode = 0 then
                FStatusCode := DecodeExceptionErrorCode(E.Message);
              FStatusText := SysErrorMessage(FStatusCode);
              FLastException := E;
              FAbort := True;
              TThread.Synchronize(nil, DoError);
            end
          end;
          DoAfterDone(AClient);
        end, nil);
  end;
{$ELSE}
  AClient.AfterDone := DoAfterDone;
  AClient.OnRedirect := DoClientRedirect;
  AClient.RequestHeaders.Assign
    (({$IF RTLVersion=18}ObjectOf(RequestHeaders){$ELSE}RequestHeaders{$IFEND} as THeadersHelper).FHeaders);
  AClient.MaxRedirects := FMaxRedirectTimes;
  case Action of
    reqGet:
      AClient.Get(Url, ResponseStream, false);
    reqPost:
      AClient.Post(Url, ContentStream, ResponseStream, false);
    reqHead:
      AClient.Head(Url, false);
  end;

{$ENDIF}
end;

function TQHttpRequestItem.WaitFor(ATimeout: Cardinal): TWaitResult;
begin
  if Assigned(FSyncEvent) then
  begin
    if GetCurrentThreadId = MainThreadId then
      Result := MsgWaitForEvent(FSyncEvent, ATimeout)
    else
      Result := FSyncEvent.WaitFor(ATimeout);
  end
  else
    Result := wrError;
end;

{ TQHttpRequests }

procedure TQHttpRequests.Clear(AExclude: TQHttpRequestItem);
var
  AReq: TQHttpRequestItem;
  I: Integer;
  AEvent: TEvent;
begin
  AEvent := TEvent.Create;
  while FBusyClients > 0 do
    MsgWaitForEvent(AEvent, 0);
  FreeAndNil(AEvent);
  Lock;
  try
    I := 0;
    while I < FRequests.Count do
    begin
      AReq := FRequests[I];
      if AReq <> AExclude then
      begin
        AReq.FStatusCode := 1223;
        // Windows Error code of ERROR_CANCELLED;
        AReq.FStatusText := SUserCanceled;
        AReq.FAbort := True;
        if not Assigned(AReq.HttpClient) then
          RequestDone(AReq)
        else
          Inc(I);
      end
      else
        Inc(I);
    end;
  finally
    Unlock;
  end;
end;

constructor TQHttpRequests.Create;
begin
  inherited Create;
  FCS := TCriticalSection.Create;
  FRequests := TQRequestList.Create;
  FCookieManager := TCookieManager.Create;
  FMaxClients := 1; // 默认只有一个工作
  FHttpClients := TQSimplePool.Create(FMaxClients, SizeOf(Pointer));
  FHttpClients.OnNewItem := DoNewHttpClient;
  FHttpClients.OnFree := DoFreeHttpClient;
  FDefaultHeaders := THeadersHelper.Create;
  FDefaultHeaders.Values['User-Agent'] := DefaultUserAgent;
end;

destructor TQHttpRequests.Destroy;
begin
  Clear;
  FreeAndNil(FHttpClients);
  FreeAndNil(FRequests);
  FreeAndNil(FCookieManager);
  FreeAndNil(FCS);
  inherited;
end;

procedure TQHttpRequests.DoEventReqDone(ASender: TObject);
var
  AReq: TQHttpRequestItem;
begin
  AReq := ASender as TQHttpRequestItem;
  if Assigned(AReq.FSyncEvent) then
    AReq.FSyncEvent.SetEvent;
end;

procedure TQHttpRequests.DoFreeHttpClient(ASender: TQSimplePool;
AData: Pointer);
begin
  FreeAndNil(AData);
end;

procedure TQHttpRequests.DoNewHttpClient(ASender: TQSimplePool;
var AData: Pointer);
begin
  AData := THttpClientClass.Create;
end;

function TQHttpRequests.Get(const AUrl: QStringW; var AResult: QStringW;
AHeaders: IQHttpHeaders): Integer;
var
  AReq: TQHttpRequestItem;
begin
  AReq := TQHttpRequestItem.Create(Self, True);
  try
    AReq._AddRef;
    AReq.Url := AUrl;
    AReq.Action := reqGet;
    if Assigned(AHeaders) then
      AReq.RequestHeaders.Replace(AHeaders);
    AReq.AfterDone := DoEventReqDone;
    Push(AReq);
    AReq.WaitFor(INFINITE);
    AResult := AReq.ContentAsString;
    Result := AReq.StatusCode;
  finally
    AReq._Release;
  end;
end;

function TQHttpRequests.Get(const AUrl: QStringW; AReplyStream: TStream;
AHeaders: IQHttpHeaders): Integer;
var
  AReq: TQHttpRequestItem;
begin
  AReq := TQHttpRequestItem.Create(Self, True);
  try
    AReq._AddRef;
    AReq.Url := AUrl;
    AReq.Action := reqGet;
    AReq.ResponseStream := AReplyStream;
    AReq.AfterDone := DoEventReqDone;
    if Assigned(AHeaders) then
      AReq.RequestHeaders.Replace(AHeaders);
    Push(AReq);
    AReq.WaitFor(INFINITE);
    Result := AReq.StatusCode;
  finally
    AReq._Release;
  end;
end;

procedure TQHttpRequests.Lock;
begin
  FCS.Enter;
end;

function TQHttpRequests.NewHeaders: IQHttpHeaders;
begin
  Result := THeadersHelper.Create;
end;

function TQHttpRequests.Post(const AUrl: QStringW; var AResult: QStringW;
AHeaders: IQHttpHeaders): Integer;
var
  AReq: TQHttpRequestItem;
begin
  AReq := TQHttpRequestItem.Create(Self, True);
  try
    AReq._AddRef;
    AReq.Url := AUrl;
    AReq.Action := reqPost;
    if Assigned(AHeaders) then
      AReq.RequestHeaders.Replace(AHeaders);
    AReq.AfterDone := DoEventReqDone;
    Push(AReq);
    AReq.WaitFor(INFINITE);
    AResult := AReq.ContentAsString;
    Result := AReq.StatusCode;
  finally
    AReq._Release;
  end;
end;

function TQHttpRequests.Post(const AUrl: QStringW; AReplyStream: TStream;
AHeaders: IQHttpHeaders): Integer;
var
  AReq: TQHttpRequestItem;
begin
  AReq := TQHttpRequestItem.Create(Self, True);
  try
    AReq._AddRef;
    AReq.Url := AUrl;
    AReq.Action := reqPost;
    AReq.ResponseStream := AReplyStream;
    AReq.AfterDone := DoEventReqDone;
    if Assigned(AHeaders) then
      AReq.RequestHeaders.Replace(AHeaders);
    Push(AReq);
    AReq.WaitFor(INFINITE);
    Result := AReq.StatusCode;
  finally
    AReq._Release;
  end;
end;

function TQHttpRequests.Post(const AUrl: QStringW; AFormParams: TStrings;
AReplyStream: TStream; AfterDone: TNotifyEvent;
AHeaders: IQHttpHeaders): Integer;
var
  AReq: TQHttpRequestItem;
  I: Integer;
  AParams: QStringW;
begin
  AReq := TQHttpRequestItem.Create(Self, not Assigned(AfterDone));
  try
    AReq._AddRef;
    if not Assigned(AfterDone) then
      AReq.AfterDone := DoEventReqDone
    else
    begin
      AReq.AfterDone := AfterDone;
    end;
    AReq.Url := AUrl;
    AReq.Action := reqPost;
    if Assigned(AFormParams) and (AFormParams.Count > 0) then
    begin
      AReq.Action := reqPost;
      AReq.RequestHeaders.Values['Content-Type'] :=
        'application/x-www-form-urlencoded;charset=UTF-8';
      AParams := '';
      for I := 0 to AFormParams.Count - 1 do
        AParams := AParams + UrlEncode(AFormParams.Names[I], True) + '=' +
          UrlEncode(AFormParams.ValueFromIndex[I], True) + '&';
      SetLength(AParams, Length(AParams) - 1);
      SaveTextU(AReq.NeedRequestStream, AParams, false);
      AReq.RequestStream.Position := 0;
    end;
    if Assigned(AReplyStream) then
      AReq.ResponseStream := AReplyStream;
    if Assigned(AHeaders) then
      AReq.RequestHeaders.Replace(AHeaders);
    Push(AReq);
    if Assigned(AfterDone) then
      Result := 200
    else
    begin
      AReq.WaitFor(INFINITE);
      Result := AReq.StatusCode;
    end;
  finally
    AReq._Release;
  end;
end;

function TQHttpRequests.Post(const AUrl: QStringW; AFormParams: TStrings;
var AReply: QStringW): Integer;
var
  AReq: TQHttpRequestItem;
  I: Integer;
  AParams: QStringW;
begin
  AReq := TQHttpRequestItem.Create(Self, True);
  try
    AReq._AddRef;
    AReq.AfterDone := DoEventReqDone;
    AReq.Url := AUrl;
    AReq.Action := reqPost;
    if Assigned(AFormParams) and (AFormParams.Count > 0) then
    begin
      AReq.Action := reqPost;
      AReq.RequestHeaders.Values['Content-Type'] :=
        'application/x-www-form-urlencoded;charset=UTF-8';
      AParams := '';
      for I := 0 to AFormParams.Count - 1 do
        AParams := AParams + UrlEncode(AFormParams.Names[I], True) + '=' +
          UrlEncode(AFormParams.ValueFromIndex[I], True) + '&';
      SetLength(AParams, Length(AParams) - 1);
      SaveTextU(AReq.NeedRequestStream, AParams, false);
      AReq.RequestStream.Position := 0;
    end;
    Push(AReq);
    AReq.WaitFor(INFINITE);
    Result := AReq.StatusCode;
    if Result = 200 then
      AReply := AReq.ContentAsString
    else
      SetLength(AReply, 0);
  finally
    AReq._Release;
  end;
end;

function TQHttpRequests.Post(const AUrl: QStringW; AContent: TStrings;
AReplyStream: TStream; AContentType: QStringW; AfterDone: TNotifyEvent;
AHeaders: IQHttpHeaders): Integer;
var
  AReq: TQHttpRequestItem;
  AName, AValue: QStringW;
begin
  AReq := TQHttpRequestItem.Create(Self, not Assigned(AfterDone));
  try
    AReq._AddRef;
    if not Assigned(AfterDone) then
      AReq.AfterDone := DoEventReqDone
    else
    begin
      AReq.AfterDone := AfterDone;
    end;
    AReq.Url := AUrl;
    AReq.Action := reqPost;
    if Assigned(AContent) and (AContent.Count > 0) then
    begin
      AReq.Action := reqPost;
      AReq.RequestHeaders.Values['Content-Type'] := AContentType;

      SaveTextU(AReq.NeedRequestStream, AContent.DelimitedText, false);
      AReq.RequestStream.Position := 0;
    end;
    if Assigned(AReplyStream) then
      AReq.ResponseStream := AReplyStream;
    if Assigned(AHeaders) then
      AReq.RequestHeaders.Replace(AHeaders);
    Push(AReq);
    if Assigned(AfterDone) then
      Result := 200
    else
    begin
      AReq.WaitFor(INFINITE);
      Result := AReq.StatusCode;
    end;
  finally
    AReq._Release;
  end;
end;

function TQHttpRequests.Post(const AUrl: QStringW; AContent: QStringW;
var AReply: QStringW; AContentType: QStringW): Integer;
var
  AReq: TQHttpRequestItem;
begin
  AReq := TQHttpRequestItem.Create(Self, True);
  try
    AReq._AddRef;
    AReq.AfterDone := DoEventReqDone;
    AReq.Url := AUrl;
    AReq.Action := reqPost;
    if Length(AContent) > 0 then
    begin
      AReq.Action := reqPost;
      AReq.RequestHeaders.Values['Content-Type'] := AContentType;
      SaveTextU(AReq.NeedRequestStream, AContent, false);
      AReq.RequestStream.Position := 0;
    end;
    Push(AReq);
    AReq.WaitFor(INFINITE);
    Result := AReq.StatusCode;
    if Result = 200 then
      AReply := AReq.ContentAsString
    else
      SetLength(AReply, 0);
  finally
    AReq._Release;
  end;
end;

procedure TQHttpRequests.Push(ARequest: TQHttpRequestItem);
begin
  ARequest.RequestHeaders.Merge(DefaultHeaders);
  ARequest.FQueue := Self;
  if not(ARequest.Action in [reqGet, reqHead, reqPost]) then
    // 其它的统一当Get处理，不支持其它操作
    ARequest.Action := reqGet;
  ARequest.BeforePush;
  Lock;
  try
    FRequests.Add(ARequest);
  finally
    Unlock;
    ARequest.AfterPush;
  end;
  Start(ARequest);
end;

procedure TQHttpRequests.RequestDone(ARequest: TQHttpRequestItem);
var
  I: Integer;
  AClient: TObject;
  ATemp: TQHttpRequestItem;
begin
  if Assigned(ARequest) then
  begin
    ARequest.FIsDone := True;
    ARequest._AddRef;
    Lock;
    try
      AClient := ARequest.HttpClient;
      FRequests.Remove(ARequest);
      if Assigned(AClient) then
      begin
        for I := 0 to FRequests.Count - 1 do
        begin
          ATemp := FRequests[I] as TQHttpRequestItem;
          if not Assigned(ATemp.HttpClient) then
          begin
            if ATemp.StartWith(AClient) then
              Exit;
          end;
        end;
      end;
      // 没有需要处理的请求了，则将自己标记为空闲
      FHttpClients.Push(AClient);
      Dec(FBusyClients);
    finally
      Unlock;
      ARequest._Release;
    end;
  end;
end;

function TQHttpRequests.Rest(const AUrl: QStringW; AContent: QStringW;
AResult: TQJson; AHeaders: IQHttpHeaders; AfterDone: TNotifyEvent;
Action: TQHttpClientAction): Integer;
var
  AReq: TQHttpRequestItem;
  I: Integer;
begin
  AReq := TQHttpRequestItem.Create(Self, not Assigned(AfterDone));
  try
    AReq._AddRef;
    if not Assigned(AfterDone) then
      AReq.AfterDone := DoEventReqDone
    else
    begin
      AReq.AfterDone := AfterDone;
    end;
    AReq.Url := AUrl;
    if Length(AContent) > 0 then
    begin
      AReq.Action := reqPost;
      AReq.RequestHeaders.Values['Content-Type'] :=
        'application/x-www-form-urlencoded;charset=UTF-8';
      SaveTextU(AReq.NeedRequestStream, AContent, false);
      AReq.RequestStream.Position := 0;
    end
    else if Action = reqUnknown then
      AReq.Action := reqGet
    else
      AReq.Action := Action;
    if Assigned(AHeaders) then
      AReq.RequestHeaders.Replace(AHeaders);
    Push(AReq);
    if Assigned(AfterDone) then
      Result := 200
    else
    begin
      AReq.WaitFor(INFINITE);
      Result := AReq.StatusCode;
      if Assigned(AResult) and (Result = 200) then
      begin
        if not AResult.TryParse(AReq.ContentAsString) then
          raise Exception.CreateFmt(SContnetIsNotJson, [AReq.ContentAsString]);
      end;
    end;
  finally
    AReq._Release;
  end;
end;

function TQHttpRequests.Rest(const AUrl: QStringW; ASource, AResult: TQJson;
AHeaders: IQHttpHeaders; AfterDone: TNotifyEvent;
Action: TQHttpClientAction): Integer;
var
  AReq: TQHttpRequestItem;
begin
  AReq := TQHttpRequestItem.Create(Self, not Assigned(AfterDone));
  try
    AReq._AddRef;
    if not Assigned(AfterDone) then
      AReq.AfterDone := DoEventReqDone
    else
    begin
      AReq.AfterDone := AfterDone;
    end;
    AReq.Url := AUrl;
    if Assigned(ASource) then
    begin
      AReq.Action := reqPost;
      AReq.RequestHeaders.Values['Content-Type'] :=
        'application/json;charset=UTF-8';
      ASource.SaveToStream(AReq.NeedRequestStream, teUTF8, false, false);
      AReq.RequestStream.Position := 0;
    end
    else if Action = reqUnknown then
      AReq.Action := reqGet
    else
    begin
      AReq.Action := Action;
    end;
    if Assigned(AHeaders) then
      AReq.RequestHeaders.Replace(AHeaders);
    Push(AReq);
    if Assigned(AfterDone) then
      Result := 200
    else
    begin
      AReq.WaitFor(INFINITE);
      Result := AReq.StatusCode;
      if Assigned(AResult) and (Result = 200) then
      begin
        if not AResult.TryParse(AReq.ContentAsString) then
          raise Exception.CreateFmt(SContnetIsNotJson, [AReq.ContentAsString]);
      end;
    end;
  finally
    AReq._Release;
  end;
end;

function TQHttpRequests.Rest(const AUrl: QStringW; AParams: TStrings;
AResult: TQJson; AHeaders: IQHttpHeaders; AfterDone: TNotifyEvent;
Action: TQHttpClientAction): Integer;
var
  AContent: QStringW;
  I: Integer;
begin
  AContent := '';
  for I := 0 to AParams.Count - 1 do
    AContent := AContent + UrlEncode(AParams.Names[I], True) + '=' +
      UrlEncode(AParams.ValueFromIndex[I], True) + '&';
  SetLength(AContent, Length(AContent) - 1);
  Result := Rest(AUrl, AContent, AResult, AHeaders, AfterDone, Action);
end;

function TQHttpRequests.Soap(const AUrl, Action, ARequestBody: QStringW;
var AResult: QStringW): Integer;
var
  AReq: TQHttpRequestItem;
  AXML: TQXML;
  p: PQCharW;
begin
  AXML := nil;
  AReq := TQHttpRequestItem.Create(Self, True);
  try
    AReq._AddRef;
    AReq.AfterDone := DoEventReqDone;
    AReq.Url := AUrl;
    AReq.Action := reqGet;
    Push(AReq);
    AReq.WaitFor(INFINITE);
    if AReq.StatusCode = 200 then
    begin
      AXML := TQXML.Create;
      AXML.Parse(AReq.ContentAsString);

      p := PQCharW(AUrl);
      AReq.Url := DecodeTokenW(p, '?', #0, false, false);
      AReq.Action := reqPost;
      if Length(Action) = 0 then
        AReq.RequestHeaders.Values['SOAPAction'] := '""'
      else
        AReq.RequestHeaders.Values['SOAPAction'] := Action;
      if Length(ARequestBody) > 0 then
      begin
        AReq.Action := reqPost;
        if not StartWithW(PQCharW(ARequestBody), '<?xml', false) then
          SaveTextU(AReq.NeedRequestStream, '<?xml verision="1.0"?>'#13#10 +
            ARequestBody, false)
        else
          SaveTextU(AReq.NeedRequestStream, ARequestBody, false);
        AReq.RequestStream.Position := 0;
        AReq.RequestHeaders.Values['Content-Type'] := 'text/xml; charset=utf-8';
        AReq.RequestHeaders.Values['Content-Length'] :=
          IntToStr(AReq.NeedRequestStream.Size);
      end;
      Push(AReq);
      AReq.WaitFor(INFINITE);
      Result := AReq.StatusCode;
      if Result = 200 then
        AResult := AReq.ContentAsString
      else
        SetLength(AResult, 0);
    end
    else
      Result := AReq.StatusCode;
  finally
    AReq._Release;
    if Assigned(AXML) then
      FreeAndNil(AXML);
  end;
end;

procedure TQHttpRequests.Start(ARequest: TQHttpRequestItem);
var
  AClient: THttpClientClass;
begin
  Lock;
  try
    if (FBusyClients < FMaxClients) or (FBusyClients = 0) then
    begin
      AClient := FHttpClients.Pop;
{$IFDEF SYSHTTP}
      AClient.CookieManager := FCookieManager;
{$ENDIF}
      if ARequest.StartWith(AClient) then
        Inc(FBusyClients);
    end
  finally
    Unlock;
  end;
end;

procedure TQHttpRequests.Unlock;
begin
  FCS.Leave;
end;

{$IFDEF SYSHTTP}
// Delphi 自带的 TNetHeaders 转 IQHttpHeaders 接口封装
{ THeadersHelper }

constructor THeadersHelper.Create;
begin
  inherited Create;
end;

constructor THeadersHelper.Create(AHeaders: TNetHeaders);
begin
  inherited Create;
  FHeaders := AHeaders;
end;

function THeadersHelper.GetCount: Integer;
begin
  Result := Length(FHeaders);
end;

function THeadersHelper.GetHeaderValue(const AName: QStringW): QStringW;
var
  I: Integer;
begin
  I := HeaderIndex(AName);
  if I <> -1 then
    Result := FHeaders[I].Value
  else
    Result := '';
end;

function THeadersHelper.GetNames(const AIndex: Integer): QStringW;
begin
  Result := FHeaders[AIndex].Name;
end;

function THeadersHelper.GetText: QStringW;
var
  I: Integer;
begin
  Result := '';
  for I := 0 to High(FHeaders) do
  begin
    Result := Result + FHeaders[I].Name + ': ' + FHeaders[I].Value + SLineBreak;
  end;
  if Length(Result) > 2 then
    SetLength(Result, Length(Result) - 2);
end;

function THeadersHelper.GetValueFromIndex(const AIndex: Integer): QStringW;
begin
  Result := FHeaders[AIndex].Value;
end;

function THeadersHelper.HeaderIndex(AName: QStringW): Integer;
var
  I: Integer;
begin
  AName := LowerCase(AName);
  for I := 0 to High(FHeaders) do
  begin
    if LowerCase(FHeaders[I].Name) = AName then
    begin
      Result := I;
      Exit;
    end;
  end;
  Result := -1;
end;

function THeadersHelper.HeaderValue(AName, ADefVal: QStringW): QStringW;
var
  I: Integer;
begin
  I := HeaderIndex(AName);
  if I = -1 then
    Result := ADefVal
  else
    Result := FHeaders[I].Value;
end;

procedure THeadersHelper.Merge(AHeaders: IQHttpHeaders);
var
  I: Integer;
begin
  for I := 0 to AHeaders.Count - 1 do
  begin
    if HeaderIndex(AHeaders.Names[I]) = -1 then
      SetHeaderValue(AHeaders.Names[I], AHeaders.ValueFromIndex[I]);
  end;
end;

procedure THeadersHelper.RemoveHeader(AName: QStringW);
var
  AIdx: Integer;
begin
  AIdx := HeaderIndex(AName);
  if AIdx <> -1 then
  begin
    while AIdx < High(FHeaders) do
    begin
      FHeaders[AIdx] := FHeaders[AIdx + 1];
      Inc(AIdx);
    end;
    SetLength(FHeaders, High(FHeaders));
  end;
end;

procedure THeadersHelper.Replace(AHeaders: IQHttpHeaders);
var
  I: Integer;
begin
  if Assigned(AHeaders) then
  begin
    for I := 0 to AHeaders.Count - 1 do
      SetHeaderValue(AHeaders.Names[I], AHeaders.ValueFromIndex[I]);
  end;
end;

procedure THeadersHelper.ReplaceHeader(AName, AValue: QStringW);
begin
  SetHeaderValue(AName, AValue);
end;

procedure THeadersHelper.SetHeaders(const AValue: TNetHeaders);
begin
  FHeaders := AValue;
end;

procedure THeadersHelper.SetHeaderValue(const AName, AValue: QStringW);
var
  AIdx: Integer;
begin
  AIdx := HeaderIndex(AName);
  if AIdx <> -1 then
    FHeaders[AIdx].Value := AValue
  else
  begin
    SetLength(FHeaders, Length(FHeaders) + 1);
    with FHeaders[High(FHeaders)] do
    begin
      Name := AName;
      Value := AValue;
    end;
  end;
end;

procedure THeadersHelper.SetText(const S: QStringW);
var
  I: Integer;
  AList: TStringList;
begin
  AList := TStringList.Create;
  try
    AList.Text := S;
    AList.NameValueSeparator := ':';
    SetLength(FHeaders, AList.Count);
    for I := 0 to AList.Count - 1 do
    begin
      FHeaders[I].Name := AList.Names[I];
      FHeaders[I].Value := Trim(AList.ValueFromIndex[I]);
    end;
  finally
    FreeAndNil(AList);
  end;
end;

{$ELSE}
{ THeadersHelper }

constructor THeadersHelper.Create;
begin
  inherited Create;
  FHeaders := TQHttpHeaders.Create;
end;

constructor THeadersHelper.Create(AHeaders: TQHttpHeaders);
begin
  inherited Create;
  FHeaders := TQHttpHeaders.Create;
  FHeaders.Assign(AHeaders);
end;

destructor THeadersHelper.Destroy;
begin
  FreeAndNil(FHeaders);
  inherited;
end;

function THeadersHelper.GetCount: Integer;
begin
  Result := FHeaders.Count;
end;

function THeadersHelper.GetHeaderValue(const AName: QStringW): QStringW;
begin
  Result := Trim(FHeaders.Values[AName]);
end;

function THeadersHelper.GetNames(const AIndex: Integer): QStringW;
begin
  Result := FHeaders.Names[AIndex];
end;

function THeadersHelper.GetValueFromIndex(const AIndex: Integer): QStringW;
begin
  Result := Trim(FHeaders.ValueFromIndex[AIndex]);
end;

function THeadersHelper.GetText: QStringW;
begin
  Result := FHeaders.Text;
end;

function THeadersHelper.HeaderIndex(AName: QStringW): Integer;
begin
  Result := FHeaders.HeaderIndex(AName);
end;

function THeadersHelper.HeaderValue(AName, ADefVal: QStringW): QStringW;
begin
  Result := FHeaders.HeaderValue(AName, ADefVal);
end;

procedure THeadersHelper.Merge(AHeaders: IQHttpHeaders);
var
  I: Integer;
begin
  for I := 0 to AHeaders.Count - 1 do
  begin
    if HeaderIndex(AHeaders.Names[I]) = -1 then
      SetHeaderValue(AHeaders.Names[I], AHeaders.ValueFromIndex[I]);
  end;
end;

function THeadersHelper.QueryInterface(const IID: TGUID; out Obj): HResult;
begin
{$IF RTLVersion=18}
  if SameId(IID, ObjCastGUID) then
  begin
    Pointer(Obj) := Pointer(Self);
    Result := S_OK;
  end
  else
{$IFEND}
    Result := inherited QueryInterface(IID, Obj);
end;

procedure THeadersHelper.RemoveHeader(AName: QStringW);
begin
  FHeaders.RemoveHeader(AName);
end;

procedure THeadersHelper.Replace(AHeaders: IQHttpHeaders);
var
  I: Integer;
begin
  if Assigned(AHeaders) then
  begin
    for I := 0 to AHeaders.Count - 1 do
      SetHeaderValue(AHeaders.Names[I], AHeaders.ValueFromIndex[I]);
  end;
end;

procedure THeadersHelper.ReplaceHeader(AName, AValue: QStringW);
begin
  FHeaders.ReplaceHeader(AName, AValue);
end;

procedure THeadersHelper.SetHeaders(const Value: TQHttpHeaders);
begin
  FHeaders.Assign(Value);
end;

procedure THeadersHelper.SetHeaderValue(const AName, AValue: QStringW);
begin
  FHeaders.Values[AName] := AValue;
end;

procedure THeadersHelper.SetText(const S: QStringW);
begin
  FHeaders.Text := S;
end;

{$ENDIF}
{ TQHttpDownloader }

function TQHttpFileRequestItem.CreateInternalStream: TStream;
var
  AFileName: QStringW;
begin
  AFileName := FilePath;
  if ResumeBroken then
  begin
    if FileExists(AFileName) then
    begin
      Result := TFileStream.Create(AFileName, fmOpenReadWrite or
        fmShareDenyWrite);
      Result.Seek(0, soFromEnd);
    end
    else
      Result := TFileStream.Create(AFileName, fmCreate);
  end
  else
    Result := TFileStream.Create(AFileName, fmCreate);
end;

procedure TQHttpFileRequestItem.DoError(ASender: TObject; AError: Exception);
begin
  if Assigned(FOnError) then
    FOnError(Self, AError);
end;

procedure TQHttpFileRequestItem.DoHeadReady(ASender: TObject);
var
  AHead: TQHttpRequestItem;
  AFileSize: Int64;
  AContinue: Boolean;
  function DecodeFileName: QStringW;
  var
    Value: QStringW;
  const
    ItemDelimiter: PWideChar = ';';
    NullChar: WideChar = #0;
  begin
    // 查找Content-disposition中的文件名约定
    Value := AHead.ResponseHeaders['content-disposition'];
    while Length(Value) > 0 do
    begin
      Result := Trim(DecodeTokenW(Value, ItemDelimiter, NullChar, false, True));
      if LowerCase(NameOfW(Result, '=')) = 'filename' then
        Result := DequotedStrW(ValueOfW(Result, '='), '"')
      else
        Result := '';
    end;
    // 如果没有，以URL文档名为名
    if Length(Result) = 0 then
    begin
      Result := StrBetweenTimes(AHead.ResultUrl, '/', false, 0, -1);
      Result := StrBeforeW(Result, '?', false, false);
      // 如果仍没有，以URL为路径为名
      if Length(Result) = 0 then
        Result := DeleteCharW(AHead.ResultUrl, ',:/\#@');
    end;
  end;

  procedure CheckHTST;
  var
    AUrl: TQUrl;
  begin
    if Length(AHead.ResponseHeaders['Strict-Transport-Security']) > 0 then
    begin
      AUrl := TQUrl.Create(FUrl);
      try
        if AUrl.Scheme = 'http' then
          AUrl.Scheme := 'https';
        FResultUrl := AUrl.Url;
      finally
        FreeAndNil(AUrl);
      end;
    end;
  end;

begin
  AHead := ASender as TQHttpRequestItem;
  if AHead.StatusCode = 200 then
  begin
    CheckHTST;
    AContinue := True;
    FFileSize := StrToInt64Def(AHead.ResponseHeaders['content-length'], 0);
    if Length(FileName) = 0 then
    begin
      if Length(FileName) = 0 then
        FileName := DecodeFileName;
      if AHead.ResponseHeaders['accept-ranges'] <> 'bytes' then
        // 如果服务器不支持断点续传，就设置ResumeBroke为False，以避免启用断点续传
        ResumeBroken := false
    end;
    AFileSize := SizeOfFile(FilePath);
    if AFileSize > 0 then
    begin
      if AFileSize > FFileSize then
        ResumeBroken := false
      else if AFileSize = FFileSize then
      begin
        AContinue := false;
        FStatusCode := 304;
        FStatusText := 'Not Modified';
        ResumeBroken := false;
      end;
      if ResumeBroken then
        RequestHeaders['Range'] := 'bytes=' + IntToStr(AFileSize) + '-';
    end;
    if AContinue and Assigned(BeforeDownload) then
    begin
      BeforeDownload(Self, AHead.ResponseHeaders, AContinue);
      if not AContinue then
      begin
        FStatusCode := 1223;
        // Windows Error code of ERROR_CANCELLED;
        FStatusText := SUserCanceled;
      end;
    end;
    FHeadReady := True;
  end
  else
  begin
    FStatusCode := AHead.StatusCode;
    FStatusText := AHead.StatusText;
    AContinue := false;
  end;
  if not AContinue then
  begin
    FAbort := True;
    DoAfterDone(Self);
  end;
end;

{ TQHttpFileRequestItem }

procedure TQHttpFileRequestItem.BeforePush;
var
  AHeadReq: TQHttpRequestItem;
begin
  // 如果是下载文件请求，则先请求Head命令
  AHeadReq := TQHttpRequestItem.Create(Self, false);
  AHeadReq.Url := Url;
  AHeadReq.Action := reqHead;
  AHeadReq.AfterDone := DoHeadReady;
  AHeadReq.OnError := DoError;
  FQueue.Push(AHeadReq);
  inherited;
end;

function TQHttpFileRequestItem.GetCanStart: Boolean;
begin
  Result := FHeadReady and (Length(FFileName) > 0);
end;

function TQHttpFileRequestItem.GetFilePath: QStringW;
const
  PathDelimiter: QStringW =
{$IFDEF MSWINDOWS}'\'{$ELSE}'/'{$ENDIF};
begin
  if Length(FPath) > 0 then
  begin
    if not EndWithW(FPath, PathDelimiter, false) then
      FPath := FPath + PathDelimiter;
  end;
  Result := FPath + FFileName;
end;

{ TQRequestList }

function TQRequestList.Add(const ARequest: TQHttpRequestItem): Integer;
begin
  ARequest._AddRef;
  Result := FItems.Add(ARequest);
end;

procedure TQRequestList.Clear;
var
  I: Integer;
begin
  for I := 0 to FItems.Count - 1 do
    Items[I]._Release;
  FItems.Clear;
end;

constructor TQRequestList.Create;
begin
  inherited;
  FItems := TList.Create;
end;

procedure TQRequestList.Delete(AIndex: Integer);
var
  AItem: TQHttpRequestItem;
begin
  AItem := Items[AIndex];
  AItem._Release;
  FItems.Delete(AIndex);
end;

destructor TQRequestList.Destroy;
begin
  Clear;
  FreeAndNil(FItems);
  inherited;
end;

function TQRequestList.GetCount: Integer;
begin
  Result := FItems.Count;
end;

function TQRequestList.GetItems(const AIndex: Integer): TQHttpRequestItem;
begin
  Result := FItems[AIndex];
end;

function TQRequestList.IndexOf(const ARequest: TQHttpRequestItem): Integer;
begin
  Result := FItems.IndexOf(ARequest);
end;

procedure TQRequestList.Remove(const ARequest: TQHttpRequestItem);
var
  AIdx: Integer;
begin
  AIdx := FItems.IndexOf(ARequest);
  if AIdx <> -1 then
    Delete(AIdx);
end;

initialization

StartSocket;
{$IF RTLVersion=18}
ZLibHandle := LoadLibrary('zlib1.dll');
if ZLibHandle <> 0 then
  inflateInit2_ := GetProcAddress(ZLibHandle, 'inflateInit2_');
{$IFEND}

finalization

CleanSocket;
{$IF RTLVersion=18}
if ZLibHandle <> 0 then
  FreeLibrary(ZLibHandle);
{$IFEND}

end.
