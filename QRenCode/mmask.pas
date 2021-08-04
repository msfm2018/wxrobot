{*******************************************************************************

 * qrencode - QR Code encoder
 *
 * Masking for Micro QR Code.
 * This code is taken from Kentaro Fukuchi's mmask.h and
 * mmask.c then editted and packed into a .pas file.
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

unit mmask;

interface

uses
  SysUtils, struct;

function MMask_makeMask(version: Integer; frame: PByte; mask: Integer;
  level: QRecLevel): PByte;
function MMask_mask(version: Integer; frame: PByte; level: QRecLevel): PByte;
{$IFDEF WITH_TESTS}
procedure MMask_writeFormatInformation(version, width: Integer; frame: PByte;
  mask: Integer; level: QRecLevel);
function MMask_evaluateSymbol(width: Integer; frame: PByte): Integer;
function MMask_makeMaskedFrame(width: Integer; frame: PByte; mask: Integer): PByte;
{$ENDIF}

implementation

uses
  mqrspec;

const
  maskNum = 4;

type
  TMaskType = (mtMask0, mtMask1, mtMask2, mtMask3);

  TMaskMaker = procedure(width: Integer; const s: PByte; d: PByte);

procedure MMask_writeFormatInformation(version, width: Integer; frame: PByte;
  mask: Integer; level: QRecLevel);
var
  fr: Cardinal;
  v: Byte;
  i: Integer;
begin
  fr := MQRspec_getFormatInfo(mask, version, level);
  for i := 0 to 7 do
  begin
    v := $84 or (fr and 1);
    PIndex(frame, width * (i + 1) + 8)^ := v;
    fr := fr shr 1;
  end;
  for i := 0 to 6 do
  begin
    v := $84 or (fr and 1);
    PIndex(frame, width * 8 + 7 - i)^ := v;
    fr := fr shr 1;
  end;     
end;

procedure Mask_mask(width: Integer; s, d: PByte; mask: TMaskType);
var
  x, y: Integer;
  exp: Integer;
begin
  for y := 0 to width - 1 do
  begin
    for x := 0 to width - 1 do
    begin
      if (s^ and $80) <> 0 then
        d^ := s^
      else begin
        case mask of
          mtMask0: exp := y and 1;
          mtMask1: exp := ((y div 2) + (x div 3)) and 1;
          mtMask2: exp := (((x * y) and 1) + (x * y) mod 3) and 1;
          mtMask3: exp := (((x + y) and 1) + ((x * y) mod 3)) and 1;
        else
          exp := 0; 
        end;
        if exp = 0 then
          d^ := s^ xor 1
        else
          d^ := s^ xor 0;
      end;
      Inc(s);
      Inc(d);
    end;
  end;
end;

procedure Mask_mask0(width: Integer; const s: PByte; d: PByte);
begin
  Mask_mask(width, s, d, mtMask0);
end;

procedure Mask_mask1(width: Integer; const s: PByte; d: PByte);
begin
	Mask_mask(width, s, d, mtMask1);
end;

procedure Mask_mask2(width: Integer; const s: PByte; d: PByte);
begin
	Mask_mask(width, s, d, mtMask2);
end;

procedure Mask_mask3(width: Integer; const s: PByte; d: PByte);
begin
	Mask_mask(width, s, d, mtMask3);
end;

var
  maskMakers: array[0..maskNum - 1] of TMaskMaker = (
    Mask_mask0, Mask_mask1, Mask_mask2, Mask_mask3
  );

{$IFDEF WITH_TESTS}
function MMask_makeMaskedFrame(width: Integer; frame: PByte; mask: Integer): PByte;
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

function MMask_makeMask(version: Integer; frame: PByte; mask: Integer;
  level: QRecLevel): PByte;
var
  masked: PByte;
  width: Integer;
begin
  if (mask < 0) or (mask >= maskNum) then
  begin
    Result := nil;
    Exit;
  end;

  width := MQRspec_getWidth(version);
  try
    GetMem(masked, width * width);
  except
    Result := nil;
    Exit;
  end;
  maskMakers[mask](width, frame, masked);
  MMask_writeFormatInformation(version, width, masked, mask, level);
  Result := masked;
end;

function MMask_evaluateSymbol(width: Integer; frame: PByte): Integer;
var
  x, y: Integer;
  p: PByte;
  sum1, sum2: Integer;
begin
  sum1 := 0;
  sum2 := 0;

  p := PIndex(frame, width * (width - 1));
  for x := 1 to width - 1 do
    sum1 := sum1 + (PIndex(p, x)^ and 1);

  p := PIndex(frame, width * 2 - 1);
  for y := 1 to width - 1 do
  begin
    sum2 := sum2 + (p^ and 1);
    Inc(p, width);
  end;
  if sum1 <= sum2 then
    Result := sum1 * 16 + sum2
  else
    Result := sum2 * 16 + sum1;
end;

function MMask_mask(version: Integer; frame: PByte; level: QRecLevel): PByte;
var
  i, score, width, maxScore: Integer;
  mask, bestMask: PByte;
begin
  maxScore := 0;
  width := MQRspec_getWidth(version);

  try
    GetMem(mask, width * width);
  except
    Result := nil;
    Exit;
  end;
  bestMask := nil;
  for i := 0 to maskNum - 1 do
  begin
    maskMakers[i](width, frame, mask);
    MMask_writeFormatInformation(version, width, mask, i, level);
    score := MMask_evaluateSymbol(width, mask);
    if score > maxScore then
    begin
      maxScore := score;
      if bestMask <> nil then
        FreeMem(bestMask);
      bestMask := mask;
      try
        GetMem(mask, width * width);
      except
        Break;
      end;
    end;
  end;
  FreeMem(mask);
  Result := bestMask;
end;

end.
