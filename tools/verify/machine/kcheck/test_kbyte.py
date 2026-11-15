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
            ("match(bytes, end, bytes[at] % 16, with_literals, cap)", "match(bytes, end, bytes[at] / 16, with_literals, cap)"), ("match(bytes, end, bytes[at] % 16, with_literals, cap)", "match(bytes, end, bytes[at] % 16, out, cap)"),
            ("let offset = bytes[at] + 256 * bytes[at + 1]", "let offset = 256 * bytes[at] + bytes[at + 1]"), ("let offset = bytes[at] + 256 * bytes[at + 1]", "let offset = bytes[at] + 255 * bytes[at + 1]"),
            ("let n = count(bytes, at + 2, low)", "let n = count(bytes, at + 3, low)"),
            ("copies(out, offset)[n.value + 4], cap)", "copies(out, offset)[n.value + 3], cap)"), ("copies(out, offset)[n.value + 4], cap)", "copies(out, offset + 1)[n.value + 4], cap)"),
            ("sequences(bytes, n.next, copies", "sequences(bytes, n.next + 1, copies"),
            ("def lz4(bytes, cap) { sequences(bytes, 0, [], cap) }", "def lz4(bytes, cap) { sequences(bytes, 0, [0], cap) }"), ("def lz4(bytes, cap) { sequences(bytes, 0, [], cap) }", "def lz4(bytes, cap) { sequences(bytes, 1, [], cap) }"),
            ("if end == len(bytes) then with_literals else", "if end == len(bytes) then out else"),
            # where it fails: a test of the specification left out, or made another
            ("    fails MALFORMED if at >= len(bytes)\n    let literals", "    let literals"), ("    fails MALFORMED if end > len(bytes)\n", ""), ("    fails ROOM if len(out) + literals.value > cap\n", ""),
            ("    fails MALFORMED if at + 2 > len(bytes)\n", ""), ("    fails MALFORMED if offset == 0 || offset > len(out)\n", ""), ("    fails ROOM if len(out) + n.value + 4 > cap\n", ""),
            ("fails MALFORMED if offset == 0 || offset > len(out)", "fails MALFORMED if offset > len(out)"), ("fails MALFORMED if offset == 0 || offset > len(out)", "fails MALFORMED if offset == 0 || offset >= len(out)"),
            ("fails ROOM if len(out) + literals.value > cap", "fails ROOM if len(out) + literals.value >= cap"), ("fails ROOM if len(out) + n.value + 4 > cap", "fails ROOM if len(out) + n.value + 3 > cap"),
            ("fails MALFORMED if end > len(bytes)", "fails MALFORMED if end >= len(bytes)"), ("fails MALFORMED if at + 2 > len(bytes)", "fails MALFORMED if at + 1 > len(bytes)"),
            # the contract
            ("returns if failed(lz4(input, cap)) then NO else len(lz4(input, cap))", "returns if failed(lz4(input, cap)) then NO else len(lz4(input, cap)) + 1"),
            ("returns if failed(lz4(input, cap)) then NO else len(lz4(input, cap))", "returns if failed(lz4(input, cap)) then 0 else len(lz4(input, cap))"),
            ("returns if failed(lz4(input, cap)) then NO else len(lz4(input, cap))", "returns NO"), ("returns if failed(lz4(input, cap)) then NO else len(lz4(input, cap))", "returns len(lz4(input, cap))"),
            ("ensures out[0 .. len(lz4(input, cap))] = lz4(input, cap) if !failed(lz4(input, cap))", "ensures out[0 .. len(lz4(input, cap))] = lz4(input, cap) ++ [0] if !failed(lz4(input, cap))"),
            ("ensures out[0 .. len(lz4(input, cap))] = lz4(input, cap) if !failed(lz4(input, cap))", "ensures out[0 .. len(lz4(input, cap))] = lz4(input, cap)"),
            ("lz4(input, cap) if !failed(lz4(input, cap))", "lz4(input, cap + 1) if !failed(lz4(input, cap))"),
            ("    requires n < 72057594037927936\n", ""), ("    trace depends on input\n    stack 104", "    stack 104"), ("stack 104", "stack 96"), ("    requires apart(out, input)\n    requires n <", "    requires n <"),
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
            ("def lz4(bytes, cap) { sequences(bytes, 0, [], cap) }", "def lz4(bytes, cap) { sequences(bytes, 0, [0], cap) }"), ("def lz4(bytes, cap) { sequences(bytes, 0, [], cap) }", "def lz4(bytes, cap) { sequences(bytes, 1, [], cap) }"),
            ("fails ROOM if len(out) + literals.value > cap", "fails ROOM if len(out) + literals.value >= cap"),
            ("ensures lz4(out[0 .. r], n) == input if r != NO" + room, "ensures lz4(out[0 .. r], n) == input ++ [0] if r != NO" + room),
            ("ensures lz4(out[0 .. r], n) == input if r != NO" + room, "ensures lz4(out[0 .. r], n) == input" + room),
            ("ensures lz4(out[0 .. r], n) == input if r != NO" + room, "ensures lz4(out[0 .. r + 1], n) == input if r != NO" + room),
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
            ("match(bytes, end, bytes[at] % 16, with_literals, cap)", "match(bytes, end, bytes[at] / 16, with_literals, cap)"), ("match(bytes, end, bytes[at] % 16, with_literals, cap)", "match(bytes, end, bytes[at] % 16, out, cap)"),
            ("let offset = bytes[at] + 256 * bytes[at + 1]", "let offset = 256 * bytes[at] + bytes[at + 1]"), ("let offset = bytes[at] + 256 * bytes[at + 1]", "let offset = bytes[at] + 255 * bytes[at + 1]"),
            ("let n = count(bytes, at + 2, low)", "let n = count(bytes, at + 3, low)"),
            ("copies(out, offset)[n.value + 4], cap)", "copies(out, offset)[n.value + 3], cap)"), ("copies(out, offset)[n.value + 4], cap)", "copies(out, offset + 1)[n.value + 4], cap)"),
            ("sequences(bytes, n.next, copies", "sequences(bytes, n.next + 1, copies"),
            ("def lz4(bytes, cap) { sequences(bytes, 0, [], cap) }", "def lz4(bytes, cap) { sequences(bytes, 0, [0], cap) }"),
            ("if end == len(bytes) then with_literals else", "if end == len(bytes) then out else"),
            ("fails MALFORMED if offset == 0 || offset > len(out)", "fails MALFORMED if offset == 0 || offset >= len(out)"),
            ("ensures lz4(out[0 .. r], n) == input if r != NO" + tail, "ensures lz4(out[0 .. r], n) == input ++ [0] if r != NO" + tail),
            ("ensures lz4(out[0 .. r], n) == input if r != NO" + tail, "ensures lz4(out[0 .. r], n) == input" + tail),
            ("ensures lz4(out[0 .. r], n) == input if r != NO" + tail, "ensures lz4(out[0 .. r + 1], n) == input if r != NO" + tail),
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
    """No proof: the loop turns at most nine times, and the checker runs it."""
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
