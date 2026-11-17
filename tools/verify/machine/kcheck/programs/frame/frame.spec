// A frame: an LZ4 block, and after it the Adler-32 of what the block decodes to, in four bytes, the highest
// first (as a zlib stream ends). What a frame holds; and the public contract of the binary's function that
// opens one.
//
// The function is made of two others, used through their contracts alone: an LZ4 block decoder and an
// Adler-32. Their definitions are the first two parts of this page, word for word those of lz4.spec and
// adler32.spec; the frame's own are the third.

// ---------------------------------------------------------------------------------------------------------
// 1. An LZ4 block (lz4.spec has the account of the format): what it decodes to.

const MALFORMED = 1

// A count of which `sum` is read so far: the bytes from `at` are added to it, up to and with the first that is
// not 255. `next`: the place after it.
def counted(bytes, at, sum) {
    fails MALFORMED if at >= len(bytes)
    if bytes[at] < 255 then {value: sum + bytes[at], next: at + 1} else counted(bytes, at + 1, sum + 255)
}

// A count whose four bits in the token are `first`: that; or, if they are 15, 15 and the bytes that follow.
def count(bytes, at, first) { if first < 15 then {value: first, next: at} else counted(bytes, at, 15) }

// `out` with one more byte, and one more, and so on: each a copy of the byte `offset` before the end as it
// then is. copies(out, offset)[n] is `out` with n more.
sequence copies(out, offset) { s[0] = out   s[k + 1] = s[k] ++ [s[k][len(s[k]) - offset]] }

// What the block decodes to, from the token at `at`, when `out` is what is decoded before it.
def sequences(bytes, at, out) {
    fails MALFORMED if at >= len(bytes)
    let literals = count(bytes, at + 1, bytes[at] / 16)
    let end = literals.next + literals.value
    fails MALFORMED if end > len(bytes)
    let with_literals = out ++ bytes[literals.next .. end]
    if end == len(bytes) then with_literals else match(bytes, end, bytes[at] % 16, with_literals)
}

// The rest of a sequence, whose offset is at `at`, and the sequences after it.
def match(bytes, at, low, out) {
    fails MALFORMED if at + 2 > len(bytes)
    let offset = bytes[at] + 256 * bytes[at + 1]
    fails MALFORMED if offset == 0 || offset > len(out)
    let n = count(bytes, at + 2, low)
    sequences(bytes, n.next, copies(out, offset)[n.value + 4])
}

def lz4(bytes) { sequences(bytes, 0, []) }

// ---------------------------------------------------------------------------------------------------------
// 2. Adler-32 (RFC 1950, section 8.2).

sequence s1(bytes) { s[0] = 1   s[i + 1] = (s[i] + bytes[i]) % 65521 }
sequence s2(bytes) { s[0] = 0   s[i + 1] = (s[i] + s1(bytes)[i + 1]) % 65521 }

def adler32(bytes) { 65536 * s2(bytes)[len(bytes)] + s1(bytes)[len(bytes)] }

// ---------------------------------------------------------------------------------------------------------
// 3. The frame.

const SHORT = 3
const SUM = 4
const NO = 18446744073709551615

// Four bytes as a number, the highest first.
def be32(b) { 16777216 * b[0] + 65536 * b[1] + 256 * b[2] + b[3] }

// What the frame holds. It holds nothing where it is less than four bytes (SHORT), where its block does not
// decode (MALFORMED), and where the four bytes are not the sum of what it decodes to (SUM).
def unframe(bytes) {
    fails SHORT if len(bytes) < 4
    let body = lz4(bytes[0 .. len(bytes) - 4])
    fails SUM if adler32(body) != be32(bytes[len(bytes) - 4 .. len(bytes)])
    body
}

// =========================================================================================================
// The public contract (what a contract means: LANGUAGE.md, part 2).
//
// Given room for `cap` bytes at `out` and the `n` bytes of a frame at `input`: where the frame holds
// something of no more than `cap` bytes, the function returns how many bytes that is, and they are at
// `out`; where it holds nothing, or more than the room, it returns NO. (cap < NO: so that NO is no count.)
contract ode_unframe(out: cap bytes, cap: number, input: n bytes, n: number) {
    requires no_overlap(out, input)
    requires n < 72057594037927936
    requires cap < NO
    returns if failed(unframe(input)) || len(unframe(input)) > cap then NO else len(unframe(input))
    ensures out[0 .. len(unframe(input))] = unframe(input) if !failed(unframe(input)) && len(unframe(input)) <= cap
    trace depends on input
    stack 184
}
