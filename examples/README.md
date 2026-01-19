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
  -e DB_ADMIN_USER=bareos \
  -e DB_ADMIN_PASSWORD=bareos \
  -e PGDATABASE=bareos \
  director db:init
```

This creates the necessary tables and grants privileges. Only run this once during initial setup.

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
- `director_config`, `storage_config`, `filedaemon_config` - Additional runtime configs

## Further Reading

- [Bareos Documentation](https://docs.bareos.org/)
- [Main Repository README](../README.md) - Information about building the images
