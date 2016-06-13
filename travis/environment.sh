if [[ $TRAVIS_OS_NAME = "osx" ]]
then
    export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH
    export PATH=$PATH:/usr/local/opt/gettext/bin
else
    echo "No custom environment on '$TRAVIS_OS_NAME'"
fi
