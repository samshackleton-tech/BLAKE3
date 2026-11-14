# kcheck: a checker made for one job (a trial, November 14, 2026)

**Not a proof, and checked by no proof assistant.** A trial of whether a small program made for exactly this
job can show that a wide kernel's machine code computes BLAKE3, for every input, in seconds and with nothing
written by hand for each kernel. `kcheck.py` is what would have to be trusted.

## What it shows today

| kernel (as shipped, lifted by `one/lift_one.py`) | instructions run | time | result |
|---|---|---|---|
| `blake3_servil_avx512_k32` (32 chunks, counter + lane) | 32,203 | 0.58 s | the 32 chaining values stored are the specification's |
| `blake3_servil_avx512_p32` (its second entry, counter fixed) | 32,195 | 0.58 s | the same |
| `blake3_servil_avx512_p16` (16 parent nodes) | 1,070 | 0.02 s | the 16 chaining values stored are the specification's |

"For every input": the key, the counter, the mode flags and the inputs' bytes are variables. Times on an Apple M6.

Controls:
- 15 of 15 changed K32 kernels are refused (`--mutants`: rotations, operands, the carry's mask, a message
  offset, a store's offset, a shuffle, a flag, a saved register, the frame's bound, the block step, one entry of
  the schedule table), each in about 0.6 s. A kernel checked against another kernel's specification is refused.
- The specification written in `kcheck.py`, evaluated on the official 2048-byte test vector (two chunks, counters
  0 and 1, then the parent as root), gives the vector's hash (`--anchor`).
- `kcheck_cross.py`: kcheck's own reading of each instruction against the Lean model's test vectors, which a
  processor agreed with (`one/cross_one.sh`): 2,925 vectors of 585 instruction forms, 0 differ. When first run it
  found two deviations (`vzeroupper` read as a no-op; an 8-bit `or` read as 32 bits): the first is now modelled,
  the second refused. 215 forms are not covered by it: SSE and XMM forms kcheck does not know, and the forms it
  reads in its own domains (the stack's alignment, `lea`, stores of general registers).

## How

1. Every instruction is run on symbolic values. A general register is a number, an address in a named region
   plus a number, or the packed flags by bytes. A ZMM register is sixteen 32-bit terms. Memory is named regions:
   the aligned frame, the saved registers, the table of inputs' addresses, the inputs, the key, the object's
   read-only data, the output.
2. The specification (BLAKE3's compression, a chunk, a parent node: about 40 lines, from the paper) is built
   with the same term constructors.
3. Terms are interned, and sums and xors are kept flat and sorted, so two terms are equal when they are the same
   node. The comparison is of 256 (or 128) node numbers. No solver.

Checked beside the result: every read is of something the contract gives; every write is to the frame, the
saved registers or the output; aligned stores are on aligned addresses; the stack used is within the contract's
4096 bytes; the registers a callee keeps are restored and the return goes to the return address; every branch
is decided by numbers and every address is a region and a number, so the trace of addresses and branches is the
same for every input.

## What it rests on (what a reader must trust or check)

- `kcheck.py` itself, 528 lines, and Python.
- The lifter (`llvm-objdump`'s reading of the object), as the Lean proofs do.
- That the regions are apart (the contract's own condition: the stack and the output apart from everything).
- One arithmetic fact taken as the specification's form of a lane's counter: low word + index, high word + carry.
  Lean proves it equal to the 64-bit counter plus the index (`lang/K32Lemmas.lean`, `counter_lo`, `counter_hi`).
- It knows only the instruction forms these kernels use, and control flow that numbers decide (the contracts fix
  the block counts: 16 and 1). A loop whose count is an input would need an invariant: not here.

## Beside the Lean proofs of the same kernels

| | by hand in Lean | kcheck |
|---|---|---|
| P16 | proved (`Proof_p16.lean`); about 7 hours of work with the model's widening, 175 Lean checks; checking it again takes 4 to 9 minutes on the workhorse | 0.02 s; written for it: one line in `KERNELS` and a 3-line specification function |
| K32 | the round, the round loop, the counters and the loads proved in 3 hours; an estimated 15 hours more | 0.58 s |
| P32 | not attempted | 0.58 s; written for it: one line in `KERNELS` |
| what is trusted | Lean's kernel, the model (cross-checked on processors), `bv_decide`'s axioms, the lifter | this program, the lifter |
| usable by a caller's Lean proof | yes | no: a caller's theorem would name the kernel's contract as a hypothesis this checker discharges |

Also tried the same day: SAW 1.6 on P16 with a Cryptol specification stops at the kernel's first AVX-512
instruction ("Could not decode instruction 62d2").

## Ways to make it trusted (undecided)

1. Write it in Lean and prove it sound once against `one/Machine.lean`; each kernel is then a theorem by
   evaluation. The cost is that one proof.
2. Keep it a small independent program: cross-check its instruction semantics on processors directly, write a
   second implementation, keep the controls. Smallest reading list; no proof assistant.
3. Have it emit a certificate (the terms after each instruction) that a proof assistant checks step by step.

    python3 kcheck.py k32 ROWS DATA --anchor ../../../../test_vectors/test_vectors.json --mutants
