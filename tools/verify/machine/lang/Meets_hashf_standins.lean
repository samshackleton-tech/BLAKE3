import Meets_hashf_bytes
import Proof_k32s
import Proof_p16s
open X86

/-! # The fast hash with the stand-ins at the kernels' addresses: BLAKE3, and nothing assumed

`hashf_meets_bytes` (`Meets_hashf_bytes.lean`) holds over any program in which the two wide kernels'
addresses meet their contracts. Here is one such program, wholly inside this machine model: `hashf` and
every function of ours it calls, with `k32s` and `p16s` (proved to meet `K32.contract` and `P16.contract`:
`Proof_k32s.lean`, `Proof_p16s.lean`) at the kernels' addresses. For it the theorem has no hypothesis.

What this says: the contracts the fast path assumes can be met, both; and everything in the fast path but
the two kernels (the groups, the levels, the last group, the root) is right. What it does not say: that
the library's own kernels meet those contracts. That is the part still assumed where `hashf` is linked
with them. -/

/-- The two stand-ins' own instructions, at the kernels' addresses. -/
def Standins.ext (pc : Nat) : Option (Instr × Nat) := (Code_k32s.table.lookup pc).or (Code_p16s.table.lookup pc)

theorem Standins.or_cases {α : Type} {a b : Option α} {x : α} (h : a.or b = some x) : a = some x ∨ (a = none ∧ b = some x) := by
  cases a with
  | none => exact Or.inr ⟨rfl, by simpa using h⟩
  | some y => exact Or.inl (by simpa using h)

/-- `k32s`'s program (its own instructions and those of what it calls) is part of this one. -/
theorem Standins.k32s_in : ∀ pc x, Code_k32s.prog pc = some x → Code_hashf.prog Standins.ext pc = some x := by
  intro pc x h
  have h' : (KCode.table ++ Code_pad.table ++ Code_chunk_node.table ++ Code_node_out.table ++ Code_k32s.table).lookup pc = some x := h
  rw [lookup_append_or] at h'
  rcases Standins.or_cases h' with h1 | ⟨_, h1⟩
  · rw [lookup_append_or] at h1
    rcases Standins.or_cases h1 with h2 | ⟨_, h2⟩
    · rw [lookup_append_or] at h2
      rcases Standins.or_cases h2 with h3 | ⟨_, h3⟩
      · rw [lookup_append_or] at h3
        rcases Standins.or_cases h3 with h4 | ⟨_, h4⟩
        · exact Code_hashf.has_kernels _ pc x h4
        · exact Code_hashf.in6 _ pc x h4
      · exact Code_hashf.in7 _ pc x h3
    · exact Code_hashf.in8 _ pc x h2
  · have apart : ∀ p ∈ Code_k32s.table.map (·.1), ((Code_hashf.whole.lookup p).isNone) = true := by decide +kernel
    have none := Option.isNone_iff_eq_none.mp (apart pc (lookup_mem_keys _ pc x h1))
    show (Code_hashf.whole.lookup pc).or (Standins.ext pc) = some x
    rw [none]; simp only [Option.none_or, Standins.ext, h1, Option.some_or]

/-- `p16s`'s program is part of this one. -/
theorem Standins.p16s_in : ∀ pc x, Code_p16s.prog pc = some x → Code_hashf.prog Standins.ext pc = some x := by
  intro pc x h
  have h' : (KCode.table ++ Code_p16s.table).lookup pc = some x := h
  rw [lookup_append_or] at h'
  rcases Standins.or_cases h' with h1 | ⟨_, h1⟩
  · exact Code_hashf.has_kernels _ pc x h1
  · have apart : ∀ p ∈ Code_p16s.table.map (·.1), ((Code_hashf.whole.lookup p).isNone) = true := by decide +kernel
    have apart2 : ∀ p ∈ Code_p16s.table.map (·.1), ((Code_k32s.table.lookup p).isNone) = true := by decide +kernel
    have none := Option.isNone_iff_eq_none.mp (apart pc (lookup_mem_keys _ pc x h1))
    have none2 := Option.isNone_iff_eq_none.mp (apart2 pc (lookup_mem_keys _ pc x h1))
    show (Code_hashf.whole.lookup pc).or (Standins.ext pc) = some x
    rw [none]; simp only [Option.none_or, Standins.ext, none2, h1]

/-- **`hashf`, with our two stand-ins at the kernels' addresses, computes BLAKE3 for every message**: it
meets `Hash.byteContract` with 40960 bytes of stack. Nothing is assumed. -/
theorem hashf_with_standins (out inp len key plat : BitVec 64) (msg : List (BitVec 8)) :
    Abi.Meets (Code_hashf.prog Standins.ext) 0x1A0000 (Abi.ofBytes (Hash.byteContract out inp len key plat msg) 40960#64) :=
  hashf_meets_bytes Standins.ext
    (fun x0 x1 x2 x3 x4 x5 x6 x7 x8 x9 x10 => Abi.Meets.mono Standins.k32s_in (Proof_k32s.k32s_meets x0 x1 x2 x3 x4 x5 x6 x7 x8 x9 x10))
    (fun x0 x1 x2 x3 x4 x5 x6 x7 x8 x9 x10 => Abi.Meets.mono Standins.p16s_in (Proof_p16s.p16s_meets x0 x1 x2 x3 x4 x5 x6 x7 x8 x9 x10))
    out inp len key plat msg

#print axioms hashf_with_standins
