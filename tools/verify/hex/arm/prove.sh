#!/bin/sh
# AArch64: the kernel `hex_neon` of ../hex.ode, as assembled, meets its contract and shows an observer
# nothing of the hash. On Google DeepMind's model (github.com/google-deepmind/code-verification,
# arm64-semantics, unchanged, at the commit lakefile.toml names; fetched and built here: minutes).
#   1. odec.py prints the kernel; the shipped file (c/blake3_hex_aarch64.S) is that text under the
#      library's symbol name, which ../check-shipped.sh and a comparison here establish;
#   2. the assembler makes an ELF object; its instruction words are read back (llvm-objdump);
#   3. gen_arm.py asks their decoder what each word is and writes Quiet_hex_neon.lean and
#      Proof_hex_neon.lean from the words and the source's contract; they must be the files kept here;
#   4. Lean checks: the words run on 320 hashes in their semantics (HexNeonRun.lean); hex_neon_quiet and
#      hex_neon_observed (what an observer sees); hex_neon_meets: the words meet `Hex.byteContract`
#      (../spec/HexContract.lean).
# Then the audit (MUTANTS=0 skips it): code that shows the hash, or a weaker statement, must be refused.
# Needs python3, clang (or cc on AArch64), llvm-objdump (OBJDUMP), lake (elan).
set -eu
here=$(cd "$(dirname "$0")" && pwd); cd "$here"
OBJDUMP=${OBJDUMP:-llvm-objdump}
name=hex_neon
fail() { echo "$1"; echo "hex on AArch64: NOT checked"; exit 1; }
../check-shipped.sh > /dev/null || fail "the shipped assembly is not what the source prints (../check-shipped.sh)"
python3 ../odec.py ../hex.ode aarch64 "$name" > "$name.S"
python3 ../odec.py ../hex.ode aarch64 "$name" blake3_servil_ | sed "s/blake3_servil_$name/b3l_$name/g" | cmp -s - "$name.S" \
  || fail "the shipped text and the text proved differ in more than the symbol's name"
CC=${CC:-cc}; command -v clang > /dev/null 2>&1 && CC=clang
if "$CC" -target aarch64-unknown-linux-gnu -c -o "$name.o" "$name.S" 2>/dev/null; then :; else "$CC" -c -o "$name.o" "$name.S"; fi
"$OBJDUMP" -d "$name.o" | awk "/<_?b3l_$name>:/{on=1;next} on && NF>=2 {print \$2}" | tr '\n' ' ' > "$name.words"
[ "$(wc -w < "$name.words" | tr -d ' ')" -gt 0 ] || fail "the object holds no instructions of $name"
lake build Observer > build.log 2>&1 || { tail -n 5 build.log; fail "their model does not build"; }
mkdir -p again
python3 gen_arm.py ../hex.ode "$name" "$name.words" again || fail "the generator stopped"
for f in "Quiet_$name.lean" "Proof_$name.lean"; do cmp -s "$f" "again/$f" || fail "$f is not what the compiler writes"; done
rm -rf again
if lake build > build.log 2>&1 && ! grep -q -E "error|sorry" build.log; then
  grep -E "axioms" -A3 build.log | head -n 30
else
  grep -E "error|sorry" -A5 build.log | head -n 20
  fail "Lean does not accept the proofs"
fi
grep -q "(320, 320)" build.log || fail "the 320 hashes did not all give the hexadecimal"
grep -q "(some 36, true)" build.log || fail "the observer did not see 36 things, the same on two hashes"
grep -q "'hex_neon_meets' depends on axioms" build.log || fail "hex_neon_meets was not checked"
[ "${MUTANTS:-1}" = 0 ] || python3 mutants_quiet.py "$name" || fail "the audit accepted a change"
echo "hex on AArch64: checked"
