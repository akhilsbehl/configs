Status: ready-for-agent

# Specification: `pi-subagents` Extension

## Problem Statement

When working on complex, multi-agent software engineering tasks, AI coding agents need to delegate sub-tasks (research, refactoring, code review, test generation) to specialized subagents. Currently, running subagents inside a single terminal or thread can block the driver agent, mix conversation contexts, or cause git file collisions when modifying code concurrently. Users need a way for Pi to launch and control independent subagents across multiple CLI engines (`pi`, `claude`, `codex`, `agy`) running in separate Zellij tabs with optional git worktree isolation, while retaining full visibility, context sharing, parameter overrides, and permission control from the primary Pi session.

## Solution

The `pi-subagents` extension enables Pi to act as a Primary Driver that launches, monitors, prompts, passes context to, and terminates subagents across `pi`, `claude`, `codex`, and `agy` engines running in dedicated Zellij tabs. Subagents run under a lightweight runner wrapper (`pi-subagent-runner`) that manages process execution, cleanses inherited driver environment variables (such as `PI_CODING_AGENT`), and exposes a file-based JSON IPC interface in `/tmp/pi-subagents/<id>/`. Subagents modifying code can run in isolated, disposable git worktrees (`.scratch/worktrees/<id>`). The extension operates an event-driven zero-token supervision loop in Node.js, features driver tools (`subagents_launch`, `subagents_list`, `subagents_send`, `subagents_respond`, `subagents_kill`), a declarative rule-based dispatch configuration (`crew-dispatch.json` / `subagents-dispatch.json`), a TUI text widget displaying waiting subagents, restart-proof session-start fleet recovery, and a `/sa-decisions-backlog` side-session loop for reviewing permission prompts and user authority/input requests without cluttering the main driver's conversation context.

## User Stories

1. As a developer, I want Pi to launch a subagent session in a new Zellij tab, so that I can inspect its execution visually without cluttering my driver session.
2. As a developer, I want subagent Zellij tab titles to be home-scoped (e.g. `subagent:<home_hash>-<id> [<engine>]`), so that subagents from different driver sessions do not collide.
3. As a developer, I want my active Zellij tab focus preserved when a subagent tab is created, so that launching background subagents does not yank my view away from the primary driver tab.
4. As a developer, I want to optionally run a code-modifying subagent in a disposable git worktree (`worktree: true`), so that concurrent subagent code edits do not cause git index locks or dirty file collisions.
5. As a developer, I want to choose the CLI engine (`pi`, `claude`, `codex`, or `agy`) when launching a subagent, so that I can leverage the best model for specific sub-tasks.
6. As a developer, I want to configure model names and thinking effort on the fly when launching a subagent, so that I can optimize speed versus reasoning depth per sub-task.
7. As a developer, I want optional context sharing from Pi's active `.jsonl` session log to a new subagent, so that the subagent understands the current project context immediately when requested.
8. As a developer, I want subagent context adapters to translate Pi's session context into the native system prompt/argument format expected by `claude`, `codex`, or `agy`, so that context transfer works seamlessly across engines.
9. As a developer, I want Pi to display a TUI status widget listing waiting subagents, driven by an event-driven zero-token Node.js supervision loop.
10. As a developer, I want Pi to automatically inject a subagent fleet status digest when starting or resuming a session (`pi.on("session_start")`), ensuring restart-proof session recovery after restarts or crashes.
11. As a developer, I want to send follow-up prompts or additional context to an active subagent, so that I can steer its work incrementally.
12. As a developer, I want structural lifecycle control commands (`interrupt`, `respond`, `kill`) explicitly separated from conversational chat text in the IPC queue (Control vs Data Plane split), so that subagents do not reason about control verbs as user prompts.
13. As a developer, I want to review and respond to pending permission prompts and user authority/input questions across waiting subagents via a `/sa-decisions-backlog` side-session loop, so that I can unblock subagents without polluting the primary driver's context.
14. As a developer, I want declarative rule-based subagent dispatch (`crew-dispatch.json`), matching task rules to engine/model/effort defaults, while maintaining full explicit override control in `subagents_launch`.
14. As a developer, I want to manually switch to a subagent's Zellij tab and interact with it directly, so that I have full manual control whenever needed.
15. As a developer, I want to kill a subagent, close its Zellij tab cleanly, and tear down its disposable git worktree, so that resources are freed when work finishes.
16. As a developer, I want clear error feedback if I attempt to launch a subagent outside an active Zellij session, so that I know Zellij is required.

## Implementation Decisions

1. **Disposable Worktrees (Git Worktree Isolation)**:
   - `subagents_launch` accepts an optional `worktree?: boolean` flag (defaults to false).
   - When enabled, the extension executes `git worktree add .scratch/worktrees/<id> -b subagent/<id>` and spawns the subagent inside that isolated directory.
   - On `subagents_kill` or subagent teardown, the temporary worktree is safely removed via `git worktree remove --force .scratch/worktrees/<id>` and branch cleaned up.

2. **Event-Driven Zero-Token Supervision**:
   - Primary Pi extension runs a non-blocking Node.js polling loop (`setInterval`) at 0 LLM tokens, scanning `/tmp/pi-subagents/*/status.json`.
   - Fires events (`subagent_blocked`, `subagent_completed`) to update TUI widgets and trigger alerts without consuming context or LLM tokens.

3. **Restart-Proof Design & Session Start Recovery**:
   - All subagent state is persisted durably in `/tmp/pi-subagents/<id>/status.json` and `meta.json`.
   - On `pi.on("session_start")`, the extension scans `/tmp/pi-subagents/` and auto-injects an active subagent fleet status digest into Pi's context, making sessions fully restart-proof across driver restarts.

4. **Zellij Tab Lifecycle & Focus Restoration**:
   - Subagents run in dedicated Zellij tabs spawned via `zellij action new-tab --name "subagent:<home_hash>-<id> [<engine>]"`.
   - Home-scoped tab titles (`<home_hash>`) prevent ID collisions across multiple Pi driver sessions in the same Zellij session.
   - Restores active tab focus immediately after spawn using `zellij action go-to-tab-by-id` to prevent focus stealing.
   - Requires `ZELLIJ_SESSION_NAME` in environment; fails gracefully with an informative error if absent.

5. **IPC Protocol & Control Plane Separation (`/tmp/pi-subagents/<id>/`)**:
   - `status.json`: Contains `{ id, engine, state, pid, created_at, updated_at, pending_prompt, prompt_type, error }`. States: `starting`, `running`, `blocked_permission`, `blocked_decision`, `idle`, `completed`, `failed`, `killed`. `prompt_type` distinguishes permission approvals (`permission`) from user input/authority questions (`authority`).
   - `inbox.jsonl`: Command queue read by runner. Strictly separates control plane commands (`{"type": "control", "verb": "respond" | "kill" | "interrupt", "value": "..."}`) from conversational prompts (`{"type": "prompt", "text": "..."}`).
   - `output.log`: Streamed stdout/stderr output from the subagent CLI process.
   - `context.jsonl`: Exported conversation context snapshot.

6. **Runner Process (`pi-subagent-runner`) & Environment Sanitization**:
   - A Node.js wrapper process spawned inside each subagent Zellij tab.
   - Sanitizes inherited driver environment variables (unsetting `PI_CODING_AGENT`, `CLAUDECODE`, etc.) so subagent child CLI processes do not misidentify themselves as the driver.
   - Spawns target CLI (`pi`, `claude`, `codex`, `agy`) with PATH binary lookup.
   - Parses TTY stream for permission/approval prompt patterns (e.g., `Allow execution? [y/N]`) and user authority/clarification questions, updating `status.json` with `prompt_type: "permission"` or `"authority"`.
   - Polls `inbox.jsonl` and executes structural control commands or writes prompt text to CLI stdin.

7. **Engine Format Adapters & Authority Rules**:
   - Translates generic launch arguments (`model`, `thinking`, `systemPrompt`, `context`) into native CLI options:
     - `pi`: `--model`, `--thinking`, `--system-prompt`
     - `claude`: `--model`, `--system-prompt`
     - `codex`: `-m`, `-c`
     - `agy`: `-i`, `--model`, `--effort`, `--prompt`
   - Injects system prompt guidelines enforcing that subagents must elevate authority/ask-user decisions back to the primary driver rather than making unauthorized assumptions or faking user approvals.

8. **Declarative Multi-Agent Dispatch (`crew-dispatch.json`)**:
   - Configurable rule-based dispatch file (e.g. `subagents-dispatch.json` or `crew-dispatch.json`) matching task descriptions/types (e.g. "fresh news" -> `grok`, "rote rename" -> `claude/haiku`, "complex refactor" -> `codex/gpt-5.5` or `claude/sonnet`).
   - `subagents_launch` supports matching task type rules or accepting direct engine/model/effort parameter overrides.

9. **Primary Driver Extension Tools**:
   - `subagents_launch`: Spawns subagent tab, sets up IPC directory, creates optional git worktree, resolves declarative dispatch rules if specified, and optionally exports context snapshot.
   - `subagents_list`: Scans IPC directories, verifies PID liveness (marking dead processes as `failed`/`stale`), and returns current statuses and pending prompts.
   - `subagents_send`: Appends follow-up prompt or context update to `inbox.jsonl`.
   - `subagents_respond`: Sends permission or decision response as a control plane command to unblock subagent.
   - `subagents_kill`: Sends kill control command to inbox, cleans up IPC directory, closes Zellij tab, and tears down git worktree if created.
   - `/sa-decisions-backlog`: Interactive side-session command loop for reviewing and responding to waiting subagent permission requests and authority questions.

## Testing Decisions

- **Good Test Criteria**: Tests must verify external behavior, IPC control contracts, worktree creation/cleanup, multi-surface process liveness, busy/idle classification, and focus restoration logic without invoking real third-party CLI engines or requiring a live Zellij display session during automated test runs.
- **Seams Tested**:
  1. *Engine Argument Adapters*: Pure function unit tests verifying CLI flag translation for `pi`, `claude`, `codex`, `agy`.
  2. *Runner IPC & Control Plane*: Unit/component tests verifying `status.json` serialization, control vs prompt command separation in `inbox.jsonl`, and stream prompt pattern matching.
  3. *Worktree & Zellij Manager*: Unit tests verifying `git worktree` isolation setup/teardown and Zellij command generation.
  4. *Primary Driver Tools & Auto-Recovery*: Integration tests verifying `subagents_launch`, `subagents_list`, `subagents_send`, `subagents_respond`, `subagents_kill`, and `session_start` fleet digest injection using mocked Zellij execution and mocked IPC directories.
  5. *Firstmate-Adapted Verification Suite (Ticket 07)*: Comprehensive test cases adapted from Firstmate's test suite covering duplicate tab refusal, focus restoration, false-positive exit-code defense, ghost tab prevention, multi-surface liveness classification, engine-specific busy signatures, input buffer retry/clear safety, control vs data plane isolation, worktree teardown safety, and restart-proof disk recovery.

## Out of Scope

- Strict project boundary enforcement (Pi driver remains free to make direct edits when requested).
- ToS-violating native RPC/app-server integrations for third-party CLIs.
- Modifying third-party CLI source code (`claude`, `codex`, `agy`).
- Standalone GUI/terminal emulators outside Zellij.
- Subagent-to-subagent direct communication without primary driver orchestration.

## Further Notes

- All CLI binaries (`pi`, `claude`, `codex`, `agy`) are looked up dynamically in `PATH`.
