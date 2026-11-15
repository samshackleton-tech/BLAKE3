// ode_adler32_blocks on this machine's processor against zlib's adler32: native.c, of the function that brings
// the sums below 65521 once in 5552 bytes.
//   cc -O1 -o run native_blocks.c adler32_blocks.o -lz && ./run [CASES]
#define FN ode_adler32_blocks
#include "native.c"
