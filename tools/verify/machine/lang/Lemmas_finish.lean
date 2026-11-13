import Lemmas_hashl
import Spec_finish
open X86 Cells

/-! # `finish`: lemmas for the prover

Written by hand for this function; its source names them. Checked by Lean; not to be read. -/

namespace Finish

variable {m m' : Mem} {out wl lv key flags cv : BitVec 64} {k : Blake3.CV} {units tail : Array Blake3.Node}

/-- The groups' top nodes and the last group's only chunk. -/
abbrev w1 (units tail : Array Blake3.Node) : Array Blake3.Node := units.push (tail[0]!)
/-- The groups' top nodes and the top of the tree over the last group's chunks. -/
abbrev w2 (k : Blake3.CV) (flags : BitVec 64) (units tail : Array Blake3.Node) : Array Blake3.Node :=
  units.push (Blake3.tree k ⟨flags.setWidth 32⟩ tail)

variable {sel : BitVec 64}

/-- **No whole group:** the root is over the last group's chunks. -/
theorem none (hs : sel = 0#64) (hw : Finish.way sel units tail) (_hk : Cv.At m key k) (_hf : flags < 256#64) :
    2 ≤ tail.size ∧
    Levels.top k ⟨flags.setWidth 32⟩ tail ⟨BitVec.setWidth 32 8#64⟩
      = Levels.top k ⟨flags.setWidth 32⟩ (Finish.tops k ⟨flags.setWidth 32⟩ units tail) ⟨BitVec.setWidth 32 8#64⟩ ∧
    units = (if units.size = 0 then units else units.push (Blake3.tree k ⟨flags.setWidth 32⟩ tail)) := by
  subst hs
  rcases hw with ⟨_, hz, h2⟩ | ⟨h, _⟩ | ⟨h, _⟩
  · exact ⟨h2, by simp only [Finish.tops, hz, if_true], by simp only [hz, if_true]⟩
  · exact absurd h (by decide)
  · exact absurd h (by decide)

/-- **The last group is one chunk:** its value waits in the bottom level's first place. -/
theorem one (hs : sel = 1#64) (hw : Finish.way sel units tail) (hl : Levels.At k ⟨flags.setWidth 32⟩ m lv tail) :
    Cv.At m (lv + 64#64) (tail[0]!).cv := by
  subst hs
  have hsz : tail.size = 1 := by
    rcases hw with ⟨h, _⟩ | ⟨_, _, h1⟩ | ⟨h, _⟩
    · exact absurd h (by decide)
    · exact h1
    · exact absurd h (by decide)
  obtain ⟨hn, _, _, hrest⟩ := hl
  obtain ⟨_, hc⟩ := hrest (by omega)
  rw [hsz] at hc
  simp only [Nat.sub_self, Levels.place_even (r := 0) rfl, BitVec.add_zero] at hc
  have e : Blake3.sub k ⟨flags.setWidth 32⟩ tail 0 1 = (tail[0]!).cv := by
    unfold Blake3.sub; rw [Blake3.go_one]
  rw [e] at hc; exact hc

/-- ... and the root is over the groups' tops and that chunk. -/
theorem one_root (hs : sel = 1#64) (hw : Finish.way sel units tail) (_hk : Cv.At m key k) (_hf : flags < 256#64) :
    2 ≤ (w1 units tail).size ∧
    Levels.top k ⟨flags.setWidth 32⟩ (w1 units tail) ⟨BitVec.setWidth 32 8#64⟩
      = Levels.top k ⟨flags.setWidth 32⟩ (Finish.tops k ⟨flags.setWidth 32⟩ units tail) ⟨BitVec.setWidth 32 8#64⟩ ∧
    w1 units tail = (if units.size = 0 then units else units.push (Blake3.tree k ⟨flags.setWidth 32⟩ tail)) := by
  subst hs
  rcases hw with ⟨h, _⟩ | ⟨_, hp, hsz⟩ | ⟨h, _⟩
  · exact absurd h (by decide)
  · have ht1 : Blake3.tree k ⟨flags.setWidth 32⟩ tail = tail[0]! := Blake3.tree_one k _ tail hsz
    have hne0 : ¬ units.size = 0 := by omega
    exact ⟨by simp only [w1, Array.size_push]; omega, by simp only [Finish.tops, hne0, if_false, ht1], by simp only [hne0, if_false, ht1]⟩
  · exact absurd h (by decide)

/-- **The last group is two chunks or more, after whole groups.** -/
theorem many {m : Mem} (hs0 : ¬ sel = 0#64) (hs1 : ¬ sel = 1#64) (hw : Finish.way sel units tail) : 2 ≤ tail.size := by
  rcases hw with ⟨h, _⟩ | ⟨h, _⟩ | ⟨_, _, h2⟩
  · exact absurd h hs0
  · exact absurd h hs1
  · exact h2

/-- ... and the root is over the groups' tops and the last group's. -/
theorem many_root (hs0 : ¬ sel = 0#64) (hs1 : ¬ sel = 1#64) (hw : Finish.way sel units tail) (_hk : Cv.At m key k) (_hf : flags < 256#64) :
    2 ≤ (w2 k flags units tail).size ∧
    Levels.top k ⟨flags.setWidth 32⟩ (w2 k flags units tail) ⟨BitVec.setWidth 32 8#64⟩
      = Levels.top k ⟨flags.setWidth 32⟩ (Finish.tops k ⟨flags.setWidth 32⟩ units tail) ⟨BitVec.setWidth 32 8#64⟩ ∧
    w2 k flags units tail = (if units.size = 0 then units else units.push (Blake3.tree k ⟨flags.setWidth 32⟩ tail)) := by
  rcases hw with ⟨h, _⟩ | ⟨h, _⟩ | ⟨_, hp, _⟩
  · exact absurd h hs0
  · exact absurd h hs1
  · have hne0 : ¬ units.size = 0 := by omega
    exact ⟨by simp only [w2, Array.size_push]; omega, by simp only [Finish.tops, hne0, if_false], by simp only [hne0, if_false]⟩

/-- The top node's compression with no flag more is the tree's chaining value (two chunks or more: a parent). -/
theorem sub (h : Cv.At m cv (Levels.top k ⟨flags.setWidth 32⟩ tail ⟨BitVec.setWidth 32 0#64⟩)) (h2 : 2 ≤ tail.size) :
    Cv.At m cv (Blake3.tree k ⟨flags.setWidth 32⟩ tail).cv := by
  have e : Levels.top k ⟨flags.setWidth 32⟩ tail ⟨BitVec.setWidth 32 0#64⟩ = (Blake3.tree k ⟨flags.setWidth 32⟩ tail).cv := by
    have ht : (Blake3.tree k ⟨flags.setWidth 32⟩ tail).t = 0 := by
      unfold Blake3.tree
      rw [Blake3.tree.go, dif_neg (by omega)]
      rfl
    unfold Levels.top Blake3.Node.cv
    rw [ht, show (Blake3.tree k ⟨flags.setWidth 32⟩ tail).flags ||| (⟨BitVec.setWidth 32 0#64⟩ : UInt32)
        = (Blake3.tree k ⟨flags.setWidth 32⟩ tail).flags from by apply UInt32.toBitVec_inj.mp; simp]
  rw [← e]; exact h

end Finish

/-- **At the return:** the root at `out`; the levels over the groups, with the last group's value if any. -/
theorem Finish.exit {m : Mem} {out wl flags : BitVec 64} {k : Blake3.CV} {units tail W : Array Blake3.Node} {X : Blake3.CV}
    (h : Cv.At m out X)
    (hX : X = Levels.top k ⟨flags.setWidth 32⟩ (Finish.tops k ⟨flags.setWidth 32⟩ units tail) ⟨BitVec.setWidth 32 8#64⟩)
    (hw : Levels.At k ⟨flags.setWidth 32⟩ m wl W)
    (hW : W = (if units.size = 0 then units else units.push (Blake3.tree k ⟨flags.setWidth 32⟩ tail))) :
    True ∧ Levels.At k ⟨flags.setWidth 32⟩ m wl (if units.size = 0 then units else units.push (Blake3.tree k ⟨flags.setWidth 32⟩ tail)) ∧
      Cv.At m out (Levels.top k ⟨flags.setWidth 32⟩ (Finish.tops k ⟨flags.setWidth 32⟩ units tail) ⟨BitVec.setWidth 32 8#64⟩) :=
  ⟨trivial, hW ▸ hw, hX ▸ h⟩
