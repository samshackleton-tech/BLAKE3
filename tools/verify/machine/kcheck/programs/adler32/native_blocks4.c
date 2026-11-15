// ode_adler32_blocks4 on this machine's processor against zlib's adler32: native.c, of the function that takes
// four bytes a turn within a block.
//   cc -O1 -o run native_blocks4.c adler32_blocks4.o -lz && ./run [CASES]
#define FN ode_adler32_blocks4
#include "native.c"
