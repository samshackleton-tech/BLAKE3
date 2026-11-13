import Cells
import Kernels
import AbiProof
import AbiCall
import Spec_k32
import Lemmas_k32s
import Proof_chunk_node
import Proof_node_out
import Code_k32s
open X86 Cells

/-! # `k32s`, as assembled, meets `K32.contract`

Written by prove_fn.py from levels.ode and the compiler's layout; not edited by hand, and not to be read
but for its last theorem's statement: Lean checks the rest. The frame: 480 bytes below the stack pointer at entry
(`fb` is its lowest address), the caller's rbx, rbp, r12, r13, r14, r15 at its top.
-/

namespace Proof_k32s

set_option maxRecDepth 1000000
set_option maxHeartbeats 0
set_option linter.unusedVariables false

/-- What holds each time the loop's head is reached: the source's `invariant` clauses, each variable where the
compiler keeps it, and the frame as the compiler keeps it. -/
def Inv (fb inputs blocks key counter packed out ra : BitVec 64) (sv : Abi.Saved) (k : Blake3.CV) (base : BitVec 64) (n : BitVec 64) (flags : BitVec 64) (bytes : List (BitVec 8)) (m0 : Mem) (s : State) : Prop :=
  s.pc = 0x10045 ∧
  s.rsp = (fb + 264#64) ∧
  s.r12 = inputs ∧
  s.r13 = key ∧
  s.r15 = counter ∧
  s.r14 = out ∧
  Region s.mem fb 480#64 ∧
  Quad s.mem (fb + 480#64) ra ∧
  Quad s.mem (fb + 472#64) sv.rbx ∧
  Quad s.mem (fb + 464#64) sv.rbp ∧
  Quad s.mem (fb + 456#64) sv.r12 ∧
  Quad s.mem (fb + 448#64) sv.r13 ∧
  Quad s.mem (fb + 440#64) sv.r14 ∧
  Quad s.mem (fb + 432#64) sv.r15 ∧
  Quad s.mem (fb + 384#64) blocks ∧
  Quad s.mem (fb + 392#64) packed ∧
  Abi.WriteApart ((fb, (Abi.Contract.framed (K32.contract inputs blocks key counter packed out k base n flags bytes) 480#64).stack + 8#64) :: (Abi.Contract.framed (K32.contract inputs blocks key counter packed out k base n flags bytes) 480#64).modifies) (Abi.Contract.framed (K32.contract inputs blocks key counter packed out k base n flags bytes) 480#64).reading ∧
  (∀ x : BitVec 64, (Abi.Contract.framed (K32.contract inputs blocks key counter packed out k base n flags bytes) 480#64).stack + 8#64 ≤ x - fb → (∀ r ∈ (Abi.Contract.framed (K32.contract inputs blocks key counter packed out k base n flags bytes) 480#64).modifies, r.2 ≤ x - r.1) → s.mem x = m0 x) ∧
  (Abi.Contract.framed (K32.contract inputs blocks key counter packed out k base n flags bytes) 480#64).accepts ∧
  (Abi.Contract.framed (K32.contract inputs blocks key counter packed out k base n flags bytes) 480#64).requires m0 ∧
  s.rbp = (packed &&& 255#64) ∧
    Cv.At s.mem key k ∧
    Ptrs.At s.mem inputs (Ptrs.spread base n 1024#64) ∧
    K32s.In s.mem base n bytes ∧
    K32s.Done s.mem out k flags counter n bytes s.rbx ∧
    Region s.mem out 1024#64

theorem enter (fb inputs blocks key counter packed out ra : BitVec 64) (sv : Abi.Saved) (k : Blake3.CV) (base : BitVec 64) (n : BitVec 64) (flags : BitVec 64) (bytes : List (BitVec 8)) (m0 : Mem)
    (s : State) (hP : Abi.Pre 0x10000 (Abi.Contract.framed (K32.contract inputs blocks key counter packed out k base n flags bytes) 480#64) fb ra sv m0 s) : ∃ n_ s', steps Code_k32s.prog n_ s = some s' ∧ Inv fb inputs blocks key counter packed out ra sv k base n flags bytes m0 s' := by
  obtain ⟨rax, rcx, rdx, rbx, rsp, rbp, rsi, rdi, r8, r9, r12, r13, r14, r15, zf, cf, x0, x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12, x13, x14, x15, mem, pc⟩ := s
  obtain ⟨hpc, hsp, hargs, hbx, hbp, h12, h13, h14, h15, hmem, hF, hRa, hAp, hAcc, hReq⟩ := hP
  simp only [K32.contract, Abi.Contract.framed, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true] at hpc hsp hargs hbx hbp h12 h13 h14 h15 hmem hF hRa
  simp only [List.length_cons, List.length_nil, List.take, List.cons.injEq, and_true] at hargs
  obtain ⟨ha0, ha1, ha2, ha3, ha4, ha5⟩ := hargs
  subst pc rsp rdi rsi rdx rcx r8 r9 rbx rbp r12 r13 r14 r15 mem
  have hAp0 := hAp
  simp only [K32.contract, Abi.Contract.framed, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, Abi.WriteApart, Abi.Apart, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, BitVec.reduceAdd] at hAp
  split_ands hAp
  have hAcc0 := hAcc
  try (simp only [K32.contract, Abi.Contract.framed, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true] at hAcc; split_ands hAcc)
  have hReq0 := hReq
  simp only [K32.contract, Abi.Contract.framed, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true] at hReq
  split_ands hReq
  try (have hK0 := Cv.At.cells (m := m0) (by assumption); split_ands hK0)
  try (have hK1 := Ptrs.At.cells (m := m0) (by assumption); split_ands hK1)
  try (have hK2 := K32s.In.cells (m := m0) (by assumption); split_ands hK2)
  try (have hK3 := K32s.Done.cells (m := m0) (by assumption); split_ands hK3)
  try (have hK4 := Region.cells (m := m0) (by assumption); split_ands hK4)
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
    simp only [K32.contract, Abi.Contract.framed, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, BitVec.reduceAdd] at hx' hmod'
    first | rfl | mem_away
  · exact hAcc0
  · exact hReq0
  · skip
    refine ⟨?_, ?_, ?_, ?_, ?_, ?_⟩
    · rfl
    · first | mem_auto | (apply Cv.At.frame <;> mem_auto)
    · first | mem_auto | (apply Ptrs.At.frame <;> mem_auto)
    · apply K32s.In.start <;> mem_auto
    · apply K32s.Done.start <;> mem_auto
    · first | mem_auto | (apply Region.frame <;> mem_auto)

theorem turn (fb inputs blocks key counter packed out ra : BitVec 64) (sv : Abi.Saved) (k : Blake3.CV) (base : BitVec 64) (n : BitVec 64) (flags : BitVec 64) (bytes : List (BitVec 8)) (m0 : Mem)
    (s : State) (hI : Inv fb inputs blocks key counter packed out ra sv k base n flags bytes m0 s) (hc : s.rbx < 32#64) :
    ∃ n_ s', steps Code_k32s.prog n_ s = some s' ∧ (Inv fb inputs blocks key counter packed out ra sv k base n flags bytes m0 s' ∧ ((32#64 - s'.rbx)).toNat < ((32#64 - s.rbx)).toNat) := by
  obtain ⟨rax, rcx, rdx, i, rsp, rbp, rsi, rdi, r8, r9, r12, r13, r14, r15, zf, cf, x0, x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12, x13, x14, x15, mem, pc⟩ := s
  obtain ⟨hpc, hsp, hp0, hp1, hp2, hp3, hF, hRa, hS0, hS1, hS2, hS3, hS4, hS5, hPs0, hPs1, hAp, hOut, hAcc, hReq, hZ0, hI0, hI1, hI2, hI3, hI4⟩ := hI
  simp only at hpc hsp hp0 hp1 hp2 hp3 hF hRa hS0 hS1 hS2 hS3 hS4 hS5 hPs0 hPs1 hOut hZ0 hI0 hI1 hI2 hI3 hI4 hc
  subst pc rsp r12 r13 r15 r14 rbp
  have hAp0 := hAp
  simp only [K32.contract, Abi.Contract.framed, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, Abi.WriteApart, Abi.Apart, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, BitVec.reduceAdd] at hAp
  split_ands hAp
  have hAcc0 := hAcc
  try (simp only [K32.contract, Abi.Contract.framed, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true] at hAcc; split_ands hAcc)
  have hReq0 := hReq
  simp only [K32.contract, Abi.Contract.framed, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true] at hReq
  split_ands hReq
  forget_about m0 except hOut hReq0
  try (have hK0 := Cv.At.cells (m := mem) (by assumption); split_ands hK0)
  try (have hK1 := Ptrs.At.cells (m := mem) (by assumption); split_ands hK1)
  try (have hK2 := K32s.In.cells (m := mem) (by assumption); split_ands hK2)
  try (have hK3 := K32s.Done.cells (m := mem) (by assumption); split_ands hK3)
  try (have hK4 := Region.cells (m := mem) (by assumption); split_ands hK4)
  have_by hO0 := K32s.turn (m := mem)
  obtain ⟨k0, k1, hO0⟩ := hO0
  try norm_addr at hO0
  split_ands hO0
  have c0 : (i).ult (32#64) = true := by bv_decide
  refine runs_then (a := 26) (s1 := ?_) ?_ ?_
  case refine_2 => run_fn [c0]; rfl
  refine Abi.call_meets (c := ChunkNode.contract (fb + 264#64) (K32s.src base n i) 1024#64 (counter + i) (packed &&& 255#64) 5#64 k (K32.input n bytes i.toNat)) (ra := 65725#64)
    (Abi.Meets.mono Code_k32s.has_chunk_node (Proof_chunk_node.chunk_node_meets (fb + 264#64) (K32s.src base n i) 1024#64 (counter + i) (packed &&& 255#64) 5#64 k (K32.input n bytes i.toNat))) rfl rfl ?_ ?_ ?_ ?_ ?_ ?_
  · dsimp only; mem_fact
  · dsimp only [ChunkNode.contract]; mem_subregion
  · dsimp only
    simp only [ChunkNode.contract, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, Abi.WriteApart, Abi.Apart, BitVec.reduceAdd]
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
  · intro s1 hpc1 hsp1 hbx1 hbp1 h12_1 h13_1 h14_1 h15_1 hens1 hout1 hown1
    obtain ⟨rax_1, rcx_1, rdx_1, rbx_1, rsp_1, rbp_1, rsi_1, rdi_1, r8_1, r9_1, r12_1, r13_1, r14_1, r15_1, zf_1, cf_1, y1_0, y1_1, y1_2, y1_3, y1_4, y1_5, y1_6, y1_7, y1_8, y1_9, y1_10, y1_11, y1_12, y1_13, y1_14, y1_15, mem1, pc_1⟩ := s1
    dsimp only at hpc1 hsp1 hbx1 hbp1 h12_1 h13_1 h14_1 h15_1 hens1 hout1 hown1
    subst pc_1 rsp_1 rbx_1 rbp_1 r12_1 r13_1 r14_1 r15_1
    simp only [ChunkNode.contract, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true] at hens1
    split_ands hens1
    simp only [ChunkNode.contract, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, add_sub_lit, BitVec.add_assoc, BitVec.add_zero, BitVec.reduceAdd, BitVec.reduceSub] at hout1
    have hF1 : Region mem1 fb 480#64 := hown1 fb 480#64 (by mem_region)
    have hS1_0 : Quad mem1 (fb + 480#64) ra := X86.Quad.frame (by mem_fact) (fun x hx => hout1 x (by bv_decide) (by bv_decide))
    have hS1_1 : Quad mem1 (fb + 472#64) sv.rbx := X86.Quad.frame (by mem_fact) (fun x hx => hout1 x (by bv_decide) (by bv_decide))
    have hS1_2 : Quad mem1 (fb + 464#64) sv.rbp := X86.Quad.frame (by mem_fact) (fun x hx => hout1 x (by bv_decide) (by bv_decide))
    have hS1_3 : Quad mem1 (fb + 456#64) sv.r12 := X86.Quad.frame (by mem_fact) (fun x hx => hout1 x (by bv_decide) (by bv_decide))
    have hS1_4 : Quad mem1 (fb + 448#64) sv.r13 := X86.Quad.frame (by mem_fact) (fun x hx => hout1 x (by bv_decide) (by bv_decide))
    have hS1_5 : Quad mem1 (fb + 440#64) sv.r14 := X86.Quad.frame (by mem_fact) (fun x hx => hout1 x (by bv_decide) (by bv_decide))
    have hS1_6 : Quad mem1 (fb + 432#64) sv.r15 := X86.Quad.frame (by mem_fact) (fun x hx => hout1 x (by bv_decide) (by bv_decide))
    have hS1_7 : Quad mem1 (fb + 384#64) blocks := X86.Quad.frame (by mem_fact) (fun x hx => hout1 x (by bv_decide) (by bv_decide))
    have hS1_8 : Quad mem1 (fb + 392#64) packed := X86.Quad.frame (by mem_fact) (fun x hx => hout1 x (by bv_decide) (by bv_decide))
    have hK1_0 : Cv.At mem1 key k := Cv.At.frame (m := mem) (by assumption) (fun x hx => by rw [hout1 x (by bv_decide) (by bv_decide)]; first | rfl | mem_away)
    have hK1_1 : Ptrs.At mem1 inputs (Ptrs.spread base n 1024#64) := Ptrs.At.frame (m := mem) (by assumption) (fun x hx => by rw [hout1 x (by bv_decide) (by bv_decide)]; first | rfl | mem_away)
    have hK1_2 : K32s.In mem1 base n bytes := K32s.In.frame (m := mem) (by assumption) (fun x hx => by rw [hout1 x (by bv_decide) (by bv_decide)]; first | rfl | mem_away)
    have hK1_3 : K32s.Done mem1 out k flags counter n bytes i := K32s.Done.frame (m := mem) (by assumption) (fun x hx => by rw [hout1 x (by bv_decide) (by bv_decide)]; first | rfl | mem_away)
    have hK1_4 : Region mem1 out 1024#64 := hown1 _ _ (by mem_region)
    have hOut : (∀ x : BitVec 64, (Abi.Contract.framed (K32.contract inputs blocks key counter packed out k base n flags bytes) 480#64).stack + 8#64 ≤ x - fb → (∀ r ∈ (Abi.Contract.framed (K32.contract inputs blocks key counter packed out k base n flags bytes) 480#64).modifies, r.2 ≤ x - r.1) → mem1 x = m0 x) := by
      intro x hx hmod
      have hx' := hx
      have hmod' := hmod
      simp only [K32.contract, Abi.Contract.framed, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, BitVec.reduceAdd] at hx' hmod'
      rw [hout1 x (by bv_decide) (by bv_decide)]
      refine Eq.trans ?_ (hOut x hx hmod); first | rfl | mem_away
    clear hout1 hown1
    refine runs_then (a := 10) (s1 := ?_) ?_ ?_
    case refine_2 => run_fn [c0]; rfl
    refine Abi.call_meets (c := NodeOut.contract (out + (i <<< 5)) (fb + 264#64) 0#64 5#64 (Chunk.node k (packed &&& 255#64) (counter + i) (K32.input n bytes i.toNat))) (ra := 65777#64)
      (Abi.Meets.mono Code_k32s.has_node_out (Proof_node_out.node_out_meets (out + (i <<< 5)) (fb + 264#64) 0#64 5#64 (Chunk.node k (packed &&& 255#64) (counter + i) (K32.input n bytes i.toNat)))) rfl rfl ?_ ?_ ?_ ?_ ?_ ?_
    · dsimp only; mem_fact
    · dsimp only [NodeOut.contract]; mem_subregion
    · dsimp only
      simp only [NodeOut.contract, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, Abi.WriteApart, Abi.Apart, BitVec.reduceAdd]
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
    · intro s2 hpc2 hsp2 hbx2 hbp2 h12_2 h13_2 h14_2 h15_2 hens2 hout2 hown2
      obtain ⟨rax_2, rcx_2, rdx_2, rbx_2, rsp_2, rbp_2, rsi_2, rdi_2, r8_2, r9_2, r12_2, r13_2, r14_2, r15_2, zf_2, cf_2, y2_0, y2_1, y2_2, y2_3, y2_4, y2_5, y2_6, y2_7, y2_8, y2_9, y2_10, y2_11, y2_12, y2_13, y2_14, y2_15, mem2, pc_2⟩ := s2
      dsimp only at hpc2 hsp2 hbx2 hbp2 h12_2 h13_2 h14_2 h15_2 hens2 hout2 hown2
      subst pc_2 rsp_2 rbx_2 rbp_2 r12_2 r13_2 r14_2 r15_2
      simp only [NodeOut.contract, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true] at hens2
      split_ands hens2
      simp only [NodeOut.contract, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, add_sub_lit, BitVec.add_assoc, BitVec.add_zero, BitVec.reduceAdd, BitVec.reduceSub] at hout2
      have hF2 : Region mem2 fb 480#64 := hown2 fb 480#64 (by mem_region)
      have hS2_0 : Quad mem2 (fb + 480#64) ra := X86.Quad.frame (by mem_fact) (fun x hx => hout2 x (by bv_decide) (by bv_decide))
      have hS2_1 : Quad mem2 (fb + 472#64) sv.rbx := X86.Quad.frame (by mem_fact) (fun x hx => hout2 x (by bv_decide) (by bv_decide))
      have hS2_2 : Quad mem2 (fb + 464#64) sv.rbp := X86.Quad.frame (by mem_fact) (fun x hx => hout2 x (by bv_decide) (by bv_decide))
      have hS2_3 : Quad mem2 (fb + 456#64) sv.r12 := X86.Quad.frame (by mem_fact) (fun x hx => hout2 x (by bv_decide) (by bv_decide))
      have hS2_4 : Quad mem2 (fb + 448#64) sv.r13 := X86.Quad.frame (by mem_fact) (fun x hx => hout2 x (by bv_decide) (by bv_decide))
      have hS2_5 : Quad mem2 (fb + 440#64) sv.r14 := X86.Quad.frame (by mem_fact) (fun x hx => hout2 x (by bv_decide) (by bv_decide))
      have hS2_6 : Quad mem2 (fb + 432#64) sv.r15 := X86.Quad.frame (by mem_fact) (fun x hx => hout2 x (by bv_decide) (by bv_decide))
      have hS2_7 : Quad mem2 (fb + 384#64) blocks := X86.Quad.frame (by mem_fact) (fun x hx => hout2 x (by bv_decide) (by bv_decide))
      have hS2_8 : Quad mem2 (fb + 392#64) packed := X86.Quad.frame (by mem_fact) (fun x hx => hout2 x (by bv_decide) (by bv_decide))
      have hK2_0 : Cv.At mem2 key k := Cv.At.frame (m := mem1) (by assumption) (fun x hx => by rw [hout2 x (by bv_decide) (by bv_decide)]; first | rfl | mem_away)
      have hK2_1 : Ptrs.At mem2 inputs (Ptrs.spread base n 1024#64) := Ptrs.At.frame (m := mem1) (by assumption) (fun x hx => by rw [hout2 x (by bv_decide) (by bv_decide)]; first | rfl | mem_away)
      have hK2_2 : K32s.In mem2 base n bytes := K32s.In.frame (m := mem1) (by assumption) (fun x hx => by rw [hout2 x (by bv_decide) (by bv_decide)]; first | rfl | mem_away)
      have hK2_3 : K32s.Done mem2 out k flags counter n bytes i := K32s.Done.frame (m := mem1) (by assumption) (fun x hx => by rw [hout2 x (by bv_decide) (by bv_decide)]; first | rfl | mem_away)
      have hK2_4 : Region mem2 out 1024#64 := hown2 _ _ (by mem_region)
      have hOut : (∀ x : BitVec 64, (Abi.Contract.framed (K32.contract inputs blocks key counter packed out k base n flags bytes) 480#64).stack + 8#64 ≤ x - fb → (∀ r ∈ (Abi.Contract.framed (K32.contract inputs blocks key counter packed out k base n flags bytes) 480#64).modifies, r.2 ≤ x - r.1) → mem2 x = m0 x) := by
        intro x hx hmod
        have hx' := hx
        have hmod' := hmod
        simp only [K32.contract, Abi.Contract.framed, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, BitVec.reduceAdd] at hx' hmod'
        rw [hout2 x (by bv_decide) (by bv_decide)]
        refine Eq.trans ?_ (hOut x hx hmod); first | rfl | mem_away
      clear hout2 hown2
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
        simp only [K32.contract, Abi.Contract.framed, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, BitVec.reduceAdd] at hx' hmod'
        first | rfl | mem_away
      · exact hAcc0
      · exact hReq0
      · skip
        refine ⟨?_, ?_, ?_, ?_, ?_, ?_⟩
        · rfl
        · first | mem_auto | (apply Cv.At.frame <;> mem_auto)
        · first | mem_auto | (apply Ptrs.At.frame <;> mem_auto)
        · first | mem_auto | (apply K32s.In.frame <;> mem_auto)
        · apply K32s.Done.step <;> mem_auto
        · first | mem_auto | (apply Region.frame <;> mem_auto)
      · exact BitVec.lt_def.mp (by bv_decide)

theorem leave (fb inputs blocks key counter packed out ra : BitVec 64) (sv : Abi.Saved) (k : Blake3.CV) (base : BitVec 64) (n : BitVec 64) (flags : BitVec 64) (bytes : List (BitVec 8)) (m0 : Mem)
    (s : State) (hI : Inv fb inputs blocks key counter packed out ra sv k base n flags bytes m0 s) (hc : ¬ s.rbx < 32#64) :
    ∃ n_ s', steps Code_k32s.prog n_ s = some s' ∧ Abi.Post (Abi.Contract.framed (K32.contract inputs blocks key counter packed out k base n flags bytes) 480#64) fb ra sv m0 s' := by
  obtain ⟨rax, rcx, rdx, i, rsp, rbp, rsi, rdi, r8, r9, r12, r13, r14, r15, zf, cf, x0, x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12, x13, x14, x15, mem, pc⟩ := s
  obtain ⟨hpc, hsp, hp0, hp1, hp2, hp3, hF, hRa, hS0, hS1, hS2, hS3, hS4, hS5, hPs0, hPs1, hAp, hOut, hAcc, hReq, hZ0, hI0, hI1, hI2, hI3, hI4⟩ := hI
  simp only at hpc hsp hp0 hp1 hp2 hp3 hF hRa hS0 hS1 hS2 hS3 hS4 hS5 hPs0 hPs1 hOut hZ0 hI0 hI1 hI2 hI3 hI4 hc
  subst pc rsp r12 r13 r15 r14 rbp
  have hAp0 := hAp
  simp only [K32.contract, Abi.Contract.framed, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, Abi.WriteApart, Abi.Apart, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, BitVec.reduceAdd] at hAp
  split_ands hAp
  have hAcc0 := hAcc
  try (simp only [K32.contract, Abi.Contract.framed, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true] at hAcc; split_ands hAcc)
  have hReq0 := hReq
  simp only [K32.contract, Abi.Contract.framed, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true] at hReq
  split_ands hReq
  forget_about m0 except hOut hReq0
  try (have hK0 := Cv.At.cells (m := mem) (by assumption); split_ands hK0)
  try (have hK1 := Ptrs.At.cells (m := mem) (by assumption); split_ands hK1)
  try (have hK2 := K32s.In.cells (m := mem) (by assumption); split_ands hK2)
  try (have hK3 := K32s.Done.cells (m := mem) (by assumption); split_ands hK3)
  try (have hK4 := Region.cells (m := mem) (by assumption); split_ands hK4)
  have c0 : (i).ult (32#64) = false := by bv_decide
  refine runs_then (a := 12) (s1 := ?_) ?_ ?_
  case refine_2 => run_fn [c0]; rfl
  refine runs_done ⟨rfl, by simp only [K32.contract, Abi.Contract.framed]; bv_decide, rfl, rfl, rfl, rfl, rfl, rfl, ?_, ?_⟩
  all_goals try dsimp only
  · intro x hx hmod
    refine Eq.trans ?_ (hOut x hx hmod)
    have hx' := hx
    have hmod' := hmod
    simp only [K32.contract, Abi.Contract.framed, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, BitVec.reduceAdd] at hx' hmod'
    first | rfl | mem_away
  · simp only [K32.contract, Abi.Contract.framed, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true]
    apply K32s.exit <;> mem_auto

/-- **`k32s`, as assembled, meets its contract, whatever its arguments.** -/
theorem k32s_meets : ∀ (inputs blocks key counter packed out : BitVec 64) (k : Blake3.CV) (base : BitVec 64) (n : BitVec 64) (flags : BitVec 64) (bytes : List (BitVec 8)),
    Abi.Meets Code_k32s.prog 0x10000 (K32.contract inputs blocks key counter packed out k base n flags bytes) := by
  intro inputs blocks key counter packed out k base n flags bytes
  refine Abi.meets_of_triple 480#64 (by dsimp only [K32.contract]; decide) (by dsimp only [K32.contract]; decide) (fun fb ra sv m0 => ?_)
  refine Hoare.seq (Q := Inv fb inputs blocks key counter packed out ra sv k base n flags bytes m0) ?_ ?_
  · intro s hP
    exact enter fb inputs blocks key counter packed out ra sv k base n flags bytes m0 s hP
  · refine Hoare.loop (fun s => ((32#64 - s.rbx)).toNat) (fun s hI => ?_)
    by_cases hc : s.rbx < 32#64
    · obtain ⟨n_, s', h, hi, hm⟩ := turn fb inputs blocks key counter packed out ra sv k base n flags bytes m0 s hI hc
      exact ⟨n_, s', h, Or.inl ⟨hi, hm⟩⟩
    · obtain ⟨n_, s', h, hq⟩ := leave fb inputs blocks key counter packed out ra sv k base n flags bytes m0 s hI hc
      exact ⟨n_, s', h, Or.inr hq⟩

#print axioms k32s_meets

end Proof_k32s
