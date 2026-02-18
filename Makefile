SHELL := /bin/bash

.PHONY: all deps python package clean distclean

all: deps python package

deps:
	bash scripts/build-openssl.sh
	bash scripts/build-libffi.sh
	bash scripts/build-xz.sh
	bash scripts/build-bzip2.sh
	bash scripts/build-zstd.sh
	bash scripts/build-ncurses.sh
	bash scripts/build-gdbm.sh

python:
	bash scripts/build-python.sh

package:
	bash scripts/package-dpkg.sh

clean:
	rm -rf work/stage work/pkgroot

distclean:
	rm -rf work
