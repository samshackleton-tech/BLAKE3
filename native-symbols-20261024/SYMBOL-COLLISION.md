# Native-symbol collision: current mixed benchmark is blocked

@johnservil @devonjonte: while bringing the latest branches together and
checking where official wins, I found that both Rust crates bind the same
unmangled x86 assembly names. This affects which kernel is actually tested,
not merely the source-provenance text.

In my current EPYC benchmark (bench `0d38c5f1c4a738ef05d9baf3699f9dd8467970da`,
library integration `f31ad2fdc668110f68320ed3b3c09f69c72983ab`, official
blake3 1.8.7), `nm` shows exactly one definition:

```
00000000002aeb80 T blake3_hash_many_avx512
00000000002aeb80 T _blake3_hash_many_avx512
```

Both crates' `src/ffi_avx512.rs` declare that same symbol. The linked
function has official's four-/two-input loads, not servil's narrowed loads:

```
2b1c4c: vmovups zmm8, ZMMWORD PTR [r8+rdx*1-0x40]
2b1c6f: vmovups zmm9, ZMMWORD PTR [r8+rdx*1-0x30]
2b1ca3: vmovups zmm8, ZMMWORD PTR [r8+rdx*1-0x20]
2b1cc9: vmovups zmm9, ZMMWORD PTR [r8+rdx*1-0x10]
2b1f71: vmovups ymm8, YMMWORD PTR [r8+rdx*1-0x40]
```

Servil's source uses xmm loads at those sites. Thus this executable has
silently selected official's native implementation for both callers.
The SSE4.1 and AVX2 FFI declarations also share upstream symbol names.
Which archive supplies a shared definition may depend on the link; source
pins alone cannot establish that each contender runs its own kernel.

I stopped the in-flight SIMD comparison after its A/A passed; the maps
and partial comparison remain archived as provisional. No speed verdict
from that mixed executable is being promoted. Earlier results need a
binary-level audit; I have not established the scope across all historical
binaries or architectures. Unique newly named kernels are a separate case.

I am preparing a small private-symbol fix for the inherited x86 backends,
with native co-linking and a planted-kernel control. The assembly proof
sources and `tools/verify/` will stay untouched: the proposed build step
namespaces the assembly copies it compiles, and the Rust FFI declarations
bind those private names. Please hold new mixed-crate speed claims until
we verify that both sets of native entries exist and each caller reaches
its own.

— Sam Shackleton
