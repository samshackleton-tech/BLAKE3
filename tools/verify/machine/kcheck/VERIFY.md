# Verify it yourself

You are handed a binary and told what it does. This page is how you find out for yourself, in seconds,
without believing whoever made it.

## Run it

You need Python 3 and this folder. Nothing is installed, nothing is downloaded, no solver runs.

    python3 verify.py programs/lz4/odelz4.o        # an LZ4 decoder and two encoders: 0.3 s
    python3 verify.py programs/utf8/odeutf8.o      # a UTF-8 validator: 0.03 s
    python3 verify.py programs/frame/odeframe.o    # a function that calls two others: 0.25 s
    python3 verify.py b3hashr.o                    # BLAKE3, with its AVX-512 kernels: 16 s (8 s with pypy3)

It prints three things:

1. **What is shown**: the public contract of each function in the file, a few lines each. For example:

       contract ode_lz4_decode(out: cap bytes, cap: number, input: n bytes, n: number) {
           requires apart(out, input)
           requires n < 72057594037927936
           returns if failed(lz4(input)) || len(lz4(input)) > cap then NO else len(lz4(input))
           ensures out[0 .. len(lz4(input))] = lz4(input) if !failed(lz4(input)) && len(lz4(input)) <= cap
           trace depends on input
           stack 104
       }

2. **The verification**: each function's instructions, read from the file's own bytes, meet its contract
   on every input the contract allows; or `NOT shown`. And one line about the specification: the
   definitions the contracts speak through come to an end on everything the contracts allow (so a
   contract says something of every input), or that this is not shown.
3. **What ran**: the files of this folder that were loaded to reach that, with their sizes and digests.

Exit status 0 means shown.

## What you must read

- **The contract** (printed), and **the definitions it names**: `python3 verify.py FILE` prints the
  contract; the whole specification is `programs/NAME/NAME.spec` (`blake3.spec` for the hash), 12 to 185
  lines. `lz4(input)` means what `lz4.spec` says it means, which is the LZ4 block format written as equations.
- **What a contract means**: `CONTRACT.md`, one page. The short of it: a contract is a closed world. The
  function reads and writes nothing it does not name, returns, and what a line does not allow is not done.
- **What a specification's text means**: `LANGUAGE.md`, one page.

The specification can be **your own copy** (`python3 verify.py FILE YOUR.spec`) or the one the file carries.
If you use the file's, read it: the maker wrote it, and the verification says the code meets *that text*.

You do not read the proof, the lemmas, the contracts of the functions inside, or the source. They are in the
file; the verifier uses them and trusts none of them. A wrong one makes the verification fail.

## What you rely on

- **The files listed under "What ran"**: about 3,500 lines of Python for the hash, 4,000 for the other
  programs (they load more than they use). None of them searches for anything. They hold: how the file's bytes are read as instructions; what
  each instruction does; how a specification is read and worked out; how a proof of arithmetic is added up.
  They are tested and audited, **not proved**: that is the weakest part of this, and the work under way is
  to make that list short enough to read (`DESIGN.md`, "Where it stands").
- **Python**, and that the processor does what its manual says.
- Nothing else. Not the compiler that made the binary, not the assembler, not the linker, not the source,
  not the prover that found the proof: the verifier reads the bytes that will run.

What the audits are (`README.md`, "What has been done to find it wrong"): every single bit of every
function's code is changed in turn, 353,192 changes; each change the verifier still accepts (18,069) is
run on a processor against an independent implementation. None accepted so far behaves otherwise. The
lemmas have an audit of their own: each changed in one place, and each specification they speak of
changed in one place, judged by the specification worked out on numbers. That is evidence, not proof.

## If it says NOT shown

Not shown is not false: the verifier may be unable to show something true. On an x86-64 Linux machine the
tool then tries to settle it: it works the contract out on numbers, runs the binary's code on the same
inputs, and if they differ it prints the input:

      ode_lz4_decode: NOT shown: ...
          FALSE (ode_lz4_decode, case 0): returned 0, specification says 18446744073709551615
            input: out(out, cap=0), cap=0, input[1]=00, n=1

A FALSE is a fact you can check by hand. "Not refuted" settles nothing.

## A second opinion on one part

The proofs of arithmetic a file carries can be added up by a second program that shares nothing with the
first (C, 310 lines, its own whole numbers):

    cc -O2 -o varith2 varith2.c -lz && ./varith2 b3hashr.o programs/*/ode*.o
    varith2: 7850 proofs of arithmetic: 7850 add up to "these rows cannot all hold"

It says each proof adds up; it does not say the proof was used where its starting facts were known (the
first verifier's part). It is the beginning of a second verifier, not one.

## What it does not show

- **Speed**, and anything else a contract does not say. (A `trace` line says what the timing may depend on.)
- **That your program reaches these bytes.** The verification is of the function at a name in the file. That
  the calls in a program linked with it go there, and not to something else of the same name, is not shown.
- **The hash on AArch64**, or with an incremental interface: x86-64, one call.

## Why not Lean, Coq, or an SMT solver?

We began in Lean: the same hash, proved from its machine code. It worked and did not scale: a function took
days, the 32-lane kernel's proof ran 37 minutes on one part without ending, and a proof was of one build's
bytes, so a compiler flag undid it. (Figures from our notes of those weeks; `tools/verify/machine/lang` has
the proofs.) The work was never missing mathematics, which a library could have
supplied; it was stepping through thousands of instructions inside a general-purpose prover, where each
step is a large rewrite of a large term. A verifier made for this one job does the same stepping as plain
computation, and the code is written to be easy for it, as code is written to be fast.

And what a reader relies on: to believe a Lean proof he relies on Lean's kernel and the part of its library
his statement rests on, thousands of lines he did not choose. Here the aim is a list short enough to read.
We are not there (see above), and Lean stays welcome where it is strong: as one optional way to check the
small verifier itself.

An SMT solver searches; its yes is hard to check by other means, and its no is silence. Here the search
(which facts of arithmetic to add up) is done by a prover whose output the verifier checks by adding:
the proofs travel in the binary, a few kilobytes.
