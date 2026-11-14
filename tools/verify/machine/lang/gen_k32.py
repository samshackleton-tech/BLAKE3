#!/usr/bin/env python3
"""Write the proofs about the 32-lane chunk kernel K32 from its lifted instructions (BLAKE3 #361).

usage: gen_k32.py ROWS OUT_DIR        (ROWS: Lifted_k32.lean.rows, from try_kernel.sh)

So far: K32Round.lean, the theorem that the 240 instructions of the round loop's body are the specification's
round in each of the 32 lanes (two halves of sixteen), with the message words read through the schedule row
`rdi` points at. The registers a round reads and writes are found here by following the instructions."""
import sys

rows = [l.rstrip("\n").split("\t") for l in open(sys.argv[1])]
out_dir = sys.argv[2]
at = [int(r[0], 16) for r in rows]
ins = [r[2] for r in rows]

# the round loop: `add rdi, 64; dec r11d; jne HEAD`
tail = next(i for i, x in enumerate(ins) if x.startswith(".dec32 .r11"))
assert ins[tail - 1] == ".add 64 (.reg .rdi) (.imm 0x40)" and ins[tail + 1].startswith(".jne ")
head = int(ins[tail + 1].split()[1], 16)
h = at.index(head)
assert tail - 1 - h == 240, "a round is 240 instructions"
GP = ["rax", "rcx", "rdx", "r8"]                # where a group's four schedule entries go


def group(first, entry):
    """One quarter of a round (60 instructions from `first`): four schedule entries read, the message words at
    them added to the `a` registers of both halves, then half of G in eight columns. Returns the registers
    (a, b, c, d of half A, then of half B) and checks the shape."""
    p = [x.split() for x in ins[first:first + 60]]
    for j in range(4):
        assert ins[first + j] == f".mov 32 (.reg .{GP[j]}) (.mem .rdi 0x{4 * (entry + 2 * j):X})", ins[first + j]
    a = [int(p[4 + j][1]) for j in range(8)]
    for j in range(8):
        assert p[4 + j] == [".zpadddm", str(a[j]), str(a[j]), ".rsi", "." + GP[j % 4], "0x0" if j < 4 else "0x400"], p[4 + j]
    b = [int(p[12 + j][3]) for j in range(8)]
    d = [int(p[20 + j][1]) for j in range(8)]
    c = [int(p[36 + j][1]) for j in range(8)]
    kinds = [x[0] for x in p[12:]]
    assert kinds == [".zpaddd"] * 8 + [".zpxord"] * 8 + [".zprord"] * 8 + [".zpaddd"] * 8 + [".zpxord"] * 8 + [".zprord"] * 8
    return a, b, c, d


g = [group(h + 60 * q, e) for q, e in enumerate([0, 1, 8, 9])]
a, b, c, d = g[0]
assert g[1] == g[0] and g[2][0] == a and g[3] == g[2]
STATE_A = a[:4] + b[:4] + c[:4] + d[:4]
STATE_B = a[4:] + b[4:] + c[4:] + d[4:]
assert sorted(STATE_A + STATE_B) == list(range(32))

lanes = lambda p: " ".join(f"{p}{k}" for k in range(16))
V = lambda p: "#v[" + ", ".join(f"{p}{k} i" for k in range(16)) + "]"
FIELDS = "rax, rcx, rdx, rbx, rsp, rbp, rsi, rdi, r8, r9, r12, r13, r14, r15, zf, cf, " + ", ".join(f"x{i}" for i in range(16)) + ", mem, pc"
WIDE = "r10, r11, " + ", ".join(f"u{i}" for i in range(16)) + ", " + ", ".join(f"z{i}" for i in range(16, 32)) + ", k1, k2"
off = lambda k: f"(o{k} &&& 0xFFFFFFFF#64)"
entry_at = lambda k: "st.rdi" if k == 0 else f"st.rdi + 0x{4 * k:X}#64"

t = ["import Cells", "import Flat", "import WideLemmas", "import Code_k32", "open X86 Cells Blake3Generic", "",
     "/-! # A round of the 32-lane chunk kernel is the specification's round, in every lane",
     "",
     "Written by gen_k32.py from the kernel's lifted instructions. The lanes are two halves of sixteen. Sixteen ZMM",
     "registers hold the sixteen state words of each half (lane `i` of each is input `i`'s, or input `16 + i`'s).",
     "The message words are in memory, sixteen ZMM words a half from `rsi`; a round reads them in the order of the",
     "sixteen offsets `rdi` points at (a row of the kernel's schedule table). -/", "",
     "namespace K32", "",
     "/-- The state words of the first half, one register each: lane `i` of the register of word `k` is `s k i`. -/",
     "def RowsA (st : State) (" + lanes("s") + " : Nat → BitVec 32) : Prop :=",
     "  " + " ∧ ".join(f"st.zmm {STATE_A[k]} = zpack s{k}" for k in range(16)), "",
     "/-- The state words of the second half. -/",
     "def RowsB (st : State) (" + lanes("s") + " : Nat → BitVec 32) : Prop :=",
     "  " + " ∧ ".join(f"st.zmm {STATE_B[k]} = zpack s{k}" for k in range(16)), "",
     "/-- The sixteen offsets a round reads its message words at: 32-bit numbers at `rdi`, four bytes apart. -/",
     "def Row (st : State) (" + lanes("o") + " : BitVec 64) : Prop :=",
     "  " + " ∧ ".join(f"st.mem.read ({entry_at(k)}) 32 = some o{k}" for k in range(16)), "",
     "/-- The message words of both halves, where a round with those offsets reads them: word `k` of the first half",
     "at `rsi + o k`, of the second 1024 bytes on. -/",
     "def Msgs (st : State) (" + lanes("o") + " : BitVec 64) (" + lanes("m") + " " + lanes("n") + " : Nat → BitVec 32) : Prop :=",
     "  " + " ∧ ".join(f"st.mem.read512 (st.rsi + {off(k)}) = some (zpack m{k})" for k in range(16)) + " ∧",
     "  " + " ∧ ".join(f"st.mem.read512 (st.rsi + ({off(k)} + 0x400#64)) = some (zpack n{k})" for k in range(16)), "",
     "/-- What a round leaves alone: memory, the flags and every general register but the four the offsets go through. -/",
     "def Kept (s s' : State) : Prop :=",
     "  s'.rbx = s.rbx ∧ s'.rsp = s.rsp ∧ s'.rbp = s.rbp ∧ s'.rsi = s.rsi ∧ s'.rdi = s.rdi ∧ s'.r9 = s.r9 ∧ s'.r12 = s.r12 ∧ s'.r13 = s.r13 ∧",
     "    s'.r14 = s.r14 ∧ s'.r15 = s.r15 ∧ s'.w.r10 = s.w.r10 ∧ s'.w.r11 = s.w.r11 ∧ s'.zf = s.zf ∧ s'.cf = s.cf ∧ s'.mem = s.mem", ""]
# the hypotheses name whole registers; a register below 16 is two fields of the state
splits = []
for half, regs, name in (("s", STATE_A, "ha"), ("t", STATE_B, "hb")):
    for k, r in enumerate(regs):
        if r < 16:
            splits += [f"  have e{r} : x{r} = zlo (zpack {half}{k}) := by rw [← {name}{k}, zlo_zjoin]",
                       f"  have f{r} : u{r} = zhi (zpack {half}{k}) := by rw [← {name}{k}, zhi_zjoin]",
                       f"  subst e{r} f{r}"]
        else:
            splits.append(f"  subst {name}{k}")
names = lambda p: ", ".join(f"{p}{k}" for k in range(16))
t += ["set_option maxRecDepth 1000000 in", "set_option maxHeartbeats 0 in",
      f"/-- **A round.** The 240 instructions from the round loop's head (0x{head:X}) are the specification's round on",
      "the state words of every lane of both halves, with the message words at the row's offsets, in the row's order. -/",
      f"theorem round ({lanes('s')} {lanes('t')} {lanes('m')} {lanes('n')} : Nat → BitVec 32) ({lanes('o')} : BitVec 64)",
      f"    (st : State) (hpc : st.pc = 0x{head:X})",
      f"    (ha : RowsA st {lanes('s')}) (hb : RowsB st {lanes('t')}) (ho : Row st {lanes('o')})",
      f"    (hm : Msgs st {lanes('o')} {lanes('m')} {lanes('n')}) :",
      f"    ∃ st', steps Code_k32.prog 240 st = some st' ∧ st'.pc = 0x{at[h + 240]:X} ∧",
      "      RowsA st' " + " ".join(f"(fun i => (rnd {V('s')} {V('m')})[{k}])" for k in range(16)) + " ∧",
      "      RowsB st' " + " ".join(f"(fun i => (rnd {V('t')} {V('n')})[{k}])" for k in range(16)) + " ∧",
      "      Kept st st' := by",
      f"  obtain ⟨{FIELDS}, ⟨{WIDE}⟩⟩ := st",
      f"  obtain ⟨{names('ha')}⟩ := ha",
      f"  obtain ⟨{names('hb')}⟩ := hb",
      f"  obtain ⟨{names('ho')}⟩ := ho",
      f"  obtain ⟨{names('hm')}, {names('hn')}⟩ := hm",
      "  simp only [State.zmm] at hpc " + " ".join(f"ha{k} hb{k}" for k in range(16)),
      "  simp only at " + " ".join(f"ho{k} hm{k} hn{k}" for k in range(16)),
      "  subst hpc"] + splits + [
      "  run_fn [zjoin_split, zlo_zjoin, zhi_zjoin, " + ", ".join(f"ho{k}, hm{k}, hn{k}" for k in range(16)) + "]",
      "  refine ⟨_, rfl, rfl, ?_, ?_, ?_⟩",
      "  · simp only [RowsA, State.zmm, zjoin_split]",
      "    refine ⟨" + ", ".join(["?_"] * 16) + "⟩ <;>",
      "      (apply zpack_congr; intro i hi; simp only [zjoin_split, zdw_zmap2 _ _ _ hi, zdw_zmap1 _ _ hi, zdw_xor _ _ _ hi, zdw_zpack _ i hi]; eval_spec; bv_decide (config := { timeout := 900 }))",
      "  · simp only [RowsB, State.zmm, zjoin_split]",
      "    refine ⟨" + ", ".join(["?_"] * 16) + "⟩ <;>",
      "      (apply zpack_congr; intro i hi; simp only [zjoin_split, zdw_zmap2 _ _ _ hi, zdw_zmap1 _ _ hi, zdw_xor _ _ _ hi, zdw_zpack _ i hi]; eval_spec; bv_decide (config := { timeout := 900 }))",
      "  · simp only [Kept, and_self]",
      "", "end K32", ""]


def write_if_changed(path, content):
    try:
        with open(path, encoding="utf-8") as f:
            if f.read() == content:
                return
    except FileNotFoundError:
        pass
    with open(path, "w", encoding="utf-8") as f:
        f.write(content)


write_if_changed(f"{out_dir}/K32Round.lean", "\n".join(t))
print(f"round: head 0x{head:X}; state words of half A in ZMM {STATE_A}, of half B in ZMM {STATE_B}; wrote K32Round.lean")
