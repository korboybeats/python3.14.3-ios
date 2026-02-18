#!/usr/bin/env bash
# ==============================================================================
# Script: build-ncurses.sh
# Purpose: Build ncurses (static library) for iOS arm64.
# ==============================================================================

set -euxo pipefail

source "$(dirname "$0")/common-env.sh"

NCURSES_VER="${NCURSES_VER:-6.5}"

if [ -f "$DEPS/ncurses-ios/usr/local/lib/libncursesw.a" ]; then
  echo "Info: ncurses already built. Skipping..."
  exit 0
fi

cd "$DEPS"

for i in 1 2 3 4 5; do
  curl --fail --location --show-error -LO \
    "https://ftp.gnu.org/gnu/ncurses/ncurses-${NCURSES_VER}.tar.gz" && break || {
    echo "Error: Download failed (attempt $i). Retrying in 3s..." >&2
    sleep 3
  }
done

[ -f "ncurses-${NCURSES_VER}.tar.gz" ] || { echo "Error: ncurses tarball missing." >&2; exit 1; }

tar xf "ncurses-${NCURSES_VER}.tar.gz"
cd "ncurses-${NCURSES_VER}"

ac_cv_header_sys_ttydev_h=no cf_cv_sys_ttydev_h=no CPP="$CC -E $CFLAGS" ./configure \
  --host="${HOST_TRIPLE}" \
  --prefix=/usr/local \
  --without-shared \
  --with-normal \
  --without-debug \
  --enable-widec \
  --without-ada \
  --without-tests \
  --without-cxx-binding \
  --without-manpages \
  --without-progs \
  --enable-pc-files \
  --with-pkg-config-libdir=/usr/local/lib/pkgconfig

# iOS SDK lacks sys/ttydev.h — delete the include line
sed -i '' '/sys\/ttydev/d' ncurses/tinfo/lib_baudrate.c

# Insert termios.h + fallback baud rate defines before the DATA macro
# (curses.priv.h include regex may not match, so target DATA which is unique)
perl -0777 -pi -e '
  my @speeds = (0,50,75,110,134,150,200,300,600,1200,1800,2400,4800,9600,19200,38400);
  my $defs = "#include <termios.h>\n";
  for my $s (@speeds) { $defs .= "#ifndef B$s\n#define B$s $s\n#endif\n"; }
  s/^(#define DATA)/$defs$1/m;
' ncurses/tinfo/lib_baudrate.c

# Verify patch was applied
grep -q 'ifndef B0' ncurses/tinfo/lib_baudrate.c || { echo "Error: baud rate patch failed"; exit 1; }

make -j"${JOBS}"
make install.libs install.includes DESTDIR="$DEPS/ncurses-ios"

cd "$DEPS"
rm -rf "ncurses-${NCURSES_VER}" "ncurses-${NCURSES_VER}.tar.gz"
