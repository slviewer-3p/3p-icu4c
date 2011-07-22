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
            #
            #pushd contrib/masmx86
            #    ./bld_ml32.bat
            #popd
            # 
            #build_sln "contrib/vstudio/vc10/zlibvc.sln" "Debug|Win32" "zlibstat"
            #build_sln "contrib/vstudio/vc10/zlibvc.sln" "Release|Win32" "zlibstat"
            #mkdir -p "$stage/lib/debug"
            #mkdir -p "$stage/lib/release"
            #cp "contrib/vstudio/vc10/x86/ZlibStatDebug/zlibstat.lib" \
            #    "$stage/lib/debug/zlibd.lib"
            #cp "contrib/vstudio/vc10/x86/ZlibStatRelease/zlibstat.lib" \
            #    "$stage/lib/release/zlib.lib"
            #mkdir -p "$stage/include/zlib"
            #cp {zlib.h,zconf.h} "$stage/include/zlib"
        ;;
        "darwin")
            #./configure --prefix="$stage"
            #make
            #make install
			#mkdir -p "$stage/include/zlib"
			#mv "$stage/include/"*.h "$stage/include/zlib/"
        ;;
        "linux")
			pushd "source"
				chmod +x runConfigureICU configure install-sh
				CFLAGS="-m32" CXXFLAGS="-m32" ./runConfigureICU Linux --prefix="$stage/icu" --enable-shared=no --enable-static=yes
				make
				make install
			popd
        ;;
    esac
    mkdir -p "$stage/icu/LICENSES"
	sed -e 's/<[^>][^>]*>//g' -e '/^ *$/d' license.html >"$stage/icu/LICENSES/icu.txt"
	cp unicode-license.txt "$stage/icu/LICENSES/"
popd

pass

