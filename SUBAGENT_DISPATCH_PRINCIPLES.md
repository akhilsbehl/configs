# Subagent Dispatch Policy

## Guardrails

- Dispatch a self-contained task with a clear outcome, scope, constraints, and definition of done.
- While a child runs, the primary may prepare dependencies or do non-overlapping work, but must not independently solve the child’s assigned subproblem. Afterward, the primary may verify, integrate, and close gaps.
- Write subagent prompts using the `~/configs/pi/prompts/task-form.md` template.
  - Make sure that the agent is clear on un-necessary and harmful things not to do.

## Roster

| Tier | Agent | Default use / tier | Context |
|---|---|---|---|
| A1 | saaqi | Default for getting a second opinion on things | fresh |
| A2 | wazeer | More detailed and considered second opinion | fresh |
| A3 | saarthi | Deep challenge of assumptions, drift, and risk | fresh |
| S1 | tanuki | Fast, bounded, low-risk chores, file operations, formatting, or websearch | fresh |
| S2 | kitsune | Short range low complexity work | fresh |
| S3 | oni | Short range high complexity work | fresh |
| S4 | rasetsu | Medium to long range multi-step low complexity work | fresh |
| S5 | akuma | Medium to long range multi-step high complexity work range | fresh |
| S6 | kyubi | Highly difficult and long range work | fresh |
| S7 | tatsu | Exceptionally difficult long range work | fresh |
| Engine | codex | Requested Codex-engine execution (including requested mailbox/calendar/Teams work) | fresh |
| Utility | scribe | Summarize current parent context to prepare handoff files for subagents | fork |

`fork` shares all current parent session history; `fresh` starts the child with only the context you provide.

## Nesting & Spawning Rules

### Must not spawn their own children subagents.
- **Advisors (A1-A3):** `saaqi` (A1), `wazeer` (A2), `saarthi` (A3)
- **Utility:** `scribe`
- **Engines:** `codex`
### Allowe to spawn children subagents within bounds
- **Task subagents (S1–S7):** - `tanuki` (S1), `kitsune` (S2), `oni` (S3), `rasetsu` (S4), `akuma` (S5), `kyubi` (S6), `tatsu` (S7).
- **Strict Descending Nesting:** An agent at level $S_n$ can only spawn subagents up to level $S_{n-1}$
  - E.g., $S_3$ can spawn $S_1$ or $S_2$, but not $S_3$ or above.

## Routing and gates

For Task subagents:
- Assess scope, ambiguity, blast radius, and horizon.
- Choose the lowest safe execution tier. Escalate when evidence—not intuition—shows the task is harder.
- Confirm with me first before invoking any of these: kyubi, tatsu, saarthi. Skip confirmation when I explicitly asked for one by name.

## Context sharing with subagents

- The subagents automatically inherit all global and project instructions, extensions, skills, prompts. DRY.
- When relevant context sharing is required before dispatch (necessary for advisors and sometimes useful for executors), first invoke `scribe` (`fork`s full context) along with the task brief to capture & write out the parts of the context relevant into /tmp.
  - Share the context writeout filepath from /tmp with the subagents.
