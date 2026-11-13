import Abi
import Spec_levels
import Spec_bytes
import Spec_chunknode
open X86

/-! # `group`: what is claimed

Definitions only. The theorem is `group_meets` (`Proof_group.lean`, written by the compiler). -/

/-- The nodes of the chunks of some bytes of a message, the first chunk numbered `c0`: as the specification
makes a chunk's node (`Blake3.chunkNode`, section 4.2), chunk `i` with the number `c0 + i`. (No bytes: one
empty chunk.) -/
def Group.nodes (k : Blake3.CV) (flags c0 : BitVec 64) (bytes : List (BitVec 8)) : Array Blake3.Node :=
  (Array.range (max 1 ((bytes.length + 1023) / 1024))).map fun i =>
    Chunk.node k flags (c0 + BitVec.ofNat 64 i) ((bytes.drop (1024 * i)).take 1024)

/-- **`group(lv, input, len, key, flags, c0)`.** With `len` bytes of a message at `input`, whose first chunk
is the message's chunk number `c0`, and the key at `key`: the levels at `lv` become the levels over those
bytes' chunks (`Group.nodes`), each chunk's node made by `chunk_node`, one block at a time. The bytes and the
key are unchanged. The mode's flags are below 256. For a machine with AVX-512. -/
def Group.contract (lv input len key flags c0 : BitVec 64) (k : Blake3.CV) (bytes : List (BitVec 8)) : Abi.Contract where
  args := [lv, input, len, key, flags, c0]
  stack := 1024#64
  accepts := len.toNat = bytes.length ∧ flags < 256#64
  reads := [Cv.layout.keeps key k, (Bytes.layout bytes.length).keeps input bytes]
  updates := [(Levels.layout k ⟨flags.setWidth 32⟩).fills lv (Group.nodes k flags c0 bytes)]
  returns := fun _ => True
