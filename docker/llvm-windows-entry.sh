#!/usr/bin/env bash

set -e

export HOME=/tmp/home
mkdir -p "${HOME}"

# Initialize the wine prefix (virtual windows installation)
export WINEPREFIX=/tmp/wine
mkdir -p "${WINEPREFIX}"
# FIXME: Make the wine prefix initialization faster
wineboot &> /dev/null

export WINEPATH="/usr/bin/llvm-mingw/${CROSS_WINE_ARCH}/bin"

exec "$@"
