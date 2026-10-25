# #152 performance double-check on EPYC — October 25, 2026

## Conclusion

The bounded EPYC regression screens **did not reproduce a slowdown from
#152**. This does not contradict Devon's finding that older mixed-crate
measurements could credit servil with official's batch kernels. Those are
separate questions:

- **#152 itself:** no cell was judged slower in the first-stage comparison
  or the targeted suspect recheck on this machine.
- **Older mixed-binary measurements:** the parent's symbol collision means
  its servil calls could run official's kernels. A comparison against that
  parent measures the effect of correcting linkage as well as the symbol
  rename. It is not a pure measurement of symbol-renaming overhead.

No claim of exact equivalence, universal absence of regressions, or a
regression-free release is made. #164's broader source/proof rename is
still the reviewed replacement for #152.

## Exact setup

- Parent: `61b469ce88cec441859e7e6d698473acc9ddc929`.
- Candidate: `3d67a0d75d5a83ff6c2d0f5660e8d3216a3504e4` (#152).
- Benchmark: `d6ce88f6537a7fbd11ab9533853818b4adaf4824` on
  johnservil/bench-hashes `main`; its pinned clocks revision is
  `b94e2fac72b8be346e8c012c6a749caa134e2480`.
- EPYC 9255, quiet native runs, existing `regress`/`compare` timing and
  statistics. No custom timing loops or statistics.
- Parent tests: 106/106; candidate tests: 107/107.

## Results

1. **Independent A/A control:** four pairs, no slower verdict.
2. **Targeted #152 comparison:** eight pairs, four fresh link layouts per
   side. `regress: no cell slower`. The tool named eight level-but-slow
   suspects; those were not silently discarded.
3. **Full project `check`:** the first stage also said no cell slower and
   named eight suspects. Its second-stage artifact set is incomplete: the
   retained layout directory has only part of the fresh layouts and no
   second-stage sample directory. I therefore treat that full check as
   **unresolved**, not as a completed pass.
4. **Targeted suspect recheck:** the eight full-check suspects were run
   with `regress --judge` over eight pairs, using the corrected point
   labels. **No cell slower**, and no remaining suspects in the output.
   The 16 samples' load lines were quiet (up to 0.04 other CPUs in the
   busiest window). This is a bounded targeted recheck, not a substitute
   for the full 16-fresh-layout release gate.

Examples of retained means, all level rather than a slowdown verdict:
`ManyMessages|16` ST +4.4%, `IdleManyMessages|16` ST +5.6%, MT +6.1%.
The A/A control itself had `ManyMessages|16` +12.2% at level, showing why
positive means alone are not a finding. Other cells moved in the opposite
direction; no cells were removed for being positive or negative.

## Native-linkage interpretation

The actual candidate binary contains distinct
`blake3_hash_many_avx512` and `blake3_servil_hash_many_avx512` entries.
The parent binary has only the shared upstream entry. This confirms that
#152 changes which native implementation servil reaches in a mixed binary.
The parent can therefore show official's wide remainder loads while the
candidate reaches servil's narrowed loads. Any performance difference must
be explained with that linkage change in view; the symbol names alone do
not account for it.

The source change's build-time renaming does not add a runtime dispatch or
new kernel policy. The native audit was performed on the real executables,
not inferred from the Rust source.

## Failed/setup attempts retained

- First build used a non-nested benchmark checkout; the build correctly
  required the enclosing library checkout. No timing was collected.
- The first binary-audit script kept only the first character of symbol
  addresses. It was corrected before the benchmark ran.
- The full check initially lacked Git identity for its temporary worktree;
  it was rerun with the correct Sam identity.
- The first suspect recheck selected one-message rather than
  `ContinuousMessages` points, and the tool rejected the incomplete judge
  set. Corrected point labels were used for the final recheck.

Raw samples, full-check logs, layout orders, symbol tables, binary hashes,
scripts and the first failure directories are retained under `native/` and
the sibling `*-failure` result directories. No performance experiment was
used to change the release candidate, and no public tag or crate was
published. Native work ended with the targeted recheck at 16:28:58 UTC.
