{ ******************************************************* }
{ 内存加载DLL(Load module in memory) }
{ MemoryModule }
{ }
{ 版权所有 (C) 2012 wr960204 武稀松 }
{ wr960204@126.com }
{ ******************************************************* }

{$DEFINE USESTDCALL}
{.$DEFINE USEDBGOUT}
unit qdac_memmodule;

interface

uses
  Windows{$IFDEF USEDBGOUT}, SysUtils{$ENDIF};

type

  HMemModule = NativeUInt;

function MemLoadLibrary(const buf: Pointer): HMemModule;
{$IFDEF USESTDCALL}stdcall;
{$ENDIF}
function MemGetProcAddress(Module: HMemModule;
  const lpProcName: LPCSTR): FARPROC;
{$IFDEF USESTDCALL}stdcall; {$ENDIF}
function MemFreeLibrary(Module: HMemModule): BOOL; {$IFDEF USESTDCALL}stdcall;
{$ENDIF}

implementation

type
  TFNDllMain = function(hinstDLL: HMODULE; Reason: Integer; Reserved: Pointer)
    : BOOL; stdcall;
  LPMemModule = ^TMemModule;

  TMemModule = record
    headers: PImageNtHeaders;
    codeBase: PAnsiChar;
    entrypoint: TFNDllMain;
    modules: array of HMODULE;
    runtimeFunc: PImageRuntimeFunctionEntry;
    initialized: boolean;
    magic: Integer;
  end;

  //

type

  // Delphi7等老版本没有定义ULONGLONG
{$IFDEF VER150 or VER140 or VER 130}
{$DEFINE Delphi7Old}
{$ENDIF}
{$IFDEF Delphi7Old}
  ULONGLONG = UINT64;
{$ENDIF}
  TNativeAddr = {$IFDEF WIN64}DWORD{$ELSE}ULONGLONG{$ENDIF};
  // 'Delphi早期版本没有这个结构体声明(for old veriosn delphi)'

  _IMAGE_THUNK_DATA32 = record
    case Byte of
      0:
        (ForwarderString: DWORD); // PBYTE
      1:
        (_Function: DWORD); // PDWORD Function -> _Function
      2:
        (Ordinal: DWORD);
      3:
        (AddressOfData: DWORD); // PIMAGE_IMPORT_BY_NAME
  end;

  IMAGE_THUNK_DATA32 = _IMAGE_THUNK_DATA32;
  TImageThunkData32 = _IMAGE_THUNK_DATA32;
  PIMAGE_THUNK_DATA32 = ^_IMAGE_THUNK_DATA32;
  PImageThunkData32 = ^_IMAGE_THUNK_DATA32;

  _IMAGE_THUNK_DATA64 = record
    case Byte of
      0:
        (ForwarderString: ULONGLONG); // PBYTE
      1:
        (_Function: ULONGLONG); // PDWORD Function -> _Function
      2:
        (Ordinal: ULONGLONG);
      3:
        (AddressOfData: ULONGLONG); // PIMAGE_IMPORT_BY_NAME
  end;

  IMAGE_THUNK_DATA64 = _IMAGE_THUNK_DATA64;
  TImageThunkData64 = _IMAGE_THUNK_DATA64;
  PIMAGE_THUNK_DATA64 = ^_IMAGE_THUNK_DATA64;
  PImageThunkData64 = ^_IMAGE_THUNK_DATA64;

  _IMAGE_TLS_DIRECTORY32 = record
    StartAddressOfRawData: DWORD;
    EndAddressOfRawData: DWORD;
    AddressOfIndex: DWORD; // PDWORD
    AddressOfCallBacks: DWORD; // PIMAGE_TLS_CALLBACK *;
    SizeOfZeroFill: DWORD;
    Characteristics: DWORD;
  end;

  IMAGE_TLS_DIRECTORY32 = _IMAGE_TLS_DIRECTORY32;
  TImageTLSDirectory32 = _IMAGE_TLS_DIRECTORY32;
  PIMAGE_TLS_DIRECTORY32 = ^_IMAGE_TLS_DIRECTORY32;
  PImageTLSDirectory32 = ^_IMAGE_TLS_DIRECTORY32;

  _IMAGE_TLS_DIRECTORY64 = record
    StartAddressOfRawData: ULONGLONG;
    EndAddressOfRawData: ULONGLONG;
    AddressOfIndex: ULONGLONG; // PDWORD
    AddressOfCallBacks: ULONGLONG; // PIMAGE_TLS_CALLBACK *;
    SizeOfZeroFill: DWORD;
    Characteristics: DWORD;
  end;

  IMAGE_TLS_DIRECTORY64 = _IMAGE_TLS_DIRECTORY64;
  TImageTLSDirectory64 = _IMAGE_TLS_DIRECTORY64;
  PIMAGE_TLS_DIRECTORY64 = ^_IMAGE_TLS_DIRECTORY64;
  PImageTLSDirectory64 = ^_IMAGE_TLS_DIRECTORY64;

  _IMAGE_IMPORT_DESCRIPTOR = record
    case Byte of
      0:
        (Characteristics: DWORD); // 0 for terminating null import descriptor
      1:
        (OriginalFirstThunk: DWORD;
          // RVA to original unbound IAT (PIMAGE_THUNK_DATA)
          TimeDateStamp: DWORD; // 0 if not bound,
          // -1 if bound, and real date\time stamp
          // in IMAGE_DIRECTORY_ENTRY_BOUND_IMPORT (new BIND)
          // O.W. date/time stamp of DLL bound to (Old BIND)

          ForwarderChain: DWORD; // -1 if no forwarders
          Name: DWORD;
          FirstThunk: DWORD);
        // RVA to IAT (if bound this IAT has actual addresses)
  end;

  IMAGE_IMPORT_DESCRIPTOR = _IMAGE_IMPORT_DESCRIPTOR;
  TImageImportDescriptor = _IMAGE_IMPORT_DESCRIPTOR;
  PIMAGE_IMPORT_DESCRIPTOR = ^_IMAGE_IMPORT_DESCRIPTOR;
  PImageImportDescriptor = ^_IMAGE_IMPORT_DESCRIPTOR;

  _IMAGE_IMPORT_BY_NAME = record
    Hint: Word;
    Name: array [0 .. 0] of Byte;
  end;

  IMAGE_IMPORT_BY_NAME = _IMAGE_IMPORT_BY_NAME;
  TImageImportByName = _IMAGE_IMPORT_BY_NAME;
  PIMAGE_IMPORT_BY_NAME = ^_IMAGE_IMPORT_BY_NAME;
  PImageImportByName = ^_IMAGE_IMPORT_BY_NAME;

  // 'Windows PE文件的一些声明(winnt structures)'

  _IMAGE_BASE_RELOCATION = packed record
    VirtualAddress: DWORD;
    SizeOfBlock: DWORD;
  end;

  IMAGE_BASE_RELOCATION = _IMAGE_BASE_RELOCATION;
  PIMAGE_BASE_RELOCATION = ^_IMAGE_BASE_RELOCATION;


  // 很无语,XE2中直接定义成了32位的.没考虑64位情况.
{$IFDEF WIN64}
  PIMAGE_NT_HEADERS = ^_IMAGE_NT_HEADERS64;
  IMAGE_THUNK_DATA = IMAGE_THUNK_DATA64;
  PIMAGE_THUNK_DATA = ^IMAGE_THUNK_DATA64;

  PIMAGE_TLS_DIRECTORY = PIMAGE_TLS_DIRECTORY64;
{$ELSE}
  PIMAGE_NT_HEADERS = ^_IMAGE_NT_HEADERS;
  IMAGE_THUNK_DATA = IMAGE_THUNK_DATA32;
  PIMAGE_THUNK_DATA = ^IMAGE_THUNK_DATA32;

  PIMAGE_TLS_DIRECTORY = PIMAGE_TLS_DIRECTORY32;
{$ENDIF}
  PIMAGE_EXPORT_DIRECTORY = ^IMAGE_EXPORT_DIRECTORY;

  _IMAGE_EXPORT_DIRECTORY = record
    Characteristics: DWORD;
    TimeDateStamp: DWORD;
    MajorVersion: Word;
    MinorVersion: Word;
    Name: DWORD;
    Base: DWORD;
    NumberOfFunctions: DWORD;
    NumberOfNames: DWORD;
    AddressOfFunctions: DWORD;
    AddressOfNames: DWORD;
    AddressOfNameOrdinals: DWORD;
  end;

  IMAGE_EXPORT_DIRECTORY = _IMAGE_EXPORT_DIRECTORY;

const
  IMAGE_REL_BASED_ABSOLUTE = 0;
  IMAGE_REL_BASED_HIGH = 1;
  IMAGE_REL_BASED_LOW = 2;
  IMAGE_REL_BASED_HIGHLOW = 3;
  IMAGE_REL_BASED_HIGHADJ = 4;
  IMAGE_REL_BASED_MIPS_JMPADDR = 5;
  IMAGE_REL_BASED_SECTION = 6;
  IMAGE_REL_BASED_REL32 = 7;
  IMAGE_REL_BASED_MIPS_JMPADDR16 = 9;
  IMAGE_REL_BASED_IA64_IMM64 = 9;
  IMAGE_REL_BASED_DIR64 = 10;
  IMAGE_REL_BASED_HIGH3ADJ = 11;
  // 很无语,//XE2中直接定义成了32位的.没考虑64位情况.
  IMAGE_ORDINAL_FLAG64 = UINT64($8000000000000000);
  IMAGE_ORDINAL_FLAG32 = LongWord($80000000);
  IMAGE_ORDINAL_FLAG =
{$IFDEF WIN64}IMAGE_ORDINAL_FLAG64{$ELSE}IMAGE_ORDINAL_FLAG32{$ENDIF};
  MARCHINECODE =
{$IFDEF WIN64}IMAGE_FILE_MACHINE_AMD64{$ELSE}IMAGE_FILE_MACHINE_I386{$ENDIF};


  // 'Windows PE文件的一些声明

  MEMMODULEMAGICNUM = $19770605;

procedure dbgout(const str: string); overload;
begin
{$IFDEF USEDBGOUT}
  OutputDebugString(PChar(str));
{$ENDIF}
end;

procedure dbgout(const Format: string; const Args: array of const); overload;
begin
{$IFDEF USEDBGOUT}
  dbgout(SysUtils.Format(Format, Args));
{$ENDIF}
end;


// '拷贝Section(copy sections)'

procedure DoCopySections(const data: PAnsiChar; old_headers: PImageNtHeaders;
  var Module: TMemModule);
var
  i: Integer;
  dest: Pointer;
  section: PImageSectionHeader;
  SectionAlignment: Integer;
  Addr: Pointer;
  Size: NativeInt;
begin
  SectionAlignment := old_headers^.OptionalHeader.SectionAlignment;
  // section := IMAGE_FIRST_SECTION(Module.headers);  Delphi 的IMAGE_FIRST_SECTION计算的有问题?
  section := PImageSectionHeader(PAnsiChar(@Module.headers^.OptionalHeader) +
    Module.headers^.FileHeader.SizeOfOptionalHeader);
  for i := 0 to Module.headers.FileHeader.NumberOfSections - 1 do
  begin
    Addr := Module.codeBase + section^.VirtualAddress;
    if (section^.SizeOfRawData = 0) then
    begin
      // section没原始数据(DLL中),但是有时可能是未初始化的数据.
      Size := SectionAlignment;
      if (Size > 0) then // 对齐大小不是空
      begin
        dest := VirtualAlloc(Addr, Size, MEM_COMMIT, PAGE_EXECUTE_READWRITE);
        section^.Misc.PhysicalAddress := TNativeAddr(dest);
        ZeroMemory(dest, Size);
      end;
    end
    else
    begin
      Size := section^.SizeOfRawData;
      // 提交内存,并拷贝数据
      dest := VirtualAlloc(Addr, Size, MEM_COMMIT, PAGE_EXECUTE_READWRITE);
      CopyMemory(dest, @data[section^.PointerToRawData], Size);
      section^.Misc.PhysicalAddress := DWORD(dest);

    end;
    Inc(section);
  end;
end;

// '构建导入函数(fill imports)'

function DoFillImports(var Module: TMemModule): boolean;
type
  TFarProc = procedure();
  LPFarProc = ^TFarProc;
var
  dir: PImageDataDirectory;
  importDesc: PIMAGE_IMPORT_DESCRIPTOR;
  thunk: PIMAGE_THUNK_DATA;
  hm: HMODULE;
  mCount: Integer;
  func: LPFarProc;
  pByName: PIMAGE_IMPORT_BY_NAME;
begin
  result := false;
  dir := PImageDataDirectory(@Module.headers.OptionalHeader.DataDirectory
    [IMAGE_DIRECTORY_ENTRY_IMPORT]);
  // 没有任何导入函数,不存在导入表
  if (dir.VirtualAddress = 0) or (dir.Size = 0) then
    Exit;
  importDesc := PIMAGE_IMPORT_DESCRIPTOR(@Module.codeBase[dir.VirtualAddress]);
  mCount := 0;
  while importDesc^.Characteristics <> 0 do
  begin
    // 处理模块
    hm := LoadLibraryA(PAnsiChar(@Module.codeBase[importDesc^.Name]));
    dbgout(PAnsiChar(@Module.codeBase[importDesc^.Name]));
    if hm = 0 then
      Exit;
    if mCount >= Length(Module.modules) then
      SetLength(Module.modules, Length(Module.modules) + 16);
    Module.modules[mCount] := hm;
    Inc(mCount);
    // 处理函数
    if importDesc^.OriginalFirstThunk <> 0 then
    begin
      thunk := PIMAGE_THUNK_DATA
        (@Module.codeBase[importDesc^.OriginalFirstThunk]);
    end
    else
    begin
      thunk := PIMAGE_THUNK_DATA(@Module.codeBase[importDesc^.FirstThunk]);
    end;
    func := LPFarProc(@Module.codeBase[importDesc^.FirstThunk]);

    while thunk^._Function <> 0 do
    begin
      if (thunk^.Ordinal and IMAGE_ORDINAL_FLAG <> 0) then
      begin // 按序号
        func^ := Windows.GetProcAddress(hm,
          PAnsiChar(thunk^.Ordinal and $0000FFFF));
      end
      else // 按函数名
      begin
        pByName := PIMAGE_IMPORT_BY_NAME
          (@Module.codeBase[thunk^.AddressOfData]);
        func^ := Windows.GetProcAddress(hm, PAnsiChar(@pByName^.Name));
      end;
      if not Assigned(func^) then
        Exit;
      Inc(thunk);
      Inc(func);
    end;
    //
    Inc(importDesc);
  end;
  SetLength(Module.modules, mCount);
  result := True;
end;

// '修复需要重定位的地址(fix relocation)'

procedure DoRelocation(var Module: TMemModule; ImageBaseDelta: NativeInt);
var
  dir: PImageDataDirectory;
  relocation: PIMAGE_BASE_RELOCATION;
  BlockAddr: Pointer;
  i: Integer;
  pw: PWORD;
  relType: Word;
  offset: Word;
begin

  dir := PImageDataDirectory(@Module.headers.OptionalHeader.DataDirectory
    [IMAGE_DIRECTORY_ENTRY_BASERELOC]);
  if (dir.VirtualAddress = 0) or (dir.Size = 0) then
  begin
    dbgout('No RelocationData found.');
    Exit;
  end;
  relocation := PIMAGE_BASE_RELOCATION(@Module.codeBase[dir^.VirtualAddress]);
  while (relocation^.VirtualAddress <> 0) and (relocation^.SizeOfBlock > 0) do
  begin
    BlockAddr := @Module.codeBase[relocation^.VirtualAddress];
    // pw从定位表跳过头后面的实体数据
    pw := PWORD(NativeUInt(relocation) + SizeOf(IMAGE_BASE_RELOCATION));
    dbgout('pw=%x', [DWORD(pw)]);
    for i := 0 to (relocation.SizeOfBlock - SizeOf(IMAGE_BASE_RELOCATION))
      div SizeOf(Word) - 1 do
    begin
      // dbgout('*relInfo = %x',[DWORD(pw^)]);
      offset := pw^ and $0FFF;
      relType := (pw^ and $F000) shr 12;

      case relType of
        IMAGE_REL_BASED_ABSOLUTE:
          ;

        IMAGE_REL_BASED_HIGHLOW: // 32位
          begin
            Inc(PDWORD(DWORD(BlockAddr) + offset)^, ImageBaseDelta);
          end;
{$IFDEF WIN64}
        IMAGE_REL_BASED_DIR64:
          begin
            Inc(PUINT64(UINT64(BlockAddr) + offset)^, ImageBaseDelta);
            dbgout('IMAGE_REL_BASED_DIR64(=%x).',
              [PUINT64(UINT64(BlockAddr) + offset)^]);
          end;
{$ENDIF}
      else
        begin
          dbgout('Unknown relocation(=%d).', [relType]);
        end;
      end;
      Inc(pw);
    end;
    // 下一个定位
    relocation := PIMAGE_BASE_RELOCATION(PAnsiChar(relocation) +
      relocation^.SizeOfBlock);
  end;
end;


// '根据Section的选项设置页面的的保护属性(set page protect)'

procedure DoSetPageProtect(var Module: TMemModule);
var
  section: PImageSectionHeader;
  i: Integer;
  protectvalue, oldProtect: DWORD;
  imageOffset: NativeUInt;
  pgsize: NativeInt;
begin
  imageOffset :=
{$IFDEF WIN64} Module.headers.OptionalHeader.ImageBase and $FFFFFFFF00000000;
{$ELSE}0{$ENDIF};
  section := PImageSectionHeader(PAnsiChar(Module.headers) +
    SizeOf(TImageNtHeaders));
  //
  for i := 0 to Module.headers.FileHeader.NumberOfSections - 1 do
  begin
    protectvalue := 0;
    if (section^.Characteristics and IMAGE_SCN_MEM_EXECUTE) = IMAGE_SCN_MEM_EXECUTE
    then
      protectvalue := protectvalue or PAGE_EXECUTE;
    if (section^.Characteristics and IMAGE_SCN_MEM_READ) = IMAGE_SCN_MEM_READ
    then
      protectvalue := protectvalue or PAGE_READONLY;
    if (section^.Characteristics and IMAGE_SCN_MEM_WRITE) = IMAGE_SCN_MEM_WRITE
    then
      protectvalue := protectvalue or PAGE_WRITECOPY;
    if (section^.Characteristics and IMAGE_SCN_MEM_NOT_CACHED) = IMAGE_SCN_MEM_NOT_CACHED
    then
      protectvalue := protectvalue or PAGE_NOCACHE;
    // protectvalue := protectvalue and PAGE_EXECUTE_READWRITE;
    //
    if (section^.Characteristics and IMAGE_SCN_MEM_DISCARDABLE) = IMAGE_SCN_MEM_DISCARDABLE
    then
    begin
      VirtualFree(Pointer(section^.Misc.PhysicalAddress or imageOffset),
        section^.SizeOfRawData, MEM_DECOMMIT);
      continue;
    end;
    pgsize := section^.SizeOfRawData;
    if pgsize = 0 then
    begin
      if (section^.Characteristics and IMAGE_SCN_CNT_INITIALIZED_DATA) = IMAGE_SCN_CNT_INITIALIZED_DATA
      then
      begin
        pgsize := Module.headers.OptionalHeader.SizeOfInitializedData;
      end
      else if (section^.Characteristics and IMAGE_SCN_CNT_UNINITIALIZED_DATA) = IMAGE_SCN_CNT_UNINITIALIZED_DATA
      then
      begin
        pgsize := Module.headers.OptionalHeader.SizeOfUninitializedData;
      end
    end;

    if pgsize > 0 then
    begin
      VirtualProtect(Pointer(section^.Misc.PhysicalAddress or imageOffset),
        pgsize, protectvalue, oldProtect);
    end;
    //
    Inc(section);
  end;
end;

// '初始化异常处理函数表(initialize exceptions)'

{$IFDEF WIN64}

{ X86处理器的SEH机制是不用这里的,所以是空.其他处理器AMD64,Alpha,Arm等才使用.
  所以32位的情况不需要处理,X64的时候才处理.
}
procedure DoInitializeSEH(var Module: TMemModule);

var
  dir: PImageDataDirectory;
  pTmp: PImageRuntimeFunctionEntry;
  EnrtyNums: DWORD;
  RtlAddFunctionTable: function(FunctionTable: PImageRuntimeFunctionEntry;
    EntryCount: DWORD; BaseAddress: DWORD64): boolean; stdcall;
begin
  @RtlAddFunctionTable := GetProcAddress(GetModuleHandle(kernel32),
    'RtlAddFunctionTable');
  if not Assigned(RtlAddFunctionTable) then
    Exit;
  dir := PImageDataDirectory(@Module.headers.OptionalHeader.DataDirectory
    [IMAGE_DIRECTORY_ENTRY_EXCEPTION]);
  if (dir.VirtualAddress = 0) or (dir.Size = 0) then
  begin
    dbgout('No SEH found.');
    Exit;
  end;
  Module.runtimeFunc := PImageRuntimeFunctionEntry
    (@Module.codeBase[dir.VirtualAddress]);
  pTmp := Module.runtimeFunc;

  EnrtyNums := dir.Size div SizeOf(IMAGE_RUNTIME_FUNCTION_ENTRY);
  if not RtlAddFunctionTable(Module.runtimeFunc, EnrtyNums,
    DWORD64(Module.codeBase)) then
    dbgout('Could not add function table.');
end;
{$ENDIF}

// 'LoadLibrary'
function MemLoadLibrary(const buf: Pointer): HMemModule;
var
  pDos: PImageDosHeader;
  pOld: PImageNtHeaders;
  _buf: PAnsiChar;
  // headers: PAnsiChar;
  ret: LPMemModule;
  ImageBaseDelta: NativeInt;
begin
  result := 0;
  new(ret);
  ZeroMemory(ret, SizeOf(TMemModule));
  ret^.magic := MEMMODULEMAGICNUM;
  _buf := buf;
  pDos := PImageDosHeader(_buf);
  if pDos^.e_magic <> IMAGE_DOS_SIGNATURE then
  begin
    Dispose(ret);
    dbgout('Not a valid executable file,No DOS header found.');
    Exit;
  end;
  pOld := PImageNtHeaders(@_buf[pDos^._lfanew]);

  if pOld^.Signature <> IMAGE_NT_SIGNATURE then
  begin
    Dispose(ret);
    dbgout('Not a valid executable file,No PE header found.');
    Exit;
  end;

  if pOld^.FileHeader.Machine <> MARCHINECODE then
  begin
    Dispose(ret);
    dbgout('Not a right mathine.');
    Exit;
  end;
  // 尝试在ImageBase的位置分配内存
  ret^.codeBase :=
    PAnsiChar(VirtualAlloc(Pointer(pOld^.OptionalHeader.ImageBase),
    pOld^.OptionalHeader.SizeOfImage, MEM_COMMIT or MEM_RESERVE,
    PAGE_EXECUTE_READWRITE));
  // 如果分配失败就由系统指派
  if ret^.codeBase = nil then
    ret^.codeBase :=
      PAnsiChar(VirtualAlloc(nil, pOld^.OptionalHeader.SizeOfImage, MEM_RESERVE,
      PAGE_EXECUTE_READWRITE));
  if ret^.codeBase = nil then
  begin
    Dispose(ret);
    dbgout('Can''t alloc memory.');
    Exit;
  end;
  //
  // 真正按code地址分配
  VirtualAlloc(ret^.codeBase, pOld^.OptionalHeader.SizeOfImage, MEM_COMMIT,
    PAGE_EXECUTE_READWRITE);
  VirtualAlloc(ret^.codeBase, pOld^.OptionalHeader.SizeOfHeaders, MEM_COMMIT,
    PAGE_EXECUTE_READWRITE);
  ret^.headers := PImageNtHeaders(@ret^.codeBase[pDos^._lfanew]);
  CopyMemory(ret^.codeBase, pDos, pOld^.OptionalHeader.SizeOfHeaders);
  //
  ret^.headers := PImageNtHeaders(@ret^.codeBase[pDos^._lfanew]);
  // 修正ImageBase如果原有ImageBase被占用,结果分配到不同地方
  ret^.headers.OptionalHeader.ImageBase := TNativeAddr(ret^.codeBase);
  // 拷贝Section
  DoCopySections(_buf, pOld, ret^);
  // 查看是否需要重定位.
  ImageBaseDelta := (NativeInt(ret^.codeBase) - pOld^.OptionalHeader.ImageBase);
  if (ImageBaseDelta <> 0) then
    DoRelocation(ret^, ImageBaseDelta);
  // 初始化异常处理表
{$IFDEF WIN64}
  DoInitializeSEH(ret^);
{$ENDIF}
  // 修正导入表
  if not DoFillImports(ret^) then
  begin
    MemFreeLibrary(HMemModule(@ret));
    Exit;
  end;

  // 设置Section的页面保护属性.
  DoSetPageProtect(ret^);
  // 设置和调用入口函数
  if ret^.headers.OptionalHeader.AddressOfEntryPoint <> 0 then
  begin
    ret^.entrypoint :=
      TFNDllMain(@ret^.codeBase
      [ret^.headers.OptionalHeader.AddressOfEntryPoint]);
    if (Assigned(ret^.entrypoint)) then //
    begin
      try
        if (not ret^.entrypoint(HMODULE(ret^.codeBase), DLL_PROCESS_ATTACH, nil))
        // if false

        then
        begin
          MemFreeLibrary(HMemModule(@ret));
          Exit;
        end;
      except

      end;
    end
    else
    begin
      MemFreeLibrary(HMemModule(@ret));
      Exit;
    end;
    ret^.initialized := True;
  end;
  result := HMODULE(ret);
end;

// 'GetProcAddress'
function MemGetProcAddress(Module: HMemModule;
  const lpProcName: LPCSTR): FARPROC;
type
  TDWORDArray = array [0 .. 0] of DWORD;
  PDWORDArray = ^TDWORDArray;
  function StrIComp(const Str1, Str2: PAnsiChar): Integer;
  var
    P1, P2: PAnsiChar;
    C1, C2: AnsiChar;
  begin
    P1 := Str1;
    P2 := Str2;
    while True do
    begin
      if P1^ in ['a' .. 'z'] then
        C1 := AnsiChar(Byte(P1^) xor $20)
      else
        C1 := P1^;

      if P2^ in ['a' .. 'z'] then
        C2 := AnsiChar(Byte(P2^) xor $20)
      else
        C2 := P2^;

      if (C1 <> C2) or (C1 = #0) then
      begin
        Result := (Ord(C1) - Ord(C2));
        Exit;
      end;
      Inc(P1);
      Inc(P2);
    end;
  end;

var
  i, idx: Integer;
  dir: PImageDataDirectory;
  pm: LPMemModule;
  Ordinal: PWORD;
  nameRef: PDWORD;
  exps: PIMAGE_EXPORT_DIRECTORY;
  func: DWORD;
begin
  result := nil;
  idx := -1;
  pm := LPMemModule(Module);
  if (pm = nil) or (pm^.magic <> MEMMODULEMAGICNUM) then
    Exit;
  // Exit(FindMyResFunc(pm^.codeBase, lpProcName));
  dir := PImageDataDirectory(@pm^.headers.OptionalHeader.DataDirectory
    [IMAGE_DIRECTORY_ENTRY_EXPORT]);

  if (dir^.VirtualAddress = 0) or (dir^.Size = 0) then
    Exit;

  exps := PIMAGE_EXPORT_DIRECTORY(@pm^.codeBase[dir.VirtualAddress]);

  if (exps^.NumberOfFunctions = 0) then
    Exit;
  // 16位以上是0,那么就是用索引查找函数.
  if ((NativeUInt(lpProcName)) <= $FFFF) then
  begin
    idx := NativeUInt(lpProcName) - exps^.Base;
  end
  else // 否则按照函数名称查找
  begin
    if (exps^.NumberOfNames = 0) then
      Exit;
    nameRef := PDWORD(pm^.codeBase + exps^.AddressOfNames);
    Ordinal := PWORD(pm^.codeBase + exps^.AddressOfNameOrdinals);
    for i := 0 to exps^.NumberOfNames-1 do
    begin
      if StrIComp(lpProcName, LPCSTR(@pm^.codeBase[nameRef^])) = 0 then
      begin
        idx := Ordinal^;
        Break;
      end;
      //
      Inc(nameRef);
      Inc(Ordinal);
    end;
  end;
  if (idx < 0) or (idx > exps^.NumberOfFunctions) then
    Exit;
  func := PDWORDArray(@pm^.codeBase[exps^.AddressOfFunctions])[idx];
  result := @pm^.codeBase[func];
end;

// 'FreeLibrary'
function MemFreeLibrary(Module: HMemModule): BOOL;
var
  pm: LPMemModule;
  i: Integer;
  RtlDeleteFunctionTable: function(FunctionTable: PImageRuntimeFunctionEntry)
    : boolean; stdcall;
begin
  result := false;
  pm := LPMemModule(Module);
  if (pm = nil) or (pm^.magic <> MEMMODULEMAGICNUM) then
    Exit;
  if pm^.initialized and Assigned(pm^.entrypoint) then
    pm.entrypoint(NativeUInt(pm^.codeBase), DLL_PROCESS_DETACH, nil);
  if pm^.runtimeFunc <> nil then
  begin
    @RtlDeleteFunctionTable := GetProcAddress(GetModuleHandle(kernel32),
      'RtlDeleteFunctionTable');
    if Assigned(RtlDeleteFunctionTable) then
      RtlDeleteFunctionTable(pm^.runtimeFunc);
    pm^.runtimeFunc := nil;
  end;
  for i := Low(pm^.modules) to High(pm^.modules) do
    if (pm^.modules[i] <> 0) and (pm^.modules[i] <> INVALID_HANDLE_VALUE) then
      FreeLibrary(pm^.modules[i]);
  pm^.modules := nil;
  if pm^.codeBase <> nil then
    VirtualFree(pm^.codeBase, 0, MEM_RELEASE);
  Dispose(pm);
end;

end.