# Shared LentMessages 64 B: a stack-offset (4 KiB aliasing) effect

Native AMD EPYC 9255 (Zen 5), Linux 7.0, glibc 2.43. Benchmark `ae6301136e1827cff86bf823f024870775b224d5` (0.17.0), clocks `7f9f1f7f79f4b239bf9b3089afdde83d2333febb`. Executables built by `bench-hashes check`: parent `a5e1e18ad9874f419abfd61fe7c5c6c0f2bf7e00` ("old") and a one-function `lanes.rs` change `36da4dbcb19efa0b9cebf3bf61bec22f8965168d` ("new"). Serialized server work; diagnostics, not acceptance runs.

## Finding

The shared (duo) LentMessages 64 B cell runs about 35–45% slower or not, depending on where the duo-copy threads' stack frames sit relative to the kept input buffer, modulo 4096. Unmodified binaries switch between the two states with one glibc tunable that shifts only new threads' stacks (`tls-sweep-table.txt`):

| Binary | `GLIBC_TUNABLES=glibc.rtld.optional_static_tls=` | duo stack slot mod 4096 | shared 64 B ST / MT ns/B |
|---|---:|---:|---:|
| old | 512 (default) | 528 | 1.05 / 1.05 |
| old | 528 | 464 | 1.46 / 1.55 |
| new | 512 (default) | 544 | 1.46 / 1.53 |
| new | 448 | 608 | 1.05 / 1.09 |

The kept input buffer sits at 3360 mod 4096 in every run. Solo samples (main thread) stay at 1.05.

## Supporting evidence

- Per-thread counters (`thread-counters-table.txt`): in the slow state both duo threads drop from IPC ≈2.1 to ≈1.4–1.6, with ≈2.5× more `ls_bad_status2.stli_other` (store-to-load conflicts) per instruction. The main thread is unaffected; dTLB misses are zero.
- Conflict sites (`data/lent64-stli-ip/*/stli-by-sym.txt`, `disassembly-hash_in_memory-new.txt`): the increase is in the digest hand-off after the hash returns and in call/return stack traffic.
- IBS data addresses: in the slow build, function entry/exit stack accesses of `hash_serial`/`hash_serial_from` land inside the input window (3360–3423 mod 4096).
- Ruled out: scheduler/SMT placement (`data/lent64-placement/`: the slow build stays slow pinned to two separate cores; the fast build slows only when forced onto SMT siblings), static-data false sharing (`.bss` statics identical modulo 128), changed code on the 64 B path (hash functions and kernels identical; frame sizes in callers differ).
- Focused reproduction (`data/lent64-repro/`): ~3 s per `regress --points 'lent 64 B'`, every pair slower; A/A of the parent clean.

## Not yet shown

The tunable moves the stack, not the heap buffer, so the separation of "relative offset" from "absolute stack alignment" is inferred from the counters and conflict sites rather than demonstrated by moving the buffer independently.

## Reproduce

```sh
# any servil build that bench-hashes check produced, e.g. target/check/old/bench-hashes-0
for s in 448 512 528 576; do
  GLIBC_TUNABLES=glibc.rtld.optional_static_tls=$s ./bench-hashes-0 --threads 48 \
    --contenders blake3-servil-st,blake3-servil-mt --points 'lent 64 B' \
    --for-regression-check --rounds 24
done
```

Which tunable values are slow depends on the build's frame sizes; sweeping 16–64-byte steps finds both states. `scripts/` holds the exact runners.
