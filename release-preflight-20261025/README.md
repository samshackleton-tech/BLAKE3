# Linux packaging preflight and Batch constructor review

See RESULT.md for exact source pins, supported scope and open items.
No performance experiments, release tags or uploads to crates.io occurred.

- `package-preflight.tar.gz`: native package/CLI/C tests and extracted-crate
  Rust consumer, locks, source identity, compiler records, and SHA-256/BLAKE3
  artifact digests. The `.crate` and consumer executable are retained;
  the duplicate unpacked source tree is omitted from this archive.
- `overflow-tests.tar.gz`: passing API fix and failing release-mode
  constructor control, with exact source commits.
- `scripts/`: the exact preflight programs, with machine-local paths.
- `batch-overflow.bundle`: test/control and fix commits based on Devon80f845c;
  candidate5bd6d5a is for API-owner review, not a chosen release candidate.
- `capi-review.md`: source-level questions about output initialization,
  aliasing, callbacks and raw-memory contract wording. These are review
  findings, not a reproduced memory-corruption claim or a Miri result.

PR152/154 CI awaited maintainer approval in the recorded snapshot; Linux
success is not Windows/macOS coverage. Final candidate/tagged-artifact
validation and contract closure remain necessary. Dual manifests cover
this directory except themselves.
