#!/bin/bash

cd "$(dirname "$0")"

# turn on verbose debugging output for parabuild logs.
set -x
# make errors fatal
set -e

ICU4C_VERSION="48.1"
ICU4C_SOURCE_DIR="icu"

if [ -z "$AUTOBUILD" ] ; then 
    fail
fi

if [ "$OSTYPE" = "cygwin" ] ; then
    export AUTOBUILD="$(cygpath -u $AUTOBUILD)"
fi

# load autbuild provided shell functions and variables
set +x
eval "$("$AUTOBUILD" source_environment)"
set -x

stage="$(pwd)/stage"
pushd "$ICU4C_SOURCE_DIR"
    case "$AUTOBUILD_PLATFORM" in
        "windows")
            #load_vsvars
        ;;
        "darwin")
            #./configure --prefix="$stage"
        ;;
        "linux")
            pushd "source"
                export CFLAGS="-m32"
                export CXXFLAGS=$CFLAGS
                common_options="--prefix="$stage" --enable-shared=yes \
                    --enable-static=yes --disable-dyload --enable-extras=no \
                    --enable-layout=no --enable-samples=no --enable-icuio=no \
                    --enable-tests=no"
                mkdir -p $stage
                chmod +x runConfigureICU configure install-sh
                ./runConfigureICU Linux $common_options --libdir=$stage/lib/release
                make
                make install
                ./runConfigureICU Linux $common_options --libdir=$stage/lib/debug \
                    --prefix="$stage" --enable-shared=yes --enable-static=yes \
                    --enable-debug=yes --enable-release=no
                make
                make install
            popd
        ;;
    esac
    mkdir -p "$stage/LICENSES"
	sed -e 's/<[^>][^>]*>//g' -e '/^ *$/d' license.html >"$stage/LICENSES/icu.txt"
	cp unicode-license.txt "$stage/LICENSES/"
popd

pass

