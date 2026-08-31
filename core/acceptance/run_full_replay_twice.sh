#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="${TITAN_FULL_REPLAY_DIR:-$ROOT/acceptance/full_replay}"
mkdir -p "$OUT"
export TITAN_ACCEPTANCE_ALLOW_DROP=YES

for n in 1 2; do
  export TITAN_ACCEPTANCE_DB="titan_acceptance_full_replay_${n}"
  export TITAN_ACCEPTANCE_LOG_DIR="$OUT/run_${n}"
  "$ROOT/acceptance/run_full_operational_acceptance.sh"
done

h1=$(cut -d' ' -f1 "$OUT/run_1/schema.sha256")
h2=$(cut -d' ' -f1 "$OUT/run_2/schema.sha256")
if [[ "$h1" != "$h2" ]]; then
  echo "FULL REPLAY FAIL: schema hashes differ: $h1 vs $h2" >&2
  exit 10
fi
echo "FULL REPLAY PASS: clean-run schema hashes match: $h1"
