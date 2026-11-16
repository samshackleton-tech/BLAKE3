#!/usr/bin/env python3
"""Tests of lemma_audit.py: it finds nothing false among what the verifier shows of changed lemmas (two small
programs here; all six: `python3 lemma_audit.py`, five minutes), and it finds out a verifier made wrong."""
import os, subprocess, sys, unittest
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import lemma_audit


def run(*args):
    r = subprocess.run([sys.executable, os.path.join(HERE, "lemma_audit.py"), *args], capture_output=True, text=True, timeout=600)
    return r.returncode, r.stdout + r.stderr


class LemmaAudit(unittest.TestCase):
    def test_no_changed_lemma_is_shown_and_false(self):
        code, out = run("common", "varint", "lz4")
        self.assertEqual(code, 0, out[-2000:])
        self.assertIn("lemma_audit: no changed lemma is shown and false", out)
        self.assertNotIn("CONTROL FAILED", out); self.assertNotIn("HOLE", out)
        self.assertIn("lz4: 101 changed lemmas: 98 refused, 3 shown and so on every use tried, 0 shown and not judged, 0 SHOWN AND FALSE", out)

    def test_a_verifier_made_wrong_is_found_out(self):
        code, out = run("common", "lz4", "--control", "7")
        self.assertEqual(code, 0, out[-2000:])
        self.assertIn("SHOWN, and FALSE", out)
        self.assertIn("the number that decreases is", out)              # a definition "shown" to end that does not get smaller
        self.assertIn("ensures (its clause", out)                       # and something "shown" of a value that is not so

    def test_the_changed_copies(self):
        text = "lemma f(a: bytes, n: number): number {\n    requires n <= len(a)\n    ensures result >= n + 1\n    decreases len(a) - n\n}\n"
        whats = [w for w, _ in lemma_audit.changed(text)]
        for want in ("f: `requires n <= len(a)`: left out", "f: `ensures result >= n + 1`: 1 made 2", "f: `ensures result >= n + 1`: 1 made 0", "f: `ensures result >= n + 1`: >= made <",
                     "f: `ensures result >= n + 1`: + made -", "f: `decreases len(a) - n`: n made a", "f: `decreases len(a) - n`: n made 0", "f: `requires n <= len(a)`: a made n"):
            self.assertIn(want, whats)
        for what, changed in lemma_audit.changed(text):
            self.assertNotEqual(changed, text, what)
            self.assertEqual(changed.count("lemma f("), 1)
        spec = "def f(a, n) { if n == len(a) then n + 1 else f(a, n + 1) }   // a comment with 7 in it\ndef g(x) { x + 2 }\n// ====\ncontract c() { stack 8 }\n"
        whats = [w for w, _ in lemma_audit.changed_spec(spec, {"f"})]
        self.assertIn("the specification's f, line 1: == made !=", whats); self.assertIn("the specification's f, line 1: 1 made 2", whats)
        self.assertFalse([w for w in whats if "7 made" in w or "'s g" in w or "8 made" in w])


if __name__ == "__main__":
    unittest.main()
