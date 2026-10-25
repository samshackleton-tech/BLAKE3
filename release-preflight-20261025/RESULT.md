# Release preflight — October 25, 2026, 00:31–00:42 UTC

No performance experiments. No tag, release or crate was published. The
final release candidate remains unselected; these are preflight results
on explicitly named review/API branches.

## Review and CI status

John's main remains61b469ce; Devon's API branch remains80f845c.
PR152 (native symbols) and154 (release gates) are open and unmerged.
Their CI runs are completed with `action_required`, not successful:
40142930740 and40145324311. Maintainer approval is needed before supported
Windows CI results can be claimed. No review replies were present in the
fetched snapshot.

## Packaged native-symbol fix: PASS on Linux x86-64

Exact source:3d67a0d75d5a83ff6c2d0f5660e8d3216a3504e4, PR152's review head.
Rust1.99.1, GCC15.2.0, cargo-c0.10.26+cargo-0.100.0 on EPYC9255.

- `cargo package --locked --no-verify` produced a45-file crate. This is
  not a publish dry-run or a full release gate.
- All42 source files in that archive match the exact Git commit.
  Cargo's normalized manifest, lock and VCS metadata are recorded separately;
  VCS metadata names the expected clean source commit.
- An external Rust consumer uses the **extracted archive**, not the Git
  checkout, alongside official blake3 1.8.7. It checks12 lengths (including
  empty, partial blocks/chunks and524289 bytes), unaligned slices, plain/
  keyed/derive-key, single/MT and incremental hashing, XOF seeking across
  output blocks, and6 batch counts. All match official.
- That consumer passes with default features, `pure`, and `serde,zeroize`
  enabled. The latter is a feature-enabled hashing smoke test, not a claim
  that it exercises serialization and zeroization behavior comprehensively.
- The actual packaged-consumer executable has distinct official and servil
  AVX-512 hash-many entries (0x2f740 and0x5b940). The namespace fix therefore
  survives packaging and a downstream mixed-crate build.
- CLI suite:29/29. C API suite:4/4, including fresh cargo-c installations
  and C11/C++11 consumers linked against static and shared libraries.
- Independent suites ran concurrently. Source tree stayed clean.

Cargo warned that repository integration-test files are omitted from the
published crate by its current include list. Those warnings are retained;
this consumer check does not replace repository tests or the release's
full source/proof distribution. Version fields are still the branch's
pre-release fields, not a finalized release version. Native Windows/Mac,
compiler-floor coverage and final tagged-artifact checks remain open.

Artifacts, locks, scripts, compiler versions, payload identity and dual
SHA-256/BLAKE3 digests are in `native-package/`. Installed C artifacts remain
under the server's dedicated cargo target; this record preserves their test
logs. The package job completed00:36:47UTC.

## Batch constructor overflow: reproduced and fixed for review

Devon's API base:80f845c7c83418ded3e3098bc9236044d2a94c5b.

`Batch::new(128, usize::MAX / 2 + 1)` needs two blocks per message. In a
release build, `per * count` wraps to zero, so it returns an empty buffer
with a nonzero logical count. This is a constructor-invariant failure;
no memory-corruption or digest exploit is claimed.

- Test-only negative control:89f9d1ed (full pin in native-overflow).
  It fails in release mode: the constructor did not panic as expected.
- Fix:5bd6d5ae140fbf1ed029227300d47fa0167c5670. A checked multiplication
  rejects the overflow before allocating. A zero-count batch with a very
  large message length still works.
- Exact fixed head:107/107 native tests pass. rustfmt/diff checks pass.
- This changes construction validation, not compression or scheduling.
  It is pending API-owner review, not part of a selected release candidate.

The two commits' combined diff is confined to src/block.rs. Test and fix
are archived separately so the negative result is reproducible. Native
work ended00:38:49UTC; no native build or benchmark remains running.
