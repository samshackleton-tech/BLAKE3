// ode_inet on this machine's processor against the Internet checksum as RFC 1071's own C code computes it
// (16 bits at a time, the carries folded in while there are any): every length from 0 to 2,000 and random
// longer ones; random bytes, all 0xFF, all zero, and bytes that carry often. The input ends where a page
// that faults begins (a read past it is a crash). And for 2^49 bytes and more it must say NO having read
// nothing: it is given the address of the page that faults.
//   cc -O1 -o run native.c inet.o && ./run [CASES]
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
uint64_t ode_inet(const uint8_t *input, uint64_t n);
static uint64_t seed = 0x2545F4914F6CDD1Dull;
static uint64_t rnd(void) { seed ^= seed << 13; seed ^= seed >> 7; seed ^= seed << 17; return seed; }
static uint64_t rfc1071(const uint8_t *addr, size_t count) {
    unsigned long sum = 0;
    while (count > 1) { sum += (unsigned long)addr[0] << 8 | addr[1]; addr += 2; count -= 2; }
    if (count > 0) sum += (unsigned long)addr[0] << 8;
    while (sum >> 16) sum = (sum & 0xffff) + (sum >> 16);
    return ~sum & 0xffff;
}
int main(int argc, char **argv) {
    long cases = argc > 1 ? atol(argv[1]) : 20000, done = 0;
    size_t room = 1 << 20;
    uint8_t *x = mmap(0, room + 4096, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
    if (x == MAP_FAILED || mprotect(x + room, 4096, PROT_NONE)) return 2;
    for (long c = 0; c < cases + 2001; c++) {
        size_t n = c <= 2000 ? (size_t)c : rnd() % (c % 50 ? 70000 : room);
        uint8_t *s = x + room - n;
        int kind = c % 5;
        for (size_t i = 0; i < n; i++) s[i] = kind == 1 ? 0xFF : kind == 2 ? 0 : kind == 3 ? (uint8_t)(0xF0 | rnd()) : (uint8_t)rnd();
        uint64_t want = rfc1071(s, n), got = ode_inet(s, n);
        if (got != want) { printf("case %ld: %zu bytes: %llx, RFC 1071's code says %llx\n", c, n, (unsigned long long)got, (unsigned long long)want); return 1; }
        done++;
    }
    uint64_t big[] = {1ull << 49, (1ull << 49) + 1, 1ull << 50, 1ull << 63, ~0ull};
    for (int k = 0; k < 5; k++) if (ode_inet(x + room, big[k]) != ~0ull) { printf("%llu bytes: not NO\n", (unsigned long long)big[k]); return 1; }
    printf("%ld checksums as RFC 1071's code gives them; NO for 2^49 bytes and more, with nothing read\n", done);
    return 0;
}
