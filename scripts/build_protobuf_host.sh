#!/usr/bin/env sh
set -ex

WD=$("$READLINK_CMD" -f "`dirname $0`/..")
PROTOBUF_ROOT=${WD}/protobuf
BUILD_DIR=${PROTOBUF_ROOT}/build_host/${ANDROID_ABI}
INSTALL_DIR=${WD}/android_lib/${ANDROID_ABI}

if [ -f "${INSTALL_DIR}/protobuf_host/bin/protoc" ]; then
    echo "Found host protoc"
    exit 0
fi

rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"
cd "${BUILD_DIR}"

cmake -DCMAKE_INSTALL_PREFIX="${INSTALL_DIR}/protobuf_host" \
      -DBUILD_TESTING=OFF \
      ../../cmake

make -j
rm -rf "${INSTALL_DIR}/protobuf_host"
make install/strip

cd "${WD}"
rm -rf "${BUILD_DIR}"
