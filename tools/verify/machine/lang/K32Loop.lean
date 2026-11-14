import K32Round
open X86 Cells Blake3Generic

/-! # The round loop of the 32-lane chunk kernel is the specification's seven rounds

Written by gen_k32.py from the kernel's lifted instructions and the object's read-only data. A turn of the loop
is a round (K32Round.lean) with the message words at the offsets of one row of the kernel's schedule table,
then `rdi` moved to the next row. The table's rows are the specification's message permutation, applied
0 to 6 times: checked here, row by row, when this file is written, and by Lean in `perm1` to `perm6`. -/

namespace K32

/-- The state words of the first half's lanes, as one vector a lane. -/
abbrev RowsAV (st : State) (v : Nat → Vector (BitVec 32) 16) : Prop :=
  RowsA st (fun i => (v i)[0]) (fun i => (v i)[1]) (fun i => (v i)[2]) (fun i => (v i)[3]) (fun i => (v i)[4]) (fun i => (v i)[5]) (fun i => (v i)[6]) (fun i => (v i)[7]) (fun i => (v i)[8]) (fun i => (v i)[9]) (fun i => (v i)[10]) (fun i => (v i)[11]) (fun i => (v i)[12]) (fun i => (v i)[13]) (fun i => (v i)[14]) (fun i => (v i)[15])

/-- The state words of the second half's lanes, as one vector a lane. -/
abbrev RowsBV (st : State) (v : Nat → Vector (BitVec 32) 16) : Prop :=
  RowsB st (fun i => (v i)[0]) (fun i => (v i)[1]) (fun i => (v i)[2]) (fun i => (v i)[3]) (fun i => (v i)[4]) (fun i => (v i)[5]) (fun i => (v i)[6]) (fun i => (v i)[7]) (fun i => (v i)[8]) (fun i => (v i)[9]) (fun i => (v i)[10]) (fun i => (v i)[11]) (fun i => (v i)[12]) (fun i => (v i)[13]) (fun i => (v i)[14]) (fun i => (v i)[15])

/-- The lanes' message words where the block loop puts them: word `k` of the first half's lanes (lane `i`'s
in lane `i`) at `a + 64 k`, of the second half's 1024 bytes on. -/
def BlocksAt (mem : Mem) (a : BitVec 64) (m n : Nat → Vector (BitVec 32) 16) : Prop :=
  mem.read512 (a) = some (zpack fun i => (m i)[0]) ∧ mem.read512 (a + 0x40#64) = some (zpack fun i => (m i)[1]) ∧ mem.read512 (a + 0x80#64) = some (zpack fun i => (m i)[2]) ∧ mem.read512 (a + 0xC0#64) = some (zpack fun i => (m i)[3]) ∧ mem.read512 (a + 0x100#64) = some (zpack fun i => (m i)[4]) ∧ mem.read512 (a + 0x140#64) = some (zpack fun i => (m i)[5]) ∧ mem.read512 (a + 0x180#64) = some (zpack fun i => (m i)[6]) ∧ mem.read512 (a + 0x1C0#64) = some (zpack fun i => (m i)[7]) ∧ mem.read512 (a + 0x200#64) = some (zpack fun i => (m i)[8]) ∧ mem.read512 (a + 0x240#64) = some (zpack fun i => (m i)[9]) ∧ mem.read512 (a + 0x280#64) = some (zpack fun i => (m i)[10]) ∧ mem.read512 (a + 0x2C0#64) = some (zpack fun i => (m i)[11]) ∧ mem.read512 (a + 0x300#64) = some (zpack fun i => (m i)[12]) ∧ mem.read512 (a + 0x340#64) = some (zpack fun i => (m i)[13]) ∧ mem.read512 (a + 0x380#64) = some (zpack fun i => (m i)[14]) ∧ mem.read512 (a + 0x3C0#64) = some (zpack fun i => (m i)[15]) ∧
  mem.read512 (a + 0x400#64) = some (zpack fun i => (n i)[0]) ∧ mem.read512 (a + 0x440#64) = some (zpack fun i => (n i)[1]) ∧ mem.read512 (a + 0x480#64) = some (zpack fun i => (n i)[2]) ∧ mem.read512 (a + 0x4C0#64) = some (zpack fun i => (n i)[3]) ∧ mem.read512 (a + 0x500#64) = some (zpack fun i => (n i)[4]) ∧ mem.read512 (a + 0x540#64) = some (zpack fun i => (n i)[5]) ∧ mem.read512 (a + 0x580#64) = some (zpack fun i => (n i)[6]) ∧ mem.read512 (a + 0x5C0#64) = some (zpack fun i => (n i)[7]) ∧ mem.read512 (a + 0x600#64) = some (zpack fun i => (n i)[8]) ∧ mem.read512 (a + 0x640#64) = some (zpack fun i => (n i)[9]) ∧ mem.read512 (a + 0x680#64) = some (zpack fun i => (n i)[10]) ∧ mem.read512 (a + 0x6C0#64) = some (zpack fun i => (n i)[11]) ∧ mem.read512 (a + 0x700#64) = some (zpack fun i => (n i)[12]) ∧ mem.read512 (a + 0x740#64) = some (zpack fun i => (n i)[13]) ∧ mem.read512 (a + 0x780#64) = some (zpack fun i => (n i)[14]) ∧ mem.read512 (a + 0x7C0#64) = some (zpack fun i => (n i)[15])

/-- The kernel's schedule table at `a`: seven rows of sixteen offsets, as the object's read-only data has them. -/
def SchedAt (mem : Mem) (a : BitVec 64) : Prop :=
  mem.read (a) 32 = some 0#64 ∧ mem.read (a + 0x4#64) 32 = some 64#64 ∧ mem.read (a + 0x8#64) 32 = some 128#64 ∧ mem.read (a + 0xC#64) 32 = some 192#64 ∧ mem.read (a + 0x10#64) 32 = some 256#64 ∧ mem.read (a + 0x14#64) 32 = some 320#64 ∧ mem.read (a + 0x18#64) 32 = some 384#64 ∧ mem.read (a + 0x1C#64) 32 = some 448#64 ∧ mem.read (a + 0x20#64) 32 = some 512#64 ∧ mem.read (a + 0x24#64) 32 = some 576#64 ∧ mem.read (a + 0x28#64) 32 = some 640#64 ∧ mem.read (a + 0x2C#64) 32 = some 704#64 ∧ mem.read (a + 0x30#64) 32 = some 768#64 ∧ mem.read (a + 0x34#64) 32 = some 832#64 ∧ mem.read (a + 0x38#64) 32 = some 896#64 ∧ mem.read (a + 0x3C#64) 32 = some 960#64 ∧
  mem.read (a + 0x40#64) 32 = some 128#64 ∧ mem.read (a + 0x44#64) 32 = some 384#64 ∧ mem.read (a + 0x48#64) 32 = some 192#64 ∧ mem.read (a + 0x4C#64) 32 = some 640#64 ∧ mem.read (a + 0x50#64) 32 = some 448#64 ∧ mem.read (a + 0x54#64) 32 = some 0#64 ∧ mem.read (a + 0x58#64) 32 = some 256#64 ∧ mem.read (a + 0x5C#64) 32 = some 832#64 ∧ mem.read (a + 0x60#64) 32 = some 64#64 ∧ mem.read (a + 0x64#64) 32 = some 704#64 ∧ mem.read (a + 0x68#64) 32 = some 768#64 ∧ mem.read (a + 0x6C#64) 32 = some 320#64 ∧ mem.read (a + 0x70#64) 32 = some 576#64 ∧ mem.read (a + 0x74#64) 32 = some 896#64 ∧ mem.read (a + 0x78#64) 32 = some 960#64 ∧ mem.read (a + 0x7C#64) 32 = some 512#64 ∧
  mem.read (a + 0x80#64) 32 = some 192#64 ∧ mem.read (a + 0x84#64) 32 = some 256#64 ∧ mem.read (a + 0x88#64) 32 = some 640#64 ∧ mem.read (a + 0x8C#64) 32 = some 768#64 ∧ mem.read (a + 0x90#64) 32 = some 832#64 ∧ mem.read (a + 0x94#64) 32 = some 128#64 ∧ mem.read (a + 0x98#64) 32 = some 448#64 ∧ mem.read (a + 0x9C#64) 32 = some 896#64 ∧ mem.read (a + 0xA0#64) 32 = some 384#64 ∧ mem.read (a + 0xA4#64) 32 = some 320#64 ∧ mem.read (a + 0xA8#64) 32 = some 576#64 ∧ mem.read (a + 0xAC#64) 32 = some 0#64 ∧ mem.read (a + 0xB0#64) 32 = some 704#64 ∧ mem.read (a + 0xB4#64) 32 = some 960#64 ∧ mem.read (a + 0xB8#64) 32 = some 512#64 ∧ mem.read (a + 0xBC#64) 32 = some 64#64 ∧
  mem.read (a + 0xC0#64) 32 = some 640#64 ∧ mem.read (a + 0xC4#64) 32 = some 448#64 ∧ mem.read (a + 0xC8#64) 32 = some 768#64 ∧ mem.read (a + 0xCC#64) 32 = some 576#64 ∧ mem.read (a + 0xD0#64) 32 = some 896#64 ∧ mem.read (a + 0xD4#64) 32 = some 192#64 ∧ mem.read (a + 0xD8#64) 32 = some 832#64 ∧ mem.read (a + 0xDC#64) 32 = some 960#64 ∧ mem.read (a + 0xE0#64) 32 = some 256#64 ∧ mem.read (a + 0xE4#64) 32 = some 0#64 ∧ mem.read (a + 0xE8#64) 32 = some 704#64 ∧ mem.read (a + 0xEC#64) 32 = some 128#64 ∧ mem.read (a + 0xF0#64) 32 = some 320#64 ∧ mem.read (a + 0xF4#64) 32 = some 512#64 ∧ mem.read (a + 0xF8#64) 32 = some 64#64 ∧ mem.read (a + 0xFC#64) 32 = some 384#64 ∧
  mem.read (a + 0x100#64) 32 = some 768#64 ∧ mem.read (a + 0x104#64) 32 = some 832#64 ∧ mem.read (a + 0x108#64) 32 = some 576#64 ∧ mem.read (a + 0x10C#64) 32 = some 704#64 ∧ mem.read (a + 0x110#64) 32 = some 960#64 ∧ mem.read (a + 0x114#64) 32 = some 640#64 ∧ mem.read (a + 0x118#64) 32 = some 896#64 ∧ mem.read (a + 0x11C#64) 32 = some 512#64 ∧ mem.read (a + 0x120#64) 32 = some 448#64 ∧ mem.read (a + 0x124#64) 32 = some 128#64 ∧ mem.read (a + 0x128#64) 32 = some 320#64 ∧ mem.read (a + 0x12C#64) 32 = some 192#64 ∧ mem.read (a + 0x130#64) 32 = some 0#64 ∧ mem.read (a + 0x134#64) 32 = some 64#64 ∧ mem.read (a + 0x138#64) 32 = some 384#64 ∧ mem.read (a + 0x13C#64) 32 = some 256#64 ∧
  mem.read (a + 0x140#64) 32 = some 576#64 ∧ mem.read (a + 0x144#64) 32 = some 896#64 ∧ mem.read (a + 0x148#64) 32 = some 704#64 ∧ mem.read (a + 0x14C#64) 32 = some 320#64 ∧ mem.read (a + 0x150#64) 32 = some 512#64 ∧ mem.read (a + 0x154#64) 32 = some 768#64 ∧ mem.read (a + 0x158#64) 32 = some 960#64 ∧ mem.read (a + 0x15C#64) 32 = some 64#64 ∧ mem.read (a + 0x160#64) 32 = some 832#64 ∧ mem.read (a + 0x164#64) 32 = some 192#64 ∧ mem.read (a + 0x168#64) 32 = some 0#64 ∧ mem.read (a + 0x16C#64) 32 = some 640#64 ∧ mem.read (a + 0x170#64) 32 = some 128#64 ∧ mem.read (a + 0x174#64) 32 = some 384#64 ∧ mem.read (a + 0x178#64) 32 = some 256#64 ∧ mem.read (a + 0x17C#64) 32 = some 448#64 ∧
  mem.read (a + 0x180#64) 32 = some 704#64 ∧ mem.read (a + 0x184#64) 32 = some 960#64 ∧ mem.read (a + 0x188#64) 32 = some 320#64 ∧ mem.read (a + 0x18C#64) 32 = some 0#64 ∧ mem.read (a + 0x190#64) 32 = some 64#64 ∧ mem.read (a + 0x194#64) 32 = some 576#64 ∧ mem.read (a + 0x198#64) 32 = some 512#64 ∧ mem.read (a + 0x19C#64) 32 = some 384#64 ∧ mem.read (a + 0x1A0#64) 32 = some 896#64 ∧ mem.read (a + 0x1A4#64) 32 = some 640#64 ∧ mem.read (a + 0x1A8#64) 32 = some 128#64 ∧ mem.read (a + 0x1AC#64) 32 = some 768#64 ∧ mem.read (a + 0x1B0#64) 32 = some 192#64 ∧ mem.read (a + 0x1B4#64) 32 = some 256#64 ∧ mem.read (a + 0x1B8#64) 32 = some 448#64 ∧ mem.read (a + 0x1BC#64) 32 = some 832#64

theorem perm1 (v : Vector (BitVec 32) 16) : PERMUTE v = #v[v[2], v[6], v[3], v[10], v[7], v[0], v[4], v[13], v[1], v[11], v[12], v[5], v[9], v[14], v[15], v[8]] := by
  ext i hi; rcases i with _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | i
  all_goals first
    | omega
    | eval_spec

theorem perm2 (v : Vector (BitVec 32) 16) : PERMUTE (PERMUTE v) = #v[v[3], v[4], v[10], v[12], v[13], v[2], v[7], v[14], v[6], v[5], v[9], v[0], v[11], v[15], v[8], v[1]] := by
  rw [perm1, perm1]
  ext i hi; rcases i with _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | i
  all_goals first
    | omega
    | (simp only [Vector.getElem_mk, List.getElem_toArray, List.getElem_cons_succ, List.getElem_cons_zero])

theorem perm3 (v : Vector (BitVec 32) 16) : PERMUTE (PERMUTE (PERMUTE v)) = #v[v[10], v[7], v[12], v[9], v[14], v[3], v[13], v[15], v[4], v[0], v[11], v[2], v[5], v[8], v[1], v[6]] := by
  rw [perm2, perm1]
  ext i hi; rcases i with _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | i
  all_goals first
    | omega
    | (simp only [Vector.getElem_mk, List.getElem_toArray, List.getElem_cons_succ, List.getElem_cons_zero])

theorem perm4 (v : Vector (BitVec 32) 16) : PERMUTE (PERMUTE (PERMUTE (PERMUTE v))) = #v[v[12], v[13], v[9], v[11], v[15], v[10], v[14], v[8], v[7], v[2], v[5], v[3], v[0], v[1], v[6], v[4]] := by
  rw [perm3, perm1]
  ext i hi; rcases i with _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | i
  all_goals first
    | omega
    | (simp only [Vector.getElem_mk, List.getElem_toArray, List.getElem_cons_succ, List.getElem_cons_zero])

theorem perm5 (v : Vector (BitVec 32) 16) : PERMUTE (PERMUTE (PERMUTE (PERMUTE (PERMUTE v)))) = #v[v[9], v[14], v[11], v[5], v[8], v[12], v[15], v[1], v[13], v[3], v[0], v[10], v[2], v[6], v[4], v[7]] := by
  rw [perm4, perm1]
  ext i hi; rcases i with _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | i
  all_goals first
    | omega
    | (simp only [Vector.getElem_mk, List.getElem_toArray, List.getElem_cons_succ, List.getElem_cons_zero])

theorem perm6 (v : Vector (BitVec 32) 16) : PERMUTE (PERMUTE (PERMUTE (PERMUTE (PERMUTE (PERMUTE v))))) = #v[v[11], v[15], v[5], v[0], v[1], v[9], v[8], v[6], v[14], v[10], v[2], v[12], v[3], v[4], v[7], v[13]] := by
  rw [perm5, perm1]
  ext i hi; rcases i with _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | _ | i
  all_goals first
    | omega
    | (simp only [Vector.getElem_mk, List.getElem_toArray, List.getElem_cons_succ, List.getElem_cons_zero])

private theorem rowsA_zmm_eq {p q : State} {s0 s1 s2 s3 s4 s5 s6 s7 s8 s9 s10 s11 s12 s13 s14 s15 : Nat → BitVec 32}
    (hz : ∀ r, q.zmm r = p.zmm r) (hv : RowsA p s0 s1 s2 s3 s4 s5 s6 s7 s8 s9 s10 s11 s12 s13 s14 s15) : RowsA q s0 s1 s2 s3 s4 s5 s6 s7 s8 s9 s10 s11 s12 s13 s14 s15 := by
  simp only [RowsA, hz] at hv ⊢; exact hv

private theorem rowsB_zmm_eq {p q : State} {s0 s1 s2 s3 s4 s5 s6 s7 s8 s9 s10 s11 s12 s13 s14 s15 : Nat → BitVec 32}
    (hz : ∀ r, q.zmm r = p.zmm r) (hv : RowsB p s0 s1 s2 s3 s4 s5 s6 s7 s8 s9 s10 s11 s12 s13 s14 s15) : RowsB q s0 s1 s2 s3 s4 s5 s6 s7 s8 s9 s10 s11 s12 s13 s14 s15 := by
  simp only [RowsB, hz] at hv ⊢; exact hv

set_option maxRecDepth 1000000 in
/-- The loop's end when rounds remain (0x10EE3, 3 instructions): `rdi` to the next row, back to the head. -/
private theorem tail_next (c : BitVec 64) (st : State) (hpc : st.pc = 0x10EE3) (hr11 : st.w.r11 = c)
    (hc : c = 7#64 ∨ c = 6#64 ∨ c = 5#64 ∨ c = 4#64 ∨ c = 3#64 ∨ c = 2#64) :
    ∃ st', steps Code_k32.prog 3 st = some st' ∧ st'.pc = 0x10900 ∧ st'.w.r11 = c - 1#64 ∧ st'.rdi = st.rdi + 0x40#64 ∧
      (∀ r, st'.zmm r = st.zmm r) ∧ st'.rbx = st.rbx ∧ st'.rsp = st.rsp ∧ st'.rbp = st.rbp ∧ st'.rsi = st.rsi ∧ st'.r9 = st.r9 ∧ st'.r12 = st.r12 ∧ st'.r13 = st.r13 ∧ st'.r14 = st.r14 ∧ st'.r15 = st.r15 ∧ st'.w.r10 = st.w.r10 ∧ st'.mem = st.mem := by
  rcases hc with h | h | h | h | h | h <;> subst h <;>
  · obtain ⟨rax, rcx, rdx, rbx, rsp, rbp, rsi, rdi, r8, r9, r12, r13, r14, r15, zf, cf, x0, x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12, x13, x14, x15, mem, pc, ⟨r10, r11, u0, u1, u2, u3, u4, u5, u6, u7, u8, u9, u10, u11, u12, u13, u14, u15, z16, z17, z18, z19, z20, z21, z22, z23, z24, z25, z26, z27, z28, z29, z30, z31, k1, k2⟩⟩ := st
    simp only at hpc hr11; subst hpc hr11
    run_fn []
    exact ⟨_, rfl, rfl, rfl, rfl, fun _ => rfl, rfl, rfl, rfl, rfl, rfl, rfl, rfl, rfl, rfl, rfl, rfl⟩

set_option maxRecDepth 1000000 in
/-- The loop's end after the seventh round: on to 0x10EF0. -/
private theorem tail_done (st : State) (hpc : st.pc = 0x10EE3) (hr11 : st.w.r11 = 1#64) :
    ∃ st', steps Code_k32.prog 3 st = some st' ∧ st'.pc = 0x10EF0 ∧ st'.w.r11 = 0#64 ∧ st'.rdi = st.rdi + 0x40#64 ∧
      (∀ r, st'.zmm r = st.zmm r) ∧ st'.rbx = st.rbx ∧ st'.rsp = st.rsp ∧ st'.rbp = st.rbp ∧ st'.rsi = st.rsi ∧ st'.r9 = st.r9 ∧ st'.r12 = st.r12 ∧ st'.r13 = st.r13 ∧ st'.r14 = st.r14 ∧ st'.r15 = st.r15 ∧ st'.w.r10 = st.w.r10 ∧ st'.mem = st.mem := by
  obtain ⟨rax, rcx, rdx, rbx, rsp, rbp, rsi, rdi, r8, r9, r12, r13, r14, r15, zf, cf, x0, x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12, x13, x14, x15, mem, pc, ⟨r10, r11, u0, u1, u2, u3, u4, u5, u6, u7, u8, u9, u10, u11, u12, u13, u14, u15, z16, z17, z18, z19, z20, z21, z22, z23, z24, z25, z26, z27, z28, z29, z30, z31, k1, k2⟩⟩ := st
  simp only at hpc hr11; subst hpc hr11
  run_fn []
  exact ⟨_, rfl, rfl, rfl, rfl, fun _ => rfl, rfl, rfl, rfl, rfl, rfl, rfl, rfl, rfl, rfl, rfl, rfl⟩

set_option maxRecDepth 1000000 in
set_option maxHeartbeats 0 in
/-- **A turn of the round loop with rounds to come** (243 instructions): a round on every lane, with the message words
at the offsets `rdi` points at, and `rdi` on to the next row. -/
theorem turn (v w : Nat → Vector (BitVec 32) 16) (m0 m1 m2 m3 m4 m5 m6 m7 m8 m9 m10 m11 m12 m13 m14 m15 n0 n1 n2 n3 n4 n5 n6 n7 n8 n9 n10 n11 n12 n13 n14 n15 : Nat → BitVec 32) (o0 o1 o2 o3 o4 o5 o6 o7 o8 o9 o10 o11 o12 o13 o14 o15 : BitVec 64)
    (c : BitVec 64) (st : State) (hpc : st.pc = 0x10900) (hr11 : st.w.r11 = c) (hc : c = 7#64 ∨ c = 6#64 ∨ c = 5#64 ∨ c = 4#64 ∨ c = 3#64 ∨ c = 2#64)
    (ha : RowsAV st v) (hb : RowsBV st w) (ho : Row st o0 o1 o2 o3 o4 o5 o6 o7 o8 o9 o10 o11 o12 o13 o14 o15) (hm : Msgs st o0 o1 o2 o3 o4 o5 o6 o7 o8 o9 o10 o11 o12 o13 o14 o15 m0 m1 m2 m3 m4 m5 m6 m7 m8 m9 m10 m11 m12 m13 m14 m15 n0 n1 n2 n3 n4 n5 n6 n7 n8 n9 n10 n11 n12 n13 n14 n15) :
    ∃ st', steps Code_k32.prog 243 st = some st' ∧ st'.pc = 0x10900 ∧ st'.w.r11 = c - 1#64 ∧ st'.rdi = st.rdi + 0x40#64 ∧
      RowsAV st' (fun i => rnd (v i) #v[m0 i, m1 i, m2 i, m3 i, m4 i, m5 i, m6 i, m7 i, m8 i, m9 i, m10 i, m11 i, m12 i, m13 i, m14 i, m15 i]) ∧
      RowsBV st' (fun i => rnd (w i) #v[n0 i, n1 i, n2 i, n3 i, n4 i, n5 i, n6 i, n7 i, n8 i, n9 i, n10 i, n11 i, n12 i, n13 i, n14 i, n15 i]) ∧
      st'.rbx = st.rbx ∧ st'.rsp = st.rsp ∧ st'.rbp = st.rbp ∧ st'.rsi = st.rsi ∧ st'.r9 = st.r9 ∧ st'.r12 = st.r12 ∧ st'.r13 = st.r13 ∧ st'.r14 = st.r14 ∧ st'.r15 = st.r15 ∧ st'.w.r10 = st.w.r10 ∧ st'.mem = st.mem := by
  obtain ⟨s1, e1, pc1, hA1, hB1, rbx1, rsp1, rbp1, rsi1, rdi1, r91, r121, r131, r141, r151, r101, r111, _, _, mem1⟩ :=
    round _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ st hpc ha hb ho hm
  have hr11_1 : s1.w.r11 = c := by rw [r111]; exact hr11
  obtain ⟨s2, e2, pc2, hr11_2, di2, hz2, rbx2, rsp2, rbp2, rsi2, r92, r122, r132, r142, r152, r102, mem2⟩ := tail_next c s1 pc1 hr11_1 hc
  refine ⟨s2, ?_, pc2, hr11_2, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_⟩
  · rw [show (243 : Nat) = 240 + 3 from rfl, steps_add, e1, Option.bind_some, e2]
  · rw [di2, rdi1]
  · simpa only [RowsAV, eta16] using rowsA_zmm_eq hz2 hA1
  · simpa only [RowsBV, eta16] using rowsB_zmm_eq hz2 hB1
  all_goals first
    | (rw [rbx2, rbx1])
    | (rw [rsp2, rsp1])
    | (rw [rbp2, rbp1])
    | (rw [rsi2, rsi1])
    | (rw [r92, r91])
    | (rw [r122, r121])
    | (rw [r132, r131])
    | (rw [r142, r141])
    | (rw [r152, r151])
    | (rw [r102, r101])
    | (rw [mem2, mem1])

set_option maxRecDepth 1000000 in
set_option maxHeartbeats 0 in
/-- **The last turn of the round loop** (243 instructions): a round on every lane, with the message words
at the offsets `rdi` points at, and `rdi` on to the next row. -/
theorem turn_last (v w : Nat → Vector (BitVec 32) 16) (m0 m1 m2 m3 m4 m5 m6 m7 m8 m9 m10 m11 m12 m13 m14 m15 n0 n1 n2 n3 n4 n5 n6 n7 n8 n9 n10 n11 n12 n13 n14 n15 : Nat → BitVec 32) (o0 o1 o2 o3 o4 o5 o6 o7 o8 o9 o10 o11 o12 o13 o14 o15 : BitVec 64)
    (st : State) (hpc : st.pc = 0x10900) (hr11 : st.w.r11 = 1#64)
    (ha : RowsAV st v) (hb : RowsBV st w) (ho : Row st o0 o1 o2 o3 o4 o5 o6 o7 o8 o9 o10 o11 o12 o13 o14 o15) (hm : Msgs st o0 o1 o2 o3 o4 o5 o6 o7 o8 o9 o10 o11 o12 o13 o14 o15 m0 m1 m2 m3 m4 m5 m6 m7 m8 m9 m10 m11 m12 m13 m14 m15 n0 n1 n2 n3 n4 n5 n6 n7 n8 n9 n10 n11 n12 n13 n14 n15) :
    ∃ st', steps Code_k32.prog 243 st = some st' ∧ st'.pc = 0x10EF0 ∧ st'.w.r11 = 0#64 ∧ st'.rdi = st.rdi + 0x40#64 ∧
      RowsAV st' (fun i => rnd (v i) #v[m0 i, m1 i, m2 i, m3 i, m4 i, m5 i, m6 i, m7 i, m8 i, m9 i, m10 i, m11 i, m12 i, m13 i, m14 i, m15 i]) ∧
      RowsBV st' (fun i => rnd (w i) #v[n0 i, n1 i, n2 i, n3 i, n4 i, n5 i, n6 i, n7 i, n8 i, n9 i, n10 i, n11 i, n12 i, n13 i, n14 i, n15 i]) ∧
      st'.rbx = st.rbx ∧ st'.rsp = st.rsp ∧ st'.rbp = st.rbp ∧ st'.rsi = st.rsi ∧ st'.r9 = st.r9 ∧ st'.r12 = st.r12 ∧ st'.r13 = st.r13 ∧ st'.r14 = st.r14 ∧ st'.r15 = st.r15 ∧ st'.w.r10 = st.w.r10 ∧ st'.mem = st.mem := by
  obtain ⟨s1, e1, pc1, hA1, hB1, rbx1, rsp1, rbp1, rsi1, rdi1, r91, r121, r131, r141, r151, r101, r111, _, _, mem1⟩ :=
    round _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ st hpc ha hb ho hm
  have hr11_1 : s1.w.r11 = 1#64 := by rw [r111]; exact hr11
  obtain ⟨s2, e2, pc2, hr11_2, di2, hz2, rbx2, rsp2, rbp2, rsi2, r92, r122, r132, r142, r152, r102, mem2⟩ := tail_done s1 pc1 hr11_1
  refine ⟨s2, ?_, pc2, hr11_2, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_⟩
  · rw [show (243 : Nat) = 240 + 3 from rfl, steps_add, e1, Option.bind_some, e2]
  · rw [di2, rdi1]
  · simpa only [RowsAV, eta16] using rowsA_zmm_eq hz2 hA1
  · simpa only [RowsBV, eta16] using rowsB_zmm_eq hz2 hB1
  all_goals first
    | (rw [rbx2, rbx1])
    | (rw [rsp2, rsp1])
    | (rw [rbp2, rbp1])
    | (rw [rsi2, rsi1])
    | (rw [r92, r91])
    | (rw [r122, r121])
    | (rw [r132, r131])
    | (rw [r142, r141])
    | (rw [r152, r151])
    | (rw [r102, r101])
    | (rw [mem2, mem1])

set_option maxRecDepth 1000000 in
set_option maxHeartbeats 0 in
/-- **The round loop** (0x10900 to 0x10EF0, 1701 instructions): the specification's seven rounds on every lane of
both halves, with that lane's message words. Memory and the registers the kernel keeps are as they were. -/
theorem seven_rounds (v w m n : Nat → Vector (BitVec 32) 16) (st : State)
    (hpc : st.pc = 0x10900) (hr11 : st.w.r11 = 7#64)
    (ha : RowsAV st v) (hb : RowsBV st w) (hs : SchedAt st.mem st.rdi) (hm : BlocksAt st.mem st.rsi m n) :
    ∃ st', steps Code_k32.prog 1701 st = some st' ∧ st'.pc = 0x10EF0 ∧
      RowsAV st' (fun i => rounds7 (v i) (m i)) ∧ RowsBV st' (fun i => rounds7 (w i) (n i)) ∧
      st'.rbx = st.rbx ∧ st'.rsp = st.rsp ∧ st'.rbp = st.rbp ∧ st'.rsi = st.rsi ∧ st'.r9 = st.r9 ∧ st'.r12 = st.r12 ∧ st'.r13 = st.r13 ∧ st'.r14 = st.r14 ∧ st'.r15 = st.r15 ∧ st'.w.r10 = st.w.r10 ∧ st'.mem = st.mem := by
  obtain ⟨hs_0_0, hs_0_1, hs_0_2, hs_0_3, hs_0_4, hs_0_5, hs_0_6, hs_0_7, hs_0_8, hs_0_9, hs_0_10, hs_0_11, hs_0_12, hs_0_13, hs_0_14, hs_0_15, hs_1_0, hs_1_1, hs_1_2, hs_1_3, hs_1_4, hs_1_5, hs_1_6, hs_1_7, hs_1_8, hs_1_9, hs_1_10, hs_1_11, hs_1_12, hs_1_13, hs_1_14, hs_1_15, hs_2_0, hs_2_1, hs_2_2, hs_2_3, hs_2_4, hs_2_5, hs_2_6, hs_2_7, hs_2_8, hs_2_9, hs_2_10, hs_2_11, hs_2_12, hs_2_13, hs_2_14, hs_2_15, hs_3_0, hs_3_1, hs_3_2, hs_3_3, hs_3_4, hs_3_5, hs_3_6, hs_3_7, hs_3_8, hs_3_9, hs_3_10, hs_3_11, hs_3_12, hs_3_13, hs_3_14, hs_3_15, hs_4_0, hs_4_1, hs_4_2, hs_4_3, hs_4_4, hs_4_5, hs_4_6, hs_4_7, hs_4_8, hs_4_9, hs_4_10, hs_4_11, hs_4_12, hs_4_13, hs_4_14, hs_4_15, hs_5_0, hs_5_1, hs_5_2, hs_5_3, hs_5_4, hs_5_5, hs_5_6, hs_5_7, hs_5_8, hs_5_9, hs_5_10, hs_5_11, hs_5_12, hs_5_13, hs_5_14, hs_5_15, hs_6_0, hs_6_1, hs_6_2, hs_6_3, hs_6_4, hs_6_5, hs_6_6, hs_6_7, hs_6_8, hs_6_9, hs_6_10, hs_6_11, hs_6_12, hs_6_13, hs_6_14, hs_6_15⟩ := hs
  obtain ⟨hma0, hma1, hma2, hma3, hma4, hma5, hma6, hma7, hma8, hma9, hma10, hma11, hma12, hma13, hma14, hma15, hmb0, hmb1, hmb2, hmb3, hmb4, hmb5, hmb6, hmb7, hmb8, hmb9, hmb10, hmb11, hmb12, hmb13, hmb14, hmb15⟩ := hm
  have ho0 : Row st 0#64 64#64 128#64 192#64 256#64 320#64 384#64 448#64 512#64 576#64 640#64 704#64 768#64 832#64 896#64 960#64 := by unfold Row; exact ⟨hs_0_0, hs_0_1, hs_0_2, hs_0_3, hs_0_4, hs_0_5, hs_0_6, hs_0_7, hs_0_8, hs_0_9, hs_0_10, hs_0_11, hs_0_12, hs_0_13, hs_0_14, hs_0_15⟩
  have hm0 : Msgs st 0#64 64#64 128#64 192#64 256#64 320#64 384#64 448#64 512#64 576#64 640#64 704#64 768#64 832#64 896#64 960#64 (fun i => (m i)[0]) (fun i => (m i)[1]) (fun i => (m i)[2]) (fun i => (m i)[3]) (fun i => (m i)[4]) (fun i => (m i)[5]) (fun i => (m i)[6]) (fun i => (m i)[7]) (fun i => (m i)[8]) (fun i => (m i)[9]) (fun i => (m i)[10]) (fun i => (m i)[11]) (fun i => (m i)[12]) (fun i => (m i)[13]) (fun i => (m i)[14]) (fun i => (m i)[15]) (fun i => (n i)[0]) (fun i => (n i)[1]) (fun i => (n i)[2]) (fun i => (n i)[3]) (fun i => (n i)[4]) (fun i => (n i)[5]) (fun i => (n i)[6]) (fun i => (n i)[7]) (fun i => (n i)[8]) (fun i => (n i)[9]) (fun i => (n i)[10]) (fun i => (n i)[11]) (fun i => (n i)[12]) (fun i => (n i)[13]) (fun i => (n i)[14]) (fun i => (n i)[15]) := by
    unfold Msgs; simp only [BitVec.reduceAnd, BitVec.reduceAdd, BitVec.add_zero]
    exact ⟨hma0, hma1, hma2, hma3, hma4, hma5, hma6, hma7, hma8, hma9, hma10, hma11, hma12, hma13, hma14, hma15, hmb0, hmb1, hmb2, hmb3, hmb4, hmb5, hmb6, hmb7, hmb8, hmb9, hmb10, hmb11, hmb12, hmb13, hmb14, hmb15⟩
  obtain ⟨s1, e1, pc1, r11_1, di1, hA1, hB1, rbx_1, rsp_1, rbp_1, rsi_1, r9_1, r12_1, r13_1, r14_1, r15_1, r10_1, mem1⟩ :=
    turn _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ 7#64 st hpc hr11 (by decide) ha hb ho0 hm0
  have r11_1' : s1.w.r11 = 6#64 := by rw [r11_1]; decide
  have hmem1 : s1.mem = st.mem := by rw [mem1]
  have hrsi1 : s1.rsi = st.rsi := by rw [rsi_1]
  have hrdi1 : s1.rdi = st.rdi + 0x40#64 := by exact di1
  have ho1 : Row s1 128#64 384#64 192#64 640#64 448#64 0#64 256#64 832#64 64#64 704#64 768#64 320#64 576#64 896#64 960#64 512#64 := by
    unfold Row; rw [hmem1, hrdi1]; simp only [BitVec.add_assoc, BitVec.reduceAdd]
    exact ⟨hs_1_0, hs_1_1, hs_1_2, hs_1_3, hs_1_4, hs_1_5, hs_1_6, hs_1_7, hs_1_8, hs_1_9, hs_1_10, hs_1_11, hs_1_12, hs_1_13, hs_1_14, hs_1_15⟩
  have hm1 : Msgs s1 128#64 384#64 192#64 640#64 448#64 0#64 256#64 832#64 64#64 704#64 768#64 320#64 576#64 896#64 960#64 512#64 (fun i => (m i)[2]) (fun i => (m i)[6]) (fun i => (m i)[3]) (fun i => (m i)[10]) (fun i => (m i)[7]) (fun i => (m i)[0]) (fun i => (m i)[4]) (fun i => (m i)[13]) (fun i => (m i)[1]) (fun i => (m i)[11]) (fun i => (m i)[12]) (fun i => (m i)[5]) (fun i => (m i)[9]) (fun i => (m i)[14]) (fun i => (m i)[15]) (fun i => (m i)[8]) (fun i => (n i)[2]) (fun i => (n i)[6]) (fun i => (n i)[3]) (fun i => (n i)[10]) (fun i => (n i)[7]) (fun i => (n i)[0]) (fun i => (n i)[4]) (fun i => (n i)[13]) (fun i => (n i)[1]) (fun i => (n i)[11]) (fun i => (n i)[12]) (fun i => (n i)[5]) (fun i => (n i)[9]) (fun i => (n i)[14]) (fun i => (n i)[15]) (fun i => (n i)[8]) := by
    unfold Msgs; rw [hmem1, hrsi1]; simp only [BitVec.reduceAnd, BitVec.reduceAdd, BitVec.add_zero]
    exact ⟨hma2, hma6, hma3, hma10, hma7, hma0, hma4, hma13, hma1, hma11, hma12, hma5, hma9, hma14, hma15, hma8, hmb2, hmb6, hmb3, hmb10, hmb7, hmb0, hmb4, hmb13, hmb1, hmb11, hmb12, hmb5, hmb9, hmb14, hmb15, hmb8⟩
  obtain ⟨s2, e2, pc2, r11_2, di2, hA2, hB2, rbx_2, rsp_2, rbp_2, rsi_2, r9_2, r12_2, r13_2, r14_2, r15_2, r10_2, mem2⟩ :=
    turn _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ 6#64 s1 pc1 r11_1' (by decide) hA1 hB1 ho1 hm1
  have r11_2' : s2.w.r11 = 5#64 := by rw [r11_2]; decide
  have hmem2 : s2.mem = st.mem := by rw [mem2, hmem1]
  have hrsi2 : s2.rsi = st.rsi := by rw [rsi_2, hrsi1]
  have hrdi2 : s2.rdi = st.rdi + 0x80#64 := by simp only [di2, hrdi1, BitVec.add_assoc, BitVec.reduceAdd]
  have ho2 : Row s2 192#64 256#64 640#64 768#64 832#64 128#64 448#64 896#64 384#64 320#64 576#64 0#64 704#64 960#64 512#64 64#64 := by
    unfold Row; rw [hmem2, hrdi2]; simp only [BitVec.add_assoc, BitVec.reduceAdd]
    exact ⟨hs_2_0, hs_2_1, hs_2_2, hs_2_3, hs_2_4, hs_2_5, hs_2_6, hs_2_7, hs_2_8, hs_2_9, hs_2_10, hs_2_11, hs_2_12, hs_2_13, hs_2_14, hs_2_15⟩
  have hm2 : Msgs s2 192#64 256#64 640#64 768#64 832#64 128#64 448#64 896#64 384#64 320#64 576#64 0#64 704#64 960#64 512#64 64#64 (fun i => (m i)[3]) (fun i => (m i)[4]) (fun i => (m i)[10]) (fun i => (m i)[12]) (fun i => (m i)[13]) (fun i => (m i)[2]) (fun i => (m i)[7]) (fun i => (m i)[14]) (fun i => (m i)[6]) (fun i => (m i)[5]) (fun i => (m i)[9]) (fun i => (m i)[0]) (fun i => (m i)[11]) (fun i => (m i)[15]) (fun i => (m i)[8]) (fun i => (m i)[1]) (fun i => (n i)[3]) (fun i => (n i)[4]) (fun i => (n i)[10]) (fun i => (n i)[12]) (fun i => (n i)[13]) (fun i => (n i)[2]) (fun i => (n i)[7]) (fun i => (n i)[14]) (fun i => (n i)[6]) (fun i => (n i)[5]) (fun i => (n i)[9]) (fun i => (n i)[0]) (fun i => (n i)[11]) (fun i => (n i)[15]) (fun i => (n i)[8]) (fun i => (n i)[1]) := by
    unfold Msgs; rw [hmem2, hrsi2]; simp only [BitVec.reduceAnd, BitVec.reduceAdd, BitVec.add_zero]
    exact ⟨hma3, hma4, hma10, hma12, hma13, hma2, hma7, hma14, hma6, hma5, hma9, hma0, hma11, hma15, hma8, hma1, hmb3, hmb4, hmb10, hmb12, hmb13, hmb2, hmb7, hmb14, hmb6, hmb5, hmb9, hmb0, hmb11, hmb15, hmb8, hmb1⟩
  obtain ⟨s3, e3, pc3, r11_3, di3, hA3, hB3, rbx_3, rsp_3, rbp_3, rsi_3, r9_3, r12_3, r13_3, r14_3, r15_3, r10_3, mem3⟩ :=
    turn _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ 5#64 s2 pc2 r11_2' (by decide) hA2 hB2 ho2 hm2
  have r11_3' : s3.w.r11 = 4#64 := by rw [r11_3]; decide
  have hmem3 : s3.mem = st.mem := by rw [mem3, hmem2]
  have hrsi3 : s3.rsi = st.rsi := by rw [rsi_3, hrsi2]
  have hrdi3 : s3.rdi = st.rdi + 0xC0#64 := by simp only [di3, hrdi2, BitVec.add_assoc, BitVec.reduceAdd]
  have ho3 : Row s3 640#64 448#64 768#64 576#64 896#64 192#64 832#64 960#64 256#64 0#64 704#64 128#64 320#64 512#64 64#64 384#64 := by
    unfold Row; rw [hmem3, hrdi3]; simp only [BitVec.add_assoc, BitVec.reduceAdd]
    exact ⟨hs_3_0, hs_3_1, hs_3_2, hs_3_3, hs_3_4, hs_3_5, hs_3_6, hs_3_7, hs_3_8, hs_3_9, hs_3_10, hs_3_11, hs_3_12, hs_3_13, hs_3_14, hs_3_15⟩
  have hm3 : Msgs s3 640#64 448#64 768#64 576#64 896#64 192#64 832#64 960#64 256#64 0#64 704#64 128#64 320#64 512#64 64#64 384#64 (fun i => (m i)[10]) (fun i => (m i)[7]) (fun i => (m i)[12]) (fun i => (m i)[9]) (fun i => (m i)[14]) (fun i => (m i)[3]) (fun i => (m i)[13]) (fun i => (m i)[15]) (fun i => (m i)[4]) (fun i => (m i)[0]) (fun i => (m i)[11]) (fun i => (m i)[2]) (fun i => (m i)[5]) (fun i => (m i)[8]) (fun i => (m i)[1]) (fun i => (m i)[6]) (fun i => (n i)[10]) (fun i => (n i)[7]) (fun i => (n i)[12]) (fun i => (n i)[9]) (fun i => (n i)[14]) (fun i => (n i)[3]) (fun i => (n i)[13]) (fun i => (n i)[15]) (fun i => (n i)[4]) (fun i => (n i)[0]) (fun i => (n i)[11]) (fun i => (n i)[2]) (fun i => (n i)[5]) (fun i => (n i)[8]) (fun i => (n i)[1]) (fun i => (n i)[6]) := by
    unfold Msgs; rw [hmem3, hrsi3]; simp only [BitVec.reduceAnd, BitVec.reduceAdd, BitVec.add_zero]
    exact ⟨hma10, hma7, hma12, hma9, hma14, hma3, hma13, hma15, hma4, hma0, hma11, hma2, hma5, hma8, hma1, hma6, hmb10, hmb7, hmb12, hmb9, hmb14, hmb3, hmb13, hmb15, hmb4, hmb0, hmb11, hmb2, hmb5, hmb8, hmb1, hmb6⟩
  obtain ⟨s4, e4, pc4, r11_4, di4, hA4, hB4, rbx_4, rsp_4, rbp_4, rsi_4, r9_4, r12_4, r13_4, r14_4, r15_4, r10_4, mem4⟩ :=
    turn _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ 4#64 s3 pc3 r11_3' (by decide) hA3 hB3 ho3 hm3
  have r11_4' : s4.w.r11 = 3#64 := by rw [r11_4]; decide
  have hmem4 : s4.mem = st.mem := by rw [mem4, hmem3]
  have hrsi4 : s4.rsi = st.rsi := by rw [rsi_4, hrsi3]
  have hrdi4 : s4.rdi = st.rdi + 0x100#64 := by simp only [di4, hrdi3, BitVec.add_assoc, BitVec.reduceAdd]
  have ho4 : Row s4 768#64 832#64 576#64 704#64 960#64 640#64 896#64 512#64 448#64 128#64 320#64 192#64 0#64 64#64 384#64 256#64 := by
    unfold Row; rw [hmem4, hrdi4]; simp only [BitVec.add_assoc, BitVec.reduceAdd]
    exact ⟨hs_4_0, hs_4_1, hs_4_2, hs_4_3, hs_4_4, hs_4_5, hs_4_6, hs_4_7, hs_4_8, hs_4_9, hs_4_10, hs_4_11, hs_4_12, hs_4_13, hs_4_14, hs_4_15⟩
  have hm4 : Msgs s4 768#64 832#64 576#64 704#64 960#64 640#64 896#64 512#64 448#64 128#64 320#64 192#64 0#64 64#64 384#64 256#64 (fun i => (m i)[12]) (fun i => (m i)[13]) (fun i => (m i)[9]) (fun i => (m i)[11]) (fun i => (m i)[15]) (fun i => (m i)[10]) (fun i => (m i)[14]) (fun i => (m i)[8]) (fun i => (m i)[7]) (fun i => (m i)[2]) (fun i => (m i)[5]) (fun i => (m i)[3]) (fun i => (m i)[0]) (fun i => (m i)[1]) (fun i => (m i)[6]) (fun i => (m i)[4]) (fun i => (n i)[12]) (fun i => (n i)[13]) (fun i => (n i)[9]) (fun i => (n i)[11]) (fun i => (n i)[15]) (fun i => (n i)[10]) (fun i => (n i)[14]) (fun i => (n i)[8]) (fun i => (n i)[7]) (fun i => (n i)[2]) (fun i => (n i)[5]) (fun i => (n i)[3]) (fun i => (n i)[0]) (fun i => (n i)[1]) (fun i => (n i)[6]) (fun i => (n i)[4]) := by
    unfold Msgs; rw [hmem4, hrsi4]; simp only [BitVec.reduceAnd, BitVec.reduceAdd, BitVec.add_zero]
    exact ⟨hma12, hma13, hma9, hma11, hma15, hma10, hma14, hma8, hma7, hma2, hma5, hma3, hma0, hma1, hma6, hma4, hmb12, hmb13, hmb9, hmb11, hmb15, hmb10, hmb14, hmb8, hmb7, hmb2, hmb5, hmb3, hmb0, hmb1, hmb6, hmb4⟩
  obtain ⟨s5, e5, pc5, r11_5, di5, hA5, hB5, rbx_5, rsp_5, rbp_5, rsi_5, r9_5, r12_5, r13_5, r14_5, r15_5, r10_5, mem5⟩ :=
    turn _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ 3#64 s4 pc4 r11_4' (by decide) hA4 hB4 ho4 hm4
  have r11_5' : s5.w.r11 = 2#64 := by rw [r11_5]; decide
  have hmem5 : s5.mem = st.mem := by rw [mem5, hmem4]
  have hrsi5 : s5.rsi = st.rsi := by rw [rsi_5, hrsi4]
  have hrdi5 : s5.rdi = st.rdi + 0x140#64 := by simp only [di5, hrdi4, BitVec.add_assoc, BitVec.reduceAdd]
  have ho5 : Row s5 576#64 896#64 704#64 320#64 512#64 768#64 960#64 64#64 832#64 192#64 0#64 640#64 128#64 384#64 256#64 448#64 := by
    unfold Row; rw [hmem5, hrdi5]; simp only [BitVec.add_assoc, BitVec.reduceAdd]
    exact ⟨hs_5_0, hs_5_1, hs_5_2, hs_5_3, hs_5_4, hs_5_5, hs_5_6, hs_5_7, hs_5_8, hs_5_9, hs_5_10, hs_5_11, hs_5_12, hs_5_13, hs_5_14, hs_5_15⟩
  have hm5 : Msgs s5 576#64 896#64 704#64 320#64 512#64 768#64 960#64 64#64 832#64 192#64 0#64 640#64 128#64 384#64 256#64 448#64 (fun i => (m i)[9]) (fun i => (m i)[14]) (fun i => (m i)[11]) (fun i => (m i)[5]) (fun i => (m i)[8]) (fun i => (m i)[12]) (fun i => (m i)[15]) (fun i => (m i)[1]) (fun i => (m i)[13]) (fun i => (m i)[3]) (fun i => (m i)[0]) (fun i => (m i)[10]) (fun i => (m i)[2]) (fun i => (m i)[6]) (fun i => (m i)[4]) (fun i => (m i)[7]) (fun i => (n i)[9]) (fun i => (n i)[14]) (fun i => (n i)[11]) (fun i => (n i)[5]) (fun i => (n i)[8]) (fun i => (n i)[12]) (fun i => (n i)[15]) (fun i => (n i)[1]) (fun i => (n i)[13]) (fun i => (n i)[3]) (fun i => (n i)[0]) (fun i => (n i)[10]) (fun i => (n i)[2]) (fun i => (n i)[6]) (fun i => (n i)[4]) (fun i => (n i)[7]) := by
    unfold Msgs; rw [hmem5, hrsi5]; simp only [BitVec.reduceAnd, BitVec.reduceAdd, BitVec.add_zero]
    exact ⟨hma9, hma14, hma11, hma5, hma8, hma12, hma15, hma1, hma13, hma3, hma0, hma10, hma2, hma6, hma4, hma7, hmb9, hmb14, hmb11, hmb5, hmb8, hmb12, hmb15, hmb1, hmb13, hmb3, hmb0, hmb10, hmb2, hmb6, hmb4, hmb7⟩
  obtain ⟨s6, e6, pc6, r11_6, di6, hA6, hB6, rbx_6, rsp_6, rbp_6, rsi_6, r9_6, r12_6, r13_6, r14_6, r15_6, r10_6, mem6⟩ :=
    turn _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ 2#64 s5 pc5 r11_5' (by decide) hA5 hB5 ho5 hm5
  have r11_6' : s6.w.r11 = 1#64 := by rw [r11_6]; decide
  have hmem6 : s6.mem = st.mem := by rw [mem6, hmem5]
  have hrsi6 : s6.rsi = st.rsi := by rw [rsi_6, hrsi5]
  have hrdi6 : s6.rdi = st.rdi + 0x180#64 := by simp only [di6, hrdi5, BitVec.add_assoc, BitVec.reduceAdd]
  have ho6 : Row s6 704#64 960#64 320#64 0#64 64#64 576#64 512#64 384#64 896#64 640#64 128#64 768#64 192#64 256#64 448#64 832#64 := by
    unfold Row; rw [hmem6, hrdi6]; simp only [BitVec.add_assoc, BitVec.reduceAdd]
    exact ⟨hs_6_0, hs_6_1, hs_6_2, hs_6_3, hs_6_4, hs_6_5, hs_6_6, hs_6_7, hs_6_8, hs_6_9, hs_6_10, hs_6_11, hs_6_12, hs_6_13, hs_6_14, hs_6_15⟩
  have hm6 : Msgs s6 704#64 960#64 320#64 0#64 64#64 576#64 512#64 384#64 896#64 640#64 128#64 768#64 192#64 256#64 448#64 832#64 (fun i => (m i)[11]) (fun i => (m i)[15]) (fun i => (m i)[5]) (fun i => (m i)[0]) (fun i => (m i)[1]) (fun i => (m i)[9]) (fun i => (m i)[8]) (fun i => (m i)[6]) (fun i => (m i)[14]) (fun i => (m i)[10]) (fun i => (m i)[2]) (fun i => (m i)[12]) (fun i => (m i)[3]) (fun i => (m i)[4]) (fun i => (m i)[7]) (fun i => (m i)[13]) (fun i => (n i)[11]) (fun i => (n i)[15]) (fun i => (n i)[5]) (fun i => (n i)[0]) (fun i => (n i)[1]) (fun i => (n i)[9]) (fun i => (n i)[8]) (fun i => (n i)[6]) (fun i => (n i)[14]) (fun i => (n i)[10]) (fun i => (n i)[2]) (fun i => (n i)[12]) (fun i => (n i)[3]) (fun i => (n i)[4]) (fun i => (n i)[7]) (fun i => (n i)[13]) := by
    unfold Msgs; rw [hmem6, hrsi6]; simp only [BitVec.reduceAnd, BitVec.reduceAdd, BitVec.add_zero]
    exact ⟨hma11, hma15, hma5, hma0, hma1, hma9, hma8, hma6, hma14, hma10, hma2, hma12, hma3, hma4, hma7, hma13, hmb11, hmb15, hmb5, hmb0, hmb1, hmb9, hmb8, hmb6, hmb14, hmb10, hmb2, hmb12, hmb3, hmb4, hmb7, hmb13⟩
  obtain ⟨s7, e7, pc7, r11_7, di7, hA7, hB7, rbx_7, rsp_7, rbp_7, rsi_7, r9_7, r12_7, r13_7, r14_7, r15_7, r10_7, mem7⟩ :=
    turn_last _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ s6 pc6 r11_6' hA6 hB6 ho6 hm6
  refine ⟨s7, ?_, pc7, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_⟩
  · rw [show (1701 : Nat) = 243 + (243 + (243 + (243 + (243 + (243 + 243))))) from rfl,
      steps_add, e1, Option.bind_some, steps_add, e2, Option.bind_some, steps_add, e3, Option.bind_some, steps_add, e4, Option.bind_some, steps_add, e5, Option.bind_some, steps_add, e6, Option.bind_some, e7]
  · simpa only [RowsAV, rounds7, eta16, ← perm1, ← perm2, ← perm3, ← perm4, ← perm5, ← perm6] using hA7
  · simpa only [RowsBV, rounds7, eta16, ← perm1, ← perm2, ← perm3, ← perm4, ← perm5, ← perm6] using hB7
  all_goals first
    | (rw [rbx_7, rbx_6, rbx_5, rbx_4, rbx_3, rbx_2, rbx_1])
    | (rw [rsp_7, rsp_6, rsp_5, rsp_4, rsp_3, rsp_2, rsp_1])
    | (rw [rbp_7, rbp_6, rbp_5, rbp_4, rbp_3, rbp_2, rbp_1])
    | (rw [rsi_7, rsi_6, rsi_5, rsi_4, rsi_3, rsi_2, rsi_1])
    | (rw [r9_7, r9_6, r9_5, r9_4, r9_3, r9_2, r9_1])
    | (rw [r12_7, r12_6, r12_5, r12_4, r12_3, r12_2, r12_1])
    | (rw [r13_7, r13_6, r13_5, r13_4, r13_3, r13_2, r13_1])
    | (rw [r14_7, r14_6, r14_5, r14_4, r14_3, r14_2, r14_1])
    | (rw [r15_7, r15_6, r15_5, r15_4, r15_3, r15_2, r15_1])
    | (rw [r10_7, r10_6, r10_5, r10_4, r10_3, r10_2, r10_1])
    | (rw [mem7, hmem6])

end K32
