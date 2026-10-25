# Full-group pool experiment — completed, excluded from release

User directed optimization work to stop after this experiment. No further
performance experiments are scheduled. Native work ended23:48:20UTC,
October24,2026; the server is idle.

## Sources and scope

- Baseline: ce93dbf139032016b74bb2354f3f1be3538ddfa1 (current API integration
  with isolated native symbols).
- Candidate: 3d2c625e777cf6d15a7821465ae31f215e7cf397.
- Negative control: 7fda24046846f8586c2981d72a721bd442c65c63.
- Benchmark: 0d38c5f1c4a738ef05d9baf3699f9dd8467970da.
- Clocks: d6671f57483b7e4626d5415b8242fd67b8dbaab0, explicitly recorded.

The candidate increases only AVX-512 pool-tree pieces' minimum from8KiB
to16KiB; other platforms, batches and collections keep their floor.
The merger starts at the smallest whole piece so the larger floor does
not leave an empty merge level. No GPR or SIMD-root draft is included.

Tests of the actual cutter show, at48threads:

| Input | Old pieces | Candidate pieces |
|---|---:|---:|
|512KiB|64 (all8KiB)|32 (all16KiB)|
|1MiB|111|64|
|2MiB|158|111|
|8MiB|252|205|

This changes both kernel grouping and available task parallelism. The
measurements do not isolate which mechanism causes each gain or loss.

## Correctness

108/108 native tests pass, with new cut/merge checks for odd final pieces
and thread counts through96. The floor-removal control fails as required
(63pieces instead of32 at512KiB/48threads; nextest exit100). Pure and
benchmark suite logs are retained. Co-linking symbol isolation is checked.
These tests are not a formal proof or cross-platform performance evidence.

## Timing

Eight distinct candidate layouts and all eight layouts of the existing
baseline bank, each used once in the eight comparison pairs. A four-pair
A/A precedes them; existing bench-hashes regress/compare judges44cells.
The A/A produced no slower labels, but positive means remain visible,
including+3.8% at MT512KiB after idle. Level is not equivalence.

Selected MT results, changes in elapsed time:

| Workload | Change | Existing compare verdict |
|---|---:|---|
|512KiB after other work|**+17.3%**|slower;8/8pairs slower|
|512KiB after idle|**+19.4%**|slower;7/8pairs slower|
|1MiB after other work|−5.5%|faster;8/8|
|2MiB after other work|−4.7%|faster;8/8|
|2MiB after idle|−5.2%|faster;8/8|
|8MiB after idle|−4.9%|faster;8/8|
|4MiB warm lent, solo|−3.7%|faster;8/8|
|1MiB warm lent, two callers|−6.3%|faster;8/8|
|4MiB warm lent, two callers|−4.1%|faster;8/8|

ST controls are labelled level. All cells, positive means, raw samples,
layout orders, source records and executable hashes are retained under
`native/`; the benchmark reports wall time and available native counts.
No custom timing or statistical implementation was used.

Regress exits1: two cells slower. The orchestration exits0 because it
completed and preserved that result, not because the candidate passed.

## Decision

**Do not adopt.** The larger floor worsens the very split-boundary case it
was meant to improve. Modest gains elsewhere do not justify shipping
these regressions or adding tuning exceptions before a stable release.
Keep the existing pool behavior. Archive the branch and stop optimization.
