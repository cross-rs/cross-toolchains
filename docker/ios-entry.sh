#!/usr/bin/env bash

set -e

# export the SDK home
sdk_home="/opt/cctools/SDK"
sdk_name=$(ls -t -1 "${sdk_home}" | head -1)
export SDKROOT="${sdk_home}/${sdk_name}"

# export the bindgen args
envvar_suffix="${CROSS_TARGET//-/_}"
declare -x BINDGEN_EXTRA_CLANG_ARGS_$envvar_suffix="--sysroot=${SDKROOT}/usr"

exec "$@"
