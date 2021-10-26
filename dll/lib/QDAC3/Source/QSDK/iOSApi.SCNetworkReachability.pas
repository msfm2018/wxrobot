unit iOSApi.SCNetworkReachability;

interface

{$IFDEF IOS}
uses
  Macapi.CoreFoundation,
  Posix.SysSocket,
  Macapi.Dispatch;

const
  libSystemConfiguration = '/System/Library/Frameworks/SystemConfiguration.framework/SystemConfiguration';

  kSCNetworkFlagsConnectionAutomatic = 8;
  kSCNetworkFlagsConnectionRequired = 4;
  kSCNetworkFlagsInterventionRequired = 16;
  kSCNetworkFlagsIsDirect = 131072;
  kSCNetworkFlagsIsLocalAddress = 65536;
  kSCNetworkFlagsReachable = 2;
  kSCNetworkFlagsTransientConnection = 1;
  kSCNetworkReachabilityFlagsConnectionAutomatic = 8;
  kSCNetworkReachabilityFlagsConnectionOnDemand = 32;
  kSCNetworkReachabilityFlagsConnectionOnTraffic = 8;
  kSCNetworkReachabilityFlagsConnectionRequired = 4;
  kSCNetworkReachabilityFlagsInterventionRequired = 16;
  kSCNetworkReachabilityFlagsIsDirect = 131072;
  kSCNetworkReachabilityFlagsIsLocalAddress = 65536;
  kSCNetworkReachabilityFlagsReachable = 2;
  kSCNetworkReachabilityFlagsTransientConnection = 1;
  kSCNetworkReachabilityFlagsIsWWAN = $40000; // iOS only

type
  SCNetworkReachabilityFlags = UInt32;

  SCNetworkReachabilityRef = ^__SCNetworkReachability;

  __SCNetworkReachability = record
  end;

  SCNetworkReachabilityContext = record
    version: CFIndex;
    info: Pointer;
    retain: function(info: Pointer): Pointer;
    release: procedure(info: Pointer);
    copyDescription: function(info: Pointer): CFStringRef;
  end;

  SCNetworkReachabilityContextPtr = ^SCNetworkReachabilityContext;

  SCNetworkReachabilityCallback = procedure(target: SCNetworkReachabilityRef;
    flags: SCNetworkReachabilityFlags; info: Pointer);

function SCNetworkReachabilityCreateWithAddress(allocator: CFAllocatorRef; address: psockaddr): SCNetworkReachabilityRef; cdecl;
  external libSystemConfiguration name _PU + 'SCNetworkReachabilityCreateWithAddress';
function SCNetworkReachabilityCreateWithAddressPair(allocator: CFAllocatorRef; localAddress: psockaddr;
  remoteAddress: psockaddr): SCNetworkReachabilityRef; cdecl;
  external libSystemConfiguration name _PU + 'SCNetworkReachabilityCreateWithAddressPair';
function SCNetworkReachabilityCreateWithName(allocator: CFAllocatorRef; nodename: PChar): SCNetworkReachabilityRef; cdecl;
  external libSystemConfiguration name _PU + 'SCNetworkReachabilityCreateWithName';
function SCNetworkReachabilityGetTypeID: CFTypeID; cdecl;
  external libSystemConfiguration name _PU + 'SCNetworkReachabilityGetTypeID';
function SCNetworkReachabilityGetFlags(target: SCNetworkReachabilityRef; var flags: SCNetworkReachabilityFlags): Boolean; cdecl;
  external libSystemConfiguration name _PU + 'SCNetworkReachabilityGetFlags';
function SCNetworkReachabilitySetCallback(target: SCNetworkReachabilityRef; callout: SCNetworkReachabilityCallback;
  var context: SCNetworkReachabilityContext): Boolean; cdecl;
  external libSystemConfiguration name _PU + 'SCNetworkReachabilitySetCallback';
function SCNetworkReachabilityScheduleWithRunLoop(target: SCNetworkReachabilityRef; runLoop: CFRunLoopRef;
  runLoopMode: CFStringRef): Boolean; cdecl;
  external libSystemConfiguration name _PU + 'SCNetworkReachabilityScheduleWithRunLoop';
function SCNetworkReachabilityUnscheduleFromRunLoop(target: SCNetworkReachabilityRef; runLoop: CFRunLoopRef; runLoopMode: CFStringRef): Boolean; cdecl;
  external libSystemConfiguration name _PU + 'SCNetworkReachabilityUnscheduleFromRunLoop';
function SCNetworkReachabilitySetDispatchQueue(target: SCNetworkReachabilityRef; queue: dispatch_queue_t): Boolean; cdecl;
  external libSystemConfiguration name _PU + 'SCNetworkReachabilitySetDispatchQueue';

{$ENDIF}

implementation



end.
