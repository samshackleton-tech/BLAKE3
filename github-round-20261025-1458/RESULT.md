# GitHub round — October 25, 2026, 14:58–15:20 UTC

Optimization remains frozen. This round reviewed new upstream work and
performed release correctness/proof/integration checks. No new speed
experiments, public release tags or crate uploads occurred.

## New upstream state

- John main: `7213223d9449040e8701c48ef3b777e89539d4a4`.
- PR157 (two kinds API): `b012dc1f33bfe44a138ca65b3c69cadc683e898b`.
  It now documents unspecified stream-room contents and removes the
  sanitizer claims that were not being run.
- PR164: `bfbda1920283335ff3802723db11c209159f47fc`; source/proof-wide
  `blake3_servil_` symbol naming, superseding #152.
- PR166: `f4f530eb304285ba261f9b94bfb09d2dbb524892`; AVX-512 XOF split at
  32 blocks and `pair.rs`'s incrementing-counter shape proved.
- #161 is decided: document unspecified initial stream-room contents,
  no clearing. #160 Win32 and #162 Fil-C are outside 0.8.
- #163 is being resolved by completing the proof coverage; #165 remains a
  fallback documentation draft.
- #125 is on hold for the after-a-pause slowdown in the larger integration,
  with cold-state and speed-state evidence still being investigated by Devon.

## PR166 / PR164 EPYC validation

Exact PR166 head `f4f530eb`, which includes #164:

| Check | Result |
|---|---|
| Default library | **108/108** |
| Pure library | **106/106** |
| no_std | **33/33** |
| C API | **4/4** |
| Doc tests | **22/22** |
| Proof helper tests | **34/34** |

The checked-in `.S`/`.asm` files contain 198 exported names; all carry
`blake3_servil_`. The source/proof naming test and co-linking test are in
this suite. This validates #164's broader approach; #152 was closed as
superseded, with its commit retained in #164's history.

Selected proofs using the repository's existing proof engine, not a full
campaign:

- AVX2 and AVX-512 `hash_many`, two inputs at consecutive counters, 15
  blocks, every entry-stack alignment;
- AVX-512 `xof_many` at 1 and 32 blocks, every entry-stack alignment.

The 33-block XOF case was not asserted as a single proved kernel call:
production splits it. Native tests already exercise 32, 33, 64, 65 and
100 output blocks. No full representative/long proof campaign is claimed.

## Unified C contract tests

Devon's new `contracts.rs` and the Miri-driven `guards.rs` duplicated the
C contract inventory. Integration branch
`integration/sam-capi-contract-list`, exact head
`4676382afb07a2f982e9ca5b5860e9538b077a9c`, based on the latest PR157:

- one shared case inventory and broken-call implementations in
  `capi/tests/guards.rs`;
- native child-process runner and Miri driver consume the same inventory;
  `contracts.rs` is removed;
- old contract cases retained alongside overlap, overflow, alignment and
  rounded-stream cases; current checked-range diagnostics are used;
- Batch block-count overflow rejection and latest guard-page callback
  adaptation included;
- no output zeroing or new tracking/synchronization mechanism.

Results on EPYC: **8/8 native C API**, **107/107 native library**, and
**33 interpreted malformed calls** with intended diagnostics and no Miri UB.
Earlier failures in this integration are retained: the new guard-page
callback needed `Some`, the oversized-batch expected message was corrected,
and an initial test script's source pin failed before running. No final RC
or release-check PASS is claimed. The branch is for the C/API owners to
rebase/take; PR159 itself was not rewritten to a new base.

## Handoff actions

- Posted PR166 EPYC/proof results: comment 6399433723.
- Posted #164 review and closed #152 as superseded: comments 6399433932
  and PR state closed.
- Posted unified C test integration on #159: comment 6399434188.
- #161's document-only decision is reflected in the current PR157 source.
- #160/#162 remain out of scope; no implementation work was started.

## Remaining release blockers

- #125's after-a-pause investigation and its acceptance decision.
- Final proof/mutation campaigns and supported-platform validation.
- C ABI output-initialization contract (#155), independent of the passing
  write-only Miri cases.
- Final API/RC scope and human review. #165 is only a fallback if the
  stronger proof claim cannot be completed in time.

The selected proof results and native tests are not a full release gate.
The server was idle after the C list checks; no native benchmark or long
job was left running. Raw logs and source bundles are in this round's
`native/` and `scripts/` directories.
