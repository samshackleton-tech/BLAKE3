#!/usr/bin/env python3
"""The specifications of programs/ evaluated on numbers, against other people's answers.

    python3 programs/test_specs.py [SIGIL]         (SIGIL: a checkout of github.com/johnservil/sigil, for its vectors.tsv)

Adler-32 against zlib's; LZ4 against a decoder written here another way (a loop, as decoders are), on blocks
a small compressor here makes, on the format document's examples, and on damaged blocks; a varint against
LEB128 written here; the count of bytes alike against a search; Sigil against the 220 good vectors of its
repository. A specification that disagrees with them is wrong, or they are."""
import os, random, sys, unittest, zlib
sys.setrecursionlimit(60000)            # a definition of itself on smaller things is followed as deep as its count
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(HERE))
import ode

def spec(name):
    with open(os.path.join(HERE, name, name + ".spec")) as f: return ode.Spec(f.read())

def value(s, name, *args):
    """("ok", value) or ("fails", reason)."""
    try: return "ok", s.call(ode.Numbers(), name, *args)
    except ode.Fails as f: return "fails", f.reason


def lz4_decode(src):
    """LZ4 block decoding as decoders do it. None: not a block."""
    out, i, n = bytearray(), 0, len(src)
    while True:
        if i >= n: return None
        token = src[i]; i += 1
        lit = token >> 4
        if lit == 15:
            while True:
                if i >= n: return None
                b = src[i]; i += 1; lit += b
                if b != 255: break
        if i + lit > n: return None
        out += src[i:i + lit]; i += lit
        if i == n: return bytes(out)
        if i + 2 > n: return None
        offset = src[i] | src[i + 1] << 8; i += 2
        if offset == 0 or offset > len(out): return None
        m = token & 15
        if m == 15:
            while True:
                if i >= n: return None
                b = src[i]; i += 1; m += b
                if b != 255: break
        for _ in range(m + 4): out.append(out[-offset])


def lz4_compress(data):
    """A valid block for data: greedy matches of 4 or more found by looking back (slow; for tests)."""
    def length(n): return bytes([255] * (n // 255) + [n % 255])
    out, i, start, n = bytearray(), 0, 0, len(data)
    while i + 12 < n:
        best, where = 0, 0
        for j in range(max(0, i - 300), i):
            k = 0
            while i + k < n - 5 and data[j + k] == data[i + k]: k += 1
            if k > best: best, where = k, j
        if best < 4: i += 1; continue
        lit, m = i - start, best - 4
        out.append(min(lit, 15) << 4 | min(m, 15))
        if lit >= 15: out += length(lit - 15)
        out += data[start:i] + bytes([(i - where) & 255, (i - where) >> 8])
        if m >= 15: out += length(m - 15)
        i += best; start = i
    lit = n - start
    out.append(min(lit, 15) << 4)
    if lit >= 15: out += length(lit - 15)
    return bytes(out + data[start:])


class Specs(unittest.TestCase):
    def test_adler32_is_zlibs(self):
        s, r = spec("adler32"), random.Random(1)
        cases = [b"", b"a", b"abc", b"Wikipedia", b"\xff" * 5553, bytes(range(256)) * 23] + [bytes(r.randrange(256) for _ in range(r.randrange(0, 3000))) for _ in range(40)]
        for data in cases: self.assertEqual(value(s, "adler32", list(data)), ("ok", zlib.adler32(data)), len(data))

    def test_lz4_is_the_decoders(self):
        s, r = spec("lz4"), random.Random(2)
        self.assertEqual(value(s, "count", [33], 0, 15), ("ok", {"value": 48, "next": 1}))                # the document's three examples
        self.assertEqual(value(s, "count", [255, 10], 0, 15), ("ok", {"value": 280, "next": 2}))
        self.assertEqual(value(s, "count", [0], 0, 15), ("ok", {"value": 15, "next": 1}))
        self.assertEqual(value(s, "lz4", [0], 100), ("ok", []))                                               # "even empty input can be represented, using a zero byte"
        texts = [b"", b"a", b"hello hello hello hello hello hello hello", b"abcd" * 100, bytes(300), bytes(range(256)) * 3] + [bytes(r.choice(b"ab\x00\xff") for _ in range(r.randrange(0, 700))) for _ in range(25)]
        blocks = []
        for data in texts:
            block = lz4_compress(data)
            self.assertEqual(lz4_decode(block), data)
            self.assertEqual(value(s, "lz4", list(block), len(data)), ("ok", list(data)))
            blocks.append(block)
        self.assertTrue(any(len(b) < len(t) // 4 for b, t in zip(blocks, texts)), "some block has matches")
        damaged = 0
        for block in blocks:                                 # damaged blocks: the same verdict, and where both decode the same bytes
            for _ in range(30):
                b = bytearray(block)
                for _ in range(r.randrange(1, 3)):
                    how = r.randrange(3)
                    if how == 0 and b: b[r.randrange(len(b))] = r.randrange(256)
                    elif how == 1 and b: del b[r.randrange(len(b)):]
                    else: b.insert(r.randrange(len(b) + 1), r.randrange(256))
                theirs = lz4_decode(bytes(b))
                ours = value(s, "lz4", list(b), 100000)
                self.assertEqual(ours, ("fails", 1) if theirs is None else ("ok", list(theirs)), bytes(b).hex())
                damaged += theirs is None
        self.assertGreater(damaged, 100)
        for block, data in zip(blocks, texts):              # room: one byte too few is ROOM; none of the damaged is taken for whole
            if data: self.assertEqual(value(s, "lz4", list(block), len(data) - 1), ("fails", 2))
        self.assertEqual(value(s, "lz4", [0x10], 100), ("fails", 1))

    def test_varint_is_leb128(self):
        s, r = spec("varint"), random.Random(3)
        def leb128(v):
            out = []
            while v >= 128: out.append(128 | (v & 127)); v >>= 7
            return out + [v]
        for v in [0, 1, 127, 128, 300, 16383, 16384, 2 ** 32, 2 ** 63, 2 ** 64 - 1] + [r.getrandbits(r.randrange(1, 65)) for _ in range(300)]:
            self.assertEqual(value(s, "varint", v), ("ok", leb128(v)), v)
        self.assertEqual(value(s, "varint", 300), ("ok", [0xAC, 0x02]))               # the example of the protocol buffers' documentation

    def test_common_is_the_count_alike(self):
        s, r = spec("common"), random.Random(4)
        for _ in range(300):
            n = r.randrange(0, 60); a = [r.randrange(3) for _ in range(n)]; b = list(a)
            for k in range(r.randrange(0, n + 1), n): b[k] = r.randrange(3)
            want = next((k for k in range(n) if a[k] != b[k]), n)
            self.assertEqual(value(s, "common", a, b), ("ok", want))

    def test_utf8_is_pythons(self):
        # the strict decoder of Python: text of every length of sequence, the same with a byte changed or left out,
        # random bytes, and the boundaries of table 3-7 with every first byte
        s, r = spec("utf8"), random.Random(7)
        pick = lambda: chr(r.choice([r.randrange(0x80), r.randrange(0x80, 0x800), r.randrange(0x800, 0xD800), r.randrange(0xE000, 0x10000), r.randrange(0x10000, 0x110000)]))
        cases = [b"", b"a", b"\xc0\x80", b"\xc1\xbf", b"\xe0\x9f\xbf", b"\xe0\xa0\x80", b"\xed\x9f\xbf", b"\xed\xa0\x80", b"\xf0\x8f\xbf\xbf", b"\xf0\x90\x80\x80", b"\xf4\x8f\xbf\xbf", b"\xf4\x90\x80\x80",
                 b"\xf5\x80\x80\x80", b"\xf8\x88\x80\x80\x80", b"\xff", b"\x80", b"\xc2", b"\xe1\x80", b"\xf1\x80\x80", b"\xef\xbf\xbf"]
        for k in range(1500):
            text = bytearray("".join(pick() for _ in range(r.randrange(0, 12))).encode())
            if k % 4 == 1 and text: text[r.randrange(len(text))] = r.randrange(256)
            if k % 4 == 2 and text: del text[r.randrange(len(text))]
            if k % 4 == 3: text = bytearray(r.randrange(256) for _ in range(r.randrange(0, 12)))
            cases.append(bytes(text))
        for a in range(256):
            for b in (0x7F, 0x80, 0x8F, 0x90, 0x9F, 0xA0, 0xBF, 0xC0): cases += [bytes([a, b]), bytes([a, b, 0x80]), bytes([a, b, 0x80, 0x80]), bytes([a, b, 0xBF, 0xBF])]
        good = 0
        for data in cases:
            try: want = ("ok", len(data.decode("utf-8", "strict"))); good += 1
            except UnicodeDecodeError: want = ("fails", 1)
            self.assertEqual(value(s, "utf8", list(data)), want, data.hex())
        self.assertGreater(good, 500)

    def test_base64_is_pythons(self):
        import base64
        s, r = spec("base64"), random.Random(11)
        for n in list(range(0, 80)) + [r.randrange(80, 700) for _ in range(40)]:
            data = bytes(r.randrange(256) for _ in range(n))
            self.assertEqual(value(s, "base64", list(data)), ("ok", list(base64.b64encode(data))), n)
        for v in range(64): self.assertEqual(value(s, "letter", v), ("ok", b"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"[v]))

    def test_sigil_is_the_repositorys(self):
        path = os.path.join(sys.argv[1] if len(sys.argv) > 1 else os.path.expanduser("~/tmp/night/sigil"), "vectors.tsv")
        if not os.path.exists(path): self.skipTest("no vectors.tsv: give the sigil checkout")
        s, good = spec("sigil"), 0
        with open(path, encoding="utf-8") as f:
            for line in f:
                kind, hexed, sigil = line.rstrip("\n").split("\t")[:3]
                if kind != "good": continue
                data = bytes.fromhex(hexed)
                self.assertEqual(value(s, "sigil", list(data)), ("ok", [ord(c) for c in sigil]), hexed)
                self.assertEqual(value(s, "sigil_utf8", list(data)), ("ok", list(sigil.encode("utf-8"))), hexed)
                good += 1
        self.assertEqual(good, 220)


if __name__ == "__main__":
    unittest.main(argv=sys.argv[:1])
