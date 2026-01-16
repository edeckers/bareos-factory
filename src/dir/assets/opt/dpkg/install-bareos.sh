#!/usr/bin/env bash

set -euo pipefail

function assert_env_complete () {
  if [[ -z "${BAREOS_VERSION:-}" ]]; then
      echo "Error: BAREOS_VERSION environment variable is required" >&2
      exit 1
  fi
}

assert_env_complete

echo "bareos-database-common bareos-database-common/dbconfig-install boolean false" | debconf-set-selections
echo "bareos-database-common bareos-database-common/install-error select ignore" | debconf-set-selections
echo "bareos-database-common bareos-database-common/database-type select pgsql" | debconf-set-selections
echo "bareos-database-common bareos-database-common/missing-db-package-error select ignore" | debconf-set-selections
echo 'postfix postfix/main_mailer_type select No configuration' | debconf-set-selections

DEBIAN_FRONTEND=noninteractive

apt-get update

apt-get -y install \
  apt-transport-https \
  ca-certificates \
  ./bareos-common_${BAREOS_VERSION}.deb \
  ./bareos-database-postgresql_${BAREOS_VERSION}.deb \
  ./bareos-database-common_${BAREOS_VERSION}.deb \
  ./bareos-database-tools_${BAREOS_VERSION}.deb \
  ./bareos-director_${BAREOS_VERSION}.deb \
  ./bareos-tools_${BAREOS_VERSION}.deb \
  ./bareos-bconsole_${BAREOS_VERSION}.deb

