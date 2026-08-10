# 01 — Engine Argument Adapters, Authority Rules & Declarative Dispatch

**What to build:** Pure function engine argument translation for `pi`, `claude`, `codex`, and `agy`, dynamic binary PATH lookup (`which pi`, `claude`, `codex`, `agy`), system prompt authority boundary injection, and declarative dispatch rules (`crew-dispatch.json` / `subagents-dispatch.json`).

**Blocked by:** None — can start immediately

**Status:** ready-for-agent

- [ ] `buildEngineArgs` translates generic launch options (`model`, `thinking`, `systemPrompt`, `prompt`, `rawArgs`) to native CLI flags for `pi`, `claude`, `codex`, and `agy`
- [ ] Injects system prompt authority guidelines enforcing that subagents elevate authority/ask-user decisions back to the primary driver instead of making unauthorized assumptions or faking approvals
- [ ] Implement declarative dispatch resolver (`resolveDispatchRules`) that reads `subagents-dispatch.json` / `crew-dispatch.json` and maps task rules/types to engine, model, and thinking effort defaults
- [ ] Dynamically checks binary existence in system PATH and throws clear error if target CLI binary is missing
- [ ] Supports raw argument pass-through overrides for custom CLI flags
- [ ] 100% unit test coverage for argument translation, authority prompt injection, and dispatch rule resolution across all 4 engines
