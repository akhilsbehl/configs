# 03 — Send prompts and respond to control commands via IPC

**What to build:** The driver can send a follow-up prompt to a running subagent, and separately unblock it with a permission/decision response — through two structurally distinct channels that the runner never confuses with each other.

**Blocked by:** 01 — Launch a subagent to a Zellij tab and see it run to completion.

**Status:** ready-for-agent

- [ ] `subagents_send` appends a `{"type": "prompt", "text": "..."}` line to the target subagent's `inbox.jsonl`.
- [ ] `subagents_respond` appends a `{"type": "control", "verb": "respond", "value": "..."}` line to the same `inbox.jsonl`.
- [ ] The runner polls `inbox.jsonl` and strictly separates control-plane lines from data-plane prompt lines — a control verb is never passed to the subagent as if it were conversational text, and vice versa.
- [ ] Sending a response via `subagents_respond` clears the subagent's `blocked_permission`/`blocked_decision` state and `pending_prompt` once delivered.
- [ ] Tests run against mocked IPC directories verifying: prompt lines and control lines interleaved in the same `inbox.jsonl` are each routed correctly; a malformed line in the inbox doesn't crash the runner's poll loop.
