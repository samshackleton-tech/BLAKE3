// khash_bench: the speed of a hash function of six arguments (out, input, len, key, flags, plat), one thread:
// GiB a second, the best of 7 rounds, at eight lengths, on the AVX-512 kernels (plat 5) and the SSE4.1 one.
//
//     cc -O2 -DFN=b3l_hashr -DNAME='"hashr"' -o bench khash_bench.c OBJECTS...        (hash.ode's)
//     cc -O2 -DFN=b3l_hashf -DNAME='"hashf"' -o bench khash_bench.c OBJECTS...        (earlier/: levels.ode's)
//
// Not the library's benchmark (bench-hashes): a look at whether code written to be proved is slower than the
// earlier code on the same kernels. Timing is evidence only on a machine whose bench lock is held.
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
void FN(uint8_t *out, const uint8_t *input, uint64_t len, const uint8_t *key, uint64_t flags, uint64_t plat);
static double now(void) { struct timespec t; clock_gettime(CLOCK_MONOTONIC, &t); return t.tv_sec + t.tv_nsec * 1e-9; }
int main(void) {
    static const uint32_t IV[8] = {0x6A09E667, 0xBB67AE85, 0x3C6EF372, 0xA54FF53A, 0x510E527F, 0x9B05688C, 0x1F83D9AB, 0x5BE0CD19};
    static const size_t SIZES[] = {1024, 16384, 32768, 65536, 100000, 1 << 20, (1 << 20) + 1, 16 << 20};
    uint8_t out[32], key[32];
    memcpy(key, IV, 32);
    uint8_t *buf = aligned_alloc(64, 16 << 20);
    for (size_t i = 0; i < (16u << 20); i++) buf[i] = (uint8_t)(i * 251 + 7);
    for (int plat = 5; plat >= 0; plat -= 5)
        for (unsigned s = 0; s < sizeof SIZES / sizeof *SIZES; s++) {
            size_t len = SIZES[s];
            long reps = (long)((plat ? 400e6 : 60e6) / (len + 64)) + 1;
            double best = 1e9;
            for (int round = 0; round < 7; round++) {
                double t0 = now();
                for (long r = 0; r < reps; r++) FN(out, buf, len, key, 0, plat);
                double dt = (now() - t0) / reps;
                if (dt < best) best = dt;
            }
            printf("%-10s plat %d  %9zu bytes  %7.3f GiB/s  (%02x%02x%02x%02x)\n", NAME, plat, len, len / best / (1 << 30), out[0], out[1], out[2], out[3]);
        }
    return 0;
}
