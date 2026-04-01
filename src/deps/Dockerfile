FROM ubuntu:noble

ARG BAREOS_VERSION="25.0.3"
ARG POSTGRES_VERSION

LABEL maintainer="rough.grip1725@fastmail.com"

# 'Builder' code is licensed MPL-2.0, but the resulting image is
# AGPL-3.0-only as per Bareos licensing
LABEL license="AGPL-3.0-only"

LABEL org.opencontainers.image.version=$BAREOS_VERSION
LABEL org.opencontainers.image.description="Bareos Dependencies Build Environment"
LABEL org.opencontainers.image.source="https://github.com/edeckers/bareos-factory"

ENV BAREOS_DAEMON_USER=bareos
ENV BAREOS_DAEMON_GROUP=bareos

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
  acl-dev \
  aptitude \
  cmake \
  devscripts \
  dpkg \
  equivs \
  fakeroot \
  git \
  glusterfs-common \
  libglusterfs-dev \
  libgrpc++-dev \
  libjansson-dev \
  libpam0g-dev \
  libpq-dev \
  libprotoc-dev \
  libreadline-dev \
  libtirpc-dev \
  liblzo2-dev \
  php-fpm \
  postgresql-common \
  protobuf-compiler-grpc \
  python3-dev \
  qt6-base-dev

# Fixes https://github.com/bareos/bareos/issues/2231
#
RUN apt-get update && apt-get install -y \
  libgmock-dev \
  libgtest-dev \
  libpam-wrapper

RUN /usr/share/postgresql-common/pgdg/apt.postgresql.org.sh -i -v $POSTGRES_VERSION

# Fixes https://github.com/bareos/bareos/issues/2467

RUN cd /tmp \
  && git clone https://github.com/sebsura/indicators.git \
  && cd indicators \
  && git checkout 7853f903907d831604574fa7c24c0e3d98e4aa4b

RUN cd /opt \
  && git clone https://github.com/bareos/bareos \
  && cd /opt/bareos \
  && git fetch \
  && git checkout Release/$BAREOS_VERSION

RUN cd /opt/bareos \
  && mk-build-deps \
  && NOW=$(LANG=C date -R -u) \
  && cmake -P write_version_files.cmake \
  && printf "bareos (%s) unstable; urgency=low\n\n * dummy\n\n -- nobody<nob...@example.com> %s\n\n" "${BAREOS_VERSION}" "${NOW}" > debian/changelog \
  && sed -i '/^define CONFIGURE_COMMON$/a \  -DFETCHCONTENT_FULLY_DISCONNECTED=OFF \\' debian/rules

RUN cd /opt/bareos \
  && DEB_BUILD_OPTIONS="nocheck parallel=4" fakeroot debian/rules binary

