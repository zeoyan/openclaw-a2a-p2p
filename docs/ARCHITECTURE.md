# Architecture

## High-level design

The repository is structured around two main ideas:

1. **A2A Core Plugin**
2. **OpenClaw local routing adapter**

## A2A Core Plugin

The plugin is responsible for:

- publishing an Agent Card
- exposing JSON-RPC endpoints
- managing peer definitions
- tracking tasks locally
- providing agent tools for peer operations

## Local routing adapter

Inbound A2A messages are routed into OpenClaw through a configured `routing.sessionKey`.

Current MVP behavior:

- receive A2A `message/send`
- extract text parts
- send the message into a configured OpenClaw session
- read the resulting assistant reply
- map it back into A2A-style response content

## Why this architecture

- keeps protocol work in the plugin
- keeps peer exchange simple and implementation-focused
- makes later wrapper/bridge work easier for non-A2A-native runtimes like Codex or Claude Code

## Current limitation

The MVP uses a fixed `routing.sessionKey` rather than dynamic per-context routing.
