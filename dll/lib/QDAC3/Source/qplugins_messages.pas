unit qplugins_messages;

interface
{$HPPEMIT '#pragma link "qplugins_messages"'}
uses windows;

const
  NAME_APPREADY = 'QPlugins.ApplicationReady';
  VCLAppClass: PWideChar = 'TApplication';
  FMXAppClass: PWideChar = 'TFMAppClass';

type
  IQMessageService = interface
    ['{95B1F426-633C-49DB-80F4-CB28B0AC7690}']
    function Accept(AInstance: HMODULE): Boolean; stdcall;
    procedure HandleMessage(var AMsg: TMsg; var AHandled: Boolean); stdcall;
    procedure HandleIdle; stdcall;
    function IsShowModal: Boolean; stdcall;
  end;

  IQHostService = interface
    ['{CBC04086-5153-497D-9E8D-245DD5BC69C9}']
    function GetAppWnd: HWND;
    function Terminating: Boolean;
    function Terminated: Boolean;
    function IsShareForm(AFormClass:Pointer): Boolean;
  end;

implementation

end.
