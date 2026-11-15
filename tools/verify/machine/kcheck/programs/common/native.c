// ode_common on this machine's processor against a loop written here: runs of every length up to 300 and
// random longer ones, alike up to a random place; each run ends where a page that faults begins.
//   cc -O1 -o run native.c common.o && ./run [CASES]
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
uint64_t ode_common(const uint8_t *a, const uint8_t *b, uint64_t n);
static uint64_t seed = 0x2545F4914F6CDD1Dull;
static uint64_t rnd(void) { seed ^= seed << 13; seed ^= seed >> 7; seed ^= seed << 17; return seed; }
int main(int argc, char **argv) {
    long cases = argc > 1 ? atol(argv[1]) : 20000, done = 0;
    size_t room = 1 << 16;
    uint8_t *x = mmap(0, room + 4096, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANONYMOUS, -1, 0), *y = mmap(0, room + 4096, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
    if (x == MAP_FAILED || y == MAP_FAILED || mprotect(x + room, 4096, PROT_NONE) || mprotect(y + room, 4096, PROT_NONE)) return 2;
    for (long c = 0; c < cases + 301; c++) {
        size_t n = c <= 300 ? (size_t)c : rnd() % room, same = n ? rnd() % (n + 1) : 0;
        uint8_t *a = x + room - n, *b = y + room - n;
        for (size_t i = 0; i < n; i++) { a[i] = (uint8_t)rnd(); b[i] = i < same ? a[i] : (uint8_t)(c % 3 ? rnd() : a[i] + 1); }
        size_t want = 0; while (want < n && a[want] == b[want]) want++;
        uint64_t got = ode_common(a, b, n);
        if (got != want) { printf("case %ld: %zu bytes: %llu, the loop here says %zu\n", c, n, (unsigned long long)got, want); return 1; }
        done++;
    }
    printf("%ld counts as the loop's\n", done);
    return 0;
}
