#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DB="${TITAN_ACCEPTANCE_DB:-titan_acceptance_full_20260830}"
LOG_DIR="${TITAN_ACCEPTANCE_LOG_DIR:-$ROOT/acceptance/full_logs}"
mkdir -p "$LOG_DIR"

if [[ "$DB" != titan_acceptance_* ]]; then
  echo "Refusing destructive full acceptance against DB not named titan_acceptance_*: $DB" >&2
  exit 2
fi
if [[ "${TITAN_ACCEPTANCE_ALLOW_DROP:-NO}" != "YES" ]]; then
  echo "Set TITAN_ACCEPTANCE_ALLOW_DROP=YES to recreate disposable acceptance DB $DB" >&2
  exit 2
fi
for cmd in psql createdb dropdb pg_dump; do
  command -v "$cmd" >/dev/null || { echo "Missing required command: $cmd" >&2; exit 3; }
done

run_psql() { psql -X -v ON_ERROR_STOP=1 -d "$DB" "$@"; }

echo "[1/9] Recreate $DB"
dropdb --if-exists --force "$DB"
createdb "$DB"

echo "[2/9] Base + security preflight"
run_psql -f "$ROOT/acceptance/A001__preflight.sql" | tee "$LOG_DIR/01_base_preflight.log"
run_psql -f "$ROOT/acceptance/pg10/A010__security_preflight.sql" | tee "$LOG_DIR/02_security_preflight.log"

echo "[3/9] Execute V001-V020"
for n in $(seq -f "%03g" 1 20); do
  f=$(find "$ROOT/sql" -maxdepth 1 -type f -name "V${n}__*.sql" -print -quit)
  [[ -n "$f" ]] || { echo "Missing V${n} migration" >&2; exit 4; }
  echo "== $(basename "$f") ==" | tee -a "$LOG_DIR/03_migrations.log"
  run_psql -f "$f" >> "$LOG_DIR/03_migrations.log" 2>&1
done

echo "[4/9] Post-migration gates"
run_psql -f "$ROOT/acceptance/A002__post_migration_gate.sql" | tee "$LOG_DIR/04_base_post_migration.log"
run_psql -f "$ROOT/acceptance/pg10/A011__post_security_gate.sql" | tee "$LOG_DIR/05_security_post_migration.log"

echo "[5/9] Execute T001-T011"
for n in $(seq -f "%03g" 1 11); do
  f=$(find "$ROOT/sql" -maxdepth 1 -type f -name "T${n}__*.sql" -print -quit)
  [[ -n "$f" ]] || { echo "Missing T${n} test suite" >&2; exit 5; }
  echo "== $(basename "$f") ==" | tee -a "$LOG_DIR/06_tests.log"
  run_psql -f "$f" >> "$LOG_DIR/06_tests.log" 2>&1
done

echo "[6/9] Post-test residue gates"
run_psql -f "$ROOT/acceptance/A003__post_test_integrity.sql" | tee "$LOG_DIR/07_base_post_test.log"
run_psql -f "$ROOT/acceptance/pg10/A012__post_operational_test_gate.sql" | tee "$LOG_DIR/08_ops_post_test.log"

echo "[7/9] Deterministic acceptance schema fingerprint"
pg_dump --schema-only --no-owner --no-privileges --restrict-key=TITANFULLV1 "$DB" > "$LOG_DIR/schema.sql"
sha256sum "$LOG_DIR/schema.sql" | tee "$LOG_DIR/schema.sha256"

echo "[8/9] Inventory and role posture"
run_psql -f "$ROOT/acceptance/pg10/A013__table_inventory.sql" | tee "$LOG_DIR/table_inventory.txt"
run_psql -c "SELECT * FROM titan_ops.v_database_health;" | tee "$LOG_DIR/database_health.txt"
run_psql -c "SELECT * FROM titan_ops.v_role_security_posture;" | tee "$LOG_DIR/role_posture.txt"

echo "[9/9] FULL OPERATIONAL ACCEPTANCE PASS"
