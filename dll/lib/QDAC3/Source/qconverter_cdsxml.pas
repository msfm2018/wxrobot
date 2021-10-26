unit qconverter_cdsxml;

interface

{
  #define szDATAPACKET "DATAPACKET"
  #define szDATA       "ROWDATA"
  #define szMETADATA   "METADATA"
  #define szFIELDS     "FIELDS"
  #define szFIELDDEF   "FIELD"
  #define szPARAMS     "PARAMS"
  #define szOPTPARAM   "PARAM"
  #define szNULL       "NULL"
  #define szROW        "ROW"
  #define szAttrFld    "ROWATTR"
  #define szROUNDTRIP  "Roundtrip"
  #define szVersion    "Version"
  #define szVersion20  "2.0"

  #define szRowState  "RowState"
  #define szAttrName  "Name"
  #define szAttrValue "Value"
  #define szAttrType  "Type"

  //Field attributes
  #define szAttrTagName   "tagname"
  #define szAttrAttrName  "attrname"
  #define szAttrFieldName "fieldname"
  #define szAttrFieldType "fieldtype"
  #define szAttrReadOnly  "readonly"
  #define szAttrHidden    "hidden"
  #define szAttrRequired  "required"
  #define szAttrLinkFld   "linkfield"

  #define szXMLInt8       "i1"
  #define szXMLInt16      "i2"
  #define szXMLInt32      "i4"
  #define szXMLInt64      "i8"
  #define szXMLUInt8      "ui1"
  #define szXMLUInt16     "ui2"
  #define szXMLUInt32     "ui4"
  #define szXMLUInt64     "ui8"
  #define szXMLSingle     "r4"
  #define szXMLFloat      "r8"
  #define szXMLFloat10    "r10"
  #define szXMLNumber     "r8"
  #define szXMLFixed      "fixed"
  #define szXMLFixedFMT   "fixedFMT"
  #define szXMLBool       "boolean"
  #define szXMLDate       "date"
  #define szXMLDateTime   "dateTime"
  #define szXMLTime       "time"
  #define szXMLArray      "array"
  #define szXMLADT        "struct"
  #define szXMLNested     "nested"
  #define szXMLStringUni  "string.uni"
  #define szXMLStringAnsi "string"
  #define szXMLBinHex     "bin.hex"
  #define szXMLIntArray   "IntArray"
  #define szXMLUIntArray  "UIntArray"
  #define szXMLSQLDateTime  "SQLdateTime"
  #define szXMLSQLDateTimeOffset "SQLdateTimeOffset"
}
uses classes, qdb, qstring, qxml;

type
  TQCDSXMLConverter = class(TQConverter)
  protected
    FXML, FRootNode, FDataRoot: TQXMLNode;
    FRowIndex: Integer;
    FFieldIndexes: TStringList;
    // 导入
    procedure BeforeImport; override;
    procedure BeginImport(AIndex: Integer); override;
    procedure LoadFieldDefs(ADefs: TQFieldDefs); override;
    function ReadRecord(ARec: TQRecord): Boolean; override;
    procedure EndImport(AIndex: Integer); override;
    procedure AfterImport; override;
    // 导出
    procedure BeforeExport; override;
    procedure BeginExport(AIndex: Integer); override;
    procedure SaveFieldDefs(ADefs: TQFieldDefs); override;
    function WriteRecord(ARec: TQRecord): Boolean; override;
    procedure EndExport(AIndex: Integer); override;
    procedure AfterExport; override;
  end;

implementation

{ TQCDSXMLConverter }

procedure TQCDSXMLConverter.AfterExport;
begin
  inherited;

end;

procedure TQCDSXMLConverter.AfterImport;
begin
  inherited;

end;

procedure TQCDSXMLConverter.BeforeExport;
begin
  inherited;

end;

procedure TQCDSXMLConverter.BeforeImport;
begin
  inherited;

end;

procedure TQCDSXMLConverter.BeginExport(AIndex: Integer);
begin
  inherited;

end;

procedure TQCDSXMLConverter.BeginImport(AIndex: Integer);
begin
  inherited;

end;

procedure TQCDSXMLConverter.EndExport(AIndex: Integer);
begin
  inherited;

end;

procedure TQCDSXMLConverter.EndImport(AIndex: Integer);
begin
  inherited;

end;

procedure TQCDSXMLConverter.LoadFieldDefs(ADefs: TQFieldDefs);
begin
  inherited;

end;

function TQCDSXMLConverter.ReadRecord(ARec: TQRecord): Boolean;
begin

end;

procedure TQCDSXMLConverter.SaveFieldDefs(ADefs: TQFieldDefs);
begin
  inherited;

end;

function TQCDSXMLConverter.WriteRecord(ARec: TQRecord): Boolean;
begin

end;

end.
