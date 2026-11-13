#!/bin/sh
# The proof alone, again: write Proof_NAME.lean from the source and the rows already lifted, and have Lean check it.
# (The examples were tried by prove_fn.sh; this is for a change to lemmas or to the proof generator.)
# usage: [SOURCE=.. ODEMOD=..] reproof.sh NAME
set -eu
name=$1; source=${SOURCE:-hasher.ode}
python3 prove_fn.py "$source" "$name" "Lifted_$name.lean.rows" "$name.layout" "Proof_$name.lean"
if lake build "Proof_$name" > "$name.build.log" 2>&1 && ! grep -q -E "error|sorry" "$name.build.log"; then
  echo "the compiler's proof of $name: checked (the proof alone, again)"
else
  grep -E "^error" "$name.build.log" | head -n 8
  echo "the compiler's proof of $name: NOT checked"; exit 1
fi
