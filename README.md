# openclaw-a2a-p2p

A reusable **A2A-style peer-to-peer plugin for OpenClaw**.

Its job is simple:

- expose an Agent Card
- expose a JSON-RPC endpoint
- let this node talk to other peers
- let other peers talk to this node
- exchange a minimal `peer-info` object for connectivity

This repository is designed for **peer-to-peer / multi-peer** connectivity.

---

## If you are new here

Start with:

- `START-HERE.md`

Then read:

1. `docs/INSTALL.md`
2. `docs/CONFIGURATION.md`
3. `docs/PEER-INFO.md`

Only read `docs/PITFALLS.md` if something fails.

---

## Default path

1. Install this repository as an OpenClaw plugin
2. Configure this node's reachable `agentCard.url`, inbound bearer token, and dedicated `routing.sessionKey`
3. Export this node's minimal `peer-info.json`
4. Import another peer's `peer-info.json`
5. Restart and verify connectivity

---

## Minimal peer-info

The default exchange object is intentionally small:

```json
{
  "kind": "openclaw-a2a-peer-info",
  "version": 1,
  "name": "小爪",
  "agentCardUrl": "https://example.com/a2a/.well-known/agent-card.json",
  "bearerToken": "replace-with-real-token"
}
```

This is enough for another installed `a2a-p2p` node to discover and authenticate to this node.

---

## Install

From a cloned repository:

```bash
git clone <REPO_URL>
cd openclaw-a2a-p2p
openclaw plugins install "$PWD"
openclaw gateway restart
openclaw plugins info a2a-p2p
```

For more detail:

- `docs/INSTALL.md`

---

## What this repository contains

- OpenClaw plugin manifest and implementation
- local task store
- Agent Card and JSON-RPC routes
- peer operations tools
- examples and docs for install/configuration/peer exchange
- helper scripts for export/import/bootstrap

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

---

## Validated locally

Confirmed working in local loopback testing:

- plugin loads
- Agent Card route returns `200`
- JSON-RPC route returns `200`
- inbound `message/send` routes into OpenClaw
- loopback test returns the expected response when using a dedicated routing session

Important findings:

- plugin HTTP route auth must be `plugin` or `gateway`; `none` leads to `404`
- `routing.sessionKey` should be a dedicated routing session, not a busy human chat session

---

## Documentation

- `START-HERE.md`
- `docs/INSTALL.md`
- `docs/CONFIGURATION.md`
- `docs/PEER-INFO.md`
- `docs/PITFALLS.md`
- `docs/ARCHITECTURE.md`
- `docs/TAILSCALE.md`
- `docs/SELF-TEST.md`

---

## Status

MVP validated locally. Not yet a full A2A v1.0 implementation.

Known limitations:

- no SSE streaming endpoint yet
- no full artifact/file transfer pipeline yet
- task cancellation is local-only in MVP
- current inbound routing is session-based rather than context-mapped
- no wrapper packages yet for non-A2A-native runtimes

---

## License

MIT. See `LICENSE`.
