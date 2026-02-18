#!/usr/bin/env bash
# ==============================================================================
# Script: common-env.sh
# Purpose: Define common environment variables and toolchain settings for iOS arm64 builds.
# ==============================================================================

set -euo pipefail

JOBS="$(sysctl -n hw.ncpu)"
MIN_IOS="${MIN_IOS:-15.0}"

WORKDIR="${WORKDIR:-$PWD/work}"
DEPS="$WORKDIR/deps"
BUILD="$WORKDIR/build"
STAGE="$WORKDIR/stage"

mkdir -p "$DEPS" "$BUILD" "$STAGE"

IOS_SDK="$(xcrun --sdk iphoneos --show-sdk-path)"
CC="$(xcrun --sdk iphoneos -f clang)"
CXX="$(xcrun --sdk iphoneos -f clang++)"
AR="$(xcrun --sdk iphoneos -f ar)"
RANLIB="$(xcrun --sdk iphoneos -f ranlib)"
STRIP="$(xcrun --sdk iphoneos -f strip)"
HOST_TRIPLE="aarch64-apple-darwin"

export CFLAGS="-arch arm64 -isysroot ${IOS_SDK} -miphoneos-version-min=${MIN_IOS} -fPIC"
export LDFLAGS="-arch arm64 -isysroot ${IOS_SDK} -miphoneos-version-min=${MIN_IOS}"

export JOBS WORKDIR DEPS BUILD STAGE IOS_SDK HOST_TRIPLE
export CC CXX AR RANLIB STRIP
