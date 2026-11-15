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

// A count of which `sum` is read so far: the bytes from `at` are added to it, up to and with the first that is
// not 255. `next`: the place after it.
def counted(bytes, at, sum) {
    fails MALFORMED if at >= len(bytes)
    if bytes[at] < 255 then {value: sum + bytes[at], next: at + 1} else counted(bytes, at + 1, sum + 255)
}

// A count whose four bits in the token are `first`: that; or, if they are 15, 15 and the bytes that follow.
def count(bytes, at, first) { if first < 15 then {value: first, next: at} else counted(bytes, at, 15) }

// `out` with `n` more bytes, each a copy of the byte `offset` before the end as it then is.
def copied(out, offset, n) { if n == 0 then out else copied(out ++ [out[len(out) - offset]], offset, n - 1) }

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
// The decoder is given room for `cap` bytes at `out`, and `n` bytes at `input`. It returns a number r. If r
// is not NO, the block decodes to r bytes, and they are at `out`. Whatever the input, a block or not, it
// reads nothing but the n bytes at `input`, writes nothing but the cap bytes at `out`, and returns. Which
// instructions it runs and which addresses it touches depend on the input's bytes.
//
// Not said, and so not shown: that it gives NO only where the input is no block or decodes to more than
// `cap` bytes. (It is tested: native.c, on a processor, against another decoder: 20,000 blocks, whole and
// damaged, give the same counts, the same bytes and the same refusals.)
contract ode_lz4_decode(out: cap bytes, cap: number, input: n bytes, n: number) {
    requires apart(out, input)
    requires cap < NO
    returns r
    ensures r = len(lz4(input)) if r != NO
    ensures out[0 .. r] = lz4(input) if r != NO
    writes out
    trace depends on input
    stack 104
}
