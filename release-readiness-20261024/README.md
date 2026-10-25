# Release-readiness audit, October24,2026

Optimization is frozen. The last full-group experiment is complete and
excluded from the release; see ../full-group-pool-20261024/RESULT.md.

The existing release tracker is BLAKE3 #125. RELEASE-READINESS.md lists
priorities and scope decisions, not a declaration that a release is ready.

Two deterministic fixtures exposed false passes in release-check.py:
a green workflow with skipped substantive jobs, and a Mac check restricted
to changed cells. `gate-gap-fixtures.json` contains synthetic results,
**not actual CI, proof or release evidence**. The reproduction was run
against John61b469ce.

Fix branch: samshackleton-tech/BLAKE3
`candidate/sam-release-evidence-gates`,
a6b6c1c7c59ad7873ab503bda66fc0298bff9ef4. Its13tests pass; the two
end-to-end controls fail against the old checker. Run its checked-in
`python3 tools/test_release_check.py` from the repository root. The older
reproduction script retains the local checkout path used for the audit.
No performance experiments or production-library changes are part of this
release-tool work.
