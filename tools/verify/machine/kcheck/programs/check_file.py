#!/usr/bin/env python3
"""check_file: one file as it is shipped (an object with nothing left for a linker, a shared object, an
executable) against a specification of this folder: every function the specification has a public contract
for is found in the file, read from the file's bytes as a loader maps them, and checked by kbyte.py.

    python3 programs/check_file.py FILE SPEC [--proof PROOF] [--json OUT.json]

    python3 programs/check_file.py programs/lz4/odelz4.o programs/lz4/lz4.spec

The specification is the reader's and is never taken from the file. The proof (the places of the loops) is
taken from the file's section `.ode.proof`, where kpack.py puts it and a linker carries it, or from PROOF;
it is not trusted: a wrong one makes the check fail. In a file whose names have been stripped the code is
looked for by its bytes, and the proof says where each function begins in it.

`--json OUT.json` writes what was checked, for tools that carry it on (a benchmark's record of what it ran):
the file's and the specification's SHA-256, whether the specification is the maker's, and for each function
its name, where it is, its length in bytes, its instructions, its contract's text and the verdict."""
import hashlib, json, os, sys, time
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(HERE))
import check_binary, kbyte, kcheck, kdecode, ode


def main():
    args = [a for k, a in enumerate(sys.argv[1:], 1) if not a.startswith("--") and sys.argv[k - 1] not in ("--proof", "--json")]
    path, spec_path = args[0], args[1]
    given = sys.argv[sys.argv.index("--proof") + 1] if "--proof" in sys.argv else None
    with open(spec_path) as f: text = f.read()
    spec = ode.Spec(text)
    e = kdecode.Elf(path)
    if not kdecode.settled(e): print(f"{os.path.basename(path)}: its code has relocations for a linker to fill in"); return 2
    s = kdecode.Settled(e)
    kind = {1: "an object with nothing left for a linker to fill in", 2: "an executable", 3: "a shared object, or an executable that may be loaded anywhere"}[e.type]
    print(f"{os.path.basename(path)}: {kind}, {len(e.b)} bytes; {sum(z - a for a, z, x in s.parts if x)} of them loaded to be run")
    if given is not None:
        with open(given, "rb") as f: proof, where = check_binary.carried(f.read()), given
    elif ".ode.proof" in e.index: proof, where = check_binary.carried(e.bytes_of(".ode.proof")), "the file's own section .ode.proof"
    else: print("no proof: the file has no section .ode.proof, and none is given (--proof)"); return 2
    same = hashlib.sha256(text.encode()).hexdigest() == proof.get("spec")
    print(f"the proof: {where}; the specification is the reader's ({os.path.basename(spec_path)}), " + ("the one the maker had" if same else "NOT the one the maker had"))
    wanted = [name for name in spec.contracts if name in proof["at"]]
    if not wanted: print("the specification has a contract for no function the proof speaks of"); return 1
    if any(name not in s.at for name in wanted):
        size, digest, begins = proof["code"]
        hit = next((k for k in range(0, len(s.image) - size + 1, 16) if s.image[k:k + len(begins)] == begins and hashlib.sha256(s.image[k:k + size]).hexdigest() == digest), None)
        if hit is None: print("the file does not name the functions, and the code the proof is of is not in it"); return 1
        kdecode.GIVEN.update({name: s.lo + hit + off for name, off in proof["at"].items()})
        s = kdecode.Settled(e)
        print(f"the file does not name the functions: the code the proof is of is found by its bytes at {s.lo + hit:#x}, and the proof's names are taken for them")
    failed, count, t_all, record = 0, 0, time.time(), []
    def contract_text(symbol):
        lines = text.split("\n")
        a = next(k for k, l in enumerate(lines) if l.startswith(f"contract {symbol}("))
        return "\n".join(lines[a:next(k for k in range(a, len(lines)) if lines[k].startswith("}")) + 1])
    for symbol in wanted:
        t0 = time.time()
        try:
            rows = kbyte.load(path, symbol)
            places = proof["files"].get(symbol[len("ode_"):] + ".proof", b"").decode()
            kbyte.check(rows, spec, symbol, places)
        except (kcheck.Fail, kdecode.Stop, ode.Err) as err:
            failed += 1; print(f"  {symbol}: NOT shown: {err}")
            record.append(dict(name=symbol, verdict="NOT shown", why=str(err), contract=contract_text(symbol))); continue
        count += len(rows)
        record.append(dict(name=symbol, verdict="meets its public contract", at=s.lo + s.at[symbol], bytes=rows[-1][1] - rows[0][0], instructions=len(rows), places=places.count("place +"), contract=contract_text(symbol)))
        print(f"  {symbol:<18} at {s.lo + s.at[symbol]:#8x}  {len(rows):>4} instructions  {places.count('place +')} places  {1000 * (time.time() - t0):7.1f} ms  meets its public contract")
    if "--json" in sys.argv:
        with open(sys.argv[sys.argv.index("--json") + 1], "w") as f:
            json.dump(dict(file=os.path.basename(path), file_sha256=hashlib.sha256(e.b).hexdigest(), kind=kind, specification=os.path.basename(spec_path),
                           specification_sha256=hashlib.sha256(text.encode()).hexdigest(), specification_is_the_makers=same, proof=("the file's own section" if given is None else "given beside the file"),
                           functions=record, shown=not failed), f, indent=1)
    if failed: print(f"NOT shown ({failed} of {len(wanted)} failed)"); return 1
    print(f"{len(wanted)} function(s) in this file, {count} instructions, each meets its public contract ({os.path.basename(spec_path)}), from the file's bytes, in {time.time() - t_all:.2f} s")
    return 0


if __name__ == "__main__":
    sys.exit(main())
