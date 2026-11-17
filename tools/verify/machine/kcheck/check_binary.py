#!/usr/bin/env python3
"""check_binary: one file as it is shipped: a shared object, an executable, or an object with nothing left
for a linker to fill in.

    python3 check_binary.py FILE [FUNCTION] [--proof PROOF] [--spec SPEC]      (FUNCTION: b3l_hashr)
    python3 check_binary.py FILE --show-spec                                   the specification the file carries

The claim (the last lines of blake3.spec) is about FUNCTION. Its bytes are read from the file as a loader
maps it (kdecode.py: whole pages, the parts without leave to write), and so are the bytes of every function
it calls, and of those they call: each found by where the `call` goes, and checked against the specification by
the verifier for its kind, as check_all.py does for the objects an assembler makes. No assembler and no
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
import kdecode, kfn, klin, kshow, kspec, kterms, ode, varith
from kproof import carried

# The kernels: verified by kfn.py as every other function is (since November 17, 2026; before, by verifiers of
# their own). A wide kernel loops over the blocks of a chunk, any number of them: its proof names a place in
# the loop (proofs/NAME.json). {the name a caller uses: (its proof's name, the name its code begins at)}: the
# 32-lane kernel has two ways in.
WIDE = {"blake3_servil_avx512_k32": ("k32", "blake3_servil_avx512_k32"), "blake3_servil_avx512_p32": ("p32", "blake3_servil_avx512_k32"),
        "blake3_servil_avx512_p16": ("p16", "blake3_servil_avx512_p16")}
ONE = ("blake3_servil_compress_in_place_avx512", "blake3_servil_compress_in_place_sse41")
PLACES = {}             # the kernels' places, where a proof carried in the file gives them: {name: the JSON's text}
ARITH = {}              # the arithmetic's proofs the file carries: {a function's name: the table's bytes (varith.py)}


def take(proof, spec_path):
    """The specification (the reader's file; or, with no path, the one the proof carries) with the proof's
    contracts of the functions inside; the kernels' places. True: it is the one the maker had."""
    if spec_path is None: mine = proof["files"]["specification"].decode()
    else:
        with open(spec_path) as f: mine = f.read()
    global MINE, LEMMAS
    MINE, LEMMAS = mine, proof["files"].get("proofs/blake3.lemmas", b"").decode()
    kspec.SPEC = ode.with_proof(mine, proof["files"]["proofs/inner.spec"].decode())
    kfn.CONTRACTS.clear()
    ARITH.clear()
    for name, text in proof["files"].items():
        if name.endswith(".json"): PLACES[os.path.basename(name)[:-5]] = text.decode()
        if name.endswith(".arith.z"): ARITH[name[:-len(".arith.z")]] = text
    return kshow.b3(mine.encode()) == proof.get("spec")


def ring_of(edges):
    """The functions that are called by what they call (a ring of two or more; a function that calls itself
    is shown to end by the number its contract says decreases, kfn.py: lessens). Empty where there is none."""
    def reaches(start, want, seen):
        if start == want: return True
        if start in seen: return False
        return any(reaches(n, want, seen | {start}) for n in edges.get(start, ()) if n != start)
    return {name for symbol, callees in edges.items() for name in callees if name != symbol and reaches(name, symbol, set())}


def ends(top="b3l_hashr"):
    """Do the definitions the public contract speaks through come to an end, on everything it allows? Shown by
    the lemmas the proof carries (`decreases`) and by kends.py (the lemmas' `requires` met from the contract
    inward), with the other verifier's part for lemmas (kbyte.py: loaded for this line alone; it is no part
    of what shows the code meets the contract)."""
    import kbyte, kends
    by_proof = "--search" not in sys.argv and bool(ARITH)
    try:
        spec = ode.with_proof(MINE, LEMMAS) if LEMMAS else ode.Spec(MINE)
        klin.Facts.PROOFS = (varith.unpack(ARITH["lemmas"]) if "lemmas" in ARITH else {}) if by_proof else None
        kbyte.prove_lemmas(spec)
        return kends.line(spec, [top])
    except (kterms.Fail, ode.Err, ValueError, KeyError, IndexError, TypeError, AttributeError, RecursionError) as err:
        return f"its definitions that use themselves are NOT shown to come to an end: {err}"
    finally: klin.Facts.PROOFS = None


def check(path, symbol):
    """(instructions, calls, what kind, where its bytes are in the file's image). Raises kterms.Fail."""
    if symbol in WIDE:
        name, start = WIDE[symbol]
        rows, data, entry = kfn.load_from(path, symbol, start)
        if name in PLACES: places = json.loads(PLACES[name])
        else:
            with open(os.path.join(HERE, "proofs", name + ".json")) as f: places = json.load(f)
        kfn.check(rows, None, proof=places, symbol=symbol, entry=entry, data=data)
        return rows, "a wide kernel: every number of blocks, by induction at the place its proof names", start
    if symbol in ONE:
        rows = kfn.load(path, None, symbol); kfn.check(rows, None, symbol=symbol)
        return rows, "a one-block kernel", symbol
    if symbol.startswith("b3l_") and symbol in kspec.SPEC.contracts:
        rows = kfn.load(path, symbol[4:]); kfn.check(rows, symbol[4:])
        return rows, "everything its contract allows", symbol
    raise kterms.Fail(f"{symbol}: no contract for it")


def main():
    global MINE, LEMMAS
    if not isinstance(sys.stdout, kshow.Plain): sys.stdout = kshow.Plain(sys.stdout)
    maintain = "--maintain" in sys.argv        # a maintainer's run: the functions inside by name, where each is, why one is not shown
    args = [a for k, a in enumerate(sys.argv[1:], 1) if not a.startswith("--") and sys.argv[k - 1] not in ("--proof", "--spec")]
    path, top = args[0], args[1] if len(args) > 1 else "b3l_hashr"
    option = lambda name: sys.argv[sys.argv.index(name) + 1] if name in sys.argv else None
    e = kdecode.Elf(path)
    if not kdecode.settled(e):
        print(f"{os.path.basename(path)}: its code has relocations for a linker to fill in: check_all.py reads such objects"); return 2
    offered = {}
    if e.type == 1:
        # an object to be linked: read only in the one shape whose every part a linker takes is read here
        why, offered = kdecode.linkable(e)
        if why: print(f"{os.path.basename(path)}: NOT shown: {why}"); return 1
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
        try:
            if option("--spec") is None and "specification" in proof["files"]:
                same = take(proof, None)
                text = proof["files"]["specification"]
                print(f"the proof: {where}; the specification is the one the file carries ({text.count(10)} lines, BLAKE3 {kshow.b3(text)}): read it (--show-spec), for it is what is shown")
            else:
                same = take(proof, option("--spec") or os.path.join(HERE, "blake3.spec"))
                print(f"the proof: {where}; the specification is the reader's, " + ("the one the maker had" if same else "NOT the one the maker had"))
        except ode.Err as err:
            print(f"{os.path.basename(path)}: NOT shown: the proof's part cannot be read with the specification: {err}"); return 1
        if top not in s.at:
            # no names in the file: the code is looked for by its bytes, and the proof says where each function is in it
            size, digest, begins = proof["code"]
            hit = next((k for k in range(0, len(s.image) - size + 1, 16) if s.image[k:k + len(begins)] == begins and kshow.b3(s.image[k:k + size]) == digest), None)
            if hit is None: print(f"{top}: the file has no such name, and the code the proof is of is not in it"); return 1
            kdecode.GIVEN.update({name: s.lo + hit + off for name, off in proof["at"].items()})
            s = kdecode.Settled(e)
            print(f"the file has no names: the code the proof is of is found by its bytes at {s.lo + hit:#x}, and the proof's names are taken for its functions")
    else:
        print(f"the proof: {where}")
        with open(os.path.join(HERE, "blake3.spec")) as f: MINE = f.read()            # (the lemmas for the line about the definitions' ending)
        with open(os.path.join(HERE, "proofs", "blake3.lemmas")) as f: LEMMAS = f.read()
    # every name the file gives a linker is verified too, called by `top` or not (kdecode.linkable)
    calls_seen = {top}
    done, todo, covered, failed, count, t_all, searched = {}, [top] + sorted(n for n in offered if n != top), [], 0, 0, time.time(), []
    edges = {}          # each function checked and what it calls: for the ring check below
    while todo:
        symbol = todo.pop(0)
        if symbol in done: continue
        t0 = time.time()
        # the arithmetic: by the proofs the file carries for this function (nothing is searched for); with
        # `--search`, or for a file that carries none, by this program's own search, as before
        by_proof = "--search" not in sys.argv and (symbol in ARITH or bool(ARITH))
        try:
            klin.Facts.PROOFS = (varith.unpack(ARITH[symbol]) if symbol in ARITH else {}) if by_proof else None
            rows, what, start = check(path, symbol)
        except (kterms.Fail, kdecode.Stop) as err:
            done[symbol] = None; failed += 1
            if maintain: print(f"  {symbol}: NOT shown: {err}" + (" (with the arithmetic's proofs the file carries and no search: --search to see what a search says)" if by_proof else ""))
            elif symbol == top: print(f"  {symbol}: NOT shown")
            elif symbol in offered: print(f"  {symbol}: NOT verified: the file gives a linker this name, and no contract here is shown of the bytes it leads to")
            if symbol == top:
                # not shown: is it false? The public contract worked out on numbers beside the code run here (refute.py)
                import refute
                said = refute.after_refusal(path, symbol, option("--spec"))
                if said: print("      " + said.replace("\n", "\n      "))
            continue
        except (ValueError, KeyError, IndexError, TypeError) as err:
            if not by_proof: raise
            done[symbol] = None; failed += 1
            if maintain or symbol == top: print(f"  {symbol}: NOT shown" + (f": the arithmetic's proofs the file carries cannot be read ({type(err).__name__})" if maintain else ""))
            continue
        finally: klin.Facts.PROOFS = None
        searched.append(symbol) if not by_proof else None
        done[symbol] = len(rows)
        at = s.at[start]
        if (at, at + rows[-1][1] - rows[0][0]) not in covered: covered.append((at, at + rows[-1][1] - rows[0][0])); count += len(rows)      # two ways into one body: once
        calls = sorted({i.split()[1] for _, _, i in rows if i.split()[0] == ".call"})
        edges[symbol] = calls
        if maintain: print(f"  {symbol:<42} at {s.lo + s.at[symbol]:#8x}  {len(rows):>4} instructions  {1000 * (time.time() - t0):7.1f} ms  {what}")
        calls_seen.update(calls); todo += [c for c in calls if c not in done]
    inside = bytearray(len(s.image))
    # no function is called by what it calls, except a function that calls itself over a number its contract
    # says decreases (kfn.py: lessens). (Until November 17, 2026 only programs/check_file.py asked this: a ring
    # of two could pass, each contract's stack allowing the other's, and nothing showed the calls come to an end.)
    round_ = sorted(ring_of(edges))
    if round_:
        failed += 1
        print(f"  a ring of calls: {' calls '.join(round_)}, and one of them calls itself around: nothing shows such calls come to an end")
    for a, z in covered: inside[a:z] = b"\1" * (z - a)
    rest = [i for a, z, x in s.parts if x for i in range(a, z) if not inside[i]]
    zeros = sum(1 for i in rest if s.image[i] == 0)
    run = sum(z - a for a, z, x in s.parts if x)
    print(f"of the {run} bytes loaded to be run: {sum(inside)} are the {len(covered)} bodies checked ({count} instructions), {zeros} are zero, {len(rest) - zeros} are others"
          + (" (constants the functions read; what lies between functions; whatever else the file holds)" if len(rest) - zeros else ""))
    if failed and not maintain: print("  (where, and why: run it again with --maintain)")
    if failed: print(f"{top}: NOT shown ({failed} failed)"); return 1
    print("the arithmetic: " + ("every fact by a proof the file carries, verified by adding up (varith.py); nothing was searched for" if not searched else
                              f"searched for by this program for {len(searched)} function(s): the file carries no proofs of it, or --search was given"))
    if "--no-ends" not in sys.argv:
        line = ends(top)
        print("the specification: " + kshow.ends_said(line, maintain))
        if "NOT shown" in line:
            # (a contract that speaks through a definition not shown to come to an end says nothing of the inputs on which it goes on)
            print(f"{top}: NOT shown: its code meets its contract as far as the contract says anything; the contract speaks through definitions that are not shown to come to an end"); return 1
    print(f"{top} in this file meets its public contract ({'the specification the file carries' if proof is not None and option('--spec') is None and 'specification' in proof['files'] else 'blake3.spec'}), with all it calls{' and every other name the file gives a linker' if any(n not in calls_seen for n in offered) else ''}: {len(done)} functions, from the file's bytes, in {time.time() - t_all:.2f} s")
    return 0


if __name__ == "__main__":
    sys.exit(main())
