# Subagent Dispatch Principles

While a child is running, the primary may prepare dependencies, clarify scope, or perform non-overlapping work, and additional delegations.
It must not independently solve the child’s assigned subproblem. After completion, the primary may verify, integrate, and resolve gaps.

## Roster

| Agent | Role | Context |
|---|---|---|
| `saaqi` | Quick second opinion on direction | fork |
| `saarthi` | Deep challenge: assumptions, drift, risk | fork |
| `tanuki` | Fast cheap chores | fresh |
| `kitsune` | General executor for delegated work requiring ordinary judgement and/or short-range tasks | fresh |
| `oni` | General executor for delegated work that is difficult and/or medium-range tasks | fresh |
| `akuma` | General executor for delegated work that is exceptionally difficult and/or long-range tasks | fresh |
| `codex` | Anything I ask to be run with codex | fresh |
| `sonnet` | Anything I ask to be run with sonnet | fresh |
| `opus` | Anything I ask to be run with opus | fresh |
| `fable` | Anything I ask to be run with fable | fresh |


## When to invoke a tanuki

Use freely & frequently:
- Listing, searching, summarizing, synthesizing files for simple operations
- Documentation, labeling, and classification
- Simple git tracker operations, creating listings, adding labels etc.
- Simple atomic bash-fu
- Mechanical transforms: format conversion, table extraction, boilerplate scaffolding
- First-pass triage of long documents/logs: extract the sections worth a human or a bigger agent
- Search / read a webpage and provide an answer to a bounded question.
  - Launch several tanukis in parallel for research on mece questions and synthesize their findings.

## How to determine difficulty

Score each task on four axes:


| Axis | Low | Medium | High |
|---|---|---|---|
| **Scope** | One file, one answer | Multi-file or multi-document | Cross-repo, cross-system, multi-stakeholder |
| **Ambiguity** | Acceptance criteria given | Some judgment needed | Design decisions, unclear goals, taste calls |
| **Blast radius** | Read-only or trivially reversible | Mutates deliverables | Client-facing, financial, hard to undo |
| **Horizon** | Minutes | Under an hour | Hours-to-days; needs checkpoints or missions |


### Tier mapping:

- **kitsune** — most axes low with some medium; ordinary delegated work requiring judgment or edits.
- **oni** — most axes medium with some high. Multi-source synthesis, deck/report builds with structure decisions, refactors, integrations.
- **akuma** — most axes high (confirm first). Client strategy deliverables, large migrations, ambiguous multi-day builds.

When two tiers seem plausible, start at the lower one; escalate on evidence, not vibes.

## When to invoke saaqi or saarthi

- When I explicitly ask.
- When you feel the need: propose a second opinion (don't invoke yourself).
- Default split: saaqi when speed matters and the question is narrow; saarthi when being wrong is costly or the failure mode is subtle.

### Triggers:

  - We are stuck in some debug or implementation loop (two failed fix attempts on the same problem).
  - A direction decision with material tradeoffs is about to be committed (architecture, scope, vendor/tooling choice).
  - Work has drifted from the stated goal, or subagent results contradict each other.
  - The deliverable is client-facing or carries reputational, financial, or compliance risk.

## Confirm with me before invoking akuma or saarthi

- A direct request to invoke akuma or saarthi counts as confirmation.
- Otherwise, ask before invoking them, with no exceptions, including fanout children.

## How to share context

- The subagents automatically inherit all global and project instructions, extensions, skills, prompts. DRY.
- Task prompts must be self-contained: goal, constraints, definition of done.

### History injection

- Automatic: `saaqi` and `saarthi` get a full copy of the current context by default.
- Primary: Inject a synthesized context into the task prompt.
- Secondary: If the subagent will benefit from partial verbatim context history:
  - Copy the smallest relevant chunk of your session log in ~/.pi/agent/session/**.jsonl to /tmp.
  - Point the subagent to this file with instructions to read it first.

## Codex & Claude Subagents

Claude & Codex are not subagents native to pi and behave differently.
You will not be able to modify them or adjust their models or thinking levels.
They also only provide a one shot interface - no steering or followup available.

### When to invoke codex
- When I explicitly ask for it
- When I ask you to check my outlook inbox, outlook calendar, or teams messages

### When to invoke sonnet, opus, or fable
- When I explicitly ask for `sonnet`, `opus`, or `fable`.
- When I ask for a second opinion from opus or fable:
  - Copy the smallest relevant chunk of the session log in ~/.pi/agent/session/**.jsonl to /tmp.
  - Point the subagent to this file with instructions to read it first.
