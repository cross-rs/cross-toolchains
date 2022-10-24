#!/usr/bin/env bash
# shellcheck disable=SC2016

set -x
set -euo pipefail

main() {
    # create a symlink to our sysroot to make it accessible in the dockerfile
    local sdk_version
    sdk_version=$(ls /opt/cctools/SDK)
    ln -s "/opt/cctools/SDK/${sdk_version}" "/opt/cctools/SDK/latest"

    rm "${0}"
}

main "${@}"
