
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

GLIB_MAJOR=2.42
GLIB_VERSION=2.42.1
GLIB_TARNAME=glib-$(GLIB_VERSION)

LIBSOUP_MAJOR=2.50
LIBSOUP_VERSION=2.50.0
LIBSOUP_TARNAME=libsoup-$(LIBSOUP_VERSION)

JSON_GLIB_MAJOR=1.0
JSON_GLIB_VERSION=1.0.2
JSON_GLIB_TARNAME=json-glib-$(JSON_GLIB_VERSION)

FFMPEG_VERSION=3.2
FFMPEG_OPTIONS=--enable-ffmpeg --enable-avcodec --enable-avformat

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
	cd build/$(LIBSOUP_TARNAME) && $(PREFIX)/env.sh ./configure --prefix=$(PREFIX) --disable-gtk-doc --disable-tls-check || cat config.log
	cd build/$(LIBSOUP_TARNAME) && $(PREFIX)/env.sh make -j4 install

ffmpeg: env
	cd build && curl -L -O https://ffmpeg.org/releases/ffmpeg-${FFMPEG_VERSION}.tar.xz
	cd build && tar -xf ffmpeg-${FFMPEG_VERSION}.tar.xz
	cd build/ffmpeg-${FFMPEG_VERSION} && ./configure --prefix=${PREFIX} --disable-all --enable-shared ${FFMPEG_OPTIONS}
	cd build/ffmpeg-${FFMPEG_VERSION} && make -j4 install

copy-apt:
	# move into our prefix so it will be installed and
	rsync -a /app/.apt/usr/* $(PREFIX)/

heroku-deps: ffmpeg copy-apt

null:
	echo "null target"

travis-deps: ffmpeg null

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
