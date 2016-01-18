#!/bin/bash
[[ -n $DEBUG_BUILD ]] && set -ex

if [ -d ${_WD}/protobuf ]; then
    export PROTOBUFHOST_ROOT=${_WD}/protobuf
else
    export PROTOBUFHOST_ROOT=${WD}/protobuf
fi
export PROTOBUFHOST_BUILD_DIR=${PROTOBUFHOST_ROOT}/build_host/${ANDROID_ABI_SHORT}
export PROTOBUFHOST_INSTALL_DIR=${WD}/android_lib/${ANDROID_ABI_SHORT}

if [ -f "${PROTOBUFHOST_INSTALL_DIR}/protobuf_host/bin/protoc" ]; then
    echo "Found host protoc"
    exit 0
fi

[[ -d ${PROTOBUFHOST_BUILD_DIR} ]] && rm -rf "${PROTOBUFHOST_BUILD_DIR}"
mkdir -p "${PROTOBUFHOST_BUILD_DIR}"
cd "${PROTOBUFHOST_BUILD_DIR}"

cmake -DCMAKE_INSTALL_PREFIX="${PROTOBUFHOST_INSTALL_DIR}/protobuf_host" \
      -DBUILD_TESTING=OFF \
      ../../cmake

make -j${BUILD_NUM_CORES}
rm -rf "${PROTOBUFHOST_INSTALL_DIR}/protobuf_host"
make install/strip

cd "${WD}"
rm -rf "${PROTOBUFHOST_BUILD_DIR}"
