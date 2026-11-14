import WideLemmas
open X86

/-! # Sixteen wide stores, one after another

The block loop of the 32-lane kernel stores the sixteen message words of a half (one ZMM register each) at
`a`, `a + 64`, ..., `a + 960`. Facts about the memory that leaves: each word reads back, every byte outside
those 1024 is as it was, and what was owned is owned. No code is named. Written by gen_k32.py's author by
the same pattern sixteen times (the script that printed it is in the commit's message). -/

namespace K32

/-- Memory after sixteen wide stores at `a + 64 k`. -/
def puts16 (m : Mem) (a : BitVec 64) (v : Nat → Z) : Mem :=
  (((((((((((((((m.put512 a (v 0)).put512 (a + 0x40#64) (v 1)).put512 (a + 0x80#64) (v 2)).put512 (a + 0xC0#64) (v 3)).put512 (a + 0x100#64) (v 4)).put512 (a + 0x140#64) (v 5)).put512 (a + 0x180#64) (v 6)).put512 (a + 0x1C0#64) (v 7)).put512 (a + 0x200#64) (v 8)).put512 (a + 0x240#64) (v 9)).put512 (a + 0x280#64) (v 10)).put512 (a + 0x2C0#64) (v 11)).put512 (a + 0x300#64) (v 12)).put512 (a + 0x340#64) (v 13)).put512 (a + 0x380#64) (v 14)).put512 (a + 0x3C0#64) (v 15)

/-- **Each stored word reads back.** -/
theorem puts16_read (m : Mem) (a : BitVec 64) (v : Nat → Z) :
    (puts16 m a v).read512 (a) = some (v 0) ∧
    (puts16 m a v).read512 (a + 0x40#64) = some (v 1) ∧
    (puts16 m a v).read512 (a + 0x80#64) = some (v 2) ∧
    (puts16 m a v).read512 (a + 0xC0#64) = some (v 3) ∧
    (puts16 m a v).read512 (a + 0x100#64) = some (v 4) ∧
    (puts16 m a v).read512 (a + 0x140#64) = some (v 5) ∧
    (puts16 m a v).read512 (a + 0x180#64) = some (v 6) ∧
    (puts16 m a v).read512 (a + 0x1C0#64) = some (v 7) ∧
    (puts16 m a v).read512 (a + 0x200#64) = some (v 8) ∧
    (puts16 m a v).read512 (a + 0x240#64) = some (v 9) ∧
    (puts16 m a v).read512 (a + 0x280#64) = some (v 10) ∧
    (puts16 m a v).read512 (a + 0x2C0#64) = some (v 11) ∧
    (puts16 m a v).read512 (a + 0x300#64) = some (v 12) ∧
    (puts16 m a v).read512 (a + 0x340#64) = some (v 13) ∧
    (puts16 m a v).read512 (a + 0x380#64) = some (v 14) ∧
    (puts16 m a v).read512 (a + 0x3C0#64) = some (v 15) := by
  unfold puts16
  refine ⟨?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_⟩
  · rw [read512_put512_far _ (a + 0x3C0#64) _ (a) (by constructor <;> bv_decide), read512_put512_far _ (a + 0x380#64) _ (a) (by constructor <;> bv_decide), read512_put512_far _ (a + 0x340#64) _ (a) (by constructor <;> bv_decide), read512_put512_far _ (a + 0x300#64) _ (a) (by constructor <;> bv_decide), read512_put512_far _ (a + 0x2C0#64) _ (a) (by constructor <;> bv_decide), read512_put512_far _ (a + 0x280#64) _ (a) (by constructor <;> bv_decide), read512_put512_far _ (a + 0x240#64) _ (a) (by constructor <;> bv_decide), read512_put512_far _ (a + 0x200#64) _ (a) (by constructor <;> bv_decide), read512_put512_far _ (a + 0x1C0#64) _ (a) (by constructor <;> bv_decide), read512_put512_far _ (a + 0x180#64) _ (a) (by constructor <;> bv_decide), read512_put512_far _ (a + 0x140#64) _ (a) (by constructor <;> bv_decide), read512_put512_far _ (a + 0x100#64) _ (a) (by constructor <;> bv_decide), read512_put512_far _ (a + 0xC0#64) _ (a) (by constructor <;> bv_decide), read512_put512_far _ (a + 0x80#64) _ (a) (by constructor <;> bv_decide), read512_put512_far _ (a + 0x40#64) _ (a) (by constructor <;> bv_decide)]
    exact read512_put512_same _ _ _
  · rw [read512_put512_far _ (a + 0x3C0#64) _ (a + 0x40#64) (by constructor <;> bv_decide), read512_put512_far _ (a + 0x380#64) _ (a + 0x40#64) (by constructor <;> bv_decide), read512_put512_far _ (a + 0x340#64) _ (a + 0x40#64) (by constructor <;> bv_decide), read512_put512_far _ (a + 0x300#64) _ (a + 0x40#64) (by constructor <;> bv_decide), read512_put512_far _ (a + 0x2C0#64) _ (a + 0x40#64) (by constructor <;> bv_decide), read512_put512_far _ (a + 0x280#64) _ (a + 0x40#64) (by constructor <;> bv_decide), read512_put512_far _ (a + 0x240#64) _ (a + 0x40#64) (by constructor <;> bv_decide), read512_put512_far _ (a + 0x200#64) _ (a + 0x40#64) (by constructor <;> bv_decide), read512_put512_far _ (a + 0x1C0#64) _ (a + 0x40#64) (by constructor <;> bv_decide), read512_put512_far _ (a + 0x180#64) _ (a + 0x40#64) (by constructor <;> bv_decide), read512_put512_far _ (a + 0x140#64) _ (a + 0x40#64) (by constructor <;> bv_decide), read512_put512_far _ (a + 0x100#64) _ (a + 0x40#64) (by constructor <;> bv_decide), read512_put512_far _ (a + 0xC0#64) _ (a + 0x40#64) (by constructor <;> bv_decide), read512_put512_far _ (a + 0x80#64) _ (a + 0x40#64) (by constructor <;> bv_decide)]
    exact read512_put512_same _ _ _
  · rw [read512_put512_far _ (a + 0x3C0#64) _ (a + 0x80#64) (by constructor <;> bv_decide), read512_put512_far _ (a + 0x380#64) _ (a + 0x80#64) (by constructor <;> bv_decide), read512_put512_far _ (a + 0x340#64) _ (a + 0x80#64) (by constructor <;> bv_decide), read512_put512_far _ (a + 0x300#64) _ (a + 0x80#64) (by constructor <;> bv_decide), read512_put512_far _ (a + 0x2C0#64) _ (a + 0x80#64) (by constructor <;> bv_decide), read512_put512_far _ (a + 0x280#64) _ (a + 0x80#64) (by constructor <;> bv_decide), read512_put512_far _ (a + 0x240#64) _ (a + 0x80#64) (by constructor <;> bv_decide), read512_put512_far _ (a + 0x200#64) _ (a + 0x80#64) (by constructor <;> bv_decide), read512_put512_far _ (a + 0x1C0#64) _ (a + 0x80#64) (by constructor <;> bv_decide), read512_put512_far _ (a + 0x180#64) _ (a + 0x80#64) (by constructor <;> bv_decide), read512_put512_far _ (a + 0x140#64) _ (a + 0x80#64) (by constructor <;> bv_decide), read512_put512_far _ (a + 0x100#64) _ (a + 0x80#64) (by constructor <;> bv_decide), read512_put512_far _ (a + 0xC0#64) _ (a + 0x80#64) (by constructor <;> bv_decide)]
    exact read512_put512_same _ _ _
  · rw [read512_put512_far _ (a + 0x3C0#64) _ (a + 0xC0#64) (by constructor <;> bv_decide), read512_put512_far _ (a + 0x380#64) _ (a + 0xC0#64) (by constructor <;> bv_decide), read512_put512_far _ (a + 0x340#64) _ (a + 0xC0#64) (by constructor <;> bv_decide), read512_put512_far _ (a + 0x300#64) _ (a + 0xC0#64) (by constructor <;> bv_decide), read512_put512_far _ (a + 0x2C0#64) _ (a + 0xC0#64) (by constructor <;> bv_decide), read512_put512_far _ (a + 0x280#64) _ (a + 0xC0#64) (by constructor <;> bv_decide), read512_put512_far _ (a + 0x240#64) _ (a + 0xC0#64) (by constructor <;> bv_decide), read512_put512_far _ (a + 0x200#64) _ (a + 0xC0#64) (by constructor <;> bv_decide), read512_put512_far _ (a + 0x1C0#64) _ (a + 0xC0#64) (by constructor <;> bv_decide), read512_put512_far _ (a + 0x180#64) _ (a + 0xC0#64) (by constructor <;> bv_decide), read512_put512_far _ (a + 0x140#64) _ (a + 0xC0#64) (by constructor <;> bv_decide), read512_put512_far _ (a + 0x100#64) _ (a + 0xC0#64) (by constructor <;> bv_decide)]
    exact read512_put512_same _ _ _
  · rw [read512_put512_far _ (a + 0x3C0#64) _ (a + 0x100#64) (by constructor <;> bv_decide), read512_put512_far _ (a + 0x380#64) _ (a + 0x100#64) (by constructor <;> bv_decide), read512_put512_far _ (a + 0x340#64) _ (a + 0x100#64) (by constructor <;> bv_decide), read512_put512_far _ (a + 0x300#64) _ (a + 0x100#64) (by constructor <;> bv_decide), read512_put512_far _ (a + 0x2C0#64) _ (a + 0x100#64) (by constructor <;> bv_decide), read512_put512_far _ (a + 0x280#64) _ (a + 0x100#64) (by constructor <;> bv_decide), read512_put512_far _ (a + 0x240#64) _ (a + 0x100#64) (by constructor <;> bv_decide), read512_put512_far _ (a + 0x200#64) _ (a + 0x100#64) (by constructor <;> bv_decide), read512_put512_far _ (a + 0x1C0#64) _ (a + 0x100#64) (by constructor <;> bv_decide), read512_put512_far _ (a + 0x180#64) _ (a + 0x100#64) (by constructor <;> bv_decide), read512_put512_far _ (a + 0x140#64) _ (a + 0x100#64) (by constructor <;> bv_decide)]
    exact read512_put512_same _ _ _
  · rw [read512_put512_far _ (a + 0x3C0#64) _ (a + 0x140#64) (by constructor <;> bv_decide), read512_put512_far _ (a + 0x380#64) _ (a + 0x140#64) (by constructor <;> bv_decide), read512_put512_far _ (a + 0x340#64) _ (a + 0x140#64) (by constructor <;> bv_decide), read512_put512_far _ (a + 0x300#64) _ (a + 0x140#64) (by constructor <;> bv_decide), read512_put512_far _ (a + 0x2C0#64) _ (a + 0x140#64) (by constructor <;> bv_decide), read512_put512_far _ (a + 0x280#64) _ (a + 0x140#64) (by constructor <;> bv_decide), read512_put512_far _ (a + 0x240#64) _ (a + 0x140#64) (by constructor <;> bv_decide), read512_put512_far _ (a + 0x200#64) _ (a + 0x140#64) (by constructor <;> bv_decide), read512_put512_far _ (a + 0x1C0#64) _ (a + 0x140#64) (by constructor <;> bv_decide), read512_put512_far _ (a + 0x180#64) _ (a + 0x140#64) (by constructor <;> bv_decide)]
    exact read512_put512_same _ _ _
  · rw [read512_put512_far _ (a + 0x3C0#64) _ (a + 0x180#64) (by constructor <;> bv_decide), read512_put512_far _ (a + 0x380#64) _ (a + 0x180#64) (by constructor <;> bv_decide), read512_put512_far _ (a + 0x340#64) _ (a + 0x180#64) (by constructor <;> bv_decide), read512_put512_far _ (a + 0x300#64) _ (a + 0x180#64) (by constructor <;> bv_decide), read512_put512_far _ (a + 0x2C0#64) _ (a + 0x180#64) (by constructor <;> bv_decide), read512_put512_far _ (a + 0x280#64) _ (a + 0x180#64) (by constructor <;> bv_decide), read512_put512_far _ (a + 0x240#64) _ (a + 0x180#64) (by constructor <;> bv_decide), read512_put512_far _ (a + 0x200#64) _ (a + 0x180#64) (by constructor <;> bv_decide), read512_put512_far _ (a + 0x1C0#64) _ (a + 0x180#64) (by constructor <;> bv_decide)]
    exact read512_put512_same _ _ _
  · rw [read512_put512_far _ (a + 0x3C0#64) _ (a + 0x1C0#64) (by constructor <;> bv_decide), read512_put512_far _ (a + 0x380#64) _ (a + 0x1C0#64) (by constructor <;> bv_decide), read512_put512_far _ (a + 0x340#64) _ (a + 0x1C0#64) (by constructor <;> bv_decide), read512_put512_far _ (a + 0x300#64) _ (a + 0x1C0#64) (by constructor <;> bv_decide), read512_put512_far _ (a + 0x2C0#64) _ (a + 0x1C0#64) (by constructor <;> bv_decide), read512_put512_far _ (a + 0x280#64) _ (a + 0x1C0#64) (by constructor <;> bv_decide), read512_put512_far _ (a + 0x240#64) _ (a + 0x1C0#64) (by constructor <;> bv_decide), read512_put512_far _ (a + 0x200#64) _ (a + 0x1C0#64) (by constructor <;> bv_decide)]
    exact read512_put512_same _ _ _
  · rw [read512_put512_far _ (a + 0x3C0#64) _ (a + 0x200#64) (by constructor <;> bv_decide), read512_put512_far _ (a + 0x380#64) _ (a + 0x200#64) (by constructor <;> bv_decide), read512_put512_far _ (a + 0x340#64) _ (a + 0x200#64) (by constructor <;> bv_decide), read512_put512_far _ (a + 0x300#64) _ (a + 0x200#64) (by constructor <;> bv_decide), read512_put512_far _ (a + 0x2C0#64) _ (a + 0x200#64) (by constructor <;> bv_decide), read512_put512_far _ (a + 0x280#64) _ (a + 0x200#64) (by constructor <;> bv_decide), read512_put512_far _ (a + 0x240#64) _ (a + 0x200#64) (by constructor <;> bv_decide)]
    exact read512_put512_same _ _ _
  · rw [read512_put512_far _ (a + 0x3C0#64) _ (a + 0x240#64) (by constructor <;> bv_decide), read512_put512_far _ (a + 0x380#64) _ (a + 0x240#64) (by constructor <;> bv_decide), read512_put512_far _ (a + 0x340#64) _ (a + 0x240#64) (by constructor <;> bv_decide), read512_put512_far _ (a + 0x300#64) _ (a + 0x240#64) (by constructor <;> bv_decide), read512_put512_far _ (a + 0x2C0#64) _ (a + 0x240#64) (by constructor <;> bv_decide), read512_put512_far _ (a + 0x280#64) _ (a + 0x240#64) (by constructor <;> bv_decide)]
    exact read512_put512_same _ _ _
  · rw [read512_put512_far _ (a + 0x3C0#64) _ (a + 0x280#64) (by constructor <;> bv_decide), read512_put512_far _ (a + 0x380#64) _ (a + 0x280#64) (by constructor <;> bv_decide), read512_put512_far _ (a + 0x340#64) _ (a + 0x280#64) (by constructor <;> bv_decide), read512_put512_far _ (a + 0x300#64) _ (a + 0x280#64) (by constructor <;> bv_decide), read512_put512_far _ (a + 0x2C0#64) _ (a + 0x280#64) (by constructor <;> bv_decide)]
    exact read512_put512_same _ _ _
  · rw [read512_put512_far _ (a + 0x3C0#64) _ (a + 0x2C0#64) (by constructor <;> bv_decide), read512_put512_far _ (a + 0x380#64) _ (a + 0x2C0#64) (by constructor <;> bv_decide), read512_put512_far _ (a + 0x340#64) _ (a + 0x2C0#64) (by constructor <;> bv_decide), read512_put512_far _ (a + 0x300#64) _ (a + 0x2C0#64) (by constructor <;> bv_decide)]
    exact read512_put512_same _ _ _
  · rw [read512_put512_far _ (a + 0x3C0#64) _ (a + 0x300#64) (by constructor <;> bv_decide), read512_put512_far _ (a + 0x380#64) _ (a + 0x300#64) (by constructor <;> bv_decide), read512_put512_far _ (a + 0x340#64) _ (a + 0x300#64) (by constructor <;> bv_decide)]
    exact read512_put512_same _ _ _
  · rw [read512_put512_far _ (a + 0x3C0#64) _ (a + 0x340#64) (by constructor <;> bv_decide), read512_put512_far _ (a + 0x380#64) _ (a + 0x340#64) (by constructor <;> bv_decide)]
    exact read512_put512_same _ _ _
  · rw [read512_put512_far _ (a + 0x3C0#64) _ (a + 0x380#64) (by constructor <;> bv_decide)]
    exact read512_put512_same _ _ _
  · exact read512_put512_same _ _ _

/-- **Every byte outside the 1024 is as it was.** -/
theorem puts16_other (m : Mem) (a : BitVec 64) (v : Nat → Z) (x : BitVec 64) (h : 1024#64 ≤ x - a) :
    puts16 m a v x = m x := by
  unfold puts16
  rw [put512_other _ (a + 0x3C0#64) _ x (by bv_omega), put512_other _ (a + 0x380#64) _ x (by bv_omega), put512_other _ (a + 0x340#64) _ x (by bv_omega), put512_other _ (a + 0x300#64) _ x (by bv_omega), put512_other _ (a + 0x2C0#64) _ x (by bv_omega), put512_other _ (a + 0x280#64) _ x (by bv_omega), put512_other _ (a + 0x240#64) _ x (by bv_omega), put512_other _ (a + 0x200#64) _ x (by bv_omega), put512_other _ (a + 0x1C0#64) _ x (by bv_omega), put512_other _ (a + 0x180#64) _ x (by bv_omega), put512_other _ (a + 0x140#64) _ x (by bv_omega), put512_other _ (a + 0x100#64) _ x (by bv_omega), put512_other _ (a + 0xC0#64) _ x (by bv_omega), put512_other _ (a + 0x80#64) _ x (by bv_omega), put512_other _ (a + 0x40#64) _ x (by bv_omega), put512_other _ (a) _ x (by bv_omega)]

/-- **What was owned is owned.** -/
theorem puts16_owned (m : Mem) (a : BitVec 64) (v : Nat → Z) (b : BitVec 64) (o : Owned64 m b) : Owned64 (puts16 m a v) b := by
  unfold puts16
  exact owned64_put512 _ _ _ _ (owned64_put512 _ _ _ _ (owned64_put512 _ _ _ _ (owned64_put512 _ _ _ _ (owned64_put512 _ _ _ _ (owned64_put512 _ _ _ _ (owned64_put512 _ _ _ _ (owned64_put512 _ _ _ _ (owned64_put512 _ _ _ _ (owned64_put512 _ _ _ _ (owned64_put512 _ _ _ _ (owned64_put512 _ _ _ _ (owned64_put512 _ _ _ _ (owned64_put512 _ _ _ _ (owned64_put512 _ _ _ _ (owned64_put512 _ _ _ _ (o))))))))))))))))

/-- A whole ZMM word read where it was not stored, 1024 bytes or more from `a`, reads as before. -/
theorem puts16_read_far (m : Mem) (a : BitVec 64) (v : Nat → Z) (b : BitVec 64) (h : 1024#64 ≤ b - a ∧ 64#64 ≤ a - b) :
    (puts16 m a v).read512 b = m.read512 b :=
  read512_congr b fun x hx => puts16_other m a v x (by obtain ⟨h1, h2⟩ := h; bv_omega)

end K32
