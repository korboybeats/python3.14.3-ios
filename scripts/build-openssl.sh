#!/usr/bin/env bash
# ==============================================================================
# Script: build-openssl.sh
# Purpose: Build OpenSSL 3.2 (static) for iOS arm64.
#          Python 3.13 requires OpenSSL 3.x (dropped 1.1.1 support).
# ==============================================================================

set -euxo pipefail

source "$(dirname "$0")/common-env.sh"

if [ -f "$DEPS/openssl-ios/usr/local/lib/libcrypto.a" ] && [ -f "$DEPS/openssl-ios/usr/local/lib/libssl.a" ]; then
  echo "Info: OpenSSL already built. Skipping..."
  exit 0
fi

cd "$DEPS"

OPENSSL_VER="${OPENSSL_VER:-3.2.3}"
OPENSSL_TAR="openssl-${OPENSSL_VER}.tar.gz"

if [ ! -d "openssl-${OPENSSL_VER}" ]; then
  for i in 1 2 3 4 5; do
    curl --fail --location --show-error -LO \
      "https://github.com/openssl/openssl/releases/download/openssl-${OPENSSL_VER}/${OPENSSL_TAR}" && break || {
      echo "Error: Download failed (attempt $i). Retrying in 3s..." >&2
      sleep 3
    }
  done

  [ -f "${OPENSSL_TAR}" ] || { echo "Error: OpenSSL tarball missing." >&2; exit 1; }
  tar xf "${OPENSSL_TAR}"
fi

cd "openssl-${OPENSSL_VER}"

export CROSS_TOP="$(xcrun --sdk iphoneos --show-sdk-platform-path)/Developer"
export CROSS_SDK="$(basename "${IOS_SDK}")"

./Configure ios64-xcrun no-tests no-shared --prefix=/usr/local

make -j"${JOBS}"
make install_sw DESTDIR="$DEPS/openssl-ios"

cd "$DEPS"
rm -rf "openssl-${OPENSSL_VER}" "${OPENSSL_TAR}"
