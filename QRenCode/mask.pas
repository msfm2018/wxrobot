{*******************************************************************************

 * qrencode - QR Code encoder
 *
 * Masking.
 * This code is taken from Kentaro Fukuchi's mask.h and
 * mask.c then editted and packed into a .pas file.
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

unit mask;

interface

uses
  Windows, SysUtils, struct;

function Mask_makeMask(width: Integer; frame: PByte; mask: Integer;
  level: QRecLevel): PByte;

function Mask_mask(width: Integer; frame: PByte; level: QRecLevel): PByte;

{$IFDEF WITH_TESTS}
function Mask_calcN2(width: Integer; frame: PByte): Integer;
function Mask_calcN1N3(len: Integer; runLength: PInteger): Integer;
function Mask_calcRunLength(width: Integer; frame: PByte; dir: Integer;
  runLength: PInteger): Integer;
function Mask_evaluateSymbol(width: Integer; frame: PByte): Integer;
function Mask_writeFormatInformation(width: Integer; frame: PByte; mask: Integer;
  level: QRecLevel): Integer;
function Mask_makeMaskedFrame(width: Integer; frame: PByte; mask: Integer): PByte;
{$ENDIF}

implementation

uses
  qrspec;

function Mask_writeFormatInformation(width: Integer; frame: PByte;
  mask: Integer; level: QRecLevel): Integer;
var
  fr: Cardinal;
  v: Byte;
  i: Integer;
begin
  Result := 0;
  fr := QRspec_getFormatInfo(mask, level);
  for i := 0 to 7 do
  begin
    if (fr and 1) <> 0 then
    begin
      Result := Result + 2;
      v := $85;
    end else begin
      v := $84;
    end;
    PIndex(frame, width * 8 + width - 1 - i)^ := v;
    if i < 6 then
      PIndex(frame, width * i + 8)^ := v
    else
      PIndex(frame, width * (i + 1) + 8)^ := v;
    fr := fr shr 1;
  end;
  for i := 0 to 6 do
  begin
    if (fr and 1) <> 0 then
    begin
      Result := Result + 2;
      v := $85;
    end else begin
      v := $84;
    end;
    PIndex(frame, width * (width - 7 + i) + 8)^ := v;
    if i = 0 then
			PIndex(frame, width * 8 + 7)^ := v
		else
			PIndex(frame, width * 8 + 6 - i)^ := v;
    fr := fr shr 1;
  end;
end;

type
  TMaskType = (
    mtMask0, mtMask1, mtMask2, mtMask3,
    mtMask4, mtMask5, mtMask6, mtMask7
  );
  TMaskMaker = function(width: Integer; const s: PByte; d: PByte): Integer;

{**
 * Demerit coefficients.
 * See Section 8.8.2, pp.45, JIS X0510:2004.
 *}
const
  N1 = 3;
  N2 = 3;
  N3 = 40;
  N4 = 10;

  maskNum = 8;

function Mask_Maker(width: Integer; s, d: PByte; mask: TMaskType): Integer;
var
  x, y: Integer;
  express: Integer;
begin
  Result := 0;
  for y := 0 to width - 1 do
  begin
    for x := 0 to width - 1 do
    begin
      if (s^ and $80) <> 0 then
        d^ := s^
      else begin
        case mask of
          mtMask0: express := (x + y) and 1;
          mtMask1: express := y and 1;
          mtMask2: express := x mod 3;
          mtMask3: express := (x + y) mod 3;
          mtMask4: express := ((y div 2) + (x div 3)) and 1;
          mtMask5: express := ((x * y) and 1) + (x * y) mod 3;
          mtMask6: express := (((x * y) and 1) + (x * y) mod 3) and 1;
          mtMask7: express := (((x * y) mod 3) + ((x + y) and 1)) and 1;
        else
          express := 0;
        end;
        if express = 0 then
          d^ := s^ xor 1
        else
          d^ := s^ xor 0;
      end;
      Result := Result + (d^ and 1);
      Inc(s);
      Inc(d);
    end;
  end;
end;

function Mask_mask0(width: Integer; const s: PByte; d: PByte): Integer;
begin
	Result := Mask_Maker(width, s, d, mtMask0);
end;

function Mask_mask1(width: Integer; const s: PByte; d: PByte): Integer;
begin
	Result := Mask_Maker(width, s, d, mtMask1);
end;

function Mask_mask2(width: Integer; const s: PByte; d: PByte): Integer;
begin
	Result := Mask_Maker(width, s, d, mtMask2);
end;

function Mask_mask3(width: Integer; const s: PByte; d: PByte): Integer;
begin
	Result := Mask_Maker(width, s, d, mtMask3);
end;

function Mask_mask4(width: Integer; const s: PByte; d: PByte): Integer;
begin
	Result := Mask_Maker(width, s, d, mtMask4);
end;

function Mask_mask5(width: Integer; const s: PByte; d: PByte): Integer;
begin
	Result := Mask_Maker(width, s, d, mtMask5);
end;

function Mask_mask6(width: Integer; const s: PByte; d: PByte): Integer;
begin
	Result := Mask_Maker(width, s, d, mtMask6);
end;

function Mask_mask7(width: Integer; const s: PByte; d: PByte): Integer;
begin
	Result := Mask_Maker(width, s, d, mtMask7);
end;

var
  maskMakers: array[0..maskNum - 1] of TMaskMaker = (
    Mask_mask0, Mask_mask1, Mask_mask2, Mask_mask3,
    Mask_mask4, Mask_mask5, Mask_mask6, Mask_mask7
  );

{$IFDEF WITH_TESTS}
function Mask_makeMaskedFrame(width: Integer; frame: PByte; mask: Integer): PByte;
var
  masked: PByte;
begin
  try
    GetMem(masked, width * width);
  except
    Result := nil;
    Exit;
  end;
  maskMakers[mask](width, frame, masked);
  Result := masked;
end;
{$ENDIF}

function Mask_makeMask(width: Integer; frame: PByte; mask: Integer;
  level: QRecLevel): PByte;
var
  masked: PByte;
begin
  if (mask < 0) or (mask >= maskNum) then
  begin
    Result := nil;
    Exit;
  end;

  try
    GetMem(masked, width * width);
  except
    Result := nil;
    Exit;
  end;
  maskMakers[mask](width, frame, masked);
  Mask_writeFormatInformation(width, masked, mask, level);
  Result := masked;
end;

function Mask_calcN1N3(len: Integer; runLength: PInteger): Integer;
var
  i, fact: Integer;
  run: PIntegerArray;
begin
  Result := 0;
  run := PIntegerArray(runLength);
  for i := 0 to len - 1 do
  begin
    if run[i] >= 5 then
    begin
      Result := Result + N1 + (run[i] - 5);
    end;
    if (i and 1) <> 0 then
    begin
      if (i >= 3) and (i < len - 2) and (run[i] mod 3 = 0) then
      begin
        fact := run[i] div 3;
        if ((run[i - 2] = fact) and
          (run[i - 1] = fact) and
          (run[i + 1] = fact) and
          (run[i + 2] = fact)) then
        begin
          if (i = 3) or (run[i - 3] >= (4 * fact)) then
            Result := Result + N3
          else if ((i + 4) >= len) or (run[i + 3] >= (4 * fact)) then
            Result := Result + N3;
        end;
      end;
    end;
  end;
end;

function Mask_calcN2(width: Integer; frame: PByte): Integer;
var
  x, y: Integer;
  p, p1, p2, p3: PByte;
  b22, w22: Byte;
begin
  Result := 0;

  p := PIndex(frame, width + 1);
  for y := 1 to width - 1 do
  begin
    for x := 1 to width - 1 do
    begin
      p1 := PIndex(p, -1);
      p2 := PIndex(p, -width);
      p3 := PIndex(p, -width - 1);
      b22 := p^ and p1^ and p2^ and p3^;
      w22 := p^ or  p1^ or  p2^ or  p3^;
      if ((b22 or (w22 xor 1)) and 1) <> 0 then
        Result := Result + N2;
      Inc(p);
    end;
    Inc(p);
  end;
end;

function Mask_calcRunLength(width: Integer; frame: PByte; dir: Integer;
  runLength: PInteger): Integer;
var
  i, pitch: Integer;
  p, p1: PByte;
  run: PIntegerArray;
begin
  run := PIntegerArray(runLength);
  if dir = 0 then
    pitch := 1
  else
    pitch := width;
  if (frame^ and 1) <> 0 then
  begin
    run[0] := -1;
    Result := 1;
  end else begin
    Result := 0;
  end;
  run[Result] := 1;
  p := PIndex(frame, pitch);

  for i := 1 to width - 1 do
  begin
    p1 := PIndex(p, -pitch);
    if ((p^ xor p1^) and 1) <> 0 then
    begin
      Inc(Result);
      run[Result] := 1;
    end else begin
      run[Result] := run[Result] + 1;
    end;
    Inc(p, pitch);
  end;
  Result := Result + 1;
end;

function Mask_evaluateSymbol(width: Integer; frame: PByte): Integer;
var
  x, y, len: Integer;
  runLength: array[0..QRSPEC_VERSION_MAX] of Integer;
begin
  Result := Mask_calcN2(width, frame);
  for y := 0 to width - 1 do
  begin
    len := Mask_calcRunLength(width, PIndex(frame, y * width), 0, @runLength);
		Result := Result + Mask_calcN1N3(len, @runLength);
  end;
  for x := 0 to width - 1 do
  begin
    len := Mask_calcRunLength(width, PIndex(frame, x), 1, @runLength);
		Result := Result + Mask_calcN1N3(len, @runLength);
  end;
end;

function Mask_mask(width: Integer; frame: PByte; level: QRecLevel): PByte;
var
  i, blacks, bratio, demerit, w2, minDemerit: Integer;
  mask, bestMask: PByte;
begin
  minDemerit := MaxInt;
  w2 := width * width;
  try
    GetMem(mask, w2);
  except
    Result := nil;
    Exit;
  end;
  bestMask := nil;

  for i := 0 to maskNum - 1 do
  begin
    blacks := maskMakers[i](width, frame, mask);
    blacks := blacks + Mask_writeFormatInformation(width, mask, i, level);
    bratio := (200 * blacks + w2) div w2 div 2;  //* (int)(100*blacks/w2+0.5) */
    demerit := (Abs(bratio - 50) div 5) * N4;
    demerit := demerit + Mask_evaluateSymbol(width, mask);
    if demerit < minDemerit then
    begin
      minDemerit := demerit;
      if bestMask <> nil then
        FreeMem(bestMask);
      bestMask := mask;
      try
        GetMem(mask, w2);
      except
        Break;
      end;
    end;
  end;
  FreeMem(mask);
  Result := bestMask;
end;

end.
