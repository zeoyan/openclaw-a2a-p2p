---
name: a2a-ops
description: Operate an installed openclaw-a2a-p2p deployment. Use when sending peer messages, listing peers, refreshing Agent Cards, checking task state, or performing normal day-to-day A2A peer operations between OpenClaw nodes.
---

Use these tools:

- `a2a_list_peers`
- `a2a_get_peer`
- `a2a_send`
- `a2a_get_task`
- `a2a_cancel_task`
- `a2a_refresh_peer_card`

Operational guidance:

- List peers before guessing peer ids.
- Refresh a peer card when endpoint URLs or capabilities may have changed.
- Use a dedicated routing session on the receiving side.
- Treat this repository as an MVP: task cancellation is local-only and protocol coverage is partial.
