#!/usr/bin/env python3
"""kbyte_nop: every instruction of a function left out in turn (its bytes made no-ops), checked by kbyte.py; each
such object it accepts is run on this machine's processor (the harness, as kbyte_flip.py runs it).

    [JOBS=N] [CFLAGS=...] [LIBS=...] python3 kbyte_nop.py SPEC SYMBOL OBJECT PROOF HARNESS.c ARGS...

Exit 1 if an object the verifier accepts does not keep the contract on the processor."""
import multiprocessing, os, subprocess, sys, tempfile
sys.path.insert(0, os.getcwd())
import kbyte, kbyte_flip, kdecode
spec_path, symbol, obj_path, proof_path, harness = sys.argv[1:6]
args = sys.argv[6:]
spec_text, proof = open(spec_path).read(), open(proof_path).read()
obj = open(obj_path, "rb").read()
e = kdecode.Elf(obj)
sec, start = e.sections[e.index[".text"]], kdecode.address(obj, symbol)
rows = kbyte.load(obj, symbol)
work = tempfile.mkdtemp()
subprocess.run(["cc", "-O1", "-c", "-o", f"{work}/h.o"] + os.environ.get("CFLAGS", "").split() + [harness], check=True)
def without(k):
    a, z, i = rows[k]
    b = bytearray(obj)
    lo, hi = sec["off"] + start + a - kbyte.BASE, sec["off"] + start + z - kbyte.BASE
    b[lo:hi] = b"\x90" * (hi - lo)
    return b


def taken(k):
    return kbyte_flip.verdict(bytes(without(k)), spec_text, symbol, proof)[0] == "ACCEPTED"


candidates = [k for k, (a, z, i) in enumerate(rows) if not (i.startswith((".push", ".pop")) or i in (".ret", ".nop"))]
with multiprocessing.get_context("fork").Pool(int(os.environ.get("JOBS", "8"))) as pool:          # the verifier's word on each, side by side (a refusal can take it seconds). fork: the workers have what was read above (Python 3.14 starts workers afresh by default, and this file then fell over: the audit of November 16)
    verdicts = pool.map(taken, candidates, chunksize=1)
accepted = wrong = 0
for k, yes in zip(candidates, verdicts):
    if not yes: continue
    a, z, i = rows[k]
    b = without(k)
    accepted += 1
    o, exe = f"{work}/m.o", f"{work}/m"
    open(o, "wb").write(b)
    r = subprocess.run(["cc", "-o", exe, f"{work}/h.o", o] + os.environ.get("LIBS", "").split(), capture_output=True, text=True)
    if r.returncode: print("not linked", r.stderr[-200:]); wrong += 1; continue
    try: r = subprocess.run([exe] + args, capture_output=True, text=True, timeout=300); ok = r.returncode == 0
    except subprocess.TimeoutExpired: ok = False; r = None
    if not ok: wrong += 1; print(f"ACCEPTED, AND THE PROCESSOR SAYS NO: +{a - kbyte.BASE:#x} {i}: {(r.stdout.strip()[:150] if r else 'still running')}")
print(f"{symbol}: {len(rows)} instructions; with one left out, {accepted} are accepted; on the processor {accepted - wrong} of those keep the contract, {wrong} do not")
sys.exit(1 if wrong else 0)
