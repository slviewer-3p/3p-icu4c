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

# load autobuild provided shell functions and variables
set +x
eval "$("$AUTOBUILD" source_environment)"
set -x

stage=$(pwd)/stage
pushd "$ICU4C_SOURCE_DIR"
    case "$AUTOBUILD_PLATFORM" in
        "windows")
            load_vsvars
            
            # According to the icu build instructions for Windows, 
            # runConfigureICU doesn't work for the Microsoft build tools, so
            # just use the provided .sln file.
            
            pushd ../icu/source
                build_sln "allinone\allinone.sln" "Release|Win32"
#                build_sln "allinone\allinone.sln" "Debug|Win32"
            popd
            
            mkdir -p "$stage/lib"           
#            mkdir -p "$stage/lib/debug"
#            mkdir -p "$stage/lib/release"
            mkdir -p "$stage/include"

			pwd
            
            # Copy the .lib files that don't have a "d" on the end to release
            find ./lib -regex '.*/icu.*[^d]\.lib' -exec cp {} $stage/lib/ \;
            # Copy the .lib files and .pdb files ending in "d" to debug
#            find ./lib -regex '.*/icu.*d\.{lib,pdb}' -exec cp {} $stage/lib/debug \;
            
            cp -R include/* "$stage/include"
    
        ;;
        "darwin")
            #./configure --prefix="$stage"
        ;;
        "linux")
            pushd "source"
                export CFLAGS="-m32"
                export CXXFLAGS=$CFLAGS
                export common_options="--prefix=${stage} --enable-shared=no \
                    --enable-static=yes --disable-dyload --enable-extras=no \
                    --enable-samples=no --enable-tests=no --enable-layout=no" 
                mkdir -p $stage
                chmod +x runConfigureICU configure install-sh
                # HACK: Break format layout so boost can find the library.
#                ./runConfigureICU Linux $common_options --libdir=${stage}/lib/release
                ./runConfigureICU Linux $common_options --libdir=${stage}/lib/
                
                make -j2
                make install
                # Disable debug build until we can build boost with our standard layout.
#                ./runConfigureICU Linux $common_options --libdir=${stage}/lib/debug \
#                    --enable-debug=yes --enable-release=no 
#                make -j2
#                make install
            popd
        ;;
    esac
    mkdir -p "$stage/LICENSES"
	sed -e 's/<[^>][^>]*>//g' -e '/^ *$/d' license.html >"$stage/LICENSES/icu.txt"
	cp unicode-license.txt "$stage/LICENSES/"
popd

pass

