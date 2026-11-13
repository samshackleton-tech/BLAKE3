import Sample_levels
import Sample_bytes
import Example_hashl
import Spec_group

/-! # Examples for `group`

Where the levels go, where the bytes are, how many, the key's address, the mode's flags, the first chunk's
number; then the key and the bytes. The tool runs the function on each and compares the result with the
contract (`try_fn.py`). -/

def Group.examples : List (BitVec 64 × BitVec 64 × BitVec 64 × BitVec 64 × BitVec 64 × BitVec 64 × Blake3.CV × List (BitVec 8)) := [
  -- no byte (one empty chunk); one byte; a chunk; a chunk and a byte, numbered from 32
  (0x300000#64, 0x100000#64, 0#64, 0x200000#64, 0#64, 0#64, Blake3.IV, ExampleH.bytes 0),
  (0x300000#64, 0x100000#64, 1#64, 0x200000#64, 0#64, 64#64, Blake3.IV, ExampleH.bytes 1),
  (0x300000#64, 0x100000#64, 1024#64, 0x200000#64, 0#64, 32#64, Blake3.IV, ExampleH.bytes 1024),
  (0x300000#64, 0x100000#64, 1025#64, 0x200000#64, 0#64, 32#64, Blake3.IV, ExampleH.bytes 1025),
  -- three chunks and a part, keyed; five chunks
  (0x300000#64, 0x100000#64, 3500#64, 0x200000#64, 16#64, 96#64, ExampleH.key 2, ExampleH.bytes 3500),
  (0x300000#64, 0x100000#64, 5120#64, 0x200000#64, 0#64, 32#64, Blake3.IV, ExampleH.bytes 5120),
  -- not an example: a count that is not the bytes'
  (0x300000#64, 0x100000#64, 7#64, 0x200000#64, 0#64, 0#64, Blake3.IV, ExampleH.bytes 8)]
