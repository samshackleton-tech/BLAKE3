// ode_varint on this machine's processor against LEB128 written here: numbers of every length in bits, and
// random ones; the ten bytes of room end where a page that faults begins, and the bytes before are looked at.
//   cc -O1 -o run native.c varint.o && ./run [CASES]
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
uint64_t ode_varint(uint8_t *out, uint64_t v);
static uint64_t seed = 0x9E3779B97F4A7C15ull;
static uint64_t rnd(void) { seed ^= seed << 13; seed ^= seed >> 7; seed ^= seed << 17; return seed; }
int main(int argc, char **argv) {
    long cases = argc > 1 ? atol(argv[1]) : 100000, done = 0;
    uint8_t *page = mmap(0, 8192, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
    if (page == MAP_FAILED || mprotect(page + 4096, 4096, PROT_NONE)) return 2;
    uint8_t *out = page + 4096 - 10;
    for (long c = 0; c < cases + 200; c++) {
        uint64_t v = c < 65 ? (c ? 1ull << (c - 1) : 0) : c < 130 ? (1ull << (c - 65)) - 1 : c < 200 ? (uint64_t)-1 - (uint64_t)(c - 130) : rnd() >> (rnd() % 64);
        uint8_t want[10]; size_t n = 0;
        for (uint64_t x = v;; x >>= 7) { if (x < 128) { want[n++] = (uint8_t)x; break; } want[n++] = (uint8_t)(128 | (x & 127)); }
        memset(page, 0xA5, 4096);
        uint64_t got = ode_varint(out, v);
        for (uint8_t *p = page; p < out; p++) if (*p != 0xA5) { printf("case %ld: a byte before the output was written\n", c); return 1; }
        if (got != n || memcmp(out, want, n)) { printf("case %ld: %llu: not its varint\n", c, (unsigned long long)v); return 1; }
        for (size_t k = n; k < 10; k++) if (out[k] != 0xA5) { printf("case %ld: a byte after the varint was written\n", c); return 1; }
        done++;
    }
    printf("%ld varints as LEB128's\n", done);
    return 0;
}
