#!/usr/bin/env bash

set -x
set -eo pipefail

# shellcheck disable=SC1091
. lib.sh

if [[ "${MACOS_SDK_FILE}" == "nonexistent" ]] && [[ -z "${MACOS_SDK_URL}" ]]; then
    echo 'Must set the environment variable `MACOS_SDK_FILE` or `MACOS_SDK_URL`.' 1>&2
    exit 1
fi

die() {
    printf 1>&2 "%s\n" "${@}"
    exit 1
}

install_llvm() {
    [ "${#}" -eq 1 ] || die "No version provided"

    declare -r generated_tmp_dir=$(mktemp -d -t)
    declare -r llvm_version="${1}"

    pushd "${generated_tmp_dir}"

    curl -LO https://apt.llvm.org/llvm.sh
    chmod +x llvm.sh
    ./llvm.sh "${llvm_version}"

    popd

    rm -rf "${generated_tmp_dir}"

    ln -s /usr/bin/clang-${llvm_version} /usr/bin/clang
    ln -s /usr/bin/clang++-${llvm_version} /usr/bin/clang++
}

main() {
    # http://github.com/tpoechtrager/osxcross/commit/aa4c5eac89df6ccaf2e28fbc6332ab6893047c3b
    # adds support for compiling up to SDK version 26
    local commit=aa4c5eac89df6ccaf2e28fbc6332ab6893047c3b

    # lsb-release: Needed for fetching version of OS in llvm.sh
    # software-properties-common: Required by llvm.sh
    # gnupg: Required by llvm.sh
    # bzip2: Need bzip2 for unzipping .bz2 files.
    install_packages curl \
        gcc \
        g++ \
        make \
        patch \
        xz-utils \
        python3 \
        lsb-release \
        software-properties-common \
        gnupg \
        bzip2

    # The Clang version shipped with the apt package registry for
    # Ubuntu 20.04 is too old to compile the test files that includes
    # the macOS SDK. Need to at least bump it up to major version 16.
    install_llvm 16

    apt-get update
    apt-get install --assume-yes --no-install-recommends \
        libmpc-dev \
        libmpfr-dev \
        libgmp-dev \
        libssl-dev \
        libxml2-dev \
        zlib1g-dev

    local td
    td="$(mktemp -d)"

    pushd "${td}"
    git clone https://github.com/tpoechtrager/osxcross --depth 1
    cd osxcross
    git fetch --depth=1 origin "${commit}"
    git checkout "${commit}"

    if [[ -f /"${MACOS_SDK_FILE}" ]]; then
        cp /"${MACOS_SDK_FILE}" tarballs/
    else
        pushd tarballs
        curl --retry 3 -sSfL "${MACOS_SDK_URL}" -O
        popd
    fi

    mkdir -p /opt/osxcross
    TARGET_DIR=/opt/osxcross UNATTENDED=yes OSX_VERSION_MIN=10.7 ./build.sh

    purge_packages

    popd

    rm -rf "${td}"
    rm "${0}"
}

main "${@}"
