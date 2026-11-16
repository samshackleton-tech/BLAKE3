#!/usr/bin/env python3
"""Tests of kplace.py (a prover: trusted for nothing): for three functions with one loop the proof is found from
the binary and the specification alone, the lemmas too (kguess.py), and the verifier shows each function by
what was found. And where its few shapes do not reach, it says so."""
import os, sys, unittest
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import kbyte, kcheck, kguess, kplace, ode
import test_kbyte as T


def from_nothing(folder, name):
    """(the lemmas found, the proof found or None, the rows, the specification with the lemmas found)."""
    p = T.Program(folder, name, "ode_" + name)
    spec_text = T.text(folder, folder + ".spec")
    lemmas, left, _ = kguess.whole(spec_text)
    spec = ode.with_proof(spec_text, lemmas) if lemmas else ode.Spec(spec_text)
    proof, tries = kplace.guess(p.rows, spec, p.symbol)
    return lemmas, proof, p.rows, spec, p.symbol


class Places(unittest.TestCase):
    def shown(self, rows, spec, symbol, proof):
        try: kbyte.check(rows, spec, symbol, proof); return True
        except (kcheck.Fail, ode.Err): return False

    def test_adler32(self):
        lemmas, proof, rows, spec, symbol = from_nothing("adler32", "adler32")
        self.assertEqual(lemmas, "")
        for line in ("name i = r14", "fact i <= len", "r12 = s1(input)[i]", "r13 = s2(input)[i]", "decreases len - i"): self.assertIn(line, proof)
        self.assertTrue(self.shown(rows, spec, symbol, proof))
        self.assertFalse(self.shown(rows, spec, symbol, ""))                                    # and not with nothing
        self.assertFalse(self.shown(rows, spec, symbol, proof.replace("s1(input)", "s2(input)", 1)))

    def test_the_common_start(self):
        lemmas, proof, rows, spec, symbol = from_nothing("common", "common")
        self.assertIn("decreases len(a) - at", lemmas)
        for line in ("name i = r13", "fact i <= n", "fact alike(a, b, i) == common(a, b)", "decreases n - i"): self.assertIn(line, proof)
        self.assertTrue(self.shown(rows, spec, symbol, proof))

    def test_utf8(self):
        """300 instructions; the count of code points, a state in the stack that is 0 at each turn, four things of
        which nothing is said."""
        lemmas, proof, rows, spec, symbol = from_nothing("utf8", "utf8")
        self.assertIn("decreases len(bytes) - at", lemmas)
        for line in ("name i = r12", "name count = r13", "fact count <= i", "fact points(input, i, count) == utf8(input)", "any r14, r15, stack[8], stack[0]", "decreases n - i"): self.assertIn(line, proof)
        self.assertTrue(self.shown(rows, spec, symbol, proof))
        self.assertFalse(self.shown(rows, spec, symbol, ""))

    def test_where_it_does_not_reach(self):
        lemmas, proof, rows, spec, symbol = from_nothing("inet", "inet")                        # pairs of bytes: `i % 2 == 0`, a sum bounded by the count
        self.assertIsNone(proof)
        p = T.Program("lz4", "lz4_store", "ode_lz4_store")                                      # two loops
        proof, tries = kplace.guess(p.rows, ode.Spec(p.spec), p.symbol)
        self.assertIsNone(proof)

    def test_the_loops_of_a_function(self):
        p = T.Program("common", "common", "ode_common")
        base = p.rows[0][0]
        self.assertEqual({t - base for t, _ in kplace.loops(p.rows)}, {0x25})
        self.assertEqual(kplace.written(p.rows, base + 0x25, base + 0x78), ["r13", "r14"])


if __name__ == "__main__":
    unittest.main()
