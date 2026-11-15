// ode_base64 on this machine's processor against an encoder written here another way (the alphabet as a
// table), and, with -DRESOLV (link -lresolv), against the C library's b64_ntop: every length from 0 to 600
// and random longer ones. The input ends where a page that faults begins; so does the room for the letters,
// which is exactly what the contract asks for, and the bytes before it are looked at afterwards.
//   cc -O1 -o run native.c base64.o && ./run [CASES]
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#ifdef RESOLV
#include <netinet/in.h>
#include <resolv.h>
#endif
uint64_t ode_base64(uint8_t *out, uint64_t cap, const uint8_t *input, uint64_t n);
static uint64_t seed = 0x9E3779B97F4A7C15ull;
static uint64_t rnd(void) { seed ^= seed << 13; seed ^= seed >> 7; seed ^= seed << 17; return seed; }
static const char T[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
static size_t table(uint8_t *out, const uint8_t *s, size_t n) {
    size_t o = 0;
    for (size_t i = 0; i < n; i += 3) {
        uint32_t w = (uint32_t)s[i] << 16 | (i + 1 < n ? s[i + 1] << 8 : 0) | (i + 2 < n ? s[i + 2] : 0);
        out[o++] = T[w >> 18]; out[o++] = T[w >> 12 & 63];
        out[o++] = i + 1 < n ? T[w >> 6 & 63] : '='; out[o++] = i + 2 < n ? T[w & 63] : '=';
    }
    return o;
}
int main(int argc, char **argv) {
    long cases = argc > 1 ? atol(argv[1]) : 5000, done = 0;
    size_t room = 1 << 17;
    uint8_t *in = mmap(0, room + 4096, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANONYMOUS, -1, 0), *outs = mmap(0, room + 4096, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
    static uint8_t want[1 << 17]; static char lib[(1 << 17) + 8];
    if (in == MAP_FAILED || outs == MAP_FAILED || mprotect(in + room, 4096, PROT_NONE) || mprotect(outs + room, 4096, PROT_NONE)) return 2;
    for (long c = 0; c < cases + 601; c++) {
        size_t n = c <= 600 ? (size_t)c : rnd() % 60000, cap = 4 * ((n + 2) / 3);
        uint8_t *src = in + room - n, *dst = outs + room - cap;
        for (size_t i = 0; i < n; i++) src[i] = c % 5 == 4 ? (uint8_t)(0xFB + rnd() % 5) : (uint8_t)rnd();
        memset(outs, 0xA5, room - cap);
        uint64_t got = ode_base64(dst, cap, src, n);
        size_t w = table(want, src, n);
        for (uint8_t *q = outs; q < dst; q++) if (*q != 0xA5) { printf("case %ld: a byte before the room was written\n", c); return 1; }
        if (got != w || w != cap || memcmp(dst, want, w)) { printf("case %ld: %zu bytes: not the table's letters (%llu of them, the table gives %zu)\n", c, n, (unsigned long long)got, w); return 1; }
#ifdef RESOLV
        int l = b64_ntop(src, n, lib, sizeof lib);
        if (l < 0 || (size_t)l != w || memcmp(dst, lib, w)) { printf("case %ld: %zu bytes: not the C library's letters\n", c, n); return 1; }
#endif
        done++;
    }
    printf("%ld inputs written as the table's encoder%s writes them\n", done,
#ifdef RESOLV
           " and the C library's b64_ntop"
#else
           ""
#endif
    );
    return 0;
}
