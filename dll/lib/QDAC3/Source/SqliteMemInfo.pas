{
  QDAC Sqlite不带DLL，内存处理单元
  作者：不得闲
  2015.10.18
  如果使用XE7以上的版本，则默认使用FireDac自带的Sqlite接口函数库，低于XE7版本的，则使用
  内存DLL加载资源，内存DLL资源使用 武稀松大侠的内存加载单元库，支持32和64位
}
unit SqliteMemInfo;
interface
{$IF RTLVersion>=28}
{$DEFINE VER280Higher}
{$IFEND}

{$IFNDEF VER280Higher}
  {.$DEFINE CompressMem} //是否启用压缩资源
{$ENDIF}

uses classes,{$IFDEF MSWINDOWS}Windows,{$ENDIF}
   {$IFDEF VER280Higher}FireDAC.Phys.SQLiteCli,FireDAC.Phys.SQLiteWrapper{$ELSE}qdac_memmodule{$ENDIF},
   {$IFDEF UNICODE}Generics.Collections{$ELSE}
  IniFiles{$ENDIF},qprov_sqlite;

{$IFDEF Win64}
 {$IFDEF CompressMem}
   {$R sqlite_AMD64Compress.RES}
 {$ELSE}
   {$R sqlite_AMD64.RES}
 {$ENDIF}
{$ELSE IFDEFINE WIn32}
  {$IFDEF CompressMem}
   {$R sqlite_X86Compress.RES}
  {$ELSE}
   {$R sqlite_X86.RES}
  {$ENDIF}
{$ENDIF}
var
  Fsqlite3_open: function(filename: PByte; var pDb: PSqlite3)
      : Integer; cdecl;
  Fsqlite3_open16: function(filename: PWideChar; var pDb: PSqlite3)
    : Integer; cdecl;
  Fsqlite3_open_v2: function(filename: PByte; var pDb: PSqlite3;
    flags: Integer; zVfs: PByte): Integer; cdecl;
  Fsqlite3_exec: function(pDb: PSqlite3; sql: PByte;
    Callback: TSqlite3ExecCallback; CallbackArg: Pointer; ErrMsg: PPChar)
    : Integer; cdecl;
  Fsqlite3_errmsg: function(db: PSqlite3): PByte; cdecl;
  Fsqlite3_errmsg16: function(db: PSqlite3): PWideChar; cdecl;

  Fsqlite3_prepare: function(db: PSqlite3; zSql: PByte; nByte: Integer;
    var ppStmt: Psqlite3_stmt; out pzTail: PByte): Integer; cdecl;
  Fsqlite3_prepare_v2: function(db: PSqlite3; zSql: PByte; nByte: Integer;
    var ppStmt: Psqlite3_stmt; out pzTail: PByte): Integer; cdecl;
  Fsqlite3_prepare16: function(db: PSqlite3; zSql: PWideChar; nByte: Integer;
    var ppStmt: Psqlite3_stmt; out pzTail: PWideChar): Integer; cdecl;
  Fsqlite3_prepare16_v2: function(db: PSqlite3; zSql: PWideChar;
    nByte: Integer; var ppStmt: Psqlite3_stmt; out pzTail: PWideChar)
    : Integer; cdecl;
  Fsqlite3_table_column_metadata: function(db: PSqlite3;
    DbName, TableName, zColumnName: PByte;
    var DataType, CollSeq: PByte; var NotNull, PrimaryKey,
    Autoinc: Integer): Integer; cdecl;

  Fsqlite3_key: function (db: psqlite3; key: PByte; nKey: Integer): Integer; cdecl;
  Fsqlite3_rekey: function (db: psqlite3; key: PByte; nKey: Integer): Integer; cdecl;

  //Sqlite3Value相应函数
  Fsqlite3_value_blob: function (value: psqlite3_value): Pointer; cdecl;
  Fsqlite3_value_bytes: function (value: psqlite3_value): Integer; cdecl;
  Fsqlite3_value_bytes16: function (value: psqlite3_value): Integer; cdecl;
  Fsqlite3_value_double: function (value: psqlite3_value): Double; cdecl;
  Fsqlite3_value_int: function (value: psqlite3_value): Integer; cdecl;
  Fsqlite3_value_int64: function (value: psqlite3_value): int64; cdecl;
  Fsqlite3_value_text16: function (value: psqlite3_value): PByte; cdecl;
  Fsqlite3_value_text16le: function (value: psqlite3_value): PByte; cdecl;
  Fsqlite3_value_text16be: function (value: psqlite3_value): PByte; cdecl;
  Fsqlite3_value_type: function (value: psqlite3_value): Integer; cdecl;
  Fsqlite3_value_numeric_type: function (value: psqlite3_value): Integer; cdecl;

  //Sqlite3结果返回
  Fsqlite3_result_blob: procedure (context: psqlite3_context; value: Pointer;
    nBytes: Integer; destr: Tsqlite3_destroy_callback); cdecl;
  Fsqlite3_result_blob64: procedure (context: psqlite3_context; value: Pointer;
     nBytes: int64; destr: Tsqlite3_destroy_callback); cdecl;
  Fsqlite3_result_double: procedure (context: psqlite3_context; value: Double); cdecl;
  Fsqlite3_result_error16: procedure (context: psqlite3_context; msg: PByte;nBytes: Integer); cdecl;
  Fsqlite3_result_error_code: procedure (context: psqlite3_context; code: Integer); cdecl;
  Fsqlite3_result_int64: procedure (context: psqlite3_context; value: int64); cdecl;
  Fsqlite3_result_null: procedure (context: psqlite3_context); cdecl;
  Fsqlite3_result_text16: procedure (context: psqlite3_context; value: PByte;
     nBytes: Integer; destr: Tsqlite3_destroy_callback); cdecl;
  Fsqlite3_result_text64: procedure (context: psqlite3_context; value: PByte;
    nBytes: int64; destr: Tsqlite3_destroy_callback; encoding: Byte); cdecl;
  Fsqlite3_result_zeroblob: procedure (context: psqlite3_context; n: Integer); cdecl;
  Fsqlite3_result_value: procedure (context: psqlite3_context; value: psqlite3_value); cdecl;

  Fsqlite3_column_count: function(stmt: Psqlite3_stmt): Integer; cdecl;
  Fsqlite3_column_name: function(stmt: Psqlite3_stmt; N: Integer)
    : PByte; cdecl;
  Fsqlite3_column_name16: function(stmt: Psqlite3_stmt; N: Integer)
    : PWideChar; cdecl;
  Fsqlite3_column_database_name: function(stmt: Psqlite3_stmt;
    ColumnNum: Integer): PByte; cdecl;
  Fsqlite3_column_database_name16: function(stmt: Psqlite3_stmt;
    ColumnNum: Integer): PWideChar; cdecl;
  Fsqlite3_column_table_name: function(stmt: Psqlite3_stmt; ColumnNum: Integer)
    : PByte; cdecl;
  Fsqlite3_column_table_name16: function(stmt: Psqlite3_stmt;
    ColumnNum: Integer): PWideChar; cdecl;
  Fsqlite3_column_origin_name: function(stmt: Psqlite3_stmt;
    ColumnNum: Integer): PByte; cdecl;
  Fsqlite3_column_origin_name16: function(stmt: Psqlite3_stmt;
    ColumnNum: Integer): PChar; cdecl;
  Fsqlite3_column_decltype: function(stmt: Psqlite3_stmt; ColumnNum: Integer)
    : PByte; cdecl;
  Fsqlite3_column_decltype16: function(stmt: Psqlite3_stmt; ColumnNum: Integer)
    : PWideChar; cdecl;
  Fsqlite3_column_blob: function(stmt: Psqlite3_stmt; iCol: Integer)
    : Pointer; cdecl;
  Fsqlite3_column_bytes: function(stmt: Psqlite3_stmt; iCol: Integer)
    : Integer; cdecl;
  Fsqlite3_column_bytes16: function(stmt: Psqlite3_stmt; iCol: Integer)
    : Integer; cdecl;
  Fsqlite3_column_double: function(stmt: Psqlite3_stmt; iCol: Integer)
    : Double; cdecl;
  Fsqlite3_column_int: function(stmt: Psqlite3_stmt; iCol: Integer)
    : Integer; cdecl;
  Fsqlite3_column_int64: function(stmt: Psqlite3_stmt; iCol: Integer)
    : Int64; cdecl;
  Fsqlite3_column_text: function(stmt: Psqlite3_stmt; iCol: Integer)
    : PByte; cdecl;
  Fsqlite3_column_text16: function(stmt: Psqlite3_stmt; iCol: Integer)
    : PWideChar; cdecl;
  Fsqlite3_column_type: function(stmt: Psqlite3_stmt; iCol: Integer)
    : Integer; cdecl;
  Fsqlite3_column_value: function(stmt: Psqlite3_stmt; iCol: Integer): sqlite3_value; cdecl;
  Fsqlite3_finalize: function(pStmt: Psqlite3_stmt): Integer; cdecl;
  Fsqlite3_reset: function(pStmt: Psqlite3_stmt): Integer; cdecl;

  Fsqlite3_create_function: function (db: psqlite3; zFunctionName: PByte;
    nArg: Integer; eTextRep: Integer; pApp: Pointer; xFunc: Tsqlite3_func_callback;
    xStep: Tsqlite3_step_callback; xFinal: Tsqlite3_final_callback): Integer; cdecl;
  Fsqlite3_create_function16: function (db: psqlite3; zFunctionName: PByte;
    nArg: Integer; eTextRep: Integer; pApp: Pointer; xFunc: Tsqlite3_func_callback;
    xStep: Tsqlite3_step_callback; xFinal: Tsqlite3_final_callback): Integer; cdecl;

  Fsqlite3_create_function_v2: function (db: psqlite3; zFunctionName: PByte;
    nArg: Integer; eTextRep: Integer; pApp: Pointer; xFunc: Tsqlite3_func_callback;
    xStep: Tsqlite3_step_callback; xFinal: Tsqlite3_final_callback;xdestroy: Tsqlite3_destroy_callback): Integer; cdecl;

  // 参数绑定函数
  Fsqlite3_bind_blob: function(Statement: Psqlite3_stmt; Index: Integer;
    Value: Pointer; N: Integer; Proc: TBindDestructor): Integer; cdecl;
  Fsqlite3_bind_double: function(Statement: Psqlite3_stmt; Index: Integer;
    Value: Double): Integer; cdecl;
  Fsqlite3_bind_int: function(pStmt: Psqlite3_stmt; Index: Integer;
    Value: Integer): Integer; cdecl;
  Fsqlite3_bind_int64: function(pStmt: Psqlite3_stmt; Index: Integer;
    Value: Int64): Integer; cdecl;
  Fsqlite3_bind_null: function(pStmt: Psqlite3_stmt; Index: Integer)
    : Integer; cdecl;
  Fsqlite3_bind_text: function(pStmt: Psqlite3_stmt; Index: Integer;
    Value: PByte; N: Integer; Proc: TBindDestructor): Integer; cdecl;
  Fsqlite3_bind_text16: function(pStmt: Psqlite3_stmt; Index: Integer;
    Value: PWideChar; N: Integer; Proc: TBindDestructor): Integer; cdecl;
  Fsqlite3_bind_value: function(pStmt: Psqlite3_stmt; Index: Integer;
    Value: sqlite3_value): Integer; cdecl;
  Fsqlite3_bind_zeroblob: function(pStmt: Psqlite3_stmt; Index, N: Integer)
    : Integer; cdecl;
  Fsqlite3_bind_parameter_count: function(pStmt: Psqlite3_stmt)
    : Integer; cdecl;
  Fsqlite3_bind_parameter_name: function(pStmt: Psqlite3_stmt;
    ParamNum: Integer): PByte; cdecl;
  Fsqlite3_bind_parameter_index: function(pStmt: Psqlite3_stmt;
    zName: PByte): Integer; cdecl;

  Fsqlite3_step: function(pStmt: Psqlite3_stmt): Integer; cdecl;
  Fsqlite3_data_count: function(pStmt: Psqlite3_stmt): Integer; cdecl;

  Fsqlite3_close: function(pDb: PSqlite3): Integer; cdecl;
  Fsqlite3_free: procedure(APtr: Pointer); cdecl;
  Fsqlite3_user_data: function(context: psqlite3_context): Pointer; cdecl;
implementation
{$IFDEF VER280Higher}
  {$IfNDef MSWINDOWS}
   const SqliteLib = 'libsqlite.a';
  {$ELSE}
    {$IFDEF WIn32}
     const SqliteLib = 'sqlite3_x86.obj';
    {$ELSE}
     const SqliteLib = 'sqlite3_x64.obj';
    {$ENDIF}
  {$ENDIF}
  function sqlite3_exec(pDb: PSqlite3; sql: PByte;
      Callback: TSqlite3ExecCallback; CallbackArg: Pointer; ErrMsg: PPChar)
      : Integer; cdecl;external SqliteLib;
{$ENDIF}
{$IFDEF CompressMem}uses Zlib;{$ENDIF}

{$IFNDEF VER280Higher}
var
  MemDllHandle: THandle;
  MemBuffStream: TCustomMemoryStream;
{$ENDIF}

procedure InitSqliteFuncs;
{$IFNDEF VER280Higher and CompressMem}
var
  resStream: TResourceStream;
{$ENDIF}
begin
  {$IFDEF VER280Higher}
  with TSQLiteLib.Create do
  begin
    Load('','');
    Free;
  end;
  @Fsqlite3_open := @FireDAC.Phys.SQLiteCli.sqlite3_open;
  @Fsqlite3_open_v2 := @FireDAC.Phys.SQLiteCli.sqlite3_open_v2;
  @Fsqlite3_open16 := @FireDAC.Phys.SQLiteCli.sqlite3_open16;

  @Fsqlite3_exec := nil;
  @Fsqlite3_errmsg := @FireDAC.Phys.SQLiteCli.sqlite3_errmsg;
  @Fsqlite3_errmsg16 := @FireDAC.Phys.SQLiteCli.sqlite3_errmsg16;



  @Fsqlite3_close := @FireDAC.Phys.SQLiteCli.sqlite3_close;
  @Fsqlite3_free := @FireDAC.Phys.SQLiteCli.sqlite3_free;

  @Fsqlite3_column_count := @FireDAC.Phys.SQLiteCli.sqlite3_column_count;
  @Fsqlite3_column_name := @FireDAC.Phys.SQLiteCli.sqlite3_column_name;
  @Fsqlite3_column_name16 := @FireDAC.Phys.SQLiteCli.sqlite3_column_name16;
  @Fsqlite3_column_database_name := @FireDAC.Phys.SQLiteCli.sqlite3_column_database_name;
  @Fsqlite3_column_database_name16 := @FireDAC.Phys.SQLiteCli.sqlite3_column_database_name16;
  @Fsqlite3_column_table_name := @FireDAC.Phys.SQLiteCli.sqlite3_column_table_name;
  @Fsqlite3_column_table_name16 := @FireDAC.Phys.SQLiteCli.sqlite3_column_table_name16;

  @Fsqlite3_column_origin_name := @FireDAC.Phys.SQLiteCli.sqlite3_column_origin_name;
  @Fsqlite3_column_origin_name16 := @FireDAC.Phys.SQLiteCli.sqlite3_column_origin_name16;
  @Fsqlite3_column_decltype := @FireDAC.Phys.SQLiteCli.sqlite3_column_decltype;
  @Fsqlite3_column_decltype16 := @FireDAC.Phys.SQLiteCli.sqlite3_column_decltype16;
  @Fsqlite3_column_blob := @FireDAC.Phys.SQLiteCli.sqlite3_column_blob;
  @Fsqlite3_column_bytes := @FireDAC.Phys.SQLiteCli.sqlite3_column_bytes;
  @Fsqlite3_column_bytes16 := @FireDAC.Phys.SQLiteCli.sqlite3_column_bytes16;
  @Fsqlite3_column_double := @FireDAC.Phys.SQLiteCli.sqlite3_column_double;
  @Fsqlite3_column_int := @FireDAC.Phys.SQLiteCli.sqlite3_column_int;
  @Fsqlite3_column_int64 := @FireDAC.Phys.SQLiteCli.sqlite3_column_int64;
  @Fsqlite3_column_text := @FireDAC.Phys.SQLiteCli.sqlite3_column_text;
  @Fsqlite3_column_text16 := @FireDAC.Phys.SQLiteCli.sqlite3_column_text16;
  @Fsqlite3_column_type := @FireDAC.Phys.SQLiteCli.sqlite3_column_type;
  @Fsqlite3_column_value := @FireDAC.Phys.SQLiteCli.sqlite3_column_value;
  @Fsqlite3_finalize := @FireDAC.Phys.SQLiteCli.sqlite3_finalize;
  @Fsqlite3_reset := @FireDAC.Phys.SQLiteCli.sqlite3_reset;

  @Fsqlite3_create_function := @FireDAC.Phys.SQLiteCli.sqlite3_create_function;
  @Fsqlite3_create_function16 := @FireDAC.Phys.SQLiteCli.sqlite3_create_function16;
  @Fsqlite3_create_function_v2 := nil;//@FireDAC.Phys.SQLiteCli.sqlite3_create_function_v2;


  @Fsqlite3_prepare := @FireDAC.Phys.SQLiteCli.sqlite3_prepare;
  @Fsqlite3_prepare_v2 := @FireDAC.Phys.SQLiteCli.sqlite3_prepare_v2;
  @Fsqlite3_prepare16 := @FireDAC.Phys.SQLiteCli.sqlite3_prepare16;
  @Fsqlite3_prepare16_v2 := @FireDAC.Phys.SQLiteCli.sqlite3_prepare16_v2;
  @Fsqlite3_table_column_metadata := @FireDAC.Phys.SQLiteCli.sqlite3_table_column_metadata;
  @Fsqlite3_key := @FireDAC.Phys.SQLiteCli.sqlite3_key;
  @Fsqlite3_rekey := @FireDAC.Phys.SQLiteCli.sqlite3_rekey;


  @Fsqlite3_value_blob := @FireDAC.Phys.SQLiteCli.sqlite3_value_blob;
  @Fsqlite3_value_bytes := @FireDAC.Phys.SQLiteCli.sqlite3_value_bytes;
  @Fsqlite3_value_bytes16 := @FireDAC.Phys.SQLiteCli.sqlite3_value_bytes16;
  @Fsqlite3_value_double := @FireDAC.Phys.SQLiteCli.sqlite3_value_double;
  @Fsqlite3_value_int := @FireDAC.Phys.SQLiteCli.sqlite3_value_int;
  @Fsqlite3_value_int64 := @FireDAC.Phys.SQLiteCli.sqlite3_value_int64;
  @Fsqlite3_value_text16 := @FireDAC.Phys.SQLiteCli.sqlite3_value_text16;
  @Fsqlite3_value_text16le := nil;
  @Fsqlite3_value_text16be := nil;
  @Fsqlite3_value_type := @FireDAC.Phys.SQLiteCli.sqlite3_value_type;
  @Fsqlite3_value_numeric_type := @FireDAC.Phys.SQLiteCli.sqlite3_value_numeric_type;

  @Fsqlite3_result_blob := @FireDAC.Phys.SQLiteCli.sqlite3_result_blob;
  @Fsqlite3_result_blob64 := {$IFDEF VER280}nil{$ELSE}@FireDAC.Phys.SQLiteCli.sqlite3_result_blob64{$ENDIF};
  @Fsqlite3_result_double := @FireDAC.Phys.SQLiteCli.sqlite3_result_double;
  @Fsqlite3_result_error16 := @FireDAC.Phys.SQLiteCli.sqlite3_result_error16;
  @Fsqlite3_result_error_code := @FireDAC.Phys.SQLiteCli.sqlite3_result_error_code;
  @Fsqlite3_result_int64 := @FireDAC.Phys.SQLiteCli.sqlite3_result_int64;
  @Fsqlite3_result_null := @FireDAC.Phys.SQLiteCli.sqlite3_result_null;
  @Fsqlite3_result_text16 := @FireDAC.Phys.SQLiteCli.sqlite3_result_text16;
  @Fsqlite3_result_text64 := {$IFDEF VER280}nil{$ELSE}@FireDAC.Phys.SQLiteCli.sqlite3_result_text64{$ENDIF};
  @Fsqlite3_result_zeroblob := @FireDAC.Phys.SQLiteCli.sqlite3_result_zeroblob;
  @Fsqlite3_result_value := @FireDAC.Phys.SQLiteCli.sqlite3_result_value;

  @Fsqlite3_bind_blob := @FireDAC.Phys.SQLiteCli.sqlite3_bind_blob;
  @Fsqlite3_bind_double := @FireDAC.Phys.SQLiteCli.sqlite3_bind_double;
  @Fsqlite3_bind_int := @FireDAC.Phys.SQLiteCli.sqlite3_bind_int;
  @Fsqlite3_bind_int64 := @FireDAC.Phys.SQLiteCli.sqlite3_bind_int64;
  @Fsqlite3_bind_null := @FireDAC.Phys.SQLiteCli.sqlite3_bind_null;
  @Fsqlite3_bind_text := @FireDAC.Phys.SQLiteCli.sqlite3_bind_text;
  @Fsqlite3_bind_text16 := @FireDAC.Phys.SQLiteCli.sqlite3_bind_text16;
  @Fsqlite3_bind_value := @FireDAC.Phys.SQLiteCli.sqlite3_bind_value;
  @Fsqlite3_bind_zeroblob := @FireDAC.Phys.SQLiteCli.sqlite3_bind_zeroblob;
  @Fsqlite3_bind_parameter_count := @FireDAC.Phys.SQLiteCli.sqlite3_bind_parameter_count;
  @Fsqlite3_bind_parameter_name := @FireDAC.Phys.SQLiteCli.sqlite3_bind_parameter_name;
  @Fsqlite3_bind_parameter_index := @FireDAC.Phys.SQLiteCli.sqlite3_bind_parameter_index;

  @Fsqlite3_step := @FireDAC.Phys.SQLiteCli.sqlite3_step;
  @Fsqlite3_data_count := nil;
  @Fsqlite3_user_data := @FireDAC.Phys.SQLiteCli.sqlite3_user_data;
  {$ELSE}
  {$IFDEF CompressMem}
  resStream := TResourceStream.Create(HInstance,'Sqlite3',RT_RCDATA);
  MemBuffStream := TMemoryStream.Create;
  ZDecompressStream(resStream,MemBuffStream);
  resStream.free;
  {$ELSE}
  MemBuffStream := TResourceStream.Create(HInstance,'Sqlite3',RT_RCDATA);
  {$ENDIF}
  MemDllHandle := MemLoadLibrary(MemBuffStream.Memory);

  Fsqlite3_open := MemGetProcAddress(MemDllHandle, 'sqlite3_open');
  Fsqlite3_open_v2 := MemGetProcAddress(MemDllHandle, 'sqlite3_open_v2');
  Fsqlite3_open16 := MemGetProcAddress(MemDllHandle, 'sqlite3_open16');

  Fsqlite3_exec := MemGetProcAddress(MemDllHandle, 'sqlite3_exec');
  Fsqlite3_errmsg := MemGetProcAddress(MemDllHandle, 'sqlite3_errmsg');
  Fsqlite3_errmsg16 := MemGetProcAddress(MemDllHandle, 'sqlite3_errmsg16');
  Fsqlite3_close := MemGetProcAddress(MemDllHandle, 'sqlite3_close');
  Fsqlite3_free := MemGetProcAddress(MemDllHandle, 'sqlite3_free');

  Fsqlite3_column_count := MemGetProcAddress(MemDllHandle, 'sqlite3_column_count');
  Fsqlite3_column_name := MemGetProcAddress(MemDllHandle, 'sqlite3_column_name');
  Fsqlite3_column_name16 := MemGetProcAddress(MemDllHandle, 'sqlite3_column_name16');
  Fsqlite3_column_database_name := MemGetProcAddress(MemDllHandle,
    'sqlite3_column_database_name');
  Fsqlite3_column_database_name16 := MemGetProcAddress(MemDllHandle,
    'sqlite3_column_database_name16');
  Fsqlite3_column_table_name := MemGetProcAddress(MemDllHandle,
    'sqlite3_column_table_name');
  Fsqlite3_column_table_name16 := MemGetProcAddress(MemDllHandle,
    'sqlite3_column_table_name16');

  Fsqlite3_column_origin_name := MemGetProcAddress(MemDllHandle,
    'sqlite3_column_origin_name');
  Fsqlite3_column_origin_name16 := MemGetProcAddress(MemDllHandle,
    'sqlite3_column_origin_name16');
  Fsqlite3_column_decltype := MemGetProcAddress(MemDllHandle, 'sqlite3_column_decltype');
  Fsqlite3_column_decltype16 := MemGetProcAddress(MemDllHandle,
    'sqlite3_column_decltype16');
  Fsqlite3_column_blob := MemGetProcAddress(MemDllHandle, 'sqlite3_column_blob');
  Fsqlite3_column_bytes := MemGetProcAddress(MemDllHandle, 'sqlite3_column_bytes');
  Fsqlite3_column_bytes16 := MemGetProcAddress(MemDllHandle, 'sqlite3_column_bytes16');
  Fsqlite3_column_double := MemGetProcAddress(MemDllHandle, 'sqlite3_column_double');
  Fsqlite3_column_int := MemGetProcAddress(MemDllHandle, 'sqlite3_column_int');
  Fsqlite3_column_int64 := MemGetProcAddress(MemDllHandle, 'sqlite3_column_int64');
  Fsqlite3_column_text := MemGetProcAddress(MemDllHandle, 'sqlite3_column_text');
  Fsqlite3_column_text16 := MemGetProcAddress(MemDllHandle, 'sqlite3_column_text16');
  Fsqlite3_column_type := MemGetProcAddress(MemDllHandle, 'sqlite3_column_type');
  Fsqlite3_column_value := MemGetProcAddress(MemDllHandle, 'sqlite3_column_value');
  Fsqlite3_finalize := MemGetProcAddress(MemDllHandle, 'sqlite3_finalize');
  Fsqlite3_reset := MemGetProcAddress(MemDllHandle, 'sqlite3_reset');

  Fsqlite3_create_function := MemGetProcAddress(MemDllHandle, 'sqlite3_create_function');
  Fsqlite3_create_function16 := MemGetProcAddress(MemDllHandle, 'sqlite3_create_function16');
  Fsqlite3_create_function_v2 := MemGetProcAddress(MemDllHandle, 'sqlite3_create_function_v2');


  Fsqlite3_prepare := MemGetProcAddress(MemDllHandle, 'sqlite3_prepare');
  Fsqlite3_prepare_v2 := MemGetProcAddress(MemDllHandle, 'sqlite3_prepare_v2');
  Fsqlite3_prepare16 := MemGetProcAddress(MemDllHandle, 'sqlite3_prepare16');
  Fsqlite3_prepare16_v2 := MemGetProcAddress(MemDllHandle, 'sqlite3_prepare16_v2');
  Fsqlite3_table_column_metadata := MemGetProcAddress(MemDllHandle,
    'sqlite3_table_column_metadata');
  Fsqlite3_key := MemGetProcAddress(MemDllHandle, 'sqlite3_key');
  Fsqlite3_rekey := MemGetProcAddress(MemDllHandle, 'sqlite3_rekey');


  Fsqlite3_value_blob := MemGetProcAddress(MemDllHandle,'sqlite3_value_bloba');
  Fsqlite3_value_bytes := MemGetProcAddress(MemDllHandle,'sqlite3_value_bytes');
  Fsqlite3_value_bytes16 := MemGetProcAddress(MemDllHandle,'sqlite3_value_bytes16');
  Fsqlite3_value_double := MemGetProcAddress(MemDllHandle,'sqlite3_value_double');
  Fsqlite3_value_int := MemGetProcAddress(MemDllHandle,'sqlite3_value_int');
  Fsqlite3_value_int64 := MemGetProcAddress(MemDllHandle,'sqlite3_value_int64');
  Fsqlite3_value_text16 := MemGetProcAddress(MemDllHandle,'sqlite3_value_text16');
  Fsqlite3_value_text16le := MemGetProcAddress(MemDllHandle,'sqlite3_value_text16le');
  Fsqlite3_value_text16be := MemGetProcAddress(MemDllHandle,'sqlite3_value_text16be');
  Fsqlite3_value_type := MemGetProcAddress(MemDllHandle,'sqlite3_value_type');
  Fsqlite3_value_numeric_type := MemGetProcAddress(MemDllHandle,'sqlite3_value_numeric_type');

  Fsqlite3_result_blob := MemGetProcAddress(MemDllHandle,'sqlite3_result_blob');
  Fsqlite3_result_blob64 := MemGetProcAddress(MemDllHandle,'sqlite3_result_blob64');
  Fsqlite3_result_double := MemGetProcAddress(MemDllHandle,'sqlite3_result_double');
  Fsqlite3_result_error16 := MemGetProcAddress(MemDllHandle,'sqlite3_result_error16');
  Fsqlite3_result_error_code := MemGetProcAddress(MemDllHandle,'sqlite3_result_error_code');
  Fsqlite3_result_int64 := MemGetProcAddress(MemDllHandle,'sqlite3_result_int64');
  Fsqlite3_result_null := MemGetProcAddress(MemDllHandle,'sqlite3_result_null');
  Fsqlite3_result_text16 := MemGetProcAddress(MemDllHandle,'sqlite3_result_text16');
  Fsqlite3_result_text64 := MemGetProcAddress(MemDllHandle,'sqlite3_result_text64');
  Fsqlite3_result_zeroblob := MemGetProcAddress(MemDllHandle,'sqlite3_result_zeroblob');
  Fsqlite3_result_value := MemGetProcAddress(MemDllHandle,'sqlite3_result_value');

  Fsqlite3_bind_blob := MemGetProcAddress(MemDllHandle, 'sqlite3_bind_blob');
  Fsqlite3_bind_double := MemGetProcAddress(MemDllHandle, 'sqlite3_bind_double');
  Fsqlite3_bind_int := MemGetProcAddress(MemDllHandle, 'sqlite3_bind_int');
  Fsqlite3_bind_int64 := MemGetProcAddress(MemDllHandle, 'sqlite3_bind_int64');
  Fsqlite3_bind_null := MemGetProcAddress(MemDllHandle, 'sqlite3_bind_null');
  Fsqlite3_bind_text := MemGetProcAddress(MemDllHandle, 'sqlite3_bind_text');
  Fsqlite3_bind_text16 := MemGetProcAddress(MemDllHandle, 'sqlite3_bind_text16');
  Fsqlite3_bind_value := MemGetProcAddress(MemDllHandle, 'sqlite3_bind_value');
  Fsqlite3_bind_zeroblob := MemGetProcAddress(MemDllHandle, 'sqlite3_bind_zeroblob');
  Fsqlite3_bind_parameter_count := MemGetProcAddress(MemDllHandle,
    'sqlite3_bind_parameter_count');
  Fsqlite3_bind_parameter_name := MemGetProcAddress(MemDllHandle,
    'sqlite3_bind_parameter_name');
  Fsqlite3_bind_parameter_index := MemGetProcAddress(MemDllHandle,
    'sqlite3_bind_parameter_index');

  Fsqlite3_step := MemGetProcAddress(MemDllHandle, 'sqlite3_step');
  Fsqlite3_data_count := MemGetProcAddress(MemDllHandle, 'sqlite3_data_count');
  Fsqlite3_user_data := MemGetProcAddress(MemDllHandle, 'sqlite3_user_data');
  {$ENDIF}
end;

initialization
  InitSqliteFuncs;
finalization
  {$IFNDEF VER280Higher}
  MemFreeLibrary(MemDllHandle);
  MemBuffStream.Free;
  {$ENDIF}
end.
