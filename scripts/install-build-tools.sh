#!/usr/bin/env bash
# ==============================================================================
# Script: install-build-tools.sh
# Purpose: Install required build tools via Homebrew (macOS CI runner).
# ==============================================================================

set -euxo pipefail

export HOMEBREW_NO_AUTO_UPDATE=1
export HOMEBREW_NO_INSTALL_CLEANUP=1

FORMULAE=(dpkg ldid autoconf automake libtool pkg-config coreutils gnu-sed cmake nasm yasm git wget gpatch)

for f in "${FORMULAE[@]}"; do
  if brew list --formula | grep -qx "${f}"; then
    echo "Info: ${f} is already installed. Skipping..."
  else
    brew install "${f}"
  fi
done
