# Current-source EPYC integration, October 24, 2026

Unreleased evaluation, not a new benchmark release or an overview update.

**Superseding finding: native-symbol collision (#151).** The first three
maps used an executable in which official and servil shared upstream's
native AVX-512 entry. They and the interrupted first SIMD comparison are
provisional. Source headers and a passing A/A did not detect the collision.
The corrected integration is `ce93dbf139032016b74bb2354f3f1be3538ddfa1`,
with independent inherited x86 symbols; its three maps are under
`private-symbols/map-{0,1,2}`. All finished quietly by 23:22:16 UTC.
The standalone fix on John's main is PR #152, review head
`3d67a0d75d5a83ff6c2d0f5660e8d3216a3504e4` (107/107 native tests).
The co-linking negative control fails as required; the API-stack fix passes
106 default, 85 pure-library, 33 no-std-library and 48 benchmark tests.
The corrected SIMD candidate is `0584cbe29f9992c1ebea443be35bfa4efed2417b`;
its repeated A/A and comparison live under `private-symbols/simd-screen`.

## Sources

- John library `61b469ce88cec441859e7e6d698473acc9ddc929`.
- Devon library `api/two-kinds`, `80f845c7c83418ded3e3098bc9236044d2a94c5b`.
- Combined library `f31ad2fdc668110f68320ed3b3c09f69c72983ab`.
  Merge retains Devon's aborting self-test and adapted tests, mutation paths
  moved to incremental.rs and removal of outboard, and leftover-worktree test.
  John's lazy aligned ring and its assertions are adapted to Block inputs.
  John's named release logs and jobs.py are present. tools/verify and c2sp
  are identical between the inputs and untouched by this integration.
- Devon benchmark `bench/api-two-kinds`,
  `9dddb605c7b39c9b49ad85ac58fd983333f32548`, plus clocks provenance #73
  and Devon's ManyLongMessages change `97600d4bfefa8d0194685c961d30e1273f0c860c`,
  adapted to the new API and frozen-contract table. Combined benchmark:
  `0d38c5f1c4a738ef05d9baf3699f9dd8467970da`.
- Clocks patched explicitly to reviewed #142
  `d6671f57483b7e4626d5415b8242fd67b8dbaab0`. It retains the shared mean,
  native-cycle sampler and statistics. Linux load uses direct other-process
  accounting, with the PID-namespace visibility fallback. This is a
  disclosed unmerged instrument patch, not the released clocks pin.
- Official contender: Cargo.lock's blake3 1.8.7, default features off,
  std and rayon enabled. No dependency update was requested.

All final samples name their actual library, benchmark, clocks and lock.
The package version string still names 0.17.0; these next-release API,
alignment and long-batch changes make the snapshot different from released
0.17.0. Do not pool their results.

## Validation and first failure

Native initial library unit tests: 86/86; benchmark: 48/48; clocks: 37/37
(5 skipped). Test suites were launched independently; benchmark runs wait
until all tests/builds end. Full library integration tests follow in the
candidate screen.

The first smoke's provenance assertion stopped the benchmark job: John's
jobs.py put its runtime PID/log files in the measured library's untracked
`tmp/jobs/`, which the provenance reader correctly counted as dirty. The
failed smoke and its executable are retained under `provenance-failure/`.
Move runtime job state outside the measured checkout, rebuild, rerun tests
and smoke, and require all three source records clean. No source file was
hidden or ignored to make the assertion pass.

## Baseline

Three 96-round full-size maps on all 48 CPUs, with separately linked
layouts L0/L1/L2, official st/mt and servil st/mt. Maps finished
23:05:00, 23:06:00 and 23:07:01 UTC. Each preserves its raw samples, wall
and available thread-cycle counts, load windows and provenance.

These maps locate suspects. They are not a paired cross-algorithm
regression verdict. Known EPYC core-state sensitivity remains relevant.
Read wall time as measured; short-cell cycles/ns is not a frequency proof.

## Candidate screen

Library `d3a21a40` imports draft #141's final SIMD root kernel and frame
separation (d3e3cbe), adapting only the context-key test call to the new
performance module. Assembly and generator output match #141 exactly.
No GPR kernel, pointer-picking variant or CPU-model policy is added.

The bounded screen uses four layouts per side, an A/A control (four
pairs), then eight comparison pairs if A/A permits it. Points cover
64 B–1 KiB after work/idle and warm calls, 1536 B and 4 KiB boundaries,
512 KiB/1 MiB controls and a 16-message stream batch. Existing regress and
compare own timing and statistics. It is scoped, not a full adoption gate.

## Scope kept explicit

The new API branch returns Hash by value from performance::hash and
hash_multithreaded. It is not the earlier experimental final-output API
or the generated-input/direct-digest workload. Those experimental results
remain separate, including the GPR after-work regressions.

Open PRs with independent experiments are not indiscriminately merged.
The GPR draft remains review-only; the formal-proof/mutation jobs and
broader native gates still belong to the coordinated AFK queue.
