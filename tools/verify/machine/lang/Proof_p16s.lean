import Cells
import Kernels
import AbiProof
import Spec_p16
import Lemmas_p16s
import Code_p16s
open X86 Cells

/-! # `p16s`, as assembled, meets `P16.contract`

Written by prove_fn.py from levels.ode and the compiler's layout; not edited by hand, and not to be read
but for its last theorem's statement: Lean checks the rest. The frame: 96 bytes below the stack pointer at entry
(`fb` is its lowest address), the caller's rbx, rbp, r12, r13, r14, r15 at its top.
-/

namespace Proof_p16s

set_option maxRecDepth 1000000
set_option maxHeartbeats 0
set_option linter.unusedVariables false

/-- What holds each time the loop's head is reached: the source's `invariant` clauses, each variable where the
compiler keeps it, and the frame as the compiler keeps it. -/
def Inv (fb inputs blocks key counter packed out ra : BitVec 64) (sv : Abi.Saved) (k : Blake3.CV) (base : BitVec 64) (n : BitVec 64) (flags : BitVec 64) (l : List Blake3.CV) (m0 : Mem) (s : State) : Prop :=
  s.pc = 0x1803B ∧
  s.rsp = (fb + 8#64) ∧
  s.r12 = inputs ∧
  s.r15 = blocks ∧
  s.r13 = key ∧
  s.r14 = out ∧
  Region s.mem fb 96#64 ∧
  Quad s.mem (fb + 96#64) ra ∧
  Quad s.mem (fb + 88#64) sv.rbx ∧
  Quad s.mem (fb + 80#64) sv.rbp ∧
  Quad s.mem (fb + 72#64) sv.r12 ∧
  Quad s.mem (fb + 64#64) sv.r13 ∧
  Quad s.mem (fb + 56#64) sv.r14 ∧
  Quad s.mem (fb + 48#64) sv.r15 ∧
  Quad s.mem (fb + 8#64) counter ∧
  Quad s.mem (fb + 16#64) packed ∧
  Abi.WriteApart ((fb, (Abi.Contract.framed (P16.contract inputs blocks key counter packed out k base n flags l) 96#64).stack + 8#64) :: (Abi.Contract.framed (P16.contract inputs blocks key counter packed out k base n flags l) 96#64).modifies) (Abi.Contract.framed (P16.contract inputs blocks key counter packed out k base n flags l) 96#64).reading ∧
  (∀ x : BitVec 64, (Abi.Contract.framed (P16.contract inputs blocks key counter packed out k base n flags l) 96#64).stack + 8#64 ≤ x - fb → (∀ r ∈ (Abi.Contract.framed (P16.contract inputs blocks key counter packed out k base n flags l) 96#64).modifies, r.2 ≤ x - r.1) → s.mem x = m0 x) ∧
  (Abi.Contract.framed (P16.contract inputs blocks key counter packed out k base n flags l) 96#64).accepts ∧
  (Abi.Contract.framed (P16.contract inputs blocks key counter packed out k base n flags l) 96#64).requires m0 ∧
  s.rbp = (packed &&& 255#64) ∧
    P16s.Mid s.mem inputs key out k base n flags l s.rbx

theorem enter (fb inputs blocks key counter packed out ra : BitVec 64) (sv : Abi.Saved) (k : Blake3.CV) (base : BitVec 64) (n : BitVec 64) (flags : BitVec 64) (l : List Blake3.CV) (m0 : Mem)
    (s : State) (hP : Abi.Pre 0x18000 (Abi.Contract.framed (P16.contract inputs blocks key counter packed out k base n flags l) 96#64) fb ra sv m0 s) : ∃ n_ s', steps Code_p16s.prog n_ s = some s' ∧ Inv fb inputs blocks key counter packed out ra sv k base n flags l m0 s' := by
  obtain ⟨rax, rcx, rdx, rbx, rsp, rbp, rsi, rdi, r8, r9, r12, r13, r14, r15, zf, cf, x0, x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12, x13, x14, x15, mem, pc⟩ := s
  obtain ⟨hpc, hsp, hargs, hbx, hbp, h12, h13, h14, h15, hmem, hF, hRa, hAp, hAcc, hReq⟩ := hP
  simp only [P16.contract, Abi.Contract.framed, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true] at hpc hsp hargs hbx hbp h12 h13 h14 h15 hmem hF hRa
  simp only [List.length_cons, List.length_nil, List.take, List.cons.injEq, and_true] at hargs
  obtain ⟨ha0, ha1, ha2, ha3, ha4, ha5⟩ := hargs
  subst pc rsp rdi rsi rdx rcx r8 r9 rbx rbp r12 r13 r14 r15 mem
  have hAp0 := hAp
  simp only [P16.contract, Abi.Contract.framed, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, Abi.WriteApart, Abi.Apart, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, BitVec.reduceAdd] at hAp
  split_ands hAp
  have hAcc0 := hAcc
  try (simp only [P16.contract, Abi.Contract.framed, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true] at hAcc; split_ands hAcc)
  have hReq0 := hReq
  simp only [P16.contract, Abi.Contract.framed, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true] at hReq
  split_ands hReq
  try (have hK0 := P16s.Mid.cells (m := m0) (by assumption); split_ands hK0)
  refine runs_then (a := 18) (s1 := ?_) ?_ ?_
  case refine_2 => run_fn []; rfl
  refine runs_done ⟨rfl, rfl, rfl, rfl, rfl, rfl, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_⟩
  all_goals try dsimp only
  · mem_region
  · mem_fact
  · mem_fact
  · mem_fact
  · mem_fact
  · mem_fact
  · mem_fact
  · mem_fact
  · mem_fact
  · mem_fact
  · exact hAp0
  · intro x hx hmod
    have hx' := hx
    have hmod' := hmod
    simp only [P16.contract, Abi.Contract.framed, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, BitVec.reduceAdd] at hx' hmod'
    first | rfl | mem_away
  · exact hAcc0
  · exact hReq0
  · skip
    refine ⟨?_, ?_⟩
    · rfl
    · apply P16s.Mid.start <;> mem_auto

theorem turn (fb inputs blocks key counter packed out ra : BitVec 64) (sv : Abi.Saved) (k : Blake3.CV) (base : BitVec 64) (n : BitVec 64) (flags : BitVec 64) (l : List Blake3.CV) (m0 : Mem)
    (s : State) (hI : Inv fb inputs blocks key counter packed out ra sv k base n flags l m0 s) (hc : s.rbx < 16#64) :
    ∃ n_ s', steps Code_p16s.prog n_ s = some s' ∧ (Inv fb inputs blocks key counter packed out ra sv k base n flags l m0 s' ∧ ((16#64 - s'.rbx)).toNat < ((16#64 - s.rbx)).toNat) := by
  obtain ⟨rax, rcx, rdx, i, rsp, rbp, rsi, rdi, r8, r9, r12, r13, r14, r15, zf, cf, x0, x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12, x13, x14, x15, mem, pc⟩ := s
  obtain ⟨hpc, hsp, hp0, hp1, hp2, hp3, hF, hRa, hS0, hS1, hS2, hS3, hS4, hS5, hPs0, hPs1, hAp, hOut, hAcc, hReq, hZ0, hI0⟩ := hI
  simp only at hpc hsp hp0 hp1 hp2 hp3 hF hRa hS0 hS1 hS2 hS3 hS4 hS5 hPs0 hPs1 hOut hZ0 hI0 hc
  subst pc rsp r12 r15 r13 r14 rbp
  have hAp0 := hAp
  simp only [P16.contract, Abi.Contract.framed, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, Abi.WriteApart, Abi.Apart, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, BitVec.reduceAdd] at hAp
  split_ands hAp
  have hAcc0 := hAcc
  try (simp only [P16.contract, Abi.Contract.framed, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true] at hAcc; split_ands hAcc)
  have hReq0 := hReq
  simp only [P16.contract, Abi.Contract.framed, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true] at hReq
  split_ands hReq
  forget_about m0 except hOut hReq0
  try (have hK0 := P16s.Mid.cells (m := mem) (by assumption); split_ands hK0)
  have_by hO0 := P16s.Mid.turn (m := mem)
  obtain ⟨k0, k1, a0, a1, b0, b1, hO0⟩ := hO0
  try norm_addr at hO0
  split_ands hO0
  have c0 : (i).ult (16#64) = true := by bv_decide
  refine runs_then (a := 27) (s1 := ?_) ?_ ?_
  case refine_2 => run_fn [c0]; rfl
  refine Kernels.call_avx_runs Code_p16s.has_kernels (by mem_auto) (by mem_auto) (by mem_auto) (by mem_auto) (by mem_auto) (by mem_auto) (by mem_auto) (by mem_auto) ?_
  intro rax' rcx' rdx' rsi' rdi' r8' r9' zf' cf' y0 y1 y2 y3 y4 y5 y6 y7 y8 y9 y10 y11 y12 y13 y14 y15 w'
  refine runs_then (a := 4) (s1 := ?_) ?_ ?_
  case refine_2 => run_fn [c0]; rfl
  refine runs_done ⟨⟨rfl, rfl, rfl, rfl, rfl, rfl, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_⟩, ?_⟩
  all_goals try dsimp only
  · mem_region
  · mem_fact
  · mem_fact
  · mem_fact
  · mem_fact
  · mem_fact
  · mem_fact
  · mem_fact
  · mem_fact
  · mem_fact
  · exact hAp0
  · intro x hx hmod
    refine Eq.trans ?_ (hOut x hx hmod)
    have hx' := hx
    have hmod' := hmod
    simp only [P16.contract, Abi.Contract.framed, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, BitVec.reduceAdd] at hx' hmod'
    first | rfl | mem_away
  · exact hAcc0
  · exact hReq0
  · skip
    refine ⟨?_, ?_⟩
    · rfl
    · apply P16s.Mid.step <;> mem_auto
  · exact BitVec.lt_def.mp (by bv_decide)

theorem leave (fb inputs blocks key counter packed out ra : BitVec 64) (sv : Abi.Saved) (k : Blake3.CV) (base : BitVec 64) (n : BitVec 64) (flags : BitVec 64) (l : List Blake3.CV) (m0 : Mem)
    (s : State) (hI : Inv fb inputs blocks key counter packed out ra sv k base n flags l m0 s) (hc : ¬ s.rbx < 16#64) :
    ∃ n_ s', steps Code_p16s.prog n_ s = some s' ∧ Abi.Post (Abi.Contract.framed (P16.contract inputs blocks key counter packed out k base n flags l) 96#64) fb ra sv m0 s' := by
  obtain ⟨rax, rcx, rdx, i, rsp, rbp, rsi, rdi, r8, r9, r12, r13, r14, r15, zf, cf, x0, x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12, x13, x14, x15, mem, pc⟩ := s
  obtain ⟨hpc, hsp, hp0, hp1, hp2, hp3, hF, hRa, hS0, hS1, hS2, hS3, hS4, hS5, hPs0, hPs1, hAp, hOut, hAcc, hReq, hZ0, hI0⟩ := hI
  simp only at hpc hsp hp0 hp1 hp2 hp3 hF hRa hS0 hS1 hS2 hS3 hS4 hS5 hPs0 hPs1 hOut hZ0 hI0 hc
  subst pc rsp r12 r15 r13 r14 rbp
  have hAp0 := hAp
  simp only [P16.contract, Abi.Contract.framed, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, Abi.WriteApart, Abi.Apart, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, BitVec.reduceAdd] at hAp
  split_ands hAp
  have hAcc0 := hAcc
  try (simp only [P16.contract, Abi.Contract.framed, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true] at hAcc; split_ands hAcc)
  have hReq0 := hReq
  simp only [P16.contract, Abi.Contract.framed, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true] at hReq
  split_ands hReq
  forget_about m0 except hOut hReq0
  try (have hK0 := P16s.Mid.cells (m := mem) (by assumption); split_ands hK0)
  have c0 : (i).ult (16#64) = false := by bv_decide
  refine runs_then (a := 12) (s1 := ?_) ?_ ?_
  case refine_2 => run_fn [c0]; rfl
  refine runs_done ⟨rfl, by simp only [P16.contract, Abi.Contract.framed]; bv_decide, rfl, rfl, rfl, rfl, rfl, rfl, ?_, ?_⟩
  all_goals try dsimp only
  · intro x hx hmod
    refine Eq.trans ?_ (hOut x hx hmod)
    have hx' := hx
    have hmod' := hmod
    simp only [P16.contract, Abi.Contract.framed, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, BitVec.reduceAdd] at hx' hmod'
    first | rfl | mem_away
  · simp only [P16.contract, Abi.Contract.framed, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true]
    apply P16s.exit <;> mem_auto

/-- **`p16s`, as assembled, meets its contract, whatever its arguments.** -/
theorem p16s_meets : ∀ (inputs blocks key counter packed out : BitVec 64) (k : Blake3.CV) (base : BitVec 64) (n : BitVec 64) (flags : BitVec 64) (l : List Blake3.CV),
    Abi.Meets Code_p16s.prog 0x18000 (P16.contract inputs blocks key counter packed out k base n flags l) := by
  intro inputs blocks key counter packed out k base n flags l
  refine Abi.meets_of_triple 96#64 (by dsimp only [P16.contract]; decide) (by dsimp only [P16.contract]; decide) (fun fb ra sv m0 => ?_)
  refine Hoare.seq (Q := Inv fb inputs blocks key counter packed out ra sv k base n flags l m0) ?_ ?_
  · intro s hP
    exact enter fb inputs blocks key counter packed out ra sv k base n flags l m0 s hP
  · refine Hoare.loop (fun s => ((16#64 - s.rbx)).toNat) (fun s hI => ?_)
    by_cases hc : s.rbx < 16#64
    · obtain ⟨n_, s', h, hi, hm⟩ := turn fb inputs blocks key counter packed out ra sv k base n flags l m0 s hI hc
      exact ⟨n_, s', h, Or.inl ⟨hi, hm⟩⟩
    · obtain ⟨n_, s', h, hq⟩ := leave fb inputs blocks key counter packed out ra sv k base n flags l m0 s hI hc
      exact ⟨n_, s', h, Or.inr hq⟩

#print axioms p16s_meets

end Proof_p16s
