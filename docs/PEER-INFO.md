# Peer information exchange

This repository uses a **minimal peer-info format** for basic connectivity.

The goal is not to export every local detail. The goal is to export only the information another installed `a2a-p2p` node needs in order to connect.

## Minimal peer-info fields

Recommended basic format:

- `kind`
- `version`
- `name`
- `agentCardUrl`
- `bearerToken`

Why these fields:

- `agentCardUrl` is the remote discovery entrypoint
- `bearerToken` is needed for this plugin's default inbound auth model
- `name` gives the importing side a stable human-readable peer identity
- `kind` and `version` keep the exchange format machine-readable and evolvable

Not exported in basic mode:

- `jsonRpcUrl`
- `description`
- `routingMode`
- `sessionKey`
- other local implementation details

## Exchange flow

1. Node A exports a shareable `peer-info.json`
2. Node B imports it into local plugin config
3. Node B exports its own `peer-info.json`
4. Node A imports that in reverse

After this, both peers know how to discover and authenticate to each other.

## Export

```bash
./scripts/export-peer-info.sh > peer-info.json
```

## Import

Preferred in-agent path:

- use `a2a_build_peer_entry`
- then merge the returned peer entry into local plugin config

Shell path:

```bash
./scripts/import-peer-info.sh ./peer-info.json claw-brother "爪子哥"
```

This updates the local `a2a-p2p` config and adds or replaces a peer entry.

## Important note

This solves peer metadata exchange. It does **not** magically create internet reachability.

At least one side still needs a network path the other side can reach, such as:

- public HTTP(S)
- reverse proxy / domain
- same private network
- optional Tailscale

## Recommended lightweight default

Use A2A over HTTP(S) as the default design.
Treat Tailscale, SSH tunnel, and other network helpers as optional deployment modes rather than required dependencies.
