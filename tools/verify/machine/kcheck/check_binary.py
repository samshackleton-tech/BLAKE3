#!/usr/bin/env python3
"""check_binary: one file as it is shipped: a shared object, an executable, or an object with nothing left
for a linker to fill in.

    python3 check_binary.py FILE [FUNCTION] [--proof PROOF] [--spec SPEC]      (FUNCTION: b3l_hashr)
    python3 check_binary.py FILE --show-spec                                   the specification the file carries

The claim (the last lines of blake3.spec) is about FUNCTION. Its bytes are read from the file as a loader
maps it (kdecode.py: whole pages, the parts without leave to write), and so are the bytes of every function
it calls, and of those they call: each found by where the `call` goes, and checked against the specification by
the checker for its kind, as check_all.py does for the objects an assembler makes. No assembler and no
linker is relied on: what they made is what is read.

The proof may be in the file: klink.py puts it in a section that is not loaded (`.ode.proof`), and a linker
carries that section into what it makes. It holds the contracts of the functions inside and the kernels'
places, and where each function is in the code, for a file whose names have been stripped. If the file has
none (a `strip` takes it out with the names), `--proof` gives it (klink.py's OUT.proof), and without that
the files of proofs/ are read. The proof is not trusted: a wrong one makes the check fail.

The specification is what the reader relies on, so it is his to read. With `--spec` it is his own file, and
the check says whether it is the one the maker had. Without it, the specification the file carries is used
(the file holds it beside the proof, so that a reader with the file alone can check it), and the check says
so: what is then shown is that the code meets THAT text, whatever it says. `--show-spec` prints it. (A file
that carries none is checked against blake3.spec here.)

Then what else the file holds: how many of the bytes it loads to be run are of the functions checked. (The
claim does not need the rest to be nothing: FUNCTION never leaves the functions checked. A reader may want
to know.)"""
import hashlib, json, os, sys, time
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import kcheck, kdecode, kfn, kloop, kone, kspec, ode

WIDE = {kloop.KERNELS[n]["symbol"]: n for n in ("k32", "p32", "p16")}
ONE = {c["symbol"]: n for n, c in kone.CONTRACTS.items()}
PLACES = {}             # the kernels' places, where a proof carried in the file gives them: {name: the JSON's text}


def carried(text):
    """A proof as klink.py writes it: {"spec": sha256, "code": (length, sha256, its first bytes), "at": {name: offset}, "files": {name: bytes}}."""
    out, at = {"at": {}, "files": {}}, 0
    def line():
        nonlocal at
        end = text.index(b"\n", at); l = text[at:end].decode(); at = end + 1
        return l.split(" ")
    if line() != ["ode", "proof", "1"]: raise kcheck.Fail("the proof is not one this checker reads")
    while at < len(text):
        w = line()
        if w[0] == "specification" and w[1] == "sha256": out["spec"] = w[2]
        elif w[0] == "code" and w[2] == "sha256" and w[4] == "begins": out["code"] = (int(w[1]), w[3], bytes.fromhex(w[5]))
        elif w[0] == "at": out["at"][w[2]] = int(w[1])
        elif w[0] == "file": out["files"][w[1]] = text[at:at + int(w[2])]; at += int(w[2])
        else: raise kcheck.Fail(f"the proof: a line this checker does not know: {' '.join(w)[:60]}")
    return out


def take(proof, spec_path):
    """The specification (the reader's file; or, with no path, the one the proof carries) with the proof's
    contracts of the functions inside; the kernels' places. True: it is the one the maker had."""
    global WIDE, ONE
    if spec_path is None: mine = proof["files"]["specification"].decode()
    else:
        with open(spec_path) as f: mine = f.read()
    kspec.SPEC = ode.Spec(mine + "\n" + proof["files"]["proofs/inner.spec"].decode())
    kone.CONTRACTS = kone.contracts(); kloop.KERNELS = kloop.kernels(); kfn.CONTRACTS.clear()
    WIDE = {kloop.KERNELS[n]["symbol"]: n for n in ("k32", "p32", "p16")}
    ONE = {c["symbol"]: n for n, c in kone.CONTRACTS.items()}
    for name, text in proof["files"].items():
        if name.endswith(".json"): PLACES[os.path.basename(name)[:-5]] = text.decode()
    return hashlib.sha256(mine.encode()).hexdigest() == proof.get("spec")


def check(path, symbol):
    """(instructions, calls, what kind, where its bytes are in the file's image). Raises kcheck.Fail."""
    if symbol in WIDE:
        name = WIDE[symbol]
        rows, data, entry = kloop.load(path, name)
        if name in PLACES: places = json.loads(PLACES[name])
        else:
            with open(os.path.join(HERE, "proofs", name + ".json")) as f: places = json.load(f)
        kloop.check(rows, data, name, places, entry)
        start = kloop.KERNELS[name]["start"]
        return rows, "a wide kernel: every number of blocks", start
    if symbol in ONE:
        rows = kone.load(path, ONE[symbol]); kone.check(rows, ONE[symbol])
        return rows, "a one-block kernel", symbol
    if symbol.startswith("b3l_") and symbol in kspec.SPEC.contracts:
        rows = kfn.load(path, symbol[4:]); kfn.check(rows, symbol[4:])
        return rows, "everything its contract allows", symbol
    raise kcheck.Fail(f"{symbol}: no contract for it")


def main():
    args = [a for k, a in enumerate(sys.argv[1:], 1) if not a.startswith("--") and sys.argv[k - 1] not in ("--proof", "--spec")]
    path, top = args[0], args[1] if len(args) > 1 else "b3l_hashr"
    option = lambda name: sys.argv[sys.argv.index(name) + 1] if name in sys.argv else None
    e = kdecode.Elf(path)
    if not kdecode.settled(e):
        print(f"{os.path.basename(path)}: its code has relocations for a linker to fill in: check_all.py reads such objects"); return 2
    s = kdecode.Settled(e)
    kind = {1: "an object with nothing left for a linker to fill in", 2: "an executable", 3: "a shared object, or an executable that may be loaded anywhere"}[e.type]
    print(f"{os.path.basename(path)}: {kind}, {len(e.b)} bytes; {sum(z - a for a, z, x in s.parts if x)} of them loaded to be run")
    # the proof: in the file, or beside it
    proof, where = None, "the files of proofs/"
    if option("--proof"):
        with open(option("--proof"), "rb") as f: proof, where = carried(f.read()), option("--proof")
    elif ".ode.proof" in e.index: proof, where = carried(e.bytes_of(".ode.proof")), "the file's own section .ode.proof"
    if proof is not None:
        if "--show-spec" in sys.argv:
            if "specification" not in proof["files"]: print("the file carries no specification"); return 1
            sys.stdout.write(proof["files"]["specification"].decode()); return 0
        if option("--spec") is None and "specification" in proof["files"]:
            same = take(proof, None)
            text = proof["files"]["specification"]
            print(f"the proof: {where}; the specification is the one the file carries ({text.count(10)} lines, SHA-256 {hashlib.sha256(text).hexdigest()[:16]}...): read it (--show-spec), for it is what is shown")
        else:
            same = take(proof, option("--spec") or os.path.join(HERE, "blake3.spec"))
            print(f"the proof: {where}; the specification is the reader's, " + ("the one the maker had" if same else "NOT the one the maker had"))
        if top not in s.at:
            # no names in the file: the code is looked for by its bytes, and the proof says where each function is in it
            size, digest, begins = proof["code"]
            hit = next((k for k in range(0, len(s.image) - size + 1, 16) if s.image[k:k + len(begins)] == begins and hashlib.sha256(s.image[k:k + size]).hexdigest() == digest), None)
            if hit is None: print(f"{top}: the file has no such name, and the code the proof is of is not in it"); return 1
            kdecode.GIVEN.update({name: s.lo + hit + off for name, off in proof["at"].items()})
            s = kdecode.Settled(e)
            print(f"the file has no names: the code the proof is of is found by its bytes at {s.lo + hit:#x}, and the proof's names are taken for its functions")
    else: print(f"the proof: {where}")
    done, todo, covered, failed, count, t_all = {}, [top], [], 0, 0, time.time()
    while todo:
        symbol = todo.pop(0)
        if symbol in done: continue
        t0 = time.time()
        try:
            rows, what, start = check(path, symbol)
        except (kcheck.Fail, kdecode.Stop) as err:
            done[symbol] = None; failed += 1; print(f"  {symbol}: NOT shown: {err}"); continue
        done[symbol] = len(rows)
        at = s.at[start]
        if (at, at + rows[-1][1] - rows[0][0]) not in covered: covered.append((at, at + rows[-1][1] - rows[0][0])); count += len(rows)      # two ways into one body: once
        calls = sorted({i.split()[1] for _, _, i in rows if i.split()[0] == ".call"})
        print(f"  {symbol:<42} at {s.lo + s.at[symbol]:#8x}  {len(rows):>4} instructions  {1000 * (time.time() - t0):7.1f} ms  {what}")
        todo += [c for c in calls if c not in done]
    inside = bytearray(len(s.image))
    for a, z in covered: inside[a:z] = b"\1" * (z - a)
    rest = [i for a, z, x in s.parts if x for i in range(a, z) if not inside[i]]
    zeros = sum(1 for i in rest if s.image[i] == 0)
    run = sum(z - a for a, z, x in s.parts if x)
    print(f"of the {run} bytes loaded to be run: {sum(inside)} are the {len(covered)} bodies checked ({count} instructions), {zeros} are zero, {len(rest) - zeros} are others"
          + (" (constants the functions read; what lies between functions; whatever else the file holds)" if len(rest) - zeros else ""))
    if failed: print(f"{top}: NOT shown ({failed} failed)"); return 1
    print(f"{top} in this file meets its public contract ({'the specification the file carries' if proof is not None and option('--spec') is None and 'specification' in proof['files'] else 'blake3.spec'}), with all it calls: {len(done)} functions, from the file's bytes, in {time.time() - t_all:.2f} s")
    return 0


if __name__ == "__main__":
    sys.exit(main())
