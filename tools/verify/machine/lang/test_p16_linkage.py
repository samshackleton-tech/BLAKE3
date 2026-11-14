#!/usr/bin/env python3
"""Verify that Code_p16.lean is the exact lifted disassembly of wide/p16.ode and that its assembled
instructions match c/blake3_avx512_32.S's blake3_servil_avx512_p16."""
import os, re, shutil, subprocess, sys, tempfile, unittest

HERE = os.path.dirname(os.path.abspath(__file__))
WIDE = os.path.join(os.path.dirname(HERE), "wide")
ROOT = os.path.abspath(os.path.join(HERE, "..", "..", "..", ".."))
OBJDUMP = os.environ.get("OBJDUMP") or (shutil.which("llvm-objdump") or shutil.which("objdump") or "llvm-objdump")


def assemble_linux_x86(s_path, o_path):
    r = subprocess.run(["cc", "-target", "x86_64-unknown-linux-gnu", "-c", "-o", o_path, s_path], capture_output=True)
    if r.returncode != 0:
        subprocess.run(["cc", "-c", "-o", o_path, s_path], check=True)


def insn_lines(o_path, symbol):
    out = subprocess.check_output([OBJDUMP, "-d", "--x86-asm-syntax=intel", o_path], text=True)
    lines = []
    inside = False
    for line in out.splitlines():
        if re.match(rf"^[0-9a-fA-F]+\s+<{re.escape(symbol)}>:", line):
            inside = True
            continue
        if inside and re.match(r"^[0-9a-fA-F]+\s+<[^>]+>:", line):
            break
        if inside:
            m = re.match(r"^\s*[0-9a-fA-F]+:\s+((?:[0-9a-fA-F]{2}\s+)+)\s*(.+)$", line)
            if m:
                raw = " ".join(m.group(1).split())
                txt = re.sub(r"\s+", " ", m.group(2).strip())
                txt = re.sub(r"#.*$", "", txt).strip()
                txt = re.sub(rf"0x[0-9a-fA-F]+\s+<{re.escape(symbol)}(\+0x[0-9a-fA-F]+)?>",
                             lambda mm: f"<{mm.group(1) or '+0x0'}>", txt)
                lines.append((raw, txt))
    return lines


class P16Linkage(unittest.TestCase):
    def test_code_p16_matches_ode_and_production_s(self):
        with tempfile.TemporaryDirectory(prefix="p16-link-") as d:
            p16_s = os.path.join(d, "p16.S")
            p16_o = os.path.join(d, "p16.o")
            p16_lst = os.path.join(d, "p16.listing")
            p16_lifted = os.path.join(d, "Lifted_p16.lean")
            p16_code = os.path.join(d, "Code_p16.lean")

            asm = subprocess.check_output(
                ["python3", os.path.join(HERE, "odec.py"), os.path.join(WIDE, "p16.ode"), "x86_64", "p16"],
                text=True,
            )
            with open(p16_s, "w") as f:
                f.write(asm)
            assemble_linux_x86(p16_s, p16_o)
            lst = subprocess.check_output([OBJDUMP, "-d", "-r", "--x86-asm-syntax=intel", p16_o], text=True)
            with open(p16_lst, "w") as f:
                f.write(lst)
            subprocess.run(
                ["python3", os.path.join(os.path.dirname(HERE), "one", "lift_one.py"),
                 p16_lst, "b3l_p16", "0x18000", p16_lifted, "Lifted_p16", "--object", p16_o],
                check=True,
                env=dict(os.environ, OBJDUMP=OBJDUMP),
            )
            subprocess.run(
                ["python3", os.path.join(HERE, "gen_code.py"), "p16", p16_lifted + ".rows", p16_code],
                check=True,
            )

            with open(p16_code) as f1, open(os.path.join(HERE, "Code_p16.lean")) as f2:
                self.assertEqual(
                    f1.read(),
                    f2.read(),
                    "Code_p16.lean does not match fresh emission + assembly + lift of wide/p16.ode",
                )

            # Assemble c/blake3_avx512_32.S and compare every instruction and encoded byte
            # of blake3_servil_avx512_p16 against b3l_p16.
            prod_s = os.path.join(ROOT, "c", "blake3_avx512_32.S")
            prod_o = os.path.join(d, "prod.o")
            assemble_linux_x86(prod_s, prod_o)
            ode_insns = insn_lines(p16_o, "b3l_p16")
            prod_insns = insn_lines(prod_o, "blake3_servil_avx512_p16")
            self.assertEqual(len(ode_insns), 460)
            self.assertEqual(ode_insns, prod_insns)


if __name__ == "__main__":
    unittest.main()
