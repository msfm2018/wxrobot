{*******************************************************************************

 * qrencode - QR Code encoder
 *
 * QR Code specification in convenient format. 
 * This code is taken from Kentaro Fukuchi's qrspec.h and
 * qrspec.c then editted and packed into a .pas file.
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

unit qrspec;

interface

uses
  Windows, struct;

{**
 * Return maximum data code length (bytes) for the version.
 * @param version
 * @param level
 * @return maximum size (bytes)
 *}
function QRspec_getDataLength(version: Integer; level: QRecLevel): Integer;

{**
 * Return maximum error correction code length (bytes) for the version.
 * @param version
 * @param level
 * @return ECC size (bytes)
 *}
function QRspec_getECCLength(version: Integer; level: QRecLevel): Integer;

{**
 * Return a version number that satisfies the input code length.
 * @param size input code length (byte)
 * @param level
 * @return version number
 *}
function QRspec_getMinimumVersion(size: Integer; level: QRecLevel): Integer;

{**
 * Return the width of the symbol for the version.
 * @param version
 * @return width
 *}
function QRspec_getWidth(version: Integer): Integer;

{**
 * Return the numer of remainder bits.
 * @param version
 * @return number of remainder bits
 *}
function QRspec_getRemainder(version: Integer): Integer;

{******************************************************************************
 * Length indicator
 *****************************************************************************}

{**
 * Return the size of lenght indicator for the mode and version.
 * @param mode
 * @param version
 * @return the size of the appropriate length indicator (bits).
 *}
function QRspec_lengthIndicator(mode: QRencodeMode; version: Integer): Integer;

{**
 * Return the maximum length for the mode and version.
 * @param mode
 * @param version
 * @return the maximum length (bytes)
 *}
function QRspec_maximumWords(mode: QRencodeMode; version: Integer): Integer;

{******************************************************************************
 * Error correction code
 *****************************************************************************}

{**
 * Return an array of ECC specification.
 * @param version
 * @param level
 * @param spec an array of ECC specification contains as following:
 * (# of type1 blocks, # of data code, # of ecc code,
 *  # of type2 blocks, # of data code)
 *}
//void QRspec_getEccSpec(int version, QRecLevel level, int spec[5]);
procedure QRspec_getEccSpec(version: Integer; level: QRecLevel;
  spec: PInteger);

//#define QRspec_rsBlockNum(__spec__) (__spec__[0] + __spec__[3])
//#define QRspec_rsBlockNum1(__spec__) (__spec__[0])
//#define QRspec_rsDataCodes1(__spec__) (__spec__[1])
//#define QRspec_rsEccCodes1(__spec__) (__spec__[2])
//#define QRspec_rsBlockNum2(__spec__) (__spec__[3])
//#define QRspec_rsDataCodes2(__spec__) (__spec__[4])
//#define QRspec_rsEccCodes2(__spec__) (__spec__[2])

function QRspec_rsBlockNum(spec: array of Integer): Integer;
function QRspec_rsBlockNum1(spec: array of Integer): Integer;
function QRspec_rsDataCodes1(spec: array of Integer): Integer;
function QRspec_rsEccCodes1(spec: array of Integer): Integer;
function QRspec_rsBlockNum2(spec: array of Integer): Integer;
function QRspec_rsDataCodes2(spec: array of Integer): Integer;
function QRspec_rsEccCodes2(spec: array of Integer): Integer;
//
//#define QRspec_rsDataLength(__spec__) \
//	((QRspec_rsBlockNum1(__spec__) * QRspec_rsDataCodes1(__spec__)) + \
//	 (QRspec_rsBlockNum2(__spec__) * QRspec_rsDataCodes2(__spec__)))
//#define QRspec_rsEccLength(__spec__) \
//	(QRspec_rsBlockNum(__spec__) * QRspec_rsEccCodes1(__spec__))

function QRspec_rsDataLength(spec: array of Integer): Integer;
function QRspec_rsEccLength(spec: array of Integer): Integer;

{******************************************************************************
 * Version information pattern
 *****************************************************************************}

{**
 * Return BCH encoded version information pattern that is used for the symbol
 * of version 7 or greater. Use lower 18 bits.
 * @param version
 * @return BCH encoded version information pattern
 *}
function QRspec_getVersionPattern(version: Integer): Cardinal;

{******************************************************************************
 * Format information
 *****************************************************************************}

{**
 * Return BCH encoded format information pattern.
 * @param mask
 * @param level
 * @return BCH encoded format information pattern
 *}
function QRspec_getFormatInfo(mask: Integer; level: QRecLevel): Cardinal;

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
function QRspec_newFrame(version: Integer): PByte;

{**
 * Clear the frame cache. Typically for debug.
 *}
procedure QRspec_clearCache();

implementation

uses
  qrinput;

{******************************************************************************
 * Version and capacity
 *****************************************************************************}
type
  QRspec_Capacity = record
    width: Integer; //< Edge length of the symbol
    words: Integer;  //< Data capacity (bytes)
    remainder: Integer; //< Remainder bit (bits)
    ec: array[0..3] of Integer;  //< Number of ECC code (bytes)
  end;

var
{**
 * Table of the capacity of symbols
 * See Table 1 (pp.13) and Table 12-16 (pp.30-36), JIS X0510:2004.
 *}
  qrspecCapacity: array[0..QRSPEC_VERSION_MAX] of QRspec_Capacity = (
    (width:  0; words:   0; remainder: 0; ec: (  0,    0,    0,    0)),
    (width: 21; words:  26; remainder: 0; ec: (  7,   10,   13,   17)), // 1
    (width: 25; words:  44; remainder: 7; ec: ( 10,   16,   22,   28)),
    (width: 29; words:  70; remainder: 7; ec: ( 15,   26,   36,   44)),
    (width: 33; words: 100; remainder: 7; ec: ( 20,   36,   52,   64)),
    (width: 37; words: 134; remainder: 7; ec: ( 26,   48,   72,   88)), // 5
    (width: 41; words: 172; remainder: 7; ec: ( 36,   64,   96,  112)),
    (width: 45; words: 196; remainder: 0; ec: ( 40,   72,  108,  130)),
    (width: 49; words: 242; remainder: 0; ec: ( 48,   88,  132,  156)),
    (width: 53; words: 292; remainder: 0; ec: ( 60,  110,  160,  192)),
    (width: 57; words: 346; remainder: 0; ec: ( 72,  130,  192,  224)), //10
    (width: 61; words: 404; remainder: 0; ec: ( 80,  150,  224,  264)),
    (width: 65; words: 466; remainder: 0; ec: ( 96,  176,  260,  308)),
    (width: 69; words: 532; remainder: 0; ec: (104,  198,  288,  352)),
    (width: 73; words: 581; remainder: 3; ec: (120,  216,  320,  384)),
    (width: 77; words: 655; remainder: 3; ec: (132,  240,  360,  432)), //15
    (width: 81; words: 733; remainder: 3; ec: (144,  280,  408,  480)),
    (width: 85; words: 815; remainder: 3; ec: (168,  308,  448,  532)),
    (width: 89; words: 901; remainder: 3; ec: (180,  338,  504,  588)),
    (width: 93; words: 991; remainder: 3; ec: (196,  364,  546,  650)),
    (width: 97; words:1085; remainder: 3; ec: (224,  416,  600,  700)), //20
    (width:101; words:1156; remainder: 4; ec: (224,  442,  644,  750)),
    (width:105; words:1258; remainder: 4; ec: (252,  476,  690,  816)),
    (width:109; words:1364; remainder: 4; ec: (270,  504,  750,  900)),
    (width:113; words:1474; remainder: 4; ec: (300,  560,  810,  960)),
    (width:117; words:1588; remainder: 4; ec: (312,  588,  870, 1050)), //25
    (width:121; words:1706; remainder: 4; ec: (336,  644,  952, 1110)),
    (width:125; words:1828; remainder: 4; ec: (360,  700, 1020, 1200)),
    (width:129; words:1921; remainder: 3; ec: (390,  728, 1050, 1260)),
    (width:133; words:2051; remainder: 3; ec: (420,  784, 1140, 1350)),
    (width:137; words:2185; remainder: 3; ec: (450,  812, 1200, 1440)), //30
    (width:141; words:2323; remainder: 3; ec: (480,  868, 1290, 1530)),
    (width:145; words:2465; remainder: 3; ec: (510,  924, 1350, 1620)),
    (width:149; words:2611; remainder: 3; ec: (540,  980, 1440, 1710)),
    (width:153; words:2761; remainder: 3; ec: (570, 1036, 1530, 1800)),
    (width:157; words:2876; remainder: 0; ec: (570, 1064, 1590, 1890)), //35
    (width:161; words:3034; remainder: 0; ec: (600, 1120, 1680, 1980)),
    (width:165; words:3196; remainder: 0; ec: (630, 1204, 1770, 2100)),
    (width:169; words:3362; remainder: 0; ec: (660, 1260, 1860, 2220)),
    (width:173; words:3532; remainder: 0; ec: (720, 1316, 1950, 2310)),
    (width:177; words:3706; remainder: 0; ec: (750, 1372, 2040, 2430)) //40
  );

{******************************************************************************
 * Length indicator
 *****************************************************************************}

  lengthTableBits: array[0..3, 0..2] of Integer = (
    (10, 12, 14),
    ( 9, 11, 13),
    ( 8, 16, 16),
    ( 8, 10, 12)
  );

function QRspec_getDataLength(version: Integer; level: QRecLevel): Integer;
begin
  Result := qrspecCapacity[version].words
    - qrspecCapacity[version].ec[Integer(level)];
end;

function QRspec_getECCLength(version: Integer; level: QRecLevel): Integer;
begin
  Result := qrspecCapacity[version].ec[Integer(level)];
end;

function QRspec_getMinimumVersion(size: Integer; level: QRecLevel): Integer;
var
  i, words: Integer;
begin
  Result := -1;
  for i := 1 to QRSPEC_VERSION_MAX do
  begin
    words := qrspecCapacity[i].words - qrspecCapacity[i].ec[Integer(level)];
    if words >= size then
    begin
      Result := i;
      Break;
    end;
  end;
end;

function QRspec_getWidth(version: Integer): Integer;
begin
  Result := qrspecCapacity[version].width;
end;

function QRspec_getRemainder(version: Integer): Integer;
begin
  Result := qrspecCapacity[version].remainder;
end;

function QRspec_lengthIndicator(mode: QRencodeMode; version: Integer): Integer;
var
  l: Integer;
begin
  if not QRinput_isSplittableMode(mode) then
  begin
    Result := 0;
    Exit;
  end;
  if version <= 9 then
    l := 0
  else if version <= 26 then
    l := 1
  else
    l := 2;
  Result := lengthTableBits[Integer(mode)][l];
end;

function QRspec_maximumWords(mode: QRencodeMode; version: Integer): Integer;
var
  l, bits, words: Integer;
begin
  if not QRinput_isSplittableMode(mode) then
  begin
    Result := 0;
    Exit;
  end;
  if version <= 9 then
    l := 0
  else if version <= 26 then
    l := 1
  else
    l := 2;
  bits := lengthTableBits[Integer(mode)][l];
  words := (1 shl bits) - 1;
  if mode = QR_MODE_KANJI then
    words := words * 2;   // the number of bytes is required
  Result := words;
end;

{******************************************************************************
 * Error correction code
 *****************************************************************************}
var
{**
 * Table of the error correction code (Reed-Solomon block)
 * See Table 12-16 (pp.30-36), JIS X0510:2004.
 *}
  eccTable: array[0..QRSPEC_VERSION_MAX, 0..3, 0..1] of Integer = (
    (( 0,  0), ( 0,  0), ( 0,  0), ( 0,  0)),
    (( 1,  0), ( 1,  0), ( 1,  0), ( 1,  0)), // 1
    (( 1,  0), ( 1,  0), ( 1,  0), ( 1,  0)),
    (( 1,  0), ( 1,  0), ( 2,  0), ( 2,  0)),
    (( 1,  0), ( 2,  0), ( 2,  0), ( 4,  0)),
    (( 1,  0), ( 2,  0), ( 2,  2), ( 2,  2)), // 5
    (( 2,  0), ( 4,  0), ( 4,  0), ( 4,  0)),
    (( 2,  0), ( 4,  0), ( 2,  4), ( 4,  1)),
    (( 2,  0), ( 2,  2), ( 4,  2), ( 4,  2)),
    (( 2,  0), ( 3,  2), ( 4,  4), ( 4,  4)),
    (( 2,  2), ( 4,  1), ( 6,  2), ( 6,  2)), //10
    (( 4,  0), ( 1,  4), ( 4,  4), ( 3,  8)),
    (( 2,  2), ( 6,  2), ( 4,  6), ( 7,  4)),
    (( 4,  0), ( 8,  1), ( 8,  4), (12,  4)),
    (( 3,  1), ( 4,  5), (11,  5), (11,  5)),
    (( 5,  1), ( 5,  5), ( 5,  7), (11,  7)), //15
    (( 5,  1), ( 7,  3), (15,  2), ( 3, 13)),
    (( 1,  5), (10,  1), ( 1, 15), ( 2, 17)),
    (( 5,  1), ( 9,  4), (17,  1), ( 2, 19)),
    (( 3,  4), ( 3, 11), (17,  4), ( 9, 16)),
    (( 3,  5), ( 3, 13), (15,  5), (15, 10)), //20
    (( 4,  4), (17,  0), (17,  6), (19,  6)),
    (( 2,  7), (17,  0), ( 7, 16), (34,  0)),
    (( 4,  5), ( 4, 14), (11, 14), (16, 14)),
    (( 6,  4), ( 6, 14), (11, 16), (30,  2)),
    (( 8,  4), ( 8, 13), ( 7, 22), (22, 13)), //25
    ((10,  2), (19,  4), (28,  6), (33,  4)),
    (( 8,  4), (22,  3), ( 8, 26), (12, 28)),
    (( 3, 10), ( 3, 23), ( 4, 31), (11, 31)),
    (( 7,  7), (21,  7), ( 1, 37), (19, 26)),
    (( 5, 10), (19, 10), (15, 25), (23, 25)), //30
    ((13,  3), ( 2, 29), (42,  1), (23, 28)),
    ((17,  0), (10, 23), (10, 35), (19, 35)),
    ((17,  1), (14, 21), (29, 19), (11, 46)),
    ((13,  6), (14, 23), (44,  7), (59,  1)),
    ((12,  7), (12, 26), (39, 14), (22, 41)), //35
    (( 6, 14), ( 6, 34), (46, 10), ( 2, 64)),
    ((17,  4), (29, 14), (49, 10), (24, 46)),
    (( 4, 18), (13, 32), (48, 14), (42, 32)),
    ((20,  4), (40,  7), (43, 22), (10, 67)),
    ((19,  6), (18, 31), (34, 34), (20, 61))//40
  );

//void QRspec_getEccSpec(int version, QRecLevel level, int spec[5]);
procedure QRspec_getEccSpec(version: Integer; level: QRecLevel;
  spec: PInteger);
var
  b1, b2: Integer;
  data, ecc: Integer;
begin
	b1 := eccTable[version][Integer(level)][0];
	b2 := eccTable[version][Integer(level)][1];
	data := QRspec_getDataLength(version, level);
	ecc  := QRspec_getECCLength(version, level);

	if b2 = 0 then
  begin
		PIndex(spec, 0)^ := b1;
		PIndex(spec, 1)^ := data div b1;
		PIndex(spec, 2)^ := ecc div b1;
		PIndex(spec, 3)^ := 0;
    PIndex(spec, 4)^ := 0;
	end else begin
		PIndex(spec, 0)^ := b1;
		PIndex(spec, 1)^ := data div (b1 + b2);
		PIndex(spec, 2)^ := ecc  div (b1 + b2);
		PIndex(spec, 3)^ := b2;
		PIndex(spec, 4)^ := PIndex(spec, 1)^ + 1;
	end;
end;

{******************************************************************************
 * Alignment pattern
 *****************************************************************************}

{**
 * Positions of alignment patterns.
 * This array includes only the second and the third position of the alignment
 * patterns. Rest of them can be calculated from the distance between them.
 *
 * See Table 1 in Appendix E (pp.71) of JIS X0510:2004.
 *}
var
  alignmentPattern: array[0..QRSPEC_VERSION_MAX, 0..1] of Integer = (
    ( 0,  0),
    ( 0,  0), (18,  0), (22,  0), (26,  0), (30,  0), // 1- 5
    (34,  0), (22, 38), (24, 42), (26, 46), (28, 50), // 6-10
    (30, 54), (32, 58), (34, 62), (26, 46), (26, 48), //11-15
    (26, 50), (30, 54), (30, 56), (30, 58), (34, 62), //16-20
    (28, 50), (26, 50), (30, 54), (28, 54), (32, 58), //21-25
    (30, 58), (34, 62), (26, 50), (30, 54), (26, 52), //26-30
    (30, 56), (34, 60), (30, 58), (34, 62), (30, 54), //31-35
    (24, 50), (28, 54), (32, 58), (26, 54), (30, 58) //35-40
  );

{**
 * Put an alignment marker.
 * @param frame
 * @param width
 * @param ox,oy center coordinate of the pattern
 *}
procedure QRspec_putAlignmentMarker(frame: PByte; width, ox, oy: Integer);
const
	finder: array[0..24] of Byte = (
		$a1, $a1, $a1, $a1, $a1,
		$a1, $a0, $a0, $a0, $a1,
		$a1, $a0, $a1, $a0, $a1,
		$a1, $a0, $a0, $a0, $a1,
		$a1, $a1, $a1, $a1, $a1
	);
var
  x, y: Integer;
  s: PByte;
begin
  Inc(frame, (oy - 2) * width + ox - 2);
	s := @finder;
	for y := 0 to 4  do
  begin
		for x := 0 to 4 do
      PIndex(frame, x)^ := PIndex(s, x)^;
    Inc(frame, width);
    Inc(s, 5);
	end;
end;

procedure QRspec_putAlignmentPattern(version: Integer; frame: PByte;
  width: Integer);
var
  d, w, x, y, cx, cy: Integer;
begin
	if version < 2 then
    Exit;

	d := alignmentPattern[version][1] - alignmentPattern[version][0];
	if d < 0 then
		w := 2
	else
		w := (width - alignmentPattern[version][0]) div d + 2;

	if (w * w - 3) = 1 then
  begin
		x := alignmentPattern[version][0];
		y := alignmentPattern[version][0];
		QRspec_putAlignmentMarker(frame, width, x, y);
		Exit;
	end;

	cx := alignmentPattern[version][0];
	for x := 1 to w - 2 do
  begin
		QRspec_putAlignmentMarker(frame, width,  6, cx);
		QRspec_putAlignmentMarker(frame, width, cx,  6);
		cx := cx + d;
	end;

	cy := alignmentPattern[version][0];
	for y := 0 to w - 2 do
  begin
		cx := alignmentPattern[version][0];
		for x := 0 to w - 2 do
    begin
			QRspec_putAlignmentMarker(frame, width, cx, cy);
			cx := cx + d;
		end;
		cy := cx + d;
	end;
end;

{******************************************************************************
 * Version information pattern
 *****************************************************************************}
var
{**
 * Version information pattern (BCH coded).
 * See Table 1 in Appendix D (pp.68) of JIS X0510:2004.
 *}
  versionPattern: array[0..QRSPEC_VERSION_MAX - 7] of Cardinal = (
    $07c94, $085bc, $09a99, $0a4d3, $0bbf6, $0c762, $0d847, $0e60d,
    $0f928, $10b78, $1145d, $12a17, $13532, $149a6, $15683, $168c9,
    $177ec, $18ec4, $191e1, $1afab, $1b08e, $1cc1a, $1d33f, $1ed75,
    $1f250, $209d5, $216f0, $228ba, $2379f, $24b0b, $2542e, $26a64,
    $27541, $28c69
  );

function QRspec_getVersionPattern(version: Integer): Cardinal;
begin
	if (version < 7) or (version > QRSPEC_VERSION_MAX) then
    Result := 0
  else
  	Result := versionPattern[version - 7];
end;

{******************************************************************************
 * Format information
 *****************************************************************************/}
var
{* See calcFormatInfo in tests/test_qrspec.c *}
  formatInfo: array[0..3, 0..7] of Cardinal = (
    ($77c4, $72f3, $7daa, $789d, $662f, $6318, $6c41, $6976),
    ($5412, $5125, $5e7c, $5b4b, $45f9, $40ce, $4f97, $4aa0),
    ($355f, $3068, $3f31, $3a06, $24b4, $2183, $2eda, $2bed),
    ($1689, $13be, $1ce7, $19d0, $0762, $0255, $0d0c, $083b)
  );

function QRspec_getFormatInfo(mask: Integer; level: QRecLevel): Cardinal;
begin
	if (mask < 0) or (mask > 7) then
    Result := 0
  else
    Result := formatInfo[Integer(level)][mask];
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
  frames: array[0..QRSPEC_VERSION_MAX] of PByte;

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

function QRspec_createFrame(version: Integer): PByte;
var
  frame, p, q: PByte;
  width, x, y: Integer;
  verinfo, v: Cardinal;
begin
	width := qrspecCapacity[version].width;
  try
    GetMem(frame, width * width);
  except
    Result := nil;
    Exit;
  end;

  ZeroMemory(frame, width * width);
	{* Finder pattern *}
	putFinderPattern(frame, width, 0, 0);
	putFinderPattern(frame, width, width - 7, 0);
	putFinderPattern(frame, width, 0, width - 7);
	{* Separator *}
	p := frame;
	q := PIndex(frame, width * (width - 7));
	for y := 0 to 6 do
  begin
		PIndex(p, 7)^ := $c0;
		PIndex(p, width - 8)^ := $c0;
		PIndex(q, 7)^ := $c0;
    Inc(p, width);
    Inc(q, width);
	end;
  FillChar(PIndex(frame, width * 7)^, 8, $c0);
  FillChar(PIndex(frame, width * 8 - 8)^, 8, $c0);
  FillChar(PIndex(frame, width * (width - 8))^, 8, $c0);
	{* Mask format information area *}
  FillChar(PIndex(frame, width * 8)^, 9, $84);
  FillChar(PIndex(frame, width * 9 - 8)^, 8, $84);
	p := PIndex(frame, 8);
	for y := 0 to 7 do
  begin
		p^ := $84;
    Inc(p, width);
	end;
	p := PIndex(frame, width * (width - 7) + 8);
	for y := 0 to 6 do
  begin
		p^ := $84;
    Inc(p, width);
	end;
	{* Timing pattern *}
	p := PIndex(frame, width * 6 + 8);
	q := PIndex(frame, width * 8 + 6);
	for x := 1 to width - 16 do
  begin
		p^ := $90 or (x and 1);
		q^ := $90 or (x and 1);
    Inc(p);
    Inc(q, width);
	end;
	{* Alignment pattern *}
	QRspec_putAlignmentPattern(version, frame, width);

	{* Version information *}
	if version >= 7 then
  begin
		verinfo := QRspec_getVersionPattern(version);

		p := PIndex(frame, width * (width - 11));
		v := verinfo;
		for x := 0 to 5 do
    begin
			for y := 0 to 2 do
      begin
				PIndex(p, width * y + x)^ := $88 or (v and 1);
				v := v shr 1;
			end;
		end;

		p := PIndex(frame, width - 11);
		v := verinfo;
		for y := 0 to 5 do
    begin
			for x := 0 to 2 do
      begin
				PIndex(p, x)^ := $88 or (v and 1);
				v := v shr 1;
			end;
      Inc(p, width);
		end;
	end;
	{* and a little bit... *}                      
	PIndex(frame, width * (width - 8) + 8)^ := $81;

	Result := frame;
end;

function QRspec_newFrame(version: Integer): PByte;
var
  frame: PByte;
  width: Integer;
begin
	if (version < 1) or (version > QRSPEC_VERSION_MAX) then
  begin
    Result := nil;
    Exit;
  end;

	if frames[version] = nil then
		frames[version] := QRspec_createFrame(version);

	if frames[version] = nil then
  begin
    Result := nil;
    Exit;
  end;

	width := qrspecCapacity[version].width;
  try
    GetMem(frame, width * width);
  except
    Result := nil;
    Exit;
  end;
  CopyMemory(frame, frames[version], width * width);
  Result := frame;
end;

procedure QRspec_clearCache();
var
  i: Integer;
begin
	for i := 1 to QRSPEC_VERSION_MAX do
  begin
		FreeMem(frames[i]);
		frames[i] := nil;
	end;
end;

function QRspec_rsBlockNum(spec: array of Integer): Integer;
begin
  Result := spec[0] + spec[3];
end;

function QRspec_rsBlockNum1(spec: array of Integer): Integer;
begin
  Result := spec[0];
end;

function QRspec_rsDataCodes1(spec: array of Integer): Integer;
begin
  Result := spec[1];
end;

function QRspec_rsEccCodes1(spec: array of Integer): Integer;
begin
  Result := spec[2];
end;

function QRspec_rsBlockNum2(spec: array of Integer): Integer;
begin
  Result := spec[3];
end;

function QRspec_rsDataCodes2(spec: array of Integer): Integer;
begin
  Result := spec[4];
end;

function QRspec_rsEccCodes2(spec: array of Integer): Integer;
begin
  Result := spec[2];
end;

function QRspec_rsDataLength(spec: array of Integer): Integer;
begin
  Result := QRspec_rsBlockNum1(spec) * QRspec_rsDataCodes1(spec) +
    QRspec_rsBlockNum2(spec) * QRspec_rsDataCodes2(spec);
end;

function QRspec_rsEccLength(spec: array of Integer): Integer;
begin
  Result := QRspec_rsBlockNum(spec) * QRspec_rsEccCodes1(spec);
end;

end.
