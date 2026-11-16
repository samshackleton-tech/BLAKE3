#!/usr/bin/env python3
"""programs/decimal: a count read as a proof's header writes it. The specification on numbers; the function's
bytes shown to meet its contract with no proof text; changed copies refused."""
import os, sys, unittest
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(HERE))
import kbyte, kcheck, kends, klin, ode
import test_kbyte as T


def value(spec, text):
    try: return spec.call(ode.Numbers(), "decimal", list(text.encode()))
    except ode.Fails: return "fails"


class Decimal(unittest.TestCase):
    @classmethod
    def setUpClass(cls): cls.p = T.Program("decimal", "decimal", "ode_decimal")

    def test_the_specification_on_numbers(self):
        s = ode.Spec(T.text("decimal", "decimal.spec"))
        for text, want in (("0", 0), ("7", 7), ("10", 10), ("007", 7), ("123456789", 123456789), ("999999999", 999999999), ("61554", 61554),
                           ("", "fails"), ("1234567890", "fails"), ("12a", "fails"), ("-1", "fails"), (" 1", "fails"), ("1 ", "fails"), ("1/", "fails"), ("1:", "fails")):
            self.assertEqual(value(s, text), want, text)
        for n in (0, 1, 9, 10, 99, 100, 4096, 38747, 80920, 10 ** 9 - 1): self.assertEqual(value(s, str(n)), n)       # as Python writes them (kproof.py reads these)

    def test_the_bytes_meet_the_contract_with_no_proof(self):
        self.assertEqual(self.p.proof.strip(), "")
        self.assertEqual(self.p.verdict(), "accepted")
        self.assertEqual(len(self.p.rows), 89)

    def test_changed_specifications_and_code_are_refused(self):
        self.p.changed(self, "spec", [("fails MALFORMED if b < 48 || b > 57", "fails MALFORMED if b < 48 || b > 58"), ("fails MALFORMED if b < 48 || b > 57", "fails MALFORMED if b < 47 || b > 57"),
                                      ("10 * sum + digit(bytes[at])", "10 * sum + digit(bytes[at]) + 1"), ("10 * sum + digit(bytes[at])", "9 * sum + digit(bytes[at])"), ("b - 48", "b - 47"),
                                      ("fails MALFORMED if len(bytes) == 0", "fails MALFORMED if len(bytes) == 1"), ("fails MALFORMED if len(bytes) > 9", "fails MALFORMED if len(bytes) > 8"),
                                      ("fails MALFORMED if len(bytes) > 9", "fails MALFORMED if len(bytes) > 10"), ("returns if failed(decimal(input)) then NO else decimal(input)", "returns if failed(decimal(input)) then 0 else decimal(input)"),
                                      ("returns if failed(decimal(input)) then NO else decimal(input)", "returns if failed(decimal(input)) then NO else decimal(input) + 1"), ("    stack 56", "    stack 48")])
        accepted = []
        for k, (a, z, i) in enumerate(self.p.rows):
            if i.startswith((".push", ".pop")) or i in (".ret", ".nop"): continue
            rows = list(self.p.rows); rows[k] = (a, z, ".nop")
            if self.p.verdict(rows=rows) == "accepted": accepted.append(i)
        # what may be left out and the contract kept: found by this test, judged on a processor by the audit
        self.assertLessEqual(len(accepted), 12, accepted)

    def test_its_definitions_come_to_an_end(self):
        import kguess
        text = T.text("decimal", "decimal.spec")
        self.assertIn("no number that decreases is named for digits", kends.ends_for(ode.Spec(text), "ode_decimal")[1])
        lemmas, left, tries = kguess.whole(text)                              # the lemma a prover finds
        self.assertIn("decreases len(bytes) - at", lemmas)
        spec = ode.with_proof(text, lemmas); kbyte.prove_lemmas(spec)
        try:
            klin.Facts.PROOFS = {}
            self.assertEqual(kends.ends_for(spec, "ode_decimal"), (["digits"], None))
        finally: klin.Facts.PROOFS = None


if __name__ == "__main__":
    unittest.main()
