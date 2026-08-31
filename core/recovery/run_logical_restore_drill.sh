#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_DB="${TITAN_ACCEPTANCE_DB:-titan_acceptance_full_20260830}"
RESTORE_DB="${TITAN_RESTORE_DB:-titan_acceptance_restore_20260830}"
OUT="${TITAN_RESTORE_LOG_DIR:-$ROOT/recovery/logs}"
mkdir -p "$OUT"

if [[ "$SOURCE_DB" != titan_acceptance_* || "$RESTORE_DB" != titan_acceptance_restore_* ]]; then
  echo "Restore drill is restricted to disposable titan_acceptance_* databases." >&2
  exit 2
fi
for cmd in psql pg_dump pg_dumpall pg_restore createdb dropdb; do
  command -v "$cmd" >/dev/null || { echo "Missing required command: $cmd" >&2; exit 3; }
done

start=$(date +%s)
pg_dump -Fc --no-owner --no-acl -d "$SOURCE_DB" -f "$OUT/database.dump"
pg_dumpall --globals-only > "$OUT/globals.sql"
pg_restore --list "$OUT/database.dump" > "$OUT/archive.list"

dropdb --if-exists --force "$RESTORE_DB"
createdb "$RESTORE_DB"
pg_restore --exit-on-error --no-owner --no-acl -d "$RESTORE_DB" "$OUT/database.dump"

psql -X -v ON_ERROR_STOP=1 -d "$RESTORE_DB" -f "$ROOT/acceptance/A002__post_migration_gate.sql" > "$OUT/restored_base_gate.txt"
psql -X -v ON_ERROR_STOP=1 -d "$RESTORE_DB" -f "$ROOT/acceptance/pg10/A011__post_security_gate.sql" > "$OUT/restored_security_gate.txt"

psql -X -qAt -v ON_ERROR_STOP=1 -d "$SOURCE_DB" -f "$ROOT/acceptance/pg10/A013__table_inventory.sql" > "$OUT/source_inventory.txt"
psql -X -qAt -v ON_ERROR_STOP=1 -d "$RESTORE_DB" -f "$ROOT/acceptance/pg10/A013__table_inventory.sql" > "$OUT/restored_inventory.txt"
diff -u "$OUT/source_inventory.txt" "$OUT/restored_inventory.txt" > "$OUT/inventory.diff" || {
  echo "RESTORE FAIL: table inventories differ" >&2
  cat "$OUT/inventory.diff" >&2
  exit 40
}

pg_dump --schema-only --no-owner --no-privileges --restrict-key=TITANRESTOREV1 "$SOURCE_DB" > "$OUT/source_schema.sql"
pg_dump --schema-only --no-owner --no-privileges --restrict-key=TITANRESTOREV1 "$RESTORE_DB" > "$OUT/restored_schema.sql"
h1=$(sha256sum "$OUT/source_schema.sql" | cut -d' ' -f1)
h2=$(sha256sum "$OUT/restored_schema.sql" | cut -d' ' -f1)
if [[ "$h1" != "$h2" ]]; then
  echo "RESTORE FAIL: schema hashes differ: $h1 vs $h2" >&2
  exit 41
fi

stop=$(date +%s)
elapsed=$((stop-start))
{
  echo "source_db=$SOURCE_DB"
  echo "restore_db=$RESTORE_DB"
  echo "schema_hash=$h1"
  echo "inventory_match=PASS"
  echo "elapsed_seconds=$elapsed"
  echo "rto_slo=NOT_DEFINED_UNTIL_DEPLOYMENT"
  echo "globals_capture=$OUT/globals.sql"
} | tee "$OUT/summary.txt"

echo "LOGICAL RESTORE PASS: schema and all TITAN table row-count inventories match."
echo "Production recovery still requires WAL/PITR drill and isolated-cluster globals restore."
