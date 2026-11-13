import Lemmas_hashl
import Spec_group
open X86 Cells

/-! # `group`: lemmas for the prover

Written by hand for this function; its source names them (with `hashl`'s, whose loop this is with the chunks
numbered from `c0`). Checked by Lean; not to be read. -/

namespace Group

variable {m m' : Mem} {lv input len p rem counter flags c0 : BitVec 64} {k : Blake3.CV} {bytes : List (BitVec 8)}

/-- The nodes of the first `c` chunks, numbered from `c0`. -/
def nodesTo (k : Blake3.CV) (flags c0 : BitVec 64) (bytes : List (BitVec 8)) (c : BitVec 64) : Array Blake3.Node :=
  (Array.range c.toNat).map fun i => Chunk.node k flags (c0 + BitVec.ofNat 64 i) (Hash.chunk bytes (BitVec.ofNat 64 i))

theorem nodesTo_size (c : BitVec 64) : (nodesTo k flags c0 bytes c).size = c.toNat := by simp [nodesTo]

theorem nodesTo_zero : nodesTo k flags c0 bytes 0#64 = #[] := by simp [nodesTo]

theorem nodesTo_succ (c : BitVec 64) (hc : c.toNat + 1 < 2 ^ 64) :
    nodesTo k flags c0 bytes (c + 1#64) = (nodesTo k flags c0 bytes c).push (Chunk.node k flags (c0 + c) (Hash.chunk bytes c)) := by
  have e : (c + 1#64).toNat = c.toNat + 1 := by bv_omega
  unfold nodesTo
  rw [e, Array.range_succ]
  simp [BitVec.ofNat_toNat]

/-- **Before the loop:** the count written as 0: the levels over no chunk. -/
theorem Lv.start (hq : Quad m lv 0#64) (hR : Region m lv 3520#64) : Hash.Lv m lv k flags (nodesTo k flags c0 bytes 0#64) := by
  rw [nodesTo_zero]
  exact ⟨by simp, hR, hq, fun h => absurd h (by simp)⟩

/-- **Across a turn:** the levels over one chunk more. -/
theorem Lv.step
    (h : Levels.At k ⟨flags.setWidth 32⟩ m lv ((nodesTo k flags c0 bytes counter).push (Chunk.node k flags (c0 + counter) (Hash.chunk bytes counter)))) :
    Hash.Lv m lv k flags (nodesTo k flags c0 bytes (counter + 1#64)) := by
  have hs := h.1
  rw [Array.size_push, nodesTo_size] at hs
  rw [nodesTo_succ counter (by omega)]
  exact h

/-- **In a turn:** what the three calls are given. -/
theorem turn (hin : Hash.In m input len bytes p rem counter) (hlv : Hash.Lv m lv k flags (nodesTo k flags c0 bytes counter))
    (hc : 1024#64 < rem) :
    ∃ _u : Unit, Bytes.At m p (Hash.chunk bytes counter) ∧ (Hash.chunk bytes counter).length < 2 ^ 64 ∧
      1024 = (Hash.chunk bytes counter).length ∧ (1024#64).toNat = (Hash.chunk bytes counter).length ∧
      (Hash.chunk bytes counter).length ≤ 1024 ∧ (nodesTo k flags c0 bytes counter).size < 2 ^ 54 ∧
      BitVec.ofNat 64 (Hash.chunk bytes counter).length = 1024#64 := by
  have hrem : 1024 < rem.toNat := hc
  obtain ⟨hb, hlt, hlen⟩ := Hash.In.here hin
  have e : (Hash.chunk bytes counter).length = 1024 := by rw [hlen]; omega
  refine ⟨(), hb, hlt, e.symm, by rw [e]; rfl, by omega, ?_, by rw [e]⟩
  rw [nodesTo_size]; exact Hash.counter_small hin (by omega)

/-- **After the loop:** the last chunk, and what the calls are given. -/
theorem last (hin : Hash.In m input len bytes p rem counter) (hc : ¬ 1024#64 < rem) :
    ∃ _u : Unit, Bytes.At m p (Hash.chunk bytes counter) ∧ (Hash.chunk bytes counter).length < 2 ^ 64 ∧
      rem.toNat = (Hash.chunk bytes counter).length ∧ (Hash.chunk bytes counter).length ≤ 1024 ∧
      BitVec.ofNat 64 (Hash.chunk bytes counter).length = rem := by
  have hrem : rem.toNat ≤ 1024 := by simpa [BitVec.lt_def] using hc
  obtain ⟨hb, hlt, hlen⟩ := Hash.In.here hin
  have e : (Hash.chunk bytes counter).length = rem.toNat := by rw [hlen]; omega
  exact ⟨(), hb, hlt, e.symm, by omega, by rw [e, BitVec.ofNat_toNat, BitVec.setWidth_eq]⟩

/-- After the loop: the levels have room for the last chunk, and with it they are over all the chunks. -/
theorem all (hin : Hash.In m input len bytes p rem counter) (hlv : Hash.Lv m lv k flags (nodesTo k flags c0 bytes counter))
    (hc : ¬ 1024#64 < rem) :
    (nodesTo k flags c0 bytes counter).size < 2 ^ 54 ∧
    (nodesTo k flags c0 bytes counter).push (Chunk.node k flags (c0 + counter) (Hash.chunk bytes counter))
      = Group.nodes k flags c0 bytes := by
  have hrem : rem.toNat ≤ 1024 := by simpa [BitVec.lt_def] using hc
  obtain ⟨hn, _, hr, _, hor⟩ := hin
  have hl := len.isLt
  have hsmall : counter.toNat < 2 ^ 54 := by
    rcases hor with h0 | h0
    · subst h0; decide
    · have hp : 0 < rem.toNat := h0
      omega
  refine ⟨by rw [nodesTo_size]; exact hsmall, ?_⟩
  rw [← nodesTo_succ counter (by omega)]
  have e : (counter + 1#64).toNat = max 1 ((bytes.length + 1023) / 1024) := by
    have e1 : (counter + 1#64).toNat = counter.toNat + 1 := by bv_omega
    rw [e1]
    rcases hor with h0 | h0
    · subst h0; simp at hr ⊢; omega
    · have hp : 0 < rem.toNat := h0
      omega
  unfold nodesTo Group.nodes
  rw [e]
  apply Array.ext
  · simp
  · intro i h1 h2
    simp only [Array.getElem_map, Array.getElem_range]
    have hi : i < max 1 ((bytes.length + 1023) / 1024) := by simpa using h1
    have ei : (BitVec.ofNat 64 i).toNat = i := by rw [BitVec.toNat_ofNat]; omega
    unfold Hash.chunk
    rw [ei]

end Group

/-- **At the return:** the levels over all the chunks. -/
theorem Group.exit {m : Mem} {lv flags c0 : BitVec 64} {k : Blake3.CV} {bytes : List (BitVec 8)} {X : Array Blake3.Node}
    (h : Levels.At k ⟨flags.setWidth 32⟩ m lv X) (hX : X = Group.nodes k flags c0 bytes) :
    True ∧ Levels.At k ⟨flags.setWidth 32⟩ m lv (Group.nodes k flags c0 bytes) := ⟨trivial, hX ▸ h⟩
