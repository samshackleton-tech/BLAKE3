# offset_check.py as it would land with #141 (ad29ede)

These are Devon's commits (9145354, 4f3e033, 6a9816d, on Sam's 8b25ac6),
cherry-picked onto #141 (cba5f24), plus ad29ede:
- `IMMUNE_CELLS` lists our hash() of 64 bytes, buffers lent or owned, solo and
  shared.
- `CONTROL_CELLS` lists the same cells of the upstream crate
  (`blake3-official`), measured beside ours.
- The report parser reads one column per contender.

EPYC 9255, default glibc placement unless noted (`status.log`, `*.out`):

| build | runs | exit | meaning |
|---|---|---|---|
| #141 cba5f24 | 3 | 0, 0, 0 | ours immune, upstream's seen |
| picking kernel 6f9d962 | 2 | 0, 0 | ours immune, upstream's seen |
| base b94e2fa | 2 | 1, 1 | ours sensitive (the check fails as it should) |
| base, buffers aligned to 64 | 1 | 0 | ours immune; **upstream still sensitive** |

**A correction to #65.** With aligned buffers the upstream crate's hash() still
has windows: continuous 64 B +50.1% and +51.5%, lent 64 B +10.8%, lent 256 B
+3.3% (`align64-1.out`). So "the windows need a buffer that crosses a cache
line" holds for our crate's paths, not for every hash() on this machine.
