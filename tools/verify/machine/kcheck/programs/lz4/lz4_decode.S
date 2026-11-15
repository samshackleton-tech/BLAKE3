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
.global ode_lz4_decode
.global _ode_lz4_decode
.p2align 4
ode_lz4_decode:
_ode_lz4_decode:
    push rbx
    push rbp
    push r12
    push r13
    push r14
    push r15
    sub rsp, 56
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
.Lode_lz4_decode_0:
    mov rax, qword ptr [rsp + 0]
    mov rcx, 0
    cmp rax, rcx
    jne .Lode_lz4_decode_1
    mov rax, r14
    mov rcx, r13
    cmp rax, rcx
    jae .Lode_lz4_decode_2
    mov rax, r12
    add rax, r14
    movzx eax, byte ptr [rax]
    mov qword ptr [rsp + 8], rax
    mov rax, r14
    add rax, 1
    mov r14, rax
    mov rax, qword ptr [rsp + 8]
    shr rax, 4
    mov qword ptr [rsp + 16], rax
    mov rax, qword ptr [rsp + 16]
    mov rcx, 15
    cmp rax, rcx
    jae .Lode_lz4_decode_4
    jmp .Lode_lz4_decode_5
.Lode_lz4_decode_4:
    mov rax, 1
    mov qword ptr [rsp + 40], rax
.Lode_lz4_decode_6:
    mov rax, qword ptr [rsp + 40]
    mov rcx, 1
    cmp rax, rcx
    jne .Lode_lz4_decode_7
    mov rax, r14
    mov rcx, r13
    cmp rax, rcx
    jae .Lode_lz4_decode_8
    mov rax, r12
    add rax, r14
    movzx eax, byte ptr [rax]
    mov qword ptr [rsp + 24], rax
    mov rax, r14
    add rax, 1
    mov r14, rax
    mov rax, qword ptr [rsp + 16]
    add rax, qword ptr [rsp + 24]
    mov qword ptr [rsp + 16], rax
    mov rax, qword ptr [rsp + 24]
    mov rcx, 255
    cmp rax, rcx
    jae .Lode_lz4_decode_10
    mov rax, 0
    mov qword ptr [rsp + 40], rax
.Lode_lz4_decode_10:
    jmp .Lode_lz4_decode_9
.Lode_lz4_decode_8:
    mov rax, 2
    mov qword ptr [rsp + 0], rax
    mov rax, 0
    mov qword ptr [rsp + 40], rax
.Lode_lz4_decode_9:
    jmp .Lode_lz4_decode_6
.Lode_lz4_decode_7:
.Lode_lz4_decode_5:
    mov rax, qword ptr [rsp + 0]
    mov rcx, 0
    cmp rax, rcx
    jne .Lode_lz4_decode_12
    mov rax, r13
    sub rax, r14
    mov rcx, qword ptr [rsp + 16]
    cmp rax, rcx
    jae .Lode_lz4_decode_14
    mov rax, 2
    mov qword ptr [rsp + 0], rax
    jmp .Lode_lz4_decode_15
.Lode_lz4_decode_14:
    mov rax, rbp
    sub rax, r15
    mov rcx, qword ptr [rsp + 16]
    cmp rax, rcx
    jae .Lode_lz4_decode_16
    mov rax, 2
    mov qword ptr [rsp + 0], rax
    jmp .Lode_lz4_decode_17
.Lode_lz4_decode_16:
.Lode_lz4_decode_18:
    mov rax, 0
    mov rcx, qword ptr [rsp + 16]
    cmp rax, rcx
    jae .Lode_lz4_decode_19
    mov rax, r12
    add rax, r14
    movzx eax, byte ptr [rax]
    mov rcx, rbx
    add rcx, r15
    mov byte ptr [rcx], al
    mov rax, r15
    add rax, 1
    mov r15, rax
    mov rax, r14
    add rax, 1
    mov r14, rax
    mov rax, qword ptr [rsp + 16]
    sub rax, 1
    mov qword ptr [rsp + 16], rax
    jmp .Lode_lz4_decode_18
.Lode_lz4_decode_19:
    mov rax, r14
    mov rcx, r13
    cmp rax, rcx
    jne .Lode_lz4_decode_20
    mov rax, 1
    mov qword ptr [rsp + 0], rax
    jmp .Lode_lz4_decode_21
.Lode_lz4_decode_20:
    mov rax, r13
    sub rax, r14
    mov rcx, 2
    cmp rax, rcx
    jae .Lode_lz4_decode_22
    mov rax, 2
    mov qword ptr [rsp + 0], rax
    jmp .Lode_lz4_decode_23
.Lode_lz4_decode_22:
    mov rax, r12
    add rax, r14
    movzx eax, byte ptr [rax]
    mov rcx, r12
    add rcx, r14
    add rcx, 1
    movzx ecx, byte ptr [rcx]
    shl rcx, 8
    add rax, rcx
    mov qword ptr [rsp + 32], rax
    mov rax, r14
    add rax, 2
    mov r14, rax
    mov rax, qword ptr [rsp + 32]
    mov rcx, 0
    cmp rax, rcx
    jne .Lode_lz4_decode_24
    mov rax, 2
    mov qword ptr [rsp + 0], rax
    jmp .Lode_lz4_decode_25
.Lode_lz4_decode_24:
    mov rax, r15
    mov rcx, qword ptr [rsp + 32]
    cmp rax, rcx
    jae .Lode_lz4_decode_26
    mov rax, 2
    mov qword ptr [rsp + 0], rax
    jmp .Lode_lz4_decode_27
.Lode_lz4_decode_26:
    mov rax, qword ptr [rsp + 8]
    and rax, 15
    mov qword ptr [rsp + 16], rax
    mov rax, qword ptr [rsp + 16]
    mov rcx, 15
    cmp rax, rcx
    jae .Lode_lz4_decode_28
    jmp .Lode_lz4_decode_29
.Lode_lz4_decode_28:
    mov rax, 1
    mov qword ptr [rsp + 40], rax
.Lode_lz4_decode_30:
    mov rax, qword ptr [rsp + 40]
    mov rcx, 1
    cmp rax, rcx
    jne .Lode_lz4_decode_31
    mov rax, r14
    mov rcx, r13
    cmp rax, rcx
    jae .Lode_lz4_decode_32
    mov rax, r12
    add rax, r14
    movzx eax, byte ptr [rax]
    mov qword ptr [rsp + 24], rax
    mov rax, r14
    add rax, 1
    mov r14, rax
    mov rax, qword ptr [rsp + 16]
    add rax, qword ptr [rsp + 24]
    mov qword ptr [rsp + 16], rax
    mov rax, qword ptr [rsp + 24]
    mov rcx, 255
    cmp rax, rcx
    jae .Lode_lz4_decode_34
    mov rax, 0
    mov qword ptr [rsp + 40], rax
.Lode_lz4_decode_34:
    jmp .Lode_lz4_decode_33
.Lode_lz4_decode_32:
    mov rax, 2
    mov qword ptr [rsp + 0], rax
    mov rax, 0
    mov qword ptr [rsp + 40], rax
.Lode_lz4_decode_33:
    jmp .Lode_lz4_decode_30
.Lode_lz4_decode_31:
.Lode_lz4_decode_29:
    mov rax, qword ptr [rsp + 0]
    mov rcx, 0
    cmp rax, rcx
    jne .Lode_lz4_decode_36
    mov rax, rbp
    sub rax, r15
    mov rcx, 4
    cmp rax, rcx
    jae .Lode_lz4_decode_38
    mov rax, 2
    mov qword ptr [rsp + 0], rax
    jmp .Lode_lz4_decode_39
.Lode_lz4_decode_38:
    mov rax, rbp
    sub rax, r15
    sub rax, 4
    mov rcx, qword ptr [rsp + 16]
    cmp rax, rcx
    jae .Lode_lz4_decode_40
    mov rax, 2
    mov qword ptr [rsp + 0], rax
    jmp .Lode_lz4_decode_41
.Lode_lz4_decode_40:
    mov rax, qword ptr [rsp + 16]
    add rax, 4
    mov qword ptr [rsp + 16], rax
.Lode_lz4_decode_42:
    mov rax, 0
    mov rcx, qword ptr [rsp + 16]
    cmp rax, rcx
    jae .Lode_lz4_decode_43
    mov rax, rbx
    add rax, r15
    sub rax, qword ptr [rsp + 32]
    movzx eax, byte ptr [rax]
    mov rcx, rbx
    add rcx, r15
    mov byte ptr [rcx], al
    mov rax, r15
    add rax, 1
    mov r15, rax
    mov rax, qword ptr [rsp + 16]
    sub rax, 1
    mov qword ptr [rsp + 16], rax
    jmp .Lode_lz4_decode_42
.Lode_lz4_decode_43:
.Lode_lz4_decode_41:
.Lode_lz4_decode_39:
.Lode_lz4_decode_36:
.Lode_lz4_decode_27:
.Lode_lz4_decode_25:
.Lode_lz4_decode_23:
.Lode_lz4_decode_21:
.Lode_lz4_decode_17:
.Lode_lz4_decode_15:
.Lode_lz4_decode_12:
    jmp .Lode_lz4_decode_3
.Lode_lz4_decode_2:
    mov rax, 2
    mov qword ptr [rsp + 0], rax
.Lode_lz4_decode_3:
    jmp .Lode_lz4_decode_0
.Lode_lz4_decode_1:
    mov rax, r15
    mov qword ptr [rsp + 48], rax
    mov rax, qword ptr [rsp + 0]
    mov rcx, 2
    cmp rax, rcx
    jne .Lode_lz4_decode_44
    mov rax, 18446744073709551615
    mov qword ptr [rsp + 48], rax
.Lode_lz4_decode_44:
    mov rax, qword ptr [rsp + 48]
    add rsp, 56
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    pop rbx
    ret
