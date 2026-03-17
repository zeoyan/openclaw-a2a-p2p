# Common pitfalls

This file is fallback-only.
Use it only when the main flow fails.

## 1. Agent Card returns 404

Usually means one of these:

- gateway was not restarted
- wrong base path
- plugin route registration failed

Important implementation note:

- OpenClaw plugin HTTP routes must use auth `plugin` or `gateway`
- using `none` breaks route registration

## 2. `message/send` replies with stale content

Usually means:

- `routing.sessionKey` points at a busy human chat session

Fix:

- use a dedicated A2A routing session

## 3. Wrong URL in the wrong place

Correct split:

- `agentCard.url` → `/a2a/jsonrpc`
- `peers[].agentCardUrl` → `/.well-known/agent-card.json`

## 4. 401 unauthorized

Check:

- bearer token matches
- request includes `Authorization: Bearer ...`

## 5. Remote peers still cannot connect

Even if plugin config looks correct, check:

- `agentCard.url` is not `127.0.0.1` / `localhost`
- `gateway.bind` is not loopback-only
- cloud firewall / host firewall / network path is actually open
