# Tailscale automation

Use `scripts/bootstrap-tailnet.sh` to automate Tailscale-based setup for the OpenClaw A2A plugin.

## Why this exists

The original manual path requires too much human intervention. For reusable agent-to-agent setup, the repository needs a script that automates:

- Tailscale installation
- `tailscaled` startup
- OpenClaw plugin config updates
- `plugins.allow` pinning
- generation of a strong bearer token
- construction of reachable Agent Card / JSON-RPC URLs

## Important security boundary

There is one step that cannot be safely bypassed without credentials:

- joining the machine to a tailnet

For fully unattended automation, provide:

- `TS_AUTHKEY=tskey-...`

Without `TS_AUTHKEY`, the script can still install Tailscale and print a login URL, but a human must finish the tailnet login.

## Unattended example

```bash
TS_AUTHKEY=tskey-... \
A2A_NAME="小爪" \
A2A_SESSION_KEY="a2a-peer-xiaozhua" \
./scripts/bootstrap-tailnet.sh
```

## Add a remote peer during bootstrap

```bash
TS_AUTHKEY=tskey-... \
PEER_ID=claw-brother \
PEER_NAME="爪子哥" \
PEER_AGENT_CARD_URL="http://100.x.y.z:18789/a2a/.well-known/agent-card.json" \
PEER_BEARER_TOKEN="REPLACE_WITH_PEER_TOKEN" \
./scripts/bootstrap-tailnet.sh
```

## Output

The script prints a minimal `peer-info` JSON object containing:

- `kind`
- `version`
- `name`
- `agentCardUrl`
- generated `bearerToken`

Use that peer-info on the remote peer.
