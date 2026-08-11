# 07 — Multi-engine adapters (claude, codex, agy)

**What to build:** A subagent can be launched on any of the four engines, each with its arguments correctly translated to that engine's native CLI, and with a safe, honest fallback for engines that don't have a reliable busy/idle signal.

**Blocked by:** 01 — Launch a subagent to a Zellij tab and see it run to completion; 02 — List subagents and classify liveness/busy state.

**Status:** ready-for-agent

- [ ] Before finalizing the `agy` adapter: live smoke-test the real `agy` binary to confirm the exact argument-passing shape (positional prompt vs. flag value) for `--print`/`-p`/`--prompt` — these were previously assumed to be distinct flags and are actually aliases of one flag.
- [ ] Generic launch arguments (`model`, `thinking`/`effort`, `systemPrompt`, `context`) translate correctly to each engine's native flags: `claude` (`--model`, `--system-prompt`), `codex` (`-m`/`--model`, `-c`/`--config`), `agy` (`--model`, `--effort`).
- [ ] A requested `effort` value outside an engine's accepted set (e.g. `agy` only accepts `low`/`medium`/`high`) is recorded in launch metadata but the flag is omitted from the actual launch command — the launch still succeeds.
- [ ] `codex` and `agy` subagents classify as `unknown` busy-state (never a guessed `busy`/`idle`) until a concrete signal is empirically verified against a real launch — no rendered-text heuristic is used as a stopgap.
- [ ] The subagent's system prompt includes the authority rule: elevate authority/ask-user decisions back to the primary driver rather than making unauthorized assumptions or faking user approval.
- [ ] Tests run as pure-function unit tests per engine (flag translation), plus the live `agy` smoke test's findings encoded as fixtures.
