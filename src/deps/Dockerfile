FROM ubuntu:noble

ARG BAREOS_VERSION="25.1.1"
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
  curl \
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
  qt6-base-dev \
  xz-utils

# Fixes https://github.com/bareos/bareos/issues/2231
#
RUN apt-get update && apt-get install -y \
  libgmock-dev \
  libgtest-dev \
  libpam-wrapper

RUN /usr/share/postgresql-common/pgdg/apt.postgresql.org.sh -i -v $POSTGRES_VERSION

# The webui-vue dist must be built from source in git checkouts, and its
# toolchain (vite 8) needs node >= 22.12, newer than anything in noble
ENV NODE_VERSION=22.23.2
RUN case "$(dpkg --print-architecture)" in \
    amd64) NODE_ARCH=x64   NODE_SHA256=d60acfe00a2932254bb0ad20e01b0d74397a0875595de719654b214f4b03f307 ;; \
    arm64) NODE_ARCH=arm64 NODE_SHA256=fff4078c5def658577f92c88db7db3bc0072924bfb93fe52c1e744a54e94abb8 ;; \
    *) echo "unsupported architecture" >&2; exit 1 ;; \
  esac \
  && curl -fsSL "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-${NODE_ARCH}.tar.xz" -o /tmp/node.tar.xz \
  && echo "${NODE_SHA256}  /tmp/node.tar.xz" | sha256sum -c - \
  && tar -xJf /tmp/node.tar.xz -C /usr/local --strip-components=1 \
  && rm /tmp/node.tar.xz

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
  && sed -i '/^define CONFIGURE_COMMON$/a \  -DFETCHCONTENT_FULLY_DISCONNECTED=OFF \\' debian/rules \
  && if [ -d webui-vue ]; then printf 'override_dh_auto_build:\n\tdh_auto_build\n\tcmake --build cmake-build/ --target bareos-webui-vue-build\n' >> debian/rules; fi

RUN cd /opt/bareos \
  && DEB_BUILD_OPTIONS="nocheck parallel=4" fakeroot debian/rules binary

