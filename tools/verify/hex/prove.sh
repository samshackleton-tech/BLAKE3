#!/bin/sh
# The hash's hexadecimal: both kernels, from the source to checked theorems. See README.md.
# A release runs this; CI runs it nightly; check-shipped.sh (under a second) can run on every change.
set -eu
here=$(cd "$(dirname "$0")" && pwd)
"$here/check-shipped.sh"
"$here/x86/prove.sh"
"$here/arm/prove.sh"
echo "the hash's hexadecimal, on both architectures: checked"
