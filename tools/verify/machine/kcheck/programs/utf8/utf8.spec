// UTF-8 (the Unicode Standard, chapter 3, D92 and table 3-7; RFC 3629): which bytes are well-formed UTF-8,
// and how many code points they then hold. And the public contract of the binary's function.
//
// A code point is a number from 0 to 0x10FFFF that is not a surrogate (0xD800 to 0xDFFF). It is written in
// one to four bytes, the fewest that hold it: below 0x80 in one; below 0x800 in two; below 0x10000 in three;
// the rest in four. The first byte says how many there are and holds the highest bits; each byte after it is
// 0x80 and six more bits.

const MALFORMED = 1

// How many bytes a sequence has whose first byte is b.
def length(b) {
    fails MALFORMED if b >= 128 && b < 192          // a byte that only follows another
    fails MALFORMED if b >= 248
    if b < 128 then 1 else if b < 224 then 2 else if b < 240 then 3 else 4
}

// The six bits of the byte k after the first of the sequence at `at`.
def six(bytes, at, k) {
    fails MALFORMED if at + k >= len(bytes)
    fails MALFORMED if bytes[at + k] < 128 || bytes[at + k] >= 192
    bytes[at + k] - 128
}

// The number the sequence of n bytes at `at` holds.
def held(bytes, at, n) {
    if n == 1 then bytes[at]
    else if n == 2 then 64 * (bytes[at] - 192) + six(bytes, at, 1)
    else if n == 3 then 4096 * (bytes[at] - 224) + 64 * six(bytes, at, 1) + six(bytes, at, 2)
    else 262144 * (bytes[at] - 240) + 4096 * six(bytes, at, 1) + 64 * six(bytes, at, 2) + six(bytes, at, 3)
}

// The least number that n bytes are the fewest for.
def least(n) { if n == 1 then 0 else if n == 2 then 128 else if n == 3 then 2048 else 65536 }

// The code point at `at`, and where the next begins.
def point(bytes, at) {
    let n = length(bytes[at])
    let p = held(bytes, at, n)
    fails MALFORMED if p < least(n)                 // written in more bytes than it needs
    fails MALFORMED if p >= 55296 && p < 57344      // a surrogate
    fails MALFORMED if p > 1114111
    {value: p, next: at + n}
}

// How many code points the bytes from `at` hold, after `count` before them.
def points(bytes, at, count) { if at == len(bytes) then count else points(bytes, point(bytes, at).next, count + 1) }

// The count of code points of bytes that are well-formed UTF-8. (It fails where they are not.)
def utf8(bytes) { points(bytes, 0, 0) }

const NO = 18446744073709551615

// =========================================================================================================
// The public contract (what a contract means: LANGUAGE.md, part 2): the count of code points, or NO where the bytes
// are not well-formed UTF-8. Nothing is written.
contract ode_utf8(input: n bytes, n: number) {
    returns if failed(utf8(input)) then NO else utf8(input)
    trace depends on input
    stack 88
}
