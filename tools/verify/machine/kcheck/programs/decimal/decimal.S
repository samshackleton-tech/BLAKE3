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
.global ode_decimal
.global _ode_decimal
.p2align 4
ode_decimal:
_ode_decimal:
    push rbx
    push rbp
    push r12
    push r13
    push r14
    push r15
    sub rsp, 8
    mov rbx, rdi
    mov rbp, rsi
    mov rax, 0
    mov r12, rax
    mov rax, 0
    mov r13, rax
    mov rax, 0
    mov r15, rax
    mov rax, 0
    mov r14, rax
    mov rax, 0
    mov qword ptr [rsp + 0], rax
    mov rax, rbp
    mov rcx, 0
    cmp rax, rcx
    jne .Lode_decimal_0
    mov rax, 2
    mov r14, rax
.Lode_decimal_0:
    mov rax, 9
    mov rcx, rbp
    cmp rax, rcx
    jae .Lode_decimal_2
    mov rax, 2
    mov r14, rax
.Lode_decimal_2:
.Lode_decimal_4:
    mov rax, r14
    mov rcx, 0
    cmp rax, rcx
    jne .Lode_decimal_5
    mov rax, r12
    mov rcx, rbp
    cmp rax, rcx
    jae .Lode_decimal_6
    mov rax, rbx
    add rax, r12
    movzx eax, byte ptr [rax]
    mov r15, rax
    mov rax, r15
    mov rcx, 48
    cmp rax, rcx
    jae .Lode_decimal_8
    mov rax, 2
    mov r14, rax
    jmp .Lode_decimal_9
.Lode_decimal_8:
    mov rax, 57
    mov rcx, r15
    cmp rax, rcx
    jae .Lode_decimal_10
    mov rax, 2
    mov r14, rax
    jmp .Lode_decimal_11
.Lode_decimal_10:
    mov rax, r13
    shl rax, 3
    mov rcx, r13
    shl rcx, 1
    add rax, rcx
    add rax, r15
    sub rax, 48
    mov r13, rax
    mov rax, r12
    add rax, 1
    mov r12, rax
.Lode_decimal_11:
.Lode_decimal_9:
    jmp .Lode_decimal_7
.Lode_decimal_6:
    mov rax, 1
    mov r14, rax
.Lode_decimal_7:
    jmp .Lode_decimal_4
.Lode_decimal_5:
    mov rax, r13
    mov qword ptr [rsp + 0], rax
    mov rax, r14
    mov rcx, 2
    cmp rax, rcx
    jne .Lode_decimal_12
    mov rax, 18446744073709551615
    mov qword ptr [rsp + 0], rax
.Lode_decimal_12:
    mov rax, qword ptr [rsp + 0]
    add rsp, 8
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    pop rbx
    ret
