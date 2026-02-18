# Python 3.14.3 for iOS

[![Build Status](https://github.com/korboybeats/python3.14.3-ios/actions/workflows/build.yml/badge.svg)](https://github.com/korboybeats/python3.14.3-ios/actions)
[![License](https://img.shields.io/github/license/korboybeats/python3.14.3-ios)](LICENSE)
[![iOS](https://img.shields.io/badge/iOS-15.0%2B-black?logo=apple)](https://apple.com)

Cross-compiled **Python 3.14.3** for jailbroken iOS devices (arm64). Produces rootful and rootless `.deb` packages via GitHub Actions CI.

## Features

- **Python 3.14.3** with full standard library
- **SSL/TLS** via OpenSSL 3.2.3
- **ctypes/FFI** via libffi 3.4.4
- **lzma** compression via xz/liblzma 5.6.4
- **bz2** compression via bzip2 1.0.8
- **zstd** compression via zstandard 1.5.6
- **curses** terminal UI via ncurses 6.5
- **dbm/gdbm** database via gdbm 1.24
- **pip** available via `python3.14 -m ensurepip`
- **Multi-version safe** - coexists alongside Python 3.12, 3.13, or other versions
- **Terminal-ready** - stdout/stderr patched for SSH/terminal use on jailbroken iOS

## Installation

Download the latest `.deb` from [Releases](https://github.com/korboybeats/python3.14.3-ios/actions) (Actions artifacts).

- **Rootless** (Dopamine, etc.): `python3.14_3.14.3-1_iphoneos-arm64.deb`
- **Rootful** (unc0ver, etc.): `python3.14_3.14.3-1_iphoneos-arm.deb`

Install via terminal:

```bash
dpkg -i python3.14_3.14.3-1_iphoneos-arm64.deb
```

### Post-Installation

Install pip:

```bash
python3.14 -m ensurepip
```

Verify:

```bash
python3.14 --version
python3.14 -c "import lzma, bz2, curses, dbm, ctypes, compression.zstd"
```

## Building

### GitHub Actions (recommended)

1. Fork or clone the repo
2. Go to Actions > "Build Python 3.14.3 for iOS" > Run workflow
3. Download the `.deb` artifacts when complete

### Local Build (macOS)

Requires Xcode Command Line Tools and Homebrew.

```bash
git clone https://github.com/korboybeats/python3.14.3-ios.git
cd python3.14.3-ios

export PY_VER=3.14.3
export LIBFFI_VER=3.4.4
export OPENSSL_VER=3.2.3
export XZ_VER=5.6.4
export BZ2_VER=1.0.8
export ZSTD_VER=1.5.6
export NCURSES_VER=6.5
export GDBM_VER=1.24
export MIN_IOS=15.0
export PYTHON_FOR_BUILD=$(which python3.14 || which python3)

make all
```

Output `.deb` files will be in `work/`.

## Project Structure

```
scripts/
  common-env.sh          # Shared env vars, SDK discovery, compiler flags
  install-build-tools.sh # Install ldid, dpkg, automake, etc.
  build-openssl.sh       # Cross-compile OpenSSL 3.2.3 for iOS
  build-libffi.sh        # Cross-compile libffi 3.4.4 for iOS
  build-xz.sh            # Cross-compile xz/liblzma 5.6.4 for iOS
  build-bzip2.sh         # Cross-compile bzip2 1.0.8 for iOS
  build-zstd.sh          # Cross-compile zstd 1.5.6 for iOS
  build-ncurses.sh       # Cross-compile ncurses 6.5 for iOS
  build-gdbm.sh          # Cross-compile gdbm 1.24 for iOS
  build-python.sh        # Cross-compile CPython 3.14.3 for iOS
  package-dpkg.sh        # Package rootful + rootless .deb
  entitlements.plist     # iOS code signing entitlements
debian/
  control.in             # Package metadata template
  changelog              # Package changelog
  copyright              # License info
```

## Credits

- [Python Software Foundation](https://python.org) - CPython
- [k1tty-xz/python3.12-ios-arm64](https://github.com/k1tty-xz/python3.12-ios-arm64) - Reference build system

## License

MIT License. See [LICENSE](LICENSE) for details.
