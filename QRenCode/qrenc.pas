{*******************************************************************************

 * qrencode - QR Code encoder
 *
 * QR Code encoding tool
 * This code is taken from Kentaro Fukuchi's qrenc.c
 * then editted and packed into a .pas file.
 * Copyright (C) 2006-2011 Kentaro Fukuchi <kentaro@fukuchi.org>
 *
 * Copyright (C) 2014 Hao Shi <admin@hicpp.com> 
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA
                                                               
    revision history
      2014-04-14  update from qrencode-3.4.3

*******************************************************************************}

unit qrenc;

interface

uses
  Windows, SysUtils, struct, Graphics;

procedure qr(const AStr, AOut: AnsiString; AMargin, ASize, AEightBit,
  ACasesens, AStructured, ALevel, ACode: Integer; AFore, ABack: TColor);

implementation

uses
  qrencode;

type
  imageType = (
    BMP_TYPE
  );

var
  casesensitive: Integer = 1;
  eightbit: Integer = 0;
  version: Integer = 0;
  size: Integer = 3;
  margin: Integer = -1;
  dpi: Integer = 72;
  structured: Integer = 0;
  rle: Integer = 0;
  micro: Integer = 0;
  level: QRecLevel = QR_ECLEVEL_L;
  hint: QRencodeMode = QR_MODE_8;
  fg_color: array[0..3] of Byte = (0, 0, 0, 255);
  bg_color: array[0..3] of Byte = (255, 255, 255, 255);

  image_type: imageType = BMP_TYPE;

function writeBMP(qrcode: PQRcode; const outfile: PAnsiChar): Integer;
var
  bmp: TBitmap;
  realwidth, x, xx, y, yy: Integer;
  p: PByte;
  pix, pixNew: PRGBTriple;
begin
  realwidth := (qrcode.width + margin * 2) * size;
  bmp := TBitmap.Create;
  try
    bmp.PixelFormat := pf24bit;
    bmp.Width := realwidth;
    bmp.Height := realwidth;
    //设置背景色（整个图片全部设置成背景色，然后设置需要改变的像素为前景色）开始，
    //设置第一行的颜色
    pix := bmp.ScanLine[0];
    for x := 0 to realwidth - 1 do
    begin
      pix^.rgbtRed := bg_color[0];
      pix^.rgbtGreen := bg_color[1];
      pix^.rgbtBlue := bg_color[2];
      Inc(pix);
    end;
    //后面行的数据复制第一行
    pix := bmp.ScanLine[0];
    for y := 1 to realwidth - 1 do
    begin
      pixNew := bmp.ScanLine[y];
      CopyMemory(pixNew, pix, SizeOf(TRGBTriple) * realwidth);
    end;
    //设置背景色结束

    //设置需要改变的像素为前景色
    for y := 0 to qrcode.width - 1 do
    begin
      p := PIndex(qrcode.data, y * qrcode.width);   //当前需要测试的数据
      pix := bmp.ScanLine[(y + margin) * size];     //当前需要改变颜色的像素
      Inc(pix, margin * size);                      //跳过每行的margin
      for x := 0 to qrcode.width - 1 do
      begin
        if (p^ and 1) <> 0 then   //需要改变的像素
        begin
          for xx := 0 to size - 1 do  //重复size大小的前景色
          begin
            pix^.rgbtRed := fg_color[0];
            pix^.rgbtGreen := fg_color[1];
            pix^.rgbtBlue := fg_color[2];
            Inc(pix);              
          end;
        end else  //跳过不需要改变的像素
          Inc(pix, size);
        Inc(p);
      end;
      //总共size行，其它行的数据复制当前行
      pix := bmp.ScanLine[(y + margin) * size];
      for yy := 1 to size - 1 do
      begin
        pixNew := bmp.ScanLine[(y + margin) * size + yy];
        CopyMemory(pixNew, pix, SizeOf(TRGBTriple) * realwidth);
      end;
    end;

    bmp.SaveToFile(string(StrPas(outfile)));
    Result := 0;
  finally
    FreeAndNil(bmp);
  end;
end;

function encode(const intext: PByte; length: Integer): PQRcode;
var
  code: PQRcode;
begin
	if micro <> 0 then
  begin
		if eightbit <> 0 then
    begin
			code := QRcode_encodeDataMQR(length, intext, version, level);
		end else begin
			code := QRcode_encodeStringMQR(PAnsiChar(intext), version, level, hint,
        casesensitive);
		end;
	end else begin
		if eightbit <> 0 then
    begin
			code := QRcode_encodeData(length, intext, version, level);
		end else begin
			code := QRcode_encodeString(PAnsiChar(intext), version, level, hint,
        casesensitive);
		end;
	end;

	Result := code;
end;

procedure qrcode(const intext: PByte; length: Integer; const outfile: PAnsiChar);
var
  qrcode: PQRcode;
begin
	qrcode := encode(intext, length);
	if qrcode = nil then
  begin
		Abort;
	end;
  try
    case (image_type) of
      BMP_TYPE: writeBMP(qrcode, outfile);
      else begin
        QRcode_free(qrcode);
        Abort;
      end;
    end;
  finally
  	QRcode_free(qrcode);
  end;
end;

function encodeStructured(const intext: PByte; length: Integer): PQRcode_List;
var
  list: PQRcode_List;
begin
	if eightbit <> 0 then
  begin
		list := QRcode_encodeDataStructured(length, intext, version, level);
	end else begin
		list := QRcode_encodeStringStructured(PAnsiChar(intext), version, level,
      hint, casesensitive);
	end;

	Result := list;
end;

procedure qrencodeStructured(const intext: PByte; length: Integer;
  const outfile: PAnsiChar);
var
  qrlist, p: PQRcode_List;
  filename: PAnsiChar;
  base, q, suffix: PAnsiChar;
  type_suffix: PAnsiChar;
  i: Integer;
  suffix_size: Integer;
begin
  suffix := nil;
  type_suffix := nil;
  i := 1;          
	case image_type of
    BMP_TYPE: type_suffix := '.bmp';
		else begin
			Abort;
    end;
	end;

	if outfile = nil then
  begin
		Abort;
	end;
	base := strdup(outfile);
	if base = nil then
  begin
		Abort;
	end;
	suffix_size := lstrlenA(type_suffix);
	if lstrlenA(base) > suffix_size then
  begin
		q := base + lstrlenA(base) - suffix_size;
		if lstrcmpiA(type_suffix, q) = 0 then
    begin
			suffix := strdup(q);
			q^ := #0;
		end;
	end;
	
	qrlist := encodeStructured(intext, length);
	if qrlist = nil then
  begin
		Abort;
	end;

  p := qrlist;
  try
    while p <> nil do
    begin
      if p.code = nil then
      begin
        Abort;
      end;
      if suffix <> nil then
      begin
        filename := PAnsiChar(AnsiString(Format('%s-%.2d%s', [base, i, suffix])));
      end else begin
        filename := PAnsiChar(AnsiString(Format('%s-%.2d', [base, i])));
      end;
      case image_type of
        BMP_TYPE: writeBMP(p.code, filename);
        else begin
          Abort;
        end;
      end;
      Inc(i);
      p := p.next;
    end;
  finally
    FreeMem(base);
    if suffix <> nil then
      FreeMem(suffix);  
  	QRcode_List_free(qrlist);
  end;
end;

procedure qrencode(const AStr: PByte; ALen: Integer; AOut: AnsiString; AMargin,
  ASize, AEightBit, ACasesens, AStructured, ALevel: Integer; AFore, ABack: TColor);
begin
  version := 1;
  margin := AMargin;
  size := ASize;
  eightbit := AEightBit;
  casesensitive := casesensitive;
  structured := AStructured;
  level := QRecLevel(ALevel);
  fg_color[0] := AFore and $FF;
  fg_color[1] := (AFore and $FF00) shr 8;
  fg_color[2] := (AFore and $FF0000) shr 16;
  bg_color[0] := ABack and $FF;
  bg_color[1] := (ABack and $FF00) shr 8;
  bg_color[2] := (ABack and $FF0000) shr 16;
  image_type := BMP_TYPE;

  if structured = 1 then
    qrencodeStructured(AStr, ALen, PAnsiChar(AOut))
  else
    qrcode(AStr, ALen, PAnsiChar(AOut));
end;

procedure qr(const AStr, AOut: AnsiString; AMargin, ASize, AEightBit,
  ACasesens, AStructured, ALevel, ACode: Integer; AFore, ABack: TColor);
var
  sutf8: UTF8String;
  pb: PByte;
  iLen: Integer;
begin
  if ACode = 0 then
  begin
    sutf8 := AnsiToUtf8(AStr);
    iLen := Length(sutf8);
    pb := PByte(PAnsiChar(sutf8));
  end else begin
    iLen := Length(AStr);
    pb := PByte(PAnsiChar(AStr));
  end;
  qrencode(pb, iLen, AOut, AMargin, ASize, AEightBit,
    ACasesens, AStructured, ALevel, AFore, ABack);
end;

end.
