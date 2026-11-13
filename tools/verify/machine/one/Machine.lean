import Std.Tactic.BVDecide

/-! # One small x86-64 for the kernels and the compiled Rust around them

Sixteen general registers, sixteen XMM registers and the wide registers they are part of (ZMM0 to ZMM31),
ZF and CF, and memory as the bytes the
program owns: `mem a = none` is a byte it does not own, and reading or writing one is a fault.
An aligned vector load or store (MOVAPS, MOVDQA) at an address that is not a multiple of 16 is
a fault too. Whatever is not modelled is a fault. -/

namespace X86

abbrev V := BitVec 128

/-- Doubleword `i` of a vector (0 is the lowest). -/
def dw (v : V) (i : Nat) : BitVec 32 := v.extractLsb' (32 * i) 32
/-- A vector from its doublewords, lowest first. -/
def mk4 (a b c e : BitVec 32) : V := e ++ c ++ b ++ a
def by8 (v : V) (i : Nat) : BitVec 8 := v.extractLsb' (8 * i) 8
def w16 (v : V) (i : Nat) : BitVec 16 := v.extractLsb' (16 * i) 16

def map2 (f : BitVec 32 → BitVec 32 → BitVec 32) (x y : V) : V :=
  mk4 (f (dw x 0) (dw y 0)) (f (dw x 1) (dw y 1)) (f (dw x 2) (dw y 2)) (f (dw x 3) (dw y 3))
def map1 (f : BitVec 32 → BitVec 32) (x : V) : V := mk4 (f (dw x 0)) (f (dw x 1)) (f (dw x 2)) (f (dw x 3))

/-- PSHUFB: byte `i` of the result is 0 where the mask byte's top bit is set, and otherwise the
byte of `x` its low four bits name. -/
def shufb1 (x m : V) (i : Nat) : BitVec 8 :=
  if (by8 m i).getLsbD 7 then 0 else (x >>> (((by8 m i) &&& 15).setWidth 128 <<< 3)).setWidth 8
def pshufb (x m : V) : V :=
  shufb1 x m 15 ++ shufb1 x m 14 ++ shufb1 x m 13 ++ shufb1 x m 12 ++ shufb1 x m 11 ++ shufb1 x m 10 ++ shufb1 x m 9 ++
    shufb1 x m 8 ++ shufb1 x m 7 ++ shufb1 x m 6 ++ shufb1 x m 5 ++ shufb1 x m 4 ++ shufb1 x m 3 ++ shufb1 x m 2 ++
    shufb1 x m 1 ++ shufb1 x m 0
/-- PSHUFD: doubleword `i` of the result is the doubleword of `y` that bits `2i+1:2i` of `imm` name. -/
def pshufd (y : V) (imm : Nat) : V :=
  mk4 (dw y (imm % 4)) (dw y (imm / 4 % 4)) (dw y (imm / 16 % 4)) (dw y (imm / 64 % 4))
/-- SHUFPS: the low two doublewords from `x`, the high two from `y`, each named by two bits of `imm`. -/
def shufps (x y : V) (imm : Nat) : V :=
  mk4 (dw x (imm % 4)) (dw x (imm / 4 % 4)) (dw y (imm / 16 % 4)) (dw y (imm / 64 % 4))
/-- PBLENDW: word `i` from `y` where bit `i` of `imm` is set, else from `x`. -/
def blend1 (x y : V) (imm i : Nat) : BitVec 16 := if imm / 2 ^ i % 2 = 1 then w16 y i else w16 x i
def pblendw (x y : V) (imm : Nat) : V :=
  blend1 x y imm 7 ++ blend1 x y imm 6 ++ blend1 x y imm 5 ++ blend1 x y imm 4 ++ blend1 x y imm 3 ++
    blend1 x y imm 2 ++ blend1 x y imm 1 ++ blend1 x y imm 0
/-- VPBLENDD: doubleword `i` from `y` where bit `i` of `imm` is set, else from `x`. -/
def blendd1 (x y : V) (imm i : Nat) : BitVec 32 := if imm / 2 ^ i % 2 = 1 then dw y i else dw x i
def vpblendd (x y : V) (imm : Nat) : V := mk4 (blendd1 x y imm 0) (blendd1 x y imm 1) (blendd1 x y imm 2) (blendd1 x y imm 3)
def punpcklqdq (x y : V) : V := y.extractLsb' 0 64 ++ x.extractLsb' 0 64
def punpckldq (x y : V) : V := mk4 (dw x 0) (dw y 0) (dw x 1) (dw y 1)
def punpckhdq (x y : V) : V := mk4 (dw x 2) (dw y 2) (dw x 3) (dw y 3)

/-! Byte and word forms (SSE2), added for a hexadecimal encoder. -/

/-- PADDB: bytes added, each wrapping. -/
def paddb (x y : V) : V :=
  (by8 x 15 + by8 y 15) ++ (by8 x 14 + by8 y 14) ++ (by8 x 13 + by8 y 13) ++ (by8 x 12 + by8 y 12) ++ (by8 x 11 + by8 y 11) ++
    (by8 x 10 + by8 y 10) ++ (by8 x 9 + by8 y 9) ++ (by8 x 8 + by8 y 8) ++ (by8 x 7 + by8 y 7) ++ (by8 x 6 + by8 y 6) ++
    (by8 x 5 + by8 y 5) ++ (by8 x 4 + by8 y 4) ++ (by8 x 3 + by8 y 3) ++ (by8 x 2 + by8 y 2) ++ (by8 x 1 + by8 y 1) ++ (by8 x 0 + by8 y 0)
/-- PCMPGTB: a byte of ones where the byte of `x` is greater than the byte of `y`, as signed numbers. -/
def gtb (x y : V) (i : Nat) : BitVec 8 := if (by8 y i).slt (by8 x i) then 0xFF else 0
def pcmpgtb (x y : V) : V :=
  gtb x y 15 ++ gtb x y 14 ++ gtb x y 13 ++ gtb x y 12 ++ gtb x y 11 ++ gtb x y 10 ++ gtb x y 9 ++ gtb x y 8 ++
    gtb x y 7 ++ gtb x y 6 ++ gtb x y 5 ++ gtb x y 4 ++ gtb x y 3 ++ gtb x y 2 ++ gtb x y 1 ++ gtb x y 0
/-- PUNPCKLBW: the low eight bytes of `x` and of `y`, interleaved, `x`'s first. PUNPCKHBW: the high eight. -/
def punpcklbw (x y : V) : V :=
  by8 y 7 ++ by8 x 7 ++ by8 y 6 ++ by8 x 6 ++ by8 y 5 ++ by8 x 5 ++ by8 y 4 ++ by8 x 4 ++
    by8 y 3 ++ by8 x 3 ++ by8 y 2 ++ by8 x 2 ++ by8 y 1 ++ by8 x 1 ++ by8 y 0 ++ by8 x 0
def punpckhbw (x y : V) : V :=
  by8 y 15 ++ by8 x 15 ++ by8 y 14 ++ by8 x 14 ++ by8 y 13 ++ by8 x 13 ++ by8 y 12 ++ by8 x 12 ++
    by8 y 11 ++ by8 x 11 ++ by8 y 10 ++ by8 x 10 ++ by8 y 9 ++ by8 x 9 ++ by8 y 8 ++ by8 x 8
/-- PSRLW by an immediate below 16: each 16-bit word shifted right. -/
def psrlw (x : V) (n : Nat) : V :=
  (w16 x 7 >>> n) ++ (w16 x 6 >>> n) ++ (w16 x 5 >>> n) ++ (w16 x 4 >>> n) ++ (w16 x 3 >>> n) ++ (w16 x 2 >>> n) ++ (w16 x 1 >>> n) ++ (w16 x 0 >>> n)

/-! ## The wide registers (AVX-512)

ZMM0 to ZMM15 are the XMM registers below and 384 more bits each; ZMM16 to ZMM31 are whole. R10 and R11 are
here too: the calling convention lets any function change them, and no function of ours keeps a value in one
across a call. An instruction on XMM registers written the old way (SSE) leaves the bits above; written the
new way (VEX, EVEX) it clears them. -/

abbrev Z := BitVec 512
/-- Bits 128 to 511 of a ZMM register. -/
abbrev U := BitVec 384

def zlo (v : Z) : V := v.setWidth 128
def zhi (v : Z) : U := v.extractLsb' 128 384
def zjoin (lo : V) (hi : U) : Z := hi ++ lo
/-- Doubleword `i` of a ZMM register (0 is the lowest). -/
def zdw (v : Z) (i : Nat) : BitVec 32 := v.extractLsb' (32 * i) 32
/-- A ZMM register from its sixteen doublewords, lowest first. -/
def zpack (f : Nat → BitVec 32) : Z :=
  f 15 ++ f 14 ++ f 13 ++ f 12 ++ f 11 ++ f 10 ++ f 9 ++ f 8 ++ f 7 ++ f 6 ++ f 5 ++ f 4 ++ f 3 ++ f 2 ++ f 1 ++ f 0
def zmap2 (f : BitVec 32 → BitVec 32 → BitVec 32) (a b : Z) : Z := zpack fun i => f (zdw a i) (zdw b i)
def zmap1 (f : BitVec 32 → BitVec 32) (a : Z) : Z := zpack fun i => f (zdw a i)
/-- VPBROADCASTD: the doubleword in every place. -/
def zbroadcast (v : BitVec 32) : Z := zpack fun _ => v
/-- The four unpack instructions work in each 128-bit quarter by itself: doubleword `i` of the result comes from
the quarter `i` is in (`i / 4 * 4` is that quarter's first doubleword).
VPUNPCKLDQ: a0 b0 a1 b1. VPUNPCKHDQ: a2 b2 a3 b3. VPUNPCKLQDQ: a0 a1 b0 b1. VPUNPCKHQDQ: a2 a3 b2 b3. -/
def zunpckldq (a b : Z) : Z := zpack fun i =>
  match i % 4 with | 0 => zdw a (i / 4 * 4) | 1 => zdw b (i / 4 * 4) | 2 => zdw a (i / 4 * 4 + 1) | _ => zdw b (i / 4 * 4 + 1)
def zunpckhdq (a b : Z) : Z := zpack fun i =>
  match i % 4 with | 0 => zdw a (i / 4 * 4 + 2) | 1 => zdw b (i / 4 * 4 + 2) | 2 => zdw a (i / 4 * 4 + 3) | _ => zdw b (i / 4 * 4 + 3)
def zunpcklqdq (a b : Z) : Z := zpack fun i =>
  match i % 4 with | 0 => zdw a (i / 4 * 4) | 1 => zdw a (i / 4 * 4 + 1) | 2 => zdw b (i / 4 * 4) | _ => zdw b (i / 4 * 4 + 1)
def zunpckhqdq (a b : Z) : Z := zpack fun i =>
  match i % 4 with | 0 => zdw a (i / 4 * 4 + 2) | 1 => zdw a (i / 4 * 4 + 3) | 2 => zdw b (i / 4 * 4 + 2) | _ => zdw b (i / 4 * 4 + 3)
/-- Quarter `i` of a ZMM register: 128 bits (0 is the lowest). -/
def zquarter (v : Z) (i : Nat) : V := v.extractLsb' (128 * i) 128
/-- VSHUFI32X4: the two low quarters of the result are quarters of `a`, the two high ones quarters of `b`,
each named by two bits of `imm`. -/
def zshufi32x4 (a b : Z) (imm : Nat) : Z :=
  zquarter b (imm / 64 % 4) ++ zquarter b (imm / 16 % 4) ++ zquarter a (imm / 4 % 4) ++ zquarter a (imm % 4)

structure Wide where
  r10 : BitVec 64
  r11 : BitVec 64
  u0 : U
  u1 : U
  u2 : U
  u3 : U
  u4 : U
  u5 : U
  u6 : U
  u7 : U
  u8 : U
  u9 : U
  u10 : U
  u11 : U
  u12 : U
  u13 : U
  u14 : U
  u15 : U
  z16 : Z
  z17 : Z
  z18 : Z
  z19 : Z
  z20 : Z
  z21 : Z
  z22 : Z
  z23 : Z
  z24 : Z
  z25 : Z
  z26 : Z
  z27 : Z
  z28 : Z
  z29 : Z
  z30 : Z
  z31 : Z

inductive Reg | rax | rcx | rdx | rbx | rsp | rbp | rsi | rdi | r8 | r9 | r12 | r13 | r14 | r15 | r10 | r11
  deriving DecidableEq

/-- The bytes this program owns. -/
abbrev Mem := BitVec 64 → Option (BitVec 8)

structure State where
  rax : BitVec 64
  rcx : BitVec 64
  rdx : BitVec 64
  rbx : BitVec 64
  rsp : BitVec 64
  rbp : BitVec 64
  rsi : BitVec 64
  rdi : BitVec 64
  r8 : BitVec 64
  r9 : BitVec 64
  r12 : BitVec 64
  r13 : BitVec 64
  r14 : BitVec 64
  r15 : BitVec 64
  zf : Option Bool
  cf : Option Bool
  x0 : V
  x1 : V
  x2 : V
  x3 : V
  x4 : V
  x5 : V
  x6 : V
  x7 : V
  x8 : V
  x9 : V
  x10 : V
  x11 : V
  x12 : V
  x13 : V
  x14 : V
  x15 : V
  mem : Mem
  pc : Nat
  /-- R10, R11 and the wide registers. -/
  w : Wide

def State.get (s : State) : Reg → BitVec 64
  | .rax => s.rax | .rcx => s.rcx | .rdx => s.rdx | .rbx => s.rbx | .rsp => s.rsp | .rbp => s.rbp | .rsi => s.rsi | .rdi => s.rdi | .r8 => s.r8 | .r9 => s.r9 | .r12 => s.r12 | .r13 => s.r13 | .r14 => s.r14 | .r15 => s.r15
  | .r10 => s.w.r10 | .r11 => s.w.r11

def State.set (s : State) (r : Reg) (v : BitVec 64) : State :=
  match r with
  | .rax => { s with rax := v } | .rcx => { s with rcx := v } | .rdx => { s with rdx := v } | .rbx => { s with rbx := v }
  | .rsp => { s with rsp := v } | .rbp => { s with rbp := v } | .rsi => { s with rsi := v } | .rdi => { s with rdi := v }
  | .r8 => { s with r8 := v } | .r9 => { s with r9 := v } | .r12 => { s with r12 := v } | .r13 => { s with r13 := v }
  | .r14 => { s with r14 := v } | .r15 => { s with r15 := v }
  | .r10 => { s with w := { s.w with r10 := v } } | .r11 => { s with w := { s.w with r11 := v } }

def State.xmm (s : State) : Nat → V
  | 0 => s.x0 | 1 => s.x1 | 2 => s.x2 | 3 => s.x3 | 4 => s.x4 | 5 => s.x5 | 6 => s.x6 | 7 => s.x7
  | 8 => s.x8 | 9 => s.x9 | 10 => s.x10 | 11 => s.x11 | 12 => s.x12 | 13 => s.x13 | 14 => s.x14
  | _ => s.x15

def State.setx (s : State) (i : Nat) (v : V) : State :=
  match i with
  | 0 => { s with x0 := v } | 1 => { s with x1 := v } | 2 => { s with x2 := v } | 3 => { s with x3 := v }
  | 4 => { s with x4 := v } | 5 => { s with x5 := v } | 6 => { s with x6 := v } | 7 => { s with x7 := v }
  | 8 => { s with x8 := v } | 9 => { s with x9 := v } | 10 => { s with x10 := v } | 11 => { s with x11 := v }
  | 12 => { s with x12 := v } | 13 => { s with x13 := v } | 14 => { s with x14 := v }
  | _ => { s with x15 := v }

/-- A whole ZMM register. -/
def State.zmm (s : State) : Nat → Z
  | 0 => zjoin s.x0 s.w.u0
  | 1 => zjoin s.x1 s.w.u1
  | 2 => zjoin s.x2 s.w.u2
  | 3 => zjoin s.x3 s.w.u3
  | 4 => zjoin s.x4 s.w.u4
  | 5 => zjoin s.x5 s.w.u5
  | 6 => zjoin s.x6 s.w.u6
  | 7 => zjoin s.x7 s.w.u7
  | 8 => zjoin s.x8 s.w.u8
  | 9 => zjoin s.x9 s.w.u9
  | 10 => zjoin s.x10 s.w.u10
  | 11 => zjoin s.x11 s.w.u11
  | 12 => zjoin s.x12 s.w.u12
  | 13 => zjoin s.x13 s.w.u13
  | 14 => zjoin s.x14 s.w.u14
  | 15 => zjoin s.x15 s.w.u15
  | 16 => s.w.z16
  | 17 => s.w.z17
  | 18 => s.w.z18
  | 19 => s.w.z19
  | 20 => s.w.z20
  | 21 => s.w.z21
  | 22 => s.w.z22
  | 23 => s.w.z23
  | 24 => s.w.z24
  | 25 => s.w.z25
  | 26 => s.w.z26
  | 27 => s.w.z27
  | 28 => s.w.z28
  | 29 => s.w.z29
  | 30 => s.w.z30
  | _ => s.w.z31

def State.setz (s : State) (i : Nat) (v : Z) : State :=
  match i with
  | 0 => { s with x0 := zlo v, w := { s.w with u0 := zhi v } }
  | 1 => { s with x1 := zlo v, w := { s.w with u1 := zhi v } }
  | 2 => { s with x2 := zlo v, w := { s.w with u2 := zhi v } }
  | 3 => { s with x3 := zlo v, w := { s.w with u3 := zhi v } }
  | 4 => { s with x4 := zlo v, w := { s.w with u4 := zhi v } }
  | 5 => { s with x5 := zlo v, w := { s.w with u5 := zhi v } }
  | 6 => { s with x6 := zlo v, w := { s.w with u6 := zhi v } }
  | 7 => { s with x7 := zlo v, w := { s.w with u7 := zhi v } }
  | 8 => { s with x8 := zlo v, w := { s.w with u8 := zhi v } }
  | 9 => { s with x9 := zlo v, w := { s.w with u9 := zhi v } }
  | 10 => { s with x10 := zlo v, w := { s.w with u10 := zhi v } }
  | 11 => { s with x11 := zlo v, w := { s.w with u11 := zhi v } }
  | 12 => { s with x12 := zlo v, w := { s.w with u12 := zhi v } }
  | 13 => { s with x13 := zlo v, w := { s.w with u13 := zhi v } }
  | 14 => { s with x14 := zlo v, w := { s.w with u14 := zhi v } }
  | 15 => { s with x15 := zlo v, w := { s.w with u15 := zhi v } }
  | 16 => { s with w := { s.w with z16 := v } }
  | 17 => { s with w := { s.w with z17 := v } }
  | 18 => { s with w := { s.w with z18 := v } }
  | 19 => { s with w := { s.w with z19 := v } }
  | 20 => { s with w := { s.w with z20 := v } }
  | 21 => { s with w := { s.w with z21 := v } }
  | 22 => { s with w := { s.w with z22 := v } }
  | 23 => { s with w := { s.w with z23 := v } }
  | 24 => { s with w := { s.w with z24 := v } }
  | 25 => { s with w := { s.w with z25 := v } }
  | 26 => { s with w := { s.w with z26 := v } }
  | 27 => { s with w := { s.w with z27 := v } }
  | 28 => { s with w := { s.w with z28 := v } }
  | 29 => { s with w := { s.w with z29 := v } }
  | 30 => { s with w := { s.w with z30 := v } }
  | _ => { s with w := { s.w with z31 := v } }

/-- An XMM register written the new way (VEX, EVEX): the bits above it are cleared. -/
def State.setxz (s : State) (i : Nat) (v : V) : State :=
  match i with
  | 0 => { s with x0 := v, w := { s.w with u0 := 0 } }
  | 1 => { s with x1 := v, w := { s.w with u1 := 0 } }
  | 2 => { s with x2 := v, w := { s.w with u2 := 0 } }
  | 3 => { s with x3 := v, w := { s.w with u3 := 0 } }
  | 4 => { s with x4 := v, w := { s.w with u4 := 0 } }
  | 5 => { s with x5 := v, w := { s.w with u5 := 0 } }
  | 6 => { s with x6 := v, w := { s.w with u6 := 0 } }
  | 7 => { s with x7 := v, w := { s.w with u7 := 0 } }
  | 8 => { s with x8 := v, w := { s.w with u8 := 0 } }
  | 9 => { s with x9 := v, w := { s.w with u9 := 0 } }
  | 10 => { s with x10 := v, w := { s.w with u10 := 0 } }
  | 11 => { s with x11 := v, w := { s.w with u11 := 0 } }
  | 12 => { s with x12 := v, w := { s.w with u12 := 0 } }
  | 13 => { s with x13 := v, w := { s.w with u13 := 0 } }
  | 14 => { s with x14 := v, w := { s.w with u14 := 0 } }
  | _ => { s with x15 := v, w := { s.w with u15 := 0 } }

/-- VZEROUPPER: ZMM0 to ZMM15 cleared above bit 127; the others as they were. -/
def State.zeroupper (s : State) : State :=
  { s with w := { s.w with u0 := 0, u1 := 0, u2 := 0, u3 := 0, u4 := 0, u5 := 0, u6 := 0, u7 := 0, u8 := 0, u9 := 0, u10 := 0, u11 := 0, u12 := 0, u13 := 0, u14 := 0, u15 := 0 } }

def trunc (w : Nat) (v : BitVec 64) : BitVec 64 :=
  match w with
  | 8 => v &&& 0xFF
  | 32 => v &&& 0xFFFFFFFF
  | _ => v

def byte (v : BitVec 64) (i : Nat) : BitVec 8 := (v >>> (8 * i)).setWidth 8

def Mem.read8 (m : Mem) (a : BitVec 64) : Option (BitVec 64) := (m a).map (BitVec.setWidth 64)

/-- `w` bits at `a`, little-endian (w is 8, 32 or 64). -/
def Mem.read (m : Mem) (a : BitVec 64) : Nat → Option (BitVec 64)
  | 8 => m.read8 a
  | 32 => do
    let b0 ← m.read8 a; let b1 ← m.read8 (a + 1); let b2 ← m.read8 (a + 2); let b3 ← m.read8 (a + 3)
    pure (b0 ||| (b1 <<< 8) ||| (b2 <<< 16) ||| (b3 <<< 24))
  | _ => do
    let b0 ← m.read8 a; let b1 ← m.read8 (a + 1); let b2 ← m.read8 (a + 2); let b3 ← m.read8 (a + 3)
    let b4 ← m.read8 (a + 4); let b5 ← m.read8 (a + 5); let b6 ← m.read8 (a + 6); let b7 ← m.read8 (a + 7)
    pure (b0 ||| (b1 <<< 8) ||| (b2 <<< 16) ||| (b3 <<< 24) ||| (b4 <<< 32) ||| (b5 <<< 40) ||| (b6 <<< 48) ||| (b7 <<< 56))

/-- The sixteen bytes at `a`, as a vector. -/
def Mem.read128 (m : Mem) (a : BitVec 64) : Option V := do
  let b0 ← m (a + 0); let b1 ← m (a + 1); let b2 ← m (a + 2); let b3 ← m (a + 3); let b4 ← m (a + 4); let b5 ← m (a + 5); let b6 ← m (a + 6); let b7 ← m (a + 7); let b8 ← m (a + 8); let b9 ← m (a + 9); let b10 ← m (a + 10); let b11 ← m (a + 11); let b12 ← m (a + 12); let b13 ← m (a + 13); let b14 ← m (a + 14); let b15 ← m (a + 15);
  pure (b15 ++ b14 ++ b13 ++ b12 ++ b11 ++ b10 ++ b9 ++ b8 ++ b7 ++ b6 ++ b5 ++ b4 ++ b3 ++ b2 ++ b1 ++ b0)

/-- One byte put at `a`, whoever owns it. -/
def Mem.put8 (m : Mem) (a : BitVec 64) (v : BitVec 8) : Mem := fun x => if x = a then some v else m x

/-- One byte written at `a`: a fault unless the program owns it. -/
def Mem.write8 (m : Mem) (a : BitVec 64) (v : BitVec 8) : Option Mem :=
  if (m a).isSome then some (m.put8 a v) else none

def Mem.write (m : Mem) (a : BitVec 64) (v : BitVec 64) : Nat → Option Mem
  | 8 => m.write8 a (byte v 0)
  | 32 => do
    let m ← m.write8 a (byte v 0); let m ← m.write8 (a + 1) (byte v 1)
    let m ← m.write8 (a + 2) (byte v 2); m.write8 (a + 3) (byte v 3)
  | _ => do
    let m ← m.write8 a (byte v 0); let m ← m.write8 (a + 1) (byte v 1)
    let m ← m.write8 (a + 2) (byte v 2); let m ← m.write8 (a + 3) (byte v 3)
    let m ← m.write8 (a + 4) (byte v 4); let m ← m.write8 (a + 5) (byte v 5)
    let m ← m.write8 (a + 6) (byte v 6); m.write8 (a + 7) (byte v 7)

def Mem.write128 (m : Mem) (a : BitVec 64) (v : V) : Option Mem := do
  let m ← m.write8 (a + 0) (by8 v 0)
  let m ← m.write8 (a + 1) (by8 v 1)
  let m ← m.write8 (a + 2) (by8 v 2)
  let m ← m.write8 (a + 3) (by8 v 3)
  let m ← m.write8 (a + 4) (by8 v 4)
  let m ← m.write8 (a + 5) (by8 v 5)
  let m ← m.write8 (a + 6) (by8 v 6)
  let m ← m.write8 (a + 7) (by8 v 7)
  let m ← m.write8 (a + 8) (by8 v 8)
  let m ← m.write8 (a + 9) (by8 v 9)
  let m ← m.write8 (a + 10) (by8 v 10)
  let m ← m.write8 (a + 11) (by8 v 11)
  let m ← m.write8 (a + 12) (by8 v 12)
  let m ← m.write8 (a + 13) (by8 v 13)
  let m ← m.write8 (a + 14) (by8 v 14)
  m.write8 (a + 15) (by8 v 15)

/-- The 64 bytes at `a`, as a ZMM register. -/
def Mem.read512 (m : Mem) (a : BitVec 64) : Option Z := do
  let q0 ← m.read128 a; let q1 ← m.read128 (a + 16); let q2 ← m.read128 (a + 32); let q3 ← m.read128 (a + 48)
  pure (q3 ++ q2 ++ q1 ++ q0)

def Mem.write512 (m : Mem) (a : BitVec 64) (v : Z) : Option Mem := do
  let m ← m.write128 a (zquarter v 0); let m ← m.write128 (a + 16) (zquarter v 1)
  let m ← m.write128 (a + 32) (zquarter v 2); m.write128 (a + 48) (zquarter v 3)

/-- A general-register operand. -/
inductive Opnd
  | reg (r : Reg)
  | mem (base : Reg) (disp : BitVec 64)
  | imm (v : BitVec 64)

/-- A vector operand: a register, sixteen bytes of memory, or a constant the code names (a
RIP-relative load of read-only data, which the lifter resolves). -/
inductive Src
  | x (i : Nat)
  | m (base : Reg) (disp : BitVec 64)
  | c (v : V)

inductive Instr
  -- vector moves; `aligned` is MOVAPS and MOVDQA, which fault at an address not a multiple of 16
  | movv (aligned : Bool) (dst : Nat) (src : Src)
  | storev (aligned : Bool) (base : Reg) (disp : BitVec 64) (src : Nat)
  | movq (dst : Nat) (r : Reg)
  -- SSE forms
  | paddd (dst : Nat) (src : Src)
  | pxor (dst : Nat) (src : Src)
  | por (dst : Nat) (src : Src)
  | pshufb (dst : Nat) (src : Src)
  | pslld (dst : Nat) (n : Nat)
  | psrld (dst : Nat) (n : Nat)
  | pshufd (dst : Nat) (src : Src) (imm : Nat)
  | shufps (dst : Nat) (src : Src) (imm : Nat)
  | pblendw (dst : Nat) (src : Src) (imm : Nat)
  | punpcklqdq (dst : Nat) (src : Src)
  | punpckldq (dst : Nat) (src : Src)
  | punpckhdq (dst : Nat) (src : Src)
  -- three-operand (VEX and EVEX) forms on XMM registers
  | vpaddd (dst a : Nat) (src : Src)
  | vpxor (dst a : Nat) (src : Src)
  | vprord (dst : Nat) (src : Src) (n : Nat)
  | vshufps (dst a : Nat) (src : Src) (imm : Nat)
  | vpblendd (dst a : Nat) (src : Src) (imm : Nat)
  | vpunpcklqdq (dst a : Nat) (src : Src)
  | vpunpckldq (dst a : Nat) (src : Src)
  | vpunpckhdq (dst a : Nat) (src : Src)
  -- general registers
  | mov (w : Nat) (dst src : Opnd)
  /-- MOVZX r32, r/m8 -/
  | movzx8 (dst : Reg) (src : Opnd)
  | or (w : Nat) (dst src : Opnd)
  | add (w : Nat) (dst src : Opnd)
  | sub (w : Nat) (dst src : Opnd)
  | cmp (w : Nat) (a b : Opnd)
  | shl64 (r : Reg) (n : Nat)
  | decb (r : Reg)
  | push (r : Reg)
  | pop (r : Reg)
  | je (target : Nat)
  | jne (target : Nat)
  | jmp (target : Nat)
  | call (target : Nat)
  | ret
  -- added for `CvStack::merge`
  | and (w : Nat) (dst src : Opnd)
  | xor (w : Nat) (dst src : Opnd)
  /-- LEA r64, [base + disp] -/
  | lea (dst base : Reg) (disp : BitVec 64)
  /-- JBE: taken when CF or ZF is set. JAE: when CF is clear. -/
  | jbe (target : Nat)
  | jae (target : Nat)
  | nop
  /-- DEC r64: ZF from the result, CF as it was. -/
  | dec64 (r : Reg)
  /-- A vector load from `[base + index + disp]`. -/
  | movvi (aligned : Bool) (dst : Nat) (base index : Reg) (disp : BitVec 64)
  -- byte and word forms (SSE2); a memory operand of these must be 16-byte aligned
  | pand (dst : Nat) (src : Src)
  | paddb (dst : Nat) (src : Src)
  | pcmpgtb (dst : Nat) (src : Src)
  | punpcklbw (dst : Nat) (src : Src)
  | punpckhbw (dst : Nat) (src : Src)
  | psrlw (dst : Nat) (n : Nat)
  /-- SHR r64, imm8: a logical shift right. The processor takes the count's low six bits. -/
  | shr64 (r : Reg) (n : Nat)
  -- moves written the new way (VEX): the register is cleared above bit 127
  | vmovv (aligned : Bool) (dst : Nat) (src : Src)
  | vmovvi (aligned : Bool) (dst : Nat) (base index : Reg) (disp : BitVec 64)
  | vmovq (dst : Nat) (r : Reg)
  | vpshufd (dst : Nat) (src : Src) (imm : Nat)
  /-- SHR r32, imm8: the count's low five bits; the register's upper half is cleared. -/
  | shr32 (r : Reg) (n : Nat)
  /-- DEC r32: ZF from the 32-bit result, CF as it was; the register's upper half is cleared. -/
  | dec32 (r : Reg)
  -- AVX-512F on whole ZMM registers, without masks. An aligned form (VMOVDQA32) with memory faults at an
  -- address that is not a multiple of 64.
  /-- VMOVDQA32 or VMOVDQU32 zmm, zmm -/
  | zmov (dst src : Nat)
  /-- VMOVDQA32 or VMOVDQU32 zmm, [base + disp] -/
  | zload (aligned : Bool) (dst : Nat) (base : Reg) (disp : BitVec 64)
  /-- VMOVDQU32 zmm, [base + index + disp] -/
  | zloadi (dst : Nat) (base index : Reg) (disp : BitVec 64)
  /-- VMOVDQA32 or VMOVDQU32 [base + disp], zmm -/
  | zstore (aligned : Bool) (base : Reg) (disp : BitVec 64) (src : Nat)
  /-- VPBROADCASTD zmm, r32 or m32 (or a constant the code names, which the lifter resolves) -/
  | zbroadcast (dst : Nat) (src : Opnd)
  | zpaddd (dst a b : Nat)
  | zpxord (dst a b : Nat)
  | zprord (dst a : Nat) (n : Nat)
  | zunpckldq (dst a b : Nat)
  | zunpckhdq (dst a b : Nat)
  | zunpcklqdq (dst a b : Nat)
  | zunpckhqdq (dst a b : Nat)
  | zshufi32x4 (dst a b : Nat) (imm : Nat)
  | vzeroupper

def read (s : State) (w : Nat) : Opnd → Option (BitVec 64)
  | .reg r => some (trunc w (s.get r))
  | .imm v => some (trunc w v)
  | .mem b d => s.mem.read (s.get b + d) w

/-- Writing 32 bits of a register clears its upper half; writing 8 keeps the other 56. -/
def write (s : State) (w : Nat) (o : Opnd) (v : BitVec 64) : Option State :=
  match o with
  | .reg r => some (s.set r (match w with
      | 8 => (s.get r &&& ~~~(0xFF : BitVec 64)) ||| (v &&& 0xFF)
      | 32 => v &&& 0xFFFFFFFF
      | _ => v))
  | .imm _ => none
  | .mem b d => (s.mem.write (s.get b + d) v w).map fun m => { s with mem := m }

/-- Is this address a multiple of 16? -/
def aligned16 (a : BitVec 64) : Bool := a &&& 15 == 0
/-- Is this address a multiple of 64? -/
def aligned64 (a : BitVec 64) : Bool := a &&& 63 == 0

def src (s : State) (aligned : Bool) : Src → Option V
  | .x i => some (s.xmm i)
  | .m b d => if aligned && !aligned16 (s.get b + d) then none else s.mem.read128 (s.get b + d)
  | .c v => some v

/-- One instruction at `s.pc`, the next one at `next` unless it jumps. -/
def step (i : Instr) (next : Nat) (s : State) : Option State :=
  let s := { s with pc := next }
  match i with
  | .movv al d x => do some (s.setx d (← src s al x))
  | .storev al b disp x =>
    if al && !aligned16 (s.get b + disp) then none
    else (s.mem.write128 (s.get b + disp) (s.xmm x)).map fun m => { s with mem := m }
  | .movq d r => some (s.setx d ((s.get r).setWidth 128))
  | .paddd d x => do some (s.setx d (map2 (· + ·) (s.xmm d) (← src s false x)))
  | .pxor d x => do some (s.setx d (s.xmm d ^^^ (← src s false x)))
  | .por d x => do some (s.setx d (s.xmm d ||| (← src s false x)))
  | .pshufb d x => do some (s.setx d (pshufb (s.xmm d) (← src s false x)))
  | .pslld d n => some (s.setx d (map1 (· <<< n) (s.xmm d)))
  | .psrld d n => some (s.setx d (map1 (· >>> n) (s.xmm d)))
  | .pshufd d x imm => do some (s.setx d (pshufd (← src s false x) imm))
  | .shufps d x imm => do some (s.setx d (shufps (s.xmm d) (← src s false x) imm))
  | .pblendw d x imm => do some (s.setx d (pblendw (s.xmm d) (← src s false x) imm))
  | .punpcklqdq d x => do some (s.setx d (punpcklqdq (s.xmm d) (← src s false x)))
  | .punpckldq d x => do some (s.setx d (punpckldq (s.xmm d) (← src s false x)))
  | .punpckhdq d x => do some (s.setx d (punpckhdq (s.xmm d) (← src s false x)))
  | .vpaddd d a x => do some (s.setxz d (map2 (· + ·) (s.xmm a) (← src s false x)))
  | .vpxor d a x => do some (s.setxz d (s.xmm a ^^^ (← src s false x)))
  | .vprord d x n => do some (s.setxz d (map1 (·.rotateRight n) (← src s false x)))
  | .vshufps d a x imm => do some (s.setxz d (shufps (s.xmm a) (← src s false x) imm))
  | .vpblendd d a x imm => do some (s.setxz d (vpblendd (s.xmm a) (← src s false x) imm))
  | .vpunpcklqdq d a x => do some (s.setxz d (punpcklqdq (s.xmm a) (← src s false x)))
  | .vpunpckldq d a x => do some (s.setxz d (punpckldq (s.xmm a) (← src s false x)))
  | .vpunpckhdq d a x => do some (s.setxz d (punpckhdq (s.xmm a) (← src s false x)))
  | .mov w d x => do write s w d (← read s w x)
  | .movzx8 d x => do some (s.set d (← read s 8 x))
  | .or w d x => do
    let v := (← read s w d) ||| (← read s w x)
    write { s with zf := some (trunc w v == 0), cf := some false } w d v
  | .add w d x => do
    let a ← read s w d; let b ← read s w x; let v := trunc w (a + b)
    write { s with zf := some (v == 0), cf := some (v.ult a) } w d v
  | .sub w d x => do
    let a ← read s w d; let b ← read s w x; let v := trunc w (a - b)
    write { s with zf := some (v == 0), cf := some (a.ult b) } w d v
  | .cmp w a b => do
    let a ← read s w a; let b ← read s w b
    some { s with zf := some (trunc w (a - b) == 0), cf := some (a.ult b) }
  -- A shift's carry is the last bit out; left unmodelled, so nothing may branch on it.
  | .shl64 r n => some ({ s with zf := some (s.get r <<< n == 0), cf := none }.set r (s.get r <<< n))
  -- DEC leaves CF as it was.
  | .decb r =>
    let v := (s.get r).setWidth 8 - 1
    some ({ s with zf := some (v == 0) }.set r ((s.get r &&& ~~~(0xFF : BitVec 64)) ||| v.setWidth 64))
  | .push r => (s.mem.write (s.rsp - 8) (s.get r) 64).map fun m => { s with rsp := s.rsp - 8, mem := m }
  | .pop r => (s.mem.read s.rsp 64).map fun v => { s with rsp := s.rsp + 8 }.set r v
  | .je t => s.zf.map fun z => if z then { s with pc := t } else s
  | .jne t => s.zf.map fun z => if z then s else { s with pc := t }
  | .jmp t => some { s with pc := t }
  | .call t => (s.mem.write (s.rsp - 8) (BitVec.ofNat 64 next) 64).map fun m => { s with rsp := s.rsp - 8, mem := m, pc := t }
  | .ret => (s.mem.read s.rsp 64).map fun to => { s with rsp := s.rsp + 8, pc := to.toNat }
  | .and w d x => do
    let v := (← read s w d) &&& (← read s w x)
    write { s with zf := some (trunc w v == 0), cf := some false } w d v
  | .xor w d x => do
    let v := (← read s w d) ^^^ (← read s w x)
    write { s with zf := some (trunc w v == 0), cf := some false } w d v
  | .lea d b disp => some (s.set d (s.get b + disp))
  | .jbe t => s.zf.bind fun z => s.cf.map fun c => if c || z then { s with pc := t } else s
  | .jae t => s.cf.map fun c => if c then s else { s with pc := t }
  | .nop => some s
  | .dec64 r => some ({ s with zf := some (s.get r - 1 == 0) }.set r (s.get r - 1))
  | .movvi al d b i disp =>
    if al && !aligned16 (s.get b + s.get i + disp) then none
    else (s.mem.read128 (s.get b + s.get i + disp)).map fun v => s.setx d v
  | .pand d x => do some (s.setx d (s.xmm d &&& (← src s true x)))
  | .paddb d x => do some (s.setx d (paddb (s.xmm d) (← src s true x)))
  | .pcmpgtb d x => do some (s.setx d (pcmpgtb (s.xmm d) (← src s true x)))
  | .punpcklbw d x => do some (s.setx d (punpcklbw (s.xmm d) (← src s true x)))
  | .punpckhbw d x => do some (s.setx d (punpckhbw (s.xmm d) (← src s true x)))
  | .psrlw d n => if n < 16 then some (s.setx d (psrlw (s.xmm d) n)) else none
  -- A shift's flags depend on its count (none change when it is zero): left unmodelled, so nothing may branch on them.
  | .shr64 r n => some ({ s with zf := none, cf := none }.set r (s.get r >>> (BitVec.ofNat 6 n).toNat))
  | .vmovv al d x => do some (s.setxz d (← src s al x))
  | .vmovvi al d b i disp =>
    if al && !aligned16 (s.get b + s.get i + disp) then none
    else (s.mem.read128 (s.get b + s.get i + disp)).map fun v => s.setxz d v
  | .vmovq d r => some (s.setxz d ((s.get r).setWidth 128))
  | .vpshufd d x imm => do some (s.setxz d (pshufd (← src s false x) imm))
  | .shr32 r n => some ({ s with zf := none, cf := none }.set r (((s.get r).setWidth 32 >>> (BitVec.ofNat 5 n).toNat).setWidth 64))
  | .dec32 r =>
    let v := (s.get r).setWidth 32 - 1
    some ({ s with zf := some (v == 0) }.set r (v.setWidth 64))
  | .zmov d x => some (s.setz d (s.zmm x))
  | .zload al d b disp =>
    if al && !aligned64 (s.get b + disp) then none
    else (s.mem.read512 (s.get b + disp)).map fun v => s.setz d v
  | .zloadi d b i disp => (s.mem.read512 (s.get b + s.get i + disp)).map fun v => s.setz d v
  | .zstore al b disp x =>
    if al && !aligned64 (s.get b + disp) then none
    else (s.mem.write512 (s.get b + disp) (s.zmm x)).map fun m => { s with mem := m }
  | .zbroadcast d x => do some (s.setz d (zbroadcast ((← read s 32 x).setWidth 32)))
  | .zpaddd d a b => some (s.setz d (zmap2 (· + ·) (s.zmm a) (s.zmm b)))
  | .zpxord d a b => some (s.setz d (s.zmm a ^^^ s.zmm b))
  | .zprord d a n => some (s.setz d (zmap1 (·.rotateRight n) (s.zmm a)))
  | .zunpckldq d a b => some (s.setz d (zunpckldq (s.zmm a) (s.zmm b)))
  | .zunpckhdq d a b => some (s.setz d (zunpckhdq (s.zmm a) (s.zmm b)))
  | .zunpcklqdq d a b => some (s.setz d (zunpcklqdq (s.zmm a) (s.zmm b)))
  | .zunpckhqdq d a b => some (s.setz d (zunpckhqdq (s.zmm a) (s.zmm b)))
  | .zshufi32x4 d a b imm => some (s.setz d (zshufi32x4 (s.zmm a) (s.zmm b) imm))
  | .vzeroupper => some s.zeroupper

/-- Exactly `k` instructions. -/
def steps (prog : Nat → Option (Instr × Nat)) : Nat → State → Option State
  | 0, s => some s
  | k + 1, s =>
    match prog s.pc with
    | none => none
    | some (i, next) => (step i next s).bind (steps prog k)

theorem steps_mk (prog : Nat → Option (Instr × Nat)) (k : Nat) (rax rcx rdx rbx rsp rbp rsi rdi r8 r9 r12 r13 r14 r15 : BitVec 64) (zf cf : Option Bool)
    (x0 x1 x2 x3 x4 x5 x6 x7 x8 x9 x10 x11 x12 x13 x14 x15 : V) (mem : Mem) (pc : Nat) (w : Wide) :
    steps prog (k + 1) ⟨rax, rcx, rdx, rbx, rsp, rbp, rsi, rdi, r8, r9, r12, r13, r14, r15, zf, cf, x0, x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12, x13, x14, x15, mem, pc, w⟩ =
      match prog pc with
      | none => none
      | some (i, next) => (step i next ⟨rax, rcx, rdx, rbx, rsp, rbp, rsi, rdi, r8, r9, r12, r13, r14, r15, zf, cf, x0, x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12, x13, x14, x15, mem, pc, w⟩).bind (steps prog k) := rfl

theorem steps_zero (prog : Nat → Option (Instr × Nat)) (s : State) : steps prog 0 s = some s := rfl

theorem steps_add (prog : Nat → Option (Instr × Nat)) (a b : Nat) (s : State) :
    steps prog (a + b) s = (steps prog a s).bind (steps prog b) := by
  induction a generalizing s with
  | zero => simp [steps]
  | succ a ih =>
    rw [Nat.add_right_comm]
    simp only [steps]
    cases prog s.pc with
    | none => rfl
    | some x =>
      obtain ⟨i, next⟩ := x
      simp only []
      cases step i next s with
      | none => rfl
      | some s1 => simp only [Option.bind_some, ih]

/-- A program that has all the instructions of another runs as the other does. -/
theorem steps_mono {p q : Nat → Option (Instr × Nat)} (h : ∀ pc x, p pc = some x → q pc = some x) :
    ∀ (k : Nat) (s s' : State), steps p k s = some s' → steps q k s = some s' := by
  intro k
  induction k with
  | zero => intro s s' e; exact e
  | succ k ih =>
    intro s s' e
    simp only [steps] at e ⊢
    cases hp : p s.pc with
    | none => rw [hp] at e; cases e
    | some x =>
      rw [hp] at e; rw [h _ _ hp]
      obtain ⟨i, next⟩ := x
      simp only at e ⊢
      cases hs : step i next s with
      | none => rw [hs] at e; cases e
      | some s1 => rw [hs, Option.bind_some] at e; rw [Option.bind_some]; exact ih s1 s' e

end X86
