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
.global ode_lz4_pack
.global _ode_lz4_pack
.p2align 4
ode_lz4_pack:
_ode_lz4_pack:
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
    mov qword ptr [rsp + 0], r8
    mov rax, 0
    mov r14, rax
    mov rax, 0
    mov r15, rax
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
    mov rax, 0
    mov qword ptr [rsp + 56], rax
.Lode_lz4_pack_0:
    mov rax, qword ptr [rsp + 16]
    mov rcx, 0
    cmp rax, rcx
    jne .Lode_lz4_pack_1
    mov rax, r14
    mov rcx, r13
    cmp rax, rcx
    jae .Lode_lz4_pack_2
    mov rax, 0
    mov qword ptr [rsp + 24], rax
    mov rax, r14
    mov rcx, qword ptr [rsp + 0]
    cmp rax, rcx
    jae .Lode_lz4_pack_4
    jmp .Lode_lz4_pack_5
.Lode_lz4_pack_4:
    mov rax, r13
    sub rax, r14
    mov rcx, 12
    cmp rax, rcx
    jae .Lode_lz4_pack_6
    jmp .Lode_lz4_pack_7
.Lode_lz4_pack_6:
    mov rax, 1
    mov qword ptr [rsp + 32], rax
.Lode_lz4_pack_8:
    mov rax, qword ptr [rsp + 32]
    mov rcx, 1
    cmp rax, rcx
    jne .Lode_lz4_pack_9
    mov rax, qword ptr [rsp + 24]
    mov rcx, 18
    cmp rax, rcx
    jae .Lode_lz4_pack_10
    mov rax, 5
    mov rcx, r13
    sub rcx, r14
    sub rcx, qword ptr [rsp + 24]
    cmp rax, rcx
    jae .Lode_lz4_pack_12
    mov rax, r12
    add rax, r14
    add rax, qword ptr [rsp + 24]
    movzx eax, byte ptr [rax]
    mov rcx, r12
    add rcx, r14
    add rcx, qword ptr [rsp + 24]
    sub rcx, qword ptr [rsp + 0]
    movzx ecx, byte ptr [rcx]
    cmp rax, rcx
    jne .Lode_lz4_pack_14
    mov rax, qword ptr [rsp + 24]
    add rax, 1
    mov qword ptr [rsp + 24], rax
    jmp .Lode_lz4_pack_15
.Lode_lz4_pack_14:
    mov rax, 0
    mov qword ptr [rsp + 32], rax
.Lode_lz4_pack_15:
    jmp .Lode_lz4_pack_13
.Lode_lz4_pack_12:
    mov rax, 0
    mov qword ptr [rsp + 32], rax
.Lode_lz4_pack_13:
    jmp .Lode_lz4_pack_11
.Lode_lz4_pack_10:
    mov rax, 0
    mov qword ptr [rsp + 32], rax
.Lode_lz4_pack_11:
    jmp .Lode_lz4_pack_8
.Lode_lz4_pack_9:
.Lode_lz4_pack_7:
.Lode_lz4_pack_5:
    mov rax, qword ptr [rsp + 24]
    mov rcx, 4
    cmp rax, rcx
    jae .Lode_lz4_pack_16
    mov rax, r14
    add rax, 1
    mov r14, rax
    jmp .Lode_lz4_pack_17
.Lode_lz4_pack_16:
    mov rax, r14
    sub rax, qword ptr [rsp + 8]
    mov qword ptr [rsp + 40], rax
    mov rax, r15
    mov rcx, rbp
    cmp rax, rcx
    jae .Lode_lz4_pack_18
    mov rax, qword ptr [rsp + 40]
    mov rcx, 15
    cmp rax, rcx
    jae .Lode_lz4_pack_20
    mov rax, qword ptr [rsp + 40]
    shl rax, 4
    add rax, qword ptr [rsp + 24]
    sub rax, 4
    mov rcx, rbx
    add rcx, r15
    mov byte ptr [rcx], al
    mov rax, r15
    add rax, 1
    mov r15, rax
    jmp .Lode_lz4_pack_21
.Lode_lz4_pack_20:
    mov rax, 236
    add rax, qword ptr [rsp + 24]
    mov rcx, rbx
    add rcx, r15
    mov byte ptr [rcx], al
    mov rax, r15
    add rax, 1
    mov r15, rax
    mov rax, qword ptr [rsp + 40]
    sub rax, 15
    mov qword ptr [rsp + 48], rax
    mov rax, 1
    mov qword ptr [rsp + 32], rax
.Lode_lz4_pack_22:
    mov rax, qword ptr [rsp + 32]
    mov rcx, 1
    cmp rax, rcx
    jne .Lode_lz4_pack_23
    mov rax, r15
    mov rcx, rbp
    cmp rax, rcx
    jae .Lode_lz4_pack_24
    mov rax, qword ptr [rsp + 48]
    mov rcx, 255
    cmp rax, rcx
    jae .Lode_lz4_pack_26
    mov rax, qword ptr [rsp + 48]
    mov rcx, rbx
    add rcx, r15
    mov byte ptr [rcx], al
    mov rax, r15
    add rax, 1
    mov r15, rax
    mov rax, 0
    mov qword ptr [rsp + 32], rax
    jmp .Lode_lz4_pack_27
.Lode_lz4_pack_26:
    mov rax, 255
    mov rcx, rbx
    add rcx, r15
    mov byte ptr [rcx], al
    mov rax, r15
    add rax, 1
    mov r15, rax
    mov rax, qword ptr [rsp + 48]
    sub rax, 255
    mov qword ptr [rsp + 48], rax
.Lode_lz4_pack_27:
    jmp .Lode_lz4_pack_25
.Lode_lz4_pack_24:
    mov rax, 2
    mov qword ptr [rsp + 16], rax
    mov rax, 0
    mov qword ptr [rsp + 32], rax
.Lode_lz4_pack_25:
    jmp .Lode_lz4_pack_22
.Lode_lz4_pack_23:
.Lode_lz4_pack_21:
    mov rax, qword ptr [rsp + 16]
    mov rcx, 0
    cmp rax, rcx
    jne .Lode_lz4_pack_28
    mov rax, rbp
    sub rax, r15
    mov rcx, qword ptr [rsp + 40]
    cmp rax, rcx
    jae .Lode_lz4_pack_30
    mov rax, 2
    mov qword ptr [rsp + 16], rax
    jmp .Lode_lz4_pack_31
.Lode_lz4_pack_30:
    mov rax, 0
    mov qword ptr [rsp + 56], rax
.Lode_lz4_pack_32:
    mov rax, qword ptr [rsp + 56]
    mov rcx, qword ptr [rsp + 40]
    cmp rax, rcx
    jae .Lode_lz4_pack_33
    mov rax, r12
    add rax, qword ptr [rsp + 8]
    add rax, qword ptr [rsp + 56]
    movzx eax, byte ptr [rax]
    mov rcx, rbx
    add rcx, r15
    mov byte ptr [rcx], al
    mov rax, r15
    add rax, 1
    mov r15, rax
    mov rax, qword ptr [rsp + 56]
    add rax, 1
    mov qword ptr [rsp + 56], rax
    jmp .Lode_lz4_pack_32
.Lode_lz4_pack_33:
    mov rax, rbp
    sub rax, r15
    mov rcx, 2
    cmp rax, rcx
    jae .Lode_lz4_pack_34
    mov rax, 2
    mov qword ptr [rsp + 16], rax
    jmp .Lode_lz4_pack_35
.Lode_lz4_pack_34:
    mov rax, qword ptr [rsp + 0]
    and rax, 255
    mov rcx, rbx
    add rcx, r15
    mov byte ptr [rcx], al
    mov rax, qword ptr [rsp + 0]
    shr rax, 8
    mov rcx, rbx
    add rcx, r15
    add rcx, 1
    mov byte ptr [rcx], al
    mov rax, r15
    add rax, 2
    mov r15, rax
    mov rax, r14
    add rax, qword ptr [rsp + 24]
    mov r14, rax
    mov rax, r14
    mov qword ptr [rsp + 8], rax
.Lode_lz4_pack_35:
.Lode_lz4_pack_31:
.Lode_lz4_pack_28:
    jmp .Lode_lz4_pack_19
.Lode_lz4_pack_18:
    mov rax, 2
    mov qword ptr [rsp + 16], rax
.Lode_lz4_pack_19:
.Lode_lz4_pack_17:
    jmp .Lode_lz4_pack_3
.Lode_lz4_pack_2:
    mov rax, 1
    mov qword ptr [rsp + 16], rax
.Lode_lz4_pack_3:
    jmp .Lode_lz4_pack_0
.Lode_lz4_pack_1:
    mov rax, 18446744073709551615
    mov qword ptr [rsp + 64], rax
    mov rax, qword ptr [rsp + 16]
    mov rcx, 1
    cmp rax, rcx
    jne .Lode_lz4_pack_36
    mov rax, r13
    sub rax, qword ptr [rsp + 8]
    mov qword ptr [rsp + 40], rax
    mov rax, r15
    mov rcx, rbp
    cmp rax, rcx
    jae .Lode_lz4_pack_38
    mov rax, qword ptr [rsp + 40]
    mov rcx, 15
    cmp rax, rcx
    jae .Lode_lz4_pack_40
    mov rax, qword ptr [rsp + 40]
    shl rax, 4
    mov rcx, rbx
    add rcx, r15
    mov byte ptr [rcx], al
    mov rax, r15
    add rax, 1
    mov r15, rax
    jmp .Lode_lz4_pack_41
.Lode_lz4_pack_40:
    mov rax, 240
    mov rcx, rbx
    add rcx, r15
    mov byte ptr [rcx], al
    mov rax, r15
    add rax, 1
    mov r15, rax
    mov rax, qword ptr [rsp + 40]
    sub rax, 15
    mov qword ptr [rsp + 48], rax
    mov rax, 1
    mov qword ptr [rsp + 32], rax
.Lode_lz4_pack_42:
    mov rax, qword ptr [rsp + 32]
    mov rcx, 1
    cmp rax, rcx
    jne .Lode_lz4_pack_43
    mov rax, r15
    mov rcx, rbp
    cmp rax, rcx
    jae .Lode_lz4_pack_44
    mov rax, qword ptr [rsp + 48]
    mov rcx, 255
    cmp rax, rcx
    jae .Lode_lz4_pack_46
    mov rax, qword ptr [rsp + 48]
    mov rcx, rbx
    add rcx, r15
    mov byte ptr [rcx], al
    mov rax, r15
    add rax, 1
    mov r15, rax
    mov rax, 0
    mov qword ptr [rsp + 32], rax
    jmp .Lode_lz4_pack_47
.Lode_lz4_pack_46:
    mov rax, 255
    mov rcx, rbx
    add rcx, r15
    mov byte ptr [rcx], al
    mov rax, r15
    add rax, 1
    mov r15, rax
    mov rax, qword ptr [rsp + 48]
    sub rax, 255
    mov qword ptr [rsp + 48], rax
.Lode_lz4_pack_47:
    jmp .Lode_lz4_pack_45
.Lode_lz4_pack_44:
    mov rax, 2
    mov qword ptr [rsp + 16], rax
    mov rax, 0
    mov qword ptr [rsp + 32], rax
.Lode_lz4_pack_45:
    jmp .Lode_lz4_pack_42
.Lode_lz4_pack_43:
.Lode_lz4_pack_41:
    mov rax, qword ptr [rsp + 16]
    mov rcx, 1
    cmp rax, rcx
    jne .Lode_lz4_pack_48
    mov rax, rbp
    sub rax, r15
    mov rcx, qword ptr [rsp + 40]
    cmp rax, rcx
    jae .Lode_lz4_pack_50
    mov rax, 2
    mov qword ptr [rsp + 16], rax
    jmp .Lode_lz4_pack_51
.Lode_lz4_pack_50:
    mov rax, 0
    mov qword ptr [rsp + 56], rax
.Lode_lz4_pack_52:
    mov rax, qword ptr [rsp + 56]
    mov rcx, qword ptr [rsp + 40]
    cmp rax, rcx
    jae .Lode_lz4_pack_53
    mov rax, r12
    add rax, qword ptr [rsp + 8]
    add rax, qword ptr [rsp + 56]
    movzx eax, byte ptr [rax]
    mov rcx, rbx
    add rcx, r15
    mov byte ptr [rcx], al
    mov rax, r15
    add rax, 1
    mov r15, rax
    mov rax, qword ptr [rsp + 56]
    add rax, 1
    mov qword ptr [rsp + 56], rax
    jmp .Lode_lz4_pack_52
.Lode_lz4_pack_53:
    mov rax, r15
    mov qword ptr [rsp + 64], rax
.Lode_lz4_pack_51:
.Lode_lz4_pack_48:
    jmp .Lode_lz4_pack_39
.Lode_lz4_pack_38:
    mov rax, 2
    mov qword ptr [rsp + 16], rax
.Lode_lz4_pack_39:
.Lode_lz4_pack_36:
    mov rax, qword ptr [rsp + 64]
    add rsp, 72
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    pop rbx
    ret
