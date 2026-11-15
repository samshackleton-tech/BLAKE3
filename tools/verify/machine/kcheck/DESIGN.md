# The design, after Sam's note of November 15 (a working note; README.md has the evidence)

## What is wanted, and what is given up for it

Wanted: a skeptical auditor verifies for himself that a substantial, useful program is correct, with

1. as little as possible that he must rely on, which is what he must read and understand;
2. fast code (BLAKE3 is the test);
3. programs with proofs that are practical to produce, at scale;
4. proofs that are quick to check on his own machine.

Given up, on purpose: proofs of programs that already exist (the code is written anew, for this); arbitrary
mathematics; arbitrary kinds of computation; human programmers (an AI may write the code); existing
languages; arbitrary assembly; and proofs for every program one could write in the language (the programmer
writes the code so that it can be proved, as he writes it so that it is fast).

## The five things

| | what it is | who reads it | today |
|---|---|---|---|
| the specification | what the result IS: definitions by equations, in a language made for specifications | the auditor | `blake3.spec`, 147 lines |
| the claim | the contract of each function a user calls | the auditor | 18 lines, one function |
| the code | written in the specification's shape, in Ode | nobody has to | `hash.ode`, 274 lines |
| the proof | what the checker needs beside the binary: what the functions inside do; a place for a loop of unfixed count | nobody has to | `proofs/inner.spec`; for the hash, no place |
| the checker | runs the binary on symbols and compares with the specification; does not search | the auditor, once, for every program | 3,883 lines of Python, unverified |

The auditor reads the specification and the claim, and runs the checker on the binary. If a contract of a
function inside were wrong, the checker would refuse that function, or one that calls it: the contracts
inside are steps of the proof, not things claimed to him.

## The specification is declarative

It says what the hash is. `subtree` is the paper's definition: at most one chunk's bytes are a chunk; more are
two parts, the left of `the greatest power of two k with 1024 * k < len(bytes)` chunks, under a parent. A
chunk's chaining values are a sequence, `h[0] = key`, `h[b + 1] = compress(h[b], ...)`. There are no
loops, no variables that change, no stack of subtrees.

It can still be evaluated (a definition of a thing by smaller things is a way to work it out), and that is how
it is checked against the official vectors. But it is not written as a way to compute, and an efficient way
to compute is nowhere in it.

The first form of it this week was "a program that runs": machines whose turns the code's loops followed,
and the hash by a stack of subtrees. That put the algorithm where the auditor reads, and left him to see that
the algorithm is BLAKE3.

## The code is written to be proved

What that has meant so far, as rules a programmer (or an AI) follows the way he follows rules for speed:

- **Take the definition's shape.** Where the specification is two parts under a parent, the code calls itself
  on the two parts. The checker takes each call by the function's own contract, and what the function leaves
  is then the definition, opened once. No fact about trees is needed.
- **A loop whose count the paths fix costs nothing**: the checker runs it (a block's 64 bytes, a chunk's 16
  blocks, 54 doublings). A loop whose count is not fixed must follow a sequence of the specification turn by
  turn (the wide kernels' loop over blocks does; the proof is then one place, which a prover finds), or
  become a recursion.
- **Say what the memory holds, in the specification's words.** `take` is given an array of chunk values that
  a kernel made; one line of its contract says what each element is
  (`asks cvs[i] == node_value(chunk_node(...)) for i in 0..len / 1024`). That line is the array's type. The
  checker reads elements as that term inside the function, and shows the line at every call.
- **Each function does something the specification has a word for.** Its contract is one line in the
  specification's definitions. A function for which no such line can be written is cut in the wrong place.
- **Numbers stay linear.** Sums, differences, multiples by plain numbers, halvings. "The greatest power of
  two below" is found by doubling, and each path knows which power it found.
- **The stack is bounded by an argument** (`bits` of the length), and the platform's instructions by a
  condition on an argument, in the contract.

What does not fit, and was tried: a data structure whose meaning takes an induction over counts and their
bits (the stack of subtrees; the levels). The earlier code had them; Lean proved them by lemmas written by
hand; this checker could follow the code only against an algorithm of the same shape, which is not a
specification. The answer here was to change the code, not to add the mathematics.

## How this stands to "types are proofs"

- *Curry and Howard*: a type is a proposition, a program of that type is its proof, and the type checker is
  the proof checker. With types that speak of values, `hash : (m : bytes) -> { h | h = blake3(m) }` is a
  type, and a program that has it is correct. Lean, Coq, Agda and F* take this to all of mathematics: a large
  checker, and proofs that people write.
- *Types whose indices are restricted* (DML and ATS, Xi and Pfenning; liquid types): types may speak only of
  terms from a domain that can be decided (linear arithmetic). The programmer writes the invariants as
  types; the checker solves constraints; nobody writes a proof. This is "not arbitrary mathematics", done
  in the 1990s for array bounds.
- *Typed assembly* (Morrisett; with indices, Xi and Harper) and *proof-carrying code* (Necula and Lee): the
  types, or the loop invariants, go through the compiler to the binary, and the binary is what is checked, by
  a small checker against a public policy. The compiler is not trusted.

What is here is proof-carrying code's arrangement (binary and proof to a small checker) with DML's
restriction (the checker evaluates definitions, compares terms by identity, and adds linear facts; nothing
else), where the "type" of the function a user calls is the whole specification of its result, not memory
safety alone. A contract is a function's type. A function's own contract, used at its calls of itself, is the
rule for a recursive function: the induction. A place is a loop's type. The programmer directs the proof by
the code's shape and by the contracts he gives the functions inside.

What that tradition has and this has not: a checker of the *source*. Today the programmer learns that his
code is not provable from the checker of the binary ("at a return: out is not what the contract says"). A
type checker for Ode that says so of the source line would be the programmer's tool; the binary's checker
stays the auditor's.

## Where it stands

Done: the whole hash of a message, every length, from the binary's bytes, with nothing assumed of a callee,
checked in about 3 seconds; audits with a processor as judge (README.md).

Not done, in the order I would take them:

1. **Speed** is no longer first here: every part of more than one chunk goes through the 32-lane chunk
   kernel, a whole tree of 32 chunks through the 16-lane parent kernel too, and a first look has `hashr` no
   slower than the earlier `hashf` at any size tried (README.md). To do: a timing under the bench lock,
   against the library; the parents of small parts through the parent kernel; AVX2 and narrower machines.
2. **The checker's own worth.** It is 3,883 lines of Python, tested and audited, not proved. Smaller; a
   second one written apart; or proved once. Undecided.
3. **The source's checker** (above), and the compiler printing bytes, not assembly (BLAKE3 #396).
4. **What is shown is what holds if the function returns.** Each loop is bounded and each call of itself is on
   fewer bytes, but the checker does not say so.
5. **AArch64.**
6. **An incremental hasher** (bytes arriving in pieces) holds subtrees between calls: a stack by nature. Either
   that one algorithm's mathematics is done once (Lean has it for a twin), or the interface is designed so
   that none is needed. Not thought through.
