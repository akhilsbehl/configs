# Subagent Dispatch Principles

## Roster

| Agent | Role | Context |
|---|---|---|
| `kohai` | General executor; default for delegated work and/or short-range | fresh |
| `oni` | General executor for delegated work that is difficult and/or medium-range | fresh |
| `akuma` | General executor for delegated work that is exceptionally difficult and/or long-range | fresh |
| `minion` | Fast recon, file searches, quick summaries, rote operations and handoff briefs | fresh |
| `saaqi` | Quick second opinion on direction | fork |
| `saarthi` | Deep challenge: assumptions, drift, risk | fork |


## When to invoke a minion

Use aggressively & concurrently but batch operations where reasonable:
- Listing & searching files
- Quick documentation, simple summarization, labeling, classification
- Creating tickets
- Quick throwaway cmdline-fu
- Mechanical transforms: format conversion, table extraction, boilerplate scaffolding
- Drafting handoff briefs and context packets consumed by a stronger agent
- First-pass triage of long documents/logs: extract the sections worth a human or a bigger agent

## How to determine difficulty

Score each task on four axes:

| Axis | Low | Medium | High |
|---|---|---|---|
| **Scope** | One file, one answer | Multi-file or multi-document | Cross-repo, cross-system, multi-stakeholder |
| **Ambiguity** | Acceptance criteria given | Some judgment needed | Design decisions, unclear goals, taste calls |
| **Blast radius** | Read-only or trivially reversible | Mutates deliverables | Client-facing, financial, hard to undo |
| **Horizon** | Minutes | Under an hour | Hours-to-days; needs checkpoints or missions |

Tier mapping:
- **kohai** — most axes low with some medium. Research summaries, doc drafting, single-file edits, standard analyses.
- **oni** — most axes medium with some high. Multi-source synthesis, deck/report builds with structure decisions, refactors, integrations.
- **akuma** — most axes high (confirm first). Client strategy deliverables, large migrations, ambiguous multi-day builds.

When two tiers seem plausible, start at the lower one; escalate on evidence, not vibes.

## When to invoke saaqi or saarthi

- When I explicitly ask.
- Otherwise, propose a second opinion (don't invoke yourself). Default split: saaqi when speed matters and the question is narrow; saarthi when being wrong is costly or the failure mode is subtle. Triggers:
  - We are stuck in some debug or implementation loop (two failed fix attempts on the same problem).
  - A direction decision with material tradeoffs is about to be committed (architecture, scope, vendor/tooling choice).
  - Work has drifted from the stated goal, or subagent results contradict each other.
  - The deliverable is client-facing or carries reputational, financial, or compliance risk.

## Confirm with me before invoking akuma or saarthi
- No exceptions, including fanout children

## How to share context

- The subagents automatically inherit my global and project instructions. DRY.
- Task prompts must be self-contained: goal, constraints, definition of done. Only saaqi and saarthi get a copy of the current context.
- **History dependency**: If you think that the subagent will benefit from partial context history, copy the smallest relevant chunk of your session log in ~/.pi/agent/session/**.jsonl to /tmp and point the subagent to the file with instructions to read it first.

## Choosing thinking levels

Good defaults are set for thinking levels based on model choices and task types.
However, feel free to over-ride thinking levels up or down depending on task complexity.
Prefer to adjust thinking effort higher with a lower capability subagent (e.g. kohai with high thinking) before going for a stronger subagent (e.g. oni) first.
