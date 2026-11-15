#!/usr/bin/env python3
"""blake3.spec, the specification: it gives the official test vectors, and a changed one does not.

    python3 test_ode.py                (inputs up to 8193 bytes: 96 vectors, about 3 s)
    ALL=1 python3 test_ode.py          (every length: 105 vectors, about 12 s)"""
import os, sys, unittest

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", "..", "..", ".."))
sys.path.insert(0, HERE)
import ode

VECTORS = os.path.join(ROOT, "test_vectors", "test_vectors.json")
UP_TO = None if os.environ.get("ALL") == "1" else 8193

# one change each of the specification's text: every one must be told from BLAKE3 by the vectors
CHANGES = [
    ("a rotation", "(v[d] ^ a1) >>> 16", "(v[d] ^ a1) >>> 17"),
    ("a word of the round's first column", "let c1 = g(v, 0, 4, 8, 12, m[0], m[1])", "let c1 = g(v, 0, 4, 8, 12, m[1], m[0])"),
    ("the permutation", "[2, 6, 3, 10, 7, 0, 4, 13,", "[2, 6, 3, 10, 7, 0, 13, 4,"),
    ("a round fewer", "[s[7][i] ^ s[7][i + 8] for i in 0..8]", "[s[6][i] ^ s[6][i + 8] for i in 0..8]"),
    ("a constant of the IV", "0x6A09E667", "0x6A09E666"),
    ("the feed-forward", "[s[7][i] ^ s[7][i + 8] for i in 0..8]", "[s[7][i] for i in 0..8]"),
    ("the start flag on every block", "(if b == 0 then start else 0)", "start"),
    ("no PARENT flag", "compress(key, children(key, flags, t, bytes), counter(0), 64, flags | PARENT)", "compress(key, children(key, flags, t, bytes), counter(0), 64, flags)"),
    ("the children exchanged", "subtree(key, flags, t, bytes[0 .. 1024 * k]) ++ subtree(key, flags, t + k, bytes[1024 * k .. len(bytes)])",
     "subtree(key, flags, t + k, bytes[1024 * k .. len(bytes)]) ++ subtree(key, flags, t, bytes[0 .. 1024 * k])"),
    ("a left part that may be the whole", "the greatest power of two k with 1024 * k < len(bytes)", "the greatest power of two k with 1024 * k <= len(bytes)"),
    ("the least power of two for the left part", "the greatest power of two k with 1024 * k < len(bytes)", "the least power of two k with 1024 * k < len(bytes)"),
    ("no ROOT flag on the last parent", "counter(0), 64, flags | PARENT | ROOT)", "counter(0), 64, flags | PARENT)"),
    ("no ROOT flag on a single chunk", "node_value(chunk_node(key, 0, flags, message), ROOT)", "node_value(chunk_node(key, 0, flags, message), 0)"),
    ("the right part's chunks numbered as the left's", "subtree(key, flags, t + k, bytes[1024 * k", "subtree(key, flags, t, bytes[1024 * k"),
    ("the high word of the counter left out", "lo(t), hi(t),", "lo(t), lo(t),"),
    ("the keyed mode's flag", "KEYED_HASH          = 16", "KEYED_HASH          = 0"),
    ("the last block's length always 64", "length: len(rest), flags:", "length: 64, flags:"),
    ("a short block read with ones after it", "then bytes[k] else 0 for k in 0..64", "then bytes[k] else 1 for k in 0..64"),
    ("a block more where the bytes fill the last", "with 64 * n >= len(bytes) }", "with 64 * n > len(bytes) }"),
    ("no end flag on a chunk", "(if n == 1 then CHUNK_START else 0) | CHUNK_END}", "(if n == 1 then CHUNK_START else 0)}"),
    ("the start flag on a chunk's last block always", "flags | (if n == 1 then CHUNK_START else 0) | CHUNK_END}", "flags | CHUNK_START | CHUNK_END}"),
]

# The sequence `chunk` takes an end flag and a last length that the hash's own definitions do not use (they
# compress a chunk's last block apart, as its node). The wide kernels' contracts do use them. A chunk's value
# both ways, on numbers: the node's, and the sequence over all the blocks with the end flag and the length.
SEQUENCE_CHANGES = [
    ("the end flag on no block", "(if b == n - 1 then end else 0))", "0)"),
    ("every block 64 bytes long", "if b == n - 1 then length else 64,", "64,"),
    ("the end flag on every block", "(if b == n - 1 then end else 0))", "end)"),
]


def both_ways(spec, n_bytes, t, flags):
    A = ode.Numbers()
    key = [ode.Word(0x01020304 * (i + 1) & 0xFFFFFFFF) for i in range(8)]
    data = [(7 * i + 3) % 251 for i in range(n_bytes)]
    node = spec.call(A, "node_value", spec.call(A, "chunk_node", key, t, flags, data), 0)
    n = max(1, (n_bytes + 63) // 64)
    blocks = [A.words((data[64 * b:64 * b + 64] + [0] * 64)[:64]) for b in range(n)]
    whole = spec.call(A, "chunk", key, A.counter(t), flags, 1, 2, n_bytes - 64 * (n - 1), n, blocks)
    return [w.v for w in node], [w.v for w in whole]


class Ode(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.text = ode.source()

    def test_the_specification_gives_the_official_vectors(self):
        self.assertEqual(ode.vectors(ode.Spec(self.text), VECTORS, UP_TO), 105 if UP_TO is None else 96)

    def test_a_changed_specification_does_not(self):
        for what, old, new in CHANGES:
            self.assertEqual(self.text.count(old), 1, f"`{old}` is not once in the text")
            with self.assertRaises(ode.Err, msg=what):
                ode.vectors(ode.Spec(self.text.replace(old, new)), VECTORS, 3072)

    def test_a_chunk_is_the_sequence_over_all_its_blocks(self):
        for n_bytes in (0, 1, 63, 64, 65, 128, 1000, 1023, 1024):
            a, b = both_ways(ode.Spec(self.text), n_bytes, 5, 16)
            self.assertEqual(a, b, n_bytes)
        for what, old, new in SEQUENCE_CHANGES:
            self.assertEqual(self.text.count(old), 1, f"`{old}` is not once in the text")
            changed = ode.Spec(self.text.replace(old, new))
            self.assertTrue(any(a != b for a, b in (both_ways(changed, n, 5, 16) for n in (1, 64, 65, 1000, 1024))), what)

    def test_what_is_not_the_language_is_refused(self):
        for text in ("def f(x) { x @ 1 }", "def f(x) { x + }", "machine m(a) on s { turn { s = a } }", "const = 3", "def f(x) { [x for i in 0..2 }",
                     "fn f(x) { x }", "def f(x) { var y = x\n y }", "def f(x) { let y = x\n let y = 2\n y }", "def f(x) { for i in 0..2 { x }\n x }",
                     "def f(x) { y = x\n y }", "def f(x) { return x }", "def f(x) { while x > 0 { x }\n x }",
                     "sequence s(a) { h[1] = a  h[b + 1] = h[b]  for b in 0..2 }", "sequence s(a) { h[0] = a  h[b + 1] = h  for b in 0..2 }"):
            with self.assertRaises(ode.Err, msg=text):
                ode.Spec(text)
        spec = ode.Spec("def f(x) { x + nothing }\ndef g(x) { word(1) * 2 }\ndef h(x) { [1, 2][x] }")
        for name in ("f", "g"):
            with self.assertRaises(ode.Err, msg=name):
                spec.call(ode.Numbers(), name, 1)


if __name__ == "__main__":
    unittest.main()
