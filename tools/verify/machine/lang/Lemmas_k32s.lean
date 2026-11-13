import Lemmas_cvl
import Lemmas_fillp
import Lemmas_wide
import Lemmas_hashl
import Lemmas_p16s
import Spec_k32
open X86 Cells

/-! # `k32s`: lemmas for the prover

`k32s` is the function of ours that stands at the 32-lane chunk kernel's address when examples run. Proved to
meet `K32.contract`, it is the witness that the contract the fast path assumes of that kernel can be met.
Written by hand for this function; its source names them. Checked by Lean; not to be read. -/

namespace K32s

variable {m m' : Mem} {inputs key out base n flags counter i : BitVec 64} {k : Blake3.CV} {bytes : List (BitVec 8)}

/-- The address the table holds for lane `i`. -/
def src (base n i : BitVec 64) : BitVec 64 := Ptrs.spread base n 1024#64 i.toNat

/-- The chunk a lane is given: chunk `i` of the first `n`, the first chunk in a lane past them. -/
def lane (n i : BitVec 64) : Nat := if i.toNat < n.toNat then i.toNat else 0

/-- The chunks, memory first (at least one). -/
def In (m : Mem) (base n : BitVec 64) (bytes : List (BitVec 8)) : Prop := 1#64 ≤ n ∧ Chunks.At n m base bytes

theorem In.cells (h : In m base n bytes) : 1#64 ≤ n ∧ n ≤ 32#64 := ⟨h.1, h.2.1⟩

theorem In.frame (h : In m base n bytes) (same : ∀ x : BitVec 64, x - base < n <<< 10 → m' x = m x) : In m' base n bytes :=
  ⟨h.1, Chunks.At.frame h.2 same⟩

/-- **Before the loop.** -/
theorem In.start {m0 : Mem} (hl : Chunks.At n m0 base bytes) (h1 : 1#64 ≤ n)
    (same : ∀ x : BitVec 64, x - base < n <<< 10 → m x = m0 x) : In m base n bytes :=
  ⟨h1, Chunks.At.frame hl same⟩

theorem src_eq (h32 : n.toNat ≤ 32) : src base n i = base + BitVec.ofNat 64 (1024 * lane n i) := by
  unfold src Ptrs.spread lane
  by_cases h : i.toNat < n.toNat
  · rw [if_pos h, if_pos h]
    congr 1
    apply BitVec.eq_of_toNat_eq
    simp only [BitVec.toNat_mul, BitVec.toNat_ofNat]
    omega
  · rw [if_neg h, if_neg h]; simp

theorem input_eq : K32.input n bytes i.toNat = (bytes.drop (1024 * lane n i)).take 1024 := by
  unfold K32.input lane; rfl

/-- **In a turn:** the lane's address in the table, the key's two vectors, the lane's chunk as `chunk_node`
is given it, and where it lies in the chunks' piece. -/
theorem turn (hk : Cv.At m key k) (hp : Ptrs.At m inputs (Ptrs.spread base n 1024#64)) (hin : In m base n bytes)
    (hc : i < 32#64) :
    ∃ k0 k1 : V,
      Quad m (inputs + i <<< 3) (src base n i) ∧ Vec m key k0 ∧ Vec m (key + 16#64) k1 ∧ words8 k0 k1 = k ∧
      Bytes.At m (src base n i) (K32.input n bytes i.toNat) ∧ (K32.input n bytes i.toNat).length < 2 ^ 64 ∧
      (1024#64).toNat = (K32.input n bytes i.toNat).length ∧ (K32.input n bytes i.toNat).length ≤ 1024 ∧
      BitVec.ofNat 64 (K32.input n bytes i.toNat).length = 1024#64 ∧
      src base n i - base ≤ n <<< 10 - 1024#64 ∧ 1024#64 ≤ n <<< 10 ∧ n <<< 10 ≤ 32768#64 := by
  obtain ⟨h1, h32, hl, hb⟩ := hin
  have i32 : i.toNat < 32 := hc
  have n1 : 1 ≤ n.toNat := h1
  have n32 : n.toNat ≤ 32 := h32
  have hJ : lane n i < n.toNat := by unfold lane; split <;> omega
  obtain ⟨k0, k1, hk0, hk1, hkw⟩ := hk
  have q := hp i.toNat (by omega)
  have ea : BitVec.ofNat 64 (8 * i.toNat) = i <<< 3 := by
    apply BitVec.eq_of_toNat_eq
    rw [BitVec.toNat_ofNat, BitVec.toNat_shiftLeft, Nat.shiftLeft_eq]
    omega
  rw [ea] at q
  have eS := src_eq (base := base) (i := i) n32
  have hlen : (K32.input n bytes i.toNat).length = 1024 := by
    rw [input_eq, List.length_take, List.length_drop, hl]
    have : 1024 * (lane n i + 1) ≤ 1024 * n.toNat := Nat.mul_le_mul_left 1024 hJ
    omega
  have hbytes : Bytes.At m (src base n i) (K32.input n bytes i.toNat) := by
    intro j hj
    have hj' : j < 1024 := by rw [hlen] at hj; exact hj
    have hidx : 1024 * lane n i + j < bytes.length := by
      rw [hl]
      have : 1024 * (lane n i + 1) ≤ 1024 * n.toNat := Nat.mul_le_mul_left 1024 hJ
      omega
    have e : src base n i + BitVec.ofNat 64 j = base + BitVec.ofNat 64 (1024 * lane n i + j) := by
      rw [eS]
      apply BitVec.eq_of_toNat_eq
      simp only [BitVec.toNat_add, BitVec.toNat_ofNat]
      omega
    rw [e, hb _ hidx]
    have hq : (K32.input n bytes i.toNat)[j]? = bytes[1024 * lane n i + j]? := by
      rw [input_eq, List.getElem?_take, List.getElem?_drop]
      simp only [hj', if_true]
    have hq2 : (K32.input n bytes i.toNat)[j]? = some (K32.input n bytes i.toNat)[j] := List.getElem?_eq_getElem hj
    rw [hq, List.getElem?_eq_getElem hidx] at hq2
    exact hq2
  have eN : (n <<< 10).toNat = 1024 * n.toNat := by rw [BitVec.toNat_shiftLeft, Nat.shiftLeft_eq]; omega
  have es : (BitVec.ofNat 64 (1024 * lane n i)).toNat = 1024 * lane n i := by rw [BitVec.toNat_ofNat]; omega
  have hN1 : 1024#64 ≤ n <<< 10 := by show 1024 ≤ (n <<< 10).toNat; rw [eN]; omega
  have hN2 : n <<< 10 ≤ 32768#64 := by show (n <<< 10).toNat ≤ 32768; rw [eN]; omega
  have hin' : src base n i - base ≤ n <<< 10 - 1024#64 := by
    rw [eS, P16s.add_sub_self]
    show (BitVec.ofNat 64 (1024 * lane n i)).toNat ≤ (n <<< 10 - 1024#64).toNat
    have e64 : (n <<< 10 - 1024#64).toNat = 1024 * n.toNat - 1024 := by
      rw [BitVec.toNat_sub_of_le hN1, eN]; rfl
    rw [es, e64]; omega
  exact ⟨k0, k1, q, hk0, hk1, hkw, hbytes, by rw [hlen]; decide, by rw [hlen]; rfl, by rw [hlen]; decide, by rw [hlen], hin', hN1, hN2⟩

theorem values_length : (K32.values k flags counter n bytes).length = 32 := by simp [K32.values]

theorem values_get (hi : i.toNat < 32) :
    (K32.values k flags counter n bytes)[i.toNat]? = some (Chunk.node k flags (counter + i) (K32.input n bytes i.toNat)).cv := by
  unfold K32.values
  rw [List.getElem?_map, List.getElem?_range hi]
  simp only [Option.map_some, BitVec.ofNat_toNat, BitVec.setWidth_eq]

/-- The lanes written so far: the first `i` of the 32 values, in memory at `out`. -/
def Done (m : Mem) (out : BitVec 64) (k : Blake3.CV) (flags counter n : BitVec 64) (bytes : List (BitVec 8))
    (i : BitVec 64) : Prop :=
  i ≤ 32#64 ∧ Cvl.At m out ((K32.values k flags counter n bytes).take i.toNat)

namespace Done

theorem cells (h : Done m out k flags counter n bytes i) : i ≤ 32#64 := h.1

/-- **Before the loop:** no lane is written. -/
theorem start : Done m out k flags counter n bytes 0#64 := ⟨by decide, by simp [Cvl.At]⟩

theorem frame (h : Done m out k flags counter n bytes i) (same : ∀ x : BitVec 64, x - out < i <<< 5 → m' x = m x) :
    Done m' out k flags counter n bytes i := by
  obtain ⟨hi, hw⟩ := h
  have i32 : i.toNat ≤ 32 := hi
  have ed : (i <<< 5).toNat = 32 * i.toNat := by rw [BitVec.toNat_shiftLeft, Nat.shiftLeft_eq]; omega
  refine ⟨hi, Cvl.At.frame _ out (by rw [List.length_take]; omega) (fun x hx => same x ?_) hw⟩
  rw [List.length_take, values_length, Nat.min_eq_left i32] at hx
  show (x - out).toNat < (i <<< 5).toNat
  rw [ed]; exact hx

/-- **Across a turn:** the lane written is its chunk's chaining value. -/
theorem step {packed : BitVec 64} (h : Done m out k flags counter n bytes i) (hc : i < 32#64)
    (hv : Cv.At m (out + i <<< 5)
      (Node.out (Chunk.node k (packed &&& 255#64) (counter + i) (K32.input n bytes i.toNat)) ⟨BitVec.setWidth 32 0#64⟩))
    (hpk : packed = flags ||| 0x40020100#64) (hf : flags < 256#64) :
    Done m out k flags counter n bytes (i + 1#64) := by
  obtain ⟨hi, hw⟩ := h
  have i32 : i.toNat < 32 := hc
  have ed : (i <<< 5).toNat = 32 * i.toNat := by rw [BitVec.toNat_shiftLeft, Nat.shiftLeft_eq]; omega
  have ei : (i + 1#64).toNat = i.toNat + 1 := by bv_omega
  have hfl : packed &&& 255#64 = flags := by rw [hpk]; bv_decide
  rw [hfl] at hv
  have hv' := Hash.cv_of hv
  have htake : (K32.values k flags counter n bytes).take (i.toNat + 1)
      = (K32.values k flags counter n bytes).take i.toNat ++ [(Chunk.node k flags (counter + i) (K32.input n bytes i.toNat)).cv] := by
    rw [List.take_succ, values_get i32]; rfl
  have hi1 : i + 1#64 ≤ 32#64 := by
    show (i + 1#64).toNat ≤ 32
    rw [ei]; omega
  refine ⟨hi1, ?_⟩
  rw [ei, htake]
  refine Cvl.at_snoc _ out hw ?_
  have e : out + BitVec.ofNat 64 (32 * ((K32.values k flags counter n bytes).take i.toNat).length) = out + i <<< 5 := by
    rw [List.length_take, values_length, Nat.min_eq_left (by omega)]
    congr 1
    apply BitVec.eq_of_toNat_eq
    rw [BitVec.toNat_ofNat, ed]; omega
  rw [e]; exact hv'

end Done

end K32s

/-- **When the loop ends:** the 32 lanes hold what the contract says. -/
theorem K32s.exit {m : Mem} {out flags counter n i : BitVec 64} {k : Blake3.CV} {bytes : List (BitVec 8)}
    (h : K32s.Done m out k flags counter n bytes i) (hc : ¬ i < 32#64) :
    True ∧ Cvs32.At m out (K32.values k flags counter n bytes) := by
  obtain ⟨hi, hw⟩ := h
  have i32 : i.toNat = 32 := by bv_omega
  have hlen := K32s.values_length (k := k) (flags := flags) (counter := counter) (n := n) (bytes := bytes)
  rw [i32, ← hlen, List.take_length] at hw
  exact ⟨trivial, hlen, hw⟩
