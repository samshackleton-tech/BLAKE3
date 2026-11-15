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
.global b3l_push
.global _b3l_push
.p2align 4
b3l_push:
_b3l_push:
    push rbx
    push rbp
    push r12
    mov rbx, rdi
    mov rbp, rsi
    mov rax, rbx
    mov rax, qword ptr [rax]
    mov r12, rax
    mov rax, rbp
    mov rcx, rbx
    add rcx, 32
    mov rdx, r12
    shl rdx, 5
    add rcx, rdx
    movups xmm0, xmmword ptr [rax + 0]
    movups xmmword ptr [rcx + 0], xmm0
    movups xmm0, xmmword ptr [rax + 16]
    movups xmmword ptr [rcx + 16], xmm0
    mov rax, r12
    add rax, 1
    mov rcx, rbx
    mov qword ptr [rcx], rax
    pop r12
    pop rbp
    pop rbx
    ret
