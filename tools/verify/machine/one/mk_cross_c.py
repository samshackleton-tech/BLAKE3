#!/usr/bin/env python3
"""Write cross_one.c: the processor's side of the cross-check of one/Machine.lean.

The model has every general register and every ZMM register, so the harness keeps none for itself: the
registers' values before and after an instruction are in memory at a fixed address below 2 GiB, which
every load and store here names outright (no base register)."""
import pathlib
names = "rax rcx rdx rbx rsp rbp rsi rdi r8 r9 r12 r13 r14 r15 r10 r11".split()   # the model's order, then R10 and R11
S = 0x30000000                      # where the saved registers are
GPR, FLAGS, CODE, REALSP, KMASK, ZMM = S, S + 128, S + 136, S + 144, S + 152, S + 192
q = lambda s: '    "' + s + '\\n"\n'
loads = "".join(q(f"  vmovdqu64 0x{ZMM + 64 * i:x}, %zmm{i}") for i in range(32)) + q(f"  kmovw 0x{KMASK:x}, %k1") + q(f"  kmovw 0x{KMASK + 2:x}, %k2")
stores = "".join(q(f"  vmovdqu64 %zmm{i}, 0x{ZMM + 64 * i:x}") for i in range(32)) + q(f"  kmovw %k1, 0x{KMASK:x}") + q(f"  kmovw %k2, 0x{KMASK + 2:x}")
gl = "".join(q(f"  movq 0x{GPR + 8 * i:x}, %{r}") for i, r in enumerate(names) if r not in ("rsp", "rax"))
gs = "".join(q(f"  movq %{r}, 0x{GPR + 8 * i:x}") for i, r in enumerate(names) if r != "rsp")
HEAD = r'''/* The cross-check of one/Machine.lean against this CPU: every instruction of the programs proved on it
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
    uint16_t k1, k2;      /* AVX-512 mask registers k1, k2 */
    uint16_t kpad[2];
    uint64_t pad[4];
    uint64_t zmm[32][8];  /* lowest quadword first */
};
#define SAVED 0x30000000ull

void run_one(void);
/* No register is the harness's own: every one is loaded before the instruction and stored after it. */
__asm__(
    ".globl run_one\n.globl run_back\n"
    "run_one:\n"
    "  push %rbx\n  push %rbp\n  push %r12\n  push %r13\n  push %r14\n  push %r15\n"
'''
MID1 = q(f"  pushq 0x{FLAGS:x}") + q("  popfq") + q(f"  movq %rsp, 0x{REALSP:x}")
MID2 = q(f"  movq 0x{GPR + 32:x}, %rsp") + q(f"  movq 0x{GPR:x}, %rax") + q(f"  jmp *0x{CODE:x}") + q("run_back:")
MID3 = q(f"  movq %rsp, 0x{GPR + 32:x}") + q(f"  movq 0x{REALSP:x}, %rsp") + q("  pushfq") + q(f"  popq 0x{FLAGS:x}")
TAIL = r'''    "  vzeroupper\n"
    "  pop %r15\n  pop %r14\n  pop %r13\n  pop %r12\n  pop %rbp\n  pop %rbx\n  ret\n");
extern char run_back[];

#define BASE 0x20001000ull
#define FIELDS 108
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
        r->k1 = (uint16_t)strtoul(tok[53], NULL, 16);
        r->k2 = (uint16_t)strtoul(tok[54], NULL, 16);
        r->code = (uint64_t)code;
        run_one();
        int ok = 1;
        for (int i = 0; i < 16; i++) ok &= r->gpr[i] == hex64(tok[55 + i]);
        uint64_t e[8];
        for (int i = 0; i < 32; i++) { hex512(tok[71 + i], e); ok &= !memcmp(r->zmm[i], e, sizeof e); }
        if (tok[103][0] != '-') { ok &= ((r->flags >> 6) & 1) == (uint64_t)(tok[103][0] - '0'); flagsChecked++; }
        if (tok[104][0] != '-') { ok &= (r->flags & 1) == (uint64_t)(tok[104][0] - '0'); flagsChecked++; }
        ok &= r->k1 == (uint16_t)strtoul(tok[105], NULL, 16);
        ok &= r->k2 == (uint16_t)strtoul(tok[106], NULL, 16);
        for (int k = 0; k < 1024; k++) { unsigned v; sscanf(tok[107] + 2 * k, "%2x", &v); ok &= *(unsigned char *)(BASE - 512 + k) == v; }
        tests++;
        if (!ok) { if (bad++ < 12) printf("DIFFERS: %s (seed %s)\n", tok[1], tok[2]); }
    }
    printf("%ld vectors over %ld instruction forms: %ld differ; %ld flag values checked; %ld instructions left to the proofs; %ld model faults\n",
           tests, forms, bad, flagsChecked, skipped, faults);
    return bad || faults || !tests;
}
'''
pathlib.Path(__file__).resolve().parent.joinpath("cross_one.c").write_text(HEAD + loads + MID1 + gl + MID2 + gs + MID3 + stores + TAIL)
print("wrote cross_one.c")
