# Implementation notes

## This package is intentionally an MVP

The current implementation is designed to give Joey哥 a **reusable installable folder** that can be installed into another OpenClaw host and configured for A2A-style peer communication.

## What is implemented now

- installable OpenClaw plugin folder
- plugin manifest + config schema
- Agent Card route
- JSON-RPC route
- outbound peer send tool
- local task store
- inbound request handling routed via `routing.sessionKey`
- setup/ops/troubleshooting skills
- install helper script

## What remains for full protocol maturity

- strict A2A v1.0 object validation
- SSE streaming endpoint
- push notification support
- richer artifact/file handling
- remote cancel propagation
- wrapper contract packages for Codex / Claude Code / custom runtimes

## Self-test findings folded back into the project

- Plugin HTTP route auth must be `plugin` or `gateway`; using `none` prevents route registration and causes 404s
- Reusing a busy primary session as `routing.sessionKey` can return a stale assistant message; use a dedicated routing session for inbound A2A handling

## Architectural direction retained

This implementation keeps the intended architecture:

- A2A Core in plugin
- OpenClaw local adapter in plugin
- future wrappers/bridges as separate packages
