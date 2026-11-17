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
           requires no_overlap(out, input)
           requires n < 72057594037927936
           returns if failed(lz4(input)) || len(lz4(input)) > cap then NO else len(lz4(input))
           ensures out[0 .. len(lz4(input))] = lz4(input) if !failed(lz4(input)) && len(lz4(input)) <= cap
           trace depends on input
           stack 104
       }

2. **The verification**: each function's instructions, read from the file's own bytes, meet its contract
   on every input the contract allows; or `NOT shown`. And one line about the specification: the
   definitions the contracts speak through come to an end on everything the contracts allow (so a
   contract says something of every input). Where that is not shown, the file is not shown.
3. **What ran**: the files of this folder that were loaded to reach that, with their sizes, and the `b3sum`
   command that names them (a program cannot vouch for itself; `--digests` prints their BLAKE3 hashes here
   all the same).

Exit status 0 means shown.

A reader is told, of each public contract, whether it is met, and the counts: nothing its maker chose that
he need not read. The functions inside by name, where each is, how long each took and why one is not shown
are a maintainer's: `python3 verify.py FILE --maintain`.

## What you must read

- **The contract** (printed), and **the definitions it names**: `python3 verify.py FILE` prints the
  contract; the whole specification is `programs/NAME/NAME.spec` (`blake3.spec` for the hash), 12 to 185
  lines; `python3 verify.py FILE --show-spec` prints the one the file carries. `lz4(input)` means what `lz4.spec` says it means, which is the LZ4 block format written as equations.
- **What a contract means**: `LANGUAGE.md`, part 2. The short of it: a contract is a closed world. The
  function reads and writes nothing it does not name, returns, and what a line does not allow is not done.
- **What a specification's text means**: `LANGUAGE.md`, part 1. (The two parts are one page.)

The specification can be **your own copy** (`python3 verify.py FILE YOUR.spec`) or the one the file carries.
If you use the file's, read it: the maker wrote it, and the verification says the code meets *that text*.
Its name is the BLAKE3 hash printed beside it, all 64 digits (`b3sum` gives the same): compare two of them
with a tool, not by eye. What a file carries is printed with every control character written out (`\x1b`):
a maker's comment cannot move your terminal's cursor.

You do not read the proof, the lemmas, the contracts of the functions inside, or the source. They are in the
file; the verifier uses them and trusts none of them. A wrong one makes the verification fail.

## What you rely on

- **The files listed under "What ran"**: about 3,100 lines of Python for the hash, 4,300 for the other
  programs (they load more than they use). None of them searches for anything. They hold: how the file's bytes are read as instructions; what
  each instruction does; how a specification is read and worked out; how a proof of arithmetic is added up.
  They are tested and audited, **not proved**: that is the weakest part of this, and the work under way is
  to make that list short enough to read (`DESIGN.md`, "Where it stands"). On November 17, 2026 six faults
  were found in them by reading, each one a way to have a wrong file shown (a function that wrote below its
  argument; a kernel that read its constants from an address of the maker's choosing; a register taken to
  hold what a call had written over; two unknown registers taken for one; a layout in the proof that let
  writes run past a caller's room or deleted a path from checking; a sequence whose value changed shape
  being named by its first value). They are closed, and the files that were wrongly shown are kept as tests;
  the audits, which change one bit at a time, could not have found any of them (`README.md`, last section).
  There may be more: the reading is finished, but reading is not a proof.
- **Python**, and that the processor does what its manual says.
- Nothing else. Not the compiler that made the binary, not the assembler, not the linker, not the source,
  not the prover that found the proof: the verifier reads the bytes that will run.

What the audits are (`README.md`, "What has been done to find it wrong"): every single bit of every
function's code is changed in turn; in the last whole run, of the state before the last two holes were
closed, 355,704 changes across the audit's steps, 18,278 accepted, each run on a processor against an
independent implementation, none behaving otherwise. The lemmas have an audit of their own: each changed
in one place, and each specification they speak of changed in one place, judged by the specification
worked out on numbers. `gate.py` runs the adversarial copies and every shipped file in five minutes
before a merge or a post; the whole sweep is a soak. That is evidence, not proof.

## If it says NOT shown

Not shown is not false: the verifier may be unable to show something true. On an x86-64 Linux machine the
tool then tries to settle it: it works the contract out on numbers, runs the binary's code on the same
inputs, and if they differ it prints the input:

      ode_lz4_decode: NOT shown
          FALSE (ode_lz4_decode, case 0): returned 0, specification says 18446744073709551615
            input: out(out, cap=0), cap=0, input[1]=00, n=1

A FALSE is a fact you can check by hand. "Not refuted" settles nothing. Where and why it was not shown:
`--maintain`.

## A second opinion on one part

The proofs of arithmetic a file carries can be added up by a second program that shares nothing with the
first (C, 310 lines, its own whole numbers):

    cc -O2 -o varith2 varith2.c -lz && ./varith2 b3hashr.o programs/*/ode*.o
    varith2: 7850 proofs of arithmetic: 7850 add up to "these rows cannot all hold"

It says each proof adds up; it does not say the proof was used where its starting facts were known (the
first verifier's part). It is the beginning of a second verifier, not one.

## What it does not show

- **Speed**, and anything else a contract does not say. (A `trace` line says what the timing may depend on.)
- **What else is linked into your program.** A shipped file here is an object to be linked, and it is read
  only in one shape: its code and its proof and nothing else a linker would take, and no name but those of
  functions each shown to meet a contract (a copy with a second function hidden under a verified one's name
  is refused: `README.md`, "An object is read in one shape"). So a program linked with it reaches these
  bytes under these names, unless another file linked beside it gives a linker the same name: that is not
  shown. For an executable or a shared object made from one, the verification is of the functions found
  in it; how its names are resolved when it is loaded is not shown.
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
