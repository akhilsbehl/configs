# Domain Glossary & Model: pi-subagents

## Core Concepts

- **Primary Driver**: The active `pi` session that launches, monitors, prompts, and controls subagents.
- **Subagent Session**: An isolated execution of a CLI AI coding agent (`pi`, `claude`, `codex`, `agy`) running inside its own dedicated Zellij tab.
- **Engine**: The CLI executable running inside a subagent session. Supported engines:
  - `pi` (Pi Coding Agent)
  - `claude` (Claude Code CLI)
  - `codex` (OpenAI Codex CLI)
  - `agy` (Antigravity CLI)
- **Subagent Runner / IPC Wrapper (`pi-subagent-runner`)**: A lightweight Node.js runner script launched inside each subagent Zellij tab. It sanitizes parent driver environment variables (unsetting `PI_CODING_AGENT`, `CLAUDECODE`, etc.), wraps the engine process, monitors execution/stdout/stderr, tracks PID liveness, exposes a file-based JSON IPC directory in `/tmp/pi-subagents/<id>/`, and executes inbox commands.
- **Zellij Tab Lifecycle**: Subagent tabs are spawned dynamically via `zellij action new-tab --name "subagent:<home_hash>-<id> [<engine>]"`. Tab focus is preserved immediately after spawn, and tab titles are home-scoped to prevent name collisions across driver sessions. Closing or killing a subagent terminates the tab.
- **Disposable Git Worktree**: An optional isolated git worktree (`.scratch/worktrees/<id>`) created when `worktree: true` is requested on launch, preventing concurrent subagent edits from locking or corrupting the main git working tree.
- **Context Sharing Payload**: Filtered context extracted from the primary Pi driver's session `.jsonl` log file, translated by engine-specific format adapters and injected at subagent spawn time or during follow-up messages.
- **Declarative Dispatch Rules (`crew-dispatch.json` / `subagents-dispatch.json`)**: Configurable rule-based dispatch matrix that matches task descriptions/types to default engines, models, and thinking effort levels, while supporting explicit parameter overrides.
- **Delegated Authority & Permission Gateway**: The status and event bridge that detects when a subagent is blocked on a tool execution permission prompt (`blocked_permission`) or user authority/input clarification question (`blocked_decision`). Enforces strict prompt rules that subagents must elevate authority decisions back to the primary driver rather than making unauthorized assumptions or faking user approvals.
- **Decisions Backlog Loop (`/sa-decisions-backlog`)**: An interactive side-session command loop for reviewing and responding to pending permission requests and authority questions across all waiting subagents without polluting the primary driver's conversation context.
- **Zero-Token Event Supervision**: A non-blocking Node.js polling loop (`setInterval`) running inside the primary driver extension that scans `/tmp/pi-subagents/*/status.json` at 0 LLM tokens, updating the TUI status widget and triggering session recovery digests (`pi.on("session_start")`).
