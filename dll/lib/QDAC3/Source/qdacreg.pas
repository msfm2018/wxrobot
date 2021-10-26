unit qdacreg;
{$I qdac.inc}

interface

uses Classes;

procedure Register;

implementation

uses qdb, qconverter_stds, qconverter_sql, qconverter_adoxml, qconverter_cdsxml,
  qconverter_fdac, qconverter_csv, qsp_zlib, qsp_aes, qprov_pgsql, qprov_sqlite;
{$R *.dcr}


procedure Register;
begin
  RegisterComponents('QDAC 3.0', [TQDataSet, TQPgSQLProvider, TQSqliteProvider,
    {$IF RTLVersion>25}TQFDBinaryConverter, TQFDJsonConverter, TQFDXMLConverter,
    {$IFEND} TQADOXMLConverter, TQCDSXMLConverter, TQBinaryConverter,
    TQMsgPackConverter, TQJsonConverter, TQTextConverter, TQCSVConverter,
    TQZlibStreamProcessor, TQAESStreamProcessor, TQMSSQLConverter,
    TQPgSQLConverter, TQMySQLConverter]);
end;

end.


end.
