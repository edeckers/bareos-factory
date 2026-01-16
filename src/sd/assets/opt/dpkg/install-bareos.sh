#!/usr/bin/env bash

set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

function assert_env_complete () {
  if [[ -z "${BAREOS_VERSION:-}" ]]; then
      echo "Error: BAREOS_VERSION environment variable is required" >&2
      exit 1
  fi
}

assert_env_complete

apt-get update

apt-get -y install \
  apt-transport-https \
  ca-certificates \
  mt-st \
  mtx \
  scsitools \
  sg3-utils \
  ./bareos-common_${BAREOS_VERSION}.deb \
  ./bareos-tools_${BAREOS_VERSION}.deb \
  ./bareos-storage_${BAREOS_VERSION}.deb \
  ./bareos-storage-dplcompat_${BAREOS_VERSION}.deb \
  ./bareos-storage-tape_${BAREOS_VERSION}.deb

# Database packages for restoration
apt-get -y install \
  ./bareos-database-postgresql_${BAREOS_VERSION}.deb \
  ./bareos-database-common_${BAREOS_VERSION}.deb \
  ./bareos-database-tools_${BAREOS_VERSION}.deb
