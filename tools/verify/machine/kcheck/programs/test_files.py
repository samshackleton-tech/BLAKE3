#!/usr/bin/env python3
"""The programs as they are shipped (programs/NAME/odeNAME.o), checked as files by check_file.py.

    python3 programs/test_files.py

Each file meets its specification's public contracts; the proof it carries is the folder's, made with the
folder's specification; a proof with a line left out, or of other code, is refused; a reader with another
specification is told so."""
import json, os, subprocess, sys, tempfile, unittest
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(HERE))
import check_binary, kdecode, kshow
from check_programs import PROGRAMS

NAMES = sorted({p for p, _, _ in PROGRAMS})


def run(*args):
    r = subprocess.run([sys.executable, os.path.join(HERE, "check_file.py"), "--maintain"] + list(args), capture_output=True, text=True)
    return r.returncode, r.stdout


class Files(unittest.TestCase):
    def paths(self, name): return os.path.join(HERE, name, f"ode{name}.o"), os.path.join(HERE, name, name + ".spec")

    def test_each_file_meets_its_public_contracts(self):
        total = 0
        for name in NAMES:
            code, out = run(*self.paths(name))
            self.assertEqual(code, 0, out)
            self.assertIn("the one the maker had", out)
            total += sum(1 for line in out.split("\n") if line.endswith("meets its public contract"))
        self.assertEqual(total, len(PROGRAMS))

    def test_a_program_made_of_others(self):
        """The frame's file: three functions, one specification; the function that calls the two others is
        shown by their contracts, which the proof carries, and each of the two is shown to meet the contract used."""
        obj, spec = self.paths("frame")
        for args in ((obj, spec), (obj,)):
            code, out = run(*args)
            self.assertEqual(code, 0, out)
            self.assertIn("ode_unframe", out); self.assertIn("calls ode_adler32_blocks4, ode_lz4_decode by contract", out)
            self.assertEqual(out.count("meets its contract (a step of the proof)"), 2, out)
        carried = kdecode.Elf(obj).bytes_of(".ode.proof")
        with open(os.path.join(HERE, "frame", "unframe.inner"), "rb") as f: inner = f.read()
        self.assertEqual(carried.count(inner), 1)
        def with_inner(new):
            head = b"file unframe.inner %d\n" % len(inner)
            self.assertEqual(carried.count(head), 1)
            with tempfile.TemporaryDirectory() as d:
                path = os.path.join(d, "p")
                with open(path, "wb") as f: f.write(carried.replace(head + inner, b"file unframe.inner %d\n" % len(new) + new))
                code, out = run(obj, spec, "--proof", path, "--json", os.path.join(d, "record.json"))
                if os.path.exists(os.path.join(d, "record.json")):
                    with open(os.path.join(d, "record.json")) as f: self.assertEqual(json.load(f)["shown"], code == 0, out)   # the record says what the program said
                return code, out
        # the proof's part cannot give the public function another contract, nor a definition another meaning
        for extra in (b"contract ode_unframe(out: cap bytes, cap: number, input: n bytes, n: number) {\n    requires no_overlap(out, input)\n    returns r\n    writes out\n    trace depends on input\n    stack 184\n}\n", b"def be32(b) { 0 }\n"):
            code, out = with_inner(inner + extra)
            self.assertNotEqual(code, 0, out); self.assertNotIn("meets its public contract", out)
        # a contract in the proof that says more of a function called than that function does: the caller is shown by it, the function is not
        stronger = inner.replace(b"    returns adler32(input)\n", b"    returns adler32(input) + 1\n")
        self.assertNotEqual(stronger, inner)
        code, out = with_inner(stronger)
        self.assertEqual(code, 1, out); self.assertIn("ode_adler32_blocks4: NOT shown", out)
        # a proof with no contract for a function called
        code, out = with_inner(inner[:inner.index(b"contract ode_adler32_blocks4")])
        self.assertEqual(code, 1, out); self.assertIn("ode_unframe: NOT shown", out)

    def test_a_proof_cannot_leave_a_function_out_quietly(self):
        """Which functions are verified is the proof's to say. One that leaves out a function the file has and the
        specification has a contract for: the verification is NOT shown, and says which."""
        import re
        obj, spec = self.paths("lz4")
        carried = kdecode.Elf(obj).bytes_of(".ode.proof")
        line = re.search(rb"at \d+ ode_lz4_pack\n", carried)
        self.assertIsNotNone(line)
        with tempfile.TemporaryDirectory() as d:
            path = os.path.join(d, "p")
            with open(path, "wb") as f: f.write(carried.replace(line.group(0), b""))
            code, out = run(obj, "--proof", path, "--json", os.path.join(d, "r.json"))
            self.assertEqual(code, 1, out)
            self.assertIn("ode_lz4_pack: NOT verified", out); self.assertIn("THIS FILE HAS A FUNCTION OF THAT NAME", out); self.assertIn("NOT shown (1 of 3 failed)", out)
            with open(os.path.join(d, "r.json")) as f: r = json.load(f)
            self.assertFalse(r["shown"]); self.assertEqual(r["of_them_functions_of_this_file"], ["ode_lz4_pack"])
            # a reader's specification with a contract for something this file does not have: said, and the rest stands
            more = os.path.join(d, "more.spec")
            with open(spec) as f: text = f.read()
            with open(more, "w") as f: f.write(text + "\ncontract ode_elsewhere(n: number) {\n    returns n\n    stack 8\n}\n")
            code, out = run(obj, more)
            self.assertEqual(code, 0, out)
            self.assertIn("ode_elsewhere: NOT verified", out); self.assertIn("(this file has none of that name)", out); self.assertIn("3 function(s) verified in this file", out)
        code, out = run(obj)
        self.assertEqual(code, 0, out); self.assertNotIn("NOT verified", out)

    def test_a_proof_cannot_make_the_file_say_its_definitions_end(self):
        """The lemmas come with the proof. One that requires the impossible is shown, of nothing; the line about
        the definitions coming to an end is then "NOT shown", and the record says why. (The function itself is
        still shown: UTF-8's needs no lemma.)"""
        obj, _ = self.paths("utf8")
        carried = kdecode.Elf(obj).bytes_of(".ode.proof")
        with open(os.path.join(HERE, "utf8", "utf8.lemmas"), "rb") as f: lemmas = f.read()
        head = b"file utf8.lemmas %d\n" % len(lemmas)
        self.assertEqual(carried.count(head + lemmas), 1)
        bad = b"lemma points(bytes: bytes, at: number, count: number): number {\n    requires at < at\n    decreases 0\n}\n"
        with tempfile.TemporaryDirectory() as d:
            path = os.path.join(d, "p")
            with open(path, "wb") as f: f.write(carried.replace(head + lemmas, b"file utf8.lemmas %d\n" % len(bad) + bad))
            code, out = run(obj, "--proof", path, "--json", os.path.join(d, "r.json"), "--search")
            self.assertEqual(code, 1, out)                                    # and so the file is not shown
            self.assertIn("ode_utf8", out); self.assertIn("meets its public contract", out)        # (the function's own line stands)
            self.assertTrue(out.rstrip().split("\n")[-1].startswith("NOT shown: each function's code meets its contract as far as the contract says anything"), out)
            self.assertIn("NOT shown to come to an end on everything the contracts allow", out)
            self.assertNotIn("each is shown to come to an end", out)
            with open(os.path.join(d, "r.json")) as f: r = json.load(f)
            self.assertEqual(r["definitions_that_use_themselves"], ["points"]); self.assertEqual(len(r["of_them_not_shown_to_end"]), 1)
            self.assertFalse(r["shown"])
        code, out = run(obj)
        self.assertEqual(code, 0, out); self.assertIn("(points): each is shown to come to an end on everything the contracts allow", out)

    def test_the_record_says_how_and_by_what(self):
        """--json: how the arithmetic was verified, which definitions use themselves and whether they end, and the
        verifier's own files with their digests."""
        obj, _ = self.paths("lz4")
        with tempfile.TemporaryDirectory() as d:
            for extra, how, searched in (((), "by the proofs the file carries, verified by adding up", 0), (("--search",), "searched for by the verifier", 3)):
                code, out = run(obj, "--json", os.path.join(d, "r.json"), *extra)
                self.assertEqual(code, 0, out)
                with open(os.path.join(d, "r.json")) as f: r = json.load(f)
                self.assertTrue(r["shown"]); self.assertEqual(r["arithmetic"], how); self.assertEqual(len(r["arithmetic_searched_for"]), searched)
                self.assertEqual((r["definitions_that_use_themselves"], r["of_them_not_shown_to_end"]), (["counted", "match", "sequences"], []))
                files = {x["file"]: x["blake3"] for x in r["verifier"]}
                for name in ("kbyte.py", "ode.py", "klin.py", "varith.py", "kdecode.py", "programs/check_file.py"):
                    with open(os.path.join(os.path.dirname(HERE), name), "rb") as f: self.assertEqual(files[name], kshow.b3(f.read()), name)
                self.assertEqual("kprove.py" in files, bool(extra))                      # the search is loaded only where it is asked for
                self.assertNotIn("check_binary.py", files); self.assertNotIn("kloop.py", files); self.assertNotIn("kone.py", files)
                self.assertEqual(r["verifier_blake3"], kshow.b3("".join(f"{x['blake3']}  {x['file']}\n" for x in r["verifier"]).encode()))

    def test_the_proof_carried_is_the_folders(self):
        for name in NAMES:
            obj, spec = self.paths(name)
            e = kdecode.Elf(obj)
            proof = check_binary.carried(e.bytes_of(".ode.proof"))
            with open(spec, "rb") as f: text = f.read()
            self.assertEqual(proof["spec"], kshow.b3(text), name)
            self.assertEqual(proof["files"]["specification"], text, "the specification the file carries is the folder's")
            code, out = run(obj)                                        # with the file alone: against what it carries, and it says so
            self.assertEqual(code, 0, out); self.assertIn("the specification is the one the file carries", out)
            text = e.bytes_of(".text")
            self.assertEqual(proof["code"][:2], (len(text), kshow.b3(text)))
            self.assertEqual(sorted(proof["at"]), sorted("ode_" + f for p, f, _ in PROGRAMS if p == name))
            for function in [f for p, f, _ in PROGRAMS if p == name]:
                with open(os.path.join(HERE, name, function + ".proof"), "rb") as f: self.assertEqual(proof["files"][function + ".proof"], f.read(), function)
            self.assertFalse([s for s in e.sections if s["type"] == 4 and s["size"]], "nothing for a linker to fill in")

    def test_a_changed_proof_and_another_specification(self):
        obj, spec = self.paths("lz4")
        carried = kdecode.Elf(obj).bytes_of(".ode.proof")
        with tempfile.TemporaryDirectory() as d:
            # the proof is not trusted: one fact of one place left out (the lengths the container gives kept right)
            line = b"    fact a <= p\n"
            self.assertGreaterEqual(carried.count(line), 1)
            at = carried.index(line)
            head = carried[:at].rindex(b"file lz4_pack.proof ")
            old = carried[head:carried.index(b"\n", head)]
            changed = carried[:head] + b"file lz4_pack.proof " + str(int(old.split()[-1]) - len(line)).encode() + carried[head + len(old):at] + carried[at + len(line):]
            path = os.path.join(d, "changed.proof")
            with open(path, "wb") as f: f.write(changed)
            code, out = run(obj, spec, "--proof", path)
            self.assertEqual(code, 1, out)
            self.assertIn("ode_lz4_pack: NOT shown", out)
            self.assertIn("ode_lz4_decode ", out)                      # the others are as they were
            # a proof of other code: the file names its functions, so it is the places that do not fit
            other = os.path.join(d, "other.proof")
            with open(other, "wb") as f: f.write(kdecode.Elf(self.paths("adler32")[0]).bytes_of(".ode.proof"))
            code, out = run(obj, spec, "--proof", other)
            self.assertNotEqual(code, 0, out)
            # a file that carries a specification that is not the one its code meets: with the file alone, refused
            wrong = carried.replace(b"copies(out, offset)[n.value + 4])", b"copies(out, offset)[n.value + 3])")
            self.assertNotEqual(wrong, carried)
            path = os.path.join(d, "wrong.proof")
            with open(path, "wb") as f: f.write(wrong)
            code, out = run(obj, "--proof", path)
            self.assertEqual(code, 1, out); self.assertIn("NOT shown", out)
            # a reader's own specification, not the maker's: he is told, and the check is against his
            mine = os.path.join(d, "mine.spec")
            with open(spec) as f: text = f.read()
            with open(mine, "w") as f: f.write(text + "\n// a reader's note\n")
            code, out = run(obj, mine)
            self.assertEqual(code, 0, out); self.assertIn("NOT the one the maker had", out)
            changed_text = text.replace("copies(out, offset)[n.value + 4])", "copies(out, offset)[n.value + 3])")
            self.assertNotEqual(changed_text, text)
            with open(mine, "w") as f: f.write(changed_text)
            code, out = run(obj, mine)
            self.assertEqual(code, 1, out); self.assertIn("NOT shown", out)

    def test_verify_says_what_is_shown_what_ran_and_whether(self):
        """verify.py: the contract a reader is asked to rely on, the verification, the files that ran (and not the prover's)."""
        tool = os.path.join(os.path.dirname(HERE), "verify.py")
        obj, spec = self.paths("utf8")
        r = subprocess.run([sys.executable, tool, obj], capture_output=True, text=True)
        self.assertEqual(r.returncode, 0, r.stdout + r.stderr)
        for words in ("contract ode_utf8(input: n bytes, n: number)", "returns if failed(utf8(input)) then NO else utf8(input)", "meets its public contract",
                      "nothing was searched for", "varith.py", "kdecode.py", "not loaded (a prover's or a maker's, trusted for nothing): kprove.py, refute.py"):
            self.assertIn(words, r.stdout)
        ran = r.stdout[r.stdout.index("3. What ran"):]
        self.assertNotIn("kprove.py   ", ran)
        with tempfile.TemporaryDirectory() as d:
            with open(spec) as f: text = f.read()
            mine = os.path.join(d, "mine.spec")
            with open(mine, "w") as f: f.write(text.replace("if b < 128 then 1", "if b < 127 then 1"))
            r = subprocess.run([sys.executable, tool, obj, mine], capture_output=True, text=True)
            self.assertEqual(r.returncode, 1, r.stdout + r.stderr)
            self.assertIn("your own copy (mine.spec)", r.stdout); self.assertIn("NOT shown", r.stdout)


def patched(blob, changes):
    """The file's bytes with (place, bytes) put in."""
    b = bytearray(blob)
    for at, new in changes: b[at:at + len(new)] = new
    return bytes(b)


def symbol_entry(blob, name):
    """Where in the file the entry of `name` in its table of names is (24 bytes: name, kind and binding, visibility, section, value, size)."""
    e = kdecode.Elf(blob)
    return e.sections[e.index[".symtab"]]["off"] + 24 * next(k for k, s in enumerate(e.symbols) if s["name"] == name)


def section_header(blob, name):
    """Where in the file the header of that section is (name 4, type 4, flags 8, address 8, offset 8, size 8, ...)."""
    import struct
    e = kdecode.Elf(blob)
    return struct.unpack_from("<Q", blob, 40)[0] + e.index[name] * struct.unpack_from("<H", blob, 58)[0]


class Shape(unittest.TestCase):
    """An object to be linked is read only in the one shape whose every part a linker takes is read here
    (kdecode.linkable), and every name it gives a linker is of a function shown to meet a contract. Found
    November 16, 2026: the shipped odeframe.o with `ode_unframe` made LOCAL and another function under the GLOBAL
    name in a second executable section was verified as the shipped file is; a program linked with it ran the other."""
    def setUp(self):
        with open(os.path.join(HERE, "frame", "odeframe.o"), "rb") as f: self.blob = f.read()

    def verdict(self, blob, *more):
        with tempfile.TemporaryDirectory() as d:
            path = os.path.join(d, "x.o")
            with open(path, "wb") as f: f.write(blob)
            return run(path, *more)

    def test_the_shipped_files_are_of_that_shape(self):
        for name in NAMES:
            why, names = kdecode.linkable(kdecode.Elf(os.path.join(HERE, name, f"ode{name}.o")))
            self.assertIsNone(why, name); self.assertTrue(names, name)
        self.assertEqual(self.verdict(self.blob)[0], 0)

    def test_a_name_a_linker_reads_by_other_rules(self):
        at = symbol_entry(self.blob, "ode_unframe")
        self.assertEqual(self.blob[at + 4:at + 6], b"\x12\x00")                 # GLOBAL, a function, of default visibility
        for what, change in (("LOCAL: it goes to no caller", (at + 4, b"\x02")), ("WEAK: it may give way", (at + 4, b"\x22")),
                             ("an IFUNC: resolved when the program starts", (at + 4, b"\x1a")), ("hidden", (at + 5, b"\x02"))):
            code, out = self.verdict(patched(self.blob, [change]))
            self.assertEqual(code, 1, what); self.assertIn("a name of a kind this reader does not read", out, what); self.assertNotIn("meets its public contract", out, what)

    def test_a_section_a_linker_would_take(self):
        import struct
        stack = section_header(self.blob, ".note.GNU-stack")
        code, out = self.verdict(patched(self.blob, [(stack + 8, struct.pack("<Q", 4))]))      # the stack asked to be executable
        self.assertEqual(code, 1, out); self.assertIn("has not the leave", out)
        code, out = self.verdict(patched(self.blob, [(section_header(self.blob, ".ode.proof") + 8, struct.pack("<Q", 6))]))      # the proof's section, to be loaded and run
        self.assertEqual(code, 1, out); self.assertIn("has not the leave", out)
        self.assertEqual(self.blob.count(b".note.GNU-stack\0"), 1)
        k = self.blob.index(b".note.GNU-stack\0")
        code, out = self.verdict(patched(self.blob, [(k, b".text.unlikely\0\0")]))             # a section of a name this reader does not know
        self.assertEqual(code, 1, out); self.assertIn("a section this reader does not read ('.text.unlikely')", out); self.assertNotIn("loaded to be run", out)

    def test_no_word_about_the_stack(self):
        """An object with no section .note.GNU-stack: a linker takes that as asking for a stack that can be run."""
        import types
        e = kdecode.Elf(self.blob)
        sections = [s for s in e.sections if s["name"] != ".note.GNU-stack"]
        why, names = kdecode.linkable(types.SimpleNamespace(sections=sections, symbols=e.symbols, index={s["name"]: i for i, s in enumerate(sections)}))
        self.assertIn("no section .note.GNU-stack", why); self.assertEqual(names, {})

    def test_a_name_with_no_contract(self):
        """A reader's specification without a contract for one of the file's functions: that name is given to a
        linker and nothing is shown of it. Said, and NOT shown."""
        obj, spec = os.path.join(HERE, "lz4", "odelz4.o"), os.path.join(HERE, "lz4", "lz4.spec")
        with open(spec) as f: text = f.read()
        a = text.index("contract ode_lz4_pack(")
        z = text.index("\n}\n", a) + 3
        with tempfile.TemporaryDirectory() as d:
            mine = os.path.join(d, "mine.spec")
            with open(mine, "w") as f: f.write(text[:a] + text[z:])
            code, out = run(obj, mine)
            self.assertEqual(code, 1, out); self.assertIn("ode_lz4_pack: NOT verified: the file gives a linker this name", out)

    def test_a_file_without_names_and_a_function_left_out(self):
        """A file stripped of its names whose proof is silent about one of its functions: whether the file holds
        that function cannot be told. NOT shown (it was exit 0 until November 16, 2026)."""
        import re, struct
        with open(os.path.join(HERE, "lz4", "odelz4.o"), "rb") as f: blob = f.read()
        carried = kdecode.Elf(blob).bytes_of(".ode.proof")
        line = re.search(rb"at \d+ ode_lz4_pack\n", carried)
        self.assertIsNotNone(line)
        stripped = patched(blob, [(section_header(blob, ".symtab") + 32, struct.pack("<Q", 24))])      # its table of names cut to the empty first entry
        self.assertEqual(kdecode.linkable(kdecode.Elf(stripped)), (None, {}))
        with tempfile.TemporaryDirectory() as d:
            x, p = os.path.join(d, "x.o"), os.path.join(d, "p")
            with open(x, "wb") as f: f.write(stripped)
            with open(p, "wb") as f: f.write(carried)
            code, out = run(x, "--proof", p)
            self.assertEqual(code, 0, out); self.assertIn("the file does not name the functions", out)
            with open(p, "wb") as f: f.write(carried.replace(line.group(0), b""))
            code, out = run(x, "--proof", p)
            self.assertEqual(code, 1, out); self.assertIn("ode_lz4_pack: NOT verified", out); self.assertIn("this file names no functions", out)


class Readers(unittest.TestCase):
    """Two readers. An auditor is told what he has use for, and nothing its maker chose that he need not read;
    a maintainer asks for the rest (--maintain). Digits are BLAKE3's, all 64. No control character passes."""
    tool = os.path.join(os.path.dirname(HERE), "verify.py")

    def test_an_auditor_is_not_shown_the_makers_names(self):
        obj = os.path.join(HERE, "frame", "odeframe.o")
        r = subprocess.run([sys.executable, self.tool, obj], capture_output=True, text=True)
        self.assertEqual(r.returncode, 0, r.stdout + r.stderr)
        said = r.stdout[r.stdout.index("2. The verification"):r.stdout.index("3. What ran")]
        self.assertIn("ode_unframe: meets its public contract", said)
        for inner in ("ode_lz4_decode", "ode_adler32_blocks4", "counted", "sequences"): self.assertNotIn(inner, said, inner)
        self.assertRegex(r.stdout, r"BLAKE3 [0-9a-f]{64}\b"); self.assertNotIn("SHA-256", r.stdout); self.assertNotIn("...", said)
        r = subprocess.run([sys.executable, self.tool, obj, "--maintain"], capture_output=True, text=True)
        self.assertEqual(r.returncode, 0, r.stdout + r.stderr)
        for inner in ("ode_lz4_decode", "ode_adler32_blocks4", "counted, match, sequences", "calls ode_adler32_blocks4, ode_lz4_decode by contract"): self.assertIn(inner, r.stdout, inner)

    def test_a_refusal_as_each_reader_is_told_it(self):
        obj, spec = os.path.join(HERE, "frame", "odeframe.o"), os.path.join(HERE, "frame", "frame.spec")
        with open(spec) as f: text = f.read()
        self.assertEqual(text.count("65521"), 2)
        with tempfile.TemporaryDirectory() as d:
            mine = os.path.join(d, "mine.spec")
            with open(mine, "w") as f: f.write(text.replace("65521", "65522"))
            r = subprocess.run([sys.executable, self.tool, obj, mine], capture_output=True, text=True)
            said = r.stdout[r.stdout.index("2. The verification"):r.stdout.index("3. What ran")]
            self.assertEqual(r.returncode, 1, r.stdout); self.assertIn("ode_unframe: NOT shown", said); self.assertIn("--maintain", said)
            for inner in ("ode_adler32_blocks4", "s1.", "@0x"): self.assertNotIn(inner, said, inner)
            r = subprocess.run([sys.executable, self.tool, obj, mine, "--maintain"], capture_output=True, text=True)
            self.assertEqual(r.returncode, 1, r.stdout); self.assertIn("ode_adler32_blocks4: NOT shown:", r.stdout)

    def test_the_carried_specification_is_shown_and_no_control_character_passes(self):
        obj = os.path.join(HERE, "utf8", "odeutf8.o")
        with open(os.path.join(HERE, "utf8", "utf8.spec")) as f: text = f.read()
        r = subprocess.run([sys.executable, self.tool, obj, "--show-spec"], capture_output=True, text=True)
        self.assertEqual((r.returncode, r.stdout), (0, text))
        carried = kdecode.Elf(obj).bytes_of(".ode.proof")
        k = carried.index(b"// ")
        with tempfile.TemporaryDirectory() as d:
            p = os.path.join(d, "p")
            with open(p, "wb") as f: f.write(carried[:k + 3] + b"\x1b[2K\r" + carried[k + 8:])      # in a comment: an escape that takes a line back, and a return
            for tool in ([self.tool], [os.path.join(HERE, "check_file.py")]):
                r = subprocess.run([sys.executable] + tool + [obj, "--show-spec", "--proof", p], capture_output=True, text=True)
                self.assertEqual(r.returncode, 0, r.stdout + r.stderr)
                self.assertNotIn("\x1b", r.stdout); self.assertNotIn("\r", r.stdout); self.assertIn("\\x1b[2K\\x0d", r.stdout)

    def test_the_digits_are_blake3s_and_an_earlier_proof_is_refused(self):
        self.assertEqual(kshow.b3(b""), "af1349b9f5f9a1a6a0404dea36dcc9499bcb25c9adc112b7cc9a93cae41f3262")
        self.assertEqual(kshow.b3(b"abc"), "6437b3ac38465133ffb63b75273a8db548c558465d79db03fd359c6cd5bd9d85")
        obj = os.path.join(HERE, "utf8", "odeutf8.o")
        carried = kdecode.Elf(obj).bytes_of(".ode.proof")
        self.assertTrue(carried.startswith(b"ode proof 2\nspecification blake3 "))
        with tempfile.TemporaryDirectory() as d:
            p = os.path.join(d, "p")
            with open(p, "wb") as f: f.write(carried.replace(b"ode proof 2\n", b"ode proof 1\n", 1))
            r = subprocess.run([sys.executable, os.path.join(HERE, "check_file.py"), obj, "--proof", p], capture_output=True, text=True)
            self.assertNotEqual(r.returncode, 0); self.assertIn("earlier form", r.stdout + r.stderr)


if __name__ == "__main__":
    unittest.main()
