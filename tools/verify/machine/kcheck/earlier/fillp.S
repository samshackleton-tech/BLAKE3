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
.global b3l_fillp
.global _b3l_fillp
.p2align 4
b3l_fillp:
_b3l_fillp:
    push rbx
    push rbp
    push r12
    push r13
    push r14
    push r15
    sub rsp, 8
    mov rbx, rdi
    mov rbp, rsi
    mov r12, rdx
    mov r13, rcx
    mov rax, 0
    mov r14, rax
    mov rax, rbp
    mov r15, rax
.Lb3l_fillp_0:
    mov rax, r14
    mov rcx, 32
    cmp rax, rcx
    jae .Lb3l_fillp_1
    mov rax, r14
    mov rcx, r12
    cmp rax, rcx
    jae .Lb3l_fillp_2
    mov rax, r15
    mov rcx, rbx
    mov rdx, r14
    shl rdx, 3
    add rcx, rdx
    mov qword ptr [rcx], rax
    jmp .Lb3l_fillp_3
.Lb3l_fillp_2:
    mov rax, rbp
    mov rcx, rbx
    mov rdx, r14
    shl rdx, 3
    add rcx, rdx
    mov qword ptr [rcx], rax
.Lb3l_fillp_3:
    mov rax, r15
    add rax, r13
    mov r15, rax
    mov rax, r14
    add rax, 1
    mov r14, rax
    jmp .Lb3l_fillp_0
.Lb3l_fillp_1:
    add rsp, 8
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    pop rbx
    ret
