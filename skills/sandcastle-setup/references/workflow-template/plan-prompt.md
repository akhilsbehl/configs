# SKILLS

The following skills are mounted at `~/.pi/agent/skills/`. Read the relevant
`SKILL.md` before acting and follow it where applicable:

- `triage` — issue intake, labels, and readiness.
- `codebase-design` — dependency and module-boundary reasoning.

Use only the skills relevant to this planning task. Do not invent issue or
triage facts that are not present in the issue data.

# ISSUES

The following open issues are ready for work. The list has already been
filtered by the orchestrator — everything here is workable; do not exclude
any of it yourself:

<issues-json>

{{ISSUES_JSON}}

</issues-json>

# TASK

Analyze these issues and build a dependency graph. For each issue, determine whether it **blocks** or **is blocked by** any other issue in the list.

An issue B is **blocked by** issue A if:

- B requires code or infrastructure that A introduces
- B and A modify overlapping files or modules, making concurrent work likely to produce merge conflicts
- B's requirements depend on a decision or API shape that A will establish

An issue is **unblocked** if it has zero blocking dependencies on other issues in the list.

For each unblocked issue, keep its branch name exactly as given (format `sandcastle/issue-{id}`, no slug or other suffix). This must be deterministic so that re-planning the same issue always produces the same branch name and accumulated progress is preserved.

Emit issues in dependency-safe order — an issue that others depend on comes first.

# OUTPUT

Output your plan as a JSON object wrapped in `<plan>` tags:

<plan>
{"issues": [{"id": "42", "title": "Fix auth bug", "branch": "sandcastle/issue-42"}]}
</plan>

Include only unblocked issues. If every issue is blocked, include the single highest-priority candidate (the one with the fewest or weakest dependencies).

Always emit the `<plan>` tags, even when there is nothing to do. If there are no issues to work on at all, output `<plan>{"issues": []}</plan>` so the run can exit cleanly.
