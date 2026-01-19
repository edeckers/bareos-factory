#!/usr/bin/env bash

set -euo pipefail

BAREOS_DAEMON_USER=${BAREOS_DAEMON_USER:-bareos}
BAREOS_DAEMON_GROUP=${BAREOS_DAEMON_GROUP:-bareos}

case "${1}" in
    fs:privileges)
        find /etc/bareos ! -user ${BAREOS_DAEMON_USER} -exec chown ${BAREOS_DAEMON_USER} {} \;
        chown -R ${BAREOS_DAEMON_USER}:${BAREOS_DAEMON_GROUP} /var/lib/bareos
        ;;
    app:start)
        /usr/sbin/bareos-fd -f
        ;;
    *)
        exec "$@"
        ;;
esac
