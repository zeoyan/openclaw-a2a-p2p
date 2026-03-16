#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <peer-info.json> [peer-id] [peer-name]" >&2
  exit 1
fi

PEER_INFO_FILE="$1"
PEER_ID="${2:-}"
PEER_NAME="${3:-}"
OPENCLAW_CONFIG="${OPENCLAW_CONFIG:-$HOME/.openclaw/openclaw.json}"
PLUGIN_ID="${PLUGIN_ID:-a2a-p2p}"

node - <<'NODE' "$OPENCLAW_CONFIG" "$PLUGIN_ID" "$PEER_INFO_FILE" "$PEER_ID" "$PEER_NAME"
const fs = require('fs');
const [configPath, pluginId, peerInfoFile, peerIdOverride, peerNameOverride] = process.argv.slice(2);
const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
const peerInfo = JSON.parse(fs.readFileSync(peerInfoFile, 'utf8'));
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
const idx = cfg.peers.findIndex((p) => p && (p.id === peerId || p.name === peerName));
if (idx >= 0) cfg.peers[idx] = entry;
else cfg.peers.push(entry);
fs.writeFileSync(configPath, JSON.stringify(config, null, 2));
console.log(JSON.stringify(entry, null, 2));
NODE
