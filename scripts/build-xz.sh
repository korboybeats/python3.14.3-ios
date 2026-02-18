#!/usr/bin/env bash
# ==============================================================================
# Script: build-xz.sh
# Purpose: Build xz/liblzma (static library) for iOS arm64.
# ==============================================================================

set -euxo pipefail

source "$(dirname "$0")/common-env.sh"

XZ_VER="${XZ_VER:-5.6.4}"

if [ -f "$DEPS/xz-ios/usr/local/lib/liblzma.a" ]; then
  echo "Info: xz/liblzma already built. Skipping..."
  exit 0
fi

cd "$DEPS"

for i in 1 2 3 4 5; do
  curl --fail --location --show-error -LO \
    "https://github.com/tukaani-project/xz/releases/download/v${XZ_VER}/xz-${XZ_VER}.tar.gz" && break || {
    echo "Error: Download failed (attempt $i). Retrying in 3s..." >&2
    sleep 3
  }
done

[ -f "xz-${XZ_VER}.tar.gz" ] || { echo "Error: xz tarball missing." >&2; exit 1; }

tar xf "xz-${XZ_VER}.tar.gz"
cd "xz-${XZ_VER}"

./configure \
  --host="${HOST_TRIPLE}" \
  --prefix=/usr/local \
  --disable-shared \
  --enable-static \
  --disable-xz \
  --disable-xzdec \
  --disable-lzmadec \
  --disable-lzmainfo \
  --disable-scripts \
  --disable-doc

make -j"${JOBS}"
make install DESTDIR="$DEPS/xz-ios"

cd "$DEPS"
rm -rf "xz-${XZ_VER}" "xz-${XZ_VER}.tar.gz"
