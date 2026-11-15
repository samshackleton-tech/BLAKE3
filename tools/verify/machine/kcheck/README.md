# kcheck: a checker made for one job (a trial, November 14, 2026)

**Not a proof, and checked by no proof assistant.** A trial of whether a small program made for exactly this
job can show that a wide kernel's machine code computes BLAKE3, for every input, in seconds and with nothing
written by hand for each kernel. The programs here are what would have to be trusted; the second half of this
page is what has been done to find where they are wrong, and what that found.

## What it shows today

From the library's own assembly sources (`c/blake3_avx512_32.S`, `c/blake3_output16.S`), assembled, the
objects' bytes read directly:

| kernel | instructions run | time | result |
|---|---|---|---|
| `blake3_servil_avx512_k32` (32 chunks, counter + lane) | 32,203 | 0.6 s | the 32 chaining values stored are the specification's |
| `blake3_servil_avx512_p32` (its second entry, counter fixed) | 32,195 | 0.6 s | the same |
| `blake3_servil_avx512_p16` (16 parent nodes) | 1,070 | 0.02 s | the 16 chaining values stored are the specification's |
| `blake3_servil_output16` (16 compressions, each lane its own chaining value, block, length and flags) | 1,193 | 0.03 s | the same |

"For every input": the key, the counter, the mode flags and the inputs' bytes are variables (for `output16`,
every lane's chaining value, block, length byte and flags byte). Times on an Apple M6. The first three as
clang 21 assembles them and as GNU as 2.46 does (they pad the loops differently) both pass.

The fourth kernel was added to see what a new one costs: three instruction forms in the decoder (a 256-bit
load, a byte read, a 32-bit store), four cases in the checker, a five-line specification, and it passed on
its first run, a few minutes after the start. Its audit (below) then ran clean, and `kremove.py` on it found
eight instructions whose results nothing reads (BLAKE3 #398).

    python3 kcheck.py k32 --object OBJECT [--anchor ../../../../test_vectors/test_vectors.json] [--mutants]
    python3 test_kcheck.py            # all of it from the sources, with the controls: 9 tests, 12 s

## Every number of blocks: a proof that is found, then checked (`kloop.py`, November 15)

The table above is each kernel for one number of blocks (16, or 1), run to its end. `kloop.py` shows K32, P32
and P16 for **every** number of blocks `n >= 1` and every value of the four flag bytes (flags, start, end,
last length): the kernels' whole interface. It is a first trial of how proofs could be made for code with
loops: the proof is a small text the prover finds, and the checker reads it and does no searching.

- **The specification is a small machine**, a lane at a time: state 0 is the key; state b+1 is
  `compress(state b, block b, counter, length, flags)` with the start byte or-ed in for block 0, and the end
  byte and the length byte for the last block; what is stored is state n.
- **A proof** names one place in the code, the head of the loop over blocks, and says what each register and
  frame cell holds there when b blocks are done: kept as it was after the first block, a number `c + cn*n +
  cb*b`, or a word of the specification's state. K32's, with every name the checker does not need taken out
  (`proofs/k32.json`, 1,088 bytes): the place `+0x133`; `r13 = n - b`; `r14 = 64*b`; six registers kept (the
  flags, the stack and frame pointers, the inputs' table, the output's address); `zmm0` to `zmm15` hold the
  state's eight words for lanes 0-15 and 16-31; four frame cells (the counters) kept.
- **The checker** runs the code from its entry through the first block; then from the place, for an unknown
  b and an unknown state, along every path to the place again or to the return; and compares terms by
  identity with the specification's next state. That is Floyd's method. "Is this the last block?" is decided
  from two linear facts (`b >= 1`, `b <= n-1`) by adding them up.
- **The prover** runs the loop twice, compares the second and third visits of the place, guesses, and weakens
  the guess where the checker refuses. Nothing it does is trusted.

| kernel | proof found in | proof checked in | paths of the step |
|---|---|---|---|
| K32 | 0.36 s | 0.18 s | one back to the place, one to the return |
| P32 | 0.37 s | 0.18 s | the same |
| P16 | 0.18 s | 0.09 s | the same |

What was done to find it wrong: `test_kloop.py` (25 changed kernels: no proof is found for any, and the true
proof is refused on each; 7 wrong proofs are refused on the true kernel; an entry is refused against the other
entry's specification). The true kernels on a processor on the same claim (`kflip_native.c … any`: 1 to 20
blocks, any flag bytes, any counter, anything in the packed word's upper half): 5,000 cases each, as BLAKE3.
And the single-bit audit with a processor as judge (`kflip.py --general`; "accepted" = a proof is found and
checked):

| kernel | changes | stopped by the decoder | refused (no proof) | accepted | of those, as BLAKE3 on the processor |
|---|---|---|---|---|---|
| P16 | 22,144 | 14,340 | 7,591 | 213 | 213 (1,000 cases each) |
| K32 | 35,824 | 22,321 | 11,753 | 1,750 | 1,750 |
| P32 | 35,824 | 22,321 | 11,625 | 1,878 | 1,878 |

With the whole interface in the specification, what the contract "does not see" in P16 falls from 142
accepted changes to 13 (a larger frame, a 64-bit form of a 32-bit move): the statement now says what the code
does.

What this trial does not show: more than one loop that needs a proof (the seven rounds inside are run, not
proved by induction); a loop whose state is a data structure in memory; calls; code that is not a kernel.
The proof's form is made for this shape of loop. The checker is `kcheck.py` and `kdecode.py` with 300 lines
more, in Python, unverified.

## The parts

| file | lines | what it is |
|---|---|---|
| `kdecode.py` | 337 | reads the ELF object (sections, symbol, relocations) and decodes the instruction forms the kernels use, and no others; no disassembler |
| `kcheck.py` | 594 | runs the instructions on symbolic values, builds the specification with the same term constructors, compares |
| `kcheck_cross.py` | 109 | kcheck's reading of each instruction against the Lean model's processor-validated test vectors |
| `kflip.py`, `kflip_native.c`, `kflip_thunk.S` | 194 + 153 + 63 | the audit below: every single-bit change of a kernel, and the processor's word on each one accepted |
| `kloop.py`, `test_kloop.py` | 491 + 94 | every number of blocks: the prover, the proof's form, the checker by induction; its tests |
| `kremove.py` | 41 | which instructions can be replaced by a no-op with the contract still met: for a person to read |
| `test_kcheck.py` | 136 | the four kernels and the controls, from the sources |

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

## What has been done to find it wrong

1. **Changed kernels** (`--mutants`): 15 of 15 refused (rotations, operands, the carry's mask, a message offset,
   a store's offset, a shuffle, a flag, a saved register, the frame's bound, the block step, one entry of the
   schedule table). A kernel against another kernel's specification is refused.
2. **The specification against an official vector** (`--anchor`): the terms the code is compared with,
   evaluated on the 2048-byte test vector (two chunks, then the parent as root), give the vector's hash.
3. **Its reading of each instruction against the Lean model's** (`kcheck_cross.py`): the model's test vectors,
   which a processor agreed with (`one/cross_one.sh`): 2,925 vectors of 585 instruction forms, 0 differ. 215
   forms are not covered: SSE and XMM forms kcheck does not know, and forms it reads in its own domains (the
   stack's alignment, `lea`, stores of general registers).
4. **Its decoder against the lifter** (`kdecode.py --compare`): the same rows as `llvm-objdump` through
   `one/lift_one.py`, instruction for instruction: the kernels as compiled from the Ode sources (702 and 460
   instructions) and the library's own (`test_kcheck.py`, where there is an objdump).
5. **Every single-bit change of each kernel's code, with a processor as the judge** (`kflip.py --native`). Each
   bit of the kernel's bytes in the object is flipped in turn and the object read and checked as the true one
   is. A change the checker accepts is then linked with BLAKE3 written out in C and run on an AVX-512
   processor on 1,000 or 2,000 random inputs the contract allows: the chaining values, every byte beside the
   output, the inputs, their table, the key, the kept registers and the stack pointer are compared, and each
   thing the kernel is given lies between two pages that fault. An accepted change the processor tells from
   BLAKE3 is an error of the decoder or the checker.

   | kernel | changes | stopped by the decoder | refused by the checker | accepted | of those, as BLAKE3 on the processor |
   |---|---|---|---|---|---|
   | P16 | 22,144 | 14,340 | 7,462 | 342 | 342 (1,000 cases each) |
   | K32 | 35,824 | 22,321 | 11,748 | 1,755 | 1,755 (1,000 cases each) |
   | P32 | 35,824 | 22,321 | 11,620 | 1,883 | 1,883 (1,000 cases each) |
   | `output16` | 29,384 | 17,736 | 11,254 | 394 | 394 (2,000 cases each) |

   (Threadripper PRO 7975WX, clang 21.1.8's objects, the checker and decoder as they are in this commit;
   19 s for P16, 51 s for `output16`, 17 minutes each for K32 and P32, 20 at a time, the four at once.
   No change ended without a verdict. Controls in each run: the unchanged object is accepted and runs as BLAKE3;
   asked for a block more than its inputs hold it faults; a refused change of a rotation does not run as BLAKE3.)

   Where the accepted changes of the first three are: in the no-ops an assembler pads with (148), in the
   operand of a prefetch (2,560), in the four bytes of a field the linker fills (832), and 440 elsewhere, of two kinds
   (`kflip.py --detail` lists each with what it became; `audit/`):
   - code the contract never reaches, or whose result it never uses. The kernels take 1 to 16 blocks, any
     start and end flags and either entry, and the contracts fix them: the jump that P32's entry takes is never
     taken from K32's and its target may be anything; P16's loop over blocks runs once and its step may be
     anything.
   - another instruction with the same effect on the values the contract allows: the 32-bit form of an
     operation on a small number, a register that holds the same value at that point (`rsi` for `rsp`), a
     larger frame still within the stack's bound.

   `output16`'s 394: padding 48, linker fields 128, and 218 elsewhere, 148 of them in the eight shuffles
   whose results nothing reads.

   For scale, of 400 changes a kernel that were stopped or refused, 1.5 to 7% run as BLAKE3 on the same
   inputs all the same: the checker refuses what it cannot show, as it should.

**What the fifth audit found** (each fixed, each now a test in `test_kcheck.py`):

- *The checker accepted a kernel that faults.* A frame of `0x101` to `0x120` bytes (in place of `0x100`) left
  the stack pointer off the 64-byte boundary the aligned stores need; kcheck took the frame as aligned whatever
  its size. Six such changes were accepted and crashed on the processor. The frame must now be whole cells.
- *A changed kernel ran the checker out of memory.* A sum that adds a register to itself in a loop doubles a
  flat term each turn. A sum or xor is now at most 64 terms (BLAKE3's widest is 57), and a longer one is refused.
- *An addition of 32 bits was computed in 64*, and a push, pop or return did not ask that the stack pointer be
  among the saved registers. No accepted change turned on either; both are now as the processor does it.
- *The decoder read encodings no assembler writes* (a REX bit an instruction does not use, a scale with no
  index, `EVEX.R` beside an opcode digit) as the instruction without them: 277 accepted changes of P16 alone.
  What a processor does with such bytes was not tried and is not a question to rest on: they are now stopped.

Before these fixes the first audit (cross-checking, item 3) had found two more: `vzeroupper` read as a no-op and
an 8-bit `or` read as 32 bits.

## What it rests on (what a reader must trust or check)

- `kdecode.py` and `kcheck.py`, 931 lines, and Python.
- That the regions are apart (the contract's own condition: the stack and the output apart from everything).
- One arithmetic fact taken as the specification's form of a lane's counter: low word + index, high word + carry.
  Lean proves it equal to the 64-bit counter plus the index (`lang/K32Lemmas.lean`, `counter_lo`, `counter_hi`);
  the processor runs of item 5 put a quarter of their cases just below a carry.
- It knows only the instruction forms these kernels use, and control flow that numbers decide (the contracts fix
  the block counts: 16 and 1). A loop whose count is an input would need an invariant: not here.
- The audits are tests, not proofs: single-bit changes, random inputs. A fault that needs two changed bits, or
  an input no random draw makes, is not excluded by them.

## Beside the Lean proofs of the same kernels

| | by hand in Lean | kcheck |
|---|---|---|
| P16 | proved (`Proof_p16.lean`); about 7 hours of work with the model's widening, 175 Lean checks; checking it again takes 4 to 9 minutes on the workhorse | 0.02 s; written for it: one line in `KERNELS` and a 3-line specification function |
| K32 | the round, the round loop, the counters and the loads proved in 3 hours; an estimated 15 hours more | 0.6 s |
| P32 | not attempted | 0.6 s; written for it: one line in `KERNELS` |
| `output16` | not attempted | 0.03 s; a few minutes' additions (above) |
| what is trusted | Lean's kernel, the model (cross-checked on processors), `bv_decide`'s axioms, the lifter (`llvm-objdump`) | these two programs |
| usable by a caller's Lean proof | yes | no: a caller's theorem would name the kernel's contract as a hypothesis this checker discharges |

Also tried the same day: SAW 1.6 on P16 with a Cryptol specification stops at the kernel's first AVX-512
instruction ("Could not decode instruction 62d2").

## Ways to make it trusted (undecided)

1. Write it in Lean and prove it sound once against `one/Machine.lean`; each kernel is then a theorem by
   evaluation. The cost is that one proof.
2. Keep it a small independent program, with the audits above kept running and a second implementation
   written apart from the first. Smallest reading list; no proof assistant.
3. Have it emit a certificate (the terms after each instruction) that a proof assistant checks step by step.
