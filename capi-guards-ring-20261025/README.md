# Simple C guards and recycled stream-room exposure

See [RESULT.md](RESULT.md) for exact pins and limitations.

`raw-results.tar.gz` retains native and interpreted guard checks,
removed-guard controls (interpreted only), the full strict-provenance C
vector run, source pins, failed harness/record attempts, and the safe-Rust
ring-reuse probe on main and the two-kinds API.

The guard checks validate simple pre-borrow diagnostics on the tested
paths. The ring result is functional behavior with dummy data: a later
sequential caller can inspect prior bytes before overwriting its room.
It is not a memory-safety, concurrency or cross-process finding.

Review branches on samshackleton-tech/BLAKE3:
- candidate/sam-capi-memory-contracts: dc37f57 (draft PR159 follow-up).
- control/sam-capi-guards-removed: aee0baa (Miri-only mutation controls).

No performance experiment, release tag or crate upload is included.
Dual manifests cover this directory except themselves.
