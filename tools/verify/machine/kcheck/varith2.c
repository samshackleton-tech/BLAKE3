/* varith2: a second verifier of the arithmetic's proofs, written apart from the first (varith.py), in another
 * language, sharing no line with it.
 *
 *     cc -O2 -o varith2 varith2.c -lz
 *     ./varith2 b3hashr.o programs/lz4/odelz4.o ...
 *     ./varith2 --each FILE        and a letter for each proof, in the file's order (y, n, ?): for the tests
 *
 * It reads the proofs a file carries (the section .ode.proof of an ELF file: `file NAME.arith.z LENGTH` and
 * then LENGTH bytes, zlib's, of JSON: {"names": [...], "proofs": [[starts, steps], ...]}) and of each proof
 * says whether it adds up: from the rows it starts from, each step (i, a, j, b), a and b above zero, makes
 *
 *     a * row[i] + b * row[j],  divided by the greatest number that divides all its multiples,
 *                               its plain number rounded down
 *
 * and the last row has no name left and a number below zero. A row is: multiples of names, and a plain number,
 * said to be >= 0. (Why the rule is sound: the names stand for whole numbers, so the sum of the multiples
 * divided by what divides them all is a whole number, not below minus the plain number over that divisor,
 * hence not below that rounded up.)
 *
 * What it does NOT say: that the rows a proof starts from are rows the verifier knew where it used the proof.
 * That is the first verifier's (varith.py's `refutes`: each start must be among the rows given), and it
 * depends on the function and the path. This one says of every proof in the file: these rows cannot all
 * hold. So a mistake in the first one's adding up, dividing or rounding would be seen here, by code that
 * shares nothing with it but the form of the file.
 *
 * Numbers: whole numbers of up to 320 bits and a sign (the largest in the shipped files is 128 bits, before
 * a division). A number that does not fit is said, and the proof counted as not judged, never as adding up.
 */
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <zlib.h>

/* ---- whole numbers */
#define LIMBS 5
typedef struct { uint64_t m[LIMBS]; int neg; } num;            /* magnitude, least limb first; neg only if not zero */
static int overflowed;

static int is_zero(const num *a) { for (int i = 0; i < LIMBS; i++) if (a->m[i]) return 0; return 1; }
static int cmp_mag(const num *a, const num *b) {
    for (int i = LIMBS - 1; i >= 0; i--) if (a->m[i] != b->m[i]) return a->m[i] < b->m[i] ? -1 : 1;
    return 0;
}
static void add_mag(num *r, const num *a, const num *b) {
    unsigned __int128 c = 0;
    for (int i = 0; i < LIMBS; i++) { c += (unsigned __int128)a->m[i] + b->m[i]; r->m[i] = (uint64_t)c; c >>= 64; }
    if (c) overflowed = 1;
}
static void sub_mag(num *r, const num *a, const num *b) {      /* a >= b */
    unsigned __int128 borrow = 0;
    for (int i = 0; i < LIMBS; i++) {
        unsigned __int128 x = (unsigned __int128)a->m[i] - b->m[i] - borrow;
        r->m[i] = (uint64_t)x; borrow = (x >> 64) & 1;
    }
}
static void add(num *r, const num *a, const num *b) {
    num t;
    if (a->neg == b->neg) { add_mag(&t, a, b); t.neg = a->neg; }
    else if (cmp_mag(a, b) >= 0) { sub_mag(&t, a, b); t.neg = a->neg; }
    else { sub_mag(&t, b, a); t.neg = b->neg; }
    if (is_zero(&t)) t.neg = 0;
    *r = t;
}
static void mul(num *r, const num *a, const num *b) {
    uint64_t w[2 * LIMBS] = {0};
    for (int i = 0; i < LIMBS; i++) {
        unsigned __int128 c = 0;
        for (int j = 0; j < LIMBS; j++) {
            c += (unsigned __int128)a->m[i] * b->m[j] + w[i + j];
            w[i + j] = (uint64_t)c; c >>= 64;
        }
        w[i + LIMBS] = (uint64_t)c;
    }
    for (int i = LIMBS; i < 2 * LIMBS; i++) if (w[i]) overflowed = 1;
    num t; memcpy(t.m, w, sizeof t.m); t.neg = (a->neg != b->neg) && !is_zero(&t);
    *r = t;
}
/* magnitudes: q = a / b, rem = a % b (b not zero), by shifting and taking away */
static void divmod_mag(num *q, num *rem, const num *a, const num *b) {
    num qq = {{0}, 0}, r = {{0}, 0};
    for (int bit = 64 * LIMBS - 1; bit >= 0; bit--) {
        uint64_t carry = (a->m[bit / 64] >> (bit % 64)) & 1;
        for (int i = 0; i < LIMBS; i++) { uint64_t top = r.m[i] >> 63; r.m[i] = (r.m[i] << 1) | carry; carry = top; }
        if (cmp_mag(&r, b) >= 0) { sub_mag(&r, &r, b); qq.m[bit / 64] |= (uint64_t)1 << (bit % 64); }
    }
    *q = qq; *rem = r;
}
static void gcd_mag(num *g, const num *a, const num *b) {
    num x = *a, y = *b, q, r; x.neg = y.neg = 0;
    while (!is_zero(&y)) { divmod_mag(&q, &r, &x, &y); x = y; y = r; }
    *g = x;
}
/* a / g rounded down (toward minus infinity), g above zero */
static void floor_div(num *r, const num *a, const num *g) {
    num q, rem, one = {{1}, 0};
    divmod_mag(&q, &rem, a, g);
    q.neg = 0;
    if (a->neg) { if (!is_zero(&rem)) add_mag(&q, &q, &one); q.neg = !is_zero(&q); }
    *r = q;
}

/* ---- the JSON of a table, read as far as this needs */
typedef struct { const char *p, *end; int bad; } cur;
static void ws(cur *c) { while (c->p < c->end && (*c->p == ' ' || *c->p == '\n' || *c->p == '\t' || *c->p == '\r')) c->p++; }
static int take(cur *c, char ch) { ws(c); if (c->p < c->end && *c->p == ch) { c->p++; return 1; } return 0; }
static void need(cur *c, char ch) { if (!take(c, ch)) c->bad = 1; }
static void string(cur *c) {                                   /* its content is not needed: names are told apart by their place */
    need(c, '"');
    while (c->p < c->end && *c->p != '"') { if (*c->p == '\\') c->p++; c->p++; }
    need(c, '"');
}
static void number(cur *c, num *r) {
    num ten = {{10}, 0}, d = {{0}, 0}, t = {{0}, 0};
    int neg = 0, digits = 0;
    ws(c);
    if (c->p < c->end && *c->p == '-') { neg = 1; c->p++; }
    while (c->p < c->end && *c->p >= '0' && *c->p <= '9') {
        d.m[0] = (uint64_t)(*c->p - '0'); mul(&t, &t, &ten); add(&t, &t, &d); c->p++; digits++;
    }
    if (!digits || (c->p < c->end && (*c->p == '.' || *c->p == 'e' || *c->p == 'E'))) c->bad = 1;   /* whole numbers only */
    t.neg = neg && !is_zero(&t);
    *r = t;
}
static long small(cur *c) {                                    /* a place in a list: a small number not below zero, or -1 */
    num n; number(c, &n);
    if (n.neg || n.m[1] || n.m[2] || n.m[3] || n.m[4] || n.m[0] > 1000000) return -1;
    return (long)n.m[0];
}

#define ROWS 4096
typedef struct { num *c; num k; } row;                         /* c[name], and the plain number */

static long proofs_ok, proofs_bad, proofs_big;
static int each;                                               /* --each: a letter a proof, in the file's order: y adds up, n does not, ? not judged */

/* one proof: [starts, steps]. names: how many names the table has. */
static void proof(cur *c, long names) {
    static row rows[ROWS];
    long n = 0; int ok = 1;
    overflowed = 0;
    need(c, '['); need(c, '[');
    if (!take(c, ']')) { do {                                  /* a row it starts from: [[name, multiple, name, multiple, ...], number] */
        if (n >= ROWS) { c->bad = 1; break; }
        rows[n].c = calloc((size_t)names, sizeof(num));
        need(c, '['); need(c, '[');
        if (!take(c, ']')) {
            do {
                long name = small(c); need(c, ',');
                num v; number(c, &v);
                if (name < 0 || name >= names) ok = 0;
                else add(&rows[n].c[name], &rows[n].c[name], &v);
            } while (take(c, ',') && !c->bad);
            need(c, ']');
        }
        need(c, ','); number(c, &rows[n].k); need(c, ']');
        n++;
    } while (take(c, ',') && !c->bad); need(c, ']'); }
    need(c, ','); need(c, '[');
    if (!take(c, ']')) { do {                                  /* a step: [i, a, j, b] */
        need(c, '[');
        long i = small(c); need(c, ','); num a; number(c, &a); need(c, ',');
        long j = small(c); need(c, ','); num b; number(c, &b); need(c, ']');
        if (c->bad) break;
        if (n >= ROWS) { c->bad = 1; break; }
        rows[n].c = calloc((size_t)names, sizeof(num));
        if (i < 0 || j < 0 || i >= n || j >= n || a.neg || b.neg || is_zero(&a) || is_zero(&b)) { ok = 0; memset(&rows[n].k, 0, sizeof(num)); n++; continue; }   /* (continue: to the while's test) */
        num g = {{0}, 0}, t, u;
        for (long x = 0; x < names; x++) {
            mul(&t, &rows[i].c[x], &a); mul(&u, &rows[j].c[x], &b); add(&rows[n].c[x], &t, &u);
            if (!is_zero(&rows[n].c[x])) gcd_mag(&g, &g, &rows[n].c[x]);
        }
        mul(&t, &rows[i].k, &a); mul(&u, &rows[j].k, &b); add(&rows[n].k, &t, &u);
        num one = {{1}, 0};
        if (!is_zero(&g) && cmp_mag(&g, &one) > 0) {
            for (long x = 0; x < names; x++) if (!is_zero(&rows[n].c[x])) {
                num q, rem; divmod_mag(&q, &rem, &rows[n].c[x], &g);
                if (!is_zero(&rem)) ok = 0;                    /* (cannot be: g divides each) */
                q.neg = rows[n].c[x].neg; rows[n].c[x] = q;
            }
            floor_div(&rows[n].k, &rows[n].k, &g);
        }
        n++;
    } while (take(c, ',') && !c->bad); need(c, ']'); }
    need(c, ']');
    if (n == 0) ok = 0;
    else {
        for (long x = 0; x < names; x++) if (!is_zero(&rows[n - 1].c[x])) ok = 0;      /* a name is left */
        if (!rows[n - 1].k.neg) ok = 0;                                                /* and the number must be below zero */
    }
    for (long x = 0; x < n; x++) free(rows[x].c);
    if (c->bad) return;
    if (overflowed) proofs_big++; else if (ok) proofs_ok++; else proofs_bad++;
    if (each) putchar(overflowed ? '?' : ok ? 'y' : 'n');
}

static int table(const unsigned char *z, size_t zlen, const char *what) {
    uLongf cap = 1 << 20; unsigned char *out = NULL; int rc;
    for (;;) {                                                 /* its length is not said: more room until it fits */
        out = realloc(out, cap); uLongf got = cap;
        rc = uncompress(out, &got, z, zlen);
        if (rc == Z_BUF_ERROR && cap < ((uLongf)1 << 30)) { cap *= 4; continue; }
        cap = got; break;
    }
    if (rc != Z_OK) { printf("  %s: cannot be read (zlib)\n", what); free(out); return 1; }
    cur c = { (const char *)out, (const char *)out + cap, 0 };
    long names = -1; int seen_proofs = 0;
    long before_ok = proofs_ok, before_bad = proofs_bad, before_big = proofs_big;
    /* two passes over the keys, so that the names are counted before the proofs whatever the order */
    for (int pass = 0; pass < 2 && !c.bad; pass++) {
        c.p = (const char *)out;
        need(&c, '{');
        do {
            ws(&c);
            const char *key = c.p; string(&c); size_t klen = (size_t)(c.p - key);
            need(&c, ':'); need(&c, '[');
            if (klen == 7 && !memcmp(key, "\"names\"", 7)) {
                long count = 0;
                if (!take(&c, ']')) { do { string(&c); count++; } while (take(&c, ',') && !c.bad); need(&c, ']'); }
                names = count;
            } else if (klen == 8 && !memcmp(key, "\"proofs\"", 8)) {
                if (pass == 0) {                               /* skipped: to its closing bracket (no strings inside) */
                    int depth = 1;
                    while (c.p < c.end && depth) { if (*c.p == '[') depth++; else if (*c.p == ']') depth--; c.p++; }
                } else {
                    seen_proofs = 1;
                    if (names < 0) { c.bad = 1; break; }
                    if (!take(&c, ']')) { do proof(&c, names); while (take(&c, ',') && !c.bad); need(&c, ']'); }
                }
            } else c.bad = 1;
        } while (take(&c, ',') && !c.bad);
        need(&c, '}');
    }
    free(out);
    if (each) putchar('\n');
    if (c.bad || !seen_proofs) { printf("  %s: not a table of proofs this reads\n", what); return 1; }
    printf("  %s: %ld proofs: %ld add up", what, proofs_ok + proofs_bad + proofs_big - before_ok - before_bad - before_big, proofs_ok - before_ok);
    if (proofs_bad - before_bad) printf(", %ld DO NOT", proofs_bad - before_bad);
    if (proofs_big - before_big) printf(", %ld not judged (a number too large for this program)", proofs_big - before_big);
    printf("\n");
    return (proofs_bad - before_bad) || (proofs_big - before_big);
}

/* the section .ode.proof of an ELF64 file, little-endian */
static uint64_t rd(const unsigned char *p, int n) { uint64_t v = 0; for (int i = n - 1; i >= 0; i--) v = (v << 8) | p[i]; return v; }
static const unsigned char *section(const unsigned char *f, size_t len, const char *name, size_t *size) {
    if (len < 64 || memcmp(f, "\177ELF", 4) || f[4] != 2 || f[5] != 1) return NULL;
    uint64_t shoff = rd(f + 0x28, 8); unsigned shentsize = (unsigned)rd(f + 0x3A, 2), shnum = (unsigned)rd(f + 0x3C, 2), shstrndx = (unsigned)rd(f + 0x3E, 2);
    if (shentsize < 64 || shoff > len || (uint64_t)shnum * shentsize > len - shoff || shstrndx >= shnum) return NULL;
    const unsigned char *str = f + shoff + (uint64_t)shstrndx * shentsize;
    uint64_t stroff = rd(str + 0x18, 8), strsize = rd(str + 0x20, 8);
    if (stroff > len || strsize > len - stroff) return NULL;
    for (unsigned i = 0; i < shnum; i++) {
        const unsigned char *s = f + shoff + (uint64_t)i * shentsize;
        uint64_t n = rd(s, 4), off = rd(s + 0x18, 8), sz = rd(s + 0x20, 8);
        if (n >= strsize || strnlen((const char *)f + stroff + n, strsize - n) == strsize - n) continue;
        if (strcmp((const char *)f + stroff + n, name)) continue;
        if (off > len || sz > len - off) return NULL;
        *size = (size_t)sz; return f + off;
    }
    return NULL;
}

static int file(const char *path) {
    FILE *fp = fopen(path, "rb");
    if (!fp) { printf("%s: cannot be opened\n", path); return 1; }
    fseek(fp, 0, SEEK_END); long len = ftell(fp); fseek(fp, 0, SEEK_SET);
    unsigned char *f = malloc((size_t)len + 1);
    if (fread(f, 1, (size_t)len, fp) != (size_t)len) { printf("%s: cannot be read\n", path); fclose(fp); free(f); return 1; }
    fclose(fp);
    size_t size = 0; const unsigned char *p = section(f, (size_t)len, ".ode.proof", &size);
    const unsigned char *end;
    if (p) end = p + size; else { p = f; end = f + len; }      /* not an ELF file with the section: a proof kept beside a file */
    if ((size_t)(end - p) < 12 || memcmp(p, "ode proof 2\n", 12)) { printf("%s: no proof this reads (.ode.proof)\n", path); free(f); return 1; }
    printf("%s:\n", path);
    int bad = 0, tables = 0;
    p += 12;
    while (p < end) {
        const unsigned char *nl = memchr(p, '\n', (size_t)(end - p));
        if (!nl) { bad = 1; break; }
        if (nl - p > 5 && !memcmp(p, "file ", 5)) {
            /* file NAME LENGTH */
            const unsigned char *sp = nl;
            while (sp > p + 5 && sp[-1] != ' ') sp--;
            char name[256]; size_t nlen = (size_t)(sp - 1 - (p + 5));
            if (nlen >= sizeof name) { bad = 1; break; }
            memcpy(name, p + 5, nlen); name[nlen] = 0;
            unsigned long long flen = strtoull((const char *)sp, NULL, 10);
            if (flen > (unsigned long long)(end - (nl + 1))) { bad = 1; break; }
            if (nlen > 8 && !strcmp(name + nlen - 8, ".arith.z")) { tables++; bad |= table(nl + 1, (size_t)flen, name); }
            p = nl + 1 + flen;
        } else p = nl + 1;
    }
    if (bad && !tables) printf("  the proof's form is not one this reads\n");
    if (!tables) printf("  it carries no proofs of arithmetic\n");
    free(f);
    return bad;
}

int main(int argc, char **argv) {
    if (argc < 2) { fprintf(stderr, "usage: varith2 FILE...   (files that carry a proof in .ode.proof, or proofs kept beside files)\n"); return 2; }
    int bad = 0;
    for (int i = 1; i < argc; i++) if (!strcmp(argv[i], "--each")) each = 1;
    for (int i = 1; i < argc; i++) if (strcmp(argv[i], "--each")) bad |= file(argv[i]);
    printf("varith2: %ld proofs of arithmetic: %ld add up to \"these rows cannot all hold\"", proofs_ok + proofs_bad + proofs_big, proofs_ok);
    if (proofs_bad) printf("; %ld DO NOT", proofs_bad);
    if (proofs_big) printf("; %ld not judged", proofs_big);
    printf("\n");
    return bad || proofs_bad || proofs_big ? 1 : 0;
}
