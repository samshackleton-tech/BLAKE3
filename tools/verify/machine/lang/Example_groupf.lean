import Example_group
import Example_k32
import Spec_groupf

/-! # Examples for `groupf`

As for `group`. Each is a call of the chunk kernel's stand-in (some minutes in this model): two. -/

def Groupf.examples : List (BitVec 64 × BitVec 64 × BitVec 64 × BitVec 64 × BitVec 64 × BitVec 64 × Blake3.CV × List (BitVec 8)) := [
  -- a chunk and a byte, numbered from 32; three chunks and a part, keyed
  (0x300000#64, 0x100000#64, 1025#64, 0x200000#64, 0#64, 32#64, Blake3.IV, ExampleH.bytes 1025),
  (0x300000#64, 0x100000#64, 3500#64, 0x200000#64, 16#64, 96#64, ExampleH.key 2, ExampleH.bytes 3500),
  -- not examples: one chunk; a count that is not the bytes'
  (0x300000#64, 0x100000#64, 1024#64, 0x200000#64, 0#64, 32#64, Blake3.IV, ExampleH.bytes 1024),
  (0x300000#64, 0x100000#64, 2000#64, 0x200000#64, 0#64, 0#64, Blake3.IV, ExampleH.bytes 2001)]
