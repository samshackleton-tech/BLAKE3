#!/usr/bin/env python3
"""Code_k32.lean is what the lifter reads from the assembled wide/k32.ode, and the assembled kernel is the
library's: every instruction of `blake3_servil_avx512_k32` and `blake3_servil_avx512_p32` of
c/blake3_avx512_32.S (one body, two entries), byte for byte, with the same relocations; and the read-only
data the two objects hold is the same bytes at the same offsets."""
import os, re, shutil, subprocess, tempfile, unittest

HERE = os.path.dirname(os.path.abspath(__file__))
WIDE = os.path.realpath(os.path.join(os.path.dirname(HERE), "wide"))
ROOT = os.path.abspath(os.path.join(WIDE, "..", "..", "..", ".."))
OBJDUMP = os.environ.get("OBJDUMP") or (shutil.which("llvm-objdump") or shutil.which("objdump") or "llvm-objdump")
BASE, RODATA = "0x10000", "0x50000000"       # where the model places the kernel and its read-only data


def assemble_linux_x86(s_path, o_path):
    r = subprocess.run(["cc", "-target", "x86_64-unknown-linux-gnu", "-c", "-o", o_path, s_path], capture_output=True)
    if r.returncode != 0:
        subprocess.run(["cc", "-c", "-o", o_path, s_path], check=True)


def code(o_path, symbols):
    """The instructions under the symbols, in order: (offset from the first symbol, bytes, text, relocation)."""
    out, rows, inside, first = subprocess.check_output([OBJDUMP, "-d", "-r", "--x86-asm-syntax=intel", o_path], text=True), [], False, None
    for line in out.splitlines():
        m = re.match(r"^([0-9a-fA-F]+)\s+<([^>]+)>:", line)
        if m:
            inside = m.group(2) in symbols
            if inside and first is None: first = int(m.group(1), 16)
            continue
        if not inside: continue
        m = re.match(r"^\s*([0-9a-fA-F]+):\s+((?:[0-9a-fA-F]{2}\s)+)\s*(.*)$", line)
        if m:
            text = re.sub(r"\s+", " ", re.sub(r"#.*$", "", m.group(3))).strip()
            # a jump's target as its distance from the first symbol, not as a symbol's name
            text = re.sub(r"0x([0-9a-fA-F]+) <[^>]+>", lambda g: f"+0x{int(g.group(1), 16) - first:x}", text)
            rows.append([int(m.group(1), 16) - first, " ".join(m.group(2).split()), text, None]); continue
        m = re.match(r"^\s+[0-9a-fA-F]+:\s+(R_X86_64_\w+)\s+(\S+)$", line.rstrip())
        if m and rows: rows[-1][3] = (m.group(1), m.group(2))
    # after the return, an object may hold padding up to the next function's alignment: not the kernel's
    assert any(r[2] == "ret" for r in rows), "no return"
    while rows[-1][2] != "ret":
        assert rows[-1][2].startswith("nop"), f"code after the return: {rows[-1][2]}"
        rows.pop()
    return [tuple(r) for r in rows]


def rodata(o_path):
    out, sec, data = subprocess.check_output([OBJDUMP, "-s", o_path], text=True), None, {}
    for line in out.splitlines():
        m = re.match(r"^Contents of section (.+):$", line)
        if m: sec = m.group(1); continue
        m = re.match(r"^\s*([0-9a-f]+) ((?:[0-9a-f]+ )+)", line)
        if m and sec == ".rodata":
            for i, b in enumerate(bytes.fromhex(m.group(2).replace(" ", ""))): data[int(m.group(1), 16) + i] = b
    return bytes(data[i] for i in range(len(data)))


class K32Linkage(unittest.TestCase):
    def test_code_k32_is_the_source_and_the_source_is_the_library(self):
        with tempfile.TemporaryDirectory(prefix="k32-link-") as d:
            s, o, lifted, generated = (os.path.join(d, n) for n in ("k32.S", "k32.o", "Lifted_k32.lean", "Code_k32.lean"))
            with open(s, "w") as f:
                f.write(subprocess.check_output(["python3", os.path.join(HERE, "odec.py"), os.path.join(WIDE, "k32.ode"), "x86_64", "k32"], text=True))
            assemble_linux_x86(s, o)
            with open(os.path.join(d, "k32.listing"), "w") as f:
                f.write(subprocess.check_output([OBJDUMP, "-d", "-r", "--x86-asm-syntax=intel", o], text=True))
            subprocess.run(["python3", os.path.join(os.path.dirname(HERE), "one", "lift_one.py"), os.path.join(d, "k32.listing"),
                            "b3l_k32", BASE, lifted, "Lifted_k32", "--object", o, "--rodata", RODATA],
                           check=True, env=dict(os.environ, OBJDUMP=OBJDUMP), stdout=subprocess.DEVNULL)
            subprocess.run(["python3", os.path.join(HERE, "gen_code.py"), "k32", lifted + ".rows", generated, "--data", lifted + ".data"], check=True)
            with open(generated) as f1, open(os.path.join(HERE, "Code_k32.lean")) as f2:
                self.assertEqual(f1.read(), f2.read(), "Code_k32.lean is not what the lifter reads from wide/k32.ode")

            prod = os.path.join(d, "prod.o")
            library = os.path.join(ROOT, "c", "blake3_avx512_32.S")
            assemble_linux_x86(library, prod)
            ours = code(o, {"b3l_k32"})
            theirs = code(prod, {"blake3_servil_avx512_k32", "blake3_servil_avx512_p32"})
            self.assertEqual(len(ours), 702)
            self.assertEqual(ours, theirs)
            # a control: a library with one mask register changed is not this kernel
            with open(library) as f: text = f.read()
            old = "vpaddd zmm5 {k1}, zmm1, zmm4"
            self.assertEqual(text.count(old), 1)
            changed_s, changed_o = os.path.join(d, "changed.S"), os.path.join(d, "changed.o")
            with open(changed_s, "w") as f: f.write(text.replace(old, "vpaddd zmm5 {k2}, zmm1, zmm4"))
            assemble_linux_x86(changed_s, changed_o)
            self.assertNotEqual(ours, code(changed_o, {"blake3_servil_avx512_k32", "blake3_servil_avx512_p32"}))
            self.assertEqual(sum(1 for r in ours if r[3]), 11)       # eight IV words, two index rows, the schedule's address: each a relocation into .rodata
            self.assertEqual(rodata(o), rodata(prod))


if __name__ == "__main__":
    unittest.main()
