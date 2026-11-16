# What a contract means

A contract is the one thing, beside the specification it names, that a reader has to read about a function in
a binary. It is a Hoare triple with nothing left to be understood: what the caller must make true, and what
is then true when the function has returned. This page is the same for every function; read it once.

```
contract NAME(ARGUMENT: KIND, ...) {
    requires ...
    ensures ...
    returns ...
    writes ...
    trace depends on ...
    needs ...
    stack ...
}
```

**The arguments** are in the registers of the calling convention, in the order written: rdi, rsi, rdx, rcx,
r8, r9. An argument is a number (`number`: what a register holds, 0 to 2^64 - 1; `byte`: a number below
256; `any`: 64 bits of which nothing is asked) or the address of bytes in memory (`N bytes`; `len bytes`:
as many as the number `len`, another argument). The number a function returns is of the same size. (In a
specification a number is of any size and never wraps: LANGUAGE.md. It is only an argument or a result
that a register bounds.)

**`requires`**: what the caller makes true. `requires apart(a, b, ...)`: the things at those addresses do not
overlap one another. One thing is required of every caller and not written: the stack is the machine's own,
and nothing an argument addresses lies in it. Of a call that does not keep these, nothing is said.

**If the caller does that, the function returns**, and then:

- `ensures X = E`: the bytes at X are E, a value of the specification. `ensures X[a .. b] = E`: those of its
  bytes, and nothing is said of the rest of X, which may then hold anything. `ensures ... if C`: where C
  holds. On the right, a name means what was there when the function was called.
- `returns E`: the number it gives back. With no such line, nothing is said of that number. `returns r`,
  where r is no name of the specification's, gives the number that name, and other lines speak of it:
  `ensures lz4(out[0 .. r], n) == input if r != NO` (what it wrote decodes to the input, unless it said NO),
  `ensures r != NO if cap >= n + n / 255 + 16` (and with that much room it does not say NO).
- `ensures CONDITION`: something true or false of the result and of what is in memory.

Memory holds bytes and nothing else. Where a specification speaks of words, the contract says how bytes are
read as words: `words(X)` is every four bytes one word, the lowest byte first; `bytes_of(W)` is the other
way. Both are the language's own (LANGUAGE.md) and a specification may not define them otherwise.

**And it has done nothing else.**

- It has read no memory but what its arguments address, its own stack, and constants that lie in the
  binary beside its code.
- It has written no memory but what an `ensures` or a `writes` names (`writes X`: X may hold anything
  afterwards), and at most `stack` bytes below the caller's stack pointer.
- The registers the calling convention says a callee keeps are as they were.
- It has run no instructions but those every x86-64 processor has, and those a `needs` line names
  (`needs F if C`: only where C holds). That the processor has them is the caller's to know.
- Which instructions it ran, and which addresses it touched, depend on the numbers it was given and not on the
  bytes in memory: unless a line `trace depends on X` says they may depend on the bytes at X.

A function that does more, or promises less, says so in its contract. Silence always means the stronger
thing.

**What a specification's definition may be.** A definition has a value, or it `fails` with a reason
(`fails REASON if C`, in the order written). `failed(E)` says whether E has no value. A contract speaks of a
failing input through it: `returns if failed(lz4(input)) then NO else ...`.

**What the verifier does with it** (check_binary.py for the hash; programs/check_file.py for the others): it
shows all of the above from the binary's bytes, for everything the `requires` lines allow, or it refuses.
The contracts of the functions inside (proofs/inner.spec) are steps of that showing, in the same form, with
two lines of their own (`decreases`, `calls`); a reader need not read them.

**Not yet so** (November 15). There are two verifiers of functions: `kfn.py` for the hash (words, vectors,
calls by contract) and `kbyte.py` for the programs of `programs/` (bytes, numbers, loops with places). The
first does not yet know `ensures X[a .. b]`, `ensures ... if C`, `ensures CONDITION` or `trace depends on`, and
refuses a contract that has them; the second follows calls by contract (programs/frame) but not a function
that calls itself, and knows none of the first one's kinds of memory. In a specification a name is defined
once: a text that defines one twice is refused (so a proof's inner contracts, read after the reader's
text, cannot change it). A proof's part may also hold lemmas (`lemma NAME(...) { requires ... ensures ... }`:
a contract of one of the specification's definitions, of its value `result`): the verifier shows each
before it uses any, so they change no meaning either, and a reader need not read them. The inner contracts of the hash
(`proofs/inner.spec`) still name kinds of memory (`cv`: eight words); the public contract does not. That a
function returns is shown as far as the kernels it calls (README.md).
