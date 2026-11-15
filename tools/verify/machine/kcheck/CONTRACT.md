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
r8, r9. An argument is a number (`number`; `byte`: a number below 256; `any`: 64 bits of which nothing is
asked) or the address of bytes in memory (`N bytes`; `len bytes`: as many as the number `len`, another
argument).

**`requires`**: what the caller makes true. `requires apart(a, b, ...)`: the things at those addresses do not
overlap one another. One thing is required of every caller and not written: the stack is the machine's own,
and nothing an argument addresses lies in it.

**If the caller does that, the function returns**, and then:

- `ensures X = E`: the bytes at X are E, a value of the specification. `ensures X[a .. b] = E`: those of its
  bytes. `ensures ... if C`: where C holds.
- `returns E`: the number it gives back. With no such line, nothing is said of that number.

**And it has done nothing else.**

- It has read no memory but what its arguments address, and its own stack.
- It has written no memory but what an `ensures` or a `writes` names (`writes X`: X may hold anything
  afterwards), and at most `stack` bytes below the caller's stack pointer.
- The registers the calling convention says a callee keeps are as they were.
- It has run no instructions but those every x86-64 processor has, and those a `needs` line names
  (`needs F if C`: only where C holds).
- Which instructions it ran, and which addresses it touched, depend on the numbers it was given and not on the
  bytes in memory: unless a line `trace depends on X` says they may depend on the bytes at X.

A function that does more, or promises less, says so in its contract. Silence always means the stronger
thing.

**What a specification's definition may be.** A definition has a value, or it `fails` with a reason
(`fails REASON if C`, in the order written). `failed(E)` says whether E has no value. A contract speaks of a
failing input through it: `returns if failed(lz4(input)) then NO else ...`.

**What the checker does with it** (check_binary.py, check_all.py): it shows all of the above from the
binary's bytes, for everything the `requires` lines allow, or it refuses. The contracts of the functions
inside (proofs/inner.spec) are steps of that showing, in the same form; a reader need not read them.

**Not yet so** (November 15): BLAKE3's public contract still gives `out` and `key` as eight words, lowest
byte first (`cv`), where it should give bytes. The checker of functions does not yet know `ensures X[a .. b]`,
`ensures ... if C` or `trace depends on`, and refuses a contract that has them. That a function returns is
shown as far as the kernels it calls (README.md).
