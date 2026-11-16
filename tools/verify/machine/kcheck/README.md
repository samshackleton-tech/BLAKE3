# kcheck: a specification, a binary, and a verifier a reader runs (a trial, November 14 and 15, 2026)

**Two words, kept apart** (since November 15): a **prover** finds or writes out a proof and is trusted for
nothing; a **verifier** decides whether the code is shown to meet its contract, and is what a reader relies
on. The programs of this folder (`kfn.py`, `kbyte.py` and the others) are each both at once today: they
search (which facts to add up, which way to open a definition) and they decide. They are called verifiers
here because their yes is what is relied on. Taking the search out of them is the work ahead: a first cut
(the arithmetic's search replaced by written proofs that 33 lines check by adding up) is described in
DESIGN.md.

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
- **What the reader is promised is a contract** (`CONTRACT.md`, one page, the same for every function):
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

**The binary is one file, `b3hashr.o`** (40,880 bytes): the thirteen bodies of code the hash is made of,
their constants, their names, the specification, the proof, and nothing for a linker to fill in.
`python3 check_binary.py b3hashr.o` reads it, follows every call from `b3l_hashr`, and says in 19 s on an
Apple M6 that `b3l_hashr` in that file meets its public contract:

    contract b3l_hashr(out: 32 bytes, input: len bytes, len: number, key: 32 bytes, flags: byte, plat: any) {
        requires apart(out, input, key)
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
(`python3 programs/check_programs.py`: eleven functions, 1,759 instructions, 17 s, 12 of them the base-64
encoder's):

| | the public contract's `ensures` and `returns` | instructions | proof | checked in |
|---|---|---|---|---|
| Adler-32 | `returns adler32(input)` | 55 | 1 place, 7 lines | 5 ms |
| Adler-32, the sums reduced once in 5,552 bytes | the same line, the same specification | 116 | 2 places, 25 lines | 0.2 s |
| the same, four bytes a turn | the same | 164 | 3 places, 38 lines | 2 s |
| LZ4 block decoder | `returns if failed(lz4(input, cap)) then NO else len(lz4(input, cap))`; `ensures out[0 .. len(lz4(input, cap))] = lz4(input, cap) if !failed(lz4(input, cap))` | 267 | 5 places, 96 lines | 0.54 s |
| LZ4 encoder, literals only | `ensures lz4(out[0 .. r], n) == input if r != NO`; `ensures r != NO if cap >= n + n / 255 + 16` | 132 | 2 places, 26 lines | 34 ms |
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

and the public contract (above), which is all of the contracts a reader need read. `CONTRACT.md` says what
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

At a call the verifier also shows that what the callee writes is apart from everything else the callee is
given the address of (the callee's own check took them to be apart), and that what the callee needs of the
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
  **`b3hashr.o`**: 40,880 bytes, of which 16,788 are code and 21,511 the specification and the proof; fourteen names; no
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
| `b3hashr.o` | `klink.py`, of Apple clang 21's objects | 40,880 | meets its public contract |
| a shared object of it | GNU ld 2.46 | 41,640 | meets it |
| a shared object of it | lld 21 | 32,776 | meets it |
| `khash_native.c` with it (an executable loaded anywhere) | GCC 15.2, GNU ld | 58,168 | meets it |
| the same after `strip` (no names; the proof's section is kept) | | 54,808 | meets it: the functions are found by their bytes |
| the same after `strip --strip-all -R .ode.proof` (no names, no proof) | | 43,208 | meets it, given the proof beside it (`--proof b3hashr.proof`) |
| `programs/blake3-rust/main.rs` with it | rustc 1.99.1 (`-C link-arg=b3hashr.o`) | 4,595,808 | meets it |
| the same after `strip` | | 382,240 | meets it |

**The proof is in the file.** `klink.py` writes a section the loader does not map, `.ode.proof`: the inner
contracts, the wide kernels' places, where each function begins, and the SHA-256 of the specification the
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
memory, sharing a page, or apart from the others stops the reading; `TEXTREL` stops it; a name given to two
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
bytes and the proof's offsets), takes the proof from the file, and checks:

| file | bytes | functions | checked in |
|---|---|---|---|
| `adler32/odeadler32.o` | 6,032 | 3 | 2.4 s |
| `lz4/odelz4.o` | 20,712 (3,088 of code) | 3 | 2.5 s |
| `varint/odevarint.o` | 1,664 | 1 | 0.2 s |
| `utf8/odeutf8.o` | 5,400 | 1 | 0.17 s |
| `base64/odebase64.o` | 4,336 | 1 | 13 s |
| `inet/odeinet.o` | 4,104 | 1 | 0.17 s |
| `common/odecommon.o` | 2,008 | 1 | 0.01 s |
| `frame/odeframe.o` (a function and the two it calls) | 13,304 (1,936 of code) | 3 | 2.4 s |
| `programs/lz4-rust/main.rs` linked with `odelz4.o` (rustc 1.99.1) | 4,568,904 | 3 | 4.4 s on the Threadripper |
| the same after `strip` | 364,504 | 3, found by their bytes | 4.4 s |

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
  | `ode_utf8` | 9,576 | 4,305 | 4,399 | 872 | 872 keep the contract |
  | `ode_base64` | 6,608 | 3,121 | 2,984 | 503 | 503 keep the contract |
  | `ode_inet` | 2,392 | 1,130 | 1,249 | 13 | 13 keep the contract |
  | `ode_unframe` (its two calls by contract) | 2,232 | 1,098 | 886 | 248 | 248 keep the contract |

  (Threadripper PRO 7975WX. The judges: zlib's `adler32`; for the decoder a decoder written in C in the
  harness, on blocks that are right and blocks that are damaged; for the encoders that decoder,
  `ode_lz4_decode`, and for the packing one `LZ4_decompress_safe` of lz4's `lz4.c` (commit `6b589e80`) as
  well; for UTF-8 a validator by the standard's table of byte ranges and the C library's converter; for
  base 64 an encoder by a table and the C library's `b64_ntop`; for the checksum RFC 1071's own C code.
  All twelve are of one run, the whole `sh audit.sh 60` on the tree of commit `42ed51e0` (after `kbyte.py`
  learned calls and `ode.py` to refuse a name defined twice): 56,040 changes, 3,515 accepted, none without a
  verdict; the first eleven rows are what they were at `f7c0cfa9`. The same run left every instruction out
  of six of them in turn: 38, 47, 4, 11, 12 and 13 objects accepted (`lz4_pack`, `utf8`, `inet`,
  `adler32_blocks`, `adler32_blocks4`, `unframe`), each keeping its contract on the processor; and checked
  and ran the eight shipped files (30,000 frames through `odeframe.o`).)
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
  `lz4(input, cap)` failed?"): two paths after the call, one with the value named as a list, one with it
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

**Not done.** Sigil has no code. No prover searches for places: each was written from the verifier's
refusals. And what `kbyte.py` still lacks, each found by a program that wanted it:

- one verifier of functions (`kfn.py` and `kbyte.py` both follow calls now, each with its own kind of memory);
- tables of constants beside the code, and multiplication in Ode (Sigil);
- facts about a specification itself that take an induction: that what an LZ4 block decodes to only
  grows; that the least place two runs differ is where a walk over them stops. Those specifications were
  written as walks over the input so as not to need them. (A fact of arithmetic it does show: that four
  folds of the carries are a one's complement sum.)
- reads and writes of more than a byte at a time, for speed;
- taking a specification's question both ways where the code's path does not answer it (UTF-8), and
  joining paths that have come to the same state (base 64);
- a constant above 32 bits in the code (the checksum's own bound; it asks in four shifts);
- in-place work: a byte the function may write and has not yet written is unknown to it, so a function
  that reads and writes one buffer cannot be shown (tried: ASCII made upper-case in place, 44 instructions:
  refused).

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
| `blake3.spec` | 185 | the specification (147 lines), and the public contract: that of the function a user calls |
| `CONTRACT.md`, `LANGUAGE.md` | 69 + 93 | what a contract means; what the specification language's texts mean: a page each, the same for every program |
| `DESIGN.md` | 175 | the design: what is wanted and given up, the rules for code written to be proved, how it stands to types-as-proofs |
| `proofs/inner.spec`, `proofs/*.json` | 185 | the inner contracts (of the functions inside), the layouts of two records; the wide kernels' and `merge`'s places |
| `hash.ode`, `glue/*.S` | 332 | the hash written to be proved; the assembly the Ode compiler prints of it (and of the stack's three functions) |
| `b3hashr.o` | | the binary: 40,880 bytes, the specification and the proof in it |
| `check_binary.py` | 140 | what a reader runs on the binary, or on what a linker made of it |
| `programs/` | | six other programs (Sigil a specification only): each its specification and public contract, its Ode source, the compiler's assembly, its proof, a harness for the processor; `check_programs.py`, `test_specs.py`, `bench.c`; `blake3-rust/` |
| `kbyte.py`, `test_kbyte.py` | 910 + 326 | the verifier of those programs (bytes, numbers, places); its tests |
| `kbyte_flip.py`, `kbyte_nop.py` | 117 + 37 | their single-bit audit and every instruction left out, the processor judging |
| `programs/kpack.py`, `programs/check_file.py`, `programs/test_files.py` | 55 + 78 + 82 | a program as one file with its proof (untrusted); what a reader runs on it, or on what a linker made of it (`--json`: what was checked, for a benchmark's record); tests |
| `klink.py`, `klink_flip.py`, `test_kbinary.py` | 134 + 72 + 182 | makes the binary of the assembler's objects (untrusted); every single-bit change of what a linker would have written; tests of the reading of a linked file |
| `check_all.py` | 120 | every function from an assembler's objects, and that the hash's functions end |
| `ode.py`, `kspec.py`, `klin.py` | 694 + 565 + 256 | the specification's reader; its algebra on symbols; numbers that depend on counts and the facts about them |
| `kdecode.py` | 581 | reads the ELF file (an object's sections, names and relocations; a linked file as a loader maps it) and decodes the instruction forms the code uses, and no others; no disassembler |
| `kfn.py`, `test_kfn.py` | 889 + 131 | the verifier of functions; its tests |
| `kfn_flip.py`, `khash_native.c` | 133 + 176 | its single-bit audit; the whole hash on a processor against BLAKE3 in C |
| `khash_bench.c`, `earlier/*.S` | 37 | the speed of `hashr`, of the library, and of the earlier `hashf` (its assembly), in one harness |
| `kloop.py`, `test_kloop.py` | 439 + 115 | the wide kernels for every number of blocks: the prover, the proof's form, the verifier by induction; its tests |
| `kone.py`, `kone_native.c`, `test_kone.py` | 218 + 86 + 112 | the one-block kernels: the verifier (XMM registers as four terms), the processor run, the tests |
| `kcheck.py`, `test_kcheck.py` | 534 + 163 | the first verifier: a kernel's instructions run to the end on symbols (and the terms and the reading of an instruction's text that the others use); its tests |
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

(Every single-bit audit was run again in the night of November 15 to 16 by `sh audit.sh 60` on the tree of
commit `42ed51e0`, the last change to any of these programs (`ode.py`, which all of them read, and `kbyte.py`),
and `audit/` holds the outputs: 353,192 single-bit changes in all, 18,033 accepted, each of those as its
specification on the processor, none without a verdict (900 s a change at most). But for the new function's
rows every count is what it was in the run before, at `2ae7c9e9` and `f7c0cfa9`.)

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
  `.spec`), with what they mean (`LANGUAGE.md`, `CONTRACT.md`), and the programs that read them and the
  bytes: for the hash `ode.py`, `kspec.py`, `klin.py`, `kdecode.py`, `kcheck.py`, `kone.py`, `kloop.py`,
  `kfn.py`: 4,176 lines; for the programs of `programs/`, `kbyte.py` in place of the last four: 910 more;
  `kglue.py`, 569 (their provers, about 150 of those, need no trust). And Python.
- No assembler and no linker, when the file checked is the file run (`check_binary.py`). A loader that
  maps the file as its program headers say, and nothing else in the process writing over the code.
- That the things `hashr` is given the addresses of are apart from one another and from the stack (the
  public contract's `requires`: its caller's part).
- The inner contracts (`proofs/inner.spec`, or the file's own section) are not relied on: a wrong one makes
  the verifier refuse the function it is of, or a function that calls it. Nor are a program's places.
- For the wide kernels with a number of blocks other than those they are called with here: what is shown
  is what holds if they return.
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
