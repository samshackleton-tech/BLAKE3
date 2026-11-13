import Machine
import KCode
import Cells
import Code_fillp
import Code_tree32
import Code_ladd
open X86

/-! `wide` as assembled: 70 instructions. Written from the lifter's rows. -/

set_option maxRecDepth 100000
namespace Code_wide

def table : List (Nat × Instr × Nat) := [
  (0x130000, .push .rbx, 0x130001),
  (0x130001, .push .rbp, 0x130002),
  (0x130002, .push .r12, 0x130004),
  (0x130004, .push .r13, 0x130006),
  (0x130006, .push .r14, 0x130008),
  (0x130008, .push .r15, 0x13000A),
  (0x13000A, .sub 64 (.reg .rsp) (.imm 0x718), 0x130011),
  (0x130011, .mov 64 (.reg .r13) (.reg .rdi), 0x130014),
  (0x130014, .mov 64 (.mem .rsp 0x700) (.reg .rsi), 0x13001C),
  (0x13001C, .mov 64 (.mem .rsp 0x708) (.reg .rdx), 0x130024),
  (0x130024, .mov 64 (.reg .r14) (.reg .rcx), 0x130027),
  (0x130027, .mov 64 (.reg .r15) (.reg .r8), 0x13002A),
  (0x13002A, .mov 64 (.reg .rax) (.reg .r15), 0x13002D),
  (0x13002D, .or 64 (.reg .rax) (.imm 0x40020100), 0x130033),
  (0x130033, .mov 64 (.mem .rsp 0x710) (.reg .rax), 0x13003B),
  (0x13003B, .mov 64 (.reg .rax) (.imm 0x0), 0x130042),
  (0x130042, .mov 64 (.reg .rcx) (.reg .r13), 0x130045),
  (0x130045, .mov 64 (.mem .rcx 0x0) (.reg .rax), 0x130048),
  (0x130048, .mov 64 (.reg .rax) (.mem .rsp 0x700), 0x130050),
  (0x130050, .mov 64 (.reg .rbx) (.reg .rax), 0x130053),
  (0x130053, .mov 64 (.reg .rax) (.mem .rsp 0x708), 0x13005B),
  (0x13005B, .mov 64 (.reg .rbp) (.reg .rax), 0x13005E),
  (0x13005E, .mov 64 (.reg .rax) (.imm 0x0), 0x130065),
  (0x130065, .mov 64 (.reg .r12) (.reg .rax), 0x130068),
  (0x130068, .mov 64 (.reg .rax) (.imm 0x8000), 0x13006F),
  (0x13006F, .mov 64 (.reg .rcx) (.reg .rbp), 0x130072),
  (0x130072, .cmp 64 (.reg .rax) (.reg .rcx), 0x130075),
  (0x130075, .jae 0x13011A, 0x13007B),
  (0x13007B, .lea .rdi .rsp 0x0, 0x13007F),
  (0x13007F, .mov 64 (.reg .rsi) (.reg .rbx), 0x130082),
  (0x130082, .mov 64 (.reg .rdx) (.imm 0x20), 0x130089),
  (0x130089, .mov 64 (.reg .rcx) (.imm 0x400), 0x130090),
  (0x130090, .call 0x110000, 0x130095),
  (0x130095, .lea .rdi .rsp 0x0, 0x130099),
  (0x130099, .mov 64 (.reg .rsi) (.imm 0x10), 0x1300A0),
  (0x1300A0, .mov 64 (.reg .rdx) (.reg .r14), 0x1300A3),
  (0x1300A3, .mov 64 (.reg .rcx) (.reg .r12), 0x1300A6),
  (0x1300A6, .mov 64 (.reg .r8) (.mem .rsp 0x710), 0x1300AE),
  (0x1300AE, .lea .r9 .rsp 0x100, 0x1300B6),
  (0x1300B6, .call 0x10000, 0x1300BB),
  (0x1300BB, .lea .rdi .rsp 0x500, 0x1300C3),
  (0x1300C3, .lea .rsi .rsp 0x100, 0x1300CB),
  (0x1300CB, .mov 64 (.reg .rdx) (.reg .r14), 0x1300CE),
  (0x1300CE, .mov 64 (.reg .rcx) (.reg .r15), 0x1300D1),
  (0x1300D1, .call 0x120000, 0x1300D6),
  (0x1300D6, .mov 64 (.reg .rdi) (.reg .r13), 0x1300D9),
  (0x1300D9, .mov 64 (.reg .rsi) (.reg .r14), 0x1300DC),
  (0x1300DC, .mov 64 (.reg .rdx) (.reg .r15), 0x1300DF),
  (0x1300DF, .mov 64 (.reg .rcx) (.imm 0x5), 0x1300E6),
  (0x1300E6, .lea .r8 .rsp 0x500, 0x1300EE),
  (0x1300EE, .call 0xB0000, 0x1300F3),
  (0x1300F3, .mov 64 (.reg .rax) (.reg .rbx), 0x1300F6),
  (0x1300F6, .add 64 (.reg .rax) (.imm 0x8000), 0x1300FC),
  (0x1300FC, .mov 64 (.reg .rbx) (.reg .rax), 0x1300FF),
  (0x1300FF, .mov 64 (.reg .rax) (.reg .rbp), 0x130102),
  (0x130102, .sub 64 (.reg .rax) (.imm 0x8000), 0x130108),
  (0x130108, .mov 64 (.reg .rbp) (.reg .rax), 0x13010B),
  (0x13010B, .mov 64 (.reg .rax) (.reg .r12), 0x13010E),
  (0x13010E, .add 64 (.reg .rax) (.imm 0x20), 0x130112),
  (0x130112, .mov 64 (.reg .r12) (.reg .rax), 0x130115),
  (0x130115, .jmp 0x130068, 0x13011A),
  (0x13011A, .mov 64 (.reg .rax) (.reg .r12), 0x13011D),
  (0x13011D, .add 64 (.reg .rsp) (.imm 0x718), 0x130124),
  (0x130124, .pop .r15, 0x130126),
  (0x130126, .pop .r14, 0x130128),
  (0x130128, .pop .r13, 0x13012A),
  (0x13012A, .pop .r12, 0x13012C),
  (0x13012C, .pop .rbp, 0x13012D),
  (0x13012D, .pop .rbx, 0x13012E),
  (0x13012E, .ret, 0x13012F)
]

def pre0 : List (Nat × Instr × Nat) := KCode.table
def pre1 : List (Nat × Instr × Nat) := pre0 ++ Code_fillp.table
def pre2 : List (Nat × Instr × Nat) := pre1 ++ Code_tree32.table
def pre3 : List (Nat × Instr × Nat) := pre2 ++ Code_ladd.table

/-- Every instruction of the program: the two kernels' (one/KCode.lean), `fillp`'s, `tree32`'s, `ladd`'s, then this function's. -/
def whole : List (Nat × Instr × Nat) := pre3 ++ table

def prog (ext : Nat → Option (Instr × Nat)) (pc : Nat) : Option (Instr × Nat) := (whole.lookup pc).or (ext pc)

/-- What this table holds, the program holds, whatever else it holds. -/
theorem prog_of (ext : Nat → Option (Instr × Nat)) : ∀ pc x, whole.lookup pc = some x → prog ext pc = some x := by
  intro pc x h; simp only [prog, h, Option.some_or]

theorem has_kernels (ext : Nat → Option (Instr × Nat)) : ∀ pc x, KCode.prog pc = some x → prog ext pc = some x := by
  intro pc x h
  exact prog_of ext pc x (lookup_append_left pre3 table pc x (lookup_append_left pre2 Code_ladd.table pc x (lookup_append_left pre1 Code_tree32.table pc x (lookup_append_left pre0 Code_fillp.table pc x (h)))))

/-- `fillp`'s own instructions are in this program: no table before them has one at any of their addresses. -/
theorem in1 (ext : Nat → Option (Instr × Nat)) : ∀ pc x, Code_fillp.table.lookup pc = some x → prog ext pc = some x := by
  intro pc x h
  have apart : ∀ p ∈ Code_fillp.table.map (·.1), ((pre0.lookup p).isNone) = true := by decide +kernel
  have none := Option.isNone_iff_eq_none.mp (apart pc (lookup_mem_keys _ pc x h))
  have here : pre1.lookup pc = some x := by
    show (pre0 ++ Code_fillp.table).lookup pc = some x
    rw [lookup_append_or, none]; exact h
  exact prog_of ext pc x (lookup_append_left pre3 table pc x (lookup_append_left pre2 Code_ladd.table pc x (lookup_append_left pre1 Code_tree32.table pc x (here))))

/-- `tree32`'s own instructions are in this program: no table before them has one at any of their addresses. -/
theorem in2 (ext : Nat → Option (Instr × Nat)) : ∀ pc x, Code_tree32.table.lookup pc = some x → prog ext pc = some x := by
  intro pc x h
  have apart : ∀ p ∈ Code_tree32.table.map (·.1), ((pre1.lookup p).isNone) = true := by decide +kernel
  have none := Option.isNone_iff_eq_none.mp (apart pc (lookup_mem_keys _ pc x h))
  have here : pre2.lookup pc = some x := by
    show (pre1 ++ Code_tree32.table).lookup pc = some x
    rw [lookup_append_or, none]; exact h
  exact prog_of ext pc x (lookup_append_left pre3 table pc x (lookup_append_left pre2 Code_ladd.table pc x (here)))

/-- `ladd`'s own instructions are in this program: no table before them has one at any of their addresses. -/
theorem in3 (ext : Nat → Option (Instr × Nat)) : ∀ pc x, Code_ladd.table.lookup pc = some x → prog ext pc = some x := by
  intro pc x h
  have apart : ∀ p ∈ Code_ladd.table.map (·.1), ((pre2.lookup p).isNone) = true := by decide +kernel
  have none := Option.isNone_iff_eq_none.mp (apart pc (lookup_mem_keys _ pc x h))
  have here : pre3.lookup pc = some x := by
    show (pre2 ++ Code_ladd.table).lookup pc = some x
    rw [lookup_append_or, none]; exact h
  exact prog_of ext pc x (lookup_append_left pre3 table pc x (here))

/-- The tables of `tree32`'s program (its own instructions and those of what it calls) are in this one, unchanged. -/
theorem tables_tree32 (ext : Nat → Option (Instr × Nat)) : ∀ pc x, (KCode.table ++ Code_fillp.table ++ Code_tree32.table).lookup pc = some x → prog ext pc = some x := by
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
      exact in2 ext pc x h'

/-- `tree32`'s program over this one is this one: a theorem about `tree32` over any program holds here. -/
theorem has_tree32 (ext : Nat → Option (Instr × Nat)) : ∀ pc x, Code_tree32.prog (prog ext) pc = some x → prog ext pc = some x := by
  intro pc x h
  have h0 : ((KCode.table ++ Code_fillp.table ++ Code_tree32.table).lookup pc).or (prog ext pc) = some x := h
  cases hw : (KCode.table ++ Code_fillp.table ++ Code_tree32.table).lookup pc with
  | none => rw [hw] at h0; simpa only [Option.none_or] using h0
  | some y =>
    rw [hw] at h0; simp only [Option.some_or, Option.some.injEq] at h0; subst h0
    exact tables_tree32 ext pc y hw

/-- And this program is `tree32`'s over it: what is assumed of this program holds of that one. -/
theorem over_tree32 (ext : Nat → Option (Instr × Nat)) : ∀ pc x, prog ext pc = some x → Code_tree32.prog (prog ext) pc = some x := by
  intro pc x h
  show ((KCode.table ++ Code_fillp.table ++ Code_tree32.table).lookup pc).or (prog ext pc) = some x
  cases hw : (KCode.table ++ Code_fillp.table ++ Code_tree32.table).lookup pc with
  | none => simpa only [Option.none_or] using h
  | some y =>
    have e := tables_tree32 ext pc y hw
    rw [h] at e; rw [Option.some_or]; exact e.symm

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
    exact in3 ext pc x h'

/-- `ladd`'s program (its own instructions and those of what it calls) is part of this one, unchanged. -/
theorem has_ladd (ext : Nat → Option (Instr × Nat)) : ∀ pc x, Code_ladd.prog pc = some x → prog ext pc = some x :=
  fun pc x h => tables_ladd ext pc x h

/-- The tables of `fillp`'s program (its own instructions and those of what it calls) are in this one, unchanged. -/
theorem tables_fillp (ext : Nat → Option (Instr × Nat)) : ∀ pc x, (Code_fillp.table).lookup pc = some x → prog ext pc = some x := by
  intro pc x h'
  exact in1 ext pc x h'

/-- `fillp`'s program (its own instructions and those of what it calls) is part of this one, unchanged. -/
theorem has_fillp (ext : Nat → Option (Instr × Nat)) : ∀ pc x, Code_fillp.prog pc = some x → prog ext pc = some x :=
  fun pc x h => tables_fillp ext pc x h

@[ode_at] theorem at_130000 (ext : Nat → Option (Instr × Nat)) : prog ext 0x130000 = some (.push .rbx, 0x130001) := rfl
@[ode_at] theorem at_130001 (ext : Nat → Option (Instr × Nat)) : prog ext 0x130001 = some (.push .rbp, 0x130002) := rfl
@[ode_at] theorem at_130002 (ext : Nat → Option (Instr × Nat)) : prog ext 0x130002 = some (.push .r12, 0x130004) := rfl
@[ode_at] theorem at_130004 (ext : Nat → Option (Instr × Nat)) : prog ext 0x130004 = some (.push .r13, 0x130006) := rfl
@[ode_at] theorem at_130006 (ext : Nat → Option (Instr × Nat)) : prog ext 0x130006 = some (.push .r14, 0x130008) := rfl
@[ode_at] theorem at_130008 (ext : Nat → Option (Instr × Nat)) : prog ext 0x130008 = some (.push .r15, 0x13000A) := rfl
@[ode_at] theorem at_13000A (ext : Nat → Option (Instr × Nat)) : prog ext 0x13000A = some (.sub 64 (.reg .rsp) (.imm 0x718), 0x130011) := rfl
@[ode_at] theorem at_130011 (ext : Nat → Option (Instr × Nat)) : prog ext 0x130011 = some (.mov 64 (.reg .r13) (.reg .rdi), 0x130014) := rfl
@[ode_at] theorem at_130014 (ext : Nat → Option (Instr × Nat)) : prog ext 0x130014 = some (.mov 64 (.mem .rsp 0x700) (.reg .rsi), 0x13001C) := rfl
@[ode_at] theorem at_13001C (ext : Nat → Option (Instr × Nat)) : prog ext 0x13001C = some (.mov 64 (.mem .rsp 0x708) (.reg .rdx), 0x130024) := rfl
@[ode_at] theorem at_130024 (ext : Nat → Option (Instr × Nat)) : prog ext 0x130024 = some (.mov 64 (.reg .r14) (.reg .rcx), 0x130027) := rfl
@[ode_at] theorem at_130027 (ext : Nat → Option (Instr × Nat)) : prog ext 0x130027 = some (.mov 64 (.reg .r15) (.reg .r8), 0x13002A) := rfl
@[ode_at] theorem at_13002A (ext : Nat → Option (Instr × Nat)) : prog ext 0x13002A = some (.mov 64 (.reg .rax) (.reg .r15), 0x13002D) := rfl
@[ode_at] theorem at_13002D (ext : Nat → Option (Instr × Nat)) : prog ext 0x13002D = some (.or 64 (.reg .rax) (.imm 0x40020100), 0x130033) := rfl
@[ode_at] theorem at_130033 (ext : Nat → Option (Instr × Nat)) : prog ext 0x130033 = some (.mov 64 (.mem .rsp 0x710) (.reg .rax), 0x13003B) := rfl
@[ode_at] theorem at_13003B (ext : Nat → Option (Instr × Nat)) : prog ext 0x13003B = some (.mov 64 (.reg .rax) (.imm 0x0), 0x130042) := rfl
@[ode_at] theorem at_130042 (ext : Nat → Option (Instr × Nat)) : prog ext 0x130042 = some (.mov 64 (.reg .rcx) (.reg .r13), 0x130045) := rfl
@[ode_at] theorem at_130045 (ext : Nat → Option (Instr × Nat)) : prog ext 0x130045 = some (.mov 64 (.mem .rcx 0x0) (.reg .rax), 0x130048) := rfl
@[ode_at] theorem at_130048 (ext : Nat → Option (Instr × Nat)) : prog ext 0x130048 = some (.mov 64 (.reg .rax) (.mem .rsp 0x700), 0x130050) := rfl
@[ode_at] theorem at_130050 (ext : Nat → Option (Instr × Nat)) : prog ext 0x130050 = some (.mov 64 (.reg .rbx) (.reg .rax), 0x130053) := rfl
@[ode_at] theorem at_130053 (ext : Nat → Option (Instr × Nat)) : prog ext 0x130053 = some (.mov 64 (.reg .rax) (.mem .rsp 0x708), 0x13005B) := rfl
@[ode_at] theorem at_13005B (ext : Nat → Option (Instr × Nat)) : prog ext 0x13005B = some (.mov 64 (.reg .rbp) (.reg .rax), 0x13005E) := rfl
@[ode_at] theorem at_13005E (ext : Nat → Option (Instr × Nat)) : prog ext 0x13005E = some (.mov 64 (.reg .rax) (.imm 0x0), 0x130065) := rfl
@[ode_at] theorem at_130065 (ext : Nat → Option (Instr × Nat)) : prog ext 0x130065 = some (.mov 64 (.reg .r12) (.reg .rax), 0x130068) := rfl
@[ode_at] theorem at_130068 (ext : Nat → Option (Instr × Nat)) : prog ext 0x130068 = some (.mov 64 (.reg .rax) (.imm 0x8000), 0x13006F) := rfl
@[ode_at] theorem at_13006F (ext : Nat → Option (Instr × Nat)) : prog ext 0x13006F = some (.mov 64 (.reg .rcx) (.reg .rbp), 0x130072) := rfl
@[ode_at] theorem at_130072 (ext : Nat → Option (Instr × Nat)) : prog ext 0x130072 = some (.cmp 64 (.reg .rax) (.reg .rcx), 0x130075) := rfl
@[ode_at] theorem at_130075 (ext : Nat → Option (Instr × Nat)) : prog ext 0x130075 = some (.jae 0x13011A, 0x13007B) := rfl
@[ode_at] theorem at_13007B (ext : Nat → Option (Instr × Nat)) : prog ext 0x13007B = some (.lea .rdi .rsp 0x0, 0x13007F) := rfl
@[ode_at] theorem at_13007F (ext : Nat → Option (Instr × Nat)) : prog ext 0x13007F = some (.mov 64 (.reg .rsi) (.reg .rbx), 0x130082) := rfl
@[ode_at] theorem at_130082 (ext : Nat → Option (Instr × Nat)) : prog ext 0x130082 = some (.mov 64 (.reg .rdx) (.imm 0x20), 0x130089) := rfl
@[ode_at] theorem at_130089 (ext : Nat → Option (Instr × Nat)) : prog ext 0x130089 = some (.mov 64 (.reg .rcx) (.imm 0x400), 0x130090) := rfl
@[ode_at] theorem at_130090 (ext : Nat → Option (Instr × Nat)) : prog ext 0x130090 = some (.call 0x110000, 0x130095) := rfl
@[ode_at] theorem at_130095 (ext : Nat → Option (Instr × Nat)) : prog ext 0x130095 = some (.lea .rdi .rsp 0x0, 0x130099) := rfl
@[ode_at] theorem at_130099 (ext : Nat → Option (Instr × Nat)) : prog ext 0x130099 = some (.mov 64 (.reg .rsi) (.imm 0x10), 0x1300A0) := rfl
@[ode_at] theorem at_1300A0 (ext : Nat → Option (Instr × Nat)) : prog ext 0x1300A0 = some (.mov 64 (.reg .rdx) (.reg .r14), 0x1300A3) := rfl
@[ode_at] theorem at_1300A3 (ext : Nat → Option (Instr × Nat)) : prog ext 0x1300A3 = some (.mov 64 (.reg .rcx) (.reg .r12), 0x1300A6) := rfl
@[ode_at] theorem at_1300A6 (ext : Nat → Option (Instr × Nat)) : prog ext 0x1300A6 = some (.mov 64 (.reg .r8) (.mem .rsp 0x710), 0x1300AE) := rfl
@[ode_at] theorem at_1300AE (ext : Nat → Option (Instr × Nat)) : prog ext 0x1300AE = some (.lea .r9 .rsp 0x100, 0x1300B6) := rfl
@[ode_at] theorem at_1300B6 (ext : Nat → Option (Instr × Nat)) : prog ext 0x1300B6 = some (.call 0x10000, 0x1300BB) := rfl
@[ode_at] theorem at_1300BB (ext : Nat → Option (Instr × Nat)) : prog ext 0x1300BB = some (.lea .rdi .rsp 0x500, 0x1300C3) := rfl
@[ode_at] theorem at_1300C3 (ext : Nat → Option (Instr × Nat)) : prog ext 0x1300C3 = some (.lea .rsi .rsp 0x100, 0x1300CB) := rfl
@[ode_at] theorem at_1300CB (ext : Nat → Option (Instr × Nat)) : prog ext 0x1300CB = some (.mov 64 (.reg .rdx) (.reg .r14), 0x1300CE) := rfl
@[ode_at] theorem at_1300CE (ext : Nat → Option (Instr × Nat)) : prog ext 0x1300CE = some (.mov 64 (.reg .rcx) (.reg .r15), 0x1300D1) := rfl
@[ode_at] theorem at_1300D1 (ext : Nat → Option (Instr × Nat)) : prog ext 0x1300D1 = some (.call 0x120000, 0x1300D6) := rfl
@[ode_at] theorem at_1300D6 (ext : Nat → Option (Instr × Nat)) : prog ext 0x1300D6 = some (.mov 64 (.reg .rdi) (.reg .r13), 0x1300D9) := rfl
@[ode_at] theorem at_1300D9 (ext : Nat → Option (Instr × Nat)) : prog ext 0x1300D9 = some (.mov 64 (.reg .rsi) (.reg .r14), 0x1300DC) := rfl
@[ode_at] theorem at_1300DC (ext : Nat → Option (Instr × Nat)) : prog ext 0x1300DC = some (.mov 64 (.reg .rdx) (.reg .r15), 0x1300DF) := rfl
@[ode_at] theorem at_1300DF (ext : Nat → Option (Instr × Nat)) : prog ext 0x1300DF = some (.mov 64 (.reg .rcx) (.imm 0x5), 0x1300E6) := rfl
@[ode_at] theorem at_1300E6 (ext : Nat → Option (Instr × Nat)) : prog ext 0x1300E6 = some (.lea .r8 .rsp 0x500, 0x1300EE) := rfl
@[ode_at] theorem at_1300EE (ext : Nat → Option (Instr × Nat)) : prog ext 0x1300EE = some (.call 0xB0000, 0x1300F3) := rfl
@[ode_at] theorem at_1300F3 (ext : Nat → Option (Instr × Nat)) : prog ext 0x1300F3 = some (.mov 64 (.reg .rax) (.reg .rbx), 0x1300F6) := rfl
@[ode_at] theorem at_1300F6 (ext : Nat → Option (Instr × Nat)) : prog ext 0x1300F6 = some (.add 64 (.reg .rax) (.imm 0x8000), 0x1300FC) := rfl
@[ode_at] theorem at_1300FC (ext : Nat → Option (Instr × Nat)) : prog ext 0x1300FC = some (.mov 64 (.reg .rbx) (.reg .rax), 0x1300FF) := rfl
@[ode_at] theorem at_1300FF (ext : Nat → Option (Instr × Nat)) : prog ext 0x1300FF = some (.mov 64 (.reg .rax) (.reg .rbp), 0x130102) := rfl
@[ode_at] theorem at_130102 (ext : Nat → Option (Instr × Nat)) : prog ext 0x130102 = some (.sub 64 (.reg .rax) (.imm 0x8000), 0x130108) := rfl
@[ode_at] theorem at_130108 (ext : Nat → Option (Instr × Nat)) : prog ext 0x130108 = some (.mov 64 (.reg .rbp) (.reg .rax), 0x13010B) := rfl
@[ode_at] theorem at_13010B (ext : Nat → Option (Instr × Nat)) : prog ext 0x13010B = some (.mov 64 (.reg .rax) (.reg .r12), 0x13010E) := rfl
@[ode_at] theorem at_13010E (ext : Nat → Option (Instr × Nat)) : prog ext 0x13010E = some (.add 64 (.reg .rax) (.imm 0x20), 0x130112) := rfl
@[ode_at] theorem at_130112 (ext : Nat → Option (Instr × Nat)) : prog ext 0x130112 = some (.mov 64 (.reg .r12) (.reg .rax), 0x130115) := rfl
@[ode_at] theorem at_130115 (ext : Nat → Option (Instr × Nat)) : prog ext 0x130115 = some (.jmp 0x130068, 0x13011A) := rfl
@[ode_at] theorem at_13011A (ext : Nat → Option (Instr × Nat)) : prog ext 0x13011A = some (.mov 64 (.reg .rax) (.reg .r12), 0x13011D) := rfl
@[ode_at] theorem at_13011D (ext : Nat → Option (Instr × Nat)) : prog ext 0x13011D = some (.add 64 (.reg .rsp) (.imm 0x718), 0x130124) := rfl
@[ode_at] theorem at_130124 (ext : Nat → Option (Instr × Nat)) : prog ext 0x130124 = some (.pop .r15, 0x130126) := rfl
@[ode_at] theorem at_130126 (ext : Nat → Option (Instr × Nat)) : prog ext 0x130126 = some (.pop .r14, 0x130128) := rfl
@[ode_at] theorem at_130128 (ext : Nat → Option (Instr × Nat)) : prog ext 0x130128 = some (.pop .r13, 0x13012A) := rfl
@[ode_at] theorem at_13012A (ext : Nat → Option (Instr × Nat)) : prog ext 0x13012A = some (.pop .r12, 0x13012C) := rfl
@[ode_at] theorem at_13012C (ext : Nat → Option (Instr × Nat)) : prog ext 0x13012C = some (.pop .rbp, 0x13012D) := rfl
@[ode_at] theorem at_13012D (ext : Nat → Option (Instr × Nat)) : prog ext 0x13012D = some (.pop .rbx, 0x13012E) := rfl
@[ode_at] theorem at_13012E (ext : Nat → Option (Instr × Nat)) : prog ext 0x13012E = some (.ret, 0x13012F) := rfl

end Code_wide
