#!/usr/bin/env python3
"""check_file: one file as it is shipped (an object with nothing left for a linker, a shared object, an
executable) against a specification of this folder: every function the specification has a public contract
for is found in the file, read from the file's bytes as a loader maps them, and checked by kbyte.py.

    python3 programs/check_file.py FILE [SPEC] [--proof PROOF] [--json OUT.json]
    python3 programs/check_file.py FILE --show-spec

    python3 programs/check_file.py programs/lz4/odelz4.o programs/lz4/lz4.spec

The specification is what the reader relies on. Given SPEC, it is his own file, and the check says whether
it is the one the maker had. Without SPEC the specification the file carries is used, and the check says so:
what is then shown is that the code meets THAT text; `--show-spec` prints it for him to read. The proof (the places of the loops) is
taken from the file's section `.ode.proof`, where kpack.py puts it and a linker carries it, or from PROOF;
it is not trusted: a wrong one makes the check fail. In a file whose names have been stripped the code is
looked for by its bytes, and the proof says where each function begins in it.

`--json OUT.json` writes what was checked, for tools that carry it on (a benchmark's record of what it ran):
the file's and the specification's SHA-256, whether the specification is the maker's, and for each function
its name, where it is, its length in bytes, its instructions, its contract's text and the verdict; how the
arithmetic was verified (by the proofs the file carries, or searched for); the definitions that use themselves
and those of them not shown to come to an end; and the verifier itself: each file of it that was loaded, with
its SHA-256, and one SHA-256 over that list (`verifier_sha256`: what "verified" was said by)."""
import hashlib, json, os, sys, time
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(HERE))
import kbyte, kcheck, kdecode, kends, kproof, ode, klin, varith


def main():
    args = [a for k, a in enumerate(sys.argv[1:], 1) if not a.startswith("--") and sys.argv[k - 1] not in ("--proof", "--json")]
    path, spec_path = args[0], args[1] if len(args) > 1 else None
    given = sys.argv[sys.argv.index("--proof") + 1] if "--proof" in sys.argv else None
    e = kdecode.Elf(path)
    if not kdecode.settled(e): print(f"{os.path.basename(path)}: its code has relocations for a linker to fill in"); return 2
    s = kdecode.Settled(e)
    kind = {1: "an object with nothing left for a linker to fill in", 2: "an executable", 3: "a shared object, or an executable that may be loaded anywhere"}[e.type]
    print(f"{os.path.basename(path)}: {kind}, {len(e.b)} bytes; {sum(z - a for a, z, x in s.parts if x)} of them loaded to be run")
    if given is not None:
        with open(given, "rb") as f: proof, where = kproof.carried(f.read()), given
    elif ".ode.proof" in e.index: proof, where = kproof.carried(e.bytes_of(".ode.proof")), "the file's own section .ode.proof"
    else: print("no proof: the file has no section .ode.proof, and none is given (--proof)"); return 2
    if "--show-spec" in sys.argv:
        if "specification" not in proof["files"]: print("the file carries no specification"); return 1
        sys.stdout.write(proof["files"]["specification"].decode()); return 0
    if spec_path is None:
        if "specification" not in proof["files"]: print("no specification: the file carries none, and none is given"); return 2
        text, spec_path = proof["files"]["specification"].decode(), "the specification the file carries"
        print(f"the proof: {where}; the specification is the one the file carries ({text.count(chr(10))} lines, SHA-256 {hashlib.sha256(text.encode()).hexdigest()[:16]}...): read it (--show-spec), for it is what is shown")
    else:
        with open(spec_path) as f: text = f.read()
        print(f"the proof: {where}; the specification is the reader's ({os.path.basename(spec_path)}), " + ("the one the maker had" if hashlib.sha256(text.encode()).hexdigest() == proof.get("spec") else "NOT the one the maker had"))
    same = hashlib.sha256(text.encode()).hexdigest() == proof.get("spec")
    # a program made of others: the proof carries the contracts of the functions called (steps of the proof)
    # ... and lemmas about the specification's definitions, which the verifier shows before it uses them
    inner = "".join("\n" + body.decode() for name, body in sorted(proof["files"].items()) if name.endswith((".inner", ".lemmas")))
    public = set(ode.Spec(text).contracts)
    spec = ode.with_proof(text, inner) if inner else ode.Spec(text)
    wanted = [name for name in spec.contracts if name in proof["at"]]
    if not wanted: print("the specification has a contract for no function the proof speaks of"); return 1
    # Which functions are verified is the proof's to say (`at`), and the proof is not trusted: a public contract
    # of the specification that the proof leaves out is said, and if the file has a function of that name the
    # verification is "NOT shown" (a reader would take a file's function with a contract in front of him as verified).
    left_out = sorted(name for name in public if name not in proof["at"])
    in_file = [name for name in left_out if name in s.at]
    if any(name not in s.at for name in wanted):
        size, digest, begins = proof["code"]
        hit = next((k for k in range(0, len(s.image) - size + 1, 16) if s.image[k:k + len(begins)] == begins and hashlib.sha256(s.image[k:k + size]).hexdigest() == digest), None)
        if hit is None: print("the file does not name the functions, and the code the proof is of is not in it"); return 1
        kdecode.GIVEN.update({name: s.lo + hit + off for name, off in proof["at"].items()})
        s = kdecode.Settled(e)
        print(f"the file does not name the functions: the code the proof is of is found by its bytes at {s.lo + hit:#x}, and the proof's names are taken for them")
    failed, count, t_all, record = 0, 0, time.time(), []
    calls, searched, by_proof = {}, [], False
    def contract_text(symbol):
        lines = (text + inner).split("\n")
        a = next(k for k, l in enumerate(lines) if l.startswith(f"contract {symbol}("))
        return "\n".join(lines[a:next(k for k in range(a, len(lines)) if lines[k].startswith("}")) + 1])
    for symbol in wanted:
        t0 = time.time()
        try:
            rows = kbyte.load(path, symbol)
            places = proof["files"].get(symbol[len("ode_"):] + ".proof", b"").decode()
            # the arithmetic: by the proofs the file carries for this function (nothing is searched for); with
            # `--search`, or for a file that carries none at all, by the search, as before
            arith = proof["files"].get(symbol[len("ode_"):] + ".arith.z")
            by_proof = "--search" not in sys.argv and any(n.endswith(".arith.z") for n in proof["files"])
            try:
                klin.Facts.PROOFS = (varith.unpack(arith) if arith is not None else {}) if by_proof else None
                calls[symbol] = kbyte.check(rows, spec, symbol, places)["calls"]
            except (ValueError, KeyError, IndexError, TypeError) as err:
                if not by_proof: raise
                raise kcheck.Fail(f"the arithmetic's proofs the file carries cannot be read ({type(err).__name__})")
            finally: klin.Facts.PROOFS = None
            if not by_proof: searched.append(symbol)
        except (kcheck.Fail, kdecode.Stop, ode.Err) as err:
            failed += 1; print(f"  {symbol}: NOT shown: {err}" + (" (with the arithmetic's proofs the file carries and no search: --search to see what a search says)" if by_proof else ""))
            # not shown: is it false? The contract worked out on numbers beside the code run here (refute.py), where this machine can run it
            import refute
            said = refute.after_refusal(path, symbol, args[1] if len(args) > 1 else None)
            if said: print("      " + said.replace("\n", "\n      "))
            record.append(dict(name=symbol, verdict="NOT shown", why=str(err), contract=contract_text(symbol))); continue
        count += len(rows)
        said = "meets its public contract" if symbol in public else "meets its contract (a step of the proof)"
        record.append(dict(name=symbol, verdict=said, calls=calls[symbol], at=s.lo + s.at[symbol], bytes=rows[-1][1] - rows[0][0], instructions=len(rows), places=places.count("place +"), contract=contract_text(symbol)))
        print(f"  {symbol:<18} at {s.lo + s.at[symbol]:#8x}  {len(rows):>4} instructions  {places.count('place +')} places  {1000 * (time.time() - t0):7.1f} ms  {said}" + (f"; calls {', '.join(calls[symbol])} by contract" if calls[symbol] else ""))
    def write_record():
        """--json: written last, when every check has had its say (it was written before the checks of the calls
        until November 16, 2026: a file with a ring of calls had `shown: true` in its record beside "NOT shown")."""
        if "--json" not in sys.argv: return
        here = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        ran = []
        for mod in sorted(sys.modules.values(), key=lambda m: getattr(m, "__file__", None) or ""):
            p = getattr(mod, "__file__", None)
            if p and os.path.abspath(p).startswith(here + os.sep) and p.endswith(".py"):
                with open(p, "rb") as g: ran.append(dict(file=os.path.relpath(os.path.abspath(p), here), sha256=hashlib.sha256(g.read()).hexdigest()))
        again, open_ = ends
        with open(sys.argv[sys.argv.index("--json") + 1], "w") as f:
            json.dump(dict(file=os.path.basename(path), file_sha256=hashlib.sha256(e.b).hexdigest(), kind=kind, specification=os.path.basename(spec_path),
                           specification_sha256=hashlib.sha256(text.encode()).hexdigest(), specification_is_the_makers=same, proof=("the file's own section" if given is None else "given beside the file"),
                           functions=record, shown=not failed,
                           arithmetic=("searched for by the verifier" if searched else "by the proofs the file carries, verified by adding up"), arithmetic_searched_for=sorted(searched),
                           definitions_that_use_themselves=again, of_them_not_shown_to_end=open_,
                           contracts_the_proof_leaves_out=left_out, of_them_functions_of_this_file=in_file,
                           verifier=ran, verifier_sha256=hashlib.sha256("".join(f"{r['sha256']}  {r['file']}\n" for r in ran).encode()).hexdigest()), f, indent=1)
    # every function called is one of those checked here; and none is called by what it calls
    for symbol, called in calls.items():
        for name in called:
            if name not in calls: failed += 1; print(f"  {symbol} calls {name}, which is not shown here to meet the contract used")
    def rings(symbol, above):
        if symbol in above: return True
        return any(rings(name, above | {symbol}) for name in calls.get(symbol, ()))
    if any(rings(symbol, frozenset()) for symbol in calls): failed += 1; print("  a function is called by what it calls: nothing here shows such calls come to an end")
    # do the definitions the public contracts speak through come to an end, on everything those contracts allow?
    # (kends.py: a lemma's number that decreases, AND the lemma's `requires` met from the contract inward. No
    # search: what the plain facts do not show is not shown.)
    mine = [s for s in wanted if s in public]
    ends, ends_line = ([], ["the functions are not shown"]), None
    if not failed:
        try:
            klin.Facts.PROOFS = None if "--search" in sys.argv else {}
            both = [kends.ends_for(spec, s) for s in mine]
            ends = (sorted({n for a, _ in both for n in a}), [w for _, w in both if w])
            ends_line = kends.line(spec, mine)
        except (kcheck.Fail, ode.Err, KeyError, IndexError, TypeError, AttributeError, RecursionError) as err:
            ends, ends_line = ([], [f"not followed ({type(err).__name__})"]), f"whether its definitions come to an end is NOT shown: {err}"
        finally: klin.Facts.PROOFS = None
    for name in left_out:
        print(f"  {name}: NOT verified: the specification has a contract for it and the proof speaks of no such function" + (", and THIS FILE HAS A FUNCTION OF THAT NAME" if name in in_file else " (this file has none of that name)"))
    if in_file: failed += len(in_file)
    # A contract that speaks through a definition not shown to come to an end says nothing of the inputs on which
    # it goes on: the file is then NOT shown, though each function's code is (Sam's reader would take "meets its
    # contract" for more than it would be).
    endless = not failed and bool(ends[1])
    if endless: failed += 1
    write_record()
    if endless:
        print("the specification: " + ends_line)
        print("NOT shown: each function's code meets its contract as far as the contract says anything; the contracts speak through definitions that are not shown to come to an end"); return 1
    if failed: print(f"NOT shown ({failed} of {len(wanted) + len(in_file)} failed)"); return 1
    print("the specification: " + ends_line)
    print("the arithmetic: " + ("every fact by a proof the file carries, verified by adding up (varith.py); nothing was searched for" if not searched else
                              f"searched for by this program for {len(searched)} function(s): the file carries no proofs of it, or --search was given"))
    print(f"{len(wanted)} function(s) verified in this file, {count} instructions, each meets its {'public ' if not inner else ''}contract ({os.path.basename(spec_path)}{', with the inner contracts and lemmas the proof carries' if inner else ''}), from the file's bytes, in {time.time() - t_all:.2f} s")
    return 0


if __name__ == "__main__":
    sys.exit(main())
