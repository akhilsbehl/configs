# 12 — Declarative dispatch config (`crew-dispatch.json`)

**What to build:** The driver can launch a subagent by describing the kind of task it is, and get a sensible default engine/model/effort — while still being able to override any of it explicitly.

**Blocked by:** 01 — Launch a subagent to a Zellij tab and see it run to completion; 07 — Multi-engine adapters (claude, codex, agy).

**Status:** ready-for-agent

- [ ] A configurable rule file (`crew-dispatch.json`/`subagents-dispatch.json`) matches task-type descriptions to default engine/model/effort.
- [ ] `subagents_launch` resolves a matching rule when a task-type is given instead of explicit engine/model/effort parameters.
- [ ] Any explicit parameter passed to `subagents_launch` overrides the corresponding value from a matched rule.
- [ ] No matching rule found falls back to a sensible documented default rather than erroring.
- [ ] Tests run against fixture dispatch-config files, covering: rule match with no override, rule match with partial override, no rule match (default fallback).
