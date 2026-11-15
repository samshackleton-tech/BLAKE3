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
.global b3l_addn
.global _b3l_addn
.p2align 4
b3l_addn:
_b3l_addn:
    push rbx
    push rbp
    push r12
    push r13
    push r14
    push r15
    sub rsp, 8
    mov r12, rdi
    mov r13, rsi
    mov r14, rdx
    mov qword ptr [rsp + 0], rcx
    mov r15, r8
    mov rax, 0
    mov rbx, rax
    mov rax, qword ptr [rsp + 0]
    mov rbp, rax
.Lb3l_addn_0:
    mov rax, rbx
    mov rcx, r15
    cmp rax, rcx
    jae .Lb3l_addn_1
    mov rdi, r12
    mov rsi, r13
    mov rdx, r14
    mov rcx, 5
    mov r8, rbp
    call CALL(b3l_ladd)
    mov rax, rbp
    add rax, 32
    mov rbp, rax
    mov rax, rbx
    add rax, 1
    mov rbx, rax
    jmp .Lb3l_addn_0
.Lb3l_addn_1:
    add rsp, 8
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    pop rbx
    ret
