# 08 — Primary Dispatch Guard

**What to build:** The primary driver is blocked from launching a subagent engine via a roundabout bash command instead of `subagents_launch` — while ordinary background shell commands stay completely unaffected.

**Blocked by:** 01 — Launch a subagent to a Zellij tab and see it run to completion.

**Status:** ready-for-agent

- [ ] A `pi.on("tool_call")` hook gated on `event.toolName === "bash"` classifies the command's **target binary**, not the presence of backgrounding syntax (`&`, `nohup`, nested subshells).
- [ ] True positives (blocked): `claude -p ...`, `claude --bg ...`, `codex exec ...`, `agy -p ...`, `pi ...` — any direct invocation of one of the four engine CLIs from the primary driver's bash tool.
- [ ] False positives that must stay allowed: `npm test &`, `tail -f log.txt &`, and any other backgrounded command whose target binary is not one of the four engines.
- [ ] A denied call's error message names `subagents_launch` as the correct path.
- [ ] The guard is unconditional for Pi-as-primary-driver — no toggle, no escape hatch.
- [ ] The guard does not fire inside subagent Zellij tabs/worktrees — subagents remain free to use their own native delegation tools.
- [ ] Tests run the full true/false-positive matrix above as unit tests against the classifier function in isolation, plus an integration test confirming the `pi.on("tool_call")` hook actually returns `{ block: true }` for a true positive.
