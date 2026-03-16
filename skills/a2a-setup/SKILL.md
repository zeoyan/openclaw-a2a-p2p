---
name: a2a-setup
description: Configure the openclaw-a2a-p2p plugin for peer-to-peer agent communication. Use when installing this repository, adding peer definitions, setting agentCard.url, bearer tokens, routing.sessionKey, or verifying that two OpenClaw nodes can reach each other over the A2A-style endpoints.
---

Configure the plugin in this order:

1. Confirm the `a2a-p2p` plugin is installed and loaded.
2. Set `agentCard.url` to the node's reachable JSON-RPC endpoint.
3. Set `security.token` for inbound bearer auth.
4. Set `routing.sessionKey` to a **dedicated** OpenClaw session.
5. Add peer entries under `peers`.
6. Restart the gateway.
7. Verify the Agent Card and JSON-RPC endpoints.

Keep these two fields distinct:

- `agentCard.url` = this node's JSON-RPC endpoint
- `peers[].agentCardUrl` = the remote node's Agent Card URL

Prefer Tailscale or private networking when possible.

Write stable peer notes into TOOLS.md after setup.
