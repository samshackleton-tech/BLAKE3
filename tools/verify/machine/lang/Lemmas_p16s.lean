import Lemmas_cvl
import Lemmas_addn
import Lemmas_merge
import Lemmas_fillp
import Spec_p16
open X86 Cells

/-! # `p16s`: lemmas for the prover

`p16s` is the function of ours that stands at the 16-lane parent kernel's address when examples run. Proved
to meet `P16.contract`, it is the witness that the contract the fast path assumes can be met: an assumed
contract that no code could meet would make every theorem that assumes it say nothing. Written by hand for
this function; its source names them. Checked by Lean; not to be read. -/

/-- The parents of a list of values, one a pair: the `j`th. -/
theorem Blake3.level_get (key : Blake3.CV) (mode : Blake3.Word) : ∀ (j : Nat) (l : List Blake3.CV), 2 * j + 1 < l.length →
    (Blake3.level key mode l)[j]? = some (Blake3.parentNode key mode l[2 * j]! l[2 * j + 1]!).cv := by
  intro j
  induction j with
  | zero =>
    intro l h
    match l, h with
    | x :: y :: rest, _ => simp [Blake3.level]
  | succ j ih =>
    intro l h
    match l, h with
    | x :: y :: rest, h =>
      simp only [List.length_cons] at h
      have := ih rest (by omega)
      rw [Blake3.level_cons, List.getElem?_cons_succ, this]
      have e1 : 2 * (j + 1) = 2 * j + 1 + 1 := by omega
      have e2 : 2 * (j + 1) + 1 = 2 * j + 1 + 1 + 1 := by omega
      simp [e1, e2]

theorem Blake3.level_length (key : Blake3.CV) (mode : Blake3.Word) : ∀ (n : Nat) (l : List Blake3.CV), l.length = 2 * n →
    (Blake3.level key mode l).length = n := by
  intro n
  induction n with
  | zero => intro l h; match l, h with | [], _ => rfl
  | succ n ih =>
    intro l h
    match l, h with
    | x :: y :: rest, h =>
      simp only [List.length_cons] at h
      rw [Blake3.level_cons, List.length_cons, ih rest (by omega)]

/-- One value more at the end of a run of values in memory. -/
theorem Cvl.at_snoc {m : Mem} {v : Blake3.CV} : ∀ (xs : List Blake3.CV) (a : BitVec 64), Cvl.At m a xs →
    Cv.At m (a + BitVec.ofNat 64 (32 * xs.length)) v → Cvl.At m a (xs ++ [v]) := by
  intro xs
  induction xs with
  | nil => intro a _ h; exact ⟨by simpa using h, trivial⟩
  | cons x rest ih =>
    intro a ⟨hx, hr⟩ h
    refine ⟨hx, ih (a + 32#64) hr ?_⟩
    have e : a + 32#64 + BitVec.ofNat 64 (32 * rest.length) = a + BitVec.ofNat 64 (32 * (x :: rest).length) := by
      apply BitVec.eq_of_toNat_eq
      simp only [BitVec.toNat_add, BitVec.toNat_ofNat, List.length_cons]
      omega
    rw [e]; exact h

namespace P16s

/-- A lane's pair is apart from where the lane writes. -/
theorem pair_apart (out base s d N : BitVec 64) (h1 : 512#64 ≤ base - out) (h2 : N ≤ out - base)
    (hs : s.toNat + 64 ≤ N.toNat) (hN : N.toNat ≤ 1024) (hd : d.toNat ≤ 480) :
    32#64 ≤ base + s - (out + d) ∧ 64#64 ≤ out + d - (base + s) := by
  constructor <;> bv_omega

/-- A byte of a piece that is apart from the 512 written bytes is not among the 32 a lane writes. -/
theorem read_away (out a d x L : BitVec 64) (h1 : 512#64 ≤ a - out) (h2 : L ≤ out - a) (hx : x - a < L)
    (hd : d.toNat ≤ 480) : 32#64 ≤ x - (out + d) := by
  bv_omega

theorem add_sub_self (a s : BitVec 64) : a + s - a = s := by bv_omega

/-- A byte of the lanes already written is not among the 32 this lane writes. -/
theorem done_away (out d x : BitVec 64) (hx : (x - out).toNat < d.toNat) (hd : d.toNat ≤ 480) :
    32#64 ≤ x - (out + d) := by
  bv_omega

variable {m m' : Mem} {inputs key out base n flags i : BitVec 64} {k : Blake3.CV} {l : List Blake3.CV}

/-- The pair a lane is given: pair `i` of the first `n`, the first pair in a lane past them. -/
def lane (n i : BitVec 64) : Nat := if i.toNat < n.toNat then i.toNat else 0

/-- What a lane writes. -/
def value (k : Blake3.CV) (flags n : BitVec 64) (l : List Blake3.CV) (i : BitVec 64) : Blake3.CV :=
  (Blake3.parentNode k ⟨flags.setWidth 32⟩ l[2 * lane n i]! l[2 * lane n i + 1]!).cv

theorem values_length (h1 : 1 ≤ n.toNat) (h16 : n.toNat ≤ 16) (hl : l.length = 2 * n.toNat) :
    (P16.values k flags n l).length = 16 := by
  unfold P16.values
  rw [List.length_append, List.length_replicate, Blake3.level_length k _ n.toNat l hl]; omega

theorem values_get (h1 : 1 ≤ n.toNat) (h16 : n.toNat ≤ 16) (hl : l.length = 2 * n.toNat) (hi : i.toNat < 16) :
    (P16.values k flags n l)[i.toNat]? = some (value k flags n l i) := by
  have hlen := Blake3.level_length k ⟨flags.setWidth 32⟩ n.toNat l hl
  unfold P16.values value lane
  by_cases h : i.toNat < n.toNat
  · rw [if_pos h, List.getElem?_append_left (by rw [hlen]; exact h)]
    exact Blake3.level_get k _ i.toNat l (by omega)
  · rw [if_neg h, List.getElem?_append_right (by rw [hlen]; omega), List.getElem?_replicate, if_pos (by rw [hlen]; omega)]
    have h0 := Blake3.level_get k ⟨flags.setWidth 32⟩ 0 l (by omega)
    rw [List.headD_eq_head?_getD, List.head?_eq_getElem?, h0]
    rfl

/-- At the loop's head: `i` lanes are written; everything read is where the contract says, and apart from
what is written. -/
def Mid (m : Mem) (inputs key out : BitVec 64) (k : Blake3.CV) (base n flags : BitVec 64) (l : List Blake3.CV)
    (i : BitVec 64) : Prop :=
  i ≤ 16#64 ∧ 1#64 ≤ n ∧ n ≤ 16#64 ∧ l.length = 2 * n.toNat ∧ flags < 256#64 ∧
  Cv.At m key k ∧ Ptrs.At m inputs (Ptrs.spread base n 64#64) ∧ Cvl.At m base l ∧ Region m out 512#64 ∧
  (512#64 ≤ key - out ∧ 32#64 ≤ out - key) ∧ (512#64 ≤ inputs - out ∧ 256#64 ≤ out - inputs) ∧
  (512#64 ≤ base - out ∧ n <<< 6 ≤ out - base) ∧
  Cvl.At m out ((P16.values k flags n l).take i.toNat)

namespace Mid

/-- What its holder may use at once. -/
theorem cells (h : Mid m inputs key out k base n flags l i) : i ≤ 16#64 ∧ Region m out 512#64 ∧ flags < 256#64 :=
  ⟨h.1, h.2.2.2.2.2.2.2.2.1, h.2.2.2.2.1⟩

/-- **Before the loop:** no lane is written. -/
theorem start {m0 : Mem} (hk : Cv.At m0 key k) (hp : Ptrs.At m0 inputs (Ptrs.spread base n 64#64)) (hl : Pairs.At n m0 base l)
    (hR : Region m out 512#64) (h1 : 1#64 ≤ n) (hf : flags < 256#64)
    (a1 : 512#64 ≤ key - out ∧ 32#64 ≤ out - key) (a2 : 512#64 ≤ inputs - out ∧ 256#64 ≤ out - inputs)
    (a3 : 512#64 ≤ base - out ∧ n <<< 6 ≤ out - base)
    (sk : ∀ x : BitVec 64, x - key < 32#64 → m x = m0 x) (sp : ∀ x : BitVec 64, x - inputs < 256#64 → m x = m0 x)
    (sl : ∀ x : BitVec 64, x - base < n <<< 6 → m x = m0 x) :
    Mid m inputs key out k base n flags l 0#64 := by
  have hl' := Pairs.At.frame hl sl
  exact ⟨by decide, h1, hl'.1, hl'.2.1, hf, Cv.At.frame hk sk, Ptrs.At.frame hp sp, hl'.2.2, hR, a1, a2, a3, by simp [Cvl.At]⟩

/-- Where a lane's pair is, as a number. -/
theorem spread_eq (h16 : n.toNat ≤ 16) :
    Ptrs.spread base n 64#64 i.toNat = base + BitVec.ofNat 64 (64 * lane n i) := by
  unfold Ptrs.spread lane
  by_cases h : i.toNat < n.toNat
  · rw [if_pos h, if_pos h]
    congr 1
    apply BitVec.eq_of_toNat_eq
    simp only [BitVec.toNat_mul, BitVec.toNat_ofNat]
    omega
  · rw [if_neg h, if_neg h]; simp

/-- **In a turn:** the lane's address in the table, the key's two vectors, the pair's four, and that the
pair is apart from where the lane writes. -/
theorem turn (h : Mid m inputs key out k base n flags l i) (hc : i < 16#64) :
    ∃ k0 k1 a0 a1 b0 b1 : V,
      Quad m (inputs + i <<< 3) (Ptrs.spread base n 64#64 i.toNat) ∧
      Vec m key k0 ∧ Vec m (key + 16#64) k1 ∧ words8 k0 k1 = k ∧
      Vec m (Ptrs.spread base n 64#64 i.toNat) a0 ∧ Vec m (Ptrs.spread base n 64#64 i.toNat + 16#64) a1 ∧
      Vec m (Ptrs.spread base n 64#64 i.toNat + 32#64) b0 ∧ Vec m (Ptrs.spread base n 64#64 i.toNat + 48#64) b1 ∧
      words8 a0 a1 = l[2 * lane n i]! ∧ words8 b0 b1 = l[2 * lane n i + 1]! ∧
      32#64 ≤ Ptrs.spread base n 64#64 i.toNat - (out + i <<< 5) ∧
      64#64 ≤ out + i <<< 5 - Ptrs.spread base n 64#64 i.toNat ∧
      Ptrs.spread base n 64#64 i.toNat - base ≤ n <<< 6 - 64#64 ∧ 64#64 ≤ n <<< 6 ∧ n <<< 6 ≤ 1024#64 := by
  obtain ⟨hi, h1, h16, hl, hf, hk, hp, hb, hR, a1, a2, a3, hw⟩ := h
  have i16 : i.toNat < 16 := hc
  have n1 : 1 ≤ n.toNat := h1
  have n16 : n.toNat ≤ 16 := h16
  have hJ : lane n i < n.toNat := by unfold lane; split <;> omega
  obtain ⟨k0, k1, hk0, hk1, hkw⟩ := hk
  have q := hp i.toNat (by omega)
  have ea : BitVec.ofNat 64 (8 * i.toNat) = i <<< 3 := by
    apply BitVec.eq_of_toNat_eq
    rw [BitVec.toNat_ofNat, BitVec.toNat_shiftLeft, Nat.shiftLeft_eq]
    omega
  rw [ea] at q
  have hL := Addn.Mid.Cvl.at_get l base (2 * lane n i) (by omega) hb (by omega)
  have hRt := Addn.Mid.Cvl.at_get l base (2 * lane n i + 1) (by omega) hb (by omega)
  have eS := spread_eq (base := base) (i := i) n16
  have e1 : base + BitVec.ofNat 64 (32 * (2 * lane n i)) = Ptrs.spread base n 64#64 i.toNat := by
    rw [eS]; congr 2; omega
  have e2 : base + BitVec.ofNat 64 (32 * (2 * lane n i + 1)) = Ptrs.spread base n 64#64 i.toNat + 32#64 := by
    rw [eS]
    apply BitVec.eq_of_toNat_eq
    simp only [BitVec.toNat_add, BitVec.toNat_ofNat]
    omega
  rw [e1] at hL
  rw [e2] at hRt
  obtain ⟨a0, a1', ha0, ha1, haw⟩ := hL
  obtain ⟨b0, b1, hb0, hb1, hbw⟩ := hRt
  have e3 : Ptrs.spread base n 64#64 i.toNat + 32#64 + 16#64 = Ptrs.spread base n 64#64 i.toNat + 48#64 := by
    rw [BitVec.add_assoc]; rfl
  rw [e3] at hb1
  have g1 : l[2 * lane n i]! = l[2 * lane n i]'(by omega) := getElem!_pos l _ (by omega)
  have g2 : l[2 * lane n i + 1]! = l[2 * lane n i + 1]'(by omega) := getElem!_pos l _ (by omega)
  have es : (BitVec.ofNat 64 (64 * lane n i)).toNat = 64 * lane n i := by rw [BitVec.toNat_ofNat]; omega
  have ed : (i <<< 5).toNat = 32 * i.toNat := by rw [BitVec.toNat_shiftLeft, Nat.shiftLeft_eq]; omega
  have eN : (n <<< 6).toNat = 64 * n.toNat := by rw [BitVec.toNat_shiftLeft, Nat.shiftLeft_eq]; omega
  have hap := pair_apart out base (BitVec.ofNat 64 (64 * lane n i)) (i <<< 5) (n <<< 6) a3.1 a3.2
    (by rw [es, eN]; omega) (by rw [eN]; omega) (by rw [ed]; omega)
  rw [← eS] at hap
  have hN1 : 64#64 ≤ n <<< 6 := by show 64 ≤ (n <<< 6).toNat; rw [eN]; omega
  have hin : Ptrs.spread base n 64#64 i.toNat - base ≤ n <<< 6 - 64#64 := by
    rw [eS, add_sub_self]
    show (BitVec.ofNat 64 (64 * lane n i)).toNat ≤ (n <<< 6 - 64#64).toNat
    have e64 : (n <<< 6 - 64#64).toNat = 64 * n.toNat - 64 := by
      rw [BitVec.toNat_sub_of_le hN1, eN]; rfl
    rw [es, e64]; omega
  have hN2 : n <<< 6 ≤ 1024#64 := by show (n <<< 6).toNat ≤ 1024; rw [eN]; omega
  exact ⟨k0, k1, a0, a1', b0, b1, q, hk0, hk1, hkw, ha0, ha1, hb0, hb1, by rw [g1]; exact haw, by rw [g2]; exact hbw, hap.1, hap.2,
    hin, hN1, hN2⟩

/-- **Across a turn:** the lane written is the pair's parent. -/
theorem step {k0 k1 a0 a1 b0 b1 : V} {packed : BitVec 64}
    (h : Mid m inputs key out k base n flags l i) (hc : i < 16#64)
    (hkw : words8 k0 k1 = k) (haw : words8 a0 a1 = l[2 * lane n i]!) (hbw : words8 b0 b1 = l[2 * lane n i + 1]!)
    (hv0 : Vec m' (out + i <<< 5) (Kernels.out k0 k1 a0 a1 b0 b1 0#64 64#32 (BitVec.setWidth 32 (BitVec.setWidth 8 (packed &&& 255#64)))).1)
    (hv1 : Vec m' (out + i <<< 5 + 16#64) (Kernels.out k0 k1 a0 a1 b0 b1 0#64 64#32 (BitVec.setWidth 32 (BitVec.setWidth 8 (packed &&& 255#64)))).2)
    (hpk : packed = flags ||| 0x40000004#64)
    (hR : Region m' out 512#64)
    (sk : ∀ x : BitVec 64, x - key < 32#64 → m' x = m x) (sp : ∀ x : BitVec 64, x - inputs < 256#64 → m' x = m x)
    (sb : ∀ x : BitVec 64, x - base < n <<< 6 → m' x = m x)
    (so : ∀ x : BitVec 64, x - out < 512#64 → 32#64 ≤ x - (out + i <<< 5) → m' x = m x) :
    Mid m' inputs key out k base n flags l (i + 1#64) := by
  obtain ⟨hi, h1, h16, hl, hf, hk, hp, hb, _, a1', a2, a3, hw⟩ := h
  have i16 : i.toNat < 16 := hc
  have n1 : 1 ≤ n.toNat := h1
  have n16 : n.toNat ≤ 16 := h16
  have ed : (i <<< 5).toNat = 32 * i.toNat := by rw [BitVec.toNat_shiftLeft, Nat.shiftLeft_eq]; omega
  have eN : (n <<< 6).toNat = 64 * n.toNat := by rw [BitVec.toNat_shiftLeft, Nat.shiftLeft_eq]; omega
  have ei : (i + 1#64).toNat = i.toNat + 1 := by bv_omega
  have hlen := values_length (k := k) (flags := flags) n1 n16 hl
  have hget := values_get (k := k) (flags := flags) n1 n16 hl i16
  have htake : (P16.values k flags n l).take (i.toNat + 1) = (P16.values k flags n l).take i.toNat ++ [value k flags n l i] := by
    rw [List.take_succ, hget]; rfl
  have hv : Cv.At m' (out + i <<< 5) (value k flags n l i) := by
    refine Cv.At.intro hv0 hv1 ?_
    have hX : BitVec.setWidth 32 (BitVec.setWidth 8 (packed &&& 255#64)) = BitVec.setWidth 32 (BitVec.setWidth 8 (flags ||| 4#64)) := by
      rw [hpk]; bv_decide
    rw [hX]
    unfold value
    rw [Merge.parent k0 k1 a0 a1 b0 b1 flags hf, hkw, haw, hbw]
  have hd : (i <<< 5).toNat ≤ 480 := by rw [ed]; omega
  have ek : Cv.At m' key k := Cv.At.frame hk sk
  have ep : Ptrs.At m' inputs (Ptrs.spread base n 64#64) := Ptrs.At.frame hp sp
  have eb : Cvl.At m' base l := by
    refine Cvl.At.frame l base (by omega) (fun x hx => sb x ?_) hb
    show (x - base).toNat < (n <<< 6).toNat
    rw [eN]; omega
  have ew : Cvl.At m' out ((P16.values k flags n l).take i.toNat) := by
    refine Cvl.At.frame _ out (by rw [List.length_take]; omega) (fun x hx => ?_) hw
    rw [List.length_take, hlen, Nat.min_eq_left (by omega)] at hx
    exact so x (by show (x - out).toNat < 512; omega) (done_away out (i <<< 5) x (by rw [ed]; exact hx) hd)
  have hi1 : i + 1#64 ≤ 16#64 := by
    show (i + 1#64).toNat ≤ 16
    rw [ei]; omega
  refine ⟨hi1, h1, h16, hl, hf, ek, ep, eb, hR, a1', a2, a3, ?_⟩
  rw [ei, htake]
  refine Cvl.at_snoc _ out ew ?_
  have e : out + BitVec.ofNat 64 (32 * ((P16.values k flags n l).take i.toNat).length) = out + i <<< 5 := by
    rw [List.length_take, hlen, Nat.min_eq_left (by omega)]
    congr 1
    apply BitVec.eq_of_toNat_eq
    rw [BitVec.toNat_ofNat, ed]; omega
  rw [e]; exact hv

end Mid

end P16s

/-- **When the loop ends:** the sixteen lanes hold what the contract says. -/
theorem P16s.exit {m : Mem} {inputs key out base n flags i : BitVec 64} {k : Blake3.CV} {l : List Blake3.CV}
    (h : P16s.Mid m inputs key out k base n flags l i) (hc : ¬ i < 16#64) :
    True ∧ Cvs16.At m out (P16.values k flags n l) := by
  obtain ⟨hi, h1, h16, hl, _, _, _, _, _, _, _, _, hw⟩ := h
  have i16 : i.toNat = 16 := by bv_omega
  have hlen := P16s.values_length (k := k) (flags := flags) (show 1 ≤ n.toNat from h1) (show n.toNat ≤ 16 from h16) hl
  rw [i16, ← hlen, List.take_length] at hw
  exact ⟨trivial, hlen, hw⟩
