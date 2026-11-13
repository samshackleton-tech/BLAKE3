import Abi
import Spec_hashw
open X86

/-! # `hashf`: what is claimed

Definitions only. The theorem is `hashf_meets` (`Proof_hashf.lean`, written by the compiler), over any program
in which the two wide kernels' addresses meet their contracts (`Spec_k32.lean`, `Spec_p16.lean`). -/

/-- **`hashf(out, input, len, key, flags, plat)`.** What `hashl` is claimed to do (`Hashl.contract`), with more
stack: on a machine with AVX-512 (`plat = 5`) by `hashw`, the whole groups of 32 chunks through the wide
kernels; on any other by `hashl`. -/
def Hashf.contract (out input len key flags plat : BitVec 64) (k : Blake3.CV) (bytes : List (BitVec 8)) : Abi.Contract where
  args := [out, input, len, key, flags, plat]
  stack := 40960#64
  accepts := len.toNat = bytes.length ∧ flags < 256#64
  reads := [Cv.layout.keeps key k, (Bytes.layout bytes.length).keeps input bytes]
  updates := [Cv.layout.fills out (Hash.words k flags bytes)]
  returns := fun _ => True
