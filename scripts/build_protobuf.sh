#!/usr/bin/env sh
[[ -n $DEBUG_BUILD ]] && set -ex

if [ -z "$NDK_ROOT" ] && [ "$#" -eq 0 ]; then
    echo 'Either $NDK_ROOT should be set or provided as argument'
    echo "e.g., 'export NDK_ROOT=/path/to/ndk' or"
    echo "      '${0} /path/to/ndk'"
    exit 1
else
    NDK_ROOT="${1:-${NDK_ROOT}}"
fi

export PROTOBUF_ROOT=${WD}/protobuf
export PROTOBUF_BUILD_DIR=${PROTOBUF_ROOT}/build_dir/${ANDROID_ABI_SHORT}
export PROTOBUF_INSTALL_DIR=${WD}/android_lib/${ANDROID_ABI_SHORT}

rm -rf "${PROTOBUF_BUILD_DIR}"
mkdir -p "${PROTOBUF_BUILD_DIR}"
cd "${PROTOBUF_BUILD_DIR}"

cmake -DCMAKE_TOOLCHAIN_FILE="${WD}/android-cmake/android.toolchain.cmake" \
      -DANDROID_NDK=${NDK_ROOT} \
      -DCMAKE_BUILD_TYPE=$BUILD_TYPE \
      -DANDROID_ABI="${ANDROID_ABI}" \
      -DANDROID_NATIVE_API_LEVEL=21 \
      -DANDROID_TOOLCHAIN_NAME=$TOOLCHAIN_NAME \
      -DCMAKE_INSTALL_PREFIX=${PROTOBUF_INSTALL_DIR}/protobuf \
      -DBUILD_TESTING=OFF \
      ../../cmake

make -j
rm -rf "${PROTOBUF_INSTALL_DIR}/protobuf"
make install/strip

cd "${WD}"
rm -rf ${PROTOBUF_BUILD_DIR}
