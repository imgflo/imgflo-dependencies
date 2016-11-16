if [[ $TRAVIS_OS_NAME = "osx" ]]
then
    brew install pkg-config intltool gettext autoconf automake libtool
    brew install glib json-glib
    brew install nasm # for ffmpeg, default version is too old
else
    sudo apt-get update -qq
    sudo apt-get --assume-yes build-dep gegl
    sudo apt-get --assume-yes install libjson-glib-dev libsdl1.2-dev
    sudo apt-get --assume-yes install sqlite3
    sudo apt-get --assume-yes install nasm # for ffmpeg
fi
