#!/bin/bash -e
[[ -n $DEBUG_BUILD ]] && set -x

OPENBLAS_DOWNLOAD_LINK="http://sourceforge.net/projects/openblas/files/v0.2.8-arm/openblas-v0.2.8-android-rc1.tar.gz/download"
OPENBLAS_TAR="openblas-v0.2.8-android-rc1.tar.gz"
OPENBLAS_DIR=openblas-android

WD=$("$READLINK_CMD" -f "`dirname $0`/..")
export OPENBLAS_DOWNLOAD_DIR=${WD}/download
export OPENBLAS_INSTALL_DIR=${WD}/android_lib

[ ! -d ${OPENBLAS_INSTALL_DIR} ] && mkdir -p ${OPENBLAS_INSTALL_DIR}

[ ! -d ${OPENBLAS_DOWNLOAD_DIR} ] && mkdir -p ${OPENBLAS_DOWNLOAD_DIR}

cd "${OPENBLAS_DOWNLOAD_DIR}"
if [ ! -f ${OPENBLAS_TAR} ]; then
    wget -O ${OPENBLAS_TAR} ${OPENBLAS_DOWNLOAD_LINK}
fi

if [ ! -d "${OPENBLAS_INSTALL_DIR}/${OPENBLAS_DIR}" ]; then
    tar -zxf ${OPENBLAS_TAR}
    sed -i.bak -e '20d' ${OPENBLAS_DIR}/include/openblas_config.h
    set +e && rm -f ${OPENBLAS_DIR}/lib/*.so* && set -e
    mv "${OPENBLAS_DIR}" "${OPENBLAS_INSTALL_DIR}"
fi

cd "${WD}"
