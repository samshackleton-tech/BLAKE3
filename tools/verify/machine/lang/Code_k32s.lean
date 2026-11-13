import Machine
import KCode
import Cells
import Code_pad
import Code_chunk_node
import Code_node_out
open X86

/-! `k32s` as assembled: 66 instructions. Written from the lifter's rows. -/

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
  (0x10011, .mov 64 (.reg .r12) (.reg .rdi), 0x10014),
  (0x10014, .mov 64 (.mem .rsp 0x78) (.reg .rsi), 0x10019),
  (0x10019, .mov 64 (.reg .r13) (.reg .rdx), 0x1001C),
  (0x1001C, .mov 64 (.reg .r15) (.reg .rcx), 0x1001F),
  (0x1001F, .mov 64 (.mem .rsp 0x80) (.reg .r8), 0x10027),
  (0x10027, .mov 64 (.reg .r14) (.reg .r9), 0x1002A),
  (0x1002A, .mov 64 (.reg .rax) (.mem .rsp 0x80), 0x10032),
  (0x10032, .and 64 (.reg .rax) (.imm 0xFF), 0x10038),
  (0x10038, .mov 64 (.reg .rbp) (.reg .rax), 0x1003B),
  (0x1003B, .mov 64 (.reg .rax) (.imm 0x0), 0x10042),
  (0x10042, .mov 64 (.reg .rbx) (.reg .rax), 0x10045),
  (0x10045, .mov 64 (.reg .rax) (.reg .rbx), 0x10048),
  (0x10048, .mov 64 (.reg .rcx) (.imm 0x20), 0x1004F),
  (0x1004F, .cmp 64 (.reg .rax) (.reg .rcx), 0x10052),
  (0x10052, .jae 0x10100, 0x10058),
  (0x10058, .mov 64 (.reg .rax) (.reg .r12), 0x1005B),
  (0x1005B, .mov 64 (.reg .rcx) (.reg .rbx), 0x1005E),
  (0x1005E, .shl64 .rcx 3, 0x10062),
  (0x10062, .add 64 (.reg .rax) (.reg .rcx), 0x10065),
  (0x10065, .mov 64 (.reg .rax) (.mem .rax 0x0), 0x10068),
  (0x10068, .mov 64 (.mem .rsp 0x88) (.reg .rax), 0x10070),
  (0x10070, .mov 64 (.reg .rax) (.reg .r15), 0x10073),
  (0x10073, .add 64 (.reg .rax) (.reg .rbx), 0x10076),
  (0x10076, .mov 64 (.mem .rsp 0x90) (.reg .rax), 0x1007E),
  (0x1007E, .mov 64 (.reg .rax) (.reg .r13), 0x10081),
  (0x10081, .lea .rcx .rsp 0x0, 0x10085),
  (0x10085, .movv false 0 (.m .rax 0x0), 0x10088),
  (0x10088, .storev false .rcx 0x0 0, 0x1008B),
  (0x1008B, .movv false 0 (.m .rax 0x10), 0x1008F),
  (0x1008F, .storev false .rcx 0x10 0, 0x10093),
  (0x10093, .lea .rdi .rsp 0x0, 0x10097),
  (0x10097, .mov 64 (.reg .rsi) (.mem .rsp 0x88), 0x1009F),
  (0x1009F, .mov 64 (.reg .rdx) (.imm 0x400), 0x100A6),
  (0x100A6, .mov 64 (.reg .rcx) (.mem .rsp 0x90), 0x100AE),
  (0x100AE, .mov 64 (.reg .r8) (.reg .rbp), 0x100B1),
  (0x100B1, .mov 64 (.reg .r9) (.imm 0x5), 0x100B8),
  (0x100B8, .call 0xF0000, 0x100BD),
  (0x100BD, .mov 64 (.reg .rax) (.reg .r14), 0x100C0),
  (0x100C0, .mov 64 (.reg .rcx) (.reg .rbx), 0x100C3),
  (0x100C3, .shl64 .rcx 5, 0x100C7),
  (0x100C7, .add 64 (.reg .rax) (.reg .rcx), 0x100CA),
  (0x100CA, .mov 64 (.mem .rsp 0x98) (.reg .rax), 0x100D2),
  (0x100D2, .mov 64 (.reg .rdi) (.mem .rsp 0x98), 0x100DA),
  (0x100DA, .lea .rsi .rsp 0x0, 0x100DE),
  (0x100DE, .mov 64 (.reg .rdx) (.imm 0x0), 0x100E5),
  (0x100E5, .mov 64 (.reg .rcx) (.imm 0x5), 0x100EC),
  (0x100EC, .call 0xD0000, 0x100F1),
  (0x100F1, .mov 64 (.reg .rax) (.reg .rbx), 0x100F4),
  (0x100F4, .add 64 (.reg .rax) (.imm 0x1), 0x100F8),
  (0x100F8, .mov 64 (.reg .rbx) (.reg .rax), 0x100FB),
  (0x100FB, .jmp 0x10045, 0x10100),
  (0x10100, .add 64 (.reg .rsp) (.imm 0xA8), 0x10107),
  (0x10107, .pop .r15, 0x10109),
  (0x10109, .pop .r14, 0x1010B),
  (0x1010B, .pop .r13, 0x1010D),
  (0x1010D, .pop .r12, 0x1010F),
  (0x1010F, .pop .rbp, 0x10110),
  (0x10110, .pop .rbx, 0x10111),
  (0x10111, .ret, 0x10112)
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
@[ode_at] theorem at_10011 : prog 0x10011 = some (.mov 64 (.reg .r12) (.reg .rdi), 0x10014) := rfl
@[ode_at] theorem at_10014 : prog 0x10014 = some (.mov 64 (.mem .rsp 0x78) (.reg .rsi), 0x10019) := rfl
@[ode_at] theorem at_10019 : prog 0x10019 = some (.mov 64 (.reg .r13) (.reg .rdx), 0x1001C) := rfl
@[ode_at] theorem at_1001C : prog 0x1001C = some (.mov 64 (.reg .r15) (.reg .rcx), 0x1001F) := rfl
@[ode_at] theorem at_1001F : prog 0x1001F = some (.mov 64 (.mem .rsp 0x80) (.reg .r8), 0x10027) := rfl
@[ode_at] theorem at_10027 : prog 0x10027 = some (.mov 64 (.reg .r14) (.reg .r9), 0x1002A) := rfl
@[ode_at] theorem at_1002A : prog 0x1002A = some (.mov 64 (.reg .rax) (.mem .rsp 0x80), 0x10032) := rfl
@[ode_at] theorem at_10032 : prog 0x10032 = some (.and 64 (.reg .rax) (.imm 0xFF), 0x10038) := rfl
@[ode_at] theorem at_10038 : prog 0x10038 = some (.mov 64 (.reg .rbp) (.reg .rax), 0x1003B) := rfl
@[ode_at] theorem at_1003B : prog 0x1003B = some (.mov 64 (.reg .rax) (.imm 0x0), 0x10042) := rfl
@[ode_at] theorem at_10042 : prog 0x10042 = some (.mov 64 (.reg .rbx) (.reg .rax), 0x10045) := rfl
@[ode_at] theorem at_10045 : prog 0x10045 = some (.mov 64 (.reg .rax) (.reg .rbx), 0x10048) := rfl
@[ode_at] theorem at_10048 : prog 0x10048 = some (.mov 64 (.reg .rcx) (.imm 0x20), 0x1004F) := rfl
@[ode_at] theorem at_1004F : prog 0x1004F = some (.cmp 64 (.reg .rax) (.reg .rcx), 0x10052) := rfl
@[ode_at] theorem at_10052 : prog 0x10052 = some (.jae 0x10100, 0x10058) := rfl
@[ode_at] theorem at_10058 : prog 0x10058 = some (.mov 64 (.reg .rax) (.reg .r12), 0x1005B) := rfl
@[ode_at] theorem at_1005B : prog 0x1005B = some (.mov 64 (.reg .rcx) (.reg .rbx), 0x1005E) := rfl
@[ode_at] theorem at_1005E : prog 0x1005E = some (.shl64 .rcx 3, 0x10062) := rfl
@[ode_at] theorem at_10062 : prog 0x10062 = some (.add 64 (.reg .rax) (.reg .rcx), 0x10065) := rfl
@[ode_at] theorem at_10065 : prog 0x10065 = some (.mov 64 (.reg .rax) (.mem .rax 0x0), 0x10068) := rfl
@[ode_at] theorem at_10068 : prog 0x10068 = some (.mov 64 (.mem .rsp 0x88) (.reg .rax), 0x10070) := rfl
@[ode_at] theorem at_10070 : prog 0x10070 = some (.mov 64 (.reg .rax) (.reg .r15), 0x10073) := rfl
@[ode_at] theorem at_10073 : prog 0x10073 = some (.add 64 (.reg .rax) (.reg .rbx), 0x10076) := rfl
@[ode_at] theorem at_10076 : prog 0x10076 = some (.mov 64 (.mem .rsp 0x90) (.reg .rax), 0x1007E) := rfl
@[ode_at] theorem at_1007E : prog 0x1007E = some (.mov 64 (.reg .rax) (.reg .r13), 0x10081) := rfl
@[ode_at] theorem at_10081 : prog 0x10081 = some (.lea .rcx .rsp 0x0, 0x10085) := rfl
@[ode_at] theorem at_10085 : prog 0x10085 = some (.movv false 0 (.m .rax 0x0), 0x10088) := rfl
@[ode_at] theorem at_10088 : prog 0x10088 = some (.storev false .rcx 0x0 0, 0x1008B) := rfl
@[ode_at] theorem at_1008B : prog 0x1008B = some (.movv false 0 (.m .rax 0x10), 0x1008F) := rfl
@[ode_at] theorem at_1008F : prog 0x1008F = some (.storev false .rcx 0x10 0, 0x10093) := rfl
@[ode_at] theorem at_10093 : prog 0x10093 = some (.lea .rdi .rsp 0x0, 0x10097) := rfl
@[ode_at] theorem at_10097 : prog 0x10097 = some (.mov 64 (.reg .rsi) (.mem .rsp 0x88), 0x1009F) := rfl
@[ode_at] theorem at_1009F : prog 0x1009F = some (.mov 64 (.reg .rdx) (.imm 0x400), 0x100A6) := rfl
@[ode_at] theorem at_100A6 : prog 0x100A6 = some (.mov 64 (.reg .rcx) (.mem .rsp 0x90), 0x100AE) := rfl
@[ode_at] theorem at_100AE : prog 0x100AE = some (.mov 64 (.reg .r8) (.reg .rbp), 0x100B1) := rfl
@[ode_at] theorem at_100B1 : prog 0x100B1 = some (.mov 64 (.reg .r9) (.imm 0x5), 0x100B8) := rfl
@[ode_at] theorem at_100B8 : prog 0x100B8 = some (.call 0xF0000, 0x100BD) := rfl
@[ode_at] theorem at_100BD : prog 0x100BD = some (.mov 64 (.reg .rax) (.reg .r14), 0x100C0) := rfl
@[ode_at] theorem at_100C0 : prog 0x100C0 = some (.mov 64 (.reg .rcx) (.reg .rbx), 0x100C3) := rfl
@[ode_at] theorem at_100C3 : prog 0x100C3 = some (.shl64 .rcx 5, 0x100C7) := rfl
@[ode_at] theorem at_100C7 : prog 0x100C7 = some (.add 64 (.reg .rax) (.reg .rcx), 0x100CA) := rfl
@[ode_at] theorem at_100CA : prog 0x100CA = some (.mov 64 (.mem .rsp 0x98) (.reg .rax), 0x100D2) := rfl
@[ode_at] theorem at_100D2 : prog 0x100D2 = some (.mov 64 (.reg .rdi) (.mem .rsp 0x98), 0x100DA) := rfl
@[ode_at] theorem at_100DA : prog 0x100DA = some (.lea .rsi .rsp 0x0, 0x100DE) := rfl
@[ode_at] theorem at_100DE : prog 0x100DE = some (.mov 64 (.reg .rdx) (.imm 0x0), 0x100E5) := rfl
@[ode_at] theorem at_100E5 : prog 0x100E5 = some (.mov 64 (.reg .rcx) (.imm 0x5), 0x100EC) := rfl
@[ode_at] theorem at_100EC : prog 0x100EC = some (.call 0xD0000, 0x100F1) := rfl
@[ode_at] theorem at_100F1 : prog 0x100F1 = some (.mov 64 (.reg .rax) (.reg .rbx), 0x100F4) := rfl
@[ode_at] theorem at_100F4 : prog 0x100F4 = some (.add 64 (.reg .rax) (.imm 0x1), 0x100F8) := rfl
@[ode_at] theorem at_100F8 : prog 0x100F8 = some (.mov 64 (.reg .rbx) (.reg .rax), 0x100FB) := rfl
@[ode_at] theorem at_100FB : prog 0x100FB = some (.jmp 0x10045, 0x10100) := rfl
@[ode_at] theorem at_10100 : prog 0x10100 = some (.add 64 (.reg .rsp) (.imm 0xA8), 0x10107) := rfl
@[ode_at] theorem at_10107 : prog 0x10107 = some (.pop .r15, 0x10109) := rfl
@[ode_at] theorem at_10109 : prog 0x10109 = some (.pop .r14, 0x1010B) := rfl
@[ode_at] theorem at_1010B : prog 0x1010B = some (.pop .r13, 0x1010D) := rfl
@[ode_at] theorem at_1010D : prog 0x1010D = some (.pop .r12, 0x1010F) := rfl
@[ode_at] theorem at_1010F : prog 0x1010F = some (.pop .rbp, 0x10110) := rfl
@[ode_at] theorem at_10110 : prog 0x10110 = some (.pop .rbx, 0x10111) := rfl
@[ode_at] theorem at_10111 : prog 0x10111 = some (.ret, 0x10112) := rfl

end Code_k32s
