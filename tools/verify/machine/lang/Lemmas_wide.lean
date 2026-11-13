import Lemmas_hashl
import Lemmas_tree32
import Spec_k32
import Spec_wide
open X86 Cells

/-! # `wide`: lemmas for the prover

Written by hand for this function; its source names them. Checked by Lean; not to be read. -/

/-- Whole chunks are in their own bytes. -/
theorem Chunks.At.frame {m m' : Mem} {n a : BitVec 64} {bytes : List (BitVec 8)} (h : Chunks.At n m a bytes)
    (same : ∀ x : BitVec 64, x - a < n <<< 10 → m' x = m x) : Chunks.At n m' a bytes := by
  obtain ⟨hn, hl, hb⟩ := h
  have hn' : n.toNat ≤ 32 := hn
  have es : (n <<< 10).toNat = 1024 * n.toNat := by rw [BitVec.toNat_shiftLeft, Nat.shiftLeft_eq]; omega
  refine ⟨hn, hl, Bytes.At.frame hb (fun x hx => same x ?_) (by rw [hl]; omega)⟩
  have e : (BitVec.ofNat 64 bytes.length).toNat = 1024 * n.toNat := by rw [BitVec.toNat_ofNat, hl]; omega
  generalize BitVec.ofNat 64 bytes.length = c at e hx
  generalize n <<< 10 = d at es
  bv_omega

namespace Wide

variable {m m' : Mem} {wl input len p rem counter flags : BitVec 64} {k : Blake3.CV} {bytes : List (BitVec 8)}

/-- The 32 chunks at the loop's place: what the chunk kernel is given. -/
def group (bytes : List (BitVec 8)) (counter : BitVec 64) : List (BitVec 8) := (bytes.drop (1024 * counter.toNat)).take 32768

/-- The levels at `wl` over the groups of the first `counter` chunks, memory first. -/
def Lv (m : Mem) (wl : BitVec 64) (k : Blake3.CV) (flags : BitVec 64) (bytes : List (BitVec 8)) (counter : BitVec 64) : Prop :=
  counter.toNat % 32 = 0 ∧ Levels.At k ⟨flags.setWidth 32⟩ m wl (Wide.units k flags bytes counter.toNat)

theorem Lv.frame (h : Lv m wl k flags bytes counter)
    (same : ∀ y : BitVec 64, y - wl < 3520#64 → m' y = m y) : Lv m' wl k flags bytes counter :=
  ⟨h.1, Levels.At.frame h.2 same⟩

/-- **Before the loop:** the count written as 0: the levels over no group. -/
theorem Lv.start (hq : Quad m wl 0#64) (hR : Region m wl 3520#64) : Lv m wl k flags bytes 0#64 := by
  refine ⟨rfl, ?_⟩
  have e : Wide.units k flags bytes (0#64).toNat = #[] := by simp [Wide.units]
  rw [e]
  exact ⟨by simp, hR, hq, fun h => absurd h (by simp)⟩

/-- **Across a turn:** 32 chunks on. -/
theorem In.step32 (h : Hash.In m input len bytes p rem counter) (hc : 32768#64 < rem) :
    Hash.In m input len bytes (p + 32768#64) (rem - 32768#64) (counter + 32#64) := by
  obtain ⟨hn, hb, hr, hp, hor⟩ := h
  have hl := len.isLt
  have hrem : 32768 < rem.toNat := hc
  refine ⟨hn, hb, ?_, by rw [hp]; bv_omega, Or.inr (by bv_omega)⟩
  have e1 : (rem - 32768#64).toNat = rem.toNat - 32768 := by bv_omega
  have e2 : (counter + 32#64).toNat = counter.toNat + 32 := by bv_omega
  rw [e1, e2]; omega

/-- **In a turn:** the 32 whole chunks at `p`, as the chunk kernel is given them. -/
theorem k32in (h : Hash.In m input len bytes p rem counter) (hc : 32768#64 < rem) :
    Chunks.At 32#64 m p (group bytes counter) := by
  obtain ⟨hn, hb, hr, hp, hor⟩ := h
  have hl := len.isLt
  have hrem : 32768 < rem.toNat := hc
  have hlen : (group bytes counter).length = 32768 := by
    unfold group; rw [List.length_take, List.length_drop]; omega
  refine ⟨by decide, by rw [hlen]; decide, ?_⟩
  intro i hi
  have hi' : 1024 * counter.toNat + i < bytes.length := by rw [hlen] at hi; omega
  have e : p + BitVec.ofNat 64 i = input + BitVec.ofNat 64 (1024 * counter.toNat + i) := by
    rw [hp]; apply BitVec.eq_of_toNat_eq
    simp only [BitVec.toNat_add, BitVec.toNat_sub, BitVec.toNat_ofNat]
    omega
  rw [e, hb _ hi']
  have hq : ((bytes.drop (1024 * counter.toNat)).take 32768)[i]? = bytes[1024 * counter.toNat + i]? := by
    rw [List.getElem?_take, List.getElem?_drop]
    simp only [ite_eq_left_iff]; intro hn'; rw [hlen] at hi; omega
  have hq2 : (group bytes counter)[i]? = some (group bytes counter)[i] := List.getElem?_eq_getElem hi
  rw [show (group bytes counter)[i]? = bytes[1024 * counter.toNat + i]? from hq, List.getElem?_eq_getElem hi'] at hq2
  exact hq2

/-- The groups of 32 chunks more. -/
theorem units_succ (c : Nat) (h : c % 32 = 0) :
    Wide.units k flags bytes (c + 32) = (Wide.units k flags bytes c).push (Wide.unit k flags bytes (c / 32)) := by
  unfold Wide.units
  rw [show (c + 32) / 32 = c / 32 + 1 by omega, Array.range_succ]
  simp

/-- Lane `i`'s chunk of the group is the message's chunk `counter + i`. -/
theorem input_chunk (counter : BitVec 64) (i : Nat) (hi : i < 32) (hc : counter.toNat + 32 < 2 ^ 64) :
    K32.input 32#64 (group bytes counter) i = Hash.chunk bytes (counter + BitVec.ofNat 64 i) := by
  have e : (counter + BitVec.ofNat 64 i).toNat = counter.toNat + i := by
    rw [BitVec.toNat_add, BitVec.toNat_ofNat]; omega
  have h32 : i < (32#64).toNat := hi
  unfold K32.input group Hash.chunk
  rw [ite_eq_left h32, e, List.drop_take, List.drop_drop, List.take_take]
  congr 1
  · omega
  · congr 1; omega

/-- **The group's value, as `tree32` makes it of the chunk kernel's 32 values, is the specification's subtree
over the group's chunks.** -/
theorem unit_value (counter : BitVec 64) (h32 : counter.toNat % 32 = 0)
    (hlen : 1024 * counter.toNat + 32768 < bytes.length) (hb : bytes.length < 2 ^ 64) :
    Tree32.value k flags (K32.values k flags counter 32#64 (group bytes counter))
      = (Wide.unit k flags bytes (counter.toNat / 32)).cv := by
  have hN : ((max 1 ((bytes.length + 1023) / 1024) : Nat)) < 2 ^ 64 := by omega
  have hall := Hash.nodes_all k flags bytes (BitVec.ofNat 64 (max 1 ((bytes.length + 1023) / 1024)))
    (by rw [BitVec.toNat_ofNat]; omega)
  have hvals : K32.values k flags counter 32#64 (group bytes counter)
      = (List.range 32).map fun i => ((Wide.nodes k flags bytes)[counter.toNat + i]!).cv := by
    unfold K32.values
    apply List.map_congr_left
    intro i hi
    have hi32 : i < 32 := List.mem_range.mp hi
    have e : (counter + BitVec.ofNat 64 i).toNat = counter.toNat + i := by
      rw [BitVec.toNat_add, BitVec.toNat_ofNat]; omega
    rw [input_chunk counter i hi32 (by omega)]
    have hin : counter.toNat + i < max 1 ((bytes.length + 1023) / 1024) := by omega
    have hget : (Wide.nodes k flags bytes)[counter.toNat + i]!
        = Chunk.node k flags (BitVec.ofNat 64 (counter.toNat + i)) (Hash.chunk bytes (BitVec.ofNat 64 (counter.toNat + i))) := by
      unfold Wide.nodes
      rw [← hall]
      unfold Hash.nodes
      rw [getElem!_pos _ _ (by simp only [Array.size_map, Array.size_range, BitVec.toNat_ofNat]; omega)]
      simp only [Array.getElem_map, Array.getElem_range]
    rw [hget]
    have ec : counter + BitVec.ofNat 64 i = BitVec.ofNat 64 (counter.toNat + i) := by
      apply BitVec.eq_of_toNat_eq; rw [e, BitVec.toNat_ofNat]; omega
    rw [ec]
  unfold Tree32.value Wide.unit
  rw [hvals, Blake3.level5 k ⟨flags.setWidth 32⟩ (Wide.nodes k flags bytes) counter.toNat]
  show Blake3.sub k ⟨flags.setWidth 32⟩ (Wide.nodes k flags bytes) counter.toNat 32 = _
  rw [show 32 * (counter.toNat / 32) = counter.toNat by omega]
  rfl

/-- **Before `ladd`:** the group's value is at `res`; the levels have room. -/
theorem unit_cv {res : BitVec 64} (hin : Hash.In m input len bytes p rem counter) (hc : 32768#64 < rem) (hlv : Lv m' wl k flags bytes counter)
    (h : Cvs16.At m' res (List.replicate 16 (Tree32.value k flags (K32.values k flags counter 32#64 (group bytes counter))))) :
    Cv.At m' res (Wide.unit k flags bytes (counter.toNat / 32)).cv ∧
      Levels.At k ⟨flags.setWidth 32⟩ m' wl (Wide.units k flags bytes counter.toNat) ∧
      (Wide.units k flags bytes counter.toNat).size < 2 ^ 54 := by
  obtain ⟨hn, hb, hr, hp, hor⟩ := hin
  have hl := len.isLt
  have hrem : 32768 < rem.toNat := hc
  refine ⟨?_, hlv.2, ?_⟩
  · rw [← unit_value counter hlv.1 (by omega) (by omega)]
    exact h.2.1
  · simp only [Wide.units, Array.size_map, Array.size_range]; omega

/-- **Across a turn:** the levels over one group more. -/
theorem Lv.step {m2 : Mem} (hin : Hash.In m input len bytes p rem counter) (hc : 32768#64 < rem) (hlv : Lv m2 wl k flags bytes counter)
    (h : Levels.At k ⟨flags.setWidth 32⟩ m' wl ((Wide.units k flags bytes counter.toNat).push (Wide.unit k flags bytes (counter.toNat / 32)))) :
    Lv m' wl k flags bytes (counter + 32#64) := by
  obtain ⟨hn, hb, hr, hp, hor⟩ := hin
  have hl := len.isLt
  have hrem : 32768 < rem.toNat := hc
  have e : (counter + 32#64).toNat = counter.toNat + 32 := by bv_omega
  refine ⟨by rw [e]; have := hlv.1; omega, ?_⟩
  rw [e, units_succ counter.toNat hlv.1]
  exact h

end Wide

/-- **When the loop ends:** the levels over all the groups but the last; their chunks' count. -/
theorem Wide.exit {m : Mem} {wl input len p rem counter flags : BitVec 64} {k : Blake3.CV} {bytes : List (BitVec 8)}
    (hin : Hash.In m input len bytes p rem counter) (hlv : Wide.Lv m wl k flags bytes counter) (hc : ¬ 32768#64 < rem) :
    counter.toNat = Wide.count bytes.length ∧
      Levels.At k ⟨flags.setWidth 32⟩ m wl (Wide.units k flags bytes (Wide.count bytes.length)) := by
  obtain ⟨hn, hb, hr, hp, hor⟩ := hin
  have hrem : rem.toNat ≤ 32768 := by simpa [BitVec.lt_def] using hc
  have h32 := hlv.1
  have hcount : counter.toNat = Wide.count bytes.length := by
    unfold Wide.count
    rcases hor with h0 | hpos
    · subst h0
      simp at hr ⊢
      omega
    · have hp' : 0 < rem.toNat := hpos
      omega
  exact ⟨hcount, hcount ▸ hlv.2⟩
