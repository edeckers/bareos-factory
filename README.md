# Bareos Factory - Docker images for Bareos Backup

[![Docker Hub](https://img.shields.io/badge/Docker%20Hub-edeckers%2Fbareos-blue?logo=docker)](https://hub.docker.com/r/edeckers/bareos-dir)
[![Release](https://github.com/edeckers/bareos-factory/actions/workflows/release.yaml/badge.svg)](https://github.com/edeckers/bareos-factory/actions/workflows/release.yaml)
[![License](https://img.shields.io/badge/License-MPL--2.0-blue.svg)](https://opensource.org/licenses/MPL-2.0)
[![Bareos](https://img.shields.io/badge/Bareos-25.0.3-green)](https://github.com/bareos/bareos)
[![Multi-Arch](https://img.shields.io/badge/platform-amd64%20%7C%20arm64-lightgrey)](https://github.com/edeckers/bareos-factory)

Run [Bareos](https://bareos.com) in Docker with multi-architecture support (amd64/arm64). These images provide a containerized Bareos backup infrastructure - Director, Storage Daemon, and File Daemon - ready to deploy with Docker Compose.

> **Note:** This project is maintained on a best-effort basis. See [Project Status](#project-status--maintenance) for details.

## Quick Start

Want to try it out? See [examples/](examples/) for a ready-to-use Docker Compose setup.

## Images

| Image                                                                          | Description                               |
|--------------------------------------------------------------------------------|-------------------------------------------|
| [`edeckers/bareos-dir:25.0.3`](https://hub.docker.com/r/edeckers/bareos-dir)   | Bareos Director                           |
| [`edeckers/bareos-fd:25.0.3`](https://hub.docker.com/r/edeckers/bareos-fd)     | Bareos File Daemon                        |
| [`edeckers/bareos-sd:25.0.3`](https://hub.docker.com/r/edeckers/bareos-sd)     | Bareos Storage Daemon                     |
| [`edeckers/bareos-deps:25.0.3`](https://hub.docker.com/r/edeckers/bareos-deps) | `.deb` packages for all Bareos components |

## Requirements

To run a complete Bareos backup infrastructure, you need:

- **PostgreSQL Database** - Required for the Director's catalog
  - Minimum version: PostgreSQL 12 (images built with PostgreSQL 18)
  - Must be accessible from the Director container
  - Initialize using the Director's `db:init` command

- **Network Connectivity** - Bareos components communicate over specific ports:
  - Director: Port 9101 (for Console connections)
  - Storage Daemon: Port 9103 (for Director and File Daemon connections)
  - File Daemon: Port 9102 (for Director connections)

- **Storage** - The Storage Daemon requires persistent storage for backup archives

These images assume you will provide your own PostgreSQL instance and handle network configuration appropriate for your environment.

## Getting Started

### Director

```bash
# Initialize databaser, first time setup. Use your own credentials
docker run --rm \
  -e DB_ADMIN_USER=bareos
  -e DB_ADMIN_PASSWORD=bareos \
  -e PGDATABASE=bareos \
  edeckers/bareos-dir:25.0.3 db:init

# Start Director, use your own credentials
docker run -d \
  --name bareos-dir \
  -e DB_HOST=postgres \
  -e DB_PORT=5432 \
  -e DB_NAME=bareos \
  -e DB_USER=postgres \
  -e DB_PASSWORD=bareos \
  edeckers/bareos-dir:25.0.3
```

### File Daemon

```bash
docker run -d --name bareos-fd edeckers/bareos-fd:25.0.3
```

### Storage Daemon

```bash
docker run -d --name bareos-sd edeckers/bareos-sd:25.0.3
```

## Environment Variables

### Director

These are all required, they're used to verify the database connection before starting the Director:

- `DB_HOST` - PostgreSQL host
- `DB_PORT` - PostgreSQL port
- `DB_NAME` - Database name
- `DB_USER` - Database user
- `DB_PASSWORD` - Database password

### Storage Daemon

- None

### File Daemon

- None

## Database Commands

The Director image includes database management commands for PostgreSQL catalog setup:

- `db:init` - Initialize a new Bareos database (run once on first setup)
- `db:update` - Update existing database schema (run after upgrading Bareos versions)

Example:
```bash
docker run --rm \
  -e DB_HOST=postgres \
  -e DB_PASSWORD=bareos \
  edeckers/bareos-dir:25.0.3 db:init
```

## Architecture Support

All images support both **amd64** and **arm64** architectures.

## Building

### Environment Variables

Configure the build process using these environment variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `BF_BAREOS_VERSION` | `25.0.3` | Bareos version to build |
| `BF_POSTGRES_VERSION` | `18` | PostgreSQL version |
| `BF_BUILD_DEPS` | `1` | Build bareos-deps (0 to skip) |
| `BF_BUILD_DIR` | `1` | Build bareos-dir (0 to skip) |
| `BF_BUILD_FD` | `1` | Build bareos-fd (0 to skip) |
| `BF_BUILD_SD` | `1` | Build bareos-sd (0 to skip) |

### Build All Images

```bash
./build.sh
```

This builds all enabled images for the configured platforms and pushes them to DockerHub.

### Build Specific Images

To build only specific images, set the corresponding build flags:

```bash
# Build only Director and File Daemon
BF_BUILD_DEPS=1 BF_BUILD_DIR=1 BF_BUILD_FD=1 BF_BUILD_SD=0 build.sh
```

### Custom Version

```bash
BF_BAREOS_VERSION=x.y.z ./build.sh
```

## Configuration

All containers start with reasonable defaults when run without arguments. Mount your configuration files to customize behavior:

```bash
docker run -d \
  -v /path/to/config:/etc/bareos \
  edeckers/bareos-dir:25.0.3
```

## Troubleshooting

### Permission Issues
If the File Daemon cannot access certain files, run the container as root:
```bash
docker run -d --user root --name bareos-fd edeckers/bareos-fd:25.0.3
```

### Database Connection Issues
Ensure PostgreSQL is accessible and credentials are correct. Test with:
```bash
docker run --rm postgres:18 psql -h <DB_HOST> -U bareos -d bareos
```

## Project Status & Maintenance

This project is maintained on a **best-effort basis**. I built these images to solve my own backup needs, and I'll continue maintaining them as long as I'm actively using Bareos in my infrastructure.

**What you can expect:**

- Regular updates to track new Bareos releases while I'm using the software
- Support for **Debian/Ubuntu-based images only** (this is what I use and test)
- Bug fixes and improvements that affect my own deployments
- Responsive to issues and pull requests when time permits

**Contributions welcome:**

- Pull requests are appreciated and will be reviewed
- If you have ideas for improvements or support for other distributions, I'm open to discussion
- Community contributions help make this project better for everyone

**Platform support:**

- Currently focused on Debian/Ubuntu base images
- No plans to support other distributions (Alpine, RHEL, etc.) unless there's significant community interest and contribution

## Security issues

The security policy of this project is described in [SECURITY.md](SECURITY.md)

## Acknowledgements

When exploring Bareos, I found [this Bareos Docker repository of @barcus](https://github.com/barcus/bareos) extremely useful - got me started quickly and allowed me to get quickly acquainted with the software. It was also an inspiration for this repository.

## License

[MPL-2.0](LICENSE)

### Bareos License

The Bareos software built and distributed through these Docker images is licensed under **AGPL-3.0-only**.

- Bareos source code: https://github.com/bareos/bareos
- Bareos version: 25.0.3
- Bareos license: https://github.com/bareos/bareos/blob/master/LICENSE.txt

By using these Docker images, you agree to comply with the AGPL-3.0-only license terms for Bareos.

