unit qdac_fmx_idle_android;
{This patch only for Delphi/C++ Builder 10.2.This is a new bug for 10.2 but not
fixed,so if you want use TIdleMessage on android for 10.2 ,please uses this unit.
Nothing need to do else.
This patch created by swish and your can share it for everyone and use it in your
production without notice to me.
}
interface
uses classes,Androidapi.JNI.Os,Androidapi.JNIBridge;
type
  TLooperIdleHandler=class(TJavaLocal,JMessageQueue_IdleHandler)
     function queueIdle: Boolean; cdecl;
  end;
implementation
uses fmx.platform,fmx.forms;
var
  _IdleHandler:JMessageQueue_IdleHandler;
{ TLooperIdleHandler }

function TLooperIdleHandler.queueIdle: Boolean;
begin
  Result:=False;
  Application.DoIdle(Result);
  Result:=true;
end;
initialization
{$IFDEF VER320}
  _IdleHandler:=TLooperIdleHandler.Create;
  TJLooper.JavaClass.getMainLooper.getQueue.addIdleHandler(_IdleHandler);
finalization
  TJLooper.JavaClass.getMainLooper.getQueue.removeIdleHandler(_IdleHandler);
  _IdleHandler:=nil;
{$ENDIF}
end.
