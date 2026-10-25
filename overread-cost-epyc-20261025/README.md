# #168: the over-read fix's AVX-512 cost on EPYC 9255

[RESULT.md](RESULT.md) has the verdict, the exact sources and command, the
per-group figures, and the failed or incomplete attempts.

The verdict: **no cell slower in either stage, in two full `check --cells all
--pairs 12` runs**, fixed (`bfbda19`) against measurement-only unfixed
(`a137c68`), with servil's own kernels on both sides. This is not a claim of
equivalence. `run2/` keeps every raw sample; `run1-nosamples/` keeps only
the first run's verdict text. Dual manifests cover this directory except
the manifests themselves.
