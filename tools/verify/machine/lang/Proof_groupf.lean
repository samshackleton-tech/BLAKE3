import Cells
import Kernels
import AbiProof
import AbiCall
import Spec_groupf
import Lemmas_groupf
import Proof_fillp
import Proof_addn
import Proof_chunk_node
import Proof_node_out
import Proof_ladd
import Code_groupf
open X86 Cells

/-! # `groupf`, as assembled, meets `Groupf.contract`

Written by prove_fn.py from levels.ode and the compiler's layout; not edited by hand, and not to be read
but for its last theorem's statement: Lean checks the rest. The frame: 5632 bytes below the stack pointer at entry
(`fb` is its lowest address), the caller's rbx, rbp, r12, r13, r14, r15 at its top.
-/

namespace Proof_groupf

set_option maxRecDepth 1000000
set_option maxHeartbeats 0
set_option linter.unusedVariables false

theorem whole (ext : Nat → Option (Instr × Nat)) (hA_chunks32 : ∀ x0 x1 x2 x3 x4 x5 x6 x7 x8 x9 x10, Abi.Meets (Code_groupf.prog ext) 0x10000 (K32.contract x0 x1 x2 x3 x4 x5 x6 x7 x8 x9 x10)) (fb lv input len key flags cfirst ra : BitVec 64) (sv : Abi.Saved) (k : Blake3.CV) (bytes : List (BitVec 8)) (m0 : Mem)
    (s : State) (hP : Abi.Pre 0x1B0000 (Abi.Contract.framed (Groupf.contract lv input len key flags cfirst k bytes) 5632#64) fb ra sv m0 s) : ∃ n_ s', steps (Code_groupf.prog ext) n_ s = some s' ∧ Abi.Post (Abi.Contract.framed (Groupf.contract lv input len key flags cfirst k bytes) 5632#64) fb ra sv m0 s' := by
  obtain ⟨rax, rcx, rdx, rbx, rsp, rbp, rsi, rdi, r8, r9, r12, r13, r14, r15, zf, cf, x0, x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12, x13, x14, x15, mem, pc⟩ := s
  obtain ⟨hpc, hsp, hargs, hbx, hbp, h12, h13, h14, h15, hmem, hF, hRa, hAp, hAcc, hReq⟩ := hP
  simp only [Groupf.contract, Abi.Contract.framed, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true] at hpc hsp hargs hbx hbp h12 h13 h14 h15 hmem hF hRa
  simp only [List.length_cons, List.length_nil, List.take, List.cons.injEq, and_true] at hargs
  obtain ⟨ha0, ha1, ha2, ha3, ha4, ha5⟩ := hargs
  subst pc rsp rdi rsi rdx rcx r8 r9 rbx rbp r12 r13 r14 r15 mem
  have hAp0 := hAp
  simp only [Groupf.contract, Abi.Contract.framed, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, Abi.AllApart, Abi.Apart, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, BitVec.reduceAdd] at hAp
  split_ands hAp
  have hAcc0 := hAcc
  try (simp only [Groupf.contract, Abi.Contract.framed, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true] at hAcc; split_ands hAcc)
  have hReq0 := hReq
  simp only [Groupf.contract, Abi.Contract.framed, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true] at hReq
  split_ands hReq
  have_by hE0 := Groupf.msg (m := m0)
  try norm_addr at hE0
  split_ands hE0
  refine runs_then (a := 38) (s1 := ?_) ?_ ?_
  case refine_2 => run_fn []; rfl
  refine Abi.call_meets (c := Fillp.contract (fb + 4264#64) input ((len - 1#64) >>> 10) 1024#64) (ra := 1769645#64)
    (Abi.Meets.mono (Code_groupf.has_fillp ext) (Proof_fillp.fillp_meets (fb + 4264#64) input ((len - 1#64) >>> 10) 1024#64)) rfl rfl ?_ ?_ ?_ ?_ ?_ ?_
  · dsimp only; mem_fact
  · dsimp only [Fillp.contract]; mem_subregion
  · dsimp only
    simp only [Fillp.contract, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, Abi.AllApart, Abi.Apart, BitVec.reduceAdd]
    try simp only [add_sub_lit, BitVec.add_assoc, BitVec.add_zero, BitVec.reduceAdd, BitVec.reduceSub]
    repeat' (with_reducible apply And.intro)
    all_goals bv_side
  · simp only [Fillp.contract]
    repeat' (with_reducible apply And.intro)
    all_goals (first | assumption | bv_side)
  · dsimp only
    simp only [Fillp.contract, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true]
    repeat' (with_reducible apply And.intro)
    all_goals (first | mem_auto | (apply_frame <;> mem_auto) | (apply_intro <;> first | mem_auto | (apply_frame <;> mem_auto)))
  · intro s1 hpc1 hsp1 hbx1 hbp1 h12_1 h13_1 h14_1 h15_1 hens1 hout1 hown1
    obtain ⟨rax_1, rcx_1, rdx_1, rbx_1, rsp_1, rbp_1, rsi_1, rdi_1, r8_1, r9_1, r12_1, r13_1, r14_1, r15_1, zf_1, cf_1, y1_0, y1_1, y1_2, y1_3, y1_4, y1_5, y1_6, y1_7, y1_8, y1_9, y1_10, y1_11, y1_12, y1_13, y1_14, y1_15, mem1, pc_1⟩ := s1
    dsimp only at hpc1 hsp1 hbx1 hbp1 h12_1 h13_1 h14_1 h15_1 hens1 hout1 hown1
    subst pc_1 rsp_1 rbx_1 rbp_1 r12_1 r13_1 r14_1 r15_1
    simp only [Fillp.contract, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true] at hens1
    split_ands hens1
    simp only [Fillp.contract, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, add_sub_lit, BitVec.add_assoc, BitVec.add_zero, BitVec.reduceAdd, BitVec.reduceSub] at hout1
    have hF1 : Region mem1 fb 5632#64 := hown1 fb 5632#64 (by mem_region)
    have hS1_0 : Quad mem1 (fb + 5632#64) ra := X86.Quad.frame (by mem_fact) (fun x hx => hout1 x (by bv_decide) (by bv_decide))
    have hS1_1 : Quad mem1 (fb + 5624#64) sv.rbx := X86.Quad.frame (by mem_fact) (fun x hx => hout1 x (by bv_decide) (by bv_decide))
    have hS1_2 : Quad mem1 (fb + 5616#64) sv.rbp := X86.Quad.frame (by mem_fact) (fun x hx => hout1 x (by bv_decide) (by bv_decide))
    have hS1_3 : Quad mem1 (fb + 5608#64) sv.r12 := X86.Quad.frame (by mem_fact) (fun x hx => hout1 x (by bv_decide) (by bv_decide))
    have hS1_4 : Quad mem1 (fb + 5600#64) sv.r13 := X86.Quad.frame (by mem_fact) (fun x hx => hout1 x (by bv_decide) (by bv_decide))
    have hS1_5 : Quad mem1 (fb + 5592#64) sv.r14 := X86.Quad.frame (by mem_fact) (fun x hx => hout1 x (by bv_decide) (by bv_decide))
    have hS1_6 : Quad mem1 (fb + 5584#64) sv.r15 := X86.Quad.frame (by mem_fact) (fun x hx => hout1 x (by bv_decide) (by bv_decide))
    have hS1_7 : Quad mem1 (fb + 5544#64) (flags ||| 1073873152#64) := X86.Quad.frame (by mem_fact) (fun x hx => hout1 x (by bv_decide) (by bv_decide))
    have hS1_8 : Quad mem1 (fb + 5552#64) ((len - 1#64) >>> 10) := X86.Quad.frame (by mem_fact) (fun x hx => hout1 x (by bv_decide) (by bv_decide))
    have hS1_9 : Quad mem1 (fb + 5560#64) (input + (((len - 1#64) >>> 10) <<< 10)) := X86.Quad.frame (by mem_fact) (fun x hx => hout1 x (by bv_decide) (by bv_decide))
    have hS1_10 : Quad mem1 (fb + 5568#64) (len - (((len - 1#64) >>> 10) <<< 10)) := X86.Quad.frame (by mem_fact) (fun x hx => hout1 x (by bv_decide) (by bv_decide))
    have hS1_11 : Quad mem1 (fb + 5576#64) (cfirst + ((len - 1#64) >>> 10)) := X86.Quad.frame (by mem_fact) (fun x hx => hout1 x (by bv_decide) (by bv_decide))
    have hK1_0 : Hash.In mem1 input len bytes input len 0#64 := Hash.In.frame (m := m0) (by assumption) (fun x hx => by rw [hout1 x (by bv_decide) (by bv_decide)]; first | rfl | mem_away)
    have hK1_1 : Cv.At mem1 key k := Cv.At.frame (m := m0) (by assumption) (fun x hx => by rw [hout1 x (by bv_decide) (by bv_decide)]; first | rfl | mem_away)
    have hK1_2 : Region mem1 lv 3520#64 := hown1 _ _ (by mem_region)
    have hOut : (∀ x : BitVec 64, (Abi.Contract.framed (Groupf.contract lv input len key flags cfirst k bytes) 5632#64).stack + 8#64 ≤ x - fb → (∀ r ∈ (Abi.Contract.framed (Groupf.contract lv input len key flags cfirst k bytes) 5632#64).modifies, r.2 ≤ x - r.1) → mem1 x = m0 x) := by
      intro x hx hmod
      have hx' := hx
      have hmod' := hmod
      simp only [Groupf.contract, Abi.Contract.framed, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, BitVec.reduceAdd] at hx' hmod'
      rw [hout1 x (by bv_decide) (by bv_decide)]
      first | rfl | mem_away
    clear hout1 hown1
    refine runs_then (a := 7) (s1 := ?_) ?_ ?_
    case refine_2 => run_fn []; rfl
    have_by hN2_0 := Groupf.k32in (m := mem1)
    try norm_addr at hN2_0
    split_ands hN2_0
    refine Abi.call_meets (c := K32.contract (fb + 4264#64) 16#64 key cfirst (flags ||| 1073873152#64) (fb + 4520#64) k input (((len - 1#64) >>> 10)) flags (Groupf.head bytes (((len - 1#64) >>> 10)))) (ra := 1769687#64)
      (hA_chunks32 (fb + 4264#64) 16#64 key cfirst (flags ||| 1073873152#64) (fb + 4520#64) k input (((len - 1#64) >>> 10)) flags (Groupf.head bytes (((len - 1#64) >>> 10)))) rfl rfl ?_ ?_ ?_ ?_ ?_ ?_
    · dsimp only; mem_fact
    · dsimp only [K32.contract]; mem_subregion
    · dsimp only
      simp only [K32.contract, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, Abi.AllApart, Abi.Apart, BitVec.reduceAdd]
      try simp only [add_sub_lit, BitVec.add_assoc, BitVec.add_zero, BitVec.reduceAdd, BitVec.reduceSub]
      repeat' (with_reducible apply And.intro)
      all_goals bv_side
    · simp only [K32.contract]
      repeat' (with_reducible apply And.intro)
      all_goals (first | assumption | bv_side)
    · dsimp only
      simp only [K32.contract, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true]
      repeat' (with_reducible apply And.intro)
      all_goals (first | mem_auto | (apply_frame <;> mem_auto) | (apply_intro <;> first | mem_auto | (apply_frame <;> mem_auto)))
    · intro s2 hpc2 hsp2 hbx2 hbp2 h12_2 h13_2 h14_2 h15_2 hens2 hout2 hown2
      obtain ⟨rax_2, rcx_2, rdx_2, rbx_2, rsp_2, rbp_2, rsi_2, rdi_2, r8_2, r9_2, r12_2, r13_2, r14_2, r15_2, zf_2, cf_2, y2_0, y2_1, y2_2, y2_3, y2_4, y2_5, y2_6, y2_7, y2_8, y2_9, y2_10, y2_11, y2_12, y2_13, y2_14, y2_15, mem2, pc_2⟩ := s2
      dsimp only at hpc2 hsp2 hbx2 hbp2 h12_2 h13_2 h14_2 h15_2 hens2 hout2 hown2
      subst pc_2 rsp_2 rbx_2 rbp_2 r12_2 r13_2 r14_2 r15_2
      simp only [K32.contract, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true] at hens2
      split_ands hens2
      simp only [K32.contract, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, add_sub_lit, BitVec.add_assoc, BitVec.add_zero, BitVec.reduceAdd, BitVec.reduceSub] at hout2
      have hF2 : Region mem2 fb 5632#64 := hown2 fb 5632#64 (by mem_region)
      have hS2_0 : Quad mem2 (fb + 5632#64) ra := X86.Quad.frame (by mem_fact) (fun x hx => hout2 x (by bv_decide) (by bv_decide))
      have hS2_1 : Quad mem2 (fb + 5624#64) sv.rbx := X86.Quad.frame (by mem_fact) (fun x hx => hout2 x (by bv_decide) (by bv_decide))
      have hS2_2 : Quad mem2 (fb + 5616#64) sv.rbp := X86.Quad.frame (by mem_fact) (fun x hx => hout2 x (by bv_decide) (by bv_decide))
      have hS2_3 : Quad mem2 (fb + 5608#64) sv.r12 := X86.Quad.frame (by mem_fact) (fun x hx => hout2 x (by bv_decide) (by bv_decide))
      have hS2_4 : Quad mem2 (fb + 5600#64) sv.r13 := X86.Quad.frame (by mem_fact) (fun x hx => hout2 x (by bv_decide) (by bv_decide))
      have hS2_5 : Quad mem2 (fb + 5592#64) sv.r14 := X86.Quad.frame (by mem_fact) (fun x hx => hout2 x (by bv_decide) (by bv_decide))
      have hS2_6 : Quad mem2 (fb + 5584#64) sv.r15 := X86.Quad.frame (by mem_fact) (fun x hx => hout2 x (by bv_decide) (by bv_decide))
      have hS2_7 : Quad mem2 (fb + 5544#64) (flags ||| 1073873152#64) := X86.Quad.frame (by mem_fact) (fun x hx => hout2 x (by bv_decide) (by bv_decide))
      have hS2_8 : Quad mem2 (fb + 5552#64) ((len - 1#64) >>> 10) := X86.Quad.frame (by mem_fact) (fun x hx => hout2 x (by bv_decide) (by bv_decide))
      have hS2_9 : Quad mem2 (fb + 5560#64) (input + (((len - 1#64) >>> 10) <<< 10)) := X86.Quad.frame (by mem_fact) (fun x hx => hout2 x (by bv_decide) (by bv_decide))
      have hS2_10 : Quad mem2 (fb + 5568#64) (len - (((len - 1#64) >>> 10) <<< 10)) := X86.Quad.frame (by mem_fact) (fun x hx => hout2 x (by bv_decide) (by bv_decide))
      have hS2_11 : Quad mem2 (fb + 5576#64) (cfirst + ((len - 1#64) >>> 10)) := X86.Quad.frame (by mem_fact) (fun x hx => hout2 x (by bv_decide) (by bv_decide))
      have hK2_0 : Hash.In mem2 input len bytes input len 0#64 := Hash.In.frame (m := mem1) (by assumption) (fun x hx => by rw [hout2 x (by bv_decide) (by bv_decide)]; first | rfl | mem_away)
      have hK2_1 : Cv.At mem2 key k := Cv.At.frame (m := mem1) (by assumption) (fun x hx => by rw [hout2 x (by bv_decide) (by bv_decide)]; first | rfl | mem_away)
      have hK2_2 : Region mem2 lv 3520#64 := hown2 _ _ (by mem_region)
      have hOut : (∀ x : BitVec 64, (Abi.Contract.framed (Groupf.contract lv input len key flags cfirst k bytes) 5632#64).stack + 8#64 ≤ x - fb → (∀ r ∈ (Abi.Contract.framed (Groupf.contract lv input len key flags cfirst k bytes) 5632#64).modifies, r.2 ≤ x - r.1) → mem2 x = m0 x) := by
        intro x hx hmod
        have hx' := hx
        have hmod' := hmod
        simp only [Groupf.contract, Abi.Contract.framed, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, BitVec.reduceAdd] at hx' hmod'
        rw [hout2 x (by bv_decide) (by bv_decide)]
        refine Eq.trans ?_ (hOut x hx hmod); first | rfl | mem_away
      clear hout2 hown2
      refine runs_then (a := 9) (s1 := ?_) ?_ ?_
      case refine_2 => run_fn []; rfl
      have_by hN3_0 := Groupf.addin (k := k) (flags := flags) (c0 := cfirst) (bytes := bytes) (m := mem2)
      try norm_addr at hN3_0
      split_ands hN3_0
      refine Abi.call_meets (c := Addn.contract lv key flags (fb + 4520#64) ((len - 1#64) >>> 10) k (#[] : Array Blake3.Node) (Groupf.news k flags cfirst bytes (((len - 1#64) >>> 10))) (K32.values k flags cfirst (((len - 1#64) >>> 10)) (Groupf.head bytes (((len - 1#64) >>> 10))))) (ra := 1769730#64)
        (Abi.Meets.mono (Code_groupf.has_addn ext) (Proof_addn.addn_meets lv key flags (fb + 4520#64) ((len - 1#64) >>> 10) k (#[] : Array Blake3.Node) (Groupf.news k flags cfirst bytes (((len - 1#64) >>> 10))) (K32.values k flags cfirst (((len - 1#64) >>> 10)) (Groupf.head bytes (((len - 1#64) >>> 10)))))) rfl rfl ?_ ?_ ?_ ?_ ?_ ?_
      · dsimp only; mem_fact
      · dsimp only [Addn.contract]; mem_subregion
      · dsimp only
        simp only [Addn.contract, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, Abi.AllApart, Abi.Apart, BitVec.reduceAdd]
        try simp only [add_sub_lit, BitVec.add_assoc, BitVec.add_zero, BitVec.reduceAdd, BitVec.reduceSub]
        repeat' (with_reducible apply And.intro)
        all_goals bv_side
      · simp only [Addn.contract]
        repeat' (with_reducible apply And.intro)
        all_goals (first | assumption | bv_side)
      · dsimp only
        simp only [Addn.contract, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true]
        repeat' (with_reducible apply And.intro)
        all_goals (first | mem_auto | (apply_frame <;> mem_auto) | (apply_intro <;> first | mem_auto | (apply_frame <;> mem_auto)))
      · intro s3 hpc3 hsp3 hbx3 hbp3 h12_3 h13_3 h14_3 h15_3 hens3 hout3 hown3
        obtain ⟨rax_3, rcx_3, rdx_3, rbx_3, rsp_3, rbp_3, rsi_3, rdi_3, r8_3, r9_3, r12_3, r13_3, r14_3, r15_3, zf_3, cf_3, y3_0, y3_1, y3_2, y3_3, y3_4, y3_5, y3_6, y3_7, y3_8, y3_9, y3_10, y3_11, y3_12, y3_13, y3_14, y3_15, mem3, pc_3⟩ := s3
        dsimp only at hpc3 hsp3 hbx3 hbp3 h12_3 h13_3 h14_3 h15_3 hens3 hout3 hown3
        subst pc_3 rsp_3 rbx_3 rbp_3 r12_3 r13_3 r14_3 r15_3
        simp only [Addn.contract, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true] at hens3
        split_ands hens3
        simp only [Addn.contract, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, add_sub_lit, BitVec.add_assoc, BitVec.add_zero, BitVec.reduceAdd, BitVec.reduceSub] at hout3
        have hF3 : Region mem3 fb 5632#64 := hown3 fb 5632#64 (by mem_region)
        have hS3_0 : Quad mem3 (fb + 5632#64) ra := X86.Quad.frame (by mem_fact) (fun x hx => hout3 x (by bv_decide) (by bv_decide))
        have hS3_1 : Quad mem3 (fb + 5624#64) sv.rbx := X86.Quad.frame (by mem_fact) (fun x hx => hout3 x (by bv_decide) (by bv_decide))
        have hS3_2 : Quad mem3 (fb + 5616#64) sv.rbp := X86.Quad.frame (by mem_fact) (fun x hx => hout3 x (by bv_decide) (by bv_decide))
        have hS3_3 : Quad mem3 (fb + 5608#64) sv.r12 := X86.Quad.frame (by mem_fact) (fun x hx => hout3 x (by bv_decide) (by bv_decide))
        have hS3_4 : Quad mem3 (fb + 5600#64) sv.r13 := X86.Quad.frame (by mem_fact) (fun x hx => hout3 x (by bv_decide) (by bv_decide))
        have hS3_5 : Quad mem3 (fb + 5592#64) sv.r14 := X86.Quad.frame (by mem_fact) (fun x hx => hout3 x (by bv_decide) (by bv_decide))
        have hS3_6 : Quad mem3 (fb + 5584#64) sv.r15 := X86.Quad.frame (by mem_fact) (fun x hx => hout3 x (by bv_decide) (by bv_decide))
        have hS3_7 : Quad mem3 (fb + 5544#64) (flags ||| 1073873152#64) := X86.Quad.frame (by mem_fact) (fun x hx => hout3 x (by bv_decide) (by bv_decide))
        have hS3_8 : Quad mem3 (fb + 5552#64) ((len - 1#64) >>> 10) := X86.Quad.frame (by mem_fact) (fun x hx => hout3 x (by bv_decide) (by bv_decide))
        have hS3_9 : Quad mem3 (fb + 5560#64) (input + (((len - 1#64) >>> 10) <<< 10)) := X86.Quad.frame (by mem_fact) (fun x hx => hout3 x (by bv_decide) (by bv_decide))
        have hS3_10 : Quad mem3 (fb + 5568#64) (len - (((len - 1#64) >>> 10) <<< 10)) := X86.Quad.frame (by mem_fact) (fun x hx => hout3 x (by bv_decide) (by bv_decide))
        have hS3_11 : Quad mem3 (fb + 5576#64) (cfirst + ((len - 1#64) >>> 10)) := X86.Quad.frame (by mem_fact) (fun x hx => hout3 x (by bv_decide) (by bv_decide))
        have hK3_0 : Hash.In mem3 input len bytes input len 0#64 := Hash.In.frame (m := mem2) (by assumption) (fun x hx => by rw [hout3 x (by bv_decide) (by bv_decide)]; first | rfl | mem_away)
        have hK3_1 : Cv.At mem3 key k := Cv.At.frame (m := mem2) (by assumption) (fun x hx => by rw [hout3 x (by bv_decide) (by bv_decide)]; first | rfl | mem_away)
        have hOut : (∀ x : BitVec 64, (Abi.Contract.framed (Groupf.contract lv input len key flags cfirst k bytes) 5632#64).stack + 8#64 ≤ x - fb → (∀ r ∈ (Abi.Contract.framed (Groupf.contract lv input len key flags cfirst k bytes) 5632#64).modifies, r.2 ≤ x - r.1) → mem3 x = m0 x) := by
          intro x hx hmod
          have hx' := hx
          have hmod' := hmod
          simp only [Groupf.contract, Abi.Contract.framed, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, BitVec.reduceAdd] at hx' hmod'
          rw [hout3 x (by bv_decide) (by bv_decide)]
          refine Eq.trans ?_ (hOut x hx hmod); first | rfl | mem_away
        clear hout3 hown3
        have_by hO4_0 := Cv.At.vectors (m := mem3)
        obtain ⟨k0, k1, hO4_0⟩ := hO4_0
        try norm_addr at hO4_0
        split_ands hO4_0
        refine runs_then (a := 13) (s1 := ?_) ?_ ?_
        case refine_2 => run_fn []; rfl
        have_by hN4_0 := Groupf.after (m := mem3)
        try norm_addr at hN4_0
        split_ands hN4_0
        refine Abi.call_meets (c := ChunkNode.contract (fb + 4104#64) (input + (((len - 1#64) >>> 10) <<< 10)) (len - (((len - 1#64) >>> 10) <<< 10)) (cfirst + ((len - 1#64) >>> 10)) flags 5#64 k (Hash.chunk bytes (((len - 1#64) >>> 10)))) (ra := 1769794#64)
          (Abi.Meets.mono (Code_groupf.has_chunk_node ext) (Proof_chunk_node.chunk_node_meets (fb + 4104#64) (input + (((len - 1#64) >>> 10) <<< 10)) (len - (((len - 1#64) >>> 10) <<< 10)) (cfirst + ((len - 1#64) >>> 10)) flags 5#64 k (Hash.chunk bytes (((len - 1#64) >>> 10))))) rfl rfl ?_ ?_ ?_ ?_ ?_ ?_
        · dsimp only; mem_fact
        · dsimp only [ChunkNode.contract]; mem_subregion
        · dsimp only
          simp only [ChunkNode.contract, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, Abi.AllApart, Abi.Apart, BitVec.reduceAdd]
          try simp only [add_sub_lit, BitVec.add_assoc, BitVec.add_zero, BitVec.reduceAdd, BitVec.reduceSub]
          repeat' (with_reducible apply And.intro)
          all_goals bv_side
        · simp only [ChunkNode.contract]
          repeat' (with_reducible apply And.intro)
          all_goals (first | assumption | bv_side)
        · dsimp only
          simp only [ChunkNode.contract, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true]
          repeat' (with_reducible apply And.intro)
          all_goals (first | mem_auto | (apply_frame <;> mem_auto) | (apply_intro <;> first | mem_auto | (apply_frame <;> mem_auto)))
        · intro s4 hpc4 hsp4 hbx4 hbp4 h12_4 h13_4 h14_4 h15_4 hens4 hout4 hown4
          obtain ⟨rax_4, rcx_4, rdx_4, rbx_4, rsp_4, rbp_4, rsi_4, rdi_4, r8_4, r9_4, r12_4, r13_4, r14_4, r15_4, zf_4, cf_4, y4_0, y4_1, y4_2, y4_3, y4_4, y4_5, y4_6, y4_7, y4_8, y4_9, y4_10, y4_11, y4_12, y4_13, y4_14, y4_15, mem4, pc_4⟩ := s4
          dsimp only at hpc4 hsp4 hbx4 hbp4 h12_4 h13_4 h14_4 h15_4 hens4 hout4 hown4
          subst pc_4 rsp_4 rbx_4 rbp_4 r12_4 r13_4 r14_4 r15_4
          simp only [ChunkNode.contract, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true] at hens4
          split_ands hens4
          simp only [ChunkNode.contract, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, add_sub_lit, BitVec.add_assoc, BitVec.add_zero, BitVec.reduceAdd, BitVec.reduceSub] at hout4
          have hF4 : Region mem4 fb 5632#64 := hown4 fb 5632#64 (by mem_region)
          have hS4_0 : Quad mem4 (fb + 5632#64) ra := X86.Quad.frame (by mem_fact) (fun x hx => hout4 x (by bv_decide) (by bv_decide))
          have hS4_1 : Quad mem4 (fb + 5624#64) sv.rbx := X86.Quad.frame (by mem_fact) (fun x hx => hout4 x (by bv_decide) (by bv_decide))
          have hS4_2 : Quad mem4 (fb + 5616#64) sv.rbp := X86.Quad.frame (by mem_fact) (fun x hx => hout4 x (by bv_decide) (by bv_decide))
          have hS4_3 : Quad mem4 (fb + 5608#64) sv.r12 := X86.Quad.frame (by mem_fact) (fun x hx => hout4 x (by bv_decide) (by bv_decide))
          have hS4_4 : Quad mem4 (fb + 5600#64) sv.r13 := X86.Quad.frame (by mem_fact) (fun x hx => hout4 x (by bv_decide) (by bv_decide))
          have hS4_5 : Quad mem4 (fb + 5592#64) sv.r14 := X86.Quad.frame (by mem_fact) (fun x hx => hout4 x (by bv_decide) (by bv_decide))
          have hS4_6 : Quad mem4 (fb + 5584#64) sv.r15 := X86.Quad.frame (by mem_fact) (fun x hx => hout4 x (by bv_decide) (by bv_decide))
          have hS4_7 : Quad mem4 (fb + 5544#64) (flags ||| 1073873152#64) := X86.Quad.frame (by mem_fact) (fun x hx => hout4 x (by bv_decide) (by bv_decide))
          have hS4_8 : Quad mem4 (fb + 5552#64) ((len - 1#64) >>> 10) := X86.Quad.frame (by mem_fact) (fun x hx => hout4 x (by bv_decide) (by bv_decide))
          have hS4_9 : Quad mem4 (fb + 5560#64) (input + (((len - 1#64) >>> 10) <<< 10)) := X86.Quad.frame (by mem_fact) (fun x hx => hout4 x (by bv_decide) (by bv_decide))
          have hS4_10 : Quad mem4 (fb + 5568#64) (len - (((len - 1#64) >>> 10) <<< 10)) := X86.Quad.frame (by mem_fact) (fun x hx => hout4 x (by bv_decide) (by bv_decide))
          have hS4_11 : Quad mem4 (fb + 5576#64) (cfirst + ((len - 1#64) >>> 10)) := X86.Quad.frame (by mem_fact) (fun x hx => hout4 x (by bv_decide) (by bv_decide))
          have hK4_0 : Hash.In mem4 input len bytes (input + (((len - 1#64) >>> 10) <<< 10)) (len - (((len - 1#64) >>> 10) <<< 10)) ((len - 1#64) >>> 10) := Hash.In.frame (m := mem3) (by assumption) (fun x hx => by rw [hout4 x (by bv_decide) (by bv_decide)]; first | rfl | mem_away)
          have hK4_1 : Hash.Lv mem4 lv k flags (Group.nodesTo k flags cfirst bytes ((len - 1#64) >>> 10)) := Hash.Lv.frame (m := mem3) (by assumption) (fun x hx => by rw [hout4 x (by bv_decide) (by bv_decide)]; first | rfl | mem_away)
          have hK4_2 : Cv.At mem4 key k := Cv.At.frame (m := mem3) (by assumption) (fun x hx => by rw [hout4 x (by bv_decide) (by bv_decide)]; first | rfl | mem_away)
          have hOut : (∀ x : BitVec 64, (Abi.Contract.framed (Groupf.contract lv input len key flags cfirst k bytes) 5632#64).stack + 8#64 ≤ x - fb → (∀ r ∈ (Abi.Contract.framed (Groupf.contract lv input len key flags cfirst k bytes) 5632#64).modifies, r.2 ≤ x - r.1) → mem4 x = m0 x) := by
            intro x hx hmod
            have hx' := hx
            have hmod' := hmod
            simp only [Groupf.contract, Abi.Contract.framed, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, BitVec.reduceAdd] at hx' hmod'
            rw [hout4 x (by bv_decide) (by bv_decide)]
            refine Eq.trans ?_ (hOut x hx hmod); first | rfl | mem_away
          clear hout4 hown4
          refine runs_then (a := 5) (s1 := ?_) ?_ ?_
          case refine_2 => run_fn []; rfl
          refine Abi.call_meets (c := NodeOut.contract (fb + 4232#64) (fb + 4104#64) 0#64 5#64 (Chunk.node k flags (cfirst + (((len - 1#64) >>> 10))) (Hash.chunk bytes (((len - 1#64) >>> 10))))) (ra := 1769825#64)
            (Abi.Meets.mono (Code_groupf.has_node_out ext) (Proof_node_out.node_out_meets (fb + 4232#64) (fb + 4104#64) 0#64 5#64 (Chunk.node k flags (cfirst + (((len - 1#64) >>> 10))) (Hash.chunk bytes (((len - 1#64) >>> 10)))))) rfl rfl ?_ ?_ ?_ ?_ ?_ ?_
          · dsimp only; mem_fact
          · dsimp only [NodeOut.contract]; mem_subregion
          · dsimp only
            simp only [NodeOut.contract, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, Abi.AllApart, Abi.Apart, BitVec.reduceAdd]
            try simp only [add_sub_lit, BitVec.add_assoc, BitVec.add_zero, BitVec.reduceAdd, BitVec.reduceSub]
            repeat' (with_reducible apply And.intro)
            all_goals bv_side
          · simp only [NodeOut.contract]
            repeat' (with_reducible apply And.intro)
            all_goals (first | assumption | bv_side)
          · dsimp only
            simp only [NodeOut.contract, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true]
            repeat' (with_reducible apply And.intro)
            all_goals (first | mem_auto | (apply_frame <;> mem_auto) | (apply_intro <;> first | mem_auto | (apply_frame <;> mem_auto)))
          · intro s5 hpc5 hsp5 hbx5 hbp5 h12_5 h13_5 h14_5 h15_5 hens5 hout5 hown5
            obtain ⟨rax_5, rcx_5, rdx_5, rbx_5, rsp_5, rbp_5, rsi_5, rdi_5, r8_5, r9_5, r12_5, r13_5, r14_5, r15_5, zf_5, cf_5, y5_0, y5_1, y5_2, y5_3, y5_4, y5_5, y5_6, y5_7, y5_8, y5_9, y5_10, y5_11, y5_12, y5_13, y5_14, y5_15, mem5, pc_5⟩ := s5
            dsimp only at hpc5 hsp5 hbx5 hbp5 h12_5 h13_5 h14_5 h15_5 hens5 hout5 hown5
            subst pc_5 rsp_5 rbx_5 rbp_5 r12_5 r13_5 r14_5 r15_5
            simp only [NodeOut.contract, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true] at hens5
            split_ands hens5
            simp only [NodeOut.contract, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, add_sub_lit, BitVec.add_assoc, BitVec.add_zero, BitVec.reduceAdd, BitVec.reduceSub] at hout5
            have hF5 : Region mem5 fb 5632#64 := hown5 fb 5632#64 (by mem_region)
            have hS5_0 : Quad mem5 (fb + 5632#64) ra := X86.Quad.frame (by mem_fact) (fun x hx => hout5 x (by bv_decide) (by bv_decide))
            have hS5_1 : Quad mem5 (fb + 5624#64) sv.rbx := X86.Quad.frame (by mem_fact) (fun x hx => hout5 x (by bv_decide) (by bv_decide))
            have hS5_2 : Quad mem5 (fb + 5616#64) sv.rbp := X86.Quad.frame (by mem_fact) (fun x hx => hout5 x (by bv_decide) (by bv_decide))
            have hS5_3 : Quad mem5 (fb + 5608#64) sv.r12 := X86.Quad.frame (by mem_fact) (fun x hx => hout5 x (by bv_decide) (by bv_decide))
            have hS5_4 : Quad mem5 (fb + 5600#64) sv.r13 := X86.Quad.frame (by mem_fact) (fun x hx => hout5 x (by bv_decide) (by bv_decide))
            have hS5_5 : Quad mem5 (fb + 5592#64) sv.r14 := X86.Quad.frame (by mem_fact) (fun x hx => hout5 x (by bv_decide) (by bv_decide))
            have hS5_6 : Quad mem5 (fb + 5584#64) sv.r15 := X86.Quad.frame (by mem_fact) (fun x hx => hout5 x (by bv_decide) (by bv_decide))
            have hS5_7 : Quad mem5 (fb + 5544#64) (flags ||| 1073873152#64) := X86.Quad.frame (by mem_fact) (fun x hx => hout5 x (by bv_decide) (by bv_decide))
            have hS5_8 : Quad mem5 (fb + 5552#64) ((len - 1#64) >>> 10) := X86.Quad.frame (by mem_fact) (fun x hx => hout5 x (by bv_decide) (by bv_decide))
            have hS5_9 : Quad mem5 (fb + 5560#64) (input + (((len - 1#64) >>> 10) <<< 10)) := X86.Quad.frame (by mem_fact) (fun x hx => hout5 x (by bv_decide) (by bv_decide))
            have hS5_10 : Quad mem5 (fb + 5568#64) (len - (((len - 1#64) >>> 10) <<< 10)) := X86.Quad.frame (by mem_fact) (fun x hx => hout5 x (by bv_decide) (by bv_decide))
            have hS5_11 : Quad mem5 (fb + 5576#64) (cfirst + ((len - 1#64) >>> 10)) := X86.Quad.frame (by mem_fact) (fun x hx => hout5 x (by bv_decide) (by bv_decide))
            have hK5_0 : Hash.In mem5 input len bytes (input + (((len - 1#64) >>> 10) <<< 10)) (len - (((len - 1#64) >>> 10) <<< 10)) ((len - 1#64) >>> 10) := Hash.In.frame (m := mem4) (by assumption) (fun x hx => by rw [hout5 x (by bv_decide) (by bv_decide)]; first | rfl | mem_away)
            have hK5_1 : Hash.Lv mem5 lv k flags (Group.nodesTo k flags cfirst bytes ((len - 1#64) >>> 10)) := Hash.Lv.frame (m := mem4) (by assumption) (fun x hx => by rw [hout5 x (by bv_decide) (by bv_decide)]; first | rfl | mem_away)
            have hK5_2 : Cv.At mem5 key k := Cv.At.frame (m := mem4) (by assumption) (fun x hx => by rw [hout5 x (by bv_decide) (by bv_decide)]; first | rfl | mem_away)
            have hOut : (∀ x : BitVec 64, (Abi.Contract.framed (Groupf.contract lv input len key flags cfirst k bytes) 5632#64).stack + 8#64 ≤ x - fb → (∀ r ∈ (Abi.Contract.framed (Groupf.contract lv input len key flags cfirst k bytes) 5632#64).modifies, r.2 ≤ x - r.1) → mem5 x = m0 x) := by
              intro x hx hmod
              have hx' := hx
              have hmod' := hmod
              simp only [Groupf.contract, Abi.Contract.framed, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, BitVec.reduceAdd] at hx' hmod'
              rw [hout5 x (by bv_decide) (by bv_decide)]
              refine Eq.trans ?_ (hOut x hx hmod); first | rfl | mem_away
            clear hout5 hown5
            refine runs_then (a := 6) (s1 := ?_) ?_ ?_
            case refine_2 => run_fn []; rfl
            have_by hN6_0 := Hash.cv_of (m := mem5)
            try norm_addr at hN6_0
            split_ands hN6_0
            have_by hN6_1 := Group.all (m := mem5)
            try norm_addr at hN6_1
            split_ands hN6_1
            refine Abi.call_meets (c := Ladd.contract lv key flags 5#64 (fb + 4232#64) k (Group.nodesTo k flags cfirst bytes (((len - 1#64) >>> 10))) (Chunk.node k flags (cfirst + (((len - 1#64) >>> 10))) (Hash.chunk bytes (((len - 1#64) >>> 10))))) (ra := 1769854#64)
              (Abi.Meets.mono (Code_groupf.has_ladd ext) (Proof_ladd.ladd_meets lv key flags 5#64 (fb + 4232#64) k (Group.nodesTo k flags cfirst bytes (((len - 1#64) >>> 10))) (Chunk.node k flags (cfirst + (((len - 1#64) >>> 10))) (Hash.chunk bytes (((len - 1#64) >>> 10)))))) rfl rfl ?_ ?_ ?_ ?_ ?_ ?_
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
            · intro s6 hpc6 hsp6 hbx6 hbp6 h12_6 h13_6 h14_6 h15_6 hens6 hout6 hown6
              obtain ⟨rax_6, rcx_6, rdx_6, rbx_6, rsp_6, rbp_6, rsi_6, rdi_6, r8_6, r9_6, r12_6, r13_6, r14_6, r15_6, zf_6, cf_6, y6_0, y6_1, y6_2, y6_3, y6_4, y6_5, y6_6, y6_7, y6_8, y6_9, y6_10, y6_11, y6_12, y6_13, y6_14, y6_15, mem6, pc_6⟩ := s6
              dsimp only at hpc6 hsp6 hbx6 hbp6 h12_6 h13_6 h14_6 h15_6 hens6 hout6 hown6
              subst pc_6 rsp_6 rbx_6 rbp_6 r12_6 r13_6 r14_6 r15_6
              simp only [Ladd.contract, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true] at hens6
              split_ands hens6
              simp only [Ladd.contract, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, add_sub_lit, BitVec.add_assoc, BitVec.add_zero, BitVec.reduceAdd, BitVec.reduceSub] at hout6
              have hF6 : Region mem6 fb 5632#64 := hown6 fb 5632#64 (by mem_region)
              have hS6_0 : Quad mem6 (fb + 5632#64) ra := X86.Quad.frame (by mem_fact) (fun x hx => hout6 x (by bv_decide) (by bv_decide))
              have hS6_1 : Quad mem6 (fb + 5624#64) sv.rbx := X86.Quad.frame (by mem_fact) (fun x hx => hout6 x (by bv_decide) (by bv_decide))
              have hS6_2 : Quad mem6 (fb + 5616#64) sv.rbp := X86.Quad.frame (by mem_fact) (fun x hx => hout6 x (by bv_decide) (by bv_decide))
              have hS6_3 : Quad mem6 (fb + 5608#64) sv.r12 := X86.Quad.frame (by mem_fact) (fun x hx => hout6 x (by bv_decide) (by bv_decide))
              have hS6_4 : Quad mem6 (fb + 5600#64) sv.r13 := X86.Quad.frame (by mem_fact) (fun x hx => hout6 x (by bv_decide) (by bv_decide))
              have hS6_5 : Quad mem6 (fb + 5592#64) sv.r14 := X86.Quad.frame (by mem_fact) (fun x hx => hout6 x (by bv_decide) (by bv_decide))
              have hS6_6 : Quad mem6 (fb + 5584#64) sv.r15 := X86.Quad.frame (by mem_fact) (fun x hx => hout6 x (by bv_decide) (by bv_decide))
              have hS6_7 : Quad mem6 (fb + 5544#64) (flags ||| 1073873152#64) := X86.Quad.frame (by mem_fact) (fun x hx => hout6 x (by bv_decide) (by bv_decide))
              have hS6_8 : Quad mem6 (fb + 5552#64) ((len - 1#64) >>> 10) := X86.Quad.frame (by mem_fact) (fun x hx => hout6 x (by bv_decide) (by bv_decide))
              have hS6_9 : Quad mem6 (fb + 5560#64) (input + (((len - 1#64) >>> 10) <<< 10)) := X86.Quad.frame (by mem_fact) (fun x hx => hout6 x (by bv_decide) (by bv_decide))
              have hS6_10 : Quad mem6 (fb + 5568#64) (len - (((len - 1#64) >>> 10) <<< 10)) := X86.Quad.frame (by mem_fact) (fun x hx => hout6 x (by bv_decide) (by bv_decide))
              have hS6_11 : Quad mem6 (fb + 5576#64) (cfirst + ((len - 1#64) >>> 10)) := X86.Quad.frame (by mem_fact) (fun x hx => hout6 x (by bv_decide) (by bv_decide))
              have hOut : (∀ x : BitVec 64, (Abi.Contract.framed (Groupf.contract lv input len key flags cfirst k bytes) 5632#64).stack + 8#64 ≤ x - fb → (∀ r ∈ (Abi.Contract.framed (Groupf.contract lv input len key flags cfirst k bytes) 5632#64).modifies, r.2 ≤ x - r.1) → mem6 x = m0 x) := by
                intro x hx hmod
                have hx' := hx
                have hmod' := hmod
                simp only [Groupf.contract, Abi.Contract.framed, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, BitVec.reduceAdd] at hx' hmod'
                rw [hout6 x (by bv_decide) (by bv_decide)]
                refine Eq.trans ?_ (hOut x hx hmod); first | rfl | mem_away
              clear hout6 hown6
              refine runs_then (a := 8) (s1 := ?_) ?_ ?_
              case refine_2 => run_fn []; rfl
              refine runs_done ⟨rfl, by simp only [Groupf.contract, Abi.Contract.framed]; bv_decide, rfl, rfl, rfl, rfl, rfl, rfl, ?_, ?_⟩
              all_goals try dsimp only
              · intro x hx hmod
                refine Eq.trans ?_ (hOut x hx hmod)
                have hx' := hx
                have hmod' := hmod
                simp only [Groupf.contract, Abi.Contract.framed, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, BitVec.reduceAdd] at hx' hmod'
                first | rfl | mem_away
              · simp only [Groupf.contract, Abi.Contract.framed, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true]
                apply Group.exit <;> mem_auto

/-- **`groupf`, as assembled, meets its contract, whatever its arguments.** -/
theorem groupf_meets (ext : Nat → Option (Instr × Nat)) (hA_chunks32 : ∀ x0 x1 x2 x3 x4 x5 x6 x7 x8 x9 x10, Abi.Meets (Code_groupf.prog ext) 0x10000 (K32.contract x0 x1 x2 x3 x4 x5 x6 x7 x8 x9 x10)) : ∀ (lv input len key flags cfirst : BitVec 64) (k : Blake3.CV) (bytes : List (BitVec 8)),
    Abi.Meets (Code_groupf.prog ext) 0x1B0000 (Groupf.contract lv input len key flags cfirst k bytes) := by
  intro lv input len key flags cfirst k bytes
  refine Abi.meets_of_triple 5632#64 (by dsimp only [Groupf.contract]; decide) (by dsimp only [Groupf.contract]; decide) (fun fb ra sv m0 => ?_)
  intro s hP
  exact whole ext hA_chunks32 fb lv input len key flags cfirst ra sv k bytes m0 s hP

#print axioms groupf_meets

end Proof_groupf
