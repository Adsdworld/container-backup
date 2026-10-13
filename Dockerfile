FROM debian:trixie-slim

RUN apt-get update \
 && apt-get install -y --no-install-recommends git rsync tini \
 && rm -rf /var/lib/apt/lists/*

COPY rootfs/ /
RUN chmod 755 /usr/local/bin/backup-start /usr/local/bin/backup-once

ARG IMAGE_VERSION=dev
ENV IMAGE_VERSION=$IMAGE_VERSION \
    BACKUP_INTERVAL=300

VOLUME ["/backup/config", "/backup/data"]
WORKDIR /backup/data
ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/backup-start"]
