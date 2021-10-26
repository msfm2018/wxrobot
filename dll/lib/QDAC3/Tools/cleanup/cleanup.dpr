program cleanup;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,windows;
var
  AFileName:String;
  ApplicationPath:String;
function CanCleanup(APath,AFileName:String;AIsDir:Boolean):Boolean;
var
  AExt:String;
  AName:String;
  function ParentCanDelete(AParent:String):Boolean;
  begin
  if AParent<>ApplicationPath then
    begin
    if AParent[AParent.Length]='\' then
      Delete(AParent,AParent.Length,1);
    Result:=CanCleanup(ExtractFilePath(AParent),ExtractFileName(AParent),True);
    end
  else
    Result:=False;
  end;
begin
AName:=LowerCase(AFileName);
if AIsDir then//历史目录直接删除
  begin
  Result:=(AName='__history') or (AName='debug') or (AName='release') or (AName='win32') or (AName='win64')
    or (AName='android') or (AName='iosdevice') or ParentCanDelete(APath);
  end
else
  begin
  AExt:=ExtractFileExt(AName);
  Result:=(AExt='.dcu') or
    (Copy(AExt,1,2)='.~') or
    (AExt='.tds') or
    (AExt='.obj') or
    (AExt='.so') or
    (Copy(AExt,1,3)='.il') or
    (AExt='.log') or
    (AExt='.sqlite3') or
    (AExt='.bcc32pch') or
    (AExt='.7z') or
    (AExt='.zip') or
    (AExt='.map') or
    (AExt='.bak') or
    (AExt='.pch') or
    (AExt='.pdi') or
    (Copy(AExt,1,2)='.#') or
    (AExt='.rar') or
    (AExt='.cgl') or
    (AExt='.tmp') or
    ParentCanDelete(APath);
  end;
end;

procedure DoClean(APath:String);
var
  wfd:WIN32_FIND_DATA;
  hFind:THandle;
begin
hFind:=FindFirstFile(PWideChar(APath+'*.*'),wfd);
if hFind<>INVALID_HANDLE_VALUE then
  begin
  repeat
    if (wfd.dwFileAttributes and FILE_ATTRIBUTE_DIRECTORY)=0 then
      begin
      if CanCleanup(APath,wfd.cFileName,false) then
        begin
        WriteLn('删除文件 '+APath+wfd.cFileName);
        DeleteFile(PWideChar(APath+wfd.cFileName));
        end;
      end
    else
      begin
      if not ((wfd.cFileName[0]='.') and ((wfd.cFileName[1]=#0) or
        ((wfd.cFileName[1]='.') and (wfd.cFileName[2]=#0)))) then
        begin
        DoClean(APath+wfd.cFileName+'\');
        if CanCleanup(APath,wfd.cFileName,true) then
          begin
          WriteLn('删除目录 '+APath+wfd.cFileName);
          RemoveDir(APath+wfd.cFileName);
          end;
        end;
      end;
  until not FindNextFile(hFind,wfd);
  FindClose(hFind);
  end;
end;

begin
  try
    { TODO -oUser -cConsole Main : Insert code here }
    SetLength(AFileName,MAX_PATH);
    SetLength(AFileName,GetModuleFileName(0,PWideChar(AFileName),MAX_PATH));
    ApplicationPath:=ExtractFilePath(AFileName);
    DoClean(ApplicationPath);
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
