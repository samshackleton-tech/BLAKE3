// Base 64 (RFC 4648, section 4): what some bytes are written as, and the public contract of the binary's
// encoder.
//
// "A 24-bit input group is formed by concatenating 3 8-bit input groups. These 24 bits are then treated as 4
// concatenated 6-bit groups, each of which is translated into a single character in the base 64 alphabet."
// At the end, one byte left over is written as two letters and "==", two as three letters and "=".

// The letter for a number below 64: A to Z, a to z, 0 to 9, "+", "/".
def letter(v) { if v < 26 then 65 + v else if v < 52 then 71 + v else if v < 62 then v - 4 else if v == 62 then 43 else 47 }

// The four letters of three bytes: their 24 bits, six at a time.
def quad(a, b, c) { [letter(a / 4), letter(16 * (a % 4) + b / 16), letter(4 * (b % 16) + c / 64), letter(c % 64)] }

// What the first k groups of three bytes are written as.
sequence groups(bytes) { s[0] = []   s[k + 1] = s[k] ++ quad(bytes[3 * k], bytes[3 * k + 1], bytes[3 * k + 2]) }

// What the bytes from `at` are written as, when fewer than three are left.
def rest(bytes, at) {
    if at == len(bytes) then []
    else if at + 1 == len(bytes) then [letter(bytes[at] / 4), letter(16 * (bytes[at] % 4)), 61, 61]
    else [letter(bytes[at] / 4), letter(16 * (bytes[at] % 4) + bytes[at + 1] / 16), letter(4 * (bytes[at + 1] % 16)), 61]
}

def base64(bytes) { groups(bytes)[len(bytes) / 3] ++ rest(bytes, 3 * (len(bytes) / 3)) }

// =========================================================================================================
// The public contract (what a contract means: LANGUAGE.md, part 2). The caller gives room for the letters: four for
// every three bytes or part of three. The count of letters is returned.
contract ode_base64(out: cap bytes, cap: number, input: n bytes, n: number) {
    requires no_overlap(out, input)
    requires cap >= 4 * ((n + 2) / 3)
    returns 4 * ((n + 2) / 3)
    ensures out[0 .. 4 * ((n + 2) / 3)] = base64(input)
    trace depends on input
    stack 120
}
