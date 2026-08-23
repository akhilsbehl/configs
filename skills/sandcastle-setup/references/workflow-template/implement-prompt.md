# SKILLS

The following skills are mounted at `~/.pi/agent/skills/`. Read the relevant
`SKILL.md` before acting and follow it where applicable:

- `implement` — implementation workflow and delivery discipline.
- `tdd` — use for red-green-refactor when the task has a suitable test seam.
- `diagnosing-bugs` — use when the issue reports a bug, failure, or regression.
- `improve-codebase-architecture` — use when the task is an architectural or
  design improvement.
- `resolving-merge-conflicts` — use only if Git reports an active conflict.

Use only the skills relevant to this task. Read `CONTEXT.md` and relevant ADRs
before changing domain concepts or architectural decisions.

# TASK

Fix issue {{TASK_ID}}: {{ISSUE_TITLE}}

This is round {{ROUND}} of up to {{ROUND_COUNT}} implement⇄review rounds for
this issue. Orchestrator run: {{RUN_ID}}.

Pull in the issue using `gh issue view {{TASK_ID}}`. If it has a parent PRD,
pull that in too. **Read the issue's full comment history first** — it contains
your previous round reports and the reviewer's findings. If the last review
verdict was REJECTED-FOR-MERGER, your task this round is precisely to satisfy
the PASS CONDITIONS in that review. Only work on the issue specified.

Work on branch {{BRANCH}}. Make commits and run tests.

# CONTEXT

Here are the last 10 commits:

<recent-commits>

!`git log -n 10 --format="%H%n%ad%n%B---" --date=short`

</recent-commits>

# EXPLORATION

Explore the repo and fill your context window with relevant information that will allow you to complete the task.

Pay extra attention to test files that touch the relevant parts of the code.

# EXECUTION

Use RGR only when this issue has a meaningful automated-test seam. For
configuration, documentation, or other non-testable work, verify the relevant
acceptance criteria directly instead of inventing tests.

When RGR applies:

1. RED: write one test
2. GREEN: write the implementation to pass that test
3. REPEAT until done
4. REFACTOR the code

# FEEDBACK LOOPS

Discover the project's verification machinery from repo convention
(`AGENTS.md`, `package.json`, Makefile, CI config). Run the applicable
typecheck, test, lint, build, or equivalent commands before committing. If no
conventional automated verification command exists, say so explicitly in the
round report; do not invent a command or claim tests passed.

# COMMIT

Make a git commit. The commit message must:

1. Start with `RALPH:` prefix
2. Include task completed + PRD reference
3. Key decisions made
4. Files changed
5. Blockers or notes for next iteration

Keep it concise.

# REPORT

Post ONE comment on issue {{TASK_ID}} describing what was done this round and
what was deliberately skipped or deferred. Include this exact machine-readable
line in that comment:

SANDCASTLE-IMPLEMENTATION-ROUND: {{RUN_ID}}:{{ROUND}}

This comment is how the next round (and any future session) picks up where you
left off.

Do NOT close the issue, post an approval token, or run `git push`. Sandcastle
synchronises local commits from the worktree; remote pushing is not part of this
workflow and must never become a blocker.

Once complete, output `<promise>COMPLETE</promise>` immediately.

# FINAL RULES

ONLY WORK ON A SINGLE TASK.
