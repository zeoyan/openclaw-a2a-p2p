# openclaw-a2a-p2p

A generic **A2A-style peer-to-peer plugin package for OpenClaw**, designed as a reusable GitHub repository that other agents can install, configure, and use.

> Status: **MVP validated locally**
>
> This repository has completed a real local loopback test:
> - Agent Card endpoint works
> - JSON-RPC endpoint works
> - `message/send` works
> - local OpenClaw routing works when using a **dedicated routing session**

---

## What this repository contains

### OpenClaw plugin
- publishes an Agent Card
- exposes JSON-RPC endpoints for A2A-style communication
- tracks local tasks
- provides agent tools for peer operations
- routes inbound messages into OpenClaw

### Skills
- `a2a-setup`
- `a2a-ops`
- `a2a-troubleshoot`

### Reference material
- peer config template
- TOOLS.md snippet template
- installation helper script
- docs for architecture, installation, configuration, and testing

---

## Current MVP scope

This repository currently focuses on the first practical milestone:

- installable OpenClaw plugin folder
- Agent Card endpoint
- JSON-RPC endpoint
- outbound peer send support
- local task store
- inbound routing into a configured OpenClaw session
- operator guidance through Skills and docs

It is **not yet** a full A2A v1.0 implementation with all protocol features.

---

## Repository layout

```text
openclaw-a2a-p2p/
├── openclaw.plugin.json
├── package.json
├── index.ts
├── README.md
├── IMPLEMENTATION_NOTES.md
├── docs/
│   ├── ARCHITECTURE.md
│   ├── CONFIGURATION.md
│   ├── INSTALL.md
│   └── SELF-TEST.md
├── examples/
│   └── openclaw.plugin-config.example.json
├── references/
│   ├── peer-config-template.json
│   └── tools-md-template.md
├── scripts/
│   └── install.sh
└── skills/
    ├── a2a-ops/
    │   └── SKILL.md
    ├── a2a-setup/
    │   └── SKILL.md
    └── a2a-troubleshoot/
        └── SKILL.md
```

---

## Quick start

### 1. Install the plugin

```bash
openclaw plugins install /path/to/openclaw-a2a-p2p
openclaw gateway restart
openclaw plugins info a2a-p2p
```

### 2. Add plugin config

Use the example in:

- `examples/openclaw.plugin-config.example.json`

or read the full guide:

- `docs/CONFIGURATION.md`

### 3. Pick a routing session

**Important:** use a **dedicated routing session** for inbound A2A traffic.

Do **not** point `routing.sessionKey` at a busy human chat session, because the MVP currently extracts the latest assistant reply from that session history.

Recommended pattern:

- one dedicated session per peer, or
- one dedicated shared A2A inbox session

### 4. Restart the gateway

```bash
openclaw gateway restart
```

### 5. Verify the Agent Card

```bash
curl http://HOST:PORT/a2a/.well-known/agent-card.json
```

### 6. Send a test request

```bash
curl -X POST http://HOST:PORT/a2a/jsonrpc \
  -H 'content-type: application/json' \
  -H 'authorization: Bearer YOUR_TOKEN' \
  --data '{
    "jsonrpc": "2.0",
    "id": "test-1",
    "method": "agent/getCard",
    "params": {}
  }'
```

---

## Tools exposed to OpenClaw agents

- `a2a_list_peers`
- `a2a_get_peer`
- `a2a_send`
- `a2a_get_task`
- `a2a_cancel_task`
- `a2a_refresh_peer_card`

---

## Local validation status

This project has been validated with real local testing.

### Confirmed working
- plugin loads
- Agent Card route returns `200`
- JSON-RPC route returns `200`
- inbound `message/send` routes into OpenClaw
- loopback test returns expected response when using a dedicated session

### Key findings from testing
- OpenClaw plugin HTTP routes must use route auth mode `plugin` or `gateway`; `none` prevents route registration and leads to `404`
- using the main active human session as `routing.sessionKey` can return stale replies; use a dedicated routing session instead

---

## Can another OpenClaw node use this repository?

Yes — **if it is configured correctly**.

Another OpenClaw instance can install this repository and communicate with this node when:

- the plugin is installed
- the plugin config is added
- the node has a reachable `agentCard.url`
- both nodes can reach each other over the network
- each node has the correct bearer token for the other peer
- each node has a valid dedicated `routing.sessionKey`

---

## Known limitations

- A2A protocol coverage is partial, not full-spec complete
- no SSE streaming endpoint yet
- no full artifact/file transfer pipeline yet
- task cancellation is local-only in MVP
- current inbound routing is session-based rather than context-mapped
- no wrapper packages yet for Claude Code / Codex / other runtimes

---

## Recommended next step after this MVP

1. Add richer protocol validation
2. Add streaming support
3. Add file/artifact handling
4. Add wrapper contracts for non-A2A-native runtimes
5. Add per-peer or per-context routing strategies

---

## Docs

- `docs/INSTALL.md`
- `docs/CONFIGURATION.md`
- `docs/ARCHITECTURE.md`
- `docs/SELF-TEST.md`

---

## License

Add your preferred license before publishing to GitHub.
