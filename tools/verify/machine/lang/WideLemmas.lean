import Machine
import Cells
open X86

/-! # The wide registers, lane by lane

A ZMM register is sixteen doublewords (`zpack`); an instruction that works on each doubleword by itself
does to a packed register what it does to each lane. What the proofs of a wide kernel use. -/

namespace X86

theorem zjoin_split (v : Z) : zjoin (zlo v) (zhi v) = v := by
  simp only [zjoin, zlo, zhi]; bv_decide
theorem zlo_zjoin (a : V) (b : U) : zlo (zjoin a b) = a := by
  simp only [zjoin, zlo]; bv_decide
theorem zhi_zjoin (a : V) (b : U) : zhi (zjoin a b) = b := by
  simp only [zjoin, zhi]; bv_decide

/-- Doubleword `i` of a packed register is lane `i`. -/
theorem zdw_zpack (f : Nat → BitVec 32) : ∀ i, i < 16 → zdw (zpack f) i = f i
  | 0, _ => by simp only [zdw, zpack, Nat.reduceMul]; bv_decide
  | 1, _ => by simp only [zdw, zpack, Nat.reduceMul]; bv_decide
  | 2, _ => by simp only [zdw, zpack, Nat.reduceMul]; bv_decide
  | 3, _ => by simp only [zdw, zpack, Nat.reduceMul]; bv_decide
  | 4, _ => by simp only [zdw, zpack, Nat.reduceMul]; bv_decide
  | 5, _ => by simp only [zdw, zpack, Nat.reduceMul]; bv_decide
  | 6, _ => by simp only [zdw, zpack, Nat.reduceMul]; bv_decide
  | 7, _ => by simp only [zdw, zpack, Nat.reduceMul]; bv_decide
  | 8, _ => by simp only [zdw, zpack, Nat.reduceMul]; bv_decide
  | 9, _ => by simp only [zdw, zpack, Nat.reduceMul]; bv_decide
  | 10, _ => by simp only [zdw, zpack, Nat.reduceMul]; bv_decide
  | 11, _ => by simp only [zdw, zpack, Nat.reduceMul]; bv_decide
  | 12, _ => by simp only [zdw, zpack, Nat.reduceMul]; bv_decide
  | 13, _ => by simp only [zdw, zpack, Nat.reduceMul]; bv_decide
  | 14, _ => by simp only [zdw, zpack, Nat.reduceMul]; bv_decide
  | 15, _ => by simp only [zdw, zpack, Nat.reduceMul]; bv_decide
  | n + 16, h => absurd h (by omega)

/-- Two packed registers with the same sixteen lanes are the same register. -/
theorem zpack_congr {f g : Nat → BitVec 32} (h : ∀ i, i < 16 → f i = g i) : zpack f = zpack g := by
  simp only [zpack, h 0 (by decide), h 1 (by decide), h 2 (by decide), h 3 (by decide), h 4 (by decide), h 5 (by decide), h 6 (by decide), h 7 (by decide), h 8 (by decide), h 9 (by decide), h 10 (by decide), h 11 (by decide), h 12 (by decide), h 13 (by decide), h 14 (by decide), h 15 (by decide)]

theorem zmap2_pack (g : BitVec 32 → BitVec 32 → BitVec 32) (a b : Nat → BitVec 32) :
    zmap2 g (zpack a) (zpack b) = zpack (fun i => g (a i) (b i)) :=
  zpack_congr fun i hi => by rw [zdw_zpack _ i hi, zdw_zpack _ i hi]

theorem zmap1_pack (g : BitVec 32 → BitVec 32) (a : Nat → BitVec 32) :
    zmap1 g (zpack a) = zpack (fun i => g (a i)) :=
  zpack_congr fun i hi => by rw [zdw_zpack _ i hi]

theorem zxor_pack (a b : Nat → BitVec 32) : zpack a ^^^ zpack b = zpack (fun i => a i ^^^ b i) := by
  simp only [zpack]; bv_decide

theorem zdw_zmap2 (g : BitVec 32 → BitVec 32 → BitVec 32) (a b : Z) {i : Nat} (hi : i < 16) :
    zdw (zmap2 g a b) i = g (zdw a i) (zdw b i) := zdw_zpack _ i hi

theorem zdw_zmap1 (g : BitVec 32 → BitVec 32) (a : Z) {i : Nat} (hi : i < 16) :
    zdw (zmap1 g a) i = g (zdw a i) := zdw_zpack _ i hi

theorem zdw_xor (a b : Z) : ∀ i, i < 16 → zdw (a ^^^ b) i = zdw a i ^^^ zdw b i
  | 0, _ | 1, _ | 2, _ | 3, _ | 4, _ | 5, _ | 6, _ | 7, _
  | 8, _ | 9, _ | 10, _ | 11, _ | 12, _ | 13, _ | 14, _ | 15, _ => by
    simp only [zdw, Nat.reduceMul]; bv_decide
  | n + 16, h => absurd h (by omega)


theorem zdw_zbroadcast (v : BitVec 32) : ∀ i, i < 16 → zdw (zbroadcast v) i = v :=
  fun i hi => zdw_zpack (fun _ => v) i hi

theorem zdw_zunpckldq (a b : Z) : ∀ i, i < 16 → zdw (zunpckldq a b) i =
    match i % 4 with | 0 => zdw a (i / 4 * 4) | 1 => zdw b (i / 4 * 4) | 2 => zdw a (i / 4 * 4 + 1) | _ => zdw b (i / 4 * 4 + 1) :=
  fun i hi => zdw_zpack _ i hi

theorem zdw_zunpckhdq (a b : Z) : ∀ i, i < 16 → zdw (zunpckhdq a b) i =
    match i % 4 with | 0 => zdw a (i / 4 * 4 + 2) | 1 => zdw b (i / 4 * 4 + 2) | 2 => zdw a (i / 4 * 4 + 3) | _ => zdw b (i / 4 * 4 + 3) :=
  fun i hi => zdw_zpack _ i hi

theorem zdw_zunpcklqdq (a b : Z) : ∀ i, i < 16 → zdw (zunpcklqdq a b) i =
    match i % 4 with | 0 => zdw a (i / 4 * 4) | 1 => zdw a (i / 4 * 4 + 1) | 2 => zdw b (i / 4 * 4) | _ => zdw b (i / 4 * 4 + 1) :=
  fun i hi => zdw_zpack _ i hi

theorem zdw_zunpckhqdq (a b : Z) : ∀ i, i < 16 → zdw (zunpckhqdq a b) i =
    match i % 4 with | 0 => zdw a (i / 4 * 4 + 2) | 1 => zdw a (i / 4 * 4 + 3) | 2 => zdw b (i / 4 * 4 + 2) | _ => zdw b (i / 4 * 4 + 3) :=
  fun i hi => zdw_zpack _ i hi

theorem zquarter_zpack (f : Nat → BitVec 32) : ∀ q, q < 4 →
    zquarter (zpack f) q = mk4 (f (4 * q)) (f (4 * q + 1)) (f (4 * q + 2)) (f (4 * q + 3))
  | 0, _ | 1, _ | 2, _ | 3, _ => by
    simp only [zquarter, zpack, mk4, Nat.reduceMul, Nat.reduceAdd]; bv_decide
  | n + 4, h => absurd h (by omega)

theorem zdw_zquarter (v : Z) (q i : Nat) (hq : q < 4) (hi : i < 4) :
    zdw v (4 * q + i) = dw (zquarter v q) i := by
  rcases q with _ | _ | _ | _ | q <;> rcases i with _ | _ | _ | _ | i <;>
    first
    | omega
    | (simp only [zdw, dw, zquarter, Nat.reduceMul, Nat.reduceAdd]; bv_decide)

theorem zquarter_join0 (q0 q1 q2 q3 : V) : zquarter (q3 ++ q2 ++ q1 ++ q0) 0 = q0 := by
  simp only [zquarter, Nat.reduceMul]; bv_decide
theorem zquarter_join1 (q0 q1 q2 q3 : V) : zquarter (q3 ++ q2 ++ q1 ++ q0) 1 = q1 := by
  simp only [zquarter, Nat.reduceMul]; bv_decide
theorem zquarter_join2 (q0 q1 q2 q3 : V) : zquarter (q3 ++ q2 ++ q1 ++ q0) 2 = q2 := by
  simp only [zquarter, Nat.reduceMul]; bv_decide
theorem zquarter_join3 (q0 q1 q2 q3 : V) : zquarter (q3 ++ q2 ++ q1 ++ q0) 3 = q3 := by
  simp only [zquarter, Nat.reduceMul]; bv_decide

theorem zdw_zshufi32x4 (a b : Z) (imm : Nat) : ∀ i, i < 16 → zdw (zshufi32x4 a b imm) i =
    let q := i / 4; let r := i % 4
    match q with
    | 0 => zdw a (4 * (imm % 4) + r)
    | 1 => zdw a (4 * (imm / 4 % 4) + r)
    | 2 => zdw b (4 * (imm / 16 % 4) + r)
    | _ => zdw b (4 * (imm / 64 % 4) + r) := by
  intro i hi
  have hq : i / 4 < 4 := by omega
  have hr : i % 4 < 4 := Nat.mod_lt _ (by decide)
  have hdiv : 4 * (i / 4) + i % 4 = i := by omega
  have e : zdw (zshufi32x4 a b imm) i = zdw (zshufi32x4 a b imm) (4 * (i / 4) + i % 4) := congrArg _ hdiv.symm
  rw [e, zdw_zquarter _ _ _ hq hr]
  simp only [zshufi32x4]
  rcases hq_eq : i / 4 with _ | _ | _ | _ | k
  · rw [zquarter_join0, ← zdw_zquarter a (imm % 4) (i % 4) (Nat.mod_lt _ (by decide)) hr]
    simp [hq_eq]
  · rw [zquarter_join1, ← zdw_zquarter a (imm / 4 % 4) (i % 4) (Nat.mod_lt _ (by decide)) hr]
    simp [hq_eq]
  · rw [zquarter_join2, ← zdw_zquarter b (imm / 16 % 4) (i % 4) (Nat.mod_lt _ (by decide)) hr]
    simp [hq_eq]
  · rw [zquarter_join3, ← zdw_zquarter b (imm / 64 % 4) (i % 4) (Nat.mod_lt _ (by decide)) hr]
    simp [hq_eq]
  · omega


def Mem.put512 (m : Mem) (a : BitVec 64) (v : Z) : Mem :=
  (((m.put128 a (zquarter v 0)).put128 (a + 16#64) (zquarter v 1)).put128 (a + 32#64) (zquarter v 2)).put128 (a + 48#64) (zquarter v 3)

def Owned64 (m : Mem) (a : BitVec 64) : Prop :=
  Owned16 m a ∧ Owned16 m (a + 16#64) ∧ Owned16 m (a + 32#64) ∧ Owned16 m (a + 48#64)

theorem zjoin_quarters (v : Z) : zquarter v 3 ++ zquarter v 2 ++ zquarter v 1 ++ zquarter v 0 = v := by
  simp only [zquarter, Nat.reduceMul]; bv_decide

theorem write512_of {m : Mem} {a : BitVec 64} (o : Owned64 m a) (v : Z) :
    m.write512 a v = some (m.put512 a v) := by
  obtain ⟨o0, o1, o2, o3⟩ := o
  have o1' := owned16_put128 m a (a + 16#64) (zquarter v 0) o1
  have o2' := owned16_put128 _ (a + 16#64) (a + 32#64) (zquarter v 1) (owned16_put128 _ a (a + 32#64) (zquarter v 0) o2)
  have o3' := owned16_put128 _ (a + 32#64) (a + 48#64) (zquarter v 2)
    (owned16_put128 _ (a + 16#64) (a + 48#64) (zquarter v 1) (owned16_put128 _ a (a + 48#64) (zquarter v 0) o3))
  simp only [Mem.write512, Mem.put512, BitVec.ofNat_eq_ofNat, write_vec o0, write_vec o1', write_vec o2', write_vec o3',
    Option.bind_eq_bind, Option.bind_some]

theorem put512_other (m : Mem) (a : BitVec 64) (v : Z) (x : BitVec 64) (h : 64 ≤ (x - a).toNat) :
    m.put512 a v x = m x := by
  simp only [Mem.put512]
  rw [put128_other _ _ _ _ (by bv_omega), put128_other _ _ _ _ (by bv_omega),
    put128_other _ _ _ _ (by bv_omega), put128_other _ _ _ _ (by bv_omega)]

theorem put512_isSome (m : Mem) (a : BitVec 64) (v : Z) (x : BitVec 64) (h : (m x).isSome) :
    (m.put512 a v x).isSome := by
  simp only [Mem.put512]
  exact put128_isSome _ _ _ _ (put128_isSome _ _ _ _ (put128_isSome _ _ _ _ (put128_isSome _ _ _ _ h)))

theorem owned64_put512 (m : Mem) (a b : BitVec 64) (v : Z) (o : Owned64 m b) : Owned64 (m.put512 a v) b := by
  obtain ⟨o0, o1, o2, o3⟩ := o
  simp only [Owned64, Mem.put512]
  exact ⟨owned16_put128 _ _ _ _ (owned16_put128 _ _ _ _ (owned16_put128 _ _ _ _ (owned16_put128 _ _ _ _ o0))),
    owned16_put128 _ _ _ _ (owned16_put128 _ _ _ _ (owned16_put128 _ _ _ _ (owned16_put128 _ _ _ _ o1))),
    owned16_put128 _ _ _ _ (owned16_put128 _ _ _ _ (owned16_put128 _ _ _ _ (owned16_put128 _ _ _ _ o2))),
    owned16_put128 _ _ _ _ (owned16_put128 _ _ _ _ (owned16_put128 _ _ _ _ (owned16_put128 _ _ _ _ o3)))⟩

theorem read512_put512_same (m : Mem) (a : BitVec 64) (v : Z) : (m.put512 a v).read512 a = some v := by
  have r0 : (m.put512 a v).read128 a = some (zquarter v 0) := by
    simp only [Mem.put512]
    rw [Cells.read128_put128_far _ _ _ _ (by bv_decide), Cells.read128_put128_far _ _ _ _ (by bv_decide),
      Cells.read128_put128_far _ _ _ _ (by bv_decide), Cells.read128_put128_same]
  have r1 : (m.put512 a v).read128 (a + 16#64) = some (zquarter v 1) := by
    simp only [Mem.put512]
    rw [Cells.read128_put128_far _ _ _ _ (by bv_decide), Cells.read128_put128_far _ _ _ _ (by bv_decide),
      Cells.read128_put128_same]
  have r2 : (m.put512 a v).read128 (a + 32#64) = some (zquarter v 2) := by
    simp only [Mem.put512]
    rw [Cells.read128_put128_far _ _ _ _ (by bv_decide), Cells.read128_put128_same]
  have r3 : (m.put512 a v).read128 (a + 48#64) = some (zquarter v 3) := by
    simp only [Mem.put512]; exact Cells.read128_put128_same _ _ _
  simp only [Mem.read512, BitVec.ofNat_eq_ofNat, r0, r1, r2, r3, Option.bind_eq_bind, Option.bind_some, Option.pure_def,
    zjoin_quarters]

theorem read512_congr {m m' : Mem} (a : BitVec 64) (h : ∀ x, (x - a).toNat < 64 → m' x = m x) :
    m'.read512 a = m.read512 a := by
  simp only [Mem.read512]
  rw [read128_congr a (fun x hx => h x (by bv_omega)),
    read128_congr (a + 16) (fun x hx => h x (by bv_omega)),
    read128_congr (a + 32) (fun x hx => h x (by bv_omega)),
    read128_congr (a + 48) (fun x hx => h x (by bv_omega))]

theorem read512_put512_far (m : Mem) (a : BitVec 64) (v : Z) (b : BitVec 64) (h : 64#64 ≤ b - a ∧ 64#64 ≤ a - b) :
    (m.put512 a v).read512 b = m.read512 b :=
  read512_congr b fun x hx => put512_other m a v x (by obtain ⟨h1, h2⟩ := h; bv_omega)

theorem read512_of_vecs {m : Mem} {a : BitVec 64} {q0 q1 q2 q3 : V}
    (h0 : Vec m a q0) (h1 : Vec m (a + 16#64) q1) (h2 : Vec m (a + 32#64) q2) (h3 : Vec m (a + 48#64) q3) :
    m.read512 a = some (q3 ++ q2 ++ q1 ++ q0) := by
  simp only [Mem.read512, BitVec.ofNat_eq_ofNat, read_vec h0, read_vec h1, read_vec h2, read_vec h3,
    Option.bind_eq_bind, Option.bind_some, Option.pure_def]

theorem owned64_region {m : Mem} {b n : BitVec 64} (h : Cells.Region m b n) (c : BitVec 64)
    (hc : c ≤ c + 63#64 ∧ c + 63#64 < n) : Owned64 m (b + c) := by
  obtain ⟨h1, h2⟩ := hc
  refine ⟨Cells.owned16_region h c (by bv_omega), ?_, ?_, ?_⟩
  · have e : b + (c + 16#64) = b + c + 16#64 := (BitVec.add_assoc b c 16#64).symm
    rw [← e]; exact Cells.owned16_region h (c + 16#64) (by bv_omega)
  · have e : b + (c + 32#64) = b + c + 32#64 := (BitVec.add_assoc b c 32#64).symm
    rw [← e]; exact Cells.owned16_region h (c + 32#64) (by bv_omega)
  · have e : b + (c + 48#64) = b + c + 48#64 := (BitVec.add_assoc b c 48#64).symm
    rw [← e]; exact Cells.owned16_region h (c + 48#64) (by bv_omega)

theorem aligned64_add {a d : BitVec 64} (ha : aligned64 a = true) (hd : aligned64 d = true) :
    aligned64 (a + d) = true := by
  simp only [aligned64] at ha hd ⊢; bv_decide

theorem aligned64_and (a : BitVec 64) : aligned64 (a &&& 0xFFFFFFFFFFFFFFC0#64) = true := by
  simp only [aligned64]; bv_decide

theorem aligned64_sub_256 {a : BitVec 64} (ha : aligned64 a = true) : aligned64 (a - 0x100#64) = true := by
  simp only [aligned64] at ha ⊢; bv_decide

end X86
