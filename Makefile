
VERSION=$(shell echo `git describe --tags`)
#PREFIX=/opt/imgflo
PREFIX=$(shell echo `pwd`/install)
FLAGS=-Wall -Werror -std=c99 -g
TARGET=$(shell uname -n)

ifneq ("$(wildcard /app)","")
# Heroku build. TODO: find better way to detect
PKGCONFIG_ARGS:=--define-variable=prefix=$(PREFIX)
else
PKGCONFIG_ARGS:=
endif

LIBS=gegl-0.3 gio-unix-2.0 json-glib-1.0 libsoup-2.4 libpng
DEPS=$(shell $(PREFIX)/env.sh pkg-config $(PKGCONFIG_ARGS) --libs --cflags $(LIBS))

GNOME_SOURCES=http://ftp.gnome.org/pub/gnome/sources

GLIB_MAJOR=2.38
GLIB_VERSION=2.38.2
GLIB_TARNAME=glib-$(GLIB_VERSION)

JSON_GLIB_MAJOR=1.0
JSON_GLIB_VERSION=1.0.0
JSON_GLIB_TARNAME=json-glib-$(JSON_GLIB_VERSION)

LIBFFI_VERSION=3.0.13
LIBFFI_TARNAME=libffi-$(LIBFFI_VERSION)

INTLTOOL_MAJOR=0.40
INTLTOOL_VERSION=0.40.6
INTLTOOL_TARNAME=intltool-$(INTLTOOL_VERSION)

GETTEXT_TARNAME=gettext-0.18.2

SQLITE_TARNAME=sqlite-autoconf-3080403

all: env

install: env link-check
	cp ./examples/link-check $(PREFIX)/bin/link-check

link-check:
	$(PREFIX)/env.sh gcc -o ./examples/link-check examples/link-check.c -I. $(FLAGS) $(DEPS)

env:
	mkdir -p build || true
	mkdir -p $(PREFIX) || true
	sed -e 's|@PREFIX@|$(PREFIX)|' env.sh.in > $(PREFIX)/env.sh
	chmod +x $(PREFIX)/env.sh

sqlite: env
	cd build && curl -o $(SQLITE_TARNAME).tar.gz http://sqlite.org/2014/$(SQLITE_TARNAME).tar.gz
	cd build && tar -xf $(SQLITE_TARNAME).tar.gz
	cd build/$(SQLITE_TARNAME) && $(PREFIX)/env.sh ./configure --prefix=$(PREFIX)
	cd build/$(SQLITE_TARNAME) && $(PREFIX)/env.sh make -j4 install

intltool: env
	cd build && curl -o $(INTLTOOL_TARNAME).tar.gz $(GNOME_SOURCES)/intltool/$(INTLTOOL_MAJOR)/$(INTLTOOL_TARNAME).tar.gz
	cd build && tar -xf $(INTLTOOL_TARNAME).tar.gz
	cd build/$(INTLTOOL_TARNAME) && $(PREFIX)/env.sh ./configure --prefix=$(PREFIX)
	cd build/$(INTLTOOL_TARNAME) && $(PREFIX)/env.sh make -j4 install

gettext: env
	cd build && curl -L -O http://ftp.gnu.org/pub/gnu/gettext/$(GETTEXT_TARNAME).tar.gz
	cd build && tar -xzvf $(GETTEXT_TARNAME).tar.gz
	cd build/$(GETTEXT_TARNAME) && $(PREFIX)/env.sh ./configure --prefix=$(PREFIX)
	cd build/$(GETTEXT_TARNAME) && make -j4 install

libffi: env
	cd build && curl -o $(LIBFFI_TARNAME).tar.gz ftp://sourceware.org/pub/libffi/$(LIBFFI_TARNAME).tar.gz
	cd build && tar -xf $(LIBFFI_TARNAME).tar.gz
	cd build/$(LIBFFI_TARNAME) && $(PREFIX)/env.sh ./configure --prefix=$(PREFIX)
	cd build/$(LIBFFI_TARNAME) && $(PREFIX)/env.sh make -j4 install

json-glib: env
	cd build && curl -o $(JSON_GLIB_TARNAME).tar.xz $(GNOME_SOURCES)/json-glib/$(JSON_GLIB_MAJOR)/$(JSON_GLIB_TARNAME).tar.xz
	cd build && tar -xf $(JSON_GLIB_TARNAME).tar.xz
	cd build/$(JSON_GLIB_TARNAME) && $(PREFIX)/env.sh ./configure --prefix=$(PREFIX)
	cd build/$(JSON_GLIB_TARNAME) && $(PREFIX)/env.sh make -j4 install

glib: env
	cd build && curl -o $(GLIB_TARNAME).tar.xz $(GNOME_SOURCES)/glib/$(GLIB_MAJOR)/$(GLIB_TARNAME).tar.xz
	cd build && tar -xf $(GLIB_TARNAME).tar.xz
	cd build/$(GLIB_TARNAME) && $(PREFIX)/env.sh ./autogen.sh --prefix=$(PREFIX)
	cd build/$(GLIB_TARNAME) && $(PREFIX)/env.sh make -j4 install

babl: env
	cd babl && $(PREFIX)/env.sh ./autogen.sh --prefix=$(PREFIX)
	cd babl && $(PREFIX)/env.sh make -j4 install

gegl: env
	cp $(PREFIX)/share/aclocal/nls.m4 ./gegl/m4/ || echo "HACK to get intltool working on Heroku not used"
	cd gegl && $(PREFIX)/env.sh ./autogen.sh --prefix=$(PREFIX) --enable-workshop --without-libavformat
	cd gegl && $(PREFIX)/env.sh make -j4 install

libsoup: env
	cp $(PREFIX)/share/aclocal/nls.m4 ./libsoup/m4/ || echo "HACK to get intltool working on Heroku not used"
	cd libsoup && $(PREFIX)/env.sh ./autogen.sh --prefix=$(PREFIX) --disable-tls-check
	cd libsoup && $(PREFIX)/env.sh make -j4 install

xml-parser: env
	echo "Installing XML::Parser module"
	$(PREFIX)/env.sh /app/local/bin/cpanm --local-lib=/app/local/lib/perl5/ -f -n XML::Parser

perl-buildpack: env
	echo "Installing Perl buildpack"
	curl -L -O https://raw.github.com/miyagawa/heroku-buildpack-perl/master/bin/compile
	chmod +x ./compile
	$(PREFIX)/env.sh ./compile /app /app/cache

heroku-deps: perl-buildpack xml-parser intltool gettext libffi glib json-glib sqlite

travis-deps: glib json-glib sqlite

dependencies: babl gegl libsoup

check: install
	$(PREFIX)/env.sh $(PREFIX)/bin/link-check

clean:
	git clean -dfx --exclude node_modules --exclude install

package:
	tar -caf ../imgflo-dependencies-$(VERSION)-$(TARGET).tgz ./install

upload:
	curl --ftp-create-dirs -T imgflo-dependencies-$(VERSION)-*.tgz -u $(FTP_USER):$(FTP_PASSWORD) ftp://vps.jonnor.com/ftp/

release: dependencies check package upload

heroku-release: heroku-deps dependencies package upload

.PHONY=all link-check
