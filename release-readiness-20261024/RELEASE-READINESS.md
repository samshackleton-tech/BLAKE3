# Release readiness — optimization freeze, October 24, 2026

Zooko directed us to finish the full-group experiment, then stop optimizing
and prioritize a stable, supported release. It finished at23:48:20UTC and
is excluded:512KiB regressed17.3% after other work and19.4% after idle.
No more performance experiments are scheduled. Regression checks remain
release validation, not a search for faster designs.

Use the existing release tracker **BLAKE3 #125**, not a second process.
The milestone there is0.8; this plan does not silently declare1.0 or its
API stability promise. No release-candidate commit has yet been selected.

## P0 — settle scope and make the gates trustworthy

1. **Freeze one candidate after necessary fixes/review.** John and Devon
   reconcile the already-agreed API work (#146), names (#105), output
   placement, removed APIs and C signatures. Document migrations explicitly.
   There is a concrete scope conflict: #125 lists #90's generated x86
   replacement as required; #90's body says after0.8. Resolve that before
   estimating the release. Do not import GPR150, SIMD141, full-group cuts
   or historical held optimizations to chase benchmark wins.
2. **Native symbol isolation (#151/#152).** Review the small build/FFI fix
   and run the required supported-platform builds. Sam's exact review head
   3d67a0d passes107 Linux x86 native tests; the no-fix co-link control fails.
   Check actual linked entries in shipped artifacts, not just source names.
   Proof inputs remain unchanged, but linkage is part of correctness.
3. **Truthful release evidence (Sam).** Deterministic fixtures reproduce
   two false passes in current tools/release-check.py at61b469c:
   a successful workflow conclusion can stand in for skipped test jobs;
   a Mac changed-cells-only check can satisfy the all-cells release gate.
   CI currently skips substantive jobs on same-repository PRs despite a
   stale comment saying pushes run them; the workflow has no push trigger.
   Require the intended CI jobs and a `type=check,cells=all` Mac result,
   tied to the exact candidate and previous release. Missing, skipped,
   cancelled, timed-out or inconclusive evidence must stay non-green.
   Fixture output in gate-gap-fixtures.json is NOT a real release verdict.
4. **Close correctness/liveness items (John/Devon, Sam cross-review).**
   Review the stream reused-room padding follow-up and #147's deterministic
   lone-task/finish/unwind tests. Update stale #125/#140 status using actual
   merged commits and results. Audit public safe-Rust and C boundaries:
   alignment, lengths, zero padding, overflow, lifetimes and unwinding.
   Release-mode removal of a precondition check must not create UB through
   a safe Rust API. Block::from_bytes currently checks alignment at runtime;
   preserve that safety property.

## P1 — evidence on the frozen candidate

- **Correctness:** reference/test vectors; default, pure, no_std and public
  features; keyed/derive-key/XOF; partial blocks and tails; guard pages;
  initialization/failure behavior; concurrent callers; stream completion,
  panic/unwind and parked workers; CLI and installed C/C++ consumers.
- **Concurrency and memory:** Shuttle models and planted ordering controls;
  full mutation results with every survivor/timeout explained; Miri;
  appropriate sanitizer runs. A timeout is not a proof of a specific bug
  or a pass. Keep tests parallel unless a specific test contract requires
  isolation. Do not replace failed tests with serialization.
- **Proofs (John):** a ledger of shipped kernels, ISA/ABI, input/counter
  ranges, memory and constant-time claims, source/object identities,
  proof results, model cross-checks and mutation controls. Explicitly name
  unproved Rust glue/intrinsics. Bind proof evidence to the compiled
  artifacts; reuse unchanged proofs only with a justified identity mapping.
  The Bob/Lean trust-reduction research is separate unless scope decisions
  or a concrete defect make it necessary for this release.
- **Portability:** the supported matrix currently says x86-64 Linux and
  Windows/MSVC, AArch64 Linux and Apple-Silicon macOS. Exercise supported
  ISA fallback paths, Arm without SME2/SHA-3, and the documented compiler
  floor. Separate native execution, emulator tests, compile-only coverage
  and unsupported targets. Do not infer runtime AVX-512 coverage from a
  CI machine that merely compiles it. State the Rust support policy and
  exact toolchains used; resolve wording that mixes stable support with
  possible nightly requirements.
- **Regression acceptance (Devon + machine owners):** one pinned instrument
  and clocks, exact source/feature/layout records, same intended workloads.
  The previous release's mixed-crate binary can have the same symbol
  collision; an uncorrected baseline is not valid evidence. Use a disclosed,
  verified namespace-only baseline backport or another reviewed isolation
  method. Cross-API `--old-bench` builds do not by themselves establish equal
  workload semantics. Accept any necessary correctness cost explicitly.

## P2 — supported product and release artifacts

- Update README, API docs, QUALITY, quality manual and CHANGELOG to the
  actual candidate. Remove unsupported "never slower" guarantees and
  distinguish kernel proofs from whole-library assurance. Current docs
  contain stale mutation/model descriptions and describe `pure` as no SIMD,
  although today's pure x86 path includes Rust SIMD intrinsics. Check every
  quickstart with visible initialization and real caller contracts.
- Define support contacts, bug/security reporting and maintenance/backport
  expectations; publish an honest support matrix and known limitations.
- Verify packaged Rust crates from clean extracted archives, not only the
  checkout; publish dry runs, licenses/dependencies, CLI behavior and exit
  codes, C headers/pkg-config/static/shared linkage and example consumers.
- Build the final tagged artifacts from recorded toolchains. Record the tag
  commit and version-parent hash distinctly, plus SHA-256 and BLAKE3
  manifests. Smoke-test the actual archives/installations on supported
  systems. Nothing is published until authorized gates/reviews are complete.

## Work order and owners

- **Sam:** archive/reject the last experiment; reproduce and repair false
  release-gate passes; native-link/artifact and x86 compatibility checks;
  evidence bookkeeping and independent review.
- **John:** proposed owner of final release scope/commit and proof ledger,
  Arm/Mac validation and review of152; confirm the allocation with him.
- **Devon:** proposed owner of API/migration closure, pool/mutation evidence,
  benchmark integrity and Intel validation; confirm with him.

Run short tooling controls now. Queue long proof/mutation/full-release
checks for the authorized AFK window; do not start a collection of long
jobs on different candidate commits. Security/correctness failures come
before documentation polish. The native EPYC server is currently idle.

## First release-tool fix prepared

`candidate/sam-release-evidence-gates`, a6b6c1c7c59ad7873ab503bda66fc0298bff9ef4,
implements the CI-job and full-scope Mac checks, removes the obsolete
same-repository PR exclusions, and runs the tool controls in CI. All13
fixture tests pass; the two end-to-end controls fail against the old
checker. CI YAML parses with nine job definitions. This validates the
checker changes, not the release itself; review and real candidate gates
remain open. No library machine code or performance policy changed.
