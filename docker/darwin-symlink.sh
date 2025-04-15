#!/usr/bin/env bash
# shellcheck disable=SC2012,SC2016

set -x
set -euo pipefail

main() {
    # create a symlink to our sysroot to make it accessible in the dockerfile
    local sdk_version
    sdk_version=$(ls -t -1 /opt/osxcross/SDK | head -1)
    ln -s "/opt/osxcross/SDK/${sdk_version}" "/opt/osxcross/SDK/latest"

    rm "${0}"
}

main "${@}"
