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
.global b3l_hashf
.global _b3l_hashf
.p2align 4
b3l_hashf:
_b3l_hashf:
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
    mov r14, r8
    mov r15, r9
    mov rax, r15
    mov rcx, 5
    cmp rax, rcx
    jne .Lb3l_hashf_0
    mov rdi, rbx
    mov rsi, rbp
    mov rdx, r12
    mov rcx, r13
    mov r8, r14
    call CALL(b3l_hashw)
    jmp .Lb3l_hashf_1
.Lb3l_hashf_0:
    mov rdi, rbx
    mov rsi, rbp
    mov rdx, r12
    mov rcx, r13
    mov r8, r14
    mov r9, r15
    call CALL(b3l_hashl)
.Lb3l_hashf_1:
    add rsp, 8
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    pop rbx
    ret
