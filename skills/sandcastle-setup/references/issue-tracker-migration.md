# Issue-tracker migration

This reference captures the reusable GitHub-to-Gitea/Forgejo or GitLab migration seam in generated Sandcastle scaffolds.

## Reference implementations

- Gitea / Forgejo support: [Sandcastle PR #512](https://github.com/mattpocock/sandcastle/pull/512/changes)
- GitLab support: [Sandcastle PR #912](https://github.com/mattpocock/sandcastle/pull/912/changes)

These changes add a tracker-specific CLI, environment example, command templates, label creation, and container installation. Apply the same separation when patching a generated project.

## Common contract

The planner needs a JSON list of open, labelled issues. The implementer needs one issue with comments. The merger comments completion and closes the issue. The selected tracker must provide:

- List open issues filtered by `Sandcastle`.
- View issue details and comments.
- Add a completion comment.
- Close an issue.
- Create the `Sandcastle` label when the user selected label creation.

Preserve the generated prompt's JSON shape. Rewire every tracker command, not only the prompts:

- `.sandcastle/main.mts` (or `main.ts`): replace every `gh issue list/view/edit/comment/close/reopen` call in the host-side tracker helpers, plus any tracker authentication or label-creation hook. The copied workflow's `ghJson`, `issueComments`, `issueState`, `addLabel`, `removeLabel`, `commentIssue`, `closeIssue`, `reopenIssue`, and planner acquisition are all part of this seam.
- `plan-prompt.md`, `implement-prompt.md`, `review-prompt.md`, and `merge-prompt.md`: replace tracker commands and preserve marker/comment ordering.
- `.sandcastle/Containerfile`: install the selected CLI and retain the certificate setup.
- `.sandcastle/.env.example` and runtime environment wiring: replace tracker variables without printing tokens.

Search the complete generated setup, including both `main.mts` and prompts, for
stale `gh`/GitHub commands after migration. Validate that list output still
normalises to the planner's expected fields and that all label operations use
the `Sandcastle` label contract.

## Gitea / Forgejo

Environment:

```dotenv
GITEA_SERVER_URL=https://gitea.example.com
GITEA_ACCESS_TOKEN=<REDACTED>
```

Container installation, for Debian amd64/arm64:

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

Runtime setup before prompts:

```bash
if [ -z "$GITEA_SERVER_URL" ] || [ -z "$GITEA_ACCESS_TOKEN" ]; then
  echo "GITEA_SERVER_URL and GITEA_ACCESS_TOKEN are required" >&2
  exit 1
fi
tea login add --name sandcastle --url "$GITEA_SERVER_URL" \
  --token "$GITEA_ACCESS_TOKEN" --no-version-check 2>/dev/null || true
tea login default sandcastle
```

Commands:

```text
LIST: tea issues list --state open --labels Sandcastle --fields index,title,body,labels,comments --output json
VIEW: tea issue <ID> --comments --output json
CLOSE: tea comment <ID> "Completed by Sandcastle" && tea issue close <ID>
LABEL: tea label create --name Sandcastle --color F9A825 --description "Issues for Sandcastle to work on"
```

Test `tea --help` on the selected version because command aliases can differ.

Official references:

- [tea repository and installation](https://gitea.com/gitea/tea#installation)
- [Tea product page](https://about.gitea.com/products/tea/)

## GitLab

Environment:

```dotenv
GITLAB_TOKEN=<REDACTED>
# Self-managed only:
GITLAB_HOST=gitlab.example.com
```

Container installation, for Debian architectures supported by the release asset:

```dockerfile
RUN ARCH=$(dpkg --print-architecture) \
  && GLAB_VERSION=$(curl -fsSL \
       "https://gitlab.com/api/v4/projects/gitlab-org%2Fcli/releases/permalink/latest" \
       | jq -r '.tag_name') \
  && curl -fsSL -o /tmp/glab.deb \
       "https://gitlab.com/gitlab-org/cli/-/releases/${GLAB_VERSION}/downloads/glab_${GLAB_VERSION#v}_linux_${ARCH}.deb" \
  && apt-get install -y /tmp/glab.deb \
  && rm -f /tmp/glab.deb
```

Commands:

```text
LIST: glab issue list --label Sandcastle --per-page 100 --output json | jq '[.[] | {number: .iid, title, body: .description, labels: (.labels // [])}]'
VIEW: glab issue view <ID> --comments
CLOSE: glab issue note <ID> --message "Completed by Sandcastle" && glab issue close <ID>
LABEL: glab label create --name "Sandcastle" --description "Issues for Sandcastle to work on" --color "#F9A825"
```

For host authentication, the official CLI supports token input on stdin:

```bash
printf '%s' "$GITLAB_TOKEN" | glab auth login \
  --hostname "${GITLAB_HOST:-gitlab.com}" --stdin
glab auth status
```

`GITLAB_TOKEN` takes precedence over stored credentials and is suitable for the container environment. The official documentation also supports `GITLAB_HOST`/`GL_HOST` for self-managed instances.

Official references:

- [GitLab CLI](https://docs.gitlab.com/cli/)
- [`glab auth login`](https://docs.gitlab.com/cli/auth/login/)

## Host and container checks

Host:

```bash
command -v tea && tea --version
command -v glab && glab --version
```

Container:

```bash
podman run --rm --entrypoint tea <image-name> --version
podman run --rm --entrypoint glab <image-name> --version
```

Run only the selected tracker checks. If the host binary is absent, guide the user to the official installation documentation and wait. If the container binary is absent, patch the `Containerfile` and rebuild before continuing.
