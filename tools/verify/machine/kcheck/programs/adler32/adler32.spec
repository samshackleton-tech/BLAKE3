// Adler-32 (RFC 1950, section 8.2): what the checksum of some bytes is, and the public contract of the
// binary's function.
//
// "Adler-32 is composed of two sums accumulated per byte: s1 is the sum of all bytes, s2 is the sum of all s1
// values. Both sums are done modulo 65521. s1 is initialized to 1, s2 to zero. The Adler-32 checksum is stored
// as s2*65536 + s1."

sequence s1(bytes) { s[0] = 1   s[i + 1] = (s[i] + bytes[i]) % 65521 }
sequence s2(bytes) { s[0] = 0   s[i + 1] = (s[i] + s1(bytes)[i + 1]) % 65521 }

def adler32(bytes) { 65536 * s2(bytes)[len(bytes)] + s1(bytes)[len(bytes)] }

// =========================================================================================================
// The public contract (what a contract means: LANGUAGE.md, part 2).
contract ode_adler32(input: len bytes, len: number) {
    returns adler32(input)
    trace depends on input
    stack 40
}

// The same, of a function that brings the two sums below 65521 once in 5552 bytes (blocks.ode): the usual
// way to make it fast. The specification above is not changed for it.
contract ode_adler32_blocks(input: len bytes, len: number) {
    returns adler32(input)
    trace depends on input
    stack 56
}

// The same again, of the function that takes four bytes a turn within a block (blocks4.ode).
contract ode_adler32_blocks4(input: len bytes, len: number) {
    returns adler32(input)
    trace depends on input
    stack 56
}
