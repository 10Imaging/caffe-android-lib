#!/bin/bash -e
[[ -n $DEBUG_BUILD ]] && set -x

export PROTOBUFHOST_ROOT=${WD}/protobuf
export PROTOBUFHOST_BUILD_DIR=${PROTOBUFHOST_ROOT}/build_host/${ANDROID_ABI_SHORT}
export PROTOBUFHOST_INSTALL_DIR=${WD}/android_lib/${ANDROID_ABI_SHORT}/protobuf_host

if [ -f "${PROTOBUFHOST_INSTALL_DIR}/bin/protoc" ]; then
    echo "Found host protoc"
    exit 0
fi

if [ -n "${REMAKE_CMAKE}" ] ; then
  [[ -d ${PROTOBUFHOST_BUILD_DIR} ]] && set +e && rm -rf "${PROTOBUFHOST_BUILD_DIR}" && set -e
  mkdir -p "${PROTOBUFHOST_BUILD_DIR}"
  cd "${PROTOBUFHOST_BUILD_DIR}"
  cmake -DCMAKE_INSTALL_PREFIX="${PROTOBUFHOST_INSTALL_DIR}" \
        -DBUILD_TESTING=OFF \
        ../../cmake
fi

cd "${PROTOBUFHOST_BUILD_DIR}"
make -j${BUILD_NUM_CORES}
[[ -d "${PROTOBUFHOST_INSTALL_DIR}" ]] && set +e && rm -rf "${PROTOBUFHOST_INSTALL_DIR}" && set -e
make install/strip

cd "${WD}"
