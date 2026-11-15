// The speed of the two programs of this folder beside others' code for the same thing, one thread.
//
//   cc -O2 -I LZ4/lib -o bench bench.c adler32/odeadler32.o lz4/odelz4.o LZ4/lib/lz4.c && ./bench
//
// (The two .o files are the files shipped: what is timed is what check_file.py checked.)
// Adler-32 of 1 MiB: ode_adler32 (a remainder at every byte); ode_adler32_blocks (the sums put off for 5552
// bytes, as the usual code does); ode_adler32_blocks4 (the same, four bytes a turn); and the usual C (the
// sums put off, one remainder a block), compiled here. LZ4: a block made by the reference compressor of text that repeats (this file's own bytes, many times,
// changed a little); ode_lz4_decode; and the reference decoder (LZ4_decompress_safe of lz4.c). The best of
// 9 passes of each, in bytes decoded (or summed) a second. The two of each pair must agree first.
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include "lz4.h"
uint64_t ode_adler32(const uint8_t *input, uint64_t len);
uint64_t ode_adler32_blocks(const uint8_t *input, uint64_t len);
uint64_t ode_adler32_blocks4(const uint8_t *input, uint64_t len);
uint64_t ode_lz4_decode(uint8_t *out, uint64_t cap, const uint8_t *input, uint64_t n);

static uint32_t c_adler32(const uint8_t *p, size_t len) {
    uint32_t a = 1, b = 0;
    while (len) {
        size_t k = len < 5552 ? len : 5552;
        len -= k;
        while (k--) { a += *p++; b += a; }
        a %= 65521; b %= 65521;
    }
    return b << 16 | a;
}

static double now(void) { struct timespec t; clock_gettime(CLOCK_MONOTONIC, &t); return t.tv_sec + t.tv_nsec * 1e-9; }
#define BEST(what, bytes, code) do { double best = 1e9; for (int pass = 0; pass < 9; pass++) { double t0 = now(); for (int r = 0; r < reps; r++) { code; } double t = (now() - t0) / reps; if (t < best) best = t; } \
    printf("%-34s %8.1f MB/s\n", what, (bytes) / best / 1e6); } while (0)

int main(void) {
    static uint8_t data[1 << 20], text[1 << 20], block[(1 << 20) + 5000], out[1 << 20];
    uint64_t seed = 88172645463325252ull, sink = 0;
    for (size_t i = 0; i < sizeof data; i++) { seed ^= seed << 13; seed ^= seed >> 7; seed ^= seed << 17; data[i] = (uint8_t)seed; }
    if (ode_adler32(data, sizeof data) != c_adler32(data, sizeof data) || ode_adler32_blocks(data, sizeof data) != c_adler32(data, sizeof data) || ode_adler32_blocks4(data, sizeof data) != c_adler32(data, sizeof data)) { printf("the Adler-32s differ\n"); return 1; }
    int reps = 20;
    BEST("adler32, ode_adler32", sizeof data, sink += ode_adler32(data, sizeof data));
    BEST("adler32, ode_adler32_blocks", sizeof data, sink += ode_adler32_blocks(data, sizeof data));
    BEST("adler32, ode_adler32_blocks4", sizeof data, sink += ode_adler32_blocks4(data, sizeof data));
    BEST("adler32, C (sums put off)", sizeof data, sink += c_adler32(data, sizeof data));
    // text that repeats: this program's source, over and over, a byte in every 97 changed
    FILE *f = fopen(__FILE__, "rb");
    size_t n = f ? fread(text, 1, 6000, f) : 0;
    if (n < 1000) { printf("no source to make text of\n"); return 1; }
    for (size_t i = n; i < sizeof text; i++) { seed ^= seed << 13; seed ^= seed >> 7; seed ^= seed << 17; text[i] = i % 97 ? text[i - n] : (uint8_t)seed; }
    int size = LZ4_compress_default((const char *)text, (char *)block, sizeof text, sizeof block);
    if (size <= 0) { printf("the reference compressor gave no block\n"); return 1; }
    uint64_t got = ode_lz4_decode(out, sizeof out, block, (uint64_t)size);
    if (got != sizeof text || memcmp(out, text, sizeof text)) { printf("ode_lz4_decode does not give the text back\n"); return 1; }
    if (LZ4_decompress_safe((const char *)block, (char *)out, size, sizeof out) != (int)sizeof text || memcmp(out, text, sizeof text)) { printf("the reference decoder does not give the text back\n"); return 1; }
    printf("lz4: %zu bytes of text in a block of %d\n", sizeof text, size);
    reps = 10;
    BEST("lz4 decode, ode_lz4_decode", sizeof text, sink += ode_lz4_decode(out, sizeof out, block, (uint64_t)size));
    BEST("lz4 decode, LZ4_decompress_safe", sizeof text, sink += (uint64_t)LZ4_decompress_safe((const char *)block, (char *)out, size, sizeof out));
    return sink == 42;
}
