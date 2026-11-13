import Cells
import Kernels
import AbiProof
import AbiCall
import Spec_addn
import Lemmas_addn
import Proof_ladd
import Code_addn
open X86 Cells

/-! # `addn`, as assembled, meets `Addn.contract`

Written by prove_fn.py from levels.ode and the compiler's layout; not edited by hand, and not to be read
but for its last theorem's statement: Lean checks the rest. The frame: 320 bytes below the stack pointer at entry
(`fb` is its lowest address), the caller's rbx, rbp, r12, r13, r14, r15 at its top.
-/

namespace Proof_addn

set_option maxRecDepth 1000000
set_option maxHeartbeats 0
set_option linter.unusedVariables false

/-- What holds each time the loop's head is reached: the source's `invariant` clauses, each variable where the
compiler keeps it, and the frame as the compiler keeps it. -/
def Inv (fb lv key flags cvs n ra : BitVec 64) (sv : Abi.Saved) (k : Blake3.CV) (chunks : Array Blake3.Node) (news : List Blake3.Node) (vals : List Blake3.CV) (m0 : Mem) (s : State) : Prop :=
  s.pc = 0x16002F ∧
  s.rsp = (fb + 264#64) ∧
  s.r12 = lv ∧
  s.r13 = key ∧
  s.r14 = flags ∧
  s.r15 = n ∧
  Region s.mem fb 320#64 ∧
  Quad s.mem (fb + 320#64) ra ∧
  Quad s.mem (fb + 312#64) sv.rbx ∧
  Quad s.mem (fb + 304#64) sv.rbp ∧
  Quad s.mem (fb + 296#64) sv.r12 ∧
  Quad s.mem (fb + 288#64) sv.r13 ∧
  Quad s.mem (fb + 280#64) sv.r14 ∧
  Quad s.mem (fb + 272#64) sv.r15 ∧
  Quad s.mem (fb + 264#64) cvs ∧
  Abi.AllApart ((fb, (Abi.Contract.framed (Addn.contract lv key flags cvs n k chunks news vals) 320#64).stack + 8#64) :: (Abi.Contract.framed (Addn.contract lv key flags cvs n k chunks news vals) 320#64).regions) ∧
  (∀ x : BitVec 64, (Abi.Contract.framed (Addn.contract lv key flags cvs n k chunks news vals) 320#64).stack + 8#64 ≤ x - fb → (∀ r ∈ (Abi.Contract.framed (Addn.contract lv key flags cvs n k chunks news vals) 320#64).modifies, r.2 ≤ x - r.1) → s.mem x = m0 x) ∧
  (Abi.Contract.framed (Addn.contract lv key flags cvs n k chunks news vals) 320#64).accepts ∧
  (Abi.Contract.framed (Addn.contract lv key flags cvs n k chunks news vals) 320#64).requires m0 ∧
  Addn.Mid s.mem lv cvs k flags chunks news vals n s.rbx s.rbp ∧
    Cv.At s.mem key k

theorem enter (fb lv key flags cvs n ra : BitVec 64) (sv : Abi.Saved) (k : Blake3.CV) (chunks : Array Blake3.Node) (news : List Blake3.Node) (vals : List Blake3.CV) (m0 : Mem)
    (s : State) (hP : Abi.Pre 0x160000 (Abi.Contract.framed (Addn.contract lv key flags cvs n k chunks news vals) 320#64) fb ra sv m0 s) : ∃ n_ s', steps Code_addn.prog n_ s = some s' ∧ Inv fb lv key flags cvs n ra sv k chunks news vals m0 s' := by
  obtain ⟨rax, rcx, rdx, rbx, rsp, rbp, rsi, rdi, r8, r9, r12, r13, r14, r15, zf, cf, x0, x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12, x13, x14, x15, mem, pc⟩ := s
  obtain ⟨hpc, hsp, hargs, hbx, hbp, h12, h13, h14, h15, hmem, hF, hRa, hAp, hAcc, hReq⟩ := hP
  simp only [Addn.contract, Abi.Contract.framed, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true] at hpc hsp hargs hbx hbp h12 h13 h14 h15 hmem hF hRa
  simp only [List.length_cons, List.length_nil, List.take, List.cons.injEq, and_true] at hargs
  obtain ⟨ha0, ha1, ha2, ha3, ha4⟩ := hargs
  subst pc rsp rdi rsi rdx rcx r8 rbx rbp r12 r13 r14 r15 mem
  have hAp0 := hAp
  simp only [Addn.contract, Abi.Contract.framed, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, Abi.AllApart, Abi.Apart, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, BitVec.reduceAdd] at hAp
  split_ands hAp
  have hAcc0 := hAcc
  try (simp only [Addn.contract, Abi.Contract.framed, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true] at hAcc; split_ands hAcc)
  have hReq0 := hReq
  simp only [Addn.contract, Abi.Contract.framed, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true] at hReq
  split_ands hReq
  try (have hK0 := Addn.Mid.cells (m := m0) (by assumption); split_ands hK0)
  try (have hK1 := Cv.At.cells (m := m0) (by assumption); split_ands hK1)
  refine runs_then (a := 16) (s1 := ?_) ?_ ?_
  case refine_2 => run_fn []; rfl
  refine runs_done ⟨rfl, rfl, rfl, rfl, rfl, rfl, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_⟩
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
  · exact hAp0
  · intro x hx hmod
    have hx' := hx
    have hmod' := hmod
    simp only [Addn.contract, Abi.Contract.framed, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, BitVec.reduceAdd] at hx' hmod'
    first | rfl | mem_away
  · exact hAcc0
  · exact hReq0
  · skip
    refine ⟨?_, ?_⟩
    · apply Addn.Mid.start <;> mem_auto
    · first | mem_auto | (apply Cv.At.frame <;> mem_auto)

theorem turn (fb lv key flags cvs n ra : BitVec 64) (sv : Abi.Saved) (k : Blake3.CV) (chunks : Array Blake3.Node) (news : List Blake3.Node) (vals : List Blake3.CV) (m0 : Mem)
    (s : State) (hI : Inv fb lv key flags cvs n ra sv k chunks news vals m0 s) (hc : s.rbx < n) :
    ∃ n_ s', steps Code_addn.prog n_ s = some s' ∧ (Inv fb lv key flags cvs n ra sv k chunks news vals m0 s' ∧ ((n - s'.rbx)).toNat < ((n - s.rbx)).toNat) := by
  obtain ⟨rax, rcx, rdx, i, rsp, p, rsi, rdi, r8, r9, r12, r13, r14, r15, zf, cf, x0, x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12, x13, x14, x15, mem, pc⟩ := s
  obtain ⟨hpc, hsp, hp0, hp1, hp2, hp3, hF, hRa, hS0, hS1, hS2, hS3, hS4, hS5, hPs0, hAp, hOut, hAcc, hReq, hI0, hI1⟩ := hI
  simp only at hpc hsp hp0 hp1 hp2 hp3 hF hRa hS0 hS1 hS2 hS3 hS4 hS5 hPs0 hOut hI0 hI1 hc
  subst pc rsp r12 r13 r14 r15
  have hAp0 := hAp
  simp only [Addn.contract, Abi.Contract.framed, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, Abi.AllApart, Abi.Apart, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, BitVec.reduceAdd] at hAp
  split_ands hAp
  have hAcc0 := hAcc
  try (simp only [Addn.contract, Abi.Contract.framed, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true] at hAcc; split_ands hAcc)
  have hReq0 := hReq
  simp only [Addn.contract, Abi.Contract.framed, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true] at hReq
  split_ands hReq
  forget_about m0 except hOut hReq0
  try (have hK0 := Addn.Mid.cells (m := mem) (by assumption); split_ands hK0)
  try (have hK1 := Cv.At.cells (m := mem) (by assumption); split_ands hK1)
  have c0 : (i).ult (n) = true := by bv_decide
  refine runs_then (a := 10) (s1 := ?_) ?_ ?_
  case refine_2 => run_fn [c0]; rfl
  have_by hN1_0 := Addn.Mid.next (m := mem)
  try norm_addr at hN1_0
  split_ands hN1_0
  refine Abi.call_meets (c := Ladd.contract lv key flags 5#64 p k (chunks ++ (news.take i.toNat).toArray) (news.getD i.toNat default)) (ra := 1441874#64)
    (Abi.Meets.mono Code_addn.has_ladd (Proof_ladd.ladd_meets lv key flags 5#64 p k (chunks ++ (news.take i.toNat).toArray) (news.getD i.toNat default))) rfl rfl ?_ ?_ ?_ ?_ ?_ ?_
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
    have hF1 : Region mem1 fb 320#64 := hown1 fb 320#64 (by mem_region)
    have hS1_0 : Quad mem1 (fb + 320#64) ra := X86.Quad.frame (by mem_fact) (fun x hx => hout1 x (by bv_decide) (by bv_decide))
    have hS1_1 : Quad mem1 (fb + 312#64) sv.rbx := X86.Quad.frame (by mem_fact) (fun x hx => hout1 x (by bv_decide) (by bv_decide))
    have hS1_2 : Quad mem1 (fb + 304#64) sv.rbp := X86.Quad.frame (by mem_fact) (fun x hx => hout1 x (by bv_decide) (by bv_decide))
    have hS1_3 : Quad mem1 (fb + 296#64) sv.r12 := X86.Quad.frame (by mem_fact) (fun x hx => hout1 x (by bv_decide) (by bv_decide))
    have hS1_4 : Quad mem1 (fb + 288#64) sv.r13 := X86.Quad.frame (by mem_fact) (fun x hx => hout1 x (by bv_decide) (by bv_decide))
    have hS1_5 : Quad mem1 (fb + 280#64) sv.r14 := X86.Quad.frame (by mem_fact) (fun x hx => hout1 x (by bv_decide) (by bv_decide))
    have hS1_6 : Quad mem1 (fb + 272#64) sv.r15 := X86.Quad.frame (by mem_fact) (fun x hx => hout1 x (by bv_decide) (by bv_decide))
    have hS1_7 : Quad mem1 (fb + 264#64) cvs := X86.Quad.frame (by mem_fact) (fun x hx => hout1 x (by bv_decide) (by bv_decide))
    have hK1_0 : Cv.At mem1 key k := Cv.At.frame (m := mem) (by assumption) (fun x hx => by rw [hout1 x (by bv_decide) (by bv_decide)]; first | rfl | mem_away)
    have hK1_1 : Cvs32.At mem1 cvs vals := Cvs32.At.frame (m := mem) (by assumption) (fun x hx => by rw [hout1 x (by bv_decide) (by bv_decide)]; first | rfl | mem_away)
    have hOut : (∀ x : BitVec 64, (Abi.Contract.framed (Addn.contract lv key flags cvs n k chunks news vals) 320#64).stack + 8#64 ≤ x - fb → (∀ r ∈ (Abi.Contract.framed (Addn.contract lv key flags cvs n k chunks news vals) 320#64).modifies, r.2 ≤ x - r.1) → mem1 x = m0 x) := by
      intro x hx hmod
      have hx' := hx
      have hmod' := hmod
      simp only [Addn.contract, Abi.Contract.framed, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, BitVec.reduceAdd] at hx' hmod'
      rw [hout1 x (by bv_decide) (by bv_decide)]
      refine Eq.trans ?_ (hOut x hx hmod); first | rfl | mem_away
    clear hout1 hown1
    refine runs_then (a := 7) (s1 := ?_) ?_ ?_
    case refine_2 => run_fn [c0]; rfl
    refine runs_done ⟨⟨rfl, rfl, rfl, rfl, rfl, rfl, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_⟩, ?_⟩
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
    · exact hAp0
    · intro x hx hmod
      refine Eq.trans ?_ (hOut x hx hmod)
      have hx' := hx
      have hmod' := hmod
      simp only [Addn.contract, Abi.Contract.framed, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, BitVec.reduceAdd] at hx' hmod'
      first | rfl | mem_away
    · exact hAcc0
    · exact hReq0
    · skip
      refine ⟨?_, ?_⟩
      · apply Addn.Mid.step <;> mem_auto
      · first | mem_auto | (apply Cv.At.frame <;> mem_auto)
    · exact BitVec.lt_def.mp (by bv_decide)

theorem leave (fb lv key flags cvs n ra : BitVec 64) (sv : Abi.Saved) (k : Blake3.CV) (chunks : Array Blake3.Node) (news : List Blake3.Node) (vals : List Blake3.CV) (m0 : Mem)
    (s : State) (hI : Inv fb lv key flags cvs n ra sv k chunks news vals m0 s) (hc : ¬ s.rbx < n) :
    ∃ n_ s', steps Code_addn.prog n_ s = some s' ∧ Abi.Post (Abi.Contract.framed (Addn.contract lv key flags cvs n k chunks news vals) 320#64) fb ra sv m0 s' := by
  obtain ⟨rax, rcx, rdx, i, rsp, p, rsi, rdi, r8, r9, r12, r13, r14, r15, zf, cf, x0, x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12, x13, x14, x15, mem, pc⟩ := s
  obtain ⟨hpc, hsp, hp0, hp1, hp2, hp3, hF, hRa, hS0, hS1, hS2, hS3, hS4, hS5, hPs0, hAp, hOut, hAcc, hReq, hI0, hI1⟩ := hI
  simp only at hpc hsp hp0 hp1 hp2 hp3 hF hRa hS0 hS1 hS2 hS3 hS4 hS5 hPs0 hOut hI0 hI1 hc
  subst pc rsp r12 r13 r14 r15
  have hAp0 := hAp
  simp only [Addn.contract, Abi.Contract.framed, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, Abi.AllApart, Abi.Apart, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, BitVec.reduceAdd] at hAp
  split_ands hAp
  have hAcc0 := hAcc
  try (simp only [Addn.contract, Abi.Contract.framed, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true] at hAcc; split_ands hAcc)
  have hReq0 := hReq
  simp only [Addn.contract, Abi.Contract.framed, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true] at hReq
  split_ands hReq
  forget_about m0 except hOut hReq0
  try (have hK0 := Addn.Mid.cells (m := mem) (by assumption); split_ands hK0)
  try (have hK1 := Cv.At.cells (m := mem) (by assumption); split_ands hK1)
  have c0 : (i).ult (n) = false := by bv_decide
  refine runs_then (a := 12) (s1 := ?_) ?_ ?_
  case refine_2 => run_fn [c0]; rfl
  refine runs_done ⟨rfl, by simp only [Addn.contract, Abi.Contract.framed]; bv_decide, rfl, rfl, rfl, rfl, rfl, rfl, ?_, ?_⟩
  all_goals try dsimp only
  · intro x hx hmod
    refine Eq.trans ?_ (hOut x hx hmod)
    have hx' := hx
    have hmod' := hmod
    simp only [Addn.contract, Abi.Contract.framed, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true, BitVec.reduceAdd] at hx' hmod'
    first | rfl | mem_away
  · simp only [Addn.contract, Abi.Contract.framed, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true]
    apply Addn.exit <;> mem_auto

/-- **`addn`, as assembled, meets its contract, whatever its arguments.** -/
theorem addn_meets : ∀ (lv key flags cvs n : BitVec 64) (k : Blake3.CV) (chunks : Array Blake3.Node) (news : List Blake3.Node) (vals : List Blake3.CV),
    Abi.Meets Code_addn.prog 0x160000 (Addn.contract lv key flags cvs n k chunks news vals) := by
  intro lv key flags cvs n k chunks news vals
  refine Abi.meets_of_triple 320#64 (by dsimp only [Addn.contract]; decide) (by dsimp only [Addn.contract]; decide) (fun fb ra sv m0 => ?_)
  refine Hoare.seq (Q := Inv fb lv key flags cvs n ra sv k chunks news vals m0) ?_ ?_
  · intro s hP
    exact enter fb lv key flags cvs n ra sv k chunks news vals m0 s hP
  · refine Hoare.loop (fun s => ((n - s.rbx)).toNat) (fun s hI => ?_)
    by_cases hc : s.rbx < n
    · obtain ⟨n_, s', h, hi, hm⟩ := turn fb lv key flags cvs n ra sv k chunks news vals m0 s hI hc
      exact ⟨n_, s', h, Or.inl ⟨hi, hm⟩⟩
    · obtain ⟨n_, s', h, hq⟩ := leave fb lv key flags cvs n ra sv k chunks news vals m0 s hI hc
      exact ⟨n_, s', h, Or.inr hq⟩

#print axioms addn_meets

end Proof_addn
