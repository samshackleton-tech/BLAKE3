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
.global ode_common
.global _ode_common
.p2align 4
ode_common:
_ode_common:
    push rbx
    push rbp
    push r12
    push r13
    push r14
    mov rbx, rdi
    mov rbp, rsi
    mov r12, rdx
    mov rax, 0
    mov r13, rax
    mov rax, 1
    mov r14, rax
.Lode_common_0:
    mov rax, r14
    mov rcx, 1
    cmp rax, rcx
    jne .Lode_common_1
    mov rax, r13
    mov rcx, r12
    cmp rax, rcx
    jae .Lode_common_2
    mov rax, rbx
    add rax, r13
    movzx eax, byte ptr [rax]
    mov rcx, rbp
    add rcx, r13
    movzx ecx, byte ptr [rcx]
    cmp rax, rcx
    jne .Lode_common_4
    mov rax, r13
    add rax, 1
    mov r13, rax
    jmp .Lode_common_5
.Lode_common_4:
    mov rax, 0
    mov r14, rax
.Lode_common_5:
    jmp .Lode_common_3
.Lode_common_2:
    mov rax, 0
    mov r14, rax
.Lode_common_3:
    jmp .Lode_common_0
.Lode_common_1:
    mov rax, r13
    pop r14
    pop r13
    pop r12
    pop rbp
    pop rbx
    ret
