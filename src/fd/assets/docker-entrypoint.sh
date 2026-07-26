#!/usr/bin/env bash

set -euo pipefail

case "${1:-app:start}" in
    fs:privileges)
        target="${2:-bareos:bareos}"
        find /etc/bareos ! -user "${target%%:*}" -exec chown "${target%%:*}" {} \;
        chown -R "${target}" /var/lib/bareos
        ;;
    app:start)
        /usr/sbin/bareos-fd -f
        ;;
    *)
        exec "$@"
        ;;
esac
