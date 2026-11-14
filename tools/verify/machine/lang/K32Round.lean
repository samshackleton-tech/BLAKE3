import Cells
import Flat
import WideLemmas
import Code_k32
open X86 Cells Blake3Generic

/-! # A round of the 32-lane chunk kernel is the specification's round, in every lane

Written by gen_k32.py from the kernel's lifted instructions. The lanes are two halves of sixteen. Sixteen ZMM
registers hold the sixteen state words of each half (lane `i` of each is input `i`'s, or input `16 + i`'s).
The message words are in memory, sixteen ZMM words a half from `rsi`; a round reads them in the order of the
sixteen offsets `rdi` points at (a row of the kernel's schedule table). -/

namespace K32

/-- The state words of the first half, one register each: lane `i` of the register of word `k` is `s k i`. -/
def RowsA (st : State) (s0 s1 s2 s3 s4 s5 s6 s7 s8 s9 s10 s11 s12 s13 s14 s15 : Nat → BitVec 32) : Prop :=
  st.zmm 0 = zpack s0 ∧ st.zmm 1 = zpack s1 ∧ st.zmm 2 = zpack s2 ∧ st.zmm 3 = zpack s3 ∧ st.zmm 4 = zpack s4 ∧ st.zmm 5 = zpack s5 ∧ st.zmm 6 = zpack s6 ∧ st.zmm 7 = zpack s7 ∧ st.zmm 16 = zpack s8 ∧ st.zmm 17 = zpack s9 ∧ st.zmm 18 = zpack s10 ∧ st.zmm 19 = zpack s11 ∧ st.zmm 20 = zpack s12 ∧ st.zmm 21 = zpack s13 ∧ st.zmm 22 = zpack s14 ∧ st.zmm 23 = zpack s15

/-- The state words of the second half. -/
def RowsB (st : State) (s0 s1 s2 s3 s4 s5 s6 s7 s8 s9 s10 s11 s12 s13 s14 s15 : Nat → BitVec 32) : Prop :=
  st.zmm 8 = zpack s0 ∧ st.zmm 9 = zpack s1 ∧ st.zmm 10 = zpack s2 ∧ st.zmm 11 = zpack s3 ∧ st.zmm 12 = zpack s4 ∧ st.zmm 13 = zpack s5 ∧ st.zmm 14 = zpack s6 ∧ st.zmm 15 = zpack s7 ∧ st.zmm 24 = zpack s8 ∧ st.zmm 25 = zpack s9 ∧ st.zmm 26 = zpack s10 ∧ st.zmm 27 = zpack s11 ∧ st.zmm 28 = zpack s12 ∧ st.zmm 29 = zpack s13 ∧ st.zmm 30 = zpack s14 ∧ st.zmm 31 = zpack s15

/-- The sixteen offsets a round reads its message words at: 32-bit numbers at `rdi`, four bytes apart. -/
def Row (st : State) (o0 o1 o2 o3 o4 o5 o6 o7 o8 o9 o10 o11 o12 o13 o14 o15 : BitVec 64) : Prop :=
  st.mem.read (st.rdi) 32 = some o0 ∧ st.mem.read (st.rdi + 0x4#64) 32 = some o1 ∧ st.mem.read (st.rdi + 0x8#64) 32 = some o2 ∧ st.mem.read (st.rdi + 0xC#64) 32 = some o3 ∧ st.mem.read (st.rdi + 0x10#64) 32 = some o4 ∧ st.mem.read (st.rdi + 0x14#64) 32 = some o5 ∧ st.mem.read (st.rdi + 0x18#64) 32 = some o6 ∧ st.mem.read (st.rdi + 0x1C#64) 32 = some o7 ∧ st.mem.read (st.rdi + 0x20#64) 32 = some o8 ∧ st.mem.read (st.rdi + 0x24#64) 32 = some o9 ∧ st.mem.read (st.rdi + 0x28#64) 32 = some o10 ∧ st.mem.read (st.rdi + 0x2C#64) 32 = some o11 ∧ st.mem.read (st.rdi + 0x30#64) 32 = some o12 ∧ st.mem.read (st.rdi + 0x34#64) 32 = some o13 ∧ st.mem.read (st.rdi + 0x38#64) 32 = some o14 ∧ st.mem.read (st.rdi + 0x3C#64) 32 = some o15

/-- The message words of both halves, where a round with those offsets reads them: word `k` of the first half
at `rsi + o k`, of the second 1024 bytes on. -/
def Msgs (st : State) (o0 o1 o2 o3 o4 o5 o6 o7 o8 o9 o10 o11 o12 o13 o14 o15 : BitVec 64) (m0 m1 m2 m3 m4 m5 m6 m7 m8 m9 m10 m11 m12 m13 m14 m15 n0 n1 n2 n3 n4 n5 n6 n7 n8 n9 n10 n11 n12 n13 n14 n15 : Nat → BitVec 32) : Prop :=
  st.mem.read512 (st.rsi + (o0 &&& 0xFFFFFFFF#64)) = some (zpack m0) ∧ st.mem.read512 (st.rsi + (o1 &&& 0xFFFFFFFF#64)) = some (zpack m1) ∧ st.mem.read512 (st.rsi + (o2 &&& 0xFFFFFFFF#64)) = some (zpack m2) ∧ st.mem.read512 (st.rsi + (o3 &&& 0xFFFFFFFF#64)) = some (zpack m3) ∧ st.mem.read512 (st.rsi + (o4 &&& 0xFFFFFFFF#64)) = some (zpack m4) ∧ st.mem.read512 (st.rsi + (o5 &&& 0xFFFFFFFF#64)) = some (zpack m5) ∧ st.mem.read512 (st.rsi + (o6 &&& 0xFFFFFFFF#64)) = some (zpack m6) ∧ st.mem.read512 (st.rsi + (o7 &&& 0xFFFFFFFF#64)) = some (zpack m7) ∧ st.mem.read512 (st.rsi + (o8 &&& 0xFFFFFFFF#64)) = some (zpack m8) ∧ st.mem.read512 (st.rsi + (o9 &&& 0xFFFFFFFF#64)) = some (zpack m9) ∧ st.mem.read512 (st.rsi + (o10 &&& 0xFFFFFFFF#64)) = some (zpack m10) ∧ st.mem.read512 (st.rsi + (o11 &&& 0xFFFFFFFF#64)) = some (zpack m11) ∧ st.mem.read512 (st.rsi + (o12 &&& 0xFFFFFFFF#64)) = some (zpack m12) ∧ st.mem.read512 (st.rsi + (o13 &&& 0xFFFFFFFF#64)) = some (zpack m13) ∧ st.mem.read512 (st.rsi + (o14 &&& 0xFFFFFFFF#64)) = some (zpack m14) ∧ st.mem.read512 (st.rsi + (o15 &&& 0xFFFFFFFF#64)) = some (zpack m15) ∧
  st.mem.read512 (st.rsi + ((o0 &&& 0xFFFFFFFF#64) + 0x400#64)) = some (zpack n0) ∧ st.mem.read512 (st.rsi + ((o1 &&& 0xFFFFFFFF#64) + 0x400#64)) = some (zpack n1) ∧ st.mem.read512 (st.rsi + ((o2 &&& 0xFFFFFFFF#64) + 0x400#64)) = some (zpack n2) ∧ st.mem.read512 (st.rsi + ((o3 &&& 0xFFFFFFFF#64) + 0x400#64)) = some (zpack n3) ∧ st.mem.read512 (st.rsi + ((o4 &&& 0xFFFFFFFF#64) + 0x400#64)) = some (zpack n4) ∧ st.mem.read512 (st.rsi + ((o5 &&& 0xFFFFFFFF#64) + 0x400#64)) = some (zpack n5) ∧ st.mem.read512 (st.rsi + ((o6 &&& 0xFFFFFFFF#64) + 0x400#64)) = some (zpack n6) ∧ st.mem.read512 (st.rsi + ((o7 &&& 0xFFFFFFFF#64) + 0x400#64)) = some (zpack n7) ∧ st.mem.read512 (st.rsi + ((o8 &&& 0xFFFFFFFF#64) + 0x400#64)) = some (zpack n8) ∧ st.mem.read512 (st.rsi + ((o9 &&& 0xFFFFFFFF#64) + 0x400#64)) = some (zpack n9) ∧ st.mem.read512 (st.rsi + ((o10 &&& 0xFFFFFFFF#64) + 0x400#64)) = some (zpack n10) ∧ st.mem.read512 (st.rsi + ((o11 &&& 0xFFFFFFFF#64) + 0x400#64)) = some (zpack n11) ∧ st.mem.read512 (st.rsi + ((o12 &&& 0xFFFFFFFF#64) + 0x400#64)) = some (zpack n12) ∧ st.mem.read512 (st.rsi + ((o13 &&& 0xFFFFFFFF#64) + 0x400#64)) = some (zpack n13) ∧ st.mem.read512 (st.rsi + ((o14 &&& 0xFFFFFFFF#64) + 0x400#64)) = some (zpack n14) ∧ st.mem.read512 (st.rsi + ((o15 &&& 0xFFFFFFFF#64) + 0x400#64)) = some (zpack n15)

/-- What a round leaves alone: memory, the flags and every general register but the four the offsets go through. -/
def Kept (s s' : State) : Prop :=
  s'.rbx = s.rbx ∧ s'.rsp = s.rsp ∧ s'.rbp = s.rbp ∧ s'.rsi = s.rsi ∧ s'.rdi = s.rdi ∧ s'.r9 = s.r9 ∧ s'.r12 = s.r12 ∧ s'.r13 = s.r13 ∧
    s'.r14 = s.r14 ∧ s'.r15 = s.r15 ∧ s'.w.r10 = s.w.r10 ∧ s'.w.r11 = s.w.r11 ∧ s'.zf = s.zf ∧ s'.cf = s.cf ∧ s'.mem = s.mem

set_option maxRecDepth 1000000 in
set_option maxHeartbeats 0 in
/-- **A round.** The 240 instructions from the round loop's head (0x10900) are the specification's round on
the state words of every lane of both halves, with the message words at the row's offsets, in the row's order. -/
theorem round (s0 s1 s2 s3 s4 s5 s6 s7 s8 s9 s10 s11 s12 s13 s14 s15 t0 t1 t2 t3 t4 t5 t6 t7 t8 t9 t10 t11 t12 t13 t14 t15 m0 m1 m2 m3 m4 m5 m6 m7 m8 m9 m10 m11 m12 m13 m14 m15 n0 n1 n2 n3 n4 n5 n6 n7 n8 n9 n10 n11 n12 n13 n14 n15 : Nat → BitVec 32) (o0 o1 o2 o3 o4 o5 o6 o7 o8 o9 o10 o11 o12 o13 o14 o15 : BitVec 64)
    (st : State) (hpc : st.pc = 0x10900)
    (ha : RowsA st s0 s1 s2 s3 s4 s5 s6 s7 s8 s9 s10 s11 s12 s13 s14 s15) (hb : RowsB st t0 t1 t2 t3 t4 t5 t6 t7 t8 t9 t10 t11 t12 t13 t14 t15) (ho : Row st o0 o1 o2 o3 o4 o5 o6 o7 o8 o9 o10 o11 o12 o13 o14 o15)
    (hm : Msgs st o0 o1 o2 o3 o4 o5 o6 o7 o8 o9 o10 o11 o12 o13 o14 o15 m0 m1 m2 m3 m4 m5 m6 m7 m8 m9 m10 m11 m12 m13 m14 m15 n0 n1 n2 n3 n4 n5 n6 n7 n8 n9 n10 n11 n12 n13 n14 n15) :
    ∃ st', steps Code_k32.prog 240 st = some st' ∧ st'.pc = 0x10EE3 ∧
      RowsA st' (fun i => (rnd #v[s0 i, s1 i, s2 i, s3 i, s4 i, s5 i, s6 i, s7 i, s8 i, s9 i, s10 i, s11 i, s12 i, s13 i, s14 i, s15 i] #v[m0 i, m1 i, m2 i, m3 i, m4 i, m5 i, m6 i, m7 i, m8 i, m9 i, m10 i, m11 i, m12 i, m13 i, m14 i, m15 i])[0]) (fun i => (rnd #v[s0 i, s1 i, s2 i, s3 i, s4 i, s5 i, s6 i, s7 i, s8 i, s9 i, s10 i, s11 i, s12 i, s13 i, s14 i, s15 i] #v[m0 i, m1 i, m2 i, m3 i, m4 i, m5 i, m6 i, m7 i, m8 i, m9 i, m10 i, m11 i, m12 i, m13 i, m14 i, m15 i])[1]) (fun i => (rnd #v[s0 i, s1 i, s2 i, s3 i, s4 i, s5 i, s6 i, s7 i, s8 i, s9 i, s10 i, s11 i, s12 i, s13 i, s14 i, s15 i] #v[m0 i, m1 i, m2 i, m3 i, m4 i, m5 i, m6 i, m7 i, m8 i, m9 i, m10 i, m11 i, m12 i, m13 i, m14 i, m15 i])[2]) (fun i => (rnd #v[s0 i, s1 i, s2 i, s3 i, s4 i, s5 i, s6 i, s7 i, s8 i, s9 i, s10 i, s11 i, s12 i, s13 i, s14 i, s15 i] #v[m0 i, m1 i, m2 i, m3 i, m4 i, m5 i, m6 i, m7 i, m8 i, m9 i, m10 i, m11 i, m12 i, m13 i, m14 i, m15 i])[3]) (fun i => (rnd #v[s0 i, s1 i, s2 i, s3 i, s4 i, s5 i, s6 i, s7 i, s8 i, s9 i, s10 i, s11 i, s12 i, s13 i, s14 i, s15 i] #v[m0 i, m1 i, m2 i, m3 i, m4 i, m5 i, m6 i, m7 i, m8 i, m9 i, m10 i, m11 i, m12 i, m13 i, m14 i, m15 i])[4]) (fun i => (rnd #v[s0 i, s1 i, s2 i, s3 i, s4 i, s5 i, s6 i, s7 i, s8 i, s9 i, s10 i, s11 i, s12 i, s13 i, s14 i, s15 i] #v[m0 i, m1 i, m2 i, m3 i, m4 i, m5 i, m6 i, m7 i, m8 i, m9 i, m10 i, m11 i, m12 i, m13 i, m14 i, m15 i])[5]) (fun i => (rnd #v[s0 i, s1 i, s2 i, s3 i, s4 i, s5 i, s6 i, s7 i, s8 i, s9 i, s10 i, s11 i, s12 i, s13 i, s14 i, s15 i] #v[m0 i, m1 i, m2 i, m3 i, m4 i, m5 i, m6 i, m7 i, m8 i, m9 i, m10 i, m11 i, m12 i, m13 i, m14 i, m15 i])[6]) (fun i => (rnd #v[s0 i, s1 i, s2 i, s3 i, s4 i, s5 i, s6 i, s7 i, s8 i, s9 i, s10 i, s11 i, s12 i, s13 i, s14 i, s15 i] #v[m0 i, m1 i, m2 i, m3 i, m4 i, m5 i, m6 i, m7 i, m8 i, m9 i, m10 i, m11 i, m12 i, m13 i, m14 i, m15 i])[7]) (fun i => (rnd #v[s0 i, s1 i, s2 i, s3 i, s4 i, s5 i, s6 i, s7 i, s8 i, s9 i, s10 i, s11 i, s12 i, s13 i, s14 i, s15 i] #v[m0 i, m1 i, m2 i, m3 i, m4 i, m5 i, m6 i, m7 i, m8 i, m9 i, m10 i, m11 i, m12 i, m13 i, m14 i, m15 i])[8]) (fun i => (rnd #v[s0 i, s1 i, s2 i, s3 i, s4 i, s5 i, s6 i, s7 i, s8 i, s9 i, s10 i, s11 i, s12 i, s13 i, s14 i, s15 i] #v[m0 i, m1 i, m2 i, m3 i, m4 i, m5 i, m6 i, m7 i, m8 i, m9 i, m10 i, m11 i, m12 i, m13 i, m14 i, m15 i])[9]) (fun i => (rnd #v[s0 i, s1 i, s2 i, s3 i, s4 i, s5 i, s6 i, s7 i, s8 i, s9 i, s10 i, s11 i, s12 i, s13 i, s14 i, s15 i] #v[m0 i, m1 i, m2 i, m3 i, m4 i, m5 i, m6 i, m7 i, m8 i, m9 i, m10 i, m11 i, m12 i, m13 i, m14 i, m15 i])[10]) (fun i => (rnd #v[s0 i, s1 i, s2 i, s3 i, s4 i, s5 i, s6 i, s7 i, s8 i, s9 i, s10 i, s11 i, s12 i, s13 i, s14 i, s15 i] #v[m0 i, m1 i, m2 i, m3 i, m4 i, m5 i, m6 i, m7 i, m8 i, m9 i, m10 i, m11 i, m12 i, m13 i, m14 i, m15 i])[11]) (fun i => (rnd #v[s0 i, s1 i, s2 i, s3 i, s4 i, s5 i, s6 i, s7 i, s8 i, s9 i, s10 i, s11 i, s12 i, s13 i, s14 i, s15 i] #v[m0 i, m1 i, m2 i, m3 i, m4 i, m5 i, m6 i, m7 i, m8 i, m9 i, m10 i, m11 i, m12 i, m13 i, m14 i, m15 i])[12]) (fun i => (rnd #v[s0 i, s1 i, s2 i, s3 i, s4 i, s5 i, s6 i, s7 i, s8 i, s9 i, s10 i, s11 i, s12 i, s13 i, s14 i, s15 i] #v[m0 i, m1 i, m2 i, m3 i, m4 i, m5 i, m6 i, m7 i, m8 i, m9 i, m10 i, m11 i, m12 i, m13 i, m14 i, m15 i])[13]) (fun i => (rnd #v[s0 i, s1 i, s2 i, s3 i, s4 i, s5 i, s6 i, s7 i, s8 i, s9 i, s10 i, s11 i, s12 i, s13 i, s14 i, s15 i] #v[m0 i, m1 i, m2 i, m3 i, m4 i, m5 i, m6 i, m7 i, m8 i, m9 i, m10 i, m11 i, m12 i, m13 i, m14 i, m15 i])[14]) (fun i => (rnd #v[s0 i, s1 i, s2 i, s3 i, s4 i, s5 i, s6 i, s7 i, s8 i, s9 i, s10 i, s11 i, s12 i, s13 i, s14 i, s15 i] #v[m0 i, m1 i, m2 i, m3 i, m4 i, m5 i, m6 i, m7 i, m8 i, m9 i, m10 i, m11 i, m12 i, m13 i, m14 i, m15 i])[15]) ∧
      RowsB st' (fun i => (rnd #v[t0 i, t1 i, t2 i, t3 i, t4 i, t5 i, t6 i, t7 i, t8 i, t9 i, t10 i, t11 i, t12 i, t13 i, t14 i, t15 i] #v[n0 i, n1 i, n2 i, n3 i, n4 i, n5 i, n6 i, n7 i, n8 i, n9 i, n10 i, n11 i, n12 i, n13 i, n14 i, n15 i])[0]) (fun i => (rnd #v[t0 i, t1 i, t2 i, t3 i, t4 i, t5 i, t6 i, t7 i, t8 i, t9 i, t10 i, t11 i, t12 i, t13 i, t14 i, t15 i] #v[n0 i, n1 i, n2 i, n3 i, n4 i, n5 i, n6 i, n7 i, n8 i, n9 i, n10 i, n11 i, n12 i, n13 i, n14 i, n15 i])[1]) (fun i => (rnd #v[t0 i, t1 i, t2 i, t3 i, t4 i, t5 i, t6 i, t7 i, t8 i, t9 i, t10 i, t11 i, t12 i, t13 i, t14 i, t15 i] #v[n0 i, n1 i, n2 i, n3 i, n4 i, n5 i, n6 i, n7 i, n8 i, n9 i, n10 i, n11 i, n12 i, n13 i, n14 i, n15 i])[2]) (fun i => (rnd #v[t0 i, t1 i, t2 i, t3 i, t4 i, t5 i, t6 i, t7 i, t8 i, t9 i, t10 i, t11 i, t12 i, t13 i, t14 i, t15 i] #v[n0 i, n1 i, n2 i, n3 i, n4 i, n5 i, n6 i, n7 i, n8 i, n9 i, n10 i, n11 i, n12 i, n13 i, n14 i, n15 i])[3]) (fun i => (rnd #v[t0 i, t1 i, t2 i, t3 i, t4 i, t5 i, t6 i, t7 i, t8 i, t9 i, t10 i, t11 i, t12 i, t13 i, t14 i, t15 i] #v[n0 i, n1 i, n2 i, n3 i, n4 i, n5 i, n6 i, n7 i, n8 i, n9 i, n10 i, n11 i, n12 i, n13 i, n14 i, n15 i])[4]) (fun i => (rnd #v[t0 i, t1 i, t2 i, t3 i, t4 i, t5 i, t6 i, t7 i, t8 i, t9 i, t10 i, t11 i, t12 i, t13 i, t14 i, t15 i] #v[n0 i, n1 i, n2 i, n3 i, n4 i, n5 i, n6 i, n7 i, n8 i, n9 i, n10 i, n11 i, n12 i, n13 i, n14 i, n15 i])[5]) (fun i => (rnd #v[t0 i, t1 i, t2 i, t3 i, t4 i, t5 i, t6 i, t7 i, t8 i, t9 i, t10 i, t11 i, t12 i, t13 i, t14 i, t15 i] #v[n0 i, n1 i, n2 i, n3 i, n4 i, n5 i, n6 i, n7 i, n8 i, n9 i, n10 i, n11 i, n12 i, n13 i, n14 i, n15 i])[6]) (fun i => (rnd #v[t0 i, t1 i, t2 i, t3 i, t4 i, t5 i, t6 i, t7 i, t8 i, t9 i, t10 i, t11 i, t12 i, t13 i, t14 i, t15 i] #v[n0 i, n1 i, n2 i, n3 i, n4 i, n5 i, n6 i, n7 i, n8 i, n9 i, n10 i, n11 i, n12 i, n13 i, n14 i, n15 i])[7]) (fun i => (rnd #v[t0 i, t1 i, t2 i, t3 i, t4 i, t5 i, t6 i, t7 i, t8 i, t9 i, t10 i, t11 i, t12 i, t13 i, t14 i, t15 i] #v[n0 i, n1 i, n2 i, n3 i, n4 i, n5 i, n6 i, n7 i, n8 i, n9 i, n10 i, n11 i, n12 i, n13 i, n14 i, n15 i])[8]) (fun i => (rnd #v[t0 i, t1 i, t2 i, t3 i, t4 i, t5 i, t6 i, t7 i, t8 i, t9 i, t10 i, t11 i, t12 i, t13 i, t14 i, t15 i] #v[n0 i, n1 i, n2 i, n3 i, n4 i, n5 i, n6 i, n7 i, n8 i, n9 i, n10 i, n11 i, n12 i, n13 i, n14 i, n15 i])[9]) (fun i => (rnd #v[t0 i, t1 i, t2 i, t3 i, t4 i, t5 i, t6 i, t7 i, t8 i, t9 i, t10 i, t11 i, t12 i, t13 i, t14 i, t15 i] #v[n0 i, n1 i, n2 i, n3 i, n4 i, n5 i, n6 i, n7 i, n8 i, n9 i, n10 i, n11 i, n12 i, n13 i, n14 i, n15 i])[10]) (fun i => (rnd #v[t0 i, t1 i, t2 i, t3 i, t4 i, t5 i, t6 i, t7 i, t8 i, t9 i, t10 i, t11 i, t12 i, t13 i, t14 i, t15 i] #v[n0 i, n1 i, n2 i, n3 i, n4 i, n5 i, n6 i, n7 i, n8 i, n9 i, n10 i, n11 i, n12 i, n13 i, n14 i, n15 i])[11]) (fun i => (rnd #v[t0 i, t1 i, t2 i, t3 i, t4 i, t5 i, t6 i, t7 i, t8 i, t9 i, t10 i, t11 i, t12 i, t13 i, t14 i, t15 i] #v[n0 i, n1 i, n2 i, n3 i, n4 i, n5 i, n6 i, n7 i, n8 i, n9 i, n10 i, n11 i, n12 i, n13 i, n14 i, n15 i])[12]) (fun i => (rnd #v[t0 i, t1 i, t2 i, t3 i, t4 i, t5 i, t6 i, t7 i, t8 i, t9 i, t10 i, t11 i, t12 i, t13 i, t14 i, t15 i] #v[n0 i, n1 i, n2 i, n3 i, n4 i, n5 i, n6 i, n7 i, n8 i, n9 i, n10 i, n11 i, n12 i, n13 i, n14 i, n15 i])[13]) (fun i => (rnd #v[t0 i, t1 i, t2 i, t3 i, t4 i, t5 i, t6 i, t7 i, t8 i, t9 i, t10 i, t11 i, t12 i, t13 i, t14 i, t15 i] #v[n0 i, n1 i, n2 i, n3 i, n4 i, n5 i, n6 i, n7 i, n8 i, n9 i, n10 i, n11 i, n12 i, n13 i, n14 i, n15 i])[14]) (fun i => (rnd #v[t0 i, t1 i, t2 i, t3 i, t4 i, t5 i, t6 i, t7 i, t8 i, t9 i, t10 i, t11 i, t12 i, t13 i, t14 i, t15 i] #v[n0 i, n1 i, n2 i, n3 i, n4 i, n5 i, n6 i, n7 i, n8 i, n9 i, n10 i, n11 i, n12 i, n13 i, n14 i, n15 i])[15]) ∧
      Kept st st' := by
  obtain ⟨rax, rcx, rdx, rbx, rsp, rbp, rsi, rdi, r8, r9, r12, r13, r14, r15, zf, cf, x0, x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12, x13, x14, x15, mem, pc, ⟨r10, r11, u0, u1, u2, u3, u4, u5, u6, u7, u8, u9, u10, u11, u12, u13, u14, u15, z16, z17, z18, z19, z20, z21, z22, z23, z24, z25, z26, z27, z28, z29, z30, z31, k1, k2⟩⟩ := st
  obtain ⟨ha0, ha1, ha2, ha3, ha4, ha5, ha6, ha7, ha8, ha9, ha10, ha11, ha12, ha13, ha14, ha15⟩ := ha
  obtain ⟨hb0, hb1, hb2, hb3, hb4, hb5, hb6, hb7, hb8, hb9, hb10, hb11, hb12, hb13, hb14, hb15⟩ := hb
  obtain ⟨ho0, ho1, ho2, ho3, ho4, ho5, ho6, ho7, ho8, ho9, ho10, ho11, ho12, ho13, ho14, ho15⟩ := ho
  obtain ⟨hm0, hm1, hm2, hm3, hm4, hm5, hm6, hm7, hm8, hm9, hm10, hm11, hm12, hm13, hm14, hm15, hn0, hn1, hn2, hn3, hn4, hn5, hn6, hn7, hn8, hn9, hn10, hn11, hn12, hn13, hn14, hn15⟩ := hm
  simp only [State.zmm] at hpc ha0 hb0 ha1 hb1 ha2 hb2 ha3 hb3 ha4 hb4 ha5 hb5 ha6 hb6 ha7 hb7 ha8 hb8 ha9 hb9 ha10 hb10 ha11 hb11 ha12 hb12 ha13 hb13 ha14 hb14 ha15 hb15
  simp only at ho0 hm0 hn0 ho1 hm1 hn1 ho2 hm2 hn2 ho3 hm3 hn3 ho4 hm4 hn4 ho5 hm5 hn5 ho6 hm6 hn6 ho7 hm7 hn7 ho8 hm8 hn8 ho9 hm9 hn9 ho10 hm10 hn10 ho11 hm11 hn11 ho12 hm12 hn12 ho13 hm13 hn13 ho14 hm14 hn14 ho15 hm15 hn15
  subst hpc
  have e0 : x0 = zlo (zpack s0) := by rw [← ha0, zlo_zjoin]
  have f0 : u0 = zhi (zpack s0) := by rw [← ha0, zhi_zjoin]
  subst e0 f0
  have e1 : x1 = zlo (zpack s1) := by rw [← ha1, zlo_zjoin]
  have f1 : u1 = zhi (zpack s1) := by rw [← ha1, zhi_zjoin]
  subst e1 f1
  have e2 : x2 = zlo (zpack s2) := by rw [← ha2, zlo_zjoin]
  have f2 : u2 = zhi (zpack s2) := by rw [← ha2, zhi_zjoin]
  subst e2 f2
  have e3 : x3 = zlo (zpack s3) := by rw [← ha3, zlo_zjoin]
  have f3 : u3 = zhi (zpack s3) := by rw [← ha3, zhi_zjoin]
  subst e3 f3
  have e4 : x4 = zlo (zpack s4) := by rw [← ha4, zlo_zjoin]
  have f4 : u4 = zhi (zpack s4) := by rw [← ha4, zhi_zjoin]
  subst e4 f4
  have e5 : x5 = zlo (zpack s5) := by rw [← ha5, zlo_zjoin]
  have f5 : u5 = zhi (zpack s5) := by rw [← ha5, zhi_zjoin]
  subst e5 f5
  have e6 : x6 = zlo (zpack s6) := by rw [← ha6, zlo_zjoin]
  have f6 : u6 = zhi (zpack s6) := by rw [← ha6, zhi_zjoin]
  subst e6 f6
  have e7 : x7 = zlo (zpack s7) := by rw [← ha7, zlo_zjoin]
  have f7 : u7 = zhi (zpack s7) := by rw [← ha7, zhi_zjoin]
  subst e7 f7
  subst ha8
  subst ha9
  subst ha10
  subst ha11
  subst ha12
  subst ha13
  subst ha14
  subst ha15
  have e8 : x8 = zlo (zpack t0) := by rw [← hb0, zlo_zjoin]
  have f8 : u8 = zhi (zpack t0) := by rw [← hb0, zhi_zjoin]
  subst e8 f8
  have e9 : x9 = zlo (zpack t1) := by rw [← hb1, zlo_zjoin]
  have f9 : u9 = zhi (zpack t1) := by rw [← hb1, zhi_zjoin]
  subst e9 f9
  have e10 : x10 = zlo (zpack t2) := by rw [← hb2, zlo_zjoin]
  have f10 : u10 = zhi (zpack t2) := by rw [← hb2, zhi_zjoin]
  subst e10 f10
  have e11 : x11 = zlo (zpack t3) := by rw [← hb3, zlo_zjoin]
  have f11 : u11 = zhi (zpack t3) := by rw [← hb3, zhi_zjoin]
  subst e11 f11
  have e12 : x12 = zlo (zpack t4) := by rw [← hb4, zlo_zjoin]
  have f12 : u12 = zhi (zpack t4) := by rw [← hb4, zhi_zjoin]
  subst e12 f12
  have e13 : x13 = zlo (zpack t5) := by rw [← hb5, zlo_zjoin]
  have f13 : u13 = zhi (zpack t5) := by rw [← hb5, zhi_zjoin]
  subst e13 f13
  have e14 : x14 = zlo (zpack t6) := by rw [← hb6, zlo_zjoin]
  have f14 : u14 = zhi (zpack t6) := by rw [← hb6, zhi_zjoin]
  subst e14 f14
  have e15 : x15 = zlo (zpack t7) := by rw [← hb7, zlo_zjoin]
  have f15 : u15 = zhi (zpack t7) := by rw [← hb7, zhi_zjoin]
  subst e15 f15
  subst hb8
  subst hb9
  subst hb10
  subst hb11
  subst hb12
  subst hb13
  subst hb14
  subst hb15
  run_fn [zjoin_split, zlo_zjoin, zhi_zjoin, ho0, hm0, hn0, ho1, hm1, hn1, ho2, hm2, hn2, ho3, hm3, hn3, ho4, hm4, hn4, ho5, hm5, hn5, ho6, hm6, hn6, ho7, hm7, hn7, ho8, hm8, hn8, ho9, hm9, hn9, ho10, hm10, hn10, ho11, hm11, hn11, ho12, hm12, hn12, ho13, hm13, hn13, ho14, hm14, hn14, ho15, hm15, hn15]
  refine ⟨_, rfl, rfl, ?_, ?_, ?_⟩
  · simp only [RowsA, State.zmm, zjoin_split]
    refine ⟨?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_⟩ <;>
      (apply zpack_congr; intro i hi; simp only [zjoin_split, zdw_zmap2 _ _ _ hi, zdw_zmap1 _ _ hi, zdw_xor _ _ _ hi, zdw_zpack _ i hi]; eval_spec; bv_decide (config := { timeout := 900 }))
  · simp only [RowsB, State.zmm, zjoin_split]
    refine ⟨?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_⟩ <;>
      (apply zpack_congr; intro i hi; simp only [zjoin_split, zdw_zmap2 _ _ _ hi, zdw_zmap1 _ _ hi, zdw_xor _ _ _ hi, zdw_zpack _ i hi]; eval_spec; bv_decide (config := { timeout := 900 }))
  · simp only [Kept, and_self]

end K32
