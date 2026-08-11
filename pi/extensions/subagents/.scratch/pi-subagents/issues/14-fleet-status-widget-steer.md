# 14 — Fleet status widget & steer action

**What to build:** A TUI widget shows the driver every waiting/active subagent at a glance, without ever growing unbounded, and each row lets the driver send it a quick instruction in one action.

**Blocked by:** 03 — Send prompts and respond to control commands via IPC; 10 — Zero-token supervision loop & Driver Turn-End Guard.

**Status:** ready-for-agent

- [ ] The widget renders purely from the supervision loop's (Ticket 10) aggregated state — it never re-derives state by reading raw IPC files itself.
- [ ] The widget's "waiting subagents" list is capped at a bounded row count with an explicit "+K more" disclosure line rather than truncating silently or growing unbounded.
- [ ] Each row exposes a one-click "steer" action that appends a `{"type": "prompt", "text": "..."}` line to that subagent's `inbox.jsonl` — the same path as `subagents_send` (Ticket 03), not a separate pane-injection mechanism.
- [ ] A "watch" affordance on each row can display the subagent's current pane content (`zellij action dump-screen --pane-id <id>`) without switching the driver's active tab focus.
- [ ] Tests run against a mocked supervision-loop state feed, covering: the row cap and "+K more" disclosure at various fleet sizes, and the steer action producing the correct `inbox.jsonl` line.
