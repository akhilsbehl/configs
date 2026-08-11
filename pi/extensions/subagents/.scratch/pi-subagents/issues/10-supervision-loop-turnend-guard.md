# 10 — Zero-token supervision loop & Driver Turn-End Guard

**What to build:** The driver is automatically alerted, at zero LLM token cost, if a background subagent needs attention before the driver's turn ends — nothing is silently missed while the driver goes idle.

**Blocked by:** 02 — List subagents and classify liveness/busy state.

**Status:** ready-for-agent

- [ ] A non-blocking Node.js polling loop scans `/tmp/pi-subagents/*/status.json` on an interval, consuming no LLM tokens.
- [ ] The loop fires `subagent_blocked`/`subagent_completed` events when a subagent's state changes into or out of `blocked_permission`/`blocked_decision`/`completed`.
- [ ] On `pi.on("agent_settled")`, if any subagent is `blocked_permission` or `blocked_decision`, a non-blocking alert is injected into the driver's context naming the subagent id and its pending prompt, pointing at `/sa-decisions-backlog` or `subagents_respond`.
- [ ] The alert does not re-trigger itself on the settle event it just caused (re-entrancy guard).
- [ ] Tests run against a mocked polling target (fixture IPC directories with changing status files over time) verifying event firing on state transitions, and a mocked `agent_settled` sequence verifying the alert fires once and doesn't loop.
