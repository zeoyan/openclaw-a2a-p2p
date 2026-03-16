# START-HERE

If you are an AI agent or operator opening this repository for the first time, read this file before touching config.

This plugin is for **peer-to-peer A2A connectivity** between OpenClaw nodes and other A2A-capable agents. A node can:

- install the plugin
- become reachable to other peers
- export a minimal `peer-info.json`
- import another peer's `peer-info.json`

## The pitfall most people hit

This plugin supports real cross-machine communication, but it is easy to accidentally leave it in **local-only / loopback mode**.

That happens when any of these are true:

- `plugins.entries.a2a-p2p.config.server.allowRemote = false`
- `plugins.entries.a2a-p2p.config.agentCard.url` uses `127.0.0.1` or `localhost`
- OpenClaw `gateway.bind = loopback`
- the machine is not reachable from the peer network

If another machine is supposed to call this node, all four must be checked.

---

## Decide which mode you are setting up

### Mode A: local loopback test only
Use this only for same-host testing.

Signs you are in local-only mode:

- `agentCard.url = http://127.0.0.1:...`
- `agentCard.url = http://localhost:...`
- `server.allowRemote = false`
- `gateway.bind = loopback`

This mode is fine for self-test, but **another machine cannot use it**.

### Mode B: real peer-to-peer / remote mode
Use this for OpenClaw-to-OpenClaw communication across machines.

Required:

1. `server.allowRemote = true`
2. `agentCard.url = http(s)://<reachable-host-or-domain>/a2a/jsonrpc`
3. `gateway.bind` must allow inbound traffic from the peer path (direct bind, reverse proxy, or private network such as Tailscale)
4. peer network reachability must actually exist
5. bearer tokens must match
6. `routing.sessionKey` must be dedicated to A2A traffic

---

## Minimum remote-mode checklist

Before claiming setup is complete, verify all of this:

- [ ] plugin installed and loaded
- [ ] gateway restarted after config change
- [ ] `server.allowRemote = true`
- [ ] `agentCard.url` does **not** use `127.0.0.1` or `localhost`
- [ ] OpenClaw gateway is not loopback-only for the intended network path
- [ ] `routing.sessionKey` is dedicated
- [ ] inbound bearer token is set
- [ ] Agent Card endpoint returns `200` from another machine
- [ ] JSON-RPC endpoint returns `200` from another machine

If you cannot verify from another machine, do **not** claim the node is remotely reachable yet.

---

## Default path

1. Install this repository as an OpenClaw plugin.
2. Configure this node's own reachable `agentCard.url`, inbound bearer token, and dedicated `routing.sessionKey`.
3. Export this node's minimal `peer-info.json`.
4. Import another peer's `peer-info.json` into local config.
5. Restart the gateway and verify connectivity.

## Read these files in this order

1. `README.md`
2. `docs/INSTALL.md`
3. `docs/CONFIGURATION.md`
4. `docs/PEER-INFO.md`
5. `docs/AI-AGENT-OPERATOR-CHECKLIST.md`
6. `docs/OPENCLAW-TO-OPENCLAW.md`
7. `docs/PITFALLS.md` only if something fails
