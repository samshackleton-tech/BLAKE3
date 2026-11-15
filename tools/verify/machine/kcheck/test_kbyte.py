#!/usr/bin/env python3
"""Tests of kbyte.py on the programs of programs/: the function as compiled meets its contract, and a changed
specification, contract, proof or instruction does not (but for instructions that do nothing).

    python3 test_kbyte.py"""
import os, shutil, sys, tempfile, unittest
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import kbyte, kcheck, kdecode, ode
from test_kcheck import assemble


def text(*path):
    with open(os.path.join(HERE, "programs", *path)) as f: return f.read()


class Program:
    def __init__(self, folder, name, symbol):
        self.dir = tempfile.mkdtemp(prefix="kbyte-")
        assemble(os.path.join(HERE, "programs", folder, name + ".S"), os.path.join(self.dir, name + ".o"))
        self.rows = kbyte.load(os.path.join(self.dir, name + ".o"), symbol)
        self.spec, self.proof, self.symbol = text(folder, folder + ".spec"), text(folder, name + ".proof"), symbol
        shutil.rmtree(self.dir)
    def verdict(self, spec=None, proof=None, rows=None):
        try: kbyte.check(rows or self.rows, ode.Spec(spec or self.spec), self.symbol, self.proof if proof is None else proof); return "accepted"
        except (kcheck.Fail, ode.Err) as e: return f"refused: {e}"
    def changed(self, test, what, changes):
        whole = self.spec if what == "spec" else self.proof
        for old, new in changes:
            test.assertEqual(whole.count(old), 1, old)
            v = self.verdict(**{what: whole.replace(old, new)})
            test.assertTrue(v.startswith("refused"), f"{old!r} -> {new!r}: {v}")


class Adler32(unittest.TestCase):
    @classmethod
    def setUpClass(cls): cls.p = Program("adler32", "adler32", "ode_adler32")

    def test_it_meets_its_contract(self):
        self.assertEqual(self.p.verdict(), "accepted")

    def test_a_branch_on_the_bytes_must_be_said(self):
        v = self.p.verdict(spec=self.p.spec.replace("    trace depends on input\n", ""))
        self.assertTrue(v.startswith("refused: a branch that depends on bytes in memory"), v)

    def test_a_changed_specification_or_contract_is_refused(self):
        self.p.changed(self, "spec", [("s[0] = 1 ", "s[0] = 0 "), ("s[0] = 0 ", "s[0] = 1 "), ("(s[i] + bytes[i]) % 65521", "(s[i] + bytes[i]) % 65520"),
                                      ("(s[i] + bytes[i]) % 65521", "(s[i] + bytes[i] + 1) % 65521"), ("s1(bytes)[i + 1]) % 65521", "s1(bytes)[i]) % 65521"),
                                      ("65536 * s2(bytes)[len(bytes)] + s1(bytes)[len(bytes)]", "65536 * s1(bytes)[len(bytes)] + s2(bytes)[len(bytes)]"), ("65536 * s2", "65535 * s2"),
                                      ("s2(bytes)[len(bytes)] + s1(bytes)[len(bytes)]", "s2(bytes)[len(bytes)] + s1(bytes)[len(bytes) - 1]"), ("stack 40", "stack 39"),
                                      ("returns adler32(input)", "returns adler32(input) + 1")])

    def test_a_changed_proof_is_refused(self):
        self.p.changed(self, "proof", [("    fact i <= len\n", ""), ("fact i <= len", "fact i <= len + 1"), ("r12 = s1(input)[i]", "r12 = s2(input)[i]"), ("r13 = s2(input)[i]", "r13 = s2(input)[i + 1]"),
                                       ("    r13 = s2(input)[i]\n", ""), ("    decreases len - i\n", ""), ("decreases len - i", "decreases len + i"), ("name i = r14", "name i = r13"),
                                       ("place +0x2c", "place +0x2f")])
        self.assertTrue(self.p.verdict(proof="").startswith("refused"), self.p.verdict(proof="")[:80])        # no place: the loop cannot be run for every count

    def test_a_changed_instruction_is_refused_unless_it_did_nothing(self):
        accepted = []
        for k, (a, z, i) in enumerate(self.p.rows):
            changes = [".nop"]
            if not (i.startswith(".push") or i.startswith(".pop") or i == ".ret"):
                changes += [c for c in (i.replace(".jae", ".jb"), i.replace("0xFFF1", "0xFFF0"), i.replace(".add", ".sub") if i.startswith(".add") else i.replace(".sub", ".add"),
                                        i.replace(".r12", ".r13"), i.replace(".shl64 .rax 16", ".shl64 .rax 15"), i.replace(".r14", ".r13")) if c != i]
            for c in dict.fromkeys(changes):
                rows = list(self.p.rows); rows[k] = (a, z, c)
                if self.p.verdict(rows=rows) == "accepted": accepted.append((a - kbyte.BASE, i, c))
        # the six that are accepted put into a register what it holds already
        self.assertEqual(sorted(a for a, _, _ in accepted), [0x22, 0x49, 0x5a, 0x6f, 0x72, 0x80], accepted)
        self.assertTrue(all(c == ".nop" and i.startswith(".mov 64 (.reg .r") for _, i, c in accepted), accepted)


class Lz4Decode(unittest.TestCase):
    """The decoder against the contract of November 15: for any input, it writes nothing but the cap bytes at
    out, reads nothing but the n bytes at input, and returns."""
    @classmethod
    def setUpClass(cls): cls.p = Program("lz4", "lz4_decode", "ode_lz4_decode")

    def test_it_meets_its_contract(self):
        self.assertEqual(self.p.verdict(), "accepted")

    def test_a_changed_contract_is_refused(self):
        self.p.changed(self, "spec", [("    writes out\n", ""), ("    trace depends on input\n", ""), ("stack 104", "stack 103"), ("    requires apart(out, input)\n", ""),
                                      ("out: cap bytes, cap: number, input: n bytes", "out: cap bytes, cap: number, input: cap bytes"),
                                      ("out: cap bytes, cap: number, input: n bytes", "out: n bytes, cap: number, input: n bytes")])

    def test_a_proof_without_one_of_its_facts_is_refused(self):
        lines, needless = self.p.proof.split("\n"), []
        for k, line in enumerate(lines):
            if not line.strip().startswith(("fact ", "decreases ", "name ")): continue
            if self.p.verdict(proof="\n".join(lines[:k] + lines[k + 1:])) == "accepted": needless.append(line.strip())
        self.assertEqual(needless, ["fact offset >= 1"])       # where the match's count is read; the copy asks it again

    def test_a_check_taken_out_of_the_code_is_refused(self):
        # every conditional jump turned round, or left out: those that guard a read, a write or a loop's end are missed
        refused = 0
        for k, (a, z, i) in enumerate(self.p.rows):
            for old, new in ((".jae", ".jb"), (".jne", ".je")):
                if not i.startswith(old): continue
                for c in (i.replace(old, new), ".nop"):
                    rows = list(self.p.rows); rows[k] = (a, z, c)
                    refused += self.p.verdict(rows=rows) != "accepted"
        self.assertEqual(refused, REFUSED_JUMPS)


REFUSED_JUMPS = 38         # of 54; the 16 accepted change what is decoded, of which this contract says nothing


if __name__ == "__main__":
    unittest.main()
