import Sample_levels
import Sample_bytes
import Example_k32
import Spec_wide

/-! # Examples for `wide`

Where the levels go, where the message is, its length, the key's address, the mode's flags; then the key and
the message. The tool runs the function on each (the two wide kernels' places taken by their stand-ins) and
compares the result with the contract (`try_fn.py`). -/

def Wide.examples : List (BitVec 64 × BitVec 64 × BitVec 64 × BitVec 64 × BitVec 64 × Blake3.CV × List (BitVec 8)) := [
  -- nothing; exactly one group (it is left: it may hold the root); one group and a byte more
  (0x100000#64, 0x200000#64, 0#64, 0x300000#64, 0#64, ExampleT.cv 1, ExampleK.bytes 0),
  (0x100000#64, 0x200000#64, 32768#64, 0x300000#64, 0#64, ExampleT.cv 1, ExampleK.bytes 32768),
  (0x100000#64, 0x200000#64, 32769#64, 0x300000#64, 16#64, ExampleT.cv 2, ExampleK.bytes 32769),
  -- (one group taken is some minutes of the chunk kernel's stand-in in this model; two are not tried here)
  -- not an example: a count that is not the message's
  (0x100000#64, 0x200000#64, 7#64, 0x300000#64, 0#64, ExampleT.cv 1, ExampleK.bytes 8)]
