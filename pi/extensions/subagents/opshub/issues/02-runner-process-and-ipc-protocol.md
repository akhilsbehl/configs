# 02 — `pi-subagent-runner` Process & IPC Protocol Layer

**What to build:** The runner script (`src/runner/`) that manages subagent process execution, sanitizes parent driver environment variables, maintains the `/tmp/pi-subagents/<id>/` IPC directory (`status.json`, `inbox.jsonl`, `output.log`), parses output streams for permission prompts and user authority/input questions, tracks PID liveness, and processes inbox commands.

**Blocked by:** 01 — Engine Argument Adapters & PATH Resolution

**Status:** ready-for-agent

- [ ] Initializes runtime directory `/tmp/pi-subagents/<id>/` and writes initial `status.json` (`state: starting`)
- [ ] Sanitizes inherited driver environment variables (`PI_CODING_AGENT`, `CLAUDECODE`, `GROK_AGENT`, etc.) before spawning the subagent process so child processes do not misidentify as the driver
- [ ] Spawns target subagent CLI process and pipes output stream to `output.log`
- [ ] Pattern matches approval/permission prompts (`prompt_type: "permission"`) and user authority/input questions (`prompt_type: "authority"`), setting `state: blocked_permission` or `state: blocked_decision` with `pending_prompt`
- [ ] Enforces Control Plane separation in `inbox.jsonl`: structural lifecycle commands (`type: "control"`, `verb: "kill" | "respond"`) are executed immediately without reaching model text, while conversational inputs (`type: "prompt"`) are written to stdin
- [ ] Updates `status.json` state to `completed` or `failed` on subagent exit, recording PID for external liveness tracking
