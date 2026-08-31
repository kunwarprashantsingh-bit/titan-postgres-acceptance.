#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DB="${TITAN_ACCEPTANCE_DB:-titan_acceptance_full_20260830}"
CLIENTS="${TITAN_LOAD_CLIENTS:-10}"
THREADS="${TITAN_LOAD_THREADS:-2}"
SECONDS="${TITAN_LOAD_SECONDS:-30}"
OUT="${TITAN_LOAD_LOG_DIR:-$ROOT/load/logs}"
mkdir -p "$OUT"

if [[ "$DB" != titan_acceptance_* ]]; then
  echo "Load acceptance is restricted to titan_acceptance_* databases: $DB" >&2
  exit 2
fi
for cmd in psql pgbench; do
  command -v "$cmd" >/dev/null || { echo "Missing required command: $cmd" >&2; exit 3; }
done

psql -X -v ON_ERROR_STOP=1 -d "$DB" -c "TRUNCATE titan_ops.operational_load_probe RESTART IDENTITY;"
dead_before=$(psql -X -qAt -d "$DB" -c "SELECT deadlocks FROM pg_stat_database WHERE datname=current_database();")

set +e
pgbench -n -c "$CLIENTS" -j "$THREADS" -T "$SECONDS" \
  -f "$ROOT/load/pgbench_insert_probe.sql" "$DB" 2>&1 | tee "$OUT/pgbench.txt"
rc=${PIPESTATUS[0]}
set -e
if [[ "$rc" -ne 0 ]]; then
  echo "LOAD FAIL: pgbench exited $rc" >&2
  exit "$rc"
fi

failed=$(awk '/number of failed transactions:/ {print $5}' "$OUT/pgbench.txt" | tail -1)
failed="${failed:-UNKNOWN}"
if [[ "$failed" != "0" ]]; then
  echo "LOAD FAIL: failed transactions=$failed" >&2
  exit 20
fi

dead_after=$(psql -X -qAt -d "$DB" -c "SELECT deadlocks FROM pg_stat_database WHERE datname=current_database();")
dead_delta=$((dead_after-dead_before))
rows=$(psql -X -qAt -d "$DB" -c "SELECT count(*) FROM titan_ops.operational_load_probe;")

{
  echo "clients=$CLIENTS"
  echo "threads=$THREADS"
  echo "seconds=$SECONDS"
  echo "failed_transactions=$failed"
  echo "deadlocks_before=$dead_before"
  echo "deadlocks_after=$dead_after"
  echo "deadlocks_delta=$dead_delta"
  echo "inserted_rows=$rows"
  echo "latency_and_tps=OBSERVATIONAL_ONLY_UNTIL_DEPLOYMENT_SLO_DEFINED"
} | tee "$OUT/summary.txt"

if [[ "$dead_delta" -ne 0 ]]; then
  echo "LOAD FAIL: deadlock delta=$dead_delta" >&2
  exit 21
fi
if [[ "$rows" -le 0 ]]; then
  echo "LOAD FAIL: no rows inserted" >&2
  exit 22
fi

psql -X -v ON_ERROR_STOP=1 -d "$DB" -c "TRUNCATE titan_ops.operational_load_probe RESTART IDENTITY;"
echo "LOAD PASS: zero failed transactions, zero new deadlocks. TPS/latency recorded, not SLA-gated."
