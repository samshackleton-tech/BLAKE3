import Abi
import Spec_lroot
open X86

/-! # `finish`: what is claimed

Definitions only. The theorem is `finish_meets` (`Proof_finish.lean`, written by the compiler). -/

/-- The top nodes the root is made over: with no whole group taken, the last group's chunks themselves;
otherwise the groups' top nodes and after them the last group's (the top of the specification's tree over
its chunks, which for one chunk is the chunk). `../alg/Groups.lean`: the tree over these is the tree over
all the chunks. -/
def Finish.tops (k : Blake3.CV) (mode : Blake3.Word) (units tail : Array Blake3.Node) : Array Blake3.Node :=
  if units.size = 0 then tail else units.push (Blake3.tree k mode tail)

/-- Which of its three ways `finish` is told to take says what is so: 0, no whole group (and the last group
has two chunks or more); 1, whole groups and a last group of one chunk; 2, whole groups and a last group of
two chunks or more. -/
def Finish.way (sel : BitVec 64) (units tail : Array Blake3.Node) : Prop :=
  (sel = 0#64 ∧ units.size = 0 ∧ 2 ≤ tail.size) ∨ (sel = 1#64 ∧ 0 < units.size ∧ tail.size = 1) ∨
  (sel = 2#64 ∧ 0 < units.size ∧ 2 ≤ tail.size)

instance (sel : BitVec 64) (units tail : Array Blake3.Node) : Decidable (Finish.way sel units tail) := by
  unfold Finish.way; infer_instance

/-- **`finish(out, wl, lv, key, flags, sel)`.** With levels at `wl` over the top nodes of a message's whole
groups (`units`) and levels at `lv` over the chunks of its last group (`tail`), and `sel` saying which of the
three cases it is (`Finish.way`): the 32 bytes at `out` become the first eight words of the specification's
output for the tree over `Finish.tops`. The last group's value (not a root) is added to the levels at `wl`,
if there is a whole group; the levels at `lv` and the key are unchanged. The mode's flags are below 256. For
a machine with AVX-512. -/
def Finish.contract (out wl lv key flags sel : BitVec 64) (k : Blake3.CV) (units tail : Array Blake3.Node) : Abi.Contract where
  args := [out, wl, lv, key, flags, sel]
  stack := 1024#64
  accepts := Finish.way sel units tail ∧ units.size < 2 ^ 54 ∧ flags < 256#64
  reads := [Cv.layout.keeps key k, (Levels.layout k ⟨flags.setWidth 32⟩).keeps lv tail]
  updates := [(Levels.layout k ⟨flags.setWidth 32⟩).turns wl units
                (if units.size = 0 then units else units.push (Blake3.tree k ⟨flags.setWidth 32⟩ tail)),
              Cv.layout.fills out (Levels.top k ⟨flags.setWidth 32⟩ (Finish.tops k ⟨flags.setWidth 32⟩ units tail) ⟨BitVec.setWidth 32 8#64⟩)]
  returns := fun _ => True
