# Release mechanics rehearsal and gate audit — October 25, 2026

**Rehearsal only. No release, public tag or crates.io upload occurred.**
No performance experiments were run. The final RC and API scope remain
unselected; C ABI review #155 and platform/review approvals remain open.

## Version stamping: passed in an isolated clone

Starting from review head3d67a0d75d5a83ff6c2d0f5660e8d3216a3504e4, an
independent private clone ran the actual `tools/gen-ver.py 0.8.0`.
Its push URL was disabled. Production tag refs were compared before/after
and remained identical.

- Local rehearsal version commit:4b2f77be1d179edf94756fd21d63a4e7dc385bf7.
- Local-only tag/version:0.8.0+3d67a0d75d5a83ff6c2d0f5660e8d3216a3504e4.
- All six expected version files changed, and no other tracked files.
- Root crate, CLI, exact CLI dependency requirement, C crate/header and
  CHANGELOG agree. The CLI lock changed only the two package versions.
- The embedded hash identifies the code parent; the tag identifies the
  version commit. Those are distinct and both must be recorded.

## Dry-runs and C artifacts

- Root `cargo publish --dry-run`: passed, verification build included.
- Independent CLI dry-run: blocked (exit101), because blake3-servil is not
  yet present in crates.io. Requiring this before the first library upload
  makes the old procedure impossible to finish as written.
- Version-stamped C API:4/4 tests pass, including installed static/shared
  C11/C++11 consumers and full version-string/pkg-config checks.
- Cargo's paired-package dry-run in a temporary parent workspace: passed
  for **both** blake3-servil and b3sums, without changing the candidate's
  manifests or Git tree. The explicit package list avoids publishing other
  workspace/path dependencies.
- The CLI archive's lock names the **SHA-256 of the exact library archive**
  staged in that run. Both archives name the expected version commit and
  full version. SHA-256 and BLAKE3 manifests are retained.

The first paired dry-run itself passed, but my evidence collector assumed
flat `package/*.crate` output. Cargo's multi-package publication stages them
under `package/tmp-crate/`; the collector failed. Its logs are retained.
The corrected procedure was rerun start-to-finish, then verified the
archives and unchanged source/production tags. Nothing was uploaded in
any attempt; Cargo's “Uploading” progress line was followed by “aborting
upload due to dry run.” Native work ended01:34:49UTC.

## Release checker: further gaps fixed in PR154's branch

Final proposed head:e19aadc2b2596912ee7295d2cf5717e762090786.
All22 controls pass. No library, compression, scheduling or proof sources
were changed.

1. **Wrong previous release.** The old global date-sorted tag selection
   picks the newly created candidate tag as its own baseline. The real
   rehearsal reproduced this. It can also select an unrelated branch's
   newer tag. The new selector takes the nearest reachable earlier tag,
   excludes tags on the candidate and follows both parents of merges.
   Real-Git end-to-end controls fail against the previous checker. The
   repaired selector also chooses the actual0.3 tag on the rehearsal clone.
2. **PR head SHA versus checked-out merge.** PR workflows normally check
   a synthetic merge, despite the API's head-SHA label. Release evidence
   now requires direct workflow_dispatch on the candidate; PR CI still
   serves review. The planted PR-only evidence passes the previous checker
   and is OPEN under the fix. This is an identity requirement, not a claim
   that our particular pending PR run tested a different tree.
3. **Mutation timeout outcome ignored.** check.py can print successful
   survivors, then report changed timeout outcomes and exit2. The old gate
   saw “each known and explained” and passed it. The reader now checks both
   existing final summaries: changed timeouts remain NO VERDICT, a survivor
   failure is FAIL, and incomplete output stays OPEN. The negative control
   uses the real log reader, not a mocked success result. No full mutation
   campaign was run or claimed to pass.

The earlier fixes for skipped CI jobs and changed-cells-only Mac checks
remain. The release instructions now stamp the version before collecting
final commit-keyed evidence, keep the tag unpublished, require exact-source
CI, and describe the verified paired package procedure. Reused proof inputs
need an explicit identity justification, not renamed old logs.

These controls validate tooling and the rehearsal mechanism. They are not
a real release-check PASS and do not authorize publishing these rehearsal
artifacts. CI approvals, C ABI contracts, proofs/reviews and the final
supported-platform matrix still need closure on the chosen candidate.
