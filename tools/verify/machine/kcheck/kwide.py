#!/usr/bin/env python3
"""kwide: a prover of a wide kernel's loop, for kfn.py's verifier. Nothing here is trusted, and no verification
loads this file.

    python3 kwide.py SYMBOL OBJECT --find PROOF.json [--smallest] [--from START]

kfn.py takes a loop whose count the path does not fix by a PLACE: one instruction the code passes once a
turn, and what the registers hold there after any number of turns (its page says what "holds" means and how
it is shown). This program guesses that: it runs the code for two turns to see which instruction a backward
branch comes to once a turn, then compares the second and the third coming to it. What is the same is "keep";
a number that moved by the same amount is one that moves with the turns; a ZMM register that holds the
specification's value for sixteen lanes is a word of it; the rest is not named. A guess the verifier refuses
at one register is weakened there and tried again. `--smallest`: every name the verifier does not need is
taken out again.

(This was kloop.py's prover, on kloop.py's own machine; since November 17, 2026 the kernels are verified by
kfn.py as every other function is, and the prover runs kfn.py's machine. The audits use it as an adversary:
kflip.py asks it for a proof of every changed kernel, and what the verifier then accepts is run on a processor.)"""
import copy, json, os, sys, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import kfn, kspec, kterms, ode
from kterms import Fail
from klin import Lin, sym, lin

B = sym("b")            # the proof's name for the turns done


def guess(rows, data, symbol, entry):
    c, T = kfn.contract(symbol), kterms.Terms()
    turns = kfn.Turns(c)
    lanes, budget = range(turns.lanes), [kfn.STEPS]
    # the place: where a backward branch comes to once a turn (with two turns: twice)
    m = kfn.Machine(T, rows, c, data); m.pc = entry
    m.facts.assume_zero(turns.count(m, 0) - 2)
    passed, back, index = {}, set(), {r[0]: r for r in rows}
    while m.pc is not None:
        pc = m.pc; passed[pc] = passed.get(pc, 0) + 1
        if sum(passed.values()) > kfn.STEPS: raise Fail("still running")
        try: m.one()
        except kfn.Fork: raise Fail("with two turns the code does not run by one path")
        if m.pc is not None and m.pc <= pc and index[pc][2].split()[0] in (".je", ".jne", ".jmp"): back.add(m.pc)
    places = sorted(p for p in back if passed[p] == 2)
    if not places: raise Fail("no place the code passes once a turn")
    head = places[0]
    # the first, the second and the third coming to the place
    m = kfn.Machine(T, rows, c, data); m.pc = entry
    ends = kfn.paths(m, budget, head)
    if len(ends) != 1 or ends[0].pc != head: raise Fail("from the entry the code does not come to the place by one path")
    first = ends[0]
    second = [e for e in kfn.paths(first.rested(), budget, head) if e.pc == head]
    if len(second) != 1: raise Fail("the first turn does not lead back to the place by one path")
    second = second[0]
    third = [e for e in kfn.paths(second.rested(), budget, head) if e.pc == head]
    if len(third) != 1: raise Fail("the second turn does not lead back to the place by one path")
    third = third[0]
    words = {}
    after2 = [turns.turn(third, lane, turns.turn(third, lane, turns.first(third, lane), 0), 1) for lane in lanes]
    for lane0 in range(0, turns.lanes, 16):
        for w in range(8): words[tuple(after2[lane0 + k][w] for k in range(16))] = [lane0, w]
    proof = dict(place=head - kfn.BASE, registers={}, vectors={}, frame={})
    for r in kfn.G64:
        v1, v2 = second.g[r], third.g[r]
        if v1 == v2: proof["registers"][r] = "keep"
        elif lin(v1) is not None and lin(v2) is not None and not (lin(v2) - lin(v1)).c:
            g = lin(v1) + (B - 1).scale((lin(v2) - lin(v1)).k)              # as it was after one turn, and its move a turn
            proof["registers"][r] = {"lin": {**{s: a for s, a in g.c}, "1": g.k}}
    for r in range(32):
        if third.x.get(r) in words: proof["vectors"][str(r)] = {"cv": words[third.x[r]]}
        elif len(second.x.get(r, ())) == 16 and second.x[r] == third.x.get(r): proof["vectors"][str(r)] = "keep"
    if second.wide is not None and third.wide is not None:
        for off, cell in second.mem["wide"].items():
            if third.mem["wide"].get(off) == cell: proof["frame"][str(off - second.g["rsp"][2])] = "keep"
    return proof


def find(rows, data, symbol, entry):
    """A proof kfn.py's verifier takes, or Fail."""
    proof = guess(rows, data, symbol, entry)
    # weaken where the verifier refuses, one name at a time
    for _ in range(96):
        try:
            kfn.check(rows, None, proof=proof, symbol=symbol, entry=entry, data=data); return proof
        except Fail as e:
            msg = str(e)
            weak = next((r for r in list(proof["registers"]) if f": {r} is " in msg), None)
            if weak is not None: del proof["registers"][weak]; continue
            weak = next((r for r in list(proof["vectors"]) if f"zmm{r} at the place" in msg and proof["vectors"][r] == "keep"), None)
            if weak is not None: del proof["vectors"][weak]; continue
            weak = next((off for off in list(proof["frame"]) if "the frame's cell at " in msg and msg.rstrip().endswith(" is not kept") and proof["frame"].pop(off, None)), None)
            if weak is not None: continue
            raise
    raise Fail("no proof found")


def smallest(rows, data, symbol, entry, proof):
    """The proof with every name taken out that the verifier does not need: what is left is what the loop rests on."""
    proof = copy.deepcopy(proof)
    for part in ("registers", "vectors", "frame"):
        for key in list(proof[part]):
            kept = proof[part].pop(key)
            try: kfn.check(rows, None, proof=proof, symbol=symbol, entry=entry, data=data)
            except Fail: proof[part][key] = kept
    return proof


def main():
    symbol, obj, path = sys.argv[1], sys.argv[2], sys.argv[sys.argv.index("--find") + 1]
    start = sys.argv[sys.argv.index("--from") + 1] if "--from" in sys.argv else symbol
    spec = sys.argv[sys.argv.index("--spec") + 1] if "--spec" in sys.argv else None
    here = os.path.dirname(os.path.abspath(__file__))
    with open(spec or os.path.join(here, "blake3.spec")) as f: text = f.read()
    with open(os.path.join(here, "proofs", "inner.spec")) as f: inner = f.read()
    kspec.SPEC = ode.with_proof(text, inner); kfn.CONTRACTS.clear()
    rows, data, entry = kfn.load_from(obj, symbol, start)
    t0 = time.time()
    proof = find(rows, data, symbol, entry)
    if "--smallest" in sys.argv: proof = smallest(rows, data, symbol, entry, proof)
    with open(path, "w") as f: json.dump(proof, f, indent=1)
    print(f"{symbol}: a proof found in {time.time() - t0:.2f} s and written to {path} ({os.path.getsize(path)} bytes): the place +0x{proof['place']:X}, "
          f"{len(proof['registers'])} registers, {len(proof['vectors'])} vector registers, {len(proof['frame'])} frame cells named")
    return 0


if __name__ == "__main__":
    try: sys.exit(main())
    except Fail as e: print(f"{sys.argv[1]}: no proof: {e}"); sys.exit(1)
