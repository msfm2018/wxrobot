unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls;

type
  TForm1 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  function StartWeChatAndInject(dllPath: PWideChar): Integer; stdcall; external 'wxstart.dll';
function InjectToWeChat(dllPath: PWideChar): Integer; stdcall; external 'wxstart.dll';
implementation

{$R *.dfm}


       const
  WM_EXEC_PATCH = WM_USER + 100;

procedure TriggerPatchFromDelphi;
var
  hWnd: thandle;
begin
  hWnd := FindWindow('RevokePatchMsgWnd', nil);
  if hWnd = 0 then
  begin
    ShowMessage('找不到隐藏窗口，DLL可能尚未注入或尚未初始化');
    Exit;
  end;


  PostMessage(hWnd, WM_EXEC_PATCH, 0, 0);


end;
procedure TForm1.Button1Click(Sender: TObject);
begin
  TriggerPatchFromDelphi
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
StartWeChatAndInject('');
end;

procedure TForm1.Button3Click(Sender: TObject);
var DllPath:string;
begin
         DllPath := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) + 'wxpatch.dll';
InjectToWeChat(pchar(DllPath));
end;

end.
