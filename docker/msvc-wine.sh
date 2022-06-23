#!/usr/bin/env bash

set -x
set -euo pipefail

# shellcheck disable=SC1091
. lib.sh

main() {
    local commit=34d9736591b691c6bdaab8e6036e1f5b47f956f5

    install_packages python3 \
        python3-pip \
        msitools \
        python3-simplejson \
        ca-certificates \
        winbind

    # python3-six takes forever
    python3 -m pip install six

    local td
    td="$(mktemp -d)"

    pushd "${td}"
    git clone https://github.com/mstorsjo/msvc-wine --depth 1
    cd msvc-wine
    git fetch --depth=1 origin "${commit}"
    git checkout "${commit}"
    python3 vsdownload.py --accept-license --dest /opt/msvc
    ./install.sh /opt/msvc

    python3 -m pip uninstall six --yes
    purge_packages

    popd

    rm -rf "${td}"
    rm "${0}"
}

main "${@}"
