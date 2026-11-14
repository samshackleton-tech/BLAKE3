import P16Round
import P16Round2
open X86 Cells Blake3Generic

/-! # The seven-round loop of the wide parent kernel `p16`

One pass of the loop body (`@round16`, `0x18360`) runs two rounds (`round`, `round2`) and rotates the
sixteen message registers (`permute2`, using 256 bytes of 64-byte-aligned stack scratch). Repeating 3.5
times from `r11 = 7` computes `rounds7` in every lane. -/

namespace P16

/-- The state words of every lane, as one vector per lane (`v i` is lane `i`'s 16 state words). -/
abbrev RowsV (st : State) (v : Nat → Vector (BitVec 32) 16) : Prop :=
  Rows st (fun i => (v i)[0]) (fun i => (v i)[1]) (fun i => (v i)[2]) (fun i => (v i)[3])
    (fun i => (v i)[4]) (fun i => (v i)[5]) (fun i => (v i)[6]) (fun i => (v i)[7])
    (fun i => (v i)[8]) (fun i => (v i)[9]) (fun i => (v i)[10]) (fun i => (v i)[11])
    (fun i => (v i)[12]) (fun i => (v i)[13]) (fun i => (v i)[14]) (fun i => (v i)[15])

/-- The message words of every lane, as one vector per lane (`m i` is lane `i`'s 16 message words). -/
abbrev MsgsV (st : State) (m : Nat → Vector (BitVec 32) 16) : Prop :=
  Msgs st (fun i => (m i)[0]) (fun i => (m i)[1]) (fun i => (m i)[2]) (fun i => (m i)[3])
    (fun i => (m i)[4]) (fun i => (m i)[5]) (fun i => (m i)[6]) (fun i => (m i)[7])
    (fun i => (m i)[8]) (fun i => (m i)[9]) (fun i => (m i)[10]) (fun i => (m i)[11])
    (fun i => (m i)[12]) (fun i => (m i)[13]) (fun i => (m i)[14]) (fun i => (m i)[15])

theorem permute_vec (v : Vector (BitVec 32) 16) :
    PERMUTE v = #v[v[2], v[6], v[3], v[10], v[7], v[0], v[4], v[13], v[1], v[11], v[12], v[5], v[9], v[14], v[15], v[8]] := by
  ext i hi; rcases i with _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | i
  all_goals first
    | omega
    | eval_spec

theorem permute2_vec (v : Vector (BitVec 32) 16) :
    PERMUTE (PERMUTE v) = #v[v[3], v[4], v[10], v[12], v[13], v[2], v[7], v[14], v[6], v[5], v[9], v[0], v[11], v[15], v[8], v[1]] := by
  rw [permute_vec, permute_vec]
  ext i hi; rcases i with _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | i
  all_goals first
    | omega
    | (simp only [Vector.getElem_mk, List.getElem_toArray, List.getElem_cons_succ, List.getElem_cons_zero])

set_option maxRecDepth 1000000 in
set_option maxHeartbeats 0 in
/-- **The message-register rotation at the bottom of the round loop** (`0x188EC` to `0x18360`, 21
instructions): leaves the state registers as they were, puts `PERMUTE (PERMUTE m)` into the message
registers, and keeps every byte outside `[st.rsp, st.rsp + 256)` unchanged. -/
theorem permute2 (s0 s1 s2 s3 s4 s5 s6 s7 s8 s9 s10 s11 s12 s13 s14 s15 m0 m1 m2 m3 m4 m5 m6 m7 m8 m9 m10 m11 m12 m13 m14 m15 : Nat → BitVec 32)
    (st : State) (hpc : st.pc = 0x188EC) (hal : aligned64 st.rsp = true)
    (ho0 : Owned64 st.mem (st.rsp + 0x0#64)) (ho1 : Owned64 st.mem (st.rsp + 0x40#64))
    (ho2 : Owned64 st.mem (st.rsp + 0x80#64)) (ho3 : Owned64 st.mem (st.rsp + 0xC0#64))
    (hv : Rows st s0 s1 s2 s3 s4 s5 s6 s7 s8 s9 s10 s11 s12 s13 s14 s15)
    (hm : Msgs st m0 m1 m2 m3 m4 m5 m6 m7 m8 m9 m10 m11 m12 m13 m14 m15) :
    ∃ st', steps Code_p16.prog 21 st = some st' ∧ st'.pc = 0x18360 ∧
      Rows st' s0 s1 s2 s3 s4 s5 s6 s7 s8 s9 s10 s11 s12 s13 s14 s15 ∧
      Msgs st' m3 m4 m10 m12 m13 m2 m7 m14 m6 m5 m9 m0 m11 m15 m8 m1 ∧
      st'.rax = st.rax ∧ st'.rcx = st.rcx ∧ st'.rdx = st.rdx ∧ st'.rbx = st.rbx ∧
      st'.rsp = st.rsp ∧ st'.rbp = st.rbp ∧ st'.rsi = st.rsi ∧ st'.rdi = st.rdi ∧
      st'.r8 = st.r8 ∧ st'.r9 = st.r9 ∧ st'.r12 = st.r12 ∧ st'.r13 = st.r13 ∧
      st'.r14 = st.r14 ∧ st'.r15 = st.r15 ∧ st'.w.r10 = st.w.r10 ∧ st'.w.r11 = st.w.r11 ∧
      st'.zf = st.zf ∧ st'.cf = st.cf ∧
      Owned64 st'.mem (st.rsp + 0x0#64) ∧ Owned64 st'.mem (st.rsp + 0x40#64) ∧
      Owned64 st'.mem (st.rsp + 0x80#64) ∧ Owned64 st'.mem (st.rsp + 0xC0#64) ∧
      (∀ x : BitVec 64, 256#64 ≤ x - st.rsp → st'.mem x = st.mem x) := by
  have ha0 : aligned64 (st.rsp + 0x0#64) = true := aligned64_add hal (by decide)
  have ha1 : aligned64 (st.rsp + 0x40#64) = true := aligned64_add hal (by decide)
  have ha2 : aligned64 (st.rsp + 0x80#64) = true := aligned64_add hal (by decide)
  have ha3 : aligned64 (st.rsp + 0xC0#64) = true := aligned64_add hal (by decide)
  obtain ⟨rax, rcx, rdx, rbx, rsp, rbp, rsi, rdi, r8, r9, r12, r13, r14, r15, zf, cf,
    x0, x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12, x13, x14, x15, mem, pc,
    ⟨r10, r11, u0, u1, u2, u3, u4, u5, u6, u7, u8, u9, u10, u11, u12, u13, u14, u15,
     z16, z17, z18, z19, z20, z21, z22, z23, z24, z25, z26, z27, z28, z29, z30, z31⟩⟩ := st
  obtain ⟨hv0, hv1, hv2, hv3, hv4, hv5, hv6, hv7, hv8, hv9, hv10, hv11, hv12, hv13, hv14, hv15⟩ := hv
  obtain ⟨hm0, hm1, hm2, hm3, hm4, hm5, hm6, hm7, hm8, hm9, hm10, hm11, hm12, hm13, hm14, hm15⟩ := hm
  simp only [State.zmm] at hpc hal ha0 ha1 ha2 ha3 ho0 ho1 ho2 ho3 hv0 hv1 hv2 hv3 hv4 hv5 hv6 hv7 hv8 hv9 hv10 hv11 hv12 hv13 hv14 hv15 hm0 hm1 hm2 hm3 hm4 hm5 hm6 hm7 hm8 hm9 hm10 hm11 hm12 hm13 hm14 hm15
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
  subst hm0 hm1 hm2 hm3 hm4 hm5 hm6 hm7 hm8 hm9 hm10 hm11 hm12
  have e8 : x8 = zlo (zpack m13) := by rw [← hm13, zlo_zjoin]
  have f8 : u8 = zhi (zpack m13) := by rw [← hm13, zhi_zjoin]
  subst e8 f8
  subst hm14 hm15
  have ho0' : Owned64 mem rsp := by simpa using ho0
  have w0 := write512_of ho0' (zpack m0)
  have ho1' := owned64_put512 mem rsp (rsp + 0x40#64) (zpack m0) ho1
  have ho2' := owned64_put512 mem rsp (rsp + 0x80#64) (zpack m0) ho2
  have ho3' := owned64_put512 mem rsp (rsp + 0xC0#64) (zpack m0) ho3
  have w1 := write512_of ho1' (zpack m1)
  have ho2'' := owned64_put512 _ (rsp + 0x40#64) (rsp + 0x80#64) (zpack m1) ho2'
  have ho3'' := owned64_put512 _ (rsp + 0x40#64) (rsp + 0xC0#64) (zpack m1) ho3'
  have w2 := write512_of ho2'' (zpack m2)
  have ho3''' := owned64_put512 _ (rsp + 0x80#64) (rsp + 0xC0#64) (zpack m2) ho3''
  have w3 := write512_of ho3''' (zpack m6)
  run_fn [hal, ha1, ha2, ha3, w0, w1, w2, w3, read512_put512_same, zjoin_split, zlo_zjoin, zhi_zjoin]
  refine ⟨_, rfl, rfl, ?_, ?_, rfl, rfl, rfl, rfl, rfl, rfl, rfl, rfl, rfl, rfl, rfl, rfl, rfl, rfl, rfl, rfl, rfl, rfl, ?_, ?_, ?_, ?_, ?_⟩
  · simp only [Rows, State.zmm, zjoin_split, and_self]
  · simp only [Msgs, State.zmm, zjoin_split, and_self]
  · simpa using owned64_put512 _ _ _ _ (owned64_put512 _ _ _ _ (owned64_put512 _ _ _ _ (owned64_put512 _ _ _ _ ho0')))
  · exact owned64_put512 _ _ _ _ (owned64_put512 _ _ _ _ (owned64_put512 _ _ _ _ ho1'))
  · exact owned64_put512 _ _ _ _ (owned64_put512 _ _ _ _ ho2'')
  · exact owned64_put512 _ _ _ _ ho3'''
  · intro x hx
    dsimp only
    rw [put512_other _ (rsp + 0xC0#64) _ x (by bv_omega), put512_other _ (rsp + 0x80#64) _ x (by bv_omega),
      put512_other _ (rsp + 0x40#64) _ x (by bv_omega), put512_other _ rsp _ x (by bv_omega)]

private theorem dec_next {n : BitVec 64} (st : State) (hpc : st.pc = 0x18620)
    (hr11 : st.w.r11 = n) (hn : n = 7#64 ∨ n = 5#64 ∨ n = 3#64) :
    ∃ st', steps Code_p16.prog 2 st = some st' ∧ st'.pc = 0x18629 ∧
      st'.w.r11 = n - 1#64 ∧
      (∀ r, st'.zmm r = st.zmm r) ∧
      st'.rax = st.rax ∧ st'.rcx = st.rcx ∧ st'.rdx = st.rdx ∧ st'.rbx = st.rbx ∧
      st'.rsp = st.rsp ∧ st'.rbp = st.rbp ∧ st'.rsi = st.rsi ∧ st'.rdi = st.rdi ∧
      st'.r8 = st.r8 ∧ st'.r9 = st.r9 ∧ st'.r12 = st.r12 ∧ st'.r13 = st.r13 ∧
      st'.r14 = st.r14 ∧ st'.r15 = st.r15 ∧ st'.w.r10 = st.w.r10 ∧ st'.mem = st.mem := by
  rcases hn with h | h | h <;> subst h <;>
  · obtain ⟨rax, rcx, rdx, rbx, rsp, rbp, rsi, rdi, r8, r9, r12, r13, r14, r15, zf, cf,
      x0, x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12, x13, x14, x15, mem, pc,
      ⟨r10, r11, u0, u1, u2, u3, u4, u5, u6, u7, u8, u9, u10, u11, u12, u13, u14, u15,
       z16, z17, z18, z19, z20, z21, z22, z23, z24, z25, z26, z27, z28, z29, z30, z31⟩⟩ := st
    simp only at hpc hr11; subst hpc hr11
    run_fn []
    exact ⟨_, rfl, rfl, rfl, fun _ => rfl, rfl, rfl, rfl, rfl, rfl, rfl, rfl, rfl, rfl, rfl, rfl, rfl, rfl, rfl, rfl, rfl⟩

private theorem dec_done (st : State) (hpc : st.pc = 0x18620) (hr11 : st.w.r11 = 1#64) :
    ∃ st', steps Code_p16.prog 2 st = some st' ∧ st'.pc = 0x18977 ∧
      (∀ r, st'.zmm r = st.zmm r) ∧
      st'.rax = st.rax ∧ st'.rcx = st.rcx ∧ st'.rdx = st.rdx ∧ st'.rbx = st.rbx ∧
      st'.rsp = st.rsp ∧ st'.rbp = st.rbp ∧ st'.rsi = st.rsi ∧ st'.rdi = st.rdi ∧
      st'.r8 = st.r8 ∧ st'.r9 = st.r9 ∧ st'.r12 = st.r12 ∧ st'.r13 = st.r13 ∧
      st'.r14 = st.r14 ∧ st'.r15 = st.r15 ∧ st'.w.r10 = st.w.r10 ∧ st'.mem = st.mem := by
  obtain ⟨rax, rcx, rdx, rbx, rsp, rbp, rsi, rdi, r8, r9, r12, r13, r14, r15, zf, cf,
    x0, x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12, x13, x14, x15, mem, pc,
    ⟨r10, r11, u0, u1, u2, u3, u4, u5, u6, u7, u8, u9, u10, u11, u12, u13, u14, u15,
     z16, z17, z18, z19, z20, z21, z22, z23, z24, z25, z26, z27, z28, z29, z30, z31⟩⟩ := st
  simp only at hpc hr11; subst hpc hr11
  run_fn []
  exact ⟨_, rfl, rfl, fun _ => rfl, rfl, rfl, rfl, rfl, rfl, rfl, rfl, rfl, rfl, rfl, rfl, rfl, rfl, rfl, rfl, rfl⟩

private theorem dec_r2 (n : BitVec 64) (st : State) (hpc : st.pc = 0x188E9)
    (hr11 : st.w.r11 = n) (hn : n = 6#64 ∨ n = 4#64 ∨ n = 2#64) :
    ∃ st', steps Code_p16.prog 1 st = some st' ∧ st'.pc = 0x188EC ∧
      st'.w.r11 = n - 1#64 ∧
      (∀ r, st'.zmm r = st.zmm r) ∧
      st'.rax = st.rax ∧ st'.rcx = st.rcx ∧ st'.rdx = st.rdx ∧ st'.rbx = st.rbx ∧
      st'.rsp = st.rsp ∧ st'.rbp = st.rbp ∧ st'.rsi = st.rsi ∧ st'.rdi = st.rdi ∧
      st'.r8 = st.r8 ∧ st'.r9 = st.r9 ∧ st'.r12 = st.r12 ∧ st'.r13 = st.r13 ∧
      st'.r14 = st.r14 ∧ st'.r15 = st.r15 ∧ st'.w.r10 = st.w.r10 ∧ st'.mem = st.mem := by
  rcases hn with h | h | h <;> subst h <;>
  · obtain ⟨rax, rcx, rdx, rbx, rsp, rbp, rsi, rdi, r8, r9, r12, r13, r14, r15, zf, cf,
      x0, x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12, x13, x14, x15, mem, pc,
      ⟨r10, r11, u0, u1, u2, u3, u4, u5, u6, u7, u8, u9, u10, u11, u12, u13, u14, u15,
       z16, z17, z18, z19, z20, z21, z22, z23, z24, z25, z26, z27, z28, z29, z30, z31⟩⟩ := st
    simp only at hpc hr11; subst hpc hr11
    run_fn []
    exact ⟨_, rfl, rfl, rfl, fun _ => rfl, rfl, rfl, rfl, rfl, rfl, rfl, rfl, rfl, rfl, rfl, rfl, rfl, rfl, rfl, rfl, rfl⟩

private theorem rows_zmm_eq {s1 s2 : State} {s0 s1' s2' s3 s4 s5 s6 s7 s8 s9 s10 s11 s12 s13 s14 s15 : Nat → BitVec 32}
    (hz : ∀ r, s2.zmm r = s1.zmm r) (hv : Rows s1 s0 s1' s2' s3 s4 s5 s6 s7 s8 s9 s10 s11 s12 s13 s14 s15) :
    Rows s2 s0 s1' s2' s3 s4 s5 s6 s7 s8 s9 s10 s11 s12 s13 s14 s15 := by
  simp only [Rows, hz] at hv ⊢; exact hv

private theorem msgs_zmm_eq {s1 s2 : State} {m0 m1 m2 m3 m4 m5 m6 m7 m8 m9 m10 m11 m12 m13 m14 m15 : Nat → BitVec 32}
    (hz : ∀ r, s2.zmm r = s1.zmm r) (hm : Msgs s1 m0 m1 m2 m3 m4 m5 m6 m7 m8 m9 m10 m11 m12 m13 m14 m15) :
    Msgs s2 m0 m1 m2 m3 m4 m5 m6 m7 m8 m9 m10 m11 m12 m13 m14 m15 := by
  simp only [Msgs, hz] at hm ⊢; exact hm

/-- **Two rounds and the message rotation** (`0x18360` back to `0x18360`, 248 instructions). -/
theorem turn2 (v m : Nat → Vector (BitVec 32) 16) (n : BitVec 64) (st : State)
    (hpc : st.pc = 0x18360) (hr11 : st.w.r11 = n) (hn : n = 7#64 ∨ n = 5#64 ∨ n = 3#64)
    (hal : aligned64 st.rsp = true)
    (ho0 : Owned64 st.mem (st.rsp + 0x0#64)) (ho1 : Owned64 st.mem (st.rsp + 0x40#64))
    (ho2 : Owned64 st.mem (st.rsp + 0x80#64)) (ho3 : Owned64 st.mem (st.rsp + 0xC0#64))
    (hv : RowsV st v) (hm : MsgsV st m) :
    ∃ st', steps Code_p16.prog 248 st = some st' ∧ st'.pc = 0x18360 ∧ st'.w.r11 = n - 2#64 ∧
      RowsV st' (fun i => rnd (rnd (v i) (m i)) (PERMUTE (m i))) ∧
      MsgsV st' (fun i => PERMUTE (PERMUTE (m i))) ∧
      st'.rax = st.rax ∧ st'.rcx = st.rcx ∧ st'.rdx = st.rdx ∧ st'.rbx = st.rbx ∧
      st'.rsp = st.rsp ∧ st'.rbp = st.rbp ∧ st'.rsi = st.rsi ∧ st'.rdi = st.rdi ∧
      st'.r8 = st.r8 ∧ st'.r9 = st.r9 ∧ st'.r12 = st.r12 ∧ st'.r13 = st.r13 ∧
      st'.r14 = st.r14 ∧ st'.r15 = st.r15 ∧ st'.w.r10 = st.w.r10 ∧
      Owned64 st'.mem (st.rsp + 0x0#64) ∧ Owned64 st'.mem (st.rsp + 0x40#64) ∧
      Owned64 st'.mem (st.rsp + 0x80#64) ∧ Owned64 st'.mem (st.rsp + 0xC0#64) ∧
      (∀ x : BitVec 64, 256#64 ≤ x - st.rsp → st'.mem x = st.mem x) := by
  obtain ⟨s1, e1, pc1, hv1, hm1, ax1, cx1, dx1, bx1, sp1, bp1, si1, di1, r8_1, r9_1, r12_1, r13_1, r14_1, r15_1, r10_1, r11_1, _, _, m1_eq, _⟩ :=
    round _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ st hpc hv hm
  have hr11_1 : s1.w.r11 = n := by rw [r11_1]; exact hr11
  obtain ⟨s2, e2, pc2, hr11_2, hz2, ax2, cx2, dx2, bx2, sp2, bp2, si2, di2, r8_2, r9_2, r12_2, r13_2, r14_2, r15_2, r10_2, m2_eq⟩ :=
    dec_next s1 pc1 hr11_1 hn
  have hv2 := rows_zmm_eq hz2 hv1
  have hm2 := msgs_zmm_eq hz2 hm1
  have hv2' : RowsV s2 (fun i => rnd (v i) (m i)) := by
    simpa only [RowsV, eta16] using hv2
  obtain ⟨s3, e3, pc3, hv3, hm3, ax3, cx3, dx3, bx3, sp3, bp3, si3, di3, r8_3, r9_3, r12_3, r13_3, r14_3, r15_3, r10_3, r11_3, _, _, m3_eq, _⟩ :=
    round2 _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ s2 pc2 hv2' hm2
  have hn2 : n - 1#64 = 6#64 ∨ n - 1#64 = 4#64 ∨ n - 1#64 = 2#64 := by rcases hn with h | h | h <;> subst h <;> simp
  have hr11_3 : s3.w.r11 = n - 1#64 := by rw [r11_3]; exact hr11_2
  obtain ⟨s4, e4, pc4, hr11_4, hz4, ax4, cx4, dx4, bx4, sp4, bp4, si4, di4, r8_4, r9_4, r12_4, r13_4, r14_4, r15_4, r10_4, m4_eq⟩ :=
    dec_r2 (n - 1#64) s3 pc3 hr11_3 hn2
  have hv4 := rows_zmm_eq hz4 hv3
  have hm4 := msgs_zmm_eq hz4 hm3
  have hsp4 : s4.rsp = st.rsp := by rw [sp4, sp3, sp2, sp1]
  have hm_eq : s4.mem = st.mem := by rw [m4_eq, m3_eq, m2_eq, m1_eq]
  have hal4 : aligned64 s4.rsp = true := by rw [hsp4]; exact hal
  have ho0_4 : Owned64 s4.mem (s4.rsp + 0x0#64) := by rw [hm_eq, hsp4]; exact ho0
  have ho1_4 : Owned64 s4.mem (s4.rsp + 0x40#64) := by rw [hm_eq, hsp4]; exact ho1
  have ho2_4 : Owned64 s4.mem (s4.rsp + 0x80#64) := by rw [hm_eq, hsp4]; exact ho2
  have ho3_4 : Owned64 s4.mem (s4.rsp + 0xC0#64) := by rw [hm_eq, hsp4]; exact ho3
  obtain ⟨s5, e5, pc5, hv5, hm5, ax5, cx5, dx5, bx5, sp5, bp5, si5, di5, r8_5, r9_5, r12_5, r13_5, r14_5, r15_5, r10_5, r11_5, _, _, po0, po1, po2, po3, pout⟩ :=
    permute2 _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ s4 pc4 hal4 ho0_4 ho1_4 ho2_4 ho3_4 hv4 hm4
  refine ⟨s5, ?_, pc5, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_⟩
  · rw [show (248 : Nat) = 112 + (2 + (112 + (1 + 21))) from rfl, steps_add, e1, Option.bind_some,
      steps_add, e2, Option.bind_some, steps_add, e3, Option.bind_some, steps_add, e4, Option.bind_some, e5]
  · rw [r11_5, hr11_4]; rcases hn with h | h | h <;> subst h <;> decide
  · simpa only [RowsV, eta16, permute_vec] using hv5
  · simpa only [MsgsV, permute2_vec, Vector.getElem_mk, List.getElem_toArray, List.getElem_cons_succ, List.getElem_cons_zero] using hm5
  all_goals first
    | (rw [ax5, ax4, ax3, ax2, ax1])
    | (rw [cx5, cx4, cx3, cx2, cx1])
    | (rw [dx5, dx4, dx3, dx2, dx1])
    | (rw [bx5, bx4, bx3, bx2, bx1])
    | (rw [sp5, hsp4])
    | (rw [bp5, bp4, bp3, bp2, bp1])
    | (rw [si5, si4, si3, si2, si1])
    | (rw [di5, di4, di3, di2, di1])
    | (rw [r8_5, r8_4, r8_3, r8_2, r8_1])
    | (rw [r9_5, r9_4, r9_3, r9_2, r9_1])
    | (rw [r12_5, r12_4, r12_3, r12_2, r12_1])
    | (rw [r13_5, r13_4, r13_3, r13_2, r13_1])
    | (rw [r14_5, r14_4, r14_3, r14_2, r14_1])
    | (rw [r15_5, r15_4, r15_3, r15_2, r15_1])
    | (rw [r10_5, r10_4, r10_3, r10_2, r10_1])
    | (rw [← hsp4]; first | exact po0 | exact po1 | exact po2 | exact po3)
    | (intro x hx; rw [pout x (by rw [hsp4]; exact hx), hm_eq])

/-- **The full seven-round loop** (`0x18360` to `0x18977`, 858 instructions): computes `rounds7` in
every lane. -/
theorem seven_rounds (v m : Nat → Vector (BitVec 32) 16) (st : State)
    (hpc : st.pc = 0x18360) (hr11 : st.w.r11 = 7#64) (hal : aligned64 st.rsp = true)
    (ho0 : Owned64 st.mem (st.rsp + 0x0#64)) (ho1 : Owned64 st.mem (st.rsp + 0x40#64))
    (ho2 : Owned64 st.mem (st.rsp + 0x80#64)) (ho3 : Owned64 st.mem (st.rsp + 0xC0#64))
    (hv : RowsV st v) (hm : MsgsV st m) :
    ∃ st', steps Code_p16.prog 858 st = some st' ∧ st'.pc = 0x18977 ∧
      RowsV st' (fun i => rounds7 (v i) (m i)) ∧
      st'.rax = st.rax ∧ st'.rcx = st.rcx ∧ st'.rdx = st.rdx ∧ st'.rbx = st.rbx ∧
      st'.rsp = st.rsp ∧ st'.rbp = st.rbp ∧ st'.rsi = st.rsi ∧ st'.rdi = st.rdi ∧
      st'.r8 = st.r8 ∧ st'.r9 = st.r9 ∧ st'.r12 = st.r12 ∧ st'.r13 = st.r13 ∧
      st'.r14 = st.r14 ∧ st'.r15 = st.r15 ∧ st'.w.r10 = st.w.r10 ∧
      (∀ x : BitVec 64, 256#64 ≤ x - st.rsp → st'.mem x = st.mem x) := by
  obtain ⟨s1, e1, pc1, hr1, hv1, hm1, ax1, cx1, dx1, bx1, sp1, bp1, si1, di1, r8_1, r9_1, r12_1, r13_1, r14_1, r15_1, r10_1, o10, o11, o12, o13, out1⟩ :=
    turn2 v m 7#64 st hpc hr11 (Or.inl rfl) hal ho0 ho1 ho2 ho3 hv hm
  have hal1 : aligned64 s1.rsp = true := by rw [sp1]; exact hal
  obtain ⟨s2, e2, pc2, hr2, hv2, hm2, ax2, cx2, dx2, bx2, sp2, bp2, si2, di2, r8_2, r9_2, r12_2, r13_2, r14_2, r15_2, r10_2, o20, o21, o22, o23, out2⟩ :=
    turn2 _ _ 5#64 s1 pc1 hr1 (Or.inr (Or.inl rfl)) hal1 (by rw [sp1]; exact o10) (by rw [sp1]; exact o11) (by rw [sp1]; exact o12) (by rw [sp1]; exact o13) hv1 hm1
  have hal2 : aligned64 s2.rsp = true := by rw [sp2, sp1]; exact hal
  obtain ⟨s3, e3, pc3, hr3, hv3, hm3, ax3, cx3, dx3, bx3, sp3, bp3, si3, di3, r8_3, r9_3, r12_3, r13_3, r14_3, r15_3, r10_3, _, _, _, _, out3⟩ :=
    turn2 _ _ 3#64 s2 pc2 hr2 (Or.inr (Or.inr rfl)) hal2 (by rw [sp2]; exact o20) (by rw [sp2]; exact o21) (by rw [sp2]; exact o22) (by rw [sp2]; exact o23) hv2 hm2
  obtain ⟨s4, e4, pc4, hv4, _, ax4, cx4, dx4, bx4, sp4, bp4, si4, di4, r8_4, r9_4, r12_4, r13_4, r14_4, r15_4, r10_4, r11_4, _, _, m4_eq, _⟩ :=
    round _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ s3 pc3 hv3 hm3
  have hr4 : s4.w.r11 = 1#64 := by rw [r11_4]; exact hr3
  obtain ⟨s5, e5, pc5, hz5, ax5, cx5, dx5, bx5, sp5, bp5, si5, di5, r8_5, r9_5, r12_5, r13_5, r14_5, r15_5, r10_5, m5_eq⟩ :=
    dec_done s4 pc4 hr4
  refine ⟨s5, ?_, pc5, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_⟩
  · rw [show (858 : Nat) = 248 + (248 + (248 + (112 + 2))) from rfl, steps_add, e1, Option.bind_some,
      steps_add, e2, Option.bind_some, steps_add, e3, Option.bind_some, steps_add, e4, Option.bind_some, e5]
  · have hv5 := rows_zmm_eq hz5 hv4
    simpa only [RowsV, eta16, rounds7] using hv5
  all_goals first
    | (rw [ax5, ax4, ax3, ax2, ax1])
    | (rw [cx5, cx4, cx3, cx2, cx1])
    | (rw [dx5, dx4, dx3, dx2, dx1])
    | (rw [bx5, bx4, bx3, bx2, bx1])
    | (rw [sp5, sp4, sp3, sp2, sp1])
    | (rw [bp5, bp4, bp3, bp2, bp1])
    | (rw [si5, si4, si3, si2, si1])
    | (rw [di5, di4, di3, di2, di1])
    | (rw [r8_5, r8_4, r8_3, r8_2, r8_1])
    | (rw [r9_5, r9_4, r9_3, r9_2, r9_1])
    | (rw [r12_5, r12_4, r12_3, r12_2, r12_1])
    | (rw [r13_5, r13_4, r13_3, r13_2, r13_1])
    | (rw [r14_5, r14_4, r14_3, r14_2, r14_1])
    | (rw [r15_5, r15_4, r15_3, r15_2, r15_1])
    | (rw [r10_5, r10_4, r10_3, r10_2, r10_1])
    | (intro x hx; rw [m5_eq, m4_eq, out3 x (by rw [sp2, sp1]; exact hx), out2 x (by rw [sp1]; exact hx), out1 x hx])

end P16
