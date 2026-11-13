#!/bin/sh
# Cross-check one/Machine.lean (the model under the kernels', the parent functions' and merge's
# theorems) against this machine's CPU: the Lean model writes test vectors for every instruction of
# those programs and of the wide kernel P16, and cross_one.c runs the same bytes on the processor. Then
# three controls: a model wrong in one way (wrong_model.py) must each be found to differ.
# Linux, x86-64 with AVX-512 F and VL.
set -eu
here=$(cd "$(dirname "$0")" && pwd); work=${CROSS_WORK:-$(mktemp -d)}; mkdir -p "$work"
cd "$here"
lake build Machine CrossOneTable >/dev/null
lake env lean --run CrossOne.lean 40 > "$work/vectors.txt"
cc -O1 -o "$work/cross_one" cross_one.c
"$work/cross_one" "$work/vectors.txt"
# Controls: a model wrong in one way must be found to differ from the processor.
for control in write32 vex unpack; do
  rm -rf "$work/wrong"; mkdir -p "$work/wrong"; cp Machine.lean CrossOneTable.lean CrossOne.lean lean-toolchain "$work/wrong/"
  printf 'name = "wrong"\n[[lean_lib]]\nname = "Machine"\n[[lean_lib]]\nname = "CrossOneTable"\n' > "$work/wrong/lakefile.toml"
  python3 wrong_model.py "$work/wrong/Machine.lean" "$control"
  (cd "$work/wrong" && lake build Machine CrossOneTable > "$work/wrong-build.log" 2>&1 || { tail -n 20 "$work/wrong-build.log"; exit 1; })
  (cd "$work/wrong" && lake env lean --run CrossOne.lean 40 > "$work/wrong-vectors.txt")
  if "$work/cross_one" "$work/wrong-vectors.txt" > "$work/wrong.out"; then echo "the control passed: a wrong model ($control) was not noticed"; exit 1; fi
  case "$control" in
    write32) what="a 32-bit write that keeps the upper half";;
    vex) what="a VEX write that keeps the bits above the XMM register";;
    unpack) what="VPUNPCKHDQ with its operands the other way round";;
  esac
  tail -n 1 "$work/wrong.out" | sed "s/^/control ($what): /"
done
echo "cross-check done"
