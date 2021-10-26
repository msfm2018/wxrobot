unit qsp_aes;

interface

uses classes, sysutils, qaes, qstring, qdb;

type
{$IF RTLVersion>=23}
  [ComponentPlatformsAttribute(pidWin32 or pidWin64{$IF RTLVersion>=24} or
    pidOSX32{$IFEND}{$IF RTLVersion>=25} or pidiOSSimulator or
    pidiOSDevice{$IFEND}{$IF RTLVersion>=26} or
    pidAndroid{$IFEND}{$IF RTLVersion>=29} or pidiOSDevice32 or
    pidiOSDevice64{$IFEND})]
{$IFEND}

  TQAESStreamProcessor = class(TQStreamProcessor)
  protected
    FKeyType: TQAESKeyType;
    FEncryptMode: TQAESEncryptMode;
    FInitVector: TQAESBuffer;
    FPassword: QStringW;
    function GetInitVector: QStringW;
    procedure SetInitVector(const Value: QStringW);
    procedure SetPassword(const Value: QStringW);
    procedure BeforeSave(ASourceStream: TStream;
      ATargetStream: TStream); override;
    procedure BeforeLoad(ASourceStream: TStream;
      ATargetStream: TStream); override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property KeyType: TQAESKeyType read FKeyType write FKeyType;
    property EncryptMode: TQAESEncryptMode read FEncryptMode write FEncryptMode;
    property Password: QStringW read FPassword write SetPassword;
    property InitVector: QStringW read GetInitVector write SetInitVector;
  end;

implementation

resourcestring
  SAESTooLong = '%s 使用UTF8编码后的长度过长。';
  { TQAESStreamProcssor }

procedure TQAESStreamProcessor.BeforeLoad(ASourceStream, ATargetStream
  : TStream);
begin
  AESDecrypt(ASourceStream, ATargetStream, FInitVector, FPassword, FKeyType,
    FEncryptMode);
end;

procedure TQAESStreamProcessor.BeforeSave(ASourceStream, ATargetStream
  : TStream);
begin
  AESEncrypt(ASourceStream, ATargetStream, FInitVector, FPassword, FKeyType,
    FEncryptMode);
end;

constructor TQAESStreamProcessor.Create(AOwner: TComponent);
begin
  inherited;
  FKeyType := kt256;
end;

function TQAESStreamProcessor.GetInitVector: QStringW;
begin
  Result := qstring.Utf8Decode(@FInitVector[0], 16);
end;

procedure TQAESStreamProcessor.SetInitVector(const Value: QStringW);
var
  ABytes: QStringA;
begin
  ABytes := qstring.Utf8Encode(Value);
  if ABytes.Length <= 16 then
  begin
    Move(ABytes.Data^, FInitVector[0], ABytes.Length);
    if ABytes.Length < 16 then
      FillChar(FInitVector[ABytes.Length], 16 - ABytes.Length, 0);
  end
  else
    raise Exception.CreateFmt(SAESTooLong, [Value]);
end;

procedure TQAESStreamProcessor.SetPassword(const Value: QStringW);
begin
  if FPassword <> Value then
  begin
    FPassword := Value;
  end;
end;

end.
