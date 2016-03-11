#!/bin/bash -e
[[ -n $DEBUG_BUILD ]] && set -x

EIGEN_VER1=3
EIGEN_VER2=2
EIGEN_VER3=7

EIGEN_DOWNLOAD_LINK="http://bitbucket.org/eigen/eigen/get/${EIGEN_VER1}.${EIGEN_VER2}.${EIGEN_VER3}.tar.bz2"
EIGEN_TAR="eigen_${EIGEN_VER1}.${EIGEN_VER2}.${EIGEN_VER3}.tar.bz2"
EIGEN_DIR=eigen3

WD=$("$READLINK_CMD" -f "`dirname $0`/..")
export EIGEN_DOWNLOAD_DIR=${WD}/download
export EIGEN_INSTALL_DIR=${WD}/android_lib/${ANDROID_ABI_SHORT}

[ ! -d ${EIGEN_INSTALL_DIR} ] && mkdir -p ${EIGEN_INSTALL_DIR}

[ ! -d ${EIGEN_DOWNLOAD_DIR} ] && mkdir -p ${EIGEN_DOWNLOAD_DIR}

cd "${EIGEN_DOWNLOAD_DIR}"
if [ ! -f ${EIGEN_TAR} ]; then
    wget -O ${EIGEN_TAR} ${EIGEN_DOWNLOAD_LINK}
fi

if [ ! -d "${EIGEN_INSTALL_DIR}/${EIGEN_DIR}" ]; then
    tar -jxf ${EIGEN_TAR}
    mv eigen-eigen-*/ "${EIGEN_INSTALL_DIR}/${EIGEN_DIR}"
fi

cd "${WD}"
