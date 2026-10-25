# Release mechanics rehearsal — NOT a release candidate

[RESULT.md](RESULT.md) records the checks and remaining blockers.
No public tag or crate was published. The version/tag operations occurred
only in an isolated clone with a disabled push URL; production tag refs
were checked unchanged. No performance experiments ran.

- `native-rehearsal.tar.gz`: version-only diff and metadata, original and
  corrected baseline selection, individual and paired package dry-runs,
  version-stamped installed C/C++ tests, staged `.crate` archives and their
  exact checksum relationship, source-clean/tag-ref controls and failures.
  The private source checkout is omitted. Its version commit is preserved
  in `rehearsal-version.bundle` inside the archive, requiring public parent
  3d67a0d; the bundle does not export a release-tag ref.
- `scripts/`: exact machine-local rehearsal and verification programs.
- `gate-tests-final.log`:22 passing release-tool controls on proposed head
  e19aadc2b2596912ee7295d2cf5717e762090786, PR154's branch.
- Negative controls: the older checker mishandles tagged/unrelated-tag
  histories, accepts PR-merge evidence and ignores unresolved mutation
  timeout differences. These are synthetic/isolated tool tests, not real
  CI, proof or mutation-campaign verdicts.

The standalone CLI dry-run failure and initial artifact-collector path
error are retained. Cargo's paired dry-run succeeds without an upload;
its CLI lock identifies the exact staged library archive. These rehearsal
artifacts must not be mistaken for an approved production release.
