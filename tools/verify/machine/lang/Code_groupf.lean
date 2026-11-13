import Machine
import KCode
import Cells
import Code_ladd
import Code_addn
import Code_pad
import Code_chunk_node
import Code_node_out
import Code_fillp
open X86

/-! `groupf` as assembled: 86 instructions. Written from the lifter's rows. -/

set_option maxRecDepth 100000
namespace Code_groupf

def table : List (Nat × Instr × Nat) := [
  (0x1B0000, .push .rbx, 0x1B0001),
  (0x1B0001, .push .rbp, 0x1B0002),
  (0x1B0002, .push .r12, 0x1B0004),
  (0x1B0004, .push .r13, 0x1B0006),
  (0x1B0006, .push .r14, 0x1B0008),
  (0x1B0008, .push .r15, 0x1B000A),
  (0x1B000A, .sub 64 (.reg .rsp) (.imm 0x5C8), 0x1B0011),
  (0x1B0011, .mov 64 (.reg .rbx) (.reg .rdi), 0x1B0014),
  (0x1B0014, .mov 64 (.reg .rbp) (.reg .rsi), 0x1B0017),
  (0x1B0017, .mov 64 (.reg .r12) (.reg .rdx), 0x1B001A),
  (0x1B001A, .mov 64 (.reg .r13) (.reg .rcx), 0x1B001D),
  (0x1B001D, .mov 64 (.reg .r14) (.reg .r8), 0x1B0020),
  (0x1B0020, .mov 64 (.reg .r15) (.reg .r9), 0x1B0023),
  (0x1B0023, .mov 64 (.reg .rax) (.reg .r14), 0x1B0026),
  (0x1B0026, .or 64 (.reg .rax) (.imm 0x40020100), 0x1B002C),
  (0x1B002C, .mov 64 (.mem .rsp 0x5A0) (.reg .rax), 0x1B0034),
  (0x1B0034, .mov 64 (.reg .rax) (.reg .r12), 0x1B0037),
  (0x1B0037, .sub 64 (.reg .rax) (.imm 0x1), 0x1B003B),
  (0x1B003B, .shr64 .rax 10, 0x1B003F),
  (0x1B003F, .mov 64 (.mem .rsp 0x5A8) (.reg .rax), 0x1B0047),
  (0x1B0047, .mov 64 (.reg .rax) (.reg .rbp), 0x1B004A),
  (0x1B004A, .mov 64 (.reg .rcx) (.mem .rsp 0x5A8), 0x1B0052),
  (0x1B0052, .shl64 .rcx 10, 0x1B0056),
  (0x1B0056, .add 64 (.reg .rax) (.reg .rcx), 0x1B0059),
  (0x1B0059, .mov 64 (.mem .rsp 0x5B0) (.reg .rax), 0x1B0061),
  (0x1B0061, .mov 64 (.reg .rax) (.reg .r12), 0x1B0064),
  (0x1B0064, .mov 64 (.reg .rcx) (.mem .rsp 0x5A8), 0x1B006C),
  (0x1B006C, .shl64 .rcx 10, 0x1B0070),
  (0x1B0070, .sub 64 (.reg .rax) (.reg .rcx), 0x1B0073),
  (0x1B0073, .mov 64 (.mem .rsp 0x5B8) (.reg .rax), 0x1B007B),
  (0x1B007B, .mov 64 (.reg .rax) (.reg .r15), 0x1B007E),
  (0x1B007E, .add 64 (.reg .rax) (.mem .rsp 0x5A8), 0x1B0086),
  (0x1B0086, .mov 64 (.mem .rsp 0x5C0) (.reg .rax), 0x1B008E),
  (0x1B008E, .lea .rdi .rsp 0xA0, 0x1B0096),
  (0x1B0096, .mov 64 (.reg .rsi) (.reg .rbp), 0x1B0099),
  (0x1B0099, .mov 64 (.reg .rdx) (.mem .rsp 0x5A8), 0x1B00A1),
  (0x1B00A1, .mov 64 (.reg .rcx) (.imm 0x400), 0x1B00A8),
  (0x1B00A8, .call 0x110000, 0x1B00AD),
  (0x1B00AD, .lea .rdi .rsp 0xA0, 0x1B00B5),
  (0x1B00B5, .mov 64 (.reg .rsi) (.imm 0x10), 0x1B00BC),
  (0x1B00BC, .mov 64 (.reg .rdx) (.reg .r13), 0x1B00BF),
  (0x1B00BF, .mov 64 (.reg .rcx) (.reg .r15), 0x1B00C2),
  (0x1B00C2, .mov 64 (.reg .r8) (.mem .rsp 0x5A0), 0x1B00CA),
  (0x1B00CA, .lea .r9 .rsp 0x1A0, 0x1B00D2),
  (0x1B00D2, .call 0x10000, 0x1B00D7),
  (0x1B00D7, .mov 64 (.reg .rax) (.imm 0x0), 0x1B00DE),
  (0x1B00DE, .mov 64 (.reg .rcx) (.reg .rbx), 0x1B00E1),
  (0x1B00E1, .mov 64 (.mem .rcx 0x0) (.reg .rax), 0x1B00E4),
  (0x1B00E4, .mov 64 (.reg .rdi) (.reg .rbx), 0x1B00E7),
  (0x1B00E7, .mov 64 (.reg .rsi) (.reg .r13), 0x1B00EA),
  (0x1B00EA, .mov 64 (.reg .rdx) (.reg .r14), 0x1B00ED),
  (0x1B00ED, .lea .rcx .rsp 0x1A0, 0x1B00F5),
  (0x1B00F5, .mov 64 (.reg .r8) (.mem .rsp 0x5A8), 0x1B00FD),
  (0x1B00FD, .call 0x160000, 0x1B0102),
  (0x1B0102, .mov 64 (.reg .rax) (.reg .r13), 0x1B0105),
  (0x1B0105, .lea .rcx .rsp 0x0, 0x1B0109),
  (0x1B0109, .movv false 0 (.m .rax 0x0), 0x1B010C),
  (0x1B010C, .storev false .rcx 0x0 0, 0x1B010F),
  (0x1B010F, .movv false 0 (.m .rax 0x10), 0x1B0113),
  (0x1B0113, .storev false .rcx 0x10 0, 0x1B0117),
  (0x1B0117, .lea .rdi .rsp 0x0, 0x1B011B),
  (0x1B011B, .mov 64 (.reg .rsi) (.mem .rsp 0x5B0), 0x1B0123),
  (0x1B0123, .mov 64 (.reg .rdx) (.mem .rsp 0x5B8), 0x1B012B),
  (0x1B012B, .mov 64 (.reg .rcx) (.mem .rsp 0x5C0), 0x1B0133),
  (0x1B0133, .mov 64 (.reg .r8) (.reg .r14), 0x1B0136),
  (0x1B0136, .mov 64 (.reg .r9) (.imm 0x5), 0x1B013D),
  (0x1B013D, .call 0xF0000, 0x1B0142),
  (0x1B0142, .lea .rdi .rsp 0x80, 0x1B014A),
  (0x1B014A, .lea .rsi .rsp 0x0, 0x1B014E),
  (0x1B014E, .mov 64 (.reg .rdx) (.imm 0x0), 0x1B0155),
  (0x1B0155, .mov 64 (.reg .rcx) (.imm 0x5), 0x1B015C),
  (0x1B015C, .call 0xD0000, 0x1B0161),
  (0x1B0161, .mov 64 (.reg .rdi) (.reg .rbx), 0x1B0164),
  (0x1B0164, .mov 64 (.reg .rsi) (.reg .r13), 0x1B0167),
  (0x1B0167, .mov 64 (.reg .rdx) (.reg .r14), 0x1B016A),
  (0x1B016A, .mov 64 (.reg .rcx) (.imm 0x5), 0x1B0171),
  (0x1B0171, .lea .r8 .rsp 0x80, 0x1B0179),
  (0x1B0179, .call 0xB0000, 0x1B017E),
  (0x1B017E, .add 64 (.reg .rsp) (.imm 0x5C8), 0x1B0185),
  (0x1B0185, .pop .r15, 0x1B0187),
  (0x1B0187, .pop .r14, 0x1B0189),
  (0x1B0189, .pop .r13, 0x1B018B),
  (0x1B018B, .pop .r12, 0x1B018D),
  (0x1B018D, .pop .rbp, 0x1B018E),
  (0x1B018E, .pop .rbx, 0x1B018F),
  (0x1B018F, .ret, 0x1B0190)
]

def pre0 : List (Nat × Instr × Nat) := KCode.table
def pre1 : List (Nat × Instr × Nat) := pre0 ++ Code_ladd.table
def pre2 : List (Nat × Instr × Nat) := pre1 ++ Code_addn.table
def pre3 : List (Nat × Instr × Nat) := pre2 ++ Code_pad.table
def pre4 : List (Nat × Instr × Nat) := pre3 ++ Code_chunk_node.table
def pre5 : List (Nat × Instr × Nat) := pre4 ++ Code_node_out.table
def pre6 : List (Nat × Instr × Nat) := pre5 ++ Code_fillp.table

/-- Every instruction of the program: the two kernels' (one/KCode.lean), `ladd`'s, `addn`'s, `pad`'s, `chunk_node`'s, `node_out`'s, `fillp`'s, then this function's. -/
def whole : List (Nat × Instr × Nat) := pre6 ++ table

def prog (ext : Nat → Option (Instr × Nat)) (pc : Nat) : Option (Instr × Nat) := (whole.lookup pc).or (ext pc)

/-- What this table holds, the program holds, whatever else it holds. -/
theorem prog_of (ext : Nat → Option (Instr × Nat)) : ∀ pc x, whole.lookup pc = some x → prog ext pc = some x := by
  intro pc x h; simp only [prog, h, Option.some_or]

theorem has_kernels (ext : Nat → Option (Instr × Nat)) : ∀ pc x, KCode.prog pc = some x → prog ext pc = some x := by
  intro pc x h
  exact prog_of ext pc x (lookup_append_left pre6 table pc x (lookup_append_left pre5 Code_fillp.table pc x (lookup_append_left pre4 Code_node_out.table pc x (lookup_append_left pre3 Code_chunk_node.table pc x (lookup_append_left pre2 Code_pad.table pc x (lookup_append_left pre1 Code_addn.table pc x (lookup_append_left pre0 Code_ladd.table pc x (h))))))))

/-- `ladd`'s own instructions are in this program: no table before them has one at any of their addresses. -/
theorem in1 (ext : Nat → Option (Instr × Nat)) : ∀ pc x, Code_ladd.table.lookup pc = some x → prog ext pc = some x := by
  intro pc x h
  have apart : ∀ p ∈ Code_ladd.table.map (·.1), ((pre0.lookup p).isNone) = true := by decide +kernel
  have none := Option.isNone_iff_eq_none.mp (apart pc (lookup_mem_keys _ pc x h))
  have here : pre1.lookup pc = some x := by
    show (pre0 ++ Code_ladd.table).lookup pc = some x
    rw [lookup_append_or, none]; exact h
  exact prog_of ext pc x (lookup_append_left pre6 table pc x (lookup_append_left pre5 Code_fillp.table pc x (lookup_append_left pre4 Code_node_out.table pc x (lookup_append_left pre3 Code_chunk_node.table pc x (lookup_append_left pre2 Code_pad.table pc x (lookup_append_left pre1 Code_addn.table pc x (here)))))))

/-- `addn`'s own instructions are in this program: no table before them has one at any of their addresses. -/
theorem in2 (ext : Nat → Option (Instr × Nat)) : ∀ pc x, Code_addn.table.lookup pc = some x → prog ext pc = some x := by
  intro pc x h
  have apart : ∀ p ∈ Code_addn.table.map (·.1), ((pre1.lookup p).isNone) = true := by decide +kernel
  have none := Option.isNone_iff_eq_none.mp (apart pc (lookup_mem_keys _ pc x h))
  have here : pre2.lookup pc = some x := by
    show (pre1 ++ Code_addn.table).lookup pc = some x
    rw [lookup_append_or, none]; exact h
  exact prog_of ext pc x (lookup_append_left pre6 table pc x (lookup_append_left pre5 Code_fillp.table pc x (lookup_append_left pre4 Code_node_out.table pc x (lookup_append_left pre3 Code_chunk_node.table pc x (lookup_append_left pre2 Code_pad.table pc x (here))))))

/-- `pad`'s own instructions are in this program: no table before them has one at any of their addresses. -/
theorem in3 (ext : Nat → Option (Instr × Nat)) : ∀ pc x, Code_pad.table.lookup pc = some x → prog ext pc = some x := by
  intro pc x h
  have apart : ∀ p ∈ Code_pad.table.map (·.1), ((pre2.lookup p).isNone) = true := by decide +kernel
  have none := Option.isNone_iff_eq_none.mp (apart pc (lookup_mem_keys _ pc x h))
  have here : pre3.lookup pc = some x := by
    show (pre2 ++ Code_pad.table).lookup pc = some x
    rw [lookup_append_or, none]; exact h
  exact prog_of ext pc x (lookup_append_left pre6 table pc x (lookup_append_left pre5 Code_fillp.table pc x (lookup_append_left pre4 Code_node_out.table pc x (lookup_append_left pre3 Code_chunk_node.table pc x (here)))))

/-- `chunk_node`'s own instructions are in this program: no table before them has one at any of their addresses. -/
theorem in4 (ext : Nat → Option (Instr × Nat)) : ∀ pc x, Code_chunk_node.table.lookup pc = some x → prog ext pc = some x := by
  intro pc x h
  have apart : ∀ p ∈ Code_chunk_node.table.map (·.1), ((pre3.lookup p).isNone) = true := by decide +kernel
  have none := Option.isNone_iff_eq_none.mp (apart pc (lookup_mem_keys _ pc x h))
  have here : pre4.lookup pc = some x := by
    show (pre3 ++ Code_chunk_node.table).lookup pc = some x
    rw [lookup_append_or, none]; exact h
  exact prog_of ext pc x (lookup_append_left pre6 table pc x (lookup_append_left pre5 Code_fillp.table pc x (lookup_append_left pre4 Code_node_out.table pc x (here))))

/-- `node_out`'s own instructions are in this program: no table before them has one at any of their addresses. -/
theorem in5 (ext : Nat → Option (Instr × Nat)) : ∀ pc x, Code_node_out.table.lookup pc = some x → prog ext pc = some x := by
  intro pc x h
  have apart : ∀ p ∈ Code_node_out.table.map (·.1), ((pre4.lookup p).isNone) = true := by decide +kernel
  have none := Option.isNone_iff_eq_none.mp (apart pc (lookup_mem_keys _ pc x h))
  have here : pre5.lookup pc = some x := by
    show (pre4 ++ Code_node_out.table).lookup pc = some x
    rw [lookup_append_or, none]; exact h
  exact prog_of ext pc x (lookup_append_left pre6 table pc x (lookup_append_left pre5 Code_fillp.table pc x (here)))

/-- `fillp`'s own instructions are in this program: no table before them has one at any of their addresses. -/
theorem in6 (ext : Nat → Option (Instr × Nat)) : ∀ pc x, Code_fillp.table.lookup pc = some x → prog ext pc = some x := by
  intro pc x h
  have apart : ∀ p ∈ Code_fillp.table.map (·.1), ((pre5.lookup p).isNone) = true := by decide +kernel
  have none := Option.isNone_iff_eq_none.mp (apart pc (lookup_mem_keys _ pc x h))
  have here : pre6.lookup pc = some x := by
    show (pre5 ++ Code_fillp.table).lookup pc = some x
    rw [lookup_append_or, none]; exact h
  exact prog_of ext pc x (lookup_append_left pre6 table pc x (here))

/-- The tables of `addn`'s program (its own instructions and those of what it calls) are in this one, unchanged. -/
theorem tables_addn (ext : Nat → Option (Instr × Nat)) : ∀ pc x, (KCode.table ++ Code_ladd.table ++ Code_addn.table).lookup pc = some x → prog ext pc = some x := by
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
      exact in1 ext pc y h1
    | none =>
      rw [h1] at h'; simp only [Option.none_or] at h'
      exact in2 ext pc x h'

/-- `addn`'s program (its own instructions and those of what it calls) is part of this one, unchanged. -/
theorem has_addn (ext : Nat → Option (Instr × Nat)) : ∀ pc x, Code_addn.prog pc = some x → prog ext pc = some x :=
  fun pc x h => tables_addn ext pc x h

/-- The tables of `chunk_node`'s program (its own instructions and those of what it calls) are in this one, unchanged. -/
theorem tables_chunk_node (ext : Nat → Option (Instr × Nat)) : ∀ pc x, (KCode.table ++ Code_pad.table ++ Code_chunk_node.table).lookup pc = some x → prog ext pc = some x := by
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
      exact in3 ext pc y h1
    | none =>
      rw [h1] at h'; simp only [Option.none_or] at h'
      exact in4 ext pc x h'

/-- `chunk_node`'s program (its own instructions and those of what it calls) is part of this one, unchanged. -/
theorem has_chunk_node (ext : Nat → Option (Instr × Nat)) : ∀ pc x, Code_chunk_node.prog pc = some x → prog ext pc = some x :=
  fun pc x h => tables_chunk_node ext pc x h

/-- The tables of `node_out`'s program (its own instructions and those of what it calls) are in this one, unchanged. -/
theorem tables_node_out (ext : Nat → Option (Instr × Nat)) : ∀ pc x, (KCode.table ++ Code_node_out.table).lookup pc = some x → prog ext pc = some x := by
  intro pc x h'
  simp only [lookup_append_or] at h'
  cases h0 : KCode.table.lookup pc with
  | some y =>
    rw [h0] at h'; simp only [Option.some_or, Option.some.injEq] at h'; subst h'
    exact has_kernels ext pc y h0
  | none =>
    rw [h0] at h'; simp only [Option.none_or] at h'
    exact in5 ext pc x h'

/-- `node_out`'s program (its own instructions and those of what it calls) is part of this one, unchanged. -/
theorem has_node_out (ext : Nat → Option (Instr × Nat)) : ∀ pc x, Code_node_out.prog pc = some x → prog ext pc = some x :=
  fun pc x h => tables_node_out ext pc x h

/-- The tables of `ladd`'s program (its own instructions and those of what it calls) are in this one, unchanged. -/
theorem tables_ladd (ext : Nat → Option (Instr × Nat)) : ∀ pc x, (KCode.table ++ Code_ladd.table).lookup pc = some x → prog ext pc = some x := by
  intro pc x h'
  simp only [lookup_append_or] at h'
  cases h0 : KCode.table.lookup pc with
  | some y =>
    rw [h0] at h'; simp only [Option.some_or, Option.some.injEq] at h'; subst h'
    exact has_kernels ext pc y h0
  | none =>
    rw [h0] at h'; simp only [Option.none_or] at h'
    exact in1 ext pc x h'

/-- `ladd`'s program (its own instructions and those of what it calls) is part of this one, unchanged. -/
theorem has_ladd (ext : Nat → Option (Instr × Nat)) : ∀ pc x, Code_ladd.prog pc = some x → prog ext pc = some x :=
  fun pc x h => tables_ladd ext pc x h

/-- The tables of `fillp`'s program (its own instructions and those of what it calls) are in this one, unchanged. -/
theorem tables_fillp (ext : Nat → Option (Instr × Nat)) : ∀ pc x, (Code_fillp.table).lookup pc = some x → prog ext pc = some x := by
  intro pc x h'
  exact in6 ext pc x h'

/-- `fillp`'s program (its own instructions and those of what it calls) is part of this one, unchanged. -/
theorem has_fillp (ext : Nat → Option (Instr × Nat)) : ∀ pc x, Code_fillp.prog pc = some x → prog ext pc = some x :=
  fun pc x h => tables_fillp ext pc x h

@[ode_at] theorem at_1B0000 (ext : Nat → Option (Instr × Nat)) : prog ext 0x1B0000 = some (.push .rbx, 0x1B0001) := rfl
@[ode_at] theorem at_1B0001 (ext : Nat → Option (Instr × Nat)) : prog ext 0x1B0001 = some (.push .rbp, 0x1B0002) := rfl
@[ode_at] theorem at_1B0002 (ext : Nat → Option (Instr × Nat)) : prog ext 0x1B0002 = some (.push .r12, 0x1B0004) := rfl
@[ode_at] theorem at_1B0004 (ext : Nat → Option (Instr × Nat)) : prog ext 0x1B0004 = some (.push .r13, 0x1B0006) := rfl
@[ode_at] theorem at_1B0006 (ext : Nat → Option (Instr × Nat)) : prog ext 0x1B0006 = some (.push .r14, 0x1B0008) := rfl
@[ode_at] theorem at_1B0008 (ext : Nat → Option (Instr × Nat)) : prog ext 0x1B0008 = some (.push .r15, 0x1B000A) := rfl
@[ode_at] theorem at_1B000A (ext : Nat → Option (Instr × Nat)) : prog ext 0x1B000A = some (.sub 64 (.reg .rsp) (.imm 0x5C8), 0x1B0011) := rfl
@[ode_at] theorem at_1B0011 (ext : Nat → Option (Instr × Nat)) : prog ext 0x1B0011 = some (.mov 64 (.reg .rbx) (.reg .rdi), 0x1B0014) := rfl
@[ode_at] theorem at_1B0014 (ext : Nat → Option (Instr × Nat)) : prog ext 0x1B0014 = some (.mov 64 (.reg .rbp) (.reg .rsi), 0x1B0017) := rfl
@[ode_at] theorem at_1B0017 (ext : Nat → Option (Instr × Nat)) : prog ext 0x1B0017 = some (.mov 64 (.reg .r12) (.reg .rdx), 0x1B001A) := rfl
@[ode_at] theorem at_1B001A (ext : Nat → Option (Instr × Nat)) : prog ext 0x1B001A = some (.mov 64 (.reg .r13) (.reg .rcx), 0x1B001D) := rfl
@[ode_at] theorem at_1B001D (ext : Nat → Option (Instr × Nat)) : prog ext 0x1B001D = some (.mov 64 (.reg .r14) (.reg .r8), 0x1B0020) := rfl
@[ode_at] theorem at_1B0020 (ext : Nat → Option (Instr × Nat)) : prog ext 0x1B0020 = some (.mov 64 (.reg .r15) (.reg .r9), 0x1B0023) := rfl
@[ode_at] theorem at_1B0023 (ext : Nat → Option (Instr × Nat)) : prog ext 0x1B0023 = some (.mov 64 (.reg .rax) (.reg .r14), 0x1B0026) := rfl
@[ode_at] theorem at_1B0026 (ext : Nat → Option (Instr × Nat)) : prog ext 0x1B0026 = some (.or 64 (.reg .rax) (.imm 0x40020100), 0x1B002C) := rfl
@[ode_at] theorem at_1B002C (ext : Nat → Option (Instr × Nat)) : prog ext 0x1B002C = some (.mov 64 (.mem .rsp 0x5A0) (.reg .rax), 0x1B0034) := rfl
@[ode_at] theorem at_1B0034 (ext : Nat → Option (Instr × Nat)) : prog ext 0x1B0034 = some (.mov 64 (.reg .rax) (.reg .r12), 0x1B0037) := rfl
@[ode_at] theorem at_1B0037 (ext : Nat → Option (Instr × Nat)) : prog ext 0x1B0037 = some (.sub 64 (.reg .rax) (.imm 0x1), 0x1B003B) := rfl
@[ode_at] theorem at_1B003B (ext : Nat → Option (Instr × Nat)) : prog ext 0x1B003B = some (.shr64 .rax 10, 0x1B003F) := rfl
@[ode_at] theorem at_1B003F (ext : Nat → Option (Instr × Nat)) : prog ext 0x1B003F = some (.mov 64 (.mem .rsp 0x5A8) (.reg .rax), 0x1B0047) := rfl
@[ode_at] theorem at_1B0047 (ext : Nat → Option (Instr × Nat)) : prog ext 0x1B0047 = some (.mov 64 (.reg .rax) (.reg .rbp), 0x1B004A) := rfl
@[ode_at] theorem at_1B004A (ext : Nat → Option (Instr × Nat)) : prog ext 0x1B004A = some (.mov 64 (.reg .rcx) (.mem .rsp 0x5A8), 0x1B0052) := rfl
@[ode_at] theorem at_1B0052 (ext : Nat → Option (Instr × Nat)) : prog ext 0x1B0052 = some (.shl64 .rcx 10, 0x1B0056) := rfl
@[ode_at] theorem at_1B0056 (ext : Nat → Option (Instr × Nat)) : prog ext 0x1B0056 = some (.add 64 (.reg .rax) (.reg .rcx), 0x1B0059) := rfl
@[ode_at] theorem at_1B0059 (ext : Nat → Option (Instr × Nat)) : prog ext 0x1B0059 = some (.mov 64 (.mem .rsp 0x5B0) (.reg .rax), 0x1B0061) := rfl
@[ode_at] theorem at_1B0061 (ext : Nat → Option (Instr × Nat)) : prog ext 0x1B0061 = some (.mov 64 (.reg .rax) (.reg .r12), 0x1B0064) := rfl
@[ode_at] theorem at_1B0064 (ext : Nat → Option (Instr × Nat)) : prog ext 0x1B0064 = some (.mov 64 (.reg .rcx) (.mem .rsp 0x5A8), 0x1B006C) := rfl
@[ode_at] theorem at_1B006C (ext : Nat → Option (Instr × Nat)) : prog ext 0x1B006C = some (.shl64 .rcx 10, 0x1B0070) := rfl
@[ode_at] theorem at_1B0070 (ext : Nat → Option (Instr × Nat)) : prog ext 0x1B0070 = some (.sub 64 (.reg .rax) (.reg .rcx), 0x1B0073) := rfl
@[ode_at] theorem at_1B0073 (ext : Nat → Option (Instr × Nat)) : prog ext 0x1B0073 = some (.mov 64 (.mem .rsp 0x5B8) (.reg .rax), 0x1B007B) := rfl
@[ode_at] theorem at_1B007B (ext : Nat → Option (Instr × Nat)) : prog ext 0x1B007B = some (.mov 64 (.reg .rax) (.reg .r15), 0x1B007E) := rfl
@[ode_at] theorem at_1B007E (ext : Nat → Option (Instr × Nat)) : prog ext 0x1B007E = some (.add 64 (.reg .rax) (.mem .rsp 0x5A8), 0x1B0086) := rfl
@[ode_at] theorem at_1B0086 (ext : Nat → Option (Instr × Nat)) : prog ext 0x1B0086 = some (.mov 64 (.mem .rsp 0x5C0) (.reg .rax), 0x1B008E) := rfl
@[ode_at] theorem at_1B008E (ext : Nat → Option (Instr × Nat)) : prog ext 0x1B008E = some (.lea .rdi .rsp 0xA0, 0x1B0096) := rfl
@[ode_at] theorem at_1B0096 (ext : Nat → Option (Instr × Nat)) : prog ext 0x1B0096 = some (.mov 64 (.reg .rsi) (.reg .rbp), 0x1B0099) := rfl
@[ode_at] theorem at_1B0099 (ext : Nat → Option (Instr × Nat)) : prog ext 0x1B0099 = some (.mov 64 (.reg .rdx) (.mem .rsp 0x5A8), 0x1B00A1) := rfl
@[ode_at] theorem at_1B00A1 (ext : Nat → Option (Instr × Nat)) : prog ext 0x1B00A1 = some (.mov 64 (.reg .rcx) (.imm 0x400), 0x1B00A8) := rfl
@[ode_at] theorem at_1B00A8 (ext : Nat → Option (Instr × Nat)) : prog ext 0x1B00A8 = some (.call 0x110000, 0x1B00AD) := rfl
@[ode_at] theorem at_1B00AD (ext : Nat → Option (Instr × Nat)) : prog ext 0x1B00AD = some (.lea .rdi .rsp 0xA0, 0x1B00B5) := rfl
@[ode_at] theorem at_1B00B5 (ext : Nat → Option (Instr × Nat)) : prog ext 0x1B00B5 = some (.mov 64 (.reg .rsi) (.imm 0x10), 0x1B00BC) := rfl
@[ode_at] theorem at_1B00BC (ext : Nat → Option (Instr × Nat)) : prog ext 0x1B00BC = some (.mov 64 (.reg .rdx) (.reg .r13), 0x1B00BF) := rfl
@[ode_at] theorem at_1B00BF (ext : Nat → Option (Instr × Nat)) : prog ext 0x1B00BF = some (.mov 64 (.reg .rcx) (.reg .r15), 0x1B00C2) := rfl
@[ode_at] theorem at_1B00C2 (ext : Nat → Option (Instr × Nat)) : prog ext 0x1B00C2 = some (.mov 64 (.reg .r8) (.mem .rsp 0x5A0), 0x1B00CA) := rfl
@[ode_at] theorem at_1B00CA (ext : Nat → Option (Instr × Nat)) : prog ext 0x1B00CA = some (.lea .r9 .rsp 0x1A0, 0x1B00D2) := rfl
@[ode_at] theorem at_1B00D2 (ext : Nat → Option (Instr × Nat)) : prog ext 0x1B00D2 = some (.call 0x10000, 0x1B00D7) := rfl
@[ode_at] theorem at_1B00D7 (ext : Nat → Option (Instr × Nat)) : prog ext 0x1B00D7 = some (.mov 64 (.reg .rax) (.imm 0x0), 0x1B00DE) := rfl
@[ode_at] theorem at_1B00DE (ext : Nat → Option (Instr × Nat)) : prog ext 0x1B00DE = some (.mov 64 (.reg .rcx) (.reg .rbx), 0x1B00E1) := rfl
@[ode_at] theorem at_1B00E1 (ext : Nat → Option (Instr × Nat)) : prog ext 0x1B00E1 = some (.mov 64 (.mem .rcx 0x0) (.reg .rax), 0x1B00E4) := rfl
@[ode_at] theorem at_1B00E4 (ext : Nat → Option (Instr × Nat)) : prog ext 0x1B00E4 = some (.mov 64 (.reg .rdi) (.reg .rbx), 0x1B00E7) := rfl
@[ode_at] theorem at_1B00E7 (ext : Nat → Option (Instr × Nat)) : prog ext 0x1B00E7 = some (.mov 64 (.reg .rsi) (.reg .r13), 0x1B00EA) := rfl
@[ode_at] theorem at_1B00EA (ext : Nat → Option (Instr × Nat)) : prog ext 0x1B00EA = some (.mov 64 (.reg .rdx) (.reg .r14), 0x1B00ED) := rfl
@[ode_at] theorem at_1B00ED (ext : Nat → Option (Instr × Nat)) : prog ext 0x1B00ED = some (.lea .rcx .rsp 0x1A0, 0x1B00F5) := rfl
@[ode_at] theorem at_1B00F5 (ext : Nat → Option (Instr × Nat)) : prog ext 0x1B00F5 = some (.mov 64 (.reg .r8) (.mem .rsp 0x5A8), 0x1B00FD) := rfl
@[ode_at] theorem at_1B00FD (ext : Nat → Option (Instr × Nat)) : prog ext 0x1B00FD = some (.call 0x160000, 0x1B0102) := rfl
@[ode_at] theorem at_1B0102 (ext : Nat → Option (Instr × Nat)) : prog ext 0x1B0102 = some (.mov 64 (.reg .rax) (.reg .r13), 0x1B0105) := rfl
@[ode_at] theorem at_1B0105 (ext : Nat → Option (Instr × Nat)) : prog ext 0x1B0105 = some (.lea .rcx .rsp 0x0, 0x1B0109) := rfl
@[ode_at] theorem at_1B0109 (ext : Nat → Option (Instr × Nat)) : prog ext 0x1B0109 = some (.movv false 0 (.m .rax 0x0), 0x1B010C) := rfl
@[ode_at] theorem at_1B010C (ext : Nat → Option (Instr × Nat)) : prog ext 0x1B010C = some (.storev false .rcx 0x0 0, 0x1B010F) := rfl
@[ode_at] theorem at_1B010F (ext : Nat → Option (Instr × Nat)) : prog ext 0x1B010F = some (.movv false 0 (.m .rax 0x10), 0x1B0113) := rfl
@[ode_at] theorem at_1B0113 (ext : Nat → Option (Instr × Nat)) : prog ext 0x1B0113 = some (.storev false .rcx 0x10 0, 0x1B0117) := rfl
@[ode_at] theorem at_1B0117 (ext : Nat → Option (Instr × Nat)) : prog ext 0x1B0117 = some (.lea .rdi .rsp 0x0, 0x1B011B) := rfl
@[ode_at] theorem at_1B011B (ext : Nat → Option (Instr × Nat)) : prog ext 0x1B011B = some (.mov 64 (.reg .rsi) (.mem .rsp 0x5B0), 0x1B0123) := rfl
@[ode_at] theorem at_1B0123 (ext : Nat → Option (Instr × Nat)) : prog ext 0x1B0123 = some (.mov 64 (.reg .rdx) (.mem .rsp 0x5B8), 0x1B012B) := rfl
@[ode_at] theorem at_1B012B (ext : Nat → Option (Instr × Nat)) : prog ext 0x1B012B = some (.mov 64 (.reg .rcx) (.mem .rsp 0x5C0), 0x1B0133) := rfl
@[ode_at] theorem at_1B0133 (ext : Nat → Option (Instr × Nat)) : prog ext 0x1B0133 = some (.mov 64 (.reg .r8) (.reg .r14), 0x1B0136) := rfl
@[ode_at] theorem at_1B0136 (ext : Nat → Option (Instr × Nat)) : prog ext 0x1B0136 = some (.mov 64 (.reg .r9) (.imm 0x5), 0x1B013D) := rfl
@[ode_at] theorem at_1B013D (ext : Nat → Option (Instr × Nat)) : prog ext 0x1B013D = some (.call 0xF0000, 0x1B0142) := rfl
@[ode_at] theorem at_1B0142 (ext : Nat → Option (Instr × Nat)) : prog ext 0x1B0142 = some (.lea .rdi .rsp 0x80, 0x1B014A) := rfl
@[ode_at] theorem at_1B014A (ext : Nat → Option (Instr × Nat)) : prog ext 0x1B014A = some (.lea .rsi .rsp 0x0, 0x1B014E) := rfl
@[ode_at] theorem at_1B014E (ext : Nat → Option (Instr × Nat)) : prog ext 0x1B014E = some (.mov 64 (.reg .rdx) (.imm 0x0), 0x1B0155) := rfl
@[ode_at] theorem at_1B0155 (ext : Nat → Option (Instr × Nat)) : prog ext 0x1B0155 = some (.mov 64 (.reg .rcx) (.imm 0x5), 0x1B015C) := rfl
@[ode_at] theorem at_1B015C (ext : Nat → Option (Instr × Nat)) : prog ext 0x1B015C = some (.call 0xD0000, 0x1B0161) := rfl
@[ode_at] theorem at_1B0161 (ext : Nat → Option (Instr × Nat)) : prog ext 0x1B0161 = some (.mov 64 (.reg .rdi) (.reg .rbx), 0x1B0164) := rfl
@[ode_at] theorem at_1B0164 (ext : Nat → Option (Instr × Nat)) : prog ext 0x1B0164 = some (.mov 64 (.reg .rsi) (.reg .r13), 0x1B0167) := rfl
@[ode_at] theorem at_1B0167 (ext : Nat → Option (Instr × Nat)) : prog ext 0x1B0167 = some (.mov 64 (.reg .rdx) (.reg .r14), 0x1B016A) := rfl
@[ode_at] theorem at_1B016A (ext : Nat → Option (Instr × Nat)) : prog ext 0x1B016A = some (.mov 64 (.reg .rcx) (.imm 0x5), 0x1B0171) := rfl
@[ode_at] theorem at_1B0171 (ext : Nat → Option (Instr × Nat)) : prog ext 0x1B0171 = some (.lea .r8 .rsp 0x80, 0x1B0179) := rfl
@[ode_at] theorem at_1B0179 (ext : Nat → Option (Instr × Nat)) : prog ext 0x1B0179 = some (.call 0xB0000, 0x1B017E) := rfl
@[ode_at] theorem at_1B017E (ext : Nat → Option (Instr × Nat)) : prog ext 0x1B017E = some (.add 64 (.reg .rsp) (.imm 0x5C8), 0x1B0185) := rfl
@[ode_at] theorem at_1B0185 (ext : Nat → Option (Instr × Nat)) : prog ext 0x1B0185 = some (.pop .r15, 0x1B0187) := rfl
@[ode_at] theorem at_1B0187 (ext : Nat → Option (Instr × Nat)) : prog ext 0x1B0187 = some (.pop .r14, 0x1B0189) := rfl
@[ode_at] theorem at_1B0189 (ext : Nat → Option (Instr × Nat)) : prog ext 0x1B0189 = some (.pop .r13, 0x1B018B) := rfl
@[ode_at] theorem at_1B018B (ext : Nat → Option (Instr × Nat)) : prog ext 0x1B018B = some (.pop .r12, 0x1B018D) := rfl
@[ode_at] theorem at_1B018D (ext : Nat → Option (Instr × Nat)) : prog ext 0x1B018D = some (.pop .rbp, 0x1B018E) := rfl
@[ode_at] theorem at_1B018E (ext : Nat → Option (Instr × Nat)) : prog ext 0x1B018E = some (.pop .rbx, 0x1B018F) := rfl
@[ode_at] theorem at_1B018F (ext : Nat → Option (Instr × Nat)) : prog ext 0x1B018F = some (.ret, 0x1B0190) := rfl

end Code_groupf
