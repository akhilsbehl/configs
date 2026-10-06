# Routing and capabilities

Generalise user requests; session examples are evidence, not hard-coded workflows.

| Task | Preferred interface | Implemented draft action |
|---|---|---|
| Identify Outlook installation | Windows inspection | diagnose / installation |
| List/search/read inbox, sent items, drafts or snoozed | COM | mail / list, search, read |
| Triage unread items | COM reads + model review | mail / list with unreadOnly; no bundled classification policy |
| Send emails; save drafts; mark read; move items | COM, specific authorisation | mail / send, save-draft, mark-read, move |
| Export email and attachments | COM + verified WSL transfer | mail / export (HTML only) |
| Read calendar; send invitations | COM, authorise invitation | calendar / list, create-invite |
| Verify sends/invitations | COM reads | mail list/search/read + calendar list; no delivery guarantee |
| Inspect sync, request Send/Receive | COM | diagnose / sync-status, sync |
| Search people and read profile/reporting relationships | Graph; COM profile alternative | directory / search, profile, page |
| Search accessible files; resolve links; download | Graph | files / search, metadata, download |
| List joined Teams | Graph | teams / joined |
| Read chats, channels and messages | Graph; appropriate scopes | teams / chats, channels, chat-messages, channel-messages, channel-replies, page |
| Send Teams messages | Graph, specific authorisation | teams / send-chat, send-channel |
| Test existing Graph Teams access | Graph, read-only | diagnose / graph-capabilities |

## Evidence from 6 October 2026

Outlook COM read inbox and directory records; sent messages and a meeting invitation; exported HTML and an attachment. Graph listed joined Teams and searched accessible files. The previous client provides directory lookup and sharing-link download; replacement parity still needs testing. Chat listing with the existing token returned 403. New Teams scopes were requested, not verified.

Initial Outlook cache was incomplete: inbox counts rose from 252 to 2,138 after sync; later Sent Items exposed only three items. Empty Drafts/Snoozed did not match the web view. Calendar server sync was not established. These historical observations must not be treated as current live state.

## Boundaries

No browser fallback. COM is preferred for mail/calendar; no Graph mail/calendar module is bundled. No automatic Outlook startup. Directory read alternatives must be explicit and source-labelled; stop immediately on authentication failure. Surface every failure. Unknown mutations must not be repeated.

No calendar updates/cancellations, deletion, Teams chat creation, cross-chat full-text search, Planner, SharePoint list operations, transcripts, or org reports in this draft. Do not claim these work merely because Graph supports them.
