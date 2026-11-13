import Machine
import KCode
import Cells
open X86

/-! `p16s` as assembled: 57 instructions. Written from the lifter's rows. -/

set_option maxRecDepth 100000
namespace Code_p16s

def table : List (Nat × Instr × Nat) := [
  (0x18000, .push .rbx, 0x18001),
  (0x18001, .push .rbp, 0x18002),
  (0x18002, .push .r12, 0x18004),
  (0x18004, .push .r13, 0x18006),
  (0x18006, .push .r14, 0x18008),
  (0x18008, .push .r15, 0x1800A),
  (0x1800A, .sub 64 (.reg .rsp) (.imm 0x28), 0x1800E),
  (0x1800E, .mov 64 (.reg .r12) (.reg .rdi), 0x18011),
  (0x18011, .mov 64 (.reg .r15) (.reg .rsi), 0x18014),
  (0x18014, .mov 64 (.reg .r13) (.reg .rdx), 0x18017),
  (0x18017, .mov 64 (.mem .rsp 0x0) (.reg .rcx), 0x1801B),
  (0x1801B, .mov 64 (.mem .rsp 0x8) (.reg .r8), 0x18020),
  (0x18020, .mov 64 (.reg .r14) (.reg .r9), 0x18023),
  (0x18023, .mov 64 (.reg .rax) (.mem .rsp 0x8), 0x18028),
  (0x18028, .and 64 (.reg .rax) (.imm 0xFF), 0x1802E),
  (0x1802E, .mov 64 (.reg .rbp) (.reg .rax), 0x18031),
  (0x18031, .mov 64 (.reg .rax) (.imm 0x0), 0x18038),
  (0x18038, .mov 64 (.reg .rbx) (.reg .rax), 0x1803B),
  (0x1803B, .mov 64 (.reg .rax) (.reg .rbx), 0x1803E),
  (0x1803E, .mov 64 (.reg .rcx) (.imm 0x10), 0x18045),
  (0x18045, .cmp 64 (.reg .rax) (.reg .rcx), 0x18048),
  (0x18048, .jae 0x180B3, 0x1804A),
  (0x1804A, .mov 64 (.reg .rax) (.reg .r12), 0x1804D),
  (0x1804D, .mov 64 (.reg .rcx) (.reg .rbx), 0x18050),
  (0x18050, .shl64 .rcx 3, 0x18054),
  (0x18054, .add 64 (.reg .rax) (.reg .rcx), 0x18057),
  (0x18057, .mov 64 (.reg .rax) (.mem .rax 0x0), 0x1805A),
  (0x1805A, .mov 64 (.mem .rsp 0x10) (.reg .rax), 0x1805F),
  (0x1805F, .mov 64 (.reg .rax) (.reg .r14), 0x18062),
  (0x18062, .mov 64 (.reg .rcx) (.reg .rbx), 0x18065),
  (0x18065, .shl64 .rcx 5, 0x18069),
  (0x18069, .add 64 (.reg .rax) (.reg .rcx), 0x1806C),
  (0x1806C, .mov 64 (.mem .rsp 0x18) (.reg .rax), 0x18071),
  (0x18071, .mov 64 (.reg .rax) (.reg .r13), 0x18074),
  (0x18074, .mov 64 (.reg .rcx) (.mem .rsp 0x18), 0x18079),
  (0x18079, .movv false 0 (.m .rax 0x0), 0x1807C),
  (0x1807C, .storev false .rcx 0x0 0, 0x1807F),
  (0x1807F, .movv false 0 (.m .rax 0x10), 0x18083),
  (0x18083, .storev false .rcx 0x10 0, 0x18087),
  (0x18087, .mov 64 (.reg .rdi) (.mem .rsp 0x18), 0x1808C),
  (0x1808C, .mov 64 (.reg .rsi) (.mem .rsp 0x10), 0x18091),
  (0x18091, .mov 64 (.reg .rdx) (.imm 0x40), 0x18098),
  (0x18098, .mov 64 (.reg .rcx) (.imm 0x0), 0x1809F),
  (0x1809F, .mov 64 (.reg .r8) (.reg .rbp), 0x180A2),
  (0x180A2, .call 0x30000, 0x180A7),
  (0x180A7, .mov 64 (.reg .rax) (.reg .rbx), 0x180AA),
  (0x180AA, .add 64 (.reg .rax) (.imm 0x1), 0x180AE),
  (0x180AE, .mov 64 (.reg .rbx) (.reg .rax), 0x180B1),
  (0x180B1, .jmp 0x1803B, 0x180B3),
  (0x180B3, .add 64 (.reg .rsp) (.imm 0x28), 0x180B7),
  (0x180B7, .pop .r15, 0x180B9),
  (0x180B9, .pop .r14, 0x180BB),
  (0x180BB, .pop .r13, 0x180BD),
  (0x180BD, .pop .r12, 0x180BF),
  (0x180BF, .pop .rbp, 0x180C0),
  (0x180C0, .pop .rbx, 0x180C1),
  (0x180C1, .ret, 0x180C2)
]

def pre0 : List (Nat × Instr × Nat) := KCode.table

/-- Every instruction of the program: the two kernels' (one/KCode.lean), then this function's. -/
def whole : List (Nat × Instr × Nat) := pre0 ++ table

def prog (pc : Nat) : Option (Instr × Nat) := whole.lookup pc

/-- The addresses the program has an instruction at. -/
def keys : List Nat := whole.map (·.1)

theorem keys_of : ∀ pc x, prog pc = some x → pc ∈ keys := fun pc x h => lookup_mem_keys whole pc x h

theorem has_kernels : ∀ pc x, KCode.prog pc = some x → prog pc = some x := by
  intro pc x h
  exact lookup_append_left pre0 table pc x (h)

@[ode_at] theorem at_18000 : prog 0x18000 = some (.push .rbx, 0x18001) := rfl
@[ode_at] theorem at_18001 : prog 0x18001 = some (.push .rbp, 0x18002) := rfl
@[ode_at] theorem at_18002 : prog 0x18002 = some (.push .r12, 0x18004) := rfl
@[ode_at] theorem at_18004 : prog 0x18004 = some (.push .r13, 0x18006) := rfl
@[ode_at] theorem at_18006 : prog 0x18006 = some (.push .r14, 0x18008) := rfl
@[ode_at] theorem at_18008 : prog 0x18008 = some (.push .r15, 0x1800A) := rfl
@[ode_at] theorem at_1800A : prog 0x1800A = some (.sub 64 (.reg .rsp) (.imm 0x28), 0x1800E) := rfl
@[ode_at] theorem at_1800E : prog 0x1800E = some (.mov 64 (.reg .r12) (.reg .rdi), 0x18011) := rfl
@[ode_at] theorem at_18011 : prog 0x18011 = some (.mov 64 (.reg .r15) (.reg .rsi), 0x18014) := rfl
@[ode_at] theorem at_18014 : prog 0x18014 = some (.mov 64 (.reg .r13) (.reg .rdx), 0x18017) := rfl
@[ode_at] theorem at_18017 : prog 0x18017 = some (.mov 64 (.mem .rsp 0x0) (.reg .rcx), 0x1801B) := rfl
@[ode_at] theorem at_1801B : prog 0x1801B = some (.mov 64 (.mem .rsp 0x8) (.reg .r8), 0x18020) := rfl
@[ode_at] theorem at_18020 : prog 0x18020 = some (.mov 64 (.reg .r14) (.reg .r9), 0x18023) := rfl
@[ode_at] theorem at_18023 : prog 0x18023 = some (.mov 64 (.reg .rax) (.mem .rsp 0x8), 0x18028) := rfl
@[ode_at] theorem at_18028 : prog 0x18028 = some (.and 64 (.reg .rax) (.imm 0xFF), 0x1802E) := rfl
@[ode_at] theorem at_1802E : prog 0x1802E = some (.mov 64 (.reg .rbp) (.reg .rax), 0x18031) := rfl
@[ode_at] theorem at_18031 : prog 0x18031 = some (.mov 64 (.reg .rax) (.imm 0x0), 0x18038) := rfl
@[ode_at] theorem at_18038 : prog 0x18038 = some (.mov 64 (.reg .rbx) (.reg .rax), 0x1803B) := rfl
@[ode_at] theorem at_1803B : prog 0x1803B = some (.mov 64 (.reg .rax) (.reg .rbx), 0x1803E) := rfl
@[ode_at] theorem at_1803E : prog 0x1803E = some (.mov 64 (.reg .rcx) (.imm 0x10), 0x18045) := rfl
@[ode_at] theorem at_18045 : prog 0x18045 = some (.cmp 64 (.reg .rax) (.reg .rcx), 0x18048) := rfl
@[ode_at] theorem at_18048 : prog 0x18048 = some (.jae 0x180B3, 0x1804A) := rfl
@[ode_at] theorem at_1804A : prog 0x1804A = some (.mov 64 (.reg .rax) (.reg .r12), 0x1804D) := rfl
@[ode_at] theorem at_1804D : prog 0x1804D = some (.mov 64 (.reg .rcx) (.reg .rbx), 0x18050) := rfl
@[ode_at] theorem at_18050 : prog 0x18050 = some (.shl64 .rcx 3, 0x18054) := rfl
@[ode_at] theorem at_18054 : prog 0x18054 = some (.add 64 (.reg .rax) (.reg .rcx), 0x18057) := rfl
@[ode_at] theorem at_18057 : prog 0x18057 = some (.mov 64 (.reg .rax) (.mem .rax 0x0), 0x1805A) := rfl
@[ode_at] theorem at_1805A : prog 0x1805A = some (.mov 64 (.mem .rsp 0x10) (.reg .rax), 0x1805F) := rfl
@[ode_at] theorem at_1805F : prog 0x1805F = some (.mov 64 (.reg .rax) (.reg .r14), 0x18062) := rfl
@[ode_at] theorem at_18062 : prog 0x18062 = some (.mov 64 (.reg .rcx) (.reg .rbx), 0x18065) := rfl
@[ode_at] theorem at_18065 : prog 0x18065 = some (.shl64 .rcx 5, 0x18069) := rfl
@[ode_at] theorem at_18069 : prog 0x18069 = some (.add 64 (.reg .rax) (.reg .rcx), 0x1806C) := rfl
@[ode_at] theorem at_1806C : prog 0x1806C = some (.mov 64 (.mem .rsp 0x18) (.reg .rax), 0x18071) := rfl
@[ode_at] theorem at_18071 : prog 0x18071 = some (.mov 64 (.reg .rax) (.reg .r13), 0x18074) := rfl
@[ode_at] theorem at_18074 : prog 0x18074 = some (.mov 64 (.reg .rcx) (.mem .rsp 0x18), 0x18079) := rfl
@[ode_at] theorem at_18079 : prog 0x18079 = some (.movv false 0 (.m .rax 0x0), 0x1807C) := rfl
@[ode_at] theorem at_1807C : prog 0x1807C = some (.storev false .rcx 0x0 0, 0x1807F) := rfl
@[ode_at] theorem at_1807F : prog 0x1807F = some (.movv false 0 (.m .rax 0x10), 0x18083) := rfl
@[ode_at] theorem at_18083 : prog 0x18083 = some (.storev false .rcx 0x10 0, 0x18087) := rfl
@[ode_at] theorem at_18087 : prog 0x18087 = some (.mov 64 (.reg .rdi) (.mem .rsp 0x18), 0x1808C) := rfl
@[ode_at] theorem at_1808C : prog 0x1808C = some (.mov 64 (.reg .rsi) (.mem .rsp 0x10), 0x18091) := rfl
@[ode_at] theorem at_18091 : prog 0x18091 = some (.mov 64 (.reg .rdx) (.imm 0x40), 0x18098) := rfl
@[ode_at] theorem at_18098 : prog 0x18098 = some (.mov 64 (.reg .rcx) (.imm 0x0), 0x1809F) := rfl
@[ode_at] theorem at_1809F : prog 0x1809F = some (.mov 64 (.reg .r8) (.reg .rbp), 0x180A2) := rfl
@[ode_at] theorem at_180A2 : prog 0x180A2 = some (.call 0x30000, 0x180A7) := rfl
@[ode_at] theorem at_180A7 : prog 0x180A7 = some (.mov 64 (.reg .rax) (.reg .rbx), 0x180AA) := rfl
@[ode_at] theorem at_180AA : prog 0x180AA = some (.add 64 (.reg .rax) (.imm 0x1), 0x180AE) := rfl
@[ode_at] theorem at_180AE : prog 0x180AE = some (.mov 64 (.reg .rbx) (.reg .rax), 0x180B1) := rfl
@[ode_at] theorem at_180B1 : prog 0x180B1 = some (.jmp 0x1803B, 0x180B3) := rfl
@[ode_at] theorem at_180B3 : prog 0x180B3 = some (.add 64 (.reg .rsp) (.imm 0x28), 0x180B7) := rfl
@[ode_at] theorem at_180B7 : prog 0x180B7 = some (.pop .r15, 0x180B9) := rfl
@[ode_at] theorem at_180B9 : prog 0x180B9 = some (.pop .r14, 0x180BB) := rfl
@[ode_at] theorem at_180BB : prog 0x180BB = some (.pop .r13, 0x180BD) := rfl
@[ode_at] theorem at_180BD : prog 0x180BD = some (.pop .r12, 0x180BF) := rfl
@[ode_at] theorem at_180BF : prog 0x180BF = some (.pop .rbp, 0x180C0) := rfl
@[ode_at] theorem at_180C0 : prog 0x180C0 = some (.pop .rbx, 0x180C1) := rfl
@[ode_at] theorem at_180C1 : prog 0x180C1 = some (.ret, 0x180C2) := rfl

end Code_p16s
