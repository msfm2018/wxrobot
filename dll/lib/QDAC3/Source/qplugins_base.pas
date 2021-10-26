unit qplugins_base;

interface

uses classes, sysutils, types, syncobjs;

const
  SQPluginsVersion = '3.1'; { 版本号，当前为3.1版  }
  { 日志级别：紧急 }
  LOG_EMERGENCY: BYTE = 0;
  /// <summary>
  /// 日志级别-警报
  /// </summary>
  LOG_ALERT = 1;
  /// <summary>
  /// 日志级别-致命错误
  /// </summary>
  LOG_FATAL = 2;
  /// <summary>
  /// 日志级别-错误
  /// </summary>
  LOG_ERROR = 3;
  /// <summary>
  /// 日志级别-警告
  /// </summary>
  LOG_WARN = 4;
  /// <summary>
  /// 日志级别-提示
  /// </summary>
  LOG_HINT = 5;
  /// <summary>
  /// 日志级别-消息
  /// </summary>
  LOG_MESSAGE = 6;
  /// <summary>
  /// 日志级别-调试信息
  /// </summary>
  LOG_DEBUG = 7;

  /// <summary>
  /// 预定义通知的ID-服务管理器被替换（这个通知只需要进程内插件响应） <br />
  /// </summary>
  NID_MANAGER_REPLACED = 0;
  /// <summary>
  /// 预定义通知的ID
  /// </summary>
  NID_MANAGER_FREE = 1; // 插件管理器需要被立即释放
  /// <summary>
  /// 预定义通知的ID-正在启动加载器
  /// </summary>
  NID_LOADERS_STARTING = 2; //
  /// <summary>
  /// 预定义通知的ID-启动器加载完成
  /// </summary>
  NID_LOADERS_STARTED = 3; //
  /// <summary>
  /// 预定义通知的ID-启动器停止中
  /// </summary>
  NID_LOADERS_STOPPING = 4;
  /// <summary>
  /// 预定义通知的ID-启动器已停止
  /// </summary>
  NID_LOADERS_STOPPED = 5;
  /// <summary>
  /// 预定义通知的ID-启动器加载/停止进度
  /// </summary>
  NID_LOADERS_PROGRESS = 6;
  /// <summary>
  /// 预定义通知的ID-启动器加载出错
  /// </summary>
  NID_LOADER_ERROR = 7; //
  /// <summary>
  /// 预定义通知的ID-正在加载插件
  /// </summary>
  NID_PLUGIN_LOADING = 8; //
  /// <summary>
  /// 预定义通知的ID-加载插件完成
  /// </summary>
  NID_PLUGIN_LOADED = 9; //
  /// <summary>
  /// 预定义通知的ID-服务准备卸载
  /// </summary>
  NID_PLUGIN_UNLOADING = 10; //
  /// <summary>
  /// 预定义通知的ID-服务卸载完成
  /// </summary>
  NID_PLUGIN_UNLOADED = 11; //
  /// <summary>
  /// 预定义通知的ID-通知将要被处理
  /// </summary>
  NID_NOTIFY_PROCESSING = 12; //
  /// <summary>
  /// 预定义通知的ID-通知已经处理完成
  /// </summary>
  NID_NOTIFY_PROCESSED = 13; //
  /// <summary>
  /// 预定义通知的ID-等待的服务已经注册完成
  /// </summary>
  NID_SERVICE_READY = 14; //

type
  /// <summary>
  /// 标准接口结果定义，这个是为了与其它语言兼容兼容时使用，Delphi 本身不需要使用此版本接口
  /// </summary>
  StandInterfaceResult = Pointer;
  /// <summary>
  /// 异步执行回调全局函数接口定义
  /// </summary>
  TQAsynProcG = procedure(AParams: IInterface); stdcall;
  /// <summary>
  /// 异步回调事件定义，仅适用于 Delphi
  /// </summary>
  TQAsynProc = procedure(AParasm: IInterface) of object; // Delphi only

  /// <summary>
  /// 动态字节数组接口
  /// </summary>
  /// <remarks>
  /// 动态字节数组用于二进制数据的存贮或缓冲区管理
  /// </remarks>
  IQBytes = interface
    ['{8C570D86-517F-4729-8C5F-427F3F6A414B}']
    /// <summary>
    /// 设置字节数组长度
    /// </summary>
    procedure SetLength(const len: DWORD); stdcall;
    /// <summary>
    /// 获取字节数组长度
    /// </summary>
    function GetLength: DWORD; stdcall;
    /// <summary>
    /// 获取指定的字节的值
    /// </summary>
    /// <param name="idx">
    /// 要获取的字节的0基的索引位置
    /// </param>
    /// <param name="value">
    /// 字节值
    /// </param>
    /// <returns>
    /// 如果索引位置有效，返回true，并设置 value 的值，否则返回false
    /// </returns>
    function GetByte(const idx: DWORD; var value: BYTE): Boolean; stdcall;
    /// <summary>
    /// 设置指定位置的字节内容
    /// </summary>
    /// <param name="idx">
    /// 要设置的字节的0基的索引位置
    /// </param>
    /// <param name="value">
    /// 要设置的字节值
    /// </param>
    /// <returns>
    /// 如果索引位置有效替换并返回true，如果索引位置无效，则返回false
    /// </returns>
    function SetByte(const idx: DWORD; const value: BYTE): Boolean; stdcall;
    /// <summary>
    /// 获取内部数据内容的首地址
    /// </summary>
    /// <returns>
    /// 返回内容数据内容的首地址
    /// </returns>
    function GetData: Pointer; stdcall;
    /// <summary>
    /// 设置内部数组的容量
    /// </summary>
    /// <param name="len">
    /// 容易大小，以字节计数
    /// </param>
    /// <remarks>
    /// 注意它和Length的区别，Length 是实际存贮的有效数据内容大小，Capacity
    /// 是存贮区域占用的内存大小，Length始终小于等于Capacity。
    /// </remarks>
    procedure SetCapacity(const len: DWORD); stdcall;
    /// <summary>
    /// 获取内部数组的容量
    /// </summary>
    /// <returns>
    /// 返回当前分配的实际内存大小
    /// </returns>
    function GetCapcacity: DWORD; stdcall;
    /// <summary>
    /// 追加指定长度的数据
    /// </summary>
    /// <param name="src">
    /// 源数据地址
    /// </param>
    /// <param name="len">
    /// 要复制的数据内容长度
    /// </param>
    procedure Append(const src: Pointer; const len: DWORD); stdcall;
    /// <summary>
    /// 在指定的位置开始，插入指定长度的内容
    /// </summary>
    /// <param name="idx">
    /// 0基的起始位置
    /// </param>
    /// <param name="src">
    /// 源地址
    /// </param>
    /// <param name="len">
    /// 要插入的内容长度
    /// </param>
    procedure Insert(const idx: DWORD; const src: Pointer;
      const len: DWORD); stdcall;
    /// <summary>
    /// 从指定的位置开始，替换指定长度的内容
    /// </summary>
    /// <param name="idx">
    /// 0基的起始位置
    /// </param>
    /// <param name="src">
    /// 源地址
    /// </param>
    /// <param name="len">
    /// 要替换的内容长度
    /// </param>
    procedure Replace(const idx: DWORD; const src: Pointer;
      const len: DWORD); stdcall;
    /// <summary>
    /// 从指定的位置开始，删除特定长度的内容
    /// </summary>
    /// <param name="idx">
    /// 0基的起始位置
    /// </param>
    /// <param name="Count">
    /// 要删除的内容长度
    /// </param>
    procedure Delete(const idx: DWORD; const Count: DWORD); stdcall;
    /// <summary>
    /// 复制指定的内容到目标缓冲区
    /// </summary>
    /// <param name="dest">
    /// 目标缓冲区，请确定目标位置至少有足够区域存贮目标内容
    /// </param>
    /// <param name="idx">
    /// 起始位置
    /// </param>
    /// <param name="Count">
    /// 要复制的内容长度
    /// </param>
    /// <returns>
    /// 返回实际复制的内容长度
    /// </returns>
    function CopyTo(dest: Pointer; const idx, Count: DWORD): DWORD; stdcall;
    /// <summary>
    /// 从文件中加载数据内容
    /// </summary>
    /// <param name="fileName">
    /// 源文件名
    /// </param>
    procedure LoadFromFile(const fileName: PWideChar); stdcall;
    /// <summary>
    /// 保存内容到文件中
    /// </summary>
    /// <param name="fileName">
    /// 目标文件名
    /// </param>
    procedure SaveToFile(const fileName: PWideChar); stdcall;
    /// <summary>
    /// 追加到目标文件中
    /// </summary>
    /// <param name="fileName">
    /// 目标文件名
    /// </param>
    procedure AppendToFile(const fileName: PWideChar); stdcall;
  end;

  // 基础类型定义
  // 流
  /// <summary>
  /// 流接口
  /// </summary>
  IQStream = interface
    ['{BCFD2F69-CCB8-4E0B-9FE9-A7D58797D1B8}']
    /// <summary>
    /// 从流中读取指定字节的数据
    /// </summary>
    /// <param name="pv">
    /// 要存放读取数据的目标地址
    /// </param>
    /// <param name="cb">
    /// 要读取的字节数
    /// </param>
    /// <returns>
    /// 实际读取的字节数
    /// </returns>
    function Read(pv: Pointer; cb: Cardinal): Cardinal; stdcall;
    /// <summary>
    /// 写入指定长度的数据到流中
    /// </summary>
    /// <param name="pv">
    /// 要写入的源数据地址
    /// </param>
    /// <param name="cb">
    /// 要写入的数据长度
    /// </param>
    /// <returns>
    /// 返回实际写入的字节数
    /// </returns>
    function Write(pv: Pointer; cb: Cardinal): Cardinal; stdcall;
    /// <summary>
    /// 定位到数据流的指定位置
    /// </summary>
    /// <param name="AOffset">
    /// 偏移量
    /// </param>
    /// <param name="AFrom">
    /// 偏移相对值
    /// </param>
    /// <returns>
    /// 返回定位后的实际位置
    /// </returns>
    function Seek(AOffset: Int64; AFrom: BYTE): Int64; stdcall;
    /// <summary>
    /// 设置流的大小
    /// </summary>
    /// <param name="ANewSize">
    /// 新的大小
    /// </param>
    procedure SetSize(ANewSize: UInt64); stdcall;
    /// <summary>
    /// 从另一个流中复制指定长度的内容到当前流的当前位置
    /// </summary>
    /// <param name="AStream">
    /// 源数据流
    /// </param>
    /// <param name="ACount">
    /// 要复制的内容长度，如果为0，则复制整个数据流
    /// </param>
    /// <returns>
    /// 返回实际复制的字节数
    /// </returns>
    function CopyFrom(AStream: IQStream; ACount: Int64): Int64; stdcall;
  end;

  /// <summary>
  /// 参数规格化，用于使用不同语言之间交互
  /// </summary>
  TQParamType = (
    /// <summary>
    /// 未知类型
    /// </summary>
    ptUnknown,
    // Integer Types
    /// <summary>
    /// 8位整数
    /// </summary>
    ptInt8,
    /// <summary>
    /// 8位无符号整数
    /// </summary>
    ptUInt8,
    /// <summary>
    /// 16位整数
    /// </summary>
    ptInt16,
    /// <summary>
    /// 16位无符号整数
    /// </summary>
    ptUInt16,
    /// <summary>
    /// 32位整
    /// </summary>
    ptInt32,
    /// <summary>
    /// 32位无符号整数
    /// </summary>
    ptUInt32,
    /// <summary>
    /// 64位整数
    /// </summary>
    ptInt64,
    /// <summary>
    /// 64位无符号整数
    /// </summary>
    ptUInt64,
    /// <summary>
    /// 浮点数
    /// </summary>
    ptFloat4,
    /// <summary>
    /// 双精度浮点数
    /// </summary>
    ptFloat8, // Float types
    /// <summary>
    /// 日期时间
    /// </summary>
    ptDateTime,
    /// <summary>
    /// 时间间隔
    /// </summary>
    ptInterval, // DateTime types
    /// <summary>
    /// Ansi 编码的字符串
    /// </summary>
    ptAnsiString,
    /// <summary>
    /// UTF8 编码字符串
    /// </summary>
    ptUtf8String,
    /// <summary>
    /// Unicode 16 LE 编码字符串
    /// </summary>
    ptUnicodeString, // String types
    /// <summary>
    /// 布尔
    /// </summary>
    ptBoolean, // Boolean
    /// <summary>
    /// 全局唯一编码
    /// </summary>
    ptGuid, // Guid
    /// <summary>
    /// 字节流
    /// </summary>
    ptBytes, // Binary
    /// <summary>
    /// 流
    /// </summary>
    ptStream, // 流
    /// <summary>
    /// 数组
    /// </summary>
    ptArray, // Array
    /// <summary>
    /// 接口
    /// </summary>
    ptInterface);
  IQParams = interface;

  /// <summary>
  /// 字符串接口，用于一些不适合直接使用字符串指针的场景使用
  /// </summary>
  IQString = interface
    ['{B2FB1524-A06D-47F6-AA85-87C2251F2FCF}']
    /// <summary>
    /// 设置字符串内容
    /// </summary>
    /// <param name="S">
    /// 源字符串
    /// </param>
    procedure SetValue(const S: PWideChar); stdcall;
    /// <summary>
    /// 获取字符串内容
    /// </summary>
    /// <returns>
    /// 返回Unicode 16 LE 编码的字符串内容
    /// </returns>
    function GetValue: PWideChar; stdcall;
    /// <summary>
    /// 获取字符串长度
    /// </summary>
    /// <returns>
    /// 返回当前内容长度，注意扩展区字符每个返回长度为2
    /// </returns>
    function GetLength: Integer; stdcall;
    /// <summary>
    /// 设置字符串长度，注意如果是包含扩展区字符，每个扩展区字符长度为2
    /// </summary>
    /// <param name="ALen">
    /// 新长度
    /// </param>
    /// <remarks>
    /// 如果设置的长度大于当前长度，多出的部分将被填充为0，反之会被直接截断
    /// </remarks>
    procedure SetLength(ALen: Integer); stdcall;
    property Value: PWideChar read GetValue write SetValue;
    property Length: Integer read GetLength write SetLength;
  end;

  /// <summary>
  /// IQString 的扩展支持，暂未全部实现，将来根据需要实现
  /// </summary>
  IQStringEx = interface(IQString)
    ['{54BF45E6-0D9F-4E66-9AA3-87974FB50893}']
    function Left(const AMaxCount: Cardinal; const ACheckExt: Boolean)
      : IQString; stdcall;
    function Right(const AMaxCount: Cardinal; const ACheckExt: Boolean)
      : IQString; stdcall;
    function SubString(const AStart, ACount: Cardinal; const ACheckExt: Boolean)
      : IQString; stdcall;
    function Replace(const oldpat, newpat: PWideChar; AFlags: Integer): Cardinal;
    // Todo:Add more function
  end;

  // 单个参数
  IQParam = interface
    ['{8641FD44-1BC3-4F04-B730-B5406CDA17E3}']
    /// <summary>
    /// 获取参数的名称
    /// </summary>
    function GetName: PWideChar; stdcall;
    /// <summary>
    /// 以32位整数方式获取当前参数的值
    /// </summary>
    function GetAsInteger: Integer; stdcall;
    /// <summary>
    /// 以32位整数方式设置当前的值
    /// </summary>
    procedure SetAsInteger(const AValue: Integer); stdcall;
    /// <summary>
    /// 以64位整数的方式，获取当前参数的值
    /// </summary>
    function GetAsInt64: Int64; stdcall;
    /// <summary>
    /// 以64位整数方式设置当前参数的值
    /// </summary>
    procedure SetAsInt64(const AValue: Int64); stdcall;
    /// <summary>
    /// 以布尔值获取当前参数的值
    /// </summary>
    function GetAsBoolean: Boolean; stdcall;
    /// <summary>
    /// 以布尔值类型设置当前参数的值
    /// </summary>
    procedure SetAsBoolean(const AValue: Boolean); stdcall;
    /// <summary>
    /// 以单精度浮点数类型来获取当前参数的值
    /// </summary>
    function GetAsSingle: Single; stdcall;
    /// <summary>
    /// 以单精度浮点数类型来设置当前参数的值
    /// </summary>
    procedure SetAsSingle(const AValue: Single); stdcall;
    /// <summary>
    /// 以双精度浮点数来获取当前参数的值
    /// </summary>
    function GetAsFloat: Double; stdcall;
    /// <summary>
    /// 以双精度浮点数来设置当前参数的值
    /// </summary>
    procedure SetAsFloat(const AValue: Double); stdcall;
    /// <summary>
    /// 以字符串形式来获取当前参数的值
    /// </summary>
    function GetAsString: IQString; stdcall;
    /// <summary>
    /// 以字符串形式设置当前参数的值
    /// </summary>
    procedure SetAsString(const AValue: IQString); stdcall;
    /// <summary>
    /// 以GUID类型来获取当前参数的值
    /// </summary>
    function GetAsGuid: TGuid; stdcall;
    /// <summary>
    /// 以GUID类型设置当前参数的值
    /// </summary>
    procedure SetAsGuid(const value: TGuid); stdcall;
    /// <summary>
    /// 获取字节类型的数据内容到目标缓冲区中
    /// </summary>
    /// <param name="ABuf">
    /// 缓冲区地址
    /// </param>
    /// <param name="ABufLen">
    /// 缓冲区大小
    /// </param>
    /// <returns>
    /// 返回实际填充的字节数
    /// </returns>
    function GetAsBytes(ABuf: PByte; ABufLen: Cardinal): Cardinal;
      overload; stdcall;
    /// <summary>
    /// 从指定的地址设置字节类型的数据内容
    /// </summary>
    /// <param name="ABuf">
    /// 源缓冲区
    /// </param>
    /// <param name="ABufLen">
    /// 内容长度
    /// </param>
    procedure SetAsBytes(ABuf: PByte; ABufLen: Cardinal); overload; stdcall;
    /// <summary>
    /// 判断当前参数内容是否是空（未赋过值）
    /// </summary>
    function GetIsNull: Boolean; stdcall;
    /// <summary>
    /// 设置当前参数内容为空
    /// </summary>
    procedure SetNull; stdcall;
    /// <summary>
    /// 以数组方式来获取子参数列表对象
    /// </summary>
    /// <remarks>
    /// 参数的类型必需是ptArray
    /// </remarks>
    function GetAsArray: IQParams; stdcall;
    /// <summary>
    /// 以流的方式获取当前参数的值
    /// </summary>
    /// <returns>
    /// 返回关联的流对象
    /// </returns>
    function GetAsStream: IQStream; stdcall;
    /// <summary>
    /// 设置当前参数的数据流内容
    /// </summary>
    procedure SetAsStream(AStream: IQStream); stdcall;
    /// <summary>
    /// 获取当前参数所隶属的父列表
    /// </summary>
    function GetParent: IQParams; overload; stdcall;
    /// <summary>
    /// 获取当前参数的类型
    /// </summary>
    function GetType: TQParamType; stdcall;
    /// <summary>
    /// 修改当前参数的类型
    /// </summary>
    procedure SetType(const AType: TQParamType); stdcall;
    /// <summary>
    /// 获取当前参数的接口类型的值
    /// </summary>
    function GetAsInterface: IInterface; overload; stdcall;
    /// <summary>
    /// 设置当前参数的接口类型的值
    /// </summary>
    procedure SetAsInterface(const AIntf: IInterface); stdcall;
    /// <summary>
    /// 获取当前参数在父列表中的索引
    /// </summary>
    function GetIndex: Integer; stdcall;
    /// <summary>
    /// 获取当前字节数组类型的内容
    /// </summary>
    function GetAsBytes: IQBytes; overload; stdcall;
    /// <summary>
    /// 设置当前字节数组类型的参数内容
    /// </summary>
    procedure SetAsBytes(const ABytes: IQBytes); overload; stdcall;
    // 下面的代码为了兼容其它语言加入
    function _GetAsArray: StandInterfaceResult; stdcall;
    function _GetAsStream: StandInterfaceResult; stdcall;
    function _GetParent: StandInterfaceResult; overload; stdcall;
    function _GetAsInterface: StandInterfaceResult; overload; stdcall;
    function _GetAsBytes: StandInterfaceResult; overload; stdcall;
    property AsInteger: Integer read GetAsInteger write SetAsInteger;
    property AsInt64: Int64 read GetAsInt64 write SetAsInt64;
    property AsBoolean: Boolean read GetAsBoolean write SetAsBoolean;
    property AsSingle: Single read GetAsSingle write SetAsSingle;
    property AsFloat: Double read GetAsFloat write SetAsFloat;
    property AsGuid: TGuid read GetAsGuid write SetAsGuid;
    property IsNull: Boolean read GetIsNull;
    property Name: PWideChar read GetName;
    property AsArray: IQParams read GetAsArray;
    property AsStream: IQStream read GetAsStream write SetAsStream;
    property AsString: IQString read GetAsString write SetAsString;
    property Parent: IQParams read GetParent;
    property ParamType: TQParamType read GetType;
    property AsInterface: IInterface read GetAsInterface write SetAsInterface;
    property Index: Integer read GetIndex;
  end;

  /// <summary>
  /// 参数列表接口，用于管理多个参数
  /// </summary>
  IQParams = interface
    ['{B5746B65-7586-4DED-AE20-D4FF9B6ECD9E}']
    /// <summary>
    /// 获取指定索引的参数
    /// </summary>
    /// <param name="AIndex">
    /// 要获取的参数索引
    /// </param>
    function GetItems(AIndex: Integer): IQParam; overload; stdcall;
    /// <summary>
    /// 获取列表中的参数个数
    /// </summary>
    function GetCount: Integer; stdcall;
    /// <summary>
    /// 获取指定名称的参数
    /// </summary>
    /// <param name="AName">
    /// 要获取的参数名称，区分大小写
    /// </param>
    /// <returns>
    /// 找到，返回该实例，未找到，返回空
    /// </returns>
    function ByName(const AName: PWideChar): IQParam; stdcall;
    /// <summary>
    /// 获取指定路径的参数
    /// </summary>
    /// <param name="APath">
    /// 参数路径，名称之间通过/分隔，注意名称区分大小写
    /// </param>
    function ByPath(APath: PWideChar): IQParam; stdcall;
    /// <summary>
    /// 添加一个参数
    /// </summary>
    /// <param name="AName">
    /// 参数名称
    /// </param>
    /// <param name="AParamType">
    /// 参数类型
    /// </param>
    function Add(const AName: PWideChar; AParamType: TQParamType): IQParam;
      overload; stdcall;
    /// <summary>
    /// 添加一个列表做为参数
    /// </summary>
    /// <param name="AName">
    /// 参数名称
    /// </param>
    /// <param name="AChildren">
    /// 要复制的参数来源
    /// </param>
    /// <remarks>

    /// 这个函数并不会直接将AChildren做为子结点，而是创建它的复制品，所以AChildren在使用完成后可以简单释放。但参数中如果有流、接口等类型的参数，则会直接使用相应的接口。
    /// </remarks>
    function Add(const AName: PWideChar; AChildren: IQParams): IQParam;
      overload; stdcall;
    /// <summary>
    /// 将整个列表当做字符串来访问
    /// </summary>
    /// <remarks>
    /// 返回的字符串内容为JSON格式
    /// </remarks>
    function GetAsString: IQString; stdcall;
    /// <summary>
    /// 删除指定索引的参数
    /// </summary>
    /// <param name="AIndex">
    /// 要删除的参数的索引
    /// </param>
    procedure Delete(AIndex: Integer); stdcall;
    /// <summary>
    /// 清除所有的参数
    /// </summary>
    procedure Clear; stdcall;
    /// <summary>
    /// 返回指定参数的索引
    /// </summary>
    /// <param name="AParam">
    /// 要检查的参数
    /// </param>
    /// <returns>
    /// 返回实际的索引值，如果未找到返回-1
    /// </returns>
    function IndexOf(const AParam: IQParam): Integer; stdcall;
    /// <summary>
    /// 将参数保存到流中 <br />
    /// </summary>
    /// <param name="AStream">
    /// 目标数据流
    /// </param>
    procedure SaveToStream(AStream: IQStream); stdcall;
    /// <summary>
    /// 从流中加载参数列表
    /// </summary>
    /// <param name="AStream">
    /// 参数源流
    /// </param>
    procedure LoadFromStream(AStream: IQStream); stdcall;
    /// <summary>
    /// 保存参数列表内容到文件
    /// </summary>
    /// <param name="AFileName">
    /// 目标文件名
    /// </param>
    procedure SaveToFile(const AFileName: PWideChar); stdcall;
    /// <summary>
    /// 从文件中加载参数列表
    /// </summary>
    /// <param name="AFileName">
    /// 源文件名
    /// </param>
    procedure LoadFromFile(const AFileName: PWideChar); stdcall;

    function _GetItems(AIndex: Integer): StandInterfaceResult;
      overload; stdcall;
    function _ByName(const AName: PWideChar): StandInterfaceResult; stdcall;
    function _ByPath(APath: PWideChar): StandInterfaceResult; stdcall;
    function _Add(const AName: PWideChar; AParamType: TQParamType)
      : StandInterfaceResult; overload; stdcall;
    function _Add(const AName: PWideChar; AChildren: IQParams)
      : StandInterfaceResult; overload; stdcall;
    function _GetAsString: StandInterfaceResult; stdcall;

    property Items[AIndex: Integer]: IQParam read GetItems; default;
    property Count: Integer read GetCount;
    property AsString: IQString read GetAsString;
  end;

  /// <summary>
  /// 版本信息,Major 为主版本号，Minor为副版本号，Release为发布版本号，Build为构建版本号，每个都不能大于255
  /// </summary>
  TQShortVersion = packed record
    case Integer of
      0:
        (Major, Minor, Release, Build: BYTE
        ); // 主、副、发布、构建的版本号
      1:
        (Value: Integer);
  end;
{$IF RTLVersion>=21}
{$M+}
{$IFEND}

  /// <summary>
  /// 完整的插件版本信息结构
  /// </summary>
  TQVersion = packed record
    /// <summary>
    /// 版本
    /// </summary>
    Version: TQShortVersion; //
    /// <summary>
    /// 提供插件的公司名
    /// </summary>
    Company: array [0 .. 63] of WideChar; //
    /// <summary>
    /// 模块名称
    /// </summary>
    Name: array [0 .. 63] of WideChar; //
    /// <summary>
    /// 描述
    /// </summary>
    Description: array [0 .. 255] of WideChar; //
    /// <summary>
    /// 原始文件名
    /// </summary>
    FileName: array [0 .. 259] of WideChar; //
  end;

  //
  /// <summary>
  /// 版本信息接口
  /// </summary>
  IQVersion = interface
    ['{4AD82500-4148-45D1-B0F8-F6B6FB8B7F1C}']
    /// <summary>
    /// 获取版本信息
    /// </summary>
    /// <param name="AVerInfo">
    /// 用于返回版本信息的结构体
    /// </param>
    /// <returns>
    /// 插件或服务有版本信息，则返回true，否则返回false
    /// </returns>
    function GetVersion(var AVerInfo: TQVersion): Boolean; stdcall;
  end;

  IQServices = interface;
  IQLoader = interface;

  /// <summary>
  /// 服务扩展多实例接口
  /// </summary>
  /// <remarks>
  /// 与服务本身不一样，服务接口本身就有GetInstance方法，而作为服务的扩展，其只要求继承自IUnknown(也叫IInterface)，所以需要额外的判定以确定是否直接返回它的实例自身
  /// </remarks>
  IQMultiInstanceExtension = interface
    ['{A13CADF7-96EE-4B95-B3CA-1476EBC19A41}']
    function GetInstance(var AResult: IInterface): Boolean; stdcall;
  end;

  /// <summary>
  /// 普通服务接口定义
  /// </summary>
  /// <remarks>
  /// 普通服务用于完成某项特定的功能。一个插件可以注册 n 个服务（n&gt;=0），每个服务都至少要提供 IQService
  /// 相关的信息，以便进行管理
  /// </remarks>
  IQService = interface
    ['{0DA5CBAC-6AB0-49FA-B845-FDF493D9E639}']
    /// <summary>
    /// 获取用于提供服务的实例
    /// </summary>
    /// <returns>
    /// 返回用于提供服务的实例，如果是单实例服务，则返回自身，如果是多实例服务，则会创建一个新的实例用于提供实际的服务
    /// </returns>
    function GetInstance: IQService; stdcall;
    /// <summary>
    /// 获取服务提供者模块句柄
    /// </summary>
    /// <returns>
    /// 返回模块句柄，同一个句柄代表是同一个插件提供的服务
    /// </returns>
    /// <remarks>

    /// 这个句柄的具体含义取决于对应的加载器，比如对于DLL/SO类型的插件，它就是调用LoadLibrary返回的句柄，对于BPL，它就是LoadPackage返回的句柄
    /// </remarks>
    function GetOwnerInstance: THandle; stdcall;
    /// <summary>
    /// 执行服务并将结果返回到AResult中
    /// </summary>
    /// <param name="AParams">
    /// 传递给服务的参数
    /// </param>
    /// <param name="AResult">
    /// 服务的返回值
    /// </param>
    /// <returns>
    /// 执行成功，返回true，执行失败，返回false
    /// </returns>
    /// <remarks>
    /// 实际服务并不一定会通过这个接口来提供具体的服务，对于不支持的服务，会直接返回false，它们会通过直接支持其它接口的方式来提供具体的服务。
    /// </remarks>
    function Execute(AParams: IQParams; AResult: IQParams): Boolean; stdcall;
    /// <summary>
    /// 暂停服务
    /// </summary>
    /// <param name="AParams">
    /// 暂停服务参数
    /// </param>
    /// <returns>
    /// 成功，返回 true，失败或不受支持，返回false
    /// </returns>
    function Suspended(AParams: IQParams): Boolean; stdcall;
    /// <summary>
    /// 恢复当前服务执行
    /// </summary>
    /// <param name="AParams">
    /// 恢复服务参数
    /// </param>
    /// <returns>
    /// 如果调用完成后服务处于执行状态，则返回true，否则返回false
    /// </returns>
    function Resume(AParams: IQParams): Boolean; stdcall;
    /// <summary>
    /// 获取服务所隶属的父服务列表接口实例
    /// </summary>
    function GetParent: IQServices; stdcall;
    /// <summary>
    /// 获取服务的创建者服务接口实例
    /// </summary>
    /// <returns>
    /// 返回服务的创建者服务
    /// </returns>
    /// <remarks>

    /// 对于多实例服务，其创建者被注册到QPlugins，一旦请求服务时，通过GetInstance会创建一个新实例，这个新实例的服务创建者就是注册到QPlugins中的服务创建者接口实例
    /// </remarks>
    function GetInstanceCreator: IQService; stdcall;
    /// <summary>
    /// 为服务添加一个额外扩展
    /// </summary>
    /// <param name="AInterface">
    /// 要添加的新服务接口实例
    /// </param>
    /// <remarks>
    /// 1、服务扩展主要为服务扩展新功能，如果要支持多实例，需要实现IQMultiInstanceExtension接口； <br />
    /// 2、如果要通过扩展实现服务的热替换，则服务的QueryInterface 实现应优先检查扩展中是否提供了相应接口的实现； <br />
    /// 3、服务的热替换并不会替换正在执行的服务，而只对后续请求生效。要对当前使用中服务生效，则需要调用者支持；
    /// </remarks>
    procedure AddExtension(AInterface: IInterface); stdcall;

    /// <summary>
    /// 移除一个已经注册的扩展
    /// </summary>
    procedure RemoveExtension(AInterface: IInterface); stdcall;
    /// <summary>
    /// 设置服务的父服务列表
    /// </summary>
    procedure SetParent(AParent: IQServices); stdcall;
    /// <summary>
    /// 获取服务名称
    /// </summary>
    function GetName: PWideChar; stdcall;
    /// <summary>
    /// 获取服务的扩展属性
    /// </summary>
    function GetAttrs: IQParams; stdcall;
    /// <summary>
    /// 获取末次错误信息内容
    /// </summary>
    function GetLastErrorMsg: PWideChar; stdcall;
    /// <summary>
    /// 获取末次错误代码
    /// </summary>
    function GetLastErrorCode: Cardinal; stdcall;
    /// <summary>
    /// 获取服务的ID
    /// </summary>
    function GetId: TGuid; stdcall;
    /// <summary>
    /// 服务服务的加载器
    /// </summary>
    /// <remarks>
    /// 服务未必是通过加载器注册的，所以如果不是，那么也就没有加载器，GetLoader这时返回空；
    /// </remarks>
    function GetLoader: IQLoader; stdcall;
    /// <summary>
    /// 获取服务的实际原生对象地址
    /// </summary>
    function GetOriginObject: Pointer; stdcall;
    /// <summary>
    /// 判断当前服务是否有指定的模块提供
    /// </summary>
    function IsInModule(AModule: THandle): Boolean; stdcall;
    procedure _GetId(AId: PGuid); stdcall;
    function _GetInstance: StandInterfaceResult; stdcall;
    function _GetParent: StandInterfaceResult; stdcall;
    function _GetInstanceCreator: StandInterfaceResult; stdcall;
    function _GetAttrs: StandInterfaceResult; stdcall;

    property Parent: IQServices read GetParent write SetParent;
    property Name: PWideChar read GetName;
    property Attrs: IQParams read GetAttrs;
    property LastError: Cardinal read GetLastErrorCode;
    property LastErrorMsg: PWideChar read GetLastErrorMsg;
    property Loader: IQLoader read GetLoader;
    property Creator: IQService read GetInstanceCreator;
  end;

  //
  /// <summary>
  /// 服务列表接口，用于管理多个服务。它继承自IQService，增加了管理相关的功能
  /// </summary>
  IQServices = interface(IQService)
    ['{7325DF17-BC83-4163-BB72-0AE0208352ED}']
    /// <summary>
    /// 获取指定索引的服务接口实例
    /// </summary>
    function GetItems(AIndex: Integer): IQService; stdcall;
    /// <summary>
    /// 获取列表中总的服务数量
    /// </summary>
    function GetCount: Integer; stdcall;
    /// <summary>
    /// 通过路径获取指定的服务接口实例
    /// </summary>
    /// <param name="APath">
    /// 服务路径，中间以/分隔，不区分大小写
    /// </param>
    /// <returns>
    /// 返回可以用于提供服务的实例，也就是如果不为空，它会调用服务的GetInstance来获取可以提供服务的实例
    /// </returns>
    function ByPath(APath: PWideChar): IQService; stdcall;
    /// <summary>
    /// 通过服务接口ID获取服务接口实例
    /// </summary>
    /// <param name="AId">
    /// 服务接口ID
    /// </param>
    /// <param name="ADoGetInstance">
    /// 是否调用服务的GetInstance来获取新实例
    /// </param>
    /// <returns>
    /// 返回接口服务实例，如果是多实例并且ADoGetInstance为true，则返回一个新实例
    /// </returns>
    function ById(const AId: TGuid; ADoGetInstance: Boolean = true)
      : IQService; stdcall;
    /// <summary>
    /// 添加一个子服务接口实例
    /// </summary>
    /// <param name="AItem">
    /// 要添加子服务
    /// </param>
    /// <returns>
    /// 返回添加的服务接口的索引
    /// </returns>
    function Add(AItem: IQService): Integer; stdcall;
    /// <summary>
    /// 获取指定服务在父中的索引
    /// </summary>
    /// <param name="AItem">
    /// 要查询的服务接口实例
    /// </param>
    /// <returns>
    /// 找到，返回实际的索引，未找到返回-1
    /// </returns>
    function IndexOf(AItem: IQService): Integer; stdcall;
    /// <summary>
    /// 删除指定索引的服务接口实例
    /// </summary>
    /// <param name="AIndex">
    /// 服务接口实例索引
    /// </param>
    procedure Delete(AIndex: Integer); stdcall;
    /// <summary>
    /// 从父中移出指定的服务接口实例
    /// </summary>
    /// <param name="AItem">
    /// 要移除的服务接口实例
    /// </param>
    procedure Remove(AItem: IQService); stdcall;
    /// <summary>
    /// 将服务从指定的索引位置移动到新位置
    /// </summary>
    /// <param name="AIndex">
    /// 原位置
    /// </param>
    /// <param name="ANewIndex">
    /// 新位置
    /// </param>
    /// <returns>
    /// 成功，返回true，位置无效返回 false
    /// </returns>
    function MoveTo(AIndex, ANewIndex: Integer): Boolean; stdcall;
    /// <summary>
    /// 清除所有的接口实例
    /// </summary>
    procedure Clear; stdcall;
    //
    function _GetItems(AIndex: Integer): StandInterfaceResult; stdcall;
    function _ByPath(APath: PWideChar): StandInterfaceResult; stdcall;
    function _ById(const AId: TGuid; ADoGetInstance: Boolean = true)
      : StandInterfaceResult; stdcall;

    property Name: PWideChar read GetName;
    property Parent: IQServices read GetParent;
    property Count: Integer read GetCount;
    property Items[AIndex: Integer]: IQService read GetItems; default;
  end;

  /// <summary>
  /// 通知响应接口，关注某个通知时，应实现IQNotify接口，以便接收相关的通知
  /// </summary>
  IQNotify = interface
    ['{00C7F80F-44BF-4E60-AA58-5992B2B71754}']

    /// <summary>
    /// 在通知发生时，通知响应函数接口
    /// </summary>
    /// <param name="AId">
    /// 通知ID
    /// </param>
    /// <param name="AParams">
    /// 通知参数
    /// </param>
    /// <param name="AFireNext">
    /// 是否继续触发下一个通知
    /// </param>
    procedure Notify(const AId: Cardinal; AParams: IQParams;
      var AFireNext: Boolean); stdcall;
  end;

  /// <summary>
  /// 枚举订阅者回调方法
  /// </summary>
  /// <remarks>
  /// ANotify是订阅者，AParam是调用时传入的用户自定义参数，AContinue 决定是否继续枚举
  /// </remarks>
  TQSubscribeEnumCallback = procedure(ANotify: IQNotify; AParam: Int64;
    var AContinue: Boolean); stdcall;

  /// <summary>
  /// 通知广播接口，用于广播某个固定ID的通知
  /// </summary>
  IQNotifyBroadcast = interface
    ['{3AE4FD5D-7F13-479D-94C2-4813CD283F82}']
    /// <summary>
    /// 添加一个响应者
    /// </summary>
    /// <param name="ANotify">
    /// 要添加的响应者
    /// </param>
    function Add(ANotify: IQNotify): Integer; stdcall;
    /// <summary>
    /// 移除一个响应者
    /// </summary>
    /// <param name="ANotify">
    /// 要移除的响应者
    /// </param>
    procedure Remove(ANotify: IQNotify); stdcall;
    /// <summary>
    /// 清除所有的响应者
    /// </summary>
    procedure Clear; stdcall;
    /// <summary>
    /// 发送通知并等待通知处理结束
    /// </summary>
    /// <param name="AParams">
    /// 通知参数
    /// </param>
    procedure Send(AParams: IQParams); stdcall;
    /// <summary>
    /// 投递一个通知
    /// </summary>
    /// <param name="AParams">
    /// 通知参数
    /// </param>
    procedure Post(AParams: IQParams); stdcall;
    /// <summary>
    /// 枚举指定通知的所有订阅者
    /// </summary>
    /// <param name="ACallback">
    /// 回调函数
    /// </param>
    /// <param name="AParam">
    /// 额外的用户自定义参数，会传递给ACallback的AParam
    /// </param>
    /// <returns>
    /// 返回枚举的订阅者数量
    /// </returns>
    /// <remarks>
    /// 注意返回的数量并不一定是实际的订阅者数量，如果 ACallback 被调用时，AContinue 参数被设置为
    /// false，则会中止枚举，此时返回的是实际已经枚举的数量。
    /// </remarks>
    function EnumSubscribe(ACallback: TQSubscribeEnumCallback; AParam: Int64)
      : Integer; stdcall;
  end;

  IQNotifyBroadcast2=interface(IQNotifyBroadcast)
    ['{A6D51A69-6588-4513-B9F9-45314840FF3D}']
    /// <summary>
    /// 添加一个响应者并将其设置为首个响应者
    /// </summary>
    /// <param name="ANotify">
    /// 要添加的响应者
    /// </param>
    function AddFirst(ANotify: IQNotify): Integer; stdcall;
    function GetNotifyId:Integer;stdcall;
  end;
  //
  /// <summary>
  /// 通知管理器用于内部维护多个通知和订阅者队列
  /// </summary>
  IQNotifyManager = interface
    ['{037DCCD1-6877-4917-A315-120CD3E403F4}']
    /// <summary>
    /// 订阅一个通知
    /// </summary>
    /// <param name="ANotifyId">
    /// 通知的ID
    /// </param>
    /// <param name="AHandler">
    /// 通知订阅者
    /// </param>
    /// <returns>
    /// 订阅成功，返回 true，订阅失败，返回false
    /// </returns>
    function Subscribe(ANotifyId: Cardinal; AHandler: IQNotify)
      : Boolean; stdcall;
    /// <summary>
    /// 取消一个订阅
    /// </summary>
    /// <param name="ANotifyId">
    /// 通知ID
    /// </param>
    /// <param name="AHandler">
    /// 通知订阅者
    /// </param>
    procedure Unsubscribe(ANotifyId: Cardinal; AHandler: IQNotify); stdcall;
    /// <summary>
    /// 返回指定名称的通知ID
    /// </summary>
    /// <param name="AName">
    /// 通知名称
    /// </param>
    /// <returns>
    /// 返回通知ID
    /// </returns>
    /// <remarks>
    /// 如果指定的通知名称没有定义，会自动添加一个此名称并返回ID，如果指定名称的ID已经存在，则返回原来的ID
    /// </remarks>
    function IdByName(const AName: PWideChar): Cardinal; stdcall;
    /// <summary>
    /// 获取指定通知ID的名称
    /// </summary>
    /// <param name="AId">
    /// 通知ID
    /// </param>
    /// <returns>
    /// 返回通知的名称
    /// </returns>
    function NameOfId(const AId: Cardinal): PWideChar; stdcall;
    /// <summary>
    /// 投递一个通知并等待它被处理完成
    /// </summary>
    /// <param name="AId">
    /// 通知ID
    /// </param>
    /// <param name="AParams">
    /// 通知的附加参数
    /// </param>
    procedure Send(AId: Cardinal; AParams: IQParams); stdcall;
    /// <summary>
    /// 投递一个通知
    /// </summary>
    /// <param name="AId">
    /// 通知ID
    /// </param>
    /// <param name="AParams">
    /// 通知的附加参数
    /// </param>
    procedure Post(AId: Cardinal; AParams: IQParams); stdcall;
    /// <summary>
    /// 清除所有的通知及订阅
    /// </summary>
    procedure Clear;

    /// <summary>
    /// 枚举指定通知的所有订阅者
    /// </summary>
    /// <param name="ANotifyId">
    /// 通知ID
    /// </param>
    /// <param name="ACallback">
    /// 通知枚举回调函数
    /// </param>
    /// <param name="AParam">
    /// 用户添加的额外附加参数，会传给 ACallback 的AParam
    /// </param>
    function EnumSubscribe(ANotifyId: Cardinal;
      ACallback: TQSubscribeEnumCallback; AParam: Int64): Integer; stdcall;
    /// <summary>
    /// 已经注册的通知数量
    /// </summary>
    function GetCount: Integer; stdcall;
    /// <summary>
    /// 获取指定索引的通知ID
    /// </summary>
    function GetId(const AIndex: Integer): Cardinal; stdcall;
    /// <summary>
    /// 获取指定索引的通知的名称
    /// </summary>
    function GetName(const AIndex: Integer): PWideChar; stdcall;
    /// <summary>
    /// 判断指定ID的通知是否有订阅者
    /// </summary>
    /// <param name="AId">
    /// 通知ID
    /// </param>
    function HasSubscriber(const AId: Cardinal): Boolean; stdcall;
    property Count: Integer read GetCount;
    property Id[const AIndex: Integer]: Cardinal read GetId;
    property Name[const AIndex: Integer]: PWideChar read GetName;
  end;

  /// <summary>
  /// 模块状态
  /// </summary>
  TQModuleState = (
    /// <summary>
    /// 状态未知
    /// </summary>
    msUnknown,
    /// <summary>
    /// 正在加载中
    /// </summary>
    msLoading,
    /// <summary>
    /// 已经加载完成
    /// </summary>
    msLoaded,
    /// <summary>
    /// 正在卸载
    /// </summary>
    msUnloading);
  /// <summary>
  /// 加载器状态
  /// </summary>
  TQLoaderState = (
    /// <summary>
    /// 空闲
    /// </summary>
    lsIdle,
    /// <summary>
    /// 正在加载
    /// </summary>
    lsLoading,
    /// <summary>
    /// 正在卸载
    /// </summary>
    lsUnloading);

  /// <summary>
  /// 加载器接口，用于实现加载不同类型的服务
  /// </summary>
  IQLoader = interface(IQService)
    ['{3F576A14-D251-47C4-AB6E-0F89B849B71F}']
    /// <summary>
    /// 获取服务的来源
    /// </summary>
    /// <param name="AService">
    /// 服务实例
    /// </param>
    /// <param name="ABuf">
    /// 用于存放来源的缓冲区
    /// </param>
    /// <param name="ALen">
    /// 缓冲区大小
    /// </param>
    /// <returns>
    /// 返回实际使用的缓冲区大小
    /// </returns>
    function GetServiceSource(AService: IQService; ABuf: PWideChar;
      ALen: Integer): Integer; stdcall;
    /// <summary>
    /// 开始加载所有支持的插件
    /// </summary>
    procedure Start; stdcall;
    /// <summary>
    /// 卸载所有已经加载的插件
    /// </summary>
    procedure Stop; stdcall;
    /// <summary>
    /// 加载指定文件名的插件提供的所有服务
    /// </summary>
    /// <param name="AFileName">
    /// 插件文件名
    /// </param>
    /// <returns>
    /// 返回文件名对应的模块句柄
    /// </returns>
    function LoadServices(const AFileName: PWideChar): THandle;
      stdcall; overload;
    /// <summary>
    /// 从流中加载插件
    /// </summary>
    /// <param name="AStream">
    /// 插件所在的数据流
    /// </param>
    /// <returns>
    /// 返回流加载后的模块句柄
    /// </returns>
    function LoadServices(const AStream: IQStream): THandle; stdcall; overload;
    /// <summary>
    /// 卸载指定的插件
    /// </summary>
    /// <param name="AHandle">
    /// 要卸载的插件句柄
    /// </param>
    /// <param name="AWaitDone">
    /// 是否等待插件卸载完成
    /// </param>
    /// <returns>
    /// 成功，返回 true，失败，返回 false
    /// </returns>
    /// <remarks>
    /// 如果在一个本插件提供的服务里卸载插件自身，AWaitDone 参数必需设置为 false，以避免死锁 <br />
    /// </remarks>
    function UnloadServices(const AHandle: THandle; AWaitDone: Boolean = true)
      : Boolean; stdcall;
    /// <summary>
    /// 获取加载的模块数量
    /// </summary>
    function GetModuleCount: Integer; stdcall;
    /// <summary>
    /// 获取指定索引的模块名称
    /// </summary>
    function GetModuleName(AIndex: Integer): PWideChar; stdcall;
    /// <summary>
    /// 获取指定索引的模块句柄
    /// </summary>
    function GetModules(AIndex: Integer): HMODULE; stdcall;
    /// <summary>
    /// 获取模块的状态
    /// </summary>
    function GetModuleState(AInstance: HINST): TQModuleState; stdcall;
    /// <summary>
    /// 设置当前加载的模块
    /// </summary>
    procedure SetLoadingModule(AInstance: HINST); stdcall;
    /// <summary>
    /// 获取正在加载的模块文件名
    /// </summary>
    function GetLoadingFileName: PWideChar; stdcall;
    /// <summary>
    /// 获取正在加载的模块句柄
    /// </summary>
    function GetLoadingModule: HINST; stdcall;
    /// <summary>
    /// 获取当前加载器状态
    /// </summary>
    function GetState: TQLoaderState; stdcall;
  end;

  /// <summary>
  /// 日志接口，一般由宿主提供并管理，插件只是通过 Post 接口投递日志。
  /// </summary>
  /// <remarks>
  /// QPlugins 默认并没有实现日志接口， 你可以直接用 QLog 实现该接口并注册为日志服务
  /// </remarks>
  IQLog = interface(IQService)
    ['{14F4C543-2D43-4AAD-BAFE-B25784BC917D}']
    /// <summary>
    /// 投递一条日志
    /// </summary>
    /// <param name="ALevel">
    /// 日志记录级别
    /// </param>
    /// <param name="AMsg">
    /// 日志消息内容
    /// </param>
    procedure Post(ALevel: BYTE; AMsg: PWideChar); stdcall;
    /// <summary>
    /// 强制日志写入
    /// </summary>
    procedure Flush; stdcall;
  end;

  // QWorker接口封装
  /// <summary>
  /// QWorker 作业组完成回调接口
  /// </summary>
  IQNotifyCallback = interface
    ['{8039F16A-0D0C-42C9-B891-454935371ACE}']
    /// <summary>
    /// 通知响应事件
    /// </summary>
    /// <param name="ASender">
    /// 通知发送者，一般为对应的JobGroup接口实例
    /// </param>
    procedure DoNotify(ASender: IInterface); stdcall;
  end;

  /// <summary>
  /// QWorker 作业回调接口
  /// </summary>
  IQJobCallback = interface
    ['{886BE1F7-3365-4F81-9CEA-742EBD833584}']
    /// <summary>
    /// 作业实际执行接口
    /// </summary>
    /// <param name="AParams">
    /// 传递给作业的参数
    /// </param>
    procedure DoJob(AParams: IQParams); stdcall;
    /// <summary>
    /// 作业完成时被调用的接口
    /// </summary>
    procedure AfterDone; stdcall;
    /// <summary>
    /// 在作业取消之前触发
    /// </summary>
    procedure BeforeCancel; stdcall;
  end;

  /// <summary>
  /// For 并行作业管理接口
  /// </summary>
  IQForJobManager = interface
    ['{F67881A5-92C6-4656-8073-C58E4DA43BF7}']
    /// <summary>
    /// 中断循环
    /// </summary>
    procedure BreakIt; stdcall;
    /// <summary>
    /// 获取起始索引
    /// </summary>
    function GetStartIndex: Int64; stdcall;
    /// <summary>
    /// 获取结束索引
    /// </summary>
    function GetStopIndex: Int64; stdcall;
    /// <summary>
    /// 判断是否被中断
    /// </summary>
    function GetBreaked: Boolean; stdcall;
    /// <summary>
    /// 获取实际运行的次数
    /// </summary>
    function GetRuns: Int64; stdcall;
    /// <summary>
    /// 获取总运行时间，精度为0.1ms
    /// </summary>
    function GetTotalTime: Int64; stdcall;
    /// <summary>
    /// 获取平均运行时间，精度为0.1ms
    /// </summary>
    function GetAvgTime: Int64; stdcall;
  end;

  /// <summary>
  /// For 并行作业回调函数
  /// </summary>
  IQForJobCallback = interface
    ['{9A29AC85-2A57-4C01-8313-E7D3A7C29904}']
    /// <summary>
    /// For 并行回调作业处理函数
    /// </summary>
    /// <param name="AMgr">
    /// FOR 并行作业管理对象
    /// </param>
    /// <param name="AIndex">
    /// 当前作业要处理的循环索引
    /// </param>
    /// <param name="AParams">
    /// 传递给作业处理函数的附加参数
    /// </param>
    procedure DoJob(AMgr: IQForJobManager; AIndex: Int64;
      AParams: IQParams); stdcall;
  end;

  /// <summary>
  /// 作业组管理接口
  /// </summary>
  IQJobGroup = interface
    ['{061C27B2-1D09-42FA-8A80-B738E8CFA5F3}']
    /// <summary>
    /// 取消后续作业的执行
    /// </summary>
    /// <param name="AWaitRunningDone">
    /// 是否等待正在执行的作业结束
    /// </param>
    /// <remarks>
    /// 如果要在作业组的作业中取消作业，AWaitRunningDone 必需设置为 False 以避免死锁。
    /// </remarks>
    procedure Cancel(AWaitRunningDone: Boolean = true); stdcall;
    /// <summary>
    /// 准备开始批量添加分组作业
    /// </summary>
    procedure Prepare; stdcall;
    /// <summary>
    /// 运行 Prepare 后添加到列表中的作业
    /// </summary>
    /// <param name="ATimeout">
    /// 作业完成超时，如果在指定的时间内，作业组内的作业没有完成，则后续未开始执行的作业将被取消执行，并触发 AfterDone（如果设置了）
    /// </param>
    procedure Run(ATimeout: Cardinal = INFINITE); stdcall;
    /// <summary>
    /// 插入一个新的作业
    /// </summary>
    /// <param name="AIndex">
    /// 要插入的作业位置
    /// </param>
    /// <param name="AJob">
    /// 要添加的作业
    /// </param>
    /// <param name="AParams">
    /// 传给作业的额外参数
    /// </param>
    /// <param name="ARunInMainThread">
    /// 是否作业需要运行在主线程中
    /// </param>
    /// <returns>
    /// 成功，返回 true，失败，返回 false
    /// </returns>
    function Insert(AIndex: Integer; AJob: IQJobCallback; AParams: IQParams;
      ARunInMainThread: Boolean): Boolean; stdcall;
    /// <summary>
    /// 追加一个新的作业
    /// </summary>
    /// <param name="AJob">
    /// 要添加的作业
    /// </param>
    /// <param name="AParams">
    /// 传给作业的额外参数
    /// </param>
    /// <param name="ARunInMainThread">
    /// 是否作业需要运行在主线程中
    /// </param>
    /// <returns>
    /// 成功，返回 true，失败，返回 false
    /// </returns>
    function Add(AJob: IQJobCallback; AParams: IQParams; AInMainThread: Boolean)
      : Boolean; stdcall;
    /// <summary>
    /// 等待分组中所有作业完成
    /// </summary>
    /// <param name="ABlockMessage">
    /// 是否阻塞消息循环
    /// </param>
    /// <param name="ATimeout">
    /// 等待超时
    /// </param>
    /// <returns>
    /// 返回等待结果，如果在 ATimeout 超时之前所有作业都执行完成了，则返回 wrSignaled，如果超时，返回 wrTimeout
    /// </returns>
    function Wait(ABlockMessage: Boolean; ATimeout: Cardinal = INFINITE)
      : TWaitResult; overload;
    /// <summary>
    /// 作业分组中子作业的数量
    /// </summary>
    function GetCount: Integer; stdcall;
    /// <summary>
    /// 设置 AfterDone 的通知回调
    /// </summary>
    procedure SetAfterDone(AValue: IQNotifyCallback); stdcall;
    /// <summary>
    /// 获取作业分组完成 AfterDone 的通知回调
    /// </summary>
    function GetAfterDone: IQNotifyCallback; stdcall;
    /// <summary>
    /// 获取作业是否是顺序执行的
    /// </summary>
    function GetByOrder: Boolean; stdcall;
    /// <summary>
    /// 获取已经执行的作业数量
    /// </summary>
    function GetRuns: Integer; stdcall;
    /// <summary>
    /// 设置分组最大允许使用的工作者数量
    /// </summary>
    function GetMaxWorkers: Integer; stdcall;
    /// <summary>
    /// 设置分组最大允许使用的工作者数量
    /// </summary>
    procedure SetMaxWorkers(const AValue: Integer); stdcall;
    property Count: Integer read GetCount;
    function _GetAfterDone: StandInterfaceResult; stdcall;
    property AfterDone: IQNotifyCallback read GetAfterDone write SetAfterDone;
    property ByOrder: Boolean read GetByOrder;
    property Runs: Integer read GetRuns;
    property MaxWorkers: Integer read GetMaxWorkers write SetMaxWorkers;
  end;

  /// <summary>
  /// 全局 QWorker 作业管理对象接口定义
  /// </summary>
  IQWorkers = interface
    ['{94B6F5B4-1C16-448F-927C-DD8772DDAA78}']
    /// <summary>
    /// 投递一个新的普通作业
    /// </summary>
    /// <param name="AJob">
    /// 作业
    /// </param>
    /// <param name="AParams">
    /// 提供给作业的参数
    /// </param>
    /// <param name="ARunInMainThread">
    /// 作业是否需要运行在主线程
    /// </param>
    /// <returns>
    /// 返回作业句柄，如果失败，返回0
    /// </returns>
    function Post(AJob: IQJobCallback; AParams: IQParams;
      ARunInMainThread: Boolean): Int64; stdcall;
    /// <summary>
    /// 投递一个定时作业
    /// </summary>
    /// <param name="AJob">
    /// 作业
    /// </param>
    /// <param name="AInterval">
    /// 时间间隔，单位为0.1ms
    /// </param>
    /// <param name="AParams">
    /// 提供给作业的额外参数
    /// </param>
    /// <param name="ARunInMainThread">
    /// 作业是否需要运行在主线程
    /// </param>
    /// <returns>
    /// 返回作业句柄，如果失败返回0
    /// </returns>
    /// <remarks>
    /// 定时作业并不会等待上一次完成，只要到时间点就会触发，所以定时作业的作业必需保证在下一次作业触发之前完成。
    /// </remarks>
    function Timer(AJob: IQJobCallback; AInterval: Cardinal; AParams: IQParams;
      ARunInMainThread: Boolean): Int64; stdcall;
    /// <summary>
    /// 延迟指定的时间再执行作业
    /// </summary>
    /// <param name="AJob">
    /// 要执行的作业
    /// </param>
    /// <param name="AParams">
    /// 作业参数
    /// </param>
    /// <param name="ADelay">
    /// 延迟时间，单位为0.1ms
    /// </param>
    /// <param name="ARunInMainThread">
    /// 是否要求运行在主线程
    /// </param>
    /// <param name="AIsRepeat">
    /// 是否重复执行
    /// </param>
    /// <returns>
    /// 返回作业句柄，如果失败，返回0
    /// </returns>
    /// <remarks>
    /// 如果 AIsRepeat 参数为 true，那个它是一个定时作业，但与 Timer 不同，Delay
    /// 是一个定间隔作业，下一次作业触发是在上一次作业执行完成后的 AInterval 参数指定的时间点触发。
    /// </remarks>
    function Delay(AJob: IQJobCallback; AParams: IQParams; ADelay: Int64;
      ARunInMainThread, AIsRepeat: Boolean): Int64; stdcall;
    /// <summary>
    /// 在指定的时间点运行指定的作业
    /// </summary>
    /// <param name="AJob">
    /// 作业
    /// </param>
    /// <param name="AParams">
    /// 作业参数
    /// </param>
    /// <param name="ATime">
    /// 要执行的时间点
    /// </param>
    /// <param name="AInterval">
    /// 作业重复执行时间间隔，如果为0，则不能重复执行
    /// </param>
    /// <param name="ARunInMainThread">
    /// 是否需要在主线程中执行
    /// </param>
    /// <returns>
    /// 返回作业句柄，如果失败，则返回0
    /// </returns>
    function At(AJob: IQJobCallback; AParams: IQParams; ATime: TDateTime;
      AInterval: Cardinal; ARunInMainThread: Boolean): Int64; stdcall;
    /// <summary>
    /// 安排一个类Linux Cron 格式的计划任务作业
    /// </summary>
    /// <param name="AJob">
    /// 作业
    /// </param>
    /// <param name="AParams">
    /// 参数
    /// </param>
    /// <param name="APlan">
    /// 执行计划
    /// </param>
    /// <param name="ARunInMainThread">
    /// 是否需要在主线程中执行
    /// </param>
    /// <returns>
    /// 成功，返回作业句柄
    /// </returns>
    /// <remarks>
    /// 与其它作业不同，计划任务作业会受系统时钟的影响，而其它类型的作业与系统时间无关。
    /// </remarks>
    function Plan(AJob: IQJobCallback; AParams: IQParams; APlan: PWideChar;
      ARunInMainThread: Boolean): Int64; stdcall;
    /// <summary>
    /// 执行一个For并行作业
    /// </summary>
    /// <param name="AJob">
    /// 作业
    /// </param>
    /// <param name="AParams">
    /// 作业参数
    /// </param>
    /// <param name="AStart">
    /// 起始索引
    /// </param>
    /// <param name="AStop">
    /// 停止索引
    /// </param>
    /// <param name="AMsgWait">
    /// 等待作业完成过程中，是否允许消息处理
    /// </param>
    procedure &For(AJob: IQForJobCallback; AParams: IQParams;
      AStart, AStop: Int64; AMsgWait: Boolean); stdcall;
    /// <summary>
    /// 清除指定句柄的作业
    /// </summary>
    /// <param name="AHandle">
    /// 要清除的作业句柄
    /// </param>
    /// <param name="AWaitRunningDone">
    /// 如果作业正在执行，是否等待它完成
    /// </param>
    procedure Clear(AHandle: Int64; AWaitRunningDone: Boolean); stdcall;
    /// <summary>
    /// 创建一个作业分组
    /// </summary>
    /// <param name="AByOrder">
    /// 分组内的作业是否要求顺序执行
    /// </param>
    function CreateJobGroup(AByOrder: Boolean): IQJobGroup; stdcall;
    /// <summary>
    /// 设置工作者数量
    /// </summary>
    /// <param name="AMinWorkers">
    /// 最小工作者数量，不能小于2
    /// </param>
    /// <param name="AMaxWorkers">
    /// 最大工作者数量，必需 &gt;=AMinWorkers
    /// </param>
    procedure SetWorkers(const AMinWorkers, AMaxWorkers: Integer); stdcall;
    /// <summary>
    /// 获取当前工作者状态统计数据
    /// </summary>
    /// <param name="ATotal">
    /// 当前的总工作者数量
    /// </param>
    /// <param name="AIdle">
    /// 当前空闲的工作者数量
    /// </param>
    /// <param name="ABusy">
    /// 当前忙碌的工作者数量
    /// </param>
    procedure PeekCurrentWorkers(var ATotal, AIdle, ABusy: Integer); stdcall;
    /// <summary>
    /// 注册一个信号
    /// </summary>
    /// <param name="ASignal">
    /// 要注册的信号名称
    /// </param>
    function RegisterSignal(const ASignal: PWideChar): Integer; stdcall;
    /// <summary>
    /// 创建一个等待信号触发的作业
    /// </summary>
    /// <param name="ASignal">
    /// 要等待的信号名称
    /// </param>
    /// <param name="AJob">
    /// 信号触发时，要执行的作业
    /// </param>
    /// <param name="ARunInMainThread">
    /// 作业是否需要在主线程中执行
    /// </param>
    /// <returns>
    /// 返回作业句柄，如果失败，返回0
    /// </returns>
    function WaitSignal(const ASignal: PWideChar; AJob: IQJobCallback;
      ARunInMainThread: Boolean): Int64; stdcall;
    /// <summary>
    /// 触发信号
    /// </summary>
    /// <param name="ASignal">
    /// 信号名称
    /// </param>
    /// <param name="AParams">
    /// 传递给信号处理函数的参数
    /// </param>
    procedure Signal(const ASignal: PWideChar; AParams: IQParams);
    //
    function _CreateJobGroup(AByOrder: Boolean): StandInterfaceResult; stdcall;
  end;

  /// <summary>
  /// 服务回调接口定义，AService 是回调的服务参数
  /// </summary>
  TQServiceCallback = procedure(const AService: IQService); stdcall;

  /// <summary>
  /// 插件管理器，用于管理所有插件及服务
  /// </summary>
  IQPluginsManager = interface(IQServices)
    ['{BDE6247B-87AD-4105-BDC9-1EA345A9E4B0}']
    /// <summary>
    /// 所有的加载器服务的根结点
    /// </summary>
    /// <remarks>
    /// 该结点下的子服务应实现 IQLoader 接口。实际路径为 /Loaders
    /// </remarks>
    function GetLoaders: IQServices; stdcall;
    /// <summary>
    /// 所有路由器接口服务的根结点
    /// </summary>
    /// <remarks>
    /// 1、此结点下的所有服务必需实现 IQServices 接口，以便调用其 ByPath 或 ById 获取正确的服务实例 <br />
    /// 2、此结点的实际路径为 /Routers
    /// </remarks>
    function GetRouters: IQServices; stdcall;
    /// <summary>
    /// 用户自定义其它类型服务的根结点，其实际路径为 /Services
    /// </summary>
    /// <remarks>
    /// 用户自定义的其它类型服务可以注册自己的根结点，但推荐统一放到 /Services 及其子目录下，以便于管理
    /// </remarks>
    function GetServices: IQServices; stdcall;
    /// <summary>
    /// 确保指定路径的服务列表存在
    /// </summary>
    /// <param name="APath">
    /// 服务路径，路径之间以 “/” 分隔
    /// </param>
    /// <returns>
    /// 如果成功，返回服务列表对象，如果失败，返回空（可能路径被注册为其它类型的服务）
    /// </returns>
    function ForcePath(APath: PWideChar): IQServices; stdcall;
    /// <summary>
    /// 获取当前的活动加载器
    /// </summary>
    function GetActiveLoader: IQLoader; stdcall;
    /// <summary>
    /// 设置当前的活动加载器
    /// </summary>
    procedure SetActiveLoader(ALoader: IQLoader); stdcall;
    /// <summary>
    /// 启动所有的加载器加载支持的插件
    /// </summary>
    procedure Start; stdcall;
    /// <summary>
    /// 标记指定的模块处于准备卸载状态
    /// </summary>
    procedure ModuleUnloading(AInstance: HINST); stdcall;
    /// <summary>
    /// 在主线程中异步调用指定的函数
    /// </summary>
    /// <param name="AProc">
    /// 要执行的异步作业函数
    /// </param>
    /// <param name="AParams">
    /// 传递给异步作业函数的参数
    /// </param>
    procedure AsynCall(AProc: TQAsynProc; AParams: IQParams); stdcall;
    /// <summary>
    /// 处理入队的异步作业
    /// </summary>
    procedure ProcessQueuedCalls; stdcall;
    /// <summary>
    /// 卸载所有的插件
    /// </summary>
    function Stop: Boolean; stdcall;
    /// <summary>
    /// 替换当前的管理器对象
    /// </summary>
    function Replace(ANewManager: IQPluginsManager): Boolean; stdcall;
    /// <summary>
    /// 等待指定的服务注册
    /// </summary>
    /// <param name="AService">
    /// 要等待的服务路径
    /// </param>
    /// <param name="ANotify">
    /// 服务注册完成时的通知回调
    /// </param>
    function WaitService(const AService: PWideChar; ANotify: TQServiceCallback)
      : Boolean; overload; stdcall;
    /// <summary>
    /// 等待指定的服务注册
    /// </summary>
    /// <param name="AId">
    /// 要等待的服务的ID
    /// </param>
    /// <param name="ANotify">
    /// 服务注册完成时的通知回调
    /// </param>
    function WaitService(const AId: TGuid; ANotify: TQServiceCallback): Boolean;
      overload; stdcall;
    /// <summary>
    /// 移除服务注册等待
    /// </summary>
    /// <param name="ANotify">
    /// 要移除的通知回调，所有关联到这个回调的等待都会被移除
    /// </param>
    procedure RemoveServiceWait(ANotify: TQServiceCallback); overload; stdcall;
    /// <summary>
    /// 移除指定服务的注册等待
    /// </summary>
    /// <param name="AService">
    /// 要等待的服务路径
    /// </param>
    /// <param name="ANotify">
    /// 要移除的通知回调
    /// </param>
    procedure RemoveServiceWait(const AService: PWideChar;
      ANotify: TQServiceCallback); overload; stdcall;
    /// <summary>
    /// 移除指定服务的注册等待
    /// </summary>
    /// <param name="AService">
    /// 要等待的服务ID
    /// </param>
    /// <param name="ANotify">
    /// 要移除的通知回调
    /// </param>
    procedure RemoveServiceWait(const AId: TGuid; ANotify: TQServiceCallback);
      overload; stdcall;
    /// <summary>
    /// 触发指定的服务已经注册就绪通知
    /// </summary>
    /// <param name="AService">
    /// 要通知的服务接口实例
    /// </param>
    procedure ServiceReady(AService: IQService); stdcall;
    /// <summary>
    /// 创建一个新的参数列表
    /// </summary>
    function NewParams: IQParams; stdcall;
    /// <summary>
    /// 创建一个新的IQString接口
    /// </summary>
    function NewString: IQString; overload; stdcall;
    /// <summary>
    /// 创建一个新的 IQString 接口，并设置初始内容
    /// </summary>
    function NewString(const ASource: PWideChar): IQString; overload; stdcall;
    /// <summary>
    /// 创建一个新的广播通道
    /// </summary>
    function NewBroadcast(const AId: Cardinal): IQNotifyBroadcast; stdcall;

    function _GetLoaders: StandInterfaceResult; stdcall;
    function _GetRouters: StandInterfaceResult; stdcall;
    function _GetServices: StandInterfaceResult; stdcall;
    function _ForcePath(APath: PWideChar): StandInterfaceResult; stdcall;
    function _GetActiveLoader: StandInterfaceResult; stdcall;
    function _NewParams: StandInterfaceResult; stdcall;
    function _NewString: StandInterfaceResult; overload; stdcall;
    function _NewString(const ASource: PWideChar): StandInterfaceResult;
      overload; stdcall;
    procedure _AsynCall(AProc: TQAsynProcG; AParams: IQParams); stdcall;
    function _NewBroadcast(const AId: Cardinal): Pointer; stdcall;
    property Services: IQServices read GetServices;
    property Routers: IQServices read GetRouters;
    property Loaders: IQServices read GetLoaders;
    property ActiveLoader: IQLoader read GetActiveLoader write SetActiveLoader;
  end;

  /// <summary>
  /// 全局锁，供调用 QPlugins 相关内部接口时进行线程同步
  /// </summary>
  IQLocker = interface
    ['{5008B5D4-EE67-419D-80CB-E5C62FA95243}']
    /// <summary>
    /// 锁定
    /// </summary>
    procedure Lock; stdcall;
    /// <summary>
    /// 解锁
    /// </summary>
    procedure Unlock; stdcall;
  end;

  /// <summary>新建字符串服务接口</summary>
  IQStringService = interface
    ['{9B9384C6-8E8C-4E32-B07B-3F60A7D0A595}']
    /// <summary>
    /// 创建一个新的 IQString 接口，并设置初始内容
    /// </summary>
    /// <remarks>
    /// 推荐使用PluginsManager.NewString 替代此接口
    /// </remarks>
    function NewString(const S: PWideChar): IQString; stdcall;
  end;

implementation

end.
