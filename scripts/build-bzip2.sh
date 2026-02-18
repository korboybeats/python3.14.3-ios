#!/usr/bin/env bash
# ==============================================================================
# Script: build-bzip2.sh
# Purpose: Build bzip2 (static library) for iOS arm64.
#          bzip2 uses a plain Makefile (no configure script).
# ==============================================================================

set -euxo pipefail

source "$(dirname "$0")/common-env.sh"

BZ2_VER="${BZ2_VER:-1.0.8}"

if [ -f "$DEPS/bzip2-ios/usr/local/lib/libbz2.a" ]; then
  echo "Info: bzip2 already built. Skipping..."
  exit 0
fi

cd "$DEPS"

for i in 1 2 3 4 5; do
  curl --fail --location --show-error -LO \
    "https://sourceware.org/pub/bzip2/bzip2-${BZ2_VER}.tar.gz" && break || {
    echo "Error: Download failed (attempt $i). Retrying in 3s..." >&2
    sleep 3
  }
done

[ -f "bzip2-${BZ2_VER}.tar.gz" ] || { echo "Error: bzip2 tarball missing." >&2; exit 1; }

tar xf "bzip2-${BZ2_VER}.tar.gz"
cd "bzip2-${BZ2_VER}"

make CC="$CC" AR="$AR" RANLIB="$RANLIB" CFLAGS="$CFLAGS" libbz2.a -j"${JOBS}"

# Manual install (bzip2 has no configure/install target for just the library)
mkdir -p "$DEPS/bzip2-ios/usr/local/lib"
mkdir -p "$DEPS/bzip2-ios/usr/local/include"
cp libbz2.a "$DEPS/bzip2-ios/usr/local/lib/"
cp bzlib.h "$DEPS/bzip2-ios/usr/local/include/"

cd "$DEPS"
rm -rf "bzip2-${BZ2_VER}" "bzip2-${BZ2_VER}.tar.gz"
