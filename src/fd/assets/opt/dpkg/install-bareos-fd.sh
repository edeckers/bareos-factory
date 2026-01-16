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
  ./bareos-common_${BAREOS_VERSION}.deb \
  ./bareos-bconsole_${BAREOS_VERSION}.deb \
  ./bareos-filedaemon_${BAREOS_VERSION}.deb \
  ./bareos-client_${BAREOS_VERSION}.deb \
  ./bareos-filedaemon-postgresql-python-plugin_${BAREOS_VERSION}.deb \
  ./bareos-filedaemon-python3-plugin_${BAREOS_VERSION}.deb \
  ./bareos-filedaemon-python-plugins-common_${BAREOS_VERSION}.deb

