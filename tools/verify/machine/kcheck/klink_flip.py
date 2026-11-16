#!/usr/bin/env python3
"""klink_flip: every single-bit change of what a linker would have written, in the one object klink.py makes.

    python3 klink_flip.py BLOB.o [--native CASES]

In an assembler's object the four bytes of an instruction that say how far away its operand or the function
it calls is are left for a linker, and the single-bit audits of the functions (kflip.py, kfn_flip.py) pass
them by. In klink.py's object they are written, and kdecode.py reads the target from them. This changes each
of their bits in turn and asks the verifier of the function they are in. A change it accepts is, with
--native, linked with khash_native.c and run on this machine's processor against BLAKE3 in C (the whole
hash: exit 1 if any differs)."""
import os, subprocess, sys, tempfile
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import check_binary, kcheck, kdecode, klink


class Recording(kdecode.Settled):
    def __init__(self, e):
        super().__init__(e); self.fields = []
    def data(self, code, field, end):
        self.fields.append(("an operand", field)); return super().data(code, field, end)
    def callee(self, code, field, end):
        self.fields.append(("a call", field)); return super().callee(code, field, end)


def fields(blob, symbol):
    s = Recording(kdecode.Elf(blob)); at = start = s.at[symbol]
    while True:
        n, ins = kdecode.decode(s.image, at, s, s.image, 0, 0, start)
        at += n
        if ins == ".ret": return s.fields


def main():
    path = sys.argv[1]
    cases = sys.argv[sys.argv.index("--native") + 1] if "--native" in sys.argv else None
    with open(path, "rb") as f: blob = f.read()
    e = kdecode.Elf(blob)
    text = e.sections[e.index[".text"]]["off"]
    count, accepted, wrong = {"stopped": 0, "refused": 0, "ACCEPTED": 0}, [], 0
    for _, symbol in klink.BODIES:
        here = {"stopped": 0, "refused": 0, "ACCEPTED": 0}
        found = fields(blob, symbol)
        for kind, field in found:
            for bit in range(32):
                b = bytearray(blob); b[text + field + bit // 8] ^= 1 << (bit % 8)
                try:
                    check_binary.check(bytes(b), symbol); verdict = "ACCEPTED"; accepted.append((symbol, kind, field, bit, bytes(b)))
                except kdecode.Stop: verdict = "stopped"
                except kcheck.Fail: verdict = "refused"
                here[verdict] += 1; count[verdict] += 1
        print(f"  {symbol:<42} {len(found):>3} fields  {32 * len(found):>5} changes  {here['stopped']:>5} stopped by the decoder  {here['refused']:>5} refused  {here['ACCEPTED']:>3} accepted")
    print(f"{sum(count.values())} changes: {count['stopped']} stopped by the decoder, {count['refused']} refused, {count['ACCEPTED']} accepted")
    for symbol, kind, field, bit, b in accepted:
        line = f"  accepted: {symbol}, {kind} at {field:#x}, bit {bit}"
        if cases:
            with tempfile.TemporaryDirectory() as d:
                with open(os.path.join(d, "blob.o"), "wb") as f: f.write(b)
                exe = os.path.join(d, "run")
                subprocess.run(["cc", "-O1", "-o", exe, os.path.join(HERE, "khash_native.c"), os.path.join(HERE, "kflip_thunk.S"), os.path.join(d, "blob.o")], check=True)
                try: r = subprocess.run([exe, cases], capture_output=True, text=True, timeout=300); ok = r.returncode == 0
                except subprocess.TimeoutExpired: ok = False
            line += ": as BLAKE3 on the processor" if ok else ": DIFFERS on the processor"
            wrong += not ok
        print(line)
    if wrong: print(f"{wrong} accepted changes DIFFER on the processor: the verifier or the decoder is wrong")
    return 1 if wrong else 0


if __name__ == "__main__":
    sys.exit(main())
