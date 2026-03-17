# openclaw-a2a-p2p

A reusable **A2A-style peer-to-peer plugin for OpenClaw**.

This repository is now optimized around a simple default workflow:

1. **install + init this node**
2. **copy this node's peer info**
3. **later paste another node's peer info to add that peer**
4. **start talking**

Advanced deployment and troubleshooting still exist, but they are secondary.

---

## Quick start

### Option A — one-shot install + init self

```bash
git clone <REPO_URL>
cd openclaw-a2a-p2p
./scripts/install-and-init.sh
```

What this does:

- installs the plugin
- enables remote-mode plugin config
- generates an inbound bearer token
- creates a dedicated routing session key
- tries to infer a reachable base URL
- exports this node's shareable `peer-info`
- writes that peer info to `~/.openclaw/state/a2a-p2p/peer-info.json`
- restarts the gateway last

This keeps the main goal intact: even if the current session is interrupted by restart, the peer info is already available.

Optional environment variables:

- `PUBLIC_BASE_URL=https://example.com`
- `A2A_NAME=小爪`
- `A2A_TOKEN=...`
- `A2A_ROUTING_SESSION_KEY=a2a-peer-xiaozhua`

### Option B — install from an agent

After install, the ideal agent flow is:

1. call `a2a_export_peer_info`
2. share the result with another node
3. when the other node's `peer-info` is pasted in, call `a2a_import_peer_info`

---

## The two core user actions

### 1) Export my peer info

Tool:

- `a2a_export_peer_info`

Shell:

```bash
./scripts/export-peer-info.sh > peer-info.json
```

Example output:

```json
{
  "kind": "openclaw-a2a-peer-info",
  "version": 1,
  "name": "小爪",
  "agentCardUrl": "https://example.com/a2a/.well-known/agent-card.json",
  "bearerToken": "replace-with-real-token"
}
```

### 2) Import someone else's peer info

Preferred in-agent path:

- `a2a_import_peer_info`

Lower-level helper:

- `a2a_build_peer_entry`

Shell path:

```bash
./scripts/import-peer-info.sh ./peer-info.json claw-brother "爪子哥"
```

Import means:

- create/update one entry under local `peers[]`
- keep that peer in the local address book
- allow future `a2a_send` calls to target it

---

## Communication model

This plugin uses a local peer registry.

- If **A wants to send to B**, A must know B's `peer-info`
- If **B also wants to send back to A**, B must also know A's `peer-info`

So:

- **one-way communication** only requires one side to import the other
- **two-way communication** usually means both sides exchange and import each other's `peer-info`

---

## Tools exposed to OpenClaw agents

- `a2a_list_peers`
- `a2a_get_peer`
- `a2a_send`
- `a2a_get_task`
- `a2a_cancel_task`
- `a2a_refresh_peer_card`
- `a2a_export_peer_info`
- `a2a_build_peer_entry`
- `a2a_import_peer_info`
- `a2a_remove_peer`

---

## What stays out of the main flow

These topics still matter, but they are fallback / advanced material rather than the main UX:

- public internet reachability
- reverse proxy / domain setup
- Tailscale
- AWS security groups / host firewalls
- loopback-only pitfalls
- advanced operator checklists

See:

- `docs/INSTALL.md`
- `docs/CONFIGURATION.md`
- `docs/PEER-INFO.md`
- `docs/AGENT-RECOVERY.md`
- `docs/PITFALLS.md`
- `docs/TAILSCALE.md`
- `docs/ARCHITECTURE.md`

---

## Status

MVP validated locally and in basic two-node setup. Not yet a full A2A v1.0 implementation.

Known limitations:

- no SSE streaming endpoint yet
- no full artifact/file transfer pipeline yet
- task cancellation is local-only in MVP
- inbound routing is still session-based rather than context-mapped
- network exposure still depends on actual reachability outside OpenClaw

---

## License

MIT. See `LICENSE`.
