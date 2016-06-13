if [[ $TRAVIS_OS_NAME = "osx" ]]
then
    brew install pkg-config intltool gettext autoconf automake libtool
    brew install glib json-glib
else
    sudo apt-get update -qq
    sudo apt-get --assume-yes build-dep gegl
    sudo apt-get --assume-yes install libjson-glib-dev libsdl1.2-dev
fi
