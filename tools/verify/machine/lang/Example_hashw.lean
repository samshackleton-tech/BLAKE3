import Sample_bytes
import Example_hashl
import Example_k32
import Spec_hashw

/-! # Examples for `hashw`

Where the hash goes, where the message is, its length, the key's address, the mode's flags; then the key and the message. The tool runs the function on each (the two wide kernels' places
taken by their stand-ins) and compares the result with the contract (`try_fn.py`). A call of the chunk kernel's stand-in is some minutes
in this model, more the more has been written before it, and every message of more than a chunk makes one:
two examples do. The way through with two such calls (whole groups, then a last group of more than a chunk:
33,793 bytes) is not among them: run once, it met the contract (524,646 instructions), and the examples
together took 50 minutes. The assembled function with the library's kernels linked is run on that way
outside the model (`../levels/README.md`). -/

def Hashw.examples : List (BitVec 64 × BitVec 64 × BitVec 64 × BitVec 64 × BitVec 64 × Blake3.CV × List (BitVec 8)) := [
  -- the empty message, a chunk (to hashl); three chunks and a part (no whole group), keyed
  (0x300000#64, 0x100000#64, 0#64, 0x200000#64, 0#64, Blake3.IV, ExampleH.bytes 0),
  (0x300000#64, 0x100000#64, 1024#64, 0x200000#64, 0#64, Blake3.IV, ExampleH.bytes 1024),
  (0x300000#64, 0x100000#64, 3500#64, 0x200000#64, 16#64, ExampleH.key 2, ExampleH.bytes 3500),
  -- a whole group and a byte: the wide kernels, then a last group of one chunk
  (0x300000#64, 0x100000#64, 32769#64, 0x200000#64, 0#64, Blake3.IV, ExampleH.bytes 32769),
  -- not an example: a count that is not the message's
  (0x300000#64, 0x100000#64, 7#64, 0x200000#64, 0#64, Blake3.IV, ExampleH.bytes 8)]
