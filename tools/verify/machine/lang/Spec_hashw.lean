import Abi
import Spec_hashl
open X86

/-! # `hashw`: what is claimed

Definitions only. The theorem is `hashw_meets` (`Proof_hashw.lean`,
written by the compiler), over any program in which the two wide kernels' addresses meet their contracts
(`Spec_k32.lean`, `Spec_p16.lean`). -/

/-- **`hashw(out, input, len, key, flags)`.** What `hashl` is claimed to do (`Hashl.contract`): the 32 bytes
at `out` become the first 32 bytes of BLAKE3's output for the message under the key and the mode's flags.
The whole groups of 32 chunks go through the wide kernels (`wide`), the last group one block at a time
(`group`), and `finish` makes the root. For a machine with AVX-512. -/
def Hashw.contract (out input len key flags : BitVec 64) (k : Blake3.CV) (bytes : List (BitVec 8)) : Abi.Contract where
  args := [out, input, len, key, flags]
  stack := 32768#64
  accepts := len.toNat = bytes.length ∧ flags < 256#64
  reads := [Cv.layout.keeps key k, (Bytes.layout bytes.length).keeps input bytes]
  updates := [Cv.layout.fills out (Hash.words k flags bytes)]
  returns := fun _ => True
