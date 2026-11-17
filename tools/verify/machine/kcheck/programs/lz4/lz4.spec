// LZ4, the block format (lz4_Block_format.md, Yann Collet): what a block of bytes decodes to, and the public
// contracts of the binary's decoder and encoders.
//
// A block is sequences, one after another. A sequence is: a token (one byte); a count of literals (the
// token's high four bits; if they are 15, more bytes follow); that many literal bytes; and then, unless the
// block ends there, an offset (two bytes, the low one first) and a count (the token's low four bits; if they
// are 15, more bytes follow; 4 is added): that many bytes are copied to the end of what is decoded so far,
// one at a time, each from `offset` bytes before the end. The block ends after the literals of its last
// sequence.
//
// (The format's three "end of block" restrictions on encoders, which a decoder "is allowed to" enforce, are
// not enforced here: a block that breaks them decodes.)
//
// Decoding fails where the bytes are no block (MALFORMED). How much room a decoder has is no part of the
// format: it is in the decoder's contract, below.

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

const NO = 18446744073709551615

// =========================================================================================================
// The public contract (what a contract means: LANGUAGE.md, part 2).
//
// The decoder is given room for `cap` bytes at `out`, and `n` bytes at `input`. Where the block decodes to
// no more than `cap` bytes, it returns the count of the bytes decoded, and they are at `out`. Where it does
// not (no block, or more bytes than the room), it returns NO. Whatever the input, it reads nothing but the n bytes at `input`,
// writes nothing but the cap bytes at `out`, and returns. Which instructions it runs and which addresses it
// touches depend on the input's bytes.
//
// (The `requires` on n: the block is less than 2^56 bytes, so that no count read from it passes 64 bits.
// Such a block decodes to fewer than 2^64 - 1 bytes, so NO is never a count.)
contract ode_lz4_decode(out: cap bytes, cap: number, input: n bytes, n: number) {
    requires no_overlap(out, input)
    requires n < 72057594037927936
    returns if failed(lz4(input)) || len(lz4(input)) > cap then NO else len(lz4(input))
    ensures out[0 .. len(lz4(input))] = lz4(input) if !failed(lz4(input)) && len(lz4(input)) <= cap
    trace depends on input
    stack 104
}

// =========================================================================================================
// An encoder's public contract: what it writes is a block that decodes to the input.
//
// This says nothing of how the block is made, and it is not a way to make one: it is true of every encoder
// that is right, and of one that always gives NO. So a second line says when it does not: where the room
// is the bound every user of LZ4 knows (LZ4_compressBound). `ode_lz4_store` is the plainest encoder: it
// holds the n bytes as they are, in one sequence. It returns the count of bytes written at `out`, or NO.
contract ode_lz4_store(out: cap bytes, cap: number, input: n bytes, n: number) {
    requires no_overlap(out, input)
    requires cap < NO
    returns r
    ensures lz4(out[0 .. r]) == input if r != NO
    ensures r != NO if cap >= n + n / 255 + 16
    writes out
    stack 88
}

// An encoder that packs: `ode_lz4_pack` writes a match where the bytes ahead are the bytes `d` before (the
// caller chooses the distance), and literals elsewhere. The same contract: what it writes decodes to the
// input, and with the same room it does not say NO. (The `requires` on d: a distance is 1 to 65535, as the
// format's two bytes hold it.)
contract ode_lz4_pack(out: cap bytes, cap: number, input: n bytes, n: number, d: number) {
    requires no_overlap(out, input)
    requires cap < NO
    requires d >= 1
    requires d <= 65535
    returns r
    ensures lz4(out[0 .. r]) == input if r != NO
    ensures r != NO if cap >= n + n / 255 + 16
    writes out
    trace depends on input
    stack 120
}
