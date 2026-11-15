#!/usr/bin/env python3
"""kfn on the hash written to be proved (hash.ode): each function meets its contract; changed code, a changed
contract and a changed specification are refused.

    python3 test_kfn.py

glue/pad.S, chunk_node.S, node_out.S, subtree.S and hashr.S are hash.ode as the Ode compiler prints it
(copies: the compiler needs Lean); they are assembled here (clang where there is one, else cc)."""
import json, os, shutil, sys, tempfile, unittest

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import kcheck, kfn, kspec, ode
from test_kcheck import assemble

NAMES = ["pad", "chunk_node", "node_out", "subtree", "hashr"]
FLIP = {".jae": ".jb", ".jb": ".jae", ".je": ".jne", ".jne": ".je"}

# (function, the text of blake3.spec, what it becomes): the function that met the text does not meet the change
TEXT = [
    ("pad", "then bytes[k] else 0 for k in 0..64", "then bytes[k] else 1 for k in 0..64"),
    ("pad", "leaves block = padded(src)\n    stack 48", "leaves block = padded(src)\n    stack 32"),
    ("chunk_node", "leaves nd = chunk_node(nd.h, t, flags, input)", "leaves nd = chunk_node(nd.h, t + 1, flags, input)"),
    ("chunk_node", "asks len <= 1024\n", "asks len <= 1025\n"),
    ("chunk_node", "length: len(rest), flags:", "length: 64, flags:"),
    ("chunk_node", "(if n == 1 then CHUNK_START else 0) | CHUNK_END}", "(if n == 1 then CHUNK_START else 0)}"),
    ("chunk_node", "the least number n in 1..17 with 64 * n >= len(bytes)", "the least number n in 1..17 with 64 * n > len(bytes)"),
    ("chunk_node", "length: number at 104 below 65", "length: number at 104 below 64"),
    ("node_out", "leaves out = node_value(nd, root)", "leaves out = node_value(nd, 0)"),
    ("node_out", "counter(node.counter), node.length, node.flags | root)", "counter(node.counter), 64, node.flags | root)"),
    ("node_out", "counter: number at 96, length: number at 104", "counter: number at 104, length: number at 96"),
    ("subtree", "leaves out = subtree(kf.key, kf.flags, t, input)", "leaves out = subtree(kf.key, kf.flags, t + 1, input)"),
    ("subtree", "asks 1024 * t + len <= 18446744073709551615", "asks t <= 18446744073709551615"),         # the chunks' numbers may then pass 64 bits
    ("subtree", "stack 640 + 384 * bits((len - 1) / 1024)", "stack 640 + 320 * bits((len - 1) / 1024)"),
    ("subtree", "the greatest power of two k with 1024 * k < len(bytes)", "the least power of two k with 1024 * k < len(bytes)"),
    ("subtree", "compress(key, children(key, flags, t, bytes), counter(0), 64, flags | PARENT)", "compress(key, children(key, flags, t, bytes), counter(0), 64, flags)"),
    ("subtree", "subtree(key, flags, t + k, bytes[1024 * k", "subtree(key, flags, t, bytes[1024 * k"),
    ("subtree", "if len(bytes) <= 1024 then node_value(chunk_node(key, t, flags, bytes), 0)", "if len(bytes) <= 1024 then node_value(chunk_node(key, t, flags, bytes), ROOT)"),
    ("hashr", "leaves out = hash_words(key, flags, input)", "leaves out = hash_words(key, 0, input)"),
    ("hashr", "counter(0), 64, flags | PARENT | ROOT)", "counter(0), 64, flags | PARENT)"),
    ("hashr", "node_value(chunk_node(key, 0, flags, message), ROOT)", "node_value(chunk_node(key, 0, flags, message), 0)"),
    ("hashr", "stack 1024 + 384 * bits(len / 1024)\n    calls blake3_servil_compress_in_place_avx512 if plat == 5", "stack 1024 + 384 * bits(len / 1024)"),
]


class Kfn(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.tmp = tempfile.mkdtemp(prefix="kfn-")
        cls.rows = {}
        for name in NAMES:
            assemble(os.path.join(HERE, "glue", name + ".S"), os.path.join(cls.tmp, name + ".o"))
            cls.rows[name] = kfn.load(os.path.join(cls.tmp, name + ".o"), name)

    @classmethod
    def tearDownClass(cls): shutil.rmtree(cls.tmp)

    def test_each_function_meets_its_contract(self):
        for name in NAMES:
            done = kfn.check(self.rows[name], name)
            self.assertGreater(done["return"], 0)

    def test_changed_code_is_refused(self):
        # every call left out, and every branch turned round
        for name in NAMES:
            for k, (a, nxt, ins) in enumerate(self.rows[name]):
                op = ins.split()[0]
                new = ".nop" if op == ".call" else FLIP[op] + ins[len(op):] if op in FLIP else None
                if new is None: continue
                rows = list(self.rows[name]); rows[k] = (a, nxt, new)
                with self.assertRaises(kcheck.Fail, msg=f"{name}: {ins} -> {new}"):
                    kfn.check(rows, name)

    def test_a_changed_contract_or_specification_is_refused(self):
        true = kspec.SPEC
        text = ode.source()
        try:
            for name, old, new in TEXT:
                self.assertEqual(text.count(old), 1, old)
                kspec.SPEC = ode.Spec(text.replace(old, new)); kfn.CONTRACTS.clear()
                with self.assertRaises(kcheck.Fail, msg=f"{name}: {new}"):
                    kfn.check(self.rows[name], name)
        finally:
            kspec.SPEC = true; kfn.CONTRACTS.clear()

    def test_a_function_is_not_another(self):
        with self.assertRaises(kcheck.Fail): kfn.check(self.rows["subtree"], "hashr")
        with self.assertRaises(kcheck.Fail): kfn.check(self.rows["hashr"], "subtree")


if __name__ == "__main__":
    unittest.main()
