#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
chmod +x run_acceptance.sh run_pitr_lab.sh run_codespaces_acceptance.sh 2>/dev/null || true
chmod +x core/acceptance/*.sh core/load/*.sh core/recovery/*.sh 2>/dev/null || true
mkdir -p artifacts
printf '\nTITAN Codespaces environment configured.\n'
printf 'Run: ./run_codespaces_acceptance.sh\n\n'
