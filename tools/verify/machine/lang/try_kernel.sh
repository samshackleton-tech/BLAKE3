#!/bin/sh
# A kernel written in Ode (its instructions chosen by hand), from the source to a run in the machine model
# on its contract's examples (BLAKE3 #361). For `p16` of ../wide/p16.ode:
#   1. odec.py prints the kernel's assembly: its lines, defs and fors expanded, nothing added or changed;
#   2. the assembler makes an ELF object, and the lifter reads the object's bytes back (llvm-objdump);
#   3. the instructions the lifter read are run in the machine model on each example of the contract the
#      source names (`kernel NAME meets CONTRACT(...)`), and the result compared with the contract.
# This is a test by running, not a proof: it says the model, the lifter and the contract agree on these
# examples, and gives a refuting input when they do not.
# Needs python3, cc (clang, or gcc on x86-64 Linux), llvm-objdump (OBJDUMP), lake.
# usage: SOURCE=FILE.ode ./try_kernel.sh NAME BASE
set -eu
here=$(cd "$(dirname "$0")" && pwd); cd "$here"
OBJDUMP=${OBJDUMP:-llvm-objdump}; export OBJDUMP
name=$1; base=$2
source=${SOURCE:?the kernel\'s source file}
python3 odec.py "$source" x86_64 "$name" > "$name.S"
if cc -target x86_64-unknown-linux-gnu -c -o "$name.o" "$name.S" 2>/dev/null; then :; else cc -c -o "$name.o" "$name.S"; fi
"$OBJDUMP" -d -r --x86-asm-syntax=intel "$name.o" > "$name.listing"
python3 ../one/lift_one.py "$name.listing" "b3l_$name" "$base" "Lifted_$name.lean" "Lifted_$name" --object "$name.o"
python3 gen_code.py "$name" "Lifted_$name.lean.rows" "Code_$name.lean"
contract=$(python3 -c "import odec,re,sys; c=odec.contracts_of(odec.read_source(sys.argv[-1]))[0][sys.argv[1]]['head']; print(re.match(r'[\w.]+', next(r for w,r in c if w=='meets')).group(0))" "$name" "$source")
spec=$(python3 -c "import sys; print('Spec_' + sys.argv[1].split('.')[0].lower())" "$contract")
examples=$(echo "$spec" | sed 's/^Spec_/Example_/')
lake build "Code_$name" "$examples" Checks TrySem > "$name.try.build.log" 2>&1 || { grep -E "error" "$name.try.build.log" | head -n 5; echo "the examples of $name do not build"; exit 1; }
python3 try_fn.py "$source" "$name" "Lifted_$name.lean.rows" || { echo "$name: NOT shown to meet $contract on its examples (above)"; exit 1; }
echo "$name: tried on the examples of $contract in the machine model; not proved"
