import Machine
import KCode
import Cells
import Code_pad
import Code_chunk_node
import Code_node_out
import Code_ladd
open X86

/-! `group` as assembled: 98 instructions. Written from the lifter's rows. -/

set_option maxRecDepth 100000
namespace Code_group

def table : List (Nat × Instr × Nat) := [
  (0x180000, .push .rbx, 0x180001),
  (0x180001, .push .rbp, 0x180002),
  (0x180002, .push .r12, 0x180004),
  (0x180004, .push .r13, 0x180006),
  (0x180006, .push .r14, 0x180008),
  (0x180008, .push .r15, 0x18000A),
  (0x18000A, .sub 64 (.reg .rsp) (.imm 0xC8), 0x180011),
  (0x180011, .mov 64 (.reg .r15) (.reg .rdi), 0x180014),
  (0x180014, .mov 64 (.mem .rsp 0xA0) (.reg .rsi), 0x18001C),
  (0x18001C, .mov 64 (.mem .rsp 0xA8) (.reg .rdx), 0x180024),
  (0x180024, .mov 64 (.reg .r13) (.reg .rcx), 0x180027),
  (0x180027, .mov 64 (.reg .r14) (.reg .r8), 0x18002A),
  (0x18002A, .mov 64 (.mem .rsp 0xB0) (.reg .r9), 0x180032),
  (0x180032, .mov 64 (.reg .rax) (.imm 0x0), 0x180039),
  (0x180039, .mov 64 (.reg .rcx) (.reg .r15), 0x18003C),
  (0x18003C, .mov 64 (.mem .rcx 0x0) (.reg .rax), 0x18003F),
  (0x18003F, .mov 64 (.reg .rax) (.mem .rsp 0xA0), 0x180047),
  (0x180047, .mov 64 (.reg .rbx) (.reg .rax), 0x18004A),
  (0x18004A, .mov 64 (.reg .rax) (.mem .rsp 0xA8), 0x180052),
  (0x180052, .mov 64 (.reg .rbp) (.reg .rax), 0x180055),
  (0x180055, .mov 64 (.reg .rax) (.imm 0x0), 0x18005C),
  (0x18005C, .mov 64 (.reg .r12) (.reg .rax), 0x18005F),
  (0x18005F, .mov 64 (.reg .rax) (.imm 0x400), 0x180066),
  (0x180066, .mov 64 (.reg .rcx) (.reg .rbp), 0x180069),
  (0x180069, .cmp 64 (.reg .rax) (.reg .rcx), 0x18006C),
  (0x18006C, .jae 0x180122, 0x180072),
  (0x180072, .mov 64 (.reg .rax) (.mem .rsp 0xB0), 0x18007A),
  (0x18007A, .add 64 (.reg .rax) (.reg .r12), 0x18007D),
  (0x18007D, .mov 64 (.mem .rsp 0xB8) (.reg .rax), 0x180085),
  (0x180085, .mov 64 (.reg .rax) (.reg .r13), 0x180088),
  (0x180088, .lea .rcx .rsp 0x0, 0x18008C),
  (0x18008C, .movv false 0 (.m .rax 0x0), 0x18008F),
  (0x18008F, .storev false .rcx 0x0 0, 0x180092),
  (0x180092, .movv false 0 (.m .rax 0x10), 0x180096),
  (0x180096, .storev false .rcx 0x10 0, 0x18009A),
  (0x18009A, .lea .rdi .rsp 0x0, 0x18009E),
  (0x18009E, .mov 64 (.reg .rsi) (.reg .rbx), 0x1800A1),
  (0x1800A1, .mov 64 (.reg .rdx) (.imm 0x400), 0x1800A8),
  (0x1800A8, .mov 64 (.reg .rcx) (.mem .rsp 0xB8), 0x1800B0),
  (0x1800B0, .mov 64 (.reg .r8) (.reg .r14), 0x1800B3),
  (0x1800B3, .mov 64 (.reg .r9) (.imm 0x5), 0x1800BA),
  (0x1800BA, .call 0xF0000, 0x1800BF),
  (0x1800BF, .lea .rdi .rsp 0x80, 0x1800C7),
  (0x1800C7, .lea .rsi .rsp 0x0, 0x1800CB),
  (0x1800CB, .mov 64 (.reg .rdx) (.imm 0x0), 0x1800D2),
  (0x1800D2, .mov 64 (.reg .rcx) (.imm 0x5), 0x1800D9),
  (0x1800D9, .call 0xD0000, 0x1800DE),
  (0x1800DE, .mov 64 (.reg .rdi) (.reg .r15), 0x1800E1),
  (0x1800E1, .mov 64 (.reg .rsi) (.reg .r13), 0x1800E4),
  (0x1800E4, .mov 64 (.reg .rdx) (.reg .r14), 0x1800E7),
  (0x1800E7, .mov 64 (.reg .rcx) (.imm 0x5), 0x1800EE),
  (0x1800EE, .lea .r8 .rsp 0x80, 0x1800F6),
  (0x1800F6, .call 0xB0000, 0x1800FB),
  (0x1800FB, .mov 64 (.reg .rax) (.reg .rbx), 0x1800FE),
  (0x1800FE, .add 64 (.reg .rax) (.imm 0x400), 0x180104),
  (0x180104, .mov 64 (.reg .rbx) (.reg .rax), 0x180107),
  (0x180107, .mov 64 (.reg .rax) (.reg .rbp), 0x18010A),
  (0x18010A, .sub 64 (.reg .rax) (.imm 0x400), 0x180110),
  (0x180110, .mov 64 (.reg .rbp) (.reg .rax), 0x180113),
  (0x180113, .mov 64 (.reg .rax) (.reg .r12), 0x180116),
  (0x180116, .add 64 (.reg .rax) (.imm 0x1), 0x18011A),
  (0x18011A, .mov 64 (.reg .r12) (.reg .rax), 0x18011D),
  (0x18011D, .jmp 0x18005F, 0x180122),
  (0x180122, .mov 64 (.reg .rax) (.mem .rsp 0xB0), 0x18012A),
  (0x18012A, .add 64 (.reg .rax) (.reg .r12), 0x18012D),
  (0x18012D, .mov 64 (.mem .rsp 0xC0) (.reg .rax), 0x180135),
  (0x180135, .mov 64 (.reg .rax) (.reg .r13), 0x180138),
  (0x180138, .lea .rcx .rsp 0x0, 0x18013C),
  (0x18013C, .movv false 0 (.m .rax 0x0), 0x18013F),
  (0x18013F, .storev false .rcx 0x0 0, 0x180142),
  (0x180142, .movv false 0 (.m .rax 0x10), 0x180146),
  (0x180146, .storev false .rcx 0x10 0, 0x18014A),
  (0x18014A, .lea .rdi .rsp 0x0, 0x18014E),
  (0x18014E, .mov 64 (.reg .rsi) (.reg .rbx), 0x180151),
  (0x180151, .mov 64 (.reg .rdx) (.reg .rbp), 0x180154),
  (0x180154, .mov 64 (.reg .rcx) (.mem .rsp 0xC0), 0x18015C),
  (0x18015C, .mov 64 (.reg .r8) (.reg .r14), 0x18015F),
  (0x18015F, .mov 64 (.reg .r9) (.imm 0x5), 0x180166),
  (0x180166, .call 0xF0000, 0x18016B),
  (0x18016B, .lea .rdi .rsp 0x80, 0x180173),
  (0x180173, .lea .rsi .rsp 0x0, 0x180177),
  (0x180177, .mov 64 (.reg .rdx) (.imm 0x0), 0x18017E),
  (0x18017E, .mov 64 (.reg .rcx) (.imm 0x5), 0x180185),
  (0x180185, .call 0xD0000, 0x18018A),
  (0x18018A, .mov 64 (.reg .rdi) (.reg .r15), 0x18018D),
  (0x18018D, .mov 64 (.reg .rsi) (.reg .r13), 0x180190),
  (0x180190, .mov 64 (.reg .rdx) (.reg .r14), 0x180193),
  (0x180193, .mov 64 (.reg .rcx) (.imm 0x5), 0x18019A),
  (0x18019A, .lea .r8 .rsp 0x80, 0x1801A2),
  (0x1801A2, .call 0xB0000, 0x1801A7),
  (0x1801A7, .add 64 (.reg .rsp) (.imm 0xC8), 0x1801AE),
  (0x1801AE, .pop .r15, 0x1801B0),
  (0x1801B0, .pop .r14, 0x1801B2),
  (0x1801B2, .pop .r13, 0x1801B4),
  (0x1801B4, .pop .r12, 0x1801B6),
  (0x1801B6, .pop .rbp, 0x1801B7),
  (0x1801B7, .pop .rbx, 0x1801B8),
  (0x1801B8, .ret, 0x1801B9)
]

def pre0 : List (Nat × Instr × Nat) := KCode.table
def pre1 : List (Nat × Instr × Nat) := pre0 ++ Code_pad.table
def pre2 : List (Nat × Instr × Nat) := pre1 ++ Code_chunk_node.table
def pre3 : List (Nat × Instr × Nat) := pre2 ++ Code_node_out.table
def pre4 : List (Nat × Instr × Nat) := pre3 ++ Code_ladd.table

/-- Every instruction of the program: the two kernels' (one/KCode.lean), `pad`'s, `chunk_node`'s, `node_out`'s, `ladd`'s, then this function's. -/
def whole : List (Nat × Instr × Nat) := pre4 ++ table

def prog (pc : Nat) : Option (Instr × Nat) := whole.lookup pc

/-- The addresses the program has an instruction at. -/
def keys : List Nat := whole.map (·.1)

theorem keys_of : ∀ pc x, prog pc = some x → pc ∈ keys := fun pc x h => lookup_mem_keys whole pc x h

theorem has_kernels : ∀ pc x, KCode.prog pc = some x → prog pc = some x := by
  intro pc x h
  exact lookup_append_left pre4 table pc x (lookup_append_left pre3 Code_ladd.table pc x (lookup_append_left pre2 Code_node_out.table pc x (lookup_append_left pre1 Code_chunk_node.table pc x (lookup_append_left pre0 Code_pad.table pc x (h)))))

/-- `pad`'s own instructions are in this program: no table before them has one at any of their addresses. -/
theorem in1 : ∀ pc x, Code_pad.table.lookup pc = some x → prog pc = some x := by
  intro pc x h
  have apart : ∀ p ∈ Code_pad.table.map (·.1), ((pre0.lookup p).isNone) = true := by decide +kernel
  have none := Option.isNone_iff_eq_none.mp (apart pc (lookup_mem_keys _ pc x h))
  have here : pre1.lookup pc = some x := by
    show (pre0 ++ Code_pad.table).lookup pc = some x
    rw [lookup_append_or, none]; exact h
  exact lookup_append_left pre4 table pc x (lookup_append_left pre3 Code_ladd.table pc x (lookup_append_left pre2 Code_node_out.table pc x (lookup_append_left pre1 Code_chunk_node.table pc x (here))))

/-- `chunk_node`'s own instructions are in this program: no table before them has one at any of their addresses. -/
theorem in2 : ∀ pc x, Code_chunk_node.table.lookup pc = some x → prog pc = some x := by
  intro pc x h
  have apart : ∀ p ∈ Code_chunk_node.table.map (·.1), ((pre1.lookup p).isNone) = true := by decide +kernel
  have none := Option.isNone_iff_eq_none.mp (apart pc (lookup_mem_keys _ pc x h))
  have here : pre2.lookup pc = some x := by
    show (pre1 ++ Code_chunk_node.table).lookup pc = some x
    rw [lookup_append_or, none]; exact h
  exact lookup_append_left pre4 table pc x (lookup_append_left pre3 Code_ladd.table pc x (lookup_append_left pre2 Code_node_out.table pc x (here)))

/-- `node_out`'s own instructions are in this program: no table before them has one at any of their addresses. -/
theorem in3 : ∀ pc x, Code_node_out.table.lookup pc = some x → prog pc = some x := by
  intro pc x h
  have apart : ∀ p ∈ Code_node_out.table.map (·.1), ((pre2.lookup p).isNone) = true := by decide +kernel
  have none := Option.isNone_iff_eq_none.mp (apart pc (lookup_mem_keys _ pc x h))
  have here : pre3.lookup pc = some x := by
    show (pre2 ++ Code_node_out.table).lookup pc = some x
    rw [lookup_append_or, none]; exact h
  exact lookup_append_left pre4 table pc x (lookup_append_left pre3 Code_ladd.table pc x (here))

/-- `ladd`'s own instructions are in this program: no table before them has one at any of their addresses. -/
theorem in4 : ∀ pc x, Code_ladd.table.lookup pc = some x → prog pc = some x := by
  intro pc x h
  have apart : ∀ p ∈ Code_ladd.table.map (·.1), ((pre3.lookup p).isNone) = true := by decide +kernel
  have none := Option.isNone_iff_eq_none.mp (apart pc (lookup_mem_keys _ pc x h))
  have here : pre4.lookup pc = some x := by
    show (pre3 ++ Code_ladd.table).lookup pc = some x
    rw [lookup_append_or, none]; exact h
  exact lookup_append_left pre4 table pc x (here)

/-- `chunk_node`'s program (its own instructions and those of what it calls) is part of this one, unchanged. -/
theorem has_chunk_node : ∀ pc x, Code_chunk_node.prog pc = some x → prog pc = some x := by
  intro pc x h
  have h' : (KCode.table ++ Code_pad.table ++ Code_chunk_node.table).lookup pc = some x := h
  simp only [lookup_append_or] at h'
  cases h0 : KCode.table.lookup pc with
  | some y =>
    rw [h0] at h'; simp only [Option.some_or, Option.some.injEq] at h'; subst h'
    exact has_kernels pc y h0
  | none =>
    rw [h0] at h'; simp only [Option.none_or] at h'
    cases h1 : Code_pad.table.lookup pc with
    | some y =>
      rw [h1] at h'; simp only [Option.some_or, Option.some.injEq] at h'; subst h'
      exact in1 pc y h1
    | none =>
      rw [h1] at h'; simp only [Option.none_or] at h'
      exact in2 pc x h'

/-- `node_out`'s program (its own instructions and those of what it calls) is part of this one, unchanged. -/
theorem has_node_out : ∀ pc x, Code_node_out.prog pc = some x → prog pc = some x := by
  intro pc x h
  have h' : (KCode.table ++ Code_node_out.table).lookup pc = some x := h
  simp only [lookup_append_or] at h'
  cases h0 : KCode.table.lookup pc with
  | some y =>
    rw [h0] at h'; simp only [Option.some_or, Option.some.injEq] at h'; subst h'
    exact has_kernels pc y h0
  | none =>
    rw [h0] at h'; simp only [Option.none_or] at h'
    exact in3 pc x h'

/-- `ladd`'s program (its own instructions and those of what it calls) is part of this one, unchanged. -/
theorem has_ladd : ∀ pc x, Code_ladd.prog pc = some x → prog pc = some x := by
  intro pc x h
  have h' : (KCode.table ++ Code_ladd.table).lookup pc = some x := h
  simp only [lookup_append_or] at h'
  cases h0 : KCode.table.lookup pc with
  | some y =>
    rw [h0] at h'; simp only [Option.some_or, Option.some.injEq] at h'; subst h'
    exact has_kernels pc y h0
  | none =>
    rw [h0] at h'; simp only [Option.none_or] at h'
    exact in4 pc x h'

@[ode_at] theorem at_180000 : prog 0x180000 = some (.push .rbx, 0x180001) := rfl
@[ode_at] theorem at_180001 : prog 0x180001 = some (.push .rbp, 0x180002) := rfl
@[ode_at] theorem at_180002 : prog 0x180002 = some (.push .r12, 0x180004) := rfl
@[ode_at] theorem at_180004 : prog 0x180004 = some (.push .r13, 0x180006) := rfl
@[ode_at] theorem at_180006 : prog 0x180006 = some (.push .r14, 0x180008) := rfl
@[ode_at] theorem at_180008 : prog 0x180008 = some (.push .r15, 0x18000A) := rfl
@[ode_at] theorem at_18000A : prog 0x18000A = some (.sub 64 (.reg .rsp) (.imm 0xC8), 0x180011) := rfl
@[ode_at] theorem at_180011 : prog 0x180011 = some (.mov 64 (.reg .r15) (.reg .rdi), 0x180014) := rfl
@[ode_at] theorem at_180014 : prog 0x180014 = some (.mov 64 (.mem .rsp 0xA0) (.reg .rsi), 0x18001C) := rfl
@[ode_at] theorem at_18001C : prog 0x18001C = some (.mov 64 (.mem .rsp 0xA8) (.reg .rdx), 0x180024) := rfl
@[ode_at] theorem at_180024 : prog 0x180024 = some (.mov 64 (.reg .r13) (.reg .rcx), 0x180027) := rfl
@[ode_at] theorem at_180027 : prog 0x180027 = some (.mov 64 (.reg .r14) (.reg .r8), 0x18002A) := rfl
@[ode_at] theorem at_18002A : prog 0x18002A = some (.mov 64 (.mem .rsp 0xB0) (.reg .r9), 0x180032) := rfl
@[ode_at] theorem at_180032 : prog 0x180032 = some (.mov 64 (.reg .rax) (.imm 0x0), 0x180039) := rfl
@[ode_at] theorem at_180039 : prog 0x180039 = some (.mov 64 (.reg .rcx) (.reg .r15), 0x18003C) := rfl
@[ode_at] theorem at_18003C : prog 0x18003C = some (.mov 64 (.mem .rcx 0x0) (.reg .rax), 0x18003F) := rfl
@[ode_at] theorem at_18003F : prog 0x18003F = some (.mov 64 (.reg .rax) (.mem .rsp 0xA0), 0x180047) := rfl
@[ode_at] theorem at_180047 : prog 0x180047 = some (.mov 64 (.reg .rbx) (.reg .rax), 0x18004A) := rfl
@[ode_at] theorem at_18004A : prog 0x18004A = some (.mov 64 (.reg .rax) (.mem .rsp 0xA8), 0x180052) := rfl
@[ode_at] theorem at_180052 : prog 0x180052 = some (.mov 64 (.reg .rbp) (.reg .rax), 0x180055) := rfl
@[ode_at] theorem at_180055 : prog 0x180055 = some (.mov 64 (.reg .rax) (.imm 0x0), 0x18005C) := rfl
@[ode_at] theorem at_18005C : prog 0x18005C = some (.mov 64 (.reg .r12) (.reg .rax), 0x18005F) := rfl
@[ode_at] theorem at_18005F : prog 0x18005F = some (.mov 64 (.reg .rax) (.imm 0x400), 0x180066) := rfl
@[ode_at] theorem at_180066 : prog 0x180066 = some (.mov 64 (.reg .rcx) (.reg .rbp), 0x180069) := rfl
@[ode_at] theorem at_180069 : prog 0x180069 = some (.cmp 64 (.reg .rax) (.reg .rcx), 0x18006C) := rfl
@[ode_at] theorem at_18006C : prog 0x18006C = some (.jae 0x180122, 0x180072) := rfl
@[ode_at] theorem at_180072 : prog 0x180072 = some (.mov 64 (.reg .rax) (.mem .rsp 0xB0), 0x18007A) := rfl
@[ode_at] theorem at_18007A : prog 0x18007A = some (.add 64 (.reg .rax) (.reg .r12), 0x18007D) := rfl
@[ode_at] theorem at_18007D : prog 0x18007D = some (.mov 64 (.mem .rsp 0xB8) (.reg .rax), 0x180085) := rfl
@[ode_at] theorem at_180085 : prog 0x180085 = some (.mov 64 (.reg .rax) (.reg .r13), 0x180088) := rfl
@[ode_at] theorem at_180088 : prog 0x180088 = some (.lea .rcx .rsp 0x0, 0x18008C) := rfl
@[ode_at] theorem at_18008C : prog 0x18008C = some (.movv false 0 (.m .rax 0x0), 0x18008F) := rfl
@[ode_at] theorem at_18008F : prog 0x18008F = some (.storev false .rcx 0x0 0, 0x180092) := rfl
@[ode_at] theorem at_180092 : prog 0x180092 = some (.movv false 0 (.m .rax 0x10), 0x180096) := rfl
@[ode_at] theorem at_180096 : prog 0x180096 = some (.storev false .rcx 0x10 0, 0x18009A) := rfl
@[ode_at] theorem at_18009A : prog 0x18009A = some (.lea .rdi .rsp 0x0, 0x18009E) := rfl
@[ode_at] theorem at_18009E : prog 0x18009E = some (.mov 64 (.reg .rsi) (.reg .rbx), 0x1800A1) := rfl
@[ode_at] theorem at_1800A1 : prog 0x1800A1 = some (.mov 64 (.reg .rdx) (.imm 0x400), 0x1800A8) := rfl
@[ode_at] theorem at_1800A8 : prog 0x1800A8 = some (.mov 64 (.reg .rcx) (.mem .rsp 0xB8), 0x1800B0) := rfl
@[ode_at] theorem at_1800B0 : prog 0x1800B0 = some (.mov 64 (.reg .r8) (.reg .r14), 0x1800B3) := rfl
@[ode_at] theorem at_1800B3 : prog 0x1800B3 = some (.mov 64 (.reg .r9) (.imm 0x5), 0x1800BA) := rfl
@[ode_at] theorem at_1800BA : prog 0x1800BA = some (.call 0xF0000, 0x1800BF) := rfl
@[ode_at] theorem at_1800BF : prog 0x1800BF = some (.lea .rdi .rsp 0x80, 0x1800C7) := rfl
@[ode_at] theorem at_1800C7 : prog 0x1800C7 = some (.lea .rsi .rsp 0x0, 0x1800CB) := rfl
@[ode_at] theorem at_1800CB : prog 0x1800CB = some (.mov 64 (.reg .rdx) (.imm 0x0), 0x1800D2) := rfl
@[ode_at] theorem at_1800D2 : prog 0x1800D2 = some (.mov 64 (.reg .rcx) (.imm 0x5), 0x1800D9) := rfl
@[ode_at] theorem at_1800D9 : prog 0x1800D9 = some (.call 0xD0000, 0x1800DE) := rfl
@[ode_at] theorem at_1800DE : prog 0x1800DE = some (.mov 64 (.reg .rdi) (.reg .r15), 0x1800E1) := rfl
@[ode_at] theorem at_1800E1 : prog 0x1800E1 = some (.mov 64 (.reg .rsi) (.reg .r13), 0x1800E4) := rfl
@[ode_at] theorem at_1800E4 : prog 0x1800E4 = some (.mov 64 (.reg .rdx) (.reg .r14), 0x1800E7) := rfl
@[ode_at] theorem at_1800E7 : prog 0x1800E7 = some (.mov 64 (.reg .rcx) (.imm 0x5), 0x1800EE) := rfl
@[ode_at] theorem at_1800EE : prog 0x1800EE = some (.lea .r8 .rsp 0x80, 0x1800F6) := rfl
@[ode_at] theorem at_1800F6 : prog 0x1800F6 = some (.call 0xB0000, 0x1800FB) := rfl
@[ode_at] theorem at_1800FB : prog 0x1800FB = some (.mov 64 (.reg .rax) (.reg .rbx), 0x1800FE) := rfl
@[ode_at] theorem at_1800FE : prog 0x1800FE = some (.add 64 (.reg .rax) (.imm 0x400), 0x180104) := rfl
@[ode_at] theorem at_180104 : prog 0x180104 = some (.mov 64 (.reg .rbx) (.reg .rax), 0x180107) := rfl
@[ode_at] theorem at_180107 : prog 0x180107 = some (.mov 64 (.reg .rax) (.reg .rbp), 0x18010A) := rfl
@[ode_at] theorem at_18010A : prog 0x18010A = some (.sub 64 (.reg .rax) (.imm 0x400), 0x180110) := rfl
@[ode_at] theorem at_180110 : prog 0x180110 = some (.mov 64 (.reg .rbp) (.reg .rax), 0x180113) := rfl
@[ode_at] theorem at_180113 : prog 0x180113 = some (.mov 64 (.reg .rax) (.reg .r12), 0x180116) := rfl
@[ode_at] theorem at_180116 : prog 0x180116 = some (.add 64 (.reg .rax) (.imm 0x1), 0x18011A) := rfl
@[ode_at] theorem at_18011A : prog 0x18011A = some (.mov 64 (.reg .r12) (.reg .rax), 0x18011D) := rfl
@[ode_at] theorem at_18011D : prog 0x18011D = some (.jmp 0x18005F, 0x180122) := rfl
@[ode_at] theorem at_180122 : prog 0x180122 = some (.mov 64 (.reg .rax) (.mem .rsp 0xB0), 0x18012A) := rfl
@[ode_at] theorem at_18012A : prog 0x18012A = some (.add 64 (.reg .rax) (.reg .r12), 0x18012D) := rfl
@[ode_at] theorem at_18012D : prog 0x18012D = some (.mov 64 (.mem .rsp 0xC0) (.reg .rax), 0x180135) := rfl
@[ode_at] theorem at_180135 : prog 0x180135 = some (.mov 64 (.reg .rax) (.reg .r13), 0x180138) := rfl
@[ode_at] theorem at_180138 : prog 0x180138 = some (.lea .rcx .rsp 0x0, 0x18013C) := rfl
@[ode_at] theorem at_18013C : prog 0x18013C = some (.movv false 0 (.m .rax 0x0), 0x18013F) := rfl
@[ode_at] theorem at_18013F : prog 0x18013F = some (.storev false .rcx 0x0 0, 0x180142) := rfl
@[ode_at] theorem at_180142 : prog 0x180142 = some (.movv false 0 (.m .rax 0x10), 0x180146) := rfl
@[ode_at] theorem at_180146 : prog 0x180146 = some (.storev false .rcx 0x10 0, 0x18014A) := rfl
@[ode_at] theorem at_18014A : prog 0x18014A = some (.lea .rdi .rsp 0x0, 0x18014E) := rfl
@[ode_at] theorem at_18014E : prog 0x18014E = some (.mov 64 (.reg .rsi) (.reg .rbx), 0x180151) := rfl
@[ode_at] theorem at_180151 : prog 0x180151 = some (.mov 64 (.reg .rdx) (.reg .rbp), 0x180154) := rfl
@[ode_at] theorem at_180154 : prog 0x180154 = some (.mov 64 (.reg .rcx) (.mem .rsp 0xC0), 0x18015C) := rfl
@[ode_at] theorem at_18015C : prog 0x18015C = some (.mov 64 (.reg .r8) (.reg .r14), 0x18015F) := rfl
@[ode_at] theorem at_18015F : prog 0x18015F = some (.mov 64 (.reg .r9) (.imm 0x5), 0x180166) := rfl
@[ode_at] theorem at_180166 : prog 0x180166 = some (.call 0xF0000, 0x18016B) := rfl
@[ode_at] theorem at_18016B : prog 0x18016B = some (.lea .rdi .rsp 0x80, 0x180173) := rfl
@[ode_at] theorem at_180173 : prog 0x180173 = some (.lea .rsi .rsp 0x0, 0x180177) := rfl
@[ode_at] theorem at_180177 : prog 0x180177 = some (.mov 64 (.reg .rdx) (.imm 0x0), 0x18017E) := rfl
@[ode_at] theorem at_18017E : prog 0x18017E = some (.mov 64 (.reg .rcx) (.imm 0x5), 0x180185) := rfl
@[ode_at] theorem at_180185 : prog 0x180185 = some (.call 0xD0000, 0x18018A) := rfl
@[ode_at] theorem at_18018A : prog 0x18018A = some (.mov 64 (.reg .rdi) (.reg .r15), 0x18018D) := rfl
@[ode_at] theorem at_18018D : prog 0x18018D = some (.mov 64 (.reg .rsi) (.reg .r13), 0x180190) := rfl
@[ode_at] theorem at_180190 : prog 0x180190 = some (.mov 64 (.reg .rdx) (.reg .r14), 0x180193) := rfl
@[ode_at] theorem at_180193 : prog 0x180193 = some (.mov 64 (.reg .rcx) (.imm 0x5), 0x18019A) := rfl
@[ode_at] theorem at_18019A : prog 0x18019A = some (.lea .r8 .rsp 0x80, 0x1801A2) := rfl
@[ode_at] theorem at_1801A2 : prog 0x1801A2 = some (.call 0xB0000, 0x1801A7) := rfl
@[ode_at] theorem at_1801A7 : prog 0x1801A7 = some (.add 64 (.reg .rsp) (.imm 0xC8), 0x1801AE) := rfl
@[ode_at] theorem at_1801AE : prog 0x1801AE = some (.pop .r15, 0x1801B0) := rfl
@[ode_at] theorem at_1801B0 : prog 0x1801B0 = some (.pop .r14, 0x1801B2) := rfl
@[ode_at] theorem at_1801B2 : prog 0x1801B2 = some (.pop .r13, 0x1801B4) := rfl
@[ode_at] theorem at_1801B4 : prog 0x1801B4 = some (.pop .r12, 0x1801B6) := rfl
@[ode_at] theorem at_1801B6 : prog 0x1801B6 = some (.pop .rbp, 0x1801B7) := rfl
@[ode_at] theorem at_1801B7 : prog 0x1801B7 = some (.pop .rbx, 0x1801B8) := rfl
@[ode_at] theorem at_1801B8 : prog 0x1801B8 = some (.ret, 0x1801B9) := rfl

end Code_group
