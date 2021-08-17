{*******************************************************************************

 * qrencode - QR Code encoder
 *
 * This code is taken from Kentaro Fukuchi's .h and
 * .c then editted and packed into a .pas file.
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

unit struct;

interface

uses
  Windows;

const
{**
 * Maximum version (size) of QR-code symbol.
 *}
  QRSPEC_VERSION_MAX  = 40;

{**
 * Maximum version (size) of QR-code symbol.
 *}
  MQRSPEC_VERSION_MAX = 4;

{**
 * Length of a standard mode indicator in bits.
 *}

  MODE_INDICATOR_SIZE = 4;

{**
 * Length of a segment of structured-append header.
 *}
  STRUCTURE_HEADER_SIZE = 20;

{**
 * Maximum number of symbols in a set of structured-appended symbols.
 *}
  MAX_STRUCTURED_SYMBOLS = 16;


{**
 * Maximum width of a symbol
 *}
  QRSPEC_WIDTH_MAX = 177;

{******************************************************************************
 * Mode indicator
 *****************************************************************************}

{**
 * Mode indicator. See Table 2 of JIS X0510:2004, pp.16.
 *}
  QRSPEC_MODEID_ECI        = 7;
  QRSPEC_MODEID_NUM        = 1;
  QRSPEC_MODEID_AN         = 2;
  QRSPEC_MODEID_8          = 4;
  QRSPEC_MODEID_KANJI      = 8;
  QRSPEC_MODEID_FNC1FIRST  = 5;
  QRSPEC_MODEID_FNC1SECOND = 9;
  QRSPEC_MODEID_STRUCTURE  = 3;
  QRSPEC_MODEID_TERMINATOR = 0;

  MAJOR_VERSION = 3;
  MINOR_VERSION = 4;
  MICRO_VERSION = 3;

type
  PBitStream = ^TBitStream;
  TBitStream = record
    length: Integer;
    data: PByte;
  end;

{* Stuff specific to the 8-bit symbol version of the general purpose RS codecs
 *
 *}
  data_t = Byte;
  PData_t = ^data_t;

{**
 * Reed-Solomon codec control block
 *}
  PRS = ^TRS;
  TRS = record
    mm: Integer;              {* Bits per symbol *}
    nn: Integer;              {* Symbols per block (= (1<<mm)-1) *}
    alpha_to: PData_t;     {* log lookup table *}
    index_of: PData_t;     {* Antilog lookup table *}
    genpoly: PData_t;      {* Generator polynomial *}
    nroots: Integer;     {* Number of generator roots = number of parity symbols *}
    fcr: Integer;        {* First consecutive root, index form *}
    prim: Integer;       {* Primitive element, index form *}
    iprim: Integer;      {* prim-th root of 1, index form *}
    pad: Integer;        {* Padding bytes in shortened block *}
    gfpoly: Integer;
    next: PRS;
  end;

{**
 * Level of error correction.
 *}
  QRecLevel = (
    QR_ECLEVEL_L = 0, ///< lowest
    QR_ECLEVEL_M,
    QR_ECLEVEL_Q,
    QR_ECLEVEL_H      ///< highest
  );

{**
 * Encoding mode.
 *}
  QRencodeMode = (
    QR_MODE_NUL = -1,  ///< Terminator (NUL character). Internal use only
    QR_MODE_NUM = 0,   ///< Numeric mode
    QR_MODE_AN,        ///< Alphabet-numeric mode
    QR_MODE_8,         ///< 8-bit data mode
    QR_MODE_KANJI,     ///< Kanji (shift-jis) mode
    QR_MODE_STRUCTURE, ///< Internal use only
    QR_MODE_ECI,       ///< ECI mode
    QR_MODE_FNC1FIRST,  ///< FNC1, first position
    QR_MODE_FNC1SECOND  ///< FNC1, second position
  );

{******************************************************************************
 * Entry of input data
 *****************************************************************************}

  PQRinput_List = ^QRinput_List;

  _QRinput_List = record
    mode: QRencodeMode;
    size: Integer;				///< Size of data chunk (byte).
    data: PByte;	///< Data chunk.
    bstream: PBitStream;
    next: PQRinput_List;
  end;
  QRinput_List = _QRinput_List;

{******************************************************************************
 * Input Data
 *****************************************************************************}
  PQRinput = ^TQRinput;

  _QRinput = record
    version: Integer;
    level: QRecLevel;
    head: PQRinput_List;
    tail: PQRinput_List;
    mqr: Integer;
    fnc1: Integer;
    appid: Byte;
  end;
  TQRinput = _QRinput;

{******************************************************************************
 * Structured append input data
 *****************************************************************************}
  PQRinput_InputList = ^QRinput_InputList;

  _QRinput_InputList = record
    input: PQRinput;
    next: PQRinput_InputList;
  end;
  QRinput_InputList = _QRinput_InputList;

  PQRinput_Struct = ^QRinput_Struct;

  _QRinput_Struct = record
    size: Integer;					///< number of structured symbols
    parity: Integer;
    head: PQRinput_InputList;
    tail: PQRinput_InputList;
  end;
  QRinput_Struct = _QRinput_Struct;

{**
 * QRcode class.
 * Symbol data is represented as an array contains width*width uchars.
 * Each uchar represents a module (dot). If the less significant bit of
 * the uchar is 1, the corresponding module is black. The other bits are
 * meaningless for usual applications, but here its specification is described.
 *
 * <pre>
 * MSB 76543210 LSB
 *     |||||||`- 1=black/0=white
 *     ||||||`-- data and ecc code area
 *     |||||`--- format information
 *     ||||`---- version information
 *     |||`----- timing pattern
 *     ||`------ alignment pattern
 *     |`------- finder pattern and separator
 *     `-------- non-data modules (format, timing, etc.)
 * </pre>
 *}
  PQRcode = ^TQRcode;
  TQRcode = record
    version: Integer;         ///< version of the symbol
    width: Integer;           ///< width of the symbol
    data: PByte; ///< symbol data
  end;

{**
 * Singly-linked list of QRcode. Used to represent a structured symbols.
 * A list is terminated with NULL.
 *}
  PQRcode_List = ^QRcode_List;
  _QRcode_List = record
    code: PQRcode;
    next: PQRcode_List;
  end;
  QRcode_List = _QRcode_List;

function PIndex(ASrc: PAnsiChar; AIndex: Integer): PAnsiChar; overload;
function PIndex(ASrc: PByte; AIndex: Integer): PByte; overload;
function PIndex(ASrc: PInteger; AIndex: Integer): PInteger; overload;
function PIndex(ASrc: PData_t; AIndex: Integer): PData_t; overload;

function strdup(const s: PAnsiChar): PAnsiChar;

function btoi(b: Boolean): Integer;

implementation

function PIndex(ASrc: PAnsiChar; AIndex: Integer): PAnsiChar;
begin
  Result := ASrc;
  Inc(Result, AIndex);
end;

function PIndex(ASrc: PByte; AIndex: Integer): PByte;
begin
  Result := ASrc;
  Inc(Result, AIndex);
end;

function PIndex(ASrc: PInteger; AIndex: Integer): PInteger;
begin
  Result := ASrc;
  Inc(Result, AIndex);
end;

function PIndex(ASrc: PData_t; AIndex: Integer): PData_t;
begin
  Result := ASrc;
  Inc(Result, AIndex);
end;

function strdup(const s: PAnsiChar): PAnsiChar;
var
  len: Cardinal;
begin
  len := lstrlenA(s) + 1;
  try
    GetMem(Result, len);
    CopyMemory(Result, s, len);
  except
    Result := nil;
  end;
end;

function btoi(b: Boolean): Integer;
begin
  if b then
    Result := 1
  else
    Result := 0;
end;

end.

