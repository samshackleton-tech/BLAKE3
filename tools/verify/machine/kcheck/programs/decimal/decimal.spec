// A count as a proof's header writes it (`file NAME LENGTH`, `at OFFSET NAME`: kproof.py): decimal digits, the
// most significant first; at least one, and at most nine (so the count is below 1,000,000,000). And the
// public contract of a function that reads one.
//
// This is the first piece of a verifier's own work written in Ode and shown by the verifier: the reading
// of one field of the form its proofs travel in.

const MALFORMED = 1

// What a digit's byte counts for.
def digit(b) {
    fails MALFORMED if b < 48 || b > 57
    b - 48
}

// The number the digits from `at` on make of `sum`, the number of those before them.
def digits(bytes, at, sum) { if at == len(bytes) then sum else digits(bytes, at + 1, 10 * sum + digit(bytes[at])) }

def decimal(bytes) {
    fails MALFORMED if len(bytes) == 0
    fails MALFORMED if len(bytes) > 9
    digits(bytes, 0, 0)
}

const NO = 18446744073709551615

// =========================================================================================================
// The public contract (what a contract means: LANGUAGE.md, part 2): the count, or NO where the bytes are not one.
// Nothing is written.
contract ode_decimal(input: n bytes, n: number) {
    returns if failed(decimal(input)) then NO else decimal(input)
    trace depends on input
    stack 56
}
