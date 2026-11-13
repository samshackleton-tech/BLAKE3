import Proof_hashf
import Meets_hashl_bytes
import Spec_k32
import Spec_p16
open X86

/-! # `hashf` on x86-64 meets the contract that names no machine: the fast hash computes BLAKE3, given its kernels

`Hash.byteContract` (`../spec/HashContract.lean`) is the statement a user reads, as for `hashl`
(`Meets_hashl_bytes.lean`). `hashf` calls the library's two wide kernels, which this machine model does not
hold: the theorem is about `hashf`'s instructions (with every function of ours it calls) over any program
`ext` in which those kernels' addresses meet their contracts (`K32.contract`, `P16.contract`). The two
hypotheses are what is not proved here. -/

/-- **`Hash.byteContract` read for this machine is `Hashf.contract` under the IV and no flags**, with what
the byte contract accepts. -/
theorem Hashf.contract_eq (out inp len key plat : BitVec 64) (msg : List (BitVec 8)) (hlen : msg.length < 2 ^ 64) :
    Abi.ofBytes (Hash.byteContract out inp len key plat msg) 40960#64
      = { Hashf.contract out inp len key 0#64 plat Blake3.IV msg with accepts := (Hash.byteContract out inp len key plat msg).accepts } := by
  simp only [Abi.ofBytes, Hash.byteContract, Hashf.contract, List.map, Hash.piece_key, Hash.piece_out, Bytes.piece_keeps _ hlen]

/-- **The x86-64 code of `hashf` computes BLAKE3, over any program in which the 32-lane chunk kernel and the
16-lane parent kernel meet their contracts**: for every message it meets `Hash.byteContract`, with 40960
bytes of stack. -/
theorem hashf_meets_bytes (ext : Nat → Option (Instr × Nat))
    (hK32 : ∀ x0 x1 x2 x3 x4 x5 x6 x7 x8 x9 x10, Abi.Meets (Code_hashf.prog ext) 0x10000 (K32.contract x0 x1 x2 x3 x4 x5 x6 x7 x8 x9 x10))
    (hP16 : ∀ x0 x1 x2 x3 x4 x5 x6 x7 x8 x9 x10, Abi.Meets (Code_hashf.prog ext) 0x18000 (P16.contract x0 x1 x2 x3 x4 x5 x6 x7 x8 x9 x10))
    (out inp len key plat : BitVec 64) (msg : List (BitVec 8)) :
    Abi.Meets (Code_hashf.prog ext) 0x1A0000 (Abi.ofBytes (Hash.byteContract out inp len key plat msg) 40960#64) := by
  by_cases hlen : msg.length < 2 ^ 64
  · rw [Hashf.contract_eq out inp len key plat msg hlen]
    exact Abi.Meets.of_accepts _ (Proof_hashf.hashf_meets ext hK32 hP16 out inp len key 0#64 plat Blake3.IV msg)
      (fun h => ⟨h.1, by decide⟩)
  · -- no `len` is the length of such a message: the contract accepts no call
    intro s ra hpc hargs hq hR hAp ha hreq
    have h1 : len.toNat = msg.length := ha.1
    have := len.isLt
    omega

#print axioms hashf_meets_bytes
