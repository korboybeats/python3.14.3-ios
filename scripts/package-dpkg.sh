#!/usr/bin/env bash
# ==============================================================================
# Script: package-dpkg.sh
# Purpose: Package staged files into rootful and rootless .deb packages.
# ==============================================================================

set -euxo pipefail

source "$(dirname "$0")/common-env.sh"

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CONTROL_TEMPLATE="$REPO_ROOT/debian/control.in"
CHANGELOG_FILE="$REPO_ROOT/debian/changelog"
COPYRIGHT_FILE="$REPO_ROOT/debian/copyright"

build_deb() {
  local arch="$1"    # "iphoneos-arm" or "iphoneos-arm64"
  local prefix="$2"  # "" or "/var/jb"

  local PKGROOT="$WORKDIR/pkgroot-${arch}"
  rm -rf "$PKGROOT"
  mkdir -p "$PKGROOT/DEBIAN"

  # Copy staged files into package root with correct prefix
  mkdir -p "$PKGROOT${prefix}"
  cp -a "$STAGE/usr" "$PKGROOT${prefix}/usr"
  cp -a "$STAGE/etc" "$PKGROOT${prefix}/etc" 2>/dev/null || true

  INSTALLED_SIZE="$(du -sk "$PKGROOT${prefix}/usr" | awk '{print $1}')"

  sed -e "s#\${PY_VER}#${PY_VER}#g" \
      -e "s#\${INSTALLED_SIZE}#${INSTALLED_SIZE}#g" \
      -e "s#iphoneos-arm64#${arch}#g" \
      "$CONTROL_TEMPLATE" > "$PKGROOT/DEBIAN/control"

  if [ -f "$CHANGELOG_FILE" ]; then
      mkdir -p "$PKGROOT${prefix}/usr/share/doc/com.korboy.python3.14"
      gzip -9 -n -c "$CHANGELOG_FILE" > "$PKGROOT${prefix}/usr/share/doc/com.korboy.python3.14/changelog.gz"
  fi

  if [ -f "$COPYRIGHT_FILE" ]; then
      mkdir -p "$PKGROOT${prefix}/usr/share/doc/com.korboy.python3.14"
      cp "$COPYRIGHT_FILE" "$PKGROOT${prefix}/usr/share/doc/com.korboy.python3.14/copyright"
  fi

  local OUTPUT="python3.14_${PY_VER}-1_${arch}.deb"
  dpkg-deb --build --root-owner-group "$PKGROOT" "$WORKDIR/$OUTPUT"
  echo "Success: Package built at $WORKDIR/$OUTPUT"
}

# Rootful (iphoneos-arm, installs to /)
build_deb "iphoneos-arm" ""

# Rootless (iphoneos-arm64, installs to /var/jb)
build_deb "iphoneos-arm64" "/var/jb"
