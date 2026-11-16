// kflip_native: a kernel object run on this processor against BLAKE3 written out here, on inputs the
// contract allows. kflip.py links it with each changed object its verifier accepted: the processor arbitrates.
//
//     cc -O1 -o run kflip_native.c kflip_thunk.S OBJECT && ./run k32|p32|p16|o16 CASES [over|any]
//
// `any` (k32, p32, p16): the kernel's whole interface, as kloop.py shows it: 1 to 20 blocks an input, any
// flags, start, end and last-length bytes, any counter, and anything in the packed word's upper half.
//
// Exit 0: on every case the 32 (16) chaining values are the reference's, nothing beside the output was
// written (the bytes around it, the inputs, the table of their addresses, the key), and the registers a
// callee keeps and the stack pointer came back. Exit 1 and one line otherwise. A crash is the caller's to
// see (a signal): each thing the kernel is given lies in a page of its own between two pages that fault,
// against one of them or the other or anywhere between, so a read or a write beside it faults.
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>

typedef void kernel(const uint8_t *const *inputs, uint64_t blocks, const uint32_t *key, uint64_t counter, uint64_t packed, uint8_t *out);
// weak: an object holds the kernels of one source file, and the others' names stay unresolved
__attribute__((weak)) kernel blake3_servil_avx512_k32, blake3_servil_avx512_p32, blake3_servil_avx512_p16;
// c/blake3_output16.S: (descriptors, out), a descriptor a lane
struct descriptor { const uint8_t *block; const uint32_t *cv; uint8_t length, flags; uint8_t unused[6]; };
__attribute__((weak)) void blake3_servil_output16(const struct descriptor *inputs, uint8_t *out);
// kflip_thunk.S: calls f(args[0..5]) with known values in rbx, rbp, r12..r15; leaves what they and rsp were after in after[0..6]
void call_kernel(kernel *f, const uint64_t *args, uint64_t *after);
extern const uint64_t call_kernel_values[6];

static const uint32_t IV[8] = {0x6A09E667, 0xBB67AE85, 0x3C6EF372, 0xA54FF53A, 0x510E527F, 0x9B05688C, 0x1F83D9AB, 0x5BE0CD19};
static const uint8_t PERM[16] = {2, 6, 3, 10, 7, 0, 4, 13, 1, 11, 12, 5, 9, 14, 15, 8};
static uint32_t ror(uint32_t x, int n) { return x >> n | x << (32 - n); }
static void g(uint32_t *s, int a, int b, int c, int d, uint32_t x, uint32_t y) {
    s[a] += s[b] + x; s[d] = ror(s[d] ^ s[a], 16); s[c] += s[d]; s[b] = ror(s[b] ^ s[c], 12);
    s[a] += s[b] + y; s[d] = ror(s[d] ^ s[a], 8); s[c] += s[d]; s[b] = ror(s[b] ^ s[c], 7);
}
// BLAKE3's compression (the paper's section 2.2), the first 8 words of its result
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
// a page that can be read and written, between two that fault
static uint8_t *page(void) {
    uint8_t *p = mmap(0, 3 * PAGE, PROT_NONE, MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
    if (p == MAP_FAILED || mprotect(p + PAGE, PAGE, PROT_READ | PROT_WRITE)) { perror("mmap"); exit(2); }
    return p + PAGE;
}
// n bytes in the page: against the page above, against the page below, or anywhere
static uint8_t *place(uint8_t *pg, size_t n, size_t align) {
    uint64_t r = rnd();
    size_t at = r % 3 == 0 ? PAGE - n : r % 3 == 1 ? 0 : (r >> 8) % (PAGE - n + 1);
    return pg + at / align * align;
}

int main(int argc, char **argv) {
    if (argc < 3) return 2;
    int over = argc > 3 && !strcmp(argv[3], "over");        // a control: one block more than the inputs hold is asked for, and a page that faults is read
    int any = argc > 3 && !strcmp(argv[3], "any");
    int p16 = !strcmp(argv[1], "p16"), k32 = !strcmp(argv[1], "k32"), o16 = !strcmp(argv[1], "o16");
    kernel *f = o16 ? (kernel *)blake3_servil_output16 : p16 ? blake3_servil_avx512_p16 : k32 ? blake3_servil_avx512_k32 : blake3_servil_avx512_p32;
    if (!f) { printf("the object does not hold %s's kernel\n", argv[1]); return 2; }
    if (sizeof(struct descriptor) != 24) return 2;
    int lanes = p16 || o16 ? 16 : 32, blocks = p16 || o16 ? 1 : 16, cases = atoi(argv[2]);
    uint8_t *cv_page[16];
    for (int i = 0; i < 16; i++) cv_page[i] = o16 ? page() : 0;
    uint8_t *in_page[32], *key_page = page(), *table_page = page(), *out_page = page(), *shadow = malloc(PAGE);
    for (int i = 0; i < lanes; i++) in_page[i] = page();
    for (int c = 0; c < cases; c++) {
        state = 0x9E3779B97F4A7C15ull * (uint64_t)(c + 1);
        // what every page holds is made again from its seed afterwards, to see that nothing was written
        uint64_t seed = state;
        for (int i = 0; i < lanes; i++) for (int j = 0; j < PAGE; j++) in_page[i][j] = (uint8_t)rnd();
        for (int j = 0; j < PAGE; j++) key_page[j] = (uint8_t)rnd();
        for (int j = 0; j < PAGE; j++) table_page[j] = (uint8_t)rnd();
        if (o16) for (int i = 0; i < 16; i++) for (int j = 0; j < PAGE; j++) cv_page[i][j] = (uint8_t)rnd();
        int nb = any && !o16 ? 1 + (int)(rnd() % 20) : blocks;
        size_t len = 64 * (size_t)nb;
        size_t table_size = o16 ? 24 * 16 : 8 * (size_t)lanes;
        const uint8_t **inputs = (const uint8_t **)place(table_page, table_size, 8);
        uint32_t *key = (uint32_t *)place(key_page, 32, 4), key0[8];
        memcpy(key0, key, 32);
        const uint8_t *in0[32];
        struct descriptor d0[16];
        if (o16) {
            // a descriptor a lane: its block and chaining value anywhere, a length 0 to 64, any flags byte
            struct descriptor *d = (struct descriptor *)inputs;
            for (int i = 0; i < 16; i++) {
                d[i].block = over ? in_page[i] + PAGE - 63 : place(in_page[i], 64, 1);       // the control: a block one byte short of its page
                d[i].cv = (const uint32_t *)place(cv_page[i], 32, 1);
                d[i].length = (uint8_t)(rnd() % 65); d[i].flags = (uint8_t)rnd();
                in0[i] = d[i].block;
            }
            memcpy(d0, d, sizeof d0);
        } else {
            for (int i = 0; i < lanes; i++) inputs[i] = place(in_page[i], len, 1);        // any alignment
            memcpy(in0, inputs, 8 * (size_t)lanes);
        }
        uint64_t flags = rnd() & 0xFF;
        // the counter: any; one case in four close below a carry out of the low word or of the whole
        uint64_t counter = p16 && !any ? 0 : (c % 4 == 1 ? 0xFFFFFFFFull - rnd() % 40 : c % 4 == 2 ? 0xFFFFFFFFFFFFFFFFull - rnd() % 40 : c % 4 == 3 ? rnd() << 32 | (0xFFFFFFFFull - rnd() % 40) : rnd());
        uint64_t mode = p16 && !any ? flags | 4 : flags;         // the parents' kernel is given the PARENT flag by its caller
        uint64_t start_byte = any ? rnd() & 0xFF : p16 ? 0 : 1, end_byte = any ? rnd() & 0xFF : p16 ? 0 : 2, last_length = any ? rnd() & 0xFF : 64;
        uint64_t packed = mode | start_byte << 8 | end_byte << 16 | last_length << 24 | (any ? rnd() << 32 : 0);
        memset(out_page, 0xA5, PAGE);
        uint8_t *out = place(out_page, 32 * (size_t)lanes, 1);
        uint64_t args[6] = {(uint64_t)inputs, (uint64_t)(nb + over), (uint64_t)key, counter, packed, (uint64_t)out}, after[8];
        if (o16) { args[1] = (uint64_t)out; args[2] = args[3] = args[4] = args[5] = rnd(); }       // (descriptors, out); the other registers hold anything
        call_kernel(f, args, after);
        for (int i = 0; i < 6; i++)
            if (after[i] != call_kernel_values[i]) { printf("case %d: a register the callee keeps came back changed (%d)\n", c, i); return 1; }
        if (after[6]) { printf("case %d: the stack pointer came back moved\n", c); return 1; }
        for (int lane = 0; lane < lanes; lane++) {
            uint32_t cv[8];
            memcpy(cv, key0, sizeof cv);
            if (o16) { memcpy(cv, d0[lane].cv, sizeof cv); compress(cv, in0[lane], 0, d0[lane].length, d0[lane].flags); }
            else
                for (int b = 0; b < nb; b++)
                    compress(cv, in0[lane] + 64 * b, k32 ? counter + (uint64_t)lane : counter, b == nb - 1 ? (uint32_t)last_length : 64,
                             (uint32_t)(mode | (b == 0 ? start_byte : 0) | (b == nb - 1 ? end_byte : 0)));
            for (int w = 0; w < 8; w++) {
                const uint8_t *q = out + 32 * lane + 4 * w;
                uint32_t got = q[0] | q[1] << 8 | q[2] << 16 | (uint32_t)q[3] << 24;
                if (got != cv[w]) { printf("case %d: lane %d word %d is %08x, BLAKE3's is %08x\n", c, lane, w, got, cv[w]); return 1; }
            }
        }
        for (uint8_t *q = out_page; q < out_page + PAGE; q++)
            if ((q < out || q >= out + 32 * lanes) && *q != 0xA5) { printf("case %d: a byte beside the output was written (%ld)\n", c, (long)(q - out)); return 1; }
        state = seed;
        for (int i = 0; i < lanes; i++) {
            for (int j = 0; j < PAGE; j++) shadow[j] = (uint8_t)rnd();
            if (memcmp(shadow, in_page[i], PAGE)) { printf("case %d: input %d's page was written\n", c, i); return 1; }
        }
        for (int j = 0; j < PAGE; j++) shadow[j] = (uint8_t)rnd();
        if (memcmp(shadow, key_page, PAGE)) { printf("case %d: the key's page was written\n", c); return 1; }
        for (int j = 0; j < PAGE; j++) shadow[j] = (uint8_t)rnd();
        if (o16) memcpy(shadow + ((uint8_t *)inputs - table_page), d0, sizeof d0);
        else memcpy(shadow + ((uint8_t *)inputs - table_page), in0, 8 * (size_t)lanes);
        if (memcmp(shadow, table_page, PAGE)) { printf("case %d: the table of addresses was written\n", c); return 1; }
        if (o16) for (int i = 0; i < 16; i++) {
            for (int j = 0; j < PAGE; j++) shadow[j] = (uint8_t)rnd();
            if (memcmp(shadow, cv_page[i], PAGE)) { printf("case %d: chaining value %d's page was written\n", c, i); return 1; }
        }
    }
    printf("%s: %d cases, as BLAKE3\n", argv[1], cases);
    return 0;
}
