# Peer information exchange

This repository now treats peer exchange as a simple two-step workflow:

1. initialize this node and export **my peer info**
2. later import **someone else's peer info** when I want to talk to them

## Minimal peer-info fields

Recommended basic format:

- `kind`
- `version`
- `name`
- `agentCardUrl`
- `bearerToken`

Example:

```json
{
  "kind": "openclaw-a2a-peer-info",
  "version": 1,
  "name": "小爪",
  "agentCardUrl": "https://example.com/a2a/.well-known/agent-card.json",
  "bearerToken": "replace-with-real-token"
}
```

## Export my peer info

Preferred in-agent path:

- `a2a_export_peer_info`

Shell path:

```bash
./scripts/export-peer-info.sh > peer-info.json
```

## Import someone else's peer info

Preferred in-agent path:

- `a2a_import_peer_info`

Lower-level helper:

- `a2a_build_peer_entry`

Shell path:

```bash
./scripts/import-peer-info.sh ./peer-info.json claw-brother "爪子哥"
```

## Communication model

This plugin keeps a **local peer registry**.

That means:

- if node A wants to send to node B, A must import B's peer info
- if node B also wants to send to node A, B must also import A's peer info

So full two-way communication usually means both sides exchange peer info.

## Important note

Peer-info exchange solves discovery + auth metadata.
It does **not** create network reachability by itself.

At least one side still needs a network path the other side can reach, such as:

- public HTTP(S)
- reverse proxy / domain
- same private network
- optional Tailscale
