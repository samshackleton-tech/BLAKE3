# x86 items at d34af741 (BLAKE3 #125) on the EPYC 9255, AVX-512 with the wide kernels on

runs/x86-d34af741-*: suites (all status 0); John's check against 83d59db, old bench 2c9633ae, bench 0.18.3 f17a161b nested (no cell slower, both stages); check.py and --write (the list it writes equals #207's row for row, apart from assert_slots's reason). runs/x86-list-207-*: check.py at #207's head 877f5146: exit 0. All via pinned-run.
- runs/x86-list-85868fc9-*: check.py / --write at 85868fc9 (assert_slots a debug check): 193 same code, assert_slots UNCLASSIFIED.
- runs/x86-list-58381c42-*: at 58381c42 (the length check in every build again, with its test): check.py exits 0 (629 / 31); --write's list equals #207's merged list (50e7ba1) row for row (454 rows).
- runs/final-e77fc67-*: the version commit 0.8.0+302bae15 (e77fc67): suites all pass, check.py exits 0 (629 / 31).
