# Announcing BLAKE3-Servil 0.9 (and `blake3-servil-core`)

BLAKE3-Servil `0.9.0` reduces the library's scope, source size, and API surface to make the core easier to audit and verify, and fixes security and safety bugs found in `0.8.0`.

## Two crates, starting with a single-threaded core

`0.9.0` splits the library into two crates:

- **[`blake3-servil-core`](https://crates.io/crates/blake3-servil-core)** provides everything except multithreading. Every call runs on the calling thread, with zero background threads and zero locks. Without its `std` feature, it needs no allocator. Isolating the sequential core removes the thread pool and concurrency machinery from the code an auditor or verifier has to inspect, while keeping every proved ARM64 and x86-64 assembly kernel.
- **[`blake3-servil`](https://crates.io/crates/blake3-servil)** re-exports `blake3-servil-core` and adds a shared thread pool and multithreaded calls (`hash_multithreaded`, `hash_many_multithreaded`, `hash_each_multithreaded`, `update_multithreaded`, `update_each_multithreaded`).

## Smaller API, and no streaming API in 0.9

- **Streaming removed for now.** `0.8.0`'s `performance::stream` API is gone. A single replacement streaming API (`Pipeline`) is in development for a later release.
- **Explicit cold vs. hot paths.** `0.8.0` read a clock on every call to guess whether code had left the CPU caches. `0.9.0` drops that clock. Calls in `convenience` (including `Hasher`) tune for calls made amid other work; calls in `throughput` (renamed from `performance`) tune for calls made back to back.
- **Simpler `Hasher`.** `Hasher::finalize` and `Hasher::finalize_xof` consume `self`, and `count` and `reset` are removed.

## Security and safety fixes (`0.8.0` yanked)

`blake3-servil` `0.8.0` has been yanked from crates.io under [GHSA-mf3f-vh3v-f7v6](https://github.com/servil-software-factory/BLAKE3/security/advisories/GHSA-mf3f-vh3v-f7v6):

- **Stream memory-safety bugs removed ([#308](https://github.com/servil-software-factory/BLAKE3/issues/308), [#302](https://github.com/servil-software-factory/BLAKE3/issues/302)).** `0.8.0` had a safe `Stream::open` function that could leave worker threads accessing borrowed buffers after `mem::forget`, and a ring-slot reuse race in `performance::stream`. Removing the stream eliminates both.
- **Constant-time hex and key-independent grouping ([#370](https://github.com/servil-software-factory/BLAKE3/issues/370), [#312](https://github.com/servil-software-factory/BLAKE3/issues/312)).** `Hash::to_hex` and `Hash::from_hex` now compute over all 64 characters with branch-free arithmetic instead of table lookups and early-exit checks, and `update_each` groups hashers by public parameters rather than comparing secret keys.
- **Overflow check in `Batch::new` ([#320](https://github.com/servil-software-factory/BLAKE3/pull/320)).** `Batch::new` now panics when block capacity overflows `usize` in release builds instead of wrapping.

## Performance tuning

- **x86-64:** whole-chunk and parent passes round up to full SIMD lane widths (24–45% faster on 3–8 KiB single messages on Ryzen 9700X), short-message batches and new `Packed<16>` / `Packed<32>` inputs hash 8 or 16 leaves at a time (45–78% faster single-threaded Merkle trees), and `finalize_each` finishes 16 hashers at once on AVX-512.
- **ARM64:** plain short messages fed incrementally finish side by side (`finalize_each`), and unnecessary startup self-test cases were trimmed so single-file `b3sum` invocations stay fast.

## Links

- **`blake3-servil-core` API preview:** [`docs/core-api.md`](core-api.md)
- **Full changelog and `b3sum` / C library downloads:** [`v0.9.0+73ee859efce085d28f1c2b22c35a5703403476f7` release](https://github.com/servil-software-factory/BLAKE3/releases/tag/v0.9.0%2B73ee859efce085d28f1c2b22c35a5703403476f7)
- **Benchmarks:** [servil-software-factory.github.io/bench-hashes](https://servil-software-factory.github.io/bench-hashes/)
- **Quality & verification overview:** [`QUALITY.md`](../QUALITY.md)
