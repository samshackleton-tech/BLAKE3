// A number as a varint (LEB128, as in protocol buffers and DWARF): seven bits to a byte, the lowest first;
// every byte but the last has 128 added. And the public contract of the binary's encoder.

def varint(v) { if v < 128 then [v] else [128 + v % 128] ++ varint(v / 128) }

// =========================================================================================================
// The public contract (what a contract means: LANGUAGE.md, part 2). A number below 2^64 takes at most ten bytes.
contract ode_varint(out: 10 bytes, v: number) {
    returns r
    ensures out[0 .. r] = varint(v)
    stack 24
}
