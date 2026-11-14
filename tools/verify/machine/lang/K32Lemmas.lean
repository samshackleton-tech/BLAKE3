import WideLemmas
open X86

/-! # The mask registers, lane by lane, and the 32 lanes' chunk counters

Facts about the model's wide values alone (no code): a compare writes one bit a lane, a masked add changes
the lanes whose bit is set, and the kernel's counter set-up (add the lane's index to the low word; where that
wrapped, add one to the high word) is the 64-bit counter plus the lane's index, in both words. -/

namespace K32

/-- A wide value is its sixteen lanes. -/
theorem zpack_zdw (v : Z) : zpack (zdw v) = v := by
  simp only [zpack, zdw, Nat.reduceMul]; bv_decide

theorem z_ext {a b : Z} (h : ∀ i, i < 16 → zdw a i = zdw b i) : a = b := by
  rw [← zpack_zdw a, ← zpack_zdw b]; exact zpack_congr h

/-- A masked lane-wise instruction: the lanes whose mask bit is set get the result, the others keep the
destination's. -/
theorem zdw_zmap2k (f : BitVec 32 → BitVec 32 → BitVec 32) (dst : Z) (k : BitVec 16) (a b : Z) {i : Nat} (hi : i < 16) :
    zdw (zmap2k f dst k a b) i = if k.getLsbD i then f (zdw a i) (zdw b i) else zdw dst i := by
  simp only [zmap2k]; exact zdw_zpack _ i hi

/-- VPCMPUD writes lane `i`'s comparison to bit `i` of the mask. -/
theorem zcmpud_getLsbD (a b : Z) (imm : Nat) : ∀ i, i < 16 → (zcmpud a b imm).getLsbD i = cmpud1 imm (zdw a i) (zdw b i)
  | 0, _ => by simp only [zcmpud]; bv_decide
  | 1, _ => by simp only [zcmpud]; bv_decide
  | 2, _ => by simp only [zcmpud]; bv_decide
  | 3, _ => by simp only [zcmpud]; bv_decide
  | 4, _ => by simp only [zcmpud]; bv_decide
  | 5, _ => by simp only [zcmpud]; bv_decide
  | 6, _ => by simp only [zcmpud]; bv_decide
  | 7, _ => by simp only [zcmpud]; bv_decide
  | 8, _ => by simp only [zcmpud]; bv_decide
  | 9, _ => by simp only [zcmpud]; bv_decide
  | 10, _ => by simp only [zcmpud]; bv_decide
  | 11, _ => by simp only [zcmpud]; bv_decide
  | 12, _ => by simp only [zcmpud]; bv_decide
  | 13, _ => by simp only [zcmpud]; bv_decide
  | 14, _ => by simp only [zcmpud]; bv_decide
  | 15, _ => by simp only [zcmpud]; bv_decide
  | n + 16, h => absurd h (by omega)

/-- Predicate 1 of VPCMPUD is "less than", unsigned. -/
theorem cmpud1_lt (a b : BitVec 32) : cmpud1 1 a b = a.ult b := rfl

/-- The low word of a counter plus a lane's index. -/
theorem counter_lo (c j : BitVec 64) :
    (c &&& 0xFFFFFFFF#64).setWidth 32 + j.setWidth 32 = (c + j).setWidth 32 := by bv_decide

/-- The high word: one more where adding the index wrapped the low word. -/
theorem counter_hi (c j : BitVec 64) (hj : j < 0x100000000#64) :
    (if ((c &&& 0xFFFFFFFF#64).setWidth 32 + j.setWidth 32).ult ((c &&& 0xFFFFFFFF#64).setWidth 32)
      then ((c >>> 32) &&& 0xFFFFFFFF#64).setWidth 32 + 1#32 else ((c >>> 32) &&& 0xFFFFFFFF#64).setWidth 32) =
    ((c + j) >>> 32).setWidth 32 := by bv_decide

/-- **The low counter words of sixteen lanes**, as the kernel makes them: the counter's low word in every lane,
plus the lanes' indices (`first` to `first + 15`, a row of the kernel's index table). -/
theorem counters_lo (c : BitVec 64) (first : BitVec 64) (idx : Z)
    (hidx : ∀ i, i < 16 → zdw idx i = (first + BitVec.ofNat 64 i).setWidth 32) :
    zmap2 (· + ·) (zbroadcast ((c &&& 0xFFFFFFFF#64).setWidth 32)) idx =
      zpack fun i => (c + (first + BitVec.ofNat 64 i)).setWidth 32 := by
  apply z_ext; intro i hi
  rw [zdw_zmap2 _ _ _ hi, zdw_zbroadcast _ i hi, hidx i hi, zdw_zpack _ i hi]
  exact counter_lo c _

/-- **The high counter words of sixteen lanes**, as the kernel makes them: the counter's high word in every
lane, and one more (a masked add) in the lanes whose low word wrapped (an unsigned compare into the mask). -/
theorem counters_hi (c : BitVec 64) (first : BitVec 64) (idx : Z) (hf : first ≤ 16#64)
    (hidx : ∀ i, i < 16 → zdw idx i = (first + BitVec.ofNat 64 i).setWidth 32) :
    zmap2k (· + ·) (zbroadcast (((c >>> 32) &&& 0xFFFFFFFF#64).setWidth 32))
        (zcmpud (zmap2 (· + ·) (zbroadcast ((c &&& 0xFFFFFFFF#64).setWidth 32)) idx) (zbroadcast ((c &&& 0xFFFFFFFF#64).setWidth 32)) 1)
        (zbroadcast (((c >>> 32) &&& 0xFFFFFFFF#64).setWidth 32)) (zbroadcast 1#32) =
      zpack fun i => ((c + (first + BitVec.ofNat 64 i)) >>> 32).setWidth 32 := by
  apply z_ext; intro i hi
  rw [zdw_zmap2k _ _ _ _ _ hi, zcmpud_getLsbD _ _ _ i hi, cmpud1_lt, zdw_zmap2 _ _ _ hi, zdw_zbroadcast _ i hi,
    zdw_zbroadcast _ i hi, zdw_zbroadcast _ i hi, hidx i hi, zdw_zpack _ i hi]
  have hj : first + BitVec.ofNat 64 i < 0x100000000#64 := by
    have : BitVec.ofNat 64 i < 16#64 := by
      rw [BitVec.lt_def, BitVec.toNat_ofNat]; simp only [BitVec.toNat_ofNat, Nat.reducePow, Nat.reduceMod]; omega
    bv_omega
  exact counter_hi c _ hj

/-- The first row of the kernel's index table: lane `i`'s index is `i`. -/
theorem indices0 : ∀ i, i < 16 → zdw 0x0000000F0000000E0000000D0000000C0000000B0000000A00000009000000080000000700000006000000050000000400000003000000020000000100000000#512 i = (0#64 + BitVec.ofNat 64 i).setWidth 32
  | 0, _ => by simp only [zdw, Nat.reduceMul]; bv_decide
  | 1, _ => by simp only [zdw, Nat.reduceMul]; bv_decide
  | 2, _ => by simp only [zdw, Nat.reduceMul]; bv_decide
  | 3, _ => by simp only [zdw, Nat.reduceMul]; bv_decide
  | 4, _ => by simp only [zdw, Nat.reduceMul]; bv_decide
  | 5, _ => by simp only [zdw, Nat.reduceMul]; bv_decide
  | 6, _ => by simp only [zdw, Nat.reduceMul]; bv_decide
  | 7, _ => by simp only [zdw, Nat.reduceMul]; bv_decide
  | 8, _ => by simp only [zdw, Nat.reduceMul]; bv_decide
  | 9, _ => by simp only [zdw, Nat.reduceMul]; bv_decide
  | 10, _ => by simp only [zdw, Nat.reduceMul]; bv_decide
  | 11, _ => by simp only [zdw, Nat.reduceMul]; bv_decide
  | 12, _ => by simp only [zdw, Nat.reduceMul]; bv_decide
  | 13, _ => by simp only [zdw, Nat.reduceMul]; bv_decide
  | 14, _ => by simp only [zdw, Nat.reduceMul]; bv_decide
  | 15, _ => by simp only [zdw, Nat.reduceMul]; bv_decide
  | n + 16, h => absurd h (by omega)

/-- The second row: lane `i`'s index is `16 + i`. -/
theorem indices1 : ∀ i, i < 16 → zdw 0x0000001F0000001E0000001D0000001C0000001B0000001A00000019000000180000001700000016000000150000001400000013000000120000001100000010#512 i = (16#64 + BitVec.ofNat 64 i).setWidth 32
  | 0, _ => by simp only [zdw, Nat.reduceMul]; bv_decide
  | 1, _ => by simp only [zdw, Nat.reduceMul]; bv_decide
  | 2, _ => by simp only [zdw, Nat.reduceMul]; bv_decide
  | 3, _ => by simp only [zdw, Nat.reduceMul]; bv_decide
  | 4, _ => by simp only [zdw, Nat.reduceMul]; bv_decide
  | 5, _ => by simp only [zdw, Nat.reduceMul]; bv_decide
  | 6, _ => by simp only [zdw, Nat.reduceMul]; bv_decide
  | 7, _ => by simp only [zdw, Nat.reduceMul]; bv_decide
  | 8, _ => by simp only [zdw, Nat.reduceMul]; bv_decide
  | 9, _ => by simp only [zdw, Nat.reduceMul]; bv_decide
  | 10, _ => by simp only [zdw, Nat.reduceMul]; bv_decide
  | 11, _ => by simp only [zdw, Nat.reduceMul]; bv_decide
  | 12, _ => by simp only [zdw, Nat.reduceMul]; bv_decide
  | 13, _ => by simp only [zdw, Nat.reduceMul]; bv_decide
  | 14, _ => by simp only [zdw, Nat.reduceMul]; bv_decide
  | 15, _ => by simp only [zdw, Nat.reduceMul]; bv_decide
  | n + 16, h => absurd h (by omega)

end K32
