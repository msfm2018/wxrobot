{*******************************************************************************

 * qrencode - QR Code encoder
 *
 * Input data splitter.
 * This code is taken from Kentaro Fukuchi's split.h and
 * split.c then editted and packed into a .pas file.
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

unit split;

interface

uses
  Windows, struct, SysUtils, Classes, qrinput, qrspec;

{**
 * Split the input string (null terminated) into QRinput.
 * @param string input string
 * @param hint give QR_MODE_KANJI if the input string contains Kanji character encoded in Shift-JIS. If not, give QR_MODE_8.
 * @param casesensitive 0 for case-insensitive encoding (all alphabet characters are replaced to UPPER-CASE CHARACTERS.
 * @retval 0 success.
 * @retval -1 an error occurred. errno is set to indicate the error. See
 *               Exceptions for the details.
 * @throw EINVAL invalid input object.
 * @throw ENOMEM unable to allocate memory for input objects.
 *}
function Split_splitStringToQRinput(const str: PAnsiChar; input: PQRinput;
  hint: QRencodeMode; casesensitive: Integer): Integer;

implementation

function isdigit(c: AnsiChar): Boolean;
begin
  Result := Byte(Byte(c) - Byte('0')) < 10;
end;

function isalnum(c: AnsiChar): Boolean;
begin
  Result := QRinput_lookAnTable(Byte(c)) >= 0;
end;

function Split_identifyMode(const str: PAnsiChar; hint: QRencodeMode): QRencodeMode;
var
  c, d: AnsiChar;
  word: Cardinal;
begin
  Result := QR_MODE_8;
  c := str^;
  if c = #0 then
    Result := QR_MODE_NUL
  else if isdigit(c) then
    Result := QR_MODE_NUM
  else if isalnum(c) then
    Result := QR_MODE_AN
  else if hint = QR_MODE_KANJI then
  begin
    d := PIndex(str, 1)^;
    if d <> #0 then
    begin
      word := (Byte(c) shl 8) or Byte(d);
      if ((word >= $8140) and (word <= $9ffc))
        or ((word >= $e040) and (word <= $ebbf)) then
      begin
        Result := QR_MODE_KANJI;
      end;
    end;
  end;
end;

function Split_eat8(const str: PAnsiChar; input: PQRinput;
  hint: QRencodeMode): Integer;
var
  p, q: PAnsiChar;
  mode: QRencodeMode;
  ret, run, dif, la, ln, l8, swcost: Integer;
begin
	la := QRspec_lengthIndicator(QR_MODE_AN, input.version);
	ln := QRspec_lengthIndicator(QR_MODE_NUM, input.version);
	l8 := QRspec_lengthIndicator(QR_MODE_8, input.version);
  p := PIndex(str, 1);
  while p^ <> #0 do
  begin
    mode := Split_identifyMode(p, hint);
    if mode = QR_MODE_KANJI then
      Break;
    if mode = QR_MODE_NUM then
    begin
      q := p;
      while isdigit(q^) do
        Inc(q);

      if Split_identifyMode(q, hint) = QR_MODE_8 then
        swcost := 4 + l8
      else
        swcost := 0;
      dif := QRinput_estimateBitsMode8(p - str) //* + 4 + l8 */
				+ QRinput_estimateBitsModeNum(q - p) + 4 + ln
				+ swcost
				- QRinput_estimateBitsMode8(q - str); //* - 4 - l8 */
      if dif < 0 then
        Break
      else
        p := q;
    end else if mode = QR_MODE_AN then
    begin
      q := p;
      while isalnum(q^) do
        Inc(q);
      if Split_identifyMode(q, hint) = QR_MODE_8 then
        swcost := 4 + l8
      else
        swcost := 0;
      dif := QRinput_estimateBitsMode8(p - str) //* + 4 + l8 */
				+ QRinput_estimateBitsModeAn(q - p) + 4 + la
				+ swcost
				- QRinput_estimateBitsMode8(q - str); //* - 4 - l8 */
      if dif < 0 then
        Break
      else
        p := q;
    end else begin
      Inc(p);
    end;
  end;
  run := p - str;
	ret := QRinput_append(input, QR_MODE_8, run, PByte(str));
	if ret < 0 then
    Result := -1
  else
    Result := run;
end;

function Split_eatAn(const str: PAnsiChar; input: PQRinput;
  hint: QRencodeMode): Integer;
var
  p, q: PAnsiChar;
  ret, run, dif, la, ln, temp: Integer;
begin
  la := QRspec_lengthIndicator(QR_MODE_AN, input.version);
  ln := QRspec_lengthIndicator(QR_MODE_NUM, input.version);

  p := str;
  while isalnum(p^) do
  begin
    if isdigit(p^) then
    begin
      q := p;
      while isdigit(q^) do
        Inc(q);
      if isalnum(q^) then
        temp := 4 + ln
      else
        temp := 0;
      dif := QRinput_estimateBitsModeAn(p - str) //* + 4 + la */
				+ QRinput_estimateBitsModeNum(q - p) + 4 + ln
				+ temp
				- QRinput_estimateBitsModeAn(q - str); //* - 4 - la */
      if dif < 0 then
        Break
      else
        p := q;
    end else begin
      Inc(p);
    end;
  end;
  run := p - str;
  if (p^ <> #0) and (not isalnum(p^)) then
  begin
    dif := QRinput_estimateBitsModeAn(run) + 4 + la
			+ QRinput_estimateBitsMode8(1) //* + 4 + l8 */
			- QRinput_estimateBitsMode8(run + 1); //* - 4 - l8 */
    if dif < 0 then
    begin
      Result := Split_eat8(str, input, hint);
      Exit;
    end;
  end;
  ret := QRinput_append(input, QR_MODE_AN, run, PByte(str));
  if ret < 0 then
    Result := -1
  else
    Result := run;
end;

function Split_eatKanji(const str: PAnsiChar; input: PQRinput;
  hint: QRencodeMode): Integer;
var
  p: PAnsiChar;
  ret, run: Integer;
begin
  p := str;
  while Split_identifyMode(p, hint) = QR_MODE_KANJI do
    Inc(p, 2);

  run := p - str;
  ret := QRinput_append(input, QR_MODE_KANJI, run, PByte(str));
  if ret < 0 then
    Result := -1
  else
    Result := run;
end;

function Split_eatNum(const str: PAnsiChar; input: PQRinput;
  hint: QRencodeMode): Integer;
var
  p: PAnsiChar;
  ret, run, dif, ln: Integer;
  mode: QRencodeMode;
begin
  ln := QRspec_lengthIndicator(QR_MODE_NUM, input.version);
  p := str;
  while isdigit(p^) do
    Inc(p);
  run := p - str;
  mode := Split_identifyMode(p, hint);
  if mode = QR_MODE_8 then
  begin
    dif := QRinput_estimateBitsModeNum(run) + 4 + ln
			+ QRinput_estimateBitsMode8(1) //* + 4 + l8 */
			- QRinput_estimateBitsMode8(run + 1); //* - 4 - l8 */
    if dif > 0 then
    begin
      Result := Split_eat8(str, input, hint);
      Exit;
    end;
  end;
  if (mode = QR_MODE_AN) then
  begin
		dif := QRinput_estimateBitsModeNum(run) + 4 + ln
			+ QRinput_estimateBitsModeAn(1) //* + 4 + la */
			- QRinput_estimateBitsModeAn(run + 1); //* - 4 - la */
		if (dif > 0) then
    begin
			Result := Split_eatAn(str, input, hint);
      Exit;
		end;
	end;
  ret := QRinput_append(input, QR_MODE_NUM, run, PByte(str));
  if ret < 0 then
    Result := -1
  else
    Result := run;
end;

function Split_splitString(const str: PAnsiChar; input: PQRinput;
  hint: QRencodeMode): Integer;
var
  len: Integer;
  mode: QRencodeMode;
begin
	if str^ = #0 then
  begin
    Result := 0;
    Exit;
  end;

	mode := Split_identifyMode(str, hint);
	if mode = QR_MODE_NUM then
  begin
		len := Split_eatNum(str, input, hint);
	end else if mode = QR_MODE_AN then
  begin
		len := Split_eatAn(str, input, hint);
	end else if (mode = QR_MODE_KANJI) and (hint = QR_MODE_KANJI) then
  begin
		len := Split_eatKanji(str, input, hint);
	end else begin
		len := Split_eat8(str, input, hint);
	end;
	if len = 0 then
    Result := 0
	else if len < 0 then
    Result := -1
  else begin
	  Result := Split_splitString(PIndex(str, len), input, hint);
  end;
end;

function dupAndToUpper(const str: PAnsiChar; hint: QRencodeMode): PAnsiChar;
var
  newstr, p: PAnsiChar;
  mode: QRencodeMode;
begin
	newstr := strdup(str);
	if newstr = nil then
  begin
    Result := nil;
    Exit;
  end;

	p := newstr;
	while p^ <> #0 do
  begin
		mode := Split_identifyMode(p, hint);
		if mode = QR_MODE_KANJI then
			Inc(p, 2)
		else begin
			if (p^ >= 'a') and (p^ <= 'z') then
				p^ := AnsiChar(Ord(p^) - 32);
			Inc(p);
		end;
	end;        
	Result := newstr;
end;

function Split_splitStringToQRinput(const str: PAnsiChar; input: PQRinput;
  hint: QRencodeMode; casesensitive: Integer): Integer;
var
  newstr: PAnsiChar;
  ret: Integer;
begin
  if (str = nil) or (str^ = #0) then
  begin
    Result := -1;
    Exit;
  end;
  if casesensitive = 0 then
  begin
    newstr := dupAndToUpper(str, hint);
    if newstr = nil then
    begin
      Result := -1;
      Exit;
    end;
    ret := Split_splitString(newstr, input, hint);
    FreeMem(newstr);
  end else begin
    ret := Split_splitString(str, input, hint);
  end;
  Result := ret;
end;

end.
