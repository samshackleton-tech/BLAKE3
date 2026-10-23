# Compact AVX-512 experiment: EPYC 9255

This is a review checkpoint for pure-assembly BLAKE3 kernels and their Rust dispatch. **The tables and gates here are historical corrected-trim samples-v6 results**, from the exact instrument pinned below. They show substantial single-threaded cost reductions and small, repeatable positive multithreaded estimates. Fresh validation under the released every-sample v7 rule is in progress. Adoption requires that validation, further review, and another physical CPU.

## Source and instrument

- [Source checkpoint](https://github.com/samshackleton-tech/BLAKE3/tree/a5e1e18ad9874f419abfd61fe7c5c6c0f2bf7e00): `a5e1e18ad9874f419abfd61fe7c5c6c0f2bf7e00`.
- Measured snapshot: `215441f3f1c327e00869538eeced3ad90ec46dea`. Both have tree `221858fad66ba99619754f402424d5884b397e80`.
- Original baseline: `8e968d5599b3ae577f5234f1e8e5e10cfb72b9e4`.
- Existing bench-hashes instrument: `61afea44ac45fc94f0a91d5e150b56689891f074`; its clocks dependency stays pinned independently to `99d34d94db14eac01a9c652e0a4858055502b08f`.
- Host: native AMD EPYC 9255, 24 cores / 48 logical CPUs, Linux, performance governor. Server work was serialized. No local i7 native build or measurement was used.

All speed percentages below describe changes in the pinned v6 **trimmed wall-time cost estimate**, not throughput increases. This specific prerelease instrument calls `mean_totals` in clocks99d34d9 and excludes its slowest `ceil(n/100)` samples. It differs from the older released tools whose `Mean::of` bypassed that trim. CPU time is a separate measure, not core cycles. This pinned clocks implementation predates the homogeneous-Linux cycle-counter addition in BLAKE3 #138, so these comparisons provide no native EPYC core-cycle breakdown. The separate benchmark-calibration limitations discussed in bench-hashes #60 also remain; this experiment does not qualify the instrument for general reliance.

## Fresh v7 validation

The approved October 23 decision replaces trimming with total time / total work, counting every sample. A separate run pins released benchmark `ae6301136e1827cff86bf823f024870775b224d5` (0.17.0+1b480eed20d11d7cd1417384e4a9d540b0e321be) and clocks `7f9f1f7f79f4b239bf9b3089afdde83d2333febb`, with the new 1536-byte points. It checks the instrument, runs a four-pair A/A, then a sixteen-pair full comparison of this source against the original baseline. Results are pending. Old files are neither relabelled as v7 nor mixed with new runs.

## Results and open costs (historical v6)

The four-pair full parent comparison and sixteen-pair full original-baseline comparison both exit 0. Four-pair all-cell checks with two and eight participants also exit 0. The existing gate uses a 3% margin and controls discoveries across the cells; passing it does not establish equivalence.

| Solo workload, original baseline comparison | Wall-time change | Pairs faster |
|---|---:|---:|
| ST continuous 1 MiB | −21.7% | 16/16 |
| ST Nix collection | −16.2% | 16/16 |
| MT Nix collection | −17.4% | 16/16 |
| ST outboard 64 MiB | −11.2% | 16/16 |
| MT outboard 64 MiB | **+1.8%, level** | 2/16 |
| MT after-other-work message 64 MiB | **+1.9%, level** | 0/16 |
| MT after-other-work message 128 MiB | **+1.8%, level** | 0/16 |

The prior combined candidate failed the sixteen-pair gate: MT outboard 64 MiB +3.1%, 0/16 faster, CPU time ×1.139. Retaining the original register-message chunk kernel for pooled group jobs reduces this excess. At this checkpoint the cell's CPU-time ratio is ×0.996, while its wall-time mean remains positive. The general pooled-group rule also forgoes some gains observed with the wide kernel at smaller thread counts. Sequential group hashing and parent routing keep the new kernels.

The CLI comparison uses the existing `b3sum` machinery: four independently laid-out executables per side, sixteen rounds, single-threaded and default multithreaded, cached and storage-backed files. No cell is labelled slower. Warm ST 1 GiB process cost falls 19.3%; warm ST mixed tree falls 8.9%. Positive means include warm ST 64 KiB +5.4%, cold ST 4 KiB +8.1%, and warm MT 256 MiB +9.0%, all unlabelled. These remain observations to investigate; the CLI result does not imply every file or invocation improves.

Full printed comparisons are in `gate/`, `threads-2/`, `threads-8/`, and `cli-{st,mt}/`. They include the small positive means and CPU/energy observations. No universal energy improvement is claimed. `raw-and-native.tar.gz` contains the raw gate/low-thread samples, native test logs and CLI result directories. Its SHA-256 and BLAKE3 manifests are included and were both checked after transfer. Read these historical files with the pinned 61afea44/99d34d9 instrument, rather than the new v7 reader.

## What changed

The generated x86-64 assembly keeps eight independent compression chains active across 32 inputs. A compact seven-round loop limits instruction footprint. One flat block loop uses a 2368-byte aligned frame: 2048 bytes for the current transposed messages, 256 for counters, and a 64-byte CV spill; a nine-register output transpose packs adjacent chaining values into 64-byte stores. The k32/p32 pair occupies 4478 bytes of text. An experimental register-resident p16 parent entry brings the total to 7248 bytes. Its incremental benefit remains unresolved. Disabling only its production routing did not produce a clean improvement: the stronger historical gate flagged a small-message cell outside that route. That ablation is held separately.

Rust handles feature dispatch, bounds, tests, and a coherent tree-worker budget. Proposed compression arithmetic stays in assembly. Linux x86-64 dispatch retains the existing AVX-512 F+VL requirement, and existing kernels handle other supported systems, short routes, and tails. The proposed bodies use AVX-512F instructions. Proof sources are unchanged.

Useful review entry points:

- [`tools/gen_avx512_32.py`](https://github.com/samshackleton-tech/BLAKE3/blob/a5e1e18ad9874f419abfd61fe7c5c6c0f2bf7e00/tools/gen_avx512_32.py): readable register allocation and emitted schedule.
- [`src/ffi_avx512_32.rs`](https://github.com/samshackleton-tech/BLAKE3/blob/a5e1e18ad9874f419abfd61fe7c5c6c0f2bf7e00/src/ffi_avx512_32.rs): raw ABI contract, reference/route/startup controls.
- [`src/ffi_avx512_32_guard_tests.rs`](https://github.com/samshackleton-tech/BLAKE3/blob/a5e1e18ad9874f419abfd61fe7c5c6c0f2bf7e00/src/ffi_avx512_32_guard_tests.rs): guarded buffers and read-only sources.

The raw SysV entries take `(inputs, blocks, key, counter, packed_flags, out)`. k32/p32 consume exactly 32 pointers and write 1024 bytes; p16 consumes 16 pointers and writes 512 bytes. Blocks are 1–16; the final block length is 0–64 and its full 64-byte padded region is readable. k32 adds the input index to the counter with wrapping; p32/p16 keep it fixed. The source contract gives the packing, extents, and aliasing requirements.

## Validation limits

Current native suites pass: release 109, debug 110, no-default 37, pure 97, test vectors 3, C API 4, docs 22. Entry tracing, independent startup folds, corruption controls, bounds, tails, counters, and guarded-memory tests accompany the digest comparisons. Earlier standalone GCC/Clang ABI diagnostics cover callee-saved GPRs, selected control state, and output extents for these unchanged assembly bodies.

A scoped mutation pilot on an earlier checkpoint found 31 caught, 15 missed and unclassified, 3 unviable, and no timeout observations among 49 selected mutants. Unsafe functions and assembly were outside that tool's mutation scope. Seven separately seeded safe FFI fault controls were caught. This is neither a full current mutation inventory nor a formal kernel/constant-time/unwind proof.

A diagnostic runtime AVX2 override, retaining the compiled wide code and maximum workspace, passed native tests and a four-pair all-cell comparison on this EPYC. It is not another-CPU evidence. Actual second-machine validation, remaining positive costs, proof/assembly review, and integration onto the current public fork remain open.

## Reproduce the comparison

Use the source checkpoint above and the pinned benchmark revision in a nested `bench-hashes` checkout. The existing tool keeps its clocks dependency independent when it builds the two contenders:

```sh
cd BLAKE3/bench-hashes
cargo run --release -- check \
  --against 8e968d5599b3ae577f5234f1e8e5e10cfb72b9e4 \
  --cells all --pairs 16 --keep /absolute/path/to/fresh-samples
```

Coordinate native host use first. Read the benchmark's own methodology and retain its outputs and samples, including failures and busy/no-verdict results.
