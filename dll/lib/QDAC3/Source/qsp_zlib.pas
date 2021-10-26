unit qsp_zlib;

interface

{$I qdac.inc}

uses classes, sysutils, qstring, qdb, ZLib;

type
{$IFNDEF UNICODE}
  TZCompressionStream = TCompressionStream;
  TZDecompressionStream = TDecompressionStream;
  TZCompressionLevel = TCompressionLevel;
{$ENDIF}
{$IF RTLVersion>=23}
  [ComponentPlatformsAttribute(pidWin32 or pidWin64{$IF RTLVersion>=24} or
    pidOSX32{$IFEND}{$IF RTLVersion>=25} or pidiOSSimulator or
    pidiOSDevice{$IFEND}{$IF RTLVersion>=26} or
    pidAndroid{$IFEND}{$IF RTLVersion>=29} or pidiOSDevice32 or
    pidiOSDevice64{$IFEND})]
{$IFEND}

  TQZlibStreamProcessor = class(TQStreamProcessor)
  protected
    FCompressionLevel: TZCompressionLevel;
    procedure BeforeSave(ASourceStream: TStream;
      ATargetStream: TStream); override;
    procedure BeforeLoad(ASourceStream: TStream;
      ATargetStream: TStream); override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property CompressionLevel: TZCompressionLevel read FCompressionLevel
      write FCompressionLevel;
  end;

implementation

{ TQZlibStreamProcessor }

procedure TQZlibStreamProcessor.BeforeLoad(ASourceStream,
  ATargetStream: TStream);
var
  AStream: TZDecompressionStream;
begin
  inherited;
  AStream := TZDecompressionStream.Create(ASourceStream);
  try
    ATargetStream.CopyFrom(AStream, 0);
  finally
    FreeObject(AStream);
  end;
end;

procedure TQZlibStreamProcessor.BeforeSave(ASourceStream,
  ATargetStream: TStream);
var
  AStream: TZCompressionStream;
begin
  inherited;
{$IFDEF UNICODE}
  AStream := TZCompressionStream.Create(ATargetStream,
    CompressionLevel{$IF RTLVersion>=23}, 15{$IFEND});
{$ELSE}
    AStream := TZCompressionStream.Create(CompressionLevel, ATargetStream);
{$ENDIF}
  try
    AStream.CopyFrom(ASourceStream, 0);
  finally
    FreeObject(AStream);
  end;
end;

constructor TQZlibStreamProcessor.Create(AOwner: TComponent);
begin
  inherited;
  FCompressionLevel := {$IFDEF UNICODE} zcDefault{$ELSE}clDefault{$ENDIF};
end;

end.
