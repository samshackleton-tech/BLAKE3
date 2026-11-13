import Abi
import Spec_cvl
import Spec_ptrs
import Spec_bytes
import Spec_chunknode
open X86

/-! # The 32-lane chunk kernel: the contract its callers assume

`blake3_servil_avx512_k32` of the library (AVX-512: 32 whole chunks at once) is not in this machine model.
A function that calls it is proved over any program in which the kernel's address meets this contract (as
for the 16-lane parent kernel, `Spec_p16.lean`). This is the kernel's contract as our callers use it, written
by hand; a slow function of ours stands in for it when examples run. Definitions only. -/

/-- `n` whole chunks one after another at `a` (at most 32): `1024 n` bytes. -/
def Chunks.At (n : BitVec 64) (m : Mem) (a : BitVec 64) (bytes : List (BitVec 8)) : Prop :=
  n ≤ 32#64 ∧ bytes.length = 1024 * n.toNat ∧ Bytes.At m a bytes
@[abi] def Chunks.layout (n : BitVec 64) : Abi.Layout (List (BitVec 8)) := ⟨n <<< 10, Chunks.At n⟩

/-- The bytes lane `i` hashes: chunk `i` of the `n` given, or the first again in a lane past them. -/
def K32.input (n : BitVec 64) (bytes : List (BitVec 8)) (i : Nat) : List (BitVec 8) :=
  (bytes.drop (1024 * (if i < n.toNat then i else 0))).take 1024

/-- What the kernel writes: for each of its 32 lanes, the chaining value of that lane's chunk, numbered
`counter + i` (the kernel counts from `counter`, one a lane). -/
def K32.values (k : Blake3.CV) (flags counter n : BitVec 64) (bytes : List (BitVec 8)) : List Blake3.CV :=
  (List.range 32).map fun i => (Chunk.node k flags (counter + BitVec.ofNat 64 i) (K32.input n bytes i)).cv

/-- **`blake3_servil_avx512_k32(inputs, blocks, key, counter, packed, out)`**, as our callers use it: 16
blocks an input (a whole chunk), the mode's flags with the chunk's start and end flags and a last block
length of 64 packed above them; the table at `inputs` holds the addresses of `n` chunks one after another
from `base` (1 to 32) and `base` again in the lanes past them. The 32 values at `out` become the lanes'
chunks' chaining values under the key at `key` (`K32.values`). The key, the table and the chunks are
unchanged. -/
def K32.contract (inputs blocks key counter packed out : BitVec 64) (k : Blake3.CV) (base n flags : BitVec 64)
    (bytes : List (BitVec 8)) : Abi.Contract where
  args := [inputs, blocks, key, counter, packed, out]
  stack := 4096#64
  accepts := blocks = 16#64 ∧ packed = flags ||| 0x40020100#64 ∧ flags < 256#64 ∧ 1#64 ≤ n ∧ n ≤ 32#64
  reads := [Cv.layout.keeps key k, Ptrs.layout.keeps inputs (Ptrs.spread base n 1024#64), (Chunks.layout n).keeps base bytes]
  updates := [Cvs32.layout.fills out (K32.values k flags counter n bytes)]
  returns := fun _ => True
