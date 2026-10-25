# SMT on the EPYC 9255: what the "SMT co-location" slowdown was, and what it means for 0.8

October 25, 2026. AMD EPYC 9255 (Zen 5: 24 cores, 2 SMT threads each,
siblings n and n+24; 1 MiB L2 a core; 4 x 32 MiB L3), Linux 7.0.0-38,
governor `performance`. Measurement only: existing binaries and bench
builds, `perf stat` counters, and the bench's own `regress`/`compare`. No
code under test was changed.

## Summary

1. **The slowdown belonged to the held 32-way AVX-512 kernel, not to SMT
   in general.** Alone on a core it is the fastest kernel measured: 19%
   fewer ns/B than 0.8's at 1 MiB warm. It gets almost nothing from a
   second thread on the same core: two threads together do x0.96-1.11 of
   one thread's work, against x1.44-1.57 for 0.8's kernel. With its
   sibling busy, each of its threads is 14-32% slower than 0.8's kernel in
   the same place. Whenever siblings share a core (every all-core run on
   an SMT machine), its lead becomes a loss. Its all-core clock is also
   lower (3.62 against 3.79 GHz).
2. **Why:** alone, the narrow kernels (0.8's, official's) leave about 73%
   of dispatch slots stalled in the backend. The counters attribute
   nearly all of that to loads not yet complete (message data from L2/L3,
   sixteen chunks read side by side), not to busy execution units (0.4%).
   A second thread on the core fills those slots: with the sibling busy,
   57-59% of the measured thread's slots go to the sibling, and the core
   does 1.4-1.7x the work. The wide kernel hides more of that wait itself
   (memory-bound 44-48% of slots against 51-53%, retiring 13.7% against
   12.0%), so it is faster alone, but it leaves the sibling little idle
   capacity. It also executes 4.6% more instructions per byte.
3. **0.8 ships no such kernel. For 0.8's kernels SMT is a gain** (x1.44-1.73
   per core, the same as official BLAKE3), and the default of one thread
   per logical CPU is right for bulk work.
4. **Capping the pool at the physical cores is a trade-off, not a fix.** At
   the candidate, 24 threads (one per core) against 48: large one-shots
   (3-128 MiB) 3-8% slower, batches of 32768-65536 4-6% slower, collections
   10-39% slower; 512 KiB-1 MiB one-shots 6-7.5% faster, lent 1 MiB 5-9%
   faster. Unpinned and pinned 24 behave alike in the CLI, so the gain at
   medium sizes comes from **fewer threads to coordinate**, not from
   placement.
5. **Mixed-speed threads are already handled.** 36 threads on 12 doubled
   cores and 12 single ones (a stand-in for hybrid chips: two speeds of
   thread in one pool) lands between 24 and 48 threads at 1 GiB, with no
   straggler collapse. Its 7.99 ms is about 7% above an ideal
   capacity-proportional figure. The pool's dynamic claiming of shrinking
   pieces (lanes.rs, "Pieces") does what it was designed to do.

## Part 1: one thread's kernel under SMT, streaming 1 GiB (`part1`)

`b3sum --num-threads 1` on a 1 GiB file in /dev/shm, pinned. Medians of 5
(siblings and separate: 10 processes; 24 or 48 processes: 120/240).
These figures include streaming the file from DRAM.

| kernel | alone cyc/B (IPC) | sibling busy cyc/B (IPC) | core with 2 threads | 48 vs 24 threads, whole machine |
|---|---|---|---|---|
| 0.8 candidate (ee4c0d7) | 0.544 (1.89) | 0.656 (1.57) | x1.66 | x1.67 |
| official b3sum 1.8.2 | 0.547 (1.90) | 0.662 (1.57) | x1.65 | x1.68 |
| servil baseline (8e968d5) | 0.542 (1.90) | 0.652 (1.58) | x1.66 | x1.65 |
| held wide kernel (215441f) | 0.474 (2.27) | 0.729 (1.48) | **x1.30** | x1.55 |

Instructions per byte: narrow 1.028-1.038, wide 1.076. Clock with every
CPU busy: narrow 3.78-3.87 GHz, wide 3.62 GHz.

## Part 1b: cache-resident input, sibling kept busy (`warm3`)

The bench's own single-thread one-shot cells (64 KiB, 1 MiB, warm) on CPU
0. In the busy cases, the same kernel hashes a 16 MiB file in a loop on
CPU 24 (the sibling) or CPU 1 (another core) for the whole run. Medians of
5 processes. Each measured process ran under `perf stat -M PipelineL1`.

| kernel | cell | alone | other core busy | sibling busy | per-thread cost of a busy sibling | core with 2 threads |
|---|---|---|---|---|---|---|
| 0.8 candidate | 64 KiB | 0.1524 | 0.1756 | 0.2122 | x1.39 | x1.44 |
| 0.8 candidate | 1 MiB | 0.1272 | 0.1287 | 0.1619 | x1.27 | x1.57 |
| official | 64 KiB | 0.1565 | 0.1780 | 0.1926 | x1.23 | x1.63 |
| official | 1 MiB | 0.1271 | 0.1288 | 0.1647 | x1.30 | x1.54 |
| wide | 64 KiB | **0.1339** | 0.1777 | **0.2798** | **x2.09** | **x0.96** |
| wide | 1 MiB | **0.1032** | 0.1071 | **0.1854** | **x1.80** | **x1.11** |

(ns/B. A busy *other* core costs the 64 KiB cell about 15% for every
kernel: the loader is a loop of processes, with their exec and page-fault
traffic. So the 64 KiB sibling figures include that too; 1 MiB is the
cleaner cell.)

Dispatch slots (PipelineL1, whole bench process, medians):

| kernel | placement | retiring | SMT contention | backend-bound | frontend-bound |
|---|---|---|---|---|---|
| 0.8 candidate | alone | 12.0% | 1.6% | 73.2% | 12.6% |
| 0.8 candidate | sibling busy | 8.2% | 59.2% | 25.8% | 13.0% |
| official | alone | 11.9% | 1.7% | 72.9% | 12.8% |
| official | sibling busy | 8.3% | 56.6% | 23.9% | 12.3% |
| wide | alone | 13.7% | 1.4% | 65.4% | 17.5% |
| wide | sibling busy | 8.9% | 45.4% | 24.4% | 17.5% |

PipelineL2, alone (3 runs each): backend-bound by memory (the retire
head waiting on a load) 51-53% for 0.8's kernel and 44-48% for wide;
backend-bound by CPU 0.4-0.5%. These metrics multiplex their counters
(5-25% coverage each), so the attribution is approximate.

## Part 2: the candidate's pool by thread count and placement (`part2`)

The candidate's b3sum (ee4c0d7) on a warm file, wall ms, median of 9 (x
against 48 threads):

| size | 48 threads, all CPUs | 24 unpinned | 24, one per core | 36 on 36 CPUs (12 doubled cores, 12 single) | 24 on 12 cores (all doubled) |
|---|---|---|---|---|---|
| 4 MiB | 1.55 | 1.19 (x0.77) | 1.09 (x0.71) | 1.11 (x0.72) | 1.13 (x0.73) |
| 16 MiB | 1.73 | 1.41 (x0.82) | 1.42 (x0.82) | 1.44 (x0.83) | 1.30 (x0.75) |
| 256 MiB | 3.27 | 3.27 (x1.00) | 3.36 (x1.03) | 3.31 (x1.01) | 3.77 (x1.15) |
| 1 GiB | 7.32 | 9.32 (x1.27) | 9.70 (x1.32) | 7.99 (x1.09) | 11.26 (x1.54) |

These are whole CLI processes. At 4-16 MiB the cost of 48 threads is the
process starting its 47 workers (20-30 us each, by the library's docs)
and coordinating them, which a long-lived library pool pays once.

## Part 3: the library's mt cells, 24 threads one per core against 48 (`part3`)

`regress --contenders blake3-servil-mt --pairs 8` on 8 of the
candidate's own relinked builds (ee4c0d7, bench d21cdf36). Wrappers `--threads
48` and `taskset -c 0-23 ... --threads 24`; all 16 runs quiet.
"REGRESSION: 17 cells slower", 14 faster:
- slower with 24: Collection git objects +38.8% (solo) / +37.7% (shared),
  Nix files +9.5% / +21.2%; one-shots 3, 4, 32, 64, 128 MiB +3.2% to
  +5.1%; after a pause 3-128 MiB +3.9% to +7.6%; batches of 32768 and
  65536 +3.9% / +5.7%; lent 4 and 64 MiB +3.6% / +5.4%;
- faster with 24: one-shots of 512 KiB and 1 MiB -7.5% / -6.2%; after a
  pause -7.3% / -7.1%; lent 1 MiB -5.2% (solo) / -8.9% (shared); lent
  batches of 256 and 16384 -4% to -7%; Merkle 4096/16384 -3.7%; batches
  of 8192/16384 after a pause -3% to -6%.

## What this suggests for 0.8

- **No SMT fix is needed in the code.** 0.8's kernels gain 1.4-1.7x a core
  from SMT, as official's do. Defaulting to one thread per logical CPU is
  correct for throughput. A physical-core default would cost bulk and
  collections more than it saves at medium sizes. It would also need
  topology code on every OS (Linux sysfs, macOS sysctl, Windows), and that
  code can't be tested on the machines we don't have.
- **The wide kernel stays held.** Its alone-on-a-core advantage turns into
  a loss whenever siblings share cores. Choosing it only when a thread
  has a core to itself would need exactly the topology knowledge and
  runtime policy we don't want.
- **A simple accommodation: say it in the docs.** `initialize_multithreaded`'s
  `None` counts logical CPUs, SMT threads included. Which choice is
  right depends on the workload, and the measured trade-off would let
  users choose. The pool's shrinking pieces already handle threads of
  unequal speed (SMT siblings, efficiency cores, other programs). That
  is the part most likely to matter on hybrid or untested SMT machines.

## Not claimed

One machine and one microarchitecture. On Intel SMT (Hyper-Threading,
different ports and caches) the per-core gain may differ; Arm and Apple
chips have no SMT. The pool-level and CLI figures are diagnostics, not
release gates. The counters' attribution is approximate.
