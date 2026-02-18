#!/usr/bin/env bash
# ==============================================================================
# Script: build-gdbm.sh
# Purpose: Build gdbm (static library) for iOS arm64.
# ==============================================================================

set -euxo pipefail

source "$(dirname "$0")/common-env.sh"

GDBM_VER="${GDBM_VER:-1.24}"

if [ -f "$DEPS/gdbm-ios/usr/local/lib/libgdbm.a" ]; then
  echo "Info: gdbm already built. Skipping..."
  exit 0
fi

cd "$DEPS"

for i in 1 2 3 4 5; do
  curl --fail --location --show-error -LO \
    "https://ftp.gnu.org/gnu/gdbm/gdbm-${GDBM_VER}.tar.gz" && break || {
    echo "Error: Download failed (attempt $i). Retrying in 3s..." >&2
    sleep 3
  }
done

[ -f "gdbm-${GDBM_VER}.tar.gz" ] || { echo "Error: gdbm tarball missing." >&2; exit 1; }

tar xf "gdbm-${GDBM_VER}.tar.gz"
cd "gdbm-${GDBM_VER}"

./configure \
  --host="${HOST_TRIPLE}" \
  --prefix=/usr/local \
  --disable-shared \
  --enable-static \
  --without-readline \
  --enable-libgdbm-compat

make -j"${JOBS}"
make install DESTDIR="$DEPS/gdbm-ios"

cd "$DEPS"
rm -rf "gdbm-${GDBM_VER}" "gdbm-${GDBM_VER}.tar.gz"
