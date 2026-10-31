# BLAKE3 #198 / #199 on a 2x Xeon Gold 6330 (Ice Lake, re-rented), October 31

All at 0.8 (tag b5b988d8) against candidate/base-0.8 (bfbda192), bench 0.18.3 nested, old bench 5be5f236.
- runs/i198-icelake-*: release check (all CPUs), then mt ManyMessages 16384 at 24 pairs, A/B and A/A, by placement.
- runs/i198-icelake-node0-check-*: the release check confined to NUMA node 0, then mt IdleManyMessages 2 likewise.
- runs/*-confirm: on the confined check's builds, 24 pairs A/B and A/A, all CPUs and node 0, for the cells slower in both checks (confirm198.sh).
- runs/i198-bisect-icelake-*-d141edbe and i198-bisect-merge-icelake-*: the bisect (bisect.py, bisect2.py): each candidate measured against bfbda192 as the release check measures, 32 pairs of mt ManyMessages 16384 on check's layouts; out/bisect.log, out/bisect.json. Earlier attempts: -19c3bfd1 (script name shadowed Python's bisect module), -ed72a6ff (bench chosen by API step failed to build mid-range), -cd47e7a0 (measured c75daeb good, x0.993).
