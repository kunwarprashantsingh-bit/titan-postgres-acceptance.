#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

printf 'TITAN PostgreSQL 18.6 — GitHub Codespaces live acceptance\n'
printf 'Local laptop installation required: NONE\n\n'

for i in $(seq 1 60); do
  if docker info >/dev/null 2>&1; then
    break
  fi
  sleep 2
  if [[ "$i" -eq 60 ]]; then
    echo 'Docker-in-Docker daemon did not become ready inside Codespaces.' >&2
    echo 'Use Command Palette > Codespaces: Rebuild Container, then run this script again.' >&2
    exit 2
  fi
done

docker version
docker compose version

export TITAN_KEEP_DOCKER="${TITAN_KEEP_DOCKER:-NO}"
./run_acceptance.sh
