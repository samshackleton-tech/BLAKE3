import Sample_levels
import Example_ladd
import Spec_finish

/-! # Examples for `finish`

Where the root goes, where the groups' levels and the last group's levels are, the key's address, the mode's
flags, which case it is; then the key, the groups' top nodes and the last group's chunks. The tool runs the function on each
and compares the result with the contract (`try_fn.py`). -/

def ExampleF.units (n : Nat) : Array Blake3.Node := (Array.range n).map fun i => ExampleL.node (700 + i)

def Finish.examples : List (BitVec 64 × BitVec 64 × BitVec 64 × BitVec 64 × BitVec 64 × BitVec 64 × Blake3.CV × Array Blake3.Node × Array Blake3.Node) := [
  -- no whole group: two chunks; five
  (0x300000#64, 0x100000#64, 0x200000#64, 0x400000#64, 0#64, 0#64, ExampleL.cv 1, ExampleF.units 0, ExampleL.nodes 2),
  (0x300000#64, 0x100000#64, 0x200000#64, 0x400000#64, 16#64, 0#64, ExampleL.cv 2, ExampleF.units 0, ExampleL.nodes 5),
  -- one group and a last group of one chunk; of three; three groups and seven chunks
  (0x300000#64, 0x100000#64, 0x200000#64, 0x400000#64, 0#64, 1#64, ExampleL.cv 1, ExampleF.units 1, ExampleL.nodes 1),
  (0x300000#64, 0x100000#64, 0x200000#64, 0x400000#64, 0#64, 2#64, ExampleL.cv 1, ExampleF.units 1, ExampleL.nodes 3),
  (0x300000#64, 0x100000#64, 0x200000#64, 0x400000#64, 16#64, 2#64, ExampleL.cv 2, ExampleF.units 3, ExampleL.nodes 7),
  -- not examples: no chunk; one chunk and no group (it is its own root, made elsewhere); a case that is not so
  (0x300000#64, 0x100000#64, 0x200000#64, 0x400000#64, 0#64, 2#64, ExampleL.cv 1, ExampleF.units 1, ExampleL.nodes 0),
  (0x300000#64, 0x100000#64, 0x200000#64, 0x400000#64, 0#64, 0#64, ExampleL.cv 1, ExampleF.units 0, ExampleL.nodes 1),
  (0x300000#64, 0x100000#64, 0x200000#64, 0x400000#64, 0#64, 1#64, ExampleL.cv 1, ExampleF.units 1, ExampleL.nodes 3)]
