# blake3-servil 0.8's Linux x86-64 b3sum release binary

`b3sum-v0.8.0+b3c5efc7c975d903762dea809066f7c0a0603861-x86_64-unknown-linux-gnu`, with its `.sha256` and `.b3`:
built by the tag's own `tools/b3sum-release.sh`, unmodified, in a clean checkout of
`v0.8.0+b3c5efc7…` (b5b988d8) at the fixed path `/root/b3sum-release-build`, on the EPYC 9255
(Ubuntu 26.04.1, rustc 1.99.1, CARGO_HOME /root/.cargo). Statically linked (static-pie).

**Reproducible:** two separate clean checkouts, each built there, give identical bytes
(build-record/b3sum-x86-fixedpath-test-*). Built at two different paths it is not, since the
library is a path dependency of b3sum: its absolute path enters Cargo's symbol hashes and the
panic locations (build-record/b3sum-x86-release-*, b3sum-x86-remap-test-*: --remap-path-prefix
removes the path strings but not the hashes).

**Checked:** `--version` names 0.8.0+b3c5efc7; the empty input's digest is BLAKE3's published one;
on an i7-12700K (AVX2), 41 files (100 MB random and /usr/bin binaries) give digests identical to
official b3sum's, multithreaded and with --num-threads 1. All builds ran through pinned-run.
