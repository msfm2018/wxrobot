unit qdb;

interface

{$I 'qdac.inc'}

{
  Todo:2015.7.16
  =========
  1.QDB 在字段列表太多时，效率会明显下降(五月光报告）
  2.QDB
  Changes:
  2017.6.13
  ==========
  * 修正了TQProvider没有监听数据集对应的释放造成的AV错误（云大第一菜籽报告）

  2015.12.14
  ==========
  * 修正了 SetRecNo 没有正确定位到指定位置的问题(蜗牛也是牛报告）

  2015.12.7
  ==========
  * 修正了 SetRecNo 时比较值时忘记加一的问题(tgwang报告）
  + 增加对设计器通过编辑字段设计表的支持(易度变和建议）

  2015.12.6
  ==========
  * 修正了与 2007 的兼容问题（蜗牛也是牛报告）

  2015.11.14
  ==========
  * 修正了使用表达式过滤时，TQFilterExp 析构时 FValue 没有清理造成的内存泄露（阿木报告）

  2015.11.10
  ==========
  * 修正了CopyFrom模式为dcmView和dcmFiltered时，如果数据是过滤过的数据时出错的问题（幽灵报告）

  2015.10.21
  ==========
  * 修正了OpenDataSet在脚本没返回结果集时未抛出错误的问题

  2015.10.20
  ==========
  * 修正了AddResultSet对多数据集支持时未修改FActiveFieldDefs造成出错的问题（不得闲报告）
  * 修正了AddResultSet未检查当前结果集字段是否已有字段信息的问题

  2015.10.15
  ===========
  * 修正了CloneSourceEdit没有处理克隆的数据集内容编辑完成时，没有到过滤和排序进行处理的问题
  * 修正了TQRecords.Delete删除时没有标记索引信息脏的问题

  2015.10.13
  ==========
  * 修正了 CopyFrom 时，如果设置了分页，且复制模式为dcmView时，复制的不是当前页内容的问题（幽灵报告）
  2015.10.12
  ==========
  * 修正了 ApplyChanges 合并变更内容时，未重置记录的 FChangedIndex 造成的问题（AK47报告）
  2015.10.10
  ==========
  * 将 TQSocketProvider 从 qprov_pgsql 移入此单元
  + 合并不得闲编写的 TQLibProvider

  2015.9.10
  =========
  * 修正了克隆的数据集 Records 列表由于未指向原始结果集，造成访问可能存在问题（阿木报告）
  * 修正了 SaveToStream 函数中，usUnmodified 错误的写成usModified的问题（阿木报告）
  * 修正了连接数据库用CommandText+Open方法直接打开数据集出错时未抛出异常的问题；
  * 修正了连接数据库直接提交时出现AV错误的问题
  * 修正 Provider OpenDataSet 函数同步打开判定标志位错误的问题

  2015.9.9
  =========
  * 修正了 TQDataSet 在克隆的数据集时过滤时出错的问题（阿木报告）
  2015.9.1
  =========
  + 支持先设置 Provider 和 CommandText 再调用 Open 打开数据集的方式（AK47、空、ijia建议）

  2015.8.30
  =========
  * 修正了 InternalSetData 时AsTime对时间类型的处理错误（阿木报告）
  2015.7.31
  =========
  * 修正了克隆的数据集编辑时出错的问题（阿木报告）
  * 修正了将Owner为其它数据源的数据集加入到数据集列表后，退出时出错的问题（阿木报告）
  2015.7.30
  =========
  * 修正了 CreateFieldsByUser 在使用 TFields.LifeCycle 时的判定算法错误（AK47报告）
  2015.7.22
  ---------
  * 修正了Blob数据无清正确清除的问题（感谢ijia报告)
}
uses classes, sysutils, types, RTLConsts, qstring, qrbtree, qdigest, qworker,
  qsimplepool, db, fmtbcd, dbcommon, SqlTimSt, variants, syncobjs, dateutils,
  qtimetypes, qvalue, qmacros
{$IFDEF MSWINDOWS},
  windows, winsock
{$ELSE}
    , Posix.Base, Posix.Stdio, Posix.Pthread, Posix.UniStd, System.IOUtils,
{$WARN UNIT_PLATFORM OFF}Posix.StrOpts, {$WARN UNIT_PLATFORM ON}
  Posix.NetDB, Posix.SysSocket, Posix.NetinetIn, Posix.arpainet,
  Posix.SysSelect,
  Posix.Systime
{$ENDIF}
{$IFDEF LINUX}
    , Linuxapi.KernelIoctl
{$ENDIF}
{$IFDEF UNICODE}
    , Generics.Collections
{$ENDIF}
{$IF RTLVersion<22}// 2007-2010
    , PerlRegEx, pcre
{$ELSE}
    , RegularExpressionsCore
{$IFEND}
    ;

const
  // 数据库架构对象定义
  SCHEMA_DATABASE = $4000000; // 数据库
  SCHEMA_SCHEMA = $20000000; // 元数据定义
  SCHEMA_TABLE = $10000000; // 数据表
  SCHEMA_COLUMN = $08000000; // 数据列
  SCHEMA_TYPE = $04000000; // 数据类型
  SCHEMA_METATYPE = $FF000000; // 元数据类型
  // 数据列属性定义
  SCHEMA_ISINDEX = $00000001; // 索引
  SCHEMA_ISPRIMARY = $00000002; // 主键
  SCHEMA_NULLABLE = $000000004; // 允许为空
  SCHEMA_ISFIXED = $00000008; // 固定长度
  SCHEMA_AUTOINC = $00000010; // 自动增加
  SCHEMA_VISIBLE = $00000020; // 列是否可见
  SCHEMA_READONLY = $00000040; // 列是否只读
  SCHEMA_UNNAMED = $00000080; // 未命名列
  SCHEMA_CALC = $00000100; // 内部计算列
  SCHEMA_ARRAY = $00000200; // 数组类型
  SCHEMA_INWHERE = $00000400; // 可在Where条件中使用，用于更新或删除数据
  SCHEMA_UNIQUE = $00000800; // 唯一约束
  SCHEMA_HASDEFAULT = $00001000; // 拥有默认值定义
  SCHEMA_COLUMNATTR = $00001FFF; // 列属性掩码

  // SQL数据类型(32位整数代表数据类型,高16位为掩码，低16位为类型编码)
  SQL_MASK_COMPLEX = $80000000;
  SQL_MASK_NUMERIC = $40000000; // 数值类型ID的掩码
  SQL_MASK_FIXEDSIZE = $20000000; // 固定大小
  SQL_MASK_INTEGER = SQL_MASK_NUMERIC OR SQL_MASK_FIXEDSIZE OR $10000000;
  // 是一个整数类型
  SQL_MASK_UNSIGNED = SQL_MASK_INTEGER OR $08000000; // 无符号类型
  SQL_MASK_FLOAT = SQL_MASK_NUMERIC OR SQL_MASK_FIXEDSIZE; // 浮点数
  SQL_MASK_SPEC = $04000000; // 是特定数据特有类型，如PostgreSQL的特定类型
  SQL_MASK_ARRAY = $02000000; // 是数组的一部分
  SQL_MASK_BINARY = $01000000; // 是二进制数据类型
  SQL_MASK_AUTOINC = SQL_MASK_INTEGER OR $00800000; // 是自增的序列
  SQL_MASK_CHAR = $00400000; // 字符
  SQL_MASK_TIME = SQL_MASK_FIXEDSIZE OR $00200000; // 日期时间类型
  SQL_MASK_LONGSIZE = $00100000; // 长长度类型

  // 字符
  SQL_BASE_CHAR = $00000001; // ANSI字符
  SQL_BASE_WIDECHAR = $00000002; // Unicode字符
  // 整数
  SQL_BASE_BYTE = $00000003; // 单字节
  SQL_BASE_WORD = $00000004; // 双字节
  SQL_BASE_DWORD = $00000005; // 四字节
  SQL_BASE_QWORD = $00000006; // 八字节

  // 浮点数
  SQL_BASE_SINGLE = $00000007; // 单精度浮点值
  SQL_BASE_DOUBLE = $00000008; // 双精度浮点值
  SQL_BASE_EXTENDED = $00000009; // 扩展浮点类型
  SQL_BASE_BCD = $0000000A; // BCD类型
  SQL_BASE_SMALLMONEY = $0000000B; // 短货币
  SQL_BASE_MONEY = $0000000C; // 长货币

  SQL_BASE_BOOLEAN = $0000000D; // 布尔
  SQL_BASE_UUID = $0000000E; // UUID类型
  SQL_BASE_BIT = $0000000F; // 位类型

  // 日期时间
  SQL_BASE_TIME = $00000010; // 时间类型
  SQL_BASE_DATE = $00000011; // 日期类型
  SQL_BASE_SMALLDATETIME = $00000012; // 短日期时间类型
  SQL_BASE_DATETIME = $00000013; // 日期时间类型
  SQL_BASE_INTERVAL = $00000014; // 时间间隔
  SQL_BASE_TIMEOFFSET = $00000015; // 时间偏移
  SQL_BASE_TIMESTAMP = $00000016; // 时间戳

  SQL_BASE_BINARY = $00000017; // 二进制
  // 扩展的类型
  SQL_BASE_PICTURE = $00000018; // 图片（好吧，这个实际上仅早期的少数数据库支持，实际不会用到）
  SQL_BASE_STREAM = $00000019; // 数据流
  SQL_BASE_XML = $0000001A; // XML数据
  SQL_BASE_JSON = $0000001B; // JSON数据

  SQL_BASE_OID = $0000001C; // OID
  SQL_BASE_POINT = $0000001D; // 点
  SQL_BASE_LINE = $0000001E; // 线
  SQL_BASE_LSEG = $0000001F; // 线段
  SQL_BASE_BOX = $00000020; // 矩形
  SQL_BASE_PATH = $00000021; // 路径
  SQL_BASE_POLYGON = $00000022; // 多边形
  SQL_BASE_CIRCLE = $00000023; // 圆
  SQL_BASE_CIDR = $00000024; // 可以带掩码IP地址
  SQL_BASE_INET = $00000025; // IP
  SQL_BASE_MACADDR = $00000026; // 网卡物理地址
  SQL_BASE_ROWS = $00000027; // 行集(记录集)
  SQL_BASE_ACL = $00000028; // 访问控制列表
  SQL_BASE_DATASET = $00000029; // 数据集
  SQL_BASE_CURSOR = $0000002A; // 游标
  SQL_BASE_VARIANT = $0000002B; // 变体
  SQL_BASE_INTERFACE = $0000002C; // 接口
  SQL_BASE_IDISPATCH = $0000002D; // IDispatch
  SQL_BASE_OBJECT = $0000002E; // 对象
  SQL_BASE_PARAMS = $0000002F; // 参数
  SQL_BASE_CONNECTION = $00000030; // 连接
  SQL_BASE_OLE = $00000031; // OLE对象，用OLESave和OLELoad保存和加载
  SQL_BASE_POINTER = $00000032; // 指针引用
  SQL_BASE_ENUM = $00000033; // 枚举
  SQL_BASE_SET = $00000034; // 集合
  SQL_BASE_TSVECTOR = $00000035; // 全文检索向量
  SQL_BASE_TSQUERY = $00000036; // 全文检索查询
  SQL_BASE_TREE = $00000037; // 树
  SQL_BASE_ADT = $00000027; // 高级数据类型，用户在服务器端定义的数据类型
  // 基本类型

  SQL_UNKNOWN = $00000000; // 未知类型

  // 整数类型
  SQL_TINYINT = SQL_MASK_INTEGER OR SQL_BASE_BYTE; // -128-127
  SQL_BYTE = SQL_TINYINT OR SQL_MASK_UNSIGNED; // 0-255
  SQL_SMALLINT = SQL_MASK_INTEGER OR SQL_BASE_WORD; // 有符号的-32768-32767
  SQL_WORD = SQL_SMALLINT OR SQL_MASK_UNSIGNED; // 无符号整数，0-65535
  SQL_INTEGER = SQL_MASK_INTEGER OR SQL_BASE_DWORD; // 有符号的32位整数
  SQL_DWORD = SQL_INTEGER OR SQL_MASK_UNSIGNED; // 无符号的32位整数
  SQL_INT64 = SQL_MASK_INTEGER OR SQL_BASE_QWORD; // 有符号的64位整数
  SQL_QWORD = SQL_INT64 OR SQL_MASK_UNSIGNED; // 无符号的64位整数
  SQL_SMALLSERIAL = SQL_SMALLINT OR SQL_MASK_AUTOINC; // 16位自增
  SQL_SERIAL = SQL_INTEGER OR SQL_MASK_AUTOINC; // 32位自增序列
  SQL_BIGSERIAL = SQL_INT64 OR SQL_MASK_AUTOINC; // 64位自增序列

  // 浮点类型
  SQL_SINGLE = SQL_MASK_FLOAT OR SQL_BASE_DWORD OR SQL_BASE_SINGLE; // 有符号的32位实数
  SQL_FLOAT = SQL_MASK_FLOAT OR SQL_BASE_QWORD OR SQL_BASE_DOUBLE; // 有符号的64位实数
  SQL_BCD = SQL_MASK_FLOAT OR SQL_BASE_BCD; // 有符号的任意精度实数
  SQL_NUMERIC = SQL_BCD;
  SQL_MONEY = SQL_MASK_FLOAT OR SQL_BASE_MONEY; // 货币类型
  SQL_SMALLMONEY = SQL_MASK_FLOAT OR SQL_BASE_SMALLMONEY; // 小货币类型
  SQL_EXTENDED = SQL_MASK_FLOAT OR SQL_BASE_EXTENDED;

  // 字符串类型
  SQL_CHAR = SQL_MASK_FIXEDSIZE OR SQL_MASK_CHAR OR SQL_BASE_CHAR; // 固定长度字符串
  SQL_VARCHAR = SQL_MASK_CHAR OR SQL_BASE_CHAR; // 变长字符串
  SQL_WIDECHAR = SQL_MASK_FIXEDSIZE OR SQL_MASK_CHAR OR SQL_BASE_WIDECHAR;
  // 固定长度Unicode字符串
  SQL_WIDEVARCHAR = SQL_MASK_CHAR OR SQL_BASE_WIDECHAR; // 变长Unicode字符串
  SQL_TEXT = SQL_VARCHAR OR SQL_MASK_LONGSIZE; // 文本
  SQL_WIDETEXT = SQL_WIDEVARCHAR OR SQL_MASK_LONGSIZE; // Unicode文本
  SQL_XML = SQL_WIDETEXT OR SQL_BASE_XML;
  SQL_JSON = SQL_WIDETEXT OR SQL_BASE_JSON;
  SQL_TREE = SQL_WIDETEXT OR SQL_BASE_TREE;

  // 二进制数据类型
  SQL_BINARY = SQL_MASK_FIXEDSIZE OR SQL_MASK_BINARY;
  // 二进制数据
  SQL_BYTES = SQL_BINARY or SQL_BASE_BINARY;
  SQL_BIT = SQL_MASK_FIXEDSIZE OR SQL_BASE_BIT OR SQL_MASK_BINARY;
  SQL_VARBIT = SQL_BASE_BIT OR SQL_MASK_BINARY;
  SQL_VARBINARY = SQL_MASK_BINARY or SQL_BASE_BINARY; // 变长二进制数据
  SQL_VARBYTES = SQL_VARBINARY;
  SQL_LARGEOBJECT = SQL_VARBINARY OR SQL_MASK_LONGSIZE; // 大二进制对象(BLOB)
  SQL_PICTURE = SQL_LARGEOBJECT OR SQL_BASE_PICTURE; // 图片数据
  SQL_STREAM = SQL_LARGEOBJECT OR SQL_BASE_STREAM; // 流对象
  SQL_OLE = SQL_LARGEOBJECT OR SQL_BASE_OLE;

  SQL_BOOLEAN = SQL_MASK_FIXEDSIZE OR SQL_BASE_BOOLEAN; // 布尔
  SQL_UUID = SQL_MASK_FIXEDSIZE OR SQL_BASE_UUID;
  SQL_GUID = SQL_UUID;
  SQL_BITS = SQL_BIT;
  SQL_VARBITS = SQL_BASE_BIT;

  // 日期时间类型
  SQL_DATE = SQL_MASK_TIME OR SQL_BASE_DATE; // 日期
  SQL_TIME = SQL_MASK_TIME OR SQL_BASE_TIME; // 时间
  SQL_SMALLDATETIME = SQL_MASK_TIME or SQL_BASE_SMALLDATETIME; // 小日期时间类型
  SQL_DATETIME = SQL_MASK_TIME OR SQL_BASE_DATETIME; // 日期时间
  SQL_TIMESTAMP = SQL_MASK_TIME OR SQL_BASE_TIMESTAMP; // 时间戳
  SQL_INTERVAL = SQL_MASK_TIME OR SQL_BASE_INTERVAL; // 时间间隔
  SQL_TIMEOFFSET = SQL_MASK_TIME OR SQL_BASE_TIMEOFFSET; // 时间偏移

  SQL_DATASET = SQL_MASK_COMPLEX OR SQL_BASE_DATASET; // 数据集
  SQL_CURSOR = SQL_MASK_COMPLEX OR SQL_BASE_CURSOR; // 游标
  SQL_VARIANT = SQL_MASK_COMPLEX OR SQL_BASE_VARIANT; // 变体
  SQL_INTERFACE = SQL_MASK_COMPLEX OR SQL_BASE_INTERFACE; // 接口
  SQL_IDISPATCH = SQL_MASK_COMPLEX OR SQL_BASE_IDISPATCH; // IDispatch
  SQL_OBJECT = SQL_MASK_COMPLEX OR SQL_BASE_OBJECT; // 对象
  SQL_PARAMS = SQL_MASK_COMPLEX OR SQL_BASE_PARAMS; // 参数
  SQL_CONNECTION = SQL_MASK_COMPLEX OR SQL_BASE_CONNECTION; // 连接
  SQL_REFERENCE = SQL_MASK_COMPLEX OR SQL_BASE_POINTER; // 指针引用，这种类型仅在运行时有效
  SQL_ARRAY = SQL_MASK_COMPLEX OR SQL_MASK_ARRAY; // 数组
  SQL_ADT = SQL_MASK_COMPLEX OR SQL_MASK_ARRAY OR SQL_BASE_ADT; // 高级数据类型

  // PostgreSQL类型
  SQL_PG_OID = SQL_MASK_SPEC OR SQL_DWORD OR SQL_MASK_AUTOINC OR SQL_BASE_OID;
  SQL_PG_POINT = SQL_MASK_SPEC OR SQL_MASK_COMPLEX OR SQL_BASE_POINT;
  SQL_PG_LINE = SQL_MASK_SPEC OR SQL_MASK_COMPLEX OR SQL_BASE_LINE;
  SQL_PG_LSEG = SQL_MASK_SPEC OR SQL_MASK_COMPLEX OR SQL_BASE_LSEG;
  SQL_PG_BOX = SQL_MASK_SPEC OR SQL_MASK_COMPLEX OR SQL_BASE_BOX;
  SQL_PG_PATH = SQL_MASK_SPEC OR SQL_MASK_COMPLEX OR SQL_BASE_PATH;
  SQL_PG_POLYGON = SQL_MASK_SPEC OR SQL_MASK_COMPLEX OR SQL_BASE_POLYGON;
  SQL_PG_CIRCLE = SQL_MASK_SPEC OR SQL_MASK_COMPLEX OR SQL_BASE_CIRCLE;
  SQL_PG_CIDR = SQL_MASK_SPEC OR SQL_MASK_COMPLEX OR SQL_BASE_CIDR;
  SQL_PG_INET = SQL_MASK_SPEC OR SQL_MASK_COMPLEX OR SQL_BASE_INET;
  SQL_PG_MACADDR = SQL_MASK_SPEC OR SQL_MASK_COMPLEX OR SQL_BASE_MACADDR;
  SQL_PG_ROWS = SQL_MASK_SPEC OR SQL_MASK_COMPLEX OR SQL_BASE_ROWS;
  SQL_PG_ACL = SQL_MASK_SPEC OR SQL_MASK_COMPLEX OR SQL_BASE_ACL;
  SQL_PG_ENUM = SQL_MASK_SPEC OR SQL_MASK_COMPLEX OR SQL_BASE_ENUM;
  SQL_PG_TSVECTOR = SQL_MASK_SPEC OR SQL_MASK_COMPLEX OR SQL_MASK_CHAR OR
    SQL_BASE_TSVECTOR;
  SQL_PG_TSQUERY = SQL_MASK_SPEC OR SQL_MASK_COMPLEX OR SQL_MASK_CHAR OR
    SQL_BASE_TSQUERY;

  // 已知错误代码
  PROV_ERROR_SQL_EMPTY = $80000001; // 脚本为空
  PROV_EEROR_RESULT_EMPTY = $80000002; // 结果集为空
  PROV_DRIVER_NOT_FOUND = $80000003; // 驱动程序对应的动态链接库未找到
  PROV_NOT_CONNECTED = $80000004; // 连接未就绪
  // Provider标志位
  PF_CONNECTING = $00000001; // 正在连接数据库
  PF_CONNECTED = $00000002; // 已经连接到数据库
  PF_CLOSING = $00000004; // 正在关闭连接
  PF_CLOSED = $00000008; // 连接已经关闭
  PF_EXECUTING = $00000010; // 连接正在执行脚本
  PF_KEEPALIVE = $00000020; // 需要进行连接保持测试
  PF_PEEKING = $00000040; // 正在执行连接保持测试
  PF_NSLOOKUP = $00000080; // 正在解析服务器地址
  PF_HANDSHAKE = $00000100; // 正在初始化握手
  PF_LOGIN = $00000200; // 正在登录
{$IFDEF POSIX}
  SOCKET_ERROR = -1;
{$ENDIF}
{$HPPEMIT '#pragma link "qdb"'}

type
{$IF RTLVersion<260}
  PDateTimeRec = ^TDateTimeRec;
{$IFEND}
  TQFieldDef = class;
  TQFieldDefs = class;
  TQSchema = class;
  TQSchemas = class;
  PQDataSet = ^TQDataSet;
  TQDataSet = class;
  TQProvider = class;
  TQConverter = class;
  TQConverterClass = class of TQConverter;
  TQLocalCheck = class; // TCheckConstraint,TParams.ParseSQL解析SQL脚本
  TQLocalChecks = class;
  TQRecord = class;
  TQFilterExp = class;
{$IFDEF UNICODE}
  TQFieldDefList = TList<TQFieldDef>;
  TQSchemaList = TList<TQSchema>;
  TQDataSetList = TList<TQDataSet>;
  TQFilterExps = TList<TQFilterExp>;
{$ELSE}
  TQFieldDefList = TList;
  TQSchemaList = TList;
  TQDataSetList = TList;
  TQFilterExps = TList;
{$ENDIF}
  TQSDatabase = class;
  TQSTable = class;
  TQSColumn = class;

  { 排序表达式内部结构定义 }
  PQSortExp = ^TQSortExp;

  { 编译后的排序表达式 }
  TQSortExp = record
    Field: TQFieldDef; // 排序的字段索引
    OnCompare: TQValueCompare;
    { 是否降序排列 }
    { 是否忽略大小写 }
    Desc, IgnoreCase: Boolean; // 是否降序排列
    Next: PQSortExp; { 下一条件 }
  end;

  // 条件过滤表达式的处理
  PQFilterExp = ^TQFilterExp;
  { 过滤条件支持的比较操作符
    foUnknown : 未知
    foEQ : 等于
    foLT : 小于
    foGT : 大于
    foLE : 小于等于
    foGE : 大于等于
    foNotEQ : 不等于
    foIn : 位于多个值列表之中
    foNotIn : 值不存在于指定的列表中
    foIsNull : 用于判断是否为空
    foIsNotNull : 用于判断是否为非空
    foLike : 包含，Like操作将被实际转换成foStartWith,foEndWith,foContains
    foNotLike : 不包含
    foStartWith : 以指定的字符串开始
    foEndWith : 以指定的字符串结束
    foContains : 包含
    foRegex : 正则表达式匹配 }
  TQFilterOperator = (foUnknown, foEQ, foLT, foGT, foLE, foGE, foNotEQ, foIn,
    foNotIn, foIsNull, foIsNotNull, foLike, foNotLike, foStartWith, foEndWith,
    foContains, foRegex);
  { 过滤操作时表达式之间的逻辑关系，内部使用
    fgoUnknown : 未知
    fgoAnd : 并且
    fgoOr : 或者
    fgoDone : 已完成，没有后续的逻辑关系了 }
  TQFilterGroupOperator = (fgoUnknown, fgoAnd, fgoOr, fgoDone);

  { 过滤条件表达式 }
  TQFilterExp = class
  protected
    FField: TQFieldDef; // 字段索引
    FValue: TQValue; // 比较的目标值
    FDisplayFormat: QStringW; // 字段的显示格式
    FCompareOpr: TQFilterOperator; // 比较操作符
    FOnCompare: TQValueCompare;
    FNextOpr: TQFilterGroupOperator; // 下一逻辑表达式，最后一个表达式为fgoDone
    FParent: TQFilterExp; // 父表达式
    FItems: TQFilterExps; // 子表达式列表
    FRegex: TPerlRegEx;
    FDataSet: TQDataSet;
    FLocker: TCriticalSection;
    function GetCount: Integer;
    function GetItems(AIndex: Integer): TQFilterExp;
    procedure SetCompareOpr(const Value: TQFilterOperator);
  public
    constructor Create(ADataSet: TQDataSet); overload;
    destructor Destroy; override;
    function Add(AExp: TQFilterExp): Integer; overload; // 添加一个子表达式
    function Add: TQFilterExp; overload; // 添加一个子表达式
    procedure Clear; // 清除子表达式
    procedure Parse(const S: QStringW; AIgnoreCase, ANaturalCompare: Boolean);
    property Count: Integer read GetCount; // 子表达式数据
    property Items[AIndex: Integer]: TQFilterExp read GetItems; // 子表达式列表
    property Value: TQValue read FValue; // 比较的目标值
    function Accept(ARecord: TQRecord; AFilterOptions: TFilterOptions): Boolean;
    property CompareOpr: TQFilterOperator read FCompareOpr write SetCompareOpr;
    // 比较操作符
    property NextOpr: TQFilterGroupOperator read FNextOpr write FNextOpr;
    // 下一逻辑操作符
    property Parent: TQFilterExp read FParent; // 父表达式
    property Field: TQFieldDef read FField write FField; // 关联字段
  end;

  TQColumnValue = record
    OldValue: TQValue;
    NewValue: TQValue;
    Changed: Boolean;
    function CurrentValue: PQValue;
  end;

  PQColumnValue = ^TQColumnValue;

  TQColumnValues = array of TQColumnValue;

  // TQRecord 用于对应单条记录
  TQRecord = class
  private
    FOriginIndex: Integer; // 在克隆时原始数据集中的索引
    FChangedIndex: Integer; // 变更列表中的记录索引
    FSortedIndex: Integer; // 当前排序结果中的记录索引
    FFilteredIndex: Integer; // 当前过滤结果中的记录索引
{$IFNDEF AUTOREFCOUNT}
    FRefCount: Integer; // 引用计数
{$ENDIF}
    FBookmark: Pointer; // 记录对应的书签,指向记录自己
    FBookmarkFlag: TBookmarkFlag; // 书签标志位
    FStatus: TUpdateStatus; // 记录状态
    FOwner: TComponent; // 记录所有者
    FValues: TQColumnValues; // 值列表
    FFields: TQFieldDefs; // 字段定义
    FTag: Pointer; // 附加额外的标签数据
    procedure ClearValues;
    procedure Assign(ASource: TQRecord);
    procedure CopyValues(const ASource: TQRecord);
    function GetModified: Boolean;
  public
    constructor Create(AFields: TQFieldDefs); overload;
    destructor Destroy; override;
    procedure AddRef;
    procedure Release;
{$IFDEF AUTOREFCOUNT}
    function __ObjAddRef: Integer; override;
    function __ObjRelease: Integer; override;
{$ENDIF}
    procedure Reset;
    property Modified: Boolean read GetModified;
    property Owner: TComponent read FOwner;
    property OriginIndex: Integer read FOriginIndex; // 在克隆时原始数据集中的索引
    property ChangedIndex: Integer read FChangedIndex; // 当前数据集中的记录索引
    property SortedIndex: Integer read FSortedIndex; // 当前排序结果中的记录索引
    property FilteredIndex: Integer read FFilteredIndex; // 当前过滤结果中的记录索引
    property RefCount: Integer read FRefCount; // 引用计数
    property Bookmark: Pointer read FBookmark; // 记录对应的书签,指向记录自己
    property BookmarkFlag: TBookmarkFlag read FBookmarkFlag; //
    property Values: TQColumnValues read FValues; // 记录值列表
    property Status: TUpdateStatus read FStatus write FStatus; // 记录状态
    property Fields: TQFieldDefs read FFields;
  end;

  PQRecord = ^TQRecord;

  /// <summary>支持的迭代器级别
  /// rilForwardOnly : 只进迭代器，仅支持 First 和 Next 操作
  /// rilBackwardOnly : 只退迭代器，仅支持 Last 和 Prior 操作
  /// rilBidirection : 双向迭代器，支持 First/Last/Prior/Next 操作
  /// riRandom : 随机迭代器，支持First/Last/Next/Prior/MoveTo 操作
  TQRecordIteratorLevel = (rilForwardOnly, rilBackwardOnly, rilBidirection,
    rilRandom);

  /// <summary> TQRecords 接口用于实现一个记录集，TQDataSet、TQConverter 者实现了该
  /// 接口，以便能够实现对数据的遍历
  IQRecords = interface
    function LoadFields(ADefs: TQFieldDefs): Boolean;
    function GetRecordCount: Integer; // 获取记录总数
    procedure First; // 到第一条记录
    procedure Last; // 到最后一条记录
    procedure Next; // 下一条记录
    procedure Prior; // 前一条记录
    procedure MoveTo(const AIndex: Cardinal); // 移动到指定的记录
    function ActiveRecordBuffer: TQRecord; // 当前记录缓冲区
    function AllocRecord: TQRecord; // 分配一个新的记录
    procedure FreeRecord(ARec: TQRecord); // 释放一个记录
    procedure AddRecord(ARec: TQRecord; Append: Boolean);
    function GetIteratorType: TQRecordIteratorLevel; // 支持的迭代级别
    procedure GetFieldValue(ARecord: PQRecord; AField: TField;
      var AValue: TQValue);
    procedure SetFieldValue(ARecord: PQRecord; AField: TField;
      const AValue: TQValue);
  end;

  TQDirtyIndexType = (ditOrigin, ditChanged, ditSorted, ditFiltered);

  TQRecords = class
  protected
    FFirstDirtyIndex: Integer;
    FIndexType: TQDirtyIndexType;
    FItems: TQPagedList;
    function GetRecords(AIndex: Integer): TQRecord; inline;
    procedure SetRecords(AIndex: Integer; const Value: TQRecord);
    procedure ValidIndex(const AIndex: Integer);
    function GetCount: Integer; inline;
  public
    constructor Create(AIndexType: TQDirtyIndexType); overload;
    destructor Destroy; override;
    procedure Assign(ASource: TQRecords);
    procedure Clean;
    function Add(const Value: TQRecord): Integer;
    function AddWithoutRef(const Value: TQRecord): Integer;
    procedure Delete(AIndex: Integer);
    procedure DeleteWithoutRef(AIndex: Integer);
    procedure Clear(ADoPack: Boolean = True);
    procedure Insert(Index: Integer; const Value: TQRecord);
    procedure MoveTo(AFrom, ATo: Integer);
    procedure Unlink;
    property Records[AIndex: Integer]: TQRecord read GetRecords
      write SetRecords; default;
    property Count: Integer read GetCount;
  end;

  TQFieldDef = class(TFieldDef)
  private
    FSchema: QStringW; // 架构名，如public
    FDatabase: QStringW; // 数据库名
    FTable: QStringW; // 表名
    FBaseName: QStringW; // 数据表中原始的列名
    FDBType: Integer; // 数据字段类型
    FFlags: Integer; // 标志位
    FValueType: TQValueDataType;
    FDBNo: Word; // 数据库中原始字段序列号
    FOnCompare: TQValueCompare; // 字段值的比较方法
{$IF RTLVersion>=24}
    [Weak]
{$IFEND <=XE3}
    FField: TField; // 关联的字段
    FScale: Word;
    function GetFlags(const Index: Integer): Boolean;
    function GetIsArray: Boolean;
    function GetItems(AIndex: Integer): TQFieldDef;
    procedure SetDBType(const Value: Integer);
    procedure SetField(const Value: TField);
    procedure SetFlags(const Index: Integer; const Value: Boolean);
    procedure SetScale(const Value: Word);
    function GetCount: Integer;
    function GetInternalFlags: Integer;
    function GetReadOnly: Boolean;
    procedure SetReadOnly(const Value: Boolean);
    function GetVisible: Boolean;
    procedure SetVisible(const Value: Boolean);
    function GetNullable: Boolean;
    procedure SetNullable(const Value: Boolean);
    function GetFixed: Boolean;
    procedure SetFixed(const Value: Boolean);
    function GetValueType: TQValueDataType;
    function GetOnCompare: TQValueCompare;
    function GetIsBlob: Boolean;
    function GetIsBinary: Boolean;
    function GetInWhere(const Index: Integer): Boolean;
    function GetDBType: Integer;
    procedure SetInternalFlags(const Value: Integer);
    procedure SetIsArray(const Value: Boolean);
  protected
    procedure LookupValueType;
    function LookupCompareProc(AIgnoreCase: Boolean): TQValueCompare;
  public
    constructor Create(Owner: TFieldDefs; const Name:
{$IFDEF UNICODE}string{$ELSE}WideString{$ENDIF}; DataType: TFieldType;
      Size: Integer; Required: Boolean; FieldNo: Integer);
{$IFDEF UNICODE }override; {$ELSE}overload; {$ENDIF}
    destructor Destroy; override;
    procedure Assign(Source: TPersistent); override;
    property Items[AIndex: Integer]: TQFieldDef read GetItems; default;
    // 下面的属性对于非本单元来说是只读的
    property Schema: QStringW read FSchema write FSchema;
    property Database: QStringW read FDatabase write FDatabase;
    property Table: QStringW read FTable write FTable;
    property BaseName: QStringW read FBaseName write FBaseName;
    property DBType: Integer read GetDBType write SetDBType;
    property Field: TField read FField write SetField;
    property Scale: Word read FScale write SetScale;
    property DBNo: Word read FDBNo write FDBNo;
    property IsPrimary: Boolean index SCHEMA_ISPRIMARY read GetFlags
      write SetFlags;
    property IsIndex: Boolean index SCHEMA_ISINDEX read GetFlags write SetFlags;
    property IsUnique: Boolean index SCHEMA_UNIQUE read GetFlags write SetFlags;
    property Nullable: Boolean read GetNullable write SetNullable;
    property IsFixed: Boolean read GetFixed write SetFixed;
    property IsAutoInc: Boolean index SCHEMA_AUTOINC read GetFlags
      write SetFlags;
    property Visible: Boolean read GetVisible write SetVisible;
    property ReadOnly: Boolean read GetReadOnly write SetReadOnly;
    property IsCalc: Boolean index SCHEMA_CALC read GetFlags write SetFlags;
    property InWhere: Boolean index SCHEMA_INWHERE read GetInWhere
      write SetFlags;
    property IsArray: Boolean read GetIsArray write SetIsArray;
    property HasDefault: Boolean index SCHEMA_HASDEFAULT read GetFlags
      write SetFlags;
    property IsBlob: Boolean read GetIsBlob;
    property IsBinary: Boolean read GetIsBinary;
    property Flags: Integer read GetInternalFlags write SetInternalFlags;
    property Count: Integer read GetCount;
    property ValueType: TQValueDataType read GetValueType;
    property ValueComparor: TQValueCompare read GetOnCompare;
  end;

  TQFieldDefArray = array of TQFieldDef;

  TQFieldDefs = class(TFieldDefs)
  protected
    procedure Notify(Item: TCollectionItem;
      Action: classes.TCollectionNotification); override;
{$IFDEF UNICODE}
    function GetFieldDefClass: TFieldDefClass; override;
{$ENDIF}
  public
    constructor Create(AOwner: TPersistent); {$IFDEF UNICODE}override; {$ENDIF}
  end;

  TQIntervalField = class(TField)
  protected
{$IF RTLVersion>=24}
    FIOBuffer: TValueBuffer;
{$IFEND}
    function GetValue(var AValue: TQInterval): Boolean;
    procedure SetValue(const AValue: TQInterval);
    function GetAsInterval: TQInterval;
    procedure SetAsInterval(AValue: TQInterval);
    function GetClassDesc: string; override;
    function GetAsString: String; override;
    procedure SetAsString(const AValue: String); override;
    function GetAsVariant: Variant; override;
    procedure SetVarValue(const AValue: Variant); override;
    procedure SetSize(Value: Integer); override;
  public
    constructor Create(AOwner: TComponent); override;
    property AsInterval: TQInterval read GetAsInterval write SetAsInterval;
  end;

  TQBlobField = class(TBlobField)
  private
    FTextEncoding: TTextEncoding;
  protected
    function GetAsString: String; override;
  public
    property TextEncoding: TTextEncoding read FTextEncoding write FTextEncoding;
  end;

  TQRecordCheckEvent = procedure(ADataSet: TQDataSet; ACheck: TQLocalCheck;
    var Accept: Boolean) of object;
  TQRecordCheckConflictEvent = procedure(ADataSet: TQDataSet;
    ACheck: TQLocalCheck; var AHandled: Boolean) of object;
  /// <summary>
  /// lctUnique - 唯一约束，Expression中指定的字段列表值的组合，在当前数据集中必需唯一
  /// lctDefault - 默认值约束，Expression中指定的值为表达式默认值
  /// lctRangeCheck - 范围约束，Expression中指定的表达式为值边界检查
  /// </summary>
  TQLocalCheckType = (lctUnique, lctDefault, lctRangeCheck);

  TQLocalCheck = class(TCollectionItem)
    // protected
    // FNameHash: Cardinal;
    // FOnCheck: TQRecordCheckEvent;
    // FOnConflict: TQRecordCheckConflictEvent;
    // FCheckExp: TQFilterExp;
    // FValueHashes: TQHashTable;
    // FName: QStringW;
    // FExpr: QStringW;
    // FErrorText: QStringW;
    // FEnabled: Boolean;
    // FCheckType: TQLocalCheckType;
    // procedure SetName(const Value: QStringW);
    // procedure SetEnabled(const Value: Boolean);
    // procedure SetErrorText(const Value: QStringW);
    // procedure SetExpr(const Value: QStringW);
    // procedure SetOnCheck(const Value: TQRecordCheckEvent);
    // procedure SetOnConflict(const Value: TQRecordCheckConflictEvent);
    // procedure SetCheckType(const Value: TQLocalCheckType);
    // function CheckRange: Boolean;
    // function CheckUnique: Boolean;
    // function CheckDefault: Boolean;
    // function ParseDefault: Boolean;
    // function ParseUnique: Boolean;
    // function ParseCheck: Boolean;
    // public
    // destructor Destroy; override;
    // // 执行默认的约束，如果失败返回False，如果成功，返回True
    // function DefaultCheck: Boolean;
    // procedure Assign(Source: TPersistent); override;
    // function GetDisplayName: string; override;
    // published
    // /// <summary>名称</summary>
    // property Name: QStringW read FName write SetName;
    // /// <summary>约束表达式，详细说明:http://www.qdac.cc/?p=638</summary>
    // property Expression: QStringW read FExpr write SetExpr;
    // /// <summary>错误提示文本</summary>
    // /// <remarks>错误提示中可以引用标志符，[Name]为约束名称,[Value]为违反约束的值</remarks>
    // property ErrorText: QStringW read FErrorText write SetErrorText;
    // /// <summary>是否启用本约束规则</summary>
    // property Enabled: Boolean read FEnabled write SetEnabled;
    // /// <summary>用户自定义的约束检查事件，优先于Expression检查</summary>
    // property OnCheck: TQRecordCheckEvent read FOnCheck write SetOnCheck;
    // /// <summary>在发生违反约束时，如何处理</summary>
    // property OnConflict: TQRecordCheckConflictEvent read FOnConflict
    // write SetOnConflict;
    // /// <summary>约束类型</summary>
    // property CheckType: TQLocalCheckType read FCheckType write SetCheckType;
  end;

  TQLocalChecks = class(TCollection)
  protected
    FDataSet: TQDataSet;
    // FOnUpdate: TNotifyEvent;
    // function GetItems(Index: Integer): TQLocalCheck;
    // procedure SetItems(Index: Integer; const Value: TQLocalCheck);
  public
    // constructor Create(AOwner: TQDataSet); overload;
    // function Add: TQLocalCheck; overload;
    // function Find(const Name: QStringW): TQLocalCheck;
    function Accept(ABuf: TQRecord): Boolean;
    procedure Check(ABuf: TQRecord);
    // procedure Update; reintroduce;
    // property Items[Index: Integer]: TQLocalCheck read GetItems
    // write SetItems; default;
    // property OnUpdate: TNotifyEvent read FOnUpdate write FOnUpdate;
    // property DataSet: TQDataSet read FDataSet;
  end;

  TQConvertStep = (csBeforeImport, csBeginImport, csLoadFields, csLoadData,
    csEndImport, csAfterImport, csBeforeExport, csBeginExport, csSaveFields,
    csSaveData, csEndExport, csAfterExport);
  TQDataConveterProgress = procedure(ASender: TQConverter; AStep: TQConvertStep;
    AProgress, ATotal: Integer) of object;
  /// <summary>
  /// 导出范围选项
  /// </summary>
  /// <list>
  /// <item><term>merMeta</term><description>元数据（也就是字段定义）</description></item>
  /// <item><term>merUnmodified</term><description>未修改的数据</description></item>
  /// <item><term>merInserted</term><description>新插入的数据</description></item>
  /// <item><term>merModified</term><description>已变更的数据</description></item>
  /// <item><term>merDeleted</term><description>已删除的数据</description></item>
  /// </list>
  /// <remarks>
  ///
  /// </remarks>
  TQExportRange = (merMeta, merUnmodified, merInserted, merModified,
    merDeleted);
  TQRecordEnumProc = procedure(ASender: TComponent; AIndex: Integer;
    ARecord: TQRecord; AParam: Pointer) of object;
{$IFDEF UNICODE}
  TQRecordEnumProcA = reference to procedure(ASender: TComponent;
    AIndex: Integer; ARecord: TQRecord);
{$ENDIF}
  TQExportRanges = set of TQExportRange;

  TQStreamProcessor = class(TComponent)
  protected
    procedure BeforeSave(ASourceStream: TStream; ATargetStream: TStream);
      virtual; abstract;
    procedure BeforeLoad(ASourceStream: TStream; ATargetStream: TStream);
      virtual; abstract;
  end;

  TQStreamProcessorItem = class(TCollectionItem)
  private
    FProcessor: TQStreamProcessor;
  published
    property Processor: TQStreamProcessor read FProcessor write FProcessor;
  end;

  TQStreamProcessors = class(TCollection)
  private
    function GetProcessor(Index: Integer): TQStreamProcessorItem;
    procedure SetProcessor(Index: Integer; const Value: TQStreamProcessorItem);
  public
    constructor Create; overload;
    function Add: TQStreamProcessorItem; reintroduce;
    property Items[Index: Integer]: TQStreamProcessorItem read GetProcessor
      write SetProcessor; default;
  end;

  TQConverter = class(TComponent)
  private

  protected
    FDataSet: TQDataSet;
    FExportRanges: TQExportRanges;
    FStream: TStream;
    FOriginStream: TStream;
    FDataSetCount: Integer;
    FActiveDataSet: Integer;
    FOnProgress: TQDataConveterProgress;
    FStreamProcessors: TQStreamProcessors;
    FStartOffset: Int64;
    procedure SetDataSet(const Value: TQDataSet);
    // 导出接口
    procedure BeforeExport; virtual;
    procedure BeginExport(AIndex: Integer); virtual;
    procedure SaveFieldDefs(ADefs: TQFieldDefs); virtual; abstract;
    function WriteRecord(ARec: TQRecord): Boolean; virtual; abstract; // 写出数据
    procedure EndExport(AIndex: Integer); virtual;
    procedure AfterExport; virtual;
    // 导入接口
    procedure BeforeImport; virtual;
    procedure BeginImport(AIndex: Integer); virtual;
    procedure LoadFieldDefs(AFieldDefs: TQFieldDefs); virtual; abstract;
    function ReadRecord(ARec: TQRecord): Boolean; virtual; abstract; // 导入数据内容
    procedure EndImport(AIndex: Integer); virtual;
    procedure AfterImport; virtual;
    // 进度
    procedure DoProgress(AStep: TQConvertStep; AProgress, ATotal: Integer);
    procedure RemoveChild(AIndex: Integer);
    function GetActiveRecCount: Integer; virtual;
    procedure SetFStreamProcessors(const Value: TQStreamProcessors);
    property ActiveDataSet: Integer read FActiveDataSet write FActiveDataSet;
    property DataSetCount: Integer read FDataSetCount write FDataSetCount;
    property StartOffset: Int64 read FStartOffset;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    /// <summary>
    procedure LoadFromStream(ADataSet: TQDataSet; AStream: TStream); overload;
    procedure LoadFromFile(ADataSet: TQDataSet; AFileName: QStringW); overload;
    procedure LoadFromConverter(AConverter: TQConverter;
      ASourceStream, ATargetStream: TStream); overload;
    procedure LoadFromConverter(AConverter: TQConverter;
      ASourceFile, ATargetFile: QStringW); overload;
    procedure LoadFromConverter(AConverter: TQConverterClass;
      ASourceStream, ATargetStream: TStream); overload;
    procedure LoadFromConverter(AConverter: TQConverterClass;
      ASourceFile, ATargetFile: QStringW); overload;

    procedure SaveToStream(ADataSet: TQDataSet; AStream: TStream); overload;
    procedure SaveToFile(ADataSet: TQDataSet; AFileName: QStringW); overload;
    procedure SaveToConverter(AConverter: TQConverter;
      ASourceStream, ATargetStream: TStream); overload;
    procedure SaveToConverter(AConverter: TQConverter;
      ASourceFile, ATargetFile: QStringW); overload;
    procedure SaveToConverter(AConverter: TQConverterClass;
      ASourceStream, ATargetStream: TStream); overload;
    procedure SaveToConverter(AConverter: TQConverterClass;
      ASourceFile, ATargetFile: QStringW); overload;
    property ActiveRecCount: Integer read GetActiveRecCount;
  published
    property ExportRanges: TQExportRanges read FExportRanges
      write FExportRanges; // 导出范围选择
    property OnProgress: TQDataConveterProgress read FOnProgress
      write FOnProgress;
    property DataSet: TQDataSet read FDataSet write SetDataSet;
    property StreamProcessors: TQStreamProcessors read FStreamProcessors
      write SetFStreamProcessors;
  end;

  { 复制数据来源类型，可取以下值之一：

    <table>
    取值              备注
    --------------  -------------
    dcmUnknown      未知来源
    dcmView         当前用户查看到的数据
    dcmCurrents     当前显示的原始数据
    dcmOrigins      更改之前的原始数据
    dcmInserted     新插入的数据
    dcmDeleted      已删除但未提交的数据
    dcmModified     修改过的数据
    dcmChanged      所有变更的数据
    dcmSorted       排序后的数据
    dcmFiltered     按表达式过滤后的数据
    dcmMetaOnly   仅复制表结构，不复制数据
    </table> }
  TQDataCopySource = (dcmUnknown, dcmView, dcmCurrents, dcmOrigins, dcmInserted,
    dcmDeleted, dcmModified, dcmChanged, dcmSorted, dcmFiltered, dcmMetaOnly);

  /// <summary> 数据集打开方法，内部使用</summary>
  /// <list>
  /// <item><term>dsomByCreate</term><description>通过CreateDataSet创建内存数据集</description></item>
  /// <item><term>dsomByProvider</term><description>通过脚本从TQProvider打开</description></item>
  /// <item><term>dsomByConverter</term><description>从转换器加载</description></item>
  /// <item><term>dsomByClone</term><description>从源克隆得到</description></item>
  /// <item><term>dsomByCopy</term><description>从源复制得到</description></item>
  /// </list>
  TQDataSetOpenMethod = (dsomByCreate, dsomByProvider, dsomByConverter,
    dsomByClone, dsomByCopy);

  /// <summary>数据集对象允许的编辑操作</summary>
  /// <list>
  /// <item><term>deaInsert</term><description>插入操作</description></item>
  /// <item><term>deaEdit</term><description>编辑操作</description></item>
  /// <item><term>deaDelete</term><description>删除操作</description></item>
  /// </list>
  TQDataSetEditAction = (deaInsert, deaEdit, deaDelete);
  TQDataSetEditActions = set of TQDataSetEditAction;
  /// <summary>
  /// <list>
  /// <item><term>dmmAppend</term><description>追加到已有的结果集后面</description></item>
  /// <item><term>dmmReplace</term><description>替换已有的结果集</description></item>
  /// <item><term>dmmMerge</term><description>融合，重复的记录会被忽略</description></item>
  /// </list>
  TQDataMergeMethod = (dmmAppend, dmmReplace, dmmMerge);
  /// <summary>记录变更通知类型，用于克隆的数据集之间相互通知变更信息</summary>
  TQRecordChangeNotify = (rcnDeleted, rcnInserted, rcnModified);

  TQBlobStream = class(TStream)
  protected
    FMode: TBlobStreamMode; // 读写模式
    FField: TBlobField; // 关联字段
    FData: TQValue; // 数据内容
    FOriginValue: PQValue; // 原始的字段值
    function GetSize: Int64; override;
    procedure SetSize(NewSize: Longint); overload; override;
  public
    constructor Create(AField: TBlobField; AMode: TBlobStreamMode); overload;
    destructor Destroy; override;
    function Read(var Buffer; Count: Longint): Longint; overload; override;
    function Write(const Buffer; Count: Longint): Longint; override;
    function Seek(const Offset: Int64; Origin: TSeekOrigin): Int64; override;
    procedure Truncate;
  end;

  TQCustomSortEvent = procedure(ADataSet: TQDataSet;
    ARecord1, ARecord2: TQRecord; var AResult: Integer) of object;
  TQRecordCompareProc = function(AExp: PQSortExp; ARec1, ARec2: TQRecord)
    : Integer of object;

  // 记录哈希的结果
  TQRecordHash = record
    HashCode: Cardinal; // 普通哈希值，如果一致时，再计算并比较MD5的哈希值
    MD5: TQMD5Digest; // MD5哈希值，默认不计算，只有HashCode一致时才会进一步计算
    Rec: TQRecord; // 原始记录指针
    FlatValues: TBytes; // 原始值平面化后的值
    MD5Hashed: Boolean; // 是否已经哈希过MD5
  end;

  PQRecordHash = ^TQRecordHash;

  TQDiffCache = record
    HashTable: TQHashTable;
    Fields: TQFieldDefArray;
  end;

  TQMasterDataLink = class(TMasterDataLink)
  protected
    procedure ActiveChanged; override;
    procedure RecordChanged(Field: TField); override;
  end;

  TQHashDupFoundEvent = procedure(ATable: TQHashTable; AHash: PQRecordHash;
    AParam: Pointer) of object;
{$IF RTLVersion>=23}
  [ComponentPlatformsAttribute(pidWin32 or pidWin64{$IF RTLVersion>=24} or
    pidOSX32{$IFEND}{$IF RTLVersion>=25} or pidiOSSimulator or
    pidiOSDevice{$IFEND}{$IF RTLVersion>=26} or
    pidAndroid{$IFEND}{$IF RTLVersion>=29} or pidiOSDevice32 or
    pidiOSDevice64{$IFEND})]
{$IFEND}

  TQDataSet = class(TDataSet, IQRecords)
  private
    procedure SetMasterFields(const Value: QStringW);
    procedure SetMasterSource(const Value: TDataSource);
    function GetMasterSource: TDataSource;
  protected
    FProvider: TQProvider; // 数据提供者
    FConverter: TQConverter; // 数据转换器
    FHandle: THandle; // 从提供者获取数据的句柄，当内存表使用时，始终为空
    FChecks: TQLocalChecks; // 本地约束检查
    // 记录列表
    FOriginRecords: TQRecords; // 原始记录列表
    FLoadedRecordCount: Integer;
    FProviderRecordCount: Integer;
    FChangedRecords: TQRecords; // 变更记录列表
    FFilteredRecords: TQRecords; // 过滤后的记录列表
    FSortedRecords: TQRecords; // 排序后的记录列表
    FActiveRecords: TQRecords; // 当前活动的记录列表，指向上述四个中的某一个
    FActiveRecordset: Integer;
    FOwnerField: TField; // 当自己是一个数据集类型的字段值时，所隶属的字段
    FRecordNo: Integer; // 当前记录索引
    FEditingRow: TQRecord; // 当前插入的记录，用来避免重复拷贝
    FRecordsets: array of TQDataSet;
    // 克隆支持
    FClones: TQDataSetList; // 从自己克隆出去的数据集列表
    FCloneSource: TQDataSet; // 自己做为克隆后的数据集，那么指向来源数据集
    FOpenBy: TQDataSetOpenMethod; // 数据集打开方式
    FBatchMode: Boolean; // 是否工作在批量模式，批量模式提交数据时，如果关联了Provider不会立即提交
    FReadOnly: Boolean; // 是否允许修改数据集
    FDefChanging: Boolean; // 数据集定义正在改变
    FActiveRecordsetChanging: Boolean; // 活动数据集正在改变
    FTempState: TDataSetState; // 临时状态
    FIsOpening: Boolean; // 是否正在打开
    FCursorOpened: Boolean; // 是否已打开
    FPageIndex: Integer; // 当前页索引
    FPageSize: Integer; // 分页大小
    FCommandText: QStringW; // 脚本
    FSort: QStringW;
    FSortExp: PQSortExp;
    FAllowEditActions: TQDataSetEditActions;
    // 数据集字段支持
    FParentDataSet: TQDataSet;
    FDataSetField: TDataSetField;
    FOnInitFieldDefs: TNotifyEvent; // 用于不使用提供者或转换组件初始化字段定义时触发，用于用户自定义字段
    FOnLoadData: TNotifyEvent; // 用于不使用提供者或转换组件加载数据时

    FCopySource: TQDataSet; // 复制数据来源
    FCopySourceType: TQDataCopySource; // 复制数据方式
    // 过滤与排序
    FFilterExp: TQFilterExp;
    FNaturalFilter: Boolean;
    FOnCustomSort: TQCustomSortEvent;
    FAnsiNulls: Boolean;
    // 主从数据集支持
    FMasterLink: TQMasterDataLink;
    FOnMasterChanged: TDataSetNotifyEvent;
    FMasterDetailFields: QStringW;
    FDetailFields: array of QStringW;
    procedure MasterChanged(Sender: TObject);
    procedure MasterDisabled(Sender: TObject);
    function GetChangedRecords: TQRecords;
    function GetPageCount: Integer;
    function GetRecordCount: Integer; override;
    procedure SetProvider(const Value: TQProvider);
    procedure SetCommandText(const Value: QStringW);
    procedure SetPageIndex(const Value: Integer);
    procedure SetPageSize(const Value: Integer);
    procedure SetReadOnly(const Value: Boolean);
    procedure SetSort(const Value: QStringW);
    procedure SetFiltered(Value: Boolean); override;
    procedure SetFilterText(const Value: string); override;
    procedure SetFilterOptions(Value: TFilterOptions); override;
    procedure SetAllowEditActions(const Value: TQDataSetEditActions);
{$IFDEF NEXTGEN}
    function AllocRecBuf: TRecBuf; override;
    procedure FreeRecBuf(var Buffer: TRecBuf); override;
{$ELSE}
{$IF RTLVersion>19}
    function AllocRecordBuffer: TRecordBuffer; override;
    procedure FreeRecordBuffer(var Buffer: TRecordBuffer); override;
    procedure GetBookmarkData(Buffer: TRecordBuffer; Data: TBookmark); overload;
{$IF RTLVERSION>23}override; {$IFEND XE3}
    procedure SetBookmarkData(Buffer: TRecordBuffer; Data: TBookmark); overload;
{$IF RTLVersion>23} override; {$IFEND}
    procedure GetBookmarkData(Buffer: TRecordBuffer; Data: Pointer);
      overload; override;
    procedure SetBookmarkData(Buffer: TRecordBuffer; Data: Pointer); override;
    procedure SetBookmarkFlag(Buffer: TRecordBuffer; Value: TBookmarkFlag);
      overload; override;
    function GetBookmarkFlag(Buffer: TRecordBuffer): TBookmarkFlag;
      overload; override;
{$IF RTLVersion>23}
    procedure InternalAddRecord(Buffer: TRecordBuffer; Append: Boolean);
      overload; override;
{$IFEND XE3}
    function GetRecord(Buffer: TRecordBuffer; GetMode: TGetMode;
      DoCheck: Boolean): TGetResult; overload; override;
    procedure InternalInitRecord(Buffer: TRecordBuffer); overload; override;
    procedure InternalSetToRecord(Buffer: TRecordBuffer); overload; override;
{$IF RTLVersion>23}
    procedure InternalGotoBookmark(Bookmark: TBookmark); overload; override;
    procedure SetFieldData(Field: TField; Buffer: TValueBuffer);
      overload; override;
{$IFEND >XE3}
{$IFEND 2009+}
    procedure SetFieldData(Field: TField; Buffer: Pointer); overload; override;
    procedure InternalAddRecord(Buffer: Pointer; Append: Boolean);
      overload; override;
{$IFNDEF UNICODE}
    function GetRecord(Buffer: PChar; GetMode: TGetMode; DoCheck: Boolean)
      : TGetResult; overload; override;
    procedure InternalInitRecord(Buffer: PChar); overload; override;
    function AllocRecordBuffer: PChar; overload; override;
    procedure FreeRecordBuffer(var Buffer: PChar); overload; override;
    procedure GetBookmarkData(Buffer: PChar; Data: Pointer); overload; override;
    function GetBookmarkFlag(Buffer: PChar): TBookmarkFlag; overload; override;
    procedure InternalSetToRecord(Buffer: PChar); overload; override;
    procedure SetBookmarkFlag(Buffer: PChar; Value: TBookmarkFlag);
      overload; override;
    procedure SetBookmarkData(Buffer: PChar; Data: Pointer); overload; override;

{$ENDIF}
    procedure InternalGotoBookmark(Bookmark: Pointer); overload; override;
{$ENDIF !NEXTGEN}
    function GetRecNo: Integer; override;
    procedure SetRecNo(Value: Integer); override;
    procedure InternalInitRecord(Buffer: TQRecord); reintroduce; overload;
{$IF RTLVersion>24}// XE4
    procedure SetBookmarkFlag(Buffer: TRecBuf; Value: TBookmarkFlag);
      overload; override;
    procedure InternalInitRecord(Buffer: TRecBuf); overload; override;
    function GetRecord(Buffer: TRecBuf; GetMode: TGetMode; DoCheck: Boolean)
      : TGetResult; overload; override;
    procedure GetBookmarkData(Buffer: TRecBuf; Data: TBookmark);
      overload; override;
    procedure SetBookmarkData(Buffer: TRecBuf; Data: TBookmark);
      overload; override;
    function GetBookmarkFlag(Buffer: TRecBuf): TBookmarkFlag; overload;
      override;
    procedure InternalAddRecord(Buffer: TRecBuf; Append: Boolean);
      overload; override;
    procedure InternalSetToRecord(Buffer: TRecBuf); overload; override;
{$IFEND}
    function GetRecordSize: Word; override;
    procedure InternalAddRecord(Buffer: TQRecord; Append: Boolean);
      reintroduce; overload;
    procedure InternalSetToRecord(Buffer: TQRecord); reintroduce; overload;
    function InternalAddToFiltered(ABuf: TQRecord): Boolean;
    procedure InternalAddToSorted(ABuf: TQRecord);
    function InternalGetFieldData(ARecord: TQRecord; AField: TField;
      ABuffer: Pointer; AIsOld: Boolean): Boolean;
    procedure InternalSetFieldData(ARecord: TQRecord; AField: TField;
      ABuffer: Pointer; AIsOld: Boolean);
    procedure InternalDelete; override;
    procedure InternalInsert; override;
    procedure InternalEdit; override;
    procedure InternalCancel; override;
    procedure InternalFirst; override;
    procedure InternalLast; override;
    procedure InternalPost; override;
    procedure InternalClose; override;
    procedure InternalHandleException; override;
    procedure InternalInitFieldDefs; override;
    procedure InternalOpen; override;
    function IsCursorOpen: Boolean; override;
    function InternalFind(ASorted: TQRecords; AExp: PQSortExp; ABuf: TQRecord;
      var AIndex: Integer): Boolean;
    function GetRecord(Buffer: TQRecord; GetMode: TGetMode; DoCheck: Boolean)
      : TGetResult; reintroduce; overload;
    function BufferOfRecNo(ARecNo: Integer): TQRecord;
    procedure FetchProviderRecord(ARec: TQRecord);
    procedure FetchAllRecords;
    procedure ClearSort(var AExp: PQSortExp);
    function ParseSort(const S: QStringW): PQSortExp;
    procedure DoSort(AFireNotify: Boolean);
    procedure QuickSort(ARecords: TQRecords; AExp: PQSortExp; L, R: Integer;
      ACompareProc: TQRecordCompareProc);
    function SortCompare(AExp: PQSortExp; ARec1, ARec2: TQRecord): Integer;
    procedure DoDelete(ABuf: TQRecord);
    procedure InternalApplyChanges(AProvider: TQProvider);
    procedure MergeChanges;
    procedure MergeRecordChanges(ARec: TQRecord);
    procedure CloneNotify(ARec: TQRecord; AEvent: TQRecordChangeNotify);
    procedure CloneSourceDeleted(ARec: TQRecord);
    procedure CloneSourceInserted(ARec: TQRecord);
    procedure CloneSourceEdited(ARec: TQRecord);
    procedure FilterRecord(ARec: TQRecord; var Accept: Boolean;
      AParser: TQFilterExp);
    procedure FilterRecords(AParseNeeded, AFireNotify: Boolean);
    procedure DoThreadFilterJob(ALoopMgr: TQForJobs; AJob: PQJob;
      AIndex: NativeInt);
    procedure HandleExceptionInMainThread(ASender: Pointer);
{$IFDEF UNICODE}
    function GetFieldDefsClass: TFieldDefsClass; override;
{$ENDIF}
    function DoCustomSort(AExp: PQSortExp; ARec1, ARec2: TQRecord): Integer;
    function IsSorted: Boolean; inline;
    procedure ActiveRecordsChanged;
    procedure DefChanged(Sender: TObject); override;
    function GetRecordsets(AIndex: Integer): TQDataSet;
    procedure SetActiveRecordset(const Value: Integer);
    procedure SetOnCustomSort(const Value: TQCustomSortEvent);
    function GetRecords(AIndex: Integer): TQRecord;
    function GetRecordsetCount: Integer;
    procedure BindFields(Binding: Boolean); {$IFDEF UNICODE}override;
{$ELSE}reintroduce; overload; {$ENDIF}
    procedure MarkRecordStatus(ARec: TQRecord; ANewStatus: TUpdateStatus);
    procedure FlatFieldValues(ARec: TQRecord; const AFields: TQFieldDefArray;
      var ABytes: TBytes);
    function MD5OfRecord(ARec: TQRecord; const AFields: TQFieldDefArray)
      : TQMD5Digest;
    function HashOfRecord(ARec: TQRecord; const AFields: TQFieldDefArray)
      : TQHashType; overload;
    procedure DecodeFieldDefs(AFieldList: QStringW;
      var AFieldDefs: TQFieldDefArray);
    procedure HashOfRecord(ARec: TQRecord; const AFields: TQFieldDefArray;
      var AResult: TQRecordHash); overload;
    procedure HashRecords(ARecords: TQRecords; const AFields: TQFieldDefArray;
      AHashs: TQHashTable);
    procedure RemoveDupFromHash(AHashs: TQHashTable;
      AOnFound: TQHashDupFoundEvent; AParam: Pointer);
    procedure ClearHashs(AHashs: TQHashTable);
    procedure DoDupCount(AHashs: TQHashTable; AHash: PQRecordHash;
      AParam: Pointer);
    procedure PrepareDiffCheck(ASource1, ASource2: TQDataSet; AFields: QStringW;
      var AHash1, AHash2: TQDiffCache);
    function LoadFields(ADefs: TQFieldDefs): Boolean;
    procedure AddRecord(ARec: TQRecord; Append: Boolean);
    function GetFieldClass(FieldType: TFieldType): TFieldClass; override;
    function RealRecord(ARec: TQRecord): TQRecord;
    function GetAggregateValue(Field: TField): Variant; override;

    procedure Notification(AComponent: TComponent;
      Operation: TOperation); override;
    property ChangedRecords: TQRecords read GetChangedRecords;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure CreateDataSet; // 创建一个纯内存数据集
    procedure RecreateDataSet; // 清除所有的数据，重建空的数据集
    function CreateFieldsByUser: Boolean;
    function CreateBlobStream(Field: TField; Mode: TBlobStreamMode)
      : TStream; override;
    function GetBlobFieldData(FieldNo: Integer; var Buffer: TBlobByteData)
      : Integer; override;
    function GetFieldData(Field: TField; Buffer: Pointer): Boolean; override;
    function BookmarkValid(Bookmark: TBookmark): Boolean; override;
    function GetBookmark: TBookmark;
{$IFNDEF NEXTGEN}override; {$ENDIF}
    procedure MoveTo(const AIndex: Cardinal); // 移动到指定的记录
    function ActiveRecordBuffer: TQRecord; // 当前记录缓冲区
    function AllocRecord: TQRecord; // 分配一个新的记录
    procedure FreeRecord(ARec: TQRecord); // 释放一个记录
    function GetIteratorType: TQRecordIteratorLevel; // 支持的迭代级别
    procedure GetFieldValue(ARecord: PQRecord; AField: TField;
      var AValue: TQValue);
    procedure SetFieldValue(ARecord: PQRecord; AField: TField;
      const AValue: TQValue);
    function ForEach(AProc: TQRecordEnumProc; AParam: Pointer)
      : Integer; overload;
{$IF RTLVersion>24}
    function GetFieldData(Field: TField; var Buffer: TValueBuffer): Boolean;
      overload; override;
{$IFEND}
    function UpdateStatus: TUpdateStatus; override;
{$IFDEF UNICODE}
    function ForEach(AProc: TQRecordEnumProcA): Integer; overload;
{$ENDIF}
    /// <summary> 执行指定的脚本并将返回结果合并到当前数据集</summay>
    /// <param name="ACmdText"> SQL 脚本</param>
    /// <param name="AType"> 合并方式 </param>
    /// <param name="AWaitDone"> 是否等待 SQL 脚本执行完成</param>
    /// <returns>成功，返回True，失败，返回false</returns>
    /// <remarks>
    /// 1.如果 AWaitDone 为False，则函数始终返回True，并计划异步执行；
    /// 2.要用此函数，则 Provider 属性必需指向一个有效的数据提供者
    /// </remarks>
    function Merge(const ACmdText: QStringW; AType: TQDataMergeMethod;
      AWaitDone: Boolean): Boolean; overload;
    /// <summary> 合并指定的数据集内容到当前数据集</summay>
    /// <param name="ASource"> 源数据集 </param>
    /// <param name="AType"> 合并方式 </param>
    /// <param name="ACheckDeleted"> 是否检查已删除的记录</param>
    procedure Merge(ASource: TQDataSet; AType: TQDataMergeMethod;
      ACheckDeleted: Boolean = False); overload;
    /// <summary> 合并指定的数据集内容到当前数据集</summay>
    /// <param name="ASource"> 源数据集 </param>
    /// <param name="AUnionAll"> 是否直接追加数据 </param>
    procedure Union(ASource: TQDataSet; AUnionAll: Boolean = False); overload;
    /// <summary> 计算两个数据集共有的记录，并将结果保存到当前结果集</summay>
    /// <param name="ASource1"> 第一个源数据集</param>
    /// <param name="ASource2"> 第二个源数据集</param>
    /// <param name="AFields"> 要比较的字段列表，中间以","分隔，字段名不一致时参考备注</param>
    /// <remarks>如果两个数据集要比较的字段名不一致，则可以在字段列表中使用下面的格式：
    /// FieldName1=FieldName2
    /// 其中，FieldName1 是第一个数据集的字段名，FieldName2 是第二个数据集的字段名。
    /// 另外，注意两个要计算的源数据集对应字段的类型应保持一致.
    /// </remarks>
    procedure Intersect(ASource1, ASource2: TQDataSet; AFields: QStringW);
    /// <summary> 计算两个数据集不同的记录，并将结果保存到当前结果集</summay>
    /// <param name="ASource1"> 第一个源数据集</param>
    /// <param name="ASource2"> 第二个源数据集</param>
    /// <param name="AFields"> 要比较的字段列表，中间以","分隔，字段名不一致时参考备注</param>
    /// <param name="AIncSource1"> 结果中包含在第一个数据集而不在第二个数据集中的记录</param>
    /// <param name="AIncSource2"> 结果中包含在第二个数据集而不在第一个数据集中的记录</param>
    /// <remarks>如果两个数据集要比较的字段名不一致，则可以在字段列表中使用下面的格式：
    /// FieldName1=FieldName2
    /// 其中，FieldName1 是第一个数据集的字段名，FieldName2 是第二个数据集的字段名。
    /// 另外，注意两个要计算的源数据集对应字段的类型应保持一致.
    /// </remarks>
    procedure Diff(ASource1, ASource2: TQDataSet; AFields: QStringW;
      AIncSource1, AIncSource2: Boolean);

    function FindRecord(Restart, GoForward: Boolean): Boolean; override;
    /// <summary>定位到下一条符合条件的记录</summary>
    /// <param name="KeyFields"> 要比较的字段列表，中间以","或";"分隔</param>
    /// <param name="KeyValues"> 要比较的字段的关键值列表</param>
    /// <param name="Options"> 定位的选项</param>
    /// <returns>成功，移动到指定的记录并返回True，否则，返回False</returns>
    function Locate(const KeyFields: string; const KeyValues: Variant;
      Options: TLocateOptions): Boolean; override;
    /// <summary>定位到下一条符合条件的记录</summary>
    /// <param name="KeyFields"> 要比较的字段列表，中间以","或";"分隔</param>
    /// <param name="KeyValues"> 要比较的字段的关键值列表</param>
    /// <param name="Options"> 定位的选项</param>
    /// <param name="ARestart"> 是否重新开始定位</param>
    /// <param name="AGoBack"> 是否往回查找</param>
    /// <returns>成功，移动到指定的记录并返回True，否则，返回False</returns>
    function LocateEx(const KeyFields: QStringW; const KeyValues: Variant;
      Options: TLocateOptions; ARestart, AGoBack: Boolean): Boolean;
    /// <summary>定位到首条符合条件的记录</summary>
    /// <param name="KeyFields"> 要比较的字段列表，中间以","或";"分隔</param>
    /// <param name="KeyValues"> 要比较的字段的关键值列表</param>
    /// <param name="Options"> 定位的选项</param>
    /// <returns>成功，移动到指定的记录并返回True，否则，返回False</returns>
    function LocateFirst(const KeyFields: string; const KeyValues: Variant;
      Options: TLocateOptions): Boolean;
    /// <summary>定位到下一条符合条件的记录</summary>
    /// <param name="KeyFields"> 要比较的字段列表，中间以","或";"分隔</param>
    /// <param name="KeyValues"> 要比较的字段的关键值列表</param>
    /// <param name="Options"> 定位的选项</param>
    /// <returns>成功，移动到指定的记录并返回True，否则，返回False</returns>
    function LocateNext(const KeyFields: string; const KeyValues: Variant;
      Options: TLocateOptions): Boolean;
    /// <summary>定位到上一条符合条件的记录</summary>
    /// <param name="KeyFields"> 要比较的字段列表，中间以","或";"分隔</param>
    /// <param name="KeyValues"> 要比较的字段的关键值列表</param>
    /// <param name="Options"> 定位的选项</param>
    /// <returns>成功，移动到指定的记录并返回True，否则，返回False</returns>
    function LocatePrior(const KeyFields: string; const KeyValues: Variant;
      Options: TLocateOptions): Boolean;
    /// <summary>定位到最后一条符合条件的记录</summary>
    /// <param name="KeyFields"> 要比较的字段列表，中间以","或";"分隔</param>
    /// <param name="KeyValues"> 要比较的字段的关键值列表</param>
    /// <param name="Options"> 定位的选项</param>
    /// <returns>成功，移动到指定的记录并返回True，否则，返回False</returns>
    function LocateLast(const KeyFields: string; const KeyValues: Variant;
      Options: TLocateOptions): Boolean;
    /// <summary>判断是否存在符合指定条件的记录</summary>
    /// <param name="AFilterExp">条件过滤表达式，与 Filter 的格式相同</param>
    /// <param name="AFilterOptions">过滤选项</param>
    /// <returns>如果存在符合条件的记录，返回true，否则返回false</returns>
    function Exists(const AFilterExp: QStringW;
      AFilterOptions: TFilterOptions): Boolean;
    /// <summary> 从源数据集克隆一个新实例 </summary>
    /// <param name="ASource">克隆的源数据集</param>
    procedure Clone(ASource: TQDataSet);
    /// <summary> 断开与克隆源数据集的链接</summay>
    /// <remarks>断开连接后，数据集的变更不会再反馈到克隆源及其它克隆数据集</remarks>
    procedure Unlink;
    /// <summary> 从源数据集拷贝一个新实例</summary>
    /// <param name="ASource"> 源数据集 </param>
    /// <param name="AMethod"> 复制方式</param>
    /// <param name="AFields"> 要复制的字段列表，多个字段之间以“,”或“;”分隔，如果为空，则复制全部</param>
    procedure CopyFrom(ASource: TQDataSet; AMethod: TQDataCopySource;
      AFields: QStringW = ''); overload;
    /// <summary> 从源数据集拷贝一个新实例</summary>
    /// <param name="ASource"> 源数据集 </param>
    /// <param name="AFields"> 要复制的字段列表，多个字段之间以“,”或“;”分隔，如果为空，则复制全部</param>
    procedure CopyFrom(ASource: TDataSet; AFields: QStringW = ''); overload;
    /// <summary> 标记记录的状态为新状态 </summary>
    /// <param name="ANewStatus"> 新状态 </summary>
    /// <param name="ApplyToAll"> 是否应用到所有的记录，如果为False，则只修改当前记录</param>
    procedure MarkStatus(ANewStatus: TUpdateStatus; ApplyToAll: Boolean = True);
    procedure Distinct; // 保证每条记录的值唯一
    /// <summary> 交叉表函数</summay>
    /// <param name="AColField"> 用于做为字段名的字段名 </param>
    /// <param name="AKeyField"> 用于做为行主键的字段名 </param>
    /// <param name="AValueField"> 用于做为交叉值的字段名</param>
    /// <param name="AKeyName"> 转换后行主键字段的名称，如果为空，则使用AKeyField</param>
    procedure Cross(AColField, AKeyField, AValueField, AKeyName: QStringW);
    function EnumValues(const AFields: QStringW; AList: TStrings;
      AValueDelimiter: Char; AIgnoreNull: Boolean): Integer;
    procedure LoadFromStream(AStream: TStream;
      AConverter: TQConverter); overload;
    procedure LoadFromStream(AStream: TStream;
      AConverterClass: TQConverterClass); overload;
    procedure LoadFromFile(const AFileName: QStringW;
      AConverter: TQConverter); overload;
    procedure LoadFromFile(const AFileName: QStringW;
      AConverterClass: TQConverterClass); overload;
    procedure SaveToStream(AStream: TStream; AConverter: TQConverter); overload;
    procedure SaveToStream(AStream: TStream; AConverterClass: TQConverterClass;
      AExports: TQExportRanges); overload;
    procedure SaveToFile(const AFileName: QStringW;
      AConverter: TQConverter); overload;
    procedure SaveToFile(const AFileName: QStringW;
      AConverterClass: TQConverterClass; AExports: TQExportRanges); overload;
    procedure ApplyChanges;
    procedure CancelChanges;
    procedure Empty;
    procedure ClearRecords(AVisibleOnly: Boolean);
    procedure AddDataSet(ADataSet: TQDataSet);
    procedure DeleteDataSet(AIndex: Integer);
    function Sum(AFieldName: QStringW): Variant;
    function Avg(AFieldName: QStringW): Variant;
    function Max(AFieldName: QStringW): Variant;
    function Min(AFieldName: QStringW): Variant;
    function DistinctCount(AFieldNames: QStringW): Integer;
    function GroupBy(AFields, AFilter, AOrderBy: QStringW): TQDataSet; overload;
    procedure GroupBy(ADataSet: TQDataSet;
      AFields, AFilter, AOrderBy: QStringW); overload;
    property Handle: THandle read FHandle;
    property Recordsets[AIndex: Integer]: TQDataSet read GetRecordsets;
    property Records[AIndex: Integer]: TQRecord read GetRecords;
  published
    property AnsiNulls: Boolean read FAnsiNulls write FAnsiNulls;
    property Provider: TQProvider read FProvider write SetProvider;
    property CommandText: QStringW read FCommandText write SetCommandText;
    property PageSize: Integer read FPageSize write SetPageSize;
    property PageIndex: Integer read FPageIndex write SetPageIndex;
    property PageCount: Integer read GetPageCount;
    property ReadOnly: Boolean read FReadOnly write SetReadOnly;
    property Sort: QStringW read FSort write SetSort;
    /// <summary>批量模式切换开关，在批量模式下，数据变更不会提交，除非手动调用ApplyChanges</summary>
    property BatchMode: Boolean read FBatchMode write FBatchMode default True;
    property Checks: TQLocalChecks read FChecks;
    property Active default False;
    property AllowEditActions: TQDataSetEditActions read FAllowEditActions
      write SetAllowEditActions;
    property NaturalFilter: Boolean read FNaturalFilter write FNaturalFilter;
    property AutoCalcFields;
    property DataSetField;
    property RecordsetCount: Integer read GetRecordsetCount;
    property ActiveRecordset: Integer read FActiveRecordset
      write SetActiveRecordset;
    property OnCustomSort: TQCustomSortEvent read FOnCustomSort
      write SetOnCustomSort;
    property MasterSource: TDataSource read GetMasterSource
      write SetMasterSource;
    property MasterFields: QStringW read FMasterDetailFields
      write SetMasterFields;
    property OnMasterChanged: TDataSetNotifyEvent read FOnMasterChanged
      write FOnMasterChanged;
    { <summary> 过滤条件，支持以下运算符：
      运算符         备注
      ----------  ---------------
      =           等于
      \>          大于
      \>=         大于等于
      \<          小于
      \<=         小于等于
      !=或\<\>     不等于
      \* 或 like   包含
      nlike       不包含
      ~           匹配正则表达式
      (           分组开始
      )           分组结束
      and         两个表达式之间是“并且”关系
      or          两个表达式之间是“或”关系
      </summary>
      <remarks>表达式之间按照从左到右的优先级进行运算</remarks> }
    property Filter;
    property Filtered;
    property FilterOptions;
    property BeforeOpen;
    property AfterOpen;
    property BeforeClose;
    property AfterClose;
    property BeforeInsert;
    property AfterInsert;
    property BeforeEdit;
    property AfterEdit;
    property BeforePost;
    property AfterPost;
    property BeforeCancel;
    property AfterCancel;
    property BeforeDelete;
    property AfterDelete;
    property BeforeScroll;
    property AfterScroll;
    property BeforeRefresh;
    property AfterRefresh;
    property OnCalcFields;
    property OnDeleteError;
    property OnEditError;
    property OnFilterRecord;
    property OnNewRecord;
    property OnPostError;
  end;
  /// <summary>事务隔离级别，具体支持程度由数据库本身决定，如果不支持，会转换为比较接近的级别</summary>
  /// dilUnspecified - 未指定，一般会转换为dilReadCommited
  /// dilReadCommited - 读取已经提交的数据
  /// dilReadUncommited - 允许读取未提交的数据（脏读）
  /// dilRepeatableRead - 循环读
  /// dilSerializable - 串行
  /// dilSnapshot - 快照

  TQDBIsolationLevel = (dilUnspecified, dilReadCommitted, dilReadUncommitted,
    dilRepeatableRead, dilSerializable, dilSnapshot);
  TQCommandAction = (caPrepare, caFetchStream, caFetchRecords, caExecute,
    caUnprepare);

  /// <summary>TQCommand用于SQL脚本相关信息记录</summary>
  TQCommand = record
    Id: QStringW;
    SQL: QStringW;
    Action: TQCommandAction;
    Params: array of TQValue;
    PreparedData: TObject;
    Prepared: Boolean;
    FieldDefs: TQFieldDefs;
    DataObject: Pointer;
  end;

  TQExecuteStatics = record
    QueuedTime: Int64; // 请求投寄时间
    StartTime: Int64; // 请求开始时间
    PreparedTime: Int64; // 准备就绪时间
    ExecuteStartTime: Int64; // 脚本开始执行时间
    ExecuteDoneTime: Int64; // 执行完成时间
    StopTime: Int64; // 执行完成时间
    LoadedTime: Int64; // 加载完成
    AffectRows: Integer; // 影响的行数
  end;

  TQExecuteResult = record
    Statics: TQExecuteStatics; // 运行统计信息
    ErrorCode: Cardinal; // 错误代码
    ErrorMsg: QStringW; // 错误提示
  end;

  /// <summary>命令被发往数据库执行脚本前触发的事件</summary>
  /// <params>
  /// <param name="ASender">当前执行的Provider对象</param>
  /// <param name="ACommand">当前要执行的脚本对象</param>
  /// </params>
  TQBeforeExecuteEvent = procedure(ASender: TQProvider;
    const ACommand: TQCommand) of object;
  /// <summary>在命令执行完成后触发的事件</summary>
  /// <params>
  /// <param name="ASender">提供者对象</param>
  /// <param name="ACommand">执行的命令对象</param>
  /// <param name="AResult">执行结果</param>
  /// </params>
  TQAfterExecuteEvent = procedure(ASender: TQProvider;
    const ACommand: TQCommand; const AResult: TQExecuteResult) of object;

  PQSQLRequest = ^TQSQLRequest;

  // 内部记录执行参数的相关记录
  TQSQLRequest = record
    Command: TQCommand; // 命令
    WaitResult: Boolean; // 如果不为空，则等待结果完成，如果为空，则不等待
    Result: TQExecuteResult; // 执行结果
    AfterOpen: TQAfterExecuteEvent; // 执行完成回调事件
  end;

  /// <summary>通知信息级别</summary>
  TQNoticeLevel = (nlLog, nlInfo, nlDebug, nlNotice, nlWarning, nlError,
    nlPanic, nlFatal);

  TQServerNotificationEvent = procedure(ASender: TQProvider;
    ALevel: TQNoticeLevel; const AMsg: QStringW) of object;

  TQServerNotifyEvent = procedure(ASender: TQProvider;
    const AName, APayload: QStringW) of object;

  TQSQLResultset = record
    FieldDefs: TQFieldDefs;
    Records: TQRecords;
  end;

  PQSQLResultSet = ^TQSQLResultset;
  TQResultSets = array of TQSQLResultset;

  TQProvider = class(TComponent)
  private
    function GetKeepAlive: Boolean;
  protected
    FProviderName: QStringW; // 唯一名称标志
    FDatabase: QStringW; // 数据库表
    FSchema: QStringW; // 连接到的模式名
    FErrorCode: Cardinal; // 末次错误代码
    FErrorMsg: QStringW; // 末次错误消息
    FOnNotify: TQServerNotifyEvent;
    FDefaultDataSet: TQDataSet;
    // 连接相关事件
    FBeforeConnect: TNotifyEvent;
    FAfterConnected: TNotifyEvent;
    FBeforeDisconnect: TNotifyEvent;
    FAfterDisconnect: TNotifyEvent;
    FOnParamChanged: TNotifyEvent;
    // 执行相关事件
    FBeforeExecute: TQBeforeExecuteEvent; // 执行脚本前触发的事件
    FAfterExecute: TQAfterExecuteEvent; // 执行脚本完成后触发的事件
    FOnServerNotification: TQServerNotificationEvent;
    FTransactionLevel: Integer; // 事务嵌套级别
    FHandle: THandle; // 由底层驱动返回的连接句柄
    FCommandTimeout: Cardinal; // 命令超时
    FParams: TStrings;
    FDataSets: TQDataSetList; // 关联的数据集对象
    FPeekInterval: Integer;
    FPeekJobHandle: Int64;
    FFlags: Integer;
    FIdentStartChar, FIdentStopChar: QCharW;
    FLastOID: Cardinal;
    FActiveRequest: PQSQLRequest;
    FResultSets: TQResultSets;
    FActiveResultset: Integer;
    FActiveRecords: TQRecords;
    FActiveRecord: TQRecord;
    FActiveFieldDefs: TQFieldDefs;
    procedure DoParamChanged(); virtual;
    procedure SetConnectionString(const Value: QStringW);
    /// <summary>释放一个由Execute返回的结果句柄</summary>
    /// <param name="AHandle">要释放的句柄，由Execute函数返回</param>
    procedure CloseHandle(AHandle: THandle); virtual; abstract;
    procedure SetError(ACode: Cardinal; const AMsg: QStringW);
    procedure SetParams(const Value: TStrings);
    procedure SetConnected(const Value: Boolean);
    // { 获取指定的连接字符串列表，注意内部使用UTF8编码，如果包含中文等字符应先转为UTF8编码 }
    function GetConnected: Boolean;
    /// <summary>执行指定的脚本</summary>
    /// <params>
    /// <param name="ARequest">命令执行参数</param>
    /// </params>
    /// <returns>成功，返回原始结果句柄，失败，返回-1。</returns>
    function InternalExecute(var ARequest: TQSQLRequest): Boolean;
      virtual; abstract;
    { 执行实际的关闭连接动作 }
    procedure InternalClose; virtual; abstract;
    { 执行实际的建立连接动作 }
    procedure InternalOpen; virtual; abstract;
    { 内部执行实际的更新操作
      Parameters
      ARootField :  根字段，它可能隶属于一个数据集，也可能是临时创建的一个对象
      ARecords :    要更新的记录列表 }
    procedure InternalApplyChanges(Fields: TFieldDefs;
      ARecords: TQRecords); virtual;
    // { 组件加载完成后，检查属性，以确定是否连接（如Connected在设计时设置为True) }
    procedure Loaded; override;
    /// <summary>执行指定的脚本</summary>
    /// <params>
    /// <param name="ARequest">命令执行参数</param>
    /// </params>
    /// <returns>成功，返回原始结果句柄，失败，返回-1。</returns>
    function Execute(var ARequest: TQSQLRequest): Boolean; virtual;
    procedure KeepAliveNeeded; virtual;
    procedure Notification(AComponent: TComponent;
      Operation: TOperation); override;
    procedure SetKeepAlive(const Value: Boolean);
    procedure SetPeekInterval(const Value: Integer);
    procedure DoLivePeek(AJob: PQJob);
    procedure FireKeepAlive;
    function GetConnectionString: QStringW;
    function GetFlags(const Index: Integer): Boolean;
    procedure SetFlags(AFlag: Integer; AValue: Boolean);
    procedure InternalSetParams(ADest: TParams; const ASource: array of const);
    procedure InitializeRequest(var ARequest: TQSQLRequest;
      const ASQL: QStringW; ACreateParams: Boolean);
    procedure InternalApplyUpdate(ADataSource: TObject); virtual;
    function PrepareChangeRequest(var ARequest: TQSQLRequest;
      AUpdatStatus: TUpdateStatus): Boolean; virtual;
    function ParseNameToken(var S: QStringW): QStringW;
    function GetDatabase: String;
    function GetPassword: String;
    function GetUserName: String;
    procedure SetDatabase(const Value: String);
    procedure SetPassword(const Value: String);
    procedure SetUserName(const Value: String);
    procedure ServerNotice(ALevel: TQNoticeLevel; const AMsg: QStringW);
    procedure AddResultField(const AFieldName: QStringW;
      ACol: TQSColumn); virtual;
    procedure AddResultRecord(var ARecord: TQRecord); virtual;
    function AllocRecord: TQRecord;
    procedure SetFetching(ADefs: TQFieldDefs; ARecords: TQRecords);
      overload; inline;
    procedure SetFetching(ADataSet: TQDataSet); overload; inline;
    procedure AddResultSet;
    function CreateDefaultDefs: TQFieldDefs;
    procedure DisablePeek;
    procedure EnablePeek;
    procedure ParamValues(var ACommand: TQCommand;
      const AParams: array of const);
    procedure ConnectionAborted; virtual;
    procedure SetDataSetHandle(ADataSet: TQDataSet; AHandle: THandle);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    { 内部使用，析构前进行一些清理工作 }
    procedure BeforeDestruction; override;
    /// <summary>打开连接</summary>
    /// <returns>如果成功，返回true，如果失败，返回false</returns>
    function Open: Boolean;
    // OpenStream函数

    function OpenStream(ACmdText: QStringW; AStreamFormat: TQConverterClass)
      : TMemoryStream; overload;
    function OpenStream(AStream: TStream; ACmdText: QStringW;
      AStreamFormat: TQConverterClass): Boolean; overload; virtual;
    function OpenStream(AStream: TStream; ASQL: TQCommand;
      AStreamFormat: TQConverterClass): Boolean; overload; virtual;
    function OpenStream(ASQL: TQCommand; AStreamFormat: TQConverterClass)
      : TMemoryStream; overload;
    function OpenStream(AStream: TStream; ACmdText: QStringW;
      AStreamFormat: TQConverterClass; AParams: array of const)
      : Boolean; overload;
    function OpenStream(ACmdText: QStringW; AStreamFormat: TQConverterClass;
      AParams: array of const): TMemoryStream; overload;
    function OpenStream(ACmdText: QStringW; AStreamFormat: TQConverter)
      : TMemoryStream; overload;
    function OpenStream(AStream: TStream; ACmdText: QStringW;
      AStreamFormat: TQConverter): Boolean; overload; virtual;
    function OpenStream(AStream: TStream; ASQL: TQCommand;
      AStreamFormat: TQConverter): Boolean; overload; virtual;
    function OpenStream(ASQL: TQCommand; AStreamFormat: TQConverter)
      : TMemoryStream; overload;
    function OpenStream(AStream: TStream; ACmdText: QStringW;
      AStreamFormat: TQConverter; AParams: array of const): Boolean; overload;
    function OpenStream(ACmdText: QStringW; AStreamFormat: TQConverter;
      AParams: array of const): TMemoryStream; overload;

    // OpenDataSet函数

    function OpenDataSet(ACmdText: QStringW): TQDataSet; overload;
    function OpenDataSet(ADataSet: TQDataSet; ACmdText: QStringW;
      AfterOpen: TQAfterExecuteEvent = nil): Boolean; overload; virtual;
    function OpenDataSet(ADataSet: TQDataSet; ASQL: TQCommand;
      AParams: array of const; AfterOpen: TQAfterExecuteEvent = nil): Boolean;
      overload; virtual;
    function OpenDataSet(ADataSet: TQDataSet; ACmdText: QStringW;
      AParams: array of const; AfterOpen: TQAfterExecuteEvent = nil)
      : Boolean; overload;
    function OpenDataSet(ACmdText: QStringW; AParams: array of const)
      : TQDataSet; overload;
    // ExecuteCmd函数
    /// <summary>执行一个脚本并返回影响的行数</summary>
    /// <param name="ACmdText">要执行的SQL脚本</param>
    /// <returns>返回影响的行数，如果小于0，则出错</returns>
    function ExecuteCmd(ACmdText: QStringW): Integer; overload; virtual;
    /// <summary>执行一个已准备过的脚本并返回影响的行数</summary>
    /// <param name="APrepared">要执行的SQL脚本，如果没有准备，则会准备并执行</param>
    /// <param name="AParams">附加的参数值</param>
    /// <returns>返回影响的行数，如果小于0，则出错</returns>
    function ExecuteCmd(var APrepared: TQCommand; const AParams: array of const)
      : Integer; overload; virtual;
    /// <summary>执行一个脚本并返回影响的行数</summary>
    /// <param name="ACmdText">要执行的SQL脚本</param>
    /// <param name="AParams">附加的要执行的参数</param>
    /// <returns>返回影响的行数，如果小于0，则出错</returns>
    function ExecuteCmd(ACmdText: QStringW; const AParams: array of const)
      : Integer; overload;

    // Prepare
    /// <summary>准备一个SQL脚本，以便重复执行</summary>
    /// <params>
    /// <param name="ACmdText">要执行的SQL脚本</param>
    /// <param name="AId">结果的命令ID</param>
    /// </params>
    /// <returns>成功，返回准备完成的SQL语句对象，可以用于OpenStream/OpenDataSet/ExecuteCmd语句</returns>
    /// <remarks>返回的TQCommand对象需要手动释放
    function Prepare(var AResult: TQCommand; ACmdText, AId: QStringW)
      : Boolean; virtual;
    procedure Unprepare(var ACmd: TQCommand); virtual;
    procedure FreeCommand(var ACmd: TQCommand);
    /// <summary> 开启事务或保存点</summary>
    /// <params>
    /// <param name="ALevel">新事务的事务隔离级别，默认为diUnspecified，由数据库决定</param>
    /// <param name="ASavePointName">数据库事务保存点名称</param>
    /// </params>
    /// <returns>成功开启事务，返回true，否则，返回false</returns>
    function BeginTrans(ALevel: TQDBIsolationLevel = dilUnspecified;
      ASavePointName: QStringW = ''): Boolean; virtual;

    { 判断是否存在指定的物理表（不包含视图）
      Parameters
      ATableName :  要判断的表名

      Returns
      存在，返回true，不存在，返回false }
    function TableExists(ATableName: QStringW): Boolean; virtual;
    { 判断指定的视图是否存在
      Parameters
      AName :  要判断的视图名称

      Returns
      存在，返回true，不存在，返回false }
    function ViewExists(AName: QStringW): Boolean; virtual;
    { 判断指定的函数是否存在
      Parameters
      AName :  要判断的函数名称 }
    function FunctionExists(AName: QStringW): Boolean; virtual;
    { 判断是否存在指定的存贮过程
      Parameters
      AName :  要判断的存贮过程名

      Returns
      存在，返回true，否则，返回false }
    function ProcedureExists(AName: QStringW): Boolean; virtual;
    { 判断指定的触发器是否存在
      Parameters
      AName :  要判断的触发器名称

      Returns
      存在，返回true，不存在，返回false }
    function TriggerExists(AName: QStringW): Boolean; virtual;
    { 判断指定表的指定字段是否存在,如果存在，返回true
      Parameters
      ATableName :  表名
      AColName :    列名 }
    function ColumnExists(ATableName, AColName: QStringW): Boolean; virtual;
    { 判断指定的脚本是否返回至少一条记录
      Parameters
      ACmdText :  要执行的脚本

      Returns
      如果返回一个结果集，并且至少返回一条记录，则返回True，否则返回false


      Remarks
      传递的命令脚本是实际被执行的，因此，如果包含了修改数据的命令，请做好相应的事务处理。 }
    function RecordExists(ACmdText: QStringW): Boolean; virtual;
    procedure CommitTrans; virtual; // 提交事务
    procedure RollbackTrans(ASavePointName: QStringW = ''); virtual;
    { 回滚事务或保存点
      Parameters
      ASavePointName :  保存点名称，为空表示还原事务，否则是还原保存点 }
    procedure Close; // 关闭连接
    procedure ApplyChanges(ADataSet: TQDataSet); overload; virtual;
    { 将指定数据集的变更内容应用到数据库中
      Parameters
      ADataSet :  要更新的数据集对象 }
    { 将指定流中的变更内容应用到数据库中
      Parameters
      AStream :  源数据流
      AFormat :  数据流内容的格式转换器类型 }
    procedure ApplyChanges(AStream: TStream; AFormat: TQConverterClass);
      overload; virtual;
    procedure ApplyChanges(AStream: TStream; AConverter: TQConverter);
      overload; virtual;

    { 将指定文件中的变更信息应用
      Parameters
      AFileName :  文件名
      AFormat :    文件格式转换器类型 }
    procedure ApplyChanges(AFileName: QStringW; AFormat: TQConverterClass);
      overload; virtual;
    procedure ApplyChanges(AFileName: QStringW; AConverter: TQConverter);
      overload; virtual;
    { 从缓存中分配一个数据集对象，如果不存在，就创建一个新的数据集对象返回。 }
    class function AcquireDataSet: TQDataSet;
    { 将一个由OpenDataSet或AcquireDataSet返回的数据集对象交还回缓冲池 }
    class procedure ReleaseDataSet(ADataSet: TQDataSet);
    /// <summary>监听服务器上指定名称的通知</summary>
    /// <param name="AName">要监听的通知名称</param>
    procedure Listen(const AName: QStringW); virtual;
    /// <summary>取消对指定名称的通知的监听</summary>
    procedure Unlisten(const AName: QStringW); virtual;
    /// <summary>触发服务器上特定名称的通知</summary>
    /// <param name="AName">要发送的通知名称</param>
    /// <param name="APayload">要发送的通知内容字符串</param>
    procedure Notify(const AName: QStringW; const APayload: QStringW); virtual;

    property ProviderName: QStringW read FProviderName; // 名称标志
    property LastError: Cardinal read FErrorCode; // 末次错误代码
    property LastErrorMsg: QStringW read FErrorMsg; // 末次错误消息内容
    property TransactionLevel: Integer read FTransactionLevel;
    // 事务隔离级别;//事务隔离级别
    property Handle: THandle read FHandle;
  published
    property BeforeExecute: TQBeforeExecuteEvent read FBeforeExecute
      write FBeforeExecute; // 执行脚本前触发事件
    property AfterExecute: TQAfterExecuteEvent read FAfterExecute
      write FAfterExecute; // 执行脚本后触发事件
    property BeforeConnect: TNotifyEvent read FBeforeConnect
      write FBeforeConnect; // 连接建立前触发
    property AfterConnected: TNotifyEvent read FAfterConnected
      write FAfterConnected; // 连接建立后触发
    property BeforeDisconnect: TNotifyEvent read FBeforeDisconnect
      write FBeforeDisconnect; // 连接断开前触发
    property AfterDisconnect: TNotifyEvent read FAfterDisconnect
      write FAfterDisconnect; // 连接断开后触发
    property OnParamChanged: TNotifyEvent read FOnParamChanged
      write FOnParamChanged;
    property OnServerNotification: TQServerNotificationEvent
      read FOnServerNotification write FOnServerNotification;
    property OnNotify: TQServerNotifyEvent read FOnNotify write FOnNotify;
    property Params: TStrings read FParams write SetParams;
    // 连接参数，注意使用的应为UTF8编码
    property Connected: Boolean read GetConnected write SetConnected; // 是否已连接
    property ConnectionString: QStringW read GetConnectionString
      write SetConnectionString; // 连接字符串
    property CommandTimeout: Cardinal read FCommandTimeout write FCommandTimeout
      default 30; { 命令执行超时时间，对于部分提供者对象，可能无意义 }
    property Connecting: Boolean Index PF_CONNECTING read GetFlags; // 是否正在连接数据库
    property Closing: Boolean Index PF_CLOSING read GetFlags;
    property Executing: Boolean Index PF_EXECUTING read GetFlags;
    property Peeking: Boolean Index PF_PEEKING read GetFlags;
    property KeepAlive: Boolean read GetKeepAlive write SetKeepAlive;
    property PeekInterval: Integer read FPeekInterval write SetPeekInterval;
    property UserName: String read GetUserName write SetUserName;
    property Password: String read GetPassword write SetPassword;
    property Database: String read GetDatabase write SetDatabase;
  end;

  // 基于DLL或so的提供者基类，需要第三方的动态链接库支持
  TQLibProvider = class(TQProvider)
  private
    FLibName: string;
    procedure SetLibName(const Value: string);
  protected
    procedure LoadEntries; virtual; abstract; // 加载DLL的时候触发
    procedure UnLoad; virtual; abstract;
    procedure InternalOpen; override;
    procedure InternalClose; override;
    property LibName: string read FLibName write SetLibName;
    procedure InitFieldDescs; virtual; abstract;
  end;

{$IFDEF POSIX}

  TInAddr = in_addr;
  TSockAddrIn = sockaddr_in;
  TTimeVal = timeval;
  TFdSet = fd_set;
{$ENDIF}

  TQSocketProvider = class(TQProvider)
  protected
    FDefaultPort: Word;
    FConnectTimeout: Cardinal;
    FRecvBuf, FSendBuf: TQBytesCatHelper;
    FRecvJob: IntPtr;
    function RemoteAddr: TInAddr;
    procedure HandleNeeded; virtual;
    procedure InternalOpen; override;
    procedure InternalClose; override;
    procedure Login; virtual;
    procedure Handshake; virtual;
    procedure SendRequest(ARequest: TQSQLRequest);
    function SendData: Boolean;
    procedure DispatchData; virtual; abstract;
    function GetServerHost: QStringW;
    function GetServerPort: Word;
    procedure SetServerHost(const Value: QStringW);
    procedure SetServerPort(const Value: Word);
    procedure DoRecv(AJob: PQJob);
    procedure ConnectionAborted; override;
    property RecvBuffer: TQBytesCatHelper read FRecvBuf;
    property SendBuffer: TQBytesCatHelper read FSendBuf;
    property DefaultPort: Word read FDefaultPort write FDefaultPort;
  published
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    property ServerHost: QStringW read GetServerHost write SetServerHost;
    property ServerPort: Word read GetServerPort write SetServerPort;
    property ConnectTimeout: Cardinal read FConnectTimeout write FConnectTimeout
      default 30;
  end;

  // 元数据信息记录
  TQSchema = class
  protected
    FName: QStringW; // 名称
    FParent: TQSchema; // 父对象
    FFlags: Integer; // 元数据信息标志
    FId: Cardinal;
    FOwner: TQSchemas;
    function GetFlags(const Index: Integer): Boolean;
    procedure SetFlags(const Index: Integer; const Value: Boolean);
  public
    constructor Create(AOwner: TQSchemas); overload;
    destructor Destroy; override;
    function GetHashCode: Integer; {$IFDEF UNICODE}override; {$ENDIF}
    property Id: Cardinal read FId write FId;
    property Name: QStringW read FName write FName; // 元数据名称
    property IsDatabase: Boolean index SCHEMA_DATABASE read GetFlags;
    property IsSchema: Boolean index SCHEMA_SCHEMA read GetFlags; // 是否是架构名
    property IsTable: Boolean index SCHEMA_TABLE read GetFlags; // 是否是表名
    property IsField: Boolean index SCHEMA_COLUMN read GetFlags; // 是否是字段名
    property IsType: Boolean index SCHEMA_TYPE read GetFlags; // 是否是类型名
    property HashCode: Integer read GetHashCode;
    property Parent: TQSchema read FParent; // 父项目
  end;

  TQSList = class(TQSchema)
  private
    function GetCount: Integer;
    function GetItems(AIndex: Integer): TQSchema;
  protected
    FLocker: TCriticalSection;
    FOwner: TQSchemas;
    FItems: TQSchemaList; // 子项目列表
    function InternalFind(const AId: Cardinal; var AIndex: Integer): Boolean;
    function FindById(const AId: Cardinal): TQSchema;
    function CreateItem: TQSchema; virtual; abstract;
    function FindByName(const AName: QStringW): TQSchema;
    function Add(const AId: Cardinal; const AName: QStringW): TQSchema;
    property Items[AIndex: Integer]: TQSchema read GetItems; default; // 子项目
  public
    constructor Create(AOwner: TQSchemas); overload;
    destructor Destroy; override;
    procedure Lock;
    procedure Unlock;
    procedure Delete(AIdx: Integer);
    procedure Clear;
    property Count: Integer read GetCount; // 子项目数
    property Owner: TQSchemas read FOwner;
  end;

  TQSDatabase = class(TQSList)
  protected
    function GetTables(AIndex: Integer): TQSTable;
    function CreateItem: TQSchema; override;
  public
    constructor Create(AOwner: TQSchemas); overload;
    function Add(const AId: Cardinal; AName: QStringW): TQSTable;
    function FindById(const AId: Cardinal): TQSTable; overload;
    function FindByName(const AName: QStringW): TQSTable; overload;
    property Tables[AIndex: Integer]: TQSTable read GetTables;
  end;

  TQSTable = class(TQSList)
  private
    function GetColumns(AIndex: Integer): TQSColumn;
    function GetDatabase: TQSDatabase;
    function GetSchema: TQSchema;
  protected
    function CreateItem: TQSchema; override;
  public
    constructor Create(AOwner: TQSchemas); overload;
    function Add(const AId: Cardinal; AName: QStringW): TQSColumn;
    function FindById(const AId: Cardinal): TQSColumn; overload;
    function FindByName(const AName: QStringW): TQSColumn; overload;
    property Columns[AIndex: Integer]: TQSColumn read GetColumns;
    property Database: TQSDatabase read GetDatabase;
    property Schema: TQSchema read GetSchema;
  end;

  TQSType = class(TQSchema)
  protected
    FBaseId: Cardinal;
    FSQLType: Integer;
    FSize: Smallint;
  public
    constructor Create(AOwner: TQSchemas); overload;
    property BaseId: Cardinal read FBaseId write FBaseId;
    property SQLType: Integer read FSQLType write FSQLType;
    property Size: Smallint read FSize write FSize;
  end;

  TQSTypes = class(TQSList)
  protected
    function GetTypes(AIndex: Integer): TQSType;
    function CreateItem: TQSchema; override;
  public
    constructor Create(AOwner: TQSchemas); overload;
    function Add(AName: QStringW; const ATypeId, ABaseId, ASQLType: Cardinal;
      ASize: Smallint): TQSType;
    function FindById(const AId: Cardinal): TQSType; overload;
    function FindByName(const AName: QStringW): TQSType; overload;
    property Columns[AIndex: Integer]: TQSType read GetTypes;
  end;

  TQSColumn = class(TQSchema)
  private

  protected
    FSize: Integer; // 元数据大小（字段）
    FDBType: TQSType; // 数据库原始类型
    FPrecision: Word; // 精度
    FScale: Word; // 小数点位数
    function GetTable: TQSTable;
  public
    constructor Create(AOwner: TQSchemas); overload;
    property IsIndex: Boolean index SCHEMA_ISINDEX read GetFlags write SetFlags;
    // 是否是索引
    property IsPrimary: Boolean index SCHEMA_ISPRIMARY read GetFlags
      write SetFlags; // 是否是主键
    property Nullable: Boolean index SCHEMA_NULLABLE read GetFlags
      write SetFlags; // 是否允许为空
    property IsFixed: Boolean index SCHEMA_ISFIXED read GetFlags write SetFlags;
    property IsUnique: Boolean index SCHEMA_UNIQUE read GetFlags write SetFlags;
    property IsAutoInc: Boolean index SCHEMA_AUTOINC read GetFlags
      write SetFlags;
    property Visible: Boolean index SCHEMA_VISIBLE read GetFlags write SetFlags;
    property ReadOnly: Boolean index SCHEMA_READONLY read GetFlags
      write SetFlags;
    property IsCalc: Boolean index SCHEMA_CALC read GetFlags write SetFlags;
    property InWhere: Boolean index SCHEMA_INWHERE read GetFlags write SetFlags;
    property IsArray: Boolean index SCHEMA_ARRAY read GetFlags write SetFlags;

    // 是否是固定长度
    property Size: Integer read FSize write FSize; // 大小
    property DBType: TQSType read FDBType write FDBType; // 数据库原始类型
    property Precision: Word read FPrecision write FPrecision; // 精度
    property Scale: Word read FScale write FScale; // 小数点位数
    property Table: TQSTable read GetTable;
  end;

  TQSchemas = class
  protected
    FItems: TQHashTable;
  public
    constructor Create;
    destructor Destroy; override;
    function Find(AId: Cardinal): TQSchema;
  end;

const
  merChanges = [merMeta, merInserted, merModified, merDeleted];
  merChangesData = [merInserted, merModified, merDeleted];
  merAll = [merMeta, merUnmodified, merInserted, merModified, merDeleted];
  SQLTypeMap: array [TFieldType] of Cardinal = (
    // ftUnknown, ftString, ftSmallint, ftInteger, ftWord,// 0..4
    SQL_UNKNOWN, SQL_VARCHAR, SQL_SMALLINT, SQL_INTEGER, SQL_WORD,
    // ftBoolean, ftFloat, ftCurrency, ftBCD, ftDate, ftTime, ftDateTime,// 5..11
    SQL_BOOLEAN, SQL_FLOAT, SQL_MONEY, SQL_BCD, SQL_DATE, SQL_TIME,
    SQL_DATETIME,
    // ftBytes, ftVarBytes, ftAutoInc, ftBlob, ftMemo, ftGraphic, ftFmtMemo, // 12..18
    SQL_BYTES, SQL_VARBYTES, SQL_SERIAL, SQL_LARGEOBJECT, SQL_TEXT,
    SQL_PICTURE, SQL_TEXT,
    // ftParadoxOle, ftDBaseOle, ftTypedBinary, ftCursor, ftFixedChar, ftQStringW, // 19..24
    SQL_OLE, SQL_OLE, SQL_LARGEOBJECT, SQL_CURSOR, SQL_CHAR, SQL_WIDEVARCHAR,
    // ftLargeint, ftADT, ftArray, ftReference, ftDataSet, ftOraBlob, ftOraClob, // 25..31
    SQL_INT64, SQL_ADT, SQL_ARRAY, SQL_REFERENCE, SQL_DATASET, SQL_LARGEOBJECT,
    SQL_WIDETEXT,
    // ftVariant, ftInterface, ftIDispatch, ftGuid, ftTimeStamp, ftFMTBcd, // 32..37
    SQL_VARIANT, SQL_INTERFACE, SQL_IDISPATCH, SQL_GUID, SQL_TIMESTAMP, SQL_BCD,
    // ftFixedWideChar, ftWideMemo, ftOraTimeStamp, ftOraInterval, // 38..41
    SQL_WIDECHAR, SQL_WIDETEXT, SQL_TIMESTAMP, SQL_INTERVAL{$IFDEF UNICODE},
    // ftLongWord, ftShortint, ftByte, ftExtended, ftConnection, ftParams, ftStream, //42..48
    SQL_DWORD, SQL_TINYINT, SQL_BYTE, SQL_EXTENDED, SQL_CONNECTION, SQL_PARAMS,
    SQL_STREAM{$IF RTLVersion>20},
    // ftTimeStampOffset, ftObject, ftSingle
    SQL_TIMEOFFSET, SQL_OBJECT, SQL_SINGLE{$IFEND >=2010}{$ENDIF >=2009});

implementation

uses math;

resourcestring
  SBadTypeConvert = '无效的类型转换:%s->%s';
  SConvertError = '无法将 %s 转换为 %s 类型的值。';
  SCantCompareField = '指定的字段类型 [%s] 不能进行比较操作。';
  SOutOfRange = '索引 %d 越界。';
  SUnsupportDataType = '不支持的字段类型 %s';
  SNotArrayType = '%s 不是ftArray,ftObject,ftADT之一。';
  SNotConnected = '未连接到数据库，请先连接到数据库。';
  SEmptySQL = '未指定要执行的SQL脚本内容.';
  SUpdateNotSupport = '[%s] 对应的驱动程序不支持更新操作。';
  SCantConnectToDB = '无法建立与数据库的连接，错误代码:%d,错误信息:'#13#10'%s';
  SUnsupportParamValue = '不支持的参数值类型';
  SUnsupportRecordOwner = '不支持的记录所有者类型。';
  SVarExists = '名为 %s 的函数或变量已经存在。';
  SUnsupportFunction = '不支持的函数 %s。';
  SNoRecord = '当前记录集中没有可用的记录。';
  SSortFieldNotFound = '要排序的字段 [%s] 未找到。';
  SSortKeywordUnknown = '无法识别的排序关键字 [%s]。';
  SDSNotInEdit = '数据集当前未处于编辑模式，不能修改内容。';
  SFieldReadOnly = '字段 [%s] 当前为只读，无法修改内容。';
  SFieldCantSetData = '字段 [%s] 的类型 [%s] 不受支持，无法设置数据。';
  SUnsupportFieldType = '[%s] 的类型 [%s] 不是支持的数据类型。';
  SFilterLogisticError = '过滤条件中存在无法识别的逻辑操作符 [%s]。';
  SFieldCantFilter = '要过滤的字段 [%s] 不存在或不支持过滤。';
  SUnknownFilterOperator = '过滤条件中存在无法识别的比较操作符 [%s]。';
  SFilterExpUnknown = '无效的过滤表达式[%s]。';
  SRegexBadExpression = '正则表达式 "%s" 无法编译：%s';
  SInExpNeedBracket = 'In 操作符需要使用()来包含值列表:%s。';
  SRightBracketNeeded = '表达式需要结束符")"，实际：^s。';
  SUnsupportNullCompare = '不支持当前操作符与 null 进行比较。';
  SFieldNotFound = '指定的字段 %s 不存在。';
  SBadLocateValues = '要定位的值数量与需要定位的字段数不匹配。';
  SMultiEditUnsupport = '同时编辑克隆的多个数据集不受支持。';
  SCantMarkRecordAsModified = '不能将其它状态的记录修改为已修改状态。';
  SCanWriteConvertedStream = '无法写入数据到目标格式，空间不足？';
  SMergeFieldTypeMismatch = '要合并的数据字段 %s 类型不匹配。';
  SFieldTypeMissmatch = '第一个数据集字段 %s 和第二个数据集字段 %s 类型不匹配。';
  SMismathDataType = '交换表顺序要求数据列类型保持一致。';
  SUnclosedToken = '未结束的关键词定义: %s 。';
  SNoDetailFilter = '子表不能设置 Filter 属性。';
  SCircularDataLink = '数据源不能循环引用。';
  SParamNumberMismatch = '提供的参数个数 %d 与需要的参数个数 %d 不匹配。';
  SSQLNoReturnRecords = 'SQL 脚本没有返回任何可用的结果集。';

var
  QDataSetPool: TQSimplePool;

const
  ListDelimiter: PQCharW = ',;';
  NullChar: WideChar = #0;
  QValueTypeMap: array [TFieldType] of TQValueDataType = (
    // ftUnknown, ftString, ftSmallint, ftInteger, ftWord,// 0..4
    vdtNull, vdtString, vdtInteger, vdtInteger, vdtInteger,
    // ftBoolean, ftFloat, ftCurrency, ftBCD, ftDate, ftTime, ftDateTime,// 5..11
    vdtBoolean, vdtFloat, vdtCurrency, vdtBcd, vdtDateTime, vdtDateTime,
    vdtDateTime,
    // ftBytes, ftVarBytes, ftAutoInc, ftBlob, ftMemo, ftGraphic, ftFmtMemo, // 12..18
    vdtStream, vdtStream, vdtInt64, vdtStream, vdtStream, vdtStream, vdtStream,
    // ftParadoxOle, ftDBaseOle, ftTypedBinary, ftCursor, ftFixedChar, ftQStringW, // 19..24
    vdtStream, vdtStream, vdtStream, vdtInteger, vdtString, vdtString,
    // ftLargeint, ftADT, ftArray, ftReference, ftDataSet, ftOraBlob, ftOraClob, // 25..31
    vdtInt64, vdtInt64, vdtArray, vdtInt64, vdtInt64, vdtStream, vdtString,
    // ftVariant, ftInterface, ftIDispatch, ftGuid, ftTimeStamp, ftFMTBcd, // 32..37
    vdtStream, vdtStream, vdtStream, vdtGuid, vdtDateTime, vdtBcd,
    // ftFixedWideChar, ftWideMemo, ftOraTimeStamp, ftOraInterval, // 38..41
    vdtString, vdtStream, vdtDateTime, vdtInterval{$IFDEF UNICODE},
    // ftLongWord, ftShortint, ftByte, ftExtended, ftConnection, ftParams, ftStream, //42..48
    vdtInt64, vdtInteger, vdtInteger, vdtFloat, vdtInt64, vdtInt64,
    vdtStream{$IF RTLVersion>20},
    // ftTimeStampOffset, ftObject, ftSingle
    vdtDateTime, vdtInt64, vdtFloat{$IFEND >=2010}{$ENDIF >=2009});

type
  PDataSetState = ^TDataSetState;

function RegexStr(const S: QStringW):
{$IF RTLVersion<=24}UTF8String{$ELSE}UnicodeString{$IFEND};
begin
{$IF RTLVersion<19}
  Result := System.UTF8Encode(S);
{$ELSE}
{$IF RTLVersion<=24}
  Result := UTF8String(S);
{$ELSE}
  Result := S;
{$IFEND}
{$IFEND}
end;

function DBType2FieldType(AType: Cardinal): TFieldType;
begin
  case AType of
    SQL_TINYINT:
      Result := {$IFDEF UNICODE}ftShortint{$ELSE}ftSmallint{$ENDIF};
    SQL_BYTE:
      Result := {$IFDEF UNICODE}ftByte{$ELSE}ftWord{$ENDIF};
    SQL_SMALLINT:
      Result := ftSmallint;
    SQL_WORD:
      Result := ftWord;
    SQL_INTEGER:
      Result := ftInteger;
    SQL_DWORD:
      Result := {$IFDEF UNICODE}ftLongword{$ELSE}ftLargeint{$ENDIF};
    SQL_INT64:
      Result := ftLargeint;
    SQL_QWORD:
      Result := ftLargeint;
    SQL_SMALLSERIAL:
      Result := ftSmallint;
    SQL_SERIAL:
      Result := ftInteger;
    SQL_BIGSERIAL:
      Result := ftLargeint;
    SQL_SINGLE:
      Result := {$IF RTLVersion>20}ftSingle{$ELSE}ftFloat{$IFEND};
    SQL_FLOAT:
      Result := ftFloat;
    SQL_BCD:
      Result := ftBcd;
    SQL_MONEY:
      Result := ftCurrency;
    SQL_SMALLMONEY:
      Result := ftCurrency;
    SQL_EXTENDED:
      Result := ftFloat;
    // 字符串类型
    SQL_CHAR:
      Result := ftFixedChar;
    SQL_VARCHAR:
      Result := ftString;
    SQL_WIDECHAR:
      Result := ftFixedWideChar;
    SQL_WIDEVARCHAR:
      Result := ftWideString;
    SQL_TEXT:
      Result := ftMemo;
    SQL_WIDETEXT:
      Result := ftWideMemo;
    SQL_XML:
      Result := ftWideMemo;
    SQL_JSON:
      Result := ftWideMemo;
    SQL_TREE:
      Result := ftWideMemo;
    SQL_BYTES:
      Result := ftBytes;
    SQL_VARBIT:
      Result := ftVarBytes;
    SQL_VARBINARY:
      Result := ftVarBytes;
    SQL_LARGEOBJECT:
      Result := ftBlob;
    SQL_PICTURE:
      Result := ftGraphic;
    // SQL_STREAM:
    // Result := ftBlob;
    SQL_OLE:
      Result := ftBlob;
    SQL_BOOLEAN:
      Result := ftBoolean; // 布尔
    SQL_UUID:
      Result := ftGuid;
    SQL_BITS:
      Result := ftBytes;
    SQL_VARBITS:
      Result := ftVarBytes;
    // 日期时间类型
    SQL_DATE:
      Result := ftDate;
    SQL_TIME:
      Result := ftTime;
    SQL_SMALLDATETIME:
      Result := ftDateTime;
    SQL_DATETIME:
      Result := ftDateTime;
    SQL_TIMESTAMP:
      Result := ftDateTime;
    SQL_INTERVAL:
      Result := ftOraInterval;
    SQL_TIMEOFFSET:
      Result := ftDateTime;
    SQL_DATASET:
      Result := ftDataSet;
    SQL_CURSOR:
      Result := ftCursor;
    SQL_VARIANT:
      Result := ftVariant;
    SQL_INTERFACE:
      Result := ftInterface;
    SQL_IDISPATCH:
      Result := ftIDispatch;
    SQL_OBJECT:
      Result := {$IF RTLVersion>20}ftObject{$ELSE}ftLargeint{$IFEND};
    SQL_PARAMS:
      Result := {$IFDEF UNICODE}ftParams{$ELSE}ftLargeint{$ENDIF};
    SQL_CONNECTION:
      Result := {$IFDEF UNICODE}ftConnection{$ELSE}ftLargeint{$ENDIF};
    SQL_REFERENCE:
      Result := ftReference;
    SQL_ARRAY:
      Result := ftArray;
    SQL_ADT:
      Result := ftADT;
    SQL_PG_OID:
      Result := {$IFDEF UNICODE}ftLongword{$ELSE}ftLargeint{$ENDIF};
    SQL_PG_POINT:
      Result := ftMemo; //
    SQL_PG_LINE:
      Result := ftMemo;
    SQL_PG_LSEG:
      Result := ftMemo;
    SQL_PG_BOX:
      Result := ftMemo;
    SQL_PG_PATH:
      Result := ftMemo;
    SQL_PG_POLYGON:
      Result := ftMemo;
    SQL_PG_CIRCLE:
      Result := ftMemo;
    SQL_PG_CIDR:
      Result := ftMemo;
    SQL_PG_INET:
      Result := ftString;
    SQL_PG_MACADDR:
      Result := ftString;
    SQL_PG_ROWS:
      Result := {$IF RTLVersion>20}ftObject{$ELSE}ftMemo{$IFEND};
    SQL_PG_ACL:
      Result := {$IF RTLVersion>20}ftObject{$ELSE}ftMemo{$IFEND};
    SQL_PG_ENUM:
      Result := ftString;
    SQL_PG_TSVECTOR:
      Result := ftString;
    SQL_PG_TSQUERY:
      Result := ftString
  else // 其它不识别的类型转换为字符串处理
    Result := ftUnknown;
  end;
end;

{ TQRecord }

{$IFDEF AUTOREFCOUNT}

function TQRecord.__ObjAddRef: Integer;
begin
  Result := inherited;
end;

function TQRecord.__ObjRelease: Integer;
begin
  Result := inherited;
end;
{$ENDIF}

/// <summary>复制另一个记录的值到本记录，注意它不检查太多东西，所以除非你知道干什么，否则不要用</summary>
procedure TQRecord.AddRef;
begin
{$IFDEF AUTOREFCOUNT}
  __ObjAddRef;
{$ELSE}
  AtomicIncrement(FRefCount);
{$ENDIF}
end;

procedure TQRecord.Assign(ASource: TQRecord);
var
  I: Integer;
begin
  FStatus := ASource.Status;
  FOriginIndex := ASource.FOriginIndex;
  FChangedIndex := ASource.FChangedIndex;
  FSortedIndex := ASource.FSortedIndex;
  FFilteredIndex := ASource.FFilteredIndex;
  FBookmark := ASource.FBookmark;
  FBookmarkFlag := ASource.FBookmarkFlag;
  if Assigned(FBookmark) then
  begin
    ASource := FBookmark;
    for I := High(ASource.FValues) to High(FValues) do
    begin
      FValues[I].OldValue.Reset;
      FValues[I].NewValue.Reset;
    end;
    SetLength(FValues, Length(ASource.FValues))
  end;
  CopyValues(ASource);
end;

procedure TQRecord.ClearValues;
var
  I, C: Integer;
begin
  C := High(FValues);
  I := 0;
  while I <= C do
  begin
    FValues[I].OldValue.Reset;
    FValues[I].NewValue.Reset;
    Inc(I);
  end;
end;

procedure TQRecord.CopyValues(const ASource: TQRecord);
var
  L: Integer;
  I: Integer;
begin
  L := High(FValues);
  if L > High(ASource.FValues) then
    L := High(ASource.FValues);
  for I := 0 to L do
  begin
    FValues[I].OldValue.Copy(ASource.FValues[I].OldValue, False);
    FValues[I].NewValue.Copy(ASource.FValues[I].NewValue, False);
    FValues[I].Changed := ASource.FValues[I].Changed;
  end;
end;

constructor TQRecord.Create(AFields: TQFieldDefs);
begin
  inherited Create;
  FOriginIndex := -1;
  FChangedIndex := -1;
  FSortedIndex := -1;
  FFilteredIndex := -1;
{$IFNDEF AUTOREFCOUNT}
  FRefCount := 0;
{$ENDIF}
  FBookmark := nil;
  FStatus := usUnmodified;
  FOwner := AFields.Owner as TComponent;
  FFields := AFields;
  if Assigned(AFields.DataSet) then
  begin
    // 如果是克隆的，只有克隆源有一份实际的数据，剩下的都是通过Bookmark的引用
    if Assigned(TQDataSet(AFields.DataSet).FCloneSource) then
      SetLength(FValues, 0)
    else
    begin
      SetLength(FValues, FFields.Count);
    end;
  end
  else
    SetLength(FValues, FFields.Count);
  // OutputDebugString(PChar(IntToHex(IntPtr(Self), 8) + ' Created.'));
end;

destructor TQRecord.Destroy;
begin
  // OutputDebugString(PChar(IntToHex(IntPtr(Self), 8) + ' free.'));
  ClearValues;
  TQRecord(FBookmark) := nil;
  inherited;
end;

function TQRecord.GetModified: Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := 0 to High(FValues) do
  begin
    if FValues[I].Changed then
    begin
      Result := True;
      Break;
    end;
  end;
end;

procedure TQRecord.Release;
begin
{$IFDEF AUTOREFCOUNT}
  __ObjRelease;
{$ELSE}
  if AtomicDecrement(FRefCount) = 0 then
    FreeObject(Self);
{$ENDIF}
end;

procedure TQRecord.Reset;
begin
  FOriginIndex := -1;
  FChangedIndex := -1;
  FSortedIndex := -1;
  FFilteredIndex := -1;
  FBookmark := nil;
  FStatus := usUnmodified;
  ClearValues;
end;

{ TQFieldDef }

procedure TQFieldDef.Assign(Source: TPersistent);
var
  ADef: TQFieldDef;
begin
  inherited;
  if Source is TQFieldDef then
  begin
    ADef := TQFieldDef(Source);
    FSchema := ADef.FSchema;
    FDatabase := ADef.FDatabase;
    FTable := ADef.FTable;
    FBaseName := ADef.FBaseName;
    FDBType := ADef.FDBType;
    FFlags := ADef.FFlags;
    FValueType := ADef.FValueType;
    FDBNo := ADef.FDBNo;
    FOnCompare := ADef.FOnCompare;
    FScale := ADef.FScale;
  end
  else
    LookupValueType;
end;

constructor TQFieldDef.Create(Owner: TFieldDefs; const Name:
{$IFDEF UNICODE}string{$ELSE}WideString{$ENDIF}; DataType: TFieldType;
  Size: Integer; Required: Boolean; FieldNo: Integer);
begin
  inherited;
  LookupValueType;
end;

destructor TQFieldDef.Destroy;
begin

  inherited;
end;

function TQFieldDef.GetCount: Integer;
begin
  Result := ChildDefs.Count;
end;

function TQFieldDef.GetDBType: Integer;
begin
  if FDBType = 0 then
    Result := SQLTypeMap[DataType]
  else
    Result := FDBType;
end;

function TQFieldDef.GetFixed: Boolean;
begin
  Result := faFixed in Attributes;
end;

function TQFieldDef.GetFlags(const Index: Integer): Boolean;
begin
  Result := (FFlags and Index) <> 0;
end;

function TQFieldDef.GetInternalFlags: Integer;
begin
  Result := FFlags;
  if not Required then
    Result := Result or SCHEMA_NULLABLE;
  if ReadOnly then
    Result := Result or SCHEMA_READONLY;
  if Visible then
    Result := Result or SCHEMA_VISIBLE;
  if faUnnamed in Attributes then
    Result := Result or SCHEMA_UNNAMED;
end;

function TQFieldDef.GetInWhere(const Index: Integer): Boolean;
begin
  Result := Length(BaseName) > 0;
end;

function TQFieldDef.GetIsArray: Boolean;
begin
  Result := (DataType = ftArray) or ((Flags and SCHEMA_ARRAY) <> 0);
end;

function TQFieldDef.GetIsBinary: Boolean;
begin
  Result := (DBType and SQL_MASK_BINARY) <> 0;
end;

function TQFieldDef.GetIsBlob: Boolean;
begin
  Result := (DBType and SQL_MASK_LONGSIZE) = SQL_MASK_LONGSIZE;
end;

function TQFieldDef.GetItems(AIndex: Integer): TQFieldDef;
begin
  Result := inherited ChildDefs[AIndex] as TQFieldDef;
end;

function TQFieldDef.GetNullable: Boolean;
begin
  Result := not(faRequired in Attributes);
end;

function TQFieldDef.GetOnCompare: TQValueCompare;
begin
  if not Assigned(FOnCompare) then
    LookupValueType;
  Result := FOnCompare;
end;

function TQFieldDef.GetReadOnly: Boolean;
begin
  Result := faReadonly in Attributes;
end;

function TQFieldDef.GetValueType: TQValueDataType;
begin
  if FValueType in [vdtNull, vdtUnset] then
    LookupValueType;
  Result := FValueType;
end;

function TQFieldDef.GetVisible: Boolean;
begin
  Result := not(faHiddenCol in Attributes);
end;

function TQFieldDef.LookupCompareProc(AIgnoreCase: Boolean): TQValueCompare;
begin
  FOnCompare := qvalue.LookupCompareProc(FValueType, FValueType,
    AIgnoreCase, False);
  Result := FOnCompare;
end;

procedure TQFieldDef.LookupValueType;
begin
  FValueType := QValueTypeMap[DataType];
  LookupCompareProc(False);
end;

procedure TQFieldDef.SetDBType(const Value: Integer);
begin
  if FDBType <> Value then
  begin
    FDBType := Value;
    if FDBType = Integer(SQL_PG_INET) then
    begin
      DataType := ftString;
      Size := 30;
    end
    else
    begin
      DataType := DBType2FieldType(FDBType);
      if DataType = ftGuid then
        Size := 38
      else if DataType = ftUnknown then
      begin
        DataType := ftWideString;
        Size := MaxInt;
      end;
    end;
    LookupValueType;
  end;
end;

procedure TQFieldDef.SetField(const Value: TField);
begin
  if FField <> Value then
    FField := Value;
end;

procedure TQFieldDef.SetFixed(const Value: Boolean);
begin
  if Value then
    Attributes := Attributes + [faFixed]
  else
    Attributes := Attributes - [faFixed];
  SetFlags(SCHEMA_ISFIXED, Value);
end;

procedure TQFieldDef.SetFlags(const Index: Integer; const Value: Boolean);
begin
  if Value then
    FFlags := FFlags or Index
  else
    FFlags := FFlags and (not Index);
end;

procedure TQFieldDef.SetInternalFlags(const Value: Integer);
begin
  if FFlags <> Value then
  begin
    FFlags := Value;
  end;
end;

procedure TQFieldDef.SetIsArray(const Value: Boolean);
begin
  SetFlags(SCHEMA_ARRAY, Value);
  if Value then
  begin
    DataType := ftWideString;
    Size := MaxInt;
    // DataType := ftArray;
  end;
end;

procedure TQFieldDef.SetNullable(const Value: Boolean);
begin
  if Value then
    Attributes := Attributes - [faRequired]
  else
    Attributes := Attributes + [faRequired];
  SetFlags(SCHEMA_NULLABLE, Value);
end;

procedure TQFieldDef.SetReadOnly(const Value: Boolean);
begin
  if Value then
    Attributes := Attributes + [faReadonly]
  else
    Attributes := Attributes - [faReadonly];
  SetFlags(SCHEMA_READONLY, Value);
end;

procedure TQFieldDef.SetScale(const Value: Word);
begin
  FScale := Value;
end;

procedure TQFieldDef.SetVisible(const Value: Boolean);
begin
  if Value then
    Attributes := Attributes - [faHiddenCol]
  else
    Attributes := Attributes + [faHiddenCol];
  SetFlags(SCHEMA_VISIBLE, Value);
end;

{ TQDataSet }

function TQDataSet.ActiveRecordBuffer: TQRecord;
begin
  Result := TQRecord(ActiveBuffer);
end;
{$IFDEF NEXTGEN}

function TQDataSet.AllocRecBuf: TRecBuf;
begin
  Result := TRecBuf(AllocRecord);
end;
{$ENDIF}

procedure TQDataSet.ActiveRecordsChanged;
begin
  if IsSorted then
    FActiveRecords := FSortedRecords
  else if State = dsFilter then
    FActiveRecords := FOriginRecords
  else if Filtered then
    FActiveRecords := FFilteredRecords
  else
    FActiveRecords := FOriginRecords;
end;

procedure TQDataSet.AddDataSet(ADataSet: TQDataSet);
var
  I: Integer;
begin
  ADataSet.CheckActive;
  for I := 0 to High(FRecordsets) do
  begin
    if Recordsets[I] = ADataSet then
      Exit;
  end;
  SetLength(FRecordsets, Length(FRecordsets) + 1);
  FRecordsets[High(FRecordsets)] := ADataSet;
  ADataSet.FreeNotification(Self);
  if not Active then
  begin
    Clone(ADataSet);
    FActiveRecordset := 0;
  end;
end;

procedure TQDataSet.AddRecord(ARec: TQRecord; Append: Boolean);
begin
  InternalAddRecord(ARec, Append);
end;

function TQDataSet.AllocRecord: TQRecord;
begin
  Result := TQRecord.Create(FieldDefs as TQFieldDefs);
  Result.AddRef;
end;
{$IFNDEF UNICODE}

function TQDataSet.AllocRecordBuffer: PChar;
begin
  Result := PChar(AllocRecord);
end;
{$ENDIF}
{$IFNDEF NEXTGEN}
{$IF RTLVersion>19}

function TQDataSet.AllocRecordBuffer: TRecordBuffer;
begin
  Result := TRecordBuffer(AllocRecord);
end;
{$IFEND}
{$ENDIF}

procedure TQDataSet.ApplyChanges;
begin
  InternalApplyChanges(FProvider);
end;

function TQDataSet.Avg(AFieldName: QStringW): Variant;
begin
  if FActiveRecords.Count > 0 then
    Result := Sum(AFieldName) / FActiveRecords.Count
  else
    Result := 0;
end;

procedure TQDataSet.BindFields(Binding: Boolean);
var
  I: Integer;
  ADef: TQFieldDef;
begin
  inherited;
  if Binding then
  begin
    for I := 0 to FieldDefs.Count - 1 do
    begin
      ADef := FieldDefs[I] as TQFieldDef;
      ADef.Field := FieldByNumber(ADef.FieldNo);
    end;
  end;
end;

function TQDataSet.BookmarkValid(Bookmark: TBookmark): Boolean;
var
  pBookmark: PPointer;
begin
  Result := False;
{$IFDEF UNICODE}
  if Length(Bookmark) = BookmarkSize then
{$ENDIF}
  begin
    pBookmark := PPointer({$IFDEF UNICODE}@Bookmark[0]{$ELSE}Bookmark{$ENDIF});
    if pBookmark <> nil then
    begin
      Inc(pBookmark);
      Result := pBookmark^ = Self;
    end;
  end;
end;

function TQDataSet.BufferOfRecNo(ARecNo: Integer): TQRecord;
begin
  if PageSize <> 0 then
    ARecNo := PageIndex * PageSize + ARecNo;
  if ARecNo >= FActiveRecords.Count then
    ARecNo := FActiveRecords.Count - 1;
  Result := FActiveRecords[ARecNo];
end;

procedure TQDataSet.CancelChanges;
var
  I, J: Integer;
  ARec: TQRecord;
  ADataSet: TQDataSet;
begin
  if Assigned(FCloneSource) then // 如果是克隆的，那由克隆源负责取消变更
    FCloneSource.CancelChanges
  else
  begin
    I := 0;
    while I < FOriginRecords.Count do
    begin
      ARec := FOriginRecords[I];
      if ARec.Status = usModified then
      begin
        ARec.Status := usUnmodified;
        for J := 0 to High(ARec.Values) do
        begin
          ARec.Values[J].Changed := False;
          ARec.Values[J].NewValue.Reset;
        end;
      end
      else if ARec.Status = usInserted then // 新插入的记录，那么移除它
      begin
        FOriginRecords.Delete(I);
        Continue;
      end;
      Inc(I);
    end;
    // 恢复已经删除的记录
    I := 0;
    while I < FChangedRecords.Count do
    begin
      ARec := FChangedRecords[I];
      if ARec.Status = usDeleted then
      begin
        if (ARec.FOriginIndex >= 0) and
          (ARec.FOriginIndex < FOriginRecords.Count) then
          FOriginRecords.Insert(ARec.FOriginIndex, ARec);
      end;
      Inc(I);
    end;
    FChangedRecords.Clear();
    FOriginRecords.Clean;
    for I := 0 to FClones.Count - 1 do
    begin
      ADataSet := FClones[I];
      ADataSet.Clone(Self);
    end;
    // 取消变更后，直接定位到首行
    First;
  end;
end;

procedure TQDataSet.ClearHashs(AHashs: TQHashTable);
var
  I: Integer;
  AList: PQHashList;
begin
  for I := 0 to AHashs.BucketCount - 1 do
  begin
    AList := AHashs[I];
    while AList <> nil do
    begin
      Dispose(PQRecordHash(AList.Data));
      AList := AList.Next;
    end;
  end;
  AHashs.Clear;
end;

procedure TQDataSet.ClearRecords(AVisibleOnly: Boolean);
begin
  if AVisibleOnly then
  begin

  end
  else
  begin
  end;
end;

procedure TQDataSet.ClearSort(var AExp: PQSortExp);
var
  ANext: PQSortExp;
begin
  while Assigned(AExp) do
  begin
    ANext := AExp.Next;
    Dispose(AExp);
    AExp := ANext;
  end;
end;

procedure TQDataSet.Clone(ASource: TQDataSet);
begin
  Close;
  FOpenBy := dsomByClone;
  FCloneSource := ASource;
  Open;
end;

procedure TQDataSet.CloneNotify(ARec: TQRecord; AEvent: TQRecordChangeNotify);
var
  I: Integer;
  procedure NotifyClones(ADataSet: TQDataSet);
  begin
    ADataSet.FOriginRecords.Clean;
    case AEvent of
      rcnDeleted:
        ADataSet.CloneSourceDeleted(ARec);
      rcnInserted:
        ADataSet.CloneSourceInserted(ARec);
      rcnModified:
        ADataSet.CloneSourceEdited(ARec);
    end;
  end;

begin
  if Assigned(FCloneSource) then
    NotifyClones(FCloneSource)
  else
  begin
    for I := 0 to FClones.Count - 1 do
      NotifyClones(TQDataSet(FClones[I]));
  end;
end;

procedure TQDataSet.CloneSourceDeleted(ARec: TQRecord);
var
  ABuf: TQRecord;
  ANewRecNo: Integer;
begin
  ABuf := FOriginRecords[ARec.OriginIndex];
  ANewRecNo := RecNo - 1;
  if ARec.FOriginIndex < ANewRecNo then
    Dec(ANewRecNo);
  if Filtered and (ABuf.FilteredIndex <> -1) then
  begin
    ANewRecNo := ABuf.FilteredIndex;
    FFilteredRecords.Delete(ABuf.FilteredIndex);
  end;
  if IsSorted and (ABuf.FSortedIndex <> -1) then
  begin
    ANewRecNo := ABuf.FSortedIndex;
    FSortedRecords.Delete(ABuf.FSortedIndex);
  end;
  FOriginRecords.Delete(ABuf.FOriginIndex);
  FActiveRecords.Clean;
  FRecordNo := ANewRecNo;
  Resync([]);
end;

procedure TQDataSet.CloneSourceEdited(ARec: TQRecord);
var
  ARealRecord: TQRecord;
  I: Integer;
begin
  if Filtered or (Length(Sort) <> 0) then
  begin
    ARealRecord := RealRecord(ARec);
    if Assigned(FCloneSource) then
    begin
      for I := 0 to FOriginRecords.Count - 1 do
      begin
        if FOriginRecords[I].Bookmark = ARealRecord then
        begin
          ARealRecord := FOriginRecords[I];
          Break;
        end;
      end;
    end;
    if InternalAddToFiltered(ARealRecord) then
      InternalAddToSorted(ARealRecord);
  end;
  DataEvent(deDataSetChange, 0);
end;

procedure TQDataSet.CloneSourceInserted(ARec: TQRecord);
var
  ABuf: TQRecord;
begin
  ABuf := AllocRecord;
  ABuf.FBookmark := ARec;
  ABuf.FOriginIndex := ARec.FOriginIndex;
  ABuf.FStatus := ARec.FStatus;
  FOriginRecords.Insert(ABuf.FOriginIndex, ABuf);
  if InternalAddToFiltered(ARec) then
    InternalAddToSorted(ARec);
  FRecordNo := RecNo - 1;
  Resync([]);
end;

procedure TQDataSet.CopyFrom(ASource: TDataSet; AFields: QStringW = '');
var
  ABookmark: {$IFDEF UNICODE}TBookmark{$ELSE}TBookmarkStr{$ENDIF};
  ARec: TQRecord;
  ACopyFields: array of TFieldDef;
  procedure CopyValue(ADef: TQFieldDef; var ADest: TQValue;
    const ASource: Variant);
  begin
    if VarIsNull(ASource) then
      ADest.Reset
    else
    begin
      if ADef.ValueType = vdtUnset then
        ADef.LookupValueType;
      ADest.TypeNeeded(ADef.ValueType);
      ADest.AsVariant := ASource;
    end;
  end;
  procedure ParseFields;
  var
    p: PQCharW;
    AFieldName: QStringW;
    ADef: TFieldDef;
    I: Integer;
  begin
    SetLength(ACopyFields, ASource.FieldDefs.Count);
    FieldDefs.BeginUpdate;
    try
      if Length(AFields) = 0 then
      begin
        FieldDefs.Assign(ASource.FieldDefs);
        I := 0;
        while I < ASource.FieldDefs.Count do
        begin
          ACopyFields[I] := ASource.FieldDefs[I];
          Inc(I);
        end;
      end
      else
      begin
        p := PQCharW(AFields);
        I := 0;
        while p^ <> #0 do
        begin
          AFieldName := DecodeTokenW(p, ListDelimiter, WideChar(#0), True);
          ADef := ASource.FieldDefs.Find(AFieldName);
          if ADef = nil then
            DatabaseError(Format(SFieldNotFound, [AFieldName]));
          FieldDefs.AddFieldDef.Assign(ADef);
          ACopyFields[I] := ADef;
          Inc(I);
        end;
        SetLength(ACopyFields, I);
      end;
    finally
      FieldDefs.EndUpdate;
    end;
  end;
  procedure DoCopy;
  var
    ADef: TQFieldDef;
    AField: TField;
    ASavedState: TDataSetState;
    I: Integer;
    ASourceStream, ADestStream: TStream;
  begin
    ASource.First;
    while not ASource.Eof do
    begin
      ARec := AllocRecord;
      ARec.FOriginIndex := FOriginRecords.Add(ARec);
      for I := 0 to High(ACopyFields) do
      begin
        ADef := FieldDefs[I] as TQFieldDef;
        AField := ASource.Fields[ACopyFields[I].FieldNo - 1];
        if AField.IsBlob then
        begin
          if ASource.UpdateStatus <> usUnmodified then
          begin
            ASavedState := ASource.State;
            PDataSetState(@ASource.State)^ := dsOldValue;
            try
              if not AField.IsNull then
              begin
                ARec.Values[I].OldValue.TypeNeeded(vdtStream);
                ASourceStream := ASource.CreateBlobStream(AField, bmRead);
                ADestStream := ARec.Values[I].OldValue.AsStream;
                ADestStream.CopyFrom(ASourceStream, 0);
                ASourceStream.Free;
              end;
              PDataSetState(@ASource.State)^ := dsNewValue;
              if not AField.IsNull then
              begin
                ARec.Values[I].NewValue.TypeNeeded(vdtStream);
                ASourceStream := ASource.CreateBlobStream(AField, bmRead);
                ADestStream := ARec.Values[I].NewValue.AsStream;
                ADestStream.CopyFrom(ASourceStream, 0);
                ASourceStream.Free;
                ARec.Values[I].Changed := True;
              end;
            finally
              PDataSetState(@ASource.State)^ := ASavedState;
            end;
          end
          else if not AField.IsNull then
          begin
            ARec.Values[I].OldValue.TypeNeeded(vdtStream);
            ASourceStream := ASource.CreateBlobStream(AField, bmRead);
            ADestStream := ARec.Values[I].OldValue.AsStream;
            ADestStream.CopyFrom(ASourceStream, 0);
            ASourceStream.Free;
          end;;
        end
        else
        begin
          CopyValue(ADef, ARec.Values[I].OldValue, AField.OldValue);
          CopyValue(ADef, ARec.Values[I].NewValue, AField.NewValue);
        end;
        ARec.Values[I].Changed := ASource.UpdateStatus <> usUnmodified;
      end;
      ARec.FStatus := ASource.UpdateStatus;
      if ARec.FStatus <> usUnmodified then
        ARec.FChangedIndex := FChangedRecords.Add(ARec);
      ARec.Release;
      ASource.Next;
    end;
    Open;
  end;

begin
  if ASource is TQDataSet then
    CopyFrom(ASource as TQDataSet, dcmCurrents, AFields)
  else
  begin
    Close;
    ParseFields;
    ABookmark := ASource.Bookmark;
    ASource.DisableControls;
    try
      DoCopy;
    finally
      ASource.Bookmark := ABookmark;
      ASource.EnableControls;
    end;
  end;
end;

function TQDataSet.DistinctCount(AFieldNames: QStringW): Integer;
var
  AHashs: TQHashTable;
  AFieldDefs: TQFieldDefArray;
begin
  AHashs := TQHashTable.Create(FActiveRecords.Count);
  try
    DecodeFieldDefs(AFieldNames, AFieldDefs);
    HashRecords(FActiveRecords, AFieldDefs, AHashs);
    RemoveDupFromHash(AHashs, nil, nil);
    Result := AHashs.Count;
  finally
    ClearHashs(AHashs);
    FreeObject(AHashs);
  end;
end;

procedure TQDataSet.CopyFrom(ASource: TQDataSet; AMethod: TQDataCopySource;
  AFields: QStringW);
var
  I, J: Integer;
  ARec, ACopy: TQRecord;
  ACopyFields: TQFieldDefArray;
  procedure ParseFields;
  var
    p: PQCharW;
    AFieldName: QStringW;
    ADef: TQFieldDef;
  begin
    SetLength(ACopyFields, ASource.FieldDefs.Count);
    FieldDefs.BeginUpdate;
    try
      if Length(AFields) = 0 then
      begin
        FieldDefs.Assign(ASource.FieldDefs);
        I := 0;
        while I < ASource.FieldDefs.Count do
        begin
          ACopyFields[I] := ASource.FieldDefs[I] as TQFieldDef;
          Inc(I);
        end;
      end
      else
      begin
        p := PQCharW(AFields);
        I := 0;
        while p^ <> #0 do
        begin
          AFieldName := DecodeTokenW(p, ListDelimiter, WideChar(#0), True);
          ADef := ASource.FieldDefs.Find(AFieldName) as TQFieldDef;
          if ADef = nil then
            DatabaseError(Format(SFieldNotFound, [AFieldName]));
          FieldDefs.AddFieldDef.Assign(ADef);
          ACopyFields[I] := ADef;
          Inc(I);
        end;
        SetLength(ACopyFields, I);
      end;
    finally
      FieldDefs.EndUpdate;
    end;
  end;
  procedure CopyRecords(AList: TQRecords; AStartIdx, ACount: Integer;
    AcceptStatus: TUpdateStatusSet);
  var
    AValue: PQColumnValue;
  begin
    if AStartIdx + ACount > AList.Count then
      ACount := AList.Count - AStartIdx;
    I := AStartIdx;
    while ACount > 0 do
    begin
      ARec := AList[I];
      if ARec.Bookmark <> nil then // 如果是克隆来的引用，则指向原始记录
        ARec := ARec.Bookmark;
      if ARec.Status in AcceptStatus then
      begin
        ACopy := AllocRecord;
        ACopy.FStatus := ARec.FStatus;
        if ACopy.Status <> usDeleted then
          ACopy.FOriginIndex := FOriginRecords.Add(ACopy);
        if ACopy.Status <> usUnmodified then
          ACopy.FChangedIndex := FChangedRecords.Add(ACopy);
        // 复制字段的值
        J := 0;
        while J <= High(ACopyFields) do
        begin
          AValue := @ARec.Values[ACopyFields[J].FieldNo - 1];
          ACopy.Values[J].Changed := AValue.Changed;
          if AValue.Changed then
            ACopy.Values[J].NewValue.Copy(AValue.NewValue, False);
          if ACopy.FStatus <> usInserted then
            ACopy.Values[J].OldValue.Copy(AValue.OldValue, False);
          Inc(J);
        end;
        ACopy.Release;
      end;
      Inc(I);
      Dec(ACount);
    end;
  end;

begin
  Close;
  ParseFields;
  FOpenBy := dsomByCopy;
  case AMethod of
    dcmUnknown, dcmView: // 如果是未知，则取当前用户查看视图的内容
      begin
        if ASource.PageSize > 0 then
        begin
          I := ASource.PageSize * ASource.PageIndex;
          J := ASource.PageSize;
        end
        else
        begin
          I := 0;
          J := ASource.FActiveRecords.Count;
        end;
        if ASource.Filtered or (Length(ASource.Sort) > 0) then
        begin
          CopyRecords(ASource.FActiveRecords, I, J, [usUnmodified, usInserted,
            usDeleted, usModified]);
        end
        else
        begin
          if Assigned(ASource.FCloneSource) then
            CopyRecords(ASource.FCloneSource.FOriginRecords, I, J,
              [usUnmodified, usInserted, usDeleted, usModified])
          else
            CopyRecords(ASource.FOriginRecords, I, J,
              [usUnmodified, usInserted, usDeleted, usModified]);
        end;
      end;
    dcmCurrents:
      begin
        if Assigned(ASource.FCloneSource) then
          CopyRecords(ASource.FCloneSource.FOriginRecords, 0,
            ASource.FCloneSource.FOriginRecords.Count,
            [usUnmodified, usInserted, usDeleted, usModified])
        else
          CopyRecords(ASource.FOriginRecords, 0, ASource.FOriginRecords.Count,
            [usUnmodified, usInserted, usDeleted, usModified]);
      end;
    dcmOrigins: // 最原始未变更的记录，注意，如果删除过记录，则被删除过的记录始终位于最后
      begin
        if Assigned(ASource.FCloneSource) then
          CopyRecords(ASource.FCloneSource.FOriginRecords, 0,
            ASource.FCloneSource.FOriginRecords.Count, [usUnmodified])
        else
          CopyRecords(ASource.FOriginRecords, 0, ASource.FOriginRecords.Count,
            [usUnmodified]);
      end;
    dcmInserted:
      if Assigned(ASource.FCloneSource) then
        CopyRecords(ASource.FCloneSource.ChangedRecords, 0,
          ASource.FCloneSource.ChangedRecords.Count, [usInserted])
      else
        CopyRecords(ASource.ChangedRecords, 0, ASource.ChangedRecords.Count,
          [usInserted]);
    dcmDeleted:
      if Assigned(ASource.FCloneSource) then
        CopyRecords(ASource.FCloneSource.ChangedRecords, 0,
          ASource.FCloneSource.ChangedRecords.Count, [usDeleted])
      else
        CopyRecords(ASource.ChangedRecords, 0, ASource.ChangedRecords.Count,
          [usDeleted]);
    dcmModified:
      if Assigned(ASource.FCloneSource) then
        CopyRecords(ASource.FCloneSource.ChangedRecords, 0,
          ASource.FCloneSource.ChangedRecords.Count, [usModified])
      else
        CopyRecords(ASource.ChangedRecords, 0, ASource.ChangedRecords.Count,
          [usModified]);
    dcmChanged:
      if Assigned(ASource.FCloneSource) then
        CopyRecords(ASource.FCloneSource.ChangedRecords, 0,
          ASource.FCloneSource.ChangedRecords.Count,
          [usInserted, usDeleted, usModified])
      else
        CopyRecords(ASource.ChangedRecords, 0, ASource.ChangedRecords.Count,
          [usInserted, usDeleted, usModified]);
    dcmSorted: // 以排序结果为依据复制数据
      CopyRecords(ASource.FSortedRecords, 0, ASource.FSortedRecords.Count,
        [usUnmodified, usInserted, usDeleted, usModified]);
    dcmFiltered:
      CopyRecords(ASource.FFilteredRecords, 0, ASource.FFilteredRecords.Count,
        [usUnmodified, usInserted, usDeleted, usModified]);
    dcmMetaOnly: // 不复制任何数据
      ;
  end;
  Open;
end;

constructor TQDataSet.Create(AOwner: TComponent);
begin
  inherited;
{$IFNDEF UNICODE}
  FreeObject(FieldDefs);
  PPointer(@FieldDefs)^ := TQFieldDefs.Create(Self);
{$ENDIF}
  FOriginRecords := TQRecords.Create(ditOrigin); // 每条记录在此记录一个
  FSortedRecords := TQRecords.Create(ditSorted); // 排序后的列表以此为基准遍历
  FChangedRecords := TQRecords.Create(ditChanged); // 修改过的记录
  FFilteredRecords := TQRecords.Create(ditFiltered);
  FActiveRecords := FOriginRecords;
  FClones := TQDataSetList.Create;
  FRecordNo := -1; // 当前记录索引
  FBatchMode := True;
  NestedDataSetClass := TQDataSet;
  // 子数据集对象类型，目前暂不实际支持子数据集
  FChecks := TQLocalChecks.Create(TQLocalCheck);
  FChecks.FDataSet := Self;
  FAnsiNulls := True;
  FActiveRecordset := -1;
  FMasterLink := TQMasterDataLink.Create(Self);
  FMasterLink.OnMasterChange := MasterChanged;
  FMasterLink.OnMasterDisable := MasterDisabled;
  FOpenBy := dsomByCreate;
end;

function TQDataSet.CreateBlobStream(Field: TField;
  Mode: TBlobStreamMode): TStream;
begin
  Result := TQBlobStream.Create(Field as TBlobField, Mode);
end;

procedure TQDataSet.CreateDataSet;
begin
  FProvider := nil;
  FConverter := nil;
  FOpenBy := dsomByCreate;
  Active := True;
end;

function TQDataSet.CreateFieldsByUser: Boolean;
begin
{$IF RTLVersion>=27}
  Result := (FieldOptions.AutoCreateMode <> acExclusive) or
    not(lcPersistent in Fields.LifeCycles);
{$ELSE}
  Result := DefaultFields;
{$IFEND}
end;

procedure TQDataSet.Cross(AColField, AKeyField, AValueField,
  AKeyName: QStringW);
var
  AFieldNames: TStringList;
  I, J, AKeyIdx, AColIdx, AValIdx: Integer;
  ASrc, ADest: TQRecord;
  ACopy: TQDataSet;
  ASorts: TQRecords;
  ACompare: TQValueCompare;
  procedure CheckField(var AIdx: Integer; const AName: QStringW);
  var
    ADef: TFieldDef;
  begin
    ADef := ACopy.FieldDefs.Find(AName);
    if ADef = nil then
      DatabaseError(Format(SFieldNotFound, [AName]), Self)
    else
      AIdx := ADef.FieldNo - 1;
  end;

  function DoSearch(var AIndex: Integer): Boolean;
  var
    L, H, I, C: Integer;
    V2: PQValue;
  begin
    Result := False;
    L := 0;
    H := ASorts.Count - 1;
    V2 := ASrc.Values[AKeyIdx].CurrentValue;
    if V2.IsNull then
    begin
      AIndex := 0;
      if (ASorts.Count > 0) and (ASorts[0].Values[0].OldValue.IsNull) then
        Result := True;
    end
    else
      while L <= H do
      begin
        I := (L + H) shr 1;
        if ASorts[I].Values[0].OldValue.IsNull then
          C := -1
        else
          C := ACompare(@ASorts[I].Values[0].OldValue, V2);
        if C < 0 then
          L := I + 1
        else
        begin
          H := I - 1;
          if C = 0 then
            Result := True;
        end;
      end;
    AIndex := L;
  end;

begin
  CheckActive;
  ApplyChanges; // 将所有的变更都应用
  Filtered := False;
  AFieldNames := TStringList.Create;
  ACopy := TQDataSet.Create(nil);
  ASorts := TQRecords.Create(ditSorted);
  try
    ACopy.CopyFrom(Self, dcmView, AKeyField + ',' + AColField + ',' +
      AValueField);
    ACopy.EnumValues(AColField, AFieldNames, #0, False);
    Close;
    FieldDefs.Clear;
    CheckField(AColIdx, AColField);
    CheckField(AKeyIdx, AKeyField);
    CheckField(AValIdx, AValueField);
    if Length(AKeyName) = 0 then
      AKeyName := AKeyField;
    FieldDefs.Add(AKeyName, ACopy.FieldDefs[AKeyIdx].DataType,
      ACopy.FieldDefs[AKeyIdx].Size);
    ACompare := (ACopy.FieldDefs[AKeyIdx] as TQFieldDef).FOnCompare;
    for I := 0 to AFieldNames.Count - 1 do
      FieldDefs.Add(AFieldNames[I], ACopy.FieldDefs[AValIdx].DataType,
        ACopy.FieldDefs[AValIdx].Size);
    // 复制字段值
    for I := 0 to ACopy.FOriginRecords.Count - 1 do
    begin
      ASrc := ACopy.FOriginRecords[I];
      if DoSearch(J) then
        ADest := ASorts[J]
      else
      begin
        ADest := AllocRecord;
        ADest.FOriginIndex := FOriginRecords.Add(ADest);
        ADest.Values[0].OldValue.Copy
          (ASrc.Values[AKeyIdx].CurrentValue^, False);
        ASorts.Insert(J, ADest);
      end;
      ADest.Values[FieldDefs.Find(ASrc.Values[AColIdx].CurrentValue^.AsString)
        .FieldNo - 1].OldValue.Copy(ASrc.Values[AValIdx].CurrentValue^, False);
    end;
  finally
    FreeObject(AFieldNames);
    FreeObject(ACopy);
    FreeObject(ASorts);
  end;
  FOpenBy := dsomByCreate;
  Open;
end;

procedure TQDataSet.DecodeFieldDefs(AFieldList: QStringW;
  var AFieldDefs: TQFieldDefArray);
var
  I: Integer;
  AFieldName: QStringW;
begin
  SetLength(AFieldDefs, FieldDefs.Count);
  I := 0;
  while Length(AFieldList) > 0 do
  begin
    AFieldName := DecodeTokenW(AFieldList, ListDelimiter, NullChar, True, True);
    AFieldDefs[I] := FieldDefs.Find(AFieldName) as TQFieldDef;
    if AFieldDefs[I] = nil then
      raise QException.CreateFmt(SFieldNotFound, [AFieldName]);
    Inc(I);
  end;
  SetLength(AFieldDefs, I);
end;

procedure TQDataSet.DefChanged(Sender: TObject);
var
  ARecNo: Integer;
begin
  inherited;
  if Active then
  begin
    FDefChanging := True;
    ARecNo := RecNo;
    try
      Close;
      Open;
      RecNo := ARecNo;
    finally
      FDefChanging := False;
    end;
  end;
end;

procedure TQDataSet.DeleteDataSet(AIndex: Integer);
var
  ATemp: TQDataSet;
  I, C: Integer;
begin
  C := Length(FRecordsets);
  if (AIndex >= 0) and (AIndex < C) then
  begin
    Dec(C, 2);
    ATemp := FRecordsets[AIndex];
    for I := AIndex to C do
      FRecordsets[I] := FRecordsets[I + 1];
    Inc(C);
    SetLength(FRecordsets, C);
    if FActiveRecordset = AIndex then
    begin
      FActiveRecordset := -1;
      if AIndex = C then
        Dec(AIndex);
      ActiveRecordset := AIndex;
    end;
    ATemp.Close;
    if ATemp.Owner = nil then
      TQProvider.ReleaseDataSet(ATemp)
    else
      FreeObject(ATemp);
  end;
end;

destructor TQDataSet.Destroy;
begin
  inherited;
  FreeObject(FSortedRecords);
  FreeObject(FChangedRecords);
  FreeObject(FFilteredRecords);
  FreeObject(FOriginRecords);
  FreeObject(FClones);
  FreeObject(FChecks);
  FreeObject(FMasterLink);
end;

procedure TQDataSet.Diff(ASource1, ASource2: TQDataSet; AFields: QStringW;
  AIncSource1, AIncSource2: Boolean);
var
  AHash1, AHash2: TQDiffCache;
  I: Integer;
  AList1, ATemp: PQHashList;
  R1, R2: TQRecord;
  AColVal: PQColumnValue;
  procedure CopyRecord(ASource: TQRecord; const AFields: TQFieldDefArray);
  var
    J: Integer;
  begin
    R2 := AllocRecord;
    R2.FStatus := ASource.Status;
    for J := 0 to FieldDefs.Count - 1 do
    begin
      AColVal := @ASource.Values[AFields[J].FieldNo - 1];
      if AColVal.Changed then
        R2.Values[J].NewValue.Copy(AColVal.NewValue, False);
      if R2.Status <> usInserted then
        R2.Values[J].OldValue.Copy(AColVal.OldValue, False);
      R2.Values[J].Changed := AColVal.Changed;
    end;
    if R2.Status <> usDeleted then
      R2.FOriginIndex := FOriginRecords.Add(R2);
    if R2.Status <> usUnmodified then
      R2.FChangedIndex := FChangedRecords.Add(R2);
  end;

  function DoCompareInHashTable(const V1: TBytes; AFirst: PQHashList;
    ATable: TQDiffCache): Boolean;
  var
    V2: TBytes;
  begin
    Result := False;
    while AFirst <> nil do
    begin
      FlatFieldValues(AFirst.Data, ATable.Fields, V2);
      if (Length(V1) = Length(V2)) and CompareMem(@V1[0], @V2[0], Length(V1))
      then
      begin
        Result := True;
        Exit;
      end;
      AFirst := ATable.HashTable.FindNext(AFirst);
    end;
  end;

  function FindInHash(AItem: PQHashList): Boolean;
  var
    V1: TBytes;
    AStep: Integer;
  begin
    Result := False;
    ATemp := AHash1.HashTable.FindFirst(AItem.Hash);
    if ATemp = AItem then
      ATemp := AHash1.HashTable.FindNext(ATemp);
    AStep := 0;
    if Assigned(ATemp) then
    begin
      AStep := 1;
      FlatFieldValues(AItem.Data, AHash1.Fields, V1);
      Result := DoCompareInHashTable(V1, ATemp, AHash1);
      if Result then
        Exit;
    end;
    ATemp := AHash2.HashTable.FindFirst(AItem.Hash);
    if ATemp = AItem then
      ATemp := AHash2.HashTable.FindNext(ATemp);
    if Assigned(ATemp) then
    begin
      if AStep = 0 then
        FlatFieldValues(AItem.Data, AHash1.Fields, V1);
      Result := DoCompareInHashTable(V1, ATemp, AHash2);
    end;
  end;

  procedure RemoveDuplicates(ACache: TQDiffCache);
  var
    I: Integer;
    V1, V2: TBytes;
  begin
    I := 0;
    while I < ACache.HashTable.BucketCount do
    begin
      AList1 := ACache.HashTable.Buckets[I];
      while AList1 <> nil do
      begin
        ATemp := ACache.HashTable.FindNext(AList1);
        if Assigned(ATemp) then
        begin
          FlatFieldValues(AList1.Data, ACache.Fields, V1);
          while ATemp <> nil do
          begin
            R1 := ATemp.Data;
            FlatFieldValues(R1, ACache.Fields, V2);
            if (Length(V1) = Length(V2)) and CompareMem(@V1[0], @V2[0],
              Length(V1)) then
            begin
              ATemp := ACache.HashTable.FindNext(ATemp);
              ACache.HashTable.Delete(R1, AList1.Hash);
            end;
          end;
        end;
        AList1 := AList1.Next;
      end;
      Inc(I);
    end;
  end;

begin
  PrepareDiffCheck(ASource1, ASource2, AFields, AHash1, AHash2);
  RemoveDuplicates(AHash1);
  RemoveDuplicates(AHash2);
  if AIncSource1 then
  begin
    for I := 0 to AHash1.HashTable.BucketCount - 1 do
    begin
      AList1 := AHash1.HashTable.Buckets[I];
      while Assigned(AList1) do
      begin
        if not FindInHash(AList1) then
          CopyRecord(AList1.Data, AHash1.Fields);
        AList1 := AList1.Next;
      end;
    end;
  end;
  if AIncSource2 then
  begin
    for I := 0 to AHash2.HashTable.BucketCount - 1 do
    begin
      AList1 := AHash2.HashTable.Buckets[I];
      while Assigned(AList1) do
      begin
        if not FindInHash(AList1) then
          CopyRecord(AList1.Data, AHash1.Fields);
        AList1 := AList1.Next;
      end;
    end;
  end;
  FOpenBy := dsomByCreate;
  FreeObject(AHash1.HashTable);
  FreeObject(AHash2.HashTable);
  Open;
end;

procedure TQDataSet.Distinct;
var
  AHash: TQHashTable;
  ARec: TQRecord;
  AFieldList: TQFieldDefArray;
  I: Integer;
  procedure HashRecords;
  var
    AValue: TQHashType;
  begin
    I := 0;
    SetLength(AFieldList, FieldDefs.Count);
    while I < FieldDefs.Count do
    begin
      AFieldList[I] := FieldDefs[I] as TQFieldDef;
      Inc(I);
    end;
    I := 0;
    while I < FOriginRecords.Count do
    begin
      ARec := FOriginRecords[I];
      AValue := HashOfRecord(ARec, AFieldList);
      AHash.Add(ARec, AValue);
      Inc(I);
    end;
  end;
  procedure DeleteMarkedDups(AList: TQRecords);
  begin
    I := 0;
    while I < AList.Count do
    begin
      if AList[I].FTag <> nil then
        AList.Delete(I)
      else
        Inc(I);
    end;
    AList.Clean;
  end;

  procedure DoDistinct;
  var
    V1, V2: TBytes;
    AHashList, ATemp: PQHashList;
    ADup: TQRecord;
  begin
    I := 0;
    while I < AHash.BucketCount do
    begin
      AHashList := AHash.Buckets[I];
      while AHashList <> nil do
      begin
        ARec := AHashList.Data;
        ATemp := AHash.FindNext(AHashList);
        if Assigned(ATemp) then
        begin
          FlatFieldValues(ARec, AFieldList, V1);
          while Assigned(ATemp) do
          begin
            ADup := ATemp.Data;
            FlatFieldValues(ADup, AFieldList, V2);
            if (Length(V1) = Length(V2)) and CompareMem(@V1[0], @V2[0],
              Length(V1)) then
            begin
              AHash.Delete(ADup, AHashList.Hash);
              if ADup.FOriginIndex < ARec.FOriginIndex then
              begin
                ARec.FTag := Pointer(-2);
                ARec := ADup;
              end
              else
                ADup.FTag := Pointer(-2);
            end;
            ATemp := AHash.FindNext(ATemp);
          end;
        end;
        AHashList := AHashList.Next;
      end;
      Inc(I);
    end;
    DeleteMarkedDups(FOriginRecords);
    DeleteMarkedDups(FChangedRecords);
    DeleteMarkedDups(FSortedRecords);
    DeleteMarkedDups(FFilteredRecords);
  end;

begin
  AHash := TQHashTable.Create(FOriginRecords.Count);
  try
    Unlink;
    HashRecords;
    DoDistinct;
  finally
    FreeObject(AHash);
    First;
  end;
end;

function TQDataSet.DoCustomSort(AExp: PQSortExp;
  ARec1, ARec2: TQRecord): Integer;
begin
  FOnCustomSort(Self, ARec1, ARec2, Result);
end;

procedure TQDataSet.DoDelete(ABuf: TQRecord);
var
  ALastStatus: TUpdateStatus;
begin
  CheckBrowseMode;
  UpdateCursorPos;
  ChangedRecords.Clean;
  FOriginRecords.Clean;
  FSortedRecords.Clean;
  FFilteredRecords.Clean;
  // 如果是非批量模式，则先提交变更
  if ABuf.FStatus <> usInserted then
  begin
    ALastStatus := ABuf.Status;
    ABuf.FStatus := usDeleted;
    ABuf.FChangedIndex := ChangedRecords.Add(ABuf);
    if Assigned(Provider) and (not BatchMode) then
    begin
      try
        InternalApplyChanges(Provider);
      except
        begin
          ABuf.FStatus := ALastStatus;
          ChangedRecords.Delete(ABuf.FChangedIndex);
          ABuf.FChangedIndex := -1;
          raise;
        end;
      end;
    end;
  end
  else
  begin
    if ABuf.ChangedIndex <> -1 then
    begin
      ChangedRecords.Delete(ABuf.ChangedIndex);
      // ChangedRecords.Dirty(ABuf.ChangedIndex);
    end;
  end;
  FOriginRecords.Delete(ABuf.OriginIndex);
  // FOriginRecords.Dirty(ABuf.OriginIndex);
  if Length(FSort) > 0 then
  begin
    FSortedRecords.Delete(ABuf.SortedIndex);
    // FSortedRecords.Dirty(ABuf.SortedIndex);
  end;
  if Filtered then
  begin
    FFilteredRecords.Delete(ABuf.FFilteredIndex);
    // FFilteredRecords.Dirty(ABuf.FFilteredIndex);
  end;
end;

procedure TQDataSet.DoDupCount(AHashs: TQHashTable; AHash: PQRecordHash;
  AParam: Pointer);
begin
  Inc(PCardinal(AParam)^);
end;

procedure TQDataSet.DoSort(AFireNotify: Boolean);
var
  I: Integer;
  AList: TQRecords;
  ALast: TQRecord;
begin
  if not FIsOpening then
  begin
    ALast := ActiveRecordBuffer;
    if Assigned(ALast.Bookmark) then
      ALast := ALast.Bookmark;
  end
  else
    ALast := nil;
  FetchAllRecords;
  if Filtered then
    AList := FFilteredRecords
  else
    AList := FOriginRecords;
  FSortedRecords.Assign(AList);
  // 暂时先直接单线程直接排序，将来再处理多线程排序
  if Assigned(FOnCustomSort) then
    QuickSort(FSortedRecords, FSortExp, 0, FSortedRecords.Count - 1,
      DoCustomSort)
  else
    QuickSort(FSortedRecords, FSortExp, 0, FSortedRecords.Count - 1,
      SortCompare);
  // OutputDebugString(PAnsiChar(Format('Sort Used:%dms',[GetTickCount-T])));
  for I := 0 to FSortedRecords.Count - 1 do
    TQRecord(FSortedRecords[I]).FSortedIndex := I;
  FActiveRecords := FSortedRecords;
  if AFireNotify and Assigned(ALast) then
  begin
    ClearBuffers;
    InternalSetToRecord(ALast);
    Resync([]);
  end;
end;

procedure TQDataSet.DoThreadFilterJob(ALoopMgr: TQForJobs; AJob: PQJob;
  AIndex: NativeInt);
var
  Accept: Boolean;
  ARec: TQRecord;
begin
  ARec := FOriginRecords[AIndex];
  FilterRecord(ARec, Accept, FFilterExp);
  if Accept then
    ARec.FFilteredIndex := -2
  else
    ARec.FFilteredIndex := -1;
end;

procedure TQDataSet.Empty;
begin
  if Assigned(FCloneSource) then
    FCloneSource := nil;
  if (FHandle <> 0) and Assigned(FProvider) then
    FProvider.CloseHandle(FHandle);
  FHandle := 0;
  FOriginRecords.Clear;
  FSortedRecords.Clear;
  FFilteredRecords.Clear;
  FChangedRecords.Clear;
  ClearBuffers;
  CursorPosChanged;
  FRecordNo := -1;
  Resync([]);
end;

function DoEnumValuesCompare(List: TStringList;
  Index1, Index2: Integer): Integer;
begin
  Result := IntPtr(List.Objects[Index1]) - IntPtr(List.Objects[Index2]);
end;

function TQDataSet.EnumValues(const AFields: QStringW; AList: TStrings;
  AValueDelimiter: Char; AIgnoreNull: Boolean): Integer;
var
  I, K: Integer;
  ADef: TFieldDef;
  ATemp: TStringList;
  ARec: TQRecord;
  AFieldList: array of Integer;
  S: String;
  p: PQCharW;
const
  ListValueDelimiter: PQCharW = ',;';
  function EncodeValues: Boolean;
  begin
    K := 0;
    Result := False;
    SetLength(S, 0);
    while K < Length(AFieldList) do
    begin
      if AIgnoreNull and ARec.Values[AFieldList[K]].CurrentValue.IsNull then
        Continue
      else
      begin
        Result := True;
        if (Length(S) > 0) and (AValueDelimiter <> #0) then
          S := S + AValueDelimiter + ARec.Values[AFieldList[K]]
            .CurrentValue^.AsString
        else
          S := S + ARec.Values[AFieldList[K]].CurrentValue^.AsString;
      end;
      Inc(K);
    end;
  end;

begin
  SetLength(AFieldList, FieldDefs.Count);
  p := PQCharW(AFields);
  I := 0;
  while p^ > #0 do
  begin
    S := DecodeTokenW(p, ListValueDelimiter, QCharW(#0), True);
    ADef := FieldDefs.Find(S);
    if ADef = nil then
      DatabaseError(Format(SFieldNotFound, [S]), Self);
    AFieldList[I] := ADef.FieldNo - 1;
    Inc(I);
  end;
  SetLength(AFieldList, I);
  I := 0;
  AList.BeginUpdate;
  ATemp := TStringList.Create;
  try
    ATemp.Sorted := True;
    ATemp.Duplicates := dupIgnore;
    while I < FActiveRecords.Count do
    begin
      ARec := FActiveRecords[I];
      if EncodeValues then
        ATemp.AddObject(S, TObject(I));
      Inc(I);
    end;
    // 将值按原始顺序拷贝回AList
    ATemp.CustomSort(DoEnumValuesCompare);
    I := 0;
    while I < ATemp.Count do
    begin
      AList.Add(ATemp[I]);
      Inc(I);
    end;
  finally
    FreeObject(ATemp);
    AList.EndUpdate;
  end;
  Result := AList.Count;
end;

function TQDataSet.Exists(const AFilterExp: QStringW;
  AFilterOptions: TFilterOptions): Boolean;
var
  AExp: TQFilterExp;
  I: Integer;
begin
  Result := False;
  AExp := TQFilterExp.Create(Self);
  try
    AExp.Parse(AFilterExp, foCaseInsensitive in AFilterOptions, False);
    for I := 0 to FOriginRecords.Count - 1 do
    begin
      if AExp.Accept(FOriginRecords[I], AFilterOptions) then
      begin
        Result := True;
        Break;
      end;
    end;
  finally
    FreeObject(AExp);
  end;
end;

function TQDataSet.ForEach(AProc: TQRecordEnumProc; AParam: Pointer): Integer;
begin
  Result := 0;
  if Assigned(AProc) then
  begin
    while Result < FActiveRecords.Count do
    begin
      AProc(Self, Result, FActiveRecords[Result], AParam);
      Inc(Result);
    end;
  end;
end;

procedure TQDataSet.FetchAllRecords;
var
  I: Integer;
begin
  if Assigned(FProvider) and (FHandle <> 0) then
  begin
    if FLoadedRecordCount <> FProviderRecordCount then
    begin
      for I := FLoadedRecordCount to FOriginRecords.Count - 1 do
        FetchProviderRecord(FOriginRecords[I]);
    end;
  end;
end;

procedure TQDataSet.FetchProviderRecord(ARec: TQRecord);
begin

end;

procedure TQDataSet.FilterRecord(ARec: TQRecord; var Accept: Boolean;
  AParser: TQFilterExp);
begin
  Accept := True;
  ARec := RealRecord(ARec);
  if Assigned(OnFilterRecord) then
  begin
    if State in [dsEdit, dsInsert] then
      OnFilterRecord(Self, Accept)
    else
    begin
      // 移动到指定的记录上
      RecNo := ARec.FOriginIndex + 1;
      Assert(RecNo = ARec.FOriginIndex + 1);
      OnFilterRecord(Self, Accept);
    end;
  end
  else if Assigned(FFilterExp) then
    Accept := FFilterExp.Accept(ARec, FilterOptions);
end;

procedure TQDataSet.FilterRecords(AParseNeeded, AFireNotify: Boolean);
// 判断是否需要多线程过滤，手动过滤最多1000条记录，然后估计总体时间
var
  AFilterSource: TQRecords;
  procedure FilterInMainThread(AStart, ACount: Integer);
  var
    ARec: TQRecord;
    Accept: Boolean;
  begin
    while ACount > 0 do
    begin
      ARec := AFilterSource[AStart];
      FilterRecord(ARec, Accept, FFilterExp);
      if Accept then
        ARec.FFilteredIndex := FFilteredRecords.Add(ARec);
      Inc(AStart);
      Dec(ACount);
    end;
  end;
  function MultiThreadNeeded(var AMaxTest: Integer): Boolean;
  var
    T: Int64;
  begin
    if Assigned(OnFilterRecord) then
    begin
      Result := False;
      FilterInMainThread(0, AFilterSource.Count);
      AMaxTest := AFilterSource.Count;
    end
    else
    begin
      Result := AFilterSource.Count > 5000;
      if not Result then
      begin
        AMaxTest := AFilterSource.Count;
        if AMaxTest > 1000 then
          AMaxTest := 1000;
        T := GetTimeStamp;
        FilterInMainThread(0, AMaxTest);
        T := GetTimeStamp - T;
        if T > 0 then
        begin
          // 估算剩余记录计算约需要的时间
          if ((AFilterSource.Count - AMaxTest) * T div 1000) > 500 then
            // >50ms，就启用多线程过滤
            Result := True;
        end;
      end
      else
        AMaxTest := 0;
    end;
  end;

  procedure DoFilterRecords;
  var
    I, C: Integer;
    ARec: TQRecord;
    ATempState: TDataSetState;
  begin
    if Length(Sort) > 0 then
      AFilterSource := FSortedRecords
    else
      AFilterSource := FOriginRecords;
    ATempState := SetTempState(dsFilter);
    try
      ActiveRecordsChanged;
      if Assigned(OnFilterRecord) then
        First;
      if not Assigned(FFilterExp) then
      begin
        FFilterExp := TQFilterExp.Create(Self);
        FFilterExp.Parse(Filter, foCaseInsensitive in FilterOptions, False);
      end
      else if AParseNeeded then
        FFilterExp.Parse(Filter, foCaseInsensitive in FilterOptions, False);
      if MultiThreadNeeded(C) then
      begin
        Workers.&For(C, AFilterSource.Count - 1, DoThreadFilterJob, False, nil);
        for I := C to AFilterSource.Count - 1 do
        begin
          ARec := AFilterSource[I];
          if ARec.FFilteredIndex = -2 then
            ARec.FFilteredIndex := FFilteredRecords.Add(ARec);
        end;
      end;
      if AFilterSource = FSortedRecords then
        FSortedRecords.Assign(FFilteredRecords);
    finally
      RestoreState(ATempState);
    end;
  end;

begin
  FFilteredRecords.Clear;
  if Filtered then
    DoFilterRecords
  else if Length(FSort) > 0 then
    DoSort(False);
  ActiveRecordsChanged;
  if AFireNotify then
    First;
end;

function TQDataSet.FindRecord(Restart, GoForward: Boolean): Boolean;
var
  AIndex, ARecNo: Integer;
begin
  CheckBrowseMode;
  if (Length(Filter) > 0) then
  begin
    if not Assigned(FFilterExp) then
      FFilterExp := TQFilterExp.Create(Self);
    if (FFilterExp.Count = 0) then
      FFilterExp.Parse(Filter, False, False);
  end;
  if Restart then
  begin
    if GoForward then
      AIndex := -1
    else
      AIndex := RecordCount;
  end
  else
    AIndex := RecNo - 1;
  Result := False;
  if RecordCount > 0 then
  begin
    ARecNo := RecNo;
    DisableControls;
    try
      if GoForward then
      begin
        repeat
          Inc(AIndex);
          if (AIndex < RecordCount) and
            FFilterExp.Accept(FActiveRecords[AIndex], FilterOptions) then
          begin
            Result := True;
            RecNo := AIndex + 1;
            Break;
          end;
        until AIndex >= RecordCount;
      end
      else
      begin
        while AIndex > 0 do
        begin
          Dec(AIndex);
          if FFilterExp.Accept(FActiveRecords[AIndex], FilterOptions) then
          begin
            Result := True;
            RecNo := AIndex + 1;
            Break;
          end;
        end;
      end;
    finally
      if not Result then
        RecNo := ARecNo;
      EnableControls;
    end;
  end;
end;

procedure TQDataSet.FlatFieldValues(ARec: TQRecord;
  const AFields: TQFieldDefArray; var ABytes: TBytes);
var
  I, ASize: Integer;
  ADef: TQFieldDef;
  procedure WriteValue(AValue: PQValue);
  var
    J: Integer;
  begin
    case AValue.ValueType of
      vdtNull:
        ;
      vdtBoolean:
        begin
          ABytes[ASize] := Byte(AValue.Value.AsBoolean);
          Inc(ASize);
        end;
      vdtInteger:
        begin
          PInteger(@ABytes[ASize])^ := AValue.Value.AsInteger;
          Inc(ASize, SizeOf(Integer));
        end;
      vdtFloat, vdtInt64, vdtCurrency, vdtDateTime, vdtInterval: // 8B
        begin
          PInt64(@ABytes[ASize])^ := AValue.Value.AsInt64;
          Inc(ASize, SizeOf(Int64));
        end;
      vdtBcd:
        begin
          PBcd(@ABytes[ASize])^ := AValue.Value.AsBcd^;
          Inc(ASize, SizeOf(TBcd));
        end;
      vdtGuid:
        begin
          PGuid(@ABytes[ASize])^ := AValue.Value.AsGuid^;
          Inc(ASize, SizeOf(TGuid));
        end;
      vdtString:
        begin
          Move(PQCharW(AValue.Value.AsString^)^, ABytes[ASize],
            Length(AValue.Value.AsString^) shl 1);
          Inc(ASize, Length(AValue.Value.AsString^) shl 1);
        end;
      vdtStream:
        begin
          Move(TMemoryStream(AValue.Value.AsStream).Memory^, ABytes[ASize],
            TMemoryStream(AValue.Value.AsStream).Size);
          Inc(ASize, TMemoryStream(AValue.Value.AsStream).Size);
        end;
      vdtArray:
        begin
          for J := 0 to AValue.Value.Size - 1 do
            WriteValue(AValue.Items[J]);
        end;
    end;
  end;

begin
  ASize := 0;
  ARec := RealRecord(ARec);
  for I := 0 to High(AFields) do
  begin
    ADef := AFields[I];
    if Assigned(ADef) then
      Inc(ASize, ARec.Values[ADef.FieldNo - 1].CurrentValue.Size);
  end;
  SetLength(ABytes, ASize);
  ASize := 0;
  for I := 0 to High(AFields) do
  begin
    ADef := AFields[I];
    if Assigned(ADef) then
      WriteValue(ARec.Values[ADef.FieldNo - 1].CurrentValue);
  end;
end;
{$IFDEF UNICODE}

function TQDataSet.ForEach(AProc: TQRecordEnumProcA): Integer;
begin
  Result := 0;
  if Assigned(AProc) then
  begin
    while Result < FActiveRecords.Count do
    begin
      AProc(Self, Result, FActiveRecords[Result]);
      Inc(Result);
    end;
  end;
end;
{$ENDIF}
{$IFDEF NEXTGEN}

procedure TQDataSet.FreeRecBuf(var Buffer: TRecBuf);
begin
  inherited;

end;
{$ENDIF}

procedure TQDataSet.FreeRecord(ARec: TQRecord);
begin
  TQRecord(ARec.FBookmark) := nil;
  ARec.Release;
end;
{$IFNDEF UNICODE}

procedure TQDataSet.FreeRecordBuffer(var Buffer: PChar);
begin
  FreeRecord(TQRecord(Buffer));
  Buffer := nil;
end;
{$ENDIF}
{$IFNDEF NEXTGEN}
{$IF RTLVersion>19}

procedure TQDataSet.FreeRecordBuffer(var Buffer: TRecordBuffer);
begin
  FreeRecord(TQRecord(Buffer));
  Buffer := nil;
end;
{$IFEND}
{$ENDIF}

function TQDataSet.GetAggregateValue(Field: TField): Variant;
var
  AggField: TAggregateField;
  AField, Action: QStringW;
const
  RightBracket: PWideChar = ')';
begin
  AggField := Field as TAggregateField;
  AField := AggField.Expression;
  Action := UpperCase(DecodeTokenW(AField, RightBracket, NullChar, True, True));
  AField := DecodeTokenW(AField, RightBracket, NullChar, True, True);
  if Action = 'SUM' then
    Result := Sum(AField)
  else if Action = 'AVG' then
    Result := Avg(AField)
  else if Action = 'MAX' then
    Result := Max(AField)
  else if Action = 'MIN' then
    Result := Min(AField)
  else if Action = 'COUNT' then
  begin
    if AField <> '*' then
      Result := DistinctCount(AField)
    else
      Result := FActiveRecords.Count;
  end
  else
    VarClear(Result);
end;

function TQDataSet.GetBlobFieldData(FieldNo: Integer;
  var Buffer: TBlobByteData): Integer;
var
  AValue: PQValue;
  ARec: TQRecord;
begin
  Result := 0;
  if FieldNo > 0 then
  begin
    ARec := ActiveRecordBuffer;
    Dec(FieldNo);
    if ARec.Values[FieldNo].Changed then
      AValue := @ARec.Values[FieldNo].NewValue
    else
      AValue := @ARec.Values[FieldNo].OldValue;
    if AValue.IsNull then
      SetLength(Buffer, 0)
    else
    begin
      Result := AValue.AsStream.Size;
      SetLength(Buffer, Result);
      Move(AValue.AsStream.Memory^, Buffer[0], Result);
    end;
  end;
end;

function TQDataSet.GetBookmark: TBookmark;
begin
{$IFDEF UNICODE}
  SetLength(Result, BookmarkSize);
  GetBookmarkData(TRecordBuffer(ActiveBuffer), @Result[0]);
{$ELSE}
  GetMem(Result, BookmarkSize);
  GetBookmarkData(PChar(ActiveBuffer), Result);
{$ENDIF}
end;

{$IFNDEF NEXTGEN}
{$IFNDEF UNICODE}

procedure TQDataSet.GetBookmarkData(Buffer: PChar; Data: Pointer);
begin
  PPointer(Data)^ := TQRecord(Buffer).Bookmark;
end;

function TQDataSet.GetBookmarkFlag(Buffer: PChar): TBookmarkFlag;
begin
  if Assigned(TQRecord(Buffer).Bookmark) then
    Result := TQRecord(TQRecord(Buffer).Bookmark).BookmarkFlag
  else
    Result := TQRecord(Buffer).BookmarkFlag;
end;
{$ENDIF}
{$IF RTLVersion>19}

procedure TQDataSet.GetBookmarkData(Buffer: TRecordBuffer; Data: Pointer);
var
  pBookmark: PPointer;
begin
  pBookmark := PPointer(Data);
  pBookmark^ := TQRecord(Buffer).Bookmark;
  Inc(pBookmark);
  pBookmark^ := Self;
end;

procedure TQDataSet.GetBookmarkData(Buffer: TRecordBuffer; Data: TBookmark);
begin
  // >=XE3 TBookmark=TArray<Byte> <XE3 TBookmark=TBytes
  SetLength(Data, BookmarkSize);
  GetBookmarkData(Buffer, PByte(@Data[0]));
end;

function TQDataSet.GetBookmarkFlag(Buffer: TRecordBuffer): TBookmarkFlag;
begin
  if Assigned(TQRecord(Buffer).Bookmark) then
    Result := TQRecord(TQRecord(Buffer).Bookmark).BookmarkFlag
  else
    Result := TQRecord(Buffer).BookmarkFlag;
end;
{$IFEND}
{$ENDIF}
{$IF RTLVersion>24}

procedure TQDataSet.GetBookmarkData(Buffer: TRecBuf; Data: TBookmark);
begin
  SetLength(Data, BookmarkSize);
  GetBookmarkData(TRecordBuffer(Buffer), @Data[0]);
end;

function TQDataSet.GetBookmarkFlag(Buffer: TRecBuf): TBookmarkFlag;
begin
  if Assigned(TQRecord(Buffer).Bookmark) then
    Result := TQRecord(TQRecord(Buffer).Bookmark).BookmarkFlag
  else
    Result := TQRecord(Buffer).BookmarkFlag;
end;
{$IFEND}

function TQDataSet.GetChangedRecords: TQRecords;
begin
  if Assigned(FCloneSource) then
    Result := FCloneSource.FChangedRecords
  else
    Result := FChangedRecords;
end;
{$IF RTLVersion>24}

function TQDataSet.GetFieldData(Field: TField;
  var Buffer: TValueBuffer): Boolean;
begin
  Result := GetFieldData(Field, @Buffer[0]);
end;
{$IFEND}

function TQDataSet.GetFieldClass(FieldType: TFieldType): TFieldClass;
begin
  if FieldType = ftOraInterval then
    Result := TQIntervalField
  else if FieldType = ftBlob then
    Result := TQBlobField
  else
    Result := inherited GetFieldClass(FieldType);
end;

function TQDataSet.GetFieldData(Field: TField; Buffer: Pointer): Boolean;
var
  ABuf: TQRecord;
begin
  ABuf := ActiveRecordBuffer;
  if (State = dsInsert) and (ABuf.Bookmark = FEditingRow) then
    ABuf := FEditingRow
  else if (State <> dsEdit) or (ABuf.Bookmark <> FEditingRow) then
  begin
    if Assigned(ABuf.Bookmark) then
      ABuf := ABuf.Bookmark;
  end;
  Result := InternalGetFieldData(ABuf, Field, Buffer, False);
end;
{$IFDEF UNICODE}

function TQDataSet.GetFieldDefsClass: TFieldDefsClass;
begin
  Result := TQFieldDefs;
end;
{$ENDIF}

procedure TQDataSet.GetFieldValue(ARecord: PQRecord; AField: TField;
  var AValue: TQValue);
var
  ASource: PQValue;
begin
  if ARecord.Values[AField.FieldNo].Changed then
    ASource := @ARecord.Values[AField.FieldNo].NewValue
  else
    ASource := @ARecord.Values[AField.FieldNo].OldValue;
  AValue.Copy(ASource^, False);
end;

function TQDataSet.GetIteratorType: TQRecordIteratorLevel;
begin
  Result := rilRandom; // 数据集支持随机迭代器
end;

function TQDataSet.GetMasterSource: TDataSource;
begin
  Result := FMasterLink.DataSource;
end;

function TQDataSet.GetPageCount: Integer;
var
  ACount: Integer;
begin
  if PageSize > 0 then
  begin
    if Filtered then
      ACount := FFilteredRecords.Count
    else
      ACount := FOriginRecords.Count;
    if (ACount mod PageSize) <> 0 then
      Result := (ACount div PageSize) + 1
    else
      Result := ACount div PageSize;
  end
  else
    Result := -1;
end;
{$IFNDEF NEXTGEN}
{$IF RTLVersion>19}

function TQDataSet.GetRecord(Buffer: TRecordBuffer; GetMode: TGetMode;
  DoCheck: Boolean): TGetResult;
begin
  Result := GetRecord(TQRecord(Buffer), GetMode, DoCheck);
end;
{$IFEND}
{$ENDIF}
{$IF RTLVersion>24}

function TQDataSet.GetRecord(Buffer: TRecBuf; GetMode: TGetMode;
  DoCheck: Boolean): TGetResult;
begin
  Result := GetRecord(TQRecord(Buffer), GetMode, DoCheck);
end;
{$IFEND}

function TQDataSet.GetRecNo: Integer;
var
  ABuf: TQRecord;
begin
  if State = dsInsert then
  begin
    if ActiveRecordBuffer.BookmarkFlag = bfEof then
      Result := RecordCount
    else
      Result := FEditingRow.FOriginIndex + 1;
  end
  else if Active then
  begin
    FActiveRecords.Clean;
    ABuf := ActiveRecordBuffer;
    if Assigned(ABuf.Bookmark) then
      ABuf := ABuf.Bookmark;
    if FActiveRecords = FOriginRecords then // 未排序和过滤
      Result := ABuf.FOriginIndex + 1
    else if FActiveRecords = FSortedRecords then // 已排序
      Result := ABuf.FSortedIndex + 1
    else // 已过滤
      Result := ABuf.FFilteredIndex + 1;
  end
  else
    Result := -1;
end;

function TQDataSet.GetRecord(Buffer: TQRecord; GetMode: TGetMode;
  DoCheck: Boolean): TGetResult;
var
  AOrigin: TQRecord;
  // ARecNo: Integer;
  function ModeName: String;
  begin
    case GetMode of
      gmCurrent:
        Result := 'gmCurrent';
      gmNext:
        Result := 'gmNext';
      gmPrior:
        Result := 'gmPrior';
    end;
  end;
  function ResultName(AResult: TGetResult): String;
  begin
    case AResult of
      grOK:
        Result := 'grOK';
      grBOF:
        Result := 'grBOF';
      grEOF:
        Result := 'grEOF';
      grError:
        Result := 'grError';
    end;
  end;

begin
  // AMsg := IntToHex(IntPtr(Self), SizeOf(Pointer) shl 1) + '.GetRecord.' + ModeName
  // + '(FRecordNo=' + IntToStr(FRecordNo) + ',RecNo=' + IntToStr(RecNo) +
  // ',ActiveRecord=' + IntToStr(ActiveRecord) + ')=';
  Result := grError;
  case GetMode of
    gmCurrent:
      begin
        if FRecordNo = -1 then
          Result := grBOF
        else if FRecordNo = RecordCount then
          Result := grEOF
        else if (FRecordNo >= 0) and (FRecordNo < RecordCount) then
          Result := grOK
        else
          Result := grError;
      end;
    gmNext:
      begin
        Inc(FRecordNo);

        if FRecordNo >= RecordCount then
        begin
          Result := grEOF;
          if CurrentRecord = 0 then
            Dec(FRecordNo);
        end
        else
          Result := grOK;
      end;
    gmPrior:
      begin
        Dec(FRecordNo);
        if FRecordNo < 0 then
        begin
          Result := grBOF;
          if CurrentRecord < 0 then
            Inc(FRecordNo);
        end
        else if FRecordNo < RecordCount then
        begin
          Result := grOK
        end
        else
          Result := grError;
      end;
  end;
  // AMsg := AMsg + ResultName(Result) + '(FRecordNo=' + IntToStr(FRecordNo) + ')';
  // PostLog(llDebug, AMsg);
  case Result of
    grOK:
      begin
        AOrigin := BufferOfRecNo(FRecordNo);
        // Assert(AOrigin.Bookmark = nil);
        TQRecord(Buffer.FBookmark) := AOrigin; //
        Buffer.FBookmarkFlag := bfCurrent;
        if AOrigin.OriginIndex >= FLoadedRecordCount then
        begin
          if Assigned(FProvider) and (FHandle <> 0) then
            FetchProviderRecord(Buffer);
        end;
      end;
    grError:
      if DoCheck then
        DatabaseError(SNoRecord);
  end;
end;
{$IFNDEF UNICODE}

function TQDataSet.GetRecord(Buffer: PChar; GetMode: TGetMode; DoCheck: Boolean)
  : TGetResult;
begin
  Result := GetRecord(TQRecord(Buffer), GetMode, DoCheck);
end;
{$ENDIF}

function TQDataSet.GetRecordCount: Integer;
begin
  Result := FActiveRecords.Count;
  if PageSize > 0 then
  begin
    Result := Result - PageSize * PageIndex;
    if Result > 0 then
    begin
      if Result > PageSize then
        Result := PageSize
    end
    else
      Result := 0;
  end;
end;

function TQDataSet.GetRecords(AIndex: Integer): TQRecord;
begin
  Result := RealRecord(FActiveRecords[AIndex]);
end;

function TQDataSet.GetRecordsetCount: Integer;
begin
  Result := Length(FRecordsets);
end;

function TQDataSet.GetRecordsets(AIndex: Integer): TQDataSet;
begin
  Result := FRecordsets[AIndex];
end;

function TQDataSet.GetRecordSize: Word;
begin
  Result := SizeOf(TQRecord);
end;

procedure TQDataSet.GroupBy(ADataSet: TQDataSet;
  AFields, AFilter, AOrderBy: QStringW);
var
  ATemp: TQDataSet;
  ASourceFields, AHashFields: TQFieldDefArray;
  ACalcFields: Integer;
  ASortFields: QStringW;
  A2Pass: Boolean;
  procedure CreateFieldDefs;
  var
    AFieldName, ANewName, AFuncName, S: QStringW;
    AField, ADef: TQFieldDef;
    I, AHashFieldCount: Integer;
    p: PQCharW;
  const
    LeftBracket: PWideChar = '(';
    RightBracket: PWideChar = ')';
    SpaceChars: PWideChar = ' '#9#10#13;
  begin
    SetLength(ASourceFields, FieldDefs.Count);
    SetLength(AHashFields, FieldDefs.Count);
    I := 0;
    AHashFieldCount := 0;
    ASortFields := '';
    ACalcFields := 0;
    A2Pass := False;
    ADataSet.FieldDefs.BeginUpdate;
    try
      ADataSet.FieldDefs.Clear;
      p := PQCharW(AFields);
      while p^ <> #0 do
      begin
        ANewName := DecodeTokenW(p, ListDelimiter, NullChar, True, True);
        if ANewName = '*' then
          raise QException.CreateFmt(SFieldNotFound, [AFieldName]);
        if ContainsCharW(ANewName, '(') then // 是一个函数？
        begin
          AFuncName := UpperCase(DecodeTokenW(ANewName, LeftBracket, NullChar,
            True, True));
          AFieldName := DecodeTokenW(ANewName, RightBracket, NullChar,
            True, True);
          Inc(ACalcFields);
          if AFieldName = '*' then
          begin
            if AFuncName <> 'COUNT' then
              raise QException.CreateFmt(SFieldNotFound, [AFieldName]);
          end;
        end
        else
        begin
          AFieldName := DecodeTokenW(ANewName, SpaceChars, NullChar,
            True, True);
          ASortFields := ASortFields + AFieldName + ',';
          AHashFields[AHashFieldCount] := FieldDefs.Find(AFieldName)
            as TQFieldDef;
          Inc(AHashFieldCount);
        end;
        if Length(ANewName) > 0 then
        begin
          S := DecodeTokenW(ANewName, SpaceChars, NullChar, True, True);
          if Length(ANewName) = 0 then
            ANewName := S;
        end
        else
        begin
          if Length(AFuncName) > 0 then
          begin
            if AFieldName <> '*' then
              ANewName := UpperFirstW(AFuncName) + '_' + AFieldName
            else
              ANewName := UpperFirstW(AFuncName);
          end
          else
            ANewName := AFieldName;
        end;

        ADef := ADataSet.FieldDefs.AddFieldDef as TQFieldDef;
        if AFieldName <> '*' then
        begin
          AField := FieldDefs.Find(AFieldName) as TQFieldDef;
          if AField = nil then
            raise QException.CreateFmt(SFieldNotFound, [AFieldName]);
          ADef.Assign(AField);
          if Length(AFuncName) <> 0 then
          begin
            ADef.InternalCalcField := True;
            ADef.BaseName := AFuncName;
            ADef.Name := ANewName;
          end
          else
            ADef.InternalCalcField := False;
        end
        else
        begin
          ADef.Name := ANewName;
          ADef.BaseName := '*';
          ADef.DBType := SQL_DWORD;
          ADef.InternalCalcField := True;
          AField := nil;
        end;
        ASourceFields[I] := AField;
        Inc(I);
        if ADef.BaseName = 'AVG' then
          A2Pass := True;
      end;
      SetLength(ASourceFields, I);
      if Length(ASortFields) > 0 then
        SetLength(ASortFields, Length(ASortFields) - 1);
      SetLength(AHashFields, AHashFieldCount);
    finally
      ADataSet.FieldDefs.EndUpdate;
    end;
  end;
  procedure Pass2(ADest: TQRecord; ACount: Integer);
  var
    J: Integer;
    ADef: TQFieldDef;
    ADVal: PQValue;
  begin
    if ACount > 0 then
    begin
      for J := 0 to ADataSet.FieldDefs.Count - 1 do
      begin
        ADef := ADataSet.FieldDefs[J] as TQFieldDef;
        if ADef.InternalCalcField and (ADef.BaseName = 'AVG') then
        begin
          ADVal := @ADest.Values[J].OldValue;
          case ADVal.ValueType of
            vdtSingle:
              ADVal.AsSingle := ADVal.AsSingle / ACount;
            vdtFloat:
              ADVal.AsFloat := ADVal.AsFloat / ACount;
            vdtInteger:
              ADVal.AsInteger := ADVal.AsInteger div ACount;
            vdtInt64:
              ADVal.AsInt64 := ADVal.AsInt64 div ACount;
            vdtCurrency:
              ADVal.AsCurrency := ADVal.AsCurrency / ACount;
            vdtBcd:
              BcdDivide(ADVal.AsBcd, IntegerToBcd(ACount), ADVal.Value.AsBcd^);
          end;
        end;
      end;
    end;
  end;
  procedure CopyRecords;
  var
    ASource, ADest: TQRecord;
    I, J, K: Integer;
    ADef: TQFieldDef;
    ASVal, ADVal: PQValue;
    AChanged: Boolean;
    ASourceHash, ARecHash: TQRecordHash;
  begin
    K := 0;
    I := 0;
    ADest := nil;
    while I < ATemp.FActiveRecords.Count do
    begin
      ASource := RealRecord(ATemp.FActiveRecords[I]);
      HashOfRecord(ASource, AHashFields, ARecHash);
      if I = 0 then
        AChanged := True
      else
      begin
        AChanged := ARecHash.HashCode <> ASourceHash.HashCode;
        if not AChanged then // 相同？
        begin
          // 先比较下内容长度
          AChanged := Length(ASourceHash.FlatValues) <>
            Length(ARecHash.FlatValues);
          if (not AChanged) and (Length(ASourceHash.FlatValues) > 0) then
          begin
            // 再比较下实际的内容
            AChanged := not CompareMem(@ASourceHash.FlatValues[0],
              @ARecHash.FlatValues[0], Length(ASourceHash.FlatValues));
          end
        end;
      end;
      if AChanged then
      begin
        if A2Pass and (I - K > 0) then
          Pass2(ADest, I - K);
        K := I;
        ASourceHash := ARecHash;
        ADest := ADataSet.AllocRecord;
        ADest.FOriginIndex := ADataSet.FOriginRecords.Add(ADest);
      end;
      for J := 0 to ADataSet.FieldDefs.Count - 1 do
      begin
        ADef := ADataSet.FieldDefs[J] as TQFieldDef;
        if Assigned(ASourceFields[J]) then
          ASVal := ASource.Values[ASourceFields[J].FieldNo - 1].CurrentValue
        else
          ASVal := nil;
        if ADef.InternalCalcField then
        begin
          ADVal := @ADest.Values[J].OldValue;
          if K <> I then
          begin
            if ADef.BaseName = 'MAX' then
            begin
              if ADef.ValueComparor(ADVal, ASVal) < 0 then // 新值>旧值
                ADVal.Copy(ASVal^, False);
            end
            else if ADef.BaseName = 'MIN' then
            begin
              if ADef.ValueComparor(ADVal, ASVal) > 0 then
                ADVal.Copy(ASVal^, False);
            end
            else if ADef.BaseName = '*' then
            begin
              ADVal.AsInteger := ADVal.AsInteger + 1;
            end
            else if (ADef.BaseName = 'SUM') or (ADef.BaseName = 'AVG') then
            begin
              case ADVal.ValueType of
                vdtSingle:
                  ADVal.AsSingle := ADVal.AsSingle + ASVal.AsSingle;
                vdtFloat:
                  ADVal.AsFloat := ADVal.AsFloat + ASVal.AsFloat;
                vdtInteger:
                  ADVal.AsInteger := ADVal.AsInteger + ASVal.AsInteger;
                vdtInt64:
                  ADVal.AsInt64 := ADVal.AsInt64 + ASVal.AsInt64;
                vdtCurrency:
                  ADVal.AsCurrency := ADVal.AsCurrency + ASVal.AsCurrency;
                vdtBcd:
                  BcdAdd(ADVal.AsBcd, ASVal.AsBcd, ADVal.Value.AsBcd^);
              end;
            end
          end
          else
          begin
            if ADef.BaseName <> '*' then
              ADVal.Copy(ASVal^, False)
            else
            begin
              ADVal.TypeNeeded(ADef.ValueType);
              ADVal.AsInteger := 1;
            end;
          end;
        end
        else if AChanged then
          ADest.Values[J].OldValue.Copy(ASVal^, False)
      end;
      Inc(I);
    end;
    if A2Pass then
      Pass2(ADest, I - K);
  end;

begin
  ATemp := TQProvider.AcquireDataSet;
  try
    ADataSet.Close;
    CreateFieldDefs;
    ATemp.Clone(Self);
    if Length(AFilter) > 0 then
    begin
      ATemp.Filter := AFilter;
      ATemp.Filtered := True;
    end;
    ATemp.Sort := ASortFields;
    CopyRecords;
    ADataSet.FOpenBy := dsomByCreate;
    ADataSet.Open;
    ADataSet.Sort := AOrderBy;
  except
    on E: Exception do
    begin
      TQProvider.ReleaseDataSet(ATemp);
      raise;
    end;
  end;
end;

function TQDataSet.GroupBy(AFields, AFilter, AOrderBy: QStringW): TQDataSet;
var
  ATemp: TQDataSet;
begin
  ATemp := TQProvider.AcquireDataSet;
  Result := TQProvider.AcquireDataSet;
  try
    GroupBy(Result, AFields, AFilter, AOrderBy);
  except
    on E: Exception do
    begin
      TQProvider.ReleaseDataSet(ATemp);
      TQProvider.ReleaseDataSet(Result);
      raise;
    end;
  end;
end;

procedure TQDataSet.HandleExceptionInMainThread(ASender: Pointer);
begin
  if Assigned(ApplicationHandleException) then
    ApplicationHandleException(ASender);
end;

procedure TQDataSet.HashOfRecord(ARec: TQRecord; const AFields: TQFieldDefArray;
  var AResult: TQRecordHash);
begin
  AResult.Rec := ARec;
  FlatFieldValues(ARec, AFields, AResult.FlatValues);
  FillChar(AResult.MD5, SizeOf(TQMD5Digest), 0);
  if Length(AResult.FlatValues) > 0 then
  begin
    AResult.HashCode := HashOf(@AResult.FlatValues[0],
      Length(AResult.FlatValues));
    AResult.MD5Hashed := False;
  end
  else
  begin
    AResult.HashCode := 0;
    AResult.MD5Hashed := True;
  end;
end;

procedure TQDataSet.HashRecords(ARecords: TQRecords;
  const AFields: TQFieldDefArray; AHashs: TQHashTable);
var
  I: Integer;
  AHash: PQRecordHash;
begin
  AHashs.Resize(ARecords.Count);
  for I := 0 to ARecords.Count - 1 do
  begin
    New(AHash);
    HashOfRecord(ARecords[I], AFields, AHash^);
    AHashs.Add(AHash, AHash.HashCode);
  end;
end;

function TQDataSet.HashOfRecord(ARec: TQRecord; const AFields: TQFieldDefArray)
  : TQHashType;
var
  ATemp: TBytes;
begin
  FlatFieldValues(ARec, AFields, ATemp);
  if Length(ATemp) > 0 then
    Result := HashOf(@ATemp[0], Length(ATemp))
  else
    Result := 0;
end;

procedure TQDataSet.InternalAddRecord(Buffer: TQRecord; Append: Boolean);
var
  ABuf: TQRecord;
  AInsertPos: Integer;
begin
  ABuf := AllocRecord;
  ABuf.Assign(TQRecord(Buffer));
  if Append then
    AInsertPos := FOriginRecords.Count
  else
    AInsertPos := FRecordNo + 1;
  FOriginRecords.Insert(AInsertPos, ABuf);
  if ABuf.Status <> usUnmodified then
    ABuf.FChangedIndex := ChangedRecords.Add(ABuf);
  if InternalAddToFiltered(ABuf) then
  // 如果当前处于过滤模式，则检查是否需要加入到已过滤的记录列表中
  begin
    if Length(Sort) > 0 then // 如果当前已经排序，则检查是否需要加入到已经排序孤记录列表中
      InternalAddToSorted(ABuf);
    InternalSetToRecord(ABuf);
  end;
end;

{$IFNDEF NEXTGEN}
{$IF RTLVersion>23}

procedure TQDataSet.InternalAddRecord(Buffer: TRecordBuffer; Append: Boolean);
begin
  InternalAddRecord(TQRecord(Buffer), Append);
end;
{$IFEND}
{$ENDIF}
{$IF RTLVersion>24}

procedure TQDataSet.InternalAddRecord(Buffer: TRecBuf; Append: Boolean);
begin
  InternalAddRecord(TQRecord(Buffer), Append);
end;
{$IFEND}

function TQDataSet.InternalAddToFiltered(ABuf: TQRecord): Boolean;
begin
  Result := True;
  if Filtered then
  begin
    FFilteredRecords.Clean;
    if Assigned(OnFilterRecord) then
      OnFilterRecord(Self, Result)
    else if Assigned(FFilterExp) then
      Result := FFilterExp.Accept(RealRecord(ABuf), FilterOptions);
    if Result then
    begin
      if ABuf.FFilteredIndex = -1 then
        ABuf.FFilteredIndex := FFilteredRecords.Add(ABuf)
    end
    else if ABuf.FFilteredIndex <> -1 then
    begin
      FFilteredRecords.Delete(ABuf.FFilteredIndex);
      ABuf.FFilteredIndex := -1;
      ClearBuffers;
    end;
  end;
end;

procedure TQDataSet.InternalAddToSorted(ABuf: TQRecord);
var
  AIndex: Integer;
begin
  if Length(FSort) > 0 then
  begin
    if ABuf.SortedIndex <> -1 then
      FSortedRecords.Delete(ABuf.SortedIndex);
    InternalFind(FSortedRecords, FSortExp, ABuf, AIndex);
    ABuf.FSortedIndex := AIndex;
    FSortedRecords.Insert(AIndex, ABuf);
  end;
end;

procedure TQDataSet.InternalApplyChanges(AProvider: TQProvider);
begin
  CheckBrowseMode;
  if Assigned(FCloneSource) then
    FCloneSource.InternalApplyChanges(AProvider)
  else
  begin;
    if AProvider <> nil then
      AProvider.ApplyChanges(Self);
    MergeChanges;
  end;
end;

procedure TQDataSet.InternalCancel;
begin
  inherited;
  if Assigned(FEditingRow) then
  begin
    if State = dsInsert then
      FreeRecord(FEditingRow);
    FEditingRow := nil;
  end;
end;

procedure TQDataSet.InternalClose;
var
  I: Integer;
begin
  if Assigned(FCloneSource) then
  begin
    FCloneSource.FClones.Remove(Self);
    FCloneSource := nil;
  end;
  if CreateFieldsByUser then
  begin
    DestroyFields;
    if not FDefChanging then
      FieldDefs.Clear;
  end;
  FCursorOpened := False;
  if FDefChanging then
  begin
    if FOpenBy = dsomByClone then
      FOriginRecords.Unlink
    else if Assigned(FProvider) and (FHandle <> 0) then
      FetchAllRecords;
  end
  else
  begin
    // 有多个数据集时将其它数据集释放
    if not FActiveRecordsetChanging then
    begin
      I := 0;
      while I < Length(FRecordsets) do
      begin
        if FRecordsets[I].Owner <> nil then
        begin
          if FRecordsets[I].Owner = Self then
          begin
            FreeObject(FRecordsets[I]);
            Continue;
          end
          else
            FRecordsets[I].RemoveFreeNotification(Self);
        end
        else
          TQProvider.ReleaseDataSet(FRecordsets[I]);
        TQDataSet(FRecordsets[I]) := nil;
        Inc(I);
      end;
      SetLength(FRecordsets, 0);
      FActiveRecordset := -1;
    end;
    FOriginRecords.Clear;
    FChangedRecords.Clear;
    FSortedRecords.Clear;
    FFilteredRecords.Clear;
    FRecordNo := -1;
    if Assigned(FSortExp) then
      ClearSort(FSortExp);
    if Assigned(FFilterExp) then
      FreeAndNil(FFilterExp);
    if Assigned(FProvider) and (FHandle <> 0) then
      FProvider.CloseHandle(FHandle);
    FChecks.Clear;
    FHandle := 0;
    FLoadedRecordCount := 0;
    FProviderRecordCount := 0;
  end;

end;

procedure TQDataSet.InternalDelete;
var
  ABuf: TQRecord;
begin
  ABuf := FActiveRecords[FRecordNo];
  ABuf.AddRef;
  try
    DoDelete(ABuf);
    CloneNotify(ABuf, rcnDeleted);
  finally
    ABuf.Release;
  end;
end;

procedure TQDataSet.InternalEdit;
var
  ABuf, ARealRec: TQRecord;
begin
  inherited;
  ABuf := ActiveRecordBuffer;
  FEditingRow := ABuf.Bookmark;
  if Assigned(ABuf.Bookmark) then // 值拷贝，以便缓存新值
  begin
    ARealRec := RealRecord(ABuf.Bookmark);
    SetLength(ABuf.FValues, Length(ARealRec.FValues));
    ABuf.Assign(ARealRec);
  end;
end;

function TQDataSet.InternalFind(ASorted: TQRecords; AExp: PQSortExp;
  ABuf: TQRecord; var AIndex: Integer): Boolean;
var
  L, H, I, C: Integer;
begin
  Result := False;
  L := 0;
  H := RecordCount - 1;
  while L <= H do
  begin
    I := (L + H) shr 1;
    C := SortCompare(AExp, ASorted[I], ABuf);
    if C < 0 then
      L := I + 1
    else
    begin
      H := I - 1;
      if C = 0 then
        Result := True;
    end;
  end;
  AIndex := L;
end;

procedure TQDataSet.InternalFirst;
begin
  FRecordNo := -1;
end;

function TQDataSet.InternalGetFieldData(ARecord: TQRecord; AField: TField;
  ABuffer: Pointer; AIsOld: Boolean): Boolean;
var
  AValue: PQValue;
  procedure AsAnsiString;
  var
    S: QStringA;
  begin
    if Assigned(AValue.Value.AsString) then
    begin
      S := qstring.AnsiEncode(AValue.Value.AsString^);
      Move(S.Data^, ABuffer^, S.Length);
      PByte(IntPtr(ABuffer) + S.Length)^ := 0;
    end
    else
      PByte(ABuffer)^ := 0;
  end;
  procedure AsGuid;
  var
    S: QStringA;
  begin
    S := qstring.UTF8Encode(GuidToString(AValue.Value.AsGuid^));
    Move(S.Data^, ABuffer^, S.Length);
    PByte(IntPtr(ABuffer) + S.Length)^ := 0;
  end;
  procedure ToDate;
  begin
    PDateTimeRec(ABuffer).Date := DateTimeToTimeStamp
      (AValue.Value.AsDateTime).Date;
  end;
  procedure ToTime;
  begin
    PDateTimeRec(ABuffer).Time := DateTimeToTimeStamp
      (AValue.Value.AsDateTime).Time;
  end;
  procedure ToDateTime;
  begin
    PDateTimeRec(ABuffer).DateTime :=
      TimeStampToMSecs(DateTimeToTimeStamp(AValue.Value.AsDateTime));
  end;

begin
  Result := False;
  if (AField.FieldNo > 0) and (not IsEmpty) then
  begin
    if Assigned(ARecord) then
    begin
      ARecord := RealRecord(ARecord);
      if AIsOld or (not ARecord.Values[AField.FieldNo - 1].Changed) then
        AValue := @ARecord.Values[AField.FieldNo - 1].OldValue
      else
        AValue := @ARecord.Values[AField.FieldNo - 1].NewValue;
      Result := (not AValue.IsNull);
      if Result and Assigned(ABuffer) then
      begin
        case AField.DataType of
          ftString, ftFixedChar:
            AsAnsiString;
          ftGuid:
            AsGuid;
          ftFixedWideChar, ftWideString:
            Move(PQCharW(AValue.Value.AsString^)^, ABuffer^,
              (Length(AValue.Value.AsString^) + 1) shl 1);
          ftSmallint, ftWord:
            PSmallint(ABuffer)^ := AValue.Value.AsInteger;
          ftInteger:
            PInteger(ABuffer)^ := AValue.Value.AsInteger;
          ftLargeint, ftAutoInc{$IFDEF UNICODE}, ftLongword{$ENDIF}:
            PInt64(ABuffer)^ := AValue.Value.AsInt64;
          ftBoolean:
            PWordBool(ABuffer)^ := AValue.Value.AsBoolean;
{$IFDEF UNICODE}
          ftShortint:
            PShortint(ABuffer)^ := AValue.Value.AsInteger;
          ftByte:
            PByte(ABuffer)^ := AValue.Value.AsInteger;
{$ENDIF}
{$IF RTLVersion>=21}
          ftSingle:
            PSingle(ABuffer)^ := AValue.Value.AsSingle;
{$IFEND}
          ftFloat:
            PDouble(ABuffer)^ := AValue.Value.AsFloat;
          ftCurrency:
            PDouble(ABuffer)^ := AValue.Value.AsCurrency;
          ftDate:
            ToDate;
          ftTime:
            ToTime;
          ftDateTime:
            ToDateTime;
          ftBytes, ftVarBytes:
            Move(TMemoryStream(AValue.Value.AsStream).Memory^, ABuffer^,
              TMemoryStream(AValue.Value.AsStream).Size);
          ftBcd, ftFMTBcd:
            PBcd(ABuffer)^ := AValue.Value.AsBcd^;
          ftTimeStamp:
            SqlTimSt.PSQLTimeStamp(ABuffer)^ :=
              DateTimeToSQLTimeStamp(AValue.Value.AsDateTime);
          ftBlob, ftGraphic, ftTypedBinary, ftMemo, ftFmtMemo, ftWideMemo:
            { 什么也不需要做，二进制数据的访问是通过CreateBlobStream来执行的 }
            ;
          ftOraInterval:
            PQInterval(ABuffer)^ := AValue.Value.AsInterval
        else
          DatabaseError(Format(SUnsupportFieldType, [AField.DisplayName,
            FieldTypeNames[AField.DataType]]));
        end;
      end;
    end
    else
      Result := False;
  end;
end;
{$IFNDEF NEXTGEN}

procedure TQDataSet.InternalGotoBookmark(Bookmark: Pointer);
begin
  InternalSetToRecord(PPointer(Bookmark)^);
end;
{$IF RTLVersion>23}

procedure TQDataSet.InternalGotoBookmark(Bookmark: TBookmark);
begin
  InternalSetToRecord(PPointer(@Bookmark[0])^);
end;
{$IFEND >XE3}
{$ENDIF !NEXTGEN}

procedure TQDataSet.InternalHandleException;
begin
  RunInMainThread(HandleExceptionInMainThread, Self);
end;

procedure TQDataSet.InternalInitRecord(Buffer: TQRecord);
begin
  Buffer.Reset
end;
{$IF RTLVersion>24}

procedure TQDataSet.InternalInitRecord(Buffer: TRecBuf);
begin
  InternalInitRecord(TQRecord(Buffer));
end;
{$IFEND}

procedure TQDataSet.InternalInitFieldDefs;
begin
  FieldDefs.Clear;
  if Assigned(FOnInitFieldDefs) then
    FOnInitFieldDefs(Self);
end;
{$IFNDEF UNICODE}

procedure TQDataSet.InternalInitRecord(Buffer: PChar);
begin
  InternalInitRecord(TQRecord(Buffer));
end;
{$ENDIF}
{$IFNDEF NEXTGEN}
{$IF RTLVersion>19}

procedure TQDataSet.InternalInitRecord(Buffer: TRecordBuffer);
begin
  InternalInitRecord(TQRecord(Buffer));
end;
{$IFEND}
{$ENDIF}

procedure TQDataSet.InternalInsert;
var
  ARec: TQRecord;
begin
  ARec := ActiveRecordBuffer;
  FEditingRow := AllocRecord;
  FEditingRow.FStatus := usInserted;
  inherited;
  if (ARec.BookmarkFlag = bfEof) or IsEmpty then // 追加
    FEditingRow.FOriginIndex := FOriginRecords.Count
  else // 插入
  begin
    if FActiveRecords = FOriginRecords then // 如果未过滤
    begin
      if FOriginRecords.Count > 0 then
        FEditingRow.FOriginIndex := FRecordNo + ActiveRecord
      else
        FEditingRow.FOriginIndex := 0;
    end
    else
      // 如果是在已经排序或过滤的结果集中插入，则在原始记录列表中直接追加到末尾
      FEditingRow.FOriginIndex := FOriginRecords.Count;
  end;
  ActiveRecordBuffer.FBookmark := FEditingRow;
end;

procedure TQDataSet.InternalLast;
begin
  FRecordNo := RecordCount;
end;

procedure TQDataSet.InternalOpen;
  procedure DefsFromFields;
  var
    I: Integer;
    ADef: TQFieldDef;
    AField: TField;
  begin
    for I := 0 to Fields.Count - 1 do
    begin
      AField := Fields[I];
      FieldDefs.Add(AField.FieldName, AField.DataType, AField.Size,
        AField.Required);
    end;
  end;
  procedure DoCustomCreate;
  begin
    if Assigned(FOnInitFieldDefs) then
      FOnInitFieldDefs(Self);
    if Assigned(FOnLoadData) then
      FOnLoadData(Self);
    if CreateFieldsByUser then
      CreateFields();
    if (FieldDefs.Count = 0) and (Fields.Count > 0) then
      DefsFromFields;
    BindFields(True);
  end;
  procedure DoClone;
  var
    I: Integer;
    ACopy, ASource: TQRecord;
  begin
    FieldDefs.Assign(FCloneSource.FieldDefs);
    for I := 0 to FCloneSource.FOriginRecords.Count - 1 do
    begin
      ACopy := AllocRecord;
      ASource := TQRecord(FCloneSource.FOriginRecords[I]);
      ACopy.FBookmark := ASource;
      // 记录的其它xxxIndex与记录的过滤、排序状态有关，独立于原始数据集
      ACopy.FOriginIndex := FOriginRecords.Add(ACopy);
      if ACopy.Status <> usUnmodified then
        ACopy.FChangedIndex := ChangedRecords.Add(ACopy);
    end;
    if CreateFieldsByUser then
      CreateFields;
    BindFields(True);
    FCloneSource.FClones.Add(Self);
  end;

  procedure DoDefaultCreate;
  begin
    if CreateFieldsByUser then
      CreateFields;
    BindFields(True);
  end;

  procedure DoFromProvider;
  begin
    if FProvider.FActiveFieldDefs <> FieldDefs then
    begin
      if not FProvider.OpenDataSet(Self, FCommandText) then
        DatabaseError(FProvider.LastErrorMsg, Self);
    end
    else
      DoDefaultCreate;
  end;
  procedure DefsCheck;
  var
    I: Integer;
  begin
    for I := 0 to FieldDefs.Count - 1 do
      (FieldDefs[I] as TQFieldDef).LookupValueType;
  end;

begin
  FIsOpening := True;
  try
    case FOpenBy of
      dsomByCreate:
        DoCustomCreate;
      dsomByProvider:
        DoFromProvider;
      dsomByConverter:
        DoDefaultCreate;
      dsomByClone:
        DoClone;
      dsomByCopy:
        DoDefaultCreate;
    end;
    FRecordNo := -1;
    BookmarkSize := SizeOf(Pointer) * 2;
    FCursorOpened := True;
    DefsCheck;
    if Filtered then
      FilterRecords(True, False);
    if Length(FSort) > 0 then
    begin
      ClearSort(FSortExp);
      FSortExp := ParseSort(FSort);
      DoSort(False);
    end;
  finally
    FIsOpening := False;
  end;
end;

procedure TQDataSet.InternalPost;
var
  AEdited: TQRecord;
  procedure ApplyRecordChanges(ARecord: TQRecord);
  var
    AList: TQRecords;
  begin
    // Todo:ARecord的引用计数不正确，造成提交出问题
    AList := TQRecords.Create(ditChanged);
    try
      AList.AddWithoutRef(ARecord);
      Provider.InternalApplyChanges(FieldDefs, AList);
      MergeRecordChanges(ARecord);
      AList.DeleteWithoutRef(0);
    finally
      FreeObject(AList);
    end;
  end;
  procedure PostChanges;
  var
    ACopy: TQRecord;
  begin
    FChecks.Check(AEdited);
    if State = dsEdit then
    begin
      ACopy := RealRecord(FEditingRow);
      if Assigned(Provider) and (not BatchMode) then
      begin
        ApplyRecordChanges(AEdited);
        ACopy.Assign(AEdited);
      end
      else
      begin
        ACopy.Assign(AEdited);
        if ACopy.Status <> usInserted then
          ACopy.FStatus := usModified;
      end;
    end
    else
    begin
      // 如果是克隆的子实例，则将记录插入主实例，并创建一个游标
      if Assigned(Provider) and (not BatchMode) then
        ApplyRecordChanges(FEditingRow);
      if Assigned(FCloneSource) then
      begin
        FCloneSource.FOriginRecords.Insert(FEditingRow.FOriginIndex,
          FEditingRow);
        ACopy := AllocRecord;
        ACopy.FBookmark := FEditingRow;
        ACopy.FOriginIndex := FEditingRow.FOriginIndex;
        FEditingRow := ACopy;
      end;
      FOriginRecords.Insert(FEditingRow.FOriginIndex, FEditingRow);
      FEditingRow.Release;
    end;
    if FEditingRow.Status in [usModified, usInserted] then
    begin
      if FEditingRow.ChangedIndex = -1 then
        // 如果是新增的记录，则记录到变更里
        FEditingRow.FChangedIndex := ChangedRecords.Add(FEditingRow);
    end;
    if InternalAddToFiltered(FEditingRow) then
    begin
      InternalAddToSorted(FEditingRow);
      InternalSetToRecord(FEditingRow);
    end;
    if State = dsEdit then
      CloneNotify(FEditingRow, rcnModified)
    else
      CloneNotify(FEditingRow, rcnInserted);
  end;
  procedure ClonesCheck;
  var
    I, ACount: Integer;
    ASource: TQDataSet;
  begin
    if Assigned(FCloneSource) then
    begin
      ASource := FCloneSource;
      if FCloneSource.State in [dsEdit, dsInsert] then
        DatabaseError(SMultiEditUnsupport, Self);
    end
    else
      ASource := Self;
    ACount := 0;
    for I := 0 to ASource.FClones.Count - 1 do
    begin
      if TQDataSet(ASource.FClones[I]).State in [dsEdit, dsInsert] then
        Inc(ACount);
    end;
    if ACount > 1 then
      DatabaseError(SMultiEditUnsupport, Self);
  end;

begin
  ClonesCheck;
  AEdited := TQRecord(ActiveBuffer());
  if State = dsInsert then
    PostChanges
  else if AEdited.Modified then
    PostChanges;
  AEdited.FBookmark := nil;
  FEditingRow := nil;
end;
{$IF RTLVersion>24}

procedure TQDataSet.InternalSetToRecord(Buffer: TRecBuf);
begin
  InternalSetToRecord(TQRecord(Buffer));
end;
{$IFEND}

procedure TQDataSet.InternalSetFieldData(ARecord: TQRecord; AField: TField;
  ABuffer: Pointer; AIsOld: Boolean);
var
  AValue: PQValue;
  AFieldIdx: Integer;
  procedure AsTime;
  var
    AStamp: TTimeStamp;
  begin
    AValue.TypeNeeded(vdtDateTime);
    AStamp.Date := DateDelta;
    AStamp.Time := PDateTimeRec(ABuffer).Time;
    AValue.Value.AsDateTime := TimeStampToDateTime(AStamp);
  end;

  procedure AsDate;
  var
    AStamp: TTimeStamp;
  begin
    AValue.TypeNeeded(vdtDateTime);
    AStamp.Date := PDateTimeRec(ABuffer).Date;
    AStamp.Time := 0;
    AValue.Value.AsDateTime := TimeStampToDateTime(AStamp);
  end;

  procedure AsDateTime;
  begin
    AValue.TypeNeeded(vdtDateTime);
    AValue.Value.AsDateTime := TimeStampToDateTime
      (MSecsToTimeStamp(PDateTimeRec(ABuffer).DateTime));
  end;

begin
  if (AField.FieldNo > 0) and Assigned(ARecord) then
  begin
    if AField.ReadOnly and not(State in [dsSetKey, dsFilter]) then
      DatabaseErrorFmt(SFieldReadOnly, [AField.DisplayName]);
    if Assigned(ARecord.Bookmark) then
      ARecord := ARecord.Bookmark;
    AFieldIdx := AField.FieldNo - 1;
    if AIsOld then
      AValue := @ARecord.Values[AFieldIdx].OldValue
    else
    begin
      AValue := @ARecord.Values[AFieldIdx].NewValue;
      ARecord.Values[AFieldIdx].Changed := True;
    end;
    if ABuffer = nil then
      AValue.Reset
    else
    begin
      case AField.DataType of
        ftString, ftFixedChar:
          begin
            AValue.TypeNeeded(vdtString);
            AValue.Value.AsString^ := AnsiDecode(PQCharA(ABuffer), -1);
          end;
        ftGuid:
          begin
            AValue.TypeNeeded(vdtGuid);
            AValue.Value.AsGuid^ :=
              StringToGUID(AnsiDecode(PQCharA(ABuffer), -1));
          end;
        ftFixedWideChar, ftWideString:
          begin
            AValue.TypeNeeded(vdtString);
            AValue.Value.AsString^ := PWideChar(ABuffer);
          end;
        ftSmallint, ftWord:
          begin
            AValue.TypeNeeded(vdtInteger);
            AValue.Value.AsInteger := PSmallint(ABuffer)^;
          end;
        ftInteger:
          begin
            AValue.TypeNeeded(vdtInteger);
            AValue.Value.AsInteger := PInteger(ABuffer)^;
          end;
        ftLargeint, ftAutoInc:
          begin
            AValue.TypeNeeded(vdtInt64);
            AValue.Value.AsInt64 := PInt64(ABuffer)^;
          end;
        ftBoolean:
          begin
            AValue.TypeNeeded(vdtBoolean);
            AValue.Value.AsBoolean := PBoolean(ABuffer)^;
          end;
{$IFDEF UNICODE}
        ftShortint:
          begin
            AValue.TypeNeeded(vdtInteger);
            AValue.Value.AsInteger := PShortint(ABuffer)^;
          end;
        ftByte:
          begin
            AValue.TypeNeeded(vdtInteger);
            AValue.Value.AsInteger := PByte(ABuffer)^;
          end;
{$ENDIF}
{$IF RTLVersion>=21}
        ftSingle:
          begin
            AValue.TypeNeeded(vdtSingle);
            AValue.Value.AsSingle := PSingle(ABuffer)^;
          end;
{$IFEND}
        ftFloat:
          begin
            AValue.TypeNeeded(vdtFloat);
            AValue.Value.AsFloat := PDouble(ABuffer)^;
          end;
        ftCurrency:
          begin
            AValue.TypeNeeded(vdtCurrency);
            AValue.Value.AsCurrency := PDouble(ABuffer)^;
          end;
        ftBcd:
          begin
            AValue.TypeNeeded(vdtBcd);
            AValue.Value.AsBcd^ := PBcd(ABuffer)^;
          end;
        ftDate:
          AsDate;
        ftTime:
          AsTime;
        ftDateTime:
          AsDateTime;
        ftBytes, ftVarBytes:
          begin
            AValue.TypeNeeded(vdtStream);
            AValue.AsStream.Size := AField.Size;
            Move(ABuffer^, AValue.AsStream.Memory^, AField.Size);
          end;
        ftFMTBcd:
          begin
            AValue.TypeNeeded(vdtBcd);
            AValue.Value.AsBcd^ := PBcd(ABuffer)^;
          end;
        ftBlob, ftGraphic, ftTypedBinary, ftMemo, ftFmtMemo, ftWideMemo:
          begin
            AValue.TypeNeeded(vdtStream);
            AValue.AsStream.Size := PQValue(ABuffer).AsStream.Size;
            Move(PQValue(ABuffer).AsStream.Memory^, AValue.AsStream.Memory^,
              AValue.AsStream.Size);
          end;
        ftOraInterval:
          AValue.Value.AsInterval := PQInterval(ABuffer)^;
      else
        DatabaseError(Format(SFieldCantSetData, [AField.DisplayName,
          FieldTypeNames[AField.DataType]]));
      end;
    end;
  end;
end;

{$IFNDEF NEXTGEN}
{$IFNDEF UNICODE}

procedure TQDataSet.InternalSetToRecord(Buffer: PChar);
begin
  InternalSetToRecord(TQRecord(Buffer));
end;
{$ENDIF}
{$IF RTLVersion>19}

procedure TQDataSet.InternalSetToRecord(Buffer: TRecordBuffer);
begin
  InternalSetToRecord(TQRecord(Buffer));
end;
{$IFEND}
{$ENDIF}

procedure TQDataSet.Intersect(ASource1, ASource2: TQDataSet; AFields: QStringW);
var
  AHash1, AHash2: TQDiffCache;
  I: Integer;
  AList1, ATemp: PQHashList;
  R1, R2: TQRecord;
  AColVal: PQColumnValue;
  procedure CopyRecord(ASource: TQRecord; const AFields: TQFieldDefArray);
  var
    J: Integer;
  begin
    R2 := AllocRecord;
    R2.FStatus := ASource.Status;
    for J := 0 to FieldDefs.Count - 1 do
    begin
      AColVal := @ASource.Values[AFields[J].FieldNo - 1];
      if AColVal.Changed then
        R2.Values[J].NewValue.Copy(AColVal.NewValue, False);
      if R2.Status <> usInserted then
        R2.Values[J].OldValue.Copy(AColVal.OldValue, False);
      R2.Values[J].Changed := AColVal.Changed;
    end;
    if R2.Status <> usDeleted then
      R2.FOriginIndex := FOriginRecords.Add(R2);
    if R2.Status <> usUnmodified then
      R2.FChangedIndex := FChangedRecords.Add(R2);
  end;

  function DoCompareInHashTable(const V1: TBytes; AFirst: PQHashList;
    ATable: TQDiffCache): Boolean;
  var
    V2: TBytes;
  begin
    Result := False;
    while AFirst <> nil do
    begin
      FlatFieldValues(AFirst.Data, ATable.Fields, V2);
      if (Length(V1) = Length(V2)) and CompareMem(@V1[0], @V2[0], Length(V1))
      then
      begin
        Result := True;
        Exit;
      end;
      AFirst := ATable.HashTable.FindNext(AFirst);
    end;
  end;

  function FindInHash(AItem: PQHashList): Boolean;
  var
    V1: TBytes;
    AStep: Integer;
  begin
    Result := False;
    ATemp := AHash1.HashTable.FindFirst(AItem.Hash);
    if ATemp = AItem then
      ATemp := AHash1.HashTable.FindNext(ATemp);
    AStep := 0;
    if Assigned(ATemp) then
    begin
      AStep := 1;
      FlatFieldValues(AItem.Data, AHash1.Fields, V1);
      Result := DoCompareInHashTable(V1, ATemp, AHash1);
      if Result then
        Exit;
    end;
    ATemp := AHash2.HashTable.FindFirst(AItem.Hash);
    if ATemp = AItem then
      ATemp := AHash2.HashTable.FindNext(ATemp);
    if Assigned(ATemp) then
    begin
      if AStep = 0 then
        FlatFieldValues(AItem.Data, AHash1.Fields, V1);
      Result := DoCompareInHashTable(V1, ATemp, AHash2);
    end;
  end;

  procedure RemoveDuplicates(ACache: TQDiffCache);
  var
    I: Integer;
    V1, V2: TBytes;
  begin
    I := 0;
    while I < ACache.HashTable.BucketCount do
    begin
      AList1 := ACache.HashTable.Buckets[I];
      while AList1 <> nil do
      begin
        ATemp := ACache.HashTable.FindNext(AList1);
        if Assigned(ATemp) then
        begin
          FlatFieldValues(AList1.Data, ACache.Fields, V1);
          while ATemp <> nil do
          begin
            R1 := ATemp.Data;
            FlatFieldValues(R1, ACache.Fields, V2);
            if (Length(V1) = Length(V2)) and CompareMem(@V1[0], @V2[0],
              Length(V1)) then
            begin
              ATemp := ACache.HashTable.FindNext(ATemp);
              ACache.HashTable.Delete(R1, AList1.Hash);
            end;
          end;
        end;
        AList1 := AList1.Next;
      end;
      Inc(I);
    end;
  end;

begin
  PrepareDiffCheck(ASource1, ASource2, AFields, AHash1, AHash2);
  RemoveDuplicates(AHash1);
  RemoveDuplicates(AHash2);
  for I := 0 to AHash1.HashTable.BucketCount - 1 do
  begin
    AList1 := AHash1.HashTable.Buckets[I];
    while Assigned(AList1) do
    begin
      if FindInHash(AList1) then
        CopyRecord(AList1.Data, AHash1.Fields);
      AList1 := AList1.Next;
    end;
  end;
  FOpenBy := dsomByCreate;
  FreeObject(AHash1.HashTable);
  FreeObject(AHash2.HashTable);
  Open;
end;

function TQDataSet.IsCursorOpen: Boolean;
begin
  Result := FCursorOpened;
end;

function TQDataSet.IsSorted: Boolean;
begin
  Result := (Length(Sort) > 0) or Assigned(FOnCustomSort);
end;

function TQDataSet.LoadFields(ADefs: TQFieldDefs): Boolean;
begin
  ADefs.Assign(FieldDefs);
  Result := True;
end;

procedure TQDataSet.LoadFromFile(const AFileName: QStringW;
  AConverterClass: TQConverterClass);
var
  AStream: TMemoryStream;
begin
  AStream := TMemoryStream.Create;
  try
    AStream.LoadFromFile(AFileName);
    LoadFromStream(AStream, AConverterClass);
  finally
    FreeObject(AStream);
  end;
end;

procedure TQDataSet.LoadFromFile(const AFileName: QStringW;
  AConverter: TQConverter);
var
  AStream: TFileStream;
begin
  AStream := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyWrite);
  try
    LoadFromStream(AStream, AConverter);
  finally
    FreeObject(AStream);
  end;
end;

procedure TQDataSet.LoadFromStream(AStream: TStream; AConverter: TQConverter);
var
  ARec: TQRecord;
  I: Integer;
  procedure LoadDataSet(ADataSet: TQDataSet);
  begin
    AConverter.BeginImport(AConverter.FActiveDataSet);
    try
      ADataSet.FOpenBy := dsomByConverter;
      AConverter.DoProgress(csLoadFields, 0, 0);
      AConverter.LoadFieldDefs(ADataSet.FieldDefs as TQFieldDefs);
      AConverter.DoProgress(csLoadData, 0, 0);
      ARec := ADataSet.AllocRecord;
      while AConverter.ReadRecord(ARec) do
      begin
        if ARec.Status = usDeleted then
          ARec.FChangedIndex := ADataSet.FChangedRecords.Add(ARec)
        else
        begin
          ARec.FOriginIndex := ADataSet.FOriginRecords.Add(ARec);
          if ARec.Status <> usUnmodified then
            ARec.FChangedIndex := ADataSet.FChangedRecords.Add(ARec);
        end;
        ARec := ADataSet.AllocRecord;
      end;
      ADataSet.FreeRecord(ARec);
      ADataSet.Open;
    finally
      AConverter.EndImport(AConverter.FActiveDataSet);
    end;
  end;

  procedure CopySingleDataSet;
  var
    ATemp: TQRecords;
    ASource: TQDataSet;
    I: Integer;
    ADefs: TQFieldDefs;
  begin
    ASource := FRecordsets[0];
    ATemp := FOriginRecords;
    FOriginRecords := ASource.FOriginRecords;
    ASource.FOriginRecords := ATemp;
    ATemp := FChangedRecords;
    FChangedRecords := ASource.FChangedRecords;
    ASource.FChangedRecords := ATemp;
    FieldDefs.Assign(ASource.FieldDefs);
    FActiveRecords := FOriginRecords;
    FOpenBy := dsomByCopy;
    ADefs := FieldDefs as TQFieldDefs;
    for I := 0 to FOriginRecords.Count - 1 do
      FOriginRecords[I].FFields := ADefs;
    for I := 0 to FChangedRecords.Count - 1 do
      FChangedRecords[I].FFields := ADefs;
    Open;
  end;

begin
  Close;
  FOpenBy := dsomByConverter;
  FieldDefs.Clear;
  AConverter.FDataSet := Self;
  AConverter.FStream := AStream;
  AConverter.BeforeImport;
  try
    if AConverter.FDataSetCount > 1 then
    begin
      SetLength(FRecordsets, 0);
      I := 0;
      while I < AConverter.FDataSetCount do
      begin
        if (I and $F) = 0 then
          SetLength(FRecordsets, Length(FRecordsets) + 16);
        AConverter.FActiveDataSet := I;
        FRecordsets[I] := TQDataSet.Create(Self);
        LoadDataSet(FRecordsets[I]);
        Inc(I);
      end;
      if I = 1 then
      begin
        CopySingleDataSet;
        FreeAndNil(FRecordsets[0]);
        SetLength(FRecordsets, 0);
      end
      else
      begin
        SetLength(FRecordsets, I);
        ActiveRecordset := 0;
      end;
    end
    else
    begin
      AConverter.FActiveDataSet := 0;
      LoadDataSet(Self);
    end;
  finally
    AConverter.AfterImport;
    if AConverter.DataSetCount > 1 then
      SetLength(FRecordsets, AConverter.DataSetCount);
  end;
end;

procedure TQDataSet.LoadFromStream(AStream: TStream;
  AConverterClass: TQConverterClass);
var
  AConverter: TQConverter;
begin
  AConverter := AConverterClass.Create(nil);
  try
    LoadFromStream(AStream, AConverter);
  finally
    FreeObject(AConverter);
  end;
end;

function TQDataSet.Locate(const KeyFields: string; const KeyValues: Variant;
  Options: TLocateOptions): Boolean;
begin
  Result := LocateEx(KeyFields, KeyValues, Options, True, False);
end;

function TQDataSet.LocateEx(const KeyFields: QStringW; const KeyValues: Variant;
  Options: TLocateOptions; ARestart, AGoBack: Boolean): Boolean;
var
  AIndex, ADelta, ARange: Integer;
  ARec: TQRecord;
  AFields: array of TFieldDef;
  AValues: array of QStringW;
  procedure Prepare;
  var
    p: PQCharW;
    AFieldName: QStringW;
    I: Integer;
  const
    FieldsDelimiters: PWideChar = ',;';
  begin
    if ARestart then
    begin
      if AGoBack then
        AIndex := RecordCount
      else
        AIndex := -1;
    end
    else
      AIndex := RecNo - 1;
    if AGoBack then
    begin
      ARange := -1;
      ADelta := -1;
      Dec(AIndex);
    end
    else
    begin
      ARange := RecordCount;
      ADelta := 1;
      Inc(AIndex);
    end;
    p := PQCharW(KeyFields);
    SetLength(AFields, FieldDefs.Count);
    I := 0;
    while p^ <> #0 do
    begin
      AFieldName := DecodeTokenW(p, FieldsDelimiters, QCharW(#0), True);
      AFields[I] := FieldDefs.Find(AFieldName);
      if not Assigned(AFields[I]) then
        DatabaseError(Format(SFieldNotFound, [AFieldName]));
      Inc(I);
    end;
    SetLength(AFields, I);
    if I > 1 then
    begin
      if not(VarIsArray(KeyValues) and (VarArrayHighBound(KeyValues, 1) <> I))
      then
        DatabaseError(SBadLocateValues);
      SetLength(AValues, I);
      for I := 0 to High(AValues) do
        AValues[I] := VarToStr(KeyValues[I]);
    end
    else
    begin
      SetLength(AValues, 1);
      AValues[0] := VarToStr(KeyValues);
    end;
  end;

  function LocateCompare: Boolean;
  var
    I: Integer;
  begin
    ARec := FActiveRecords[AIndex];
    Result := True;
    for I := 0 to High(AFields) do
    begin
      if loCaseInsensitive in Options then
      begin
        if loPartialKey in Options then
          Result := StrIStrW(PQCharW(ARec.Values[AFields[I].FieldNo - 1]
            .CurrentValue^.AsString), PQCharW(AValues[I])) <> nil
        else
          Result := StrCmpW(PQCharW(ARec.Values[AFields[I].FieldNo - 1]
            .CurrentValue^.AsString), PQCharW(AValues[I]), True) = 0;
      end
      else
      begin
        if loPartialKey in Options then
          Result := StrStrW(PQCharW(ARec.Values[AFields[I].FieldNo - 1]
            .CurrentValue^.AsString), PQCharW(AValues[I])) <> nil
        else
          Result := StrCmpW(PQCharW(ARec.Values[AFields[I].FieldNo - 1]
            .CurrentValue^.AsString), PQCharW(AValues[I]), False) = 0;
      end;
      if not Result then
        Break;
    end;
  end;

begin
  CheckBrowseMode;
  Result := False;
  Prepare;
  while AIndex <> ARange do
  begin
    Result := LocateCompare;
    if Result then
    begin
      RecNo := AIndex + 1;
      Break;
    end;
    Inc(AIndex, ADelta);
  end;
end;

function TQDataSet.LocateFirst(const KeyFields: string;
  const KeyValues: Variant; Options: TLocateOptions): Boolean;
begin
  Result := LocateEx(KeyFields, KeyValues, Options, True, False);
end;

function TQDataSet.LocateLast(const KeyFields: string; const KeyValues: Variant;
  Options: TLocateOptions): Boolean;
var
  ARecNo: Integer;
begin
  Result := False;
  CheckBrowseMode;
  ARecNo := RecNo;
  DisableControls;
  try
    Result := LocateEx(KeyFields, KeyValues, Options, True, True);
  finally
    if not Result then
      RecNo := ARecNo;
    EnableControls;
  end;
end;

function TQDataSet.LocateNext(const KeyFields: string; const KeyValues: Variant;
  Options: TLocateOptions): Boolean;
begin
  Result := LocateEx(KeyFields, KeyValues, Options, False, False);
end;

function TQDataSet.LocatePrior(const KeyFields: string;
  const KeyValues: Variant; Options: TLocateOptions): Boolean;
begin
  Result := LocateEx(KeyFields, KeyValues, Options, False, True);
end;

procedure TQDataSet.InternalSetToRecord(Buffer: TQRecord);
begin
  FActiveRecords.Clean;
  if (Buffer <> FEditingRow) and Assigned(Buffer.Bookmark) then
    Buffer := Buffer.Bookmark;
  if Length(FSort) > 0 then
    FRecordNo := Buffer.FSortedIndex
  else if Filtered then
    FRecordNo := Buffer.FFilteredIndex
  else
    FRecordNo := Buffer.FOriginIndex;
  if PageSize <> 0 then
    FRecordNo := FRecordNo - FPageSize * FPageIndex;
end;
{$IFNDEF NEXTGEN}

procedure TQDataSet.InternalAddRecord(Buffer: Pointer; Append: Boolean);
begin
  InternalAddRecord(TQRecord(Buffer), Append);
end;
{$ENDIF}

procedure TQDataSet.MarkRecordStatus(ARec: TQRecord; ANewStatus: TUpdateStatus);
var
  I: Integer;
begin
  ChangedRecords.Clean;
  case ANewStatus of
    usUnmodified: // 标记为未修改
      begin
        if ARec.ChangedIndex <> -1 then
          ChangedRecords.Delete(ARec.ChangedIndex);
        ARec.FChangedIndex := -1;
        ARec.FStatus := ANewStatus;
        for I := 0 to High(ARec.Values) do
        begin
          if ARec.Values[I].Changed then
          begin
            ARec.Values[I].OldValue.Copy(ARec.Values[I].NewValue, False);
            ARec.Values[I].NewValue.Reset;
            ARec.Values[I].Changed := False;
          end;
        end;
      end;
    usModified:
      DatabaseError(SCantMarkRecordAsModified, Self);
    usInserted:
      begin
        if ARec.FChangedIndex = -1 then
          ARec.FChangedIndex := FChangedRecords.Add(ARec);
        ARec.FStatus := ANewStatus;
        for I := 0 to High(ARec.Values) do
        begin
          if not ARec.Values[I].Changed then
          begin
            ARec.Values[I].NewValue.Copy(ARec.Values[I].OldValue, False);
            ARec.Values[I].OldValue.Reset;
            ARec.Values[I].Changed := True;
          end;
        end;
      end;
    usDeleted:
      begin
        if ARec.ChangedIndex = -1 then
          ARec.FChangedIndex := FChangedRecords.Add(ARec);
        ARec.FStatus := ANewStatus;
        FOriginRecords.Delete(ARec.FOriginIndex);
        ARec.FOriginIndex := -1;
      end;
  end;
end;

procedure TQDataSet.MarkStatus(ANewStatus: TUpdateStatus; ApplyToAll: Boolean);
var
  I: Integer;
  ARec: TQRecord;
  procedure MarkDeletedRecords;
  var
    I, J: Integer;
    ACopy: TQRecord;
    AModified: Boolean;
  begin
    // 将删除的数据也标记为当前状态
    I := 0;
    while I < ChangedRecords.Count do
    begin
      ARec := ChangedRecords[I];
      if ARec.Status = usDeleted then
      begin
        ACopy := AllocRecord;
        ACopy.CopyValues(ARec);
        ACopy.FStatus := ANewStatus;
        if Assigned(FCloneSource) then
        begin
          ACopy.FOriginIndex := FCloneSource.FOriginRecords.Add(ACopy);
          CloneNotify(ACopy, rcnInserted);
        end
        else
          ACopy.FOriginIndex := FOriginRecords.Add(ACopy);
        case ANewStatus of
          usUnmodified, usInserted:
            MarkRecordStatus(ACopy, ANewStatus);
          usModified:
            begin
              AModified := False;
              for J := 0 to High(ACopy.Values) do
              begin
                if ACopy.Values[J].Changed then
                begin
                  AModified := True;
                  Break;
                end;
              end;
              if not AModified then
                MarkRecordStatus(ACopy, ANewStatus);
            end;
        end;
      end;
      Inc(I);
    end;
  end;

begin
  CheckBrowseMode;
  if ApplyToAll then
  begin
    I := 0;
    while I < FOriginRecords.Count do
    begin
      ARec := FOriginRecords[I];
      if ARec.Status <> ANewStatus then
      begin
        if Assigned(ARec.Bookmark) then
          MarkRecordStatus(ARec.Bookmark, ANewStatus)
        else
          MarkRecordStatus(ARec, ANewStatus);
      end;
      Inc(I);
    end;
    if ANewStatus <> usDeleted then
      MarkDeletedRecords;
  end
  else
  begin
    ARec := ActiveRecordBuffer.Bookmark;
    if ARec.Status <> ANewStatus then
    begin
      if Assigned(ARec.Bookmark) then
        MarkRecordStatus(ARec.Bookmark, ANewStatus)
      else
        MarkRecordStatus(ARec, ANewStatus);
    end;
  end;
  Resync([]);
end;

procedure TQDataSet.MasterChanged(Sender: TObject);
var
  AFilter: QStringW;
  I: Integer;
  AField: TField;
begin
  if Assigned(FOnMasterChanged) then
  begin
    FOnMasterChanged(Self);
    Exit;
  end;
  if not Active then
    Exit;
  CheckBrowseMode;
  AFilter := '';
  for I := 0 to FMasterLink.Fields.Count - 1 do
  begin
    AField := FMasterLink.Fields[I];
    if I < Length(FDetailFields) then
      AFilter := FDetailFields[I]
    else
      AFilter := AField.FieldName;
    if AField.IsNull then
      AFilter := AFilter + ' is null and '
    else if AField is TStringField then
      AFilter := AFilter + '=' + QuotedStrW(AField.AsWideString, '''') + ' and '
    else if (AField is TDateTimeField) or (AField is TSQLTimeStampField) then
      AFilter := AFilter + '=''' + FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz',
        AField.AsDateTime) + ''' and '
    else if AField is TNumericField then
      AFilter := AFilter + '=' + AField.AsWideString + ''' and '
    else if AField is TBooleanField then
      AFilter := AFilter + '=' + BoolToStr(AField.AsBoolean, True) + ' and '
    else
      raise QException.CreateFmt(SUnsupportFieldType,
        [AField.Name, FieldTypeNames[AField.DataType]]);
  end;
  if Length(AFilter) > 0 then
    SetLength(AFilter, Length(AFilter) - 5);
  if not Assigned(FFilterExp) then
    FFilterExp := TQFilterExp.Create(Self);
  FFilterExp.Parse(AFilter, False, False);
  if not Filtered then
    Filtered := True
  else
    FilterRecords(False, True);

end;

procedure TQDataSet.MasterDisabled(Sender: TObject);
begin
  Filter := '';
  Filtered := False;
  if Assigned(FOnMasterChanged) then
    FOnMasterChanged(Self);
end;

function TQDataSet.Max(AFieldName: QStringW): Variant;
var
  I: Integer;
  ADef: TQFieldDef;
  AVal: TQValue;
  ARec: TQRecord;
begin
  ADef := FieldDefs.Find(AFieldName) as TQFieldDef;
  if FActiveRecords.Count > 0 then
  begin
    ARec := RealRecord(FActiveRecords[0]);
    AVal.Copy(ARec.Values[ADef.FieldNo - 1].CurrentValue^, False);
    for I := 1 to FActiveRecords.Count - 1 do
    begin
      ARec := FActiveRecords[I];
      if ADef.ValueComparor(@AVal, ARec.Values[ADef.FieldNo - 1].CurrentValue) < 0
      then
        AVal.Copy(ARec.Values[ADef.FieldNo - 1].CurrentValue^, False);
    end;
    Result := AVal.AsVariant;
  end
  else
    VarClear(Result);
end;

function TQDataSet.MD5OfRecord(ARec: TQRecord; const AFields: TQFieldDefArray)
  : TQMD5Digest;
var
  ATemp: TBytes;
begin
  FlatFieldValues(ARec, AFields, ATemp);
  if Length(ATemp) > 0 then
    Result := MD5Hash(@ATemp[0], Length(ATemp))
  else
    FillChar(Result, SizeOf(TQMD5Digest), 0);
end;

procedure TQDataSet.Merge(ASource: TQDataSet; AType: TQDataMergeMethod;
  ACheckDeleted: Boolean);
var
  AFields: TQFieldDefArray;
  I, J, ASrcIdx, ADestIdx: Integer;
  ARec, ASrc: TQRecord;

  procedure AddRecord;
  begin
    ARec := AllocRecord;
    ARec.FStatus := ASrc.Status;
    case ARec.Status of
      usUnmodified:
        begin
          J := 0;
          while J < Length(AFields) do
          begin
            if Assigned(AFields[J]) then
            begin
              ASrcIdx := AFields[J].FieldNo - 1;
              if not ASrc.Values[ASrcIdx].OldValue.IsNull then
              begin
                ADestIdx := FieldDefs[J].FieldNo - 1;
                ARec.Values[ADestIdx].OldValue.TypeNeeded
                  (AFields[J].FValueType);
                ARec.Values[ADestIdx].OldValue.Copy
                  (ASrc.Values[ASrcIdx].OldValue, False);
              end;
            end;
            Inc(J);
          end;
          ARec.FOriginIndex := FOriginRecords.Add(ARec);
        end;
      usModified, usDeleted:
        begin
          J := 0;
          while J < Length(AFields) do
          begin
            if Assigned(AFields[J]) then
            begin
              ASrcIdx := AFields[J].FieldNo - 1;
              ADestIdx := FieldDefs[J].FieldNo - 1;
              ARec.Values[ADestIdx].Changed := ASrc.Values[ASrcIdx].Changed;
              if not ASrc.Values[ASrcIdx].OldValue.IsNull then
              begin
                ARec.Values[ADestIdx].OldValue.TypeNeeded
                  (AFields[J].FValueType);
                ARec.Values[ADestIdx].OldValue.Copy
                  (ASrc.Values[ASrcIdx].OldValue, False);
              end;
              if (ASrc.Values[ASrcIdx].Changed) and
                (not ASrc.Values[ASrcIdx].NewValue.IsNull) then
              begin
                ARec.Values[ADestIdx].NewValue.TypeNeeded
                  (AFields[J].FValueType);
                ARec.Values[ADestIdx].NewValue.Copy
                  (ASrc.Values[ASrcIdx].NewValue, False);
              end;
            end;
            Inc(J);
          end;
          if ARec.Status <> usDeleted then
            ARec.FOriginIndex := FOriginRecords.Add(ARec);
          ARec.FChangedIndex := FChangedRecords.Add(ARec);
        end;
      usInserted:
        begin
          J := 0;
          while J < Length(AFields) do
          begin
            if Assigned(AFields[J]) then
            begin
              ASrcIdx := AFields[J].FieldNo - 1;
              if not ASrc.Values[ASrcIdx].NewValue.IsNull then
              begin
                ADestIdx := FieldDefs[J].FieldNo - 1;
                ARec.Values[ADestIdx].NewValue.TypeNeeded
                  (AFields[J].FValueType);
                ARec.Values[ADestIdx].NewValue.Copy
                  (ASrc.Values[ASrcIdx].NewValue, False);
                ARec.Values[ADestIdx].Changed := True;
              end;
            end;
            Inc(J);
          end;
          ARec.FOriginIndex := FOriginRecords.Add(ARec);
          ARec.FChangedIndex := FChangedRecords.Add(ARec);
        end;
    end;
  end;
  procedure DoAppend;
  begin
    I := 0;
    while I < ASource.FOriginRecords.Count do
    begin
      ASrc := ASource.FOriginRecords[I];
      AddRecord;
      Inc(I);
    end;
  end;

  procedure DoMerge;
  var
    AHash: TQHashTable;
    AList: PQHashList;
    ADestFields: TQFieldDefArray;
    AValues1, AValues2: TBytes;
    AHashValue: TQHashType;
  begin
    AHash := TQHashTable.Create(FOriginRecords.Count + FChangedRecords.Count);
    try
      SetLength(ADestFields, Length(AFields));
      I := 0;
      while I < Length(AFields) do
      begin
        if Assigned(AFields[I]) then
          ADestFields[I] := FieldDefs[I] as TQFieldDef;
        Inc(I);
      end;
      // 计算已有记录的哈希值，以便插入时比较
      I := 0;
      while I < FOriginRecords.Count do
      begin
        ARec := FOriginRecords[I];
        AHash.Add(ARec, HashOfRecord(ARec, ADestFields));
        Inc(I);
      end;
      if ACheckDeleted then
      begin
        I := 0;
        while I < FOriginRecords.Count do
        begin
          ARec := FChangedRecords[I];
          if ARec.Status = usDeleted then
            AHash.Add(ARec, HashOfRecord(ARec, ADestFields));
          Inc(I);
        end;
      end;
      I := 0;
      while I < ASource.FOriginRecords.Count do
      begin
        ASrc := ASource.FOriginRecords[I];
        FlatFieldValues(ASrc, AFields, AValues1);
        AHashValue := HashOf(@AValues1[0], Length(AValues1));
        AList := AHash.Find(AHashValue);
        if Assigned(AList) then
        begin
          repeat
            FlatFieldValues(AList.Data, ADestFields, AValues2);
            if (Length(AValues1) = Length(AValues2)) and
              CompareMem(@AValues1[0], @AValues2[0], Length(AValues1)) then
              Break
            else
              AList := AList.Next;
          until AList = nil;
          if not Assigned(AList) then
          begin
            AddRecord;
            AHash.Add(ARec, AHashValue);
          end;
        end
        else
        begin
          AddRecord;
          AHash.Add(ARec, AHashValue);
        end;
        Inc(I);
      end;
    finally
      FreeObject(AHash);
    end;
  end;

begin
  CheckActive;
  ASource.CheckActive;
  if AType = dmmReplace then
  begin
    Empty;
    Merge(ASource, dmmAppend);
  end
  else
  begin
    Unlink; // 保证自身不是克隆的子数据集
    // 建立字段映射关系
    SetLength(AFields, FieldDefs.Count);
    for I := 0 to High(AFields) do
    begin
      AFields[I] := ASource.FieldDefs.Find(FieldDefs[I].Name) as TQFieldDef;
      if Assigned(AFields[I]) then
      begin
        if AFields[I].FValueType <> TQFieldDef(FieldDefs[I]).FValueType then
          DatabaseError(Format(SMergeFieldTypeMismatch, [FieldDefs[I].Name]));
      end;
    end;
    if Assigned(ASource.FCloneSource) then
      ASource := ASource.FCloneSource;
    if AType = dmmAppend then
      DoAppend
    else // Merge
      DoMerge;
  end;
  FRecordNo := RecNo - 1;
  Resync([]);
end;

procedure TQDataSet.MergeChanges;
var
  I: Integer;
  ADataSet: TQDataSet;
begin
  if Assigned(FCloneSource) then
    FCloneSource.MergeChanges
  else
  begin;
    for I := 0 to FChangedRecords.Count - 1 do
      MergeRecordChanges(FChangedRecords[I]);
    // 移除变更信息
    FChangedRecords.Clear();
    // 子对象重新克隆自己
    for I := 0 to FClones.Count - 1 do
    begin
      ADataSet := FClones[I];
      ADataSet.Clone(Self);
    end;
  end;
end;

procedure TQDataSet.MergeRecordChanges(ARec: TQRecord);
var
  J: Integer;
begin
  if ARec.Status in [usModified, usInserted] then
  begin
    for J := 0 to High(ARec.Values) do
    begin
      if ARec.Values[J].Changed then
      begin
        ARec.Values[J].OldValue.Copy(ARec.Values[J].NewValue, False);
        ARec.Values[J].NewValue.Reset;
        ARec.Values[J].Changed := False;
      end;
    end;
    ARec.FChangedIndex := -1;
    ARec.Status := usUnmodified;
  end;
end;

function TQDataSet.Min(AFieldName: QStringW): Variant;
var
  I: Integer;
  ADef: TQFieldDef;
  AVal: TQValue;
  ARec: TQRecord;
begin
  ADef := FieldDefs.Find(AFieldName) as TQFieldDef;
  if FActiveRecords.Count > 0 then
  begin
    ARec := RealRecord(FActiveRecords[0]);
    AVal.Copy(ARec.Values[ADef.FieldNo - 1].CurrentValue^, False);
    for I := 1 to FActiveRecords.Count - 1 do
    begin
      ARec := FActiveRecords[I];
      if ADef.ValueComparor(@AVal, ARec.Values[ADef.FieldNo - 1].CurrentValue) > 0
      then
        AVal.Copy(ARec.Values[ADef.FieldNo - 1].CurrentValue^, False);
    end;
    Result := AVal.AsVariant;
  end
  else
    VarClear(Result);
end;

function TQDataSet.Merge(const ACmdText: QStringW; AType: TQDataMergeMethod;
  AWaitDone: Boolean): Boolean;
begin
  // Todo:从Provider中取出数据集结果并合并到当前结果集中
  raise Exception.CreateFmt(SUnsupportFunction, ['Merge']);
end;

procedure TQDataSet.MoveTo(const AIndex: Cardinal);
begin
  RecNo := AIndex + 1;
end;

procedure TQDataSet.Notification(AComponent: TComponent; Operation: TOperation);
var
  I: Integer;
  J: Integer;
begin
  inherited;
  if Operation = opRemove then
  begin
    for I := 0 to High(FRecordsets) do
    begin
      if FRecordsets[I] = AComponent then
      begin
        FRecordsets[I] := nil;
        for J := I to High(FRecordsets) - 1 do
          FRecordsets[J] := FRecordsets[J + 1];
        SetLength(FRecordsets, Length(FRecordsets) - 1);
        if not(State in [dsInactive, dsOpening]) then
        begin
          if Length(FRecordsets) = 0 then // 没有子数据集了，关闭
            Close
          else if I = ActiveRecordset then // 移除的是当前活动的数据集
          begin
            FActiveRecordset := -1;
            ActiveRecordset := I;
          end;
        end;
        Break;
      end;
    end;
  end;
end;

function TQDataSet.ParseSort(const S: QStringW): PQSortExp;
var
  AExp, ANext: PQSortExp;
  AFieldName, ASortOrder: QStringW;
  p, n: PQCharW;
  AField: TQFieldDef;
const
  StrQuoter: QCharW = '"';
  StrSpace: PQCharW = ' '#9#10#13;
  StrDelimiter: PQCharW = ',;';
begin
  Result := nil;
  p := PQCharW(S);
  AExp := nil;
  while p^ <> #0 do
  begin
    ASortOrder := DecodeTokenW(p, StrDelimiter, StrQuoter, True);
    n := PQCharW(ASortOrder);
    AFieldName := DecodeTokenW(n, StrSpace, StrQuoter, True);
    SkipSpaceW(n);
    ASortOrder := n;
    AField := FieldDefs.Find(AFieldName) as TQFieldDef;
    if not Assigned(AField) then
    begin
      ClearSort(Result);
      DatabaseError(Format(SSortFieldNotFound, [AFieldName]));
    end;
    SkipSpaceW(p);
    New(ANext);
    if not Assigned(Result) then
      Result := ANext
    else
      AExp.Next := ANext;
    AExp := ANext;
    ANext.Field := AField;
    ANext.Next := nil;
    ANext.OnCompare := AField.FOnCompare;
    ANext.IgnoreCase := False;
    if p^ <> ',' then
    begin
      if Length(ASortOrder) > 0 then
      begin
        n := PWideChar(ASortOrder);
        if StrCmpW(n, 'DESC', True) = 0 then
          ANext.Desc := True
        else if StrCmpW(n, 'IDESC', True) = 0 then
        begin
          ANext.Desc := True;
          if ANext.Field.FValueType = vdtString then
          begin
            ANext.IgnoreCase := True;
            ANext.OnCompare := LookupCompareProc(vdtString, vdtString,
              True, False);
          end;
        end
        else if StrCmpW(n, 'NDESC', True) = 0 then
        begin
          ANext.Desc := True;
          if ANext.Field.FValueType = vdtString then
            ANext.OnCompare := LookupCompareProc(vdtString, vdtString,
              False, True);
        end
        else if StrCmpW(n, 'NIDESC', True) = 0 then
        begin
          ANext.Desc := True;
          if ANext.Field.FValueType = vdtString then
          begin
            ANext.IgnoreCase := True;
            ANext.OnCompare := LookupCompareProc(vdtString, vdtString,
              True, True);
          end;
        end
        else if StrCmpW(n, 'IASC', True) = 0 then
        begin
          ANext.Desc := False;
          if ANext.Field.FValueType = vdtString then
          begin
            ANext.IgnoreCase := True;
            ANext.OnCompare := LookupCompareProc(vdtString, vdtString,
              True, False);
          end;
        end
        else if StrCmpW(n, 'NASC', True) = 0 then
        begin
          ANext.Desc := False;
          if ANext.Field.FValueType = vdtString then
            ANext.OnCompare := LookupCompareProc(vdtString, vdtString,
              False, True);
        end
        else if StrCmpW(n, 'NIASC', True) = 0 then
        begin
          ANext.Desc := False;
          if ANext.Field.FValueType = vdtString then
          begin
            ANext.IgnoreCase := True;
            ANext.OnCompare := LookupCompareProc(vdtString, vdtString,
              True, True);
          end;
        end
        else if StrCmpW(n, 'ASC', True) <> 0 then
        begin
          ClearSort(Result);
          DatabaseError(Format(SSortKeywordUnknown, [ASortOrder]));
        end;
      end
      else
        ANext.Desc := False;;
    end
    else
      ANext.Desc := False;
  end;
end;

procedure TQDataSet.PrepareDiffCheck(ASource1, ASource2: TQDataSet;
  AFields: QStringW; var AHash1, AHash2: TQDiffCache);
var
  I, ACount: Integer;
  AToken, AFieldName: QStringW;
  p: PQCharW;
const
  ListDelimiters: PQCharW = ',;';
  NameValueSpliter: PWideChar = '=';
  procedure HashRecords(AList: TQRecords; const AFieldList: TQFieldDefArray;
    AHash: TQHashTable);
  var
    AValue: TQHashType;
  begin
    I := 0;
    while I < AList.Count do
    begin
      AValue := HashOfRecord(AList[I], AFieldList);
      AHash.Add(AList[I], AValue);
      // {$IFDEF MSWINDOWS}
      // if ASource1.FOriginRecords = AList then
      // OutputDebugString(PChar('Source1.' + IntToStr(I) + '.Hash=' +
      // IntToStr(AValue)))
      // else
      // OutputDebugString(PChar('Source2.' + IntToStr(I) + '.Hash=' +
      // IntToStr(AValue)));
      // {$ENDIF}
      Inc(I);
    end;
  end;

begin
  ASource1.CheckActive;
  ASource2.CheckActive;
  Close;
  ACount := ASource1.FieldDefs.Count;
  if ASource2.FieldDefs.Count > ACount then
    ACount := ASource2.FieldDefs.Count;
  SetLength(AHash1.Fields, ACount);
  SetLength(AHash2.Fields, ACount);
  p := PQCharW(AFields);
  I := 0;
  while p^ <> #0 do
  begin
    AToken := DecodeTokenW(p, ListDelimiters, QCharW(#0), True);
    AFieldName := DecodeTokenW(AToken, NameValueSpliter, QCharW('"'),
      True, True);
    if I > ACount then
    begin
      ACount := ACount shl 1;
      SetLength(AHash1.Fields, ACount);
      SetLength(AHash2.Fields, ACount);
    end;
    AHash1.Fields[I] := ASource1.FieldDefs.Find(AFieldName) as TQFieldDef;
    if AHash1.Fields[I] = nil then
      DatabaseError(Format(SFieldNotFound, [AFieldName]), ASource1);
    if Length(AToken) > 0 then
    begin
      AHash2.Fields[I] := ASource2.FieldDefs.Find(AToken) as TQFieldDef;
      if AHash2.Fields[I] = nil then
        DatabaseError(Format(SFieldNotFound, [AToken]), ASource2);
    end
    else
    begin
      AHash2.Fields[I] := ASource2.FieldDefs.Find(AFieldName) as TQFieldDef;
      if AHash2.Fields[I] = nil then
        DatabaseError(Format(SFieldNotFound, [AFieldName]), ASource2);
    end;
    if AHash1.Fields[I].FValueType <> AHash2.Fields[I].FValueType then
      DatabaseError(Format(SFieldTypeMissmatch, [AHash1.Fields[I].Name,
        AHash2.Fields[I].Name]));
    Inc(I);
  end;
  SetLength(AHash1.Fields, I);
  SetLength(AHash2.Fields, I);
  AHash1.HashTable := TQHashTable.Create(ASource1.FOriginRecords.Count);
  AHash2.HashTable := TQHashTable.Create(ASource2.FOriginRecords.Count);
  HashRecords(ASource1.FOriginRecords, AHash1.Fields, AHash1.HashTable);
  HashRecords(ASource2.FOriginRecords, AHash2.Fields, AHash2.HashTable);
  FieldDefs.BeginUpdate;
  try
    FieldDefs.Clear;
    for I := 0 to High(AHash1.Fields) do
      FieldDefs.AddFieldDef.Assign(AHash1.Fields[I]);
  finally
    FieldDefs.EndUpdate;
  end;
end;

procedure TQDataSet.QuickSort(ARecords: TQRecords; AExp: PQSortExp;
  L, R: Integer; ACompareProc: TQRecordCompareProc);
var
  I, J: Integer;
  pivot, temp: TQRecord;
begin
  if (ARecords.Count = 0) or ((R - L) <= 0) then
    Exit;
  repeat
    I := L;
    J := R;
    pivot := RealRecord(ARecords[L + (R - L) shr 1]);
    repeat
      while ACompareProc(AExp, RealRecord(ARecords[I]), pivot) < 0 do
        Inc(I);
      while ACompareProc(AExp, RealRecord(ARecords[J]), pivot) > 0 do
        Dec(J);
      if I <= J then
      begin
        if I <> J then
        begin
          temp := ARecords[I];
          ARecords[I] := ARecords[J];
          ARecords[J] := temp;
        end;
        Inc(I);
        Dec(J);
      end;
    until I > J;
    if L < J then
      QuickSort(ARecords, AExp, L, J, ACompareProc);
    L := I;
  until I >= R;
end;

function TQDataSet.RealRecord(ARec: TQRecord): TQRecord;
begin
  Result := ARec;
  while Result.Bookmark <> nil do
  begin
    if Result.Bookmark <> Result then
      Result := ARec.Bookmark
    else
      Break;
  end;
end;

procedure TQDataSet.RecreateDataSet;
begin
  Close;
  FRecordNo := -1;
  if Assigned(FProvider) and (FHandle <> 0) then
    FProvider.CloseHandle(FHandle);
  FHandle := 0;
  FLoadedRecordCount := 0;
  FProviderRecordCount := 0;
  FCloneSource := nil;
  FConverter := nil;
  FOpenBy := dsomByCreate;
  Active := True;
end;

procedure TQDataSet.RemoveDupFromHash(AHashs: TQHashTable;
  AOnFound: TQHashDupFoundEvent; AParam: Pointer);
var
  AList, ANext, ATemp: PQHashList;
  I: Integer;
  AFirstHash, ANextHash: PQRecordHash;
begin
  for I := 0 to AHashs.BucketCount do
  begin
    AList := AHashs[I];
    if AList <> nil then // 桶中不止一个元素，检查哈希值
    begin
      ANext := AHashs.FindNext(AList);
      if Assigned(ANext) then
      begin
        AFirstHash := AList.Data;
        if not AFirstHash.MD5Hashed then
        begin
          AFirstHash.MD5 := MD5Hash(@AFirstHash.FlatValues[0],
            Length(AFirstHash.FlatValues));
          AFirstHash.MD5Hashed := True;
        end;
        while ANext <> nil do
        begin
          ANextHash := ANext.Data;
          if not ANextHash.MD5Hashed then
          begin
            ANextHash.MD5 := MD5Hash(@ANextHash.FlatValues[0],
              Length(ANextHash.FlatValues));
            ANextHash.MD5Hashed := True;
          end;
          if MD5Equal(ANextHash.MD5, AFirstHash.MD5) then
          begin
            ATemp := AHashs.FindNext(ANext);
            if Assigned(AOnFound) then
              AOnFound(AHashs, ANextHash, AParam);
            Dispose(ANextHash);
            AHashs.Delete(ANext);
            ANext := ATemp;
          end
          else
            ANext := AHashs.FindNext(ANext);
        end;
      end;
    end;
  end;
end;

procedure TQDataSet.SaveToFile(const AFileName: QStringW;
  AConverter: TQConverter);
var
  AStream: TMemoryStream;
begin
  AStream := TMemoryStream.Create;
  try
    SaveToStream(AStream, AConverter);
    AStream.SaveToFile(AFileName);
  finally
    FreeObject(AStream);
  end;
end;

procedure TQDataSet.SaveToFile(const AFileName: QStringW;
  AConverterClass: TQConverterClass; AExports: TQExportRanges);
var
  AStream: TMemoryStream;
begin
  AStream := TMemoryStream.Create;
  try
    SaveToStream(AStream, AConverterClass, AExports);
    AStream.SaveToFile(AFileName);
  finally
    FreeObject(AStream);
  end;
end;

procedure TQDataSet.SaveToStream(AStream: TStream;
  AConverterClass: TQConverterClass; AExports: TQExportRanges);
var
  AConverter: TQConverter;
begin
  CheckActive;
  AConverter := AConverterClass.Create(nil);
  try
    AConverter.FExportRanges := AExports;
    SaveToStream(AStream, AConverter);
  finally
    FreeObject(AConverter);
  end;
end;

procedure TQDataSet.SaveToStream(AStream: TStream; AConverter: TQConverter);
var
  I: Integer;
  AList: TQRecords;
  AcceptStatus: TUpdateStatusSet;
  ARec: TQRecord;
  ADataExportNeeded: Boolean;
  procedure SaveDataSet(ADataSet: TQDataSet);
  var
    I: Integer;
  begin
    AConverter.BeginExport(AConverter.FActiveDataSet);
    if merMeta in AConverter.ExportRanges then
    begin
      AConverter.DoProgress(csSaveFields, 0, 0);
      AConverter.SaveFieldDefs(ADataSet.FieldDefs as TQFieldDefs);
    end;
    if ADataExportNeeded then
    begin
      if usUnmodified in AcceptStatus then
        // 需要导出未修改的数据
        AList := ADataSet.FOriginRecords
      else
        AList := ADataSet.FChangedRecords;
      AConverter.DoProgress(csSaveData, 0, AList.Count);
      I := 0;
      while I < AList.Count do
      begin
        ARec := RealRecord(AList[I]);
        if ARec.Status in AcceptStatus then
        begin
          AConverter.WriteRecord(ARec);
          AConverter.DoProgress(csSaveData, I, AList.Count);
        end;
        Inc(I);
      end;
      if (AList <> ADataSet.FChangedRecords) and (usDeleted in AcceptStatus)
      then
      begin
        I := 0;
        while I < ADataSet.FChangedRecords.Count do
        begin
          ARec := RealRecord(ADataSet.FChangedRecords[I]);
          if ARec.Status = usDeleted then
          begin
            AConverter.WriteRecord(ARec);
            AConverter.DoProgress(csSaveData, I,
              ADataSet.FChangedRecords.Count);
          end;
          Inc(I);
        end;
      end;
    end;
    AConverter.DoProgress(csAfterExport, 0, 0);
    AConverter.EndExport(AConverter.FActiveDataSet);
  end;

begin
  try
    AConverter.FStream := AStream;
    AConverter.DataSet := Self;
    if merUnmodified in AConverter.FExportRanges then // 需要导出未修改的数据
      AcceptStatus := [usUnmodified]
    else
      AcceptStatus := [];
    if merInserted in AConverter.FExportRanges then
      AcceptStatus := AcceptStatus + [usInserted];
    if merModified in AConverter.FExportRanges then
      AcceptStatus := AcceptStatus + [usModified];
    if merDeleted in AConverter.FExportRanges then
      AcceptStatus := AcceptStatus + [usDeleted];
    ADataExportNeeded := AConverter.FExportRanges <> [merMeta];
    AConverter.BeforeExport;
    if RecordsetCount > 0 then
    begin
      for I := 0 to High(FRecordsets) do
      begin
        AConverter.FActiveDataSet := I;
        SaveDataSet(FRecordsets[I]);
      end;
    end
    else
      SaveDataSet(Self);
  finally
    AConverter.AfterExport;
  end;
end;

procedure TQDataSet.SetActiveRecordset(const Value: Integer);
begin
  if FActiveRecordset <> Value then
  begin
    if (Value < 0) or (Value > High(FRecordsets)) then
      DatabaseError(Format(SOutOfRange, [Value]));
    FActiveRecordsetChanging := True;
    try
      FActiveRecordset := Value;
      if FRecordsets[Value] <> Self then
        Clone(FRecordsets[Value]);
    finally
      FActiveRecordsetChanging := False;
    end;
  end;
end;

procedure TQDataSet.SetAllowEditActions(const Value: TQDataSetEditActions);
begin
  if Value <> AllowEditActions then
    FAllowEditActions := Value;
end;

{$IFNDEF NEXTGEN}
{$IFNDEF UNICODE}

procedure TQDataSet.SetBookmarkData(Buffer: PChar; Data: Pointer);
begin
  TQRecord(Buffer).FBookmark := PPointer(Data)^;
end;

procedure TQDataSet.SetBookmarkFlag(Buffer: PChar; Value: TBookmarkFlag);
begin
  if Assigned(TQRecord(Buffer).Bookmark) then
    TQRecord(TQRecord(Buffer).Bookmark).FBookmarkFlag := Value
  else
    TQRecord(Buffer).FBookmarkFlag := Value;
end;
{$ENDIF}
{$IF RTLVersion>19}

procedure TQDataSet.SetBookmarkData(Buffer: TRecordBuffer; Data: Pointer);
begin
  TQRecord(Buffer).FBookmark := PPointer(Data)^;
end;
{$IFEND}
{$ENDIF}
{$IF RTLVersion>24}

procedure TQDataSet.SetBookmarkFlag(Buffer: TRecBuf; Value: TBookmarkFlag);
begin
  if Assigned(TQRecord(Buffer).Bookmark) then
    TQRecord(TQRecord(Buffer).Bookmark).FBookmarkFlag := Value
  else
    TQRecord(Buffer).FBookmarkFlag := Value;
end;
{$IFEND}
{$IFNDEF NEXTGEN}
{$IF RTLVersion>19}

procedure TQDataSet.SetBookmarkFlag(Buffer: TRecordBuffer;
  Value: TBookmarkFlag);
begin
  if Assigned(TQRecord(Buffer).Bookmark) then
    TQRecord(TQRecord(Buffer).Bookmark).FBookmarkFlag := Value
  else
    TQRecord(Buffer).FBookmarkFlag := Value;
end;

procedure TQDataSet.SetBookmarkData(Buffer: TRecordBuffer; Data: TBookmark);
begin
  TQRecord(Buffer).FBookmark := PPointer(@Data[0])^;
end;
{$IFEND}
{$ENDIF}
{$IF RTLVersion>24}

procedure TQDataSet.SetBookmarkData(Buffer: TRecBuf; Data: TBookmark);
begin
  TQRecord(Buffer).FBookmark := PPointer(@Data[0])^;
end;
{$IFEND}

procedure TQDataSet.SetCommandText(const Value: QStringW);
begin
  if FCommandText <> Value then
  begin
    if Active then
      Close;
    FCommandText := Value;
  end;
end;
{$IFNDEF NEXTGEN}

procedure TQDataSet.SetFieldData(Field: TField; Buffer: Pointer);
var
  pBuf: TQRecord;
begin
  if not(State in dsWriteModes) then
    DatabaseError(SDSNotInEdit, Self);
  pBuf := TQRecord(ActiveBuffer);
  if Assigned(pBuf) then
  begin
    if State = dsInsert then
      InternalSetFieldData(FEditingRow, Field, Buffer, False)
    else
      InternalSetFieldData(TQRecord(ActiveBuffer), Field, Buffer, False);
    if State = dsInsert then
      pBuf.FStatus := usInserted
    else if pBuf.Status <> usInserted then
      pBuf.FStatus := usModified;
    SetModified(True);
    if not(State in [dsCalcFields, dsInternalCalc, dsFilter, dsNewValue]) then
      DataEvent(deFieldChange, Longint(Field));
  end;
end;
{$ENDIF}
{$IFNDEF NEXTGEN}
{$IF RTLVersion>23}

procedure TQDataSet.SetFieldData(Field: TField; Buffer: TValueBuffer);
begin
  SetFieldData(Field, @Buffer[0]);
end;
{$IFEND}
{$ENDIF !NEXTGEN}

procedure TQDataSet.SetFieldValue(ARecord: PQRecord; AField: TField;
  const AValue: TQValue);
begin
  ARecord.Values[AField.FieldNo].NewValue.Copy(AValue, True);
end;

procedure TQDataSet.SetFiltered(Value: Boolean);
begin
  if Value <> Filtered then
  begin
    inherited;
    FilterRecords(True, True)
  end;
end;

procedure TQDataSet.SetFilterOptions(Value: TFilterOptions);
begin
  if FilterOptions <> Value then
  begin
    inherited;
    FilterRecords(True, Filtered);
  end;
end;

procedure TQDataSet.SetFilterText(const Value: string);
begin
  if Filter <> Value then
  begin
    if (Value <> '') and (MasterFields <> '') then
      DatabaseError(SNoDetailFilter, Self);
    inherited;
    if Assigned(FFilterExp) then
      FFilterExp.Clear;
    FilterRecords(True, Filtered);
  end;
end;

procedure TQDataSet.SetMasterFields(const Value: QStringW);
var
  p: PQCharW;
  AMasters, AMaster, ADetail: QStringW;
  I: Integer;
const
  APairDelimiter: PQCharW = ',;';
  AValueDelmiter: PWideChar = '=';
begin
  if (Value <> '') and (Filter <> '') then
    DatabaseError(SNoDetailFilter, Self);
  p := PQCharW(Value);
  I := 0;
  SetLength(FDetailFields, 16);
  while p^ <> #0 do
  begin
    ADetail := DecodeTokenW(p, APairDelimiter, NullChar, True);
    AMaster := DecodeTokenW(ADetail, AValueDelmiter, NullChar, True, True);
    if Length(ADetail) = 0 then
      FDetailFields[I] := AMaster
    else
      FDetailFields[I] := ADetail;
    Inc(I);
    if I > Length(FDetailFields) then
      SetLength(FDetailFields, I + 16);
    AMasters := AMasters + AMaster + ';';
  end;
  FMasterDetailFields := Value;
  FMasterLink.FieldNames := AMasters;
  SetLength(FDetailFields, I);
end;

procedure TQDataSet.SetMasterSource(const Value: TDataSource);
begin
  if IsLinkedTo(Value) then
    raise QException.Create(SCircularDataLink);
  FMasterLink.DataSource := Value;
end;

procedure TQDataSet.SetOnCustomSort(const Value: TQCustomSortEvent);
begin
  if (TMethod(FOnCustomSort).Data <> TMethod(Value).Data) or
    (TMethod(FOnCustomSort).Code <> TMethod(Value).Code) then
  begin
    FOnCustomSort := Value;
    if Active then
    begin
      CheckBrowseMode;
      if Assigned(Value) or Assigned(FSortExp) then
        DoSort(True)
      else
      begin
        ActiveRecordsChanged;
        Resync([]);
      end;
    end;
  end;
end;

procedure TQDataSet.SetPageIndex(const Value: Integer);
begin
  if Value >= 0 then
  begin
    if FPageIndex <> Value then
    begin
      if FPageSize <= 0 then
        FPageIndex := Value
      else if Value < PageCount then
        FPageIndex := Value
      else
        FPageIndex := PageCount - 1;
      FRecordNo := -1;
      Resync([]);
    end;
  end
  else if FPageIndex <> 0 then
  begin
    FPageIndex := 0;
    FRecordNo := -1;
    Resync([]);
  end;
end;

procedure TQDataSet.SetPageSize(const Value: Integer);
begin
  if Value > 0 then
  begin
    FPageSize := Value;
    if PageIndex > PageCount then
      PageIndex := PageCount - 1
    else
    begin
      FRecordNo := -1;
      DataEvent(deDataSetChange, 0);
      Resync([]);
    end;
  end
  else if FPageSize <> 0 then
  begin
    FRecordNo := -1;
    Resync([]);
    FPageSize := 0;
  end;
end;

procedure TQDataSet.SetProvider(const Value: TQProvider);
begin
  if FProvider <> Value then
  begin
    if FProvider <> nil then
    begin
      FetchAllRecords;
      FProvider.RemoveFreeNotification(Self);
      FProvider.CloseHandle(FHandle);
      FHandle := 0;
    end;
    FProvider := Value;
    if not Active then
      FOpenBy := dsomByProvider;
    if Assigned(FProvider) then
      FProvider.FreeNotification(Self);
  end;
end;

procedure TQDataSet.SetReadOnly(const Value: Boolean);
begin
  if FReadOnly <> Value then
  begin
    FReadOnly := Value;
    if Value and (not(csDesigning in ComponentState)) then
      CheckBrowseMode;
  end;
end;

procedure TQDataSet.SetRecNo(Value: Integer);
var
  ARecNo: Integer;
begin
  ARecNo := RecNo;
  if ARecNo <> Value then
  begin
    if ((Value > 0) and (Value <= RecordCount)) then
      MoveBy(Value - ARecNo);
  end;
end;

procedure TQDataSet.SetSort(const Value: QStringW);
begin
  if Value <> FSort then
  begin
    ClearSort(FSortExp);
    if Active then
      FSortExp := ParseSort(Value)
    else
      FSortExp := nil;
    FSort := Value;
    if Active then
    begin
      CheckBrowseMode;
      if (Length(FSort) > 0) and Assigned(FSortExp) then
        DoSort(True)
      else
      begin
        ActiveRecordsChanged;
        Resync([]);
      end;
    end;
  end;
end;

function TQDataSet.SortCompare(AExp: PQSortExp; ARec1, ARec2: TQRecord)
  : Integer;
var
  AVal1, AVal2: PQValue;
begin
  Result := 0;
  while Assigned(AExp) do
  begin
    AVal1 := ARec1.Values[AExp.Field.FieldNo - 1].CurrentValue;
    AVal2 := ARec2.Values[AExp.Field.FieldNo - 1].CurrentValue;
    if AVal1.IsNull then
    begin
      if AVal2.IsNull then
        Result := 0
      else
        Result := -1
    end
    else if AVal2.IsNull then
      Result := 1
    else
      Result := AExp.OnCompare(AVal1, AVal2);
    if Result <> 0 then
    begin
      if AExp.Desc then
        Result := -Result;
      Break;
    end;
    AExp := AExp.Next;
  end;
end;

function TQDataSet.Sum(AFieldName: QStringW): Variant;
var
  AField: TField;
  I, AFieldNo: Integer;
  ARec: TQRecord;
begin
  AField := FieldByName(AFieldName);
  AFieldNo := AField.FieldNo - 1;
  Result := 0;
  for I := 0 to FActiveRecords.Count - 1 do
  begin
    ARec := FActiveRecords[I];
    Result := Result + ARec.Values[AFieldNo].CurrentValue.AsVariant;
  end;
end;

procedure TQDataSet.Union(ASource: TQDataSet; AUnionAll: Boolean);
begin
  if AUnionAll then
    Merge(ASource, dmmAppend)
  else
    Merge(ASource, dmmMerge);
end;

procedure TQDataSet.Unlink;
var
  I: Integer;
  ARec: TQRecord;
begin
  if Assigned(FCloneSource) then
  begin
    FOriginRecords.Unlink;
    FChangedRecords.Clear;
    for I := 0 to FCloneSource.FChangedRecords.Count do
    begin
      ARec := FOriginRecords[TQRecord(FCloneSource.FChangedRecords[I])
        .FOriginIndex];
      ARec.FChangedIndex := FChangedRecords.Add(ARec);
    end;
    FChangedRecords.FFirstDirtyIndex := FChangedRecords.Count;
  end;
end;

function TQDataSet.UpdateStatus: TUpdateStatus;
var
  ARec: TQRecord;
begin
  if IsEmpty then
    Result := usUnmodified
  else
  begin
    ARec := ActiveRecordBuffer;
    while Assigned(ARec.Bookmark) do
      ARec := ARec.Bookmark;
    Result := ARec.Status;
  end;
end;

{ TQFilterExp }

function TQFilterExp.Accept(ARecord: TQRecord;
  AFilterOptions: TFilterOptions): Boolean;
  function DoCompare(AFieldVal, ACompareVal: PQValue; ACompare: TQValueCompare;
    ACompareOpr: TQFilterOperator): Boolean;
  begin
    Result := False;
    case ACompareOpr of
      foEQ:
        if AFieldVal.IsNull then
          Result := False
        else
          Result := (ACompare(AFieldVal, ACompareVal) = 0);
      foNotEQ:
        begin
          if AFieldVal.IsNull then
          begin
            if FDataSet.AnsiNulls then
              Result := False
            else
              Result := True
          end
          else
            Result := (ACompare(AFieldVal, ACompareVal) <> 0);
        end;
      foLT:
        begin
          if AFieldVal.IsNull then
          begin
            if FDataSet.AnsiNulls then
              Result := False
            else
              Result := True
          end
          else
            Result := (ACompare(AFieldVal, ACompareVal) < 0);
        end;
      foGT:
        begin
          if AFieldVal.IsNull then
            Result := False
          else
            Result := (ACompare(AFieldVal, ACompareVal) > 0);
        end;
      foLE:
        begin
          if AFieldVal.IsNull then
          begin
            if FDataSet.AnsiNulls then
              Result := False
            else
              Result := True
          end
          else
            Result := (ACompare(AFieldVal, ACompareVal) <= 0);
        end;
      foGE:
        begin
          if AFieldVal.IsNull then
            Result := False
          else
            Result := (ACompare(AFieldVal, ACompareVal) >= 0);
        end;
    end;
  end;

  function ValueString(const AValue: PQValue; AFormat: QStringW): QStringW;
  begin
    if Length(AFormat) > 0 then
    begin
      case AValue.ValueType of
        vdtDateTime:
          Result := FormatDateTime(AFormat, AValue.AsDateTime);
        vdtInteger, vdtInt64, vdtFloat, vdtCurrency:
          Result := FormatFloat(AFormat, AValue.AsFloat)
      else
        Result := AValue.AsString;
      end;
    end
    else
      Result := AValue.AsString;
  end;

  function LikeCompare(const AFieldVal: PQValue; AExp: TQFilterExp): Boolean;
  var
    S1, S2: QStringW;
  begin
    S2 := AExp.Value.AsString;
    S1 := ValueString(AFieldVal, AExp.FDisplayFormat);
    Result := StrLikeW(PQCharW(S1), PQCharW(S2),
      (foCaseInsensitive in AFilterOptions));
  end;
  function IsIn(const AFieldVal: PQValue; AExp: TQFilterExp): Boolean;
  var
    I: Integer;
  begin
    Result := False;
    for I := 0 to AExp.FValue.Value.Size - 1 do
    begin
      Result := DoCompare(AFieldVal, AExp.FValue.Items[I],
        AExp.FOnCompare, foEQ);
      if Result then
        Break;
    end;
  end;
  function DoFilter(AParent: TQFilterExp): Boolean; // 执行实际的过滤
  var
    AExp: TQFilterExp;
    I: Integer;
    AFieldVal: PQValue;
    ACol: TQColumnValue;
  begin
    Result := True;
    if AParent.Count > 0 then
    begin
      for I := 0 to AParent.Count - 1 do
      begin
        AExp := AParent.Items[I];
        Result := DoFilter(AExp);
        if Result then
        begin
          if AExp.NextOpr = fgoOr then
            Exit;
        end
        else if AExp.NextOpr = fgoAnd then
          Exit;
      end
    end
    else
    begin
      AExp := AParent;
      if Assigned(AExp.Field) then
      begin
        ACol := ARecord.Values[AExp.Field.FieldNo - 1];
        AFieldVal := ACol.CurrentValue;
        case AExp.CompareOpr of
          foLike, foStartWith, foEndWith, foContains:
            Result := LikeCompare(AFieldVal, AExp);
          foNotLike:
            Result := not LikeCompare(AFieldVal, AExp);
          foRegex:
            begin
              AExp.FLocker.Enter;
              try
                AExp.FRegex.Subject :=
                  RegexStr(ValueString(AFieldVal, AExp.FDisplayFormat));
                Result := AExp.FRegex.Match;
              finally
                AExp.FLocker.Leave;
              end;
            end;
          foIn:
            Result := IsIn(AFieldVal, AExp);
          foNotIn:
            Result := not IsIn(AFieldVal, AExp);
          foIsNull:
            Result := AFieldVal.IsNull;
          foIsNotNull:
            Result := not AFieldVal.IsNull
        else
          Result := DoCompare(AFieldVal, @AExp.Value, AExp.FOnCompare,
            AExp.CompareOpr);
        end;
      end
      else
        Result := False;
    end;
  end;

begin
  Result := DoFilter(Self);
end;

function TQFilterExp.Add: TQFilterExp;
begin
  Result := TQFilterExp.Create(FDataSet);
  Add(Result);
end;

function TQFilterExp.Add(AExp: TQFilterExp): Integer;
begin
  AExp.FParent := Self;
  Result := FItems.Add(AExp);
end;

procedure TQFilterExp.Clear;
var
  I: Integer;
begin
  for I := 0 to FItems.Count - 1 do
    FreeObject(FItems[I]);
  FItems.Clear;
end;

constructor TQFilterExp.Create(ADataSet: TQDataSet);
begin
  inherited Create;
  FItems := TQFilterExps.Create;
  FNextOpr := fgoDone;
  FDataSet := ADataSet;
end;

destructor TQFilterExp.Destroy;
begin
  Clear;
  FreeObject(FItems);
  if Assigned(FLocker) then
    FreeObject(FLocker);
  FValue.Reset;
  inherited;
end;

function TQFilterExp.GetCount: Integer;
begin
  Result := FItems.Count;
end;

function TQFilterExp.GetItems(AIndex: Integer): TQFilterExp;
begin
  Result := FItems[AIndex];
end;

procedure TQFilterExp.Parse(const S: QStringW;
  AIgnoreCase, ANaturalCompare: Boolean);
var
  p: PQCharW;
  AExp: TQFilterExp;
  AToken, AValue: QStringW;
  function ParseRegexOptions(var AToken: QStringW): TPerlRegExOptions;
  var
    S, E, T: PQCharW;
  begin
    Result := [];
    if Length(AToken) > 0 then
    begin
      S := PQCharW(AToken);
      if S^ = '/' then
      begin
        E := S + Length(AToken);
        Inc(S);
        while E > S do
        begin
          Dec(E);
          if E^ = '/' then
          begin
            T := E;
            Inc(T);
            while T^ <> #0 do
            begin
              case T^ of
                'i':
                  Result := Result + [preCaseLess];
                'm':
                  Result := Result + [preMultiLine];
                's':
                  Result := Result + [preSingleLine];
                'x':
                  Result := Result + [preExtended];
                'A':
                  Result := Result + [preAnchored];
                // 其它的皆忽略
              end;
              Inc(T);
            end;
            AToken := StrDupX(S, (IntPtr(E) - IntPtr(S)) shr 1);
            Break;
          end;
        end;
      end;
    end;
  end;
  procedure ParseExp(AParent: TQFilterExp);
  const
    TokenDelimiters: PWideChar = ' '#9#13#10;
    NameValueDelimiters: PWideChar = ' >=<*~'#9#13#10;
    ValueDelimiters: PWideChar = '"'''' )'#9#10#13;
    ValueListDelimiters: PWideChar = ';,'#9#10#13;
  var
    S: PQCharW;
    I, ACount: Cardinal;
    AQuoter: QCharW;
  begin
    while p^ <> #0 do
    begin
      case p^ of
        '(': // 嵌套解析开始
          begin
            Inc(p);
            SkipSpaceW(p);
            ParseExp(AParent.Add);
          end;
        ')': // 嵌套解析结束
          begin
            Inc(p);
            SkipSpaceW(p);
            Exit;
          end
      else
        begin
          AExp := AParent.Add;
          S := p;
          if (p^ = '''') or (p^ = '"') then
            AToken := DecodeTokenW(p, NameValueDelimiters, p^, True)
          else
            AToken := DecodeTokenW(p, NameValueDelimiters, QCharW(#0), True);
          AExp.FField := FDataSet.FieldDefs.Find(AToken) as TQFieldDef;
          if not Assigned(AExp.FField) then
            DatabaseError(Format(SFieldCantFilter, [AToken]));
          AExp.FOnCompare := qvalue.LookupCompareProc(AExp.Field.ValueType,
            AExp.Field.ValueType, AIgnoreCase, ANaturalCompare);
          while p > S do
          begin
            Dec(p);
            if not IsSpaceW(p) then
            begin
              while (p > S) and CharInW(p, NameValueDelimiters) do
                Dec(p);
              Inc(p);
              Break;
            end;
          end;
          SkipSpaceW(p);
          // 比较操作符
          if p^ = '>' then
          begin
            Inc(p);
            if p^ = '=' then
            begin
              AExp.FCompareOpr := foGE;
              Inc(p);
            end
            else
              AExp.FCompareOpr := foGT;
          end
          else if p^ = '<' then
          begin
            Inc(p);
            if p^ = '=' then
            begin
              AExp.FCompareOpr := foLE;
              Inc(p);
            end
            else if p^ = '>' then
            begin
              AExp.FCompareOpr := foNotEQ;
              Inc(p);
            end
            else
              AExp.FCompareOpr := foLT;
          end
          else if p^ = '=' then
          begin
            AExp.FCompareOpr := foEQ;
            Inc(p);
          end
          else if p^ = '!' then
          begin
            Inc(p);
            if p^ = '=' then // !=
              AExp.FCompareOpr := foNotEQ
            else if p^ = '*' then
              AExp.FCompareOpr := foNotLike
            else
            begin
              Dec(p);
              DatabaseError(Format(SUnknownFilterOperator, [StrDupX(p, 2)]));
            end;
            Inc(p);
          end
          else if (p^ = '*') then
          begin
            AExp.FCompareOpr := foLike;
            Inc(p);
          end
          else if p^ = '~' then // 正则
          begin
            AExp.CompareOpr := foRegex;
            Inc(p);
          end
          else if StrNCmpW(p, 'like', True, 4) = 0 then
          begin
            AExp.FCompareOpr := foLike;
            Inc(p, 4);
          end
          else if StrNCmpW(p, 'nlike', True, 5) = 0 then
          begin
            AExp.FCompareOpr := foNotLike;
            Inc(p, 5);
          end
          else if StrNCmpW(p, 'in', True, 2) = 0 then
          begin
            AExp.FCompareOpr := foIn;
            Inc(p, 2);
          end
          else if StrNCmpW(p, 'notin', True, 5) = 0 then
          begin
            AExp.FCompareOpr := foNotIn;
            Inc(p, 5);
          end
          else if StrNCmpW(p, 'is', True, 2) = 0 then
          begin
            Inc(p, 2);
            S := p;
            SkipSpaceW(p);
            if StrNCmpW(p, 'not', True, 3) = 0 then // IsNot
            begin
              Inc(p, 3);
              if IsSpaceW(p) then
              begin
                SkipSpaceW(p);
                if StrNCmpW(p, 'null', True, 4) = 0 then
                begin
                  Inc(p, 4);
                  if IsSpaceW(p) or (p^ = #0) or (p^ = ')') then
                    AExp.FCompareOpr := foIsNotNull
                  else
                    DatabaseError(Format(SFilterExpUnknown, [StrDupX(S, 30)]));
                end
                else
                  DatabaseError(Format(SFilterExpUnknown, [StrDupX(S, 30)]));
              end
              else
              begin
                Dec(p);
                DatabaseError(Format(SUnknownFilterOperator, [StrDupX(p, 30)]));
              end;
            end
            else
            begin
              if IsSpaceW(S) then
              begin
                if StrNCmpW(p, 'null', True, 4) = 0 then
                begin
                  Inc(p, 4);
                  if IsSpaceW(p) or (p^ = #0) or (p^ = ')') then
                    AExp.FCompareOpr := foIsNull
                  else
                    DatabaseError(Format(SFilterExpUnknown, [StrDupX(S, 30)]));
                end
                else
                  DatabaseError(Format(SFilterExpUnknown, [StrDupX(S, 30)]));
              end;
            end;
          end
          else
            DatabaseError(Format(SUnknownFilterOperator,
              [DecodeTokenW(p, ValueDelimiters, QCharW(#0), True)]));
          // 解析值
          SkipSpaceW(p);
          if AExp.CompareOpr in [foIn, foNotIn] then // In 操作
          begin
            if (p^ = '(') then // 解析值列表
            begin
              Inc(p);
              S := p;
              ACount := 1;
              while p^ <> #0 do
              begin
                if (p^ = ')') or (p^ = ']') then
                begin
                  Dec(ACount);
                  if ACount = 0 then
                    Break;
                end
                else if (p^ = '(') or (p^ = '[') then
                  Inc(ACount);
                Inc(p);
              end;
              if (p^ <> ')') then
                DatabaseError(Format(SRightBracketNeeded, [StrDupX(p, 30)]));
              AValue := StrDupX(S, (IntPtr(p) - IntPtr(S)) shr 1);
              Inc(p);
              S := PQCharW(AValue);
              SkipSpaceW(S);
              I := 0;
              AExp.FValue.ArrayNeeded(64);
              while S^ <> #0 do
              begin
                if (S^ = '"') or (S^ = '''') then
                begin
                  AQuoter := S^;
                  AToken := DequotedStrW(DecodeTokenW(S, ValueListDelimiters,
                    S^, True), AQuoter)
                end
                else
                  AToken := DecodeTokenW(S, ValueListDelimiters,
                    QCharW(#0), True);
                AExp.FValue.Items[I].TypeNeeded(AExp.Field.FValueType);
                AExp.FValue.Items[I].AsString := AToken;
                Inc(I);
                SkipSpaceW(S);
                if I = AExp.FValue.Value.Size then
                  AExp.FValue.ArrayNeeded(I shl 1);
              end;
              AExp.FValue.ArrayNeeded(I);
            end
            else
              DatabaseError(Format(SInExpNeedBracket, [StrDupX(p, 30)]));
          end
          else if not(AExp.CompareOpr in [foIsNull, foIsNotNull]) then
          begin
            if (p^ = '''') or (p^ = '"') then
            begin
              AQuoter := p^;
              AToken := DequotedStrW(DecodeTokenW(p, ValueDelimiters, p^, True,
                False), AQuoter);
            end
            else
            begin
              AQuoter := #0;
              AToken := DecodeTokenW(p, ValueDelimiters, QCharW(#0),
                True, False);
              if AExp.FCompareOpr in [foEQ, foNotEQ] then
              begin
                if StrCmpW(PQCharW(AToken), 'null', True) = 0 then
                begin
                  if AExp.FCompareOpr = foEQ then
                    AExp.FCompareOpr := foIsNull
                  else
                    AExp.FCompareOpr := foIsNotNull;
                end;
              end;
            end;
            if AExp.CompareOpr in [foLike, foNotLike, foRegex] then
            begin
              AExp.FValue.TypeNeeded(vdtString);
              AExp.FValue.Value.AsString^ := AToken;
              if AExp.CompareOpr = foRegex then
              begin
                AExp.FRegex := TPerlRegEx.Create;
                AExp.FRegex.Options := ParseRegexOptions(AToken);
                AExp.FRegex.RegEx := RegexStr(AToken);
                try
                  if foCaseInsensitive in FDataSet.FilterOptions then
                    AExp.FRegex.Options := AExp.FRegex.Options + [preCaseLess];
                  AExp.FRegex.Compile;
                except
                  on E: Exception do
                  begin
                    FreeAndNil(AExp.FRegex);
                    DatabaseError(Format(SRegexBadExpression,
                      [AToken, E.Message]));
                  end;
                end;
              end;
            end
            else
            begin
              if (AQuoter = #0) and (StrCmpW(PQCharW(AToken), 'null', True) = 0)
              then // =null?
              begin
                if AExp.FCompareOpr = foEQ then
                  AExp.FCompareOpr := foIsNull
                else if AExp.FCompareOpr = foNotEQ then
                  AExp.FCompareOpr := foIsNotNull
                else
                  DatabaseError(SUnsupportNullCompare);
              end
              else
              begin
                AExp.FValue.TypeNeeded(AExp.Field.FValueType);
                AExp.FValue.AsString := AToken;
              end;
            end;
          end;
          if foCaseInsensitive in FDataSet.FilterOptions then
          begin
            if (AExp.FValue.ValueType = vdtString) or
              (AExp.CompareOpr in [foLike, foNotLike, foStartWith, foEndWith,
              foContains, foIn, foNotIn]) then
              AExp.FOnCompare := LookupCompareProc(AExp.Field.FValueType,
                vdtString, True, FDataSet.NaturalFilter);
          end;
        end;
      end;
      if (p^ <> #0) and (p^ <> ')') then
      begin
        // 解析表达式间的逻辑关系
        AToken := DecodeTokenW(p, TokenDelimiters, QCharW(#0), True);
        if Length(AToken) > 0 then
        begin
          S := PQCharW(AToken);
          if StrNCmpW(S, 'and', True, 3) = 0 then
            AExp.NextOpr := fgoAnd
          else if StrNCmpW(S, 'or', True, 2) = 0 then
            AExp.NextOpr := fgoOr
          else if S^ = ')' then
          begin
            AExp.NextOpr := fgoDone;
            Exit;
          end
          else
            DatabaseError(Format(SFilterLogisticError, [AToken]));
        end
        else
        begin
          AExp.NextOpr := fgoDone;
          Exit;
        end;
      end;
    end;
  end;

begin
  Clear;
  p := PQCharW(S);
  ParseExp(Self);
  if p^ <> #0 then
    DatabaseError(Format(SFilterExpUnknown, [Copy(p, 0, MaxInt)]));
end;

procedure TQFilterExp.SetCompareOpr(const Value: TQFilterOperator);
begin
  if FCompareOpr <> Value then
  begin
    FCompareOpr := Value;
    if (Value = foRegex) and (not Assigned(FLocker)) then
      FLocker := TCriticalSection.Create;
  end;
end;

{ TQLocalChecks }

function TQLocalChecks.Accept(ABuf: TQRecord): Boolean;
begin
  Result := True;
end;

procedure TQLocalChecks.Check(ABuf: TQRecord);
begin

end;

{ TQProvider }

class function TQProvider.AcquireDataSet: TQDataSet;
begin
  if Assigned(QDataSetPool) then
  begin
    Result := QDataSetPool.Pop;
    while Result.ControlsDisabled do
      Result.EnableControls;
  end
  else
    Result := TQDataSet.Create(nil);
end;

procedure TQProvider.ApplyChanges(ADataSet: TQDataSet);
begin
  ADataSet.CheckBrowseMode;
  InternalApplyChanges(ADataSet.FieldDefs, ADataSet.FChangedRecords);
  ADataSet.MergeChanges;
end;

procedure TQProvider.ApplyChanges(AStream: TStream; AFormat: TQConverterClass);
var
  AConverter: TQConverter;
begin
  AConverter := AFormat.Create(nil);
  try
    ApplyChanges(AStream, AConverter);
  finally
    FreeAndNil(AConverter);
  end;
end;

procedure TQProvider.AddResultSet;
var
  ADataSet, ANewDataSet: TQDataSet;
  ALastIndex: Integer;
begin
  SetLength(FResultSets, Length(FResultSets) + 1);
  if FActiveRequest.Command.Action = caFetchRecords then
  begin
    ADataSet := TQDataSet(FActiveRequest.Command.DataObject);
    if (Length(ADataSet.FRecordsets) = 0) and (ADataSet.FieldDefs.Count > 0)
    then
    begin
      // 返回了多个结果集，所以需要将当前的结果集的内容移动为第一个
      SetLength(ADataSet.FRecordsets, 2);
      ANewDataSet := AcquireDataSet;
      ADataSet.FRecordsets[0] := ANewDataSet;
      ANewDataSet.FieldDefs.Assign(ADataSet.FieldDefs);
      ANewDataSet.FOriginRecords.Assign(ADataSet.FOriginRecords);
      ANewDataSet.Provider := Self;
      FActiveFieldDefs := ANewDataSet.FieldDefs as TQFieldDefs;
      ANewDataSet.Open;
      ADataSet.FOriginRecords.Clear();
      ADataSet.FieldDefs.Clear;
      FResultSets[0].FieldDefs := ANewDataSet.FieldDefs as TQFieldDefs;
      FResultSets[0].Records := ANewDataSet.FOriginRecords;
    end
    else
      SetLength(ADataSet.FRecordsets, Length(ADataSet.FRecordsets) + 1);
    ANewDataSet := AcquireDataSet;
    ALastIndex := High(ADataSet.FRecordsets);
    ADataSet.FRecordsets[ALastIndex] := ANewDataSet;
    FResultSets[ALastIndex].FieldDefs := ANewDataSet.FieldDefs as TQFieldDefs;
    FResultSets[ALastIndex].Records := ANewDataSet.FOriginRecords;
    FActiveFieldDefs := ANewDataSet.FieldDefs as TQFieldDefs;
    FActiveRecords := ANewDataSet.FOriginRecords;
    SetFetching(ANewDataSet);
  end
  else
  begin
    FActiveFieldDefs := CreateDefaultDefs;
    FResultSets[High(FResultSets)].FieldDefs := FActiveFieldDefs;
    FActiveRecords := TQRecords.Create(ditOrigin);
    FResultSets[High(FResultSets)].Records := FActiveRecords;
  end;
end;

procedure TQProvider.AddResultField(const AFieldName: QStringW;
  ACol: TQSColumn);
var
  ADef: TQFieldDef;
  ASchema: TQSchema;
begin
  ADef := FResultSets[FActiveResultset].FieldDefs.AddFieldDef as TQFieldDef;
  if Assigned(ACol.Table) and (ACol.Table.Id <> 0) then
  begin
    ASchema := ACol.Table.Database;
    if ASchema <> nil then
      ADef.FDatabase := ASchema.Name;
    ASchema := ACol.Table.Schema;
    if Assigned(ASchema) then
      ADef.FSchema := ASchema.Name;
    if Length(ACol.Table.Name) = 0 then
      ADef.FTable := IntToStr(ACol.Table.Id)
    else
      ADef.FTable := ACol.Table.Name;
    ADef.FBaseName := ACol.Name;
  end
  else
    ADef.InternalCalcField := True;
  ADef.Name := AFieldName;
  ADef.DBType := ACol.DBType.SQLType;
  ADef.DBNo := ACol.Id;
  if (ADef.DBType and SQL_MASK_FIXEDSIZE) = 0 then
    ADef.Size := ACol.Size;
  ADef.IsPrimary := ACol.IsPrimary;
  ADef.IsIndex := ACol.IsIndex;
  ADef.IsUnique := ACol.IsUnique;
  ADef.IsAutoInc := ACol.IsAutoInc;
  ADef.IsCalc := ACol.IsCalc;
  ADef.IsArray := ACol.IsArray;
  ADef.IsFixed := ACol.IsFixed;
  if (ADef.DBType and SQL_MASK_FLOAT) <> 0 then
  begin
    ADef.Scale := ACol.Scale;
    ADef.Precision := ACol.Precision;
  end;
end;

procedure TQProvider.AddResultRecord(var ARecord: TQRecord);
begin
  FActiveRecords.Add(ARecord);
  ARecord.Release;
end;

function TQProvider.AllocRecord: TQRecord;
begin
  Result := TQRecord.Create(FActiveFieldDefs);
end;

procedure TQProvider.ApplyChanges(AFileName: QStringW; AConverter: TQConverter);
var
  AStream: TMemoryStream;
begin
  AStream := TMemoryStream.Create;
  try
    AStream.LoadFromFile(AFileName);
    ApplyChanges(AStream, AConverter);
  finally
    FreeAndNil(AStream);
  end;
end;

procedure TQProvider.ApplyChanges(AStream: TStream; AConverter: TQConverter);
var
  ARecords: TQRecords;
  ARec: TQRecord;
  I: Integer;
  ADataSet: TQDataSet;
begin
  AConverter.FDataSet := nil;
  AConverter.FStream := AStream;
  AConverter.BeforeImport;
  ADataSet := AcquireDataSet; // 只是临时借来用的
  ARecords := TQRecords.Create(ditChanged);
  try
    I := 0;
    while I < AConverter.DataSetCount do
    begin
      ADataSet.FieldDefs.Clear;
      AConverter.LoadFieldDefs(ADataSet.FieldDefs as TQFieldDefs);
      ARec := ADataSet.AllocRecord;
      while AConverter.ReadRecord(ARec) do
      begin
        if ARec.Status <> usDeleted then
          ARec.FChangedIndex := ADataSet.FChangedRecords.Add(ARec);
        ARec := ADataSet.AllocRecord;
      end;
      ADataSet.FreeRecord(ARec);
      InternalApplyChanges(ADataSet.FieldDefs, ADataSet.FChangedRecords);
      ADataSet.FChangedRecords.Clear(False);
      Inc(I);
    end;
  finally
    FreeAndNil(ARecords);
    ADataSet.FieldDefs.Clear;
    ADataSet.FChangedRecords.Clear();
    ReleaseDataSet(ADataSet);
    AConverter.AfterImport;
  end;
end;

procedure TQProvider.ApplyChanges(AFileName: QStringW;
  AFormat: TQConverterClass);
var
  AStream: TMemoryStream;
begin
  AStream := TMemoryStream.Create;
  try
    AStream.LoadFromFile(AFileName);
    ApplyChanges(AStream, AFormat);
  finally
    FreeAndNil(AStream);
  end;
end;

procedure TQProvider.BeforeDestruction;
begin
  inherited;

end;

function TQProvider.BeginTrans(ALevel: TQDBIsolationLevel;
  ASavePointName: QStringW): Boolean;
begin
  Result := True;
  Inc(FTransactionLevel);
end;

procedure TQProvider.Close;
var
  I: Integer;
  ADataSet: TQDataSet;
begin
  if Connected then
  begin
    SetFlags(PF_CLOSING, True);
    try
      DisablePeek;
      // 强制将未全部加载记录的数据集加载完全
      for I := 0 to FDataSets.Count - 1 do
      begin
        ADataSet := FDataSets[I];
        if ADataSet.Active then
        begin
          ADataSet.FetchAllRecords;
          ADataSet.FHandle := 0;
        end;
      end;
      FDataSets.Clear;
      InternalClose;
    finally
      SetFlags(PF_CLOSING, False);
      SetFlags(PF_CONNECTED, False);
    end;
  end;
end;

function TQProvider.ColumnExists(ATableName, AColName: QStringW): Boolean;
var
  ASchema, ACmdText: QStringW;
begin
  ASchema := ParseNameToken(ATableName);
  if Length(ASchema) > 0 then
    ACmdText := 'select * from information_schema.columns where table_schema=' +
      QuotedStrW(ASchema, '''') + ' and table_name=' + QuotedStrW(ATableName,
      '''') + ' and column_name=' + QuotedStrW(AColName, '''') + ';'
  else
    ACmdText := 'select * from information_schema.columns where table_name=' +
      QuotedStrW(ATableName, '''') + ' and column_name=' +
      QuotedStrW(AColName, '''') + ';';
  Result := RecordExists(ACmdText);
end;

procedure TQProvider.CommitTrans;
begin
  Dec(FTransactionLevel);
end;

procedure TQProvider.ConnectionAborted;
begin
  DisablePeek;
  SetFlags(PF_CONNECTED, False);
end;

constructor TQProvider.Create(AOwner: TComponent);
begin
  inherited;
  FParams := TStringList.Create;
  FParams.Delimiter := ';';
  FDataSets := TQDataSetList.Create; // 关联的数据集对象
  FCommandTimeout := 30;
  FPeekInterval := 30;
  FDefaultDataSet := TQDataSet.Create(Self);
end;

function TQProvider.CreateDefaultDefs: TQFieldDefs;
begin
  Result := TQFieldDefs.Create(FDefaultDataSet);
end;

destructor TQProvider.Destroy;
var
  I: Integer;
begin
  Close;
  FreeObject(FParams);
  for I := FDataSets.Count - 1 downto 0 do
  begin
    if TQDataSet(FDataSets[I]).Owner = nil then
      FreeObject(FDataSets[I]);
  end;
  FreeObject(FDataSets);
  inherited;
end;

procedure TQProvider.DisablePeek;
begin
  if FPeekJobHandle <> 0 then
  begin
    Workers.ClearSingleJob(FPeekJobHandle,false);
    FPeekJobHandle := 0;
  end;
end;

procedure TQProvider.DoLivePeek(AJob: PQJob);
begin
  if FFlags = (PF_CONNECTED or PF_KEEPALIVE) then
  begin
    SetFlags(PF_PEEKING, True);
    KeepAliveNeeded;
    SetFlags(PF_PEEKING, False);
    FPeekJobHandle := 0;
    FireKeepAlive;
  end;
end;

procedure TQProvider.DoParamChanged;
begin
  if Assigned(FOnParamChanged) then
    FOnParamChanged(Self);
end;

procedure TQProvider.EnablePeek;
begin
  FireKeepAlive;
end;

function TQProvider.Execute(var ARequest: TQSQLRequest): Boolean;
var
  ADataSet: TQDataSet;
  I, ALastActiveResultset: Integer;
  ALastRequest: PQSQLRequest;
  ALastActiveFieldDefs: TQFieldDefs;
  FLastActiveRecords: TQRecords;
  ALastResultSets: TQResultSets;
  procedure DoOpenDataSet;
  begin
    ADataSet.Provider := Self;
    if Length(FResultSets) = 1 then
    begin
      if ADataSet.FieldDefs.Count = 0 then
      begin
        ARequest.Result.ErrorCode := PROV_EEROR_RESULT_EMPTY;
        ARequest.Result.ErrorMsg := SSQLNoReturnRecords;
        Exit;
      end;
      ADataSet.Open;
    end
    else
    begin
      I := 0;
      while I < Length(FResultSets) do
      begin
        FResultSets[I].FieldDefs := nil;
        FResultSets[I].Records := nil;
        Inc(I);
      end;
      ADataSet.ActiveRecordset := 0;
    end;
  end;

  procedure DoExportStream;
  var
    AConverter: TQConverter;
    J: Integer;
  begin
    AConverter := ARequest.Command.DataObject;
    AConverter.FDataSetCount := Length(FResultSets);
    I := 0;
    AConverter.BeforeExport;
    try
      while I < Length(FResultSets) do
      begin
        AConverter.FActiveDataSet := I;
        AConverter.BeginExport(I);
        if merMeta in AConverter.ExportRanges then
          AConverter.SaveFieldDefs(FResultSets[I].FieldDefs);
        if merUnmodified in AConverter.ExportRanges then
        begin
          for J := 0 to FResultSets[I].Records.Count - 1 do
          begin
            if not AConverter.WriteRecord(FResultSets[I].Records[J]) then
              Exit
          end;
        end;
        AConverter.EndExport(I);
        FreeAndNil(FResultSets[I].FieldDefs);
        FreeAndNil(FResultSets[I].Records);
        Inc(I);
      end;
    finally
      AConverter.AfterExport;
    end;
  end;
  procedure EmptyResultSets;
  begin
    I := 0;
    while I < High(FResultSets) do
    begin
      if FResultSets[I].FieldDefs <> nil then
        FreeAndNil(FResultSets[I].FieldDefs);
      if FResultSets[I].Records <> nil then
        FreeAndNil(FResultSets[I].Records);
      Inc(I);
    end;
    SetLength(FResultSets, 0);
  end;

begin
  ALastRequest := FActiveRequest;
  ALastActiveResultset := FActiveResultset;
  FActiveRequest := @ARequest;
  ALastActiveFieldDefs := FActiveFieldDefs;
  FLastActiveRecords := FActiveRecords;
  ALastResultSets := Copy(FResultSets, 0, Length(FResultSets));
  if Assigned(FBeforeExecute) then
    FBeforeExecute(Self, ARequest.Command);
  DisablePeek;
  ADataSet := nil;
  FActiveResultset := 0;
  case ARequest.Command.Action of
    caPrepare:
      begin
        if ARequest.Command.FieldDefs = nil then
          ARequest.Command.FieldDefs := CreateDefaultDefs;
        FActiveFieldDefs := ARequest.Command.FieldDefs;
        FActiveRecords := nil;
      end;
    caFetchStream:
      begin
        SetLength(FResultSets, 1);
        FActiveFieldDefs := CreateDefaultDefs;
        FActiveRecords := TQRecords.Create(ditOrigin);
        FResultSets[0].FieldDefs := FActiveFieldDefs;
        FResultSets[0].Records := FActiveRecords;
      end;
    caFetchRecords:
      begin
        ADataSet := ARequest.Command.DataObject;
        ADataSet.Close;
        ADataSet.DisableControls;
        ADataSet.CommandText := ARequest.Command.SQL;
        SetLength(FResultSets, 1);
        FActiveFieldDefs := ADataSet.FieldDefs as TQFieldDefs;
        FResultSets[0].FieldDefs := FActiveFieldDefs;
        FActiveRecords := ADataSet.FOriginRecords;
        FResultSets[0].Records := FActiveRecords;
      end
  end;
  try
    ARequest.Result.Statics.AffectRows := 0;
    ARequest.Result.Statics.ExecuteStartTime := GetTimeStamp;
    repeat
      Result := InternalExecute(ARequest);
    until Result or Connected;
    ARequest.Result.Statics.ExecuteDoneTime := GetTimeStamp;
    if ARequest.Result.ErrorCode = 0 then
    begin
      if (ARequest.Command.Action = caFetchRecords) then
        DoOpenDataSet
      else if ARequest.Command.Action = caFetchStream then
        DoExportStream;
    end
    else
      SetError(ARequest.Result.ErrorCode, ARequest.Result.ErrorMsg);
  finally
    if ARequest.Command.Action = caFetchRecords then
      ADataSet.EnableControls;
    EmptyResultSets;
    FActiveRequest := ALastRequest;
    FActiveResultset := ALastActiveResultset;
    FActiveFieldDefs := ALastActiveFieldDefs;
    FActiveRecords := FLastActiveRecords;
    FResultSets := ALastResultSets;
    if Assigned(FAfterExecute) then
      FAfterExecute(Self, ARequest.Command, ARequest.Result);
    ARequest.Result.Statics.StopTime := GetTimeStamp;
    EnablePeek;
    Result := ARequest.Result.ErrorCode = 0;
  end;
end;

function TQProvider.ExecuteCmd(ACmdText: QStringW;
  const AParams: array of const): Integer;
begin
  ACmdText := Format(ACmdText, AParams);
  Result := ExecuteCmd(ACmdText);
end;

function TQProvider.ExecuteCmd(var APrepared: TQCommand;
  const AParams: array of const): Integer;
var
  ARequest: TQSQLRequest;
begin
  Result := -1;
  if not APrepared.Prepared then
  begin
    if not Prepare(APrepared, APrepared.SQL, APrepared.Id) then
      Exit;
  end;
  ARequest.Command := APrepared;
  ARequest.Command.Action := caExecute;
  ParamValues(ARequest.Command, AParams);
  ARequest.WaitResult := True;
  ARequest.AfterOpen := nil;
  ARequest.Result.ErrorCode := 0;
  FillChar(ARequest.Result.Statics, SizeOf(TQExecuteStatics), 0);
  ARequest.Result.Statics.QueuedTime := GetTimeStamp;
  if Execute(ARequest) then
  begin
    Result := ARequest.Result.Statics.AffectRows;
  end
  else
  begin
    SetError(ARequest.Result.ErrorCode, ARequest.Result.ErrorMsg);
  end;
end;

function TQProvider.ExecuteCmd(ACmdText: QStringW): Integer;
var
  ARequest: TQSQLRequest;
begin
  ARequest.Command.DataObject := nil;
  ARequest.Command.SQL := ACmdText;
  ARequest.Command.Prepared := False;
  ARequest.Command.PreparedData := nil;
  ARequest.Command.FieldDefs := nil;
  ARequest.Command.Action := caExecute;
  ARequest.WaitResult := True;
  ARequest.AfterOpen := nil;
  ARequest.Result.ErrorCode := 0;
  FillChar(ARequest.Result.Statics, SizeOf(TQExecuteStatics), 0);
  ARequest.Result.Statics.QueuedTime := GetTimeStamp;
  if Execute(ARequest) then
  begin
    Result := ARequest.Result.Statics.AffectRows;
  end
  else
  begin
    Result := -1;
    SetError(ARequest.Result.ErrorCode, ARequest.Result.ErrorMsg);
  end;
end;

procedure TQProvider.FireKeepAlive;
begin
  if KeepAlive and (PeekInterval > 0) and (not Closing) then
  begin
    if FPeekJobHandle <> 0 then
      Workers.ClearSingleJob(FPeekJobHandle);
    FPeekJobHandle := Workers.Delay(DoLivePeek, FPeekInterval * Q1Second,
      nil, True);
  end
  else if FPeekJobHandle <> 0 then
  begin
    Workers.ClearSingleJob(FPeekJobHandle);
    FPeekJobHandle := 0;
  end;
end;

procedure TQProvider.FreeCommand(var ACmd: TQCommand);
begin
  if ACmd.Prepared then
    Unprepare(ACmd);
  if Assigned(ACmd.FieldDefs) then
  begin
    FreeObject(ACmd.FieldDefs);
    ACmd.FieldDefs := nil;
  end;
  if ACmd.PreparedData <> nil then
    FreeAndNil(ACmd.PreparedData);
  SetLength(ACmd.Params, 0);
end;

function TQProvider.FunctionExists(AName: QStringW): Boolean;
var
  ACmdText: QStringW;
  ASchema: QStringW;
begin
  ASchema := ParseNameToken(AName);
  if Length(ASchema) > 0 then
    ACmdText :=
      'select * from information_schema.routines where routine_schema=' +
      QuotedStrW(ASchema, '''') + ' and routine_name=' + QuotedStrW(AName, '''')
      + ' and routine_type=''FUNCTION'';'
  else
    ACmdText := 'select * from information_schema.routines where routine_name='
      + QuotedStrW(AName, '''') + ' and routine_type=''FUNCTION'';';
  Result := RecordExists(ACmdText);
end;

function TQProvider.GetConnected: Boolean;
begin
  Result := (FHandle <> 0);
end;

function TQProvider.GetConnectionString: QStringW;
begin
  FParams.Delimiter := ';';
  Result := FParams.DelimitedText;
end;

function TQProvider.GetDatabase: String;
begin
  Result := FParams.Values['database'];
end;

function TQProvider.GetFlags(const Index: Integer): Boolean;
begin
  Result := (FFlags and Index) <> 0;
end;

function TQProvider.GetKeepAlive: Boolean;
begin
  Result := GetFlags(PF_KEEPALIVE);
end;

function TQProvider.GetPassword: String;
begin
  Result := FParams.Values['password'];
end;

function TQProvider.GetUserName: String;
begin
  Result := FParams.Values['user'];
end;

procedure TQProvider.InitializeRequest(var ARequest: TQSQLRequest;
  const ASQL: QStringW; ACreateParams: Boolean);
begin

end;

procedure TQProvider.InternalApplyUpdate(ADataSource: TObject);
begin

end;

procedure TQProvider.InternalApplyChanges(Fields: TFieldDefs;
  ARecords: TQRecords);
begin

end;

procedure TQProvider.InternalSetParams(ADest: TParams;
  const ASource: array of const);
begin

end;

procedure TQProvider.KeepAliveNeeded;
begin
  ExecuteCmd('select 0 as QDAC_LivePeek where 1=2');
end;

procedure TQProvider.Listen(const AName: QStringW);
begin

end;

procedure TQProvider.Loaded;
begin
  inherited;
  if Connected then
    Open;
end;

procedure TQProvider.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  inherited;
  if AComponent is TQDataSet then
  begin
    if Operation = opInsert then
    begin
      FDataSets.Add(AComponent as TQDataSet);
      AComponent.FreeNotification(Self);
    end
    else
    begin
      AComponent.RemoveFreeNotification(Self);
      FDataSets.Remove(AComponent as TQDataSet);
    end;
  end;
end;

procedure TQProvider.Notify(const AName, APayload: QStringW);
begin

end;

function TQProvider.Open: Boolean;
begin
  if FHandle = 0 then
  begin
    SetFlags(PF_CONNECTING, True);
    try
      InternalOpen
    finally
      SetFlags(PF_CONNECTING, False);
    end;
    Result := FHandle <> 0;
    if Result then
      SetFlags(PF_CONNECTED, True);
  end
  else
    Result := True;
end;

function TQProvider.OpenDataSet(ADataSet: TQDataSet; ASQL: TQCommand;
  AParams: array of const; AfterOpen: TQAfterExecuteEvent): Boolean;
var
  ARequest: TQSQLRequest;
begin
  if Length(AParams) <> Length(ASQL.Params) then
    DatabaseError(Format(SParamNumberMismatch, [Length(AParams),
      Length(ASQL.Params)]));
  ARequest.Command.Action := caFetchRecords;
  ARequest.Command.Id := ASQL.Id;
  ARequest.Command.SQL := ASQL.SQL;
  ARequest.Command.Params := Copy(ASQL.Params, 0, MaxInt);
  ParamValues(ARequest.Command, AParams);
  ARequest.Command.PreparedData := ASQL.PreparedData;
  ARequest.Command.Prepared := ASQL.Prepared;
  ARequest.Command.FieldDefs := ASQL.FieldDefs;
  ARequest.Command.DataObject := ADataSet;
  ADataSet.FOpenBy := dsomByProvider;
  ARequest.WaitResult := not Assigned(AfterOpen);
  ARequest.AfterOpen := AfterOpen;
  ARequest.Result.ErrorCode := 0;
  FillChar(ARequest.Result.Statics, SizeOf(TQExecuteStatics), 0);
  ARequest.Result.Statics.QueuedTime := GetTimeStamp;
  if (not Execute(ARequest)) and ARequest.WaitResult then
  begin
    SetError(ARequest.Result.ErrorCode, ARequest.Result.ErrorMsg);
    Result := False;
  end
  else
    Result := True;
end;

function TQProvider.OpenDataSet(ADataSet: TQDataSet; ACmdText: QStringW;
  AfterOpen: TQAfterExecuteEvent): Boolean;
var
  ARequest: TQSQLRequest;
begin
  ARequest.Command.DataObject := ADataSet;
  ARequest.Command.SQL := ACmdText;
  ARequest.Command.Params := nil;
  ARequest.Command.Prepared := False;
  ARequest.Command.PreparedData := nil;
  ARequest.Command.FieldDefs := nil;
  ARequest.Command.DataObject := ADataSet;
  ARequest.Command.Action := caFetchRecords;
  ADataSet.FOpenBy := dsomByProvider;
  ARequest.WaitResult := not Assigned(AfterOpen);
  ARequest.AfterOpen := AfterOpen;
  ARequest.Result.ErrorCode := 0;
  FillChar(ARequest.Result.Statics, SizeOf(TQExecuteStatics), 0);
  ARequest.Result.Statics.QueuedTime := GetTimeStamp;
  if (not Execute(ARequest)) and ARequest.WaitResult then
  begin
    SetError(ARequest.Result.ErrorCode, ARequest.Result.ErrorMsg);
    Result := False;
  end
  else
    Result := True;
end;

function TQProvider.OpenDataSet(ACmdText: QStringW): TQDataSet;
begin
  Result := AcquireDataSet;
  if not OpenDataSet(Result, ACmdText) then
  begin
    ReleaseDataSet(Result);
    Result := nil;
  end;
end;

function TQProvider.OpenDataSet(ACmdText: QStringW; AParams: array of const)
  : TQDataSet;
begin
  Result := OpenDataSet(Format(ACmdText, AParams));
end;

function TQProvider.OpenDataSet(ADataSet: TQDataSet; ACmdText: QStringW;
  AParams: array of const; AfterOpen: TQAfterExecuteEvent): Boolean;
begin
  Result := OpenDataSet(ADataSet, Format(ACmdText, AParams), AfterOpen);
end;

function TQProvider.OpenStream(ACmdText: QStringW;
  AStreamFormat: TQConverterClass; AParams: array of const): TMemoryStream;
var
  AConverter: TQConverter;
begin
  AConverter := AStreamFormat.Create(nil);
  Result := TMemoryStream.Create;
  try
    if not OpenStream(Result, Format(ACmdText, AParams), AConverter) then
    begin
      FreeObject(Result);
      Result := nil;
    end;
  finally
    FreeObject(AConverter);
  end;
end;

function TQProvider.OpenStream(AStream: TStream; ACmdText: QStringW;
  AStreamFormat: TQConverterClass; AParams: array of const): Boolean;
var
  AConverter: TQConverter;
begin
  AConverter := AStreamFormat.Create(nil);
  try
    Result := OpenStream(AStream, Format(ACmdText, AParams), AConverter);
  finally
    FreeObject(AConverter);
  end;
end;

function TQProvider.OpenStream(AStream: TStream; ACmdText: QStringW;
  AStreamFormat: TQConverter): Boolean;
var
  ARequest: TQSQLRequest;
begin
  ARequest.Command.DataObject := AStreamFormat;
  AStreamFormat.FStream := AStream;
  ARequest.Command.SQL := ACmdText;
  ARequest.Command.Params := nil;
  ARequest.Command.Prepared := False;
  ARequest.Command.PreparedData := nil;
  ARequest.Command.FieldDefs := nil;
  ARequest.Command.Action := caFetchStream;
  ARequest.WaitResult := True;
  ARequest.AfterOpen := nil;
  ARequest.Result.ErrorCode := 0;
  FillChar(ARequest.Result.Statics, SizeOf(TQExecuteStatics), 0);
  ARequest.Result.Statics.QueuedTime := GetTimeStamp;
  if (not Execute(ARequest)) and (ARequest.WaitResult) then
  begin
    SetError(ARequest.Result.ErrorCode, ARequest.Result.ErrorMsg);
    Result := False;
  end
  else
    Result := True;
end;

function TQProvider.OpenStream(ACmdText: QStringW; AStreamFormat: TQConverter)
  : TMemoryStream;
begin
  Result := TMemoryStream.Create;
  if not OpenStream(Result, ACmdText, AStreamFormat) then
  begin
    FreeObject(Result);
    Result := nil;
  end;
end;

function TQProvider.OpenStream(AStream: TStream; ACmdText: QStringW;
  AStreamFormat: TQConverterClass): Boolean;
var
  AConverter: TQConverter;
begin
  AConverter := AStreamFormat.Create(nil);
  try
    Result := OpenStream(AStream, ACmdText, AConverter);
  finally
    FreeObject(AConverter);
  end;
end;

function TQProvider.OpenStream(ACmdText: QStringW;
  AStreamFormat: TQConverterClass): TMemoryStream;
var
  AConverter: TQConverter;
begin
  AConverter := AStreamFormat.Create(nil);
  Result := TMemoryStream.Create;
  try
    AConverter.FStream := Result;
    if not OpenStream(Result, ACmdText, AConverter) then
    begin
      FreeObject(Result);
      Result := nil;
    end;
  finally
    FreeObject(AConverter);
  end;
end;

function TQProvider.OpenStream(ASQL: TQCommand; AStreamFormat: TQConverterClass)
  : TMemoryStream;
var
  AConverter: TQConverter;
begin
  AConverter := AStreamFormat.Create(nil);
  try
    Result := OpenStream(ASQL, AConverter);
  finally
    FreeObject(AConverter);
  end;
end;

function TQProvider.OpenStream(AStream: TStream; ASQL: TQCommand;
  AStreamFormat: TQConverterClass): Boolean;
var
  AConverter: TQConverter;
begin
  AConverter := AStreamFormat.Create(nil);
  try
    Result := OpenStream(AStream, ASQL, AConverter);
  finally
    FreeObject(AConverter);
  end;
end;

function TQProvider.OpenStream(AStream: TStream; ASQL: TQCommand;
  AStreamFormat: TQConverter): Boolean;
var
  ARequest: TQSQLRequest;
begin
  ARequest.Command := ASQL;
  ARequest.Command.Action := caFetchStream;
  ARequest.Command.DataObject := AStreamFormat;
  ARequest.WaitResult := True;
  ARequest.AfterOpen := nil;
  ARequest.Result.ErrorCode := 0;
  FillChar(ARequest.Result.Statics, SizeOf(TQExecuteStatics), 0);
  ARequest.Result.Statics.QueuedTime := GetTimeStamp;
  if (not Execute(ARequest)) and (ARequest.WaitResult) then
  begin
    SetError(ARequest.Result.ErrorCode, ARequest.Result.ErrorMsg);
    Result := False;
  end
  else
    Result := True;
end;

function TQProvider.OpenStream(ACmdText: QStringW; AStreamFormat: TQConverter;
  AParams: array of const): TMemoryStream;
begin
  Result := OpenStream(Format(ACmdText, AParams), AStreamFormat);
end;

function TQProvider.OpenStream(AStream: TStream; ACmdText: QStringW;
  AStreamFormat: TQConverter; AParams: array of const): Boolean;
begin
  Result := OpenStream(AStream, Format(ACmdText, AParams), AStreamFormat);
end;

function TQProvider.OpenStream(ASQL: TQCommand; AStreamFormat: TQConverter)
  : TMemoryStream;
var
  AConverter: TQConverter;
begin
  AConverter := AStreamFormat.Create(nil);
  try
    Result := OpenStream(ASQL, AConverter);
  finally
    FreeObject(AConverter);
  end;
end;

procedure TQProvider.ParamValues(var ACommand: TQCommand;
  const AParams: array of const);
var
  I: Integer;
  function ToVaraint(AVar: TVarRec): Variant;
  begin
    case AVar.VType of
      vtInteger:
        Result := AVar.VInteger;
      vtBoolean:
        Result := AVar.VBoolean;
      vtExtended:
        Result := AVar.VExtended^;
      vtPointer:
        Result := IntPtr(AVar.VPointer);
      vtObject:
        Result := IntPtr(AVar.VObject);
      vtClass:
        Result := '<' + AVar.VClass.ClassName + '>';
      vtWideChar:
        Result := AVar.VWideChar;
{$IFNDEF NEXTGEN}
      vtPWideChar:
        Result := WideString(AVar.VPWideChar);
      vtWideString:
        Result := PWideString(AVar.VWideString)^;
{$ENDIF}
      vtCurrency:
        Result := AVar.VCurrency^;
      vtVariant:
        Result := AVar.VVariant^;
      vtInterface:
        Result := IUnknown(AVar.VInterface);
      vtInt64:
        Result := AVar.VInt64^;
{$IFDEF UNICODE}
      vtUnicodeString:
        Result := PUnicodeString(AVar.VUnicodeString)^;
{$ENDIF}
{$IFNDEF NEXTGEN}
      vtChar:
        Result := AVar.VChar;
      vtString:
        Result := AVar.VString^;
      vtPChar:
        Result := AnsiString(AVar.VPChar);
      vtAnsiString:
        Result := PAnsiString(AVar.VAnsiString)^;
{$ENDIF !NEXTGEN}
    end;
  end;

begin
  if Length(ACommand.Params) <> Length(AParams) then
    DatabaseError(Format(SParamNumberMismatch, [Length(AParams),
      Length(ACommand.Params)]));
  for I := Low(ACommand.Params) to High(ACommand.Params) do
  begin
    case ACommand.Params[I].ValueType of
      vdtBoolean:
        ACommand.Params[I].AsBoolean := ToVaraint(AParams[I]);
      vdtSingle:
        ACommand.Params[I].AsSingle := ToVaraint(AParams[I]);
      vdtFloat:
        ACommand.Params[I].AsFloat := ToVaraint(AParams[I]);
      vdtInteger:
        ACommand.Params[I].AsInteger := ToVaraint(AParams[I]);
      vdtInt64:
        ACommand.Params[I].AsInt64 := ToVaraint(AParams[I]);
      vdtCurrency:
        ACommand.Params[I].AsCurrency := ToVaraint(AParams[I]);
      vdtBcd:
        ACommand.Params[I].AsBcd := VarToBcd(ToVaraint(AParams[I]));
      vdtGuid:
        ACommand.Params[I].AsGuid := sysutils.StringToGUID
          (ToVaraint(AParams[I]));
      vdtDateTime:
        ACommand.Params[I].AsDateTime := ToVaraint(AParams[I]);
      vdtInterval:
        ACommand.Params[I].AsInterval.AsString := ToVaraint(AParams[I]);
      vdtString:
        ACommand.Params[I].AsString := ToVaraint(AParams[I])
    else
      raise Exception.Create(SUnsupportParamValue);
    end;
  end; // End for
end;

function TQProvider.ParseNameToken(var S: QStringW): QStringW;
var
  p, ps, pe: PQCharW;
begin
  p := PQCharW(S);
  if p^ = FIdentStartChar then
  begin
    Inc(p);
    SkipSpaceW(p);
    ps := p;
    while (p^ <> #0) and (p^ <> FIdentStopChar) do
      Inc(p);
    if p^ = #0 then
      raise Exception.CreateFmt(SUnclosedToken, [S]);
    // 去掉后面的空白
    pe := p;
    Inc(pe);
  end
  else
  begin
    SkipSpaceW(p);
    ps := p;
    while (p^ <> #0) and (p^ <> '.') do
      Inc(p);
    pe := p;
  end;
  Dec(p);
  while p > ps do
  begin
    if IsSpaceW(p) then
      Dec(p)
    else
    begin
      Inc(p);
      Break;
    end;
  end;
  Result := StrDupX(ps, (IntPtr(p) - IntPtr(ps)) shr 1);
  SkipSpaceW(pe);
  if pe^ = '.' then
  begin
    Inc(pe);
    SkipSpaceW(pe);
  end;
  Result := pe;
end;

function TQProvider.Prepare(var AResult: TQCommand;
  ACmdText, AId: QStringW): Boolean;
var
  ARequest: TQSQLRequest;
begin
  ARequest.Command.Id := AId;
  ARequest.Command.SQL := ACmdText;
  ARequest.Command.Prepared := False;
  ARequest.Command.PreparedData := nil;
  ARequest.Command.FieldDefs := nil;
  ARequest.Command.DataObject := nil;
  ARequest.Command.Action := caPrepare;
  ARequest.WaitResult := True;
  ARequest.AfterOpen := nil;
  ARequest.Result.ErrorCode := 0;
  FillChar(ARequest.Result.Statics, SizeOf(TQExecuteStatics), 0);
  ARequest.Result.Statics.QueuedTime := GetTimeStamp;
  Result := Execute(ARequest);
  if Result then
    AResult := ARequest.Command
  else
  begin
    SetError(ARequest.Result.ErrorCode, ARequest.Result.ErrorMsg);
  end;
end;

function TQProvider.PrepareChangeRequest(var ARequest: TQSQLRequest;
  AUpdatStatus: TUpdateStatus): Boolean;
begin
  Result := False;
end;

function TQProvider.ProcedureExists(AName: QStringW): Boolean;
var
  ACmdText: QStringW;
  ASchema: QStringW;
begin
  ASchema := ParseNameToken(AName);
  if Length(ASchema) > 0 then
    ACmdText :=
      'select * from information_schema.routines where routine_schema=' +
      QuotedStrW(ASchema, '''') + ' and routine_name=' + QuotedStrW(AName, '''')
      + ' and routine_type=''PROCEDURE'';'
  else
    ACmdText := 'select * from information_schema.routines where routine_name='
      + QuotedStrW(AName, '''') + ' and routine_type=''PROCEDURE'';';
  Result := RecordExists(ACmdText);

end;

function TQProvider.RecordExists(ACmdText: QStringW): Boolean;
begin
  if Handle = 0 then
    DatabaseError(SNotConnected);
  Result := ExecuteCmd(ACmdText) > 0;
end;

class procedure TQProvider.ReleaseDataSet(ADataSet: TQDataSet);
begin
  ADataSet.Close;
  ADataSet.Provider := nil;
  if ADataSet.Owner = nil then // 有所有者的，由所隶属的所有者负责释放
  begin
    if Assigned(QDataSetPool) then
      QDataSetPool.Push(ADataSet)
    else
      FreeObject(ADataSet);
  end;
end;

procedure TQProvider.RollbackTrans(ASavePointName: QStringW);
begin
  Dec(FTransactionLevel);
end;

procedure TQProvider.ServerNotice(ALevel: TQNoticeLevel; const AMsg: QStringW);
begin
  if Assigned(FOnServerNotification) then
    FOnServerNotification(Self, ALevel, AMsg);
end;

procedure TQProvider.SetConnected(const Value: Boolean);
begin
  if Connected <> Value then
  begin
    if not(csLoading in ComponentState) then
    begin
      if Value then
        Open
      else
        Close;
    end
    else
      SetFlags(PF_CONNECTED, Value);
  end;
end;

procedure TQProvider.SetConnectionString(const Value: QStringW);
const
  AListChars: PWideChar = ';';
  AQuoterChar: WideChar = '"';
begin
  FParams.Clear;
  SplitTokenW(FParams, Value, AListChars, AQuoterChar, True);
end;

procedure TQProvider.SetDatabase(const Value: String);
begin
  FParams.Values['database'] := Value;
end;

procedure TQProvider.SetDataSetHandle(ADataSet: TQDataSet; AHandle: THandle);
begin
  ADataSet.FHandle := AHandle;
end;

procedure TQProvider.SetError(ACode: Cardinal; const AMsg: QStringW);
begin
  FErrorCode := ACode;
  FErrorMsg := AMsg;
end;

procedure TQProvider.SetFetching(ADefs: TQFieldDefs; ARecords: TQRecords);
begin
  FActiveFieldDefs := ADefs;
  FActiveRecords := ARecords;
end;

procedure TQProvider.SetFetching(ADataSet: TQDataSet);
begin
  SetFetching(ADataSet.FieldDefs as TQFieldDefs, ADataSet.FOriginRecords);
end;

procedure TQProvider.SetFlags(AFlag: Integer; AValue: Boolean);
begin
  if AValue then
    FFlags := FFlags or AFlag
  else
    FFlags := FFlags and (not AFlag);
end;

procedure TQProvider.SetKeepAlive(const Value: Boolean);
begin
  if KeepAlive <> Value then
  begin
    SetFlags(PF_KEEPALIVE, Value);
    FireKeepAlive;
  end;
end;

procedure TQProvider.SetParams(const Value: TStrings);
begin
  FParams.Assign(Value);
end;

procedure TQProvider.SetPassword(const Value: String);
begin
  FParams.Values['password'] := Value;
end;

procedure TQProvider.SetPeekInterval(const Value: Integer);
begin
  if FPeekInterval <> Value then
  begin
    FPeekInterval := Value;
    FireKeepAlive;
  end;
end;

procedure TQProvider.SetUserName(const Value: String);
begin
  FParams.Values['user'] := Value;
end;

function TQProvider.TableExists(ATableName: QStringW): Boolean;
var
  ACmdText: QStringW;
  ASchema: QStringW;
begin
  ASchema := ParseNameToken(ATableName);
  if Length(ASchema) > 0 then
    ACmdText := 'select * from information_schema.tables where table_schema=' +
      QuotedStrW(ASchema, '''') + ' and table_name=' + QuotedStrW(ATableName,
      '''') + ' and table_type=''BASE TABLE'''
  else
    ACmdText := 'select * from information_schema.tables where table_name=' +
      QuotedStrW(ATableName, '''') + ' and table_type=''BASE TABLE''';
  Result := RecordExists(ACmdText);
end;

function TQProvider.TriggerExists(AName: QStringW): Boolean;
var
  ACmdText: QStringW;
  ASchema: QStringW;
begin
  ASchema := ParseNameToken(AName);
  if Length(ASchema) > 0 then
    ACmdText :=
      'select * from information_schema.triggers where trigger_schema=' +
      QuotedStrW(ASchema, '''') + ' and trigger_name=' +
      QuotedStrW(AName, '''') + ';'
  else
    ACmdText := 'select * from information_schema.triggers where trigger_name='
      + QuotedStrW(AName, '''') + ';';
  Result := RecordExists(ACmdText);
end;

procedure TQProvider.Unlisten(const AName: QStringW);
begin
  raise Exception.CreateFmt(SUnsupportFunction, ['Unlisten']);
end;

procedure TQProvider.Unprepare(var ACmd: TQCommand);
var
  ARequest: TQSQLRequest;
begin
  ARequest.Command := ACmd;
  ARequest.Command.Action := caUnprepare;
  ARequest.WaitResult := True;
  ARequest.AfterOpen := nil;
  ARequest.Result.ErrorCode := 0;
  FillChar(ARequest.Result.Statics, SizeOf(TQExecuteStatics), 0);
  ARequest.Result.Statics.QueuedTime := GetTimeStamp;
  if not Execute(ARequest) then
    SetError(ARequest.Result.ErrorCode, ARequest.Result.ErrorMsg);
end;

function TQProvider.ViewExists(AName: QStringW): Boolean;
var
  ACmdText: QStringW;
  ASchema: QStringW;
begin
  ASchema := ParseNameToken(AName);
  if Length(ASchema) > 0 then
    ACmdText := 'select * from information_schema.views where table_schema=' +
      QuotedStrW(ASchema, '''') + ' and table_name=' +
      QuotedStrW(AName, '''') + ';'
  else
    ACmdText := 'select * from information_schema.views where table_name=' +
      QuotedStrW(AName, '''') + ';';
  Result := RecordExists(ACmdText);
end;

{ TQBlobStream }

constructor TQBlobStream.Create(AField: TBlobField; AMode: TBlobStreamMode);
var
  ABuf: TQRecord;
  procedure AnsiStringToStream;
  var
    S: TBytes;
  begin
    S := AnsiEncode(FOriginValue.Value.AsString^);
    TMemoryStream(FData.Value.AsStream).Write(S[0], Length(S));
  end;

begin
  inherited Create;
  FField := AField;
  FMode := AMode;
  FData.TypeNeeded(vdtStream);
  if not FField.DataSet.IsEmpty then
  begin
    if FField.DataSet.State in [dsCalcFields, dsInternalCalc] then
      ABuf := TQRecord(TQDataSet(FField.DataSet).CalcBuffer)
    else
      ABuf := TQRecord(TQDataSet(FField.DataSet).ActiveBuffer);
    if Assigned(ABuf.Bookmark) then
      ABuf := ABuf.Bookmark;
    if AMode <> bmRead then
    begin
      if FField.ReadOnly then
        DatabaseError(Format(SFieldReadOnly, [FField.DisplayName]));
      if not(FField.DataSet.State in dsEditModes) then
        DatabaseError(SDSNotInEdit, FField.DataSet);
    end;
    FOriginValue := ABuf.Values[FField.FieldNo - 1].CurrentValue;
    if AMode = bmWrite then
      Truncate
    else
    begin
      if not FOriginValue.IsNull then
      begin
        if FOriginValue.ValueType = vdtStream then
          TMemoryStream(FData.Value.AsStream)
            .CopyFrom(FOriginValue.Value.AsStream, 0)
        else if FOriginValue.ValueType = vdtString then
        begin
          if FField.DataType in [ftFixedChar, ftString, ftMemo] then
            // Ansi编码
            AnsiStringToStream
          else
            TMemoryStream(FData.Value.AsStream).
              Write(PQCharW(FOriginValue.Value.AsString^)^,
              Length(FOriginValue.Value.AsString^) shl 1)
        end
        else
          DatabaseError(Format(SUnsupportDataType, [AField.FieldName]));
      end;
    end;
    TMemoryStream(FData.Value.AsStream).Position := 0;
  end;
end;

destructor TQBlobStream.Destroy;
var
  AValues: PQColumnValue;
  ADataSet: TQDataSet;
  ABuf: TQRecord;
  AModified: Boolean;
begin
  if FMode = bmWrite then
  begin
    if FOriginValue.IsNull then
      AModified := FData.AsStream.Size <> 0
    else if FData.AsStream.Size <> FOriginValue.AsStream.Size then
      AModified := True
    else
      AModified := not CompareMem(FData.AsStream.Memory,
        FOriginValue.AsStream.Memory, FData.AsStream.Size);
    if AModified then
    begin
      try
        ADataSet := FField.DataSet as TQDataSet;
        if FField.DataSet.State in [dsCalcFields, dsInternalCalc] then
          ABuf := TQRecord(TQDataSet(FField.DataSet).CalcBuffer)
        else
          ABuf := TQRecord(TQDataSet(FField.DataSet).ActiveBuffer);
        if Assigned(ABuf.Bookmark) then
          ABuf := ABuf.Bookmark;
        AValues := @ABuf.Values[FField.FieldNo - 1];
        AValues.Changed := True;
        if TQValueStream(FData.Value.AsStream).Size = 0 then
          AValues.NewValue.Reset
        else if QValueTypeMap[FField.DataType] = vdtString then
        begin
          AValues.NewValue.TypeNeeded(vdtString);
          TQValueStream(FData.Value.AsStream).Position := 0;
          AValues.NewValue.Value.AsString^ := LoadTextW(FData.Value.AsStream);
        end
        else
        begin
          AValues.NewValue.TypeNeeded(vdtStream);
          TQValueStream(AValues.NewValue.Value.AsStream).Size :=
            TMemoryStream(FData.Value.AsStream).Size;
          Move(TQValueStream(FData.Value.AsStream).Memory^,
            TQValueStream(AValues.NewValue.Value.AsStream).Memory^,
            TQValueStream(FData.Value.AsStream).Size);
          TQValueStream(AValues.NewValue.Value.AsStream).Position := 0;
        end;
        FField.Modified := True;
        ADataSet.DataEvent(deFieldChange, Longint(FField));
      except
        RunInMainThread(TQDataSet(FField.DataSet)
          .HandleExceptionInMainThread, Self);
      end;
    end;
  end;
  FData.Reset;
  inherited;
end;

function TQBlobStream.GetSize: Int64;
begin
  Result := FData.AsStream.Size;
end;

function TQBlobStream.Read(var Buffer; Count: Longint): Longint;
begin
  Result := FData.AsStream.Read(Buffer, Count);
end;

function TQBlobStream.Seek(const Offset: Int64; Origin: TSeekOrigin): Int64;
begin
  Result := FData.AsStream.Seek(Offset, Origin);
end;

procedure TQBlobStream.SetSize(NewSize: Longint);
begin
  FData.AsStream.SetSize(NewSize);
end;

procedure TQBlobStream.Truncate;
begin
  FData.AsStream.Size := 0;
end;

function TQBlobStream.Write(const Buffer; Count: Longint): Longint;
begin
  Result := FData.AsStream.Write(Buffer, Count);
end;

{ TQColumnValue }

function TQColumnValue.CurrentValue: PQValue;
begin
  if Changed then
    Result := @NewValue
  else
    Result := @OldValue;
end;

{ TQRecords }

function TQRecords.Add(const Value: TQRecord): Integer;
begin
  Result := FItems.Add(Value);
  Value.AddRef;
end;

function TQRecords.AddWithoutRef(const Value: TQRecord): Integer;
begin
  Result := FItems.Add(Value);
end;

procedure TQRecords.Assign(ASource: TQRecords);
var
  I: Integer;
begin
  Clear(False);
  FItems.Assign(ASource.FItems);
  I := 0;
  while I < Count do
  begin
    Records[I].AddRef;
    Inc(I);
  end;
end;

procedure TQRecords.Clean;
  procedure ClearOrigins;
  var
    I, C: Integer;
  begin
    C := Count;
    I := FFirstDirtyIndex;
    while I < C do
    begin
      Records[I].FOriginIndex := I;
      Inc(I);
    end;
    FFirstDirtyIndex := C;
  end;

  procedure ClearChangeds;
  var
    I, C: Integer;
  begin
    C := Count;
    I := FFirstDirtyIndex;
    while I < C do
    begin
      Records[I].FChangedIndex := I;
      Inc(I);
    end;
    FFirstDirtyIndex := C;
  end;
  procedure ClearSorteds;
  var
    I, C: Integer;
  begin
    C := Count;
    I := FFirstDirtyIndex;
    while I < C do
    begin
      Records[I].FSortedIndex := I;
      Inc(I);
    end;
    FFirstDirtyIndex := C;
  end;
  procedure ClearFiltereds;
  var
    I, C: Integer;
  begin
    C := Count;
    I := FFirstDirtyIndex;
    while I < C do
    begin
      Records[I].FFilteredIndex := I;
      Inc(I);
    end;
    FFirstDirtyIndex := C;
  end;

begin
  if FFirstDirtyIndex >= Count then
    FFirstDirtyIndex := Count
  else
  begin
    case FIndexType of
      ditOrigin:
        ClearOrigins;
      ditChanged:
        ClearChangeds;
      ditSorted:
        ClearSorteds;
      ditFiltered:
        ClearFiltereds;
    end;
  end;
end;

procedure TQRecords.Clear(ADoPack: Boolean);
var
  I: Integer;
begin
  I := 0;
  while I < Count do
  begin
    Records[I].Release;
    Inc(I);
  end;
  FItems.Clear;
  if ADoPack then
    FItems.Pack;
end;

constructor TQRecords.Create(AIndexType: TQDirtyIndexType);
begin
  inherited Create;
  FIndexType := AIndexType;
  FItems := TQPagedList.Create;
end;

procedure TQRecords.Delete(AIndex: Integer);
begin
  Records[AIndex].Release;
  FItems.Delete(AIndex);
  if AIndex < FFirstDirtyIndex then
    FFirstDirtyIndex := AIndex;
end;

procedure TQRecords.DeleteWithoutRef(AIndex: Integer);
begin
  FItems.Delete(AIndex);
end;

destructor TQRecords.Destroy;
begin
  Clear;
  FreeObject(FItems);
  inherited;
end;

function TQRecords.GetCount: Integer;
begin
  Result := FItems.Count;
end;

function TQRecords.GetRecords(AIndex: Integer): TQRecord;
begin
  Result := FItems[AIndex];
  case Self.FIndexType of
    ditOrigin:
      Result.FOriginIndex := AIndex;
    ditSorted:
      Result.FSortedIndex := AIndex;
    ditFiltered:
      Result.FFilteredIndex := AIndex;
  end;
end;

procedure TQRecords.Insert(Index: Integer; const Value: TQRecord);
begin
  FItems.Insert(Index, Value);
  Value.AddRef;
end;

procedure TQRecords.MoveTo(AFrom, ATo: Integer);
begin
  if AFrom <> ATo then
    FItems.Move(AFrom, ATo);
end;

procedure TQRecords.SetRecords(AIndex: Integer; const Value: TQRecord);
begin
  Records[AIndex].Release;
  FItems[AIndex] := Value;
  Value.AddRef;
end;

procedure TQRecords.Unlink;
var
  ABuf, ASource: TQRecord;
  I: Integer;
begin
  I := 0;
  while I < Count do
  begin
    ABuf := FItems[I];
    if Assigned(ABuf.Bookmark) then
    begin
      ASource := ABuf.Bookmark;
      ABuf.Reset;
      SetLength(ABuf.FValues, Length(ASource.Values));
      ABuf.CopyValues(ABuf.Bookmark);
      ABuf.FBookmark := nil;
    end;
    Inc(I);
  end;
end;

procedure TQRecords.ValidIndex(const AIndex: Integer);
begin
  if (AIndex < 0) or (AIndex >= Count) then
    raise EListError.CreateFmt(SListIndexError, [AIndex]);
end;

{ TQFieldDefs }

constructor TQFieldDefs.Create(AOwner: TPersistent);
begin
  inherited;
{$IFNDEF UNICODE}
  // Hack
  PPointer(@ItemClass)^ := TQFieldDef;
{$ENDIF}
end;
{$IFDEF UNICODE}

function TQFieldDefs.GetFieldDefClass: TFieldDefClass;
begin
  Result := TQFieldDef;
end;
{$ENDIF}

procedure TQFieldDefs.Notify(Item: TCollectionItem;
  Action: classes.TCollectionNotification);
var
  ADataSet: TQDataSet;
  AList: TQRecords;
  ARec: TQRecord;
  I, AMoveNeeded, ACount: Integer;
begin
  if Assigned(DataSet) and DataSet.Active then // 只在活动的数据集上处理
  begin
    ADataSet := DataSet as TQDataSet;
    AList := ADataSet.FOriginRecords;
    AMoveNeeded := Count - Item.Index - 1;
    if (Action = cnDeleting) or (Action = cnExtracting) then
    begin
      // 要删除
      ACount := Count - 1;
      for I := 0 to AList.Count - 1 do
      begin
        ARec := AList[I];
        ARec.Values[Item.Index].OldValue.Reset;
        ARec.Values[Item.Index].NewValue.Reset;
        if AMoveNeeded > 0 then
          Move(ARec.FValues[Item.Index + 1], ARec.FValues[Item.Index],
            AMoveNeeded * SizeOf(TQColumnValue));
        SetLength(ARec.FValues, ACount);
      end;
    end
    else // 已添加
    begin
      for I := 0 to AList.Count - 1 do
      begin
        ARec := AList[I];
        SetLength(ARec.FValues, Count);
        if AMoveNeeded > 0 then
          Move(ARec.FValues[Item.Index], ARec.FValues[Item.Index + 1],
            AMoveNeeded * SizeOf(TQColumnValue));
      end;
    end;
  end;
  inherited Notify(Item, Action);
end;

{ TQConverter }

procedure TQConverter.AfterExport;
var
  I: Integer;
  ASource, ADest: TMemoryStream;
begin
  if Assigned(FStream) and (FOriginStream <> FStream) then
  begin
    ASource := FStream as TMemoryStream;
    ADest := TMemoryStream.Create;
    try
      for I := 0 to FStreamProcessors.Count - 1 do
      begin
        ASource.Position := 0;
        ADest.Size := 0;
        FStreamProcessors[I].Processor.BeforeSave(ASource, ADest);
        ASource.Size := ADest.Size;
        if ASource.Size > 0 then
          Move(ADest.Memory^, ASource.Memory^, ASource.Size);
      end;
      FOriginStream.CopyFrom(ASource, 0);
    finally
      FreeObject(ASource);
      FreeObject(ADest);
      FStream := FOriginStream;
    end;
  end;
  DoProgress(csAfterExport, 0, 0);
end;

procedure TQConverter.AfterImport;
begin
  if Assigned(FStream) then
  begin
    if FOriginStream <> FStream then
      FreeObject(FStream);
  end;
  DoProgress(csAfterImport, 0, 0);
end;

procedure TQConverter.BeforeExport;
begin
  DoProgress(csBeforeExport, 0, 0);
  FOriginStream := FStream;
  if Assigned(FStream) then
  begin
    if FStreamProcessors.Count > 0 then
      FStream := TMemoryStream.Create;
    FStartOffset := FStream.Position;
  end
  else
    FStartOffset := 0;
end;

procedure TQConverter.BeforeImport;
var
  I: Integer;
  ASource, ADest: TMemoryStream;
begin
  DoProgress(csBeforeImport, 0, 0);
  FOriginStream := FStream;
  if Assigned(FStream) then
  begin
    if FStreamProcessors.Count > 0 then
    begin
      ASource := TMemoryStream.Create;
      ADest := TMemoryStream.Create;
      try
        ASource.CopyFrom(FStream, FStream.Size - FStream.Position);
        for I := FStreamProcessors.Count - 1 downto 0 do
        begin
          ASource.Position := 0;
          ADest.Size := 0;
          FStreamProcessors[I].Processor.BeforeLoad(ASource, ADest);
          ASource.Size := ADest.Size;
          if ASource.Size > 0 then
            Move(ADest.Memory^, ASource.Memory^, ASource.Size);
        end;
      finally
        FreeObject(ADest);
        FStream := ASource;
        FStream.Position := 0;
      end;
    end;
    FStartOffset := FStream.Position;
  end
  else
    FStartOffset := 0;
end;

procedure TQConverter.BeginExport(AIndex: Integer);
begin
  DoProgress(csBeginExport, 0, 0);
end;

procedure TQConverter.BeginImport(AIndex: Integer);
begin
  DoProgress(csBeginImport, 0, 0);
end;

constructor TQConverter.Create(AOwner: TComponent);
begin
  inherited;
  FExportRanges := [merMeta, merUnmodified, merInserted, merDeleted,
    merModified];
  FStreamProcessors := TQStreamProcessors.Create;
end;

destructor TQConverter.Destroy;
begin
  FreeObject(FStreamProcessors);
  inherited;
end;

procedure TQConverter.DoProgress(AStep: TQConvertStep;
  AProgress, ATotal: Integer);
begin
  if Assigned(FOnProgress) then
    FOnProgress(Self, AStep, AProgress, ATotal);
end;

procedure TQConverter.EndExport(AIndex: Integer);
begin
  DoProgress(csEndExport, 0, 0);
end;

procedure TQConverter.EndImport(AIndex: Integer);
begin
  DoProgress(csEndImport, 0, 0);
end;

function TQConverter.GetActiveRecCount: Integer;
begin
  Result := -1;
end;

procedure TQConverter.LoadFromConverter(AConverter: TQConverterClass;
  ASourceFile, ATargetFile: QStringW);
var
  ACvt: TQConverter;
begin
  ACvt := AConverter.Create(nil);
  try
    LoadFromConverter(ACvt, ASourceFile, ATargetFile);
  finally
    FreeAndNil(ACvt);
  end;
end;

procedure TQConverter.LoadFromConverter(AConverter: TQConverter;
  ASourceFile, ATargetFile: QStringW);
var
  ASourceStream, ATargetStream: TStream;
begin
  ASourceStream := TFileStream.Create(ASourceFile, fmOpenRead or
    fmShareDenyWrite);
  try
    ATargetStream := TFileStream.Create(ATargetFile, fmCreate);
    try
      LoadFromConverter(Self, ASourceStream, ATargetStream);
    finally
      FreeAndNil(ATargetStream);
    end;
  finally
    FreeAndNil(ASourceStream);
  end;
end;

procedure TQConverter.LoadFromFile(ADataSet: TQDataSet; AFileName: QStringW);
begin
  ADataSet.LoadFromFile(AFileName, Self);
end;

procedure TQConverter.LoadFromStream(ADataSet: TQDataSet; AStream: TStream);
begin
  ADataSet.LoadFromStream(AStream, Self);
end;

procedure TQConverter.LoadFromConverter(AConverter: TQConverter;
  ASourceStream, ATargetStream: TStream);
var
  ADataSet: TQDataSet;
  ARecords: TQRecords;
  ARec: TQRecord;
  I: Integer;
  AcceptStatus: TUpdateStatusSet;
begin
  if merUnmodified in ExportRanges then // 需要导出未修改的数据
    AcceptStatus := [usUnmodified]
  else
    AcceptStatus := [];
  if merInserted in ExportRanges then
    AcceptStatus := AcceptStatus + [usInserted];
  if merModified in ExportRanges then
    AcceptStatus := AcceptStatus + [usModified];
  if merDeleted in ExportRanges then
    AcceptStatus := AcceptStatus + [usDeleted];
  AConverter.FDataSet := nil;
  AConverter.FStream := ASourceStream;
  AConverter.BeforeImport;
  ADataSet := TQProvider.AcquireDataSet; // 只是临时借来用的
  ARecords := TQRecords.Create(ditOrigin);
  FStream := ATargetStream;
  try
    BeforeExport; // 自己
    I := 0;
    while I < AConverter.DataSetCount do
    begin
      ADataSet.FieldDefs.Clear;
      AConverter.LoadFieldDefs(ADataSet.FieldDefs as TQFieldDefs);
      ARec := ADataSet.AllocRecord;
      BeginExport(I);
      try
        if merMeta in ExportRanges then
          SaveFieldDefs(ADataSet.FieldDefs as TQFieldDefs);
        while AConverter.ReadRecord(ARec) do
        begin
          if ARec.Status in AcceptStatus then
          begin
            if not WriteRecord(ARec) then
              Break;
          end;
          ARec.Reset;
        end;
      finally
        ADataSet.FreeRecord(ARec);
        ADataSet.FOriginRecords.Clear(False);
        EndExport(I);
      end;
      Inc(I);
    end;
  finally
    FreeAndNil(ARecords);
    ADataSet.FieldDefs.Clear;
    ADataSet.FOriginRecords.Clear();
    TQProvider.ReleaseDataSet(ADataSet);
    AConverter.AfterImport;
    AfterExport;
  end;
end;

procedure TQConverter.LoadFromConverter(AConverter: TQConverterClass;
  ASourceStream, ATargetStream: TStream);
var
  ACvt: TQConverter;
begin
  ACvt := AConverter.Create(nil);
  try
    LoadFromConverter(ACvt, ASourceStream, ATargetStream);
  finally
    FreeAndNil(ACvt);
  end;
end;

procedure TQConverter.RemoveChild(AIndex: Integer);
begin
  if AIndex < DataSetCount then
  begin
    FreeAndNil(FDataSet.FRecordsets[AIndex]);
    Dec(FDataSetCount);
    while AIndex < DataSetCount do
    begin
      FDataSet.FRecordsets[AIndex] := FDataSet.FRecordsets[AIndex + 1];
      Inc(AIndex);
    end;
  end;
end;

procedure TQConverter.SaveToFile(ADataSet: TQDataSet; AFileName: QStringW);
begin
  ADataSet.SaveToFile(AFileName, Self);
end;

procedure TQConverter.SaveToConverter(AConverter: TQConverter;
  ASourceFile, ATargetFile: QStringW);
var
  ASourceStream, ATargetStream: TStream;
begin
  ASourceStream := TFileStream.Create(ASourceFile, fmOpenRead or
    fmShareDenyWrite);
  try
    ATargetStream := TFileStream.Create(ATargetFile, fmCreate);
    try
      SaveToConverter(AConverter, ASourceStream, ATargetStream);
    finally
      FreeAndNil(ATargetStream);
    end;
  finally
    FreeAndNil(ASourceStream);
  end;
end;

procedure TQConverter.SaveToConverter(AConverter: TQConverterClass;
  ASourceFile, ATargetFile: QStringW);
var
  ACvt: TQConverter;
begin
  ACvt := AConverter.Create(nil);
  try
    SaveToConverter(ACvt, ASourceFile, ATargetFile);
  finally
    FreeAndNil(ACvt);
  end;
end;

procedure TQConverter.SaveToConverter(AConverter: TQConverterClass;
  ASourceStream, ATargetStream: TStream);
var
  ACvt: TQConverter;
begin
  ACvt := AConverter.Create(nil);
  try
    SaveToConverter(ACvt, ASourceStream, ATargetStream);
  finally
    FreeAndNil(ACvt);
  end;
end;

procedure TQConverter.SaveToConverter(AConverter: TQConverter;
  ASourceStream, ATargetStream: TStream);
begin
  AConverter.LoadFromConverter(Self, ASourceStream, ATargetStream);
end;

procedure TQConverter.SaveToStream(ADataSet: TQDataSet; AStream: TStream);
begin
  ADataSet.SaveToStream(AStream, Self);
end;

procedure TQConverter.SetDataSet(const Value: TQDataSet);
begin
  if FDataSet <> Value then
  begin
    FDataSet := Value;
    if Assigned(FDataSet) then
    begin
      FDataSetCount := FDataSet.RecordsetCount;
      if FDataSetCount = 0 then
        FDataSetCount := 1;
      FActiveDataSet := 0;
    end
    else
    begin
      FDataSetCount := 0;
      FActiveDataSet := -1;
    end;
  end;
end;

procedure TQConverter.SetFStreamProcessors(const Value: TQStreamProcessors);
begin
  FStreamProcessors.Assign(Value);
end;

{ TQStreamProcessors }

function TQStreamProcessors.Add: TQStreamProcessorItem;
begin
  Result := inherited Add as TQStreamProcessorItem;
end;

constructor TQStreamProcessors.Create;
begin
  inherited Create(TQStreamProcessorItem);
end;

function TQStreamProcessors.GetProcessor(Index: Integer): TQStreamProcessorItem;
begin
  Result := inherited Items[Index] as TQStreamProcessorItem;
end;

procedure TQStreamProcessors.SetProcessor(Index: Integer;
  const Value: TQStreamProcessorItem);
begin
  inherited Items[Index] := Value;
end;

procedure DoNewDataSetItem(ASender: TQSimplePool; var AData: Pointer);
begin
  AData := TQDataSet.Create(nil);
end;

procedure DoFreeDataSetItem(ASender: TQSimplePool; AData: Pointer);
begin
  FreeObject(AData);
end;

procedure DoResetDataSetItem(ASender: TQSimplePool; AData: Pointer);
begin
  with TQDataSet(AData) do
  begin
    Close;
    FAnsiNulls := True;
    FProvider := nil;
    FCommandText := '';
    FPageSize := 0;
    FBatchMode := True;
    FOpenBy := dsomByCreate;
    FPageIndex := 0;
    FReadOnly := False;
    FSort := '';
    FChecks.Clear;
    FAllowEditActions := [];
    FNaturalFilter := False;
    AutoCalcFields := True;
    DataSetField := nil;
    FActiveRecordset := 0;
    OnCustomSort := nil;
    FMasterLink.DataSource := nil;
    FMasterDetailFields := '';
    FOnMasterChanged := nil;
    Filter := '';
    Filtered := False;
    FilterOptions := [];
    BeforeOpen := nil;
    AfterOpen := nil;
    BeforeClose := nil;
    AfterClose := nil;
    BeforeInsert := nil;
    AfterInsert := nil;
    BeforeEdit := nil;
    AfterEdit := nil;
    BeforePost := nil;
    AfterPost := nil;
    BeforeCancel := nil;
    AfterCancel := nil;
    BeforeDelete := nil;
    AfterDelete := nil;
    BeforeScroll := nil;
    AfterScroll := nil;
    BeforeRefresh := nil;
    AfterRefresh := nil;
    OnCalcFields := nil;
    OnDeleteError := nil;
    OnEditError := nil;
    OnFilterRecord := nil;
    OnNewRecord := nil;
    OnPostError := nil;
  end;
end;

{ TQSchemas }

constructor TQSchemas.Create;
begin
  FItems := TQHashTable.Create;
end;

destructor TQSchemas.Destroy;
begin
  FreeObject(FItems);
  inherited;
end;

function TQSchemas.Find(AId: Cardinal): TQSchema;
begin
  Result := FItems.FindFirstData(AId);
end;

{ TQSchema }

constructor TQSchema.Create(AOwner: TQSchemas);
begin
  inherited Create;
  FOwner := AOwner;
end;

destructor TQSchema.Destroy;
begin

  inherited;
end;

function TQSchema.GetFlags(const Index: Integer): Boolean;
begin
  Result := (FFlags and Index) <> 0;
end;

function TQSchema.GetHashCode: Integer;
var
  AParent: TQSchema;
begin
  Result := FId;
  AParent := FParent;
  while AParent <> nil do
  begin
    Result := Result * 100 + Integer(AParent.Id);
    AParent := AParent.Parent;
  end;
end;

procedure TQSchema.SetFlags(const Index: Integer; const Value: Boolean);
begin
  if Value then
    FFlags := FFlags or Index
  else
    FFlags := FFlags and (not Index);
end;

{ TQSColumn }

constructor TQSColumn.Create(AOwner: TQSchemas);
begin
  inherited;
  FFlags := FFlags or SCHEMA_COLUMN;
end;

function TQSColumn.GetTable: TQSTable;
begin
  Result := TQSTable(FParent);
end;

{ TQSList }

function TQSList.Add(const AId: Cardinal; const AName: QStringW): TQSchema;
var
  AIdx: Integer;
begin
  if InternalFind(AId, AIdx) then
    Result := Items[AIdx]
  else
  begin
    Result := CreateItem;
    Result.FId := AId;
    Result.FName := AName;
    Result.FParent := Self;
    FOwner.FItems.Add(Result, Result.HashCode);
    FItems.Insert(AIdx, Result);
  end;

end;

procedure TQSList.Clear;
var
  I: Integer;
begin
  Lock;
  try
    for I := 0 to Count do
      FreeObject(Items[I]);
    FItems.Clear;
  finally
    Unlock;
  end;
end;

constructor TQSList.Create(AOwner: TQSchemas);
begin
  inherited Create;
  FOwner := AOwner;
  FLocker := TCriticalSection.Create;
  FItems := TQSchemaList.Create;
end;

procedure TQSList.Delete(AIdx: Integer);
begin
  Lock;
  try
    FreeObject(Items[AIdx]);
    FItems.Delete(AIdx);
  finally
    Unlock;
  end;
end;

destructor TQSList.Destroy;
begin
  Clear;
  FreeObject(FLocker);
  FreeObject(FItems);
  inherited;
end;

function TQSList.FindById(const AId: Cardinal): TQSchema;
var
  AIdx: Integer;
begin
  if InternalFind(AId, AIdx) then
    Result := Items[AIdx]
  else
    Result := nil;
end;

function TQSList.FindByName(const AName: QStringW): TQSchema;
var
  I: Integer;
begin
  Result := nil;
  for I := 0 to Count - 1 do
  begin
    if Items[I].Name = AName then
    begin
      Result := Items[I];
      Break;
    end;
  end;
end;

function TQSList.GetCount: Integer;
begin
  Result := FItems.Count;
end;

function TQSList.GetItems(AIndex: Integer): TQSchema;
begin
  Result := FItems[AIndex];
end;

function TQSList.InternalFind(const AId: Cardinal; var AIndex: Integer)
  : Boolean;
var
  L, H, I, C: Integer;
begin
  Result := False;
  L := 0;
  H := Count - 1;
  while L <= H do
  begin
    I := (L + H) shr 1;
    C := Items[I].Id - AId;
    if C < 0 then
      L := I + 1
    else
    begin
      H := I - 1;
      if C = 0 then
        Result := True;
    end;
  end;
  AIndex := L;
end;

procedure TQSList.Lock;
begin
  FLocker.Enter;
end;

procedure TQSList.Unlock;
begin
  FLocker.Leave;
end;

{ TQSDatabase }

function TQSDatabase.Add(const AId: Cardinal; AName: QStringW): TQSTable;
begin
  Result := inherited Add(AId, AName) as TQSTable;
end;

constructor TQSDatabase.Create(AOwner: TQSchemas);
begin
  inherited;
  FFlags := FFlags or SCHEMA_DATABASE;
end;

function TQSDatabase.CreateItem: TQSchema;
begin
  Result := TQSTable.Create(Owner);
end;

function TQSDatabase.FindById(const AId: Cardinal): TQSTable;
begin
  Lock;
  try
    Result := inherited FindById(AId) as TQSTable;
  finally
    Unlock;
  end;
end;

function TQSDatabase.FindByName(const AName: QStringW): TQSTable;
begin
  Lock;
  try
    Result := inherited FindByName(AName) as TQSTable;
  finally
    Unlock;
  end;
end;

function TQSDatabase.GetTables(AIndex: Integer): TQSTable;
begin
  Result := Items[AIndex] as TQSTable;
end;

{ TQSTable }

function TQSTable.Add(const AId: Cardinal; AName: QStringW): TQSColumn;
begin
  Result := inherited Add(AId, AName) as TQSColumn;
end;

constructor TQSTable.Create(AOwner: TQSchemas);
begin
  inherited;
  FFlags := FFlags or SCHEMA_TABLE;
end;

function TQSTable.CreateItem: TQSchema;
begin
  Result := TQSColumn.Create(Owner);
end;

function TQSTable.FindById(const AId: Cardinal): TQSColumn;
begin
  Result := inherited FindById(AId) as TQSColumn;
end;

function TQSTable.FindByName(const AName: QStringW): TQSColumn;
begin
  Result := inherited FindByName(AName) as TQSColumn;
end;

function TQSTable.GetColumns(AIndex: Integer): TQSColumn;
begin
  Result := Items[AIndex] as TQSColumn;
end;

function TQSTable.GetDatabase: TQSDatabase;
var
  AParent: TQSchema;
begin
  AParent := FParent;
  Result := nil;
  while AParent <> nil do
  begin
    if AParent is TQSDatabase then
    begin
      Result := AParent as TQSDatabase;
      Break;
    end;
    AParent := AParent.FParent;
  end;
end;

function TQSTable.GetSchema: TQSchema;
var
  AParent: TQSchema;
begin
  AParent := FParent;
  Result := nil;
  while AParent <> nil do
  begin
    if AParent.ClassType = TQSchema then
    begin
      Result := AParent;
      Break;
    end;
    AParent := AParent.FParent;
  end;
end;

{ TQSType }

constructor TQSType.Create(AOwner: TQSchemas);
begin
  inherited;
  FFlags := FFlags or SCHEMA_TYPE;
end;

{ TQSTypes }

function TQSTypes.Add(AName: QStringW; const ATypeId, ABaseId,
  ASQLType: Cardinal; ASize: Smallint): TQSType;
begin
  Result := inherited Add(ATypeId, AName) as TQSType;
  Result.BaseId := ABaseId;
  Result.SQLType := ASQLType;
  Result.Size := ASize;
end;

constructor TQSTypes.Create(AOwner: TQSchemas);
begin
  inherited;
end;

function TQSTypes.CreateItem: TQSchema;
begin
  Result := TQSType.Create(Owner);
end;

function TQSTypes.FindById(const AId: Cardinal): TQSType;
begin
  Result := inherited FindById(AId) as TQSType;
end;

function TQSTypes.FindByName(const AName: QStringW): TQSType;
begin
  Result := inherited FindByName(AName) as TQSType;
end;

function TQSTypes.GetTypes(AIndex: Integer): TQSType;
begin
  Result := inherited Items[AIndex] as TQSType;
end;

{ TQIntervalField }

constructor TQIntervalField.Create(AOwner: TComponent);
begin
  inherited;
  SetDataType(ftOraInterval);
{$IF RTLVersion>=24}
  SetLength(FIOBuffer, SizeOf(TQInterval));
{$IFEND}
end;

function TQIntervalField.GetAsInterval: TQInterval;
begin
  GetValue(Result);
end;

function TQIntervalField.GetAsString: String;
var
  AValue: TQInterval;
begin
  if GetValue(AValue) then
    Result := AValue.AsString
  else
    Result := '';
end;

function TQIntervalField.GetAsVariant: Variant;
begin
  Result := GetAsString;
end;

function TQIntervalField.GetClassDesc: string;
begin
  Result := '(Interval)';
  if not IsNull then
    Result := AnsiUpperCase(Result);
end;

function TQIntervalField.GetValue(var AValue: TQInterval): Boolean;
begin
{$IF RTLVersion>=24}
  Result := GetData(FIOBuffer, True);
  if Result then
    Move(FIOBuffer[0], AValue, SizeOf(TQInterval))
  else
    AValue.Clear
{$ELSE}
  Result := GetData(@AValue, True);
  if not Result then
    AValue.Clear;
{$IFEND}
end;

procedure TQIntervalField.SetAsInterval(AValue: TQInterval);
begin
  SetValue(AValue);
end;

procedure TQIntervalField.SetAsString(const AValue: String);
var
  AInterval: TQInterval;
begin
  if AInterval.TryFromString(AValue) then
    SetValue(AInterval)
  else
    raise EConvertError.CreateFmt(SConvertError,
      [Value, FieldTypeNames[DataType]]);
end;

procedure TQIntervalField.SetSize(Value: Integer);
begin
  // Do nothing
end;

procedure TQIntervalField.SetValue(const AValue: TQInterval);
begin
{$IF RTLVersion>=24}
  Move(AValue, FIOBuffer[0], SizeOf(TQInterval));
  SetData(FIOBuffer);
{$ELSE}
  SetData(@AValue);
{$IFEND}
end;

procedure TQIntervalField.SetVarValue(const AValue: Variant);
begin
  SetAsString(VarToStr(AValue));
end;

{ TQMasterDataLink }

procedure TQMasterDataLink.ActiveChanged;
begin
  inherited;
  if not(GetDetailDataSet.Active or (csDestroying in DataSet.ComponentState))
  then
  begin
    if Assigned(OnMasterChange) then
      OnMasterChange(Self);
  end;
end;

procedure TQMasterDataLink.RecordChanged(Field: TField);
begin
  inherited;
  if (not GetDetailDataSet.Active) or (Fields.Count = 0) and
    Assigned(OnMasterChange) then
    OnMasterChange(Self);
end;

{ TQLibProvider }

procedure TQLibProvider.InternalClose;
begin
  if FHandle <> 0 then
  begin
    UnLoad;
    FreeLibrary(FHandle);
    FHandle := 0;
  end;
end;

procedure TQLibProvider.InternalOpen;
begin
  if FHandle = 0 then
  begin
    try
      FHandle := SafeLoadLibrary(FLibName);
      if FHandle <> 0 then
        LoadEntries;
    finally
    end;
  end;
end;

procedure TQLibProvider.SetLibName(const Value: string);
begin
  if FLibName <> Value then
  begin
    Close;
    FLibName := Value;
  end;
end;

{ TQSocketProvider }
procedure TQSocketProvider.ConnectionAborted;
begin
  inherited;
  if FHandle <> 0 then // 连接中断，释放Socket资源
  begin
{$IFDEF POSIX}
    __close(FHandle);
{$ELSE}
    closesocket(FHandle);
{$ENDIF}
    FHandle := 0;;
  end;
end;

constructor TQSocketProvider.Create(AOwner: TComponent);
begin
  inherited;
  FRecvBuf := TQBytesCatHelper.Create;
  FSendBuf := TQBytesCatHelper.Create;
  FConnectTimeout := 30;
end;

destructor TQSocketProvider.Destroy;
begin
  if FHandle <> 0 then
  begin
    Close;
    Workers.ClearSingleJob(FRecvJob);
  end;
  FreeObject(FRecvBuf);
  FreeObject(FSendBuf);
  inherited;
end;

procedure TQSocketProvider.DoRecv(AJob: PQJob);
var
  tv: TTimeVal;
  fdRead, fdExcept: TFdSet;
  AToRead, AReaded, rc: Integer;
begin
  try
    while (not AJob.IsTerminated) and (Connecting or Connected) do
    begin
      FD_Zero(fdRead);
      FD_Zero(fdExcept);
{$IFDEF POSIX}
      _FD_SET(FHandle, fdRead);
      _FD_SET(FHandle, fdExcept);
{$ELSE}
      fd_set(FHandle, fdRead);
      fd_set(FHandle, fdExcept);
{$ENDIF}
      tv.tv_sec := 0;
      tv.tv_usec := 1000;
      rc := select(FHandle + 1, @fdRead, nil, @fdExcept, @tv);
      if rc > 0 then
      begin
        if FD_ISSet(FHandle, fdRead) then
        begin
          AToRead := 0;
          AReaded := 0;
          if {$IFDEF MSWINDOWS}ioctlsocket{$ELSE}ioctl{$ENDIF}(FHandle,
            FIONREAD, AToRead) = 0 then
          // 得到缓冲区内容长度
          begin
            FRecvBuf.Capacity := FRecvBuf.Position + AToRead;
            while AToRead > 0 do
            begin
              AReaded := recv(FHandle, FRecvBuf.Current^, AToRead, 0);
              if AReaded > 0 then
              begin
                FRecvBuf.Position := FRecvBuf.Position + AReaded;
                Dec(AToRead, AReaded);
              end
              else
                Break;
            end;
            if AReaded > 0 then
              DispatchData;
          end;
        end
        else if FD_ISSet(FHandle, fdExcept) then
        begin
          RaiseLastOSError;
          Break;
        end;
      end
      else if rc < 0 then
      begin
        if (FHandle <> 0) and (not AJob.IsTerminated) then
        begin
          RaiseLastOSError;
          Break;
        end;
      end;
    end;
  finally
    if Connected then
      ConnectionAborted;
  end;
end;

function TQSocketProvider.GetServerHost: QStringW;
begin
  Result := Params.Values['host'];
end;

function TQSocketProvider.GetServerPort: Word;
var
  S: QStringW;
  V: Integer;
begin
  S := Params.Values['port'];
  if (Length(S) > 0) and TryStrToInt(S, V) then
    Result := V
  else
    Result := FDefaultPort;
end;

procedure TQSocketProvider.HandleNeeded;
var
  Addr: TSockAddrIn;
  AHost: TInAddr;
begin
  if FHandle = 0 then
  begin
    AHost := RemoteAddr;
    FHandle := socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
    if FHandle = 0 then
      RaiseLastOSError;
    Addr.sin_family := AF_INET;
    Addr.sin_port := ExchangeByteOrder(ServerPort);
    Addr.sin_addr := AHost;
    PInt64(@Addr.sin_zero[0])^ := 0;
    if connect(FHandle,
{$IFDEF POSIX}sockaddr{$ELSE}sockaddr_in{$ENDIF}(Addr), SizeOf(TSockAddrIn)) = SOCKET_ERROR
    then
    begin
      SetError(GetLastError, SysErrorMessage(GetLastError));
{$IFDEF POSIX}
      __close(FHandle);
{$ELSE}
      closesocket(FHandle);
{$ENDIF}
      FHandle := 0;
      DatabaseError(LastErrorMsg);
    end;
    // 启动接收线程
    FRecvJob := Workers.LongtimeJob(DoRecv, nil);
  end;
end;

procedure TQSocketProvider.Handshake;
begin

end;

procedure TQSocketProvider.InternalClose;
begin
  if FHandle <> 0 then
  begin
    Workers.ClearSingleJob(FRecvJob);
    FRecvJob := 0;
{$IFDEF POSIX}
    __close(FHandle);
{$ELSE}
    closesocket(FHandle);
{$ENDIF}
    FHandle := 0;
  end;
end;

procedure TQSocketProvider.InternalOpen;
begin
  // 初始化握手
  SetError(0, '');
  Handshake;
  // 登录
  Login;
end;

procedure TQSocketProvider.Login;
begin

end;

function TQSocketProvider.RemoteAddr: TInAddr;
var
  S: QStringW;
  AEntry: PHostEnt;
  I: Integer;
  pIP: PPointer;
  AIPList: array of Integer;
begin
  S := ServerHost;
  if not TryStrToIPV4(S, Result.S_addr) then
  begin
    AEntry := gethostbyname(Pointer(PQCharA(AnsiEncode(S))));
    if Assigned(AEntry) then
    begin
      // 如果有多个IP，则随机选择一个
      randomize;
      SetLength(AIPList, 64);
      I := 0;
      pIP := PPointer(AEntry.h_addr_list);
      while pIP^ <> nil do
      begin
        AIPList[I] := PInteger(pIP^)^;
        Inc(I);
        Inc(pIP);
        if I = 64 then // 最多取前64个
          Break;
      end;
      Result.S_addr := AIPList[random(I)];
    end
    else
      RaiseLastOSError;
  end;
end;

function TQSocketProvider.SendData: Boolean;
var
  ASent, ASize: Integer;
  ABuf: PByte;
  AErrorCode: DWORD;
begin
  HandleNeeded;
  ASize := SendBuffer.Position;
  ABuf := SendBuffer.Start;
  Result := True;
  while ASize > 0 do
  begin
    ASent := send(FHandle, ABuf^, ASize, 0);
    if ASent <> SOCKET_ERROR then
    begin
      Dec(ASize, ASent);
      Inc(ABuf, ASent);
    end
    else
    begin
      AErrorCode := GetLastError;
      ConnectionAborted;
      SetError(AErrorCode, SysErrorMessage(AErrorCode));
      Result := False;
      Break;
    end;
  end;
  SendBuffer.Reset;
end;

procedure TQSocketProvider.SendRequest(ARequest: TQSQLRequest);
begin

end;

procedure TQSocketProvider.SetServerHost(const Value: QStringW);
begin
  Params.Values['host'] := Value;
end;

procedure TQSocketProvider.SetServerPort(const Value: Word);
begin
  Params.Values['port'] := IntToStr(Integer(Value));
end;

procedure SocketInit;
{$IFDEF MSWINDOWS}
var
  AData: WSAData;
{$ENDIF}
begin
{$IFDEF MSWINDOWS}
  if WSAStartup(MakeWord(1, 1), AData) <> 0 then
    RaiseLastOSError(WSAGetLastError);
{$ENDIF}
end;

procedure SocketCleanup;
begin
{$IFDEF MSWINDOWS}
  WSACleanup;
{$ENDIF}
end;

{ TQBlobField }

function TQBlobField.GetAsString: String;
var
  AStream: TStream;
begin
  AStream := DataSet.CreateBlobStream(Self, bmRead);
  try
    Result := LoadTextW(AStream, FTextEncoding);
  finally
    FreeAndNil(AStream);
  end;
end;

initialization

QDataSetPool := TQSimplePool.Create(1024, SizeOf(TObject));
QDataSetPool.OnNewItem := Pool_MakeNewItemProc(DoNewDataSetItem);
QDataSetPool.OnFree := Pool_MakeNotifyProc(DoFreeDataSetItem);
QDataSetPool.OnReset := Pool_MakeNotifyProc(DoResetDataSetItem);
SocketInit;

finalization

SocketCleanup;
FreeAndNil(QDataSetPool);

end.
