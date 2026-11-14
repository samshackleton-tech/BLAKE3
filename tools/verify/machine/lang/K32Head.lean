import K32Loop
open X86 Cells Blake3Generic

/-! # A block of the 32-lane chunk kernel: its set-up and its end

Written by gen_k32.py from the kernel's lifted instructions. Before the rounds: this block's flags (the chunk's
start flag on the first block, its end flag on the last), and the sixteen state words of every lane (the
chaining value, the IV, the lane's counter, the block length, the flags). After them: the new chaining value
(the two halves of the state, xored), the block offset moved on, and back for the next block or out. -/

namespace K32

/-- The chaining values of the first half's lanes: word `k` in ZMM `k`. -/
def CvA (st : State) (c : Nat → Vector (BitVec 32) 8) : Prop :=
  st.zmm 0 = zpack (fun i => (c i)[0]) ∧ st.zmm 1 = zpack (fun i => (c i)[1]) ∧ st.zmm 2 = zpack (fun i => (c i)[2]) ∧ st.zmm 3 = zpack (fun i => (c i)[3]) ∧ st.zmm 4 = zpack (fun i => (c i)[4]) ∧ st.zmm 5 = zpack (fun i => (c i)[5]) ∧ st.zmm 6 = zpack (fun i => (c i)[6]) ∧ st.zmm 7 = zpack (fun i => (c i)[7])

/-- The chaining values of the second half's lanes. -/
def CvB (st : State) (c : Nat → Vector (BitVec 32) 8) : Prop :=
  st.zmm 8 = zpack (fun i => (c i)[0]) ∧ st.zmm 9 = zpack (fun i => (c i)[1]) ∧ st.zmm 10 = zpack (fun i => (c i)[2]) ∧ st.zmm 11 = zpack (fun i => (c i)[3]) ∧ st.zmm 12 = zpack (fun i => (c i)[4]) ∧ st.zmm 13 = zpack (fun i => (c i)[5]) ∧ st.zmm 14 = zpack (fun i => (c i)[6]) ∧ st.zmm 15 = zpack (fun i => (c i)[7])

/-- The second half's chaining values but the last word, whose register the loads borrow (it waits on the stack). -/
def CvB7 (st : State) (c : Nat → Vector (BitVec 32) 8) : Prop :=
  st.zmm 8 = zpack (fun i => (c i)[0]) ∧ st.zmm 9 = zpack (fun i => (c i)[1]) ∧ st.zmm 10 = zpack (fun i => (c i)[2]) ∧ st.zmm 11 = zpack (fun i => (c i)[3]) ∧ st.zmm 12 = zpack (fun i => (c i)[4]) ∧ st.zmm 13 = zpack (fun i => (c i)[5]) ∧ st.zmm 14 = zpack (fun i => (c i)[6])

/-- The lanes' counters where the kernel keeps them: low words and high words of each half, at `a + 2048`. -/
def Counters (mem : Mem) (a : BitVec 64) (tA tB : Nat → BitVec 64) : Prop :=
  mem.read512 (a + 0x800#64) = some (zpack fun i => (tA i).setWidth 32) ∧
  mem.read512 (a + 0x840#64) = some (zpack fun i => ((tA i) >>> 32).setWidth 32) ∧
  mem.read512 (a + 0x880#64) = some (zpack fun i => (tB i).setWidth 32) ∧
  mem.read512 (a + 0x8C0#64) = some (zpack fun i => ((tB i) >>> 32).setWidth 32)

set_option maxRecDepth 1000000 in
set_option maxHeartbeats 0 in
/-- **A block's set-up, for the chunk's first block (the start flag)** (0x10829 to 0x10900, 30 instructions). -/
theorem hdr_first (cA cB : Nat → Vector (BitVec 32) 8) (tA tB : Nat → BitVec 64) (flags : BitVec 64) (st : State)
    (hpc : st.pc = 0x10829) (hal : aligned64 st.rsp = true)
    (hbx : st.rbx = flags ||| 0x40020100#64) (hf : flags < 256#64)
    (hr14 : st.r14 = 0#64) (hz13 : (st.r13 - 1#64 == 0#64) = false)
    (ha : CvA st cA) (hb : CvB7 st cB) (hs : st.mem.read512 (st.rsp + 0x900#64) = some (zpack fun i => (cB i)[7]))
    (ht : Counters st.mem st.rsp tA tB) :
    ∃ st', steps Code_k32.prog 30 st = some st' ∧ st'.pc = 0x10900 ∧ st'.w.r11 = 7#64 ∧ st'.rdi = 0x500000C0#64 ∧
      RowsAV st' (fun i => initv (cA i) (tA i) 64#32 (flags.setWidth 32 ||| 1#32)) ∧ RowsBV st' (fun i => initv (cB i) (tB i) 64#32 (flags.setWidth 32 ||| 1#32)) ∧
      st'.rbx = st.rbx ∧ st'.rsp = st.rsp ∧ st'.rbp = st.rbp ∧ st'.rsi = st.rsi ∧ st'.r9 = st.r9 ∧ st'.r12 = st.r12 ∧ st'.r13 = st.r13 ∧ st'.r14 = st.r14 ∧ st'.r15 = st.r15 ∧ st'.w.r10 = st.w.r10 ∧ st'.mem = st.mem := by
  have a800 : aligned64 (st.rsp + 0x800#64) = true := aligned64_add hal (by decide)
  have a840 : aligned64 (st.rsp + 0x840#64) = true := aligned64_add hal (by decide)
  have a880 : aligned64 (st.rsp + 0x880#64) = true := aligned64_add hal (by decide)
  have a8C0 : aligned64 (st.rsp + 0x8C0#64) = true := aligned64_add hal (by decide)
  have a900 : aligned64 (st.rsp + 0x900#64) = true := aligned64_add hal (by decide)
  obtain ⟨ha0, ha1, ha2, ha3, ha4, ha5, ha6, ha7⟩ := ha
  obtain ⟨hb0, hb1, hb2, hb3, hb4, hb5, hb6⟩ := hb
  obtain ⟨ht0, ht1, ht2, ht3⟩ := ht
  obtain ⟨rax, rcx, rdx, rbx, rsp, rbp, rsi, rdi, r8, r9, r12, r13, r14, r15, zf, cf, x0, x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12, x13, x14, x15, mem, pc, ⟨r10, r11, u0, u1, u2, u3, u4, u5, u6, u7, u8, u9, u10, u11, u12, u13, u14, u15, z16, z17, z18, z19, z20, z21, z22, z23, z24, z25, z26, z27, z28, z29, z30, z31, k1, k2⟩⟩ := st
  simp only [State.zmm] at hpc hal a800 a840 a880 a8C0 a900 hbx hs ht0 ht1 ht2 ht3 hz13 hr14 ha0 ha1 ha2 ha3 ha4 ha5 ha6 ha7 hb0 hb1 hb2 hb3 hb4 hb5 hb6
  subst hpc hbx hr14
  have e0 : x0 = zlo (zpack (fun i => (cA i)[0])) := by rw [← ha0, zlo_zjoin]
  have f0 : u0 = zhi (zpack (fun i => (cA i)[0])) := by rw [← ha0, zhi_zjoin]
  subst e0 f0
  have e1 : x1 = zlo (zpack (fun i => (cA i)[1])) := by rw [← ha1, zlo_zjoin]
  have f1 : u1 = zhi (zpack (fun i => (cA i)[1])) := by rw [← ha1, zhi_zjoin]
  subst e1 f1
  have e2 : x2 = zlo (zpack (fun i => (cA i)[2])) := by rw [← ha2, zlo_zjoin]
  have f2 : u2 = zhi (zpack (fun i => (cA i)[2])) := by rw [← ha2, zhi_zjoin]
  subst e2 f2
  have e3 : x3 = zlo (zpack (fun i => (cA i)[3])) := by rw [← ha3, zlo_zjoin]
  have f3 : u3 = zhi (zpack (fun i => (cA i)[3])) := by rw [← ha3, zhi_zjoin]
  subst e3 f3
  have e4 : x4 = zlo (zpack (fun i => (cA i)[4])) := by rw [← ha4, zlo_zjoin]
  have f4 : u4 = zhi (zpack (fun i => (cA i)[4])) := by rw [← ha4, zhi_zjoin]
  subst e4 f4
  have e5 : x5 = zlo (zpack (fun i => (cA i)[5])) := by rw [← ha5, zlo_zjoin]
  have f5 : u5 = zhi (zpack (fun i => (cA i)[5])) := by rw [← ha5, zhi_zjoin]
  subst e5 f5
  have e6 : x6 = zlo (zpack (fun i => (cA i)[6])) := by rw [← ha6, zlo_zjoin]
  have f6 : u6 = zhi (zpack (fun i => (cA i)[6])) := by rw [← ha6, zhi_zjoin]
  subst e6 f6
  have e7 : x7 = zlo (zpack (fun i => (cA i)[7])) := by rw [← ha7, zlo_zjoin]
  have f7 : u7 = zhi (zpack (fun i => (cA i)[7])) := by rw [← ha7, zhi_zjoin]
  subst e7 f7
  have e8 : x8 = zlo (zpack (fun i => (cB i)[0])) := by rw [← hb0, zlo_zjoin]
  have f8 : u8 = zhi (zpack (fun i => (cB i)[0])) := by rw [← hb0, zhi_zjoin]
  subst e8 f8
  have e9 : x9 = zlo (zpack (fun i => (cB i)[1])) := by rw [← hb1, zlo_zjoin]
  have f9 : u9 = zhi (zpack (fun i => (cB i)[1])) := by rw [← hb1, zhi_zjoin]
  subst e9 f9
  have e10 : x10 = zlo (zpack (fun i => (cB i)[2])) := by rw [← hb2, zlo_zjoin]
  have f10 : u10 = zhi (zpack (fun i => (cB i)[2])) := by rw [← hb2, zhi_zjoin]
  subst e10 f10
  have e11 : x11 = zlo (zpack (fun i => (cB i)[3])) := by rw [← hb3, zlo_zjoin]
  have f11 : u11 = zhi (zpack (fun i => (cB i)[3])) := by rw [← hb3, zhi_zjoin]
  subst e11 f11
  have e12 : x12 = zlo (zpack (fun i => (cB i)[4])) := by rw [← hb4, zlo_zjoin]
  have f12 : u12 = zhi (zpack (fun i => (cB i)[4])) := by rw [← hb4, zhi_zjoin]
  subst e12 f12
  have e13 : x13 = zlo (zpack (fun i => (cB i)[5])) := by rw [← hb5, zlo_zjoin]
  have f13 : u13 = zhi (zpack (fun i => (cB i)[5])) := by rw [← hb5, zhi_zjoin]
  subst e13 f13
  have e14 : x14 = zlo (zpack (fun i => (cB i)[6])) := by rw [← hb6, zlo_zjoin]
  have f14 : u14 = zhi (zpack (fun i => (cB i)[6])) := by rw [← hb6, zhi_zjoin]
  subst e14 f14
  run_fn [a800, a840, a880, a8C0, a900, hs, ht0, ht1, ht2, ht3, hz13, zjoin_split, zlo_zjoin, zhi_zjoin]
  refine ⟨_, rfl, rfl, rfl, ?_, ?_, rfl, rfl, rfl, rfl, rfl, rfl, rfl, rfl, rfl, rfl, rfl⟩
  · simp only [RowsAV, RowsA, State.zmm, zjoin_split, initv, zbroadcast, Vector.getElem_mk, List.getElem_toArray, List.getElem_cons_succ, List.getElem_cons_zero]
    refine ⟨?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_⟩ <;> first | rfl | trivial | (exact congrArg zpack (funext fun _ => by bv_decide))
  · simp only [RowsBV, RowsB, State.zmm, zjoin_split, initv, zbroadcast, Vector.getElem_mk, List.getElem_toArray, List.getElem_cons_succ, List.getElem_cons_zero]
    refine ⟨?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_⟩ <;> first | rfl | trivial | (exact congrArg zpack (funext fun _ => by bv_decide))

set_option maxRecDepth 1000000 in
set_option maxHeartbeats 0 in
/-- **A block's set-up, for a block that is neither the first nor the last** (0x10829 to 0x10900, 26 instructions). -/
theorem hdr_mid (cA cB : Nat → Vector (BitVec 32) 8) (tA tB : Nat → BitVec 64) (flags : BitVec 64) (st : State)
    (hpc : st.pc = 0x10829) (hal : aligned64 st.rsp = true)
    (hbx : st.rbx = flags ||| 0x40020100#64) (hf : flags < 256#64)
    (hz14 : (st.r14 &&& st.r14 == 0#64) = false) (hz13 : (st.r13 - 1#64 == 0#64) = false)
    (ha : CvA st cA) (hb : CvB7 st cB) (hs : st.mem.read512 (st.rsp + 0x900#64) = some (zpack fun i => (cB i)[7]))
    (ht : Counters st.mem st.rsp tA tB) :
    ∃ st', steps Code_k32.prog 26 st = some st' ∧ st'.pc = 0x10900 ∧ st'.w.r11 = 7#64 ∧ st'.rdi = 0x500000C0#64 ∧
      RowsAV st' (fun i => initv (cA i) (tA i) 64#32 (flags.setWidth 32)) ∧ RowsBV st' (fun i => initv (cB i) (tB i) 64#32 (flags.setWidth 32)) ∧
      st'.rbx = st.rbx ∧ st'.rsp = st.rsp ∧ st'.rbp = st.rbp ∧ st'.rsi = st.rsi ∧ st'.r9 = st.r9 ∧ st'.r12 = st.r12 ∧ st'.r13 = st.r13 ∧ st'.r14 = st.r14 ∧ st'.r15 = st.r15 ∧ st'.w.r10 = st.w.r10 ∧ st'.mem = st.mem := by
  have a800 : aligned64 (st.rsp + 0x800#64) = true := aligned64_add hal (by decide)
  have a840 : aligned64 (st.rsp + 0x840#64) = true := aligned64_add hal (by decide)
  have a880 : aligned64 (st.rsp + 0x880#64) = true := aligned64_add hal (by decide)
  have a8C0 : aligned64 (st.rsp + 0x8C0#64) = true := aligned64_add hal (by decide)
  have a900 : aligned64 (st.rsp + 0x900#64) = true := aligned64_add hal (by decide)
  obtain ⟨ha0, ha1, ha2, ha3, ha4, ha5, ha6, ha7⟩ := ha
  obtain ⟨hb0, hb1, hb2, hb3, hb4, hb5, hb6⟩ := hb
  obtain ⟨ht0, ht1, ht2, ht3⟩ := ht
  obtain ⟨rax, rcx, rdx, rbx, rsp, rbp, rsi, rdi, r8, r9, r12, r13, r14, r15, zf, cf, x0, x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12, x13, x14, x15, mem, pc, ⟨r10, r11, u0, u1, u2, u3, u4, u5, u6, u7, u8, u9, u10, u11, u12, u13, u14, u15, z16, z17, z18, z19, z20, z21, z22, z23, z24, z25, z26, z27, z28, z29, z30, z31, k1, k2⟩⟩ := st
  simp only [State.zmm] at hpc hal a800 a840 a880 a8C0 a900 hbx hs ht0 ht1 ht2 ht3 hz14 hz13 ha0 ha1 ha2 ha3 ha4 ha5 ha6 ha7 hb0 hb1 hb2 hb3 hb4 hb5 hb6
  subst hpc hbx
  have e0 : x0 = zlo (zpack (fun i => (cA i)[0])) := by rw [← ha0, zlo_zjoin]
  have f0 : u0 = zhi (zpack (fun i => (cA i)[0])) := by rw [← ha0, zhi_zjoin]
  subst e0 f0
  have e1 : x1 = zlo (zpack (fun i => (cA i)[1])) := by rw [← ha1, zlo_zjoin]
  have f1 : u1 = zhi (zpack (fun i => (cA i)[1])) := by rw [← ha1, zhi_zjoin]
  subst e1 f1
  have e2 : x2 = zlo (zpack (fun i => (cA i)[2])) := by rw [← ha2, zlo_zjoin]
  have f2 : u2 = zhi (zpack (fun i => (cA i)[2])) := by rw [← ha2, zhi_zjoin]
  subst e2 f2
  have e3 : x3 = zlo (zpack (fun i => (cA i)[3])) := by rw [← ha3, zlo_zjoin]
  have f3 : u3 = zhi (zpack (fun i => (cA i)[3])) := by rw [← ha3, zhi_zjoin]
  subst e3 f3
  have e4 : x4 = zlo (zpack (fun i => (cA i)[4])) := by rw [← ha4, zlo_zjoin]
  have f4 : u4 = zhi (zpack (fun i => (cA i)[4])) := by rw [← ha4, zhi_zjoin]
  subst e4 f4
  have e5 : x5 = zlo (zpack (fun i => (cA i)[5])) := by rw [← ha5, zlo_zjoin]
  have f5 : u5 = zhi (zpack (fun i => (cA i)[5])) := by rw [← ha5, zhi_zjoin]
  subst e5 f5
  have e6 : x6 = zlo (zpack (fun i => (cA i)[6])) := by rw [← ha6, zlo_zjoin]
  have f6 : u6 = zhi (zpack (fun i => (cA i)[6])) := by rw [← ha6, zhi_zjoin]
  subst e6 f6
  have e7 : x7 = zlo (zpack (fun i => (cA i)[7])) := by rw [← ha7, zlo_zjoin]
  have f7 : u7 = zhi (zpack (fun i => (cA i)[7])) := by rw [← ha7, zhi_zjoin]
  subst e7 f7
  have e8 : x8 = zlo (zpack (fun i => (cB i)[0])) := by rw [← hb0, zlo_zjoin]
  have f8 : u8 = zhi (zpack (fun i => (cB i)[0])) := by rw [← hb0, zhi_zjoin]
  subst e8 f8
  have e9 : x9 = zlo (zpack (fun i => (cB i)[1])) := by rw [← hb1, zlo_zjoin]
  have f9 : u9 = zhi (zpack (fun i => (cB i)[1])) := by rw [← hb1, zhi_zjoin]
  subst e9 f9
  have e10 : x10 = zlo (zpack (fun i => (cB i)[2])) := by rw [← hb2, zlo_zjoin]
  have f10 : u10 = zhi (zpack (fun i => (cB i)[2])) := by rw [← hb2, zhi_zjoin]
  subst e10 f10
  have e11 : x11 = zlo (zpack (fun i => (cB i)[3])) := by rw [← hb3, zlo_zjoin]
  have f11 : u11 = zhi (zpack (fun i => (cB i)[3])) := by rw [← hb3, zhi_zjoin]
  subst e11 f11
  have e12 : x12 = zlo (zpack (fun i => (cB i)[4])) := by rw [← hb4, zlo_zjoin]
  have f12 : u12 = zhi (zpack (fun i => (cB i)[4])) := by rw [← hb4, zhi_zjoin]
  subst e12 f12
  have e13 : x13 = zlo (zpack (fun i => (cB i)[5])) := by rw [← hb5, zlo_zjoin]
  have f13 : u13 = zhi (zpack (fun i => (cB i)[5])) := by rw [← hb5, zhi_zjoin]
  subst e13 f13
  have e14 : x14 = zlo (zpack (fun i => (cB i)[6])) := by rw [← hb6, zlo_zjoin]
  have f14 : u14 = zhi (zpack (fun i => (cB i)[6])) := by rw [← hb6, zhi_zjoin]
  subst e14 f14
  run_fn [a800, a840, a880, a8C0, a900, hs, ht0, ht1, ht2, ht3, hz14, hz13, zjoin_split, zlo_zjoin, zhi_zjoin]
  refine ⟨_, rfl, rfl, rfl, ?_, ?_, rfl, rfl, rfl, rfl, rfl, rfl, rfl, rfl, rfl, rfl, rfl⟩
  · simp only [RowsAV, RowsA, State.zmm, zjoin_split, initv, zbroadcast, Vector.getElem_mk, List.getElem_toArray, List.getElem_cons_succ, List.getElem_cons_zero]
    refine ⟨?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_⟩ <;> first | rfl | trivial | (exact congrArg zpack (funext fun _ => by bv_decide))
  · simp only [RowsBV, RowsB, State.zmm, zjoin_split, initv, zbroadcast, Vector.getElem_mk, List.getElem_toArray, List.getElem_cons_succ, List.getElem_cons_zero]
    refine ⟨?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_⟩ <;> first | rfl | trivial | (exact congrArg zpack (funext fun _ => by bv_decide))

set_option maxRecDepth 1000000 in
set_option maxHeartbeats 0 in
/-- **A block's set-up, for the chunk's last block (the end flag)** (0x10829 to 0x10900, 32 instructions). -/
theorem hdr_last (cA cB : Nat → Vector (BitVec 32) 8) (tA tB : Nat → BitVec 64) (flags : BitVec 64) (st : State)
    (hpc : st.pc = 0x10829) (hal : aligned64 st.rsp = true)
    (hbx : st.rbx = flags ||| 0x40020100#64) (hf : flags < 256#64)
    (hz14 : (st.r14 &&& st.r14 == 0#64) = false) (hr13 : st.r13 = 1#64)
    (ha : CvA st cA) (hb : CvB7 st cB) (hs : st.mem.read512 (st.rsp + 0x900#64) = some (zpack fun i => (cB i)[7]))
    (ht : Counters st.mem st.rsp tA tB) :
    ∃ st', steps Code_k32.prog 32 st = some st' ∧ st'.pc = 0x10900 ∧ st'.w.r11 = 7#64 ∧ st'.rdi = 0x500000C0#64 ∧
      RowsAV st' (fun i => initv (cA i) (tA i) 64#32 (flags.setWidth 32 ||| 2#32)) ∧ RowsBV st' (fun i => initv (cB i) (tB i) 64#32 (flags.setWidth 32 ||| 2#32)) ∧
      st'.rbx = st.rbx ∧ st'.rsp = st.rsp ∧ st'.rbp = st.rbp ∧ st'.rsi = st.rsi ∧ st'.r9 = st.r9 ∧ st'.r12 = st.r12 ∧ st'.r13 = st.r13 ∧ st'.r14 = st.r14 ∧ st'.r15 = st.r15 ∧ st'.w.r10 = st.w.r10 ∧ st'.mem = st.mem := by
  have a800 : aligned64 (st.rsp + 0x800#64) = true := aligned64_add hal (by decide)
  have a840 : aligned64 (st.rsp + 0x840#64) = true := aligned64_add hal (by decide)
  have a880 : aligned64 (st.rsp + 0x880#64) = true := aligned64_add hal (by decide)
  have a8C0 : aligned64 (st.rsp + 0x8C0#64) = true := aligned64_add hal (by decide)
  have a900 : aligned64 (st.rsp + 0x900#64) = true := aligned64_add hal (by decide)
  obtain ⟨ha0, ha1, ha2, ha3, ha4, ha5, ha6, ha7⟩ := ha
  obtain ⟨hb0, hb1, hb2, hb3, hb4, hb5, hb6⟩ := hb
  obtain ⟨ht0, ht1, ht2, ht3⟩ := ht
  obtain ⟨rax, rcx, rdx, rbx, rsp, rbp, rsi, rdi, r8, r9, r12, r13, r14, r15, zf, cf, x0, x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12, x13, x14, x15, mem, pc, ⟨r10, r11, u0, u1, u2, u3, u4, u5, u6, u7, u8, u9, u10, u11, u12, u13, u14, u15, z16, z17, z18, z19, z20, z21, z22, z23, z24, z25, z26, z27, z28, z29, z30, z31, k1, k2⟩⟩ := st
  simp only [State.zmm] at hpc hal a800 a840 a880 a8C0 a900 hbx hs ht0 ht1 ht2 ht3 hz14 hr13 ha0 ha1 ha2 ha3 ha4 ha5 ha6 ha7 hb0 hb1 hb2 hb3 hb4 hb5 hb6
  subst hpc hbx hr13
  have e0 : x0 = zlo (zpack (fun i => (cA i)[0])) := by rw [← ha0, zlo_zjoin]
  have f0 : u0 = zhi (zpack (fun i => (cA i)[0])) := by rw [← ha0, zhi_zjoin]
  subst e0 f0
  have e1 : x1 = zlo (zpack (fun i => (cA i)[1])) := by rw [← ha1, zlo_zjoin]
  have f1 : u1 = zhi (zpack (fun i => (cA i)[1])) := by rw [← ha1, zhi_zjoin]
  subst e1 f1
  have e2 : x2 = zlo (zpack (fun i => (cA i)[2])) := by rw [← ha2, zlo_zjoin]
  have f2 : u2 = zhi (zpack (fun i => (cA i)[2])) := by rw [← ha2, zhi_zjoin]
  subst e2 f2
  have e3 : x3 = zlo (zpack (fun i => (cA i)[3])) := by rw [← ha3, zlo_zjoin]
  have f3 : u3 = zhi (zpack (fun i => (cA i)[3])) := by rw [← ha3, zhi_zjoin]
  subst e3 f3
  have e4 : x4 = zlo (zpack (fun i => (cA i)[4])) := by rw [← ha4, zlo_zjoin]
  have f4 : u4 = zhi (zpack (fun i => (cA i)[4])) := by rw [← ha4, zhi_zjoin]
  subst e4 f4
  have e5 : x5 = zlo (zpack (fun i => (cA i)[5])) := by rw [← ha5, zlo_zjoin]
  have f5 : u5 = zhi (zpack (fun i => (cA i)[5])) := by rw [← ha5, zhi_zjoin]
  subst e5 f5
  have e6 : x6 = zlo (zpack (fun i => (cA i)[6])) := by rw [← ha6, zlo_zjoin]
  have f6 : u6 = zhi (zpack (fun i => (cA i)[6])) := by rw [← ha6, zhi_zjoin]
  subst e6 f6
  have e7 : x7 = zlo (zpack (fun i => (cA i)[7])) := by rw [← ha7, zlo_zjoin]
  have f7 : u7 = zhi (zpack (fun i => (cA i)[7])) := by rw [← ha7, zhi_zjoin]
  subst e7 f7
  have e8 : x8 = zlo (zpack (fun i => (cB i)[0])) := by rw [← hb0, zlo_zjoin]
  have f8 : u8 = zhi (zpack (fun i => (cB i)[0])) := by rw [← hb0, zhi_zjoin]
  subst e8 f8
  have e9 : x9 = zlo (zpack (fun i => (cB i)[1])) := by rw [← hb1, zlo_zjoin]
  have f9 : u9 = zhi (zpack (fun i => (cB i)[1])) := by rw [← hb1, zhi_zjoin]
  subst e9 f9
  have e10 : x10 = zlo (zpack (fun i => (cB i)[2])) := by rw [← hb2, zlo_zjoin]
  have f10 : u10 = zhi (zpack (fun i => (cB i)[2])) := by rw [← hb2, zhi_zjoin]
  subst e10 f10
  have e11 : x11 = zlo (zpack (fun i => (cB i)[3])) := by rw [← hb3, zlo_zjoin]
  have f11 : u11 = zhi (zpack (fun i => (cB i)[3])) := by rw [← hb3, zhi_zjoin]
  subst e11 f11
  have e12 : x12 = zlo (zpack (fun i => (cB i)[4])) := by rw [← hb4, zlo_zjoin]
  have f12 : u12 = zhi (zpack (fun i => (cB i)[4])) := by rw [← hb4, zhi_zjoin]
  subst e12 f12
  have e13 : x13 = zlo (zpack (fun i => (cB i)[5])) := by rw [← hb5, zlo_zjoin]
  have f13 : u13 = zhi (zpack (fun i => (cB i)[5])) := by rw [← hb5, zhi_zjoin]
  subst e13 f13
  have e14 : x14 = zlo (zpack (fun i => (cB i)[6])) := by rw [← hb6, zlo_zjoin]
  have f14 : u14 = zhi (zpack (fun i => (cB i)[6])) := by rw [← hb6, zhi_zjoin]
  subst e14 f14
  run_fn [a800, a840, a880, a8C0, a900, hs, ht0, ht1, ht2, ht3, hz14, zjoin_split, zlo_zjoin, zhi_zjoin]
  refine ⟨_, rfl, rfl, rfl, ?_, ?_, rfl, rfl, rfl, rfl, rfl, rfl, rfl, rfl, rfl, rfl, rfl⟩
  · simp only [RowsAV, RowsA, State.zmm, zjoin_split, initv, zbroadcast, Vector.getElem_mk, List.getElem_toArray, List.getElem_cons_succ, List.getElem_cons_zero]
    refine ⟨?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_⟩ <;> first | rfl | trivial | (exact congrArg zpack (funext fun _ => by bv_decide))
  · simp only [RowsBV, RowsB, State.zmm, zjoin_split, initv, zbroadcast, Vector.getElem_mk, List.getElem_toArray, List.getElem_cons_succ, List.getElem_cons_zero]
    refine ⟨?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_⟩ <;> first | rfl | trivial | (exact congrArg zpack (funext fun _ => by bv_decide))

set_option maxRecDepth 1000000 in
set_option maxHeartbeats 0 in
/-- **A block's end, with blocks to come: back to the block loop's head** (0x10EF0, 19 instructions): the new chaining value of every lane is
the two halves of its state, xored; the block offset moves on by 64. -/
theorem ff_next (v w : Nat → Vector (BitVec 32) 16) (st : State) (hpc : st.pc = 0x10EF0) (hz13 : (st.r13 - 1#64 == 0#64) = false)
    (ha : RowsAV st v) (hb : RowsBV st w) :
    ∃ st', steps Code_k32.prog 19 st = some st' ∧ st'.pc = 0x10133 ∧ st'.r13 = st.r13 - 1#64 ∧ st'.r14 = st.r14 + 0x40#64 ∧
      CvA st' (fun i => low8 (v i)) ∧ CvB st' (fun i => low8 (w i)) ∧
      st'.rbx = st.rbx ∧ st'.rsp = st.rsp ∧ st'.rbp = st.rbp ∧ st'.rsi = st.rsi ∧ st'.r9 = st.r9 ∧ st'.r12 = st.r12 ∧ st'.r15 = st.r15 ∧ st'.w.r10 = st.w.r10 ∧ st'.mem = st.mem := by
  obtain ⟨ha0, ha1, ha2, ha3, ha4, ha5, ha6, ha7, ha8, ha9, ha10, ha11, ha12, ha13, ha14, ha15⟩ := ha
  obtain ⟨hb0, hb1, hb2, hb3, hb4, hb5, hb6, hb7, hb8, hb9, hb10, hb11, hb12, hb13, hb14, hb15⟩ := hb
  obtain ⟨rax, rcx, rdx, rbx, rsp, rbp, rsi, rdi, r8, r9, r12, r13, r14, r15, zf, cf, x0, x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12, x13, x14, x15, mem, pc, ⟨r10, r11, u0, u1, u2, u3, u4, u5, u6, u7, u8, u9, u10, u11, u12, u13, u14, u15, z16, z17, z18, z19, z20, z21, z22, z23, z24, z25, z26, z27, z28, z29, z30, z31, k1, k2⟩⟩ := st
  simp only [State.zmm] at hpc hz13 ha0 hb0 ha1 hb1 ha2 hb2 ha3 hb3 ha4 hb4 ha5 hb5 ha6 hb6 ha7 hb7 ha8 hb8 ha9 hb9 ha10 hb10 ha11 hb11 ha12 hb12 ha13 hb13 ha14 hb14 ha15 hb15
  subst hpc
  have e0 : x0 = zlo (zpack (fun i => (v i)[0])) := by rw [← ha0, zlo_zjoin]
  have f0 : u0 = zhi (zpack (fun i => (v i)[0])) := by rw [← ha0, zhi_zjoin]
  subst e0 f0
  have e1 : x1 = zlo (zpack (fun i => (v i)[1])) := by rw [← ha1, zlo_zjoin]
  have f1 : u1 = zhi (zpack (fun i => (v i)[1])) := by rw [← ha1, zhi_zjoin]
  subst e1 f1
  have e2 : x2 = zlo (zpack (fun i => (v i)[2])) := by rw [← ha2, zlo_zjoin]
  have f2 : u2 = zhi (zpack (fun i => (v i)[2])) := by rw [← ha2, zhi_zjoin]
  subst e2 f2
  have e3 : x3 = zlo (zpack (fun i => (v i)[3])) := by rw [← ha3, zlo_zjoin]
  have f3 : u3 = zhi (zpack (fun i => (v i)[3])) := by rw [← ha3, zhi_zjoin]
  subst e3 f3
  have e4 : x4 = zlo (zpack (fun i => (v i)[4])) := by rw [← ha4, zlo_zjoin]
  have f4 : u4 = zhi (zpack (fun i => (v i)[4])) := by rw [← ha4, zhi_zjoin]
  subst e4 f4
  have e5 : x5 = zlo (zpack (fun i => (v i)[5])) := by rw [← ha5, zlo_zjoin]
  have f5 : u5 = zhi (zpack (fun i => (v i)[5])) := by rw [← ha5, zhi_zjoin]
  subst e5 f5
  have e6 : x6 = zlo (zpack (fun i => (v i)[6])) := by rw [← ha6, zlo_zjoin]
  have f6 : u6 = zhi (zpack (fun i => (v i)[6])) := by rw [← ha6, zhi_zjoin]
  subst e6 f6
  have e7 : x7 = zlo (zpack (fun i => (v i)[7])) := by rw [← ha7, zlo_zjoin]
  have f7 : u7 = zhi (zpack (fun i => (v i)[7])) := by rw [← ha7, zhi_zjoin]
  subst e7 f7
  subst ha8
  subst ha9
  subst ha10
  subst ha11
  subst ha12
  subst ha13
  subst ha14
  subst ha15
  have e8 : x8 = zlo (zpack (fun i => (w i)[0])) := by rw [← hb0, zlo_zjoin]
  have f8 : u8 = zhi (zpack (fun i => (w i)[0])) := by rw [← hb0, zhi_zjoin]
  subst e8 f8
  have e9 : x9 = zlo (zpack (fun i => (w i)[1])) := by rw [← hb1, zlo_zjoin]
  have f9 : u9 = zhi (zpack (fun i => (w i)[1])) := by rw [← hb1, zhi_zjoin]
  subst e9 f9
  have e10 : x10 = zlo (zpack (fun i => (w i)[2])) := by rw [← hb2, zlo_zjoin]
  have f10 : u10 = zhi (zpack (fun i => (w i)[2])) := by rw [← hb2, zhi_zjoin]
  subst e10 f10
  have e11 : x11 = zlo (zpack (fun i => (w i)[3])) := by rw [← hb3, zlo_zjoin]
  have f11 : u11 = zhi (zpack (fun i => (w i)[3])) := by rw [← hb3, zhi_zjoin]
  subst e11 f11
  have e12 : x12 = zlo (zpack (fun i => (w i)[4])) := by rw [← hb4, zlo_zjoin]
  have f12 : u12 = zhi (zpack (fun i => (w i)[4])) := by rw [← hb4, zhi_zjoin]
  subst e12 f12
  have e13 : x13 = zlo (zpack (fun i => (w i)[5])) := by rw [← hb5, zlo_zjoin]
  have f13 : u13 = zhi (zpack (fun i => (w i)[5])) := by rw [← hb5, zhi_zjoin]
  subst e13 f13
  have e14 : x14 = zlo (zpack (fun i => (w i)[6])) := by rw [← hb6, zlo_zjoin]
  have f14 : u14 = zhi (zpack (fun i => (w i)[6])) := by rw [← hb6, zhi_zjoin]
  subst e14 f14
  have e15 : x15 = zlo (zpack (fun i => (w i)[7])) := by rw [← hb7, zlo_zjoin]
  have f15 : u15 = zhi (zpack (fun i => (w i)[7])) := by rw [← hb7, zhi_zjoin]
  subst e15 f15
  subst hb8
  subst hb9
  subst hb10
  subst hb11
  subst hb12
  subst hb13
  subst hb14
  subst hb15
  run_fn [hz13, zjoin_split, zlo_zjoin, zhi_zjoin, zxor_pack]
  refine ⟨_, rfl, rfl, rfl, ?_, ?_, rfl, rfl, rfl, rfl, rfl, rfl, rfl, rfl, rfl⟩
  · simp only [CvA, State.zmm, zjoin_split, low8, Vector.getElem_mk, List.getElem_toArray, List.getElem_cons_succ, List.getElem_cons_zero, and_self]
  · simp only [CvB, State.zmm, zjoin_split, low8, Vector.getElem_mk, List.getElem_toArray, List.getElem_cons_succ, List.getElem_cons_zero, and_self]

set_option maxRecDepth 1000000 in
set_option maxHeartbeats 0 in
/-- **A block's end, after the last block: out of the loop** (0x10EF0, 19 instructions): the new chaining value of every lane is
the two halves of its state, xored; the block offset moves on by 64. -/
theorem ff_done (v w : Nat → Vector (BitVec 32) 16) (st : State) (hpc : st.pc = 0x10EF0) (hr13 : st.r13 = 1#64)
    (ha : RowsAV st v) (hb : RowsBV st w) :
    ∃ st', steps Code_k32.prog 19 st = some st' ∧ st'.pc = 0x10F5D ∧ st'.r13 = st.r13 - 1#64 ∧ st'.r14 = st.r14 + 0x40#64 ∧
      CvA st' (fun i => low8 (v i)) ∧ CvB st' (fun i => low8 (w i)) ∧
      st'.rbx = st.rbx ∧ st'.rsp = st.rsp ∧ st'.rbp = st.rbp ∧ st'.rsi = st.rsi ∧ st'.r9 = st.r9 ∧ st'.r12 = st.r12 ∧ st'.r15 = st.r15 ∧ st'.w.r10 = st.w.r10 ∧ st'.mem = st.mem := by
  obtain ⟨ha0, ha1, ha2, ha3, ha4, ha5, ha6, ha7, ha8, ha9, ha10, ha11, ha12, ha13, ha14, ha15⟩ := ha
  obtain ⟨hb0, hb1, hb2, hb3, hb4, hb5, hb6, hb7, hb8, hb9, hb10, hb11, hb12, hb13, hb14, hb15⟩ := hb
  obtain ⟨rax, rcx, rdx, rbx, rsp, rbp, rsi, rdi, r8, r9, r12, r13, r14, r15, zf, cf, x0, x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12, x13, x14, x15, mem, pc, ⟨r10, r11, u0, u1, u2, u3, u4, u5, u6, u7, u8, u9, u10, u11, u12, u13, u14, u15, z16, z17, z18, z19, z20, z21, z22, z23, z24, z25, z26, z27, z28, z29, z30, z31, k1, k2⟩⟩ := st
  simp only [State.zmm] at hpc hr13 ha0 hb0 ha1 hb1 ha2 hb2 ha3 hb3 ha4 hb4 ha5 hb5 ha6 hb6 ha7 hb7 ha8 hb8 ha9 hb9 ha10 hb10 ha11 hb11 ha12 hb12 ha13 hb13 ha14 hb14 ha15 hb15
  subst hpc hr13
  have e0 : x0 = zlo (zpack (fun i => (v i)[0])) := by rw [← ha0, zlo_zjoin]
  have f0 : u0 = zhi (zpack (fun i => (v i)[0])) := by rw [← ha0, zhi_zjoin]
  subst e0 f0
  have e1 : x1 = zlo (zpack (fun i => (v i)[1])) := by rw [← ha1, zlo_zjoin]
  have f1 : u1 = zhi (zpack (fun i => (v i)[1])) := by rw [← ha1, zhi_zjoin]
  subst e1 f1
  have e2 : x2 = zlo (zpack (fun i => (v i)[2])) := by rw [← ha2, zlo_zjoin]
  have f2 : u2 = zhi (zpack (fun i => (v i)[2])) := by rw [← ha2, zhi_zjoin]
  subst e2 f2
  have e3 : x3 = zlo (zpack (fun i => (v i)[3])) := by rw [← ha3, zlo_zjoin]
  have f3 : u3 = zhi (zpack (fun i => (v i)[3])) := by rw [← ha3, zhi_zjoin]
  subst e3 f3
  have e4 : x4 = zlo (zpack (fun i => (v i)[4])) := by rw [← ha4, zlo_zjoin]
  have f4 : u4 = zhi (zpack (fun i => (v i)[4])) := by rw [← ha4, zhi_zjoin]
  subst e4 f4
  have e5 : x5 = zlo (zpack (fun i => (v i)[5])) := by rw [← ha5, zlo_zjoin]
  have f5 : u5 = zhi (zpack (fun i => (v i)[5])) := by rw [← ha5, zhi_zjoin]
  subst e5 f5
  have e6 : x6 = zlo (zpack (fun i => (v i)[6])) := by rw [← ha6, zlo_zjoin]
  have f6 : u6 = zhi (zpack (fun i => (v i)[6])) := by rw [← ha6, zhi_zjoin]
  subst e6 f6
  have e7 : x7 = zlo (zpack (fun i => (v i)[7])) := by rw [← ha7, zlo_zjoin]
  have f7 : u7 = zhi (zpack (fun i => (v i)[7])) := by rw [← ha7, zhi_zjoin]
  subst e7 f7
  subst ha8
  subst ha9
  subst ha10
  subst ha11
  subst ha12
  subst ha13
  subst ha14
  subst ha15
  have e8 : x8 = zlo (zpack (fun i => (w i)[0])) := by rw [← hb0, zlo_zjoin]
  have f8 : u8 = zhi (zpack (fun i => (w i)[0])) := by rw [← hb0, zhi_zjoin]
  subst e8 f8
  have e9 : x9 = zlo (zpack (fun i => (w i)[1])) := by rw [← hb1, zlo_zjoin]
  have f9 : u9 = zhi (zpack (fun i => (w i)[1])) := by rw [← hb1, zhi_zjoin]
  subst e9 f9
  have e10 : x10 = zlo (zpack (fun i => (w i)[2])) := by rw [← hb2, zlo_zjoin]
  have f10 : u10 = zhi (zpack (fun i => (w i)[2])) := by rw [← hb2, zhi_zjoin]
  subst e10 f10
  have e11 : x11 = zlo (zpack (fun i => (w i)[3])) := by rw [← hb3, zlo_zjoin]
  have f11 : u11 = zhi (zpack (fun i => (w i)[3])) := by rw [← hb3, zhi_zjoin]
  subst e11 f11
  have e12 : x12 = zlo (zpack (fun i => (w i)[4])) := by rw [← hb4, zlo_zjoin]
  have f12 : u12 = zhi (zpack (fun i => (w i)[4])) := by rw [← hb4, zhi_zjoin]
  subst e12 f12
  have e13 : x13 = zlo (zpack (fun i => (w i)[5])) := by rw [← hb5, zlo_zjoin]
  have f13 : u13 = zhi (zpack (fun i => (w i)[5])) := by rw [← hb5, zhi_zjoin]
  subst e13 f13
  have e14 : x14 = zlo (zpack (fun i => (w i)[6])) := by rw [← hb6, zlo_zjoin]
  have f14 : u14 = zhi (zpack (fun i => (w i)[6])) := by rw [← hb6, zhi_zjoin]
  subst e14 f14
  have e15 : x15 = zlo (zpack (fun i => (w i)[7])) := by rw [← hb7, zlo_zjoin]
  have f15 : u15 = zhi (zpack (fun i => (w i)[7])) := by rw [← hb7, zhi_zjoin]
  subst e15 f15
  subst hb8
  subst hb9
  subst hb10
  subst hb11
  subst hb12
  subst hb13
  subst hb14
  subst hb15
  run_fn [zjoin_split, zlo_zjoin, zhi_zjoin, zxor_pack]
  refine ⟨_, rfl, rfl, rfl, ?_, ?_, rfl, rfl, rfl, rfl, rfl, rfl, rfl, rfl, rfl⟩
  · simp only [CvA, State.zmm, zjoin_split, low8, Vector.getElem_mk, List.getElem_toArray, List.getElem_cons_succ, List.getElem_cons_zero, and_self]
  · simp only [CvB, State.zmm, zjoin_split, low8, Vector.getElem_mk, List.getElem_toArray, List.getElem_cons_succ, List.getElem_cons_zero, and_self]

end K32
