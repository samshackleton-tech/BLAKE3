// ode_adler32 on this machine's processor against zlib's adler32: every length from 0 to 6000 and random
// longer ones, the input ending where a page that faults begins (a read past it is a crash).
//   cc -O1 -o run native.c adler32.o -lz && ./run [CASES]
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <zlib.h>
#ifndef FN
#define FN ode_adler32          // -DFN=ode_adler32_blocks: the function that reduces once in 5552 bytes
#endif
uint64_t FN(const uint8_t *input, uint64_t len);
static uint64_t seed = 0x9E3779B97F4A7C15ull;
static uint64_t rnd(void) { seed ^= seed << 13; seed ^= seed >> 7; seed ^= seed << 17; return seed; }
int main(int argc, char **argv) {
    long cases = argc > 1 ? atol(argv[1]) : 2000, done = 0;
    size_t room = 1 << 21;
    uint8_t *base = mmap(0, room + 4096, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
    if (base == MAP_FAILED || mprotect(base + room, 4096, PROT_NONE)) return 2;
    for (long c = 0; c < 6001 + cases; c++) {
        // every length to 6000 (past the first block of 5552), then the three around each of the next 40 blocks' ends, then any
        size_t len = c <= 6000 ? (size_t)c : c <= 6120 ? 5552 * (2 + (c - 6001) / 3) - 1 + (c - 6001) % 3 : rnd() % room;
        uint8_t *p = base + room - len;
        int kind = c % 4;
        for (size_t i = 0; i < len; i++) p[i] = kind == 0 ? 0xFF : kind == 1 ? 0 : (uint8_t)rnd();
        uint64_t got = FN(p, len), want = adler32(1, p, (uInt)len);
        if (got != want) { printf("case %ld: %zu bytes: %llx, zlib says %llx\n", c, len, (unsigned long long)got, (unsigned long long)want); return 1; }
        done++;
    }
    printf("%ld checksums as zlib's\n", done);
    return 0;
}
