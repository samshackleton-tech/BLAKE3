import Lemmas_hashl
import Lemmas_wide
import Lemmas_group
import Lemmas_finish
import Spec_hashw
open X86 Cells

/-! # `hashw`: lemmas for the prover

Written by hand for this function; its source names them. The tree's part is `Blake3.tree_groups`
(`../alg/Groups.lean`). Checked by Lean; not to be read. -/

namespace Hashw

variable {m m' : Mem} {out input len key flags rax : BitVec 64} {k : Blake3.CV} {bytes : List (BitVec 8)}

/-- The bytes `wide` leaves: the last group's. -/
abbrev rest (bytes : List (BitVec 8)) : List (BitVec 8) := bytes.drop (1024 * Wide.count bytes.length)

/-- The groups `wide` leaves in its levels. -/
abbrev units (k : Blake3.CV) (flags : BitVec 64) (bytes : List (BitVec 8)) : Array Blake3.Node :=
  Wide.units k flags bytes (Wide.count bytes.length)

/-- At entry: the message, in the form the calls keep it (`hashl`'s, with nothing done yet). -/
theorem msg (hb : Bytes.At m input bytes) (hn : len.toNat = bytes.length) :
    Hash.In m input len bytes input len 0#64 ∧ len = BitVec.ofNat 64 bytes.length ∧ bytes.length < 2 ^ 64 :=
  ⟨⟨hn, hb, by simp [hn], by simp, Or.inl rfl⟩, by apply BitVec.eq_of_toNat_eq; rw [hn, BitVec.toNat_ofNat]; have := len.isLt; omega,
    by have := len.isLt; omega⟩

theorem count_le (n : Nat) : 1024 * Wide.count n ≤ n := by unfold Wide.count; omega

/-- **Before `group`:** the last group's bytes are where `wide`'s count says, and so many. -/
theorem tailin (hin : Hash.In m input len bytes input len 0#64) (hr : rax.toNat = Wide.count bytes.length) :
    (len - rax <<< 10).toNat = (rest bytes).length ∧ Bytes.At m (input + rax <<< 10) (rest bytes) ∧
      BitVec.ofNat 64 (rest bytes).length = len - rax <<< 10 ∧ rax <<< 10 ≤ len ∧ len = BitVec.ofNat 64 bytes.length ∧
      (rest bytes).length < 2 ^ 64 ∧ len - rax <<< 10 ≤ 32768#64 ∧ (1024#64 < len → 0#64 < len - rax <<< 10) := by
  obtain ⟨hn, hb, _, _, _⟩ := hin
  have hl := len.isLt
  have hc := count_le bytes.length
  have es : (rax <<< 10).toNat = 1024 * Wide.count bytes.length := by
    rw [BitVec.toNat_shiftLeft, Nat.shiftLeft_eq, hr]; omega
  have hlen : (rest bytes).length = bytes.length - 1024 * Wide.count bytes.length := by simp [rest]
  have e1 : (len - rax <<< 10).toNat = (rest bytes).length := by
    rw [hlen, BitVec.toNat_sub, es, hn]; omega
  refine ⟨e1, ?_, ?_, ?_, ?_, by rw [hlen]; omega, ?_, ?_⟩
  rotate_right 2
  · show (len - rax <<< 10).toNat ≤ 32768
    rw [e1, hlen]; unfold Wide.count; omega
  · intro h
    have h' : 1024 < len.toNat := h
    show 0 < (len - rax <<< 10).toNat
    rw [e1, hlen]; unfold Wide.count; omega
  · intro i hi
    have hi' : 1024 * Wide.count bytes.length + i < bytes.length := by rw [hlen] at hi; omega
    have e : input + rax <<< 10 + BitVec.ofNat 64 i = input + BitVec.ofNat 64 (1024 * Wide.count bytes.length + i) := by
      apply BitVec.eq_of_toNat_eq
      simp only [BitVec.toNat_add, BitVec.toNat_ofNat, es]
      omega
    rw [e, hb _ hi']
    simp [rest, List.getElem_drop]
  · apply BitVec.eq_of_toNat_eq; rw [e1, BitVec.toNat_ofNat]; omega
  · show (rax <<< 10).toNat ≤ len.toNat
    rw [es, hn]; exact hc
  · apply BitVec.eq_of_toNat_eq; rw [hn, BitVec.toNat_ofNat]; omega

/-- The last group's nodes are the message's chunks from `wide`'s count on. -/
theorem tail_get (hr : rax.toNat = Wide.count bytes.length) (hb : bytes.length < 2 ^ 64) (i : Nat)
    (hi : Wide.count bytes.length + i < max 1 ((bytes.length + 1023) / 1024)) :
    (Group.nodes k flags rax (rest bytes))[i]! = (Wide.nodes k flags bytes)[Wide.count bytes.length + i]! := by
  have hc := count_le bytes.length
  have hlen : (rest bytes).length = bytes.length - 1024 * Wide.count bytes.length := by simp [rest]
  have hN : (max 1 ((bytes.length + 1023) / 1024) : Nat) < 2 ^ 64 := by omega
  have hall := Hash.nodes_all k flags bytes (BitVec.ofNat 64 (max 1 ((bytes.length + 1023) / 1024)))
    (by rw [BitVec.toNat_ofNat]; omega)
  have hi2 : i < max 1 (((rest bytes).length + 1023) / 1024) := by rw [hlen]; omega
  unfold Group.nodes Wide.nodes
  rw [← hall]
  unfold Hash.nodes
  rw [getElem!_pos _ _ (by simp only [Array.size_map, Array.size_range]; exact hi2),
      getElem!_pos _ _ (by simp only [Array.size_map, Array.size_range, BitVec.toNat_ofNat]; omega)]
  simp only [Array.getElem_map, Array.getElem_range]
  have ec : rax + BitVec.ofNat 64 i = BitVec.ofNat 64 (Wide.count bytes.length + i) := by
    apply BitVec.eq_of_toNat_eq
    rw [BitVec.toNat_add, BitVec.toNat_ofNat, BitVec.toNat_ofNat, hr]; omega
  have et : (BitVec.ofNat 64 (Wide.count bytes.length + i)).toNat = Wide.count bytes.length + i := by
    rw [BitVec.toNat_ofNat]; omega
  rw [ec]
  unfold Hash.chunk
  rw [et, show rest bytes = bytes.drop (1024 * Wide.count bytes.length) from rfl, List.drop_drop,
      show 1024 * Wide.count bytes.length + 1024 * i = 1024 * (Wide.count bytes.length + i) by omega]

theorem tail_size (hb : 1 ≤ bytes.length) :
    (Group.nodes k flags rax (rest bytes)).size = max 1 ((bytes.length + 1023) / 1024) - Wide.count bytes.length ∧
    1 ≤ max 1 ((bytes.length + 1023) / 1024) - Wide.count bytes.length ∧
    max 1 ((bytes.length + 1023) / 1024) - Wide.count bytes.length ≤ 32 := by
  have hlen : (rest bytes).length = bytes.length - 1024 * Wide.count bytes.length := by simp [rest]
  have hc : Wide.count bytes.length = 32 * ((bytes.length - 1) / 32768) := rfl
  refine ⟨?_, by omega, by omega⟩
  simp only [Group.nodes, Array.size_map, Array.size_range, hlen]
  omega

/-- **The tree over the groups' tops is the tree over the message's chunks**, so its root's output is the
hash's first eight words. -/
theorem root (hr : rax.toNat = Wide.count bytes.length) (h1 : 1 ≤ bytes.length) (hb : bytes.length < 2 ^ 64) :
    Levels.top k ⟨flags.setWidth 32⟩
        (Finish.tops k ⟨flags.setWidth 32⟩ (Wide.units k flags bytes (Wide.count bytes.length)) (Group.nodes k flags rax (rest bytes)))
        ⟨BitVec.setWidth 32 8#64⟩
      = Hash.words k flags bytes := by
  obtain ⟨hts, hj1, hj32⟩ := tail_size (k := k) (flags := flags) (rax := rax) h1
  have hc : Wide.count bytes.length = 32 * ((bytes.length - 1) / 32768) := rfl
  have hNsize : (Wide.nodes k flags bytes).size = max 1 ((bytes.length + 1023) / 1024) := by
    simp [Wide.nodes, Blake3.chunksOf, Blake3.ofBytes_size]
  have htree : Blake3.tree k ⟨flags.setWidth 32⟩
      (Finish.tops k ⟨flags.setWidth 32⟩ (Wide.units k flags bytes (Wide.count bytes.length)) (Group.nodes k flags rax (rest bytes)))
      = Blake3.tree k ⟨flags.setWidth 32⟩ (Wide.nodes k flags bytes) := by
    have husize : (Wide.units k flags bytes (Wide.count bytes.length)).size = (bytes.length - 1) / 32768 := by
      simp only [Wide.units, Array.size_map, Array.size_range, hc]; omega
    by_cases hu : (Wide.units k flags bytes (Wide.count bytes.length)).size = 0
    · -- no whole group: the last group is all the chunks
      have hc0 : Wide.count bytes.length = 0 := by omega
      simp only [Finish.tops, hu, if_true]
      congr 1
      apply Array.ext
      · rw [hts, hNsize, hc0]; rfl
      · intro i hi1 hi2
        have := tail_get (k := k) (flags := flags) hr hb i (by rw [hts] at hi1; omega)
        rw [hc0, Nat.zero_add, getElem!_pos (Group.nodes k flags rax (rest bytes)) i hi1,
            getElem!_pos (Wide.nodes k flags bytes) i hi2] at this
        exact this
    · simp only [Finish.tops, hu, if_false]
      symm
      refine Blake3.tree_groups k ⟨flags.setWidth 32⟩ (Wide.nodes k flags bytes) 5
        (max 1 ((bytes.length + 1023) / 1024) - Wide.count bytes.length) ((bytes.length - 1) / 32768 + 1)
        (by omega) hj1 hj32 _ ?_ ?_ ?_
      · rw [hNsize]; omega
      · rw [Array.size_push, husize]
      · intro g hg
        by_cases hlast : g + 1 < (bytes.length - 1) / 32768 + 1
        · -- a whole group: its own top
          simp only [hlast, if_true]
          rw [getElem!_pos _ _ (by rw [Array.size_push, husize]; omega), Array.getElem_push_lt (by rw [husize]; omega)]
          simp only [Wide.units, Array.getElem_map, Array.getElem_range, Wide.unit]
          rw [Nat.mul_comm]
        · -- the last group: the tree over its chunks
          have hg' : g = (bytes.length - 1) / 32768 := by omega
          simp only [hlast, if_false]
          rw [getElem!_pos _ _ (by rw [Array.size_push, husize]; omega)]
          have hidx : g = (Wide.units k flags bytes (Wide.count bytes.length)).size := by rw [husize]; exact hg'
          rw [show (Array.push (Wide.units k flags bytes (Wide.count bytes.length))
                (Blake3.tree k ⟨flags.setWidth 32⟩ (Group.nodes k flags rax (rest bytes))))[g]'(by rw [Array.size_push, husize]; omega)
              = Blake3.tree k ⟨flags.setWidth 32⟩ (Group.nodes k flags rax (rest bytes)) from by
            subst hidx; exact Array.getElem_push_eq]
          unfold Blake3.tree
          rw [hts]
          have := Blake3.go_congr k ⟨flags.setWidth 32⟩ (Wide.nodes k flags bytes) (Group.nodes k flags rax (rest bytes))
            (g * 2 ^ 5) 0 (max 1 ((bytes.length + 1023) / 1024) - Wide.count bytes.length) 0 hj1 (fun i hi => by
              have h2 := tail_get (k := k) (flags := flags) hr hb i (by omega)
              have e : g * 2 ^ 5 + 0 + i = Wide.count bytes.length + i := by rw [hc, hg']; omega
              rw [e]
              simpa using h2.symm)
          rw [Nat.add_zero, Nat.zero_add] at this
          exact this.symm
  unfold Levels.top Hash.words Blake3.rootWords
  rw [htree]
  rfl

variable {lv wl : BitVec 64}

/-- **No whole group** (`wide` took nothing): `finish`'s first case, and the root is the hash's. -/
theorem way0 (_hk : Cv.At m key k) (_hf : flags < 256#64) (hr : rax.toNat = Wide.count bytes.length) (h0 : rax = 0#64) (hlen : 1024#64 < len) (hn : len.toNat = bytes.length) :
    Finish.way 0#64 (Wide.units k flags bytes (Wide.count bytes.length)) (Group.nodes k flags rax (rest bytes)) ∧
    (Wide.units k flags bytes (Wide.count bytes.length)).size < 2 ^ 54 ∧
    Levels.top k ⟨flags.setWidth 32⟩
        (Finish.tops k ⟨flags.setWidth 32⟩ (Wide.units k flags bytes (Wide.count bytes.length)) (Group.nodes k flags rax (rest bytes)))
        ⟨BitVec.setWidth 32 8#64⟩ = Hash.words k flags bytes := by
  have hl := len.isLt
  have h1024 : 1024 < bytes.length := by rw [← hn]; exact hlen
  have hc0 : Wide.count bytes.length = 0 := by rw [← hr, h0]; rfl
  have husize : (Wide.units k flags bytes (Wide.count bytes.length)).size = 0 := by simp [Wide.units, hc0]
  obtain ⟨hts, _, _⟩ := tail_size (k := k) (flags := flags) (rax := rax) (bytes := bytes) (by omega)
  exact ⟨Or.inl ⟨rfl, husize, by rw [hts, hc0]; omega⟩, by rw [husize]; decide, root hr (by omega) (by omega)⟩

/-- **Whole groups, and a last group of one chunk.** -/
theorem way1 (_hk : Cv.At m key k) (_hf : flags < 256#64) (hr : rax.toNat = Wide.count bytes.length) (h0 : ¬ rax = 0#64) (hrem : ¬ 1024#64 < len - rax <<< 10)
    (hlen : 1024#64 < len) (hn : len.toNat = bytes.length) :
    Finish.way 1#64 (Wide.units k flags bytes (Wide.count bytes.length)) (Group.nodes k flags rax (rest bytes)) ∧
    (Wide.units k flags bytes (Wide.count bytes.length)).size < 2 ^ 54 ∧
    Levels.top k ⟨flags.setWidth 32⟩
        (Finish.tops k ⟨flags.setWidth 32⟩ (Wide.units k flags bytes (Wide.count bytes.length)) (Group.nodes k flags rax (rest bytes)))
        ⟨BitVec.setWidth 32 8#64⟩ = Hash.words k flags bytes := by
  have hl := len.isLt
  have h1024 : 1024 < bytes.length := by rw [← hn]; exact hlen
  have hc := count_le bytes.length
  have hcpos : 0 < Wide.count bytes.length := by
    rcases Nat.eq_zero_or_pos (Wide.count bytes.length) with h | h
    · exact absurd (BitVec.eq_of_toNat_eq (by rw [hr, h]; rfl)) h0
    · exact h
  have es : (rax <<< 10).toNat = 1024 * Wide.count bytes.length := by
    rw [BitVec.toNat_shiftLeft, Nat.shiftLeft_eq, hr]; omega
  have hrem' : bytes.length - 1024 * Wide.count bytes.length ≤ 1024 := by
    have : (len - rax <<< 10).toNat ≤ 1024 := by simpa [BitVec.lt_def] using hrem
    rw [BitVec.toNat_sub, es, hn] at this; omega
  have husize : (Wide.units k flags bytes (Wide.count bytes.length)).size = Wide.count bytes.length / 32 := by
    simp [Wide.units]
  have hcdef : Wide.count bytes.length = 32 * ((bytes.length - 1) / 32768) := rfl
  obtain ⟨hts, _, _⟩ := tail_size (k := k) (flags := flags) (rax := rax) (bytes := bytes) (by omega)
  exact ⟨Or.inr (Or.inl ⟨rfl, by rw [husize]; omega, by rw [hts]; omega⟩), by rw [husize]; omega, root hr (by omega) (by omega)⟩

/-- **Whole groups, and a last group of two chunks or more.** -/
theorem way2 (_hk : Cv.At m key k) (_hf : flags < 256#64) (hr : rax.toNat = Wide.count bytes.length) (h0 : ¬ rax = 0#64) (hrem : 1024#64 < len - rax <<< 10)
    (hlen : 1024#64 < len) (hn : len.toNat = bytes.length) :
    Finish.way 2#64 (Wide.units k flags bytes (Wide.count bytes.length)) (Group.nodes k flags rax (rest bytes)) ∧
    (Wide.units k flags bytes (Wide.count bytes.length)).size < 2 ^ 54 ∧
    Levels.top k ⟨flags.setWidth 32⟩
        (Finish.tops k ⟨flags.setWidth 32⟩ (Wide.units k flags bytes (Wide.count bytes.length)) (Group.nodes k flags rax (rest bytes)))
        ⟨BitVec.setWidth 32 8#64⟩ = Hash.words k flags bytes := by
  have hl := len.isLt
  have h1024 : 1024 < bytes.length := by rw [← hn]; exact hlen
  have hc := count_le bytes.length
  have hcpos : 0 < Wide.count bytes.length := by
    rcases Nat.eq_zero_or_pos (Wide.count bytes.length) with h | h
    · exact absurd (BitVec.eq_of_toNat_eq (by rw [hr, h]; rfl)) h0
    · exact h
  have es : (rax <<< 10).toNat = 1024 * Wide.count bytes.length := by
    rw [BitVec.toNat_shiftLeft, Nat.shiftLeft_eq, hr]; omega
  have hrem' : 1024 < bytes.length - 1024 * Wide.count bytes.length := by
    have : 1024 < (len - rax <<< 10).toNat := hrem
    rw [BitVec.toNat_sub, es, hn] at this; omega
  have husize : (Wide.units k flags bytes (Wide.count bytes.length)).size = Wide.count bytes.length / 32 := by
    simp [Wide.units]
  have hcdef : Wide.count bytes.length = 32 * ((bytes.length - 1) / 32768) := rfl
  obtain ⟨hts, _, _⟩ := tail_size (k := k) (flags := flags) (rax := rax) (bytes := bytes) (by omega)
  exact ⟨Or.inr (Or.inr ⟨rfl, by rw [husize]; omega, by rw [hts]; omega⟩), by rw [husize]; omega, root hr (by omega) (by omega)⟩

/-- A short message goes to `hashl`, whose result is the hash's. -/
theorem same (_hk : Cv.At m key k) (_hn : len.toNat = bytes.length) (_hf : flags < 256#64) :
    Hash.words k flags bytes = Hash.words k flags bytes := rfl

end Hashw
