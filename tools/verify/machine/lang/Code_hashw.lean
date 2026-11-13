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
open X86

/-! `hashw` as assembled: 101 instructions. Written from the lifter's rows. -/

set_option maxRecDepth 100000
namespace Code_hashw

def table : List (Nat × Instr × Nat) := [
  (0x190000, .push .rbx, 0x190001),
  (0x190001, .push .rbp, 0x190002),
  (0x190002, .push .r12, 0x190004),
  (0x190004, .push .r13, 0x190006),
  (0x190006, .push .r14, 0x190008),
  (0x190008, .push .r15, 0x19000A),
  (0x19000A, .sub 64 (.reg .rsp) (.imm 0x1B98), 0x190011),
  (0x190011, .mov 64 (.reg .rbx) (.reg .rdi), 0x190014),
  (0x190014, .mov 64 (.reg .rbp) (.reg .rsi), 0x190017),
  (0x190017, .mov 64 (.reg .r12) (.reg .rdx), 0x19001A),
  (0x19001A, .mov 64 (.reg .r13) (.reg .rcx), 0x19001D),
  (0x19001D, .mov 64 (.reg .r14) (.reg .r8), 0x190020),
  (0x190020, .mov 64 (.reg .rax) (.imm 0x400), 0x190027),
  (0x190027, .mov 64 (.reg .rcx) (.reg .r12), 0x19002A),
  (0x19002A, .cmp 64 (.reg .rax) (.reg .rcx), 0x19002D),
  (0x19002D, .jae 0x190176, 0x190033),
  (0x190033, .lea .rdi .rsp 0x0, 0x190037),
  (0x190037, .mov 64 (.reg .rsi) (.reg .rbp), 0x19003A),
  (0x19003A, .mov 64 (.reg .rdx) (.reg .r12), 0x19003D),
  (0x19003D, .mov 64 (.reg .rcx) (.reg .r13), 0x190040),
  (0x190040, .mov 64 (.reg .r8) (.reg .r14), 0x190043),
  (0x190043, .call 0x130000, 0x190048),
  (0x190048, .mov 64 (.reg .r15) (.reg .rax), 0x19004B),
  (0x19004B, .mov 64 (.reg .rax) (.reg .rbp), 0x19004E),
  (0x19004E, .mov 64 (.reg .rcx) (.reg .r15), 0x190051),
  (0x190051, .shl64 .rcx 10, 0x190055),
  (0x190055, .add 64 (.reg .rax) (.reg .rcx), 0x190058),
  (0x190058, .mov 64 (.mem .rsp 0x1B80) (.reg .rax), 0x190060),
  (0x190060, .mov 64 (.reg .rax) (.reg .r12), 0x190063),
  (0x190063, .mov 64 (.reg .rcx) (.reg .r15), 0x190066),
  (0x190066, .shl64 .rcx 10, 0x19006A),
  (0x19006A, .sub 64 (.reg .rax) (.reg .rcx), 0x19006D),
  (0x19006D, .mov 64 (.mem .rsp 0x1B88) (.reg .rax), 0x190075),
  (0x190075, .mov 64 (.reg .rax) (.reg .r15), 0x190078),
  (0x190078, .mov 64 (.reg .rcx) (.imm 0x0), 0x19007F),
  (0x19007F, .cmp 64 (.reg .rax) (.reg .rcx), 0x190082),
  (0x190082, .jne 0x1900D0, 0x190084),
  (0x190084, .lea .rdi .rsp 0xDC0, 0x19008C),
  (0x19008C, .mov 64 (.reg .rsi) (.mem .rsp 0x1B80), 0x190094),
  (0x190094, .mov 64 (.reg .rdx) (.mem .rsp 0x1B88), 0x19009C),
  (0x19009C, .mov 64 (.reg .rcx) (.reg .r13), 0x19009F),
  (0x19009F, .mov 64 (.reg .r8) (.reg .r14), 0x1900A2),
  (0x1900A2, .mov 64 (.reg .r9) (.reg .r15), 0x1900A5),
  (0x1900A5, .call 0x1B0000, 0x1900AA),
  (0x1900AA, .mov 64 (.reg .rdi) (.reg .rbx), 0x1900AD),
  (0x1900AD, .lea .rsi .rsp 0x0, 0x1900B1),
  (0x1900B1, .lea .rdx .rsp 0xDC0, 0x1900B9),
  (0x1900B9, .mov 64 (.reg .rcx) (.reg .r13), 0x1900BC),
  (0x1900BC, .mov 64 (.reg .r8) (.reg .r14), 0x1900BF),
  (0x1900BF, .mov 64 (.reg .r9) (.imm 0x0), 0x1900C6),
  (0x1900C6, .call 0x170000, 0x1900CB),
  (0x1900CB, .jmp 0x190174, 0x1900D0),
  (0x1900D0, .mov 64 (.reg .rax) (.imm 0x400), 0x1900D7),
  (0x1900D7, .mov 64 (.reg .rcx) (.mem .rsp 0x1B88), 0x1900DF),
  (0x1900DF, .cmp 64 (.reg .rax) (.reg .rcx), 0x1900E2),
  (0x1900E2, .jae 0x19012D, 0x1900E4),
  (0x1900E4, .lea .rdi .rsp 0xDC0, 0x1900EC),
  (0x1900EC, .mov 64 (.reg .rsi) (.mem .rsp 0x1B80), 0x1900F4),
  (0x1900F4, .mov 64 (.reg .rdx) (.mem .rsp 0x1B88), 0x1900FC),
  (0x1900FC, .mov 64 (.reg .rcx) (.reg .r13), 0x1900FF),
  (0x1900FF, .mov 64 (.reg .r8) (.reg .r14), 0x190102),
  (0x190102, .mov 64 (.reg .r9) (.reg .r15), 0x190105),
  (0x190105, .call 0x1B0000, 0x19010A),
  (0x19010A, .mov 64 (.reg .rdi) (.reg .rbx), 0x19010D),
  (0x19010D, .lea .rsi .rsp 0x0, 0x190111),
  (0x190111, .lea .rdx .rsp 0xDC0, 0x190119),
  (0x190119, .mov 64 (.reg .rcx) (.reg .r13), 0x19011C),
  (0x19011C, .mov 64 (.reg .r8) (.reg .r14), 0x19011F),
  (0x19011F, .mov 64 (.reg .r9) (.imm 0x2), 0x190126),
  (0x190126, .call 0x170000, 0x19012B),
  (0x19012B, .jmp 0x190174, 0x19012D),
  (0x19012D, .lea .rdi .rsp 0xDC0, 0x190135),
  (0x190135, .mov 64 (.reg .rsi) (.mem .rsp 0x1B80), 0x19013D),
  (0x19013D, .mov 64 (.reg .rdx) (.mem .rsp 0x1B88), 0x190145),
  (0x190145, .mov 64 (.reg .rcx) (.reg .r13), 0x190148),
  (0x190148, .mov 64 (.reg .r8) (.reg .r14), 0x19014B),
  (0x19014B, .mov 64 (.reg .r9) (.reg .r15), 0x19014E),
  (0x19014E, .call 0x180000, 0x190153),
  (0x190153, .mov 64 (.reg .rdi) (.reg .rbx), 0x190156),
  (0x190156, .lea .rsi .rsp 0x0, 0x19015A),
  (0x19015A, .lea .rdx .rsp 0xDC0, 0x190162),
  (0x190162, .mov 64 (.reg .rcx) (.reg .r13), 0x190165),
  (0x190165, .mov 64 (.reg .r8) (.reg .r14), 0x190168),
  (0x190168, .mov 64 (.reg .r9) (.imm 0x1), 0x19016F),
  (0x19016F, .call 0x170000, 0x190174),
  (0x190174, .jmp 0x190191, 0x190176),
  (0x190176, .mov 64 (.reg .rdi) (.reg .rbx), 0x190179),
  (0x190179, .mov 64 (.reg .rsi) (.reg .rbp), 0x19017C),
  (0x19017C, .mov 64 (.reg .rdx) (.reg .r12), 0x19017F),
  (0x19017F, .mov 64 (.reg .rcx) (.reg .r13), 0x190182),
  (0x190182, .mov 64 (.reg .r8) (.reg .r14), 0x190185),
  (0x190185, .mov 64 (.reg .r9) (.imm 0x5), 0x19018C),
  (0x19018C, .call 0x40000, 0x190191),
  (0x190191, .add 64 (.reg .rsp) (.imm 0x1B98), 0x190198),
  (0x190198, .pop .r15, 0x19019A),
  (0x19019A, .pop .r14, 0x19019C),
  (0x19019C, .pop .r13, 0x19019E),
  (0x19019E, .pop .r12, 0x1901A0),
  (0x1901A0, .pop .rbp, 0x1901A1),
  (0x1901A1, .pop .rbx, 0x1901A2),
  (0x1901A2, .ret, 0x1901A3)
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

/-- Every instruction of the program: the two kernels' (one/KCode.lean), `fillp`'s, `tree32`'s, `ladd`'s, `wide`'s, `addn`'s, `pad`'s, `chunk_node`'s, `node_out`'s, `groupf`'s, `lroot`'s, `finish`'s, `group`'s, `hashl`'s, then this function's. -/
def whole : List (Nat × Instr × Nat) := pre13 ++ table

def prog (ext : Nat → Option (Instr × Nat)) (pc : Nat) : Option (Instr × Nat) := (whole.lookup pc).or (ext pc)

/-- What this table holds, the program holds, whatever else it holds. -/
theorem prog_of (ext : Nat → Option (Instr × Nat)) : ∀ pc x, whole.lookup pc = some x → prog ext pc = some x := by
  intro pc x h; simp only [prog, h, Option.some_or]

theorem has_kernels (ext : Nat → Option (Instr × Nat)) : ∀ pc x, KCode.prog pc = some x → prog ext pc = some x := by
  intro pc x h
  exact prog_of ext pc x (lookup_append_left pre13 table pc x (lookup_append_left pre12 Code_hashl.table pc x (lookup_append_left pre11 Code_group.table pc x (lookup_append_left pre10 Code_finish.table pc x (lookup_append_left pre9 Code_lroot.table pc x (lookup_append_left pre8 Code_groupf.table pc x (lookup_append_left pre7 Code_node_out.table pc x (lookup_append_left pre6 Code_chunk_node.table pc x (lookup_append_left pre5 Code_pad.table pc x (lookup_append_left pre4 Code_addn.table pc x (lookup_append_left pre3 Code_wide.table pc x (lookup_append_left pre2 Code_ladd.table pc x (lookup_append_left pre1 Code_tree32.table pc x (lookup_append_left pre0 Code_fillp.table pc x (h)))))))))))))))

/-- `fillp`'s own instructions are in this program: no table before them has one at any of their addresses. -/
theorem in1 (ext : Nat → Option (Instr × Nat)) : ∀ pc x, Code_fillp.table.lookup pc = some x → prog ext pc = some x := by
  intro pc x h
  have apart : ∀ p ∈ Code_fillp.table.map (·.1), ((pre0.lookup p).isNone) = true := by decide +kernel
  have none := Option.isNone_iff_eq_none.mp (apart pc (lookup_mem_keys _ pc x h))
  have here : pre1.lookup pc = some x := by
    show (pre0 ++ Code_fillp.table).lookup pc = some x
    rw [lookup_append_or, none]; exact h
  exact prog_of ext pc x (lookup_append_left pre13 table pc x (lookup_append_left pre12 Code_hashl.table pc x (lookup_append_left pre11 Code_group.table pc x (lookup_append_left pre10 Code_finish.table pc x (lookup_append_left pre9 Code_lroot.table pc x (lookup_append_left pre8 Code_groupf.table pc x (lookup_append_left pre7 Code_node_out.table pc x (lookup_append_left pre6 Code_chunk_node.table pc x (lookup_append_left pre5 Code_pad.table pc x (lookup_append_left pre4 Code_addn.table pc x (lookup_append_left pre3 Code_wide.table pc x (lookup_append_left pre2 Code_ladd.table pc x (lookup_append_left pre1 Code_tree32.table pc x (here))))))))))))))

/-- `tree32`'s own instructions are in this program: no table before them has one at any of their addresses. -/
theorem in2 (ext : Nat → Option (Instr × Nat)) : ∀ pc x, Code_tree32.table.lookup pc = some x → prog ext pc = some x := by
  intro pc x h
  have apart : ∀ p ∈ Code_tree32.table.map (·.1), ((pre1.lookup p).isNone) = true := by decide +kernel
  have none := Option.isNone_iff_eq_none.mp (apart pc (lookup_mem_keys _ pc x h))
  have here : pre2.lookup pc = some x := by
    show (pre1 ++ Code_tree32.table).lookup pc = some x
    rw [lookup_append_or, none]; exact h
  exact prog_of ext pc x (lookup_append_left pre13 table pc x (lookup_append_left pre12 Code_hashl.table pc x (lookup_append_left pre11 Code_group.table pc x (lookup_append_left pre10 Code_finish.table pc x (lookup_append_left pre9 Code_lroot.table pc x (lookup_append_left pre8 Code_groupf.table pc x (lookup_append_left pre7 Code_node_out.table pc x (lookup_append_left pre6 Code_chunk_node.table pc x (lookup_append_left pre5 Code_pad.table pc x (lookup_append_left pre4 Code_addn.table pc x (lookup_append_left pre3 Code_wide.table pc x (lookup_append_left pre2 Code_ladd.table pc x (here)))))))))))))

/-- `ladd`'s own instructions are in this program: no table before them has one at any of their addresses. -/
theorem in3 (ext : Nat → Option (Instr × Nat)) : ∀ pc x, Code_ladd.table.lookup pc = some x → prog ext pc = some x := by
  intro pc x h
  have apart : ∀ p ∈ Code_ladd.table.map (·.1), ((pre2.lookup p).isNone) = true := by decide +kernel
  have none := Option.isNone_iff_eq_none.mp (apart pc (lookup_mem_keys _ pc x h))
  have here : pre3.lookup pc = some x := by
    show (pre2 ++ Code_ladd.table).lookup pc = some x
    rw [lookup_append_or, none]; exact h
  exact prog_of ext pc x (lookup_append_left pre13 table pc x (lookup_append_left pre12 Code_hashl.table pc x (lookup_append_left pre11 Code_group.table pc x (lookup_append_left pre10 Code_finish.table pc x (lookup_append_left pre9 Code_lroot.table pc x (lookup_append_left pre8 Code_groupf.table pc x (lookup_append_left pre7 Code_node_out.table pc x (lookup_append_left pre6 Code_chunk_node.table pc x (lookup_append_left pre5 Code_pad.table pc x (lookup_append_left pre4 Code_addn.table pc x (lookup_append_left pre3 Code_wide.table pc x (here))))))))))))

/-- `wide`'s own instructions are in this program: no table before them has one at any of their addresses. -/
theorem in4 (ext : Nat → Option (Instr × Nat)) : ∀ pc x, Code_wide.table.lookup pc = some x → prog ext pc = some x := by
  intro pc x h
  have apart : ∀ p ∈ Code_wide.table.map (·.1), ((pre3.lookup p).isNone) = true := by decide +kernel
  have none := Option.isNone_iff_eq_none.mp (apart pc (lookup_mem_keys _ pc x h))
  have here : pre4.lookup pc = some x := by
    show (pre3 ++ Code_wide.table).lookup pc = some x
    rw [lookup_append_or, none]; exact h
  exact prog_of ext pc x (lookup_append_left pre13 table pc x (lookup_append_left pre12 Code_hashl.table pc x (lookup_append_left pre11 Code_group.table pc x (lookup_append_left pre10 Code_finish.table pc x (lookup_append_left pre9 Code_lroot.table pc x (lookup_append_left pre8 Code_groupf.table pc x (lookup_append_left pre7 Code_node_out.table pc x (lookup_append_left pre6 Code_chunk_node.table pc x (lookup_append_left pre5 Code_pad.table pc x (lookup_append_left pre4 Code_addn.table pc x (here)))))))))))

/-- `addn`'s own instructions are in this program: no table before them has one at any of their addresses. -/
theorem in5 (ext : Nat → Option (Instr × Nat)) : ∀ pc x, Code_addn.table.lookup pc = some x → prog ext pc = some x := by
  intro pc x h
  have apart : ∀ p ∈ Code_addn.table.map (·.1), ((pre4.lookup p).isNone) = true := by decide +kernel
  have none := Option.isNone_iff_eq_none.mp (apart pc (lookup_mem_keys _ pc x h))
  have here : pre5.lookup pc = some x := by
    show (pre4 ++ Code_addn.table).lookup pc = some x
    rw [lookup_append_or, none]; exact h
  exact prog_of ext pc x (lookup_append_left pre13 table pc x (lookup_append_left pre12 Code_hashl.table pc x (lookup_append_left pre11 Code_group.table pc x (lookup_append_left pre10 Code_finish.table pc x (lookup_append_left pre9 Code_lroot.table pc x (lookup_append_left pre8 Code_groupf.table pc x (lookup_append_left pre7 Code_node_out.table pc x (lookup_append_left pre6 Code_chunk_node.table pc x (lookup_append_left pre5 Code_pad.table pc x (here))))))))))

/-- `pad`'s own instructions are in this program: no table before them has one at any of their addresses. -/
theorem in6 (ext : Nat → Option (Instr × Nat)) : ∀ pc x, Code_pad.table.lookup pc = some x → prog ext pc = some x := by
  intro pc x h
  have apart : ∀ p ∈ Code_pad.table.map (·.1), ((pre5.lookup p).isNone) = true := by decide +kernel
  have none := Option.isNone_iff_eq_none.mp (apart pc (lookup_mem_keys _ pc x h))
  have here : pre6.lookup pc = some x := by
    show (pre5 ++ Code_pad.table).lookup pc = some x
    rw [lookup_append_or, none]; exact h
  exact prog_of ext pc x (lookup_append_left pre13 table pc x (lookup_append_left pre12 Code_hashl.table pc x (lookup_append_left pre11 Code_group.table pc x (lookup_append_left pre10 Code_finish.table pc x (lookup_append_left pre9 Code_lroot.table pc x (lookup_append_left pre8 Code_groupf.table pc x (lookup_append_left pre7 Code_node_out.table pc x (lookup_append_left pre6 Code_chunk_node.table pc x (here)))))))))

/-- `chunk_node`'s own instructions are in this program: no table before them has one at any of their addresses. -/
theorem in7 (ext : Nat → Option (Instr × Nat)) : ∀ pc x, Code_chunk_node.table.lookup pc = some x → prog ext pc = some x := by
  intro pc x h
  have apart : ∀ p ∈ Code_chunk_node.table.map (·.1), ((pre6.lookup p).isNone) = true := by decide +kernel
  have none := Option.isNone_iff_eq_none.mp (apart pc (lookup_mem_keys _ pc x h))
  have here : pre7.lookup pc = some x := by
    show (pre6 ++ Code_chunk_node.table).lookup pc = some x
    rw [lookup_append_or, none]; exact h
  exact prog_of ext pc x (lookup_append_left pre13 table pc x (lookup_append_left pre12 Code_hashl.table pc x (lookup_append_left pre11 Code_group.table pc x (lookup_append_left pre10 Code_finish.table pc x (lookup_append_left pre9 Code_lroot.table pc x (lookup_append_left pre8 Code_groupf.table pc x (lookup_append_left pre7 Code_node_out.table pc x (here))))))))

/-- `node_out`'s own instructions are in this program: no table before them has one at any of their addresses. -/
theorem in8 (ext : Nat → Option (Instr × Nat)) : ∀ pc x, Code_node_out.table.lookup pc = some x → prog ext pc = some x := by
  intro pc x h
  have apart : ∀ p ∈ Code_node_out.table.map (·.1), ((pre7.lookup p).isNone) = true := by decide +kernel
  have none := Option.isNone_iff_eq_none.mp (apart pc (lookup_mem_keys _ pc x h))
  have here : pre8.lookup pc = some x := by
    show (pre7 ++ Code_node_out.table).lookup pc = some x
    rw [lookup_append_or, none]; exact h
  exact prog_of ext pc x (lookup_append_left pre13 table pc x (lookup_append_left pre12 Code_hashl.table pc x (lookup_append_left pre11 Code_group.table pc x (lookup_append_left pre10 Code_finish.table pc x (lookup_append_left pre9 Code_lroot.table pc x (lookup_append_left pre8 Code_groupf.table pc x (here)))))))

/-- `groupf`'s own instructions are in this program: no table before them has one at any of their addresses. -/
theorem in9 (ext : Nat → Option (Instr × Nat)) : ∀ pc x, Code_groupf.table.lookup pc = some x → prog ext pc = some x := by
  intro pc x h
  have apart : ∀ p ∈ Code_groupf.table.map (·.1), ((pre8.lookup p).isNone) = true := by decide +kernel
  have none := Option.isNone_iff_eq_none.mp (apart pc (lookup_mem_keys _ pc x h))
  have here : pre9.lookup pc = some x := by
    show (pre8 ++ Code_groupf.table).lookup pc = some x
    rw [lookup_append_or, none]; exact h
  exact prog_of ext pc x (lookup_append_left pre13 table pc x (lookup_append_left pre12 Code_hashl.table pc x (lookup_append_left pre11 Code_group.table pc x (lookup_append_left pre10 Code_finish.table pc x (lookup_append_left pre9 Code_lroot.table pc x (here))))))

/-- `lroot`'s own instructions are in this program: no table before them has one at any of their addresses. -/
theorem in10 (ext : Nat → Option (Instr × Nat)) : ∀ pc x, Code_lroot.table.lookup pc = some x → prog ext pc = some x := by
  intro pc x h
  have apart : ∀ p ∈ Code_lroot.table.map (·.1), ((pre9.lookup p).isNone) = true := by decide +kernel
  have none := Option.isNone_iff_eq_none.mp (apart pc (lookup_mem_keys _ pc x h))
  have here : pre10.lookup pc = some x := by
    show (pre9 ++ Code_lroot.table).lookup pc = some x
    rw [lookup_append_or, none]; exact h
  exact prog_of ext pc x (lookup_append_left pre13 table pc x (lookup_append_left pre12 Code_hashl.table pc x (lookup_append_left pre11 Code_group.table pc x (lookup_append_left pre10 Code_finish.table pc x (here)))))

/-- `finish`'s own instructions are in this program: no table before them has one at any of their addresses. -/
theorem in11 (ext : Nat → Option (Instr × Nat)) : ∀ pc x, Code_finish.table.lookup pc = some x → prog ext pc = some x := by
  intro pc x h
  have apart : ∀ p ∈ Code_finish.table.map (·.1), ((pre10.lookup p).isNone) = true := by decide +kernel
  have none := Option.isNone_iff_eq_none.mp (apart pc (lookup_mem_keys _ pc x h))
  have here : pre11.lookup pc = some x := by
    show (pre10 ++ Code_finish.table).lookup pc = some x
    rw [lookup_append_or, none]; exact h
  exact prog_of ext pc x (lookup_append_left pre13 table pc x (lookup_append_left pre12 Code_hashl.table pc x (lookup_append_left pre11 Code_group.table pc x (here))))

/-- `group`'s own instructions are in this program: no table before them has one at any of their addresses. -/
theorem in12 (ext : Nat → Option (Instr × Nat)) : ∀ pc x, Code_group.table.lookup pc = some x → prog ext pc = some x := by
  intro pc x h
  have apart : ∀ p ∈ Code_group.table.map (·.1), ((pre11.lookup p).isNone) = true := by decide +kernel
  have none := Option.isNone_iff_eq_none.mp (apart pc (lookup_mem_keys _ pc x h))
  have here : pre12.lookup pc = some x := by
    show (pre11 ++ Code_group.table).lookup pc = some x
    rw [lookup_append_or, none]; exact h
  exact prog_of ext pc x (lookup_append_left pre13 table pc x (lookup_append_left pre12 Code_hashl.table pc x (here)))

/-- `hashl`'s own instructions are in this program: no table before them has one at any of their addresses. -/
theorem in13 (ext : Nat → Option (Instr × Nat)) : ∀ pc x, Code_hashl.table.lookup pc = some x → prog ext pc = some x := by
  intro pc x h
  have apart : ∀ p ∈ Code_hashl.table.map (·.1), ((pre12.lookup p).isNone) = true := by decide +kernel
  have none := Option.isNone_iff_eq_none.mp (apart pc (lookup_mem_keys _ pc x h))
  have here : pre13.lookup pc = some x := by
    show (pre12 ++ Code_hashl.table).lookup pc = some x
    rw [lookup_append_or, none]; exact h
  exact prog_of ext pc x (lookup_append_left pre13 table pc x (here))

/-- The tables of `wide`'s program (its own instructions and those of what it calls) are in this one, unchanged. -/
theorem tables_wide (ext : Nat → Option (Instr × Nat)) : ∀ pc x, (KCode.table ++ Code_fillp.table ++ Code_tree32.table ++ Code_ladd.table ++ Code_wide.table).lookup pc = some x → prog ext pc = some x := by
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
          exact in4 ext pc x h'

/-- `wide`'s program over this one is this one: a theorem about `wide` over any program holds here. -/
theorem has_wide (ext : Nat → Option (Instr × Nat)) : ∀ pc x, Code_wide.prog (prog ext) pc = some x → prog ext pc = some x := by
  intro pc x h
  have h0 : ((KCode.table ++ Code_fillp.table ++ Code_tree32.table ++ Code_ladd.table ++ Code_wide.table).lookup pc).or (prog ext pc) = some x := h
  cases hw : (KCode.table ++ Code_fillp.table ++ Code_tree32.table ++ Code_ladd.table ++ Code_wide.table).lookup pc with
  | none => rw [hw] at h0; simpa only [Option.none_or] using h0
  | some y =>
    rw [hw] at h0; simp only [Option.some_or, Option.some.injEq] at h0; subst h0
    exact tables_wide ext pc y hw

/-- And this program is `wide`'s over it: what is assumed of this program holds of that one. -/
theorem over_wide (ext : Nat → Option (Instr × Nat)) : ∀ pc x, prog ext pc = some x → Code_wide.prog (prog ext) pc = some x := by
  intro pc x h
  show ((KCode.table ++ Code_fillp.table ++ Code_tree32.table ++ Code_ladd.table ++ Code_wide.table).lookup pc).or (prog ext pc) = some x
  cases hw : (KCode.table ++ Code_fillp.table ++ Code_tree32.table ++ Code_ladd.table ++ Code_wide.table).lookup pc with
  | none => simpa only [Option.none_or] using h
  | some y =>
    have e := tables_wide ext pc y hw
    rw [h] at e; rw [Option.some_or]; exact e.symm

/-- The tables of `groupf`'s program (its own instructions and those of what it calls) are in this one, unchanged. -/
theorem tables_groupf (ext : Nat → Option (Instr × Nat)) : ∀ pc x, (KCode.table ++ Code_ladd.table ++ Code_addn.table ++ Code_pad.table ++ Code_chunk_node.table ++ Code_node_out.table ++ Code_fillp.table ++ Code_groupf.table).lookup pc = some x → prog ext pc = some x := by
  intro pc x h'
  simp only [lookup_append_or] at h'
  cases h0 : KCode.table.lookup pc with
  | some y =>
    rw [h0] at h'; simp only [Option.some_or, Option.some.injEq] at h'; subst h'
    exact has_kernels ext pc y h0
  | none =>
    rw [h0] at h'; simp only [Option.none_or] at h'
    cases h1 : Code_ladd.table.lookup pc with
    | some y =>
      rw [h1] at h'; simp only [Option.some_or, Option.some.injEq] at h'; subst h'
      exact in3 ext pc y h1
    | none =>
      rw [h1] at h'; simp only [Option.none_or] at h'
      cases h2 : Code_addn.table.lookup pc with
      | some y =>
        rw [h2] at h'; simp only [Option.some_or, Option.some.injEq] at h'; subst h'
        exact in5 ext pc y h2
      | none =>
        rw [h2] at h'; simp only [Option.none_or] at h'
        cases h3 : Code_pad.table.lookup pc with
        | some y =>
          rw [h3] at h'; simp only [Option.some_or, Option.some.injEq] at h'; subst h'
          exact in6 ext pc y h3
        | none =>
          rw [h3] at h'; simp only [Option.none_or] at h'
          cases h4 : Code_chunk_node.table.lookup pc with
          | some y =>
            rw [h4] at h'; simp only [Option.some_or, Option.some.injEq] at h'; subst h'
            exact in7 ext pc y h4
          | none =>
            rw [h4] at h'; simp only [Option.none_or] at h'
            cases h5 : Code_node_out.table.lookup pc with
            | some y =>
              rw [h5] at h'; simp only [Option.some_or, Option.some.injEq] at h'; subst h'
              exact in8 ext pc y h5
            | none =>
              rw [h5] at h'; simp only [Option.none_or] at h'
              cases h6 : Code_fillp.table.lookup pc with
              | some y =>
                rw [h6] at h'; simp only [Option.some_or, Option.some.injEq] at h'; subst h'
                exact in1 ext pc y h6
              | none =>
                rw [h6] at h'; simp only [Option.none_or] at h'
                exact in9 ext pc x h'

/-- `groupf`'s program over this one is this one: a theorem about `groupf` over any program holds here. -/
theorem has_groupf (ext : Nat → Option (Instr × Nat)) : ∀ pc x, Code_groupf.prog (prog ext) pc = some x → prog ext pc = some x := by
  intro pc x h
  have h0 : ((KCode.table ++ Code_ladd.table ++ Code_addn.table ++ Code_pad.table ++ Code_chunk_node.table ++ Code_node_out.table ++ Code_fillp.table ++ Code_groupf.table).lookup pc).or (prog ext pc) = some x := h
  cases hw : (KCode.table ++ Code_ladd.table ++ Code_addn.table ++ Code_pad.table ++ Code_chunk_node.table ++ Code_node_out.table ++ Code_fillp.table ++ Code_groupf.table).lookup pc with
  | none => rw [hw] at h0; simpa only [Option.none_or] using h0
  | some y =>
    rw [hw] at h0; simp only [Option.some_or, Option.some.injEq] at h0; subst h0
    exact tables_groupf ext pc y hw

/-- And this program is `groupf`'s over it: what is assumed of this program holds of that one. -/
theorem over_groupf (ext : Nat → Option (Instr × Nat)) : ∀ pc x, prog ext pc = some x → Code_groupf.prog (prog ext) pc = some x := by
  intro pc x h
  show ((KCode.table ++ Code_ladd.table ++ Code_addn.table ++ Code_pad.table ++ Code_chunk_node.table ++ Code_node_out.table ++ Code_fillp.table ++ Code_groupf.table).lookup pc).or (prog ext pc) = some x
  cases hw : (KCode.table ++ Code_ladd.table ++ Code_addn.table ++ Code_pad.table ++ Code_chunk_node.table ++ Code_node_out.table ++ Code_fillp.table ++ Code_groupf.table).lookup pc with
  | none => simpa only [Option.none_or] using h
  | some y =>
    have e := tables_groupf ext pc y hw
    rw [h] at e; rw [Option.some_or]; exact e.symm

/-- The tables of `finish`'s program (its own instructions and those of what it calls) are in this one, unchanged. -/
theorem tables_finish (ext : Nat → Option (Instr × Nat)) : ∀ pc x, (KCode.table ++ Code_lroot.table ++ Code_ladd.table ++ Code_finish.table).lookup pc = some x → prog ext pc = some x := by
  intro pc x h'
  simp only [lookup_append_or] at h'
  cases h0 : KCode.table.lookup pc with
  | some y =>
    rw [h0] at h'; simp only [Option.some_or, Option.some.injEq] at h'; subst h'
    exact has_kernels ext pc y h0
  | none =>
    rw [h0] at h'; simp only [Option.none_or] at h'
    cases h1 : Code_lroot.table.lookup pc with
    | some y =>
      rw [h1] at h'; simp only [Option.some_or, Option.some.injEq] at h'; subst h'
      exact in10 ext pc y h1
    | none =>
      rw [h1] at h'; simp only [Option.none_or] at h'
      cases h2 : Code_ladd.table.lookup pc with
      | some y =>
        rw [h2] at h'; simp only [Option.some_or, Option.some.injEq] at h'; subst h'
        exact in3 ext pc y h2
      | none =>
        rw [h2] at h'; simp only [Option.none_or] at h'
        exact in11 ext pc x h'

/-- `finish`'s program (its own instructions and those of what it calls) is part of this one, unchanged. -/
theorem has_finish (ext : Nat → Option (Instr × Nat)) : ∀ pc x, Code_finish.prog pc = some x → prog ext pc = some x :=
  fun pc x h => tables_finish ext pc x h

/-- The tables of `group`'s program (its own instructions and those of what it calls) are in this one, unchanged. -/
theorem tables_group (ext : Nat → Option (Instr × Nat)) : ∀ pc x, (KCode.table ++ Code_pad.table ++ Code_chunk_node.table ++ Code_node_out.table ++ Code_ladd.table ++ Code_group.table).lookup pc = some x → prog ext pc = some x := by
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
            exact in12 ext pc x h'

/-- `group`'s program (its own instructions and those of what it calls) is part of this one, unchanged. -/
theorem has_group (ext : Nat → Option (Instr × Nat)) : ∀ pc x, Code_group.prog pc = some x → prog ext pc = some x :=
  fun pc x h => tables_group ext pc x h

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

@[ode_at] theorem at_190000 (ext : Nat → Option (Instr × Nat)) : prog ext 0x190000 = some (.push .rbx, 0x190001) := rfl
@[ode_at] theorem at_190001 (ext : Nat → Option (Instr × Nat)) : prog ext 0x190001 = some (.push .rbp, 0x190002) := rfl
@[ode_at] theorem at_190002 (ext : Nat → Option (Instr × Nat)) : prog ext 0x190002 = some (.push .r12, 0x190004) := rfl
@[ode_at] theorem at_190004 (ext : Nat → Option (Instr × Nat)) : prog ext 0x190004 = some (.push .r13, 0x190006) := rfl
@[ode_at] theorem at_190006 (ext : Nat → Option (Instr × Nat)) : prog ext 0x190006 = some (.push .r14, 0x190008) := rfl
@[ode_at] theorem at_190008 (ext : Nat → Option (Instr × Nat)) : prog ext 0x190008 = some (.push .r15, 0x19000A) := rfl
@[ode_at] theorem at_19000A (ext : Nat → Option (Instr × Nat)) : prog ext 0x19000A = some (.sub 64 (.reg .rsp) (.imm 0x1B98), 0x190011) := rfl
@[ode_at] theorem at_190011 (ext : Nat → Option (Instr × Nat)) : prog ext 0x190011 = some (.mov 64 (.reg .rbx) (.reg .rdi), 0x190014) := rfl
@[ode_at] theorem at_190014 (ext : Nat → Option (Instr × Nat)) : prog ext 0x190014 = some (.mov 64 (.reg .rbp) (.reg .rsi), 0x190017) := rfl
@[ode_at] theorem at_190017 (ext : Nat → Option (Instr × Nat)) : prog ext 0x190017 = some (.mov 64 (.reg .r12) (.reg .rdx), 0x19001A) := rfl
@[ode_at] theorem at_19001A (ext : Nat → Option (Instr × Nat)) : prog ext 0x19001A = some (.mov 64 (.reg .r13) (.reg .rcx), 0x19001D) := rfl
@[ode_at] theorem at_19001D (ext : Nat → Option (Instr × Nat)) : prog ext 0x19001D = some (.mov 64 (.reg .r14) (.reg .r8), 0x190020) := rfl
@[ode_at] theorem at_190020 (ext : Nat → Option (Instr × Nat)) : prog ext 0x190020 = some (.mov 64 (.reg .rax) (.imm 0x400), 0x190027) := rfl
@[ode_at] theorem at_190027 (ext : Nat → Option (Instr × Nat)) : prog ext 0x190027 = some (.mov 64 (.reg .rcx) (.reg .r12), 0x19002A) := rfl
@[ode_at] theorem at_19002A (ext : Nat → Option (Instr × Nat)) : prog ext 0x19002A = some (.cmp 64 (.reg .rax) (.reg .rcx), 0x19002D) := rfl
@[ode_at] theorem at_19002D (ext : Nat → Option (Instr × Nat)) : prog ext 0x19002D = some (.jae 0x190176, 0x190033) := rfl
@[ode_at] theorem at_190033 (ext : Nat → Option (Instr × Nat)) : prog ext 0x190033 = some (.lea .rdi .rsp 0x0, 0x190037) := rfl
@[ode_at] theorem at_190037 (ext : Nat → Option (Instr × Nat)) : prog ext 0x190037 = some (.mov 64 (.reg .rsi) (.reg .rbp), 0x19003A) := rfl
@[ode_at] theorem at_19003A (ext : Nat → Option (Instr × Nat)) : prog ext 0x19003A = some (.mov 64 (.reg .rdx) (.reg .r12), 0x19003D) := rfl
@[ode_at] theorem at_19003D (ext : Nat → Option (Instr × Nat)) : prog ext 0x19003D = some (.mov 64 (.reg .rcx) (.reg .r13), 0x190040) := rfl
@[ode_at] theorem at_190040 (ext : Nat → Option (Instr × Nat)) : prog ext 0x190040 = some (.mov 64 (.reg .r8) (.reg .r14), 0x190043) := rfl
@[ode_at] theorem at_190043 (ext : Nat → Option (Instr × Nat)) : prog ext 0x190043 = some (.call 0x130000, 0x190048) := rfl
@[ode_at] theorem at_190048 (ext : Nat → Option (Instr × Nat)) : prog ext 0x190048 = some (.mov 64 (.reg .r15) (.reg .rax), 0x19004B) := rfl
@[ode_at] theorem at_19004B (ext : Nat → Option (Instr × Nat)) : prog ext 0x19004B = some (.mov 64 (.reg .rax) (.reg .rbp), 0x19004E) := rfl
@[ode_at] theorem at_19004E (ext : Nat → Option (Instr × Nat)) : prog ext 0x19004E = some (.mov 64 (.reg .rcx) (.reg .r15), 0x190051) := rfl
@[ode_at] theorem at_190051 (ext : Nat → Option (Instr × Nat)) : prog ext 0x190051 = some (.shl64 .rcx 10, 0x190055) := rfl
@[ode_at] theorem at_190055 (ext : Nat → Option (Instr × Nat)) : prog ext 0x190055 = some (.add 64 (.reg .rax) (.reg .rcx), 0x190058) := rfl
@[ode_at] theorem at_190058 (ext : Nat → Option (Instr × Nat)) : prog ext 0x190058 = some (.mov 64 (.mem .rsp 0x1B80) (.reg .rax), 0x190060) := rfl
@[ode_at] theorem at_190060 (ext : Nat → Option (Instr × Nat)) : prog ext 0x190060 = some (.mov 64 (.reg .rax) (.reg .r12), 0x190063) := rfl
@[ode_at] theorem at_190063 (ext : Nat → Option (Instr × Nat)) : prog ext 0x190063 = some (.mov 64 (.reg .rcx) (.reg .r15), 0x190066) := rfl
@[ode_at] theorem at_190066 (ext : Nat → Option (Instr × Nat)) : prog ext 0x190066 = some (.shl64 .rcx 10, 0x19006A) := rfl
@[ode_at] theorem at_19006A (ext : Nat → Option (Instr × Nat)) : prog ext 0x19006A = some (.sub 64 (.reg .rax) (.reg .rcx), 0x19006D) := rfl
@[ode_at] theorem at_19006D (ext : Nat → Option (Instr × Nat)) : prog ext 0x19006D = some (.mov 64 (.mem .rsp 0x1B88) (.reg .rax), 0x190075) := rfl
@[ode_at] theorem at_190075 (ext : Nat → Option (Instr × Nat)) : prog ext 0x190075 = some (.mov 64 (.reg .rax) (.reg .r15), 0x190078) := rfl
@[ode_at] theorem at_190078 (ext : Nat → Option (Instr × Nat)) : prog ext 0x190078 = some (.mov 64 (.reg .rcx) (.imm 0x0), 0x19007F) := rfl
@[ode_at] theorem at_19007F (ext : Nat → Option (Instr × Nat)) : prog ext 0x19007F = some (.cmp 64 (.reg .rax) (.reg .rcx), 0x190082) := rfl
@[ode_at] theorem at_190082 (ext : Nat → Option (Instr × Nat)) : prog ext 0x190082 = some (.jne 0x1900D0, 0x190084) := rfl
@[ode_at] theorem at_190084 (ext : Nat → Option (Instr × Nat)) : prog ext 0x190084 = some (.lea .rdi .rsp 0xDC0, 0x19008C) := rfl
@[ode_at] theorem at_19008C (ext : Nat → Option (Instr × Nat)) : prog ext 0x19008C = some (.mov 64 (.reg .rsi) (.mem .rsp 0x1B80), 0x190094) := rfl
@[ode_at] theorem at_190094 (ext : Nat → Option (Instr × Nat)) : prog ext 0x190094 = some (.mov 64 (.reg .rdx) (.mem .rsp 0x1B88), 0x19009C) := rfl
@[ode_at] theorem at_19009C (ext : Nat → Option (Instr × Nat)) : prog ext 0x19009C = some (.mov 64 (.reg .rcx) (.reg .r13), 0x19009F) := rfl
@[ode_at] theorem at_19009F (ext : Nat → Option (Instr × Nat)) : prog ext 0x19009F = some (.mov 64 (.reg .r8) (.reg .r14), 0x1900A2) := rfl
@[ode_at] theorem at_1900A2 (ext : Nat → Option (Instr × Nat)) : prog ext 0x1900A2 = some (.mov 64 (.reg .r9) (.reg .r15), 0x1900A5) := rfl
@[ode_at] theorem at_1900A5 (ext : Nat → Option (Instr × Nat)) : prog ext 0x1900A5 = some (.call 0x1B0000, 0x1900AA) := rfl
@[ode_at] theorem at_1900AA (ext : Nat → Option (Instr × Nat)) : prog ext 0x1900AA = some (.mov 64 (.reg .rdi) (.reg .rbx), 0x1900AD) := rfl
@[ode_at] theorem at_1900AD (ext : Nat → Option (Instr × Nat)) : prog ext 0x1900AD = some (.lea .rsi .rsp 0x0, 0x1900B1) := rfl
@[ode_at] theorem at_1900B1 (ext : Nat → Option (Instr × Nat)) : prog ext 0x1900B1 = some (.lea .rdx .rsp 0xDC0, 0x1900B9) := rfl
@[ode_at] theorem at_1900B9 (ext : Nat → Option (Instr × Nat)) : prog ext 0x1900B9 = some (.mov 64 (.reg .rcx) (.reg .r13), 0x1900BC) := rfl
@[ode_at] theorem at_1900BC (ext : Nat → Option (Instr × Nat)) : prog ext 0x1900BC = some (.mov 64 (.reg .r8) (.reg .r14), 0x1900BF) := rfl
@[ode_at] theorem at_1900BF (ext : Nat → Option (Instr × Nat)) : prog ext 0x1900BF = some (.mov 64 (.reg .r9) (.imm 0x0), 0x1900C6) := rfl
@[ode_at] theorem at_1900C6 (ext : Nat → Option (Instr × Nat)) : prog ext 0x1900C6 = some (.call 0x170000, 0x1900CB) := rfl
@[ode_at] theorem at_1900CB (ext : Nat → Option (Instr × Nat)) : prog ext 0x1900CB = some (.jmp 0x190174, 0x1900D0) := rfl
@[ode_at] theorem at_1900D0 (ext : Nat → Option (Instr × Nat)) : prog ext 0x1900D0 = some (.mov 64 (.reg .rax) (.imm 0x400), 0x1900D7) := rfl
@[ode_at] theorem at_1900D7 (ext : Nat → Option (Instr × Nat)) : prog ext 0x1900D7 = some (.mov 64 (.reg .rcx) (.mem .rsp 0x1B88), 0x1900DF) := rfl
@[ode_at] theorem at_1900DF (ext : Nat → Option (Instr × Nat)) : prog ext 0x1900DF = some (.cmp 64 (.reg .rax) (.reg .rcx), 0x1900E2) := rfl
@[ode_at] theorem at_1900E2 (ext : Nat → Option (Instr × Nat)) : prog ext 0x1900E2 = some (.jae 0x19012D, 0x1900E4) := rfl
@[ode_at] theorem at_1900E4 (ext : Nat → Option (Instr × Nat)) : prog ext 0x1900E4 = some (.lea .rdi .rsp 0xDC0, 0x1900EC) := rfl
@[ode_at] theorem at_1900EC (ext : Nat → Option (Instr × Nat)) : prog ext 0x1900EC = some (.mov 64 (.reg .rsi) (.mem .rsp 0x1B80), 0x1900F4) := rfl
@[ode_at] theorem at_1900F4 (ext : Nat → Option (Instr × Nat)) : prog ext 0x1900F4 = some (.mov 64 (.reg .rdx) (.mem .rsp 0x1B88), 0x1900FC) := rfl
@[ode_at] theorem at_1900FC (ext : Nat → Option (Instr × Nat)) : prog ext 0x1900FC = some (.mov 64 (.reg .rcx) (.reg .r13), 0x1900FF) := rfl
@[ode_at] theorem at_1900FF (ext : Nat → Option (Instr × Nat)) : prog ext 0x1900FF = some (.mov 64 (.reg .r8) (.reg .r14), 0x190102) := rfl
@[ode_at] theorem at_190102 (ext : Nat → Option (Instr × Nat)) : prog ext 0x190102 = some (.mov 64 (.reg .r9) (.reg .r15), 0x190105) := rfl
@[ode_at] theorem at_190105 (ext : Nat → Option (Instr × Nat)) : prog ext 0x190105 = some (.call 0x1B0000, 0x19010A) := rfl
@[ode_at] theorem at_19010A (ext : Nat → Option (Instr × Nat)) : prog ext 0x19010A = some (.mov 64 (.reg .rdi) (.reg .rbx), 0x19010D) := rfl
@[ode_at] theorem at_19010D (ext : Nat → Option (Instr × Nat)) : prog ext 0x19010D = some (.lea .rsi .rsp 0x0, 0x190111) := rfl
@[ode_at] theorem at_190111 (ext : Nat → Option (Instr × Nat)) : prog ext 0x190111 = some (.lea .rdx .rsp 0xDC0, 0x190119) := rfl
@[ode_at] theorem at_190119 (ext : Nat → Option (Instr × Nat)) : prog ext 0x190119 = some (.mov 64 (.reg .rcx) (.reg .r13), 0x19011C) := rfl
@[ode_at] theorem at_19011C (ext : Nat → Option (Instr × Nat)) : prog ext 0x19011C = some (.mov 64 (.reg .r8) (.reg .r14), 0x19011F) := rfl
@[ode_at] theorem at_19011F (ext : Nat → Option (Instr × Nat)) : prog ext 0x19011F = some (.mov 64 (.reg .r9) (.imm 0x2), 0x190126) := rfl
@[ode_at] theorem at_190126 (ext : Nat → Option (Instr × Nat)) : prog ext 0x190126 = some (.call 0x170000, 0x19012B) := rfl
@[ode_at] theorem at_19012B (ext : Nat → Option (Instr × Nat)) : prog ext 0x19012B = some (.jmp 0x190174, 0x19012D) := rfl
@[ode_at] theorem at_19012D (ext : Nat → Option (Instr × Nat)) : prog ext 0x19012D = some (.lea .rdi .rsp 0xDC0, 0x190135) := rfl
@[ode_at] theorem at_190135 (ext : Nat → Option (Instr × Nat)) : prog ext 0x190135 = some (.mov 64 (.reg .rsi) (.mem .rsp 0x1B80), 0x19013D) := rfl
@[ode_at] theorem at_19013D (ext : Nat → Option (Instr × Nat)) : prog ext 0x19013D = some (.mov 64 (.reg .rdx) (.mem .rsp 0x1B88), 0x190145) := rfl
@[ode_at] theorem at_190145 (ext : Nat → Option (Instr × Nat)) : prog ext 0x190145 = some (.mov 64 (.reg .rcx) (.reg .r13), 0x190148) := rfl
@[ode_at] theorem at_190148 (ext : Nat → Option (Instr × Nat)) : prog ext 0x190148 = some (.mov 64 (.reg .r8) (.reg .r14), 0x19014B) := rfl
@[ode_at] theorem at_19014B (ext : Nat → Option (Instr × Nat)) : prog ext 0x19014B = some (.mov 64 (.reg .r9) (.reg .r15), 0x19014E) := rfl
@[ode_at] theorem at_19014E (ext : Nat → Option (Instr × Nat)) : prog ext 0x19014E = some (.call 0x180000, 0x190153) := rfl
@[ode_at] theorem at_190153 (ext : Nat → Option (Instr × Nat)) : prog ext 0x190153 = some (.mov 64 (.reg .rdi) (.reg .rbx), 0x190156) := rfl
@[ode_at] theorem at_190156 (ext : Nat → Option (Instr × Nat)) : prog ext 0x190156 = some (.lea .rsi .rsp 0x0, 0x19015A) := rfl
@[ode_at] theorem at_19015A (ext : Nat → Option (Instr × Nat)) : prog ext 0x19015A = some (.lea .rdx .rsp 0xDC0, 0x190162) := rfl
@[ode_at] theorem at_190162 (ext : Nat → Option (Instr × Nat)) : prog ext 0x190162 = some (.mov 64 (.reg .rcx) (.reg .r13), 0x190165) := rfl
@[ode_at] theorem at_190165 (ext : Nat → Option (Instr × Nat)) : prog ext 0x190165 = some (.mov 64 (.reg .r8) (.reg .r14), 0x190168) := rfl
@[ode_at] theorem at_190168 (ext : Nat → Option (Instr × Nat)) : prog ext 0x190168 = some (.mov 64 (.reg .r9) (.imm 0x1), 0x19016F) := rfl
@[ode_at] theorem at_19016F (ext : Nat → Option (Instr × Nat)) : prog ext 0x19016F = some (.call 0x170000, 0x190174) := rfl
@[ode_at] theorem at_190174 (ext : Nat → Option (Instr × Nat)) : prog ext 0x190174 = some (.jmp 0x190191, 0x190176) := rfl
@[ode_at] theorem at_190176 (ext : Nat → Option (Instr × Nat)) : prog ext 0x190176 = some (.mov 64 (.reg .rdi) (.reg .rbx), 0x190179) := rfl
@[ode_at] theorem at_190179 (ext : Nat → Option (Instr × Nat)) : prog ext 0x190179 = some (.mov 64 (.reg .rsi) (.reg .rbp), 0x19017C) := rfl
@[ode_at] theorem at_19017C (ext : Nat → Option (Instr × Nat)) : prog ext 0x19017C = some (.mov 64 (.reg .rdx) (.reg .r12), 0x19017F) := rfl
@[ode_at] theorem at_19017F (ext : Nat → Option (Instr × Nat)) : prog ext 0x19017F = some (.mov 64 (.reg .rcx) (.reg .r13), 0x190182) := rfl
@[ode_at] theorem at_190182 (ext : Nat → Option (Instr × Nat)) : prog ext 0x190182 = some (.mov 64 (.reg .r8) (.reg .r14), 0x190185) := rfl
@[ode_at] theorem at_190185 (ext : Nat → Option (Instr × Nat)) : prog ext 0x190185 = some (.mov 64 (.reg .r9) (.imm 0x5), 0x19018C) := rfl
@[ode_at] theorem at_19018C (ext : Nat → Option (Instr × Nat)) : prog ext 0x19018C = some (.call 0x40000, 0x190191) := rfl
@[ode_at] theorem at_190191 (ext : Nat → Option (Instr × Nat)) : prog ext 0x190191 = some (.add 64 (.reg .rsp) (.imm 0x1B98), 0x190198) := rfl
@[ode_at] theorem at_190198 (ext : Nat → Option (Instr × Nat)) : prog ext 0x190198 = some (.pop .r15, 0x19019A) := rfl
@[ode_at] theorem at_19019A (ext : Nat → Option (Instr × Nat)) : prog ext 0x19019A = some (.pop .r14, 0x19019C) := rfl
@[ode_at] theorem at_19019C (ext : Nat → Option (Instr × Nat)) : prog ext 0x19019C = some (.pop .r13, 0x19019E) := rfl
@[ode_at] theorem at_19019E (ext : Nat → Option (Instr × Nat)) : prog ext 0x19019E = some (.pop .r12, 0x1901A0) := rfl
@[ode_at] theorem at_1901A0 (ext : Nat → Option (Instr × Nat)) : prog ext 0x1901A0 = some (.pop .rbp, 0x1901A1) := rfl
@[ode_at] theorem at_1901A1 (ext : Nat → Option (Instr × Nat)) : prog ext 0x1901A1 = some (.pop .rbx, 0x1901A2) := rfl
@[ode_at] theorem at_1901A2 (ext : Nat → Option (Instr × Nat)) : prog ext 0x1901A2 = some (.ret, 0x1901A3) := rfl

end Code_hashw
