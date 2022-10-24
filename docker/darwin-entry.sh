#!/usr/bin/env bash
# shellcheck disable=SC2086

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

exec "$@"
