#!/usr/bin/env bash
# Test the NEW local Compose demo, not the historical VMware virtual machines.
set -Eeuo pipefail
cd "$(dirname "$0")/.."
compose_file="deploy/local/compose.yaml"
stopped=0

restore() {
  if [[ "$stopped" == 1 ]]; then
    echo "Restoring node1..."
    docker compose -f "$compose_file" start node1 >/dev/null || true
  fi
}
trap restore EXIT

for executable in docker curl awk; do
  command -v "$executable" >/dev/null 2>&1 || { echo "Missing: $executable" >&2; exit 1; }
done

backend() {
  curl --fail --silent --show-error --max-time 5 --dump-header - --output /dev/null \
    http://127.0.0.1:8080/ |
    awk 'tolower($1) == "x-backend-node:" {gsub(/\r/, "", $2); print $2}' |
    tail -n 1
}

echo "Waiting for HAProxy..."
ready=0
for ((i=0; i<40; i++)); do
  b="$(backend 2>/dev/null || true)"
  if [[ "$b" == node1 || "$b" == node2 ]]; then ready=1; break; fi
  sleep 1
done
[[ "$ready" == 1 ]] || { echo "HAProxy not ready" >&2; exit 1; }

echo "TEST 1: both Nginx backends must serve requests"
seen1=0
seen2=0
for ((i=1; i<=16; i++)); do
  b="$(backend)"
  case "$b" in
    node1) seen1=1 ;;
    node2) seen2=1 ;;
    *) echo "Unexpected X-Backend-Node: '$b'" >&2; exit 1 ;;
  esac
done
[[ "$seen1" == 1 && "$seen2" == 1 ]] || { echo "Only one backend observed" >&2; exit 1; }
echo "PASS: HAProxy routed traffic to both backends"

echo "TEST 2: stop node1, wait for health checks, check node2"
docker compose -f "$compose_file" stop node1
stopped=1
sleep 5
for ((i=1; i<=10; i++)); do
  b="$(backend)"
  [[ "$b" == node2 ]] || { echo "Expected node2, got '$b'" >&2; exit 1; }
done
echo "PASS: node2 handles all tested requests after detection of node1 failure"

echo "Restoring node1"
docker compose -f "$compose_file" start node1
stopped=0
rejoined=0
for ((i=0; i<30; i++)); do
  b="$(backend 2>/dev/null || true)"
  if [[ "$b" == node1 ]]; then rejoined=1; break; fi
  sleep 1
done
[[ "$rejoined" == 1 ]] || { echo "node1 did not rejoin" >&2; exit 1; }
echo "PASS: node1 rejoined HAProxy"
echo "ALL TESTS PASSED"
echo "This only tests backend failure, not failover of HAProxy or the physical host."
