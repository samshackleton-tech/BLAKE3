#!/usr/bin/env python3
"""blake3.ode, the specification that runs: it gives the official test vectors, and a changed one does not.

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
    ("a rotation", "(v[d] ^ v[a]) >>> 16", "(v[d] ^ v[a]) >>> 17"),
    ("a word of the round's first column", "v = g(v, 0, 4, 8, 12, m[0], m[1])", "v = g(v, 0, 4, 8, 12, m[1], m[0])"),
    ("the permutation", "[2, 6, 3, 10, 7, 0, 4, 13,", "[2, 6, 3, 10, 7, 0, 13, 4,"),
    ("a round fewer", "for r in 0..7 {", "for r in 0..6 {"),
    ("a constant of the IV", "0x6A09E667", "0x6A09E666"),
    ("the feed-forward", "[s[i] ^ s[i + 8] for i in 0..8]", "[s[i] for i in 0..8]"),
    ("the start flag on every block", "(if b == 0 then start else 0)", "start"),
    ("the end flag on no block", "(if b == n - 1 then end else 0))", "0)"),
    ("every block 64 bytes long", "if b == n - 1 then length else 64,", "64,"),
    ("no PARENT flag", "compress(key, left ++ right, counter(0), 64, flags | PARENT)", "compress(key, left ++ right, counter(0), 64, flags)"),
    ("the children exchanged", "compress(key, left ++ right,", "compress(key, right ++ left,"),
    ("the merge leaves one value more", "while len(s) > target", "while len(s) > target + 1"),
    ("the stack merged to the count's one bits, a chunk late", "ones(i + 1)", "ones(i)"),
    ("no ROOT flag on the last parent", "parent(key, flags | ROOT, s[0], s[1])", "parent(key, flags, s[0], s[1])"),
    ("no ROOT flag on a single chunk", "CHUNK_END | ROOT, message)", "CHUNK_END, message)"),
    ("the chunk counter always 0", "chunk(key, counter(index),", "chunk(key, counter(0),"),
    ("the high word of the counter left out", "lo(t), hi(t),", "lo(t), lo(t),"),
    ("the keyed mode's flag", "KEYED_HASH          = 16", "KEYED_HASH          = 0"),
]


class Ode(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        with open(os.path.join(HERE, "blake3.ode")) as f: cls.text = f.read()

    def test_the_specification_gives_the_official_vectors(self):
        self.assertEqual(ode.vectors(ode.Spec(self.text), VECTORS, UP_TO), 105 if UP_TO is None else 96)

    def test_a_changed_specification_does_not(self):
        for what, old, new in CHANGES:
            self.assertEqual(self.text.count(old), 1, f"`{old}` is not once in the text")
            with self.assertRaises(ode.Err, msg=what):
                ode.vectors(ode.Spec(self.text.replace(old, new)), VECTORS, 3072)

    def test_what_is_not_the_language_is_refused(self):
        for text in ("fn f(x) { x @ 1 }", "fn f(x) { x + }", "machine m(a) on s { turn { s = a } }", "const = 3", "fn f(x) { [x for i in 0..2 }"):
            with self.assertRaises(ode.Err, msg=text):
                ode.Spec(text)
        spec = ode.Spec("fn f(x) { x + nothing }\nfn g(x) { word(1) * 2 }\nfn h(x) { [1, 2][x] }")
        for name in ("f", "g"):
            with self.assertRaises(ode.Err, msg=name):
                spec.call(ode.Numbers(), name, 1)


if __name__ == "__main__":
    unittest.main()
