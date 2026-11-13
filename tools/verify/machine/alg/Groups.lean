import Stack

/-! # Whole groups of chunks are leaves of the specification's tree

The specification defines the tree from the top. A hasher that takes many chunks at a time (a wide
kernel takes 32) makes each group's subtree first and then a tree over the groups' values. This file
proves that this is the specification's tree: with the chunks in groups of `2^b`, the last group of
`1` to `2^b` chunks, the tree over the chunks is the tree over the groups' own trees.

It names no code and no machine. -/

namespace Blake3

set_option linter.deprecated false

variable (key : Vector Word 8) (mode : Word) (chunks : Array Node)

/-- A number of two or more is a power of two and a rest of one up to that power. -/
theorem pow_and_rest (m : Nat) (h : 2 ≤ m) : ∃ a r, m = 2 ^ a + r ∧ 1 ≤ r ∧ r ≤ 2 ^ a := by
  refine ⟨(m - 1).log2, m - leftCount m, ?_, ?_, ?_⟩
  · have := leftCount_lt m h; unfold leftCount at this ⊢; omega
  · exact (split_nonempty m h).2
  · exact left_big m h

/-- The chunks in groups of `size`, the last of `last` chunks: how many chunks `g` groups from the
first are, where `g` may count the last (`count` groups in all). -/
def groupsLen (size last count g : Nat) : Nat := if g < count then g * size else (count - 1) * size + last

/-- **The specification's subtree over `m` whole groups from group `g0` is its subtree over those
groups' own subtrees**: `groups` holds, for each group, the node of the specification's subtree over
its chunks. -/
theorem go_groups (b last count : Nat) (hl1 : 1 ≤ last) (hl : last ≤ 2 ^ b) (groups : Array Node)
    (hg : ∀ g, g < count → groups[g]! = tree.go key mode chunks (g * 2 ^ b) (if g + 1 < count then 2 ^ b else last)) :
    ∀ (m g0 : Nat), 1 ≤ m → g0 + m ≤ count →
      tree.go key mode chunks (g0 * 2 ^ b) (if g0 + m < count then m * 2 ^ b else (m - 1) * 2 ^ b + last) =
        tree.go key mode groups g0 m := by
  intro m
  induction m using Nat.strongRecOn with
  | _ m ih =>
    intro g0 h1 hc
    rcases Nat.lt_or_ge m 2 with hm | hm
    · -- one group: its own subtree
      have e : m = 1 := by omega
      subst e
      rw [go_one, hg g0 (by omega)]
      by_cases hlast : g0 + 1 < count
      · simp [hlast]
      · simp [hlast]
    · obtain ⟨a, r, e, hr1, hr⟩ := pow_and_rest m hm
      subst e
      have hp := Nat.two_pow_pos a
      have hb := Nat.two_pow_pos b
      -- the chunks: a power of two, and a rest of one up to it
      have hn : (if g0 + (2 ^ a + r) < count then (2 ^ a + r) * 2 ^ b else (2 ^ a + r - 1) * 2 ^ b + last) =
          2 ^ (a + b) + (if g0 + (2 ^ a + r) < count then r * 2 ^ b else (r - 1) * 2 ^ b + last) := by
        rw [Nat.pow_add]
        by_cases hh : g0 + (2 ^ a + r) < count
        · simp only [hh, if_true]; rw [Nat.add_mul]
        · simp only [hh, if_false]
          have : 2 ^ a + r - 1 = 2 ^ a + (r - 1) := by omega
          rw [this, Nat.add_mul]; omega
      have hrest1 : 1 ≤ (if g0 + (2 ^ a + r) < count then r * 2 ^ b else (r - 1) * 2 ^ b + last) := by
        by_cases hh : g0 + (2 ^ a + r) < count
        · simp only [hh, if_true]; exact Nat.le_trans hb (Nat.le_mul_of_pos_left _ hr1)
        · simp only [hh, if_false]; omega
      have hrest : (if g0 + (2 ^ a + r) < count then r * 2 ^ b else (r - 1) * 2 ^ b + last) ≤ 2 ^ (a + b) := by
        rw [Nat.pow_add]
        by_cases hh : g0 + (2 ^ a + r) < count
        · simp only [hh, if_true]; exact Nat.mul_le_mul_right _ hr
        · simp only [hh, if_false]
          have h1' : (r - 1) * 2 ^ b + 2 ^ b = r * 2 ^ b := by
            have : r = (r - 1) + 1 := by omega
            conv => rhs; rw [this, Nat.add_mul, Nat.one_mul]
          have h2' : r * 2 ^ b ≤ 2 ^ a * 2 ^ b := Nat.mul_le_mul_right _ hr
          omega
      rw [hn, go_split key mode chunks _ (a + b) _ hrest1 hrest, go_split key mode groups g0 a r hr1 hr]
      -- the left: 2^a whole groups; the right: the r groups after them
      have left := ih (2 ^ a) (by omega) g0 (by omega) (by omega)
      have hleft : g0 + 2 ^ a < count := by omega
      simp only [hleft, if_true] at left
      have right := ih r (by omega) (g0 + 2 ^ a) hr1 (by omega)
      have hstart : (g0 + 2 ^ a) * 2 ^ b = g0 * 2 ^ b + 2 ^ (a + b) := by rw [Nat.add_mul, Nat.pow_add]
      rw [hstart, Nat.add_assoc] at right
      simp only [sub]
      rw [← Nat.pow_add] at left
      rw [left, right]

/-- **The tree over the chunks is the tree over their groups**: `count` groups of `2^b` chunks, the
last of `1` to `2^b`. -/
theorem tree_groups (b last count : Nat) (hc : 1 ≤ count) (hl1 : 1 ≤ last) (hl : last ≤ 2 ^ b) (groups : Array Node)
    (hsize : chunks.size = (count - 1) * 2 ^ b + last) (hgs : groups.size = count)
    (hg : ∀ g, g < count → groups[g]! = tree.go key mode chunks (g * 2 ^ b) (if g + 1 < count then 2 ^ b else last)) :
    tree key mode chunks = tree key mode groups := by
  have := go_groups key mode chunks b last count hl1 hl groups hg count 0 hc (by omega)
  simp only [Nat.zero_mul, Nat.zero_add, Nat.lt_irrefl, if_false] at this
  rw [tree, tree, hsize, hgs]; exact this

/-! ## A level of parents at a time

A wide kernel makes sixteen parents in one call. Each pair's parent, in order, is one level of a tree; five
levels over the values of 32 chunks one after another are the specification's subtree over them. -/

/-- One level of a tree: each pair's parent value, in order (C2SP's BLAKE3, section 4.3.1). -/
def level : List CV → List CV
  | x :: y :: rest => (parentNode key mode x y).cv :: level rest
  | _ => []

/-- The values of `n` subtrees of the specification, `w` chunks each, one after another from chunk `s`. -/
def subs (s w : Nat) : Nat → List CV
  | 0 => []
  | n + 1 => sub key mode chunks s w :: subs (s + w) w n

theorem subs_succ (s w n : Nat) : subs key mode chunks s w (n + 1) = sub key mode chunks s w :: subs key mode chunks (s + w) w n := rfl

theorem level_cons (x y : CV) (rest : List CV) : level key mode (x :: y :: rest) = (parentNode key mode x y).cv :: level key mode rest := rfl

theorem subs_length (s w n : Nat) : (subs key mode chunks s w n).length = n := by
  induction n generalizing s with
  | zero => rfl
  | succ n ih => rw [subs_succ, List.length_cons, ih]

/-- One level of parents over subtrees of `2^a` chunks: the subtrees of `2^(a+1)`. -/
theorem level_subs (a : Nat) : ∀ (n s : Nat),
    level key mode (subs key mode chunks s (2 ^ a) (2 * n)) = subs key mode chunks s (2 ^ (a + 1)) n := by
  intro n
  induction n with
  | zero => intro s; rfl
  | succ n ih =>
    intro s
    have hp := Nat.two_pow_pos a
    have e2 : 2 ^ (a + 1) = 2 ^ a + 2 ^ a := by rw [Nat.pow_succ]; omega
    rw [show 2 * (n + 1) = (2 * n + 1) + 1 by omega, subs_succ, subs_succ, level_cons, subs_succ,
        show s + 2 ^ a + 2 ^ a = s + 2 ^ (a + 1) by omega, ih (s + 2 ^ (a + 1))]
    have := go_split key mode chunks s a (2 ^ a) hp (Nat.le_refl _)
    rw [← e2] at this
    have hv : (parentNode key mode (sub key mode chunks s (2 ^ a)) (sub key mode chunks (s + 2 ^ a) (2 ^ a))).cv
        = sub key mode chunks s (2 ^ (a + 1)) := by
      unfold sub at this ⊢
      rw [this]
    rw [hv]

/-- The values of the chunks one after another are the subtrees of one chunk. -/
theorem subs_one : ∀ (n s : Nat), subs key mode chunks s 1 n = (List.range n).map fun i => (chunks[s + i]!).cv := by
  intro n
  induction n with
  | zero => intro s; rfl
  | succ n ih =>
    intro s
    rw [subs_succ, ih (s + 1), List.range_succ_eq_map, List.map_cons, List.map_map]
    have h0 : sub key mode chunks s 1 = (chunks[s + 0]!).cv := by
      unfold sub; rw [go_one, Nat.add_zero]
    have hr : (List.range n).map (fun i => (chunks[s + 1 + i]!).cv) = (List.range n).map ((fun i => (chunks[s + i]!).cv) ∘ Nat.succ) := by
      apply List.map_congr_left
      intro i _
      show (chunks[s + 1 + i]!).cv = (chunks[s + (i + 1)]!).cv
      rw [show s + 1 + i = s + (i + 1) by omega]
    rw [h0, hr]

/-- **Five levels of parents over the values of 32 chunks one after another are the specification's
subtree over them.** -/
theorem level5 (s : Nat) :
    level key mode (level key mode (level key mode (level key mode (level key mode
      ((List.range 32).map fun i => (chunks[s + i]!).cv))))) = [sub key mode chunks s 32] := by
  rw [← subs_one key mode chunks 32 s]
  have h1 := level_subs key mode chunks 0 16 s
  have h2 := level_subs key mode chunks 1 8 s
  have h3 := level_subs key mode chunks 2 4 s
  have h4 := level_subs key mode chunks 3 2 s
  have h5 := level_subs key mode chunks 4 1 s
  rw [show 2 * 16 = 32 from rfl, show (2:Nat) ^ 0 = 1 from rfl, show (2:Nat) ^ (0 + 1) = 2 from rfl] at h1
  rw [show 2 * 8 = 16 from rfl, show (2:Nat) ^ 1 = 2 from rfl, show (2:Nat) ^ (1 + 1) = 4 from rfl] at h2
  rw [show 2 * 4 = 8 from rfl, show (2:Nat) ^ 2 = 4 from rfl, show (2:Nat) ^ (2 + 1) = 8 from rfl] at h3
  rw [show 2 * 2 = 4 from rfl, show (2:Nat) ^ 3 = 8 from rfl, show (2:Nat) ^ (3 + 1) = 16 from rfl] at h4
  rw [show 2 * 1 = 2 from rfl, show (2:Nat) ^ 4 = 16 from rfl, show (2:Nat) ^ (4 + 1) = 32 from rfl] at h5
  rw [h1, h2, h3, h4, h5]
  rfl

/-- The specification's subtree over a range reads only that range: over other chunks that are the same
there, it is the same. -/
theorem go_congr (other : Array Node) (s s' : Nat) : ∀ (n start : Nat), 1 ≤ n →
    (∀ i, i < n → chunks[s + start + i]! = other[s' + start + i]!) →
    tree.go key mode chunks (s + start) n = tree.go key mode other (s' + start) n := by
  intro n
  induction n using Nat.strongRecOn with
  | _ n ih =>
    intro start hn h
    rw [tree.go, tree.go]
    by_cases h1 : n ≤ 1
    · simp only [h1, dite_true]
      have := h 0 (by omega); simpa using this
    · simp only [h1, dite_false]
      have hk := leftCount_lt n (by omega)
      have hk0 := leftCount_pos n
      rw [ih (leftCount n) hk start hk0 (fun i hi => h i (by omega))]
      have := ih (n - leftCount n) (by omega) (start + leftCount n) (by omega) (fun i hi => by
        have := h (leftCount n + i) (by omega)
        rw [show s + (start + leftCount n) + i = s + start + (leftCount n + i) by omega,
            show s' + (start + leftCount n) + i = s' + start + (leftCount n + i) by omega]; exact this)
      rw [show s + (start + leftCount n) = s + start + leftCount n by omega,
          show s' + (start + leftCount n) = s' + start + leftCount n by omega] at this
      rw [this]

end Blake3
