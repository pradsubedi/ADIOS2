#!/bin/bash

mkdir -p ${HOME}/dashboards/summitdev/adios2
cd ${HOME}/dashboards/summitdev/adios2

module purge
module load git cmake lsf-tools

CTEST=$(which ctest)

if [ ! -d source/.git ]
then
  git clone https://github.com/ornladios/adios2.git source
else
  pushd source
  git fetch --all -p
  git checkout -f master
  git pull --ff-only
  popd
fi
SCRIPT_DIR=${PWD}/source/scripts/dashboard/nightly

# First run the serial tests
${CTEST} -VV -S ${SCRIPT_DIR}/summitdev-gcc-nompi.cmake 2>&1 1>summitdev-gcc-nompi.log
${CTEST} -VV -S ${SCRIPT_DIR}/summitdev-xl-nompi.cmake 2>&1 1>summitdev-xl-nompi.log
${CTEST} -VV -S ${SCRIPT_DIR}/summitdev-pgi-nompi.cmake 2>&1 1>summitdev-pgi-nompi.log

# Now run the configure and build steps for the MPI tests
${CTEST} -VV -S ${SCRIPT_DIR}/summitdev-gcc-spectrum.cmake \
  -Ddashboard_full=OFF \
  -Ddashboard_fresh=ON \
  -Ddashboard_do_checkout=ON \
  -Ddashboard_do_update=ON \
  -Ddashboard_do_configure=ON \
  -Ddashboard_do_build=ON 2>&1 1>summitdev-gcc-spectrum.log

${CTEST} -VV -S ${SCRIPT_DIR}/summitdev-xl-spectrum.cmake \
  -Ddashboard_full=OFF \
  -Ddashboard_fresh=ON \
  -Ddashboard_do_checkout=ON \
  -Ddashboard_do_update=ON \
  -Ddashboard_do_configure=ON \
  -Ddashboard_do_build=ON 2>&1 1>summitdev-xl-spectrum.log

${CTEST} -VV -S ${SCRIPT_DIR}/summitdev-pgi-spectrum.cmake \
  -Ddashboard_full=OFF \
  -Ddashboard_fresh=ON \
  -Ddashboard_do_checkout=ON \
  -Ddashboard_do_update=ON \
  -Ddashboard_do_configure=ON \
  -Ddashboard_do_build=ON 2>&1 1>summitdev-pgi-spectrum.log

# Now run the MPI tests in a batch job
bsub -P CSC143SUMMITDEV -W 00:30 -nnodes 2 -I \
  ${SCRIPT_DIR}/summitdev-spectrum-tests.lsf

# Finaly submit the test results from the batch job
${CTEST} -VV -S ${SCRIPT_DIR}/summitdev-gcc-spectrum.cmake \
  -Ddashboard_full=OFF \
  -Ddashboard_do_test=ON \
  -Ddashboard_do_submit_only=ON 2>&1 1>>summitdev-gcc-spectrum.log

${CTEST} -VV -S ${SCRIPT_DIR}/summitdev-xl-spectrum.cmake \
  -Ddashboard_full=OFF \
  -Ddashboard_do_test=ON \
  -Ddashboard_do_submit_only=ON 2>&1 1>>summitdev-xl-spectrum.log

${CTEST} -VV -S ${SCRIPT_DIR}/summitdev-pgi-spectrum.cmake \
  -Ddashboard_full=OFF \
  -Ddashboard_do_test=ON \
  -Ddashboard_do_submit_only=ON 2>&1 1>>summitdev-pgi-spectrum.log
