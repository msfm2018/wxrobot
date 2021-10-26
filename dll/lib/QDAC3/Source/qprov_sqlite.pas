{
  QDAC Sqlite数据库驱动支持
  作者：不得闲
  2015.10.10
  ==========
  * 初步实现Sqlite数据库的查询和基本的提交功能
  2015.10.15
  ========
  + 增加Sqlite自定义函数的支持
  * 修正查询计算列的时候列信息获取不正常的问题，以及计算列未指定列名自动添加默认列名的功能
  2015.10.19
  ========
  +增加不带sqlite3.dll的支持，如果指定了LibName，则使用指定的Sqlite3.dll引擎作为数据库引擎，
  否则使用内部自带的Sqlite3进行处理
  2015-10-20
  +增加多数据集结果查询返回
  *修正由as之后的计算列导致的提交更新问题
}
unit qprov_sqlite;

interface

{$IFDEF MSWINDOWS}
{$DEFINE MemSqlite}
{$ENDIF}

uses classes, sysutils, db, qdb, qstring, qvalue, fmtbcd{$IFDEF MSWINDOWS},
  Windows{$ENDIF}, {$IFDEF UNICODE}Generics.Collections{$ELSE}
  IniFiles{$ENDIF};

{$REGION 'Sqlite3的API接口常量'}

const
  // 类型
  SQLITE_INTEGER = 1;
  SQLITE_FLOAT = 2;
  SQLITE_TEXT = 3;
  SQLITE_BLOB = 4;
  SQLITE_NULL = 5;

  // SQLITE打开模式
  SQLITE_OPEN_READONLY = $00000001; // Ok for sqlite3_open_v2()
  SQLITE_OPEN_READWRITE = $00000002; // Ok for sqlite3_open_v2()
  SQLITE_OPEN_CREATE = $00000004; // Ok for sqlite3_open_v2()
  SQLITE_OPEN_DELETEONCLOSE = $00000008; // VFS only
  SQLITE_OPEN_EXCLUSIVE = $00000010; // VFS only
  SQLITE_OPEN_AUTOPROXY = $00000020; // VFS only
  SQLITE_OPEN_URI = $00000040; // Ok for sqlite3_open_v2()
  SQLITE_OPEN_MAIN_DB = $00000100; // VFS only
  SQLITE_OPEN_TEMP_DB = $00000200; // VFS only
  SQLITE_OPEN_TRANSIENT_DB = $00000400; // VFS only
  SQLITE_OPEN_MAIN_JOURNAL = $00000800; // VFS only
  SQLITE_OPEN_TEMP_JOURNAL = $00001000; // VFS only
  SQLITE_OPEN_SUBJOURNAL = $00002000; // VFS only
  SQLITE_OPEN_MASTER_JOURNAL = $00004000; // VFS only
  SQLITE_OPEN_NOMUTEX = $00008000; // Ok for sqlite3_open_v2()
  SQLITE_OPEN_FULLMUTEX = $00010000; // Ok for sqlite3_open_v2()
  SQLITE_OPEN_SHAREDCACHE = $00020000; // Ok for sqlite3_open_v2()
  SQLITE_OPEN_PRIVATECACHE = $00040000; // Ok for sqlite3_open_v2()
  SQLITE_OPEN_WAL = $00080000; // VFS only

  SQLITE_OK = 0; // Successful result
  SQLITE_ERROR = 1; // SQL error or missing database
  SQLITE_INTERNAL = 2; // Internal logic error in SQLite
  SQLITE_PERM = 3; // Access permission denied
  SQLITE_ABORT = 4; // Callback routine requested an abort
  SQLITE_BUSY = 5; // The database file is locked
  SQLITE_LOCKED = 6; // A table in the database is locked
  SQLITE_NOMEM = 7; // A malloc() failed
  SQLITE_READONLY = 8; // Attempt to write a readonly database
  SQLITE_INTERRUPT = 9; // Operation terminated by sqlite3_interrupt()
  SQLITE_IOERR = 10; // Some kind of disk I/O error occurred
  SQLITE_CORRUPT = 11; // The database disk image is malformed
  SQLITE_NOTFOUND = 12; // Unknown opcode in sqlite3_file_control()
  SQLITE_FULL = 13; // Insertion failed because database is full
  SQLITE_CANTOPEN = 14; // Unable to open the database file
  SQLITE_PROTOCOL = 15; // Database lock protocol error
  SQLITE_EMPTY = 16; // Database is empty
  SQLITE_SCHEMA = 17; // The database schema changed
  SQLITE_TOOBIG = 18; // String or BLOB exceeds size limit
  SQLITE_CONSTRAINT = 19; // Abort due to constraint violation
  SQLITE_MISMATCH = 20; // Data type mismatch
  SQLITE_MISUSE = 21; // Library used incorrectly
  SQLITE_NOLFS = 22; // Uses OS features not supported on host
  SQLITE_AUTH = 23; // Authorization denied
  SQLITE_FORMAT = 24; // Auxiliary database format error
  SQLITE_RANGE = 25; // 2nd parameter to sqlite3_bind out of range
  SQLITE_NOTADB = 26; // File opened that is not a database file
  SQLITE_ROW = 100; // sqlite3_step() has another row ready
  SQLITE_DONE = 101; // sqlite3_step() has finished executing

  SQLITE_STATIC = 0; // 用在绑定，表示常量
  SQLITE_TRANSIENT = -1; // 用在绑定，表示会拷贝一份

  // sqlite3_create_function创建的函数中传递的参数类型编码eTextRep
  SQLITE_UTF8 = 1;
  SQLITE_UTF16 = 2;
  SQLITE_UTF16BE = 3;
  SQLITE_UTF16LE = 4;
  SQLITE_ANY = 5;
{$IF DEFINED(MSWINDOWS)}
  SQLiteDLL = 'sqlite3.dll';
{$ELSEIF DEFINED(ANDROID)}
  SQLiteDLL = 'sqlite3.so';
{$ELSEIF DEFINED(OSX) or DEFINED(IOS)}
  SQLiteDLL = 'sqlite3.dylib';
{$IFEND}

type
  TSqlite3 = Pointer;
  PSqlite3 = ^TSqlite3;
  Sqlite3_value = Pointer;
  PSqlite3_value = ^Sqlite3_value;
  Psqlite3_stmt = Pointer;
  PSqlite3_context = Pointer;

  PPSqlite3_value = ^PSqlite3_value;

  TSqlite3ExecCallback = function(Param: Pointer; NumCols: Integer;
    ColTextStrs: PPChar; ColNameStrs: PPQCharA): Integer; cdecl;

  Tsqlite3_func_callback = procedure(context: PSqlite3_context; nargs: Integer;
    args: PPSqlite3_value); cdecl;
  Tsqlite3_step_callback = Tsqlite3_func_callback;
  Tsqlite3_final_callback = procedure(context: PSqlite3_context); cdecl;
  TSqlite3_destroy_callBack = procedure(Data: Pointer); cdecl;

  TBindDestructor = procedure(Ptr: Pointer); cdecl;
{$ENDREGION}

type
  TQSqliteProvider = class;
  TQSqliteFunction = class;
  TOnSqliteFuncExec = procedure(Func: TQSqliteFunction;
    Params: array of TQValue; var result: TQValue) of object;

  // Sqlite函数
  TQSqliteFunction = class(TCollectionItem)
  private
    FIsAggregateFunc: Boolean;
    FFuncName: string;
    FArgCount: Integer;
    FOnExecute: TOnSqliteFuncExec;
    procedure SetFuncName(const Value: string);
    procedure SetIsAggregateFunc(const Value: Boolean);
    procedure SetArgCount(const Value: Integer);
  protected
    procedure Execute(context: PSqlite3_context; nargs: Integer;
      args: PPSqlite3_value); virtual;
  public
    constructor Create(Collection: TCollection); override;
    procedure Reset; // 重置
  published
    property IsAggregateFunc: Boolean read FIsAggregateFunc
      write SetIsAggregateFunc default False; // 是否是聚合函数
    property FuncName: string read FFuncName write SetFuncName;
    property ArgCount: Integer read FArgCount write SetArgCount; // 参数个数
    procedure Install;
    procedure UnInstall;
    property OnExecute: TOnSqliteFuncExec read FOnExecute write FOnExecute;
  end;

  TQSqliteFunctions = class(TCollection)
  private
    FProvider: TQSqliteProvider;
    function GetFunction(Index: Integer): TQSqliteFunction;
    procedure SetFunction(Index: Integer; Value: TQSqliteFunction);
  public
    procedure InstallFuncs; // 注册函数
    function Add: TQSqliteFunction;
    property Items[Index: Integer]: TQSqliteFunction read GetFunction
      write SetFunction; default;
  end;

  TQSqliteProvider = class(TQLibProvider)
  private
    FUseMemSqlite: Boolean;
    // sqlite3_open和sqlite3_open_v2中的fileName必须传递UTF8编码
{$REGION 'Sqlite3的API接口函数'}
    sqlite3_open: function(filename: PQCharA; var pDb: PSqlite3)
      : Integer; cdecl;
    sqlite3_open16: function(filename: PWideChar; var pDb: PSqlite3)
      : Integer; cdecl;
    sqlite3_open_v2: function(filename: PQCharA; var pDb: PSqlite3;
      flags: Integer; zVfs: PQCharA): Integer; cdecl;
    sqlite3_exec: function(pDb: PSqlite3; sql: PQCharA;
      Callback: TSqlite3ExecCallback; CallbackArg: Pointer; ErrMsg: PPQCharA)
      : Integer; cdecl;
    sqlite3_errmsg: function(db: PSqlite3): PQCharA; cdecl;
    sqlite3_errmsg16: function(db: PSqlite3): PWideChar; cdecl;

    sqlite3_prepare: function(db: PSqlite3; zSql: PQCharA; nByte: Integer;
      var ppStmt: Psqlite3_stmt; out pzTail: PQCharA): Integer; cdecl;
    sqlite3_prepare_v2: function(db: PSqlite3; zSql: PQCharA; nByte: Integer;
      var ppStmt: Psqlite3_stmt; out pzTail: PQCharA): Integer; cdecl;
    sqlite3_prepare16: function(db: PSqlite3; zSql: PWideChar; nByte: Integer;
      var ppStmt: Psqlite3_stmt; out pzTail: PWideChar): Integer; cdecl;
    sqlite3_prepare16_v2: function(db: PSqlite3; zSql: PWideChar;
      nByte: Integer; var ppStmt: Psqlite3_stmt; out pzTail: PWideChar)
      : Integer; cdecl;
    sqlite3_table_column_metadata: function(db: PSqlite3;
      DbName, TableName, zColumnName: PQCharA; var DataType, CollSeq: PQCharA;
      var NotNull, PrimaryKey, Autoinc: Integer): Integer; cdecl;

    sqlite3_key: function(db: PSqlite3; key: PQCharA; nKey: Integer)
      : Integer; cdecl;
    sqlite3_rekey: function(db: PSqlite3; key: PQCharA; nKey: Integer)
      : Integer; cdecl;

    // Sqlite3Value相应函数
    sqlite3_value_blob: function(Value: PSqlite3_value): Pointer; cdecl;
    sqlite3_value_bytes: function(Value: PSqlite3_value): Integer; cdecl;
    sqlite3_value_bytes16: function(Value: PSqlite3_value): Integer; cdecl;
    sqlite3_value_double: function(Value: PSqlite3_value): Double; cdecl;
    sqlite3_value_int: function(Value: PSqlite3_value): Integer; cdecl;
    sqlite3_value_int64: function(Value: PSqlite3_value): int64; cdecl;
    sqlite3_value_text16: function(Value: PSqlite3_value): PByte; cdecl;
    sqlite3_value_text16le: function(Value: PSqlite3_value): PByte; cdecl;
    sqlite3_value_text16be: function(Value: PSqlite3_value): PByte; cdecl;
    sqlite3_value_type: function(Value: PSqlite3_value): Integer; cdecl;
    sqlite3_value_numeric_type: function(Value: PSqlite3_value): Integer; cdecl;

    // Sqlite3结果返回
    sqlite3_result_blob: procedure(context: PSqlite3_context; Value: Pointer;
      nBytes: Integer; destr: TSqlite3_destroy_callBack); cdecl;
    sqlite3_result_blob64: procedure(context: PSqlite3_context; Value: Pointer;
      nBytes: int64; destr: TSqlite3_destroy_callBack); cdecl;
    sqlite3_result_double: procedure(context: PSqlite3_context;
      Value: Double); cdecl;
    sqlite3_result_error16: procedure(context: PSqlite3_context; msg: PByte;
      nBytes: Integer); cdecl;
    sqlite3_result_error_code: procedure(context: PSqlite3_context;
      code: Integer); cdecl;
    sqlite3_result_int64: procedure(context: PSqlite3_context;
      Value: int64); cdecl;
    sqlite3_result_null: procedure(context: PSqlite3_context); cdecl;
    sqlite3_result_text16: procedure(context: PSqlite3_context; Value: PByte;
      nBytes: Integer; destr: TSqlite3_destroy_callBack); cdecl;
    sqlite3_result_text64: procedure(context: PSqlite3_context; Value: PByte;
      nBytes: int64; destr: TSqlite3_destroy_callBack; encoding: Byte); cdecl;
    sqlite3_result_zeroblob: procedure(context: PSqlite3_context;
      n: Integer); cdecl;
    sqlite3_result_value: procedure(context: PSqlite3_context;
      Value: PSqlite3_value); cdecl;

    sqlite3_column_count: function(stmt: Psqlite3_stmt): Integer; cdecl;
    sqlite3_column_name: function(stmt: Psqlite3_stmt; n: Integer)
      : PQCharA; cdecl;
    sqlite3_column_name16: function(stmt: Psqlite3_stmt; n: Integer)
      : PWideChar; cdecl;
    sqlite3_column_database_name: function(stmt: Psqlite3_stmt;
      ColumnNum: Integer): PQCharA; cdecl;
    sqlite3_column_database_name16: function(stmt: Psqlite3_stmt;
      ColumnNum: Integer): PWideChar; cdecl;
    sqlite3_column_table_name: function(stmt: Psqlite3_stmt; ColumnNum: Integer)
      : PQCharA; cdecl;
    sqlite3_column_table_name16: function(stmt: Psqlite3_stmt;
      ColumnNum: Integer): PWideChar; cdecl;
    sqlite3_column_origin_name: function(stmt: Psqlite3_stmt;
      ColumnNum: Integer): PQCharA; cdecl;
    sqlite3_column_origin_name16: function(stmt: Psqlite3_stmt;
      ColumnNum: Integer): PChar; cdecl;
    sqlite3_column_decltype: function(stmt: Psqlite3_stmt; ColumnNum: Integer)
      : PQCharA; cdecl;
    sqlite3_column_decltype16: function(stmt: Psqlite3_stmt; ColumnNum: Integer)
      : PWideChar; cdecl;
    sqlite3_column_blob: function(stmt: Psqlite3_stmt; iCol: Integer)
      : Pointer; cdecl;
    sqlite3_column_bytes: function(stmt: Psqlite3_stmt; iCol: Integer)
      : Integer; cdecl;
    sqlite3_column_bytes16: function(stmt: Psqlite3_stmt; iCol: Integer)
      : Integer; cdecl;
    sqlite3_column_double: function(stmt: Psqlite3_stmt; iCol: Integer)
      : Double; cdecl;
    sqlite3_column_int: function(stmt: Psqlite3_stmt; iCol: Integer)
      : Integer; cdecl;
    sqlite3_column_int64: function(stmt: Psqlite3_stmt; iCol: Integer)
      : int64; cdecl;
    sqlite3_column_text: function(stmt: Psqlite3_stmt; iCol: Integer)
      : PQCharA; cdecl;
    sqlite3_column_text16: function(stmt: Psqlite3_stmt; iCol: Integer)
      : PWideChar; cdecl;
    sqlite3_column_type: function(stmt: Psqlite3_stmt; iCol: Integer)
      : Integer; cdecl;
    sqlite3_column_value: function(stmt: Psqlite3_stmt; iCol: Integer)
      : Sqlite3_value; cdecl;
    sqlite3_finalize: function(pStmt: Psqlite3_stmt): Integer; cdecl;
    sqlite3_reset: function(pStmt: Psqlite3_stmt): Integer; cdecl;

    sqlite3_create_function: function(db: PSqlite3; zFunctionName: PQCharA;
      nArg: Integer; eTextRep: Integer; pApp: Pointer;
      xFunc: Tsqlite3_func_callback; xStep: Tsqlite3_step_callback;
      xFinal: Tsqlite3_final_callback): Integer; cdecl;
    sqlite3_create_function16: function(db: PSqlite3; zFunctionName: PByte;
      nArg: Integer; eTextRep: Integer; pApp: Pointer;
      xFunc: Tsqlite3_func_callback; xStep: Tsqlite3_step_callback;
      xFinal: Tsqlite3_final_callback): Integer; cdecl;

    sqlite3_create_function_v2: function(db: PSqlite3; zFunctionName: PQCharA;
      nArg: Integer; eTextRep: Integer; pApp: Pointer;
      xFunc: Tsqlite3_func_callback; xStep: Tsqlite3_step_callback;
      xFinal: Tsqlite3_final_callback; xdestroy: TSqlite3_destroy_callBack)
      : Integer; cdecl;

    // 参数绑定函数
    sqlite3_bind_blob: function(Statement: Psqlite3_stmt; Index: Integer;
      Value: Pointer; n: Integer; Proc: TBindDestructor): Integer; cdecl;
    sqlite3_bind_double: function(Statement: Psqlite3_stmt; Index: Integer;
      Value: Double): Integer; cdecl;
    sqlite3_bind_int: function(pStmt: Psqlite3_stmt; Index: Integer;
      Value: Integer): Integer; cdecl;
    sqlite3_bind_int64: function(pStmt: Psqlite3_stmt; Index: Integer;
      Value: int64): Integer; cdecl;
    sqlite3_bind_null: function(pStmt: Psqlite3_stmt; Index: Integer)
      : Integer; cdecl;
    sqlite3_bind_text: function(pStmt: Psqlite3_stmt; Index: Integer;
      Value: PQCharA; n: Integer; Proc: TBindDestructor): Integer; cdecl;
    sqlite3_bind_text16: function(pStmt: Psqlite3_stmt; Index: Integer;
      Value: PWideChar; n: Integer; Proc: TBindDestructor): Integer; cdecl;
    sqlite3_bind_value: function(pStmt: Psqlite3_stmt; Index: Integer;
      Value: Sqlite3_value): Integer; cdecl;
    sqlite3_bind_zeroblob: function(pStmt: Psqlite3_stmt; Index, n: Integer)
      : Integer; cdecl;
    sqlite3_bind_parameter_count: function(pStmt: Psqlite3_stmt)
      : Integer; cdecl;
    sqlite3_bind_parameter_name: function(pStmt: Psqlite3_stmt;
      ParamNum: Integer): PQCharA; cdecl;
    sqlite3_bind_parameter_index: function(pStmt: Psqlite3_stmt; zName: PQCharA)
      : Integer; cdecl;

    sqlite3_step: function(pStmt: Psqlite3_stmt): Integer; cdecl;
    sqlite3_data_count: function(pStmt: Psqlite3_stmt): Integer; cdecl;

    sqlite3_close: function(pDb: PSqlite3): Integer; cdecl;
    sqlite3_free: procedure(APtr: Pointer); cdecl;
{$ENDREGION}
  private
    FDbName: string;
    FReadOnly: Boolean;
    FFunctions: TQSqliteFunctions;
    procedure SetDbName(const Value: string);
    procedure SetReadOnly(const Value: Boolean);
    procedure SetFunctions(const Value: TQSqliteFunctions);
  protected
    FSqlite3: PSqlite3;
    function FieldDataType(ExtDataType: Integer): TFieldType;
    procedure LoadEntries; override;
{$IFDEF MemSqlite}
    procedure InitStaticFuncs;
{$ENDIF}
    procedure CloseHandle(AHandle: THandle); override;
    procedure UnLoad; override;
    procedure InternalOpen; override;
    procedure InternalClose; override;
    function InternalExecute(var ARequest: TQSQLRequest): Boolean; override;
    procedure InternalApplyChanges(AFields: TFieldDefs;
      ARecords: TQRecords); override;
    procedure Check(rcd: Integer);
    procedure InitFieldDescs; override;
    procedure OpenNextSqlDataSet(var NextSql: PQCharA; AttachDs: TQDataSet);
    procedure PrepareSql(sql: QStringW; var pStmt: Psqlite3_stmt;
      var NextSql: PQCharA);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function BeginTrans(ALevel: TQDBIsolationLevel = dilUnspecified;
      ASavePointName: QStringW = ''): Boolean; override;
    procedure CommitTrans; override; // 提交事务
    function TableExists(ATableName: QStringW): Boolean; override;
    function ViewExists(AName: QStringW): Boolean; override;
    function FunctionExists(AName: QStringW): Boolean; override;
    function ProcedureExists(AName: QStringW): Boolean; override;
    function TriggerExists(AName: QStringW): Boolean; override;
    function ColumnExists(ATableName, AColName: QStringW): Boolean; override;
    function RecordExists(ACmdText: QStringW): Boolean; override;
    procedure RollbackTrans(ASavePointName: QStringW = ''); override;
    procedure RestDbPassword(NewPwd: string); // 重新设置Sqlite密码
  published
    property LibName;
    property DbName: string read FDbName write SetDbName;
    property ReadOnly: Boolean read FReadOnly write SetReadOnly;
    property Functions: TQSqliteFunctions read FFunctions write SetFunctions;
  end;

implementation

{$IFDEF MemSqlite}

uses SqliteMemInfo;
{$ENDIF}

const
  SqliteInFunctions: array [0 .. 32] of string = ('abs', 'max', 'min', 'random',
    'round', 'length', 'lower', 'upper', 'substr', 'randstr', 'quote', 'like',
    'glob', 'total', 'sum', 'coalesce', 'ifnull', 'nullif', 'avg', 'count',
    'typeof', 'last_insert_rowid', 'like', 'soundex', 'sqlite_version',
    'change_count', 'last_statement_change_count', 'datetime', 'date', 'time',
    'strftime', 'now', 'julianday');

var
  SqliteTypes:
{$IFDEF UNICODE}TDictionary<string, Cardinal>{$ELSE}THashedStringList{$ENDIF};

procedure InitSqliteTypes;
  procedure AddSqliteType(typeName: string; DType: Cardinal);
  begin
{$IFDEF UNICODE}
    SqliteTypes.AddOrSetValue(UpperCase(typeName), DType);
{$ELSE}
    SqliteTypes.AddObject(UpperCase(typeName), Pointer(DType));
{$ENDIF}
  end;

begin
{$IFDEF UNICODE}
  SqliteTypes := TDictionary<string, Cardinal>.Create;
{$ELSE}
  SqliteTypes := THashedStringList.Create;
{$ENDIF};
  AddSqliteType('BIGINT', SQL_INT64);
  AddSqliteType('INT64', SQL_INT64);
  AddSqliteType('Largetint', SQL_INT64);
  AddSqliteType('Word', SQL_WORD);
  AddSqliteType('Smallint', SQL_SMALLINT);
  AddSqliteType('bit', SQL_BOOLEAN);
  AddSqliteType('BOOLEAN', SQL_BOOLEAN);
  AddSqliteType('Bool', SQL_BOOLEAN);
  AddSqliteType('INT', SQL_INTEGER);
  AddSqliteType('integer', SQL_INTEGER);
  AddSqliteType('MONEY', SQL_MONEY);
  AddSqliteType('SMALLMONEY', SQL_MONEY);
  AddSqliteType('NUMERIC', SQL_EXTENDED);
  AddSqliteType('CURRENCY', SQL_MONEY);
  AddSqliteType('DOUBLE', SQL_FLOAT);
  AddSqliteType('REAL', SQL_MONEY);
  AddSqliteType('TIME', SQL_TIME);
  AddSqliteType('TIMESTAMP', SQL_TIMESTAMP);
  AddSqliteType('FLOAT', SQL_FLOAT);
  AddSqliteType('DATE', SQL_DATE);
  AddSqliteType('DATETIME', SQL_DATETIME);
  AddSqliteType('CHAR', SQL_CHAR);
  AddSqliteType('NCHAR', SQL_WIDECHAR);
  AddSqliteType('VARCHAR', SQL_VARCHAR);
  AddSqliteType('VARCHAR2', SQL_VARCHAR);
  AddSqliteType('NVARCHAR', SQL_WIDEVARCHAR);
  AddSqliteType('NVARCHAR2', SQL_WIDEVARCHAR);
  AddSqliteType('text', SQL_TEXT);
  AddSqliteType('Ntext', SQL_WIDETEXT);
  AddSqliteType('VARBINARY', SQL_VARBINARY);
  AddSqliteType('PICTURE', SQL_PICTURE);
  AddSqliteType('GRAPHIC', SQL_PICTURE);
  AddSqliteType('GUID', SQL_GUID);
  AddSqliteType('BINARY', SQL_BINARY);
  AddSqliteType('BLOB', SQL_OLE);
  AddSqliteType('IMAGE', SQL_BINARY);
end;

function GetDbType(tpName: string): Cardinal;
{$IFNDEF UNICODE}
var
  idx: Integer;
{$ENDIF}
begin
{$IFDEF UNICODE}
  if not SqliteTypes.TryGetValue(UpperCase(tpName), result) then
    result := SQL_UNKNOWN
{$ELSE}
  idx := SqliteTypes.indexof(UpperCase(tpName));
  if idx = -1 then
    result := SQL_UNKNOWN
  else
    result := Cardinal(SqliteTypes.Objects[idx]);
{$ENDIF};
end;

function Sqlite3ExecCallback(Param: Pointer; NumCols: Integer;
  ColTextStrs: PPChar; ColNameStrs: PPQCharA): Integer; cdecl;
var
  provider: TQSqliteProvider;
  i: Integer;
  AName: PQCharA;
  (* procedure AddFieldDef;
    var
    ADef: TQFieldDef;
    nColType: Integer;
    ft: TFieldType;
    sColName, sSqlType: string;
    m: PWideChar;
    begin
    ADef := provider.FActiveFieldDefs.AddFieldDef as TQFieldDef;
    sColName := qstring.Utf8Decode(StrPas(AName));
    ADef.Name := sColName;
    ADef.DataType := ftString;
    ADef.Size := 100;
    { sSqlType := qstring.Utf8Decode(provider.sqlite3_column_decltype16(provider.FSqlite3,i));
    if Assigned(provider.sqlite3_column_type) then

    nColType := provider.sqlite3_column_type(provider.FSqlite3,i);
    ft := provider.FieldDataType(nColType);
    case ft of
    ftUnknown: DatabaseErrorFmt( 'Field ''%s'' is of an unsupported type', [sColName]);
    ftInteger:
    begin

    end;
    end; }
    end; *)

begin
  provider := Param;
  case provider.FActiveRequest^.Command.Action of
    caPrepare:
      ;
    caExecute:
      ;
    caFetchStream, caFetchRecords:
      begin
        provider.FActiveRequest.result.Statics.AffectRows := 0;
        if Assigned(provider.FActiveFieldDefs) then
        begin
          provider.FActiveFieldDefs.BeginUpdate;
          try
            provider.FActiveFieldDefs.Clear;
            for i := 0 to NumCols - 1 do
            begin
              AName := PPQCharA(NativeUInt(ColNameStrs) +
                SizeOf(NativeUInt) * i)^;
              // AddFieldDef; // 使用sqlite3_exec的不能获得列类型，列数据等信息，所以，默认都作为String
            end;
          finally
            provider.FActiveFieldDefs.EndUpdate;
          end;
        end;
      end;
  end;
  result := SQLITE_OK;
end;

{ TQSqliteProvider }
function TQSqliteProvider.BeginTrans(ALevel: TQDBIsolationLevel;
  ASavePointName: QStringW): Boolean;
var
  ErrMsg: PPQCharA;
  rc: Integer;
  pStmt: Psqlite3_stmt;
  NextSql: PQCharA;
begin
  ErrMsg := nil;
  if Assigned(sqlite3_exec) then
    rc := sqlite3_exec(FSqlite3, PQCharA(qstring.Utf8Encode('begin transaction')
      ), nil, nil, ErrMsg)
  else
  begin
    PrepareSql('begin transaction', pStmt, NextSql);
    rc := sqlite3_step(pStmt);
    sqlite3_finalize(pStmt);
  end;
  Check(rc);
  result := rc = SQLITE_OK;
  if ErrMsg <> nil then
    sqlite3_free(ErrMsg);
end;

procedure TQSqliteProvider.Check(rcd: Integer);
var
  szMsg: {$IFDEF Unicode}PWideChar{$ELSE}PQCharA{$ENDIF};
begin
  if rcd in [SQLITE_OK, SQLITE_DONE, SQLITE_ROW, SQLITE_BUSY] then
    Exit;
{$IFDEF Unicode}
  szMsg := sqlite3_errmsg16(FSqlite3);
  raise Exception.Create('发生错误：' + StrPas(szMsg));
{$ELSE}
  szMsg := sqlite3_errmsg(FSqlite3);
  raise Exception.Create('发生错误：' + qstring.Utf8Decode(szMsg));
{$ENDIF}
end;

procedure TQSqliteProvider.CloseHandle(AHandle: THandle);
begin
  sqlite3_finalize(Psqlite3_stmt(AHandle));
end;

function TQSqliteProvider.ColumnExists(ATableName, AColName: QStringW): Boolean;
var
  NullParam: PQCharA;
  IntNull: Integer;
begin
  NullParam := nil;
  IntNull := 0;
  result := sqlite3_table_column_metadata(FSqlite3, nil,
    PQCharA(qstring.Utf8Encode(ATableName)),
    PQCharA(qstring.Utf8Encode(AColName)), NullParam, NullParam, IntNull,
    IntNull, IntNull) = SQLITE_OK;
end;

procedure TQSqliteProvider.CommitTrans;
var
  ErrMsg: PPQCharA;
  pStmt: Psqlite3_stmt;
  rc: Integer;
  NextSql: PQCharA;
begin
  ErrMsg := nil;
  if Assigned(sqlite3_exec) then
  begin
    Check(sqlite3_exec(FSqlite3,
      PQCharA(qstring.Utf8Encode('commit transaction')), nil, nil, ErrMsg));
    if ErrMsg <> nil then
    begin
      sqlite3_free(ErrMsg);
    end;
  end
  else
  begin
    PrepareSql('commit transaction', pStmt, NextSql);
    rc := sqlite3_step(pStmt);
    sqlite3_finalize(pStmt);
    Check(rc);
  end;
end;

constructor TQSqliteProvider.Create(AOwner: TComponent);
begin
  inherited;
  FFunctions := TQSqliteFunctions.Create(TQSqliteFunction);
  FFunctions.FProvider := self;
end;

destructor TQSqliteProvider.Destroy;
begin
  FFunctions.Free;
  inherited;
end;

function TQSqliteProvider.FieldDataType(ExtDataType: Integer): TFieldType;
begin
  case ExtDataType of
    SQLITE_INTEGER:
      result := ftInteger;
    SQLITE_FLOAT:
      result := ftFloat;
    SQLITE_TEXT:
      result := ftString;
    SQLITE_BLOB:
      result := ftBlob;
    SQLITE_NULL:
      result := ftUnknown;
  else
    result := ftString;
  end;
end;

function TQSqliteProvider.FunctionExists(AName: QStringW): Boolean;
var
  i: Integer;
begin
  result := False;
  for i := 0 to FFunctions.Count - 1 do
  begin
    if CompareText(FFunctions.Items[i].FuncName, AName) = 0 then
    begin
      result := True;
      Exit;
    end;
  end;
  for i := Low(SqliteInFunctions) to High(SqliteInFunctions) do
  begin
    if CompareText(AName, SqliteInFunctions[i]) = 0 then
    begin
      result := True;
      Break;
    end;
  end;
end;

procedure TQSqliteProvider.InitFieldDescs;
var
  Ds: TQDataSet;
  clmCount, nColType, FSize: Integer;
  iNum, i, precision: Integer;
  clmName, sqlTypeString, tmptypString: QStringW;
  psqlType: PQCharW;
  ADef: TQFieldDef;
  CurIsFixed: Boolean;
  DataType, CollSeq: PQCharA;
  NotNull, PrimaryKey, Autoinc: Integer;
const
  StartStr: PWideChar = '(';
  StopStr: PWideChar = ')';
  Delimiter: PWideChar = ',';
  NullChar: WideChar = #0;
begin
  Ds := TQDataSet(FActiveRequest.Command.DataObject);
  if Ds.RecordsetCount > 0 then
    Ds := Ds.Recordsets[Ds.RecordsetCount - 1];
  clmCount := sqlite3_column_count(Psqlite3_stmt(Ds.Handle));
  FActiveRequest.Command.Prepared := clmCount > 0;
  if not FActiveRequest.Command.Prepared then
    Exit;
  nColType := SQL_UNKNOWN;
  FActiveFieldDefs.BeginUpdate;
  try
    FActiveFieldDefs.Clear;
    iNum := 0;
    for i := 0 to clmCount - 1 do
    begin
      FSize := 0;
      precision := 0;
      psqlType := sqlite3_column_decltype16(Psqlite3_stmt(Ds.Handle), i);
      sqlTypeString := psqlType;
      clmName := sqlite3_column_name16(Psqlite3_stmt(Ds.Handle), i);
      CurIsFixed := False;
      // sqlite3_column_table_name16: function(stmt: Psqlite3_stmt; ColumnNum: Integer): PWideChar; cdecl;
      // nColType := sqlite3_column_type(Psqlite3_stmt(Ds.Handle), i);
      if sqlTypeString = '' then // 是计算列
      begin
        if PosW('(', clmName, True) <> 0 then // 无列名指定
        begin
          Inc(iNum);
          clmName := 'unknownCol' + inttostr(iNum);
        end;
        CurIsFixed := True;
      end
      else if qstring.PosW('(', sqlTypeString, True) <> 0 then
      begin
        tmptypString := qstring.DecodeTokenW(sqlTypeString, StartStr, NullChar,
          True, True);
        nColType := GetDbType(tmptypString);
        if qstring.PosW(',', sqlTypeString, True) <> 0 then
        begin
          sqlTypeString := qstring.StrBetween(psqlType, '(', ')', True);
          FSize := StrToInt(qstring.DecodeTokenW(sqlTypeString, Delimiter,
            NullChar, True, True));
          FSize := 0;
          precision := StrToInt(sqlTypeString);
        end
        else
        begin
          sqlTypeString := qstring.StrBetween(psqlType, '(', ')', True);
          FSize := StrToInt(sqlTypeString);
        end;
      end
      else
      begin
        nColType := GetDbType(sqlTypeString);
        if nColType = SQL_UNKNOWN then
        begin
          DatabaseErrorFmt('字段 ''%s''映射了一个未知的数据类型', [clmName]);
        end;
      end;
      ADef := FActiveFieldDefs.AddFieldDef as TQFieldDef;
      ADef.Name := clmName;
      ADef.BaseName := clmName;
      ADef.IsCalc := CurIsFixed;
      if not ADef.IsCalc then
      begin
        ADef.Table := sqlite3_column_table_name16(Psqlite3_stmt(Ds.Handle), i);
        // 判断
        ADef.Database := sqlite3_column_database_name16
          (Psqlite3_stmt(Ds.Handle), i);
        sqlite3_table_column_metadata(FSqlite3,
          PQCharA(qstring.Utf8Encode(ADef.Database)),
          PQCharA(qstring.Utf8Encode(ADef.Table)),
          PQCharA(qstring.Utf8Encode(clmName)), DataType, CollSeq, NotNull,
          PrimaryKey, Autoinc);
        ADef.IsPrimary := PrimaryKey = 1;
        ADef.Nullable := NotNull = 0;
        ADef.IsAutoInc := Autoinc = 1;
      end
      else
        ADef.InWhere := False;
      ADef.DBType := nColType;

      if precision <> 0 then
        ADef.precision := precision;
      if FSize <> 0 then
        ADef.Size := FSize;
    end;
  finally
    FActiveFieldDefs.EndUpdate;
  end;
end;

{$IFDEF MemSqlite}

procedure TQSqliteProvider.InitStaticFuncs;
begin
  @sqlite3_open := @SqliteMemInfo.Fsqlite3_open;
  @sqlite3_open_v2 := @SqliteMemInfo.Fsqlite3_open_v2;
  @sqlite3_open16 := @SqliteMemInfo.Fsqlite3_open16;

  @sqlite3_exec := @SqliteMemInfo.Fsqlite3_exec;
  @sqlite3_errmsg := @SqliteMemInfo.Fsqlite3_errmsg;
  @sqlite3_errmsg16 := @SqliteMemInfo.Fsqlite3_errmsg16;

  @sqlite3_close := @SqliteMemInfo.Fsqlite3_close;
  @sqlite3_free := @SqliteMemInfo.Fsqlite3_free;

  @sqlite3_column_count := @SqliteMemInfo.Fsqlite3_column_count;
  @sqlite3_column_name := @SqliteMemInfo.Fsqlite3_column_name;
  @sqlite3_column_name16 := @SqliteMemInfo.Fsqlite3_column_name16;
  @sqlite3_column_database_name := @SqliteMemInfo.Fsqlite3_column_database_name;
  @sqlite3_column_database_name16 :=
    @SqliteMemInfo.Fsqlite3_column_database_name16;
  @sqlite3_column_table_name := @SqliteMemInfo.Fsqlite3_column_table_name;
  @sqlite3_column_table_name16 := @SqliteMemInfo.Fsqlite3_column_table_name16;

  @sqlite3_column_origin_name := @SqliteMemInfo.Fsqlite3_column_origin_name;
  @sqlite3_column_origin_name16 := @SqliteMemInfo.Fsqlite3_column_origin_name16;
  @sqlite3_column_decltype := @SqliteMemInfo.Fsqlite3_column_decltype;
  @sqlite3_column_decltype16 := @SqliteMemInfo.Fsqlite3_column_decltype16;
  @sqlite3_column_blob := @SqliteMemInfo.Fsqlite3_column_blob;
  @sqlite3_column_bytes := @SqliteMemInfo.Fsqlite3_column_bytes;
  @sqlite3_column_bytes16 := @SqliteMemInfo.Fsqlite3_column_bytes16;
  @sqlite3_column_double := @SqliteMemInfo.Fsqlite3_column_double;
  @sqlite3_column_int := @SqliteMemInfo.Fsqlite3_column_int;
  @sqlite3_column_int64 := @SqliteMemInfo.Fsqlite3_column_int64;
  @sqlite3_column_text := @SqliteMemInfo.Fsqlite3_column_text;
  @sqlite3_column_text16 := @SqliteMemInfo.Fsqlite3_column_text16;
  @sqlite3_column_type := @SqliteMemInfo.Fsqlite3_column_type;
  @sqlite3_column_value := @SqliteMemInfo.Fsqlite3_column_value;
  @sqlite3_finalize := @SqliteMemInfo.Fsqlite3_finalize;
  @sqlite3_reset := @SqliteMemInfo.Fsqlite3_reset;

  @sqlite3_create_function := @SqliteMemInfo.Fsqlite3_create_function;
  @sqlite3_create_function16 := @SqliteMemInfo.Fsqlite3_create_function16;
  @sqlite3_create_function_v2 := @SqliteMemInfo.Fsqlite3_create_function_v2;

  @sqlite3_prepare := @SqliteMemInfo.Fsqlite3_prepare;
  @sqlite3_prepare_v2 := @SqliteMemInfo.Fsqlite3_prepare_v2;
  @sqlite3_prepare16 := @SqliteMemInfo.Fsqlite3_prepare16;
  @sqlite3_prepare16_v2 := @SqliteMemInfo.Fsqlite3_prepare16_v2;
  @sqlite3_table_column_metadata :=
    @SqliteMemInfo.Fsqlite3_table_column_metadata;
  @sqlite3_key := @SqliteMemInfo.Fsqlite3_key;
  @sqlite3_rekey := @SqliteMemInfo.Fsqlite3_rekey;

  @sqlite3_value_blob := @SqliteMemInfo.Fsqlite3_value_blob;
  @sqlite3_value_bytes := @SqliteMemInfo.Fsqlite3_value_bytes;
  @sqlite3_value_bytes16 := @SqliteMemInfo.Fsqlite3_value_bytes16;
  @sqlite3_value_double := @SqliteMemInfo.Fsqlite3_value_double;
  @sqlite3_value_int := @SqliteMemInfo.Fsqlite3_value_int;
  @sqlite3_value_int64 := @SqliteMemInfo.Fsqlite3_value_int64;
  @sqlite3_value_text16 := @SqliteMemInfo.Fsqlite3_value_text16;
  @sqlite3_value_text16le := @SqliteMemInfo.Fsqlite3_value_text16le;
  @sqlite3_value_text16be := @SqliteMemInfo.Fsqlite3_value_text16be;
  @sqlite3_value_type := @SqliteMemInfo.Fsqlite3_value_type;
  @sqlite3_value_numeric_type := @SqliteMemInfo.Fsqlite3_value_numeric_type;

  @sqlite3_result_blob := @SqliteMemInfo.Fsqlite3_result_blob;
  @sqlite3_result_blob64 := @SqliteMemInfo.Fsqlite3_result_blob64;
  @sqlite3_result_double := @SqliteMemInfo.Fsqlite3_result_double;
  @sqlite3_result_error16 := @SqliteMemInfo.Fsqlite3_result_error16;
  @sqlite3_result_error_code := @SqliteMemInfo.Fsqlite3_result_error_code;
  @sqlite3_result_int64 := @SqliteMemInfo.Fsqlite3_result_int64;
  @sqlite3_result_null := @SqliteMemInfo.Fsqlite3_result_null;
  @sqlite3_result_text16 := @SqliteMemInfo.Fsqlite3_result_text16;
  @sqlite3_result_text64 := @SqliteMemInfo.Fsqlite3_result_text64;
  @sqlite3_result_zeroblob := @SqliteMemInfo.Fsqlite3_result_zeroblob;
  @sqlite3_result_value := @SqliteMemInfo.Fsqlite3_result_value;

  @sqlite3_bind_blob := @SqliteMemInfo.Fsqlite3_bind_blob;
  @sqlite3_bind_double := @SqliteMemInfo.Fsqlite3_bind_double;
  @sqlite3_bind_int := @SqliteMemInfo.Fsqlite3_bind_int;
  @sqlite3_bind_int64 := @SqliteMemInfo.Fsqlite3_bind_int64;
  @sqlite3_bind_null := @SqliteMemInfo.Fsqlite3_bind_null;
  @sqlite3_bind_text := @SqliteMemInfo.Fsqlite3_bind_text;
  @sqlite3_bind_text16 := @SqliteMemInfo.Fsqlite3_bind_text16;
  @sqlite3_bind_value := @SqliteMemInfo.Fsqlite3_bind_value;
  @sqlite3_bind_zeroblob := @SqliteMemInfo.Fsqlite3_bind_zeroblob;
  @sqlite3_bind_parameter_count := @SqliteMemInfo.Fsqlite3_bind_parameter_count;
  @sqlite3_bind_parameter_name := @SqliteMemInfo.Fsqlite3_bind_parameter_name;
  @sqlite3_bind_parameter_index := @SqliteMemInfo.Fsqlite3_bind_parameter_index;

  @sqlite3_step := @SqliteMemInfo.Fsqlite3_step;
  @sqlite3_data_count := @SqliteMemInfo.Fsqlite3_data_count;
end;
{$ENDIF}

function QValueToSqliteString(AValue: TQValue): string;
begin
  case AValue.ValueType of
    vdtUnset, vdtNull:
      result := 'null';
    vdtBoolean:
      begin
        if AValue.Value.AsBoolean then
          result := '1'
        else
          result := '0';
      end;
    vdtSingle:
      result := FloatToStr(AValue.Value.AsSingle);
    vdtFloat:
      result := FloatToStr(AValue.Value.AsFloat);
    vdtInteger:
      result := inttostr(AValue.Value.AsInteger);
    vdtInt64:
      result := inttostr(AValue.Value.AsInt64);
    vdtCurrency:
      result := CurrToStr(AValue.Value.AsCurrency);
    vdtBcd:
      result := BcdToStr(AValue.Value.AsBcd^);
    vdtGuid:
      result := '''' + GuidToString(AValue.Value.AsGuid^) + '''';
    vdtDateTime:
      result := '''' + FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz',AValue.AsDateTime) + '''';
    vdtInterval:
      result := '''' + AValue.Value.AsInterval.AsPgString + '''';
    vdtString:
      result := QuotedStrW(AValue.Value.AsString^, '''');
    vdtStream: // Todo:加入代码处理
      result := 'E''\\x' + BinToHex(TQValueStream(AValue.Value.AsStream).Memory,
        TQValueStream(AValue.Value.AsStream).Size) + '''';
  end;
end;

procedure TQSqliteProvider.InternalApplyChanges(AFields: TFieldDefs;
  ARecords: TQRecords);
var
  i, j: Integer;
  rec: TQRecord;
  sql, CurTableName: string;
  ErrMsg: PPQCharA;
  HasErr: Boolean;
  AField: TQFieldDef;
  ASQLBuilder: TQStringCatHelperW;
  AWhereFields: array of TQFieldDef;
  function QuotedIdent(const S: QStringW): QStringW;
  begin
    if ContainsCharW(S, ' ') then
      result := QuotedStrW(S, '"')
    else
      result := S;
  end;

  procedure CheckTable;
  var
    ADef: TQFieldDef;
    ACount, j: Integer;
    Added: Boolean;
    ADefTable: QStringW;
  begin
    i := 0;
    ACount := 0;
    SetLength(AWhereFields, AFields.Count);
    while i < AFields.Count do
    begin
      ADef := AFields[i] as TQFieldDef;
      if ADef.IsBinary or ADef.IsBlob or ADef.IsFixed or ADef.IsCalc then
      begin
        Inc(i);
        Continue;
      end;

      if (Length(ADef.BaseName) > 0) and ADef.InWhere then
      // 计算字段、二进制数据和Blob字段不能做为where条件
      begin
        if ACount > 0 then
        begin
          Added := False;
          if ADef.IsPrimary then
          begin
            Move(AWhereFields[0], AWhereFields[1], ACount * SizeOf(TQFieldDef));
            AWhereFields[0] := ADef;
            Added := True;
            Inc(ACount);
          end
          else if ADef.IsUnique then // 唯一,挪到主键后面做为值
          begin
            for j := 0 to ACount - 1 do
            begin
              if not AWhereFields[j].IsPrimary then
              begin
                Move(AWhereFields[j], AWhereFields[j + 1],
                  (ACount - j) * SizeOf(TQFieldDef));
                AWhereFields[j] := ADef;
                Added := True;
                Inc(ACount);
                Break;
              end;
            end;
          end
          else if ADef.IsIndex then // 索引字段放到普通字段的前面，但主键和唯一索引后面
          begin
            for j := 0 to ACount - 1 do
            begin
              if not(AWhereFields[j].IsPrimary or AWhereFields[j].IsUnique or
                AWhereFields[j].IsIndex) then
              begin
                Move(AWhereFields[j], AWhereFields[j + 1],
                  (ACount - j) * SizeOf(TQFieldDef));
                AWhereFields[j] := ADef;
                Added := True;
                Inc(ACount);
                Break;
              end;
            end;
          end;
          if not Added then
          begin
            AWhereFields[ACount] := ADef;
            Inc(ACount);
          end;
        end
        else
        begin
          AWhereFields[ACount] := ADef;
          Inc(ACount);
        end;
      end;
      if Length(ADef.Table) > 0 then
      begin
        if Length(ADef.Database) > 0 then
          ADefTable := QuotedIdent(ADef.Database) + '.' +
            QuotedIdent(ADef.Table)
        else
          ADefTable := QuotedIdent(ADef.Table);
        if Length(CurTableName) = 0 then
        begin
          if Length(ADef.Database) > 0 then
            CurTableName := QuotedIdent(ADef.Database) + '.' +
              QuotedIdent(ADef.Table)
          else
            CurTableName := QuotedIdent(ADef.Table);
        end
        else if CurTableName <> ADefTable then
          raise QException.CreateFmt('数据集来源于不只一个表无法自动更新( %s 和 %s 等)。',
            [CurTableName, ADef.Table]);
      end;
      Inc(i);
    end;
    SetLength(AWhereFields, ACount);
    if ACount = 0 then
      raise QException.Create('数据集没有更新目标的元数据信息，无法自动更新。');
  end;

var
  HasBinary: Boolean;
  ic, rc: Integer;
  pStmt: Psqlite3_stmt;
  ABinaryFields: array of TQFieldDef;
  pv: TQValue;
  st: string;
  NextSql: PQCharA;
begin
  // 根据信息构建更新语句,
  ErrMsg := nil;
  CheckTable;
  SetLength(ABinaryFields, AFields.Count);
  ASQLBuilder := TQStringCatHelperW.Create;
  try
    HasErr := False;
    for i := 0 to ARecords.Count - 1 do
    begin
      rec := ARecords.Records[i];
      ic := 0;
      CurTableName := '';
      ASQLBuilder.Reset;
      HasBinary := False;
      case rec.Status of
        usModified:
          begin
            for j := 0 to AFields.Count - 1 do
            begin
              AField := AFields[j] as TQFieldDef;
              if rec.Values[j].Changed then
              begin
                if CurTableName = '' then
                begin
                  CurTableName := AField.Table;
                  ASQLBuilder.Cat('update ').Cat(CurTableName).Cat(' set ');
                end;
                if CurTableName <> AField.Table then
                begin
                  sql := '不可同时更新多个表数据';
                  HasErr := True;
                  Break;
                end;
                if AField.IsBlob or AField.IsBinary then
                begin
                  ABinaryFields[ic] := AField;
                  Inc(ic);
                  HasBinary := True;
                  ASQLBuilder.Cat(QuotedIdent(AField.BaseName)).Cat('=?,');
                end
                else
                begin
                  ASQLBuilder.Cat(QuotedIdent(AField.BaseName)).Cat('=')
                    .Cat(QValueToSqliteString(rec.Values[j].NewValue)).Cat(',');
                end;
              end;
            end;
            if HasErr then
              Break;
            ASQLBuilder.Back(1);
            ASQLBuilder.Cat(' where ');
            for j := 0 to High(AWhereFields) do
            begin
              AField := AWhereFields[j];
              if rec.Values[AField.FieldNo - 1].OldValue.IsNull then
                ASQLBuilder.Cat(QuotedIdent(AField.BaseName)).Cat(' is null')
              else
                ASQLBuilder.Cat(QuotedIdent(AField.BaseName)).Cat('=')
                  .Cat(QValueToSqliteString(rec.Values[AField.FieldNo - 1]
                  .OldValue));
              ASQLBuilder.Cat(' and ');
            end;
            ASQLBuilder.Back(5);
            ASQLBuilder.Cat(';');
          end;
        usInserted:
          begin
            CurTableName := (AFields[0] as TQFieldDef).Table;
            ASQLBuilder.Cat('insert into ').Cat(CurTableName).Cat(' (');
            for j := 0 to AFields.Count - 1 do
            begin
              AField := AFields[j] as TQFieldDef;
              ASQLBuilder.Cat(QuotedIdent(AField.BaseName)).Cat(',');
            end;
            ASQLBuilder.Back(1);
            ASQLBuilder.Cat(') values (');
            for j := 0 to AFields.Count - 1 do
            begin
              AField := AFields[j] as TQFieldDef;
              if AField.IsBlob or AField.IsBinary then
              begin
                HasBinary := True;
                ABinaryFields[ic] := AField;
                Inc(ic);
                ASQLBuilder.Cat('?,');
              end
              else
                ASQLBuilder.Cat(QValueToSqliteString(rec.Values[j].NewValue)
                  ).Cat(',');
            end;
            ASQLBuilder.Back(1);
            ASQLBuilder.Cat(');');
          end;
        usDeleted:
          begin
            CurTableName := (AFields[0] as TQFieldDef).Table;
            ASQLBuilder.Cat('delete from ').Cat(CurTableName).Cat(' where ');
            for j := 0 to High(AWhereFields) do
            begin
              AField := AWhereFields[j];
              if rec.Values[AField.FieldNo - 1].OldValue.IsNull then
                ASQLBuilder.Cat(QuotedIdent(AField.BaseName)).Cat(' is null')
              else
                ASQLBuilder.Cat(QuotedIdent(AField.BaseName)).Cat('=')
                  .Cat(QValueToSqliteString(rec.Values[AField.FieldNo - 1]
                  .OldValue));
              ASQLBuilder.Cat(' and ');
            end;
            ASQLBuilder.Back(5);
            ASQLBuilder.Cat(';');
          end;
      end;
      sql := ASQLBuilder.Value;
      if HasBinary then
      begin
        PrepareSql(sql, pStmt, NextSql);
        // 绑定参数
        for j := 0 to ic - 1 do
        begin
          AField := ABinaryFields[j];
          pv := rec.Values[AField.FieldNo - 1].NewValue;
          if pv.IsNull then
            Check(sqlite3_bind_null(pStmt, j + 1)) // 参数绑定从1开始计数
          else
          begin
            case pv.ValueType of
              vdtInt64:
                Check(sqlite3_bind_int64(pStmt, j + 1, pv.AsInt64));
              vdtInteger:
                Check(sqlite3_bind_int(pStmt, j + 1, pv.AsInt64));
              vdtStream:
                Check(sqlite3_bind_blob(pStmt, j + 1, pv.AsStream.Memory,
                  pv.AsStream.Size, Pointer(SQLITE_TRANSIENT)));
              vdtCurrency, vdtFloat, vdtSingle:
                Check(sqlite3_bind_double(pStmt, j + 1, pv.AsFloat));
              vdtString:
                begin
                  st := pv.AsString;
                  Check(sqlite3_bind_text16(pStmt, i + 1, PQCharW(pv.AsString),
                    Length(st) * SizeOf(QCharW), Pointer(SQLITE_TRANSIENT)));
                end;
            end;
          end;
        end;
        Check(sqlite3_step(pStmt));
        Check(sqlite3_finalize(pStmt));
      end
      else if Assigned(sqlite3_exec) then
        Check(sqlite3_exec(FSqlite3, PQCharA(qstring.Utf8Encode(sql)),
          Sqlite3ExecCallback, self, ErrMsg))
      else
      begin
        PrepareSql(sql, pStmt, NextSql);
        rc := sqlite3_step(pStmt);
        Check(sqlite3_finalize(pStmt));
        Check(rc);
      end;
      if ErrMsg <> nil then
      begin
        sql := 'sqlite3_exec错误：' + qstring.Utf8Decode(ErrMsg^);
        sqlite3_free(ErrMsg);
        HasErr := True;
        Break;
      end;
    end;
  finally
    FreeAndNil(ASQLBuilder);
  end;
  if HasErr then
    raise Exception.Create(sql);
end;

procedure TQSqliteProvider.InternalClose;
begin
  if FHandle > 1 then
    inherited
  else
  begin
    UnLoad;
    FHandle := 0;
  end;
end;

function TQSqliteProvider.InternalExecute(var ARequest: TQSQLRequest): Boolean;
var
  ErrMsg: PPQCharA;
  rc: Integer;
  pStmt: Psqlite3_stmt;
  BlobSize, i: Integer;
  pv: TQValue;
  nColType: Integer;
  DataPtr: Pointer;
  st: QStringW;
  sql: string;
  NextSql: PQCharA;
label DoFetchNext;
begin
  ErrMsg := nil;
  case ARequest.Command.Action of
    caPrepare:
      begin
        PrepareSql(ARequest.Command.sql, pStmt, NextSql);
        if (ARequest.Command.DataObject <> nil) and
          TObject(ARequest.Command.DataObject).InheritsFrom(TQDataSet) then
        begin
          SetDataSetHandle(ARequest.Command.DataObject, NativeUInt(pStmt));
          InitFieldDescs;
        end;
      end;
    caExecute:
      begin
        if Assigned(sqlite3_exec) then
          rc := sqlite3_exec(FSqlite3,
            PQCharA(qstring.Utf8Encode(ARequest.Command.sql)),
            Sqlite3ExecCallback, self, ErrMsg)
        else
        begin
          PrepareSql(ARequest.Command.sql, pStmt, NextSql);
          rc := sqlite3_step(pStmt);
          Check(sqlite3_finalize(pStmt));
          Check(rc);
        end;
        if ErrMsg <> nil then
        begin
          st := qstring.Utf8Decode(ErrMsg^);
          sqlite3_free(ErrMsg);
          raise Exception.Create('sqlite3_exec错误：' + st);
        end
        else
          Check(rc);
      end;
    caFetchStream, caFetchRecords:
      begin
        if TQDataSet(ARequest.Command.DataObject).Handle = 0 then
        begin
          sql := ARequest.Command.sql;
          PrepareSql(sql, pStmt, NextSql);
          if pStmt = nil then
            goto DoFetchNext;
          SetDataSetHandle(ARequest.Command.DataObject, NativeUInt(pStmt));
        end;
        // 绑定参数
        for i := Low(ARequest.Command.Params)
          to High(ARequest.Command.Params) do
        begin
          pv := ARequest.Command.Params[i];
          if pv.IsNull then
            Check(sqlite3_bind_null(pStmt, i + 1)) // 参数绑定从1开始计数
          else
          begin
            case pv.ValueType of
              vdtInt64:
                Check(sqlite3_bind_int64(pStmt, i + 1, pv.AsInt64));
              vdtInteger:
                Check(sqlite3_bind_int(pStmt, i + 1, pv.AsInt64));
              vdtStream:
                Check(sqlite3_bind_blob(pStmt, i + 1, pv.AsStream.Memory,
                  pv.AsStream.Size, Pointer(SQLITE_TRANSIENT)));
              vdtCurrency, vdtFloat, vdtSingle:
                Check(sqlite3_bind_double(pStmt, i + 1, pv.AsFloat));
              vdtString:
                begin
                  st := pv.AsString;
                  Check(sqlite3_bind_text16(pStmt, i + 1, PQCharW(pv.AsString),
                    Length(st) * SizeOf(QCharW), Pointer(SQLITE_TRANSIENT)));
                end;
            end;
          end;
        end;
        InitFieldDescs;
        // 执行获取每一条数据
        while True do
        begin
          rc := sqlite3_step(pStmt);
          // 添加记录
          if rc <> SQLITE_ROW then
            Break;
          FActiveRecord := AllocRecord;
          for i := 0 to FActiveFieldDefs.Count - 1 do
          begin
            nColType := sqlite3_column_type(pStmt, i);
            if nColType = SQLITE_NULL then
              FActiveRecord.Values[i].OldValue.TypeNeeded(vdtNull)
            else
            begin
              if TQFieldDef(FActiveFieldDefs[i]).DBType = SQL_UNKNOWN then
              begin
                case nColType of
                  SQLITE_INTEGER:
                    TQFieldDef(FActiveFieldDefs[i]).DBType := SQL_INT64;
                  SQLITE_FLOAT:
                    TQFieldDef(FActiveFieldDefs[i]).DBType := SQL_FLOAT;
                  SQLITE_BLOB:
                    TQFieldDef(FActiveFieldDefs[i]).DBType := SQL_BINARY;
                  SQLITE_TEXT:
                    TQFieldDef(FActiveFieldDefs[i]).DBType := SQL_VARCHAR;
                end;
              end;
              FActiveRecord.Values[i].OldValue.TypeNeeded
                (TQFieldDef(FActiveFieldDefs[i]).ValueType);
              case nColType of
                SQLITE_INTEGER:
                  begin
                    FActiveRecord.Values[i].OldValue.AsInteger :=
                      sqlite3_column_int64(pStmt, i);
                  end;
                SQLITE_FLOAT:
                  begin
                    FActiveRecord.Values[i].OldValue.AsFloat :=
                      sqlite3_column_double(pStmt, i);
                  end;
                SQLITE_TEXT:
                  begin
                    FActiveRecord.Values[i].OldValue.AsString :=
                      sqlite3_column_text16(pStmt, i);
                  end;
                SQLITE_BLOB:
                  begin
                    if TQFieldDef(FActiveFieldDefs[i]).DataType = ftBlob then
                    begin
                      DataPtr := sqlite3_column_blob(pStmt, i);
                      BlobSize := sqlite3_column_bytes(pStmt, i);
                    end
                    else
                    begin
                      DataPtr := sqlite3_column_text(pStmt, i);
                      BlobSize := sqlite3_column_bytes(pStmt, i);
                    end;
                    if Assigned(DataPtr) and (BlobSize > 0) then
                      FActiveRecord.Values[i].OldValue.AsStream.WriteBuffer
                        (DataPtr^, BlobSize);
                  end;
              end;
            end;
          end;
          AddResultRecord(FActiveRecord);
          Inc(FActiveRequest.result.Statics.AffectRows);
        end;
      DoFetchNext:
        while Assigned(NextSql) and (NextSql^ <> 0) do // 然后判定是否还有其他的Sql
          OpenNextSqlDataSet(NextSql, ARequest.Command.DataObject);
      end;
  end;
  result := True;
end;

procedure TQSqliteProvider.InternalOpen;
var
  rc: Integer;
  st: QStringA;
begin
  inherited;
  if FHandle = 0 then
  begin
{$IFDEF MemSqlite}
    InitStaticFuncs;
    FUseMemSqlite := True;
    FHandle := 1;
{$ELSE}
    FHandle := LoadLibrary(SQLiteDLL);
    if FHandle <> 0 then
      LoadEntries
    else
      Exit;
{$ENDIF}
  end;
  if FDbName = '' then
  begin
    Close;
    Exit;
  end;
  if FReadOnly then
    rc := sqlite3_open_v2(PQCharA(qstring.Utf8Encode(FDbName)), FSqlite3,
      SQLITE_OPEN_READONLY, nil)
  else
    rc := sqlite3_open_v2(PQCharA(qstring.Utf8Encode(FDbName)), FSqlite3,
      SQLITE_OPEN_READWRITE or SQLITE_OPEN_CREATE, nil);
  if rc <> SQLITE_OK then
  begin
    Close;
    Check(rc);
  end
  else
  begin
    if Password <> '' then
    begin
      if Assigned(sqlite3_key) then
      begin
        st := qstring.Utf8Encode(Password);
        Check(sqlite3_key(FSqlite3, PQCharA(st), Length(st)));
      end;
    end;
    FFunctions.InstallFuncs;
  end;
end;

procedure TQSqliteProvider.LoadEntries;
begin
  inherited;
  sqlite3_open := GetProcAddress(FHandle, 'sqlite3_open');
  sqlite3_open_v2 := GetProcAddress(FHandle, 'sqlite3_open_v2');
  sqlite3_open16 := GetProcAddress(FHandle, 'sqlite3_open16');

  sqlite3_exec := GetProcAddress(FHandle, 'sqlite3_exec');
  sqlite3_errmsg := GetProcAddress(FHandle, 'sqlite3_errmsg');
  sqlite3_errmsg16 := GetProcAddress(FHandle, 'sqlite3_errmsg16');
  sqlite3_close := GetProcAddress(FHandle, 'sqlite3_close');
  sqlite3_free := GetProcAddress(FHandle, 'sqlite3_free');

  sqlite3_column_count := GetProcAddress(FHandle, 'sqlite3_column_count');
  sqlite3_column_name := GetProcAddress(FHandle, 'sqlite3_column_name');
  sqlite3_column_name16 := GetProcAddress(FHandle, 'sqlite3_column_name16');
  sqlite3_column_database_name := GetProcAddress(FHandle,
    'sqlite3_column_database_name');
  sqlite3_column_database_name16 := GetProcAddress(FHandle,
    'sqlite3_column_database_name16');
  sqlite3_column_table_name := GetProcAddress(FHandle,
    'sqlite3_column_table_name');
  sqlite3_column_table_name16 := GetProcAddress(FHandle,
    'sqlite3_column_table_name16');

  sqlite3_column_origin_name := GetProcAddress(FHandle,
    'sqlite3_column_origin_name');
  sqlite3_column_origin_name16 := GetProcAddress(FHandle,
    'sqlite3_column_origin_name16');
  sqlite3_column_decltype := GetProcAddress(FHandle, 'sqlite3_column_decltype');
  sqlite3_column_decltype16 := GetProcAddress(FHandle,
    'sqlite3_column_decltype16');
  sqlite3_column_blob := GetProcAddress(FHandle, 'sqlite3_column_blob');
  sqlite3_column_bytes := GetProcAddress(FHandle, 'sqlite3_column_bytes');
  sqlite3_column_bytes16 := GetProcAddress(FHandle, 'sqlite3_column_bytes16');
  sqlite3_column_double := GetProcAddress(FHandle, 'sqlite3_column_double');
  sqlite3_column_int := GetProcAddress(FHandle, 'sqlite3_column_int');
  sqlite3_column_int64 := GetProcAddress(FHandle, 'sqlite3_column_int64');
  sqlite3_column_text := GetProcAddress(FHandle, 'sqlite3_column_text');
  sqlite3_column_text16 := GetProcAddress(FHandle, 'sqlite3_column_text16');
  sqlite3_column_type := GetProcAddress(FHandle, 'sqlite3_column_type');
  sqlite3_column_value := GetProcAddress(FHandle, 'sqlite3_column_value');
  sqlite3_finalize := GetProcAddress(FHandle, 'sqlite3_finalize');
  sqlite3_reset := GetProcAddress(FHandle, 'sqlite3_reset');

  sqlite3_create_function := GetProcAddress(FHandle, 'sqlite3_create_function');
  sqlite3_create_function16 := GetProcAddress(FHandle,
    'sqlite3_create_function16');
  sqlite3_create_function_v2 := GetProcAddress(FHandle,
    'sqlite3_create_function_v2');

  sqlite3_prepare := GetProcAddress(FHandle, 'sqlite3_prepare');
  sqlite3_prepare_v2 := GetProcAddress(FHandle, 'sqlite3_prepare_v2');
  sqlite3_prepare16 := GetProcAddress(FHandle, 'sqlite3_prepare16');
  sqlite3_prepare16_v2 := GetProcAddress(FHandle, 'sqlite3_prepare16_v2');
  sqlite3_table_column_metadata := GetProcAddress(FHandle,
    'sqlite3_table_column_metadata');
  sqlite3_key := GetProcAddress(FHandle, 'sqlite3_key');
  sqlite3_rekey := GetProcAddress(FHandle, 'sqlite3_rekey');

  sqlite3_value_blob := GetProcAddress(FHandle, 'sqlite3_value_bloba');
  sqlite3_value_bytes := GetProcAddress(FHandle, 'sqlite3_value_bytes');
  sqlite3_value_bytes16 := GetProcAddress(FHandle, 'sqlite3_value_bytes16');
  sqlite3_value_double := GetProcAddress(FHandle, 'sqlite3_value_double');
  sqlite3_value_int := GetProcAddress(FHandle, 'sqlite3_value_int');
  sqlite3_value_int64 := GetProcAddress(FHandle, 'sqlite3_value_int64');
  sqlite3_value_text16 := GetProcAddress(FHandle, 'sqlite3_value_text16');
  sqlite3_value_text16le := GetProcAddress(FHandle, 'sqlite3_value_text16le');
  sqlite3_value_text16be := GetProcAddress(FHandle, 'sqlite3_value_text16be');
  sqlite3_value_type := GetProcAddress(FHandle, 'sqlite3_value_type');
  sqlite3_value_numeric_type := GetProcAddress(FHandle,
    'sqlite3_value_numeric_type');

  sqlite3_result_blob := GetProcAddress(FHandle, 'sqlite3_result_blob');
  sqlite3_result_blob64 := GetProcAddress(FHandle, 'sqlite3_result_blob64');
  sqlite3_result_double := GetProcAddress(FHandle, 'sqlite3_result_double');
  sqlite3_result_error16 := GetProcAddress(FHandle, 'sqlite3_result_error16');
  sqlite3_result_error_code := GetProcAddress(FHandle,
    'sqlite3_result_error_code');
  sqlite3_result_int64 := GetProcAddress(FHandle, 'sqlite3_result_int64');
  sqlite3_result_null := GetProcAddress(FHandle, 'sqlite3_result_null');
  sqlite3_result_text16 := GetProcAddress(FHandle, 'sqlite3_result_text16');
  sqlite3_result_text64 := GetProcAddress(FHandle, 'sqlite3_result_text64');
  sqlite3_result_zeroblob := GetProcAddress(FHandle, 'sqlite3_result_zeroblob');
  sqlite3_result_value := GetProcAddress(FHandle, 'sqlite3_result_value');

  sqlite3_bind_blob := GetProcAddress(FHandle, 'sqlite3_bind_blob');
  sqlite3_bind_double := GetProcAddress(FHandle, 'sqlite3_bind_double');
  sqlite3_bind_int := GetProcAddress(FHandle, 'sqlite3_bind_int');
  sqlite3_bind_int64 := GetProcAddress(FHandle, 'sqlite3_bind_int64');
  sqlite3_bind_null := GetProcAddress(FHandle, 'sqlite3_bind_null');
  sqlite3_bind_text := GetProcAddress(FHandle, 'sqlite3_bind_text');
  sqlite3_bind_text16 := GetProcAddress(FHandle, 'sqlite3_bind_text16');
  sqlite3_bind_value := GetProcAddress(FHandle, 'sqlite3_bind_value');
  sqlite3_bind_zeroblob := GetProcAddress(FHandle, 'sqlite3_bind_zeroblob');
  sqlite3_bind_parameter_count := GetProcAddress(FHandle,
    'sqlite3_bind_parameter_count');
  sqlite3_bind_parameter_name := GetProcAddress(FHandle,
    'sqlite3_bind_parameter_name');
  sqlite3_bind_parameter_index := GetProcAddress(FHandle,
    'sqlite3_bind_parameter_index');

  sqlite3_step := GetProcAddress(FHandle, 'sqlite3_step');
  sqlite3_data_count := GetProcAddress(FHandle, 'sqlite3_data_count');
end;

type
  TQtmpDataSet = class(qdb.TQDataSet);

procedure TQSqliteProvider.OpenNextSqlDataSet(var NextSql: PQCharA;
  AttachDs: TQDataSet);
var
  pStmt: Psqlite3_stmt;
  rc: Integer;
  i, nColType, BlobSize: Integer;
  DataPtr: Pointer;
begin
  if (NextSql = nil) or (NextSql^ = 0) then
    Exit;
  sqlite3_prepare_v2(FSqlite3, NextSql, -1, pStmt, NextSql);
  if pStmt = nil then
  begin
    NextSql := nil;
    Exit;
  end;
  i := sqlite3_column_count(pStmt);
  if i <> 0 then
  begin
    AddResultSet;
    SetDataSetHandle(AttachDs.Recordsets[AttachDs.RecordsetCount - 1],
      NativeUInt(pStmt));
    InitFieldDescs;
  end;
  while True do
  begin
    rc := sqlite3_step(pStmt);
    if rc <> SQLITE_ROW then
      Break;
    FActiveRecord := AllocRecord;
    for i := 0 to FActiveFieldDefs.Count - 1 do
    begin
      nColType := sqlite3_column_type(pStmt, i);
      if nColType = SQLITE_NULL then
        FActiveRecord.Values[i].OldValue.TypeNeeded(vdtNull)
      else
      begin
        if TQFieldDef(FActiveFieldDefs[i]).DBType = SQL_UNKNOWN then
        begin
          case nColType of
            SQLITE_INTEGER:
              TQFieldDef(FActiveFieldDefs[i]).DBType := SQL_INT64;
            SQLITE_FLOAT:
              TQFieldDef(FActiveFieldDefs[i]).DBType := SQL_FLOAT;
            SQLITE_BLOB:
              TQFieldDef(FActiveFieldDefs[i]).DBType := SQL_BINARY;
            SQLITE_TEXT:
              TQFieldDef(FActiveFieldDefs[i]).DBType := SQL_VARCHAR;
          end;
        end;
        FActiveRecord.Values[i].OldValue.TypeNeeded
          (TQFieldDef(FActiveFieldDefs[i]).ValueType);
        case nColType of
          SQLITE_INTEGER:
            FActiveRecord.Values[i].OldValue.AsInteger :=
              sqlite3_column_int64(pStmt, i);
          SQLITE_FLOAT:
            FActiveRecord.Values[i].OldValue.AsFloat :=
              sqlite3_column_double(pStmt, i);
          SQLITE_TEXT:
            FActiveRecord.Values[i].OldValue.AsString :=
              sqlite3_column_text16(pStmt, i);
          SQLITE_BLOB:
            begin
              if TQFieldDef(FActiveFieldDefs[i]).DataType = ftBlob then
              begin
                DataPtr := sqlite3_column_blob(pStmt, i);
                BlobSize := sqlite3_column_bytes(pStmt, i);
              end
              else
              begin
                DataPtr := sqlite3_column_text(pStmt, i);
                BlobSize := sqlite3_column_bytes(pStmt, i);
              end;
              if Assigned(DataPtr) and (BlobSize > 0) then
                FActiveRecord.Values[i].OldValue.AsStream.WriteBuffer(DataPtr^,
                  BlobSize);
            end;
        end;
      end;
    end;
    AddResultRecord(FActiveRecord);
    Inc(FActiveRequest.result.Statics.AffectRows);
  end;
end;

procedure TQSqliteProvider.PrepareSql(sql: QStringW; var pStmt: Psqlite3_stmt;
  var NextSql: PQCharA);
var
  utf8Sql: QStringA;
begin
  utf8Sql := qstring.Utf8Encode(sql);
  sqlite3_prepare_v2(FSqlite3, PQCharA(utf8Sql), -1 { Length(utf8Sql)+1 } ,
    pStmt, NextSql);
end;

function TQSqliteProvider.ProcedureExists(AName: QStringW): Boolean;
begin
  result := False;
  // SQLite don't support procedure
end;

function TQSqliteProvider.RecordExists(ACmdText: QStringW): Boolean;
var
  ADataSet: TQDataSet;
begin
  ADataSet := OpenDataSet(ACmdText);
  if Assigned(ADataSet) then
  begin
    result := ADataSet.RecordCount > 0;
    ReleaseDataSet(ADataSet);
  end
  else
    result := False;
end;

procedure TQSqliteProvider.RestDbPassword(NewPwd: string);
var
  st: QStringA;
begin
  if Connected and Assigned(sqlite3_rekey) then
  begin
    if Password <> NewPwd then
    begin
      if NewPwd <> '' then
      begin
        st := qstring.Utf8Encode(NewPwd);
        Check(sqlite3_rekey(FSqlite3, PQCharA(st), Length(st)));
      end
      else
        Check(sqlite3_rekey(FSqlite3, nil, 0));
      Password := NewPwd;
    end;
  end;
end;

procedure TQSqliteProvider.RollbackTrans(ASavePointName: QStringW);
var
  ErrMsg: PPQCharA;
  pStmt: Psqlite3_stmt;
  NextSql: PQCharA;
begin
  if Assigned(sqlite3_exec) then
  begin
    ErrMsg := nil;
    Check(sqlite3_exec(FSqlite3,
      PQCharA(qstring.Utf8Encode('rollback transaction')), nil, nil, ErrMsg));
    if ErrMsg <> nil then
      sqlite3_free(ErrMsg);
  end
  else
  begin
    PrepareSql('rollback transaction', pStmt, NextSql);
    Check(sqlite3_step(pStmt));
    sqlite3_finalize(pStmt);
  end;
end;

procedure TQSqliteProvider.SetDbName(const Value: string);
begin
  if FDbName <> Value then
  begin
    FDbName := Value;
    Close;
  end;
end;

procedure TQSqliteProvider.SetFunctions(const Value: TQSqliteFunctions);
begin
  FFunctions.Assign(Value);
end;

procedure TQSqliteProvider.SetReadOnly(const Value: Boolean);
begin
  if FReadOnly <> Value then
  begin
    FReadOnly := Value;
    Close;
  end;
end;

function TQSqliteProvider.TableExists(ATableName: QStringW): Boolean;
begin
  result := RecordExists('select * from sqlite_master where name=' +
    QuotedStrW(ATableName, '''') + ' and type=''table'';');
end;

function TQSqliteProvider.TriggerExists(AName: QStringW): Boolean;
begin
  result := RecordExists('select * from sqlite_master where name=' +
    QuotedStrW(AName, '''') + ' and type=''trigger'';');
end;

var
  sqlite3_user_data: function(context: PSqlite3_context): Pointer; cdecl;

procedure TQSqliteProvider.UnLoad;
begin
  sqlite3_close(FSqlite3);
  sqlite3_open := nil;
  sqlite3_open_v2 := nil;
  sqlite3_open16 := nil;
  sqlite3_key := nil;
  sqlite3_rekey := nil;

  sqlite3_exec := nil;
  sqlite3_errmsg := nil;
  sqlite3_errmsg16 := nil;
  sqlite3_close := nil;

  sqlite3_column_count := nil;
  sqlite3_column_name := nil;
  sqlite3_column_name16 := nil;
  sqlite3_column_database_name := nil;
  sqlite3_column_database_name16 := nil;
  sqlite3_column_table_name := nil;
  sqlite3_column_table_name16 := nil;

  sqlite3_column_origin_name := nil;
  sqlite3_column_origin_name16 := nil;
  sqlite3_column_decltype := nil;
  sqlite3_column_decltype16 := nil;
  sqlite3_column_blob := nil;
  sqlite3_column_bytes := nil;
  sqlite3_column_bytes16 := nil;
  sqlite3_column_double := nil;
  sqlite3_column_int := nil;
  sqlite3_column_int64 := nil;
  sqlite3_column_text := nil;
  sqlite3_column_text16 := nil;
  sqlite3_column_type := nil;
  sqlite3_column_value := nil;
  sqlite3_free := nil;
  sqlite3_prepare := nil;
  sqlite3_prepare_v2 := nil;
  sqlite3_prepare16 := nil;
  sqlite3_prepare16_v2 := nil;
  sqlite3_table_column_metadata := nil;
  sqlite3_finalize := nil;
  sqlite3_reset := nil;

  sqlite3_bind_blob := nil;
  sqlite3_bind_double := nil;
  sqlite3_bind_int := nil;
  sqlite3_bind_int64 := nil;
  sqlite3_bind_null := nil;
  sqlite3_bind_text := nil;
  sqlite3_bind_text16 := nil;
  sqlite3_bind_value := nil;
  sqlite3_bind_zeroblob := nil;
  sqlite3_bind_parameter_count := nil;
  sqlite3_bind_parameter_name := nil;
  sqlite3_bind_parameter_index := nil;
  sqlite3_step := nil;
  sqlite3_data_count := nil;
  sqlite3_create_function := nil;
  sqlite3_create_function16 := nil;
  sqlite3_create_function_v2 := nil;
  sqlite3_user_data := nil;

  sqlite3_value_blob := nil;
  sqlite3_value_bytes := nil;
  sqlite3_value_bytes16 := nil;
  sqlite3_value_double := nil;
  sqlite3_value_int := nil;
  sqlite3_value_int64 := nil;
  sqlite3_value_text16 := nil;
  sqlite3_value_text16le := nil;
  sqlite3_value_text16be := nil;
  sqlite3_value_type := nil;
  sqlite3_value_numeric_type := nil;

  sqlite3_result_blob := nil;
  sqlite3_result_blob64 := nil;
  sqlite3_result_double := nil;
  sqlite3_result_error16 := nil;
  sqlite3_result_error_code := nil;
  sqlite3_result_int64 := nil;
  sqlite3_result_null := nil;
  sqlite3_result_text16 := nil;
  sqlite3_result_text64 := nil;
  sqlite3_result_zeroblob := nil;
  sqlite3_result_value := nil;
end;

function TQSqliteProvider.ViewExists(AName: QStringW): Boolean;
begin
  result := RecordExists('select * from sqlite_master where name=' +
    QuotedStrW(AName, '''') + ' and type=''view'';');
end;

{ TQSqliteFunction }

constructor TQSqliteFunction.Create(Collection: TCollection);
begin
  inherited;

end;

procedure sqlite3_func_step(context: PSqlite3_context; nargs: Integer;
  args: PPSqlite3_value); cdecl;
var
  Func: TQSqliteFunction;
begin
  Func := sqlite3_user_data(context);
  Func.Execute(context, nargs, args);
end;

procedure sqlite3_final(context: PSqlite3_context); cdecl;
var
  Func: TQSqliteFunction;
begin
  Func := sqlite3_user_data(context);
end;

procedure TQSqliteFunction.Execute(context: PSqlite3_context; nargs: Integer;
  args: PPSqlite3_value);
var
  Prov: TQSqliteProvider;
  pVal: PPSqlite3_value;
  i, vtype: Integer;
  Values: array of TQValue;
  buf: PByte;
  v: TQValue;
  st: QStringW;
  bcd: TBcd;
begin
  Prov := TQSqliteFunctions(Collection).FProvider;
  pVal := args;
  SetLength(Values, nargs);
  for i := 0 to nargs - 1 do
  begin
    vtype := Prov.sqlite3_value_type(pVal^);
    case vtype of
      SQLITE_NULL:
        Values[i].TypeNeeded(vdtNull);
      SQLITE_INTEGER:
        begin
          Values[i].TypeNeeded(vdtInt64);
          Values[i].AsInteger := Prov.sqlite3_value_int64(pVal^);
        end;
      SQLITE_FLOAT:
        begin
          Values[i].TypeNeeded(vdtFloat);
          Values[i].AsFloat := Prov.sqlite3_value_double(pVal^);
        end;
      SQLITE_TEXT:
        begin
          buf := Prov.sqlite3_value_text16(pVal^);
          Values[i].TypeNeeded(vdtString);
          Values[i].AsString := PWideChar(buf);
        end;
      SQLITE_BLOB:
        begin
          vtype := Prov.sqlite3_value_bytes(pVal^);
          buf := Prov.sqlite3_value_blob(pVal^);
          Values[i].TypeNeeded(vdtStream);
          Values[i].AsStream.WriteBuffer(buf^, vtype);
        end;
    end;
    pVal := PPSqlite3_value(NativeUInt(pVal) + SizeOf(PSqlite3_value));
  end;
  if Assigned(FOnExecute) then
  begin
    v.TypeNeeded(vdtNull);
    FOnExecute(self, Values, v);
    if v.IsNull then
      Prov.sqlite3_result_null(context)
    else
      case v.ValueType of
        vdtStream:
          begin
            Prov.sqlite3_result_zeroblob(context, v.AsStream.Size);
            Prov.sqlite3_result_blob(context, v.AsStream.Memory,
              v.AsStream.Size, Pointer($FFFFFFFF));
          end;
        vdtString:
          begin
            st := v.AsString;
            if st <> '' then
              Prov.sqlite3_result_text16(context, PByte(@st[1]),
                Length(st) * SizeOf(char), Pointer($FFFFFFFF))
            else
              Prov.sqlite3_result_text16(context, nil, 0, Pointer($FFFFFFFF))
          end;
        vdtFloat, vdtSingle, vdtCurrency, vdtDateTime:
          Prov.sqlite3_result_double(context, v.AsFloat);
        vdtBoolean:
          Prov.sqlite3_result_int64(context, v.AsInteger);
        vdtInteger, vdtInt64:
          Prov.sqlite3_result_int64(context, v.AsInt64);
        vdtGuid:
          begin
            st := GuidToString(v.AsGuid);
            Prov.sqlite3_result_text16(context, PByte(@st[1]),
              Length(st) * SizeOf(char), Pointer($FFFFFFFF))
          end;
        vdtBcd:
          begin
            Prov.sqlite3_result_zeroblob(context, SizeOf(TBcd));
            bcd := v.AsBcd;
            Prov.sqlite3_result_blob(context, @bcd, SizeOf(TBcd),
              Pointer($FFFFFFFF));
          end;
      end;
  end;
end;

procedure TQSqliteFunction.Install;
var
  Prov: TQSqliteProvider;
begin
  if FFuncName <> '' then
  begin
    Prov := TQSqliteFunctions(Collection).FProvider;
    if not Assigned(sqlite3_user_data) then
    begin
{$IFDEF MemSqlite}
      if Prov.FUseMemSqlite then
        sqlite3_user_data := @SqliteMemInfo.Fsqlite3_user_data
      else {$ENDIF}
        sqlite3_user_data := GetProcAddress(Prov.FHandle, 'sqlite3_user_data');

    end;
    if not Assigned(sqlite3_user_data) then
      raise Exception.Create('获取sqlite3_user_data函数失败');
    if FIsAggregateFunc then // 聚合函数，需要设置 xStep 和 xFinal 参数,Xfunc为nil
      Prov.Check(Prov.sqlite3_create_function(Prov.FSqlite3,
        PQCharA(qstring.Utf8Encode(FFuncName)), FArgCount, SQLITE_UTF16, self,
        nil, sqlite3_func_step, sqlite3_final))
    else // 普通函数，只用设置XFunc
      Prov.Check(Prov.sqlite3_create_function(Prov.FSqlite3,
        PQCharA(qstring.Utf8Encode(FFuncName)), FArgCount, SQLITE_UTF16, self,
        sqlite3_func_step, nil, nil));
  end;
end;

procedure TQSqliteFunction.Reset;
begin
  if TQSqliteFunctions(Collection).FProvider.Connected then
  begin
    UnInstall;
    Install;
  end;
end;

procedure TQSqliteFunction.SetArgCount(const Value: Integer);
begin
  FArgCount := Value;
end;

procedure TQSqliteFunction.SetFuncName(const Value: string);
begin
  if FFuncName <> Value then
  begin
    FFuncName := Value;
    Reset
  end;
end;

procedure TQSqliteFunction.SetIsAggregateFunc(const Value: Boolean);
begin
  if FIsAggregateFunc <> Value then
  begin
    FIsAggregateFunc := Value;
    Reset;
  end;
end;

procedure TQSqliteFunction.UnInstall;
begin

end;

{ TQSqliteFunctions }

function TQSqliteFunctions.Add: TQSqliteFunction;
begin
  result := TQSqliteFunction(inherited Add);
end;

function TQSqliteFunctions.GetFunction(Index: Integer): TQSqliteFunction;
begin
  result := TQSqliteFunction(inherited Items[Index]);
end;

procedure TQSqliteFunctions.InstallFuncs;
var
  i: Integer;
begin
  for i := 0 to Count - 1 do
    TQSqliteFunction(Items[i]).Install;
end;

procedure TQSqliteFunctions.SetFunction(Index: Integer;
  Value: TQSqliteFunction);
begin
  Items[Index].Assign(Value);
end;

initialization

InitSqliteTypes;

finalization

SqliteTypes.Free;

end.
