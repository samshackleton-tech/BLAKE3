#!/bin/sh
# x86-64: the kernel `hex` of ../hex.ode, as assembled, meets its contract, quietly. On our machine model.
#   1. odec.py prints the kernel; the shipped file (c/blake3_hex_x86-64_unix.S) is that text under the
#      library's symbol name, which ../check-shipped.sh and a comparison here establish;
#   2. the assembler makes an ELF object; the lifter reads its instructions back (llvm-objdump);
#   3. prove.py writes Attr_hex.lean, Code_hex.lean and Proof_hex.lean from the instructions and the
#      source's contract; they must be the files kept here;
#   4. Lean checks `hex_meets_bytes`: the instructions meet `Hex.byteContract` (../spec/HexContract.lean)
#      whatever the hash is, and what an observer of time and cache sees does not depend on the hash.
# Needs python3, cc (clang, or gcc on x86-64 Linux), llvm-objdump (OBJDUMP), lake (elan).
set -eu
here=$(cd "$(dirname "$0")" && pwd); cd "$here"
OBJDUMP=${OBJDUMP:-llvm-objdump}; export OBJDUMP
base=0x50000
fail() { echo "$1"; echo "hex on x86-64: NOT checked"; exit 1; }
../check-shipped.sh > /dev/null || fail "the shipped assembly is not what the source prints (../check-shipped.sh)"
python3 ../odec.py ../hex.ode x86_64 hex > hex.S
python3 ../odec.py ../hex.ode x86_64 hex blake3_servil_ | sed 's/blake3_servil_hex/b3l_hex/g' | cmp -s - hex.S \
  || fail "the shipped text and the text proved differ in more than the symbol's name"
if cc -target x86_64-unknown-linux-gnu -c -o hex.o hex.S 2>/dev/null; then :; else cc -c -o hex.o hex.S; fi
"$OBJDUMP" -d -r --x86-asm-syntax=intel hex.o | awk "/<_?b3l_hex>:/,/ret/" > hex.listing
python3 lift_one.py hex.listing "$(head -n 1 hex.listing | sed 's/.*<\(.*\)>:/\1/')" $base Lifted_hex.lean Lifted_hex --object hex.o > /dev/null
mkdir -p again
python3 prove.py ../hex.ode hex Lifted_hex.lean.rows $base again > /dev/null || fail "the proof generator stopped"
for f in Attr_hex.lean Code_hex.lean Proof_hex.lean; do cmp -s "$f" "again/$f" || fail "$f is not what the compiler writes"; done
rm -rf again
if lake build Meets_hex_bytes > build.log 2>&1 && ! grep -q -E "error|sorry" build.log; then
  grep -E "hex_meets_bytes. depends on axioms" -A8 build.log | tr '\n' ' ' | cut -c1-400; echo
else
  grep -E "error|sorry" -A5 build.log | head -n 20
  fail "Lean does not accept the proof"
fi
grep -q "'hex_meets_bytes' depends on axioms" build.log || fail "hex_meets_bytes was not checked"
echo "hex on x86-64: checked"
