# fal-ms-365 — draft bundle

One skill, two interfaces: classic Outlook COM for mail/calendar and Microsoft Graph for files, directory and Teams. See [SKILL.md](SKILL.md) for operating instructions and [references/migration.md](references/migration.md) before activation.

## Quick start

```bash
bash scripts/run.sh /absolute/path/request.json
```

Adapt one file in `examples/`. Scripts produce structured JSON; write guards are not substitutes for explicit user approval. No dependencies are installed; existing Graph authentication is reused silently. No browser fallback or automatic Outlook startup.

## Validation

```bash
bash tests/run.sh
```

Offline fixture tests only. They do not connect to Outlook/Graph or send messages. Read [TEST_REPORT.md](TEST_REPORT.md) for separately performed read-only smoke tests and known gaps.

## Draft boundaries

Not activated and not a drop-in CLI replacement. Mail/calendar writes and newly scoped Teams actions are implemented templates but have not been live-tested by this bundle. No calendar update/cancel, delete, Teams full-text search or automatic inbox-classification policy. The original `query-ms-graph` skill and CLI remain unchanged.

## Revision Log

- 6 October 2026: created draft bundle after design review. Generalised tasks, selected COM-first mail/calendar, removed browser fallback, and added templates/references and safe read-only validation.
