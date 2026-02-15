#!/usr/bin/env bash
set -euo pipefail

echo "[1/1] Runtime checks"
bash scripts/verify/runtime_checks.sh

echo "verify passed (${VERIFY_PROFILE:-profile1})"
