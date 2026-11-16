#!/usr/bin/env python3
"""The programs as they are shipped (programs/NAME/odeNAME.o), checked as files by check_file.py.

    python3 programs/test_files.py

Each file meets its specification's public contracts; the proof it carries is the folder's, made with the
folder's specification; a proof with a line left out, or of other code, is refused; a reader with another
specification is told so."""
import hashlib, json, os, subprocess, sys, tempfile, unittest
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(HERE))
import check_binary, kdecode
from check_programs import PROGRAMS

NAMES = sorted({p for p, _, _ in PROGRAMS})


def run(*args):
    r = subprocess.run([sys.executable, os.path.join(HERE, "check_file.py")] + list(args), capture_output=True, text=True)
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
                files = {x["file"]: x["sha256"] for x in r["verifier"]}
                for name in ("kbyte.py", "ode.py", "klin.py", "varith.py", "kdecode.py", "programs/check_file.py"):
                    with open(os.path.join(os.path.dirname(HERE), name), "rb") as f: self.assertEqual(files[name], hashlib.sha256(f.read()).hexdigest(), name)
                self.assertEqual("kprove.py" in files, bool(extra))                      # the search is loaded only where it is asked for
                self.assertNotIn("check_binary.py", files); self.assertNotIn("kloop.py", files); self.assertNotIn("kone.py", files)
                self.assertEqual(r["verifier_sha256"], hashlib.sha256("".join(f"{x['sha256']}  {x['file']}\n" for x in r["verifier"]).encode()).hexdigest())

    def test_the_proof_carried_is_the_folders(self):
        for name in NAMES:
            obj, spec = self.paths(name)
            e = kdecode.Elf(obj)
            proof = check_binary.carried(e.bytes_of(".ode.proof"))
            with open(spec, "rb") as f: text = f.read()
            self.assertEqual(proof["spec"], hashlib.sha256(text).hexdigest(), name)
            self.assertEqual(proof["files"]["specification"], text, "the specification the file carries is the folder's")
            code, out = run(obj)                                        # with the file alone: against what it carries, and it says so
            self.assertEqual(code, 0, out); self.assertIn("the specification is the one the file carries", out)
            text = e.bytes_of(".text")
            self.assertEqual(proof["code"][:2], (len(text), hashlib.sha256(text).hexdigest()))
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


if __name__ == "__main__":
    unittest.main()
