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
    sub rsp, 312
    mov rbx, rdi
    mov rbp, rsi
    mov r12, rdx
    mov r13, rcx
    mov r14, r8
    mov r15, r9
    mov rax, 0
    mov qword ptr [rsp + 240], rax
    mov rax, 0
    mov qword ptr [rsp + 248], rax
    mov rax, 0
    mov qword ptr [rsp + 256], rax
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
    mov rax, 1024
    mov rcx, r12
    cmp rax, rcx
    jae .Lb3l_hashr_0
    mov rax, r12
    sub rax, 1
    shr rax, 10
    add rax, 1
    mov qword ptr [rsp + 240], rax
    mov rax, 1
    mov qword ptr [rsp + 248], rax
    mov rax, 2
    mov qword ptr [rsp + 256], rax
.Lb3l_hashr_2:
    mov rax, qword ptr [rsp + 256]
    mov rcx, qword ptr [rsp + 240]
    cmp rax, rcx
    jae .Lb3l_hashr_3
    mov rax, qword ptr [rsp + 256]
    mov qword ptr [rsp + 248], rax
    mov rax, qword ptr [rsp + 256]
    shl rax, 1
    mov qword ptr [rsp + 256], rax
    jmp .Lb3l_hashr_2
.Lb3l_hashr_3:
    mov rax, qword ptr [rsp + 248]
    shl rax, 10
    mov qword ptr [rsp + 264], rax
    lea rax, [rsp + 176]
    add rax, 32
    mov qword ptr [rsp + 272], rax
    mov rax, rbp
    add rax, qword ptr [rsp + 264]
    mov qword ptr [rsp + 280], rax
    mov rax, r12
    sub rax, qword ptr [rsp + 264]
    mov qword ptr [rsp + 288], rax
    mov rax, r14
    or rax, 4
    or rax, 8
    mov qword ptr [rsp + 296], rax
    lea rdi, [rsp + 176]
    mov rsi, rbp
    mov rdx, qword ptr [rsp + 264]
    lea rcx, [rsp + 0]
    mov r8, 0
    mov r9, r15
    call CALL(b3l_subtree)
    mov rdi, qword ptr [rsp + 272]
    mov rsi, qword ptr [rsp + 280]
    mov rdx, qword ptr [rsp + 288]
    lea rcx, [rsp + 0]
    mov r8, qword ptr [rsp + 248]
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
    jne .Lb3l_hashr_4
    mov rdi, rbx
    lea rsi, [rsp + 176]
    mov rdx, 64
    mov rcx, 0
    mov r8, qword ptr [rsp + 296]
    call CALL(blake3_servil_compress_in_place_avx512)
    jmp .Lb3l_hashr_5
.Lb3l_hashr_4:
    mov rdi, rbx
    lea rsi, [rsp + 176]
    mov rdx, 64
    mov rcx, 0
    mov r8, qword ptr [rsp + 296]
    call CALL(blake3_servil_compress_in_place_sse41)
.Lb3l_hashr_5:
    jmp .Lb3l_hashr_1
.Lb3l_hashr_0:
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
.Lb3l_hashr_1:
    add rsp, 312
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    pop rbx
    ret
