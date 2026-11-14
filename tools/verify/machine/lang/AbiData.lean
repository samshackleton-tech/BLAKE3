import Abi
import Spec_bytes
open X86

/-! # The read-only data a program holds

Read once. Definitions only. A program is its instructions, each at an address, and may hold read-only
data: bytes at addresses too (a table of constants the linker places beside the code). Instructions are
not in the model's memory; data is, because code reads it through a register like any other bytes. -/

namespace Abi

/-- Read-only data a program holds: bytes, at the addresses they are placed at. -/
abbrev Data := List (BitVec 64 × List (BitVec 8))

/-- One item of the data, as a piece of memory: its bytes are there at the call and at the return. -/
def Data.piece (x : BitVec 64 × List (BitVec 8)) : Piece :=
  ⟨x.1, BitVec.ofNat 64 x.2.length, fun m => Bytes.At m x.1 x.2, fun m => Bytes.At m x.1 x.2⟩

/-- **The contract `c`, for a function of a program that holds the data `d`.** At the call the data is in
memory, apart from the stack and from every piece the function may change (`Meets` asks that of whatever a
contract reads); the function does not change it (`Meets`: every byte outside what it may change is as it
was). All else is as `c` says. -/
@[abi] def Contract.over (c : Contract) (d : Data) : Contract :=
  { c with reads := c.reads ++ d.map Data.piece }

end Abi
