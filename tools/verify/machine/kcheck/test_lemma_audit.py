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
        self.assertIn("lz4: 129 changed lemmas: 126 refused, 3 shown and so on every use tried, 0 shown and not judged, 0 SHOWN AND FALSE", out)

    def test_a_verifier_made_wrong_is_found_out(self):
        code, out = run("common", "lz4", "--control", "7")
        self.assertEqual(code, 0, out[-2000:])
        self.assertIn("SHOWN, and FALSE", out)
        self.assertIn("the number that decreases is", out)              # a definition "shown" to end that does not get smaller
        self.assertIn("ensures (its clause", out)                       # and something "shown" of a value that is not so

    def test_the_judge_on_numbers_sees_a_false_lemma(self):
        """The judge alone, with no verifier asked: lemmas that are not so, of a definition and of a sequence."""
        import ode, random
        spec_text, lemmas = lemma_audit.read("programs/lz4/lz4.spec"), lemma_audit.read("programs/lz4/lz4.lemmas")
        def judged(old, new):
            self.assertEqual(lemmas.count(old), 1, old)
            s = ode.with_proof(spec_text, lemmas.replace(old, new))
            rng = random.Random(3)
            uses = lemma_audit.noted(s, lemma_audit.runs("lz4", s, rng, 60))
            bad, u, n = lemma_audit.judge(s, uses)
            if not bad: bad, u, n = lemma_audit.judge_places(s, lemma_audit.places(s, rng, 60))
            return bad
        self.assertIsNone(judged("ensures len(result) == len(out) + k", "ensures len(result) == len(out) + k"))
        self.assertIn("does not hold of place", judged("ensures len(result) == len(out) + k", "ensures len(result) == len(out) + k + 1"))
        # (without `requires offset >= 1` the lemma is still so on numbers: place 1 from offset 0 has no value, and a
        # lemma speaks of values. The verifier refuses it all the same: it cannot follow the opening.)
        self.assertIsNone(judged("    requires offset >= 1\n", ""))
        self.assertIn("ensures", judged("ensures result.next >= at + 1", "ensures result.next >= at + 2"))
        self.assertIn("the number that decreases", judged("    ensures result.next >= at + 1\n    decreases len(bytes) - at\n", "    ensures result.next >= at + 1\n    decreases len(bytes)\n"))

    def test_a_lemma_that_requires_the_impossible_counts_for_nothing(self):
        """Such a lemma is shown, of nothing. The audit asks that "its definitions come to an end" is then not
        said; and it finds out the way that line was made until November 16, 2026 (a count of lemmas with a
        number that decreases), which said it."""
        import kbyte
        lines = []
        self.assertEqual(lemma_audit.audit("common", 40, 1, out=lines.append), 0)
        self.assertEqual(sum(1 for l in lines if "made to require the impossible" in l and '"comes to an end" is not said with it' in l), 3, lines)
        honest = lemma_audit.said_to_end
        try:
            lemma_audit.said_to_end = lambda spec, text: not kbyte.ends(spec)[1]          # the line as it was made before
            lines = []
            self.assertGreaterEqual(lemma_audit.audit("common", 40, 1, out=lines.append), 3)
            self.assertTrue(any("HOLE" in l and "STILL SAID" in l for l in lines), lines)
        finally: lemma_audit.said_to_end = honest

    def test_a_kind_that_is_not_so_is_found_out(self):
        """The judge on numbers looks at the kind of what a definition gave; and the way lemmas were shown until
        November 16, 2026 (the kind taken as said where nothing else was ensured) is reported by the audit."""
        import kbyte
        lines = []
        self.assertEqual(lemma_audit.audit("common", 40, 1, out=lines.append), 0)
        with open(os.path.join(HERE, "kbyte.py")) as f: source = f.read()
        self.assertIn("it says the definition's value is a", source)
        # the same audit with a verifier that does not look at the kind: made here by taking that one check out
        import types
        old = types.ModuleType("kbyte_before"); old.__file__ = os.path.join(HERE, "kbyte.py")
        a = source.index("            # the kind the lemma says the value is of is something said too"); b = source.index("            env = dict(env0); env[\"result\"] = v", a)
        exec(compile(source[:a] + source[b:], "kbyte_before", "exec"), old.__dict__)
        prove = kbyte.prove_lemmas
        try:
            kbyte.prove_lemmas = old.prove_lemmas
            lines = []
            self.assertGreaterEqual(lemma_audit.audit("common", 40, 1, out=lines.append), 2)
            self.assertTrue(any("HOLE" in l and "the lemma says the value is a list, and the definition gave int" in l for l in lines), lines)
        finally: kbyte.prove_lemmas = prove

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
