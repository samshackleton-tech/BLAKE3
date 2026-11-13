import Abi
import Spec_levels
import Spec_cvl
open X86

/-! # `addn`: what is claimed

Definitions only. The theorem is `addn_meets` (`Proof_addn.lean`, written by the compiler). -/

/-- **`addn(lv, key, flags, cvs, n)`.** The first `n` of the 32 chaining values at `cvs` are those of the
chunks `news`, in order: the levels at `lv` over `chunks` become the levels over `chunks` and `news`. The
32 values and the key are unchanged. The mode's flags are below 256. For a machine with AVX-512. -/
def Addn.contract (lv key flags cvs n : BitVec 64) (k : Blake3.CV) (chunks : Array Blake3.Node)
    (news : List Blake3.Node) (vals : List Blake3.CV) : Abi.Contract where
  args := [lv, key, flags, cvs, n]
  stack := 512#64
  accepts := news.length = n.toNat ∧ n ≤ 32#64 ∧ news.map Blake3.Node.cv = vals.take n.toNat ∧
    chunks.size + 32 ≤ 2 ^ 54 ∧ flags < 256#64
  reads := [Cv.layout.keeps key k, Cvs32.layout.keeps cvs vals]
  updates := [(Levels.layout k ⟨flags.setWidth 32⟩).turns lv chunks (chunks ++ news.toArray)]
  returns := fun _ => True
