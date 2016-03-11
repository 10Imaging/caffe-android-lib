#!/bin/bash -e
[[ -n $DEBUG_BUILD ]] && set -x

if [ -z "$ANDROID_NDK" ] && [ "$#" -eq 0 ]; then
    echo 'Either $ANDROID_NDK should be set or provided as argument'
    echo "e.g., 'export ANDROID_NDK=/path/to/ndk' or"
    echo "      '${0} /path/to/ndk'"
    exit 1
else
    ANDROID_NDK="${1:-${ANDROID_NDK}}"
fi

export OPENCV_ROOT=${WD}/opencv
export OPENCV_BUILD_DIR=$OPENCV_ROOT/platforms/build_android_arm/${ANDROID_ABI_SHORT}
export OPENCV_INSTALL_DIR=${WD}/android_lib/${ANDROID_ABI_SHORT}

[[ -d ${OPENCV_BUILD_DIR} ]] && rm -rf "${OPENCV_BUILD_DIR}"
mkdir -p "${OPENCV_BUILD_DIR}"
cd "${OPENCV_BUILD_DIR}"

cmake -DCMAKE_BUILD_WITH_INSTALL_RPATH=ON \
    -D CMAKE_BUILD_TYPE=$BUILD_TYPE \
    -D CMAKE_TOOLCHAIN_FILE="${WD}/android-cmake/android.toolchain.cmake" \
    -D ANDROID_NDK="${ANDROID_NDK}" \
    -D ANDROID_NATIVE_API_LEVEL=21 \
    -D ANDROID_ABI="${ANDROID_ABI}" \
    -D WITH_CUDA=OFF \
    -D ENABLE_NEON=ON \
    -D ENABLE_VFPV3=ON \
    -D WITH_TBB=ON \
    -D BUILD_TBB=ON \
    -D WITH_OPENCL=OFF \
    -D WITH_MATLAB=OFF \
    -D BUILD_ANDROID_EXAMPLES=OFF \
    -D BUILD_DOCS=OFF \
    -D BUILD_PERF_TESTS=OFF \
    -D BUILD_TESTS=OFF \
    -D ENABLE_PRECOMPILED_HEADERS=OFF \
    -D CMAKE_INSTALL_PREFIX="${OPENCV_INSTALL_DIR}/opencv" \
    ../../..

make -j${BUILD_NUM_CORES}
[[ ${OPENCV_INSTALL_DIR} ]] && rm -rf "${OPENCV_INSTALL_DIR}/opencv"
make install/strip

cd "${WD}"
rm -rf "${OPENCV_BUILD_DIR}"
