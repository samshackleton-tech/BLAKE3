// ode_lz4_decode on this machine's processor, against an LZ4 block decoder written here another way.
//
//   cc -O1 -o run native.c lz4_decode.o && ./run CASES safety|sound|full
//
// The input ends where a page that faults begins, and so does the room for the output; the bytes before the
// output are looked at afterwards. `safety`: the function returns, and has written nothing but the cap bytes
// at out (a read past the input, or a write past the output, is a crash; a write before it is seen).
// `sound`: what the public contract says: and a count it gives is the count of the bytes the block decodes
// to, which are then at out. `full`: and it gives NO only where the reference decoder does (no block, or no
// room). Exit 0: so in every case; 1: not so.
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#define NO 0xFFFFFFFFFFFFFFFFull
uint64_t ode_lz4_decode(uint8_t *out, uint64_t cap, const uint8_t *input, uint64_t n);

static uint64_t seed = 0x243F6A8885A308D3ull;
static uint64_t rnd(void) { seed ^= seed << 13; seed ^= seed >> 7; seed ^= seed << 17; return seed; }

// The reference: one sequence a turn, with a place in the input and a place in the output.
static uint64_t reference(const uint8_t *src, uint64_t n, uint8_t *dst, uint64_t cap) {
    uint64_t i = 0, o = 0;
    for (;;) {
        if (i >= n) return NO;
        unsigned token = src[i++];
        uint64_t lit = token >> 4;
        if (lit == 15) { unsigned b; do { if (i >= n) return NO; b = src[i++]; lit += b; if (lit > n) return NO; } while (b == 255); }
        if (lit > n - i || lit > cap - o) return NO;
        memcpy(dst + o, src + i, lit); o += lit; i += lit;
        if (i == n) return o;
        if (n - i < 2) return NO;
        uint64_t offset = src[i] | (uint64_t)src[i + 1] << 8; i += 2;
        if (offset == 0 || offset > o) return NO;
        uint64_t m = token & 15;
        if (m == 15) { unsigned b; do { if (i >= n) return NO; b = src[i++]; m += b; if (m > cap) return NO; } while (b == 255); }
        m += 4;
        if (m > cap - o) return NO;
        for (uint64_t k = 0; k < m; k++, o++) dst[o] = dst[o - offset];
    }
}

// A block for some bytes: matches of four or more found by looking back a little (for tests: slow, valid).
static size_t length(uint8_t *out, size_t n) { size_t k = 0; while (n >= 255) { out[k++] = 255; n -= 255; } out[k++] = (uint8_t)n; return k; }
static size_t compress(const uint8_t *d, size_t n, uint8_t *out) {
    size_t i = 0, start = 0, k = 0;
    while (i + 12 < n) {
        size_t best = 0, where = 0;
        for (size_t j = i > 64 ? i - 64 : 0; j < i; j++) { size_t m = 0; while (i + m < n - 5 && d[j + m] == d[i + m]) m++; if (m > best) { best = m; where = j; } }
        if (best < 4) { i++; continue; }
        size_t lit = i - start, m = best - 4;
        out[k++] = (uint8_t)((lit < 15 ? lit : 15) << 4 | (m < 15 ? m : 15));
        if (lit >= 15) k += length(out + k, lit - 15);
        memcpy(out + k, d + start, lit); k += lit;
        out[k++] = (uint8_t)(i - where); out[k++] = (uint8_t)((i - where) >> 8);
        if (m >= 15) k += length(out + k, m - 15);
        i += best; start = i;
    }
    size_t lit = n - start;
    out[k++] = (uint8_t)((lit < 15 ? lit : 15) << 4);
    if (lit >= 15) k += length(out + k, lit - 15);
    memcpy(out + k, d + start, lit);
    return k + lit;
}

int main(int argc, char **argv) {
    long cases = argc > 1 ? atol(argv[1]) : 2000;
    int full = argc > 2 && !strcmp(argv[2], "full"), sound = full || (argc > 2 && !strcmp(argv[2], "sound"));
    size_t room = 1 << 16;
    uint8_t *in = mmap(0, room + 4096, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
    uint8_t *outs = mmap(0, room + 4096, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
    static uint8_t text[20000], block[40000], want[70000];
    if (in == MAP_FAILED || outs == MAP_FAILED || mprotect(in + room, 4096, PROT_NONE) || mprotect(outs + room, 4096, PROT_NONE)) return 2;
    long blocks = 0, refused = 0;
    for (long c = 0; c < cases; c++) {
        // some bytes that repeat, their block, and then perhaps damage to it; or bytes of no block at all
        size_t len = c < 40 ? (size_t)c : rnd() % (c % 7 ? 600 : 20000), n;
        unsigned alphabet = 1 + rnd() % (c % 3 ? 4 : 250);
        for (size_t i = 0; i < len; i++) text[i] = (uint8_t)(rnd() % alphabet * 37);
        if (c % 11 == 10) { n = rnd() % 300; for (size_t i = 0; i < n; i++) block[i] = (uint8_t)(rnd() % (c % 2 ? 256 : 20)); }
        else {
            n = compress(text, len, block);
            int damage = c % 3 == 2 ? 1 + (int)(rnd() % 3) : 0;
            for (int k = 0; k < damage && n; k++) {
                unsigned how = rnd() % 4;
                if (how == 0) block[rnd() % n] = (uint8_t)rnd();
                else if (how == 1) n = rnd() % n;
                else if (how == 2) block[rnd() % n] = 255;
                else block[rnd() % n] ^= (uint8_t)(1u << (rnd() % 8));
            }
        }
        // room for the output: enough, exactly enough, one too few, or little
        uint64_t whole = reference(block, n, want, sizeof want);
        uint64_t cap = whole == NO ? rnd() % 3000 : c % 4 == 0 ? whole : c % 4 == 1 ? whole + rnd() % 100 : c % 4 == 2 && whole ? whole - 1 : rnd() % (whole + 1);
        uint64_t expect = reference(block, n, want, cap);
        uint8_t *src = in + room - n, *dst = outs + room - cap;
        memcpy(src, block, n);
        memset(outs, 0xA5, room);
        uint64_t got = ode_lz4_decode(dst, cap, src, n);
        for (uint8_t *p = outs; p < dst; p++) if (*p != 0xA5) { printf("case %ld: a byte before the output was written\n", c); return 1; }
        if (sound && got != NO) {
            if (whole == NO || got != whole || got > cap || memcmp(dst, want, got)) { printf("case %ld: %llu bytes in: it gives %llu, which is not the count of what the block decodes to, or the bytes are not those\n", c, (unsigned long long)n, (unsigned long long)got); return 1; }
        }
        if (full) {
            if (got != expect) { printf("case %ld: %llu bytes in, room for %llu: the result is %llu, the reference says %llu\n", c, (unsigned long long)n, (unsigned long long)cap, (unsigned long long)got, (unsigned long long)expect); return 1; }
            if (got != NO && memcmp(dst, want, got)) { printf("case %ld: the %llu bytes are not the reference's\n", c, (unsigned long long)got); return 1; }
        }
        blocks += expect != NO; refused += expect == NO;
    }
    printf("%ld blocks decoded and %ld refused, %s\n", blocks, refused, full ? "as the reference decoder does" : sound ? "every count given and its bytes the reference decoder's" : "nothing written but the output");
    return 0;
}
