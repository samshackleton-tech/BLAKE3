// ode_lz4_pack on this machine's processor: what it writes is decoded by a decoder written here (and by
// ode_lz4_decode, if that is linked: -DBOTH; and by the reference LZ4_decompress_safe: -DLZ4), and must be
// the input.
//
//   cc -O1 -o run native_pack.c lz4_pack.o && ./run CASES sound|full     (full: and NO only where the room is less than n + n/255 + 16)
//   cc -O1 -DBOTH -DLZ4 -I LZ4/lib -o run native_pack.c lz4_pack.o lz4_decode.o LZ4/lib/lz4.c && ./run CASES sound
//
// The input ends where a page that faults begins, and so does the room; the bytes before the room are looked
// at afterwards. `sound`: what the contract says: a count it gives is of bytes that decode to the input.
// The inputs are runs and patterns that repeat at the distance tried, with other bytes among them, and bytes
// with no pattern; the distances 1 to 9 and some up to 65535. Exit 0: so in every case. The last line says
// how much smaller the blocks were.
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#define NO 0xFFFFFFFFFFFFFFFFull
uint64_t ode_lz4_pack(uint8_t *out, uint64_t cap, const uint8_t *input, uint64_t n, uint64_t d);
#ifdef LZ4
#include "lz4.h"
#endif
uint64_t ode_lz4_decode(uint8_t *out, uint64_t cap, const uint8_t *input, uint64_t n);
static uint64_t seed = 0x243F6A8885A308D3ull;
static uint64_t rnd(void) { seed ^= seed << 13; seed ^= seed >> 7; seed ^= seed << 17; return seed; }

static uint64_t reference(const uint8_t *src, uint64_t n, uint8_t *dst, uint64_t cap) {
    uint64_t i = 0, o = 0;
    for (;;) {
        if (i >= n) return NO;
        unsigned token = src[i++];
        uint64_t lit = token >> 4;
        if (lit == 15) { unsigned b; do { if (i >= n) return NO; b = src[i++]; lit += b; } while (b == 255); }
        if (lit > n - i || lit > cap - o) return NO;
        memcpy(dst + o, src + i, lit); o += lit; i += lit;
        if (i == n) return o;
        if (n - i < 2) return NO;
        uint64_t offset = src[i] | (uint64_t)src[i + 1] << 8; i += 2;
        if (offset == 0 || offset > o) return NO;
        uint64_t m = token & 15;
        if (m == 15) { unsigned b; do { if (i >= n) return NO; b = src[i++]; m += b; } while (b == 255); }
        m += 4;
        if (m > cap - o) return NO;
        for (uint64_t k = 0; k < m; k++, o++) dst[o] = dst[o - offset];
    }
}

int main(int argc, char **argv) {
    long cases = argc > 1 ? atol(argv[1]) : 3000, stored = 0, refused = 0;
    int full = argc > 2 && !strcmp(argv[2], "full");
    size_t room = 1 << 17;
    uint8_t *in = mmap(0, room + 4096, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
    uint8_t *outs = mmap(0, room + 4096, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
    static uint8_t back[1 << 17];
    if (in == MAP_FAILED || outs == MAP_FAILED || mprotect(in + room, 4096, PROT_NONE) || mprotect(outs + room, 4096, PROT_NONE)) return 2;
    uint64_t bytes_in = 0, bytes_out = 0;
    for (long c = 0; c < cases + 600; c++) {
        uint64_t n = c < 600 ? (uint64_t)c : rnd() % 60000;
        uint64_t d = c % 5 == 4 ? 1 + rnd() % 65535 : 1 + rnd() % 9;
        // bytes that repeat at distance d for a while, then do not, and so on
        uint64_t run = 0;
        for (uint64_t i = 0; i < n; i++) {
            if (run == 0) run = c % 7 == 6 ? 1 : 1 + rnd() % (c % 3 ? 40 : 400);
            in[room - n + i] = (i >= d && run > 1 && (c % 7 != 5)) ? in[room - n + i - d] : (uint8_t)rnd();
            run--;
        }
        uint64_t need = n + n / 255 + 16;
        uint64_t cap = c % 4 == 0 ? need : c % 4 == 1 ? need + rnd() % 50 : rnd() % (need + 1);
        uint8_t *src = in + room - n, *dst = outs + room - cap;
        memset(outs, 0xA5, room - cap);
        uint64_t got = ode_lz4_pack(dst, cap, src, n, d);
        for (uint8_t *q = outs; q < dst; q++) if (*q != 0xA5) { printf("case %ld: a byte before the room was written\n", c); return 1; }
        if (got != NO) {
            if (got > cap) { printf("case %ld: it says it wrote more than the room\n", c); return 1; }
            uint64_t back_n = reference(dst, got, back, n);
            if (back_n != n || memcmp(back, src, n)) { printf("case %ld: %llu bytes, distance %llu: what it wrote does not decode to them\n", c, (unsigned long long)n, (unsigned long long)d); return 1; }
#ifdef BOTH
            memset(back, 0, n);
            if (ode_lz4_decode(back, n, dst, got) != n || memcmp(back, src, n)) { printf("case %ld: ode_lz4_decode does not give the bytes back\n", c); return 1; }
#endif
#ifdef LZ4
            memset(back, 0, n);
            if (LZ4_decompress_safe((const char *)dst, (char *)back, (int)got, (int)n) != (int)n || memcmp(back, src, n)) { printf("case %ld: LZ4_decompress_safe does not give the bytes back\n", c); return 1; }
#endif
            stored++; bytes_in += n; bytes_out += got;
        } else {
            if (full && cap >= need) { printf("case %ld: %llu bytes, room for %llu: NO, where there is room for any block of them\n", c, (unsigned long long)n, (unsigned long long)cap); return 1; }
            refused++;
        }
    }
    printf("%ld blocks written that decode to their input (%llu bytes in %llu), %ld refused for want of room\n", stored, (unsigned long long)bytes_in, (unsigned long long)bytes_out, refused);
    return 0;
}
