FROM postgres:18.6-bookworm

USER root
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        diffutils \
    ; \
    rm -rf /var/lib/apt/lists/*; \
    command -v psql; \
    command -v createdb; \
    command -v dropdb; \
    command -v pg_dump; \
    command -v pg_restore; \
    command -v pg_dumpall; \
    command -v pgbench; \
    test -f /usr/share/postgresql/18/extension/btree_gist.control; \
    test -f /usr/share/postgresql/18/extension/pgcrypto.control

COPY docker/db_entrypoint.sh /usr/local/bin/titan-db-entrypoint
RUN chmod +x /usr/local/bin/titan-db-entrypoint

LABEL org.opencontainers.image.title="TITAN PostgreSQL 18.6 Acceptance Runtime" \
      org.opencontainers.image.description="Disposable PostgreSQL 18.6 runtime for Project TITAN sustainability database acceptance" \
      org.opencontainers.image.version="1.0"
