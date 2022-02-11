program Project1;

uses
  Vcl.Forms,
  utils in 'utils.pas',
  Unit2 in 'Unit2.pas' {main},
  define in 'define.pas',
  Vcl.Themes,
  Vcl.Styles;

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;

  Application.CreateForm(Tmain, main);
  Application.Run;
end.


