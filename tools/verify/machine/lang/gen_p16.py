#!/usr/bin/env python3
"""Write the proofs about the wide parent kernel P16 from its lifted instructions (BLAKE3 #361).

usage: gen_p16.py ROWS OUT_DIR        (ROWS: Lifted_p16.lean.rows, from try_kernel.sh)

So far: P16Round.lean, the theorem that the 112 instructions of a round (two uses of the source's `g4`) are
the specification's round in each of the sixteen lanes. The registers a round reads and writes are found
here by following the instructions; nothing about them is written by hand."""
import re
import sys

rows = [l.rstrip("\n").split("\t") for l in open(sys.argv[1])]
out_dir = sys.argv[2]
at = [int(r[0], 16) for r in rows]
ins = [r[2] for r in rows]

# the round loop's head: the target of the one backward `jmp`
head = next(int(x.split()[1], 16) for x in ins if x.startswith(".jmp"))
h = at.index(head)
assert all(x.split()[0] in (".zpaddd", ".zpxord", ".zprord") for x in ins[h:h + 112]), "a round is 112 lane-wise instructions"
assert ins[h + 112].startswith(".dec32")


def roles(first):
    """The registers of one `g4` (56 instructions from `first`): a, b, c, d, x, y, four each, read off the
    instructions' operands in the order the source's macro has them."""
    p = [x.split() for x in ins[first:first + 56]]
    a = [int(p[i][1]) for i in range(4)]; x = [int(p[i][3]) for i in range(4)]
    b = [int(p[4 + i][3]) for i in range(4)]
    d = [int(p[8 + i][1]) for i in range(4)]
    c = [int(p[16 + i][1]) for i in range(4)]
    y = [int(p[28 + i][3]) for i in range(4)]
    return a, b, c, d, x, y


a1, b1, c1, d1, x1, y1 = roles(h)
a2, b2, c2, d2, x2, y2 = roles(h + 56)
assert a1 == a2 and sorted(b1) == sorted(b2) and sorted(c1) == sorted(c2) and sorted(d1) == sorted(d2)
STATE = a1 + b1 + c1 + d1                       # the register of each of the sixteen state words
# message words: columns take m[2i], m[2i+1]; diagonals m[8+2i], m[9+2i]
MSG = [None] * 16
for i in range(4):
    MSG[2 * i], MSG[2 * i + 1], MSG[8 + 2 * i], MSG[9 + 2 * i] = x1[i], y1[i], x2[i], y2[i]
assert len(set(STATE + MSG)) == 32

V = lambda p: "#v[" + ", ".join(f"{p}{k} i" for k in range(16)) + "]"
lanes = lambda p: " ".join(f"{p}{k}" for k in range(16))
FIELDS = "rax, rcx, rdx, rbx, rsp, rbp, rsi, rdi, r8, r9, r12, r13, r14, r15, zf, cf, " + ", ".join(f"x{i}" for i in range(16)) + ", mem, pc"
WIDE = "r10, r11, " + ", ".join(f"u{i}" for i in range(16)) + ", " + ", ".join(f"z{i}" for i in range(16, 32))


def reg_is(s, r, value):
    return f"{s}.zmm {r} = {value}"


t = ["import Cells", "import Flat", "import WideLemmas", "import Code_p16", "open X86 Cells Blake3Generic", "",
     "/-! # A round of the wide parent kernel is the specification's round, in every lane",
     "",
     "Written by gen_p16.py from the kernel's lifted instructions. Sixteen ZMM registers hold the sixteen state",
     "words of sixteen inputs (lane `i` of each is input `i`'s), sixteen more the message words. -/", "",
     "namespace P16", "",
     "/-- The state words, one register each: lane `i` of the register of word `k` is `s k i`. -/",
     "def Rows (st : State) (" + lanes("s") + " : Nat → BitVec 32) : Prop :=",
     "  " + " ∧ ".join(reg_is("st", STATE[k], f"zpack s{k}") for k in range(16)), "",
     "/-- The message words where the first round's instructions read them. -/",
     "def Msgs (st : State) (" + lanes("m") + " : Nat → BitVec 32) : Prop :=",
     "  " + " ∧ ".join(reg_is("st", MSG[k], f"zpack m{k}") for k in range(16)), "",
     "/-- What a round leaves alone: the general registers, the flags, memory and the message registers. -/",
     "def Kept (s s' : State) : Prop :=",
     "  s'.rax = s.rax ∧ s'.rcx = s.rcx ∧ s'.rdx = s.rdx ∧ s'.rbx = s.rbx ∧ s'.rsp = s.rsp ∧ s'.rbp = s.rbp ∧ s'.rsi = s.rsi ∧ s'.rdi = s.rdi ∧",
     "    s'.r8 = s.r8 ∧ s'.r9 = s.r9 ∧ s'.r12 = s.r12 ∧ s'.r13 = s.r13 ∧ s'.r14 = s.r14 ∧ s'.r15 = s.r15 ∧ s'.w.r10 = s.w.r10 ∧ s'.w.r11 = s.w.r11 ∧",
     "    s'.zf = s.zf ∧ s'.cf = s.cf ∧ s'.mem = s.mem ∧",
     "    " + " ∧ ".join(f"s'.zmm {r} = s.zmm {r}" for r in MSG), ""]
# the hypotheses name whole registers; a register below 16 is two fields of the state
splits = []
for k, r in enumerate(STATE + MSG):
    name = f"hv{k}" if k < 16 else f"hm{k - 16}"
    if r < 16:
        splits.append(f"  have e{r} : x{r} = zlo ({'zpack s' + str(k) if k < 16 else 'zpack m' + str(k - 16)}) := by rw [← {name}, zlo_zjoin]")
        splits.append(f"  have f{r} : u{r} = zhi ({'zpack s' + str(k) if k < 16 else 'zpack m' + str(k - 16)}) := by rw [← {name}, zhi_zjoin]")
        splits.append(f"  subst e{r} f{r}")
    else:
        splits.append(f"  subst {name}")
t += ["set_option maxRecDepth 1000000 in", "set_option maxHeartbeats 0 in",
      f"/-- **A round.** The 112 instructions from the round loop's head (0x{head:X}) are the specification's round on",
      "the state words of every lane, with that lane's message words. -/",
      f"theorem round ({lanes('s')} {lanes('m')} : Nat → BitVec 32) (st : State) (hpc : st.pc = 0x{head:X})",
      f"    (hv : Rows st {lanes('s')}) (hm : Msgs st {lanes('m')}) :",
      f"    ∃ st', steps Code_p16.prog 112 st = some st' ∧ st'.pc = 0x{at[h + 112]:X} ∧",
      "      Rows st' " + " ".join(f"(fun i => (rnd {V('s')} {V('m')})[{k}])" for k in range(16)) + " ∧",
      f"      Msgs st' {lanes('m')} ∧ Kept st st' := by",
      f"  obtain ⟨{FIELDS}, ⟨{WIDE}⟩⟩ := st",
      "  obtain ⟨" + ", ".join(f"hv{k}" for k in range(16)) + "⟩ := hv",
      "  obtain ⟨" + ", ".join(f"hm{k}" for k in range(16)) + "⟩ := hm",
      "  simp only [State.zmm] at hpc " + " ".join(f"hv{k}" for k in range(16)) + " " + " ".join(f"hm{k}" for k in range(16)),
      "  subst hpc"] + splits + [
      "  run_fn [zjoin_split, zlo_zjoin, zhi_zjoin]",
      "  refine ⟨_, rfl, rfl, ?_, ?_, ?_⟩",
      "  · simp only [Rows, State.zmm, zjoin_split]",
      "    refine ⟨" + ", ".join(["?_"] * 16) + "⟩ <;>",
      "      (apply zpack_congr; intro i hi; simp only [zjoin_split, zdw_zmap2 _ _ _ hi, zdw_zmap1 _ _ hi, zdw_xor _ _ _ hi, zdw_zpack _ i hi]; eval_spec; bv_decide (config := { timeout := 900 }))",
      "  · simp only [Msgs, State.zmm, zjoin_split, and_self]",
      "  · simp only [Kept, State.zmm, zjoin_split, and_self]",
      "", "end P16", ""]
def write_if_changed(path, content):
    try:
        with open(path, encoding="utf-8") as f:
            if f.read() == content:
                return
    except FileNotFoundError:
        pass
    with open(path, "w", encoding="utf-8") as f:
        f.write(content)


write_if_changed(f"{out_dir}/P16Round.lean", "\n".join(t))
print(f"round: head 0x{head:X}; state words in ZMM {STATE}; message words in ZMM {MSG}; wrote P16Round.lean")

# Second round of the loop (0x18629 -> 0x188E9): same state registers, permuted message words.
PERM = [2, 6, 3, 10, 7, 0, 4, 13, 1, 11, 12, 5, 9, 14, 15, 8]
r2 = h + 114
assert all(x.split()[0] in (".zpaddd", ".zpxord", ".zprord") for x in ins[r2:r2 + 112])
assert ins[r2 + 112].startswith(".dec32")
c1, d1, e1, f1, u1, v1 = roles(r2)
c2, d2, e2, f2, u2, v2 = roles(r2 + 56)
assert c1 + d1 + e1 + f1 == STATE
MSG2 = [None] * 16
for i in range(4):
    MSG2[2 * i], MSG2[2 * i + 1], MSG2[8 + 2 * i], MSG2[9 + 2 * i] = u1[i], v1[i], u2[i], v2[i]
assert [MSG[p] for p in PERM] == MSG2, "second round must read PERMUTE of message registers"

Vp = lambda p: "#v[" + ", ".join(f"{p}{PERM[k]} i" for k in range(16)) + "]"
t2 = ["import P16Round", "open X86 Cells Blake3Generic", "",
      "/-! # The second round of the wide parent kernel's loop body",
      "",
      "Written by gen_p16.py from the kernel's lifted instructions. Before the message registers are rotated,",
      "the second 112 instructions read the permuted message words directly from them. -/", "",
      "namespace P16", "",
      "set_option maxRecDepth 1000000 in", "set_option maxHeartbeats 0 in",
      f"/-- **Second round.** The 112 instructions at 0x{at[r2]:X} are the specification's round on the state",
      "words of every lane, with `PERMUTE` of that lane's message words. -/",
      f"theorem round2 ({lanes('s')} {lanes('m')} : Nat → BitVec 32) (st : State) (hpc : st.pc = 0x{at[r2]:X})",
      f"    (hv : Rows st {lanes('s')}) (hm : Msgs st {lanes('m')}) :",
      f"    ∃ st', steps Code_p16.prog 112 st = some st' ∧ st'.pc = 0x{at[r2 + 112]:X} ∧",
      "      Rows st' " + " ".join(f"(fun i => (rnd {V('s')} {Vp('m')})[{k}])" for k in range(16)) + " ∧",
      f"      Msgs st' {lanes('m')} ∧ Kept st st' := by",
      f"  obtain ⟨{FIELDS}, ⟨{WIDE}⟩⟩ := st",
      "  obtain ⟨" + ", ".join(f"hv{k}" for k in range(16)) + "⟩ := hv",
      "  obtain ⟨" + ", ".join(f"hm{k}" for k in range(16)) + "⟩ := hm",
      "  simp only [State.zmm] at hpc " + " ".join(f"hv{k}" for k in range(16)) + " " + " ".join(f"hm{k}" for k in range(16)),
      "  subst hpc"] + splits + [
      "  run_fn [zjoin_split, zlo_zjoin, zhi_zjoin]",
      "  refine ⟨_, rfl, rfl, ?_, ?_, ?_⟩",
      "  · simp only [Rows, State.zmm, zjoin_split]",
      "    refine ⟨" + ", ".join(["?_"] * 16) + "⟩ <;>",
      "      (apply zpack_congr; intro i hi; simp only [zjoin_split, zdw_zmap2 _ _ _ hi, zdw_zmap1 _ _ hi, zdw_xor _ _ _ hi, zdw_zpack _ i hi]; eval_spec; bv_decide (config := { timeout := 900 }))",
      "  · simp only [Msgs, State.zmm, zjoin_split, and_self]",
      "  · simp only [Kept, State.zmm, zjoin_split, and_self]",
      "", "end P16", ""]
write_if_changed(f"{out_dir}/P16Round2.lean", "\n".join(t2))
print(f"round2: 0x{at[r2]:X} -> 0x{at[r2 + 112]:X}; wrote P16Round2.lean")
