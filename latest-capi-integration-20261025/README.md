# Latest two-kinds C integration and release review

See RESULT.md for exact source pins, tests and remaining blockers.
This is release correctness/review work; no performance experiment or
release publication occurred.

`raw-results.tar.gz` contains the final native and interpreted results,
full strict-provenance C vector logs, the integrated build/doc suites,
source pins, and the retained earlier callback/ordering/exit-status
failures. `scripts/` contains the collection/check programs and source
bundles used for the local integration.

The final local review integration is
`96f017bc190e867c22d176a330da644bdf32ce3f`, branch
`integration/sam-release-candidate-review` on samshackleton-tech/BLAKE3.
It combines PR157/e3013b1, the padding fix, simple C guards, Batch
block-count overflow rejection and native x86 symbol isolation. It is a
review integration, not an approved release candidate.

The latest C guard branch is `07c245e712297d6eb6c39ebddffc3d20470eabc1`.
Its C API source is identical to the integration's, so its full strict-Miri
C vector result (2/2, large case1160.117s) maps explicitly to that C API.
The integrated native library, pure-library, C API, build and doc suites
are independently recorded. No proof campaign or Windows/macOS run is
claimed. Output initialization #155, recycled-room contents #161,
proof-scope documentation #163 and final scope/approvals remain open.

Dual manifests cover this directory except themselves.
