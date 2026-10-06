# Directory, files and Teams

## Directory

Graph `directory/search` takes `name`, uses displayName/givenName prefix matching and returns one page plus `nextLink`. This is not fuzzy matching. Exact original CLI parity is pending. `directory/profile` takes `identity` (Graph user ID or UPN) and optional `relationships: true`; manager is attempted, direct reports and memberships return their own pages. `directory/page` takes a returned Graph `nextLink`.

COM `directory/profile` takes `backend: "com"`, `identity` (resolvable name/address) and optional `relationships`. Returns Outlook's directory fields, manager and visible reports/memberships. A membership name does not prove current application usage or permissions. Missing fields are not guessed. Do not recursively expand the organisation or hidden/nested groups without a request.

## Files

`files/search` takes Graph Search KQL `query`, `limit`, `offset`. Example:

```text
"AI Governance" (filetype:pptx OR filetype:ppt OR filetype:pdf)
```

This searches indexed names/content across accessible supported OneDrive/SharePoint files, not every byte of every file. Results can contain generic decks that merely mention the phrase. Rank, date and title are search evidence, not a review of slides. Repeat with the next offset while `moreAvailable` and disclose when you stop.

`files/metadata` or `files/download` accepts either `link` OR both `driveId` and `itemId`. Search results provide these IDs. Download optionally takes `name` and `outputDir`; folders are not downloaded recursively. The existing sharing-link approach is preserved, including Graph preauthenticated URLs or the content endpoint. Do not log preauthenticated URLs.

## Teams

- `teams/joined`: existing cached scopes, returns one page. Successful membership listing does not prove message access.
- `teams/channels`: `teamId`; needs `Channel.ReadBasic.All` (not among the four originally requested message scopes).
- `teams/chats`: needs `Chat.Read`.
- `teams/chat-messages`: `chatId`, `limit`; needs `Chat.Read`.
- `teams/channel-messages`: `teamId`, `channelId`, `limit`; needs `ChannelMessage.Read.All`. Root posts only.
- `teams/channel-replies`: same IDs plus `messageId`; reads replies separately.
- `teams/page`: returned `nextLink`; chooses the matching read scope.
- `teams/send-chat`: exact `chatId`, plain-text `body`, approval; `ChatMessage.Send`.
- `teams/send-channel`: exact `teamId`, `channelId`, plain-text `body`, approval; `ChannelMessage.Send`.

Do not pick a similarly named chat/channel for a write. Verify exact destination before approval. Chat creation, search across all chats and send-to-new-recipient are not implemented. No application-only message sending workaround or browser fallback. New scopes may trigger a silent-auth failure until consent/login is refreshed; stop on that failure.
