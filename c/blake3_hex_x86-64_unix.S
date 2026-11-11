// blake3_servil_hex: the 64 hexadecimal characters of the 32 bytes at RSI, written at RDI.
// SSE2, 45 instructions: no table and no branch, so no address and no jump depends on the bytes.
//
// Not written by hand. Printed from the kernel `hex` of tools/verify/machine/lang/hasher.ode (branch
// experiment/sam-machine-code-lean of samshackleton-tech/BLAKE3, commit e54162a1) by that folder's
// compiler, which also writes the proof Lean checks there (`hex_meets_its_contract`, Proof_hex.lean):
// these instructions write the hexadecimal of the bytes read, change no other byte, keep the registers
// a callee keeps, and show an observer one list of addresses whatever the bytes are.
#if defined(__ELF__) && defined(__linux__)
.section .note.GNU-stack,"",%progbits
#endif
#ifdef __APPLE__
#define CALL(f) _##f
#else
#define CALL(f) f@PLT
#endif
.intel_syntax noprefix
#ifdef __APPLE__
.static_data
#else
.section .rodata
#endif
.p2align 6
.Lode_data_nib:
    .long 252645135
    .long 252645135
    .long 252645135
    .long 252645135
.p2align 6
.Lode_data_nine:
    .long 151587081
    .long 151587081
    .long 151587081
    .long 151587081
.p2align 6
.Lode_data_alpha:
    .long 656877351
    .long 656877351
    .long 656877351
    .long 656877351
.p2align 6
.Lode_data_zero:
    .long 808464432
    .long 808464432
    .long 808464432
    .long 808464432
.text
.text
.global blake3_servil_hex
.global _blake3_servil_hex
.p2align 4
blake3_servil_hex:
_blake3_servil_hex:
    movdqu xmm0, xmmword ptr [rsi]
    movdqu xmm1, xmmword ptr [rsi + 16]
    movdqa xmm5, xmmword ptr [rip + .Lode_data_nib]
    movdqa xmm6, xmmword ptr [rip + .Lode_data_nine]
    movdqa xmm7, xmmword ptr [rip + .Lode_data_alpha]
    movdqa xmm8, xmmword ptr [rip + .Lode_data_zero]
    movdqa xmm2, xmm0
    psrlw xmm2, 4
    pand xmm2, xmm5
    pand xmm0, xmm5
    movdqa xmm3, xmm2
    punpcklbw xmm3, xmm0
    punpckhbw xmm2, xmm0
    movdqa xmm4, xmm3
    pcmpgtb xmm4, xmm6
    pand xmm4, xmm7
    paddb xmm3, xmm4
    paddb xmm3, xmm8
    movdqa xmm4, xmm2
    pcmpgtb xmm4, xmm6
    pand xmm4, xmm7
    paddb xmm2, xmm4
    paddb xmm2, xmm8
    movdqu xmmword ptr [rdi + 0], xmm3
    movdqu xmmword ptr [rdi + 0 + 16], xmm2
    movdqa xmm2, xmm1
    psrlw xmm2, 4
    pand xmm2, xmm5
    pand xmm1, xmm5
    movdqa xmm3, xmm2
    punpcklbw xmm3, xmm1
    punpckhbw xmm2, xmm1
    movdqa xmm4, xmm3
    pcmpgtb xmm4, xmm6
    pand xmm4, xmm7
    paddb xmm3, xmm4
    paddb xmm3, xmm8
    movdqa xmm4, xmm2
    pcmpgtb xmm4, xmm6
    pand xmm4, xmm7
    paddb xmm2, xmm4
    paddb xmm2, xmm8
    movdqu xmmword ptr [rdi + 32], xmm3
    movdqu xmmword ptr [rdi + 32 + 16], xmm2
    ret
