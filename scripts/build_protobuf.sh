#!/bin/bash
[[ -n $DEBUG_BUILD ]] && set -ex

if [ -z "$ANDROID_NDK" ] && [ "$#" -eq 0 ]; then
    echo 'Either $ANDROID_NDK should be set or provided as argument'
    echo "e.g., 'export ANDROID_NDK=/path/to/ndk' or"
    echo "      '${0} /path/to/ndk'"
    exit 1
else
    ANDROID_NDK="${1:-${ANDROID_NDK}}"
fi

export PROTOBUF_ROOT=${WD}/protobuf
export PROTOBUF_BUILD_DIR=${PROTOBUF_ROOT}/build_dir/${ANDROID_ABI_SHORT}
export PROTOBUF_INSTALL_DIR=${WD}/android_lib/${ANDROID_ABI_SHORT}

rm -rf "${PROTOBUF_BUILD_DIR}"
mkdir -p "${PROTOBUF_BUILD_DIR}"
cd "${PROTOBUF_BUILD_DIR}"

cmake -DCMAKE_TOOLCHAIN_FILE="${WD}/android-cmake/android.toolchain.cmake" \
      -DANDROID_NDK=${ANDROID_NDK} \
      -DCMAKE_BUILD_TYPE=$BUILD_TYPE \
      -DANDROID_ABI="${ANDROID_ABI}" \
      -DANDROID_NATIVE_API_LEVEL=21 \
      -DANDROID_TOOLCHAIN_NAME=$TOOLCHAIN_NAME \
      -DCMAKE_INSTALL_PREFIX=${PROTOBUF_INSTALL_DIR}/protobuf \
      -DBUILD_TESTING=OFF \
      ../../cmake

make -j${BUILD_NUM_CORES}
rm -rf "${PROTOBUF_INSTALL_DIR}/protobuf"
make install/strip

cd "${WD}"
rm -rf ${PROTOBUF_BUILD_DIR}
