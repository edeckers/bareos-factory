#!/usr/bin/env bash

set -euo pipefail

BAREOS_DAEMON_USER=${BAREOS_DAEMON_USER:-bareos}
BAREOS_DAEMON_GROUP=${BAREOS_DAEMON_GROUP:-bareos}

wait_for_db() {
    echo "Waiting for PostgreSQL database to be ready"

    while true; do
        if PGPASSWORD="${DB_PASSWORD}" pg_isready \
            --host="${DB_HOST}" \
            --port="${DB_PORT}" \
            --user="${DB_USER}" \
            --dbname="bareos" >/dev/null 2>&1; then
            echo "PostgreSQL database is ready"
            break
        else
            echo "Cannot connect to database. Did you initialize it with db:init? Retrying in 5 seconds"
            sleep 5
        fi
    done
}

db_init() {
    echo "Starting database initialization"

    export PGHOST="${DB_HOST}"
    export PGPORT="${DB_PORT}"
    export PGUSER="${DB_ADMIN_USER}"
    export PGPASSWORD="${DB_ADMIN_PASSWORD}"

    /usr/lib/bareos/scripts/create_bareos_database 2>&1
    /usr/lib/bareos/scripts/make_bareos_tables 2>&1
    /usr/lib/bareos/scripts/grant_bareos_privileges 2>&1

    echo "Database initialization completed successfully"
}

db_update() {
    echo "Updating database contents"

    export PGHOST="${DB_HOST}"
    export PGPORT="${DB_PORT}"
    export PGUSER="${DB_ADMIN_USER}"
    export PGPASSWORD="${DB_ADMIN_PASSWORD}"

    /usr/lib/bareos/scripts/update_bareos_tables 2>&1
    /usr/lib/bareos/scripts/grant_bareos_privileges 2>&1

    echo "Database update completed successfully"
}

case "${1}" in
    db:init)
        db_init
        ;;
    db:update)
        db_update
        ;;
    fs:privileges)
        find /etc/bareos ! -user ${BAREOS_DAEMON_USER} -exec chown ${BAREOS_DAEMON_USER} {} \;
        chown -R ${BAREOS_DAEMON_USER}:${BAREOS_DAEMON_GROUP} /var/lib/bareos
        ;;
    app:start)
        wait_for_db

	echo "Starting Bareos Director"
        /usr/sbin/bareos-dir -f
        ;;
    *)
        exec "$@"
        ;;
esac
