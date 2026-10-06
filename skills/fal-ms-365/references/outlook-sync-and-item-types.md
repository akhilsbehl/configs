# Outlook sync and item types

## Diagnosis

`diagnose/installation` inspects AppX packages, classic executable registration, running processes and COM registration. It does not launch Outlook or prove mailbox access.

`diagnose/sync-status` attaches and reports connection mode, offline state, Windows timezone, basic folder counts and recent sync-log subjects/times. Empty diagnostic folders do not establish healthy or completed sync.

`diagnose/sync` requires `approved: true` after the user requests sync. It calls SendAndReceive(false), then returns a snapshot. This is NOT the UI's folder-specific Update Folder command or Show Progress window. It does not wait for completion or poll.

Initial mailbox cache download may take time. There is no supported guarantee that it takes 30 minutes. If local folders disagree with a web view, label that discrepancy and ask the user before changing cached-mode settings, profiles or accounts. No profile rebuild in this bundle.

## Item types

Outlook `Class=43` is mail. `Class=53` is a meeting request. Calendar appointments are `Class=26`. Other meeting response/report classes exist. Unread counts must include all returned unread items, not just Class 43. HTML mail export intentionally rejects other types rather than silently omitting them.

Do not display an item merely to read it; inspector/reading-pane actions can mark it read. COM access can fail despite registration (e.g. `0x80080005` server execution failure). Ask the user to open classic Outlook and resolve startup prompts. Do not auto-launch, restart or terminate it.
