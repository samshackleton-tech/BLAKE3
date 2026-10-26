# The 32-input AVX-512 kernel on the 0.8 candidate, EPYC 9255 (#125)

**Open [`view/wide-kernel-epyc.html`](view/wide-kernel-epyc.html)** (download it; GitHub doesn't render HTML). It has the comparison, the pros and cons table, and every chart. Quick views:
[`view/wide-kernel-epyc-top.png`](view/wide-kernel-epyc-top.png) (summary, pros and cons, CLI) and
[`view/wide-kernel-epyc-charts.png`](view/wide-kernel-epyc-charts.png) (the charts, old dashed, new solid).

- old `a9e70b8`: John's `candidate/release-0.8` 0754066 + Devon's FANOUT 8 (485d7ab)
- new `a49ff2c` (`experiment/sam-wide-on-0.8`): old + the 32-input AVX-512 chunk kernel, its 16-input parent kernel and its tree-thread budget, ported from a5e1e18
- ablation `433502a` (`experiment/sam-wide-kernel-only`): new without the tree budget (measurement only)

`data/` holds every log and kept sample: suites, the same-code control, two library checks, the ablation, five CLI runs (one busy, kept), SMT and energy. `scripts/` holds the job scripts as run and the report generator. Dual manifests cover this directory except themselves.
