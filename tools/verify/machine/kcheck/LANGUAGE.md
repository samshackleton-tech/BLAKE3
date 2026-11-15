# The specification language: what its texts mean

A specification is what a reader checks a binary against, so it is written for the reader: definitions by
equations, nothing that changes, nothing about memory. It is a language of its own, apart from the language
the code is written in (Ode) and smaller. This page is its whole meaning; `ode.py` is the program that reads
it (and reads contracts), and where the two differ the program is wrong. `CONTRACT.md` is the other page a
reader needs: what a contract means.

A specification can be worked out on numbers: that is how each one here is checked against other people's
answers (BLAKE3's official vectors; zlib's Adler-32; an LZ4 decoder written another way; Sigil's vectors).
But it is not written as a way to compute, and a contract may use it in a way nobody could compute by
(`ensures lz4(out[0 .. r], n) == input`: what was written decodes to the input).

## Values

| value | written | meaning |
|---|---|---|
| number | `0`, `65521`, `0x40` | a whole number, not below zero, of any size. Numbers never wrap. |
| word | `word(n)` | 32 bits. `+` wraps, `^`, `|`, `>>>` (rotate right). |
| counter | `counter(n)` | 64 bits as two words; `+` a number; `lo(t)`, `hi(t)`. |
| list | `[a, b]`, `[]` | values in order. A list of numbers below 256 is bytes. |
| record | `{value: a, next: b}` | named values; `r.value`. |
| true, false | `a < b`, `!c`, `c && d`, `c || d` | only where a condition is asked for. |

## What can be said of them

- **Numbers**: `+`, `*`, `/` (whole division), `%` (remainder), `-`. A difference below zero has no meaning:
  see "No value" below. `pow(a, b)`, `bits(n)` (its length in bits), `==`, `!=`, `<`, `<=`, `>`, `>=`.
- **Lists**: `xs[i]` (place i, from 0), `xs[a .. b]` (places a up to b, b not among them), `xs ++ ys`,
  `len(xs)`, `[e for i in a .. b]` (e for each i from a up to b), `xs with [i: a]` (xs with place i
  replaced), `words(bytes)` (every four bytes a word, the lowest byte first) and `bytes_of(words)` (the
  other way). These two are the only place a byte order is said, and a specification may not define them.
- **Choice**: `if c then a else b`.
- **Search**, among numbers that can be listed: `the least number n in a .. b with C`,
  `the greatest power of two k with C`.

## Definitions

```
const NAME = E

def NAME(x, y) {
    fails REASON if C          (any number of these, and of `let`, in the order they are meant)
    let a = E
    E                          the value
}

sequence NAME(x) { s[0] = E   s[i + 1] = F }
```

- A **definition** is its value, with names (`let`) for parts of it. A name is given once. Nothing loops and
  nothing changes. A definition may be of itself on smaller things (`subtree` of a part of the bytes;
  `sequences` from a later place of the block).
- **`fails REASON if C`**: where C holds, the definition has no value, and REASON (a number) says why. They
  are read in order, with the `let`s between them, so each may rest on those before. Something that has no
  value gives none to whatever is made of it. `failed(E)`: E has no value. `reason(E)`: why.
- A **sequence** is values in order, each from the one before: `NAME(x)[k]` is the one at place k. (Adler-32's
  two sums; a match's copies in LZ4; a chunk's chaining values in BLAKE3.) Written with `for i in 0 .. n`
  after its two equations, `NAME(x)` is its value at place n. Inside a definition, `let s[0] = E` and
  `let s[i + 1] = F` make one without a name of its own.

## No value

Three things have no meaning: a place outside a list, a difference below zero, a search with no result. A
specification that comes to one of them is wrong there, and the reader stops; nothing is given in its
place. The checker, reading on a path of the code, must be shown that it does not happen (the path's facts
show `i < len(bytes)`), or it refuses. So a specification that means to have no value somewhere says so with
`fails`, before it gets there.

## What is not in it, and why

- **Nothing that changes** (no assignment, no loop, no variable given twice). An auditor reading a state
  that changes must convince himself that an algorithm computes the thing; here he reads the thing. The
  earlier specification of BLAKE3 had a stack of subtrees in it; its own comment had to point to a proof that
  the stack was the tree.
- **No memory**: no addresses, no registers, no lengths in bytes of things. Those are the contract's.
- **No numbers that wrap**, but words, which are written `word(...)` and are of one size. A reader never has
  to ask whether `1024 * k` passes 64 bits.
- **No functions given to functions, no types with parameters, no modules.** None was needed for a hash, a
  checksum, a compression format or an encoding, and each makes "what does this name mean here" a longer
  question.
- **No search without bounds, no "there is" or "for all" over everything.** A search is among numbers that
  can be listed, so it has an answer that can be worked out.

## Known warts (November 15)

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
