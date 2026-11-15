// ode_unframe on this machine's processor, with the two functions it calls (ode_lz4_decode,
// ode_adler32_blocks4), against a frame opened another way: an LZ4 block decoder written here and zlib's
// adler32.
//
//   cc -O1 -o run native.c unframe.o lz4_decode.o adler32_blocks4.o -lz && ./run CASES
//
// The input ends where a page that faults begins, and so does the room for the output; the bytes before the
// output are looked at afterwards. In every case: the function gives a count just where the frame holds
// something (its block decodes within the room, and its last four bytes are the Adler-32 of that, the
// highest first), the count is of those bytes, and they are at out; else it gives NO. Exit 0: so; 1: not so.
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#define compress zlib_compress          // (zlib has a function of this name; the one here makes a block)
#include <zlib.h>
#undef compress
#define NO 0xFFFFFFFFFFFFFFFFull
uint64_t ode_unframe(uint8_t *out, uint64_t cap, const uint8_t *input, uint64_t n);

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
    size_t room = 1 << 16;
    uint8_t *in = mmap(0, room + 4096, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
    uint8_t *outs = mmap(0, room + 4096, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
    static uint8_t text[20000], frame[40004], want[70000];
    if (in == MAP_FAILED || outs == MAP_FAILED || mprotect(in + room, 4096, PROT_NONE) || mprotect(outs + room, 4096, PROT_NONE)) return 2;
    long held = 0, nothing = 0, sums = 0;
    for (long c = 0; c < cases; c++) {
        // some bytes that repeat, their block, the sum after it; then perhaps damage: to the block, to the sum, to the length
        size_t len = c < 40 ? (size_t)c : rnd() % (c % 7 ? 600 : 20000), n;
        unsigned alphabet = 1 + rnd() % (c % 3 ? 4 : 250);
        for (size_t i = 0; i < len; i++) text[i] = (uint8_t)(rnd() % alphabet * 37);
        n = compress(text, len, frame);
        uint32_t sum = (uint32_t)adler32(adler32(0, 0, 0), text, (unsigned)len);
        frame[n] = (uint8_t)(sum >> 24); frame[n + 1] = (uint8_t)(sum >> 16); frame[n + 2] = (uint8_t)(sum >> 8); frame[n + 3] = (uint8_t)sum;
        n += 4;
        unsigned kind = c % 9;
        if (kind == 3) frame[rnd() % n] ^= (uint8_t)(1u << (rnd() % 8));                 // one bit, anywhere
        else if (kind == 4) frame[n - 1 - rnd() % 4] = (uint8_t)rnd();                   // a byte of the sum
        else if (kind == 5) n = rnd() % (n + 1);                                         // cut short (to nothing, to under four bytes)
        else if (kind == 6) { uint8_t t = frame[n - 4]; frame[n - 4] = frame[n - 1]; frame[n - 1] = t; t = frame[n - 3]; frame[n - 3] = frame[n - 2]; frame[n - 2] = t; }   // the sum the lowest first
        else if (kind == 7) { n = rnd() % 300; for (size_t i = 0; i < n; i++) frame[i] = (uint8_t)(rnd() % (c % 2 ? 256 : 20)); }
        // room for the output: enough, exactly enough, one too few, or little
        uint64_t whole = n < 4 ? NO : reference(frame, n - 4, want, sizeof want);
        uint64_t cap = whole == NO ? rnd() % 3000 : c % 4 == 0 ? whole : c % 4 == 1 ? whole + rnd() % 100 : c % 4 == 2 && whole ? whole - 1 : rnd() % (whole + 1);
        uint64_t expect = n < 4 ? NO : reference(frame, n - 4, want, cap);
        if (expect != NO) {
            uint32_t said = (uint32_t)frame[n - 4] << 24 | (uint32_t)frame[n - 3] << 16 | (uint32_t)frame[n - 2] << 8 | frame[n - 1];
            if ((uint32_t)adler32(adler32(0, 0, 0), want, (unsigned)expect) != said) { expect = NO; sums++; }
        }
        uint8_t *src = in + room - n, *dst = outs + room - cap;
        memcpy(src, frame, n);
        memset(outs, 0xA5, room);
        uint64_t got = ode_unframe(dst, cap, src, n);
        for (uint8_t *p = outs; p < dst; p++) if (*p != 0xA5) { printf("case %ld: a byte before the output was written\n", c); return 1; }
        if (got != expect) { printf("case %ld: %llu bytes in, room for %llu: the result is %llu, the reference says %llu\n", c, (unsigned long long)n, (unsigned long long)cap, (unsigned long long)got, (unsigned long long)expect); return 1; }
        if (got != NO && memcmp(dst, want, got)) { printf("case %ld: the %llu bytes are not the reference's\n", c, (unsigned long long)got); return 1; }
        held += expect != NO; nothing += expect == NO;
    }
    printf("%ld frames opened and %ld refused (%ld of them for the sum alone), as the reference does\n", held, nothing, sums);
    return 0;
}
