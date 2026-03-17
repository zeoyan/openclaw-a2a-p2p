# START-HERE

If you are an AI agent or operator opening this repository for the first time, follow this order:

## Main path

1. `README.md`
2. `docs/INSTALL.md`
3. `docs/PEER-INFO.md`

That is the default workflow.

The intended UX is:

1. install + init this node
2. output this node's peer info
3. later import another node's peer info when needed
4. start talking

## Do not overcomplicate first-run setup

Do **not** start with advanced deployment branches unless the main path fails.

For most first runs, the important question is simply:

- can this node initialize itself cleanly?
- can it export its own peer info?
- can it later import another peer's peer info?

## Only if something fails

Then move to fallback / advanced material:

- `docs/AGENT-RECOVERY.md`
- `docs/PITFALLS.md`
- `docs/CONFIGURATION.md`
- `docs/TAILSCALE.md`
- `docs/ARCHITECTURE.md`

## Still true even with the simpler UX

Remote communication still requires all of these:

- `server.allowRemote = true`
- `agentCard.url` is reachable from the peer
- `gateway.bind` is not loopback-only for the intended path
- the real network path exists

A clean install is **not** the same as real remote reachability.
