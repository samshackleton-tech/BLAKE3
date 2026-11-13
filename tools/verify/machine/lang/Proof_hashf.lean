import Cells
import Kernels
import AbiProof
import AbiCall
import Spec_hashf
import Lemmas_hashw
import Proof_hashw
import Proof_hashl
import Code_hashf
open X86 Cells

/-! # `hashf`, as assembled, meets `Hashf.contract`

Written by prove_fn.py from levels.ode and the compiler's layout; not edited by hand, and not to be read
but for its last theorem's statement: Lean checks the rest. The frame: 32832 bytes below the stack pointer at entry
(`fb` is its lowest address), the caller's rbx, rbp, r12, r13, r14, r15 at its top.
-/

namespace Proof_hashf

set_option maxRecDepth 1000000
set_option maxHeartbeats 0
set_option linter.unusedVariables false

theorem whole (ext : Nat → Option (Instr × Nat)) (hA_chunks32 : ∀ x0 x1 x2 x3 x4 x5 x6 x7 x8 x9 x10, Abi.Meets (Code_hashf.prog ext) 0x10000 (K32.contract x0 x1 x2 x3 x4 x5 x6 x7 x8 x9 x10)) (hA_parents16 : ∀ x0 x1 x2 x3 x4 x5 x6 x7 x8 x9 x10, Abi.Meets (Code_hashf.prog ext) 0x18000 (P16.contract x0 x1 x2 x3 x4 x5 x6 x7 x8 x9 x10)) (fb out input len key flags plat ra : BitVec 64) (sv : Abi.Saved) (k : Blake3.CV) (bytes : List (BitVec 8)) (m0 : Mem)
    (s : State) (hP : Abi.Pre 0x1A0000 (Abi.Contract.framed (Hashf.contract out input len key flags plat k bytes) 32832#64) fb ra sv m0 s) : ∃ n_ s', steps (Code_hashf.prog ext) n_ s = some s' ∧ Abi.Post (Abi.Contract.framed (Hashf.contract out input len key flags plat k bytes) 32832#64) fb ra sv m0 s' := by
  obtain ⟨rax, rcx, rdx, rbx, rsp, rbp, rsi, rdi, r8, r9, r12, r13, r14, r15, zf, cf, x0, x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12, x13, x14, x15, mem, pc⟩ := s
  obtain ⟨hpc, hsp, hargs, hbx, hbp, h12, h13, h14, h15, hmem, hF, hRa, hAp, hAcc, hReq⟩ := hP
  simp only [Hashf.contract, Abi.Contract.framed, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true] at hpc hsp hargs hbx hbp h12 h13 h14 h15 hmem hF hRa
  simp only [List.length_cons, List.length_nil, List.take, List.cons.injEq, and_true] at hargs
  obtain ⟨ha0, ha1, ha2, ha3, ha4, ha5⟩ := hargs
  subst pc rsp rdi rsi rdx rcx r8 r9 rbx rbp r12 r13 r14 r15 mem
  have hAp0 := hAp
  simp only [Hashf.contract, Abi.Contract.framed, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, Abi.AllApart, Abi.Apart, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, BitVec.reduceAdd] at hAp
  split_ands hAp
  have hAcc0 := hAcc
  try (simp only [Hashf.contract, Abi.Contract.framed, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true] at hAcc; split_ands hAcc)
  have hReq0 := hReq
  simp only [Hashf.contract, Abi.Contract.framed, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true] at hReq
  split_ands hReq
  have_by hE0 := Hashw.msg (m := m0)
  try norm_addr at hE0
  split_ands hE0
  by_cases hs0 : plat = 5#64
  · have c0 : (plat - 5#64 == 0#64) = true := by bv_decide
    refine runs_then (a := 23) (s1 := ?_) ?_ ?_
    case refine_2 => run_fn [c0]; rfl
    have_by hN1_0 := Hashw.same (m := m0)
    try norm_addr at hN1_0
    split_ands hN1_0
    refine Abi.call_meets (c := Hashw.contract out input len key flags k bytes) (ra := 1704003#64)
      (Abi.Meets.mono (Code_hashf.has_hashw ext) (Proof_hashw.hashw_meets (Code_hashf.prog ext) (fun x0 x1 x2 x3 x4 x5 x6 x7 x8 x9 x10 => Abi.Meets.mono (Code_hashf.over_hashw ext) (hA_chunks32 x0 x1 x2 x3 x4 x5 x6 x7 x8 x9 x10)) (fun x0 x1 x2 x3 x4 x5 x6 x7 x8 x9 x10 => Abi.Meets.mono (Code_hashf.over_hashw ext) (hA_parents16 x0 x1 x2 x3 x4 x5 x6 x7 x8 x9 x10)) out input len key flags k bytes)) rfl rfl ?_ ?_ ?_ ?_ ?_ ?_
    · dsimp only; mem_fact
    · dsimp only [Hashw.contract]; mem_subregion
    · dsimp only
      simp only [Hashw.contract, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, Abi.AllApart, Abi.Apart, BitVec.reduceAdd]
      try simp only [add_sub_lit, BitVec.add_assoc, BitVec.add_zero, BitVec.reduceAdd, BitVec.reduceSub]
      repeat' (with_reducible apply And.intro)
      all_goals bv_side
    · simp only [Hashw.contract]
      repeat' (with_reducible apply And.intro)
      all_goals (first | assumption | bv_side)
    · dsimp only
      simp only [Hashw.contract, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true]
      repeat' (with_reducible apply And.intro)
      all_goals (first | mem_auto | (apply_frame <;> mem_auto) | (apply_intro <;> first | mem_auto | (apply_frame <;> mem_auto)))
    · intro s1 hpc1 hsp1 hbx1 hbp1 h12_1 h13_1 h14_1 h15_1 hens1 hout1 hown1
      obtain ⟨rax_1, rcx_1, rdx_1, rbx_1, rsp_1, rbp_1, rsi_1, rdi_1, r8_1, r9_1, r12_1, r13_1, r14_1, r15_1, zf_1, cf_1, y1_0, y1_1, y1_2, y1_3, y1_4, y1_5, y1_6, y1_7, y1_8, y1_9, y1_10, y1_11, y1_12, y1_13, y1_14, y1_15, mem1, pc_1⟩ := s1
      dsimp only at hpc1 hsp1 hbx1 hbp1 h12_1 h13_1 h14_1 h15_1 hens1 hout1 hown1
      subst pc_1 rsp_1 rbx_1 rbp_1 r12_1 r13_1 r14_1 r15_1
      simp only [Hashw.contract, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true] at hens1
      split_ands hens1
      simp only [Hashw.contract, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, add_sub_lit, BitVec.add_assoc, BitVec.add_zero, BitVec.reduceAdd, BitVec.reduceSub] at hout1
      have hF1 : Region mem1 fb 32832#64 := hown1 fb 32832#64 (by mem_region)
      have hS1_0 : Quad mem1 (fb + 32832#64) ra := X86.Quad.frame (by mem_fact) (fun x hx => hout1 x (by bv_decide) (by bv_decide))
      have hS1_1 : Quad mem1 (fb + 32824#64) sv.rbx := X86.Quad.frame (by mem_fact) (fun x hx => hout1 x (by bv_decide) (by bv_decide))
      have hS1_2 : Quad mem1 (fb + 32816#64) sv.rbp := X86.Quad.frame (by mem_fact) (fun x hx => hout1 x (by bv_decide) (by bv_decide))
      have hS1_3 : Quad mem1 (fb + 32808#64) sv.r12 := X86.Quad.frame (by mem_fact) (fun x hx => hout1 x (by bv_decide) (by bv_decide))
      have hS1_4 : Quad mem1 (fb + 32800#64) sv.r13 := X86.Quad.frame (by mem_fact) (fun x hx => hout1 x (by bv_decide) (by bv_decide))
      have hS1_5 : Quad mem1 (fb + 32792#64) sv.r14 := X86.Quad.frame (by mem_fact) (fun x hx => hout1 x (by bv_decide) (by bv_decide))
      have hS1_6 : Quad mem1 (fb + 32784#64) sv.r15 := X86.Quad.frame (by mem_fact) (fun x hx => hout1 x (by bv_decide) (by bv_decide))
      have hOut : (∀ x : BitVec 64, (Abi.Contract.framed (Hashf.contract out input len key flags plat k bytes) 32832#64).stack + 8#64 ≤ x - fb → (∀ r ∈ (Abi.Contract.framed (Hashf.contract out input len key flags plat k bytes) 32832#64).modifies, r.2 ≤ x - r.1) → mem1 x = m0 x) := by
        intro x hx hmod
        have hx' := hx
        have hmod' := hmod
        simp only [Hashf.contract, Abi.Contract.framed, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, BitVec.reduceAdd] at hx' hmod'
        rw [hout1 x (by bv_decide) (by bv_decide)]
        first | rfl | mem_away
      clear hout1 hown1
      refine runs_then (a := 9) (s1 := ?_) ?_ ?_
      case refine_2 => run_fn [c0]; rfl
      refine runs_done ⟨rfl, by simp only [Hashf.contract, Abi.Contract.framed]; bv_decide, rfl, rfl, rfl, rfl, rfl, rfl, ?_, ?_⟩
      all_goals try dsimp only
      · intro x hx hmod
        refine Eq.trans ?_ (hOut x hx hmod)
        have hx' := hx
        have hmod' := hmod
        simp only [Hashf.contract, Abi.Contract.framed, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, BitVec.reduceAdd] at hx' hmod'
        first | rfl | mem_away
      · simp only [Hashf.contract, Abi.Contract.framed, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true]
        apply Hashl.exit <;> mem_auto
  · have c0 : (plat - 5#64 == 0#64) = false := by bv_decide
    refine runs_then (a := 24) (s1 := ?_) ?_ ?_
    case refine_2 => run_fn [c0]; rfl
    have_by hN1_0 := Hashw.same (m := m0)
    try norm_addr at hN1_0
    split_ands hN1_0
    refine Abi.call_meets (c := Hashl.contract out input len key flags plat k bytes) (ra := 1704028#64)
      (Abi.Meets.mono (Code_hashf.has_hashl ext) (Proof_hashl.hashl_meets out input len key flags plat k bytes)) rfl rfl ?_ ?_ ?_ ?_ ?_ ?_
    · dsimp only; mem_fact
    · dsimp only [Hashl.contract]; mem_subregion
    · dsimp only
      simp only [Hashl.contract, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, Abi.AllApart, Abi.Apart, BitVec.reduceAdd]
      try simp only [add_sub_lit, BitVec.add_assoc, BitVec.add_zero, BitVec.reduceAdd, BitVec.reduceSub]
      repeat' (with_reducible apply And.intro)
      all_goals bv_side
    · simp only [Hashl.contract]
      repeat' (with_reducible apply And.intro)
      all_goals (first | assumption | bv_side)
    · dsimp only
      simp only [Hashl.contract, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true]
      repeat' (with_reducible apply And.intro)
      all_goals (first | mem_auto | (apply_frame <;> mem_auto) | (apply_intro <;> first | mem_auto | (apply_frame <;> mem_auto)))
    · intro s1 hpc1 hsp1 hbx1 hbp1 h12_1 h13_1 h14_1 h15_1 hens1 hout1 hown1
      obtain ⟨rax_1, rcx_1, rdx_1, rbx_1, rsp_1, rbp_1, rsi_1, rdi_1, r8_1, r9_1, r12_1, r13_1, r14_1, r15_1, zf_1, cf_1, y1_0, y1_1, y1_2, y1_3, y1_4, y1_5, y1_6, y1_7, y1_8, y1_9, y1_10, y1_11, y1_12, y1_13, y1_14, y1_15, mem1, pc_1⟩ := s1
      dsimp only at hpc1 hsp1 hbx1 hbp1 h12_1 h13_1 h14_1 h15_1 hens1 hout1 hown1
      subst pc_1 rsp_1 rbx_1 rbp_1 r12_1 r13_1 r14_1 r15_1
      simp only [Hashl.contract, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true] at hens1
      split_ands hens1
      simp only [Hashl.contract, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, add_sub_lit, BitVec.add_assoc, BitVec.add_zero, BitVec.reduceAdd, BitVec.reduceSub] at hout1
      have hF1 : Region mem1 fb 32832#64 := hown1 fb 32832#64 (by mem_region)
      have hS1_0 : Quad mem1 (fb + 32832#64) ra := X86.Quad.frame (by mem_fact) (fun x hx => hout1 x (by bv_decide) (by bv_decide))
      have hS1_1 : Quad mem1 (fb + 32824#64) sv.rbx := X86.Quad.frame (by mem_fact) (fun x hx => hout1 x (by bv_decide) (by bv_decide))
      have hS1_2 : Quad mem1 (fb + 32816#64) sv.rbp := X86.Quad.frame (by mem_fact) (fun x hx => hout1 x (by bv_decide) (by bv_decide))
      have hS1_3 : Quad mem1 (fb + 32808#64) sv.r12 := X86.Quad.frame (by mem_fact) (fun x hx => hout1 x (by bv_decide) (by bv_decide))
      have hS1_4 : Quad mem1 (fb + 32800#64) sv.r13 := X86.Quad.frame (by mem_fact) (fun x hx => hout1 x (by bv_decide) (by bv_decide))
      have hS1_5 : Quad mem1 (fb + 32792#64) sv.r14 := X86.Quad.frame (by mem_fact) (fun x hx => hout1 x (by bv_decide) (by bv_decide))
      have hS1_6 : Quad mem1 (fb + 32784#64) sv.r15 := X86.Quad.frame (by mem_fact) (fun x hx => hout1 x (by bv_decide) (by bv_decide))
      have hOut : (∀ x : BitVec 64, (Abi.Contract.framed (Hashf.contract out input len key flags plat k bytes) 32832#64).stack + 8#64 ≤ x - fb → (∀ r ∈ (Abi.Contract.framed (Hashf.contract out input len key flags plat k bytes) 32832#64).modifies, r.2 ≤ x - r.1) → mem1 x = m0 x) := by
        intro x hx hmod
        have hx' := hx
        have hmod' := hmod
        simp only [Hashf.contract, Abi.Contract.framed, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, BitVec.reduceAdd] at hx' hmod'
        rw [hout1 x (by bv_decide) (by bv_decide)]
        first | rfl | mem_away
      clear hout1 hown1
      refine runs_then (a := 8) (s1 := ?_) ?_ ?_
      case refine_2 => run_fn [c0]; rfl
      refine runs_done ⟨rfl, by simp only [Hashf.contract, Abi.Contract.framed]; bv_decide, rfl, rfl, rfl, rfl, rfl, rfl, ?_, ?_⟩
      all_goals try dsimp only
      · intro x hx hmod
        refine Eq.trans ?_ (hOut x hx hmod)
        have hx' := hx
        have hmod' := hmod
        simp only [Hashf.contract, Abi.Contract.framed, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, BitVec.reduceAdd] at hx' hmod'
        first | rfl | mem_away
      · simp only [Hashf.contract, Abi.Contract.framed, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true]
        apply Hashl.exit <;> mem_auto

/-- **`hashf`, as assembled, meets its contract, whatever its arguments.** -/
theorem hashf_meets (ext : Nat → Option (Instr × Nat)) (hA_chunks32 : ∀ x0 x1 x2 x3 x4 x5 x6 x7 x8 x9 x10, Abi.Meets (Code_hashf.prog ext) 0x10000 (K32.contract x0 x1 x2 x3 x4 x5 x6 x7 x8 x9 x10)) (hA_parents16 : ∀ x0 x1 x2 x3 x4 x5 x6 x7 x8 x9 x10, Abi.Meets (Code_hashf.prog ext) 0x18000 (P16.contract x0 x1 x2 x3 x4 x5 x6 x7 x8 x9 x10)) : ∀ (out input len key flags plat : BitVec 64) (k : Blake3.CV) (bytes : List (BitVec 8)),
    Abi.Meets (Code_hashf.prog ext) 0x1A0000 (Hashf.contract out input len key flags plat k bytes) := by
  intro out input len key flags plat k bytes
  refine Abi.meets_of_triple 32832#64 (by dsimp only [Hashf.contract]; decide) (by dsimp only [Hashf.contract]; decide) (fun fb ra sv m0 => ?_)
  intro s hP
  exact whole ext hA_chunks32 hA_parents16 fb out input len key flags plat ra sv k bytes m0 s hP

#print axioms hashf_meets

end Proof_hashf
