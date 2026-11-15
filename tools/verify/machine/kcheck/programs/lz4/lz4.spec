// LZ4, the block format (lz4_Block_format.md, Yann Collet): what a block of bytes decodes to, and the public
// contract of the binary's decoder.
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

const MALFORMED = 1

// How many bytes from `at` on are 255, before the first that is not.
def run(bytes, at) {
    fails MALFORMED if at >= len(bytes)
    if bytes[at] < 255 then 0 else 1 + run(bytes, at + 1)
}

// A count whose four bits in the token are `first`: that; or, if they are 15, 15 and the bytes from `at` up
// to and with the first that is not 255. `next`: the place after it.
def count(bytes, at, first) {
    let k = if first < 15 then 0 else run(bytes, at)
    if first < 15 then {value: first, next: at} else {value: 15 + 255 * k + bytes[at + k], next: at + k + 1}
}

// `out` with `n` more bytes, each a copy of the byte `offset` before the end as it then is.
def copied(out, offset, n) {
    let s[0] = out
    let s[k + 1] = s[k] ++ [s[k][len(s[k]) - offset]]
    s[n]
}

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
    sequences(bytes, n.next, copied(out, offset, n.value + 4))
}

def lz4(bytes) { sequences(bytes, 0, []) }

// Does the block decode, to at most `cap` bytes?
def fits(bytes, cap) { !failed(lz4(bytes)) && len(lz4(bytes)) <= cap }

const NO = 18446744073709551615

// =========================================================================================================
// The public contract (what a contract means: CONTRACT.md).
//
// The decoder is given room for `cap` bytes at `out`, and `n` bytes at `input`. It gives the count of the
// bytes the block decodes to, which are then at `out`; or NO, where the bytes at `input` are no LZ4 block or
// decode to more than `cap` bytes. Whatever the input, it writes nothing but the `cap` bytes at `out`.
// Which instructions it runs and which addresses it touches depend on the input's bytes.
contract ode_lz4_decode(out: cap bytes, cap: number, input: n bytes, n: number) {
    requires apart(out, input)
    returns if fits(input, cap) then len(lz4(input)) else NO
    ensures out[0 .. len(lz4(input))] = lz4(input) if fits(input, cap)
    writes out
    trace depends on input
    stack 0
}
