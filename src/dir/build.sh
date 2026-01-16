#!/usr/bin/env bash

set -euo pipefail

function assert_env_complete () {
  if [[ -z "${BAREOS_VERSION:-}" ]]; then
      echo "Error: BAREOS_VERSION environment variable is required" >&2
      exit 1
  fi
  
  if [[ -z "${POSTGRES_VERSION:-}" ]]; then
      echo "Error: POSTGRES_VERSION environment variable is required" >&2
      exit 1
  fi
}

function cd_to_deps_directory () {
  cd `dirname ${0}`/.
}

assert_env_complete
cd_to_deps_directory

DOCKER_IMAGE="edeckers/bareos-dir"
DOCKER_TAG="${BAREOS_VERSION}"

echo "Building Docker image ${DOCKER_IMAGE}:${DOCKER_TAG} (native platform only)"
echo "For multi-arch deployment, use GitHub Actions workflow"

docker build . \
  --no-cache \
  --build-arg BAREOS_VERSION=${BAREOS_VERSION} \
  --build-arg POSTGRES_VERSION=${POSTGRES_VERSION} \
  -t ${DOCKER_IMAGE}:${DOCKER_TAG}

echo "Docker image ${DOCKER_IMAGE}:${DOCKER_TAG} built successfully."

