import Sample_cvl
import Sample_ptrs
import Sample_chunks
import Example_p16
import Spec_k32

/-! # Examples for the 32-lane chunk kernel's contract

For a function that stands in for the kernel in this model (`k32s`): the table, 16 blocks, the key's address,
the first chunk's number, the packed flags, where the 32 values go; then the key, where the chunks are, how
many, the mode's flags, the chunks' bytes. The tool runs the stand-in on each and compares the result with
the contract (`try_fn.py`). -/

def ExampleK.bytes (n : Nat) : List (BitVec 8) := (List.range n).map fun i => BitVec.ofNat 8 (i * 7 + i / 251 + 3)

def K32.examples : List (BitVec 64 × BitVec 64 × BitVec 64 × BitVec 64 × BitVec 64 × BitVec 64 × Blake3.CV × BitVec 64 × BitVec 64 × BitVec 64 × List (BitVec 8)) := [
  (0x100000#64, 16#64, 0x200000#64, 0#64, 0x40020100#64, 0x300000#64, ExampleT.cv 1, 0x400000#64, 32#64, 0#64, ExampleK.bytes 32768),
  (0x100000#64, 16#64, 0x200000#64, 0xFFFFFFF0#64, 0x40020100#64, 0x300000#64, ExampleT.cv 1, 0x400000#64, 32#64, 0#64, ExampleK.bytes 32768),
  (0x100000#64, 16#64, 0x200000#64, 64#64, 0x40020110#64, 0x300000#64, ExampleT.cv 2, 0x400000#64, 3#64, 16#64, ExampleK.bytes 3072),
  -- not examples: one block an input; no chunk
  (0x100000#64, 1#64, 0x200000#64, 0#64, 0x40020100#64, 0x300000#64, ExampleT.cv 1, 0x400000#64, 3#64, 0#64, ExampleK.bytes 3072),
  (0x100000#64, 16#64, 0x200000#64, 0#64, 0x40020100#64, 0x300000#64, ExampleT.cv 1, 0x400000#64, 0#64, 0#64, [])]
