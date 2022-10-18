#!/usr/bin/env bash

set -e

export HOME=/tmp/home
mkdir -p "${HOME}"

# decide if we want to use strawberry perl or the system perl
if [[ "${CROSS_WINDOWS_PERL}" == 1 ]]; then
    export PATH=/opt/bin:"${PATH}"
fi

# Initialize the wine prefix (virtual windows installation)
export WINEPREFIX=/tmp/wine
mkdir -p "${WINEPREFIX}"
# FIXME: Make the wine prefix initialization faster
wineboot &> /dev/null

exec "$@"
