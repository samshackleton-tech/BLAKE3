# kcheck: a specification, a binary, and a checker a reader runs (a trial, November 14 and 15, 2026)

**Not a proof in a proof assistant, and checked by none.** A trial of another way to the goal of BLAKE3 #361:
to hand a skeptical reader a specification, a binary and a proof, such that he checks for himself, in
seconds, that the binary meets the specification, relying on little.

The scope is narrow on purpose (Sam, November 15). The code is new code written for this, not existing code.
The mathematics is what the code needs, not all of mathematics. The programs are those that can be written
this way, not all programs. The languages are our own.

- **The specification says what the hash is, not how to compute it** (`blake3.spec`: 147 lines with its
  comments, and an 18-line claim). Definitions by equations, in a language made for specifications of this
  kind: the compression function; a chunk as a sequence (`h[0] = key`, `h[b + 1] = compress(h[b], ...)`);
  the tree by the paper's own rule (the left part holds `the greatest power of two k with 1024 * k < len`
  chunks; a tree is its two parts' trees under a parent). Evaluated on numbers it gives the 105 official test
  vectors. Nothing in it is a stack, a counter of subtrees, or a loop.
- **The code is written to be proved** (`hash.ode`, in Ode), as code is written to be fast: in the
  specification's shape. `subtree` splits its bytes by the same rule and calls itself on each part; its loops
  run a number of times the paths fix.
- **The proof is whatever the checker needs beside the binary.** Here: what each function inside is claimed
  to do (`proofs/inner.spec`). For the hash that is all: there is no proof text to write. (The library's wide
  kernels loop over a number of blocks that is an argument: each has a place, which a prover finds.)
- **The checker does not search.** It runs each function's machine code on symbols along every path; a call
  is taken by the callee's contract (a call of itself by its own); what is left at the return is compared
  with the specification's definition, opened once. Terms are compared by identity, numbers by adding linear
  facts up. No solver.

What is shown, from the binary's bytes (`python3 check_all.py`: 15 functions, 2,780 instructions, 5.2 s on an
Apple M6):

- **`b3l_hashr`: BLAKE3 of a message of every length, under any key and flags** (the claim in `blake3.spec`),
  through `pad`, `chunk_node`, `node_out`, `wide32` and `subtree` of `hash.ode` and the library's kernels:
  the two one-block ones, and for a whole tree of 32 chunks the 32-lane chunk kernel and the 16-lane parent
  kernel. Nothing is assumed of a callee: each is checked against its own bytes.
- The library's wide kernels by themselves (K32, P32 and P16 for every number of blocks; `output16`).
- An earlier trial (`push`, `merge`, `add` of a stack of subtrees) against an algorithm, not the
  specification.

What a reader relies on: `blake3.spec`, which he reads; the checker, 3,772 lines of unverified Python for the
hash (4,340 with the stack's checker); the processor doing what the checker takes each instruction form
to do; Python. Most of this page is what has been done to find where the checker is wrong,
and what that found.

## The specification: `blake3.spec`

    python3 ode.py blake3.spec --vectors ../../../../test_vectors/test_vectors.json      # 105 vectors, 6 s
    python3 test_ode.py

The language (its summary is at the top of the file): numbers, 32-bit words, 64-bit counters, lists, bytes,
records, `if c then a else b`, and

    def NAME(args) { let X = E ... VALUE }                     a definition: equations and a value
    let s[0] = A   let s[i + 1] = F(s[i])                      a sequence, by its first value and each next
    sequence NAME(args) { h[0] = A   h[b + 1] = F(h[b])   for b in 0..n }
    the least number n in a..b with C                          a number by what is true of it
    the greatest power of two k with C

Nothing is given twice and nothing loops; a definition may be of itself on smaller things. The tree:

    def left_chunks(bytes) { the greatest power of two k with 1024 * k < len(bytes) }

    def children(key, flags, t, bytes) {
        let k = left_chunks(bytes)
        subtree(key, flags, t, bytes[0 .. 1024 * k]) ++ subtree(key, flags, t + k, bytes[1024 * k .. len(bytes)])
    }

    def subtree(key, flags, t, bytes) {
        if len(bytes) <= 1024 then node_value(chunk_node(key, t, flags, bytes), 0)
        else compress(key, children(key, flags, t, bytes), counter(0), 64, flags | PARENT)
    }

and the claim, which is all of the contracts a reader need read:

    contract b3l_hashr(out: cv, input: len bytes, len: number, key: cv, flags: byte, plat: any) {
        leaves out = hash_words(key, flags, input)
        stack 9216 + 384 * bits(len / 1024)
        needs sse41
        needs avx512 if plat == 5
    }

(`needs`: it runs SSE4.1 instructions, and AVX-512 instructions only where `plat` is 5.)

- `ode.py` (638 lines) reads the text and evaluates it over an algebra of words. On numbers: the official
  vectors, at every length, for the hash, the keyed hash and key derivation.
- `kspec.py` (480 lines) is the other algebra, for the checkers: words are terms; a number may depend on a
  count, and a comparison of such numbers is decided from the code path's facts or the evaluation stops;
  bytes may be some of a message of unknown length. What cannot be worked out on a path (the tree over bytes
  whose count is not known) is named by what it is of, and two names are one thing when they are the same.
- `test_ode.py`: 21 single changes of the text (a rotation, the permutation, a flag, the counter, the root,
  the rule for the left part, the padding) are each told from BLAKE3 by the vectors. Three more are of the
  parts of `chunk` that the hash's own definitions do not use (an end flag and a last length inside the
  sequence: the wide kernels' contracts use them); they are told by a chunk's value computed both ways.

**What the specification is not.** It was first "a program that runs": machines whose turns the code's loops
followed, the hash by a stack (then by Sam's levels) of subtrees. A reader would have had to see that such an
algorithm is BLAKE3. Now the algorithm is in the code only, and the code is compared with the definition.
(One algorithm remains, in `proofs/inner.spec` and marked so: the stack machine three functions of the
earlier trial follow.)

## The code: `hash.ode`, written to be proved

190 lines of Ode (the language of `lang/`; its compiler is `lang/odec.py` and `lang/Lang.lean`, and prints
assembly). Six functions:

| function | instructions | what its contract says it leaves (`proofs/inner.spec`, but for the last) |
|---|---|---|
| `pad(block, src, n)` | 39 | `block = padded(src)` |
| `chunk_node(nd, input, len, t, flags, plat)` | 81 | `nd = chunk_node(nd.h, t, flags, input)` |
| `node_out(out, nd, root, plat)` | 58 | `out = node_value(nd, root)` |
| `wide32(out, input, kf, t)` | 259 | `out = subtree(kf.key, kf.flags, t, input)`, for 32,768 bytes |
| `subtree(out, input, len, kf, t, plat)` | 150 | `out = subtree(kf.key, kf.flags, t, input)` |
| `hashr(out, input, len, key, flags, plat)` | 132 | `out = hash_words(key, flags, input)` |

What "written to be proved" meant, each a choice the programmer made as one makes choices for speed:

- **The tree is a recursion, as in the specification.** `subtree` finds the count of chunks for its left
  part, calls itself on the two parts, and compresses the two values. Its own contract is what the checker
  takes at those calls. An earlier form of this code kept a stack of subtrees (and one after it, levels): to
  show that such a thing makes the tree takes an induction over counts and their bits, which Lean did by
  lemmas written by hand. Here there is nothing to show: the code's two calls are the definition's two parts.
- **The wide kernels are a leaf of the recursion.** A part of exactly 32 chunks, on a machine with AVX-512,
  goes to `wide32`: the 32-lane chunk kernel, then five rounds of the 16-lane parent kernel (16, 8, 4, 2, 1
  parents). The checker opens the specification's `subtree` down to those 32 chunks and their 31 parents,
  and it is the term the kernels' contracts give. No new idea was needed, and nothing about trees.
- **Every loop runs a number of times that the paths fix**: a block's 64 bytes, a chunk's 16 blocks, the 54
  doublings that find the left part's count. The checker runs them; none needs an invariant.
- **Six arguments**, which the calling convention carries in registers: the key and the flags travel as one
  record (`kf`).
- **The stack is bounded by the length**: `subtree` may use `8704 + 384 * bits((len - 1) / 1024)` bytes, a
  level of recursion for each halving of the count of chunks (and the wide kernels' frames).
- **What the processor must have is in the contract**: `needs avx512 if plat == 5`. A function may call one
  that needs AVX-512 only on a path where its own contract's condition holds, or hand it its own `plat`.

    python3 kfn.py subtree OBJECT          # the checker: the object's bytes, blake3.spec, proofs/inner.spec
    python3 test_kfn.py                    # 4 tests, 23 s

| function | paths to the return | instructions run | checked in |
|---|---|---|---|
| `pad` | 65 | 40,564 | 0.11 s |
| `chunk_node` | 31 | 1,740 | 0.43 s |
| `node_out` | 2 | 67 | 0.01 s |
| `wide32` | 1 | 2,383 | 1.6 s |
| `subtree` | 111 | 7,527 | 1.3 s |
| `hashr` | 109 | 4,544 | 1.0 s |

## The checker of functions: `kfn.py`

It follows one function at a time. Memory is in named regions of typed things: a chaining value, bytes (a
message's, of a length that is a symbol), a record whose `layout` is in `proofs/inner.spec`. A branch on
something the path does not fix splits the path, and each side keeps the fact; a path whose facts cannot all
hold is dropped. At a call the callee's contract is used: what it `asks` is shown from the caller's facts,
what it `leaves` replaces what was there (a definition's value there is not opened, only named: the caller's
own specification, opened later on the same path, finds the same name). At the return each thing the
contract says is left is the specification's value of it; the result, the registers a callee keeps, the stack
pointer and the stack used are checked; every write was within what the contract lets the function write.

The numbers' part (`klin.py`, 209 lines): a fact is a number known not to be below zero; one known both
ways is an equality and one of its symbols is replaced; a question is answered by adding facts up (Fourier
and Motzkin's elimination, in whole numbers). Halving and the low bit make a symbol with its two facts.

A loop is run: a path that jumps back to one instruction more than 100 times is refused. (The code's
earlier form, a stack of levels with a loop over them, was checked too, by a place for that loop: the name of
a machine of the specification and what the registers and the memory hold for any state of it, found by a
prover that comes to the loop three times. When the hash was written as the specification's own recursion no
loop needed a place, and that part of the checker was taken out.)

At a call the checker also shows that what the callee writes is apart from everything else the callee is
given the address of (the callee's own check took them to be apart), and that what the callee needs of the
processor the caller's contract allows there.

**What was done to find it wrong**, as for the kernels below:

- *Changed code* (`test_kfn.py`): every call left out and every branch turned round, in all five functions:
  each refused.
- *Changed text* (`test_kfn.py`): 22 changes of the contracts, the layouts and the specification: each
  refuses the function that met the text.
- *Every single-bit change of each function's code, with a processor as the judge* (`kfn_flip.py`,
  `khash_native.c`). A change for which a proof is found is linked with the other four functions and the
  kernels, and the whole hash is run on an AVX-512 processor against BLAKE3 written out in C another way (the
  reference's stack of subtrees): every length from 0 to 200, every seventh to 2,200, the three around each
  multiple of 1,024 up to 70 chunks, 200 random lengths to 300,000; the three modes' flags; both kernels; the
  message ending where a page that faults begins.

  | function | changes | stopped by the decoder | refused (no proof) | accepted | of those, as BLAKE3 on the processor |
  |---|---|---|---|---|---|
  | `pad` | 896 | 447 | 416 | 33 | 33 |
  | `chunk_node` | 2,280 | 1,080 | 1,100 | 100 | 100 |
  | `node_out` | 1,432 | 722 | 635 | 75 | 75 |
  | `subtree` | 5,008 | 1,999 | 2,641 | 368 | 368 |
  | `hashr` | 5,048 | 2,099 | 2,575 | 374 | 374 |

  (Threadripper PRO 7975WX. The judge is the whole hash: a change that is wrong only where no hash goes, a
  write beside what a callee may write that no later read meets, is not seen by it. The accepted changes are
  mostly of moves whose value is already where it goes, of the first values of variables that are given
  again before they are read, and of which register carries the platform word to a callee when it is a
  plain number that is not 5.)

**What that found.** Before the processor was asked, a run of changed instructions through the checker had
`hashl` (the earlier form) accept 80 changes of the moves that carry the platform word to its callees: a
callee's `calls F if plat == 5` was not carried to its caller, so a caller could hand a callee anything as
the platform, and the AVX-512 kernel be run where the caller's contract says it is not. The condition is now
carried: what a callee is given for `plat` must be the caller's own, or a plain number that is not 5, or
anything on a path where the caller's own condition holds.

**Speed, roughly.** One run on the Threadripper PRO 7975WX while 44 other processes loaded it (no timing
lock: not evidence, a first look), one thread, AVX-512, best of 7 rounds, GiB a second; `hashf` is the earlier
code (`levels/levels.ode`: levels over groups of 32 chunks), on the same kernels:

| bytes | `hashr` | `hashf` |
|---|---|---|
| 1,024 | 1.04 | 1.03 |
| 16,384 | 0.98 | 2.73 |
| 32,768 | 0.98 | 4.68 |
| 65,536 | 6.45 | 5.35 |
| 100,000 | 5.87 | 4.82 |
| 1,048,576 | 6.28 | 6.05 |
| 16,777,216 | 5.40 | 5.25 |

Where whole trees of 32 chunks carry the message the recursion costs nothing. At 32 KiB and below `hashr`
compresses one block at a time and `hashf` does not: parts of 2 to 31 chunks through the chunk kernel are the
next thing to write.

**The checker refused my first form of the wide leaf.** I had written `wide32(...)` and then `return 0`
inside an `if`; Ode's `return` gives the result and does not leave the function, so the code went on, hashed
the 32 chunks again by halves, and wrote the same value a second time. The checker's message was that `out`
at the return is not what the contract says: it holds the parent of two named halves where the contract's
tree had been named whole by the call. Right hash, wrong code; an `else` fixed it.

**Not shown:** that `hashr` ends (each loop is bounded and each call of itself is on fewer bytes, so it
does, but the checker shows only what holds if it returns, and the stack it uses on the way); that a
function without `needs avx512` holds no such instruction (the kernels' `needs` lines are taken from their
names); AArch64. Only whole trees of 32 chunks go to the wide kernels: a message of 32 KiB or less, and up
to the last 31 chunks of any message, are compressed one block at a time.

## The library's wide kernels, each run to its end (`kcheck.py`, the first trial)

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

    python3 kcheck.py k32 --object OBJECT [--mutants]
    python3 test_kcheck.py            # all of it from the sources, with the controls: 9 tests, 12 s

## Every number of blocks: a proof that is found, then checked (`kloop.py`, November 15)

The table above is each kernel for one number of blocks (16, or 1), run to its end. `kloop.py` shows K32, P32
and P16 for **every** number of blocks `n >= 1` and every value of the four flag bytes (flags, start, end,
last length): the kernels' whole interface. It is a first trial of how proofs could be made for code with
loops: the proof is a small text the prover finds, and the checker reads it and does no searching.

- **The specification is the sequence `chunk`**, a lane at a time: `h[0]` is the key; `h[b + 1]` is
  `compress(h[b], block b, counter, length, flags)` with the start byte or-ed in for block 0, and the end
  byte and the length byte for the last block; what is stored is `h[n]`.
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
| P16 | 22,144 | 14,191 | 7,740 | 213 | 213 (1,000 cases each) |
| K32 | 35,824 | 22,163 | 11,910 | 1,751 | 1,751 |
| P32 | 35,824 | 22,163 | 11,783 | 1,878 | 1,878 |

With the whole interface in the specification, what the contract "does not see" in P16 falls from 142
accepted changes to 13 (a larger frame, a 64-bit form of a 32-bit move): the statement now says what the code
does.

What this trial does not show: more than one loop that needs a proof (the seven rounds inside are run, not
proved by induction); a loop whose state is a data structure in memory; calls; code that is not a kernel.
The proof's form is made for this shape of loop. The checker is `kcheck.py` and `kdecode.py` with 300 lines
more, in Python, unverified.

## A stack in memory, a loop over it, calls: against an algorithm (`kglue.py`, November 15, an earlier trial)

(Before `hash.ode`: existing code, and a specification that was the code's algorithm. Kept for what its
audit found.) The same way on a hasher's stack of chaining values: `push`, `merge` and `add` of `lang/hasher.ode`, as the
Ode compiler and the assembler leave them. `merge` loops while the stack (in memory, its count a symbol) holds
more than `target` values and calls a one-block kernel; `add` calls `push` and `merge`. Lean checks the same
three in about 100 seconds, from proofs that name lemmas written by hand (`Lemmas_merge.lean`,
`StackLemmas.lean`).

- **What it is compared with** is the merge machine (an algorithm, not BLAKE3's specification): while the stack holds more than `target` values, its top two
  become their parent. A function's contract says what each argument is, what the caller must show, and what
  the function leaves (for `merge`: what the machine makes of the stack).
- **A proof** names the loop's place and what the registers and the frame hold there *for any stack the
  memory may hold* (`proofs/merge.json`, 396 bytes: the count in `r15`; four registers and eight frame cells
  kept). `push` and `add` have no loop and the empty proof.
- **The checker** runs the code from the entry and from the place along every path. To the place: the stack
  in memory is one turn of the machine from the stack the path began with, and the machine does turn there.
  To the return: the machine has stopped and the result is the count. At a call: the callee's contract: what
  it asks is shown from the caller's facts, what it leaves replaces what was there. A stack is a named unknown
  stack with some places replaced; whether two places are one is decided from linear facts.

| function | instructions | proof found in | checked in |
|---|---|---|---|
| `push` | 26 | (none needed) | under 1 ms |
| `merge` | 88 | 0.03 s | 0.004 s |
| `add` | 32 | (none needed) | under 1 ms |

What was done to find it wrong: `test_kglue.py` (25 changed functions: no proof found, and the true proof
refused; 7 wrong proofs of `merge` refused). The three on a processor against the merge machine written in C,
with the library's own one-block kernels linked (`kglue_native.c`): 20,000 cases each. And every single-bit
change, with the processor as judge (`kglue_flip.py`, `audit/kglue-flip-*.txt`):

| function | changes | stopped by the decoder | refused (no proof) | accepted | of those, as the machine on the processor |
|---|---|---|---|---|---|
| `push` | 568 | 308 | 256 | 4 | 4 (3,000 cases each) |
| `merge` | 2,528 | 1,311 | 1,112 | 105 | 105 |
| `add` | 688 | 349 | 255 | 84 | 84 |

**What that audit found.** Run first, it had 24 changes of `merge` accepted that the processor told from the
machine: all in `mov rdx, 64`, the block length given to the kernel. I had written the two kernels' contract
by hand as "the low byte of the length"; the SSE4.1 kernel reads all of EDX. The contract was wrong, not the
checker's logic: a callee's contract taken on trust is a hole until it is itself checked against the callee's
bytes (the Lean proofs have it right for that reason). Reading the accepted changes then showed a second
thing: `mov rcx, 5` (the platform word that selects the AVX-512 kernel) could become any number, and the
AVX-512 kernel be called on a machine without it, with the contract none the wiser. The contract now says the
AVX-512 kernel is called only where the platform word is 5.

**The kernels `merge` calls are checked too** (`kone.py`, written after that finding): the library's
`blake3_servil_compress_in_place_avx512` (76 instructions) and `_sse41` (94), each against `compress` of
`blake3.spec` for every chaining value, block and counter, in 3 ms. What each asks of its caller is now read
from that check, not written by hand: the AVX-512 kernel takes the low byte of RDX and of R8; the SSE4.1
kernel takes all of EDX (RDX must be below 2^32) and the low word of R8. `test_kone.py`: 19 changed kernels
refused, and each kernel refused against the other's contract. On the processor (`kone_native.c`): 200,000
cases each as their contracts say. Single-bit audit: 3,016 changes of the AVX-512 kernel, 48 accepted, each
as BLAKE3 on 20,000 cases; 3,528 of the SSE4.1 kernel, 116 accepted, each as BLAKE3.

So for `add` everything it runs is checked against the one specification: `add`, `push`, `merge`, and the two
kernels, 316 instructions in all, in under 20 ms.

Not shown here: that the merge machine is BLAKE3's tree (`alg/Stack.lean` proves that of its twin). The
machine and these three contracts are in `proofs/inner.spec`, marked as an algorithm and not the
specification. (The hash above does not use them: it has no stack.)

## The parts

| file | lines | what it is |
|---|---|---|
| `blake3.spec` | 168 | the specification (147 lines), and the claim: the contract of the function a user calls |
| `proofs/inner.spec`, `proofs/*.json` | 147 | what the functions inside are claimed to do, the layouts of two records; the wide kernels' and `merge`'s places |
| `hash.ode`, `glue/*.S` | 190 | the hash written to be proved; the assembly the Ode compiler prints of it (and of the stack's three functions) |
| `ode.py`, `kspec.py`, `klin.py` | 638 + 480 + 209 | the specification's reader; its algebra on symbols; numbers that depend on counts and the facts about them |
| `kfn.py`, `kfn_flip.py`, `khash_native.c`, `test_kfn.py` | 797 + 132 + 142 + 102 | the checker of functions; its single-bit audit; the whole hash on a processor against BLAKE3 in C; the tests |
| `kdecode.py` | 459 | reads the ELF object (sections, symbol, relocations) and decodes the instruction forms the code uses, and no others; no disassembler |
| `kcheck.py` | 534 | runs a kernel's instructions on symbolic values and compares with the specification's terms |
| `kcheck_cross.py` | 109 | kcheck's reading of each instruction against the Lean model's processor-validated test vectors |
| `kflip.py`, `kflip_native.c`, `kflip_thunk.S` | 204 + 160 + 66 | the audit below: every single-bit change of a kernel, and the processor's word on each one accepted |
| `kloop.py`, `test_kloop.py` | 438 + 115 | every number of blocks: the prover, the proof's form, the checker by induction; its tests |
| `kglue.py`, `kglue_flip.py`, `kglue_native.c`, `test_kglue.py` | 568 + 135 + 109 + 119 | the stack's functions: contracts, prover, checker; the audit; the tests |
| `kone.py`, `kone_native.c`, `test_kone.py` | 217 + 86 + 94 | the one-block kernels: the checker (XMM registers as four terms), the processor run, the tests |
| `kremove.py` | 41 | which instructions can be replaced by a no-op with the contract still met: for a person to read |
| `test_kcheck.py`, `test_ode.py` | 163 + 99 | the four kernels and the controls, from the sources; the specification on the vectors |

## How

1. Every instruction is run on symbolic values. A general register is a number, an address in a named region
   plus a number, or the packed flags by bytes. A ZMM register is sixteen 32-bit terms. Memory is named regions:
   the aligned frame, the saved registers, the table of inputs' addresses, the inputs, the key, the object's
   read-only data, the output.
2. The specification (`blake3.spec`, read on symbols) is built with the same term constructors.
3. Terms are interned, and sums and xors are kept flat and sorted, so two terms are equal when they are the same
   node. The comparison is of 256 (or 128) node numbers. No solver.

Checked beside the result: every read is of something the contract gives; every write is to the frame, the
saved registers or the output; aligned stores are on aligned addresses; the stack used is within the contract's
4096 bytes; the registers a callee keeps are restored and the return goes to the return address; every branch
is decided by numbers and every address is a region and a number, so the trace of addresses and branches is the
same for every input.

## What has been done to find it wrong

(Every single-bit audit below and above was run again, by `sh audit.sh 40`, at commit `b3d52cc1`: the
specification and all nine contracts in `blake3.spec`. `audit/` holds the outputs.)

1. **Changed kernels** (`--mutants`): 15 of 15 refused (rotations, operands, the carry's mask, a message offset,
   a store's offset, a shuffle, a flag, a saved register, the frame's bound, the block step, one entry of the
   schedule table). A kernel against another kernel's specification is refused.
2. **The specification against the official vectors** (`ode.py --vectors`, `test_ode.py`): the text the code
   is compared with gives all 105, and 18 single changes of it are each told by them.
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
   | P16 | 22,144 | 14,191 | 7,611 | 342 | 342 (1,000 cases each) |
   | K32 | 35,824 | 22,163 | 11,905 | 1,756 | 1,756 (1,000 cases each) |
   | P32 | 35,824 | 22,163 | 11,778 | 1,883 | 1,883 (1,000 cases each) |
   | `output16` | 29,384 | 17,597 | 11,393 | 394 | 394 (2,000 cases each) |

   (Threadripper PRO 7975WX, clang 21.1.8's objects, the checker and decoder as they are at commit `b3d52cc1`;
   16 s for P16, 26 s for `output16`, 13 minutes each for K32 and P32, 40 at a time.
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

- The specification and the claim, `blake3.spec` (168 lines), and the programs that read it and the bytes:
  for the hash `ode.py`, `kspec.py`, `klin.py`, `kdecode.py`, `kcheck.py`, `kone.py`, `kloop.py`, `kfn.py`:
  3,772 lines; with `kglue.py`, 4,340 (their provers, about 150 of those, need no trust). And Python.
- That the things `hashr` is given the addresses of are apart from one another and from the stack (the
  claim says so: its caller's part).
- What the functions inside are claimed to do (`proofs/inner.spec`) is not relied on: a wrong contract there
  makes the checker refuse the function it is of, or a function that calls it.
- For a function that calls itself: what is shown is what holds if it returns.
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
