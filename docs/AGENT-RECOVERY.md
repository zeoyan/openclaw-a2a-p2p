# Agent recovery notes

This file is not part of the main user flow.

Use it only when the ideal path fails.

## Common recovery branches

### Plugin installed but remote peers cannot connect
Check:

- `server.allowRemote=true`
- `agentCard.url` is not `127.0.0.1` / `localhost`
- `gateway.bind` is not loopback-only
- the real network path exists

### Peer imported but `a2a_send` still fails
Check:

- the peer exists in local `peers[]`
- the remote `agentCardUrl` returns `200`
- the remote bearer token matches

### Messages look stale or wrong
Check:

- `routing.sessionKey` is dedicated to A2A
- it is not a busy human chat session

### Public IP still times out
Check:

- AWS Security Group / cloud firewall
- host firewall
- reverse proxy / NAT / public routing
- whether private-network-only communication is intended instead
