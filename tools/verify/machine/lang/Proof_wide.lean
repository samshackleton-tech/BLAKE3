import Cells
import Kernels
import AbiProof
import AbiCall
import Spec_wide
import Lemmas_wide
import Proof_fillp
import Proof_tree32
import Proof_ladd
import Code_wide
open X86 Cells

/-! # `wide`, as assembled, meets `Wide.contract`

Written by prove_fn.py from levels.ode and the compiler's layout; not edited by hand, and not to be read
but for its last theorem's statement: Lean checks the rest. The frame: 10064 bytes below the stack pointer at entry
(`fb` is its lowest address), the caller's rbx, rbp, r12, r13, r14, r15 at its top.
-/

namespace Proof_wide

set_option maxRecDepth 1000000
set_option maxHeartbeats 0
set_option linter.unusedVariables false

/-- What holds each time the loop's head is reached: the source's `invariant` clauses, each variable where the
compiler keeps it, and the frame as the compiler keeps it. -/
def Inv (fb wl input len key flags ra : BitVec 64) (sv : Abi.Saved) (k : Blake3.CV) (bytes : List (BitVec 8)) (m0 : Mem) (s : State) : Prop :=
  s.pc = 0x130068 ∧
  s.rsp = (fb + 8200#64) ∧
  s.r13 = wl ∧
  s.r14 = key ∧
  s.r15 = flags ∧
  Region s.mem fb 10064#64 ∧
  Quad s.mem (fb + 10064#64) ra ∧
  Quad s.mem (fb + 10056#64) sv.rbx ∧
  Quad s.mem (fb + 10048#64) sv.rbp ∧
  Quad s.mem (fb + 10040#64) sv.r12 ∧
  Quad s.mem (fb + 10032#64) sv.r13 ∧
  Quad s.mem (fb + 10024#64) sv.r14 ∧
  Quad s.mem (fb + 10016#64) sv.r15 ∧
  Quad s.mem (fb + 9992#64) input ∧
  Quad s.mem (fb + 10000#64) len ∧
  Abi.WriteApart ((fb, (Abi.Contract.framed (Wide.contract wl input len key flags k bytes) 10064#64).stack + 8#64) :: (Abi.Contract.framed (Wide.contract wl input len key flags k bytes) 10064#64).modifies) (Abi.Contract.framed (Wide.contract wl input len key flags k bytes) 10064#64).reading ∧
  (∀ x : BitVec 64, (Abi.Contract.framed (Wide.contract wl input len key flags k bytes) 10064#64).stack + 8#64 ≤ x - fb → (∀ r ∈ (Abi.Contract.framed (Wide.contract wl input len key flags k bytes) 10064#64).modifies, r.2 ≤ x - r.1) → s.mem x = m0 x) ∧
  (Abi.Contract.framed (Wide.contract wl input len key flags k bytes) 10064#64).accepts ∧
  (Abi.Contract.framed (Wide.contract wl input len key flags k bytes) 10064#64).requires m0 ∧
  Quad s.mem (fb + 10008#64) (flags ||| 1073873152#64) ∧
    Hash.In s.mem input len bytes s.rbx s.rbp s.r12 ∧
    Wide.Lv s.mem wl k flags bytes s.r12 ∧
    Cv.At s.mem key k

theorem enter (ext : Nat → Option (Instr × Nat)) (hA_chunks32 : ∀ x0 x1 x2 x3 x4 x5 x6 x7 x8 x9 x10, Abi.Meets (Code_wide.prog ext) 0x10000 (K32.contract x0 x1 x2 x3 x4 x5 x6 x7 x8 x9 x10)) (hA_parents16 : ∀ x0 x1 x2 x3 x4 x5 x6 x7 x8 x9 x10, Abi.Meets (Code_wide.prog ext) 0x18000 (P16.contract x0 x1 x2 x3 x4 x5 x6 x7 x8 x9 x10)) (fb wl input len key flags ra : BitVec 64) (sv : Abi.Saved) (k : Blake3.CV) (bytes : List (BitVec 8)) (m0 : Mem)
    (s : State) (hP : Abi.Pre 0x130000 (Abi.Contract.framed (Wide.contract wl input len key flags k bytes) 10064#64) fb ra sv m0 s) : ∃ n_ s', steps (Code_wide.prog ext) n_ s = some s' ∧ Inv fb wl input len key flags ra sv k bytes m0 s' := by
  obtain ⟨rax, rcx, rdx, rbx, rsp, rbp, rsi, rdi, r8, r9, r12, r13, r14, r15, zf, cf, x0, x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12, x13, x14, x15, mem, pc⟩ := s
  obtain ⟨hpc, hsp, hargs, hbx, hbp, h12, h13, h14, h15, hmem, hF, hRa, hAp, hAcc, hReq⟩ := hP
  simp only [Wide.contract, Abi.Contract.framed, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true] at hpc hsp hargs hbx hbp h12 h13 h14 h15 hmem hF hRa
  simp only [List.length_cons, List.length_nil, List.take, List.cons.injEq, and_true] at hargs
  obtain ⟨ha0, ha1, ha2, ha3, ha4⟩ := hargs
  subst pc rsp rdi rsi rdx rcx r8 rbx rbp r12 r13 r14 r15 mem
  have hAp0 := hAp
  simp only [Wide.contract, Abi.Contract.framed, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, Abi.WriteApart, Abi.Apart, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, BitVec.reduceAdd] at hAp
  split_ands hAp
  have hAcc0 := hAcc
  try (simp only [Wide.contract, Abi.Contract.framed, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true] at hAcc; split_ands hAcc)
  have hReq0 := hReq
  simp only [Wide.contract, Abi.Contract.framed, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true] at hReq
  split_ands hReq
  try (have hK0 := Hash.In.cells (m := m0) (by assumption); split_ands hK0)
  try (have hK1 := Wide.Lv.cells (m := m0) (by assumption); split_ands hK1)
  try (have hK2 := Cv.At.cells (m := m0) (by assumption); split_ands hK2)
  refine runs_then (a := 24) (s1 := ?_) ?_ ?_
  case refine_2 => run_fn []; rfl
  refine runs_done ⟨rfl, rfl, rfl, rfl, rfl, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_⟩
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
    simp only [Wide.contract, Abi.Contract.framed, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, BitVec.reduceAdd] at hx' hmod'
    first | rfl | mem_away
  · exact hAcc0
  · exact hReq0
  · skip
    refine ⟨?_, ?_, ?_, ?_⟩
    · mem_fact
    · apply Hash.In.start <;> mem_auto
    · apply Wide.Lv.start <;> mem_auto
    · first | mem_auto | (apply Cv.At.frame <;> mem_auto)

theorem turn (ext : Nat → Option (Instr × Nat)) (hA_chunks32 : ∀ x0 x1 x2 x3 x4 x5 x6 x7 x8 x9 x10, Abi.Meets (Code_wide.prog ext) 0x10000 (K32.contract x0 x1 x2 x3 x4 x5 x6 x7 x8 x9 x10)) (hA_parents16 : ∀ x0 x1 x2 x3 x4 x5 x6 x7 x8 x9 x10, Abi.Meets (Code_wide.prog ext) 0x18000 (P16.contract x0 x1 x2 x3 x4 x5 x6 x7 x8 x9 x10)) (fb wl input len key flags ra : BitVec 64) (sv : Abi.Saved) (k : Blake3.CV) (bytes : List (BitVec 8)) (m0 : Mem)
    (s : State) (hI : Inv fb wl input len key flags ra sv k bytes m0 s) (hc : 32768#64 < s.rbp) :
    ∃ n_ s', steps (Code_wide.prog ext) n_ s = some s' ∧ (Inv fb wl input len key flags ra sv k bytes m0 s' ∧ s'.rbp.toNat < s.rbp.toNat) := by
  obtain ⟨rax, rcx, rdx, p, rsp, rem, rsi, rdi, r8, r9, counter, r13, r14, r15, zf, cf, x0, x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12, x13, x14, x15, mem, pc⟩ := s
  obtain ⟨hpc, hsp, hp0, hp1, hp2, hF, hRa, hS0, hS1, hS2, hS3, hS4, hS5, hPs0, hPs1, hAp, hOut, hAcc, hReq, hZ0, hI0, hI1, hI2⟩ := hI
  simp only at hpc hsp hp0 hp1 hp2 hF hRa hS0 hS1 hS2 hS3 hS4 hS5 hPs0 hPs1 hOut hZ0 hI0 hI1 hI2 hc
  subst pc rsp r13 r14 r15
  have hAp0 := hAp
  simp only [Wide.contract, Abi.Contract.framed, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, Abi.WriteApart, Abi.Apart, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, BitVec.reduceAdd] at hAp
  split_ands hAp
  have hAcc0 := hAcc
  try (simp only [Wide.contract, Abi.Contract.framed, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true] at hAcc; split_ands hAcc)
  have hReq0 := hReq
  simp only [Wide.contract, Abi.Contract.framed, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true] at hReq
  split_ands hReq
  forget_about m0 except hOut hReq0
  try (have hK0 := Hash.In.cells (m := mem) (by assumption); split_ands hK0)
  try (have hK1 := Wide.Lv.cells (m := mem) (by assumption); split_ands hK1)
  try (have hK2 := Cv.At.cells (m := mem) (by assumption); split_ands hK2)
  have c0 : (32768#64).ult (rem) = true := by bv_decide
  refine runs_then (a := 9) (s1 := ?_) ?_ ?_
  case refine_2 => run_fn [c0]; rfl
  refine Abi.call_meets (c := Fillp.contract (fb + 8200#64) p 32#64 1024#64) (ra := 1245333#64)
    (Abi.Meets.mono (Code_wide.has_fillp ext) (Proof_fillp.fillp_meets (fb + 8200#64) p 32#64 1024#64)) rfl rfl ?_ ?_ ?_ ?_ ?_ ?_
  · dsimp only; mem_fact
  · dsimp only [Fillp.contract]; mem_subregion
  · dsimp only
    simp only [Fillp.contract, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, Abi.WriteApart, Abi.Apart, BitVec.reduceAdd]
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
    have hF1 : Region mem1 fb 10064#64 := hown1 fb 10064#64 (by mem_region)
    have hS1_0 : Quad mem1 (fb + 10064#64) ra := X86.Quad.frame (by mem_fact) (fun x hx => hout1 x (by bv_decide) (by bv_decide))
    have hS1_1 : Quad mem1 (fb + 10056#64) sv.rbx := X86.Quad.frame (by mem_fact) (fun x hx => hout1 x (by bv_decide) (by bv_decide))
    have hS1_2 : Quad mem1 (fb + 10048#64) sv.rbp := X86.Quad.frame (by mem_fact) (fun x hx => hout1 x (by bv_decide) (by bv_decide))
    have hS1_3 : Quad mem1 (fb + 10040#64) sv.r12 := X86.Quad.frame (by mem_fact) (fun x hx => hout1 x (by bv_decide) (by bv_decide))
    have hS1_4 : Quad mem1 (fb + 10032#64) sv.r13 := X86.Quad.frame (by mem_fact) (fun x hx => hout1 x (by bv_decide) (by bv_decide))
    have hS1_5 : Quad mem1 (fb + 10024#64) sv.r14 := X86.Quad.frame (by mem_fact) (fun x hx => hout1 x (by bv_decide) (by bv_decide))
    have hS1_6 : Quad mem1 (fb + 10016#64) sv.r15 := X86.Quad.frame (by mem_fact) (fun x hx => hout1 x (by bv_decide) (by bv_decide))
    have hS1_7 : Quad mem1 (fb + 9992#64) input := X86.Quad.frame (by mem_fact) (fun x hx => hout1 x (by bv_decide) (by bv_decide))
    have hS1_8 : Quad mem1 (fb + 10000#64) len := X86.Quad.frame (by mem_fact) (fun x hx => hout1 x (by bv_decide) (by bv_decide))
    have hS1_9 : Quad mem1 (fb + 10008#64) (flags ||| 1073873152#64) := X86.Quad.frame (by mem_fact) (fun x hx => hout1 x (by bv_decide) (by bv_decide))
    have hK1_0 : Hash.In mem1 input len bytes p rem counter := Hash.In.frame (m := mem) (by assumption) (fun x hx => by rw [hout1 x (by bv_decide) (by bv_decide)]; first | rfl | mem_away)
    have hK1_1 : Wide.Lv mem1 wl k flags bytes counter := Wide.Lv.frame (m := mem) (by assumption) (fun x hx => by rw [hout1 x (by bv_decide) (by bv_decide)]; first | rfl | mem_away)
    have hK1_2 : Cv.At mem1 key k := Cv.At.frame (m := mem) (by assumption) (fun x hx => by rw [hout1 x (by bv_decide) (by bv_decide)]; first | rfl | mem_away)
    have hOut : (∀ x : BitVec 64, (Abi.Contract.framed (Wide.contract wl input len key flags k bytes) 10064#64).stack + 8#64 ≤ x - fb → (∀ r ∈ (Abi.Contract.framed (Wide.contract wl input len key flags k bytes) 10064#64).modifies, r.2 ≤ x - r.1) → mem1 x = m0 x) := by
      intro x hx hmod
      have hx' := hx
      have hmod' := hmod
      simp only [Wide.contract, Abi.Contract.framed, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, BitVec.reduceAdd] at hx' hmod'
      rw [hout1 x (by bv_decide) (by bv_decide)]
      refine Eq.trans ?_ (hOut x hx hmod); first | rfl | mem_away
    clear hout1 hown1
    refine runs_then (a := 7) (s1 := ?_) ?_ ?_
    case refine_2 => run_fn [c0]; rfl
    have_by hN2_0 := Wide.k32in (m := mem1)
    try norm_addr at hN2_0
    split_ands hN2_0
    refine Abi.call_meets (c := K32.contract (fb + 8200#64) 16#64 key counter (flags ||| 1073873152#64) (fb + 8456#64) k p 32#64 flags (Wide.group bytes counter)) (ra := 1245371#64)
      (hA_chunks32 (fb + 8200#64) 16#64 key counter (flags ||| 1073873152#64) (fb + 8456#64) k p 32#64 flags (Wide.group bytes counter)) rfl rfl ?_ ?_ ?_ ?_ ?_ ?_
    · dsimp only; mem_fact
    · dsimp only [K32.contract]; mem_subregion
    · dsimp only
      simp only [K32.contract, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, Abi.WriteApart, Abi.Apart, BitVec.reduceAdd]
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
      have hF2 : Region mem2 fb 10064#64 := hown2 fb 10064#64 (by mem_region)
      have hS2_0 : Quad mem2 (fb + 10064#64) ra := X86.Quad.frame (by mem_fact) (fun x hx => hout2 x (by bv_decide) (by bv_decide))
      have hS2_1 : Quad mem2 (fb + 10056#64) sv.rbx := X86.Quad.frame (by mem_fact) (fun x hx => hout2 x (by bv_decide) (by bv_decide))
      have hS2_2 : Quad mem2 (fb + 10048#64) sv.rbp := X86.Quad.frame (by mem_fact) (fun x hx => hout2 x (by bv_decide) (by bv_decide))
      have hS2_3 : Quad mem2 (fb + 10040#64) sv.r12 := X86.Quad.frame (by mem_fact) (fun x hx => hout2 x (by bv_decide) (by bv_decide))
      have hS2_4 : Quad mem2 (fb + 10032#64) sv.r13 := X86.Quad.frame (by mem_fact) (fun x hx => hout2 x (by bv_decide) (by bv_decide))
      have hS2_5 : Quad mem2 (fb + 10024#64) sv.r14 := X86.Quad.frame (by mem_fact) (fun x hx => hout2 x (by bv_decide) (by bv_decide))
      have hS2_6 : Quad mem2 (fb + 10016#64) sv.r15 := X86.Quad.frame (by mem_fact) (fun x hx => hout2 x (by bv_decide) (by bv_decide))
      have hS2_7 : Quad mem2 (fb + 9992#64) input := X86.Quad.frame (by mem_fact) (fun x hx => hout2 x (by bv_decide) (by bv_decide))
      have hS2_8 : Quad mem2 (fb + 10000#64) len := X86.Quad.frame (by mem_fact) (fun x hx => hout2 x (by bv_decide) (by bv_decide))
      have hS2_9 : Quad mem2 (fb + 10008#64) (flags ||| 1073873152#64) := X86.Quad.frame (by mem_fact) (fun x hx => hout2 x (by bv_decide) (by bv_decide))
      have hK2_0 : Hash.In mem2 input len bytes p rem counter := Hash.In.frame (m := mem1) (by assumption) (fun x hx => by rw [hout2 x (by bv_decide) (by bv_decide)]; first | rfl | mem_away)
      have hK2_1 : Wide.Lv mem2 wl k flags bytes counter := Wide.Lv.frame (m := mem1) (by assumption) (fun x hx => by rw [hout2 x (by bv_decide) (by bv_decide)]; first | rfl | mem_away)
      have hK2_2 : Cv.At mem2 key k := Cv.At.frame (m := mem1) (by assumption) (fun x hx => by rw [hout2 x (by bv_decide) (by bv_decide)]; first | rfl | mem_away)
      have hOut : (∀ x : BitVec 64, (Abi.Contract.framed (Wide.contract wl input len key flags k bytes) 10064#64).stack + 8#64 ≤ x - fb → (∀ r ∈ (Abi.Contract.framed (Wide.contract wl input len key flags k bytes) 10064#64).modifies, r.2 ≤ x - r.1) → mem2 x = m0 x) := by
        intro x hx hmod
        have hx' := hx
        have hmod' := hmod
        simp only [Wide.contract, Abi.Contract.framed, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, BitVec.reduceAdd] at hx' hmod'
        rw [hout2 x (by bv_decide) (by bv_decide)]
        refine Eq.trans ?_ (hOut x hx hmod); first | rfl | mem_away
      clear hout2 hown2
      refine runs_then (a := 5) (s1 := ?_) ?_ ?_
      case refine_2 => run_fn [c0]; rfl
      refine Abi.call_meets (c := Tree32.contract (fb + 9480#64) (fb + 8456#64) key flags k (K32.values k flags counter 32#64 (Wide.group bytes counter))) (ra := 1245398#64)
        (Abi.Meets.mono (Code_wide.has_tree32 ext) (Proof_tree32.tree32_meets (Code_wide.prog ext) (fun x0 x1 x2 x3 x4 x5 x6 x7 x8 x9 x10 => Abi.Meets.mono (Code_wide.over_tree32 ext) (hA_parents16 x0 x1 x2 x3 x4 x5 x6 x7 x8 x9 x10)) (fb + 9480#64) (fb + 8456#64) key flags k (K32.values k flags counter 32#64 (Wide.group bytes counter)))) rfl rfl ?_ ?_ ?_ ?_ ?_ ?_
      · dsimp only; mem_fact
      · dsimp only [Tree32.contract]; mem_subregion
      · dsimp only
        simp only [Tree32.contract, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, Abi.WriteApart, Abi.Apart, BitVec.reduceAdd]
        try simp only [add_sub_lit, BitVec.add_assoc, BitVec.add_zero, BitVec.reduceAdd, BitVec.reduceSub]
        repeat' (with_reducible apply And.intro)
        all_goals bv_side
      · simp only [Tree32.contract]
        repeat' (with_reducible apply And.intro)
        all_goals (first | assumption | bv_side)
      · dsimp only
        simp only [Tree32.contract, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true]
        repeat' (with_reducible apply And.intro)
        all_goals (first | mem_auto | (apply_frame <;> mem_auto) | (apply_intro <;> first | mem_auto | (apply_frame <;> mem_auto)))
      · intro s3 hpc3 hsp3 hbx3 hbp3 h12_3 h13_3 h14_3 h15_3 hens3 hout3 hown3
        obtain ⟨rax_3, rcx_3, rdx_3, rbx_3, rsp_3, rbp_3, rsi_3, rdi_3, r8_3, r9_3, r12_3, r13_3, r14_3, r15_3, zf_3, cf_3, y3_0, y3_1, y3_2, y3_3, y3_4, y3_5, y3_6, y3_7, y3_8, y3_9, y3_10, y3_11, y3_12, y3_13, y3_14, y3_15, mem3, pc_3⟩ := s3
        dsimp only at hpc3 hsp3 hbx3 hbp3 h12_3 h13_3 h14_3 h15_3 hens3 hout3 hown3
        subst pc_3 rsp_3 rbx_3 rbp_3 r12_3 r13_3 r14_3 r15_3
        simp only [Tree32.contract, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true] at hens3
        split_ands hens3
        simp only [Tree32.contract, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, add_sub_lit, BitVec.add_assoc, BitVec.add_zero, BitVec.reduceAdd, BitVec.reduceSub] at hout3
        have hF3 : Region mem3 fb 10064#64 := hown3 fb 10064#64 (by mem_region)
        have hS3_0 : Quad mem3 (fb + 10064#64) ra := X86.Quad.frame (by mem_fact) (fun x hx => hout3 x (by bv_decide) (by bv_decide))
        have hS3_1 : Quad mem3 (fb + 10056#64) sv.rbx := X86.Quad.frame (by mem_fact) (fun x hx => hout3 x (by bv_decide) (by bv_decide))
        have hS3_2 : Quad mem3 (fb + 10048#64) sv.rbp := X86.Quad.frame (by mem_fact) (fun x hx => hout3 x (by bv_decide) (by bv_decide))
        have hS3_3 : Quad mem3 (fb + 10040#64) sv.r12 := X86.Quad.frame (by mem_fact) (fun x hx => hout3 x (by bv_decide) (by bv_decide))
        have hS3_4 : Quad mem3 (fb + 10032#64) sv.r13 := X86.Quad.frame (by mem_fact) (fun x hx => hout3 x (by bv_decide) (by bv_decide))
        have hS3_5 : Quad mem3 (fb + 10024#64) sv.r14 := X86.Quad.frame (by mem_fact) (fun x hx => hout3 x (by bv_decide) (by bv_decide))
        have hS3_6 : Quad mem3 (fb + 10016#64) sv.r15 := X86.Quad.frame (by mem_fact) (fun x hx => hout3 x (by bv_decide) (by bv_decide))
        have hS3_7 : Quad mem3 (fb + 9992#64) input := X86.Quad.frame (by mem_fact) (fun x hx => hout3 x (by bv_decide) (by bv_decide))
        have hS3_8 : Quad mem3 (fb + 10000#64) len := X86.Quad.frame (by mem_fact) (fun x hx => hout3 x (by bv_decide) (by bv_decide))
        have hS3_9 : Quad mem3 (fb + 10008#64) (flags ||| 1073873152#64) := X86.Quad.frame (by mem_fact) (fun x hx => hout3 x (by bv_decide) (by bv_decide))
        have hK3_0 : Hash.In mem3 input len bytes p rem counter := Hash.In.frame (m := mem2) (by assumption) (fun x hx => by rw [hout3 x (by bv_decide) (by bv_decide)]; first | rfl | mem_away)
        have hK3_1 : Wide.Lv mem3 wl k flags bytes counter := Wide.Lv.frame (m := mem2) (by assumption) (fun x hx => by rw [hout3 x (by bv_decide) (by bv_decide)]; first | rfl | mem_away)
        have hK3_2 : Cv.At mem3 key k := Cv.At.frame (m := mem2) (by assumption) (fun x hx => by rw [hout3 x (by bv_decide) (by bv_decide)]; first | rfl | mem_away)
        have hOut : (∀ x : BitVec 64, (Abi.Contract.framed (Wide.contract wl input len key flags k bytes) 10064#64).stack + 8#64 ≤ x - fb → (∀ r ∈ (Abi.Contract.framed (Wide.contract wl input len key flags k bytes) 10064#64).modifies, r.2 ≤ x - r.1) → mem3 x = m0 x) := by
          intro x hx hmod
          have hx' := hx
          have hmod' := hmod
          simp only [Wide.contract, Abi.Contract.framed, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, BitVec.reduceAdd] at hx' hmod'
          rw [hout3 x (by bv_decide) (by bv_decide)]
          refine Eq.trans ?_ (hOut x hx hmod); first | rfl | mem_away
        clear hout3 hown3
        refine runs_then (a := 6) (s1 := ?_) ?_ ?_
        case refine_2 => run_fn [c0]; rfl
        have_by hN4_0 := Wide.unit_cv (m := mem3)
        try norm_addr at hN4_0
        split_ands hN4_0
        refine Abi.call_meets (c := Ladd.contract wl key flags 5#64 (fb + 9480#64) k (Wide.units k flags bytes counter.toNat) (Wide.unit k flags bytes (counter.toNat / 32))) (ra := 1245427#64)
          (Abi.Meets.mono (Code_wide.has_ladd ext) (Proof_ladd.ladd_meets wl key flags 5#64 (fb + 9480#64) k (Wide.units k flags bytes counter.toNat) (Wide.unit k flags bytes (counter.toNat / 32)))) rfl rfl ?_ ?_ ?_ ?_ ?_ ?_
        · dsimp only; mem_fact
        · dsimp only [Ladd.contract]; mem_subregion
        · dsimp only
          simp only [Ladd.contract, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, Abi.WriteApart, Abi.Apart, BitVec.reduceAdd]
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
        · intro s4 hpc4 hsp4 hbx4 hbp4 h12_4 h13_4 h14_4 h15_4 hens4 hout4 hown4
          obtain ⟨rax_4, rcx_4, rdx_4, rbx_4, rsp_4, rbp_4, rsi_4, rdi_4, r8_4, r9_4, r12_4, r13_4, r14_4, r15_4, zf_4, cf_4, y4_0, y4_1, y4_2, y4_3, y4_4, y4_5, y4_6, y4_7, y4_8, y4_9, y4_10, y4_11, y4_12, y4_13, y4_14, y4_15, mem4, pc_4⟩ := s4
          dsimp only at hpc4 hsp4 hbx4 hbp4 h12_4 h13_4 h14_4 h15_4 hens4 hout4 hown4
          subst pc_4 rsp_4 rbx_4 rbp_4 r12_4 r13_4 r14_4 r15_4
          simp only [Ladd.contract, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true] at hens4
          split_ands hens4
          simp only [Ladd.contract, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, add_sub_lit, BitVec.add_assoc, BitVec.add_zero, BitVec.reduceAdd, BitVec.reduceSub] at hout4
          have hF4 : Region mem4 fb 10064#64 := hown4 fb 10064#64 (by mem_region)
          have hS4_0 : Quad mem4 (fb + 10064#64) ra := X86.Quad.frame (by mem_fact) (fun x hx => hout4 x (by bv_decide) (by bv_decide))
          have hS4_1 : Quad mem4 (fb + 10056#64) sv.rbx := X86.Quad.frame (by mem_fact) (fun x hx => hout4 x (by bv_decide) (by bv_decide))
          have hS4_2 : Quad mem4 (fb + 10048#64) sv.rbp := X86.Quad.frame (by mem_fact) (fun x hx => hout4 x (by bv_decide) (by bv_decide))
          have hS4_3 : Quad mem4 (fb + 10040#64) sv.r12 := X86.Quad.frame (by mem_fact) (fun x hx => hout4 x (by bv_decide) (by bv_decide))
          have hS4_4 : Quad mem4 (fb + 10032#64) sv.r13 := X86.Quad.frame (by mem_fact) (fun x hx => hout4 x (by bv_decide) (by bv_decide))
          have hS4_5 : Quad mem4 (fb + 10024#64) sv.r14 := X86.Quad.frame (by mem_fact) (fun x hx => hout4 x (by bv_decide) (by bv_decide))
          have hS4_6 : Quad mem4 (fb + 10016#64) sv.r15 := X86.Quad.frame (by mem_fact) (fun x hx => hout4 x (by bv_decide) (by bv_decide))
          have hS4_7 : Quad mem4 (fb + 9992#64) input := X86.Quad.frame (by mem_fact) (fun x hx => hout4 x (by bv_decide) (by bv_decide))
          have hS4_8 : Quad mem4 (fb + 10000#64) len := X86.Quad.frame (by mem_fact) (fun x hx => hout4 x (by bv_decide) (by bv_decide))
          have hS4_9 : Quad mem4 (fb + 10008#64) (flags ||| 1073873152#64) := X86.Quad.frame (by mem_fact) (fun x hx => hout4 x (by bv_decide) (by bv_decide))
          have hK4_0 : Hash.In mem4 input len bytes p rem counter := Hash.In.frame (m := mem3) (by assumption) (fun x hx => by rw [hout4 x (by bv_decide) (by bv_decide)]; first | rfl | mem_away)
          have hK4_1 : Cv.At mem4 key k := Cv.At.frame (m := mem3) (by assumption) (fun x hx => by rw [hout4 x (by bv_decide) (by bv_decide)]; first | rfl | mem_away)
          have hOut : (∀ x : BitVec 64, (Abi.Contract.framed (Wide.contract wl input len key flags k bytes) 10064#64).stack + 8#64 ≤ x - fb → (∀ r ∈ (Abi.Contract.framed (Wide.contract wl input len key flags k bytes) 10064#64).modifies, r.2 ≤ x - r.1) → mem4 x = m0 x) := by
            intro x hx hmod
            have hx' := hx
            have hmod' := hmod
            simp only [Wide.contract, Abi.Contract.framed, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, BitVec.reduceAdd] at hx' hmod'
            rw [hout4 x (by bv_decide) (by bv_decide)]
            refine Eq.trans ?_ (hOut x hx hmod); first | rfl | mem_away
          clear hout4 hown4
          refine runs_then (a := 10) (s1 := ?_) ?_ ?_
          case refine_2 => run_fn [c0]; rfl
          refine runs_done ⟨⟨rfl, rfl, rfl, rfl, rfl, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_⟩, ?_⟩
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
            simp only [Wide.contract, Abi.Contract.framed, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, BitVec.reduceAdd] at hx' hmod'
            first | rfl | mem_away
          · exact hAcc0
          · exact hReq0
          · skip
            refine ⟨?_, ?_, ?_, ?_⟩
            · mem_fact
            · apply Wide.In.step32 <;> mem_auto
            · apply Wide.Lv.step <;> mem_auto
            · first | mem_auto | (apply Cv.At.frame <;> mem_auto)
          · exact BitVec.lt_def.mp (by bv_decide)

theorem leave (ext : Nat → Option (Instr × Nat)) (hA_chunks32 : ∀ x0 x1 x2 x3 x4 x5 x6 x7 x8 x9 x10, Abi.Meets (Code_wide.prog ext) 0x10000 (K32.contract x0 x1 x2 x3 x4 x5 x6 x7 x8 x9 x10)) (hA_parents16 : ∀ x0 x1 x2 x3 x4 x5 x6 x7 x8 x9 x10, Abi.Meets (Code_wide.prog ext) 0x18000 (P16.contract x0 x1 x2 x3 x4 x5 x6 x7 x8 x9 x10)) (fb wl input len key flags ra : BitVec 64) (sv : Abi.Saved) (k : Blake3.CV) (bytes : List (BitVec 8)) (m0 : Mem)
    (s : State) (hI : Inv fb wl input len key flags ra sv k bytes m0 s) (hc : ¬ 32768#64 < s.rbp) :
    ∃ n_ s', steps (Code_wide.prog ext) n_ s = some s' ∧ Abi.Post (Abi.Contract.framed (Wide.contract wl input len key flags k bytes) 10064#64) fb ra sv m0 s' := by
  obtain ⟨rax, rcx, rdx, p, rsp, rem, rsi, rdi, r8, r9, counter, r13, r14, r15, zf, cf, x0, x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12, x13, x14, x15, mem, pc⟩ := s
  obtain ⟨hpc, hsp, hp0, hp1, hp2, hF, hRa, hS0, hS1, hS2, hS3, hS4, hS5, hPs0, hPs1, hAp, hOut, hAcc, hReq, hZ0, hI0, hI1, hI2⟩ := hI
  simp only at hpc hsp hp0 hp1 hp2 hF hRa hS0 hS1 hS2 hS3 hS4 hS5 hPs0 hPs1 hOut hZ0 hI0 hI1 hI2 hc
  subst pc rsp r13 r14 r15
  have hAp0 := hAp
  simp only [Wide.contract, Abi.Contract.framed, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, Abi.WriteApart, Abi.Apart, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, BitVec.reduceAdd] at hAp
  split_ands hAp
  have hAcc0 := hAcc
  try (simp only [Wide.contract, Abi.Contract.framed, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true] at hAcc; split_ands hAcc)
  have hReq0 := hReq
  simp only [Wide.contract, Abi.Contract.framed, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true] at hReq
  split_ands hReq
  forget_about m0 except hOut hReq0
  try (have hK0 := Hash.In.cells (m := mem) (by assumption); split_ands hK0)
  try (have hK1 := Wide.Lv.cells (m := mem) (by assumption); split_ands hK1)
  try (have hK2 := Cv.At.cells (m := mem) (by assumption); split_ands hK2)
  have c0 : (32768#64).ult (rem) = false := by bv_decide
  refine runs_then (a := 13) (s1 := ?_) ?_ ?_
  case refine_2 => run_fn [c0]; rfl
  refine runs_done ⟨rfl, by simp only [Wide.contract, Abi.Contract.framed]; bv_decide, rfl, rfl, rfl, rfl, rfl, rfl, ?_, ?_⟩
  all_goals try dsimp only
  · intro x hx hmod
    refine Eq.trans ?_ (hOut x hx hmod)
    have hx' := hx
    have hmod' := hmod
    simp only [Wide.contract, Abi.Contract.framed, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, BitVec.reduceAdd] at hx' hmod'
    first | rfl | mem_away
  · simp only [Wide.contract, Abi.Contract.framed, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true]
    apply Wide.exit <;> mem_auto

/-- **`wide`, as assembled, meets its contract, whatever its arguments.** -/
theorem wide_meets (ext : Nat → Option (Instr × Nat)) (hA_chunks32 : ∀ x0 x1 x2 x3 x4 x5 x6 x7 x8 x9 x10, Abi.Meets (Code_wide.prog ext) 0x10000 (K32.contract x0 x1 x2 x3 x4 x5 x6 x7 x8 x9 x10)) (hA_parents16 : ∀ x0 x1 x2 x3 x4 x5 x6 x7 x8 x9 x10, Abi.Meets (Code_wide.prog ext) 0x18000 (P16.contract x0 x1 x2 x3 x4 x5 x6 x7 x8 x9 x10)) : ∀ (wl input len key flags : BitVec 64) (k : Blake3.CV) (bytes : List (BitVec 8)),
    Abi.Meets (Code_wide.prog ext) 0x130000 (Wide.contract wl input len key flags k bytes) := by
  intro wl input len key flags k bytes
  refine Abi.meets_of_triple 10064#64 (by dsimp only [Wide.contract]; decide) (by dsimp only [Wide.contract]; decide) (fun fb ra sv m0 => ?_)
  refine Hoare.seq (Q := Inv fb wl input len key flags ra sv k bytes m0) ?_ ?_
  · intro s hP
    exact enter ext hA_chunks32 hA_parents16 fb wl input len key flags ra sv k bytes m0 s hP
  · refine Hoare.loop (fun s => s.rbp.toNat) (fun s hI => ?_)
    by_cases hc : 32768#64 < s.rbp
    · obtain ⟨n_, s', h, hi, hm⟩ := turn ext hA_chunks32 hA_parents16 fb wl input len key flags ra sv k bytes m0 s hI hc
      exact ⟨n_, s', h, Or.inl ⟨hi, hm⟩⟩
    · obtain ⟨n_, s', h, hq⟩ := leave ext hA_chunks32 hA_parents16 fb wl input len key flags ra sv k bytes m0 s hI hc
      exact ⟨n_, s', h, Or.inr hq⟩

#print axioms wide_meets

end Proof_wide
