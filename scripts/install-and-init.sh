#!/usr/bin/env bash
set -euo pipefail

PLUGIN_DIR="${1:-$(cd "$(dirname "$0")/.." && pwd)}"
OPENCLAW_CONFIG="${OPENCLAW_CONFIG:-$HOME/.openclaw/openclaw.json}"
A2A_NAME="${A2A_NAME:-$(hostname)}"
PUBLIC_BASE_URL="${PUBLIC_BASE_URL:-}"
A2A_BASE_PATH="${A2A_BASE_PATH:-/a2a}"
A2A_ROUTING_SESSION_KEY="${A2A_ROUTING_SESSION_KEY:-a2a-peer-$(hostname | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' '-' | sed 's/-*$//')}"
A2A_WAIT_TIMEOUT_MS="${A2A_WAIT_TIMEOUT_MS:-15000}"
A2A_MAX_BODY_BYTES="${A2A_MAX_BODY_BYTES:-262144}"
OUTPUT_DIR="${OUTPUT_DIR:-$HOME/.openclaw/state/a2a-p2p}"
PEER_INFO_FILE="$OUTPUT_DIR/peer-info.json"

mkdir -p "$OUTPUT_DIR"

if ! command -v openclaw >/dev/null 2>&1; then
  echo "openclaw CLI not found" >&2
  exit 1
fi

if ! command -v node >/dev/null 2>&1; then
  echo "node not found" >&2
  exit 1
fi

install_plugin() {
  local out rc
  set +e
  out="$(openclaw plugins install "$PLUGIN_DIR" 2>&1)"
  rc=$?
  set -e
  if [[ $rc -eq 0 ]]; then
    printf '%s\n' "$out"
    return 0
  fi
  if grep -q "plugin already exists" <<<"$out"; then
    printf '%s\n' "$out"
    echo "==> Plugin already installed; continuing"
    return 0
  fi
  printf '%s\n' "$out" >&2
  return $rc
}

A2A_TOKEN="${A2A_TOKEN:-$(node -e 'console.log(require("crypto").randomBytes(24).toString("hex"))')}"

echo "==> Installing plugin from: $PLUGIN_DIR"
install_plugin

node - <<'NODE' "$OPENCLAW_CONFIG" "$A2A_NAME" "$PUBLIC_BASE_URL" "$A2A_BASE_PATH" "$A2A_ROUTING_SESSION_KEY" "$A2A_WAIT_TIMEOUT_MS" "$A2A_TOKEN" "$A2A_MAX_BODY_BYTES"
const fs = require('fs');
const cp = require('child_process');
const [configPath, name, publicBaseUrl, basePathRaw, routingSessionKey, waitTimeoutMsRaw, token, maxBodyBytesRaw] = process.argv.slice(2);
const basePath = `/${String(basePathRaw || '/a2a').replace(/^\/+/, '').replace(/\/+$/, '') || 'a2a'}`;
const waitTimeoutMs = Number(waitTimeoutMsRaw || 15000);
const maxBodyBytes = Number(maxBodyBytesRaw || 262144);
const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
config.gateway ||= {};
if (!config.gateway.bind || config.gateway.bind === 'loopback') config.gateway.bind = 'lan';
const port = Number(config.gateway.port || 18789);
function discoverPublicIp() {
  const cmds = [
    'curl -fsS https://checkip.amazonaws.com 2>/dev/null',
    'curl -fsS https://ifconfig.me 2>/dev/null'
  ];
  for (const cmd of cmds) {
    try {
      const out = cp.execSync(cmd, { encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'] }).trim();
      if (out) return out;
    } catch {}
  }
  return null;
}
const host = publicBaseUrl ? String(publicBaseUrl).replace(/\/$/, '') : `http://${discoverPublicIp() || '127.0.0.1'}:${port}`;
config.plugins ||= {};
config.plugins.allow = Array.isArray(config.plugins.allow) ? Array.from(new Set([...config.plugins.allow, 'a2a-p2p'])) : ['a2a-p2p'];
config.plugins.entries ||= {};
config.plugins.entries['a2a-p2p'] ||= { enabled: true, config: {} };
const plugin = config.plugins.entries['a2a-p2p'];
plugin.enabled = true;
plugin.config ||= {};
plugin.config.server = { ...(plugin.config.server || {}), basePath, allowRemote: true };
plugin.config.agentCard = {
  ...(plugin.config.agentCard || {}),
  name,
  description: plugin.config.agentCard?.description || 'OpenClaw A2A peer',
  provider: plugin.config.agentCard?.provider || 'OpenClaw',
  streaming: plugin.config.agentCard?.streaming !== false,
  pushNotifications: Boolean(plugin.config.agentCard?.pushNotifications),
  skills: Array.isArray(plugin.config.agentCard?.skills) && plugin.config.agentCard.skills.length ? plugin.config.agentCard.skills : [{ id: 'chat', name: 'chat', description: 'General-purpose text chat routed into OpenClaw' }],
  url: `${host}${basePath}/jsonrpc`
};
plugin.config.routing = { ...(plugin.config.routing || {}), sessionKey: routingSessionKey, mode: plugin.config.routing?.mode === 'system-event' ? 'system-event' : 'subagent', waitTimeoutMs };
plugin.config.security = { ...(plugin.config.security || {}), inboundAuth: 'bearer', token, maxBodyBytes };
plugin.config.peers = Array.isArray(plugin.config.peers) ? plugin.config.peers : [];
fs.writeFileSync(configPath, JSON.stringify(config, null, 2));
NODE

chmod +x "$PLUGIN_DIR/scripts/export-peer-info.sh" || true
"$PLUGIN_DIR/scripts/export-peer-info.sh" > "$PEER_INFO_FILE"

echo
echo "==> Your peer info"
cat "$PEER_INFO_FILE"

echo
echo "Peer info was written before restart, so it is available even if the current session is interrupted."
echo "Saved at: $PEER_INFO_FILE"

echo
echo "==> Restarting gateway"
openclaw gateway restart || true
