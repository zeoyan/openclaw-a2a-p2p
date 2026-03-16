# Configuration

## Minimal plugin config

```json
{
  "plugins": {
    "entries": {
      "a2a-p2p": {
        "enabled": true,
        "config": {
          "server": {
            "basePath": "/a2a",
            "allowRemote": true
          },
          "agentCard": {
            "name": "小爪",
            "description": "OpenClaw A2A peer",
            "url": "http://HOST:PORT/a2a/jsonrpc",
            "provider": "OpenClaw",
            "streaming": true,
            "pushNotifications": false,
            "skills": [
              {
                "id": "chat",
                "name": "chat",
                "description": "General-purpose text chat routed into OpenClaw"
              }
            ]
          },
          "routing": {
            "sessionKey": "a2a-peer-inbox",
            "mode": "subagent",
            "waitTimeoutMs": 15000
          },
          "security": {
            "inboundAuth": "bearer",
            "token": "REPLACE_WITH_LOCAL_INBOUND_TOKEN",
            "maxBodyBytes": 262144
          },
          "peers": [
            {
              "id": "claw-brother",
              "name": "爪子哥",
              "agentCardUrl": "http://PEER_HOST:PEER_PORT/a2a/.well-known/agent-card.json",
              "auth": {
                "type": "bearer",
                "token": "REPLACE_WITH_PEER_INBOUND_TOKEN"
              },
              "labels": ["peer", "openclaw"]
            }
          ]
        }
      }
    }
  }
}
```

## Important distinctions

### `agentCard.url`
This is the node's own JSON-RPC endpoint.

Example:

```text
http://HOST:PORT/a2a/jsonrpc
```

### `peers[].agentCardUrl`
This is the remote peer's Agent Card URL.

Example:

```text
http://PEER_HOST:PEER_PORT/a2a/.well-known/agent-card.json
```

## Routing guidance

Use a dedicated routing session.

Recommended patterns:

- `a2a-peer-inbox`
- `a2a-peer-clawbro`
- `a2a-peer-codex`
- `a2a-peer-claude`

Avoid reusing an actively busy human chat session.

## Security guidance

- prefer private networking or Tailscale
- give each node its own inbound bearer token
- store peer tokens carefully
- only set `allowRemote=true` when remote access is intended
