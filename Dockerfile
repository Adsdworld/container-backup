FROM debian:trixie-slim

RUN apt-get update \
 && apt-get install -y --no-install-recommends git rsync tini \
 && rm -rf /var/lib/apt/lists/*

COPY rootfs/ /
RUN chmod 755 /usr/local/bin/backup-start

ARG IMAGE_VERSION=dev
ENV IMAGE_VERSION=$IMAGE_VERSION

VOLUME ["/config", "/data"]
WORKDIR /data
ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/backup-start"]
