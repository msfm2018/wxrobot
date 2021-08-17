{*******************************************************************************

 * qrencode - QR Code encoder
 *
 * Input data chunk class
 * This code is taken from Kentaro Fukuchi's qrinput.h and
 * qrinput.c then editted and packed into a .pas file.
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

unit qrinput;

interface

uses
  Windows, bitstream, struct;

{******************************************************************************
 * Input data (qrinput.c)
 *****************************************************************************}

{**
 * Instantiate an input data object. The version is set to 0 (auto-select)
 * and the error correction level is set to QR_ECLEVEL_L.
 * @return an input object (initialized). On error, NULL is returned and errno
 *         is set to indicate the error.
 * @throw ENOMEM unable to allocate memory.
 *}
function QRinput_new(): PQRinput;

{**
 * Instantiate an input data object.
 * @param version version number.
 * @param level Error correction level.
 * @return an input object (initialized). On error, NULL is returned and errno
 *         is set to indicate the error.
 * @throw ENOMEM unable to allocate memory for input objects.
 * @throw EINVAL invalid arguments.
 *}
function QRinput_new2(version: Integer; level: QRecLevel): PQRinput;

{**
 * Instantiate an input data object. Object's Micro QR Code flag is set.
 * Unlike with full-sized QR Code, version number must be specified (>0).
 * @param version version number (1--4).
 * @param level Error correction level.
 * @return an input object (initialized). On error, NULL is returned and errno
 *         is set to indicate the error.
 * @throw ENOMEM unable to allocate memory for input objects.
 * @throw EINVAL invalid arguments.
 *}
function QRinput_newMQR(version: Integer; level: QRecLevel): PQRinput;

{**
 * Append data to an input object.
 * The data is copied and appended to the input object.
 * @param input input object.
 * @param mode encoding mode.
 * @param size size of data (byte).
 * @param data a pointer to the memory area of the input data.
 * @retval 0 success.
 * @retval -1 an error occurred and errno is set to indeicate the error.
 *            See Execptions for the details.
 * @throw ENOMEM unable to allocate memory.
 * @throw EINVAL input data is invalid.
 *
 *}
function QRinput_append(input: PQRinput; mode: QRencodeMode; size: Integer;
  const data: PByte): Integer;

{**
 * Append ECI header.
 * @param input input object.
 * @param ecinum ECI indicator number (0 - 999999)
 * @retval 0 success.
 * @retval -1 an error occurred and errno is set to indeicate the error.
 *            See Execptions for the details.
 * @throw ENOMEM unable to allocate memory.
 * @throw EINVAL input data is invalid.
 *
 *}
function QRinput_appendEChead_imper(input: PQRinput; ecinum: Cardinal): Integer;

{**
 * Get current version.
 * @param input input object.
 * @return current version.
 *}
function QRinput_getVersion(input: PQRinput): Integer;

{**
 * Set version of the QR code that is to be encoded.
 * This function cannot be applied to Micro QR Code.
 * @param input input object.
 * @param version version number (0 = auto)
 * @retval 0 success.
 * @retval -1 invalid argument.
 *}
function QRinput_setVersion(input: PQRinput; version: Integer): Integer;

{**
 * Get current error correction level.
 * @param input input object.
 * @return Current error correcntion level.
 *}
function QRinput_getErrorCorrectionLevel(input: PQRinput): QRecLevel;

{**
 * Set error correction level of the QR code that is to be encoded.
 * This function cannot be applied to Micro QR Code.
 * @param input input object.
 * @param level Error correction level.
 * @retval 0 success.
 * @retval -1 invalid argument.
 *}
function QRinput_setErrorCorrectionLevel(input: PQRinput; level: QRecLevel): Integer;

{**
 * Set version and error correction level of the QR code at once.
 * This function is recommened for Micro QR Code.
 * @param input input object.
 * @param version version number (0 = auto)
 * @param level Error correction level.
 * @retval 0 success.
 * @retval -1 invalid argument.
 *}
function QRinput_setVersionAndErrorCorrectionLevel(input: PQRinput;
  version: Integer; level: QRecLevel): Integer;

{**
 * Free the input object.
 * All of data chunks in the input object are freed too.
 * @param input input object.
 *}
procedure QRinput_free(input: PQRinput);

{**
 * Validate the input data.
 * @param mode encoding mode.
 * @param size size of data (byte).
 * @param data a pointer to the memory area of the input data.
 * @retval 0 success.
 * @retval -1 invalid arguments.
 *}
function QRinput_check(mode: QRencodeMode; size: Integer;
  const data: PByte): Integer;

{**
 * Set of QRinput for structured symbols.
 *}
//typedef struct _QRinput_Struct QRinput_Struct;

{**
 * Instantiate a set of input data object.
 * @return an instance of QRinput_Struct. On error, NULL is returned and errno
 *         is set to indicate the error.
 * @throw ENOMEM unable to allocate memory.
 *}
//extern QRinput_Struct *QRinput_Struct_new(void);

{**
 * Set parity of structured symbols.
 * @param s structured input object.
 * @param parity parity of s.
 *}
procedure QRinput_Struct_setParity(s: PQRinput_Struct; parity: Byte);

{**
 * Append a QRinput object to the set. QRinput created by QRinput_newMQR()
 * will be rejected.
 * @warning never append the same QRinput object twice or more.
 * @param s structured input object.
 * @param input an input object.
 * @retval >0 number of input objects in the structure.
 * @retval -1 an error occurred. See Exceptions for the details.
 * @throw ENOMEM unable to allocate memory.
 * @throw EINVAL invalid arguments.
 *}
function QRinput_Struct_appendInput(s: PQRinput_Struct; input: PQRinput): Integer;

{**
 * Free all of QRinput in the set.
 * @param s a structured input object.
 *}
procedure QRinput_Struct_free(s: PQRinput_Struct);

{**
 * Split a QRinput to QRinput_Struct. It calculates a parity, set it, then
 * insert structured-append headers. QRinput created by QRinput_newMQR() will
 * be rejected.
 * @param input input object. Version number and error correction level must be
 *        set.
 * @return a set of input data. On error, NULL is returned, and errno is set
 *         to indicate the error. See Exceptions for the details.
 * @throw ERANGE input data is too large.
 * @throw EINVAL invalid input data.
 * @throw ENOMEM unable to allocate memory.
 *}
function QRinput_splitQRinputToStruct(input: PQRinput): PQRinput_Struct;

{**
 * Insert structured-append headers to the input structure. It calculates
 * a parity and set it if the parity is not set yet.
 * @param s input structure
 * @retval 0 success.
 * @retval -1 an error occurred and errno is set to indeicate the error.
 *            See Execptions for the details.
 * @throw EINVAL invalid input object.
 * @throw ENOMEM unable to allocate memory.
 *}
function QRinput_Struct_insertStructuredAppendHeaders(s: PQRinput_Struct): Integer;

{**
 * Set FNC1-1st position flag.
 *}
function QRinput_setFNC1First(input: PQRinput): Integer;

{**
 * Set FNC1-2nd position flag and application identifier.
 *}
function QRinput_setFNC1Second(input: PQRinput; appid: Byte): Integer;

function QRinput_isSplittableMode(mode: QRencodeMode): Boolean;

{**
 * Pack all bit streams padding bits into a byte array.
 * @param input input data.
 * @return padded merged byte stream
 *}
function QRinput_getByteStream(input: PQRinput): PByte;


function QRinput_estimateBitsModeNum(size: Integer): Integer;
function QRinput_estimateBitsModeAn(size: Integer): Integer;
function QRinput_estimateBitsMode8(size: Integer): Integer;
function QRinput_estimateBitsModeKanji(size: Integer): Integer;

function QRinput_dup(input: PQRinput): PQRinput;

{**
 * Look up the alphabet-numeric convesion table (see JIS X0510:2004, pp.19).
 * @param __c__ character
 * @return value
 *}
function QRinput_lookAnTable(c: byte): Integer;
//#define QRinput_lookAnTable(__c__) \
//	((__c__ & 0x80)?-1:QRinput_anTable[(int)__c__])

{$IFDEF WITH_TESTS}
function QRinput_mergeBitStream(input: PQRinput): PBitStream;
function QRinput_getBitStream(input: PQRinput): PBitStream;
function QRinput_estimateBitStreamSize(input: PQRinput; version: Integer): Integer;
function QRinput_splitEntry(entry: PQRinput_List; bytes: Integer): Integer;
function QRinput_lengthOfCode(mode: QRencodeMode; version, bits: Integer): Integer;
function QRinput_insertStructuredAppendHeader(input: PQRinput;
  size, number: Integer; parity: Byte): Integer;
{$ENDIF}

implementation

uses
  mqrspec, qrspec;

{******************************************************************************
 * Utilities
 *****************************************************************************}
function QRinput_isSplittableMode(mode: QRencodeMode): Boolean;
begin
  Result := (mode >= QR_MODE_NUM) and (mode <= QR_MODE_KANJI);
end;

{******************************************************************************
 * Entry of input data
 *****************************************************************************}

function QRinput_List_newEntry(mode: QRencodeMode; size: Integer;
  const data: PByte): PQRinput_List;
var
  entry: PQRinput_List;
begin
	if (QRinput_check(mode, size, data) <> 0) then
  begin
//		errno = EINVAL;
		Result := nil;
    Exit;
	end;
  try
    GetMem(entry, SizeOf(QRinput_List));
  except
    Result := nil;
    Exit;
  end;

	entry.mode := mode;
	entry.size := size;
	if size > 0 then
  begin
    try
      GetMem(entry.data, size);
    except
      FreeMem(entry);
      Result := nil;
      Exit;
    end;
    CopyMemory(entry.data, data, size);
	end;
	entry.bstream := nil;
	entry.next := nil;

	Result := entry;
end;

procedure QRinput_List_freeEntry(entry: PQRinput_List);
begin
	if entry <> nil then
  begin
		FreeMem(entry.data);
    entry.data := nil;
		BitStream_free(entry.bstream);
		FreeMem(entry);
	end;
end;

function QRinput_List_dup(entry: PQRinput_List): PQRinput_List;
begin
	try
    GetMem(Result, SizeOf(QRinput_List));
  except
    Result := nil;
    Exit;
  end;
  Result.mode := entry.mode;
  Result.size := entry.size;
  try
    GetMem(Result.data, Result.size);
  except
    FreeMem(Result);
    Result := nil;
    Exit;
  end;
  CopyMemory(Result.data, entry.data, entry.size);
  Result.bstream := nil;
  Result.next := nil;
end;

{******************************************************************************
 * Input Data
 *****************************************************************************}

function QRinput_new2(version: Integer; level: QRecLevel): PQRinput;
begin
	if (version < 0) or (version > QRSPEC_VERSION_MAX) or (level > QR_ECLEVEL_H) then
  begin
    Result := nil;
    Exit;
  end;

  try
    GetMem(Result, SizeOf(TQRinput));
  except
    Result := nil;
    Exit;
  end;

	Result.head := nil;
	Result.tail := nil;
	Result.version := version;
	Result.level := level;
	Result.mqr := 0;
	Result.fnc1 := 0;
end;

function QRinput_new(): PQRinput;
begin
	Result := QRinput_new2(0, QR_ECLEVEL_L);
end;

function QRinput_newMQR(version: Integer; level: QRecLevel): PQRinput;
begin
  Result := nil;
	if (version <= 0) or (version > MQRSPEC_VERSION_MAX) then
    Exit;
	if ((MQRspec_getECCLength(version, level) = 0)) then
    Exit;

	Result := QRinput_new2(version, level);
	if (Result = nil) then
    Exit;

	Result.mqr := 1;
end;

function QRinput_getVersion(input: PQRinput): Integer;
begin
	Result := input.version;
end;

function QRinput_setVersion(input: PQRinput; version: Integer): Integer;
begin
	if (input.mqr <> 0) or (version < 0) or (version > QRSPEC_VERSION_MAX) then
  begin
    Result := -1;
    Exit;
  end;

	input.version := version;

	Result := 0;
end;

function QRinput_getErrorCorrectionLevel(input: PQRinput): QRecLevel;
begin
	Result := input.level;
end;

function QRinput_setErrorCorrectionLevel(input: PQRinput;
  level: QRecLevel): Integer;
begin
	if (input.mqr <> 0) or (level > QR_ECLEVEL_H) then
  begin
    Result := -1;
    Exit;
  end;

	input.level := level;

	Result := 0;
end;

function QRinput_setVersionAndErrorCorrectionLevel(input: PQRinput;
  version: Integer; level: QRecLevel): Integer;
begin
  Result := -1;
	if input.mqr <> 0 then
  begin
		if (version <= 0) or (version > MQRSPEC_VERSION_MAX) then Exit;
		if ((MQRspec_getECCLength(version, level) = 0)) then  Exit;
	end else begin
		if (version < 0) or (version > QRSPEC_VERSION_MAX) then Exit;
		if (level > QR_ECLEVEL_H) then  Exit;
	end;

	input.version := version;
	input.level := level;

	Result := 0;
end;

procedure QRinput_appendEntry(input: PQRinput; entry: PQRinput_List);
begin
	if (input.tail = nil) then
  begin
		input.head := entry;
		input.tail := entry;
	end else begin
		input.tail.next := entry;
		input.tail := entry;
	end;
	entry.next := nil;
end;

function QRinput_append(input: PQRinput; mode: QRencodeMode; size: Integer;
  const data: PByte): Integer;
var
  entry: PQRinput_List;
begin
	entry := QRinput_List_newEntry(mode, size, data);
	if entry = nil then
  begin
    Result := -1;
    Exit;
  end;

	QRinput_appendEntry(input, entry);

	Result := 0;
end;

{**
 * Insert a structured-append header to the head of the input data.
 * @param input input data.
 * @param size number of structured symbols.
 * @param number index number of the symbol. (1 <= number <= size)
 * @param parity parity among input data. (NOTE: each symbol of a set of structured symbols has the same parity data)
 * @retval 0 success.
 * @retval -1 error occurred and errno is set to indeicate the error. See Execptions for the details.
 * @throw EINVAL invalid parameter.
 * @throw ENOMEM unable to allocate memory.
 *}
function QRinput_insertStructuredAppendHeader(input: PQRinput;
  size, number: Integer; parity: Byte): Integer;
var
  entry: PQRinput_List;
  buf: array[0..2] of Byte;
begin
	if size > MAX_STRUCTURED_SYMBOLS then
  begin
//		errno = EINVAL;
		Result := -1;
    Exit;
	end;
	if (number <= 0) or (number > size) then
  begin
//		errno = EINVAL;
		Result := -1;
    Exit;
  end;

	buf[0] := Byte(size);
	buf[1] := Byte(number);
	buf[2] := parity;
	entry := QRinput_List_newEntry(QR_MODE_STRUCTURE, 3, @buf);
  if entry = nil then
  begin
		Result := -1;
    Exit;
  end;

	entry.next := input.head;
	input.head := entry;

	Result := 0;
end;

function QRinput_appendEChead_imper(input: PQRinput; ecinum: Cardinal): Integer;
var
  data: array[0..3] of Byte;
begin
  Result := -1;
	if (ecinum > 999999) then
    Exit;

	{* We manually create byte array of ecinum because
	 (unsigned char *)&ecinum may cause bus error on some architectures, *}
	data[0] := ecinum and $ff;
	data[1] := (ecinum shr  8) and $ff;
	data[2] := (ecinum shr 16) and $ff;
	data[3] := (ecinum shr 24) and $ff;
	Result := QRinput_append(input, QR_MODE_ECI, 4, @data);
end;

procedure QRinput_free(input: PQRinput);
var
  list, next: PQRinput_List;
begin
	if input <> nil then
  begin
		list := input.head;
		while list <> nil do
    begin
			next := list.next;
			QRinput_List_freeEntry(list);
			list := next;
		end;
		FreeMem(input);
	end;
end;

function QRinput_calcParity(input: PQRinput): Byte;
var
  list: PQRinput_List;
  i: Integer;
begin
	Result := 0;

	list := input.head;
	while list <> nil do
  begin
		if(list.mode <> QR_MODE_STRUCTURE) then
    begin
			for i := list.size - 1 downto 0 do
				Result := Result xor PIndex(list.data, i)^;
		end;
		list := list.next;
	end;
end;

function QRinput_dup(input: PQRinput): PQRinput;
var
  list, e: PQRinput_List;
begin
	if input.mqr <> 0 then
		Result := QRinput_newMQR(input.version, input.level)
	else
		Result := QRinput_new2(input.version, input.level);
  
	if Result = nil then Exit;

	list := input.head;
	while list <> nil do
  begin
		e := QRinput_List_dup(list);
		if e = nil then
    begin
			QRinput_free(Result);
			Result := nil;
      Exit;
		end;
		QRinput_appendEntry(Result, e);
		list := list.next;
	end;
end;

{******************************************************************************
 * Numeric data
 *****************************************************************************}

{**
 * Check the input data.
 * @param size
 * @param data
 * @return result
 *}
function QRinput_checkModeNum(size: Integer; const data: PAnsiChar): Integer;
var
  i: Integer;
begin
  Result := 0;
	for i := 0 to size - 1 do
  begin
		if (PIndex(data, i)^ < '0') or (PIndex(data, i)^ > '9') then
    begin
      Result := -1;
      Break;
    end;
	end;
end;

{**
 * Estimates the length of the encoded bit stream of numeric data.
 * @param size
 * @return number of bits
 *}
function QRinput_estimateBitsModeNum(size: Integer): Integer;
var
  w: Integer;
begin
	w := size div 3;
	Result := w * 10;
	case (size - w * 3) of
		1: Result := Result + 4;
		2: Result := Result + 7;
	end;
end;

{**
 * Convert the number data to a bit stream.
 * @param entry
 * @param mqr
 * @retval 0 success
 * @retval -1 an error occurred and errno is set to indeicate the error.
 *            See Execptions for the details.
 * @throw ENOMEM unable to allocate memory.
 *}
function QRinput_encodeModeNum(entry: PQRinput_List;
  version, mqr: Integer): Integer;
var
  words, i, ret: Integer;
  val: Cardinal;
begin
  Result := -1;
	entry.bstream := BitStream_new();
  if entry.bstream = nil then
    Exit;

	if mqr <> 0 then
  begin
		if version > 1 then
    begin
			ret := BitStream_appendNum(entry.bstream, version - 1, MQRSPEC_MODEID_NUM);
			if ret < 0 then
      begin
        BitStream_free(entry.bstream);
        Exit;
      end;
		end;
		ret := BitStream_appendNum(entry.bstream,
      MQRspec_lengthIndicator(QR_MODE_NUM, version), entry.size);
		if ret < 0 then
    begin
      BitStream_free(entry.bstream);
      Exit;
    end;
	end else begin
		ret := BitStream_appendNum(entry.bstream, 4, QRSPEC_MODEID_NUM);
		if ret < 0 then
    begin
      BitStream_free(entry.bstream);
      Exit;
    end;
	
		ret := BitStream_appendNum(entry.bstream,
      QRspec_lengthIndicator(QR_MODE_NUM, version), entry.size);
		if ret < 0 then
    begin
      BitStream_free(entry.bstream);
      Exit;
    end;
	end;

	words := entry.size div 3;
	for i := 0 to words - 1 do
  begin
		val := (PIndex(entry.data, i * 3)^ - Ord('0')) * 100;
		val := val + (PIndex(entry.data, i * 3 + 1)^ - Ord('0')) * 10;
		val := val + (PIndex(entry.data, i * 3 + 2)^ - Ord('0'));

		ret := BitStream_appendNum(entry.bstream, 10, val);
		if ret < 0 then
    begin
      BitStream_free(entry.bstream);
      Exit;
    end;
	end;

	if (entry.size - words * 3) = 1 then
  begin
		val := PIndex(entry.data, words * 3)^ - Ord('0');
		ret := BitStream_appendNum(entry.bstream, 4, val);
		if ret < 0 then
    begin
      BitStream_free(entry.bstream);
      Exit;
    end;
	end else if (entry.size - words * 3) = 2 then
  begin
		val := (PIndex(entry.data, words * 3)^ - Ord('0')) * 10;
		val := val + (PIndex(entry.data, words * 3 + 1)^ - Ord('0'));
		BitStream_appendNum(entry.bstream, 7, val);
		if ret < 0 then
    begin
      BitStream_free(entry.bstream);
      Exit;
    end;
	end;

	Result := 0;
end;

var
{******************************************************************************
 * Alphabet-numeric data
 *****************************************************************************}

  QRinput_anTable: array[0..127] of ShortInt = (
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
    36, -1, -1, -1, 37, 38, -1, -1, -1, -1, 39, 40, -1, 41, 42, 43,
     0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 44, -1, -1, -1, -1, -1,
    -1, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24,
    25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, -1, -1, -1, -1, -1,
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1
  );

function QRinput_lookAnTable(c: Byte): Integer;
begin
  if (c and $80) <> 0 then
    Result := -1
  else
    Result := Ord(QRinput_anTable[c]);
end;

{**
 * Check the input data.
 * @param size
 * @param data
 * @return result
 *}
function QRinput_checkModeAn(size: Integer; const data: PAnsiChar): Integer;
var
  i: Integer;
begin
  Result := 0;
	for i := 0 to size - 1 do
  begin
		if QRinput_lookAnTable(Ord(PIndex(data, i)^)) < 0 then
    begin
			Result := -1;
      Exit;
    end;
	end;
end;

{**
 * Estimates the length of the encoded bit stream of alphabet-numeric data.
 * @param size
 * @return number of bits
 *}
function QRinput_estimateBitsModeAn(size: Integer): Integer;
var
  w: Integer;
begin
	w := size div 2;
	Result := w * 11;
	if (size and 1) <> 0 then
		Result := Result + 6;
end;

{**
 * Convert the alphabet-numeric data to a bit stream.
 * @param entry
 * @param mqr
 * @retval 0 success
 * @retval -1 an error occurred and errno is set to indeicate the error.
 *            See Execptions for the details.
 * @throw ENOMEM unable to allocate memory.
 * @throw EINVAL invalid version.
 *}
function QRinput_encodeModeAn(entry: PQRinput_List; version, mqr: Integer): Integer;
var
  words, i, ret: Integer;
  val: Cardinal;
begin
  Result := -1;
	entry.bstream := BitStream_new();
	if entry.bstream = nil then Exit;

	if mqr <> 0 then
  begin
		if version < 2 then
    begin
      BitStream_free(entry.bstream);
      Exit;
    end;
		ret := BitStream_appendNum(entry.bstream, version - 1, MQRSPEC_MODEID_AN);
		if ret < 0 then
    begin
      BitStream_free(entry.bstream);
      Exit;
    end;
		ret := BitStream_appendNum(entry.bstream,
      MQRspec_lengthIndicator(QR_MODE_AN, version), entry.size);
		if ret < 0 then
    begin
      BitStream_free(entry.bstream);
      Exit;
    end;
	end else begin
		ret := BitStream_appendNum(entry.bstream, 4, QRSPEC_MODEID_AN);
		if ret < 0 then
    begin
      BitStream_free(entry.bstream);
      Exit;
    end;
		ret := BitStream_appendNum(entry.bstream,
      QRspec_lengthIndicator(QR_MODE_AN, version), entry.size);
		if ret < 0 then
    begin
      BitStream_free(entry.bstream);
      Exit;
    end;
	end;

	words := entry.size div 2;
	for i := 0 to words - 1 do
  begin
		val := Cardinal(QRinput_lookAnTable(PIndex(entry.data, i * 2)^)) * 45;
		val := val + Cardinal(QRinput_lookAnTable(Pindex(entry.data, i * 2 + 1)^));

		ret := BitStream_appendNum(entry.bstream, 11, val);
		if ret < 0 then
    begin
      BitStream_free(entry.bstream);
      Exit;
    end;
	end;

	if (entry.size and 1) <> 0 then
  begin
		val := Cardinal(QRinput_lookAnTable(PIndex(entry.data, words * 2)^));

		ret := BitStream_appendNum(entry.bstream, 6, val);
    if ret < 0 then
    begin
      BitStream_free(entry.bstream);
      Exit;
    end;
	end;

	Result := 0;
end;

{******************************************************************************
 * 8 bit data
 *****************************************************************************}

{**
 * Estimates the length of the encoded bit stream of 8 bit data.
 * @param size
 * @return number of bits
 *}
function QRinput_estimateBitsMode8(size: Integer): Integer;
begin
  Result := size * 8;
end;

{**
 * Convert the 8bits data to a bit stream.
 * @param entry
 * @param mqr
 * @retval 0 success
 * @retval -1 an error occurred and errno is set to indeicate the error.
 *            See Execptions for the details.
 * @throw ENOMEM unable to allocate memory.
 *}
function QRinput_encodeMode8(entry: PQRinput_List; version, mqr: Integer): Integer;
var
  ret: Integer;
begin
  Result := -1;
	entry.bstream := BitStream_new();
	if entry.bstream = nil then Exit;

	if mqr <> 0 then
  begin
		if version < 3 then
    begin
      BitStream_free(entry.bstream);
      Exit;
    end;
		ret := BitStream_appendNum(entry.bstream, version - 1, MQRSPEC_MODEID_8);
    if ret < 0 then
    begin
      BitStream_free(entry.bstream);
      Exit;
    end;
		ret := BitStream_appendNum(entry.bstream,
      MQRspec_lengthIndicator(QR_MODE_8, version), entry.size);
    if ret < 0 then
    begin
      BitStream_free(entry.bstream);
      Exit;
    end;
	end else begin
		ret := BitStream_appendNum(entry.bstream, 4, QRSPEC_MODEID_8);
    if ret < 0 then
    begin
      BitStream_free(entry.bstream);
      Exit;
    end;
		ret := BitStream_appendNum(entry.bstream,
      QRspec_lengthIndicator(QR_MODE_8, version), entry.size);
    if ret < 0 then
    begin
      BitStream_free(entry.bstream);
      Exit;
    end;
	end;

	ret := BitStream_appendBytes(entry.bstream, entry.size, entry.data);
  if ret < 0 then
  begin
    BitStream_free(entry.bstream);
    Exit;
  end;

	Result := 0;
end;

{******************************************************************************
 * Kanji data
 *****************************************************************************}

{**
 * Estimates the length of the encoded bit stream of kanji data.
 * @param size
 * @return number of bits
 *}
function QRinput_estimateBitsModeKanji(size: Integer): Integer;
begin
	Result := (size div 2) * 13;
end;

{**
 * Check the input data.
 * @param size
 * @param data
 * @return result
 *}
function QRinput_checkModeKanji(size: Integer; const data: PByte): Integer;
var
  i: Integer;
  val: Cardinal;
begin
  Result := 0;
	if (size and 1) <> 0 then
  begin
		Result := -1;
    Exit;
  end;

	for i := 0 to size - 1 do
  begin
		val := (Cardinal(PIndex(data, i)^) shl 8) or PIndex(data, i + 1)^;
		if (val < $8140) or ((val > $9ffc) and (val < $e040)) or (val > $ebbf) then
    begin
			Result := -1;
      Break;
		end;
	end;
end;

{**
 * Convert the kanji data to a bit stream.
 * @param entry
 * @param mqr
 * @retval 0 success
 * @retval -1 an error occurred and errno is set to indeicate the error.
 *            See Execptions for the details.
 * @throw ENOMEM unable to allocate memory.
 * @throw EINVAL invalid version.
 *}
function QRinput_encodeModeKanji(entry: PQRinput_List; version, mqr: Integer): Integer;
var
  ret, i: Integer;
  val, h: Cardinal;
begin
  Result := -1;
	entry.bstream := BitStream_new();
	if entry.bstream = nil then Exit;

	if mqr <> 0 then
  begin
		if version < 2 then
    begin
      BitStream_free(entry.bstream);
      Exit;
    end;
		ret := BitStream_appendNum(entry.bstream, version - 1, MQRSPEC_MODEID_KANJI);
		if ret < 0 then
    begin
      BitStream_free(entry.bstream);
      Exit;    
    end;
		ret := BitStream_appendNum(entry.bstream,
      MQRspec_lengthIndicator(QR_MODE_KANJI, version), entry.size div 2);
		if ret < 0 then
    begin
      BitStream_free(entry.bstream);
      Exit;    
    end;
	end else begin
		ret := BitStream_appendNum(entry.bstream, 4, QRSPEC_MODEID_KANJI);
    if ret < 0 then
    begin
      BitStream_free(entry.bstream);
      Exit;    
    end;
		ret := BitStream_appendNum(entry.bstream,
      QRspec_lengthIndicator(QR_MODE_KANJI, version), entry.size div 2);
		if ret < 0 then
    begin
      BitStream_free(entry.bstream);
      Exit;    
    end;
	end;

  i := 0;
  while i < entry.size do
  begin
		val := (Cardinal(PIndex(entry.data, i)^) shl 8) or PIndex(entry.data, i + 1)^;
		if val <= $9ffc then
			val := val - $8140
		else
			val := val - $c140;
		h := (val shr 8) * $c0;
		val := (val and $ff) + h;

		ret := BitStream_appendNum(entry.bstream, 13, val);
    if ret < 0 then
    begin
      BitStream_free(entry.bstream);
      Exit;
    end;
    Inc(i, 2);
	end;

	Result := 0;
end;

{******************************************************************************
 * Structured Symbol
 *****************************************************************************}

{**
 * Convert a structure symbol code to a bit stream.
 * @param entry
 * @param mqr
 * @retval 0 success
 * @retval -1 an error occurred and errno is set to indeicate the error.
 *            See Execptions for the details.
 * @throw ENOMEM unable to allocate memory.
 * @throw EINVAL invalid entry.
 *}
function QRinput_encodeModeStructure(entry: PQRinput_List; mqr: Integer): Integer;
var
  ret: Integer;
begin
  Result := -1;

	if mqr <> 0 then
  begin
    BitStream_free(entry.bstream);
    Exit;
	end;
	entry.bstream := BitStream_new();
	if entry.bstream = nil then Exit;

	ret := BitStream_appendNum(entry.bstream, 4, QRSPEC_MODEID_STRUCTURE);
  if ret < 0 then
  begin
    BitStream_free(entry.bstream);
    Exit;
  end;
	ret := BitStream_appendNum(entry.bstream, 4, PIndex(entry.data, 1)^ - 1);
	if ret < 0 then
  begin
    BitStream_free(entry.bstream);
    Exit;
  end;
	ret := BitStream_appendNum(entry.bstream, 4, entry.data^ - 1);
	if ret < 0 then
  begin
    BitStream_free(entry.bstream);
    Exit;
  end;
	ret := BitStream_appendNum(entry.bstream, 8, PIndex(entry.data, 2)^);
	if ret < 0 then
  begin
    BitStream_free(entry.bstream);
    Exit;
  end;

	Result := 0;
end;

{******************************************************************************
 * FNC1
 *****************************************************************************}

function QRinput_checkModeFNC1Second(size: Integer; const data: PByte): Integer;
begin
  if size <> 1 then
    Result := -1
  else
    Result := 0;
end;

function QRinput_encodeModeFNC1Second(entry: PQRinput_List;
  version: Integer): Integer;
var
  ret: Integer;
begin
  Result := -1;
  
	entry.bstream := BitStream_new();
	if entry.bstream = nil then
    Exit;

	ret := BitStream_appendNum(entry.bstream, 4, QRSPEC_MODEID_FNC1SECOND);
	if (ret < 0) then
  begin
    BitStream_free(entry.bstream);
    Exit;
  end;

	ret := BitStream_appendBytes(entry.bstream, 1, entry.data);
  if (ret < 0) then
  begin
    BitStream_free(entry.bstream);
    Exit;
  end;

	Result := 0;
end;

{******************************************************************************
 * ECI header
 *****************************************************************************}
function QRinput_decodeECIfromByteArray(data: PByte): Cardinal;
var
  i: Integer;
begin
	Result := 0;
	for i := 0 to 3 do
  begin
		Result := Result shl 8;
		Result := Result or PIndex(data, 3 - i)^;
	end;
end;

function QRinput_estimateBitsModeECI(data: PByte): Integer;
var
  ecinum: Cardinal;
begin
	ecinum := QRinput_decodeECIfromByteArray(data);;

	{* See Table 4 of JISX 0510:2004 pp.17. *}
	if ecinum < 128 then
		Result := MODE_INDICATOR_SIZE + 8
	else if ecinum < 16384 then
		Result := MODE_INDICATOR_SIZE + 16
	else
		Result := MODE_INDICATOR_SIZE + 24;
end;

function QRinput_encodeModeECI(entry: PQRinput_List; version: Integer): Integer;
var
  ret, words: Integer;
  ecinum, code: Cardinal;
begin
  Result := -1;
	entry.bstream := BitStream_new();
	if entry.bstream = nil then Exit;

	ecinum := QRinput_decodeECIfromByteArray(entry.data);;

	{* See Table 4 of JISX 0510:2004 pp.17. *}
	if ecinum < 128 then
  begin
		words := 1;
		code := ecinum;
	end else if ecinum < 16384 then
  begin
		words := 2;
		code := $8000 + ecinum;
	end else begin
		words := 3;
		code := $c0000 + ecinum;
	end;

	ret := BitStream_appendNum(entry.bstream, 4, QRSPEC_MODEID_ECI);
	if ret < 0 then
  begin
    BitStream_free(entry.bstream);
    Exit;  
  end;
	
	ret := BitStream_appendNum(entry.bstream, words * 8, code);
	if ret < 0 then
  begin
    BitStream_free(entry.bstream);
    Exit;  
  end;

	Result := 0;
end;

{******************************************************************************
 * Validation
 *****************************************************************************}

function QRinput_check(mode: QRencodeMode; size: Integer;
  const data: PByte): Integer;
begin
  Result := -1;
	if((mode = QR_MODE_FNC1FIRST) and (size < 0)) or (size <= 0) then
  begin
    Result := -1;
    Exit;
  end;

	case (mode) of
		QR_MODE_NUM:
			Result := QRinput_checkModeNum(size, PAnsiChar(data));
		QR_MODE_AN:
			Result := QRinput_checkModeAn(size, PAnsiChar(data));
		QR_MODE_KANJI:
			Result := QRinput_checkModeKanji(size, data);
		QR_MODE_8:
			Result := 0;
		QR_MODE_STRUCTURE:
			Result := 0;
		QR_MODE_ECI:
			Result := 0;
		QR_MODE_FNC1FIRST:
			Result := 0;
		QR_MODE_FNC1SECOND:
			Result := QRinput_checkModeFNC1Second(size, data);
		QR_MODE_NUL:
			Result := -1;
	end;
end;

{******************************************************************************
 * Estimation of the bit length
 *****************************************************************************}

{**
 * Estimates the length of the encoded bit stream on the current version.
 * @param entry
 * @param version version of the symbol
 * @param mqr
 * @return number of bits
 *}
function QRinput_estimateBitStreamSizeOfEntry(entry: PQRinput_List;
  version, mqr: Integer): Integer;
var
  l, m, num: Integer;
begin
	if version = 0 then
    version := 1;

	case entry.mode of
    QR_MODE_NUM: Result := QRinput_estimateBitsModeNum(entry.size);
		QR_MODE_AN: Result := QRinput_estimateBitsModeAn(entry.size);
		QR_MODE_8: Result := QRinput_estimateBitsMode8(entry.size);
		QR_MODE_KANJI: Result := QRinput_estimateBitsModeKanji(entry.size);
		QR_MODE_STRUCTURE: begin
			Result := STRUCTURE_HEADER_SIZE;
      Exit;
    end;
		QR_MODE_ECI: Result := QRinput_estimateBitsModeECI(entry.data);
		QR_MODE_FNC1FIRST: begin
			Result := MODE_INDICATOR_SIZE;
      Exit;
    end;
		QR_MODE_FNC1SECOND: begin
			Result := MODE_INDICATOR_SIZE + 8;
      Exit;
    end;
    else begin
      Result := 0;
      Exit;
    end;
	end;

	if mqr <> 0 then
  begin
		l := QRspec_lengthIndicator(entry.mode, version);
		m := version - 1;
		Result := Result + l + m;
	end else begin
		l := QRspec_lengthIndicator(entry.mode, version);
		m := 1 shl l;
		num := (entry.size + m - 1) div m;

		Result := Result + num * (MODE_INDICATOR_SIZE + l);
	end;
end;

{**
 * Estimates the length of the encoded bit stream of the data.
 * @param input input data
 * @param version version of the symbol
 * @return number of bits
 *}
function QRinput_estimateBitStreamSize(input: PQRinput; version: Integer): Integer;
var
  list: PQRinput_List;
begin
	Result := 0;

	list := input.head;
	while list <> nil do
  begin
		Result := Result +
      QRinput_estimateBitStreamSizeOfEntry(list, version, input.mqr);
		list := list.next;
	end;
end;

{**
 * Estimates the required version number of the symbol.
 * @param input input data
 * @return required version number
 *}
function QRinput_estimateVersion(input: PQRinput): Integer;
var
  bits, prev: Integer;
begin
	Result := 0;
	repeat
		prev := Result;
		bits := QRinput_estimateBitStreamSize(input, prev);
		Result := QRspec_getMinimumVersion((bits + 7) div 8, input.level);
		if Result < 0 then
    begin
			Result := -1;
      Exit;
		end;
	until (Result <= prev);
end;

{**
 * Returns required length in bytes for specified mode, version and bits.
 * @param mode
 * @param version
 * @param bits
 * @return required length of code words in bytes.
 *}
function QRinput_lengthOfCode(mode: QRencodeMode; version, bits: Integer): Integer;
var
  payload, size, chunks, remain, maxsize: Integer;
begin
	payload := bits - 4 - QRspec_lengthIndicator(mode, version);
	case mode of
		QR_MODE_NUM: begin
			chunks := payload div 10;
			remain := payload - chunks * 10;
			size := chunks * 3;
			if remain >= 7 then
				size := size + 2
			else if remain >= 4 then
				size := size + 1;
		end;
		QR_MODE_AN: begin
			chunks := payload div 11;
			remain := payload - chunks * 11;
			size := chunks * 2;
			if remain >= 6 then
        Inc(size);
		end;
		QR_MODE_8: begin
			size := payload div 8;
		end;
		QR_MODE_KANJI: begin
			size := (payload div 13) * 2;
		end;
		QR_MODE_STRUCTURE: begin
			size := payload div 8;
		end;
		else begin
			size := 0;
		end;
	end;
	maxsize := QRspec_maximumWords(mode, version);
	if size < 0 then
    size := 0;
	if (maxsize > 0) and (size > maxsize) then
    size := maxsize;

	Result := size;
end;

{******************************************************************************
 * Data conversion
 *****************************************************************************}

{**
 * Convert the input data in the data chunk to a bit stream.
 * @param entry
 * @return number of bits (>0) or -1 for failure.
 *}
function QRinput_encodeBitStream(entry: PQRinput_List;
  version, mqr: Integer): Integer;
label
  clear;
var
  words, ret: Integer;
  st1, st2: PQRinput_List;
begin
	st1 := nil;
  st2 := nil;

	if entry.bstream <> nil then
		BitStream_free(entry.bstream);

	words := QRspec_maximumWords(entry.mode, version);
	if (words <> 0) and (entry.size > words) then
  begin
		st1 := QRinput_List_newEntry(entry.mode, words, entry.data);
		if st1 = nil then
      goto clear;
		st2 := QRinput_List_newEntry(entry.mode, entry.size - words,
      PIndex(entry.data, words));
		if st2 = nil then
      goto clear;

		ret := QRinput_encodeBitStream(st1, version, mqr);
		if ret < 0 then
      goto clear;
		ret := QRinput_encodeBitStream(st2, version, mqr);
		if ret < 0 then
      goto clear;
		entry.bstream := BitStream_new();
		if entry.bstream = nil then
      goto clear;
		ret := BitStream_append(entry.bstream, st1.bstream);
		if ret < 0 then
      goto clear;
		ret := BitStream_append(entry.bstream, st2.bstream);
		if ret < 0 then
      goto clear;
		QRinput_List_freeEntry(st1);
		QRinput_List_freeEntry(st2);
	end else begin
		ret := 0;
		case entry.mode of
			QR_MODE_NUM: ret := QRinput_encodeModeNum(entry, version, mqr);
			QR_MODE_AN: ret := QRinput_encodeModeAn(entry, version, mqr);
			QR_MODE_8: ret := QRinput_encodeMode8(entry, version, mqr);
			QR_MODE_KANJI: ret := QRinput_encodeModeKanji(entry, version, mqr);
			QR_MODE_STRUCTURE: ret := QRinput_encodeModeStructure(entry, mqr);
			QR_MODE_ECI: ret := QRinput_encodeModeECI(entry, version);
			QR_MODE_FNC1SECOND: ret := QRinput_encodeModeFNC1Second(entry, version);
		end;
    if ret < 0 then
    begin
      Result := -1;
      Exit;
    end;
	end;     
	Result := BitStream_size(entry.bstream);
  Exit;
clear:
	QRinput_List_freeEntry(st1);
	QRinput_List_freeEntry(st2);
	Result := -1;
end;

{**
 * Convert the input data to a bit stream.
 * @param input input data.
 * @retval 0 success
 * @retval -1 an error occurred and errno is set to indeicate the error.
 *            See Execptions for the details.
 * @throw ENOMEM unable to allocate memory.
 *}
function QRinput_createBitStream(input: PQRinput): Integer;
var
  list: PQRinput_List;
  bits: Integer;
begin
	Result := 0;

	list := input.head;
	while (list <> nil) do
  begin
		bits := QRinput_encodeBitStream(list, input.version, input.mqr);
		if bits < 0 then
    begin
      Result := -1;
      Exit;
    end;
		Result := Result + bits;
		list := list.next;
	end;
end;

{**
 * Convert the input data to a bit stream.
 * When the version number is given and that is not sufficient, it is increased
 * automatically.
 * @param input input data.
 * @retval 0 success
 * @retval -1 an error occurred and errno is set to indeicate the error.
 *            See Execptions for the details.
 * @throw ENOMEM unable to allocate memory.
 * @throw ERANGE input is too large.
 *}
function QRinput_convertData(input: PQRinput): Integer;
var
  bits, ver: Integer;
begin
	ver := QRinput_estimateVersion(input);
	if (ver > QRinput_getVersion(input)) then
  begin
		QRinput_setVersion(input, ver);
	end;

	while True do
  begin
		bits := QRinput_createBitStream(input);
		if (bits < 0) then
    begin
      Result := -1;
      Exit;
    end;
		ver := QRspec_getMinimumVersion((bits + 7) div 8, input.level);
		if ver < 0 then
    begin
//			errno := ERANGE;
			Result := -1;
      Exit;
    end else if (ver > QRinput_getVersion(input)) then
    begin
			QRinput_setVersion(input, ver);
		end else begin
			break;
		end;
	end;

	Result := 0;
end;

{**
 * Append padding bits for the input data.
 * @param bstream Bitstream to be appended.
 * @param input input data.
 * @retval 0 success
 * @retval -1 an error occurred and errno is set to indeicate the error.
 *            See Execptions for the details.
 * @throw ERANGE input data is too large.
 * @throw ENOMEM unable to allocate memory.
 *}
function QRinput_appendPaddingBit(bstream: PBitStream; input: PQRinput): Integer;
var
  bits, maxbits, words, maxwords, i: Integer;
  padding: PBitStream;
  padbuf: PByte;
  padlen: Integer;
begin
	padding := nil;

	bits := BitStream_size(bstream);
	maxwords := QRspec_getDataLength(input.version, input.level);
	maxbits := maxwords * 8;

	if (maxbits < bits) then
  begin
//		errno = ERANGE;
		Result := -1;
    Exit;
	end;
	if (maxbits = bits) then
  begin
		Result := 0;
    Exit;
	end;

	if (maxbits - bits <= 4) then
  begin
		Result := BitStream_appendNum(bstream, maxbits - bits, 0);
    Exit;
	end;

	words := (bits + 4 + 7) div 8;

	padding := BitStream_new();
	if (padding = nil) then
  begin
    Result := -1;
    Exit;
  end;
	Result := BitStream_appendNum(padding, words * 8 - bits, 0);
	if (Result < 0) then
  begin
    BitStream_free(padding);
    Exit;
  end;

	padlen := maxwords - words;
	if (padlen > 0) then
  begin
    try
      GetMem(padbuf, padlen);
    except
      BitStream_free(padding);
      Result := -1;
      Exit;
    end;
    for i := 0 to padlen - 1 do
    begin
      if (i and 1) <> 0 then
        PIndex(padbuf, i)^ := $11
      else
        PIndex(padbuf, i)^ := $ec;
    end;

    Result := BitStream_appendBytes(padding, padlen, padbuf);
    FreeMem(padbuf);
    if (Result < 0) then
    begin
      BitStream_free(padding);
      Exit;
    end;
	end;

	Result := BitStream_append(bstream, padding);
	BitStream_free(padding);
end;

{**
 * Append padding bits for the input data - Micro QR Code version.
 * @param bstream Bitstream to be appended.
 * @param input input data.
 * @retval 0 success
 * @retval -1 an error occurred and errno is set to indeicate the error.
 *            See Execptions for the details.
 * @throw ERANGE input data is too large.
 * @throw ENOMEM unable to allocate memory.
 *}
function QRinput_appendPaddingBitMQR(bstream: PBitStream; input: PQRinput): Integer;
label
  done;
var
  bits, maxbits, words, maxwords, i, ret, termbits: Integer;
  padlen: Integer;
  padbuf: PByte;
  padding: PBitStream;
begin
	padding := nil;
	bits := BitStream_size(bstream);
	maxbits := MQRspec_getDataLengthBit(input.version, input.level);
	maxwords := maxbits div 8;

	if (maxbits < bits) then
  begin
//		errno = ERANGE;
		Result := -1;
    Exit;
	end;
	if (maxbits = bits) then
  begin
		Result := 0;
    Exit;
  end;

	termbits := input.version * 2 + 1;

	if (maxbits - bits) <= termbits then
  begin
		ret := BitStream_appendNum(bstream, maxbits - bits, 0);
		goto done;
	end;

	bits := bits + termbits;

	words := (bits + 7) div 8;
	if (maxbits - words * 8) > 0 then
  begin
		termbits := termbits + words * 8 - bits;
		if words = maxwords then
      termbits := termbits + maxbits - words * 8;
	end else begin
		termbits := termbits + words * 8 - bits;
	end;
	padding := BitStream_new();
	if padding = nil then
  begin
    Result := -1;
    Exit;
  end;
	ret := BitStream_appendNum(padding, termbits, 0);
	if (ret < 0) then
    goto done;

	padlen := maxwords - words;
	if padlen > 0 then
  begin
    try
      GetMem(padbuf, padlen);
    except
      Result := -1;
      BitStream_free(padding);
      Exit;
    end;
		for i := 0 to padlen - 1 do
    begin
      if (i and 1) <> 0 then
        PIndex(padbuf, i)^ := $11
      else
        PIndex(padbuf, i)^ := $ec;
		end;
		ret := BitStream_appendBytes(padding, padlen, padbuf);
		FreeMem(padbuf);
		if ret < 0 then
			goto done;
		termbits := maxbits - maxwords * 8;
		if termbits > 0 then
    begin
			ret := BitStream_appendNum(padding, termbits, 0);
			if ret < 0 then
        goto done;
		end;
	end;

	ret := BitStream_append(bstream, padding);

done:
	BitStream_free(padding);
	Result := ret;
end;

function QRinput_insertFNC1Header(input: PQRinput): Integer;
var
  entry: PQRinput_List;
begin
	entry := nil;

	if input.fnc1 = 1 then
		entry := QRinput_List_newEntry(QR_MODE_FNC1FIRST, 0, nil)
	else if input.fnc1 = 2 then
		entry := QRinput_List_newEntry(QR_MODE_FNC1SECOND, 1, @(input.appid));
	if entry = nil then
  begin
  	Result := -1;
    Exit;
	end;

	if (input.head.mode <> QR_MODE_STRUCTURE)
    or (input.head.mode <> QR_MODE_ECI) then
  begin
		entry.next := input.head;
		input.head := entry;
	end else begin
		entry.next := input.head.next;
		input.head.next := entry;
	end;       
	Result := 0;
end;

{**
 * Merge all bit streams in the input data.
 * @param input input data.
 * @return merged bit stream
 *}
function QRinput_mergeBitStream(input: PQRinput): PBitStream;
var
  list: PQRinput_List;
  ret: Integer;
begin            
	if input.mqr <> 0 then
  begin
		if (QRinput_createBitStream(input) < 0) then
    begin
			Result := nil;
      Exit;
		end;
	end else begin
		if (input.fnc1 <> 0) then
    begin
			if (QRinput_insertFNC1Header(input) < 0) then
      begin
				Result := nil;
        Exit;
			end;
		end;
		if (QRinput_convertData(input) < 0) then
    begin
			Result := nil;
      Exit;
		end;
	end;

	Result := BitStream_new();
	if Result = nil then
    Exit;

	list := input.head;
	while list <> nil do
  begin
		ret := BitStream_append(Result, list.bstream);
		if (ret < 0) then
    begin
			BitStream_free(Result);
			Exit;
		end;
		list := list.next;
	end;
end;

{**
 * Merge all bit streams in the input data and append padding bits
 * @param input input data.
 * @return padded merged bit stream
 *}
function QRinput_getBitStream(input: PQRinput): PBitStream;
var
  ret: Integer;
begin
	Result := QRinput_mergeBitStream(input);
	if Result = nil then
		Exit;

	if input.mqr <> 0 then
		ret := QRinput_appendPaddingBitMQR(Result, input)
	else
		ret := QRinput_appendPaddingBit(Result, input);
	if (ret < 0) then
		BitStream_free(Result);
end;

{**
 * Pack all bit streams padding bits into a byte array.
 * @param input input data.
 * @return padded merged byte stream
 *}
function QRinput_getByteStream(input: PQRinput): PByte;
var
  bstream: PBitStream;
begin
	bstream := QRinput_getBitStream(input);
	if bstream = nil then
  begin
    Result := nil;
    Exit;
  end;
	Result := BitStream_toByte(bstream);
	BitStream_free(bstream);
end;

{******************************************************************************
 * Structured input data
 *****************************************************************************}

function QRinput_InputList_newEntry(input: PQRinput): PQRinput_InputList;
begin
  try
    GetMem(Result, SizeOf(QRinput_InputList));
  except
    Result := nil;
    Exit;
  end;
	Result.input := input;
	Result.next := nil;
end;

procedure QRinput_InputList_freeEntry(entry: PQRinput_InputList);
begin
	if entry <> nil then
  begin
		QRinput_free(entry.input);
		FreeMem(entry);
	end;
end;

function QRinput_Struct_new(): PQRinput_Struct;
begin
  try
    GetMem(Result, SizeOf(QRinput_Struct));
  except
    Result := nil;
    Exit;
  end;
	Result.size := 0;
	Result.parity := -1;
	Result.head := nil;
	Result.tail := nil;
end;

procedure QRinput_Struct_setParity(s: PQRinput_Struct; parity: Byte);
begin
	s.parity := parity;
end;

function QRinput_Struct_appendInput(s: PQRinput_Struct; input: PQRinput): Integer;
var
  e: PQRinput_InputList;
begin
  Result := -1;
	if input.mqr <> 0 then
  begin
//		errno = EINVAL;
    Exit;
	end;

	e := QRinput_InputList_newEntry(input);
	if e = nil then
    Exit;

	Inc(s.size);
	if s.tail = nil then
  begin
		s.head := e;
		s.tail := e;
	end else begin
		s.tail.next := e;
		s.tail := e;
	end;

	Result := s.size;
end;

procedure QRinput_Struct_free(s: PQRinput_Struct);
var
  list, next: PQRinput_InputList;
begin	
	if s <> nil then
  begin
		list := s.head;
		while list <> nil do
    begin
			next := list.next;
			QRinput_InputList_freeEntry(list);
			list := next;
		end;
		FreeMem(s);
	end;
end;

function QRinput_Struct_calcParity(s: PQRinput_Struct): Byte;
var
  list: PQRinput_InputList;
begin
	Result := 0;

	list := s.head;
	while list <> nil do
  begin
		Result := Result xor QRinput_calcParity(list.input);
		list := list.next;
	end;
	QRinput_Struct_setParity(s, Result);
end;

function QRinput_List_shrinkEntry(entry: PQRinput_List; bytes: Integer): Integer;
var
  data: PByte;
begin
	try
    GetMem(data, bytes);
  except
    Result := -1;
    Exit;
  end;
  CopyMemory(data, entry.data, bytes);
	FreeMem(entry.data);
	entry.data := data;
	entry.size := bytes;    
	Result := 0;
end;

function QRinput_splitEntry(entry: PQRinput_List; bytes: Integer): Integer;
var
  e: PQRinput_List;
  ret: Integer;
begin
	e := QRinput_List_newEntry(entry.mode, entry.size - bytes,
    PIndex(entry.data, bytes));
	if e = nil then
  begin
		Result := -1;
    Exit;
  end;

	ret := QRinput_List_shrinkEntry(entry, bytes);
	if ret < 0 then
  begin
		QRinput_List_freeEntry(e);
		Result := -1;
    Exit;
	end;

	e.next := entry.next;
	entry.next := e;

	Result := 0;
end;

function QRinput_splitQRinputToStruct(input: PQRinput): PQRinput_Struct;
label
  done;
var
  p: PQRinput;
  s: PQRinput_Struct;
  bits, maxbits, nextbits, bytes, ret: Integer;
  list, next, prev: PQRinput_List;
begin
	if input.mqr <> 0 then
  begin
//		errno = EINVAL;
		Result := nil;
    Exit;
	end;

	s := QRinput_Struct_new();
	if s = nil then
  begin
    Result := nil;
    Exit;
  end;

	input := QRinput_dup(input);
	if input = nil then
  begin
		QRinput_Struct_free(s);
		Result := nil;
    Exit;
	end;

	QRinput_Struct_setParity(s, QRinput_calcParity(input));
	maxbits := QRspec_getDataLength(input.version, input.level) * 8
    - STRUCTURE_HEADER_SIZE;

	if maxbits <= 0 then
  begin
		QRinput_Struct_free(s);
		QRinput_free(input);
		Result := nil;
    Exit;
	end;

	bits := 0;
	list := input.head;
	prev := nil;
	while list <> nil do
  begin
		nextbits := QRinput_estimateBitStreamSizeOfEntry(list, input.version,
      input.mqr);
    if (bits + nextbits) <= maxbits then
    begin
			ret := QRinput_encodeBitStream(list, input.version, input.mqr);
			if ret < 0 then
        goto done;
			bits := bits + ret;
			prev := list;
			list := list.next;
		end else begin
			bytes := QRinput_lengthOfCode(list.mode, input.version, maxbits - bits);
			p := QRinput_new2(input.version, input.level);
			if p = nil then
        goto done;
			if bytes > 0 then
      begin
				{* Splits this entry into 2 entries. *}
				ret := QRinput_splitEntry(list, bytes);
				if ret < 0 then
        begin
					QRinput_free(p);
					goto done;
				end;
				{* First half is the tail of the current input. *}
				next := list.next;
				list.next := nil;
				{* Second half is the head of the next input, p.*}
				p.head := next;
				{* Renew QRinput.tail. *}
				p.tail := input.tail;
				input.tail := list;
				{* Point to the next entry. *}
				prev := list;
				list := next;
			end else begin
				{* Current entry will go to the next input. *}
				prev.next := nil;
				p.head := list;
				p.tail := input.tail;
				input.tail := prev;
			end;
			ret := QRinput_Struct_appendInput(s, input);
			if ret < 0 then
      begin
				QRinput_free(p);
				goto done;
			end;
			input := p;
			bits := 0;
		end;
	end;
	ret := QRinput_Struct_appendInput(s, input);
	if ret < 0 then
    goto done;
	if s.size > MAX_STRUCTURED_SYMBOLS then
  begin
		QRinput_Struct_free(s);
//		errno := ERANGE;
		Result := nil;
    Exit;
	end;
	ret := QRinput_Struct_insertStructuredAppendHeaders(s);
	if ret < 0 then
  begin
		QRinput_Struct_free(s);
		Result := nil;
    Exit;
	end;

	Result := s;
  Exit;

done:
	QRinput_free(input);
	QRinput_Struct_free(s);
	Result := nil;
end;

function QRinput_Struct_insertStructuredAppendHeaders(s: PQRinput_Struct): Integer;
var
  i, num: Integer;
  list: PQRinput_InputList;
begin
	if s.parity < 0 then
		QRinput_Struct_calcParity(s);

	num := 0;
	list := s.head;
	while list <> nil do
  begin
		Inc(num);
		list := list.next;
	end;
	i := 1;
	list := s.head;
	while list <> nil do
  begin
		if QRinput_insertStructuredAppendHeader(
      list.input, num, i, s.parity) <> 0 then
    begin
      Result := -1;
      Exit;
    end;
		Inc(i);
		list := list.next;
	end;

	Result := 0;
end;

{******************************************************************************
 * Extended encoding mode (FNC1 and ECI)
 *****************************************************************************}

function QRinput_setFNC1First(input: PQRinput): Integer;
begin
	if input.mqr <> 0 then
  begin
//		errno = EINVAL;
		Result := -1;
    Exit;
	end;
	input.fnc1 := 1;

	Result := 0;
end;

function QRinput_setFNC1Second(input: PQRinput; appid: Byte): Integer;
begin
	if input.mqr <> 0 then
  begin
//		errno = EINVAL;
		Result := -1;
    Exit;
	end;
	input.fnc1 := 2;
	input.appid := appid;

	Result := 0;
end;

end.
