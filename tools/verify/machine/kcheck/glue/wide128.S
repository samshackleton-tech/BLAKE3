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
.global b3l_wide128
.global _b3l_wide128
.p2align 4
b3l_wide128:
_b3l_wide128:
    push rbx
    push rbp
    push r12
    push r13
    push r14
    push r15
    sub rsp, 8488
    mov rbx, rdi
    mov rbp, rsi
    mov r12, rdx
    mov r13, rcx
    mov rax, r12
    add rax, 32
    mov rax, qword ptr [rax]
    mov r14, rax
    mov rax, r14
    or rax, 1073873152
    mov r15, rax
    mov rax, r14
    or rax, 1073741828
    mov qword ptr [rsp + 8448], rax
    mov rax, 0
    mov qword ptr [rsp + 8456], rax
    mov rax, 0
    mov qword ptr [rsp + 8464], rax
    mov rax, 0
    mov qword ptr [rsp + 8472], rax
    mov rax, 0
    mov qword ptr [rsp + 8480], rax
    mov rax, rbp
    add rax, 0
    mov qword ptr [rsp + 8464], rax
    lea rax, [rsp + 256]
    add rax, 0
    mov qword ptr [rsp + 8472], rax
    mov rax, r13
    add rax, 0
    mov qword ptr [rsp + 8480], rax
    mov rax, 0
    mov qword ptr [rsp + 8456], rax
.Lb3l_wide128_0:
    mov rax, qword ptr [rsp + 8456]
    mov rcx, 32
    cmp rax, rcx
    jae .Lb3l_wide128_1
    mov rax, qword ptr [rsp + 8456]
    mov rcx, 32
    cmp rax, rcx
    jae .Lb3l_wide128_2
    mov rax, qword ptr [rsp + 8464]
    mov rcx, qword ptr [rsp + 8456]
    shl rcx, 10
    add rax, rcx
    lea rcx, [rsp + 0]
    mov rdx, qword ptr [rsp + 8456]
    shl rdx, 3
    add rcx, rdx
    mov qword ptr [rcx], rax
    jmp .Lb3l_wide128_3
.Lb3l_wide128_2:
    mov rax, qword ptr [rsp + 8464]
    lea rcx, [rsp + 0]
    mov rdx, qword ptr [rsp + 8456]
    shl rdx, 3
    add rcx, rdx
    mov qword ptr [rcx], rax
.Lb3l_wide128_3:
    mov rax, qword ptr [rsp + 8456]
    add rax, 1
    mov qword ptr [rsp + 8456], rax
    jmp .Lb3l_wide128_0
.Lb3l_wide128_1:
    lea rdi, [rsp + 0]
    mov rsi, 16
    mov rdx, r12
    mov rcx, qword ptr [rsp + 8480]
    mov r8, r15
    mov r9, qword ptr [rsp + 8472]
    call CALL(blake3_servil_avx512_k32)
    mov rax, rbp
    add rax, 32768
    mov qword ptr [rsp + 8464], rax
    lea rax, [rsp + 256]
    add rax, 1024
    mov qword ptr [rsp + 8472], rax
    mov rax, r13
    add rax, 32
    mov qword ptr [rsp + 8480], rax
    mov rax, 0
    mov qword ptr [rsp + 8456], rax
.Lb3l_wide128_4:
    mov rax, qword ptr [rsp + 8456]
    mov rcx, 32
    cmp rax, rcx
    jae .Lb3l_wide128_5
    mov rax, qword ptr [rsp + 8456]
    mov rcx, 32
    cmp rax, rcx
    jae .Lb3l_wide128_6
    mov rax, qword ptr [rsp + 8464]
    mov rcx, qword ptr [rsp + 8456]
    shl rcx, 10
    add rax, rcx
    lea rcx, [rsp + 0]
    mov rdx, qword ptr [rsp + 8456]
    shl rdx, 3
    add rcx, rdx
    mov qword ptr [rcx], rax
    jmp .Lb3l_wide128_7
.Lb3l_wide128_6:
    mov rax, qword ptr [rsp + 8464]
    lea rcx, [rsp + 0]
    mov rdx, qword ptr [rsp + 8456]
    shl rdx, 3
    add rcx, rdx
    mov qword ptr [rcx], rax
.Lb3l_wide128_7:
    mov rax, qword ptr [rsp + 8456]
    add rax, 1
    mov qword ptr [rsp + 8456], rax
    jmp .Lb3l_wide128_4
.Lb3l_wide128_5:
    lea rdi, [rsp + 0]
    mov rsi, 16
    mov rdx, r12
    mov rcx, qword ptr [rsp + 8480]
    mov r8, r15
    mov r9, qword ptr [rsp + 8472]
    call CALL(blake3_servil_avx512_k32)
    mov rax, rbp
    add rax, 65536
    mov qword ptr [rsp + 8464], rax
    lea rax, [rsp + 256]
    add rax, 2048
    mov qword ptr [rsp + 8472], rax
    mov rax, r13
    add rax, 64
    mov qword ptr [rsp + 8480], rax
    mov rax, 0
    mov qword ptr [rsp + 8456], rax
.Lb3l_wide128_8:
    mov rax, qword ptr [rsp + 8456]
    mov rcx, 32
    cmp rax, rcx
    jae .Lb3l_wide128_9
    mov rax, qword ptr [rsp + 8456]
    mov rcx, 32
    cmp rax, rcx
    jae .Lb3l_wide128_10
    mov rax, qword ptr [rsp + 8464]
    mov rcx, qword ptr [rsp + 8456]
    shl rcx, 10
    add rax, rcx
    lea rcx, [rsp + 0]
    mov rdx, qword ptr [rsp + 8456]
    shl rdx, 3
    add rcx, rdx
    mov qword ptr [rcx], rax
    jmp .Lb3l_wide128_11
.Lb3l_wide128_10:
    mov rax, qword ptr [rsp + 8464]
    lea rcx, [rsp + 0]
    mov rdx, qword ptr [rsp + 8456]
    shl rdx, 3
    add rcx, rdx
    mov qword ptr [rcx], rax
.Lb3l_wide128_11:
    mov rax, qword ptr [rsp + 8456]
    add rax, 1
    mov qword ptr [rsp + 8456], rax
    jmp .Lb3l_wide128_8
.Lb3l_wide128_9:
    lea rdi, [rsp + 0]
    mov rsi, 16
    mov rdx, r12
    mov rcx, qword ptr [rsp + 8480]
    mov r8, r15
    mov r9, qword ptr [rsp + 8472]
    call CALL(blake3_servil_avx512_k32)
    mov rax, rbp
    add rax, 98304
    mov qword ptr [rsp + 8464], rax
    lea rax, [rsp + 256]
    add rax, 3072
    mov qword ptr [rsp + 8472], rax
    mov rax, r13
    add rax, 96
    mov qword ptr [rsp + 8480], rax
    mov rax, 0
    mov qword ptr [rsp + 8456], rax
.Lb3l_wide128_12:
    mov rax, qword ptr [rsp + 8456]
    mov rcx, 32
    cmp rax, rcx
    jae .Lb3l_wide128_13
    mov rax, qword ptr [rsp + 8456]
    mov rcx, 32
    cmp rax, rcx
    jae .Lb3l_wide128_14
    mov rax, qword ptr [rsp + 8464]
    mov rcx, qword ptr [rsp + 8456]
    shl rcx, 10
    add rax, rcx
    lea rcx, [rsp + 0]
    mov rdx, qword ptr [rsp + 8456]
    shl rdx, 3
    add rcx, rdx
    mov qword ptr [rcx], rax
    jmp .Lb3l_wide128_15
.Lb3l_wide128_14:
    mov rax, qword ptr [rsp + 8464]
    lea rcx, [rsp + 0]
    mov rdx, qword ptr [rsp + 8456]
    shl rdx, 3
    add rcx, rdx
    mov qword ptr [rcx], rax
.Lb3l_wide128_15:
    mov rax, qword ptr [rsp + 8456]
    add rax, 1
    mov qword ptr [rsp + 8456], rax
    jmp .Lb3l_wide128_12
.Lb3l_wide128_13:
    lea rdi, [rsp + 0]
    mov rsi, 16
    mov rdx, r12
    mov rcx, qword ptr [rsp + 8480]
    mov r8, r15
    mov r9, qword ptr [rsp + 8472]
    call CALL(blake3_servil_avx512_k32)
    lea rax, [rsp + 256]
    add rax, 0
    mov qword ptr [rsp + 8464], rax
    lea rax, [rsp + 4352]
    add rax, 0
    mov qword ptr [rsp + 8472], rax
    mov rax, 0
    mov qword ptr [rsp + 8456], rax
.Lb3l_wide128_16:
    mov rax, qword ptr [rsp + 8456]
    mov rcx, 16
    cmp rax, rcx
    jae .Lb3l_wide128_17
    mov rax, qword ptr [rsp + 8456]
    mov rcx, 16
    cmp rax, rcx
    jae .Lb3l_wide128_18
    mov rax, qword ptr [rsp + 8464]
    mov rcx, qword ptr [rsp + 8456]
    shl rcx, 6
    add rax, rcx
    lea rcx, [rsp + 0]
    mov rdx, qword ptr [rsp + 8456]
    shl rdx, 3
    add rcx, rdx
    mov qword ptr [rcx], rax
    jmp .Lb3l_wide128_19
.Lb3l_wide128_18:
    mov rax, qword ptr [rsp + 8464]
    lea rcx, [rsp + 0]
    mov rdx, qword ptr [rsp + 8456]
    shl rdx, 3
    add rcx, rdx
    mov qword ptr [rcx], rax
.Lb3l_wide128_19:
    mov rax, qword ptr [rsp + 8456]
    add rax, 1
    mov qword ptr [rsp + 8456], rax
    jmp .Lb3l_wide128_16
.Lb3l_wide128_17:
    lea rdi, [rsp + 0]
    mov rsi, 1
    mov rdx, r12
    mov rcx, 0
    mov r8, qword ptr [rsp + 8448]
    mov r9, qword ptr [rsp + 8472]
    call CALL(blake3_servil_avx512_p16)
    lea rax, [rsp + 256]
    add rax, 1024
    mov qword ptr [rsp + 8464], rax
    lea rax, [rsp + 4352]
    add rax, 512
    mov qword ptr [rsp + 8472], rax
    mov rax, 0
    mov qword ptr [rsp + 8456], rax
.Lb3l_wide128_20:
    mov rax, qword ptr [rsp + 8456]
    mov rcx, 16
    cmp rax, rcx
    jae .Lb3l_wide128_21
    mov rax, qword ptr [rsp + 8456]
    mov rcx, 16
    cmp rax, rcx
    jae .Lb3l_wide128_22
    mov rax, qword ptr [rsp + 8464]
    mov rcx, qword ptr [rsp + 8456]
    shl rcx, 6
    add rax, rcx
    lea rcx, [rsp + 0]
    mov rdx, qword ptr [rsp + 8456]
    shl rdx, 3
    add rcx, rdx
    mov qword ptr [rcx], rax
    jmp .Lb3l_wide128_23
.Lb3l_wide128_22:
    mov rax, qword ptr [rsp + 8464]
    lea rcx, [rsp + 0]
    mov rdx, qword ptr [rsp + 8456]
    shl rdx, 3
    add rcx, rdx
    mov qword ptr [rcx], rax
.Lb3l_wide128_23:
    mov rax, qword ptr [rsp + 8456]
    add rax, 1
    mov qword ptr [rsp + 8456], rax
    jmp .Lb3l_wide128_20
.Lb3l_wide128_21:
    lea rdi, [rsp + 0]
    mov rsi, 1
    mov rdx, r12
    mov rcx, 0
    mov r8, qword ptr [rsp + 8448]
    mov r9, qword ptr [rsp + 8472]
    call CALL(blake3_servil_avx512_p16)
    lea rax, [rsp + 256]
    add rax, 2048
    mov qword ptr [rsp + 8464], rax
    lea rax, [rsp + 4352]
    add rax, 1024
    mov qword ptr [rsp + 8472], rax
    mov rax, 0
    mov qword ptr [rsp + 8456], rax
.Lb3l_wide128_24:
    mov rax, qword ptr [rsp + 8456]
    mov rcx, 16
    cmp rax, rcx
    jae .Lb3l_wide128_25
    mov rax, qword ptr [rsp + 8456]
    mov rcx, 16
    cmp rax, rcx
    jae .Lb3l_wide128_26
    mov rax, qword ptr [rsp + 8464]
    mov rcx, qword ptr [rsp + 8456]
    shl rcx, 6
    add rax, rcx
    lea rcx, [rsp + 0]
    mov rdx, qword ptr [rsp + 8456]
    shl rdx, 3
    add rcx, rdx
    mov qword ptr [rcx], rax
    jmp .Lb3l_wide128_27
.Lb3l_wide128_26:
    mov rax, qword ptr [rsp + 8464]
    lea rcx, [rsp + 0]
    mov rdx, qword ptr [rsp + 8456]
    shl rdx, 3
    add rcx, rdx
    mov qword ptr [rcx], rax
.Lb3l_wide128_27:
    mov rax, qword ptr [rsp + 8456]
    add rax, 1
    mov qword ptr [rsp + 8456], rax
    jmp .Lb3l_wide128_24
.Lb3l_wide128_25:
    lea rdi, [rsp + 0]
    mov rsi, 1
    mov rdx, r12
    mov rcx, 0
    mov r8, qword ptr [rsp + 8448]
    mov r9, qword ptr [rsp + 8472]
    call CALL(blake3_servil_avx512_p16)
    lea rax, [rsp + 256]
    add rax, 3072
    mov qword ptr [rsp + 8464], rax
    lea rax, [rsp + 4352]
    add rax, 1536
    mov qword ptr [rsp + 8472], rax
    mov rax, 0
    mov qword ptr [rsp + 8456], rax
.Lb3l_wide128_28:
    mov rax, qword ptr [rsp + 8456]
    mov rcx, 16
    cmp rax, rcx
    jae .Lb3l_wide128_29
    mov rax, qword ptr [rsp + 8456]
    mov rcx, 16
    cmp rax, rcx
    jae .Lb3l_wide128_30
    mov rax, qword ptr [rsp + 8464]
    mov rcx, qword ptr [rsp + 8456]
    shl rcx, 6
    add rax, rcx
    lea rcx, [rsp + 0]
    mov rdx, qword ptr [rsp + 8456]
    shl rdx, 3
    add rcx, rdx
    mov qword ptr [rcx], rax
    jmp .Lb3l_wide128_31
.Lb3l_wide128_30:
    mov rax, qword ptr [rsp + 8464]
    lea rcx, [rsp + 0]
    mov rdx, qword ptr [rsp + 8456]
    shl rdx, 3
    add rcx, rdx
    mov qword ptr [rcx], rax
.Lb3l_wide128_31:
    mov rax, qword ptr [rsp + 8456]
    add rax, 1
    mov qword ptr [rsp + 8456], rax
    jmp .Lb3l_wide128_28
.Lb3l_wide128_29:
    lea rdi, [rsp + 0]
    mov rsi, 1
    mov rdx, r12
    mov rcx, 0
    mov r8, qword ptr [rsp + 8448]
    mov r9, qword ptr [rsp + 8472]
    call CALL(blake3_servil_avx512_p16)
    lea rax, [rsp + 4352]
    add rax, 0
    mov qword ptr [rsp + 8464], rax
    lea rax, [rsp + 6400]
    add rax, 0
    mov qword ptr [rsp + 8472], rax
    mov rax, 0
    mov qword ptr [rsp + 8456], rax
.Lb3l_wide128_32:
    mov rax, qword ptr [rsp + 8456]
    mov rcx, 16
    cmp rax, rcx
    jae .Lb3l_wide128_33
    mov rax, qword ptr [rsp + 8456]
    mov rcx, 16
    cmp rax, rcx
    jae .Lb3l_wide128_34
    mov rax, qword ptr [rsp + 8464]
    mov rcx, qword ptr [rsp + 8456]
    shl rcx, 6
    add rax, rcx
    lea rcx, [rsp + 0]
    mov rdx, qword ptr [rsp + 8456]
    shl rdx, 3
    add rcx, rdx
    mov qword ptr [rcx], rax
    jmp .Lb3l_wide128_35
.Lb3l_wide128_34:
    mov rax, qword ptr [rsp + 8464]
    lea rcx, [rsp + 0]
    mov rdx, qword ptr [rsp + 8456]
    shl rdx, 3
    add rcx, rdx
    mov qword ptr [rcx], rax
.Lb3l_wide128_35:
    mov rax, qword ptr [rsp + 8456]
    add rax, 1
    mov qword ptr [rsp + 8456], rax
    jmp .Lb3l_wide128_32
.Lb3l_wide128_33:
    lea rdi, [rsp + 0]
    mov rsi, 1
    mov rdx, r12
    mov rcx, 0
    mov r8, qword ptr [rsp + 8448]
    mov r9, qword ptr [rsp + 8472]
    call CALL(blake3_servil_avx512_p16)
    lea rax, [rsp + 4352]
    add rax, 1024
    mov qword ptr [rsp + 8464], rax
    lea rax, [rsp + 6400]
    add rax, 512
    mov qword ptr [rsp + 8472], rax
    mov rax, 0
    mov qword ptr [rsp + 8456], rax
.Lb3l_wide128_36:
    mov rax, qword ptr [rsp + 8456]
    mov rcx, 16
    cmp rax, rcx
    jae .Lb3l_wide128_37
    mov rax, qword ptr [rsp + 8456]
    mov rcx, 16
    cmp rax, rcx
    jae .Lb3l_wide128_38
    mov rax, qword ptr [rsp + 8464]
    mov rcx, qword ptr [rsp + 8456]
    shl rcx, 6
    add rax, rcx
    lea rcx, [rsp + 0]
    mov rdx, qword ptr [rsp + 8456]
    shl rdx, 3
    add rcx, rdx
    mov qword ptr [rcx], rax
    jmp .Lb3l_wide128_39
.Lb3l_wide128_38:
    mov rax, qword ptr [rsp + 8464]
    lea rcx, [rsp + 0]
    mov rdx, qword ptr [rsp + 8456]
    shl rdx, 3
    add rcx, rdx
    mov qword ptr [rcx], rax
.Lb3l_wide128_39:
    mov rax, qword ptr [rsp + 8456]
    add rax, 1
    mov qword ptr [rsp + 8456], rax
    jmp .Lb3l_wide128_36
.Lb3l_wide128_37:
    lea rdi, [rsp + 0]
    mov rsi, 1
    mov rdx, r12
    mov rcx, 0
    mov r8, qword ptr [rsp + 8448]
    mov r9, qword ptr [rsp + 8472]
    call CALL(blake3_servil_avx512_p16)
    mov rax, 0
    mov qword ptr [rsp + 8456], rax
.Lb3l_wide128_40:
    mov rax, qword ptr [rsp + 8456]
    mov rcx, 16
    cmp rax, rcx
    jae .Lb3l_wide128_41
    mov rax, qword ptr [rsp + 8456]
    mov rcx, 16
    cmp rax, rcx
    jae .Lb3l_wide128_42
    lea rax, [rsp + 6400]
    mov rcx, qword ptr [rsp + 8456]
    shl rcx, 6
    add rax, rcx
    lea rcx, [rsp + 0]
    mov rdx, qword ptr [rsp + 8456]
    shl rdx, 3
    add rcx, rdx
    mov qword ptr [rcx], rax
    jmp .Lb3l_wide128_43
.Lb3l_wide128_42:
    lea rax, [rsp + 6400]
    lea rcx, [rsp + 0]
    mov rdx, qword ptr [rsp + 8456]
    shl rdx, 3
    add rcx, rdx
    mov qword ptr [rcx], rax
.Lb3l_wide128_43:
    mov rax, qword ptr [rsp + 8456]
    add rax, 1
    mov qword ptr [rsp + 8456], rax
    jmp .Lb3l_wide128_40
.Lb3l_wide128_41:
    lea rdi, [rsp + 0]
    mov rsi, 1
    mov rdx, r12
    mov rcx, 0
    mov r8, qword ptr [rsp + 8448]
    lea r9, [rsp + 7424]
    call CALL(blake3_servil_avx512_p16)
    mov rax, 0
    mov qword ptr [rsp + 8456], rax
.Lb3l_wide128_44:
    mov rax, qword ptr [rsp + 8456]
    mov rcx, 16
    cmp rax, rcx
    jae .Lb3l_wide128_45
    mov rax, qword ptr [rsp + 8456]
    mov rcx, 8
    cmp rax, rcx
    jae .Lb3l_wide128_46
    lea rax, [rsp + 7424]
    mov rcx, qword ptr [rsp + 8456]
    shl rcx, 6
    add rax, rcx
    lea rcx, [rsp + 0]
    mov rdx, qword ptr [rsp + 8456]
    shl rdx, 3
    add rcx, rdx
    mov qword ptr [rcx], rax
    jmp .Lb3l_wide128_47
.Lb3l_wide128_46:
    lea rax, [rsp + 7424]
    lea rcx, [rsp + 0]
    mov rdx, qword ptr [rsp + 8456]
    shl rdx, 3
    add rcx, rdx
    mov qword ptr [rcx], rax
.Lb3l_wide128_47:
    mov rax, qword ptr [rsp + 8456]
    add rax, 1
    mov qword ptr [rsp + 8456], rax
    jmp .Lb3l_wide128_44
.Lb3l_wide128_45:
    lea rdi, [rsp + 0]
    mov rsi, 1
    mov rdx, r12
    mov rcx, 0
    mov r8, qword ptr [rsp + 8448]
    lea r9, [rsp + 7936]
    call CALL(blake3_servil_avx512_p16)
    mov rax, 0
    mov qword ptr [rsp + 8456], rax
.Lb3l_wide128_48:
    mov rax, qword ptr [rsp + 8456]
    mov rcx, 16
    cmp rax, rcx
    jae .Lb3l_wide128_49
    mov rax, qword ptr [rsp + 8456]
    mov rcx, 4
    cmp rax, rcx
    jae .Lb3l_wide128_50
    lea rax, [rsp + 7936]
    mov rcx, qword ptr [rsp + 8456]
    shl rcx, 6
    add rax, rcx
    lea rcx, [rsp + 0]
    mov rdx, qword ptr [rsp + 8456]
    shl rdx, 3
    add rcx, rdx
    mov qword ptr [rcx], rax
    jmp .Lb3l_wide128_51
.Lb3l_wide128_50:
    lea rax, [rsp + 7936]
    lea rcx, [rsp + 0]
    mov rdx, qword ptr [rsp + 8456]
    shl rdx, 3
    add rcx, rdx
    mov qword ptr [rcx], rax
.Lb3l_wide128_51:
    mov rax, qword ptr [rsp + 8456]
    add rax, 1
    mov qword ptr [rsp + 8456], rax
    jmp .Lb3l_wide128_48
.Lb3l_wide128_49:
    lea rdi, [rsp + 0]
    mov rsi, 1
    mov rdx, r12
    mov rcx, 0
    mov r8, qword ptr [rsp + 8448]
    lea r9, [rsp + 7424]
    call CALL(blake3_servil_avx512_p16)
    mov rax, 0
    mov qword ptr [rsp + 8456], rax
.Lb3l_wide128_52:
    mov rax, qword ptr [rsp + 8456]
    mov rcx, 16
    cmp rax, rcx
    jae .Lb3l_wide128_53
    mov rax, qword ptr [rsp + 8456]
    mov rcx, 2
    cmp rax, rcx
    jae .Lb3l_wide128_54
    lea rax, [rsp + 7424]
    mov rcx, qword ptr [rsp + 8456]
    shl rcx, 6
    add rax, rcx
    lea rcx, [rsp + 0]
    mov rdx, qword ptr [rsp + 8456]
    shl rdx, 3
    add rcx, rdx
    mov qword ptr [rcx], rax
    jmp .Lb3l_wide128_55
.Lb3l_wide128_54:
    lea rax, [rsp + 7424]
    lea rcx, [rsp + 0]
    mov rdx, qword ptr [rsp + 8456]
    shl rdx, 3
    add rcx, rdx
    mov qword ptr [rcx], rax
.Lb3l_wide128_55:
    mov rax, qword ptr [rsp + 8456]
    add rax, 1
    mov qword ptr [rsp + 8456], rax
    jmp .Lb3l_wide128_52
.Lb3l_wide128_53:
    lea rdi, [rsp + 0]
    mov rsi, 1
    mov rdx, r12
    mov rcx, 0
    mov r8, qword ptr [rsp + 8448]
    lea r9, [rsp + 7936]
    call CALL(blake3_servil_avx512_p16)
    mov rax, 0
    mov qword ptr [rsp + 8456], rax
.Lb3l_wide128_56:
    mov rax, qword ptr [rsp + 8456]
    mov rcx, 16
    cmp rax, rcx
    jae .Lb3l_wide128_57
    mov rax, qword ptr [rsp + 8456]
    mov rcx, 1
    cmp rax, rcx
    jae .Lb3l_wide128_58
    lea rax, [rsp + 7936]
    mov rcx, qword ptr [rsp + 8456]
    shl rcx, 6
    add rax, rcx
    lea rcx, [rsp + 0]
    mov rdx, qword ptr [rsp + 8456]
    shl rdx, 3
    add rcx, rdx
    mov qword ptr [rcx], rax
    jmp .Lb3l_wide128_59
.Lb3l_wide128_58:
    lea rax, [rsp + 7936]
    lea rcx, [rsp + 0]
    mov rdx, qword ptr [rsp + 8456]
    shl rdx, 3
    add rcx, rdx
    mov qword ptr [rcx], rax
.Lb3l_wide128_59:
    mov rax, qword ptr [rsp + 8456]
    add rax, 1
    mov qword ptr [rsp + 8456], rax
    jmp .Lb3l_wide128_56
.Lb3l_wide128_57:
    lea rdi, [rsp + 0]
    mov rsi, 1
    mov rdx, r12
    mov rcx, 0
    mov r8, qword ptr [rsp + 8448]
    lea r9, [rsp + 7424]
    call CALL(blake3_servil_avx512_p16)
    lea rax, [rsp + 7424]
    mov rcx, rbx
    movups xmm0, xmmword ptr [rax + 0]
    movups xmmword ptr [rcx + 0], xmm0
    movups xmm0, xmmword ptr [rax + 16]
    movups xmmword ptr [rcx + 16], xmm0
    add rsp, 8488
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    pop rbx
    ret
