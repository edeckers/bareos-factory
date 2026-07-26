ARG BAREOS_VERSION="25.0.4"

FROM edeckers/bareos-deps:$BAREOS_VERSION AS bareos-deps

FROM ubuntu:noble

ARG BAREOS_VERSION="25.0.4"

LABEL maintainer="rough.grip1725@fastmail.com"

# 'Builder' code is licensed MPL-2.0, but the resulting image is
# AGPL-3.0-only as per Bareos licensing
LABEL license="AGPL-3.0-only"

LABEL org.opencontainers.image.version=$BAREOS_VERSION
LABEL org.opencontainers.image.description="Bareos File Daemon"
LABEL org.opencontainers.image.source="https://github.com/edeckers/bareos-factory"

ENV BAREOS_DAEMON_USER=bareos
ENV BAREOS_DAEMON_GROUP=bareos

ARG BAREOS_UID=101
ARG BAREOS_GID=101

# Claim a fixed uid/gid before any package install, so volume ownership
# stays stable across rebuilds
RUN groupadd -g $BAREOS_GID bareos \
 && useradd -r -u $BAREOS_UID -g bareos -d /var/lib/bareos -s /usr/sbin/nologin bareos

COPY --from=bareos-deps /opt/*.deb /opt/dpkg/

RUN apt-get update && apt-get install -y \
      rename

# Ditch the architecture suffix in the .deb filenames. Kind of hacky
# with the string matching, but it works good enough
RUN rename 's/_a.*\.deb/.deb/' /opt/dpkg/*.deb

ADD assets/opt/dpkg/install-bareos-fd.sh /opt/dpkg/install-bareos.sh
RUN cd /opt/dpkg && /opt/dpkg/install-bareos.sh

RUN apt-get clean
RUN rm -rf /var/lib/apt/lists/*

COPY assets/docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod u+x /docker-entrypoint.sh

EXPOSE 9102

USER bareos

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["app:start"]

