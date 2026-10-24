# AFK validation and smaller GPR kernel — EPYC 9255, October 24

Native jobs serialized, approximately 20:00–22:00 UTC. No production dispatch
or public overview changes. All implementation comparisons use bench-hashes
regress/compare, 16 independently relinked layouts per side, 16 alternating
pairs. The final broad-family control uses the ordinary first-stage budget of
4 pairs. Raw samples, failed attempts and command logs are in the archive;
readable comparisons and state files are in `summary/`.

## Caller model and scope

Experimental `diag-direct-flow` feature: calculate the message directly in
its final aligned input buffer (or the aligned Stream ring), write the digest
into its final heap slot, and read all its words there into a scalar checksum.
No caller message-copy or digest-copy sink. Single-message latency normally
feeds that checksum into the next message's seed; batches/streams are independent.
The word producer emits 8-byte generated stores. A second producer fills the
input directly with a varying byte. Generation, hashing, consumption and stream
setup/draining are included; these are not compression-only timings.

ST affinity CPUs 0,2; streams CPUs 0,2,4,6 with four participants. Shared scenarios
are retained. Every samples file labels the experiment, producer, requested
kernel and, where applicable, active plant. Ordinary convenience OneMessage
cells are unchanged by the experiment and checked separately below.

## Controls: what passed, and what had to be corrected

1. Ordinary SIMD A/A, 16 layouts per side: no slower cell in serial/batch or
   stream families.
2. First plant attempt was INVALID: the driver omitted plant=True, so the
   group compiled without its feature. The sample headers correctly lacked
   the plant. These runs say nothing about sensitivity and remain archived.
3. Enabling the compile-time plant detected solo64 (+16.4%), but also shifted
   two batch16 cells (~+6%). The changed helper code/setup made this an unsuitable
   isolated one-cell control. Implementation comparisons stopped as declared.
4. Final control: identical plant-capable code on both sides; equal-length
   DIAG_DIRECT_PLANT_ACTIVE=0/1 settings. Independent layouts on each side.
   - A/A inactive: no slower cell in either family.
   - Active: ONLY solo direct64 slower, +16.2%, all16 pairs positive.
   - Headers checked for old inactive / new active.
5. Broader family: 412 ST/MT cells, four pairs, only that same cell flagged
   slower (+16.1%; pairs +16.1/+16.1/+16.0/+16.3%). This tests the full-family
   first-stage comparison budget, not coverage selection or every possible
   slowdown. It does not establish universal detector reliability.

The positive control adds one hash every fourth message in the solo64 cell,
observes its output, then performs the normal hash; the final digest agrees.
Its scope has a native test. Implementation speed comparisons compile the
plant feature OUT altogether.

## Original GPR kernel: confirmation and sensitivities

Library 0627c0c38309a9e68ecf51ca1764978a67c6cb3d (Devon f503409 output API,
GPR opt-in, aligned Stream ring). Benchmark
84248f33eb0a8d196e8e17a68acc711f4a5c641f.

Cost reductions against SIMD, solo single-message cells:

| Producer/model | 64 B | 256 B | 1 KiB |
|---|---:|---:|---:|
| dependent generated words | 22.8% | 22.2% | 23.2% |
| dependent byte fill | 20.8% | 23.4% | 23.9% |
| independent generated words (bench e24c2df) | 23.3% | 23.5% | 23.2% |

All16 pairs faster in each cell. Removing the cross-message dependency did
not explain the earlier 64 B reversal versus the copy-in benchmark. That
mechanism remains open; neither dependency nor producer width is established
as its sole cause.

Batches remain level. Streams remain mixed/level, NOT equivalent: with words,
solo1KiB mean +14.5%, solo64 +6.9%, shared64 +5.6%; with fill, shared1KiB +5.6%.
The previously profiled wide batch kernels and queue work dominate these paths.

## Smaller resident-D kernel: the substantial new improvement

Measured library **6cad867a5cafe5b6d75f360be86b884dc026c5fb**, based on the same
0627c0c. Generator `tools/gen_x86_gpr_resident.py` uses the same arithmetic,
message reads, ABI and SSE2 requirement. Two D-row words stay in GPRs between
rounds; independent Gs are reordered:

```
columns 0,1 -> 2,3 -> diagonals 3,0 -> 1,2
```

GP/XMM transfers fall from 16 to 8 per round. No new branch, spill, packed-word
arithmetic or CPU-specific instruction. Text shrinks **3232 -> 2996 bytes**.

Against the original GPR, words: 17.2%/17.9%/16.5% less time at 64/256/1024 B,
all16 pairs faster. The DIRECT comparison against SIMD (not composed ratios):

| Size | SIMD ns/B | resident-D ns/B | Paired cost reduction |
|---|---:|---:|---:|
| 64 B | 1.380 | 0.884 | 35.9%, 16/16 |
| 256 B | 1.262 | 0.807 | 36.1%, 16/16 |
| 1 KiB | 1.246 | 0.796 | 36.1%, 16/16 |

64 B is **88.3 -> 56.6 ns/message**; 1 KiB approximately **1.276 -> 0.815 us**.
Fill gives 37.7%/37.2%/36.8% reductions, all16 pairs faster. Batch controls stay
level. These are warm direct-flow calls on one host, not cross-machine claims.

Validation: 199680 ABI/output/canary differential calls pass (all input and
output offsets modulo64; all whole-block counts and final lengths; three flag
modes), library 108/108, benchmark 49/49. These are tests, not formal proofs.

An Intel-testable branch **8e6f0a1a3fa016a7cb0528ed7fbf593b57600883** has the
same assembly, plus opt-in routing on SSE4.1/AVX2 CPUs and corrected test tracing
of the actual GPR entry. EPYC native tests: default108/108, GPR109/109, including
both x86 routes. Its glue differs from measured 6cad867; no Intel timing claim.

## Other controlled variants

- Two 16-byte GPR output stores instead of eight 4-byte stores (ff46a606):
  words producer -1.0%/-1.7%/-0.1%, level; fill64 -5.4% faster, other lengths
  mostly level. Extra packing instructions and SSE4.1; not combined with
  resident-D and not proposed for adoption on this evidence alone.
- `vzeroupper` at SIMD return (2c48fa4): roughly -1% or less, level. It does
  not account for the large gap. Resident-D still wins 35–36% in a direct
  comparison with this SIMD variant.
- Three repeats of Devon's 103adbf core-axis detector find the six known
  core-sensitive cells. Hardware cause still open; these are detector checks.

## Costs still owed: convenience API

Unchanged after-other-work OneMessage cells, same retained 16-layout sets:

| Size | SIMD ns/B | resident-D ns/B | Paired judgment |
|---|---:|---:|---|
| 64 B | 4.857 | 8.636 | +77.8% slower, 0/16 faster |
| 256 B | 2.248 | 2.869 | +27.6% slower, 0/16 faster |
| 1 KiB | 1.555 | 1.417 | -8.9% faster, 15/16 |

The prototype's current global opt-in substitutes its one-chunk kernel for
convenience calls too. These regressions block an unconditional replacement.
The performance API and convenience API must be evaluated separately, with
cross-machine checks before selecting a production policy. Default builds
still use SIMD; no published overview result was replaced.

## Reproduction

Sources are on Sam's forks in experimental branches. Run builds with the
library enclosing the benchmark and the benchmark's git dependency patched
to that checkout. `--features diag-direct-flow` selects this workload;
`diag-direct-fill` selects its byte-fill sensitivity variant.
`BLAKE3_DIAGNOSTIC_GPR=1` at build time selects the GPR prototype. Runtime
plant activation is required only for a `diag-direct-plant` build.
Scripts retain exact paths, pins, feature sets, link seeds, layout orders,
commands and timings. Benchmark default features are unchanged. Keep these
experimental results separate from released 0.17 and future standard workloads.
