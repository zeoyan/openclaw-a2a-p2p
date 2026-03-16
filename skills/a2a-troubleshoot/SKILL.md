---
name: a2a-troubleshoot
description: Troubleshoot openclaw-a2a-p2p installation and runtime issues. Use when Agent Card requests fail, JSON-RPC returns 404/401, plugin routes do not register, bearer auth mismatches, peers cannot communicate, or routing.sessionKey causes stale or missing replies.
---

Check in this order:

1. Confirm the plugin is installed and loaded.
2. Confirm the gateway was restarted after config changes.
3. Confirm the Agent Card URL returns JSON.
4. Confirm `agentCard.url` points to `/a2a/jsonrpc`.
5. Confirm `peers[].agentCardUrl` points to `/.well-known/agent-card.json`.
6. Confirm bearer tokens match.
7. Confirm `routing.sessionKey` is set.
8. Prefer a dedicated routing session if replies look stale.

Common failures:

- `404`: route not registered or wrong path
- `401`: bearer token mismatch
- stale reply: busy session reused as `routing.sessionKey`
- peer not found: bad peer id or missing peer config
