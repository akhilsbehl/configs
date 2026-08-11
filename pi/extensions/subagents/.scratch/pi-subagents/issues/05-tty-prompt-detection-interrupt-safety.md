# 05 — TTY prompt detection and interrupt buffer safety

**What to build:** The runner recognizes when a subagent's CLI is showing a permission prompt vs. an authority/clarification question on its terminal, records which via `prompt_type`, and clears any partially-typed input safely when interrupted.

**Blocked by:** 03 — Send prompts and respond to control commands via IPC.

**Status:** ready-for-agent

- [ ] Before writing the pattern matchers below: run each engine (`pi`, `claude`, `codex`, `agy`) live, deliberately provoke a permission prompt and a clarification question, and capture the literal on-screen text — no existing source (including firstmate) has this, since it is specific to each CLI's own rendering.
- [ ] The runner classifies a detected permission prompt as `status.json`'s `prompt_type: "permission"`, and a clarification/authority question as `"authority"`.
- [ ] After executing an `interrupt` control command, the runner sends the equivalent of `Ctrl+U` to the subagent's pane before delivering the next command, so partially-typed/cancelled text never concatenates with what comes next.
- [ ] A brief settle delay is applied before writing prompt text to a subagent's stdin, so keystrokes don't collide with the target CLI's own startup/initialization output.
- [ ] Tests run against captured real prompt text (fixtures from the live capture above) plus a mocked TTY stream, covering: correct classification of both prompt types per engine, and buffer-clear behavior verified via `zellij action write-chars`/`dump-screen` against a mocked pane.
