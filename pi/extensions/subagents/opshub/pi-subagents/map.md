# Wayfinder Map: pi-subagents

## Destination

Design and implement the `pi-subagents` extension for Pi, enabling launching, monitoring, prompting, context-sharing, disposable git worktrees, and lifecycle control across `pi`, `claude`, `codex`, and `agy` subagent sessions running in dedicated Zellij tabs.

## Notes

- Domain: Pi extensions, Zellij tab management, multi-engine CLI IPC wrapper, JSONL context sharing, disposable git worktrees.
- Skills to consult: `/domain-modeling`, `/codebase-design`, `/tdd`.
- Execution constraints:
  - Working directory boundary: `/home/akhil/warchives/pi-subagents/pi/extensions/subagents`.
  - Zellij layout: Dedicated tab per subagent (`zellij action new-tab`) with focus preservation and home-scoped titles (`subagent:<home_hash>-<id>`).
  - Worktree isolation: Optional disposable git worktrees (`.scratch/worktrees/<id>`) for code-modifying subagents.
  - Context sharing base: Optional filtered Pi session `.jsonl` conversation log adapted per engine.
  - CLI binaries: Dynamic PATH lookup for `pi`, `claude`, `codex`, `agy`.
  - IPC & Control Plane: Lightweight runner script (`pi-subagent-runner`) with `/tmp/pi-subagents/<id>/` IPC directory separating control commands from chat text, sanitizing parent driver environment variables (e.g., `PI_CODING_AGENT`), and detecting process liveness.
  - Supervision & UI: Event-driven zero-token Node.js supervision loop, declarative rule-based dispatch (`crew-dispatch.json`), TUI status text widget, restart-proof session recovery digest, and `/sa-decisions-backlog` side-session review loop.

## Decisions so far

- [Decision 01: Engine Adapters & PATH Resolution](issues/01-engine-adapters-and-path-resolution.md) — Dynamic PATH lookup, engine argument translation for `pi`, `claude`, `codex`, and `agy`, system prompt authority boundaries, and declarative rule-based dispatch (`crew-dispatch.json`).
- [Decision 02: IPC & Control Plane Layer](issues/02-runner-process-and-ipc-protocol.md) — `/tmp/pi-subagents/<id>/` IPC directory with Control vs Data Plane isolation in `inbox.jsonl`, env var sanitization, and PID liveness tracking.
- [Decision 03: Zellij & Disposable Worktree Manager](issues/03-zellij-and-worktree-manager.md) — Dedicated home-scoped Zellij tabs with focus restoration and optional `git worktree` isolation with safe orphan cleanup.
- [Decision 04: Session Context Exporter & Adapters](issues/04-session-context-exporter.md) — Optional context extraction from Pi's `.jsonl` session log with engine-specific prompt adapters.
- [Decision 05: Driver Tools, Supervision & Recovery](issues/05-driver-tools-and-tui-widget.md) — Driver tools with declarative dispatch support, 0-token Node.js supervision loop, TUI widget, and restart-proof `pi.on("session_start")` recovery digest.
- [Decision 06: `/sa-decisions-backlog` Review Command](issues/06-sa-decisions-backlog-command.md) — Side-session prompt-and-choose review loop for unblocking subagent permission requests and user authority/input decisions.
- [Decision 07: Firstmate-Adapted Test Suite](issues/07-firstmate-adapted-test-suite.md) — Test behaviors covering Zellij tab safety, multi-surface process liveness, engine-specific busy signatures, input retry safety, worktree teardown, and disk recovery.

## Not yet specified

- Subagent transcript logging & long-term session archiving across Zellij restarts.
- Multi-agent topologies (e.g. subagent-to-subagent IPC).

## Out of scope

- Strict project boundary enforcement (Pi driver remains free to make direct edits when requested).
- Native RPC / App-Server API modes for third-party CLIs that violate ToS.
- Direct modification of third-party CLI binaries (`claude`, `codex`, `agy`).
- Standalone GUI/terminal emulators outside Zellij.
