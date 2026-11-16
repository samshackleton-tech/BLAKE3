#!/usr/bin/env python3
"""kfn on the hash written to be proved (hash.ode): each function meets its contract; changed code, a changed
contract and a changed specification are refused.

    python3 test_kfn.py

glue/pad.S, chunk_node.S, node_out.S, wide32.S, wide128.S, take.S, part32.S, subtree.S and hashr.S are hash.ode as the Ode compiler prints it
(copies: the compiler needs Lean); they are assembled here (clang where there is one, else cc)."""
import json, os, shutil, sys, tempfile, unittest

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import kcheck, kfn, kspec, ode
from test_kcheck import assemble

NAMES = ["pad", "chunk_node", "node_out", "wide32", "wide128", "take", "part32", "subtree", "hashr"]
FLIP = {".jae": ".jb", ".jb": ".jae", ".je": ".jne", ".jne": ".je"}

# (function, the text of blake3.spec, what it becomes): the function that met the text does not meet the change
TEXT = [
    ("pad", "then bytes[k] else 0 for k in 0..64", "then bytes[k] else 1 for k in 0..64"),
    ("pad", "ensures block = padded(src)\n    stack 48", "ensures block = padded(src)\n    stack 32"),
    ("chunk_node", "ensures nd = chunk_node(nd.h, t, flags, input)", "ensures nd = chunk_node(nd.h, t + 1, flags, input)"),
    ("chunk_node", "requires len <= 1024\n", "requires len <= 1025\n"),
    ("chunk_node", "length: len(rest), flags:", "length: 64, flags:"),
    ("chunk_node", "(if n == 1 then CHUNK_START else 0) | CHUNK_END}", "(if n == 1 then CHUNK_START else 0)}"),
    ("chunk_node", "the least number n in 1..17 with 64 * n >= len(bytes)", "the least number n in 1..17 with 64 * n > len(bytes)"),
    ("chunk_node", "length: number at 104 below 65", "length: number at 104 below 64"),
    ("node_out", "ensures out = node_value(nd, root)", "ensures out = node_value(nd, 0)"),
    ("node_out", "counter(node.counter), node.length, node.flags | root)", "counter(node.counter), 64, node.flags | root)"),
    ("node_out", "counter: number at 96, length: number at 104", "counter: number at 104, length: number at 96"),
    ("subtree", "ensures out = subtree(kf.key, kf.flags, t, input)\n    decreases len\n    stack 16896", "ensures out = subtree(kf.key, kf.flags, t + 1, input)\n    decreases len\n    stack 16896"),
    ("subtree", "t: number, plat: any) {\n    requires no_overlap(out, input, kf)\n    requires len >= 1\n    requires 1024 * t + len <= 18446744073709551615", "t: number, plat: any) {\n    requires no_overlap(out, input, kf)\n    requires len >= 1\n    requires t <= 18446744073709551615"),         # the chunks' numbers may then pass 64 bits
    ("subtree", "stack 16896 + 384 * bits((len - 1) / 1024)", "stack 16896 + 320 * bits((len - 1) / 1024)"),
    ("subtree", "stack 16896 + 384 * bits((len - 1) / 1024)\n    needs sse41\n    needs avx512 if plat == 5", "stack 16896 + 384 * bits((len - 1) / 1024)\n    needs sse41\n    needs avx512 if plat == 4"),
    ("subtree", "stack 16896 + 384 * bits((len - 1) / 1024)\n    needs sse41\n", "stack 16896 + 384 * bits((len - 1) / 1024)\n"),
    ("wide32", "requires 1024 * t + 32768 <= 18446744073709551615\n    ensures out = subtree(kf.key, kf.flags, t, input)\n    stack 8192", "requires 1024 * t + 32768 <= 18446744073709551615\n    ensures out = subtree(kf.key, kf.flags, t + 1, input)\n    stack 8192"),
    ("wide32", "stack 8192\n    needs avx512\n", "stack 8192\n"),
    ("wide32", "requires 1024 * t + 32768 <= 18446744073709551615\n    ensures out = subtree(kf.key, kf.flags, t, input)\n    stack 8192", "requires 1024 * t + 32768 <= 18446744073709551615\n    ensures out = subtree(kf.key, kf.flags, t, input)\n    stack 4096"),
    ("wide32", "contract b3l_wide32(out: cv, input: 32768 bytes,", "contract b3l_wide32(out: cv, input: 32767 bytes,"),
    ("wide32", "requires 1024 * t + 32768 <= 18446744073709551615", "requires t <= 18446744073709551615"),
    ("wide32", "ensures out[i] = chunk(key, t + i, flags, start, end, length, n, inputs[i]) for i in 0..32", "ensures out[i] = chunk(key, t, flags, start, end, length, n, inputs[i]) for i in 0..32"),
    ("wide32", "def left_chunks(bytes) { the greatest power of two k with 1024 * k < len(bytes) }", "def left_chunks(bytes) { the least power of two k with 1024 * k < len(bytes) }"),
    ("subtree", "the greatest power of two k with 1024 * k < len(bytes)", "the least power of two k with 1024 * k < len(bytes)"),
    ("subtree", "compress(key, children(key, flags, t, bytes), counter(0), 64, flags | PARENT)", "compress(key, children(key, flags, t, bytes), counter(0), 64, flags)"),
    ("subtree", "subtree(key, flags, t + k, bytes[1024 * k", "subtree(key, flags, t, bytes[1024 * k"),
    ("subtree", "if len(bytes) <= 1024 then node_value(chunk_node(key, t, flags, bytes), 0)", "if len(bytes) <= 1024 then node_value(chunk_node(key, t, flags, bytes), ROOT)"),
    ("hashr", "ensures out = bytes_of(hash_words(words(key), flags, input))", "ensures out = bytes_of(hash_words(words(key), 0, input))"),
    # the public contract is of bytes: the key's bytes as words and the hash's words as bytes, both said; neither left out
    ("hashr", "ensures out = bytes_of(hash_words(words(key), flags, input))", "ensures out = hash_words(words(key), flags, input)"),
    ("hashr", "ensures out = bytes_of(hash_words(words(key), flags, input))", "ensures out = bytes_of(hash_words(words(key), flags, input))\n    requires len(key) == 32"),
    ("hashr", "def iv_words() {", "def bytes_of(ws) { [word_bytes(ws[i / 4])[3 - i % 4] for i in 0..4 * len(ws)] }\ndef iv_words() {"),
    ("hashr", "def iv_words() {", "def words(bs) { [word(bs[4 * i + 3] + 256 * bs[4 * i + 2] + 65536 * bs[4 * i + 1] + 16777216 * bs[4 * i]) for i in 0..len(bs) / 4] }\ndef iv_words() {"),
    ("hashr", "contract b3l_hashr(out: 32 bytes, input: len bytes, len: number, key: 32 bytes,", "contract b3l_hashr(out: 32 bytes, input: len bytes, len: number, key: 31 bytes,"),
    ("hashr", "contract b3l_hashr(out: 32 bytes, input: len bytes, len: number, key: 32 bytes,", "contract b3l_hashr(out: 28 bytes, input: len bytes, len: number, key: 32 bytes,"),
    ("hashr", "counter(0), 64, flags | PARENT | ROOT)", "counter(0), 64, flags | PARENT)"),
    ("hashr", "node_value(chunk_node(key, 0, flags, message), ROOT)", "node_value(chunk_node(key, 0, flags, message), 0)"),
    ("hashr", "stack 18688 + 384 * bits(len / 1024)\n    needs sse41\n    needs avx512 if plat == 5", "stack 18688 + 384 * bits(len / 1024)\n    needs sse41"),
    ("hashr", "stack 18688 + 384 * bits(len / 1024)\n    needs sse41\n", "stack 18688 + 384 * bits(len / 1024)\n"),
    ("hashr", "stack 18688 + 384 * bits(len / 1024)", "stack 9216 + 384 * bits(len / 1024)"),
    ("wide128", "requires 1024 * t + 131072 <= 18446744073709551615\n    ensures out = subtree(kf.key, kf.flags, t, input)\n    stack 16384", "requires 1024 * t + 131072 <= 18446744073709551615\n    ensures out = subtree(kf.key, kf.flags, t + 1, input)\n    stack 16384"),
    ("wide128", "requires 1024 * t + 131072 <= 18446744073709551615\n    ensures out = subtree(kf.key, kf.flags, t, input)\n    stack 16384", "requires 1024 * t + 131072 <= 18446744073709551615\n    ensures out = subtree(kf.key, kf.flags, t, input)\n    stack 8192"),
    ("wide128", "contract b3l_wide128(out: cv, input: 131072 bytes,", "contract b3l_wide128(out: cv, input: 131071 bytes,"),
    ("wide128", "compress(key, children(key, flags, t, bytes), counter(0), 64, flags | PARENT)", "compress(key, children(key, flags, t, bytes), counter(0), 64, flags)"),
    ("subtree", "    requires no_overlap(out, input, kf)\n    requires len >= 1\n    requires 1024 * t", "    requires len >= 1\n    requires 1024 * t"),       # the caller is asked for what the check assumes
    ("take", "requires no_overlap(out, input, kf, cvs)", "requires no_overlap(out, input, kf)"),
    ("subtree", "    decreases len\n    stack 16896", "    stack 16896"),                           # it calls itself: on what that is less?
    ("take", "    decreases len\n    stack 640", "    decreases t\n    stack 640"),
    # an array with a type: what each value at cvs is
    ("take", "requires cvs[i] == node_value(chunk_node(kf.key, t + i, kf.flags, input[1024 * i .. 1024 * i + 1024]), 0) for i in 0..len / 1024", "requires cvs[i] == node_value(chunk_node(kf.key, t + i + 1, kf.flags, input[1024 * i .. 1024 * i + 1024]), 0) for i in 0..len / 1024"),
    ("take", "requires cvs[i] == node_value(chunk_node(kf.key, t + i, kf.flags, input[1024 * i .. 1024 * i + 1024]), 0) for i in 0..len / 1024", "requires cvs[i] == node_value(chunk_node(kf.key, t + i, kf.flags, input[1024 * i .. 1024 * i + 1024]), 0) for i in 0..len / 1024 - 1"),
    ("take", "requires cvs[i] == node_value(chunk_node(kf.key, t + i, kf.flags, input[1024 * i .. 1024 * i + 1024]), 0) for i in 0..len / 1024", "requires cvs[i] == node_value(chunk_node(kf.key, t + i, kf.flags, input[1024 * i .. 1024 * i + 1023]), 0) for i in 0..len / 1024"),
    ("part32", "requires cvs[i] == node_value(chunk_node(kf.key, t + i, kf.flags, input[1024 * i .. 1024 * i + 1024]), 0) for i in 0..len / 1024", "requires cvs[i] == node_value(chunk_node(kf.key, t + i + 1, kf.flags, input[1024 * i .. 1024 * i + 1024]), 0) for i in 0..len / 1024"),
    ("part32", "requires cvs[i] == node_value(chunk_node(kf.key, t + i, kf.flags, input[1024 * i .. 1024 * i + 1024]), 0) for i in 0..len / 1024", "requires cvs[i] == node_value(chunk_node(kf.key, t + i, kf.flags, input[1024 * i .. 1024 * i + 1024]), 0) for i in 0..len / 1024 + 1"),
    ("part32", "stack 8192\n    needs sse41", "stack 4096\n    needs sse41"),
    ("hashr", "requires cvs[i] == node_value(chunk_node(kf.key, t + i, kf.flags, input[1024 * i .. 1024 * i + 1024]), 0) for i in 0..len / 1024", "requires cvs[i] == node_value(chunk_node(kf.key, t + i, kf.flags, input[1024 * i .. 1024 * i + 1024]), ROOT) for i in 0..len / 1024"),
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
        # every call left out, and every branch turned round (of wide128's thirty branches, which are fifteen
        # copies of one loop, the first four: the single-bit audit has them all)
        for name in NAMES:
            branches = 0
            for k, (a, nxt, ins) in enumerate(self.rows[name]):
                op = ins.split()[0]
                new = ".nop" if op == ".call" else FLIP[op] + ins[len(op):] if op in FLIP else None
                if new is None: continue
                if op in FLIP:
                    branches += 1
                    if name == "wide128" and branches > 4: continue
                rows = list(self.rows[name]); rows[k] = (a, nxt, new)
                with self.assertRaises(kcheck.Fail, msg=f"{name}: {ins} -> {new}"):
                    kfn.check(rows, name)

    def test_a_changed_contract_or_specification_is_refused(self):
        true = kspec.SPEC
        text = ode.source()
        try:
            for name, old, new in TEXT:
                self.assertEqual(text.count(old), 1, old)
                with self.assertRaises(kcheck.Fail, msg=f"{name}: {new}"):          # (a text the reader of specifications refuses is refused there)
                    kspec.SPEC = ode.Spec(text.replace(old, new)); kfn.CONTRACTS.clear()
                    kfn.check(self.rows[name], name)
        finally:
            kspec.SPEC = true; kfn.CONTRACTS.clear()

    def test_a_function_is_not_another(self):
        with self.assertRaises(kcheck.Fail): kfn.check(self.rows["subtree"], "hashr")
        with self.assertRaises(kcheck.Fail): kfn.check(self.rows["hashr"], "subtree")


if __name__ == "__main__":
    unittest.main()
