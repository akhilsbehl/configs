Type: research
Status: resolved
Blocked by: none

## Question

How does Firstmate separate Control Plane (verbs, interrupts, decisions) from Data Plane (prompts, context), and how should `pi-subagents` structure `/tmp/pi-subagents/<id>/` IPC files (`status.json`, `inbox.jsonl`, `output.log`, `context.jsonl`) to guarantee atomic reads/writes and prevent CLI prompt collision?

## Answer

Firstmate enforces a strict Control Plane (`bin/fm-control.sh`) vs Data Plane (`bin/fm-send.sh`) separation. Control plane commands use an allowlisted verb set (`interrupt`, `exit`, `relaunch`) with verified postconditions. Conversational messages use data plane routing markers (`[fm-from-firstmate]`). 

**Recommendation for `pi-subagents`**:
1. Retain `inbox.jsonl` control plane separation (`{"type": "control", "verb": "..."}`) vs prompt lines (`{"type": "prompt", "text": "..."}`).
2. Add a transactional `relaunch` control verb to `pi-subagents` allowing on-the-fly engine/model/thinking updates for active subagents without discarding Zellij tab, worktree, or instruction history.
3. Ensure atomic JSON line appends and file locking for `/tmp/pi-subagents/<id>/inbox.jsonl` and `status.json`.
