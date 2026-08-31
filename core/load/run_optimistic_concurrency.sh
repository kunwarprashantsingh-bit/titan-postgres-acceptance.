#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DB="${TITAN_ACCEPTANCE_DB:-titan_acceptance_concurrency_20260830}"
OUT="${TITAN_CONCURRENCY_LOG_DIR:-$ROOT/load/concurrency_logs}"
mkdir -p "$OUT"

if [[ "$DB" != titan_acceptance_* ]]; then
  echo "Concurrency acceptance is restricted to titan_acceptance_* databases: $DB" >&2
  exit 2
fi
command -v psql >/dev/null || { echo "Missing psql" >&2; exit 3; }

wid=$(psql -X -qAt -v ON_ERROR_STOP=1 -d "$DB" -c \
  "SET ROLE titan_researcher; INSERT INTO titan_ops.work_item(work_item_type,subject_object_type,subject_object_id,workflow_state,transition_note) VALUES ('CONCURRENCY_TEST','TEST','PG10-CONCURRENCY','RAW','two-writer fixture') RETURNING work_item_id;")
ver=$(psql -X -qAt -d "$DB" -c "SELECT row_version FROM titan_ops.work_item WHERE work_item_id='$wid';")

writer() {
  local name="$1"
  psql -X -qAt -v ON_ERROR_STOP=1 -d "$DB" -c \
    "SET ROLE titan_researcher; SELECT titan_ops.try_transition_work_item('$wid',$ver,'STAGED','$name');" \
    | tail -1 > "$OUT/${name}.result"
}

writer writer_A &
p1=$!
writer writer_B &
p2=$!
wait "$p1"
wait "$p2"

r1=$(cat "$OUT/writer_A.result")
r2=$(cat "$OUT/writer_B.result")
wins=0
[[ "$r1" == "t" ]] && wins=$((wins+1))
[[ "$r2" == "t" ]] && wins=$((wins+1))

state=$(psql -X -qAt -d "$DB" -c "SELECT workflow_state||'|'||row_version FROM titan_ops.work_item WHERE work_item_id='$wid';")
events=$(psql -X -qAt -d "$DB" -c "SELECT count(*) FROM titan_ops.workflow_event WHERE work_item_id='$wid';")

{
  echo "work_item_id=$wid"
  echo "starting_row_version=$ver"
  echo "writer_A=$r1"
  echo "writer_B=$r2"
  echo "wins=$wins"
  echo "final_state_version=$state"
  echo "audit_events=$events"
} | tee "$OUT/summary.txt"

if [[ "$wins" -ne 1 ]]; then
  echo "CONCURRENCY FAIL: expected exactly one optimistic-lock winner" >&2
  exit 30
fi
if [[ "$state" != "STAGED|2" ]]; then
  echo "CONCURRENCY FAIL: expected STAGED|2, got $state" >&2
  exit 31
fi
if [[ "$events" -ne 2 ]]; then
  echo "CONCURRENCY FAIL: expected insert + one transition audit event" >&2
  exit 32
fi

echo "CONCURRENCY PASS: exactly one stale-base writer won; no last-write-wins."
echo "NOTE: fixture remains in this disposable acceptance database as evidence."
