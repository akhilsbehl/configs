# Sandcastle workflow template

This directory is the copyable workflow used by the Sandcastle setup skill.
It replaces the vendor's `parallel-planner-with-review` orchestration.

## Install

From a project after `sandcastle init`:

```bash
cp <this-directory>/main.mts .sandcastle/main.mts
cp <this-directory>/scrun ./scrun
cp <this-directory>/*-prompt.md .sandcastle/
cp <this-directory>/Containerfile.github .sandcastle/Containerfile
cp <this-directory>/sandcastle.gitignore .sandcastle/.gitignore
cp <this-directory>/scbuild ./scbuild
chmod u+x scrun scbuild
```

`main.mts`, `scrun`, and the prompts form one protocol. Copy them as a set.
The template uses GitHub CLI commands. For Gitea/Forgejo or GitLab, apply the
corresponding adapter in `../issue-tracker-migration.md` to every tracker
command, the image CLI, and the runtime authentication hook. Do not mix
tracker command sets.

## Workflow contract

- Planner input is mechanically acquired and filtered to open issues carrying
  the `Sandcastle` label. Planner output is authority-checked by ID, title, and
  deterministic `sandcastle/issue-<ID>` branch.
- Issue pipelines run in batches of up to eight. Each issue has one shared
  explicit worktree for implementer and reviewer.
- Each issue gets up to four implement⇄review rounds: 64 implementer and 16
  reviewer iterations per round.
- The reviewer reports all established blocking findings in one comment and
  emits an approval marker plus a final `READY-FOR-MERGER-AGENT` comment only
  when the branch is ready.
- The merger handles approved branches sequentially. The script checks merge
  receipts, target-branch ancestry, issue state, and verification before it
  closes an issue.
- The script owns labels, bookkeeping, and circuit breakers. The merger may
  close only after its per-branch verification receipt; the script remains the
  final postcondition authority. On human escalation the script adds
  `ready-for-human` and removes `Sandcastle`.

Do not change marker formats or make prose a substitute for a mechanical gate.

## Revision Log

- 2026-08-24: Added the copyable gated workflow used by the setup skill.
