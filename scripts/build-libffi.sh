#!/usr/bin/env bash
# ==============================================================================
# Script: build-libffi.sh
# Purpose: Build libffi (static library) for iOS arm64.
# ==============================================================================

set -euxo pipefail

source "$(dirname "$0")/common-env.sh"

if [ -f "$DEPS/libffi-ios/usr/local/lib/libffi.a" ]; then
  echo "Info: libffi already built. Skipping..."
  exit 0
fi

cd "$DEPS"

for i in 1 2 3 4 5; do
  curl --fail --location --show-error -LO \
    "https://github.com/libffi/libffi/releases/download/v${LIBFFI_VER}/libffi-${LIBFFI_VER}.tar.gz" && break || {
    echo "Error: Download failed (attempt $i). Retrying in 3s..." >&2
    sleep 3
  }
done

[ -f "libffi-${LIBFFI_VER}.tar.gz" ] || { echo "Error: libffi tarball missing." >&2; exit 1; }

tar xf "libffi-${LIBFFI_VER}.tar.gz"
cd "libffi-${LIBFFI_VER}"

./configure \
  --host="${HOST_TRIPLE}" \
  --prefix=/usr/local \
  --disable-shared \
  --enable-static

make -j"${JOBS}"
make install DESTDIR="$DEPS/libffi-ios"

cd "$DEPS"
rm -rf "libffi-${LIBFFI_VER}" "libffi-${LIBFFI_VER}.tar.gz"
