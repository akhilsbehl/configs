# Permissions and capability checks

## Current state

As observed on 6 October 2026, the existing delegated token included `User.Read`, `User.ReadBasic.All`, `User.Read.All`, `Files.Read.All`, `Sites.Read.All`, plus identity scopes. Joined-Team listing and indexed file search worked. Chat listing returned 403. This is historical evidence, not a promise about a future token.

The draft preserves existing scope acquisition for directory/files and joined-Team probes. Specific Teams actions request their named delegated scopes silently. No application permissions, client secret, admin role assignment or automatic consent workflow.

## Teams scope map

| Capability | Scope used by template | State |
|---|---|---|
| List chats, read chat messages | `Chat.Read` | Requested; not yet live-verified |
| Send to an existing chat | `ChatMessage.Send` | Requested; not yet live-verified |
| List channel messages/replies | `ChannelMessage.Read.All` | Requested; not yet live-verified |
| Send channel posts | `ChannelMessage.Send` | Requested; not yet live-verified |
| Discover channel names/IDs | `Channel.ReadBasic.All` | Additional optional scope; not included in earlier request |

`Chat.ReadBasic` is enough for basic chat listing, but the bundle uses `Chat.Read` to support message reading as well. Channel discovery needs a distinct scope; do not assume message scopes allow it. Teams chat/message page size is capped at 50 in the draft.

Delegated `ChannelMessage.Read.All` requires administrator consent. The other three originally requested message scopes do not inherently require administrator consent, but tenant policy can still require IT approval. The full consent flags should be rechecked in Microsoft's permissions reference before a new approval request. Consent authorises an app; it does not grant the user an administrator role or access to channels they cannot see.

## Official references

Endpoint permission tables consulted on 6 October 2026:

- [List chats](https://learn.microsoft.com/en-us/graph/api/chat-list?view=graph-rest-1.0): `Chat.ReadBasic`, `Chat.Read`, `Chat.ReadWrite`; maximum `$top=50`.
- [List channels](https://learn.microsoft.com/en-us/graph/api/channel-list?view=graph-rest-1.0): least-privileged delegated scope `Channel.ReadBasic.All`; private/shared channel visibility is membership-dependent.
- [List channel messages](https://learn.microsoft.com/en-us/graph/api/channel-list-messages?view=graph-rest-1.0): delegated `ChannelMessage.Read.All`; roots without replies by default; maximum `$top=50`.
- [Search query](https://learn.microsoft.com/en-us/graph/api/search-query?view=graph-rest-1.0): scopes depend on requested entity type; existing file/site-read access passed the file search live test.

Further endpoint references (links supplied for implementation review, not all re-read during this draft):

- [Chat messages](https://learn.microsoft.com/en-us/graph/api/chat-list-messages?view=graph-rest-1.0)
- [Send chat message](https://learn.microsoft.com/en-us/graph/api/chat-post-messages?view=graph-rest-1.0)
- [Send channel message](https://learn.microsoft.com/en-us/graph/api/channel-post-messages?view=graph-rest-1.0)
- [List replies](https://learn.microsoft.com/en-us/graph/api/chatmessage-list-replies?view=graph-rest-1.0)
- [Sharing-link drive item](https://learn.microsoft.com/en-us/graph/api/shares-get?view=graph-rest-1.0)
- [Permissions reference](https://learn.microsoft.com/en-us/graph/permissions-reference)

## Diagnostics

`diagnose/graph-capabilities` uses the existing token to probe joined Teams and chat listing without dumping tokens or message bodies. Each endpoint reports pass/fail and HTTP status. A 401 stops the operation; 403 establishes denied endpoint access, not the cause by itself. Silent auth failure must stop without retry. New-scope actions might require refreshed login after IT consent.

No mail/calendar Graph scopes are required for COM. Read-only COM access still depends on Outlook security and company policy. No changes to scopes or app settings are made by this bundle.
