#!/usr/bin/env bash
set -euo pipefail

CONFIG_PATH="${1:-$HOME/.openclaw/openclaw.json}"

if [[ ! -f "$CONFIG_PATH" ]]; then
  echo "Config not found: $CONFIG_PATH"
  exit 1
fi

node - "$CONFIG_PATH" <<'NODE'
const fs = require('fs');
const path = process.argv[2];
const raw = fs.readFileSync(path, 'utf8');
const text = raw
  .replace(/([{,]\s*)([A-Za-z0-9_-]+)\s*:/g, '$1"$2":')
  .replace(/'([^'\\]*(?:\\.[^'\\]*)*)'/g, (_, s) => JSON.stringify(s));
let cfg;
try {
  cfg = JSON.parse(text);
} catch (err) {
  console.error(`Could not parse config: ${err.message}`);
  process.exit(2);
}

const plugin = cfg?.plugins?.entries?.['a2a-p2p']?.config || {};
const allowRemote = plugin?.server?.allowRemote;
const agentCardUrl = String(plugin?.agentCard?.url || '');
const gatewayBind = String(cfg?.gateway?.bind || '');
const routingSessionKey = String(plugin?.routing?.sessionKey || '');
const inboundToken = String(plugin?.security?.token || '');

const failures = [];
const warnings = [];

if (allowRemote !== true) failures.push('server.allowRemote is not true');
if (!agentCardUrl) failures.push('agentCard.url is missing');
if (/https?:\/\/(127\.0\.0\.1|localhost)([:/]|$)/i.test(agentCardUrl)) failures.push('agentCard.url uses 127.0.0.1 or localhost');
if (!/^https?:\/\//i.test(agentCardUrl)) warnings.push('agentCard.url is not an absolute http(s) URL');
if (!routingSessionKey) failures.push('routing.sessionKey is missing');
if (!inboundToken) failures.push('security.token is missing');
if (gatewayBind === 'loopback') failures.push('gateway.bind is loopback');
if (!gatewayBind) warnings.push('gateway.bind is empty or unspecified; confirm actual exposure path');

console.log('A2A P2P remote-mode preflight');
console.log(`- config: ${path}`);
console.log(`- allowRemote: ${String(allowRemote)}`);
console.log(`- agentCard.url: ${agentCardUrl || '(missing)'}`);
console.log(`- gateway.bind: ${gatewayBind || '(missing)'}`);
console.log(`- routing.sessionKey: ${routingSessionKey || '(missing)'}`);
console.log(`- security.token: ${inboundToken ? '(set)' : '(missing)'}`);
console.log('');

if (!failures.length) {
  console.log('PASS: no obvious local-only configuration blockers found.');
  console.log('Still verify from another machine before claiming remote readiness.');
} else {
  console.log('FAIL: remote-mode blockers found:');
  for (const item of failures) console.log(`- ${item}`);
}

if (warnings.length) {
  console.log('');
  console.log('Warnings:');
  for (const item of warnings) console.log(`- ${item}`);
}
NODE
