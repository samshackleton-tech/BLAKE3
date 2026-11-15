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
.global ode_utf8
.global _ode_utf8
.p2align 4
ode_utf8:
_ode_utf8:
    push rbx
    push rbp
    push r12
    push r13
    push r14
    push r15
    sub rsp, 40
    mov rbx, rdi
    mov rbp, rsi
    mov rax, 0
    mov r12, rax
    mov rax, 0
    mov r13, rax
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
.Lode_utf8_0:
    mov rax, qword ptr [rsp + 16]
    mov rcx, 0
    cmp rax, rcx
    jne .Lode_utf8_1
    mov rax, r12
    mov rcx, rbp
    cmp rax, rcx
    jae .Lode_utf8_2
    mov rax, rbx
    add rax, r12
    movzx eax, byte ptr [rax]
    mov r14, rax
    mov rax, r14
    mov rcx, 128
    cmp rax, rcx
    jae .Lode_utf8_4
    mov rax, r12
    add rax, 1
    mov r12, rax
    mov rax, r13
    add rax, 1
    mov r13, rax
    jmp .Lode_utf8_5
.Lode_utf8_4:
    mov rax, r14
    mov rcx, 192
    cmp rax, rcx
    jae .Lode_utf8_6
    mov rax, 2
    mov qword ptr [rsp + 16], rax
    jmp .Lode_utf8_7
.Lode_utf8_6:
    mov rax, r14
    mov rcx, 248
    cmp rax, rcx
    jae .Lode_utf8_8
    mov rax, 2
    mov qword ptr [rsp + 8], rax
    mov rax, r14
    mov rcx, 224
    cmp rax, rcx
    jae .Lode_utf8_10
    jmp .Lode_utf8_11
.Lode_utf8_10:
    mov rax, 3
    mov qword ptr [rsp + 8], rax
.Lode_utf8_11:
    mov rax, r14
    mov rcx, 240
    cmp rax, rcx
    jae .Lode_utf8_12
    jmp .Lode_utf8_13
.Lode_utf8_12:
    mov rax, 4
    mov qword ptr [rsp + 8], rax
.Lode_utf8_13:
    mov rax, r12
    add rax, 1
    mov rcx, rbp
    cmp rax, rcx
    jae .Lode_utf8_14
    mov rax, rbx
    add rax, r12
    add rax, 1
    movzx eax, byte ptr [rax]
    mov r15, rax
    mov rax, r15
    mov rcx, 128
    cmp rax, rcx
    jae .Lode_utf8_16
    mov rax, 2
    mov qword ptr [rsp + 16], rax
    jmp .Lode_utf8_17
.Lode_utf8_16:
    mov rax, r15
    mov rcx, 192
    cmp rax, rcx
    jae .Lode_utf8_18
    jmp .Lode_utf8_19
.Lode_utf8_18:
    mov rax, 2
    mov qword ptr [rsp + 16], rax
.Lode_utf8_19:
.Lode_utf8_17:
    jmp .Lode_utf8_15
.Lode_utf8_14:
    mov rax, 2
    mov qword ptr [rsp + 16], rax
.Lode_utf8_15:
    mov rax, qword ptr [rsp + 16]
    mov rcx, 0
    cmp rax, rcx
    jne .Lode_utf8_20
    mov rax, qword ptr [rsp + 8]
    mov rcx, 3
    cmp rax, rcx
    jae .Lode_utf8_22
    jmp .Lode_utf8_23
.Lode_utf8_22:
    mov rax, r12
    add rax, 2
    mov rcx, rbp
    cmp rax, rcx
    jae .Lode_utf8_24
    mov rax, rbx
    add rax, r12
    add rax, 2
    movzx eax, byte ptr [rax]
    mov qword ptr [rsp + 0], rax
    mov rax, qword ptr [rsp + 0]
    mov rcx, 128
    cmp rax, rcx
    jae .Lode_utf8_26
    mov rax, 2
    mov qword ptr [rsp + 16], rax
    jmp .Lode_utf8_27
.Lode_utf8_26:
    mov rax, qword ptr [rsp + 0]
    mov rcx, 192
    cmp rax, rcx
    jae .Lode_utf8_28
    jmp .Lode_utf8_29
.Lode_utf8_28:
    mov rax, 2
    mov qword ptr [rsp + 16], rax
.Lode_utf8_29:
.Lode_utf8_27:
    jmp .Lode_utf8_25
.Lode_utf8_24:
    mov rax, 2
    mov qword ptr [rsp + 16], rax
.Lode_utf8_25:
.Lode_utf8_23:
.Lode_utf8_20:
    mov rax, qword ptr [rsp + 16]
    mov rcx, 0
    cmp rax, rcx
    jne .Lode_utf8_30
    mov rax, qword ptr [rsp + 8]
    mov rcx, 4
    cmp rax, rcx
    jae .Lode_utf8_32
    jmp .Lode_utf8_33
.Lode_utf8_32:
    mov rax, r12
    add rax, 3
    mov rcx, rbp
    cmp rax, rcx
    jae .Lode_utf8_34
    mov rax, rbx
    add rax, r12
    add rax, 3
    movzx eax, byte ptr [rax]
    mov qword ptr [rsp + 0], rax
    mov rax, qword ptr [rsp + 0]
    mov rcx, 128
    cmp rax, rcx
    jae .Lode_utf8_36
    mov rax, 2
    mov qword ptr [rsp + 16], rax
    jmp .Lode_utf8_37
.Lode_utf8_36:
    mov rax, qword ptr [rsp + 0]
    mov rcx, 192
    cmp rax, rcx
    jae .Lode_utf8_38
    jmp .Lode_utf8_39
.Lode_utf8_38:
    mov rax, 2
    mov qword ptr [rsp + 16], rax
.Lode_utf8_39:
.Lode_utf8_37:
    jmp .Lode_utf8_35
.Lode_utf8_34:
    mov rax, 2
    mov qword ptr [rsp + 16], rax
.Lode_utf8_35:
.Lode_utf8_33:
.Lode_utf8_30:
    mov rax, qword ptr [rsp + 16]
    mov rcx, 0
    cmp rax, rcx
    jne .Lode_utf8_40
    mov rax, qword ptr [rsp + 8]
    mov rcx, 3
    cmp rax, rcx
    jae .Lode_utf8_42
    mov rax, r14
    mov rcx, 194
    cmp rax, rcx
    jae .Lode_utf8_44
    mov rax, 2
    mov qword ptr [rsp + 16], rax
    jmp .Lode_utf8_45
.Lode_utf8_44:
    mov rax, r12
    add rax, 2
    mov r12, rax
    mov rax, r13
    add rax, 1
    mov r13, rax
.Lode_utf8_45:
    jmp .Lode_utf8_43
.Lode_utf8_42:
    mov rax, qword ptr [rsp + 8]
    mov rcx, 4
    cmp rax, rcx
    jae .Lode_utf8_46
    mov rax, r14
    mov rcx, 224
    cmp rax, rcx
    jne .Lode_utf8_48
    mov rax, r15
    mov rcx, 160
    cmp rax, rcx
    jae .Lode_utf8_50
    mov rax, 2
    mov qword ptr [rsp + 16], rax
.Lode_utf8_50:
    jmp .Lode_utf8_49
.Lode_utf8_48:
    mov rax, r14
    mov rcx, 237
    cmp rax, rcx
    jae .Lode_utf8_52
    jmp .Lode_utf8_53
.Lode_utf8_52:
    mov rax, r14
    mov rcx, 238
    cmp rax, rcx
    jae .Lode_utf8_54
    mov rax, r15
    mov rcx, 160
    cmp rax, rcx
    jae .Lode_utf8_56
    jmp .Lode_utf8_57
.Lode_utf8_56:
    mov rax, 2
    mov qword ptr [rsp + 16], rax
.Lode_utf8_57:
.Lode_utf8_54:
.Lode_utf8_53:
.Lode_utf8_49:
    mov rax, qword ptr [rsp + 16]
    mov rcx, 0
    cmp rax, rcx
    jne .Lode_utf8_58
    mov rax, r12
    add rax, 3
    mov r12, rax
    mov rax, r13
    add rax, 1
    mov r13, rax
.Lode_utf8_58:
    jmp .Lode_utf8_47
.Lode_utf8_46:
    mov rax, r14
    mov rcx, 240
    cmp rax, rcx
    jne .Lode_utf8_60
    mov rax, r15
    mov rcx, 144
    cmp rax, rcx
    jae .Lode_utf8_62
    mov rax, 2
    mov qword ptr [rsp + 16], rax
.Lode_utf8_62:
    jmp .Lode_utf8_61
.Lode_utf8_60:
    mov rax, r14
    mov rcx, 244
    cmp rax, rcx
    jae .Lode_utf8_64
    jmp .Lode_utf8_65
.Lode_utf8_64:
    mov rax, r14
    mov rcx, 245
    cmp rax, rcx
    jae .Lode_utf8_66
    mov rax, r15
    mov rcx, 144
    cmp rax, rcx
    jae .Lode_utf8_68
    jmp .Lode_utf8_69
.Lode_utf8_68:
    mov rax, 2
    mov qword ptr [rsp + 16], rax
.Lode_utf8_69:
    jmp .Lode_utf8_67
.Lode_utf8_66:
    mov rax, 2
    mov qword ptr [rsp + 16], rax
.Lode_utf8_67:
.Lode_utf8_65:
.Lode_utf8_61:
    mov rax, qword ptr [rsp + 16]
    mov rcx, 0
    cmp rax, rcx
    jne .Lode_utf8_70
    mov rax, r12
    add rax, 4
    mov r12, rax
    mov rax, r13
    add rax, 1
    mov r13, rax
.Lode_utf8_70:
.Lode_utf8_47:
.Lode_utf8_43:
.Lode_utf8_40:
    jmp .Lode_utf8_9
.Lode_utf8_8:
    mov rax, 2
    mov qword ptr [rsp + 16], rax
.Lode_utf8_9:
.Lode_utf8_7:
.Lode_utf8_5:
    jmp .Lode_utf8_3
.Lode_utf8_2:
    mov rax, 1
    mov qword ptr [rsp + 16], rax
.Lode_utf8_3:
    jmp .Lode_utf8_0
.Lode_utf8_1:
    mov rax, 18446744073709551615
    mov qword ptr [rsp + 24], rax
    mov rax, qword ptr [rsp + 16]
    mov rcx, 1
    cmp rax, rcx
    jne .Lode_utf8_72
    mov rax, r13
    mov qword ptr [rsp + 24], rax
.Lode_utf8_72:
    mov rax, qword ptr [rsp + 24]
    add rsp, 40
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    pop rbx
    ret
