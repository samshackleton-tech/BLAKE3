import Machine
import KCode
import Cells
open X86

/-! `lroot` as assembled: 108 instructions. Written from the lifter's rows. -/

set_option maxRecDepth 100000
namespace Code_lroot

def table : List (Nat × Instr × Nat) := [
  (0xC0000, .push .rbx, 0xC0001),
  (0xC0001, .push .rbp, 0xC0002),
  (0xC0002, .push .r12, 0xC0004),
  (0xC0004, .push .r13, 0xC0006),
  (0xC0006, .push .r14, 0xC0008),
  (0xC0008, .push .r15, 0xC000A),
  (0xC000A, .sub 64 (.reg .rsp) (.imm 0x88), 0xC0011),
  (0xC0011, .mov 64 (.mem .rsp 0x60) (.reg .rdi), 0xC0016),
  (0xC0016, .mov 64 (.reg .r13) (.reg .rsi), 0xC0019),
  (0xC0019, .mov 64 (.reg .r14) (.reg .rdx), 0xC001C),
  (0xC001C, .mov 64 (.mem .rsp 0x68) (.reg .rcx), 0xC0021),
  (0xC0021, .mov 64 (.reg .r15) (.reg .r8), 0xC0024),
  (0xC0024, .mov 64 (.mem .rsp 0x70) (.reg .r9), 0xC0029),
  (0xC0029, .mov 64 (.reg .rax) (.mem .rsp 0x68), 0xC002E),
  (0xC002E, .or 64 (.reg .rax) (.imm 0x4), 0xC0032),
  (0xC0032, .mov 64 (.mem .rsp 0x78) (.reg .rax), 0xC0037),
  (0xC0037, .mov 64 (.reg .rax) (.reg .r13), 0xC003A),
  (0xC003A, .mov 64 (.reg .rax) (.mem .rax 0x0), 0xC003D),
  (0xC003D, .sub 64 (.reg .rax) (.imm 0x1), 0xC0041),
  (0xC0041, .mov 64 (.reg .rbx) (.reg .rax), 0xC0044),
  (0xC0044, .mov 64 (.reg .rax) (.reg .r13), 0xC0047),
  (0xC0047, .add 64 (.reg .rax) (.imm 0x40), 0xC004B),
  (0xC004B, .mov 64 (.reg .rbp) (.reg .rax), 0xC004E),
  (0xC004E, .mov 64 (.reg .rax) (.reg .rbp), 0xC0051),
  (0xC0051, .mov 64 (.reg .rcx) (.reg .rbx), 0xC0054),
  (0xC0054, .and 64 (.reg .rcx) (.imm 0x1), 0xC0058),
  (0xC0058, .shl64 .rcx 5, 0xC005C),
  (0xC005C, .add 64 (.reg .rax) (.reg .rcx), 0xC005F),
  (0xC005F, .lea .rcx .rsp 0x40, 0xC0064),
  (0xC0064, .movv false 0 (.m .rax 0x0), 0xC0067),
  (0xC0067, .storev false .rcx 0x0 0, 0xC006A),
  (0xC006A, .movv false 0 (.m .rax 0x10), 0xC006E),
  (0xC006E, .storev false .rcx 0x10 0, 0xC0072),
  (0xC0072, .mov 64 (.reg .rax) (.imm 0x0), 0xC0079),
  (0xC0079, .mov 64 (.reg .rcx) (.reg .rbx), 0xC007C),
  (0xC007C, .cmp 64 (.reg .rax) (.reg .rcx), 0xC007F),
  (0xC007F, .jae 0xC016D, 0xC0085),
  (0xC0085, .mov 64 (.reg .rax) (.reg .rbx), 0xC0088),
  (0xC0088, .and 64 (.reg .rax) (.imm 0x1), 0xC008C),
  (0xC008C, .mov 64 (.reg .rcx) (.imm 0x1), 0xC0093),
  (0xC0093, .cmp 64 (.reg .rax) (.reg .rcx), 0xC0096),
  (0xC0096, .jne 0xC0155, 0xC009C),
  (0xC009C, .mov 64 (.reg .rax) (.mem .rsp 0x78), 0xC00A1),
  (0xC00A1, .mov 64 (.reg .r12) (.reg .rax), 0xC00A4),
  (0xC00A4, .mov 64 (.reg .rax) (.reg .rbx), 0xC00A7),
  (0xC00A7, .mov 64 (.reg .rcx) (.imm 0x1), 0xC00AE),
  (0xC00AE, .cmp 64 (.reg .rax) (.reg .rcx), 0xC00B1),
  (0xC00B1, .jne 0xC00C0, 0xC00B3),
  (0xC00B3, .mov 64 (.reg .rax) (.mem .rsp 0x78), 0xC00B8),
  (0xC00B8, .or 64 (.reg .rax) (.mem .rsp 0x70), 0xC00BD),
  (0xC00BD, .mov 64 (.reg .r12) (.reg .rax), 0xC00C0),
  (0xC00C0, .mov 64 (.reg .rax) (.reg .rbp), 0xC00C3),
  (0xC00C3, .lea .rcx .rsp 0x0, 0xC00C7),
  (0xC00C7, .movv false 0 (.m .rax 0x0), 0xC00CA),
  (0xC00CA, .storev false .rcx 0x0 0, 0xC00CD),
  (0xC00CD, .movv false 0 (.m .rax 0x10), 0xC00D1),
  (0xC00D1, .storev false .rcx 0x10 0, 0xC00D5),
  (0xC00D5, .lea .rax .rsp 0x40, 0xC00DA),
  (0xC00DA, .lea .rcx .rsp 0x0, 0xC00DE),
  (0xC00DE, .add 64 (.reg .rcx) (.imm 0x20), 0xC00E2),
  (0xC00E2, .movv false 0 (.m .rax 0x0), 0xC00E5),
  (0xC00E5, .storev false .rcx 0x0 0, 0xC00E8),
  (0xC00E8, .movv false 0 (.m .rax 0x10), 0xC00EC),
  (0xC00EC, .storev false .rcx 0x10 0, 0xC00F0),
  (0xC00F0, .mov 64 (.reg .rax) (.reg .r14), 0xC00F3),
  (0xC00F3, .lea .rcx .rsp 0x40, 0xC00F8),
  (0xC00F8, .movv false 0 (.m .rax 0x0), 0xC00FB),
  (0xC00FB, .storev false .rcx 0x0 0, 0xC00FE),
  (0xC00FE, .movv false 0 (.m .rax 0x10), 0xC0102),
  (0xC0102, .storev false .rcx 0x10 0, 0xC0106),
  (0xC0106, .mov 64 (.reg .rax) (.reg .r15), 0xC0109),
  (0xC0109, .mov 64 (.reg .rcx) (.imm 0x5), 0xC0110),
  (0xC0110, .cmp 64 (.reg .rax) (.reg .rcx), 0xC0113),
  (0xC0113, .jne 0xC0136, 0xC0115),
  (0xC0115, .lea .rdi .rsp 0x40, 0xC011A),
  (0xC011A, .lea .rsi .rsp 0x0, 0xC011E),
  (0xC011E, .mov 64 (.reg .rdx) (.imm 0x40), 0xC0125),
  (0xC0125, .mov 64 (.reg .rcx) (.imm 0x0), 0xC012C),
  (0xC012C, .mov 64 (.reg .r8) (.reg .r12), 0xC012F),
  (0xC012F, .call 0x30000, 0xC0134),
  (0xC0134, .jmp 0xC0155, 0xC0136),
  (0xC0136, .lea .rdi .rsp 0x40, 0xC013B),
  (0xC013B, .lea .rsi .rsp 0x0, 0xC013F),
  (0xC013F, .mov 64 (.reg .rdx) (.imm 0x40), 0xC0146),
  (0xC0146, .mov 64 (.reg .rcx) (.imm 0x0), 0xC014D),
  (0xC014D, .mov 64 (.reg .r8) (.reg .r12), 0xC0150),
  (0xC0150, .call 0x20000, 0xC0155),
  (0xC0155, .mov 64 (.reg .rax) (.reg .rbx), 0xC0158),
  (0xC0158, .shr64 .rax 1, 0xC015B),
  (0xC015B, .mov 64 (.reg .rbx) (.reg .rax), 0xC015E),
  (0xC015E, .mov 64 (.reg .rax) (.reg .rbp), 0xC0161),
  (0xC0161, .add 64 (.reg .rax) (.imm 0x40), 0xC0165),
  (0xC0165, .mov 64 (.reg .rbp) (.reg .rax), 0xC0168),
  (0xC0168, .jmp 0xC0072, 0xC016D),
  (0xC016D, .lea .rax .rsp 0x40, 0xC0172),
  (0xC0172, .mov 64 (.reg .rcx) (.mem .rsp 0x60), 0xC0177),
  (0xC0177, .movv false 0 (.m .rax 0x0), 0xC017A),
  (0xC017A, .storev false .rcx 0x0 0, 0xC017D),
  (0xC017D, .movv false 0 (.m .rax 0x10), 0xC0181),
  (0xC0181, .storev false .rcx 0x10 0, 0xC0185),
  (0xC0185, .add 64 (.reg .rsp) (.imm 0x88), 0xC018C),
  (0xC018C, .pop .r15, 0xC018E),
  (0xC018E, .pop .r14, 0xC0190),
  (0xC0190, .pop .r13, 0xC0192),
  (0xC0192, .pop .r12, 0xC0194),
  (0xC0194, .pop .rbp, 0xC0195),
  (0xC0195, .pop .rbx, 0xC0196),
  (0xC0196, .ret, 0xC0197)
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

@[ode_at] theorem at_C0000 : prog 0xC0000 = some (.push .rbx, 0xC0001) := rfl
@[ode_at] theorem at_C0001 : prog 0xC0001 = some (.push .rbp, 0xC0002) := rfl
@[ode_at] theorem at_C0002 : prog 0xC0002 = some (.push .r12, 0xC0004) := rfl
@[ode_at] theorem at_C0004 : prog 0xC0004 = some (.push .r13, 0xC0006) := rfl
@[ode_at] theorem at_C0006 : prog 0xC0006 = some (.push .r14, 0xC0008) := rfl
@[ode_at] theorem at_C0008 : prog 0xC0008 = some (.push .r15, 0xC000A) := rfl
@[ode_at] theorem at_C000A : prog 0xC000A = some (.sub 64 (.reg .rsp) (.imm 0x88), 0xC0011) := rfl
@[ode_at] theorem at_C0011 : prog 0xC0011 = some (.mov 64 (.mem .rsp 0x60) (.reg .rdi), 0xC0016) := rfl
@[ode_at] theorem at_C0016 : prog 0xC0016 = some (.mov 64 (.reg .r13) (.reg .rsi), 0xC0019) := rfl
@[ode_at] theorem at_C0019 : prog 0xC0019 = some (.mov 64 (.reg .r14) (.reg .rdx), 0xC001C) := rfl
@[ode_at] theorem at_C001C : prog 0xC001C = some (.mov 64 (.mem .rsp 0x68) (.reg .rcx), 0xC0021) := rfl
@[ode_at] theorem at_C0021 : prog 0xC0021 = some (.mov 64 (.reg .r15) (.reg .r8), 0xC0024) := rfl
@[ode_at] theorem at_C0024 : prog 0xC0024 = some (.mov 64 (.mem .rsp 0x70) (.reg .r9), 0xC0029) := rfl
@[ode_at] theorem at_C0029 : prog 0xC0029 = some (.mov 64 (.reg .rax) (.mem .rsp 0x68), 0xC002E) := rfl
@[ode_at] theorem at_C002E : prog 0xC002E = some (.or 64 (.reg .rax) (.imm 0x4), 0xC0032) := rfl
@[ode_at] theorem at_C0032 : prog 0xC0032 = some (.mov 64 (.mem .rsp 0x78) (.reg .rax), 0xC0037) := rfl
@[ode_at] theorem at_C0037 : prog 0xC0037 = some (.mov 64 (.reg .rax) (.reg .r13), 0xC003A) := rfl
@[ode_at] theorem at_C003A : prog 0xC003A = some (.mov 64 (.reg .rax) (.mem .rax 0x0), 0xC003D) := rfl
@[ode_at] theorem at_C003D : prog 0xC003D = some (.sub 64 (.reg .rax) (.imm 0x1), 0xC0041) := rfl
@[ode_at] theorem at_C0041 : prog 0xC0041 = some (.mov 64 (.reg .rbx) (.reg .rax), 0xC0044) := rfl
@[ode_at] theorem at_C0044 : prog 0xC0044 = some (.mov 64 (.reg .rax) (.reg .r13), 0xC0047) := rfl
@[ode_at] theorem at_C0047 : prog 0xC0047 = some (.add 64 (.reg .rax) (.imm 0x40), 0xC004B) := rfl
@[ode_at] theorem at_C004B : prog 0xC004B = some (.mov 64 (.reg .rbp) (.reg .rax), 0xC004E) := rfl
@[ode_at] theorem at_C004E : prog 0xC004E = some (.mov 64 (.reg .rax) (.reg .rbp), 0xC0051) := rfl
@[ode_at] theorem at_C0051 : prog 0xC0051 = some (.mov 64 (.reg .rcx) (.reg .rbx), 0xC0054) := rfl
@[ode_at] theorem at_C0054 : prog 0xC0054 = some (.and 64 (.reg .rcx) (.imm 0x1), 0xC0058) := rfl
@[ode_at] theorem at_C0058 : prog 0xC0058 = some (.shl64 .rcx 5, 0xC005C) := rfl
@[ode_at] theorem at_C005C : prog 0xC005C = some (.add 64 (.reg .rax) (.reg .rcx), 0xC005F) := rfl
@[ode_at] theorem at_C005F : prog 0xC005F = some (.lea .rcx .rsp 0x40, 0xC0064) := rfl
@[ode_at] theorem at_C0064 : prog 0xC0064 = some (.movv false 0 (.m .rax 0x0), 0xC0067) := rfl
@[ode_at] theorem at_C0067 : prog 0xC0067 = some (.storev false .rcx 0x0 0, 0xC006A) := rfl
@[ode_at] theorem at_C006A : prog 0xC006A = some (.movv false 0 (.m .rax 0x10), 0xC006E) := rfl
@[ode_at] theorem at_C006E : prog 0xC006E = some (.storev false .rcx 0x10 0, 0xC0072) := rfl
@[ode_at] theorem at_C0072 : prog 0xC0072 = some (.mov 64 (.reg .rax) (.imm 0x0), 0xC0079) := rfl
@[ode_at] theorem at_C0079 : prog 0xC0079 = some (.mov 64 (.reg .rcx) (.reg .rbx), 0xC007C) := rfl
@[ode_at] theorem at_C007C : prog 0xC007C = some (.cmp 64 (.reg .rax) (.reg .rcx), 0xC007F) := rfl
@[ode_at] theorem at_C007F : prog 0xC007F = some (.jae 0xC016D, 0xC0085) := rfl
@[ode_at] theorem at_C0085 : prog 0xC0085 = some (.mov 64 (.reg .rax) (.reg .rbx), 0xC0088) := rfl
@[ode_at] theorem at_C0088 : prog 0xC0088 = some (.and 64 (.reg .rax) (.imm 0x1), 0xC008C) := rfl
@[ode_at] theorem at_C008C : prog 0xC008C = some (.mov 64 (.reg .rcx) (.imm 0x1), 0xC0093) := rfl
@[ode_at] theorem at_C0093 : prog 0xC0093 = some (.cmp 64 (.reg .rax) (.reg .rcx), 0xC0096) := rfl
@[ode_at] theorem at_C0096 : prog 0xC0096 = some (.jne 0xC0155, 0xC009C) := rfl
@[ode_at] theorem at_C009C : prog 0xC009C = some (.mov 64 (.reg .rax) (.mem .rsp 0x78), 0xC00A1) := rfl
@[ode_at] theorem at_C00A1 : prog 0xC00A1 = some (.mov 64 (.reg .r12) (.reg .rax), 0xC00A4) := rfl
@[ode_at] theorem at_C00A4 : prog 0xC00A4 = some (.mov 64 (.reg .rax) (.reg .rbx), 0xC00A7) := rfl
@[ode_at] theorem at_C00A7 : prog 0xC00A7 = some (.mov 64 (.reg .rcx) (.imm 0x1), 0xC00AE) := rfl
@[ode_at] theorem at_C00AE : prog 0xC00AE = some (.cmp 64 (.reg .rax) (.reg .rcx), 0xC00B1) := rfl
@[ode_at] theorem at_C00B1 : prog 0xC00B1 = some (.jne 0xC00C0, 0xC00B3) := rfl
@[ode_at] theorem at_C00B3 : prog 0xC00B3 = some (.mov 64 (.reg .rax) (.mem .rsp 0x78), 0xC00B8) := rfl
@[ode_at] theorem at_C00B8 : prog 0xC00B8 = some (.or 64 (.reg .rax) (.mem .rsp 0x70), 0xC00BD) := rfl
@[ode_at] theorem at_C00BD : prog 0xC00BD = some (.mov 64 (.reg .r12) (.reg .rax), 0xC00C0) := rfl
@[ode_at] theorem at_C00C0 : prog 0xC00C0 = some (.mov 64 (.reg .rax) (.reg .rbp), 0xC00C3) := rfl
@[ode_at] theorem at_C00C3 : prog 0xC00C3 = some (.lea .rcx .rsp 0x0, 0xC00C7) := rfl
@[ode_at] theorem at_C00C7 : prog 0xC00C7 = some (.movv false 0 (.m .rax 0x0), 0xC00CA) := rfl
@[ode_at] theorem at_C00CA : prog 0xC00CA = some (.storev false .rcx 0x0 0, 0xC00CD) := rfl
@[ode_at] theorem at_C00CD : prog 0xC00CD = some (.movv false 0 (.m .rax 0x10), 0xC00D1) := rfl
@[ode_at] theorem at_C00D1 : prog 0xC00D1 = some (.storev false .rcx 0x10 0, 0xC00D5) := rfl
@[ode_at] theorem at_C00D5 : prog 0xC00D5 = some (.lea .rax .rsp 0x40, 0xC00DA) := rfl
@[ode_at] theorem at_C00DA : prog 0xC00DA = some (.lea .rcx .rsp 0x0, 0xC00DE) := rfl
@[ode_at] theorem at_C00DE : prog 0xC00DE = some (.add 64 (.reg .rcx) (.imm 0x20), 0xC00E2) := rfl
@[ode_at] theorem at_C00E2 : prog 0xC00E2 = some (.movv false 0 (.m .rax 0x0), 0xC00E5) := rfl
@[ode_at] theorem at_C00E5 : prog 0xC00E5 = some (.storev false .rcx 0x0 0, 0xC00E8) := rfl
@[ode_at] theorem at_C00E8 : prog 0xC00E8 = some (.movv false 0 (.m .rax 0x10), 0xC00EC) := rfl
@[ode_at] theorem at_C00EC : prog 0xC00EC = some (.storev false .rcx 0x10 0, 0xC00F0) := rfl
@[ode_at] theorem at_C00F0 : prog 0xC00F0 = some (.mov 64 (.reg .rax) (.reg .r14), 0xC00F3) := rfl
@[ode_at] theorem at_C00F3 : prog 0xC00F3 = some (.lea .rcx .rsp 0x40, 0xC00F8) := rfl
@[ode_at] theorem at_C00F8 : prog 0xC00F8 = some (.movv false 0 (.m .rax 0x0), 0xC00FB) := rfl
@[ode_at] theorem at_C00FB : prog 0xC00FB = some (.storev false .rcx 0x0 0, 0xC00FE) := rfl
@[ode_at] theorem at_C00FE : prog 0xC00FE = some (.movv false 0 (.m .rax 0x10), 0xC0102) := rfl
@[ode_at] theorem at_C0102 : prog 0xC0102 = some (.storev false .rcx 0x10 0, 0xC0106) := rfl
@[ode_at] theorem at_C0106 : prog 0xC0106 = some (.mov 64 (.reg .rax) (.reg .r15), 0xC0109) := rfl
@[ode_at] theorem at_C0109 : prog 0xC0109 = some (.mov 64 (.reg .rcx) (.imm 0x5), 0xC0110) := rfl
@[ode_at] theorem at_C0110 : prog 0xC0110 = some (.cmp 64 (.reg .rax) (.reg .rcx), 0xC0113) := rfl
@[ode_at] theorem at_C0113 : prog 0xC0113 = some (.jne 0xC0136, 0xC0115) := rfl
@[ode_at] theorem at_C0115 : prog 0xC0115 = some (.lea .rdi .rsp 0x40, 0xC011A) := rfl
@[ode_at] theorem at_C011A : prog 0xC011A = some (.lea .rsi .rsp 0x0, 0xC011E) := rfl
@[ode_at] theorem at_C011E : prog 0xC011E = some (.mov 64 (.reg .rdx) (.imm 0x40), 0xC0125) := rfl
@[ode_at] theorem at_C0125 : prog 0xC0125 = some (.mov 64 (.reg .rcx) (.imm 0x0), 0xC012C) := rfl
@[ode_at] theorem at_C012C : prog 0xC012C = some (.mov 64 (.reg .r8) (.reg .r12), 0xC012F) := rfl
@[ode_at] theorem at_C012F : prog 0xC012F = some (.call 0x30000, 0xC0134) := rfl
@[ode_at] theorem at_C0134 : prog 0xC0134 = some (.jmp 0xC0155, 0xC0136) := rfl
@[ode_at] theorem at_C0136 : prog 0xC0136 = some (.lea .rdi .rsp 0x40, 0xC013B) := rfl
@[ode_at] theorem at_C013B : prog 0xC013B = some (.lea .rsi .rsp 0x0, 0xC013F) := rfl
@[ode_at] theorem at_C013F : prog 0xC013F = some (.mov 64 (.reg .rdx) (.imm 0x40), 0xC0146) := rfl
@[ode_at] theorem at_C0146 : prog 0xC0146 = some (.mov 64 (.reg .rcx) (.imm 0x0), 0xC014D) := rfl
@[ode_at] theorem at_C014D : prog 0xC014D = some (.mov 64 (.reg .r8) (.reg .r12), 0xC0150) := rfl
@[ode_at] theorem at_C0150 : prog 0xC0150 = some (.call 0x20000, 0xC0155) := rfl
@[ode_at] theorem at_C0155 : prog 0xC0155 = some (.mov 64 (.reg .rax) (.reg .rbx), 0xC0158) := rfl
@[ode_at] theorem at_C0158 : prog 0xC0158 = some (.shr64 .rax 1, 0xC015B) := rfl
@[ode_at] theorem at_C015B : prog 0xC015B = some (.mov 64 (.reg .rbx) (.reg .rax), 0xC015E) := rfl
@[ode_at] theorem at_C015E : prog 0xC015E = some (.mov 64 (.reg .rax) (.reg .rbp), 0xC0161) := rfl
@[ode_at] theorem at_C0161 : prog 0xC0161 = some (.add 64 (.reg .rax) (.imm 0x40), 0xC0165) := rfl
@[ode_at] theorem at_C0165 : prog 0xC0165 = some (.mov 64 (.reg .rbp) (.reg .rax), 0xC0168) := rfl
@[ode_at] theorem at_C0168 : prog 0xC0168 = some (.jmp 0xC0072, 0xC016D) := rfl
@[ode_at] theorem at_C016D : prog 0xC016D = some (.lea .rax .rsp 0x40, 0xC0172) := rfl
@[ode_at] theorem at_C0172 : prog 0xC0172 = some (.mov 64 (.reg .rcx) (.mem .rsp 0x60), 0xC0177) := rfl
@[ode_at] theorem at_C0177 : prog 0xC0177 = some (.movv false 0 (.m .rax 0x0), 0xC017A) := rfl
@[ode_at] theorem at_C017A : prog 0xC017A = some (.storev false .rcx 0x0 0, 0xC017D) := rfl
@[ode_at] theorem at_C017D : prog 0xC017D = some (.movv false 0 (.m .rax 0x10), 0xC0181) := rfl
@[ode_at] theorem at_C0181 : prog 0xC0181 = some (.storev false .rcx 0x10 0, 0xC0185) := rfl
@[ode_at] theorem at_C0185 : prog 0xC0185 = some (.add 64 (.reg .rsp) (.imm 0x88), 0xC018C) := rfl
@[ode_at] theorem at_C018C : prog 0xC018C = some (.pop .r15, 0xC018E) := rfl
@[ode_at] theorem at_C018E : prog 0xC018E = some (.pop .r14, 0xC0190) := rfl
@[ode_at] theorem at_C0190 : prog 0xC0190 = some (.pop .r13, 0xC0192) := rfl
@[ode_at] theorem at_C0192 : prog 0xC0192 = some (.pop .r12, 0xC0194) := rfl
@[ode_at] theorem at_C0194 : prog 0xC0194 = some (.pop .rbp, 0xC0195) := rfl
@[ode_at] theorem at_C0195 : prog 0xC0195 = some (.pop .rbx, 0xC0196) := rfl
@[ode_at] theorem at_C0196 : prog 0xC0196 = some (.ret, 0xC0197) := rfl

end Code_lroot
