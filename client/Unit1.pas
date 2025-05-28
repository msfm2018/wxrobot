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
    Button4: TButton;
    Button5: TButton;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  function StartWeChatAndInject(dllPath: PWideChar): Integer; stdcall; external 'wxstart.dll';
  function InjectToWeChat(dllPath: PWideChar): Integer; stdcall; external 'wxstart.dll';

  function PatchWeChatDllFile(dllPath: PWideChar): Bool; stdcall; external 'myfilemopen.dll';

implementation

{$R *.dfm}




procedure TriggerPatchFromDelphi(cmd:uint);
var
  hWnd: thandle;
begin
  hWnd := FindWindow('RevokePatchMsgWnd', nil);
  if hWnd = 0 then
  begin
    ShowMessage('找不到隐藏窗口，DLL可能尚未注入或尚未初始化');
    Exit;
  end;


  PostMessage(hWnd, cmd, 0, 0);


end;
procedure TForm1.Button1Click(Sender: TObject);
begin
  TriggerPatchFromDelphi( WM_USER + 40517);
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
button3.Enabled:=false;
end;

procedure TForm1.Button4Click(Sender: TObject);
begin
    TriggerPatchFromDelphi( WM_USER + 40518);
end;

procedure TForm1.Button5Click(Sender: TObject);
//begin
//    PatchWeChatDllFile( 'C:\Program Files\Tencent\Weixin\4.0.5.18\Weixin.dll');

    var
  dlg: TOpenDialog;
  dllPath: string;
  result: Bool;
begin
  dlg := TOpenDialog.Create(nil);
  try
    dlg.Filter := 'DLL Files (*.dll)|*.dll';
    dlg.InitialDir := 'C:\Program Files\Tencent\Weixin\';
    if dlg.Execute then
    begin
      dllPath := dlg.FileName;
      result := PatchWeChatDllFile(PWideChar(dllPath));
      if result then
        ShowMessage('补丁应用成功！')
      else
        ShowMessage('补丁失败或DLL不兼容。');
    end;
  finally
    dlg.Free;
  end;
end;

end.
