# Common pitfalls

## 1. Agent Card returns 404

Likely causes:

- gateway was not restarted
- plugin route registration failed
- wrong base path

Important implementation note:

- OpenClaw plugin HTTP routes must use route auth `plugin` or `gateway`
- using `none` causes route registration failure and 404 responses

## 2. `message/send` replies with stale content

Likely cause:

- `routing.sessionKey` points at an already-busy human chat session

Fix:

- use a dedicated routing session for A2A traffic

## 3. `agentCard.url` and `peers[].agentCardUrl` mixed up

Correct:

- `agentCard.url` -> `/a2a/jsonrpc`
- `peers[].agentCardUrl` -> `/.well-known/agent-card.json`

## 4. 401 unauthorized

Likely causes:

- wrong bearer token
- missing `Authorization: Bearer ...`
- peer token mismatch

## 5. Plugin installs but another agent still cannot use it

Check:

- the repo includes docs and config examples
- the operator actually copied the plugin config into OpenClaw
- the peer is reachable over the network
- a dedicated routing session is configured
