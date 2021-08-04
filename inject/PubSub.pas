unit PubSub;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, System.Messaging;

type
  tx = record
    bb: string;
    i: Integer;
  end;

var
  ttx: tx;

var
  message_bus: TMessageManager;

var
  SubscriptionId: Integer;

var
  MsgListener: TMessageListener;

implementation

initialization
  message_bus := TMessageManager.DefaultManager;

end.

