#!/usr/bin/env bash

set -e

# extract our tools version. credit @0xdeafbeef.
tools=$(compgen -c | grep "${CROSS_TARGET}")
version=$(echo "${tools}" | grep 'ar$' |  sed 's/'"${CROSS_TARGET}"'//' | sed 's/-ar//')

# export our toolchain versions
envvar_suffix="${CROSS_TARGET//-/_}"
upper_suffix=$(echo ${envvar_suffix} | tr '[:lower:]' '[:upper:]')
tools_prefix="${CROSS_TARGET}${version}"
declare -x AR_${envvar_suffix}="${tools_prefix}"-ar
declare -x CC_${envvar_suffix}="${tools_prefix}"-clang
declare -x CXX_${envvar_suffix}="${tools_prefix}"-clang++
declare -x CARGO_TARGET_${upper_suffix}_LINKER="${tools_prefix}"-clang

# by default, older versions of macOS (<10.9) link to libstdc++,
# but rust expects it to link to libc++, we can set stdlib to libc++.
#
# some time, the osxcross clang wrapper can't use right ld linker,
# the error looks like: /usr/bin/ld: unrecognized option '-dynamic'.
# let the clang wrapper to use its own linker in the osxcross bin path.
declare -x CFLAGS_${envvar_suffix}="-stdlib=libc++ -fuse-ld=${tools_prefix}-ld"
declare -x CXXFLAGS_${envvar_suffix}="-stdlib=libc++ -fuse-ld=${tools_prefix}-ld"

exec "$@"
