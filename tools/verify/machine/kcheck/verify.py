#!/usr/bin/env python3
"""verify: one command for a reader who has a binary and wants to know what it is shown to do.

    python3 verify.py FILE [SPEC] [--search] [--proof PROOF]

FILE: a shipped file of this folder (b3hashr.o, programs/NAME/odeNAME.o), or what a linker made of one.
It prints, in this order:

  1. what you are asked to rely on: the public contract(s), from SPEC if you give one (your own copy), else
     from the specification the file carries, with that text's SHA-256. Read it: it is what is shown.
  2. the verification itself (check_binary.py for the hash, programs/check_file.py for the others), which
     reads the file's bytes as a loader maps them and takes nothing else from the file on trust;
  3. what ran: every file of this folder that was loaded to reach the verdict, with its lines of code and
     digest. That list is what you relied on, beside Python itself. The prover's files are not on it.

Exit 0: shown. 1: not shown (and, on an x86-64 Linux machine, whether an input was found that shows it false).
"""
import ast, hashlib, io, os, re, sys, tokenize

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE); sys.path.insert(0, os.path.join(HERE, "programs"))


def code_lines(path):
    """Lines that hold code: not blank, not a comment, not a docstring."""
    with open(path) as f: src = f.read()
    doc = set()
    for n in ast.walk(ast.parse(src)):
        if isinstance(n, (ast.Module, ast.ClassDef, ast.FunctionDef)) and n.body and isinstance(n.body[0], ast.Expr) and isinstance(getattr(n.body[0], "value", None), ast.Constant) and isinstance(n.body[0].value.value, str):
            doc.update(range(n.body[0].lineno, n.body[0].end_lineno + 1))
    lines = set()
    for t in tokenize.generate_tokens(io.StringIO(src).readline):
        if t.type in (tokenize.COMMENT, tokenize.NL, tokenize.NEWLINE, tokenize.INDENT, tokenize.DEDENT, tokenize.ENDMARKER): continue
        lines.update(l for l in range(t.start[0], t.end[0] + 1) if l not in doc)
    return len(lines)


def contracts(text, names):
    out = []
    for m in re.finditer(r"^contract (\w+)\(.*?^\}", text, re.S | re.M):
        if m.group(1) in names: out.append(m.group(0))
    return out


def main():
    args = [a for k, a in enumerate(sys.argv[1:], 1) if not a.startswith("--") and sys.argv[k - 1] != "--proof"]
    if not args: print(__doc__); return 2
    path, spec_path = args[0], args[1] if len(args) > 1 else None
    import kdecode, kproof
    e = kdecode.Elf(path)
    given = sys.argv[sys.argv.index("--proof") + 1] if "--proof" in sys.argv else None
    if given:
        with open(given, "rb") as f: proof = kproof.carried(f.read())
    elif ".ode.proof" in e.index: proof = kproof.carried(e.bytes_of(".ode.proof"))
    else: print(f"{path}: it carries no proof (give one with --proof)"); return 2
    if spec_path:
        with open(spec_path) as f: text = f.read()
        whose = f"your own copy ({os.path.basename(spec_path)})"
    elif "specification" in proof["files"]: text, whose = proof["files"]["specification"].decode(), "the one the file carries (given by its maker: read it)"
    else: print("no specification: the file carries none, and none is given"); return 2
    hash_file = "b3l_hashr" in proof["at"]
    public = contracts(text, set(proof["at"]) if not hash_file else {"b3l_hashr"})
    print(f"1. What is shown, if the verification below says so. The specification: {whose}; {text.count(chr(10))} lines, SHA-256 {hashlib.sha256(text.encode()).hexdigest()}.")
    print("   Its definitions say what the words of these contracts mean (CONTRACT.md: what a contract is; LANGUAGE.md: the specification's language).\n")
    for c in public: print("   " + c.replace("\n", "\n   ") + "\n")
    print("2. The verification:\n")
    sys.stdout.flush()
    if hash_file:
        import check_binary
        sys.argv = ["check_binary.py", path, "--no-ends"] + (["--spec", spec_path] if spec_path else []) + (["--proof", given] if given else []) + (["--search"] if "--search" in sys.argv else [])
        code = check_binary.main()
    else:
        import check_file
        sys.argv = ["check_file.py", path] + ([spec_path] if spec_path else []) + (["--proof", given] if given else []) + (["--search"] if "--search" in sys.argv else [])
        code = check_file.main()
    def loaded(but=()):
        ran = []
        for name, mod in sorted(sys.modules.items()):
            f = getattr(mod, "__file__", None)
            if f and os.path.abspath(f).startswith(HERE + os.sep) and os.path.abspath(f) != os.path.abspath(__file__) and os.path.relpath(f, HERE) not in but:
                with open(f, "rb") as fh: digest = hashlib.sha256(fh.read()).hexdigest()[:16]
                ran.append((os.path.relpath(f, HERE), code_lines(f), digest))
        return ran
    ran = loaded()
    more, line = [], None
    if hash_file and code == 0:
        line = check_binary.ends()                              # a second question, with a second verifier's part
        more = loaded(but={r[0] for r in ran})
        print("   the specification: " + line)
    print("\n3. What ran, to reach that (the files of this folder that were loaded; beside them, Python):\n")
    total = sum(n for _, n, _ in ran)
    for f, n, digest in ran: print(f"   {f:<26} {n:>5} lines of code   SHA-256 {digest}...")
    print(f"   {'in all':<26} {total:>5} lines of code, {len(ran)} files")
    if more:
        print("   and for the one line about the specification's definitions coming to an end (no part of what shows the code meets the contract):")
        for f, n, digest in more: print(f"   {f:<26} {n:>5} lines of code   SHA-256 {digest}...")
    absent = [f for f in ("kprove.py", "refute.py", "klink.py", os.path.join("programs", "kpack.py")) if f not in {r[0] for r in ran + more}]
    if absent: print(f"   not loaded (a prover's or a maker's, trusted for nothing): {', '.join(absent)}")
    return code


if __name__ == "__main__":
    sys.exit(main())
