# 04 — Session Context Exporter & Format Adapters

**What to build:** Optional context extraction from Pi's active `.jsonl` session log file (`ctx.sessionFile`), filtering heavy tool outputs, and adapting context payloads for target CLI engines.

**Blocked by:** 01 — Engine Argument Adapters & PATH Resolution

**Status:** ready-for-agent

- [ ] Context sharing is strictly optional (`shareContext?: boolean`, defaults to false)
- [ ] Reads active Pi session `.jsonl` file and filters out raw heavy `toolResult` payloads (file reads, command outputs)
- [ ] Translates conversation turns into engine-specific context payloads (`--system-prompt` for Claude/Pi, prompt text for Codex/Antigravity)
- [ ] Writes exported context snapshot to `/tmp/pi-subagents/<id>/context.jsonl`
