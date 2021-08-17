{*******************************************************************************

 * qrencode - QR Code encoder
 *
 * Binary sequence class.
 * This code is taken from Kentaro Fukuchi's bitstream.h and
 * bitstream.c then editted and packed into a .pas file.
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


unit bitstream;

interface

uses
  Windows, struct;

function BitStream_new(): PBitStream;
function BitStream_append(bstream, arg: PBitStream): Integer;
function BitStream_appendNum(bstream: PBitStream; bits: Integer;
  num: Cardinal): Integer;
function BitStream_appendBytes(bstream: PBitStream; size: Integer;
  data: PByte): Integer;
function BitStream_size(bstream: PBitStream): Integer;
function BitStream_toByte(bstream: PBitStream): PByte;
procedure BitStream_free(var bstream: PBitStream);

implementation

procedure BitStream_freeData(bstream: PBitStream);
begin
  if (bstream <> nil) and (bstream.data <> nil) then
  begin
    FreeMem(bstream.data, bstream.length);
    bstream.data := nil;
    bstream.length := 0;
  end;
end;

function BitStream_new(): PBitStream;
begin
  try
    GetMem(Result, SizeOf(TBitStream));
  except
    Result := nil;
  end;
  Result.length := 0;
  Result.data := nil;
end;

function BitStream_allocate(bstream: PBitStream; length: Integer): Integer;
begin
  Result := -1;
  if bstream = nil then
    Exit;
  BitStream_freeData(bstream);

  try
    GetMem(bstream.data, length);
    bstream.length := length;
    Result := 0;
  except
  end;
end;

function BitStream_size(bstream: PBitStream): Integer;
begin
  Result := bstream.length;
end;

function BitStream_newFromNum(bits: Integer; num: Cardinal): PBitStream;
var
  mask: Cardinal;
  i: Integer;
  p: PByte;
begin
  Result := BitStream_new();
  if (Result = nil) then
    Exit;
  if (BitStream_allocate(Result, bits) <> 0) then
  begin
    BitStream_free(Result);
    Exit;
  end;
  p := Result.data;
  mask := 1 shl (bits - 1);
  for i := 0 to bits - 1 do
  begin
    if (num and mask) <> 0 then
      p^ := 1
    else
      p^ := 0;
    Inc(p);
    mask := mask shr 1;
  end;
end;

function BitStream_newFromBytes(size: Integer; data: PByte): PBitStream;
var
  mask: Byte;
  i, j: Integer;
  p: PByte;
begin
  Result := BitStream_new();
  if (Result = nil) then  Exit;

  if (BitStream_allocate(Result, size * 8) <> 0) then
  begin
    BitStream_free(Result);
    Exit;
  end;

  p := Result.data;
  for i := 0 to size - 1 do
  begin
    mask := $80;
    for j := 0 to 7 do
    begin
      if (PIndex(data, i)^ and mask) <> 0 then
        p^ := 1
      else
        p^ := 0;
      Inc(p);
      mask := mask shr 1;
    end;
  end;
end;

function BitStream_append(bstream, arg: PBitStream): Integer;
var
  data, p: PByte;
  iLen: Integer;
begin
  Result := -1;
  if arg = nil then
    Exit;

  if arg.length = 0 then
  begin
    Result := 0;
    Exit;
  end;
  if (bstream.length = 0) then
  begin
    if (BitStream_allocate(bstream, arg.length) <> 0) then
      Exit;

    CopyMemory(bstream.data, arg.data, arg.length);
    Result := 0;
    Exit;
  end;
  try
    GetMem(data, bstream.length + arg.length);
  except
    Exit;
  end;
  p := data;
  CopyMemory(data, bstream.data, bstream.length);
  Inc(p, bstream.length);
  CopyMemory(p, arg.data, arg.length);
  iLen := bstream.length + arg.length;
  BitStream_freeData(bstream);
  bstream.length := iLen;
  bstream.data := data;
  Result := 0;
end;

function BitStream_appendNum(bstream: PBitStream; bits: Integer;
  num: Cardinal): Integer;
var
  pbs: PBitStream;
begin
  if (bits = 0) then
  begin
    Result := 0;
    Exit;
  end;
  pbs := BitStream_newFromNum(bits, num);
  if (pbs = nil) then
  begin
    Result := -1;
    Exit;
  end;
  Result := BitStream_append(bstream, pbs);
  BitStream_free(pbs);
end;

function BitStream_appendBytes(bstream: PBitStream; size: Integer;
  data: PByte): Integer;
var
  pbs: PBitStream;
begin
  if (size = 0) then
  begin
    Result := 0;
    Exit;
  end;
  pbs := BitStream_newFromBytes(size, data);
  if (pbs = nil) then
  begin
    Result := -1;
    Exit;
  end;
  Result := BitStream_append(bstream, pbs);
  BitStream_free(pbs);
end;

function BitStream_toByte(bstream: PBitStream): PByte;
var
  i, j, size, bytes: Integer;
  data, p: PByte;
  v: Byte;
begin
  size := BitStream_size(bstream);
  if (size = 0) then
  begin
    Result := nil;
    Exit;
  end;
  try
    GetMem(data, (size + 7) div 8);
  except
    Result := nil;
    Exit;
  end;
  bytes := size div 8;
  p := bstream.data;
  for i := 0 to bytes - 1 do
  begin
    v := 0;
    for j := 0 to 7 do
    begin
      v := v shl 1;
      v := v or p^;
      Inc(p);
    end;
    PIndex(data, i)^ := v;
  end;
  if ((size and 7) <> 0) then
  begin
    v := 0;
    for j := 0 to (size and 7) - 1 do
    begin
      v := v shl 1;
      v := v or p^;
      Inc(p);
    end;
    PIndex(data, bytes)^ := v;
  end;
  Result := data;
end;

procedure BitStream_free(var bstream: PBitStream);
begin
  if (bstream <> nil) then
  begin
    BitStream_freeData(bstream);
    FreeMem(bstream, SizeOf(TBitStream));
    bstream := nil;
  end;
end;

end.
