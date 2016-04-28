#!/bin/bash -e
[[ -n $DEBUG_BUILD ]] && set -x

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

export -n REMAKE_CMAKE
for i in "$@"
do
case $i in
    clean)
    export REMAKE_CMAKE=true
    shift
    ;;
    -t=*|--targets=*)
    BUILD_ABIS="${i#*=}"
    shift
    ;;
    -h|--help|*)
    echo "`basename $0` - [clean] remake cmake files [-a=,--abi=] x68,arm7,arm7h,arm8,mips"
    exit 0
    ;;
esac
done

HAS_WGET=`which wget`
[[ -z "$HAS_WGET" ]] && echo "wget command is invalid" && exit 1

HAS_READLINK=`which ${READLINK_CMD}`
[[ -z "$HAS_READLINK" ]] && echo "readlink command (${READLINK_CMD}) is invalid" && exit 1

if [ -z "${ANDROID_NDK}" ] && [ "$#" -eq 0 ]; then
    echo 'Either $ANDROID_NDK should be set or provided as argument'
    echo "e.g., 'export ANDROID_NDK=/path/to/ndk' or"
    echo "      '${0} /path/to/ndk'"
    exit 1
else
    ANDROID_NDK=$("$READLINK_CMD" -f "${1:-${ANDROID_NDK}}")
    export ANDROID_NDK="${ANDROID_NDK}"
fi

export WD=$("$READLINK_CMD" -f "`dirname $0`")
cd ${PWD}

declare -a TARGETS=("armeabi-v7a with NEON" "arm64-v8a")
declare -a TARGETS_ROOT=("armeabi-v7a" "arm64-v8a")

# update all submodules to latest versions
git submodule update

# build each target
for (( INDEX=0; INDEX < ${#TARGETS[@]} ; INDEX++ )) ; 
do
    export BUILD_ROOT=${WD}/build
    export ANDROID_ABI=${TARGETS[$INDEX]}
    export ANDROID_ABI_SHORT=${TARGETS_ROOT[$INDEX]}
    export USE_OPENBLAS=${USE_OPENBLAS:-0}
    export BUILD_ROOT_ABI=${BUILD_ROOT}/${ANDROID_ABI_SHORT}

    if [ "${ANDROID_ABI}" == "arm64-v8a" ]; then
        export TOOLCHAIN_NAME=aarch64-linux-android-4.9
        export TOOLCHAIN_PREFIX=aarch64-linux-android
        export TARGET_ARCH=ARMV8A
    else
        export TOOLCHAIN_NAME=arm-linux-androideabi-4.9
        export TOOLCHAIN_PREFIX=arm-linux-androideabi
        export TARGET_ARCH=ARMV7
    fi

    banner "Building Android TARGET ${ANDROID_ABI} into ${BUILD_ROOT_ABI}"
    
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
      if [[ "$OSTYPE" == *darwin* ]] ; then
        export BUILD_NUM_CORES=`sysctl -n hw.ncpu`
      elif [[ "$OSTYPE" == *linux* ]] ; then
        export BUILD_NUM_CORES=`nproc`
      else
        export BUILD_NUM_CORES=1
      fi
    fi
    export BUILD_TYPE=Release

    ./scripts/build_boost.sh
    ./scripts/build_gflags.sh
    ./scripts/build_opencv.sh
    ./scripts/build_protobuf_host.sh
    ./scripts/build_protobuf.sh
    ./scripts/build_caffe.sh
    ./scripts/build_caffe_cl.sh

    export ASSEMBLY_DIR="${BUILD_ROOT}/caffe"
    banner "Assembling build for ${ANDROID_ABI_SHORT} into {$ASSEMBLY_DIR}"
    #[[ -d "${ASSEMBLY_DIR}" ]] && set +e && rm -rf "${ASSEMBLY_DIR}" && set -e
    mkdir -p "${ASSEMBLY_DIR}"
    cp -a "${WD}/template/src" "${ASSEMBLY_DIR}"
    #cp -a "${BUILD_ROOT_ABI}/caffe/include" "${ASSEMBLY_DIR}"
    mkdir -p "${ASSEMBLY_DIR}/src/main/jniLibs/${ANDROID_ABI_SHORT}"
    cp -a "${BUILD_ROOT_ABI}/caffe/lib/libcaffe.so" "${ASSEMBLY_DIR}/src/main/jniLibs/${ANDROID_ABI_SHORT}"
    cp -a "${BUILD_ROOT_ABI}/caffe/lib/libcaffe_jni.so" "${ASSEMBLY_DIR}/src/main/jniLibs/${ANDROID_ABI_SHORT}"
    cp -a "${BUILD_ROOT_ABI}/caffe-cl/lib/libcaffe.so" "${ASSEMBLY_DIR}/src/main/jniLibs/${ANDROID_ABI_SHORT}/libcaffe-cl.so"
    cp -a "${BUILD_ROOT_ABI}/caffe-cl/lib/libcaffe_jni.so" "${ASSEMBLY_DIR}/src/main/jniLibs/${ANDROID_ABI_SHORT}/libcaffe-cl_jni.so"

    banner "Completed build for ${ANDROID_ABI}"
done
