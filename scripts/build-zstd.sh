#!/usr/bin/env bash
# ==============================================================================
# Script: build-zstd.sh
# Purpose: Build zstd (static library) for iOS arm64 using cmake.
# ==============================================================================

set -euxo pipefail

source "$(dirname "$0")/common-env.sh"

ZSTD_VER="${ZSTD_VER:-1.5.6}"

if [ -f "$DEPS/zstd-ios/usr/local/lib/libzstd.a" ]; then
  echo "Info: zstd already built. Skipping..."
  exit 0
fi

cd "$DEPS"

for i in 1 2 3 4 5; do
  curl --fail --location --show-error -LO \
    "https://github.com/facebook/zstd/releases/download/v${ZSTD_VER}/zstd-${ZSTD_VER}.tar.gz" && break || {
    echo "Error: Download failed (attempt $i). Retrying in 3s..." >&2
    sleep 3
  }
done

[ -f "zstd-${ZSTD_VER}.tar.gz" ] || { echo "Error: zstd tarball missing." >&2; exit 1; }

tar xf "zstd-${ZSTD_VER}.tar.gz"
cd "zstd-${ZSTD_VER}"

mkdir -p _build && cd _build

cmake ../build/cmake \
  -DCMAKE_SYSTEM_NAME=iOS \
  -DCMAKE_OSX_ARCHITECTURES=arm64 \
  -DCMAKE_OSX_SYSROOT="$IOS_SDK" \
  -DCMAKE_OSX_DEPLOYMENT_TARGET="$MIN_IOS" \
  -DCMAKE_INSTALL_PREFIX=/usr/local \
  -DCMAKE_C_COMPILER="$CC" \
  -DZSTD_BUILD_SHARED=OFF \
  -DZSTD_BUILD_PROGRAMS=OFF \
  -DZSTD_BUILD_TESTS=OFF \
  -DZSTD_BUILD_CONTRIB=OFF

make -j"${JOBS}"
make install DESTDIR="$DEPS/zstd-ios"

cd "$DEPS"
rm -rf "zstd-${ZSTD_VER}" "zstd-${ZSTD_VER}.tar.gz"
