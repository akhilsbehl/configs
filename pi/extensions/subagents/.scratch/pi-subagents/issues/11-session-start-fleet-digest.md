# 11 — Session-start fleet recovery digest

**What to build:** If the driver's Pi session restarts or resumes, it immediately knows what subagents are still out there and what state they're in — nothing is orphaned or forgotten across a restart.

**Blocked by:** 02 — List subagents and classify liveness/busy state; 10 — Zero-token supervision loop & Driver Turn-End Guard.

**Status:** ready-for-agent

- [ ] On `pi.on("session_start")`, the extension scans `/tmp/pi-subagents/` and injects an active-fleet status digest into the driver's context.
- [ ] The digest reflects each subagent's current classified state (from Ticket 02's logic), not a stale snapshot from before the restart.
- [ ] A session restart with zero active subagents injects nothing (no empty/noisy digest).
- [ ] Tests run against mocked IPC directories with fixtures for: multiple active subagents of mixed states, zero active subagents, and a subagent whose process died while the driver was down (reclassified correctly per Ticket 02, not shown as still running).
