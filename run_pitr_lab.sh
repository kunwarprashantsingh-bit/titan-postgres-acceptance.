#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"
command -v docker >/dev/null || { echo 'Docker required' >&2; exit 2; }
docker compose version >/dev/null

# PITR lab assumes the source acceptance DB currently exists. Keep the environment after run_acceptance first:
# TITAN_KEEP_DOCKER=YES ./run_acceptance.sh
if ! docker compose exec -T db pg_isready -U postgres -d postgres >/dev/null 2>&1; then
  echo 'Source db container is not running. First run: TITAN_KEEP_DOCKER=YES ./run_acceptance.sh' >&2
  exit 3
fi

rm -rf artifacts/pitr
mkdir -p artifacts/pitr

docker compose --profile pitr rm -sf pitr-db pitr-prep pitr-verify >/dev/null 2>&1 || true

echo '[1/5] Reset PITR backup volume and take physical base backup locally'
docker compose exec -T db bash -lc "rm -rf /pitr/* && mkdir -p /pitr/18/docker && chown -R postgres:postgres /pitr && gosu postgres pg_basebackup -D /pitr/18/docker -Fp -Xs -P"

echo '[2/5] Create recovery markers, archive WAL and configure recovery target'
docker compose --profile pitr run --rm pitr-prep

echo '[3/5] Start recovered PostgreSQL cluster'
docker compose --profile pitr up -d pitr-db
for i in $(seq 1 120); do
  if docker compose --profile pitr exec -T pitr-db pg_isready -U postgres -d postgres >/dev/null 2>&1; then break; fi
  sleep 1
  [[ "$i" -lt 120 ]] || { echo 'PITR database did not become ready' >&2; exit 4; }
done

echo '[4/5] Verify target-time semantics and TITAN gates'
docker compose --profile pitr run --rm pitr-verify

echo '[5/5] PITR lab evidence'
cat artifacts/pitr/PITR_SUMMARY.txt

echo 'NOTE: This is disposable lab evidence; production RPO/RTO still requires the deployment PITR contract.'
