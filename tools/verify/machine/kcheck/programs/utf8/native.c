// ode_utf8 on this machine's processor against a validator written here another way (the Unicode Standard's
// table 3-7 of well-formed byte sequences, as ranges of bytes), and, with -DICONV, against the C library's
// own converter: every one- and two-byte input, every three-byte one whose first byte is 0xE0 or more, and
// random ones: well-formed text of every length of sequence, the same with a byte changed or left out, and
// plain random bytes. The input ends where a page that faults begins (a read past it is a crash).
//   cc -O1 -o run native.c utf8.o && ./run [CASES]
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#ifdef ICONV
#include <iconv.h>
#endif
#define NO 0xFFFFFFFFFFFFFFFFull
uint64_t ode_utf8(const uint8_t *input, uint64_t n);
static uint64_t seed = 0x9E3779B97F4A7C15ull;
static uint64_t rnd(void) { seed ^= seed << 13; seed ^= seed >> 7; seed ^= seed << 17; return seed; }

// Table 3-7: first byte, then the range of the second, then 0x80..0xBF for each byte after.
static uint64_t table(const uint8_t *s, uint64_t n) {
    uint64_t i = 0, count = 0;
    while (i < n) {
        uint8_t b = s[i], lo = 0x80, hi = 0xBF; int more;
        if (b <= 0x7F) { i++; count++; continue; }
        else if (b >= 0xC2 && b <= 0xDF) more = 1;
        else if (b == 0xE0) { more = 2; lo = 0xA0; }
        else if (b >= 0xE1 && b <= 0xEC) more = 2;
        else if (b == 0xED) { more = 2; hi = 0x9F; }
        else if (b >= 0xEE && b <= 0xEF) more = 2;
        else if (b == 0xF0) { more = 3; lo = 0x90; }
        else if (b >= 0xF1 && b <= 0xF3) more = 3;
        else if (b == 0xF4) { more = 3; hi = 0x8F; }
        else return NO;
        if (n - i <= (uint64_t)more) return NO;
        if (s[i + 1] < lo || s[i + 1] > hi) return NO;
        for (int k = 2; k <= more; k++) if (s[i + k] < 0x80 || s[i + k] > 0xBF) return NO;
        i += more + 1; count++;
    }
    return count;
}

static size_t put(uint8_t *out, uint32_t p) {
    if (p < 0x80) { out[0] = p; return 1; }
    if (p < 0x800) { out[0] = 0xC0 | p >> 6; out[1] = 0x80 | (p & 63); return 2; }
    if (p < 0x10000) { out[0] = 0xE0 | p >> 12; out[1] = 0x80 | (p >> 6 & 63); out[2] = 0x80 | (p & 63); return 3; }
    out[0] = 0xF0 | p >> 18; out[1] = 0x80 | (p >> 12 & 63); out[2] = 0x80 | (p >> 6 & 63); out[3] = 0x80 | (p & 63); return 4;
}

static long done, good;
static int one(const uint8_t *s, uint64_t n, const char *what) {
    uint64_t want = table(s, n), got = ode_utf8(s, n);
    if (got != want) { printf("%s, %llu bytes (%02x %02x %02x ..): %llu, the table says %llu\n", what, (unsigned long long)n, n > 0 ? s[0] : 0, n > 1 ? s[1] : 0, n > 2 ? s[2] : 0, (unsigned long long)got, (unsigned long long)want); return 1; }
#ifdef ICONV
    static iconv_t cd; static int open; static char sink[1 << 19];
    if (!open) { cd = iconv_open("UTF-32LE", "UTF-8"); open = 1; }
    char *in = (char *)s, *out = sink; size_t inleft = n, outleft = sizeof sink;
    iconv(cd, 0, 0, 0, 0);
    size_t r = iconv(cd, &in, &inleft, &out, &outleft);
    uint64_t lib = (r == (size_t)-1 || inleft) ? NO : (uint64_t)(out - sink) / 4;
    if (lib != got) { printf("%s, %llu bytes: %llu, the C library's converter says %llu\n", what, (unsigned long long)n, (unsigned long long)got, (unsigned long long)lib); return 1; }
#endif
    done++; good += got != NO;
    return 0;
}

int main(int argc, char **argv) {
    long cases = argc > 1 ? atol(argv[1]) : 20000;
    size_t room = 1 << 16;
    uint8_t *x = mmap(0, room + 4096, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
    if (x == MAP_FAILED || mprotect(x + room, 4096, PROT_NONE)) return 2;
    uint8_t *end = x + room;
    if (one(end, 0, "nothing")) return 1;
    for (int a = 0; a < 256; a++) {
        end[-1] = a; if (one(end - 1, 1, "one byte")) return 1;
        for (int b = 0; b < 256; b++) {
            end[-2] = a; end[-1] = b; if (one(end - 2, 2, "two bytes")) return 1;
            if (a < 0xE0) continue;
            for (int c = 0; c < 256; c++) { end[-3] = a; end[-2] = b; end[-1] = c; if (one(end - 3, 3, "three bytes")) return 1; }
            if (a < 0xF0) continue;
            for (int c = 0x70; c < 0xD0; c += 0x0F) for (int d = 0x70; d < 0xD0; d += 0x0F) { end[-4] = a; end[-3] = b; end[-2] = c; end[-1] = d; if (one(end - 4, 4, "four bytes")) return 1; }
        }
    }
    static uint8_t text[1 << 15];
    for (long c = 0; c < cases; c++) {
        size_t n = 0, points = rnd() % 200;
        int kind = c % 4;
        if (kind == 3) { n = rnd() % 64; for (size_t i = 0; i < n; i++) text[i] = (uint8_t)rnd(); }
        else {
            for (size_t k = 0; k < points; k++) {
                uint32_t p;
                switch (rnd() % 6) { case 0: p = rnd() % 0x80; break; case 1: p = 0x80 + rnd() % 0x780; break; case 2: p = 0x800 + rnd() % 0xD000; break;
                                     case 3: p = 0xE000 + rnd() % 0x2000; break; case 4: p = 0x10000 + rnd() % 0x100000; break; default: p = (uint32_t[]){0x7F, 0x80, 0x7FF, 0x800, 0xD7FF, 0xE000, 0xFFFF, 0x10000, 0x10FFFF}[rnd() % 9]; }
                n += put(text + n, p);
            }
            if (kind == 1 && n) text[rnd() % n] = (uint8_t)rnd();
            if (kind == 2 && n) { size_t k = rnd() % n; memmove(text + k, text + k + 1, n - k - 1); n--; }
        }
        memcpy(end - n, text, n);
        if (one(end - n, n, kind == 0 ? "well-formed text" : kind == 1 ? "text with a byte changed" : kind == 2 ? "text with a byte left out" : "random bytes")) return 1;
    }
    printf("%ld inputs as the table's validator%s: %ld well-formed, %ld not\n", done,
#ifdef ICONV
           " and the C library's converter",
#else
           "",
#endif
           good, done - good);
    return 0;
}
