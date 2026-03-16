#!/usr/bin/env bash
set -euo pipefail

OPENCLAW_CONFIG="${OPENCLAW_CONFIG:-$HOME/.openclaw/openclaw.json}"
PLUGIN_ID="${PLUGIN_ID:-a2a-p2p}"
PUBLIC_BASE_URL="${PUBLIC_BASE_URL:-}"
PREFER_PUBLIC="${PREFER_PUBLIC:-true}"

node - <<'NODE' "$OPENCLAW_CONFIG" "$PLUGIN_ID" "$PUBLIC_BASE_URL" "$PREFER_PUBLIC"
const fs = require('fs');
const cp = require('child_process');
const [configPath, pluginId, publicBaseUrl, preferPublicRaw] = process.argv.slice(2);
const preferPublic = preferPublicRaw !== 'false';
const j = JSON.parse(fs.readFileSync(configPath, 'utf8'));
const cfg = j.plugins?.entries?.[pluginId]?.config;
if (!cfg) throw new Error(`missing plugin config for ${pluginId}`);

function discoverPublicIp() {
  const cmds = [
    "curl -fsS https://checkip.amazonaws.com 2>/dev/null",
    "curl -fsS https://ifconfig.me 2>/dev/null"
  ];
  for (const cmd of cmds) {
    try {
      const out = cp.execSync(cmd, { encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'] }).trim();
      if (out) return out;
    } catch {}
  }
  return null;
}

const configuredJsonRpcUrl = cfg.agentCard?.url || null;
const basePath = cfg.server?.basePath || '/a2a';
let agentCardUrl = configuredJsonRpcUrl ? String(configuredJsonRpcUrl).replace(/\/jsonrpc$/, '/.well-known/agent-card.json') : null;

if (publicBaseUrl) {
  const base = publicBaseUrl.replace(/\/$/, '');
  agentCardUrl = `${base}${basePath}/.well-known/agent-card.json`;
} else if (preferPublic && typeof configuredJsonRpcUrl === 'string' && configuredJsonRpcUrl.includes('127.0.0.1')) {
  const discoveredIp = discoverPublicIp();
  if (discoveredIp) {
    const publicJsonRpcUrl = configuredJsonRpcUrl.replace('127.0.0.1', discoveredIp);
    agentCardUrl = String(publicJsonRpcUrl).replace(/\/jsonrpc$/, '/.well-known/agent-card.json');
  }
}

const out = {
  kind: 'openclaw-a2a-peer-info',
  version: 1,
  name: cfg.agentCard?.name || 'OpenClaw A2A peer',
  agentCardUrl,
  bearerToken: cfg.security?.token || null
};
console.log(JSON.stringify(out, null, 2));
NODE
