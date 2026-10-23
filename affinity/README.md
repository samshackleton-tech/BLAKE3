# Historical v6 fixed-affinity diagnostic

These focused comparisons use the same 61afea44/99d34d9 corrected-trim instrument as the main historical evidence. They do not substitute for fresh v7 runs, the full-cell gate, or a second CPU.

Each configuration compares sixteen existing independent layouts per side, original baseline versus either the wide-group candidate (`605b1035baba…`, full commit in `sources.txt`) or the retained-kernel pooled-group checkpoint (`215441f3f1c327e00869538eeced3ad90ec46dea`). The existing regress command measures 1 MiB and 64 MiB outboards. Its printed summaries, verdicts, CPU sets, source IDs and topology are retained here; the raw samples remain on the server.

## Solo outboard 64 MiB

Ratios are candidate/original. Wall ratios use the pinned estimator; CPU-time ratios are the instrument's reported process CPU-time ratios, with no statistical verdict.

| Physical cores / participants | Wide wall | Wide CPU time | Retained-kernel wall | Retained-kernel CPU time |
|---|---:|---:|---:|---:|
| 12 / 12, one sibling each | 0.961 | 0.864 | 1.016 | 0.988 |
| 12 / 24, both siblings | 1.008 | 1.110 | 1.000 | 0.997 |
| 24 / 24, one sibling each | 0.979 | 0.892 | 0.998 | 0.980 |
| 24 / 48, both siblings | 1.013 | 1.117 | 0.991 | 0.995 |

The wide kernel's CPU-time estimate falls with one participant per physical core and rises with both siblings active, at both physical-core counts. This supports a contention hypothesis. The experiment does not identify a particular micro-operation or prove that memory operands cause the difference: participant count also changes scheduling and partitioning.

The half-core configurations choose even primary CPU IDs, spread across all four last-level-cache groups. A primary CPU's sibling is its ID +24. Each pair uses the same affinity on both sides. All eight focused checks exit 0; only the wide 12/12 solo 64 MiB row is labelled faster among the wall ratios in this table. The remaining table rows are level, including positive ratios. The earlier full-run +3.1% failure remains part of the record.
