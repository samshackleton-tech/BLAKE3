import Try
import Spec_k32
open X86

/-! # Whole chunks one after another, for trying functions on examples

Test-side: not proved against `Chunks.At`. -/

def Chunks.sample (n : BitVec 64) : Try.Sample (List (BitVec 8)) where
  put := fun m a bs => Try.fill m a bs.toArray
  check := fun m a bs => decide (n ≤ 32#64) && decide (bs.length = 1024 * n.toNat) && Try.bytes? m a bs.length == some bs
