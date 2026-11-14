import Meets_hashf_bytes
import Proof_k32s
import Proof_p16
open X86

/-! # The fast hash with the wide AVX-512 parent kernel `p16`: BLAKE3, with only `k32s` as stand-in

`hashf_meets_bytes` (`Meets_hashf_bytes.lean`) holds over any program in which the two wide kernels'
addresses meet their contracts. Here `k32s` (`Proof_k32s.lean`) stands in at `K32`'s address and the
real 460-instruction wide AVX-512 parent kernel `p16` (`Code_p16.lean`, proved in `Proof_p16.lean`) is
at `P16`'s address `0x18000`. -/

/-- `k32s` at `K32`'s address and the real wide `p16` kernel at `P16`'s address. -/
def RealP16.ext (pc : Nat) : Option (Instr × Nat) := (Code_k32s.table.lookup pc).or (Code_p16.table.lookup pc)

theorem RealP16.or_cases {α : Type} {a b : Option α} {x : α} (h : a.or b = some x) : a = some x ∨ (a = none ∧ b = some x) := by
  cases a with
  | none => exact Or.inr ⟨rfl, by simpa using h⟩
  | some y => exact Or.inl (by simpa using h)

/-- `k32s`'s program is part of this one. -/
theorem RealP16.k32s_in : ∀ pc x, Code_k32s.prog pc = some x → Code_hashf.prog RealP16.ext pc = some x := by
  intro pc x h
  have h' : (KCode.table ++ Code_pad.table ++ Code_chunk_node.table ++ Code_node_out.table ++ Code_k32s.table).lookup pc = some x := h
  rw [lookup_append_or] at h'
  rcases RealP16.or_cases h' with h1 | ⟨_, h1⟩
  · rw [lookup_append_or] at h1
    rcases RealP16.or_cases h1 with h2 | ⟨_, h2⟩
    · rw [lookup_append_or] at h2
      rcases RealP16.or_cases h2 with h3 | ⟨_, h3⟩
      · rw [lookup_append_or] at h3
        rcases RealP16.or_cases h3 with h4 | ⟨_, h4⟩
        · exact Code_hashf.has_kernels _ pc x h4
        · exact Code_hashf.in6 _ pc x h4
      · exact Code_hashf.in7 _ pc x h3
    · exact Code_hashf.in8 _ pc x h2
  · have apart : ∀ p ∈ Code_k32s.table.map (·.1), ((Code_hashf.whole.lookup p).isNone) = true := by decide +kernel
    have none := Option.isNone_iff_eq_none.mp (apart pc (lookup_mem_keys _ pc x h1))
    show (Code_hashf.whole.lookup pc).or (RealP16.ext pc) = some x
    rw [none]; simp only [Option.none_or, RealP16.ext, h1, Option.some_or]

private theorem lookup_none_of_forall {α : Type} (t : List (Nat × α)) (p : Nat)
    (h : ∀ x ∈ t, x.1 ≠ p) : t.lookup p = Option.none := by
  induction t with
  | nil => rfl
  | cons hd tl ih =>
    simp only [List.lookup]
    have hne : (p == hd.1) = false := beq_false_of_ne (h hd List.mem_cons_self).symm
    rw [hne]
    exact ih (fun x hx => h x (List.mem_cons_of_mem hd hx))

/-- `p16`'s 460-instruction program is part of this one. -/
theorem RealP16.p16_in : ∀ pc x, Code_p16.prog pc = some x → Code_hashf.prog RealP16.ext pc = some x := by
  intro pc x h
  have h1 : Code_p16.table.lookup pc = some x := h
  have hpc : 0x18000 ≤ pc ∧ pc ≤ 0x18ACF :=
    (by decide +kernel : ∀ y ∈ Code_p16.table.map (·.1), 0x18000 ≤ y ∧ y ≤ 0x18ACF) pc (lookup_mem_keys _ pc x h1)
  have hwhole : ∀ y ∈ Code_hashf.whole, ¬(0x18000 ≤ y.1 ∧ y.1 ≤ 0x18ACF) := by decide +kernel
  have hk32 : ∀ y ∈ Code_k32s.table, ¬(0x18000 ≤ y.1 ∧ y.1 ≤ 0x18ACF) := by decide +kernel
  have hnone : Code_hashf.whole.lookup pc = Option.none :=
    lookup_none_of_forall Code_hashf.whole pc (fun y hy e => hwhole y hy (e ▸ hpc))
  have hnone2 : Code_k32s.table.lookup pc = Option.none :=
    lookup_none_of_forall Code_k32s.table pc (fun y hy e => hk32 y hy (e ▸ hpc))
  show (Code_hashf.whole.lookup pc).or (RealP16.ext pc) = some x
  rw [hnone]; simp only [Option.none_or, RealP16.ext, hnone2, h1]

/-- **`hashf`, with the real wide AVX-512 `p16` kernel and the `k32s` stand-in, computes BLAKE3 for every
message**: it meets `Hash.byteContract` with 40960 bytes of stack. -/
theorem hashf_with_p16 (out inp len key plat : BitVec 64) (msg : List (BitVec 8)) :
    Abi.Meets (Code_hashf.prog RealP16.ext) 0x1A0000 (Abi.ofBytes (Hash.byteContract out inp len key plat msg) 40960#64) :=
  hashf_meets_bytes RealP16.ext
    (fun x0 x1 x2 x3 x4 x5 x6 x7 x8 x9 x10 => Abi.Meets.mono RealP16.k32s_in (Proof_k32s.k32s_meets x0 x1 x2 x3 x4 x5 x6 x7 x8 x9 x10))
    (fun x0 x1 x2 x3 x4 x5 x6 x7 x8 x9 x10 => Abi.Meets.mono RealP16.p16_in (Proof_p16.p16_meets x0 x1 x2 x3 x4 x5 x6 x7 x8 x9 x10))
    out inp len key plat msg

#print axioms hashf_with_p16
