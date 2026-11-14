import P16Loop
import Spec_cvl
open X86 Cells Blake3Generic

/-! # Input and output transposes of the wide parent kernel `p16`

Proved by six pure rewrite rules over 16 doublewords (`z16`): `zunpckldq`, `zunpckhdq`, `zunpcklqdq`,
`zunpckhqdq`, `zshufi32x4 _ _ 0x88` and `zshufi32x4 _ _ 0xDD`. No SAT solver. -/

namespace P16

/-- Sixteen doublewords as a ZMM register, lowest first (`z16 (f 0) ... (f 15) = zpack f`). -/
def z16 (w0 w1 w2 w3 w4 w5 w6 w7 w8 w9 w10 w11 w12 w13 w14 w15 : BitVec 32) : Z :=
  w15 ++ w14 ++ w13 ++ w12 ++ w11 ++ w10 ++ w9 ++ w8 ++ w7 ++ w6 ++ w5 ++ w4 ++ w3 ++ w2 ++ w1 ++ w0

theorem z16_eq_zpack (f : Nat → BitVec 32) :
    z16 (f 0) (f 1) (f 2) (f 3) (f 4) (f 5) (f 6) (f 7) (f 8) (f 9) (f 10) (f 11) (f 12) (f 13) (f 14) (f 15) = zpack f := rfl

private theorem zpack_quarters (f : Nat → BitVec 32) :
    mk4 (f 12) (f 13) (f 14) (f 15) ++ mk4 (f 8) (f 9) (f 10) (f 11) ++
      mk4 (f 4) (f 5) (f 6) (f 7) ++ mk4 (f 0) (f 1) (f 2) (f 3) =
      z16 (f 0) (f 1) (f 2) (f 3) (f 4) (f 5) (f 6) (f 7) (f 8) (f 9) (f 10) (f 11) (f 12) (f 13) (f 14) (f 15) := by
  have h := zjoin_quarters (zpack f)
  rw [zquarter_zpack f 0 (by decide), zquarter_zpack f 1 (by decide),
    zquarter_zpack f 2 (by decide), zquarter_zpack f 3 (by decide)] at h
  exact h

theorem zdw_z16 {w0 w1 w2 w3 w4 w5 w6 w7 w8 w9 w10 w11 w12 w13 w14 w15 : BitVec 32} (i : Nat) (hi : i < 16) :
    zdw (z16 w0 w1 w2 w3 w4 w5 w6 w7 w8 w9 w10 w11 w12 w13 w14 w15) i =
      #[w0, w1, w2, w3, w4, w5, w6, w7, w8, w9, w10, w11, w12, w13, w14, w15][i]! := by
  change zdw (zpack fun k => #[w0, w1, w2, w3, w4, w5, w6, w7, w8, w9, w10, w11, w12, w13, w14, w15][k]!) i = _
  exact zdw_zpack _ i hi

theorem zquarter_eq {a b : Z}
    (h0 : zquarter a 0 = zquarter b 0) (h1 : zquarter a 1 = zquarter b 1)
    (h2 : zquarter a 2 = zquarter b 2) (h3 : zquarter a 3 = zquarter b 3) : a = b := by
  rw [← zjoin_quarters a, ← zjoin_quarters b, h0, h1, h2, h3]

theorem zpack_zdw (v : Z) : zpack (zdw v) = v := by
  apply zquarter_eq
  · rw [zquarter_zpack _ 0 (by decide)]; simp only [zdw, zquarter, mk4, Nat.reduceMul, Nat.reduceAdd]; bv_decide
  · rw [zquarter_zpack _ 1 (by decide)]; simp only [zdw, zquarter, mk4, Nat.reduceMul, Nat.reduceAdd]; bv_decide
  · rw [zquarter_zpack _ 2 (by decide)]; simp only [zdw, zquarter, mk4, Nat.reduceMul, Nat.reduceAdd]; bv_decide
  · rw [zquarter_zpack _ 3 (by decide)]; simp only [zdw, zquarter, mk4, Nat.reduceMul, Nat.reduceAdd]; bv_decide

theorem z16_eq_arr (w0 w1 w2 w3 w4 w5 w6 w7 w8 w9 w10 w11 w12 w13 w14 w15 : BitVec 32) :
    z16 w0 w1 w2 w3 w4 w5 w6 w7 w8 w9 w10 w11 w12 w13 w14 w15 =
      zpack (fun k => #[w0, w1, w2, w3, w4, w5, w6, w7, w8, w9, w10, w11, w12, w13, w14, w15][k]!) := rfl

theorem z16_ldq (a0 a1 a2 a3 a4 a5 a6 a7 a8 a9 a10 a11 a12 a13 a14 a15
    b0 b1 b2 b3 b4 b5 b6 b7 b8 b9 b10 b11 b12 b13 b14 b15 : BitVec 32) :
    zunpckldq (z16 a0 a1 a2 a3 a4 a5 a6 a7 a8 a9 a10 a11 a12 a13 a14 a15)
      (z16 b0 b1 b2 b3 b4 b5 b6 b7 b8 b9 b10 b11 b12 b13 b14 b15) =
    z16 a0 b0 a1 b1 a4 b4 a5 b5 a8 b8 a9 b9 a12 b12 a13 b13 := by
  rw [← zpack_zdw (zunpckldq _ _)]
  conv => rhs; rw [z16_eq_arr]
  apply zpack_congr; intro i hi
  rcases i with _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | i
  all_goals first
    | omega
    | (simp (disch := decide) only [zdw_zunpckldq, zdw_z16, Nat.reduceMul, Nat.reduceDiv, Nat.reduceMod, Nat.reduceAdd]; rfl)

theorem z16_hdq (a0 a1 a2 a3 a4 a5 a6 a7 a8 a9 a10 a11 a12 a13 a14 a15
    b0 b1 b2 b3 b4 b5 b6 b7 b8 b9 b10 b11 b12 b13 b14 b15 : BitVec 32) :
    zunpckhdq (z16 a0 a1 a2 a3 a4 a5 a6 a7 a8 a9 a10 a11 a12 a13 a14 a15)
      (z16 b0 b1 b2 b3 b4 b5 b6 b7 b8 b9 b10 b11 b12 b13 b14 b15) =
    z16 a2 b2 a3 b3 a6 b6 a7 b7 a10 b10 a11 b11 a14 b14 a15 b15 := by
  rw [← zpack_zdw (zunpckhdq _ _)]
  conv => rhs; rw [z16_eq_arr]
  apply zpack_congr; intro i hi
  rcases i with _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | i
  all_goals first
    | omega
    | (simp (disch := decide) only [zdw_zunpckhdq, zdw_z16, Nat.reduceMul, Nat.reduceDiv, Nat.reduceMod, Nat.reduceAdd]; rfl)

theorem z16_lqdq (a0 a1 a2 a3 a4 a5 a6 a7 a8 a9 a10 a11 a12 a13 a14 a15
    b0 b1 b2 b3 b4 b5 b6 b7 b8 b9 b10 b11 b12 b13 b14 b15 : BitVec 32) :
    zunpcklqdq (z16 a0 a1 a2 a3 a4 a5 a6 a7 a8 a9 a10 a11 a12 a13 a14 a15)
      (z16 b0 b1 b2 b3 b4 b5 b6 b7 b8 b9 b10 b11 b12 b13 b14 b15) =
    z16 a0 a1 b0 b1 a4 a5 b4 b5 a8 a9 b8 b9 a12 a13 b12 b13 := by
  rw [← zpack_zdw (zunpcklqdq _ _)]
  conv => rhs; rw [z16_eq_arr]
  apply zpack_congr; intro i hi
  rcases i with _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | i
  all_goals first
    | omega
    | (simp (disch := decide) only [zdw_zunpcklqdq, zdw_z16, Nat.reduceMul, Nat.reduceDiv, Nat.reduceMod, Nat.reduceAdd]; rfl)

theorem z16_hqdq (a0 a1 a2 a3 a4 a5 a6 a7 a8 a9 a10 a11 a12 a13 a14 a15
    b0 b1 b2 b3 b4 b5 b6 b7 b8 b9 b10 b11 b12 b13 b14 b15 : BitVec 32) :
    zunpckhqdq (z16 a0 a1 a2 a3 a4 a5 a6 a7 a8 a9 a10 a11 a12 a13 a14 a15)
      (z16 b0 b1 b2 b3 b4 b5 b6 b7 b8 b9 b10 b11 b12 b13 b14 b15) =
    z16 a2 a3 b2 b3 a6 a7 b6 b7 a10 a11 b10 b11 a14 a15 b14 b15 := by
  rw [← zpack_zdw (zunpckhqdq _ _)]
  conv => rhs; rw [z16_eq_arr]
  apply zpack_congr; intro i hi
  rcases i with _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | i
  all_goals first
    | omega
    | (simp (disch := decide) only [zdw_zunpckhqdq, zdw_z16, Nat.reduceMul, Nat.reduceDiv, Nat.reduceMod, Nat.reduceAdd]; rfl)

theorem z16_shuf_88 (a0 a1 a2 a3 a4 a5 a6 a7 a8 a9 a10 a11 a12 a13 a14 a15
    b0 b1 b2 b3 b4 b5 b6 b7 b8 b9 b10 b11 b12 b13 b14 b15 : BitVec 32) :
    zshufi32x4 (z16 a0 a1 a2 a3 a4 a5 a6 a7 a8 a9 a10 a11 a12 a13 a14 a15)
      (z16 b0 b1 b2 b3 b4 b5 b6 b7 b8 b9 b10 b11 b12 b13 b14 b15) 136 =
    z16 a0 a1 a2 a3 a8 a9 a10 a11 b0 b1 b2 b3 b8 b9 b10 b11 := by
  rw [← zpack_zdw (zshufi32x4 _ _ _)]
  conv => rhs; rw [z16_eq_arr]
  apply zpack_congr; intro i hi
  rcases i with _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | i
  all_goals first
    | omega
    | (simp (disch := decide) only [zdw_zshufi32x4, zdw_z16, Nat.reduceMul, Nat.reduceDiv, Nat.reduceMod, Nat.reduceAdd]; rfl)

theorem z16_shuf_dd (a0 a1 a2 a3 a4 a5 a6 a7 a8 a9 a10 a11 a12 a13 a14 a15
    b0 b1 b2 b3 b4 b5 b6 b7 b8 b9 b10 b11 b12 b13 b14 b15 : BitVec 32) :
    zshufi32x4 (z16 a0 a1 a2 a3 a4 a5 a6 a7 a8 a9 a10 a11 a12 a13 a14 a15)
      (z16 b0 b1 b2 b3 b4 b5 b6 b7 b8 b9 b10 b11 b12 b13 b14 b15) 221 =
    z16 a4 a5 a6 a7 a12 a13 a14 a15 b4 b5 b6 b7 b12 b13 b14 b15 := by
  rw [← zpack_zdw (zshufi32x4 _ _ _)]
  conv => rhs; rw [z16_eq_arr]
  apply zpack_congr; intro i hi
  rcases i with _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | i
  all_goals first
    | omega
    | (simp (disch := decide) only [zdw_zshufi32x4, zdw_z16, Nat.reduceMul, Nat.reduceDiv, Nat.reduceMod, Nat.reduceAdd]; rfl)

/-- A 64-byte input block in memory (`4` vectors), as `16` doublewords. -/
def BlockAt (mem : Mem) (a : BitVec 64) (w : Vector (BitVec 32) 16) : Prop :=
  Vec mem (a + 0#64) (mk4 w[0] w[1] w[2] w[3]) ∧
  Vec mem (a + 16#64) (mk4 w[4] w[5] w[6] w[7]) ∧
  Vec mem (a + 32#64) (mk4 w[8] w[9] w[10] w[11]) ∧
  Vec mem (a + 48#64) (mk4 w[12] w[13] w[14] w[15])

theorem read512_blockAt {mem : Mem} {a : BitVec 64} {w : Vector (BitVec 32) 16} (h : BlockAt mem a w) :
    mem.read512 a = some (z16 w[0] w[1] w[2] w[3] w[4] w[5] w[6] w[7] w[8] w[9] w[10] w[11] w[12] w[13] w[14] w[15]) := by
  obtain ⟨h0, h1, h2, h3⟩ := h
  rw [BitVec.add_zero] at h0
  rw [read512_of_vecs h0 h1 h2 h3]
  have e : ∀ (k : Nat) (hk : k < 16), w[k]! = w[k] := fun k hk => getElem!_pos w k hk
  have hz := zpack_quarters (fun k => w[k]!)
  rw [e 0 (by decide), e 1 (by decide), e 2 (by decide), e 3 (by decide),
    e 4 (by decide), e 5 (by decide), e 6 (by decide), e 7 (by decide),
    e 8 (by decide), e 9 (by decide), e 10 (by decide), e 11 (by decide),
    e 12 (by decide), e 13 (by decide), e 14 (by decide), e 15 (by decide)] at hz
  congr 1

set_option maxRecDepth 1000000 in
set_option maxHeartbeats 0 in
/-- **Input loads and transpose** (`0x18091` to `0x182F0`, 96 instructions): loads the 16 64-byte
input blocks whose addresses are in `[r12 + 8*j]` and transposes them into `MsgsV`. -/
theorem transpose_in (ptrs : Nat → BitVec 64) (m : Nat → Vector (BitVec 32) 16) (st : State)
    (hpc : st.pc = 0x18091) (hr14 : st.r14 = 0#64)
    (hp : ∀ j : Nat, j < 16 → Quad st.mem (st.r12 + BitVec.ofNat 64 (8 * j)) (ptrs j))
    (hb : ∀ j : Nat, j < 16 → BlockAt st.mem (ptrs j) (m j)) :
    ∃ st', steps Code_p16.prog 96 st = some st' ∧ st'.pc = 0x182F0 ∧
      MsgsV st' m ∧
      (∀ r, r ≤ 7 → st'.zmm r = st.zmm r) ∧
      st'.rcx = st.rcx ∧ st'.rdx = st.rdx ∧ st'.rbx = st.rbx ∧
      st'.rsp = st.rsp ∧ st'.rbp = st.rbp ∧ st'.rsi = st.rsi ∧ st'.rdi = st.rdi ∧
      st'.r8 = st.r8 ∧ st'.r9 = st.r9 ∧ st'.r12 = st.r12 ∧ st'.r13 = st.r13 ∧
      st'.r14 = st.r14 ∧ st'.r15 = st.r15 ∧ st'.w.r10 = st.w.r10 ∧ st'.w.r11 = st.w.r11 ∧
      st'.mem = st.mem := by
  have q0 := read_quad (hp 0 (by decide))
  have q1 := read_quad (hp 1 (by decide))
  have q2 := read_quad (hp 2 (by decide))
  have q3 := read_quad (hp 3 (by decide))
  have q4 := read_quad (hp 4 (by decide))
  have q5 := read_quad (hp 5 (by decide))
  have q6 := read_quad (hp 6 (by decide))
  have q7 := read_quad (hp 7 (by decide))
  have q8 := read_quad (hp 8 (by decide))
  have q9 := read_quad (hp 9 (by decide))
  have q10 := read_quad (hp 10 (by decide))
  have q11 := read_quad (hp 11 (by decide))
  have q12 := read_quad (hp 12 (by decide))
  have q13 := read_quad (hp 13 (by decide))
  have q14 := read_quad (hp 14 (by decide))
  have q15 := read_quad (hp 15 (by decide))
  have b0 := read512_blockAt (hb 0 (by decide))
  have b1 := read512_blockAt (hb 1 (by decide))
  have b2 := read512_blockAt (hb 2 (by decide))
  have b3 := read512_blockAt (hb 3 (by decide))
  have b4 := read512_blockAt (hb 4 (by decide))
  have b5 := read512_blockAt (hb 5 (by decide))
  have b6 := read512_blockAt (hb 6 (by decide))
  have b7 := read512_blockAt (hb 7 (by decide))
  have b8 := read512_blockAt (hb 8 (by decide))
  have b9 := read512_blockAt (hb 9 (by decide))
  have b10 := read512_blockAt (hb 10 (by decide))
  have b11 := read512_blockAt (hb 11 (by decide))
  have b12 := read512_blockAt (hb 12 (by decide))
  have b13 := read512_blockAt (hb 13 (by decide))
  have b14 := read512_blockAt (hb 14 (by decide))
  have b15 := read512_blockAt (hb 15 (by decide))
  obtain ⟨rax, rcx, rdx, rbx, rsp, rbp, rsi, rdi, r8, r9, r12, r13, r14, r15, zf, cf,
    x0, x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12, x13, x14, x15, mem, pc,
    ⟨r10, r11, u0, u1, u2, u3, u4, u5, u6, u7, u8, u9, u10, u11, u12, u13, u14, u15,
     z16, z17, z18, z19, z20, z21, z22, z23, z24, z25, z26, z27, z28, z29, z30, z31, _, _⟩⟩ := st
  simp only [Nat.reduceMul, BitVec.add_zero] at hpc hr14 q0 q1 q2 q3 q4 q5 q6 q7 q8 q9 q10 q11 q12 q13 q14 q15 b0 b1 b2 b3 b4 b5 b6 b7 b8 b9 b10 b11 b12 b13 b14 b15
  subst hpc hr14
  run_fn [BitVec.add_zero, q0, q1, q2, q3, q4, q5, q6, q7, q8, q9, q10, q11, q12, q13, q14, q15,
    b0, b1, b2, b3, b4, b5, b6, b7, b8, b9, b10, b11, b12, b13, b14, b15, zjoin_split, zlo_zjoin, zhi_zjoin,
    z16_ldq, z16_hdq, z16_lqdq, z16_hqdq, z16_shuf_88, z16_shuf_dd]
  refine ⟨_, rfl, rfl, ?_, ?_, rfl, rfl, rfl, rfl, rfl, rfl, rfl, rfl, rfl, rfl, rfl, rfl, rfl, rfl, rfl, rfl⟩
  · simp only [MsgsV, Msgs, State.zmm, zjoin_split]
    exact ⟨rfl, rfl, rfl, rfl, rfl, rfl, rfl, rfl, rfl, rfl, rfl, rfl, rfl, rfl, rfl, rfl⟩
  · intro r hr
    rcases r with _ | _ | _ | _ | _ | _ | _ | _ | r <;> first | omega | rfl

end P16
