#!/usr/bin/env bash
# shellcheck disable=SC2016

set -x
set -euo pipefail

main() {
    local arch="${1}"

    # speed up scripts by specifying wine instead of wine64
    local prefix="/opt/msvc/bin/${arch}"
    sed -i 's/wine64/wine/g' "${prefix}/wine-msvc.sh"

    # need to specifically fix cmd, so it uses windows cmd.
    echo -e '#!/usr/bin/env bash\nwine cmd "${@}"' > "${prefix}/cmd"
    echo -e '#!/usr/bin/env bash\nwine cmd "${@}"' > "${prefix}/cmd.exe"
    chmod +x "${prefix}/cmd"
    chmod +x "${prefix}/cmd.exe"

    rm "${0}"
}

main "${@}"
