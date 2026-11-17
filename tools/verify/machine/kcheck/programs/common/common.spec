// How many bytes two runs of n bytes have alike at their start. And the public contract of the binary's
// function.

// The same, when the first `at` bytes are known to be alike.
def alike(a, b, at) { if at == len(a) then at else if a[at] != b[at] then at else alike(a, b, at + 1) }

def common(a, b) { alike(a, b, 0) }

// =========================================================================================================
// The public contract (what a contract means: LANGUAGE.md, part 2). Nothing is written, so the two runs may overlap.
contract ode_common(a: n bytes, b: n bytes, n: number) {
    returns common(a, b)
    trace depends on a, b
    stack 40
}
