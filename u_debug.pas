unit u_Debug;

interface

uses
  windows, SysUtils, Vcl.Graphics;

{$DEFINE DEBUG}
{$DEFINE DEBUGLOG}
var
  Freq ,Timer1, Timer2, Timer3: Comp;

var
    DebugLog :Boolean =False;
    DebugWin :Boolean =false;
type
  TLog = class
  private
      FF :textfile;
  protected

  public
    constructor Create(FileName :string);
    destructor Destroy; override;
    procedure WriteString(str :String);
    procedure Clear();
  end;
  
  TDebug = class
  private
    hConsole :THandle;
    err :boolean;
    Log :TLog;
    lgfile :string;
    procedure newConsole();
    procedure outmsg (msg :string);
//    procedure close();

  protected

  public
    constructor Create(LogFileName :string='');
    destructor Destroy();override;
    {class} procedure Error(msg :string);overload;
    {class} procedure Error(msg :integer);overload;
    {class} procedure Error(msg :Int64);overload;
    {class} procedure Error(msg :Pointer;Len :integer; hex :boolean =false);overload;
    {class} procedure Error(msg :double);overload;
    {class} procedure Error(msg :TObject);overload;
    {     }
    {class} procedure Show(msg :string);overload;
    {class} procedure Show(msg :integer);overload;
    {class} procedure Show(msg :Int64);overload;
    {class} procedure Show(msg :Pointer;Len :integer; hex :boolean =false);overload;
    {class} procedure Show(msg :double);overload;
    {class} procedure Show(msg :TObject);overload;
    {class} procedure StartTime();
    {class} procedure ShowUseTime(Description :string);
            procedure ShowCurrentTime(Description :string);
            procedure Resetlog();

  published

  end;

var
  Debug :TDebug;
  Debug1 :TDebug;
  defColor :TColor =$FF0007;
  errColor :TColor =$FF0003;
implementation

{$I-}
{ TLog }

constructor TLog.Create(FileName :string);
begin
  inherited create();
    AssignFile(ff, FileName);
    if not fileexists(FileName) then
        ReWrite(fF);
    Append(ff);
end;

destructor TLog.Destroy;
begin
     closefile(ff);

  inherited;
end;

procedure TLog.WriteString(str: String);
begin
    write(ff, str);
    write(ff, #13#10);
    Flush(ff);
end;

procedure TLog.clear;
begin
    ReWrite(fF);
end;


{ TDebug }

{procedure TDebug.close;
begin
//{$ifdef DEBUG}
       // CloseHandle(hConsole);
       // FreeConsole;
//{$endif DEBUG}

{end; }


procedure TDebug.Error(msg: integer);
begin
  Debug.err :=true;
  Show(msg);
end;

procedure TDebug.Error(msg: string);
begin
  Debug.err :=true;
  Show(msg);
end;

constructor TDebug.Create(LogFileName :string='');
begin
{$ifdef DEBUGLOG}
    hConsole :=0;
    lgfile :=LogFileName;
    if lgfile ='' then lgfile :='debug.log';
    if not DirectoryExists(ExtractFilePath(ParamStr(0)) + '\log\') then
        MkDir(ExtractFilePath(ParamStr(0)) + '\log\');

{$endif DEBUGLOG}
end;

procedure TDebug.Error(msg: TObject);
begin
  Debug.err :=true;
  Show(msg);
end;

procedure TDebug.Error(msg: Pointer; Len: integer; hex :boolean =false);
begin
  Debug.err :=true;
  Show(msg, len, hex);
end;

procedure TDebug.Error(msg: double);
begin
  Debug.err :=true;
  Show(msg);
end;

procedure TDebug.newConsole;
var
    hc :HWND;
    hMenu :HWND;
begin
    if hConsole <>0 then
    begin
        CloseHandle(hConsole);
        FreeConsole;
    end;
    AllocConsole;
    hConsole :=GetStdHandle(STD_OUTPUT_HANDLE);//
    SetWindowLong(hConsole,GWL_EXSTYLE, GetWindowLong(hConsole, GWL_EXSTYLE) or WS_EX_TOOLWINDOW) ;
    SetConsoleMode(hConsole, ENABLE_PROCESSED_OUTPUT or ENABLE_WRAP_AT_EOL_OUTPUT );
    //(hConsole, FOREGROUND_GREEN );
    hc :=FindWindow('ConsoleWindowClass', nil);
    hMenu := GetSystemMenu(hc, false);
    if(hMenu <> 0) then
    begin
        DeleteMenu(hMenu, SC_CLOSE, MF_BYCOMMAND);
        DrawMenuBar(hc);
    end;  

end;

procedure TDebug.outmsg(msg: string);
var
    nCharsWritten :dword;
    rn :string;
begin
{$ifdef DEBUG}
    if DebugWin then
    begin
        if hConsole = 0 then newConsole;
        if err then
          SetConsoleTextAttribute(hConsole, errColor);
        msg :=FormatDateTime('hh:mm:ss:zzz ', now) + msg;
        rn :=#13#10;
        WriteConsole(hConsole, @msg[1], length(msg), nCharsWritten, nil);
        WriteConsole(hConsole, @rn[1], length(rn), nCharsWritten, nil);
        SetConsoleTextAttribute(hConsole, defColor);
        err :=false;
    end;
{$endif DEBUG}
{$ifdef DEBUGLOG}
    if DebugLog then
    begin
        if Log = nil then Log :=TLog.Create(ExtractFilePath(ParamStr(0)) + '\log\' + lgfile);
        Log.WriteString(MSG);
    end;
{$endif DEBUGLOG}
end;

procedure TDebug.Show(msg: string);
begin
{$ifdef DEBUG}
    //if not DebugWin then exit;
    outmsg(msg);
{$endif DEBUG}
end;

procedure TDebug.Show(msg: integer);
begin
{$ifdef DEBUG}

    outmsg(InttoStr(msg));
{$endif DEBUG}

end;

procedure TDebug.Show(msg: Pointer; Len: integer; hex :boolean =false);
var
  str :String;
  function StrToHex(AStr: string): string;
  var
  I ,Len: Integer;
  s:char;
  begin
    len:=length(AStr);
    Result:='';
    for i:=1 to len  do
    begin
      s:=AStr[i];
      Result:=Result +' '+IntToHex(Ord(s),2); //将字符串转化为16进制字符串，
                                              //并以空格间隔。
    end;
    Delete(Result,1,1); //删去字符串中第一个空格
  end;

begin
{$ifdef DEBUG}
    if not DebugWin then exit;
    if Len > 500 then exit;
    SetLength(str, len);
    Move(msg^, str[1], len);
    //if hex then
      str :=StrToHex(str);
    outmsg(str);
{$endif DEBUG}
end;

procedure TDebug.Show(msg: TObject);

//var

//  Method: TMethod;
//  TtoString :function :string of Object;
begin
{$ifdef DEBUG}

  outmsg('ClassName :' + msg.ClassName);
  if msg.ClassParent <> nil then
    outmsg('ClassParent :' + msg.ClassParent.ClassName);
  {Method.Code := msg.MethodAddress('toString');
  Method.Data := Self;
  if Assigned(Method.Code) then
  begin
    TMethod(TtoString) := Method;
    Debug.outmsg('toString :' +TtoString);
  end; }
{$endif DEBUG}
end;

procedure TDebug.Show(msg: double);
begin
{$ifdef DEBUG}
  outmsg(FloattoStr(msg));
{$endif DEBUG}

end;

procedure TDebug.ShowUseTime(Description :string);
begin
{$ifdef DEBUG}
    QueryPerformanceFrequency(TLargeInteger((@Freq)^));
    QueryPerformanceCounter(TLargeInteger((@Timer1)^));
    Show(Description +':' + Sysutils.FloatToStr((Timer1 - Timer2) / Freq));
    Timer2 :=Timer1;
{$endif DEBUG}
end;

procedure TDebug.StartTime;
begin
{$ifdef DEBUG}
    QueryPerformanceFrequency(TLargeInteger((@Freq)^));
    QueryPerformanceCounter(TLargeInteger((@Timer1)^));
    Timer2 :=Timer1;
{$endif DEBUG}

end;

destructor TDebug.Destroy;
begin
    Log.Free ;
end;

procedure TDebug.Show(msg: Int64);
begin
{$ifdef DEBUG}
  outmsg(InttoStr(msg));
{$endif DEBUG}

end;

procedure TDebug.Error(msg: Int64);
begin
{$ifdef DEBUG}
  Debug.err :=true;
  Show(msg);
{$endif DEBUG}
end;

procedure TDebug.ShowCurrentTime(Description: string);
begin
    QueryPerformanceCounter(TLargeInteger((@Timer1)^));
    Show('ShowCurrentTime' + Description +':' + Sysutils.FloatToStr((Timer1) / Freq));
    Show('ShowCurrentTime' + Description +':' +InttoStr(GetTickCount()));

end;

procedure TDebug.Resetlog;
begin
     if Log <> nil then Log.Clear();//
end;

initialization
  DebugWin:=true;
  Debug :=TDebug.Create;
  Debug1 :=TDebug.Create('debug1.log');
finalization
begin
//  Debug.close;
  Debug.Free ;
  Debug :=nil;
end;
end.

