# Issue tracker: Gitea / Forgejo

Issues and specs for this repo live as Gitea or Forgejo issues. Use the `tea` CLI for all operations. This is the Gitea/Forgejo integration; do not use GitHub's native `gh` commands or assume GitHub-only APIs are available.

## Configuration

Set the server and access token in the runtime environment:

```dotenv
GITEA_SERVER_URL=https://gitea.example.com
GITEA_ACCESS_TOKEN=<REDACTED>
```

Authenticate the CLI before tracker operations:

```bash
tea login add --name sandcastle --url "$GITEA_SERVER_URL" \
  --token "$GITEA_ACCESS_TOKEN" --no-version-check 2>/dev/null || true
tea login default sandcastle
```

Never print the access token. Fail setup when either required variable is missing.

## Conventions

- **Create an issue**: `tea issue create --title "..." --body "..."` (confirm the selected `tea` version's flags with `tea --help`).
- **Read an issue**: `tea issue <number> --comments --output json`.
- **List issues**: `tea issues list --state open --labels Sandcastle --fields index,title,body,labels,comments --output json`. Normalize the result to the planner's expected `number`, `title`, `body`, `labels`, and `comments` fields when wiring it into automation.
- **Comment on an issue**: `tea comment <number> "..."`.
- **Apply / remove labels**: use the selected `tea` version's label edit command; create the label with `tea label create --name Sandcastle --color F9A825 --description "Issues for Sandcastle to work on"` when needed.
- **Close**: `tea comment <number> "Completed by Sandcastle"` followed by `tea issue close <number>`.

Infer the repository from the configured `tea` login and current clone. Unlike GitHub's native integration, Gitea requires explicit server/token configuration and `tea` authentication.

## Pull requests as a triage surface

**PRs as a request surface: no.** _(Set to `yes` if this repo treats external pull requests as feature requests; `/triage` reads this flag.)_

When set to `yes`, use the corresponding `tea` pull-request commands for the configured Gitea/Forgejo server (for example, `tea pulls list`, `tea pr view`, and `tea pr close`; verify exact aliases with `tea --help`). Keep only pull requests from external contributors according to the repository's contribution policy.

## When a skill says "publish to the issue tracker"

Create a Gitea/Forgejo issue.

## When a skill says "fetch the relevant ticket"

Run `tea issue view <number> --comments` (or the version-appropriate equivalent shown by `tea --help`).

## Wayfinding operations

Used by `/wayfinder`. The **map** is a single issue labelled `wayfinder:map`, holding the Notes / Decisions-so-far / Fog body. Create it with the Gitea/Forgejo issue-create command and label it with `tea`.

- **Child ticket**: create one issue per ticket, with `Part of #<map>` at the top of the body. Labels are `wayfinder:<type>` (`research`/`prototype`/`grilling`/`task`). Once claimed, assign it to the driving developer using the configured `tea` assignment command.
- **Blocking**: use native Gitea/Forgejo issue dependencies only if the server version exposes them through `tea`; otherwise use a `Blocked by: #<n>, #<n>` line at the top of the child body. A ticket is unblocked when every blocker is closed.
- **Frontier query**: list the map's open children, drop any with an open blocker or assignee, and choose the first in map order.
- **Claim**: assign the issue to the driving developer as the session's first write, using the configured Gitea/Forgejo CLI/API operation.
- **Resolve**: comment the answer, close the issue, then append a context pointer (gist + link) to the map's Decisions-so-far.

Gitea/Forgejo does not provide GitHub's native sub-issues and dependency APIs in every deployment. Prefer server-supported native features, and use the documented body-line fallbacks when unavailable.

## Sandcastle migration wiring

When patching a generated Sandcastle scaffold, replace every GitHub-specific `gh` operation—not only prompt text—with the Gitea/Forgejo equivalent. Update `.sandcastle/main.mts` (or `main.ts`), all plan/implement/review/merge prompts, `.sandcastle/Containerfile`, `.sandcastle/.env.example`, and runtime environment wiring. Preserve the planner's JSON shape, marker/comment ordering, the `Sandcastle` label contract, and certificate setup. Search the complete setup for stale `gh`/GitHub commands after migration.

Install `tea` in Debian amd64/arm64 containers as follows:

```dockerfile
ARG TEA_VERSION=0.14.0
RUN set -eux; \
  case "$(dpkg --print-architecture)" in \
    amd64) TEA_ARCH="linux-amd64" ;; \
    arm64) TEA_ARCH="linux-arm64" ;; \
    *) echo "Unsupported architecture for tea" >&2; exit 1 ;; \
  esac; \
  curl -fsSL -o /usr/local/bin/tea \
    "https://dl.gitea.com/tea/${TEA_VERSION}/tea-${TEA_VERSION}-${TEA_ARCH}"; \
  chmod +x /usr/local/bin/tea
```

Test `tea --help` on the selected version because command aliases can differ.

## Official references

- [tea repository and installation](https://gitea.com/gitea/tea#installation)
- [Tea product page](https://about.gitea.com/products/tea/)
- [Sandcastle issue-tracker migration seam](issue-tracker-migration.md)
