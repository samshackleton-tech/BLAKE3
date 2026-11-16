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
        if os.path.exists(os.path.join(HERE, "programs", folder, name + ".inner")): self.spec += "\n" + text(folder, name + ".inner")   # the contracts of what it calls
        if os.path.exists(os.path.join(HERE, "programs", folder, folder + ".lemmas")): self.spec += "\n" + text(folder, folder + ".lemmas")   # lemmas about the definitions
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
        line = "    trace depends on input\n    stack 40"
        self.assertEqual(self.p.spec.count(line), 1)
        v = self.p.verdict(spec=self.p.spec.replace(line, "    stack 40"))
        self.assertTrue(v.startswith("refused: a branch that depends on bytes in memory"), v)

    def test_a_changed_specification_or_contract_is_refused(self):
        self.p.changed(self, "spec", [("s[0] = 1 ", "s[0] = 0 "), ("s[0] = 0 ", "s[0] = 1 "), ("(s[i] + bytes[i]) % 65521", "(s[i] + bytes[i]) % 65520"),
                                      ("(s[i] + bytes[i]) % 65521", "(s[i] + bytes[i] + 1) % 65521"), ("s1(bytes)[i + 1]) % 65521", "s1(bytes)[i]) % 65521"),
                                      ("65536 * s2(bytes)[len(bytes)] + s1(bytes)[len(bytes)]", "65536 * s1(bytes)[len(bytes)] + s2(bytes)[len(bytes)]"), ("65536 * s2", "65535 * s2"),
                                      ("s2(bytes)[len(bytes)] + s1(bytes)[len(bytes)]", "s2(bytes)[len(bytes)] + s1(bytes)[len(bytes) - 1]"), ("stack 40", "stack 39"),
                                      ("returns adler32(input)\n    trace depends on input\n    stack 40", "returns adler32(input) + 1\n    trace depends on input\n    stack 40")])

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


class Adler32Blocks(unittest.TestCase):
    """Adler-32 the usual fast way: the two sums are brought below 65521 once in 5552 bytes, not at every byte.
    The specification is the one above, unchanged: it reduces at every byte. The place says the sums' remainders
    are the specification's and bounds them; the verifier's arithmetic does the rest (a number has one quotient
    and one remainder). Written with the verifier frozen: no change to it."""
    @classmethod
    def setUpClass(cls): cls.p = Program("adler32", "adler32_blocks", "ode_adler32_blocks")

    def test_it_meets_its_contract(self):
        self.assertEqual(self.p.verdict(), "accepted")

    def test_a_changed_specification_or_contract_is_refused(self):
        head = "contract ode_adler32_blocks(input: len bytes, len: number) {\n"
        whole = head + "    returns adler32(input)\n    trace depends on input\n    stack 56\n}"
        self.p.changed(self, "spec", [
            ("s[0] = 1 ", "s[0] = 0 "), ("s[0] = 0 ", "s[0] = 1 "), ("(s[i] + bytes[i]) % 65521", "(s[i] + bytes[i]) % 65520"), ("(s[i] + bytes[i]) % 65521", "(s[i] + bytes[i]) % 65536"),
            ("(s[i] + s1(bytes)[i + 1]) % 65521", "(s[i] + s1(bytes)[i]) % 65521"), ("(s[i] + s1(bytes)[i + 1]) % 65521", "(s[i] + s1(bytes)[i + 1]) % 65522"),
            ("65536 * s2(bytes)[len(bytes)] + s1(bytes)[len(bytes)]", "65536 * s1(bytes)[len(bytes)] + s2(bytes)[len(bytes)]"), ("65536 * s2(bytes)[len(bytes)] + s1(bytes)[len(bytes)]", "65535 * s2(bytes)[len(bytes)] + s1(bytes)[len(bytes)]"),
            (whole, whole.replace("returns adler32(input)", "returns adler32(input) + 1")), (whole, whole.replace("    trace depends on input\n", "")), (whole, whole.replace("stack 56", "stack 48"))])

    def test_a_changed_proof_is_refused(self):
        lines, needless = self.p.proof.split("\n"), []
        for k, line in enumerate(lines):
            if not line.strip() or line.strip().startswith(("//", "place", "}", "any ")): continue
            if self.p.verdict(proof="\n".join(lines[:k] + lines[k + 1:])) == "accepted": needless.append(line.strip())
        self.assertEqual(needless, [])
        # a block one byte longer, a bound a little too small, the sums said equal where they are only alike by 65521
        self.p.changed(self, "proof", [("fact end <= i0 + 5552", "fact end <= i0 + 5553"), ("fact a <= 65520 + 255 * (i - i0)", "fact a <= 65520 + 254 * (i - i0)"),
                                       ("fact b <= 65520 + 1481280 * (i - i0)", "fact b <= 65520 + 1481279 * (i - i0)"), ("fact a % 65521 == s1(input)[i]", "fact a == s1(input)[i]"),
                                       ("fact b % 65521 == s2(input)[i]", "fact b % 65521 == s1(input)[i]"), ("decreases len - i0, 0, len - i", "decreases len - i, 0, 0")])

    def test_a_changed_instruction_is_refused_unless_it_keeps_the_contract(self):
        # Of 127, 11 accepted: moves of what is already there.
        n, accepted = instructions_changed(self.p)
        self.assertEqual((n, len(accepted)), (127, 11))
        self.assertTrue(all(i.startswith(".mov") and c == ".nop" for i, c in accepted))


class Adler32Blocks4(unittest.TestCase):
    """The same with four bytes a turn inside a block: the verifier steps the specification's sequences four
    places on, one after another."""
    @classmethod
    def setUpClass(cls): cls.p = Program("adler32", "adler32_blocks4", "ode_adler32_blocks4")

    def test_it_meets_its_contract(self):
        self.assertEqual(self.p.verdict(), "accepted")

    def test_a_changed_proof_is_refused(self):
        lines, needless = self.p.proof.split("\n"), []
        for k, line in enumerate(lines):
            if not line.strip() or line.strip().startswith(("//", "place", "}", "any ")): continue
            if self.p.verdict(proof="\n".join(lines[:k] + lines[k + 1:])) == "accepted": needless.append(line.strip())
        self.assertEqual(needless, [])

    def test_a_byte_taken_twice_or_left_out_is_refused(self):
        # the four reads of a turn are of input[i], [i + 1], [i + 2], [i + 3]: each made the one before, or the one after
        reads = [k for k, (a, z, i) in enumerate(self.p.rows) if i.startswith(".add 64 (.reg .rcx) (.imm 0x")]
        self.assertEqual([self.p.rows[k][2] for k in reads], [f".add 64 (.reg .rcx) (.imm 0x{d})" for d in (1, 2, 3)])
        for k in reads:
            a, z, i = self.p.rows[k]
            d = int(i.split("0x")[1].rstrip(")"), 16)
            for other in (d - 1, d + 1):
                rows = list(self.p.rows); rows[k] = (a, z, i.replace(f"0x{d})", f"0x{other})"))
                self.assertTrue(self.p.verdict(rows=rows).startswith("refused"), (i, other))


class Lz4Decode(unittest.TestCase):
    """The decoder against its public contract: a count returned is the count of the bytes the block decodes
    to, and they are at out; and on any input it reads and writes nothing else, and returns."""
    @classmethod
    def setUpClass(cls): cls.p = Program("lz4", "lz4_decode", "ode_lz4_decode")

    def test_it_meets_its_contract(self):
        self.assertEqual(self.p.verdict(), "accepted")

    def test_a_changed_specification_or_contract_is_refused(self):
        self.p.changed(self, "spec", [
            ("{value: sum + bytes[at], next: at + 1}", "{value: sum + bytes[at] + 1, next: at + 1}"), ("{value: sum + bytes[at], next: at + 1}", "{value: sum + bytes[at], next: at + 2}"),
            ("counted(bytes, at + 1, sum + 255)", "counted(bytes, at + 1, sum + 254)"), ("if bytes[at] < 255 then", "if bytes[at] < 254 then"),
            ("if first < 15 then {value: first, next: at} else counted(bytes, at, 15)", "if first < 14 then {value: first, next: at} else counted(bytes, at, 15)"),
            ("else counted(bytes, at, 15) }", "else counted(bytes, at, 16) }"),
            ("s[k] ++ [s[k][len(s[k]) - offset]]", "s[k] ++ [s[k][len(s[k]) - offset + 1]]"), ("s[k] ++ [s[k][len(s[k]) - offset]]", "s[k] ++ [s[k][len(s[k]) - offset]] ++ [0]"),
            ("{ s[0] = out ", "{ s[0] = out ++ [0] "),
            ("count(bytes, at + 1, bytes[at] / 16)", "count(bytes, at + 1, bytes[at] % 16)"), ("count(bytes, at + 1, bytes[at] / 16)", "count(bytes, at + 2, bytes[at] / 16)"),
            ("let with_literals = out ++ bytes[literals.next .. end]", "let with_literals = out ++ bytes[literals.next .. end] ++ [0]"),
            ("let with_literals = out ++ bytes[literals.next .. end]", "let with_literals = bytes[literals.next .. end] ++ out"),
            ("match(bytes, end, bytes[at] % 16, with_literals)", "match(bytes, end, bytes[at] / 16, with_literals)"), ("match(bytes, end, bytes[at] % 16, with_literals)", "match(bytes, end, bytes[at] % 16, out)"),
            ("let offset = bytes[at] + 256 * bytes[at + 1]", "let offset = 256 * bytes[at] + bytes[at + 1]"), ("let offset = bytes[at] + 256 * bytes[at + 1]", "let offset = bytes[at] + 255 * bytes[at + 1]"),
            ("let n = count(bytes, at + 2, low)", "let n = count(bytes, at + 3, low)"),
            ("copies(out, offset)[n.value + 4])", "copies(out, offset)[n.value + 3])"), ("copies(out, offset)[n.value + 4])", "copies(out, offset + 1)[n.value + 4])"),
            ("sequences(bytes, n.next, copies", "sequences(bytes, n.next + 1, copies"),
            ("def lz4(bytes) { sequences(bytes, 0, []) }", "def lz4(bytes) { sequences(bytes, 0, [0]) }"), ("def lz4(bytes) { sequences(bytes, 0, []) }", "def lz4(bytes) { sequences(bytes, 1, []) }"),
            ("if end == len(bytes) then with_literals else", "if end == len(bytes) then out else"),
            # where it fails: a test of the specification left out, or made another
            ("    fails MALFORMED if at >= len(bytes)\n    let literals", "    let literals"), ("    fails MALFORMED if end > len(bytes)\n", ""), 
            ("    fails MALFORMED if at + 2 > len(bytes)\n", ""), ("    fails MALFORMED if offset == 0 || offset > len(out)\n", ""), 
            ("fails MALFORMED if offset == 0 || offset > len(out)", "fails MALFORMED if offset > len(out)"), ("fails MALFORMED if offset == 0 || offset > len(out)", "fails MALFORMED if offset == 0 || offset >= len(out)"),
            
            ("fails MALFORMED if end > len(bytes)", "fails MALFORMED if end >= len(bytes)"), ("fails MALFORMED if at + 2 > len(bytes)", "fails MALFORMED if at + 1 > len(bytes)"),
            # the contract
            ("returns if failed(lz4(input)) || len(lz4(input)) > cap then NO else len(lz4(input))", "returns if failed(lz4(input)) || len(lz4(input)) > cap then NO else len(lz4(input)) + 1"),
            ("returns if failed(lz4(input)) || len(lz4(input)) > cap then NO else len(lz4(input))", "returns if failed(lz4(input)) || len(lz4(input)) > cap then 0 else len(lz4(input))"),
            ("returns if failed(lz4(input)) || len(lz4(input)) > cap then NO else len(lz4(input))", "returns NO"), ("returns if failed(lz4(input)) || len(lz4(input)) > cap then NO else len(lz4(input))", "returns len(lz4(input))"),
            ("ensures out[0 .. len(lz4(input))] = lz4(input) if !failed(lz4(input)) && len(lz4(input)) <= cap", "ensures out[0 .. len(lz4(input))] = lz4(input) ++ [0] if !failed(lz4(input)) && len(lz4(input)) <= cap"),
            ("ensures out[0 .. len(lz4(input))] = lz4(input) if !failed(lz4(input)) && len(lz4(input)) <= cap", "ensures out[0 .. len(lz4(input))] = lz4(input)"),
            # the room is the contract's: each part of what it says of it
            ("&& len(lz4(input)) <= cap", "&& len(lz4(input)) <= cap + 1"), ("|| len(lz4(input)) > cap then", "|| len(lz4(input)) >= cap then"), ("|| len(lz4(input)) > cap then", "|| len(lz4(input)) > cap + 1 then"),
            ("returns if failed(lz4(input)) || len(lz4(input)) > cap then NO", "returns if failed(lz4(input)) then NO"), ("returns if failed(lz4(input)) || len(lz4(input)) > cap then NO", "returns if len(lz4(input)) > cap then NO"),
            ("if !failed(lz4(input)) && len(lz4(input)) <= cap", "if !failed(lz4(input))"), ("if !failed(lz4(input)) && len(lz4(input)) <= cap", "if len(lz4(input)) <= cap"),
            ("    requires n < 72057594037927936\n", ""), ("    trace depends on input\n    stack 104", "    stack 104"), ("stack 104", "stack 96"), ("    requires no_overlap(out, input)\n    requires n <", "    requires n <"),
            ("ode_lz4_decode(out: cap bytes, cap: number, input: n bytes", "ode_lz4_decode(out: cap bytes, cap: number, input: cap bytes"), ("ode_lz4_decode(out: cap bytes, cap: number, input: n bytes", "ode_lz4_decode(out: n bytes, cap: number, input: n bytes")])

    def test_a_proof_without_one_of_its_lines_is_refused(self):
        lines, needless = self.p.proof.split("\n"), []
        for k, line in enumerate(lines):
            if not line.strip() or line.strip().startswith(("//", "place", "}", "any ")): continue
            if self.p.verdict(proof="\n".join(lines[:k] + lines[k + 1:])) == "accepted": needless.append(line.strip())
        self.assertEqual(needless, [])

    def test_a_changed_instruction_is_refused_unless_it_keeps_the_contract(self):
        accepted = []
        for k, (a, z, i) in enumerate(self.p.rows):
            changes = [".nop"] if not (i.startswith(".push") or i.startswith(".pop") or i == ".ret") else []
            changes += [i.replace(x, y) for x, y in ((".jae", ".jb"), (".jne", ".je"), (".add", ".sub")) if i.startswith(x)]
            if i.startswith(".sub"): changes.append(i.replace(".sub", ".add"))
            for c in changes:
                rows = list(self.p.rows); rows[k] = (a, z, c)
                if self.p.verdict(rows=rows) == "accepted": accepted.append((i.split()[0], c.split()[0]))
        # Of 309. The 19 accepted are moves left out: of something to where it is already, of a first value that is
        # not read before it is given again, and one `state = 2` after which the decoder still comes to give NO.
        self.assertEqual(len(accepted), ACCEPTED)
        self.assertEqual(sorted(set(accepted)), [(".mov", ".nop")])


ACCEPTED = 19


def instructions_changed(p):
    """Every instruction left out, and every jump and add turned round: (changes, those accepted)."""
    accepted, n = [], 0
    for k, (a, z, i) in enumerate(p.rows):
        changes = [".nop"] if not (i.startswith(".push") or i.startswith(".pop") or i == ".ret") else []
        changes += [i.replace(x, y) for x, y in ((".jae", ".jb"), (".jb", ".jae"), (".jne", ".je"), (".je", ".jne"), (".add", ".sub")) if i.startswith(x)]
        if i.startswith(".sub"): changes.append(i.replace(".sub", ".add"))
        for c in changes:
            rows = list(p.rows); rows[k] = (a, z, c); n += 1
            if p.verdict(rows=rows) == "accepted": accepted.append((i, c))
    return n, accepted


class Frame(unittest.TestCase):
    """A function made of two others, each used through its contract alone."""
    @classmethod
    def setUpClass(cls): cls.p = Program("frame", "unframe", "ode_unframe")

    def test_it_meets_its_contract(self):
        self.assertEqual(self.p.verdict(), "accepted")

    def test_no_line_of_the_public_contract_can_go(self):
        for line in ("    requires no_overlap(out, input)\n    requires n < 72057594037927936\n    requires cap < NO\n", "    requires n < 72057594037927936\n    requires cap < NO\n",
                     "    requires cap < NO\n", "    trace depends on input\n    stack 184\n"):
            self.assertEqual(self.p.spec.count(line), 1, line)
            first = line.split("\n")[0] + "\n"
            v = self.p.verdict(spec=self.p.spec.replace(line, line[len(first):]))
            self.assertTrue(v.startswith("refused"), f"without {first!r}: {v}")

    def test_a_changed_specification_or_contract_is_refused(self):
        self.p.changed(self, "spec", [
            ("    stack 184", "    stack 183"),
            ("fails SHORT if len(bytes) < 4", "fails SHORT if len(bytes) < 3"),
            ("    fails SHORT if len(bytes) < 4\n", ""), ("    fails SUM if adler32(body) != be32(bytes[len(bytes) - 4 .. len(bytes)])\n", ""),
            ("lz4(bytes[0 .. len(bytes) - 4])", "lz4(bytes[0 .. len(bytes) - 3])"), ("lz4(bytes[0 .. len(bytes) - 4])", "lz4(bytes[1 .. len(bytes) - 4])"),
            ("lz4(bytes[0 .. len(bytes) - 4])", "lz4(bytes)"),
            ("|| len(unframe(input)) > cap then", "|| len(unframe(input)) >= cap then"), ("returns if failed(unframe(input)) || len(unframe(input)) > cap then NO", "returns if failed(unframe(input)) then NO"),
            ("&& len(unframe(input)) <= cap", "&& len(unframe(input)) <= cap + 1"),
            ("adler32(body) != be32(", "adler32(body) == be32("), ("adler32(body) != be32(", "adler32(bytes) != be32("), ("adler32(body) != be32(", "adler32(body) + 1 != be32("),
            ("be32(bytes[len(bytes) - 4 .. len(bytes)])", "be32(bytes[len(bytes) - 5 .. len(bytes)])"), ("be32(bytes[len(bytes) - 4 .. len(bytes)])", "be32(bytes[0 .. 4])"),
            ("16777216 * b[0] + 65536 * b[1] + 256 * b[2] + b[3]", "16777216 * b[3] + 65536 * b[2] + 256 * b[1] + b[0]"), ("16777216 * b[0]", "16777215 * b[0]"), ("256 * b[2] + b[3]", "256 * b[2] + b[2]"),
            ("    body\n}", "    body ++ [0]\n}"), ("    body\n}", "    bytes\n}"),
            ("returns if failed(unframe(input)) || len(unframe(input)) > cap then NO else len(unframe(input))", "returns if failed(unframe(input)) || len(unframe(input)) > cap then NO else len(unframe(input)) + 1"),
            ("returns if failed(unframe(input)) || len(unframe(input)) > cap then NO else len(unframe(input))", "returns if failed(unframe(input)) || len(unframe(input)) > cap then 0 else len(unframe(input))"),
            ("returns if failed(unframe(input)) || len(unframe(input)) > cap then NO else len(unframe(input))", "returns len(unframe(input))"),
            ("ensures out[0 .. len(unframe(input))] = unframe(input) if !failed(unframe(input)) && len(unframe(input)) <= cap", "ensures out[0 .. len(unframe(input))] = unframe(input)"),
            ("ensures out[0 .. len(unframe(input))] = unframe(input) if !failed(unframe(input)) && len(unframe(input)) <= cap", "ensures out[0 .. len(unframe(input))] = input[0 .. len(unframe(input))] if !failed(unframe(input)) && len(unframe(input)) <= cap"),
            ("contract ode_unframe(out: cap bytes, cap: number, input: n bytes, n: number)", "contract ode_unframe(out: cap bytes, cap: number, input: cap bytes, n: number)"),
            ])

    def test_a_specification_that_says_the_same_another_way_is_shown_too(self):
        """A frame of four bytes holds an empty block, and an empty block decodes to nothing: so "fails SHORT
        if len(bytes) < 5" is the same specification as far as the contract asks. With the bent LZ4 (the room
        inside the definitions) the verifier could not see it and refused; opening `sequences` once, it does."""
        old = "fails SHORT if len(bytes) < 4"
        self.assertEqual(self.p.spec.count(old), 1)
        self.assertEqual(self.p.verdict(spec=self.p.spec.replace(old, "fails SHORT if len(bytes) < 5")), "accepted")

    def test_what_the_parts_are_is_not_the_callers_to_show(self):
        """With another Adler-32, or another LZ4, in the definitions, the caller is still shown: it uses the two
        functions by what their contracts say, whatever that is. It is the function called that no longer
        meets its contract (programs/check_programs.py checks each against the same text)."""
        for old, new, part in (("s[0] = 1 ", "s[0] = 2 ", ("adler32", "adler32_blocks4")), ("let offset = bytes[at] + 256 * bytes[at + 1]", "let offset = bytes[at] + 255 * bytes[at + 1]", ("lz4", "lz4_decode"))):
            self.assertEqual(self.p.spec.count(old), 1, old)
            spec = self.p.spec.replace(old, new)
            self.assertEqual(self.p.verdict(spec=spec), "accepted")
            q = Program(part[0], part[1], "ode_" + part[1])
            self.assertTrue(q.verdict(spec=spec).startswith("refused"), part)
            self.assertEqual(q.verdict(spec=self.p.spec), "accepted")           # and against the frame's text unchanged it is shown

    def test_a_callee_is_used_by_its_contract_and_nothing_else(self):
        """What the caller is shown to do rests on each line of the contracts of what it calls: with one weaker, or
        one that asks more, or one that says another thing, the caller is refused."""
        dec = "returns if failed(lz4(input)) || len(lz4(input)) > cap then NO else len(lz4(input))\n    ensures out[0 .. len(lz4(input))] = lz4(input) if !failed(lz4(input)) && len(lz4(input)) <= cap\n    trace depends on input\n    stack 104"
        self.assertEqual(self.p.spec.count(dec), 1)
        sums = "contract ode_adler32_blocks4(input: len bytes, len: number) {\n    returns adler32(input)\n"
        self.assertEqual(self.p.spec.count(sums), 1)
        for old, new in ((dec, dec.replace("    ensures out[0 .. len(lz4(input))] = lz4(input) if !failed(lz4(input)) && len(lz4(input)) <= cap\n", "    writes out\n")),      # the decoder says nothing of the bytes
                         (dec, dec.replace("then NO else", "then 0 else")), (dec, dec.replace("else len(lz4(input))\n", "else len(lz4(input)) + 1\n")),
                         (dec, dec.replace("> cap then", ">= cap then")), (dec, dec.replace("|| len(lz4(input)) > cap then", "then")), (dec, dec.replace("ensures out[0 .. len(lz4(input))] = lz4(input) if !failed", "ensures out[0 .. len(lz4(input))] = lz4(input) if failed")),
                         (dec, dec.replace("stack 104", "stack 105")),                                                                                               # the decoder may use more stack
                         (dec, "returns r\n    trace depends on input\n    writes out\n    stack 104"),                                                             # nothing said of the result
                         ("    requires n < 72057594037927936\n    returns if failed(lz4", "    requires n < 72057594037927931\n    returns if failed(lz4"),      # the decoder asks more than the caller shows (n - 4 < 2^56 - 4 it does show)
                         ("    requires n < 72057594037927936\n    returns if failed(lz4", "    requires n < 72057594037927936\n    requires cap >= 1\n    returns if failed(lz4"),
                         (sums, sums.replace("adler32(input)", "adler32(input) + 1")), (sums, sums.replace("returns adler32(input)", "returns r")),
                         (sums, sums.replace("input: len bytes, len: number", "len: number, input: len bytes")),                                                   # the arguments the other way round
                         (sums, sums.replace("returns adler32(input)\n", "requires len >= 1\n    returns adler32(input)\n")),
                         (sums, "contract ode_adler32_blocks5(input: len bytes, len: number) {\n    returns adler32(input)\n")):                                    # no contract for what is called
            self.assertEqual(self.p.spec.count(old), 1, old)
            v = self.p.verdict(spec=self.p.spec.replace(old, new))
            self.assertTrue(v.startswith("refused"), f"{old[:60]!r} -> {new[:90]!r}: {v}")

    def test_the_code_changed(self):
        n, accepted = instructions_changed(self.p)
        # the thirteen accepted do nothing: a variable set to 0 that is set again before it is read (eight); a
        # register given what it already holds (n in rax; the first call's three arguments; r in rax)
        self.assertEqual((n, len(accepted)), (83, 13), f"{n} changes; accepted: {accepted}")
        self.assertTrue(all(c == ".nop" and i.startswith(".mov") for i, c in accepted), accepted)

    def test_the_definitions_are_those_of_the_parts(self):
        """frame.spec's first two parts are the definitions of lz4.spec and adler32.spec, word for word; the
        contracts of the functions called are those files' public contracts."""
        lz, ad = text("lz4", "lz4.spec"), text("adler32", "adler32.spec")
        frame, inner = text("frame", "frame.spec"), text("frame", "unframe.inner")
        self.assertIn(lz[lz.index("const MALFORMED"):lz.index("const NO = ")].rstrip(), frame)
        self.assertIn(ad[ad.index("sequence s1"):ad.index("// ====")].rstrip(), frame)
        for whole, name in ((lz, "ode_lz4_decode"), (ad, "ode_adler32_blocks4")):
            c = whole[whole.index(f"contract {name}("):]
            self.assertIn(c[:c.index("\n}\n") + 3], inner)


class Lemmas(unittest.TestCase):
    """Lemmas about the specification's definitions (programs/lz4/lz4.lemmas): the verifier shows each before it
    uses any, so a lemma that is not so shows nothing; and the decoder's proof rests on them."""
    @classmethod
    def setUpClass(cls): cls.p = Program("lz4", "lz4_decode", "ode_lz4_decode")

    def test_a_lemma_that_is_not_so_is_refused(self):
        for old, new in (("    ensures len(result) >= len(out)\n    decreases len(bytes) - at\n}\n\n// The same of the rest", "    ensures len(result) >= len(out) + 1\n    decreases len(bytes) - at\n}\n\n// The same of the rest"),      # a last sequence with no literals adds nothing
                         ("// The same of the rest of a sequence, from its offset on.\nlemma match(bytes: bytes, at: number, low: number, out: list): list {\n    ensures len(result) >= len(out)", "lemma match(bytes: bytes, at: number, low: number, out: list): list {\n    ensures len(result) >= len(out) + 5"),
                         ("    ensures len(result) >= len(out)\n    decreases len(bytes) - at\n}\n\n// The same of the rest", "    ensures len(result) <= len(out)\n    decreases len(bytes) - at\n}\n\n// The same of the rest"),
                         ("ensures result.value >= sum", "ensures result.value >= sum + 1"), ("ensures result.next >= at + 1", "ensures result.next >= at + 2"), ("ensures result.next >= at + 1", "ensures result.next == at + 1"),
                         ("ensures len(result) == len(out) + k", "ensures len(result) == len(out) + k + 1"), ("ensures len(result) == len(out) + k", "ensures len(result) >= len(out) + 2 * k"),
                         # what a lemma requires is what makes it so
                         ("    requires offset >= 1\n", ""), ("    requires offset <= len(out)\n", ""),
                         # a lemma of something that is no definition, or with other things than the definition is given
                         ("lemma counted(bytes: bytes, at: number, sum: number)", "lemma counting(bytes: bytes, at: number, sum: number)"), ("lemma counted(bytes: bytes, at: number, sum: number)", "lemma counted(bytes: bytes, at: number)"),
                         ("lemma copies(out: list, offset: number)[k]: list", "lemma copies(out: list, offset: number): list")):
            self.assertEqual(self.p.spec.count(old), 1, old)
            v = self.p.verdict(spec=self.p.spec.replace(old, new))
            self.assertTrue(v.startswith("refused"), f"{new[:80]!r}: {v}")
            self.assertTrue("lemma" in v, v)

    def test_a_lemma_that_is_so_and_says_more_is_taken(self):
        old = "lemma match(bytes: bytes, at: number, low: number, out: list): list {\n    ensures len(result) >= len(out)"
        self.assertEqual(self.p.spec.count(old), 1)
        self.assertEqual(self.p.verdict(spec=self.p.spec.replace(old, old + " + 4")), "accepted")        # a match adds four bytes at least

    def test_a_lemma_is_of_the_definition_as_it_is(self):
        # the specification changed so that what is decoded may get shorter: the lemma is not so of it, and is refused
        for old, new in (("let with_literals = out ++ bytes[literals.next .. end]", "let with_literals = bytes[literals.next .. end]"),
                         ("if bytes[at] < 255 then {value: sum + bytes[at], next: at + 1}", "if bytes[at] < 255 then {value: bytes[at], next: at + 1}")):
            self.assertEqual(self.p.spec.count(old), 1, old)
            v = self.p.verdict(spec=self.p.spec.replace(old, new))
            self.assertTrue(v.startswith("refused") and "lemma" in v, v)

    def test_the_decoders_proof_rests_on_the_lemmas(self):
        """Without them the decoder is not shown: it gives NO for room before it has seen the whole block."""
        at = self.p.spec.index("// Lemmas about lz4.spec's definitions")
        v = self.p.verdict(spec=self.p.spec[:at])
        self.assertTrue(v.startswith("refused"), v)
        def without(spec, name):
            a = spec.index(f"lemma {name}("); z = spec.index("\n}\n", a) + 3
            return spec[:a] + spec[z:]
        needed = [name for name in ("counted", "copies", "sequences", "match") if self.p.verdict(spec=without(self.p.spec, name)).startswith("refused")]
        # `sequences` and `match` are each other's rest: with the lemma of one, the other is opened where it stands
        self.assertEqual(needed, ["counted", "copies"])
        self.assertTrue(self.p.verdict(spec=without(without(self.p.spec, "sequences"), "match")).startswith("refused"))

    def test_a_definition_that_uses_itself_is_shown_to_come_to_an_end(self):
        """`decreases E` in a lemma: E is not below zero where the definition uses itself (or one that uses it
        back), and less at each such use."""
        s = ode.Spec(self.p.spec)
        self.assertEqual({n: sorted(kbyte.ring(s, n)) for n in ("counted", "sequences", "match", "lz4", "copies")},
                         {"counted": ["counted"], "sequences": ["match", "sequences"], "match": ["match", "sequences"], "lz4": [], "copies": []})
        self.assertEqual(kbyte.ends(s), (["counted", "match", "sequences"], []))
        counted = "    ensures result.next >= at + 1\n    decreases len(bytes) - at\n"
        seqs = "    ensures len(result) >= len(out)\n    decreases len(bytes) - at\n}\n\n// The same of the rest"
        for old, new, want in ((counted, counted.replace("- at", "- at + 1"), "accepted"),                  # still less each time
                               (counted, counted.replace("- at", "- at - 1"), "accepted"),                  # it uses itself only with a byte ahead
                               (counted, counted.replace("len(bytes) - at", "at"), "refused"),              # it grows
                               (counted, counted.replace("len(bytes) - at", "len(bytes)"), "refused"),      # it stays
                               (seqs, seqs.replace("- at", "- at + len(out)"), "refused"),                  # what is decoded grows by more than is read
                               (seqs, seqs.replace("    decreases len(bytes) - at\n", ""), "refused"),      # `match` uses `sequences` back
                               ("    ensures len(result) == len(out) + k\n", "    ensures len(result) == len(out) + k\n    decreases k\n", "refused"),   # a sequence's place: no
                               (counted, counted + "    decreases at\n", "refused")):                       # said twice
            self.assertEqual(self.p.spec.count(old), 1, old)
            v = self.p.verdict(spec=self.p.spec.replace(old, new))
            self.assertTrue(v.startswith(want), f"{new!r}: {v}")
        # without the number, the definition is not said to end (and the rest stands)
        bare = self.p.spec.replace("    decreases len(bytes) - at\n", "")
        self.assertEqual(kbyte.ends(ode.Spec(bare)), (["counted", "match", "sequences"], ["counted", "match", "sequences"]))
        self.assertEqual(self.p.verdict(spec=bare), "accepted")

    def test_the_other_programs_definitions_come_to_an_end(self):
        def lemma(head, *body): return f"\nlemma {head} {{\n" + "".join(f"    {line}\n" for line in body) + "}\n"
        for key, head, tries in (
                (("common", "common", "ode_common"), "alike(a: bytes, b: bytes, at: number): number", (
                    (("requires at <= len(a)", "requires len(a) <= len(b)", "decreases len(a) - at"), "accepted"),
                    (("requires len(a) <= len(b)", "decreases len(a) - at"), "refused"),                 # from past the end it reads no byte
                    (("requires at <= len(a)", "decreases len(a) - at"), "refused"),                     # the second run may be the shorter
                    (("requires at <= len(a)", "requires len(a) <= len(b)", "decreases len(a)"), "refused"),
                    (("requires at <= len(a)", "requires len(a) <= len(b)", "decreases at"), "refused"))),
                (("varint", "varint", "ode_varint"), "varint(v: number): list", (
                    (("decreases v",), "accepted"), (("decreases v / 128",), "accepted"), (("decreases 128",), "refused"), (("decreases 300 - v",), "refused"))),
                (("utf8", "utf8", "ode_utf8"), "points(bytes: bytes, at: number, count: number): number", (
                    (("requires at <= len(bytes)", "decreases len(bytes) - at"), "accepted"),
                    (("decreases len(bytes) - at",), "refused"),
                    (("requires at <= len(bytes)", "decreases len(bytes) - at - count"), "refused"),
                    (("requires at <= len(bytes)", "decreases count"), "refused"),
                    (("requires at <= len(bytes)", "decreases len(bytes)"), "refused")))):
            p = Program(*key)
            at = p.spec.index("\nlemma ")
            self.assertEqual(kbyte.ends(ode.Spec(p.spec))[1], [], key)
            for body, want in tries:
                v = p.verdict(spec=p.spec[:at] + lemma(head, *body))
                self.assertTrue(v.startswith(want), f"{key[0]} {body}: {v}")
        for folder in ("adler32", "base64", "inet"):
            self.assertEqual(kbyte.ends(ode.Spec(text(folder, folder + ".spec"))), ([], []))
        # a definition that comes back to itself through a sequence is seen as one that uses itself
        s = ode.Spec("def f(x) { if x == 0 then 0 else g(x)[1] }\nsequence g(x) { s[0] = x   s[k + 1] = f(s[k]) }\ndef other(x) { x + 1 }\n")
        self.assertEqual(kbyte.ends(s), (["f", "g"], ["f", "g"]))

    def test_a_lemma_of_kind_any_says_nothing_and_gives_nothing(self):
        """`any`: a thing passed on. A lemma that says nothing of a definition is not shown (there is nothing to
        show), and what it gives can be used for nothing: the decoder, whose proof needs to know what `counted`
        is, is not shown with it."""
        old = self.p.spec[self.p.spec.index("lemma counted("):]
        old = old[:old.index("\n}\n") + 3]
        self.assertEqual(self.p.verdict(spec=self.p.spec.replace(old, "lemma counted(bytes: any, at: any, sum: any): any { }\n")).split(":")[0], "refused")
        # with something said, it is shown like any other: and this is not so (nothing is known of a thing of kind any)
        v = self.p.verdict(spec=self.p.spec.replace(old, "lemma counted(bytes: bytes, at: number, sum: number): any {\n    ensures result.value >= sum\n}\n"))
        self.assertTrue(v.startswith("refused"), v)
        with self.assertRaises(ode.Err): ode.Spec(text("lz4", "lz4.spec") + "\nlemma counted(bytes: words, at: number, sum: number): any { }\n")

    def test_the_kind_a_lemma_says_is_shown_too(self):
        """A lemma says what kind of thing the definition's value is (a list, a number, a record of these fields),
        and a use is given a thing of that kind. Until November 16, 2026 the kind was taken as said where the
        lemma ensured nothing else (`lemma counted(...): list { }` was shown; `counted` gives a record)."""
        spec = text("lz4", "lz4.spec")
        def shown(lemma):
            try: kbyte.prove_lemmas(ode.with_proof(spec, lemma)); return True
            except (kcheck.Fail, ode.Err): return False
        head = "lemma counted(bytes: bytes, at: number, sum: number): "
        self.assertTrue(shown(head + "record(value, next) { }\n"))
        self.assertTrue(shown(head + "record(next, value) { }\n"))
        for kind in ("list", "number", "record(value)", "record(value, next, more)", "record(a, b)"):
            self.assertFalse(shown(head + kind + " { }\n"), kind)
        self.assertTrue(shown(head + "any { }\n"))                                              # nothing said: nothing to show
        copies = "lemma copies(out: list, offset: number)[k]: list {\n    requires offset >= 1\n    requires offset <= len(out)\n    ensures len(result) == len(out) + k\n}\n"
        self.assertTrue(shown(copies))
        self.assertFalse(shown(copies.replace("[k]: list", "[k]: number").replace("    ensures len(result) == len(out) + k\n", "")))

    def test_a_proofs_part_gives_a_lemma_and_no_meaning(self):
        """ode.with_proof lets a proof's part hold a lemma of a definition of the reader's, and still no second
        definition of it."""
        spec, lemmas = text("lz4", "lz4.spec"), text("lz4", "lz4.lemmas")
        self.assertEqual(sorted(ode.with_proof(spec, lemmas).lemmas), ["copies", "counted", "match", "sequences"])
        with self.assertRaises(ode.Err): ode.with_proof(spec, lemmas + "\ndef match(bytes, at, low, out) { out }\n")
        with self.assertRaises(ode.Err): ode.with_proof(spec, lemmas + lemmas)                      # a lemma said twice


class Lz4Store(unittest.TestCase):
    """The encoder against a contract that is not a way to compute: what it writes decodes to the input."""
    @classmethod
    def setUpClass(cls): cls.p = Program("lz4", "lz4_store", "ode_lz4_store")

    def test_it_meets_its_contract(self):
        self.assertEqual(self.p.verdict(), "accepted")

    def test_a_changed_specification_or_contract_is_refused(self):
        after = "\n    writes out\n    stack 88"
        room = "\n    ensures r != NO if cap >= n + n / 255 + 16" + after
        self.p.changed(self, "spec", [
            ("{value: sum + bytes[at], next: at + 1}", "{value: sum + bytes[at] + 1, next: at + 1}"), ("{value: sum + bytes[at], next: at + 1}", "{value: sum + bytes[at], next: at + 2}"),
            ("counted(bytes, at + 1, sum + 255)", "counted(bytes, at + 1, sum + 254)"), ("if bytes[at] < 255 then", "if bytes[at] < 254 then"),
            ("if first < 15 then {value: first, next: at} else counted(bytes, at, 15)", "if first < 14 then {value: first, next: at} else counted(bytes, at, 15)"),
            ("else counted(bytes, at, 15) }", "else counted(bytes, at, 16) }"),
            ("count(bytes, at + 1, bytes[at] / 16)", "count(bytes, at + 1, bytes[at] % 16)"), ("count(bytes, at + 1, bytes[at] / 16)", "count(bytes, at + 2, bytes[at] / 16)"),
            ("let with_literals = out ++ bytes[literals.next .. end]", "let with_literals = out ++ bytes[literals.next .. end] ++ [0]"),
            ("if end == len(bytes) then with_literals else", "if end == len(bytes) then out else"),
            ("def lz4(bytes) { sequences(bytes, 0, []) }", "def lz4(bytes) { sequences(bytes, 0, [0]) }"), ("def lz4(bytes) { sequences(bytes, 0, []) }", "def lz4(bytes) { sequences(bytes, 1, []) }"),
            
            ("ensures lz4(out[0 .. r]) == input if r != NO" + room, "ensures lz4(out[0 .. r]) == input ++ [0] if r != NO" + room),
            ("ensures lz4(out[0 .. r]) == input if r != NO" + room, "ensures lz4(out[0 .. r]) == input" + room),
            ("ensures lz4(out[0 .. r]) == input if r != NO" + room, "ensures lz4(out[0 .. r + 1], n) == input if r != NO" + room),
            # when it does not give NO: no less room than it needs will do (15 bytes need 17), and not the other answer
            (room, "\n    ensures r != NO if cap >= n + n / 255 + 1" + after), (room, "\n    ensures r != NO if cap >= n + 16" + after), (room, "\n    ensures r != NO if cap >= n + n / 256 + 2" + after),
            (room, "\n    ensures r != NO" + after), (room, "\n    ensures r == NO if cap >= n + n / 255 + 16" + after),
            ("    writes out\n    stack 88", "    stack 88"), ("stack 88", "stack 80")])

    def test_a_proof_without_one_of_its_lines_is_refused(self):
        lines, needless = self.p.proof.split("\n"), []
        for k, line in enumerate(lines):
            if not line.strip() or line.strip().startswith(("//", "place", "}", "any ")): continue
            if self.p.verdict(proof="\n".join(lines[:k] + lines[k + 1:])) == "accepted": needless.append(line.strip())
        self.assertEqual(needless, [])

    def test_a_changed_instruction_is_refused_unless_it_keeps_the_contract(self):
        # Of 142, 14 accepted: moves left out that change nothing, and a compare after which the flags are those of
        # the same comparison made before. (Before the contract said when NO is not given, 17: a jump and a compare
        # left out on the way to NO were accepted too.)
        n, accepted = instructions_changed(self.p)
        self.assertEqual((n, len(accepted)), (142, 14))
        self.assertEqual(sorted(c for i, c in accepted if not i.startswith(".mov")), [".nop"])


class Lz4Pack(unittest.TestCase):
    """An encoder that writes matches, against the same contract: what it writes decodes to the input."""
    @classmethod
    def setUpClass(cls): cls.p = Program("lz4", "lz4_pack", "ode_lz4_pack")

    def test_it_meets_its_contract(self):
        self.assertEqual(self.p.verdict(), "accepted")

    def test_a_changed_specification_or_contract_is_refused(self):
        tail = "\n    ensures r != NO if cap >= n + n / 255 + 16\n    writes out\n    trace"
        room, after = "\n    ensures r != NO if cap >= n + n / 255 + 16\n    writes out\n    trace", "\n    writes out\n    trace"
        self.p.changed(self, "spec", [
            ("{value: sum + bytes[at], next: at + 1}", "{value: sum + bytes[at] + 1, next: at + 1}"), ("counted(bytes, at + 1, sum + 255)", "counted(bytes, at + 1, sum + 254)"), ("if bytes[at] < 255 then", "if bytes[at] < 254 then"),
            ("if first < 15 then {value: first, next: at} else counted(bytes, at, 15)", "if first < 14 then {value: first, next: at} else counted(bytes, at, 15)"),
            ("s[k] ++ [s[k][len(s[k]) - offset]]", "s[k] ++ [s[k][len(s[k]) - offset + 1]]"), ("{ s[0] = out ", "{ s[0] = out ++ [0] "),
            ("count(bytes, at + 1, bytes[at] / 16)", "count(bytes, at + 1, bytes[at] % 16)"),
            ("let with_literals = out ++ bytes[literals.next .. end]", "let with_literals = out ++ bytes[literals.next .. end] ++ [0]"),
            ("match(bytes, end, bytes[at] % 16, with_literals)", "match(bytes, end, bytes[at] / 16, with_literals)"), ("match(bytes, end, bytes[at] % 16, with_literals)", "match(bytes, end, bytes[at] % 16, out)"),
            ("let offset = bytes[at] + 256 * bytes[at + 1]", "let offset = 256 * bytes[at] + bytes[at + 1]"), ("let offset = bytes[at] + 256 * bytes[at + 1]", "let offset = bytes[at] + 255 * bytes[at + 1]"),
            ("let n = count(bytes, at + 2, low)", "let n = count(bytes, at + 3, low)"),
            ("copies(out, offset)[n.value + 4])", "copies(out, offset)[n.value + 3])"), ("copies(out, offset)[n.value + 4])", "copies(out, offset + 1)[n.value + 4])"),
            ("sequences(bytes, n.next, copies", "sequences(bytes, n.next + 1, copies"),
            ("def lz4(bytes) { sequences(bytes, 0, []) }", "def lz4(bytes) { sequences(bytes, 0, [0]) }"),
            ("if end == len(bytes) then with_literals else", "if end == len(bytes) then out else"),
            ("fails MALFORMED if offset == 0 || offset > len(out)", "fails MALFORMED if offset == 0 || offset >= len(out)"),
            ("ensures lz4(out[0 .. r]) == input if r != NO" + tail, "ensures lz4(out[0 .. r]) == input ++ [0] if r != NO" + tail),
            ("ensures lz4(out[0 .. r]) == input if r != NO" + tail, "ensures lz4(out[0 .. r]) == input" + tail),
            ("ensures lz4(out[0 .. r]) == input if r != NO" + tail, "ensures lz4(out[0 .. r + 1], n) == input if r != NO" + tail),
            ("    requires d >= 1\n", ""), ("    requires d <= 65535\n", ""), ("requires d <= 65535", "requires d <= 65536"),
            ("    trace depends on input\n    stack 120", "    stack 120"), ("stack 120", "stack 112"), ("    requires cap < NO\n    requires d", "    requires d"),
            # when it does not give NO: no less room will do (15 bytes that do not repeat need 17), and not the other answer
            (room, "\n    ensures r != NO if cap >= n + n / 255 + 1" + after), (room, "\n    ensures r != NO if cap >= n + 16" + after), (room, "\n    ensures r != NO if cap >= n + n / 256 + 16" + after),
            (room, "\n    ensures r != NO" + after), (room, "\n    ensures r == NO if cap >= n + n / 255 + 16" + after)])

    def test_a_proof_without_one_of_its_lines_is_refused(self):
        lines, needless = self.p.proof.split("\n"), []
        for k, line in enumerate(lines):
            if not line.strip() or line.strip().startswith(("//", "place", "}", "any ")): continue
            if self.p.verdict(proof="\n".join(lines[:k] + lines[k + 1:])) == "accepted": needless.append(line.strip())
        self.assertEqual(needless, [])

    def test_a_changed_instruction_is_refused_unless_it_keeps_the_contract(self):
        # Of 429, 38 accepted, each an instruction left out: moves that change nothing, and jumps after which a
        # match is not taken. (Each such object is run on the processor by the audit: what it writes still decodes
        # to its input, and it has room where the contract says so. Before the contract said when NO is not given,
        # 45: seven more, after which NO was given for a block that fits.)
        n, accepted = instructions_changed(self.p)
        self.assertEqual((n, len(accepted)), (429, 38))
        self.assertEqual({c for i, c in accepted}, {".nop"})


class Utf8(unittest.TestCase):
    """A validator: the count of code points, or NO where the bytes are not well-formed UTF-8. Written after
    the verifier was frozen for an audit: it needed no change to the verifier or to either language."""
    @classmethod
    def setUpClass(cls): cls.p = Program("utf8", "utf8", "ode_utf8")

    def test_it_meets_its_contract(self):
        self.assertEqual(self.p.verdict(), "accepted")

    def test_a_changed_specification_or_contract_is_refused(self):
        length = "if b < 128 then 1 else if b < 224 then 2 else if b < 240 then 3 else 4"
        least = "if n == 1 then 0 else if n == 2 then 128 else if n == 3 then 2048 else 65536"
        three = "else if n == 3 then 4096 * (bytes[at] - 224) + 64 * six(bytes, at, 1) + six(bytes, at, 2)"
        four = "else 262144 * (bytes[at] - 240) + 4096 * six(bytes, at, 1) + 64 * six(bytes, at, 2) + six(bytes, at, 3)"
        rest = "if at == len(bytes) then count else points(bytes, point(bytes, at).next, count + 1)"
        result = "returns if failed(utf8(input)) then NO else utf8(input)"
        self.p.changed(self, "spec", [
            ("fails MALFORMED if b >= 128 && b < 192", "fails MALFORMED if b >= 128 && b < 191"),
            (length, length.replace("b < 224", "b < 225")), (length, length.replace("b < 240", "b < 239")), (length, length.replace("b < 128", "b < 127")),
            ("fails MALFORMED if at + k >= len(bytes)", "fails MALFORMED if at + k > len(bytes)"),
            ("fails MALFORMED if bytes[at + k] < 128 || bytes[at + k] >= 192", "fails MALFORMED if bytes[at + k] < 127 || bytes[at + k] >= 192"),
            ("fails MALFORMED if bytes[at + k] < 128 || bytes[at + k] >= 192", "fails MALFORMED if bytes[at + k] < 128 || bytes[at + k] >= 193"),
            ("else if n == 2 then 64 * (bytes[at] - 192) + six(bytes, at, 1)", "else if n == 2 then 64 * (bytes[at] - 192) + six(bytes, at, 0)"),
            (three, three.replace("+ six(bytes, at, 2)", "+ six(bytes, at, 1)")), (three, three.replace("64 * six", "32 * six")),
            (four, four.replace("+ six(bytes, at, 3)", "+ six(bytes, at, 2)")), (four, four.replace("262144", "131072")),
            (least, least.replace("128", "127")), (least, least.replace("2048", "2049")), (least, least.replace("65536", "65537")), (least, least.replace("65536", "4096")),
            # the three things that make a sequence no code point: each left out, and each off by one
            ("    fails MALFORMED if p < least(n)                 // written in more bytes than it needs\n", ""),
            ("fails MALFORMED if p >= 55296 && p < 57344", "fails MALFORMED if p >= 55297 && p < 57344"), ("fails MALFORMED if p >= 55296 && p < 57344", "fails MALFORMED if p >= 55296 && p < 57343"),
            ("    fails MALFORMED if p >= 55296 && p < 57344      // a surrogate\n", ""),
            ("fails MALFORMED if p > 1114111", "fails MALFORMED if p > 1114112"), ("fails MALFORMED if p > 1114111", "fails MALFORMED if p > 1114110"), ("    fails MALFORMED if p > 1114111\n", ""),
            ("{value: p, next: at + n}", "{value: p, next: at + 1}"),
            (rest, rest.replace("count + 1)", "count + 2)")), (rest, rest.replace("then count else", "then count + 1 else")),
            ("def utf8(bytes) { points(bytes, 0, 0) }", "def utf8(bytes) { points(bytes, 0, 1) }"),
            (result, "returns utf8(input)"), (result, result + " + 1"), (result, result.replace("then NO", "then 0")),
            ("    trace depends on input\n", ""), ("stack 88", "stack 80")])

    def test_a_proof_without_one_of_its_lines_is_refused(self):
        lines, needless = self.p.proof.split("\n"), []
        for k, line in enumerate(lines):
            if not line.strip() or line.strip().startswith(("//", "place", "}", "any ")): continue
            if self.p.verdict(proof="\n".join(lines[:k] + lines[k + 1:])) == "accepted": needless.append(line.strip())
        self.assertEqual(needless, [])

    def test_a_changed_instruction_is_refused_unless_it_keeps_the_contract(self):
        # Of 344, 50 accepted, each an instruction left out: moves of what is already there, and jumps over code
        # that then does the same again. (Each such object is run on the processor by kbyte_nop.py.) Three of
        # the 50 were refused until November 16, 2026, and keep the contract: without the test "b < 192" (two
        # ways) a byte that only follows another is refused a little later by "b < 194"; without the jump of
        # "b >= 248" such a first byte is refused by the tests of a four-byte form. The verifier sees it since
        # it takes "has utf8(input) a value?" both ways and opens the definition once (split_defined).
        n, accepted = instructions_changed(self.p)
        self.assertEqual((n, len(accepted)), (344, 50))
        self.assertEqual({c for i, c in accepted}, {".nop"})

    def test_a_specification_that_says_the_same_another_way_is_shown_too(self):
        """A first byte of 245 and above is no UTF-8 whatever `length` says of it: read as the first of four it
        holds a number above 0x10FFFF. So "fails MALFORMED if b >= 248" can be 249 or 247 and the specification
        is the same one (2,040,719 inputs worked out both ways agree). The verifier refused those two until
        November 16, 2026: not shown, of something that is so."""
        old = "fails MALFORMED if b >= 248"
        self.assertEqual(self.p.spec.count(old), 1)
        for new in ("fails MALFORMED if b >= 249", "fails MALFORMED if b >= 247"):
            self.assertEqual(self.p.verdict(spec=self.p.spec.replace(old, new)), "accepted", new)
        # and one that does not say the same is refused: 244 is the first byte of U+100000 to U+10FFFF
        self.assertTrue(self.p.verdict(spec=self.p.spec.replace(old, "fails MALFORMED if b >= 244")).startswith("refused"))


class Base64(unittest.TestCase):
    """An encoder whose room is the caller's to give (`requires cap >= 4 * ((n + 2) / 3)`), in groups of three
    bytes. Written, like the UTF-8 validator, while the verifier was frozen: no change to it. (A check takes 13 s:
    the four letters of a group are five-way branches, 625 paths a turn. Its changed instructions are left to the
    single-bit audit.)"""
    @classmethod
    def setUpClass(cls): cls.p = Program("base64", "base64", "ode_base64")

    def test_it_meets_its_contract(self):
        self.assertEqual(self.p.verdict(), "accepted")

    def test_a_changed_specification_or_contract_is_refused(self):
        letter = "if v < 26 then 65 + v else if v < 52 then 71 + v else if v < 62 then v - 4 else if v == 62 then 43 else 47"
        quad = "[letter(a / 4), letter(16 * (a % 4) + b / 16), letter(4 * (b % 16) + c / 64), letter(c % 64)]"
        one = "[letter(bytes[at] / 4), letter(16 * (bytes[at] % 4)), 61, 61]"
        two = "[letter(bytes[at] / 4), letter(16 * (bytes[at] % 4) + bytes[at + 1] / 16), letter(4 * (bytes[at + 1] % 16)), 61]"
        whole = "groups(bytes)[len(bytes) / 3] ++ rest(bytes, 3 * (len(bytes) / 3))"
        self.p.changed(self, "spec", [
            (letter, letter.replace("v < 26", "v < 25")), (letter, letter.replace("65 + v", "66 + v")), (letter, letter.replace("71 + v", "70 + v")), (letter, letter.replace("v < 52", "v < 53")),
            (letter, letter.replace("v - 4", "v - 5")), (letter, letter.replace("then 43 else 47", "then 47 else 43")), (letter, letter.replace("then 43 else 47", "then 45 else 95")),
            (quad, quad.replace("letter(a / 4)", "letter(a % 64)")), (quad, quad.replace("16 * (a % 4) + b / 16", "16 * (a % 4) + b % 16")), (quad, quad.replace("4 * (b % 16) + c / 64", "4 * (b % 16)")),
            (quad, quad.replace("letter(c % 64)]", "letter(c / 4)]")), (quad, quad.replace("16 * (a % 4)", "8 * (a % 4)")),
            ("quad(bytes[3 * k], bytes[3 * k + 1], bytes[3 * k + 2])", "quad(bytes[3 * k], bytes[3 * k + 2], bytes[3 * k + 1])"), ("s[0] = []   s[k + 1] = s[k] ++ quad", "s[0] = [61]   s[k + 1] = s[k] ++ quad"),
            (one, one.replace("61, 61]", "61]")), (one, one.replace("16 * (bytes[at] % 4)", "bytes[at] % 4")), (two, two.replace(", 61]", ", 61, 61]")), (two, two.replace("letter(4 * (bytes[at + 1] % 16))", "letter(bytes[at + 1] % 16)")),
            ("if at == len(bytes) then []", "if at == len(bytes) then [61]"), ("else if at + 1 == len(bytes) then", "else if at + 2 == len(bytes) then"),
            (whole, "groups(bytes)[len(bytes) / 3]"), (whole, "groups(bytes)[len(bytes) / 3] ++ rest(bytes, len(bytes))"),
            # the room is the caller's to give: not left out, not a letter less; and the count is of all the letters
            ("    requires no_overlap(out, input)\n", ""), ("    requires cap >= 4 * ((n + 2) / 3)\n", ""), ("requires cap >= 4 * ((n + 2) / 3)", "requires cap >= 4 * ((n + 2) / 3) - 1"), ("requires cap >= 4 * ((n + 2) / 3)", "requires cap >= 4 * (n / 3)"),
            ("returns 4 * ((n + 2) / 3)", "returns 4 * (n / 3)"), ("returns 4 * ((n + 2) / 3)", "returns 4 * ((n + 2) / 3) + 1"),
            ("ensures out[0 .. 4 * ((n + 2) / 3)] = base64(input)", "ensures out[0 .. 4 * ((n + 2) / 3)] = base64(input) ++ [61]"),
            ("    trace depends on input\n", ""), ("stack 120", "stack 112")])

    def test_a_proof_without_one_of_its_lines_is_refused(self):
        lines, needless = self.p.proof.split("\n"), []
        for k, line in enumerate(lines):
            if not line.strip() or line.strip().startswith(("//", "place", "}", "any ")): continue
            if self.p.verdict(proof="\n".join(lines[:k] + lines[k + 1:])) == "accepted": needless.append(line.strip())
        self.assertEqual(needless, [])


class Inet(unittest.TestCase):
    """The Internet checksum. Its contract has no `trace` line: no branch and no address depends on the bytes,
    though every byte goes into the result. And it has no `requires`: where the sum might not fit it says NO.
    The specification says what a one's complement sum is (the plain sum less as many 65535s as leave it from 1
    to 65535); the code folds the carries in four times; the verifier's arithmetic shows they are the same.
    Written with the verifier frozen: no change to it."""
    @classmethod
    def setUpClass(cls): cls.p = Program("inet", "inet", "ode_inet")

    def test_it_meets_its_contract(self):
        self.assertEqual(self.p.verdict(), "accepted")
        contract = self.p.spec.split("contract ode_inet")[1]
        self.assertNotIn("trace", contract); self.assertNotIn("requires", contract)

    def test_a_changed_specification_or_contract_is_refused(self):
        pair = "s[k + 1] = s[k] + 256 * bytes[2 * k] + bytes[2 * k + 1]"
        total = "if len(bytes) % 2 == 0 then sums(bytes)[pairs] else sums(bytes)[pairs] + 256 * bytes[len(bytes) - 1]"
        ones = "if s == 0 then 0 else (s - 1) % 65535 + 1"
        no, zero, other = "ensures r == NO if n >= 562949953421312", "ensures r == checksum(input) if n < 562949953421312 && total(input) == 0", "ensures r == checksum(input) if n < 562949953421312 && total(input) != 0"
        self.p.changed(self, "spec", [
            ("s[0] = 0   " + pair, "s[0] = 1   " + pair), (pair, "s[k + 1] = s[k] + bytes[2 * k] + 256 * bytes[2 * k + 1]"), (pair, pair.replace("256", "255")), (pair, pair.replace("bytes[2 * k + 1]", "bytes[2 * k]")),
            (total, total.replace("+ 256 * bytes[len(bytes) - 1]", "+ bytes[len(bytes) - 1]")), (total, total.replace("else sums(bytes)[pairs] + 256 * bytes[len(bytes) - 1]", "else sums(bytes)[pairs]")),
            (total, total.replace("% 2 == 0", "% 2 == 1")), ("let pairs = len(bytes) / 2", "let pairs = (len(bytes) + 1) / 2"),
            # the one's complement sum: not the plain remainder (which gives 0 for 65535), not by 65536, not one off
            (ones, "if s == 0 then 0 else s % 65535"), (ones, ones.replace("65535", "65536")), (ones, "if s == 0 then 0 else (s - 1) % 65535"), (ones, "if s == 0 then 0 else s % 65535 + 1"),
            (ones, "if s == 0 then 65535 else (s - 1) % 65535 + 1"),
            ("def checksum(bytes) { 65535 - ones_sum(total(bytes)) }", "def checksum(bytes) { ones_sum(total(bytes)) }"), ("def checksum(bytes) { 65535 - ones_sum(total(bytes)) }", "def checksum(bytes) { 65536 - ones_sum(total(bytes)) }"),
            # it says NO from 2^49 bytes on, not from one more or one fewer; and the checksum everywhere else
            (no, no.replace(">= 562949953421312", ">= 562949953421311")), (no, "ensures r == 0 if n >= 562949953421312"),
            (zero, zero.replace("n < 562949953421312", "n < 562949953421314")), (other, other.replace("n < 562949953421312", "n < 562949953421314")),
            (zero, zero.replace("r == checksum(input)", "r == checksum(input) + 1")), (other, other.replace("r == checksum(input)", "r == checksum(input) + 1")), ("stack 40", "stack 32")])

    def test_a_proof_without_one_of_its_lines_is_refused(self):
        lines, needless = self.p.proof.split("\n"), []
        for k, line in enumerate(lines):
            if not line.strip() or line.strip().startswith(("//", "place", "}", "any ")): continue
            if self.p.verdict(proof="\n".join(lines[:k] + lines[k + 1:])) == "accepted": needless.append(line.strip())
        self.assertEqual(needless, [])

    def test_a_changed_instruction_is_refused_unless_it_keeps_the_contract(self):
        # Of 95, 4 accepted: moves of what is already there.
        n, accepted = instructions_changed(self.p)
        self.assertEqual((n, len(accepted)), (95, 4))
        self.assertTrue(all(i.startswith(".mov") and c == ".nop" for i, c in accepted))


class Contracts(unittest.TestCase):
    def test_no_line_of_a_public_contract_can_go(self):
        """Every `requires`, `writes`, `trace` and `needs` line of every program's public contract, left out in turn,
        is refused: none asks more of the caller, or allows the function more, than the code needs. (It found two
        such lines in the base-64 encoder's contract when it was first run.)"""
        from programs.check_programs import PROGRAMS
        for program, function, _ in PROGRAMS:
            p = Program(program, function, "ode_" + function)
            lines = p.spec.split("\n")
            start = next(k for k, l in enumerate(lines) if l.startswith(f"contract ode_{function}("))
            end = next(k for k in range(start, len(lines)) if lines[k].startswith("}"))
            for k in range(start + 1, end):
                if lines[k].strip().startswith(("requires", "writes", "trace", "needs")):
                    self.assertTrue(p.verdict(spec="\n".join(lines[:k] + lines[k + 1:])).startswith("refused"), f"ode_{function}: {lines[k].strip()}")


class Arithmetic(unittest.TestCase):
    """klin.py asked again (kbyte.py's facts are `thorough`): by bounds, and by elimination with more room."""
    def test_a_quotient_gets_its_value_from_bounds_whatever_else_is_known(self):
        from klin import Facts, sym, Lin
        f = Facts(); f.thorough = True
        q, m = sym("q"), sym("m")
        others = [sym(f"x{i}") for i in range(12)]
        for a, b in zip(others, others[1:]): f.add(b.scale(255) - a.scale(256) + 7); f.add(a.scale(3) - b + 1000)       # rows that have nothing to do with it
        for fact in (m - 4, Lin.of(18) - m, m + 236 - q.scale(16), q.scale(16) + 15 - m - 236): f.add(fact)
        self.assertIs(f.zero(q - 15), True)
        self.assertFalse(f.ge0(q - 16)); self.assertFalse(f.ge0(Lin.of(14) - q))
        plain = Facts()
        for fact in (m - 4, Lin.of(18) - m, m + 236 - q.scale(16), q.scale(16) + 15 - m - 236): plain.add(fact)
        self.assertFalse(plain.thorough)

    def test_or_is_a_sum_only_of_numbers_with_no_bit_in_common(self):
        # Adler-32's two sums are joined as (b << 16) + a. With `or` in place of the add (as Devon's source has it):
        # the same, since a is below 2^16. With the shift one less, or the add an `or` of the unshifted sum: not shown.
        p = Program("adler32", "adler32", "ode_adler32")
        k = next(j for j, (a, z, i) in enumerate(p.rows) if i == ".add 64 (.reg .rax) (.reg .r12)" and p.rows[j - 1][2] == ".shl64 .rax 16")
        a, z, i = p.rows[k]
        with_or = list(p.rows); with_or[k] = (a, z, ".or 64 (.reg .rax) (.reg .r12)")
        self.assertEqual(p.verdict(rows=with_or), "accepted")
        less = list(with_or); less[k - 1] = (p.rows[k - 1][0], p.rows[k - 1][1], ".shl64 .rax 15")
        self.assertTrue(p.verdict(rows=less).startswith("refused"), p.verdict(rows=less))
        none = list(with_or); none[k - 1] = (p.rows[k - 1][0], p.rows[k - 1][1], ".nop")
        self.assertTrue(p.verdict(rows=none).startswith("refused"), p.verdict(rows=none))

    def test_neither_way_shows_what_is_not_so(self):
        # 3,000 systems of a few small rows over three symbols: where `bounded`, or the elimination with the room
        # and the order `again` gives it, says they cannot all hold, no values from -6 to 6 make them hold
        import itertools, random
        from klin import Facts, Lin, AGAIN
        r, shown = random.Random(5), [0, 0]
        names = ("x", "y", "z")
        for _ in range(3000):
            rows = [Lin([(s, r.randrange(-3, 4)) for s in names if r.random() < 0.7], r.randrange(-8, 9)) for _ in range(r.randrange(2, 6))]
            rows = [Facts.norm(f) for f in rows if f.c]
            ways = (Facts.bounded(rows), Facts.eliminate(rows, limit=AGAIN, last=frozenset(r.sample(names, r.randrange(0, 3)))))
            for k, said in enumerate(ways): shown[k] += said
            if any(ways):
                for v in itertools.product(range(-6, 7), repeat=3):
                    env = dict(zip(names, v))
                    self.assertFalse(all(sum(a * env[s] for s, a in f.c) + f.k >= 0 for f in rows), (rows, v, ways))
        self.assertGreater(min(shown), 50)


class Varint(unittest.TestCase):
    """No proof: the loop turns at most nine times, and the verifier runs it."""
    @classmethod
    def setUpClass(cls): cls.p = Program("varint", "varint", "ode_varint")

    def test_it_meets_its_contract(self):
        self.assertEqual(self.p.verdict(), "accepted")
        self.assertEqual(self.p.proof.strip(), "")

    def test_a_changed_specification_or_contract_is_refused(self):
        self.p.changed(self, "spec", [("if v < 128 then [v]", "if v < 127 then [v]"), ("if v < 128 then [v]", "if v < 128 then [v + 1]"), ("[128 + v % 128]", "[127 + v % 128]"), ("[128 + v % 128]", "[128 + v % 64]"),
                                      ("++ varint(v / 128)", "++ varint(v / 64)"), ("[128 + v % 128] ++ varint(v / 128)", "varint(v / 128) ++ [128 + v % 128]"),
                                      ("ensures out[0 .. r] = varint(v)", "ensures out[0 .. r] = varint(v) ++ [0]"), ("ensures out[0 .. r] = varint(v)", "ensures out[0 .. r] = varint(v + 1)"),
                                      ("out: 10 bytes", "out: 9 bytes"), ("stack 24", "stack 16")])

    def test_a_changed_instruction_is_refused_unless_it_did_nothing(self):
        n, accepted = instructions_changed(self.p)
        self.assertTrue(all(c == ".nop" and i.startswith(".mov 64 (.reg") for i, c in accepted), accepted)
        self.assertLess(len(accepted), 6)


class Common(unittest.TestCase):
    @classmethod
    def setUpClass(cls): cls.p = Program("common", "common", "ode_common")

    def test_it_meets_its_contract(self):
        self.assertEqual(self.p.verdict(), "accepted")

    def test_a_changed_specification_contract_or_proof_is_refused(self):
        self.p.changed(self, "spec", [("if at == len(a) then at else", "if at == len(a) then 0 else"), ("if a[at] != b[at] then at", "if a[at] != b[at] then at + 1"), ("else alike(a, b, at + 1)", "else alike(a, b, at + 2)"),
                                      ("def common(a, b) { alike(a, b, 0) }", "def common(a, b) { alike(a, b, 1) }"), ("    trace depends on a, b\n", ""), ("trace depends on a, b", "trace depends on a"),
                                      ("returns common(a, b)", "returns common(a, b) + 1"), ("stack 40", "stack 32"), ("a: n bytes, b: n bytes, n: number", "a: n bytes, b: n bytes, m: number, n: number")])
        self.p.changed(self, "proof", [("    fact go == 1\n", ""), ("    fact i <= n\n", ""), ("    fact alike(a, b, i) == common(a, b)\n", ""), ("fact alike(a, b, i) == common(a, b)", "fact alike(a, b, i + 1) == common(a, b)"),
                                       ("    decreases n - i\n", ""), ("name i = r13", "name i = r12")])

    def test_a_changed_instruction_is_refused_unless_it_did_nothing(self):
        n, accepted = instructions_changed(self.p)
        self.assertTrue(all(c == ".nop" and i.startswith(".mov 64 (.reg") for i, c in accepted), accepted)
        self.assertLess(len(accepted), 6)


if __name__ == "__main__":
    unittest.main()
