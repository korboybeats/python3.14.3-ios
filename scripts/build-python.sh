#!/usr/bin/env bash
# ==============================================================================
# Script: build-python.sh
# Purpose: Build CPython 3.14 for iOS arm64.
# ==============================================================================

set -euxo pipefail

source "$(dirname "$0")/common-env.sh"

cd "$BUILD"

if [ -z "${PYTHON_FOR_BUILD:-}" ]; then
    echo "Error: PYTHON_FOR_BUILD is not set." >&2
    echo "Please set it to the path of a host python3 interpreter." >&2
    exit 1
fi
if [ ! -x "$PYTHON_FOR_BUILD" ]; then
    echo "Error: PYTHON_FOR_BUILD='$PYTHON_FOR_BUILD' is not executable." >&2
    exit 1
fi

# Download CPython source
for i in 1 2 3 4 5; do
  curl --fail --location --show-error -LO \
    "https://www.python.org/ftp/python/${PY_VER}/Python-${PY_VER}.tgz" && break || {
    echo "Error: Download failed (attempt $i). Retrying in 3s..." >&2
    sleep 3
  }
done

[ -f "Python-${PY_VER}.tgz" ] || { echo "Error: Python tarball missing." >&2; exit 1; }

tar xf "Python-${PY_VER}.tgz"
cd "Python-${PY_VER}"

# Disable modules that don't work on iOS
cat > Modules/Setup.local <<'EOF'
*disabled*
 nis
_tkinter
_scproxy
EOF

# Patch _remote_debugging module to include missing header on iOS
if [ -f Modules/_remote_debugging/module.c ]; then
  sed -i.bak '1s/^/#include <unistd.h>\n/' Modules/_remote_debugging/module.c
elif [ -f Modules/_remote_debugging_module.c ]; then
  sed -i.bak '1s/^/#include <unistd.h>\n/' Modules/_remote_debugging_module.c
fi

REPO_ROOT="$(cd "$(dirname "$WORKDIR")" && pwd)"
VENDOR_DIR="$REPO_ROOT/vendor/gnu-config"

# Patch configure to allow cross-compilation for iOS
# Python 3.14 may have "cross build not supported" checks — replace with no-ops
sed -i.bak 's/as_fn_error \$? "cross build not supported for \$host"/: # allow iOS cross build/' configure
grep -n 'cross build not supported' configure && { echo "Error: patch did not apply"; exit 1; } || echo "Patched configure successfully"

# Pre-define answers for configure checks that fail during cross-compilation
cat > config.site <<'EOF'
ac_cv_file__dev_ptc=no
ac_cv_file__dev_ptmx=no

ac_cv_func_system=no
ac_cv_func_pipe2=no
ac_cv_func_forkpty=no
ac_cv_func_openpty=no

ac_cv_func_sendfile=no
ac_cv_func_preadv=no
ac_cv_func_pwritev=no
ac_cv_func_getentropy=no
ac_cv_func_utimensat=no
ac_cv_func_posix_fallocate=no
ac_cv_func_clock_settime=no

ac_cv_header_rpcsvc_yp_prot_h=no
ac_cv_header_rpcsvc_ypclnt_h=no
ac_cv_header_rpcsvc_rpcsvc_h=no
ac_cv_func_yp_get_default_domain=no
ac_cv_lib_nsl_yp_get_default_domain=no
ac_cv_have_nis=no

ac_cv_func_getaddrinfo=yes
ac_cv_working_getaddrinfo=yes
ac_cv_buggy_getaddrinfo=no
ac_cv_func_getnameinfo=yes

# sizeof values for arm64 iOS (LP64)
ac_cv_sizeof_int=4
ac_cv_sizeof_long=8
ac_cv_sizeof_long_long=8
ac_cv_sizeof_void_p=8
ac_cv_sizeof_short=2
ac_cv_sizeof_float=4
ac_cv_sizeof_double=8
ac_cv_sizeof_fpos_t=8
ac_cv_sizeof_size_t=8
ac_cv_sizeof_pid_t=4
ac_cv_sizeof_off_t=8
ac_cv_sizeof_time_t=8
ac_cv_sizeof_wchar_t=4
ac_cv_sizeof_uintptr_t=8
ac_cv_sizeof_pthread_t=8
ac_cv_sizeof_pthread_key_t=8
ac_cv_sizeof__Bool=1
ac_cv_sizeof_mode_t=2
ac_cv_sizeof_uid_t=4
ac_cv_sizeof_gid_t=4
ac_cv_sizeof_dev_t=4
ac_cv_sizeof_ino_t=8
ac_cv_sizeof_nlink_t=2
ac_cv_sizeof_ssize_t=8

# alignof values for arm64
ac_cv_alignof_long=8
ac_cv_alignof_size_t=8
ac_cv_alignof_max_align_t=8

# type checks
ac_cv_type_uid_t=yes
ac_cv_type_ssize_t=yes
ac_cv_type___uint128_t=yes
ac_cv_c_char_unsigned=no
EOF
export CONFIG_SITE="$PWD/config.site"

# Set compiler flags for dependencies
# -Wno-unguarded-availability: suppress iOS SDK marking ffi symbols as unavailable
# (we link against our own libffi, not the SDK's)
export CPPFLAGS="\
-I$DEPS/openssl-ios/usr/local/include \
-I$DEPS/libffi-ios/usr/local/include \
-I$DEPS/xz-ios/usr/local/include \
-I$DEPS/bzip2-ios/usr/local/include \
-I$DEPS/zstd-ios/usr/local/include \
-I$DEPS/ncurses-ios/usr/local/include \
-I$DEPS/ncurses-ios/usr/local/include/ncursesw \
-I$DEPS/gdbm-ios/usr/local/include"

export CFLAGS="${CFLAGS} -Wno-unguarded-availability"

export LDFLAGS="\
-L$DEPS/openssl-ios/usr/local/lib \
-L$DEPS/libffi-ios/usr/local/lib \
-L$DEPS/xz-ios/usr/local/lib \
-L$DEPS/bzip2-ios/usr/local/lib \
-L$DEPS/zstd-ios/usr/local/lib \
-L$DEPS/ncurses-ios/usr/local/lib \
-L$DEPS/gdbm-ios/usr/local/lib \
${LDFLAGS}"

export LIBS="-lssl -lcrypto"

export PKG_CONFIG_PATH="\
$DEPS/libffi-ios/usr/local/lib/pkgconfig:\
$DEPS/openssl-ios/usr/local/lib/pkgconfig:\
$DEPS/xz-ios/usr/local/lib/pkgconfig:\
$DEPS/zstd-ios/usr/local/lib/pkgconfig:\
$DEPS/ncurses-ios/usr/local/lib/pkgconfig:\
${PKG_CONFIG_PATH:-}"

export LD="$CC"
export LDSHARED="$CC -bundle -undefined dynamic_lookup $LDFLAGS"
export LDCXXSHARED="$CXX -bundle -undefined dynamic_lookup $LDFLAGS"

./configure \
  --host="${HOST_TRIPLE}" \
  --build="$(uname -m)-apple-darwin" \
  --prefix=/usr/local \
  --with-build-python="${PYTHON_FOR_BUILD}" \
  --with-openssl="$DEPS/openssl-ios/usr/local" \
  --with-ensurepip=install \
  --disable-test-modules

# Fix _ctypes to use our libffi instead of Apple's system libffi.
# Python's configure detects Apple's libffi and adds -DUSING_APPLE_OS_LIBFFI=1
# with macOS SDK ffi headers that mark symbols __IOS_UNAVAILABLE.
sed -i.bak 's/-DUSING_APPLE_OS_LIBFFI=1//g' Makefile
sed -i.bak "s|-I[^ ]*/MacOSX[^ ]*/usr/include/ffi|-I$DEPS/libffi-ios/usr/local/include|g" Makefile

# Patch Makefile to skip checksharedmods (fails during cross-compilation)
awk 'BEGIN{skip=0}
  /^checksharedmods:/{print "checksharedmods:\n\t@true"; skip=1; next}
  skip && (/^\t/ || /^[[:space:]]*$/){next}
  skip {skip=0}
  {print}
' Makefile > Makefile.new && mv Makefile.new Makefile

make -j"${JOBS}"
make install ENSUREPIP=no DESTDIR="$STAGE"

cd "$BUILD"
rm -f "Python-${PY_VER}.tgz"

# Patch urllib.request to not crash on iOS when _scproxy is unavailable.
# _scproxy is macOS-only but sys.platform == 'darwin' is true on iOS.
"$PYTHON_FOR_BUILD" -c "
import pathlib
p = pathlib.Path('$STAGE/usr/local/lib/python3.14/urllib/request.py')
t = p.read_text()
t = t.replace(
    'from _scproxy import _get_proxy_settings, _get_proxies',
    '''try:
        from _scproxy import _get_proxy_settings, _get_proxies
    except ImportError:
        def _get_proxy_settings(): return {}
        def _get_proxies(): return {}'''
)
p.write_text(t)
"

# Fix stdout/stderr for jailbroken iOS terminal use.
# Python 3.14 redirects them to Apple os_log by default, which breaks SSH/terminal.
cat > "$STAGE/usr/local/lib/python3.14/sitecustomize.py" <<'PYEOF'
import sys
import os
import io

# On jailbroken iOS, restore real stdout/stderr when running in a terminal
# (not an iOS app). Python 3.14 redirects them to Apple os_log by default.
if hasattr(sys.stdout, "__class__") and sys.stdout.__class__.__name__ == "SystemLog":
    try:
        sys.stdout = io.TextIOWrapper(
            io.FileIO(1, "w", closefd=False),
            encoding="utf-8", line_buffering=True
        )
        sys.stderr = io.TextIOWrapper(
            io.FileIO(2, "w", closefd=False),
            encoding="utf-8", line_buffering=True
        )
    except Exception:
        pass

# Shorten the resolved preboot path back to /var/jb in sys paths.
# On rootless jailbreaks, /var/jb is a symlink to a long preboot UUID path.
if os.path.islink("/var/jb"):
    _preboot = os.path.realpath("/var/jb")
    for _attr in ("prefix", "exec_prefix", "base_prefix", "base_exec_prefix"):
        _val = getattr(sys, _attr, "")
        if _val.startswith(_preboot):
            setattr(sys, _attr, "/var/jb" + _val[len(_preboot):])
    sys.path = [
        "/var/jb" + p[len(_preboot):] if p.startswith(_preboot) else p
        for p in sys.path
    ]
    del _preboot, _attr, _val
PYEOF

# Remove unversioned files/symlinks so multiple Python versions can coexist
rm -f "$STAGE/usr/local/bin/python3"
rm -f "$STAGE/usr/local/bin/python3-config"
rm -f "$STAGE/usr/local/bin/idle3"
rm -f "$STAGE/usr/local/bin/pip3"
rm -f "$STAGE/usr/local/bin/pydoc3"
rm -f "$STAGE/usr/local/bin/2to3"
rm -f "$STAGE/usr/local/bin/python"
rm -f "$STAGE/usr/local/bin/pip"
# Remove unversioned pkgconfig files
rm -f "$STAGE/usr/local/lib/pkgconfig/python3.pc"
rm -f "$STAGE/usr/local/lib/pkgconfig/python3-embed.pc"
# Remove unversioned man pages
rm -f "$STAGE/usr/local/share/man/man1/python3.1"
# Remove any other unversioned symlinks in bin that could conflict
find "$STAGE/usr/local/bin" -maxdepth 1 -type l | while read -r link; do
  name="$(basename "$link")"
  case "$name" in *3.14*) ;; *) rm -f "$link" ;; esac
done

# Strip debug symbols
echo "Stripping binaries..."
find "$STAGE" -type f \( -name "*.dylib" -o -name "*.so" -o -path "$STAGE/usr/local/bin/*" \) | while read -r f; do
    if file -b "$f" | grep -q 'Mach-O'; then
        "$STRIP" -x "$f" || echo "Warning: strip failed on $f" >&2
    fi
done

# Sign binaries with entitlements
ENTITLEMENTS="$REPO_ROOT/scripts/entitlements.plist"
while IFS= read -r -d '' f; do
  if file -b "$f" | grep -q 'Mach-O'; then
    ldid -S"$ENTITLEMENTS" "$f" || echo "Warning: ldid failed on $f" >&2
  fi
done < <(find "$STAGE" -type f \( -name "*.dylib" -o -name "*.so" -o -path "$STAGE/usr/local/bin/*" \) -print0)
