{*******************************************************************************

 * qrencode - QR Code encoder
 *
 * Reed solomon encoder. This code is taken from Kentaro Fukuchi's rscode.h and
 * rscode.c then editted and packed into a .pas file.
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

unit rscode;

interface

uses
  Windows, SysUtils, struct;

{*
 * General purpose RS codec, 8-bit symbols.
 *}

function init_rs(symsize, gfpoly, fcr, prim, nroots, pad: Integer): PRS;
procedure encode_rs_char(rs: PRS; const data: PData_t; parity: PData_t);
procedure free_rs_char(rs: PRS);
procedure free_rs_cache();

implementation

var
  rslist: PRS;

function modnn(rs: PRS; x: Integer): Integer;
begin
  while (x >= rs.nn) do
  begin
    x := x - rs.nn;
    x := (x shr rs.mm) + (x and rs.nn);
  end;
  Result := x;
end;

//#define MM (rs->mm)
//#define NN (rs->nn)
//#define ALPHA_TO (rs->alpha_to)
//#define INDEX_OF (rs->index_of)
//#define GENPOLY (rs->genpoly)
//#define NROOTS (rs->nroots)
//#define FCR (rs->fcr)
//#define PRIM (rs->prim)
//#define IPRIM (rs->iprim)
//#define PAD (rs->pad)
//#define A0 (NN)

{* Initialize a Reed-Solomon codec
 * symsize = symbol size, bits
 * gfpoly = Field generator polynomial coefficients
 * fcr = first root of RS code generator polynomial, index form
 * prim = primitive element to generate polynomial roots
 * nroots = RS code generator polynomial degree (number of roots)
 * pad = padding bytes at front of shortened block
 *}
function init_rs_char(symsize, gfpoly, fcr, prim, nroots, pad: Integer): PRS;
var
  i, j, sr, root, iprim: Integer;
  index_of, alpha_to, genpoly: PByteArray;
begin
{* Common code for intializing a Reed-Solomon control block (char or int symbols)
 * Copyright 2004 Phil Karn, KA9Q
 * May be used under the terms of the GNU Lesser General Public License (LGPL)
 *}
//#undef NULL
//#define NULL ((void *)0)
  Result := nil;
  {* Check parameter ranges *}
  if (symsize < 0) or (symsize > SizeOf(data_t) * 8) then
    Exit;
  if (fcr < 0) or (fcr >= (1 shl symsize)) then
    Exit;
  if (prim <= 0) or (prim >= (1 shl symsize)) then
    Exit;
  if (nroots < 0) or (nroots >= (1 shl symsize)) then
    Exit;
  if (pad < 0) or (pad >= ((1 shl symsize) - 1 - nroots)) then
    Exit;

  try
    GetMem(Result, SizeOf(TRS));
    ZeroMemory(Result, SizeOf(TRS));
  except
    Exit;
  end;
  Result.mm := symsize;
  Result.nn := (1 shl symsize) - 1;
  Result.pad := pad;
  try
    GetMem(Result.alpha_to, SizeOf(data_t) * (Result.nn + 1));
  except
    FreeMem(Result);
    Result := nil;
    Exit;
  end;
  try
    GetMem(Result.index_of, SizeOf(data_t) * (Result.nn + 1));
  except
    FreeMem(Result.alpha_to);
    FreeMem(Result);
    Result := nil;
    Exit;
  end;
  index_of := PByteArray(Result.index_of);
  alpha_to := PByteArray(Result.alpha_to);
  {* Generate Galois field lookup tables *}
  {* log(zero) = -inf *}
  index_of[0] := Result.nn;
  {* alpha**-inf = 0 *}
  alpha_to[Result.nn] := 0;

  sr := 1;
  for i := 0 to Result.nn - 1 do
  begin
    index_of[sr] := i;
    alpha_to[i] := sr;
    sr := sr shl 1;
    if (sr and (1 shl symsize) <> 0) then
      sr := sr xor gfpoly;
    sr := sr and Result.nn;
  end;
  if (sr <> 1) then
  begin
    {* field generator polynomial is not primitive! *}
    FreeMem(Result.alpha_to);
    FreeMem(Result.index_of);
    FreeMem(Result);
    Result := nil;
    Exit;
  end;
  try
    {* Form RS code generator polynomial from its roots *}
    GetMem(Result.genpoly, SizeOf(data_t) * (nroots + 1));
    genpoly := PByteArray(Result.genpoly);
  except
    FreeMem(Result.alpha_to);
    FreeMem(Result.index_of);
    FreeMem(Result);
    Result := nil;
    Exit;
  end;
  Result.fcr := fcr;
  Result.prim := prim;
  Result.nroots := nroots;
  Result.gfpoly := gfpoly;
  {* Find prim-th root of 1, used in decoding *}
  iprim := 1;
  while (iprim mod prim <> 0) do
    iprim := iprim + Result.nn;
  Result.iprim := iprim div prim;

  genpoly[0] := 1;
  root := fcr * prim;
  for i := 0 to nroots - 1 do
  begin
    genpoly[i + 1] := 1;

    {* Multiply rs->genpoly[] by  @**(root + x) *}
    for j := i downto 1 do
    begin
      if genpoly[j] <> 0 then
        genpoly[j] := genpoly[j - 1]
          xor alpha_to[modnn(Result, index_of[genpoly[j]] + root)]
      else
        genpoly[j] := genpoly[j - 1];
    end;
    {* rs->genpoly[0] can never be zero *}
    genpoly[0] := alpha_to[modnn(Result, index_of[genpoly[0]] + root)];
    root := root + prim;
  end;
  {* convert rs->genpoly[] to index form for quicker encoding *}
  for i := 0 to nroots do
    genpoly[i] := index_of[genpoly[i]];
end;

function init_rs(symsize, gfpoly, fcr, prim, nroots, pad: Integer): PRS;
var
  rs: PRS;
begin
  rs := rslist;
  while rs <> nil do
  begin
		if(rs.pad = pad) and (rs.nroots = nroots) and (rs.prim = prim)
      and (rs.mm = symsize) and (rs.gfpoly = gfpoly) and (rs.fcr = fcr) then
		begin
      Result := rs;
      Exit;
    end;
    rs := rs.next;
  end;
  rs := init_rs_char(symsize, gfpoly, fcr, prim, nroots, pad);
  if rs = nil then
  begin
    Result := nil;
    Exit;
  end;
  rs.next := rslist;
  rslist := rs;
  Result := rs;
end;

procedure free_rs_char(rs: PRS);
begin
  if rs <> nil then
  begin
    if rs.alpha_to <> nil then
      FreeMem(rs.alpha_to);
    if rs.index_of <> nil then
      FreeMem(rs.index_of);
    if rs.genpoly <> nil then
      FreeMem(rs.genpoly);
    FreeMem(rs);
  end;
end;

procedure free_rs_cache();
var
  rs, next: PRS;
begin
  rs := rslist;
  while (rs <> nil) do
  begin
    next := rs.next;
    free_rs_char(rs);
    rs := next;
  end;
  rslist := nil;
end;

{* The guts of the Reed-Solomon encoder, meant to be #included
 * into a function body with the following typedefs, macros and variables supplied
 * according to the code parameters:

 * data_t - a typedef for the data symbol
 * data_t data[] - array of NN-NROOTS-PAD and type data_t to be encoded
 * data_t parity[] - an array of NROOTS and type data_t to be written with parity symbols
 * NROOTS - the number of roots in the RS code generator polynomial,
 *          which is the same as the number of parity symbols in a block.
            Integer variable or literal.
	    * 
 * NN - the total number of symbols in a RS block. Integer variable or literal.
 * PAD - the number of pad symbols in a block. Integer variable or literal.
 * ALPHA_TO - The address of an array of NN elements to convert Galois field
 *            elements in index (log) form to polynomial form. Read only.
 * INDEX_OF - The address of an array of NN elements to convert Galois field
 *            elements in polynomial form to index (log) form. Read only.
 * MODNN - a function to reduce its argument modulo NN. May be inline or a macro.
 * GENPOLY - an array of NROOTS+1 elements containing the generator polynomial in index form

 * The memset() and memmove() functions are used. The appropriate header
 * file declaring these functions (usually <string.h>) must be included by the calling
 * program.

 * Copyright 2004, Phil Karn, KA9Q
 * May be used under the terms of the GNU Lesser General Public License (LGPL)
 *}

procedure encode_rs_char(rs: PRS; const data: PData_t; parity: PData_t);
var
  i, j: Integer;
  feedback: data_t;
  index_of, data_a, parity_a, alpha_to, genpoly: PByteArray;
begin
  data_a := PByteArray(data);
  parity_a := PByteArray(parity);
  index_of := PByteArray(rs.index_of);
  alpha_to := PByteArray(rs.alpha_to);
  genpoly := PByteArray(rs.genpoly);
  ZeroMemory(parity, rs.nroots * SizeOf(data_t));
  for i := 0 to rs.nn - rs.nroots - rs.pad - 1 do
  begin
    feedback := index_of[data_a[i] xor parity_a[0]];
    if feedback <> rs.nn then   {* feedback term is non-zero *}
    begin
      {$IFDEF UNNORMALIZED}
      {* This line is unnecessary when GENPOLY[NROOTS] is unity, as it must
       * always be for the polynomials constructed by init_rs()
       *}
      feedback := modnn(rs, rs.nn - genpoly[rs.nroots] + feedback);
      {$ENDIF}    
      for j := 1 to rs.nroots - 1 do
        parity_a[j] := parity_a[j]
          xor alpha_to[modnn(rs, feedback + genpoly[rs.nroots - j])];
    end;
    {* Shift *}
    MoveMemory(@parity_a[0], @parity_a[1], SizeOf(data_t) * (rs.nroots - 1));
    if (feedback <> rs.nn) then
      parity_a[rs.nroots - 1] := alpha_to[modnn(rs, feedback + genpoly[0])]
    else
      parity_a[rs.nroots - 1] := 0;
  end;
end;

end.
