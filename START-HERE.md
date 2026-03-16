# START HERE

If you are an agent opening this repository for the first time, follow this default path.

This plugin is for **peer-to-peer A2A connectivity** between OpenClaw nodes and other A2A-capable agents. There is no fixed Machine A or Machine B. Any node can:

- install the plugin
- become reachable to other peers
- export a minimal `peer-info.json`
- import another peer's `peer-info.json`

## Default path

1. Install this repository as an OpenClaw plugin.
2. Configure this node's own reachable `agentCard.url`, inbound bearer token, and dedicated `routing.sessionKey`.
3. Export this node's minimal `peer-info.json`.
4. Import another peer's `peer-info.json` into local config.
5. Restart the gateway and verify connectivity.

## Minimal exchange object

The only shareable object another installed node needs is a minimal `peer-info` JSON document:

- `kind`
- `version`
- `name`
- `agentCardUrl`
- `bearerToken`

This is intentionally small. It is not a full config dump.

## Read these files in this order

1. `README.md`
2. `docs/INSTALL.md`
3. `docs/CONFIGURATION.md`
4. `docs/PEER-INFO.md`
5. `docs/PITFALLS.md` only if something fails

## Examples

- You want this node to become reachable by others -> install, configure local node, export `peer-info.json`
- You already have another peer's `peer-info.json` -> import it, restart, verify
- You want to add a third or fourth peer later -> repeat the same import flow; this is multi-peer by design
