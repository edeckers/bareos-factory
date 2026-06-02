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

## Further Reading

- [Bareos Documentation](https://docs.bareos.org/)
- [Main Repository README](../README.md) - Information about building the images
