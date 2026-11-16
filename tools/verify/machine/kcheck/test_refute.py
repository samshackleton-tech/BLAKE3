#!/usr/bin/env python3
"""refute.py: what is false is said to be false, with an input; what is so is not. (Runs the binaries' code:
on an x86-64 Linux machine with a C compiler; elsewhere every test is skipped.)

    python3 test_refute.py"""
import os, subprocess, sys, tempfile, unittest
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import ode, refute

P = lambda *p: os.path.join(HERE, *p)


def run(binary, spec_path=None, symbol=None, cases=100):
    s, spec, public, at = refute.load_spec_and_offsets(binary, spec_path)
    assert refute.library().init_runner(s.image, len(s.image)) == 0
    symbol = symbol or next(nm for nm in public if nm in at)
    return refute.refute_symbol(s, spec, symbol, at[symbol], cases, seed=1)


@unittest.skipUnless(refute.available(), "the refuter runs x86-64 code: an x86-64 Linux machine with a C compiler")
class Refute(unittest.TestCase):
    def test_the_shipped_files_are_not_refuted(self):
        for program in ("varint", "common", "adler32", "inet", "base64", "utf8", "lz4", "frame"):
            s, spec, public, at = refute.load_spec_and_offsets(P("programs", program, f"ode{program}.o"))
            assert refute.library().init_runner(s.image, len(s.image)) == 0
            for symbol in sorted(nm for nm in public if nm in at):
                ok, n, _, msg = refute.refute_symbol(s, spec, symbol, at[symbol], 150, 1)
                self.assertTrue(ok and n >= 100, msg)
        ok, n, _, msg = run(P("b3hashr.o"), cases=60)
        self.assertTrue(ok, msg)

    def test_a_contract_or_specification_that_is_not_the_codes_is_false_with_an_input(self):
        cases = [
            ("programs/adler32/odeadler32.o", "programs/adler32/adler32.spec", "ode_adler32", "(s[i] + bytes[i]) % 65521", "(s[i] + bytes[i]) % 65520"),
            ("programs/varint/odevarint.o", "programs/varint/varint.spec", "ode_varint", "128 + v % 128", "128 + v % 127"),
            ("programs/lz4/odelz4.o", "programs/lz4/lz4.spec", "ode_lz4_store", "ensures r != NO if cap >= n + n / 255 + 16\n    writes out\n    stack 88", "ensures r != NO if cap >= n\n    writes out\n    stack 88"),
            ("programs/lz4/odelz4.o", "programs/lz4/lz4.spec", "ode_lz4_decode", "|| len(lz4(input)) > cap then", "|| len(lz4(input)) >= cap then"),
            ("programs/lz4/odelz4.o", "programs/lz4/lz4.spec", "ode_lz4_decode", "let offset = bytes[at] + 256 * bytes[at + 1]", "let offset = bytes[at + 1] + 256 * bytes[at]"),
            ("programs/utf8/odeutf8.o", "programs/utf8/utf8.spec", "ode_utf8", "if b < 128 then 1", "if b < 127 then 1"),
            ("programs/base64/odebase64.o", "programs/base64/base64.spec", "ode_base64", "requires cap >= 4 * ((n + 2) / 3)", "requires cap >= 4 * ((n + 1) / 3)"),
            ("programs/inet/odeinet.o", "programs/inet/inet.spec", "ode_inet", "% 65535 + 1", "% 65534 + 1"),
            ("programs/frame/odeframe.o", "programs/frame/frame.spec", "ode_unframe", "16777216 * b[0] + 65536 * b[1] + 256 * b[2] + b[3]", "16777216 * b[3] + 65536 * b[2] + 256 * b[1] + b[0]"),
            ("b3hashr.o", "blake3.spec", "b3l_hashr", ">>> 16", ">>> 17"),
            ("b3hashr.o", "blake3.spec", "b3l_hashr", "node_value(chunk_node(key, 0, flags, message), ROOT)", "node_value(chunk_node(key, 0, flags, message), 0)"),
        ]
        with tempfile.TemporaryDirectory() as d:
            for binary, spec, symbol, old, new in cases:
                with open(P(spec)) as f: text = f.read()
                self.assertEqual(text.count(old), 1, old)
                path = os.path.join(d, "changed.spec")
                with open(path, "w") as f: f.write(text.replace(old, new))
                ok, n, _, msg = run(P(binary), path, symbol, cases=120)
                self.assertFalse(ok, f"not refuted: {symbol} with {new!r}")
                self.assertIn("FALSE", msg); self.assertIn("input:", msg)

    def test_code_that_is_not_the_contracts_is_false_with_an_input(self):
        broken = [
            ("does not give back rbx", "ode_common", "programs/common/common.spec", "  mov rbx, 42\n  xor eax, eax\n  ret\n", "callee-saved"),
            ("reads past its input", "ode_adler32", "programs/adler32/adler32.spec", "  movzx eax, byte ptr [rdi + rsi]\n  ret\n", "crashed"),
            ("writes before its output", "ode_varint", "programs/varint/varint.spec", "  mov byte ptr [rdi - 1], 1\n  mov eax, 1\n  ret\n", "BEFORE"),
            ("does not return", "ode_common", "programs/common/common.spec", "1: jmp 1b\n", "timed out"),
            ("an encoder that always says NO", "ode_lz4_store", "programs/lz4/lz4.spec", "  mov rax, -1\n  ret\n", "ensures"),
            ("a varint of one byte whatever the number", "ode_varint", "programs/varint/varint.spec", "  mov byte ptr [rdi], sil\n  mov eax, 1\n  ret\n", "specification says"),
        ]
        with tempfile.TemporaryDirectory() as d:
            for label, symbol, spec, body, word in broken:
                with open(os.path.join(d, "b.S"), "w") as f: f.write(f".intel_syntax noprefix\n.globl {symbol}\n{symbol}:\n{body}")
                subprocess.run(["cc", "-c", "-o", os.path.join(d, "b.o"), os.path.join(d, "b.S")], check=True)
                ok, n, _, msg = run(os.path.join(d, "b.o"), P(spec), symbol, cases=40)
                self.assertFalse(ok, label)
                self.assertIn(word, msg, label)


if __name__ == "__main__":
    unittest.main()
