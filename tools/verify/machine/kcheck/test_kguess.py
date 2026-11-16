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

    def test_lz4s_lemmas_from_nothing_and_the_binaries_shown_by_them(self):
        """The four lemmas of the unbent LZ4, found from lz4.spec alone: the clauses of the ones written by hand;
        and the decoder, both encoders and the frame's opener are shown with what was found (and the decoder
        is not, with none)."""
        import test_kbyte as T
        spec_text = lemma_audit.read("programs/lz4/lz4.spec")
        text, left, tries = kguess.whole(spec_text)
        self.assertEqual(left, [])
        found, sequences = kguess.split_lemmas(text)
        self.assertEqual(found["counted"][1], ["decreases len(bytes) - at", "ensures result.value >= sum", "ensures result.next >= at + 1"])
        self.assertEqual(found["sequences"][1], ["decreases len(bytes) - at", "ensures len(result) >= len(out)"])
        self.assertEqual(found["match"][1], ["decreases len(bytes) - at", "ensures len(result) >= len(out)"])
        self.assertIn("lemma copies(out: list, offset: number)[k]: list {\n    requires offset >= 1\n    requires offset <= len(out)\n    ensures len(result) == len(out) + k\n}", sequences)
        for name in ("lz4_decode", "lz4_store", "lz4_pack"):
            p = T.Program("lz4", name, "ode_" + name)
            self.assertEqual(p.verdict(spec=spec_text + "\n" + text), "accepted", name)
        p = T.Program("lz4", "lz4_decode", "ode_lz4_decode")
        self.assertTrue(p.verdict(spec=spec_text).startswith("refused"))
        frame = lemma_audit.read("programs/frame/frame.spec")
        text, left, tries = kguess.whole(frame)
        p = T.Program("frame", "unframe", "ode_unframe")
        self.assertEqual(p.verdict(spec=frame + "\n" + lemma_audit.read("programs/frame/unframe.inner") + "\n" + text), "accepted")

    def test_the_others_from_nothing(self):
        import test_kbyte as T
        for folder, name in (("utf8", "utf8"), ("varint", "varint"), ("common", "common")):
            spec_text = lemma_audit.read(f"programs/{folder}/{folder}.spec")
            text, left, tries = kguess.whole(spec_text)
            self.assertEqual(left, [], folder)
            p = T.Program(folder, name, "ode_" + name)
            self.assertEqual(p.verdict(spec=spec_text + "\n" + text), "accepted", folder)
            self.assertEqual(kbyte.ends(ode.with_proof(spec_text, text))[1], [])

    def test_none_where_there_is_none(self):
        text, left, tries = kguess.guess("def f(a, n) { if n == len(a) then n else f(a, n) }\n")          # it goes on for ever
        self.assertEqual(left, [["f"]])
        text, left, tries = kguess.guess("def f(a, n) { if n == 0 then 0 else f(a, n + 1) }\n")
        self.assertEqual(left, [["f"]])
        text, left, tries = kguess.guess("def f(a, n) { if n == 0 then 0 else f(a, n - 1) }\n")
        self.assertEqual(left, []); self.assertIn("decreases n", text)


if __name__ == "__main__":
    unittest.main()
