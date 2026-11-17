#!/usr/bin/env python3
"""Tests of varith2.c, the second verifier of the arithmetic's proofs: it says of every proof the shipped files
carry what the first says (they add up), and of thousands of proofs changed in one place the two say the same,
proof by proof. (Skipped where there is no C compiler or no zlib to link.)"""
import glob, os, random, shutil, subprocess, sys, tempfile, unittest
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import kdecode, kproof, varith

SHIPPED = [os.path.join(HERE, "b3hashr.o")] + sorted(glob.glob(os.path.join(HERE, "programs", "*", "ode*.o")))


def build(folder):
    out = os.path.join(folder, "varith2")
    r = subprocess.run([os.environ.get("CC", "cc"), "-O2", "-o", out, os.path.join(HERE, "varith2.c"), "-lz"], capture_output=True, text=True)
    return out if r.returncode == 0 else None


def first_says(proof):
    """The first verifier, of a proof alone: do the rows it starts from fail to hold all together, by its steps?"""
    starts, steps = proof
    try: return varith.refutes({varith.key(r) for r in starts}, proof)
    except Exception: return False


def beside(folder, name, table_bytes):
    """A proof kept beside a file, holding one table."""
    path = os.path.join(folder, name)
    with open(path, "wb") as f: f.write(b"ode proof 2\nfile t.arith.z %d\n" % len(table_bytes) + table_bytes)
    return path


class Second(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.dir = tempfile.mkdtemp(prefix="varith2-")
        cls.exe = build(cls.dir) if shutil.which(os.environ.get("CC", "cc")) else None
    @classmethod
    def tearDownClass(cls): shutil.rmtree(cls.dir)
    def setUp(self):
        if self.exe is None: self.skipTest("no C compiler with zlib here")

    def proofs(self):
        """Every proof of arithmetic the shipped files carry: [(starts, steps)]."""
        out = []
        for path in SHIPPED:
            carried = kproof.carried(kdecode.Elf(path).bytes_of(".ode.proof"))
            for name, blob in sorted(carried["files"].items()):
                if name.endswith(".arith.z"):
                    for proofs in varith.unpack(blob).values(): out += proofs
        return out

    def test_the_shipped_files(self):
        r = subprocess.run([self.exe] + SHIPPED, capture_output=True, text=True)
        self.assertEqual(r.returncode, 0, r.stdout[-800:])
        n = len(self.proofs())
        self.assertGreater(n, 7000)
        self.assertIn(f'varith2: {n} proofs of arithmetic: {n} add up to "these rows cannot all hold"', r.stdout)
        self.assertNotIn("DO NOT", r.stdout); self.assertNotIn("not judged", r.stdout)

    def test_the_two_say_the_same_of_changed_proofs(self):
        """Each of some thousands of proofs changed in one place (a multiplier, which rows a step takes, a plain
        number, a multiple of a name, a step left out, the steps of another proof): what the first verifier says
        of it and what the second says, proof by proof."""
        rng = random.Random(20261116)
        proofs = self.proofs()
        changed, kinds = [], {}
        for starts, steps in rng.sample(proofs, 1500):
            starts = [(dict(c), k) for c, k in starts]; steps = [tuple(s) for s in steps]
            kind = rng.choice(["multiplier", "which", "number", "multiple", "left out", "another", "as it is", "zero", "name gone"])
            if kind == "multiplier" and steps:
                s = rng.randrange(len(steps)); i, a, j, b = steps[s]; d = rng.choice([1, -1, 2, a])
                steps[s] = (i, a + d, j, b) if rng.random() < 0.5 else (i, a, j, b + d)
            elif kind == "zero" and steps:
                s = rng.randrange(len(steps)); i, a, j, b = steps[s]; steps[s] = rng.choice([(i, 0, j, b), (i, a, j, 0), (i, -a, j, b), (i, a, j, -b)])
            elif kind == "which" and steps:
                s = rng.randrange(len(steps)); i, a, j, b = steps[s]; steps[s] = (rng.randrange(-1, len(starts) + len(steps) + 1), a, j, b) if rng.random() < 0.5 else (i, a, rng.randrange(-1, len(starts) + s + 2), b)
            elif kind == "number":
                r = rng.randrange(len(starts)); starts[r] = (starts[r][0], starts[r][1] + rng.choice([1, -1, 2, 255, -(1 << 64), 1 << 64]))
            elif kind == "multiple" and any(c for c, _ in starts):
                r = rng.choice([x for x in range(len(starts)) if starts[x][0]]); n = rng.choice(sorted(starts[r][0]))
                c = dict(starts[r][0]); c[n] += rng.choice([1, -1, c[n]]); starts[r] = ({k: v for k, v in c.items() if v}, starts[r][1])
            elif kind == "name gone" and any(c for c, _ in starts):
                r = rng.choice([x for x in range(len(starts)) if starts[x][0]]); c = dict(starts[r][0]); c.pop(rng.choice(sorted(c))); starts[r] = (c, starts[r][1])
            elif kind == "left out" and steps: steps.pop(rng.randrange(len(steps)))
            elif kind == "another": steps = [tuple(s) for s in rng.choice(proofs)[1]]
            kinds[kind] = kinds.get(kind, 0) + 1
            changed.append((starts, steps))
        # the tables as bytes: one proof a table, so that a proof the packer cannot write stops only itself
        said = []
        blob = b"ode proof 2\n"
        kept = []
        for k, p in enumerate(changed):
            try: z = varith.pack({k: [p]})
            except Exception: continue
            blob += b"file p%d.arith.z %d\n" % (k, len(z)) + z; kept.append(p)
        path = os.path.join(self.dir, "changed.proof")
        with open(path, "wb") as f: f.write(blob)
        r = subprocess.run([self.exe, "--each", path], capture_output=True, text=True)
        letters = [l for l in r.stdout.split("\n") if l in ("y", "n", "?")]
        self.assertEqual(len(letters), len(kept), r.stdout[-600:])
        first = ["y" if first_says(p) else "n" for p in kept]
        differ = [(k, a, b) for k, (a, b) in enumerate(zip(first, letters)) if a != b]
        self.assertEqual(differ, [], f"the two verifiers differ on {len(differ)} of {len(kept)} changed proofs; the first: {kept[differ[0][0]] if differ else None}")
        self.assertGreater(first.count("y"), 50); self.assertGreater(first.count("n"), 500)          # both answers were asked for
        self.assertGreater(len(kinds), 6)

    def test_what_is_no_table_is_no_proof(self):
        import zlib
        for junk in (b"", b"not zlib", zlib.compress(b"{}"), zlib.compress(b'{"names":[],"proofs":[[[],[]]]}'), zlib.compress(b'{"names":["x"],"proofs":[[[[[0,1],0.5]],[]]]}'),
                     zlib.compress(b'{"names":["x"],"proofs":[[[[[0,1],-1]],[]]]}'),            # a name is left: x - 1 >= 0 can hold
                     zlib.compress(b'{"names":["x"],"proofs":[[[[[5,1],-1]],[]]]}')):           # a name that is not there
            r = subprocess.run([self.exe, beside(self.dir, "junk.proof", junk)], capture_output=True, text=True)
            self.assertNotEqual(r.returncode, 0, (junk, r.stdout))
        # and the smallest proofs there are: -1 >= 0 cannot hold; x >= 0 and -x - 1 >= 0 cannot both
        for good in (b'{"names":[],"proofs":[[[[[],-1]],[]]]}', b'{"names":["x"],"proofs":[[[[[0,1],0],[[0,-1],-1]],[[0,1,1,1]]]]}',
                     b'{"names":["x"],"proofs":[[[[[0,2],-1],[[0,-2],1]],[[0,1,0,1],[2,2,1,1]]]]}'):            # 2x >= 1 rounds to x >= 1; twice that with 1 >= 2x: -1 >= 0
            r = subprocess.run([self.exe, beside(self.dir, "good.proof", zlib.compress(good))], capture_output=True, text=True)
            self.assertEqual(r.returncode, 0, (good, r.stdout))
            for proofs in varith.unpack(zlib.compress(good)).values(): self.assertTrue(all(first_says(p) for p in proofs), good)      # and the first says so too
        # the same steps where the rows can hold (x = 1): no proof
        odd = b'{"names":["x"],"proofs":[[[[[0,2],-1],[[0,-2],2]],[[0,1,0,1],[2,2,1,1]]]]}'                     # 2x >= 1 and 2 >= 2x: x = 1 holds: no proof
        r = subprocess.run([self.exe, beside(self.dir, "odd.proof", zlib.compress(odd))], capture_output=True, text=True)
        self.assertNotEqual(r.returncode, 0, r.stdout)
        for proofs in varith.unpack(zlib.compress(odd)).values(): self.assertFalse(any(first_says(p) for p in proofs))


if __name__ == "__main__":
    unittest.main()
