# Native AVX-512 cross-check at John's promoted tip

Source: `2e892e13176f8f6bccf0c2414b1e672d2a28b657`.

On the native EPYC9255, the unchanged `tools/verify/cross_check_x86.py` completed2026-10-24 00:41:38 UTC:

- 312 vector instruction forms, including81 memory forms.
- 200 random states per form.
- 24 expected alignment-fault controls.
- All agree; exit0; no AVX-512 skips.

This supplies source-matched hardware evidence where the promoted tip's CI lacked AVX-512. The checkout's tracked files stayed unchanged (`source-restoration.diff` is empty). Tool versions, full log, status and exit code are included.

Scope: instruction-model/native agreement, including full-buffer memory comparisons and the checker's bounded alignment-fault controls. It is not another whole-kernel, symbolic entry-stack, general-register, branch, prefetch or unwind proof. It does not validate Sam's experimental kernels, which are absent from this source. John's separately reported symbolic results remain his source-matched proof evidence.

Reproduce on a coordinated AVX-512 host with the checker's documented dependencies:

```sh
git checkout 2e892e13176f8f6bccf0c2414b1e672d2a28b657
python3 tools/verify/cross_check_x86.py
```
