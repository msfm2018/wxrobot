unit qplugins_loader_lib;

{ DLL/SO/BPL加载器实现单元，在使用时加载特定的加载器实现加载特定的插件
  TQDLLLoader - Windows 的 DLL 加载器
  TQBPLLoader - BPL 加载器
  TQSOLoader - Linux 系的 SO 加载器
}
interface

uses classes, sysutils{$IFDEF MSWINDOWS}, windows, qdac_memmodule{$ENDIF},
  qstring, qplugins, qplugins_base;
{$HPPEMIT '#pragma link "qplugins_loader_lib"'}

type
  // 基类
  TQLibLoader = class(TQBaseLoader)
  protected
    function GetLoadingModule: HINST; override; stdcall;
    function GetServiceSource(AService: IQService; ABuf: PWideChar;
      ALen: Integer): Integer; override; stdcall;
  public
  end;
{$IFDEF MSWINDOWS}

  TQDLLLoader = class(TQLibLoader)
  protected
    function CanLoad(const AFileName: QStringW): Boolean;
    function InternalLoadServices(const AFileName: PWideChar): THandle;
      overload; override;
    function InternalLoadServices(const AStream: TStream): THandle;
      overload; override;
    function InternalUnloadServices(const AHandle: THandle): Boolean; override;
  public
    constructor Create(APath, AExt: QStringW;
      AIncludeSubDir: Boolean = false); overload;
  end;

  TQBPLLoader = class(TQLibLoader)
  protected
    function InternalLoadServices(const AFileName: PWideChar): THandle;
      overload; override;
    function InternalLoadServices(const AStream: TStream): THandle;
      overload; override;
    function InternalUnloadServices(const AHandle: THandle): Boolean; override;
  public
    constructor Create(APath, AExt: QStringW;
      AIncludeSubDir: Boolean = false); overload;
  end;

{$ELSE}

  TQSOLoader = class(TQLibLoader)
  protected
    function InternalLoadServices(const AFileName: PWideChar): THandle;
      override;
    function InternalUnloadServices(const AHandle: THandle): Boolean; override;
  public
    constructor Create(APath, AExt: QStringW); overload;
  end;
{$ENDIF}

function GetCodeFileName(Addr: Pointer): QStringW;

const
  LID_DLL: TGuid = '{558F1A1B-52E6-4E88-8FD2-9F02027E8C39}';
  LID_SO: TGuid = '{65689986-CEC7-4FFF-99F5-BA86D4E48F2F}';
  LID_PACKAGE: TGuid = '{5EB06801-995A-4AA9-95E8-E450D38DD5CA}';

implementation

resourcestring
  SServiceAlreayLoaded = '服务插件 %s 可能已经被静态加载，不需要再动态导入。';
  SCanLoadDiffPlatformLibrary =
{$IFDEF CPU64BITS}'不能在64位宿主中加载32位插件 %s 。'{$ELSE}'不能在32位宿主中加载64位插件 %s 。'{$ENDIF};
  { TQLibLoader }

function TQLibLoader.GetLoadingModule: HINST;
begin
  Result := inherited;
  if (Result = 0) and (Length(FActiveFileName) > 0) then
    Result := GetModuleHandle{$IFNDEF UNICODE}W{$ENDIF}(PWideChar(FActiveFileName));
end;

function TQLibLoader.GetServiceSource(AService: IQService; ABuf: PWideChar;
  ALen: Integer): Integer;
begin
  Result := {$IFDEF UNICODE}GetModuleFileName{$ELSE}GetModuleFileNameW{$ENDIF}(AService.GetOwnerInstance, ABuf, ALen);
end;

function GetCodeFileName(Addr: Pointer): QStringW;
begin
  SetLength(Result, MAX_PATH);
  SetLength(Result,
{$IFDEF UNICODE}GetModuleFileName{$ELSE}GetModuleFileNameW{$ENDIF}(FindHInstance(Addr), PWideChar(Result), MAX_PATH));
end;

// 获取指定地址所隶属的实例，暂时只实现了 Windows，Linux下的回头再研究
{$IFDEF MSWINDOWS}
{ TQDLLLoader }

function TQDLLLoader.CanLoad(const AFileName: QStringW): Boolean;
{$IFDEF MSWINDOWS}
  function WinLibCheck: Boolean;
  var
    AStream: TFileStream;
    wMachine: Word;
    ADosHeader: TImageDosHeader;
  begin
    AStream := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyNone);
    try
      Result := false;
      if AStream.Read(ADosHeader, SizeOf(TImageDosHeader))
        = SizeOf(TImageDosHeader) then
      begin
        AStream.Position := ADosHeader._lfanew;
        if (AStream.Read(wMachine, 2) = 2) and (wMachine = $4550) then
        begin
          AStream.Position := ADosHeader._lfanew + 4;
          if AStream.Read(wMachine, 2) = 2 then
            Result := (wMachine =
{$IFDEF CPUX64}IMAGE_FILE_MACHINE_AMD64{$ELSE}IMAGE_FILE_MACHINE_I386{$ENDIF});
        end;
      end;
    finally
      FreeAndNil(AStream);
    end;
  end;
{$ENDIF}

begin
{$IFDEF MSWINDOWS}
  Result := WinLibCheck;
{$ELSE}
  Result := true;
{$ENDIF}
end;

constructor TQDLLLoader.Create(APath, AExt: QStringW; AIncludeSubDir: Boolean);
begin
  if Length(AExt) = 0 then
    AExt := '.DLL';
  inherited Create(LID_DLL, 'Loader_DLL', APath, AExt, AIncludeSubDir);
end;

function TQDLLLoader.InternalLoadServices(const AStream: TStream): THandle;
var
  AMemStream: TMemoryStream;
begin
  if AStream is TMemoryStream then
    AMemStream := AStream as TMemoryStream
  else
  begin
    AMemStream := TMemoryStream.Create;
    AMemStream.Size := AStream.Size;
    AMemStream.CopyFrom(AStream, 0);
  end;
  try
    Result := MemLoadLibrary(AMemStream.Memory);
    if Result <> 0 then
      Result := Result + 1;
  finally
    if AMemStream <> AStream then
      FreeAndNil(AMemStream);
  end;
end;

function TQDLLLoader.InternalUnloadServices(const AHandle: THandle): Boolean;
begin
  if (AHandle and $1) <> 0 then
    MemFreeLibrary(AHandle and (not THandle(1)))
  else
    FreeLibrary(AHandle);
  Result := true;
end;

function TQDLLLoader.InternalLoadServices(const AFileName: PWideChar): THandle;
var
  AErrorCode: Integer;
begin
  try
    Result := GetModuleHandleW(AFileName);
    if Result <> 0 then
    begin
      Result := 0;
      SetLastError(1, Format(SServiceAlreayLoaded,[AFileName]));
    end
    else if CanLoad(AFileName) then
    begin
      Result := {$IFDEF UNICODE}LoadLibrary{$ELSE}LoadLibraryW{$ENDIF}(PWideChar(AFileName));
      if Result = 0 then
      begin
        AErrorCode := GetLastError;
        SetLastError(AErrorCode, SysErrorMessage(AErrorCode));
      end;
    end
    else
      SetLastError(2, Format(SCanLoadDiffPlatformLibrary,[AFileName]));
  except
    on E: Exception do
    begin
      Result := 0;
      SetLastError(1, E.Message);
    end;
  end;
end;

{ TQBPLLoader }

constructor TQBPLLoader.Create(APath, AExt: QStringW; AIncludeSubDir: Boolean);
begin
  if Length(AExt) = 0 then
    AExt := '.BPL';
  inherited Create(LID_PACKAGE, 'Loader_BPL', APath, AExt, AIncludeSubDir);
end;

function TQBPLLoader.InternalLoadServices(const AFileName: PWideChar): THandle;
begin
  try
    Result := LoadPackage(AFileName);
  except
    on E: Exception do
    begin
      Result := 0;
      SetLastError(1, E.Message);
    end;
  end;
end;

function TQBPLLoader.InternalLoadServices(const AStream: TStream): THandle;
var
  AMemStream: TMemoryStream;
begin
  if AStream is TMemoryStream then
    AMemStream := AStream as TMemoryStream
  else
  begin
    AMemStream := TMemoryStream.Create;
    AMemStream.Size := AStream.Size;
    AMemStream.CopyFrom(AStream, 0);
  end;
  try
    Result := MemLoadLibrary(AMemStream.Memory);
    if Result <> 0 then
      InitializePackage(Result);
  finally
    if AMemStream <> AStream then
      FreeAndNil(AMemStream);
  end;
end;

function TQBPLLoader.InternalUnloadServices(const AHandle: THandle): Boolean;
begin
  UnloadPackage(AHandle);
  Result := true;
end;
{$ELSE}
{ TQSOLoader }

constructor TQSOLoader.Create(APath, AExt: QStringW);
begin
  if Length(AExt) = 0 then
    AExt := '.SO';
  inherited Create(LID_SO, 'Loader_SO', APath, AExt);
end;

function TQSOLoader.InternalLoadServices(const AFileName: PWideChar): THandle;
begin
  try
    Result := LoadLibrary(PWideChar(AFileName));
  except
    on E: Exception do
    begin
      Result := 0;
      SetLastError(1, E.Message);
    end;
  end;
end;

function TQSOLoader.InternalUnloadServices(const AHandle: THandle): Boolean;
begin
  FreeLibrary(AHandle);
  Result := true;
end;
{$ENDIF}

end.
