#!/usr/bin/env sh
set -ex

_BRED='\x1b[1m\x1b[31m'
_BYEL='\x1b[1m\x1b[33m'
_NORM='\x1b[00m'

function banner () {
    if [ -n "$1" ]
    then
        echo "***************************************************************"
        echo -e "$_BYEL$1$_NORM"
        echo "***************************************************************"
    fi
}

function becho () {
    [[ -n "$1" ]] && echo -e "$_BRED$1$_NORM"
}

# only OS X and Linux are supported
if [[ "$OSTYPE" == *darwin* ]] ; then
    # use brew install coreutils for greadlink and gsed
    export READLINK_CMD='greadlink'
    export SED_CMD='gsed'
else
    export READLINK_CMD='readlink'
    export SED_CMD='sed'
fi

if [ -z "$NDK_ROOT" ] && [ "$#" -eq 0 ]; then
    echo 'Either $NDK_ROOT should be set or provided as argument'
    echo "e.g., 'export NDK_ROOT=/path/to/ndk' or"
    echo "      '${0} /path/to/ndk'"
    exit 1
else
    NDK_ROOT=$("$READLINK_CMD" -f "${1:-${NDK_ROOT}}")
    export NDK_ROOT="${NDK_ROOT}"
fi

export _WD=$("$READLINK_CMD" -f "`dirname $0/..`")
export WD=$("$READLINK_CMD" -f "`dirname $0`")
cd ${PWD}

#export DEFAULT_ANDROID_ABI="armeabi-v7a with NEON"
export DEFAULT_ANDROID_ABI="arm64-v8a"
export ANDROID_ABI="${ANDROID_ABI:-"arm64-v8a"}"
export USE_OPENBLAS=${USE_OPENBLAS:-0}

if [ ${ANDROID_ABI} == "arm64-v8a" ] ; then
    export TOOLCHAIN_NAME=aarch64-linux-android-4.9
    export TOOLCHAIN_PREFIX=aarch64-linux-android
    export TARGET_ARCH=ARMV8A
else
    export TOOLCHAIN_NAME=arm-linux-androideabi-4.9
    export TOOLCHAIN_PREFIX=arm-linux-androideabi
    export TARGET_ARCH=ARMV7
fi

if [ ${USE_OPENBLAS} -eq 1 ]; then
    if [ "${ANDROID_ABI}" = "armeabi-v7a-hard-softfp with NEON" ]; then
        ./scripts/build_openblas_hard.sh
    elif [ "${ANDROID_ABI}" = "armeabi-v7a with NEON"  ]; then
        ./scripts/get_openblas.sh
    else
        echo "Warning: not support OpenBLAS for ABI: ${ANDROID_ABI}, use Eigen instead"
        export USE_OPENBLAS=0
        ./scripts/get_eigen.sh
    fi
else
    ./scripts/get_eigen.sh
fi

export BUILD_TYPE=Release

./scripts/build_boost.sh
./scripts/build_gflags.sh
./scripts/build_opencv.sh
./scripts/build_protobuf_host.sh
./scripts/build_protobuf.sh
./scripts/build_caffe.sh

echo "DONE!!"
