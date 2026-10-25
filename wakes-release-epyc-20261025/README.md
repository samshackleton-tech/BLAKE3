# EPYC 9255: the newer wake design (#119) and the 0.8 release run (#125)

[RESULT.md](RESULT.md) has the commits, commands and verdicts. The wake
design alone (d795fd0 against 338e249): no cell slower, with the pool
cells 3-12% faster. The release run (ee4c0d7 against bfbda19, `--old-bench
5be5f236`): 4 cells slower (LentBatches 256, st and mt, and mt Nix files),
none of them pool cells, so far unresolved. The same-code control made one
false "faster" decision (mt OneMessage 64 B).

`wakes8-epyc/` and `release-08-epyc/` keep the logs, the suites' output,
provenance and every kept sample. The scripts are as run. Dual manifests
cover this directory except the manifests themselves.
