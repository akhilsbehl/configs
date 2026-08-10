# 05 — Primary Driver Tools, Zero-Token Supervision, & Restart-Proof Recovery

**What to build:** Primary Pi extension registering driver tools (`subagents_launch`, `subagents_list`, `subagents_send`, `subagents_respond`, `subagents_kill`), declarative dispatch rule integration (`crew-dispatch.json`), event-driven zero-token Node.js supervision loop, TUI status text widget, and restart-proof session recovery digest.

**Blocked by:** 02, 03, 04

**Status:** ready-for-agent

- [ ] `subagents_launch` tool spawns subagent tab, sets up IPC directory, creates optional disposable git worktree, resolves declarative dispatch rules if `task_type` specified, and optionally exports context snapshot
- [ ] Operates an event-driven zero-token Node.js polling loop (`setInterval`) scanning `/tmp/pi-subagents/*/status.json` at 0 LLM tokens
- [ ] `subagents_list` tool scans `/tmp/pi-subagents/` directories, verifies PID liveness (marking dead processes as `failed`/`stale`), and returns active subagent statuses and pending permission prompts or decision questions
- [ ] `subagents_send` tool appends follow-up prompts or context updates to `inbox.jsonl`
- [ ] `subagents_respond` tool sends permission response (`y`/`n`) or authority decision text as a control plane command to unblock subagent
- [ ] `subagents_kill` tool terminates runner process, closes Zellij tab, and tears down disposable git worktree
- [ ] Pi TUI text widget renders active subagents in `blocked_permission` or `blocked_decision` state
- [ ] Auto-injects subagent fleet summary digest into driver context when Pi starts or resumes (`pi.on("session_start")`), ensuring restart-proof recovery across driver restarts
