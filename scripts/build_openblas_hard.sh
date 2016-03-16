#!/bin/bash -e
[[ -n $DEBUG_BUILD ]] && set -x

if [ -z "$ANDROID_NDK" ] && [ "$#" -eq 0 ]; then
    echo 'Either $ANDROID_NDK should be set or provided as argument'
    echo "e.g., 'export ANDROID_NDK=/path/to/ndk' or"
    echo "      '${0} /path/to/ndk'"exit 1
else
    ANDROID_NDK="${1:-${ANDROID_NDK}}"
fi

if [ "$(uname)" = "Darwin" ]; then
    OS=darwin
elif [ "$(expr substr $(uname -s) 1 5)" = "Linux" ]; then
    OS=linux
elif [ "$(expr substr $(uname -s) 1 10)" = "MINGW32_NT" ||
       "$(expr substr $(uname -s) 1 9)" = "CYGWIN_NT" ]; then
    OS=windows
else
    echo "Unknown OS"
    exit 1
fi

if [ "$(uname -m)" = "x86_64"  ]; then
    BIT=x86_64
else
    BIT=x86
fi

TOOLCHAIN_DIR=$ANDROID_NDK/toolchains/$TOOLCHAIN_NAME/prebuilt/${OS}-${BIT}/bin
WD=$(readlink -f "`dirname $0`/..")
OPENBLAS_ROOT=${WD}/OpenBLAS

cd "${OPENBLAS_ROOT}"

make clean
make -j${BUILD_NUM_CORES} \
     CC="$TOOLCHAIN_DIR/arm-linux-androideabi-gcc --sysroot=$ANDROID_NDK/platforms/android-21/arch-arm" \
     CROSS_SUFFIX=${TOOLCHAIN_DIR}/${TOOLCHAIN_PREFIX}- \
     HOSTCC=gcc NO_LAPACK=1 TARGET=ARMV7 \
     USE_THREAD=1 NUM_THREADS=8 USE_OPENMP=1

set +e && rm -rf "${BUILD_ROOT_ABI}/openblas-hard" && set -e
make PREFIX="${BUILD_ROOT_ABI}/openblas-hard" install

cd "${WD}"
