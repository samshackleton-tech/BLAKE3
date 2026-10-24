# Solo ManyMessages: a per-process state, about 1.6×, set by where the process may run

AMD EPYC 9255 (4 CCDs: L3 0 = CPUs 0–5 and 24–29, L3 2 = 6–11 and 30–35, …),
Ubuntu 26.04. October 24, 2026, 11:45–12:30 UTC. All runs are
`--contenders blake3-servil-st --points 64[,256] --for-regression-check --rounds 24`.
The binary is servil b94e2fa with bench #67 plus `diag-align64` (buffers aligned,
so #65's windows are absent), unless noted. These are diagnostics, not speed
verdicts.

**Solo ManyMessages|64, in ns per message:**

| How the process may run | Per-process means | Slow (≥ 33) |
|---|---|---|
| unpinned, ASLR on, 16 processes | 21.0–36.6 | 3 |
| unpinned, ASLR off, main stack moved k × 128 B (32 processes) | 22.2–42.0 | 15 |
| the same pad repeated 3 times (pads 0–7) | e.g. pad 6: 21.3, 27.2, 37.2 | not set by the pad |
| one CPU (`taskset -c N`, every even CPU 0–46, plus repeats) | 21.3–30.2 | 0 of 32 |
| one logical CPU per physical core (0–23), 10 processes | 23.8–44.2 | 6 |
| two CPUs of one CCD (0,1), 10 | 21.9–42.9 | 4 |
| one whole CCD (0–5), 10 | 20.9–44.1 | 2 |
| **two CPUs in different CCDs (0,6), 10** | **21.0–28.6** | **0** |

ManyMessages|256 follows the same pattern, at about 12–13 against 15–17.

**What these runs show:**
- The state is per process. The bench reports one solo ManyMessages mean per
  process, so a check's pair is effectively a coin flip.
- Migrations: `perf stat` shows 0–1 per process and 2–6 context switches, in
  slow and fast runs alike (`unpinned-stat-summary.txt`).
- With one CPU, every run is fast.
- With a second CPU in a different CCD, every run is fast. With a second CPU in
  the same CCD, some runs are slow.

**Mechanism: open.** The duo copies sleep on a condition variable between jobs,
so nothing should poll during a solo sample.

**It is in the published v7 instrument too** (plain ae63011, default glibc).
`per-process-means-in-checks.txt` lists each process's mean in each check:
- v7 A/A (a5e1e18 against itself): old 21.9/28.1/34.1/23.7, new 23.6/23.5/35.4/36.1;
- v7 full16 (a5e1e18 against 8e968d5): old and new each scatter from 20 to 47.

**A consequence.** Under `diag-align64`, the parent-routing ablation showed
ManyMessages ×0.82 with "11 of 16 pairs faster". Those were coin flips: 10 of 16
old processes landed slow against 4 of 16 new.
