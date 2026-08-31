#!/usr/bin/env bash
set -euo pipefail
CORE=/workspace/core
ART=/workspace/artifacts/pitr
DB="${TITAN_ACCEPTANCE_DB:-titan_acceptance_full_docker}"
source "$ART/target.env"

# pg_isready may succeed during hot-standby recovery; wait for recovery_target_action=promote.
for i in $(seq 1 120); do
  state="$(psql -X -qAt -v ON_ERROR_STOP=1 -d postgres -c 'SELECT pg_is_in_recovery();' | tail -1)"
  [[ "$state" == "f" ]] && break
  sleep 1
  [[ "$i" -lt 120 ]] || { echo 'PITR VERIFY FAIL: restored server did not promote at target' >&2; exit 70; }
done

pre_count="$(psql -X -qAt -v ON_ERROR_STOP=1 -d "$DB" -c "SELECT count(*) FROM titan_ops.recovery_probe WHERE marker_text='$PITR_PRE_MARKER';")"
post_count="$(psql -X -qAt -v ON_ERROR_STOP=1 -d "$DB" -c "SELECT count(*) FROM titan_ops.recovery_probe WHERE marker_text='$PITR_POST_MARKER';")"

[[ "$pre_count" == "1" ]] || { echo "PITR VERIFY FAIL: pre-target marker count=$pre_count" >&2; exit 71; }
[[ "$post_count" == "0" ]] || { echo "PITR VERIFY FAIL: post-target marker survived recovery count=$post_count" >&2; exit 72; }

psql -X -v ON_ERROR_STOP=1 -d "$DB" -f "$CORE/acceptance/A002__post_migration_gate.sql" > "$ART/restored_base_gate.txt"
psql -X -v ON_ERROR_STOP=1 -d "$DB" -f "$CORE/acceptance/pg10/A011__post_security_gate.sql" > "$ART/restored_security_gate.txt"

{
  echo 'PITR LAB PASS'
  echo "target_time=$PITR_TARGET_TIME"
  echo "pre_target_marker=$PITR_PRE_MARKER present=1"
  echo "post_target_marker=$PITR_POST_MARKER present=0"
  echo 'base_structural_gate=PASS'
  echo 'security_rls_gate=PASS'
  echo 'classification=DISPOSABLE_LAB_EVIDENCE_NOT_PRODUCTION_RPO_RTO_CERTIFICATION'
} | tee "$ART/PITR_SUMMARY.txt"
