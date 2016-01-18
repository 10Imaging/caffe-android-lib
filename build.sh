#!/bin/bash
set -e

if [[ "$OSTYPE" == *darwin* ]] ; then
    # use brew install coreutils for greadlink and gsed
    export READLINK_CMD='greadlink'
    export SED_CMD='gsed'
else
    export READLINK_CMD='readlink'
    export SED_CMD='sed'
fi

if [ -z "$ANDROID_NDK" ] && [ "$#" -eq 0 ]; then
    echo 'Either $ANDROID_NDK should be set or provided as argument'
    echo "e.g., 'export ANDROID_NDK=/path/to/ndk' or"
    echo "      '${0} /path/to/ndk'"
    exit 1
else
    ANDROID_NDK=$("$READLINK_CMD" -f "${1:-${ANDROID_NDK}}")
    export ANDROID_NDK="${ANDROID_NDK}"
fi

WD=$("$READLINK_CMD" -f "`dirname $0`")
cd ${WD}

#export DEFAULT_ANDROID_ABI="armeabi-v7a with NEON"
export DEFAULT_ANDROID_ABI="arm64-v8a"
export ANDROID_ABI="${ANDROID_ABI:-"armeabi-v7a with NEON"}"
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

if [ "${TRAVIS}" == "true" -a "${CI}" == "true" ] ; then
  export BUILD_NUM_CORES=1
else
  if [ "$OSTYPE" == *darwin* ] ; then
    export BUILD_NUM_CORES=`sysctl -n hw.ncpu`
  elif [ "$OSTYPE" == *linux* ] ; then
    export BUILD_NUM_CORES=`nproc`
  else
    export BUILD_NUM_CORES=1
  fi
fi
export BUILD_TYPE=Debug

./scripts/build_boost.sh
./scripts/build_gflags.sh
./scripts/build_opencv.sh
./scripts/build_protobuf_host.sh
./scripts/build_protobuf.sh
./scripts/build_caffe.sh

echo "DONE!!"
