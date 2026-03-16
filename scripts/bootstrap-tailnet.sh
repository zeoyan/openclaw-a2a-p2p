#!/usr/bin/env bash
set -euo pipefail

# Automate Tailscale + OpenClaw A2A plugin setup as far as possible.
#
# Required for fully unattended mode:
#   TS_AUTHKEY=tskey-...
#
# Optional env vars:
#   OPENCLAW_CONFIG=/home/ec2-user/.openclaw/openclaw.json
#   A2A_PLUGIN_ID=a2a-p2p
#   A2A_NAME="小爪"
#   A2A_DESCRIPTION="OpenClaw A2A peer"
#   A2A_SESSION_KEY="a2a-peer-inbox"
#   A2A_BEARER_TOKEN=<hex token>
#   A2A_BASE_PATH=/a2a
#   A2A_ALLOW_REMOTE=true
#   PEER_ID=self
#   PEER_NAME=self
#   PEER_AGENT_CARD_URL=http://PEER_HOST:18789/a2a/.well-known/agent-card.json
#   PEER_BEARER_TOKEN=<peer token>
#
# If TS_AUTHKEY is omitted, the script installs Tailscale and prints the login URL,
# but cannot finish tailnet enrollment unattended.

OPENCLAW_CONFIG="${OPENCLAW_CONFIG:-/home/ec2-user/.openclaw/openclaw.json}"
A2A_PLUGIN_ID="${A2A_PLUGIN_ID:-a2a-p2p}"
A2A_NAME="${A2A_NAME:-小爪}"
A2A_DESCRIPTION="${A2A_DESCRIPTION:-OpenClaw A2A peer}"
A2A_SESSION_KEY="${A2A_SESSION_KEY:-a2a-peer-inbox}"
A2A_BEARER_TOKEN="${A2A_BEARER_TOKEN:-$(openssl rand -hex 32)}"
A2A_BASE_PATH="${A2A_BASE_PATH:-/a2a}"
A2A_ALLOW_REMOTE="${A2A_ALLOW_REMOTE:-true}"
PEER_ID="${PEER_ID:-}"
PEER_NAME="${PEER_NAME:-}"
PEER_AGENT_CARD_URL="${PEER_AGENT_CARD_URL:-}"
PEER_BEARER_TOKEN="${PEER_BEARER_TOKEN:-}"
TS_AUTHKEY="${TS_AUTHKEY:-}"

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || { echo "missing required command: $1" >&2; exit 1; }
}

need_cmd node
need_cmd sudo
need_cmd curl
need_cmd openssl

install_tailscale() {
  if command -v tailscale >/dev/null 2>&1; then
    echo "tailscale already installed"
    return
  fi
  echo "Installing Tailscale..."
  curl -fsSL https://tailscale.com/install.sh | sh
}

ensure_tailscaled() {
  echo "Ensuring tailscaled service is running..."
  sudo systemctl enable --now tailscaled
  systemctl is-active tailscaled >/dev/null
}

enroll_tailscale() {
  if tailscale status >/dev/null 2>&1; then
    echo "tailscale already logged in"
    return
  fi

  if [[ -n "$TS_AUTHKEY" ]]; then
    echo "Enrolling in tailnet using TS_AUTHKEY..."
    sudo tailscale up --authkey="$TS_AUTHKEY" --accept-dns=true
  else
    echo "No TS_AUTHKEY provided. Starting interactive login flow..."
    set +e
    LOGIN_OUTPUT=$(sudo tailscale up 2>&1)
    STATUS=$?
    set -e
    echo "$LOGIN_OUTPUT"
    if [[ $STATUS -ne 0 ]]; then
      echo
      echo "Tailscale enrollment is waiting for a human login step."
      echo "For unattended use, rerun with TS_AUTHKEY=tskey-..."
      exit 2
    fi
  fi
}

resolve_tailnet_addr() {
  local ip fqdn
  ip="$(tailscale ip -4 2>/dev/null | head -n 1 || true)"
  fqdn="$(tailscale status --json 2>/dev/null | node -e 'let s="";process.stdin.on("data",d=>s+=d);process.stdin.on("end",()=>{try{const j=JSON.parse(s); console.log(j.Self?.DNSName || "");}catch{}})')"
  if [[ -n "$fqdn" ]]; then
    printf '%s\n' "$fqdn"
    return
  fi
  if [[ -n "$ip" ]]; then
    printf '%s\n' "$ip"
    return
  fi
  echo "failed to resolve tailnet address" >&2
  exit 1
}

update_openclaw_config() {
  local tail_addr="$1"
  local peer_json="null"

  if [[ -n "$PEER_ID" && -n "$PEER_NAME" && -n "$PEER_AGENT_CARD_URL" ]]; then
    local peer_token_json="null"
    if [[ -n "$PEER_BEARER_TOKEN" ]]; then
      peer_token_json=$(node -e 'console.log(JSON.stringify(process.argv[1]))' "$PEER_BEARER_TOKEN")
    fi
    peer_json=$(cat <<JSON
{
  "id": ${PEER_ID@Q},
  "name": ${PEER_NAME@Q},
  "agentCardUrl": ${PEER_AGENT_CARD_URL@Q},
  "auth": {
    "type": "bearer",
    "token": $peer_token_json
  },
  "labels": ["peer", "tailnet"]
}
JSON
)
  fi

  node - <<'NODE' "$OPENCLAW_CONFIG" "$A2A_PLUGIN_ID" "$A2A_NAME" "$A2A_DESCRIPTION" "$A2A_SESSION_KEY" "$A2A_BEARER_TOKEN" "$A2A_BASE_PATH" "$A2A_ALLOW_REMOTE" "$tail_addr" "$peer_json"
const fs = require('fs');
const [configPath, pluginId, name, description, sessionKey, bearerToken, basePath, allowRemoteRaw, tailAddr, peerJson] = process.argv.slice(2);
const allowRemote = allowRemoteRaw === 'true';
const j = JSON.parse(fs.readFileSync(configPath, 'utf8'));
j.plugins ||= {};
j.plugins.allow = Array.from(new Set([...(j.plugins.allow || []), pluginId]));
j.plugins.entries ||= {};
j.plugins.entries[pluginId] ||= { enabled: true };
const cfg = j.plugins.entries[pluginId].config ||= {};
cfg.server = { basePath, allowRemote };
cfg.agentCard = {
  name,
  description,
  url: `http://${tailAddr}${basePath}/jsonrpc`,
  provider: 'OpenClaw',
  streaming: true,
  pushNotifications: false,
  skills: [{ id: 'chat', name: 'chat', description: 'General-purpose text chat routed into OpenClaw' }]
};
cfg.routing = { sessionKey, mode: 'subagent', waitTimeoutMs: 15000 };
cfg.security = { inboundAuth: 'bearer', token: bearerToken, maxBodyBytes: 262144 };
let peers = [];
try {
  const parsedPeer = JSON.parse(peerJson);
  if (parsedPeer && parsedPeer.id) peers.push(parsedPeer);
} catch {}
cfg.peers = peers;
fs.writeFileSync(configPath, JSON.stringify(j, null, 2));
console.log(JSON.stringify({
  agentCardUrl: `http://${tailAddr}${basePath}/.well-known/agent-card.json`,
  jsonRpcUrl: `http://${tailAddr}${basePath}/jsonrpc`,
  bearerToken
}, null, 2));
NODE
}

restart_gateway() {
  echo "Restarting OpenClaw gateway..."
  openclaw gateway restart || true
}

main() {
  install_tailscale
  ensure_tailscaled
  enroll_tailscale
  local tail_addr
  tail_addr="$(resolve_tailnet_addr)"
  echo "Tailnet address: $tail_addr"
  update_openclaw_config "$tail_addr"
  restart_gateway
  echo
  echo "Bootstrap complete."
  echo "Use the printed agentCardUrl/jsonRpcUrl/bearerToken values on the remote peer."
}

main "$@"
