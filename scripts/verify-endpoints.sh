#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${1:-http://127.0.0.1:18789}"
TOKEN="${2:-}"

if [[ -z "$TOKEN" ]]; then
  echo "Usage: $0 <base-url> <bearer-token>"
  echo "Example (local self-test): $0 http://127.0.0.1:18789 local-secret-token"
  echo "Example (remote verification): $0 https://agent.example.com remote-secret-token"
  exit 1
fi

if [[ "$BASE_URL" =~ ^https?://(127\.0\.0\.1|localhost)(:|/|$) ]]; then
  echo "NOTE: verifying a loopback URL. This only proves local/self-test reachability, not cross-machine readiness."
  echo
fi

echo "[1/3] Agent Card"
curl -fsS "$BASE_URL/a2a/.well-known/agent-card.json" | sed -n '1,120p'

echo
echo "[2/3] JSON-RPC agent/getCard"
curl -fsS -X POST "$BASE_URL/a2a/jsonrpc" \
  -H 'content-type: application/json' \
  -H "authorization: Bearer $TOKEN" \
  --data '{"jsonrpc":"2.0","id":"verify-card","method":"agent/getCard","params":{}}' | sed -n '1,160p'

echo
echo "[3/3] JSON-RPC message/send"
curl -fsS -X POST "$BASE_URL/a2a/jsonrpc" \
  -H 'content-type: application/json' \
  -H "authorization: Bearer $TOKEN" \
  --data '{"jsonrpc":"2.0","id":"verify-message","method":"message/send","params":{"message":{"role":"user","parts":[{"type":"text","text":"Reply with exactly: LOOPBACK_OK"}]}}}' | sed -n '1,200p'

echo
if [[ "$BASE_URL" =~ ^https?://(127\.0\.0\.1|localhost)(:|/|$) ]]; then
  echo "Done. If the final response contains LOOPBACK_OK, the basic local loopback path works."
else
  echo "Done. If the final response contains LOOPBACK_OK, the basic remote request path works from the machine that ran this script."
fi
