# Bareos Docker Compose Example

This directory contains a complete Docker Compose setup for running Bareos backup infrastructure using the pre-built images from Docker Hub.

## Images

- [edeckers/bareos-dir](https://hub.docker.com/r/edeckers/bareos-dir) - Bareos Director
- [edeckers/bareos-sd](https://hub.docker.com/r/edeckers/bareos-sd) - Bareos Storage Daemon
- [edeckers/bareos-fd](https://hub.docker.com/r/edeckers/bareos-fd) - Bareos File Daemon

## What's Included

This example deploys a full Bareos environment with:

- **PostgreSQL 18** - Database backend for the Bareos catalog
- **Bareos Director** - Central management component
- **Bareos Storage Daemon** - Handles backup storage
- **Bareos File Daemon** - Backup agent (can backup the container itself or mounted volumes)

## Configuration

The `config/` directory contains customized Bareos configurations:

- `config/bareos-dir/` - Director configuration with corrected database credentials
- `config/bareos-fd/` - File Daemon configuration
- `config/bareos-sd/` - Storage Daemon configuration (if customized)

These configurations are mounted read-only into the containers, overriding the default shipped configurations where needed.

## Getting Started

### 1. Initialize the Database

Before starting the services, initialize the Bareos database schema:

```bash
docker compose run --rm \
  -e DB_ADMIN_USER=postgres \
  -e DB_ADMIN_PASSWORD=postgres \
  director db:init
```

This connects to PostgreSQL as the cluster admin (`postgres`) to create the `bareos` database, tables, and the `bareos` catalog role used at runtime. Only run this once during initial setup.

### 2. Access the Director Console

Connect to the Bareos Console (bconsole):

```bash
docker compose exec director bconsole
```

Check the status of all connected daemons by running `status all`. The Director should successfully connect to both the Storage Daemon and File Daemon.

### 3. Run a Backup and Restore It

The `backup-bareos-fd` job backs up `/etc`, `/home` and `/root` from the File
Daemon (its `LinuxDefault` fileset). Run it from bconsole:

```
*run job=backup-bareos-fd yes
*wait
*messages
```

The job should end with `Termination: Backup OK`. To prove the files round-trip,
restore the most recent backup into a scratch directory:

```
*restore client=bareos-fd select all done
yes
```

Restored files land under `/tmp/bareos-restores` inside the File Daemon
container (`docker compose exec filedaemon ls /tmp/bareos-restores/etc`).

The File Daemon runs as `root` (see `docker-compose.yaml`) so it can read files
it does not own, such as `/etc/shadow` or another user's home directory. That is
what a backup agent normally needs. In production, drop it to the least
privilege your data allows.

## Ports

Exposed ports for external access:

- **9101** - Director (for remote bconsole connections)
- **9102** - File Daemon (for remote Directors)
- **9103** - Storage Daemon (for remote Directors/File Daemons)

## Volumes

Persistent data is stored in named volumes:

- `postgres_data` - PostgreSQL database files
- `storage_data` - Backup archives
- `catalog_dump` - Catalog dump shared between the Director and File Daemon (see [Catalog Backup](#catalog-backup))

## Catalog Backup

The `BackupCatalog` job dumps the PostgreSQL catalog and backs it up. Because the Director and File Daemon run in separate containers, this needs a little wiring:

1. The Director's `RunBeforeJob` runs `make_catalog_backup`, which writes the dump to `/var/lib/bareos/bareos.sql` inside the Director container.
2. A second `RunBeforeJob` copies it into the shared `catalog_dump` volume at `/backups/bareos/catalog/bareos.sql`.
3. The File Daemon mounts that volume read-only and backs the dump up through the `Catalog` fileset.

A one-shot `catalog-init` service runs first to `chown` the volume to the `bareos` user. A fresh named volume is owned by root, and the Director runs as an unprivileged user, so without this step it could not write the dump. This is the Compose equivalent of a Kubernetes initContainer.

The job's bootstrap (the recipe to restore the catalog without a working catalog) is saved to a file and also printed to the Director's log, so you can watch it with `docker compose logs director`.

## Before Production

This is a runnable example, not a hardened production setup. It makes a few deliberate demo tradeoffs: the File Daemon backs up its own container's filesystem rather than the host, and the catalog bootstrap is stored alongside the backups instead of offsite.

So, before trusting Bareos with real data, read the Bareos [Critical Items to Implement Before Production](https://docs.bareos.org/IntroductionAndTutorial/CriticalItemsToImplementBeforeProduction.html) page and check this setup against it.

## Further Reading

- [Bareos Documentation](https://docs.bareos.org/)
- [Main Repository README](../README.md) - Information about building the images
