// Adler-32 (RFC 1950, section 8.2): what the checksum of some bytes is, and the public contract of the
// binary's function.
//
// "Adler-32 is composed of two sums accumulated per byte: s1 is the sum of all bytes, s2 is the sum of all s1
// values. Both sums are done modulo 65521. s1 is initialized to 1, s2 to zero. The Adler-32 checksum is stored
// as s2*65536 + s1."

def adler32(bytes) {
    let s1[0] = 1
    let s1[i + 1] = (s1[i] + bytes[i]) % 65521
    let s2[0] = 0
    let s2[i + 1] = (s2[i] + s1[i + 1]) % 65521
    65536 * s2[len(bytes)] + s1[len(bytes)]
}

// =========================================================================================================
// The public contract (what a contract means: CONTRACT.md).
contract ode_adler32(input: len bytes, len: number) {
    returns adler32(input)
    stack 0
}
