#!/bin/bash

cd "$(dirname "$0")"
top="$(pwd)"

# turn on verbose debugging output for parabuild logs.
set -x
# make errors fatal
set -e
# complain about undefined variables
set -u

ICU4C_SOURCE_DIR="icu"
VERSION_HEADER_FILE="$ICU4C_SOURCE_DIR/source/common/unicode/uvernum.h"
VERSION_MACRO="U_ICU_VERSION"

if [ -z "$AUTOBUILD" ] ; then
    fail
fi

if [ "$OSTYPE" = "cygwin" ] ; then
    autobuild="$(cygpath -u $AUTOBUILD)"
else
    autobuild="$AUTOBUILD"
fi

# load autobuild provided shell functions and variables
set +x
eval "$("$autobuild" source_environment)"
set -x

# pull in LL_BUILD with platform-specific compiler switches
set_build_variables convenience Release

stage="$(pwd)/stage"
pushd "$ICU4C_SOURCE_DIR"
    case "$AUTOBUILD_PLATFORM" in
        windows*)
            load_vsvars

            # According to the icu build instructions for Windows,
            # runConfigureICU doesn't work for the Microsoft build tools, so
            # just use the provided .sln file.

            pushd ../icu/source
                build_sln "allinone\allinone.sln" "Release|$AUTOBUILD_WIN_VSPLATFORM"
            popd

            mkdir -p "$stage/lib"
            mkdir -p "$stage/include"

            if [ "$AUTOBUILD_ADDRSIZE" = 32 ]
            then bitdir=./lib
            else bitdir=./lib64
            fi
            find $bitdir -name 'icu*.lib' -print -exec cp {} $stage/lib/ \;

            cp -R include/* "$stage/include"

            # populate version_file
            cl /DVERSION_HEADER_FILE="\"$VERSION_HEADER_FILE\"" \
               /DVERSION_MACRO="$VERSION_MACRO" \
               /Fo"$(cygpath -w "$stage/version.obj")" \
               /Fe"$(cygpath -w "$stage/version.exe")" \
               "$(cygpath -w "$top/version.c")"
            "$stage/version.exe" > "$stage/version.txt"
            rm "$stage"/version.{obj,exe}
        ;;
        darwin*)
            pushd "source"

                opts='-arch $AUTOBUILD_CONFIGURE_ARCH $LL_BUILD -DU_CHARSET_IS_UTF8=1'
                export CFLAGS="$opts"
                export CXXFLAGS="$opts"
                export LDFLAGS="$opts"
                export common_options="--prefix=${stage} --enable-shared=no \
                    --enable-static=yes --disable-dyload --enable-extras=no \
                    --enable-samples=no --enable-tests=no --enable-layout=no"
                mkdir -p $stage
                chmod +x runConfigureICU configure install-sh
                # HACK: Break format layout so boost can find the library.
                ./runConfigureICU MacOSX $common_options --libdir=${stage}/lib/

                make -j2
                make install
            popd

            # populate version_file
            cc -DVERSION_HEADER_FILE="\"$VERSION_HEADER_FILE\"" \
               -DVERSION_MACRO="$VERSION_MACRO" \
               -o "$stage/version" "$top/version.c"
            "$stage/version" > "$stage/version.txt"
            rm "$stage/version"
        ;;
        linux*)
            pushd "source"
                ## export CC="gcc-4.1"
                ## export CXX="g++-4.1"
                export CFLAGS="-m$AUTOBUILD_ADDRSIZE $LL_BUILD"
                export CXXFLAGS="$CFLAGS"
                export common_options="--prefix=${stage} --enable-shared=no \
                    --enable-static=yes --disable-dyload --enable-extras=no \
                    --enable-samples=no --enable-tests=no --enable-layout=no"
                mkdir -p $stage
                chmod +x runConfigureICU configure install-sh
                # HACK: Break format layout so boost can find the library.
                ./runConfigureICU Linux $common_options --libdir=${stage}/lib/

                make -j2
                make install
            popd

            # populate version_file
            cc -DVERSION_HEADER_FILE="\"$VERSION_HEADER_FILE\"" \
               -DVERSION_MACRO="$VERSION_MACRO" \
               -o "$stage/version" "$top/version.c"
            "$stage/version" > "$stage/version.txt"
            rm "$stage/version"
        ;;
    esac
    mkdir -p "$stage/LICENSES"
	sed -e 's/<[^>][^>]*>//g' -e '/^ *$/d' license.html >"$stage/LICENSES/icu.txt"
	cp unicode-license.txt "$stage/LICENSES/"
popd

pass
