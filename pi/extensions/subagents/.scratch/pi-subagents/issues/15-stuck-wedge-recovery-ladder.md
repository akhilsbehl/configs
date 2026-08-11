# 15 — Stuck/wedge recovery ladder

**What to build:** A subagent that's alive but stopped making progress gets recovered automatically through an escalating sequence of responses, and if recovery genuinely fails, the driver is told plainly instead of the fleet spinning forever.

**Blocked by:** 04 — Kill a subagent and tear down its Zellij tab; 05 — TTY prompt detection and interrupt buffer safety; 09 — Transactional relaunch control verb.

**Status:** ready-for-agent

- [ ] A subagent that is alive (PID present) but produces no output and doesn't respond to a control message within a bounded window is detected as a distinct "wedged" state — separate from process death.
- [ ] On suspected wedge, the ladder escalates in order: (1) peek at recent pane output (`zellij action dump-screen --pane-id <id>`), (2) send a redirect via `inbox.jsonl`, (3) send `interrupt`, (4) force a `relaunch` (Ticket 09) into the same tab/worktree/branch with a progress note.
- [ ] Forced relaunches are capped at 2 attempts per wedge episode; if still unresponsive after the second, the subagent is marked `failed` and the concrete state is surfaced to the driver rather than retried again.
- [ ] `correlation_id` is preserved unchanged across every relaunch this ladder triggers.
- [ ] Tests run against a mocked unresponsive subagent, verifying: the escalation fires in the correct order, the 2-attempt cap is enforced, and the `failed` terminal state is reached (not an infinite retry loop) when recovery is exhausted.
