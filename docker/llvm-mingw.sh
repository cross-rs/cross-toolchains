#!/usr/bin/env bash

set -x
set -euo pipefail

# shellcheck disable=SC1091
. lib.sh

main() {
    local version=20220323
    local host_os="ubuntu-18.04"
    local host_arch=x86_64
    local filename="llvm-mingw-${version}-msvcrt-${host_os}-${host_arch}.tar.xz"
    local url="https://github.com/mstorsjo/llvm-mingw/releases/download/${version}/${filename}"

    install_packages xz-utils

    local td
    td="$(mktemp -d)"

    pushd "${td}"

    local root="/usr/llvm-mingw"
    mkdir -p "${root}"
    curl --retry 3 -sSfL "${url}" -O
    tar --strip-components=1 -xJf "${filename}" --directory "${root}"

    popd

    rm -rf "${td}"
    rm "${0}"
}

main "${@}"
