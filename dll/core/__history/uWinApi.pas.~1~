unit uWinApi;


// http://bbs.pediy.com/thread-217610.htm
// 微信(WeChat)电脑端多开分析+源码

{  感谢原文提供的代码和 exe
   晓不得2013 qq 26562729
   2017-07-04
   // 本代码是学习 win api 的一个经典示例
   // 希望您会有所收获
}
interface

uses
  windows, TLHelp32, Generics.collections;

type

  PSystemHandle = ^TSystemHandle; // 此结构体未公开，找了很久才弄正确。

  TSystemHandle = packed record // 共16字节. 长度一定要准确。否则，后面没法玩。
    dwProcessID: THandle;
    bObjectType: Byte;
    bflags: Byte;
    wValue: Word;
    GrantedAcess: Int64;
  end;

  PSystemHandleList = ^TSystemHandleList;

  TSystemHandleList = record
    dwHandleCount: Cardinal; // 获取到的结果前4个字节，表示数量
    // 后面的就每 16 个字节一组，表示一个 TSystemHandle
    Handles: array of TSystemHandle; // 定义成下面这样，亦可行。
    // Handles:TSystemHandle; 只是不便于理解
  end;

  PProcessRec = ^TProcessRec;

  TProcessRec = record
    ProcessName: string;
    ProcessID: THandle;
  end;

  TProcessRecList = class(TList<PProcessRec>)
  public
    procedure FreeAllItem;
  end;

  // win 规则下，都是让调用者传入 buff 长度，然后检查这个长度是否合适
  // 如果不够，就返回一个错误，并且在 ASize 中指明需要的长度
  // 以便调用者重新分配 buff 再次调用
  // ASysInfoCls 是查询什么类别。 MS 没有全部公开. $10 为 SystemHanle.
  // ASysInfo 理解为 Buff 就行了。
function ZwQuerySystemInformation(ASysInfoCls: Integer; ASysInfo: Pointer; ABufLen: Cardinal;
  var ASize: Cardinal): Cardinal; stdcall; external 'ntdll.dll';


function NtQueryObject(Ahandle: THandle; AQuertyIndex: Integer; ABuff: Pointer; ABuffSize: Cardinal;
  var ASize: Cardinal): Cardinal; stdcall; external 'ntdll.dll';

// 获取当前的进程
function GetAllProcess: TProcessRecList;

implementation

{ TProcessRecList }

procedure TProcessRecList.FreeAllItem;
var
  p: PProcessRec;
begin
  for p in self do
    Dispose(p);
end;

function GetAllProcess: TProcessRecList;
var
  Entry32: TProcessEntry32W;
  SnapshotHandle: THandle;
  Found: boolean;
  sExeFileName: string;
  p: PProcessRec;
begin
  Result := TProcessRecList.Create;
  SnapshotHandle := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  Entry32.dwSize := sizeof(Entry32);
  Found := Process32First(SnapshotHandle, Entry32);
  while Found do
  begin
    new(p);
    Result.Add(p);
    sExeFileName := Entry32.szExeFile;
    p.ProcessName := sExeFileName;
    p.ProcessID := Entry32.th32ProcessID;
    Found := Process32Next(SnapshotHandle, Entry32);
  end;
  CloseHandle(SnapshotHandle);
end;

end.
