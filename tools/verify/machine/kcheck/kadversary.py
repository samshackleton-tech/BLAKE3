#!/usr/bin/env python3
"""kadversary: an audit of the verifier by a prover that tries to get changed code accepted.

    [LIBS=...] python3 kadversary.py PROGRAM FUNCTION OBJECT HARNESS.c ARGS... [--limit TRIES] [--jobs N]

The flips and the left-out instructions (kbyte_flip.py, kbyte_nop.py) ask the verifier of changed code with
the proof written for the unchanged code. Most are refused because that proof no longer fits; that says
little about whether SOME proof would get the changed code accepted. Here each instruction of a function is
left out in turn, and for each changed object the verifier refuses with the proof it has, a prover
(kplace.py: it guesses the place of a loop, led by the verifier's refusals) looks for another proof.
Every changed object accepted, with the proof as written or with one the prover found, is run on this
machine's processor (the program's harness): it must keep the contract.

Exit 1 if an accepted object does not. For functions with one loop (what kplace.py takes)."""
import multiprocessing, os, subprocess, sys, tempfile
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import kbyte, kcheck, kdecode, kplace, ode


def setup(argv):
    global program, function, obj, rows, spec, proof, sec, start, symbol, limit
    args = [a for k, a in enumerate(argv) if not a.startswith("--") and (k == 0 or argv[k - 1] not in ("--limit", "--jobs"))]
    program, function, obj_path, harness = args[:4]
    symbol = "ode_" + function
    limit = int(argv[argv.index("--limit") + 1]) if "--limit" in argv else 150
    with open(obj_path, "rb") as f: obj = f.read()
    text = open(os.path.join(HERE, "programs", program, program + ".spec")).read()
    lemmas = os.path.join(HERE, "programs", program, program + ".lemmas")
    spec = ode.with_proof(text, open(lemmas).read()) if os.path.exists(lemmas) else ode.Spec(text)
    proof = open(os.path.join(HERE, "programs", program, function + ".proof")).read()
    e = kdecode.Elf(obj)
    sec, start = e.sections[e.index[".text"]], kdecode.address(obj, symbol)
    rows = kbyte.load(obj, symbol)
    return harness, args[4:]


def without(k):
    a, z, i = rows[k]
    b = bytearray(obj)
    lo, hi = sec["off"] + start + a - kbyte.BASE, sec["off"] + start + z - kbyte.BASE
    b[lo:hi] = b"\x90" * (hi - lo)
    return bytes(b)


def one(k):
    """(k, "as written" | "found" | None, the proof found)"""
    b = without(k)
    try: changed = kbyte.load(b, symbol)
    except (kdecode.Stop, kcheck.Fail, IndexError, ValueError, KeyError, StopIteration): return k, None, None
    if kplace.verdict(changed, spec, symbol, proof) is None: return k, "as written", None
    try: found, tries = kplace.guess(changed, spec, symbol, limit=limit)
    except (KeyError, IndexError, ValueError, TypeError, AssertionError, RecursionError, AttributeError): found = None
    if found is not None and kplace.verdict(changed, spec, symbol, found) is None: return k, "found", found
    return k, None, None


def main():
    harness, args = setup(sys.argv[1:])
    jobs = int(sys.argv[sys.argv.index("--jobs") + 1]) if "--jobs" in sys.argv else int(os.environ.get("JOBS", "4"))
    work = tempfile.mkdtemp()
    subprocess.run(["cc", "-O1", "-c", "-o", f"{work}/h.o"] + os.environ.get("CFLAGS", "").split() + [harness], check=True)
    # the control: the unchanged code is shown by a proof the prover finds (else it finds nothing, and this audit asks nothing)
    found, tries = kplace.guess(rows, spec, symbol, limit=max(limit, 400))
    if found is None: print(f"{symbol}: CONTROL FAILED: the prover finds no proof of the unchanged code"); return 2
    candidates = [k for k, (a, z, i) in enumerate(rows) if not (i.startswith((".push", ".pop")) or i in (".ret", ".nop"))]
    with multiprocessing.get_context("fork").Pool(jobs) as pool: results = pool.map(one, candidates, chunksize=1)        # (fork: the workers have what was read here)
    counts, wrong = {"as written": 0, "found": 0}, 0
    for k, how, text in results:
        if how is None: continue
        counts[how] += 1
        a, z, i = rows[k]
        o, exe = f"{work}/m.o", f"{work}/m"
        with open(o, "wb") as f: f.write(without(k))
        r = subprocess.run(["cc", "-o", exe, f"{work}/h.o", o] + os.environ.get("LIBS", "").split(), capture_output=True, text=True)
        if r.returncode: print("not linked", r.stderr[-200:]); wrong += 1; continue
        try: r = subprocess.run([exe] + args, capture_output=True, text=True, timeout=300); ok = r.returncode == 0
        except subprocess.TimeoutExpired: ok, r = False, None
        if how == "found": print(f"  +{a - kbyte.BASE:#x} {i} left out: refused with the proof as written; ACCEPTED with a proof the prover found; the processor: {'keeps the contract' if ok else 'DOES NOT'}")
        if not ok:
            wrong += 1
            print(f"ACCEPTED ({how}), AND THE PROCESSOR SAYS NO: +{a - kbyte.BASE:#x} {i}: {(r.stdout.strip()[:150] if r else 'still running')}")
            if text: print("    " + text.replace("\n", "\n    "))
    n = len(candidates)
    print(f"{symbol}: {len(rows)} instructions; {n} left out in turn: {counts['as written']} accepted with the proof as written, {counts['found']} more with a proof the prover found, "
          f"{n - counts['as written'] - counts['found']} with none (the prover's limit: {limit} tries); on the processor {counts['as written'] + counts['found'] - wrong} of the accepted keep the contract, {wrong} do not")
    return 1 if wrong else 0


if __name__ == "__main__":
    sys.exit(main())
