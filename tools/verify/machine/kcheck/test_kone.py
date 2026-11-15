#!/usr/bin/env python3
"""kone on the library's two one-block kernels: each meets its contract; changed ones do not; each against the
other's contract does not.

    python3 test_kone.py"""
import os, shutil, sys, tempfile, unittest

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", "..", "..", ".."))
sys.path.insert(0, HERE)
import kcheck, kone
from test_kcheck import assemble

SOURCES = {"avx512": "blake3_avx512_x86-64_unix.S", "sse41": "blake3_sse41_x86-64_unix.S"}
MUTANTS = [
    ("avx512", "a rotation", ".xprord 3 3 16", 0, ".xprord 3 3 17"),
    ("avx512", "a rotation's source", ".xprord 1 1 7", 1, ".xprord 1 3 7"),
    ("avx512", "the block's words shuffled another way", ".xshufps 4 8 9 136", 0, ".xshufps 4 8 9 137"),
    ("avx512", "a blend's mask", ".xpblendd 9 9 8 170", 0, ".xpblendd 9 9 8 169"),
    ("avx512", "the diagonal's turn", ".xpshufd 0 0 147", 0, ".xpshufd 0 0 57"),
    ("avx512", "the flags' byte not cut to a byte", ".movzx8 .rax (.reg .r8)", 0, ".nop"),
    ("avx512", "the length from the counter", ".xmovq 4 .rdx", 0, ".xmovq 4 .rcx"),
    ("avx512", "a round fewer", ".mov 8 (.reg .rax) (.imm 0x7)", 0, ".mov 8 (.reg .rax) (.imm 0x6)"),
    ("avx512", "no feed-forward of the second half", ".xpxor 1 1 3", 0, ".nop"),
    ("avx512", "the halves stored the other way round", ".xstoreu .rdi 0x10 1", 0, ".xstoreu .rdi 0x10 0"),
    ("avx512", "a store past the chaining value", ".xstoreu .rdi 0x10 1", 0, ".xstoreu .rdi 0x20 1"),
    ("sse41", "a rotation by shifts", ".xpslld 1 1 20", 0, ".xpslld 1 1 21"),
    ("sse41", "the two byte rotations exchanged", ".xpshufb 3 3 15", 0, ".xpshufb 3 3 14"),
    ("sse41", "a blend's mask", ".xpblendw 9 9 8 204", 0, ".xpblendw 9 9 8 192"),
    ("sse41", "a blend that splits a word", ".xpblendw 9 9 8 204", 0, ".xpblendw 9 9 8 200"),
    ("sse41", "the flags not shifted up", ".shl64 .r8 32", 0, ".nop"),
    ("sse41", "a word of the IV", ".xconst 2 0x6A09E667 0xBB67AE85 0x3C6EF372 0xA54FF53A", 0, ".xconst 2 0x6A09E667 0xBB67AE85 0x3C6EF372 0xA54FF53B"),
    ("sse41", "a read past the block", ".xloadu 7 .rsi 0x30", 0, ".xloadu 7 .rsi 0x40"),
    ("sse41", "a round more", ".mov 8 (.reg .rax) (.imm 0x7)", 0, ".mov 8 (.reg .rax) (.imm 0x8)"),
]


class Kone(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.dir = tempfile.mkdtemp(prefix="kone-")
        cls.rows = {}
        for name, source in SOURCES.items():
            assemble(os.path.join(ROOT, "c", source), os.path.join(cls.dir, name + ".o"))
            cls.rows[name] = kone.load(os.path.join(cls.dir, name + ".o"), name)

    @classmethod
    def tearDownClass(cls):
        shutil.rmtree(cls.dir)

    def test_each_kernel_meets_its_contract(self):
        self.assertEqual({name: kone.check(rows, name) for name, rows in self.rows.items()}, {"avx512": 362, "sse41": 467})

    def test_changed_kernels_do_not(self):
        for name, what, old, which, new in MUTANTS:
            rows = list(self.rows[name])
            hits = [k for k, r in enumerate(rows) if r[2] == old]
            self.assertGreater(len(hits), which, f"{name}: no instruction `{old}` number {which}")
            rows[hits[which]] = (rows[hits[which]][0], rows[hits[which]][1], new)
            with self.assertRaises(kcheck.Fail, msg=f"{name}: {what}"):
                kone.check(rows, name)

    def test_a_changed_contract_refuses_the_true_kernel(self):
        import kspec, ode
        true = kspec.SPEC
        text = ode.source()
        head = {"avx512": "contract blake3_servil_compress_in_place_avx512(h: cv, m: block, length: low byte, t: counter, flags: low byte) {\n    ensures h = compress(h, m, t, length, flags)",
                "sse41": "contract blake3_servil_compress_in_place_sse41(h: cv, m: block, length: word, t: counter, flags: low word) {\n    ensures h = compress(h, m, t, length, flags)"}
        try:
            for name, old, new in (("avx512", "compress(h, m, t, length, flags)", "compress(h, m, t, flags, length)"),
                                   ("avx512", "compress(h, m, t, length, flags)", "compress(h, m, t + 1, length, flags)"),
                                   ("avx512", "length: low byte", "length: word"),
                                   ("sse41", "compress(h, m, t, length, flags)", "compress(m[0..8], m, t, length, flags)"),
                                   ("sse41", "length: word", "length: low byte"),
                                   ("sse41", "flags: low word", "flags: low byte")):
                self.assertEqual(text.count(head[name]), 1)
                kspec.SPEC = ode.Spec(text.replace(head[name], head[name].replace(old, new)))
                kone.CONTRACTS = kone.contracts()
                with self.assertRaises(kcheck.Fail, msg=f"{name}: {new}"):
                    kone.check(self.rows[name], name)
        finally:
            kspec.SPEC = true
            kone.CONTRACTS = kone.contracts()

    def test_a_kernel_holds_only_what_its_contract_says_it_needs(self):
        # `needs avx512`, `needs sse41` in a contract: read from the kernel's bytes, by how each instruction is encoded
        import kdecode, kspec, ode
        self.assertEqual(kdecode.features(os.path.join(self.dir, "avx512.o"), "blake3_servil_compress_in_place_avx512"), {"avx", "avx512"})
        self.assertEqual(kdecode.features(os.path.join(self.dir, "sse41.o"), "blake3_servil_compress_in_place_sse41"), {"sse41"})
        true, text = kspec.SPEC, ode.source()
        try:
            for name, old, new in (("avx512", "ensures h = compress(h, m, t, length, flags)\n    stack 0\n    needs avx512\n", "ensures h = compress(h, m, t, length, flags)\n    stack 0\n"),
                                   ("avx512", "ensures h = compress(h, m, t, length, flags)\n    stack 0\n    needs avx512\n", "ensures h = compress(h, m, t, length, flags)\n    stack 0\n    needs sse41\n"),
                                   ("sse41", "ensures h = compress(h, m, t, length, flags)\n    stack 0\n    needs sse41\n", "ensures h = compress(h, m, t, length, flags)\n    stack 0\n")):
                self.assertEqual(text.count(old), 1, old)
                kspec.SPEC = ode.Spec(text.replace(old, new))
                with self.assertRaises(kcheck.Fail, msg=f"{name}: {new}"):
                    kone.load(os.path.join(self.dir, name + ".o"), name)
        finally:
            kspec.SPEC = true
        kone.load(os.path.join(self.dir, "sse41.o"), "sse41")

    def test_a_kernel_does_not_meet_the_others_contract(self):
        # the SSE4.1 kernel reads all of EDX: against "the low byte of RDX" it is refused, and the other way round
        with self.assertRaises(kcheck.Fail):
            kone.check(self.rows["sse41"], "avx512")
        with self.assertRaises(kcheck.Fail):
            kone.check(self.rows["avx512"], "sse41")


if __name__ == "__main__":
    unittest.main()
