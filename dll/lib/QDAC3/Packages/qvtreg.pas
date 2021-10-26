unit qvtreg;

interface

uses system.classes, fmx.types, qdac_fmx_virtualtree;
procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('QDAC 3.0', [TQVirtualTreeView, TQVTCustomTextCell,
    TQVTCustomCheckCell, TQVTCustomRadioCell, TQVTCustomProgressCell,
    TQVTImageCell, TQVTImageCell, TQVTPickListCell, TQVTTextEditor,
    TQVTListEditor, TQVTColorEditor, TQVTDialogEditor,TQVTDBAdapter]);
end;

initialization

RegisterFmxClasses([TQVirtualTreeView, TQVTCustomTextCell, TQVTCustomCheckCell,
  TQVTCustomRadioCell, TQVTCustomProgressCell, TQVTImageCell, TQVTImageCell,
  TQVTPickListCell, TQVTTextEditor, TQVTListEditor, TQVTColorEditor,
  TQVTDialogEditor,TQVTDBAdapter,TQVTCustomDrawer]);

end.
