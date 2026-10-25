# SMT on the EPYC 9255 (#119): the held wide kernel's SMT loss, and 0.8's SMT gain

[RESULT.md](RESULT.md) has the explanation, tables, commands and caveats.
In short: the held 32-way kernel gains almost nothing from a second thread
on its core (x0.96-1.11), so its alone-on-a-core lead becomes a loss when
siblings share cores. 0.8's kernels, like official BLAKE3, gain
x1.44-1.73 a core. Capping the pool at physical cores is a trade-off, not
a fix. Mixed-speed threads are handled by the pool's shrinking pieces.
Measurement only: existing binaries and bench builds, perf counters, and
bench regress/compare. Dual manifests cover this directory except
themselves.
