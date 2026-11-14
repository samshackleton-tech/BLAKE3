#!/usr/bin/env python3
"""Write the proofs about the 32-lane chunk kernel K32 from its lifted instructions (BLAKE3 #361).

usage: gen_k32.py ROWS OUT_DIR        (ROWS: Lifted_k32.lean.rows, from try_kernel.sh; ROWS's .data beside it)

So far:
  K32Round.lean  the 240 instructions of the round loop's body are the specification's round in each of the 32
                 lanes (two halves of sixteen), with the message words read through the schedule row `rdi` points at;
  K32Loop.lean   the round loop: seven turns of it are the specification's seven rounds (`rounds7`), given the
                 kernel's schedule table at `rdi` and the lanes' message words at `rsi`.
The registers a round reads and writes, and the schedule, are found here by following the instructions and the
object's read-only data; nothing about them is written by hand."""
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


# ---------------------------------------------------------------------------------------------------------------
# The round loop. The schedule: seven rows of sixteen 32-bit offsets, in the object's read-only data at the
# address `lea rdi` names (the lifter wrote it as a number).
lea = next(x for x in ins if x.startswith(".mov 64 (.reg .rdi) (.imm 0x"))
table_at = int(lea.split("(.imm ")[1].rstrip(")"), 16)
data_at, data_hex = open(sys.argv[1].replace(".rows", ".data")).read().split()
data = bytes.fromhex(data_hex)
base = table_at - int(data_at, 16)
SCHED = [[int.from_bytes(data[base + 64 * r + 4 * k:][:4], "little") for k in range(16)] for r in range(7)]
assert all(sorted(row) == [64 * w for w in range(16)] for row in SCHED), "a row of the schedule is the sixteen words' offsets, each once"
IDX = [[o // 64 for o in row] for row in SCHED]
PERM = IDX[1]
assert IDX[0] == list(range(16))
for r in range(1, 7):
    assert IDX[r] == [IDX[r - 1][PERM[k]] for k in range(16)], "row r is the specification's permutation of row r - 1"
exit_at = at[tail + 2]
tail_at = at[tail - 1]
lit = lambda n: f"0x{n:X}#64"
plus = lambda a, n: a if n == 0 else f"{a} + {lit(n)}"
KEEP = ["rbx", "rsp", "rbp", "rsi", "r9", "r12", "r13", "r14", "r15", "w.r10"]
kept = lambda a, b: " ∧ ".join(f"{b}.{r} = {a}.{r}" for r in KEEP) + f" ∧ {b}.mem = {a}.mem"
nm = lambda r: r.replace("w.", "")
KEPT = kept("st", "st'")
VA = lambda v: " ".join(f"(fun i => ({v} i)[{k}])" for k in range(16))
u = lambda n: " ".join(["_"] * n)
counts = " ∨ ".join(f"c = {n}#64" for n in range(7, 1, -1))
tail_proof = lambda: ["    obtain ⟨" + FIELDS + ", ⟨" + WIDE + "⟩⟩ := st",
                      "    simp only at hpc hr11; subst hpc hr11",
                      "    run_fn []",
                      "    exact ⟨_, rfl, rfl, rfl, rfl, fun _ => rfl, " + ", ".join(["rfl"] * (len(KEEP) + 1)) + "⟩"]
L = ["import K32Round", "open X86 Cells Blake3Generic", "",
     "/-! # The round loop of the 32-lane chunk kernel is the specification's seven rounds",
     "",
     "Written by gen_k32.py from the kernel's lifted instructions and the object's read-only data. A turn of the loop",
     "is a round (K32Round.lean) with the message words at the offsets of one row of the kernel's schedule table,",
     "then `rdi` moved to the next row. The table's rows are the specification's message permutation, applied",
     "0 to 6 times: checked here, row by row, when this file is written, and by Lean in `perm1` to `perm6`. -/", "",
     "namespace K32", "",
     "/-- The state words of the first half's lanes, as one vector a lane. -/",
     "abbrev RowsAV (st : State) (v : Nat → Vector (BitVec 32) 16) : Prop :=", f"  RowsA st {VA('v')}", "",
     "/-- The state words of the second half's lanes, as one vector a lane. -/",
     "abbrev RowsBV (st : State) (v : Nat → Vector (BitVec 32) 16) : Prop :=", f"  RowsB st {VA('v')}", "",
     "/-- The lanes' message words where the block loop puts them: word `k` of the first half's lanes (lane `i`'s",
     "in lane `i`) at `a + 64 k`, of the second half's 1024 bytes on. -/",
     "def BlocksAt (mem : Mem) (a : BitVec 64) (m n : Nat → Vector (BitVec 32) 16) : Prop :=",
     "  " + " ∧ ".join(f"mem.read512 ({plus('a', 64 * k)}) = some (zpack fun i => (m i)[{k}])" for k in range(16)) + " ∧",
     "  " + " ∧ ".join(f"mem.read512 ({plus('a', 1024 + 64 * k)}) = some (zpack fun i => (n i)[{k}])" for k in range(16)), "",
     "/-- The kernel's schedule table at `a`: seven rows of sixteen offsets, as the object's read-only data has them. -/",
     "def SchedAt (mem : Mem) (a : BitVec 64) : Prop :=",
     "  " + " ∧\n  ".join(" ∧ ".join(f"mem.read ({plus('a', 64 * r + 4 * k)}) 32 = some {SCHED[r][k]}#64" for k in range(16)) for r in range(7)), ""]
# the specification's permutation, r times, as the table's row r
for r in range(1, 7):
    lhs = "v"
    for _ in range(r): lhs = f"PERMUTE ({lhs})" if lhs != "v" else "PERMUTE v"
    rhs = "#v[" + ", ".join(f"v[{i}]" for i in IDX[r]) + "]"
    L += [f"theorem perm{r} (v : Vector (BitVec 32) 16) : {lhs} = {rhs} := by"]
    if r == 1:
        L += ["  ext i hi; rcases i with _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | i",
              "  all_goals first", "    | omega", "    | eval_spec", ""]
    else:
        L += [f"  rw [perm{r - 1}, perm1]",
              "  ext i hi; rcases i with _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | i",
              "  all_goals first", "    | omega",
              "    | (simp only [Vector.getElem_mk, List.getElem_toArray, List.getElem_cons_succ, List.getElem_cons_zero])", ""]
L += ["private theorem rowsA_zmm_eq {p q : State} {" + lanes("s") + " : Nat → BitVec 32}",
      f"    (hz : ∀ r, q.zmm r = p.zmm r) (hv : RowsA p {lanes('s')}) : RowsA q {lanes('s')} := by",
      "  simp only [RowsA, hz] at hv ⊢; exact hv", "",
      "private theorem rowsB_zmm_eq {p q : State} {" + lanes("s") + " : Nat → BitVec 32}",
      f"    (hz : ∀ r, q.zmm r = p.zmm r) (hv : RowsB p {lanes('s')}) : RowsB q {lanes('s')} := by",
      "  simp only [RowsB, hz] at hv ⊢; exact hv", "",
      "set_option maxRecDepth 1000000 in",
      f"/-- The loop's end when rounds remain (0x{tail_at:X}, 3 instructions): `rdi` to the next row, back to the head. -/",
      f"private theorem tail_next (c : BitVec 64) (st : State) (hpc : st.pc = 0x{tail_at:X}) (hr11 : st.w.r11 = c)",
      f"    (hc : {counts}) :",
      f"    ∃ st', steps Code_k32.prog 3 st = some st' ∧ st'.pc = 0x{head:X} ∧ st'.w.r11 = c - 1#64 ∧ st'.rdi = st.rdi + 0x40#64 ∧",
      f"      (∀ r, st'.zmm r = st.zmm r) ∧ {KEPT} := by",
      "  rcases hc with h | h | h | h | h | h <;> subst h <;>"] + ["  · " + x.strip() if i == 0 else x for i, x in enumerate(tail_proof())]
L += ["",
      "set_option maxRecDepth 1000000 in",
      f"/-- The loop's end after the seventh round: on to 0x{exit_at:X}. -/",
      f"private theorem tail_done (st : State) (hpc : st.pc = 0x{tail_at:X}) (hr11 : st.w.r11 = 1#64) :",
      f"    ∃ st', steps Code_k32.prog 3 st = some st' ∧ st'.pc = 0x{exit_at:X} ∧ st'.w.r11 = 0#64 ∧ st'.rdi = st.rdi + 0x40#64 ∧",
      f"      (∀ r, st'.zmm r = st.zmm r) ∧ {KEPT} := by"] + [x[2:] for x in tail_proof()] + [""]
ob1 = "⟨s1, e1, pc1, hA1, hB1, " + ", ".join(f"{nm(r)}1" for r in ["rbx", "rsp", "rbp", "rsi", "rdi", "r9", "r12", "r13", "r14", "r15", "w.r10", "w.r11"]) + ", _, _, mem1⟩"
ob2 = "⟨s2, e2, pc2, hr11_2, di2, hz2, " + ", ".join(f"{nm(r)}2" for r in KEEP) + ", mem2⟩"
closing = ["  · rw [show (243 : Nat) = 240 + 3 from rfl, steps_add, e1, Option.bind_some, e2]",
           "  · rw [di2, rdi1]",
           "  · simpa only [RowsAV, eta16] using rowsA_zmm_eq hz2 hA1",
           "  · simpa only [RowsBV, eta16] using rowsB_zmm_eq hz2 hB1",
           "  all_goals first"] + [f"    | (rw [{nm(r)}2, {nm(r)}1])" for r in KEEP] + ["    | (rw [mem2, mem1])"]
for name, pc_out, r11_out, hyp, call, doc in [
        ("turn", head, "c - 1#64", f" (hc : {counts})", "tail_next c s1 pc1 hr11_1 hc", "**A turn of the round loop with rounds to come** (243 instructions)"),
        ("turn_last", exit_at, "0#64", "", "tail_done s1 pc1 hr11_1", "**The last turn of the round loop** (243 instructions)")]:
    c = "c" if name == "turn" else "1#64"
    L += ["set_option maxRecDepth 1000000 in", "set_option maxHeartbeats 0 in",
          f"/-- {doc}: a round on every lane, with the message words",
          "at the offsets `rdi` points at, and `rdi` on to the next row. -/",
          f"theorem {name} (v w : Nat → Vector (BitVec 32) 16) ({lanes('m')} {lanes('n')} : Nat → BitVec 32) ({lanes('o')} : BitVec 64)",
          ("    (c : BitVec 64) " if name == "turn" else "    ") + f"(st : State) (hpc : st.pc = 0x{head:X}) (hr11 : st.w.r11 = {c}){hyp}",
          f"    (ha : RowsAV st v) (hb : RowsBV st w) (ho : Row st {lanes('o')}) (hm : Msgs st {lanes('o')} {lanes('m')} {lanes('n')}) :",
          f"    ∃ st', steps Code_k32.prog 243 st = some st' ∧ st'.pc = 0x{pc_out:X} ∧ st'.w.r11 = {r11_out} ∧ st'.rdi = st.rdi + 0x40#64 ∧",
          "      RowsAV st' (fun i => rnd (v i) #v[" + ", ".join(f"m{k} i" for k in range(16)) + "]) ∧",
          "      RowsBV st' (fun i => rnd (w i) #v[" + ", ".join(f"n{k} i" for k in range(16)) + "]) ∧",
          f"      {KEPT} := by",
          f"  obtain {ob1} :=",
          f"    round {u(64)} {u(16)} st hpc ha hb ho hm",
          f"  have hr11_1 : s1.w.r11 = {c} := by rw [r111]; exact hr11",
          f"  obtain {ob2} := {call}",
          "  refine ⟨s2, ?_, pc2, hr11_2, ?_, ?_, ?_, " + ", ".join(["?_"] * (len(KEEP) + 1)) + "⟩"] + closing + [""]
# seven turns
L += ["set_option maxRecDepth 1000000 in", "set_option maxHeartbeats 0 in",
      f"/-- **The round loop** (0x{head:X} to 0x{exit_at:X}, 1701 instructions): the specification's seven rounds on every lane of",
      "both halves, with that lane's message words. Memory and the registers the kernel keeps are as they were. -/",
      "theorem seven_rounds (v w m n : Nat → Vector (BitVec 32) 16) (st : State)",
      f"    (hpc : st.pc = 0x{head:X}) (hr11 : st.w.r11 = 7#64)",
      "    (ha : RowsAV st v) (hb : RowsBV st w) (hs : SchedAt st.mem st.rdi) (hm : BlocksAt st.mem st.rsi m n) :",
      f"    ∃ st', steps Code_k32.prog 1701 st = some st' ∧ st'.pc = 0x{exit_at:X} ∧",
      "      RowsAV st' (fun i => rounds7 (v i) (m i)) ∧ RowsBV st' (fun i => rounds7 (w i) (n i)) ∧",
      f"      {KEPT} := by",
      "  obtain ⟨" + ", ".join(f"hs_{r}_{k}" for r in range(7) for k in range(16)) + "⟩ := hs",
      "  obtain ⟨" + ", ".join(f"hma{k}" for k in range(16)) + ", " + ", ".join(f"hmb{k}" for k in range(16)) + "⟩ := hm"]
prev = "st"
for r in range(7):
    s = f"s{r + 1}"
    ms = " ".join(f"(fun i => (m i)[{IDX[r][k]}])" for k in range(16))
    ns = " ".join(f"(fun i => (n i)[{IDX[r][k]}])" for k in range(16))
    os_ = " ".join(f"{SCHED[r][k]}#64" for k in range(16))
    rows = "⟨" + ", ".join(f"hs_{r}_{k}" for k in range(16)) + "⟩"
    msgs = "⟨" + ", ".join(f"hma{IDX[r][k]}" for k in range(16)) + ", " + ", ".join(f"hmb{IDX[r][k]}" for k in range(16)) + "⟩"
    if r == 0:
        L += [f"  have ho0 : Row st {os_} := by unfold Row; exact {rows}",
              f"  have hm0 : Msgs st {os_} {ms} {ns} := by",
              "    unfold Msgs; simp only [BitVec.reduceAnd, BitVec.reduceAdd, BitVec.add_zero]", f"    exact {msgs}"]
    else:
        L += [f"  have ho{r} : Row {prev} {os_} := by",
              f"    unfold Row; rw [hmem{r}, hrdi{r}]; simp only [BitVec.add_assoc, BitVec.reduceAdd]", f"    exact {rows}",
              f"  have hm{r} : Msgs {prev} {os_} {ms} {ns} := by",
              f"    unfold Msgs; rw [hmem{r}, hrsi{r}]; simp only [BitVec.reduceAnd, BitVec.reduceAdd, BitVec.add_zero]", f"    exact {msgs}"]
    ob = f"⟨{s}, e{r + 1}, pc{r + 1}, r11_{r + 1}, di{r + 1}, hA{r + 1}, hB{r + 1}, " + ", ".join(f"{nm(q)}_{r + 1}" for q in KEEP) + f", mem{r + 1}⟩"
    count = f"{7 - r}#64"
    hr = "hr11" if r == 0 else f"r11_{r}'"
    hA, hB = ("ha", "hb") if r == 0 else (f"hA{r}", f"hB{r}")
    if r < 6:
        L += [f"  obtain {ob} :=",
              f"    turn _ _ {u(32)} {u(16)} {count} {prev} {'hpc' if r == 0 else f'pc{r}'} {hr} (by decide) {hA} {hB} ho{r} hm{r}",
              f"  have r11_{r + 1}' : {s}.w.r11 = {6 - r}#64 := by rw [r11_{r + 1}]; decide",
              f"  have hmem{r + 1} : {s}.mem = st.mem := by rw [mem{r + 1}" + (f", hmem{r}" if r else "") + "]",
              f"  have hrsi{r + 1} : {s}.rsi = st.rsi := by rw [rsi_{r + 1}" + (f", hrsi{r}" if r else "") + "]",
              f"  have hrdi{r + 1} : {s}.rdi = st.rdi + {lit(64 * (r + 1))} := by " + ("exact di1" if r == 0 else f"simp only [di{r + 1}, hrdi{r}, BitVec.add_assoc, BitVec.reduceAdd]")]
    else:
        L += [f"  obtain {ob} :=",
              f"    turn_last _ _ {u(32)} {u(16)} {prev} pc{r} {hr} {hA} {hB} ho{r} hm{r}"]
    prev = s
steps = " ".join("steps_add, e%d, Option.bind_some," % (r + 1) for r in range(6))
chain = lambda q: ", ".join(f"{nm(q)}_{r}" for r in range(7, 0, -1))
L += ["  refine ⟨s7, ?_, pc7, ?_, ?_, " + ", ".join(["?_"] * (len(KEEP) + 1)) + "⟩",
      "  · rw [show (1701 : Nat) = 243 + (243 + (243 + (243 + (243 + (243 + 243))))) from rfl,",
      f"      {steps} e7]",
      "  · simpa only [RowsAV, rounds7, eta16, " + ", ".join(f"← perm{r}" for r in range(1, 7)) + "] using hA7",
      "  · simpa only [RowsBV, rounds7, eta16, " + ", ".join(f"← perm{r}" for r in range(1, 7)) + "] using hB7",
      "  all_goals first"] + [f"    | (rw [{chain(q)}])" for q in KEEP] + ["    | (rw [mem7, hmem6])", "", "end K32", ""]
write_if_changed(f"{out_dir}/K32Loop.lean", "\n".join(L))
print(f"loop: 0x{head:X} to 0x{exit_at:X}; the schedule at 0x{table_at:X}; wrote K32Loop.lean")


# ---------------------------------------------------------------------------------------------------------------
# The block loop's loads: sixteen inputs' blocks loaded and transposed (112 instructions), then the sixteen
# message words stored at `rsi` (16 instructions); twice, for the two halves.
GPRS = ["rax", "rcx", "rdx", "rbx", "rsp", "rbp", "rsi", "rdi", "r8", "r9", "r12", "r13", "r14", "r15", "w.r10", "w.r11"]
ST = f"obtain ⟨{FIELDS}, ⟨{WIDE}⟩⟩ := st"
spill = next(i for i, x in enumerate(ins) if x == ".zstore true .rsp 0x900 15")
B = ["import K32Loop", "import K32Mem", "import P16Transpose", "open X86 Cells Blake3Generic", "",
     "/-! # The block loop's loads: sixteen blocks to sixteen message words, and the words to the stack",
     "",
     "Written by gen_k32.py from the kernel's lifted instructions. For each half of the lanes: the sixteen inputs'",
     "blocks are loaded (through the table of their addresses at `r12`, `r14` bytes into each), transposed into the",
     "sixteen message words (lane `i` of word `k` is input `i`'s word `k`), and stored at `rsi + 64 k`. -/", "",
     "namespace K32", ""]
for half, first, table, base in (("A", spill + 1, 0, 0), ("B", spill + 129, 16, 0x400)):
    for j in range(16):
        assert ins[first + 3 * j] == f".mov 64 (.reg .rax) (.mem .r12 0x{8 * (table + j):X})", ins[first + 3 * j]
        assert ins[first + 3 * j + 1] == f".zloadi {16 + j} .rax .r14 0x0" and ins[first + 3 * j + 2] == ".nop"
    assert all(x.split()[0] in (".zunpckldq", ".zunpckhdq", ".zunpcklqdq", ".zunpckhqdq", ".zshufi32x4") for x in ins[first + 48:first + 112])
    REG = []
    for k in range(16):
        f = ins[first + 112 + k].split()
        assert f[:4] == [".zstore", "true", ".rsi", f"0x{base + 64 * k:X}"], f
        REG.append(int(f[4]))
    assert sorted(REG) == list(range(15, 32))[:16] or sorted(REG) == sorted(REG) and len(set(REG)) == 16
    untouched = [r for r in range(32) if r not in REG and r not in range(16, 32)]
    assert untouched == list(range(15)), untouched
    A = lambda k: "rsi" if base + 64 * k == 0 else f"rsi + 0x{base + 64 * k:X}#64"
    idx = (lambda j: f"8 * {j}") if table == 0 else (lambda j: f"8 * ({table} + {j})")
    keep = [r for r in GPRS if r != "rax"]
    B += ["set_option maxRecDepth 1000000 in", "set_option maxHeartbeats 0 in",
          f"/-- **Half {half}: load and transpose** (0x{at[first]:X} to 0x{at[first + 112]:X}, 112 instructions). The sixteen blocks, at `r14`",
          f"bytes into the inputs whose addresses are at `r12 + {8 * table}`, become the sixteen message words, one register each. -/",
          f"theorem load_{half} (ptrs : Nat → BitVec 64) (m : Nat → Vector (BitVec 32) 16) (st : State)",
          f"    (hpc : st.pc = 0x{at[first]:X})",
          f"    (hp : ∀ j : Nat, j < 16 → Quad st.mem (st.r12 + BitVec.ofNat 64 ({idx('j')})) (ptrs j))",
          "    (hb : ∀ j : Nat, j < 16 → P16.BlockAt st.mem (ptrs j + st.r14) (m j)) :",
          f"    ∃ st', steps Code_k32.prog 112 st = some st' ∧ st'.pc = 0x{at[first + 112]:X} ∧",
          "      (" + " ∧ ".join(f"st'.zmm {REG[k]} = zpack (fun i => (m i)[{k}])" for k in range(16)) + ") ∧",
          "      (∀ r, r ≤ 14 → st'.zmm r = st.zmm r) ∧",
          "      " + " ∧ ".join(f"st'.{r} = st.{r}" for r in keep) + " ∧ st'.mem = st.mem := by"]
    B += [f"  have q{j} := read_quad (hp {j} (by decide))" for j in range(16)]
    B += [f"  have b{j} := P16.read512_blockAt (hb {j} (by decide))" for j in range(16)]
    qs, bs = " ".join(f"q{j}" for j in range(16)), " ".join(f"b{j}" for j in range(16))
    B += [f"  {ST}",
          f"  simp only [Nat.reduceMul, Nat.reduceAdd, BitVec.add_zero] at hpc {qs} {bs}",
          "  subst hpc",
          "  run_fn [BitVec.add_zero, " + ", ".join(f"q{j}" for j in range(16)) + ", " + ", ".join(f"b{j}" for j in range(16)) + ",",
          "    zjoin_split, zlo_zjoin, zhi_zjoin, P16.z16_ldq, P16.z16_hdq, P16.z16_lqdq, P16.z16_hqdq, P16.z16_shuf_88, P16.z16_shuf_dd]",
          "  refine ⟨_, rfl, rfl, ?_, ?_, " + ", ".join(["rfl"] * (len(keep) + 1)) + "⟩",
          "  · simp only [State.zmm, zjoin_split]",
          "    exact ⟨" + ", ".join(["rfl"] * 16) + "⟩",
          "  · intro r hr",
          "    rcases r with " + " | ".join(["_"] * 15) + " | r <;> first | omega | rfl", ""]
    # the stores
    M = ["mem"]
    for k in range(16): M.append(f"({M[k]}).put512 ({A(k)}) (v {k})" if k else f"mem.put512 ({A(0)}) (v 0)")
    def owned(k):
        o = f"o{k}"
        for j in range(k): o = f"owned64_put512 ({M[j]}) ({A(j)}) ({A(k)}) (v {j}) ({o})"
        return o
    target = "st.rsi" if base == 0 else f"(st.rsi + 0x{base:X}#64)"
    B += ["set_option maxRecDepth 1000000 in", "set_option maxHeartbeats 0 in",
          f"/-- **Half {half}: the sixteen message words to the stack** (0x{at[first + 112]:X} to 0x{at[first + 128]:X}, 16 instructions). -/",
          f"theorem store_{half} (v : Nat → Z) (st : State) (hpc : st.pc = 0x{at[first + 112]:X}) (hal : aligned64 st.rsi = true)",
          f"    (ho : ∀ k : Nat, k < 16 → Owned64 st.mem (st.rsi + BitVec.ofNat 64 ({base} + 64 * k)))",
          "    (hr : " + " ∧ ".join(f"st.zmm {REG[k]} = v {k}" for k in range(16)) + ") :",
          f"    ∃ st', steps Code_k32.prog 16 st = some st' ∧ st'.pc = 0x{at[first + 128]:X} ∧ st'.mem = puts16 st.mem {target} v ∧",
          "      (∀ r, st'.zmm r = st.zmm r) ∧ " + " ∧ ".join(f"st'.{r} = st.{r}" for r in GPRS) + " := by"]
    B += [f"  have a{k} : aligned64 (st.rsi + 0x{base + 64 * k:X}#64) = true := aligned64_add hal (by decide)" for k in range(16) if base + 64 * k]
    B += [f"  have o{k} := ho {k} (by decide)" for k in range(16)]
    B += ["  obtain ⟨" + ", ".join(f"hr{k}" for k in range(16)) + "⟩ := hr", f"  {ST}",
          "  simp only [State.zmm, Nat.reduceMul, Nat.reduceAdd, BitVec.add_zero] at hpc hal " + " ".join(f"a{k}" for k in range(16) if base + 64 * k) + " " + " ".join(f"o{k}" for k in range(16)) + " " + " ".join(f"hr{k}" for k in range(16)),
          "  subst hpc"]
    for k, r in enumerate(REG):
        if r < 16:
            B += [f"  have e{r} : x{r} = zlo (v {k}) := by rw [← hr{k}, zlo_zjoin]", f"  have f{r} : u{r} = zhi (v {k}) := by rw [← hr{k}, zhi_zjoin]", f"  subst e{r} f{r}"]
        else:
            B += [f"  subst hr{k}"]
    B += [f"  have w{k} := write512_of ({owned(k)}) (v {k})" for k in range(16)]
    B += ["  run_fn [hal, " + ", ".join(f"a{k}" for k in range(16) if base + 64 * k) + ", " + ", ".join(f"w{k}" for k in range(16)) + ", zjoin_split, zlo_zjoin, zhi_zjoin]",
          "  refine ⟨_, rfl, rfl, ?_, ?_, " + ", ".join(["rfl"] * len(GPRS)) + "⟩",
          "  · simp only [puts16, BitVec.add_assoc, BitVec.reduceAdd]",
          "  · intro r; simp only [State.zmm, zjoin_split]", ""]
B += ["end K32", ""]
write_if_changed(f"{out_dir}/K32Block.lean", "\n".join(B))
print(f"block: the loads at 0x{at[spill + 1]:X} and 0x{at[spill + 129]:X}; wrote K32Block.lean")


# ---------------------------------------------------------------------------------------------------------------
# A block's set-up (the flags of this block, the sixteen state words of every lane) and its end (the new
# chaining values, on to the next block or out of the loop).
reload = ins.index(".zload true 15 .rsp 0x900")
assert reload == spill + 257 and ins[h - 3] == lea and ins[h - 2] == ".mov 32 (.reg .r11) (.imm 0x7)" and ins[h - 1] == ".nop"
ff = tail + 2
assert all(ins[ff + k] == f".zpxord {STATE_A[k]} {STATE_A[k]} {STATE_A[8 + k]}" for k in range(8))
assert all(ins[ff + 8 + k] == f".zpxord {STATE_B[k]} {STATE_B[k]} {STATE_B[8 + k]}" for k in range(8))
assert ins[ff + 16:ff + 19] == [".add 64 (.reg .r14) (.imm 0x40)", ".dec64 .r13", f".jne 0x{at[spill]:X}"]
out_at = at[ff + 19]
skip_start = int(ins[reload + 3].split()[1], 16); skip_end = int(ins[reload + 10].split()[1], 16)
n_start = at.index(skip_start) - (reload + 4); n_end = at.index(skip_end) - (reload + 11)
assert ins[reload + 2] == ".test 64 (.reg .r14) (.reg .r14)" and ins[reload + 3].startswith(".jne") and ins[reload + 9] == ".cmp 64 (.reg .r13) (.imm 0x1)"
total = h - reload
KEEP2 = ["rbx", "rsp", "rbp", "rsi", "r9", "r12", "r13", "r14", "r15", "w.r10"]
kept2 = " ∧ ".join(f"st'.{r} = st.{r}" for r in KEEP2) + " ∧ st'.mem = st.mem"
V8 = lambda v: " ∧ ".join(f"st.zmm {{r}} = zpack (fun i => ({v} i)[{k}])" for k in range(8))
def splits_for(pairs):
    """`pairs`: (register, hypothesis, value) of whole registers the hypotheses name."""
    out = []
    for r, name, val in pairs:
        if r < 16:
            out += [f"  have e{r} : x{r} = zlo ({val}) := by rw [← {name}, zlo_zjoin]", f"  have f{r} : u{r} = zhi ({val}) := by rw [← {name}, zhi_zjoin]", f"  subst e{r} f{r}"]
        else:
            out.append(f"  subst {name}")
    return out
H = ["import K32Loop", "open X86 Cells Blake3Generic", "",
     "/-! # A block of the 32-lane chunk kernel: its set-up and its end",
     "",
     "Written by gen_k32.py from the kernel's lifted instructions. Before the rounds: this block's flags (the chunk's",
     "start flag on the first block, its end flag on the last), and the sixteen state words of every lane (the",
     "chaining value, the IV, the lane's counter, the block length, the flags). After them: the new chaining value",
     "(the two halves of the state, xored), the block offset moved on, and back for the next block or out. -/", "",
     "namespace K32", "",
     "/-- The chaining values of the first half's lanes: word `k` in ZMM `k`. -/",
     "def CvA (st : State) (c : Nat → Vector (BitVec 32) 8) : Prop :=",
     "  " + " ∧ ".join(f"st.zmm {STATE_A[k]} = zpack (fun i => (c i)[{k}])" for k in range(8)), "",
     "/-- The chaining values of the second half's lanes. -/",
     "def CvB (st : State) (c : Nat → Vector (BitVec 32) 8) : Prop :=",
     "  " + " ∧ ".join(f"st.zmm {STATE_B[k]} = zpack (fun i => (c i)[{k}])" for k in range(8)), "",
     "/-- The second half's chaining values but the last word, whose register the loads borrow (it waits on the stack). -/",
     "def CvB7 (st : State) (c : Nat → Vector (BitVec 32) 8) : Prop :=",
     "  " + " ∧ ".join(f"st.zmm {STATE_B[k]} = zpack (fun i => (c i)[{k}])" for k in range(7)), "",
     "/-- The lanes' counters where the kernel keeps them: low words and high words of each half, at `a + 2048`. -/",
     "def Counters (mem : Mem) (a : BitVec 64) (tA tB : Nat → BitVec 64) : Prop :=",
     "  mem.read512 (a + 0x800#64) = some (zpack fun i => (tA i).setWidth 32) ∧",
     "  mem.read512 (a + 0x840#64) = some (zpack fun i => ((tA i) >>> 32).setWidth 32) ∧",
     "  mem.read512 (a + 0x880#64) = some (zpack fun i => (tB i).setWidth 32) ∧",
     "  mem.read512 (a + 0x8C0#64) = some (zpack fun i => ((tB i) >>> 32).setWidth 32)", ""]
assert STATE_B[7] == 15
for name, fl, steps, conds, substs, extra, doc in [
        ("first", "flags.setWidth 32 ||| 1#32", total - n_end, "(hr14 : st.r14 = 0#64) (hz13 : (st.r13 - 1#64 == 0#64) = false)", "hr14", "hz13", "the chunk's first block (the start flag)"),
        ("mid", "flags.setWidth 32", total - n_start - n_end, "(hz14 : (st.r14 &&& st.r14 == 0#64) = false) (hz13 : (st.r13 - 1#64 == 0#64) = false)", "", "hz14, hz13", "a block that is neither the first nor the last"),
        ("last", "flags.setWidth 32 ||| 2#32", total - n_start, "(hz14 : (st.r14 &&& st.r14 == 0#64) = false) (hr13 : st.r13 = 1#64)", "hr13", "hz14", "the chunk's last block (the end flag)")]:
    regs = [(STATE_A[k], f"ha{k}", f"zpack (fun i => (cA i)[{k}])") for k in range(8)] + [(STATE_B[k], f"hb{k}", f"zpack (fun i => (cB i)[{k}])") for k in range(7)]
    hyps = " ".join(x.strip() for x in extra.split(",")) + (" " + substs if substs else "")
    H += ["set_option maxRecDepth 1000000 in", "set_option maxHeartbeats 0 in",
          f"/-- **A block's set-up, for {doc}** (0x{at[reload]:X} to 0x{head:X}, {steps} instructions). -/",
          f"theorem hdr_{name} (cA cB : Nat → Vector (BitVec 32) 8) (tA tB : Nat → BitVec 64) (flags : BitVec 64) (st : State)",
          f"    (hpc : st.pc = 0x{at[reload]:X}) (hal : aligned64 st.rsp = true)",
          "    (hbx : st.rbx = flags ||| 0x40020100#64) (hf : flags < 256#64)",
          f"    {conds}",
          "    (ha : CvA st cA) (hb : CvB7 st cB) (hs : st.mem.read512 (st.rsp + 0x900#64) = some (zpack fun i => (cB i)[7]))",
          "    (ht : Counters st.mem st.rsp tA tB) :",
          f"    ∃ st', steps Code_k32.prog {steps} st = some st' ∧ st'.pc = 0x{head:X} ∧ st'.w.r11 = 7#64 ∧ st'.rdi = 0x{table_at:X}#64 ∧",
          f"      RowsAV st' (fun i => initv (cA i) (tA i) 64#32 ({fl})) ∧ RowsBV st' (fun i => initv (cB i) (tB i) 64#32 ({fl})) ∧",
          f"      {kept2} := by"]
    H += [f"  have a{c:X} : aligned64 (st.rsp + 0x{c:X}#64) = true := aligned64_add hal (by decide)" for c in (0x800, 0x840, 0x880, 0x8C0, 0x900)]
    H += ["  obtain ⟨" + ", ".join(f"ha{k}" for k in range(8)) + "⟩ := ha", "  obtain ⟨" + ", ".join(f"hb{k}" for k in range(7)) + "⟩ := hb",
          "  obtain ⟨ht0, ht1, ht2, ht3⟩ := ht", f"  {ST}",
          "  simp only [State.zmm] at hpc hal a800 a840 a880 a8C0 a900 hbx hs ht0 ht1 ht2 ht3 " + hyps + " " + " ".join(f"ha{k}" for k in range(8)) + " " + " ".join(f"hb{k}" for k in range(7)),
          "  subst hpc hbx" + (" " + substs if substs else "")] + splits_for(regs) + [
          "  run_fn [a800, a840, a880, a8C0, a900, hs, ht0, ht1, ht2, ht3, " + extra + ", zjoin_split, zlo_zjoin, zhi_zjoin]",
          "  refine ⟨_, rfl, rfl, rfl, ?_, ?_, " + ", ".join(["rfl"] * (len(KEEP2) + 1)) + "⟩",
          "  · simp only [RowsAV, RowsA, State.zmm, zjoin_split, initv, zbroadcast, Vector.getElem_mk, List.getElem_toArray, List.getElem_cons_succ, List.getElem_cons_zero]",
          "    refine ⟨" + ", ".join(["?_"] * 16) + "⟩ <;> first | rfl | trivial | (exact congrArg zpack (funext fun _ => by bv_decide))",
          "  · simp only [RowsBV, RowsB, State.zmm, zjoin_split, initv, zbroadcast, Vector.getElem_mk, List.getElem_toArray, List.getElem_cons_succ, List.getElem_cons_zero]",
          "    refine ⟨" + ", ".join(["?_"] * 16) + "⟩ <;> first | rfl | trivial | (exact congrArg zpack (funext fun _ => by bv_decide))", ""]
KEEP3 = ["rbx", "rsp", "rbp", "rsi", "r9", "r12", "r15", "w.r10"]
kept3 = " ∧ ".join(f"st'.{r} = st.{r}" for r in KEEP3) + " ∧ st'.mem = st.mem"
for name, cond, subst, extra, pc_out, doc in [
        ("next", "(hz13 : (st.r13 - 1#64 == 0#64) = false)", "", "hz13, ", at[spill], "with blocks to come: back to the block loop's head"),
        ("done", "(hr13 : st.r13 = 1#64)", " hr13", "", out_at, "after the last block: out of the loop")]:
    regs = [(STATE_A[k], f"ha{k}", f"zpack (fun i => (v i)[{k}])") for k in range(16)] + [(STATE_B[k], f"hb{k}", f"zpack (fun i => (w i)[{k}])") for k in range(16)]
    H += ["set_option maxRecDepth 1000000 in", "set_option maxHeartbeats 0 in",
          f"/-- **A block's end, {doc}** (0x{at[ff]:X}, 19 instructions): the new chaining value of every lane is",
          "the two halves of its state, xored; the block offset moves on by 64. -/",
          f"theorem ff_{name} (v w : Nat → Vector (BitVec 32) 16) (st : State) (hpc : st.pc = 0x{at[ff]:X}) {cond}",
          "    (ha : RowsAV st v) (hb : RowsBV st w) :",
          f"    ∃ st', steps Code_k32.prog 19 st = some st' ∧ st'.pc = 0x{pc_out:X} ∧ st'.r13 = st.r13 - 1#64 ∧ st'.r14 = st.r14 + 0x40#64 ∧",
          "      CvA st' (fun i => low8 (v i)) ∧ CvB st' (fun i => low8 (w i)) ∧",
          f"      {kept3} := by",
          "  obtain ⟨" + ", ".join(f"ha{k}" for k in range(16)) + "⟩ := ha", "  obtain ⟨" + ", ".join(f"hb{k}" for k in range(16)) + "⟩ := hb", f"  {ST}",
          "  simp only [State.zmm] at hpc " + (cond.split(" ")[0].strip("(") + " " if True else "") + " ".join(f"ha{k} hb{k}" for k in range(16)),
          "  subst hpc" + subst] + splits_for(regs) + [
          f"  run_fn [{extra}zjoin_split, zlo_zjoin, zhi_zjoin, zxor_pack]",
          "  refine ⟨_, rfl, rfl, rfl, ?_, ?_, " + ", ".join(["rfl"] * (len(KEEP3) + 1)) + "⟩",
          "  · simp only [CvA, State.zmm, zjoin_split, low8, Vector.getElem_mk, List.getElem_toArray, List.getElem_cons_succ, List.getElem_cons_zero, and_self]",
          "  · simp only [CvB, State.zmm, zjoin_split, low8, Vector.getElem_mk, List.getElem_toArray, List.getElem_cons_succ, List.getElem_cons_zero, and_self]", ""]
H += ["end K32", ""]
write_if_changed(f"{out_dir}/K32Head.lean", "\n".join(H))
print(f"head: set-up 0x{at[reload]:X} ({total - n_end}, {total - n_start - n_end}, {total - n_start} instructions), end 0x{at[ff]:X} to 0x{at[spill]:X} or 0x{out_at:X}; wrote K32Head.lean")
