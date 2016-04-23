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

OPENCV_HOME=${BUILD_ROOT_ABI}/opencv/sdk/native/jni
PROTOBUF_HOME=${BUILD_ROOT_ABI}/protobuf
GFLAGS_HOME=${BUILD_ROOT_ABI}/gflags
BOOST_HOME=${BUILD_ROOT_ABI}/boost_1.56.0
export CAFFE_ROOT=${WD}/caffe
export CAFFE_BUILD_DIR=${CAFFE_ROOT}/build/${ANDROID_ABI_SHORT}
export CAFFE_INSTALL_DIR=${BUILD_ROOT_ABI}/caffe

USE_OPENBLAS=${USE_OPENBLAS:-0}
if [ ${USE_OPENBLAS} -eq 1 ]; then
    if [ "${ANDROID_ABI}" = "armeabi-v7a-hard-softfp with NEON" ]; then
        OpenBLAS_HOME=${BUILD_ROOT_ABI}/openblas-hard
    elif [ "${ANDROID_ABI}" = "armeabi-v7a with NEON"  ]; then
        OpenBLAS_HOME=${BUILD_ROOT_ABI}/openblas-android
    else
        echo "Error: not support OpenBLAS for ABI: ${ANDROID_ABI}"
        exit 1
    fi

    BLAS=open
    export OpenBLAS_HOME="${OpenBLAS_HOME}"
else
    BLAS=eigen
    export EIGEN_HOME="${BUILD_ROOT_ABI}/eigen3"
fi

if [ -n "${REMAKE_CMAKE}" -o ! -d ${CAFFE_BUILD_DIR} ] ; then
  rm -rf "${CAFFE_BUILD_DIR}"
  mkdir -p "${CAFFE_BUILD_DIR}"
  cd "${CAFFE_BUILD_DIR}"
  cmake -DCMAKE_TOOLCHAIN_FILE="${WD}/android-cmake/android.toolchain.cmake" \
      -DANDROID_NDK="${ANDROID_NDK}" \
      -DCMAKE_BUILD_TYPE=${BUILD_TYPE} \
      -DANDROID_ABI="${ANDROID_ABI}" \
      -DANDROID_NATIVE_API_LEVEL=21 \
      -DANDROID_TOOLCHAIN_NAME=$TOOLCHAIN_NAME \
      -DANDROID_USE_OPENMP=ON \
      -DADDITIONAL_FIND_PATH="${BUILD_ROOT_ABI}" \
      -DBUILD_python=OFF \
      -DBUILD_docs=OFF \
      -DCPU_ONLY=ON \
      -DUSE_GLOG=OFF \
      -DUSE_LMDB=OFF \
      -DUSE_LEVELDB=OFF \
      -DUSE_HDF5=OFF \
      -DBLAS=${BLAS} \
      -DBOOST_ROOT="${BOOST_HOME}" \
      -DGFLAGS_INCLUDE_DIR="${GFLAGS_HOME}/include" \
      -DGFLAGS_LIBRARY="${GFLAGS_HOME}/lib/libgflags.a" \
      -DOpenCV_DIR="${OPENCV_HOME}" \
      -DPROTOBUF_PROTOC_EXECUTABLE="${BUILD_ROOT_ABI}/protobuf_host/bin/protoc" \
      -DPROTOBUF_INCLUDE_DIR="${PROTOBUF_HOME}/include" \
      -DPROTOBUF_LIBRARY="${PROTOBUF_HOME}/lib/libprotobuf.a" \
      -DCMAKE_INSTALL_PREFIX="${CAFFE_INSTALL_DIR}" \
      ../..
fi

cd "${CAFFE_BUILD_DIR}"
make -j${BUILD_NUM_CORES}
[[ -d "${CAFFE_INSTALL_DIR}" ]] && set +e && rm -rf "${CAFFE_INSTALL_DIR}" && set -e
make install/strip

cd "${WD}"
