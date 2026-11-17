// The Internet checksum (RFC 1071), as IP, UDP and TCP carry it: what the checksum of some bytes is, and the
// public contract of the binary's function.
//
// "(1) Adjacent octets to be checksummed are paired to form 16-bit integers, and the 1's complement sum of
// these 16-bit integers is formed. (2) To generate a checksum, [...] the 16-bit 1's complement sum is computed
// over the octets concerned, and the 1's complement of this sum is placed in the checksum field." A byte left
// over at the end is paired with a zero. The first byte of a pair is the high one.

// The plain sum of the first k pairs.
sequence sums(bytes) { s[0] = 0   s[k + 1] = s[k] + 256 * bytes[2 * k] + bytes[2 * k + 1] }

// The plain sum of all the pairs, a last byte alone paired with zero.
def total(bytes) {
    let pairs = len(bytes) / 2
    if len(bytes) % 2 == 0 then sums(bytes)[pairs] else sums(bytes)[pairs] + 256 * bytes[len(bytes) - 1]
}

// The one's complement sum of 16-bit numbers whose plain sum is s. One's complement addition lets what is
// carried out of 16 bits come back in at the bottom, which takes 65535 off; so the sum is s less as many
// 65535s as leave it from 1 to 65535. Only a plain sum of 0 gives 0: in one's complement 65535 is a zero
// too, and it is the zero every other sum that is a multiple of 65535 comes to.
def ones_sum(s) { if s == 0 then 0 else (s - 1) % 65535 + 1 }

// The checksum: the one's complement (every bit turned) of that sum.
def checksum(bytes) { 65535 - ones_sum(total(bytes)) }

const NO = 18446744073709551615

// =========================================================================================================
// The public contract (what a contract means: LANGUAGE.md, part 2). There is no `requires`: of 2^49 bytes or more,
// whose plain sum might not fit 64 bits, it says NO and reads none. There is no `trace` line: which
// instructions run and which addresses are touched depend on n, and not on the bytes.
//
// (The second and third lines are one line, said for a sum that is 0 and for one that is not: the verifier
// has to be told to take that question both ways. README.md, "What each made the languages gain".)
contract ode_inet(input: n bytes, n: number) {
    returns r
    ensures r == NO if n >= 562949953421312
    ensures r == checksum(input) if n < 562949953421312 && total(input) == 0
    ensures r == checksum(input) if n < 562949953421312 && total(input) != 0
    stack 40
}
