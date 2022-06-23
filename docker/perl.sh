#!/usr/bin/env bash
# shellcheck disable=SC2016

set -x
set -euo pipefail

# shellcheck disable=SC1091
. lib.sh

main() {
    local version="5.32.1.1"
    local home="https://strawberryperl.com/download"
    local arch="64"
    local file="strawberry-perl-${version}-${arch}bit-portable.zip"
    local url="${home}/${version}/${file}"

    install_packages wget unzip

    local td
    td="$(mktemp -d)"

    pushd "${td}"
    wget "${url}"
    unzip "${file}" -d /opt/perl

    local src="/opt/perl/perl/bin"
    local dst="/opt/bin"
    mkdir -p "${dst}"
    echo -e '#!/usr/bin/env bash\nwine '"${src}/perl.exe"' "${@}"' > "${dst}/perl"
    echo -e '#!/usr/bin/env bash\nwine '"${src}/perl.exe"' "${@}"' > "${dst}/perl.exe"
    chmod +x "${dst}/perl"
    chmod +x "${dst}/perl.exe"

    purge_packages

    popd

    rm -rf "${td}"

    rm "${0}"
}

main "${@}"
