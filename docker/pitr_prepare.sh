#!/usr/bin/env bash
set -euo pipefail

ART=/workspace/artifacts/pitr
DB="${TITAN_ACCEPTANCE_DB:-titan_acceptance_full_docker}"
mkdir -p "$ART"

test -f /pitr/18/docker/PG_VERSION || { echo 'PITR PREP FAIL: physical base backup is missing' >&2; exit 60; }

run_id="$(date -u +%Y%m%dT%H%M%SZ)_$RANDOM"
pre="PRE_TARGET_${run_id}"
post="POST_TARGET_${run_id}"

psql -X -v ON_ERROR_STOP=1 -d "$DB" -c \
  "INSERT INTO titan_ops.recovery_probe(marker_text,probe_notes) VALUES ('$pre','Docker PITR pre-target marker');"

target_time="$(psql -X -qAt -v ON_ERROR_STOP=1 -d "$DB" -c "SELECT clock_timestamp();" | tail -1)"
sleep 1
psql -X -v ON_ERROR_STOP=1 -d "$DB" -c \
  "INSERT INTO titan_ops.recovery_probe(marker_text,probe_notes) VALUES ('$post','Docker PITR post-target marker');"

wal_to_archive="$(psql -X -qAt -v ON_ERROR_STOP=1 -d postgres -c "SELECT pg_walfile_name(pg_switch_wal());" | tail -1)"
for i in $(seq 1 90); do
  last="$(psql -X -qAt -v ON_ERROR_STOP=1 -d postgres -c "SELECT COALESCE(last_archived_wal,'') FROM pg_stat_archiver;" | tail -1)"
  if [[ "$last" == "$wal_to_archive" || "$last" > "$wal_to_archive" ]]; then
    break
  fi
  sleep 1
  if [[ "$i" -eq 90 ]]; then
    echo "PITR PREP FAIL: WAL $wal_to_archive was not observed archived; last=$last" >&2
    exit 61
  fi
done

cat >> /pitr/18/docker/postgresql.auto.conf <<EOF2
restore_command = 'cp /wal_archive/%f %p'
recovery_target_time = '$target_time'
recovery_target_action = 'promote'
EOF2
touch /pitr/18/docker/recovery.signal
chown -R postgres:postgres /pitr/18/docker
chmod 700 /pitr/18/docker

cat > "$ART/target.env" <<EOF2
PITR_RUN_ID=$run_id
PITR_PRE_MARKER=$pre
PITR_POST_MARKER=$post
PITR_TARGET_TIME=$target_time
PITR_ARCHIVED_WAL=$wal_to_archive
EOF2

cat "$ART/target.env"
echo 'PITR PREP PASS'
