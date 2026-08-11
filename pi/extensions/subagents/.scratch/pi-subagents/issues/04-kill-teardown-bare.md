# 04 — Kill a subagent and tear down its Zellij tab

**What to build:** The driver can end a subagent's session cleanly — the process stops, its Zellij tab closes, and its IPC directory is removed. (No git worktree teardown logic yet — bare subagents only, worktree isolation is Ticket 06.)

**Blocked by:** 01 — Launch a subagent to a Zellij tab and see it run to completion; 03 — Send prompts and respond to control commands via IPC.

**Status:** ready-for-agent

- [ ] `subagents_kill` sends a `{"type": "control", "verb": "kill"}` command via the same `inbox.jsonl` path as Ticket 03.
- [ ] The subagent's Zellij tab is closed by matching its home-scoped `<home_hash>-<id>` tab name — including a ghost tab whose process already died.
- [ ] The subagent's `/tmp/pi-subagents/<id>/` IPC directory is removed only after the kill is confirmed (process gone), not optimistically before.
- [ ] Killing a subagent that is already dead (ghost tab, stale status) still succeeds and cleans up, rather than erroring because there was "nothing to kill."
- [ ] Tests run against a mocked `zellij` binary and mocked IPC directories, covering both a live subagent and an already-dead ghost.
