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

`calendar/list`: explicit local `start` and `end` (ISO recommended), `limit`, `offset`. Returns overlapping appointments and recurring occurrences; bounded iteration avoids infinite recurring collections. Local dates/timezone plus Outlook response status, recurrence state, GlobalAppointmentID and OriginalDate are returned when exposed by COM. EntryIDs are local Outlook identifiers, not stable cross-store/server identifiers. This is evidence from the local view, not server truth.

`calendar/free-busy`: `recipient`, explicit local `start`/`end` in `yyyy-MM-ddTHH:mm:ss`, `timezone` equal to the Windows timezone ID, optional `minutesPerInterval` (1–1440, default 30). Resolves the recipient and returns Outlook FreeBusy status digits clipped to the requested interval count. This is availability data, not event details or a guarantee of server freshness. Confirm less-common status digits against the tenant/client; no Graph or browser fallback.

`calendar/create-invite`: `subject`, exact local `start` in `yyyy-MM-ddTHH:mm:ss`, `durationMinutes` (1–1440), `timezone` equal to the Windows timezone ID, `attendees` array, optional `body` and `location`, approval. Run sync-status to inspect the timezone when needed. Resolve “tomorrow” before building JSON. Reject ambiguous/invalid DST times. Outlook saves the organiser's calendar entry and submits the invite; recipients and web calendar may behave differently.

`calendar/respond`: `response` (`accept`, `decline`, or `tentative`), `entryId`, optional `storeId`, exact `expectedSubject` and `expectedOrganizer`, local `start`/`end` in `yyyy-MM-ddTHH:mm:ss`, exact Windows `timezone`, and `approved: true`. Approval must expressly cover the response and exact non-recurring meeting. To change an already accepted meeting to declined, the exact authorization must also be represented by `allowAcceptedToDeclinedChange: true` and numeric `expectedPriorResponseStatus: 3`; approval alone does not authorize the override. This override cannot be used for other response changes or statuses. The adapter re-fetches by ID and verifies class, subject, organizer, start/end and received-meeting status; it rejects all recurring items (series masters, occurrences and exceptions). It calls `AppointmentItem.Respond(responseCode, $true, $false)` with OlMeetingResponse values accepted=3, tentative=2, declined=4, then verifies the response item's `Class` is 56 (accept), 57 (tentative), or 55 (decline) and sends the returned MeetingItem with `.Send()`. These classes are distinct from `olMeetingRequest=53`; see Microsoft's [Respond](https://learn.microsoft.com/en-us/office/vba/api/outlook.appointmentitem.respond), [OlMeetingResponse](https://learn.microsoft.com/en-us/office/vba/api/outlook.olmeetingresponse), [OlObjectClass](https://learn.microsoft.com/en-us/office/vba/api/outlook.olobjectclass), and [RecurrencePattern.GetOccurrence](https://learn.microsoft.com/en-us/office/vba/api/outlook.recurrencepattern.getoccurrence) documentation. Recurrence occurrence responses are deliberately unsupported until master/occurrence identity can be safely resolved and verified. On an error after Respond begins, treat outcome as unknown and inspect; never retry blindly. Microsoft notes accepted/tentative Respond may replace the appointment and alter EntryID.

This does not create a Teams join link or edit/cancel calendar events. Do not work around unsupported operations by deleting or resending.
