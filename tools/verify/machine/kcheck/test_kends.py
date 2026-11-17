#!/usr/bin/env python3
"""Tests of kends.py: "its definitions come to an end on everything the contract allows" is said only where
it is shown from the contract inward. A lemma comes with the proof, which is not trusted: one that requires
the impossible is shown (of nothing) and must not make the line say what is not so."""
import os, sys, unittest
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import kbyte, kcheck, kends, klin, ode


def read(*path):
    with open(os.path.join(HERE, *path)) as f: return f.read()


def ask(spec_text, lemmas, symbol):
    """"ends" | "lemmas refused" | the reason it is not shown. With no search (an empty table of proofs), as a
    verification of a shipped file asks."""
    try:
        klin.Facts.PROOFS = None
        spec = ode.with_proof(spec_text, lemmas) if lemmas else ode.Spec(spec_text)
        try: kbyte.prove_lemmas(spec)
        except (kcheck.Fail, ode.Err): return "lemmas refused"
        klin.Facts.PROOFS = {}
        again, why = kends.ends_for(spec, symbol)
        return "ends" if why is None else why
    finally: klin.Facts.PROOFS = None


class Ends(unittest.TestCase):
    def test_every_public_contract_here(self):
        for folder, symbols in (("lz4", ["ode_lz4_decode", "ode_lz4_store", "ode_lz4_pack"]), ("utf8", ["ode_utf8"]), ("varint", ["ode_varint"]), ("common", ["ode_common"]), ("frame", ["ode_unframe"])):
            for s in symbols: self.assertEqual(ask(read("programs", folder, folder + ".spec"), read("programs", folder, folder + ".lemmas"), s), "ends", s)
        for folder, symbols in (("adler32", ["ode_adler32", "ode_adler32_blocks", "ode_adler32_blocks4"]), ("base64", ["ode_base64"]), ("inet", ["ode_inet"])):
            for s in symbols: self.assertEqual(kends.ends_for(ode.Spec(read("programs", folder, folder + ".spec")), s), ([], None))
        self.assertEqual(ask(read("blake3.spec"), read("proofs", "blake3.lemmas"), "b3l_hashr"), "ends")

    def test_a_lemma_that_requires_the_impossible(self):
        """Shown, of nothing: and until November 16, 2026 the line counted it."""
        utf8, common = read("programs", "utf8", "utf8.spec"), read("programs", "common", "common.spec")
        for spec_text, lemma, symbol in ((utf8, "lemma points(bytes: bytes, at: number, count: number): number {\n    requires at < at\n    decreases 0\n}\n", "ode_utf8"),
                                         (common, "lemma alike(a: bytes, b: bytes, at: number): number {\n    requires len(a) + 1 <= len(a)\n    decreases 7\n}\n", "ode_common")):
            spec = ode.with_proof(spec_text, lemma); kbyte.prove_lemmas(spec)             # the lemma itself is shown
            self.assertEqual(kbyte.ends(spec)[1], [])                                     # and the count of lemmas with a number is taken in by it
            v = ask(spec_text, lemma, symbol)
            self.assertIn("does not apply here", v)                                       # the contract's own use is not one the lemma speaks of
            self.assertIn("NOT shown", kends.line(spec, [symbol]))

    def test_the_contract_decides(self):
        common, lemmas = read("programs", "common", "common.spec"), read("programs", "common", "common.lemmas")
        self.assertEqual(ask(common, lemmas, "ode_common"), "ends")
        # the second run of another length: `alike` reads past its end; the lemma asks that it be no shorter, and the contract no longer gives that
        old = "contract ode_common(a: n bytes, b: n bytes, n: number) {"
        self.assertEqual(common.count(old), 1)
        self.assertIn("does not apply", ask(common.replace(old, "contract ode_common(a: n bytes, b: m bytes, n: number, m: number) {"), lemmas, "ode_common"))
        # with what the contract requires, it is given again
        longer = common.replace(old, "contract ode_common(a: n bytes, b: m bytes, n: number, m: number) {\n    requires n <= m")
        self.assertEqual(ask(longer, lemmas, "ode_common"), "ends")
        self.assertIn("no number that decreases is named for alike", ask(common, "", "ode_common"))
        utf8, ul = read("programs", "utf8", "utf8.spec"), read("programs", "utf8", "utf8.lemmas")
        old = "def utf8(bytes) { points(bytes, 0, 0) }"
        self.assertEqual(utf8.count(old), 1)
        self.assertIn("does not apply", ask(utf8.replace(old, "def utf8(bytes) { points(bytes, 1, 0) }"), ul, "ode_utf8"))       # from past the end of no bytes

    def test_a_definition_given_what_the_function_wrote(self):
        """The encoders' contracts speak of lz4 of a part of the bytes written: any bytes. LZ4's lemmas require
        nothing, so it ends on those too; a lemma that required something of them would not be met."""
        lz4, lemmas = read("programs", "lz4", "lz4.spec"), read("programs", "lz4", "lz4.lemmas")
        self.assertIn(("lz4", [("slice", ("name", "out"), ("num", 0), ("name", "r"))]), kends.calls_of(ode.Spec(lz4), ode.Spec(lz4).contracts["ode_lz4_pack"]))
        self.assertEqual(ask(lz4, lemmas, "ode_lz4_pack"), "ends")
        old = "lemma sequences(bytes: bytes, at: number, out: list): list {\n"
        self.assertEqual(lemmas.count(old), 1)
        v = ask(lz4, lemmas.replace(old, old + "    requires len(bytes) >= 1\n"), "ode_lz4_pack")
        self.assertTrue(v == "lemmas refused" or "does not apply" in v, v)

    def test_a_machine_that_goes_round_while(self):
        """The language has machines that go round while something holds. Nothing here shows one stops: a
        contract that speaks through one is not said to end."""
        text = ("machine halve(n) on x = n {\n    while x > 1\n    turn { x = x / 2 }\n}\n"
                "def steps(n) { halve(n) }\n"
                "contract ode_x(n: number) {\n    returns steps(n)\n    stack 8\n}\n"
                "contract ode_y(n: number) {\n    returns n + 1\n    stack 8\n}\n")
        try: spec = ode.Spec(text)
        except ode.Err as err: self.skipTest(f"not a machine as the language writes one: {err}")
        again, why = kends.ends_for(spec, "ode_x")
        self.assertIn("halve goes round while something holds", why or "")
        self.assertEqual(kends.ends_for(spec, "ode_y"), ([], None))
        self.assertIn("NOT shown", kends.line(spec, ["ode_x"]))

    def test_a_lemma_that_says_nothing_hides_nothing(self):
        """`lemma NAME(...): any { }` is taken without NAME being gone through. Over a definition that uses
        itself it hid that one's uses (found November 16, 2026, in the review of the night)."""
        utf8 = read("programs", "utf8", "utf8.spec")
        impossible = "lemma points(bytes: bytes, at: number, count: number): number {\n    requires at < at\n    decreases 0\n}\n"
        v = ask(utf8, "lemma utf8(bytes: any): any { }\n" + impossible, "ode_utf8")
        self.assertNotEqual(v, "ends"); self.assertIn("points", v); self.assertIn("not gone through", v)
        # a definition that never comes to an end, behind such a lemma
        spin = ("def spin(b, v) { if v == len(b) then 0 else spin(b, v) }\ndef wrap(b) { spin(b, 0) }\n"
                "contract ode_x(b: n bytes, n: number) {\n    returns wrap(b)\n    stack 8\n}\n")
        narrow = "lemma spin(b: bytes, v: number): number {\n    requires v == len(b)\n    decreases 0\n}\n"
        v = ask(spin, "lemma wrap(b: any): any { }\n" + narrow, "ode_x")
        self.assertNotEqual(v, "ends"); self.assertIn("spin", v)
        self.assertNotEqual(ask(spin, narrow, "ode_x"), "ends")                         # without it: the use is not one the lemma speaks of
        # and one level further in: the lemma that says nothing is under a definition that is gone through
        deeper = spin.replace("returns wrap(b)", "returns outer(b)") + "def outer(b) { wrap(b) + 1 }\n"
        self.assertNotEqual(ask(deeper, "lemma wrap(b: any): any { }\n" + narrow, "ode_x"), "ends")

    def test_a_sequence_hides_nothing(self):
        """A sequence is taken a place at a time, never gone through: a definition that uses itself must not be
        among what it reaches. One written with `for` was not even followed to what it uses."""
        narrow = "lemma spin(b: bytes, v: number): number {\n    requires v == len(b)\n    decreases 0\n}\n"
        text = ("def spin(b, v) { if v == len(b) then 0 else spin(b, v) }\n"
                "sequence turns(b) { s[0] = 0   s[k + 1] = s[k] + spin(b, 0) }\n"
                "contract ode_x(b: n bytes, n: number) {\n    returns turns(b)[3]\n    stack 8\n}\n")
        v = ask(text, narrow, "ode_x")
        self.assertNotEqual(v, "ends"); self.assertIn("spin", v)
        written = ("def spin(b, v) { if v == len(b) then 0 else spin(b, v) }\n"
                   "sequence turns(b) {\n    h[0] = 0\n    h[k + 1] = h[k] + spin(b, 0)\n    for k in 0..3\n}\n"
                   "contract ode_x(b: n bytes, n: number) {\n    returns turns(b)\n    stack 8\n}\n")
        v = ask(written, narrow, "ode_x")
        self.assertNotEqual(v, "ends"); self.assertIn("spin", v)
        inside = written.replace("returns turns(b)", "returns twice(b)") + "def twice(b) { 2 * turns(b) }\n"
        self.assertNotEqual(ask(inside, narrow, "ode_x"), "ends")

    def test_the_tree(self):
        b, bl = read("blake3.spec"), read("proofs", "blake3.lemmas")
        self.assertEqual(ask(b, bl, "b3l_hashr"), "ends")
        self.assertIn("no number that decreases is named for children, subtree", ask(b, "", "b3l_hashr"))
        old = "lemma subtree(key: any, flags: any, t: number, bytes: bytes): any {\n"
        self.assertEqual(bl.count(old), 1)
        self.assertNotEqual(ask(b, bl.replace(old, old + "    requires t < t\n"), "b3l_hashr"), "ends")


if __name__ == "__main__":
    unittest.main()
