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
.global b3l_hashr
.global _b3l_hashr
.p2align 4
b3l_hashr:
_b3l_hashr:
    push rbx
    push rbp
    push r12
    push r13
    push r14
    push r15
    sub rsp, 1672
    mov rbx, rdi
    mov rbp, rsi
    mov r12, rdx
    mov r13, rcx
    mov r14, r8
    mov r15, r9
    mov rax, 0
    mov qword ptr [rsp + 1520], rax
    mov rax, 0
    mov qword ptr [rsp + 1528], rax
    mov rax, 0
    mov qword ptr [rsp + 1536], rax
    mov rax, 0
    mov qword ptr [rsp + 1544], rax
    mov rax, 0
    mov qword ptr [rsp + 1552], rax
    mov rax, r13
    lea rcx, [rsp + 0]
    movups xmm0, xmmword ptr [rax + 0]
    movups xmmword ptr [rcx + 0], xmm0
    movups xmm0, xmmword ptr [rax + 16]
    movups xmmword ptr [rcx + 16], xmm0
    mov rax, r14
    lea rcx, [rsp + 0]
    add rcx, 32
    mov qword ptr [rcx], rax
    mov rax, r15
    mov rcx, 5
    cmp rax, rcx
    jne .Lb3l_hashr_0
    mov rax, 1024
    mov rcx, r12
    cmp rax, rcx
    jae .Lb3l_hashr_2
    mov rax, 32768
    mov rcx, r12
    cmp rax, rcx
    jae .Lb3l_hashr_4
    jmp .Lb3l_hashr_5
.Lb3l_hashr_4:
    mov rax, 1
    mov qword ptr [rsp + 1552], rax
.Lb3l_hashr_5:
.Lb3l_hashr_2:
.Lb3l_hashr_0:
    mov rax, qword ptr [rsp + 1552]
    mov rcx, 1
    cmp rax, rcx
    jne .Lb3l_hashr_6
    mov rax, r14
    or rax, 1073873152
    mov qword ptr [rsp + 1560], rax
    mov rax, r12
    shr rax, 10
    mov qword ptr [rsp + 1568], rax
    mov rax, 0
    mov qword ptr [rsp + 1544], rax
.Lb3l_hashr_8:
    mov rax, qword ptr [rsp + 1544]
    mov rcx, 32
    cmp rax, rcx
    jae .Lb3l_hashr_9
    mov rax, qword ptr [rsp + 1544]
    mov rcx, qword ptr [rsp + 1568]
    cmp rax, rcx
    jae .Lb3l_hashr_10
    mov rax, rbp
    mov rcx, qword ptr [rsp + 1544]
    shl rcx, 10
    add rax, rcx
    lea rcx, [rsp + 240]
    mov rdx, qword ptr [rsp + 1544]
    shl rdx, 3
    add rcx, rdx
    mov qword ptr [rcx], rax
    jmp .Lb3l_hashr_11
.Lb3l_hashr_10:
    mov rax, rbp
    lea rcx, [rsp + 240]
    mov rdx, qword ptr [rsp + 1544]
    shl rdx, 3
    add rcx, rdx
    mov qword ptr [rcx], rax
.Lb3l_hashr_11:
    mov rax, qword ptr [rsp + 1544]
    add rax, 1
    mov qword ptr [rsp + 1544], rax
    jmp .Lb3l_hashr_8
.Lb3l_hashr_9:
    lea rdi, [rsp + 240]
    mov rsi, 16
    lea rdx, [rsp + 0]
    mov rcx, 0
    mov r8, qword ptr [rsp + 1560]
    lea r9, [rsp + 496]
    call CALL(blake3_servil_avx512_k32)
    mov rax, r12
    sub rax, 1
    shr rax, 10
    add rax, 1
    mov qword ptr [rsp + 1520], rax
    mov rax, 1
    mov qword ptr [rsp + 1528], rax
    mov rax, 2
    mov qword ptr [rsp + 1536], rax
.Lb3l_hashr_12:
    mov rax, qword ptr [rsp + 1536]
    mov rcx, qword ptr [rsp + 1520]
    cmp rax, rcx
    jae .Lb3l_hashr_13
    mov rax, qword ptr [rsp + 1536]
    mov qword ptr [rsp + 1528], rax
    mov rax, qword ptr [rsp + 1536]
    shl rax, 1
    mov qword ptr [rsp + 1536], rax
    jmp .Lb3l_hashr_12
.Lb3l_hashr_13:
    mov rax, qword ptr [rsp + 1528]
    shl rax, 10
    mov qword ptr [rsp + 1576], rax
    lea rax, [rsp + 176]
    add rax, 32
    mov qword ptr [rsp + 1584], rax
    mov rax, rbp
    add rax, qword ptr [rsp + 1576]
    mov qword ptr [rsp + 1592], rax
    mov rax, r12
    sub rax, qword ptr [rsp + 1576]
    mov qword ptr [rsp + 1600], rax
    lea rax, [rsp + 496]
    mov rcx, qword ptr [rsp + 1528]
    shl rcx, 5
    add rax, rcx
    mov qword ptr [rsp + 1608], rax
    mov rax, r14
    or rax, 4
    or rax, 8
    mov qword ptr [rsp + 1616], rax
    lea rdi, [rsp + 176]
    mov rsi, rbp
    mov rdx, qword ptr [rsp + 1576]
    lea rcx, [rsp + 0]
    mov r8, 0
    lea r9, [rsp + 496]
    call CALL(b3l_take)
    mov rdi, qword ptr [rsp + 1584]
    mov rsi, qword ptr [rsp + 1592]
    mov rdx, qword ptr [rsp + 1600]
    lea rcx, [rsp + 0]
    mov r8, qword ptr [rsp + 1528]
    mov r9, qword ptr [rsp + 1608]
    call CALL(b3l_take)
    mov rax, r13
    mov rcx, rbx
    movups xmm0, xmmword ptr [rax + 0]
    movups xmmword ptr [rcx + 0], xmm0
    movups xmm0, xmmword ptr [rax + 16]
    movups xmmword ptr [rcx + 16], xmm0
    mov rdi, rbx
    lea rsi, [rsp + 176]
    mov rdx, 64
    mov rcx, 0
    mov r8, qword ptr [rsp + 1616]
    call CALL(blake3_servil_compress_in_place_avx512)
    jmp .Lb3l_hashr_7
.Lb3l_hashr_6:
    mov rax, 1024
    mov rcx, r12
    cmp rax, rcx
    jae .Lb3l_hashr_14
    mov rax, r12
    sub rax, 1
    shr rax, 10
    add rax, 1
    mov qword ptr [rsp + 1520], rax
    mov rax, 1
    mov qword ptr [rsp + 1528], rax
    mov rax, 2
    mov qword ptr [rsp + 1536], rax
.Lb3l_hashr_16:
    mov rax, qword ptr [rsp + 1536]
    mov rcx, qword ptr [rsp + 1520]
    cmp rax, rcx
    jae .Lb3l_hashr_17
    mov rax, qword ptr [rsp + 1536]
    mov qword ptr [rsp + 1528], rax
    mov rax, qword ptr [rsp + 1536]
    shl rax, 1
    mov qword ptr [rsp + 1536], rax
    jmp .Lb3l_hashr_16
.Lb3l_hashr_17:
    mov rax, qword ptr [rsp + 1528]
    shl rax, 10
    mov qword ptr [rsp + 1624], rax
    lea rax, [rsp + 176]
    add rax, 32
    mov qword ptr [rsp + 1632], rax
    mov rax, rbp
    add rax, qword ptr [rsp + 1624]
    mov qword ptr [rsp + 1640], rax
    mov rax, r12
    sub rax, qword ptr [rsp + 1624]
    mov qword ptr [rsp + 1648], rax
    mov rax, r14
    or rax, 4
    or rax, 8
    mov qword ptr [rsp + 1656], rax
    lea rdi, [rsp + 176]
    mov rsi, rbp
    mov rdx, qword ptr [rsp + 1624]
    lea rcx, [rsp + 0]
    mov r8, 0
    mov r9, r15
    call CALL(b3l_subtree)
    mov rdi, qword ptr [rsp + 1632]
    mov rsi, qword ptr [rsp + 1640]
    mov rdx, qword ptr [rsp + 1648]
    lea rcx, [rsp + 0]
    mov r8, qword ptr [rsp + 1528]
    mov r9, r15
    call CALL(b3l_subtree)
    mov rax, r13
    mov rcx, rbx
    movups xmm0, xmmword ptr [rax + 0]
    movups xmmword ptr [rcx + 0], xmm0
    movups xmm0, xmmword ptr [rax + 16]
    movups xmmword ptr [rcx + 16], xmm0
    mov rax, r15
    mov rcx, 5
    cmp rax, rcx
    jne .Lb3l_hashr_18
    mov rdi, rbx
    lea rsi, [rsp + 176]
    mov rdx, 64
    mov rcx, 0
    mov r8, qword ptr [rsp + 1656]
    call CALL(blake3_servil_compress_in_place_avx512)
    jmp .Lb3l_hashr_19
.Lb3l_hashr_18:
    mov rdi, rbx
    lea rsi, [rsp + 176]
    mov rdx, 64
    mov rcx, 0
    mov r8, qword ptr [rsp + 1656]
    call CALL(blake3_servil_compress_in_place_sse41)
.Lb3l_hashr_19:
    jmp .Lb3l_hashr_15
.Lb3l_hashr_14:
    mov rax, r13
    lea rcx, [rsp + 48]
    movups xmm0, xmmword ptr [rax + 0]
    movups xmmword ptr [rcx + 0], xmm0
    movups xmm0, xmmword ptr [rax + 16]
    movups xmmword ptr [rcx + 16], xmm0
    lea rdi, [rsp + 48]
    mov rsi, rbp
    mov rdx, r12
    mov rcx, 0
    mov r8, r14
    mov r9, r15
    call CALL(b3l_chunk_node)
    mov rdi, rbx
    lea rsi, [rsp + 48]
    mov rdx, 8
    mov rcx, r15
    call CALL(b3l_node_out)
.Lb3l_hashr_15:
.Lb3l_hashr_7:
    add rsp, 1672
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    pop rbx
    ret
