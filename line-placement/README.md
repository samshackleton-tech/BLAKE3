# Buffer placement within a cache line: #65's precondition, and a cost of #141

AMD EPYC 9255 (Zen 5), Ubuntu 26.04, glibc. October 24, 2026, 06:40–08:30 UTC.
Every map is `tools/offset_check.py --map` (repeat 3; thread-stack axis in 64-byte
TLS quanta, main-stack axis in 16-byte steps, ASLR off). These are diagnostics,
not speed verdicts. The one `regress` run is noted as such.

## What was varied

`bench-hashes-allocator-options.diff` is against #67 (aedc061). It adds three
global-allocator options to the bench:

- `smalloc`: smalloc (crates.io `smmalloc` 7.6.13) as the global allocator. The
  samples header and report say so; default builds are unchanged.
- `diag-align64` (diagnostic only): the system allocator, with every allocation of
  64 bytes or more aligned to 64.
- `diag-line-offset` (diagnostic only): the system allocator, with every allocation
  of 64 bytes or more (alignment 16 or less) placed `BENCH_DIAG_LINE_OFFSET` = 16,
  32 or 48 bytes into a line.

The bench's tests pass with smalloc (`tests/bench-tests-with-smalloc.log`). The
uprobe address probes in `addresses/` confirm each placement for the main
thread's input: 64 B at 2128/2144/2160, 256 B at 2576/2592/2608, align64 at
1792/320.

## Results: base (servil b94e2fa), `blake3-servil-st`, buffers lent

| Buffer offset into a line | 64 B median | 64 B slow positions, shared / solo | 256 B median |
|---|---|---|---|
| 0 (align64) | 1.045 | 0/64 / 0/256 | 1.19 |
| 0 (smalloc: size-aligned slots) | 1.049 | 0/64 / 0/256 | 1.19 |
| 16 | 1.048 | 5/64 / 24/256, worst 1.44× | 1.29 |
| 32 | 1.053 | 4/64 / 20/256, worst 1.40× | 1.19 |
| 48 | 1.053 | 3/64 / 12/256, worst 1.48× | 1.31 |

- **#65's windows need the caller's buffer to cross a cache line.** At offset 0
  there are none on either axis. glibc's 16-byte alignment leaves 3 of 4
  placements of a 64-byte buffer crossing a line. The bench's usual one, 3360,
  is 32 into a line.
- **A second effect, separate from aliasing, at 256 B.** At offsets 16 and 48,
  256 B is uniformly about 8% slower than at 0 and 32, at every stack position.
  This is the solo 1.19↔1.29 "heap-layout state" we saw before #67.

## Results: the #141 fix (cba5f24, tree bd9af8ec) and an experiment

| Buffer offset | base 64 B | fix 64 B | fix-ymm 64 B | base 256 B | fix 256 B | fix-ymm 256 B |
|---|---|---|---|---|---|---|
| 0 | 1.05 | 0.94 (smalloc) | 0.95 | 1.19 | 1.15 (smalloc) | 1.16 |
| 16 | 1.05 | **1.30** | **1.31** | 1.29 | 1.24 | 1.25 |
| 32 | 1.05 | 0.94 | 0.95 | 1.19 | 1.15 | 1.16 |
| 48 | 1.05 | **1.38** | **1.39** | 1.31 | 1.27 | 1.27 |

- The fix is flat at every placement: there are no windows anywhere.
- **But at 64 B, with the buffer 16 or 48 bytes into a line, the fix is
  uniformly 24–31% slower than the base's median.** #141's speed check measured
  only placement 32 (glibc's usual), where the fix is 10% faster. Averaged over
  the four placements, the fix is slower at 64 B (about 1.14 against about 1.06
  for the base, windows included) and faster at 256 B (1.20 against 1.25).
- Counters (`counters/line-offset-mechanism`, CPU 3 pinned, solo lent 64 B, per
  1k instructions):
  - stli_other: fix 1.55/0.27/2.39 at offsets 16/32/48; base 2.5–2.8 everywhere.
  - IPC: fix 1.92/2.36/1.77.
  - Line-crossing loads (ma64): equal across placements.
- **Working hypothesis, not established.**
  - Before each timed call, the bench copies the input into its kept buffer
    (`take_prepared_sample`: `produced.copy_from_slice(input)`). glibc's memcpy
    writes 33–64 bytes as two 32-byte stores. At offsets 16 and 48, one of them
    crosses a line.
  - A load from a line-split store cannot be forwarded, so it waits for the
    store to commit. The fix reads the buffer soon enough after the copy to
    wait; the base, by this reading, does not.
- **What that hypothesis has to explain.** Loading the message as two 32-byte
  loads, the shape of the stores, changes nothing (`fix-ymm`,
  `chunk-root-ymm-experiment.patch`, 5c8fdb5, focused 3/3 and release 106/106
  pass). So it is not about a load's shape against the store's shape.

## smalloc as the global allocator

- **Determinism, 16 processes.** glibc+#67 gives 1 input offset. smalloc gives 2:
  320 ×14 and 0 ×2 at 64 B; 1024 ×14 and 256 ×2 at 256 B.
- **Speed.** `smalloc-vs-glibc-regress.out`: `regress`, 8 pairs, 8 relinked
  layouts a side, servil st/mt, sha256, ring, bench and servil the same on both
  sides; glibc is old, smalloc is new. Exit 0, but REGRESSION: 12 cells slower,
  every one a multithreaded servil collection or large-message cell:
  - continuous 4 MiB +21.7% shared / +39.1% solo;
  - outboard 1 MiB +22.5% / +23.4%;
  - lent 1 MiB +17.4% / +22.2%;
  - batches 65536 +16.1% / +26.5%;
  - Merkle 4096 +13.5% / +15.8%;
  - lent batches 16384 +12.5% / +13.8%.

  Faster: every 256 B cell of every contender, 5–11% (placement again), and
  servil ManyMessages 2048–8192, 4–5%.
- **One profile per side** (`counters/smalloc-mt-profile`):
  - dTLB load misses +57% and more system time under smalloc;
  - `__rust_alloc_zeroed` 7.8% of stli samples, against 0.7% under glibc.

  Causes not tested.
