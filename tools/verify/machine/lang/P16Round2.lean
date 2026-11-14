import P16Round
open X86 Cells Blake3Generic

/-! # The second round of the wide parent kernel's loop body

Written by gen_p16.py from the kernel's lifted instructions. Before the message registers are rotated,
the second 112 instructions read the permuted message words directly from them. -/

namespace P16

set_option maxRecDepth 1000000 in
set_option maxHeartbeats 0 in
/-- **Second round.** The 112 instructions at 0x18629 are the specification's round on the state
words of every lane, with `PERMUTE` of that lane's message words. -/
theorem round2 (s0 s1 s2 s3 s4 s5 s6 s7 s8 s9 s10 s11 s12 s13 s14 s15 m0 m1 m2 m3 m4 m5 m6 m7 m8 m9 m10 m11 m12 m13 m14 m15 : Nat → BitVec 32) (st : State) (hpc : st.pc = 0x18629)
    (hv : Rows st s0 s1 s2 s3 s4 s5 s6 s7 s8 s9 s10 s11 s12 s13 s14 s15) (hm : Msgs st m0 m1 m2 m3 m4 m5 m6 m7 m8 m9 m10 m11 m12 m13 m14 m15) :
    ∃ st', steps Code_p16.prog 112 st = some st' ∧ st'.pc = 0x188E9 ∧
      Rows st' (fun i => (rnd #v[s0 i, s1 i, s2 i, s3 i, s4 i, s5 i, s6 i, s7 i, s8 i, s9 i, s10 i, s11 i, s12 i, s13 i, s14 i, s15 i] #v[m2 i, m6 i, m3 i, m10 i, m7 i, m0 i, m4 i, m13 i, m1 i, m11 i, m12 i, m5 i, m9 i, m14 i, m15 i, m8 i])[0]) (fun i => (rnd #v[s0 i, s1 i, s2 i, s3 i, s4 i, s5 i, s6 i, s7 i, s8 i, s9 i, s10 i, s11 i, s12 i, s13 i, s14 i, s15 i] #v[m2 i, m6 i, m3 i, m10 i, m7 i, m0 i, m4 i, m13 i, m1 i, m11 i, m12 i, m5 i, m9 i, m14 i, m15 i, m8 i])[1]) (fun i => (rnd #v[s0 i, s1 i, s2 i, s3 i, s4 i, s5 i, s6 i, s7 i, s8 i, s9 i, s10 i, s11 i, s12 i, s13 i, s14 i, s15 i] #v[m2 i, m6 i, m3 i, m10 i, m7 i, m0 i, m4 i, m13 i, m1 i, m11 i, m12 i, m5 i, m9 i, m14 i, m15 i, m8 i])[2]) (fun i => (rnd #v[s0 i, s1 i, s2 i, s3 i, s4 i, s5 i, s6 i, s7 i, s8 i, s9 i, s10 i, s11 i, s12 i, s13 i, s14 i, s15 i] #v[m2 i, m6 i, m3 i, m10 i, m7 i, m0 i, m4 i, m13 i, m1 i, m11 i, m12 i, m5 i, m9 i, m14 i, m15 i, m8 i])[3]) (fun i => (rnd #v[s0 i, s1 i, s2 i, s3 i, s4 i, s5 i, s6 i, s7 i, s8 i, s9 i, s10 i, s11 i, s12 i, s13 i, s14 i, s15 i] #v[m2 i, m6 i, m3 i, m10 i, m7 i, m0 i, m4 i, m13 i, m1 i, m11 i, m12 i, m5 i, m9 i, m14 i, m15 i, m8 i])[4]) (fun i => (rnd #v[s0 i, s1 i, s2 i, s3 i, s4 i, s5 i, s6 i, s7 i, s8 i, s9 i, s10 i, s11 i, s12 i, s13 i, s14 i, s15 i] #v[m2 i, m6 i, m3 i, m10 i, m7 i, m0 i, m4 i, m13 i, m1 i, m11 i, m12 i, m5 i, m9 i, m14 i, m15 i, m8 i])[5]) (fun i => (rnd #v[s0 i, s1 i, s2 i, s3 i, s4 i, s5 i, s6 i, s7 i, s8 i, s9 i, s10 i, s11 i, s12 i, s13 i, s14 i, s15 i] #v[m2 i, m6 i, m3 i, m10 i, m7 i, m0 i, m4 i, m13 i, m1 i, m11 i, m12 i, m5 i, m9 i, m14 i, m15 i, m8 i])[6]) (fun i => (rnd #v[s0 i, s1 i, s2 i, s3 i, s4 i, s5 i, s6 i, s7 i, s8 i, s9 i, s10 i, s11 i, s12 i, s13 i, s14 i, s15 i] #v[m2 i, m6 i, m3 i, m10 i, m7 i, m0 i, m4 i, m13 i, m1 i, m11 i, m12 i, m5 i, m9 i, m14 i, m15 i, m8 i])[7]) (fun i => (rnd #v[s0 i, s1 i, s2 i, s3 i, s4 i, s5 i, s6 i, s7 i, s8 i, s9 i, s10 i, s11 i, s12 i, s13 i, s14 i, s15 i] #v[m2 i, m6 i, m3 i, m10 i, m7 i, m0 i, m4 i, m13 i, m1 i, m11 i, m12 i, m5 i, m9 i, m14 i, m15 i, m8 i])[8]) (fun i => (rnd #v[s0 i, s1 i, s2 i, s3 i, s4 i, s5 i, s6 i, s7 i, s8 i, s9 i, s10 i, s11 i, s12 i, s13 i, s14 i, s15 i] #v[m2 i, m6 i, m3 i, m10 i, m7 i, m0 i, m4 i, m13 i, m1 i, m11 i, m12 i, m5 i, m9 i, m14 i, m15 i, m8 i])[9]) (fun i => (rnd #v[s0 i, s1 i, s2 i, s3 i, s4 i, s5 i, s6 i, s7 i, s8 i, s9 i, s10 i, s11 i, s12 i, s13 i, s14 i, s15 i] #v[m2 i, m6 i, m3 i, m10 i, m7 i, m0 i, m4 i, m13 i, m1 i, m11 i, m12 i, m5 i, m9 i, m14 i, m15 i, m8 i])[10]) (fun i => (rnd #v[s0 i, s1 i, s2 i, s3 i, s4 i, s5 i, s6 i, s7 i, s8 i, s9 i, s10 i, s11 i, s12 i, s13 i, s14 i, s15 i] #v[m2 i, m6 i, m3 i, m10 i, m7 i, m0 i, m4 i, m13 i, m1 i, m11 i, m12 i, m5 i, m9 i, m14 i, m15 i, m8 i])[11]) (fun i => (rnd #v[s0 i, s1 i, s2 i, s3 i, s4 i, s5 i, s6 i, s7 i, s8 i, s9 i, s10 i, s11 i, s12 i, s13 i, s14 i, s15 i] #v[m2 i, m6 i, m3 i, m10 i, m7 i, m0 i, m4 i, m13 i, m1 i, m11 i, m12 i, m5 i, m9 i, m14 i, m15 i, m8 i])[12]) (fun i => (rnd #v[s0 i, s1 i, s2 i, s3 i, s4 i, s5 i, s6 i, s7 i, s8 i, s9 i, s10 i, s11 i, s12 i, s13 i, s14 i, s15 i] #v[m2 i, m6 i, m3 i, m10 i, m7 i, m0 i, m4 i, m13 i, m1 i, m11 i, m12 i, m5 i, m9 i, m14 i, m15 i, m8 i])[13]) (fun i => (rnd #v[s0 i, s1 i, s2 i, s3 i, s4 i, s5 i, s6 i, s7 i, s8 i, s9 i, s10 i, s11 i, s12 i, s13 i, s14 i, s15 i] #v[m2 i, m6 i, m3 i, m10 i, m7 i, m0 i, m4 i, m13 i, m1 i, m11 i, m12 i, m5 i, m9 i, m14 i, m15 i, m8 i])[14]) (fun i => (rnd #v[s0 i, s1 i, s2 i, s3 i, s4 i, s5 i, s6 i, s7 i, s8 i, s9 i, s10 i, s11 i, s12 i, s13 i, s14 i, s15 i] #v[m2 i, m6 i, m3 i, m10 i, m7 i, m0 i, m4 i, m13 i, m1 i, m11 i, m12 i, m5 i, m9 i, m14 i, m15 i, m8 i])[15]) ∧
      Msgs st' m0 m1 m2 m3 m4 m5 m6 m7 m8 m9 m10 m11 m12 m13 m14 m15 ∧ Kept st st' := by
  obtain ⟨rax, rcx, rdx, rbx, rsp, rbp, rsi, rdi, r8, r9, r12, r13, r14, r15, zf, cf, x0, x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12, x13, x14, x15, mem, pc, ⟨r10, r11, u0, u1, u2, u3, u4, u5, u6, u7, u8, u9, u10, u11, u12, u13, u14, u15, z16, z17, z18, z19, z20, z21, z22, z23, z24, z25, z26, z27, z28, z29, z30, z31⟩⟩ := st
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
