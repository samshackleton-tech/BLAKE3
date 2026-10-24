# x86-64 one-chunk root kernel: evidence (EPYC 9255)

Change: `samshackleton-tech/BLAKE3` `candidate/sam-x86-chunk-root` `cba5f240b875b187412c7b3be6b9dab099e3f5bb` (tree `bd9af8ecf6cf927f47d639c3ad9e3b5449ae2e27`), on `servil` `b94e2fac72b8be346e8c012c6a749caa134e2480`. Serialized native work; no local builds.

- `check-main/`: `bench-hashes check --cells all --pairs 8` against `b94e2fa` on bench `main` `e3cfbd1`: no cell slower, 18 faster (64 B −10% to −14%, 128 B −8% to −10%, 256 B −4% to −7%, 512 B and 1 KiB −4%). An earlier run on bench `aedc061` (#67) agreed: none slower, 24 faster.
- `maps/`: offset maps (`tools/offset_check.py --map`, `setarch -R`, three repeats, bench `aedc061`), base against fix. Shared 64 B: four 64-byte thread-stack positions at up to 1.39–1.54 ns/B become flat at 0.94. Main-stack positions at up to 1.45–1.52 (12 of 256) become flat. `summary.txt` reads them per axis.
- `mechanism/`: duo threads' `ls_bad_status2.stli_other` per 1k instructions, 5.5–8.7 (base, at neutral and worst offsets) against 0.10–0.11 (fix, at all three); IPC 1.54–1.86 against 1.97–2.01. The structural test fails on a planted `push`/`pop` (`negative.log`) and passes again restored.
- Not addressed here: a heap-layout state that sets solo 64 B and 256 B fast or slow in both builds alike (e.g. base solo 64 B 1.04 or 1.38 with `glibc.malloc.tcache_count=1`); it does not follow our stack.
