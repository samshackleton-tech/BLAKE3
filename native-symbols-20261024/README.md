# Native-symbol isolation and current-source EPYC measurements

See [RESULT.md](RESULT.md) for the decision and [INTEGRATION.md](INTEGRATION.md)
for exact pins. BLAKE3 issue151 and PR152 document the correctness fix.

- `raw-results.tar.gz`: completed native logs, samples, maps, layout orders,
  source records and executable digests. First failed provenance smoke and
  the interrupted colliding comparison are retained. Extracts into
  `complete-native/`; corrected measurements are under `private-symbols/`.
- `audit/baseline-L0` and `audit/private-symbols-bench`: the actual colliding
  and isolated executables inspected, with symbol/disassembly records.
- `audit/static-symbol-check/`: namespace-only assembly comparison; all
  three inherited x86 backends' .text bytes match before/after renaming.
- `scripts/`: the collection and inspection scripts, retaining machine-local
  paths for reproducibility. Other layout executables remain on the EPYC;
  their hashes are in the raw archive.

The corrected SIMD draft is held: the scoped screen flags a stream-batch
regression, and its A/A also shows substantial stream variability. These
unreleased results do not replace the public overview or released0.17 data.
Source branches are on samshackleton-tech/BLAKE3 and bench-hashes, named in
the scripts and integration record. SHA-256 and BLAKE3 manifests cover this
folder, excluding the manifests themselves.
