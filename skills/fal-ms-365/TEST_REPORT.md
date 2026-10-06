# Draft validation — 6 October 2026

## Result

The draft bundle has passed offline tests and live read-only checks. It is **not activated** and does not replace the existing skill or CLI. No live email, calendar or Teams writes were performed while building/testing this bundle.

## Offline validation

Command: `bash tests/run.sh`.

- Bash syntax checks for runner/test runner.
- PowerShell parser checks for every bundled `.ps1` script.
- 10 Node tests: Unicode/quote round-trip, private request permissions, invalid input, example safety, Markdown reference resolution, HTML/asset/attachment transfer, copy hashes, private output permissions, overwrite rejection, traversal and symlink rejection.
- 22 PowerShell fixture assertions: approval guard including wrong boolean type, bounded paging, filename safety, Graph host/HTTPS checks, unread meeting-request inclusion, COM paging, subject-quote escaping, mail/calendar/Teams write blocking, timezone mismatch, Graph continuation/scopes, endpoint page-size cap, file-search IDs/paging and preauthenticated-URL suppression.

Fixtures mock COM/auth/network boundaries. They do not establish successful real sends or newly granted Teams access. An additional end-to-end negative request confirmed the dispatcher rejects an unapproved email send before attaching to Outlook.

## Live read-only smoke tests

Results directory: `/tmp/fal-ms-365-live.yby87bg8` (private temporary directory).

| Check | Observed result |
|---|---|
| Windows Outlook installation diagnostics | Passed: both editions detected, classic COM registered, Outlook running |
| Unread inbox list through COM | Passed: three-item bounded page returned, local-view completeness labelled |
| COM directory profile | Passed: one resolved profile |
| Graph directory name lookup | Passed: one result |
| Graph indexed file search | Passed: three-result bounded page |
| Graph joined-Team listing | Passed: 66 results |
| COM calendar read | Passed: three-item bounded page |

Additional export checks: `/tmp/fal-ms-365-artifacts.6SzczItE`.

- Subject search found the intended single candidate.
- Native Outlook HTML export, companion-assets directory and separate attachment transferred successfully: three verified top-level artifacts.
- Read-state comparison before export and after subsequent read passed; original state unchanged.
- **Graph file metadata check failed with HTTP 423 Locked** for the selected previously found PDF. The download step was not attempted. No retries, browser fallback or permission changes followed. Download implementation remains live-unverified; fixture transfer checks are not a substitute.

The export creates local copies only. Private test request/results and export artifacts are outside the repository.

## Source verification

Official endpoint documentation checked for chat listing, channel discovery, channel message listing and Graph search. Three explicit citation checks passed for the scope/page-limit/root-message claims. Remaining references are supplied for later endpoint review; do not imply every linked endpoint was revalidated.

## Remaining gates

- Consent and live verification of new Teams message scopes. Channel discovery optionally needs `Channel.ReadBasic.All`, not included in the four-scope request already sent.
- User-approved sandbox write tests for sends, saved drafts, marking read, moving messages and invitations. No such approval has been sought or assumed during draft construction.
- Sharing-link and file-download parity with the legacy CLI; one candidate's metadata was locked.
- More calendar fixture coverage for recurring exceptions and DST transitions; only timezone mismatch is currently asserted offline.
- Read-only Graph/COM relationship paging and missing-field edge cases beyond the tested profile/name lookups.
- Activation, skill discovery/reload, and retirement/compatibility handling of the old skill after review.

## Limits

`approved: true` is a defensive guard, not proof of user consent. No durable approval/idempotency journal. Local cache and indexing can be incomplete. No automatic retry or browser fallback. No calendar update/cancellation, mailbox deletion, Teams full-text search, Planner, lists, transcripts, usage reports, To Do or OneNote modules.

## Revision Log

- Created draft and performed offline plus read-only validation. Recorded the locked-file blocker rather than claiming download parity.
