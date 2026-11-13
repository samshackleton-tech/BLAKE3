import Machine
import KCode
import Cells
import Code_pad
import Code_chunk_node
import Code_node_out
open X86

/-! `k32s` as assembled: 72 instructions. Written from the lifter's rows. -/

set_option maxRecDepth 100000
namespace Code_k32s

def table : List (Nat × Instr × Nat) := [
  (0x10000, .push .rbx, 0x10001),
  (0x10001, .push .rbp, 0x10002),
  (0x10002, .push .r12, 0x10004),
  (0x10004, .push .r13, 0x10006),
  (0x10006, .push .r14, 0x10008),
  (0x10008, .push .r15, 0x1000A),
  (0x1000A, .sub 64 (.reg .rsp) (.imm 0xA8), 0x10011),
  (0x10011, .mov 64 (.reg .rbx) (.reg .rdi), 0x10014),
  (0x10014, .mov 64 (.reg .rbp) (.reg .rsi), 0x10017),
  (0x10017, .mov 64 (.reg .r12) (.reg .rdx), 0x1001A),
  (0x1001A, .mov 64 (.reg .r13) (.reg .rcx), 0x1001D),
  (0x1001D, .mov 64 (.reg .r14) (.reg .r8), 0x10020),
  (0x10020, .mov 64 (.reg .r15) (.reg .r9), 0x10023),
  (0x10023, .mov 64 (.reg .rax) (.reg .r14), 0x10026),
  (0x10026, .and 64 (.reg .rax) (.imm 0xFF), 0x1002C),
  (0x1002C, .mov 64 (.mem .rsp 0x78) (.reg .rax), 0x10031),
  (0x10031, .mov 64 (.reg .rax) (.imm 0x0), 0x10038),
  (0x10038, .mov 64 (.mem .rsp 0x80) (.reg .rax), 0x10040),
  (0x10040, .mov 64 (.reg .rax) (.imm 0x0), 0x10047),
  (0x10047, .mov 64 (.mem .rsp 0x88) (.reg .rax), 0x1004F),
  (0x1004F, .mov 64 (.reg .rax) (.imm 0x0), 0x10056),
  (0x10056, .mov 64 (.mem .rsp 0x90) (.reg .rax), 0x1005E),
  (0x1005E, .mov 64 (.reg .rax) (.imm 0x0), 0x10065),
  (0x10065, .mov 64 (.mem .rsp 0x98) (.reg .rax), 0x1006D),
  (0x1006D, .mov 64 (.reg .rax) (.mem .rsp 0x80), 0x10075),
  (0x10075, .mov 64 (.reg .rcx) (.imm 0x20), 0x1007C),
  (0x1007C, .cmp 64 (.reg .rax) (.reg .rcx), 0x1007F),
  (0x1007F, .jae 0x10148, 0x10085),
  (0x10085, .mov 64 (.reg .rax) (.reg .rbx), 0x10088),
  (0x10088, .mov 64 (.reg .rcx) (.mem .rsp 0x80), 0x10090),
  (0x10090, .shl64 .rcx 3, 0x10094),
  (0x10094, .add 64 (.reg .rax) (.reg .rcx), 0x10097),
  (0x10097, .mov 64 (.reg .rax) (.mem .rax 0x0), 0x1009A),
  (0x1009A, .mov 64 (.mem .rsp 0x88) (.reg .rax), 0x100A2),
  (0x100A2, .mov 64 (.reg .rax) (.reg .r15), 0x100A5),
  (0x100A5, .mov 64 (.reg .rcx) (.mem .rsp 0x80), 0x100AD),
  (0x100AD, .shl64 .rcx 5, 0x100B1),
  (0x100B1, .add 64 (.reg .rax) (.reg .rcx), 0x100B4),
  (0x100B4, .mov 64 (.mem .rsp 0x90) (.reg .rax), 0x100BC),
  (0x100BC, .mov 64 (.reg .rax) (.reg .r13), 0x100BF),
  (0x100BF, .add 64 (.reg .rax) (.mem .rsp 0x80), 0x100C7),
  (0x100C7, .mov 64 (.mem .rsp 0x98) (.reg .rax), 0x100CF),
  (0x100CF, .mov 64 (.reg .rax) (.reg .r12), 0x100D2),
  (0x100D2, .lea .rcx .rsp 0x0, 0x100D6),
  (0x100D6, .movv false 0 (.m .rax 0x0), 0x100D9),
  (0x100D9, .storev false .rcx 0x0 0, 0x100DC),
  (0x100DC, .movv false 0 (.m .rax 0x10), 0x100E0),
  (0x100E0, .storev false .rcx 0x10 0, 0x100E4),
  (0x100E4, .lea .rdi .rsp 0x0, 0x100E8),
  (0x100E8, .mov 64 (.reg .rsi) (.mem .rsp 0x88), 0x100F0),
  (0x100F0, .mov 64 (.reg .rdx) (.imm 0x400), 0x100F7),
  (0x100F7, .mov 64 (.reg .rcx) (.mem .rsp 0x98), 0x100FF),
  (0x100FF, .mov 64 (.reg .r8) (.mem .rsp 0x78), 0x10104),
  (0x10104, .mov 64 (.reg .r9) (.imm 0x5), 0x1010B),
  (0x1010B, .call 0xF0000, 0x10110),
  (0x10110, .mov 64 (.reg .rdi) (.mem .rsp 0x90), 0x10118),
  (0x10118, .lea .rsi .rsp 0x0, 0x1011C),
  (0x1011C, .mov 64 (.reg .rdx) (.imm 0x0), 0x10123),
  (0x10123, .mov 64 (.reg .rcx) (.imm 0x5), 0x1012A),
  (0x1012A, .call 0xD0000, 0x1012F),
  (0x1012F, .mov 64 (.reg .rax) (.mem .rsp 0x80), 0x10137),
  (0x10137, .add 64 (.reg .rax) (.imm 0x1), 0x1013B),
  (0x1013B, .mov 64 (.mem .rsp 0x80) (.reg .rax), 0x10143),
  (0x10143, .jmp 0x1006D, 0x10148),
  (0x10148, .add 64 (.reg .rsp) (.imm 0xA8), 0x1014F),
  (0x1014F, .pop .r15, 0x10151),
  (0x10151, .pop .r14, 0x10153),
  (0x10153, .pop .r13, 0x10155),
  (0x10155, .pop .r12, 0x10157),
  (0x10157, .pop .rbp, 0x10158),
  (0x10158, .pop .rbx, 0x10159),
  (0x10159, .ret, 0x1015A)
]

def pre0 : List (Nat × Instr × Nat) := KCode.table
def pre1 : List (Nat × Instr × Nat) := pre0 ++ Code_pad.table
def pre2 : List (Nat × Instr × Nat) := pre1 ++ Code_chunk_node.table
def pre3 : List (Nat × Instr × Nat) := pre2 ++ Code_node_out.table

/-- Every instruction of the program: the two kernels' (one/KCode.lean), `pad`'s, `chunk_node`'s, `node_out`'s, then this function's. -/
def whole : List (Nat × Instr × Nat) := pre3 ++ table

def prog (pc : Nat) : Option (Instr × Nat) := whole.lookup pc

/-- The addresses the program has an instruction at. -/
def keys : List Nat := whole.map (·.1)

theorem keys_of : ∀ pc x, prog pc = some x → pc ∈ keys := fun pc x h => lookup_mem_keys whole pc x h

theorem has_kernels : ∀ pc x, KCode.prog pc = some x → prog pc = some x := by
  intro pc x h
  exact lookup_append_left pre3 table pc x (lookup_append_left pre2 Code_node_out.table pc x (lookup_append_left pre1 Code_chunk_node.table pc x (lookup_append_left pre0 Code_pad.table pc x (h))))

/-- `pad`'s own instructions are in this program: no table before them has one at any of their addresses. -/
theorem in1 : ∀ pc x, Code_pad.table.lookup pc = some x → prog pc = some x := by
  intro pc x h
  have apart : ∀ p ∈ Code_pad.table.map (·.1), ((pre0.lookup p).isNone) = true := by decide +kernel
  have none := Option.isNone_iff_eq_none.mp (apart pc (lookup_mem_keys _ pc x h))
  have here : pre1.lookup pc = some x := by
    show (pre0 ++ Code_pad.table).lookup pc = some x
    rw [lookup_append_or, none]; exact h
  exact lookup_append_left pre3 table pc x (lookup_append_left pre2 Code_node_out.table pc x (lookup_append_left pre1 Code_chunk_node.table pc x (here)))

/-- `chunk_node`'s own instructions are in this program: no table before them has one at any of their addresses. -/
theorem in2 : ∀ pc x, Code_chunk_node.table.lookup pc = some x → prog pc = some x := by
  intro pc x h
  have apart : ∀ p ∈ Code_chunk_node.table.map (·.1), ((pre1.lookup p).isNone) = true := by decide +kernel
  have none := Option.isNone_iff_eq_none.mp (apart pc (lookup_mem_keys _ pc x h))
  have here : pre2.lookup pc = some x := by
    show (pre1 ++ Code_chunk_node.table).lookup pc = some x
    rw [lookup_append_or, none]; exact h
  exact lookup_append_left pre3 table pc x (lookup_append_left pre2 Code_node_out.table pc x (here))

/-- `node_out`'s own instructions are in this program: no table before them has one at any of their addresses. -/
theorem in3 : ∀ pc x, Code_node_out.table.lookup pc = some x → prog pc = some x := by
  intro pc x h
  have apart : ∀ p ∈ Code_node_out.table.map (·.1), ((pre2.lookup p).isNone) = true := by decide +kernel
  have none := Option.isNone_iff_eq_none.mp (apart pc (lookup_mem_keys _ pc x h))
  have here : pre3.lookup pc = some x := by
    show (pre2 ++ Code_node_out.table).lookup pc = some x
    rw [lookup_append_or, none]; exact h
  exact lookup_append_left pre3 table pc x (here)

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

@[ode_at] theorem at_10000 : prog 0x10000 = some (.push .rbx, 0x10001) := rfl
@[ode_at] theorem at_10001 : prog 0x10001 = some (.push .rbp, 0x10002) := rfl
@[ode_at] theorem at_10002 : prog 0x10002 = some (.push .r12, 0x10004) := rfl
@[ode_at] theorem at_10004 : prog 0x10004 = some (.push .r13, 0x10006) := rfl
@[ode_at] theorem at_10006 : prog 0x10006 = some (.push .r14, 0x10008) := rfl
@[ode_at] theorem at_10008 : prog 0x10008 = some (.push .r15, 0x1000A) := rfl
@[ode_at] theorem at_1000A : prog 0x1000A = some (.sub 64 (.reg .rsp) (.imm 0xA8), 0x10011) := rfl
@[ode_at] theorem at_10011 : prog 0x10011 = some (.mov 64 (.reg .rbx) (.reg .rdi), 0x10014) := rfl
@[ode_at] theorem at_10014 : prog 0x10014 = some (.mov 64 (.reg .rbp) (.reg .rsi), 0x10017) := rfl
@[ode_at] theorem at_10017 : prog 0x10017 = some (.mov 64 (.reg .r12) (.reg .rdx), 0x1001A) := rfl
@[ode_at] theorem at_1001A : prog 0x1001A = some (.mov 64 (.reg .r13) (.reg .rcx), 0x1001D) := rfl
@[ode_at] theorem at_1001D : prog 0x1001D = some (.mov 64 (.reg .r14) (.reg .r8), 0x10020) := rfl
@[ode_at] theorem at_10020 : prog 0x10020 = some (.mov 64 (.reg .r15) (.reg .r9), 0x10023) := rfl
@[ode_at] theorem at_10023 : prog 0x10023 = some (.mov 64 (.reg .rax) (.reg .r14), 0x10026) := rfl
@[ode_at] theorem at_10026 : prog 0x10026 = some (.and 64 (.reg .rax) (.imm 0xFF), 0x1002C) := rfl
@[ode_at] theorem at_1002C : prog 0x1002C = some (.mov 64 (.mem .rsp 0x78) (.reg .rax), 0x10031) := rfl
@[ode_at] theorem at_10031 : prog 0x10031 = some (.mov 64 (.reg .rax) (.imm 0x0), 0x10038) := rfl
@[ode_at] theorem at_10038 : prog 0x10038 = some (.mov 64 (.mem .rsp 0x80) (.reg .rax), 0x10040) := rfl
@[ode_at] theorem at_10040 : prog 0x10040 = some (.mov 64 (.reg .rax) (.imm 0x0), 0x10047) := rfl
@[ode_at] theorem at_10047 : prog 0x10047 = some (.mov 64 (.mem .rsp 0x88) (.reg .rax), 0x1004F) := rfl
@[ode_at] theorem at_1004F : prog 0x1004F = some (.mov 64 (.reg .rax) (.imm 0x0), 0x10056) := rfl
@[ode_at] theorem at_10056 : prog 0x10056 = some (.mov 64 (.mem .rsp 0x90) (.reg .rax), 0x1005E) := rfl
@[ode_at] theorem at_1005E : prog 0x1005E = some (.mov 64 (.reg .rax) (.imm 0x0), 0x10065) := rfl
@[ode_at] theorem at_10065 : prog 0x10065 = some (.mov 64 (.mem .rsp 0x98) (.reg .rax), 0x1006D) := rfl
@[ode_at] theorem at_1006D : prog 0x1006D = some (.mov 64 (.reg .rax) (.mem .rsp 0x80), 0x10075) := rfl
@[ode_at] theorem at_10075 : prog 0x10075 = some (.mov 64 (.reg .rcx) (.imm 0x20), 0x1007C) := rfl
@[ode_at] theorem at_1007C : prog 0x1007C = some (.cmp 64 (.reg .rax) (.reg .rcx), 0x1007F) := rfl
@[ode_at] theorem at_1007F : prog 0x1007F = some (.jae 0x10148, 0x10085) := rfl
@[ode_at] theorem at_10085 : prog 0x10085 = some (.mov 64 (.reg .rax) (.reg .rbx), 0x10088) := rfl
@[ode_at] theorem at_10088 : prog 0x10088 = some (.mov 64 (.reg .rcx) (.mem .rsp 0x80), 0x10090) := rfl
@[ode_at] theorem at_10090 : prog 0x10090 = some (.shl64 .rcx 3, 0x10094) := rfl
@[ode_at] theorem at_10094 : prog 0x10094 = some (.add 64 (.reg .rax) (.reg .rcx), 0x10097) := rfl
@[ode_at] theorem at_10097 : prog 0x10097 = some (.mov 64 (.reg .rax) (.mem .rax 0x0), 0x1009A) := rfl
@[ode_at] theorem at_1009A : prog 0x1009A = some (.mov 64 (.mem .rsp 0x88) (.reg .rax), 0x100A2) := rfl
@[ode_at] theorem at_100A2 : prog 0x100A2 = some (.mov 64 (.reg .rax) (.reg .r15), 0x100A5) := rfl
@[ode_at] theorem at_100A5 : prog 0x100A5 = some (.mov 64 (.reg .rcx) (.mem .rsp 0x80), 0x100AD) := rfl
@[ode_at] theorem at_100AD : prog 0x100AD = some (.shl64 .rcx 5, 0x100B1) := rfl
@[ode_at] theorem at_100B1 : prog 0x100B1 = some (.add 64 (.reg .rax) (.reg .rcx), 0x100B4) := rfl
@[ode_at] theorem at_100B4 : prog 0x100B4 = some (.mov 64 (.mem .rsp 0x90) (.reg .rax), 0x100BC) := rfl
@[ode_at] theorem at_100BC : prog 0x100BC = some (.mov 64 (.reg .rax) (.reg .r13), 0x100BF) := rfl
@[ode_at] theorem at_100BF : prog 0x100BF = some (.add 64 (.reg .rax) (.mem .rsp 0x80), 0x100C7) := rfl
@[ode_at] theorem at_100C7 : prog 0x100C7 = some (.mov 64 (.mem .rsp 0x98) (.reg .rax), 0x100CF) := rfl
@[ode_at] theorem at_100CF : prog 0x100CF = some (.mov 64 (.reg .rax) (.reg .r12), 0x100D2) := rfl
@[ode_at] theorem at_100D2 : prog 0x100D2 = some (.lea .rcx .rsp 0x0, 0x100D6) := rfl
@[ode_at] theorem at_100D6 : prog 0x100D6 = some (.movv false 0 (.m .rax 0x0), 0x100D9) := rfl
@[ode_at] theorem at_100D9 : prog 0x100D9 = some (.storev false .rcx 0x0 0, 0x100DC) := rfl
@[ode_at] theorem at_100DC : prog 0x100DC = some (.movv false 0 (.m .rax 0x10), 0x100E0) := rfl
@[ode_at] theorem at_100E0 : prog 0x100E0 = some (.storev false .rcx 0x10 0, 0x100E4) := rfl
@[ode_at] theorem at_100E4 : prog 0x100E4 = some (.lea .rdi .rsp 0x0, 0x100E8) := rfl
@[ode_at] theorem at_100E8 : prog 0x100E8 = some (.mov 64 (.reg .rsi) (.mem .rsp 0x88), 0x100F0) := rfl
@[ode_at] theorem at_100F0 : prog 0x100F0 = some (.mov 64 (.reg .rdx) (.imm 0x400), 0x100F7) := rfl
@[ode_at] theorem at_100F7 : prog 0x100F7 = some (.mov 64 (.reg .rcx) (.mem .rsp 0x98), 0x100FF) := rfl
@[ode_at] theorem at_100FF : prog 0x100FF = some (.mov 64 (.reg .r8) (.mem .rsp 0x78), 0x10104) := rfl
@[ode_at] theorem at_10104 : prog 0x10104 = some (.mov 64 (.reg .r9) (.imm 0x5), 0x1010B) := rfl
@[ode_at] theorem at_1010B : prog 0x1010B = some (.call 0xF0000, 0x10110) := rfl
@[ode_at] theorem at_10110 : prog 0x10110 = some (.mov 64 (.reg .rdi) (.mem .rsp 0x90), 0x10118) := rfl
@[ode_at] theorem at_10118 : prog 0x10118 = some (.lea .rsi .rsp 0x0, 0x1011C) := rfl
@[ode_at] theorem at_1011C : prog 0x1011C = some (.mov 64 (.reg .rdx) (.imm 0x0), 0x10123) := rfl
@[ode_at] theorem at_10123 : prog 0x10123 = some (.mov 64 (.reg .rcx) (.imm 0x5), 0x1012A) := rfl
@[ode_at] theorem at_1012A : prog 0x1012A = some (.call 0xD0000, 0x1012F) := rfl
@[ode_at] theorem at_1012F : prog 0x1012F = some (.mov 64 (.reg .rax) (.mem .rsp 0x80), 0x10137) := rfl
@[ode_at] theorem at_10137 : prog 0x10137 = some (.add 64 (.reg .rax) (.imm 0x1), 0x1013B) := rfl
@[ode_at] theorem at_1013B : prog 0x1013B = some (.mov 64 (.mem .rsp 0x80) (.reg .rax), 0x10143) := rfl
@[ode_at] theorem at_10143 : prog 0x10143 = some (.jmp 0x1006D, 0x10148) := rfl
@[ode_at] theorem at_10148 : prog 0x10148 = some (.add 64 (.reg .rsp) (.imm 0xA8), 0x1014F) := rfl
@[ode_at] theorem at_1014F : prog 0x1014F = some (.pop .r15, 0x10151) := rfl
@[ode_at] theorem at_10151 : prog 0x10151 = some (.pop .r14, 0x10153) := rfl
@[ode_at] theorem at_10153 : prog 0x10153 = some (.pop .r13, 0x10155) := rfl
@[ode_at] theorem at_10155 : prog 0x10155 = some (.pop .r12, 0x10157) := rfl
@[ode_at] theorem at_10157 : prog 0x10157 = some (.pop .rbp, 0x10158) := rfl
@[ode_at] theorem at_10158 : prog 0x10158 = some (.pop .rbx, 0x10159) := rfl
@[ode_at] theorem at_10159 : prog 0x10159 = some (.ret, 0x1015A) := rfl

end Code_k32s
