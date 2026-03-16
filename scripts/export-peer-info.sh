#!/usr/bin/env bash
set -euo pipefail

OPENCLAW_CONFIG="${OPENCLAW_CONFIG:-/home/ec2-user/.openclaw/openclaw.json}"
PLUGIN_ID="${PLUGIN_ID:-a2a-p2p}"

node - <<'NODE' "$OPENCLAW_CONFIG" "$PLUGIN_ID"
const fs = require('fs');
const [configPath, pluginId] = process.argv.slice(2);
const j = JSON.parse(fs.readFileSync(configPath, 'utf8'));
const cfg = j.plugins?.entries?.[pluginId]?.config;
if (!cfg) throw new Error(`missing plugin config for ${pluginId}`);
const out = {
  kind: 'openclaw-a2a-peer-info',
  version: 1,
  pluginId,
  name: cfg.agentCard?.name || 'OpenClaw A2A peer',
  description: cfg.agentCard?.description || 'OpenClaw A2A peer',
  agentCardUrl: String(cfg.agentCard?.url || '').replace(/\/jsonrpc$/, '/.well-known/agent-card.json'),
  jsonRpcUrl: cfg.agentCard?.url || null,
  bearerToken: cfg.security?.token || null,
  routingMode: cfg.routing?.mode || 'subagent',
  sessionKey: cfg.routing?.sessionKey || null
};
console.log(JSON.stringify(out, null, 2));
NODE
