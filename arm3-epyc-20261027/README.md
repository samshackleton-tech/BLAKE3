# hash_four_at_a_time's arm 3 on the EPYC 9255 (BLAKE3 #183)

Devon's probe (devonjonte/bench-hashes data 2026-10-27/arm3-i7: arm3_probe.rs, delete.diff, whole.diff, unchanged)
on an AVX-512 machine with the wide kernels on. Builds at devonjonte candidate/devon-no-portable 8769d4b3:
keep, delete (arm 3 deleted), whole (every lane to the platform's hash_many) (build_epyc.sh).
run_epyc.py = Devon's run.py with AMD's events (instructions:u, cycles:u) and these paths; pinned to CPU 2,
5 rounds rotating the builds. Output: run.stdout.txt.
