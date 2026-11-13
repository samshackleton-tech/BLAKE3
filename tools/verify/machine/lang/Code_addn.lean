import Machine
import KCode
import Cells
import Code_ladd
open X86

/-! `addn` as assembled: 41 instructions. Written from the lifter's rows. -/

set_option maxRecDepth 100000
namespace Code_addn

def table : List (Nat × Instr × Nat) := [
  (0x160000, .push .rbx, 0x160001),
  (0x160001, .push .rbp, 0x160002),
  (0x160002, .push .r12, 0x160004),
  (0x160004, .push .r13, 0x160006),
  (0x160006, .push .r14, 0x160008),
  (0x160008, .push .r15, 0x16000A),
  (0x16000A, .sub 64 (.reg .rsp) (.imm 0x8), 0x16000E),
  (0x16000E, .mov 64 (.reg .r12) (.reg .rdi), 0x160011),
  (0x160011, .mov 64 (.reg .r13) (.reg .rsi), 0x160014),
  (0x160014, .mov 64 (.reg .r14) (.reg .rdx), 0x160017),
  (0x160017, .mov 64 (.mem .rsp 0x0) (.reg .rcx), 0x16001B),
  (0x16001B, .mov 64 (.reg .r15) (.reg .r8), 0x16001E),
  (0x16001E, .mov 64 (.reg .rax) (.imm 0x0), 0x160025),
  (0x160025, .mov 64 (.reg .rbx) (.reg .rax), 0x160028),
  (0x160028, .mov 64 (.reg .rax) (.mem .rsp 0x0), 0x16002C),
  (0x16002C, .mov 64 (.reg .rbp) (.reg .rax), 0x16002F),
  (0x16002F, .mov 64 (.reg .rax) (.reg .rbx), 0x160032),
  (0x160032, .mov 64 (.reg .rcx) (.reg .r15), 0x160035),
  (0x160035, .cmp 64 (.reg .rax) (.reg .rcx), 0x160038),
  (0x160038, .jae 0x160068, 0x16003A),
  (0x16003A, .mov 64 (.reg .rdi) (.reg .r12), 0x16003D),
  (0x16003D, .mov 64 (.reg .rsi) (.reg .r13), 0x160040),
  (0x160040, .mov 64 (.reg .rdx) (.reg .r14), 0x160043),
  (0x160043, .mov 64 (.reg .rcx) (.imm 0x5), 0x16004A),
  (0x16004A, .mov 64 (.reg .r8) (.reg .rbp), 0x16004D),
  (0x16004D, .call 0xB0000, 0x160052),
  (0x160052, .mov 64 (.reg .rax) (.reg .rbp), 0x160055),
  (0x160055, .add 64 (.reg .rax) (.imm 0x20), 0x160059),
  (0x160059, .mov 64 (.reg .rbp) (.reg .rax), 0x16005C),
  (0x16005C, .mov 64 (.reg .rax) (.reg .rbx), 0x16005F),
  (0x16005F, .add 64 (.reg .rax) (.imm 0x1), 0x160063),
  (0x160063, .mov 64 (.reg .rbx) (.reg .rax), 0x160066),
  (0x160066, .jmp 0x16002F, 0x160068),
  (0x160068, .add 64 (.reg .rsp) (.imm 0x8), 0x16006C),
  (0x16006C, .pop .r15, 0x16006E),
  (0x16006E, .pop .r14, 0x160070),
  (0x160070, .pop .r13, 0x160072),
  (0x160072, .pop .r12, 0x160074),
  (0x160074, .pop .rbp, 0x160075),
  (0x160075, .pop .rbx, 0x160076),
  (0x160076, .ret, 0x160077)
]

def pre0 : List (Nat × Instr × Nat) := KCode.table
def pre1 : List (Nat × Instr × Nat) := pre0 ++ Code_ladd.table

/-- Every instruction of the program: the two kernels' (one/KCode.lean), `ladd`'s, then this function's. -/
def whole : List (Nat × Instr × Nat) := pre1 ++ table

def prog (pc : Nat) : Option (Instr × Nat) := whole.lookup pc

/-- The addresses the program has an instruction at. -/
def keys : List Nat := whole.map (·.1)

theorem keys_of : ∀ pc x, prog pc = some x → pc ∈ keys := fun pc x h => lookup_mem_keys whole pc x h

theorem has_kernels : ∀ pc x, KCode.prog pc = some x → prog pc = some x := by
  intro pc x h
  exact lookup_append_left pre1 table pc x (lookup_append_left pre0 Code_ladd.table pc x (h))

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
    have apart : ∀ p ∈ Code_ladd.table.map (·.1), ((pre0.lookup p).isNone) = true := by decide +kernel
    have none := Option.isNone_iff_eq_none.mp (apart pc (lookup_mem_keys _ pc x h'))
    have here : pre1.lookup pc = some x := by
      show (pre0 ++ Code_ladd.table).lookup pc = some x
      rw [lookup_append_or, none]; exact h'
    exact lookup_append_left pre1 table pc x (here)

@[ode_at] theorem at_160000 : prog 0x160000 = some (.push .rbx, 0x160001) := rfl
@[ode_at] theorem at_160001 : prog 0x160001 = some (.push .rbp, 0x160002) := rfl
@[ode_at] theorem at_160002 : prog 0x160002 = some (.push .r12, 0x160004) := rfl
@[ode_at] theorem at_160004 : prog 0x160004 = some (.push .r13, 0x160006) := rfl
@[ode_at] theorem at_160006 : prog 0x160006 = some (.push .r14, 0x160008) := rfl
@[ode_at] theorem at_160008 : prog 0x160008 = some (.push .r15, 0x16000A) := rfl
@[ode_at] theorem at_16000A : prog 0x16000A = some (.sub 64 (.reg .rsp) (.imm 0x8), 0x16000E) := rfl
@[ode_at] theorem at_16000E : prog 0x16000E = some (.mov 64 (.reg .r12) (.reg .rdi), 0x160011) := rfl
@[ode_at] theorem at_160011 : prog 0x160011 = some (.mov 64 (.reg .r13) (.reg .rsi), 0x160014) := rfl
@[ode_at] theorem at_160014 : prog 0x160014 = some (.mov 64 (.reg .r14) (.reg .rdx), 0x160017) := rfl
@[ode_at] theorem at_160017 : prog 0x160017 = some (.mov 64 (.mem .rsp 0x0) (.reg .rcx), 0x16001B) := rfl
@[ode_at] theorem at_16001B : prog 0x16001B = some (.mov 64 (.reg .r15) (.reg .r8), 0x16001E) := rfl
@[ode_at] theorem at_16001E : prog 0x16001E = some (.mov 64 (.reg .rax) (.imm 0x0), 0x160025) := rfl
@[ode_at] theorem at_160025 : prog 0x160025 = some (.mov 64 (.reg .rbx) (.reg .rax), 0x160028) := rfl
@[ode_at] theorem at_160028 : prog 0x160028 = some (.mov 64 (.reg .rax) (.mem .rsp 0x0), 0x16002C) := rfl
@[ode_at] theorem at_16002C : prog 0x16002C = some (.mov 64 (.reg .rbp) (.reg .rax), 0x16002F) := rfl
@[ode_at] theorem at_16002F : prog 0x16002F = some (.mov 64 (.reg .rax) (.reg .rbx), 0x160032) := rfl
@[ode_at] theorem at_160032 : prog 0x160032 = some (.mov 64 (.reg .rcx) (.reg .r15), 0x160035) := rfl
@[ode_at] theorem at_160035 : prog 0x160035 = some (.cmp 64 (.reg .rax) (.reg .rcx), 0x160038) := rfl
@[ode_at] theorem at_160038 : prog 0x160038 = some (.jae 0x160068, 0x16003A) := rfl
@[ode_at] theorem at_16003A : prog 0x16003A = some (.mov 64 (.reg .rdi) (.reg .r12), 0x16003D) := rfl
@[ode_at] theorem at_16003D : prog 0x16003D = some (.mov 64 (.reg .rsi) (.reg .r13), 0x160040) := rfl
@[ode_at] theorem at_160040 : prog 0x160040 = some (.mov 64 (.reg .rdx) (.reg .r14), 0x160043) := rfl
@[ode_at] theorem at_160043 : prog 0x160043 = some (.mov 64 (.reg .rcx) (.imm 0x5), 0x16004A) := rfl
@[ode_at] theorem at_16004A : prog 0x16004A = some (.mov 64 (.reg .r8) (.reg .rbp), 0x16004D) := rfl
@[ode_at] theorem at_16004D : prog 0x16004D = some (.call 0xB0000, 0x160052) := rfl
@[ode_at] theorem at_160052 : prog 0x160052 = some (.mov 64 (.reg .rax) (.reg .rbp), 0x160055) := rfl
@[ode_at] theorem at_160055 : prog 0x160055 = some (.add 64 (.reg .rax) (.imm 0x20), 0x160059) := rfl
@[ode_at] theorem at_160059 : prog 0x160059 = some (.mov 64 (.reg .rbp) (.reg .rax), 0x16005C) := rfl
@[ode_at] theorem at_16005C : prog 0x16005C = some (.mov 64 (.reg .rax) (.reg .rbx), 0x16005F) := rfl
@[ode_at] theorem at_16005F : prog 0x16005F = some (.add 64 (.reg .rax) (.imm 0x1), 0x160063) := rfl
@[ode_at] theorem at_160063 : prog 0x160063 = some (.mov 64 (.reg .rbx) (.reg .rax), 0x160066) := rfl
@[ode_at] theorem at_160066 : prog 0x160066 = some (.jmp 0x16002F, 0x160068) := rfl
@[ode_at] theorem at_160068 : prog 0x160068 = some (.add 64 (.reg .rsp) (.imm 0x8), 0x16006C) := rfl
@[ode_at] theorem at_16006C : prog 0x16006C = some (.pop .r15, 0x16006E) := rfl
@[ode_at] theorem at_16006E : prog 0x16006E = some (.pop .r14, 0x160070) := rfl
@[ode_at] theorem at_160070 : prog 0x160070 = some (.pop .r13, 0x160072) := rfl
@[ode_at] theorem at_160072 : prog 0x160072 = some (.pop .r12, 0x160074) := rfl
@[ode_at] theorem at_160074 : prog 0x160074 = some (.pop .rbp, 0x160075) := rfl
@[ode_at] theorem at_160075 : prog 0x160075 = some (.pop .rbx, 0x160076) := rfl
@[ode_at] theorem at_160076 : prog 0x160076 = some (.ret, 0x160077) := rfl

end Code_addn
