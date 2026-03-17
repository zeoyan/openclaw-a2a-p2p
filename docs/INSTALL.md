# Installation

If you want the shortest path, use the one-shot bootstrap script.

## Quick start

```bash
git clone <REPO_URL>
cd openclaw-a2a-p2p
./scripts/install-and-init.sh
```

This is the recommended default for users and agents with no prior setup context.

It will:

- install the plugin
- enable the plugin config
- generate a bearer token if needed
- create a dedicated routing session key
- try to infer a reachable base URL
- export this node's shareable peer info
- write it to `~/.openclaw/state/a2a-p2p/peer-info.json`
- restart the gateway last

This means the most important output already exists before restart happens.

Optional environment variables:

- `PUBLIC_BASE_URL=https://example.com`
- `A2A_NAME=小爪`
- `A2A_TOKEN=...`
- `A2A_ROUTING_SESSION_KEY=a2a-peer-xiaozhua`

## Manual path

If you want to do everything step-by-step:

```bash
openclaw plugins install /path/to/openclaw-a2a-p2p
openclaw gateway restart
openclaw plugins info a2a-p2p
```

Then configure:

- `server.allowRemote=true`
- `agentCard.url`
- `routing.sessionKey`
- `security.token`

## Important

Install success is not the same as remote reachability.

The plugin can be installed and loaded while the node is still local-only.

If another machine is supposed to call this node, also verify:

- `agentCard.url` is reachable from that machine
- `gateway.bind` is not loopback-only
- the actual network path exists

If something fails, then look at:

- `docs/PITFALLS.md`
- `docs/TAILSCALE.md`
- `docs/ARCHITECTURE.md`
