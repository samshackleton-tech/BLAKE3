import P16Transpose
open X86 Cells Blake3Generic

/-! # Feed-forward, output transpose and stores of the wide parent kernel `p16`

Proved in small steps:
  1. `feed_forward` (`0x18977` to `0x189B7`, 12 instructions): XORs the two halves (`low8`), updates
     `r14`, and exits the block loop (`dec64 r13; jne`);
  2. `out_shuf` (`0x189B7` to `0x18A4F`, 24 instructions): transposes the eight registers by `z16_*`;
  3. `out_pair` (`0x18A4F` to `0x18ABE`, 8 × 2 instructions): eight `(vshufi32x4, vmovdqu32)` stores. -/

namespace P16

private theorem zquarter_z16_0 (w0 w1 w2 w3 w4 w5 w6 w7 w8 w9 w10 w11 w12 w13 w14 w15 : BitVec 32) :
    zquarter (z16 w0 w1 w2 w3 w4 w5 w6 w7 w8 w9 w10 w11 w12 w13 w14 w15) 0 = mk4 w0 w1 w2 w3 := by
  have h := zquarter_zpack (fun k => #[w0, w1, w2, w3, w4, w5, w6, w7, w8, w9, w10, w11, w12, w13, w14, w15][k]!) 0 (by decide)
  exact h

private theorem zquarter_z16_1 (w0 w1 w2 w3 w4 w5 w6 w7 w8 w9 w10 w11 w12 w13 w14 w15 : BitVec 32) :
    zquarter (z16 w0 w1 w2 w3 w4 w5 w6 w7 w8 w9 w10 w11 w12 w13 w14 w15) 1 = mk4 w4 w5 w6 w7 := by
  have h := zquarter_zpack (fun k => #[w0, w1, w2, w3, w4, w5, w6, w7, w8, w9, w10, w11, w12, w13, w14, w15][k]!) 1 (by decide)
  exact h

private theorem zquarter_z16_2 (w0 w1 w2 w3 w4 w5 w6 w7 w8 w9 w10 w11 w12 w13 w14 w15 : BitVec 32) :
    zquarter (z16 w0 w1 w2 w3 w4 w5 w6 w7 w8 w9 w10 w11 w12 w13 w14 w15) 2 = mk4 w8 w9 w10 w11 := by
  have h := zquarter_zpack (fun k => #[w0, w1, w2, w3, w4, w5, w6, w7, w8, w9, w10, w11, w12, w13, w14, w15][k]!) 2 (by decide)
  exact h

private theorem zquarter_z16_3 (w0 w1 w2 w3 w4 w5 w6 w7 w8 w9 w10 w11 w12 w13 w14 w15 : BitVec 32) :
    zquarter (z16 w0 w1 w2 w3 w4 w5 w6 w7 w8 w9 w10 w11 w12 w13 w14 w15) 3 = mk4 w12 w13 w14 w15 := by
  have h := zquarter_zpack (fun k => #[w0, w1, w2, w3, w4, w5, w6, w7, w8, w9, w10, w11, w12, w13, w14, w15][k]!) 3 (by decide)
  exact h

/-- Sixteen chaining values in `mem` from `out`, as `32` vectors. -/
def CvsOutAt (mem : Mem) (out : BitVec 64) (c : Nat → Vector (BitVec 32) 8) : Prop :=
  ∀ i : Nat, i < 16 →
    Vec mem (out + BitVec.ofNat 64 (32 * i)) (mk4 (c i)[0] (c i)[1] (c i)[2] (c i)[3]) ∧
    Vec mem (out + BitVec.ofNat 64 (32 * i + 16)) (mk4 (c i)[4] (c i)[5] (c i)[6] (c i)[7])

private theorem vec_put512_q0 {mem : Mem} {a : BitVec 64} {v : Z} :
    Vec (mem.put512 a v) a (zquarter v 0) := by
  simp only [Mem.put512]
  exact vec_put128_far _ _ _ _ _ (by bv_decide) (vec_put128_far _ _ _ _ _ (by bv_decide)
    (vec_put128_far _ _ _ _ _ (by bv_decide) (vec_put128 mem a (zquarter v 0))))

private theorem vec_put512_q1 {mem : Mem} {a : BitVec 64} {v : Z} :
    Vec (mem.put512 a v) (a + 16#64) (zquarter v 1) := by
  simp only [Mem.put512]
  exact vec_put128_far _ _ _ _ _ (by bv_decide) (vec_put128_far _ _ _ _ _ (by bv_decide)
    (vec_put128 _ (a + 16#64) (zquarter v 1)))

private theorem vec_put512_q2 {mem : Mem} {a : BitVec 64} {v : Z} :
    Vec (mem.put512 a v) (a + 32#64) (zquarter v 2) := by
  simp only [Mem.put512]
  exact vec_put128_far _ _ _ _ _ (by bv_decide) (vec_put128 _ (a + 32#64) (zquarter v 2))

private theorem vec_put512_q3 {mem : Mem} {a : BitVec 64} {v : Z} :
    Vec (mem.put512 a v) (a + 48#64) (zquarter v 3) := by
  simp only [Mem.put512]; exact vec_put128 _ (a + 48#64) (zquarter v 3)

private theorem vec_put512_far {mem : Mem} {a b : BitVec 64} {w : Z} {v : V}
    (h : 64#64 ≤ b - a ∧ 16#64 ≤ a - b) (hv : Vec mem b v) : Vec (mem.put512 a w) b v :=
  vec_congr (fun x hx => put512_other mem a w x (by obtain ⟨h1, h2⟩ := h; bv_omega)) hv

private theorem add_sub_add (a c d : BitVec 64) : (a + d) - (a + c) = d - c := by bv_decide

private theorem vec_put512_far_off {mem : Mem} {a c d : BitVec 64} {w : Z} {v : V}
    (h1 : 64#64 ≤ d - c) (h2 : 16#64 ≤ c - d) (hv : Vec mem (a + d) v) : Vec (mem.put512 (a + c) w) (a + d) v := by
  apply vec_put512_far
  · rw [add_sub_add, add_sub_add]; exact ⟨h1, h2⟩
  · exact hv

private theorem vec_put512_far0 {mem : Mem} {a d : BitVec 64} {w : Z} {v : V}
    (h1 : 64#64 ≤ d) (h2 : 16#64 ≤ 0#64 - d) (hv : Vec mem (a + d) v) : Vec (mem.put512 a w) (a + d) v := by
  have h := vec_put512_far_off (a := a) (c := 0#64) (d := d) (w := w) (by simpa using h1) h2 hv
  simpa using h

private theorem vec_put512_q0_at {mem : Mem} {a c d : BitVec 64} {v : Z} (h : d = c) :
    Vec (mem.put512 (a + c) v) (a + d) (zquarter v 0) := by rw [h]; exact vec_put512_q0

private theorem vec_put512_q1_at {mem : Mem} {a c d : BitVec 64} {v : Z} (h : d = c + 16#64) :
    Vec (mem.put512 (a + c) v) (a + d) (zquarter v 1) := by rw [h, ← BitVec.add_assoc]; exact vec_put512_q1

private theorem vec_put512_q2_at {mem : Mem} {a c d : BitVec 64} {v : Z} (h : d = c + 32#64) :
    Vec (mem.put512 (a + c) v) (a + d) (zquarter v 2) := by rw [h, ← BitVec.add_assoc]; exact vec_put512_q2

private theorem vec_put512_q3_at {mem : Mem} {a c d : BitVec 64} {v : Z} (h : d = c + 48#64) :
    Vec (mem.put512 (a + c) v) (a + d) (zquarter v 3) := by rw [h, ← BitVec.add_assoc]; exact vec_put512_q3

/-- The eight 4-word pairs waiting in ZMM `6, 5, 2, 3, 7, 16, 1, 0` after `out_shuf`. -/
def OutRegs (st : State) (c : Nat → Nat → BitVec 32) : Prop :=
  st.zmm 6 = z16 (c 0 0) (c 0 1) (c 0 2) (c 0 3) (c 8 0) (c 8 1) (c 8 2) (c 8 3)
                 (c 0 4) (c 0 5) (c 0 6) (c 0 7) (c 8 4) (c 8 5) (c 8 6) (c 8 7) ∧
  st.zmm 5 = z16 (c 1 0) (c 1 1) (c 1 2) (c 1 3) (c 9 0) (c 9 1) (c 9 2) (c 9 3)
                 (c 1 4) (c 1 5) (c 1 6) (c 1 7) (c 9 4) (c 9 5) (c 9 6) (c 9 7) ∧
  st.zmm 2 = z16 (c 2 0) (c 2 1) (c 2 2) (c 2 3) (c 10 0) (c 10 1) (c 10 2) (c 10 3)
                 (c 2 4) (c 2 5) (c 2 6) (c 2 7) (c 10 4) (c 10 5) (c 10 6) (c 10 7) ∧
  st.zmm 3 = z16 (c 3 0) (c 3 1) (c 3 2) (c 3 3) (c 11 0) (c 11 1) (c 11 2) (c 11 3)
                 (c 3 4) (c 3 5) (c 3 6) (c 3 7) (c 11 4) (c 11 5) (c 11 6) (c 11 7) ∧
  st.zmm 7 = z16 (c 4 0) (c 4 1) (c 4 2) (c 4 3) (c 12 0) (c 12 1) (c 12 2) (c 12 3)
                 (c 4 4) (c 4 5) (c 4 6) (c 4 7) (c 12 4) (c 12 5) (c 12 6) (c 12 7) ∧
  st.zmm 16 = z16 (c 5 0) (c 5 1) (c 5 2) (c 5 3) (c 13 0) (c 13 1) (c 13 2) (c 13 3)
                  (c 5 4) (c 5 5) (c 5 6) (c 5 7) (c 13 4) (c 13 5) (c 13 6) (c 13 7) ∧
  st.zmm 1 = z16 (c 6 0) (c 6 1) (c 6 2) (c 6 3) (c 14 0) (c 14 1) (c 14 2) (c 14 3)
                 (c 6 4) (c 6 5) (c 6 6) (c 6 7) (c 14 4) (c 14 5) (c 14 6) (c 14 7) ∧
  st.zmm 0 = z16 (c 7 0) (c 7 1) (c 7 2) (c 7 3) (c 15 0) (c 15 1) (c 15 2) (c 15 3)
                 (c 7 4) (c 7 5) (c 7 6) (c 7 7) (c 15 4) (c 15 5) (c 15 6) (c 15 7)

set_option maxRecDepth 1000000 in
set_option maxHeartbeats 0 in
/-- **Feed-forward and block-loop exit** (`0x18977` to `0x189B7`, 12 instructions). -/
private theorem feed_forward (v : Nat → Vector (BitVec 32) 16) (st : State)
    (hpc : st.pc = 0x18977) (hr13 : st.r13 = 1#64) (hv : RowsV st v) :
    let c (i k : Nat) := (low8 (v i))[k]!
    ∃ st', steps Code_p16.prog 12 st = some st' ∧ st'.pc = 0x189B7 ∧
      st'.zmm 0 = z16 (c 0 0) (c 1 0) (c 2 0) (c 3 0) (c 4 0) (c 5 0) (c 6 0) (c 7 0) (c 8 0) (c 9 0) (c 10 0) (c 11 0) (c 12 0) (c 13 0) (c 14 0) (c 15 0) ∧
      st'.zmm 1 = z16 (c 0 1) (c 1 1) (c 2 1) (c 3 1) (c 4 1) (c 5 1) (c 6 1) (c 7 1) (c 8 1) (c 9 1) (c 10 1) (c 11 1) (c 12 1) (c 13 1) (c 14 1) (c 15 1) ∧
      st'.zmm 2 = z16 (c 0 2) (c 1 2) (c 2 2) (c 3 2) (c 4 2) (c 5 2) (c 6 2) (c 7 2) (c 8 2) (c 9 2) (c 10 2) (c 11 2) (c 12 2) (c 13 2) (c 14 2) (c 15 2) ∧
      st'.zmm 3 = z16 (c 0 3) (c 1 3) (c 2 3) (c 3 3) (c 4 3) (c 5 3) (c 6 3) (c 7 3) (c 8 3) (c 9 3) (c 10 3) (c 11 3) (c 12 3) (c 13 3) (c 14 3) (c 15 3) ∧
      st'.zmm 4 = z16 (c 0 4) (c 1 4) (c 2 4) (c 3 4) (c 4 4) (c 5 4) (c 6 4) (c 7 4) (c 8 4) (c 9 4) (c 10 4) (c 11 4) (c 12 4) (c 13 4) (c 14 4) (c 15 4) ∧
      st'.zmm 5 = z16 (c 0 5) (c 1 5) (c 2 5) (c 3 5) (c 4 5) (c 5 5) (c 6 5) (c 7 5) (c 8 5) (c 9 5) (c 10 5) (c 11 5) (c 12 5) (c 13 5) (c 14 5) (c 15 5) ∧
      st'.zmm 6 = z16 (c 0 6) (c 1 6) (c 2 6) (c 3 6) (c 4 6) (c 5 6) (c 6 6) (c 7 6) (c 8 6) (c 9 6) (c 10 6) (c 11 6) (c 12 6) (c 13 6) (c 14 6) (c 15 6) ∧
      st'.zmm 7 = z16 (c 0 7) (c 1 7) (c 2 7) (c 3 7) (c 4 7) (c 5 7) (c 6 7) (c 7 7) (c 8 7) (c 9 7) (c 10 7) (c 11 7) (c 12 7) (c 13 7) (c 14 7) (c 15 7) ∧
      st'.rbx = st.rbx ∧ st'.rbp = st.rbp ∧ st'.r12 = st.r12 ∧ st'.r14 = st.r14 + 0x40#64 ∧
      st'.r15 = st.r15 ∧ st'.rsp = st.rsp ∧ st'.mem = st.mem := by
  intro c
  obtain ⟨rax, rcx, rdx, rbx, rsp, rbp, rsi, rdi, r8, r9, r12, r13, r14, r15, zf, cf,
    x0, x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12, x13, x14, x15, mem, pc,
    ⟨r10, r11, u0, u1, u2, u3, u4, u5, u6, u7, u8, u9, u10, u11, u12, u13, u14, u15,
     wz16, z17, z18, z19, z20, z21, z22, z23, z24, z25, z26, z27, z28, z29, z30, z31, _, _⟩⟩ := st
  obtain ⟨hv0, hv1, hv2, hv3, hv4, hv5, hv6, hv7, hv8, hv9, hv10, hv11, hv12, hv13, hv14, hv15⟩ := hv
  simp only [State.zmm] at hpc hr13 hv0 hv1 hv2 hv3 hv4 hv5 hv6 hv7 hv8 hv9 hv10 hv11 hv12 hv13 hv14 hv15
  subst hpc hr13
  have e0 : x0 = zlo (zpack fun i => (v i)[0]) := by rw [← hv0, zlo_zjoin]
  have f0 : u0 = zhi (zpack fun i => (v i)[0]) := by rw [← hv0, zhi_zjoin]
  subst e0 f0
  have e1 : x1 = zlo (zpack fun i => (v i)[1]) := by rw [← hv1, zlo_zjoin]
  have f1 : u1 = zhi (zpack fun i => (v i)[1]) := by rw [← hv1, zhi_zjoin]
  subst e1 f1
  have e2 : x2 = zlo (zpack fun i => (v i)[2]) := by rw [← hv2, zlo_zjoin]
  have f2 : u2 = zhi (zpack fun i => (v i)[2]) := by rw [← hv2, zhi_zjoin]
  subst e2 f2
  have e3 : x3 = zlo (zpack fun i => (v i)[3]) := by rw [← hv3, zlo_zjoin]
  have f3 : u3 = zhi (zpack fun i => (v i)[3]) := by rw [← hv3, zhi_zjoin]
  subst e3 f3
  have e4 : x4 = zlo (zpack fun i => (v i)[4]) := by rw [← hv4, zlo_zjoin]
  have f4 : u4 = zhi (zpack fun i => (v i)[4]) := by rw [← hv4, zhi_zjoin]
  subst e4 f4
  have e5 : x5 = zlo (zpack fun i => (v i)[5]) := by rw [← hv5, zlo_zjoin]
  have f5 : u5 = zhi (zpack fun i => (v i)[5]) := by rw [← hv5, zhi_zjoin]
  subst e5 f5
  have e6 : x6 = zlo (zpack fun i => (v i)[6]) := by rw [← hv6, zlo_zjoin]
  have f6 : u6 = zhi (zpack fun i => (v i)[6]) := by rw [← hv6, zhi_zjoin]
  subst e6 f6
  have e7 : x7 = zlo (zpack fun i => (v i)[7]) := by rw [← hv7, zlo_zjoin]
  have f7 : u7 = zhi (zpack fun i => (v i)[7]) := by rw [← hv7, zhi_zjoin]
  subst e7 f7
  have e9 : x9 = zlo (zpack fun i => (v i)[8]) := by rw [← hv8, zlo_zjoin]
  have f9 : u9 = zhi (zpack fun i => (v i)[8]) := by rw [← hv8, zhi_zjoin]
  subst e9 f9
  have e10 : x10 = zlo (zpack fun i => (v i)[9]) := by rw [← hv9, zlo_zjoin]
  have f10 : u10 = zhi (zpack fun i => (v i)[9]) := by rw [← hv9, zhi_zjoin]
  subst e10 f10
  have e11 : x11 = zlo (zpack fun i => (v i)[10]) := by rw [← hv10, zlo_zjoin]
  have f11 : u11 = zhi (zpack fun i => (v i)[10]) := by rw [← hv10, zhi_zjoin]
  subst e11 f11
  have e12 : x12 = zlo (zpack fun i => (v i)[11]) := by rw [← hv11, zlo_zjoin]
  have f12 : u12 = zhi (zpack fun i => (v i)[11]) := by rw [← hv11, zhi_zjoin]
  subst e12 f12
  have e13 : x13 = zlo (zpack fun i => (v i)[12]) := by rw [← hv12, zlo_zjoin]
  have f13 : u13 = zhi (zpack fun i => (v i)[12]) := by rw [← hv12, zhi_zjoin]
  subst e13 f13
  have e14 : x14 = zlo (zpack fun i => (v i)[13]) := by rw [← hv13, zlo_zjoin]
  have f14 : u14 = zhi (zpack fun i => (v i)[13]) := by rw [← hv13, zhi_zjoin]
  subst e14 f14
  have e15 : x15 = zlo (zpack fun i => (v i)[14]) := by rw [← hv14, zlo_zjoin]
  have f15 : u15 = zhi (zpack fun i => (v i)[14]) := by rw [← hv14, zhi_zjoin]
  subst e15 f15
  subst hv15
  run_fn [zjoin_split, zlo_zjoin, zhi_zjoin, zxor_pack]
  refine ⟨_, rfl, rfl, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, rfl, rfl, rfl, rfl, rfl, rfl, rfl⟩
  all_goals
    (simp only [State.zmm, zjoin_split, z16_eq_zpack, c, low8_0, low8_1, low8_2, low8_3, low8_4, low8_5, low8_6, low8_7]; rfl)

set_option maxRecDepth 1000000 in
set_option maxHeartbeats 0 in
/-- **Output transpose in registers** (`0x189B7` to `0x18A4F`, 24 instructions). -/
private theorem out_shuf (c : Nat → Nat → BitVec 32) (st : State) (hpc : st.pc = 0x189B7)
    (hz0 : st.zmm 0 = z16 (c 0 0) (c 1 0) (c 2 0) (c 3 0) (c 4 0) (c 5 0) (c 6 0) (c 7 0) (c 8 0) (c 9 0) (c 10 0) (c 11 0) (c 12 0) (c 13 0) (c 14 0) (c 15 0))
    (hz1 : st.zmm 1 = z16 (c 0 1) (c 1 1) (c 2 1) (c 3 1) (c 4 1) (c 5 1) (c 6 1) (c 7 1) (c 8 1) (c 9 1) (c 10 1) (c 11 1) (c 12 1) (c 13 1) (c 14 1) (c 15 1))
    (hz2 : st.zmm 2 = z16 (c 0 2) (c 1 2) (c 2 2) (c 3 2) (c 4 2) (c 5 2) (c 6 2) (c 7 2) (c 8 2) (c 9 2) (c 10 2) (c 11 2) (c 12 2) (c 13 2) (c 14 2) (c 15 2))
    (hz3 : st.zmm 3 = z16 (c 0 3) (c 1 3) (c 2 3) (c 3 3) (c 4 3) (c 5 3) (c 6 3) (c 7 3) (c 8 3) (c 9 3) (c 10 3) (c 11 3) (c 12 3) (c 13 3) (c 14 3) (c 15 3))
    (hz4 : st.zmm 4 = z16 (c 0 4) (c 1 4) (c 2 4) (c 3 4) (c 4 4) (c 5 4) (c 6 4) (c 7 4) (c 8 4) (c 9 4) (c 10 4) (c 11 4) (c 12 4) (c 13 4) (c 14 4) (c 15 4))
    (hz5 : st.zmm 5 = z16 (c 0 5) (c 1 5) (c 2 5) (c 3 5) (c 4 5) (c 5 5) (c 6 5) (c 7 5) (c 8 5) (c 9 5) (c 10 5) (c 11 5) (c 12 5) (c 13 5) (c 14 5) (c 15 5))
    (hz6 : st.zmm 6 = z16 (c 0 6) (c 1 6) (c 2 6) (c 3 6) (c 4 6) (c 5 6) (c 6 6) (c 7 6) (c 8 6) (c 9 6) (c 10 6) (c 11 6) (c 12 6) (c 13 6) (c 14 6) (c 15 6))
    (hz7 : st.zmm 7 = z16 (c 0 7) (c 1 7) (c 2 7) (c 3 7) (c 4 7) (c 5 7) (c 6 7) (c 7 7) (c 8 7) (c 9 7) (c 10 7) (c 11 7) (c 12 7) (c 13 7) (c 14 7) (c 15 7)) :
    ∃ st', steps Code_p16.prog 24 st = some st' ∧ st'.pc = 0x18A4F ∧ OutRegs st' c ∧
      st'.rbx = st.rbx ∧ st'.rbp = st.rbp ∧ st'.r12 = st.r12 ∧ st'.r14 = st.r14 ∧
      st'.r15 = st.r15 ∧ st'.rsp = st.rsp ∧ st'.mem = st.mem := by
  obtain ⟨rax, rcx, rdx, rbx, rsp, rbp, rsi, rdi, r8, r9, r12, r13, r14, r15, zf, cf,
    x0, x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12, x13, x14, x15, mem, pc,
    ⟨r10, r11, u0, u1, u2, u3, u4, u5, u6, u7, u8, u9, u10, u11, u12, u13, u14, u15,
     wz16, z17, z18, z19, z20, z21, z22, z23, z24, z25, z26, z27, z28, z29, z30, z31, _, _⟩⟩ := st
  simp only [State.zmm] at hpc hz0 hz1 hz2 hz3 hz4 hz5 hz6 hz7
  subst hpc
  have e0 : x0 = zlo (z16 (c 0 0) (c 1 0) (c 2 0) (c 3 0) (c 4 0) (c 5 0) (c 6 0) (c 7 0) (c 8 0) (c 9 0) (c 10 0) (c 11 0) (c 12 0) (c 13 0) (c 14 0) (c 15 0)) := by rw [← hz0, zlo_zjoin]
  have f0 : u0 = zhi (z16 (c 0 0) (c 1 0) (c 2 0) (c 3 0) (c 4 0) (c 5 0) (c 6 0) (c 7 0) (c 8 0) (c 9 0) (c 10 0) (c 11 0) (c 12 0) (c 13 0) (c 14 0) (c 15 0)) := by rw [← hz0, zhi_zjoin]
  subst e0 f0
  have e1 : x1 = zlo (z16 (c 0 1) (c 1 1) (c 2 1) (c 3 1) (c 4 1) (c 5 1) (c 6 1) (c 7 1) (c 8 1) (c 9 1) (c 10 1) (c 11 1) (c 12 1) (c 13 1) (c 14 1) (c 15 1)) := by rw [← hz1, zlo_zjoin]
  have f1 : u1 = zhi (z16 (c 0 1) (c 1 1) (c 2 1) (c 3 1) (c 4 1) (c 5 1) (c 6 1) (c 7 1) (c 8 1) (c 9 1) (c 10 1) (c 11 1) (c 12 1) (c 13 1) (c 14 1) (c 15 1)) := by rw [← hz1, zhi_zjoin]
  subst e1 f1
  have e2 : x2 = zlo (z16 (c 0 2) (c 1 2) (c 2 2) (c 3 2) (c 4 2) (c 5 2) (c 6 2) (c 7 2) (c 8 2) (c 9 2) (c 10 2) (c 11 2) (c 12 2) (c 13 2) (c 14 2) (c 15 2)) := by rw [← hz2, zlo_zjoin]
  have f2 : u2 = zhi (z16 (c 0 2) (c 1 2) (c 2 2) (c 3 2) (c 4 2) (c 5 2) (c 6 2) (c 7 2) (c 8 2) (c 9 2) (c 10 2) (c 11 2) (c 12 2) (c 13 2) (c 14 2) (c 15 2)) := by rw [← hz2, zhi_zjoin]
  subst e2 f2
  have e3 : x3 = zlo (z16 (c 0 3) (c 1 3) (c 2 3) (c 3 3) (c 4 3) (c 5 3) (c 6 3) (c 7 3) (c 8 3) (c 9 3) (c 10 3) (c 11 3) (c 12 3) (c 13 3) (c 14 3) (c 15 3)) := by rw [← hz3, zlo_zjoin]
  have f3 : u3 = zhi (z16 (c 0 3) (c 1 3) (c 2 3) (c 3 3) (c 4 3) (c 5 3) (c 6 3) (c 7 3) (c 8 3) (c 9 3) (c 10 3) (c 11 3) (c 12 3) (c 13 3) (c 14 3) (c 15 3)) := by rw [← hz3, zhi_zjoin]
  subst e3 f3
  have e4 : x4 = zlo (z16 (c 0 4) (c 1 4) (c 2 4) (c 3 4) (c 4 4) (c 5 4) (c 6 4) (c 7 4) (c 8 4) (c 9 4) (c 10 4) (c 11 4) (c 12 4) (c 13 4) (c 14 4) (c 15 4)) := by rw [← hz4, zlo_zjoin]
  have f4 : u4 = zhi (z16 (c 0 4) (c 1 4) (c 2 4) (c 3 4) (c 4 4) (c 5 4) (c 6 4) (c 7 4) (c 8 4) (c 9 4) (c 10 4) (c 11 4) (c 12 4) (c 13 4) (c 14 4) (c 15 4)) := by rw [← hz4, zhi_zjoin]
  subst e4 f4
  have e5 : x5 = zlo (z16 (c 0 5) (c 1 5) (c 2 5) (c 3 5) (c 4 5) (c 5 5) (c 6 5) (c 7 5) (c 8 5) (c 9 5) (c 10 5) (c 11 5) (c 12 5) (c 13 5) (c 14 5) (c 15 5)) := by rw [← hz5, zlo_zjoin]
  have f5 : u5 = zhi (z16 (c 0 5) (c 1 5) (c 2 5) (c 3 5) (c 4 5) (c 5 5) (c 6 5) (c 7 5) (c 8 5) (c 9 5) (c 10 5) (c 11 5) (c 12 5) (c 13 5) (c 14 5) (c 15 5)) := by rw [← hz5, zhi_zjoin]
  subst e5 f5
  have e6 : x6 = zlo (z16 (c 0 6) (c 1 6) (c 2 6) (c 3 6) (c 4 6) (c 5 6) (c 6 6) (c 7 6) (c 8 6) (c 9 6) (c 10 6) (c 11 6) (c 12 6) (c 13 6) (c 14 6) (c 15 6)) := by rw [← hz6, zlo_zjoin]
  have f6 : u6 = zhi (z16 (c 0 6) (c 1 6) (c 2 6) (c 3 6) (c 4 6) (c 5 6) (c 6 6) (c 7 6) (c 8 6) (c 9 6) (c 10 6) (c 11 6) (c 12 6) (c 13 6) (c 14 6) (c 15 6)) := by rw [← hz6, zhi_zjoin]
  subst e6 f6
  have e7 : x7 = zlo (z16 (c 0 7) (c 1 7) (c 2 7) (c 3 7) (c 4 7) (c 5 7) (c 6 7) (c 7 7) (c 8 7) (c 9 7) (c 10 7) (c 11 7) (c 12 7) (c 13 7) (c 14 7) (c 15 7)) := by rw [← hz7, zlo_zjoin]
  have f7 : u7 = zhi (z16 (c 0 7) (c 1 7) (c 2 7) (c 3 7) (c 4 7) (c 5 7) (c 6 7) (c 7 7) (c 8 7) (c 9 7) (c 10 7) (c 11 7) (c 12 7) (c 13 7) (c 14 7) (c 15 7)) := by rw [← hz7, zhi_zjoin]
  subst e7 f7
  run_fn [zjoin_split, zlo_zjoin, zhi_zjoin, z16_ldq, z16_hdq, z16_lqdq, z16_hqdq, z16_shuf_88, z16_shuf_dd]
  refine ⟨_, rfl, rfl, ?_, rfl, rfl, rfl, rfl, rfl, rfl, rfl⟩
  simp only [OutRegs, State.zmm, zjoin_split, and_self]

/-- One 2-instruction store pair (`vshufi32x4 4, a, b, imm` then `vmovdqu32 [r15 + disp], zmm4`),
writing 64 bytes at `st.r15 + disp`. -/
private theorem out_pair (st : State) (pc0 pc1 pc2 : Nat) (ra rb : Nat) (imm : Nat) (disp : BitVec 64)
    (a0 a1 a2 a3 a4 a5 a6 a7 a8 a9 a10 a11 a12 a13 a14 a15
     b0 b1 b2 b3 b4 b5 b6 b7 b8 b9 b10 b11 b12 b13 b14 b15 : BitVec 32)
    (hpc : st.pc = pc0)
    (hi1 : Code_p16.prog pc0 = some (.zshufi32x4 4 ra rb imm, pc1))
    (hi2 : Code_p16.prog pc1 = some (.zstore false .r15 disp 4, pc2))
    (himm : imm = 136 ∨ imm = 221)
    (ho : Owned64 st.mem (st.r15 + disp))
    (ha : st.zmm ra = z16 a0 a1 a2 a3 a4 a5 a6 a7 a8 a9 a10 a11 a12 a13 a14 a15)
    (hb : st.zmm rb = z16 b0 b1 b2 b3 b4 b5 b6 b7 b8 b9 b10 b11 b12 b13 b14 b15) :
    let v := if imm = 136 then z16 a0 a1 a2 a3 a8 a9 a10 a11 b0 b1 b2 b3 b8 b9 b10 b11
             else z16 a4 a5 a6 a7 a12 a13 a14 a15 b4 b5 b6 b7 b12 b13 b14 b15
    ∃ st', steps Code_p16.prog 2 st = some st' ∧ st'.pc = pc2 ∧
      st'.mem = st.mem.put512 (st.r15 + disp) v ∧
      (∀ r, r ≠ 4 → st'.zmm r = st.zmm r) ∧
      st'.rbx = st.rbx ∧ st'.rbp = st.rbp ∧ st'.r12 = st.r12 ∧ st'.r14 = st.r14 ∧
      st'.r15 = st.r15 ∧ st'.rsp = st.rsp := by
  intro v
  have hw := write512_of ho v
  have heq : zshufi32x4 (z16 a0 a1 a2 a3 a4 a5 a6 a7 a8 a9 a10 a11 a12 a13 a14 a15)
      (z16 b0 b1 b2 b3 b4 b5 b6 b7 b8 b9 b10 b11 b12 b13 b14 b15) imm = v := by
    rcases himm with h | h <;> subst h
    · exact z16_shuf_88 _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
    · exact z16_shuf_dd _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
  have ha' : ({ st with pc := pc1 }).zmm ra = z16 a0 a1 a2 a3 a4 a5 a6 a7 a8 a9 a10 a11 a12 a13 a14 a15 := ha
  have hb' : ({ st with pc := pc1 }).zmm rb = z16 b0 b1 b2 b3 b4 b5 b6 b7 b8 b9 b10 b11 b12 b13 b14 b15 := hb
  have s_step1 : steps Code_p16.prog 1 st = some ({ st with pc := pc1 }.setz 4 v) := by
    rw [steps, hpc, hi1]; simp only [step, ha', hb', heq, Option.bind_eq_bind, Option.bind_some, steps_zero]
  let st1 := { st with pc := pc1 }.setz 4 v
  have hpc1 : st1.pc = pc1 := by simp only [st1, State.setz]
  have hz4 : ({ st1 with pc := pc2 }).zmm 4 = v := by simp only [st1, State.setz, State.zmm, zjoin_split]
  have hr15 : ({ st1 with pc := pc2 }).r15 = st.r15 := by simp only [st1, State.setz]
  have hmem1 : ({ st1 with pc := pc2 }).mem = st.mem := by simp only [st1, State.setz]
  have s_step2 : steps Code_p16.prog 1 st1 = some { st1 with pc := pc2, mem := st.mem.put512 (st.r15 + disp) v } := by
    rw [steps, hpc1, hi2]
    dsimp only [step]
    have hr15' : ({ st1 with pc := pc2 }).get Reg.r15 = st.r15 := hr15
    have hw' : ({ st1 with pc := pc2 }).mem.write512 (st.r15 + disp) v = some (st.mem.put512 (st.r15 + disp) v) := hw
    simp only [Bool.false_and, Bool.false_eq_true, ↓reduceIte, hr15', hz4, hw',
      Option.map_some, Option.bind_eq_bind, Option.bind_some, steps_zero]
  have s_both : steps Code_p16.prog 2 st = some { st1 with pc := pc2, mem := st.mem.put512 (st.r15 + disp) v } := by
    rw [show (2 : Nat) = 1 + 1 from rfl, steps_add, s_step1, Option.bind_some, s_step2]
  refine ⟨_, s_both, rfl, rfl, ?_, rfl, rfl, rfl, rfl, rfl, rfl⟩
  intro r hr
  simp only [st1, State.setz, State.zmm]
  rcases r with _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | r
  all_goals first | (exfalso; exact hr rfl) | rfl

private theorem out_pair_88 (st : State) (pc0 pc1 pc2 : Nat) (ra rb : Nat) (disp : BitVec 64)
    (a0 a1 a2 a3 a4 a5 a6 a7 a8 a9 a10 a11 a12 a13 a14 a15
     b0 b1 b2 b3 b4 b5 b6 b7 b8 b9 b10 b11 b12 b13 b14 b15 : BitVec 32)
    (hpc : st.pc = pc0)
    (hi1 : Code_p16.prog pc0 = some (.zshufi32x4 4 ra rb 136, pc1))
    (hi2 : Code_p16.prog pc1 = some (.zstore false .r15 disp 4, pc2))
    (ho : Owned64 st.mem (st.r15 + disp))
    (ha : st.zmm ra = z16 a0 a1 a2 a3 a4 a5 a6 a7 a8 a9 a10 a11 a12 a13 a14 a15)
    (hb : st.zmm rb = z16 b0 b1 b2 b3 b4 b5 b6 b7 b8 b9 b10 b11 b12 b13 b14 b15) :
    ∃ st', steps Code_p16.prog 2 st = some st' ∧ st'.pc = pc2 ∧
      st'.mem = st.mem.put512 (st.r15 + disp) (z16 a0 a1 a2 a3 a8 a9 a10 a11 b0 b1 b2 b3 b8 b9 b10 b11) ∧
      (∀ r, r ≠ 4 → st'.zmm r = st.zmm r) ∧
      st'.rbx = st.rbx ∧ st'.rbp = st.rbp ∧ st'.r12 = st.r12 ∧ st'.r14 = st.r14 ∧
      st'.r15 = st.r15 ∧ st'.rsp = st.rsp := by
  simpa only [↓reduceIte] using out_pair st pc0 pc1 pc2 ra rb 136 disp
    a0 a1 a2 a3 a4 a5 a6 a7 a8 a9 a10 a11 a12 a13 a14 a15
    b0 b1 b2 b3 b4 b5 b6 b7 b8 b9 b10 b11 b12 b13 b14 b15 hpc hi1 hi2 (Or.inl rfl) ho ha hb

private theorem out_pair_dd (st : State) (pc0 pc1 pc2 : Nat) (ra rb : Nat) (disp : BitVec 64)
    (a0 a1 a2 a3 a4 a5 a6 a7 a8 a9 a10 a11 a12 a13 a14 a15
     b0 b1 b2 b3 b4 b5 b6 b7 b8 b9 b10 b11 b12 b13 b14 b15 : BitVec 32)
    (hpc : st.pc = pc0)
    (hi1 : Code_p16.prog pc0 = some (.zshufi32x4 4 ra rb 221, pc1))
    (hi2 : Code_p16.prog pc1 = some (.zstore false .r15 disp 4, pc2))
    (ho : Owned64 st.mem (st.r15 + disp))
    (ha : st.zmm ra = z16 a0 a1 a2 a3 a4 a5 a6 a7 a8 a9 a10 a11 a12 a13 a14 a15)
    (hb : st.zmm rb = z16 b0 b1 b2 b3 b4 b5 b6 b7 b8 b9 b10 b11 b12 b13 b14 b15) :
    ∃ st', steps Code_p16.prog 2 st = some st' ∧ st'.pc = pc2 ∧
      st'.mem = st.mem.put512 (st.r15 + disp) (z16 a4 a5 a6 a7 a12 a13 a14 a15 b4 b5 b6 b7 b12 b13 b14 b15) ∧
      (∀ r, r ≠ 4 → st'.zmm r = st.zmm r) ∧
      st'.rbx = st.rbx ∧ st'.rbp = st.rbp ∧ st'.r12 = st.r12 ∧ st'.r14 = st.r14 ∧
      st'.r15 = st.r15 ∧ st'.rsp = st.rsp := by
  have hne : ((221 : Nat) = 136) = False := by decide
  simpa only [hne, ↓reduceIte] using out_pair st pc0 pc1 pc2 ra rb 221 disp
    a0 a1 a2 a3 a4 a5 a6 a7 a8 a9 a10 a11 a12 a13 a14 a15
    b0 b1 b2 b3 b4 b5 b6 b7 b8 b9 b10 b11 b12 b13 b14 b15 hpc hi1 hi2 (Or.inr rfl) ho ha hb

private theorem vec_put512_z16_0 {mem : Mem} {a c d : BitVec 64}
    {w0 w1 w2 w3 w4 w5 w6 w7 w8 w9 w10 w11 w12 w13 w14 w15 : BitVec 32} (h : d = c) :
    Vec (mem.put512 (a + c) (z16 w0 w1 w2 w3 w4 w5 w6 w7 w8 w9 w10 w11 w12 w13 w14 w15)) (a + d) (mk4 w0 w1 w2 w3) := by
  rw [← zquarter_z16_0 w0 w1 w2 w3 w4 w5 w6 w7 w8 w9 w10 w11 w12 w13 w14 w15]
  exact vec_put512_q0_at h

private theorem vec_put512_z16_1 {mem : Mem} {a c d : BitVec 64}
    {w0 w1 w2 w3 w4 w5 w6 w7 w8 w9 w10 w11 w12 w13 w14 w15 : BitVec 32} (h : d = c + 16#64) :
    Vec (mem.put512 (a + c) (z16 w0 w1 w2 w3 w4 w5 w6 w7 w8 w9 w10 w11 w12 w13 w14 w15)) (a + d) (mk4 w4 w5 w6 w7) := by
  rw [← zquarter_z16_1 w0 w1 w2 w3 w4 w5 w6 w7 w8 w9 w10 w11 w12 w13 w14 w15]
  exact vec_put512_q1_at h

private theorem vec_put512_z16_2 {mem : Mem} {a c d : BitVec 64}
    {w0 w1 w2 w3 w4 w5 w6 w7 w8 w9 w10 w11 w12 w13 w14 w15 : BitVec 32} (h : d = c + 32#64) :
    Vec (mem.put512 (a + c) (z16 w0 w1 w2 w3 w4 w5 w6 w7 w8 w9 w10 w11 w12 w13 w14 w15)) (a + d) (mk4 w8 w9 w10 w11) := by
  rw [← zquarter_z16_2 w0 w1 w2 w3 w4 w5 w6 w7 w8 w9 w10 w11 w12 w13 w14 w15]
  exact vec_put512_q2_at h

private theorem vec_put512_z16_3 {mem : Mem} {a c d : BitVec 64}
    {w0 w1 w2 w3 w4 w5 w6 w7 w8 w9 w10 w11 w12 w13 w14 w15 : BitVec 32} (h : d = c + 48#64) :
    Vec (mem.put512 (a + c) (z16 w0 w1 w2 w3 w4 w5 w6 w7 w8 w9 w10 w11 w12 w13 w14 w15)) (a + d) (mk4 w12 w13 w14 w15) := by
  rw [← zquarter_z16_3 w0 w1 w2 w3 w4 w5 w6 w7 w8 w9 w10 w11 w12 w13 w14 w15]
  exact vec_put512_q3_at h

set_option maxRecDepth 1000000 in
private theorem cvsOutAt_of_8_stores (mem : Mem) (r15 : BitVec 64) (c : Nat → Nat → BitVec 32)
    (v0 v1 v2 v3 v4 v5 v6 v7 : Z)
    (hv0 : v0 = z16 (c 0 0) (c 0 1) (c 0 2) (c 0 3) (c 0 4) (c 0 5) (c 0 6) (c 0 7) (c 1 0) (c 1 1) (c 1 2) (c 1 3) (c 1 4) (c 1 5) (c 1 6) (c 1 7))
    (hv1 : v1 = z16 (c 2 0) (c 2 1) (c 2 2) (c 2 3) (c 2 4) (c 2 5) (c 2 6) (c 2 7) (c 3 0) (c 3 1) (c 3 2) (c 3 3) (c 3 4) (c 3 5) (c 3 6) (c 3 7))
    (hv2 : v2 = z16 (c 4 0) (c 4 1) (c 4 2) (c 4 3) (c 4 4) (c 4 5) (c 4 6) (c 4 7) (c 5 0) (c 5 1) (c 5 2) (c 5 3) (c 5 4) (c 5 5) (c 5 6) (c 5 7))
    (hv3 : v3 = z16 (c 6 0) (c 6 1) (c 6 2) (c 6 3) (c 6 4) (c 6 5) (c 6 6) (c 6 7) (c 7 0) (c 7 1) (c 7 2) (c 7 3) (c 7 4) (c 7 5) (c 7 6) (c 7 7))
    (hv4 : v4 = z16 (c 8 0) (c 8 1) (c 8 2) (c 8 3) (c 8 4) (c 8 5) (c 8 6) (c 8 7) (c 9 0) (c 9 1) (c 9 2) (c 9 3) (c 9 4) (c 9 5) (c 9 6) (c 9 7))
    (hv5 : v5 = z16 (c 10 0) (c 10 1) (c 10 2) (c 10 3) (c 10 4) (c 10 5) (c 10 6) (c 10 7) (c 11 0) (c 11 1) (c 11 2) (c 11 3) (c 11 4) (c 11 5) (c 11 6) (c 11 7))
    (hv6 : v6 = z16 (c 12 0) (c 12 1) (c 12 2) (c 12 3) (c 12 4) (c 12 5) (c 12 6) (c 12 7) (c 13 0) (c 13 1) (c 13 2) (c 13 3) (c 13 4) (c 13 5) (c 13 6) (c 13 7))
    (hv7 : v7 = z16 (c 14 0) (c 14 1) (c 14 2) (c 14 3) (c 14 4) (c 14 5) (c 14 6) (c 14 7) (c 15 0) (c 15 1) (c 15 2) (c 15 3) (c 15 4) (c 15 5) (c 15 6) (c 15 7)) :
    let m := (((((((mem.put512 (r15 + 0#64) v0).put512 (r15 + 64#64) v1).put512 (r15 + 128#64) v2).put512 (r15 + 192#64) v3).put512 (r15 + 256#64) v4).put512 (r15 + 320#64) v5).put512 (r15 + 384#64) v6).put512 (r15 + 448#64) v7
    ∀ i : Nat, i < 16 →
      Vec m (r15 + BitVec.ofNat 64 (32 * i)) (mk4 (c i 0) (c i 1) (c i 2) (c i 3)) ∧
      Vec m (r15 + BitVec.ofNat 64 (32 * i + 16)) (mk4 (c i 4) (c i 5) (c i 6) (c i 7)) := by
  intro m i hi
  have step_far : ∀ {memk : Mem} {c0 : BitVec 64} {vk : Z} {d : BitVec 64} {v : V},
      64#64 ≤ d - c0 → 16#64 ≤ c0 - d → Vec memk (r15 + d) v → Vec (memk.put512 (r15 + c0) vk) (r15 + d) v :=
    fun h1 h2 hv => vec_put512_far_off h1 h2 hv
  have pair0 : ∀ (memk : Mem) (d0 d1 : BitVec 64) (h0 : d0 = 0#64) (h1 : d1 = 16#64),
      Vec (memk.put512 (r15 + 0#64) v0) (r15 + d0) (mk4 (c 0 0) (c 0 1) (c 0 2) (c 0 3)) ∧
      Vec (memk.put512 (r15 + 0#64) v0) (r15 + d1) (mk4 (c 0 4) (c 0 5) (c 0 6) (c 0 7)) := by
    intro memk d0 d1 h0 h1; rw [hv0]; exact ⟨vec_put512_z16_0 h0, vec_put512_z16_1 h1⟩
  have pair1 : ∀ (memk : Mem) (d0 d1 : BitVec 64) (h0 : d0 = 32#64) (h1 : d1 = 48#64),
      Vec (memk.put512 (r15 + 0#64) v0) (r15 + d0) (mk4 (c 1 0) (c 1 1) (c 1 2) (c 1 3)) ∧
      Vec (memk.put512 (r15 + 0#64) v0) (r15 + d1) (mk4 (c 1 4) (c 1 5) (c 1 6) (c 1 7)) := by
    intro memk d0 d1 h0 h1; rw [hv0]; exact ⟨vec_put512_z16_2 h0, vec_put512_z16_3 h1⟩
  have far1 : ∀ {memk : Mem} {c0 : BitVec 64} {vk : Z} {d0 d1 : BitVec 64} {u0 u1 : V},
      64#64 ≤ d0 - c0 → 16#64 ≤ c0 - d0 → 64#64 ≤ d1 - c0 → 16#64 ≤ c0 - d1 →
      (Vec memk (r15 + d0) u0 ∧ Vec memk (r15 + d1) u1) →
      (Vec (memk.put512 (r15 + c0) vk) (r15 + d0) u0 ∧ Vec (memk.put512 (r15 + c0) vk) (r15 + d1) u1) :=
    fun a1 a2 b1 b2 h => ⟨step_far a1 a2 h.1, step_far b1 b2 h.2⟩
  have mk_pair : ∀ (k : Nat) (ck : BitVec 64) (vk : Z)
      (hvk : vk = z16 (c (2*k) 0) (c (2*k) 1) (c (2*k) 2) (c (2*k) 3) (c (2*k) 4) (c (2*k) 5) (c (2*k) 6) (c (2*k) 7)
                      (c (2*k+1) 0) (c (2*k+1) 1) (c (2*k+1) 2) (c (2*k+1) 3) (c (2*k+1) 4) (c (2*k+1) 5) (c (2*k+1) 6) (c (2*k+1) 7))
      (memk : Mem) (d0 d1 d2 d3 : BitVec 64)
      (h0 : d0 = ck) (h1 : d1 = ck + 16#64) (h2 : d2 = ck + 32#64) (h3 : d3 = ck + 48#64),
      (Vec (memk.put512 (r15 + ck) vk) (r15 + d0) (mk4 (c (2*k) 0) (c (2*k) 1) (c (2*k) 2) (c (2*k) 3)) ∧
       Vec (memk.put512 (r15 + ck) vk) (r15 + d1) (mk4 (c (2*k) 4) (c (2*k) 5) (c (2*k) 6) (c (2*k) 7))) ∧
      (Vec (memk.put512 (r15 + ck) vk) (r15 + d2) (mk4 (c (2*k+1) 0) (c (2*k+1) 1) (c (2*k+1) 2) (c (2*k+1) 3)) ∧
       Vec (memk.put512 (r15 + ck) vk) (r15 + d3) (mk4 (c (2*k+1) 4) (c (2*k+1) 5) (c (2*k+1) 6) (c (2*k+1) 7))) := by
    intro k ck vk hvk memk d0 d1 d2 d3 h0 h1 h2 h3; subst hvk
    exact ⟨⟨vec_put512_z16_0 h0, vec_put512_z16_1 h1⟩, ⟨vec_put512_z16_2 h2, vec_put512_z16_3 h3⟩⟩
  clear pair0 pair1
  dsimp only [m]
  rcases i with _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | i
  · refine far1 ?_ ?_ ?_ ?_ (far1 ?_ ?_ ?_ ?_ (far1 ?_ ?_ ?_ ?_ (far1 ?_ ?_ ?_ ?_ (far1 ?_ ?_ ?_ ?_ (far1 ?_ ?_ ?_ ?_ (far1 ?_ ?_ ?_ ?_ (mk_pair 0 0#64 v0 hv0 _ 0#64 16#64 32#64 48#64 (by decide) (by decide) (by decide) (by decide)).1)))))); all_goals decide
  · refine far1 ?_ ?_ ?_ ?_ (far1 ?_ ?_ ?_ ?_ (far1 ?_ ?_ ?_ ?_ (far1 ?_ ?_ ?_ ?_ (far1 ?_ ?_ ?_ ?_ (far1 ?_ ?_ ?_ ?_ (far1 ?_ ?_ ?_ ?_ (mk_pair 0 0#64 v0 hv0 _ 0#64 16#64 32#64 48#64 (by decide) (by decide) (by decide) (by decide)).2)))))); all_goals decide
  · refine far1 ?_ ?_ ?_ ?_ (far1 ?_ ?_ ?_ ?_ (far1 ?_ ?_ ?_ ?_ (far1 ?_ ?_ ?_ ?_ (far1 ?_ ?_ ?_ ?_ (far1 ?_ ?_ ?_ ?_ (mk_pair 1 64#64 v1 hv1 _ 64#64 80#64 96#64 112#64 (by decide) (by decide) (by decide) (by decide)).1))))); all_goals decide
  · refine far1 ?_ ?_ ?_ ?_ (far1 ?_ ?_ ?_ ?_ (far1 ?_ ?_ ?_ ?_ (far1 ?_ ?_ ?_ ?_ (far1 ?_ ?_ ?_ ?_ (far1 ?_ ?_ ?_ ?_ (mk_pair 1 64#64 v1 hv1 _ 64#64 80#64 96#64 112#64 (by decide) (by decide) (by decide) (by decide)).2))))); all_goals decide
  · refine far1 ?_ ?_ ?_ ?_ (far1 ?_ ?_ ?_ ?_ (far1 ?_ ?_ ?_ ?_ (far1 ?_ ?_ ?_ ?_ (far1 ?_ ?_ ?_ ?_ (mk_pair 2 128#64 v2 hv2 _ 128#64 144#64 160#64 176#64 (by decide) (by decide) (by decide) (by decide)).1)))); all_goals decide
  · refine far1 ?_ ?_ ?_ ?_ (far1 ?_ ?_ ?_ ?_ (far1 ?_ ?_ ?_ ?_ (far1 ?_ ?_ ?_ ?_ (far1 ?_ ?_ ?_ ?_ (mk_pair 2 128#64 v2 hv2 _ 128#64 144#64 160#64 176#64 (by decide) (by decide) (by decide) (by decide)).2)))); all_goals decide
  · refine far1 ?_ ?_ ?_ ?_ (far1 ?_ ?_ ?_ ?_ (far1 ?_ ?_ ?_ ?_ (far1 ?_ ?_ ?_ ?_ (mk_pair 3 192#64 v3 hv3 _ 192#64 208#64 224#64 240#64 (by decide) (by decide) (by decide) (by decide)).1))); all_goals decide
  · refine far1 ?_ ?_ ?_ ?_ (far1 ?_ ?_ ?_ ?_ (far1 ?_ ?_ ?_ ?_ (far1 ?_ ?_ ?_ ?_ (mk_pair 3 192#64 v3 hv3 _ 192#64 208#64 224#64 240#64 (by decide) (by decide) (by decide) (by decide)).2))); all_goals decide
  · refine far1 ?_ ?_ ?_ ?_ (far1 ?_ ?_ ?_ ?_ (far1 ?_ ?_ ?_ ?_ (mk_pair 4 256#64 v4 hv4 _ 256#64 272#64 288#64 304#64 (by decide) (by decide) (by decide) (by decide)).1)); all_goals decide
  · refine far1 ?_ ?_ ?_ ?_ (far1 ?_ ?_ ?_ ?_ (far1 ?_ ?_ ?_ ?_ (mk_pair 4 256#64 v4 hv4 _ 256#64 272#64 288#64 304#64 (by decide) (by decide) (by decide) (by decide)).2)); all_goals decide
  · refine far1 ?_ ?_ ?_ ?_ (far1 ?_ ?_ ?_ ?_ (mk_pair 5 320#64 v5 hv5 _ 320#64 336#64 352#64 368#64 (by decide) (by decide) (by decide) (by decide)).1); all_goals decide
  · refine far1 ?_ ?_ ?_ ?_ (far1 ?_ ?_ ?_ ?_ (mk_pair 5 320#64 v5 hv5 _ 320#64 336#64 352#64 368#64 (by decide) (by decide) (by decide) (by decide)).2); all_goals decide
  · refine far1 ?_ ?_ ?_ ?_ (mk_pair 6 384#64 v6 hv6 _ 384#64 400#64 416#64 432#64 (by decide) (by decide) (by decide) (by decide)).1; all_goals decide
  · refine far1 ?_ ?_ ?_ ?_ (mk_pair 6 384#64 v6 hv6 _ 384#64 400#64 416#64 432#64 (by decide) (by decide) (by decide) (by decide)).2; all_goals decide
  · exact (mk_pair 7 448#64 v7 hv7 _ 448#64 464#64 480#64 496#64 (by decide) (by decide) (by decide) (by decide)).1
  · exact (mk_pair 7 448#64 v7 hv7 _ 448#64 464#64 480#64 496#64 (by decide) (by decide) (by decide) (by decide)).2
  · omega

set_option maxRecDepth 1000000 in
set_option maxHeartbeats 0 in
/-- **Feed-forward and output transpose** (`0x18977` to `0x18ABE`, 52 instructions). -/
theorem transpose_out (v : Nat → Vector (BitVec 32) 16) (st : State)
    (hpc : st.pc = 0x18977) (hr13 : st.r13 = 1#64)
    (ho : Cells.Region st.mem st.r15 512#64) (hv : RowsV st v) :
    ∃ st', steps Code_p16.prog 52 st = some st' ∧ st'.pc = 0x18ABE ∧
      CvsOutAt st'.mem st.r15 (fun i => low8 (v i)) ∧
      st'.rbx = st.rbx ∧ st'.rbp = st.rbp ∧ st'.r12 = st.r12 ∧ st'.r14 = st.r14 + 0x40#64 ∧
      st'.r15 = st.r15 ∧ st'.rsp = st.rsp ∧
      (∀ x : BitVec 64, 512#64 ≤ x - st.r15 → st'.mem x = st.mem x) := by
  let c (i k : Nat) := (low8 (v i))[k]!
  obtain ⟨sf, ef, pcf, hz0, hz1, hz2, hz3, hz4, hz5, hz6, hz7, bxf, bpf, r12f, r14f, r15f, spf, mf⟩ :=
    feed_forward v st hpc hr13 hv
  obtain ⟨s0, es, pc0, hr, bx0, bp0, r12_0, r14_0, r15_0, sp0, m0⟩ :=
    out_shuf c sf pcf hz0 hz1 hz2 hz3 hz4 hz5 hz6 hz7
  have e0 : steps Code_p16.prog 36 st = some s0 := by rw [show (36 : Nat) = 12 + 24 from rfl, steps_add, ef, Option.bind_some, es]
  have bx0 : s0.rbx = st.rbx := bx0.trans bxf
  have bp0 : s0.rbp = st.rbp := bp0.trans bpf
  have r12_0 : s0.r12 = st.r12 := r12_0.trans r12f
  have r14_0 : s0.r14 = st.r14 + 0x40#64 := r14_0.trans r14f
  have r15_0 : s0.r15 = st.r15 := r15_0.trans r15f
  have sp0 : s0.rsp = st.rsp := sp0.trans spf
  have m0 : s0.mem = st.mem := m0.trans mf
  have ho_0 : Cells.Region s0.mem s0.r15 512#64 := by rw [m0, r15_0]; exact ho
  have ho0 := owned64_region ho_0 0#64 (by bv_decide)
  have ho1 := owned64_region ho_0 64#64 (by bv_decide)
  have ho2 := owned64_region ho_0 128#64 (by bv_decide)
  have ho3 := owned64_region ho_0 192#64 (by bv_decide)
  have ho4 := owned64_region ho_0 256#64 (by bv_decide)
  have ho5 := owned64_region ho_0 320#64 (by bv_decide)
  have ho6 := owned64_region ho_0 384#64 (by bv_decide)
  have ho7 := owned64_region ho_0 448#64 (by bv_decide)
  obtain ⟨h6, h5, h2, h3, h7, h16, h1, h0⟩ := hr
  obtain ⟨s1, e1, pc1, m1, z1, bx1, bp1, r12_1, r14_1, r15_1, sp1⟩ :=
    out_pair_88 s0 0x18A4F 0x18A56 0x18A5C 6 5 0#64 _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
      pc0 Code_p16.at_18A4F Code_p16.at_18A56 ho0 h6 h5
  obtain ⟨s2, e2, pc2, m2, z2, bx2, bp2, r12_2, r14_2, r15_2, sp2⟩ :=
    out_pair_88 s1 0x18A5C 0x18A63 0x18A6A 2 3 64#64 _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
      pc1 Code_p16.at_18A5C Code_p16.at_18A63 (by rw [m1, r15_1]; exact owned64_put512 _ _ _ _ ho1)
      (by rw [z1 2 (by decide)]; exact h2) (by rw [z1 3 (by decide)]; exact h3)
  obtain ⟨s3, e3, pc3, m3, z3, bx3, bp3, r12_3, r14_3, r15_3, sp3⟩ :=
    out_pair_88 s2 0x18A6A 0x18A71 0x18A78 7 16 128#64 _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
      pc2 Code_p16.at_18A6A Code_p16.at_18A71 (by rw [m2, r15_2, m1, r15_1]; exact owned64_put512 _ _ _ _ (owned64_put512 _ _ _ _ ho2))
      (by rw [z2 7 (by decide), z1 7 (by decide)]; exact h7) (by rw [z2 16 (by decide), z1 16 (by decide)]; exact h16)
  obtain ⟨s4, e4, pc4, m4, z4, bx4, bp4, r12_4, r14_4, r15_4, sp4⟩ :=
    out_pair_88 s3 0x18A78 0x18A7F 0x18A86 1 0 192#64 _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
      pc3 Code_p16.at_18A78 Code_p16.at_18A7F (by rw [m3, r15_3, m2, r15_2, m1, r15_1]; exact owned64_put512 _ _ _ _ (owned64_put512 _ _ _ _ (owned64_put512 _ _ _ _ ho3)))
      (by rw [z3 1 (by decide), z2 1 (by decide), z1 1 (by decide)]; exact h1) (by rw [z3 0 (by decide), z2 0 (by decide), z1 0 (by decide)]; exact h0)
  obtain ⟨s5, e5, pc5, m5, z5, bx5, bp5, r12_5, r14_5, r15_5, sp5⟩ :=
    out_pair_dd s4 0x18A86 0x18A8D 0x18A94 6 5 256#64 _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
      pc4 Code_p16.at_18A86 Code_p16.at_18A8D (by rw [m4, r15_4, m3, r15_3, m2, r15_2, m1, r15_1]; exact owned64_put512 _ _ _ _ (owned64_put512 _ _ _ _ (owned64_put512 _ _ _ _ (owned64_put512 _ _ _ _ ho4))))
      (by rw [z4 6 (by decide), z3 6 (by decide), z2 6 (by decide), z1 6 (by decide)]; exact h6) (by rw [z4 5 (by decide), z3 5 (by decide), z2 5 (by decide), z1 5 (by decide)]; exact h5)
  obtain ⟨s6, e6, pc6, m6, z6, bx6, bp6, r12_6, r14_6, r15_6, sp6⟩ :=
    out_pair_dd s5 0x18A94 0x18A9B 0x18AA2 2 3 320#64 _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
      pc5 Code_p16.at_18A94 Code_p16.at_18A9B (by rw [m5, r15_5, m4, r15_4, m3, r15_3, m2, r15_2, m1, r15_1]; exact owned64_put512 _ _ _ _ (owned64_put512 _ _ _ _ (owned64_put512 _ _ _ _ (owned64_put512 _ _ _ _ (owned64_put512 _ _ _ _ ho5)))))
      (by rw [z5 2 (by decide), z4 2 (by decide), z3 2 (by decide), z2 2 (by decide), z1 2 (by decide)]; exact h2) (by rw [z5 3 (by decide), z4 3 (by decide), z3 3 (by decide), z2 3 (by decide), z1 3 (by decide)]; exact h3)
  obtain ⟨s7, e7, pc7, m7, z7, bx7, bp7, r12_7, r14_7, r15_7, sp7⟩ :=
    out_pair_dd s6 0x18AA2 0x18AA9 0x18AB0 7 16 384#64 _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
      pc6 Code_p16.at_18AA2 Code_p16.at_18AA9 (by rw [m6, r15_6, m5, r15_5, m4, r15_4, m3, r15_3, m2, r15_2, m1, r15_1]; exact owned64_put512 _ _ _ _ (owned64_put512 _ _ _ _ (owned64_put512 _ _ _ _ (owned64_put512 _ _ _ _ (owned64_put512 _ _ _ _ (owned64_put512 _ _ _ _ ho6))))))
      (by rw [z6 7 (by decide), z5 7 (by decide), z4 7 (by decide), z3 7 (by decide), z2 7 (by decide), z1 7 (by decide)]; exact h7) (by rw [z6 16 (by decide), z5 16 (by decide), z4 16 (by decide), z3 16 (by decide), z2 16 (by decide), z1 16 (by decide)]; exact h16)
  obtain ⟨s8, e8, pc8, m8, _, bx8, bp8, r12_8, r14_8, r15_8, sp8⟩ :=
    out_pair_dd s7 0x18AB0 0x18AB7 0x18ABE 1 0 448#64 _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
      pc7 Code_p16.at_18AB0 Code_p16.at_18AB7 (by rw [m7, r15_7, m6, r15_6, m5, r15_5, m4, r15_4, m3, r15_3, m2, r15_2, m1, r15_1]; exact owned64_put512 _ _ _ _ (owned64_put512 _ _ _ _ (owned64_put512 _ _ _ _ (owned64_put512 _ _ _ _ (owned64_put512 _ _ _ _ (owned64_put512 _ _ _ _ (owned64_put512 _ _ _ _ ho7)))))))
      (by rw [z7 1 (by decide), z6 1 (by decide), z5 1 (by decide), z4 1 (by decide), z3 1 (by decide), z2 1 (by decide), z1 1 (by decide)]; exact h1) (by rw [z7 0 (by decide), z6 0 (by decide), z5 0 (by decide), z4 0 (by decide), z3 0 (by decide), z2 0 (by decide), z1 0 (by decide)]; exact h0)
  refine ⟨s8, ?_, pc8, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_⟩
  · rw [show (52 : Nat) = 36 + (2 + (2 + (2 + (2 + (2 + (2 + (2 + 2))))))) from rfl,
      steps_add, e0, Option.bind_some, steps_add, e1, Option.bind_some, steps_add, e2, Option.bind_some,
      steps_add, e3, Option.bind_some, steps_add, e4, Option.bind_some, steps_add, e5, Option.bind_some,
      steps_add, e6, Option.bind_some, steps_add, e7, Option.bind_some, e8]
  · rw [m8, r15_7, m7, r15_6, m6, r15_5, m5, r15_4, m4, r15_3, m3, r15_2, m2, r15_1, m1, r15_0, m0]
    intro i hi
    have h8 := cvsOutAt_of_8_stores st.mem st.r15 c _ _ _ _ _ _ _ _ rfl rfl rfl rfl rfl rfl rfl rfl i hi
    have ew : ∀ (w : Vector (BitVec 32) 8) (k : Nat) (hk : k < 8), w[k] = w[k]! := fun w k hk => (getElem!_pos w k hk).symm
    simp only [ew _ 0 (by decide), ew _ 1 (by decide), ew _ 2 (by decide), ew _ 3 (by decide),
      ew _ 4 (by decide), ew _ 5 (by decide), ew _ 6 (by decide), ew _ 7 (by decide)]
    exact h8
  · rw [bx8, bx7, bx6, bx5, bx4, bx3, bx2, bx1, bx0]
  · rw [bp8, bp7, bp6, bp5, bp4, bp3, bp2, bp1, bp0]
  · rw [r12_8, r12_7, r12_6, r12_5, r12_4, r12_3, r12_2, r12_1, r12_0]
  · rw [r14_8, r14_7, r14_6, r14_5, r14_4, r14_3, r14_2, r14_1, r14_0]
  · rw [r15_8, r15_7, r15_6, r15_5, r15_4, r15_3, r15_2, r15_1, r15_0]
  · rw [sp8, sp7, sp6, sp5, sp4, sp3, sp2, sp1, sp0]
  · intro x hx
    rw [m8, r15_7, m7, r15_6, m6, r15_5, m5, r15_4, m4, r15_3, m3, r15_2, m2, r15_1, m1, r15_0, m0]
    clear m8 r15_7 m7 r15_6 m6 r15_5 m5 r15_4 m4 r15_3 m3 r15_2 m2 r15_1 m1 ho0 ho1 ho2 ho3 ho4 ho5 ho6 ho7 ho_0
    have ha : ∀ (mm : Mem) (d : BitVec 64) (v : Z), d ≤ 448#64 → 512#64 ≤ x - st.r15 → mm.put512 (st.r15 + d) v x = mm x :=
      fun mm d v hd hx' => put512_other mm (st.r15 + d) v x (by bv_omega)
    rw [ha _ 448#64 _ (by decide) hx, ha _ 384#64 _ (by decide) hx,
      ha _ 320#64 _ (by decide) hx, ha _ 256#64 _ (by decide) hx,
      ha _ 192#64 _ (by decide) hx, ha _ 128#64 _ (by decide) hx,
      ha _ 64#64 _ (by decide) hx, ha _ 0#64 _ (by decide) hx]

end P16
