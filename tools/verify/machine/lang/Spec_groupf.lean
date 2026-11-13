import Abi
import Spec_group
open X86

/-! # `groupf`: what is claimed

Definitions only. The theorem is `groupf_meets` (`Proof_groupf.lean`, written by the compiler), over any
program in which the chunk kernel's address meets its contract (`Spec_k32.lean`). -/

/-- **`groupf(lv, input, len, key, flags, c0)`.** What `group` is claimed to do (`Group.contract`: the levels
at `lv` become the levels over the chunks of the `len` bytes at `input`, the first numbered `c0`), for more
than one chunk and at most 32: every chunk but the last by one call of the 32-lane chunk kernel, the last by
`chunk_node`. For a machine with AVX-512. -/
def Groupf.contract (lv input len key flags c0 : BitVec 64) (k : Blake3.CV) (bytes : List (BitVec 8)) : Abi.Contract where
  args := [lv, input, len, key, flags, c0]
  stack := 8192#64
  accepts := len.toNat = bytes.length ∧ 1024#64 < len ∧ len ≤ 32768#64 ∧ flags < 256#64
  reads := [Cv.layout.keeps key k, (Bytes.layout bytes.length).keeps input bytes]
  updates := [(Levels.layout k ⟨flags.setWidth 32⟩).fills lv (Group.nodes k flags c0 bytes)]
  returns := fun _ => True
