# #152 EPYC performance double-check

[RESULT.md](RESULT.md) records exact sources, benchmark, clocks, verdicts,
native-linkage interpretation and retained setup failures.

The bounded first-stage comparison and targeted suspect recheck found no
slower cell. The full project check's second-stage layout/sample set was
incomplete, so that full check is explicitly unresolved. This is not a
claim of exact equivalence or a completed release gate.

`native/` contains raw samples, comparison outputs, symbol tables and
initial executables, plus the incomplete full-check artifacts and failed
setup attempts. `benchmark.sh`, `check.sh` and `suspects.sh` are the exact
collection scripts. No performance experiment, release tag or crate upload
is included. Dual manifests cover this directory except themselves.
