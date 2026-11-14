#!/usr/bin/env python3
"""kcheck on the library's own wide kernels, from the library's assembly source.

    python3 test_kcheck.py

c/blake3_avx512_32.S is assembled (clang where there is one, else cc), the object's bytes are read by
kdecode.py, and kcheck.py shows each of the three kernels against the specification. Then the controls:
changed kernels are refused; a kernel is refused against another's specification; the specification gives the
official test vector; and, where there is an objdump, kdecode's reading is the lifter's (one/lift_one.py)
instruction for instruction. The single-bit audit with a processor's verdict (kflip.py) is not run here: it
wants an AVX-512 machine and a minute."""
import os, shutil, subprocess, sys, tempfile, unittest

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", "..", "..", ".."))
sys.path.insert(0, HERE)
import kcheck, kdecode

BASE, DATA = 0x10000, 0x50000000
OBJDUMP = os.environ.get("OBJDUMP") or shutil.which("llvm-objdump") or shutil.which("objdump")


def assemble(s_path, o_path):
    for cc in (["clang", "--target=x86_64-unknown-linux-gnu"], ["cc", "-target", "x86_64-unknown-linux-gnu"]):
        if shutil.which(cc[0]) and subprocess.run(cc + ["-c", "-o", o_path, s_path], capture_output=True).returncode == 0: return
    subprocess.run(["cc", "-c", "-o", o_path, s_path], check=True)


def load(obj, name):
    rows, data = kdecode.read(obj, kcheck.KERNELS[name]["start"], BASE, DATA)
    entry = BASE + kdecode.address(obj, "blake3_servil_avx512_" + name) - kdecode.address(obj, kcheck.KERNELS[name]["start"])
    return rows, data, entry


class Kcheck(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.dir = tempfile.mkdtemp(prefix="kcheck-")
        cls.obj = os.path.join(cls.dir, "k.o")
        assemble(os.path.join(ROOT, "c", "blake3_avx512_32.S"), cls.obj)

    @classmethod
    def tearDownClass(cls):
        shutil.rmtree(cls.dir)

    def test_the_three_kernels_meet_the_specification(self):
        for name, steps in (("k32", 32203), ("p32", 32195), ("p16", 1070)):
            rows, data, entry = load(self.obj, name)
            m, T = kcheck.check(rows, DATA, data, name, entry)
            self.assertEqual(m.steps, steps, name)
            self.assertLessEqual(-m.low, 4096, name)

    def test_changed_kernels_are_refused(self):
        rows, data, entry = load(self.obj, "k32")
        for label, old, new in kcheck.MUTANTS:
            hits = [k for k, r in enumerate(rows) if r[2] == old]
            self.assertTrue(hits, f"no instruction `{old}` to change ({label})")
            changed = list(rows); a, n, _ = changed[hits[0]]; changed[hits[0]] = (a, n, new)
            with self.assertRaises(kcheck.Fail, msg=label):
                kcheck.check(changed, DATA, data, "k32", entry)
        bad = bytearray(data); bad[0xC0 + 64 + 4] ^= 0x40           # one entry of the message schedule
        with self.assertRaises(kcheck.Fail):
            kcheck.check(rows, DATA, bytes(bad), "k32", entry)

    def test_a_kernel_is_refused_against_another_specification(self):
        rows, data, entry = load(self.obj, "k32")
        p32 = BASE + kdecode.address(self.obj, "blake3_servil_avx512_p32") - kdecode.address(self.obj, "blake3_servil_avx512_k32")
        with self.assertRaises(kcheck.Fail):
            kcheck.check(rows, DATA, data, "k32", p32)          # the fixed-counter entry, the counting specification
        with self.assertRaises(kcheck.Fail):
            kcheck.check(rows, DATA, data, "p32", entry)        # and the other way

    def test_a_frame_that_is_not_whole_cells_is_refused(self):
        # found by kflip.py: `sub rsp, 0x101` was accepted, and its aligned stores fault on a processor
        rows, data, entry = load(self.obj, "p16")
        k = next(k for k, r in enumerate(rows) if r[2] == ".sub 64 (.reg .rsp) (.imm 0x100)")
        for size in ("0x101", "0x120", "0xC0"):
            changed = list(rows); changed[k] = (rows[k][0], rows[k][1], f".sub 64 (.reg .rsp) (.imm {size})")
            with self.assertRaises(kcheck.Fail, msg=size):
                kcheck.check(changed, DATA, data, "p16", entry)

    def test_a_sum_that_doubles_is_stopped(self):
        # found by kflip.py: a changed kernel that adds a register to itself in a loop ran out of memory
        T = kcheck.Terms()
        x = T.add(T.var("key", 0), T.var("key", 1))
        with self.assertRaises(kcheck.Fail):
            for _ in range(12): x = T.add(x, x)

    def test_the_specification_gives_the_official_vector(self):
        got = kcheck.anchor(os.path.join(ROOT, "test_vectors", "test_vectors.json"))
        self.assertTrue(got.startswith("e776b6028c7cd22a"), got)

    def test_the_decoder_stops_at_encodings_no_assembler_writes(self):
        with open(self.obj, "rb") as f: obj = f.read()
        e = kdecode.Elf(obj); sec = e.sections[e.index[".text"]]
        start = sec["off"] + kdecode.address(obj, "blake3_servil_avx512_p16")
        rows, _ = kdecode.read(obj, "blake3_servil_avx512_p16", BASE, DATA)
        def changed(ins, byte, bit):
            r = next(r for r in rows if r[2] == ins)
            b = bytearray(obj); b[start + r[0] - BASE + byte] ^= 1 << bit
            return bytes(b)
        for ins, byte, bit, what in ((".push .r15", 0, 3, "REX.W on a push"), (".push .r15", 0, 1, "REX.X on a push"),
                                     (".zprord 4 4 12", 1, 7, "EVEX.R beside an opcode digit"), (".zload true 19 .rsp 0x0", 6, 6, "a scale with no index"),
                                     (".sub 64 (.reg .rsp) (.imm 0x100)", 0, 3, "an empty REX prefix"), (".cmp 64 (.reg .r13) (.imm 0x1)", 0, 2, "REX.R beside an opcode digit")):
            with self.assertRaises(kdecode.Stop, msg=what):
                kdecode.read(changed(ins, byte, bit), "blake3_servil_avx512_p16", BASE, DATA)

    @unittest.skipUnless(OBJDUMP, "no objdump: the lifter's reading is not made")
    def test_the_decoder_reads_what_the_lifter_reads(self):
        listing = os.path.join(self.dir, "k.listing")
        with open(listing, "w") as f:
            subprocess.run([OBJDUMP, "-d", "-r", "--x86-asm-syntax=intel", self.obj], stdout=f, check=True)
        lift = os.path.join(HERE, "..", "one", "lift_one.py")
        for symbol, base in (("blake3_servil_avx512_p16", "0x18000"), ("blake3_servil_avx512_p32", "0x1000C")):
            out = os.path.join(self.dir, symbol)
            subprocess.run([sys.executable, lift, listing, symbol, base, out + ".lean", "L", "--object", self.obj, "--rodata", "0x50000000"], check=True, capture_output=True)
            r = subprocess.run([sys.executable, os.path.join(HERE, "kdecode.py"), "--compare", self.obj, symbol, base, "0x50000000", out + ".lean.rows", out + ".lean.data"], capture_output=True, text=True)
            self.assertEqual(r.returncode, 0, r.stdout)
            self.assertIn("the same, every one", r.stdout)


if __name__ == "__main__":
    unittest.main()
