# 07 — Firstmate-Adapted Verification Test Suite

**What to build:** Test behaviors adapted from Firstmate's test suite (`fm-backend-zellij.test.sh`, `fm-tmux-agent-liveness.test.sh`, `fm-tmux-submit-busy.test.sh`, `fm-control.test.sh`, `fm-spawn-worktree-settle.test.sh`, `fm-session-start.test.sh`) ensuring robust multiplexer handling, multi-surface liveness detection, busy/idle state classification, input retry safety, IPC control plane isolation, worktree teardown safety, and restart-proof recovery.

**Blocked by:** 01, 02, 03, 04, 05, 06

**Status:** ready-for-agent

## Required Test Behaviors

### 1. Zellij Backend & Tab Management Behaviors (from `fm-backend-zellij.test.sh`)
- [ ] **Version Check**: Refuses execution if `zellij` binary is missing or version is below 0.44.0.
- [ ] **Duplicate Tab Title Refusal**: Fails launch if a tab with the home-scoped title (`subagent:<home_hash>-<id>`) already exists.
- [ ] **Steal-Focus Restoration**: Verifies that `zellij action go-to-tab-by-id` is called immediately after `zellij action new-tab` to restore the driver's active tab.
- [ ] **False-Positive Exit-Code Defense**: Verifies that pane/session existence is checked before issuing Zellij CLI actions (preventing Zellij's exit-0 on missing targets from reporting false success).
- [ ] **Ghost Tab Prevention**: Verifies that subagent cleanup resolves the owning `tab_id` and calls `close-tab-by-id` (not bare `close-pane`).

### 2. Multi-Surface Subagent Process Liveness Behaviors (from `fm-tmux-agent-liveness.test.sh`)
- [ ] **Foreground Child Process Detection**: Accurately classifies a subagent as `alive` when running inside a launcher shell script (inspects foreground process group children).
- [ ] **Version-Path Disambiguation**: Classifies executable names like `claude/2.1.220` as `alive` if the installation directory matches the harness.
- [ ] **Decoy Name Isolation**: Ensures binaries merely containing harness fragments (e.g. `musescore` containing `muse`) are classified as `ambiguous` or `dead`, never `alive`.
- [ ] **Background Job Rejection**: Ensures backgrounded jobs (`agent &`) in an idle terminal classify as `dead`.
- [ ] **Idle Shell Liveness**: Confirms an idle shell with no active CLI process classifies as `dead`.

### 3. Busy vs. Idle State & Input Submission Behaviors (from `fm-tmux-submit-busy.test.sh`)
- [ ] **Engine-Specific Busy Signatures**:
  - `pi`: Matches `Working...` stream indicator.
  - `claude`: Matches progress/spinner signatures (`✢ Pollinating...`, `esc to interrupt`).
  - `codex`: Matches `esc to interrupt`.
  - `agy`: Matches reasoning effort indicator.
- [ ] **Signature Isolation**: Ensures `pi` busy signatures are NOT evaluated against `claude` or `codex` streams to prevent false busy state matches.
- [ ] **Input Buffer Retry & Partial Clear**: When input is sent to a busy subagent, applies a bounded Enter retry budget. If submission fails, issues `Ctrl+C` to clear uncleared partial input and prevent prompt corruption.

### 4. Control Plane vs. Data Plane Isolation Behaviors (from `fm-control.test.sh`)
- [ ] **Control Verb Separation**: Verifies that `kill`, `respond`, and `interrupt` commands are written as `type: "control"` in `inbox.jsonl` and handled directly without reaching model prompt text.
- [ ] **Permission Unblock Atomic Closure**: Verifies that passing `subagents_respond` with approval transitions subagent state from `blocked_permission` back to `running` or `idle` and clears `pending_prompt`.

### 5. Disposable Worktree Behaviors (from `fm-spawn-worktree-settle.test.sh` & `fm-teardown.test.sh`)
- [ ] **Worktree Creation Isolation**: Verifies that `worktree: true` creates `.scratch/worktrees/<id>` via `git worktree add` and sets subagent CWD to that isolated path.
- [ ] **Worktree Teardown Safety**: Verifies that `subagents_kill` removes `.scratch/worktrees/<id>` via `git worktree remove --force` without affecting uncommitted changes on the main branch.

### 6. Restart-Proof Recovery Behaviors (from `fm-session-start.test.sh`)
- [ ] **Disk State Reconstruction**: Verifies that `pi.on("session_start")` scans `/tmp/pi-subagents/*/status.json` and auto-injects active/blocked subagent fleet status into Pi driver context.
