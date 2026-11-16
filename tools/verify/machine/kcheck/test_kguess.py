#!/usr/bin/env python3
"""Tests of kguess.py (a prover: trusted for nothing): the numbers that decrease are found again from the
specifications, and what it prints is shown by the verifier."""
import os, subprocess, sys, unittest
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import kbyte, kguess, lemma_audit, ode


class Guess(unittest.TestCase):
    def test_from_the_specification_alone(self):
        for program, want in (("utf8", {"points": ["requires at <= len(bytes)", "decreases len(bytes) - at"]}), ("varint", {"varint": ["decreases v"]}),
                              ("common", {"alike": ["requires at <= len(a)", "requires len(a) <= len(b)", "decreases len(a) - at"]})):
            spec_text = lemma_audit.read(lemma_audit.PROGRAMS[program][0])
            text, left, tries = kguess.guess(spec_text)
            self.assertEqual(left, [], program)
            self.assertEqual({n: cs for n, (h, cs) in kguess.split_lemmas(text)[0].items()}, want)
            spec = ode.with_proof(spec_text, text); kbyte.prove_lemmas(spec)            # what it found is shown
            self.assertEqual(kbyte.ends(spec)[1], [])

    def test_blake3s_tree(self):
        spec_text = lemma_audit.read("blake3.spec")
        text, left, tries = kguess.guess(spec_text)
        self.assertEqual(left, [])
        found = kguess.split_lemmas(text)[0]
        self.assertEqual(found["subtree"][1], ["decreases 2 * len(bytes)"])
        self.assertEqual(found["children"][1], ["requires len(bytes) > 1024", "decreases 2 * len(bytes) - 1"])
        self.assertEqual(sorted(n for n in found if not found[n][1]), ["chunk_node", "compress", "node_value"])     # words: passed on

    def test_with_the_lemmas_that_say_other_things_kept(self):
        r = subprocess.run([sys.executable, os.path.join(HERE, "kguess.py"), "--again"], capture_output=True, text=True, timeout=600)
        self.assertEqual(r.returncode, 0, r.stdout[-1500:] + r.stderr[-500:])
        self.assertIn("kguess: the number that decreases found for 8 of 8 rings", r.stdout)

    def test_none_where_there_is_none(self):
        text, left, tries = kguess.guess("def f(a, n) { if n == len(a) then n else f(a, n) }\n")          # it goes on for ever
        self.assertEqual(left, [["f"]])
        text, left, tries = kguess.guess("def f(a, n) { if n == 0 then 0 else f(a, n + 1) }\n")
        self.assertEqual(left, [["f"]])
        text, left, tries = kguess.guess("def f(a, n) { if n == 0 then 0 else f(a, n - 1) }\n")
        self.assertEqual(left, []); self.assertIn("decreases n", text)


if __name__ == "__main__":
    unittest.main()
