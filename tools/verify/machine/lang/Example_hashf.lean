import Example_hashw
import Spec_hashf

/-! # Examples for `hashf`

As for `hashw`, with the platform. -/

def Hashf.examples : List (BitVec 64 × BitVec 64 × BitVec 64 × BitVec 64 × BitVec 64 × BitVec 64 × Blake3.CV × List (BitVec 8)) := [
  -- with AVX-512 (to hashw); with SSE4.1 (to hashl)
  (0x300000#64, 0x100000#64, 1025#64, 0x200000#64, 0#64, 5#64, Blake3.IV, ExampleH.bytes 1025),
  (0x300000#64, 0x100000#64, 3500#64, 0x200000#64, 16#64, 3#64, ExampleH.key 2, ExampleH.bytes 3500),
  (0x300000#64, 0x100000#64, 0#64, 0x200000#64, 0#64, 5#64, Blake3.IV, ExampleH.bytes 0),
  -- not an example: a count that is not the message's
  (0x300000#64, 0x100000#64, 7#64, 0x200000#64, 0#64, 5#64, Blake3.IV, ExampleH.bytes 8)]
