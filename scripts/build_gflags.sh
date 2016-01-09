#!/usr/bin/env sh
set -ex

if [ -z "$NDK_ROOT" ] && [ "$#" -eq 0 ]; then
    echo 'Either $NDK_ROOT should be set or provided as argument'
    echo "e.g., 'export NDK_ROOT=/path/to/ndk' or"
    echo "      '${0} /path/to/ndk'"
    exit 1
else
    NDK_ROOT="${1:-${NDK_ROOT}}"
fi

ANDROID_ABI=${ANDROID_ABI:-"armeabi-v7a with NEON"}
LINK="https://github.com/gflags/gflags/archive/v2.1.2.tar.gz"
TARBALL=gflags_v2.1.2.tar.gz
WD=$("$READLINK_CMD" -f "`dirname $0`/..")
DOWNLOAD_DIR=${WD}/download
GFLAGS_ROOT=${WD}/gflags-2.1.2
BUILD_DIR=${GFLAGS_ROOT}/build/${ANDROID_ABI}
INSTALL_DIR=${WD}/android_lib/${ANDROID_ABI}

[ ! -d ${DOWNLOAD_DIR} ] && mkdir -p ${DOWNLOAD_DIR}

cd ${DOWNLOAD_DIR}
if [ ! -f ${TARBALL} ]; then
    wget ${LINK} -O ${TARBALL}
fi

if [ ! -d ${GFLAGS_ROOT} ]; then
    tar zxf ${TARBALL} -C "${WD}"
fi

rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"
cd "${BUILD_DIR}"

cmake -DCMAKE_TOOLCHAIN_FILE="${WD}/android-cmake/android.toolchain.cmake" \
      -DANDROID_NDK="${NDK_ROOT}" \
      -DCMAKE_BUILD_TYPE=${BUILD_TYPE} \
      -DANDROID_ABI="${ANDROID_ABI}" \
      -DANDROID_NATIVE_API_LEVEL=21 \
      -DANDROID_TOOLCHAIN_NAME=$TOOLCHAIN_NAME \
      -DCMAKE_INSTALL_PREFIX="${INSTALL_DIR}/gflags" \
      ../..

make -j
rm -rf "${INSTALL_DIR}/gflags"
make install/strip

cd "${WD}"
