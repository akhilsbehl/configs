---
name: richie
description: Always consult before using the richie command.
---

# Use Richie

Richie is the human review gate. Keep the source Markdown canonical. Apply only feedback the user authorises.

## Open and wait

1. Choose the Markdown file:
   - Put transient communication in `~/.richie/ephemeral/`.
   - Put durable work in the appropriate project path.
   - Before opening it, check `<original-file-path>-commented.md` for feedback from an earlier review. Apply authorised feedback to the canonical source, then delete the commented file.
2. Run `richie review --json <file>`. Retain the returned session ID. For multiple files, open and track one session per file.
3. Run `richie poll <session-id>` for each live session. Do not repeat the Markdown content in chat while Richie is carrying it.
4. Handle the terminal result:
   - `finished`: read the returned Markdown path. If it is a commented review file, apply authorised feedback to the canonical source and delete the commented file. If it is the source path, no feedback was recorded.
   - `aborted`: stop. Keep the source unchanged.

## Session lifecycle

- An interrupted poll stops only that wait. Resume with `richie poll <same-session-id>` while the session remains alive.
- Closing the browser tab is not terminal. The poll remains pending until the user finishes or aborts.
- Browser reload keeps the same session and poll.
- If the source changes during review, Finish remains non-terminal and polling continues. The user may confirm **Reload new draft**; this keeps the session ID, loads the current source, clears prior review operations, and leaves the poll pending.
- Never substitute a file path for a session ID or reuse one file's session ID for another file.
