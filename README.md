# Bareos Factory

[![Docker Hub](https://img.shields.io/badge/Docker%20Hub-edeckers%2Fbareos-blue?logo=docker)](https://hub.docker.com/u/edeckers)
[![Release](https://github.com/edeckers/bareos-factory/actions/workflows/release.yaml/badge.svg)](https://github.com/edeckers/bareos-factory/actions/workflows/release.yaml)
[![License](https://img.shields.io/badge/License-MPL--2.0-blue.svg)](https://opensource.org/licenses/MPL-2.0)
[![Bareos](https://img.shields.io/badge/Bareos-24.0.0-green)](https://github.com/bareos/bareos)
[![Multi-Arch](https://img.shields.io/badge/platform-amd64%20%7C%20arm64-lightgrey)](https://github.com/edeckers/bareos-factory)

Builder and publisher of [Bareos](https://bareos.com) Docker images.

> **Note:** This project is maintained on a best-effort basis. See [Project Status](#project-status--maintenance) for details.

## Images

- **edeckers/bareos-deps:24.0.0** - Contains `.deb` packages for all Bareos components
- **edeckers/bareos-dir:24.0.0** - Bareos Director
- **edeckers/bareos-fd:24.0.0** - Bareos File Daemon
- **edeckers/bareos-sd:24.0.0** - Bareos Storage Daemon

## Quick Start

### Director

```bash
# Start with defaults
docker run -d --name bareos-dir edeckers/bareos-dir:24.0.0

# Initialize database
docker run --rm edeckers/bareos-dir:24.0.0 db:init

# Update database schema
docker run --rm edeckers/bareos-dir:24.0.0 db:update
```

### File Daemon

```bash
docker run -d --name bareos-fd edeckers/bareos-fd:24.0.0
```

### Storage Daemon

```bash
docker run -d --name bareos-sd edeckers/bareos-sd:24.0.0
```

## Database Commands

The Director image includes database management commands:

- `db:init` - Initialize a new Bareos database
- `db:update` - Update existing database schema

## Architecture Support

All images support both **amd64** and **arm64** architectures.

Replace the entire "Building" section with this:

## Building

### Environment Variables

Configure the build process using these environment variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `BF_BAREOS_VERSION` | `24.0.0` | Bareos version to build |
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
  edeckers/bareos-dir:24.0.0
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

## Acknowledgements

When exploring the Bareos,  I found [this Bareos Docker repository of @barcus](https://github.com/barcus/bareos) extremely useful - got me started quickly and allowed me to get quickly acquainted with the software. It was also an inspiration for this repository.

## License

MPL-2.0

### Bareos License

The Bareos software built and distributed through these Docker images is licensed under **AGPL-3.0-only**.

- Bareos source code: https://github.com/bareos/bareos
- Bareos version: 24.0.0
- Bareos license: https://github.com/bareos/bareos/blob/master/LICENSE.txt

By using these Docker images, you agree to comply with the AGPL-3.0-only license terms for Bareos.