import Lemmas_hashl
import Lemmas_cvl
import Spec_addn
open X86 Cells

/-! # `addn`: lemmas for the prover

Written by hand for this function; its source names them. Checked by Lean; not to be read. -/

/-- At the loop's head: the first `i` of the new chunks are in the levels; `p` is where the next value is. -/
def Addn.Mid (m : Mem) (lv cvs : BitVec 64) (k : Blake3.CV) (flags : BitVec 64) (chunks : Array Blake3.Node)
    (news : List Blake3.Node) (vals : List Blake3.CV) (n i p : BitVec 64) : Prop :=
  i ≤ n ∧ n ≤ 32#64 ∧ p = cvs + i <<< 5 ∧ news.length = n.toNat ∧ news.map Blake3.Node.cv = vals.take n.toNat ∧
  chunks.size + 32 ≤ 2 ^ 54 ∧
  Levels.At k ⟨flags.setWidth 32⟩ m lv (chunks ++ (news.take i.toNat).toArray) ∧ Cvs32.At m cvs vals

namespace Addn.Mid

variable {m m' m2 : Mem} {lv cvs flags n i p : BitVec 64} {k : Blake3.CV} {chunks : Array Blake3.Node}
  {news : List Blake3.Node} {vals : List Blake3.CV}

/-- What its holder may use at once, in the words a proof of apartness speaks. -/
theorem cells (h : Addn.Mid m lv cvs k flags chunks news vals n i p) : i ≤ n ∧ n ≤ 32#64 ∧ p = cvs + i <<< 5 :=
  ⟨h.1, h.2.1, h.2.2.1⟩

/-- **Before the loop.** -/
theorem start (hl : Levels.At k ⟨flags.setWidth 32⟩ m lv chunks) (hv : Cvs32.At m cvs vals)
    (hlen : news.length = n.toNat) (hn : n ≤ 32#64) (hmap : news.map Blake3.Node.cv = vals.take n.toNat)
    (hsize : chunks.size + 32 ≤ 2 ^ 54)
    (sameL : ∀ y : BitVec 64, y - lv < 3520#64 → m' y = m y) (sameV : ∀ x : BitVec 64, x - cvs < 1024#64 → m' x = m x) :
    Addn.Mid m' lv cvs k flags chunks news vals n 0#64 cvs := by
  refine ⟨by bv_omega, hn, by simp, hlen, hmap, hsize, ?_, Cvs32.At.frame hv sameV⟩
  simpa using Levels.At.frame hl sameL

theorem Cvl.at_get {m : Mem} : ∀ (l : List Blake3.CV) (a : BitVec 64) (j : Nat) (hj : j < l.length), Cvl.At m a l →
    32 * l.length < 2 ^ 64 → Cv.At m (a + BitVec.ofNat 64 (32 * j)) l[j] := by
  intro l
  induction l with
  | nil => intro a j hj; exact absurd hj (by simp)
  | cons cv rest ih =>
    intro a j hj h hl
    cases j with
    | zero => simpa using h.1
    | succ j =>
      simp only [List.length_cons] at hj hl
      have := ih (a + 32#64) j (by omega) h.2 (by omega)
      simp only [List.getElem_cons_succ]
      have e : a + BitVec.ofNat 64 (32 * (j + 1)) = a + 32#64 + BitVec.ofNat 64 (32 * j) := by
        apply BitVec.eq_of_toNat_eq
        simp only [BitVec.toNat_add, BitVec.toNat_ofNat]
        omega
      rw [e]; exact this

/-- **Before `ladd`:** the next chunk's value is at `p`; the levels are over the chunks so far, and have room. -/
theorem next (h : Addn.Mid m lv cvs k flags chunks news vals n i p) (hc : i < n) :
    Cv.At m p (news.getD i.toNat default).cv ∧
      Levels.At k ⟨flags.setWidth 32⟩ m lv (chunks ++ (news.take i.toNat).toArray) ∧
      (chunks ++ (news.take i.toNat).toArray).size < 2 ^ 54 ∧ Cvs32.At m cvs vals := by
  obtain ⟨hi, hn, hp, hlen, hmap, hsize, hl, hv⟩ := h
  have hin : i.toNat < n.toNat := hc
  have hn32 : n.toNat ≤ 32 := hn
  refine ⟨?_, hl, ?_, hv⟩
  · have hj : i.toNat < vals.length := by rw [hv.1]; omega
    have hget := Cvl.at_get vals cvs i.toNat hj hv.2 (by rw [hv.1]; decide)
    have ea : cvs + BitVec.ofNat 64 (32 * i.toNat) = p := by
      rw [hp]; congr 1
      apply BitVec.eq_of_toNat_eq
      rw [BitVec.toNat_ofNat, BitVec.toNat_shiftLeft, Nat.shiftLeft_eq]
      omega
    rw [ea] at hget
    have hval : vals[i.toNat] = (news.getD i.toNat default).cv := by
      have h1 : (news.map Blake3.Node.cv)[i.toNat]? = (vals.take n.toNat)[i.toNat]? := by rw [hmap]
      rw [List.getElem?_map, List.getElem?_take, if_pos hin, List.getElem?_eq_getElem hj,
          List.getElem?_eq_getElem (by rw [hlen]; exact hin)] at h1
      simp only [Option.map_some, Option.some.injEq] at h1
      rw [← h1, List.getD_eq_getElem?_getD, List.getElem?_eq_getElem (by rw [hlen]; exact hin)]
      rfl
    rw [← hval]; exact hget
  · simp only [Array.size_append, List.size_toArray, List.length_take]; omega

/-- **Across a turn:** the levels over one chunk more. -/
theorem step (h : Addn.Mid m lv cvs k flags chunks news vals n i p) (hc : i < n)
    (hl' : Levels.At k ⟨flags.setWidth 32⟩ m' lv ((chunks ++ (news.take i.toNat).toArray).push (news.getD i.toNat default)))
    (hv' : Cvs32.At m' cvs vals) :
    Addn.Mid m' lv cvs k flags chunks news vals n (i + 1#64) (p + 32#64) := by
  obtain ⟨hi, hn, hp, hlen, hmap, hsize, hl, hv⟩ := h
  have hin : i.toNat < n.toNat := hc
  have hn32 : n.toNat ≤ 32 := hn
  have e : (i + 1#64).toNat = i.toNat + 1 := by bv_omega
  refine ⟨by bv_omega, hn, by rw [hp]; bv_omega, hlen, hmap, hsize, ?_, hv'⟩
  have hpush : (chunks ++ (news.take i.toNat).toArray).push (news.getD i.toNat default)
      = chunks ++ (news.take (i + 1#64).toNat).toArray := by
    rw [e, List.take_succ, List.getD_eq_getElem?_getD, List.getElem?_eq_getElem (by rw [hlen]; exact hin)]
    simp
  rw [← hpush]; exact hl'

end Addn.Mid

/-- **When the loop ends:** the levels over the chunks and all the new ones. -/
theorem Addn.exit {m : Mem} {lv cvs flags n i p : BitVec 64} {k : Blake3.CV} {chunks : Array Blake3.Node}
    {news : List Blake3.Node} {vals : List Blake3.CV}
    (h : Addn.Mid m lv cvs k flags chunks news vals n i p) (hc : ¬ i < n) :
    True ∧ Levels.At k ⟨flags.setWidth 32⟩ m lv (chunks ++ news.toArray) := by
  obtain ⟨hi, hn, hp, hlen, hmap, hsize, hl, hv⟩ := h
  have e : i.toNat = n.toNat := by
    have h1 : i.toNat ≤ n.toNat := hi
    have h2 : ¬ i.toNat < n.toNat := hc
    omega
  rw [e, ← hlen, List.take_length] at hl
  exact ⟨trivial, hl⟩
