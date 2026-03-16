# Installation

## Requirements

- OpenClaw installed
- access to `openclaw` CLI
- a reachable network path between peers
- a plan for bearer tokens and routing sessions

## Install from a local folder

```bash
openclaw plugins install /path/to/openclaw-a2a-p2p
openclaw gateway restart
openclaw plugins info a2a-p2p
```

## Install from a cloned GitHub repository

```bash
git clone <REPO_URL>
cd openclaw-a2a-p2p
openclaw plugins install "$PWD"
openclaw gateway restart
openclaw plugins info a2a-p2p
```

## Verify plugin load

Expected result:

- plugin id: `a2a-p2p`
- status: `loaded`
- tools visible in plugin info

## If install succeeds but routes still fail

Check:

1. gateway was restarted
2. plugin config exists under `plugins.entries.a2a-p2p.config`
3. `agentCard.url` points at the JSON-RPC endpoint
4. the node can actually bind and serve the gateway
