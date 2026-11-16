// kone_native: a one-block kernel run on this processor against BLAKE3's compression written out here, on
// what its contract (kone.py) allows. kglue_flip.py links it with each changed object the verifier accepted.
//
//     cc -O1 -o run kone_native.c kflip_thunk.S OBJECT && ./run avx512|sse41 CASES
//
// avx512: RDX and R8 hold any 64 bits; the length and the flags are their low bytes.
// sse41:  RDX is below 2^32 and is the length; R8 holds any 64 bits and its low word is the flags.
// Exit 0: on every case the 32 bytes at cv are the reference's, nothing else was written (the block's page,
// the bytes around cv; each lies between two pages that fault), the registers a callee keeps and the stack
// pointer came back. Exit 1 and one line otherwise.
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>

__attribute__((weak)) void blake3_servil_compress_in_place_avx512(uint32_t *cv, const uint8_t *block, uint8_t block_len, uint64_t counter, uint8_t flags);
__attribute__((weak)) void blake3_servil_compress_in_place_sse41(uint32_t *cv, const uint8_t *block, uint8_t block_len, uint64_t counter, uint8_t flags);
void call_kernel(void *f, const uint64_t *args, uint64_t *after);
extern const uint64_t call_kernel_values[6];

static const uint32_t IV[8] = {0x6A09E667, 0xBB67AE85, 0x3C6EF372, 0xA54FF53A, 0x510E527F, 0x9B05688C, 0x1F83D9AB, 0x5BE0CD19};
static const uint8_t PERM[16] = {2, 6, 3, 10, 7, 0, 4, 13, 1, 11, 12, 5, 9, 14, 15, 8};
static uint32_t ror(uint32_t x, int n) { return x >> n | x << (32 - n); }
static void g(uint32_t *s, int a, int b, int c, int d, uint32_t x, uint32_t y) {
    s[a] += s[b] + x; s[d] = ror(s[d] ^ s[a], 16); s[c] += s[d]; s[b] = ror(s[b] ^ s[c], 12);
    s[a] += s[b] + y; s[d] = ror(s[d] ^ s[a], 8); s[c] += s[d]; s[b] = ror(s[b] ^ s[c], 7);
}
static void compress(uint32_t cv[8], const uint8_t block[64], uint64_t counter, uint32_t len, uint32_t flags) {
    uint32_t m[16], s[16], t[16];
    for (int i = 0; i < 16; i++) m[i] = block[4 * i] | block[4 * i + 1] << 8 | block[4 * i + 2] << 16 | (uint32_t)block[4 * i + 3] << 24;
    for (int i = 0; i < 8; i++) { s[i] = cv[i]; s[8 + i] = IV[i]; }
    s[12] = (uint32_t)counter; s[13] = (uint32_t)(counter >> 32); s[14] = len; s[15] = flags;
    for (int r = 0; r < 7; r++) {
        g(s, 0, 4, 8, 12, m[0], m[1]); g(s, 1, 5, 9, 13, m[2], m[3]); g(s, 2, 6, 10, 14, m[4], m[5]); g(s, 3, 7, 11, 15, m[6], m[7]);
        g(s, 0, 5, 10, 15, m[8], m[9]); g(s, 1, 6, 11, 12, m[10], m[11]); g(s, 2, 7, 8, 13, m[12], m[13]); g(s, 3, 4, 9, 14, m[14], m[15]);
        for (int i = 0; i < 16; i++) t[i] = m[PERM[i]];
        memcpy(m, t, sizeof m);
    }
    for (int i = 0; i < 8; i++) cv[i] = s[i] ^ s[i + 8];
}

static uint64_t state = 1;
static uint64_t rnd(void) { state ^= state << 13; state ^= state >> 7; state ^= state << 17; return state; }
enum { PAGE = 4096 };
static uint8_t *page(void) {
    uint8_t *p = mmap(0, 3 * PAGE, PROT_NONE, MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
    if (p == MAP_FAILED || mprotect(p + PAGE, PAGE, PROT_READ | PROT_WRITE)) { perror("mmap"); exit(2); }
    return p + PAGE;
}
static uint8_t *place(uint8_t *pg, size_t n) {
    uint64_t r = rnd();
    return pg + (r % 3 == 0 ? PAGE - n : r % 3 == 1 ? 0 : (r >> 8) % (PAGE - n + 1));
}

int main(int argc, char **argv) {
    if (argc != 3) return 2;
    int wide = !strcmp(argv[1], "avx512"), cases = atoi(argv[2]);
    void *f = wide ? (void *)blake3_servil_compress_in_place_avx512 : (void *)blake3_servil_compress_in_place_sse41;
    if (!f) { printf("the object does not hold %s's kernel\n", argv[1]); return 2; }
    uint8_t *cv_page = page(), *block_page = page();
    for (int c = 0; c < cases; c++) {
        state = 0x9E3779B97F4A7C15ull * (uint64_t)(c + 1);
        memset(cv_page, 0xA5, PAGE);
        for (int j = 0; j < PAGE; j++) block_page[j] = (uint8_t)rnd();
        uint8_t *cvp = place(cv_page, 32), *block = place(block_page, 64);
        uint32_t cv[8];
        for (int i = 0; i < 8; i++) cv[i] = (uint32_t)rnd();
        memcpy(cvp, cv, 32);
        uint64_t counter = c % 3 == 0 ? rnd() : c % 3 == 1 ? 0xFFFFFFFFull - rnd() % 3 : rnd() << 32;
        uint64_t rdx = wide ? rnd() : rnd() & 0xFFFFFFFFull, r8 = rnd();
        compress(cv, block, counter, wide ? (uint32_t)(rdx & 0xFF) : (uint32_t)rdx, wide ? (uint32_t)(r8 & 0xFF) : (uint32_t)r8);
        uint64_t args[6] = {(uint64_t)cvp, (uint64_t)block, rdx, counter, r8, rnd()}, after[8];
        call_kernel(f, args, after);
        for (int i = 0; i < 6; i++)
            if (after[i] != call_kernel_values[i]) { printf("case %d: a register the callee keeps came back changed (%d)\n", c, i); return 1; }
        if (after[6]) { printf("case %d: the stack pointer came back moved\n", c); return 1; }
        if (memcmp(cvp, cv, 32)) { printf("case %d: the chaining value is not BLAKE3's\n", c); return 1; }
        for (int j = 0; j < PAGE; j++)
            if ((cv_page + j < cvp || cv_page + j >= cvp + 32) && cv_page[j] != 0xA5) { printf("case %d: a byte beside the chaining value was written\n", c); return 1; }
        state = 0x9E3779B97F4A7C15ull * (uint64_t)(c + 1);
        for (int j = 0; j < PAGE; j++) if (block_page[j] != (uint8_t)rnd()) { printf("case %d: the block's page was written\n", c); return 1; }
    }
    printf("%s: %d cases, as BLAKE3\n", argv[1], cases);
    return 0;
}
