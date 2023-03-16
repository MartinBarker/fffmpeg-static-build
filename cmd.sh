#!/bin/bash

set -e

CWD=$(pwd)
PACKAGES="$CWD/packages"
WORKSPACE="$CWD/workspace"
ADDITIONAL_CONFIGURE_OPTIONS=""
LIBMP3LAME_VERSION="3.100"

mkdir -p "$PACKAGES"
mkdir -p "$WORKSPACE"

FFMPEG_TAG="$1"
FFMPEG_URL="https://git.ffmpeg.org/gitweb/ffmpeg.git/snapshot/74c4c539538e36d8df02de2484b045010d292f2c.tar.gz"
LIBMP3LAME_URL="http://downloads.sourceforge.net/project/lame/lame/${LIBMP3LAME_VERSION}/lame-${LIBMP3LAME_VERSION}.tar.gz"
LIBMP3LAME_ARCHIVE="$PACKAGES/lame-${LIBMP3LAME_VERSION}.tar.gz"

if [ ! -f "$LIBMP3LAME_ARCHIVE" ]; then
    echo "Downloading libmp3lame ${LIBMP3LAME_VERSION}..."
    curl -L -k -o "$LIBMP3LAME_ARCHIVE" "$LIBMP3LAME_URL"
fi

if [ ! -d "$PACKAGES/lame-${LIBMP3LAME_VERSION}" ]; then
    echo "Extracting libmp3lame ${LIBMP3LAME_VERSION}..."
    mkdir -p "$PACKAGES/lame-${LIBMP3LAME_VERSION}"
    tar -xf "$LIBMP3LAME_ARCHIVE" -C "$PACKAGES/lame-${LIBMP3LAME_VERSION}" --strip-components=1
fi

FFMPEG_ARCHIVE="$PACKAGES/ffmpeg.tar.gz"

if [ ! -f "$FFMPEG_ARCHIVE" ]; then
    echo "Downloading tag ${FFMPEG_TAG}..."
    curl -L -k -o "$FFMPEG_ARCHIVE" "$FFMPEG_URL"
fi

EXTRACTED_DIR="$PACKAGES/extracted"

mkdir -p "$EXTRACTED_DIR"

echo "Extracting..."
tar -xf "$FFMPEG_ARCHIVE" --strip-components=1 -C "$EXTRACTED_DIR"

cd "$EXTRACTED_DIR"

echo "Building..."

# Min electron supported version
MACOS_MIN="10.10"

# Add the following line to set the path to the static libmp3lame library
export LAME_PATH="/usr/local/opt/lame/lib/libmp3lame.0.dylib"

./configure $ADDITIONAL_CONFIGURE_OPTIONS \
    --pkgconfigdir="$WORKSPACE/lib/pkgconfig" \
    --prefix=${WORKSPACE} \
    --pkg-config-flags="--static" \
    --extra-cflags="-I$WORKSPACE/include -mmacosx-version-min=${MACOS_MIN} -I$PACKAGES/lame-${LIBMP3LAME_VERSION}/include -I$PREFIX/include -I$LAME_PATH" \
    --extra-ldflags="-L$WORKSPACE/lib -mmacosx-version-min=${MACOS_MIN} -L$PACKAGES/lame-${LIBMP3LAME_VERSION}/lib -L$PREFIX/lib -L$LAME_PATH/.libs" \
    --extra-libs="-lpthread -lm" \
    --enable-static \
    --disable-shared \
    --disable-debug \
    --disable-ffplay \
    --disable-lzma \
    --disable-doc \
    --enable-version3 \
    --enable-pthreads \
    --enable-runtime-cpudetect \
    --enable-avfilter \
    --enable-filters \
    --disable-libxcb \
    --enable-gpl \
    --disable-libass \
    --enable-libmp3lame \
    --enable-libx264

make -j 4
make install

otool -L "$WORKSPACE/bin/ffmpeg"
otool -L "$WORKSPACE/bin/ffprobe"

echo "done"

