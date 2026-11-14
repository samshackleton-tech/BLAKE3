import P16Out
import AbiProof
import Spec_p16
import Lemmas_p16s
open X86 Cells Blake3Generic

/-! # The wide parent kernel `p16`, as assembled, meets `P16.contract`

`wide/p16.ode` (the 460 instructions of `blake3_servil_avx512_p16`, lifted from its ELF object in
`Code_p16.lean`) meets `P16.contract` (`Spec_p16.lean`), with 368 bytes of stack (within the contract's
4096-byte budget). -/

namespace Proof_p16

set_option maxRecDepth 1000000
set_option maxHeartbeats 0

private theorem read32_congr {m m' : Mem} (a : BitVec 64) (h : ∀ x, (x - a).toNat < 4 → m' x = m x) :
    m'.read a 32 = m.read a 32 := by
  simp only [Mem.read, Mem.read8]
  rw [h a (by bv_omega), h (a + 1) (by bv_omega), h (a + 2) (by bv_omega), h (a + 3) (by bv_omega)]

private theorem read32_vec_0 {m : Mem} {a : BitVec 64} {v : V} (h : Vec m a v) :
    m.read a 32 = some ((dw v 0).setWidth 64) := by
  obtain ⟨h0, h1, h2, h3, _⟩ := h
  simp only [add_zero'] at h0
  simp only [Mem.read, Mem.read8, h0, h1, h2, h3, Option.map_some, Option.bind_eq_bind, Option.bind_some,
    Option.pure_def, Option.some.injEq, dw, by8, Nat.reduceMul]
  bv_decide

private theorem read32_vec_4 {m : Mem} {a : BitVec 64} {v : V} (h : Vec m a v) :
    m.read (a + 4#64) 32 = some ((dw v 1).setWidth 64) := by
  obtain ⟨_, _, _, _, h4, h5, h6, h7, _⟩ := h
  have e4 : a + 4#64 = a + 4 := rfl
  have e5 : a + 4 + 1 = a + 5 := by bv_decide
  have e6 : a + 4 + 2 = a + 6 := by bv_decide
  have e7 : a + 4 + 3 = a + 7 := by bv_decide
  simp only [Mem.read, Mem.read8, e4, e5, e6, e7, h4, h5, h6, h7, Option.map_some, Option.bind_eq_bind, Option.bind_some,
    Option.pure_def, Option.some.injEq, dw, by8, Nat.reduceMul]
  bv_decide

private theorem read32_vec_8 {m : Mem} {a : BitVec 64} {v : V} (h : Vec m a v) :
    m.read (a + 8#64) 32 = some ((dw v 2).setWidth 64) := by
  obtain ⟨_, _, _, _, _, _, _, _, h8, h9, h10, h11, _⟩ := h
  have e8 : a + 8#64 = a + 8 := rfl
  have e9 : a + 8 + 1 = a + 9 := by bv_decide
  have e10 : a + 8 + 2 = a + 10 := by bv_decide
  have e11 : a + 8 + 3 = a + 11 := by bv_decide
  simp only [Mem.read, Mem.read8, e8, e9, e10, e11, h8, h9, h10, h11, Option.map_some, Option.bind_eq_bind, Option.bind_some,
    Option.pure_def, Option.some.injEq, dw, by8, Nat.reduceMul]
  bv_decide

private theorem read32_vec_12 {m : Mem} {a : BitVec 64} {v : V} (h : Vec m a v) :
    m.read (a + 12#64) 32 = some ((dw v 3).setWidth 64) := by
  obtain ⟨_, _, _, _, _, _, _, _, _, _, _, _, h12, h13, h14, h15⟩ := h
  have e12 : a + 12#64 = a + 12 := rfl
  have e13 : a + 12 + 1 = a + 13 := by bv_decide
  have e14 : a + 12 + 2 = a + 14 := by bv_decide
  have e15 : a + 12 + 3 = a + 15 := by bv_decide
  simp only [Mem.read, Mem.read8, e12, e13, e14, e15, h12, h13, h14, h15, Option.map_some, Option.bind_eq_bind, Option.bind_some,
    Option.pure_def, Option.some.injEq, dw, by8, Nat.reduceMul]
  bv_decide

private theorem setWidth_32_64 (x : BitVec 32) : (x.setWidth 64).setWidth 32 = x := by bv_decide

private theorem fp_bounds (fb : BitVec 64) :
    let fp := ((fb + 320#64) &&& 0xFFFFFFFFFFFFFFC0#64) - 256#64
    1#64 ≤ fp - fb ∧ fp - fb ≤ 64#64 ∧ fp + 256#64 - fb ≤ 320#64 ∧ 256#64 ≤ (fb + 320#64) - fp := by
  bv_decide

private theorem unpack_flags {flags : BitVec 64} (hf : flags < 256#64) :
    let packed := flags ||| 0x40000004#64
    ((packed &&& 0xFF#64) = flags ||| 4#64) ∧
    ((((packed.setWidth 32 >>> (BitVec.ofNat 5 8).toNat).setWidth 64 &&& 255#64) ||| (packed &&& 0xFF#64)) = flags ||| 4#64) ∧
    ((packed.setWidth 32 >>> (BitVec.ofNat 5 16).toNat).setWidth 64 &&& 255#64 = 0#64) ∧
    ((packed.setWidth 32 >>> (BitVec.ofNat 5 24).toNat).setWidth 64 = 64#64) := by
  bv_decide

private theorem push_step {fb off off' : BitVec 64} {r : Reg} {v : BitVec 64} {pc0 pc1 : Nat} {st : State}
    (hpc : st.pc = pc0) (hrsp : st.rsp = fb + off)
    (hi : Code_p16.prog pc0 = some (.push r, pc1))
    (hv : st.get r = v)
    (ho : Owned8 st.mem (fb + off'))
    (hoff : fb + off - 8#64 = fb + off') :
    ∃ st', steps Code_p16.prog 1 st = some st' ∧ st'.pc = pc1 ∧ st'.rsp = fb + off' ∧
      st'.mem = st.mem.put64 (fb + off') v ∧
      st'.rbp = st.rbp ∧ st'.rbx = st.rbx ∧ st'.r12 = st.r12 ∧ st'.r13 = st.r13 ∧
      st'.r14 = st.r14 ∧ st'.r15 = st.r15 ∧ st'.rdi = st.rdi ∧ st'.rsi = st.rsi ∧
      st'.rdx = st.rdx ∧ st'.rcx = st.rcx ∧ st'.r8 = st.r8 ∧ st'.r9 = st.r9 ∧ st'.w = st.w := by
  have hw := write_quad ho v
  have hw' : st.mem.write (fb + off - 8#64) v 64 = some (st.mem.put64 (fb + off') v) := by
    rw [hoff]; exact hw
  rw [steps, hpc, hi]
  dsimp only [step]
  have hrsp' : ({ st with pc := pc1 }).rsp = fb + off := hrsp
  have hv' : ({ st with pc := pc1 }).get r = v := hv
  rw [hv', hrsp', show fb + off - 8 = fb + off' from hoff]
  have hm' : ({ st with pc := pc1 }).mem.write (fb + off') v 64 = some (st.mem.put64 (fb + off') v) := hw
  rw [hm']
  simp only [Option.map_some, Option.bind_eq_bind, Option.bind_some, steps_zero]
  refine ⟨_, rfl, rfl, rfl, rfl, rfl, rfl, rfl, rfl, rfl, rfl, rfl, rfl, rfl, rfl, rfl, rfl, rfl⟩

private theorem prologue_saves (inputs key out fb : BitVec 64) (sv : Abi.Saved) (m0 : Mem)
    (st : State) (hpc : st.pc = 0x18000) (hrsp : st.rsp = fb + 368#64)
    (hrdi : st.rdi = inputs) (hrsi : st.rsi = 1#64) (hrdx : st.rdx = key) (hrcx : st.rcx = 0#64)
    (hr9 : st.r9 = out) (hbx : st.rbx = sv.rbx) (hbp : st.rbp = sv.rbp)
    (h12 : st.r12 = sv.r12) (h13 : st.r13 = sv.r13) (h14 : st.r14 = sv.r14) (h15 : st.r15 = sv.r15)
    (hm : st.mem = m0) (hStack : Cells.Region m0 fb 368#64) :
    let m6 := (((((m0.put64 (fb + 360#64) sv.rbp).put64 (fb + 352#64) sv.rbx).put64 (fb + 344#64) sv.r12).put64 (fb + 336#64) sv.r13).put64 (fb + 328#64) sv.r14).put64 (fb + 320#64) sv.r15
    ∃ st', steps Code_p16.prog 8 st = some st' ∧ st'.pc = 0x18011 ∧
      st'.rsp = fb + 320#64 ∧ st'.rbp = fb + 360#64 ∧ st'.mem = m6 ∧
      st'.rdi = inputs ∧ st'.rsi = 1#64 ∧ st'.rdx = key ∧ st'.rcx = 0#64 ∧
      st'.r8 = st.r8 ∧ st'.r9 = out := by
  intro m6
  have hb0 := owned8_region hStack 360#64 (by bv_decide)
  have hb1 := owned8_region hStack 352#64 (by bv_decide)
  have hb2 := owned8_region hStack 344#64 (by bv_decide)
  have hb3 := owned8_region hStack 336#64 (by bv_decide)
  have hb4 := owned8_region hStack 328#64 (by bv_decide)
  have hb5 := owned8_region hStack 320#64 (by bv_decide)
  have s0 : steps Code_p16.prog 1 st = some { st with pc := 0x18004 } := by
    rw [steps, hpc, Code_p16.at_18000]; rfl
  let sa := { st with pc := 0x18004 }
  obtain ⟨sb, eb, pcb, spb, mb, bpb, bxb, r12b, r13b, r14b, r15b, dib, sib, dxb, cxb, r8b, r9b, _⟩ :=
    push_step (v := sv.rbp) (off' := 360#64) (rfl : sa.pc = 0x18004) hrsp Code_p16.at_18004 hbp (by simpa [sa, hm] using hb0) (by bv_decide)
  have ec : steps Code_p16.prog 1 sb = some { sb with pc := 0x18008, rbp := sb.rsp } := by
    rw [steps, pcb, Code_p16.at_18005]; rfl
  let sc := { sb with pc := 0x18008, rbp := sb.rsp }
  obtain ⟨sd, ed, pcd, spd, md, bpd, bxd, r12d, r13d, r14d, r15d, did, sid, dxd, cxd, r8d, r9d, _⟩ :=
    push_step (v := sv.rbx) (off' := 352#64) (rfl : sc.pc = 0x18008) spb Code_p16.at_18008 (by simp only [sc, State.get, bxb, sa, hbx])
      (by simp only [sc, mb, sa, hm]; exact owned8_put64 _ _ _ _ hb1) (by bv_decide)
  obtain ⟨se, ee, pce, spe, me, bpe, bxe, r12e, r13e, r14e, r15e, die, sie, dxe, cxe, r8e, r9e, _⟩ :=
    push_step (v := sv.r12) (off' := 344#64) pcd spd Code_p16.at_18009 (by simp only [State.get, r12d, sc, r12b, sa, h12])
      (by rw [md, mb]; simp only [sc, sa, hm]; exact owned8_put64 _ _ _ _ (owned8_put64 _ _ _ _ hb2)) (by bv_decide)
  obtain ⟨sf, ef, pcf, spf, mf, bpf, bxf, r12f, r13f, r14f, r15f, dif, sif, dxf, cxf, r8f, r9f, _⟩ :=
    push_step (v := sv.r13) (off' := 336#64) pce spe Code_p16.at_1800B (by simp only [State.get, r13e, r13d, sc, r13b, sa, h13])
      (by rw [me, md, mb]; simp only [sc, sa, hm]; exact owned8_put64 _ _ _ _ (owned8_put64 _ _ _ _ (owned8_put64 _ _ _ _ hb3))) (by bv_decide)
  obtain ⟨sg, eg, pcg, spg, mg, bpg, bxg, r12g, r13g, r14g, r15g, dig, sig, dxg, cxg, r8g, r9g, _⟩ :=
    push_step (v := sv.r14) (off' := 328#64) pcf spf Code_p16.at_1800D (by simp only [State.get, r14f, r14e, r14d, sc, r14b, sa, h14])
      (by rw [mf, me, md, mb]; simp only [sc, sa, hm]; exact owned8_put64 _ _ _ _ (owned8_put64 _ _ _ _ (owned8_put64 _ _ _ _ (owned8_put64 _ _ _ _ hb4)))) (by bv_decide)
  obtain ⟨sh, eh, pch, sph, mh, bph, bxh, r12h, r13h, r14h, r15h, dih, sih, dxh, cxh, r8h, r9h, _⟩ :=
    push_step (v := sv.r15) (off' := 320#64) pcg spg Code_p16.at_1800F (by simp only [State.get, r15g, r15f, r15e, r15d, sc, r15b, sa, h15])
      (by rw [mg, mf, me, md, mb]; simp only [sc, sa, hm]; exact owned8_put64 _ _ _ _ (owned8_put64 _ _ _ _ (owned8_put64 _ _ _ _ (owned8_put64 _ _ _ _ (owned8_put64 _ _ _ _ hb5))))) (by bv_decide)
  refine ⟨sh, ?_, pch, sph, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_⟩
  · rw [show (8 : Nat) = 1 + (1 + (1 + (1 + (1 + (1 + (1 + 1)))))) from rfl,
      steps_add, s0, Option.bind_some, steps_add, eb, Option.bind_some, steps_add, ec, Option.bind_some,
      steps_add, ed, Option.bind_some, steps_add, ee, Option.bind_some, steps_add, ef, Option.bind_some,
      steps_add, eg, Option.bind_some, eh]
  · rw [bph, bpg, bpf, bpe, bpd]; simp only [sc, spb]
  · rw [mh, mg, mf, me, md, mb]; simp only [sc, sa, hm, m6]
  · rw [dih, dig, dif, die, did]; simp only [sc, dib, sa, hrdi]
  · rw [sih, sig, sif, sie, sid]; simp only [sc, sib, sa, hrsi]
  · rw [dxh, dxg, dxf, dxe, dxd]; simp only [sc, dxb, sa, hrdx]
  · rw [cxh, cxg, cxf, cxe, cxd]; simp only [sc, cxb, sa, hrcx]
  · rw [r8h, r8g, r8f, r8e, r8d]; simp only [sc, r8b, sa]
  · rw [r9h, r9g, r9f, r9e, r9d]; simp only [sc, r9b, sa, hr9]

private theorem prologue_alloc (fb : BitVec 64) (st : State)
    (hpc : st.pc = 0x18011) (hrsp : st.rsp = fb + 320#64)
    (hb : (st.mem (((fb + 320#64) &&& 0xFFFFFFFFFFFFFFC0#64) - 256#64)).isSome) :
    let fp := ((fb + 320#64) &&& 0xFFFFFFFFFFFFFFC0#64) - 256#64
    ∃ st', steps Code_p16.prog 3 st = some st' ∧ st'.pc = 0x18020 ∧
      st'.rsp = fp ∧ st'.rbp = st.rbp ∧ st'.rdi = st.rdi ∧ st'.rsi = st.rsi ∧
      st'.rdx = st.rdx ∧ st'.rcx = st.rcx ∧ st'.r8 = st.r8 ∧ st'.r9 = st.r9 ∧
      st'.mem = st.mem.put8 fp 0#8 := by
  obtain ⟨rax, rcx, rdx, rbx, rsp, rbp, rsi, rdi, r8, r9, r12, r13, r14, r15, zf, cf,
    x0, x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12, x13, x14, x15, mem, pc, w⟩ := st
  simp only at hpc hrsp hb; subst hpc hrsp
  have hw6 := write_byte hb 0#64
  run_fn [BitVec.add_zero, hw6]
  exact ⟨_, rfl, rfl, rfl, rfl, rfl, rfl, rfl, rfl, rfl, rfl, rfl⟩

private theorem prologue_args (st : State) (hpc : st.pc = 0x18020) :
    ∃ st', steps Code_p16.prog 6 st = some st' ∧ st'.pc = 0x18032 ∧
      st'.rsp = st.rsp ∧ st'.rbp = st.rbp ∧ st'.r12 = st.rdi ∧ st'.r13 = st.rsi ∧
      st'.r14 = st.rdx ∧ st'.r15 = st.r9 ∧ st'.rbx = st.r8 ∧ st'.r9 = st.rcx ∧
      st'.mem = st.mem := by
  obtain ⟨rax, rcx, rdx, rbx, rsp, rbp, rsi, rdi, r8, r9, r12, r13, r14, r15, zf, cf,
    x0, x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12, x13, x14, x15, mem, pc, w⟩ := st
  simp only at hpc; subst hpc
  run_fn []
  exact ⟨_, rfl, rfl, rfl, rfl, rfl, rfl, rfl, rfl, rfl, rfl, rfl⟩

private theorem mem_saves_fp_isSome {m0 : Mem} {fb fp d : BitVec 64} {sv : Abi.Saved}
    (hfp1 : 1#64 ≤ fp - fb) (hfp_le : fp - fb ≤ 64#64)
    (hStack : Cells.Region m0 fb 368#64) (hd : d.toNat < 256) :
    ((((((m0.put64 (fb + 360#64) sv.rbp).put64 (fb + 352#64) sv.rbx).put64 (fb + 344#64) sv.r12).put64 (fb + 336#64) sv.r13).put64 (fb + 328#64) sv.r14).put64 (fb + 320#64) sv.r15 |>.put8 fp 0#8) (fp + d) |>.isSome := by
  have h1 : (fp - fb + d).toNat < 368 := by bv_omega
  have hd' := hStack (fp - fb + d) h1
  have e : fp + d = fb + (fp - fb + d) := by bv_omega
  rw [e]
  exact put8_isSome _ _ _ _ (put64_isSome _ _ _ _ (put64_isSome _ _ _ _ (put64_isSome _ _ _ _
    (put64_isSome _ _ _ _ (put64_isSome _ _ _ _ (put64_isSome _ _ _ _ hd'))))))

private theorem mem_saves_quads {m0 : Mem} {fb fp : BitVec 64} {sv : Abi.Saved}
    (hfp1 : 1#64 ≤ fp - fb) (hfp_le : fp - fb ≤ 64#64) :
    let m6 := (((((m0.put64 (fb + 360#64) sv.rbp).put64 (fb + 352#64) sv.rbx).put64 (fb + 344#64) sv.r12).put64 (fb + 336#64) sv.r13).put64 (fb + 328#64) sv.r14).put64 (fb + 320#64) sv.r15
    let m7 := m6.put8 fp 0#8
    Quad m7 (fb + 360#64) sv.rbp ∧ Quad m7 (fb + 352#64) sv.rbx ∧
    Quad m7 (fb + 344#64) sv.r12 ∧ Quad m7 (fb + 336#64) sv.r13 ∧
    Quad m7 (fb + 328#64) sv.r14 ∧ Quad m7 (fb + 320#64) sv.r15 := by
  have hf : ∀ (a : BitVec 64), 320#64 ≤ a - fb → a - fb < 368#64 →
      ∀ (x : BitVec 64), (x - a).toNat < 8 → x ≠ fp :=
    fun a ha1 ha2 x hx e => by subst e; bv_omega
  refine ⟨?_, ?_, ?_, ?_, ?_, ?_⟩
  · exact quad_congr (fun x hx => put8_other _ _ _ _ (hf _ (by bv_decide) (by bv_decide) x hx))
      (quad_put64_far _ _ _ _ _ (by bv_decide) (quad_put64_far _ _ _ _ _ (by bv_decide)
        (quad_put64_far _ _ _ _ _ (by bv_decide) (quad_put64_far _ _ _ _ _ (by bv_decide)
          (quad_put64_far _ _ _ _ _ (by bv_decide) (quad_put64 _ _ _))))))
  · exact quad_congr (fun x hx => put8_other _ _ _ _ (hf _ (by bv_decide) (by bv_decide) x hx))
      (quad_put64_far _ _ _ _ _ (by bv_decide) (quad_put64_far _ _ _ _ _ (by bv_decide)
        (quad_put64_far _ _ _ _ _ (by bv_decide) (quad_put64_far _ _ _ _ _ (by bv_decide)
          (quad_put64 _ _ _)))))
  · exact quad_congr (fun x hx => put8_other _ _ _ _ (hf _ (by bv_decide) (by bv_decide) x hx))
      (quad_put64_far _ _ _ _ _ (by bv_decide) (quad_put64_far _ _ _ _ _ (by bv_decide)
        (quad_put64_far _ _ _ _ _ (by bv_decide) (quad_put64 _ _ _))))
  · exact quad_congr (fun x hx => put8_other _ _ _ _ (hf _ (by bv_decide) (by bv_decide) x hx))
      (quad_put64_far _ _ _ _ _ (by bv_decide) (quad_put64_far _ _ _ _ _ (by bv_decide) (quad_put64 _ _ _)))
  · exact quad_congr (fun x hx => put8_other _ _ _ _ (hf _ (by bv_decide) (by bv_decide) x hx))
      (quad_put64_far _ _ _ _ _ (by bv_decide) (quad_put64 _ _ _))
  · exact quad_congr (fun x hx => put8_other _ _ _ _ (hf _ (by bv_decide) (by bv_decide) x hx))
      (quad_put64 _ _ _)

private theorem mem_saves_above {m0 : Mem} {fb fp x : BitVec 64} {sv : Abi.Saved}
    (hfp1 : 1#64 ≤ fp - fb) (hfp_le : fp - fb ≤ 64#64) (hx : 368#64 ≤ x - fb) :
    ((((((m0.put64 (fb + 360#64) sv.rbp).put64 (fb + 352#64) sv.rbx).put64 (fb + 344#64) sv.r12).put64 (fb + 336#64) sv.r13).put64 (fb + 328#64) sv.r14).put64 (fb + 320#64) sv.r15 |>.put8 fp 0#8) x = m0 x := by
  rw [put8_other _ _ _ _ (by intro e; subst e; bv_omega),
    put64_other _ _ _ _ (by bv_omega), put64_other _ _ _ _ (by bv_omega),
    put64_other _ _ _ _ (by bv_omega), put64_other _ _ _ _ (by bv_omega),
    put64_other _ _ _ _ (by bv_omega), put64_other _ _ _ _ (by bv_omega)]

private theorem mem_saves_key {m0 : Mem} {fb fp key x : BitVec 64} {sv : Abi.Saved}
    (hfp1 : 1#64 ≤ fp - fb) (hfp_le : fp - fb ≤ 64#64)
    (hap : 32#64 ≤ fb - key ∧ 376#64 ≤ key - fb) (hx : (x - key).toNat < 32) :
    ((((((m0.put64 (fb + 360#64) sv.rbp).put64 (fb + 352#64) sv.rbx).put64 (fb + 344#64) sv.r12).put64 (fb + 336#64) sv.r13).put64 (fb + 328#64) sv.r14).put64 (fb + 320#64) sv.r15 |>.put8 fp 0#8) x = m0 x := by
  obtain ⟨h1, h2⟩ := hap
  rw [put8_other _ _ _ _ (by intro e; subst e; bv_omega),
    put64_other _ _ _ _ (by bv_omega), put64_other _ _ _ _ (by bv_omega),
    put64_other _ _ _ _ (by bv_omega), put64_other _ _ _ _ (by bv_omega),
    put64_other _ _ _ _ (by bv_omega), put64_other _ _ _ _ (by bv_omega)]

private theorem prologue_push (inputs key out fb : BitVec 64) (sv : Abi.Saved) (m0 : Mem)
    (st : State) (hpc : st.pc = 0x18000) (hrsp : st.rsp = fb + 368#64)
    (hrdi : st.rdi = inputs) (hrsi : st.rsi = 1#64) (hrdx : st.rdx = key) (hrcx : st.rcx = 0#64)
    (hr8 : st.r8 = st.r8) (hr9 : st.r9 = out)
    (hbx : st.rbx = sv.rbx) (hbp : st.rbp = sv.rbp) (h12 : st.r12 = sv.r12)
    (h13 : st.r13 = sv.r13) (h14 : st.r14 = sv.r14) (h15 : st.r15 = sv.r15)
    (hm : st.mem = m0) (hStack : Cells.Region m0 fb 368#64) :
    let fp := ((fb + 320#64) &&& 0xFFFFFFFFFFFFFFC0#64) - 256#64
    ∃ st', steps Code_p16.prog 17 st = some st' ∧ st'.pc = 0x18032 ∧
      st'.rsp = fp ∧ aligned64 st'.rsp = true ∧ st'.rbp = fb + 360#64 ∧
      st'.r12 = inputs ∧ st'.r13 = 1#64 ∧ st'.r14 = key ∧ st'.r15 = out ∧
      st'.rbx = st.r8 ∧ st'.r9 = 0#64 ∧
      Cells.Region st'.mem fp 256#64 ∧
      Quad st'.mem (fb + 360#64) sv.rbp ∧ Quad st'.mem (fb + 352#64) sv.rbx ∧
      Quad st'.mem (fb + 344#64) sv.r12 ∧ Quad st'.mem (fb + 336#64) sv.r13 ∧
      Quad st'.mem (fb + 328#64) sv.r14 ∧ Quad st'.mem (fb + 320#64) sv.r15 ∧
      (∀ x : BitVec 64, 368#64 ≤ x - fb → st'.mem x = m0 x) ∧
      (∀ x : BitVec 64, 32#64 ≤ fb - key ∧ 376#64 ≤ key - fb → (x - key).toNat < 32 → st'.mem x = m0 x) := by
  intro fp
  obtain ⟨hfp1, hfp_le, hfp2, hfp3⟩ := fp_bounds fb
  have hal : aligned64 fp = true := aligned64_sub_256 (aligned64_and (fb + 320#64))
  obtain ⟨s1, e1, pc1, sp1, bp1, m1_eq, di1, si1, dx1, cx1, r8_1, r9_1⟩ :=
    prologue_saves inputs key out fb sv m0 st hpc hrsp hrdi hrsi hrdx hrcx hr9 hbx hbp h12 h13 h14 h15 hm hStack
  have hbyte : (s1.mem fp).isSome := by
    rw [m1_eq]
    have hlt : (fp - fb).toNat < 368 := by
      have : fp - fb ≤ 64#64 := hfp_le
      bv_omega
    have hd := hStack (fp - fb) hlt
    rw [show fb + (fp - fb) = fp by bv_decide] at hd
    exact put64_isSome _ _ _ _ (put64_isSome _ _ _ _ (put64_isSome _ _ _ _ (put64_isSome _ _ _ _ (put64_isSome _ _ _ _ (put64_isSome _ _ _ _ hd)))))
  obtain ⟨s1b, e1b, pc1b, sp1b, bp1b, di1b, si1b, dx1b, cx1b, r8_1b, r9_1b, m1b⟩ :=
    prologue_alloc fb s1 pc1 sp1 hbyte
  obtain ⟨s2, e2, pc2, sp2, bp2, r12_2, r13_2, r14_2, r15_2, rbx_2, r9_2, m2_eq⟩ :=
    prologue_args s1b pc1b
  obtain ⟨q0, q1, q2, q3, q4, q5⟩ := mem_saves_quads (m0 := m0) (fb := fb) (fp := fp) (sv := sv) hfp1 hfp_le
  refine ⟨s2, ?_, pc2, by rw [sp2, sp1b], by rw [sp2, sp1b]; exact hal, by rw [bp2, bp1b, bp1],
    by rw [r12_2, di1b, di1], by rw [r13_2, si1b, si1], by rw [r14_2, dx1b, dx1],
    by rw [r15_2, r9_1b, r9_1], by rw [rbx_2, r8_1b, r8_1], by rw [r9_2, cx1b, cx1],
    fun d hd => by rw [m2_eq, m1b, m1_eq]; exact mem_saves_fp_isSome hfp1 hfp_le hStack hd,
    by rw [m2_eq, m1b, m1_eq]; exact q0, by rw [m2_eq, m1b, m1_eq]; exact q1,
    by rw [m2_eq, m1b, m1_eq]; exact q2, by rw [m2_eq, m1b, m1_eq]; exact q3,
    by rw [m2_eq, m1b, m1_eq]; exact q4, by rw [m2_eq, m1b, m1_eq]; exact q5,
    fun x hx => by rw [m2_eq, m1b, m1_eq]; exact mem_saves_above hfp1 hfp_le hx,
    fun x hap hx => by rw [m2_eq, m1b, m1_eq]; exact mem_saves_key hfp1 hfp_le hap hx⟩
  · rw [show (17 : Nat) = 8 + (3 + 6) from rfl, steps_add, e1, Option.bind_some, steps_add, e1b, Option.bind_some, e2]

private theorem prologue_key (key : BitVec 64) (k0 k1 : V) (st : State)
    (hpc : st.pc = 0x18032) (hr14 : st.r14 = key)
    (hk0 : Vec st.mem key k0) (hk1 : Vec st.mem (key + 16#64) k1) :
    ∃ st', steps Code_p16.prog 8 st = some st' ∧ st'.pc = 0x18069 ∧
      st'.zmm 0 = zbroadcast (dw k0 0) ∧ st'.zmm 1 = zbroadcast (dw k0 1) ∧
      st'.zmm 2 = zbroadcast (dw k0 2) ∧ st'.zmm 3 = zbroadcast (dw k0 3) ∧
      st'.zmm 4 = zbroadcast (dw k1 0) ∧ st'.zmm 5 = zbroadcast (dw k1 1) ∧
      st'.zmm 6 = zbroadcast (dw k1 2) ∧ st'.zmm 7 = zbroadcast (dw k1 3) ∧
      st'.rsp = st.rsp ∧ st'.rbp = st.rbp ∧ st'.rbx = st.rbx ∧
      st'.r9 = st.r9 ∧ st'.r12 = st.r12 ∧ st'.r13 = st.r13 ∧ st'.r14 = st.r14 ∧ st'.r15 = st.r15 ∧
      st'.mem = st.mem := by
  have rk0 := read32_vec_0 hk0
  have rk1 := read32_vec_4 hk0
  have rk2 := read32_vec_8 hk0
  have rk3 := read32_vec_12 hk0
  have rk4 := read32_vec_0 hk1
  have rk5 := read32_vec_4 hk1
  have rk6 := read32_vec_8 hk1
  have rk7 := read32_vec_12 hk1
  have hk1' : key + 16#64 + 4#64 = key + 20#64 := by bv_decide
  have hk1'' : key + 16#64 + 8#64 = key + 24#64 := by bv_decide
  have hk1''' : key + 16#64 + 12#64 = key + 28#64 := by bv_decide
  rw [hk1'] at rk5; rw [hk1''] at rk6; rw [hk1'''] at rk7
  obtain ⟨rax, rcx, rdx, rbx, rsp, rbp, rsi, rdi, r8, r9, r12, r13, r14, r15, zf, cf,
    x0, x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12, x13, x14, x15, mem, pc,
    ⟨r10, r11, u0, u1, u2, u3, u4, u5, u6, u7, u8, u9, u10, u11, u12, u13, u14, u15,
     z16, z17, z18, z19, z20, z21, z22, z23, z24, z25, z26, z27, z28, z29, z30, z31⟩⟩ := st
  simp only at hpc hr14 rk0 rk1 rk2 rk3 rk4 rk5 rk6 rk7
  subst hpc hr14
  run_fn [BitVec.add_zero, rk0, rk1, rk2, rk3, rk4, rk5, rk6, rk7,
    setWidth_32_64, zjoin_split, zlo_zjoin, zhi_zjoin]
  refine ⟨_, rfl, rfl, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, rfl, rfl, rfl, rfl, rfl, rfl, rfl, rfl, rfl⟩
  all_goals simp only [State.zmm, zjoin_split]

private theorem prologue_flags (flags : BitVec 64) (st : State)
    (hpc : st.pc = 0x18069) (hbx : st.rbx = flags ||| 0x40000004#64) (hf : flags < 256#64) :
    ∃ st', steps Code_p16.prog 11 st = some st' ∧ st'.pc = 0x18091 ∧
      st'.r14 = 0#64 ∧ st'.w.r10 = flags ||| 4#64 ∧ st'.rdi = 0#64 ∧ st'.rsi = 64#64 ∧
      st'.rsp = st.rsp ∧ st'.rbp = st.rbp ∧ st'.rbx = st.rbx ∧
      st'.r9 = st.r9 ∧ st'.r12 = st.r12 ∧ st'.r13 = st.r13 ∧ st'.r15 = st.r15 ∧
      (∀ r, st'.zmm r = st.zmm r) ∧ st'.mem = st.mem := by
  obtain ⟨rax, rcx, rdx, rbx, rsp, rbp, rsi, rdi, r8, r9, r12, r13, r14, r15, zf, cf,
    x0, x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12, x13, x14, x15, mem, pc,
    ⟨r10, r11, u0, u1, u2, u3, u4, u5, u6, u7, u8, u9, u10, u11, u12, u13, u14, u15,
     z16, z17, z18, z19, z20, z21, z22, z23, z24, z25, z26, z27, z28, z29, z30, z31⟩⟩ := st
  simp only at hpc hbx
  subst hpc hbx
  run_fn []
  refine ⟨_, rfl, rfl, ?_, ?_, ?_, ?_, rfl, rfl, rfl, rfl, rfl, rfl, rfl, fun _ => rfl, rfl⟩
  · simp only; bv_decide
  · simp only; bv_decide
  · simp only; bv_decide
  · simp only; bv_decide

/-- **Prologue and key broadcast** (`0x18000` to `0x18091`, 36 instructions). -/
private theorem prologue (inputs key out fb ra flags : BitVec 64) (sv : Abi.Saved) (k0 k1 : V) (m0 : Mem)
    (st : State) (hpc : st.pc = 0x18000) (hrsp : st.rsp = fb + 368#64)
    (hrdi : st.rdi = inputs) (hrsi : st.rsi = 1#64) (hrdx : st.rdx = key) (hrcx : st.rcx = 0#64)
    (hr8 : st.r8 = flags ||| 0x40000004#64) (hr9 : st.r9 = out)
    (hbx : st.rbx = sv.rbx) (hbp : st.rbp = sv.rbp) (h12 : st.r12 = sv.r12)
    (h13 : st.r13 = sv.r13) (h14 : st.r14 = sv.r14) (h15 : st.r15 = sv.r15)
    (hm : st.mem = m0) (hf : flags < 256#64)
    (hStack : Cells.Region m0 fb 368#64)
    (hk0 : Vec m0 key k0) (hk1 : Vec m0 (key + 16#64) k1)
    (hKeyApart : 32#64 ≤ fb - key ∧ 376#64 ≤ key - fb) :
    let fp := ((fb + 320#64) &&& 0xFFFFFFFFFFFFFFC0#64) - 256#64
    ∃ st', steps Code_p16.prog 36 st = some st' ∧ st'.pc = 0x18091 ∧
      st'.rsp = fp ∧ aligned64 st'.rsp = true ∧ st'.rbp = fb + 360#64 ∧
      st'.r12 = inputs ∧ st'.r13 = 1#64 ∧ st'.r14 = 0#64 ∧ st'.r15 = out ∧
      st'.rbx = flags ||| 0x40000004#64 ∧ st'.r9 = 0#64 ∧
      st'.w.r10 = flags ||| 4#64 ∧ st'.rdi = 0#64 ∧ st'.rsi = 64#64 ∧
      st'.zmm 0 = zbroadcast (dw k0 0) ∧ st'.zmm 1 = zbroadcast (dw k0 1) ∧
      st'.zmm 2 = zbroadcast (dw k0 2) ∧ st'.zmm 3 = zbroadcast (dw k0 3) ∧
      st'.zmm 4 = zbroadcast (dw k1 0) ∧ st'.zmm 5 = zbroadcast (dw k1 1) ∧
      st'.zmm 6 = zbroadcast (dw k1 2) ∧ st'.zmm 7 = zbroadcast (dw k1 3) ∧
      Cells.Region st'.mem fp 256#64 ∧
      Quad st'.mem (fb + 360#64) sv.rbp ∧ Quad st'.mem (fb + 352#64) sv.rbx ∧
      Quad st'.mem (fb + 344#64) sv.r12 ∧ Quad st'.mem (fb + 336#64) sv.r13 ∧
      Quad st'.mem (fb + 328#64) sv.r14 ∧ Quad st'.mem (fb + 320#64) sv.r15 ∧
      (∀ x : BitVec 64, 368#64 ≤ x - fb → st'.mem x = m0 x) ∧
      (∀ x : BitVec 64, 320#64 ≤ x - fb → (x - fb).toNat < 368 → (st'.mem x = st'.mem x)) := by
  intro fp
  obtain ⟨s1, e1, pc1, sp1, hal1, bp1, r12_1, r13_1, r14_1, r15_1, rbx_1, r9_1,
    hFp, hq5, hq4, hq3, hq2, hq1, hq0, hOut, hKey⟩ :=
    prologue_push inputs key out fb sv m0 st hpc hrsp hrdi hrsi hrdx hrcx rfl hr9
      hbx hbp h12 h13 h14 h15 hm hStack
  have hk0' : Vec s1.mem key k0 := vec_congr (fun x hx => hKey x hKeyApart (by bv_omega)) hk0
  have hk1' : Vec s1.mem (key + 16#64) k1 := vec_congr (fun x hx => hKey x hKeyApart (by bv_omega)) hk1
  obtain ⟨s2, e2, pc2, z0, z1, z2, z3, z4, z5, z6, z7, sp2, bp2, bx2, r9_2, r12_2, r13_2, r14_2, r15_2, m2⟩ :=
    prologue_key key k0 k1 s1 pc1 r14_1 hk0' hk1'
  obtain ⟨s3, e3, pc3, r14_3, r10_3, rdi_3, rsi_3, sp3, bp3, bx3, r9_3, r12_3, r13_3, r15_3, z3', m3⟩ :=
    prologue_flags flags s2 pc2 (by rw [bx2, rbx_1, hr8]) hf
  refine ⟨s3, ?_, pc3, by rw [sp3, sp2, sp1], by rw [sp3, sp2, sp1, ← sp1]; exact hal1, by rw [bp3, bp2, bp1],
    by rw [r12_3, r12_2, r12_1], by rw [r13_3, r13_2, r13_1], r14_3, by rw [r15_3, r15_2, r15_1],
    by rw [bx3, bx2, rbx_1, hr8], by rw [r9_3, r9_2, r9_1], r10_3, rdi_3, rsi_3,
    by rw [z3' 0, z0], by rw [z3' 1, z1], by rw [z3' 2, z2], by rw [z3' 3, z3],
    by rw [z3' 4, z4], by rw [z3' 5, z5], by rw [z3' 6, z6], by rw [z3' 7, z7],
    by rw [m3, m2]; exact hFp, by rw [m3, m2]; exact hq5, by rw [m3, m2]; exact hq4,
    by rw [m3, m2]; exact hq3, by rw [m3, m2]; exact hq2, by rw [m3, m2]; exact hq1,
    by rw [m3, m2]; exact hq0, fun x hx => by rw [m3, m2]; exact hOut x hx, fun _ _ _ => rfl⟩
  rw [show (36 : Nat) = 17 + (8 + 11) from rfl, steps_add, e1, Option.bind_some, steps_add, e2, Option.bind_some, e3]

private theorem block_hdr_flags (flags : BitVec 64) :
    BitVec.setWidth 32
      (((flags ||| 4#64) &&& 4294967295#64 &&& 4294967295#64 &&& 4294967295#64 ||| 0#64) &&& 4294967295#64 &&&
        4294967295#64) = BitVec.setWidth 32 flags ||| 4#32 := by bv_decide

/-- **Block header and initial state vectors** (`0x182F0` to `0x18360`, 19 instructions). -/
private theorem block_hdr (k0 k1 : V) (flags : BitVec 64) (m : Nat → Vector (BitVec 32) 16)
    (st : State) (hpc : st.pc = 0x182F0) (hr13 : st.r13 = 1#64) (hr9 : st.r9 = 0#64)
    (hr10 : st.w.r10 = flags ||| 4#64) (hrdi : st.rdi = 0#64) (hrsi : st.rsi = 64#64) (hf : flags < 256#64)
    (hz0 : st.zmm 0 = zbroadcast (dw k0 0)) (hz1 : st.zmm 1 = zbroadcast (dw k0 1))
    (hz2 : st.zmm 2 = zbroadcast (dw k0 2)) (hz3 : st.zmm 3 = zbroadcast (dw k0 3))
    (hz4 : st.zmm 4 = zbroadcast (dw k1 0)) (hz5 : st.zmm 5 = zbroadcast (dw k1 1))
    (hz6 : st.zmm 6 = zbroadcast (dw k1 2)) (hz7 : st.zmm 7 = zbroadcast (dw k1 3))
    (hm : P16.MsgsV st m) :
    ∃ st', steps Code_p16.prog 19 st = some st' ∧ st'.pc = 0x18360 ∧ st'.w.r11 = 7#64 ∧
      P16.RowsV st' (fun _ => initv (cvWords k0 k1) 0#64 64#32 (flags.setWidth 32 ||| 4#32)) ∧
      P16.MsgsV st' m ∧
      st'.rsp = st.rsp ∧ st'.rbp = st.rbp ∧ st'.rbx = st.rbx ∧
      st'.r12 = st.r12 ∧ st'.r13 = st.r13 ∧ st'.r14 = st.r14 ∧ st'.r15 = st.r15 ∧
      st'.r8 = st.r8 ∧ st'.mem = st.mem := by
  obtain ⟨rax, rcx, rdx, rbx, rsp, rbp, rsi, rdi, r8, r9, r12, r13, r14, r15, zf, cf,
    x0, x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12, x13, x14, x15, mem, pc,
    ⟨r10, r11, u0, u1, u2, u3, u4, u5, u6, u7, u8, u9, u10, u11, u12, u13, u14, u15,
     z16, z17, z18, z19, z20, z21, z22, z23, z24, z25, z26, z27, z28, z29, z30, z31⟩⟩ := st
  simp only at hpc hr13 hr9 hr10 hrdi hrsi
  subst hpc hr13 hr9 hr10 hrdi hrsi
  run_fn []
  refine ⟨_, rfl, rfl, rfl, ?_, ?_, rfl, rfl, rfl, rfl, rfl, rfl, rfl, rfl, rfl⟩
  · simp only [P16.RowsV, P16.Rows, State.zmm, zjoin_split, initv, cvWords, zbroadcast,
      Vector.getElem_mk, List.getElem_toArray, List.getElem_cons_succ, List.getElem_cons_zero] at hz0 hz1 hz2 hz3 hz4 hz5 hz6 hz7 ⊢
    refine ⟨?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, by first | rfl | trivial, by first | rfl | trivial, by first | rfl | trivial, by first | rfl | trivial, by first | rfl | trivial, by first | rfl | trivial, by first | rfl | trivial, ?_⟩
    · exact hz0
    · exact hz1
    · exact hz2
    · exact hz3
    · exact hz4
    · exact hz5
    · exact hz6
    · exact hz7
    · exact congrArg zpack (funext fun _ => block_hdr_flags flags)
  · simp only [P16.MsgsV, P16.Msgs, State.zmm] at hm ⊢
    exact hm

/-- **Epilogue** (`0x18ABE` to `ra`, 9 instructions). -/
private theorem epilogue (fb ra : BitVec 64) (sv : Abi.Saved) (st : State)
    (hpc : st.pc = 0x18ABE) (hbp : st.rbp = fb + 360#64)
    (hq0 : Quad st.mem (fb + 320#64) sv.r15) (hq1 : Quad st.mem (fb + 328#64) sv.r14)
    (hq2 : Quad st.mem (fb + 336#64) sv.r13) (hq3 : Quad st.mem (fb + 344#64) sv.r12)
    (hq4 : Quad st.mem (fb + 352#64) sv.rbx) (hq5 : Quad st.mem (fb + 360#64) sv.rbp)
    (hra : Quad st.mem (fb + 368#64) ra) :
    ∃ st', steps Code_p16.prog 9 st = some st' ∧ st'.pc = ra.toNat ∧ st'.rsp = fb + 376#64 ∧
      st'.rbx = sv.rbx ∧ st'.rbp = sv.rbp ∧ st'.r12 = sv.r12 ∧ st'.r13 = sv.r13 ∧
      st'.r14 = sv.r14 ∧ st'.r15 = sv.r15 ∧ st'.mem = st.mem := by
  have r0 := read_quad hq0
  have r1 := read_quad hq1
  have r2 := read_quad hq2
  have r3 := read_quad hq3
  have r4 := read_quad hq4
  have r5 := read_quad hq5
  have rr := read_quad hra
  obtain ⟨rax, rcx, rdx, rbx, rsp, rbp, rsi, rdi, r8, r9, r12, r13, r14, r15, zf, cf,
    x0, x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12, x13, x14, x15, mem, pc,
    ⟨r10, r11, u0, u1, u2, u3, u4, u5, u6, u7, u8, u9, u10, u11, u12, u13, u14, u15,
     z16, z17, z18, z19, z20, z21, z22, z23, z24, z25, z26, z27, z28, z29, z30, z31⟩⟩ := st
  simp only at hpc hbp r0 r1 r2 r3 r4 r5 rr
  subst hpc hbp
  have e_lea : fb + 360#64 + 0xFFFFFFFFFFFFFFD8#64 = fb + 320#64 := by bv_decide
  have e_p1 : fb + 320#64 + 8#64 = fb + 328#64 := by bv_decide
  have e_p2 : fb + 328#64 + 8#64 = fb + 336#64 := by bv_decide
  have e_p3 : fb + 336#64 + 8#64 = fb + 344#64 := by bv_decide
  have e_p4 : fb + 344#64 + 8#64 = fb + 352#64 := by bv_decide
  have e_p5 : fb + 352#64 + 8#64 = fb + 360#64 := by bv_decide
  have e_p6 : fb + 360#64 + 8#64 = fb + 368#64 := by bv_decide
  run_fn [e_lea, e_p1, e_p2, e_p3, e_p4, e_p5, e_p6, r0, r1, r2, r3, r4, r5, rr]
  exact ⟨_, rfl, rfl, by simp only, rfl, rfl, rfl, rfl, rfl, rfl, rfl⟩

private theorem cvl_of_cvsOutAt {mem : Mem} {out : BitVec 64} {c : Nat → Vector (BitVec 32) 8}
    {vals : List Blake3.CV} (hlen : vals.length = 16)
    (hc : P16.CvsOutAt mem out c)
    (hmatch : ∀ (i : Nat) (hi : i < 16), vals[i]? = some (Vector.ofFn fun w => ⟨(c i)[w]⟩)) :
    Cvs16.At mem out vals := by
  refine ⟨hlen, ?_⟩
  have step_cv : ∀ (k : Nat) (hk : k ≤ 16) (a : BitVec 64) (l : List Blake3.CV),
      a = out + BitVec.ofNat 64 (32 * (16 - k)) →
      l = vals.drop (16 - k) →
      Cvl.At mem a l := by
    intro k
    induction k with
    | zero =>
      intro _ a l _ hl
      have : 16 - 0 = vals.length := hlen.symm
      rw [this, List.drop_length] at hl
      subst hl; trivial
    | succ k ih =>
      intro hk a l ha hl
      have hi : 16 - (k + 1) < 16 := by omega
      have hget := hmatch (16 - (k + 1)) hi
      have hdrop : vals.drop (16 - (k + 1)) = (Vector.ofFn fun w => ⟨(c (16 - (k + 1)))[w]⟩) :: vals.drop (16 - k) := by
        have hd := List.drop_eq_getElem_cons (i := 16 - (k + 1)) (l := vals) (by omega)
        have hv : vals[16 - (k + 1)] = Vector.ofFn fun w => ⟨(c (16 - (k + 1)))[w]⟩ := by
          have := hget; rw [List.getElem?_eq_getElem (by omega)] at this; exact Option.some.inj this
        rw [hd, hv, show 16 - (k + 1) + 1 = 16 - k by omega]
      rw [hl, hdrop]
      obtain ⟨hv0, hv1⟩ := hc (16 - (k + 1)) hi
      have e16 : out + BitVec.ofNat 64 (32 * (16 - (k + 1))) + 16#64 = out + BitVec.ofNat 64 (32 * (16 - (k + 1)) + 16) := by
        apply BitVec.eq_of_toNat_eq; simp only [BitVec.toNat_add, BitVec.toNat_ofNat]; omega
      refine ⟨⟨_, _, by rw [ha]; exact hv0, by rw [ha, e16]; exact hv1, ?_⟩, ih (by omega) (a + 32#64) (vals.drop (16 - k)) ?_ rfl⟩
      · simp only [words8, dw_mk4_0, dw_mk4_1, dw_mk4_2, dw_mk4_3]
        ext w hw; rcases w with _ | _ | _ | _ | _ | _ | _ | _ | w <;> first | omega | rfl
      · rw [ha]; apply BitVec.eq_of_toNat_eq; simp only [BitVec.toNat_add, BitVec.toNat_ofNat]; omega
  exact step_cv 16 (Nat.le_refl 16) out vals (by simp) (by simp)

private theorem words8_mk4 {a0 a1 : V} {cv : Blake3.CV} (h : words8 a0 a1 = cv) :
    a0 = mk4 cv[0].toBitVec cv[1].toBitVec cv[2].toBitVec cv[3].toBitVec ∧
    a1 = mk4 cv[4].toBitVec cv[5].toBitVec cv[6].toBitVec cv[7].toBitVec := by
  subst h; simp only [words8, Vector.getElem_mk, List.getElem_toArray,
    List.getElem_cons_succ, List.getElem_cons_zero]
  constructor <;> (simp only [mk4, dw, Nat.reduceMul]; bv_decide)

private theorem blockWords_mk4 (l0 l1 r0 r1 : V) :
    blockWords l0 l1 r0 r1 = #v[dw l0 0, dw l0 1, dw l0 2, dw l0 3, dw l1 0, dw l1 1, dw l1 2, dw l1 3,
      dw r0 0, dw r0 1, dw r0 2, dw r0 3, dw r1 0, dw r1 1, dw r1 2, dw r1 3] := rfl

private theorem mk4_dw (v : V) : mk4 (dw v 0) (dw v 1) (dw v 2) (dw v 3) = v := by
  simp only [mk4, dw, Nat.reduceMul]; bv_decide

private theorem blockAt_of_pairs {mem : Mem} {p : BitVec 64} {a0 a1 b0 b1 : V} {lv rv : Blake3.CV}
    (ha0 : Vec mem p a0) (ha1 : Vec mem (p + 16#64) a1) (hb0 : Vec mem (p + 32#64) b0) (hb1 : Vec mem (p + 48#64) b1)
    (hl : words8 a0 a1 = lv) (hr : words8 b0 b1 = rv) :
    let l0 := mk4 lv[0].toBitVec lv[1].toBitVec lv[2].toBitVec lv[3].toBitVec
    let l1 := mk4 lv[4].toBitVec lv[5].toBitVec lv[6].toBitVec lv[7].toBitVec
    let r0 := mk4 rv[0].toBitVec rv[1].toBitVec rv[2].toBitVec rv[3].toBitVec
    let r1 := mk4 rv[4].toBitVec rv[5].toBitVec rv[6].toBitVec rv[7].toBitVec
    P16.BlockAt mem p (blockWords l0 l1 r0 r1) := by
  obtain ⟨ea0, ea1⟩ := words8_mk4 hl
  obtain ⟨eb0, eb1⟩ := words8_mk4 hr
  simp only [P16.BlockAt, blockWords_mk4, Vector.getElem_mk, List.getElem_toArray,
    List.getElem_cons_succ, List.getElem_cons_zero, mk4_dw, BitVec.add_zero]
  rw [← ea0, ← ea1, ← eb0, ← eb1]
  exact ⟨ha0, ha1, hb0, hb1⟩

private theorem ra_above {fb x : BitVec 64} (hx : (x - (fb + 368#64)).toNat < 8) :
    368#64 ≤ x - fb := by bv_omega

private theorem region_above_nat {fb a sz x : BitVec 64} {szx : Nat}
    (hap : 368#64 + 8#64 ≤ a - fb ∧ sz ≤ fb - a) (hx : (x - a).toNat < szx) (hle : szx ≤ sz.toNat) :
    368#64 ≤ x - fb := by obtain ⟨h1, h2⟩ := hap; bv_omega

private theorem out_d_above {fb out d : BitVec 64}
    (hap : 368#64 + 8#64 ≤ out - fb ∧ 512#64 ≤ fb - out) (hd : d < 512#64) :
    368#64 ≤ (out + d) - fb := by obtain ⟨h1, h2⟩ := hap; bv_omega

private theorem stack_fp_above {fb x : BitVec 64} (hx : 320#64 ≤ x - fb) :
    256#64 ≤ x - (((fb + 320#64) &&& 0xFFFFFFFFFFFFFFC0#64) - 256#64) := by
  obtain ⟨h1, h2, h3, h4⟩ := fp_bounds fb
  have h1' : 1#64 ≤ (((fb + 320#64) &&& 0xFFFFFFFFFFFFFFC0#64) - 256#64) - fb := h1
  have h2' : (((fb + 320#64) &&& 0xFFFFFFFFFFFFFFC0#64) - 256#64) - fb ≤ 64#64 := h2
  generalize (((fb + 320#64) &&& 0xFFFFFFFFFFFFFFC0#64) - 256#64) = p at h1' h2' ⊢
  bv_omega

private theorem out_d_ge320 {fb out d : BitVec 64}
    (hap : 368#64 + 8#64 ≤ out - fb ∧ 512#64 ≤ fb - out) (hd : d < 512#64) :
    320#64 ≤ (out + d) - fb := by obtain ⟨h1, h2⟩ := hap; bv_omega

private theorem stack_apart_out {fb out x : BitVec 64}
    (hap : 368#64 + 8#64 ≤ out - fb ∧ 512#64 ≤ fb - out) (hx : (x - fb).toNat < 376) :
    512#64 ≤ x - out := by obtain ⟨h1, h2⟩ := hap; bv_omega

private theorem fb_quad_ge320 {fb d x : BitVec 64} (h1 : 320#64 ≤ d) (h2 : d ≤ 368#64)
    (hx : (x - (fb + d)).toNat < 8) : 320#64 ≤ x - fb := by bv_omega

private theorem fb_quad_lt376 {fb d x : BitVec 64} (h1 : 320#64 ≤ d) (h2 : d ≤ 368#64)
    (hx : (x - (fb + d)).toNat < 8) : (x - fb).toNat < 376 := by bv_omega

private theorem fb_376 (fb : BitVec 64) : fb + 376#64 = fb + 368#64 + 8#64 := by bv_decide

private theorem above_376_to_320 {fb x : BitVec 64} (hx : 368#64 + 8#64 ≤ x - fb) : 320#64 ≤ x - fb := by bv_omega

private theorem above_376_to_368 {fb x : BitVec 64} (hx : 368#64 + 8#64 ≤ x - fb) : 368#64 ≤ x - fb := by bv_omega

private theorem rounds7_eq_parentNode (k0 k1 l0 l1 r0 r1 : V) (flags : BitVec 64) :
    low8 (rounds7 (initv (cvWords k0 k1) 0#64 64#32 (flags.setWidth 32 ||| 4#32)) (blockWords l0 l1 r0 r1)) =
    (Blake3.parentNode (words8 k0 k1) ⟨flags.setWidth 32⟩ (words8 l0 l1) (words8 r0 r1)).cv.map bv := by
  have hs := spec_eq (cvWords k0 k1) (blockWords l0 l1 r0 r1) 0#64 64#32 (flags.setWidth 32 ||| 4#32)
  have hb := specCv_is_the_specifications (words8 k0 k1) (words8 l0 l1 ++ words8 r0 r1) 0 64 (⟨flags.setWidth 32⟩ ||| Blake3.PARENT)
  rw [words8_bv, block_bv] at hb
  have hfl : bv (⟨flags.setWidth 32⟩ ||| Blake3.PARENT) = flags.setWidth 32 ||| 4#32 := by
    simp only [bv, Blake3.PARENT]; bv_decide
  rw [hfl] at hb
  exact hs.symm.trans hb

private theorem words8_mk4_id (v : Blake3.CV) :
    words8 (mk4 v[0].toBitVec v[1].toBitVec v[2].toBitVec v[3].toBitVec)
           (mk4 v[4].toBitVec v[5].toBitVec v[6].toBitVec v[7].toBitVec) = v := by
  simp only [words8, dw_mk4_0, dw_mk4_1, dw_mk4_2, dw_mk4_3]
  ext w hw; rcases w with _ | _ | _ | _ | _ | _ | _ | _ | w <;> first | omega | rfl

private theorem cv_ofFn_eq {v : Blake3.CV} {w : Vector (BitVec 32) 8} (h : w = v.map bv) :
    (Vector.ofFn fun j => (⟨w[j]⟩ : UInt32)) = v := by
  subst h; ext j hj; apply UInt32.toBitVec_inj.mp; simp [bv]

/-- **`p16`, as assembled in `Code_p16.lean`, meets `P16.contract`.** -/
theorem p16_meets : ∀ (inputs blocks key counter packed out : BitVec 64) (k : Blake3.CV) (base : BitVec 64) (n : BitVec 64) (flags : BitVec 64) (l : List Blake3.CV),
    Abi.Meets Code_p16.prog 0x18000 (P16.contract inputs blocks key counter packed out k base n flags l) := by
  intro inputs blocks key counter packed out k base n flags l
  refine Abi.meets_of_triple 368#64 (by dsimp only [P16.contract]; decide) (by dsimp only [P16.contract]; decide) (fun fb ra sv m0 s ⟨hpc, hrsp, hargs, hbx, hbp, h12, h13, h14, h15, hm, hStack, hRa, hAp, hAcc, hReq⟩ => ?_)
  simp only [P16.contract, Abi.Contract.framed] at hargs hRa hAp hAcc hReq
  obtain ⟨hblocks, hctr, hpk, hf, hn1, hn16⟩ := hAcc
  simp only [List.length_cons, List.length_nil, List.take_succ_cons, List.take_zero] at hargs
  injection hargs with hrdi hargs; injection hargs with hrsi hargs; injection hargs with hrdx hargs
  injection hargs with hrcx hargs; injection hargs with hr8 hargs; injection hargs with hr9 _
  subst blocks counter packed
  simp only [Abi.Contract.requires, abi, List.map_cons, List.map_nil, List.cons_append, List.nil_append,
    List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true] at hReq
  obtain ⟨hOutR, hKeyAt, hPtrsAt, hPairsAt⟩ := hReq
  simp only [Abi.Contract.modifies, Abi.Contract.reading, Abi.Contract.regions, abi,
    List.map_cons, List.map_nil, List.cons_append, List.nil_append,
    Abi.WriteApart, Abi.Apart, List.forall_mem_cons, List.not_mem_nil, false_imp_iff, implies_true, and_true] at hAp
  obtain ⟨⟨hStackOut, hStackKey, hStackPtrs, hStackBase⟩, ⟨hOutKey, hOutPtrs, hOutBase⟩⟩ := hAp
  obtain ⟨k0, k1, hk0, hk1, hkw⟩ := hKeyAt
  obtain ⟨s1, e1, pc1, sp1, hal1, bp1, r12_1, r13_1, r14_1, r15_1, rbx_1, r9_1, r10_1, rdi_1, rsi_1,
    z0_1, z1_1, z2_1, z3_1, z4_1, z5_1, z6_1, z7_1, hFpR, hq5_1, hq4_1, hq3_1, hq2_1, hq1_1, hq0_1, hOut1, _⟩ :=
    prologue inputs key out fb ra flags sv k0 k1 m0 s hpc hrsp hrdi.symm hrsi.symm hrdx.symm hrcx.symm hr8.symm hr9.symm
      hbx hbp h12 h13 h14 h15 hm hf hStack hk0 hk1 ⟨hStackKey.2, by bv_omega⟩
  have hRa1 : Quad s1.mem (fb + 368#64) ra := quad_congr (fun x hx => hOut1 x (ra_above hx)) hRa
  have hOutR1 : Cells.Region s1.mem out 512#64 := fun d hd => by
    have := hOutR d hd; rw [hOut1 (out + d) (out_d_above hStackOut hd)]; exact this
  have hPtrs1 : Ptrs.At s1.mem inputs (Ptrs.spread base n 64#64) :=
    Ptrs.At.frame hPtrsAt (fun x hx => hOut1 x (region_above_nat (sz := 256#64) hStackPtrs hx (by decide)))
  have hPairs1 : Pairs.At n s1.mem base l :=
    Pairs.At.frame hPairsAt (fun x hx => hOut1 x (region_above_nat (sz := n <<< 6) hStackBase hx (by have : n ≤ 16#64 := hn16; bv_omega)))
  let p_j (j : Nat) := Ptrs.spread base n 64#64 j
  let lv_j (j : Nat) := l[2 * P16s.lane n (BitVec.ofNat 64 j)]!
  let rv_j (j : Nat) := l[2 * P16s.lane n (BitVec.ofNat 64 j) + 1]!
  let l0_j (j : Nat) := mk4 (lv_j j)[0].toBitVec (lv_j j)[1].toBitVec (lv_j j)[2].toBitVec (lv_j j)[3].toBitVec
  let l1_j (j : Nat) := mk4 (lv_j j)[4].toBitVec (lv_j j)[5].toBitVec (lv_j j)[6].toBitVec (lv_j j)[7].toBitVec
  let r0_j (j : Nat) := mk4 (rv_j j)[0].toBitVec (rv_j j)[1].toBitVec (rv_j j)[2].toBitVec (rv_j j)[3].toBitVec
  let r1_j (j : Nat) := mk4 (rv_j j)[4].toBitVec (rv_j j)[5].toBitVec (rv_j j)[6].toBitVec (rv_j j)[7].toBitVec
  let msg_j (j : Nat) := blockWords (l0_j j) (l1_j j) (r0_j j) (r1_j j)
  have hQuad_j : ∀ j : Nat, j < 16 → Quad s1.mem (s1.r12 + BitVec.ofNat 64 (8 * j)) (p_j j) := by
    intro j hj; rw [r12_1]; exact hPtrs1 j (by omega)
  have hBlock_j : ∀ j : Nat, j < 16 → P16.BlockAt s1.mem (p_j j) (msg_j j) := by
    intro j hj
    have n1 : 1 ≤ n.toNat := by bv_omega
    have n16 : n.toNat ≤ 16 := by bv_omega
    have hj64 : (BitVec.ofNat 64 j).toNat = j := by rw [BitVec.toNat_ofNat]; omega
    have hL := Addn.Mid.Cvl.at_get l base (2 * P16s.lane n (BitVec.ofNat 64 j))
      (by rw [hPairs1.2.1]; unfold P16s.lane; rw [hj64]; split <;> omega)
      hPairs1.2.2 (by rw [hPairs1.2.1]; omega)
    have hR := Addn.Mid.Cvl.at_get l base (2 * P16s.lane n (BitVec.ofNat 64 j) + 1)
      (by rw [hPairs1.2.1]; unfold P16s.lane; rw [hj64]; split <;> omega)
      hPairs1.2.2 (by rw [hPairs1.2.1]; omega)
    have eS := P16s.Mid.spread_eq (base := base) (i := BitVec.ofNat 64 j) n16
    rw [hj64] at eS
    have e1p : base + BitVec.ofNat 64 (32 * (2 * P16s.lane n (BitVec.ofNat 64 j))) = p_j j := by
      rw [show p_j j = Ptrs.spread base n 64#64 j from rfl, eS]; congr 2; omega
    have e2p : base + BitVec.ofNat 64 (32 * (2 * P16s.lane n (BitVec.ofNat 64 j) + 1)) = p_j j + 32#64 := by
      rw [show p_j j = Ptrs.spread base n 64#64 j from rfl, eS]
      apply BitVec.eq_of_toNat_eq; simp only [BitVec.toNat_add, BitVec.toNat_ofNat]; omega
    rw [e1p] at hL; rw [e2p] at hR
    obtain ⟨a0, a1, ha0, ha1, haw⟩ := hL
    obtain ⟨b0, b1, hb0, hb1, hbw⟩ := hR
    have e3p : p_j j + 32#64 + 16#64 = p_j j + 48#64 := by rw [BitVec.add_assoc]; rfl
    rw [e3p] at hb1
    have g1 := getElem!_pos l (2 * P16s.lane n (BitVec.ofNat 64 j)) (by rw [hPairs1.2.1]; unfold P16s.lane; rw [hj64]; split <;> omega)
    have g2 := getElem!_pos l (2 * P16s.lane n (BitVec.ofNat 64 j) + 1) (by rw [hPairs1.2.1]; unfold P16s.lane; rw [hj64]; split <;> omega)
    exact blockAt_of_pairs ha0 ha1 hb0 hb1 (by rw [← g1] at haw; exact haw) (by rw [← g2] at hbw; exact hbw)
  obtain ⟨s2, e2, pc2, hm2, hz2, _, _, _, sp2, bp2, si2, di2, _, r9_2, r12_2, r13_2, r14_2, r15_2, r10_2, _, m2_eq⟩ :=
    P16.transpose_in p_j msg_j s1 pc1 r14_1 hQuad_j hBlock_j
  obtain ⟨s3, e3, pc3, hr11_3, hv3, hm3, sp3, bp3, _, r12_3, r13_3, r14_3, r15_3, _, m3_eq⟩ :=
    block_hdr k0 k1 flags msg_j s2 pc2 (by rw [r13_2, r13_1]) (by rw [r9_2, r9_1]) (by rw [r10_2, r10_1])
      (by rw [di2, rdi_1]) (by rw [si2, rsi_1]) hf (by rw [hz2 0 (by decide)]; exact z0_1)
      (by rw [hz2 1 (by decide)]; exact z1_1) (by rw [hz2 2 (by decide)]; exact z2_1)
      (by rw [hz2 3 (by decide)]; exact z3_1) (by rw [hz2 4 (by decide)]; exact z4_1)
      (by rw [hz2 5 (by decide)]; exact z5_1) (by rw [hz2 6 (by decide)]; exact z6_1)
      (by rw [hz2 7 (by decide)]; exact z7_1) hm2
  have hsp3 : s3.rsp = ((fb + 320#64) &&& 0xFFFFFFFFFFFFFFC0#64) - 256#64 := by rw [sp3, sp2, sp1]
  have hal3 : aligned64 s3.rsp = true := by rw [hsp3, ← sp1]; exact hal1
  have hm_eq3 : s3.mem = s1.mem := by rw [m3_eq, m2_eq]
  have hFp3 : Cells.Region s3.mem s3.rsp 256#64 := by rw [hm_eq3, hsp3]; exact hFpR
  obtain ⟨s4, e4, pc4, hv4, _, _, _, _, sp4, bp4, _, _, _, _, _, r13_4, _, r15_4, _, out4⟩ :=
    P16.seven_rounds _ msg_j s3 pc3 hr11_3 hal3
      (owned64_region hFp3 0#64 (by bv_decide)) (owned64_region hFp3 64#64 (by bv_decide))
      (owned64_region hFp3 128#64 (by bv_decide)) (owned64_region hFp3 192#64 (by bv_decide)) hv3 hm3
  have hfp_b := fp_bounds fb
  have hout4_away : ∀ x : BitVec 64, 320#64 ≤ x - fb → s4.mem x = s1.mem x := fun x hx => by
    have hx' : 256#64 ≤ x - s3.rsp := by rw [hsp3]; exact stack_fp_above hx
    rw [out4 x hx', hm_eq3]
  have hOutR4 : Cells.Region s4.mem s4.r15 512#64 := fun d hd => by
    rw [r15_4, r15_3, r15_2, r15_1]
    rw [hout4_away (out + d) (out_d_ge320 hStackOut hd)]
    exact hOutR1 d hd
  obtain ⟨s5, e5, pc5, hCvs5, _, bp5, _, _, r15_5, _, out5⟩ :=
    P16.transpose_out _ s4 pc4 (by rw [r13_4, r13_3, r13_2, r13_1]) hOutR4 hv4
  have hr15_4 : s4.r15 = out := by rw [r15_4, r15_3, r15_2, r15_1]
  have hout5_stack : ∀ x : BitVec 64, 320#64 ≤ x - fb → (x - fb).toNat < 376 → s5.mem x = s1.mem x := fun x hx1 hx2 => by
    rw [out5 x (by rw [hr15_4]; exact stack_apart_out hStackOut hx2), hout4_away x hx1]
  obtain ⟨s6, e6, pc6, sp6, bx6, bp6, r12_6, r13_6, r14_6, r15_6, m6_eq⟩ :=
    epilogue fb ra sv s5 pc5 (by rw [bp5, bp4, bp3, bp2, bp1])
      (quad_congr (fun x hx => hout5_stack x (fb_quad_ge320 (by decide) (by decide) hx) (fb_quad_lt376 (by decide) (by decide) hx)) hq0_1)
      (quad_congr (fun x hx => hout5_stack x (fb_quad_ge320 (by decide) (by decide) hx) (fb_quad_lt376 (by decide) (by decide) hx)) hq1_1)
      (quad_congr (fun x hx => hout5_stack x (fb_quad_ge320 (by decide) (by decide) hx) (fb_quad_lt376 (by decide) (by decide) hx)) hq2_1)
      (quad_congr (fun x hx => hout5_stack x (fb_quad_ge320 (by decide) (by decide) hx) (fb_quad_lt376 (by decide) (by decide) hx)) hq3_1)
      (quad_congr (fun x hx => hout5_stack x (fb_quad_ge320 (by decide) (by decide) hx) (fb_quad_lt376 (by decide) (by decide) hx)) hq4_1)
      (quad_congr (fun x hx => hout5_stack x (fb_quad_ge320 (by decide) (by decide) hx) (fb_quad_lt376 (by decide) (by decide) hx)) hq5_1)
      (quad_congr (fun x hx => hout5_stack x (fb_quad_ge320 (by decide) (by decide) hx) (fb_quad_lt376 (by decide) (by decide) hx)) hRa1)
  refine ⟨36 + (96 + (19 + (858 + (52 + 9)))), s6, ?_, pc6, sp6.trans (fb_376 fb), bx6, bp6, r12_6, r13_6, r14_6, r15_6, ?_, trivial, ?_⟩
  · rw [steps_add, e1, Option.bind_some, steps_add, e2, Option.bind_some, steps_add, e3, Option.bind_some,
      steps_add, e4, Option.bind_some, steps_add, e5, Option.bind_some, e6]
  · intro x hx hmod
    simp only [P16.contract, Abi.Contract.framed] at hx
    have hmod_out : 512#64 ≤ x - out := by
      simp only [P16.contract, Abi.Contract.framed, abi, List.map_cons, List.map_nil] at hmod
      exact hmod (out, 512#64) (List.mem_cons_self ..)
    rw [m6_eq, out5 x (by rw [hr15_4]; exact hmod_out), hout4_away x (above_376_to_320 hx), hOut1 x (above_376_to_368 hx)]
  · intro p hp
    simp only [P16.contract, Abi.Contract.framed, abi, List.mem_cons, List.not_mem_nil, or_false] at hp
    subst hp
    rw [← m6_eq, hr15_4] at hCvs5
    have hlen := P16s.values_length (k := k) (flags := flags) hn1 hn16 hPairsAt.2.1
    refine cvl_of_cvsOutAt hlen hCvs5 (fun i hi => ?_)
    have hi64 : (BitVec.ofNat 64 i).toNat = i := by rw [BitVec.toNat_ofNat]; omega
    have hget := P16s.values_get (k := k) (flags := flags) hn1 hn16 hPairsAt.2.1 (i := BitVec.ofNat 64 i) (by rw [hi64]; exact hi)
    rw [hi64] at hget
    rw [hget]
    apply congrArg some
    apply Eq.symm
    apply cv_ofFn_eq
    have heq := rounds7_eq_parentNode k0 k1 (l0_j i) (l1_j i) (r0_j i) (r1_j i) flags
    change low8 (rounds7 (initv (cvWords k0 k1) 0#64 64#32 (flags.setWidth 32 ||| 4#32))
        (blockWords (l0_j i) (l1_j i) (r0_j i) (r1_j i))) =
      (Blake3.parentNode k ⟨flags.setWidth 32⟩ (lv_j i) (rv_j i)).cv.map bv
    rw [heq, hkw, words8_mk4_id (lv_j i), words8_mk4_id (rv_j i)]

#print axioms p16_meets

end Proof_p16

