# The hash's hexadecimal: source, compiler, proof

`Hash::to_hex` is two kernels of vector instructions, one for x86-64 (SSE2, 45 instructions) and one for
AArch64 (NEON, 32). Neither is written by hand in assembly: both are printed from `hex.ode`, and Lean
checks, of the instructions as assembled, that they write the hexadecimal and show an observer of time
and cache nothing of the hash.

## What is claimed

One contract, for both, in `spec/HexContract.lean`, naming no machine:

> `Hex.byteContract out hash`: the 64 bytes at `out` become `Hex.text` of the 32 bytes at `hash`, which
> are unchanged.

`Hex.text` is `spec/HexText.lean` (two characters a byte, the high four bits first; `0` to `9`, then `a`
to `f`). `spec/Contract.lean` says what a contract is.

| | x86-64 | AArch64 |
|---|---|---|
| the machine | a model written here (`x86/Machine.lean`, 435 lines) | Google DeepMind's (`arm64-semantics` of github.com/google-deepmind/code-verification, Apache-2.0, unchanged, fetched at the commit `arm/lakefile.toml` names) |
| what meeting a contract means there | `x86/Abi.lean`, `x86/AbiBytes.lean` (System V) | `arm/ArmAbi.lean` (AAPCS64, in their logic) |
| the theorem | `hex_meets_bytes` (`x86/Meets_hex_bytes.lean`): for every hash the instructions meet the contract, and what an observer sees (`x86/Observer.lean`: every address read or written, every jump) is one list, whatever the hash | `hex_neon_meets` (`arm/HexNeonBytes.lean`): the instructions meet the contract; `hex_neon_quiet`, `hex_neon_observed` (`arm/Quiet_hex_neon.lean`): two machines that differ only in what memory holds and in the vector registers show an observer (`arm/Observer.lean`) the same |
| the instructions the theorem is about | read back from the assembled object by `x86/lift_one.py` (llvm-objdump's listing) | the object's 32 words; Lean decodes them with their decoder |

## How it is checked

- `check-shipped.sh` (python3; under a second): `c/blake3_hex_x86-64_unix.S` and `c/blake3_hex_aarch64.S`
  are what `odec.py` prints from `hex.ode`, byte for byte.
- `prove.sh` (elan, a C compiler, llvm-objdump; minutes): for each architecture, print, assemble, read
  the instructions back, write the proof (`x86/prove.py`, `arm/gen_arm.py`; the proofs kept here must be
  what they write) and have Lean check it. Then the audits (`x86/mutants.py`, `arm/mutants_quiet.py`;
  `MUTANTS=0` skips them): an unchanged copy must be accepted; then changed instructions, code that shows
  the hash, and false or weaker statements must each be refused.

The compiler (`odec.py`) and the proof generators are not trusted: a wrong print or a wrong proof is a
theorem Lean refuses.

## What it does not say

- Nothing of an instruction's own time: no model has it. (Arm's DIT and Intel's DOIT are the vendors'
  promises that these instructions take the same time whatever their operands.)
- On x86-64 the instruction table is the lifter's reading of the object, not Lean's. On AArch64 Lean
  decodes the words; there the observer's theorems are about the words run in order, not yet about the
  model fetching them from memory (the contract's theorem is).
- The proofs are about the instructions of ELF objects. The kernels use no relocation that differs on
  Mach-O (AArch64: none at all).
- Axioms beyond Lean's three: `bv_decide`'s (each a claim that a SAT certificate was checked by compiled
  code): 5 for `hex_meets_bytes`; 8 for `hex_neon_meets`, all in the kernel's own proof (the lemmas between
  bytes and vectors are checked by Lean's kernel alone); the AArch64 observer's theorems need none.
- That `Hash::to_hex` passes the kernel the right addresses is Rust's, and the tests'.

## What a call takes, measured (single runs; no judged timing yet)

`Hash::to_hex` through the library, beside the arithmetic of 0.9 it replaces:

| machine | this draft | 0.9 | the kernel alone |
|---|---|---|---|
| EPYC 9255 | 3.47 ns | 6.54 ns | 2.31 ns |
| Ryzen 9700X | 3.25 ns | 5.20 ns | 1.86 ns |
| Apple M6 | **3.50 ns** | **1.85 ns** | 1.72 ns |
| a Neoverse virtual server | **10.2 ns** | **8.2 ns** | 6.3 to 6.7 ns |

**On AArch64 the draft is slower than what it replaces.** The compiler makes vector code of 0.9's arithmetic
that is as fast as the NEON kernel alone, and the kernel adds a call and a copy. This is a measured
regression and is not settled: to try, a NEON kernel that looks the characters up in a register (`tbl`);
failing that, the cost is to be weighed against the proof, or AArch64 keeps the arithmetic.

The string is made from a buffer the kernel fills: written in place by the kernel, the string was copied out
of the function across the kernel's sixteen-byte stores, and the call took as long as 0.9's on x86-64.

## Where it comes from

The experiment under BLAKE3 #361 (branch `experiment/sam-machine-code-lean` of the fork,
`tools/verify/machine/`): this folder is what these two theorems need and nothing else. `odec.py` is that
experiment's whole reader; only its kernel printers are used here.
