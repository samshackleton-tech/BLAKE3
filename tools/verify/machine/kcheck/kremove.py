#!/usr/bin/env python3
"""kremove: which instructions of a kernel can go, and the kernel still meet its contract?

    python3 kremove.py k32|p32|p16|o16 OBJECT

Each instruction in turn is replaced by a no-op and the kernel checked as before (kcheck.py). One that can go
is either code the contract never needs (the kernels take 1 to 16 blocks and any start and end flags; the
contracts fix them), an instruction whose result nothing reads, or one the contract does not speak of
(`vzeroupper`, a stack probe). The list is for a person to read: it is how the eight unread shuffles of
`blake3_servil_output16` were found (BLAKE3 #398). It rests on the verifier, as everything here does."""
import os, sys, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import kcheck, kdecode

BASE, DATA = 0x10000, 0x50000000


def main():
    name, obj = sys.argv[1], sys.argv[2]
    kernel = kcheck.KERNELS[name]
    rows, data = kdecode.read(obj, kernel["start"], BASE, DATA)
    entry = BASE + kdecode.address(obj, kernel["symbol"]) - kdecode.address(obj, kernel["start"])
    kcheck.check(rows, DATA, data, name, entry)         # the control: the kernel as it is
    gone, t0 = [], time.time()
    for k, r in enumerate(rows):
        if r[2] == ".nop": continue
        changed = list(rows); changed[k] = (r[0], r[1], ".nop")
        try:
            kcheck.check(changed, DATA, data, name, entry); gone.append(r)
        except kcheck.Fail:
            pass
    print(f"{name}: of {sum(1 for r in rows if r[2] != '.nop')} instructions, {len(gone)} can be replaced by a no-op and the kernel still meets its contract ({time.time() - t0:.0f} s)")
    for r in gone: print(f"  +0x{r[0] - BASE:X}  {r[2]}")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except kcheck.Fail as e:
        print(f"{sys.argv[1]}: the kernel as it is is NOT shown: {e}"); sys.exit(1)
