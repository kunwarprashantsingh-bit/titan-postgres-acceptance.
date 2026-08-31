#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

for cmd in docker; do
  command -v "$cmd" >/dev/null || { echo "Docker is required: $cmd not found" >&2; exit 2; }
done
docker compose version >/dev/null

mkdir -p artifacts
rm -rf artifacts/full_acceptance artifacts/full_replay artifacts/concurrency artifacts/load artifacts/restore artifacts/ACCEPTANCE_SUMMARY.txt

echo '[1/5] Reset disposable Docker acceptance environment'
docker compose down -v --remove-orphans >/dev/null 2>&1 || true

echo '[2/5] Build pinned PostgreSQL 18.6 acceptance image'
docker compose build --pull

echo '[3/5] Start isolated PostgreSQL server'
docker compose up -d db

cleanup() {
  if [[ "${TITAN_KEEP_DOCKER:-NO}" != "YES" ]]; then
    docker compose down -v --remove-orphans >/dev/null 2>&1 || true
  else
    echo 'TITAN_KEEP_DOCKER=YES: leaving Docker environment running for inspection.'
  fi
}
trap cleanup EXIT

for i in $(seq 1 90); do
  if docker compose exec -T db pg_isready -U postgres -d postgres >/dev/null 2>&1; then
    break
  fi
  sleep 1
  [[ "$i" -lt 90 ]] || { echo 'PostgreSQL did not become healthy.' >&2; exit 3; }
done

echo '[4/5] Execute full acceptance + replay + concurrency + load + logical restore'
docker compose run --rm runner

echo '[5/5] Acceptance evidence written to ./artifacts'
cat artifacts/ACCEPTANCE_SUMMARY.txt
