#!/usr/bin/env bash
set -euo pipefail
mkdir -p /wal_archive /pitr
chown postgres:postgres /wal_archive /pitr
chmod 700 /wal_archive
exec docker-entrypoint.sh "$@"
