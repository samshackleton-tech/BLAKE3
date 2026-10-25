# C ABI Miri cases and stream-padding review

See [RESULT.md](RESULT.md) for exact pins, outcomes and limitations.
This is release correctness/review work, not a performance experiment.

`raw-results.tar.gz` preserves:
- the pinned Miri setup/version and unchanged stable-default record;
- initial fixtures, including the invalid first re-entry fixture;
- corrected v2 cases on main and PR157, plus strict-provenance cases;
- native installed C/C++ tests and the permanent context test/control;
- PR158's surviving x86 digest-only control and the improved direct
  padding test, its failing control, native/pure suites and Miri check.

Invalid controls were interpreted, never executed natively. Default Miri
uses experimental Stacked Borrows here. Uninitialized write-only outputs
and the ignored input tail completed in the tested paths: no failure was
reproduced there, and no general initialization/soundness proof is claimed.
The pointer/integer round trip is rejected by strict-provenance mode;
that does not by itself make exposed-provenance Rust an invalid program.

Review source branches on samshackleton-tech/BLAKE3:
- review/sam-stream-padding-contract: c49d335 (test-only follow-up to158).
- candidate/sam-capi-memory-contracts: 2eaa230 (partial155 proposal).
Controls and source bundles are retained. The C ABI output-initialization
question and the proposed support-contract wording still require review.
Dual manifests cover this directory except themselves.
