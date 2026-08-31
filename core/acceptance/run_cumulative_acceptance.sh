#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DB="${TITAN_ACCEPTANCE_DB:-titan_acceptance_20260830}"
ADMIN_DB="${PGADMIN_DB:-postgres}"
LOG_DIR="${TITAN_ACCEPTANCE_LOG_DIR:-$ROOT/acceptance/logs}"
mkdir -p "$LOG_DIR"

if [[ "$DB" != titan_acceptance_* ]]; then
  echo "Refusing destructive clean-run against DB not named titan_acceptance_*: $DB" >&2
  exit 2
fi
if [[ "${TITAN_ACCEPTANCE_ALLOW_DROP:-NO}" != "YES" ]]; then
  echo "Set TITAN_ACCEPTANCE_ALLOW_DROP=YES to authorize recreation of disposable acceptance DB $DB" >&2
  exit 2
fi
for cmd in psql createdb dropdb pg_dump; do
  command -v "$cmd" >/dev/null || { echo "Missing required command: $cmd" >&2; exit 3; }
done

run_psql() { psql -X -v ON_ERROR_STOP=1 -d "$DB" "$@"; }

echo "[1/7] Recreate disposable acceptance database: $DB"
dropdb --if-exists --force "$DB"
createdb "$DB"

echo "[2/7] Preflight"
run_psql -f "$ROOT/acceptance/A001__preflight.sql" | tee "$LOG_DIR/01_preflight.log"

echo "[3/7] Execute V001-V018"
for n in $(seq -f "%03g" 1 18); do
  f=$(find "$ROOT/sql" -maxdepth 1 -type f -name "V${n}__*.sql" -print -quit)
  [[ -n "$f" ]] || { echo "Missing V${n} migration" >&2; exit 4; }
  echo "== $(basename "$f") ==" | tee -a "$LOG_DIR/02_migrations.log"
  run_psql -f "$f" >> "$LOG_DIR/02_migrations.log" 2>&1
done
run_psql -f "$ROOT/acceptance/A002__post_migration_gate.sql" | tee "$LOG_DIR/03_post_migration_gate.log"

echo "[4/7] Execute T001-T009"
for n in $(seq -f "%03g" 1 9); do
  f=$(find "$ROOT/sql" -maxdepth 1 -type f -name "T${n}__*.sql" -print -quit)
  [[ -n "$f" ]] || { echo "Missing T${n} test suite" >&2; exit 5; }
  echo "== $(basename "$f") ==" | tee -a "$LOG_DIR/04_tests.log"
  run_psql -f "$f" >> "$LOG_DIR/04_tests.log" 2>&1
done
run_psql -f "$ROOT/acceptance/A003__post_test_integrity.sql" | tee "$LOG_DIR/05_post_test_gate.log"

echo "[5/7] Capture schema-only canonical dump"
pg_dump --schema-only --no-owner --no-privileges --restrict-key=TITANREPLAYV1 "$DB" > "$LOG_DIR/schema.sql"
sha256sum "$LOG_DIR/schema.sql" | tee "$LOG_DIR/schema.sha256"

echo "[6/7] Capture inventory"
run_psql -Atc "SELECT current_setting('server_version'),count(*) FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname IN ('titan_ref','titan_core','titan_migration') AND c.relkind='r';" | tee "$LOG_DIR/inventory.txt"

echo "[7/7] ACCEPTANCE PASS — all migrations/tests/gates completed"
