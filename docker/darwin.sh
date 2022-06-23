#!/usr/bin/env bash

set -x
set -eo pipefail

# shellcheck disable=SC1091
. lib.sh

if [[ "${MACOS_SDK_FILE}" == "nonexistent" ]] && [[ -z "${MACOS_SDK_URL}" ]]; then
    echo 'Must set the environment variable `MACOS_SDK_FILE` or `MACOS_SDK_URL`.' 1>&2
    exit 1
fi

main() {
    local commit=17bb5e2d0a46533c1dd525cf4e9a80d88bd9f00e

    install_packages curl \
        gcc \
        g++ \
        make \
        patch \
        xz-utils

    apt-get update
    apt-get install --assume-yes --no-install-recommends clang \
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
