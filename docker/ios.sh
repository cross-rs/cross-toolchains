#!/usr/bin/env bash
# Adapted from cctools-port
#   https://github.com/tpoechtrager/cctools-port/tree/master/usage_examples/ios_toolchain
# This code is public domain
#   https://github.com/tpoechtrager/cctools-port/issues/21#issuecomment-223382676

set -x
set -eo pipefail

# shellcheck disable=SC1091
. lib.sh

if [[ "${IOS_SDK_FILE}" == "nonexistent" ]] && [[ -z "${IOS_SDK_URL}" ]]; then
    echo 'Must set the environment variable `IOS_SDK_FILE` or `IOS_SDK_URL`.' 1>&2
    exit 1
fi

get_sdk_version() {
    local version
    version=$(echo "${1}" | grep -P -o "[0-9][0-9].[0-9]+" | head -1)
    if [ -z "${version}" ]; then
        version=$(echo "${1}" | grep -P -o "[0-9].[0-9]+" | head -1)
    fi
    if [ -z "${version}" ]; then
        echo "iPhoneOS Version must be in the SDK filename!" 1>&2
        exit 1
    fi

    echo "${version}"
}

extract() {
    local tarball="${1}"
    local outdir="${2}"
    mkdir -p "${outdir}"

    case $1 in
        *.tar.xz|*.txz)
            tar -xJf "${tarball}" --directory "${2}"
            ;;
        *.tar.gz|*.tgz)
            tar -xzf "${tarball}" --directory "${2}"
            ;;
        *.tar.bz2|*.tbz2)
            tar -xjf "${tarball}" --directory "${2}"
            ;;
        *)
            echo "unhandled archive type" 1>&2
            exit 1
            ;;
    esac
}

main() {
    local target="${1}"
    local target_cpu="${2}"
    local ldid_commit="4bf8f4d60384a0693dbbe2084ce62a35bfeb87ab"
    local libdispatch_commit="a102d19751cfa81f22d1ea5c71c8d1d985a71417"
    local libtapi_commit="b8c5ac40267aa5f6004dd38cc2b2cd84f2d9d555"
    local cctools_commit="a98286d858210b209395624477533c0bde05556a"
    local install_dir="/opt/cctools"
    local sdk_dir="${install_dir}"/SDK

    install_packages curl \
        gcc \
        g++ \
        make

    apt-get update
    apt-get install --assume-yes --no-install-recommends clang \
        libbz2-dev \
        libssl-dev \
        libxml2-dev \
        zlib1g-dev \
        xz-utils \
        llvm-dev \
        uuid-dev \
        libstdc++-10-dev

    local td
    td="$(mktemp -d)"
    pushd "${td}"

    # first, extract the SDK and get the version.
    mkdir sdk
    pushd sdk
    if [[ -f /"${IOS_SDK_FILE}" ]]; then
        cp /"${IOS_SDK_FILE}" .
    else
        curl --retry 3 -sSfL "${IOS_SDK_URL}" -O
    fi
    filename=$(ls -t -1 . | head -1)
    sdk_version=$(get_sdk_version "${filename}")
    extract "${filename}" SDK

    # now, need to get our metadata, and move the SDK to the output dir
    mkdir -p "${install_dir}"
    mv SDK "${sdk_dir}"
    local syslib
    syslib=$(find "${sdk_dir}" -name libSystem.dylib -o -name libSystem.tbd | head -n1)
    local wrapper_sdkdir
    pushd "${sdk_dir}"
    wrapper_sdkdir=$(echo iPhoneOS*sdk | head -n1)
    popd
    popd

    mkdir -p ios-wrapper
    pushd ios-wrapper
    cp /ios-wrapper.c .
    # want targets like armv7s, arm64
    mkdir -p "${install_dir}/bin"
    local clang="${install_dir}/bin/${target}-clang"
    gcc -O2 -Wall -Wextra -pedantic ios-wrapper.c \
        -DSDK_DIR="\"${wrapper_sdkdir}\"" \
        -DTARGET_CPU="\"${target_cpu}"\" \
        -DOS_VER_MIN="\"${sdk_version}"\" \
        -o "${clang}"
    popd

    # build our apple dependencies
    git clone https://github.com/tpoechtrager/ldid.git --depth 1
    pushd ldid
    git fetch --depth=1 origin "${ldid_commit}"
    make INSTALLPREFIX="${install_dir}" -j install
    popd

    git clone https://github.com/tpoechtrager/apple-libtapi.git --depth 1
    pushd apple-libtapi
    git fetch --depth=1 origin "${libtapi_commit}"
    INSTALLPREFIX="${install_dir}" ./build.sh
    ./install.sh
    popd

    git clone https://github.com/apple/swift-corelibs-libdispatch.git --depth 1
    pushd swift-corelibs-libdispatch
    git fetch --depth=1 origin "${libdispatch_commit}"
    CC=clang CXX=clang++ cmake \
	-DCMAKE_BUILD_TYPE=RELEASE \
	-DCMAKE_INSTALL_PREFIX=${install_dir}
    make install
    popd

    # valid targets include `aarch64-apple-ios`
    git clone https://github.com/tpoechtrager/cctools-port.git --depth 1
    pushd cctools-port/cctools
    git fetch --depth=1 origin "${cctools_commit}"
    ./configure \
        --prefix="${install_dir}" \
        --with-libtapi="${install_dir}" \
        --with-libdispatch="${install_dir}" \
        --with-libblocksruntime="${install_dir}" \
        --target="${target}"
    make -j
    make install
    popd

    # make a symlink since clang is both a c and c++ compiler
    ln -sf "${clang}" "${clang}"++

    # need a fake wrapper for xcrun, which is used by `cc`.
    echo '#!/usr/bin/env sh
echo "${SDKROOT}"
' > "${install_dir}/bin/xcrun"
chmod +x "${install_dir}/bin/xcrun"

    purge_packages

    popd

    rm -rf "${td}"
    rm ios-wrapper.c
    rm "${0}"
}

main "${@}"
