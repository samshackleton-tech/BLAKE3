// ode_decimal on this machine's processor against a loop written here: every run of up to three bytes over
// the bytes around the digits, runs of digits of every length up to twelve, and random runs with one byte that
// is no digit; each run ends where a page that faults begins.
//   cc -O1 -o run native.c decimal.o && ./run [CASES]
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
uint64_t ode_decimal(const uint8_t *input, uint64_t n);
#define NO 0xFFFFFFFFFFFFFFFFull
static uint64_t seed = 0x2545F4914F6CDD1Dull;
static uint64_t rnd(void) { seed ^= seed << 13; seed ^= seed >> 7; seed ^= seed << 17; return seed; }
static uint64_t want(const uint8_t *p, size_t n) {
    if (n == 0 || n > 9) return NO;
    uint64_t v = 0;
    for (size_t i = 0; i < n; i++) { if (p[i] < '0' || p[i] > '9') return NO; v = 10 * v + (uint64_t)(p[i] - '0'); }
    return v;
}
static long done;
static int one(uint8_t *end, const uint8_t *bytes, size_t n) {
    uint8_t *p = end - n;
    memcpy(p, bytes, n);
    uint64_t got = ode_decimal(p, n), w = want(p, n);
    if (got != w) { printf("%zu bytes", n); for (size_t i = 0; i < n && i < 16; i++) printf(" %02x", p[i]); printf(": %llu, the loop here says %llu\n", (unsigned long long)got, (unsigned long long)w); return 1; }
    done++;
    return 0;
}
int main(int argc, char **argv) {
    long cases = argc > 1 ? atol(argv[1]) : 20000;
    size_t room = 1 << 12;
    uint8_t *x = mmap(0, room + 4096, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
    if (x == MAP_FAILED || mprotect(x + room, 4096, PROT_NONE)) return 2;
    uint8_t *end = x + room, b[64];
    static const uint8_t edge[] = {0, '/', '0', '1', '5', '9', ':', 'A', 0x7F, 0x80, 0xFF, ' ', '\n', '-', '+'};
    size_t e = sizeof edge;
    if (one(end, b, 0)) return 1;
    for (size_t i = 0; i < e; i++) { b[0] = edge[i]; if (one(end, b, 1)) return 1;
        for (size_t j = 0; j < e; j++) { b[1] = edge[j]; if (one(end, b, 2)) return 1;
            for (size_t k = 0; k < e; k++) { b[2] = edge[k]; if (one(end, b, 3)) return 1; } } }
    for (long c = 0; c < cases; c++) {
        size_t n = rnd() % 13;
        for (size_t i = 0; i < n; i++) b[i] = (uint8_t)('0' + rnd() % 10);
        if (c % 4 == 0) for (size_t i = 0; i < n; i++) b[i] = (c % 8) ? '9' : '0';          // the greatest and the least of a length
        if (c % 3 == 0 && n) b[rnd() % n] = (c % 2) ? (uint8_t)rnd() : edge[rnd() % e];     // one byte that may be no digit
        if (one(end, b, n)) return 1;
    }
    printf("%ld counts as the loop's\n", done);
    return 0;
}
