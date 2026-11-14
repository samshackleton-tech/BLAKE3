import Cells
import Flat
import WideLemmas
import Code_p16
open X86 Cells Blake3Generic

/-! # A round of the wide parent kernel is the specification's round, in every lane

Written by gen_p16.py from the kernel's lifted instructions. Sixteen ZMM registers hold the sixteen state
words of sixteen inputs (lane `i` of each is input `i`'s), sixteen more the message words. -/

namespace P16

/-- The state words, one register each: lane `i` of the register of word `k` is `s k i`. -/
def Rows (st : State) (s0 s1 s2 s3 s4 s5 s6 s7 s8 s9 s10 s11 s12 s13 s14 s15 : Nat → BitVec 32) : Prop :=
  st.zmm 0 = zpack s0 ∧ st.zmm 1 = zpack s1 ∧ st.zmm 2 = zpack s2 ∧ st.zmm 3 = zpack s3 ∧ st.zmm 4 = zpack s4 ∧ st.zmm 5 = zpack s5 ∧ st.zmm 6 = zpack s6 ∧ st.zmm 7 = zpack s7 ∧ st.zmm 9 = zpack s8 ∧ st.zmm 10 = zpack s9 ∧ st.zmm 11 = zpack s10 ∧ st.zmm 12 = zpack s11 ∧ st.zmm 13 = zpack s12 ∧ st.zmm 14 = zpack s13 ∧ st.zmm 15 = zpack s14 ∧ st.zmm 24 = zpack s15

/-- The message words where the first round's instructions read them. -/
def Msgs (st : State) (m0 m1 m2 m3 m4 m5 m6 m7 m8 m9 m10 m11 m12 m13 m14 m15 : Nat → BitVec 32) : Prop :=
  st.zmm 28 = zpack m0 ∧ st.zmm 26 = zpack m1 ∧ st.zmm 20 = zpack m2 ∧ st.zmm 29 = zpack m3 ∧ st.zmm 27 = zpack m4 ∧ st.zmm 25 = zpack m5 ∧ st.zmm 22 = zpack m6 ∧ st.zmm 23 = zpack m7 ∧ st.zmm 30 = zpack m8 ∧ st.zmm 21 = zpack m9 ∧ st.zmm 18 = zpack m10 ∧ st.zmm 19 = zpack m11 ∧ st.zmm 31 = zpack m12 ∧ st.zmm 8 = zpack m13 ∧ st.zmm 17 = zpack m14 ∧ st.zmm 16 = zpack m15

/-- What a round leaves alone: the general registers, the flags, memory and the message registers. -/
def Kept (s s' : State) : Prop :=
  s'.rax = s.rax ∧ s'.rcx = s.rcx ∧ s'.rdx = s.rdx ∧ s'.rbx = s.rbx ∧ s'.rsp = s.rsp ∧ s'.rbp = s.rbp ∧ s'.rsi = s.rsi ∧ s'.rdi = s.rdi ∧
    s'.r8 = s.r8 ∧ s'.r9 = s.r9 ∧ s'.r12 = s.r12 ∧ s'.r13 = s.r13 ∧ s'.r14 = s.r14 ∧ s'.r15 = s.r15 ∧ s'.w.r10 = s.w.r10 ∧ s'.w.r11 = s.w.r11 ∧
    s'.zf = s.zf ∧ s'.cf = s.cf ∧ s'.mem = s.mem ∧
    s'.zmm 28 = s.zmm 28 ∧ s'.zmm 26 = s.zmm 26 ∧ s'.zmm 20 = s.zmm 20 ∧ s'.zmm 29 = s.zmm 29 ∧ s'.zmm 27 = s.zmm 27 ∧ s'.zmm 25 = s.zmm 25 ∧ s'.zmm 22 = s.zmm 22 ∧ s'.zmm 23 = s.zmm 23 ∧ s'.zmm 30 = s.zmm 30 ∧ s'.zmm 21 = s.zmm 21 ∧ s'.zmm 18 = s.zmm 18 ∧ s'.zmm 19 = s.zmm 19 ∧ s'.zmm 31 = s.zmm 31 ∧ s'.zmm 8 = s.zmm 8 ∧ s'.zmm 17 = s.zmm 17 ∧ s'.zmm 16 = s.zmm 16

set_option maxRecDepth 1000000 in
set_option maxHeartbeats 0 in
/-- **A round.** The 112 instructions from the round loop's head (0x18360) are the specification's round on
the state words of every lane, with that lane's message words. -/
theorem round (s0 s1 s2 s3 s4 s5 s6 s7 s8 s9 s10 s11 s12 s13 s14 s15 m0 m1 m2 m3 m4 m5 m6 m7 m8 m9 m10 m11 m12 m13 m14 m15 : Nat → BitVec 32) (st : State) (hpc : st.pc = 0x18360)
    (hv : Rows st s0 s1 s2 s3 s4 s5 s6 s7 s8 s9 s10 s11 s12 s13 s14 s15) (hm : Msgs st m0 m1 m2 m3 m4 m5 m6 m7 m8 m9 m10 m11 m12 m13 m14 m15) :
    ∃ st', steps Code_p16.prog 112 st = some st' ∧ st'.pc = 0x18620 ∧
      Rows st' (fun i => (rnd #v[s0 i, s1 i, s2 i, s3 i, s4 i, s5 i, s6 i, s7 i, s8 i, s9 i, s10 i, s11 i, s12 i, s13 i, s14 i, s15 i] #v[m0 i, m1 i, m2 i, m3 i, m4 i, m5 i, m6 i, m7 i, m8 i, m9 i, m10 i, m11 i, m12 i, m13 i, m14 i, m15 i])[0]) (fun i => (rnd #v[s0 i, s1 i, s2 i, s3 i, s4 i, s5 i, s6 i, s7 i, s8 i, s9 i, s10 i, s11 i, s12 i, s13 i, s14 i, s15 i] #v[m0 i, m1 i, m2 i, m3 i, m4 i, m5 i, m6 i, m7 i, m8 i, m9 i, m10 i, m11 i, m12 i, m13 i, m14 i, m15 i])[1]) (fun i => (rnd #v[s0 i, s1 i, s2 i, s3 i, s4 i, s5 i, s6 i, s7 i, s8 i, s9 i, s10 i, s11 i, s12 i, s13 i, s14 i, s15 i] #v[m0 i, m1 i, m2 i, m3 i, m4 i, m5 i, m6 i, m7 i, m8 i, m9 i, m10 i, m11 i, m12 i, m13 i, m14 i, m15 i])[2]) (fun i => (rnd #v[s0 i, s1 i, s2 i, s3 i, s4 i, s5 i, s6 i, s7 i, s8 i, s9 i, s10 i, s11 i, s12 i, s13 i, s14 i, s15 i] #v[m0 i, m1 i, m2 i, m3 i, m4 i, m5 i, m6 i, m7 i, m8 i, m9 i, m10 i, m11 i, m12 i, m13 i, m14 i, m15 i])[3]) (fun i => (rnd #v[s0 i, s1 i, s2 i, s3 i, s4 i, s5 i, s6 i, s7 i, s8 i, s9 i, s10 i, s11 i, s12 i, s13 i, s14 i, s15 i] #v[m0 i, m1 i, m2 i, m3 i, m4 i, m5 i, m6 i, m7 i, m8 i, m9 i, m10 i, m11 i, m12 i, m13 i, m14 i, m15 i])[4]) (fun i => (rnd #v[s0 i, s1 i, s2 i, s3 i, s4 i, s5 i, s6 i, s7 i, s8 i, s9 i, s10 i, s11 i, s12 i, s13 i, s14 i, s15 i] #v[m0 i, m1 i, m2 i, m3 i, m4 i, m5 i, m6 i, m7 i, m8 i, m9 i, m10 i, m11 i, m12 i, m13 i, m14 i, m15 i])[5]) (fun i => (rnd #v[s0 i, s1 i, s2 i, s3 i, s4 i, s5 i, s6 i, s7 i, s8 i, s9 i, s10 i, s11 i, s12 i, s13 i, s14 i, s15 i] #v[m0 i, m1 i, m2 i, m3 i, m4 i, m5 i, m6 i, m7 i, m8 i, m9 i, m10 i, m11 i, m12 i, m13 i, m14 i, m15 i])[6]) (fun i => (rnd #v[s0 i, s1 i, s2 i, s3 i, s4 i, s5 i, s6 i, s7 i, s8 i, s9 i, s10 i, s11 i, s12 i, s13 i, s14 i, s15 i] #v[m0 i, m1 i, m2 i, m3 i, m4 i, m5 i, m6 i, m7 i, m8 i, m9 i, m10 i, m11 i, m12 i, m13 i, m14 i, m15 i])[7]) (fun i => (rnd #v[s0 i, s1 i, s2 i, s3 i, s4 i, s5 i, s6 i, s7 i, s8 i, s9 i, s10 i, s11 i, s12 i, s13 i, s14 i, s15 i] #v[m0 i, m1 i, m2 i, m3 i, m4 i, m5 i, m6 i, m7 i, m8 i, m9 i, m10 i, m11 i, m12 i, m13 i, m14 i, m15 i])[8]) (fun i => (rnd #v[s0 i, s1 i, s2 i, s3 i, s4 i, s5 i, s6 i, s7 i, s8 i, s9 i, s10 i, s11 i, s12 i, s13 i, s14 i, s15 i] #v[m0 i, m1 i, m2 i, m3 i, m4 i, m5 i, m6 i, m7 i, m8 i, m9 i, m10 i, m11 i, m12 i, m13 i, m14 i, m15 i])[9]) (fun i => (rnd #v[s0 i, s1 i, s2 i, s3 i, s4 i, s5 i, s6 i, s7 i, s8 i, s9 i, s10 i, s11 i, s12 i, s13 i, s14 i, s15 i] #v[m0 i, m1 i, m2 i, m3 i, m4 i, m5 i, m6 i, m7 i, m8 i, m9 i, m10 i, m11 i, m12 i, m13 i, m14 i, m15 i])[10]) (fun i => (rnd #v[s0 i, s1 i, s2 i, s3 i, s4 i, s5 i, s6 i, s7 i, s8 i, s9 i, s10 i, s11 i, s12 i, s13 i, s14 i, s15 i] #v[m0 i, m1 i, m2 i, m3 i, m4 i, m5 i, m6 i, m7 i, m8 i, m9 i, m10 i, m11 i, m12 i, m13 i, m14 i, m15 i])[11]) (fun i => (rnd #v[s0 i, s1 i, s2 i, s3 i, s4 i, s5 i, s6 i, s7 i, s8 i, s9 i, s10 i, s11 i, s12 i, s13 i, s14 i, s15 i] #v[m0 i, m1 i, m2 i, m3 i, m4 i, m5 i, m6 i, m7 i, m8 i, m9 i, m10 i, m11 i, m12 i, m13 i, m14 i, m15 i])[12]) (fun i => (rnd #v[s0 i, s1 i, s2 i, s3 i, s4 i, s5 i, s6 i, s7 i, s8 i, s9 i, s10 i, s11 i, s12 i, s13 i, s14 i, s15 i] #v[m0 i, m1 i, m2 i, m3 i, m4 i, m5 i, m6 i, m7 i, m8 i, m9 i, m10 i, m11 i, m12 i, m13 i, m14 i, m15 i])[13]) (fun i => (rnd #v[s0 i, s1 i, s2 i, s3 i, s4 i, s5 i, s6 i, s7 i, s8 i, s9 i, s10 i, s11 i, s12 i, s13 i, s14 i, s15 i] #v[m0 i, m1 i, m2 i, m3 i, m4 i, m5 i, m6 i, m7 i, m8 i, m9 i, m10 i, m11 i, m12 i, m13 i, m14 i, m15 i])[14]) (fun i => (rnd #v[s0 i, s1 i, s2 i, s3 i, s4 i, s5 i, s6 i, s7 i, s8 i, s9 i, s10 i, s11 i, s12 i, s13 i, s14 i, s15 i] #v[m0 i, m1 i, m2 i, m3 i, m4 i, m5 i, m6 i, m7 i, m8 i, m9 i, m10 i, m11 i, m12 i, m13 i, m14 i, m15 i])[15]) ∧
      Msgs st' m0 m1 m2 m3 m4 m5 m6 m7 m8 m9 m10 m11 m12 m13 m14 m15 ∧ Kept st st' := by
  obtain ⟨rax, rcx, rdx, rbx, rsp, rbp, rsi, rdi, r8, r9, r12, r13, r14, r15, zf, cf, x0, x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12, x13, x14, x15, mem, pc, ⟨r10, r11, u0, u1, u2, u3, u4, u5, u6, u7, u8, u9, u10, u11, u12, u13, u14, u15, z16, z17, z18, z19, z20, z21, z22, z23, z24, z25, z26, z27, z28, z29, z30, z31, _, _⟩⟩ := st
  obtain ⟨hv0, hv1, hv2, hv3, hv4, hv5, hv6, hv7, hv8, hv9, hv10, hv11, hv12, hv13, hv14, hv15⟩ := hv
  obtain ⟨hm0, hm1, hm2, hm3, hm4, hm5, hm6, hm7, hm8, hm9, hm10, hm11, hm12, hm13, hm14, hm15⟩ := hm
  simp only [State.zmm] at hpc hv0 hv1 hv2 hv3 hv4 hv5 hv6 hv7 hv8 hv9 hv10 hv11 hv12 hv13 hv14 hv15 hm0 hm1 hm2 hm3 hm4 hm5 hm6 hm7 hm8 hm9 hm10 hm11 hm12 hm13 hm14 hm15
  subst hpc
  have e0 : x0 = zlo (zpack s0) := by rw [← hv0, zlo_zjoin]
  have f0 : u0 = zhi (zpack s0) := by rw [← hv0, zhi_zjoin]
  subst e0 f0
  have e1 : x1 = zlo (zpack s1) := by rw [← hv1, zlo_zjoin]
  have f1 : u1 = zhi (zpack s1) := by rw [← hv1, zhi_zjoin]
  subst e1 f1
  have e2 : x2 = zlo (zpack s2) := by rw [← hv2, zlo_zjoin]
  have f2 : u2 = zhi (zpack s2) := by rw [← hv2, zhi_zjoin]
  subst e2 f2
  have e3 : x3 = zlo (zpack s3) := by rw [← hv3, zlo_zjoin]
  have f3 : u3 = zhi (zpack s3) := by rw [← hv3, zhi_zjoin]
  subst e3 f3
  have e4 : x4 = zlo (zpack s4) := by rw [← hv4, zlo_zjoin]
  have f4 : u4 = zhi (zpack s4) := by rw [← hv4, zhi_zjoin]
  subst e4 f4
  have e5 : x5 = zlo (zpack s5) := by rw [← hv5, zlo_zjoin]
  have f5 : u5 = zhi (zpack s5) := by rw [← hv5, zhi_zjoin]
  subst e5 f5
  have e6 : x6 = zlo (zpack s6) := by rw [← hv6, zlo_zjoin]
  have f6 : u6 = zhi (zpack s6) := by rw [← hv6, zhi_zjoin]
  subst e6 f6
  have e7 : x7 = zlo (zpack s7) := by rw [← hv7, zlo_zjoin]
  have f7 : u7 = zhi (zpack s7) := by rw [← hv7, zhi_zjoin]
  subst e7 f7
  have e9 : x9 = zlo (zpack s8) := by rw [← hv8, zlo_zjoin]
  have f9 : u9 = zhi (zpack s8) := by rw [← hv8, zhi_zjoin]
  subst e9 f9
  have e10 : x10 = zlo (zpack s9) := by rw [← hv9, zlo_zjoin]
  have f10 : u10 = zhi (zpack s9) := by rw [← hv9, zhi_zjoin]
  subst e10 f10
  have e11 : x11 = zlo (zpack s10) := by rw [← hv10, zlo_zjoin]
  have f11 : u11 = zhi (zpack s10) := by rw [← hv10, zhi_zjoin]
  subst e11 f11
  have e12 : x12 = zlo (zpack s11) := by rw [← hv11, zlo_zjoin]
  have f12 : u12 = zhi (zpack s11) := by rw [← hv11, zhi_zjoin]
  subst e12 f12
  have e13 : x13 = zlo (zpack s12) := by rw [← hv12, zlo_zjoin]
  have f13 : u13 = zhi (zpack s12) := by rw [← hv12, zhi_zjoin]
  subst e13 f13
  have e14 : x14 = zlo (zpack s13) := by rw [← hv13, zlo_zjoin]
  have f14 : u14 = zhi (zpack s13) := by rw [← hv13, zhi_zjoin]
  subst e14 f14
  have e15 : x15 = zlo (zpack s14) := by rw [← hv14, zlo_zjoin]
  have f15 : u15 = zhi (zpack s14) := by rw [← hv14, zhi_zjoin]
  subst e15 f15
  subst hv15
  subst hm0
  subst hm1
  subst hm2
  subst hm3
  subst hm4
  subst hm5
  subst hm6
  subst hm7
  subst hm8
  subst hm9
  subst hm10
  subst hm11
  subst hm12
  have e8 : x8 = zlo (zpack m13) := by rw [← hm13, zlo_zjoin]
  have f8 : u8 = zhi (zpack m13) := by rw [← hm13, zhi_zjoin]
  subst e8 f8
  subst hm14
  subst hm15
  run_fn [zjoin_split, zlo_zjoin, zhi_zjoin]
  refine ⟨_, rfl, rfl, ?_, ?_, ?_⟩
  · simp only [Rows, State.zmm, zjoin_split]
    refine ⟨?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_⟩ <;>
      (apply zpack_congr; intro i hi; simp only [zjoin_split, zdw_zmap2 _ _ _ hi, zdw_zmap1 _ _ hi, zdw_xor _ _ _ hi, zdw_zpack _ i hi]; eval_spec; bv_decide (config := { timeout := 900 }))
  · simp only [Msgs, State.zmm, zjoin_split, and_self]
  · simp only [Kept, State.zmm, zjoin_split, and_self]

end P16
