#!/usr/bin/env python3
"""The programs as they are shipped (programs/NAME/odeNAME.o), checked as files by check_file.py.

    python3 programs/test_files.py

Each file meets its specification's public contracts; the proof it carries is the folder's, made with the
folder's specification; a proof with a line left out, or of other code, is refused; a reader with another
specification is told so."""
import hashlib, os, subprocess, sys, tempfile, unittest
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
            wrong = carried.replace(b"copies(out, offset)[n.value + 4], cap)", b"copies(out, offset)[n.value + 3], cap)")
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
            with open(mine, "w") as f: f.write(text.replace("copies(out, offset)[n.value + 4], cap)", "copies(out, offset)[n.value + 3], cap)"))
            code, out = run(obj, mine)
            self.assertEqual(code, 1, out); self.assertIn("NOT shown", out)


if __name__ == "__main__":
    unittest.main()
