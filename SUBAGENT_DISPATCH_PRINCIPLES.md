# Subagent Dispatch Policy

## Guardrails

- Dispatch a self-contained task with a clear outcome, scope, constraints, and definition of done.
- While a child runs, the primary may prepare dependencies or do non-overlapping work, but must not independently solve the child’s assigned subproblem. Afterward, the primary may verify, integrate, and close gaps.
- State explicitly what the child must do and must not do, including unnecessary reviews, tests, fixes, or follow-up work.

## Roster
| Agent | Default use / tier | Context |
|---|---|---|
| saaqi | Quick, narrow second opinion | fork |
| saarthi | Deep challenge of assumptions, drift, and risk | fork |
| tanuki | Fast, bounded, low-risk chores, file operations, formatting, or websearch | fresh |
| kitsune | Short range low complexity work | fresh |
| oni | Short range high complexity work | fresh |
| rasetsu | Medium to long range multi-step low compexlity work | fresh |
| akuma | Medium to long range multi-step high complexity work range | fresh |
| kyubi | Highly difficult and long range work | fresh |
| tatsu | Exceptionally difficult long range work | fresh |
| codex | Requested Codex-engine execution (including requested mailbox/calendar/Teams work) | fresh |
| sonnet | Requested Sonnet-engine execution | fresh |
| opus | Requested Opus-engine execution | fresh |
| fable | Requested Fable-engine execution | fresh |

`fork` shares all current parent session history; `fresh` starts the child with only the context you provide.

## Routing and gates

Assess scope, ambiguity, blast radius, and horizon.
Choose the lowest safe execution tier. Escalate when evidence—not intuition—shows the task is harder.
Confirm with me first before invoking any of these: akuma, kyubi, tatsu, opus, fable, saarthi. Skip confirmation when I explicitly asked for one by name.

## Context management

- Task prompts must be self-contained.
- The subagents automatically inherit all global and project instructions, extensions, skills, prompts. DRY.
- Prefer pointing to existing skills, tools, extensions, and file paths in the subagent prompt instead of detailing everything in their prompts.
