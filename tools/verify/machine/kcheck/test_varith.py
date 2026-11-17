#!/usr/bin/env python3
"""varith.py: a proof of arithmetic that adds up is taken, one that does not shows nothing; and the shipped
files are shown by the proofs they carry with klin.py's search taken away.

    python3 test_varith.py"""
import os, re, subprocess, sys, tempfile, unittest
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE); sys.path.insert(0, os.path.join(HERE, "programs"))
import check_binary, kbyte, kdecode, klin, kprove, ode, varith
from klin import Lin, sym

x, y, z = sym("x"), sym("y"), sym("z")
row = lambda f: (dict(f.c), f.k)


class Arithmetic(unittest.TestCase):
    def test_a_proof_that_adds_up(self):
        # x >= 0, y - x >= 0, 5 - y >= 0, and (asked: x <= 5?) x - 6 >= 0: cannot all be
        rows = [row(x), row(y - x), row(Lin.of(5) - y), row(x - 6)]
        proof = ([rows[1], rows[2], rows[3]], [(0, 1, 1, 1), (3, 1, 2, 1)])       # (y - x) + (5 - y) = 5 - x; + (x - 6) = -1
        given = {varith.key(r) for r in rows}
        self.assertTrue(varith.refutes(given, proof))
        self.assertTrue(varith.shown({varith.key(rows[-1]): [proof]}, rows))

    def test_what_does_not_add_up_shows_nothing(self):
        rows = [row(x), row(y - x), row(Lin.of(5) - y), row(x - 6)]
        given = {varith.key(r) for r in rows}
        good = ([rows[1], rows[2], rows[3]], [(0, 1, 1, 1), (3, 1, 2, 1)])
        for starts, steps in (
            (good[0], [(0, 1, 1, 1)]),                                  # stops with a name left
            (good[0], [(0, 1, 1, 1), (3, 1, 2, 2)]),                    # a multiple that leaves x
            (good[0], [(0, 1, 1, 1), (3, 0, 2, 1)]),                    # a multiple of zero
            (good[0], [(0, 1, 1, 1), (3, -1, 2, 1)]),                   # a multiple below zero (a row turned round is no fact)
            (good[0], [(0, 1, 1, 1), (3, 1, 7, 1)]),                    # a row that is not there
            ([rows[1], rows[2], row(x - 7)], good[1]),                  # a row to start from that is not given
            ([rows[1], rows[2], row(x - 5)], good[1]),                  # the question made weaker: 5 - x + x - 5 = 0, not below zero
            ([], []), (good[0], []),
            (good[0], [(0, 1.5, 1, 1), (3, 1, 2, 1)]), (good[0], [(0, True, 1, 1)]),
        ):
            self.assertFalse(varith.refutes(given, (starts, steps)), (starts, steps))
        self.assertFalse(varith.shown({}, rows)); self.assertFalse(varith.shown({varith.key(rows[-1]): [good]}, rows[2:]))   # a row the proof needs is not known

    def test_whole_numbers_round_down_and_only_down(self):
        # 2x - 1 >= 0 and 1 - 2x >= 0: no whole x (x >= 1/2 and x <= 1/2); the step divides by 2 and rounds
        rows = [row(x.scale(2) - 1), row(Lin.of(1) - x.scale(2))]
        self.assertEqual(varith.combine(rows[0], 1, rows[0], 1), ({"x": 1}, -1))        # 4x - 2 >= 0 is x - 1/2 >= 0: x - 1 >= 0 for whole x
        proof = (rows, [(0, 1, 0, 1), (1, 1, 1, 1), (2, 1, 3, 1)])
        self.assertTrue(varith.refutes({varith.key(r) for r in rows}, proof))
        # the same shape where there is a whole x: 2x >= 0 and 0 - 2x >= 0 (x = 0)
        rows = [row(x.scale(2)), row(-x.scale(2))]
        self.assertFalse(varith.refutes({varith.key(r) for r in rows}, (rows, [(0, 1, 0, 1), (1, 1, 1, 1), (2, 1, 3, 1)])))

    def test_the_prover_finds_what_the_search_shows_and_the_table_survives_its_bytes(self):
        import random
        rnd, n = random.Random(5), 0
        for _ in range(400):
            names = [sym(f"v{k}") for k in range(4)]
            system = []
            for _ in range(rnd.randrange(2, 7)):
                f = Lin.of(rnd.randrange(-6, 7))
                for v in rnd.sample(names, rnd.randrange(1, 4)): f = f + v.scale(rnd.choice([-3, -2, -1, 1, 2, 3]))
                system.append(klin.Facts.norm(f))
            if not klin.Facts.search(system): continue
            p = kprove.find(system, klin.Facts.search)
            self.assertIsNotNone(p, system)                             # what the search shows, the prover can write out
            n += 1
            rows = [row(f) for f in system]
            table = varith.unpack(varith.pack({varith.key(rows[-1]): [p]}))
            self.assertTrue(varith.shown(table, rows))
            # and a system that CAN hold is never shown: every one of its rows made true by some whole numbers
        self.assertGreater(n, 30)

    def test_numbers_that_can_all_hold_have_no_proof(self):
        """Soundness on small systems: where whole numbers make every row >= 0, nothing the prover writes (or
        anything else of the proof's form, tried at random) is taken."""
        import itertools, random
        rnd, tried = random.Random(9), 0
        for _ in range(300):
            names = ["a", "b", "c"]
            system = []
            for _ in range(rnd.randrange(2, 6)):
                c = {v: rnd.choice([-2, -1, 1, 2]) for v in rnd.sample(names, rnd.randrange(1, 4))}
                system.append((c, rnd.randrange(-4, 5)))
            holds = any(all(sum(m * val[v] for v, m in c.items()) + k >= 0 for c, k in system)
                        for val in ({"a": p, "b": q, "c": r} for p, q, r in itertools.product(range(-6, 7), repeat=3)))
            if not holds: continue
            given = {varith.key(r) for r in system}
            for _ in range(60):
                steps = [(rnd.randrange(len(system) + j), rnd.randrange(1, 4), rnd.randrange(len(system) + j), rnd.randrange(1, 4)) for j in range(rnd.randrange(1, 5))]
                tried += 1
                self.assertFalse(varith.refutes(given, (system, steps)), (system, steps))
        self.assertGreater(tried, 3000)


def no_search(*a, **k): raise AssertionError("the search was used")


class Shipped(unittest.TestCase):
    """The files as shipped: shown by the arithmetic's proofs they carry, with the search not there to be used."""
    def setUp(self):
        self.saved = (klin.Facts.search, klin.Facts.bounds)
        klin.Facts.search = klin.Facts.bounds = staticmethod(no_search)
    def tearDown(self):
        klin.Facts.search, klin.Facts.bounds = self.saved
        klin.Facts.PROOFS = None

    def programs(self):
        for program in ("adler32", "lz4", "varint", "common", "utf8", "base64", "inet", "frame"):
            path = os.path.join(HERE, "programs", program, f"ode{program}.o")
            proof = check_binary.carried(kdecode.Elf(path).bytes_of(".ode.proof"))
            inner = "".join("\n" + body.decode() for name, body in sorted(proof["files"].items()) if name.endswith((".inner", ".lemmas")))
            text = proof["files"]["specification"].decode()
            spec = ode.with_proof(text, inner) if inner else ode.Spec(text)
            for symbol in sorted(proof["at"]):
                yield path, proof, spec, symbol

    def test_every_program_is_shown_with_no_search(self):
        n = 0
        for path, proof, spec, symbol in self.programs():
            name = symbol[len("ode_"):]
            klin.Facts.PROOFS = varith.unpack(proof["files"][name + ".arith.z"]) if name + ".arith.z" in proof["files"] else {}
            kbyte.check(kbyte.load(path, symbol), spec, symbol, proof["files"].get(name + ".proof", b"").decode())
            n += 1
        self.assertEqual(n, 14)                                         # twelve functions, two of them in two files

    def test_without_its_proofs_or_with_anothers_a_function_is_not_shown(self):
        tables = {}
        for path, proof, spec, symbol in self.programs():
            name = symbol[len("ode_"):]
            if name + ".arith.z" in proof["files"]: tables[(path, symbol)] = (proof, spec, varith.unpack(proof["files"][name + ".arith.z"]))
        (pa, sa), (pb, sb) = [k for k in tables if k[1] in ("ode_varint", "ode_utf8")]
        for (path, symbol), table in (((pa, sa), {}), ((pa, sa), tables[(pb, sb)][2]), ((pb, sb), tables[(pa, sa)][2])):
            proof, spec, _ = tables[(path, symbol)]
            klin.Facts.PROOFS = table
            with self.assertRaises(ode.Err, msg=symbol):
                kbyte.check(kbyte.load(path, symbol), spec, symbol, proof["files"].get(symbol[4:] + ".proof", b"").decode())

    def test_a_proof_changed_is_not_taken(self):
        """Every multiple of every step of varint's proofs made one more: none adds up, and the function is not shown."""
        path = os.path.join(HERE, "programs", "varint", "odevarint.o")
        proof = check_binary.carried(kdecode.Elf(path).bytes_of(".ode.proof"))
        table = varith.unpack(proof["files"]["varint.arith.z"])
        changed = {k: [(starts, [(i, a + 1, j, b) for i, a, j, b in steps]) for starts, steps in ps] for k, ps in table.items()}
        klin.Facts.PROOFS = changed
        with self.assertRaises(ode.Err):
            kbyte.check(kbyte.load(path, "ode_varint"), ode.Spec(proof["files"]["specification"].decode()), "ode_varint", "")


class Drivers(unittest.TestCase):
    def run_tool(self, *args):
        r = subprocess.run([sys.executable, *args], capture_output=True, text=True)
        return r.returncode, r.stdout + r.stderr

    def test_the_drivers_say_how_the_arithmetic_was_answered(self):
        code, out = self.run_tool(os.path.join(HERE, "programs", "check_file.py"), os.path.join(HERE, "programs", "utf8", "odeutf8.o"), "--maintain")
        self.assertEqual(code, 0, out); self.assertIn("nothing was searched for", out)
        code, out = self.run_tool(os.path.join(HERE, "programs", "check_file.py"), os.path.join(HERE, "programs", "utf8", "odeutf8.o"), "--maintain", "--search")
        self.assertEqual(code, 0, out); self.assertIn("searched for by this program", out)

    def test_a_file_whose_arithmetic_proofs_are_damaged_is_not_shown(self):
        path = os.path.join(HERE, "programs", "varint", "odevarint.o")
        carried = kdecode.Elf(path).bytes_of(".ode.proof")
        m = re.search(rb"file varint.arith.z (\d+)\n", carried)
        n = int(m.group(1))
        with tempfile.TemporaryDirectory() as d:
            for label, body in (("cut short", carried[m.end():m.end() + n - 9]), ("not a table", b"x" * n), ("an empty table", varith.pack({}))):
                p = os.path.join(d, "p")
                with open(p, "wb") as f: f.write(carried[:m.start()] + b"file varint.arith.z %d\n" % len(body) + body + carried[m.end() + n:])
                code, out = self.run_tool(os.path.join(HERE, "programs", "check_file.py"), path, "--maintain", "--proof", p)
                self.assertEqual(code, 1, f"{label}: {out}"); self.assertIn("NOT shown", out, label)


if __name__ == "__main__":
    unittest.main()
