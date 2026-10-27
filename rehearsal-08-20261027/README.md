# Rehearsal of 0.8's release runs, six x86 machines (October 27, BLAKE3 #125)

Stand-ins for John's measured commit and bench 0.18: library = #195's head 4fa4d555 (devonjonte candidate/devon-no-portable);
bench = samshackleton-tech/bench-hashes measure/bench87-names (9eb9f14: #87 + John's candidate/names; 72b90f9: + bench-hashes #90's fix).
Machines as in ../release-08-x86-20261027. Governor performance on all.

Per machine, `rehearsal-4fa4d55/`: host-08c.sh: suites at 4fa4d555, John's release check with 9eb9f14 (exit 2 everywhere:
the old bench 5be5f236 rejects the merged sizes file's new cells; bench-hashes #90), the full `--all` run of the release commit.
`rehearsal-4fa4d55/release-fixed/` (EPYC: `fixtest-72b90f9/`): John's exact release check with 72b90f9, both stages, verdict.
EPYC only: `split-15/` A = same library (4fa4d555) both sides, old bench 3f9edd1 (John's candidate/names, before #87), new 72b90f9;
B = bfbda192 + 5be5f236 against 4fa4d555 + 3f9edd1. `diag-256/`: mt ContinuousMessages 256 B alone and after other points, two
processes each (bistable 0.19 / 0.30 ns/B). EPYC's b3sum rehearsal results are not here (98 MB; kept on the machine).
Samples in *.tar.xz. Dual manifests cover this directory except themselves.

**Correction (October 27, 20:50; Devon on #125):** every `rehearsal-4fa4d55/full.out` here measured the
bench's pinned servil (0.3.0+2e4fa821, commit 49b43b1d), not 4fa4d555: the full runs were built with a
`--config` patch that Cargo left unused (the lock pins 0.3.0; the fork is 0.8.0). They are not runs of
4fa4d555. The checks are unaffected (check builds its sides with build-against). The release full runs at
934dee89 were redone with `bench-hashes build-against ..` and verified (bench-hashes data/2026-10-27/release-0.8-x86).
