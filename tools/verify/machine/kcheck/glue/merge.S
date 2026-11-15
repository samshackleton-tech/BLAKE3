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
.global b3l_merge
.global _b3l_merge
.p2align 4
b3l_merge:
_b3l_merge:
    push rbx
    push rbp
    push r12
    push r13
    push r14
    push r15
    sub rsp, 120
    mov rbx, rdi
    mov rbp, rsi
    mov r12, rdx
    mov r13, rcx
    mov r14, r8
    mov rax, rbx
    mov rax, qword ptr [rax]
    mov r15, rax
    mov rax, r12
    or rax, 4
    mov qword ptr [rsp + 96], rax
.Lb3l_merge_0:
    mov rax, r14
    mov rcx, r15
    cmp rax, rcx
    jae .Lb3l_merge_1
    mov rax, rbx
    add rax, 32
    mov rcx, r15
    sub rcx, 2
    shl rcx, 5
    add rax, rcx
    mov qword ptr [rsp + 104], rax
    mov rax, qword ptr [rsp + 104]
    lea rcx, [rsp + 0]
    movups xmm0, xmmword ptr [rax + 0]
    movups xmmword ptr [rcx + 0], xmm0
    movups xmm0, xmmword ptr [rax + 16]
    movups xmmword ptr [rcx + 16], xmm0
    mov rax, qword ptr [rsp + 104]
    add rax, 32
    lea rcx, [rsp + 0]
    add rcx, 32
    movups xmm0, xmmword ptr [rax + 0]
    movups xmmword ptr [rcx + 0], xmm0
    movups xmm0, xmmword ptr [rax + 16]
    movups xmmword ptr [rcx + 16], xmm0
    mov rax, rbp
    lea rcx, [rsp + 64]
    movups xmm0, xmmword ptr [rax + 0]
    movups xmmword ptr [rcx + 0], xmm0
    movups xmm0, xmmword ptr [rax + 16]
    movups xmmword ptr [rcx + 16], xmm0
    mov rax, r13
    mov rcx, 5
    cmp rax, rcx
    jne .Lb3l_merge_2
    lea rdi, [rsp + 64]
    lea rsi, [rsp + 0]
    mov rdx, 64
    mov rcx, 0
    mov r8, qword ptr [rsp + 96]
    call CALL(blake3_servil_compress_in_place_avx512)
    jmp .Lb3l_merge_3
.Lb3l_merge_2:
    lea rdi, [rsp + 64]
    lea rsi, [rsp + 0]
    mov rdx, 64
    mov rcx, 0
    mov r8, qword ptr [rsp + 96]
    call CALL(blake3_servil_compress_in_place_sse41)
.Lb3l_merge_3:
    lea rax, [rsp + 64]
    mov rcx, qword ptr [rsp + 104]
    movups xmm0, xmmword ptr [rax + 0]
    movups xmmword ptr [rcx + 0], xmm0
    movups xmm0, xmmword ptr [rax + 16]
    movups xmmword ptr [rcx + 16], xmm0
    mov rax, r15
    sub rax, 1
    mov r15, rax
    mov rax, r15
    mov rcx, rbx
    mov qword ptr [rcx], rax
    jmp .Lb3l_merge_0
.Lb3l_merge_1:
    mov rax, r15
    add rsp, 120
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    pop rbx
    ret
.global b3l_merge_checked
.global _b3l_merge_checked
.p2align 4
b3l_merge_checked:
_b3l_merge_checked:
    cmp r8, 1
    jae .Lb3l_merge_ok0
    jmp .Lb3l_merge_refuse
.Lb3l_merge_ok0:
    cmp rdx, 256
    jae .Lb3l_merge_refuse
    jmp b3l_merge
.Lb3l_merge_refuse:
    mov rax, -1
    ret
