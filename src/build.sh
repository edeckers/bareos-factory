#!/usr/bin/env bash

set -euo pipefail

export BAREOS_VERSION=${BF_BAREOS_VERSION:-"25.0.3"}
export POSTGRES_VERSION=${BF_POSTGRES_VERSION:-"18"}

BUILD_DEPS=${BF_BUILD_DEPS:-1}
BUILD_DIR=${BF_BUILD_DIR:-1}
BUILD_FD=${BF_BUILD_FD:-1}
BUILD_SD=${BF_BUILD_SD:-1}

function cd_to_src_directory () {
  cd `dirname ${0}`/.
}

cd_to_src_directory

echo "Building Bareos version $BAREOS_VERSION"

echo "Build dependencies: ${BUILD_DEPS}"
[[ $BUILD_DEPS == "1" ]] && deps/build.sh

echo "Build dir: ${BUILD_DIR}"
[[ $BUILD_DIR == "1" ]] && dir/build.sh

echo "Build fd ${BUILD_FD}"
[[ $BUILD_FD == "1" ]] && fd/build.sh

echo "Build sd ${BUILD_SD}"
[[ $BUILD_SD == "1" ]] && sd/build.sh

echo "Build process completed."

