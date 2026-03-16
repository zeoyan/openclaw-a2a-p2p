# AI Agent Operator Checklist

Use this checklist when an AI agent or human operator is configuring this repository for the first time.

## Goal declaration

Before editing config, explicitly decide which goal applies:

- **Local self-test only**
- **Real cross-machine peer communication**

Do not mix the two.

---

## If the goal is real cross-machine communication

The setup is **not complete** until all of these are true:

### Plugin config

- [ ] `plugins.entries.a2a-p2p.enabled = true`
- [ ] `plugins.entries.a2a-p2p.config.server.allowRemote = true`
- [ ] `plugins.entries.a2a-p2p.config.agentCard.url = http(s)://REACHABLE_HOST/.../jsonrpc`
- [ ] `agentCard.url` does **not** use `127.0.0.1` or `localhost`
- [ ] `plugins.entries.a2a-p2p.config.security.token` is set
- [ ] `plugins.entries.a2a-p2p.config.routing.sessionKey` is dedicated to A2A traffic

### OpenClaw gateway / network

- [ ] OpenClaw `gateway.bind` is not loopback-only for the intended network path
- [ ] firewall / reverse proxy / Tailscale / private network path is actually reachable
- [ ] another machine can reach the Agent Card URL

### Verification

- [ ] Agent Card returns `200` from another machine
- [ ] `agent/getCard` returns `200` from another machine
- [ ] `message/send` returns a valid reply from another machine

If any item above is false, do **not** claim the node is remotely ready.

---

## Wrong conclusions to avoid

Do **not** conclude success from any of these alone:

- plugin installed successfully
- plugin status is `loaded`
- localhost curl works
- `server.allowRemote=true` is set
- config file contains a URL that merely looks complete

Those are necessary in some cases, but not sufficient for real peer-to-peer reachability.

---

## Recommended operator flow

1. Read `START-HERE.md`
2. Read `docs/CONFIGURATION.md`
3. Run `scripts/preflight-remote.sh` against the OpenClaw config before making claims
4. Read `docs/OPENCLAW-TO-OPENCLAW.md`
5. Verify from another machine

---

## Minimum acceptable final output from an AI agent

A setup agent should clearly say one of these:

### Good output

- "Configured for local-only loopback testing. Not reachable from another machine yet."
- "Configured for remote mode, but external verification is still pending."
- "Configured for remote mode and verified from another machine."

### Bad output

- "Setup complete" after only localhost checks
- "Peer-ready" while `agentCard.url` still points to `127.0.0.1`
- "Remote mode enabled" while OpenClaw gateway is still loopback-only
