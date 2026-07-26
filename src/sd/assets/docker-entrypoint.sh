#!/usr/bin/env bash

set -euo pipefail

case "${1:-app:start}" in
    fs:privileges)
        target="${2:-bareos:bareos}"
        find /etc/bareos ! -user "${target%%:*}" -exec chown "${target%%:*}" {} \;
        chown -R "${target}" /var/lib/bareos
        find /dev -regex "/dev/[n]?st[0-9]+" ! -user "${target%%:*}" -exec chown "${target%%:*}" {} \;
        find /dev -regex "/dev/tape/.*" ! -user "${target%%:*}" -exec chown "${target%%:*}" {} \;
        ;;
    app:start)
        /usr/sbin/bareos-sd -f
        ;;
    *)
        exec "$@"
        ;;
esac
