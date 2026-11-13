/* The cross-check of one/Machine.lean against this CPU: every instruction of the programs proved on it
 * and of the wide kernel run on it (its own bytes), on the random states CrossOne.lean made, compared
 * with what the Lean model says it leaves in the sixteen general registers, the thirty-two ZMM registers
 * (all 512 bits of each), ZF and CF (where the model defines them) and 1024 bytes of memory. The buffer
 * is mapped at the address the model uses. Written by mk_cross_c.py.
 *   cc -O1 -o cross_one cross_one.c && ./cross_one vectors.txt
 * Exit status 0 only if every vector agrees. Needs Linux and an x86-64 CPU with AVX-512 F and VL. */
#define _GNU_SOURCE
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>

/* The registers before, then after: mapped at SAVED (the assembly below names these addresses). */
struct regs {
    uint64_t gpr[16];     /* rax rcx rdx rbx rsp rbp rsi rdi r8 r9 r12 r13 r14 r15 r10 r11 */
    uint64_t flags;       /* in, then out */
    uint64_t code;        /* where the instruction is */
    uint64_t realsp;      /* this program's own stack pointer, while the instruction runs */
    uint64_t pad[5];
    uint64_t zmm[32][8];  /* lowest quadword first */
};
#define SAVED 0x30000000ull

void run_one(void);
/* No register is the harness's own: every one is loaded before the instruction and stored after it. */
__asm__(
    ".globl run_one\n.globl run_back\n"
    "run_one:\n"
    "  push %rbx\n  push %rbp\n  push %r12\n  push %r13\n  push %r14\n  push %r15\n"
    "  vmovdqu64 0x300000c0, %zmm0\n"
    "  vmovdqu64 0x30000100, %zmm1\n"
    "  vmovdqu64 0x30000140, %zmm2\n"
    "  vmovdqu64 0x30000180, %zmm3\n"
    "  vmovdqu64 0x300001c0, %zmm4\n"
    "  vmovdqu64 0x30000200, %zmm5\n"
    "  vmovdqu64 0x30000240, %zmm6\n"
    "  vmovdqu64 0x30000280, %zmm7\n"
    "  vmovdqu64 0x300002c0, %zmm8\n"
    "  vmovdqu64 0x30000300, %zmm9\n"
    "  vmovdqu64 0x30000340, %zmm10\n"
    "  vmovdqu64 0x30000380, %zmm11\n"
    "  vmovdqu64 0x300003c0, %zmm12\n"
    "  vmovdqu64 0x30000400, %zmm13\n"
    "  vmovdqu64 0x30000440, %zmm14\n"
    "  vmovdqu64 0x30000480, %zmm15\n"
    "  vmovdqu64 0x300004c0, %zmm16\n"
    "  vmovdqu64 0x30000500, %zmm17\n"
    "  vmovdqu64 0x30000540, %zmm18\n"
    "  vmovdqu64 0x30000580, %zmm19\n"
    "  vmovdqu64 0x300005c0, %zmm20\n"
    "  vmovdqu64 0x30000600, %zmm21\n"
    "  vmovdqu64 0x30000640, %zmm22\n"
    "  vmovdqu64 0x30000680, %zmm23\n"
    "  vmovdqu64 0x300006c0, %zmm24\n"
    "  vmovdqu64 0x30000700, %zmm25\n"
    "  vmovdqu64 0x30000740, %zmm26\n"
    "  vmovdqu64 0x30000780, %zmm27\n"
    "  vmovdqu64 0x300007c0, %zmm28\n"
    "  vmovdqu64 0x30000800, %zmm29\n"
    "  vmovdqu64 0x30000840, %zmm30\n"
    "  vmovdqu64 0x30000880, %zmm31\n"
    "  pushq 0x30000080\n"
    "  popfq\n"
    "  movq %rsp, 0x30000090\n"
    "  movq 0x30000008, %rcx\n"
    "  movq 0x30000010, %rdx\n"
    "  movq 0x30000018, %rbx\n"
    "  movq 0x30000028, %rbp\n"
    "  movq 0x30000030, %rsi\n"
    "  movq 0x30000038, %rdi\n"
    "  movq 0x30000040, %r8\n"
    "  movq 0x30000048, %r9\n"
    "  movq 0x30000050, %r12\n"
    "  movq 0x30000058, %r13\n"
    "  movq 0x30000060, %r14\n"
    "  movq 0x30000068, %r15\n"
    "  movq 0x30000070, %r10\n"
    "  movq 0x30000078, %r11\n"
    "  movq 0x30000020, %rsp\n"
    "  movq 0x30000000, %rax\n"
    "  jmp *0x30000088\n"
    "run_back:\n"
    "  movq %rax, 0x30000000\n"
    "  movq %rcx, 0x30000008\n"
    "  movq %rdx, 0x30000010\n"
    "  movq %rbx, 0x30000018\n"
    "  movq %rbp, 0x30000028\n"
    "  movq %rsi, 0x30000030\n"
    "  movq %rdi, 0x30000038\n"
    "  movq %r8, 0x30000040\n"
    "  movq %r9, 0x30000048\n"
    "  movq %r12, 0x30000050\n"
    "  movq %r13, 0x30000058\n"
    "  movq %r14, 0x30000060\n"
    "  movq %r15, 0x30000068\n"
    "  movq %r10, 0x30000070\n"
    "  movq %r11, 0x30000078\n"
    "  movq %rsp, 0x30000020\n"
    "  movq 0x30000090, %rsp\n"
    "  pushfq\n"
    "  popq 0x30000080\n"
    "  vmovdqu64 %zmm0, 0x300000c0\n"
    "  vmovdqu64 %zmm1, 0x30000100\n"
    "  vmovdqu64 %zmm2, 0x30000140\n"
    "  vmovdqu64 %zmm3, 0x30000180\n"
    "  vmovdqu64 %zmm4, 0x300001c0\n"
    "  vmovdqu64 %zmm5, 0x30000200\n"
    "  vmovdqu64 %zmm6, 0x30000240\n"
    "  vmovdqu64 %zmm7, 0x30000280\n"
    "  vmovdqu64 %zmm8, 0x300002c0\n"
    "  vmovdqu64 %zmm9, 0x30000300\n"
    "  vmovdqu64 %zmm10, 0x30000340\n"
    "  vmovdqu64 %zmm11, 0x30000380\n"
    "  vmovdqu64 %zmm12, 0x300003c0\n"
    "  vmovdqu64 %zmm13, 0x30000400\n"
    "  vmovdqu64 %zmm14, 0x30000440\n"
    "  vmovdqu64 %zmm15, 0x30000480\n"
    "  vmovdqu64 %zmm16, 0x300004c0\n"
    "  vmovdqu64 %zmm17, 0x30000500\n"
    "  vmovdqu64 %zmm18, 0x30000540\n"
    "  vmovdqu64 %zmm19, 0x30000580\n"
    "  vmovdqu64 %zmm20, 0x300005c0\n"
    "  vmovdqu64 %zmm21, 0x30000600\n"
    "  vmovdqu64 %zmm22, 0x30000640\n"
    "  vmovdqu64 %zmm23, 0x30000680\n"
    "  vmovdqu64 %zmm24, 0x300006c0\n"
    "  vmovdqu64 %zmm25, 0x30000700\n"
    "  vmovdqu64 %zmm26, 0x30000740\n"
    "  vmovdqu64 %zmm27, 0x30000780\n"
    "  vmovdqu64 %zmm28, 0x300007c0\n"
    "  vmovdqu64 %zmm29, 0x30000800\n"
    "  vmovdqu64 %zmm30, 0x30000840\n"
    "  vmovdqu64 %zmm31, 0x30000880\n"
    "  vzeroupper\n"
    "  pop %r15\n  pop %r14\n  pop %r13\n  pop %r12\n  pop %rbp\n  pop %rbx\n  ret\n");
extern char run_back[];

#define BASE 0x20001000ull
#define FIELDS 104
static uint64_t hex64(const char *s) { char b[17]; memcpy(b, s, 16); b[16] = 0; return strtoull(b, NULL, 16); }
/* 128 digits, the highest first, as eight quadwords, the lowest first */
static void hex512(const char *s, uint64_t out[8]) { for (int k = 0; k < 8; k++) out[7 - k] = hex64(s + 16 * k); }

int main(int argc, char **argv) {
    FILE *f = fopen(argc > 1 ? argv[1] : "vectors.txt", "r");
    if (!f) { perror("vectors"); return 2; }
    unsigned char *code = mmap(NULL, 4096, PROT_READ | PROT_WRITE | PROT_EXEC, MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
    unsigned char *buf = mmap((void *)(BASE - 0x1000), 0x2000, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANONYMOUS | MAP_FIXED, -1, 0);
    struct regs *r = mmap((void *)SAVED, 0x1000, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANONYMOUS | MAP_FIXED, -1, 0);
    if (code == MAP_FAILED || buf != (unsigned char *)(BASE - 0x1000) || r != (struct regs *)SAVED) { perror("mmap"); return 2; }
    if (sizeof *r > 0x1000 || (char *)r->zmm - (char *)r != 192) { printf("the saved registers are not laid out as the assembly names them\n"); return 2; }
    static char line[65536];
    long tests = 0, bad = 0, skipped = 0, faults = 0, forms = 0, flagsChecked = 0;
    char last[64] = "";
    while (fgets(line, sizeof line, f)) {
        static char *tok[FIELDS + 2]; int n = 0;
        for (char *p = strtok(line, " \n"); p && n < FIELDS + 2; p = strtok(NULL, " \n")) tok[n++] = p;
        if (n < 2) continue;
        if (!strcmp(tok[0], "skip")) { skipped++; continue; }
        if (!strcmp(tok[0], "fault")) { faults++; printf("the model faults on %s\n", tok[1]); continue; }
        if (strcmp(tok[0], "test") || n != FIELDS) { printf("unreadable line (%d fields)\n", n); return 2; }
        if (strcmp(last, tok[1])) { forms++; snprintf(last, sizeof last, "%s", tok[1]); }
        size_t len = strlen(tok[1]) / 2;
        for (size_t i = 0; i < len; i++) { unsigned v; sscanf(tok[1] + 2 * i, "%2x", &v); code[i] = (unsigned char)v; }
        code[len] = 0xFF; code[len + 1] = 0x25; memset(code + len + 2, 0, 4);          /* jmp [rip+0] */
        uint64_t back = (uint64_t)run_back; memcpy(code + len + 6, &back, 8);
        uint64_t seed = strtoull(tok[2], NULL, 10);
        for (uint64_t a = BASE - 512; a < BASE + 512; a++) *(unsigned char *)a = (unsigned char)((a * 2654435761ull + seed * 40503ull) / 256);
        memset(r, 0, sizeof *r);
        for (int i = 0; i < 16; i++) r->gpr[i] = hex64(tok[3 + i]);
        for (int i = 0; i < 32; i++) hex512(tok[19 + i], r->zmm[i]);
        r->flags = 0x2 | (tok[51][0] == '1' ? 0x40 : 0) | (tok[52][0] == '1' ? 0x1 : 0);
        r->code = (uint64_t)code;
        run_one();
        int ok = 1;
        for (int i = 0; i < 16; i++) ok &= r->gpr[i] == hex64(tok[53 + i]);
        uint64_t e[8];
        for (int i = 0; i < 32; i++) { hex512(tok[69 + i], e); ok &= !memcmp(r->zmm[i], e, sizeof e); }
        if (tok[101][0] != '-') { ok &= ((r->flags >> 6) & 1) == (uint64_t)(tok[101][0] - '0'); flagsChecked++; }
        if (tok[102][0] != '-') { ok &= (r->flags & 1) == (uint64_t)(tok[102][0] - '0'); flagsChecked++; }
        for (int k = 0; k < 1024; k++) { unsigned v; sscanf(tok[103] + 2 * k, "%2x", &v); ok &= *(unsigned char *)(BASE - 512 + k) == v; }
        tests++;
        if (!ok) { if (bad++ < 12) printf("DIFFERS: %s (seed %s)\n", tok[1], tok[2]); }
    }
    printf("%ld vectors over %ld instruction forms: %ld differ; %ld flag values checked; %ld instructions left to the proofs; %ld model faults\n",
           tests, forms, bad, flagsChecked, skipped, faults);
    return bad || faults || !tests;
}
