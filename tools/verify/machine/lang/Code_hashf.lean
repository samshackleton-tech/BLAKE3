import Machine
import KCode
import Cells
import Code_fillp
import Code_tree32
import Code_ladd
import Code_wide
import Code_addn
import Code_pad
import Code_chunk_node
import Code_node_out
import Code_groupf
import Code_lroot
import Code_finish
import Code_group
import Code_hashl
import Code_hashw
open X86

/-! `hashf` as assembled: 39 instructions. Written from the lifter's rows. -/

set_option maxRecDepth 100000
namespace Code_hashf

def table : List (Nat × Instr × Nat) := [
  (0x1A0000, .push .rbx, 0x1A0001),
  (0x1A0001, .push .rbp, 0x1A0002),
  (0x1A0002, .push .r12, 0x1A0004),
  (0x1A0004, .push .r13, 0x1A0006),
  (0x1A0006, .push .r14, 0x1A0008),
  (0x1A0008, .push .r15, 0x1A000A),
  (0x1A000A, .sub 64 (.reg .rsp) (.imm 0x8), 0x1A000E),
  (0x1A000E, .mov 64 (.reg .rbx) (.reg .rdi), 0x1A0011),
  (0x1A0011, .mov 64 (.reg .rbp) (.reg .rsi), 0x1A0014),
  (0x1A0014, .mov 64 (.reg .r12) (.reg .rdx), 0x1A0017),
  (0x1A0017, .mov 64 (.reg .r13) (.reg .rcx), 0x1A001A),
  (0x1A001A, .mov 64 (.reg .r14) (.reg .r8), 0x1A001D),
  (0x1A001D, .mov 64 (.reg .r15) (.reg .r9), 0x1A0020),
  (0x1A0020, .mov 64 (.reg .rax) (.reg .r15), 0x1A0023),
  (0x1A0023, .mov 64 (.reg .rcx) (.imm 0x5), 0x1A002A),
  (0x1A002A, .cmp 64 (.reg .rax) (.reg .rcx), 0x1A002D),
  (0x1A002D, .jne 0x1A0045, 0x1A002F),
  (0x1A002F, .mov 64 (.reg .rdi) (.reg .rbx), 0x1A0032),
  (0x1A0032, .mov 64 (.reg .rsi) (.reg .rbp), 0x1A0035),
  (0x1A0035, .mov 64 (.reg .rdx) (.reg .r12), 0x1A0038),
  (0x1A0038, .mov 64 (.reg .rcx) (.reg .r13), 0x1A003B),
  (0x1A003B, .mov 64 (.reg .r8) (.reg .r14), 0x1A003E),
  (0x1A003E, .call 0x190000, 0x1A0043),
  (0x1A0043, .jmp 0x1A005C, 0x1A0045),
  (0x1A0045, .mov 64 (.reg .rdi) (.reg .rbx), 0x1A0048),
  (0x1A0048, .mov 64 (.reg .rsi) (.reg .rbp), 0x1A004B),
  (0x1A004B, .mov 64 (.reg .rdx) (.reg .r12), 0x1A004E),
  (0x1A004E, .mov 64 (.reg .rcx) (.reg .r13), 0x1A0051),
  (0x1A0051, .mov 64 (.reg .r8) (.reg .r14), 0x1A0054),
  (0x1A0054, .mov 64 (.reg .r9) (.reg .r15), 0x1A0057),
  (0x1A0057, .call 0x40000, 0x1A005C),
  (0x1A005C, .add 64 (.reg .rsp) (.imm 0x8), 0x1A0060),
  (0x1A0060, .pop .r15, 0x1A0062),
  (0x1A0062, .pop .r14, 0x1A0064),
  (0x1A0064, .pop .r13, 0x1A0066),
  (0x1A0066, .pop .r12, 0x1A0068),
  (0x1A0068, .pop .rbp, 0x1A0069),
  (0x1A0069, .pop .rbx, 0x1A006A),
  (0x1A006A, .ret, 0x1A006B)
]

def pre0 : List (Nat × Instr × Nat) := KCode.table
def pre1 : List (Nat × Instr × Nat) := pre0 ++ Code_fillp.table
def pre2 : List (Nat × Instr × Nat) := pre1 ++ Code_tree32.table
def pre3 : List (Nat × Instr × Nat) := pre2 ++ Code_ladd.table
def pre4 : List (Nat × Instr × Nat) := pre3 ++ Code_wide.table
def pre5 : List (Nat × Instr × Nat) := pre4 ++ Code_addn.table
def pre6 : List (Nat × Instr × Nat) := pre5 ++ Code_pad.table
def pre7 : List (Nat × Instr × Nat) := pre6 ++ Code_chunk_node.table
def pre8 : List (Nat × Instr × Nat) := pre7 ++ Code_node_out.table
def pre9 : List (Nat × Instr × Nat) := pre8 ++ Code_groupf.table
def pre10 : List (Nat × Instr × Nat) := pre9 ++ Code_lroot.table
def pre11 : List (Nat × Instr × Nat) := pre10 ++ Code_finish.table
def pre12 : List (Nat × Instr × Nat) := pre11 ++ Code_group.table
def pre13 : List (Nat × Instr × Nat) := pre12 ++ Code_hashl.table
def pre14 : List (Nat × Instr × Nat) := pre13 ++ Code_hashw.table

/-- Every instruction of the program: the two kernels' (one/KCode.lean), `fillp`'s, `tree32`'s, `ladd`'s, `wide`'s, `addn`'s, `pad`'s, `chunk_node`'s, `node_out`'s, `groupf`'s, `lroot`'s, `finish`'s, `group`'s, `hashl`'s, `hashw`'s, then this function's. -/
def whole : List (Nat × Instr × Nat) := pre14 ++ table

def prog (ext : Nat → Option (Instr × Nat)) (pc : Nat) : Option (Instr × Nat) := (whole.lookup pc).or (ext pc)

/-- What this table holds, the program holds, whatever else it holds. -/
theorem prog_of (ext : Nat → Option (Instr × Nat)) : ∀ pc x, whole.lookup pc = some x → prog ext pc = some x := by
  intro pc x h; simp only [prog, h, Option.some_or]

theorem has_kernels (ext : Nat → Option (Instr × Nat)) : ∀ pc x, KCode.prog pc = some x → prog ext pc = some x := by
  intro pc x h
  exact prog_of ext pc x (lookup_append_left pre14 table pc x (lookup_append_left pre13 Code_hashw.table pc x (lookup_append_left pre12 Code_hashl.table pc x (lookup_append_left pre11 Code_group.table pc x (lookup_append_left pre10 Code_finish.table pc x (lookup_append_left pre9 Code_lroot.table pc x (lookup_append_left pre8 Code_groupf.table pc x (lookup_append_left pre7 Code_node_out.table pc x (lookup_append_left pre6 Code_chunk_node.table pc x (lookup_append_left pre5 Code_pad.table pc x (lookup_append_left pre4 Code_addn.table pc x (lookup_append_left pre3 Code_wide.table pc x (lookup_append_left pre2 Code_ladd.table pc x (lookup_append_left pre1 Code_tree32.table pc x (lookup_append_left pre0 Code_fillp.table pc x (h))))))))))))))))

/-- `fillp`'s own instructions are in this program: no table before them has one at any of their addresses. -/
theorem in1 (ext : Nat → Option (Instr × Nat)) : ∀ pc x, Code_fillp.table.lookup pc = some x → prog ext pc = some x := by
  intro pc x h
  have apart : ∀ p ∈ Code_fillp.table.map (·.1), ((pre0.lookup p).isNone) = true := by decide +kernel
  have none := Option.isNone_iff_eq_none.mp (apart pc (lookup_mem_keys _ pc x h))
  have here : pre1.lookup pc = some x := by
    show (pre0 ++ Code_fillp.table).lookup pc = some x
    rw [lookup_append_or, none]; exact h
  exact prog_of ext pc x (lookup_append_left pre14 table pc x (lookup_append_left pre13 Code_hashw.table pc x (lookup_append_left pre12 Code_hashl.table pc x (lookup_append_left pre11 Code_group.table pc x (lookup_append_left pre10 Code_finish.table pc x (lookup_append_left pre9 Code_lroot.table pc x (lookup_append_left pre8 Code_groupf.table pc x (lookup_append_left pre7 Code_node_out.table pc x (lookup_append_left pre6 Code_chunk_node.table pc x (lookup_append_left pre5 Code_pad.table pc x (lookup_append_left pre4 Code_addn.table pc x (lookup_append_left pre3 Code_wide.table pc x (lookup_append_left pre2 Code_ladd.table pc x (lookup_append_left pre1 Code_tree32.table pc x (here)))))))))))))))

/-- `tree32`'s own instructions are in this program: no table before them has one at any of their addresses. -/
theorem in2 (ext : Nat → Option (Instr × Nat)) : ∀ pc x, Code_tree32.table.lookup pc = some x → prog ext pc = some x := by
  intro pc x h
  have apart : ∀ p ∈ Code_tree32.table.map (·.1), ((pre1.lookup p).isNone) = true := by decide +kernel
  have none := Option.isNone_iff_eq_none.mp (apart pc (lookup_mem_keys _ pc x h))
  have here : pre2.lookup pc = some x := by
    show (pre1 ++ Code_tree32.table).lookup pc = some x
    rw [lookup_append_or, none]; exact h
  exact prog_of ext pc x (lookup_append_left pre14 table pc x (lookup_append_left pre13 Code_hashw.table pc x (lookup_append_left pre12 Code_hashl.table pc x (lookup_append_left pre11 Code_group.table pc x (lookup_append_left pre10 Code_finish.table pc x (lookup_append_left pre9 Code_lroot.table pc x (lookup_append_left pre8 Code_groupf.table pc x (lookup_append_left pre7 Code_node_out.table pc x (lookup_append_left pre6 Code_chunk_node.table pc x (lookup_append_left pre5 Code_pad.table pc x (lookup_append_left pre4 Code_addn.table pc x (lookup_append_left pre3 Code_wide.table pc x (lookup_append_left pre2 Code_ladd.table pc x (here))))))))))))))

/-- `ladd`'s own instructions are in this program: no table before them has one at any of their addresses. -/
theorem in3 (ext : Nat → Option (Instr × Nat)) : ∀ pc x, Code_ladd.table.lookup pc = some x → prog ext pc = some x := by
  intro pc x h
  have apart : ∀ p ∈ Code_ladd.table.map (·.1), ((pre2.lookup p).isNone) = true := by decide +kernel
  have none := Option.isNone_iff_eq_none.mp (apart pc (lookup_mem_keys _ pc x h))
  have here : pre3.lookup pc = some x := by
    show (pre2 ++ Code_ladd.table).lookup pc = some x
    rw [lookup_append_or, none]; exact h
  exact prog_of ext pc x (lookup_append_left pre14 table pc x (lookup_append_left pre13 Code_hashw.table pc x (lookup_append_left pre12 Code_hashl.table pc x (lookup_append_left pre11 Code_group.table pc x (lookup_append_left pre10 Code_finish.table pc x (lookup_append_left pre9 Code_lroot.table pc x (lookup_append_left pre8 Code_groupf.table pc x (lookup_append_left pre7 Code_node_out.table pc x (lookup_append_left pre6 Code_chunk_node.table pc x (lookup_append_left pre5 Code_pad.table pc x (lookup_append_left pre4 Code_addn.table pc x (lookup_append_left pre3 Code_wide.table pc x (here)))))))))))))

/-- `wide`'s own instructions are in this program: no table before them has one at any of their addresses. -/
theorem in4 (ext : Nat → Option (Instr × Nat)) : ∀ pc x, Code_wide.table.lookup pc = some x → prog ext pc = some x := by
  intro pc x h
  have apart : ∀ p ∈ Code_wide.table.map (·.1), ((pre3.lookup p).isNone) = true := by decide +kernel
  have none := Option.isNone_iff_eq_none.mp (apart pc (lookup_mem_keys _ pc x h))
  have here : pre4.lookup pc = some x := by
    show (pre3 ++ Code_wide.table).lookup pc = some x
    rw [lookup_append_or, none]; exact h
  exact prog_of ext pc x (lookup_append_left pre14 table pc x (lookup_append_left pre13 Code_hashw.table pc x (lookup_append_left pre12 Code_hashl.table pc x (lookup_append_left pre11 Code_group.table pc x (lookup_append_left pre10 Code_finish.table pc x (lookup_append_left pre9 Code_lroot.table pc x (lookup_append_left pre8 Code_groupf.table pc x (lookup_append_left pre7 Code_node_out.table pc x (lookup_append_left pre6 Code_chunk_node.table pc x (lookup_append_left pre5 Code_pad.table pc x (lookup_append_left pre4 Code_addn.table pc x (here))))))))))))

/-- `addn`'s own instructions are in this program: no table before them has one at any of their addresses. -/
theorem in5 (ext : Nat → Option (Instr × Nat)) : ∀ pc x, Code_addn.table.lookup pc = some x → prog ext pc = some x := by
  intro pc x h
  have apart : ∀ p ∈ Code_addn.table.map (·.1), ((pre4.lookup p).isNone) = true := by decide +kernel
  have none := Option.isNone_iff_eq_none.mp (apart pc (lookup_mem_keys _ pc x h))
  have here : pre5.lookup pc = some x := by
    show (pre4 ++ Code_addn.table).lookup pc = some x
    rw [lookup_append_or, none]; exact h
  exact prog_of ext pc x (lookup_append_left pre14 table pc x (lookup_append_left pre13 Code_hashw.table pc x (lookup_append_left pre12 Code_hashl.table pc x (lookup_append_left pre11 Code_group.table pc x (lookup_append_left pre10 Code_finish.table pc x (lookup_append_left pre9 Code_lroot.table pc x (lookup_append_left pre8 Code_groupf.table pc x (lookup_append_left pre7 Code_node_out.table pc x (lookup_append_left pre6 Code_chunk_node.table pc x (lookup_append_left pre5 Code_pad.table pc x (here)))))))))))

/-- `pad`'s own instructions are in this program: no table before them has one at any of their addresses. -/
theorem in6 (ext : Nat → Option (Instr × Nat)) : ∀ pc x, Code_pad.table.lookup pc = some x → prog ext pc = some x := by
  intro pc x h
  have apart : ∀ p ∈ Code_pad.table.map (·.1), ((pre5.lookup p).isNone) = true := by decide +kernel
  have none := Option.isNone_iff_eq_none.mp (apart pc (lookup_mem_keys _ pc x h))
  have here : pre6.lookup pc = some x := by
    show (pre5 ++ Code_pad.table).lookup pc = some x
    rw [lookup_append_or, none]; exact h
  exact prog_of ext pc x (lookup_append_left pre14 table pc x (lookup_append_left pre13 Code_hashw.table pc x (lookup_append_left pre12 Code_hashl.table pc x (lookup_append_left pre11 Code_group.table pc x (lookup_append_left pre10 Code_finish.table pc x (lookup_append_left pre9 Code_lroot.table pc x (lookup_append_left pre8 Code_groupf.table pc x (lookup_append_left pre7 Code_node_out.table pc x (lookup_append_left pre6 Code_chunk_node.table pc x (here))))))))))

/-- `chunk_node`'s own instructions are in this program: no table before them has one at any of their addresses. -/
theorem in7 (ext : Nat → Option (Instr × Nat)) : ∀ pc x, Code_chunk_node.table.lookup pc = some x → prog ext pc = some x := by
  intro pc x h
  have apart : ∀ p ∈ Code_chunk_node.table.map (·.1), ((pre6.lookup p).isNone) = true := by decide +kernel
  have none := Option.isNone_iff_eq_none.mp (apart pc (lookup_mem_keys _ pc x h))
  have here : pre7.lookup pc = some x := by
    show (pre6 ++ Code_chunk_node.table).lookup pc = some x
    rw [lookup_append_or, none]; exact h
  exact prog_of ext pc x (lookup_append_left pre14 table pc x (lookup_append_left pre13 Code_hashw.table pc x (lookup_append_left pre12 Code_hashl.table pc x (lookup_append_left pre11 Code_group.table pc x (lookup_append_left pre10 Code_finish.table pc x (lookup_append_left pre9 Code_lroot.table pc x (lookup_append_left pre8 Code_groupf.table pc x (lookup_append_left pre7 Code_node_out.table pc x (here)))))))))

/-- `node_out`'s own instructions are in this program: no table before them has one at any of their addresses. -/
theorem in8 (ext : Nat → Option (Instr × Nat)) : ∀ pc x, Code_node_out.table.lookup pc = some x → prog ext pc = some x := by
  intro pc x h
  have apart : ∀ p ∈ Code_node_out.table.map (·.1), ((pre7.lookup p).isNone) = true := by decide +kernel
  have none := Option.isNone_iff_eq_none.mp (apart pc (lookup_mem_keys _ pc x h))
  have here : pre8.lookup pc = some x := by
    show (pre7 ++ Code_node_out.table).lookup pc = some x
    rw [lookup_append_or, none]; exact h
  exact prog_of ext pc x (lookup_append_left pre14 table pc x (lookup_append_left pre13 Code_hashw.table pc x (lookup_append_left pre12 Code_hashl.table pc x (lookup_append_left pre11 Code_group.table pc x (lookup_append_left pre10 Code_finish.table pc x (lookup_append_left pre9 Code_lroot.table pc x (lookup_append_left pre8 Code_groupf.table pc x (here))))))))

/-- `groupf`'s own instructions are in this program: no table before them has one at any of their addresses. -/
theorem in9 (ext : Nat → Option (Instr × Nat)) : ∀ pc x, Code_groupf.table.lookup pc = some x → prog ext pc = some x := by
  intro pc x h
  have apart : ∀ p ∈ Code_groupf.table.map (·.1), ((pre8.lookup p).isNone) = true := by decide +kernel
  have none := Option.isNone_iff_eq_none.mp (apart pc (lookup_mem_keys _ pc x h))
  have here : pre9.lookup pc = some x := by
    show (pre8 ++ Code_groupf.table).lookup pc = some x
    rw [lookup_append_or, none]; exact h
  exact prog_of ext pc x (lookup_append_left pre14 table pc x (lookup_append_left pre13 Code_hashw.table pc x (lookup_append_left pre12 Code_hashl.table pc x (lookup_append_left pre11 Code_group.table pc x (lookup_append_left pre10 Code_finish.table pc x (lookup_append_left pre9 Code_lroot.table pc x (here)))))))

/-- `lroot`'s own instructions are in this program: no table before them has one at any of their addresses. -/
theorem in10 (ext : Nat → Option (Instr × Nat)) : ∀ pc x, Code_lroot.table.lookup pc = some x → prog ext pc = some x := by
  intro pc x h
  have apart : ∀ p ∈ Code_lroot.table.map (·.1), ((pre9.lookup p).isNone) = true := by decide +kernel
  have none := Option.isNone_iff_eq_none.mp (apart pc (lookup_mem_keys _ pc x h))
  have here : pre10.lookup pc = some x := by
    show (pre9 ++ Code_lroot.table).lookup pc = some x
    rw [lookup_append_or, none]; exact h
  exact prog_of ext pc x (lookup_append_left pre14 table pc x (lookup_append_left pre13 Code_hashw.table pc x (lookup_append_left pre12 Code_hashl.table pc x (lookup_append_left pre11 Code_group.table pc x (lookup_append_left pre10 Code_finish.table pc x (here))))))

/-- `finish`'s own instructions are in this program: no table before them has one at any of their addresses. -/
theorem in11 (ext : Nat → Option (Instr × Nat)) : ∀ pc x, Code_finish.table.lookup pc = some x → prog ext pc = some x := by
  intro pc x h
  have apart : ∀ p ∈ Code_finish.table.map (·.1), ((pre10.lookup p).isNone) = true := by decide +kernel
  have none := Option.isNone_iff_eq_none.mp (apart pc (lookup_mem_keys _ pc x h))
  have here : pre11.lookup pc = some x := by
    show (pre10 ++ Code_finish.table).lookup pc = some x
    rw [lookup_append_or, none]; exact h
  exact prog_of ext pc x (lookup_append_left pre14 table pc x (lookup_append_left pre13 Code_hashw.table pc x (lookup_append_left pre12 Code_hashl.table pc x (lookup_append_left pre11 Code_group.table pc x (here)))))

/-- `group`'s own instructions are in this program: no table before them has one at any of their addresses. -/
theorem in12 (ext : Nat → Option (Instr × Nat)) : ∀ pc x, Code_group.table.lookup pc = some x → prog ext pc = some x := by
  intro pc x h
  have apart : ∀ p ∈ Code_group.table.map (·.1), ((pre11.lookup p).isNone) = true := by decide +kernel
  have none := Option.isNone_iff_eq_none.mp (apart pc (lookup_mem_keys _ pc x h))
  have here : pre12.lookup pc = some x := by
    show (pre11 ++ Code_group.table).lookup pc = some x
    rw [lookup_append_or, none]; exact h
  exact prog_of ext pc x (lookup_append_left pre14 table pc x (lookup_append_left pre13 Code_hashw.table pc x (lookup_append_left pre12 Code_hashl.table pc x (here))))

/-- `hashl`'s own instructions are in this program: no table before them has one at any of their addresses. -/
theorem in13 (ext : Nat → Option (Instr × Nat)) : ∀ pc x, Code_hashl.table.lookup pc = some x → prog ext pc = some x := by
  intro pc x h
  have apart : ∀ p ∈ Code_hashl.table.map (·.1), ((pre12.lookup p).isNone) = true := by decide +kernel
  have none := Option.isNone_iff_eq_none.mp (apart pc (lookup_mem_keys _ pc x h))
  have here : pre13.lookup pc = some x := by
    show (pre12 ++ Code_hashl.table).lookup pc = some x
    rw [lookup_append_or, none]; exact h
  exact prog_of ext pc x (lookup_append_left pre14 table pc x (lookup_append_left pre13 Code_hashw.table pc x (here)))

/-- `hashw`'s own instructions are in this program: no table before them has one at any of their addresses. -/
theorem in14 (ext : Nat → Option (Instr × Nat)) : ∀ pc x, Code_hashw.table.lookup pc = some x → prog ext pc = some x := by
  intro pc x h
  have apart : ∀ p ∈ Code_hashw.table.map (·.1), ((pre13.lookup p).isNone) = true := by decide +kernel
  have none := Option.isNone_iff_eq_none.mp (apart pc (lookup_mem_keys _ pc x h))
  have here : pre14.lookup pc = some x := by
    show (pre13 ++ Code_hashw.table).lookup pc = some x
    rw [lookup_append_or, none]; exact h
  exact prog_of ext pc x (lookup_append_left pre14 table pc x (here))

/-- The tables of `hashw`'s program (its own instructions and those of what it calls) are in this one, unchanged. -/
theorem tables_hashw (ext : Nat → Option (Instr × Nat)) : ∀ pc x, (KCode.table ++ Code_fillp.table ++ Code_tree32.table ++ Code_ladd.table ++ Code_wide.table ++ Code_addn.table ++ Code_pad.table ++ Code_chunk_node.table ++ Code_node_out.table ++ Code_groupf.table ++ Code_lroot.table ++ Code_finish.table ++ Code_group.table ++ Code_hashl.table ++ Code_hashw.table).lookup pc = some x → prog ext pc = some x := by
  intro pc x h'
  simp only [lookup_append_or] at h'
  cases h0 : KCode.table.lookup pc with
  | some y =>
    rw [h0] at h'; simp only [Option.some_or, Option.some.injEq] at h'; subst h'
    exact has_kernels ext pc y h0
  | none =>
    rw [h0] at h'; simp only [Option.none_or] at h'
    cases h1 : Code_fillp.table.lookup pc with
    | some y =>
      rw [h1] at h'; simp only [Option.some_or, Option.some.injEq] at h'; subst h'
      exact in1 ext pc y h1
    | none =>
      rw [h1] at h'; simp only [Option.none_or] at h'
      cases h2 : Code_tree32.table.lookup pc with
      | some y =>
        rw [h2] at h'; simp only [Option.some_or, Option.some.injEq] at h'; subst h'
        exact in2 ext pc y h2
      | none =>
        rw [h2] at h'; simp only [Option.none_or] at h'
        cases h3 : Code_ladd.table.lookup pc with
        | some y =>
          rw [h3] at h'; simp only [Option.some_or, Option.some.injEq] at h'; subst h'
          exact in3 ext pc y h3
        | none =>
          rw [h3] at h'; simp only [Option.none_or] at h'
          cases h4 : Code_wide.table.lookup pc with
          | some y =>
            rw [h4] at h'; simp only [Option.some_or, Option.some.injEq] at h'; subst h'
            exact in4 ext pc y h4
          | none =>
            rw [h4] at h'; simp only [Option.none_or] at h'
            cases h5 : Code_addn.table.lookup pc with
            | some y =>
              rw [h5] at h'; simp only [Option.some_or, Option.some.injEq] at h'; subst h'
              exact in5 ext pc y h5
            | none =>
              rw [h5] at h'; simp only [Option.none_or] at h'
              cases h6 : Code_pad.table.lookup pc with
              | some y =>
                rw [h6] at h'; simp only [Option.some_or, Option.some.injEq] at h'; subst h'
                exact in6 ext pc y h6
              | none =>
                rw [h6] at h'; simp only [Option.none_or] at h'
                cases h7 : Code_chunk_node.table.lookup pc with
                | some y =>
                  rw [h7] at h'; simp only [Option.some_or, Option.some.injEq] at h'; subst h'
                  exact in7 ext pc y h7
                | none =>
                  rw [h7] at h'; simp only [Option.none_or] at h'
                  cases h8 : Code_node_out.table.lookup pc with
                  | some y =>
                    rw [h8] at h'; simp only [Option.some_or, Option.some.injEq] at h'; subst h'
                    exact in8 ext pc y h8
                  | none =>
                    rw [h8] at h'; simp only [Option.none_or] at h'
                    cases h9 : Code_groupf.table.lookup pc with
                    | some y =>
                      rw [h9] at h'; simp only [Option.some_or, Option.some.injEq] at h'; subst h'
                      exact in9 ext pc y h9
                    | none =>
                      rw [h9] at h'; simp only [Option.none_or] at h'
                      cases h10 : Code_lroot.table.lookup pc with
                      | some y =>
                        rw [h10] at h'; simp only [Option.some_or, Option.some.injEq] at h'; subst h'
                        exact in10 ext pc y h10
                      | none =>
                        rw [h10] at h'; simp only [Option.none_or] at h'
                        cases h11 : Code_finish.table.lookup pc with
                        | some y =>
                          rw [h11] at h'; simp only [Option.some_or, Option.some.injEq] at h'; subst h'
                          exact in11 ext pc y h11
                        | none =>
                          rw [h11] at h'; simp only [Option.none_or] at h'
                          cases h12 : Code_group.table.lookup pc with
                          | some y =>
                            rw [h12] at h'; simp only [Option.some_or, Option.some.injEq] at h'; subst h'
                            exact in12 ext pc y h12
                          | none =>
                            rw [h12] at h'; simp only [Option.none_or] at h'
                            cases h13 : Code_hashl.table.lookup pc with
                            | some y =>
                              rw [h13] at h'; simp only [Option.some_or, Option.some.injEq] at h'; subst h'
                              exact in13 ext pc y h13
                            | none =>
                              rw [h13] at h'; simp only [Option.none_or] at h'
                              exact in14 ext pc x h'

/-- `hashw`'s program over this one is this one: a theorem about `hashw` over any program holds here. -/
theorem has_hashw (ext : Nat → Option (Instr × Nat)) : ∀ pc x, Code_hashw.prog (prog ext) pc = some x → prog ext pc = some x := by
  intro pc x h
  have h0 : ((KCode.table ++ Code_fillp.table ++ Code_tree32.table ++ Code_ladd.table ++ Code_wide.table ++ Code_addn.table ++ Code_pad.table ++ Code_chunk_node.table ++ Code_node_out.table ++ Code_groupf.table ++ Code_lroot.table ++ Code_finish.table ++ Code_group.table ++ Code_hashl.table ++ Code_hashw.table).lookup pc).or (prog ext pc) = some x := h
  cases hw : (KCode.table ++ Code_fillp.table ++ Code_tree32.table ++ Code_ladd.table ++ Code_wide.table ++ Code_addn.table ++ Code_pad.table ++ Code_chunk_node.table ++ Code_node_out.table ++ Code_groupf.table ++ Code_lroot.table ++ Code_finish.table ++ Code_group.table ++ Code_hashl.table ++ Code_hashw.table).lookup pc with
  | none => rw [hw] at h0; simpa only [Option.none_or] using h0
  | some y =>
    rw [hw] at h0; simp only [Option.some_or, Option.some.injEq] at h0; subst h0
    exact tables_hashw ext pc y hw

/-- And this program is `hashw`'s over it: what is assumed of this program holds of that one. -/
theorem over_hashw (ext : Nat → Option (Instr × Nat)) : ∀ pc x, prog ext pc = some x → Code_hashw.prog (prog ext) pc = some x := by
  intro pc x h
  show ((KCode.table ++ Code_fillp.table ++ Code_tree32.table ++ Code_ladd.table ++ Code_wide.table ++ Code_addn.table ++ Code_pad.table ++ Code_chunk_node.table ++ Code_node_out.table ++ Code_groupf.table ++ Code_lroot.table ++ Code_finish.table ++ Code_group.table ++ Code_hashl.table ++ Code_hashw.table).lookup pc).or (prog ext pc) = some x
  cases hw : (KCode.table ++ Code_fillp.table ++ Code_tree32.table ++ Code_ladd.table ++ Code_wide.table ++ Code_addn.table ++ Code_pad.table ++ Code_chunk_node.table ++ Code_node_out.table ++ Code_groupf.table ++ Code_lroot.table ++ Code_finish.table ++ Code_group.table ++ Code_hashl.table ++ Code_hashw.table).lookup pc with
  | none => simpa only [Option.none_or] using h
  | some y =>
    have e := tables_hashw ext pc y hw
    rw [h] at e; rw [Option.some_or]; exact e.symm

/-- The tables of `hashl`'s program (its own instructions and those of what it calls) are in this one, unchanged. -/
theorem tables_hashl (ext : Nat → Option (Instr × Nat)) : ∀ pc x, (KCode.table ++ Code_pad.table ++ Code_chunk_node.table ++ Code_node_out.table ++ Code_ladd.table ++ Code_lroot.table ++ Code_hashl.table).lookup pc = some x → prog ext pc = some x := by
  intro pc x h'
  simp only [lookup_append_or] at h'
  cases h0 : KCode.table.lookup pc with
  | some y =>
    rw [h0] at h'; simp only [Option.some_or, Option.some.injEq] at h'; subst h'
    exact has_kernels ext pc y h0
  | none =>
    rw [h0] at h'; simp only [Option.none_or] at h'
    cases h1 : Code_pad.table.lookup pc with
    | some y =>
      rw [h1] at h'; simp only [Option.some_or, Option.some.injEq] at h'; subst h'
      exact in6 ext pc y h1
    | none =>
      rw [h1] at h'; simp only [Option.none_or] at h'
      cases h2 : Code_chunk_node.table.lookup pc with
      | some y =>
        rw [h2] at h'; simp only [Option.some_or, Option.some.injEq] at h'; subst h'
        exact in7 ext pc y h2
      | none =>
        rw [h2] at h'; simp only [Option.none_or] at h'
        cases h3 : Code_node_out.table.lookup pc with
        | some y =>
          rw [h3] at h'; simp only [Option.some_or, Option.some.injEq] at h'; subst h'
          exact in8 ext pc y h3
        | none =>
          rw [h3] at h'; simp only [Option.none_or] at h'
          cases h4 : Code_ladd.table.lookup pc with
          | some y =>
            rw [h4] at h'; simp only [Option.some_or, Option.some.injEq] at h'; subst h'
            exact in3 ext pc y h4
          | none =>
            rw [h4] at h'; simp only [Option.none_or] at h'
            cases h5 : Code_lroot.table.lookup pc with
            | some y =>
              rw [h5] at h'; simp only [Option.some_or, Option.some.injEq] at h'; subst h'
              exact in10 ext pc y h5
            | none =>
              rw [h5] at h'; simp only [Option.none_or] at h'
              exact in13 ext pc x h'

/-- `hashl`'s program (its own instructions and those of what it calls) is part of this one, unchanged. -/
theorem has_hashl (ext : Nat → Option (Instr × Nat)) : ∀ pc x, Code_hashl.prog pc = some x → prog ext pc = some x :=
  fun pc x h => tables_hashl ext pc x h

@[ode_at] theorem at_1A0000 (ext : Nat → Option (Instr × Nat)) : prog ext 0x1A0000 = some (.push .rbx, 0x1A0001) := rfl
@[ode_at] theorem at_1A0001 (ext : Nat → Option (Instr × Nat)) : prog ext 0x1A0001 = some (.push .rbp, 0x1A0002) := rfl
@[ode_at] theorem at_1A0002 (ext : Nat → Option (Instr × Nat)) : prog ext 0x1A0002 = some (.push .r12, 0x1A0004) := rfl
@[ode_at] theorem at_1A0004 (ext : Nat → Option (Instr × Nat)) : prog ext 0x1A0004 = some (.push .r13, 0x1A0006) := rfl
@[ode_at] theorem at_1A0006 (ext : Nat → Option (Instr × Nat)) : prog ext 0x1A0006 = some (.push .r14, 0x1A0008) := rfl
@[ode_at] theorem at_1A0008 (ext : Nat → Option (Instr × Nat)) : prog ext 0x1A0008 = some (.push .r15, 0x1A000A) := rfl
@[ode_at] theorem at_1A000A (ext : Nat → Option (Instr × Nat)) : prog ext 0x1A000A = some (.sub 64 (.reg .rsp) (.imm 0x8), 0x1A000E) := rfl
@[ode_at] theorem at_1A000E (ext : Nat → Option (Instr × Nat)) : prog ext 0x1A000E = some (.mov 64 (.reg .rbx) (.reg .rdi), 0x1A0011) := rfl
@[ode_at] theorem at_1A0011 (ext : Nat → Option (Instr × Nat)) : prog ext 0x1A0011 = some (.mov 64 (.reg .rbp) (.reg .rsi), 0x1A0014) := rfl
@[ode_at] theorem at_1A0014 (ext : Nat → Option (Instr × Nat)) : prog ext 0x1A0014 = some (.mov 64 (.reg .r12) (.reg .rdx), 0x1A0017) := rfl
@[ode_at] theorem at_1A0017 (ext : Nat → Option (Instr × Nat)) : prog ext 0x1A0017 = some (.mov 64 (.reg .r13) (.reg .rcx), 0x1A001A) := rfl
@[ode_at] theorem at_1A001A (ext : Nat → Option (Instr × Nat)) : prog ext 0x1A001A = some (.mov 64 (.reg .r14) (.reg .r8), 0x1A001D) := rfl
@[ode_at] theorem at_1A001D (ext : Nat → Option (Instr × Nat)) : prog ext 0x1A001D = some (.mov 64 (.reg .r15) (.reg .r9), 0x1A0020) := rfl
@[ode_at] theorem at_1A0020 (ext : Nat → Option (Instr × Nat)) : prog ext 0x1A0020 = some (.mov 64 (.reg .rax) (.reg .r15), 0x1A0023) := rfl
@[ode_at] theorem at_1A0023 (ext : Nat → Option (Instr × Nat)) : prog ext 0x1A0023 = some (.mov 64 (.reg .rcx) (.imm 0x5), 0x1A002A) := rfl
@[ode_at] theorem at_1A002A (ext : Nat → Option (Instr × Nat)) : prog ext 0x1A002A = some (.cmp 64 (.reg .rax) (.reg .rcx), 0x1A002D) := rfl
@[ode_at] theorem at_1A002D (ext : Nat → Option (Instr × Nat)) : prog ext 0x1A002D = some (.jne 0x1A0045, 0x1A002F) := rfl
@[ode_at] theorem at_1A002F (ext : Nat → Option (Instr × Nat)) : prog ext 0x1A002F = some (.mov 64 (.reg .rdi) (.reg .rbx), 0x1A0032) := rfl
@[ode_at] theorem at_1A0032 (ext : Nat → Option (Instr × Nat)) : prog ext 0x1A0032 = some (.mov 64 (.reg .rsi) (.reg .rbp), 0x1A0035) := rfl
@[ode_at] theorem at_1A0035 (ext : Nat → Option (Instr × Nat)) : prog ext 0x1A0035 = some (.mov 64 (.reg .rdx) (.reg .r12), 0x1A0038) := rfl
@[ode_at] theorem at_1A0038 (ext : Nat → Option (Instr × Nat)) : prog ext 0x1A0038 = some (.mov 64 (.reg .rcx) (.reg .r13), 0x1A003B) := rfl
@[ode_at] theorem at_1A003B (ext : Nat → Option (Instr × Nat)) : prog ext 0x1A003B = some (.mov 64 (.reg .r8) (.reg .r14), 0x1A003E) := rfl
@[ode_at] theorem at_1A003E (ext : Nat → Option (Instr × Nat)) : prog ext 0x1A003E = some (.call 0x190000, 0x1A0043) := rfl
@[ode_at] theorem at_1A0043 (ext : Nat → Option (Instr × Nat)) : prog ext 0x1A0043 = some (.jmp 0x1A005C, 0x1A0045) := rfl
@[ode_at] theorem at_1A0045 (ext : Nat → Option (Instr × Nat)) : prog ext 0x1A0045 = some (.mov 64 (.reg .rdi) (.reg .rbx), 0x1A0048) := rfl
@[ode_at] theorem at_1A0048 (ext : Nat → Option (Instr × Nat)) : prog ext 0x1A0048 = some (.mov 64 (.reg .rsi) (.reg .rbp), 0x1A004B) := rfl
@[ode_at] theorem at_1A004B (ext : Nat → Option (Instr × Nat)) : prog ext 0x1A004B = some (.mov 64 (.reg .rdx) (.reg .r12), 0x1A004E) := rfl
@[ode_at] theorem at_1A004E (ext : Nat → Option (Instr × Nat)) : prog ext 0x1A004E = some (.mov 64 (.reg .rcx) (.reg .r13), 0x1A0051) := rfl
@[ode_at] theorem at_1A0051 (ext : Nat → Option (Instr × Nat)) : prog ext 0x1A0051 = some (.mov 64 (.reg .r8) (.reg .r14), 0x1A0054) := rfl
@[ode_at] theorem at_1A0054 (ext : Nat → Option (Instr × Nat)) : prog ext 0x1A0054 = some (.mov 64 (.reg .r9) (.reg .r15), 0x1A0057) := rfl
@[ode_at] theorem at_1A0057 (ext : Nat → Option (Instr × Nat)) : prog ext 0x1A0057 = some (.call 0x40000, 0x1A005C) := rfl
@[ode_at] theorem at_1A005C (ext : Nat → Option (Instr × Nat)) : prog ext 0x1A005C = some (.add 64 (.reg .rsp) (.imm 0x8), 0x1A0060) := rfl
@[ode_at] theorem at_1A0060 (ext : Nat → Option (Instr × Nat)) : prog ext 0x1A0060 = some (.pop .r15, 0x1A0062) := rfl
@[ode_at] theorem at_1A0062 (ext : Nat → Option (Instr × Nat)) : prog ext 0x1A0062 = some (.pop .r14, 0x1A0064) := rfl
@[ode_at] theorem at_1A0064 (ext : Nat → Option (Instr × Nat)) : prog ext 0x1A0064 = some (.pop .r13, 0x1A0066) := rfl
@[ode_at] theorem at_1A0066 (ext : Nat → Option (Instr × Nat)) : prog ext 0x1A0066 = some (.pop .r12, 0x1A0068) := rfl
@[ode_at] theorem at_1A0068 (ext : Nat → Option (Instr × Nat)) : prog ext 0x1A0068 = some (.pop .rbp, 0x1A0069) := rfl
@[ode_at] theorem at_1A0069 (ext : Nat → Option (Instr × Nat)) : prog ext 0x1A0069 = some (.pop .rbx, 0x1A006A) := rfl
@[ode_at] theorem at_1A006A (ext : Nat → Option (Instr × Nat)) : prog ext 0x1A006A = some (.ret, 0x1A006B) := rfl

end Code_hashf
