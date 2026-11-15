// kglue_native: push, merge and add of the hasher's stack run on this processor against the merge machine
// written out here, on what their contracts allow. kglue_flip.py links it with each changed object for which
// a proof was found: the processor arbitrates.
//
//     cc -O1 -o run kglue_native.c kflip_thunk.S push.o merge.o add.o KERNELS.o... && ./run push|merge|add CASES
//
// Exit 0: on every case the stack's count and its values below the count are the reference's, the result is the
// count (merge, add), nothing beside the stack's 1792 bytes was written (the key, the new value, the bytes
// around the stack; each lies between two pages that fault), and the registers a callee keeps and the stack
// pointer came back. Exit 1 and one line otherwise. A crash is the caller's to see.
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>

uint64_t b3l_push(uint8_t *st, const uint8_t *cv);
uint64_t b3l_merge(uint8_t *st, const uint8_t *key, uint64_t flags, uint64_t plat, uint64_t target);
uint64_t b3l_add(uint8_t *st, const uint8_t *key, uint64_t flags, uint64_t plat, const uint8_t *cv, uint64_t target);
void call_kernel(void *f, const uint64_t *args, uint64_t *after);      // kflip_thunk.S
extern const uint64_t call_kernel_values[6];

static const uint32_t IV[8] = {0x6A09E667, 0xBB67AE85, 0x3C6EF372, 0xA54FF53A, 0x510E527F, 0x9B05688C, 0x1F83D9AB, 0x5BE0CD19};
static const uint8_t PERM[16] = {2, 6, 3, 10, 7, 0, 4, 13, 1, 11, 12, 5, 9, 14, 15, 8};
static uint32_t ror(uint32_t x, int n) { return x >> n | x << (32 - n); }
static void g(uint32_t *s, int a, int b, int c, int d, uint32_t x, uint32_t y) {
    s[a] += s[b] + x; s[d] = ror(s[d] ^ s[a], 16); s[c] += s[d]; s[b] = ror(s[b] ^ s[c], 12);
    s[a] += s[b] + y; s[d] = ror(s[d] ^ s[a], 8); s[c] += s[d]; s[b] = ror(s[b] ^ s[c], 7);
}
static uint32_t word(const uint8_t *p) { return p[0] | p[1] << 8 | p[2] << 16 | (uint32_t)p[3] << 24; }
// the parent of two chaining values (32 bytes each, little-endian words): BLAKE3's compression of the key,
// the two values as one block, counter 0, 64 bytes, flags | PARENT; its first eight words, as bytes
static void parent(uint8_t out[32], const uint8_t key[32], const uint8_t left[32], const uint8_t right[32], uint32_t flags) {
    uint32_t m[16], s[16], t[16];
    for (int i = 0; i < 8; i++) { m[i] = word(left + 4 * i); m[8 + i] = word(right + 4 * i); s[i] = word(key + 4 * i); s[8 + i] = IV[i]; }
    s[12] = 0; s[13] = 0; s[14] = 64; s[15] = flags | 4;
    for (int r = 0; r < 7; r++) {
        g(s, 0, 4, 8, 12, m[0], m[1]); g(s, 1, 5, 9, 13, m[2], m[3]); g(s, 2, 6, 10, 14, m[4], m[5]); g(s, 3, 7, 11, 15, m[6], m[7]);
        g(s, 0, 5, 10, 15, m[8], m[9]); g(s, 1, 6, 11, 12, m[10], m[11]); g(s, 2, 7, 8, 13, m[12], m[13]); g(s, 3, 4, 9, 14, m[14], m[15]);
        for (int i = 0; i < 16; i++) t[i] = m[PERM[i]];
        memcpy(m, t, sizeof m);
    }
    for (int i = 0; i < 8; i++) { uint32_t v = s[i] ^ s[i + 8]; out[4 * i] = (uint8_t)v; out[4 * i + 1] = (uint8_t)(v >> 8); out[4 * i + 2] = (uint8_t)(v >> 16); out[4 * i + 3] = (uint8_t)(v >> 24); }
}

static uint64_t state = 1;
static uint64_t rnd(void) { state ^= state << 13; state ^= state >> 7; state ^= state << 17; return state; }
enum { PAGE = 4096, SIZE = 1792, CAPACITY = 55 };
static uint8_t *page(void) {
    uint8_t *p = mmap(0, 3 * PAGE, PROT_NONE, MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
    if (p == MAP_FAILED || mprotect(p + PAGE, PAGE, PROT_READ | PROT_WRITE)) { perror("mmap"); exit(2); }
    return p + PAGE;
}
static uint8_t *place(uint8_t *pg, size_t n, size_t align) {
    uint64_t r = rnd();
    size_t at = r % 3 == 0 ? PAGE - n : r % 3 == 1 ? 0 : (r >> 8) % (PAGE - n + 1);
    return pg + at / align * align;
}

int main(int argc, char **argv) {
    if (argc != 3) return 2;
    int push = !strcmp(argv[1], "push"), merge = !strcmp(argv[1], "merge"), add = !strcmp(argv[1], "add");
    if (!push && !merge && !add) return 2;
    int cases = atoi(argv[2]);
    int wide = __builtin_cpu_supports("avx512f") && __builtin_cpu_supports("avx512vl");
    uint8_t *st_page = page(), *key_page = page(), *new_page = page(), copy[PAGE];
    static uint8_t model[CAPACITY + 1][32];
    for (int c = 0; c < cases; c++) {
        state = 0x9E3779B97F4A7C15ull * (uint64_t)(c + 1);
        memset(st_page, 0xA5, PAGE);
        for (int j = 0; j < PAGE; j++) key_page[j] = (uint8_t)rnd();
        for (int j = 0; j < PAGE; j++) new_page[j] = (uint8_t)rnd();
        uint8_t *st = place(st_page, SIZE, 8), *key = place(key_page, 32, 1), *value = place(new_page, 32, 1);
        // what the contract allows: a count the stack's memory holds (one fewer where a value is to be put), a
        // target of at least one, flags below 256, any platform word (5 calls the AVX-512 kernel)
        uint64_t count = rnd() % (merge ? CAPACITY + 1 : CAPACITY);
        uint64_t target = c % 5 == 0 ? rnd() | 1 : 1 + rnd() % 8, flags = rnd() & 0xFF;
        uint64_t plat = wide && rnd() % 2 ? 5 : c % 7 == 0 ? rnd() << 3 : 4;
        for (size_t j = 0; j < SIZE; j++) st[j] = (uint8_t)rnd();
        memcpy(st, &count, 8);
        memcpy(model, st + 32, count * 32);
        memcpy(copy, st_page, PAGE);
        // the reference: the value put on, then the merge machine
        uint64_t n = count;
        if (push || add) { memcpy(model[n], value, 32); n++; }
        if (merge || add) while (n > target) { parent(model[n - 2], key, model[n - 2], model[n - 1], (uint32_t)flags); n--; }
        uint64_t args[6] = {(uint64_t)st, 0, 0, 0, 0, 0}, after[8];
        if (push) args[1] = (uint64_t)value;
        else { args[1] = (uint64_t)key; args[2] = flags; args[3] = plat; if (merge) args[4] = target; else { args[4] = (uint64_t)value; args[5] = target; } }
        if (push) { args[2] = rnd(); args[3] = rnd(); args[4] = rnd(); args[5] = rnd(); }         // the other registers hold anything
        if (merge) args[5] = rnd();
        call_kernel(push ? (void *)b3l_push : merge ? (void *)b3l_merge : (void *)b3l_add, args, after);
        for (int i = 0; i < 6; i++)
            if (after[i] != call_kernel_values[i]) { printf("case %d: a register the callee keeps came back changed (%d)\n", c, i); return 1; }
        if (after[6]) { printf("case %d: the stack pointer came back moved\n", c); return 1; }
        uint64_t got;
        memcpy(&got, st, 8);
        if (got != n) { printf("case %d: the count is %llu, the machine's is %llu\n", c, (unsigned long long)got, (unsigned long long)n); return 1; }
        if (!push && after[7] != n) { printf("case %d: the result is %llu, the count is %llu\n", c, (unsigned long long)after[7], (unsigned long long)n); return 1; }
        if (memcmp(st + 32, model, n * 32)) { printf("case %d: a value below the count is not the machine's\n", c); return 1; }
        for (int j = 0; j < PAGE; j++)
            if ((st_page + j < st || st_page + j >= st + SIZE) && st_page[j] != copy[j]) { printf("case %d: a byte beside the stack's memory was written\n", c); return 1; }
        state = 0x9E3779B97F4A7C15ull * (uint64_t)(c + 1);
        for (int j = 0; j < PAGE; j++) if (key_page[j] != (uint8_t)rnd()) { printf("case %d: the key's page was written\n", c); return 1; }
        for (int j = 0; j < PAGE; j++) if (new_page[j] != (uint8_t)rnd()) { printf("case %d: the new value's page was written\n", c); return 1; }
    }
    printf("%s: %d cases, as the machine\n", argv[1], cases);
    return 0;
}
