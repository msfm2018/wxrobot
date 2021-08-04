{*******************************************************************************

 * qrencode - QR Code encoder
 *
 * Micro QR Code specification in convenient format.
 * This code is taken from Kentaro Fukuchi's mqrspec.h and
 * mqrspec.c then editted and packed into a .pas file.
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

unit mqrspec;

interface

uses
  Windows, struct;

const
{******************************************************************************
 * Mode indicator
 *****************************************************************************}

{**
 * Mode indicator. See Table 2 in Appendix 1 of JIS X0510:2004, pp.107.
 *}
  MQRSPEC_MODEID_NUM    =   0;
  MQRSPEC_MODEID_AN     =   1;
  MQRSPEC_MODEID_8      =   2;
  MQRSPEC_MODEID_KANJI  =   3;

{******************************************************************************
 * Version and capacity
 *****************************************************************************}

{**
 * Maximum width of a symbol
 *}
  MQRSPEC_WIDTH_MAX     =   17;

{**
 * Return maximum data code length (bits) for the version.
 * @param version
 * @param level
 * @return maximum size (bits)
 *}
function MQRspec_getDataLengthBit(version: Integer; level: QRecLevel): Integer;

{**
 * Return maximum data code length (bytes) for the version.
 * @param version
 * @param level
 * @return maximum size (bytes)
 *}
function MQRspec_getDataLength(version: Integer; level: QRecLevel): Integer;

{**
 * Return maximum error correction code length (bytes) for the version.
 * @param version
 * @param level
 * @return ECC size (bytes)
 *}
function MQRspec_getECCLength(version: Integer; level: QRecLevel): Integer;

{**
 * Return a version number that satisfies the input code length.
 * @param size input code length (byte)
 * @param level
 * @return version number
 *}
//function MQRspec_getMinimumVersion(size: Integer; level: QRecLevel): Integer;

{**
 * Return the width of the symbol for the version.
 * @param version
 * @return width
 *}
function MQRspec_getWidth(version: Integer): Integer;

{**
 * Return the numer of remainder bits.
 * @param version
 * @return number of remainder bits
 *}
//function MQRspec_getRemainder(version: Integer): Integer;

{******************************************************************************
 * Length indicator
 *****************************************************************************}

{**
 * Return the size of lenght indicator for the mode and version.
 * @param mode
 * @param version
 * @return the size of the appropriate length indicator (bits).
 *}
function MQRspec_lengthIndicator(mode: QRencodeMode; version: Integer): Integer;

{**
 * Return the maximum length for the mode and version.
 * @param mode
 * @param version
 * @return the maximum length (bytes)
 *}
function MQRspec_maximumWords(mode: QRencodeMode; version: Integer): Integer;

{******************************************************************************
 * Version information pattern
 *****************************************************************************}

{**
 * Return BCH encoded version information pattern that is used for the symbol
 * of version 7 or greater. Use lower 18 bits.
 * @param version
 * @return BCH encoded version information pattern
 *}
//function MQRspec_getVersionPattern(version: Integer): Cardinal;

{******************************************************************************
 * Format information
 *****************************************************************************}

{**
 * Return BCH encoded format information pattern.
 * @param mask
 * @param version
 * @param level
 * @return BCH encoded format information pattern
 *}
function MQRspec_getFormatInfo(mask, version: Integer; level: QRecLevel): Cardinal;

{******************************************************************************
 * Frame
 *****************************************************************************}

{**
 * Return a copy of initialized frame.
 * When the same version is requested twice or more, a copy of cached frame
 * is returned.
 * @param version
 * @return Array of unsigned char. You can free it by free().
 *}
//extern unsigned char *MQRspec_newFrame(int version);
function MQRspec_newFrame(version: Integer): PByte;

{**
 * Clear the frame cache. Typically for debug.
 *}
procedure MQRspec_clearCache();


implementation

{******************************************************************************
 * Version and capacity
 *****************************************************************************}

type
  MQRspec_Capacity = record
    width: Integer;   //< Edge length of the symbol
    ec: array[0..3] of Integer;   //< Number of ECC code (bytes)
  end;

{**
 * Table of the capacity of symbols
 * See Table 1 (pp.106) and Table 8 (pp.113) of Appendix 1, JIS X0510:2004.
 *}
const
  mqrspecCapacity: array[0..MQRSPEC_VERSION_MAX] of MQRspec_Capacity = (
    (width:  0; ec: (0,  0,  0,  0)),
    (width: 11; ec: (2,  0,  0,  0)),
    (width: 13; ec: (5,  6,  0,  0)),
    (width: 15; ec: (6,  8,  0,  0)),
    (width: 17; ec: (8,  10, 14, 0))
  );

function MQRspec_getDataLengthBit(version: Integer; level: QRecLevel): Integer;
var
  w, ecc: Integer;
begin
  w := mqrspecCapacity[version].width - 1;
  ecc := mqrspecCapacity[version].ec[Integer(level)];
  if ecc = 0 then
    Result := 0
  else
    Result := w * w - 64 - ecc * 8;
end;

function MQRspec_getDataLength(version: Integer; level: QRecLevel): Integer;
begin
  Result := (MQRspec_getDataLengthBit(version, level) + 4) div 8;
end;

function MQRspec_getECCLength(version: Integer; level: QRecLevel): Integer;
begin
  Result := mqrspecCapacity[version].ec[Integer(level)];
end;

function MQRspec_getWidth(version: Integer): Integer;
begin
  Result := mqrspecCapacity[version].width;
end;

{******************************************************************************
 * Length indicator
 *****************************************************************************}

{**
 * See Table 3 (pp.107) of Appendix 1, JIS X0510:2004.
 *}
const
  lengthTableBits: array[0..3] of array[0..3] of Integer = (
    ( 3, 4, 5, 6),
    ( 0, 3, 4, 5),
    ( 0, 0, 4, 5),
    ( 0, 0, 3, 4)
  );

function MQRspec_lengthIndicator(mode: QRencodeMode; version: Integer): Integer;
begin
  Result := lengthTableBits[Integer(mode)][version - 1];
end;

function MQRspec_maximumWords(mode: QRencodeMode; version: Integer): Integer;
var
  bits: Integer;
begin
  bits := lengthTableBits[Integer(mode)][version - 1];
  Result := (1 shl bits) - 1;
  if (mode = QR_MODE_KANJI) then
    Result := Result * 2; // the number of bytes is required
end;

{******************************************************************************
 * Format information
 *****************************************************************************}

const
{* See calcFormatInfo in tests/test_mqrspec.c *}
  formatInfo: array[0..3] of array[0..7] of Cardinal = (
    ($4445, $55ae, $6793, $7678, $06de, $1735, $2508, $34e3),
    ($4172, $5099, $62a4, $734f, $03e9, $1202, $203f, $31d4),
    ($4e2b, $5fc0, $6dfd, $7c16, $0cb0, $1d5b, $2f66, $3e8d),
    ($4b1c, $5af7, $68ca, $7921, $0987, $186c, $2a51, $3bba)
  );

{* See Table 10 of Appendix 1. (pp.115) *}
  typeTable: array[0..MQRSPEC_VERSION_MAX] of array[0..2] of Integer = (
    (-1, -1, -1),
    ( 0, -1, -1),
    ( 1,  2, -1),
    ( 3,  4, -1),
    ( 5,  6,  7)
  );

function MQRspec_getFormatInfo(mask, version: Integer; level: QRecLevel): Cardinal;
var
  iType: Integer;
begin
  Result := 0;
  if (mask < 0) or (mask > 3) then
    Exit;

  if (version <= 0) or (version > MQRSPEC_VERSION_MAX) then
    Exit;

  if (level = QR_ECLEVEL_H) then
    Exit;

  iType := typeTable[version][Integer(level)];
  if iType < 0 then
    Exit;

  Result := formatInfo[mask][iType];
end;

{******************************************************************************
 * Frame
 *****************************************************************************}

{**
 * Cache of initial frames.
 *}
{* C99 says that static storage shall be initialized to a null pointer
 * by compiler. *}
var
//  unsigned char *frames[MQRSPEC_VERSION_MAX + 1];
  frames: array[0..MQRSPEC_VERSION_MAX] of PByte;

{**
 * Put a finder pattern.
 * @param frame
 * @param width
 * @param ox,oy upper-left coordinate of the pattern
 *}
procedure putFinderPattern(frame: PByte; width, ox, oy: Integer);
const
	finder: array[0..48] of Byte = (
		$c1, $c1, $c1, $c1, $c1, $c1, $c1,
		$c1, $c0, $c0, $c0, $c0, $c0, $c1,
		$c1, $c0, $c1, $c1, $c1, $c0, $c1,
		$c1, $c0, $c1, $c1, $c1, $c0, $c1,
		$c1, $c0, $c1, $c1, $c1, $c0, $c1,
		$c1, $c0, $c0, $c0, $c0, $c0, $c1,
		$c1, $c1, $c1, $c1, $c1, $c1, $c1
	);
var
	x, y: Integer;
  s: PByte;
begin
  Inc(frame, oy * width + ox);
	s := @finder;
	for y := 0 to 6 do
  begin
		for x := 0 to 6 do
      PIndex(frame, x)^ := PIndex(s, x)^;
    Inc(frame, width);
    Inc(s, 7);
	end;
end;

function MQRspec_createFrame(version: Integer): PByte;
var
  p, q: PByte;
  width, x, y: Integer;
begin
  Result := nil;
  width := mqrspecCapacity[version].width;
  try
    GetMem(Result, width * width);
  except      
    Exit;
  end;
  ZeroMemory(Result, width * width);
  {* Finder pattern *}
  putFinderPattern(Result, width, 0, 0);
  {* Separator *}
  p := Result;
  for y := 0 to 6 do
  begin
    PIndex(p, 7)^ := $c0;
    Inc(p, width);
  end;
  p := PIndex(Result, width * 7);
  FillChar(p, 8, $c0);
  {* Mask format information area *}
  p := PIndex(Result, width * 8 + 1);
  FillChar(p, 8, $84);
  p := PIndex(Result, width + 8);
  for y := 0 to 6 do
  begin
    p^ := $84;
    Inc(p, width);
  end;
  {* Timing pattern *}
  p := PIndex(Result, 8);
  q := PIndex(Result, width * 8);
  for x := 1 to width - 8 do
  begin
    p^ := $90 or (x and 1);
    q^ := $90 or (x and 1);
    Inc(p);
    Inc(q, width);
  end;
end;

function MQRspec_newFrame(version: Integer): PByte;
var
  width: Integer;
begin
  Result := nil;
  if (version < 1) or (version > MQRSPEC_VERSION_MAX) then
    Exit;

  if frames[version] = nil then
    frames[version] := MQRspec_createFrame(version);
  if frames[version] = nil then
    Exit;
  width := mqrspecCapacity[version].width;
  try
    GetMem(Result, width * width);
    CopyMemory(Result, frames[version], width * width);
  except
  end;
end;

procedure MQRspec_clearCache();
var
  i: Integer;
begin
  for i := 1 to MQRSPEC_VERSION_MAX do
  begin
    FreeMem(frames[i]);
    frames[i] := nil;
  end;
end;

end.
