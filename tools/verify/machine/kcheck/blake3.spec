// BLAKE3: what it is, and the public contract of the binary's function.
//
// The first part is the specification. It says what the hash of a message IS, by definitions; it does not say
// how to compute it. A reader checks it against the BLAKE3 paper, and a program (ode.py) checks that it gives
// the official test vectors (test_vectors/test_vectors.json: 35 lengths, the three modes). The verifiers read
// the same text on symbols and compare machine code with it; there is no other specification.
//
// The language is made for specifications of this kind:
//   numbers                whole, not below zero
//   words                  32 bits: `+` wraps, `^`, `|`, `>>>` rotates right; `word(n)`
//   counters               64 bits: `counter(n)`; `+` a number; `lo`, `hi` are its words
//   lists                  `[a, b]`, `xs[i]`, `xs[a..b]`, `xs ++ ys`, `len(xs)`, `[e for i in a..b]`,
//                          `xs with [i: a, j: b]` (xs with those places replaced)
//   bytes                  a list of bytes; `words(bs)`: every four a word, the lowest byte first
//   records                `{h: a, length: b}`, `r.h`
//   `if c then a else b`
//   `def NAME(args) { let X = E ... VALUE }`
//                          a definition: equations and a value. Nothing is given twice; nothing loops. It
//                          may be of itself on smaller things (the tree).
//   `let s[0] = A   let s[i + 1] = F(s[i])`
//                          a sequence, by its first value and each next one from the one before
//   `sequence NAME(args) { h[0] = A   h[b + 1] = F(h[b])   for b in 0..n }`
//                          the same as a definition of its own: NAME(args) is the last, h[n]
//   `the least number n in a..b with C`, `the greatest power of two k with C`

const IV = [0x6A09E667, 0xBB67AE85, 0x3C6EF372, 0xA54FF53A, 0x510E527F, 0x9B05688C, 0x1F83D9AB, 0x5BE0CD19]
const PERMUTATION = [2, 6, 3, 10, 7, 0, 4, 13, 1, 11, 12, 5, 9, 14, 15, 8]

const CHUNK_START         = 1
const CHUNK_END           = 2
const PARENT              = 4
const ROOT                = 8
const KEYED_HASH          = 16
const DERIVE_KEY_CONTEXT  = 32
const DERIVE_KEY_MATERIAL = 64

// ---------------------------------------------------------------------------------------------------------
// The compression function (the BLAKE3 paper, section 2.2).

// The state v of sixteen words with four of them mixed, and two words of the message.
def g(v, a, b, c, d, x, y) {
    let a1 = v[a] + v[b] + x
    let d1 = (v[d] ^ a1) >>> 16
    let c1 = v[c] + d1
    let b1 = (v[b] ^ c1) >>> 12
    let a2 = a1 + b1 + y
    let d2 = (d1 ^ a2) >>> 8
    let c2 = c1 + d2
    let b2 = (b1 ^ c2) >>> 7
    v with [a: a2, b: b2, c: c2, d: d2]
}

// A round: the four columns, then the four diagonals.
def round(v, m) {
    let c1 = g(v, 0, 4, 8, 12, m[0], m[1])
    let c2 = g(c1, 1, 5, 9, 13, m[2], m[3])
    let c3 = g(c2, 2, 6, 10, 14, m[4], m[5])
    let c4 = g(c3, 3, 7, 11, 15, m[6], m[7])
    let d1 = g(c4, 0, 5, 10, 15, m[8], m[9])
    let d2 = g(d1, 1, 6, 11, 12, m[10], m[11])
    let d3 = g(d2, 2, 7, 8, 13, m[12], m[13])
    g(d3, 3, 4, 9, 14, m[14], m[15])
}

// h: the chaining value, 8 words. m: the block, 16 words. t: the counter. length: the block's bytes. flags:
// the domain flags. Seven rounds, the message's words permuted between them; the result is the new chaining
// value, 8 words.
def compress(h, m, t, length, flags) {
    let s[0] = h ++ [word(IV[0]), word(IV[1]), word(IV[2]), word(IV[3]), lo(t), hi(t), word(length), word(flags)]
    let w[0] = m
    let s[r + 1] = round(s[r], w[r])
    let w[r + 1] = [w[r][PERMUTATION[i]] for i in 0..16]
    [s[7][i] ^ s[7][i + 8] for i in 0..8]
}

// ---------------------------------------------------------------------------------------------------------
// A chunk (section 2.4).

// The chaining value after n blocks: they are compressed one after another from the key. The first block is
// given `start`; the last is given `end` and its own `length` (every other block's is 64).
sequence chunk(key, t, flags, start, end, length, n, input) {
    h[0] = key
    h[b + 1] = compress(h[b], input[b], t,
                        if b == n - 1 then length else 64,
                        flags | (if b == 0 then start else 0) | (if b == n - 1 then end else 0))
    for b in 0..n
}

// A chunk of a message is at most 1024 bytes, in blocks of 64; the last block may hold fewer, and is read
// with zeros after them. A chunk of no bytes (the message of no bytes) is one block.
def block_count(bytes) { the least number n in 1..17 with 64 * n >= len(bytes) }

def padded(bytes) { [if k < len(bytes) then bytes[k] else 0 for k in 0..64] }

// What a chunk's last compression is given (its "node"): the chaining value after every block but the last,
// the last block, the chunk's number t, the last block's length, the flags.
def chunk_node(key, t, flags, bytes) {
    let n = block_count(bytes)
    let rest = bytes[64 * (n - 1) .. len(bytes)]
    {h: chunk(key, counter(t), flags, CHUNK_START, 0, 64, n - 1, [words(bytes[64 * b .. 64 * b + 64]) for b in 0..n - 1]),
     block: padded(rest), counter: t, length: len(rest), flags: flags | (if n == 1 then CHUNK_START else 0) | CHUNK_END}
}

// A node's chaining value; with root = ROOT, the hash.
def node_value(node, root) {
    compress(node.h, words(node.block), counter(node.counter), node.length, node.flags | root)
}

// ---------------------------------------------------------------------------------------------------------
// The tree (sections 2.1 and 2.5), and the hash.

// A parent node: one block, its two children's chaining values.
def parent(key, flags, left, right) {
    compress(key, left ++ right, counter(0), 64, flags | PARENT)
}

// More than one chunk's bytes are in two parts: the left part holds the greatest power-of-two count of
// chunks that leaves bytes for the right.
def left_chunks(bytes) { the greatest power of two k with 1024 * k < len(bytes) }

// The two parts' values side by side (a parent's block). The chunks are numbered from t.
def children(key, flags, t, bytes) {
    let k = left_chunks(bytes)
    subtree(key, flags, t, bytes[0 .. 1024 * k]) ++ subtree(key, flags, t + k, bytes[1024 * k .. len(bytes)])
}

// The chaining value of the tree over some bytes of a message.
def subtree(key, flags, t, bytes) {
    if len(bytes) <= 1024 then node_value(chunk_node(key, t, flags, bytes), 0)
    else compress(key, children(key, flags, t, bytes), counter(0), 64, flags | PARENT)
}

// The hash's eight words: the tree over the whole message, its last compression with ROOT.
def hash_words(key, flags, message) {
    if len(message) <= 1024 then node_value(chunk_node(key, 0, flags, message), ROOT)
    else compress(key, children(key, flags, 0, message), counter(0), 64, flags | PARENT | ROOT)
}

// The three modes (section 2.3), bytes to bytes.
def blake3(message) { bytes_of(hash_words(iv_words(), 0, message)) }
def blake3_keyed(key_bytes, message) { bytes_of(hash_words(words(key_bytes), KEYED_HASH, message)) }
def blake3_derive_key(context, material) {
    bytes_of(hash_words(hash_words(iv_words(), DERIVE_KEY_CONTEXT, context), DERIVE_KEY_MATERIAL, material))
}
def iv_words() { [word(IV[i]) for i in 0..8] }

// =========================================================================================================
// The public contract: what the function in the binary does (hash.ode's `hashr`).
//
// What a contract means. This is the same for every function; read it once.
//
//   The arguments are in the registers of the calling convention, in the order written (rdi, rsi, rdx, rcx,
//   r8, r9). An argument is a number, or the address of something in memory.
//   `requires`: what the caller makes true. `requires no_overlap(a, b, ...)`: the things at those addresses do
//   not overlap one another. The stack is the machine's own: none of them lies in it.
//
//   If the caller does that, the function returns, and then:
//   `ensures X = E`: what is at X is E, a value of the specification above. `returns E`: the number it gives.
//
//   And it has done nothing else. It has read no memory but what its arguments address, and its own stack.
//   It has written none but what an `ensures` names, and at most `stack` bytes below the caller's stack
//   pointer. The registers a callee keeps are as they were. It has run no instructions but those every
//   x86-64 processor has and those a `needs` line names (`needs F if C`: only where C holds). Which
//   instructions it ran and which addresses it touched depend on the numbers it was given, and not on the
//   bytes in memory.
//
//   A function that does more, or promises less, says so in its contract. Nothing is left to be understood.
//
// Here: `out` and `key` are each the address of 32 bytes; `input` is the address of `len` bytes; `flags` is
// a number below 256 (the mode's); `plat` is any word (5 where the caller answers for the processor having
// AVX-512). `words(bytes)`: every four bytes a word, the lowest byte first; `bytes_of(words)`: the other
// way. `bits(n)`: the length of n in bits. So with the key's bytes those of IV and flags 0 the 32 bytes at
// `out` are blake3(input) as defined above; with KEYED_HASH, blake3_keyed(key, input).
//
// The verifier shows the contract from the binary's bytes (check_binary.py b3hashr.o). What it needs beside
// them is in proofs/: the inner contracts, of the functions this one calls, and for a few loops a place. A
// reader of this contract need not read those: if one were wrong, the verifier would refuse the function it
// is of, or the function that relies on it.
contract b3l_hashr(out: 32 bytes, input: len bytes, len: number, key: 32 bytes, flags: byte, plat: any) {
    requires no_overlap(out, input, key)
    ensures out = bytes_of(hash_words(words(key), flags, input))
    stack 18688 + 384 * bits(len / 1024)
    needs sse41
    needs avx512 if plat == 5
}
