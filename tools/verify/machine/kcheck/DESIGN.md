# The design, after Sam's notes of November 15 (a working note; README.md has the evidence)

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

## The six things

| | what it is | who reads it | today |
|---|---|---|---|
| the specification | what the result IS: definitions by equations, in a language made for specifications and nothing else | the auditor | `blake3.spec`, 147 lines; `LANGUAGE.md` says what such a text means |
| the public contract | a Hoare triple for each function a user calls: `requires`, `ensures`, and a closed world | the auditor | 7 lines for the hash; `LANGUAGE.md` (part 2) says what any contract means |
| the code | written to be proved, in Ode | nobody has to | `hash.ode`, 332 lines; `programs/*/*.ode` |
| the binary | one file: the code's bytes, its constants, its names, the proof; nothing for a linker to fill in | the verifier | `b3hashr.o`, 80,920 bytes |
| the proof | what the verifier needs beside the code: the inner contracts; a place for a loop whose count is not fixed | nobody has to | for the hash, `proofs/inner.spec` and no place of its own; for the programs, 0 to 6 places each |
| the verifier | runs the binary on symbols and compares with the specification; does not search | the auditor, once, for every program | 4,176 lines of Python for the hash, 910 more for the programs; unverified |

The auditor reads the specification and the public contract, and runs the verifier on the binary
(`python3 check_binary.py b3hashr.o`, or on the shared object or the executable a linker made of it: 19 s).
What made the binary (the Ode compiler, an assembler, `klink.py`, a linker) he does not rely on. If an
inner contract were wrong, the verifier would refuse that function, or one that calls it: the inner
contracts are steps of the proof, not things said to him.

## The two languages are apart (Sam, November 15)

The specification language is not the code language and shares nothing with it but numbers. It is made for
the reader's cost and risk: it has no state that changes, no memory, no numbers that wrap, and nothing a
hash, a checksum, a compression format and an encoding did not need. The code language is made for the
writer and the processor, and nothing in it is the reader's concern. What joins them is the contract, and
only the contract speaks of memory: bytes at addresses, which of them may be read and written, how much
stack, which instructions, what the timing may depend on.

**The contract is a closed world.** It says everything the function may do, and silence means the stronger
thing: a line is needed to be allowed more (`writes`, `needs`, `trace depends on`), never to promise the
usual. So a reader need not know what to look for; what is not there is not done.

**Failure is a value of the specification, not of the verifier.** `fails REASON if C` in a definition; a
contract says what the function does then (`returns if failed(lz4(input)) || len(lz4(input)) > cap then NO else ...`). A
function given bytes from anywhere (a decoder) must be right for all of them: there is no `requires` for
"the block is well formed", and the closed world makes "safe on every input" the default, not a second
theorem.

**A contract may be no way to compute.** `ensures lz4(out[0 .. r], n) == input`: what the encoder wrote
decodes to the input. Nobody could run that to get `out`; the verifier shows it of the code by carrying,
from place to place, that the block being written decodes so far to the input so far. It is also true of
an encoder that always says NO, which is why a contract must be read for what it does not promise; the
plain encoder's says when it does not say NO.

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
  on the two parts. The verifier takes each call by the function's own contract, and what the function leaves
  is then the definition, opened once. No fact about trees is needed.
- **A loop whose count the paths fix costs nothing**: the verifier runs it (a block's 64 bytes, a chunk's 16
  blocks, 54 doublings). A loop whose count is not fixed must follow a sequence of the specification turn by
  turn (the wide kernels' loop over blocks does; the proof is then one place, which a prover finds), or
  become a recursion.
- **Say what the memory holds, in the specification's words.** `take` is given an array of chunk values that
  a kernel made; one line of its contract says what each element is
  (`asks cvs[i] == node_value(chunk_node(...)) for i in 0..len / 1024`). That line is the array's type. The
  verifier reads elements as that term inside the function, and shows the line at every call.
- **Each function does something the specification has a word for.** Its contract is one line in the
  specification's definitions. A function for which no such line can be written is cut in the wrong place.
- **Numbers stay linear.** Sums, differences, multiples by plain numbers, halvings. "The greatest power of
  two below" is found by doubling, and each path knows which power it found.
- **The stack is bounded by an argument** (`bits` of the length), and the platform's instructions by a
  condition on an argument, in the contract.

What does not fit, and was tried: a data structure whose meaning takes an induction over counts and their
bits (the stack of subtrees; the levels). The earlier code had them; Lean proved them by lemmas written by
hand; this verifier could follow the code only against an algorithm of the same shape, which is not a
specification. The answer here was to change the code, not to add the mathematics.

## How this stands to "types are proofs"

- *Curry and Howard*: a type is a proposition, a program of that type is its proof, and the type checker is
  the proof verifier. With types that speak of values, `hash : (m : bytes) -> { h | h = blake3(m) }` is a
  type, and a program that has it is correct. Lean, Coq, Agda and F* take this to all of mathematics: a large
  verifier, and proofs that people write.
- *Types whose indices are restricted* (DML and ATS, Xi and Pfenning; liquid types): types may speak only of
  terms from a domain that can be decided (linear arithmetic). The programmer writes the invariants as
  types; the verifier solves constraints; nobody writes a proof. This is "not arbitrary mathematics", done
  in the 1990s for array bounds.
- *Typed assembly* (Morrisett; with indices, Xi and Harper) and *proof-carrying code* (Necula and Lee): the
  types, or the loop invariants, go through the compiler to the binary, and the binary is what is checked, by
  a small verifier against a public policy. The compiler is not trusted.

What is here is proof-carrying code's arrangement (binary and proof to a small verifier) with DML's
restriction (the verifier evaluates definitions, compares terms by identity, and adds linear facts; nothing
else), where the "type" of the function a user calls is the whole specification of its result, not memory
safety alone. A contract is a function's type. A function's own contract, used at its calls of itself, is the
rule for a recursive function: the induction. A place is a loop's type. The programmer directs the proof by
the code's shape and by the contracts he gives the functions inside.

Nearest relatives, as I remember them (not re-read today; to be read against this design):

- Xi and Pfenning, "Eliminating array bound checking through dependent types" (1998) and "Dependent types in
  practical programming" (1999): DML. Indices from linear arithmetic; annotations, not proofs.
- Xi and Harper, "A dependently typed assembly language" (2001): the same at the level of assembly.
- Morrisett, Walker, Crary and Glew, "From System F to typed assembly language" (1998).
- Necula and Lee, "Safe kernel extensions without run-time checking" (1996); Necula, "Proof-carrying code"
  (1997); Appel, "Foundational proof-carrying code" (2001), which shrinks what the consumer trusts to a
  machine's semantics and a logic.
- Bond and others, "Vale: verifying high-performance cryptographic assembly code" (2017): a language made
  for assembly procedures with requires and ensures, checked through Dafny or F* and an SMT solver. Nearest in
  subject (hashes and ciphers in assembly, fast). It trusts the solver and proves at the level of assembly
  text; proofs take minutes and people guide them.
- Sammler and others, "RefinedC" (2021): refinement types for C whose checking is a search-free procedure
  (no backtracking), producing proofs a proof assistant checks. Nearest in method.

What that tradition has and this has not: a verifier of the *source*. Today the programmer learns that his
code is not provable from the verifier of the binary ("at a return: out is not what the contract says"). A
type checker for Ode that says so of the source line would be the programmer's tool; the binary's verifier
stays the auditor's.

## Where it stands

Done: the whole hash of a message, every length, from the binary's bytes, with nothing assumed of a callee,
checked in 19 seconds; seven other programs with their own specifications and contracts (Adler-32, an LZ4
decoder and two encoders, a varint, a first difference, a UTF-8 validator, a base-64 encoder, the Internet
checksum), eleven functions, 1,759 instructions, checked in 17 seconds; the
proof carried in the binary; a C and a Rust program linked with it and checked as files; audits with a
processor as judge (README.md).

Since November 17 (Sam's direction: the target is the single-threaded hash of blake3-servil-core, as fast
as the library and verifiable; one kind of input to the prover, Ode source; the kernels written in Ode and
shown by the same verifier as everything else): the hash's five kernels have Ode sources that give the
library's bytes, a loop's proof is written by the compiler from what the source says holds there, and one
verifier of functions shows all fourteen functions of the file shipped (README.md, last section). Two
faults of the verifier were found on the way, by reading (the same section).

Not done, in the order I would take them:

1. **Speed.** Under the bench lock `hashr` runs at 97% to 98% of the library's own one-shot hash from 1 MiB
   up (16.05 against 16.37 GiB/s on a Ryzen 7 9700X), 94% to 95% at 64 KiB, about 60% at 16 and 32 KiB, and
   is no slower than the earlier `hashf` anywhere (README.md). The rest is code not yet written: a 16-lane
   path for 16 chunks or fewer (a kernel to check); parents many to a call over small parts; AVX2 and
   narrower machines.
2. **The verifier's own worth: the goal (Sam, November 15).** Soundness of the verifier is a hard
   requirement, and so is that a reader can verify it without believing the whole verifier. The way: shrink
   the core he relies on, and make it more provable as well as smaller. A prover, trusted for nothing,
   writes out a proof; a small verifier decides by it; everything clever (the search in arithmetic, opening
   definitions, lemmas, joining paths) moves to the prover's side. What is at the bottom need not be one
   thing: the verifier is right if any one of these is, and each reader takes the one he trusts: he reads
   the small verifier himself; a second one, written apart, verifies the same proof; it is proved in
   something he already relies on, such as Lean (never required); or it is written in Ode, specified in
   Ode's specification language, and shown by Ode's own verifier to meet it (circular alone; strong once any
   one outside check breaks the circle). So it is to be designed so that it could be written in Ode. No
   technique removes what he must always read: the account of the machine, and what a contract and a
   specification mean.

   **Chosen (Sam, November 15): the verifier runs the instructions and opens the definitions itself; the
   proof carries what would otherwise be searched for.** (Every step written out would make proofs of
   megabytes for these small programs: too big.) What was measured that evening, with the programs as they
   were (`count_steps.py` is kept beside the reports); the second item is in this folder since November 16
   (`varith.py`, `kprove.py`; README.md has the files' sizes and times as shipped):
   - Counted on eight functions: an arithmetic fact that is shown rests on three or four of the thirty-odd
     facts in play; nine tenths of the eliminations show nothing; using a callee's contract is cheap, and
     paths are the load (`hashr`'s 265 instructions are run 20,404 times); the bulk of the work is running
     instructions and opening definitions (157,000 openings for `wide128`).
   - The arithmetic's search taken out: the prover writes, for each fact shown, the rows it starts from and
     steps "a times this row plus b times that one, divided through, rounded down", ending in a number
     below zero; 33 lines verify that by adding up. With no search left in the arithmetic, all twelve
     functions of `programs/` and the hash's nine are still shown. Proofs, gzipped: 0.1 to 6 kB a function
     of `programs/`, 57 kB for the whole hash. Time: the byte programs 8 to 30 times faster (base 64: 13 s
     to 1.6 s); the hash's functions less (their time is in definitions). With no proof, with every
     multiplier changed, with another function's proof: refused.
   - What would still be relied on after that cut, counted in lines of code without comments: 4,097. About
     2,400 are what a reader must be given in some form anyway (bytes to instructions 491; what the
     instructions do, about 700; reading a specification and working it out on names, about 1,200). The
     cleverness still inside is mostly the last of those (about 630 lines: naming lists, stepping
     sequences): the next thing to move to the prover's side, as "this definition, of these, is this",
     one opening verified at a time. And there are two verifiers of functions that should be one
     (`kfn.py`, `kbyte.py`), and a third way for the wide kernels.

   **Lemmas (November 16).** A fact about a definition of the specification that takes an induction ("what
   an LZ4 block decodes to only grows") is a lemma: a contract of that definition, `requires` and `ensures`,
   in the proof's part. The verifier shows it by opening the definition once, each use inside of a
   definition with a lemma taken by that lemma, and only then uses it. So an induction costs the reader
   nothing: he does not read the lemma, and what he relies on is one more rule of the verifier (the
   definition opened once, its own uses by its own lemma), which is the rule a function that calls itself
   is already verified by. This is what let LZ4's specification be the format's own again: bending a
   specification toward the code is a cost on the reader (he must believe the two say the same), a lemma is
   a cost on the prover. A prover that finds them is small: `kguess.py` tries a few shapes and asks the
   verifier, and writes LZ4's four lemmas from the specification alone (README.md, "A prover that guesses").

   **False, with an input (November 16).** `refute.py` works a public contract out on numbers beside the
   binary's code run on a processor, and says FALSE with the input where they differ. It is a prover's tool
   (goal b and b.2: what is false is said to be false, with why); "not refuted" shows nothing.

   **Names (November 15, after a hole).** A proof's part (the contracts of the functions inside) is read
   after the reader's specification, in one space of names. Until that day a second definition of a name
   took the first one's place, a definition could take the name of one of the language's own (`len`,
   `bits`), and a name the reader's text used without defining could be given its meaning by the proof.
   Now (`ode.with_proof`): a name is declared once; the language's own names are no specification's to
   define; and the proof's part may declare no name that the reader's text writes anywhere. So no name
   the reader reads has its meaning from the proof. What remains open: names that authenticate nothing
   (a symbol of the file, or an offset the proof gives, says which bytes are "the function"); Sam is
   weighing identifiers that authenticate themselves.
3. **The source's verifier** (above), and the compiler printing bytes, not assembly (BLAKE3 #396). (The
   binary is already one file of settled bytes, made of an assembler's objects by `klink.py`; the verifier
   reads it as a loader maps it.)
4. **That the functions return** is now shown as far as the kernels (a `decreases` line where a function
   calls itself; no ring of calls; every loop run to its end). That the wide kernels return for every number
   of blocks is not: they are called with 16 and with 1, for which they are run to their end.
5. **AArch64.**
6. **The programs' speed**: Adler-32 at half the usual C's with its sums put off (a fifth without), the LZ4
   decoder at an eighth (README.md): the Ode compiler's doing, and a decoder that copies a byte at a time.
7. **Sigil** (John's encoding of 32 bytes): specified, not coded: it multiplies a number of 258 bits by a
   prime and looks letters up in a table; Ode has no multiplication yet and `kbyte.py` reads no table.
8. **An incremental hasher** (bytes arriving in pieces) holds subtrees between calls: a stack by nature. Either
   that one algorithm's mathematics is done once (Lean has it for a twin), or the interface is designed so
   that none is needed. Not thought through.
