#!/usr/bin/env python3
"""The controls of cross_one.sh: a model that is wrong in one way, which the processor must be found to differ from.

usage: wrong_model.py MACHINE.lean [write32 | vex | unpack]
  write32  a 32-bit write keeps the register's upper half
  vex      an XMM register written the VEX way keeps the bits above it (register 0)
  unpack   VPUNPCKHDQ on ZMM registers takes its two operands the other way round"""
import sys
p = sys.argv[1]
which = sys.argv[2] if len(sys.argv) > 2 else "write32"
with open(p) as f:
    t = f.read()
old, new = {
    "write32": ("      | 32 => v &&& 0xFFFFFFFF\n",
                "      | 32 => (s.get r &&& ~~~(0xFFFFFFFF : BitVec 64)) ||| (v &&& 0xFFFFFFFF)\n"),
    "vex": ("  | 0 => { s with x0 := v, w := { s.w with u0 := 0 } }\n",
            "  | 0 => { s with x0 := v }\n"),
    "unpack": ("  match i % 4 with | 0 => zdw a (i / 4 * 4 + 2) | 1 => zdw b (i / 4 * 4 + 2) | 2 => zdw a (i / 4 * 4 + 3) | _ => zdw b (i / 4 * 4 + 3)\n",
               "  match i % 4 with | 0 => zdw b (i / 4 * 4 + 2) | 1 => zdw a (i / 4 * 4 + 2) | 2 => zdw b (i / 4 * 4 + 3) | _ => zdw a (i / 4 * 4 + 3)\n"),
}[which]
assert t.count(old) == 1, (which, t.count(old))
with open(p, "w") as f:
    f.write(t.replace(old, new))
