import Abi
import Spec_levels
import Spec_bytes
import Spec_chunknode
import Chunk
import Groups
open X86

/-! # `wide`: what is claimed

Definitions only. The theorem is `wide_meets` (`Proof_wide.lean`, written by the compiler), over any program
in which the two wide kernels' addresses meet their contracts (`Spec_k32.lean`, `Spec_p16.lean`). -/

/-- The nodes of all the chunks of a message, as the specification makes them (`Blake3.chunksOf`). -/
def Wide.nodes (k : Blake3.CV) (flags : BitVec 64) (bytes : List (BitVec 8)) : Array Blake3.Node :=
  Blake3.chunksOf k ⟨flags.setWidth 32⟩ (Blake3.ofBytes bytes)

/-- The specification's subtree over the 32 chunks of group `g` of a message: its top node. Its chaining value
is what a level of the tree over groups holds (`../alg/Groups.lean`: the tree over the chunks is the tree
over the groups' own trees). -/
def Wide.unit (k : Blake3.CV) (flags : BitVec 64) (bytes : List (BitVec 8)) (g : Nat) : Blake3.Node :=
  Blake3.tree.go k ⟨flags.setWidth 32⟩ (Wide.nodes k flags bytes) (32 * g) 32

/-- The groups of the first `c` chunks (`c` a multiple of 32). -/
def Wide.units (k : Blake3.CV) (flags : BitVec 64) (bytes : List (BitVec 8)) (c : Nat) : Array Blake3.Node :=
  (Array.range (c / 32)).map (Wide.unit k flags bytes)

/-- How many chunks `wide` takes of a message of `n` bytes: whole groups of 32, while more of the message
follows the group (the last group, whole or short, is left: it may hold the root). -/
def Wide.count (n : Nat) : Nat := 32 * ((n - 1) / 32768)

/-- **`wide(wl, input, len, key, flags)`.** With the `len` bytes of a message at `input` and the key at `key`:
the levels at `wl` become the levels over the message's whole groups of 32 chunks that have more of the
message after them (`Wide.count`: all but the last group), each group's value made by the 32-lane chunk
kernel and the 16-lane parent kernel; the result is how many chunks that is. The message and the key are
unchanged. The mode's flags are below 256. For a machine with AVX-512. -/
def Wide.contract (wl input len key flags : BitVec 64) (k : Blake3.CV) (bytes : List (BitVec 8)) : Abi.Contract where
  args := [wl, input, len, key, flags]
  stack := 16384#64
  accepts := len.toNat = bytes.length ∧ flags < 256#64
  reads := [Cv.layout.keeps key k, (Bytes.layout bytes.length).keeps input bytes]
  updates := [(Levels.layout k ⟨flags.setWidth 32⟩).fills wl (Wide.units k flags bytes (Wide.count bytes.length))]
  returns := fun r => r.toNat = Wide.count bytes.length
