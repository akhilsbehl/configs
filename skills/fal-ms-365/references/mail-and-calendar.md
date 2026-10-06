# Mail and calendar

All operations here use COM. Folder defaults to `Inbox`; exact nested paths use `/` or `\`. `store` can select a unique store display name. No implicit all-mailbox recursion.

## Read and search

`mail/list`: `folder`, `unreadOnly`, `limit` (1–100, default 25), `offset`. It includes non-mail unread objects. Results include `entryId` and `storeId`; retain both for later targeting. The mailbox can change between pages; counts are snapshots, not a transactional scan.

`mail/search`: same fields plus `query`. Subject-only local-view search. Returned search terms use Outlook DASL LIKE semantics; `%` and `_` can behave as wildcards. Read candidate IDs for body evidence. Do not promise full-text or exhaustive server results. Folder sort by ReceivedTime may fail for unsupported folder types: surface the error.

`mail/read`: `entryId`, optional `storeId`. Returns body and attachment names without opening an inspector or marking read. A quoted prior email is not the original sent item; label it.

`mail/export`: same ID fields, `name` (default `email`), `outputDir` (default `/tmp`), `includeAttachments` (default true). HTML only; see export reference.

## Authorised writes

- `mail/send`: `to` array, `subject`, optional `body`, `cc`, `attachments` (absolute Linux paths), `approved: true`. Text body. Recipients must resolve. No automatic signatures or hidden recipients.
- `mail/save-draft`: same shape, requires authorisation to save. Otherwise draft text locally without calling this action.
- `mail/mark-read`: `entryIds` array, optional `storeId`, approval. Resolve every target before writing; a later failure can still leave partial changes.
- `mail/move`: `entryId`, `storeId`, `destinationFolder`, optional destination `store`, approval. Moving can change EntryID; use returned ID.

No delete, reply-thread preservation, HTML send, or automated VIP classification module. To draft a response, read context and prepare text. Do not represent a new composed message as a native reply.

## Calendar

`calendar/list`: explicit local `start` and `end` (ISO recommended), `limit`, `offset`. Returns overlapping appointments and recurring occurrences; bounded iteration avoids infinite recurring collections. Local dates and timezone are returned, not inferred server state.

`calendar/create-invite`: `subject`, exact local `start` in `yyyy-MM-ddTHH:mm:ss`, `durationMinutes` (1–1440), `timezone` equal to the Windows timezone ID, `attendees` array, optional `body` and `location`, approval. Run sync-status to inspect the timezone when needed. Resolve “tomorrow” before building JSON. Reject ambiguous/invalid DST times. Outlook saves the organiser's calendar entry and submits the invite; recipients and web calendar may behave differently.

This does not create a Teams join link. Calendar updates, cancellation and availability lookup are future work. Do not work around them by deleting or resending.
