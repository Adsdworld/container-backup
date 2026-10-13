FROM debian:trixie-slim

RUN apt-get update \
 && apt-get install -y --no-install-recommends git rsync tini \
 && rm -rf /var/lib/apt/lists/*

COPY rootfs/ /
RUN chmod 755 /usr/local/bin/entrypoint.sh /usr/local/bin/backup-health

ARG IMAGE_VERSION=dev
ENV IMAGE_VERSION=$IMAGE_VERSION \
    BACKUP_INTERVAL=300 \
    SOURCE_FOLDER=/source

VOLUME ["/data"]
WORKDIR /data
HEALTHCHECK --interval=10s --timeout=5s --start-period=10s --start-interval=1s --retries=1 \
    CMD backup-health | grep -qx Ok
ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/entrypoint.sh"]
