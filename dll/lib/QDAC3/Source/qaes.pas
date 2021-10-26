{
  本单元基于EldoS, Alexander Ionov的EIAES重装封装改动而来，特别感谢！
  AES加密是一种对称加密，理论上密文与原文长度一致，但由于AES是基于块加密的，所以
  产生的密文长度实际上是16的整数倍，不足的部分被填充为#0。所以如果要准确还原加密
  前的数据，你在保存时，应保存下其原始长度，以便解密后，对长度进行截断。 本单元为
  简化操作，在加密流时，会自动在密文的头部加入实际的长度（64位，8B），解密时使用
  该长度信息截取实际的内容长度。

  关于CBC和EBC
  EBC是最原始的加密方法，CBC引入了初始化向量来与原始数据先异或再执行EBC相同的加密
  操作，理论上CBC更安全一点点。 }
unit qaes;
{$I qdac.inc}

interface

{ 更新日志
  2016.10.25
  =========
  * 进行流加密或解密时加入压缩进度回调支持，回调的频率可以通过全局的AESProgressBlock
  来设置，默认为每1MB回调一次，不足1MB，加密完成后回调一次（阿木建议）

  2015.7.17
  =========
  * 去除了AlignAESBlockSize选项，强制全部对齐

  2015.5.14
  =========
  + TQAES.AsECB/AsCBC 加入了对字节序列的Key支持
  * 修正了新增的条件编译选项在 XE 下无法编译的问题（感谢麦子仲肥报告）
  2015.1.8
  =========
  * 修正了KeyFromBytes函数处理192/256位密钥时出错的问题（阿呆报告）
  2014.12.9
  =========
  * 修正了单个汉字解密时，出现乱码的问题（霸天虎报告）
  2014.12.2
  ==========
  * 修正了解密字符串时，如果是UTF-8编码时，会错误的将\0结束符包含在解密完成的字符串中的问题
  2014.11.26
  ==========
  * 修正了解密字符串时，由于自动检测内容编码错误，造成解密内容与原始字符串不一致的问题（志文2014报告）

  2014.11.3
  =========
  * 修正了AES CBC加密算法中由于未更新初始化向量造成CBC加密时不兼容与其它加密算法的问题
  + 增加AlignAESBlockSize全局变量控制是否自动对齐16字节数据（默认为True）

}
uses classes, sysutils, qstring, EncdDecd{$IFDEF MSWINDOWS},
  windows{$ENDIF}{$IF RTLVersion>27},
  System.NetEncoding{$IFEND};
{$HPPEMIT '#pragma link "qaes"'}
{$HPPEMIT '#pragma comment(lib,"soaprtl")'}

type
  /// AES加密的密钥强度类型
  TQAESKeyType = (kt128,
    /// 最长支持128位密钥加密
    kt192,
    /// 最长支持192位密钥加密
    kt256
    /// 最长支持256位密钥加密
    );
  /// AES加密模式
  TQAESEncryptMode = (emCBC,
    /// CBC加密模式
    emECB
    /// ECB加密模式
    );
  // 补码方式
  TQAESPaddingMode = (
    // 后面全部补零对齐
    pmZero,
    // 填充需要补码的字节数(1-8)
    pmPKCS5,
    // 填充需要补码的字节数(1-255)
    pmPKCS7);
  TQAESBuffer = array [0 .. 15] of byte;
  PQAESBuffer = ^TQAESBuffer;
  PQAES = ^TQAES;
  TQAESKey128 = array [0 .. 15] of byte;
  TQAESKey192 = array [0 .. 23] of byte;
  TQAESKey256 = array [0 .. 31] of byte;
  TQAESExpandedKey128 = array [0 .. 43] of Cardinal;
  TQAESExpandedKey192 = array [0 .. 53] of Cardinal;
  TQAESExpandedKey256 = array [0 .. 63] of Cardinal;

  PAESKey128 = ^TQAESKey128;
  PAESKey192 = ^TQAESKey192;
  PAESKey256 = ^TQAESKey256;
  PAESExpandedKey128 = ^TQAESExpandedKey128;
  PAESExpandedKey192 = ^TQAESExpandedKey192;
  PAESExpandedKey256 = ^TQAESExpandedKey256;

  TQAESKey = record
    KeyType: TQAESKeyType;
    case Integer of
      0:
        (Key128: TQAESKey128);
      1:
        (Key192: TQAESKey192);
      2:
        (Key256: TQAESKey256);
  end;

  TQAESExpandedKey = record
    case Integer of
      0:
        (Key128: TQAESExpandedKey128);
      1:
        (Key192: TQAESExpandedKey192);
      2:
        (Key256: TQAESExpandedKey256);
  end;

  TQAESProgress = procedure(AProcessed, ATotal: Int64) of object;

  { 用于简化AES加密和解密操作而封装的记录 }
  TQAES = record
  private
    FKeyIsString: Boolean;
    { 加密密钥 }
    FKey: QStringW;
    { 加密方式 }
    FMode: TQAESEncryptMode;
    { 密钥强度类型 }
    FKeyType: TQAESKeyType;
    { 加密初始向量 }
    FInitVector: TQAESBuffer;
    { 进度提示 }
    FOnProgress: TQAESProgress;
    FPaddingMode: TQAESPaddingMode;
  public
    { 采用ECB加密算法


      <param name="AKey">加密密钥</param>
      <param name="AKeyType">密钥强度类型</param>

      <returns>
      返回当前记录实例的地址，以便串联调用。
      </returns> }
    function AsECB(const AKey: QStringW; AKeyType: TQAESKeyType = kt256)
      : PQAES; overload;
    function AsECB(const AKey: TBytes; AKeyType: TQAESKeyType = kt256)
      : PQAES; overload;
    function AsCBC(AInitVector: TQAESBuffer; const AKey: QStringW;
      AKeyType: TQAESKeyType = kt256): PQAES; overload;
    function AsCBC(AInitVector: TQAESBuffer; const AKey: TBytes;
      AKeyType: TQAESKeyType = kt256): PQAES; overload;
    { 加密指定的数据流
      <param name="ASource">未加密的原始数据流</param>
      <param name="ADest">用于保存加密结果的目标数据流</param> }
    procedure Encrypt(ASource, ADest: TStream); overload;
    { 加密指定的数据
      <param name="p">要加密的数据内容的首地址</param>
      <param name="len">要加密的数据内容长度（字节数）</param>
      <param name="AResult">用于保存加密结果的缓冲区</param> }
    procedure Encrypt(const p: Pointer; len: Integer;
      var AResult: TBytes); overload;
    { 加密指定的内容
      <param name="AData">未加密的原始数据</param>
      <param name="AResult">用于保存加密结果的缓冲区</param> }
    procedure Encrypt(const AData: TBytes; var AResult: TBytes); overload;
    { 加密指定的字符串
      <param name="AData">要加密的字符串（Unicode编码）</param>
      <param name="AResult">用来保存加密结果的缓冲区</param> }
    procedure Encrypt(const AData: QStringW; var AResult: TBytes); overload;
    { 加密指定的字符串
      <param name="AData">要加密的字符串（Unicode编码）</param>
      <param name="AHexBeforeBase64">在进行Base64编码返回结果前，先转换为十六进制</param>
      <returns>返回加密后的字符串</returns>
    }
    function Encrypt(const AData: QStringW; AHexBeforeBase64: Boolean = true)
      : QStringW; overload;
    { 加密指定的文件


      <param name="ASourceFile">要加密的原始文件名</param>
      <param name="ADestFile">加密后的目标文件名</param> }
    procedure Encrypt(const ASourceFile, ADestFile: QStringW); overload;
    { <summary>解密指定的流数据内容</summary>
      <param name="ASource">加密过的原始数据流</param>
      <param name="ADest">用于存放解密结果的目标数据流</param>
      <remark>默认加密数据流算法会在数据头部加上64位的实际流长度</remark>
    }
    procedure Decrypt(ASource, ADest: TStream); overload;

    { 解密指定的加密数据


      <param name="AData">要解密的数据内容</param>
      <param name="AResult">用于存贮解密后的原始数据的缓冲区</param> }
    procedure Decrypt(const AData: TBytes; var AResult: TBytes); overload;

    procedure Decrypt(const AData: PByte; ALen: Integer;
      var AResult: TBytes); overload;
    { 对指定的加密字符串数据进行解密，并返回解密后的字符串


      <param name="AData">已加密的数据内容</param>

      <returns>
      返回解密后的内容的字符串值，解密时自动检测内容编码格式
      </returns> }
    function Decrypt(const AData: TBytes): String; overload;
    function Decrypt(const S: String; AHexBeforeBase64: Boolean = true)
      : String; overload;
    { 对指定的加密文件进行解密
      <param name="ASourceFile">加密过的源文件</param>
      <param name="ADestFile">解密后的目标文件</param> }
    procedure Decrypt(const ASourceFile, ADestFile: QStringW); overload;
    procedure SetProgressCallback(ACallback: TQAESProgress); overload;
    { 加密原始密钥 }
    property Key: QStringW read FKey write FKey;
    { 加密模式 }
    property Mode: TQAESEncryptMode read FMode;
    { 加密密钥强度 }
    property KeyType: TQAESKeyType read FKeyType write FKeyType;
    property PaddingMode: TQAESPaddingMode read FPaddingMode write FPaddingMode;
  end;

  // 计算加密后的内容大小，由于AES属于对称加密算法，但约定尺寸必是16的整数倍
  // 返回结果为((ASize/16)+1)*16
function AESEncryptSize(ASize: Int64): Int64;
// 加密函数,AInitVector(初始化向量)只是用于CBC模式，如果是ECB模式，它被忽略，
// 直接传AESEmptyBuffer就可以。在CBC模式下，加密和解决的初始化向量必需一致
procedure AESEncrypt(ASource, ADest: TStream; AInitVector: TQAESBuffer;
  const AKey: TQAESKey; AMode: TQAESEncryptMode = emCBC;
  APaddingMode: TQAESPaddingMode = pmPKCS5;
  AOnProgress: TQAESProgress = nil); overload;
procedure AESEncrypt(ASource, ADest: TStream; AInitVector: TQAESBuffer;
  const AKey: QStringW; AKeyType: TQAESKeyType = kt256;
  AMode: TQAESEncryptMode = emCBC; AKeyIsString: Boolean = true;
  APaddingMode: TQAESPaddingMode = pmPKCS5;
  AOnProgress: TQAESProgress = nil); overload;
procedure AESEncrypt(const p: Pointer; len: Integer; AInitVector: TQAESBuffer;
  var AResult: TBytes; const AKey: QStringW; AKeyType: TQAESKeyType = kt256;
  AMode: TQAESEncryptMode = emCBC; AKeyIsString: Boolean = true;
  APaddingMode: TQAESPaddingMode = pmPKCS5;
  AOnProgress: TQAESProgress = nil); overload;
procedure AESEncrypt(const AData: TBytes; AInitVector: TQAESBuffer;
  var AResult: TBytes; const AKey: QStringW; AKeyType: TQAESKeyType = kt256;
  AMode: TQAESEncryptMode = emCBC; AKeyIsString: Boolean = true;
  APaddingMode: TQAESPaddingMode = pmPKCS5;
  AOnProgress: TQAESProgress = nil); overload;
procedure AESEncrypt(const AData: QStringW; AInitVector: TQAESBuffer;
  var AResult: TBytes; const AKey: QStringW; AKeyType: TQAESKeyType = kt256;
  AMode: TQAESEncryptMode = emCBC; AKeyIsString: Boolean = true;
  APaddingMode: TQAESPaddingMode = pmPKCS5;
  AOnProgress: TQAESProgress = nil); overload;
procedure AESEncrypt(const ASourceFile, ADestFile: QStringW;
  AInitVector: TQAESBuffer; const AKey: QStringW;
  AKeyType: TQAESKeyType = kt256; AMode: TQAESEncryptMode = emCBC;
  AKeyIsString: Boolean = true; APaddingMode: TQAESPaddingMode = pmPKCS5;
  AOnProgress: TQAESProgress = nil); overload;
// 解密函数
procedure AESDecrypt(const AData: TBytes; AInitVector: TQAESBuffer;
  var AResult: TBytes; const AKey: TQAESKey; AMode: TQAESEncryptMode = emCBC;
  APaddingMode: TQAESPaddingMode = pmPKCS5); overload;
procedure AESDecrypt(ASource, ADest: TStream; AInitVector: TQAESBuffer;
  const AKey: QStringW; AKeyType: TQAESKeyType = kt256;
  AMode: TQAESEncryptMode = emCBC; AKeyIsString: Boolean = true;
  APaddingMode: TQAESPaddingMode = pmPKCS5;
  AOnProgress: TQAESProgress = nil); overload;
procedure AESDecrypt(const AData: TBytes; AInitVector: TQAESBuffer;
  var AResult: TBytes; const AKey: QStringW; AKeyType: TQAESKeyType = kt256;
  AMode: TQAESEncryptMode = emCBC; AKeyIsString: Boolean = true;
  APaddingMode: TQAESPaddingMode = pmPKCS5); overload;
function AESDecrypt(const AData: TBytes; AInitVector: TQAESBuffer;
  const AKey: QStringW; AKeyType: TQAESKeyType = kt256;
  AMode: TQAESEncryptMode = emCBC; ATrimZero: Boolean = true;
  AKeyIsString: Boolean = true; APaddingMode: TQAESPaddingMode = pmPKCS5;
  AOnProgress: TQAESProgress = nil): String; overload;
procedure AESDecrypt(const ASourceFile, ADestFile: QStringW;
  AInitVector: TQAESBuffer; const AKey: QStringW;
  AKeyType: TQAESKeyType = kt256; AMode: TQAESEncryptMode = emCBC;
  AKeyIsString: Boolean = true; APaddingMode: TQAESPaddingMode = pmPKCS5;
  AOnProgress: TQAESProgress = nil); overload;
// 密钥转换函数
procedure KeyFromBytes(const AKey: Pointer; const L: Integer;
  AKeyType: TQAESKeyType; var AResult: TQAESKey); overload;
function KeyFromBytes(const ABytes: TBytes; AKeyType: TQAESKeyType)
  : TQAESKey; overload;
function KeyFromString(const S: QStringW; AKeyType: TQAESKeyType)
  : TQAESKey; overload;

var
  /// 全局的空白的TQAESBuffer类型的缓冲区，用于为参数提供默认值
  AESEmptyBuffer: TQAESBuffer = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0);
  AESProgressBlock: Integer = 1048576; // 1MB,需要显示进度时，每1MB触发一次

implementation

uses math;

resourcestring
  SInvalidInBufSize = '密文流与加密时的流大小不匹配';
  SReadError = '无法读取数据，快到结尾？';
  SWriteError = '无法写入数据，磁盘已满？';
  SBadStream = '无效的加密数据流';

type
  { AES异常类 }
  EAESError = class(Exception);
  PInteger = ^Integer;
  PCardinal = ^Cardinal;

const
  Rcon: array [1 .. 30] of Cardinal = ($00000001, $00000002, $00000004,
    $00000008, $00000010, $00000020, $00000040, $00000080, $0000001B, $00000036,
    $0000006C, $000000D8, $000000AB, $0000004D, $0000009A, $0000002F, $0000005E,
    $000000BC, $00000063, $000000C6, $00000097, $00000035, $0000006A, $000000D4,
    $000000B3, $0000007D, $000000FA, $000000EF, $000000C5, $00000091);

  ForwardTable: array [0 .. 255] of Cardinal = ($A56363C6, $847C7CF8, $997777EE,
    $8D7B7BF6, $0DF2F2FF, $BD6B6BD6, $B16F6FDE, $54C5C591, $50303060, $03010102,
    $A96767CE, $7D2B2B56, $19FEFEE7, $62D7D7B5, $E6ABAB4D, $9A7676EC, $45CACA8F,
    $9D82821F, $40C9C989, $877D7DFA, $15FAFAEF, $EB5959B2, $C947478E, $0BF0F0FB,
    $ECADAD41, $67D4D4B3, $FDA2A25F, $EAAFAF45, $BF9C9C23, $F7A4A453, $967272E4,
    $5BC0C09B, $C2B7B775, $1CFDFDE1, $AE93933D, $6A26264C, $5A36366C, $413F3F7E,
    $02F7F7F5, $4FCCCC83, $5C343468, $F4A5A551, $34E5E5D1, $08F1F1F9, $937171E2,
    $73D8D8AB, $53313162, $3F15152A, $0C040408, $52C7C795, $65232346, $5EC3C39D,
    $28181830, $A1969637, $0F05050A, $B59A9A2F, $0907070E, $36121224, $9B80801B,
    $3DE2E2DF, $26EBEBCD, $6927274E, $CDB2B27F, $9F7575EA, $1B090912, $9E83831D,
    $742C2C58, $2E1A1A34, $2D1B1B36, $B26E6EDC, $EE5A5AB4, $FBA0A05B, $F65252A4,
    $4D3B3B76, $61D6D6B7, $CEB3B37D, $7B292952, $3EE3E3DD, $712F2F5E, $97848413,
    $F55353A6, $68D1D1B9, $00000000, $2CEDEDC1, $60202040, $1FFCFCE3, $C8B1B179,
    $ED5B5BB6, $BE6A6AD4, $46CBCB8D, $D9BEBE67, $4B393972, $DE4A4A94, $D44C4C98,
    $E85858B0, $4ACFCF85, $6BD0D0BB, $2AEFEFC5, $E5AAAA4F, $16FBFBED, $C5434386,
    $D74D4D9A, $55333366, $94858511, $CF45458A, $10F9F9E9, $06020204, $817F7FFE,
    $F05050A0, $443C3C78, $BA9F9F25, $E3A8A84B, $F35151A2, $FEA3A35D, $C0404080,
    $8A8F8F05, $AD92923F, $BC9D9D21, $48383870, $04F5F5F1, $DFBCBC63, $C1B6B677,
    $75DADAAF, $63212142, $30101020, $1AFFFFE5, $0EF3F3FD, $6DD2D2BF, $4CCDCD81,
    $140C0C18, $35131326, $2FECECC3, $E15F5FBE, $A2979735, $CC444488, $3917172E,
    $57C4C493, $F2A7A755, $827E7EFC, $473D3D7A, $AC6464C8, $E75D5DBA, $2B191932,
    $957373E6, $A06060C0, $98818119, $D14F4F9E, $7FDCDCA3, $66222244, $7E2A2A54,
    $AB90903B, $8388880B, $CA46468C, $29EEEEC7, $D3B8B86B, $3C141428, $79DEDEA7,
    $E25E5EBC, $1D0B0B16, $76DBDBAD, $3BE0E0DB, $56323264, $4E3A3A74, $1E0A0A14,
    $DB494992, $0A06060C, $6C242448, $E45C5CB8, $5DC2C29F, $6ED3D3BD, $EFACAC43,
    $A66262C4, $A8919139, $A4959531, $37E4E4D3, $8B7979F2, $32E7E7D5, $43C8C88B,
    $5937376E, $B76D6DDA, $8C8D8D01, $64D5D5B1, $D24E4E9C, $E0A9A949, $B46C6CD8,
    $FA5656AC, $07F4F4F3, $25EAEACF, $AF6565CA, $8E7A7AF4, $E9AEAE47, $18080810,
    $D5BABA6F, $887878F0, $6F25254A, $722E2E5C, $241C1C38, $F1A6A657, $C7B4B473,
    $51C6C697, $23E8E8CB, $7CDDDDA1, $9C7474E8, $211F1F3E, $DD4B4B96, $DCBDBD61,
    $868B8B0D, $858A8A0F, $907070E0, $423E3E7C, $C4B5B571, $AA6666CC, $D8484890,
    $05030306, $01F6F6F7, $120E0E1C, $A36161C2, $5F35356A, $F95757AE, $D0B9B969,
    $91868617, $58C1C199, $271D1D3A, $B99E9E27, $38E1E1D9, $13F8F8EB, $B398982B,
    $33111122, $BB6969D2, $70D9D9A9, $898E8E07, $A7949433, $B69B9B2D, $221E1E3C,
    $92878715, $20E9E9C9, $49CECE87, $FF5555AA, $78282850, $7ADFDFA5, $8F8C8C03,
    $F8A1A159, $80898909, $170D0D1A, $DABFBF65, $31E6E6D7, $C6424284, $B86868D0,
    $C3414182, $B0999929, $772D2D5A, $110F0F1E, $CBB0B07B, $FC5454A8, $D6BBBB6D,
    $3A16162C);

  LastForwardTable: array [0 .. 255] of Cardinal = ($00000063, $0000007C,
    $00000077, $0000007B, $000000F2, $0000006B, $0000006F, $000000C5, $00000030,
    $00000001, $00000067, $0000002B, $000000FE, $000000D7, $000000AB, $00000076,
    $000000CA, $00000082, $000000C9, $0000007D, $000000FA, $00000059, $00000047,
    $000000F0, $000000AD, $000000D4, $000000A2, $000000AF, $0000009C, $000000A4,
    $00000072, $000000C0, $000000B7, $000000FD, $00000093, $00000026, $00000036,
    $0000003F, $000000F7, $000000CC, $00000034, $000000A5, $000000E5, $000000F1,
    $00000071, $000000D8, $00000031, $00000015, $00000004, $000000C7, $00000023,
    $000000C3, $00000018, $00000096, $00000005, $0000009A, $00000007, $00000012,
    $00000080, $000000E2, $000000EB, $00000027, $000000B2, $00000075, $00000009,
    $00000083, $0000002C, $0000001A, $0000001B, $0000006E, $0000005A, $000000A0,
    $00000052, $0000003B, $000000D6, $000000B3, $00000029, $000000E3, $0000002F,
    $00000084, $00000053, $000000D1, $00000000, $000000ED, $00000020, $000000FC,
    $000000B1, $0000005B, $0000006A, $000000CB, $000000BE, $00000039, $0000004A,
    $0000004C, $00000058, $000000CF, $000000D0, $000000EF, $000000AA, $000000FB,
    $00000043, $0000004D, $00000033, $00000085, $00000045, $000000F9, $00000002,
    $0000007F, $00000050, $0000003C, $0000009F, $000000A8, $00000051, $000000A3,
    $00000040, $0000008F, $00000092, $0000009D, $00000038, $000000F5, $000000BC,
    $000000B6, $000000DA, $00000021, $00000010, $000000FF, $000000F3, $000000D2,
    $000000CD, $0000000C, $00000013, $000000EC, $0000005F, $00000097, $00000044,
    $00000017, $000000C4, $000000A7, $0000007E, $0000003D, $00000064, $0000005D,
    $00000019, $00000073, $00000060, $00000081, $0000004F, $000000DC, $00000022,
    $0000002A, $00000090, $00000088, $00000046, $000000EE, $000000B8, $00000014,
    $000000DE, $0000005E, $0000000B, $000000DB, $000000E0, $00000032, $0000003A,
    $0000000A, $00000049, $00000006, $00000024, $0000005C, $000000C2, $000000D3,
    $000000AC, $00000062, $00000091, $00000095, $000000E4, $00000079, $000000E7,
    $000000C8, $00000037, $0000006D, $0000008D, $000000D5, $0000004E, $000000A9,
    $0000006C, $00000056, $000000F4, $000000EA, $00000065, $0000007A, $000000AE,
    $00000008, $000000BA, $00000078, $00000025, $0000002E, $0000001C, $000000A6,
    $000000B4, $000000C6, $000000E8, $000000DD, $00000074, $0000001F, $0000004B,
    $000000BD, $0000008B, $0000008A, $00000070, $0000003E, $000000B5, $00000066,
    $00000048, $00000003, $000000F6, $0000000E, $00000061, $00000035, $00000057,
    $000000B9, $00000086, $000000C1, $0000001D, $0000009E, $000000E1, $000000F8,
    $00000098, $00000011, $00000069, $000000D9, $0000008E, $00000094, $0000009B,
    $0000001E, $00000087, $000000E9, $000000CE, $00000055, $00000028, $000000DF,
    $0000008C, $000000A1, $00000089, $0000000D, $000000BF, $000000E6, $00000042,
    $00000068, $00000041, $00000099, $0000002D, $0000000F, $000000B0, $00000054,
    $000000BB, $00000016);

  InverseTable: array [0 .. 255] of Cardinal = ($50A7F451, $5365417E, $C3A4171A,
    $965E273A, $CB6BAB3B, $F1459D1F, $AB58FAAC, $9303E34B, $55FA3020, $F66D76AD,
    $9176CC88, $254C02F5, $FCD7E54F, $D7CB2AC5, $80443526, $8FA362B5, $495AB1DE,
    $671BBA25, $980EEA45, $E1C0FE5D, $02752FC3, $12F04C81, $A397468D, $C6F9D36B,
    $E75F8F03, $959C9215, $EB7A6DBF, $DA595295, $2D83BED4, $D3217458, $2969E049,
    $44C8C98E, $6A89C275, $78798EF4, $6B3E5899, $DD71B927, $B64FE1BE, $17AD88F0,
    $66AC20C9, $B43ACE7D, $184ADF63, $82311AE5, $60335197, $457F5362, $E07764B1,
    $84AE6BBB, $1CA081FE, $942B08F9, $58684870, $19FD458F, $876CDE94, $B7F87B52,
    $23D373AB, $E2024B72, $578F1FE3, $2AAB5566, $0728EBB2, $03C2B52F, $9A7BC586,
    $A50837D3, $F2872830, $B2A5BF23, $BA6A0302, $5C8216ED, $2B1CCF8A, $92B479A7,
    $F0F207F3, $A1E2694E, $CDF4DA65, $D5BE0506, $1F6234D1, $8AFEA6C4, $9D532E34,
    $A055F3A2, $32E18A05, $75EBF6A4, $39EC830B, $AAEF6040, $069F715E, $51106EBD,
    $F98A213E, $3D06DD96, $AE053EDD, $46BDE64D, $B58D5491, $055DC471, $6FD40604,
    $FF155060, $24FB9819, $97E9BDD6, $CC434089, $779ED967, $BD42E8B0, $888B8907,
    $385B19E7, $DBEEC879, $470A7CA1, $E90F427C, $C91E84F8, $00000000, $83868009,
    $48ED2B32, $AC70111E, $4E725A6C, $FBFF0EFD, $5638850F, $1ED5AE3D, $27392D36,
    $64D90F0A, $21A65C68, $D1545B9B, $3A2E3624, $B1670A0C, $0FE75793, $D296EEB4,
    $9E919B1B, $4FC5C080, $A220DC61, $694B775A, $161A121C, $0ABA93E2, $E52AA0C0,
    $43E0223C, $1D171B12, $0B0D090E, $ADC78BF2, $B9A8B62D, $C8A91E14, $8519F157,
    $4C0775AF, $BBDD99EE, $FD607FA3, $9F2601F7, $BCF5725C, $C53B6644, $347EFB5B,
    $7629438B, $DCC623CB, $68FCEDB6, $63F1E4B8, $CADC31D7, $10856342, $40229713,
    $2011C684, $7D244A85, $F83DBBD2, $1132F9AE, $6DA129C7, $4B2F9E1D, $F330B2DC,
    $EC52860D, $D0E3C177, $6C16B32B, $99B970A9, $FA489411, $2264E947, $C48CFCA8,
    $1A3FF0A0, $D82C7D56, $EF903322, $C74E4987, $C1D138D9, $FEA2CA8C, $360BD498,
    $CF81F5A6, $28DE7AA5, $268EB7DA, $A4BFAD3F, $E49D3A2C, $0D927850, $9BCC5F6A,
    $62467E54, $C2138DF6, $E8B8D890, $5EF7392E, $F5AFC382, $BE805D9F, $7C93D069,
    $A92DD56F, $B31225CF, $3B99ACC8, $A77D1810, $6E639CE8, $7BBB3BDB, $097826CD,
    $F418596E, $01B79AEC, $A89A4F83, $656E95E6, $7EE6FFAA, $08CFBC21, $E6E815EF,
    $D99BE7BA, $CE366F4A, $D4099FEA, $D67CB029, $AFB2A431, $31233F2A, $3094A5C6,
    $C066A235, $37BC4E74, $A6CA82FC, $B0D090E0, $15D8A733, $4A9804F1, $F7DAEC41,
    $0E50CD7F, $2FF69117, $8DD64D76, $4DB0EF43, $544DAACC, $DF0496E4, $E3B5D19E,
    $1B886A4C, $B81F2CC1, $7F516546, $04EA5E9D, $5D358C01, $737487FA, $2E410BFB,
    $5A1D67B3, $52D2DB92, $335610E9, $1347D66D, $8C61D79A, $7A0CA137, $8E14F859,
    $893C13EB, $EE27A9CE, $35C961B7, $EDE51CE1, $3CB1477A, $59DFD29C, $3F73F255,
    $79CE1418, $BF37C773, $EACDF753, $5BAAFD5F, $146F3DDF, $86DB4478, $81F3AFCA,
    $3EC468B9, $2C342438, $5F40A3C2, $72C31D16, $0C25E2BC, $8B493C28, $41950DFF,
    $7101A839, $DEB30C08, $9CE4B4D8, $90C15664, $6184CB7B, $70B632D5, $745C6C48,
    $4257B8D0);

  LastInverseTable: array [0 .. 255] of Cardinal = ($00000052, $00000009,
    $0000006A, $000000D5, $00000030, $00000036, $000000A5, $00000038, $000000BF,
    $00000040, $000000A3, $0000009E, $00000081, $000000F3, $000000D7, $000000FB,
    $0000007C, $000000E3, $00000039, $00000082, $0000009B, $0000002F, $000000FF,
    $00000087, $00000034, $0000008E, $00000043, $00000044, $000000C4, $000000DE,
    $000000E9, $000000CB, $00000054, $0000007B, $00000094, $00000032, $000000A6,
    $000000C2, $00000023, $0000003D, $000000EE, $0000004C, $00000095, $0000000B,
    $00000042, $000000FA, $000000C3, $0000004E, $00000008, $0000002E, $000000A1,
    $00000066, $00000028, $000000D9, $00000024, $000000B2, $00000076, $0000005B,
    $000000A2, $00000049, $0000006D, $0000008B, $000000D1, $00000025, $00000072,
    $000000F8, $000000F6, $00000064, $00000086, $00000068, $00000098, $00000016,
    $000000D4, $000000A4, $0000005C, $000000CC, $0000005D, $00000065, $000000B6,
    $00000092, $0000006C, $00000070, $00000048, $00000050, $000000FD, $000000ED,
    $000000B9, $000000DA, $0000005E, $00000015, $00000046, $00000057, $000000A7,
    $0000008D, $0000009D, $00000084, $00000090, $000000D8, $000000AB, $00000000,
    $0000008C, $000000BC, $000000D3, $0000000A, $000000F7, $000000E4, $00000058,
    $00000005, $000000B8, $000000B3, $00000045, $00000006, $000000D0, $0000002C,
    $0000001E, $0000008F, $000000CA, $0000003F, $0000000F, $00000002, $000000C1,
    $000000AF, $000000BD, $00000003, $00000001, $00000013, $0000008A, $0000006B,
    $0000003A, $00000091, $00000011, $00000041, $0000004F, $00000067, $000000DC,
    $000000EA, $00000097, $000000F2, $000000CF, $000000CE, $000000F0, $000000B4,
    $000000E6, $00000073, $00000096, $000000AC, $00000074, $00000022, $000000E7,
    $000000AD, $00000035, $00000085, $000000E2, $000000F9, $00000037, $000000E8,
    $0000001C, $00000075, $000000DF, $0000006E, $00000047, $000000F1, $0000001A,
    $00000071, $0000001D, $00000029, $000000C5, $00000089, $0000006F, $000000B7,
    $00000062, $0000000E, $000000AA, $00000018, $000000BE, $0000001B, $000000FC,
    $00000056, $0000003E, $0000004B, $000000C6, $000000D2, $00000079, $00000020,
    $0000009A, $000000DB, $000000C0, $000000FE, $00000078, $000000CD, $0000005A,
    $000000F4, $0000001F, $000000DD, $000000A8, $00000033, $00000088, $00000007,
    $000000C7, $00000031, $000000B1, $00000012, $00000010, $00000059, $00000027,
    $00000080, $000000EC, $0000005F, $00000060, $00000051, $0000007F, $000000A9,
    $00000019, $000000B5, $0000004A, $0000000D, $0000002D, $000000E5, $0000007A,
    $0000009F, $00000093, $000000C9, $0000009C, $000000EF, $000000A0, $000000E0,
    $0000003B, $0000004D, $000000AE, $0000002A, $000000F5, $000000B0, $000000C8,
    $000000EB, $000000BB, $0000003C, $00000083, $00000053, $00000099, $00000061,
    $00000017, $0000002B, $00000004, $0000007E, $000000BA, $00000077, $000000D6,
    $00000026, $000000E1, $00000069, $00000014, $00000063, $00000055, $00000021,
    $0000000C, $0000007D);

procedure ExpandAESKeyForEncryption(const Key: TQAESKey128;
  var ExpandedKey: TQAESExpandedKey128); overload;
var
  I, J: Integer;
  T: Cardinal;
  W0, W1, W2, W3: Cardinal;
begin
  ExpandedKey[0] := PCardinal(@Key[0])^;
  ExpandedKey[1] := PCardinal(@Key[4])^;
  ExpandedKey[2] := PCardinal(@Key[8])^;
  ExpandedKey[3] := PCardinal(@Key[12])^;
  I := 0;
  J := 1;
  repeat
    T := (ExpandedKey[I + 3] shl 24) or (ExpandedKey[I + 3] shr 8);
    W0 := LastForwardTable[byte(T)];
    W1 := LastForwardTable[byte(T shr 8)];
    W2 := LastForwardTable[byte(T shr 16)];
    W3 := LastForwardTable[byte(T shr 24)];
    ExpandedKey[I + 4] := ExpandedKey[I] xor (W0 xor ((W1 shl 8) or (W1 shr 24))
      xor ((W2 shl 16) or (W2 shr 16)) xor ((W3 shl 24) or (W3 shr 8)))
      xor Rcon[J];
    Inc(J);
    ExpandedKey[I + 5] := ExpandedKey[I + 1] xor ExpandedKey[I + 4];
    ExpandedKey[I + 6] := ExpandedKey[I + 2] xor ExpandedKey[I + 5];
    ExpandedKey[I + 7] := ExpandedKey[I + 3] xor ExpandedKey[I + 6];
    Inc(I, 4);
  until I >= 40;
end;

procedure ExpandAESKeyForEncryption(const Key: TQAESKey192;
  var ExpandedKey: TQAESExpandedKey192); overload;
var
  I, J: Integer;
  T: Cardinal;
  W0, W1, W2, W3: Cardinal;
begin
  ExpandedKey[0] := PCardinal(@Key[0])^;
  ExpandedKey[1] := PCardinal(@Key[4])^;
  ExpandedKey[2] := PCardinal(@Key[8])^;
  ExpandedKey[3] := PCardinal(@Key[12])^;
  ExpandedKey[4] := PCardinal(@Key[16])^;
  ExpandedKey[5] := PCardinal(@Key[20])^;
  I := 0;
  J := 1;
  repeat
    T := (ExpandedKey[I + 5] shl 24) or (ExpandedKey[I + 5] shr 8);
    W0 := LastForwardTable[byte(T)];
    W1 := LastForwardTable[byte(T shr 8)];
    W2 := LastForwardTable[byte(T shr 16)];
    W3 := LastForwardTable[byte(T shr 24)];
    ExpandedKey[I + 6] := ExpandedKey[I] xor (W0 xor ((W1 shl 8) or (W1 shr 24))
      xor ((W2 shl 16) or (W2 shr 16)) xor ((W3 shl 24) or (W3 shr 8)))
      xor Rcon[J];
    Inc(J);
    ExpandedKey[I + 7] := ExpandedKey[I + 1] xor ExpandedKey[I + 6];
    ExpandedKey[I + 8] := ExpandedKey[I + 2] xor ExpandedKey[I + 7];
    ExpandedKey[I + 9] := ExpandedKey[I + 3] xor ExpandedKey[I + 8];
    ExpandedKey[I + 10] := ExpandedKey[I + 4] xor ExpandedKey[I + 9];
    ExpandedKey[I + 11] := ExpandedKey[I + 5] xor ExpandedKey[I + 10];
    Inc(I, 6);
  until I >= 46;
end;

procedure ExpandAESKeyForEncryption(const Key: TQAESKey256;
  var ExpandedKey: TQAESExpandedKey256); overload;
var
  I, J: Integer;
  T: Cardinal;
  W0, W1, W2, W3: Cardinal;
begin
  ExpandedKey[0] := PCardinal(@Key[0])^;
  ExpandedKey[1] := PCardinal(@Key[4])^;
  ExpandedKey[2] := PCardinal(@Key[8])^;
  ExpandedKey[3] := PCardinal(@Key[12])^;
  ExpandedKey[4] := PCardinal(@Key[16])^;
  ExpandedKey[5] := PCardinal(@Key[20])^;
  ExpandedKey[6] := PCardinal(@Key[24])^;
  ExpandedKey[7] := PCardinal(@Key[28])^;
  I := 0;
  J := 1;
  repeat
    T := (ExpandedKey[I + 7] shl 24) or (ExpandedKey[I + 7] shr 8);
    W0 := LastForwardTable[byte(T)];
    W1 := LastForwardTable[byte(T shr 8)];
    W2 := LastForwardTable[byte(T shr 16)];
    W3 := LastForwardTable[byte(T shr 24)];
    ExpandedKey[I + 8] := ExpandedKey[I] xor (W0 xor ((W1 shl 8) or (W1 shr 24))
      xor ((W2 shl 16) or (W2 shr 16)) xor ((W3 shl 24) or (W3 shr 8)))
      xor Rcon[J];
    Inc(J);
    ExpandedKey[I + 9] := ExpandedKey[I + 1] xor ExpandedKey[I + 8];
    ExpandedKey[I + 10] := ExpandedKey[I + 2] xor ExpandedKey[I + 9];
    ExpandedKey[I + 11] := ExpandedKey[I + 3] xor ExpandedKey[I + 10];
    W0 := LastForwardTable[byte(ExpandedKey[I + 11])];
    W1 := LastForwardTable[byte(ExpandedKey[I + 11] shr 8)];
    W2 := LastForwardTable[byte(ExpandedKey[I + 11] shr 16)];
    W3 := LastForwardTable[byte(ExpandedKey[I + 11] shr 24)];
    ExpandedKey[I + 12] := ExpandedKey[I + 4]
      xor (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
      xor ((W3 shl 24) or (W3 shr 8)));
    ExpandedKey[I + 13] := ExpandedKey[I + 5] xor ExpandedKey[I + 12];
    ExpandedKey[I + 14] := ExpandedKey[I + 6] xor ExpandedKey[I + 13];
    ExpandedKey[I + 15] := ExpandedKey[I + 7] xor ExpandedKey[I + 14];
    Inc(I, 8);
  until I >= 52;
end;

procedure EncryptAES(const InBuf: TQAESBuffer; const Key: TQAESExpandedKey128;
  var OutBuf: TQAESBuffer); overload;
var
  T0, T1: array [0 .. 3] of Cardinal;
  W0, W1, W2, W3: Cardinal;
begin
  // initializing
  T0[0] := PCardinal(@InBuf[0])^ xor Key[0];
  T0[1] := PCardinal(@InBuf[4])^ xor Key[1];
  T0[2] := PCardinal(@InBuf[8])^ xor Key[2];
  T0[3] := PCardinal(@InBuf[12])^ xor Key[3];
  // performing transformation 9 times
  // round 1
  W0 := ForwardTable[byte(T0[0])];
  W1 := ForwardTable[byte(T0[1] shr 8)];
  W2 := ForwardTable[byte(T0[2] shr 16)];
  W3 := ForwardTable[byte(T0[3] shr 24)];
  T1[0] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[4];
  W0 := ForwardTable[byte(T0[1])];
  W1 := ForwardTable[byte(T0[2] shr 8)];
  W2 := ForwardTable[byte(T0[3] shr 16)];
  W3 := ForwardTable[byte(T0[0] shr 24)];
  T1[1] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[5];
  W0 := ForwardTable[byte(T0[2])];
  W1 := ForwardTable[byte(T0[3] shr 8)];
  W2 := ForwardTable[byte(T0[0] shr 16)];
  W3 := ForwardTable[byte(T0[1] shr 24)];
  T1[2] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[6];
  W0 := ForwardTable[byte(T0[3])];
  W1 := ForwardTable[byte(T0[0] shr 8)];
  W2 := ForwardTable[byte(T0[1] shr 16)];
  W3 := ForwardTable[byte(T0[2] shr 24)];
  T1[3] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[7];
  // round 2
  W0 := ForwardTable[byte(T1[0])];
  W1 := ForwardTable[byte(T1[1] shr 8)];
  W2 := ForwardTable[byte(T1[2] shr 16)];
  W3 := ForwardTable[byte(T1[3] shr 24)];
  T0[0] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[8];
  W0 := ForwardTable[byte(T1[1])];
  W1 := ForwardTable[byte(T1[2] shr 8)];
  W2 := ForwardTable[byte(T1[3] shr 16)];
  W3 := ForwardTable[byte(T1[0] shr 24)];
  T0[1] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[9];
  W0 := ForwardTable[byte(T1[2])];
  W1 := ForwardTable[byte(T1[3] shr 8)];
  W2 := ForwardTable[byte(T1[0] shr 16)];
  W3 := ForwardTable[byte(T1[1] shr 24)];
  T0[2] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[10];
  W0 := ForwardTable[byte(T1[3])];
  W1 := ForwardTable[byte(T1[0] shr 8)];
  W2 := ForwardTable[byte(T1[1] shr 16)];
  W3 := ForwardTable[byte(T1[2] shr 24)];
  T0[3] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[11];
  // round 3
  W0 := ForwardTable[byte(T0[0])];
  W1 := ForwardTable[byte(T0[1] shr 8)];
  W2 := ForwardTable[byte(T0[2] shr 16)];
  W3 := ForwardTable[byte(T0[3] shr 24)];
  T1[0] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[12];
  W0 := ForwardTable[byte(T0[1])];
  W1 := ForwardTable[byte(T0[2] shr 8)];
  W2 := ForwardTable[byte(T0[3] shr 16)];
  W3 := ForwardTable[byte(T0[0] shr 24)];
  T1[1] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[13];
  W0 := ForwardTable[byte(T0[2])];
  W1 := ForwardTable[byte(T0[3] shr 8)];
  W2 := ForwardTable[byte(T0[0] shr 16)];
  W3 := ForwardTable[byte(T0[1] shr 24)];
  T1[2] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[14];
  W0 := ForwardTable[byte(T0[3])];
  W1 := ForwardTable[byte(T0[0] shr 8)];
  W2 := ForwardTable[byte(T0[1] shr 16)];
  W3 := ForwardTable[byte(T0[2] shr 24)];
  T1[3] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[15];
  // round 4
  W0 := ForwardTable[byte(T1[0])];
  W1 := ForwardTable[byte(T1[1] shr 8)];
  W2 := ForwardTable[byte(T1[2] shr 16)];
  W3 := ForwardTable[byte(T1[3] shr 24)];
  T0[0] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[16];
  W0 := ForwardTable[byte(T1[1])];
  W1 := ForwardTable[byte(T1[2] shr 8)];
  W2 := ForwardTable[byte(T1[3] shr 16)];
  W3 := ForwardTable[byte(T1[0] shr 24)];
  T0[1] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[17];
  W0 := ForwardTable[byte(T1[2])];
  W1 := ForwardTable[byte(T1[3] shr 8)];
  W2 := ForwardTable[byte(T1[0] shr 16)];
  W3 := ForwardTable[byte(T1[1] shr 24)];
  T0[2] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[18];
  W0 := ForwardTable[byte(T1[3])];
  W1 := ForwardTable[byte(T1[0] shr 8)];
  W2 := ForwardTable[byte(T1[1] shr 16)];
  W3 := ForwardTable[byte(T1[2] shr 24)];
  T0[3] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[19];
  // round 5
  W0 := ForwardTable[byte(T0[0])];
  W1 := ForwardTable[byte(T0[1] shr 8)];
  W2 := ForwardTable[byte(T0[2] shr 16)];
  W3 := ForwardTable[byte(T0[3] shr 24)];
  T1[0] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[20];
  W0 := ForwardTable[byte(T0[1])];
  W1 := ForwardTable[byte(T0[2] shr 8)];
  W2 := ForwardTable[byte(T0[3] shr 16)];
  W3 := ForwardTable[byte(T0[0] shr 24)];
  T1[1] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[21];
  W0 := ForwardTable[byte(T0[2])];
  W1 := ForwardTable[byte(T0[3] shr 8)];
  W2 := ForwardTable[byte(T0[0] shr 16)];
  W3 := ForwardTable[byte(T0[1] shr 24)];
  T1[2] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[22];
  W0 := ForwardTable[byte(T0[3])];
  W1 := ForwardTable[byte(T0[0] shr 8)];
  W2 := ForwardTable[byte(T0[1] shr 16)];
  W3 := ForwardTable[byte(T0[2] shr 24)];
  T1[3] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[23];
  // round 6
  W0 := ForwardTable[byte(T1[0])];
  W1 := ForwardTable[byte(T1[1] shr 8)];
  W2 := ForwardTable[byte(T1[2] shr 16)];
  W3 := ForwardTable[byte(T1[3] shr 24)];
  T0[0] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[24];
  W0 := ForwardTable[byte(T1[1])];
  W1 := ForwardTable[byte(T1[2] shr 8)];
  W2 := ForwardTable[byte(T1[3] shr 16)];
  W3 := ForwardTable[byte(T1[0] shr 24)];
  T0[1] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[25];
  W0 := ForwardTable[byte(T1[2])];
  W1 := ForwardTable[byte(T1[3] shr 8)];
  W2 := ForwardTable[byte(T1[0] shr 16)];
  W3 := ForwardTable[byte(T1[1] shr 24)];
  T0[2] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[26];
  W0 := ForwardTable[byte(T1[3])];
  W1 := ForwardTable[byte(T1[0] shr 8)];
  W2 := ForwardTable[byte(T1[1] shr 16)];
  W3 := ForwardTable[byte(T1[2] shr 24)];
  T0[3] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[27];
  // round 7
  W0 := ForwardTable[byte(T0[0])];
  W1 := ForwardTable[byte(T0[1] shr 8)];
  W2 := ForwardTable[byte(T0[2] shr 16)];
  W3 := ForwardTable[byte(T0[3] shr 24)];
  T1[0] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[28];
  W0 := ForwardTable[byte(T0[1])];
  W1 := ForwardTable[byte(T0[2] shr 8)];
  W2 := ForwardTable[byte(T0[3] shr 16)];
  W3 := ForwardTable[byte(T0[0] shr 24)];
  T1[1] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[29];
  W0 := ForwardTable[byte(T0[2])];
  W1 := ForwardTable[byte(T0[3] shr 8)];
  W2 := ForwardTable[byte(T0[0] shr 16)];
  W3 := ForwardTable[byte(T0[1] shr 24)];
  T1[2] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[30];
  W0 := ForwardTable[byte(T0[3])];
  W1 := ForwardTable[byte(T0[0] shr 8)];
  W2 := ForwardTable[byte(T0[1] shr 16)];
  W3 := ForwardTable[byte(T0[2] shr 24)];
  T1[3] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[31];
  // round 8
  W0 := ForwardTable[byte(T1[0])];
  W1 := ForwardTable[byte(T1[1] shr 8)];
  W2 := ForwardTable[byte(T1[2] shr 16)];
  W3 := ForwardTable[byte(T1[3] shr 24)];
  T0[0] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[32];
  W0 := ForwardTable[byte(T1[1])];
  W1 := ForwardTable[byte(T1[2] shr 8)];
  W2 := ForwardTable[byte(T1[3] shr 16)];
  W3 := ForwardTable[byte(T1[0] shr 24)];
  T0[1] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[33];
  W0 := ForwardTable[byte(T1[2])];
  W1 := ForwardTable[byte(T1[3] shr 8)];
  W2 := ForwardTable[byte(T1[0] shr 16)];
  W3 := ForwardTable[byte(T1[1] shr 24)];
  T0[2] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[34];
  W0 := ForwardTable[byte(T1[3])];
  W1 := ForwardTable[byte(T1[0] shr 8)];
  W2 := ForwardTable[byte(T1[1] shr 16)];
  W3 := ForwardTable[byte(T1[2] shr 24)];
  T0[3] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[35];
  // round 9
  W0 := ForwardTable[byte(T0[0])];
  W1 := ForwardTable[byte(T0[1] shr 8)];
  W2 := ForwardTable[byte(T0[2] shr 16)];
  W3 := ForwardTable[byte(T0[3] shr 24)];
  T1[0] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[36];
  W0 := ForwardTable[byte(T0[1])];
  W1 := ForwardTable[byte(T0[2] shr 8)];
  W2 := ForwardTable[byte(T0[3] shr 16)];
  W3 := ForwardTable[byte(T0[0] shr 24)];
  T1[1] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[37];
  W0 := ForwardTable[byte(T0[2])];
  W1 := ForwardTable[byte(T0[3] shr 8)];
  W2 := ForwardTable[byte(T0[0] shr 16)];
  W3 := ForwardTable[byte(T0[1] shr 24)];
  T1[2] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[38];
  W0 := ForwardTable[byte(T0[3])];
  W1 := ForwardTable[byte(T0[0] shr 8)];
  W2 := ForwardTable[byte(T0[1] shr 16)];
  W3 := ForwardTable[byte(T0[2] shr 24)];
  T1[3] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[39];
  // last round of transformations
  W0 := LastForwardTable[byte(T1[0])];
  W1 := LastForwardTable[byte(T1[1] shr 8)];
  W2 := LastForwardTable[byte(T1[2] shr 16)];
  W3 := LastForwardTable[byte(T1[3] shr 24)];
  T0[0] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[40];
  W0 := LastForwardTable[byte(T1[1])];
  W1 := LastForwardTable[byte(T1[2] shr 8)];
  W2 := LastForwardTable[byte(T1[3] shr 16)];
  W3 := LastForwardTable[byte(T1[0] shr 24)];
  T0[1] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[41];
  W0 := LastForwardTable[byte(T1[2])];
  W1 := LastForwardTable[byte(T1[3] shr 8)];
  W2 := LastForwardTable[byte(T1[0] shr 16)];
  W3 := LastForwardTable[byte(T1[1] shr 24)];
  T0[2] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[42];
  W0 := LastForwardTable[byte(T1[3])];
  W1 := LastForwardTable[byte(T1[0] shr 8)];
  W2 := LastForwardTable[byte(T1[1] shr 16)];
  W3 := LastForwardTable[byte(T1[2] shr 24)];
  T0[3] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[43];
  // finalizing
  PCardinal(@OutBuf[0])^ := T0[0];
  PCardinal(@OutBuf[4])^ := T0[1];
  PCardinal(@OutBuf[8])^ := T0[2];
  PCardinal(@OutBuf[12])^ := T0[3];
end;

procedure EncryptAES(const InBuf: TQAESBuffer; const Key: TQAESExpandedKey192;
  var OutBuf: TQAESBuffer); overload;
var
  T0, T1: array [0 .. 3] of Cardinal;
  W0, W1, W2, W3: Cardinal;
begin
  // initializing
  T0[0] := PCardinal(@InBuf[0])^ xor Key[0];
  T0[1] := PCardinal(@InBuf[4])^ xor Key[1];
  T0[2] := PCardinal(@InBuf[8])^ xor Key[2];
  T0[3] := PCardinal(@InBuf[12])^ xor Key[3];
  // performing transformation 11 times
  // round 1
  W0 := ForwardTable[byte(T0[0])];
  W1 := ForwardTable[byte(T0[1] shr 8)];
  W2 := ForwardTable[byte(T0[2] shr 16)];
  W3 := ForwardTable[byte(T0[3] shr 24)];
  T1[0] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[4];
  W0 := ForwardTable[byte(T0[1])];
  W1 := ForwardTable[byte(T0[2] shr 8)];
  W2 := ForwardTable[byte(T0[3] shr 16)];
  W3 := ForwardTable[byte(T0[0] shr 24)];
  T1[1] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[5];
  W0 := ForwardTable[byte(T0[2])];
  W1 := ForwardTable[byte(T0[3] shr 8)];
  W2 := ForwardTable[byte(T0[0] shr 16)];
  W3 := ForwardTable[byte(T0[1] shr 24)];
  T1[2] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[6];
  W0 := ForwardTable[byte(T0[3])];
  W1 := ForwardTable[byte(T0[0] shr 8)];
  W2 := ForwardTable[byte(T0[1] shr 16)];
  W3 := ForwardTable[byte(T0[2] shr 24)];
  T1[3] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[7];
  // round 2
  W0 := ForwardTable[byte(T1[0])];
  W1 := ForwardTable[byte(T1[1] shr 8)];
  W2 := ForwardTable[byte(T1[2] shr 16)];
  W3 := ForwardTable[byte(T1[3] shr 24)];
  T0[0] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[8];
  W0 := ForwardTable[byte(T1[1])];
  W1 := ForwardTable[byte(T1[2] shr 8)];
  W2 := ForwardTable[byte(T1[3] shr 16)];
  W3 := ForwardTable[byte(T1[0] shr 24)];
  T0[1] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[9];
  W0 := ForwardTable[byte(T1[2])];
  W1 := ForwardTable[byte(T1[3] shr 8)];
  W2 := ForwardTable[byte(T1[0] shr 16)];
  W3 := ForwardTable[byte(T1[1] shr 24)];
  T0[2] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[10];
  W0 := ForwardTable[byte(T1[3])];
  W1 := ForwardTable[byte(T1[0] shr 8)];
  W2 := ForwardTable[byte(T1[1] shr 16)];
  W3 := ForwardTable[byte(T1[2] shr 24)];
  T0[3] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[11];
  // round 3
  W0 := ForwardTable[byte(T0[0])];
  W1 := ForwardTable[byte(T0[1] shr 8)];
  W2 := ForwardTable[byte(T0[2] shr 16)];
  W3 := ForwardTable[byte(T0[3] shr 24)];
  T1[0] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[12];
  W0 := ForwardTable[byte(T0[1])];
  W1 := ForwardTable[byte(T0[2] shr 8)];
  W2 := ForwardTable[byte(T0[3] shr 16)];
  W3 := ForwardTable[byte(T0[0] shr 24)];
  T1[1] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[13];
  W0 := ForwardTable[byte(T0[2])];
  W1 := ForwardTable[byte(T0[3] shr 8)];
  W2 := ForwardTable[byte(T0[0] shr 16)];
  W3 := ForwardTable[byte(T0[1] shr 24)];
  T1[2] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[14];
  W0 := ForwardTable[byte(T0[3])];
  W1 := ForwardTable[byte(T0[0] shr 8)];
  W2 := ForwardTable[byte(T0[1] shr 16)];
  W3 := ForwardTable[byte(T0[2] shr 24)];
  T1[3] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[15];
  // round 4
  W0 := ForwardTable[byte(T1[0])];
  W1 := ForwardTable[byte(T1[1] shr 8)];
  W2 := ForwardTable[byte(T1[2] shr 16)];
  W3 := ForwardTable[byte(T1[3] shr 24)];
  T0[0] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[16];
  W0 := ForwardTable[byte(T1[1])];
  W1 := ForwardTable[byte(T1[2] shr 8)];
  W2 := ForwardTable[byte(T1[3] shr 16)];
  W3 := ForwardTable[byte(T1[0] shr 24)];
  T0[1] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[17];
  W0 := ForwardTable[byte(T1[2])];
  W1 := ForwardTable[byte(T1[3] shr 8)];
  W2 := ForwardTable[byte(T1[0] shr 16)];
  W3 := ForwardTable[byte(T1[1] shr 24)];
  T0[2] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[18];
  W0 := ForwardTable[byte(T1[3])];
  W1 := ForwardTable[byte(T1[0] shr 8)];
  W2 := ForwardTable[byte(T1[1] shr 16)];
  W3 := ForwardTable[byte(T1[2] shr 24)];
  T0[3] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[19];
  // round 5
  W0 := ForwardTable[byte(T0[0])];
  W1 := ForwardTable[byte(T0[1] shr 8)];
  W2 := ForwardTable[byte(T0[2] shr 16)];
  W3 := ForwardTable[byte(T0[3] shr 24)];
  T1[0] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[20];
  W0 := ForwardTable[byte(T0[1])];
  W1 := ForwardTable[byte(T0[2] shr 8)];
  W2 := ForwardTable[byte(T0[3] shr 16)];
  W3 := ForwardTable[byte(T0[0] shr 24)];
  T1[1] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[21];
  W0 := ForwardTable[byte(T0[2])];
  W1 := ForwardTable[byte(T0[3] shr 8)];
  W2 := ForwardTable[byte(T0[0] shr 16)];
  W3 := ForwardTable[byte(T0[1] shr 24)];
  T1[2] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[22];
  W0 := ForwardTable[byte(T0[3])];
  W1 := ForwardTable[byte(T0[0] shr 8)];
  W2 := ForwardTable[byte(T0[1] shr 16)];
  W3 := ForwardTable[byte(T0[2] shr 24)];
  T1[3] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[23];
  // round 6
  W0 := ForwardTable[byte(T1[0])];
  W1 := ForwardTable[byte(T1[1] shr 8)];
  W2 := ForwardTable[byte(T1[2] shr 16)];
  W3 := ForwardTable[byte(T1[3] shr 24)];
  T0[0] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[24];
  W0 := ForwardTable[byte(T1[1])];
  W1 := ForwardTable[byte(T1[2] shr 8)];
  W2 := ForwardTable[byte(T1[3] shr 16)];
  W3 := ForwardTable[byte(T1[0] shr 24)];
  T0[1] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[25];
  W0 := ForwardTable[byte(T1[2])];
  W1 := ForwardTable[byte(T1[3] shr 8)];
  W2 := ForwardTable[byte(T1[0] shr 16)];
  W3 := ForwardTable[byte(T1[1] shr 24)];
  T0[2] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[26];
  W0 := ForwardTable[byte(T1[3])];
  W1 := ForwardTable[byte(T1[0] shr 8)];
  W2 := ForwardTable[byte(T1[1] shr 16)];
  W3 := ForwardTable[byte(T1[2] shr 24)];
  T0[3] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[27];
  // round 7
  W0 := ForwardTable[byte(T0[0])];
  W1 := ForwardTable[byte(T0[1] shr 8)];
  W2 := ForwardTable[byte(T0[2] shr 16)];
  W3 := ForwardTable[byte(T0[3] shr 24)];
  T1[0] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[28];
  W0 := ForwardTable[byte(T0[1])];
  W1 := ForwardTable[byte(T0[2] shr 8)];
  W2 := ForwardTable[byte(T0[3] shr 16)];
  W3 := ForwardTable[byte(T0[0] shr 24)];
  T1[1] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[29];
  W0 := ForwardTable[byte(T0[2])];
  W1 := ForwardTable[byte(T0[3] shr 8)];
  W2 := ForwardTable[byte(T0[0] shr 16)];
  W3 := ForwardTable[byte(T0[1] shr 24)];
  T1[2] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[30];
  W0 := ForwardTable[byte(T0[3])];
  W1 := ForwardTable[byte(T0[0] shr 8)];
  W2 := ForwardTable[byte(T0[1] shr 16)];
  W3 := ForwardTable[byte(T0[2] shr 24)];
  T1[3] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[31];
  // round 8
  W0 := ForwardTable[byte(T1[0])];
  W1 := ForwardTable[byte(T1[1] shr 8)];
  W2 := ForwardTable[byte(T1[2] shr 16)];
  W3 := ForwardTable[byte(T1[3] shr 24)];
  T0[0] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[32];
  W0 := ForwardTable[byte(T1[1])];
  W1 := ForwardTable[byte(T1[2] shr 8)];
  W2 := ForwardTable[byte(T1[3] shr 16)];
  W3 := ForwardTable[byte(T1[0] shr 24)];
  T0[1] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[33];
  W0 := ForwardTable[byte(T1[2])];
  W1 := ForwardTable[byte(T1[3] shr 8)];
  W2 := ForwardTable[byte(T1[0] shr 16)];
  W3 := ForwardTable[byte(T1[1] shr 24)];
  T0[2] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[34];
  W0 := ForwardTable[byte(T1[3])];
  W1 := ForwardTable[byte(T1[0] shr 8)];
  W2 := ForwardTable[byte(T1[1] shr 16)];
  W3 := ForwardTable[byte(T1[2] shr 24)];
  T0[3] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[35];
  // round 9
  W0 := ForwardTable[byte(T0[0])];
  W1 := ForwardTable[byte(T0[1] shr 8)];
  W2 := ForwardTable[byte(T0[2] shr 16)];
  W3 := ForwardTable[byte(T0[3] shr 24)];
  T1[0] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[36];
  W0 := ForwardTable[byte(T0[1])];
  W1 := ForwardTable[byte(T0[2] shr 8)];
  W2 := ForwardTable[byte(T0[3] shr 16)];
  W3 := ForwardTable[byte(T0[0] shr 24)];
  T1[1] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[37];
  W0 := ForwardTable[byte(T0[2])];
  W1 := ForwardTable[byte(T0[3] shr 8)];
  W2 := ForwardTable[byte(T0[0] shr 16)];
  W3 := ForwardTable[byte(T0[1] shr 24)];
  T1[2] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[38];
  W0 := ForwardTable[byte(T0[3])];
  W1 := ForwardTable[byte(T0[0] shr 8)];
  W2 := ForwardTable[byte(T0[1] shr 16)];
  W3 := ForwardTable[byte(T0[2] shr 24)];
  T1[3] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[39];
  // round 10
  W0 := ForwardTable[byte(T1[0])];
  W1 := ForwardTable[byte(T1[1] shr 8)];
  W2 := ForwardTable[byte(T1[2] shr 16)];
  W3 := ForwardTable[byte(T1[3] shr 24)];
  T0[0] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[40];
  W0 := ForwardTable[byte(T1[1])];
  W1 := ForwardTable[byte(T1[2] shr 8)];
  W2 := ForwardTable[byte(T1[3] shr 16)];
  W3 := ForwardTable[byte(T1[0] shr 24)];
  T0[1] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[41];
  W0 := ForwardTable[byte(T1[2])];
  W1 := ForwardTable[byte(T1[3] shr 8)];
  W2 := ForwardTable[byte(T1[0] shr 16)];
  W3 := ForwardTable[byte(T1[1] shr 24)];
  T0[2] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[42];
  W0 := ForwardTable[byte(T1[3])];
  W1 := ForwardTable[byte(T1[0] shr 8)];
  W2 := ForwardTable[byte(T1[1] shr 16)];
  W3 := ForwardTable[byte(T1[2] shr 24)];
  T0[3] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[43];
  // round 11
  W0 := ForwardTable[byte(T0[0])];
  W1 := ForwardTable[byte(T0[1] shr 8)];
  W2 := ForwardTable[byte(T0[2] shr 16)];
  W3 := ForwardTable[byte(T0[3] shr 24)];
  T1[0] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[44];
  W0 := ForwardTable[byte(T0[1])];
  W1 := ForwardTable[byte(T0[2] shr 8)];
  W2 := ForwardTable[byte(T0[3] shr 16)];
  W3 := ForwardTable[byte(T0[0] shr 24)];
  T1[1] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[45];
  W0 := ForwardTable[byte(T0[2])];
  W1 := ForwardTable[byte(T0[3] shr 8)];
  W2 := ForwardTable[byte(T0[0] shr 16)];
  W3 := ForwardTable[byte(T0[1] shr 24)];
  T1[2] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[46];
  W0 := ForwardTable[byte(T0[3])];
  W1 := ForwardTable[byte(T0[0] shr 8)];
  W2 := ForwardTable[byte(T0[1] shr 16)];
  W3 := ForwardTable[byte(T0[2] shr 24)];
  T1[3] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[47];
  // last round of transformations
  W0 := LastForwardTable[byte(T1[0])];
  W1 := LastForwardTable[byte(T1[1] shr 8)];
  W2 := LastForwardTable[byte(T1[2] shr 16)];
  W3 := LastForwardTable[byte(T1[3] shr 24)];
  T0[0] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[48];
  W0 := LastForwardTable[byte(T1[1])];
  W1 := LastForwardTable[byte(T1[2] shr 8)];
  W2 := LastForwardTable[byte(T1[3] shr 16)];
  W3 := LastForwardTable[byte(T1[0] shr 24)];
  T0[1] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[49];
  W0 := LastForwardTable[byte(T1[2])];
  W1 := LastForwardTable[byte(T1[3] shr 8)];
  W2 := LastForwardTable[byte(T1[0] shr 16)];
  W3 := LastForwardTable[byte(T1[1] shr 24)];
  T0[2] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[50];
  W0 := LastForwardTable[byte(T1[3])];
  W1 := LastForwardTable[byte(T1[0] shr 8)];
  W2 := LastForwardTable[byte(T1[1] shr 16)];
  W3 := LastForwardTable[byte(T1[2] shr 24)];
  T0[3] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[51];
  // finalizing
  PCardinal(@OutBuf[0])^ := T0[0];
  PCardinal(@OutBuf[4])^ := T0[1];
  PCardinal(@OutBuf[8])^ := T0[2];
  PCardinal(@OutBuf[12])^ := T0[3];
end;

procedure EncryptAES(const InBuf: TQAESBuffer; const Key: TQAESExpandedKey256;
  var OutBuf: TQAESBuffer); overload;
var
  T0, T1: array [0 .. 3] of Cardinal;
  W0, W1, W2, W3: Cardinal;
begin
  // initializing
  T0[0] := PCardinal(@InBuf[0])^ xor Key[0];
  T0[1] := PCardinal(@InBuf[4])^ xor Key[1];
  T0[2] := PCardinal(@InBuf[8])^ xor Key[2];
  T0[3] := PCardinal(@InBuf[12])^ xor Key[3];
  // performing transformation 13 times
  // round 1
  W0 := ForwardTable[byte(T0[0])];
  W1 := ForwardTable[byte(T0[1] shr 8)];
  W2 := ForwardTable[byte(T0[2] shr 16)];
  W3 := ForwardTable[byte(T0[3] shr 24)];
  T1[0] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[4];
  W0 := ForwardTable[byte(T0[1])];
  W1 := ForwardTable[byte(T0[2] shr 8)];
  W2 := ForwardTable[byte(T0[3] shr 16)];
  W3 := ForwardTable[byte(T0[0] shr 24)];
  T1[1] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[5];
  W0 := ForwardTable[byte(T0[2])];
  W1 := ForwardTable[byte(T0[3] shr 8)];
  W2 := ForwardTable[byte(T0[0] shr 16)];
  W3 := ForwardTable[byte(T0[1] shr 24)];
  T1[2] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[6];
  W0 := ForwardTable[byte(T0[3])];
  W1 := ForwardTable[byte(T0[0] shr 8)];
  W2 := ForwardTable[byte(T0[1] shr 16)];
  W3 := ForwardTable[byte(T0[2] shr 24)];
  T1[3] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[7];
  // round 2
  W0 := ForwardTable[byte(T1[0])];
  W1 := ForwardTable[byte(T1[1] shr 8)];
  W2 := ForwardTable[byte(T1[2] shr 16)];
  W3 := ForwardTable[byte(T1[3] shr 24)];
  T0[0] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[8];
  W0 := ForwardTable[byte(T1[1])];
  W1 := ForwardTable[byte(T1[2] shr 8)];
  W2 := ForwardTable[byte(T1[3] shr 16)];
  W3 := ForwardTable[byte(T1[0] shr 24)];
  T0[1] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[9];
  W0 := ForwardTable[byte(T1[2])];
  W1 := ForwardTable[byte(T1[3] shr 8)];
  W2 := ForwardTable[byte(T1[0] shr 16)];
  W3 := ForwardTable[byte(T1[1] shr 24)];
  T0[2] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[10];
  W0 := ForwardTable[byte(T1[3])];
  W1 := ForwardTable[byte(T1[0] shr 8)];
  W2 := ForwardTable[byte(T1[1] shr 16)];
  W3 := ForwardTable[byte(T1[2] shr 24)];
  T0[3] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[11];
  // round 3
  W0 := ForwardTable[byte(T0[0])];
  W1 := ForwardTable[byte(T0[1] shr 8)];
  W2 := ForwardTable[byte(T0[2] shr 16)];
  W3 := ForwardTable[byte(T0[3] shr 24)];
  T1[0] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[12];
  W0 := ForwardTable[byte(T0[1])];
  W1 := ForwardTable[byte(T0[2] shr 8)];
  W2 := ForwardTable[byte(T0[3] shr 16)];
  W3 := ForwardTable[byte(T0[0] shr 24)];
  T1[1] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[13];
  W0 := ForwardTable[byte(T0[2])];
  W1 := ForwardTable[byte(T0[3] shr 8)];
  W2 := ForwardTable[byte(T0[0] shr 16)];
  W3 := ForwardTable[byte(T0[1] shr 24)];
  T1[2] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[14];
  W0 := ForwardTable[byte(T0[3])];
  W1 := ForwardTable[byte(T0[0] shr 8)];
  W2 := ForwardTable[byte(T0[1] shr 16)];
  W3 := ForwardTable[byte(T0[2] shr 24)];
  T1[3] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[15];
  // round 4
  W0 := ForwardTable[byte(T1[0])];
  W1 := ForwardTable[byte(T1[1] shr 8)];
  W2 := ForwardTable[byte(T1[2] shr 16)];
  W3 := ForwardTable[byte(T1[3] shr 24)];
  T0[0] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[16];
  W0 := ForwardTable[byte(T1[1])];
  W1 := ForwardTable[byte(T1[2] shr 8)];
  W2 := ForwardTable[byte(T1[3] shr 16)];
  W3 := ForwardTable[byte(T1[0] shr 24)];
  T0[1] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[17];
  W0 := ForwardTable[byte(T1[2])];
  W1 := ForwardTable[byte(T1[3] shr 8)];
  W2 := ForwardTable[byte(T1[0] shr 16)];
  W3 := ForwardTable[byte(T1[1] shr 24)];
  T0[2] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[18];
  W0 := ForwardTable[byte(T1[3])];
  W1 := ForwardTable[byte(T1[0] shr 8)];
  W2 := ForwardTable[byte(T1[1] shr 16)];
  W3 := ForwardTable[byte(T1[2] shr 24)];
  T0[3] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[19];
  // round 5
  W0 := ForwardTable[byte(T0[0])];
  W1 := ForwardTable[byte(T0[1] shr 8)];
  W2 := ForwardTable[byte(T0[2] shr 16)];
  W3 := ForwardTable[byte(T0[3] shr 24)];
  T1[0] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[20];
  W0 := ForwardTable[byte(T0[1])];
  W1 := ForwardTable[byte(T0[2] shr 8)];
  W2 := ForwardTable[byte(T0[3] shr 16)];
  W3 := ForwardTable[byte(T0[0] shr 24)];
  T1[1] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[21];
  W0 := ForwardTable[byte(T0[2])];
  W1 := ForwardTable[byte(T0[3] shr 8)];
  W2 := ForwardTable[byte(T0[0] shr 16)];
  W3 := ForwardTable[byte(T0[1] shr 24)];
  T1[2] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[22];
  W0 := ForwardTable[byte(T0[3])];
  W1 := ForwardTable[byte(T0[0] shr 8)];
  W2 := ForwardTable[byte(T0[1] shr 16)];
  W3 := ForwardTable[byte(T0[2] shr 24)];
  T1[3] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[23];
  // round 6
  W0 := ForwardTable[byte(T1[0])];
  W1 := ForwardTable[byte(T1[1] shr 8)];
  W2 := ForwardTable[byte(T1[2] shr 16)];
  W3 := ForwardTable[byte(T1[3] shr 24)];
  T0[0] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[24];
  W0 := ForwardTable[byte(T1[1])];
  W1 := ForwardTable[byte(T1[2] shr 8)];
  W2 := ForwardTable[byte(T1[3] shr 16)];
  W3 := ForwardTable[byte(T1[0] shr 24)];
  T0[1] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[25];
  W0 := ForwardTable[byte(T1[2])];
  W1 := ForwardTable[byte(T1[3] shr 8)];
  W2 := ForwardTable[byte(T1[0] shr 16)];
  W3 := ForwardTable[byte(T1[1] shr 24)];
  T0[2] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[26];
  W0 := ForwardTable[byte(T1[3])];
  W1 := ForwardTable[byte(T1[0] shr 8)];
  W2 := ForwardTable[byte(T1[1] shr 16)];
  W3 := ForwardTable[byte(T1[2] shr 24)];
  T0[3] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[27];
  // round 7
  W0 := ForwardTable[byte(T0[0])];
  W1 := ForwardTable[byte(T0[1] shr 8)];
  W2 := ForwardTable[byte(T0[2] shr 16)];
  W3 := ForwardTable[byte(T0[3] shr 24)];
  T1[0] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[28];
  W0 := ForwardTable[byte(T0[1])];
  W1 := ForwardTable[byte(T0[2] shr 8)];
  W2 := ForwardTable[byte(T0[3] shr 16)];
  W3 := ForwardTable[byte(T0[0] shr 24)];
  T1[1] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[29];
  W0 := ForwardTable[byte(T0[2])];
  W1 := ForwardTable[byte(T0[3] shr 8)];
  W2 := ForwardTable[byte(T0[0] shr 16)];
  W3 := ForwardTable[byte(T0[1] shr 24)];
  T1[2] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[30];
  W0 := ForwardTable[byte(T0[3])];
  W1 := ForwardTable[byte(T0[0] shr 8)];
  W2 := ForwardTable[byte(T0[1] shr 16)];
  W3 := ForwardTable[byte(T0[2] shr 24)];
  T1[3] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[31];
  // round 8
  W0 := ForwardTable[byte(T1[0])];
  W1 := ForwardTable[byte(T1[1] shr 8)];
  W2 := ForwardTable[byte(T1[2] shr 16)];
  W3 := ForwardTable[byte(T1[3] shr 24)];
  T0[0] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[32];
  W0 := ForwardTable[byte(T1[1])];
  W1 := ForwardTable[byte(T1[2] shr 8)];
  W2 := ForwardTable[byte(T1[3] shr 16)];
  W3 := ForwardTable[byte(T1[0] shr 24)];
  T0[1] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[33];
  W0 := ForwardTable[byte(T1[2])];
  W1 := ForwardTable[byte(T1[3] shr 8)];
  W2 := ForwardTable[byte(T1[0] shr 16)];
  W3 := ForwardTable[byte(T1[1] shr 24)];
  T0[2] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[34];
  W0 := ForwardTable[byte(T1[3])];
  W1 := ForwardTable[byte(T1[0] shr 8)];
  W2 := ForwardTable[byte(T1[1] shr 16)];
  W3 := ForwardTable[byte(T1[2] shr 24)];
  T0[3] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[35];
  // round 9
  W0 := ForwardTable[byte(T0[0])];
  W1 := ForwardTable[byte(T0[1] shr 8)];
  W2 := ForwardTable[byte(T0[2] shr 16)];
  W3 := ForwardTable[byte(T0[3] shr 24)];
  T1[0] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[36];
  W0 := ForwardTable[byte(T0[1])];
  W1 := ForwardTable[byte(T0[2] shr 8)];
  W2 := ForwardTable[byte(T0[3] shr 16)];
  W3 := ForwardTable[byte(T0[0] shr 24)];
  T1[1] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[37];
  W0 := ForwardTable[byte(T0[2])];
  W1 := ForwardTable[byte(T0[3] shr 8)];
  W2 := ForwardTable[byte(T0[0] shr 16)];
  W3 := ForwardTable[byte(T0[1] shr 24)];
  T1[2] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[38];
  W0 := ForwardTable[byte(T0[3])];
  W1 := ForwardTable[byte(T0[0] shr 8)];
  W2 := ForwardTable[byte(T0[1] shr 16)];
  W3 := ForwardTable[byte(T0[2] shr 24)];
  T1[3] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[39];
  // round 10
  W0 := ForwardTable[byte(T1[0])];
  W1 := ForwardTable[byte(T1[1] shr 8)];
  W2 := ForwardTable[byte(T1[2] shr 16)];
  W3 := ForwardTable[byte(T1[3] shr 24)];
  T0[0] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[40];
  W0 := ForwardTable[byte(T1[1])];
  W1 := ForwardTable[byte(T1[2] shr 8)];
  W2 := ForwardTable[byte(T1[3] shr 16)];
  W3 := ForwardTable[byte(T1[0] shr 24)];
  T0[1] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[41];
  W0 := ForwardTable[byte(T1[2])];
  W1 := ForwardTable[byte(T1[3] shr 8)];
  W2 := ForwardTable[byte(T1[0] shr 16)];
  W3 := ForwardTable[byte(T1[1] shr 24)];
  T0[2] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[42];
  W0 := ForwardTable[byte(T1[3])];
  W1 := ForwardTable[byte(T1[0] shr 8)];
  W2 := ForwardTable[byte(T1[1] shr 16)];
  W3 := ForwardTable[byte(T1[2] shr 24)];
  T0[3] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[43];
  // round 11
  W0 := ForwardTable[byte(T0[0])];
  W1 := ForwardTable[byte(T0[1] shr 8)];
  W2 := ForwardTable[byte(T0[2] shr 16)];
  W3 := ForwardTable[byte(T0[3] shr 24)];
  T1[0] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[44];
  W0 := ForwardTable[byte(T0[1])];
  W1 := ForwardTable[byte(T0[2] shr 8)];
  W2 := ForwardTable[byte(T0[3] shr 16)];
  W3 := ForwardTable[byte(T0[0] shr 24)];
  T1[1] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[45];
  W0 := ForwardTable[byte(T0[2])];
  W1 := ForwardTable[byte(T0[3] shr 8)];
  W2 := ForwardTable[byte(T0[0] shr 16)];
  W3 := ForwardTable[byte(T0[1] shr 24)];
  T1[2] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[46];
  W0 := ForwardTable[byte(T0[3])];
  W1 := ForwardTable[byte(T0[0] shr 8)];
  W2 := ForwardTable[byte(T0[1] shr 16)];
  W3 := ForwardTable[byte(T0[2] shr 24)];
  T1[3] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[47];
  // round 12
  W0 := ForwardTable[byte(T1[0])];
  W1 := ForwardTable[byte(T1[1] shr 8)];
  W2 := ForwardTable[byte(T1[2] shr 16)];
  W3 := ForwardTable[byte(T1[3] shr 24)];
  T0[0] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[48];
  W0 := ForwardTable[byte(T1[1])];
  W1 := ForwardTable[byte(T1[2] shr 8)];
  W2 := ForwardTable[byte(T1[3] shr 16)];
  W3 := ForwardTable[byte(T1[0] shr 24)];
  T0[1] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[49];
  W0 := ForwardTable[byte(T1[2])];
  W1 := ForwardTable[byte(T1[3] shr 8)];
  W2 := ForwardTable[byte(T1[0] shr 16)];
  W3 := ForwardTable[byte(T1[1] shr 24)];
  T0[2] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[50];
  W0 := ForwardTable[byte(T1[3])];
  W1 := ForwardTable[byte(T1[0] shr 8)];
  W2 := ForwardTable[byte(T1[1] shr 16)];
  W3 := ForwardTable[byte(T1[2] shr 24)];
  T0[3] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[51];
  // round 13
  W0 := ForwardTable[byte(T0[0])];
  W1 := ForwardTable[byte(T0[1] shr 8)];
  W2 := ForwardTable[byte(T0[2] shr 16)];
  W3 := ForwardTable[byte(T0[3] shr 24)];
  T1[0] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[52];
  W0 := ForwardTable[byte(T0[1])];
  W1 := ForwardTable[byte(T0[2] shr 8)];
  W2 := ForwardTable[byte(T0[3] shr 16)];
  W3 := ForwardTable[byte(T0[0] shr 24)];
  T1[1] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[53];
  W0 := ForwardTable[byte(T0[2])];
  W1 := ForwardTable[byte(T0[3] shr 8)];
  W2 := ForwardTable[byte(T0[0] shr 16)];
  W3 := ForwardTable[byte(T0[1] shr 24)];
  T1[2] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[54];
  W0 := ForwardTable[byte(T0[3])];
  W1 := ForwardTable[byte(T0[0] shr 8)];
  W2 := ForwardTable[byte(T0[1] shr 16)];
  W3 := ForwardTable[byte(T0[2] shr 24)];
  T1[3] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[55];
  // last round of transformations
  W0 := LastForwardTable[byte(T1[0])];
  W1 := LastForwardTable[byte(T1[1] shr 8)];
  W2 := LastForwardTable[byte(T1[2] shr 16)];
  W3 := LastForwardTable[byte(T1[3] shr 24)];
  T0[0] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[56];
  W0 := LastForwardTable[byte(T1[1])];
  W1 := LastForwardTable[byte(T1[2] shr 8)];
  W2 := LastForwardTable[byte(T1[3] shr 16)];
  W3 := LastForwardTable[byte(T1[0] shr 24)];
  T0[1] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[57];
  W0 := LastForwardTable[byte(T1[2])];
  W1 := LastForwardTable[byte(T1[3] shr 8)];
  W2 := LastForwardTable[byte(T1[0] shr 16)];
  W3 := LastForwardTable[byte(T1[1] shr 24)];
  T0[2] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[58];
  W0 := LastForwardTable[byte(T1[3])];
  W1 := LastForwardTable[byte(T1[0] shr 8)];
  W2 := LastForwardTable[byte(T1[1] shr 16)];
  W3 := LastForwardTable[byte(T1[2] shr 24)];
  T0[3] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[59];
  // finalizing
  PCardinal(@OutBuf[0])^ := T0[0];
  PCardinal(@OutBuf[4])^ := T0[1];
  PCardinal(@OutBuf[8])^ := T0[2];
  PCardinal(@OutBuf[12])^ := T0[3];
end;

procedure ExpandAESKeyForDecryption(var ExpandedKey
  : TQAESExpandedKey128); overload;
var
  I: Integer;
  U, F2, F4, F8, F9: Cardinal;
begin
  for I := 1 to 9 do
  begin
    F9 := ExpandedKey[I * 4];
    U := F9 and $80808080;
    F2 := ((F9 and $7F7F7F7F) shl 1) xor ((U - (U shr 7)) and $1B1B1B1B);
    U := F2 and $80808080;
    F4 := ((F2 and $7F7F7F7F) shl 1) xor ((U - (U shr 7)) and $1B1B1B1B);
    U := F4 and $80808080;
    F8 := ((F4 and $7F7F7F7F) shl 1) xor ((U - (U shr 7)) and $1B1B1B1B);
    F9 := F9 xor F8;
    ExpandedKey[I * 4] := F2 xor F4 xor F8 xor (((F2 xor F9) shl 24) or
      ((F2 xor F9) shr 8)) xor (((F4 xor F9) shl 16) or ((F4 xor F9) shr 16))
      xor ((F9 shl 8) or (F9 shr 24));
    F9 := ExpandedKey[I * 4 + 1];
    U := F9 and $80808080;
    F2 := ((F9 and $7F7F7F7F) shl 1) xor ((U - (U shr 7)) and $1B1B1B1B);
    U := F2 and $80808080;
    F4 := ((F2 and $7F7F7F7F) shl 1) xor ((U - (U shr 7)) and $1B1B1B1B);
    U := F4 and $80808080;
    F8 := ((F4 and $7F7F7F7F) shl 1) xor ((U - (U shr 7)) and $1B1B1B1B);
    F9 := F9 xor F8;
    ExpandedKey[I * 4 + 1] := F2 xor F4 xor F8 xor (((F2 xor F9) shl 24) or
      ((F2 xor F9) shr 8)) xor (((F4 xor F9) shl 16) or ((F4 xor F9) shr 16))
      xor ((F9 shl 8) or (F9 shr 24));
    F9 := ExpandedKey[I * 4 + 2];
    U := F9 and $80808080;
    F2 := ((F9 and $7F7F7F7F) shl 1) xor ((U - (U shr 7)) and $1B1B1B1B);
    U := F2 and $80808080;
    F4 := ((F2 and $7F7F7F7F) shl 1) xor ((U - (U shr 7)) and $1B1B1B1B);
    U := F4 and $80808080;
    F8 := ((F4 and $7F7F7F7F) shl 1) xor ((U - (U shr 7)) and $1B1B1B1B);
    F9 := F9 xor F8;
    ExpandedKey[I * 4 + 2] := F2 xor F4 xor F8 xor (((F2 xor F9) shl 24) or
      ((F2 xor F9) shr 8)) xor (((F4 xor F9) shl 16) or ((F4 xor F9) shr 16))
      xor ((F9 shl 8) or (F9 shr 24));
    F9 := ExpandedKey[I * 4 + 3];
    U := F9 and $80808080;
    F2 := ((F9 and $7F7F7F7F) shl 1) xor ((U - (U shr 7)) and $1B1B1B1B);
    U := F2 and $80808080;
    F4 := ((F2 and $7F7F7F7F) shl 1) xor ((U - (U shr 7)) and $1B1B1B1B);
    U := F4 and $80808080;
    F8 := ((F4 and $7F7F7F7F) shl 1) xor ((U - (U shr 7)) and $1B1B1B1B);
    F9 := F9 xor F8;
    ExpandedKey[I * 4 + 3] := F2 xor F4 xor F8 xor (((F2 xor F9) shl 24) or
      ((F2 xor F9) shr 8)) xor (((F4 xor F9) shl 16) or ((F4 xor F9) shr 16))
      xor ((F9 shl 8) or (F9 shr 24));
  end;
end;

procedure ExpandAESKeyForDecryption(const Key: TQAESKey128;
  var ExpandedKey: TQAESExpandedKey128); overload;
begin
  ExpandAESKeyForEncryption(Key, ExpandedKey);
  ExpandAESKeyForDecryption(ExpandedKey);
end;

procedure ExpandAESKeyForDecryption(var ExpandedKey
  : TQAESExpandedKey192); overload;
var
  I: Integer;
  U, F2, F4, F8, F9: Cardinal;
begin
  for I := 1 to 11 do
  begin
    F9 := ExpandedKey[I * 4];
    U := F9 and $80808080;
    F2 := ((F9 and $7F7F7F7F) shl 1) xor ((U - (U shr 7)) and $1B1B1B1B);
    U := F2 and $80808080;
    F4 := ((F2 and $7F7F7F7F) shl 1) xor ((U - (U shr 7)) and $1B1B1B1B);
    U := F4 and $80808080;
    F8 := ((F4 and $7F7F7F7F) shl 1) xor ((U - (U shr 7)) and $1B1B1B1B);
    F9 := F9 xor F8;
    ExpandedKey[I * 4] := F2 xor F4 xor F8 xor (((F2 xor F9) shl 24) or
      ((F2 xor F9) shr 8)) xor (((F4 xor F9) shl 16) or ((F4 xor F9) shr 16))
      xor ((F9 shl 8) or (F9 shr 24));
    F9 := ExpandedKey[I * 4 + 1];
    U := F9 and $80808080;
    F2 := ((F9 and $7F7F7F7F) shl 1) xor ((U - (U shr 7)) and $1B1B1B1B);
    U := F2 and $80808080;
    F4 := ((F2 and $7F7F7F7F) shl 1) xor ((U - (U shr 7)) and $1B1B1B1B);
    U := F4 and $80808080;
    F8 := ((F4 and $7F7F7F7F) shl 1) xor ((U - (U shr 7)) and $1B1B1B1B);
    F9 := F9 xor F8;
    ExpandedKey[I * 4 + 1] := F2 xor F4 xor F8 xor (((F2 xor F9) shl 24) or
      ((F2 xor F9) shr 8)) xor (((F4 xor F9) shl 16) or ((F4 xor F9) shr 16))
      xor ((F9 shl 8) or (F9 shr 24));
    F9 := ExpandedKey[I * 4 + 2];
    U := F9 and $80808080;
    F2 := ((F9 and $7F7F7F7F) shl 1) xor ((U - (U shr 7)) and $1B1B1B1B);
    U := F2 and $80808080;
    F4 := ((F2 and $7F7F7F7F) shl 1) xor ((U - (U shr 7)) and $1B1B1B1B);
    U := F4 and $80808080;
    F8 := ((F4 and $7F7F7F7F) shl 1) xor ((U - (U shr 7)) and $1B1B1B1B);
    F9 := F9 xor F8;
    ExpandedKey[I * 4 + 2] := F2 xor F4 xor F8 xor (((F2 xor F9) shl 24) or
      ((F2 xor F9) shr 8)) xor (((F4 xor F9) shl 16) or ((F4 xor F9) shr 16))
      xor ((F9 shl 8) or (F9 shr 24));
    F9 := ExpandedKey[I * 4 + 3];
    U := F9 and $80808080;
    F2 := ((F9 and $7F7F7F7F) shl 1) xor ((U - (U shr 7)) and $1B1B1B1B);
    U := F2 and $80808080;
    F4 := ((F2 and $7F7F7F7F) shl 1) xor ((U - (U shr 7)) and $1B1B1B1B);
    U := F4 and $80808080;
    F8 := ((F4 and $7F7F7F7F) shl 1) xor ((U - (U shr 7)) and $1B1B1B1B);
    F9 := F9 xor F8;
    ExpandedKey[I * 4 + 3] := F2 xor F4 xor F8 xor (((F2 xor F9) shl 24) or
      ((F2 xor F9) shr 8)) xor (((F4 xor F9) shl 16) or ((F4 xor F9) shr 16))
      xor ((F9 shl 8) or (F9 shr 24));
  end;
end;

procedure ExpandAESKeyForDecryption(const Key: TQAESKey192;
  var ExpandedKey: TQAESExpandedKey192); overload;
begin
  ExpandAESKeyForEncryption(Key, ExpandedKey);
  ExpandAESKeyForDecryption(ExpandedKey);
end;

procedure ExpandAESKeyForDecryption(var ExpandedKey
  : TQAESExpandedKey256); overload;
var
  I: Integer;
  U, F2, F4, F8, F9: Cardinal;
begin
  for I := 1 to 13 do
  begin
    F9 := ExpandedKey[I * 4];
    U := F9 and $80808080;
    F2 := ((F9 and $7F7F7F7F) shl 1) xor ((U - (U shr 7)) and $1B1B1B1B);
    U := F2 and $80808080;
    F4 := ((F2 and $7F7F7F7F) shl 1) xor ((U - (U shr 7)) and $1B1B1B1B);
    U := F4 and $80808080;
    F8 := ((F4 and $7F7F7F7F) shl 1) xor ((U - (U shr 7)) and $1B1B1B1B);
    F9 := F9 xor F8;
    ExpandedKey[I * 4] := F2 xor F4 xor F8 xor (((F2 xor F9) shl 24) or
      ((F2 xor F9) shr 8)) xor (((F4 xor F9) shl 16) or ((F4 xor F9) shr 16))
      xor ((F9 shl 8) or (F9 shr 24));
    F9 := ExpandedKey[I * 4 + 1];
    U := F9 and $80808080;
    F2 := ((F9 and $7F7F7F7F) shl 1) xor ((U - (U shr 7)) and $1B1B1B1B);
    U := F2 and $80808080;
    F4 := ((F2 and $7F7F7F7F) shl 1) xor ((U - (U shr 7)) and $1B1B1B1B);
    U := F4 and $80808080;
    F8 := ((F4 and $7F7F7F7F) shl 1) xor ((U - (U shr 7)) and $1B1B1B1B);
    F9 := F9 xor F8;
    ExpandedKey[I * 4 + 1] := F2 xor F4 xor F8 xor (((F2 xor F9) shl 24) or
      ((F2 xor F9) shr 8)) xor (((F4 xor F9) shl 16) or ((F4 xor F9) shr 16))
      xor ((F9 shl 8) or (F9 shr 24));
    F9 := ExpandedKey[I * 4 + 2];
    U := F9 and $80808080;
    F2 := ((F9 and $7F7F7F7F) shl 1) xor ((U - (U shr 7)) and $1B1B1B1B);
    U := F2 and $80808080;
    F4 := ((F2 and $7F7F7F7F) shl 1) xor ((U - (U shr 7)) and $1B1B1B1B);
    U := F4 and $80808080;
    F8 := ((F4 and $7F7F7F7F) shl 1) xor ((U - (U shr 7)) and $1B1B1B1B);
    F9 := F9 xor F8;
    ExpandedKey[I * 4 + 2] := F2 xor F4 xor F8 xor (((F2 xor F9) shl 24) or
      ((F2 xor F9) shr 8)) xor (((F4 xor F9) shl 16) or ((F4 xor F9) shr 16))
      xor ((F9 shl 8) or (F9 shr 24));
    F9 := ExpandedKey[I * 4 + 3];
    U := F9 and $80808080;
    F2 := ((F9 and $7F7F7F7F) shl 1) xor ((U - (U shr 7)) and $1B1B1B1B);
    U := F2 and $80808080;
    F4 := ((F2 and $7F7F7F7F) shl 1) xor ((U - (U shr 7)) and $1B1B1B1B);
    U := F4 and $80808080;
    F8 := ((F4 and $7F7F7F7F) shl 1) xor ((U - (U shr 7)) and $1B1B1B1B);
    F9 := F9 xor F8;
    ExpandedKey[I * 4 + 3] := F2 xor F4 xor F8 xor (((F2 xor F9) shl 24) or
      ((F2 xor F9) shr 8)) xor (((F4 xor F9) shl 16) or ((F4 xor F9) shr 16))
      xor ((F9 shl 8) or (F9 shr 24));
  end;
end;

procedure ExpandAESKeyForDecryption(const Key: TQAESKey256;
  var ExpandedKey: TQAESExpandedKey256); overload;
begin
  ExpandAESKeyForEncryption(Key, ExpandedKey);
  ExpandAESKeyForDecryption(ExpandedKey);
end;

procedure DecrypAES(const InBuf: TQAESBuffer; const Key: TQAESExpandedKey128;
  var OutBuf: TQAESBuffer); overload;
var
  T0, T1: array [0 .. 3] of Cardinal;
  W0, W1, W2, W3: Cardinal;
begin
  // initializing
  T0[0] := PCardinal(@InBuf[0])^ xor Key[40];
  T0[1] := PCardinal(@InBuf[4])^ xor Key[41];
  T0[2] := PCardinal(@InBuf[8])^ xor Key[42];
  T0[3] := PCardinal(@InBuf[12])^ xor Key[43];
  // performing transformations 9 times
  // round 1
  W0 := InverseTable[byte(T0[0])];
  W1 := InverseTable[byte(T0[3] shr 8)];
  W2 := InverseTable[byte(T0[2] shr 16)];
  W3 := InverseTable[byte(T0[1] shr 24)];
  T1[0] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[36];
  W0 := InverseTable[byte(T0[1])];
  W1 := InverseTable[byte(T0[0] shr 8)];
  W2 := InverseTable[byte(T0[3] shr 16)];
  W3 := InverseTable[byte(T0[2] shr 24)];
  T1[1] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[37];
  W0 := InverseTable[byte(T0[2])];
  W1 := InverseTable[byte(T0[1] shr 8)];
  W2 := InverseTable[byte(T0[0] shr 16)];
  W3 := InverseTable[byte(T0[3] shr 24)];
  T1[2] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[38];
  W0 := InverseTable[byte(T0[3])];
  W1 := InverseTable[byte(T0[2] shr 8)];
  W2 := InverseTable[byte(T0[1] shr 16)];
  W3 := InverseTable[byte(T0[0] shr 24)];
  T1[3] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[39];
  // round 2
  W0 := InverseTable[byte(T1[0])];
  W1 := InverseTable[byte(T1[3] shr 8)];
  W2 := InverseTable[byte(T1[2] shr 16)];
  W3 := InverseTable[byte(T1[1] shr 24)];
  T0[0] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[32];
  W0 := InverseTable[byte(T1[1])];
  W1 := InverseTable[byte(T1[0] shr 8)];
  W2 := InverseTable[byte(T1[3] shr 16)];
  W3 := InverseTable[byte(T1[2] shr 24)];
  T0[1] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[33];
  W0 := InverseTable[byte(T1[2])];
  W1 := InverseTable[byte(T1[1] shr 8)];
  W2 := InverseTable[byte(T1[0] shr 16)];
  W3 := InverseTable[byte(T1[3] shr 24)];
  T0[2] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[34];
  W0 := InverseTable[byte(T1[3])];
  W1 := InverseTable[byte(T1[2] shr 8)];
  W2 := InverseTable[byte(T1[1] shr 16)];
  W3 := InverseTable[byte(T1[0] shr 24)];
  T0[3] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[35];
  // round 3
  W0 := InverseTable[byte(T0[0])];
  W1 := InverseTable[byte(T0[3] shr 8)];
  W2 := InverseTable[byte(T0[2] shr 16)];
  W3 := InverseTable[byte(T0[1] shr 24)];
  T1[0] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[28];
  W0 := InverseTable[byte(T0[1])];
  W1 := InverseTable[byte(T0[0] shr 8)];
  W2 := InverseTable[byte(T0[3] shr 16)];
  W3 := InverseTable[byte(T0[2] shr 24)];
  T1[1] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[29];
  W0 := InverseTable[byte(T0[2])];
  W1 := InverseTable[byte(T0[1] shr 8)];
  W2 := InverseTable[byte(T0[0] shr 16)];
  W3 := InverseTable[byte(T0[3] shr 24)];
  T1[2] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[30];
  W0 := InverseTable[byte(T0[3])];
  W1 := InverseTable[byte(T0[2] shr 8)];
  W2 := InverseTable[byte(T0[1] shr 16)];
  W3 := InverseTable[byte(T0[0] shr 24)];
  T1[3] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[31];
  // round 4
  W0 := InverseTable[byte(T1[0])];
  W1 := InverseTable[byte(T1[3] shr 8)];
  W2 := InverseTable[byte(T1[2] shr 16)];
  W3 := InverseTable[byte(T1[1] shr 24)];
  T0[0] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[24];
  W0 := InverseTable[byte(T1[1])];
  W1 := InverseTable[byte(T1[0] shr 8)];
  W2 := InverseTable[byte(T1[3] shr 16)];
  W3 := InverseTable[byte(T1[2] shr 24)];
  T0[1] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[25];
  W0 := InverseTable[byte(T1[2])];
  W1 := InverseTable[byte(T1[1] shr 8)];
  W2 := InverseTable[byte(T1[0] shr 16)];
  W3 := InverseTable[byte(T1[3] shr 24)];
  T0[2] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[26];
  W0 := InverseTable[byte(T1[3])];
  W1 := InverseTable[byte(T1[2] shr 8)];
  W2 := InverseTable[byte(T1[1] shr 16)];
  W3 := InverseTable[byte(T1[0] shr 24)];
  T0[3] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[27];
  // round 5
  W0 := InverseTable[byte(T0[0])];
  W1 := InverseTable[byte(T0[3] shr 8)];
  W2 := InverseTable[byte(T0[2] shr 16)];
  W3 := InverseTable[byte(T0[1] shr 24)];
  T1[0] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[20];
  W0 := InverseTable[byte(T0[1])];
  W1 := InverseTable[byte(T0[0] shr 8)];
  W2 := InverseTable[byte(T0[3] shr 16)];
  W3 := InverseTable[byte(T0[2] shr 24)];
  T1[1] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[21];
  W0 := InverseTable[byte(T0[2])];
  W1 := InverseTable[byte(T0[1] shr 8)];
  W2 := InverseTable[byte(T0[0] shr 16)];
  W3 := InverseTable[byte(T0[3] shr 24)];
  T1[2] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[22];
  W0 := InverseTable[byte(T0[3])];
  W1 := InverseTable[byte(T0[2] shr 8)];
  W2 := InverseTable[byte(T0[1] shr 16)];
  W3 := InverseTable[byte(T0[0] shr 24)];
  T1[3] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[23];
  // round 6
  W0 := InverseTable[byte(T1[0])];
  W1 := InverseTable[byte(T1[3] shr 8)];
  W2 := InverseTable[byte(T1[2] shr 16)];
  W3 := InverseTable[byte(T1[1] shr 24)];
  T0[0] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[16];
  W0 := InverseTable[byte(T1[1])];
  W1 := InverseTable[byte(T1[0] shr 8)];
  W2 := InverseTable[byte(T1[3] shr 16)];
  W3 := InverseTable[byte(T1[2] shr 24)];
  T0[1] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[17];
  W0 := InverseTable[byte(T1[2])];
  W1 := InverseTable[byte(T1[1] shr 8)];
  W2 := InverseTable[byte(T1[0] shr 16)];
  W3 := InverseTable[byte(T1[3] shr 24)];
  T0[2] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[18];
  W0 := InverseTable[byte(T1[3])];
  W1 := InverseTable[byte(T1[2] shr 8)];
  W2 := InverseTable[byte(T1[1] shr 16)];
  W3 := InverseTable[byte(T1[0] shr 24)];
  T0[3] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[19];
  // round 7
  W0 := InverseTable[byte(T0[0])];
  W1 := InverseTable[byte(T0[3] shr 8)];
  W2 := InverseTable[byte(T0[2] shr 16)];
  W3 := InverseTable[byte(T0[1] shr 24)];
  T1[0] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[12];
  W0 := InverseTable[byte(T0[1])];
  W1 := InverseTable[byte(T0[0] shr 8)];
  W2 := InverseTable[byte(T0[3] shr 16)];
  W3 := InverseTable[byte(T0[2] shr 24)];
  T1[1] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[13];
  W0 := InverseTable[byte(T0[2])];
  W1 := InverseTable[byte(T0[1] shr 8)];
  W2 := InverseTable[byte(T0[0] shr 16)];
  W3 := InverseTable[byte(T0[3] shr 24)];
  T1[2] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[14];
  W0 := InverseTable[byte(T0[3])];
  W1 := InverseTable[byte(T0[2] shr 8)];
  W2 := InverseTable[byte(T0[1] shr 16)];
  W3 := InverseTable[byte(T0[0] shr 24)];
  T1[3] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[15];
  // round 8
  W0 := InverseTable[byte(T1[0])];
  W1 := InverseTable[byte(T1[3] shr 8)];
  W2 := InverseTable[byte(T1[2] shr 16)];
  W3 := InverseTable[byte(T1[1] shr 24)];
  T0[0] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[8];
  W0 := InverseTable[byte(T1[1])];
  W1 := InverseTable[byte(T1[0] shr 8)];
  W2 := InverseTable[byte(T1[3] shr 16)];
  W3 := InverseTable[byte(T1[2] shr 24)];
  T0[1] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[9];
  W0 := InverseTable[byte(T1[2])];
  W1 := InverseTable[byte(T1[1] shr 8)];
  W2 := InverseTable[byte(T1[0] shr 16)];
  W3 := InverseTable[byte(T1[3] shr 24)];
  T0[2] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[10];
  W0 := InverseTable[byte(T1[3])];
  W1 := InverseTable[byte(T1[2] shr 8)];
  W2 := InverseTable[byte(T1[1] shr 16)];
  W3 := InverseTable[byte(T1[0] shr 24)];
  T0[3] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[11];
  // round 9
  W0 := InverseTable[byte(T0[0])];
  W1 := InverseTable[byte(T0[3] shr 8)];
  W2 := InverseTable[byte(T0[2] shr 16)];
  W3 := InverseTable[byte(T0[1] shr 24)];
  T1[0] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[4];
  W0 := InverseTable[byte(T0[1])];
  W1 := InverseTable[byte(T0[0] shr 8)];
  W2 := InverseTable[byte(T0[3] shr 16)];
  W3 := InverseTable[byte(T0[2] shr 24)];
  T1[1] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[5];
  W0 := InverseTable[byte(T0[2])];
  W1 := InverseTable[byte(T0[1] shr 8)];
  W2 := InverseTable[byte(T0[0] shr 16)];
  W3 := InverseTable[byte(T0[3] shr 24)];
  T1[2] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[6];
  W0 := InverseTable[byte(T0[3])];
  W1 := InverseTable[byte(T0[2] shr 8)];
  W2 := InverseTable[byte(T0[1] shr 16)];
  W3 := InverseTable[byte(T0[0] shr 24)];
  T1[3] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[7];
  // last round of transformations
  W0 := LastInverseTable[byte(T1[0])];
  W1 := LastInverseTable[byte(T1[3] shr 8)];
  W2 := LastInverseTable[byte(T1[2] shr 16)];
  W3 := LastInverseTable[byte(T1[1] shr 24)];
  T0[0] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[0];
  W0 := LastInverseTable[byte(T1[1])];
  W1 := LastInverseTable[byte(T1[0] shr 8)];
  W2 := LastInverseTable[byte(T1[3] shr 16)];
  W3 := LastInverseTable[byte(T1[2] shr 24)];
  T0[1] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[1];
  W0 := LastInverseTable[byte(T1[2])];
  W1 := LastInverseTable[byte(T1[1] shr 8)];
  W2 := LastInverseTable[byte(T1[0] shr 16)];
  W3 := LastInverseTable[byte(T1[3] shr 24)];
  T0[2] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[2];
  W0 := LastInverseTable[byte(T1[3])];
  W1 := LastInverseTable[byte(T1[2] shr 8)];
  W2 := LastInverseTable[byte(T1[1] shr 16)];
  W3 := LastInverseTable[byte(T1[0] shr 24)];
  T0[3] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[3];
  // finalizing
  PCardinal(@OutBuf[0])^ := T0[0];
  PCardinal(@OutBuf[4])^ := T0[1];
  PCardinal(@OutBuf[8])^ := T0[2];
  PCardinal(@OutBuf[12])^ := T0[3];
end;

procedure DecrypAES(const InBuf: TQAESBuffer; const Key: TQAESExpandedKey192;
  var OutBuf: TQAESBuffer); overload;
var
  T0, T1: array [0 .. 3] of Cardinal;
  W0, W1, W2, W3: Cardinal;
begin
  // initializing
  T0[0] := PCardinal(@InBuf[0])^ xor Key[48];
  T0[1] := PCardinal(@InBuf[4])^ xor Key[49];
  T0[2] := PCardinal(@InBuf[8])^ xor Key[50];
  T0[3] := PCardinal(@InBuf[12])^ xor Key[51];
  // performing transformations 11 times
  // round 1
  W0 := InverseTable[byte(T0[0])];
  W1 := InverseTable[byte(T0[3] shr 8)];
  W2 := InverseTable[byte(T0[2] shr 16)];
  W3 := InverseTable[byte(T0[1] shr 24)];
  T1[0] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[44];
  W0 := InverseTable[byte(T0[1])];
  W1 := InverseTable[byte(T0[0] shr 8)];
  W2 := InverseTable[byte(T0[3] shr 16)];
  W3 := InverseTable[byte(T0[2] shr 24)];
  T1[1] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[45];
  W0 := InverseTable[byte(T0[2])];
  W1 := InverseTable[byte(T0[1] shr 8)];
  W2 := InverseTable[byte(T0[0] shr 16)];
  W3 := InverseTable[byte(T0[3] shr 24)];
  T1[2] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[46];
  W0 := InverseTable[byte(T0[3])];
  W1 := InverseTable[byte(T0[2] shr 8)];
  W2 := InverseTable[byte(T0[1] shr 16)];
  W3 := InverseTable[byte(T0[0] shr 24)];
  T1[3] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[47];
  // round 2
  W0 := InverseTable[byte(T1[0])];
  W1 := InverseTable[byte(T1[3] shr 8)];
  W2 := InverseTable[byte(T1[2] shr 16)];
  W3 := InverseTable[byte(T1[1] shr 24)];
  T0[0] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[40];
  W0 := InverseTable[byte(T1[1])];
  W1 := InverseTable[byte(T1[0] shr 8)];
  W2 := InverseTable[byte(T1[3] shr 16)];
  W3 := InverseTable[byte(T1[2] shr 24)];
  T0[1] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[41];
  W0 := InverseTable[byte(T1[2])];
  W1 := InverseTable[byte(T1[1] shr 8)];
  W2 := InverseTable[byte(T1[0] shr 16)];
  W3 := InverseTable[byte(T1[3] shr 24)];
  T0[2] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[42];
  W0 := InverseTable[byte(T1[3])];
  W1 := InverseTable[byte(T1[2] shr 8)];
  W2 := InverseTable[byte(T1[1] shr 16)];
  W3 := InverseTable[byte(T1[0] shr 24)];
  T0[3] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[43];
  // round 3
  W0 := InverseTable[byte(T0[0])];
  W1 := InverseTable[byte(T0[3] shr 8)];
  W2 := InverseTable[byte(T0[2] shr 16)];
  W3 := InverseTable[byte(T0[1] shr 24)];
  T1[0] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[36];
  W0 := InverseTable[byte(T0[1])];
  W1 := InverseTable[byte(T0[0] shr 8)];
  W2 := InverseTable[byte(T0[3] shr 16)];
  W3 := InverseTable[byte(T0[2] shr 24)];
  T1[1] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[37];
  W0 := InverseTable[byte(T0[2])];
  W1 := InverseTable[byte(T0[1] shr 8)];
  W2 := InverseTable[byte(T0[0] shr 16)];
  W3 := InverseTable[byte(T0[3] shr 24)];
  T1[2] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[38];
  W0 := InverseTable[byte(T0[3])];
  W1 := InverseTable[byte(T0[2] shr 8)];
  W2 := InverseTable[byte(T0[1] shr 16)];
  W3 := InverseTable[byte(T0[0] shr 24)];
  T1[3] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[39];
  // round 4
  W0 := InverseTable[byte(T1[0])];
  W1 := InverseTable[byte(T1[3] shr 8)];
  W2 := InverseTable[byte(T1[2] shr 16)];
  W3 := InverseTable[byte(T1[1] shr 24)];
  T0[0] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[32];
  W0 := InverseTable[byte(T1[1])];
  W1 := InverseTable[byte(T1[0] shr 8)];
  W2 := InverseTable[byte(T1[3] shr 16)];
  W3 := InverseTable[byte(T1[2] shr 24)];
  T0[1] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[33];
  W0 := InverseTable[byte(T1[2])];
  W1 := InverseTable[byte(T1[1] shr 8)];
  W2 := InverseTable[byte(T1[0] shr 16)];
  W3 := InverseTable[byte(T1[3] shr 24)];
  T0[2] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[34];
  W0 := InverseTable[byte(T1[3])];
  W1 := InverseTable[byte(T1[2] shr 8)];
  W2 := InverseTable[byte(T1[1] shr 16)];
  W3 := InverseTable[byte(T1[0] shr 24)];
  T0[3] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[35];
  // round 5
  W0 := InverseTable[byte(T0[0])];
  W1 := InverseTable[byte(T0[3] shr 8)];
  W2 := InverseTable[byte(T0[2] shr 16)];
  W3 := InverseTable[byte(T0[1] shr 24)];
  T1[0] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[28];
  W0 := InverseTable[byte(T0[1])];
  W1 := InverseTable[byte(T0[0] shr 8)];
  W2 := InverseTable[byte(T0[3] shr 16)];
  W3 := InverseTable[byte(T0[2] shr 24)];
  T1[1] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[29];
  W0 := InverseTable[byte(T0[2])];
  W1 := InverseTable[byte(T0[1] shr 8)];
  W2 := InverseTable[byte(T0[0] shr 16)];
  W3 := InverseTable[byte(T0[3] shr 24)];
  T1[2] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[30];
  W0 := InverseTable[byte(T0[3])];
  W1 := InverseTable[byte(T0[2] shr 8)];
  W2 := InverseTable[byte(T0[1] shr 16)];
  W3 := InverseTable[byte(T0[0] shr 24)];
  T1[3] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[31];
  // round 6
  W0 := InverseTable[byte(T1[0])];
  W1 := InverseTable[byte(T1[3] shr 8)];
  W2 := InverseTable[byte(T1[2] shr 16)];
  W3 := InverseTable[byte(T1[1] shr 24)];
  T0[0] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[24];
  W0 := InverseTable[byte(T1[1])];
  W1 := InverseTable[byte(T1[0] shr 8)];
  W2 := InverseTable[byte(T1[3] shr 16)];
  W3 := InverseTable[byte(T1[2] shr 24)];
  T0[1] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[25];
  W0 := InverseTable[byte(T1[2])];
  W1 := InverseTable[byte(T1[1] shr 8)];
  W2 := InverseTable[byte(T1[0] shr 16)];
  W3 := InverseTable[byte(T1[3] shr 24)];
  T0[2] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[26];
  W0 := InverseTable[byte(T1[3])];
  W1 := InverseTable[byte(T1[2] shr 8)];
  W2 := InverseTable[byte(T1[1] shr 16)];
  W3 := InverseTable[byte(T1[0] shr 24)];
  T0[3] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[27];
  // round 7
  W0 := InverseTable[byte(T0[0])];
  W1 := InverseTable[byte(T0[3] shr 8)];
  W2 := InverseTable[byte(T0[2] shr 16)];
  W3 := InverseTable[byte(T0[1] shr 24)];
  T1[0] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[20];
  W0 := InverseTable[byte(T0[1])];
  W1 := InverseTable[byte(T0[0] shr 8)];
  W2 := InverseTable[byte(T0[3] shr 16)];
  W3 := InverseTable[byte(T0[2] shr 24)];
  T1[1] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[21];
  W0 := InverseTable[byte(T0[2])];
  W1 := InverseTable[byte(T0[1] shr 8)];
  W2 := InverseTable[byte(T0[0] shr 16)];
  W3 := InverseTable[byte(T0[3] shr 24)];
  T1[2] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[22];
  W0 := InverseTable[byte(T0[3])];
  W1 := InverseTable[byte(T0[2] shr 8)];
  W2 := InverseTable[byte(T0[1] shr 16)];
  W3 := InverseTable[byte(T0[0] shr 24)];
  T1[3] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[23];
  // round 8
  W0 := InverseTable[byte(T1[0])];
  W1 := InverseTable[byte(T1[3] shr 8)];
  W2 := InverseTable[byte(T1[2] shr 16)];
  W3 := InverseTable[byte(T1[1] shr 24)];
  T0[0] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[16];
  W0 := InverseTable[byte(T1[1])];
  W1 := InverseTable[byte(T1[0] shr 8)];
  W2 := InverseTable[byte(T1[3] shr 16)];
  W3 := InverseTable[byte(T1[2] shr 24)];
  T0[1] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[17];
  W0 := InverseTable[byte(T1[2])];
  W1 := InverseTable[byte(T1[1] shr 8)];
  W2 := InverseTable[byte(T1[0] shr 16)];
  W3 := InverseTable[byte(T1[3] shr 24)];
  T0[2] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[18];
  W0 := InverseTable[byte(T1[3])];
  W1 := InverseTable[byte(T1[2] shr 8)];
  W2 := InverseTable[byte(T1[1] shr 16)];
  W3 := InverseTable[byte(T1[0] shr 24)];
  T0[3] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[19];
  // round 9
  W0 := InverseTable[byte(T0[0])];
  W1 := InverseTable[byte(T0[3] shr 8)];
  W2 := InverseTable[byte(T0[2] shr 16)];
  W3 := InverseTable[byte(T0[1] shr 24)];
  T1[0] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[12];
  W0 := InverseTable[byte(T0[1])];
  W1 := InverseTable[byte(T0[0] shr 8)];
  W2 := InverseTable[byte(T0[3] shr 16)];
  W3 := InverseTable[byte(T0[2] shr 24)];
  T1[1] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[13];
  W0 := InverseTable[byte(T0[2])];
  W1 := InverseTable[byte(T0[1] shr 8)];
  W2 := InverseTable[byte(T0[0] shr 16)];
  W3 := InverseTable[byte(T0[3] shr 24)];
  T1[2] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[14];
  W0 := InverseTable[byte(T0[3])];
  W1 := InverseTable[byte(T0[2] shr 8)];
  W2 := InverseTable[byte(T0[1] shr 16)];
  W3 := InverseTable[byte(T0[0] shr 24)];
  T1[3] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[15];
  // round 10
  W0 := InverseTable[byte(T1[0])];
  W1 := InverseTable[byte(T1[3] shr 8)];
  W2 := InverseTable[byte(T1[2] shr 16)];
  W3 := InverseTable[byte(T1[1] shr 24)];
  T0[0] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[8];
  W0 := InverseTable[byte(T1[1])];
  W1 := InverseTable[byte(T1[0] shr 8)];
  W2 := InverseTable[byte(T1[3] shr 16)];
  W3 := InverseTable[byte(T1[2] shr 24)];
  T0[1] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[9];
  W0 := InverseTable[byte(T1[2])];
  W1 := InverseTable[byte(T1[1] shr 8)];
  W2 := InverseTable[byte(T1[0] shr 16)];
  W3 := InverseTable[byte(T1[3] shr 24)];
  T0[2] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[10];
  W0 := InverseTable[byte(T1[3])];
  W1 := InverseTable[byte(T1[2] shr 8)];
  W2 := InverseTable[byte(T1[1] shr 16)];
  W3 := InverseTable[byte(T1[0] shr 24)];
  T0[3] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[11];
  // round 11
  W0 := InverseTable[byte(T0[0])];
  W1 := InverseTable[byte(T0[3] shr 8)];
  W2 := InverseTable[byte(T0[2] shr 16)];
  W3 := InverseTable[byte(T0[1] shr 24)];
  T1[0] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[4];
  W0 := InverseTable[byte(T0[1])];
  W1 := InverseTable[byte(T0[0] shr 8)];
  W2 := InverseTable[byte(T0[3] shr 16)];
  W3 := InverseTable[byte(T0[2] shr 24)];
  T1[1] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[5];
  W0 := InverseTable[byte(T0[2])];
  W1 := InverseTable[byte(T0[1] shr 8)];
  W2 := InverseTable[byte(T0[0] shr 16)];
  W3 := InverseTable[byte(T0[3] shr 24)];
  T1[2] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[6];
  W0 := InverseTable[byte(T0[3])];
  W1 := InverseTable[byte(T0[2] shr 8)];
  W2 := InverseTable[byte(T0[1] shr 16)];
  W3 := InverseTable[byte(T0[0] shr 24)];
  T1[3] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[7];
  // last round of transformations
  W0 := LastInverseTable[byte(T1[0])];
  W1 := LastInverseTable[byte(T1[3] shr 8)];
  W2 := LastInverseTable[byte(T1[2] shr 16)];
  W3 := LastInverseTable[byte(T1[1] shr 24)];
  T0[0] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[0];
  W0 := LastInverseTable[byte(T1[1])];
  W1 := LastInverseTable[byte(T1[0] shr 8)];
  W2 := LastInverseTable[byte(T1[3] shr 16)];
  W3 := LastInverseTable[byte(T1[2] shr 24)];
  T0[1] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[1];
  W0 := LastInverseTable[byte(T1[2])];
  W1 := LastInverseTable[byte(T1[1] shr 8)];
  W2 := LastInverseTable[byte(T1[0] shr 16)];
  W3 := LastInverseTable[byte(T1[3] shr 24)];
  T0[2] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[2];
  W0 := LastInverseTable[byte(T1[3])];
  W1 := LastInverseTable[byte(T1[2] shr 8)];
  W2 := LastInverseTable[byte(T1[1] shr 16)];
  W3 := LastInverseTable[byte(T1[0] shr 24)];
  T0[3] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[3];
  // finalizing
  PCardinal(@OutBuf[0])^ := T0[0];
  PCardinal(@OutBuf[4])^ := T0[1];
  PCardinal(@OutBuf[8])^ := T0[2];
  PCardinal(@OutBuf[12])^ := T0[3];
end;

procedure DecrypAES(const InBuf: TQAESBuffer; const Key: TQAESExpandedKey256;
  var OutBuf: TQAESBuffer); overload;
var
  T0, T1: array [0 .. 3] of Cardinal;
  W0, W1, W2, W3: Cardinal;
begin
  // initializing
  T0[0] := PCardinal(@InBuf[0])^ xor Key[56];
  T0[1] := PCardinal(@InBuf[4])^ xor Key[57];
  T0[2] := PCardinal(@InBuf[8])^ xor Key[58];
  T0[3] := PCardinal(@InBuf[12])^ xor Key[59];
  // performing transformations 13 times
  // round 1
  W0 := InverseTable[byte(T0[0])];
  W1 := InverseTable[byte(T0[3] shr 8)];
  W2 := InverseTable[byte(T0[2] shr 16)];
  W3 := InverseTable[byte(T0[1] shr 24)];
  T1[0] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[52];
  W0 := InverseTable[byte(T0[1])];
  W1 := InverseTable[byte(T0[0] shr 8)];
  W2 := InverseTable[byte(T0[3] shr 16)];
  W3 := InverseTable[byte(T0[2] shr 24)];
  T1[1] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[53];
  W0 := InverseTable[byte(T0[2])];
  W1 := InverseTable[byte(T0[1] shr 8)];
  W2 := InverseTable[byte(T0[0] shr 16)];
  W3 := InverseTable[byte(T0[3] shr 24)];
  T1[2] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[54];
  W0 := InverseTable[byte(T0[3])];
  W1 := InverseTable[byte(T0[2] shr 8)];
  W2 := InverseTable[byte(T0[1] shr 16)];
  W3 := InverseTable[byte(T0[0] shr 24)];
  T1[3] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[55];
  // round 2
  W0 := InverseTable[byte(T1[0])];
  W1 := InverseTable[byte(T1[3] shr 8)];
  W2 := InverseTable[byte(T1[2] shr 16)];
  W3 := InverseTable[byte(T1[1] shr 24)];
  T0[0] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[48];
  W0 := InverseTable[byte(T1[1])];
  W1 := InverseTable[byte(T1[0] shr 8)];
  W2 := InverseTable[byte(T1[3] shr 16)];
  W3 := InverseTable[byte(T1[2] shr 24)];
  T0[1] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[49];
  W0 := InverseTable[byte(T1[2])];
  W1 := InverseTable[byte(T1[1] shr 8)];
  W2 := InverseTable[byte(T1[0] shr 16)];
  W3 := InverseTable[byte(T1[3] shr 24)];
  T0[2] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[50];
  W0 := InverseTable[byte(T1[3])];
  W1 := InverseTable[byte(T1[2] shr 8)];
  W2 := InverseTable[byte(T1[1] shr 16)];
  W3 := InverseTable[byte(T1[0] shr 24)];
  T0[3] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[51];
  // round 3
  W0 := InverseTable[byte(T0[0])];
  W1 := InverseTable[byte(T0[3] shr 8)];
  W2 := InverseTable[byte(T0[2] shr 16)];
  W3 := InverseTable[byte(T0[1] shr 24)];
  T1[0] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[44];
  W0 := InverseTable[byte(T0[1])];
  W1 := InverseTable[byte(T0[0] shr 8)];
  W2 := InverseTable[byte(T0[3] shr 16)];
  W3 := InverseTable[byte(T0[2] shr 24)];
  T1[1] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[45];
  W0 := InverseTable[byte(T0[2])];
  W1 := InverseTable[byte(T0[1] shr 8)];
  W2 := InverseTable[byte(T0[0] shr 16)];
  W3 := InverseTable[byte(T0[3] shr 24)];
  T1[2] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[46];
  W0 := InverseTable[byte(T0[3])];
  W1 := InverseTable[byte(T0[2] shr 8)];
  W2 := InverseTable[byte(T0[1] shr 16)];
  W3 := InverseTable[byte(T0[0] shr 24)];
  T1[3] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[47];
  // round 4
  W0 := InverseTable[byte(T1[0])];
  W1 := InverseTable[byte(T1[3] shr 8)];
  W2 := InverseTable[byte(T1[2] shr 16)];
  W3 := InverseTable[byte(T1[1] shr 24)];
  T0[0] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[40];
  W0 := InverseTable[byte(T1[1])];
  W1 := InverseTable[byte(T1[0] shr 8)];
  W2 := InverseTable[byte(T1[3] shr 16)];
  W3 := InverseTable[byte(T1[2] shr 24)];
  T0[1] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[41];
  W0 := InverseTable[byte(T1[2])];
  W1 := InverseTable[byte(T1[1] shr 8)];
  W2 := InverseTable[byte(T1[0] shr 16)];
  W3 := InverseTable[byte(T1[3] shr 24)];
  T0[2] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[42];
  W0 := InverseTable[byte(T1[3])];
  W1 := InverseTable[byte(T1[2] shr 8)];
  W2 := InverseTable[byte(T1[1] shr 16)];
  W3 := InverseTable[byte(T1[0] shr 24)];
  T0[3] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[43];
  // round 5
  W0 := InverseTable[byte(T0[0])];
  W1 := InverseTable[byte(T0[3] shr 8)];
  W2 := InverseTable[byte(T0[2] shr 16)];
  W3 := InverseTable[byte(T0[1] shr 24)];
  T1[0] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[36];
  W0 := InverseTable[byte(T0[1])];
  W1 := InverseTable[byte(T0[0] shr 8)];
  W2 := InverseTable[byte(T0[3] shr 16)];
  W3 := InverseTable[byte(T0[2] shr 24)];
  T1[1] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[37];
  W0 := InverseTable[byte(T0[2])];
  W1 := InverseTable[byte(T0[1] shr 8)];
  W2 := InverseTable[byte(T0[0] shr 16)];
  W3 := InverseTable[byte(T0[3] shr 24)];
  T1[2] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[38];
  W0 := InverseTable[byte(T0[3])];
  W1 := InverseTable[byte(T0[2] shr 8)];
  W2 := InverseTable[byte(T0[1] shr 16)];
  W3 := InverseTable[byte(T0[0] shr 24)];
  T1[3] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[39];
  // round 6
  W0 := InverseTable[byte(T1[0])];
  W1 := InverseTable[byte(T1[3] shr 8)];
  W2 := InverseTable[byte(T1[2] shr 16)];
  W3 := InverseTable[byte(T1[1] shr 24)];
  T0[0] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[32];
  W0 := InverseTable[byte(T1[1])];
  W1 := InverseTable[byte(T1[0] shr 8)];
  W2 := InverseTable[byte(T1[3] shr 16)];
  W3 := InverseTable[byte(T1[2] shr 24)];
  T0[1] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[33];
  W0 := InverseTable[byte(T1[2])];
  W1 := InverseTable[byte(T1[1] shr 8)];
  W2 := InverseTable[byte(T1[0] shr 16)];
  W3 := InverseTable[byte(T1[3] shr 24)];
  T0[2] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[34];
  W0 := InverseTable[byte(T1[3])];
  W1 := InverseTable[byte(T1[2] shr 8)];
  W2 := InverseTable[byte(T1[1] shr 16)];
  W3 := InverseTable[byte(T1[0] shr 24)];
  T0[3] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[35];
  // round 7
  W0 := InverseTable[byte(T0[0])];
  W1 := InverseTable[byte(T0[3] shr 8)];
  W2 := InverseTable[byte(T0[2] shr 16)];
  W3 := InverseTable[byte(T0[1] shr 24)];
  T1[0] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[28];
  W0 := InverseTable[byte(T0[1])];
  W1 := InverseTable[byte(T0[0] shr 8)];
  W2 := InverseTable[byte(T0[3] shr 16)];
  W3 := InverseTable[byte(T0[2] shr 24)];
  T1[1] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[29];
  W0 := InverseTable[byte(T0[2])];
  W1 := InverseTable[byte(T0[1] shr 8)];
  W2 := InverseTable[byte(T0[0] shr 16)];
  W3 := InverseTable[byte(T0[3] shr 24)];
  T1[2] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[30];
  W0 := InverseTable[byte(T0[3])];
  W1 := InverseTable[byte(T0[2] shr 8)];
  W2 := InverseTable[byte(T0[1] shr 16)];
  W3 := InverseTable[byte(T0[0] shr 24)];
  T1[3] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[31];
  // round 8
  W0 := InverseTable[byte(T1[0])];
  W1 := InverseTable[byte(T1[3] shr 8)];
  W2 := InverseTable[byte(T1[2] shr 16)];
  W3 := InverseTable[byte(T1[1] shr 24)];
  T0[0] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[24];
  W0 := InverseTable[byte(T1[1])];
  W1 := InverseTable[byte(T1[0] shr 8)];
  W2 := InverseTable[byte(T1[3] shr 16)];
  W3 := InverseTable[byte(T1[2] shr 24)];
  T0[1] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[25];
  W0 := InverseTable[byte(T1[2])];
  W1 := InverseTable[byte(T1[1] shr 8)];
  W2 := InverseTable[byte(T1[0] shr 16)];
  W3 := InverseTable[byte(T1[3] shr 24)];
  T0[2] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[26];
  W0 := InverseTable[byte(T1[3])];
  W1 := InverseTable[byte(T1[2] shr 8)];
  W2 := InverseTable[byte(T1[1] shr 16)];
  W3 := InverseTable[byte(T1[0] shr 24)];
  T0[3] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[27];
  // round 9
  W0 := InverseTable[byte(T0[0])];
  W1 := InverseTable[byte(T0[3] shr 8)];
  W2 := InverseTable[byte(T0[2] shr 16)];
  W3 := InverseTable[byte(T0[1] shr 24)];
  T1[0] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[20];
  W0 := InverseTable[byte(T0[1])];
  W1 := InverseTable[byte(T0[0] shr 8)];
  W2 := InverseTable[byte(T0[3] shr 16)];
  W3 := InverseTable[byte(T0[2] shr 24)];
  T1[1] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[21];
  W0 := InverseTable[byte(T0[2])];
  W1 := InverseTable[byte(T0[1] shr 8)];
  W2 := InverseTable[byte(T0[0] shr 16)];
  W3 := InverseTable[byte(T0[3] shr 24)];
  T1[2] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[22];
  W0 := InverseTable[byte(T0[3])];
  W1 := InverseTable[byte(T0[2] shr 8)];
  W2 := InverseTable[byte(T0[1] shr 16)];
  W3 := InverseTable[byte(T0[0] shr 24)];
  T1[3] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[23];
  // round 10
  W0 := InverseTable[byte(T1[0])];
  W1 := InverseTable[byte(T1[3] shr 8)];
  W2 := InverseTable[byte(T1[2] shr 16)];
  W3 := InverseTable[byte(T1[1] shr 24)];
  T0[0] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[16];
  W0 := InverseTable[byte(T1[1])];
  W1 := InverseTable[byte(T1[0] shr 8)];
  W2 := InverseTable[byte(T1[3] shr 16)];
  W3 := InverseTable[byte(T1[2] shr 24)];
  T0[1] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[17];
  W0 := InverseTable[byte(T1[2])];
  W1 := InverseTable[byte(T1[1] shr 8)];
  W2 := InverseTable[byte(T1[0] shr 16)];
  W3 := InverseTable[byte(T1[3] shr 24)];
  T0[2] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[18];
  W0 := InverseTable[byte(T1[3])];
  W1 := InverseTable[byte(T1[2] shr 8)];
  W2 := InverseTable[byte(T1[1] shr 16)];
  W3 := InverseTable[byte(T1[0] shr 24)];
  T0[3] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[19];
  // round 11
  W0 := InverseTable[byte(T0[0])];
  W1 := InverseTable[byte(T0[3] shr 8)];
  W2 := InverseTable[byte(T0[2] shr 16)];
  W3 := InverseTable[byte(T0[1] shr 24)];
  T1[0] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[12];
  W0 := InverseTable[byte(T0[1])];
  W1 := InverseTable[byte(T0[0] shr 8)];
  W2 := InverseTable[byte(T0[3] shr 16)];
  W3 := InverseTable[byte(T0[2] shr 24)];
  T1[1] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[13];
  W0 := InverseTable[byte(T0[2])];
  W1 := InverseTable[byte(T0[1] shr 8)];
  W2 := InverseTable[byte(T0[0] shr 16)];
  W3 := InverseTable[byte(T0[3] shr 24)];
  T1[2] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[14];
  W0 := InverseTable[byte(T0[3])];
  W1 := InverseTable[byte(T0[2] shr 8)];
  W2 := InverseTable[byte(T0[1] shr 16)];
  W3 := InverseTable[byte(T0[0] shr 24)];
  T1[3] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[15];
  // round 12
  W0 := InverseTable[byte(T1[0])];
  W1 := InverseTable[byte(T1[3] shr 8)];
  W2 := InverseTable[byte(T1[2] shr 16)];
  W3 := InverseTable[byte(T1[1] shr 24)];
  T0[0] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[8];
  W0 := InverseTable[byte(T1[1])];
  W1 := InverseTable[byte(T1[0] shr 8)];
  W2 := InverseTable[byte(T1[3] shr 16)];
  W3 := InverseTable[byte(T1[2] shr 24)];
  T0[1] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[9];
  W0 := InverseTable[byte(T1[2])];
  W1 := InverseTable[byte(T1[1] shr 8)];
  W2 := InverseTable[byte(T1[0] shr 16)];
  W3 := InverseTable[byte(T1[3] shr 24)];
  T0[2] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[10];
  W0 := InverseTable[byte(T1[3])];
  W1 := InverseTable[byte(T1[2] shr 8)];
  W2 := InverseTable[byte(T1[1] shr 16)];
  W3 := InverseTable[byte(T1[0] shr 24)];
  T0[3] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[11];
  // round 13
  W0 := InverseTable[byte(T0[0])];
  W1 := InverseTable[byte(T0[3] shr 8)];
  W2 := InverseTable[byte(T0[2] shr 16)];
  W3 := InverseTable[byte(T0[1] shr 24)];
  T1[0] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[4];
  W0 := InverseTable[byte(T0[1])];
  W1 := InverseTable[byte(T0[0] shr 8)];
  W2 := InverseTable[byte(T0[3] shr 16)];
  W3 := InverseTable[byte(T0[2] shr 24)];
  T1[1] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[5];
  W0 := InverseTable[byte(T0[2])];
  W1 := InverseTable[byte(T0[1] shr 8)];
  W2 := InverseTable[byte(T0[0] shr 16)];
  W3 := InverseTable[byte(T0[3] shr 24)];
  T1[2] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[6];
  W0 := InverseTable[byte(T0[3])];
  W1 := InverseTable[byte(T0[2] shr 8)];
  W2 := InverseTable[byte(T0[1] shr 16)];
  W3 := InverseTable[byte(T0[0] shr 24)];
  T1[3] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[7];
  // last round of transformations
  W0 := LastInverseTable[byte(T1[0])];
  W1 := LastInverseTable[byte(T1[3] shr 8)];
  W2 := LastInverseTable[byte(T1[2] shr 16)];
  W3 := LastInverseTable[byte(T1[1] shr 24)];
  T0[0] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[0];
  W0 := LastInverseTable[byte(T1[1])];
  W1 := LastInverseTable[byte(T1[0] shr 8)];
  W2 := LastInverseTable[byte(T1[3] shr 16)];
  W3 := LastInverseTable[byte(T1[2] shr 24)];
  T0[1] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[1];
  W0 := LastInverseTable[byte(T1[2])];
  W1 := LastInverseTable[byte(T1[1] shr 8)];
  W2 := LastInverseTable[byte(T1[0] shr 16)];
  W3 := LastInverseTable[byte(T1[3] shr 24)];
  T0[2] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[2];
  W0 := LastInverseTable[byte(T1[3])];
  W1 := LastInverseTable[byte(T1[2] shr 8)];
  W2 := LastInverseTable[byte(T1[1] shr 16)];
  W3 := LastInverseTable[byte(T1[0] shr 24)];
  T0[3] := (W0 xor ((W1 shl 8) or (W1 shr 24)) xor ((W2 shl 16) or (W2 shr 16))
    xor ((W3 shl 24) or (W3 shr 8))) xor Key[3];
  // finalizing
  PCardinal(@OutBuf[0])^ := T0[0];
  PCardinal(@OutBuf[4])^ := T0[1];
  PCardinal(@OutBuf[8])^ := T0[2];
  PCardinal(@OutBuf[12])^ := T0[3];
end;

procedure FillPaddings(var ABuf: TQAESBuffer; len: Integer;
  APaddingMode: TQAESPaddingMode); inline;
begin
  case APaddingMode of
    pmZero:
      FillChar(ABuf[len], SizeOf(TQAESBuffer) - len, 0);
    pmPKCS5, pmPKCS7:
      FillChar(ABuf[len], SizeOf(TQAESBuffer) - len, SizeOf(TQAESBuffer) - len);
  end;
end;

procedure EncryptAESStreamECB(Source: TStream;
  const ExpandedKey: TQAESExpandedKey128; Dest: TStream;
  APaddingMode: TQAESPaddingMode; AOnProgress: TQAESProgress); overload;
var
  TempIn, TempOut: TQAESBuffer;
  AProcessed, ALastProcessed, ATotal, ASize: Int64;
  procedure ProcessBlock;
  var
    ABlockSize: Integer;
  begin
    ABlockSize := Source.Read(TempIn, SizeOf(TempIn));
    if ABlockSize < SizeOf(TempIn) then
      FillPaddings(TempIn, ABlockSize, APaddingMode);
    EncryptAES(TempIn, ExpandedKey, TempOut);
    Dest.WriteBuffer(TempOut, SizeOf(TempOut));
    Dec(ASize, SizeOf(TempOut));
    Inc(AProcessed, SizeOf(TempOut));
  end;

begin
  Source.Position := 0;
  ASize := Source.Size;
  Dest.WriteBuffer(ASize, SizeOf(ASize));
  ATotal := ASize;
  AProcessed := 0;
  ALastProcessed := 0;
  while ASize > 0 do
  begin
    ProcessBlock;
    if AProcessed - ALastProcessed > AESProgressBlock then
    begin
      ALastProcessed := AProcessed;
      if Assigned(AOnProgress) then
        AOnProgress(AProcessed, ATotal);
    end;
  end;
  if (AProcessed > ALastProcessed) and Assigned(AOnProgress) then
    AOnProgress(ATotal, ATotal);
end;

procedure EncryptAESStreamECB(Source: TStream;
  const ExpandedKey: TQAESExpandedKey192; Dest: TStream;
  APaddingMode: TQAESPaddingMode; AOnProgress: TQAESProgress); overload;
var
  TempIn, TempOut: TQAESBuffer;
  AProcessed, ALastProcessed, ATotal, ASize: Int64;
  procedure ProcessBlock;
  var
    ABlockSize: Integer;
  begin
    ABlockSize := Source.Read(TempIn, SizeOf(TempIn));
    if ABlockSize < SizeOf(TempIn) then
      FillPaddings(TempIn, ABlockSize, APaddingMode);
    EncryptAES(TempIn, ExpandedKey, TempOut);
    Dest.WriteBuffer(TempOut, SizeOf(TempOut));
    Dec(ASize, SizeOf(TempOut));
    Inc(AProcessed, SizeOf(TempOut));
  end;

begin
  Source.Position := 0;
  ASize := Source.Size;
  Dest.WriteBuffer(ASize, SizeOf(ASize));
  ATotal := ASize;
  AProcessed := 0;
  ALastProcessed := 0;
  while ASize > 0 do
  begin
    ProcessBlock;
    if AProcessed - ALastProcessed > AESProgressBlock then
    begin
      ALastProcessed := AProcessed;
      if Assigned(AOnProgress) then
        AOnProgress(AProcessed, ATotal);
    end;
  end;
  if (AProcessed > ALastProcessed) and Assigned(AOnProgress) then
    AOnProgress(ATotal, ATotal);
end;

procedure EncryptAESStreamECB(Source: TStream;
  const ExpandedKey: TQAESExpandedKey256; Dest: TStream;
  APaddingMode: TQAESPaddingMode; AOnProgress: TQAESProgress); overload;
var
  TempIn, TempOut: TQAESBuffer;
  AProcessed, ALastProcessed, ATotal, ASize: Int64;
  procedure ProcessBlock;
  var
    ABlockSize: Integer;
  begin
    ABlockSize := Source.Read(TempIn, SizeOf(TempIn));
    if ABlockSize < SizeOf(TempIn) then
      FillPaddings(TempIn, ABlockSize, APaddingMode);
    EncryptAES(TempIn, ExpandedKey, TempOut);
    Dest.WriteBuffer(TempOut, SizeOf(TempOut));
    Dec(ASize, SizeOf(TempOut));
    Inc(AProcessed, SizeOf(TempOut));
  end;

begin
  Source.Position := 0;
  ASize := Source.Size;
  Dest.WriteBuffer(ASize, SizeOf(ASize));
  ATotal := ASize;
  AProcessed := 0;
  ALastProcessed := 0;
  while ASize > 0 do
  begin
    ProcessBlock;
    if AProcessed - ALastProcessed > AESProgressBlock then
    begin
      ALastProcessed := AProcessed;
      if Assigned(AOnProgress) then
        AOnProgress(AProcessed, ATotal);
    end;
  end;
  if (AProcessed > ALastProcessed) and Assigned(AOnProgress) then
    AOnProgress(ATotal, ATotal);
end;

procedure EncryptAESStreamECB(Source: TStream; const Key: TQAESKey128;
  Dest: TStream; APaddingMode: TQAESPaddingMode;
  AOnProgress: TQAESProgress); overload;
var
  ExpandedKey: TQAESExpandedKey128;
begin
  ExpandAESKeyForEncryption(Key, ExpandedKey);
  EncryptAESStreamECB(Source, ExpandedKey, Dest, APaddingMode, AOnProgress);
end;

procedure EncryptAESStreamECB(Source: TStream; const Key: TQAESKey192;
  Dest: TStream; APaddingMode: TQAESPaddingMode;
  AOnProgress: TQAESProgress); overload;
var
  ExpandedKey: TQAESExpandedKey192;
begin
  ExpandAESKeyForEncryption(Key, ExpandedKey);
  EncryptAESStreamECB(Source, ExpandedKey, Dest, APaddingMode, AOnProgress);
end;

procedure EncryptAESStreamECB(Source: TStream; const Key: TQAESKey256;
  Dest: TStream; APaddingMode: TQAESPaddingMode;
  AOnProgress: TQAESProgress); overload;
var
  ExpandedKey: TQAESExpandedKey256;
begin
  ExpandAESKeyForEncryption(Key, ExpandedKey);
  EncryptAESStreamECB(Source, ExpandedKey, Dest, APaddingMode, AOnProgress);
end;

procedure DecrypAESStreamECB(Source: TStream;
  const ExpandedKey: TQAESExpandedKey128; Dest: TStream;
  APaddingMode: TQAESPaddingMode; AOnProgress: TQAESProgress); overload;
var
  TempIn, TempOut: TQAESBuffer;
  AProcessed, ALastProcessed, ATotal, ASize: Int64;
begin
  Source.ReadBuffer(ASize, SizeOf(Int64));
  if ASize > Source.Size - Source.Position then
    raise EAESError.Create(SBadStream);
  ATotal := ASize;
  AProcessed := 0;
  ALastProcessed := 0;
  while ASize > 0 do
  begin
    Source.ReadBuffer(TempIn, SizeOf(TempIn));
    DecrypAES(TempIn, ExpandedKey, TempOut);
    if ASize >= SizeOf(TempIn) then
      Dest.WriteBuffer(TempOut, SizeOf(TempIn))
    else
      Dest.WriteBuffer(TempOut, ASize);
    Dec(ASize, SizeOf(TempIn));
    Inc(AProcessed, SizeOf(TempIn));
    if AProcessed - ALastProcessed > AESProgressBlock then
    begin
      ALastProcessed := AProcessed;
      if Assigned(AOnProgress) then
        AOnProgress(AProcessed, ATotal);
    end;
  end;
  if (AProcessed > ALastProcessed) and Assigned(AOnProgress) then
    AOnProgress(ATotal, ATotal);
end;

procedure DecrypAESStreamECB(Source: TStream;
  const ExpandedKey: TQAESExpandedKey192; Dest: TStream;
  APaddingMode: TQAESPaddingMode; AOnProgress: TQAESProgress); overload;
var
  TempIn, TempOut: TQAESBuffer;
  AProcessed, ALastProcessed, ATotal, ASize: Int64;
begin
  Source.ReadBuffer(ASize, SizeOf(Int64));
  if ASize > Source.Size - Source.Position then
    raise EAESError.Create(SBadStream);
  ATotal := ASize;
  AProcessed := 0;
  ALastProcessed := 0;
  while ASize > 0 do
  begin
    Source.ReadBuffer(TempIn, SizeOf(TempIn));
    DecrypAES(TempIn, ExpandedKey, TempOut);
    if ASize >= SizeOf(TempIn) then
      Dest.WriteBuffer(TempOut, SizeOf(TempIn))
    else
      Dest.WriteBuffer(TempOut, ASize);
    Dec(ASize, SizeOf(TempIn));
    Inc(AProcessed, SizeOf(TempIn));
    if AProcessed - ALastProcessed > AESProgressBlock then
    begin
      ALastProcessed := AProcessed;
      if Assigned(AOnProgress) then
        AOnProgress(AProcessed, ATotal);
    end;
  end;
  if (AProcessed > ALastProcessed) and Assigned(AOnProgress) then
    AOnProgress(ATotal, ATotal);
end;

procedure DecrypAESStreamECB(Source: TStream;
  const ExpandedKey: TQAESExpandedKey256; Dest: TStream;
  APaddingMode: TQAESPaddingMode; AOnProgress: TQAESProgress); overload;
var
  TempIn, TempOut: TQAESBuffer;
  AProcessed, ALastProcessed, ATotal, ASize: Int64;
begin
  Source.ReadBuffer(ASize, SizeOf(Int64));
  if ASize > Source.Size - Source.Position then
    raise EAESError.Create(SBadStream);
  ATotal := ASize;
  AProcessed := 0;
  ALastProcessed := 0;
  while ASize > 0 do
  begin
    Source.ReadBuffer(TempIn, SizeOf(TempIn));
    DecrypAES(TempIn, ExpandedKey, TempOut);
    if ASize >= SizeOf(TempIn) then
      Dest.WriteBuffer(TempOut, SizeOf(TempIn))
    else
      Dest.WriteBuffer(TempOut, ASize);
    Dec(ASize, SizeOf(TempIn));
    Inc(AProcessed, SizeOf(TempIn));
    if AProcessed - ALastProcessed > AESProgressBlock then
    begin
      ALastProcessed := AProcessed;
      if Assigned(AOnProgress) then
        AOnProgress(AProcessed, ATotal);
    end;
  end;
  if (AProcessed > ALastProcessed) and Assigned(AOnProgress) then
    AOnProgress(ATotal, ATotal);
end;

procedure DecrypAESStreamECB(Source: TStream; const Key: TQAESKey128;
  Dest: TStream; APaddingMode: TQAESPaddingMode;
  AOnProgress: TQAESProgress); overload;
var
  ExpandedKey: TQAESExpandedKey128;
begin
  ExpandAESKeyForDecryption(Key, ExpandedKey);
  DecrypAESStreamECB(Source, ExpandedKey, Dest, APaddingMode, AOnProgress);
end;

procedure DecrypAESStreamECB(Source: TStream; const Key: TQAESKey192;
  Dest: TStream; APaddingMode: TQAESPaddingMode;
  AOnProgress: TQAESProgress); overload;
var
  ExpandedKey: TQAESExpandedKey192;
begin
  ExpandAESKeyForDecryption(Key, ExpandedKey);
  DecrypAESStreamECB(Source, ExpandedKey, Dest, APaddingMode, AOnProgress);
end;

procedure DecrypAESStreamECB(Source: TStream; const Key: TQAESKey256;
  Dest: TStream; APaddingMode: TQAESPaddingMode;
  AOnProgress: TQAESProgress); overload;
var
  ExpandedKey: TQAESExpandedKey256;
begin
  ExpandAESKeyForDecryption(Key, ExpandedKey);
  DecrypAESStreamECB(Source, ExpandedKey, Dest, APaddingMode, AOnProgress);
end;


// Stream encryption routines (CBC mode)

procedure EncryptAESStreamCBC(Source: TStream;
  const ExpandedKey: TQAESExpandedKey128; const InitVector: TQAESBuffer;
  Dest: TStream; APaddingMode: TQAESPaddingMode;
  AOnProgress: TQAESProgress); overload;
var
  TempIn, TempOut, Vector: TQAESBuffer;
  AProcessed, ALastProcessed, ATotal, ASize: Int64;
  procedure ProcessBlock;
  var
    ABlockSize: Integer;
  begin
    ABlockSize := Source.Read(TempIn, SizeOf(TempIn));
    if ABlockSize < SizeOf(TempIn) then
      FillPaddings(TempIn, ABlockSize, APaddingMode);
    PCardinal(@TempIn[0])^ := PCardinal(@TempIn[0])^ xor PCardinal(@Vector[0])^;
    PCardinal(@TempIn[4])^ := PCardinal(@TempIn[4])^ xor PCardinal(@Vector[4])^;
    PCardinal(@TempIn[8])^ := PCardinal(@TempIn[8])^ xor PCardinal(@Vector[8])^;
    PCardinal(@TempIn[12])^ := PCardinal(@TempIn[12])
      ^ xor PCardinal(@Vector[12])^;
    EncryptAES(TempIn, ExpandedKey, TempOut);
    Dest.WriteBuffer(TempOut, SizeOf(TempOut));
    Vector := TempOut;
    Dec(ASize, SizeOf(TempIn));
    Inc(AProcessed, SizeOf(TempIn));
  end;

begin
  Source.Position := 0;
  ASize := Source.Size;
  Dest.WriteBuffer(ASize, SizeOf(Int64));
  if ASize > Source.Size - Source.Position then
    raise EAESError.Create(SBadStream);
  Vector := InitVector;
  ATotal := ASize;
  AProcessed := 0;
  ALastProcessed := 0;
  while ASize > 0 do
  begin
    ProcessBlock;
    if AProcessed - ALastProcessed > AESProgressBlock then
    begin
      ALastProcessed := AProcessed;
      if Assigned(AOnProgress) then
        AOnProgress(AProcessed, ATotal);
    end;
  end;
  if (AProcessed > ALastProcessed) and Assigned(AOnProgress) then
    AOnProgress(ATotal, ATotal);
end;

procedure EncryptAESStreamCBC(Source: TStream;
  const ExpandedKey: TQAESExpandedKey192; const InitVector: TQAESBuffer;
  Dest: TStream; APaddingMode: TQAESPaddingMode;
  AOnProgress: TQAESProgress); overload;
var
  TempIn, TempOut, Vector: TQAESBuffer;
  AProcessed, ALastProcessed, ATotal, ASize: Int64;
  procedure ProcessBlock;
  var
    ABlockSize: Integer;
  begin
    ABlockSize := Source.Read(TempIn, SizeOf(TempIn));
    if ABlockSize < SizeOf(TempIn) then
      FillPaddings(TempIn, ABlockSize, APaddingMode);
    PCardinal(@TempIn[0])^ := PCardinal(@TempIn[0])^ xor PCardinal(@Vector[0])^;
    PCardinal(@TempIn[4])^ := PCardinal(@TempIn[4])^ xor PCardinal(@Vector[4])^;
    PCardinal(@TempIn[8])^ := PCardinal(@TempIn[8])^ xor PCardinal(@Vector[8])^;
    PCardinal(@TempIn[12])^ := PCardinal(@TempIn[12])
      ^ xor PCardinal(@Vector[12])^;
    EncryptAES(TempIn, ExpandedKey, TempOut);
    Dest.WriteBuffer(TempOut, SizeOf(TempOut));
    Vector := TempOut;
    Dec(ASize, SizeOf(TempIn));
    Inc(AProcessed, SizeOf(TempIn));
  end;

begin
  Source.Position := 0;
  ASize := Source.Size;
  Dest.WriteBuffer(ASize, SizeOf(Int64));
  if ASize > Source.Size - Source.Position then
    raise EAESError.Create(SBadStream);
  Vector := InitVector;
  ATotal := ASize;
  AProcessed := 0;
  ALastProcessed := 0;
  while ASize > 0 do
  begin
    ProcessBlock;
    if AProcessed - ALastProcessed > AESProgressBlock then
    begin
      ALastProcessed := AProcessed;
      if Assigned(AOnProgress) then
        AOnProgress(AProcessed, ATotal);
    end;
  end;
  if (AProcessed > ALastProcessed) and Assigned(AOnProgress) then
    AOnProgress(ATotal, ATotal);
end;

procedure EncryptAESStreamCBC(Source: TStream;
  const ExpandedKey: TQAESExpandedKey256; const InitVector: TQAESBuffer;
  Dest: TStream; APaddingMode: TQAESPaddingMode;
  AOnProgress: TQAESProgress); overload;
var
  TempIn, TempOut, Vector: TQAESBuffer;
  AProcessed, ALastProcessed, ATotal, ASize: Int64;
  procedure ProcessBlock;
  var
    ABlockSize: Integer;
  begin
    ABlockSize := Source.Read(TempIn, SizeOf(TempIn));
    if ABlockSize < SizeOf(TempIn) then
      FillPaddings(TempIn, ABlockSize, APaddingMode);
    PCardinal(@TempIn[0])^ := PCardinal(@TempIn[0])^ xor PCardinal(@Vector[0])^;
    PCardinal(@TempIn[4])^ := PCardinal(@TempIn[4])^ xor PCardinal(@Vector[4])^;
    PCardinal(@TempIn[8])^ := PCardinal(@TempIn[8])^ xor PCardinal(@Vector[8])^;
    PCardinal(@TempIn[12])^ := PCardinal(@TempIn[12])
      ^ xor PCardinal(@Vector[12])^;
    EncryptAES(TempIn, ExpandedKey, TempOut);
    Dest.WriteBuffer(TempOut, SizeOf(TempOut));
    Vector := TempOut;
    Dec(ASize, SizeOf(TempIn));
    Inc(AProcessed, SizeOf(TempIn));
  end;

begin
  Source.Position := 0;
  ASize := Source.Size;
  Dest.WriteBuffer(ASize, SizeOf(Int64));
  if ASize > Source.Size - Source.Position then
    raise EAESError.Create(SBadStream);
  Vector := InitVector;
  ATotal := ASize;
  AProcessed := 0;
  ALastProcessed := 0;
  while ASize > 0 do
  begin
    ProcessBlock;
    if AProcessed - ALastProcessed > AESProgressBlock then
    begin
      ALastProcessed := AProcessed;
      if Assigned(AOnProgress) then
        AOnProgress(AProcessed, ATotal);
    end;
  end;
  if (AProcessed > ALastProcessed) and Assigned(AOnProgress) then
    AOnProgress(ATotal, ATotal);
end;

procedure EncryptAESStreamCBC(Source: TStream; const Key: TQAESKey128;
  const InitVector: TQAESBuffer; Dest: TStream; APaddingMode: TQAESPaddingMode;
  AOnProgress: TQAESProgress); overload;
var
  ExpandedKey: TQAESExpandedKey128;
begin
  ExpandAESKeyForEncryption(Key, ExpandedKey);
  EncryptAESStreamCBC(Source, ExpandedKey, InitVector, Dest, APaddingMode,
    AOnProgress);
end;

procedure EncryptAESStreamCBC(Source: TStream; const Key: TQAESKey192;
  const InitVector: TQAESBuffer; Dest: TStream; APaddingMode: TQAESPaddingMode;
  AOnProgress: TQAESProgress); overload;
var
  ExpandedKey: TQAESExpandedKey192;
begin
  ExpandAESKeyForEncryption(Key, ExpandedKey);
  EncryptAESStreamCBC(Source, ExpandedKey, InitVector, Dest, APaddingMode,
    AOnProgress);
end;

procedure EncryptAESStreamCBC(Source: TStream; const Key: TQAESKey256;
  const InitVector: TQAESBuffer; Dest: TStream; APaddingMode: TQAESPaddingMode;
  AOnProgress: TQAESProgress); overload;
var
  ExpandedKey: TQAESExpandedKey256;
begin
  ExpandAESKeyForEncryption(Key, ExpandedKey);
  EncryptAESStreamCBC(Source, ExpandedKey, InitVector, Dest, APaddingMode,
    AOnProgress);
end;

// Stream decryption routines (CBC mode)

procedure DecrypAESStreamCBC(Source: TStream;
  const ExpandedKey: TQAESExpandedKey128; const InitVector: TQAESBuffer;
  Dest: TStream; APaddingMode: TQAESPaddingMode;
  AOnProgress: TQAESProgress); overload;
var
  TempIn, TempOut: TQAESBuffer;
  Vector1, Vector2: TQAESBuffer;
  AProcessed, ALastProcessed, ATotal, ASize: Int64;
  procedure ProcessBlock;
  begin
    Source.ReadBuffer(TempIn, SizeOf(TempIn));
    Vector2 := TempIn;
    DecrypAES(TempIn, ExpandedKey, TempOut);
    PCardinal(@TempOut[0])^ := PCardinal(@TempOut[0])
      ^ xor PCardinal(@Vector1[0])^;
    PCardinal(@TempOut[4])^ := PCardinal(@TempOut[4])
      ^ xor PCardinal(@Vector1[4])^;
    PCardinal(@TempOut[8])^ := PCardinal(@TempOut[8])
      ^ xor PCardinal(@Vector1[8])^;
    PCardinal(@TempOut[12])^ := PCardinal(@TempOut[12])
      ^ xor PCardinal(@Vector1[12])^;
    if ASize > SizeOf(TempOut) then
      Dest.WriteBuffer(TempOut, SizeOf(TempOut))
    else
      Dest.WriteBuffer(TempOut, ASize);
    Vector1 := Vector2;
    Dec(ASize, SizeOf(TempIn));
    Inc(AProcessed, SizeOf(TempIn));
  end;

begin
  Source.ReadBuffer(ASize, SizeOf(Int64));
  if ASize > Source.Size - Source.Position then
    raise EAESError.Create(SBadStream);
  Vector1 := InitVector;
  ATotal := ASize;
  AProcessed := 0;
  ALastProcessed := 0;
  while ASize > 0 do
  begin
    ProcessBlock;
    if AProcessed - ALastProcessed > AESProgressBlock then
    begin
      ALastProcessed := AProcessed;
      if Assigned(AOnProgress) then
        AOnProgress(AProcessed, ATotal);
    end;
  end;
  if (AProcessed > ALastProcessed) and Assigned(AOnProgress) then
    AOnProgress(ATotal, ATotal);
end;

procedure DecrypAESStreamCBC(Source: TStream;
  const ExpandedKey: TQAESExpandedKey192; const InitVector: TQAESBuffer;
  Dest: TStream; APaddingMode: TQAESPaddingMode;
  AOnProgress: TQAESProgress); overload;
var
  TempIn, TempOut: TQAESBuffer;
  Vector1, Vector2: TQAESBuffer;
  AProcessed, ALastProcessed, ATotal, ASize: Int64;
  procedure ProcessBlock;
  begin
    Source.ReadBuffer(TempIn, SizeOf(TempIn));
    Vector2 := TempIn;
    DecrypAES(TempIn, ExpandedKey, TempOut);
    PCardinal(@TempOut[0])^ := PCardinal(@TempOut[0])
      ^ xor PCardinal(@Vector1[0])^;
    PCardinal(@TempOut[4])^ := PCardinal(@TempOut[4])
      ^ xor PCardinal(@Vector1[4])^;
    PCardinal(@TempOut[8])^ := PCardinal(@TempOut[8])
      ^ xor PCardinal(@Vector1[8])^;
    PCardinal(@TempOut[12])^ := PCardinal(@TempOut[12])
      ^ xor PCardinal(@Vector1[12])^;
    if ASize > SizeOf(TempOut) then
      Dest.WriteBuffer(TempOut, SizeOf(TempOut))
    else
      Dest.WriteBuffer(TempOut, ASize);
    Vector1 := Vector2;
    Dec(ASize, SizeOf(TempIn));
    Inc(AProcessed, SizeOf(TempIn));
  end;

begin
  Source.ReadBuffer(ASize, SizeOf(Int64));
  if ASize > Source.Size - Source.Position then
    raise EAESError.Create(SBadStream);
  Vector1 := InitVector;
  ATotal := ASize;
  AProcessed := 0;
  ALastProcessed := 0;
  while ASize > 0 do
  begin
    ProcessBlock;
    if AProcessed - ALastProcessed > AESProgressBlock then
    begin
      ALastProcessed := AProcessed;
      if Assigned(AOnProgress) then
        AOnProgress(AProcessed, ATotal);
    end;
  end;
  if (AProcessed > ALastProcessed) and Assigned(AOnProgress) then
    AOnProgress(ATotal, ATotal);
end;

procedure DecrypAESStreamCBC(Source: TStream;
  const ExpandedKey: TQAESExpandedKey256; const InitVector: TQAESBuffer;
  Dest: TStream; APaddingMode: TQAESPaddingMode;
  AOnProgress: TQAESProgress); overload;
var
  TempIn, TempOut: TQAESBuffer;
  Vector1, Vector2: TQAESBuffer;
  AProcessed, ALastProcessed, ATotal, ASize: Int64;
  procedure ProcessBlock;
  begin
    Source.ReadBuffer(TempIn, SizeOf(TempIn));
    Vector2 := TempIn;
    DecrypAES(TempIn, ExpandedKey, TempOut);
    PCardinal(@TempOut[0])^ := PCardinal(@TempOut[0])
      ^ xor PCardinal(@Vector1[0])^;
    PCardinal(@TempOut[4])^ := PCardinal(@TempOut[4])
      ^ xor PCardinal(@Vector1[4])^;
    PCardinal(@TempOut[8])^ := PCardinal(@TempOut[8])
      ^ xor PCardinal(@Vector1[8])^;
    PCardinal(@TempOut[12])^ := PCardinal(@TempOut[12])
      ^ xor PCardinal(@Vector1[12])^;
    if ASize > SizeOf(TempOut) then
      Dest.WriteBuffer(TempOut, SizeOf(TempOut))
    else
      Dest.WriteBuffer(TempOut, ASize);
    Vector1 := Vector2;
    Dec(ASize, SizeOf(TempIn));
    Inc(AProcessed, SizeOf(TempIn));
  end;

begin
  Source.ReadBuffer(ASize, SizeOf(Int64));
  if ASize > Source.Size - Source.Position then
    raise EAESError.Create(SBadStream);
  Vector1 := InitVector;
  ATotal := ASize;
  AProcessed := 0;
  ALastProcessed := 0;
  while ASize > 0 do
  begin
    ProcessBlock;
    if AProcessed - ALastProcessed > AESProgressBlock then
    begin
      ALastProcessed := AProcessed;
      if Assigned(AOnProgress) then
        AOnProgress(AProcessed, ATotal);
    end;
  end;;
  if (AProcessed > ALastProcessed) and Assigned(AOnProgress) then
    AOnProgress(ATotal, ATotal);
end;

procedure DecrypAESStreamCBC(Source: TStream; const Key: TQAESKey128;
  const InitVector: TQAESBuffer; Dest: TStream; APaddingMode: TQAESPaddingMode;
  AOnProgress: TQAESProgress); overload;
var
  ExpandedKey: TQAESExpandedKey128;
begin
  ExpandAESKeyForDecryption(Key, ExpandedKey);
  DecrypAESStreamCBC(Source, ExpandedKey, InitVector, Dest, APaddingMode,
    AOnProgress);
end;

procedure DecrypAESStreamCBC(Source: TStream; const Key: TQAESKey192;
  const InitVector: TQAESBuffer; Dest: TStream; APaddingMode: TQAESPaddingMode;
  AOnProgress: TQAESProgress); overload;
var
  ExpandedKey: TQAESExpandedKey192;
begin
  ExpandAESKeyForDecryption(Key, ExpandedKey);
  DecrypAESStreamCBC(Source, ExpandedKey, InitVector, Dest, APaddingMode,
    AOnProgress);
end;

procedure DecrypAESStreamCBC(Source: TStream; const Key: TQAESKey256;
  const InitVector: TQAESBuffer; Dest: TStream; APaddingMode: TQAESPaddingMode;
  AOnProgress: TQAESProgress); overload;
var
  ExpandedKey: TQAESExpandedKey256;
begin
  ExpandAESKeyForDecryption(Key, ExpandedKey);
  DecrypAESStreamCBC(Source, ExpandedKey, InitVector, Dest, APaddingMode,
    AOnProgress);
end;

procedure KeyFromBytes(const AKey: Pointer; const L: Integer;
  AKeyType: TQAESKeyType; var AResult: TQAESKey); overload;
begin
  AResult.KeyType := AKeyType;
  case AKeyType of
    kt128:
      begin
        if L > SizeOf(TQAESKey128) then
          Move(AKey^, AResult.Key128, SizeOf(TQAESKey128))
        else
        begin
          Move(AKey^, AResult.Key128, L);
          FillChar(AResult.Key128[L], SizeOf(TQAESKey128) - L, 0);
        end;
      end;
    kt192:
      begin
        if L > SizeOf(TQAESKey192) then
          Move(AKey^, AResult.Key192, SizeOf(TQAESKey192))
        else
        begin
          Move(AKey^, AResult.Key192, L);
          FillChar(AResult.Key192[L], SizeOf(TQAESKey192) - L, 0);
        end;
      end;
    kt256:
      begin
        if L > SizeOf(TQAESKey256) then
          Move(AKey^, AResult.Key256, SizeOf(TQAESKey256))
        else
        begin
          Move(AKey^, AResult.Key256, L);
          FillChar(AResult.Key256[L], SizeOf(TQAESKey256) - L, 0);
        end;
      end;
  end;
end;

function KeyFromBytes(const ABytes: TBytes; AKeyType: TQAESKeyType)
  : TQAESKey; overload;
begin
  KeyFromBytes(@ABytes[0], Length(ABytes), AKeyType, Result);
end;

function KeyFromString(const S: QStringW; AKeyType: TQAESKeyType)
  : TQAESKey; overload;
var
  U: QStringA;
begin
  U := qstring.Utf8Encode(S);
  KeyFromBytes(PQCharA(U), U.Length, AKeyType, Result);
end;

procedure AESEncrypt(ASource, ADest: TStream; AInitVector: TQAESBuffer;
  const AKey: TQAESKey; AMode: TQAESEncryptMode = emCBC;
  APaddingMode: TQAESPaddingMode = pmPKCS5;
  AOnProgress: TQAESProgress = nil); overload;
begin
  case AKey.KeyType of
    kt128:
      begin
        if AMode = emECB then
          EncryptAESStreamECB(ASource, AKey.Key128, ADest, APaddingMode,
            AOnProgress)
        else
          EncryptAESStreamCBC(ASource, AKey.Key128, AInitVector, ADest,
            APaddingMode, AOnProgress);
      end;
    kt192:
      begin
        if AMode = emECB then
          EncryptAESStreamECB(ASource, AKey.Key192, ADest, APaddingMode,
            AOnProgress)
        else
          EncryptAESStreamCBC(ASource, AKey.Key192, AInitVector, ADest,
            APaddingMode, AOnProgress);
      end;
    kt256:
      begin
        if AMode = emECB then
          EncryptAESStreamECB(ASource, AKey.Key256, ADest, APaddingMode,
            AOnProgress)
        else
          EncryptAESStreamCBC(ASource, AKey.Key256, AInitVector, ADest,
            APaddingMode, AOnProgress);
      end;
  end;
end;

procedure AESEncrypt(ASource, ADest: TStream; AInitVector: TQAESBuffer;
  const AKey: QStringW; AKeyType: TQAESKeyType; AMode: TQAESEncryptMode;
  AKeyIsString: Boolean; APaddingMode: TQAESPaddingMode;
  AOnProgress: TQAESProgress);
var
  AESKey: TQAESKey;
begin
  if AKeyIsString then
    AESKey := KeyFromString(AKey, AKeyType)
  else
    KeyFromBytes(PQCharW(AKey), Length(AKey) shl 1, AKeyType, AESKey);
  case AKeyType of
    kt128:
      begin
        if AMode = emECB then
          EncryptAESStreamECB(ASource, AESKey.Key128, ADest, APaddingMode,
            AOnProgress)
        else
          EncryptAESStreamCBC(ASource, AESKey.Key128, AInitVector, ADest,
            APaddingMode, AOnProgress);
      end;
    kt192:
      begin
        if AMode = emECB then
          EncryptAESStreamECB(ASource, AESKey.Key192, ADest, APaddingMode,
            AOnProgress)
        else
          EncryptAESStreamCBC(ASource, AESKey.Key192, AInitVector, ADest,
            APaddingMode, AOnProgress);
      end;
    kt256:
      begin
        if AMode = emECB then
          EncryptAESStreamECB(ASource, AESKey.Key256, ADest, APaddingMode,
            AOnProgress)
        else
          EncryptAESStreamCBC(ASource, AESKey.Key256, AInitVector, ADest,
            APaddingMode, AOnProgress);
      end;
  end;
end;

procedure AESEncrypt(const p: Pointer; len: Integer; AInitVector: TQAESBuffer;
  var AResult: TBytes; const AKey: QStringW; AKeyType: TQAESKeyType;
  AMode: TQAESEncryptMode; AKeyIsString: Boolean;
  APaddingMode: TQAESPaddingMode; AOnProgress: TQAESProgress); overload;
var
  pIn, pOut: PQAESBuffer;
  ABuf: TQAESBuffer;
  // 用来处理最后不足16字节的内容
  AKeyData: TQAESKey;
  AExpendedKey: TQAESExpandedKey;
  procedure Encrypt128EBC;
  begin
    ExpandAESKeyForEncryption(AKeyData.Key128, AExpendedKey.Key128);
    while len > SizeOf(TQAESBuffer) do
    begin
      EncryptAES(pIn^, AExpendedKey.Key128, pOut^);
      Dec(len, SizeOf(TQAESBuffer));
      Inc(pIn);
      Inc(pOut);
    end;
    if len <> 0 then
    begin
      Move(pIn^, ABuf[0], len);
      FillPaddings(ABuf, len, APaddingMode);
      EncryptAES(ABuf, AExpendedKey.Key128, pOut^);
    end;
  end;

  procedure Encrypt192EBC;
  begin
    ExpandAESKeyForEncryption(AKeyData.Key192, AExpendedKey.Key192);
    while len > SizeOf(TQAESBuffer) do
    begin
      EncryptAES(pIn^, AExpendedKey.Key192, pOut^);
      Dec(len, SizeOf(TQAESBuffer));
      Inc(pIn);
      Inc(pOut);
    end;
    if len <> 0 then
    begin
      Move(pIn^, ABuf[0], len);
      FillPaddings(ABuf, len, APaddingMode);
      EncryptAES(ABuf, AExpendedKey.Key192, pOut^);
    end;
  end;

  procedure Encrypt256EBC;
  begin
    ExpandAESKeyForEncryption(AKeyData.Key256, AExpendedKey.Key256);
    while len > SizeOf(TQAESBuffer) do
    begin
      EncryptAES(pIn^, AExpendedKey.Key256, pOut^);
      Dec(len, SizeOf(TQAESBuffer));
      Inc(pIn);
      Inc(pOut);
    end;
    if len <> 0 then
    begin
      Move(pIn^, ABuf[0], len);
      FillPaddings(ABuf, len, APaddingMode);
      EncryptAES(ABuf, AExpendedKey.Key256, pOut^);
    end;
  end;

  procedure XorVector;
  begin
    PInt64(@ABuf[0])^ := PInt64(@ABuf[0])^ xor PInt64(@AInitVector[0])^;
    PInt64(@ABuf[8])^ := PInt64(@ABuf[8])^ xor PInt64(@AInitVector[8])^;
  end;

  procedure Encrypt128CBC;
  begin
    ExpandAESKeyForEncryption(AKeyData.Key128, AExpendedKey.Key128);
    while len > SizeOf(TQAESBuffer) do
    begin
      ABuf := pIn^;
      XorVector;
      EncryptAES(ABuf, AExpendedKey.Key128, pOut^);
      Dec(len, SizeOf(TQAESBuffer));
      AInitVector := pOut^;
      Inc(pIn);
      Inc(pOut);
    end;
    if len <> 0 then
    begin
      Move(pIn^, ABuf[0], len);
      FillPaddings(ABuf, len, APaddingMode);
      XorVector;
      EncryptAES(ABuf, AExpendedKey.Key128, pOut^);
    end;
  end;

  procedure Encrypt192CBC;
  begin
    ExpandAESKeyForEncryption(AKeyData.Key192, AExpendedKey.Key192);
    while len > SizeOf(TQAESBuffer) do
    begin
      ABuf := pIn^;
      XorVector;
      EncryptAES(ABuf, AExpendedKey.Key192, pOut^);
      Dec(len, SizeOf(TQAESBuffer));
      AInitVector := pOut^;
      Inc(pIn);
      Inc(pOut);
    end;
    if len <> 0 then
    begin
      Move(pIn^, ABuf[0], len);
      FillPaddings(ABuf, len, APaddingMode);
      XorVector;
      EncryptAES(ABuf, AExpendedKey.Key192, pOut^);
    end;
  end;

  procedure Encrypt256CBC;
  begin
    ExpandAESKeyForEncryption(AKeyData.Key256, AExpendedKey.Key256);
    while len > SizeOf(TQAESBuffer) do
    begin
      ABuf := pIn^;
      XorVector;
      EncryptAES(ABuf, AExpendedKey.Key256, pOut^);
      Dec(len, SizeOf(TQAESBuffer));
      AInitVector := pOut^;
      Inc(pIn);
      Inc(pOut);
    end;
    if len <> 0 then
    begin
      Move(pIn^, ABuf[0], len);
      FillPaddings(ABuf, len, APaddingMode);
      XorVector;
      EncryptAES(ABuf, AExpendedKey.Key256, pOut^);
    end;
  end;

begin
  if len <= 0 then
    exit;
  if AKeyIsString then
    AKeyData := KeyFromString(AKey, AKeyType)
  else
    KeyFromBytes(PQCharW(AKey), Length(AKey) shl 1, AKeyType, AKeyData);
  pIn := p;
  if (len and $F) <> 0 then
    SetLength(AResult, ((len shr 4) + 1) shl 4)
  else
    SetLength(AResult, len);
  pOut := @AResult[0];
  if AMode = emECB then
  begin
    case AKeyType of
      kt128:
        Encrypt128EBC;
      kt192:
        Encrypt192EBC;
      kt256:
        Encrypt256EBC;
    end;
  end
  else // CBC
  begin
    case AKeyType of
      kt128:
        Encrypt128CBC;
      kt192:
        Encrypt192CBC;
      kt256:
        Encrypt256CBC;
    end;
  end;
end;

procedure AESEncrypt(const AData: TBytes; AInitVector: TQAESBuffer;
  var AResult: TBytes; const AKey: QStringW; AKeyType: TQAESKeyType;
  AMode: TQAESEncryptMode; AKeyIsString: Boolean;
  APaddingMode: TQAESPaddingMode; AOnProgress: TQAESProgress);
begin
  AESEncrypt(@AData[0], Length(AData), AInitVector, AResult, AKey, AKeyType,
    AMode, AKeyIsString, APaddingMode, AOnProgress);
end;

procedure AESEncrypt(const AData: QStringW; AInitVector: TQAESBuffer;
  var AResult: TBytes; const AKey: QStringW; AKeyType: TQAESKeyType;
  AMode: TQAESEncryptMode; AKeyIsString: Boolean;
  APaddingMode: TQAESPaddingMode; AOnProgress: TQAESProgress);
var
  ATemp: QStringA;
begin
  ATemp := qstring.Utf8Encode(AData);
  AESEncrypt(PQCharA(ATemp), ATemp.Length, AInitVector, AResult, AKey, AKeyType,
    AMode, AKeyIsString, APaddingMode, AOnProgress);
end;

procedure AESEncrypt(const ASourceFile, ADestFile: QStringW;
  AInitVector: TQAESBuffer; const AKey: QStringW; AKeyType: TQAESKeyType;
  AMode: TQAESEncryptMode; AKeyIsString: Boolean;
  APaddingMode: TQAESPaddingMode; AOnProgress: TQAESProgress);
var
  ASourceStream, ADestStream: TFileStream;
begin
  ASourceStream := nil;
  ADestStream := nil;
  try
    ASourceStream := TFileStream.Create(ASourceFile, fmOpenRead or
      fmShareDenyWrite);
    ADestStream := TFileStream.Create(ADestFile, fmCreate);
    AESEncrypt(ASourceStream, ADestStream, AInitVector, AKey, AKeyType, AMode,
      AKeyIsString, APaddingMode, AOnProgress);
  finally
    if ASourceStream <> nil then
      FreeObject(ASourceStream);
    if ADestStream <> nil then
      FreeObject(ADestStream);
  end;
end;

procedure AESDecrypt(ASource, ADest: TStream; AInitVector: TQAESBuffer;
  const AKey: QStringW; AKeyType: TQAESKeyType; AMode: TQAESEncryptMode;
  AKeyIsString: Boolean; APaddingMode: TQAESPaddingMode;
  AOnProgress: TQAESProgress);
var
  AESKey: TQAESKey;
begin
  if AKeyIsString then
    AESKey := KeyFromString(AKey, AKeyType)
  else
    KeyFromBytes(PQCharW(AKey), Length(AKey) shl 1, AKeyType, AESKey);
  case AKeyType of
    kt128:
      begin
        if AMode = emECB then
          DecrypAESStreamECB(ASource, AESKey.Key128, ADest, APaddingMode,
            AOnProgress)
        else
          DecrypAESStreamCBC(ASource, AESKey.Key128, AInitVector, ADest,
            APaddingMode, AOnProgress);
      end;
    kt192:
      begin
        if AMode = emECB then
          DecrypAESStreamECB(ASource, AESKey.Key192, ADest, APaddingMode,
            AOnProgress)
        else
          DecrypAESStreamCBC(ASource, AESKey.Key192, AInitVector, ADest,
            APaddingMode, AOnProgress);
      end;
    kt256:
      begin
        if AMode = emECB then
          DecrypAESStreamECB(ASource, AESKey.Key256, ADest, APaddingMode,
            AOnProgress)
        else
          DecrypAESStreamCBC(ASource, AESKey.Key256, AInitVector, ADest,
            APaddingMode, AOnProgress);
      end;
  end;

end;

procedure AESDecrypt(const p: Pointer; len: Integer; AInitVector: TQAESBuffer;
  var AResult: TBytes; const AKey: TQAESKey; AMode: TQAESEncryptMode;
  APaddingMode: TQAESPaddingMode); overload;
var
  pIn, pOut: PQAESBuffer;
  AExpendedKey: TQAESExpandedKey;

  procedure Decrypt128EBC;
  begin
    ExpandAESKeyForEncryption(AKey.Key128, AExpendedKey.Key128);
    ExpandAESKeyForDecryption(AExpendedKey.Key128);
    while len > 0 do
    begin
      DecrypAES(pIn^, AExpendedKey.Key128, pOut^);
      Dec(len, SizeOf(TQAESBuffer));
      Inc(pIn);
      Inc(pOut);
    end;
  end;

  procedure Decrypt192EBC;
  begin
    ExpandAESKeyForEncryption(AKey.Key192, AExpendedKey.Key192);
    ExpandAESKeyForDecryption(AExpendedKey.Key192);
    while len > 0 do
    begin
      DecrypAES(pIn^, AExpendedKey.Key192, pOut^);
      Dec(len, SizeOf(TQAESBuffer));
      Inc(pIn);
      Inc(pOut);
    end;
  end;

  procedure Decrypt256EBC;
  begin
    ExpandAESKeyForEncryption(AKey.Key256, AExpendedKey.Key256);
    ExpandAESKeyForDecryption(AExpendedKey.Key256);
    while len > 0 do
    begin
      DecrypAES(pIn^, AExpendedKey.Key256, pOut^);
      Dec(len, SizeOf(TQAESBuffer));
      Inc(pIn);
      Inc(pOut);
    end;
  end;

  procedure XorVector;
  begin
    PInt64(IntPtr(pOut))^ := PInt64(IntPtr(pOut))^ xor PInt64(@AInitVector[0])^;
    PInt64(IntPtr(pOut) + 8)^ := PInt64(IntPtr(pOut) + 8)
      ^ xor PInt64(@AInitVector[8])^;
  end;

  procedure Decrypt128CBC;
  begin
    ExpandAESKeyForEncryption(AKey.Key128, AExpendedKey.Key128);
    ExpandAESKeyForDecryption(AExpendedKey.Key128);
    while len > 0 do
    begin
      DecrypAES(pIn^, AExpendedKey.Key128, pOut^);
      XorVector;
      AInitVector := pIn^;
      Dec(len, SizeOf(TQAESBuffer));
      Inc(pIn);
      Inc(pOut);
    end;
  end;

  procedure Decrypt192CBC;
  begin
    ExpandAESKeyForEncryption(AKey.Key192, AExpendedKey.Key192);
    ExpandAESKeyForDecryption(AExpendedKey.Key192);
    while len > 0 do
    begin
      DecrypAES(pIn^, AExpendedKey.Key192, pOut^);
      XorVector;
      AInitVector := pIn^;
      Dec(len, SizeOf(TQAESBuffer));
      Inc(pIn);
      Inc(pOut);
    end;
  end;

  procedure Decrypt256CBC;
  begin
    ExpandAESKeyForEncryption(AKey.Key256, AExpendedKey.Key256);
    ExpandAESKeyForDecryption(AExpendedKey.Key256);
    while len > 0 do
    begin
      DecrypAES(pIn^, AExpendedKey.Key256, pOut^);
      XorVector;
      AInitVector := pIn^;
      Dec(len, SizeOf(TQAESBuffer));
      Inc(pIn);
      Inc(pOut);
    end;
  end;
  procedure RemovePaddings;
  var
    B: byte;
    L: Integer;
  begin
    if APaddingMode in [pmPKCS5, pmPKCS7] then
    begin
      L := Length(AResult);
      if L > 0 then
      begin
        B := AResult[L - 1];
        if L > B then
          SetLength(AResult, L - B);
      end;
    end;
  end;

begin
  if len <= 0 then
    exit;
  pIn := p;
  if (len and $F) <> 0 then
    SetLength(AResult, ((len shr 4) + 1) shl 4)
  else
    SetLength(AResult, len);
  pOut := @AResult[0];
  if AMode = emECB then
  begin
    case AKey.KeyType of
      kt128:
        Decrypt128EBC;
      kt192:
        Decrypt192EBC;
      kt256:
        Decrypt256EBC;
    end;
  end
  else // CBC
  begin
    case AKey.KeyType of
      kt128:
        Decrypt128CBC;
      kt192:
        Decrypt192CBC;
      kt256:
        Decrypt256CBC;
    end;
  end;
  RemovePaddings;
end;

procedure AESDecrypt(const AData: TBytes; AInitVector: TQAESBuffer;
  var AResult: TBytes; const AKey: TQAESKey; AMode: TQAESEncryptMode;
  APaddingMode: TQAESPaddingMode); overload;
begin
  if Length(AData) > 0 then
    AESDecrypt(@AData[0], Length(AData), AInitVector, AResult, AKey, AMode,
      APaddingMode)
  else
    SetLength(AResult, 0);
end;

procedure AESDecrypt(const AData: TBytes; AInitVector: TQAESBuffer;
  var AResult: TBytes; const AKey: QStringW; AKeyType: TQAESKeyType;
  AMode: TQAESEncryptMode; AKeyIsString: Boolean;
  APaddingMode: TQAESPaddingMode); overload;
var
  AKeyData: TQAESKey;
begin
  if Length(AData) > 0 then
  begin
    if AKeyIsString then
      AKeyData := KeyFromString(AKey, AKeyType)
    else
      KeyFromBytes(PQCharW(AKey), Length(AKey) shl 1, AKeyType, AKeyData);
    AESDecrypt(@AData[0], Length(AData), AInitVector, AResult, AKeyData, AMode,
      APaddingMode)
  end
  else
    SetLength(AResult, 0);
end;

function AESDecrypt(const AData: TBytes; AInitVector: TQAESBuffer;
  const AKey: QStringW; AKeyType: TQAESKeyType; AMode: TQAESEncryptMode;
  ATrimZero: Boolean; AKeyIsString: Boolean; APaddingMode: TQAESPaddingMode;
  AOnProgress: TQAESProgress): String; overload;
var
  AResult: TBytes;
  L: Integer;
  ABOM: Boolean;
  AEncoding: TTextEncoding;
begin
  AESDecrypt(AData, AInitVector, AResult, AKey, AKeyType, AMode, AKeyIsString,
    APaddingMode);
  L := Length(AResult);
  SetLength(Result, 0);
  if APaddingMode = pmZero then
  begin
    if L >= SizeOf(TQAESBuffer) then // 最少也是一个数据块的大小
    begin
      if ATrimZero then
      begin
        while (AResult[L - 1] = 0) and (AResult[L - 2] = 0) do
          Dec(L, 2);
      end;
    end;
  end;
  if L > 1 then
  begin
    if AResult[L - 1] = 0 then
      AEncoding := DetectTextEncoding(@AResult[0], L - 1, ABOM)
    else
      AEncoding := DetectTextEncoding(@AResult[0], L, ABOM);
    case AEncoding of
      teAnsi:
        begin
          if AResult[L - 1] = 0 then
            Dec(L);
          Result := qstring.AnsiDecode(PQCharA(@AResult[0]), L);
        end;
      teUnicode16LE:
        if ABOM then
          Result := qstring.StrDupX(PQCharW(@AResult[1]), (L shr 1) - 1)
        else
          Result := qstring.StrDupX(PQCharW(@AResult[0]), L shr 1);
      teUnicode16BE:
        begin
          if ABOM then
            Result := qstring.StrDupX(PQCharW(@AResult[0]), (L shr 1) - 1)
          else
            Result := qstring.StrDupX(PQCharW(@AResult[0]), L shr 1);
          { Unicode BE 编码 }
          ExchangeByteOrder(PQCharA(Result), Length(Result) shl 1);
        end;
      teUTF8:
        { UTF8编码 }
        begin
          if AResult[L - 1] = 0 then
            Dec(L);
          if ABOM then
            Result := qstring.Utf8Decode(PQCharA(@AResult[3]), L)
          else
            Result := qstring.Utf8Decode(PQCharA(@AResult[0]), L);
        end;
    end;
  end
end;

procedure AESDecrypt(const ASourceFile, ADestFile: QStringW;
  AInitVector: TQAESBuffer; const AKey: QStringW; AKeyType: TQAESKeyType;
  AMode: TQAESEncryptMode; AKeyIsString: Boolean;
  APaddingMode: TQAESPaddingMode; AOnProgress: TQAESProgress);
var
  ASourceStream, ADestStream: TFileStream;
begin
  ASourceStream := nil;
  ADestStream := nil;
  try
    ASourceStream := TFileStream.Create(ASourceFile, fmOpenRead or
      fmShareDenyWrite);
    ADestStream := TFileStream.Create(ADestFile, fmCreate);
    AESDecrypt(ASourceStream, ADestStream, AInitVector, AKey, AKeyType, AMode,
      AKeyIsString, APaddingMode);
  finally
    if ASourceStream <> nil then
      FreeObject(ASourceStream);
    if ADestStream <> nil then
      FreeObject(ADestStream);
  end;
end;

function AESEncryptSize(ASize: Int64): Int64;
begin
  if (ASize and $F) <> 0 then
    Result := ((ASize shr 4) + 1) shl 4
  else
    Result := ASize;
end;

{ 使用CBC加密
  <param name="AInitVector">初始向量</param>
  <param name="AKey">密钥</param>
  <param name="AKeyType">密钥强度类型</param>

  <returns>
  返回当前记录的地址，以便串联调用。
  </returns> }

function TQAES.AsCBC(AInitVector: TQAESBuffer; const AKey: QStringW;
  AKeyType: TQAESKeyType): PQAES;
begin
  FKeyIsString := true;
  FKey := AKey;
  FMode := emCBC;
  FKeyType := AKeyType;
  FInitVector := AInitVector;
  FPaddingMode := pmPKCS5;
  FOnProgress := nil;
  Result := @Self;
end;

function TQAES.AsECB(const AKey: QStringW; AKeyType: TQAESKeyType): PQAES;
begin
  FKeyIsString := true;
  FKey := AKey;
  FMode := emECB;
  FKeyType := AKeyType;
  FInitVector := AESEmptyBuffer;
  FPaddingMode := pmPKCS5;
  FOnProgress := nil;
  Result := @Self;
end;

procedure TQAES.Decrypt(ASource, ADest: TStream);
begin
  AESDecrypt(ASource, ADest, FInitVector, FKey, FKeyType, FMode);
end;

function TQAES.AsCBC(AInitVector: TQAESBuffer; const AKey: TBytes;
  AKeyType: TQAESKeyType): PQAES;
var
  L: Integer;
begin
  FKeyIsString := False;
  L := Length(AKey);
  if L > 0 then
  begin
    if (L mod 2) = 1 then
      Inc(L);
    SetLength(FKey, L shr 1);
    Move(AKey[0], PQCharW(FKey)^, L);
  end
  else
    SetLength(FKey, 0);
  FMode := emCBC;
  FInitVector := AInitVector;
  FOnProgress := nil;
  FKeyType := AKeyType;
  FPaddingMode := pmPKCS5;
  Result := @Self;
end;

function TQAES.AsECB(const AKey: TBytes; AKeyType: TQAESKeyType): PQAES;
var
  L: Integer;
begin
  FKeyIsString := False;
  FMode := emECB;
  L := Length(AKey);
  if L > 0 then
  begin
    if (L mod 2) = 1 then
      Inc(L);
    SetLength(FKey, L shr 1);
    Move(AKey[0], PQCharW(FKey)^, L);
  end
  else
    SetLength(FKey, 0);
  FInitVector := AESEmptyBuffer;
  FOnProgress := nil;
  FPaddingMode := pmPKCS5;
  FKeyType := AKeyType;
  Result := @Self;
end;

procedure TQAES.Decrypt(const ASourceFile, ADestFile: QStringW);
begin
  AESDecrypt(ASourceFile, ADestFile, FInitVector, FKey, FKeyType, FMode,
    FKeyIsString);
end;

procedure TQAES.Decrypt(const AData: PByte; ALen: Integer; var AResult: TBytes);
var
  AKeyData: TQAESKey;
begin
  if ALen > 0 then
  begin
    if FKeyIsString then
      AKeyData := KeyFromString(FKey, FKeyType)
    else
      KeyFromBytes(PQCharW(FKey), Length(FKey) shl 1, FKeyType, AKeyData);
    AESDecrypt(AData, ALen, FInitVector, AResult, AKeyData, FMode, PaddingMode);
  end
  else
    SetLength(AResult, 0);
end;

function TQAES.Decrypt(const S: String; AHexBeforeBase64: Boolean): String;
var
  ABytes: TBytes;
begin
  if Length(S) > 0 then
  begin
    ABytes := DecodeBase64(S);
    if AHexBeforeBase64 then
      ABytes := HexToBin(AnsiDecode(PQCharA(ABytes), Length(ABytes)));
    if Length(ABytes) <> 0 then
      Result := Decrypt(ABytes)
    else
      Result := '';
  end
  else
    Result := '';
end;

function TQAES.Decrypt(const AData: TBytes): String;
begin
  Result := AESDecrypt(AData, FInitVector, FKey, FKeyType, FMode, true,
    FKeyIsString, PaddingMode);
end;

procedure TQAES.Decrypt(const AData: TBytes; var AResult: TBytes);
begin
  AESDecrypt(AData, FInitVector, AResult, FKey, FKeyType, FMode, FKeyIsString,
    PaddingMode);
end;

procedure TQAES.Encrypt(ASource, ADest: TStream);
begin
  AESEncrypt(ASource, ADest, FInitVector, FKey, FKeyType, FMode, FKeyIsString,
    PaddingMode, FOnProgress);
end;

procedure TQAES.Encrypt(const p: Pointer; len: Integer; var AResult: TBytes);
begin
  AESEncrypt(p, len, FInitVector, AResult, FKey, FKeyType, FMode, FKeyIsString,
    PaddingMode, FOnProgress);
end;

procedure TQAES.Encrypt(const ASourceFile, ADestFile: QStringW);
begin
  AESEncrypt(ASourceFile, ADestFile, FInitVector, FKey, FKeyType, FMode,
    FKeyIsString, PaddingMode, FOnProgress);
end;

procedure TQAES.SetProgressCallback(ACallback: TQAESProgress);
begin
  FOnProgress := ACallback;
end;

function TQAES.Encrypt(const AData: QStringW; AHexBeforeBase64: Boolean)
  : QStringW;
var
  AResult: TBytes;
begin
  Encrypt(AData, AResult);
  if AHexBeforeBase64 then
    Result := EncodeString(BinToHex(AResult))
  else
    Result := EncodeBase64(@AResult[0], Length(AResult));
end;

procedure TQAES.Encrypt(const AData: QStringW; var AResult: TBytes);
begin
  AESEncrypt(AData, FInitVector, AResult, FKey, FKeyType, FMode, FKeyIsString,
    PaddingMode);
end;

procedure TQAES.Encrypt(const AData: TBytes; var AResult: TBytes);
begin
  AESEncrypt(AData, FInitVector, AResult, FKey, FKeyType, FMode, FKeyIsString,
    PaddingMode);
end;

initialization

end.
