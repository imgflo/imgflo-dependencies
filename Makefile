
VERSION=$(shell echo `git describe --tags`)
#PREFIX=/opt/imgflo
PREFIX=$(shell echo `pwd`/install)
FLAGS=-Wall -Werror -std=c99 -g
TARGET=$(shell uname -n)

ifneq ("$(wildcard /app)","")
# Heroku build. TODO: find better way to detect
RELOCATE_DEPS:=true
endif

ifdef RELOCATE_DEPS
PKGCONFIG_ARGS:=--define-variable=prefix=$(PREFIX)
else
PKGCONFIG_ARGS:=
endif

LIBS=gegl-0.3 gio-unix-2.0 json-glib-1.0 libsoup-2.4 libpng
DEPS=$(shell $(PREFIX)/env.sh pkg-config $(PKGCONFIG_ARGS) --libs --cflags $(LIBS))

GNOME_SOURCES=http://ftp.gnome.org/pub/gnome/sources
KERNEL_SOURCES=https://www.kernel.org/pub/linux

GLIB_MAJOR=2.42
GLIB_VERSION=2.42.1
GLIB_TARNAME=glib-$(GLIB_VERSION)

LIBSOUP_MAJOR=2.50
LIBSOUP_VERSION=2.50.0
LIBSOUP_TARNAME=libsoup-$(LIBSOUP_VERSION)

JSON_GLIB_MAJOR=1.0
JSON_GLIB_VERSION=1.0.2
JSON_GLIB_TARNAME=json-glib-$(JSON_GLIB_VERSION)

LIBFFI_VERSION=3.0.13
LIBFFI_TARNAME=libffi-$(LIBFFI_VERSION)

INTLTOOL_MAJOR=0.40
INTLTOOL_VERSION=0.40.6
INTLTOOL_TARNAME=intltool-$(INTLTOOL_VERSION)

GETTEXT_TARNAME=gettext-0.18.2

SQLITE_TARNAME=sqlite-autoconf-3080403

UUID_MAJOR=2.24
UUID_TARNAME=util-linux-2.24.2

GEGL_OPTIONS=--enable-workshop --without-libavformat --without-libv4l --without-umfpack

all: env

install: env link-check
	cp ./examples/link-check $(PREFIX)/bin/link-check

link-check:
	$(PREFIX)/env.sh gcc -o ./examples/link-check examples/link-check.c -I. $(FLAGS) $(DEPS)

env:
	mkdir -p build || true
	mkdir -p $(PREFIX)/bin || true
	sed -e 's|@PREFIX@|$(PREFIX)|' env.sh.in > $(PREFIX)/env.sh
	chmod +x $(PREFIX)/env.sh

uuid: env
	cd build && curl -O $(KERNEL_SOURCES)/utils/util-linux/v$(UUID_MAJOR)/$(UUID_TARNAME).tar.gz
	cd build && tar -xf $(UUID_TARNAME).tar.gz
	cd build/$(UUID_TARNAME) && $(PREFIX)/env.sh ./configure --prefix=$(PREFIX) --without-systemdsystemunitdir --disable-use-tty-group --disable-bash-completion
	cd build/$(UUID_TARNAME) && $(PREFIX)/env.sh make -j4 install

sqlite: env
	cd build && curl -o $(SQLITE_TARNAME).tar.gz http://sqlite.org/2014/$(SQLITE_TARNAME).tar.gz
	cd build && tar -xf $(SQLITE_TARNAME).tar.gz
	cd build/$(SQLITE_TARNAME) && $(PREFIX)/env.sh ./configure --prefix=$(PREFIX)
	cd build/$(SQLITE_TARNAME) && $(PREFIX)/env.sh make -j4 install

intltool: env
	cd build && curl -L -O $(GNOME_SOURCES)/intltool/$(INTLTOOL_MAJOR)/$(INTLTOOL_TARNAME).tar.gz
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
	cd build && curl -L -O $(GNOME_SOURCES)/json-glib/$(JSON_GLIB_MAJOR)/$(JSON_GLIB_TARNAME).tar.xz
	cd build && tar -xf $(JSON_GLIB_TARNAME).tar.xz
	cd build/$(JSON_GLIB_TARNAME) && $(PREFIX)/env.sh ./configure --prefix=$(PREFIX)
	cd build/$(JSON_GLIB_TARNAME) && $(PREFIX)/env.sh make -j4 install

glib: env
	cd build && curl -L -O $(GNOME_SOURCES)/glib/$(GLIB_MAJOR)/$(GLIB_TARNAME).tar.xz
	cd build && tar -xf $(GLIB_TARNAME).tar.xz
	cd build/$(GLIB_TARNAME) && $(PREFIX)/env.sh ./autogen.sh --prefix=$(PREFIX)
	cd build/$(GLIB_TARNAME) && $(PREFIX)/env.sh make -j4 install

babl: env
	cd babl && $(PREFIX)/env.sh ./autogen.sh --prefix=$(PREFIX)
	cd babl && $(PREFIX)/env.sh make -j4 install

gegl: env
	cp ./hacks/nls.m4 ./gegl/m4/ && echo "HACKED nls.m4"
	cd gegl && $(PREFIX)/env.sh ./autogen.sh --prefix=$(PREFIX) $(GEGL_OPTIONS)
	cd gegl && $(PREFIX)/env.sh make -j4 install

libsoup: env
#	cp $(PREFIX)/share/aclocal/nls.m4 ./libsoup/m4/ || echo "HACK to get intltool working on Heroku not used"
	cd build && curl -L -O $(GNOME_SOURCES)/libsoup/$(LIBSOUP_MAJOR)/$(LIBSOUP_TARNAME).tar.xz
	cd build && tar -xf $(LIBSOUP_TARNAME).tar.xz
	cd build/$(LIBSOUP_TARNAME) && $(PREFIX)/env.sh ./configure --prefix=$(PREFIX) --disable-gtk-doc --disable-tls-check
	cd build/$(LIBSOUP_TARNAME) && $(PREFIX)/env.sh make -j4 install

xml-parser: env
	echo "Installing XML::Parser module"
	$(PREFIX)/env.sh /app/local/bin/cpanm --local-lib=/app/local/lib/perl5/ -f -n XML::Parser

perl-buildpack: env
	echo "Installing Perl buildpack"
	curl -L -O https://raw.github.com/miyagawa/heroku-buildpack-perl/master/bin/compile
	chmod +x ./compile
	$(PREFIX)/env.sh ./compile /app /app/cache

copy-apt:
	# move into our prefix so it will be installed and
	rsync -a /app/.apt/usr/* $(PREFIX)/

heroku-deps: copy-apt json-glib sqlite

travis-deps: sqlite

dependencies: libsoup babl gegl

check: install
	$(PREFIX)/env.sh $(PREFIX)/bin/link-check

clean:
	git clean -dfx --exclude node_modules --exclude install

package:
	tar -czf ./imgflo-dependencies-$(VERSION)-$(TARGET).tgz ./install

upload: package
	curl --ftp-create-dirs -T imgflo-dependencies-$(VERSION)-*.tgz -u $(FTP_USER):$(FTP_PASSWORD) ftp://vps.jonnor.com/ftp/

release: dependencies check upload

heroku-release: heroku-deps dependencies upload

.PHONY=all link-check libsoup
