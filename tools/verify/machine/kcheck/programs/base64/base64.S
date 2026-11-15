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
.global ode_base64
.global _ode_base64
.p2align 4
ode_base64:
_ode_base64:
    push rbx
    push rbp
    push r12
    push r13
    push r14
    push r15
    sub rsp, 72
    mov rbx, rdi
    mov rbp, rsi
    mov r12, rdx
    mov r13, rcx
    mov rax, 0
    mov r14, rax
    mov rax, 0
    mov r15, rax
    mov rax, 0
    mov qword ptr [rsp + 0], rax
    mov rax, 0
    mov qword ptr [rsp + 8], rax
    mov rax, 0
    mov qword ptr [rsp + 16], rax
    mov rax, 0
    mov qword ptr [rsp + 24], rax
    mov rax, 0
    mov qword ptr [rsp + 32], rax
    mov rax, 0
    mov qword ptr [rsp + 40], rax
    mov rax, 0
    mov qword ptr [rsp + 48], rax
    mov rax, 1
    mov qword ptr [rsp + 56], rax
.Lode_base64_0:
    mov rax, qword ptr [rsp + 56]
    mov rcx, 1
    cmp rax, rcx
    jne .Lode_base64_1
    mov rax, r13
    sub rax, r14
    mov qword ptr [rsp + 48], rax
    mov rax, qword ptr [rsp + 48]
    mov rcx, 0
    cmp rax, rcx
    jne .Lode_base64_2
    mov rax, 0
    mov qword ptr [rsp + 56], rax
    jmp .Lode_base64_3
.Lode_base64_2:
    mov rax, r12
    add rax, r14
    movzx eax, byte ptr [rax]
    shr rax, 2
    mov qword ptr [rsp + 0], rax
    mov rax, r12
    add rax, r14
    movzx eax, byte ptr [rax]
    and rax, 3
    shl rax, 4
    mov qword ptr [rsp + 8], rax
    mov rax, 64
    mov qword ptr [rsp + 16], rax
    mov rax, 64
    mov qword ptr [rsp + 24], rax
    mov rax, qword ptr [rsp + 48]
    mov rcx, 2
    cmp rax, rcx
    jae .Lode_base64_4
    jmp .Lode_base64_5
.Lode_base64_4:
    mov rax, qword ptr [rsp + 8]
    mov rcx, r12
    add rcx, r14
    add rcx, 1
    movzx ecx, byte ptr [rcx]
    shr rcx, 4
    add rax, rcx
    mov qword ptr [rsp + 8], rax
    mov rax, r12
    add rax, r14
    add rax, 1
    movzx eax, byte ptr [rax]
    and rax, 15
    shl rax, 2
    mov qword ptr [rsp + 16], rax
    mov rax, qword ptr [rsp + 48]
    mov rcx, 3
    cmp rax, rcx
    jae .Lode_base64_6
    jmp .Lode_base64_7
.Lode_base64_6:
    mov rax, qword ptr [rsp + 16]
    mov rcx, r12
    add rcx, r14
    add rcx, 2
    movzx ecx, byte ptr [rcx]
    shr rcx, 6
    add rax, rcx
    mov qword ptr [rsp + 16], rax
    mov rax, r12
    add rax, r14
    add rax, 2
    movzx eax, byte ptr [rax]
    and rax, 63
    mov qword ptr [rsp + 24], rax
.Lode_base64_7:
.Lode_base64_5:
    mov rax, 0
    mov qword ptr [rsp + 32], rax
.Lode_base64_8:
    mov rax, qword ptr [rsp + 32]
    mov rcx, 4
    cmp rax, rcx
    jae .Lode_base64_9
    mov rax, qword ptr [rsp + 0]
    mov qword ptr [rsp + 40], rax
    mov rax, qword ptr [rsp + 32]
    mov rcx, 1
    cmp rax, rcx
    jne .Lode_base64_10
    mov rax, qword ptr [rsp + 8]
    mov qword ptr [rsp + 40], rax
.Lode_base64_10:
    mov rax, qword ptr [rsp + 32]
    mov rcx, 2
    cmp rax, rcx
    jne .Lode_base64_12
    mov rax, qword ptr [rsp + 16]
    mov qword ptr [rsp + 40], rax
.Lode_base64_12:
    mov rax, qword ptr [rsp + 32]
    mov rcx, 3
    cmp rax, rcx
    jne .Lode_base64_14
    mov rax, qword ptr [rsp + 24]
    mov qword ptr [rsp + 40], rax
.Lode_base64_14:
    mov rax, qword ptr [rsp + 40]
    mov rcx, 26
    cmp rax, rcx
    jae .Lode_base64_16
    mov rax, qword ptr [rsp + 40]
    add rax, 65
    mov qword ptr [rsp + 40], rax
    jmp .Lode_base64_17
.Lode_base64_16:
    mov rax, qword ptr [rsp + 40]
    mov rcx, 52
    cmp rax, rcx
    jae .Lode_base64_18
    mov rax, qword ptr [rsp + 40]
    add rax, 71
    mov qword ptr [rsp + 40], rax
    jmp .Lode_base64_19
.Lode_base64_18:
    mov rax, qword ptr [rsp + 40]
    mov rcx, 62
    cmp rax, rcx
    jae .Lode_base64_20
    mov rax, qword ptr [rsp + 40]
    sub rax, 4
    mov qword ptr [rsp + 40], rax
    jmp .Lode_base64_21
.Lode_base64_20:
    mov rax, qword ptr [rsp + 40]
    mov rcx, 62
    cmp rax, rcx
    jne .Lode_base64_22
    mov rax, 43
    mov qword ptr [rsp + 40], rax
    jmp .Lode_base64_23
.Lode_base64_22:
    mov rax, qword ptr [rsp + 40]
    mov rcx, 63
    cmp rax, rcx
    jne .Lode_base64_24
    mov rax, 47
    mov qword ptr [rsp + 40], rax
    jmp .Lode_base64_25
.Lode_base64_24:
    mov rax, 61
    mov qword ptr [rsp + 40], rax
.Lode_base64_25:
.Lode_base64_23:
.Lode_base64_21:
.Lode_base64_19:
.Lode_base64_17:
    mov rax, qword ptr [rsp + 40]
    mov rcx, rbx
    add rcx, r15
    add rcx, qword ptr [rsp + 32]
    mov byte ptr [rcx], al
    mov rax, qword ptr [rsp + 32]
    add rax, 1
    mov qword ptr [rsp + 32], rax
    jmp .Lode_base64_8
.Lode_base64_9:
    mov rax, r15
    add rax, 4
    mov r15, rax
    mov rax, qword ptr [rsp + 48]
    mov rcx, 3
    cmp rax, rcx
    jae .Lode_base64_26
    mov rax, 0
    mov qword ptr [rsp + 56], rax
    jmp .Lode_base64_27
.Lode_base64_26:
    mov rax, r14
    add rax, 3
    mov r14, rax
.Lode_base64_27:
.Lode_base64_3:
    jmp .Lode_base64_0
.Lode_base64_1:
    mov rax, r15
    add rsp, 72
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    pop rbx
    ret
