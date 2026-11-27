#!/usr/bin/env bash

set -euo pipefail

# Run the example Compose stack end to end against locally built images:
# catalog init, a full backup, and a restore that must match the originals.
#
# Usage: smoke-test.sh [image-tag]
#
# edeckers/bareos-{dir,fd,sd}:<image-tag> are retagged as the version the
# example compose file references, and nothing Bareos is pulled, so a missing
# local image fails the run instead of silently testing the published one.
# image-tag defaults to that version.

function cd_to_examples_directory () {
  cd "$(dirname "${0}")/../examples"
}

function compose () {
  docker compose --project-name bareos-smoke "$@"
}

function bconsole () {
  compose exec -T director bconsole
}

function cleanup () {
  local status=$?
  [[ ${status} -ne 0 ]] && compose logs --no-color
  compose down --volumes
  exit ${status}
}

function wait_for_director () {
  for _ in $(seq 1 30); do
    echo 'status director' | bconsole 2>/dev/null | grep -q 'Daemon started' && return 0
    sleep 2
  done

  echo "Director did not come up" >&2
  return 1
}

function run_and_expect () {
  local commands="${1}"
  local expected="${2}"
  local output

  output="$(printf '%s\nwait\nmessages\nquit\n' "${commands}" | bconsole)"
  echo "${output}"
  grep -qE "Termination:.*${expected}" <<< "${output}"
}

cd_to_examples_directory

VERSION="$(cat ../.bareos-version)"
TAG="${1:-${VERSION}}"

for image in dir fd sd; do
  docker tag "edeckers/bareos-${image}:${TAG}" "edeckers/bareos-${image}:${VERSION}"
done

trap cleanup EXIT

compose pull postgres

compose run --rm --pull never \
  -e DB_ADMIN_USER=postgres \
  -e DB_ADMIN_PASSWORD=postgres \
  director db:init

compose up --detach --pull never

wait_for_director

run_and_expect 'run job=backup-bareos-fd level=Full yes' 'Backup OK'
run_and_expect 'restore client=bareos-fd fileset=LinuxDefault select all done yes' 'Restore OK'

# /etc/shadow is root-only, so a match also proves the FD reads files it doesn't own
compose exec -T filedaemon sh -c \
  'for f in /etc/passwd /etc/group /etc/shadow; do cmp "${f}" "/tmp/bareos-restores${f}"; done'

echo "Smoke test passed"
