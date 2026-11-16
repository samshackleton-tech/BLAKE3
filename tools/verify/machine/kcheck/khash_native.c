// khash_native: `b3l_hashr` (hash.ode: the hash written to be proved) run on this processor against BLAKE3
// written out here another way (the reference's stack of subtrees, not the specification's recursion).
// kfn_flip.py links it with each changed object the verifier accepts: the processor arbitrates.
//
//     cc -O1 -o run khash_native.c kflip_thunk.S pad.o chunk_node.o node_out.o wide32.o wide128.o take.o part32.o subtree.o hashr.o KERNELS.o...
//     ./run CASES
//
// The lengths: every one from 0 to 200, then every seventh to 2200, the three around each multiple of 1024
// up to 70 chunks and of 32768 up to 12, and CASES random ones up to 300,000 bytes; each with no flags and with a mode's flag, on
// the SSE4.1 kernel and (where the processor has AVX-512) the AVX-512 one. The message ends where a page
// that faults begins; the 32 bytes of the hash and the key lie between two such pages.
// First of all, six of the official test vectors, plain and keyed: the reference here gives them, and hashr.
// Exit 0: every hash is the reference's, nothing beside the 32 bytes was written, the registers a callee
// keeps and the stack pointer came back. Exit 1 and one line otherwise. A crash is the caller's to see.
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>

void b3l_hashr(uint8_t *out, const uint8_t *input, uint64_t len, const uint8_t *key, uint64_t flags, uint64_t plat);
void call_kernel(void *f, const uint64_t *args, uint64_t *after);      // kflip_thunk.S
extern const uint64_t call_kernel_values[6];

enum { CHUNK_START = 1, CHUNK_END = 2, PARENT = 4, ROOT = 8 };
static const uint32_t IV[8] = {0x6A09E667, 0xBB67AE85, 0x3C6EF372, 0xA54FF53A, 0x510E527F, 0x9B05688C, 0x1F83D9AB, 0x5BE0CD19};
static const uint8_t PERM[16] = {2, 6, 3, 10, 7, 0, 4, 13, 1, 11, 12, 5, 9, 14, 15, 8};
static uint32_t ror(uint32_t x, int n) { return x >> n | x << (32 - n); }
static void g(uint32_t *s, int a, int b, int c, int d, uint32_t x, uint32_t y) {
    s[a] += s[b] + x; s[d] = ror(s[d] ^ s[a], 16); s[c] += s[d]; s[b] = ror(s[b] ^ s[c], 12);
    s[a] += s[b] + y; s[d] = ror(s[d] ^ s[a], 8); s[c] += s[d]; s[b] = ror(s[b] ^ s[c], 7);
}
static uint32_t word(const uint8_t *p) { return p[0] | p[1] << 8 | p[2] << 16 | (uint32_t)p[3] << 24; }
static void compress(uint32_t h[8], const uint32_t block[16], uint64_t t, uint32_t len, uint32_t flags) {
    uint32_t s[16], m[16], n[16];
    memcpy(m, block, 64);
    for (int i = 0; i < 8; i++) s[i] = h[i];
    for (int i = 0; i < 4; i++) s[8 + i] = IV[i];
    s[12] = (uint32_t)t; s[13] = (uint32_t)(t >> 32); s[14] = len; s[15] = flags;
    for (int r = 0; r < 7; r++) {
        g(s, 0, 4, 8, 12, m[0], m[1]); g(s, 1, 5, 9, 13, m[2], m[3]); g(s, 2, 6, 10, 14, m[4], m[5]); g(s, 3, 7, 11, 15, m[6], m[7]);
        g(s, 0, 5, 10, 15, m[8], m[9]); g(s, 1, 6, 11, 12, m[10], m[11]); g(s, 2, 7, 8, 13, m[12], m[13]); g(s, 3, 4, 9, 14, m[14], m[15]);
        for (int i = 0; i < 16; i++) n[i] = m[PERM[i]];
        memcpy(m, n, 64);
    }
    for (int i = 0; i < 8; i++) h[i] = s[i] ^ s[i + 8];
}

// What a node's compression is given; its chaining value, or with ROOT the hash.
typedef struct { uint32_t h[8], m[16]; uint64_t t; uint32_t len, flags; } node;
static void value(uint32_t out[8], const node *n, uint32_t root) { memcpy(out, n->h, 32); compress(out, n->m, n->t, n->len, n->flags | root); }
static void chunk(node *n, const uint32_t key[8], const uint8_t *p, size_t len, uint64_t t, uint32_t flags) {
    uint32_t m[16], first = CHUNK_START;
    uint8_t last[64] = {0};
    memcpy(n->h, key, 32);
    while (len > 64) {
        for (int i = 0; i < 16; i++) m[i] = word(p + 4 * i);
        compress(n->h, m, t, 64, flags | first);
        first = 0; p += 64; len -= 64;
    }
    memcpy(last, p, len);
    for (int i = 0; i < 16; i++) n->m[i] = word(last + 4 * i);
    n->t = t; n->len = (uint32_t)len; n->flags = flags | first | CHUNK_END;
}
// The reference's way: a stack of the subtrees finished so far, merged as the count of chunks has zero bits.
static void reference(uint8_t out[32], const uint8_t *input, size_t len, const uint8_t key_bytes[32], uint32_t flags) {
    uint32_t key[8], stack[64][8], cv[8], h[8];
    int depth = 0;
    uint64_t chunks = 0;
    node n;
    for (int i = 0; i < 8; i++) key[i] = word(key_bytes + 4 * i);
    while (len > 1024) {
        chunk(&n, key, input, 1024, chunks, flags); value(cv, &n, 0);
        chunks++; input += 1024; len -= 1024;
        for (uint64_t total = chunks; (total & 1) == 0; total >>= 1) {
            depth--;
            memcpy(n.h, key, 32); memcpy(n.m, stack[depth], 32); memcpy(n.m + 8, cv, 32); n.t = 0; n.len = 64; n.flags = flags | PARENT;
            value(cv, &n, 0);
        }
        memcpy(stack[depth++], cv, 32);
    }
    chunk(&n, key, input, len, chunks, flags);
    while (depth > 0) {
        value(cv, &n, 0); depth--;
        memcpy(n.h, key, 32); memcpy(n.m, stack[depth], 32); memcpy(n.m + 8, cv, 32); n.t = 0; n.len = 64; n.flags = flags | PARENT;
    }
    value(h, &n, ROOT);
    for (int i = 0; i < 8; i++) { out[4 * i] = (uint8_t)h[i]; out[4 * i + 1] = (uint8_t)(h[i] >> 8); out[4 * i + 2] = (uint8_t)(h[i] >> 16); out[4 * i + 3] = (uint8_t)(h[i] >> 24); }
}

// Six of the official test vectors (test_vectors/test_vectors.json: byte i of the input is i % 251; the key of
// the keyed hash is "whats the Elvish word for friend"): the reference here, and hashr, must give them.
static const struct { size_t len; const char *hash, *keyed; } OFFICIAL[] = {
    {0, "af1349b9f5f9a1a6a0404dea36dcc9499bcb25c9adc112b7cc9a93cae41f3262", "92b2b75604ed3c761f9d6f62392c8a9227ad0ea3f09573e783f1498a4ed60d26"},
    {1, "2d3adedff11b61f14c886e35afa036736dcd87a74d27b5c1510225d0f592e213", "6d7878dfff2f485635d39013278ae14f1454b8c0a3a2d34bc1ab38228a80c95b"},
    {1024, "42214739f095a406f3fc83deb889744ac00df831c10daa55189b5d121c855af7", "75c46f6f3d9eb4f55ecaaee480db732e6c2105546f1e675003687c31719c7ba4"},
    {1025, "d00278ae47eb27b34faecf67b4fe263f82d5412916c1ffd97c8cb7fb814b8444", "357dc55de0c7e382c900fd6e320acc04146be01db6a8ce7210b7189bd664ea69"},
    {31744, "62b6960e1a44bcc1eb1a611a8d6235b6b4b78f32e7abc4fb4c6cdcce94895c47", "efa53b389ab67c593dba624d898d0f7353ab99e4ac9d42302ee64cbf9939a419"},
    {102400, "bc3e3d41a1146b069abffad3c0d44860cf664390afce4d9661f7902e7943e085", "1c35d1a5811083fd7119f5d5d1ba027b4d01c0c6c49fb6ff2cf75393ea5db4a7"},
};
static int official(int wide) {
    static uint8_t input[102400], iv[32];
    static const char KEY[] = "whats the Elvish word for friend";
    char hex[65];
    uint8_t out[32];
    for (size_t i = 0; i < sizeof input; i++) input[i] = (uint8_t)(i % 251);
    for (int i = 0; i < 8; i++) { iv[4 * i] = (uint8_t)IV[i]; iv[4 * i + 1] = (uint8_t)(IV[i] >> 8); iv[4 * i + 2] = (uint8_t)(IV[i] >> 16); iv[4 * i + 3] = (uint8_t)(IV[i] >> 24); }
    for (unsigned c = 0; c < sizeof OFFICIAL / sizeof *OFFICIAL; c++)
        for (int mode = 0; mode < 2; mode++)
            for (int which = 0; which < (wide ? 3 : 2); which++) {         // the reference; hashr on the SSE4.1 kernel; on the AVX-512 ones
                const uint8_t *key = mode ? (const uint8_t *)KEY : iv;
                if (which == 0) reference(out, input, OFFICIAL[c].len, key, mode ? 16 : 0);
                else b3l_hashr(out, input, OFFICIAL[c].len, key, mode ? 16 : 0, which == 2 ? 5 : 0);
                for (int i = 0; i < 32; i++) sprintf(hex + 2 * i, "%02x", out[i]);
                if (strcmp(hex, mode ? OFFICIAL[c].keyed : OFFICIAL[c].hash)) {
                    printf("an official vector (%zu bytes, %s) is not what %s gives\n", OFFICIAL[c].len, mode ? "keyed" : "plain", which ? "hashr" : "the reference here");
                    return 1;
                }
            }
    return 0;
}

static uint64_t seed = 0x9E3779B97F4A7C15ull;
static uint64_t rnd(void) { seed ^= seed << 13; seed ^= seed >> 7; seed ^= seed << 17; return seed; }

// `size` bytes that end where a page that faults begins, and begin after one (for size a multiple of 4096).
static uint8_t *guarded(size_t size, int both) {
    size_t pages = (size + 4095) / 4096 * 4096;
    uint8_t *p = mmap(0, pages + 8192, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
    if (p == MAP_FAILED) { perror("mmap"); exit(3); }
    mprotect(p, 4096, PROT_NONE); mprotect(p + 4096 + pages, 4096, PROT_NONE);
    (void)both;
    return p + 4096 + pages - size;
}

static int one(size_t len, uint32_t flags, uint64_t plat, long id) {
    uint8_t *input = guarded(len, 0), *page = guarded(4096, 1), *keypage = guarded(4096, 1), want[32], before[4096];
    uint8_t *out = page + 4096 - 32 - 8 * (rnd() % 100), *key = keypage + 4096 - 32;
    uint64_t args[6] = {(uint64_t)out, (uint64_t)input, len, (uint64_t)key, flags, plat}, after[8];
    int bad = 0;
    for (size_t i = 0; i < len; i++) input[i] = (uint8_t)rnd();
    for (int i = 0; i < 4096; i++) page[i] = (uint8_t)rnd();
    for (int i = 0; i < 32; i++) key[i] = (uint8_t)rnd();
    memcpy(before, page, 4096);
    reference(want, input, len, key, flags);
    call_kernel((void *)b3l_hashr, args, after);
    if (memcmp(out, want, 32)) { printf("case %ld: the hash of %zu bytes (flags %u, platform %lu) is not BLAKE3's\n", id, len, flags, (unsigned long)plat); bad = 1; }
    else {
        memcpy(before + (out - page), want, 32);
        if (memcmp(before, page, 4096)) { printf("case %ld: bytes beside the hash were written (%zu bytes hashed)\n", id, len); bad = 1; }
        else if (memcmp(after, call_kernel_values, 48) || after[6]) { printf("case %ld: a kept register or the stack pointer did not come back (%zu bytes hashed)\n", id, len); bad = 1; }
    }
    size_t pages = (len + 4095) / 4096 * 4096;
    munmap(input + len - pages - 4096, pages + 8192); munmap(page - 4096, 3 * 4096); munmap(keypage - 4096, 3 * 4096);
    return bad;
}

int main(int argc, char **argv) {
    long cases = argc > 1 ? atol(argv[1]) : 100, id = 0;
    __builtin_cpu_init();
    int wide = __builtin_cpu_supports("avx512f") && __builtin_cpu_supports("avx512vl");
    static const uint32_t MODES[4] = {0, 16, 32, 64};
    if (official(wide)) return 1;
    for (int pass = 0; pass < (wide ? 2 : 1); pass++) {
        uint64_t plat = pass ? 5 : (id % 2 ? 0 : 3);
        for (size_t len = 0; len <= 200; len++) { if (one(len, len % 3 ? 0 : MODES[1 + len % 3], plat, id++)) return 1; }
        for (size_t len = 201; len <= 2200; len += 7) { if (one(len, MODES[rnd() % 4], plat, id++)) return 1; }
        for (size_t k = 1; k <= 70; k++)
            for (int d = -1; d <= 1; d++) { if (one(1024 * k + d, MODES[rnd() % 4], plat, id++)) return 1; }
        for (size_t k = 1; k <= 12; k++)        // whole trees of 32 chunks: the wide kernels' leaves
            for (int d = -1; d <= 1; d++) { if (one(32768 * k + d, MODES[rnd() % 4], plat, id++)) return 1; }
        for (long i = 0; i < cases; i++) { if (one(rnd() % 300001, MODES[rnd() % 4], plat, id++)) return 1; }
    }
    if (argc > 2) printf("%ld hashes as BLAKE3's (%s)\n", id, wide ? "both kernels" : "the SSE4.1 kernel");
    return 0;
}
