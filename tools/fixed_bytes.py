#!/usr/bin/env python3
"""A kernel as fixed bytes: the same instructions for every user, whatever assembles the crate.

    python3 tools/fixed_bytes.py write     assemble the readable source, write the bytes file
    python3 tools/fixed_bytes.py check     the committed bytes file is what `write` makes now

The readable source of `blake3_servil_avx512_p16` is c/blake3_avx512_32.S (tools/gen_avx512_32.py). An
assembler chooses some of its bytes: clang's and GNU's pad the round loop's alignment with different
no-op instructions. c/blake3_avx512_p16_bytes.s holds the bytes one assembler made (the reference: clang
for x86_64-unknown-linux-gnu), one `.byte` line an instruction with the instruction it is beside it, and
src/ffi_avx512_32.rs includes that file with `global_asm!`: the user's toolchain copies the bytes and
chooses none. What stays symbolic is what the linker fills in: the four-byte distance from an instruction
to a word of the IV table (the file holds its own copy of the table, 16 bytes of read-only data), and the
unwind directives, which sit at the places they have in the source.

`check` needs the reference assembler. Its version is not pinned here; a different result from another
version would show as a difference, to be looked at."""
import os, re, subprocess, sys, tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SOURCE = os.path.join(ROOT, "c", "blake3_avx512_32.S")
OUT = os.path.join(ROOT, "c", "blake3_avx512_p16_bytes.s")
FUNCTION, SYMBOL = "blake3_servil_avx512_p16", "blake3_servil_avx512_p16_bytes"
TABLE = ".Lblake3_servil_avx512_p16_bytes_iv"
IV = [0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a]
CC = os.environ.get("FIXED_BYTES_CC", "clang")
OBJDUMP = os.environ.get("OBJDUMP", "llvm-objdump")
SAME = {"jz": "je", "jnz": "jne"}          # two names of one instruction: the source's, the disassembler's


def instructions(obj):
    """The function's instructions as the object holds them: (address, bytes, text, relocation or None)."""
    out = subprocess.run([OBJDUMP, "-d", "-r", "--x86-asm-syntax=intel", obj], capture_output=True, text=True, check=True).stdout
    rows, inside = [], False
    for line in out.splitlines():
        m = re.match(r"^[0-9a-f]+ <(.+)>:$", line)
        if m: inside = m.group(1) == FUNCTION; continue
        if not inside: continue
        m = re.match(r"^\s*([0-9a-f]+):\s+((?:[0-9a-f]{2}\s)+)\s*(.*)$", line)
        if m:
            rows.append([int(m.group(1), 16), bytes.fromhex(m.group(2).replace(" ", "")), re.sub(r"\s+", " ", m.group(3).split("#")[0]).strip(), None]); continue
        m = re.match(r"^\s+([0-9a-f]+):\s+(R_X86_64_\w+)\s+(\S+)$", line.rstrip())
        if m and rows: rows[-1][3] = (int(m.group(1), 16), m.group(2), m.group(3))
    assert rows, f"{FUNCTION} is not in the object"
    while rows[-1][2] != "ret":            # padding to the next function's alignment is not the function's
        assert rows[-1][2].startswith("nop"), rows[-1]; rows.pop()
    return rows


def render():
    with open(SOURCE) as f: text = f.read()
    body = text.split(FUNCTION + ":\n", 1)[1].split(f".size {FUNCTION}", 1)[0]
    assert re.findall(r"\.Liv32:\n\.long (.*)\n", text) == [", ".join(f"0x{w:08x}" for w in IV)], "the IV table is not the one this tool holds"
    with tempfile.TemporaryDirectory() as d:
        obj = os.path.join(d, "kernel.o")
        subprocess.run([CC, "--target=x86_64-unknown-linux-gnu", "-c", "-o", obj, SOURCE], check=True)
        rows = instructions(obj)
    start, at = rows[0][0], 0
    line = lambda bs, note: "    .byte " + ", ".join(f"0x{b:02x}" for b in bs) + (f"   // {note}" if note else "")
    out = [f"// {FUNCTION}, as fixed bytes. Written by tools/fixed_bytes.py from c/blake3_avx512_32.S: not edited by hand.",
           "// One line an instruction, the instruction beside it. Nothing here is chosen by the assembler that reads",
           "// this file; the linker fills in the distance to the IV table (the `.long` lines).",
           '.pushsection .rodata', ".p2align 6", f"{TABLE}:", "    .long " + ", ".join(f"0x{w:08x}" for w in IV), ".popsection",
           '.pushsection .text', ".p2align 6", f".globl {SYMBOL}", f".hidden {SYMBOL}", f".type {SYMBOL}, @function", f"{SYMBOL}:"]
    for raw in body.splitlines():
        s = re.sub(r"\s+", " ", raw.strip())
        if not s: continue
        if s.startswith(".cfi_"): out.append(s); continue
        if s.endswith(":"): out.append(f"// {s}"); continue
        if s.startswith(".p2align "):
            # what the assembler put there to reach the alignment: here as the bytes it chose
            bound = 1 << int(s.split()[1])
            while (rows[at][0] - start) % bound:
                assert rows[at][2].startswith("nop"), f"not padding: {rows[at]}"
                out.append(line(rows[at][1], f"{s}: {rows[at][2]}")); at += 1
            continue
        address, bs, dis, reloc = rows[at]; at += 1
        assert SAME.get(s.split()[0], s.split()[0]) == dis.split()[0], f"the source says `{s}`, the object `{dis}`"
        if reloc is None:
            out.append(line(bs, s)); continue
        where, kind, target = reloc
        m = re.fullmatch(r"\.rodata([+-]0x[0-9a-f]+)?", target)
        assert kind == "R_X86_64_PC32" and m and where == address + len(bs) - 4 and bs[-4:] == bytes(4), f"a relocation this tool does not know: {reloc}"
        offset = (int(m.group(1), 16) if m.group(1) else 0) + 4          # the addend counts from the field's end
        assert 0 <= offset < 4 * len(IV) and offset % 4 == 0, f"not a word of the IV table: {reloc}"
        out.append(line(bs[:-4], s))
        out.append(f"    .long {TABLE} + {offset} - . - 4")
    assert at == len(rows), f"{len(rows) - at} instructions of the object are not in the source"
    out += [f".size {SYMBOL}, . - {SYMBOL}", ".popsection", ""]
    return "\n".join(out), len(rows)


def main():
    text, count = render()
    if sys.argv[1:] == ["write"]:
        with open(OUT, "w") as f: f.write(text)
        print(f"{os.path.relpath(OUT, ROOT)}: {count} instructions")
    elif sys.argv[1:] == ["check"]:
        with open(OUT) as f: same = f.read() == text
        print(f"{os.path.relpath(OUT, ROOT)}: " + ("the bytes the reference assembler makes of the source" if same else "NOT what the reference assembler makes of the source"))
        return 0 if same else 1
    else:
        print(__doc__); return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
