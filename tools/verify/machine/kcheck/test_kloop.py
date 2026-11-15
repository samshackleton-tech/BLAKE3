#!/usr/bin/env python3
"""kloop on the library's wide kernels: a proof is found and checked for each, and wrong kernels and wrong
proofs are refused.

    python3 test_kloop.py"""
import copy, os, shutil, subprocess, sys, tempfile, unittest

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", "..", "..", ".."))
sys.path.insert(0, HERE)
import kcheck, kloop
from test_kcheck import assemble

# changes of the loop over blocks and of the flags' bytes, which a kernel for one block count does not show
LOOP_MUTANTS = [
    ("the end flag a block early", ".cmp 64 (.reg .r13) (.imm 0x1)", ".cmp 64 (.reg .r13) (.imm 0x2)"),
    ("the start byte read from the end byte", ".shr32 .rdx 8", ".shr32 .rdx 16"),
    ("the end byte read from the start byte", ".shr32 .rcx 16", ".shr32 .rcx 8"),
    ("the last length read from the end byte", ".shr32 .rdx 24", ".shr32 .rdx 16"),
    ("the start flag on every block but the first", ".jne 0x10846", ".je 0x10846"),
    ("every second block skipped", ".add 64 (.reg .r14) (.imm 0x40)", ".add 64 (.reg .r14) (.imm 0x80)"),
    ("the count of blocks left never falls", ".dec64 .r13", ".nop"),
    ("a block length of 65", ".mov 32 (.reg .rdx) (.imm 0x40)", ".mov 32 (.reg .rdx) (.imm 0x41)"),
    ("the loop entered past its first instruction", ".jne 0x10133", ".jne 0x1013B"),
    ("the loop left a block early", ".jne 0x10133", ".nop"),
]


class Kloop(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.dir = tempfile.mkdtemp(prefix="kloop-")
        cls.obj = os.path.join(cls.dir, "k.o")
        assemble(os.path.join(ROOT, "c", "blake3_avx512_32.S"), cls.obj)
        cls.k32 = kloop.load(cls.obj, "k32")
        cls.proof = kloop.find(*cls.k32[:2], "k32", cls.k32[2])

    @classmethod
    def tearDownClass(cls):
        shutil.rmtree(cls.dir)

    def test_a_proof_is_found_and_checked_for_each_kernel(self):
        for name, place in (("k32", 0x133), ("p32", 0x133), ("p16", 0x91)):
            rows, data, entry = kloop.load(self.obj, name)
            proof = kloop.find(rows, data, name, entry)
            self.assertEqual(proof["place"], place, name)
            done = kloop.check(rows, data, name, proof, entry)
            self.assertEqual(done["paths"], {"head": 1, "return": 1}, name)

    def changed(self, old, new):
        rows, data, entry = self.k32
        hits = [k for k, r in enumerate(rows) if r[2] == old]
        self.assertTrue(hits, f"no instruction `{old}`")
        rows = list(rows); rows[hits[0]] = (rows[hits[0]][0], rows[hits[0]][1], new)
        return rows, data, entry

    def test_no_proof_is_found_for_a_changed_kernel_and_the_true_proof_is_refused_on_it(self):
        for label, old, new in LOOP_MUTANTS + kcheck.MUTANTS:
            rows, data, entry = self.changed(old, new)
            with self.assertRaises(kcheck.Fail, msg="the prover on: " + label):
                kloop.find(rows, data, "k32", entry)
            with self.assertRaises(kcheck.Fail, msg="the checker with the true proof on: " + label):
                kloop.check(rows, data, "k32", self.proof, entry)
        rows, data, entry = self.k32
        bad = bytearray(data); bad[0xC0 + 64 + 4] ^= 0x40           # one entry of the message schedule
        with self.assertRaises(kcheck.Fail):
            kloop.find(rows, bytes(bad), "k32", entry)

    def test_a_wrong_proof_is_refused_on_the_true_kernel(self):
        rows, data, entry = self.k32
        def wrong(change):
            proof = copy.deepcopy(self.proof); change(proof); return proof
        def swap(p): p["vectors"]["0"], p["vectors"]["1"] = p["vectors"]["1"], p["vectors"]["0"]
        for label, change in (("the place moved", lambda p: p.update(place=p["place"] + 8)),
                              ("the block offset said to move by 128", lambda p: p["registers"]["r14"]["lin"].update(b=128)),
                              ("the count said not to fall", lambda p: p["registers"]["r13"]["lin"].update(b=0)),
                              ("two words of the state exchanged", swap),
                              ("a state register not named", lambda p: p["vectors"].pop("5")),
                              ("a counter's cell not named", lambda p: p["frame"].pop("2048")),
                              ("the inputs' table not named", lambda p: p["registers"].pop("r12"))):
            with self.assertRaises(kcheck.Fail, msg=label):
                kloop.check(rows, data, "k32", wrong(change), entry)

    def test_a_changed_contract_refuses_the_true_kernel(self):
        # the kernels' contracts are text in blake3.spec
        import kspec, ode
        true = kspec.SPEC
        text = ode.source()
        k32 = "contract blake3_servil_avx512_k32(inputs: 32 inputs, n: number, key: cv, t: counter, packed: bytes flags start end length, out: 32 cvs) {\n    requires n >= 1\n    ensures out[i] = chunk(key, t + i, flags, start, end, length, n, inputs[i]) for i in 0..32"
        self.assertEqual(text.count(k32), 1)
        rows, data, entry = self.k32
        try:
            for old, new in (("t + i", "t"), ("t + i", "t + i + 1"), ("flags, start, end, length", "flags, end, start, length"), ("inputs[i])", "inputs[31 - i])"),
                             ("requires n >= 1", "requires n >= 0"), ("for i in 0..32", "for i in 0..16"), ("bytes flags start end length", "bytes start flags end length"),
                             ("chunk(key,", "chunk(key[0..4] ++ key[0..4],"), ("32 inputs", "16 inputs")):
                self.assertEqual(k32.count(old), 1, old)
                kspec.SPEC = ode.Spec(text.replace(k32, k32.replace(old, new)))
                with self.assertRaises(kcheck.Fail, msg=new):
                    kloop.KERNELS = kloop.kernels()
                    kloop.find(rows, data, "k32", entry)
        finally:
            kspec.SPEC = true
            kloop.KERNELS = kloop.kernels()

    def test_the_other_entry_is_refused_with_this_ones_specification(self):
        rows, data, entry = self.k32
        p32 = kloop.load(self.obj, "p32")[2]
        with self.assertRaises(kcheck.Fail):
            kloop.find(rows, data, "k32", p32)           # the entry that does not count, the counting specification
        with self.assertRaises(kcheck.Fail):
            kloop.find(rows, data, "p32", entry)


if __name__ == "__main__":
    unittest.main()
