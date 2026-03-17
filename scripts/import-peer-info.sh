#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 && -t 0 ]]; then
  echo "Usage: $0 <peer-info.json|raw-json|-> [peer-id] [peer-name]" >&2
  echo "  - use '-' to read JSON from stdin" >&2
  exit 1
fi

PEER_INFO_SOURCE="${1:--}"
PEER_ID="${2:-}"
PEER_NAME="${3:-}"
OPENCLAW_CONFIG="${OPENCLAW_CONFIG:-$HOME/.openclaw/openclaw.json}"
PLUGIN_ID="${PLUGIN_ID:-a2a-p2p}"
STDIN_JSON=""

if [[ "$PEER_INFO_SOURCE" == "-" ]]; then
  STDIN_JSON="$(cat)"
fi

node - <<'NODE' "$OPENCLAW_CONFIG" "$PLUGIN_ID" "$PEER_INFO_SOURCE" "$PEER_ID" "$PEER_NAME" "$STDIN_JSON"
const fs = require('fs');
const [configPath, pluginId, peerInfoSource, peerIdOverride, peerNameOverride, stdinJson] = process.argv.slice(2);
const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
function readPeerInfo(source, stdinRaw) {
  if (!source || source === '-') {
    if (!stdinRaw || !stdinRaw.trim()) throw new Error('stdin peer info is empty');
    return JSON.parse(stdinRaw);
  }
  if (fs.existsSync(source)) {
    return JSON.parse(fs.readFileSync(source, 'utf8'));
  }
  return JSON.parse(source);
}
const peerInfo = readPeerInfo(peerInfoSource, stdinJson);
config.plugins ||= {};
config.plugins.entries ||= {};
config.plugins.entries[pluginId] ||= { enabled: true, config: {} };
const cfg = config.plugins.entries[pluginId].config ||= {};
cfg.peers ||= [];
const peerId = peerIdOverride || String(peerInfo.name || 'peer').toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-+|-+$/g, '') || 'peer';
const peerName = peerNameOverride || peerInfo.name || 'Remote Peer';
const entry = {
  id: peerId,
  name: peerName,
  agentCardUrl: peerInfo.agentCardUrl,
  auth: {
    type: 'bearer',
    token: peerInfo.bearerToken || null
  },
  labels: ['peer', 'imported']
};
const idx = cfg.peers.findIndex((p) => p && (p.id === peerId || p.name === peerName || p.agentCardUrl === peerInfo.agentCardUrl));
if (idx >= 0) cfg.peers[idx] = entry;
else cfg.peers.push(entry);
fs.writeFileSync(configPath, JSON.stringify(config, null, 2));
console.log(JSON.stringify(entry, null, 2));
NODE
