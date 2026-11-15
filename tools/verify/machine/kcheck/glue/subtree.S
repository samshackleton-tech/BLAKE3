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
.global b3l_subtree
.global _b3l_subtree
.p2align 4
b3l_subtree:
_b3l_subtree:
    push rbx
    push rbp
    push r12
    push r13
    push r14
    push r15
    sub rsp, 280
    mov rbx, rdi
    mov rbp, rsi
    mov r12, rdx
    mov r13, rcx
    mov r14, r8
    mov r15, r9
    mov rax, r13
    add rax, 32
    mov rax, qword ptr [rax]
    mov qword ptr [rsp + 192], rax
    mov rax, 0
    mov qword ptr [rsp + 200], rax
    mov rax, 0
    mov qword ptr [rsp + 208], rax
    mov rax, 0
    mov qword ptr [rsp + 216], rax
    mov rax, 0
    mov qword ptr [rsp + 224], rax
    mov rax, r15
    mov rcx, 5
    cmp rax, rcx
    jne .Lb3l_subtree_0
    mov rax, r12
    mov rcx, 131072
    cmp rax, rcx
    jne .Lb3l_subtree_2
    mov rax, 3
    mov qword ptr [rsp + 224], rax
    jmp .Lb3l_subtree_3
.Lb3l_subtree_2:
    mov rax, r12
    mov rcx, 32768
    cmp rax, rcx
    jne .Lb3l_subtree_4
    mov rax, 1
    mov qword ptr [rsp + 224], rax
    jmp .Lb3l_subtree_5
.Lb3l_subtree_4:
    mov rax, 1024
    mov rcx, r12
    cmp rax, rcx
    jae .Lb3l_subtree_6
    mov rax, r12
    mov rcx, 32768
    cmp rax, rcx
    jae .Lb3l_subtree_8
    mov rax, 2
    mov qword ptr [rsp + 224], rax
.Lb3l_subtree_8:
.Lb3l_subtree_6:
.Lb3l_subtree_5:
.Lb3l_subtree_3:
.Lb3l_subtree_0:
    mov rax, qword ptr [rsp + 224]
    mov rcx, 3
    cmp rax, rcx
    jne .Lb3l_subtree_10
    mov rdi, rbx
    mov rsi, rbp
    mov rdx, r13
    mov rcx, r14
    call CALL(b3l_wide128)
    jmp .Lb3l_subtree_11
.Lb3l_subtree_10:
    mov rax, qword ptr [rsp + 224]
    mov rcx, 1
    cmp rax, rcx
    jne .Lb3l_subtree_12
    mov rdi, rbx
    mov rsi, rbp
    mov rdx, r13
    mov rcx, r14
    call CALL(b3l_wide32)
    jmp .Lb3l_subtree_13
.Lb3l_subtree_12:
    mov rax, qword ptr [rsp + 224]
    mov rcx, 2
    cmp rax, rcx
    jne .Lb3l_subtree_14
    mov rdi, rbx
    mov rsi, rbp
    mov rdx, r12
    mov rcx, r13
    mov r8, r14
    call CALL(b3l_part32)
    jmp .Lb3l_subtree_15
.Lb3l_subtree_14:
    mov rax, 1024
    mov rcx, r12
    cmp rax, rcx
    jae .Lb3l_subtree_16
    mov rax, r12
    sub rax, 1
    shr rax, 10
    add rax, 1
    mov qword ptr [rsp + 200], rax
    mov rax, 1
    mov qword ptr [rsp + 208], rax
    mov rax, 2
    mov qword ptr [rsp + 216], rax
.Lb3l_subtree_18:
    mov rax, qword ptr [rsp + 216]
    mov rcx, qword ptr [rsp + 200]
    cmp rax, rcx
    jae .Lb3l_subtree_19
    mov rax, qword ptr [rsp + 216]
    mov qword ptr [rsp + 208], rax
    mov rax, qword ptr [rsp + 216]
    shl rax, 1
    mov qword ptr [rsp + 216], rax
    jmp .Lb3l_subtree_18
.Lb3l_subtree_19:
    mov rax, qword ptr [rsp + 208]
    shl rax, 10
    mov qword ptr [rsp + 232], rax
    lea rax, [rsp + 128]
    add rax, 32
    mov qword ptr [rsp + 240], rax
    mov rax, rbp
    add rax, qword ptr [rsp + 232]
    mov qword ptr [rsp + 248], rax
    mov rax, r12
    sub rax, qword ptr [rsp + 232]
    mov qword ptr [rsp + 256], rax
    mov rax, r14
    add rax, qword ptr [rsp + 208]
    mov qword ptr [rsp + 264], rax
    mov rax, qword ptr [rsp + 192]
    or rax, 4
    mov qword ptr [rsp + 272], rax
    lea rdi, [rsp + 128]
    mov rsi, rbp
    mov rdx, qword ptr [rsp + 232]
    mov rcx, r13
    mov r8, r14
    mov r9, r15
    call CALL(b3l_subtree)
    mov rdi, qword ptr [rsp + 240]
    mov rsi, qword ptr [rsp + 248]
    mov rdx, qword ptr [rsp + 256]
    mov rcx, r13
    mov r8, qword ptr [rsp + 264]
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
    jne .Lb3l_subtree_20
    mov rdi, rbx
    lea rsi, [rsp + 128]
    mov rdx, 64
    mov rcx, 0
    mov r8, qword ptr [rsp + 272]
    call CALL(blake3_servil_compress_in_place_avx512)
    jmp .Lb3l_subtree_21
.Lb3l_subtree_20:
    mov rdi, rbx
    lea rsi, [rsp + 128]
    mov rdx, 64
    mov rcx, 0
    mov r8, qword ptr [rsp + 272]
    call CALL(blake3_servil_compress_in_place_sse41)
.Lb3l_subtree_21:
    jmp .Lb3l_subtree_17
.Lb3l_subtree_16:
    mov rax, r13
    lea rcx, [rsp + 0]
    movups xmm0, xmmword ptr [rax + 0]
    movups xmmword ptr [rcx + 0], xmm0
    movups xmm0, xmmword ptr [rax + 16]
    movups xmmword ptr [rcx + 16], xmm0
    lea rdi, [rsp + 0]
    mov rsi, rbp
    mov rdx, r12
    mov rcx, r14
    mov r8, qword ptr [rsp + 192]
    mov r9, r15
    call CALL(b3l_chunk_node)
    mov rdi, rbx
    lea rsi, [rsp + 0]
    mov rdx, 0
    mov rcx, r15
    call CALL(b3l_node_out)
.Lb3l_subtree_17:
.Lb3l_subtree_15:
.Lb3l_subtree_13:
.Lb3l_subtree_11:
    add rsp, 280
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    pop rbx
    ret
