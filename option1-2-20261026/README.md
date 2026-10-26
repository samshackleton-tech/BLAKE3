# Option 1 (1a/1b) and option 2 on three AVX-512 designs (#125)

- 1a `candidate/sam-wide-off` 9927504: wide kernels off (WIDE=false), tree budget as in the candidate.
- 1b `candidate/sam-wide-off-nobudget` 60f3a00: 1a + tree budget off.
- option 2 `candidate/sam-wide-zen5` 00ca06e: wide kernels on AMD Zen 5 and later only.

Machines: EPYC 9255 (Zen 5, ours), Threadripper PRO 7965WX (Zen 4), 2x Xeon Gold 6330 (Ice Lake); the last two bare metal at Cherry Servers, hourly, deleted after. Per machine: `ba*` = 1b against 1a (check --cells all --pairs 12), `rel1a*`/`rel1b*` = against 07540667, `cli-*.out` = old/1a/1b CLI where run (Ice Lake's rel1b and CLI were stopped once option 2 was chosen). `option2-tests/` = option 2's suites on the EPYC (wide on) and on Ice Lake (wide off). Dual manifests cover this directory except themselves.
