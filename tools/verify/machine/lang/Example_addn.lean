import Sample_levels
import Sample_cvl
import Example_ladd
import Spec_addn

/-! # Examples for `addn`

Where the levels are, the key's address, the mode's flags, where the 32 values are, how many are added; then
the key, the chunks the levels are over, the new chunks, and the 32 values. The tool runs the function on
each and compares the result with the contract (`try_fn.py`). -/

def ExampleA.news (n : Nat) : List Blake3.Node := (List.range n).map fun i => ExampleL.node (300 + i)
/-- 32 values: the first `n` the new chunks', the rest others. -/
def ExampleA.vals (n : Nat) : List Blake3.CV :=
  (ExampleA.news n).map Blake3.Node.cv ++ (List.range (32 - n)).map fun i => ExampleL.cv (500 + i)

def Addn.examples : List (BitVec 64 × BitVec 64 × BitVec 64 × BitVec 64 × BitVec 64 × Blake3.CV × Array Blake3.Node × List Blake3.Node × List Blake3.CV) := [
  (0x100000#64, 0x200000#64, 0#64, 0x300000#64, 0#64, ExampleL.cv 1, ExampleL.nodes 0, ExampleA.news 0, ExampleA.vals 0),
  (0x100000#64, 0x200000#64, 0#64, 0x300000#64, 1#64, ExampleL.cv 1, ExampleL.nodes 0, ExampleA.news 1, ExampleA.vals 1),
  (0x100000#64, 0x200000#64, 0#64, 0x300000#64, 5#64, ExampleL.cv 1, ExampleL.nodes 0, ExampleA.news 5, ExampleA.vals 5),
  (0x100000#64, 0x200000#64, 16#64, 0x300000#64, 31#64, ExampleL.cv 2, ExampleL.nodes 3, ExampleA.news 31, ExampleA.vals 31),
  (0x100000#64, 0x200000#64, 0#64, 0x300000#64, 32#64, ExampleL.cv 1, ExampleL.nodes 1, ExampleA.news 32, ExampleA.vals 32),
  -- not examples: a count that is not the new chunks'; values that are not theirs
  (0x100000#64, 0x200000#64, 0#64, 0x300000#64, 4#64, ExampleL.cv 1, ExampleL.nodes 0, ExampleA.news 5, ExampleA.vals 5),
  (0x100000#64, 0x200000#64, 0#64, 0x300000#64, 5#64, ExampleL.cv 1, ExampleL.nodes 0, ExampleA.news 5, ExampleA.vals 4)]
