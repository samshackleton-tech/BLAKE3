#!/bin/sh
# The shipped assembly of the hash's hexadecimal is what the source prints: c/blake3_hex_x86-64_unix.S and
# c/blake3_hex_aarch64.S against the kernels `hex` and `hex_neon` of hex.ode, byte for byte.
# Needs python3 only; under a second. A change to either side without the other fails here.
set -eu
here=$(cd "$(dirname "$0")" && pwd); root=$(cd "$here/../../.." && pwd)
bad=0
check() {  # check ARCH KERNEL FILE
  if python3 "$here/odec.py" "$here/hex.ode" "$1" "$2" blake3_servil_ | cmp -s - "$root/c/$3"; then
    echo "c/$3 is what hex.ode's kernel $2 prints"
  else
    echo "c/$3 is NOT what hex.ode's kernel $2 prints (python3 tools/verify/hex/odec.py tools/verify/hex/hex.ode $1 $2 blake3_servil_)"; bad=1
  fi
}
check x86_64 hex blake3_hex_x86-64_unix.S
check aarch64 hex_neon blake3_hex_aarch64.S
exit $bad
