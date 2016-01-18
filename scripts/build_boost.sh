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

if [ -d "$_WD/boost" ] ; then
    export BOOST_ROOT=${_WD}/boost
else
    export BOOST_ROOT=${WD}/boost
fi
export BOOST_BUILD_DIR=${BOOST_ROOT}/build/${ANDROID_ABI_SHORT}
export BOOST_INSTALL_DIR=${WD}/android_lib/${ANDROID_ABI_SHORT}

cd "${BOOST_ROOT}"
./get_boost.sh
cd "${WD}"

rm -rf "${BOOST_BUILD_DIR}"
mkdir -p "${BOOST_BUILD_DIR}"
cd "${BOOST_BUILD_DIR}"

cmake -DCMAKE_TOOLCHAIN_FILE="${WD}/android-cmake/android.toolchain.cmake" \
      -DANDROID_NDK="${ANDROID_NDK}" \
      -DCMAKE_BUILD_TYPE=${BUILD_TYPE} \
      -DANDROID_ABI="${ANDROID_ABI}" \
      -DANDROID_NATIVE_API_LEVEL=21 \
      -DANDROID_TOOLCHAIN_NAME=$TOOLCHAIN_NAME \
      -DCMAKE_INSTALL_PREFIX="${BOOST_INSTALL_DIR}/boost" \
      ../..

make -j${BUILD_NUM_CORES}
[[ -d $"{BOOST_INSTALL_DIR}" ]] && rm -rf "${BOOST_INSTALL_DIR}/boost"
make install/strip

cd "${WD}"
rm -rf "${BOOST_BUILD_DIR}"
