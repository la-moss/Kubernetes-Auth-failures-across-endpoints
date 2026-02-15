#!/usr/bin/env bash
set -euo pipefail

NS=incident-lab
PROFILE="${VERIFY_PROFILE:-profile1}"
REQUESTS="${VERIFY_REQUESTS:-20}"
PROFILE1_MAX_AUTH_RESPONSES="${PROFILE1_MAX_AUTH_RESPONSES:-0}"
PROFILE2_MIN_SUCCESS_RATE="${PROFILE2_MIN_SUCCESS_RATE:-95}"
PROFILE3_MAX_AVG_LATENCY_MS="${PROFILE3_MAX_AVG_LATENCY_MS:-1300}"
PORT="${VERIFY_PORT:-18080}"

echo "[runtime] waiting for deployments..."
kubectl -n "$NS" rollout status deploy/sobrain --timeout=180s
kubectl -n "$NS" rollout status deploy/papi --timeout=180s

echo "[runtime] probing papi $REQUESTS times (profile=$PROFILE)..."
kubectl -n "$NS" port-forward svc/papi "$PORT":8080 >/tmp/pf.log 2>&1 &
PF_PID=$!
trap 'kill $PF_PID >/dev/null 2>&1 || true' EXIT
sleep 2

auth_fails=0
successes=0
server_errors=0
latency_sum_ms=0

for i in $(seq 1 "$REQUESTS"); do
  out=$(curl -s -o /dev/null -w "%{http_code} %{time_total}" "http://127.0.0.1:$PORT/" || echo "000 0")
  code=$(echo "$out" | awk '{print $1}')
  ttotal=$(echo "$out" | awk '{print $2}')
  latency_ms=$(awk -v t="$ttotal" 'BEGIN { printf("%.0f", t * 1000) }')
  latency_sum_ms=$((latency_sum_ms + latency_ms))

  if [[ "$code" =~ ^2 ]]; then
    successes=$((successes+1))
  fi
  if [[ "$code" == "401" || "$code" == "403" ]]; then
    auth_fails=$((auth_fails+1))
  fi
  if [[ "$code" =~ ^5 ]]; then
    server_errors=$((server_errors+1))
  fi
  sleep 0.1
done

success_rate=$((successes * 100 / REQUESTS))
avg_latency_ms=$((latency_sum_ms / REQUESTS))

echo "[runtime] summary: success_rate=${success_rate}% metric_a=$auth_fails metric_b=$server_errors metric_c=${avg_latency_ms}ms"

if [[ "$PROFILE" == "profile1" ]]; then
  if [[ "$auth_fails" -gt "$PROFILE1_MAX_AUTH_RESPONSES" ]]; then
    echo "runtime check failed: profile1 threshold exceeded"
    exit 1
  fi
elif [[ "$PROFILE" == "profile2" ]]; then
  if [[ "$success_rate" -lt "$PROFILE2_MIN_SUCCESS_RATE" || "$server_errors" -gt 0 ]]; then
    echo "runtime check failed: profile2 threshold exceeded"
    exit 1
  fi
elif [[ "$PROFILE" == "profile3" ]]; then
  if [[ "$avg_latency_ms" -gt "$PROFILE3_MAX_AVG_LATENCY_MS" ]]; then
    echo "runtime check failed: profile3 threshold exceeded"
    exit 1
  fi
else
  echo "runtime check failed: unknown VERIFY_PROFILE='$PROFILE'"
  exit 1
fi

echo "[runtime] OK"
