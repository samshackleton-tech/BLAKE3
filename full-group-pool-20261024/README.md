# Full-SIMD-group pool pieces: do not adopt

[RESULT.md](RESULT.md) records the completed experiment: gains around4–6%
in several cells, but512KiB regresses17.3% after work and19.4% after idle.
The user directed optimization work to stop after this experiment.

`raw-results.tar.gz` contains all samples, comparisons, controls, test logs,
layout orders and executable digests. Eight distinct layouts per side were
used in eight comparison pairs. The baseline layout bank is preserved in
../native-symbols-20261024/raw-results.tar.gz. Executables remain on EPYC.
`sources.bundle` contains the candidate and its planted negative control,
with ce93dbf as the prerequisite. Both source branches are archived in
samshackleton-tech/BLAKE3. No release or production default includes them.
