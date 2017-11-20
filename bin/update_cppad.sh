#!/bin/bash

THISDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CPPAD_DIR=${THISDIR}/../../CppAD
TMB_INCLUDE=${THISDIR}/../TMB/inst/include
BUILD_CPPAD=${CPPAD_DIR}/build_cppad_tmb

rm -rf ${TMB_INCLUDE}/cppad
cd ${CPPAD_DIR}/cppad; git clean -xdf
rm -rf ${BUILD_CPPAD}
mkdir ${BUILD_CPPAD}
cd ${BUILD_CPPAD}; cmake -D eigen_prefix=${TMB_INCLUDE} -D cppad_testvector=eigen ..
cp -r ${CPPAD_DIR}/cppad ${TMB_INCLUDE}
