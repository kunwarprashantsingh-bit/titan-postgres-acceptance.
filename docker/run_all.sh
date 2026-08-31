#!/usr/bin/env bash
set -euo pipefail

CORE=/workspace/core
ART=/workspace/artifacts
mkdir -p "$ART"/{full_acceptance,full_replay,concurrency,load,restore}

export TITAN_ACCEPTANCE_ALLOW_DROP=YES
export TITAN_ACCEPTANCE_DB=titan_acceptance_full_docker
export TITAN_ACCEPTANCE_LOG_DIR="$ART/full_acceptance"
export TITAN_FULL_REPLAY_DIR="$ART/full_replay"
export TITAN_CONCURRENCY_LOG_DIR="$ART/concurrency"
export TITAN_LOAD_LOG_DIR="$ART/load"
export TITAN_RESTORE_LOG_DIR="$ART/restore"
export TITAN_RESTORE_DB=titan_acceptance_restore_docker

printf '%s\n' '=== TITAN PostgreSQL 18.6 Live Acceptance ==='
psql -X -v ON_ERROR_STOP=1 -d postgres -c "SELECT version(), current_user, current_database();"
printf '%s\n' 'Available required extensions:'
psql -X -v ON_ERROR_STOP=1 -d postgres -c "SELECT name,default_version FROM pg_available_extensions WHERE name IN ('btree_gist','pgcrypto') ORDER BY name;"

printf '%s\n' '--- 1/5 Full operational acceptance ---'
bash "$CORE/acceptance/run_full_operational_acceptance.sh"

printf '%s\n' '--- 2/5 Deterministic two-clean-run replay ---'
bash "$CORE/acceptance/run_full_replay_twice.sh"

# Replay script changes TITAN_ACCEPTANCE_DB inside its own process only; reset explicitly.
export TITAN_ACCEPTANCE_DB=titan_acceptance_full_docker

printf '%s\n' '--- 3/5 Two-writer optimistic concurrency ---'
bash "$CORE/load/run_optimistic_concurrency.sh"

printf '%s\n' '--- 4/5 pgbench smoke ---'
bash "$CORE/load/run_pgbench_smoke.sh"

printf '%s\n' '--- 5/5 Logical restore drill ---'
bash "$CORE/recovery/run_logical_restore_drill.sh"

{
  echo 'TITAN LIVE ACCEPTANCE DOCKER SUMMARY'
  echo '===================================='
  echo 'PostgreSQL target: 18.6'
  echo 'Full operational acceptance: PASS'
  echo 'Two-clean-run deterministic replay: PASS'
  echo 'Optimistic concurrency: PASS'
  echo 'pgbench smoke: PASS'
  echo 'Logical restore: PASS'
  echo 'PITR: run separately with ./run_pitr_lab.sh (lab evidence, not production RPO/RTO certification)'
  echo
  echo 'Schema fingerprint:'
  cat "$ART/full_acceptance/schema.sha256"
  echo
  echo 'Load summary:'
  cat "$ART/load/summary.txt"
  echo
  echo 'Concurrency summary:'
  cat "$ART/concurrency/summary.txt"
  echo
  echo 'Restore summary:'
  cat "$ART/restore/summary.txt"
} | tee "$ART/ACCEPTANCE_SUMMARY.txt"

printf '%s\n' '=== CORE LIVE ACCEPTANCE PASS ==='
