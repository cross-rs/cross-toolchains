#!/usr/bin/env bash

set -x
set -euo pipefail

main() {
    local arch="${1}"

    # need to create scripts to speed up compilation, since binfmt is slow
    # the use of wine64 is also super slow, so we want our own wrappers.
    local src="/opt/msvc/bin/${arch}"
    local dst="/usr/local/bin"
    local srcf
    local dstf
    for srcf in "$src"/*.exe; do
        dstf=$(basename "${srcf}")
        echo -e '#!/usr/bin/env bash\nwine '"${srcf}"' "${@}"' > "${dst}/${dstf}"
        chmod +x "${dst}/${dstf}"
    done

    rm "${0}"
}

main "${@}"
