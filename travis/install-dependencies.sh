if [[ $TRAVIS_OS_NAME = "osx" ]]
then
    echo 'INSTALL OSX DEPS HERE'
else
    sudo apt-get update -qq
    sudo apt-get --assume-yes build-dep gegl
    sudo apt-get --assume-yes install libjson-glib-dev libsdl1.2-dev
fi
