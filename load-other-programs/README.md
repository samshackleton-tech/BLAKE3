# clocks: other programs counted from their own CPU time (Linux)

Branch `candidate/sam-load-other-programs` on servil 0909641. clocks/ is
otherwise identical to the bench's pin 7f9f1f7.

**The problem.** `bench-hashes b3sum` on the EPYC 9255 read busy in 16 of
403 windows, about 1 CPU for 1 s each, with nothing else running. Every
window I checked overlaps the official b3sum's "1000 x 16 KiB, a process each"
cell (`b3win.py`; 1 s `pidstat` in `released-cli-v7/run2/pidstat.txt` shows
no other program). The load monitor inferred other programs' load as the
machine's busy time less our own (self and children). That residual includes
kernel work charged to no process, which our children cause: kernel threads
cleaning up after a thousand 48-thread processes (0.45 CPU-s), and other CPUs'
interrupt handling booked as system time (1.09 CPU-s). See `attribution.txt`.

**The fix.** On Linux, sum the CPU time of every process except kernel threads
(`PF_KTHREAD`) and this process's own tree. Each process's figure includes the
children it has waited for, so short-lived programs count in their parents'.
Kernel threads are remembered by pid and not re-read, since they are 542 of
574 processes here. Steal time and macOS are unchanged.

**Results:**
- The official cell's other load: 0.61 → 0.00 CPUs. A real other program
  still reads 1.00.
- The same b3sum run: "busy in 16 of 403 windows" → "quiet: 0.00 CPUs on
  average, 0.31 in the busiest window" (`load-fix-v2/status.log`).
- A reading costs 0.24 ms (`load-fix-v2/clocks-reading-cost.log`). It was
  8.6 µs, and 1.8 ms without the kernel-thread cache. It happens once a window
  (1 s), outside timed intervals.
- Tests: 37/37 three times over, and the new ignored `own_children` 3/3
  (`load-fix-tests/`).

**Changed tests:**
- On Linux a sibling this process started is its own.
- A new test checks that an orphan adopted by init, a program we didn't start,
  still reads as load.
- The load tests now take turns across processes (a file lock), because under
  nextest each test is a process and one test's spinner is another program to
  the rest.
