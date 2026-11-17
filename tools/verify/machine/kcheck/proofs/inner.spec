// What the functions inside the binary are claimed to do: the verifier's steps from the binary to the claim
// in blake3.spec. Each is checked against its function's bytes, and used where that function is called. A
// reader of blake3.spec need not read this file.
//
// The arguments are in the order the machine's calling
// convention passes them. An argument is:
//   cv, block        the address of 32 bytes (8 words), of 64 bytes (16 words)
//   N bytes          the address of N bytes (N a number, or a number among the arguments)
//   a layout's name  the address of a record that lies as the layout says
//   N inputs         the address of a table of N addresses, each of an input of n blocks
//   N cvs            the address of N chaining values, one after another
//   N descriptors    the address of N records of 24 bytes: a block's address, a chaining value's address, a
//                    length byte, a flags byte
//   stack            the address of a stack of chaining values (1792 bytes: its count in the first 8, value i
//                    at 32 + 32*i, at most 55 of them)
//   bytes a b c d    a word whose four low bytes are named a, b, c, d
//   byte, number, counter, any       a number below 256; a number; 64 bits of a counter; any 64 bits
//   low byte, word, low word         how much of a register a kernel reads (word: the number is below 2^32)
// `requires`: what a caller must show. `ensures`: what the memory named holds afterwards (`x[i] = ... for i in a..b`:
// each of its values); all else is as it was. `returns`: the result. `stack`: the bytes of stack the function
// may use below its return address (`bits(n)`: the length of n in bits). `calls F if C`: the function calls F
// only where C holds (the platform word 5 means the machine has AVX-512, which its caller answers for).

// What sort of thing some definitions of blake3.spec give: where the verifier cannot work such a value out
// (the bytes of a chunk whose length it does not know), it still knows its sort, and names it by what it is of.
kind padded: 64 bytes
kind chunk_node: node120
kind subtree: cv

// How records lie in memory.
layout node120 120 { h: cv at 0, block: 64 bytes at 32, counter: number at 96, length: number at 104 below 65, flags: byte at 112 }
layout keyed 40 { key: cv at 0, flags: byte at 32 }

// The wide kernels: each lane's chunk, for any number of blocks n. K32 gives lane i the counter t + i;
// P32 is the same code entered a little later, and gives every lane t; P16 has sixteen lanes.
contract blake3_servil_avx512_k32(inputs: 32 inputs, n: number, key: cv, t: counter, packed: bytes flags start end length, out: 32 cvs) {
    requires n >= 1
    requires no_overlap(inputs, key, out)
    ensures out[i] = chunk(key, t + i, flags, start, end, length, n, inputs[i]) for i in 0..32
    stack 4096
    needs avx512
}

contract blake3_servil_avx512_p32(inputs: 32 inputs, n: number, key: cv, t: counter, packed: bytes flags start end length, out: 32 cvs) {
    requires n >= 1
    requires no_overlap(inputs, key, out)
    ensures out[i] = chunk(key, t, flags, start, end, length, n, inputs[i]) for i in 0..32
    stack 4096
    needs avx512
}

contract blake3_servil_avx512_p16(inputs: 16 inputs, n: number, key: cv, t: counter, packed: bytes flags start end length, out: 16 cvs) {
    requires n >= 1
    requires no_overlap(inputs, key, out)
    ensures out[i] = chunk(key, t, flags, start, end, length, n, inputs[i]) for i in 0..16
    stack 4096
    needs avx512
}

// Sixteen compressions, each node with its own chaining value, block, length and flags, counter 0.
contract blake3_servil_output16(nodes: 16 descriptors, out: 16 cvs) {
    ensures out[i] = compress(nodes[i].cv, nodes[i].block, counter(0), nodes[i].length, nodes[i].flags) for i in 0..16
    stack 4096
    needs avx512
}

contract blake3_servil_compress_in_place_avx512(h: cv, m: block, length: low byte, t: counter, flags: low byte) {
    requires no_overlap(h, m)
    ensures h = compress(h, m, t, length, flags)
    stack 0
    needs avx512
}

contract blake3_servil_compress_in_place_sse41(h: cv, m: block, length: word, t: counter, flags: low word) {
    requires no_overlap(h, m)
    ensures h = compress(h, m, t, length, flags)
    stack 0
    needs sse41
}

// The hash of a message, written to be proved (hash.ode): a chunk's node and its value, and the tree by the
// specification's own two parts.
contract b3l_pad(block: 64 bytes, src: n bytes, n: number) {
    requires no_overlap(block, src)
    requires n <= 64
    ensures block = padded(src)
    stack 48
}

contract b3l_chunk_node(nd: node120, input: len bytes, len: number, t: number, flags: byte, plat: any) {
    requires no_overlap(nd, input)
    requires len <= 1024
    ensures nd = chunk_node(nd.h, t, flags, input)
    stack 256
    needs sse41
    needs avx512 if plat == 5
}

contract b3l_node_out(out: cv, nd: node120, root: byte, plat: any) {
    requires no_overlap(out, nd)
    ensures out = node_value(nd, root)
    stack 128
    needs sse41
    needs avx512 if plat == 5
}

contract b3l_wide32(out: cv, input: 32768 bytes, kf: keyed, t: number) {
    requires no_overlap(out, input, kf)
    requires 1024 * t + 32768 <= 18446744073709551615
    ensures out = subtree(kf.key, kf.flags, t, input)
    stack 8192
    needs avx512
}

contract b3l_wide128(out: cv, input: 131072 bytes, kf: keyed, t: number) {
    requires no_overlap(out, input, kf)
    requires 1024 * t + 131072 <= 18446744073709551615
    ensures out = subtree(kf.key, kf.flags, t, input)
    stack 16384
    needs avx512
}

// `cvs`: the address of chaining values, one after another, of which the contract says what each is.
contract b3l_take(out: cv, input: len bytes, len: number, kf: keyed, t: number, cvs: cvs) {
    requires no_overlap(out, input, kf, cvs)
    requires len >= 1
    requires 1024 * t + len <= 18446744073709551615
    requires cvs[i] == node_value(chunk_node(kf.key, t + i, kf.flags, input[1024 * i .. 1024 * i + 1024]), 0) for i in 0..len / 1024
    ensures out = subtree(kf.key, kf.flags, t, input)
    decreases len
    stack 640 + 384 * bits((len - 1) / 1024)
    needs sse41
    needs avx512
}

contract b3l_part32(out: cv, input: len bytes, len: number, kf: keyed, t: number) {
    requires no_overlap(out, input, kf)
    requires len >= 1025
    requires len <= 32768
    requires 1024 * t + len <= 18446744073709551615
    ensures out = subtree(kf.key, kf.flags, t, input)
    stack 8192
    needs sse41
    needs avx512
}

contract b3l_subtree(out: cv, input: len bytes, len: number, kf: keyed, t: number, plat: any) {
    requires no_overlap(out, input, kf)
    requires len >= 1
    requires 1024 * t + len <= 18446744073709551615
    ensures out = subtree(kf.key, kf.flags, t, input)
    decreases len
    stack 16896 + 384 * bits((len - 1) / 1024)
    needs sse41
    needs avx512 if plat == 5
}

// =========================================================================================================
// Not the specification: an algorithm. Three functions of an earlier trial (lang/hasher.ode: push, merge, add)
// are claimed to follow it, turn for turn. The stack of chaining values of the subtrees finished so far:
// while it holds more than `target`, its two newest become their parent. (That this makes BLAKE3's tree is
// proved of its twin in alg/Stack.lean, and is not shown here.)
machine merge(key, flags, target) on s {
    while len(s) > target
    turn {
        s = s[0..len(s) - 2] ++ [parent(key, flags, s[len(s) - 2], s[len(s) - 1])]
    }
}

contract b3l_push(st: stack, new: cv) {
    requires len(st) <= 54
    ensures st = st ++ [new]
    stack 64
}

contract b3l_merge(st: stack, key: cv, flags: byte, plat: any, target: number) {
    requires target >= 1
    ensures st = merge(key, flags, target, st)
    returns len(st)
    stack 256
    calls blake3_servil_compress_in_place_avx512 if plat == 5
}

contract b3l_add(st: stack, key: cv, flags: byte, plat: any, new: cv, target: number) {
    requires len(st) <= 54
    requires target >= 1
    ensures st = merge(key, flags, target, st ++ [new])
    returns len(st)
    stack 512
}
