# 06 — `/sa-decisions-backlog` Interactive Side-Session Review Loop

**What to build:** Command `/sa-decisions-backlog` providing an interactive prompt-and-choose side-session loop to inspect and respond to pending permissions and user authority/input decisions across waiting subagents without polluting the primary driver conversation context.

**Blocked by:** 05 — Primary Driver Tools & TUI Status Widget

**Status:** ready-for-agent

- [ ] `/sa-decisions-backlog` command identifies all subagents currently in `blocked_permission` or `blocked_decision` state
- [ ] Presents interactive prompt listing pending subagents with permission or authority prompt details and options (`y`/`n`/custom response)
- [ ] Differentiates tool execution approval prompts from user authority/input questions (`prompt_type: "permission"` vs `"authority"`)
- [ ] Loop passes user decisions/responses via `subagents_respond`
- [ ] Execution runs in side session without adding messages to primary driver conversation context
