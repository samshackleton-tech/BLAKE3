# Contract integration and Devon's core-axis detector — EPYC, October 24

## What the earlier GPR measurements exercised

The scalar kernel experiment 218b3bc was on #141 d3e3cbe. Its benchmark called
`hash()` and returned the digest by value. The aligned screen used a diagnostic
GLOBAL allocator, not the batch-only placement contract. Those figures remain
convenience-API/diagnostic measurements. They say nothing yet about the heap-output
performance API. Neither GPR implementation is selected in normal builds.

## New integrated pair

- Library: Devon `exp/hash-with-out` **f5034096284e63eba66f0f1af1d257e4a3259256**,
  plus the unchanged opt-in GPR experiment, cherry-picked as
  **e49e06f389ff79f36f4f1dd8ee1f91f35bd4ed7d**.
- Benchmark: Devon batch-alignment branch **665438c36477686ca72aedb48395e06265c847ff**
  (e943576 + the Merkle-test correction), plus Devon's heap-output experiment
  **2b7c9ea4f621df7c19855994258cb826c3aea81e**, cherry-picked as **18de07c**.
- No diagnostic global allocator. Batch inputs start at 64-byte boundaries;
  ordinary single-message inputs retain allocator placement. Servil ST kept-buffer
  cells call `hash_with(Mode::Hash, input, out)` with a Box destination.
- 107/107 native library tests pass with GPR enabled. The output-only bench
  passes 44/44 tests. The combined bench passes 45/45 with the SIMD implementation
  and 45/45 with the GPR implementation.
- Initial nextest invocation failed because I passed Cargo's `--config` before
  the external `nextest` subcommand; nextest's nested Cargo invocation used the
  old dependency. Retrying as `cargo nextest run --config ...` selected the
  intended checkout. The failure is retained; it is not a code failure.

**Open benchmark issue, reported to Devon:** `each_message_into_kept` allocates
its Box inside the helper. `hash_lent` calls that helper once per message, so
this means a fresh allocation and free per message, not one slot kept throughout
the sample. The built SIMD bench's `hash_in_memory` contains:

```
6b6e7: mov $0x20,%edi
6b6ec: mov $0x1,%esi
6b6f1: call *... <calloc@GLIBC_2.2.5>
...
6b763: mov %r14,%r8
6b766: call ... <blake3_servil::hash_serial>
...
6cdab: call *... <free@GLIBC_2.2.5>
```

`call-path.txt` retains the complete function. No performance verdict is claimed
from the integrated pair before that allocation is resolved.

The source contract takes `&mut Hash`, which can denote heap or stack storage;
heap residency is the performance-oriented caller's responsibility, not something
the Rust reference type itself enforces. MT's output-parameter wrapper still
assigns a returned value (`*out = lanes::hash_with_key(...)`), so its full
no-temporary path is not established by the serial experiment.

## Devon's core axis, 103adbf

Ran the exact tool with `--axis core` against the existing #69 aligned base
benchmark, once, bounded to 470 seconds. It completed in **144 seconds**:
48 logical CPUs scanned, 6 solo cells, 19 places rescanned twice, 5 eight-pair
confirmations. Every confirmation independently selected an odd logical CPU
against an even one; all six cells were judged core-sensitive. Exit 0 means
successful detection/reporting, not that the cores are equivalent.

CPU1 versus CPU24, cost increases (all 8 pairs positive):

| Cell | servil | official |
|---|---:|---:|
| 64 messages | +37.7% | +31.2% |
| 256 messages | +21.1% | +18.0% |
| one 64 KiB message | +8.8% | +15.9% |

The other confirmed pairs: 19/32, 29/24, 11/2, 5/24. These confirm detection
on the EPYC; they do not explain the hardware cause. Full tool output and the
scan/rescan/confirmation runs are retained in `core-axis.tar.gz`.
