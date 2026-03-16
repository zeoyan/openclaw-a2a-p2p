# Peer information exchange

This repository supports a simple information-exchange model:

1. Node A exports a shareable peer-info JSON document
2. Node B reads that JSON and imports it into its plugin config
3. Node B does the same in reverse
4. Both peers now know each other's Agent Card URL and bearer token

## Export

```bash
./scripts/export-peer-info.sh > peer-info.json
```

The output includes:

- `agentCardUrl`
- `jsonRpcUrl`
- `bearerToken`
- node identity fields

## Import

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
