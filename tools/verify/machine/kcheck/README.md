# kcheck: a specification, a binary, and a verifier a reader runs (a trial, November 14 and 15, 2026)

**To verify a shipped binary yourself: `VERIFY.md`** (one page) and `python3 verify.py FILE`, which prints
the contract you are asked to rely on, the verification, and the files that ran to reach it.

**Two words, kept apart** (since November 15): a **prover** finds or writes out a proof and is trusted for
nothing; a **verifier** decides whether the code is shown to meet its contract, and is what a reader relies
on. The programs of this folder (`kfn.py`, `kbyte.py` and the others) are each both at once today: they
search (which facts to add up, which way to open a definition) and they decide. They are called verifiers
here because their yes is what is relied on. Taking the search out of them is the work under way. **The
arithmetic's search is out (November 16):** a prover (`kprove.py`) writes a proof of each fact of arithmetic,
every shipped file carries them, and the verifier adds them up (`varith.py`, 90 lines) and searches for
nothing. What is still searched for inside the verifiers: which way a definition opens, and the paths.

**Since the night of November 16** (the sections near the end of "Programs other than the hash" say each):
the lemmas (a contract of a definition, in the proof, shown before use; LZ4's specification is the format's
own again); definitions shown to come to an end on everything a contract allows (`kends.py`); a second
verifier of the arithmetic, in C, written apart (`varith2.c`); provers that guess lemmas and the places of
loops (`kguess.py`, `kplace.py`: for three functions the whole proof from the binary and the specification
alone); two more audits (`lemma_audit.py`, `kadversary.py`); "false, and here is the input" (`refute.py`).
And three things found wrong and closed that night, none in "meets its contract": two of the kind "shown,
of something false" (what a verification said about a specification's definitions ending; the kind a
lemma gave a value) and one silence (a function the proof left out).

**November 16, evening** (the last section, "An object is read in one shape", says each): found by a
review of that night and closed. Three of the kind "shown, of something that is not so": a lemma that says
nothing, or a sequence, hid a definition that uses itself from "comes to an end"; a file without names
whose proof left a function out was verified with exit 0; and an object with a second function under a
verified function's name, in a section this reader did not read, was verified as the shipped file is, and a
program linked with it ran the other function. And Sam's changes of the same day: the contract's word
`apart` is `no_overlap`; names are BLAKE3 hashes, all 64 digits, worked out by `blake3.spec` itself
(`kshow.py`); a verification tells an auditor what he has use for and a maintainer the rest (`--maintain`);
what a file carries is printed with no control character; `CONTRACT.md` and `LANGUAGE.md` are one page.

**Not a proof in a proof assistant, and checked by none.** A trial of another way to the goal of BLAKE3 #361:
to hand a skeptical reader a specification, a binary and a proof, such that he checks for himself, in
seconds, that the binary meets the specification, relying on little.

The scope is narrow on purpose (Sam, November 15). The code is new code written for this, not existing code.
The mathematics is what the code needs, not all of mathematics. The programs are those that can be written
this way, not all programs. The languages are our own.

- **The specification says what the thing is, not how to compute it** (`blake3.spec`: 147 lines with its
  comments). Definitions by equations, in a language made for specifications and for nothing else
  (`LANGUAGE.md`, one page): the compression function; a chunk as a sequence (`h[0] = key`,
  `h[b + 1] = compress(h[b], ...)`); the tree by the paper's own rule (the left part holds `the greatest
  power of two k with 1024 * k < len` chunks; a tree is its two parts' trees under a parent). Evaluated on
  numbers it gives the 105 official test vectors. Nothing in it is a stack, a counter of subtrees, or a loop.
- **What the reader is promised is a contract** (`LANGUAGE.md`, part 2, the same for every function):
  what the caller must make true (`requires`), what is then true when the function has returned
  (`ensures`, `returns`), and that it has done nothing else. Memory holds bytes. Silence means the stronger
  thing: a function that reads or writes more, runs other instructions, or lets its timing depend on the
  bytes it is given, says so in its contract.
- **The code is written to be proved** (in Ode), as code is written to be fast: in the specification's
  shape where it can be (`hash.ode`: `subtree` splits its bytes by the specification's rule and calls itself
  on each part), and with a place for each loop where it cannot (`programs/`).
- **The proof is whatever the verifier needs beside the binary**, and is not trusted: the contracts of the
  functions inside, and for a loop a place (what holds each time round, and what decreases). For the hash's
  own nine functions there is none to write. It travels in the binary, in a section that is not loaded.
- **The verifier does not search.** It runs each function's machine code on symbols along every path; a call
  is taken by the callee's contract (a call of itself by its own); what is left at the return is compared
  with the specification's definition. Terms are compared by identity, numbers by adding linear facts up.
  No solver.

**The binary is one file, `b3hashr.o`** (80,920 bytes): the thirteen bodies of code the hash is made of,
their constants, their names, the specification, the proof, and nothing for a linker to fill in.
`python3 check_binary.py b3hashr.o` reads it, follows every call from `b3l_hashr`, and says in 19 s on an
Apple M6 that `b3l_hashr` in that file meets its public contract:

    contract b3l_hashr(out: 32 bytes, input: len bytes, len: number, key: 32 bytes, flags: byte, plat: any) {
        requires no_overlap(out, input, key)
        ensures out = bytes_of(hash_words(words(key), flags, input))
        stack 18688 + 384 * bits(len / 1024)
        needs sse41
        needs avx512 if plat == 5
    }

It says the same of a shared object GNU ld makes of it, of one lld makes, of a C program and of a Rust
program it is linked into, and of those with their names stripped: each read as a loader maps it. No
assembler and no linker is relied on.

**Programs other than the hash** (`programs/`, November 15: to find what the two languages lack). Each has
its own specification and public contract, code in Ode, and is checked from its bytes
(`python3 programs/check_programs.py`, with the search: twelve functions, 1,839 instructions, 22 s, 12 of them
the base-64 encoder's; the shipped files, by the proofs they carry: 3 s in all, see "Shipped as files"):

| | the public contract's `ensures` and `returns` | instructions | proof | checked in |
|---|---|---|---|---|
| Adler-32 | `returns adler32(input)` | 55 | 1 place, 7 lines | 5 ms |
| Adler-32, the sums reduced once in 5,552 bytes | the same line, the same specification | 116 | 2 places, 25 lines | 0.2 s |
| the same, four bytes a turn | the same | 164 | 3 places, 38 lines | 2 s |
| LZ4 block decoder | `returns if failed(lz4(input)) \|\| len(lz4(input)) > cap then NO else len(lz4(input))`; `ensures out[0 .. len(lz4(input))] = lz4(input) if !failed(lz4(input)) && len(lz4(input)) <= cap` | 267 | 5 places, 96 lines; 4 lemmas | 1.7 s |
| LZ4 encoder, literals only | `ensures lz4(out[0 .. r]) == input if r != NO`; `ensures r != NO if cap >= n + n / 255 + 16` | 132 | 2 places, 26 lines | 70 ms |
| LZ4 encoder with matches | the same two lines | 360 | 6 places, 129 lines | 1.9 s |
| a number's varint | `returns r`; `ensures out[0 .. r] = varint(v)` | 35 | none | 0.17 s |
| first difference of two runs of bytes | `returns common(a, b)` | 45 | 1 place, 8 lines | 5 ms |
| UTF-8: is it well-formed, and how many code points | `returns if failed(utf8(input)) then NO else utf8(input)` | 300 | 1 place, 11 lines | 0.16 s |
| Base 64 encoder | `requires cap >= 4 * ((n + 2) / 3)`; `returns 4 * ((n + 2) / 3)`; `ensures out[0 .. 4 * ((n + 2) / 3)] = base64(input)` | 197 | 1 place, 12 lines | 12 s |
| the Internet checksum (RFC 1071) | `ensures r == checksum(input) if n < 562949953421312`, else NO; no `requires`; no `trace` line: its timing does not depend on the bytes | 88 | 1 place, 9 lines | 0.25 s |

What is shown of BLAKE3, from the bytes (`python3 check_all.py`, of the objects an assembler makes of the
sources: 18 functions, 3,831 instructions, 19 s):

- **`b3l_hashr`: BLAKE3 of a message of every length, under any key and flags** (the public contract above),
  through the nine functions of `hash.ode` and the library's kernels: the two one-block ones, the 32-lane
  chunk kernel for every part of more than one chunk, and the 16-lane parent kernel for a whole tree of 32
  or of 128 chunks. Nothing is assumed of a callee: each is checked against its own bytes. On the same kernels it is
  as fast as the earlier Ode code that was written for speed alone, or faster, and at 1 MiB and above it
  runs at 97% to 98% of the library's own speed: 16.05 GiB/s against 16.37 on a Ryzen 7 9700X, one thread
  (below; about 60% at 16 and 32 KiB).
- The library's wide kernels by themselves (K32, P32 and P16 for every number of blocks; `output16`).
- An earlier trial (`push`, `merge`, `add` of a stack of subtrees) against an algorithm, not the
  specification.

What a reader relies on: the specification and the public contract, which he reads, with the two pages that
say what they mean; the verifier, unverified Python (4,176 lines for the hash, 910 more for the programs of
`programs/`, 569 for the stack's); the processor doing what the verifier takes each instruction form to do;
a loader that maps the file as its headers say; Python. Most of this page is what has been done to find
where the verifier is wrong, and what that found.

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

and the public contract (above), which is all of the contracts a reader need read. `LANGUAGE.md` (part 2) says what
any contract means; here: `out`, `input` and `key` do not overlap; then the 32 bytes at `out` are the
hash's eight words as bytes, each word's lowest byte first, of the key's bytes read the same way, the flags
and the input; it uses that much stack and no more; it runs SSE4.1 instructions, and AVX-512 instructions
only where `plat` is 5; and, since the contract has no `trace` line, which instructions it runs and which
addresses it touches depend on the numbers it is given (`len`, `flags`, `plat`), not on the bytes of the key
or the input. (`kfn.py` has no way to branch on anything else: a compare of two things that are not both
numbers is refused, and an address is a region and a number. No test changes the code to branch on a byte.)

- `ode.py` (694 lines) reads the text and evaluates it over an algebra of words. On numbers: the official
  vectors, at every length, for the hash, the keyed hash and key derivation.
- `kspec.py` (565 lines) is the other algebra, for the verifiers: words are terms; a number may depend on a
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

332 lines of Ode (the language of `lang/`; its compiler is `lang/odec.py` and `lang/Lang.lean`, and prints
assembly). Nine functions:

| function | instructions | what its contract ensures (`proofs/inner.spec`, but for the last) |
|---|---|---|
| `pad(block, src, n)` | 39 | `block = padded(src)` |
| `chunk_node(nd, input, len, t, flags, plat)` | 81 | `nd = chunk_node(nd.h, t, flags, input)` |
| `node_out(out, nd, root, plat)` | 58 | `out = node_value(nd, root)` |
| `wide32(out, input, kf, t)` | 259 | `out = subtree(kf.key, kf.flags, t, input)`, for 32,768 bytes |
| `wide128(out, input, kf, t)` | 670 | the same, for 131,072 bytes |
| `take(out, input, len, kf, t, cvs)` | 133 | the same, given at `cvs` the values of the chunks of 1,024 bytes |
| `part32(out, input, len, kf, t)` | 76 | the same, for more than 1,024 bytes and at most 32,768 |
| `subtree(out, input, len, kf, t, plat)` | 189 | `out = subtree(kf.key, kf.flags, t, input)` |
| `hashr(out, input, len, key, flags, plat)` | 265 | `out = bytes_of(hash_words(words(key), flags, input))` |

What "written to be proved" meant, each a choice the programmer made as one makes choices for speed:

- **The tree is a recursion, as in the specification.** `subtree` finds the count of chunks for its left
  part, calls itself on the two parts, and compresses the two values. Its own contract is what the verifier
  takes at those calls. An earlier form of this code kept a stack of subtrees (and one after it, levels): to
  show that such a thing makes the tree takes an induction over counts and their bits, which Lean did by
  lemmas written by hand. Here there is nothing to show: the code's two calls are the definition's two parts.
- **The wide kernels are a leaf of the recursion.** A part of exactly 32 chunks, on a machine with AVX-512,
  goes to `wide32`: the 32-lane chunk kernel, then five rounds of the 16-lane parent kernel (16, 8, 4, 2, 1
  parents). The verifier opens the specification's `subtree` down to those 32 chunks and their 31 parents,
  and it is the term the kernels' contracts give. No new idea was needed, and nothing about trees.
  `wide128` does the same for 128 chunks with sixteen parents to a call while a level has as many (four
  calls of the chunk kernel, eleven of the parent kernel): written after the first timing against the
  library, checked on its first run, and worth a tenth more speed at 1 MiB (below).
- **An array has a type.** A part of 2 to 32 chunks gets its chunks' values from one call of the chunk
  kernel (`part32`), and `take` builds the tree over them: the specification's two parts again, but a chunk
  of 1,024 bytes is copied from the array, not hashed. What makes that provable is one line of `take`'s
  contract, which says what each value in the array IS, in the specification's words:

      requires cvs[i] == node_value(chunk_node(kf.key, t + i, kf.flags, input[1024 * i .. 1024 * i + 1024]), 0) for i in 0..len / 1024

  Inside `take` a value read from `cvs` is that term. At a call the verifier shows the line from the caller's
  memory: lane by lane where the caller's values are the kernel's (32 at most), and for any `i` in the range
  where they are themselves such an array (`take`'s calls of itself). The programmer says what the memory
  holds; nobody writes a proof.
- **Every loop runs a number of times that the paths fix**: a block's 64 bytes, a chunk's 16 blocks, the 54
  doublings that find the left part's count. The verifier runs them; none needs an invariant.
- **Six arguments**, which the calling convention carries in registers: the key and the flags travel as one
  record (`kf`).
- **The stack is bounded by the length**: `subtree` may use `16896 + 384 * bits((len - 1) / 1024)` bytes, a
  level of recursion for each halving of the count of chunks (and the wide kernels' frames).
- **What the processor must have is in the contract**: `needs avx512 if plat == 5`. A function may call one
  that needs AVX-512 only on a path where its own contract's condition holds, or hand it its own `plat`. At
  the bottom it is read from the bytes: a function whose contract does not say `needs avx512` holds no
  instruction with an EVEX prefix (nor, without `needs sse41`, one of the SSSE3 and SSE4.1 maps).

    python3 kfn.py subtree OBJECT          # the verifier: the object's bytes, blake3.spec, proofs/inner.spec
    python3 test_kfn.py                    # 4 tests, 6 minutes

| function | paths to the return | instructions run | checked in |
|---|---|---|---|
| `pad` | 65 | 40,564 | 0.11 s |
| `chunk_node` | 31 | 1,740 | 0.43 s |
| `node_out` | 2 | 67 | 0.01 s |
| `wide32` | 1 | 2,383 | 1.2 s |
| `wide128` | 1 | 6,802 | 5.4 s |
| `take` | 56 | 3,802 | 2.3 s |
| `part32` | 32 | 10,273 | 3.8 s |
| `subtree` | 109 | 7,392 | 1.1 s |
| `hashr` | 141 | 20,264 | 3.1 s |

## The verifier of functions: `kfn.py`

It follows one function at a time. Memory is in named regions of typed things: a chaining value, bytes (a
message's, of a length that is a symbol), a record whose `layout` is in `proofs/inner.spec`. A branch on
something the path does not fix splits the path, and each side keeps the fact; a path whose facts cannot all
hold is dropped. At a call the callee's contract is used: what it `requires` is shown from the caller's facts,
what it `ensures` replaces what was there (a definition's value there is not opened, only named: the caller's
own specification, opened later on the same path, finds the same name). At the return each thing the
contract says is left is the specification's value of it; the result, the registers a callee keeps, the stack
pointer and the stack used are checked; every write was within what the contract lets the function write.

The numbers' part (`klin.py`, 256 lines): a fact is a number known not to be below zero; one known both
ways is an equality and one of its symbols is replaced; a question is answered by adding facts up (Fourier
and Motzkin's elimination, in whole numbers). Halving and the low bit make a symbol with its two facts.

A loop is run: a path that jumps back to one instruction more than 100 times is refused. (The code's
earlier form, a stack of levels with a loop over them, was checked too, by a place for that loop: the name of
a machine of the specification and what the registers and the memory hold for any state of it, found by a
prover that comes to the loop three times. When the hash was written as the specification's own recursion no
loop needed a place, and that part of the verifier was taken out.)

At a call the verifier also shows that what the callee writes overlaps nothing else the callee is
given the address of (the callee's own check took it so), and that what the callee needs of the
processor the caller's contract allows there.

**What was done to find it wrong**, as for the kernels below:

- *Changed code* (`test_kfn.py`): every call left out and every branch turned round, in all nine
  functions (of `wide128`'s thirty branches, which are fifteen copies of one loop, the first four): each
  refused.
- *Changed text* (`test_kfn.py`): 54 changes of the contracts, the layouts and the specification: each
  refuses the function that met the text.
- *Every single-bit change of each function's code, with a processor as the judge* (`kfn_flip.py`,
  `khash_native.c`). A change for which a proof is found is linked with the other eight functions and the
  kernels, and the whole hash is run on an AVX-512 processor against BLAKE3 written out in C another way (the
  reference's stack of subtrees; it and `hashr` first give six of the official vectors, plain and keyed):
  every length from 0 to 200, every seventh to 2,200, the three around each
  multiple of 1,024 up to 70 chunks, 200 random lengths to 300,000; the three modes' flags; both kernels; the
  message ending where a page that faults begins.

  (All nine functions, the verifiers as at commit `2ae7c9e9`; each change was given 900 s at most and none took them.)

  | function | changes | stopped by the decoder | refused (no proof) | accepted | of those, as BLAKE3 on the processor |
  |---|---|---|---|---|---|
  | `pad` | 896 | 447 | 416 | 33 | 33 |
  | `chunk_node` | 2,280 | 1,080 | 1,100 | 100 | 100 |
  | `node_out` | 1,432 | 722 | 635 | 75 | 75 |
  | `wide32` | 10,432 | 4,260 | 5,455 | 717 | 717 |
  | `wide128` | 28,888 | 11,380 | 14,656 | 2,852 | 2,852 |
  | `take` | 5,176 | 2,096 | 2,638 | 442 | 442 |
  | `part32` | 2,592 | 1,083 | 1,375 | 134 | 134 |
  | `subtree` | 7,152 | 2,820 | 3,516 | 816 | 816 |
  | `hashr` | 11,008 | 4,384 | 5,851 | 773 | 773 |
  | all nine | 69,856 | 28,272 | 35,642 | 5,942 | 5,942 |

  (Threadripper PRO 7975WX. The judge is the whole hash: a change that is wrong only where no hash goes, a
  write beside what a callee may write that no later read meets, is not seen by it. The accepted changes are
  mostly of moves whose value is already where it goes, of the first values of variables that are given
  again before they are read, and of which register carries the platform word to a callee when it is a
  plain number that is not 5.)

**What that found.** Before the processor was asked, a run of changed instructions through the verifier had
`hashl` (the earlier form) accept 80 changes of the moves that carry the platform word to its callees: a
callee's `calls F if plat == 5` was not carried to its caller, so a caller could hand a callee anything as
the platform, and the AVX-512 kernel be run where the caller's contract says it is not. The condition is now
carried: what a callee is given for `plat` must be the caller's own, or a plain number that is not 5, or
anything on a path where the caller's own condition holds.

**Speed.** One thread, under the bench lock, on two machines with AVX-512 (pinned runs
`hashr-speed3-9700x-…-6b02f35e` and `hashr-speed3-epyc9255-…-15e6745d`; `hash.ode` at commit `285c3d7a`, GNU
as 2.46's objects; the library at `next` `3ec37f0e`, rustc 1.99.1). `khash_bench.c`: GiB a second, the best
of 7 passes; the median of three rounds (the three were within 2% of one another in every cell). "library":
BLAKE3-Servil's own one-shot hash on the calling thread (`b3_hash` of `capi/b3.h`). `hashf`: the earlier Ode
code (`levels/levels.ode`: levels over groups of 32 chunks, written for speed, proved in Lean with a
stand-in). The three give the same hashes.

| bytes | `hashr`, Ryzen 7 9700X | library | `hashf` | `hashr`, EPYC 9255 | library | `hashf` |
|---|---|---|---|---|---|---|
| 1,024 | 0.94 | 0.98 | 0.94 | 0.74 | 0.77 | 0.74 |
| 16,384 | 6.36 | 10.56 | 4.45 | 5.12 | 8.34 | 3.57 |
| 32,768 | 9.27 | 15.26 | 7.13 | 7.45 | 12.20 | 5.70 |
| 65,536 | 14.97 | 15.92 | 9.49 | 12.17 | 12.87 | 7.64 |
| 100,000 | 10.77 | 13.44 | 10.60 | 8.80 | 10.84 | 8.62 |
| 1,048,576 | 16.05 | 16.37 | 13.65 | 13.14 | 13.43 | 11.02 |
| 1,048,577 | 16.02 | 16.34 | 14.07 | 13.14 | 13.43 | 11.36 |
| 16,777,216 | 15.45 | 15.81 | 13.59 | 12.69 | 13.05 | 11.09 |

So the code written to be proved, on the library's own kernels, runs at 97% to 98% of the library's speed
from 1 MiB up, 94% to 95% at 64 KiB, 80% at 100,000 bytes, about 60% at 16 and 32 KiB, 96% at one chunk; and
it is faster than the earlier Ode code everywhere above one chunk. One run before, without `wide128`, it was
at 87% to 89% from 1 MiB up (runs `hashr-speed2-…`): the difference is parents made sixteen to a call. What
the library still does that `hash.ode` does not: a 16-lane path for 16 chunks or fewer (here the 32-lane
kernel runs half empty), and parents many to a call over small parts and at the top of a message of 32 KiB.
Neither is something the way of proving forbids: they are code not yet written (the first needs a kernel
checked). On the SSE4.1 kernel `hashr` and `hashf` are alike (0.74 and 0.58 GiB/s: one block at a time).

**The file shipped, itself** (`b3hashr.o`, SHA-256 `ddcc8b45…f48e`, linked into the same harness; pinned runs
`hashr-speed4-9700x-…-90f68963` and `hashr-speed4-epyc9255-…-445a8dd9`, the same library, beside the
separately assembled objects in the same run):

| bytes | `b3hashr.o`, Ryzen 7 9700X | the objects | library | `b3hashr.o`, EPYC 9255 | the objects | library |
|---|---|---|---|---|---|---|
| 16,384 | 6.37 | 6.38 | 10.63 | 5.13 | 5.13 | 8.44 |
| 65,536 | 14.96 | 14.96 | 16.02 | 12.14 | 12.17 | 13.09 |
| 1,048,576 | 15.77 | 15.87 | 16.35 | 13.05 | 13.17 | 13.28 |
| 16,777,216 | 15.54 | 15.50 | 16.03 | 12.72 | 12.69 | 13.12 |

96% and 98% of the library at 1 MiB, 97% at 16 MiB. At 1 MiB the file is 0.6% to 0.9% slower than the
objects: the same instructions, laid out by `klink.py` and not by a linker.

**The verifier refused my first form of the wide leaf.** I had written `wide32(...)` and then `return 0`
inside an `if`; Ode's `return` gives the result and does not leave the function, so the code went on, hashed
the 32 chunks again by halves, and wrote the same value a second time. The verifier's message was that `out`
at the return is not what the contract says: it holds the parent of two named halves where the contract's
tree had been named whole by the call. Right hash, wrong code; an `else` fixed it.

**That it ends** is shown this far: every loop is run to its end on every path; a function that calls
itself (`subtree`, `take`) names in its contract a number that decreases (`decreases len`), and each such
call is shown to be on fewer bytes; the functions call one another without a ring (`check_all.py`); and the
wide kernels are called with 16 blocks and with 1, for which `kcheck.py` runs them to their end.

**Not shown:** AArch64; AVX2 and narrower machines (they get the one-block SSE4.1 kernel). The parents over a part of fewer than 32 chunks are compressed one at a time (those over
a whole tree of 32 go to the 16-lane kernel).

## The binary: one file (`klink.py`, `check_binary.py`, `b3hashr.o`)

Until here what was checked was the objects an assembler makes, one a source file, each with places left
for a linker to fill in: how far away the function an instruction calls is, or the constant it reads. The
verifier took those from the relocation's name, and a linker was trusted to write them so. Now:

- **`klink.py`** (134 lines, trusted for nothing) takes from the assembler's objects the bytes of the
  thirteen bodies `hashr` runs (the nine functions of `hash.ode`, the two one-block kernels, K32 with its
  second entry, P16), from each one's first byte to its `ret`, and the read-only data of the three objects
  that have any; lays them out in one section, each on the boundary it had; and writes the distances itself.
  **`b3hashr.o`**: 80,920 bytes, of which 16,788 are code and 61,554 the specification and the proof (38,747 of
  those the arithmetic's proofs, which `varith.py` adds up); fourteen names; no
  relocations. A linker has only to place it on a 64-byte boundary. The library's other functions that share a source file with a kernel
  (`hash_many`, the XOF's) are not in it.
- **`kdecode.py` reads a file whose addresses are settled** (an object with no relocation left for its code,
  a shared object, an executable): an operand's or a call's target is where the instruction's own four bytes
  say. A call must go to the start of something the file gives one name's worth of address to (a name given
  to two places is no name). An operand must lie, with the 64 bytes after it, in what is loaded without
  leave to write. For a linked file the bytes are those a loader maps: each `PT_LOAD` part in whole
  4096-byte pages of the file. It stops if two parts share a page, if a part's place in the file and in
  memory differ within the page, if a read-only part is longer in memory than in the file, if the
  read-only parts do not lie side by side, if the code is not in a part that may be run, or if the file asks
  the loader to change its code (`TEXTREL`).
- **`check_binary.py FILE`** starts at `b3l_hashr`, checks it from the file's bytes with the verifier for its
  kind, and goes on to every function it calls, found by where the call goes: thirteen bodies, 3,102
  instructions, 19 s. Then it says what else the file loads to be run: in `b3hashr.o`, beside the 16,788
  bytes of the bodies, 859 zero bytes and 529 others (the constants, and what lies between functions).

| file | made by | bytes | `b3l_hashr` in it |
|---|---|---|---|
| `b3hashr.o` | `klink.py`, of Apple clang 21's objects | 80,920 | meets its public contract |
| a shared object of it | GNU ld 2.46 | 91,672 | meets it |
| a shared object of it | lld 21 | 82,808 | meets it |
| `khash_native.c` with it (an executable loaded anywhere) | GCC 15.2, GNU ld | 108,192 | meets it; on the processor 5,466 hashes as BLAKE3's |
| the same after `strip` (no names; the proof's section is kept) | | 104,840 | meets it: the functions are found by their bytes |
| the same after `strip --strip-all -R .ode.proof` (no names, no proof) | | 43,208 | meets it, given the proof beside it (`--proof b3hashr.proof`) |
| `programs/blake3-rust/main.rs` with it | rustc 1.99.1 (`-C link-arg=b3hashr.o`) | 4,645,776 | meets it |
| the same after `strip` | | 432,208 | meets it |

(All remade on November 16 from the file as it is now, with the arithmetic's proofs and the lemmas in it: in each the
verification searches for nothing and says the tree's definitions come to an end; the stripped file with no
proof beside it is not shown. The second verifier of the arithmetic, `varith2.c`, reads the same 6,507 proofs
out of the shared object and out of the Rust executable, stripped or not.)

**The proof is in the file.** `klink.py` writes a section the loader does not map, `.ode.proof`: the inner
contracts, the wide kernels' places, where each function begins, and the BLAKE3 hash of the specification the
maker had. A linker carries the section into what it makes. `check_binary.py` takes the proof from there
(or from `--proof FILE`, or from `proofs/`), and trusts none of it: a wrong inner contract or place makes
the check fail. **The file carries the specification too** (since November 15, at Sam's word), so that a
reader with the file alone has everything: `--show-spec` prints it. It is the one thing in the file he must
read, because it is what is shown: with no `--spec` the check is against the text the file carries and
says so; with `--spec` it is against his own, and the check says whether that is the one the maker had.
(The sizes of the linked files in the table above are from before the specification was added.) In a file without names the functions are found by the
proof's offsets and the code's own bytes; a proof of other code is refused ("the code the proof is of is
not in it").

**Two ways to use it.** As a library: a C or a Rust program is linked with `b3hashr.o` as it is (the Rust
program above declares `b3l_hashr` as `extern "C"` and passes the object to the linker; no assembler and no
C compiler takes part), and the reader checks the program he was given. As the bytes of an executable: the
same check, of the executable's file.

On the processor (Threadripper PRO 7975WX), `khash_native.c` linked with `b3hashr.o`: 5,466 hashes, as
BLAKE3's, on both kernels; the Rust program gives the official vectors of 0 and of 102,400 bytes. (At commit
`b3ed2d7d`, before the proof was in the file, a shared object of the twelve objects as an assembler made
them was checked too, of GNU ld and of lld: 37,214 other bytes are loaded to be run in it, the library's
other functions among them. And each of the two shared objects of `b3hashr.o`, loaded, gave the 5,466
hashes.)

**What was done to find it wrong.** `test_kbinary.py`: the object and the same bytes under a program header
give the same instructions; a part with leave to write, with no leave to run, off its page, longer in
memory, sharing a page, or not side by side with the others stops the reading; `TEXTREL` stops it; a name given to two
places is not found, and a call to it stops; each of `node_out`'s two calls sent to each of the other
thirteen names is refused, but for one that is no fault (the AVX-512 kernel's call sent to the SSE4.1
kernel: where the first may be run so may the second, and they give the same). `klink_flip.py`: every
single-bit change of the 71 fields a linker would have written (52 calls, 19 operands): 2,272 changes,
2,060 stopped by the decoder, 200 refused, 12 accepted; the twelve read the same constants from another
place (the three objects' data each begin with BLAKE3's IV), and each, linked and run on the processor, hashes as
BLAKE3.

**What that found: an aligned read that nothing showed aligned.** The one-block kernels read sixteen bytes
of constants with `MOVAPS`, which faults unless they start on a 16-byte boundary. The decoder took the
bytes and did not ask where they lie: an object whose read-only data a linker may put on an 8-byte boundary,
or an operand four bytes further on, was accepted. The single-bit audits could not have found it: they
change the code, and this is in a section header or a relocation. It is asked now, of an assembler's object
(its `.rodata`'s boundary and the operand's place in it) and of a settled file. The library's objects pass.

`test_kbinary.py` also checks that the proof the shipped file carries was made with the specification here
and is of the file's own code, that one of its inner contracts changed makes the function it is of refused,
and that a reader with another specification is told so.

**Not done:** an audit of every single-bit change of the whole file (its headers, its names, its proof); an
executable's or a shared object's other contents are counted, not judged; the file is taken to be loaded
by a loader that does what the program headers say and to be run where nothing else writes over it.

## Programs other than the hash: `programs/`, `kbyte.py` (November 15)

Written in one night to find what the specification language and the contract lack, each chosen for
something BLAKE3 does not have: a result that is a number, a loop whose count is the input's length, input
that may be malformed, output that depends on earlier output, an answer that may be "no", and a contract
that is no way to compute anything.

    python3 programs/check_programs.py          # the eleven functions from their bytes: 1,759 instructions, 17 s
    python3 programs/test_specs.py              # each specification against someone else's answers
    python3 test_kbyte.py                       # changed specifications, contracts, proofs and instructions

| folder | specification (lines a reader reads, with comments and contract) | checked against | code |
|---|---|---|---|
| `adler32/` | 34 | zlib's `adler32` | `ode_adler32`, `ode_adler32_blocks`, `ode_adler32_blocks4` |
| `lz4/` | 111: the block format, its two ways to fail, three contracts | a decoder written in the test as decoders are (a loop over the block), on blocks an encoder of the test's made and on damaged ones | `ode_lz4_decode`, `ode_lz4_store`, `ode_lz4_pack` |
| `varint/` | 12 | LEB128 written another way | `ode_varint` |
| `common/` | 15 | the same in Python | `ode_common` |
| `utf8/` | 61: a code point is 0 to 0x10FFFF and no surrogate, written in the fewest of one to four bytes | Python's strict decoder | `ode_utf8` |
| `base64/` | 38: RFC 4648's words: 24 bits as four groups of six, a letter each; "=" at the end | Python's `base64` | `ode_base64` |
| `inet/` | 42: RFC 1071's words: pairs of bytes summed in one's complement (the plain sum less as many 65535s as leave it from 1 to 65535), and that sum's complement | the RFC's own example and its C code's way, in Python | `ode_inet` |
| `sigil/` | 175: John's Sigil 0.1 (the data with two marker bits, times a check prime, written in base 2,048 as letters) | the 220 good vectors of its repository | none: it multiplies a number of 258 bits by a prime and looks letters up in a table of 2,048; Ode has no multiplication yet, and `kbyte.py` reads no table of constants |

**What each made the languages gain.**

- *Adler-32*: a `sequence` with a name, used at any place (`s1(bytes)[k]`); a result that is a number
  (`returns`); a loop whose count is the input's length, so a **place**: what holds each time the loop
  comes round, in the specification's terms (`r12 = s1(input)[i]`: the register holds the sequence's value
  at place i), and a number that decreases.
- *LZ4 decoding*: **failure** in the specification (`fails MALFORMED if ...`, `failed(E)`), so that "it says
  NO exactly where the format gives no value" can be written; `ensures X[a .. b] = E` and `ensures ... if
  C`; `trace depends on input`, since which instructions run depends on the block (the closed world's rule
  for timing, weakened where the contract says so and nowhere else); memory safety on every input, as the
  closed world already demands: no byte read outside the block, none written outside `cap`.
- *LZ4 encoding*: a contract that is not a way to compute: `ensures lz4(out[0 .. r], n) == input`. It is
  true of every right encoder; the two here differ in what they write and share the line. It is also true
  of an encoder that always says NO, so each contract has a second line saying when it does not
  (`ensures r != NO if cap >= n + n / 255 + 16`: the room LZ4's users know as its bound).
- *Varint, first difference*: nothing. They were written after the others and needed no change to either
  language or to the verifier.
- *UTF-8*: nothing again, and it was written while the verifier was frozen for the audit: specification,
  code, proof (one place, four facts), tests and the run against the C library's converter took seven
  minutes by the clock (a model wrote them). The specification is the standard's definition (the fewest bytes, no surrogate, at most 0x10FFFF),
  not its table of byte ranges; the code tells the same from the first two bytes, and the verifier's
  arithmetic shows that the two agree. One thing it taught: **the code has to decide things in the order
  the specification does.** The first form looked at the byte after the first before it had settled how
  many bytes the sequence has; the specification settles that first, and the verifier, reading the
  specification along the code's path, could not go on ("the specification asks how input[i] and 224
  compare, and the code's path does not say"). The answer would have been the same either way. The code
  was changed. The verifier could instead take such a question both ways, as it does for a contract's
  `if`; it does not yet.
- *Base 64*: nothing in the languages either (also written with the verifier frozen; accepted on its first
  run, three minutes after its specification was begun). It is the first whose room is the caller's to
  give (`requires cap >= 4 * ((n + 2) / 3)`), so it has no NO. One thing it showed: **paths multiply.** A
  letter is a choice of five; the four letters of a group are written in a loop the verifier runs through;
  that is 625 paths a turn, and the check takes 13 s where the others take a fraction of one. A place
  inside the group should join them (not tried); a verifier that joined paths that end alike would do it
  for every program.
- *The Internet checksum*: nothing in the languages (written with the verifier frozen, accepted on its
  first run). Its contract has no `trace` line: no branch and no address depends on the bytes, though every
  byte goes into the result, and the verifier shows it (it refuses Adler-32 without the line; the storing
  encoder and the varint have none either). And the verifier
  did arithmetic its author had wrong: I wrote `requires n < 2^32` with four folds of the carries; a
  changed specification with three folds was accepted (three do suffice below 2^32), and so was `n < 2^49`
  with four (the sum then still fits 64 bits, and four folds bring any such sum within 16). The contract
  now says 2^49, and one byte more is refused. And it showed what I had assumed it could not. The
  specification first said the code's own way ("fold the carries in, four times"), with a note that what
  the folds amount to was tried on examples and shown nowhere. It now says what a one's complement sum is
  (`if s == 0 then 0 else (s - 1) % 65535 + 1`) and has no fold in it; the code still folds four times; the
  verifier's arithmetic shows the two are one, in a quarter of a second. Last, the contract was given no
  `requires` at all: from 2^49 bytes on the function says NO and
  reads nothing (`returns if n < 562949953421312 then checksum(input) else NO`). That is one compare in
  principle; here it is four shifts and a compare, because the decoder reads no constant above 32 bits and
  the machine read no shift by more than 16 (it does now; the code is as it was audited).

**`kbyte.py`** (910 lines) is the verifier for these: `kfn.py`'s machine, with memory as bytes and lists of
bytes in parts, numbers that depend on counts, and places. A proof (`programs/NAME/FUNCTION.proof`) is a
place for each loop:

    place +0x9b {                                   at this instruction, each time round:
        name p = r14                                names for what registers and the stack hold
        list E = out[0 .. e]                        what is written so far
        future R = out                              whatever is written later
        fact a <= p                                 what holds, in the specification's terms
        fact sequences(E ++ R, e, input[0 .. a], n) == lz4(E ++ R, n)
        decreases n - p, 9                          what gets less on the way to the next place
    }

From each place the code is run on symbols to the next place or to the return; what the next place says must
hold there; the numbers after `decreases` must have got less, the first, or the first no greater and the
second less, and so on. There is no induction in the verifier and no solver: a fact about the whole input is
carried from place to place by the specification's own equations, opened one step. The proof is not
trusted: a wrong place is refused where it does not hold. Finding the places is the prover's work: here
the model that wrote the code wrote them, from the verifier's refusals. Nothing searches for them.

**Shipped as files, as the hash is.** `programs/kpack.py` (trusted for nothing) makes one file of a
program: its functions' bytes, their names, and the proof in a section that is not loaded
(`programs/NAME/odeNAME.o`). `python3 programs/check_file.py FILE SPEC` reads a file as a loader maps it,
finds each function the specification has a contract for (by its name, or in a stripped file by the code's
bytes and the proof's offsets), takes the proof from the file, and verifies (the times: by the arithmetic's proofs the file carries, nothing
searched for; with `--search`, the times of the table further down):

| file | bytes | functions | verified in |
|---|---|---|---|
| `adler32/odeadler32.o` | 10,432 | 3 | 0.04 s |
| `lz4/odelz4.o` | 28,864 (3,088 of code) | 3 | 0.3 s |
| `varint/odevarint.o` | 3,120 | 1 | 0.01 s |
| `utf8/odeutf8.o` | 6,744 | 1 | 0.03 s |
| `base64/odebase64.o` | 6,368 | 1 | 1.7 s |
| `inet/odeinet.o` | 5,304 | 1 | 0.01 s |
| `common/odecommon.o` | 2,752 | 1 | under 0.01 s |
| `frame/odeframe.o` (a function and the two it calls) | 21,920 (1,936 of code) | 3 | 0.25 s |
| `programs/lz4-rust/main.rs` linked with `odelz4.o` (rustc 1.99.1) | 4,582,912 | 3 | (remade November 16; not timed: the machine was busy) |
| the same after `strip` | 378,520 | 3, found by their bytes | |
| each of the eight as a shared object (GNU ld 2.46) | 15,152 to 38,320 | all | each meets its contracts |

The Rust program packs with `ode_lz4_pack` at distances 1 to 8, keeps the smallest, unpacks with
`ode_lz4_decode`, and relies on nothing but the contracts: with `n + n / 255 + 16` bytes of room the packer
does not say NO; the decoder, given a block with a byte changed, says NO or gives something that fits (3 MB
of zeros: 500,011 bytes; this page as it then was: 65,904 of 66,086). `programs/test_files.py`: the proof each file
carries is the folder's and was made with the folder's specification; with one fact left out of one place
the function it is of is refused and the others are not; a reader with another specification is told so,
and with a wrong one the check fails.

**What was done to find it wrong** (`test_kbyte.py`, `kbyte_flip.py`, `kbyte_nop.py`, `audit.sh`):

- **Changed texts** (`test_kbyte.py`, 25 tests, about ten minutes). Each program's specification and
  contract with one thing changed (a constant, a bound, a `requires` or a `trace` line left out, the result
  off by one): refused. Each line of each proof left out in turn: refused (a line that could go was taken
  out). Each instruction left out in turn, and each jump, add and subtract turned round: refused, but for
  those the test counts, which keep the contract.
- **Every single-bit change of each function's code** (`kbyte_flip.py`), and every instruction left out
  (`kbyte_nop.py`, for the packing encoder), with a processor as the judge of those accepted: the changed
  object is linked with a harness (`programs/NAME/native*.c`) and run against someone else's answer on
  inputs that end where a page that faults begins. The harness asks what the contract says, no more.

  | function | single-bit changes | stopped by the decoder | refused | accepted | of those, on the processor |
  |---|---|---|---|---|---|
  | `ode_adler32` | 1,368 | 644 | 706 | 18 | 18 keep the contract |
  | `ode_adler32_blocks` | 3,144 | 1,458 | 1,607 | 79 | 79 keep the contract |
  | `ode_adler32_blocks4` | 4,400 | 2,047 | 2,241 | 112 | 112 keep the contract |
  | `ode_lz4_decode` | 8,608 | 4,026 | 4,156 | 426 | 426 keep the contract |
  | `ode_lz4_store` | 4,016 | 1,866 | 1,830 | 320 | 320 keep the contract |
  | `ode_lz4_pack` | 11,784 | 5,415 | 5,516 | 853 | 853 keep the contract |
  | `ode_varint` | 840 | 413 | 419 | 8 | 8 keep the contract |
  | `ode_common` | 1,072 | 526 | 483 | 63 | 63 keep the contract |
  | `ode_utf8` | 9,576 | 4,305 | 4,363 | 908 | 908 keep the contract |
  | `ode_base64` | 6,608 | 3,121 | 2,984 | 503 | 503 keep the contract |
  | `ode_inet` | 2,392 | 1,130 | 1,249 | 13 | 13 keep the contract |
  | `ode_unframe` (its two calls by contract) | 2,232 | 1,098 | 886 | 248 | 248 keep the contract |

  (Threadripper PRO 7975WX. The judges: zlib's `adler32`; for the decoder a decoder written in C in the
  harness, on blocks that are right and blocks that are damaged; for the encoders that decoder,
  `ode_lz4_decode`, and for the packing one `LZ4_decompress_safe` of lz4's `lz4.c` (commit `6b589e80`) as
  well; for UTF-8 a validator by the standard's table of byte ranges and the C library's converter; for
  base 64 an encoder by a table and the C library's `b64_ntop`; for the checksum RFC 1071's own C code.
  All twelve are of one run, the whole `sh audit.sh 60` on the tree of commit `20813274` (November 16): 56,040
  changes, 3,551 accepted, none without a verdict. Against the run before (`0a24723d`) one row moved:
  `ode_utf8` has 36 more accepted (908 for 872), each keeping the contract: the verifier shows more of what
  is so. Every instruction left out in turn, of seven of them: 38, 50, 4, 11, 12, 13 and 19 objects accepted
  (`lz4_pack`, `utf8`, `inet`, `adler32_blocks`, `adler32_blocks4`, `unframe`, `lz4_decode`), each keeping
  its contract on the processor. (Those seven steps fell over in the run itself: `kbyte_nop.py`, made to
  work side by side that night, started its workers afresh under Python 3.14 and they had not what the file
  had read. The tool was mended and the seven were run again in the same tree; the counts are of that.) It
  also checked and ran the eight shipped files (30,000 frames through `odeframe.o`).)
- **The unchanged functions on the processor**: Adler-32 on 6,301 inputs as zlib's; the decoder on 20,000
  blocks as the C decoder (count, bytes, and NO); the plain encoder: 12,877 blocks that decode to their
  input, NO only where the room is less than the block needs; the packing encoder: 15,065 blocks, each
  decoded to its input by three decoders (437.5 MB written as 193.8 MB: the inputs are runs and patterns);
  varint on 100,200 numbers; first difference on 20,301 pairs; the fast Adler-32 on 9,001 inputs; the
  UTF-8 validator on 2,403,649 (every input of one and of two bytes among them); base 64 on 20,601; the
  checksum on 22,001, and NO for 2^49 bytes and more when given the address of a page that faults.

**What that found.**

- An encoder's contract (`ensures lz4(out[0 .. r], n) == input if r != NO`) is met by an object that says
  NO where there is room. Of the packing encoder's 360 instructions, 44 could be left out with the contract
  still met, and seven of those objects, on the processor, said NO for a block that fits. The contract was
  true of them. Both contracts now say when NO is not given, and those changes are refused (the plain
  encoder's accepted changes of an instruction went from 17 to 14, the packing one's from 45 to 38).
- A contract with two `stack` lines was read as having the second. A contract now says each such thing once.
- `bytes_of` was a definition in `blake3.spec`. A contract whose meaning in memory rests on it could have
  been changed by changing the specification. It is the language's own now, as `words` was.
- The verifier's arithmetic was too weak, in a way that depended on luck. It decides `a <= b` by eliminating
  symbols from linear facts (`klin.py`), with a limit on the rows, and it rounds to whole numbers only where
  a row happens to be left with one symbol, which depends on the order of elimination. The packing
  encoder's bound on its output (`255 * e <= 256 * a` at each sequence) is linear and true; with it in the
  proof, another fact of the same path (that a token's low four bits are the match's length less four) was
  no longer shown, and
  changing the limit changed which fact failed. Now, for these programs, a question the first elimination
  leaves open is asked again two ways (`Facts.again`): by bounds (the least and greatest each symbol can
  be, from each row and the other symbols' bounds, rounded, to a fixed point: no order), and by the same
  elimination with fifty times the room and the goal's symbols last. Both only ever say "shown" when the
  facts cannot all hold; `test_kbyte.py` tries 3,000 small systems against all values. The hash's verifiers
  ask as before. "Not shown" was never "shown wrong", but a prover should not have to learn an order. (Still
  to do: a search that returns multipliers, which the verifier then only adds up.)
- The weak arithmetic had been doing a second job. A loop with no place (Adler-32 with an empty proof) used
  to be refused in a fifth of a second, because after two dozen turns the arithmetic could no longer show
  that a sum fits 64 bits. With the stronger arithmetic it could, and the verifier ran on, slower each
  turn: no verdict in ten minutes. What should have stopped it was never there. Now a path from the entry
  or a place may run 1,000 instructions before it comes to a place or returns (the longest here runs 286),
  and that loop is refused in four seconds for the right reason. This only refuses more.

**Speed** (pinned runs `night-speed3-*`, under the bench lock, one thread, 1 MiB; `programs/bench.c`, which
links the files shipped, `odeadler32.o` and `odelz4.o`, after `check_file.py` has checked them in the same
run; the median of three rounds):

| | Ryzen 7 9700X | EPYC 9255 |
|---|---|---|
| Adler-32, `ode_adler32` (a remainder at every byte) | 1,206 MB/s | 953 MB/s |
| Adler-32, `ode_adler32_blocks` (the sums put off for 5,552 bytes) | 3,164 MB/s | 2,309 MB/s |
| Adler-32, `ode_adler32_blocks4` (the same, four bytes a turn) | 4,644 MB/s | 3,689 MB/s |
| Adler-32, the usual C (the sums put off; GCC 15.2 at -O2) | 5,315 MB/s | 4,228 MB/s |
| LZ4 decoding, `ode_lz4_decode` | 2,109 MB/s | 1,706 MB/s |
| `LZ4_decompress_safe` | 16,011 MB/s | 13,074 MB/s |

Adler-32 written to be proved runs at 87% of the usual C on both machines; the plain one at 23%; the LZ4
decoder at 13%. (The middle row moved between rounds and between files: 2,729 in the run before, with the
function elsewhere in the file; one round of three here read 2,718. The others did not move.) What is left
has two causes, neither in the method: the Ode compiler keeps every variable but six in memory and makes
no instruction do two things; and the decoder copies a byte at a time. The hash, whose time is spent in
kernels, is at 97% of the library.

**The fast Adler-32 needed nothing new.** `programs/adler32/blocks.ode` adds bytes into the two sums for a
block of 5,552 and only then brings each below 65521 (two steps of "what is above 16 bits counts 15
times", and one subtraction). Its contract is the plain one's, against the same specification, which
reduces at every byte. The proof is two places; the inner one says the sums' remainders by 65521 are the
specification's and bounds them by the bytes taken in the block:

    fact a % 65521 == s1(input)[i]
    fact a <= 65520 + 255 * (i - i0)

It was accepted on its first run, in 0.2 s, with the verifier frozen. I had written here that this needed
"facts modulo a number, which the verifier cannot carry". It carries them as they are: a remainder is a
number with a quotient beside it, and the arithmetic knows a number has only one of each.

**Devon's Adler-32** (BLAKE3 #377; `tools/verify/machine/experiments/adler32/adler32.ode` on his branch,
proved in Lean with 133 lines of lemmas) compiles to the same 55 instructions as the one here but one: he
joins the two sums with `|` where this one adds them. `kbyte.py` stopped at that instruction ("or of
..."). It has the rule now (two numbers with no bit in common have their sum for their `or`), and his
code as he wrote it meets the contract here, with the same place of 7 lines (`test_kbyte.py` tries the
`or` with a shift of 16, of 15 and of none).

**Three things it lacked and has since 15:00**, each found by a program that wanted it: `or` of two numbers
with no bit in common (Devon's Adler-32); a shift right by more than 16 (the checksum's bound); a
sequence's value a few places after a known one, taken a place at a time (the fast Adler-32 with four
bytes a turn, which was refused before and is `programs/adler32/blocks4.ode` now).

### A function made of others, each used by its contract: `programs/frame` (November 15, evening)

`ode_unframe` opens a frame: an LZ4 block, and after it the Adler-32 of what the block decodes to. Its code
(`frame.ode`, 80 instructions) calls `ode_lz4_decode` and `ode_adler32_blocks4`, the functions of the tables
above, unchanged, and compares four bytes. Its specification (`frame.spec`) is the two parts' definitions,
word for word, and eight lines of its own:

    def unframe(bytes, cap) {
        fails SHORT if len(bytes) < 4
        let body = lz4(bytes[0 .. len(bytes) - 4], cap)
        fails SUM if adler32(body) != be32(bytes[len(bytes) - 4 .. len(bytes)])
        body
    }

`kbyte.py` takes a call by the callee's contract and by nothing else of it (`Machine.call`): what the
contract requires is shown at the call; what it ensures is so afterwards; its stack is counted. The
contracts of the two functions called are steps of the proof (`unframe.inner`: the auditor does not read
them), and each of the two is checked against that same text from its own bytes. What was measured:

| | |
|---|---|
| the caller checked | 10 ms; 4 paths; 115 instructions run; no proof text |
| the two it calls, against the contracts used | 0.5 s and 1.9 s (as alone) |
| the file shipped, `odeframe.o`, checked from its bytes | 2.4 s |
| on a processor (Threadripper), against another decoder and zlib's `adler32` | 30,000 frames, 6,746 opened and 23,254 refused, as the reference |

So using a function through its contract costs the verifier close to nothing: the work is in the function
called, once, and not again at each use. What it taught:

- **The caller is shown whatever the parts are.** With another Adler-32 in the definitions (`s[0] = 2`) the
  caller is accepted as before, and it is `ode_adler32_blocks4` that is refused. The caller's check never
  opens `adler32` or `lz4` beyond their names.
- **A callee's contract can be too weak to use, and the caller finds it.** The decoder returns NO or a
  count, and its contract does not say a count is never NO (only a comment did). The caller could not be
  shown until its own contract required `cap < NO`. The exactness is the same the other way: a decoder
  that asked `n < 2^56 - 4` is still enough for the caller (it passes n - 4); one that asks `2^56 - 5` is
  refused.
- **A question the callee's contract asks and the path does not answer is taken both ways** ("has
  `lz4(input)` failed?"): two paths after the call, one with the value named as a list, one with it
  failed. This is the piece `kbyte.py` lacked for UTF-8 too, here only at calls.
- **What `kbyte.py` does not do at a call**: a function that calls itself; a caller whose trace may not
  depend on something it reads (what the callee does with such bytes is not followed); passing bytes of
  its own stack; reading, as numbers its branches may depend on, the bytes a callee wrote (they are a
  list with a name: it can pass them on and return them).
- **A hole found on the way, in `ode.py`, and closed: a name defined twice.** The second definition took
  the first one's place without a word. `check_binary.py` (and now `check_file.py`) reads the proof's inner
  contracts after the reader's specification, so a proof could have given the public function a second,
  weaker contract, and the check would have said "meets its public contract". One attempt was made on
  `b3hashr.o` with the old `ode.py`: the weaker contract was taken in place of the reader's, and the check
  then failed for an unrelated reason; no file wrongly shown was produced. A specification with a name
  defined twice is refused now (tests in `test_ode.py`, `test_kbinary.py`, `programs/test_files.py`). This
  is of the kind that matters most: it could have said "shown" of something false.

### The night of November 16: no search in the arithmetic; LZ4 unbent, with lemmas; "false, and here is the input"

**1. The verifier searches for no arithmetic.** Every fact of arithmetic a verification needs ("these whole
numbers cannot all be >= 0") was found by elimination inside the verifier: a search, most of which shows
nothing (`DESIGN.md` has the counts). Now the search is the prover's:

- `kprove.py` (the prover's, trusted for nothing) does the same elimination and remembers how each row was
  made; when it comes to a contradiction it writes out the rows it started from and the steps that led there.
- `varith.py` (the verifier's, 90 lines with the reading of a table) takes such a proof and adds up: a step is
  "a times this row plus b times that one, divided through, rounded down"; the last row must be a number
  below zero with no name left. A proof that does not add up shows nothing.
- `klink.py` and `programs/kpack.py` run the prover when a file is made; the file carries the tables
  (`NAME.arith.z` in its proof section). `check_binary.py` and `programs/check_file.py` verify by them
  (`klin.Facts.PROOFS`); `--search` is the old way.

| file | bytes | of them the arithmetic's proofs | verified by the proofs | with the search |
|---|---|---|---|---|
| `b3hashr.o` | 80,920 | 38,747 (four of its thirteen functions need any) | 15.4 s | 18.3 s |
| `adler32/odeadler32.o` | 10,432 | 4,302 | 0.04 s | 2.2 s |
| `lz4/odelz4.o` | 28,864 | 6,728 | 0.3 s | 4.2 s |
| `frame/odeframe.o` | 21,920 | 6,898 | 0.25 s | 4.5 s |
| `base64/odebase64.o` | 6,368 | 2,008 | 1.7 s | 13 s |
| `utf8/odeutf8.o` | 6,744 | 699 | 0.03 s | 0.2 s |
| `inet/odeinet.o` | 5,304 | 1,179 | 0.01 s | 0.3 s |
| `varint/odevarint.o` | 3,120 | 976 | 0.01 s | 0.2 s |
| `common/odecommon.o` | 2,752 | 148 | under 0.01 s | 0.01 s |

(The hash gains least: its time is in opening definitions, not in arithmetic.) `test_varith.py` verifies every
shipped function with `klin.py`'s search replaced by an error, so that a search anywhere would show; a table
with every multiple changed, another function's table, and no table are each refused. The names a
verification gives on its way are now the same every time it is run (a proof speaks of them), and a file is
made the same twice.

**2. LZ4 is unbent.** `lz4.spec` was written with the room inside the definitions (`lz4(bytes, cap)`, a
failure ROOM), because the decoder gives NO as soon as what it is about to decode would pass its room, and
that this is right rests on "what a block decodes to only grows": an induction, which the verifier could
not do. The specification is now the format's own (`lz4(bytes)`: no `cap`, no ROOM), the room is in the
decoder's contract (the table above), and the induction is a **lemma**:

    lemma sequences(bytes: bytes, at: number, out: list): list {
        ensures len(result) >= len(out)
    }

A lemma is a contract of one of the specification's definitions: `requires` on what it is given, `ensures`
of its value (`result`), where it has one. The verifier shows it by opening the definition once on names,
each use inside of a definition that has a lemma taken by that lemma: as a function that calls itself is
taken by its own contract. (If the definition has a value it was reached by finitely many openings.) Lemmas
are steps of a proof: `programs/lz4/lz4.lemmas` holds four (`counted`, `copies`, `sequences`, `match`), the
file carries them, a reader does not read them, and `ode.with_proof` lets them give no name a meaning. Every
lemma is shown before any is used (`kbyte.prove_lemmas`, 0.04 s), so one that is not so shows nothing.

Where they are used: a contract asks "has `lz4(input)` a value?" on a path that does not say. Both ways are
now cases, at a call, at a guard and at the return; and in the case that it has one, the definition it is
known to be (the rest of the block from where the code is) is opened once, the uses inside by their lemmas
(`kbyte.split_defined`). The decoder, both encoders and the frame are shown against the unbent
specification; the two specifications agreed on 25,834 cases worked out on numbers.

What it gave beyond LZ4, in "not shown, of something that is so" (the verifier refusing what is true):

- two changed specifications of UTF-8 that the tests listed as "must be refused" are **the same
  specification**, and are now shown: `fails MALFORMED if b >= 248` can say 249 or 247, because a first byte
  of 245 and above, read as the first of four, holds a number above 0x10FFFF and fails anyway (2,040,719
  inputs worked out both ways agree). The line says nothing the rest does not;
- three changed objects of the UTF-8 validator that keep the contract are now accepted (50 of 344, from 47;
  each run on the processor: 50 keep it);
- a frame of four bytes holds an empty block, which decodes to nothing: "fails SHORT if len(bytes) < 5" is
  the frame's specification too, and is shown.

The cost: a refusal that used to take a tenth of a second can take ten, because the verifier now tries
the cases before it gives up. What is shown is as fast as before.

**3. "False, and here is the input" (`refute.py`).** A refusal says "not shown"; it does not say whether the
thing is false. `refute.py` works the public contract out on numbers beside the binary's own code run on
the processor (x86-64 Linux), on inputs made from `requires`, from the numbers the specification itself
writes and their neighbours, and at random; each buffer ends where a page that faults begins. It says FALSE
with the input where the two differ, where the code crashes or does not return, writes before a buffer, or
does not give back a register a callee keeps. The drivers call it after "NOT shown":

      ode_lz4_decode: NOT shown: ... the result is NO, the contract says ...
          FALSE (ode_lz4_decode, case 0): returned 0 (0x0), specification says 18446744073709551615
            input: out(out, cap=0), cap=0, input[1]=00, n=1

(the contract had been changed to `len(lz4(input)) >= cap`: a block of one zero byte decodes to nothing,
which fits in no room at all). `test_refute.py`: the nine shipped files are not refuted; eleven changed
specifications and six broken functions each are, within 26 inputs. "Not refuted" is no proof; a FALSE is
a fact one can check by hand. It is a prover's tool: nothing the verifier says rests on it.

**Not done.** Sigil has no code. No prover searches for places: each was written from the verifier's
refusals. And what `kbyte.py` still lacks, each found by a program that wanted it:

- one verifier of functions (`kfn.py` and `kbyte.py` both follow calls now, each with its own kind of memory);
- tables of constants beside the code, and multiplication in Ode (Sigil);
- lemmas of other shapes than the few `kguess.py` tries (below: it finds LZ4's four, and the numbers that
  decrease; a lemma that needs a new shape is still written by hand);
- `common.spec` is still a walk over the two runs and not "the least place they differ"; with a lemma it
  could be the latter;
- a quick no to a lemma that is not so: most are refused in milliseconds, but one that sends the opening
  round in cases (LZ4's `sequences` said to be a number) is refused only at the limit of 500 cases, after
  110 seconds. A wrong proof costs the reader time, never a wrong yes; a bound in time would be better;
- reads and writes of more than a byte at a time, for speed;
- joining paths that have come to the same state (base 64). (A specification's question the code's path
  does not answer is now taken both ways where it asks whether something has a value; a comparison of two
  numbers inside a definition is taken both ways only where a definition is opened for that.)
- a constant above 32 bits in the code (the checksum's own bound; it asks in four shifts);
- in-place work: a byte the function may write and has not yet written is unknown to it, so a function
  that reads and writes one buffer cannot be shown (tried: ASCII made upper-case in place, 44 instructions:
  refused).

### Later that night: the search out of the verifier's files; definitions shown to come to an end

**No file a verification of a shipped binary loads can search.** The arithmetic's search (elimination,
bounds) was in `klin.py` beside the facts, used where no table of proofs was given. It is now `kprove.py`'s
(the prover's, 150 lines of code), loaded only where there is no table: by the tools that make proofs, the
tests, and `--search`. `klin.py` is 174 lines of code and holds no elimination. A verification of a file of
`programs/` no longer loads the hash's driver or the kernels' two verifiers (`kproof.py`, 16 lines, reads
the proof's form; the helpers `value` and `lin` moved to `klin.py`): `verify.py` listed 10 files and 3,979
lines of code for an LZ4 file (it was 12 and 4,587), 11 files and 3,445 for the hash (3,484). With what
follows below (definitions that end, `any`, the record, `kends.py`) it lists 4,183 and 3,461.

**A definition that uses itself is shown to come to an end.** A specification's definition that never
ended on some input would have no value there and no failure, and a contract written with it would say
nothing of that input: a hole a reader could not see by reading the contract. A lemma may now say
`decreases E`: where the definition uses itself, or another that uses it back, E is not below zero, and it
is less for what is used. The verifier shows that with the lemma's other clauses (the same opening), so it
costs a reader nothing:

    lemma points(bytes: bytes, at: number, count: number): number {
        requires at <= len(bytes)
        decreases len(bytes) - at
    }

All six such definitions of `programs/` have it (`counted`, `sequences`, `match` of LZ4, where the last two
use each other; `points` of UTF-8; `varint`; `alike`), a verification says so ("the definitions that use
themselves (...): each is shown to come to an end") or names those that are not, and `check_programs.py`
fails on one that is not; `--json` records both, with how the arithmetic was verified and the verifier's own
files and digests (it was written before the checks of the calls: now last). Refused in the tests: a number that grows, one that stays, one that could be
below zero, a lemma without the number where another definition of its ring has one. What the first try
taught: `alike(a, b, at)` reads `b[at]` and so ends, with a value, only where `b` is no shorter than `a`;
the lemma had to say so (`requires len(a) <= len(b)`), and the public contract already gives both the same
length.

**And the refusals are fast again where there is such a lemma.** The cost named above (a refusal that took
a tenth of a second taking ten) was UTF-8's: with every question about a value taken both ways, a path that
was going to be refused opened `points` again and again first. With the lemma of `points` a use of it is
taken by the lemma: of 40 instructions of `ode_utf8`, each left out in turn, the slowest verdict takes 0.3
seconds, against 11.7 without the lemma file (the five slowest: 8.6 to 11.7; measured on this machine, the
same day). Two more
changed specifications of UTF-8 are accepted now, and both are the same specification (`b < 192` made
`b < 193` in the first check of a first byte; `b < 128` made `b < 129` in the count: 244,205 inputs agree on
each, and the two neighbouring changes that are not the same are refused).

**BLAKE3's tree too.** `subtree` and `children` (`blake3.spec`) use each other: a message of more than one
chunk is two parts. The first try stopped at "a word: this verifier's programs are of bytes and numbers";
what it took is a kind `any` for a lemma: a thing the lemma neither asks about nor says anything of (the
key, the flags, the values), passed on only. A lemma of kind `any` with no clause says nothing of its
definition, so there is nothing to show, and it keeps an opening from going into the compression function;
of a thing of kind `any` nothing can be shown. The file carries five (`proofs/blake3.lemmas`):

    lemma subtree(key: any, flags: any, t: number, bytes: bytes): any {
        decreases 2 * len(bytes)
    }
    lemma children(key: any, flags: any, t: number, bytes: bytes): any {
        requires len(bytes) > 1024
        decreases 2 * len(bytes) - 1
    }

(`children` stands between a tree and its two parts, so its number is one less; the left part is 1024 times
the greatest power of two that leaves bytes for the right, so each part is shorter than the whole.) Shown in
0.3 s. Refused in the tests: seven other numbers or `requires`, a lemma that says something of words, and
three changed specifications in which a part is not smaller (`<=` for `<` in the split among them). A
verification of `b3hashr.o` says "the definitions that use themselves (children, subtree): each is shown to
come to an end" (see below for what that line now rests on); `verify.py` lists what that one line loaded
beside the rest (`kbyte.py` and `kends.py`, 1,063 and 116 lines of code: it is no part of what shows the code meets the contract).

### A hole in the line about coming to an end, found and closed the same day (`kends.py`)

**Kind: shown, of something false** (in the line a verification prints about the specification; not in
whether the code meets the contract). The line said "each is shown to come to an end" when every definition
that uses itself had a lemma with a number that decreases, and the lemmas were shown. But a lemma speaks
only where its `requires` holds, and a lemma comes with the proof, which is not trusted:

    lemma points(bytes: bytes, at: number, count: number): number {
        requires at < at
        decreases 0
    }

is shown (of nothing: no use meets it), and the line was printed. A maker could have had a file say its
definitions end when one of them goes on for ever. No shipped file did; the lemma audit's own output had
the sign of it (two changed lemmas "shown, and judged on no use") and I had read that as harmless.

Now (`kends.py`, 116 lines of code): the line is about **the public contracts**, and it is said only where,
from the contract inward, every use of a definition is one its lemma speaks of. Each definition the
contract's text names is gone through once from what the contract gives it (an argument as it is, with its
length and what the contract `requires`; a part of what the function wrote, as any bytes; anything else,
as a thing of which nothing is known), and every use inside of a definition with a lemma must meet that
lemma's `requires`. Inside a ring the showing of the lemmas already asks the same. No search is used: what
the plain facts do not show is not shown. All thirteen public contracts here pass, BLAKE3's among them.
**Where it is not shown, the file is NOT shown** (exit status 1), though each function's own line stands: a
contract that speaks through a definition that may go on for ever says nothing of the inputs on which it
does, and "meets its contract" would be taken for more than it is.

(The language also has machines that go round `while` something holds; none of the specifications here uses
one, the proof's own part of the hash does. A contract that spoke through one is "NOT shown" to end: nothing
here shows such a machine stops.)

What it found beside the hole: `ode_common`'s definitions end *because* its contract gives both runs the
same length. With `b: m bytes` the line is "NOT shown" (the walk reads the second run past its end), and
with `requires n <= m` added it is shown again (`test_kends.py`).

The lemma audit now makes each lemma require the impossible in turn and asks that the line is then not
said; its test puts the old way of making the line back and the audit reports the hole.

**And the same question asked of every other line a verification prints: could a maker's proof make it
say what is not so?** One more, by silence. Which functions of a file are verified is the proof's to say
(its `at` lines). A proof for the LZ4 file that left `ode_lz4_pack` out got exit status 0 and "2
function(s) in this file ... each meets its contract": true of the two it named, and silent about a third
function in the file with a public contract in the same specification. Now a public contract the proof
leaves out is named ("NOT verified"), and if the file has a function of that name the verification is NOT
shown (`test_files.py`). The summary says "verified in this file". (The hash's file was not open to it: there
one named function and all it calls are verified, and the bytes that are not are counted.) The other lines:
which specification (the reader's or the file's, with its digest), each function's verdict, how the
arithmetic was verified, come from the reader's text or from what the verifier did.

**And of the lemmas themselves: the kind was taken as said.** A lemma says what kind of thing its
definition's value is (`: list`, `: number`, `: record(value, next)`), and a use is given a thing of that
kind. Where a lemma ensured something, a wrong kind was refused (the clause spoke of the wrong kind of
thing). Where it ensured nothing, nothing looked: `lemma counted(bytes: bytes, at: number, sum: number):
list { }` was shown, and `counted` gives a record. **Kind: shown, of something false.** I could not make a
function accepted wrongly with it: with the verifier as it was and seven lemma files each with one false
kind, the LZ4 decoder with each of 254 instructions left out is accepted in none of the 1,778 cases (and
the decoder as it is, is refused with each: a use of the thing as the wrong kind stops the verifier). It is
closed all the same: the value the opening gives must be of the kind said (`kbyte.py`, one check in
`prove_lemmas`). The lemma audit now changes each lemma's kind, with and without what it ensures, and its
judge on numbers looks at the kind of what the definition gave; run against the verifier as it was, it
reports the two it finds in the common-start program ("the lemma says the value is a list, and the
definition gave int").

In files the running audit covers, this changed the three drivers' lines (`check_binary.py`,
`programs/check_file.py`, `programs/check_programs.py`: what is printed and the exit status in the case
above), and one check in `kbyte.py`'s `prove_lemmas` (the kind). `kends.py` is new. The part of the audit
that covers `kbyte.py` was run again for it, on the head: nothing moved.

**How long a verification takes, and where.** `b3hashr.o`: 16 s under CPython 3.14, 7.6 s under PyPy 3.12
(the same files, the same verdict; the short verifications of `programs/` gain nothing from PyPy: 3.1 s
against 2.6 for the eight files). Nearly all of it is the specification's definitions opened on names
(`ode.py`'s `eval` under `kspec.py`'s `kept`: 51 of 60 profiled seconds), and two functions take most
(`b3l_wide128`, `b3l_part32`). So "faster" is there, and it is also where a proof could carry more.

### A first function of a verifier's own work, in Ode (`programs/decimal/`: a seed)

One of the bottoms the design allows is a verifier written in Ode, specified in Ode's specification
language, and shown by Ode's own verifier. Nothing of the verifier is in Ode yet. This is the smallest
piece of its work there is, to see what the first step costs: **reading a count as a proof's header
writes it** (`file NAME LENGTH`, `at OFFSET NAME`: one to nine decimal digits; `kproof.py` does it with
Python's `int`).

    def digit(b) { fails MALFORMED if b < 48 || b > 57   b - 48 }
    def digits(bytes, at, sum) { if at == len(bytes) then sum else digits(bytes, at + 1, 10 * sum + digit(bytes[at])) }
    def decimal(bytes) { fails MALFORMED if len(bytes) == 0   fails MALFORMED if len(bytes) > 9   digits(bytes, 0, 0) }

    contract ode_decimal(input: n bytes, n: number) {
        returns if failed(decimal(input)) then NO else decimal(input)
        trace depends on input
        stack 56
    }

`decimal.ode` is 30 lines (ten times a number is its shifts by three and by one, added: Ode has no
multiplication); the compiler's 89 instructions meet the contract **with no proof text**: the loop is run
out, nine digits at most (0.1 s). The lemma that `digits` comes to an end is the one `kguess.py` writes.
Its own audit, on the workhorse: 2,576 single-bit changes, 135 accepted, each as a loop in C on 20,000
inputs; each instruction left out in turn, 8 accepted, each keeping the contract; the unchanged code on
203,616 inputs (`audit/kbyte-flip-decimal.txt`, `kbyte-nop-decimal.txt`; `programs/test_decimal.py`).

What it is not: used. `kproof.py` still reads its numbers with Python, and a verifier in Ode would need
what Ode lacks for the rest (lists that grow, records, a way to call out for the bytes of a file). It is
not one of the shipped programs and is in none of their counts. It shows only what the first piece costs:
three definitions, a function of thirty lines, nothing else written, and under half an hour with its audit.

### A second verifier of the arithmetic, written apart (`varith2.c`)

"A is right if B or C is": one of the bottoms the design allows is a second verifier, written apart, that
verifies the same proof. The first piece small enough to have one is the arithmetic. `varith2.c` (C, 310
lines, 267 of them code, its own whole numbers of 320 bits; it links only zlib, to open the table) shares no line with
`varith.py`. It reads the proofs a file carries and says of each whether it adds up: the same rule (two
rows, each times a whole number above zero, added; divided by what divides every multiple; the plain number
rounded down; at the end no name and a number below zero).

    cc -O2 -o varith2 varith2.c -lz && ./varith2 b3hashr.o programs/*/ode*.o
    varith2: 7850 proofs of arithmetic: 7850 add up to "these rows cannot all hold"        (0.2 s)

All 7,850 proofs of the nine shipped files, on its first run. And the two are put against each other
(`test_varith2.py`): 1,500 of those proofs, each changed in one place (a multiplier, which rows a step
takes, a plain number, a multiple, a name gone, a step left out, another proof's steps, a multiplier of
zero or below), and of each what the first says and what the second says: **the same, 1,500 times**, both
answers among them. Built and passed with Apple clang 21 and with GCC 15.2.

What it does not say: that the rows a proof starts from are ones the verifier knew at the place it used
the proof. That is `varith.py`'s other half (a start must be among the rows given) and depends on the
path; a second verifier of it would be a second verifier of functions. So this is the smallest instance of
the idea, not yet much of the assurance: a mistake in the first one's adding, dividing or rounding would
be seen by code that shares nothing with it but the file's form. Its worth is also what it shows about
the proofs' form: 310 lines of another language read it and decide.

### A prover that guesses (`kguess.py`)

Who finds the number that decreases? The eight lemmas above (six of `programs/`, BLAKE3's two) were written by hand, and one took a second
try (`children` is one less than `subtree`). `kguess.py` is the smallest prover there could be: for each
ring of definitions that use themselves it tries the few numbers there are (`n`; `len(b) - n`; `len(b)`;
for a ring of two, `2 * len(b)` and one less), with none, one or two of a few `requires` (`n <= len(b)`;
`len(a) <= len(b)`; `len(b) > C` for a number the definitions name), and asks the verifier of each. For
the definitions a ring uses that work on words it writes the lemma of kind `any` that says nothing.

`python3 kguess.py --again` takes every `decreases` out of the six lemma files (and every lemma that says
nothing else) and looks for them again: **found for 8 of 8 rings**, from the specifications and the
lemmas' other clauses. UTF-8's, varint's and the common start's are found from the specification alone
in 6, 1 and 31 tries; LZ4's two rings in 246 (1.8 s); **BLAKE3's tree in 1,786 tries, 43 s: the same two
lemmas as the ones written by hand, and the three that say nothing.** What it cannot find it says
(`f(a, n) = f(a, n)`: "no number found").

**And what a lemma ensures** (`python3 kguess.py SPEC --whole`: the lemmas from nothing). A few shapes: a
field or a number not below one the definition was given (or that and one more); a list no shorter than
one it was given; place k of a sequence k longer than the list it starts from, under `n >= 1` and
`n <= len(l)`. Each clause is kept if the verifier shows it with the rest; in a ring of two, one clause
for each together (what one ensures rests on what the other does). **From `lz4.spec` alone it writes the
four lemmas of the unbent LZ4, clause for clause the ones written by hand, in 273 tries and 1.9 seconds;
and with what it wrote, in place of `lz4.lemmas`, the decoder, both encoders and the frame's opener are
shown** (with no lemmas the decoder is refused). For UTF-8 and the common start it also finds what nobody
had asked (`points`' count is not below the count before; `alike`'s place not below where it began).

It is trusted for nothing: what it prints is a lemma like any other, and the verifier shows it or does
not. It is here for what it shows about the design: the guessing costs the reader nothing wherever it is
put, so it is put outside what he relies on. The shapes are few and fitted to these programs; the next
program will want one more, and adding it touches nothing a reader relies on. (The shipped files carry the
lemmas written by hand: the audit under way is of them.)

### And the places of loops (`kplace.py`): a function shown with nothing written by hand

A place is what the proof says of a loop: what the registers hold, in the specification's terms, each time
the code comes round. They were written by whoever wrote the code, from the verifier's refusals.
`kplace.py` does that for a function with one loop, and it is led the same way: a refusal that names a
thing the proof says nothing of ("a compare of r12 and n"; "add of r13 and 1") is taken to mean that thing
wants something said of it. It asks the verifier what each thing the loop writes is when the code first
comes there (0? 1?), and then tries, the plainest first: the count of bytes taken (`i <= n`,
`decreases n - i`); another count not above it; the same number every time; place `i` of one of the
specification's sequences; nothing said; and one fact, that the definition the contract speaks of (or one
it uses), from here, is the whole.

| function | instructions | found | the proof found |
|---|---|---|---|
| `ode_adler32` | 55 | 32 tries, 3.6 s | the two sums are places `i` of `s1` and `s2`: line for line the one written by hand |
| `ode_common` | 45 | 29 tries, 3.1 s | `alike(a, b, i) == common(a, b)`; the flag is 1: the one written by hand |
| `ode_utf8` | 300 | 91 tries, 13.4 s | `points(input, i, count) == utf8(input)`, `count <= i`, the state in the stack is 0, four things of which nothing is said: the one written by hand |
| `ode_inet` | 88 | not found | (it wants `i % 2 == 0` and a bound on a sum: not among the shapes) |

With `kguess.py` before it, **the whole proof of these three comes from the binary and the specification
alone**: the lemmas (the number that decreases), then the place; the verifier shows the function by what
the two wrote (`test_kplace.py`). Functions with two loops or more are not tried (six of the twelve;
`ode_varint`'s loop is run out and `ode_unframe` has none: those two need no proof text at all).

**Another build of the same function.** In Lean a proof was of one build's bytes and another compiler
undid it. Here the three functions were assembled again with two of their registers exchanged, as another
compiler might hold them: the proof written by hand names registers and is refused for that build; the
prover finds the build's own proof, and it in turn is refused for the first build (`test_kplace.py`). So a
proof need not be kept in step with the compiler by hand.

**As an audit** (`kadversary.py`). The flips ask the verifier of changed code with the proof written for
the unchanged code; most are refused because that proof no longer fits, which says little about whether
some proof would get the changed code accepted. `kadversary.py` leaves each instruction out in turn and,
where the verifier refuses with the proof as written, lets the prover look for another; every changed
object accepted either way is run on a processor. `ode_adler32`: 44 left out, 6 accepted as written (all
keep the contract), none more by a proof found. `ode_common`: 34, none accepted either way. `ode_utf8`: 287, 50 accepted as written (all keep the contract),
none more by a proof found within 60 tries (`audit/kadversary.txt`).
The prover is weak, so this is a small thing; its control is that it does find the proof of the unchanged
code and of the other build.

The same caution as above: the shapes are few and fitted to these programs. What it shows is where the
work of finding a proof lives. None of these files is loaded by a verification.

### An audit of the part that shows lemmas (`lemma_audit.py`)

The flips of the code's bits do not ask whether the verifier could show a lemma that is not so; and a false
lemma, once shown, could show a function by something false. So the lemmas have an audit of their own, with
its own judge: **the specification worked out on numbers** (`ode.Numbers`: no symbols, no facts, nothing of
the verifier), on inputs made for it (LZ4 blocks an encoder here writes, some with a byte gone wrong; UTF-8
of the edges; messages of BLAKE3 around the chunk and tree boundaries), every use of a definition with a
lemma noted with what it was given and what it gave (a sequence's lemma: places of it worked out straight). Of each use: where `requires` holds, `ensures` must
hold of the value; and where a use is inside another of its ring, `requires` must hold of it, the outer
number that `decreases` must not be below zero, and the inner must be less.

Two ways, over the six lemma files (`audit/lemma_audit.txt`; ten minutes, nine of them BLAKE3's):

| | copies | refused | shown, and so on every use tried | shown, judged on no use | shown and false |
|---|---|---|---|---|---|
| a lemma changed (a number one more or less, a comparison made another, + and - exchanged, a `requires` left out, a name made another or 0 or 1, the kind of its value made another, the lemma made to require the impossible) | 367 | 350 | 11 | 6 | **0** |
| the lemmas as they are, of a changed specification (the same changes, in the definitions the lemmas speak of and those they use) | 621, of which 36 are no specification | 178 | 407 | 0 | **0** |

The eleven changed lemmas that are shown say less than the ones in the files, or the same, or ask more
(`result.value >= 0` for `>= sum`; a match makes the output longer, not only no shorter; `at == len(bytes)`
for `at <= len(bytes)`). The 407 changed specifications are ones the lemmas are still true of (a round
constant of BLAKE3 moved does not make its tree stop ending). The six "judged on no use" are lemmas made to
require the impossible: shown, of nothing; with each of them "its definitions come to an end" is not said
(the hole described above; the other 29 such are refused). The 38 lemmas whose kind was made another are
all refused.

**The audit's own control** (`--control 7`; `audit/lemma_audit-control.txt`): a verifier made wrong in the
process, every seventh question about the numbers answered "shown", shows five false lemmas of LZ4 and of
the two runs' common start, and each is found out with its input: an `ensures` that does not hold of what
`counted` gave, a number that "decreases" from 70 to 70.

The first run of it reported three holes. They were its own: on numbers it follows a definition's use of
itself one inside another, the language allows 400 deep, and it had made inputs of 499 bytes. It makes
none above 300 now and allows 3,000 while numbers are worked out (the verifier is asked with the
language's limit as it is). It is in `audit.sh`.

What this is not: a proof. It is the kind of evidence the flips are: every acceptance among many near
misses, judged by something that is not the verifier. It does not change the lemmas' kinds, the
specification's shape, or more than one thing at a time.

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
load, a byte read, a 32-bit store), four cases in the verifier, a five-line specification, and it passed on
its first run, a few minutes after the start. Its audit (below) then ran clean, and `kremove.py` on it found
eight instructions whose results nothing reads (BLAKE3 #398).

    python3 kcheck.py k32 --object OBJECT [--mutants]
    python3 test_kcheck.py            # all of it from the sources, with the controls: 9 tests, 12 s

## Every number of blocks: a proof that is found, then checked (`kloop.py`, November 15)

(Since November 17 `kfn.py` shows this, by the same induction on its own machine, and `kloop.py` is gone: the
last section. What follows is as it was written.)

The table above is each kernel for one number of blocks (16, or 1), run to its end. `kloop.py` shows K32, P32
and P16 for **every** number of blocks `n >= 1` and every value of the four flag bytes (flags, start, end,
last length): the kernels' whole interface. It is a first trial of how proofs could be made for code with
loops: the proof is a small text the prover finds, and the verifier reads it and does no searching.

- **The specification is the sequence `chunk`**, a lane at a time: `h[0]` is the key; `h[b + 1]` is
  `compress(h[b], block b, counter, length, flags)` with the start byte or-ed in for block 0, and the end
  byte and the length byte for the last block; what is stored is `h[n]`.
- **A proof** names one place in the code, the head of the loop over blocks, and says what each register and
  frame cell holds there when b blocks are done: kept as it was after the first block, a number `c + cn*n +
  cb*b`, or a word of the specification's state. K32's, with every name the verifier does not need taken out
  (`proofs/k32.json`, 1,088 bytes): the place `+0x133`; `r13 = n - b`; `r14 = 64*b`; six registers kept (the
  flags, the stack and frame pointers, the inputs' table, the output's address); `zmm0` to `zmm15` hold the
  state's eight words for lanes 0-15 and 16-31; four frame cells (the counters) kept.
- **The verifier** runs the code from its entry through the first block; then from the place, for an unknown
  b and an unknown state, along every path to the place again or to the return; and compares terms by
  identity with the specification's next state. That is Floyd's method. "Is this the last block?" is decided
  from two linear facts (`b >= 1`, `b <= n-1`) by adding them up.
- **The prover** runs the loop twice, compares the second and third visits of the place, guesses, and weakens
  the guess where the verifier refuses. Nothing it does is trusted.

| kernel | proof found in | proof checked in | paths of the step |
|---|---|---|---|
| K32 | 0.36 s | 0.18 s | one back to the place, one to the return |
| P32 | 0.37 s | 0.18 s | the same |
| P16 | 0.18 s | 0.09 s | the same |

What was done to find it wrong: `test_kloop.py` (25 changed kernels: no proof is found for any, and the true
proof is refused on each; 7 wrong proofs are refused on the true kernel; an entry is refused against the other
entry's specification). The true kernels on a processor on the same contract (`kflip_native.c … any`: 1 to 20
blocks, any flag bytes, any counter, anything in the packed word's upper half): 5,000 cases each, as BLAKE3.
And the single-bit audit with a processor as judge (`kflip.py --general`; "accepted" = a proof is found and
checked):

| kernel | changes | stopped by the decoder | refused (no proof) | accepted | of those, as BLAKE3 on the processor |
|---|---|---|---|---|---|
| P16 | 22,144 | 14,132 | 7,799 | 213 | 213 (1,000 cases each) |
| K32 | 35,824 | 22,053 | 12,019 | 1,752 | 1,752 |
| P32 | 35,824 | 22,053 | 11,893 | 1,878 | 1,878 |

With the whole interface in the specification, what the contract "does not see" in P16 falls from 142
accepted changes to 13 (a larger frame, a 64-bit form of a 32-bit move): the statement now says what the code
does.

What this trial does not show: more than one loop that needs a proof (the seven rounds inside are run, not
proved by induction); a loop whose state is a data structure in memory; calls; code that is not a kernel.
The proof's form is made for this shape of loop. The verifier is `kcheck.py` and `kdecode.py` with 300 lines
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
- **The verifier** runs the code from the entry and from the place along every path. To the place: the stack
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
| `push` | 568 | 304 | 260 | 4 | 4 (3,000 cases each) |
| `merge` | 2,528 | 1,296 | 1,127 | 105 | 105 |
| `add` | 688 | 348 | 256 | 84 | 84 |

**What that audit found.** Run first, it had 24 changes of `merge` accepted that the processor told from the
machine: all in `mov rdx, 64`, the block length given to the kernel. I had written the two kernels' contract
by hand as "the low byte of the length"; the SSE4.1 kernel reads all of EDX. The contract was wrong, not the
verifier's logic: a callee's contract taken on trust is a hole until it is itself checked against the callee's
bytes (the Lean proofs have it right for that reason). Reading the accepted changes then showed a second
thing: `mov rcx, 5` (the platform word that selects the AVX-512 kernel) could become any number, and the
AVX-512 kernel be called on a machine without it, with the contract none the wiser. The contract now says the
AVX-512 kernel is called only where the platform word is 5.

**The kernels `merge` calls are checked too** (`kone.py`, written after that finding; since November 17 by
`kfn.py`, and `kone.py` is gone: the last section): the library's
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
| `blake3.spec` | 185 | the specification (147 lines), and the public contract: that of the function a user calls |
| `LANGUAGE.md` | 157 | what a specification's text means and what a contract means: one page in two parts, the same for every program |
| `DESIGN.md` | 175 | the design: what is wanted and given up, the rules for code written to be proved, how it stands to types-as-proofs |
| `proofs/inner.spec`, `proofs/*.json` | 185 | the inner contracts (of the functions inside), the layouts of two records; the wide kernels' and `merge`'s places |
| `hash.ode`, `glue/*.S` | 332 | the hash written to be proved; the assembly the Ode compiler prints of it (and of the stack's three functions) |
| `b3hashr.o` | | the binary: 80,920 bytes, the specification and the proof in it |
| `VERIFY.md`, `verify.py` | 100 + 95 | the reader's page; one command: the contract, the verification, and which files of this folder ran to reach it (their lines and digests) |
| `check_binary.py` | 140 | what a reader runs on the binary, or on what a linker made of it |
| `programs/` | | six other programs (Sigil a specification only): each its specification and public contract, its Ode source, the compiler's assembly, its proof, a harness for the processor; `check_programs.py`, `test_specs.py`, `bench.c`; `blake3-rust/` |
| `kbyte.py`, `test_kbyte.py` | 1,356 + 804 | the verifier of those programs (bytes, numbers, places, calls by contract, lemmas, definitions that come to an end); its tests |
| `varith.py`, `kprove.py`, `kproof.py`, `test_varith.py` | 90 + 185 + 29 + 174 | the arithmetic: the verifier's side (a proof added up; nothing searched for), the prover's side (the search and the writing of proofs; trusted for nothing), the reading of a proof's form, their tests |
| `varith2.c`, `test_varith2.py` | 310 + 129 | a second verifier of the arithmetic's proofs, in C, written apart; the two put against each other on changed proofs |
| `kguess.py`, `test_kguess.py` | 406 + 78 | a prover that guesses lemmas (the number that decreases; what a definition ensures, of a few shapes); trusted for nothing |
| `kplace.py`, `test_kplace.py` | 235 + 65 | a prover that guesses the place of a loop, led by the verifier's refusals; trusted for nothing |
| `lemma_audit.py`, `test_lemma_audit.py` | 464 + 82 | the audit of the part that shows lemmas: changed lemmas and changed specifications, judged on numbers |
| `kends.py`, `test_kends.py` | 137 + 85 | whether the definitions a public contract speaks through come to an end on everything it allows (the lemmas' `requires` met from the contract inward) |
| `refute.py`, `refute_run.c`, `test_refute.py` | 421 + 145 + 76 | "false, and here is the input": a contract worked out on numbers beside the code run on the processor (a prover's tool); its tests |
| `kbyte_flip.py`, `kbyte_nop.py` | 117 + 37 | their single-bit audit and every instruction left out, the processor judging |
| `programs/kpack.py`, `programs/check_file.py`, `programs/test_files.py` | 55 + 78 + 82 | a program as one file with its proof (untrusted); what a reader runs on it, or on what a linker made of it (`--json`: what was checked, for a benchmark's record); tests |
| `klink.py`, `klink_flip.py`, `test_kbinary.py` | 134 + 72 + 182 | makes the binary of the assembler's objects (untrusted); every single-bit change of what a linker would have written; tests of the reading of a linked file |
| `check_all.py` | 120 | every function from an assembler's objects, and that the hash's functions end |
| `ode.py`, `kspec.py`, `klin.py` | 754 + 565 + 249 | the specification's reader; its algebra on symbols; numbers that depend on counts and the facts about them (no search: that is `kprove.py`'s) |
| `kdecode.py` | 581 | reads the ELF file (an object's sections, names and relocations; a linked file as a loader maps it) and decodes the instruction forms the code uses, and no others; no disassembler |
| `kfn.py`, `test_kfn.py` | 1,360 + 131 | the verifier of functions (since November 17 of the kernels too: a place, by induction); its tests |
| `kfn_flip.py`, `khash_native.c` | 133 + 176 | its single-bit audit; the whole hash on a processor against BLAKE3 in C |
| `khash_bench.c`, `earlier/*.S` | 37 | the speed of `hashr`, of the library, and of the earlier `hashf` (its assembly), in one harness |
| `kwide.py`, `test_kloop.py` | 126 + 131 | the prover of a wide kernel's place (trusted for nothing; the audits' adversary); the wide kernels' tests, through `kfn.py` |
| `kone_native.c`, `test_kone.py` | 86 + 122 | the one-block kernels on the processor; their tests, through `kfn.py` |
| `kernels.py`, `../wide/*.ode`, `../wide/test_sources.py` | 55 + 1,270 + 104 | the five kernels made from their Ode sources (a maker's step); the sources; that each is the library's kernel byte for byte |
| `kterms.py` | 79 | 32-bit terms compared by identity; the reading of an instruction's text; the registers' names |
| `test_kholes.py` | 106 | the two holes of November 17: the copies that were shown, each refused |
| `kcheck.py`, `test_kcheck.py` | 462 + 163 | the first verifier: a kernel's instructions run to the end on symbols; its tests |
| `kcheck_cross.py` | 109 | kcheck's reading of each instruction against the Lean model's processor-validated test vectors |
| `kflip.py`, `kflip_native.c`, `kflip_thunk.S` | 206 + 160 + 66 | the kernels' single-bit audit, and the processor's word on each change accepted |
| `kglue.py`, `kglue_flip.py`, `kglue_native.c`, `test_kglue.py` | 569 + 136 + 109 + 119 | the stack's functions (the earlier trial): prover, verifier; the audit; the tests |
| `kremove.py` | 41 | which instructions can be replaced by a no-op with the contract still met: for a person to read |
| `test_ode.py` | 105 | the specification on the vectors, and 24 changes of its text; what is not the language is refused |
| `audit.sh`, `audit/` | 45 | every single-bit audit, with this machine's processor as the judge; their outputs |

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

(Every single-bit audit was run again on November 16 by `sh audit.sh 60` on the tree of commit `20813274`
(the arithmetic by proofs, the lemmas, the unbent LZ4, `any`), and `audit/` holds the outputs: 353,192
single-bit changes in all, 18,069 accepted, each of those as its specification on the processor, none
without a verdict (900 s a change at most). But for `ode_utf8` (36 more accepted) every count of the flips
is what it was in the run before, at `0a24723d`. After that commit `kbyte.py` got one more check (the kind a
lemma says) and three drivers a line: so the part of the audit that covers `kbyte.py` was run again on the
head (`sh audit.sh 36 programs` at `aea4e440`): the twelve functions' 56,040 changes and 3,551 accepted,
the seven functions with each instruction left out, the shipped files, each count as in the whole run;
and in the same run the lemmas' audit and the prover's (see the end of "Programs other than the hash").
`audit/` holds the whole run's outputs for the hash and that run's for the rest.)

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
   is. A change the verifier accepts is then linked with BLAKE3 written out in C and run on an AVX-512
   processor on 1,000 or 2,000 random inputs the contract allows: the chaining values, every byte beside the
   output, the inputs, their table, the key, the kept registers and the stack pointer are compared, and each
   thing the kernel is given lies between two pages that fault. An accepted change the processor tells from
   BLAKE3 is an error of the decoder or the verifier.

   | kernel | changes | stopped by the decoder | refused by the verifier | accepted | of those, as BLAKE3 on the processor |
   |---|---|---|---|---|---|
   | P16 | 22,144 | 14,132 | 7,670 | 342 | 342 (1,000 cases each) |
   | K32 | 35,824 | 22,053 | 12,014 | 1,757 | 1,757 (1,000 cases each) |
   | P32 | 35,824 | 22,053 | 11,888 | 1,883 | 1,883 (1,000 cases each) |
   | `output16` | 29,384 | 17,516 | 11,474 | 394 | 394 (2,000 cases each) |

   (Threadripper PRO 7975WX, clang 21.1.8's objects, the verifier and decoder as they are at commit `55bcb1c6`;
   17 s for P16, 27 s for `output16`, 13 minutes each for K32 and P32, 48 at a time.
   No change ended without a verdict. Controls in each run: the unchanged object is accepted and runs as BLAKE3;
   asked for a block more than its inputs hold it faults; a refused change of a rotation does not run as BLAKE3.)

   Where the accepted changes of the first three are: in the no-ops an assembler pads with (148), in the
   operand of a prefetch (2,560), in the four bytes of a field the linker fills (832), and 442 elsewhere, of two kinds
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
   inputs all the same: the verifier refuses what it cannot show, as it should.

**What the fifth audit found** (each fixed, each now a test in `test_kcheck.py`):

- *The verifier accepted a kernel that faults.* A frame of `0x101` to `0x120` bytes (in place of `0x100`) left
  the stack pointer off the 64-byte boundary the aligned stores need; kcheck took the frame as aligned whatever
  its size. Six such changes were accepted and crashed on the processor. The frame must now be whole cells.
- *A changed kernel ran the verifier out of memory.* A sum that adds a register to itself in a loop doubles a
  flat term each turn. A sum or xor is now at most 64 terms (BLAKE3's widest is 57), and a longer one is refused.
- *An addition of 32 bits was computed in 64*, and a push, pop or return did not ask that the stack pointer be
  among the saved registers. No accepted change turned on either; both are now as the processor does it.
- *The decoder read encodings no assembler writes* (a REX bit an instruction does not use, a scale with no
  index, `EVEX.R` beside an opcode digit) as the instruction without them: 277 accepted changes of P16 alone.
  What a processor does with such bytes was not tried and is not a question to rest on: they are now stopped.

Before these fixes the first audit (cross-checking, item 3) had found two more: `vzeroupper` read as a no-op and
an 8-bit `or` read as 32 bits.

## What it rests on (what a reader must trust or check)

- The specification and the public contract (`blake3.spec`, 185 lines; for another program, its own
  `.spec`), with what they mean (`LANGUAGE.md`), and the programs that read them and the
  bytes: for the hash `ode.py`, `kspec.py`, `klin.py`, `kdecode.py`, `kterms.py`, `kfn.py` (and the
  drivers; since November 17, when the kernels' own verifiers went: `verify.py` lists them, 3,072 lines of code); for the programs of `programs/`, `kbyte.py` in place of the last four: 910 more;
  `kglue.py`, 569 (their provers, about 150 of those, need no trust). And Python.
- No assembler and no linker, when the file checked is the file run (`check_binary.py`). A loader that
  maps the file as its program headers say, and nothing else in the process writing over the code.
- That the things `hashr` is given the addresses of overlap neither one another nor the stack (the
  public contract's `requires`: its caller's part).
- The inner contracts (`proofs/inner.spec`, or the file's own section) are not relied on: a wrong one makes
  the verifier refuse the function it is of, or a function that calls it. Nor are a program's places.
- For the wide kernels with a number of blocks other than those they are called with here: what is shown
  is what holds if they return.
- That the regions do not overlap (the contract's own condition: the stack and the output overlap nothing else).
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
| usable by a caller's Lean proof | yes | no: a caller's theorem would name the kernel's contract as a hypothesis this verifier discharges |

For the whole hash the two are not of the same code: Lean checked the earlier code (`levels/levels.ode`:
`ladd`, `lroot`, `chunk_node`, `hashl`, and the fast path `wide`, `group`, `groupf`, `finish`, `hashw`,
`hashf`), each function from a proof with invariants and lemmas written by hand, and with the 32-lane kernel
taken on trust (a stand-in). A whole run of those chains on the workhorse, 12 at a time, took 3,120 s
(`hashw` alone 1,360 s, `hashl` 690 s, `groupf` 630 s; pinned run `wide-model-check4`, November 15: every
chain checked but one, a listing compared across two versions of `llvm-objdump`, which is not a proof).
Written by hand for that code, beside its 924 lines of source with their invariants: fourteen files of
lemmas (`lang/Lemmas_*.lean`, 2,516 lines), the contracts in Lean (`lang/Spec_*.lean`), and the tree's part
(`alg/`). Here `hash.ode` is 332 lines with no invariant and no lemma; its eight inner contracts are 56
lines of `proofs/inner.spec` (and two layouts and three kinds); nothing is taken on trust of a callee; and
`check_all.py` takes 19 s on a laptop.

Also tried the same day: SAW 1.6 on P16 with a Cryptol specification stops at the kernel's first AVX-512
instruction ("Could not decode instruction 62d2").

## Ways to make it trusted (undecided)

1. Write it in Lean and prove it sound once against `one/Machine.lean`; each kernel is then a theorem by
   evaluation. The cost is that one proof.
2. Keep it a small independent program, with the audits above kept running and a second implementation
   written apart from the first. Smallest reading list; no proof assistant.
3. Have it emit a certificate (the terms after each instruction) that a proof assistant checks step by step.

## Not yet so, and known warts of the language

(Moved here on November 16, 2026 from the two pages that are now `LANGUAGE.md`: that page holds meaning only.)

**Not yet so** (November 15). There are two verifiers of functions: `kfn.py` for the hash (words, vectors,
calls by contract) and `kbyte.py` for the programs of `programs/` (bytes, numbers, loops with places). The
first does not yet know `ensures X[a .. b]`, `ensures ... if C`, `ensures CONDITION` or `trace depends on`, and
refuses a contract that has them; the second follows calls by contract (programs/frame) but not a function
that calls itself, and knows none of the first one's kinds of memory. In a specification a name is defined
once: a text that defines one twice is refused (so a proof's inner contracts, read after the reader's
text, cannot change it). A proof's part may also hold lemmas (`lemma NAME(...) { requires ... ensures ... }`:
a contract of one of the specification's definitions, of its value `result`): the verifier shows each
before it uses any, so they change no meaning either, and a reader need not read them. A lemma may
also name a number that `decreases` at each use of a definition by itself: shown, it says the definition comes
to an end on what the lemma requires (a definition that did not would leave a contract saying nothing there). That a
contract's own uses are ones the lemmas speak of is asked apart (`kends.py`): a lemma comes with the proof,
and one that requires the impossible is shown and says nothing. What a
lemma is given or says may be of kind `any`: a thing passed on, of which the lemma asks and says nothing
(BLAKE3's words, in the lemmas that show its tree comes to an end). The inner contracts of the hash
(`proofs/inner.spec`) still name kinds of memory (`cv`: eight words); the public contract does not. That a
function returns is shown as far as the kernels it calls (README.md).

**Known warts** (November 15).

- `+` between a word and a number takes the number as a word. That is a conversion nobody wrote; it should
  be written.
- `|` is on words and on numbers, `&` on numbers only, `^` on words only (and `pow` is the power). One sign
  should mean one thing, on one kind of value.
- `machine` (states that change, a turn at a time) is still read, for `proofs/inner.spec`'s earlier trial of
  a stack. It is not part of this language and is in no specification a reader reads.
- **Nothing makes a definition come to an end.** "A definition may be of itself on smaller things", and
  nothing checks that they are smaller. The reader stops a definition that goes deeper and deeper (`def k(n)
  { k(n) + 1 }`: "does not come to an end"), but one whose call of itself is the last thing it does (`def
  k(n) { k(n + 1) }`) it follows for ever: no verdict, never a wrong one. It matters beyond that: a
  definition is read as an equation, and an equation with no solution proves anything (from `k(n) = k(n) +
  1`, 0 = 1). Noether's innermost language is definite for this reason: every computation gives a value or
  fails, in finite time. This language should be the same, and its reader should refuse a definition it
  cannot see ending (a `decreases` for definitions; every recursion in the specifications here has an
  obvious one: bytes left, `len(bytes) - at`).
- `failed(E)` and `reason(E)` look at a failure, which no definition should: with them inside definitions
  "what has no value gives none to what is made of it" would not hold. They are used only in contracts,
  and should be the contract's alone; the reader does not yet refuse them elsewhere.
- The meaning above is this page and a program in Python; neither is checked against the other but by the
  tests (`test_ode.py`, `programs/test_specs.py`).

## An object is read in one shape; names are BLAKE3's; two readers (November 16, evening)

**A name in two namespaces.** A contract was matched to its code by a name spelled the same in the file's
table of symbols. A linker reads that table by rules of its own. A copy of the shipped `odeframe.o`, changed
only so: its `ode_unframe` made a LOCAL name (a linker gives it to no caller), and a six-byte function added in
a second executable section under the GLOBAL name `ode_unframe`. `programs/check_file.py` said of it what it
says of the shipped file: "1936 of them loaded to be run" (1,942 were), "ode_unframe at 0x0 ... meets its
public contract", "3 function(s) verified in this file", exit 0. A C program linked with it and calling
`ode_unframe` got 42 from the other function. (Run on an x86-64 Linux machine with `as`, `objcopy`, `ld -r`.)

Now (`kdecode.linkable`): an object to be linked is read only in the shape the makers here write, with its
names or stripped of them: the sections `.text`, `.note.GNU-stack`, `.symtab`, `.strtab`, `.shstrtab`,
`.ode.proof` and no others, each once, of its type and with its leave (so no other section a linker would
load to be run, no stack asked to be executable); and no name but GLOBAL names of functions in `.text`, of
default visibility, each once (so none that is LOCAL, WEAK or resolved when the program starts). Then every
name the file gives a linker must be of a function shown to meet a contract: for the hash's file that is
fourteen, one more than `b3l_hashr` reaches (the 32-lane kernel's second way in), and all fourteen are
verified. Tests: `programs/test_files.py` (`Shape`), by changing bytes of the shipped files.
What it does not reach: an executable or a shared object (their names are resolved at load by rules this
does not read; `VERIFY.md` says so), and another file linked beside this one under the same name.

**Three more of the review.** A file without names whose proof is silent about one of its functions: whether
the file holds a function for the contract left out cannot be told, and it is now NOT shown (it was exit 0).
`check_binary.py` with no proof in the file and none given stopped on a name of its own that it had not set.
`refute.py` took a proof's places for places in the file; in a linked file without names it entered the code
somewhere else and could call a true contract FALSE.

**Names** (Sam, November 16). A thing's name is the BLAKE3 hash of its bytes, all 64 digits wherever digits
are shown or compared: 16 digits of SHA-256 were shown before, and two texts that agree in 16 digits cost
about 2^32 tries to make. There is no new code for the hash: `kshow.b3` works `blake3.spec` out on the bytes
with `ode.py` (0.1 s for a specification, 0.7 s for `b3hashr.o`), and `b3sum` gives the same digits. The
proof's form is `ode proof 2` (`specification blake3 ...`, `code N blake3 ...`). `verify.py` lists the files
that ran and gives the `b3sum` command that names them, for a program cannot vouch for itself; `--digests`
prints them (three seconds, which is why it is not the default).

**Two readers.** An auditor has no use for the names of the functions inside, the definitions' names in the
line about their ending, or a refusal's inner terms: each is its maker's, and each was printed. Now a
verification tells him, of each public contract, whether it is met, and the counts; `--maintain` prints the
rest for a maintainer. Whatever a file carries is printed through `kshow.Plain`: a control or formatting
character is written out (`\x1b`), so a maker's comment cannot take back a line on a reader's terminal
(`ode.py` lets a comment hold any character; a name it lets hold only letters, digits and `_`).

**One page.** `CONTRACT.md` and `LANGUAGE.md` are `LANGUAGE.md`, in two parts. It holds meaning only; what is
not yet so, and the known warts, are the section above this one.

Not yet done of what Sam asked the same day: the names a maker chose taken out of what is hashed and put in
a glossary beside it; a reader's own list of names; file names and the contract's name by the same rule; a
comment's outside documents given by their hashes.

## One verifier of functions; the kernels from Ode source; six holes found by reading (November 17)

**Six holes, each "shown, of something false".** The first two were found by reading `kfn.py` and the
kernels' verifiers in order to merge them; the next two by reading `kfn.py`'s machine again with the
question the first two had taught: what does this model take to be so that the processor does not? The last
two came from finishing that reading in the proof's part and the specification's sequences. All six were in
what a reader relied on until this day. None could have been found by the audits here, which change one bit
at a time: each needs several instructions, a contract, a layout or a specification changed.

1. *The stack pointer.* `kfn.py`'s machine (which is `kbyte.py`'s too) let `mov`, `lea` and `pop` put
   anything in the stack pointer, and then took a push to go to the function's own frame. A copy of the
   shipped `ode_common` with four instructions added (`mov rax, rsp; mov rsp, rdi; push rbx; mov rsp, rax`)
   was shown to meet its public contract, the contract unchanged; on a processor it wrote eight bytes just
   below its argument `a`. `lea` could also move the stack pointer down without the stack being counted.
   Now: after every instruction, whatever it was, the stack pointer is in the function's own frame at a
   plain number of bytes not above where it was at entry, and the stack used is counted from there; a push
   of the stack pointer and a pop into it are refused.
2. *The address of the file's data.* The decoder wrote `lea reg, [rip + data]` as a move of the number
   RODATA + where, the same row as a true `mov reg, NUMBER`; the kernels' verifiers took any such number
   within the data for the data's address. A copy of the shipped `b3hashr.o` with seven bytes changed in
   the 32-lane kernel (`mov rdi, 0x50004500` for `lea rdi, [rip + the schedule]`) was shown to meet the
   public contract, exit 0. On a processor it stops on a fault; with a page mapped at that address it
   returns a digest that is not BLAKE3's. Now the lea is a row of its own, `.lea_data reg WHERE`, which no
   move of a number is.

3. *The stack below the stack pointer.* What `kfn.py`'s machine remembered of it outlived a call, which
   writes there (its return address, the callee's frame). A copy of the shipped `ode_unframe` that pushes
   r15 and pops it before a call, then moves the stack pointer down and pops r15 again, was shown to meet
   its public contract; on a processor r15 then holds the return address, the function reads its input far
   outside it, and dies of a fault. Now nothing is remembered of the frame below the stack pointer, after
   every instruction.
4. *What a call leaves in the registers.* Every register a callee may change was one unknown, "left by a
   call"; two of them compared with a number were taken to answer alike, and a path on which they differ
   was never run. A copy of `ode_unframe` that writes a byte below `out` where rcx is zero and rdx is not
   (after a call, whose callee is free in what it leaves there) was shown to meet its public contract. Now
   each is an unknown of its own. (This one was not run on a processor: it needs a callee that leaves the
   two registers so.)

5. *The proof's layouts, and paths a proof could delete.* A layout comes with the proof, which Bob does
   not read; nothing checked where its fields lay, that they did not overlap, or that `below` was at least
   1. `layout tiny 8 { a: 32 bytes at 0 }` let a callee's writes run past what its caller had room for;
   two fields at one place were two entries of the model's memory; and `layout impossible 8 { v: number at 0
   below 0 }` put facts that cannot all hold into a caller, whose path was then dropped as no path and the
   code after its call never checked. The whole demonstration is kept with this test as `backdoor.o`: the
   real hash code with one branch added, shown against the reader's own `blake3.spec` and wrong on a
   processor for every message of a byte or more. Layouts are read strictly now, and after a call the
   caller's facts must still be able to hold together.
6. *A sequence whose value changes shape each turn.* What cannot be run was named by the shape of its
   first value: `sequence grow(n) { h[0] = [0]  h[b + 1] = h[b] ++ [0]  for b in 0..n }` made
   `len(grow(n))` one, and a function returning the constant one was shown. A sequence's state must now be
   shown to keep one shape over a turn before it is named.

And two of a milder kind, in the decoder: it read an instruction of more than fifteen bytes (a NOP after
any number of prefixes), and a VEX instruction of map 1 with the opcode 38 or 3A (where VEX has none) as a
shuffle of bytes or a blend. A processor stops on each (a fault; an illegal instruction: seen on one), so
a function with them computes nothing wrong, but it was shown to return. Both are stopped by the decoder now.

`test_kholes.py` holds the copies that were shown; each is refused. What found them was a question asked of
each instruction while reading ("what if this register is the stack pointer?", "what else writes this
row?", "who else writes there?", "are these two unknowns one?"), not a tool. One of the day's own changes
was caught the same way before it shipped (counting down and `test` taken to set the flags as a compare
does). The same reading was then finished through the files a verification loads; it also yielded smaller
closures now in the drivers (a ring of calls between distinct functions is refused, a public contract the
proof leaves out is printed and said (and fails the file where it has such a function), and tables a file points at outside itself are not read). The audits do
not reach faults of this kind, and the reading is evidence, not a proof that no seventh hole is there.

**One verifier of functions.** The five kernels of the hash (the two one-block kernels; K32, P32 and P16
for every number of blocks) are verified by `kfn.py`, as the nine functions of `hash.ode` are. `kloop.py`
and `kone.py`, the kernels' own verifiers, are gone (the sections above that describe them are as they
were written; what they showed is shown now by `kfn.py`).

- A loop whose count the path does not fix is taken by a **place**: the proof names one instruction the
  code passes once a turn and says what the registers hold there after any number of turns ("keep"; a
  number that moves with the turns; a word of the specification's value for sixteen lanes). The verifier
  runs the base (from the entry to the place and once around) and the step (from the place with an unknown
  number of turns done, to the place again or to the return), each against one turn of the specification's
  `sequence`. This is what `kloop.py` did, on `kfn.py`'s own machine and memory. `kfn.py`'s page says what
  each line of a proof means.
- The machine learned what the kernels use: ZMM registers as sixteen terms, mask registers, a frame on a
  64-byte boundary, the file's read-only data, 32-bit moves and shifts, a kernel's kinds of argument, and
  the older SSE4.1 forms (a rotation as two shifts and an or; a shuffle of bytes that rotates words).
- The kernels' contracts say `requires no_overlap(...)`, as `kfn.py` asks of every function. One thing is
  taken of a table of inputs and not written: the n blocks of an input lie in memory one after another, so
  64 * n is below 2^64 (the callers, which name each block they give, show the blocks are there).
- `python3 verify.py b3hashr.o` now loads **3,072 lines of code in 10 files** (3,461 in 11 before; with the
  line about the definitions' coming to an end 4,265, before 4,640). `kcheck.py`'s machine is not among
  them: the terms and the reading of an instruction's text moved to `kterms.py` (57 lines).
- `kwide.py` is the prover of a wide kernel's place on `kfn.py`'s machine (what `kloop.py`'s prover was).
  Nothing of it is loaded by a verification. The audits use it as an adversary: `kflip.py --general` asks
  it for a proof of every changed kernel.
- `test_kone.py` and `test_kloop.py` ask `kfn.py` what they asked the old verifiers, every case: 15 + 24
  changed kernels, 15 changed contracts, 7 wrong proofs, each kernel against the other's contract.

**The kernels from Ode source.** `../wide/one.ode` (the two one-block kernels), `../wide/k32.ode` (K32, with
P32 as a second `entry`) and `../wide/p16.ode` are the five kernels in Ode's instruction layer. Each, made by
`kernels.py` (the Ode compiler `odec.py`, then an assembler), is **byte for byte** the kernel of
BLAKE3-Servil's own assembly file and reads the same constants (`../wide/test_sources.py`).

- **A loop's proof is written by the compiler from the source.** The source says what holds at the loop:

      @block16:
      place b {
        keep rsp, rbp, rsi, rdi, r8, r9, r10, r12, r15
        r13 = n - b
        r14 = 64 * b
        zmm0 .. zmm7 = h[b]
      }

  `odec.py` leaves these lines out of the instructions and writes the proof from them; the one number it
  does not know (how many bytes into the kernel the place is) the assembler puts in the object. No search.
  The three proofs so written are, name for name, the ones the prover had found by running the kernels
  (`proofs/k32.json`, `p32.json`, `p16.json`, now written by `kernels.py --proofs`).
- `klink.py` takes the kernels' objects from the sources. `b3hashr.o` remade: every function at the same
  place, every instruction the same; 25 bytes of the kernels differ (the fields that say where their
  constants are, which now lie elsewhere after the code); 17,984 bytes loaded, 18,176 before. Its speed,
  measured again under the bench lock on two machines, one run each (three rounds, the best taken): as the
  file before, within about 1.5% either way. At 1 MiB 16.00 GiB/s on the Ryzen 7 9700X (97.1% of the
  library in the same run; the file before 15.77 two days earlier) and 13.03 on the EPYC 9255 (97.8%; before
  13.21); at 16 KiB 60% of the library on both, as before.

So for the file shipped: fourteen functions, each from Ode source (nine in the word-level language, five in
the instruction layer), one verifier, and for the loops a proof the compiler writes.

**Not yet so.**
- The whole audit of the state before holes 5 and 6 were closed (355,704 single-bit changes across its
  steps, 18,278 accepted, 0 with no verdict; every accepted change ran as its specification on the
  processor) is in `audit/`. It could not see those holes. `gate.py` is the five-minute gate Sam asked
  for before a merge or a post: the adversarial copies, every shipped file verified, the ELF outside code
  and proof flipped bit by bit, the lemma tests, and a positive control that `backdoor.o` is refused. The
  exhaustive sweep remains a soak, not a gate.
- The place's language is three forms; a loop of a function of `hash.ode` whose count is not fixed would
  need more (none has one).
- In the instruction layer the programmer writes the place by hand. A loop written in Ode's word-level
  language, from which the compiler would derive it, is not there for kernels.
- `kcheck.py`'s machine (a kernel run to its end for a fixed number of blocks; `output16`), `kglue.py` and
  `check_all.py` are earlier trials that no verification of a shipped file loads; they still have audits.
- AArch64; the hash's incremental interface; the kernels the library has beside these five (AVX2, SSE4.1
  wide, the batch kernels).
