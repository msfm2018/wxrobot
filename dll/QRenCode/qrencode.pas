{*******************************************************************************

 * qrencode - QR Code encoder
 *
 * This code is taken from Kentaro Fukuchi's qrencode.h and
 * qrencode.c then editted and packed into a .pas file.
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

unit qrencode;

interface

uses
  Windows, SysUtils, struct;

{******************************************************************************
 * QRcode output (qrencode.c)
 *****************************************************************************}

{**
 * Create a symbol from the input data.
 * @warning This function is THREAD UNSAFE when pthread is disabled.
 * @param input input data.
 * @return an instance of QRcode class. The version of the result QRcode may
 *         be larger than the designated version. On error, NULL is returned,
 *         and errno is set to indicate the error. See Exceptions for the
 *         details.
 * @throw EINVAL invalid input object.
 * @throw ENOMEM unable to allocate memory for input objects.
 *}
function QRcode_encodeInput(input: PQRinput): PQRcode;

{**
 * Create a symbol from the string. The library automatically parses the input
 * string and encodes in a QR Code symbol.
 * @warning This function is THREAD UNSAFE when pthread is disabled.
 * @param string input string. It must be NUL terminated.
 * @param version version of the symbol. If 0, the library chooses the minimum
 *                version for the given input data.
 * @param level error correction level.
 * @param hint tell the library how Japanese Kanji characters should be
 *             encoded. If QR_MODE_KANJI is given, the library assumes that the
 *             given string contains Shift-JIS characters and encodes them in
 *             Kanji-mode. If QR_MODE_8 is given, all of non-alphanumerical
 *             characters will be encoded as is. If you want to embed UTF-8
 *             string, choose this. Other mode will cause EINVAL error.
 * @param casesensitive case-sensitive(1) or not(0).
 * @return an instance of QRcode class. The version of the result QRcode may
 *         be larger than the designated version. On error, NULL is returned,
 *         and errno is set to indicate the error. See Exceptions for the
 *         details.
 * @throw EINVAL invalid input object.
 * @throw ENOMEM unable to allocate memory for input objects.
 * @throw ERANGE input data is too large.
 *}
function QRcode_encodeString(const str: PAnsiChar; version: Integer;
  level: QRecLevel; hint: QRencodeMode; casesensitive: Integer): PQRcode;

{**
 * Same to QRcode_encodeString(), but encode whole data in 8-bit mode.
 * @warning This function is THREAD UNSAFE when pthread is disabled.
 *}
function QRcode_encodeString8bit(const str: PAnsiChar; version: Integer;
  level: QRecLevel): PQRcode;

{**
 * Micro QR Code version of QRcode_encodeString().
 * @warning This function is THREAD UNSAFE when pthread is disabled.
 *}
function QRcode_encodeStringMQR(const str: PAnsiChar; version: Integer;
  level: QRecLevel; hint: QRencodeMode; casesensitive: Integer): PQRcode;

{**
 * Micro QR Code version of QRcode_encodeString8bit().
 * @warning This function is THREAD UNSAFE when pthread is disabled.
 *}
function QRcode_encodeString8bitMQR(const str: PAnsiChar; version: Integer;
  level: QRecLevel): PQRcode;

{**
 * Encode byte stream (may include '\0') in 8-bit mode.
 * @warning This function is THREAD UNSAFE when pthread is disabled.
 * @param size size of the input data.
 * @param data input data.
 * @param version version of the symbol. If 0, the library chooses the minimum
 *                version for the given input data.
 * @param level error correction level.
 * @throw EINVAL invalid input object.
 * @throw ENOMEM unable to allocate memory for input objects.
 * @throw ERANGE input data is too large.
 *}
function QRcode_encodeData(size: Integer; const data: PByte; version: Integer;
  level: QRecLevel): PQRcode;

{**
 * Micro QR Code version of QRcode_encodeData().
 * @warning This function is THREAD UNSAFE when pthread is disabled.
 *}
function QRcode_encodeDataMQR(size: Integer; const data: PByte; version: Integer;
  level: QRecLevel): PQRcode;

{**
 * Free the instance of QRcode class.
 * @param qrcode an instance of QRcode class.
 *}
procedure QRcode_free(qrcode: PQRcode);

{**
 * Create structured symbols from the input data.
 * @warning This function is THREAD UNSAFE when pthread is disabled.
 * @param s
 * @return a singly-linked list of QRcode.
 *}
function QRcode_encodeInputStructured(s: PQRinput_Struct): PQRcode_List;

{**
 * Create structured symbols from the string. The library automatically parses
 * the input string and encodes in a QR Code symbol.
 * @warning This function is THREAD UNSAFE when pthread is disabled.
 * @param string input string. It must be NUL terminated.
 * @param version version of the symbol.
 * @param level error correction level.
 * @param hint tell the library how Japanese Kanji characters should be
 *             encoded. If QR_MODE_KANJI is given, the library assumes that the
 *             given string contains Shift-JIS characters and encodes them in
 *             Kanji-mode. If QR_MODE_8 is given, all of non-alphanumerical
 *             characters will be encoded as is. If you want to embed UTF-8
 *             string, choose this. Other mode will cause EINVAL error.
 * @param casesensitive case-sensitive(1) or not(0).
 * @return a singly-linked list of QRcode. On error, NULL is returned, and
 *         errno is set to indicate the error. See Exceptions for the details.
 * @throw EINVAL invalid input object.
 * @throw ENOMEM unable to allocate memory for input objects.
 *}
function QRcode_encodeStringStructured(const str: PAnsiChar; version: Integer;
  level: QRecLevel; hint: QRencodeMode; casesensitive: Integer): PQRcode_List;

{**
 * Same to QRcode_encodeStringStructured(), but encode whole data in 8-bit mode.
 * @warning This function is THREAD UNSAFE when pthread is disabled.
 *}
function QRcode_encodeString8bitStructured(const str: PAnsiChar;
  version: Integer; level: QRecLevel): PQRcode_List;

{**
 * Create structured symbols from byte stream (may include '\0'). Wholde data
 * are encoded in 8-bit mode.
 * @warning This function is THREAD UNSAFE when pthread is disabled.
 * @param size size of the input data.
 * @param data input dat.
 * @param version version of the symbol.
 * @param level error correction level.
 * @return a singly-linked list of QRcode. On error, NULL is returned, and
 *         errno is set to indicate the error. See Exceptions for the details.
 * @throw EINVAL invalid input object.
 * @throw ENOMEM unable to allocate memory for input objects.
 *}
function QRcode_encodeDataStructured(size: Integer; const data: PByte;
  version: Integer; level: QRecLevel): PQRcode_List;

{**
 * Return the number of symbols included in a QRcode_List.
 * @param qrlist a head entry of a QRcode_List.
 * @return number of symbols in the list.
 *}
function QRcode_List_size(qrlist: PQRcode_List): Integer;

{**
 * Free the QRcode_List.
 * @param qrlist a head entry of a QRcode_List.
 *}
procedure QRcode_List_free(qrlist: PQRcode_List);


{******************************************************************************
 * System utilities
 ******************************************************************************}

{**
 * Return a string that identifies the library version.
 * @param major_version
 * @param minor_version
 * @param micro_version
 *}
procedure QRcode_APIVersion(major_ver, minor_ver, micro_ver: PInteger);

{**
 * Return a string that identifies the library version.
 * @return a string identifies the library version. The string is held by the
 * library. Do NOT free it.
 *}
function QRcode_APIVersionString(): PAnsiChar;

{**
 * Clear all caches. This is only for debug purpose. If you are attacking a
 * complicated memory leak bug, try this to reduce the reachable blocks record.
 * @warning This function is THREAD UNSAFE when pthread is disabled.
 *}
procedure QRcode_clearCache();

implementation

uses
  rscode, qrinput, qrspec, mqrspec, mask, mmask, split;

type
{******************************************************************************
 * Raw code
 *****************************************************************************}

  PRSblock = ^TRSblock;
  TRSblock = record
    dataLength: Integer;
    data: PByte;
    eccLength: Integer;
    ecc: PByte;
  end;

  PQRRawCode = ^QRRawCode;
  QRRawCode = record
    version: Integer;
    dataLength: Integer;
    eccLength: Integer;
    datacode: PByte;
    ecccode: PByte;
    b1: Integer;
    blocks: Integer;
    rsblock: PRSblock;
    count: Integer;
  end;

function PRSblockIndex(ASrc: PRSblock; AIndex: Integer): PRSblock;
begin
  Result := ASrc;
  Inc(Result, AIndex);
end;

procedure RSblock_initBlock(block: PRSblock; dl: Integer; data: PByte;
  el: Integer; ecc: PByte; rs: PRS);
begin
	block.dataLength := dl;
	block.data := data;
	block.eccLength := el;
	block.ecc := ecc;

	encode_rs_char(rs, PData_t(data), PData_t(ecc));
end;

function RSblock_init(blocks: PRSblock; spec: array of Integer;
  data, ecc: PByte): Integer;
var
  i, el, dl: Integer;
  block: PRSblock;
  dp, ep: PByte;
  rs: PRS;
begin
	dl := QRspec_rsDataCodes1(spec);
	el := QRspec_rsEccCodes1(spec);
	rs := init_rs(8, $11d, 0, 1, el, 255 - dl - el);
	if rs = nil then
  begin
    Result := -1;
    Exit;
  end;

	block := blocks;
	dp := data;
	ep := ecc;
	for i := 0 to QRspec_rsBlockNum1(spec) - 1 do
  begin
		RSblock_initBlock(block, dl, dp, el, ep, rs);
		Inc(dp, dl);
		Inc(ep, el);
		Inc(block);
	end;

	if QRspec_rsBlockNum2(spec) = 0 then
  begin
    Result := 0;
    Exit;
  end;

	dl := QRspec_rsDataCodes2(spec);
	el := QRspec_rsEccCodes2(spec);
	rs := init_rs(8, $11d, 0, 1, el, 255 - dl - el);
	if rs = nil then
  begin
    Result := -1;
    Exit;
  end;
	for i := 0 to QRspec_rsBlockNum2(spec) - 1 do
  begin
		RSblock_initBlock(block, dl, dp, el, ep, rs);
		Inc(dp, dl);
		Inc(ep, el);
		Inc(block);
	end;

	Result := 0;
end;

procedure QRraw_free(raw: PQRRawCode);
begin
	if raw <> nil then
  begin
		FreeMem(raw.datacode);
		FreeMem(raw.ecccode);
		FreeMem(raw.rsblock);
		FreeMem(raw);
	end;
end;

function QRraw_new(input: PQRinput): PQRRawCode;
var
  spec: array[0..4] of Integer;
  ret: Integer;
begin
  try
    GetMem(Result, sizeof(QRRawCode));
  except
    Result := nil;
    Exit;
  end;

	Result.datacode := QRinput_getByteStream(input);
	if Result.datacode = nil then
  begin
		FreeMem(Result);
		Result := nil;
    Exit;
	end;

	QRspec_getEccSpec(input.version, input.level, PInteger(@spec));

	Result.version := input.version;
	Result.b1 := QRspec_rsBlockNum1(spec);
	Result.dataLength := QRspec_rsDataLength(spec);
	Result.eccLength := QRspec_rsEccLength(spec);
  try
    GetMem(Result.ecccode, Result.eccLength);
  except
    FreeMem(Result.datacode);
    FreeMem(Result);
    Result := nil;
    Exit;
  end;

	Result.blocks := QRspec_rsBlockNum(spec);
  try
    GetMem(Result.rsblock, SizeOf(TRSblock));
    ZeroMemory(Result.rsblock, SizeOf(TRSblock));
  except
    QRraw_free(Result);
		Result := nil;
    Exit;
  end;
	ret := RSblock_init(Result.rsblock, spec, Result.datacode, Result.ecccode);
	if ret < 0 then
  begin
		QRraw_free(Result);
    Result := nil;
    Exit;
	end;

	Result.count := 0;
end;

{**
 * Return a code (byte).
 * This function can be called iteratively.
 * @param raw raw code.
 * @return code
 *}
function QRraw_getCode(raw: PQRRawCode): Byte;
var
  col, row: Integer;
  ret: Byte;
begin
	if raw.count < raw.dataLength then
  begin
		row := raw.count mod raw.blocks;
		col := raw.count div raw.blocks;
		if (col >= raw.rsblock^.dataLength) then
    begin
			row := row + raw.b1;
		end;
//    ret = raw->rsblock[row].data[col];
		ret := PIndex(PRSblockIndex(raw.rsblock, row).data, col)^;
	end else if raw.count < (raw.dataLength + raw.eccLength) then
  begin
		row := (raw.count - raw.dataLength) mod raw.blocks;
		col := (raw.count - raw.dataLength) div raw.blocks;
		ret := PIndex(PRSblockIndex(raw.rsblock, row).ecc, col)^;
	end else begin
		Result := 0;
    Exit;
	end;
	Inc(raw.count);
	Result := ret;
end;

type
{******************************************************************************
 * Raw code for Micro QR Code
 *****************************************************************************}
  PMQRRawCode = ^TMQRRawCode;
  TMQRRawCode = record
    version: Integer;
    dataLength: Integer;
    eccLength: Integer;
    datacode: PByte;
    ecccode: PByte;
    rsblock: PRSblock;
    oddbits: Integer;
    count: Integer;
  end;

procedure MQRraw_free(raw: PMQRRawCode);
begin
	if raw <> nil then
  begin
		FreeMem(raw.datacode);
		FreeMem(raw.ecccode);
		FreeMem(raw.rsblock);
		FreeMem(raw);
	end;
end;

function MQRraw_new(input: PQRinput): PMQRRawCode;
var
  raw: PMQRRawCode;
  rs: PRS;
begin
  try
    GetMem(raw, SizeOf(TMQRRawCode));
  except
    Result := nil;
    Exit;
  end;

	raw.version := input.version;
	raw.dataLength := MQRspec_getDataLength(input.version, input.level);
	raw.eccLength := MQRspec_getECCLength(input.version, input.level);
	raw.oddbits := raw.dataLength * 8
    - MQRspec_getDataLengthBit(input.version, input.level);
	raw.datacode := QRinput_getByteStream(input);
	if raw.datacode = nil then
  begin
		FreeMem(raw);
		Result := nil;
    Exit;
  end;

  try
    GetMem(raw.ecccode, raw.eccLength);
  except
		FreeMem(raw.datacode);
		FreeMem(raw);
		Result := nil;
    Exit;
	end;
  try
    GetMem(raw.rsblock, SizeOf(TRSblock));
    ZeroMemory(raw.rsblock, SizeOf(TRSblock));
  except
    MQRraw_free(raw);
    Result := nil;
    Exit;
  end;
	rs := init_rs(8, $11d, 0, 1, raw.eccLength,
    255 - raw.dataLength - raw.eccLength);
	if rs = nil then
  begin
		MQRraw_free(raw);
		Result := nil;
    Exit;
	end;

	RSblock_initBlock(raw.rsblock, raw.dataLength, raw.datacode, raw.eccLength,
    raw.ecccode, rs);

	raw.count := 0;

	Result := raw;
end;

{**
 * Return a code (byte).
 * This function can be called iteratively.
 * @param raw raw code.
 * @return code
 *}
function MQRraw_getCode(raw: PMQRRawCode): Byte;
var
  ret: Byte;
begin
	if (raw.count < raw.dataLength) then
		ret := PIndex(raw.datacode, raw.count)^
	else if(raw.count < raw.dataLength + raw.eccLength) then
		ret := PIndex(raw.ecccode, raw.count - raw.dataLength)^
	else begin
		Result := 0;
    Exit;
  end;
	Inc(raw.count);
	Result := ret;
end;

type
{******************************************************************************
 * Frame filling
 *****************************************************************************}
  PFrameFiller = ^TFrameFiller;
  TFrameFiller = record
    width: Integer;
    frame: PByte;
    x, y: Integer;
    dir: Integer;
    bit: Integer;
    mqr: Integer;
  end;

function FrameFiller_new(width: Integer; frame: PByte; mqr: Integer): PFrameFiller;
var
  filler: PFrameFiller;
begin
  try
    GetMem(filler, SizeOf(TFrameFiller));
  except
    Result := nil;
    Exit;
  end;
	filler.width := width;
	filler.frame := frame;
	filler.x := width - 1;
	filler.y := width - 1;
	filler.dir := -1;
	filler.bit := -1;
	filler.mqr := mqr;

	Result := filler;
end;

function FrameFiller_next(filler: PFrameFiller): PByte;
var
  p: PByte;
  x, y, w: Integer;
begin
	if filler.bit = -1 then
  begin
		filler.bit := 0;
		Result := PIndex(filler.frame, filler.y * filler.width + filler.x);
    Exit;
	end;

	x := filler.x;
	y := filler.y;
	p := filler.frame;
	w := filler.width;

	if filler.bit = 0 then
  begin
		Dec(x);
		Inc(filler.bit);
	end else begin
		Inc(x);
		y := y + filler.dir;
		Dec(filler.bit);
	end;

	if filler.dir < 0 then
  begin
		if y < 0 then
    begin
			y := 0;
			x := x - 2;
			filler.dir := 1;
			if (filler.mqr = 0) and (x = 6) then
      begin
				Dec(x);
				y := 9;
			end;
		end;
	end else begin
		if y = w then
    begin
			y := w - 1;
			x := x - 2;
			filler.dir := -1;
			if (filler.mqr = 0) and (x = 6) then
      begin
				Dec(x);
				y := y - 8;
			end;
		end;
	end;
	if (x < 0) or (y < 0) then
  begin
    Result := nil;
    Exit;
  end;  

	filler.x := x;
	filler.y := y;

	if (PIndex(p, y * w + x)^ and $80) <> 0 then
  begin
		// This tail recursion could be optimized.
		Result := FrameFiller_next(filler);
    Exit;
	end;
  Result := PIndex(p, y * w + x);
end;

{$IFDEF WITH_TESTS}
function FrameFiller_test(version: Integer): PByte;
var
  width, i, len: Integer;
  frame, p: PByte;
  filler: PFrameFiller;
begin
	width := QRspec_getWidth(version);
	frame := QRspec_newFrame(version);
	if frame = nil then
  begin
    Result := nil;
    Exit;
  end;
	filler := FrameFiller_new(width, frame, 0);
	if filler = nil then
  begin
		FreeMem(frame);
		Result := nil;
    Exit;
	end;
	len := QRspec_getDataLength(version, QR_ECLEVEL_L) * 8
    + QRspec_getECCLength(version, QR_ECLEVEL_L) * 8
    + QRspec_getRemainder(version);
	for i := 0 to len - 1 do
  begin
		p := FrameFiller_next(filler);
		if p = nil then
    begin
			FreeMem(filler);
			FreeMem(frame);
			Result := nil;
      Exit;
		end;
		p^ := (i and $7f) or $80;
	end;
	FreeMem(filler);
	Result := frame;
end;

function FrameFiller_testMQR(version: Integer): PByte;
var
  width: Integer;
  frame, p: PByte;
  filler: PFrameFiller;
  i, len: Integer;
begin
	width := MQRspec_getWidth(version);
	frame := MQRspec_newFrame(version);
	if frame = nil then
  begin
    Result := nil;
    Exit;
  end;
	filler := FrameFiller_new(width, frame, 1);
	if filler = nil then
  begin
		FreeMem(frame);
		Result := nil;
    Exit;
	end;
	len := MQRspec_getDataLengthBit(version, QR_ECLEVEL_L)
    + MQRspec_getECCLength(version, QR_ECLEVEL_L) * 8;
	for i := 0 to len - 1 do
  begin
		p := FrameFiller_next(filler);
		if p = nil then
    begin
//			fprintf(stderr, "Frame filler run over the frame!\n");
			FreeMem(filler);
			Result := frame;
      Exit;
		end;
		p^ := (i and $7f) or $80;
	end;
	FreeMem(filler);
	Result := frame;
end;
{$ENDIF}

{******************************************************************************
 * QR-code encoding
 *****************************************************************************}

function QRcode_new(version, width: Integer; data: PByte): PQRcode;
var
  qrcode: PQRcode;
begin
  try
    GetMem(qrcode, SizeOf(TQRcode));
  except
	  Result := nil;
    Exit;
  end;

	qrcode.version := version;
	qrcode.width := width;
	qrcode.data := data;

	Result := qrcode;
end;

procedure QRcode_free(qrcode: PQRcode);
begin
	if qrcode <> nil then
  begin
		FreeMem(qrcode.data);
		FreeMem(qrcode);
	end;
end;

function QRcode_encodeMask(input: PQRinput; mask: Integer): PQRcode;
label
  done;
var
  width, version, i, j: Integer;
  raw: PQRRawCode;
  frame, masked, p: PByte;
  code, bit: Byte;
  filler: PFrameFiller;
  qrcode: PQRcode;
begin
  qrcode := nil;

	if input.mqr <> 0 then
  begin
//		errno := EINVAL;
		Result := nil;
    Exit;
	end;
	if (input.version < 0) or (input.version > QRSPEC_VERSION_MAX) then
  begin
//		errno := EINVAL;
		Result := nil;
    Exit;
	end;
	if (input.level > QR_ECLEVEL_H) then
  begin
//		errno := EINVAL;
		Result := nil;
    Exit;
	end;

	raw := QRraw_new(input);
	if raw = nil then
  begin
    Result := nil;
    Exit;
  end;

	version := raw.version;
	width := QRspec_getWidth(version);
	frame := QRspec_newFrame(version);
	if frame = nil then
  begin
		QRraw_free(raw);
		Result := nil;
    Exit;
	end;
	filler := FrameFiller_new(width, frame, 0);
	if filler = nil then
  begin
		QRraw_free(raw);
		FreeMem(frame);
		Result := nil;
    Exit;
	end;

	{* inteleaved data and ecc codes *}
	for i := 0 to raw.dataLength + raw.eccLength - 1 do
  begin
		code := QRraw_getCode(raw);
		bit := $80;
		for j := 0 to 7 do
    begin
			p := FrameFiller_next(filler);
			if p = nil then
        goto done;
      if (bit and code) <> 0 then
        p^ := $02 or 1
      else
  			p^ := $02 or 0;
			bit := bit shr 1;
		end;
	end;
	QRraw_free(raw);
	raw := nil;
	{* remainder bits *}
	j := QRspec_getRemainder(version);
	for i := 0 to j - 1 do
  begin
		p := FrameFiller_next(filler);
		if p = nil then
      goto done;
		p^ := $02;
	end;

	{* masking *}

	if mask = -2 then
  begin // just for debug purpose
    try
      GetMem(masked, width * width);
    except
      Result := nil;
      Exit;
    end;
    CopyMemory(masked, frame, width * width);
//		memcpy(masked, frame, width * width);
	end else if mask < 0 then
  begin
		masked := Mask_mask(width, frame, input.level);
	end else begin
		masked := Mask_makeMask(width, frame, mask, input.level);
	end;
	if masked = nil then
		goto done;

	qrcode := QRcode_new(version, width, masked);

done:
	QRraw_free(raw);
	FreeMem(filler);
	FreeMem(frame);
	Result := qrcode;
end;

function QRcode_encodeMaskMQR(input: PQRinput; mask: Integer): PQRcode;
label
  done;
var
  width, version: Integer;
  raw: PMQRRawCode;
  frame, masked, p: PByte;
  code, bit: Byte;
  filler: PFrameFiller;
  i, j: Integer;
  qrcode: PQRcode;
begin
	qrcode := nil;

	if input.mqr = 0 then
  begin
//		errno := EINVAL;
		Result := nil;
    Exit;
	end;
	if (input.version <= 0) or (input.version > MQRSPEC_VERSION_MAX) then
  begin
//		errno := EINVAL;
		Result := nil;
    Exit;
	end;
	if (input.level > QR_ECLEVEL_Q) then
  begin
//		errno := EINVAL;
		Result := nil;
    Exit;
	end;

	raw := MQRraw_new(input);
	if raw = nil then
  begin
    Result := nil;
    Exit;
  end;

	version := raw.version;
	width := MQRspec_getWidth(version);
	frame := MQRspec_newFrame(version);
	if frame = nil then
  begin
		MQRraw_free(raw);
		Result := nil;
    Exit;
	end;
	filler := FrameFiller_new(width, frame, 1);
	if filler = nil then
  begin
		MQRraw_free(raw);
		FreeMem(frame);
		Result := nil;
    Exit;
	end;

	{* inteleaved data and ecc codes *}
	for i := 0 to raw.dataLength + raw.eccLength - 1 do
  begin
		code := MQRraw_getCode(raw);
		if (raw.oddbits <> 0) and (i = (raw.dataLength - 1)) then
    begin
			bit := 1 shl (raw.oddbits - 1);
			for j := 0 to raw.oddbits - 1 do
      begin
				p := FrameFiller_next(filler);
				if p = nil then
          goto done;

        p^ := $02 or btoi((bit and code) <> 0);
				bit := bit shr 1;
			end;
		end else begin
			bit := $80;
			for j := 0 to 7 do
      begin
				p := FrameFiller_next(filler);
				if p = nil then
          goto done;

        p^ := $02 or btoi((bit and code) <> 0);
				bit := bit shr 1;
			end;
		end;
	end;
	MQRraw_free(raw);
	raw := nil;

	{* masking *}
	if mask < 0 then
  begin
		masked := MMask_mask(version, frame, input.level);
	end else begin
		masked := MMask_makeMask(version, frame, mask, input.level);
	end;
	if masked = nil then
		goto done;

	qrcode := QRcode_new(version, width, masked);

done:
	MQRraw_free(raw);
	FreeMem(filler);
	FreeMem(frame);
	Result := qrcode;
end;

function QRcode_encodeInput(input: PQRinput): PQRcode;
begin
	if input.mqr <> 0 then
		Result := QRcode_encodeMaskMQR(input, -1)
	else
		Result := QRcode_encodeMask(input, -1);
end;

function QRcode_encodeStringReal(const str: PAnsiChar; version: Integer;
  level: QRecLevel; mqr: Integer; hint: QRencodeMode;
  casesensitive: Integer): PQRcode;
var
  input: PQRinput;
  code: PQRcode;
  ret: Integer;
begin
	if str = nil then
  begin
//		errno := EINVAL;
		Result := nil;
    Exit;
	end;
	if (hint <> QR_MODE_8) and (hint <> QR_MODE_KANJI) then
  begin
//		errno := EINVAL;
		Result := nil;
    Exit;
	end;

	if mqr <> 0 then
  begin
		input := QRinput_newMQR(version, level);
	end else begin
		input := QRinput_new2(version, level);
	end;
	if input = nil then
  begin
    Result := nil;
    Exit;
  end;

	ret := Split_splitStringToQRinput(str, input, hint, casesensitive);
	if ret < 0 then
  begin
		QRinput_free(input);
		Result := nil;
    Exit;
	end;
	code := QRcode_encodeInput(input);
	QRinput_free(input);

	Result := code;
end;

function QRcode_encodeString(const str: PAnsiChar; version: Integer;
  level: QRecLevel; hint: QRencodeMode; casesensitive: Integer): PQRcode;
begin
	Result := QRcode_encodeStringReal(str, version, level, 0, hint, casesensitive);
end;

function QRcode_encodeStringMQR(const str: PAnsiChar; version: Integer;
  level: QRecLevel; hint: QRencodeMode; casesensitive: Integer): PQRcode;
begin
	Result := QRcode_encodeStringReal(str, version, level, 1, hint, casesensitive);
end;

function QRcode_encodeDataReal(const data: PByte;
  length, version: Integer; level: QRecLevel; mqr: Integer): PQRcode;
var
  input: PQRinput;
  code: PQRcode;
  ret: Integer;
begin
	if (data = nil) or (length = 0) then
  begin
//		errno := EINVAL;
		Result := nil;
    Exit;
	end;

	if (mqr <> 0) then
  begin
		input := QRinput_newMQR(version, level);
	end else begin
		input := QRinput_new2(version, level);
	end;
	if (input = nil) then
  begin
    Result := nil;
    Exit;
  end;

	ret := QRinput_append(input, QR_MODE_8, length, data);
	if (ret < 0) then
  begin
		QRinput_free(input);
		Result := nil;
    Exit;
	end;
	code := QRcode_encodeInput(input);
	QRinput_free(input);

	Result := code;
end;

function QRcode_encodeData(size: Integer; const data: PByte;
  version: Integer; level: QRecLevel): PQRcode;
begin
	Result := QRcode_encodeDataReal(data, size, version, level, 0);
end;

function QRcode_encodeString8bit(const str: PAnsiChar; version: Integer;
  level: QRecLevel): PQRcode;
begin
	if str = nil then
  begin
//		errno = EINVAL;
	  Result := nil;
    Exit;
	end;
	Result := QRcode_encodeDataReal(PByte(str), lstrlenA(str), version, level, 0);
end;

function QRcode_encodeDataMQR(size: Integer; const data: PByte; version: Integer;
  level: QRecLevel): PQRcode;
begin
	Result := QRcode_encodeDataReal(data, size, version, level, 1);
end;

function QRcode_encodeString8bitMQR(const str: PAnsiChar; version: Integer;
  level: QRecLevel): PQRcode;
begin
	if str = nil then
  begin
//		errno = EINVAL;
		Result := nil;
    Exit;
	end;
	Result := QRcode_encodeDataReal(PByte(str), lstrlenA(str), version, level, 1);
end;

{******************************************************************************
 * Structured QR-code encoding
 *****************************************************************************}

function QRcode_List_newEntry(): PQRcode_List;
var
  entry: PQRcode_List;
begin
  try
    GetMem(entry, SizeOf(QRcode_List));
  except
  	Result := nil;
    Exit;
  end;

	entry.next := nil;
	entry.code := nil;

	Result := entry;
end;

procedure QRcode_List_freeEntry(entry: PQRcode_List);
begin
	if entry <> nil then
  begin
		QRcode_free(entry.code);
		FreeMem(entry);
	end;
end;

procedure QRcode_List_free(qrlist: PQRcode_List);
var
  list, next: PQRcode_List;
begin
	list := qrlist;

	while (list <> nil) do
  begin
		next := list.next;
		QRcode_List_freeEntry(list);
		list := next;
	end;
end;

function QRcode_List_size(qrlist: PQRcode_List): Integer;
var
  list: PQRcode_List;
  size: Integer;
begin
	list := qrlist;
	size := 0;

	while (list <> nil) do
  begin
		Inc(size);
		list := list.next;
	end;

	Result := size;
end;

{$IFDEF 0}
function QRcode_parity(const str: PAnsiChar; size: Integer): Byte;
var
  parity: Byte;
  i: Integer;
begin
	parity := 0;

	for i := 0 to size - 1 do
		parity := parity xor Byte(PIndex(str, i)^);

	Result := parity;
end;
{$ENDIF}

function QRcode_encodeInputStructured(s: PQRinput_Struct): PQRcode_List;
label
  done;
var
  head, tail, entry: PQRcode_List;
  list: PQRinput_InputList;
begin
	head := nil;
	tail := nil;
  list := s.head;

	while list <> nil do
  begin
		if head = nil then
    begin
			entry := QRcode_List_newEntry();
			if entry = nil then
        goto done;
			head := entry;
			tail := head;
		end else begin
			entry := QRcode_List_newEntry();
			if entry = nil then
        goto done;
			tail.next := entry;
			tail := tail.next;
		end;
		tail.code := QRcode_encodeInput(list.input);
		if tail.code = nil then
			goto done;
		list := list.next;
	end;

	Result := head;
  Exit;
done:
	QRcode_List_free(head);
	Result := nil;
end;

function QRcode_encodeInputToStructured(input: PQRinput): PQRcode_List;
var
  s: PQRinput_Struct;
  codes: PQRcode_List;
begin
	s := QRinput_splitQRinputToStruct(input);
	if s = nil then
  begin
    Result := nil;
    Exit;
  end;

	codes := QRcode_encodeInputStructured(s);
	QRinput_Struct_free(s);

	Result := codes;
end;

function QRcode_encodeDataStructuredReal(size: Integer; const data: PByte;
	version: Integer; level: QRecLevel; eightbit: Integer;
  hint: QRencodeMode; casesensitive: Integer): PQRcode_List;
var
  input: PQRinput;
  codes: PQRcode_List;
  ret: Integer;
begin
	if version <= 0 then
  begin
//		errno := EINVAL;
		Result := nil;
    Exit;
	end;
	if (eightbit = 0) and ((hint <> QR_MODE_8) and (hint <> QR_MODE_KANJI)) then
  begin
//		errno := EINVAL;
		Result := nil;
    Exit;
	end;

	input := QRinput_new2(version, level);
	if input = nil then
  begin
    Result := nil;
    Exit;
  end;

	if eightbit <> 0 then
  begin
		ret := QRinput_append(input, QR_MODE_8, size, data);
	end else begin
		ret := Split_splitStringToQRinput(PAnsiChar(data), input, hint, casesensitive);
	end;
	if ret < 0 then
  begin
		QRinput_free(input);
		Result := nil;
    Exit;
	end;
	codes := QRcode_encodeInputToStructured(input);
	QRinput_free(input);

	Result := codes;
end;

function QRcode_encodeDataStructured(size: Integer; const data: PByte;
  version: Integer; level: QRecLevel): PQRcode_List;
begin
	Result := QRcode_encodeDataStructuredReal(size, data, version, level, 1,
    QR_MODE_NUL, 0);
end;

function QRcode_encodeString8bitStructured(const str: PAnsiChar;
  version: Integer; level: QRecLevel): PQRcode_List;
begin
	if str = nil then
  begin
//		errno := EINVAL;
		Result := nil;
    Exit;
	end;
	Result := QRcode_encodeDataStructured(lstrlenA(str), PByte(str), version, level);
end;

function QRcode_encodeStringStructured(const str: PAnsiChar; version: Integer;
  level: QRecLevel; hint: QRencodeMode; casesensitive: Integer): PQRcode_List;
begin
	if str = nil then
  begin
//		errno := EINVAL;
		Result := nil;
    Exit;
	end;
	Result := QRcode_encodeDataStructuredReal(lstrlenA(str), PByte(str),
    version, level, 0, hint, casesensitive);  
end;

{******************************************************************************
 * System utilities
 *****************************************************************************}

procedure QRcode_APIVersion(major_ver, minor_ver, micro_ver: PInteger);
begin
	if major_ver <> nil then
  begin
		major_ver^ := MAJOR_VERSION;
	end;
	if minor_ver <> nil then
  begin
		minor_ver^ := MINOR_VERSION;
	end;
	if micro_ver <> nil then
  begin
		micro_ver^ := MICRO_VERSION;
	end;
end;

function QRcode_APIVersionString(): PAnsiChar;
begin
	Result := PAnsiChar(AnsiString(Format('%d.%d.%d', [MAJOR_VERSION,
    MINOR_VERSION, MICRO_VERSION])));
end;

procedure QRcode_clearCache();
begin
	QRspec_clearCache();
	MQRspec_clearCache();
	free_rs_cache();
end;

end.
