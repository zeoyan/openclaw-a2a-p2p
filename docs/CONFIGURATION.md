# Configuration

This file is for the small set of config fields that actually matter.

## The only self config that really matters

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
            "url": "http://HOST:PORT/a2a/jsonrpc"
          },
          "routing": {
            "sessionKey": "a2a-peer-xiaozhua",
            "mode": "subagent",
            "waitTimeoutMs": 15000
          },
          "security": {
            "inboundAuth": "bearer",
            "token": "REPLACE_WITH_LOCAL_INBOUND_TOKEN"
          },
          "peers": []
        }
      }
    }
  }
}
```

## Meaning of each field

### `server.allowRemote`
Allows non-loopback callers to hit this plugin's routes.

This is necessary for cross-machine use, but **not sufficient by itself**.

### `agentCard.url`
This node's own JSON-RPC endpoint.

For real peer-to-peer use, do **not** leave this on:

- `127.0.0.1`
- `localhost`

### `routing.sessionKey`
A dedicated local routing session for inbound A2A traffic.

Do not reuse a busy human chat session.

### `security.token`
This node's inbound bearer token.

Other peers need this token in order to call this node.

### `peers[]`
This node's local address book of other A2A peers.

## The one network rule that still matters

Cross-machine communication still requires all of these:

- `server.allowRemote = true`
- `agentCard.url` is reachable from the peer
- `gateway.bind` is not loopback-only
- the actual network path exists

If any of those are false, the plugin may be configured correctly but still unreachable.
