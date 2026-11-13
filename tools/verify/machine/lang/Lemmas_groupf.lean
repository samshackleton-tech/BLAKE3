import Lemmas_group
import Lemmas_wide
import Spec_groupf
import Spec_k32
import Spec_addn
open X86 Cells

/-! # `groupf`: lemmas for the prover

Written by hand for this function; its source names them (with `group`'s). Checked by Lean; not to be read. -/

namespace Groupf

variable {m m' : Mem} {lv input len flags c0 : BitVec 64} {k : Blake3.CV} {bytes : List (BitVec 8)}

/-- The whole chunks the kernel is given: the first `w`. -/
def head (bytes : List (BitVec 8)) (w : BitVec 64) : List (BitVec 8) := bytes.take (1024 * w.toNat)

/-- Their nodes, numbered from `c0`. -/
def news (k : Blake3.CV) (flags c0 : BitVec 64) (bytes : List (BitVec 8)) (w : BitVec 64) : List Blake3.Node :=
  (List.range w.toNat).map fun i => Chunk.node k flags (c0 + BitVec.ofNat 64 i) (Hash.chunk bytes (BitVec.ofNat 64 i))

/-- The number of chunks before the last, as a number. -/
theorem w_toNat (h1 : 1024#64 < len) (h2 : len ≤ 32768#64) :
    ((len - 1#64) >>> 10).toNat = (len.toNat - 1) / 1024 ∧ 1 ≤ (len.toNat - 1) / 1024 ∧ (len.toNat - 1) / 1024 ≤ 31 ∧
    (((len - 1#64) >>> 10) <<< 10).toNat = 1024 * ((len.toNat - 1) / 1024) := by
  have a1 : 1024 < len.toNat := h1
  have a2 : len.toNat ≤ 32768 := h2
  have e0 : (len - 1#64).toNat = len.toNat - 1 := by bv_omega
  have e1 : ((len - 1#64) >>> 10).toNat = (len.toNat - 1) / 1024 := by
    rw [BitVec.toNat_ushiftRight, e0, Nat.shiftRight_eq_div_pow]
  refine ⟨e1, by omega, by omega, ?_⟩
  rw [BitVec.toNat_shiftLeft, e1, Nat.shiftLeft_eq]; omega

/-- **At entry:** the message, in the form the calls keep it. -/
theorem msg (hb : Bytes.At m input bytes) (hn : len.toNat = bytes.length) :
    Hash.In m input len bytes input len 0#64 ∧ len = BitVec.ofNat 64 bytes.length :=
  ⟨⟨hn, hb, by simp [hn], by simp, Or.inl rfl⟩, by apply BitVec.eq_of_toNat_eq; rw [hn, BitVec.toNat_ofNat]; have := len.isLt; omega⟩

/-- **Before the kernel:** the whole chunks before the last, as the kernel is given them. -/
theorem k32in (hin : Hash.In m input len bytes input len 0#64) (h1 : 1024#64 < len) (h2 : len ≤ 32768#64) :
    Chunks.At ((len - 1#64) >>> 10) m input (head bytes ((len - 1#64) >>> 10)) := by
  obtain ⟨hn, hb, _, _, _⟩ := hin
  obtain ⟨ew, w1, w31, _⟩ := w_toNat h1 h2
  have a1 : 1024 < len.toNat := h1
  have hl : (head bytes ((len - 1#64) >>> 10)).length = 1024 * ((len.toNat - 1) / 1024) := by
    unfold head; rw [List.length_take, ew]; omega
  refine ⟨?_, by rw [hl, ew], ?_⟩
  · show ((len - 1#64) >>> 10).toNat ≤ 32
    omega
  · intro i hi
    have hi' : i < bytes.length := by rw [hl] at hi; omega
    rw [hb i hi']
    simp [head, List.getElem_take]

/-- A chunk before the last, in the kernel's lane. -/
theorem lane (w : BitVec 64) (i : Nat) (hi : i < w.toNat) :
    K32.input w (head bytes w) i = Hash.chunk bytes (BitVec.ofNat 64 i) := by
  have hw := w.isLt
  have ei : (BitVec.ofNat 64 i).toNat = i := by rw [BitVec.toNat_ofNat]; omega
  unfold K32.input head Hash.chunk
  rw [if_pos hi, ei]
  apply List.ext_getElem?
  intro j
  simp only [List.getElem?_take, List.getElem?_drop]
  by_cases hj : j < 1024
  · simp only [hj, if_true]
    rw [if_pos (by have : (i + 1) * 1024 ≤ w.toNat * 1024 := Nat.mul_le_mul_right 1024 hi; omega)]
  · simp only [hj, if_false]

/-- **Before `addn`:** the kernel's first values are the nodes' in order. -/
theorem addin {m : Mem} (h1 : 1024#64 < len) (h2 : len ≤ 32768#64) :
    (news k flags c0 bytes ((len - 1#64) >>> 10)).length = ((len - 1#64) >>> 10).toNat ∧
    (news k flags c0 bytes ((len - 1#64) >>> 10)).map Blake3.Node.cv
      = (K32.values k flags c0 ((len - 1#64) >>> 10) (head bytes ((len - 1#64) >>> 10))).take ((len - 1#64) >>> 10).toNat ∧
    (#[] : Array Blake3.Node).size + 32 ≤ 2 ^ 54 ∧ (len - 1#64) >>> 10 ≤ 32#64 := by
  obtain ⟨ew, w1, w31, _⟩ := w_toNat h1 h2
  refine ⟨by simp [news], ?_, by decide, ?_⟩
  · generalize (len - 1#64) >>> 10 = w at ew
    unfold news K32.values
    rw [← List.map_take, List.take_range, Nat.min_eq_left (by omega), List.map_map]
    apply List.map_congr_left
    intro i hi
    simp only [Function.comp]
    rw [lane w i (List.mem_range.mp hi)]
  · show ((len - 1#64) >>> 10).toNat ≤ 32
    omega

/-- The nodes so far, as `group`'s loop names them. -/
theorem nodes_eq (w : BitVec 64) :
    (#[] : Array Blake3.Node) ++ (news k flags c0 bytes w).toArray = Group.nodesTo k flags c0 bytes w := by
  unfold news Group.nodesTo
  apply Array.ext
  · simp
  · intro i h1 h2
    simp

/-- **After `addn`:** the state `group`'s loop leaves, and what the last chunk's calls are given. -/
theorem after
    (hlv : Levels.At k ⟨flags.setWidth 32⟩ m lv ((#[] : Array Blake3.Node) ++ (news k flags c0 bytes ((len - 1#64) >>> 10)).toArray))
    (hin : Hash.In m input len bytes input len 0#64) (h1 : 1024#64 < len) (h2 : len ≤ 32768#64) :
    Hash.Lv m lv k flags (Group.nodesTo k flags c0 bytes ((len - 1#64) >>> 10)) ∧
    Hash.In m input len bytes (input + (((len - 1#64) >>> 10) <<< 10)) (len - (((len - 1#64) >>> 10) <<< 10)) ((len - 1#64) >>> 10) ∧
    ¬ 1024#64 < len - (((len - 1#64) >>> 10) <<< 10) ∧
    Bytes.At m (input + (((len - 1#64) >>> 10) <<< 10)) (Hash.chunk bytes ((len - 1#64) >>> 10)) ∧
    (Hash.chunk bytes ((len - 1#64) >>> 10)).length < 2 ^ 64 ∧
    (len - (((len - 1#64) >>> 10) <<< 10)).toNat = (Hash.chunk bytes ((len - 1#64) >>> 10)).length ∧
    (Hash.chunk bytes ((len - 1#64) >>> 10)).length ≤ 1024 ∧
    BitVec.ofNat 64 (Hash.chunk bytes ((len - 1#64) >>> 10)).length = len - (((len - 1#64) >>> 10) <<< 10) := by
  obtain ⟨ew, w1, w31, es⟩ := w_toNat h1 h2
  have a1 : 1024 < len.toNat := h1
  have a2 : len.toNat ≤ 32768 := h2
  have er : (len - (((len - 1#64) >>> 10) <<< 10)).toNat = len.toNat - 1024 * ((len.toNat - 1) / 1024) := by
    rw [BitVec.toNat_sub, es]; omega
  have hc : ¬ 1024#64 < len - (((len - 1#64) >>> 10) <<< 10) := by
    show ¬ 1024 < (len - (((len - 1#64) >>> 10) <<< 10)).toNat
    rw [er]; omega
  have hin' : Hash.In m input len bytes (input + (((len - 1#64) >>> 10) <<< 10)) (len - (((len - 1#64) >>> 10) <<< 10)) ((len - 1#64) >>> 10) := by
    obtain ⟨hn, hb, _, _, _⟩ := hin
    refine ⟨hn, hb, by rw [er, ew, ← hn]; omega, ?_, Or.inr ?_⟩
    · generalize ((len - 1#64) >>> 10) <<< 10 = s
      bv_omega
    · show 0 < (len - (((len - 1#64) >>> 10) <<< 10)).toNat
      rw [er]; omega
  obtain ⟨_, hb, hlt, hlen, hle, hof⟩ := Group.last hin' hc
  exact ⟨by rw [← nodes_eq]; exact hlv, hin', hc, hb, hlt, hlen, hle, hof⟩

end Groupf

/-- The levels over no chunk: a count of 0 (for `apply_intro`: what a call asks of levels just begun). -/
theorem Levels.At.intro {m : Mem} {lv : BitVec 64} {k : Blake3.CV} {f : UInt32} (hq : Quad m lv 0#64) (hR : Region m lv 3520#64) :
    Levels.At k f m lv (#[] : Array Blake3.Node) :=
  ⟨by simp, hR, hq, fun h => absurd h (by simp)⟩
