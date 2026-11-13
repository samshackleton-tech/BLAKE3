import Cells
import Kernels
import AbiProof
import AbiCall
import Spec_finish
import Lemmas_finish
import Proof_lroot
import Proof_ladd
import Code_finish
open X86 Cells

/-! # `finish`, as assembled, meets `Finish.contract`

Written by prove_fn.py from levels.ode and the compiler's layout; not edited by hand, and not to be read
but for its last theorem's statement: Lean checks the rest. The frame: 352 bytes below the stack pointer at entry
(`fb` is its lowest address), the caller's rbx, rbp, r12, r13, r14, r15 at its top.
-/

namespace Proof_finish

set_option maxRecDepth 1000000
set_option maxHeartbeats 0
set_option linter.unusedVariables false

theorem whole (fb out wl lv key flags sel ra : BitVec 64) (sv : Abi.Saved) (k : Blake3.CV) (units : Array Blake3.Node) (tail : Array Blake3.Node) (m0 : Mem)
    (s : State) (hP : Abi.Pre 0x170000 (Abi.Contract.framed (Finish.contract out wl lv key flags sel k units tail) 352#64) fb ra sv m0 s) : ∃ n_ s', steps Code_finish.prog n_ s = some s' ∧ Abi.Post (Abi.Contract.framed (Finish.contract out wl lv key flags sel k units tail) 352#64) fb ra sv m0 s' := by
  obtain ⟨rax, rcx, rdx, rbx, rsp, rbp, rsi, rdi, r8, r9, r12, r13, r14, r15, zf, cf, x0, x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12, x13, x14, x15, mem, pc⟩ := s
  obtain ⟨hpc, hsp, hargs, hbx, hbp, h12, h13, h14, h15, hmem, hF, hRa, hAp, hAcc, hReq⟩ := hP
  simp only [Finish.contract, Abi.Contract.framed, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true] at hpc hsp hargs hbx hbp h12 h13 h14 h15 hmem hF hRa
  simp only [List.length_cons, List.length_nil, List.take, List.cons.injEq, and_true] at hargs
  obtain ⟨ha0, ha1, ha2, ha3, ha4, ha5⟩ := hargs
  subst pc rsp rdi rsi rdx rcx r8 r9 rbx rbp r12 r13 r14 r15 mem
  have hAp0 := hAp
  simp only [Finish.contract, Abi.Contract.framed, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, Abi.AllApart, Abi.Apart, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, BitVec.reduceAdd] at hAp
  split_ands hAp
  have hAcc0 := hAcc
  try (simp only [Finish.contract, Abi.Contract.framed, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true] at hAcc; split_ands hAcc)
  have hReq0 := hReq
  simp only [Finish.contract, Abi.Contract.framed, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true] at hReq
  split_ands hReq
  by_cases hs0 : sel = 0#64
  · have c0 : (sel - 0#64 == 0#64) = true := by bv_decide
    refine runs_then (a := 27) (s1 := ?_) ?_ ?_
    case refine_2 => run_fn [c0]; rfl
    have_by hN1_0 := Finish.none (m := m0)
    try norm_addr at hN1_0
    split_ands hN1_0
    refine Abi.call_meets (c := Lroot.contract out lv key flags 5#64 8#64 k tail) (ra := 1507418#64)
      (Abi.Meets.mono Code_finish.has_lroot (Proof_lroot.lroot_meets out lv key flags 5#64 8#64 k tail)) rfl rfl ?_ ?_ ?_ ?_ ?_ ?_
    · dsimp only; mem_fact
    · dsimp only [Lroot.contract]; mem_subregion
    · dsimp only
      simp only [Lroot.contract, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, Abi.AllApart, Abi.Apart, BitVec.reduceAdd]
      try simp only [add_sub_lit, BitVec.add_assoc, BitVec.add_zero, BitVec.reduceAdd, BitVec.reduceSub]
      repeat' (with_reducible apply And.intro)
      all_goals bv_side
    · simp only [Lroot.contract]
      repeat' (with_reducible apply And.intro)
      all_goals (first | assumption | bv_side)
    · dsimp only
      simp only [Lroot.contract, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true]
      repeat' (with_reducible apply And.intro)
      all_goals (first | mem_auto | (apply_frame <;> mem_auto) | (apply_intro <;> first | mem_auto | (apply_frame <;> mem_auto)))
    · intro s1 hpc1 hsp1 hbx1 hbp1 h12_1 h13_1 h14_1 h15_1 hens1 hout1 hown1
      obtain ⟨rax_1, rcx_1, rdx_1, rbx_1, rsp_1, rbp_1, rsi_1, rdi_1, r8_1, r9_1, r12_1, r13_1, r14_1, r15_1, zf_1, cf_1, y1_0, y1_1, y1_2, y1_3, y1_4, y1_5, y1_6, y1_7, y1_8, y1_9, y1_10, y1_11, y1_12, y1_13, y1_14, y1_15, mem1, pc_1⟩ := s1
      dsimp only at hpc1 hsp1 hbx1 hbp1 h12_1 h13_1 h14_1 h15_1 hens1 hout1 hown1
      subst pc_1 rsp_1 rbx_1 rbp_1 r12_1 r13_1 r14_1 r15_1
      simp only [Lroot.contract, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true] at hens1
      split_ands hens1
      simp only [Lroot.contract, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, add_sub_lit, BitVec.add_assoc, BitVec.add_zero, BitVec.reduceAdd, BitVec.reduceSub] at hout1
      have hF1 : Region mem1 fb 352#64 := hown1 fb 352#64 (by mem_region)
      have hS1_0 : Quad mem1 (fb + 352#64) ra := X86.Quad.frame (by mem_fact) (fun x hx => hout1 x (by bv_decide) (by bv_decide))
      have hS1_1 : Quad mem1 (fb + 344#64) sv.rbx := X86.Quad.frame (by mem_fact) (fun x hx => hout1 x (by bv_decide) (by bv_decide))
      have hS1_2 : Quad mem1 (fb + 336#64) sv.rbp := X86.Quad.frame (by mem_fact) (fun x hx => hout1 x (by bv_decide) (by bv_decide))
      have hS1_3 : Quad mem1 (fb + 328#64) sv.r12 := X86.Quad.frame (by mem_fact) (fun x hx => hout1 x (by bv_decide) (by bv_decide))
      have hS1_4 : Quad mem1 (fb + 320#64) sv.r13 := X86.Quad.frame (by mem_fact) (fun x hx => hout1 x (by bv_decide) (by bv_decide))
      have hS1_5 : Quad mem1 (fb + 312#64) sv.r14 := X86.Quad.frame (by mem_fact) (fun x hx => hout1 x (by bv_decide) (by bv_decide))
      have hS1_6 : Quad mem1 (fb + 304#64) sv.r15 := X86.Quad.frame (by mem_fact) (fun x hx => hout1 x (by bv_decide) (by bv_decide))
      have hS1_7 : Quad mem1 (fb + 296#64) (lv + 64#64) := X86.Quad.frame (by mem_fact) (fun x hx => hout1 x (by bv_decide) (by bv_decide))
      have hK1_0 : Hash.Lv mem1 wl k flags units := Hash.Lv.frame (m := m0) (by assumption) (fun x hx => by rw [hout1 x (by bv_decide) (by bv_decide)]; first | rfl | mem_away)
      have hOut : (∀ x : BitVec 64, (Abi.Contract.framed (Finish.contract out wl lv key flags sel k units tail) 352#64).stack + 8#64 ≤ x - fb → (∀ r ∈ (Abi.Contract.framed (Finish.contract out wl lv key flags sel k units tail) 352#64).modifies, r.2 ≤ x - r.1) → mem1 x = m0 x) := by
        intro x hx hmod
        have hx' := hx
        have hmod' := hmod
        simp only [Finish.contract, Abi.Contract.framed, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, BitVec.reduceAdd] at hx' hmod'
        rw [hout1 x (by bv_decide) (by bv_decide)]
        first | rfl | mem_away
      clear hout1 hown1
      refine runs_then (a := 9) (s1 := ?_) ?_ ?_
      case refine_2 => run_fn [c0]; rfl
      refine runs_done ⟨rfl, by simp only [Finish.contract, Abi.Contract.framed]; bv_decide, rfl, rfl, rfl, rfl, rfl, rfl, ?_, ?_⟩
      all_goals try dsimp only
      · intro x hx hmod
        refine Eq.trans ?_ (hOut x hx hmod)
        have hx' := hx
        have hmod' := hmod
        simp only [Finish.contract, Abi.Contract.framed, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, BitVec.reduceAdd] at hx' hmod'
        first | rfl | mem_away
      · simp only [Finish.contract, Abi.Contract.framed, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true]
        apply Finish.exit <;> mem_auto
  · by_cases hs1 : sel = 1#64
    · have c0 : (sel - 0#64 == 0#64) = false := by bv_decide
      have c1 : (sel - 1#64 == 0#64) = true := by bv_decide
      refine runs_then (a := 30) (s1 := ?_) ?_ ?_
      case refine_2 => run_fn [c0, c1]; rfl
      have_by hN1_0 := Finish.one (m := m0)
      try norm_addr at hN1_0
      split_ands hN1_0
      refine Abi.call_meets (c := Ladd.contract wl key flags 5#64 (lv + 64#64) k units (tail[0]!)) (ra := 1507464#64)
        (Abi.Meets.mono Code_finish.has_ladd (Proof_ladd.ladd_meets wl key flags 5#64 (lv + 64#64) k units (tail[0]!))) rfl rfl ?_ ?_ ?_ ?_ ?_ ?_
      · dsimp only; mem_fact
      · dsimp only [Ladd.contract]; mem_subregion
      · dsimp only
        simp only [Ladd.contract, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, Abi.AllApart, Abi.Apart, BitVec.reduceAdd]
        try simp only [add_sub_lit, BitVec.add_assoc, BitVec.add_zero, BitVec.reduceAdd, BitVec.reduceSub]
        repeat' (with_reducible apply And.intro)
        all_goals bv_side
      · simp only [Ladd.contract]
        repeat' (with_reducible apply And.intro)
        all_goals (first | assumption | bv_side)
      · dsimp only
        simp only [Ladd.contract, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true]
        repeat' (with_reducible apply And.intro)
        all_goals (first | mem_auto | (apply_frame <;> mem_auto) | (apply_intro <;> first | mem_auto | (apply_frame <;> mem_auto)))
      · intro s1 hpc1 hsp1 hbx1 hbp1 h12_1 h13_1 h14_1 h15_1 hens1 hout1 hown1
        obtain ⟨rax_1, rcx_1, rdx_1, rbx_1, rsp_1, rbp_1, rsi_1, rdi_1, r8_1, r9_1, r12_1, r13_1, r14_1, r15_1, zf_1, cf_1, y1_0, y1_1, y1_2, y1_3, y1_4, y1_5, y1_6, y1_7, y1_8, y1_9, y1_10, y1_11, y1_12, y1_13, y1_14, y1_15, mem1, pc_1⟩ := s1
        dsimp only at hpc1 hsp1 hbx1 hbp1 h12_1 h13_1 h14_1 h15_1 hens1 hout1 hown1
        subst pc_1 rsp_1 rbx_1 rbp_1 r12_1 r13_1 r14_1 r15_1
        simp only [Ladd.contract, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true] at hens1
        split_ands hens1
        simp only [Ladd.contract, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, add_sub_lit, BitVec.add_assoc, BitVec.add_zero, BitVec.reduceAdd, BitVec.reduceSub] at hout1
        have hF1 : Region mem1 fb 352#64 := hown1 fb 352#64 (by mem_region)
        have hS1_0 : Quad mem1 (fb + 352#64) ra := X86.Quad.frame (by mem_fact) (fun x hx => hout1 x (by bv_decide) (by bv_decide))
        have hS1_1 : Quad mem1 (fb + 344#64) sv.rbx := X86.Quad.frame (by mem_fact) (fun x hx => hout1 x (by bv_decide) (by bv_decide))
        have hS1_2 : Quad mem1 (fb + 336#64) sv.rbp := X86.Quad.frame (by mem_fact) (fun x hx => hout1 x (by bv_decide) (by bv_decide))
        have hS1_3 : Quad mem1 (fb + 328#64) sv.r12 := X86.Quad.frame (by mem_fact) (fun x hx => hout1 x (by bv_decide) (by bv_decide))
        have hS1_4 : Quad mem1 (fb + 320#64) sv.r13 := X86.Quad.frame (by mem_fact) (fun x hx => hout1 x (by bv_decide) (by bv_decide))
        have hS1_5 : Quad mem1 (fb + 312#64) sv.r14 := X86.Quad.frame (by mem_fact) (fun x hx => hout1 x (by bv_decide) (by bv_decide))
        have hS1_6 : Quad mem1 (fb + 304#64) sv.r15 := X86.Quad.frame (by mem_fact) (fun x hx => hout1 x (by bv_decide) (by bv_decide))
        have hS1_7 : Quad mem1 (fb + 296#64) (lv + 64#64) := X86.Quad.frame (by mem_fact) (fun x hx => hout1 x (by bv_decide) (by bv_decide))
        have hK1_0 : Cv.At mem1 key k := Cv.At.frame (m := m0) (by assumption) (fun x hx => by rw [hout1 x (by bv_decide) (by bv_decide)]; first | rfl | mem_away)
        have hK1_1 : Region mem1 out 32#64 := hown1 _ _ (by mem_region)
        have hOut : (∀ x : BitVec 64, (Abi.Contract.framed (Finish.contract out wl lv key flags sel k units tail) 352#64).stack + 8#64 ≤ x - fb → (∀ r ∈ (Abi.Contract.framed (Finish.contract out wl lv key flags sel k units tail) 352#64).modifies, r.2 ≤ x - r.1) → mem1 x = m0 x) := by
          intro x hx hmod
          have hx' := hx
          have hmod' := hmod
          simp only [Finish.contract, Abi.Contract.framed, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, BitVec.reduceAdd] at hx' hmod'
          rw [hout1 x (by bv_decide) (by bv_decide)]
          first | rfl | mem_away
        clear hout1 hown1
        refine runs_then (a := 7) (s1 := ?_) ?_ ?_
        case refine_2 => run_fn [c0, c1]; rfl
        have_by hN2_0 := Finish.one_root (m := mem1)
        try norm_addr at hN2_0
        split_ands hN2_0
        refine Abi.call_meets (c := Lroot.contract out wl key flags 5#64 8#64 k (Finish.w1 units tail)) (ra := 1507495#64)
          (Abi.Meets.mono Code_finish.has_lroot (Proof_lroot.lroot_meets out wl key flags 5#64 8#64 k (Finish.w1 units tail))) rfl rfl ?_ ?_ ?_ ?_ ?_ ?_
        · dsimp only; mem_fact
        · dsimp only [Lroot.contract]; mem_subregion
        · dsimp only
          simp only [Lroot.contract, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, Abi.AllApart, Abi.Apart, BitVec.reduceAdd]
          try simp only [add_sub_lit, BitVec.add_assoc, BitVec.add_zero, BitVec.reduceAdd, BitVec.reduceSub]
          repeat' (with_reducible apply And.intro)
          all_goals bv_side
        · simp only [Lroot.contract]
          repeat' (with_reducible apply And.intro)
          all_goals (first | assumption | bv_side)
        · dsimp only
          simp only [Lroot.contract, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true]
          repeat' (with_reducible apply And.intro)
          all_goals (first | mem_auto | (apply_frame <;> mem_auto) | (apply_intro <;> first | mem_auto | (apply_frame <;> mem_auto)))
        · intro s2 hpc2 hsp2 hbx2 hbp2 h12_2 h13_2 h14_2 h15_2 hens2 hout2 hown2
          obtain ⟨rax_2, rcx_2, rdx_2, rbx_2, rsp_2, rbp_2, rsi_2, rdi_2, r8_2, r9_2, r12_2, r13_2, r14_2, r15_2, zf_2, cf_2, y2_0, y2_1, y2_2, y2_3, y2_4, y2_5, y2_6, y2_7, y2_8, y2_9, y2_10, y2_11, y2_12, y2_13, y2_14, y2_15, mem2, pc_2⟩ := s2
          dsimp only at hpc2 hsp2 hbx2 hbp2 h12_2 h13_2 h14_2 h15_2 hens2 hout2 hown2
          subst pc_2 rsp_2 rbx_2 rbp_2 r12_2 r13_2 r14_2 r15_2
          simp only [Lroot.contract, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true] at hens2
          split_ands hens2
          simp only [Lroot.contract, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, add_sub_lit, BitVec.add_assoc, BitVec.add_zero, BitVec.reduceAdd, BitVec.reduceSub] at hout2
          have hF2 : Region mem2 fb 352#64 := hown2 fb 352#64 (by mem_region)
          have hS2_0 : Quad mem2 (fb + 352#64) ra := X86.Quad.frame (by mem_fact) (fun x hx => hout2 x (by bv_decide) (by bv_decide))
          have hS2_1 : Quad mem2 (fb + 344#64) sv.rbx := X86.Quad.frame (by mem_fact) (fun x hx => hout2 x (by bv_decide) (by bv_decide))
          have hS2_2 : Quad mem2 (fb + 336#64) sv.rbp := X86.Quad.frame (by mem_fact) (fun x hx => hout2 x (by bv_decide) (by bv_decide))
          have hS2_3 : Quad mem2 (fb + 328#64) sv.r12 := X86.Quad.frame (by mem_fact) (fun x hx => hout2 x (by bv_decide) (by bv_decide))
          have hS2_4 : Quad mem2 (fb + 320#64) sv.r13 := X86.Quad.frame (by mem_fact) (fun x hx => hout2 x (by bv_decide) (by bv_decide))
          have hS2_5 : Quad mem2 (fb + 312#64) sv.r14 := X86.Quad.frame (by mem_fact) (fun x hx => hout2 x (by bv_decide) (by bv_decide))
          have hS2_6 : Quad mem2 (fb + 304#64) sv.r15 := X86.Quad.frame (by mem_fact) (fun x hx => hout2 x (by bv_decide) (by bv_decide))
          have hS2_7 : Quad mem2 (fb + 296#64) (lv + 64#64) := X86.Quad.frame (by mem_fact) (fun x hx => hout2 x (by bv_decide) (by bv_decide))
          have hK2_0 : Hash.Lv mem2 wl k flags (Finish.w1 units tail) := Hash.Lv.frame (m := mem1) (by assumption) (fun x hx => by rw [hout2 x (by bv_decide) (by bv_decide)]; first | rfl | mem_away)
          have hOut : (∀ x : BitVec 64, (Abi.Contract.framed (Finish.contract out wl lv key flags sel k units tail) 352#64).stack + 8#64 ≤ x - fb → (∀ r ∈ (Abi.Contract.framed (Finish.contract out wl lv key flags sel k units tail) 352#64).modifies, r.2 ≤ x - r.1) → mem2 x = m0 x) := by
            intro x hx hmod
            have hx' := hx
            have hmod' := hmod
            simp only [Finish.contract, Abi.Contract.framed, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, BitVec.reduceAdd] at hx' hmod'
            rw [hout2 x (by bv_decide) (by bv_decide)]
            refine Eq.trans ?_ (hOut x hx hmod); first | rfl | mem_away
          clear hout2 hown2
          refine runs_then (a := 9) (s1 := ?_) ?_ ?_
          case refine_2 => run_fn [c0, c1]; rfl
          refine runs_done ⟨rfl, by simp only [Finish.contract, Abi.Contract.framed]; bv_decide, rfl, rfl, rfl, rfl, rfl, rfl, ?_, ?_⟩
          all_goals try dsimp only
          · intro x hx hmod
            refine Eq.trans ?_ (hOut x hx hmod)
            have hx' := hx
            have hmod' := hmod
            simp only [Finish.contract, Abi.Contract.framed, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, BitVec.reduceAdd] at hx' hmod'
            first | rfl | mem_away
          · simp only [Finish.contract, Abi.Contract.framed, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true]
            apply Finish.exit <;> mem_auto
    · have c0 : (sel - 0#64 == 0#64) = false := by bv_decide
      have c1 : (sel - 1#64 == 0#64) = false := by bv_decide
      refine runs_then (a := 31) (s1 := ?_) ?_ ?_
      case refine_2 => run_fn [c0, c1]; rfl
      have_by hN1_0 := Finish.many (m := m0)
      try norm_addr at hN1_0
      split_ands hN1_0
      refine Abi.call_meets (c := Lroot.contract (fb + 264#64) lv key flags 5#64 0#64 k tail) (ra := 1507529#64)
        (Abi.Meets.mono Code_finish.has_lroot (Proof_lroot.lroot_meets (fb + 264#64) lv key flags 5#64 0#64 k tail)) rfl rfl ?_ ?_ ?_ ?_ ?_ ?_
      · dsimp only; mem_fact
      · dsimp only [Lroot.contract]; mem_subregion
      · dsimp only
        simp only [Lroot.contract, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, Abi.AllApart, Abi.Apart, BitVec.reduceAdd]
        try simp only [add_sub_lit, BitVec.add_assoc, BitVec.add_zero, BitVec.reduceAdd, BitVec.reduceSub]
        repeat' (with_reducible apply And.intro)
        all_goals bv_side
      · simp only [Lroot.contract]
        repeat' (with_reducible apply And.intro)
        all_goals (first | assumption | bv_side)
      · dsimp only
        simp only [Lroot.contract, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true]
        repeat' (with_reducible apply And.intro)
        all_goals (first | mem_auto | (apply_frame <;> mem_auto) | (apply_intro <;> first | mem_auto | (apply_frame <;> mem_auto)))
      · intro s1 hpc1 hsp1 hbx1 hbp1 h12_1 h13_1 h14_1 h15_1 hens1 hout1 hown1
        obtain ⟨rax_1, rcx_1, rdx_1, rbx_1, rsp_1, rbp_1, rsi_1, rdi_1, r8_1, r9_1, r12_1, r13_1, r14_1, r15_1, zf_1, cf_1, y1_0, y1_1, y1_2, y1_3, y1_4, y1_5, y1_6, y1_7, y1_8, y1_9, y1_10, y1_11, y1_12, y1_13, y1_14, y1_15, mem1, pc_1⟩ := s1
        dsimp only at hpc1 hsp1 hbx1 hbp1 h12_1 h13_1 h14_1 h15_1 hens1 hout1 hown1
        subst pc_1 rsp_1 rbx_1 rbp_1 r12_1 r13_1 r14_1 r15_1
        simp only [Lroot.contract, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true] at hens1
        split_ands hens1
        simp only [Lroot.contract, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, add_sub_lit, BitVec.add_assoc, BitVec.add_zero, BitVec.reduceAdd, BitVec.reduceSub] at hout1
        have hF1 : Region mem1 fb 352#64 := hown1 fb 352#64 (by mem_region)
        have hS1_0 : Quad mem1 (fb + 352#64) ra := X86.Quad.frame (by mem_fact) (fun x hx => hout1 x (by bv_decide) (by bv_decide))
        have hS1_1 : Quad mem1 (fb + 344#64) sv.rbx := X86.Quad.frame (by mem_fact) (fun x hx => hout1 x (by bv_decide) (by bv_decide))
        have hS1_2 : Quad mem1 (fb + 336#64) sv.rbp := X86.Quad.frame (by mem_fact) (fun x hx => hout1 x (by bv_decide) (by bv_decide))
        have hS1_3 : Quad mem1 (fb + 328#64) sv.r12 := X86.Quad.frame (by mem_fact) (fun x hx => hout1 x (by bv_decide) (by bv_decide))
        have hS1_4 : Quad mem1 (fb + 320#64) sv.r13 := X86.Quad.frame (by mem_fact) (fun x hx => hout1 x (by bv_decide) (by bv_decide))
        have hS1_5 : Quad mem1 (fb + 312#64) sv.r14 := X86.Quad.frame (by mem_fact) (fun x hx => hout1 x (by bv_decide) (by bv_decide))
        have hS1_6 : Quad mem1 (fb + 304#64) sv.r15 := X86.Quad.frame (by mem_fact) (fun x hx => hout1 x (by bv_decide) (by bv_decide))
        have hS1_7 : Quad mem1 (fb + 296#64) (lv + 64#64) := X86.Quad.frame (by mem_fact) (fun x hx => hout1 x (by bv_decide) (by bv_decide))
        have hK1_0 : Hash.Lv mem1 wl k flags units := Hash.Lv.frame (m := m0) (by assumption) (fun x hx => by rw [hout1 x (by bv_decide) (by bv_decide)]; first | rfl | mem_away)
        have hK1_1 : Cv.At mem1 key k := Cv.At.frame (m := m0) (by assumption) (fun x hx => by rw [hout1 x (by bv_decide) (by bv_decide)]; first | rfl | mem_away)
        have hK1_2 : Region mem1 out 32#64 := hown1 _ _ (by mem_region)
        have hOut : (∀ x : BitVec 64, (Abi.Contract.framed (Finish.contract out wl lv key flags sel k units tail) 352#64).stack + 8#64 ≤ x - fb → (∀ r ∈ (Abi.Contract.framed (Finish.contract out wl lv key flags sel k units tail) 352#64).modifies, r.2 ≤ x - r.1) → mem1 x = m0 x) := by
          intro x hx hmod
          have hx' := hx
          have hmod' := hmod
          simp only [Finish.contract, Abi.Contract.framed, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, BitVec.reduceAdd] at hx' hmod'
          rw [hout1 x (by bv_decide) (by bv_decide)]
          first | rfl | mem_away
        clear hout1 hown1
        refine runs_then (a := 6) (s1 := ?_) ?_ ?_
        case refine_2 => run_fn [c0, c1]; rfl
        have_by hN2_0 := Finish.sub (m := mem1)
        try norm_addr at hN2_0
        split_ands hN2_0
        refine Abi.call_meets (c := Ladd.contract wl key flags 5#64 (fb + 264#64) k units (Blake3.tree k ⟨flags.setWidth 32⟩ tail)) (ra := 1507554#64)
          (Abi.Meets.mono Code_finish.has_ladd (Proof_ladd.ladd_meets wl key flags 5#64 (fb + 264#64) k units (Blake3.tree k ⟨flags.setWidth 32⟩ tail))) rfl rfl ?_ ?_ ?_ ?_ ?_ ?_
        · dsimp only; mem_fact
        · dsimp only [Ladd.contract]; mem_subregion
        · dsimp only
          simp only [Ladd.contract, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, Abi.AllApart, Abi.Apart, BitVec.reduceAdd]
          try simp only [add_sub_lit, BitVec.add_assoc, BitVec.add_zero, BitVec.reduceAdd, BitVec.reduceSub]
          repeat' (with_reducible apply And.intro)
          all_goals bv_side
        · simp only [Ladd.contract]
          repeat' (with_reducible apply And.intro)
          all_goals (first | assumption | bv_side)
        · dsimp only
          simp only [Ladd.contract, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true]
          repeat' (with_reducible apply And.intro)
          all_goals (first | mem_auto | (apply_frame <;> mem_auto) | (apply_intro <;> first | mem_auto | (apply_frame <;> mem_auto)))
        · intro s2 hpc2 hsp2 hbx2 hbp2 h12_2 h13_2 h14_2 h15_2 hens2 hout2 hown2
          obtain ⟨rax_2, rcx_2, rdx_2, rbx_2, rsp_2, rbp_2, rsi_2, rdi_2, r8_2, r9_2, r12_2, r13_2, r14_2, r15_2, zf_2, cf_2, y2_0, y2_1, y2_2, y2_3, y2_4, y2_5, y2_6, y2_7, y2_8, y2_9, y2_10, y2_11, y2_12, y2_13, y2_14, y2_15, mem2, pc_2⟩ := s2
          dsimp only at hpc2 hsp2 hbx2 hbp2 h12_2 h13_2 h14_2 h15_2 hens2 hout2 hown2
          subst pc_2 rsp_2 rbx_2 rbp_2 r12_2 r13_2 r14_2 r15_2
          simp only [Ladd.contract, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true] at hens2
          split_ands hens2
          simp only [Ladd.contract, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, add_sub_lit, BitVec.add_assoc, BitVec.add_zero, BitVec.reduceAdd, BitVec.reduceSub] at hout2
          have hF2 : Region mem2 fb 352#64 := hown2 fb 352#64 (by mem_region)
          have hS2_0 : Quad mem2 (fb + 352#64) ra := X86.Quad.frame (by mem_fact) (fun x hx => hout2 x (by bv_decide) (by bv_decide))
          have hS2_1 : Quad mem2 (fb + 344#64) sv.rbx := X86.Quad.frame (by mem_fact) (fun x hx => hout2 x (by bv_decide) (by bv_decide))
          have hS2_2 : Quad mem2 (fb + 336#64) sv.rbp := X86.Quad.frame (by mem_fact) (fun x hx => hout2 x (by bv_decide) (by bv_decide))
          have hS2_3 : Quad mem2 (fb + 328#64) sv.r12 := X86.Quad.frame (by mem_fact) (fun x hx => hout2 x (by bv_decide) (by bv_decide))
          have hS2_4 : Quad mem2 (fb + 320#64) sv.r13 := X86.Quad.frame (by mem_fact) (fun x hx => hout2 x (by bv_decide) (by bv_decide))
          have hS2_5 : Quad mem2 (fb + 312#64) sv.r14 := X86.Quad.frame (by mem_fact) (fun x hx => hout2 x (by bv_decide) (by bv_decide))
          have hS2_6 : Quad mem2 (fb + 304#64) sv.r15 := X86.Quad.frame (by mem_fact) (fun x hx => hout2 x (by bv_decide) (by bv_decide))
          have hS2_7 : Quad mem2 (fb + 296#64) (lv + 64#64) := X86.Quad.frame (by mem_fact) (fun x hx => hout2 x (by bv_decide) (by bv_decide))
          have hK2_0 : Cv.At mem2 key k := Cv.At.frame (m := mem1) (by assumption) (fun x hx => by rw [hout2 x (by bv_decide) (by bv_decide)]; first | rfl | mem_away)
          have hK2_1 : Region mem2 out 32#64 := hown2 _ _ (by mem_region)
          have hOut : (∀ x : BitVec 64, (Abi.Contract.framed (Finish.contract out wl lv key flags sel k units tail) 352#64).stack + 8#64 ≤ x - fb → (∀ r ∈ (Abi.Contract.framed (Finish.contract out wl lv key flags sel k units tail) 352#64).modifies, r.2 ≤ x - r.1) → mem2 x = m0 x) := by
            intro x hx hmod
            have hx' := hx
            have hmod' := hmod
            simp only [Finish.contract, Abi.Contract.framed, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, BitVec.reduceAdd] at hx' hmod'
            rw [hout2 x (by bv_decide) (by bv_decide)]
            refine Eq.trans ?_ (hOut x hx hmod); first | rfl | mem_away
          clear hout2 hown2
          refine runs_then (a := 7) (s1 := ?_) ?_ ?_
          case refine_2 => run_fn [c0, c1]; rfl
          have_by hN3_0 := Finish.many_root (m := mem2)
          try norm_addr at hN3_0
          split_ands hN3_0
          refine Abi.call_meets (c := Lroot.contract out wl key flags 5#64 8#64 k (Finish.w2 k flags units tail)) (ra := 1507585#64)
            (Abi.Meets.mono Code_finish.has_lroot (Proof_lroot.lroot_meets out wl key flags 5#64 8#64 k (Finish.w2 k flags units tail))) rfl rfl ?_ ?_ ?_ ?_ ?_ ?_
          · dsimp only; mem_fact
          · dsimp only [Lroot.contract]; mem_subregion
          · dsimp only
            simp only [Lroot.contract, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, Abi.AllApart, Abi.Apart, BitVec.reduceAdd]
            try simp only [add_sub_lit, BitVec.add_assoc, BitVec.add_zero, BitVec.reduceAdd, BitVec.reduceSub]
            repeat' (with_reducible apply And.intro)
            all_goals bv_side
          · simp only [Lroot.contract]
            repeat' (with_reducible apply And.intro)
            all_goals (first | assumption | bv_side)
          · dsimp only
            simp only [Lroot.contract, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true]
            repeat' (with_reducible apply And.intro)
            all_goals (first | mem_auto | (apply_frame <;> mem_auto) | (apply_intro <;> first | mem_auto | (apply_frame <;> mem_auto)))
          · intro s3 hpc3 hsp3 hbx3 hbp3 h12_3 h13_3 h14_3 h15_3 hens3 hout3 hown3
            obtain ⟨rax_3, rcx_3, rdx_3, rbx_3, rsp_3, rbp_3, rsi_3, rdi_3, r8_3, r9_3, r12_3, r13_3, r14_3, r15_3, zf_3, cf_3, y3_0, y3_1, y3_2, y3_3, y3_4, y3_5, y3_6, y3_7, y3_8, y3_9, y3_10, y3_11, y3_12, y3_13, y3_14, y3_15, mem3, pc_3⟩ := s3
            dsimp only at hpc3 hsp3 hbx3 hbp3 h12_3 h13_3 h14_3 h15_3 hens3 hout3 hown3
            subst pc_3 rsp_3 rbx_3 rbp_3 r12_3 r13_3 r14_3 r15_3
            simp only [Lroot.contract, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true] at hens3
            split_ands hens3
            simp only [Lroot.contract, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, add_sub_lit, BitVec.add_assoc, BitVec.add_zero, BitVec.reduceAdd, BitVec.reduceSub] at hout3
            have hF3 : Region mem3 fb 352#64 := hown3 fb 352#64 (by mem_region)
            have hS3_0 : Quad mem3 (fb + 352#64) ra := X86.Quad.frame (by mem_fact) (fun x hx => hout3 x (by bv_decide) (by bv_decide))
            have hS3_1 : Quad mem3 (fb + 344#64) sv.rbx := X86.Quad.frame (by mem_fact) (fun x hx => hout3 x (by bv_decide) (by bv_decide))
            have hS3_2 : Quad mem3 (fb + 336#64) sv.rbp := X86.Quad.frame (by mem_fact) (fun x hx => hout3 x (by bv_decide) (by bv_decide))
            have hS3_3 : Quad mem3 (fb + 328#64) sv.r12 := X86.Quad.frame (by mem_fact) (fun x hx => hout3 x (by bv_decide) (by bv_decide))
            have hS3_4 : Quad mem3 (fb + 320#64) sv.r13 := X86.Quad.frame (by mem_fact) (fun x hx => hout3 x (by bv_decide) (by bv_decide))
            have hS3_5 : Quad mem3 (fb + 312#64) sv.r14 := X86.Quad.frame (by mem_fact) (fun x hx => hout3 x (by bv_decide) (by bv_decide))
            have hS3_6 : Quad mem3 (fb + 304#64) sv.r15 := X86.Quad.frame (by mem_fact) (fun x hx => hout3 x (by bv_decide) (by bv_decide))
            have hS3_7 : Quad mem3 (fb + 296#64) (lv + 64#64) := X86.Quad.frame (by mem_fact) (fun x hx => hout3 x (by bv_decide) (by bv_decide))
            have hK3_0 : Hash.Lv mem3 wl k flags (Finish.w2 k flags units tail) := Hash.Lv.frame (m := mem2) (by assumption) (fun x hx => by rw [hout3 x (by bv_decide) (by bv_decide)]; first | rfl | mem_away)
            have hOut : (∀ x : BitVec 64, (Abi.Contract.framed (Finish.contract out wl lv key flags sel k units tail) 352#64).stack + 8#64 ≤ x - fb → (∀ r ∈ (Abi.Contract.framed (Finish.contract out wl lv key flags sel k units tail) 352#64).modifies, r.2 ≤ x - r.1) → mem3 x = m0 x) := by
              intro x hx hmod
              have hx' := hx
              have hmod' := hmod
              simp only [Finish.contract, Abi.Contract.framed, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, BitVec.reduceAdd] at hx' hmod'
              rw [hout3 x (by bv_decide) (by bv_decide)]
              refine Eq.trans ?_ (hOut x hx hmod); first | rfl | mem_away
            clear hout3 hown3
            refine runs_then (a := 8) (s1 := ?_) ?_ ?_
            case refine_2 => run_fn [c0, c1]; rfl
            refine runs_done ⟨rfl, by simp only [Finish.contract, Abi.Contract.framed]; bv_decide, rfl, rfl, rfl, rfl, rfl, rfl, ?_, ?_⟩
            all_goals try dsimp only
            · intro x hx hmod
              refine Eq.trans ?_ (hOut x hx hmod)
              have hx' := hx
              have hmod' := hmod
              simp only [Finish.contract, Abi.Contract.framed, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, BitVec.reduceAdd] at hx' hmod'
              first | rfl | mem_away
            · simp only [Finish.contract, Abi.Contract.framed, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true]
              apply Finish.exit <;> mem_auto

/-- **`finish`, as assembled, meets its contract, whatever its arguments.** -/
theorem finish_meets : ∀ (out wl lv key flags sel : BitVec 64) (k : Blake3.CV) (units : Array Blake3.Node) (tail : Array Blake3.Node),
    Abi.Meets Code_finish.prog 0x170000 (Finish.contract out wl lv key flags sel k units tail) := by
  intro out wl lv key flags sel k units tail
  refine Abi.meets_of_triple 352#64 (by dsimp only [Finish.contract]; decide) (by dsimp only [Finish.contract]; decide) (fun fb ra sv m0 => ?_)
  intro s hP
  exact whole fb out wl lv key flags sel ra sv k units tail m0 s hP

#print axioms finish_meets

end Proof_finish
