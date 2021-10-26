unit qmemstatics;

interface

uses classes, sysutils;

{ 内存分配情况统计单元
  QMemStatics提供了一种途径，来对系统的内存分配情况进行简单的统计分配跟踪，以方便
  程序通过合适的手段，减少内存碎片的产生。
  QMemStatics提供了一个最简单的减少内存碎片的办法，就是增加内存分配的粒度，通过启
  用条件编译RESIZESMALLBLOCK，就可以做到只调整最小内存分配尺寸为ResizeMaxBlockSize，
  减少绝大多数内存碎片的生产（默认是64B)。
  条件编译选项 RESIZEONLY 可以让模块不为每块内存添加用于识别的头部标志，但同时，也
  会造成统计功能失效，一般只在发布的版本中使用。
  默认情况下，这两个选项都未启用，以便真实反应内存分配情况。
  Demos\Delphi\VCL\QMemStatics\dlgMemStatics单元实现了一个示例性的图形化的内存统计
  程序，在你的程序中，可以直接调用ShowMemoryStatics方法来方便的显示内存状态。
  本单元依赖于QString.pas和qdac.inc两个文件。
  本单元支持XE7及以后版本
}
{
  本源码来自QDAC项目，版权归swish(QQ:109867294)所有。
  (1)、使用许可及限制
  您可以自由复制、分发、修改本源码，但您的修改应该反馈给作者，并允许作者在必要时，
  合并到本项目中以供使用，合并后的源码同样遵循QDAC版权声明限制。
  您的产品的关于中，应包含以下的版本声明:
  本产品使用的JSON解析器来自QDAC项目中的QJSON，版权归作者所有。
  (2)、技术支持
  有技术问题，您可以加入QDAC官方QQ群250530692共同探讨。
  (3)、赞助
  您可以自由使用本源码而不需要支付任何费用。如果您觉得本源码对您有帮助，您可以赞
  助本项目（非强制），以使作者不为生活所迫，有更多的精力为您呈现更好的作品：
  赞助方式：
  支付宝： guansonghuan@sina.com 姓名：管耸寰
  建设银行：
  户名：管耸寰
  账号：4367 4209 4324 0179 731
  开户行：建设银行长春团风储蓄所
}
{ 修订日志
  2014.7.29
  =========
  * 兼容性改进，测试在XE2下编译通过
  2014.7.25
  =========
  * 修正了几处内存异常
  * 将调整内存块大小的最大尺寸改为64字节
  * 修改统计的内存大小为4KB以下
  * 修正了统计结果可能出现负数的问题
  2014.7.24
  =========
  + 第一版
}
{.$DEFINE RESIZEONLY }
{$IFDEF RESIZEONLY}
{$IFNDEF RESIZESMALLBLOCK}
{$DEFINE RESIZESMALLBLOCK}
{$ENDIF}
{$ELSE}
{.$DEFINE RESIZESMALLBLOCK }
{$ENDIF}
{$HPPEMIT '#pragma link "qmemstatics"'}
const
  MaxStaticMemSize = 4096;
  ResizeMaxBlockSize = 64;
type
{$IF RTLVersion<=22}
  NativeInt = Integer;
  PNativeInt = ^NativeInt;
  PNativeUInt = ^Cardinal;
{$IFEND}

  TMemoryStatic = record
    Count: Integer; // 当前数量
    MaxCount: Integer; // 最大数量
    AllocateTimes: Integer; // 分配次数
    FreeTimes: Integer; // 释放次数
  end;

  PMemoryStatic = ^TMemoryStatic;

  TMemStaticItem = record
    Size: Integer; // 内存尺寸
    Statics: TMemoryStatic; // 统计结果
  end;

  TMemStatics = array of TMemStaticItem;
  TMemStaticsSortMethod = (ssmNone, ssmCount, ssmMaxCount, ssmAllocateTimes,
    ssmFreeTimes);

procedure GetMemStatics(var AStatics: TMemStatics;
  ASortType: TMemStaticsSortMethod);
procedure SortMemStatics(var AStatics: TMemStatics;
  ASortType: TMemStaticsSortMethod);
function GetMemStaticsText(const AStatics: TMemStatics): String;

implementation

uses qstring, windows;

type
  TMemMagic = record
    {$IFNDEF X64}
    Reserved:Int64;//用于保证TMemMagic加入后，地址仍是16字节对齐
    {$ENDIF}
    Size: NativeInt;
    Magic: NativeInt;
  end;

  PMemMagic = ^TMemMagic;

var
  MemoryStatics: array [0 .. MaxStaticMemSize] of TMemoryStatic;
  OldMemMgr: TMemoryManagerEx;
  DebugSize: Integer = 17;
  DebugCount: Integer = 0;
  MemMagic:NativeInt;

procedure LogAllocMem(ASize: NativeInt);
var
  pItem: PMemoryStatic;
  ACount, AMax: Integer;
begin
if ASize > MaxStaticMemSize then
  pItem := @MemoryStatics[MaxStaticMemSize]
else
  pItem := @MemoryStatics[ASize - 1];
if DebugSize = ASize then
  AtomicIncrement(DebugCount);
AtomicIncrement(pItem.Count);
AtomicIncrement(pItem.AllocateTimes);
repeat
  ACount := pItem.Count;
  AMax := pItem.MaxCount;
until (ACount <= AMax) or (AtomicCmpExchange(pItem.MaxCount, ACount, AMax)
  = ACount);
end;

procedure LogFreeMem(ASize: NativeInt);
var
  pItem: PMemoryStatic;
  ACount: Integer;
begin
if ASize > MaxStaticMemSize then
  pItem := @MemoryStatics[MaxStaticMemSize]
else
  pItem := @MemoryStatics[ASize - 1];
AtomicIncrement(pItem.FreeTimes);
ACount := AtomicDecrement(pItem.Count);
if DebugSize = ASize then
  begin
  if AtomicDecrement(DebugCount) <> ACount then
    begin
    DebugBreak;
    end;
  end;
end;

function MarkMagic(P:Pointer;ASize:NativeInt):Pointer;inline;
var
  pMagic:PMemMagic;
begin
pMagic:=P;
pMagic.Size:=ASize;
pMagic.Magic:=MemMagic;
Result:=Pointer(IntPtr(P)+SizeOf(TMemMagic));
end;

function MagicOf(P:Pointer):PMemMagic;inline;
begin
Result:=Pointer(IntPtr(P)-SizeOf(TMemMagic));
if Result.Magic<>MemMagic then
  Result:=nil;
end;

function Hook_GetMem(Size: NativeInt): Pointer;
begin
{$IFDEF RESIZESMALLBLOCK}
if Size < ResizeMaxBlockSize then
  Size := ResizeMaxBlockSize;
{$ENDIF}
{$IFDEF RESIZEONLY}
Result := OldMemMgr.GetMem(Size);
{$ELSE}
Result := OldMemMgr.GetMem(Size + SizeOf(TMemMagic));
if Result <> nil then//头部加入签名信息
  begin
  LogAllocMem(Size);
  Result:=MarkMagic(Result, Size);
  end;
{$ENDIF}
end;

{
  FreeMem返回值为错误代码，如果成功，则返回0
}
function Hook_FreeMem(P: Pointer): Integer;
var
  pMagic: PMemMagic;
  ASize: NativeInt;
begin
{$IFDEF RESIZEONLY}
Result := OldMemMgr.FreeMem(P);
{$ELSE}
if P <> nil then
  begin
  pMagic := PMemMagic(IntPtr(P) - SizeOf(TMemMagic));
  if pMagic.Magic = MemMagic then
    begin
    ASize := pMagic.Size;
    Result := OldMemMgr.FreeMem(pMagic);
    if Result = 0 then
      LogFreeMem(ASize);
    end
  else // 不是自己分配的，交回原函数
    Result := OldMemMgr.FreeMem(P);
  end
else
  Result := 0;
{$ENDIF}
end;

function Hook_ReallocMem(P: Pointer; Size: NativeInt): Pointer;
var
  pMagic: PMemMagic;
begin
{$IFDEF RESIZESMALLBLOCK}
if Size < ResizeMaxBlockSize then
  Size := ResizeMaxBlockSize;
{$ENDIF}
{$IFDEF RESIZEONLY}
Result := OldMemMgr.ReallocMem(P, Size);
{$ELSE}
if P = nil then
  Result := Hook_GetMem(Size)
else
  begin
  pMagic := PMemMagic(IntPtr(P) - SizeOf(TMemMagic));
  if pMagic.Magic = MemMagic then
    begin
    if Size <> pMagic.Size then
      begin
      Result := OldMemMgr.ReallocMem(pMagic, Size + SizeOf(TMemMagic));
      if Result <> nil then
        begin
        if Result <> pMagic then
          begin
          pMagic := PMemMagic(IntPtr(P) - SizeOf(TMemMagic));
          pMagic.Magic := MemMagic;
          end;
        LogAllocMem(Size);
        LogFreeMem(pMagic.Size);
        pMagic.Size := Size;
        Result := Pointer(IntPtr(Result) + SizeOf(TMemMagic));
        end;
      end
    else
      begin
      Result := P;
      Exit;
      end;
    end
  else // 不是自己分配的，系统分配的，交给原来的函数处理
    begin
    Result := OldMemMgr.ReallocMem(P, Size);
    end;
  end;
{$ENDIF}
end;

function Hook_AllocMem(Size: {$IF RTLVersion>22}NativeInt{$ELSE}Cardinal{$IFEND}): Pointer;
begin
Result := Hook_GetMem(Size);
if Result <> nil then
  FillChar(Result^, Size, 0);
end;

function Hook_RegisterExpectedMemoryLeak(P: Pointer): Boolean;
var
  pMagic: PMemMagic;
begin
if P <> nil then
  begin
  pMagic := PMemMagic(IntPtr(P) - SizeOf(TMemMagic));
  if pMagic.Magic = MemMagic then
    Result := OldMemMgr.RegisterExpectedMemoryLeak(pMagic)
  else
    Result := OldMemMgr.RegisterExpectedMemoryLeak(P);
  end
else
  Result := OldMemMgr.RegisterExpectedMemoryLeak(P)
end;

function Hook_UnregisterExpectedMemoryLeak(P: Pointer): Boolean;
var
  pMagic: PMemMagic;
begin
if P <> nil then
  begin
  pMagic := PMemMagic(IntPtr(P) - SizeOf(TMemMagic));
  if pMagic.Magic = MemMagic then
    Result := OldMemMgr.UnregisterExpectedMemoryLeak(pMagic)
  else
    Result := OldMemMgr.UnregisterExpectedMemoryLeak(P);
  end
else
  Result := OldMemMgr.UnregisterExpectedMemoryLeak(P)
end;

procedure RegisterMemMgr;
var
  AMgr: TMemoryManagerEx;
begin
GetMemoryManager(OldMemMgr);
AMgr.GetMem := Hook_GetMem;
AMgr.FreeMem := Hook_FreeMem;
AMgr.ReallocMem := Hook_ReallocMem;
AMgr.AllocMem := Hook_AllocMem;
AMgr.RegisterExpectedMemoryLeak := Hook_RegisterExpectedMemoryLeak;
AMgr.UnregisterExpectedMemoryLeak := Hook_UnregisterExpectedMemoryLeak;
SetMemoryManager(AMgr);
end;

procedure SortMemStatics(var AStatics: TMemStatics;
  ASortType: TMemStaticsSortMethod);

  function DoCompare(P1, P2: Integer): Integer;
  begin
  case ASortType of
    ssmCount:
      Result := AStatics[P1].Statics.Count - AStatics[P2].Statics.Count;
    ssmMaxCount:
      Result := AStatics[P1].Statics.MaxCount - AStatics[P2].Statics.MaxCount;
    ssmAllocateTimes:
      Result := AStatics[P1].Statics.AllocateTimes - AStatics[P2]
        .Statics.AllocateTimes;
    ssmFreeTimes:
      Result := AStatics[P1].Statics.FreeTimes - AStatics[P2].Statics.FreeTimes
  else
    Result := 0;

  end;
  end;
  procedure ExchangeItem(P1, P2: Integer);
  var
    S: TMemStaticItem;
  begin
  S := AStatics[P1];
  AStatics[P1] := AStatics[P2];
  AStatics[P2] := S;
  end;
  procedure SortStatics(L, R: Integer);
  var
    I, J, P: Integer;
  begin
  repeat
    I := L;
    J := R;
    P := (L + R) shr 1;
    repeat
      while DoCompare(I, P) < 0 do
        Inc(I);
      while DoCompare(J, P) > 0 do
        Dec(J);
      if I <= J then
        begin
        if I <> J then
          ExchangeItem(I, J);
        if P = I then
          P := J
        else if P = J then
          P := I;
        Inc(I);
        Dec(J);
        end;
    until I > J;
    if L < J then
      SortStatics(L, J);
    L := I;
  until I >= R;
  end;

begin
SortStatics(0, High(AStatics))
end;

procedure GetMemStatics(var AStatics: TMemStatics;
  ASortType: TMemStaticsSortMethod);
var
  I: Integer;
begin
SetLength(AStatics, MaxStaticMemSize + 1);
for I := 0 to MaxStaticMemSize - 1 do
  begin
  AStatics[I].Size := I + 1;
  Move(MemoryStatics[I], AStatics[I].Statics, SizeOf(TMemoryStatic));
  end;
AStatics[MaxStaticMemSize].Size := -1;
AStatics[MaxStaticMemSize].Statics := MemoryStatics[MaxStaticMemSize];
if ASortType <> ssmNone then
  SortMemStatics(AStatics, ASortType);
end;

function GetMemStaticsText(const AStatics: TMemStatics): String;
var
  I: Integer;
  ATotal: TMemoryStatic;
  ABuilder: TQStringCatHelperW;
begin
SetLength(Result, 0);
FillChar(ATotal, SizeOf(TMemoryStatic), 0);
for I := Low(AStatics) to High(AStatics) do
  begin
  Inc(ATotal.Count, AStatics[I].Statics.Count);
  Inc(ATotal.AllocateTimes, AStatics[I].Statics.AllocateTimes);
  Inc(ATotal.MaxCount, AStatics[I].Statics.MaxCount);
  Inc(ATotal.FreeTimes, AStatics[I].Statics.FreeTimes);
  end;
ABuilder := TQStringCatHelperW.Create;
try
  ABuilder.Cat('总计:').Cat(SLineBreak).Cat('  最大块数:')
    .Cat(ATotal.MaxCount).Cat('块');
  ABuilder.Cat(SLineBreak).Cat('  块数:').Cat(ATotal.Count).Cat('块');
  ABuilder.Cat(SLineBreak).Cat('  分配次数:').Cat(ATotal.AllocateTimes);
  ABuilder.Cat(SLineBreak).Cat('  释放次数:').Cat(ATotal.FreeTimes);
  ABuilder.Cat(SLineBreak).Cat('明细:').Cat(SLineBreak);
  for I := Low(AStatics) to High(AStatics) do
    begin
    if AStatics[I].Statics.AllocateTimes <> 0 then
      begin
      if AStatics[I].Size <> -1 then
        begin
        ABuilder.Cat(AStatics[I].Size).Cat('B:最大 ')
          .Cat(AStatics[I].Statics.MaxCount).Cat('块');
        if ATotal.MaxCount > 0 then
          ABuilder.Cat('(')
            .Cat(RollupSize(AStatics[I].Size * AStatics[I].Statics.MaxCount))
            .Cat(',').Cat(FormatFloat('0.##', AStatics[I].Statics.MaxCount * 100
            / ATotal.MaxCount)).Cat('%)');
        end
      else
        ABuilder.Cat('>=').Cat(MaxStaticMemSize).Cat('B:最大 ')
          .Cat(AStatics[I].Statics.MaxCount).Cat('块(');
      ABuilder.Cat(',当前 ').Cat(AStatics[I].Statics.Count).Cat('块');
      if ATotal.Count > 0 then
        ABuilder.Cat('(')
          .Cat(RollupSize(AStatics[I].Size * AStatics[I].Statics.Count))
          .Cat(',').Cat(FormatFloat('0.##', AStatics[I].Statics.Count * 100 /
          ATotal.Count)).Cat('%)');
      ABuilder.Cat(',分配次数:').Cat(AStatics[I].Statics.AllocateTimes);
      if ATotal.AllocateTimes > 0 then
        ABuilder.Cat('(')
          .Cat(FormatFloat('0.##', AStatics[I].Statics.AllocateTimes * 100 /
          ATotal.AllocateTimes)).Cat('%)');
      ABuilder.Cat(',释放次数:').Cat(AStatics[I].Statics.FreeTimes);
      if ATotal.AllocateTimes > 0 then
        ABuilder.Cat('(').Cat(FormatFloat('0.##', AStatics[I].Statics.FreeTimes
          * 100 / ATotal.FreeTimes)).Cat('%)');
      ABuilder.Cat(SLineBreak);
      end;
    end;
  Result := ABuilder.Value;
finally
  FreeObject(ABuilder);
end;
end;


initialization
FillChar(MemMagic,SizeOf(MemMagic),1);
FillChar(MemoryStatics, SizeOf(MemoryStatics), 0);
RegisterMemMgr;

end.
