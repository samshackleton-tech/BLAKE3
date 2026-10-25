# GitHub round, October 25, 2026

[RESULT.md](RESULT.md) summarizes the new upstream state and the actions
taken. This is release correctness/proof/review evidence, not an RC or a
performance result.

`native/` contains PR166/164 native suites, selected existing-engine proof
logs, the consolidated C contract-list suites and their retained failures.
`scripts/` contains the exact collection/check scripts and source bundle.
All source pins and test counts are in RESULT.md.

Actions: #152 closed as superseded by #164; #166 and #164 results posted;
#159's duplicate C contract lists consolidated on
`integration/sam-capi-contract-list` at4676382. #161 is document-only;
#160/#162 are out of0.8; #125 remains on hold for the cold-path investigation.

No full representative/long proof campaign, Windows/macOS run, release tag,
crate upload or new performance experiment is claimed. Dual manifests cover
this directory except themselves.
