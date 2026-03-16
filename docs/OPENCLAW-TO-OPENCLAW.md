# OpenClaw-to-OpenClaw setup

This is the simplest two-node setup for getting **小爪** and **爪子哥** to talk.

## Node A

Assume:

- name: `小爪`
- base URL: `http://NODE_A:18789`
- inbound token: `TOKEN_A`
- routing session: `a2a-peer-xiaozhua`

## Node B

Assume:

- name: `爪子哥`
- base URL: `http://NODE_B:18789`
- inbound token: `TOKEN_B`
- routing session: `a2a-peer-zhuazige`

## Install on both nodes

```bash
openclaw plugins install /path/to/openclaw-a2a-p2p
openclaw gateway restart
openclaw plugins info a2a-p2p
```

Before continuing, confirm both nodes are intended to be remotely reachable:

- `server.allowRemote = true`
- `agentCard.url` does not use `127.0.0.1` or `localhost`
- OpenClaw gateway is not loopback-only for the intended peer path

Recommended pre-check on each node:

```bash
./scripts/preflight-remote.sh ~/.openclaw/openclaw.json
```

## Configure Node A

- `agentCard.name = 小爪`
- `agentCard.url = http://NODE_A:18789/a2a/jsonrpc`
- `security.token = TOKEN_A`
- `routing.sessionKey = a2a-peer-xiaozhua`
- add peer entry for Node B using `TOKEN_B`

## Configure Node B

- `agentCard.name = 爪子哥`
- `agentCard.url = http://NODE_B:18789/a2a/jsonrpc`
- `security.token = TOKEN_B`
- `routing.sessionKey = a2a-peer-zhuazige`
- add peer entry for Node A using `TOKEN_A`

## Verify Node A can see Node B

```bash
curl http://NODE_B:18789/a2a/.well-known/agent-card.json
```

## Verify Node B can see Node A

```bash
curl http://NODE_A:18789/a2a/.well-known/agent-card.json
```

## Recommended pattern

Use one dedicated routing session per peer.

Examples:

- `a2a-peer-xiaozhua`
- `a2a-peer-zhuazige`

Do not reuse a busy human chat session.
