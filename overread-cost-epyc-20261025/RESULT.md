# #168: the over-read fix's cost on AVX-512 (EPYC 9255)

## Verdict

**No cell slower, in either stage, in two full runs.** On the EPYC
(AVX-512), with servil's own kernels on both sides, the over-read fix
(55b62ad's loads) has no measurable cost. That matches Devon's i7 (AVX2)
result.

## What was compared

- **new:** devonjonte/BLAKE3 `candidate/devon-kernel-names-john`
  `bfbda1920283335ff3802723db11c209159f47fc` (#164's names, fixed loads).
  `check` measured it as its working-tree snapshot `512dd09f304c` (the
  same tree plus the nested, untracked bench checkout).
- **old:** devonjonte/BLAKE3 `exp/devon-overread-unfixed`
  `a137c68fc5cf167cac98ebd54920b218ce10edc1`: the same, with 55b62ad's
  load changes undone. This is a measurement-only control: it was built
  and timed, never tested or offered.
- **bench:** johnservil/bench-hashes `5be5f23699ee7146ada56a08777173a4ee1c7bde`,
  nested in the new side's checkout. Its `Cargo.lock` differs only by the
  local-path patch line.
- **command:** Devon's, run unchanged:
  `cargo run --release -- check --against a137c68 --cells all --pairs 12`.
  Run 2 added `--keep` and nothing else.
- **machine:** AMD EPYC 9255, 48 CPUs, Linux 7.0.0-38, rustc 1.99.1,
  governor `performance`. The bench lock was held, and no other job ran.
  Every kept run's load line reads `quiet`: 0.01–0.03 other CPUs on
  average, at most 0.28 in the busiest window.

## Results

| run | started (UTC) | first stage (12 pairs, 412 cells) | second stage (16 fresh pairs) |
|---|---|---|---|
| 1 | 17:54 | no cell slower; 8 suspects, all mt solo continuous | no cell slower |
| 2 | 18:28 | no cell slower; 8 suspects, all mt shared continuous | no cell slower |

The two runs named different suspects, all multithreaded continuous
cells, none on a path the fix touches. That fits noise near the margin.

Run 1 omitted `--keep`, so only its verdict text is kept; run 2 kept all
its samples. Re-judging run 2's kept samples with the bench's own
`compare` gives the same verdicts. Of 412 cells, all are level.
By group, first stage (geometric mean of the pairs' new/old ratios):

| cells | median | range |
|---|---|---|
| after a pause, batches (all counts, st and mt) | x0.997 | x0.973–x1.007 |
| after a pause, one message (all sizes) | x0.998 | x0.974–x1.004 |
| after a pause, 1.5–8 KiB (trees of 2–7 chunks) | x0.994–x1.003 | |
| lent batches | x1.000 | x0.981–x1.005 |
| warm batches (all counts, solo) | x0.926 | x0.828–x0.999, all level |
| warm one message (solo) | x0.976 | x0.883–x1.002, all level |
| shared continuous messages | x1.011 | x0.995–x1.139, all level |

The warm solo cells lean faster on the fixed side, but so do cells the
fix doesn't touch (one message of 64 B: x0.904). The pairs spread widely
and every verdict is level. **I don't credit the fix with a speedup;**
the reading is "no measurable cost".

The second stage's 16 cells all fall between x0.958 and x1.031, and all
are level.

## Not claimed

- This is not equivalence, and not a judgement about other machines.
- It does not say whether a cheaper sound fix exists (#168's open
  question). It shows only that the current fix costs nothing measurable
  here.

## Failed and incomplete attempts, kept

1. `/root/results/overread-cost-20261025` (16:58): my narrower script,
   with an A/A stage (passed) and then a 12-pair comparison on selected
   points. It stopped at my own time bound at pair 7 of 12. **No
   verdict.** An even earlier attempt failed on a point label (`lent batch
   2` doesn't exist): `/root/results/overread-cost-points-failure`.
2. `failure-identity/` (17:53): `check` aborted before timing, because the
   server had no git identity for its worktree commits. The script now sets
   `GIT_AUTHOR_*`/`GIT_COMMITTER_*`.
3. `run1-nosamples/` (17:54): a full run, kept as text only (no `--keep`).

## Files

- `run2/`: `check.out` and `check.err`, `provenance.txt`, `runner.log`,
  `samples/` (24 first-stage runs plus `second/` 32 runs, with
  `sizes.tsv`), and `compare-first.out` / `compare-second.out` from
  `bench-hashes compare`.
- `run1-nosamples/`: `check.out`, `check.err`, `provenance.txt`,
  `runner.log`.
- `failure-identity/`: logs only.
- `overread-check.sh`: the job script, as used for run 2.
