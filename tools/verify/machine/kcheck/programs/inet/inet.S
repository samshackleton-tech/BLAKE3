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
.global ode_inet
.global _ode_inet
.p2align 4
ode_inet:
_ode_inet:
    push rbx
    push rbp
    push r12
    push r13
    sub rsp, 8
    mov rbx, rdi
    mov rbp, rsi
    mov rax, 0
    mov r12, rax
    mov rax, 0
    mov r13, rax
.Lode_inet_0:
    mov rax, 1
    mov rcx, rbp
    sub rcx, r12
    cmp rax, rcx
    jae .Lode_inet_1
    mov rax, r13
    mov rcx, rbx
    add rcx, r12
    movzx ecx, byte ptr [rcx]
    shl rcx, 8
    add rax, rcx
    mov rcx, rbx
    add rcx, r12
    add rcx, 1
    movzx ecx, byte ptr [rcx]
    add rax, rcx
    mov r13, rax
    mov rax, r12
    add rax, 2
    mov r12, rax
    jmp .Lode_inet_0
.Lode_inet_1:
    mov rax, rbp
    sub rax, r12
    mov rcx, 1
    cmp rax, rcx
    jne .Lode_inet_2
    mov rax, r13
    mov rcx, rbx
    add rcx, r12
    movzx ecx, byte ptr [rcx]
    shl rcx, 8
    add rax, rcx
    mov r13, rax
.Lode_inet_2:
    mov rax, r13
    and rax, 65535
    mov rcx, r13
    shr rcx, 16
    add rax, rcx
    mov r13, rax
    mov rax, r13
    and rax, 65535
    mov rcx, r13
    shr rcx, 16
    add rax, rcx
    mov r13, rax
    mov rax, r13
    and rax, 65535
    mov rcx, r13
    shr rcx, 16
    add rax, rcx
    mov r13, rax
    mov rax, r13
    and rax, 65535
    mov rcx, r13
    shr rcx, 16
    add rax, rcx
    mov r13, rax
    mov rax, 65535
    sub rax, r13
    add rsp, 8
    pop r13
    pop r12
    pop rbp
    pop rbx
    ret
