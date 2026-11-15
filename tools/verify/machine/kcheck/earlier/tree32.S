// Printed from Lean (Lang.lean). Not written or edited by hand.
#if defined(__ELF__) && defined(__linux__)
.section .note.GNU-stack,"",%progbits
#endif
#ifdef __APPLE__
#define CALL(f) _##f
#else
#define CALL(f) f@PLT
#endif
.intel_syntax noprefix
.text
.global b3l_tree32
.global _b3l_tree32
.p2align 4
b3l_tree32:
_b3l_tree32:
    push rbx
    push rbp
    push r12
    push r13
    push r14
    sub rsp, 1280
    mov rbx, rdi
    mov rbp, rsi
    mov r12, rdx
    mov r13, rcx
    mov rax, r13
    or rax, 1073741828
    mov r14, rax
    lea rdi, [rsp + 0]
    mov rsi, rbp
    mov rdx, 16
    mov rcx, 64
    call CALL(b3l_fillp)
    lea rdi, [rsp + 0]
    mov rsi, 1
    mov rdx, r12
    mov rcx, 0
    mov r8, r14
    lea r9, [rsp + 256]
    call CALL(blake3_servil_avx512_p16)
    lea rdi, [rsp + 0]
    lea rsi, [rsp + 256]
    mov rdx, 8
    mov rcx, 64
    call CALL(b3l_fillp)
    lea rdi, [rsp + 0]
    mov rsi, 1
    mov rdx, r12
    mov rcx, 0
    mov r8, r14
    lea r9, [rsp + 768]
    call CALL(blake3_servil_avx512_p16)
    lea rdi, [rsp + 0]
    lea rsi, [rsp + 768]
    mov rdx, 4
    mov rcx, 64
    call CALL(b3l_fillp)
    lea rdi, [rsp + 0]
    mov rsi, 1
    mov rdx, r12
    mov rcx, 0
    mov r8, r14
    lea r9, [rsp + 256]
    call CALL(blake3_servil_avx512_p16)
    lea rdi, [rsp + 0]
    lea rsi, [rsp + 256]
    mov rdx, 2
    mov rcx, 64
    call CALL(b3l_fillp)
    lea rdi, [rsp + 0]
    mov rsi, 1
    mov rdx, r12
    mov rcx, 0
    mov r8, r14
    lea r9, [rsp + 768]
    call CALL(blake3_servil_avx512_p16)
    lea rdi, [rsp + 0]
    lea rsi, [rsp + 768]
    mov rdx, 1
    mov rcx, 64
    call CALL(b3l_fillp)
    lea rdi, [rsp + 0]
    mov rsi, 1
    mov rdx, r12
    mov rcx, 0
    mov r8, r14
    mov r9, rbx
    call CALL(blake3_servil_avx512_p16)
    add rsp, 1280
    pop r14
    pop r13
    pop r12
    pop rbp
    pop rbx
    ret
