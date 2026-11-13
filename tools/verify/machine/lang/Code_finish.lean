import Machine
import KCode
import Cells
import Code_lroot
import Code_ladd
open X86

/-! `finish` as assembled: 74 instructions. Written from the lifter's rows. -/

set_option maxRecDepth 100000
namespace Code_finish

def table : List (Nat × Instr × Nat) := [
  (0x170000, .push .rbx, 0x170001),
  (0x170001, .push .rbp, 0x170002),
  (0x170002, .push .r12, 0x170004),
  (0x170004, .push .r13, 0x170006),
  (0x170006, .push .r14, 0x170008),
  (0x170008, .push .r15, 0x17000A),
  (0x17000A, .sub 64 (.reg .rsp) (.imm 0x28), 0x17000E),
  (0x17000E, .mov 64 (.reg .rbx) (.reg .rdi), 0x170011),
  (0x170011, .mov 64 (.reg .rbp) (.reg .rsi), 0x170014),
  (0x170014, .mov 64 (.reg .r12) (.reg .rdx), 0x170017),
  (0x170017, .mov 64 (.reg .r13) (.reg .rcx), 0x17001A),
  (0x17001A, .mov 64 (.reg .r14) (.reg .r8), 0x17001D),
  (0x17001D, .mov 64 (.reg .r15) (.reg .r9), 0x170020),
  (0x170020, .mov 64 (.reg .rax) (.reg .r12), 0x170023),
  (0x170023, .add 64 (.reg .rax) (.imm 0x40), 0x170027),
  (0x170027, .mov 64 (.mem .rsp 0x20) (.reg .rax), 0x17002C),
  (0x17002C, .mov 64 (.reg .rax) (.reg .r15), 0x17002F),
  (0x17002F, .mov 64 (.reg .rcx) (.imm 0x0), 0x170036),
  (0x170036, .cmp 64 (.reg .rax) (.reg .rcx), 0x170039),
  (0x170039, .jne 0x17005F, 0x17003B),
  (0x17003B, .mov 64 (.reg .rdi) (.reg .rbx), 0x17003E),
  (0x17003E, .mov 64 (.reg .rsi) (.reg .r12), 0x170041),
  (0x170041, .mov 64 (.reg .rdx) (.reg .r13), 0x170044),
  (0x170044, .mov 64 (.reg .rcx) (.reg .r14), 0x170047),
  (0x170047, .mov 64 (.reg .r8) (.imm 0x5), 0x17004E),
  (0x17004E, .mov 64 (.reg .r9) (.imm 0x8), 0x170055),
  (0x170055, .call 0xC0000, 0x17005A),
  (0x17005A, .jmp 0x170101, 0x17005F),
  (0x17005F, .mov 64 (.reg .rax) (.reg .r15), 0x170062),
  (0x170062, .mov 64 (.reg .rcx) (.imm 0x1), 0x170069),
  (0x170069, .cmp 64 (.reg .rax) (.reg .rcx), 0x17006C),
  (0x17006C, .jne 0x1700A9, 0x17006E),
  (0x17006E, .mov 64 (.reg .rdi) (.reg .rbp), 0x170071),
  (0x170071, .mov 64 (.reg .rsi) (.reg .r13), 0x170074),
  (0x170074, .mov 64 (.reg .rdx) (.reg .r14), 0x170077),
  (0x170077, .mov 64 (.reg .rcx) (.imm 0x5), 0x17007E),
  (0x17007E, .mov 64 (.reg .r8) (.mem .rsp 0x20), 0x170083),
  (0x170083, .call 0xB0000, 0x170088),
  (0x170088, .mov 64 (.reg .rdi) (.reg .rbx), 0x17008B),
  (0x17008B, .mov 64 (.reg .rsi) (.reg .rbp), 0x17008E),
  (0x17008E, .mov 64 (.reg .rdx) (.reg .r13), 0x170091),
  (0x170091, .mov 64 (.reg .rcx) (.reg .r14), 0x170094),
  (0x170094, .mov 64 (.reg .r8) (.imm 0x5), 0x17009B),
  (0x17009B, .mov 64 (.reg .r9) (.imm 0x8), 0x1700A2),
  (0x1700A2, .call 0xC0000, 0x1700A7),
  (0x1700A7, .jmp 0x170101, 0x1700A9),
  (0x1700A9, .lea .rdi .rsp 0x0, 0x1700AD),
  (0x1700AD, .mov 64 (.reg .rsi) (.reg .r12), 0x1700B0),
  (0x1700B0, .mov 64 (.reg .rdx) (.reg .r13), 0x1700B3),
  (0x1700B3, .mov 64 (.reg .rcx) (.reg .r14), 0x1700B6),
  (0x1700B6, .mov 64 (.reg .r8) (.imm 0x5), 0x1700BD),
  (0x1700BD, .mov 64 (.reg .r9) (.imm 0x0), 0x1700C4),
  (0x1700C4, .call 0xC0000, 0x1700C9),
  (0x1700C9, .mov 64 (.reg .rdi) (.reg .rbp), 0x1700CC),
  (0x1700CC, .mov 64 (.reg .rsi) (.reg .r13), 0x1700CF),
  (0x1700CF, .mov 64 (.reg .rdx) (.reg .r14), 0x1700D2),
  (0x1700D2, .mov 64 (.reg .rcx) (.imm 0x5), 0x1700D9),
  (0x1700D9, .lea .r8 .rsp 0x0, 0x1700DD),
  (0x1700DD, .call 0xB0000, 0x1700E2),
  (0x1700E2, .mov 64 (.reg .rdi) (.reg .rbx), 0x1700E5),
  (0x1700E5, .mov 64 (.reg .rsi) (.reg .rbp), 0x1700E8),
  (0x1700E8, .mov 64 (.reg .rdx) (.reg .r13), 0x1700EB),
  (0x1700EB, .mov 64 (.reg .rcx) (.reg .r14), 0x1700EE),
  (0x1700EE, .mov 64 (.reg .r8) (.imm 0x5), 0x1700F5),
  (0x1700F5, .mov 64 (.reg .r9) (.imm 0x8), 0x1700FC),
  (0x1700FC, .call 0xC0000, 0x170101),
  (0x170101, .add 64 (.reg .rsp) (.imm 0x28), 0x170105),
  (0x170105, .pop .r15, 0x170107),
  (0x170107, .pop .r14, 0x170109),
  (0x170109, .pop .r13, 0x17010B),
  (0x17010B, .pop .r12, 0x17010D),
  (0x17010D, .pop .rbp, 0x17010E),
  (0x17010E, .pop .rbx, 0x17010F),
  (0x17010F, .ret, 0x170110)
]

def pre0 : List (Nat × Instr × Nat) := KCode.table
def pre1 : List (Nat × Instr × Nat) := pre0 ++ Code_lroot.table
def pre2 : List (Nat × Instr × Nat) := pre1 ++ Code_ladd.table

/-- Every instruction of the program: the two kernels' (one/KCode.lean), `lroot`'s, `ladd`'s, then this function's. -/
def whole : List (Nat × Instr × Nat) := pre2 ++ table

def prog (pc : Nat) : Option (Instr × Nat) := whole.lookup pc

/-- The addresses the program has an instruction at. -/
def keys : List Nat := whole.map (·.1)

theorem keys_of : ∀ pc x, prog pc = some x → pc ∈ keys := fun pc x h => lookup_mem_keys whole pc x h

theorem has_kernels : ∀ pc x, KCode.prog pc = some x → prog pc = some x := by
  intro pc x h
  exact lookup_append_left pre2 table pc x (lookup_append_left pre1 Code_ladd.table pc x (lookup_append_left pre0 Code_lroot.table pc x (h)))

/-- `lroot`'s program is part of this one, unchanged. -/
theorem has_lroot : ∀ pc x, Code_lroot.prog pc = some x → prog pc = some x := by
  intro pc x h
  have h' : (KCode.table ++ Code_lroot.table).lookup pc = some x := h
  rw [lookup_append_or] at h'
  cases hk : KCode.table.lookup pc with
  | some y =>
    rw [hk] at h'; simp only [Option.some_or, Option.some.injEq] at h'; subst h'
    exact has_kernels pc y hk
  | none =>
    rw [hk] at h'; simp only [Option.none_or] at h'
    have apart : ∀ p ∈ Code_lroot.table.map (·.1), ((pre0.lookup p).isNone) = true := by decide +kernel
    have none := Option.isNone_iff_eq_none.mp (apart pc (lookup_mem_keys _ pc x h'))
    have here : pre1.lookup pc = some x := by
      show (pre0 ++ Code_lroot.table).lookup pc = some x
      rw [lookup_append_or, none]; exact h'
    exact lookup_append_left pre2 table pc x (lookup_append_left pre1 Code_ladd.table pc x (here))

/-- `ladd`'s program is part of this one, unchanged. -/
theorem has_ladd : ∀ pc x, Code_ladd.prog pc = some x → prog pc = some x := by
  intro pc x h
  have h' : (KCode.table ++ Code_ladd.table).lookup pc = some x := h
  rw [lookup_append_or] at h'
  cases hk : KCode.table.lookup pc with
  | some y =>
    rw [hk] at h'; simp only [Option.some_or, Option.some.injEq] at h'; subst h'
    exact has_kernels pc y hk
  | none =>
    rw [hk] at h'; simp only [Option.none_or] at h'
    have apart : ∀ p ∈ Code_ladd.table.map (·.1), ((pre1.lookup p).isNone) = true := by decide +kernel
    have none := Option.isNone_iff_eq_none.mp (apart pc (lookup_mem_keys _ pc x h'))
    have here : pre2.lookup pc = some x := by
      show (pre1 ++ Code_ladd.table).lookup pc = some x
      rw [lookup_append_or, none]; exact h'
    exact lookup_append_left pre2 table pc x (here)

@[ode_at] theorem at_170000 : prog 0x170000 = some (.push .rbx, 0x170001) := rfl
@[ode_at] theorem at_170001 : prog 0x170001 = some (.push .rbp, 0x170002) := rfl
@[ode_at] theorem at_170002 : prog 0x170002 = some (.push .r12, 0x170004) := rfl
@[ode_at] theorem at_170004 : prog 0x170004 = some (.push .r13, 0x170006) := rfl
@[ode_at] theorem at_170006 : prog 0x170006 = some (.push .r14, 0x170008) := rfl
@[ode_at] theorem at_170008 : prog 0x170008 = some (.push .r15, 0x17000A) := rfl
@[ode_at] theorem at_17000A : prog 0x17000A = some (.sub 64 (.reg .rsp) (.imm 0x28), 0x17000E) := rfl
@[ode_at] theorem at_17000E : prog 0x17000E = some (.mov 64 (.reg .rbx) (.reg .rdi), 0x170011) := rfl
@[ode_at] theorem at_170011 : prog 0x170011 = some (.mov 64 (.reg .rbp) (.reg .rsi), 0x170014) := rfl
@[ode_at] theorem at_170014 : prog 0x170014 = some (.mov 64 (.reg .r12) (.reg .rdx), 0x170017) := rfl
@[ode_at] theorem at_170017 : prog 0x170017 = some (.mov 64 (.reg .r13) (.reg .rcx), 0x17001A) := rfl
@[ode_at] theorem at_17001A : prog 0x17001A = some (.mov 64 (.reg .r14) (.reg .r8), 0x17001D) := rfl
@[ode_at] theorem at_17001D : prog 0x17001D = some (.mov 64 (.reg .r15) (.reg .r9), 0x170020) := rfl
@[ode_at] theorem at_170020 : prog 0x170020 = some (.mov 64 (.reg .rax) (.reg .r12), 0x170023) := rfl
@[ode_at] theorem at_170023 : prog 0x170023 = some (.add 64 (.reg .rax) (.imm 0x40), 0x170027) := rfl
@[ode_at] theorem at_170027 : prog 0x170027 = some (.mov 64 (.mem .rsp 0x20) (.reg .rax), 0x17002C) := rfl
@[ode_at] theorem at_17002C : prog 0x17002C = some (.mov 64 (.reg .rax) (.reg .r15), 0x17002F) := rfl
@[ode_at] theorem at_17002F : prog 0x17002F = some (.mov 64 (.reg .rcx) (.imm 0x0), 0x170036) := rfl
@[ode_at] theorem at_170036 : prog 0x170036 = some (.cmp 64 (.reg .rax) (.reg .rcx), 0x170039) := rfl
@[ode_at] theorem at_170039 : prog 0x170039 = some (.jne 0x17005F, 0x17003B) := rfl
@[ode_at] theorem at_17003B : prog 0x17003B = some (.mov 64 (.reg .rdi) (.reg .rbx), 0x17003E) := rfl
@[ode_at] theorem at_17003E : prog 0x17003E = some (.mov 64 (.reg .rsi) (.reg .r12), 0x170041) := rfl
@[ode_at] theorem at_170041 : prog 0x170041 = some (.mov 64 (.reg .rdx) (.reg .r13), 0x170044) := rfl
@[ode_at] theorem at_170044 : prog 0x170044 = some (.mov 64 (.reg .rcx) (.reg .r14), 0x170047) := rfl
@[ode_at] theorem at_170047 : prog 0x170047 = some (.mov 64 (.reg .r8) (.imm 0x5), 0x17004E) := rfl
@[ode_at] theorem at_17004E : prog 0x17004E = some (.mov 64 (.reg .r9) (.imm 0x8), 0x170055) := rfl
@[ode_at] theorem at_170055 : prog 0x170055 = some (.call 0xC0000, 0x17005A) := rfl
@[ode_at] theorem at_17005A : prog 0x17005A = some (.jmp 0x170101, 0x17005F) := rfl
@[ode_at] theorem at_17005F : prog 0x17005F = some (.mov 64 (.reg .rax) (.reg .r15), 0x170062) := rfl
@[ode_at] theorem at_170062 : prog 0x170062 = some (.mov 64 (.reg .rcx) (.imm 0x1), 0x170069) := rfl
@[ode_at] theorem at_170069 : prog 0x170069 = some (.cmp 64 (.reg .rax) (.reg .rcx), 0x17006C) := rfl
@[ode_at] theorem at_17006C : prog 0x17006C = some (.jne 0x1700A9, 0x17006E) := rfl
@[ode_at] theorem at_17006E : prog 0x17006E = some (.mov 64 (.reg .rdi) (.reg .rbp), 0x170071) := rfl
@[ode_at] theorem at_170071 : prog 0x170071 = some (.mov 64 (.reg .rsi) (.reg .r13), 0x170074) := rfl
@[ode_at] theorem at_170074 : prog 0x170074 = some (.mov 64 (.reg .rdx) (.reg .r14), 0x170077) := rfl
@[ode_at] theorem at_170077 : prog 0x170077 = some (.mov 64 (.reg .rcx) (.imm 0x5), 0x17007E) := rfl
@[ode_at] theorem at_17007E : prog 0x17007E = some (.mov 64 (.reg .r8) (.mem .rsp 0x20), 0x170083) := rfl
@[ode_at] theorem at_170083 : prog 0x170083 = some (.call 0xB0000, 0x170088) := rfl
@[ode_at] theorem at_170088 : prog 0x170088 = some (.mov 64 (.reg .rdi) (.reg .rbx), 0x17008B) := rfl
@[ode_at] theorem at_17008B : prog 0x17008B = some (.mov 64 (.reg .rsi) (.reg .rbp), 0x17008E) := rfl
@[ode_at] theorem at_17008E : prog 0x17008E = some (.mov 64 (.reg .rdx) (.reg .r13), 0x170091) := rfl
@[ode_at] theorem at_170091 : prog 0x170091 = some (.mov 64 (.reg .rcx) (.reg .r14), 0x170094) := rfl
@[ode_at] theorem at_170094 : prog 0x170094 = some (.mov 64 (.reg .r8) (.imm 0x5), 0x17009B) := rfl
@[ode_at] theorem at_17009B : prog 0x17009B = some (.mov 64 (.reg .r9) (.imm 0x8), 0x1700A2) := rfl
@[ode_at] theorem at_1700A2 : prog 0x1700A2 = some (.call 0xC0000, 0x1700A7) := rfl
@[ode_at] theorem at_1700A7 : prog 0x1700A7 = some (.jmp 0x170101, 0x1700A9) := rfl
@[ode_at] theorem at_1700A9 : prog 0x1700A9 = some (.lea .rdi .rsp 0x0, 0x1700AD) := rfl
@[ode_at] theorem at_1700AD : prog 0x1700AD = some (.mov 64 (.reg .rsi) (.reg .r12), 0x1700B0) := rfl
@[ode_at] theorem at_1700B0 : prog 0x1700B0 = some (.mov 64 (.reg .rdx) (.reg .r13), 0x1700B3) := rfl
@[ode_at] theorem at_1700B3 : prog 0x1700B3 = some (.mov 64 (.reg .rcx) (.reg .r14), 0x1700B6) := rfl
@[ode_at] theorem at_1700B6 : prog 0x1700B6 = some (.mov 64 (.reg .r8) (.imm 0x5), 0x1700BD) := rfl
@[ode_at] theorem at_1700BD : prog 0x1700BD = some (.mov 64 (.reg .r9) (.imm 0x0), 0x1700C4) := rfl
@[ode_at] theorem at_1700C4 : prog 0x1700C4 = some (.call 0xC0000, 0x1700C9) := rfl
@[ode_at] theorem at_1700C9 : prog 0x1700C9 = some (.mov 64 (.reg .rdi) (.reg .rbp), 0x1700CC) := rfl
@[ode_at] theorem at_1700CC : prog 0x1700CC = some (.mov 64 (.reg .rsi) (.reg .r13), 0x1700CF) := rfl
@[ode_at] theorem at_1700CF : prog 0x1700CF = some (.mov 64 (.reg .rdx) (.reg .r14), 0x1700D2) := rfl
@[ode_at] theorem at_1700D2 : prog 0x1700D2 = some (.mov 64 (.reg .rcx) (.imm 0x5), 0x1700D9) := rfl
@[ode_at] theorem at_1700D9 : prog 0x1700D9 = some (.lea .r8 .rsp 0x0, 0x1700DD) := rfl
@[ode_at] theorem at_1700DD : prog 0x1700DD = some (.call 0xB0000, 0x1700E2) := rfl
@[ode_at] theorem at_1700E2 : prog 0x1700E2 = some (.mov 64 (.reg .rdi) (.reg .rbx), 0x1700E5) := rfl
@[ode_at] theorem at_1700E5 : prog 0x1700E5 = some (.mov 64 (.reg .rsi) (.reg .rbp), 0x1700E8) := rfl
@[ode_at] theorem at_1700E8 : prog 0x1700E8 = some (.mov 64 (.reg .rdx) (.reg .r13), 0x1700EB) := rfl
@[ode_at] theorem at_1700EB : prog 0x1700EB = some (.mov 64 (.reg .rcx) (.reg .r14), 0x1700EE) := rfl
@[ode_at] theorem at_1700EE : prog 0x1700EE = some (.mov 64 (.reg .r8) (.imm 0x5), 0x1700F5) := rfl
@[ode_at] theorem at_1700F5 : prog 0x1700F5 = some (.mov 64 (.reg .r9) (.imm 0x8), 0x1700FC) := rfl
@[ode_at] theorem at_1700FC : prog 0x1700FC = some (.call 0xC0000, 0x170101) := rfl
@[ode_at] theorem at_170101 : prog 0x170101 = some (.add 64 (.reg .rsp) (.imm 0x28), 0x170105) := rfl
@[ode_at] theorem at_170105 : prog 0x170105 = some (.pop .r15, 0x170107) := rfl
@[ode_at] theorem at_170107 : prog 0x170107 = some (.pop .r14, 0x170109) := rfl
@[ode_at] theorem at_170109 : prog 0x170109 = some (.pop .r13, 0x17010B) := rfl
@[ode_at] theorem at_17010B : prog 0x17010B = some (.pop .r12, 0x17010D) := rfl
@[ode_at] theorem at_17010D : prog 0x17010D = some (.pop .rbp, 0x17010E) := rfl
@[ode_at] theorem at_17010E : prog 0x17010E = some (.pop .rbx, 0x17010F) := rfl
@[ode_at] theorem at_17010F : prog 0x17010F = some (.ret, 0x170110) := rfl

end Code_finish
