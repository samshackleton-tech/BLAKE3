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

// One's complement addition lets what is carried out of 16 bits come back in at the bottom: so of a plain
// sum, what is above 16 bits is added to what is within them. Four times brings any sum below 2^64 within
// 16 bits, and the sum of fewer than 2^49 bytes is below 2^64. (Three times would do for fewer than 2^32
// bytes.) It is then the sum's remainder by 65535, with 65535 in place of 0 for a sum that is not 0:
// test_specs.py tries that; nothing here shows it.
def fold(s) { s % 65536 + s / 65536 }

def checksum(bytes) { 65535 - fold(fold(fold(fold(total(bytes))))) }

const NO = 18446744073709551615

// =========================================================================================================
// The public contract (what a contract means: CONTRACT.md). There is no `requires`: of 2^49 bytes or more,
// whose plain sum might not fit 64 bits, it says NO and reads none. There is no `trace` line: which
// instructions run and which addresses are touched depend on n, and not on the bytes.
contract ode_inet(input: n bytes, n: number) {
    returns if n < 562949953421312 then checksum(input) else NO
    stack 40
}
